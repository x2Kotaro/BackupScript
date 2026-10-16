local genv = (typeof(getgenv) == "function" and getgenv()) or _G

-- The site fronts the whitelist check over HTTPS and talks to the database
-- itself, server-side. The loader only ever reaches the public site, never the
-- database host: a loader is served to every executor, so anything written here
-- is public, and the database's address has no business being in it. A support
-- fallback can still be pointed somewhere else per run with getgenv().ValkyrieEndpoint
-- (use another HTTPS host, never a raw database IP).
--
-- The `www.` host is deliberate: the apex domain answers 301 to www, and not
-- every executor's request() follows redirects.
local ENDPOINTS = {
    "https://www.valkyriehub.net/api/whitelist/check",
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
    ["slayer2"] = {
        map    = "Slayer2",
        script = "https://www.valkyriehub.net/api/raw/slayer2",
    },
    ["loot-to-forge"] = {
        map    = "Loot To Forge",
        script = "https://www.valkyriehub.net/api/raw/ltf-lua",
    },
    ["anime-zero"] = {
        map    = "Anime Zero",
        script = "https://www.valkyriehub.net/api/raw/anime-zero",
    },
    ["anime-zero-kaitan"] = {
        map     = "Anime Zero",
        variant = "Kaitan",
        script  = "https://www.valkyriehub.net/api/raw/anime-zero-kaitan",
    },
}

-- Every Anime Zero place (lobby, match servers) serves both builds.
local AnimeZero = { "anime-zero", "anime-zero-kaitan" }

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
-- Normal is listed first: nothing set = the menu hub, every run. Kaitan is
-- opted into with getgenv().Mode = "Kaitan" only.
local Place = {
    [6918802270]      = "haze-seas",
    [14979402479]     = "haze-seas",
    [99664616626491]  = "haze-seas",
    [106600795455627] = "haze-seas",
    -- Grow a Chicken Fighter serves both builds, Normal first (see above).
    [94640181989498]  = { "grow-a-chicken-fighter", "grow-a-chicken-fighter-kaitan" },
    [94939256104840]  = { "grow-a-chicken-fighter", "grow-a-chicken-fighter-kaitan" },
    [107778070777162] = "steal-an-egg",
    [133470009013038] = "steal-an-egg",

    [16205713724] = "slayer2",
    [17047024836] = "slayer2",
    [75556147183481] = "slayer2",
    [109676363279588] = "slayer2",
    [130395143593224] = "slayer2",
    [136406881576517] = "slayer2",

    [118805555015549] = "loot-to-forge",

    [114574503491412] = AnimeZero,
    [75234352859575] = AnimeZero,
    [96023089630459] = AnimeZero,
    [97017097101354] = AnimeZero,
    [109151342576374] = AnimeZero,
    [113369844309540] = AnimeZero,
    [126462205679010] = AnimeZero,
    [128853426265988] = AnimeZero,
    [132303256922720] = AnimeZero,
    [139663016529990] = AnimeZero,
    [75234352859575] = AnimeZero,
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
-- Only the Kaitan build's settings table is remembered (restored before that
-- build reads it), plus the slug last approved, for support to look at. Which
-- build runs is NOT remembered: a saved pin made a later run with nothing set
-- come back as Kaitan, and nothing set must always mean the ordinary build.
-- The key has its own file (key.txt, written only after the server verified it).
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
-- about this file. getgenv().Kaitan only carries settings -- it never picks the
-- build (getgenv() outlives a run, so a table restored here used to turn every
-- re-run into Kaitan). Only getgenv().Mode does that, see Candidates below.
if type(genv.Kaitan) ~= "table" then
    genv.Kaitan = type(Session.kaitan) == "table" and Session.kaitan or nil
end

local function saveSession(slug)
    if not hasFileSystem then return end

    local Data = {
        product = slug,
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

local function trimSpaces(value)
    return (tostring(value):gsub("^%s+", ""):gsub("%s+$", ""))
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

    -- getgenv().Mode is the only switch when a place serves both builds:
    -- "Kaitan" (or "KT" / "ไก่ตัน") runs Kaitan, anything else -- including
    -- nothing set -- runs the ordinary build (the hub), every run. The Kaitan
    -- build copies Mode into its teleport queue, so it stays Kaitan across hops.
    -- A place serving only one build ignores this (filtered out below).
    local function isKaitan(value)
        if type(value) ~= "string" then return false end
        local name = string.lower(trimSpaces(value))
        return name == "kaitan" or name == "kt" or name == "ไก่ตัน" or name == "ไก่"
    end

    local pinned = isKaitan(genv.Mode) and "kaitan" or "normal"
    do
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
    return "Server refused the script request (not public/active, or the licence ticket expired -- run again)"
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

-- Proof from the server that this machine passed the whitelist for the product
-- just approved. /api/raw serves a paid script only with it (two minutes,
-- bound to HWID), so the script URL alone downloads nothing.
local ScriptTicket = nil

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
            -- What was approved goes in ValkyrieApproved, and ValkyrieProduct is
            -- cleared: it is a pin the player sets, and both builds copy it into
            -- their teleport queue. Leaving the approved slug there turned one
            -- Normal run into a pin that every later teleport obeyed, so a
            -- Kaitan buyer stayed on the menu for good.
            genv.ValkyrieApproved = slug
            ScriptTicket = type(data.ticket) == "string" and data.ticket or nil
            genv.ValkyrieProduct = nil
            -- A Kaitan build re-runs itself after every teleport. Pointing it
            -- back here (not at its raw URL) keeps the key checked each time.
            local info = Products[slug]
            if info and info.variant == "Kaitan" and (type(genv.KaitanLoader) ~= "string" or genv.KaitanLoader == "") then
                genv.KaitanLoader = 'loadstring(game:HttpGet("https://www.valkyriehub.net/api/raw/loading"))()'
            end
            -- verified, so this is the build a cold start should come back as
            saveSession(slug)
            -- Verified: remember the key so the next run needs no getgenv().License.
            if not KEY_FROM_STORAGE then saveKey(KEY) end
            return slug
        end

        -- Printed before the kick, because the kick dialog cannot say which key
        -- was actually sent -- which is the one thing needed to tell a bad key
        -- apart from a key the loader never received.
        -- Not for "No Permission" with another build still to ask: a key that
        -- owns only the Kaitan build is meant to be refused Normal first.
        local lastCandidate = slug == Candidates[#Candidates]
        if data.error ~= "No Permission" or lastCandidate then
            warn(("[Valkyrie] rejected: %s | product=%s | source=%s | len=%d | key=%s | hwid=%s")
                :format(tostring(data.error), slug, KEY_SOURCE, #KEY, maskKey(KEY), HWID))
        end

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

-- Tell the site a dump guard tripped. The site logs the public IP it sees on
-- this request -- the address of the machine actually connected to it -- ties
-- it to the key/HWID, and alerts the owner so the key can be banned and the IP
-- blocked. The IP is not sent from here on purpose: the client could forge it,
-- the server cannot. Fire-and-forget; a failed report never blocks the kick.
local function reportHook(reason)
    if typeof(httpRequest) ~= "function" then return end
    local okH, hwid = pcall(getHWID)
    local okB, body = pcall(function()
        return HttpService:JSONEncode({
            token  = KEY,
            hwid   = (okH and hwid) or "",
            reason = reason or "hook",
            place  = PlaceId,
            job    = tostring(game.JobId),
        })
    end)
    if not okB then return end
    pcall(httpRequest, {
        Url = "https://www.valkyriehub.net/api/whitelist/report",
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = body,
    })
end

-- ── Removing a tampered session ──
--
-- Nothing here waits: a hooked session is given no time at all (a dumper only
-- needs a moment). Kick() can be swallowed by an anti-kick (a __namecall or
-- hookfunction wrapper), so every removal also makes the session useless on the
-- spot -- every child of workspace is destroyed, terrain cleared, and anything
-- the server streams back in afterwards is removed as it arrives. A real kick
-- makes the wipe moot; an eaten one leaves nothing to play.

local function wipeWorkspace()
    local function clear(child)
        if child:IsA("Terrain") then
            pcall(function() child:Clear() end)
        elseif not child:IsA("Camera") then
            pcall(function() child:Destroy() end)
        end
    end
    pcall(function()
        workspace.ChildAdded:Connect(function(child) task.defer(clear, child) end)
    end)
    for _, child in ipairs(workspace:GetChildren()) do clear(child) end
end

local function kickAndWipe(message)
    pcall(function() LocalPlayer:Kick(message) end)
    wipeWorkspace()
end

-- Bounce the session to a fresh server of the same place, without waiting on
-- it: the teleport is started and the session wiped in the same instant (the
-- player is leaving anyway). pcall only says the call did not throw, so a
-- teleport that fails afterwards (TeleportInitFailed) kicks the moment the
-- failure arrives; one that cannot be started kicks right away.
local function bounceOrRemove(message)
    local okTp, tp = pcall(game.GetService, game, "TeleportService")
    local sent = false
    if okTp and tp then
        pcall(function()
            tp.TeleportInitFailed:Connect(function(player)
                if player == LocalPlayer then kickAndWipe(message) end
            end)
        end)
        sent = pcall(function() tp:Teleport(game.PlaceId, LocalPlayer) end)
    end
    if sent then
        wipeWorkspace()
    else
        kickAndWipe(message)
    end
end

-- ── loadstring / HttpGet tamper check ──
--
-- A dumper grabs the script body one of two ways, and both are caught here
-- before anything is fetched:
--   * it replaces game's __namecall with a Lua function, which is how
--     `game:HttpGet(...)` is intercepted; or
--   * it hooks `loadstring` directly, to read the body this loader hands it a
--     few lines below.
-- A clean executor leaves both as C closures. When either is a Lua closure
-- something hooked it, so the session is bounced once -- before the paid script
-- is fetched OR handed to loadstring, so a hook learns nothing either way.
--
-- Guarded by a 60s marker on disk so this never becomes a kick/rejoin loop: an
-- executor that natively implements one of these in Lua would be caught every
-- time, so after one reset inside the window the run simply continues -- a
-- persistent hook is the executor's, not a dumper's, and cannot be reset away.
do
    local getmt = rawget(genv, "getrawmetatable") or getrawmetatable
    local isLua = rawget(genv, "islclosure") or islclosure
    -- Only islclosure: a Lua closure where the executor ships a C one means it
    -- was replaced. isfunctionhooked was tried here too (to catch a hook wrapped
    -- in newcclosure), but several mainstream executors wrap their OWN loadstring
    -- / __namecall in newcclosure natively, so it reported every one of their
    -- users as hooked and the guard wiped real customers. A newcclosure dumper
    -- evading islclosure is covered by the seal + body checks instead.
    if typeof(getmt) == "function" and typeof(isLua) == "function" then
        local function isHooked(fn)
            if typeof(fn) ~= "function" then return false end
            local ok, isL = pcall(isLua, fn)
            return ok and isL == true
        end

        local hooked = false
        -- namecall metamethod (catches a game:HttpGet interceptor)
        local okMt, mt = pcall(getmt, game)
        if okMt and typeof(mt) == "table" then
            hooked = isHooked(rawget(mt, "__namecall"))
        end
        -- loadstring itself (catches a hookfunction(loadstring, ...) dumper)
        if not hooked then
            hooked = isHooked(rawget(genv, "loadstring") or loadstring)
        end

        if hooked then
            -- Log the attempt (and the IP the site sees) before doing anything else.
            -- Fire-and-forget on its own thread: the request goes out now, but
            -- nothing waits on the reply before the session is removed.
            task.spawn(pcall, reportHook, "hook")

            local marker = KEY_SUBFOLDER .. "/.reset"
            local now = os.time()
            local last = 0
            if hasFileSystem and isfile(marker) then
                last = tonumber(readfile(marker)) or 0
            end
            if now - last > 60 then
                if hasFileSystem then pcall(writefile, marker, tostring(now)) end
                -- Re-enter the same place: a fresh session with the transient
                -- hook gone. queue_on_teleport (if the build set one up) re-runs
                -- the loader on arrival. No waiting: workspace is wiped as the
                -- teleport starts, and a teleport that fails or cannot start
                -- kicks on the spot (wiped too, in case an anti-kick eats it).
                bounceOrRemove("Valkyrie: session reset, please run again")
                return
            end
            -- The hook survived the reset. A one-off hook a dumper installs for
            -- a single run is gone after the bounce, so one still here is being
            -- held in place -- never hand the script to a hooked session. This
            -- is the whole point: without it, a dumper could hook, let the first
            -- run bounce, and re-run inside the window to be served the body.
            --
            -- Not a loop: the bounce fires at most once per 60s; the rest of the
            -- window the loader just stops here without fetching anything.
            --
            -- No client-side way to skip this: a getgenv() switch is something
            -- any dumper can set too, so there is none.
            kickAndWipe("Valkyrie: unsupported executor state")
            return
        end
    end
end

local slug = resolveProduct()
if not slug then return end

local scriptUrl = Products[slug] and Products[slug].script
if not scriptUrl then
    fail("Script not found for product: " .. slug)
    return
end

if ScriptTicket then
    local sep = string.find(scriptUrl, "?", 1, true) and "&" or "?"
    scriptUrl = scriptUrl .. sep .. "ticket=" .. HttpService:UrlEncode(ScriptTicket)
        .. "&hwid=" .. HttpService:UrlEncode(HWID or "")
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

-- The ticket goes in as the chunk's argument: the launch guard /api/raw puts at
-- the top of a licensed body runs only when it is handed the ticket that body
-- was served for, so a copy dumped from memory and pasted in on its own does
-- nothing (Website/lib/script-guard.ts).
chunk(ScriptTicket)
