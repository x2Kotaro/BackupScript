-- ══════════════════════════════════════════════════════════════════════════
--  Valkyrie Hub // loader
--
--  Paste this above the loadstring, never below it -- everything here is read
--  once, at the top of the run, and a global set afterwards arrives too late.
--
--      getgenv().LicenseKey = "YOUR-KEY"
--
--      loadstring(game:HttpGet("https://www.valkyriehub.net/api/raw/loading"))()
--
--  The key is only needed the first time. Once the server has verified it, it
--  is written to `Valkyrie Hub/MyKey/key.txt` and every later run picks it up
--  from there, so the LicenseKey line can be dropped.
--
--  ── Running the KAITAN build ──
--
--  A map that ships two builds sells them as two products: the Normal one and
--  the Kaitan one. Which of them a place serves is decided here, in `Place`
--  below, and when a place is listed against BOTH the loader walks them in
--  order and runs the first one this key owns.
--
--  That is the part to override when a key owns both and the Kaitan build is
--  the one wanted:
--
--      getgenv().LicenseKey      = "YOUR-KEY"
--      getgenv().Mode = "Kaitan"
--
--      loadstring(game:HttpGet("https://www.valkyriehub.net/api/raw/loading"))()
--
--  `Mode` takes the variant name ("Kaitan", or "Normal" to force the ordinary
--  build). `ValkyrieProduct` takes a full slug instead and is the more exact of
--  the two:
--
--      getgenv().ValkyrieProduct = "grow-a-chicken-fighter-kaitan"
--
--  Either way the pin only narrows what this place already offers. Naming a
--  build the place does not serve is ignored rather than obeyed, so a pin left
--  in a saved script cannot send the wrong loader to the wrong game.
--
--  The Kaitan build takes its own settings through `getgenv().Kaitan`, which is
--  read by the script this loader fetches and has nothing to do with the
--  whitelist. It goes in the same place, above the loadstring:
--
--      getgenv().Kaitan = { Goal = { Rebirth = 100 }, Web = true }
--
--  ── Everything else that can be set from outside ──
--
--      LicenseKey / License / Key / ValkyrieKey   the key, any of the four
--      Mode                                       "Kaitan" / "Normal"
--      ValkyrieProduct                            a full product slug
--      ValkyrieHWID                               pin the machine id by hand
--      ValkyrieEndpoint                           replace the whitelist host
-- ══════════════════════════════════════════════════════════════════════════

local genv = (typeof(getgenv) == "function" and getgenv()) or _G

-- The site fronts the whitelist check over HTTPS. Plain HTTP is refused by a
-- growing number of executors, so the raw-IP check.php is only tried when the
-- HTTPS route cannot be reached at all -- never when it answers with a verdict.
--
-- The `www.` host is deliberate: the apex domain answers 301 to www, and not
-- every executor's request() follows redirects.
local ENDPOINTS = {
    "https://www.valkyriehub.net/api/whitelist/check",
    "http://119.59.99.19/check.php",
}
if type(genv.ValkyrieEndpoint) == "string" and genv.ValkyrieEndpoint ~= "" then
    ENDPOINTS = { genv.ValkyrieEndpoint }
end

local KICK_ON_FAIL = true

-- Where a verified key is remembered, inside the executor's workspace folder.
local KEY_FOLDER    = "Valkyrie Hub"
local KEY_SUBFOLDER = KEY_FOLDER .. "/MyKey"
local KEY_FILE      = KEY_SUBFOLDER .. "/key.txt"

-- ── Products ──
-- A product is one thing a customer buys. A map that ships a Normal and a
-- Kaitan build sells them separately, so each build is its own product with its
-- own slug -- `map` is only what the player is shown, and two products may
-- share it. The whitelist is asked about `product`, never about `map`.
--
-- A slug is the same string in three places, and they have to stay in step:
--   * the shop's Product.slug   (what the site sells)
--   * the Script.slug behind /api/raw/<slug>   (what is executed)
--   * the slug sent to the whitelist, which resolves it to Product.mapName
--
-- `map` .. " " .. `variant` must equal the bot's map_name ("Haze Seas Kaitan"),
-- because that pair is the fallback the server uses when a slug does not resolve.
local Products = {
    ["haze-seas"] = {
        map    = "Haze Seas",
        script = "https://www.valkyriehub.net/api/raw/haze-seas",
    },
    ["grow-a-chicken-fighter"] = {
        map    = "Grow a Chicken Fighter",
        script = "https://www.valkyriehub.net/api/raw/grow-a-chicken-fighter",
    },
    ["grow-a-chicken-fighter-kaitan"] = {
        map     = "Grow a Chicken Fighter",
        variant = "Kaitan",
        script  = "https://www.valkyriehub.net/api/raw/grow-a-chicken-fighter-kaitan",
    },
    ["steal-an-egg"] = {
        map    = "Steal An Egg",
        script = "https://www.valkyriehub.net/api/raw/steal-an-egg",
    },
}

-- PlaceId -> product slug, or a list of slugs when one place can be served by
-- more than one product (a Kaitan build living inside the same place as the
-- Normal one). A list is resolved against the server: see resolveProduct.
--
-- A place has to be listed against both builds before getgenv().Mode can pick
-- between them -- the pin narrows this list and never adds to it. So a
-- place serving a Kaitan build is written as a list even when most keys only
-- own one of the two:
--
--     [94640181989498] = { "grow-a-chicken-fighter", "grow-a-chicken-fighter-kaitan" },
--
-- Order is the default. A key that owns both and pins nothing gets the first
-- entry, so the Normal build is listed first and Kaitan is opted into.
local Place = {
    [6918802270]      = "haze-seas",
    [14979402479]     = "haze-seas",
    [99664616626491]  = "haze-seas",
    [106600795455627] = "haze-seas",
    -- Grow a Chicken Fighter serves both builds. Normal is listed first, so a
    -- key that owns it gets it and nothing changes for those customers; only a
    -- key refused the Normal build falls through and is asked about Kaitan.
    -- getgenv().Mode = "Kaitan" skips straight to the second entry.
    [94640181989498]  = { "grow-a-chicken-fighter", "grow-a-chicken-fighter-kaitan" },
    [94939256104840]  = { "grow-a-chicken-fighter", "grow-a-chicken-fighter-kaitan" },
    [107778070777162] = "steal-an-egg",
    [133470009013038] = "steal-an-egg",

    -- A Kaitan build that is its own game: one PlaceId, one product.
    -- [000000000000000] = "haze-seas-kaitan",

    -- Same place serving both builds -- tried in the order listed.
    -- [99664616626491] = { "haze-seas", "haze-seas-kaitan" },
}

local HttpService = game:GetService("HttpService")
local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

local httpRequest = (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request) or http_request or request

local hasFileSystem = typeof(writefile) == "function"
    and typeof(readfile) == "function"
    and typeof(isfile) == "function"
    and typeof(isfolder) == "function"
    and typeof(makefolder) == "function"

-- ── Saved session ──
--
-- What the player typed above the loadstring, kept on disk so the next run does
-- not need it typed again.
--
-- getgenv() lasts exactly one game session. A teleport starts a fresh one, and
-- so does a crash, a client restart, and an executor's own auto-execute folder
-- firing this file on join. The queued chunk the Kaitan build writes carries the
-- globals across a teleport it starts itself, and covers nothing else -- so a
-- run that came back any other way used to come back as the ordinary build on
-- default settings. That looks exactly like the script working.
--
-- Three things are remembered, and the key is not one of them: it has its own
-- file already (key.txt, written only after the server verified it).
--
--   product   the slug the whitelist actually approved -- more exact than the
--             variant name that asked for it
--   mode      what was passed as getgenv().Mode, for a place whose product
--             list has changed since
--   kaitan    the getgenv().Kaitan table, restored before the build reads it
--
-- getgenv() always wins: what is typed above the loadstring this run overrides
-- what was saved, and then replaces it. Deleting the file is how a run goes back
-- to defaults.
local SESSION_FILE = KEY_FOLDER .. "/Session.json"

local Session = { }

if hasFileSystem then
    local Ok, Body = pcall(function()
        if isfile(SESSION_FILE) then return readfile(SESSION_FILE) end
    end)

    if Ok and type(Body) == "string" and Body ~= "" then
        local Fine, Data = pcall(function()
            return HttpService:JSONDecode(Body)
        end)

        if Fine and type(Data) == "table" then
            Session = Data
        end
    end
end

-- The build's own settings go back into getgenv() here rather than being handed
-- over directly, because the build reads getgenv().Kaitan and knows nothing
-- about this file.
if type(genv.Kaitan) ~= "table" and type(Session.kaitan) == "table" then
    genv.Kaitan = Session.kaitan
end

local function saveSession(slug)
    if not hasFileSystem then return end

    local Data = {
        product = slug,
        mode = type(genv.Mode) == "string" and genv.Mode ~= "" and genv.Mode or Session.mode,
        kaitan = type(genv.Kaitan) == "table" and genv.Kaitan or Session.kaitan,
    }

    local Ok, Body = pcall(function()
        return HttpService:JSONEncode(Data)
    end)

    if not Ok then return end

    pcall(function()
        if not isfolder(KEY_FOLDER) then makefolder(KEY_FOLDER) end
    end)

    pcall(writefile, SESSION_FILE, Body)
end

-- The candidate products for this place, always as a list.
local Candidates do
    local entry = Place[PlaceId]
    if type(entry) == "table" then
        Candidates = entry
    elseif type(entry) == "string" then
        Candidates = { entry }
    else
        Candidates = {}
    end

    -- Support and testers can pin one build when a place serves both. Accepts
    -- either a full slug through ValkyrieProduct ("haze-seas-kaitan") or a
    -- variant name through Mode ("Kaitan").
    --
    -- What was saved last run is the last resort, and it is what makes a cold
    -- start -- a crash, a restart, an auto-execute -- come back as the same
    -- build. A saved pin naming a product this place does not serve is filtered
    -- out below like any other, so carrying one between games costs nothing.
    local pinned = genv.ValkyrieProduct or genv.Mode or Session.product or Session.mode
    if type(pinned) == "string" and pinned ~= "" then
        pinned = string.lower(pinned)
        local picked = {}
        for _, slug in ipairs(Candidates) do
            local info = Products[slug]
            local variant = (info and info.variant and string.lower(info.variant)) or "normal"
            if slug == pinned or variant == pinned then
                picked[#picked + 1] = slug
            end
        end
        if #picked > 0 then Candidates = picked end
    end
end

-- What a product is called in a message to the player: "Haze Seas (Kaitan)".
local function productLabel(slug)
    local info = Products[slug]
    if not info then return slug end
    if info.variant then return info.map .. " (" .. info.variant .. ")" end
    return info.map
end

local function fail(reason)
    genv.ValkyrieWhitelisted = false
    warn("[Valkyrie] " .. tostring(reason))
    if KICK_ON_FAIL and LocalPlayer then
        LocalPlayer:Kick("Whitelist: " .. tostring(reason))
    end
    return false
end

-- ── Saved key ──
-- Not every executor exposes a filesystem, so every call is guarded and the
-- loader still works (key required each run) when the API is missing.
-- hasFileSystem is declared with the saved session further up, which needs it
-- before the candidate list is built.

-- Keys pasted through some executor editors arrive with invisible passengers: a
-- BOM, zero-width spaces, or hyphens autocorrected into en/em dashes. On screen
-- they are identical to a good key, so the server rejecting one looks like the
-- key itself is wrong.
local function trim(value)
    local s = tostring(value)
    s = s:gsub("\239\187\191", "")           -- BOM (U+FEFF)
    s = s:gsub("\226\128[\139\140\141]", "") -- zero-width space / non-joiner / joiner
    s = s:gsub("\226\128[\144-\149]", "-")   -- U+2010..U+2015 dashes -> plain hyphen
    s = s:gsub("[\"']", "")                  -- quotes dragged along by a sloppy paste
    s = s:gsub("%s", "")                     -- a key never contains whitespace
    return s
end

-- For log lines: enough of the key to tell two keys apart, not enough to reuse.
local function maskKey(key)
    if #key <= 6 then return string.rep("*", #key) end
    return key:sub(1, 3) .. string.rep("*", #key - 6) .. key:sub(-3)
end

local function ensureFolders()
    if not hasFileSystem then return false end
    return (pcall(function()
        if not isfolder(KEY_FOLDER) then makefolder(KEY_FOLDER) end
        if not isfolder(KEY_SUBFOLDER) then makefolder(KEY_SUBFOLDER) end
    end))
end

local function loadSavedKey()
    if not hasFileSystem then return nil end
    local ok, saved = pcall(function()
        if isfile(KEY_FILE) then return readfile(KEY_FILE) end
        return nil
    end)
    if ok and saved then
        saved = trim(saved)
        if saved ~= "" then return saved end
    end
    return nil
end

local function saveKey(key)
    if not hasFileSystem or not ensureFolders() then return end
    pcall(writefile, KEY_FILE, key)
end

-- Called when the server says the key itself is bad, so a stale saved key does
-- not lock the player out of ever entering a new one.
local function forgetKey()
    if typeof(delfile) == "function" then pcall(delfile, KEY_FILE) end
end

-- Executors disagree about which table a loader's getgenv() write actually lands
-- in -- on some of them the loader's getgenv() and the chunk's getgenv() are not
-- the same table at all, and users reasonably reach for _G instead. Read every
-- global table there is rather than betting on one.
local function collectEnvs()
    local envs, seen = {}, {}

    local function add(t)
        if typeof(t) == "table" and not seen[t] then
            seen[t] = true
            envs[#envs + 1] = t
        end
    end

    add(genv)
    add(_G)
    add(shared)

    if typeof(getgenv) == "function" then
        local ok, t = pcall(getgenv)
        if ok then add(t) end
    end
    if typeof(getrenv) == "function" then
        local ok, t = pcall(getrenv)
        if ok then add(t) end
    end

    return envs
end

local KEY_NAMES = { "License", "LicenseKey", "Key", "ValkyrieKey" }
local KEY_SOURCE = "none"

local function readProvidedKey()
    for _, env in ipairs(collectEnvs()) do
        for _, name in ipairs(KEY_NAMES) do
            local ok, value = pcall(function() return env[name] end)
            if ok and type(value) == "string" then
                local cleaned = trim(value)
                if cleaned ~= "" then
                    KEY_SOURCE = "global." .. name
                    return cleaned
                end
            end
        end
    end
    return nil
end

local KEY = readProvidedKey()
local KEY_FROM_STORAGE = false
if not KEY then
    KEY = loadSavedKey()
    KEY_FROM_STORAGE = KEY ~= nil
    if KEY then KEY_SOURCE = "key.txt" end
end
KEY = KEY and trim(KEY) or ""

local function getHWID()
    -- Support can pin a machine's id by hand when an executor reports a new one.
    if type(genv.ValkyrieHWID) == "string" and genv.ValkyrieHWID ~= "" then
        return genv.ValkyrieHWID
    end

    -- A table constructor whose first entry is nil makes ipairs stop before the
    -- first iteration, so the old list silently skipped get_hwid on every
    -- executor that lacks gethwid. Index it directly instead.
    local candidates = { gethwid, get_hwid }
    for i = 1, 2 do
        local fn = candidates[i]
        if typeof(fn) == "function" then
            local ok, h = pcall(fn)
            if ok and h and tostring(h) ~= "" then return tostring(h) end
        end
    end
    local ok, id = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if ok and id and tostring(id) ~= "" then return tostring(id) end
    return "unknown"
end

-- request() is tried first because it reports the status code, but a failure
-- there must fall through to game:HttpGet rather than giving up: on some
-- executors request() is present and simply refuses HTTPS or the host.
local function httpGetOnce(url)
    if httpRequest then
        local ok, res = pcall(httpRequest, { Url = url, Method = "GET" })
        if ok and res and res.Body then return res.Body end
    end
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if ok then return body end
    return nil
end

-- Tried three times, spaced out.
--
-- On a rig running many clients at once the first attempt is regularly lost to
-- the machine's own network rather than to anything the server did: a router
-- NAT table that has filled up, or an uplink saturated by a dozen clients
-- pulling assets, drops the SYN and the request sits there for twenty seconds
-- before curl gives up. Both clear on their own within a few seconds, so the
-- retry lands where the first attempt did not -- and one client giving up here
-- means that account does nothing for the rest of the night.
local function httpGet(url)
    for attempt = 1, 3 do
        local body = httpGetOnce(url)
        if body then return body end
        if attempt < 3 then task.wait(attempt * 2 + math.random() * 2) end
    end
    return nil
end

-- The script endpoint only serves executors, and it decides that from the
-- User-Agent. game:HttpGet carries Roblox's own UA, so it must be tried first --
-- an executor's request() sends the executor's UA and gets an HTML error page.
local function fetchScriptOnce(url)
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if ok and body and body ~= "" then return body end

    if httpRequest then
        local ok2, res = pcall(httpRequest, {
            Url = url,
            Method = "GET",
            Headers = { ["User-Agent"] = "Roblox/WinInet" },
        })
        if ok2 and res and res.Body then return res.Body end
    end
    return nil
end

-- Retried for the same reason httpGet is: this is the last request of the boot
-- and losing it costs the whole run, so a transient drop is worth three tries
-- rather than one.
local function fetchScript(url)
    for attempt = 1, 3 do
        local body = fetchScriptOnce(url)
        if body then return body end
        if attempt < 3 then task.wait(attempt * 2 + math.random() * 2) end
    end
    return nil
end

-- An HTML body means the endpoint rejected us and served an error page. Parsing
-- it as Lua would only produce a confusing syntax error.
local function htmlReason(body)
    local head = string.lower(string.sub(body, 1, 400))
    if not (string.find(head, "<!doctype", 1, true) or string.find(head, "<html", 1, true)) then
        return nil
    end
    if string.find(body, "ไม่พบสคริปต์", 1, true) then
        return "Script not found on the server (wrong slug in Products table)"
    end
    return "Server refused the script request (not public/active, or blocked executor)"
end

-- Asks each endpoint in turn and returns the first decoded verdict. An endpoint
-- that answers -- valid or not -- ends the walk: only an unreachable endpoint,
-- or one that replies with something that is not JSON, falls through to the next.
local function askServer(query)
    local lastError = "Can't connect to the server."
    for _, endpoint in ipairs(ENDPOINTS) do
        local body = httpGet(endpoint .. query)
        if body then
            local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
            if ok and type(data) == "table" then
                return data
            end
            warn("[Valkyrie] " .. endpoint .. " did not return JSON: " .. string.sub(tostring(body), 1, 300))
            lastError = "Bad response from the server."
        end
    end
    return nil, lastError
end

local HWID = nil

-- One ownership question about one product.
local function askProduct(slug)
    HWID = HWID or getHWID()
    local info = Products[slug]
    -- `map` is still sent so a server that keys off the map name keeps working;
    -- `product` is what a variant-aware server reads. place_id rides along as
    -- plain digits, so it survives executors that mangle the escaping of
    -- everything else in the query string.
    local query = ("?token=%s&product=%s&map=%s&variant=%s&place_id=%d&hwid=%s"):format(
        HttpService:UrlEncode(KEY),
        HttpService:UrlEncode(slug),
        HttpService:UrlEncode(info.map),
        HttpService:UrlEncode(info.variant or "Normal"),
        PlaceId,
        HttpService:UrlEncode(HWID)
    )
    return askServer(query)
end

-- Walks the candidate products and stops at the first one this key owns. Only
-- "No Permission" moves on to the next candidate -- every other verdict is
-- about the key itself and so applies to all of them equally.
local function resolveProduct()
    if KEY == "" or KEY == "PUT-YOUR-KEY-HERE" then
        fail('Key Not Found. Set getgenv().LicenseKey = "YOUR-KEY" above the loader and run again.')
        return nil
    end

    for _, slug in ipairs(Candidates) do
        local data, err = askProduct(slug)
        if not data then
            fail(err)
            return nil
        end

        if data.valid then
            genv.ValkyrieWhitelisted = true
            genv.ValkyrieUser = data
            genv.ValkyrieProduct = slug
            -- verified, so this is the build a cold start should come back as
            saveSession(slug)
            -- Verified: remember the key so the next run needs no getgenv().License.
            if not KEY_FROM_STORAGE then saveKey(KEY) end
            return slug
        end

        -- Printed before the kick, because the kick dialog cannot say which key
        -- was actually sent -- which is the one thing needed to tell a bad key
        -- apart from a key the loader never received.
        warn(("[Valkyrie] rejected: %s | product=%s | source=%s | len=%d | key=%s | hwid=%s")
            :format(tostring(data.error), slug, KEY_SOURCE, #KEY, maskKey(KEY), HWID))

        -- The key is only wrong in these two cases. "No Permission" and
        -- "Invalid HWID" mean the key is fine, so it stays saved.
        local keyIsBad = data.error == "Invalid Key" or data.error == "Key Not Found"
        if KEY_FROM_STORAGE and keyIsBad then
            forgetKey()
        end

        if data.error == "Invalid Key" then
            fail("Invalid Key")
            return nil
        elseif data.error == "Invalid HWID" then
            fail("Invalid HWID (reset it in Discord, then run again)")
            return nil
        elseif data.error == "Key Not Found" then
            fail("Key Not Found")
            return nil
        elseif data.error ~= "No Permission" then
            fail(data.error or "Invalid or expired key")
            return nil
        end
        -- "No Permission": fall through to the next build of this map, if any.
    end

    -- Every build of this map was denied. Name them all: owning the Normal
    -- build says nothing about owning the Kaitan one, and the reverse.
    local labels = {}
    for _, slug in ipairs(Candidates) do
        labels[#labels + 1] = productLabel(slug)
    end
    fail("You don't own " .. table.concat(labels, " / ") .. ". Please purchase " ..
        (#Candidates > 1 and "that version" or "this map") .. " first.")
    return nil
end

if #Candidates == 0 then
    fail("game not support!")
    return
end

local slug = resolveProduct()
if not slug then return end

local scriptUrl = Products[slug] and Products[slug].script
if not scriptUrl then
    fail("Script not found for product: " .. slug)
    return
end

local body = fetchScript(scriptUrl)

-- The boot's HTTP work is over here, whether it worked or not, so the queue
-- slot the autoexec bootstrap took goes back now rather than at the end of the
-- chunk below -- the next client in line has nothing to do with whether this
-- one found its script. Nothing is lost when the bootstrap is not in use: the
-- global simply is not there.
do
    local release = rawget(genv, "ValkyrieQueueRelease")
    if type(release) == "function" then pcall(release) end
end

if not body then
    fail("Can't load the script.")
    return
end

local reason = htmlReason(body)
if reason then
    fail(reason)
    return
end

local chunk, err = loadstring(body)
if not chunk then
    fail("Script error: " .. tostring(err))
    return
end

chunk()