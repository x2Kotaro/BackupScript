-- ══════════════════════════════════════════════════════════════════════════
--  Valkyrie Hub // autoexec bootstrap
--
--  This replaces the plain
--
--      loadstring(game:HttpGet("https://www.valkyriehub.net/api/raw/loading"))()
--
--  line for rigs that run many clients on one machine.
--
--  ── What it is for ──
--
--  Fifty Roblox clients launched together all reach that loadstring within the
--  same second, and each boot then makes three HTTPS requests -- the loader
--  itself, the whitelist check, and the script the whitelist hands back. That
--  is a hundred and fifty connections opened at once from one address, and the
--  thing that gives out first is never the web server:
--
--      Curl error: Failed to connect to www.valkyriehub.net port 443
--      after 21081 ms: Could not connect to server
--
--  Twenty-one seconds with no answer at all is a SYN that was dropped, not one
--  that was refused -- a refusal comes back in milliseconds. What drops it is
--  the router's NAT table filling up, the uplink saturating while fifty clients
--  pull assets, or Windows running out of ephemeral ports. The server answers
--  fifty concurrent requests in twenty-five milliseconds each; it never saw
--  these.
--
--  So the clients are made to take turns.
--
--  ── How the queue works ──
--
--  Every client writes a ticket file into a folder they all share, named after
--  the second it was written. A client may go once fewer than Queue.Slots
--  tickets sort ahead of its own, and deletes its ticket when the boot is done.
--  Nothing talks to anything: the shared folder is the whole protocol, which is
--  the only kind that works between fifty separate Roblox processes.
--
--  Every failure path here fails OPEN -- no filesystem, a ticket that cannot be
--  written, a wait that runs long -- because a client that cannot queue should
--  still start. The worst case is the burst this file was written to avoid, and
--  that is strictly better than a client that never runs.
--
--  ── Install ──
--
--  Put this file in the executor's autoexec folder. Set the two lines under
--  SETTINGS and nothing else; the loader reads them out of getgenv() exactly as
--  it did before.
-- ══════════════════════════════════════════════════════════════════════════

---- ============ SETTINGS ============ ----

getgenv().LicenseKey = "PPFE-MVQX-HAVU-7TR8"
getgenv().Mode = "Kaitan"

getgenv().Kaitan = {
    Goal = { Rebirth = 100, Rank = "gold1" },

    Build = {
        TowerFloor    = 33,
        CoopSlots     = 6,
        FeederLevel   = 20,
        RecyclerLevel = 18,
    },

    RebirthLevel = 1,

    Arena = {
        Enabled   = true,
        MinRarity = "epic",
        Skip      = { "harder" },
        Ability   = true,
    },

    Server    = { Hop = true, MaxPlayers = 4, Recheck = 30 },
    Eggs      = { Hunt = true },

    Tutorial  = true,
    Rewards   = true,
    Scrap     = true,
    Events    = true,
    Incubator = true,
    Codes     = { },

    Web       = true,
    Discord   = { Webhook = "" },

    AntiAFK      = true,
    AutoRejoin   = true,
}

---- ============ Queue ============ ----

local LoaderUrl = "https://www.valkyriehub.net/api/raw/loading"
local CacheFile = "Valkyrie Hub/Boot.cache.lua"

local Queue = {
    Folder = "Valkyrie Hub/Queue",

    -- How many clients may be doing their HTTP boot at the same moment. Five
    -- keeps the connection count low enough for a home router's NAT table
    -- while still draining fifty clients in well under a minute.
    Slots = 5,

    -- A slot is given up after this long no matter what. It is not a limit on
    -- the client -- the client carries on -- it only stops one slow or crashed
    -- boot from holding the line behind it.
    TTL = 60,

    -- Longest a client waits for its turn before going anyway.
    Wait = 180,
}

local HasFiles = typeof(writefile) == "function"
    and typeof(readfile) == "function"
    and typeof(isfile) == "function"
    and typeof(isfolder) == "function"
    and typeof(makefolder) == "function"
    and typeof(listfiles) == "function"
    and typeof(delfile) == "function"

-- Ticket names only, sorted. The name carries the second it was written, zero
-- padded to a fixed width, so a plain text sort is the queue order and no file
-- has to be opened to work it out -- fifty clients reading fifty files every
-- second would cost more than the burst being avoided.
local function Tickets()
    local Ok, Found = pcall(listfiles, Queue.Folder)

    if not (Ok and type(Found) == "table") then return end

    local Names = { }

    for _, Path in ipairs(Found) do
        local Name = tostring(Path):match("(%d+_%d+)%.tkt$")

        if Name then
            table.insert(Names, Name)
        end
    end

    table.sort(Names)

    return Names
end

function Queue.Take()
    -- no filesystem to share: a random stagger is all that is left, and it is
    -- still far better than fifty clients firing on the same tick
    if not HasFiles then
        task.wait(math.random() * 25)

        return function() end
    end

    if not isfolder("Valkyrie Hub") then pcall(makefolder, "Valkyrie Hub") end
    if not isfolder(Queue.Folder) then pcall(makefolder, Queue.Folder) end

    local Mine = string.format("%010d_%09d", os.time(), math.random(0, 999999999))
    local Path = Queue.Folder .. "/" .. Mine .. ".tkt"

    if not pcall(writefile, Path, "1") then
        task.wait(math.random() * 25)

        return function() end
    end

    local Done = false

    local function Release()
        if Done then return end

        Done = true

        pcall(delfile, Path)
    end

    -- the slot is handed back on a timer as well as by hand, so a boot that
    -- errors somewhere further down cannot hold the line for the rest of the
    -- session
    task.delay(Queue.TTL, Release)

    local Deadline = os.clock() + Queue.Wait

    while os.clock() < Deadline do
        local Names = Tickets()

        if not Names then break end

        local Now = os.time()
        local Ahead = 0
        local Found = false

        for _, Name in ipairs(Names) do
            if Name == Mine then
                Found = true

                break
            end

            local At = tonumber(Name:match("^(%d+)")) or 0

            if Now - At < Queue.TTL then
                Ahead = Ahead + 1
            else
                -- left behind by a client that was closed or crashed
                pcall(delfile, Queue.Folder .. "/" .. Name .. ".tkt")
            end
        end

        -- our own ticket is gone, so waiting for a turn that will never be
        -- reached is worse than simply going
        if not Found then break end
        if Ahead < Queue.Slots then break end

        task.wait(1 + math.random())
    end

    return Release
end

---- ============ Boot ============ ----

-- Five tries rather than one. The failure this file exists for is transient by
-- nature -- a full NAT table drains, a saturated uplink clears -- so the second
-- attempt usually lands where the first did not.
local function Fetch(Url)
    for Attempt = 1, 5 do
        local Ok, Body = pcall(game.HttpGet, game, Url)

        if Ok and type(Body) == "string" and #Body > 64 then
            return Body
        end

        task.wait(Attempt * 3 + math.random() * 2)
    end
end

task.spawn(function()
    -- HttpGet from the first frame of a join is the worst moment to ask for
    -- anything; the client is still pulling the place down
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end

    local Release = Queue.Take()

    -- the loader hands the slot back once it has fetched the game script, so
    -- the whole three-request boot is covered by one ticket rather than three
    getgenv().ValkyrieQueue = Queue
    getgenv().ValkyrieQueueRelease = Release

    local Body = Fetch(LoaderUrl)

    if Body and HasFiles then
        pcall(writefile, CacheFile, Body)
    end

    -- the site is unreachable: last night's copy is a great deal better than
    -- nothing, and the whitelist inside it still runs normally
    if not Body and typeof(isfile) == "function" and isfile(CacheFile) then
        local Ok, Cached = pcall(readfile, CacheFile)

        if Ok and type(Cached) == "string" and #Cached > 64 then
            Body = Cached

            warn("[ValkyrieHub] site unreachable; running the cached loader")
        end
    end

    if not Body then
        Release()

        return warn("[ValkyrieHub] could not reach the loader and there is no cached copy on disk")
    end

    local Chunk, Err = loadstring(Body)

    if not Chunk then
        Release()

        return warn("[ValkyrieHub] the loader would not compile: " .. tostring(Err))
    end

    Chunk()
end)
