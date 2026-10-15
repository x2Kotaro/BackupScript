--!nocheck
-- ========================================================================
--  Valkyrie dump test  -- ticket + seal protected build (anime-zero-test)
--  Fill in KEY (must OWN anime-zero). Paste the whole thing, run once.
--  STEALTH=true -> hooks wrapped in newcclosure (islclosure=false)
--  No loader/dump-guard here on purpose: shows what a dumper captures once
--  the guard is out of the way -- ciphertext in transit vs plaintext at run.
-- ========================================================================
local KEY     = "PPFE-MVQX-HAVU-7TR8"
local STEALTH = true

local DIR, seen, n = "Valkyrie Hub/vkdump", {}, 0
if typeof(makefolder) == "function" then pcall(makefolder, "Valkyrie Hub") pcall(makefolder, DIR) end
local wrap = (STEALTH and typeof(newcclosure) == "function") and newcclosure or function(f) return f end
local isL  = typeof(islclosure) == "function" and islclosure or function() return "n/a" end

local function save(tag, body)
    if typeof(body) ~= "string" or #body < 200 then return end
    if seen[#body] then return end
    seen[#body] = true
    n = n + 1
    local name = ("%s/%02d_%s_%d.lua"):format(DIR, n, tag, #body)
    if typeof(writefile) == "function" then pcall(writefile, name, body) end
    local plain = body:find("DevCameraOcclusionMode", 1, true) ~= nil
    warn(("[VKDUMP] #%02d %-10s %7d B plain=%s -> %s"):format(n, tag, #body, tostring(plain), name))
end

-- 1. namecall (game:HttpGet / HttpGetAsync)
do
    local old
    local function hook(self, ...)
        local m = getnamecallmethod()
        local ret = old(self, ...)
        if (m == "HttpGet" or m == "HttpGetAsync") and typeof(ret) == "string" then save("httpget", ret) end
        return ret
    end
    if typeof(hookmetamethod) == "function" then
        old = hookmetamethod(game, "__namecall", wrap(hook))
    else
        local mt = getrawmetatable(game)
        if typeof(setreadonly) == "function" then pcall(setreadonly, mt, false) end
        old = rawget(mt, "__namecall"); mt.__namecall = wrap(hook)
    end
    warn("[VKDUMP] __namecall hooked (islclosure =", isL(rawget(getrawmetatable(game), "__namecall")), ")")
end

-- 2. loadstring (loader, seal stub, DECODED body)
if typeof(hookfunction) == "function" and typeof(loadstring) == "function" then
    local orig
    orig = hookfunction(loadstring, wrap(function(src, ...) save("loadstring", src) return orig(src, ...) end))
    warn("[VKDUMP] loadstring hooked (islclosure =", isL(loadstring), ")")
end

-- 3. executor request() (fetches that bypass game:HttpGet)
do
    local req0 = (syn and syn.request) or (http and http.request) or http_request or request
    if typeof(req0) == "function" and typeof(hookfunction) == "function" then
        local orig
        orig = hookfunction(req0, wrap(function(opts, ...)
            local res = orig(opts, ...)
            if typeof(res) == "table" and typeof(res.Body) == "string" then save("request", res.Body) end
            return res
        end))
        warn("[VKDUMP] request() hooked (islclosure =", isL(req0), ")")
    end
end

warn("[VKDUMP] hooks ready (STEALTH=" .. tostring(STEALTH) .. "). fetching sealed build...")

-- ===== licensed fetch of the sealed test build (what the loader does) =====
local HttpService = game:GetService("HttpService")
local req = (syn and syn.request) or (http and http.request) or http_request or request
local hwid = (gethwid and gethwid()) or (get_hwid and get_hwid())
          or game:GetService("RbxAnalyticsService"):GetClientId()

local res = req({
    Url = "https://www.valkyriehub.net/api/whitelist/check",
    Method = "POST",
    Headers = { ["Content-Type"] = "application/json" },
    Body = HttpService:JSONEncode({ token = KEY, map = "Anime Zero", place_id = game.PlaceId, hwid = hwid }),
})
local data = HttpService:JSONDecode(res.Body)
if not data.valid then warn("[VKDUMP] check FAILED: " .. tostring(data.error)) return end
warn("[VKDUMP] ticket ok, fetching body...")

local url = ("https://www.valkyriehub.net/api/raw/anime-zero-test?ticket=%s&hwid=%s")
    :format(HttpService:UrlEncode(data.ticket), HttpService:UrlEncode(hwid))
local sealed = req({ Url = url, Method = "GET" }).Body
save("rawbody", sealed)

warn("[VKDUMP] running sealed build (ticket as chunk arg)...")
local ok, err = pcall(function() return loadstring(sealed)(data.ticket) end)
warn("[VKDUMP] done. run ok =", ok, err and ("err=" .. tostring(err)) or "")
warn("[VKDUMP] captured " .. n .. " file(s) -> " .. DIR)
