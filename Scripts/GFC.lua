--[[ ============================ PLAN ============================

    Valkyrie Hub // Grow a Chicken Fighter -- MENU BUILD (GFC)

    Every feature is a toggle the player flips. GFCKT.lua is the same engine
    with the menu taken out and a goal put in.

    PAGES
      Chickens      Eggs, Fusion, Roster, Pit
      Progression   Rebirth, Plot, Tower
      Arena         Team, Battle, Rewards
      World         Scrap, Event
      Rewards       Daily, Progress
      Configuration Interface, FPS, Language

    STATS  (Fight.Stats, taken from ArenaView, which the arena's own battle
            simulation calls -- these are the game's numbers, not an estimate)

      hp    = 100 * 1.1^(level-1) * archetype.hp    * geneHp    * mutation.hp
      atk   =  10 * 1.1^(level-1) * archetype.atk   * geneAtk   * mutation.atk
      speed = (1 + 0.02*(level-1)) * archetype.speed * geneSpeed * mutation.speed

      vigor drives hp and furia drives atk, both to x1.50 at 31; velocidad
      drives speed to x1.15; impetu is stamina and never appears in a fight.

      GameConfig.roster.rarityMult is NOT a combat multiplier and is not read.
      Rarity matters through the archetype (a secret body carries atk 2.40
      where a common carries 1.00) and through the gene cap.

    FUSION  (Fight.PlanFusion)
      Same-rarity fusion rolls an ascend and guarantees a gene mutation;
      cross-rarity does neither and is only worth the money when the partner
      raises a gene the champion is short of. Every fuse locks LEVEL to the
      higher side and ABILITY to the harder-hitting one, which are the two free
      lock slots. Eggs stay unlocked so both stashes are summed.

    MUTATION
      Content.Mutations holds one, `inverted`: 0.5% on a hatch, x1.15 hp and
      atk. It cannot be worked towards, so it is never sold and never fed to
      the incubator, and it is marked with the game's own favourite flag so the
      protection survives a rejoin.

      mutationInherit is 0.5, and MutationView.fusionOdds returns a flat 1 when
      both sides carry the same one. So a mutated common fused into a clean
      champion is an even chance of moving it across -- and a champion that
      already carries one LOSES it at the same 50% against a clean partner,
      which is why the planner will only pair a mutated champion with the same
      mutation and otherwise leaves it alone.

    TOWER  (Fight.Best)
      One chicken against one enemy, so the pick is sqrt(atk * speed * hp)
      nudged by the signature ability's total damage multiplier. The pit and
      tower run the real combat system; the ability is a tiebreak rather than a
      factor because its cooldown is the server's and cannot be read.

    ARENA  (Fight.ArenaTeam)
      ArenaBattle.simulate reads hp, atk and speed and nothing else -- not one
      of the 146 abilities is in it. Everyone hits the enemy's first living
      slot, a fighter swings every 1/speed seconds, and at 60 seconds the
      winner is whoever kept the larger fraction of its hp.

      The view's `powerN` is atk * 100, which is what the MATCHMAKER weighs the
      account by. It is not what wins the fight, and it cannot see hp or speed
      at all -- so those are strength the account is not charged for. The team
      is picked on sqrt(sum(atk*speed) * sum(hp)) instead, best trio out of the
      top twelve, and returned heaviest hp first because slot one is the slot
      everything shoots at.

  ============================================================== --]]

getgenv().ConfigurationTable = {}
getgenv().Settings = {}
 
local FolderConfiguration = "Valkyrie Hub"
local FolderSettings = "Valkyrie Hub/GFC"
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

while not LocalPlayer do
    task.wait()

    LocalPlayer = Players.LocalPlayer
end

do
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

    Character:WaitForChild("HumanoidRootPart")
    Character:WaitForChild("Humanoid")
end

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UserId = LocalPlayer.UserId
local IconValkyrie = "87057639235201"
local LibraryUrl = "https://www.valkyriehub.net/api/raw/ui-lib"
local LoaderUrl = "https://raw.githubusercontent.com/x2Kotaro/Venuz-hub/main/Loader.lua"

---- ============ Session ============ ----

local SessionToken = { }
local SessionConnections = { }

if type(getgenv().ValkyrieCleanup) == "function" then
    pcall(getgenv().ValkyrieCleanup)
end

getgenv().ValkyrieSession = SessionToken

local SetIdentity = setthreadidentity or set_thread_identity or setidentity
    or (syn and syn.set_thread_identity)

local function Elevate()
    if SetIdentity then
        pcall(SetIdentity, 8)
    end
end

local function TrackConnection(Connection)
    if Connection then
        table.insert(SessionConnections, Connection)
    end

    return Connection
end

local filenameConfiguration = FolderConfiguration .. "/" .. "Setting_".. LocalPlayer.Name .. ".json"
local filenameSetting = FolderSettings .. "/" .. "GameConfig_".. LocalPlayer.Name..".json"

---- ============ Loader ============ ----

local FastLoadKey = "ValkyrieFastLoaded"
local LoaderCache = FolderSettings .. "/Loader.cache.lua"

local function CacheLoaderSource()
    if not (writefile and isfile) then return false end

    local Ok, Source = pcall(game.HttpGet, game, LoaderUrl)

    if not Ok or type(Source) ~= "string" or #Source < 32 then
        return isfile(LoaderCache)
    end

    if not loadstring(Source) then
        return isfile(LoaderCache)
    end

    pcall(writefile, LoaderCache, Source)

    return true
end

local function BuildQueueChunk()
    return string.format(
        [[
getgenv().%s = true

local Source

if isfile and isfile(%q) then
    local Ok, Body = pcall(readfile, %q)

    if Ok then Source = Body end
end

if type(Source) ~= "string" or #Source < 32 then
    Source = game:HttpGet(%q)
end

local Chunk = loadstring(Source)

if Chunk then Chunk() end
]],
        FastLoadKey,
        LoaderCache,
        LoaderCache,
        LoaderUrl
    )
end

task.spawn(function()
    if isfolder and makefolder then
        if not isfolder(FolderConfiguration) then makefolder(FolderConfiguration) end
        if not isfolder(FolderSettings) then makefolder(FolderSettings) end
    end

    CacheLoaderSource()
end)
---- ============ Configuration ============ ----

local DefaultConfiguration = {
    ["Transparent"] = true,
    ["AntiAFK"] = true,
    ["AutoRejoin"] = true,
    ["AutoExecutor"] = true,
    ["MinimizeBind"] = "End",
    ["Language"] = "English (US)",
    ["FPSValue"] = 144,
    ["LockFPS"] = false,
}

local function MergeConfiguration(loaded, defaults)
    for key, defaultValue in pairs(defaults) do
        if type(defaultValue) == "table" then
            loaded[key] = MergeConfiguration(loaded[key] or {}, defaultValue)
        else
            if loaded[key] == nil then
                loaded[key] = defaultValue
            end
        end
    end
    return loaded
end

function LoadConfiguration()
    if readfile and isfile and isfile(filenameConfiguration) then
        local data = readfile(filenameConfiguration)
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(data)
        end)

        if success and type(decoded) == "table" then
            getgenv().ConfigurationTable = MergeConfiguration(decoded, DefaultConfiguration)
        else
            getgenv().ConfigurationTable = DefaultConfiguration
        end
    else
        getgenv().ConfigurationTable = DefaultConfiguration
    end
end

function SaveConfiguration()
    if writefile and makefolder then
        if not isfolder("Venuz Hub") then makefolder("Venuz Hub") end
        if not isfolder(FolderConfiguration) then makefolder(FolderConfiguration) end

        local json = HttpService:JSONEncode(getgenv().ConfigurationTable)
        writefile(filenameConfiguration, json)
    end
end

LoadConfiguration()

---- ============ SaveSettings ============ ----

local DefaultSettings = {
    ["Main"] = {
        ["AutoCollectEggs"] = false,
        ["AutoOpenEgg"] = false,
        ["AutoFuseChickens"] = false,
        ["AutoSellChickens"] = false,
        ["AutoChaos"] = false,
        ["SellRarities"] = { "common" },
        ["AutoRebirth"] = false,
        ["AutoUpgradeCoop"] = false,
        ["AutoUpgradeFeeder"] = false,
        ["AutoBuyFeeder"] = false,
        ["AutoBuyRecycler"] = false,
        ["AutoUpgradeRecycler"] = false,
        ["AutoTower"] = false,
        ["TowerSkipBest"] = false,
        ["TowerMinHealth"] = 80,
        ["TowerMinLevel"] = 10,
        ["AutoClaimIncubator"] = false,
        ["AutoUpgradeIncubator"] = false,
        ["AutoInsertIncubator"] = false,
        ["IncubatorChickenId"] = "",
        ["AutoDeclineContinue"] = true,
        ["AutoClaimDailyStreak"] = false,
        ["AutoClaimPlayToday"] = false,
        ["AutoClaimMissions"] = false,
        ["AutoClaimWeeklyPass"] = false,
        ["AutoGrabScrap"] = false,
        ["AutoEventDrops"] = false,
        ["EventDropKinds"] = { "tradeOre", "meteorRock", "ufoPart", "goldCoin", "eggPod" },
        ["AutoHotEgg"] = false,
        ["AutoBossFight"] = false,
        ["AutoUfoBeam"] = false,
        ["AutoEncourage"] = false,
        ["ScrapLimit"] = 12,
        ["AutoClaimRebirthMilestones"] = false,
        ["AutoArenaTeam"] = false,
        ["AutoArenaBattle"] = false,
        ["AutoArenaClaim"] = false,
        ["ArenaAutoAbility"] = false,
        ["ArenaSkipBands"] = { "harder" },
        ["ArenaTeamMode"] = "Strength",
        ["AutoProtectMutations"] = true,
        ["FuseUseLocks"] = true,
        ["FuseFodder"] = true,
        ["SellKeepGeneDonors"] = true,
        ["SellKeepFodder"] = 2,
        ["TowerBestFighter"] = true,
        ["FuseChickenId"] = "",
        ["EventChickenId"] = "",
        ["OpenEggKinds"] = { },
    },
}

local function MergeSettings(defaults, loaded)
    for k,v in pairs(defaults) do
        if type(v) == "table" then
            if type(loaded[k]) ~= "table" then
                loaded[k] = v
            else
                MergeSettings(v, loaded[k])
            end
        else
            if loaded[k] == nil then
                loaded[k] = v
            end
        end
    end
end

function LoadSettings()
    if readfile and isfile and isfile(filenameSetting) then
        local loaded = HttpService:JSONDecode(readfile(filenameSetting))
        MergeSettings(DefaultSettings, loaded)
        getgenv().Settings = loaded
    else
        getgenv().Settings = DefaultSettings
    end
end

function SaveSetting()
    if writefile and makefolder then
        if not isfolder("Venuz Hub") then makefolder("Venuz Hub") end
        if not isfolder(FolderSettings) then makefolder(FolderSettings) end
        local json = HttpService:JSONEncode(getgenv().Settings)
        writefile(filenameSetting, json)
    end
end

LoadSettings()

local SafeStart = false

if SafeStart and type(getgenv().Settings.Main) == "table" then
    for Key, Value in pairs(getgenv().Settings.Main) do
        if type(Value) == "boolean" then
            getgenv().Settings.Main[Key] = false
        end
    end
end

if type(getgenv().Settings.Main) == "table" and getgenv().Settings.Main.WalkSpeed ~= nil then
    getgenv().Settings.Main.WalkSpeed = nil
    getgenv().Settings.Main.TweenSpeed = nil
    getgenv().Settings.Main.GrabMethod = nil

    SaveSetting()
end

if getgenv().Configuration and next(getgenv().Configuration) then
    for key, value in pairs(getgenv().Configuration) do
        if getgenv().Settings[key] ~= nil then
            getgenv().Settings[key] = value
        end
    end
    SaveSetting()
end

---- ============ Interface ============ ----

Elevate()

local Library do
    local Ok, Source = pcall(game.HttpGet, game, LibraryUrl, true)

    if not (Ok and type(Source) == "string" and #Source > 50000) then
        error(string.format(
            "[ValkyrieHub] %s did not return the UI library (%s, %d bytes -- expected 100000+)",
            LibraryUrl,
            Ok and "ok" or tostring(Source),
            Ok and #tostring(Source) or 0
        ), 0)
    end

    local Chunk, Err = loadstring(Source)

    if not Chunk then
        error("[ValkyrieHub] UI library did not compile: " .. tostring(Err), 0)
    end

    Library = Chunk()

    if type(Library) ~= "table" then
        error("[ValkyrieHub] UI library ran but returned " .. typeof(Library), 0)
    end
end

local Accent = Color3.fromRGB(255, 80, 80)
local Gradient = Color3.fromRGB(120, 20, 20)

Library.Theme.Accent = Accent
Library.Theme.AccentGradient = Gradient
Library:ChangeTheme("Accent", Accent)
Library:ChangeTheme("AccentGradient", Gradient)

Library:AddLanguages({
    th = {
        ["Configuration"] = "ตั้งค่า",
        ["Interface"] = "ตั้งค่าหน้าต่าง",
        ["Window Transparency"] = "ทำหน้าต่างโปร่งใส",
        ["Anti-AFK"] = "กันหลุด AFK",
        ["Auto Rejoin"] = "เข้าเกมใหม่อัตโนมัติ",
        ["Auto Executor"] = "รันสคริปต์ตอนย้ายเซิร์ฟ",
        ["Minimize Bind"] = "ปุ่มย่อ/เปิดเมนู",
        ["FPS"] = "FPS",
        ["FPS Value"] = "ค่า FPS",
        ["FPS Lock"] = "ล็อก FPS",
        ["Language"] = "ภาษา",
        ["Select Language"] = "เลือกภาษา",
        ["Change Language"] = "เปลี่ยนภาษา",
        ["Script | Loader"] = "สคริปต์ | โหลดเดอร์",
        ["Script Loaded Successfully"] = "โหลดสคริปต์สำเร็จ",
        ["Search"] = "ค้นหา",
        ["Close"] = "ปิด",
        ["Automatic"] = "อัตโนมัติ",
        ["Chickens"] = "ไก่",
        ["Chicken automation"] = "ระบบจัดการไก่อัตโนมัติ",
        ["Auto Collect Eggs"] = "เก็บไข่อัตโนมัติ",
        ["Auto Open Egg"] = "เปิดไข่อัตโนมัติ",
        ["Egg Types"] = "ชนิดไข่ที่จะเปิด",
        ["blessed"] = "ไข่ศักดิ์สิทธิ์",
        ["colossus"] = "ไข่ยักษ์",
        ["charm"] = "ไข่เครื่องราง",
        ["storm"] = "ไข่สายฟ้า",
        ["trick"] = "ไข่หลอกลวง",
        ["ascension"] = "ไข่เลื่อนขั้น",
        ["circuit"] = "ไข่วงจร",
        ["haunt"] = "ไข่ผีสิง",
        ["crown"] = "ไข่ราชวงศ์",
        ["feed"] = "ไข่เกา",
        ["rival"] = "ไข่คู่แค้น",
        ["demonic"] = "ไข่ปีศาจ",
        ["barn"] = "ไข่รัง",
        ["ordnance"] = "ไข่ระเบิด",
        ["golden"] = "ไข่โชคลาภ",
        ["fang"] = "ไข่เขี้ยว",
        ["diner"] = "ไข่ร้านอาหาร",
        ["void"] = "ไข่ความว่างเปล่า",
        ["meme"] = "ไข่มีม",
        ["arena"] = "ไข่อารีน่า",
        ["bloom"] = "ไข่บาน",
        ["hotEgg"] = "ไข่ร้อนแรง",
        ["Auto Fuse Chickens"] = "รวมไก่อัตโนมัติ",
        ["Auto Sell Chickens"] = "ขายไก่อัตโนมัติ",
        ["Auto Chaos"] = "ส่งไก่ลงบ่อสู้อัตโนมัติ",
        ["Sell Rarity"] = "ความหายากที่จะขาย",
        ["Upgrade"] = "อัปเกรด",
        ["Coop and rebirth automation"] = "อัปเกรดเล้าและรีเบิร์ธอัตโนมัติ",
        ["Auto Rebirth"] = "รีเบิร์ธอัตโนมัติ",
        ["Auto Upgrade Coop"] = "ขยายเล้าอัตโนมัติ",
        ["Auto Upgrade Feeder"] = "อัปเกรดรางอาหารอัตโนมัติ",
        ["Auto Buy Feeder"] = "ซื้อรางอาหารอัตโนมัติ",
        ["Auto Upgrade Recycler"] = "อัปเกรดเครื่องรีไซเคิลอัตโนมัติ",
        ["Auto Buy Recycler"] = "ซื้อเครื่องรีไซเคิลอัตโนมัติ",
        ["Tower"] = "ทาวเวอร์",
        ["Tower run automation"] = "ระบบไต่ทาวเวอร์อัตโนมัติ",
        ["Auto Tower"] = "ไต่ทาวเวอร์อัตโนมัติ",
        ["Skip to Best Floor"] = "ข้ามไปชั้นสูงสุด",
        ["Min Health"] = "เลือดขั้นต่ำก่อนเริ่ม",
        ["Auto Decline Continue"] = "ปฏิเสธการต่อรอบอัตโนมัติ",
        ["Start Run"] = "เริ่มรอบทาวเวอร์",
        ["Surrender"] = "ยอมแพ้",
        ["Misc"] = "อื่น ๆ",
        ["Rewards"] = "ของรางวัล",
        ["Reward claim automation"] = "รับของรางวัลอัตโนมัติ",
        ["Auto Claim Daily Streak"] = "รับรางวัลล็อกอินรายวัน",
        ["Auto Claim Play Today"] = "รับรางวัลเวลาเล่นวันนี้",
        ["Auto Claim Missions"] = "รับรางวัลภารกิจ",
        ["Auto Claim Weekly Pass"] = "รับรางวัลพาสรายสัปดาห์",
        ["Scrap"] = "เศษเหล็ก",
        ["Scrap automation"] = "ระบบเก็บเศษเหล็กอัตโนมัติ",
        ["Auto Grab Scrap"] = "เก็บเศษเหล็กอัตโนมัติ",
        ["Limit Scrap"] = "จำนวนเศษเหล็กต่อรอบ",
        ["Event"] = "อีเวนต์",
        ["World event automation"] = "ระบบอีเวนต์อัตโนมัติ",
        ["Auto Event Drops"] = "เก็บของอีเวนต์อัตโนมัติ",
        ["Drop Kinds"] = "ของที่จะเก็บ",
        ["Auto Hot Egg"] = "แย่งไข่ร้อนอัตโนมัติ",
        ["Auto Boss Fight"] = "ส่งไก่ตีบอสอัตโนมัติ",
        ["Auto UFO Beam"] = "ส่งไก่เข้าลำแสง UFO",
        ["Auto Encourage"] = "เชียร์ไก่อัตโนมัติ",
        ["Auto Claim Rebirth Milestones"] = "รับรางวัลไมล์สโตนรีเบิร์ธอัตโนมัติ",
        ["Arena"] = "อารีน่า",
        ["Arena battle automation"] = "ระบบสู้อารีน่าอัตโนมัติ",
        ["Auto Equip Best Team"] = "จัดทีมไก่แรงสุดอัตโนมัติ",
        ["Auto Arena Battle"] = "สู้อารีน่าอัตโนมัติ",
        ["Skip Bands"] = "ข้ามคู่ต่อสู้ประเภท",
        ["Auto Ability"] = "ใช้สกิลอัตโนมัติ",
        ["Auto Claim Arena Rewards"] = "รับรางวัลแรงก์อารีน่าอัตโนมัติ",
        ["Equip Best Team"] = "จัดทีมไก่แรงสุด",
        ["Progression"] = "ความคืบหน้า",
        ["World"] = "โลก",
        ["Eggs"] = "ไข่",
        ["Egg collecting and hatching"] = "เก็บไข่และฟักไข่",
        ["Fusion"] = "รวมไก่",
        ["Fusion planning"] = "ระบบวางแผนรวมไก่",
        ["Roster"] = "คลังไก่",
        ["Roster upkeep"] = "จัดการคลังไก่",
        ["Pit"] = "บ่อสู้",
        ["Pit automation"] = "ระบบบ่อสู้อัตโนมัติ",
        ["Rebirth"] = "รีเบิร์ธ",
        ["Rebirth automation"] = "ระบบรีเบิร์ธอัตโนมัติ",
        ["Plot"] = "แปลง",
        ["Coop and recycler upgrades"] = "อัปเกรดเล้าและเครื่องรีไซเคิล",
        ["Team"] = "ทีม",
        ["Arena team selection"] = "ระบบจัดทีมอารีน่า",
        ["Battle"] = "การต่อสู้",
        ["Arena battles"] = "สู้อารีน่า",
        ["Arena rank rewards"] = "รางวัลแรงก์อารีน่า",
        ["Daily"] = "รายวัน",
        ["Daily reward claims"] = "รับรางวัลรายวัน",
        ["Progress"] = "ความคืบหน้า",
        ["Mission and pass claims"] = "รับรางวัลภารกิจและพาส",
        ["Keep Mutations"] = "เก็บไก่กลายพันธุ์",
        ["Use Fusion Locks"] = "ล็อกเลเวลและสกิลตอนรวม",
        ["Fuse Fodder"] = "ปั่นไก่ตัวรองด้วย",
        ["Keep Gene Donors"] = "เก็บไก่ที่มียีนดี",
        ["Keep Per Rarity"] = "เก็บไว้กี่ตัวต่อความหายาก",
        ["Send Best Fighter"] = "ส่งไก่ที่แรงที่สุดขึ้นทาวเวอร์",
        ["Team Mode"] = "เกณฑ์จัดทีม",
        ["Min Level"] = "เลเวลขั้นต่ำก่อนเริ่ม",
        ["Incubator"] = "ตู้ฟักไข่",
        ["Incubator egg claiming"] = "เก็บไข่จากตู้ฟักอัตโนมัติ",
        ["Auto Claim Incubator Eggs"] = "เก็บไข่จากตู้ฟักอัตโนมัติ",
        ["Auto Upgrade Incubator"] = "อัปเกรดตู้ฟักอัตโนมัติ",
        ["Auto Insert Chicken"] = "ใส่ไก่เข้าตู้ฟักอัตโนมัติ",
        ["Select Chicken"] = "เลือกไก่",
        ["Select Fuse Target"] = "เลือกไก่ที่จะรวม",
        ["Select Event Fighter"] = "เลือกไก่ลงอีเว้นต์",
    }
})

local LocaleByLanguage = {
    ["English (US)"] = "en",
    ["Thai"] = "th"
}

local function ApplyLanguage(Name)
    Library:SetLocale(LocaleByLanguage[Name] or "en")
end

ApplyLanguage(getgenv().ConfigurationTable.Language)

local Window = Library:Window({
    Name = "Valkyrie Hub",
    SubName = "by Phoenix",
    Logo = IconValkyrie
})

local KeybindList = Library:KeybindList("Keybinds")

Window:Category("General")

---- ============ Game ============ ----

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ScanSliceSeconds = 0.008
local ScanSliceStep = 512

-- answers whether Visit asked to stop, and how many tables it was actually handed. The count
-- is what tells a game whose tables have moved apart from an executor whose getgc is not
-- giving up the game's memory at all -- see the error at the end of the module sweep.
local function ScanGarbage(Visit)
    if type(getgc) ~= "function" then return false, 0 end

    local Ok, Objects = pcall(getgc, true)

    if not (Ok and type(Objects) == "table") then return false, 0 end

    local Since = 0
    local Tables = 0
    local SliceStart = os.clock()

    for Index = 1, #Objects do
        local Value = Objects[Index]

        if type(Value) == "table" then
            Tables = Tables + 1

            local Fine, Stop = pcall(Visit, Value)

            if Fine and Stop then return true, Tables end
        end

        Since = Since + 1

        if Since >= ScanSliceStep then
            Since = 0

            if os.clock() - SliceStart > ScanSliceSeconds then
                task.wait()

                SliceStart = os.clock()
            end
        end
    end

    return false, Tables
end

local Modules = { }

do
    if type(getgc) ~= "function" then
        error("[ValkyrieHub] this executor has no getgc, which is how the game's own modules are reached without require", 0)
    end

    local Patterns = {
        DataService = function(Value)
            local Client = rawget(Value, "client")

            return type(Client) == "table" and type(rawget(Client, "get")) == "function"
        end,

        GameConfig = function(Value)
            return type(rawget(Value, "guard")) == "table"
                and type(rawget(Value, "scrap")) == "table"
                and type(rawget(Value, "rebirth")) == "table"
        end,

        Catalog = function(Value)
            return type(rawget(Value, "chickenTypes")) == "table"
                and type(rawget(Value, "generators")) == "table"
        end,

        CoopView = function(Value)
            return type(rawget(Value, "canExpand")) == "function"
                and type(rawget(Value, "canBuyGenerator")) == "function"
        end,

        RecyclerView = function(Value)
            return rawget(Value, "LockedAttr") == "recyclerLocked"
                and type(rawget(Value, "floorUnlocked")) == "function"
        end,

        IncubatorView = function(Value)
            return rawget(Value, "LockedAttr") == "incubatorLocked"
                and type(rawget(Value, "canUpgrade")) == "function"
                and type(rawget(Value, "upgradeCost")) == "function"
        end,

        DailyView = function(Value)
            return rawget(Value, "DAY_KEY") == "d"
                and type(rawget(Value, "sessionReady")) == "function"
        end,

        MissionView = function(Value)
            return type(rawget(Value, "SCOPES")) == "table"
                and type(rawget(Value, "stateOf")) == "function"
        end,

        PassView = function(Value)
            return type(rawget(Value, "claimKey")) == "function"
                and type(rawget(Value, "state")) == "function"
                and type(rawget(Value, "track")) == "function"
        end,

        RebirthBonus = function(Value)
            return type(rawget(Value, "requirementFloor")) == "function"
                and type(rawget(Value, "pointsFor")) == "function"
        end,

        -- the game runs an A/B test on the rebirth requirement curve. The control arm keeps the
        -- old requirementFloor, the variant arm uses requirementFloorV2, which asks for up to two
        -- extra tower floors past rebirth 240. Reading the floor without the arm is what made the
        -- script call a rebirth ready that the server then refused.
        RebirthExperiment = function(Value)
            return rawget(Value, "ATTRIBUTE") == "rebirth_requirement_v2"
                and type(rawget(Value, "usesV2")) == "function"
                and type(rawget(Value, "armOf")) == "function"
        end,

        RebirthMilestones = function(Value)
            return type(rawget(Value, "nth")) == "function"
                and type(rawget(Value, "reachedCount")) == "function"
                and type(rawget(Value, "indexAt")) == "function"
        end,

        Mutations = function(Value)
            local Found = 0

            for Key, Def in pairs(Value) do
                if type(Key) ~= "string" or type(Def) ~= "table" then return false end
                if rawget(Def, "id") ~= Key then return false end
                if type(rawget(Def, "chance")) ~= "number" then return false end
                if type(rawget(Def, "boost")) ~= "table" then return false end

                Found = Found + 1
            end

            return Found > 0
        end,

        PitZone = function(Value)
            return typeof(rawget(Value, "center")) == "Vector3"
                and type(rawget(Value, "contains")) == "function"
        end,

        RosterCap = function(Value)
            return rawget(Value, "PASS") == "rosterSlots"
                and type(rawget(Value, "of")) == "function"
        end,

        FusionRules = function(Value)
            return type(rawget(Value, "cost")) == "function"
                and type(rawget(Value, "ascendChance")) == "function"
                and type(rawget(Value, "RARITY_ORDER")) == "table"
        end,

        ElevatorCatalog = function(Value)
            return type(rawget(Value, "elevatorCost")) == "function"
        end,

        -- Two Charm atoms and nothing else: order is what the player told the chicken to do,
        -- where is where the bird actually is this frame. The rebirth screen gates its confirm
        -- button on exactly this pair, and so does the server, so reading it is strictly ahead
        -- of the ovState attribute the plot carries.
        ChickenMode = function(Value)
            if type(rawget(Value, "order")) ~= "function" then return false end
            if type(rawget(Value, "where")) ~= "function" then return false end

            local Keys = 0

            for _ in pairs(Value) do
                Keys = Keys + 1

                if Keys > 2 then return false end
            end

            return Keys == 2
        end,

        -- the HUD's window flags. Opening one closes the rest, which is why rebirth() is the
        -- only supported way to put the Rebirth screen on screen.
        WindowState = function(Value)
            return type(rawget(Value, "EXCLUSIVE")) == "table"
                and type(rawget(Value, "rebirth")) == "function"
                and type(rawget(Value, "busy")) == "function"
        end,
    }

    local Required = { "DataService", "GameConfig", "Catalog" }

    local function MissingRequired()
        for _, Name in ipairs(Required) do
            if not Modules[Name] then return true end
        end

        return false
    end

    -- how many tables the last sweep was actually handed, kept for the error below
    local Scanned = 0

    local function Sweep()
        local Left = 0

        for _ in pairs(Patterns) do
            Left = Left + 1
        end

        if Left == 0 then return end

        local _, Seen = ScanGarbage(function(Value)
            for Name, Test in pairs(Patterns) do
                if Test(Value) then
                    Modules[Name] = Value
                    Patterns[Name] = nil
                    Left = Left - 1
                end
            end

            return Left == 0
        end)

        Scanned = Seen or 0
    end

    -- These tables only exist once the game's own client code has required the modules that
    -- hold them, and on a cold join that happens well after the executor is ready to run.
    -- Three attempts a second and a half apart gave up after four and a half seconds, which is
    -- inside the window a slow join is still loading in -- so a perfectly good session failed
    -- on nothing but its own timing. This keeps sweeping for half a minute and stops the moment
    -- everything required is in hand, which on a warm join is still the first pass.
    local Deadline = os.clock() + 30

    repeat
        Sweep()

        if not MissingRequired() then break end

        task.wait(1.5)
    until os.clock() > Deadline

    if MissingRequired() then
        local Found, Missing = { }, { }

        for Name in pairs(Modules) do
            table.insert(Found, Name)
        end

        for _, Name in ipairs(Required) do
            if not Modules[Name] then
                table.insert(Missing, Name)
            end
        end

        table.sort(Found)

        -- The three ways this fails do not look alike, and the old message could not tell them
        -- apart: nothing scanned is an executor problem, nothing matched is the wrong game, and
        -- some matched is this game after an update that moved the field names.
        local Hint

        if Scanned == 0 then
            Hint = "  getgc handed back no tables at all -- this executor is not giving up the game's memory"
        elseif #Found == 0 then
            Hint = "  not one pattern matched, which is what running this in the wrong game looks like.\n"
                .. "  GFC.lua is the Grow a Chicken Fighter build"
        else
            Hint = "  some patterns matched and some did not, which is what a game update looks like:\n"
                .. "  the field names the missing patterns look for have moved"
        end

        error(string.format(
            "[ValkyrieHub] gave up looking for the game's own tables after 30s\n"
            .. "  missing: %s\n"
            .. "  found:   %s\n"
            .. "  scanned: %d tables\n"
            .. "  place:   %d (universe %d)\n"
            .. "%s",
            table.concat(Missing, ", "),
            #Found > 0 and table.concat(Found, ", ") or "nothing",
            Scanned,
            game.PlaceId,
            game.GameId,
            Hint
        ), 0)
    end
end

Elevate()

local DataService = Modules.DataService
local GameConfig = Modules.GameConfig
local Catalog = Modules.Catalog

local function ViewOrStub(Name, Stub)
    local View = Modules[Name]

    if View then
        return View
    end

    return Stub
end

local CoopView = ViewOrStub("CoopView", {
    canExpand = function() return false end,
    canUpgrade = function() return false end,
    canBuyGenerator = function() return false end,
    expandCost = function() return math.huge end,
    upgradeCost = function() return math.huge end,
    buyGeneratorCost = function() return math.huge end
})

local RecyclerView = ViewOrStub("RecyclerView", {
    LockedAttr = "recyclerLocked",
    BusyAttr = "recyclerBusy",
    canUpgrade = function() return false end,
    floorUnlocked = function() return false end,
    upgradeCost = function() return math.huge end
})

local IncubatorView = ViewOrStub("IncubatorView", {
    LockedAttr = "incubatorLocked",
    maxLevel = 0,
    canUpgrade = function() return false end,
    upgradeCost = function() return math.huge end,
    cap = function() return 0 end
})

local DailyView = ViewOrStub("DailyView", {
    DAY_KEY = "d",
    sessionKey = function(Index) return "s" .. tostring(Index) end,
    sessionReady = function() return false end
})

local MissionView = ViewOrStub("MissionView", {
    SCOPES = { },
    active = function() return { } end,
    stateOf = function() return "locked" end
})

local PassView = ViewOrStub("PassView", {
    state = function() return "locked" end,
    track = function() return "free" end
})

local RebirthBonus = ViewOrStub("RebirthBonus", {
    requirementFloor = function() return math.huge end,
    requirementFloorFor = function() return math.huge end,
    ready = function() return false end
})

local RebirthExperiment = ViewOrStub("RebirthExperiment", {
    VARIANT = "variant",
    usesV2 = function() return false end
})

local RebirthMilestones = ViewOrStub("RebirthMilestones", {
    nth = function() return nil end,
    reachedCount = function() return 0 end,
    indexAt = function() return nil end
})

local RosterCap = ViewOrStub("RosterCap", {
    PASS = "rosterSlots",
    of = function() return math.huge end
})

-- nil out of the stub, not a made-up state: the caller falls back to the plot attribute rather
-- than acting on a "corral" that was never read from anything.
local ChickenMode = ViewOrStub("ChickenMode", {
    order = function() return nil end,
    where = function() return nil end
})

local WindowState = ViewOrStub("WindowState", {
    EXCLUSIVE = { },
    rebirth = function() return false end,
    busy = function() return false end
})

local FusionRules = ViewOrStub("FusionRules", {
    cost = function() return nil end,
    GENE_KEYS = { "vigor", "furia", "velocidad", "impetu", "fertility" }
})

local PitZone = Modules.PitZone or {
    center = Vector3.new(0, 0, 0),
    radius = GameConfig.pit.radius
}

local RemoteFolder = ReplicatedStorage:WaitForChild("Remotes")

local function RemoteByName(Name)
    return RemoteFolder:FindFirstChild(Name)
end

-- Most remotes share one lane: a slow, conservative budget that keeps every kind of
-- automation under the same 8-call/10s ceiling. UpgradeGenerator gets its own lane instead --
-- a full plot at max level is 294 calls, and the game's own CoopController puts no throttle
-- on it at all, so the shared lane's caution was entirely this script's, not the server's.
-- A remote with no lane entry falls through the metatable to the old shared numbers.
local SendGap = setmetatable({ UpgradeGenerator = 0.15 }, { __index = function() return 0.5 end })
local RemoteGap = setmetatable({ UpgradeGenerator = 0.3 }, { __index = function() return 1.5 end })
local WindowSeconds = 10
local WindowCalls = setmetatable({ UpgradeGenerator = 30 }, { __index = function() return 8 end })

local LastSendAt = { }
local LastSendPerRemote = { }
local SendTimes = { }
local HoldAllUntil = 0

local function BudgetAllows(Name)
    local Now = os.clock()

    if Now < HoldAllUntil then return false end

    -- keyed by lane rather than by remote name: every remote without its own entry in
    -- SendGap/RemoteGap/WindowCalls above shares the "global" lane's clock and call
    -- history, exactly as when this was one flat budget
    local LaneKey = (Name == "UpgradeGenerator") and Name or "global"

    if Now - (LastSendAt[LaneKey] or 0) < SendGap[Name] then return false end
    if Now - (LastSendPerRemote[Name] or 0) < RemoteGap[Name] then return false end

    local Times = SendTimes[LaneKey]

    if not Times then
        Times = { }
        SendTimes[LaneKey] = Times
    end

    for Index = #Times, 1, -1 do
        if Now - Times[Index] > WindowSeconds then
            table.remove(Times, Index)
        end
    end

    if #Times >= WindowCalls[Name] then
        return false
    end

    LastSendAt[LaneKey] = Now
    LastSendPerRemote[Name] = Now
    table.insert(Times, Now)

    return true
end

local BudgetWaitSeconds = 4

local function BudgetWait(Name)
    if BudgetAllows(Name) then return true end

    local Deadline = os.clock() + BudgetWaitSeconds

    while os.clock() < Deadline do
        task.wait(0.1)

        if BudgetAllows(Name) then return true end
    end

    return false
end

local function NoteReply(Name, Reply)
    if type(Reply) ~= "table" then return end

    if Reply.error == "rateLimited" then
        HoldAllUntil = os.clock() + 30
    end
end

local Remotes = {
    defs = setmetatable({ }, {
        __index = function(_, Name)
            return Name
        end
    }),

    fire = function(Name, ...)
        local Remote = RemoteByName(Name)

        if not Remote then return false end

        if not BudgetWait(Name) then
            return false
        end

        Remote:FireServer(...)

        return true
    end,

    invoke = function(Name, ...)
        local Remote = RemoteByName(Name)

        if not Remote then return end

        if not BudgetWait(Name) then
            return
        end

        local Reply = Remote:InvokeServer(...)

        NoteReply(Name, Reply)

        return Reply
    end,

    onClient = function(Name, Handler)
        local Remote = RemoteByName(Name)

        if Remote then
            return Remote.OnClientEvent:Connect(Handler)
        end
    end
}

local Rarities = { "common", "uncommon", "rare", "epic", "legendary", "mythic", "divine", "celestial", "cosmic", "secret" }

local ScrapTravel = GameConfig.scrap.travel

-- The roster carries the SAVED level and xp, and for the chicken standing on the plot those are
-- stale between saves: a rebirth writes level 1, and the roster goes on saying 1 while the bird
-- eats its way back up to 38. The live pair is replicated under a key of its own, `vitals`, and
-- the game overlays it onto the active chicken before anything is allowed to read a level --
-- DataController.rosterView does exactly this, and so does every screen in the game.
--
-- Read straight, the roster told Auto Tower the fighter was level 1 forever, so a Min Level of
-- 10 was never satisfied and the run never started. It also fed a level of 1 to Fight.Stats, to
-- the fusion planner and to the arena team, which all price a chicken off its level.
local function GetRoster()
    local Ok, Roster = pcall(function()
        return DataService.client:get("roster")
    end)

    if not (Ok and type(Roster) == "table") then return end
    if type(Roster.chickens) ~= "table" then return Roster end

    local Fine, Vitals = pcall(function()
        return DataService.client:get("vitals")
    end)

    if not (Fine and type(Vitals) == "table" and Vitals.id ~= nil) then return Roster end

    -- copied rather than written through: what came back is the data service's own table, and
    -- the game is reading it too
    local Copy = table.clone(Roster)
    local Chickens = table.clone(Roster.chickens)

    for Index, Chicken in ipairs(Chickens) do
        if Chicken.id == Vitals.id then
            local Live = table.clone(Chicken)

            Live.level = Vitals.level or Live.level
            Live.xp = Vitals.xp or Live.xp
            Live.health = Vitals.health or Live.health

            Chickens[Index] = Live

            break
        end
    end

    Copy.chickens = Chickens

    return Copy
end

local function GetData(Key)
    local Ok, Value = pcall(function()
        return DataService.client:get(Key)
    end)

    if Ok then
        return Value
    end
end

local function GetCoop()
    local Coop = GetData("coop")

    if type(Coop) == "table" and type(Coop.generators) == "table" then
        return Coop
    end
end

-- The first feeder is the whole economy after a rebirth, and it is bought before anything else
-- gets a share of the purse. It is what puts corn in front of the chicken, corn is what levels
-- the chicken, and the chicken's level is what the tower stands and waits for -- so a coop
-- upgrade or a recycler that spent the money first left every one of those stalled behind it.
--
-- Held back only while the coop has no feeder at all. Once one is standing, the rest of the plot
-- spends as it always did.
local function FeederReserve()
    local Coop = GetCoop()

    if not Coop then return 0 end

    local Feeders = #Coop.generators

    if Feeders > 0 then return 0 end
    if not CoopView.canBuyGenerator(Coop.slots, Feeders) then return 0 end

    local Cost = CoopView.buyGeneratorCost(Feeders)

    return type(Cost) == "number" and Cost or 0
end

-- `Reserved` is for the one purchase the reserve is being held for: the feeder itself.
local function CanAfford(Cost, Reserved)
    if type(Cost) ~= "number" then return true end

    local Money = GetData("money")

    if type(Money) ~= "number" then return true end

    if not Reserved then
        Money = Money - FeederReserve()
    end

    return Money >= Cost
end

local function RecyclerState()
    local Scrap = GetData("scrap")

    if type(Scrap) ~= "table" then return end

    local Level = Scrap.recyclerLevel or 0
    local Rebirth = GetData("rebirth")
    local Tower = GetData("tower")

    if LocalPlayer:GetAttribute(RecyclerView.LockedAttr) == true then return end
    if LocalPlayer:GetAttribute(RecyclerView.BusyAttr) == true then return end
    if not RecyclerView.canUpgrade(Level, type(Rebirth) == "table" and Rebirth.count or 0) then return end
    if not RecyclerView.floorUnlocked(Level, type(Tower) == "table" and Tower.best or 0) then return end

    return Level
end

local function GetRootPart()
    local Character = LocalPlayer.Character

    return Character and Character:FindFirstChild("HumanoidRootPart")
end

local function RarityOf(Chicken)
    if Chicken.rarity then
        return Chicken.rarity
    end

    local TypeDef = Catalog.chickenTypes[Chicken.typeId] or Catalog.defaultChickenType

    return TypeDef and TypeDef.rarity or "common"
end

local function MyChickenBody()
    local Bodies = workspace:FindFirstChild("ChickenBodies")

    if not Bodies then return end

    local Owner = tostring(LocalPlayer.UserId)

    for _, Body in ipairs(Bodies:GetChildren()) do
        if tostring(Body:GetAttribute("ovOwner")) == Owner then
            return Body
        end
    end
end

local function ChickenStateOf(Body)
    if not Body then return nil end

    local State = Body:GetAttribute("ovState")

    if type(State) ~= "string" or State == "" then
        return "corral"
    end

    return State
end

local function MyArena()
    local Arenas = workspace:FindFirstChild("Arenas")
    local Plot = LocalPlayer:GetAttribute("Plot")

    if not (Arenas and Plot) then return end

    return Arenas:FindFirstChild("Arena" .. tostring(Plot))
end

local function TowerBest()
    local Tower = GetData("tower")

    return type(Tower) == "table" and Tower.best or 0
end

-- The level of the rival waiting on a floor, by the same formula the game's TowerFloor.at runs.
-- It is what lets the tower measure a fighter against the floor it would actually meet instead
-- of against a flat number that means something different on floor 1 and on floor 45.
local function TowerRivalLevel(Floor)
    local Formula = GameConfig.tower and GameConfig.tower.formula
    local Step = (Formula and tonumber(Formula.levelStep)) or 1.2
    local Index = math.max(1, math.floor(tonumber(Floor) or 1))

    return math.max(1, math.floor((Index - 1) * Step + 0.5))
end

-- A deadline rather than a flag, and that distinction is the whole of it: the tower loop can
-- only clear its own block from inside its body, and its body sits behind ChickenClaim("tower"),
-- which a raised block is exactly what denies. A boolean latched here stayed latched, and Auto
-- Tower was dead until the script was re-executed.
local TowerBlockedUntil = 0

-- The rail badge on the left of the screen is the same readiness the server enforces: ArenaRail
-- draws "!" in it the moment RebirthBonus.ready passes with the player's own experiment arm, and
-- a bare number when the badge is only carrying unclaimed milestones. Reading the badge means the
-- script never has to guess which requirement curve this account was assigned.
--
-- nil when the rail is not mounted yet, so the caller can fall back instead of reading a
-- missing badge as "not ready" and stalling Auto Rebirth on a fresh join.
local function RebirthBadgeReady()
    local Badge = LocalPlayer:FindFirstChild("PlayerGui")

    for _, Name in ipairs({ "ArenaSideRail", "Frame", "rail", "Frame", "Rebirth", "badge" }) do
        if not Badge then return nil end

        Badge = Badge:FindFirstChild(Name)
    end

    if not Badge then return nil end
    if Badge.Visible ~= true then return false end

    local Text = Badge:FindFirstChild("Txt")

    if not (Text and Text:IsA("TextLabel")) then return nil end

    -- "!" is rebirth ready. A digit is the unclaimed milestone count and says nothing about
    -- whether the tower requirement is met.
    return Text.Text == "!"
end

local function RebirthReady()
    local Badge = RebirthBadgeReady()

    if Badge ~= nil then return Badge end

    local Rebirth = GetData("rebirth")
    local Tower = GetData("tower")

    if not (type(Rebirth) == "table" and type(Tower) == "table") then return false end

    local Count = Rebirth.count or 0
    local Best = Tower.best or 0
    local UsesV2 = false

    pcall(function()
        UsesV2 = RebirthExperiment.usesV2(LocalPlayer) == true
    end)

    local Floor = RebirthBonus.requirementFloorFor(Count, UsesV2)

    if type(Floor) ~= "number" then
        Floor = RebirthBonus.requirementFloor(Count)
    end

    return Best >= Floor
end

local function EventLive()
    return workspace:GetAttribute("EventPhase") == "live"
end

local EventChickenFlags = {
    chickenBoss = "AutoBossFight",
    ufo = "AutoUfoBeam"
}

local ChickenPriority = { rebirth = 1, event = 2, tower = 3, chaos = 4 }

local function RebirthWantsChicken()
    return getgenv().Settings.Main.AutoRebirth == true and RebirthReady()
end

local function EventChickenFlag()
    if not EventLive() then return nil end

    local Flag = EventChickenFlags[workspace:GetAttribute("EventId")]

    if Flag and getgenv().Settings.Main[Flag] == true then
        return Flag
    end
end

-- The level of the chicken a run would actually send up. With Send Best Fighter on that is the
-- strongest of the flock, since the run swaps to it before starting; without it, whichever is
-- active. Fight.Best scores rarity and genes as well as level, so the best it picks is not
-- always the highest level -- for a floor on how weak a fighter may be, the highest level is
-- close enough, and it is defined here rather than there because Fight comes later in the file.
local function TowerFighterLevel()
    local Roster = GetRoster()

    if type(Roster) ~= "table" or type(Roster.chickens) ~= "table" then return end

    local Best, Active

    for _, Chicken in ipairs(Roster.chickens) do
        local Level = tonumber(Chicken.level) or 1

        if Chicken.id == Roster.activeId then
            Active = Level
        end

        if Best == nil or Level > Best then
            Best = Level
        end
    end

    if getgenv().Settings.Main.TowerBestFighter then return Best end

    return Active
end

local function TowerWantsChickenRaw()
    if not getgenv().Settings.Main.AutoTower then return false end

    local Arena = MyArena()

    if not Arena then return false end

    -- a run already under way is never interrupted, whatever the gates below would say
    if Arena:GetAttribute("TowerActive") == true then return true end

    if os.clock() < TowerBlockedUntil then return false end

    -- The level floor stands the tower down rather than idling inside its own loop, and that is
    -- the point: a chicken fresh out of a rebirth is level 1 and levels up by fighting in the
    -- pit, so holding the claim while waiting for a level would starve the loop that raises it.
    --
    -- The slider is taken at its word, floor 1 included. It was briefly capped by the rival
    -- waiting on the next floor, which let a level 1 bird straight out of a rebirth walk into
    -- the tower because floor 1's rival is level 1 as well -- which is not what a floor of 10
    -- was set to mean.
    local MinLevel = tonumber(getgenv().Settings.Main.TowerMinLevel) or 1

    if MinLevel > 1 then
        local Level = TowerFighterLevel()

        if Level == nil or Level < MinLevel then return false end
    end

    return true
end

local function ChickenOwner()
    if RebirthWantsChicken() then return "rebirth" end
    if EventChickenFlag() then return "event" end
    if TowerWantsChickenRaw() then return "tower" end
    if getgenv().Settings.Main.AutoChaos == true then return "chaos" end
end

local function ChickenClaim(Claimant)
    if ChickenPriority[Claimant] == nil then return false end

    return ChickenOwner() == Claimant
end

local function RosterLimit()
    local Purchases = GetData("purchases")
    local Passes = type(Purchases) == "table" and Purchases.passes or nil
    local HasPass = type(Passes) == "table" and Passes[RosterCap.PASS] == true

    local Ok, Limit = pcall(RosterCap.of, HasPass)

    return Ok and tonumber(Limit) or math.huge
end

local function ChickenCount(Roster)
    return type(Roster.chickens) == "table" and #Roster.chickens or 0
end

local function FirstEggTier(Roster)
    if type(Roster.eggs) ~= "table" then return end

    -- an empty Wanted list is "Any" -- pairs() order, exactly today's behaviour. A non-empty
    -- list is walked in the player's own dropdown order, which is also the hatch priority:
    -- first id in the list that the roster actually holds wins.
    local Wanted = getgenv().Settings.Main.OpenEggKinds

    if type(Wanted) == "table" and #Wanted > 0 then
        for _, Tier in ipairs(Wanted) do
            local Count = Roster.eggs[Tier]

            if type(Count) == "number" and Count > 0 then
                return Tier, Count
            end
        end

        return
    end

    for Tier, Count in pairs(Roster.eggs) do
        if type(Count) == "number" and Count > 0 then
            return Tier, Count
        end
    end
end

---- ============ Fighting ============ ----

-- forward-declared: Fight.PlanFusion below reads Picker.Fuse, but Picker itself is not built
-- until the incubator/fusion/event card window further down the file. Locals are not hoisted
-- in Luau, so without this the reference inside the closure would resolve to a global instead
-- of the real table assigned to it later.
local Picker = nil

local Fight = { }

do
    local GeneKeys = FusionRules.GENE_KEYS or { "vigor", "furia", "velocidad", "impetu", "fertility" }
    local GeneMax = GameConfig.fusion.geneMax or 31
    local GeneCaps = GameConfig.fusion.geneCap or { }
    local Strength = (GameConfig.fusion.geneBonus and GameConfig.fusion.geneBonus.strength) or 0.5
    local Pacing = (GameConfig.fusion.geneBonus and GameConfig.fusion.geneBonus.pacing) or 0.15
    local Base = GameConfig.chicken.base
    local Growth = GameConfig.chicken.growth.atk or 1.1
    local PerLevel = GameConfig.chicken.perLevel.speed or 0.02

    local Rank = { }

    for Index, Name in ipairs(Rarities) do
        Rank[Name] = Index
    end

    Fight.Rank = Rank

    function Fight.Mutation(Chicken)
        local Id = Chicken and Chicken.mutation

        return (type(Id) == "string" and Id ~= "") and Id or nil
    end

    function Fight.Stats(Chicken)
        if not Chicken then return 0, 0, 0 end

        local TypeDef = Catalog.chickenTypes[Chicken.typeId] or Catalog.defaultChickenType
        local Archetype = (TypeDef and TypeDef.archetype) or { hp = 1, atk = 1, speed = 1 }
        local Genome = Chicken.genome or { }
        local Steps = math.max(0, (tonumber(Chicken.level) or 1) - 1)
        local Curve = Growth ^ Steps

        local function Gene(Key, Weight)
            return 1 + math.clamp(tonumber(Genome[Key]) or 0, 0, GeneMax) / GeneMax * Weight
        end

        local Boost = { hp = 1, atk = 1, speed = 1 }
        local Mutation = Fight.Mutation(Chicken)

        if Mutation then
            local Table = Modules.Mutations

            if Table and Table[Mutation] and type(Table[Mutation].boost) == "table" then
                Boost = Table[Mutation].boost
            else
                Boost = { hp = 1.15, atk = 1.15, speed = 1.05 }
            end
        end

        local Hp = Base.hp * Curve * (Archetype.hp or 1) * Gene("vigor", Strength) * (Boost.hp or 1)
        local Atk = Base.atk * Curve * (Archetype.atk or 1) * Gene("furia", Strength) * (Boost.atk or 1)
        local Speed = (Base.speed + PerLevel * Steps) * (Archetype.speed or 1)
            * Gene("velocidad", Pacing) * (Boost.speed or 1)

        return Hp, Atk, Speed
    end

    function Fight.Power(Chicken)
        local Hp, Atk = Fight.Stats(Chicken)

        return math.sqrt(Hp * Atk)
    end

    local AbilityCache = { }

    local NotDamage = {
        buffMult = true, debuffMult = true, hasteMult = true,
        slowMult = true, turnMult = true, surgeMult = true,
    }

    local Once = {
        burst = true, blast = true, final = true, execute = true, shot = true,
        toll = true, max = true, strike = true, slam = true, kick = true, bonk = true,
    }

    function Fight.Ability(Id)
        if type(Id) ~= "string" or Id == "" then return 0 end
        if AbilityCache[Id] then return AbilityCache[Id] end

        local Table = GameConfig.combat and GameConfig.combat.abilities
        local Def = Table and Table[Id]

        if type(Def) ~= "table" then
            AbilityCache[Id] = 0

            return 0
        end

        local Total = 0

        for Key, Value in pairs(Def) do
            if type(Value) == "number" and Key:sub(-4) == "Mult" and not NotDamage[Key] then
                local Name = Key:sub(1, -5)
                local Count = 1

                if not Once[Name] then
                    local Found = Def[Name .. "s"] or Def.ticks or Def.waves or Def.hits
                        or Def.cuts or Def.pulls or Def.bites or Def.rockets
                        or Def.pearls or Def.bursts or Def.passes

                    if type(Found) == "number" then
                        Count = Found
                    end
                end

                Total = Total + Value * Count
            end
        end

        AbilityCache[Id] = Total

        return Total
    end

    function Fight.GeneCap(Rarity)
        return GeneCaps[Rarity] or GeneMax
    end

    function Fight.GeneQuality(Chicken)
        local Cap = Fight.GeneCap(RarityOf(Chicken))

        if Cap <= 0 then return 0 end

        local Genome = Chicken.genome or { }
        local Total = 0

        for _, Key in ipairs(GeneKeys) do
            Total = Total + (tonumber(Genome[Key]) or 0)
        end

        return math.clamp(Total / (#GeneKeys * Cap), 0, 1)
    end

    function Fight.Keep(Chicken)
        local TypeDef = Catalog.chickenTypes[Chicken.typeId] or Catalog.defaultChickenType
        local Archetype = (TypeDef and TypeDef.archetype) or { hp = 1, atk = 1 }

        return (Fight.Mutation(Chicken) and 1200 or 0)
            + (Rank[RarityOf(Chicken)] or 1) * 1000
            + Fight.GeneQuality(Chicken) * 300
            + ((Archetype.hp or 1) + (Archetype.atk or 1)) * 30
            + math.min(tonumber(Chicken.level) or 1, 50) * 0.5
    end

    function Fight.List(Roster)
        return (Roster and type(Roster.chickens) == "table") and Roster.chickens or { }
    end

    function Fight.Champion(Roster)
        local Best, BestScore

        for _, Chicken in ipairs(Fight.List(Roster)) do
            local Score = Fight.Keep(Chicken)

            if not BestScore or Score > BestScore then
                Best, BestScore = Chicken, Score
            end
        end

        return Best
    end

    function Fight.GeneGain(Champion, Partner)
        if not (Champion and Partner) then return 0 end

        local Cap = Fight.GeneCap(RarityOf(Champion))
        local Mine = Champion.genome or { }
        local Theirs = Partner.genome or { }
        local Gain = 0

        for _, Key in ipairs(GeneKeys) do
            local Have = tonumber(Mine[Key]) or 0
            local Offered = math.min(tonumber(Theirs[Key]) or 0, Cap)

            if Offered > Have then
                Gain = Gain + (Offered - Have)
            end
        end

        return Gain
    end

    function Fight.Cost(A, B)
        local Ok, Cost = pcall(FusionRules.cost, {
            level = A.level or 1,
            rarity = RarityOf(A),
            genome = A.genome or { }
        }, {
            level = B.level or 1,
            rarity = RarityOf(B),
            genome = B.genome or { }
        })

        return (Ok and type(Cost) == "number") and Cost or nil
    end

    function Fight.Locks(A, B)
        local Locks = { }

        if getgenv().Settings.Main.FuseUseLocks == false then
            return Locks
        end

        local FromLevel = ((B.level or 1) > (A.level or 1)) and B or A

        table.insert(Locks, { field = "level", from = FromLevel.id })

        local FromAbility

        if A.ability and not B.ability then
            FromAbility = A
        elseif B.ability and not A.ability then
            FromAbility = B
        elseif A.ability and B.ability then
            FromAbility = (Fight.Ability(A.ability) >= Fight.Ability(B.ability)) and A or B
        end

        if FromAbility then
            table.insert(Locks, { field = "ability", from = FromAbility.id })
        end

        return Locks
    end

    function Fight.PlanFusion(Roster)
        local List = Fight.List(Roster)

        if #List < 2 then return end

        -- Picker.Fuse names the champion when the player has picked one and is still holding
        -- it; a pick that has since been fused away or sold falls back to the automatic
        -- champion rather than stalling, the same way Picker.Summary reports a gone chicken.
        local Champion
        local Wanted = Picker.Fuse.Chosen()

        if Wanted then
            for _, Chicken in ipairs(List) do
                if Chicken.id == Wanted then
                    Champion = Chicken

                    break
                end
            end
        end

        Champion = Champion or Fight.Champion(Roster)

        if not Champion then return end

        local ChampionRarity = RarityOf(Champion)
        local ChampionMutation = Fight.Mutation(Champion)

        local Buckets = { }
        local Best, BestScore

        for _, Chicken in ipairs(List) do
            if Chicken.id ~= Champion.id and Chicken.id ~= Roster.activeId then
                local Rarity = RarityOf(Chicken)
                local Mutation = Fight.Mutation(Chicken)

                if not Mutation then
                    Buckets[Rarity] = Buckets[Rarity] or { }
                    table.insert(Buckets[Rarity], Chicken)
                end

                local Allowed = (ChampionMutation == nil) or (Mutation == ChampionMutation)

                if Allowed then
                    local Gain = Fight.GeneGain(Champion, Chicken)
                    local Score

                    if Mutation then
                        Score = 3000 + Gain
                    elseif Rarity == ChampionRarity then
                        Score = 1000 + Gain
                    elseif Gain > 0 then
                        Score = Gain
                    end

                    if Score and (not BestScore or Score > BestScore) then
                        Best, BestScore = Chicken, Score
                    end
                end
            end
        end

        if Best then
            return Champion, Best, "champion"
        end

        if getgenv().Settings.Main.FuseFodder == false then return end

        local BucketName, BucketList

        for Rarity, Members in pairs(Buckets) do
            if #Members >= 2 then
                if not BucketList
                    or #Members > #BucketList
                    or (#Members == #BucketList and (Rank[Rarity] or 1) > (Rank[BucketName] or 1)) then
                    BucketName = Rarity
                    BucketList = Members
                end
            end
        end

        if not BucketList then return end

        table.sort(BucketList, function(Left, Right)
            return Fight.Keep(Left) > Fight.Keep(Right)
        end)

        local A = BucketList[1]
        local B, BestGain

        for Index = 2, #BucketList do
            local Candidate = BucketList[Index]
            local Gain = Fight.GeneGain(A, Candidate)

            if not BestGain or Gain > BestGain then
                B, BestGain = Candidate, Gain
            end
        end

        if not B then return end

        return A, B, "fodder"
    end

    function Fight.Best(Roster)
        local Best, BestScore

        for _, Chicken in ipairs(Fight.List(Roster)) do
            local Hp, Atk, Speed = Fight.Stats(Chicken)
            local Score = math.sqrt(Atk * Speed * Hp)
                * (1 + math.min(Fight.Ability(Chicken.ability), 10) * 0.025)

            if not BestScore or Score > BestScore then
                Best, BestScore = Chicken, Score
            end
        end

        return Best, BestScore
    end

    function Fight.Sellable(Roster, Wanted)
        local Champion = Fight.Champion(Roster)
        local KeepGenes = getgenv().Settings.Main.SellKeepGeneDonors ~= false
        local Fodder = math.max(0, tonumber(getgenv().Settings.Main.SellKeepFodder) or 0)
        local Buckets = { }

        for _, Chicken in ipairs(Fight.List(Roster)) do
            local Rarity = RarityOf(Chicken)

            if Wanted[Rarity]
                and Chicken.id ~= Roster.activeId
                and Chicken.favorite ~= true
                and not Fight.Mutation(Chicken)
                and (not Champion or Chicken.id ~= Champion.id)
                and not (KeepGenes and Champion and Fight.GeneGain(Champion, Chicken) > 0) then
                Buckets[Rarity] = Buckets[Rarity] or { }
                table.insert(Buckets[Rarity], Chicken)
            end
        end

        local Ids = { }

        for _, Members in pairs(Buckets) do
            table.sort(Members, function(Left, Right)
                return Fight.Keep(Left) > Fight.Keep(Right)
            end)

            for Index = Fodder + 1, #Members do
                table.insert(Ids, Members[Index].id)
            end
        end

        return Ids
    end

    function Fight.ArenaTeam(Data, Roster)
        local ById = { }

        for _, Chicken in ipairs(Fight.List(Roster)) do
            if Chicken.id then
                ById[Chicken.id] = Chicken
            end
        end

        local Size = math.max(1, Data.teamSize or 3)
        local Bag = { }

        for _, Entry in ipairs(Data.inventory or { }) do
            if type(Entry) == "table" and Entry.id then
                local Mine = ById[Entry.id]
                local Hp, Atk, Speed

                if Mine then
                    Hp, Atk, Speed = Fight.Stats(Mine)
                else
                    Atk = (tonumber(Entry.powerN) or 0) / 100
                    Speed = tonumber(Entry.speed) or 1
                    Hp = Atk * 10
                end

                table.insert(Bag, {
                    id = Entry.id,
                    hp = Hp,
                    atk = Atk,
                    dps = Atk * Speed,
                    solo = math.sqrt(Atk * Speed * Hp),
                })
            end
        end

        if #Bag == 0 then return { } end

        Size = math.min(Size, #Bag)

        if getgenv().Settings.Main.ArenaTeamMode == "Attack" then
            table.sort(Bag, function(Left, Right)
                return Left.atk > Right.atk
            end)

            local Ids = { }

            for Index = 1, Size do
                table.insert(Ids, Bag[Index].id)
            end

            return Ids
        end

        table.sort(Bag, function(Left, Right)
            return Left.solo > Right.solo
        end)

        local Pool = math.min(#Bag, 12)
        local Best, BestScore
        local Pick = { }

        local function Search(Start, Depth)
            if Depth > Size then
                local Damage, Health = 0, 0

                for _, Entry in ipairs(Pick) do
                    Damage = Damage + Entry.dps
                    Health = Health + Entry.hp
                end

                local Score = math.sqrt(Damage * Health)

                if not BestScore or Score > BestScore then
                    BestScore = Score
                    Best = table.clone(Pick)
                end

                return
            end

            for Index = Start, Pool do
                table.insert(Pick, Bag[Index])
                Search(Index + 1, Depth + 1)
                table.remove(Pick)
            end
        end

        Search(1, 1)

        if not Best then return { } end

        table.sort(Best, function(Left, Right)
            return Left.hp > Right.hp
        end)

        local Ids = { }

        for _, Entry in ipairs(Best) do
            table.insert(Ids, Entry.id)
        end

        return Ids
    end
end

---- ============ Movement ============ ----

local function GetHumanoid()
    local Character = LocalPlayer.Character

    return Character and Character:FindFirstChildOfClass("Humanoid")
end

local MoveHoldUntil = 0
local KoCooldown = (GameConfig.pit.player and GameConfig.pit.player.koCooldown) or 3

local function HoldMovement(Seconds)
    MoveHoldUntil = math.max(MoveHoldUntil, os.clock() + (Seconds or KoCooldown))
end

for _, Name in ipairs({ "PitPlayerKo", "PitPlayerReset", "PitPlayerHit" }) do
    local Def = Remotes.defs[Name]

    if Def then
        TrackConnection(Remotes.onClient(Def, function(...)
            for _, Value in ipairs({ ... }) do
                if Value == LocalPlayer or Value == LocalPlayer.UserId or Value == UserId then
                    HoldMovement(Name == "PitPlayerHit" and 1 or KoCooldown)

                    return
                end
            end
        end))
    end
end

TrackConnection(LocalPlayer.CharacterAdded:Connect(function()
    HoldMovement((GameConfig.guard.spawnGrace or 3) + 1)
end))

local function MovementBusy()
    if os.clock() < MoveHoldUntil then return true end

    local Humanoid = GetHumanoid()

    if not Humanoid then return true end

    local State = Humanoid:GetState()

    return State == Enum.HumanoidStateType.Freefall
        or State == Enum.HumanoidStateType.Physics
        or State == Enum.HumanoidStateType.Ragdoll
        or State == Enum.HumanoidStateType.FallingDown
        or State == Enum.HumanoidStateType.Dead
end

---- ============ Scrap ============ ----

local NoclipParts = { }
local NoclipConnection = nil

local function StopNoclip()
    if NoclipConnection then
        NoclipConnection:Disconnect()
        NoclipConnection = nil
    end

    for Part in pairs(NoclipParts) do
        if typeof(Part) == "Instance" and Part:IsA("BasePart") and Part.Parent then
            Part.CanCollide = true
        end
    end

    table.clear(NoclipParts)
end

local function StartNoclip()
    if NoclipConnection then return end

    NoclipConnection = TrackConnection(RunService.Stepped:Connect(function()
        local Character = LocalPlayer.Character

        if not Character then return end

        for _, Part in ipairs(Character:GetDescendants()) do
            if Part:IsA("BasePart") and Part.CanCollide then
                Part.CanCollide = false
                NoclipParts[Part] = true
            end
        end
    end))
end

local function NearestStack(Origin, Wanted)
    local Folder = workspace:FindFirstChild("PitScrap")

    if not Folder then return end

    local Mine = "player:" .. LocalPlayer.UserId
    local Best, BestDistance

    for _, Piece in ipairs(Folder:GetChildren()) do
        if Piece:IsA("BasePart") then
            local Kind = Piece:GetAttribute("StackKind")
            local Owner = Piece:GetAttribute("DropOwner")

            if Kind and (Wanted == nil or Wanted[Kind]) and (Owner == nil or Owner == Mine) then
                local Distance = (Piece.Position - Origin).Magnitude

                if not BestDistance or Distance < BestDistance then
                    Best = Piece
                    BestDistance = Distance
                end
            end
        end
    end

    return Best
end

local function MyRecycler()
    local Folder = workspace:FindFirstChild("Recyclers")
    local Plot = LocalPlayer:GetAttribute("Plot")

    if not (Folder and Plot) then return end

    local Model = Folder:FindFirstChild("Recycler" .. tostring(Plot))

    if not Model then return end

    return Model.PrimaryPart or Model:FindFirstChildWhichIsA("BasePart", true)
end

local LastCarry = nil
local LastPickupAt = 0

local function TrackPickup(Carry)
    if LastCarry and Carry > LastCarry then
        LastPickupAt = os.clock()
    end

    LastCarry = Carry
end

local function PickupReady(Distance)
    if Distance <= (ScrapTravel.tolerance or 12) then
        return true
    end

    return os.clock() - LastPickupAt >= (0.5)
end

---- ============ Event ============ ----

local EventDropKinds = { "tradeOre", "meteorRock", "ufoPart", "goldCoin", "eggPod" }

local function WantedDropKinds()
    local Wanted = { }

    for _, Kind in ipairs(getgenv().Settings.Main.EventDropKinds or EventDropKinds) do
        Wanted[Kind] = true
    end

    return Wanted
end

local function CarriedPieces()
    return LocalPlayer:GetAttribute("scrapCarry") or 0
end

local function HotEgg()
    local Egg = workspace:FindFirstChild("HotEgg")

    if Egg and Egg:IsA("BasePart") then
        return Egg
    end
end

local function HotEggBusy()
    return getgenv().Settings.Main.AutoHotEgg == true and HotEgg() ~= nil
end

local function EventDropsBusy(Origin)
    if not getgenv().Settings.Main.AutoEventDrops then return false end
    if not EventLive() then return false end
    if CarriedPieces() > 0 then return true end

    return NearestStack(Origin, WantedDropKinds()) ~= nil
end

local function DodgePoint(Position)
    local Offset = Position - PitZone.center
    local Flat = Vector3.new(Offset.X, 0, Offset.Z)
    local Radius = math.clamp(Flat.Magnitude, 8, PitZone.radius - 8)
    local Angle = math.atan2(Offset.Z, Offset.X) + 0.7

    return PitZone.center + Vector3.new(math.cos(Angle) * Radius, Position.Y - PitZone.center.Y, math.sin(Angle) * Radius)
end

local function WalkTaken()
    if HotEggBusy() then return true end
    if not getgenv().Settings.Main.AutoGrabScrap then return false end

    local Root = GetRootPart()

    if not Root then return false end

    return CarriedPieces() > 0 or NearestStack(Root.Position, nil) ~= nil
end

local AskAgainAt = { }
local AskFailures = { }

local function Ask(Name, ...)
    if os.clock() < (AskAgainAt[Name] or 0) then return end

    local Reply = Remotes.invoke(Name, ...)

    if Reply == nil then
        return nil
    end

    if type(Reply) == "table" and Reply.ok then
        AskAgainAt[Name] = nil
        AskFailures[Name] = nil
    else
        local Failures = (AskFailures[Name] or 0) + 1

        AskFailures[Name] = Failures
        AskAgainAt[Name] = os.clock() + math.min(120, 10 * 2 ^ (Failures - 1))
    end

    return Reply
end

local function Claimed(_, Reply)
    return type(Reply) == "table" and Reply.ok == true
end

local Running = { }

local StartupAt = os.clock()
local StartupGrace = 5

local StartupStagger = 0.4
local StartupSlot = 0

local function Loop(Key, Delay, Step)
    if Running[Key] then return end

    Running[Key] = true

    StartupSlot = StartupSlot + 1

    local Slot = StartupSlot

    task.spawn(function()
        local Remaining = StartupGrace + Slot * StartupStagger - (os.clock() - StartupAt)

        if Remaining > 0 then
            task.wait(Remaining)
        end

        while getgenv().Settings.Main[Key] and getgenv().ValkyrieSession == SessionToken do
            pcall(Step)

            task.wait(Delay + math.random() * math.min(Delay * 0.25, 0.5))
        end

        Running[Key] = nil
    end)
end

---- ============ Pages ============ ----

Elevate()

local ChickensPage = Window:Page({ Name = "Chickens", Icon = "117851493400222", Columns = 2 })
local ProgressPage = Window:Page({ Name = "Progression", Icon = "81819858538839", Columns = 2 })
local ArenaPage = Window:Page({ Name = "Arena", Icon = "95937619060532", Columns = 2 })
local WorldPage = Window:Page({ Name = "World", Icon = "88536886295174", Columns = 2 })
local RewardsPage = Window:Page({ Name = "Rewards", Icon = "109855212076373", Columns = 2 })
local ConfigPage = Window:Page({ Name = "Configuration", Icon = "80758916183665", Columns = 2 })

---- ============ Eggs ============ ----

local EggsSection = ChickensPage:Section({
    Name = "Eggs",
    Description = "Egg collecting and hatching",
    Icon = "117851493400222",
    Side = 1,
    EnableToggle = true
})

EggsSection:Toggle({
    Name = "Auto Collect Eggs",
    Flag = "GFCAutoCollectEggs",
    Default = getgenv().Settings.Main.AutoCollectEggs,
    Callback = function(Value)
        getgenv().Settings.Main.AutoCollectEggs = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoCollectEggs", 0.4, function()
            local Root = GetRootPart()
            local Humanoid = GetHumanoid()
            local Folder = workspace:FindFirstChild("NestEggs")

            if not (Root and Humanoid and Folder) then return end
            if MovementBusy() then return end

            if HotEggBusy() or EventDropsBusy(Root.Position) then return end

            if WalkTaken() then return end

            local Best, BestDistance

            for _, Egg in ipairs(Folder:GetChildren()) do
                if Egg:IsA("BasePart") and Egg:GetAttribute("owner") == LocalPlayer.UserId then
                    local Distance = (Egg.Position - Root.Position).Magnitude

                    if not BestDistance or Distance < BestDistance then
                        Best = Egg
                        BestDistance = Distance
                    end
                end
            end

            if not Best or BestDistance <= 3 then return end

            Humanoid:MoveTo(Best.Position)
        end)
    end
})

EggsSection:Toggle({
    Name = "Auto Open Egg",
    Flag = "GFCAutoOpenEgg",
    Default = getgenv().Settings.Main.AutoOpenEgg,
    Callback = function(Value)
        getgenv().Settings.Main.AutoOpenEgg = Value
        SaveSetting()

        if not Value then return end

        local Hatching = false

        local FullAt = nil

        Loop("AutoOpenEgg", 2, function()
            if Hatching then return end

            local Roster = GetRoster()

            if not Roster then return end

            local Tier, Count = FirstEggTier(Roster)

            if not Tier then return end

            local Chickens = ChickenCount(Roster)
            local Limit = RosterLimit()

            if Chickens >= Limit then
                return
            end

            if FullAt and Chickens >= FullAt then return end

            local BatchMax = GameConfig.roster.hatch.batchMax or 10
            local Amount = math.min(Count, BatchMax, math.max(1, Limit - Chickens))

            Hatching = true

            local Ok, Reply = pcall(function()
                if Amount > 1 then
                    return Ask(Remotes.defs.HatchEggs, Tier, Amount)
                end

                return Ask(Remotes.defs.HatchEgg, Tier)
            end)

            Hatching = false

            if not Ok then
                return
            end

            if type(Reply) == "table" and Reply.ok ~= true and Reply.error == "roster-full" then
                FullAt = Chickens
            end
        end)
    end
})

do
    -- raw egg ids, same convention as Drop Kinds below and as STE.lua's own Select Egg To
    -- Place -- locale carries the display name, and an empty selection means Any with no
    -- "Any" row of its own: FirstEggTier already treats an empty OpenEggKinds as pairs()
    -- order, exactly today's behaviour.
    local Items = { }

    for Id in pairs(Catalog.eggs) do
        table.insert(Items, Id)
    end

    table.sort(Items)

    -- The library only shows its "..." placeholder for a Multi dropdown when Default is
    -- falsy: an empty table is still truthy, so passing {} runs Dropdown:Set({}), which
    -- writes DisplayValue({}) -- an empty string -- straight over the placeholder instead
    -- of leaving it. Handing nil through on an empty save is what keeps the row reading
    -- "..." for Any rather than blank.
    local Saved = getgenv().Settings.Main.OpenEggKinds
    local DefaultKinds = (type(Saved) == "table" and #Saved > 0) and Saved or nil

    EggsSection:Dropdown({
        Name = "Egg Types",
        Flag = "GFCOpenEggKinds",
        Items = Items,
        Default = DefaultKinds,
        Multi = true,
        Callback = function(Value)
            getgenv().Settings.Main.OpenEggKinds = Value
            SaveSetting()
        end
    })
end

---- ============ Fusion ============ ----

local FusionSection = ChickensPage:Section({
    Name = "Fusion",
    Description = "Fusion planning",
    Icon = "81819858538839",
    Side = 2,
    EnableToggle = true
})

FusionSection:Toggle({
    Name = "Auto Fuse Chickens",
    Flag = "GFCAutoFuseChickens",
    Default = getgenv().Settings.Main.AutoFuseChickens,
    Callback = function(Value)
        getgenv().Settings.Main.AutoFuseChickens = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoFuseChickens", 1, function()
            local Roster = GetRoster()

            if not Roster then return end

            local A, B = Fight.PlanFusion(Roster)

            if not (A and B) then return end

            local Cost = Fight.Cost(A, B)

            if Cost and not CanAfford(Cost) then return end

            Ask(Remotes.defs.FuseChickens, A.id, B.id, Fight.Locks(A, B), nil, "a")
        end)
    end
})

FusionSection:Toggle({
    Name = "Use Fusion Locks",
    Flag = "GFCFuseUseLocks",
    Default = getgenv().Settings.Main.FuseUseLocks,
    Callback = function(Value)
        getgenv().Settings.Main.FuseUseLocks = Value
        SaveSetting()
    end
})

FusionSection:Toggle({
    Name = "Fuse Fodder",
    Flag = "GFCFuseFodder",
    Default = getgenv().Settings.Main.FuseFodder,
    Callback = function(Value)
        getgenv().Settings.Main.FuseFodder = Value
        SaveSetting()
    end
})

do
    local Select = FusionSection:Button({
        Name = "Select Chicken",
        Callback = function()
            Picker.Fuse.Open()
        end
    })

    -- same override as the incubator's picker button: opens the window on the frame it is
    -- asked for instead of the library's red confirmation flash
    if type(Select) == "table" then
        function Select:Press()
            Library:SafeCall(self.Callback)
        end
    end
end

---- ============ Roster ============ ----

local RosterSection = ChickensPage:Section({
    Name = "Roster",
    Description = "Roster upkeep",
    Icon = "109855212076373",
    Side = 1,
    EnableToggle = true
})

RosterSection:Toggle({
    Name = "Auto Sell Chickens",
    Flag = "GFCAutoSellChickens",
    Default = getgenv().Settings.Main.AutoSellChickens,
    Callback = function(Value)
        getgenv().Settings.Main.AutoSellChickens = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoSellChickens", 1, function()
            local Roster = GetRoster()

            if not Roster then return end

            local Wanted = { }

            for _, Rarity in ipairs(getgenv().Settings.Main.SellRarities or { }) do
                Wanted[Rarity] = true
            end

            local Ids = Fight.Sellable(Roster, Wanted)

            if #Ids > 0 then
                Ask(Remotes.defs.SellChickens, Ids)
            end
        end)
    end
})

local ChaosMinHealth = GameConfig.chicken.recovery.minHealth or 0.2
local ChaosSentAt = 0

RosterSection:Dropdown({
    Name = "Sell Rarity",
    Flag = "GFCSellRarities",
    Items = Rarities,
    Default = getgenv().Settings.Main.SellRarities,
    Multi = true,
    Callback = function(Value)
        getgenv().Settings.Main.SellRarities = Value
        SaveSetting()
    end
})

RosterSection:Toggle({
    Name = "Keep Gene Donors",
    Flag = "GFCSellKeepGeneDonors",
    Default = getgenv().Settings.Main.SellKeepGeneDonors,
    Callback = function(Value)
        getgenv().Settings.Main.SellKeepGeneDonors = Value
        SaveSetting()
    end
})

RosterSection:Slider({
    Name = "Keep Per Rarity",
    Flag = "GFCSellKeepFodder",
    Min = 0,
    Max = 10,
    Default = getgenv().Settings.Main.SellKeepFodder,
    Callback = function(Value)
        getgenv().Settings.Main.SellKeepFodder = Value
        SaveSetting()
    end
})

local function ProtectMutations()
    local Roster = GetRoster()

    if not Roster then return end

    for _, Chicken in ipairs(Fight.List(Roster)) do
        if Fight.Mutation(Chicken) and Chicken.favorite ~= true then
            Ask(Remotes.defs.SetChickenFavorite, Chicken.id, true)

            return
        end
    end
end

RosterSection:Toggle({
    Name = "Keep Mutations",
    Flag = "GFCAutoProtectMutations",
    Default = getgenv().Settings.Main.AutoProtectMutations,
    Callback = function(Value)
        getgenv().Settings.Main.AutoProtectMutations = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoProtectMutations", 5, ProtectMutations)
    end
})

if getgenv().Settings.Main.AutoProtectMutations then
    Loop("AutoProtectMutations", 5, ProtectMutations)
end

---- ============ Pit ============ ----

local PitSection = ChickensPage:Section({
    Name = "Pit",
    Description = "Pit automation",
    Icon = "88536886295174",
    Side = 1,
    EnableToggle = true
})

PitSection:Toggle({
    Name = "Auto Chaos",
    Flag = "GFCAutoChaos",
    Default = getgenv().Settings.Main.AutoChaos,
    Callback = function(Value)
        getgenv().Settings.Main.AutoChaos = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoChaos", 1, function()
            local Body = MyChickenBody()

            if not Body then return end

            if not ChickenClaim("chaos") then return end

            local State = ChickenStateOf(Body)

            if State == "pit" or State == "campaign" then return end

            if (Body:GetAttribute("ovHpFrac") or 1) < ChaosMinHealth then return end

            if os.clock() - ChaosSentAt < 6 then return end

            if Remotes.fire(Remotes.defs.SetChickenOrder, "chaos") then
                ChaosSentAt = os.clock()
            end
        end)
    end
})

---- ============ Incubator ============ ----

-- The incubator on the plot lays eggs on its own once a chicken is sitting in it, so what
-- automation has to do is three things: empty the tray, put a chicken back when the tray owner
-- is missing, and buy the next level when it is affordable. Everything that decides whether
-- there is anything to do is on the machine model itself -- Unlocked, Eggs, Cap, Level,
-- Occupant -- which is what the game's own billboard reads.
--
-- Which chicken is in there is not a detail: the egg pool comes from the occupant, either its
-- own `eggs` table or its type's, so a rarer bird lays rarer eggs. That is why this has a
-- picker rather than choosing for itself.
local function MyIncubator()
    local Folder = workspace:FindFirstChild("Incubators")
    local Plot = LocalPlayer:GetAttribute("Plot")

    if not (Folder and Plot) then return end

    return Folder:FindFirstChild("Incubator" .. tostring(Plot))
end

local IncubatorSection = ChickensPage:Section({
    Name = "Incubator",
    Description = "Incubator egg claiming",
    Icon = "117851493400222",
    Side = 2,
    EnableToggle = true
})

-- The picker window, its rig cache and the one function the button needs. Behind a single
-- local because the main chunk is close to Luau's ceiling of 200 locals per function.
--
-- Everything visual here is read off Library.Theme rather than written out again, so the
-- window is the same near-black, the same 5-6 pixel corners and the same font as every panel
-- the library builds. Outlines are the exception rather than the rule: one around the window,
-- one around whichever card is chosen, and nothing else -- rarity is said with colour, which
-- needs no border to carry it.
Picker = { }

do
    local UserInputService = game:GetService("UserInputService")

    -- one card window shared by every instance below (incubator, fusion, event); this says
    -- which instance currently owns it, so Choose and Clear write to the right setting key
    local Active = nil

    local function Tone(Key, Fallback)
        local Value = Library.Theme and Library.Theme[Key]

        return typeof(Value) == "Color3" and Value or Fallback
    end

    -- one colour per rarity in the same order as Rarities, so a card reads at a glance
    local RarityColor = {
        common = Color3.fromRGB(154, 160, 166),
        uncommon = Color3.fromRGB(95, 208, 122),
        rare = Color3.fromRGB(74, 168, 255),
        epic = Color3.fromRGB(176, 108, 255),
        legendary = Color3.fromRGB(255, 176, 56),
        mythic = Color3.fromRGB(255, 84, 112),
        divine = Color3.fromRGB(255, 230, 128),
        celestial = Color3.fromRGB(89, 242, 224),
        cosmic = Color3.fromRGB(200, 107, 255),
        secret = Color3.fromRGB(255, 59, 59)
    }

    local ChickenBody = nil
    local ChickenBodyTried = false

    -- The game's own ChickenViewport builds its preview out of this module, and so does this:
    -- spawn(level, parent, cframe, look) hands back a rig with a .model and a :destroy(). It
    -- lives under PlayerScripts, so it is a plain require rather than anything found by hand.
    local function Rigs()
        if ChickenBodyTried then return ChickenBody end

        ChickenBodyTried = true

        local Ok, Module = pcall(function()
            local Features = LocalPlayer:WaitForChild("PlayerScripts", 5):WaitForChild("Features", 5)

            return require(Features:WaitForChild("Chicken", 5):WaitForChild("body", 5):WaitForChild("ChickenBody", 5))
        end)

        if Ok and type(Module) == "table" and type(Module.spawn) == "function" then
            ChickenBody = Module
        end

        return ChickenBody
    end

    local function TypeDef(Chicken)
        return Catalog.chickenTypes[Chicken.typeId] or Catalog.defaultChickenType
    end

    -- The game's own lookOf, and it has to be here rather than passing Chicken.look straight
    -- through: a chicken that has never been customised carries no look at all, and handing
    -- nil to spawn builds a bare default bird instead of the one the player owns. The fallback
    -- fires only on nil -- an empty table is a real look, the plain unadorned body.
    local function LookOf(Chicken)
        if Chicken.look ~= nil then return Chicken.look end

        local Def = TypeDef(Chicken)

        return (Def and Def.look) or { }
    end

    local function NameOf(Chicken)
        if type(Chicken.nickname) == "string" and Chicken.nickname ~= "" then
            return Chicken.nickname
        end

        local Def = TypeDef(Chicken)

        return (Def and Def.name) or tostring(Chicken.typeId or "Chicken")
    end

    -- the id of whatever is sitting in the machine right now, or nil -- incubator-specific,
    -- kept as a plain helper rather than a per-instance method
    local function Occupant()
        local State = GetData("incubator")

        if type(State) == "table" and type(State.chicken) == "table" then
            return State.chicken.id
        end
    end

    local function ChosenFor(Key)
        local Id = getgenv().Settings.Main[Key]

        return (type(Id) == "string" and Id ~= "") and Id or nil
    end

    local function SummaryFor(Key)
        local Id = ChosenFor(Key)

        if not Id then return "No chicken selected" end

        local Roster = GetRoster()

        for _, Chicken in ipairs(Fight.List(Roster)) do
            if Chicken.id == Id then
                return string.format("%s  Lv.%d", NameOf(Chicken), tonumber(Chicken.level) or 1)
            end
        end

        return "Selected chicken is gone"
    end

    ---- ---- the window ---- ----

    local Gui = nil
    local Grid = nil
    local Cards = { }
    local Query = ""
    local ModalConnections = { }

    local function TrackModal(Connection)
        if Connection then
            table.insert(ModalConnections, Connection)
            table.insert(SessionConnections, Connection)
        end

        return Connection
    end

    local function ClearModalConnections()
        for _, Conn in ipairs(ModalConnections) do
            pcall(function() Conn:Disconnect() end)
        end
        table.clear(ModalConnections)
    end

    local function BindClick(Button, Callback)
        if not Button then return end
        if Button:IsA("GuiButton") then
            TrackModal(Button.Activated:Connect(Callback))
        end
        TrackModal(Button.MouseButton1Click:Connect(Callback))
    end

    -- CoreGui, because it is the only place a window can sit above the hub: the hub's own
    -- holder is a CoreGui ScreenGui, and CoreGui draws over everything in PlayerGui whatever
    -- the DisplayOrder says. Inside CoreGui the DisplayOrder does count, so PickerOrder only
    -- has to beat the holder's 2.
    local function CoreParent()
        local Ok, Service = pcall(game.GetService, game, "CoreGui")

        if not (Ok and typeof(Service) == "Instance") then return end

        if type(cloneref) == "function" then
            local Fine, Ref = pcall(cloneref, Service)

            if Fine and typeof(Ref) == "Instance" then return Ref end
        end

        return Service
    end

    local PickerOrder = 1000

    -- Everything below that touches the window has to go through this. A Roblox signal handler
    -- -- a click, a scroll, a property change -- runs on a thread Roblox made, and that thread
    -- does not carry the executor's capability however high the identity reads: measured at
    -- identity 8, moving a rig into CoreGui still threw "lacking capability Plugin". A thread
    -- spawned from it does carry it, so the work is handed to one. The cost is that the window
    -- appears a frame after the click rather than on it.
    local function Elevated(Fn)
        task.spawn(function()
            Elevate()

            local Ok, Err = pcall(Fn)

            if not Ok then
                warn("[ValkyrieHub] chicken picker: " .. tostring(Err))
            end
        end)
    end

    -- A rig cannot be BUILT in CoreGui. ChickenBody.spawn is ordinary game code and throws
    -- "The current thread cannot access 'Instance' (lacking capability Plugin)" the moment its
    -- parent chain reaches CoreGui or the executor's hidden container. It can however be built
    -- under PlayerGui and MOVED afterwards, rig and all -- measured, seventeen parts before the
    -- move and seventeen after. So every viewport is assembled inside this hidden staging
    -- screen and reparented into its card once the bird is standing in it.
    local Stage = nil

    local function Staging()
        if Stage and Stage.Parent then return Stage end

        Stage = Instance.new("ScreenGui")
        Stage.Name = "ValkyrieChickenStage"
        Stage.Enabled = false
        Stage.ResetOnSpawn = false
        Stage.Parent = LocalPlayer:WaitForChild("PlayerGui")

        return Stage
    end

    local function DropRig(Entry)
        local Held = Entry.Rig

        if not Held then return end

        Entry.Rig = nil

        Elevated(function()
            pcall(function() Held.Rig:destroy() end)
            pcall(function() Held.Viewport:Destroy() end)
        end)
    end

    -- Framing copied from the game's own viewport: wait for the rig to have parts, take the
    -- bounding box, and back the camera off by the radius over the tangent of half the field
    -- of view. The rig is built a frame or two after spawn returns, hence the wait loop. This
    -- runs inline rather than on a thread of its own, because it has to be finished before the
    -- rig is carried into CoreGui.
    local function FrameRig(Camera, Rig)
        for _ = 1, 240 do
            if not Camera.Parent then return end

            local Low = Vector3.new(math.huge, math.huge, math.huge)
            local High = -Low
            local Any = false

            for _, Thing in ipairs(Rig.model:GetDescendants()) do
                if Thing:IsA("BasePart") then
                    Low = Low:Min(Thing.Position - Thing.Size / 2)
                    High = High:Max(Thing.Position + Thing.Size / 2)
                    Any = true
                end
            end

            if Any then
                local Centre = (Low + High) / 2
                local Radius = (High - Low).Magnitude / 2
                local Back = Radius / math.tan(math.rad(Camera.FieldOfView / 2)) * 1.15
                local Facing = Vector3.new(math.sin(0.61), 0.24, math.cos(0.61)).Unit

                Camera.CFrame = CFrame.lookAt(Centre + Facing * Back, Centre)

                return true
            end

            task.wait()
        end
    end

    -- A rig that ends up in CoreGui has to be finished with the game before it goes: every
    -- frame, ChickenAnimator writes to the rig's Motor6Ds off its own RenderStepped, and from
    -- the game's thread a CoreGui instance is untouchable -- so left running it throws "lacking
    -- capability Plugin" sixty times a second and the bird never moves anyway. Each rig owns
    -- its animator and the animator owns its connection, so cutting ours loose costs the farm
    -- chicken nothing. What is on screen is the pose it was standing in when it was cut.
    local function Freeze(Rig)
        for _ = 1, 240 do
            if rawget(Rig, "_animator") then break end

            task.wait()
        end

        local Animator = rawget(Rig, "_animator")

        if Animator then
            pcall(function() Animator:destroy() end)

            Rig._animator = nil
        end
    end

    local function BuildRig(Entry)
        if Entry.Rig then return end
        if not Rigs() then return end

        -- the slot is claimed before anything is built, so a second Refresh in the same frame
        -- does not start the same bird twice, and a DropRig while this is still working clears
        -- it and the thread below finds its own work orphaned and tidies up
        local Held = { }

        Entry.Rig = Held

        Elevated(function()
            local Body = Rigs()

            if not Body or Entry.Rig ~= Held then return end

            local Viewport = Instance.new("ViewportFrame")
            Viewport.Size = UDim2.fromScale(1, 1)
            Viewport.BackgroundTransparency = 1
            Viewport.BorderSizePixel = 0
            Viewport.Ambient = Color3.fromRGB(200, 200, 210)
            Viewport.LightColor = Color3.fromRGB(255, 255, 255)
            Viewport.LightDirection = Vector3.new(-0.4, -1, -0.6)
            Viewport.Parent = Staging()

            Held.Viewport = Viewport

            local Camera = Instance.new("Camera")
            Camera.FieldOfView = 40
            Camera.Parent = Viewport

            local World = Instance.new("WorldModel")
            World.Parent = Viewport

            Viewport.CurrentCamera = Camera

            local Ok, Rig = pcall(
                Body.spawn,
                math.max(1, tonumber(Entry.Chicken.level) or 1),
                World,
                CFrame.new(0, 0, 0),
                LookOf(Entry.Chicken)
            )

            if not (Ok and type(Rig) == "table" and Rig.model) then
                Viewport:Destroy()

                if Entry.Rig == Held then
                    Entry.Rig = nil
                end

                return
            end

            Held.Rig = Rig

            if Entry.Chicken.mutation then
                pcall(function() Rig:setMutation(Entry.Chicken.mutation) end)
            end

            -- everything the game has to do to this bird happens here, while it is still in
            -- PlayerGui where the game can reach it
            FrameRig(Camera, Rig)
            pcall(function() Rig:refreshAura() end)
            Freeze(Rig)

            -- the card may have scrolled away in the frames that took
            if Entry.Rig ~= Held then
                pcall(function() Rig:destroy() end)
                pcall(function() Viewport:Destroy() end)

                return
            end

            Viewport.Parent = Entry.Well
        end)
    end

    -- Fifty-odd parts a rig and a roster that runs to sixty birds is not something to build all
    -- at once, so only the cards inside the scroll window (plus a screen either side) hold a
    -- rig, and the rest give theirs back.
    local function Refresh()
        if not Grid then return end

        local Top = Grid.CanvasPosition.Y
        local Bottom = Top + Grid.AbsoluteWindowSize.Y
        local Margin = Grid.AbsoluteWindowSize.Y

        for _, Entry in ipairs(Cards) do
            if Entry.Frame.Visible then
                local Y = Entry.Frame.AbsolutePosition.Y - Grid.AbsolutePosition.Y + Top
                local Near = Y + Entry.Frame.AbsoluteSize.Y >= Top - Margin and Y <= Bottom + Margin

                if Near then
                    BuildRig(Entry)
                else
                    DropRig(Entry)
                end
            else
                DropRig(Entry)
            end
        end
    end

    local function ApplyQuery()
        local Needle = Query:lower()

        for _, Entry in ipairs(Cards) do
            Entry.Frame.Visible = Needle == "" or Entry.Search:find(Needle, 1, true) ~= nil
        end

        Refresh()
    end

    local function CloseNow()
        for _, Entry in ipairs(Cards) do
            DropRig(Entry)
        end

        table.clear(Cards)

        ClearModalConnections()

        if Gui then
            local ToDestroy = Gui
            Gui = nil
            pcall(function() ToDestroy:Destroy() end)
        end

        if Stage then
            local ToClear = Stage
            Stage = nil
            pcall(function() ToClear:Destroy() end)
        end

        Grid = nil
        Query = ""
    end

    local function Close()
        Elevated(CloseNow)
    end

    local function Choose(Id)
        if not Active then return end

        getgenv().Settings.Main[Active.Key] = Id or ""
        SaveSetting()

        Close()
    end

    ---- ---- the small builders ---- ----

    local function Corner(Parent, Radius)
        local Shape = Instance.new("UICorner")
        Shape.CornerRadius = UDim.new(0, Radius)
        Shape.Parent = Parent

        return Shape
    end

    local function Stroke(Parent, Color, Thickness)
        local Line = Instance.new("UIStroke")
        Line.Color = Color
        Line.Thickness = Thickness or 1
        Line.Parent = Parent

        return Line
    end

    local function Fill(Parent, Color, Radius)
        local Frame = Instance.new("Frame")
        Frame.BackgroundColor3 = Color
        Frame.BorderSizePixel = 0
        Frame.Parent = Parent

        if Radius then
            Corner(Frame, Radius)
        end

        return Frame
    end

    local function Text(Parent, Content, Size, Color, Dim, Light)
        local Label = Instance.new("TextLabel")
        Label.BackgroundTransparency = 1
        Label.Text = Content
        Label.TextSize = Size
        Label.TextColor3 = Color
        Label.TextTransparency = Dim or 0
        Label.FontFace = Light and (Library.Fonts and Library.Fonts.Regular or Library.Font) or Library.Font
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.TextTruncate = Enum.TextTruncate.AtEnd
        Label.Parent = Parent

        return Label
    end

    local function AddCard(Chicken, Selected)
        local Rarity = RarityOf(Chicken)
        local Tint = RarityColor[Rarity] or RarityColor.common
        local Rest = Tone("Element Background", Color3.fromRGB(26, 26, 31))
        local Hover = Tone("Element Hover", Color3.fromRGB(46, 46, 54))
        local Ink = Tone("Text", Color3.fromRGB(235, 235, 235))

        local Button = Instance.new("TextButton")
        Button.Size = UDim2.fromOffset(146, 174)
        Button.BackgroundColor3 = Selected and Hover or Rest
        Button.AutoButtonColor = false
        Button.Text = ""
        Button.Parent = Grid

        Corner(Button, 6)

        -- the one outline in the grid, and it is state rather than decoration: it says which
        -- card the incubator is set to
        if Selected then
            Stroke(Button, Accent, 1)
        end

        -- an empty well rather than the viewport itself: the viewport is built elsewhere and
        -- dropped in here, and taken back out when the card scrolls away
        local Well = Fill(Button, Tone("Section Background", Color3.fromRGB(15, 15, 18)), 5)
        Well.Size = UDim2.new(1, -16, 0, 102)
        Well.Position = UDim2.fromOffset(8, 8)
        Well.ClipsDescendants = true

        local Name = Text(Button, NameOf(Chicken), 13, Ink)
        Name.Size = UDim2.new(1, -18, 0, 16)
        Name.Position = UDim2.fromOffset(9, 116)

        local Level = Text(Button, string.format("Lv.%d", tonumber(Chicken.level) or 1), 12, Ink, 0.45, true)
        Level.Size = UDim2.new(1, -18, 0, 14)
        Level.Position = UDim2.fromOffset(9, 134)

        -- rarity said with a dot and coloured text rather than a border round the whole card
        local Dot = Fill(Button, Tint, 3)
        Dot.Size = UDim2.fromOffset(6, 6)
        Dot.Position = UDim2.fromOffset(9, 155)

        local Tag = Text(Button, Rarity, 11, Tint, nil, true)
        Tag.Size = UDim2.new(1, -40, 0, 12)
        Tag.Position = UDim2.fromOffset(21, 152)

        if Chicken.mutation then
            local Mark = Text(Button, "MUT", 10, Color3.fromRGB(255, 214, 110))
            Mark.Size = UDim2.fromOffset(34, 12)
            Mark.Position = UDim2.new(1, -43, 0, 152)
            Mark.TextXAlignment = Enum.TextXAlignment.Right
        end

        local Entry = {
            Frame = Button,
            Well = Well,
            Chicken = Chicken,
            Search = (NameOf(Chicken) .. " " .. Rarity):lower()
        }

        TrackModal(Button.MouseEnter:Connect(function()
            Button.BackgroundColor3 = Hover
        end))

        TrackModal(Button.MouseLeave:Connect(function()
            Button.BackgroundColor3 = Selected and Hover or Rest
        end))

        BindClick(Button, function()
            Choose(Chicken.id)
        end)

        table.insert(Cards, Entry)
    end

    local function OpenNow(Options)
        if Gui then
            CloseNow()
        end

        Active = Options

        local Ok, Err = pcall(function()
            local Roster = GetRoster()

            if not Roster then return end

            local Ink = Tone("Text", Color3.fromRGB(235, 235, 235))
            local Line = Tone("Outline", Color3.fromRGB(46, 46, 54))
            local Control = Tone("Element", Color3.fromRGB(38, 38, 45))

            Gui = Instance.new("ScreenGui")
            Gui.Name = "ValkyrieChickenPicker"
            Gui.ResetOnSpawn = false
            Gui.IgnoreGuiInset = true
            Gui.DisplayOrder = PickerOrder
            Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

            local Home = CoreParent()

            if not (Home and pcall(function() Gui.Parent = Home end)) then
                Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
            end


            TrackModal(Gui.Destroying:Connect(function()
                Close()
            end))

            local Backdrop = Instance.new("TextButton")
            Backdrop.Size = UDim2.fromScale(1, 1)
            Backdrop.BackgroundColor3 = Tone("Background 2", Color3.fromRGB(10, 10, 12))
            Backdrop.BackgroundTransparency = 0.35
            Backdrop.BorderSizePixel = 0
            Backdrop.Text = ""
            Backdrop.AutoButtonColor = false
            Backdrop.Parent = Gui

            BindClick(Backdrop, function()
                Close()
            end)

            local Panel = Instance.new("Frame")
            Panel.Size = UDim2.fromOffset(644, 470)
            Panel.Position = UDim2.fromScale(0.5, 0.5)
            Panel.AnchorPoint = Vector2.new(0.5, 0.5)
            Panel.BackgroundColor3 = Tone("Background", Color3.fromRGB(12, 12, 14))
            Panel.BorderSizePixel = 0
            Panel.Parent = Gui

            Corner(Panel, 6)
            Stroke(Panel, Line, 1)

            local Title = Text(Panel, Options.Title or "Select Chicken", 16, Ink)
            Title.Size = UDim2.fromOffset(240, 18)
            Title.Position = UDim2.fromOffset(16, 12)

            local Count = Text(Panel, "", 12, Ink, 0.5, true)
            Count.Size = UDim2.fromOffset(300, 14)
            Count.Position = UDim2.fromOffset(16, 31)

            local Box = Instance.new("TextBox")
            Box.Size = UDim2.fromOffset(186, 28)
            Box.Position = UDim2.new(1, -246, 0, 16)
            Box.BackgroundColor3 = Control
            Box.BorderSizePixel = 0
            Box.PlaceholderText = "Search"
            Box.PlaceholderColor3 = Ink
            Box.Text = ""
            Box.TextColor3 = Ink
            Box.TextSize = 13
            Box.FontFace = Library.Font
            Box.ClearTextOnFocus = false
            Box.Parent = Panel

            Corner(Box, 5)

            local Padding = Instance.new("UIPadding")
            Padding.PaddingLeft = UDim.new(0, 10)
            Padding.PaddingRight = UDim.new(0, 10)
            Padding.Parent = Box

            local Shut = Instance.new("TextButton")
            Shut.Size = UDim2.fromOffset(28, 28)
            Shut.Position = UDim2.new(1, -44, 0, 16)
            Shut.BackgroundColor3 = Control
            Shut.BorderSizePixel = 0
            Shut.Text = "\u{2715}"
            Shut.TextColor3 = Ink
            Shut.TextSize = 13
            Shut.FontFace = Library.Font
            Shut.AutoButtonColor = false
            Shut.Parent = Panel

            Corner(Shut, 5)

            BindClick(Shut, function()
                Close()
            end)

            local Divider = Fill(Panel, Line)
            Divider.Size = UDim2.new(1, -32, 0, 1)
            Divider.Position = UDim2.fromOffset(16, 56)

            Grid = Instance.new("ScrollingFrame")
            Grid.Size = UDim2.new(1, -32, 1, -116)
            Grid.Position = UDim2.fromOffset(16, 68)
            Grid.BackgroundTransparency = 1
            Grid.BorderSizePixel = 0
            Grid.ScrollBarThickness = 3
            Grid.ScrollBarImageColor3 = Line
            Grid.CanvasSize = UDim2.new()
            Grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
            Grid.Parent = Panel

            local Layout = Instance.new("UIGridLayout")
            Layout.CellSize = UDim2.fromOffset(146, 174)
            Layout.CellPadding = UDim2.fromOffset(10, 10)
            Layout.SortOrder = Enum.SortOrder.LayoutOrder
            Layout.Parent = Grid

            local Bottom = Instance.new("UIPadding")
            Bottom.PaddingBottom = UDim.new(0, 10)
            Bottom.Parent = Grid

            local Rule = Fill(Panel, Line)
            Rule.Size = UDim2.new(1, -32, 0, 1)
            Rule.Position = UDim2.new(0, 16, 1, -48)

            local Chosen = Text(Panel, "", 12, Ink, 0.4, true)
            Chosen.Size = UDim2.new(1, -160, 0, 32)
            Chosen.Position = UDim2.new(0, 16, 1, -40)

            local Clear = Instance.new("TextButton")
            Clear.Size = UDim2.fromOffset(112, 26)
            Clear.Position = UDim2.new(1, -128, 1, -37)
            Clear.BackgroundColor3 = Control
            Clear.BorderSizePixel = 0
            Clear.Text = "Clear"
            Clear.TextColor3 = Ink
            Clear.TextSize = 12
            Clear.FontFace = Library.Font
            Clear.AutoButtonColor = false
            Clear.Parent = Panel

            Corner(Clear, 5)

            BindClick(Clear, function()
                Choose(nil)
            end)

            -- The incubator picker offers everything but the active chicken, and the server
            -- would refuse that one anyway -- fusion and event pickers have no such rule, the
            -- active fighter is a perfectly good fuse champion or event entrant. Rarest first,
            -- then highest level, because that is the order somebody picking a layer cares about.
            local List = { }

            for _, Chicken in ipairs(Fight.List(Roster)) do
                if not (Options.ExcludeActive and Chicken.id == Roster.activeId) then
                    table.insert(List, Chicken)
                end
            end

            table.sort(List, function(Left, Right)
                local LeftRank = Fight.Rank[RarityOf(Left)] or 1
                local RightRank = Fight.Rank[RarityOf(Right)] or 1

                if LeftRank ~= RightRank then return LeftRank > RightRank end

                return (tonumber(Left.level) or 1) > (tonumber(Right.level) or 1)
            end)

            local Selected = ChosenFor(Options.Key)

            for Index, Chicken in ipairs(List) do
                AddCard(Chicken, Chicken.id == Selected)

                Cards[#Cards].Frame.LayoutOrder = Index
            end

            Count.Text = Options.ExcludeActive
                and string.format("%d in the flock, the active fighter aside", #List)
                or string.format("%d in the flock", #List)
            Chosen.Text = SummaryFor(Options.Key)

            TrackModal(Box:GetPropertyChangedSignal("Text"):Connect(function()
                Query = Box.Text

                ApplyQuery()
            end))

            TrackModal(Grid:GetPropertyChangedSignal("CanvasPosition"):Connect(Refresh))

            TrackModal(UserInputService.InputBegan:Connect(function(Input, Typed)
                if not Typed and Input.KeyCode == Enum.KeyCode.Escape then
                    Close()
                end
            end))

            -- the grid has no laid-out positions on the frame it is built, and Refresh reads
            -- exactly those, so give it a few frames and let the layout itself say when it moves
            TrackModal(Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(Refresh))

            task.spawn(function()
                for _ = 1, 3 do
                    task.wait()

                    if not Gui then return end

                    Refresh()
                end
            end)
        end)

        if not Ok then
            warn("[ValkyrieHub] Error opening chicken picker: " .. tostring(Err))
            CloseNow()
        end
    end

    -- one instance per setting key: same window, same rig cache, same everything -- only the
    -- setting written, the exclude-active rule and the title differ
    function Picker.New(Options)
        local Instance = {
            Key = Options.Key,
            Title = Options.Title,
            ExcludeActive = Options.ExcludeActive
        }

        function Instance.Open()
            Elevated(function() OpenNow(Instance) end)
        end

        function Instance.Close()
            Close()
        end

        function Instance.Chosen()
            return ChosenFor(Instance.Key)
        end

        function Instance.Summary()
            return SummaryFor(Instance.Key)
        end

        return Instance
    end

    Picker.Occupant = Occupant

    Picker.Incubator = Picker.New({ Key = "IncubatorChickenId", Title = "Select Chicken", ExcludeActive = true })
    Picker.Fuse = Picker.New({ Key = "FuseChickenId", Title = "Select Fuse Target", ExcludeActive = false })
    Picker.Event = Picker.New({ Key = "EventChickenId", Title = "Select Event Fighter", ExcludeActive = false })
end

IncubatorSection:Toggle({
    Name = "Auto Claim Incubator Eggs",
    Flag = "GFCAutoClaimIncubator",
    Default = getgenv().Settings.Main.AutoClaimIncubator,
    Callback = function(Value)
        getgenv().Settings.Main.AutoClaimIncubator = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoClaimIncubator", 5, function()
            local Machine = MyIncubator()

            if not Machine then return end

            -- locked until the third rebirth, and an empty tray is not worth a remote call
            if Machine:GetAttribute("Unlocked") ~= true then return end
            if (tonumber(Machine:GetAttribute("Eggs")) or 0) <= 0 then return end

            -- IncubatorClaim takes no arguments: it empties the whole tray in one call, which
            -- is exactly what the ClaimEggs button in the game's own frame invokes
            Ask(Remotes.defs.IncubatorClaim)
        end)
    end
})

IncubatorSection:Toggle({
    Name = "Auto Upgrade Incubator",
    Flag = "GFCAutoUpgradeIncubator",
    Default = getgenv().Settings.Main.AutoUpgradeIncubator,
    Callback = function(Value)
        getgenv().Settings.Main.AutoUpgradeIncubator = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoUpgradeIncubator", 5, function()
            local Machine = MyIncubator()

            if not Machine then return end

            local Level = tonumber(Machine:GetAttribute("Level")) or 0
            local Rebirth = GetData("rebirth")
            local Count = type(Rebirth) == "table" and (Rebirth.count or 0) or 0

            -- canUpgrade is the same call the game's own UPGRADE button is greyed out by, and
            -- it covers both ends: the level ceiling and the rebirth each level asks for. At
            -- level 0 this is the purchase that unlocks the machine in the first place.
            if not IncubatorView.canUpgrade(Level, Count) then return end
            if not CanAfford(IncubatorView.upgradeCost(Level + 1)) then return end

            Ask(Remotes.defs.IncubatorUpgrade)
        end)
    end
})

IncubatorSection:Toggle({
    Name = "Auto Insert Chicken",
    Flag = "GFCAutoInsertIncubator",
    Default = getgenv().Settings.Main.AutoInsertIncubator,
    Callback = function(Value)
        getgenv().Settings.Main.AutoInsertIncubator = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoInsertIncubator", 5, function()
            local Machine = MyIncubator()

            if not Machine then return end
            if Machine:GetAttribute("Unlocked") ~= true then return end

            -- Nothing is chosen for it to put in, and choosing on the player's behalf is not a
            -- small thing: the occupant decides the egg pool, and it is one of their chickens
            -- taken out of the flock either way. Select Chicken is how that is said.
            local Wanted = Picker.Incubator.Chosen()

            if not Wanted then return end

            local Inside = Picker.Occupant()

            if Inside == Wanted then return end

            local Roster = GetRoster()

            if not Roster then return end
            if Roster.activeId == Wanted then return end

            local Held = false

            for _, Chicken in ipairs(Fight.List(Roster)) do
                if Chicken.id == Wanted then
                    Held = true

                    break
                end
            end

            if not Held then return end

            -- one step a pass: the machine takes one bird, so the wrong one comes out first and
            -- the right one goes in on the pass after, off a save that has caught up
            if Inside then
                Ask(Remotes.defs.IncubatorRemove)

                return
            end

            Ask(Remotes.defs.IncubatorInsert, Wanted)
        end)
    end
})

do
    local Select = IncubatorSection:Button({
        Name = "Select Chicken",
        Callback = function()
            Picker.Incubator.Open()
        end
    })

    -- The library's own Button:Press paints the row accent red with black text, sleeps a fifth
    -- of a second, and only then runs the callback -- a confirmation flash, which is right for
    -- a button that does a thing and wrong for one that opens a window. The click handler calls
    -- Press through the table rather than by upvalue, so replacing it here is enough, and the
    -- window now opens on the frame it is asked for instead of a flash later.
    if type(Select) == "table" then
        function Select:Press()
            Library:SafeCall(self.Callback)
        end
    end
end

---- ============ Scrap ============ ----

local ScrapSection = WorldPage:Section({
    Name = "Scrap",
    Description = "Scrap automation",
    Icon = "140417023381961",
    Side = 1,
    EnableToggle = true
})

ScrapSection:Toggle({
    Name = "Auto Grab Scrap",
    Flag = "GFCAutoGrabScrap",
    Default = getgenv().Settings.Main.AutoGrabScrap,
    Callback = function(Value)
        getgenv().Settings.Main.AutoGrabScrap = Value
        SaveSetting()

        if not Value then
            StopNoclip()
            return
        end

        Loop("AutoGrabScrap", 0.2, function()
            local Root = GetRootPart()
            local Humanoid = GetHumanoid()

            if not (Root and Humanoid) then return end
            if MovementBusy() then return end

            if HotEggBusy() or EventDropsBusy(Root.Position) then return end

            local Carry = CarriedPieces()
            local PieceCap = GameConfig.scrap.pieceCap or 24
            local Limit = math.clamp(getgenv().Settings.Main.ScrapLimit or PieceCap, 1, PieceCap)

            TrackPickup(Carry)

            local Target

            if Carry >= Limit then
                Target = MyRecycler()
            else
                Target = NearestStack(Root.Position, nil)

                if Target and not PickupReady((Target.Position - Root.Position).Magnitude) then
                    return
                end
            end

            if not Target then return end

            Humanoid:MoveTo(Target.Position)
            StartNoclip()
        end)
    end
})

ScrapSection:Slider({
    Name = "Limit Scrap",
    Flag = "GFCScrapLimit",
    Min = 1,
    Max = GameConfig.scrap.pieceCap or 24,
    Default = getgenv().Settings.Main.ScrapLimit,
    Suffix = " pcs",
    Callback = function(Value)
        getgenv().Settings.Main.ScrapLimit = Value
        SaveSetting()
    end
})

---- ============ Event ============ ----

local EventSection = WorldPage:Section({
    Name = "Event",
    Description = "World event automation",
    Icon = "88536886295174",
    Side = 1,
    EnableToggle = true
})

EventSection:Toggle({
    Name = "Auto Event Drops",
    Flag = "GFCAutoEventDrops",
    Default = getgenv().Settings.Main.AutoEventDrops,
    Callback = function(Value)
        getgenv().Settings.Main.AutoEventDrops = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoEventDrops", 0.2, function()
            local Root = GetRootPart()
            local Humanoid = GetHumanoid()

            if not (Root and Humanoid) then return end
            if MovementBusy() then return end

            if HotEggBusy() then return end
            if not EventLive() then return end

            local Carry = CarriedPieces()

            TrackPickup(Carry)

            local Target

            if Carry > 0 then
                Target = MyRecycler()
            else
                Target = NearestStack(Root.Position, WantedDropKinds())

                if Target and not PickupReady((Target.Position - Root.Position).Magnitude) then
                    return
                end
            end

            if not Target then return end

            Humanoid:MoveTo(Target.Position)
        end)
    end
})

EventSection:Dropdown({
    Name = "Drop Kinds",
    Flag = "GFCEventDropKinds",
    Items = EventDropKinds,
    Default = getgenv().Settings.Main.EventDropKinds,
    Multi = true,
    Callback = function(Value)
        getgenv().Settings.Main.EventDropKinds = Value
        SaveSetting()
    end
})

local EventPitSentAt = 0

local function SendChickenToPit(Id)
    if workspace:GetAttribute("EventId") ~= Id then return end
    if not EventLive() then return end

    if not ChickenClaim("event") then return end

    -- same pattern StartTowerRun uses: swap the active chicken to the picked one and send on
    -- the next pass, off a plot model that has caught up. A pick that has been sold or fused
    -- away since is ignored rather than retried forever -- whatever is active goes instead.
    local Wanted = Picker.Event.Chosen()

    if Wanted then
        local Roster = GetRoster()

        if Roster and Roster.activeId ~= Wanted then
            if Claimed("SetActiveChicken", Ask(Remotes.defs.SetActiveChicken, Wanted)) then
                Remotes.invoke(Remotes.defs.SetChickenFavorite, Wanted, true)
            end

            return
        end
    end

    local Body = MyChickenBody()

    if not Body then return end

    local Arena = MyArena()

    if Arena and Arena:GetAttribute("TowerActive") == true then
        if os.clock() - EventPitSentAt >= 6 then
            EventPitSentAt = os.clock()

            Remotes.fire(Remotes.defs.SetChickenOrder, "coop")
            Remotes.invoke(Remotes.defs.TowerSurrender)
        end

        return
    end

    local State = ChickenStateOf(Body)

    if State == "pit" or State == "campaign" then return end

    if (Body:GetAttribute("ovHpFrac") or 1) < ChaosMinHealth then return end

    if os.clock() - EventPitSentAt < 6 then return end

    EventPitSentAt = os.clock()

    Remotes.fire(Remotes.defs.SetChickenOrder, "chaos")
end

EventSection:Toggle({
    Name = "Auto Boss Fight",
    Flag = "GFCAutoBossFight",
    Default = getgenv().Settings.Main.AutoBossFight,
    Callback = function(Value)
        getgenv().Settings.Main.AutoBossFight = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoBossFight", 2, function()
            SendChickenToPit("chickenBoss")
        end)
    end
})

EventSection:Toggle({
    Name = "Auto UFO Beam",
    Flag = "GFCAutoUfoBeam",
    Default = getgenv().Settings.Main.AutoUfoBeam,
    Callback = function(Value)
        getgenv().Settings.Main.AutoUfoBeam = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoUfoBeam", 2, function()
            SendChickenToPit("ufo")
        end)
    end
})


local EncouragedAt = 0

EventSection:Toggle({
    Name = "Auto Encourage",
    Flag = "GFCAutoEncourage",
    Default = getgenv().Settings.Main.AutoEncourage,
    Callback = function(Value)
        getgenv().Settings.Main.AutoEncourage = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoEncourage", 2, function()
            local Body = MyChickenBody()

            if not Body then return end
            if ChickenStateOf(Body) ~= "pit" then return end

            local Root = GetRootPart()

            if not Root then return end

            local Flat = Root.Position - PitZone.center

            if Vector3.new(Flat.X, 0, Flat.Z).Magnitude > PitZone.radius then return end

            if os.clock() - EncouragedAt < (GameConfig.pit.encourage.cooldown or 15) then return end

            EncouragedAt = os.clock()

            Ask(Remotes.defs.EncourageChicken)
        end)
    end
})

EventSection:Toggle({
    Name = "Auto Hot Egg",
    Flag = "GFCAutoHotEgg",
    Default = getgenv().Settings.Main.AutoHotEgg,
    Callback = function(Value)
        getgenv().Settings.Main.AutoHotEgg = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoHotEgg", 0.25, function()
            local Egg = HotEgg()

            if not Egg then return end

            local Root = GetRootPart()
            local Humanoid = GetHumanoid()

            if not (Root and Humanoid) then return end
            if MovementBusy() then return end

            local Carrier = Egg:GetAttribute("Carrier")

            if Carrier == LocalPlayer.UserId then
                Humanoid:MoveTo(DodgePoint(Root.Position))
            else
                Humanoid:MoveTo(Egg.Position)
            end
        end)
    end
})

do
    local Select = EventSection:Button({
        Name = "Select Chicken",
        Callback = function()
            Picker.Event.Open()
        end
    })

    -- same override as the incubator's picker button: opens the window on the frame it is
    -- asked for instead of the library's red confirmation flash
    if type(Select) == "table" then
        function Select:Press()
            Library:SafeCall(self.Callback)
        end
    end
end

---- ============ Rebirth ============ ----

local RebirthSection = ProgressPage:Section({
    Name = "Rebirth",
    Description = "Rebirth automation",
    Icon = "81819858538839",
    Side = 1,
    EnableToggle = true
})

-- Shut in a block: nothing below reads these, and the main chunk is at Luau's ceiling of
-- two hundred active locals per function.

do
local RebirthOrderAt = 0
local RebirthTriedAt = 0
local RebirthRefusals = 0

-- Rebirth used to be driven off Ask(Remotes.defs.Rebirth), and that is what made it slow: Ask
-- backs a failed name off ten seconds and doubles to two minutes, so one refusal -- the plot
-- attribute reading corral a beat before the server agreed -- parked the whole feature. On top
-- of that sat a fixed six second wait every time the order went out and a flat ten second
-- retry, so a rebirth that was ready could sit for minutes before the call even went out.
--
-- What went in for the fix was worse than what it replaced: opening the Rebirth screen,
-- selecting its confirm button and sending Return through VirtualInputManager to fire it
-- without a real key on a real keyboard behind it. That got the account kicked mid-test
-- ("removed for cheating"), so this stays a plain server call -- the same
-- Remotes.invoke(Remotes.defs.Rebirth) the button itself makes, nothing simulated in front of
-- it, no window opened, no selection touched.
--
-- The speed comes from tighter polling instead: the loop already runs every 0.5s, the retry
-- gap after a send is 1.5s instead of ten, and the order-home wait is however long the walk
-- actually takes rather than a flat six -- both read off the game's own state (ChickenMode,
-- ovState) rather than guessed at.
local RebirthRetry = 1.5
local RebirthRetryCap = 20
local RebirthOrderCooldown = 2

-- A press that goes through costs nothing to repeat, but a press the server REFUSES is a
-- rejected call every retry, and a rejected call every 1.5s is the shape of a thing worth
-- backing off from on its own. So the gap doubles per refusal up to twenty seconds and drops
-- back to 1.5 the moment a rebirth actually lands.
local function RebirthGap()
    if RebirthRefusals < 1 then return RebirthRetry end

    return math.min(RebirthRetryCap, RebirthRetry * 2 ^ RebirthRefusals)
end

local function RebirthCount()
    local Rebirth = GetData("rebirth")

    return type(Rebirth) == "table" and (Rebirth.count or 0) or 0
end

-- ChickenMode is the same pair the rebirth screen itself watches (order() is what was asked
-- for, where() is where the bird is this frame) -- reading it is a plain table call, nothing
-- sent anywhere and nothing the server or an anti-cheat can see. Falls back to the plot's own
-- ovState attribute when the atoms were not found.
local function ChickenOrder()
    local Ok, Order = pcall(ChickenMode.order)

    if Ok and type(Order) == "string" then return Order end
end

local function ChickenWhere(Body)
    local Ok, Where = pcall(ChickenMode.where)

    if Ok and type(Where) == "string" then return Where end

    return ChickenStateOf(Body)
end

local function OrderHome()
    if os.clock() - RebirthOrderAt < RebirthOrderCooldown then return end

    RebirthOrderAt = os.clock()

    Remotes.fire(Remotes.defs.SetChickenOrder, "coop")
end

RebirthSection:Toggle({
    Name = "Auto Rebirth",
    Flag = "GFCAutoRebirth",
    Default = getgenv().Settings.Main.AutoRebirth,
    Callback = function(Value)
        getgenv().Settings.Main.AutoRebirth = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoRebirth", 0.5, function()
            if not RebirthReady() then
                -- readiness gone is either the rebirth that just landed or a requirement that
                -- moved; neither is the refusal the gap was widening for
                RebirthRefusals = 0

                return
            end

            if not ChickenClaim("rebirth") then return end

            local Body = MyChickenBody()

            if not Body then return end

            local Arena = MyArena()

            if Arena and Arena:GetAttribute("TowerActive") == true then
                if os.clock() - RebirthOrderAt >= RebirthOrderCooldown then
                    RebirthOrderAt = os.clock()

                    Remotes.fire(Remotes.defs.SetChickenOrder, "coop")
                    Remotes.invoke(Remotes.defs.TowerSurrender)
                end

                return
            end

            local Order = ChickenOrder()

            if Order ~= nil and Order ~= "coop" then
                OrderHome()

                return
            end

            -- Order comes back nil when the atoms were not found -- then the order goes out
            -- blind on its cooldown and the plot attribute is all there is to read the arrival
            -- off. With the atoms in hand the order is already coop here and only the walk,
            -- polled at the loop's own 0.5s rather than waited on with a flat timer, is left.
            if ChickenWhere(Body) ~= "corral" then
                if Order == nil then
                    OrderHome()
                end

                return
            end

            if os.clock() - RebirthTriedAt < RebirthGap() then return end

            RebirthTriedAt = os.clock()

            local Before = RebirthCount()
            local Reply = Remotes.invoke(Remotes.defs.Rebirth)

            if type(Reply) == "table" and Reply.ok then
                RebirthRefusals = 0

                return
            end

            -- the count is replicated and can lag a reply that came back ok late, so it is
            -- checked either way before counting this as a refusal
            if RebirthCount() > Before then
                RebirthRefusals = 0

                return
            end

            RebirthRefusals = RebirthRefusals + 1
        end)
    end
})

end

---- ============ Plot ============ ----

local PlotSection = ProgressPage:Section({
    Name = "Plot",
    Description = "Coop and recycler upgrades",
    Icon = "140417023381961",
    Side = 1,
    EnableToggle = true
})

PlotSection:Toggle({
    Name = "Auto Upgrade Coop",
    Flag = "GFCAutoUpgradeCoop",
    Default = getgenv().Settings.Main.AutoUpgradeCoop,
    Callback = function(Value)
        getgenv().Settings.Main.AutoUpgradeCoop = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoUpgradeCoop", 1, function()
            local Coop = GetCoop()

            if not (Coop and CoopView.canExpand(Coop.slots)) then return end
            if not CanAfford(CoopView.expandCost(Coop.slots)) then return end

            Ask(Remotes.defs.ExpandCoop)
        end)
    end
})

PlotSection:Toggle({
    Name = "Auto Upgrade Feeder",
    Flag = "GFCAutoUpgradeFeeder",
    Default = getgenv().Settings.Main.AutoUpgradeFeeder,
    Callback = function(Value)
        getgenv().Settings.Main.AutoUpgradeFeeder = Value
        SaveSetting()

        if not Value then return end

        -- UpgradeGenerator has its own fast lane in the remote budget, so a tick bursts
        -- through as many upgrades as the server and the purse allow rather than sending one
        -- and waiting a second for the reply to come back through `coop`. The burst tracks
        -- level and money locally rather than re-reading Coop mid-loop -- a save round-trip
        -- lags behind a successful call, so a re-read would just see the same stale numbers
        -- and buy nothing on the next few steps.
        Loop("AutoUpgradeFeeder", 1, function()
            local Coop = GetCoop()

            if not Coop then return end

            local Levels = { }

            for _, Generator in ipairs(Coop.generators) do
                local Slot = tonumber(Generator.slot)
                local Level = tonumber(Generator.level) or 1

                if Slot then
                    Levels[Slot] = Level
                end
            end

            local Money = GetData("money")

            if type(Money) ~= "number" then return end

            Money = Money - FeederReserve()

            for _ = 1, 40 do
                if not getgenv().Settings.Main.AutoUpgradeFeeder then return end

                local Wanted, WantedCost = nil, nil

                for Slot, Level in pairs(Levels) do
                    if CoopView.canUpgrade(Level) then
                        local Cost = CoopView.upgradeCost(Level)

                        if type(Cost) ~= "number" then
                            Cost = math.huge
                        end

                        if not WantedCost or Cost < WantedCost then
                            Wanted = Slot
                            WantedCost = Cost
                        end
                    end
                end

                if not Wanted then return end
                if WantedCost > Money then return end

                local Reply = Ask(Remotes.defs.UpgradeGenerator, Wanted)

                if not Claimed("UpgradeGenerator", Reply) then return end

                Levels[Wanted] = Levels[Wanted] + 1
                Money = Money - WantedCost
            end
        end)
    end
})

PlotSection:Toggle({
    Name = "Auto Buy Feeder",
    Flag = "GFCAutoBuyFeeder",
    Default = getgenv().Settings.Main.AutoBuyFeeder,
    Callback = function(Value)
        getgenv().Settings.Main.AutoBuyFeeder = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoBuyFeeder", 1, function()
            local Coop = GetCoop()

            if not Coop then return end

            local Feeders = #Coop.generators

            if not CoopView.canBuyGenerator(Coop.slots, Feeders) then return end
            if not CanAfford(CoopView.buyGeneratorCost(Feeders), true) then return end

            Ask(Remotes.defs.BuyGenerator, Feeders + 1)
        end)
    end
})

PlotSection:Toggle({
    Name = "Auto Buy Recycler",
    Flag = "GFCAutoBuyRecycler",
    Default = getgenv().Settings.Main.AutoBuyRecycler,
    Callback = function(Value)
        getgenv().Settings.Main.AutoBuyRecycler = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoBuyRecycler", 1, function()
            local Level = RecyclerState()

            if not (Level and Level < 1) then return end
            if not CanAfford(RecyclerView.upgradeCost(Level)) then return end

            Ask(Remotes.defs.UpgradeRecycler)
        end)
    end
})

PlotSection:Toggle({
    Name = "Auto Upgrade Recycler",
    Flag = "GFCAutoUpgradeRecycler",
    Default = getgenv().Settings.Main.AutoUpgradeRecycler,
    Callback = function(Value)
        getgenv().Settings.Main.AutoUpgradeRecycler = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoUpgradeRecycler", 1, function()
            local Level = RecyclerState()

            if not (Level and Level >= 1) then return end
            if not CanAfford(RecyclerView.upgradeCost(Level)) then return end

            Ask(Remotes.defs.UpgradeRecycler)
        end)
    end
})

---- ============ Tower ============ ----

local TowerSection = ProgressPage:Section({
    Name = "Tower",
    Description = "Tower run automation",
    Icon = "95937619060532",
    Side = 2,
    EnableToggle = true
})

-- Shut in a block: nothing below reads any of these, and the main chunk is at Luau's
-- ceiling of two hundred active locals per function.

do
local ElevatorCatalog = Modules.ElevatorCatalog
local ElevatorRescanAt = 0

local function ElevatorCost(Floor, Best)
    if not ElevatorCatalog and os.clock() >= ElevatorRescanAt then
        ElevatorRescanAt = os.clock() + 30

        ScanGarbage(function(Value)
            if type(rawget(Value, "elevatorCost")) == "function" then
                ElevatorCatalog = Value

                return true
            end
        end)
    end

    if not ElevatorCatalog then return end

    local Purchases = GetData("purchases")
    local Passes = type(Purchases) == "table" and Purchases.passes or nil

    local Ok, Cost = pcall(ElevatorCatalog.elevatorCost, {
        restricted = true,
        prices = { },
        towerBest = Best,
        rewardFloor = Best,
        owned = { elevatorVip = type(Passes) == "table" and Passes.elevatorVip == true },
        boosts = { money = 0, corn = 0 }
    }, Floor)

    return Ok and tonumber(Cost) or nil
end

local function ElevatorFloor()
    local Best = TowerBest()
    local MinFloor = GameConfig.premium.elevator.minFloor or 2
    local Money = GetData("money")
    local Level = TowerFighterLevel()

    if type(Money) ~= "number" then return Best + 1 end

    -- Half the purse, never all of it, and never the part being held for the first feeder. The
    -- elevator is bought before every run, and a ride priced at everything the player has left
    -- the plot loops unable to afford the feeder -- which is the only thing that levels the
    -- chicken the tower then refuses to send.
    local Budget = math.floor(Money / 2) - FeederReserve()

    -- nothing to spend: say so here rather than pricing every floor down to the bottom first
    if Budget <= 0 then return end

    for Floor = Best + 1, MinFloor, -1 do
        -- Riding above the fighter's own level buys a rival it cannot beat: the money is gone,
        -- the floor is not cleared, and best is exactly where it was. Walk down to a floor the
        -- chicken can actually take, or take none.
        if Level == nil or TowerRivalLevel(Floor) <= Level then
            local Cost = ElevatorCost(Floor, Best)

            if not Cost then return Best + 1 end

            if Cost <= Budget then return Floor end
        end
    end
end

-- Returns true only when a run was actually asked for. Swapping the active fighter is a pass
-- of its own and returns false: it is not a start, and counting it as one meant the caller sat
-- through the grace period waiting for a run nobody had requested, then blocked itself.
local function StartTowerRun()
    if getgenv().Settings.Main.TowerBestFighter then
        local Roster = GetRoster()
        local Fighter = Roster and Fight.Best(Roster)

        if Fighter and Roster.activeId ~= Fighter.id then
            if Claimed("SetActiveChicken", Ask(Remotes.defs.SetActiveChicken, Fighter.id)) then
                Remotes.invoke(Remotes.defs.SetChickenFavorite, Fighter.id, true)
            end

            return false
        end
    end

    -- The game only offers the elevator once the tower has been climbed past its bottom, and the
    -- server refuses the ride below that. Asking anyway spent the ask on a rejection, and the
    -- backoff that rejection earns is shared by every later ride that would have been allowed.
    local MinFloor = GameConfig.premium.elevator.minFloor or 2

    if getgenv().Settings.Main.TowerSkipBest and TowerBest() >= MinFloor + 1 then
        local Floor = ElevatorFloor()

        if Floor and Floor >= MinFloor then
            Ask(Remotes.defs.TowerElevator, Floor)
        end
    end

    return Claimed("TowerStart", Ask(Remotes.defs.TowerStart))
end

local TowerStartedAt = 0
local TowerStartGrace = 12
local TowerPending = false

local TowerFedAt = 0

-- Below the Min Level slider there is nothing for the tower to do but wait, and waiting is not
-- passive: a chicken levels by eating at the feeder, and it only eats at home. So the bird is
-- sent to the coop and left there until the slider is satisfied, which is the difference between
-- a tower that resumes after a rebirth and one that waits for a level nothing was raising.
--
-- Answers true while that is what should be happening -- the tower's cue to stand down for the
-- pass. A run already under way is never routed through here.
local function TowerFeeding(State)
    local MinLevel = tonumber(getgenv().Settings.Main.TowerMinLevel) or 1

    if MinLevel <= 1 then return false end

    local Level = TowerFighterLevel()

    if Level ~= nil and Level >= MinLevel then return false end

    -- a rebirth, an event or the pit may hold a better claim on the bird, and none of them are
    -- interrupted for this: they are all doing something, and this is only waiting
    if ChickenOwner() ~= nil then return true end

    if State ~= "corral" and os.clock() - TowerFedAt >= 8 then
        TowerFedAt = os.clock()

        Remotes.fire(Remotes.defs.SetChickenOrder, "coop")
    end

    return true
end

TowerSection:Toggle({
    Name = "Auto Tower",
    Flag = "GFCAutoTower",
    Default = getgenv().Settings.Main.AutoTower,
    Callback = function(Value)
        getgenv().Settings.Main.AutoTower = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoTower", 2, function()
            local Arena = MyArena()

            if not Arena then
                TowerBlockedUntil = os.clock() + 30

                return
            end

            local Body = MyChickenBody()

            if not Body then return end

            local State = ChickenStateOf(Body)

            if Arena:GetAttribute("TowerActive") == true or State == "campaign" then
                TowerPending = false
                TowerBlockedUntil = 0

                return
            end

            -- The level floor is answered before the claim rather than behind it: the claim is
            -- exactly what a fighter under the floor is denied, so a loop that asked for it
            -- first could never reach the step that raises the level it was refused for.
            if TowerFeeding(State) then return end

            if not ChickenClaim("tower") then return end

            -- a start we asked for that never turned into a live run: stand down for half a
            -- minute so the chicken goes to whatever else wants it, then try again
            if TowerPending and os.clock() - TowerStartedAt > TowerStartGrace then
                TowerPending = false
                TowerBlockedUntil = os.clock() + 30

                return
            end

            if os.clock() - TowerStartedAt < TowerStartGrace then return end

            if State == "pit" then
                Remotes.fire(Remotes.defs.SetChickenOrder, "coop")

                return
            end

            local MinHealth = (getgenv().Settings.Main.TowerMinHealth or 80) / 100

            if (Body:GetAttribute("ovHpFrac") or 1) < MinHealth then return end

            TowerStartedAt = os.clock()
            TowerPending = StartTowerRun() == true
        end)
    end
})

end

TowerSection:Toggle({
    Name = "Send Best Fighter",
    Flag = "GFCTowerBestFighter",
    Default = getgenv().Settings.Main.TowerBestFighter,
    Callback = function(Value)
        getgenv().Settings.Main.TowerBestFighter = Value
        SaveSetting()
    end
})

TowerSection:Toggle({
    Name = "Skip to Best Floor",
    Flag = "GFCTowerSkipBest",
    Default = getgenv().Settings.Main.TowerSkipBest,
    Callback = function(Value)
        getgenv().Settings.Main.TowerSkipBest = Value
        SaveSetting()
    end
})

TowerSection:Slider({
    Name = "Min Health",
    Flag = "GFCTowerMinHealth",
    Min = 0,
    Max = 100,
    Default = getgenv().Settings.Main.TowerMinHealth,
    Suffix = " %",
    Callback = function(Value)
        getgenv().Settings.Main.TowerMinHealth = Value
        SaveSetting()
    end
})

TowerSection:Slider({
    Name = "Min Level",
    Flag = "GFCTowerMinLevel",
    Min = 1,
    Max = 100,
    Default = getgenv().Settings.Main.TowerMinLevel,
    Callback = function(Value)
        getgenv().Settings.Main.TowerMinLevel = Value
        SaveSetting()
    end
})

TowerSection:Toggle({
    Name = "Auto Decline Continue",
    Flag = "GFCAutoDeclineContinue",
    Default = getgenv().Settings.Main.AutoDeclineContinue,
    Callback = function(Value)
        getgenv().Settings.Main.AutoDeclineContinue = Value
        SaveSetting()
    end
})

TowerSection:Button({
    Name = "Surrender",
    Callback = function()
        local Arena = MyArena()

        if not (Arena and Arena:GetAttribute("TowerActive") == true) then return end

        Remotes.fire(Remotes.defs.SetChickenOrder, "coop")
        Remotes.invoke(Remotes.defs.TowerSurrender)
    end
})

---- ============ Arena ============ ----

local ArenaTeamSection = ArenaPage:Section({
    Name = "Team",
    Description = "Arena team selection",
    Icon = "117851493400222",
    Side = 1,
    EnableToggle = true
})

local ArenaBattleSection = ArenaPage:Section({
    Name = "Battle",
    Description = "Arena battles",
    Icon = "95937619060532",
    Side = 2,
    EnableToggle = true
})

local ArenaRewardSection = ArenaPage:Section({
    Name = "Rewards",
    Description = "Arena rank rewards",
    Icon = "109855212076373",
    Side = 1,
    EnableToggle = true
})

local ArenaBands = { "even", "easier", "harder", "wildcard" }

local ArenaBattleLive = false

TrackConnection(Remotes.onClient(Remotes.defs.ArenaBattleState, function(State)
    if type(State) ~= "table" then return end

    if State.phase == "started" then
        ArenaBattleLive = true
    elseif State.phase == "finished" then
        ArenaBattleLive = false
    end
end))

TrackConnection(Remotes.onClient(Remotes.defs.ArenaBattleResult, function()
    ArenaBattleLive = false
end))

local function ArenaData()
    local Reply = Ask(Remotes.defs.ArenaGetView)

    if type(Reply) ~= "table" or not Reply.ok then return end
    if type(Reply.data) ~= "table" then return end

    return Reply.data
end

local function ArenaOpen(Data)
    return Data.unlocked ~= false and Data.available ~= false
end

local function ArenaBestIds(Data)
    return Fight.ArenaTeam(Data, GetRoster())
end

local function ArenaSameTeam(Ids, Current)
    if #Ids ~= #(Current or { }) then return false end

    for Index = 1, #Ids do
        if Ids[Index] ~= Current[Index] then return false end
    end

    return true
end

local function ArenaEquipBest(Data)
    local Ids = ArenaBestIds(Data)

    if #Ids == 0 then return false end
    if ArenaSameTeam(Ids, Data.teamIds) then return false end

    return Claimed("ArenaSetTeam", Ask(Remotes.defs.ArenaSetTeam, Ids))
end

local function ArenaOpponent(Data)
    local Opponents = Data.opponents or { }

    if #Opponents == 0 then return nil end

    return Opponents[math.min((Data.cursor or 0) + 1, #Opponents)]
end

ArenaTeamSection:Toggle({
    Name = "Auto Equip Best Team",
    Flag = "GFCAutoArenaTeam",
    Default = getgenv().Settings.Main.AutoArenaTeam,
    Callback = function(Value)
        getgenv().Settings.Main.AutoArenaTeam = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoArenaTeam", 30, function()
            local Data = ArenaData()

            if not (Data and ArenaOpen(Data)) then return end
            if Data.hasActiveMatch == true or ArenaBattleLive then return end

            ArenaEquipBest(Data)
        end)
    end
})

ArenaTeamSection:Dropdown({
    Name = "Team Mode",
    Flag = "GFCArenaTeamMode",
    Items = { "Strength", "Attack" },
    Default = getgenv().Settings.Main.ArenaTeamMode,
    Multi = false,
    Callback = function(Value)
        getgenv().Settings.Main.ArenaTeamMode = Value
        SaveSetting()
    end
})

ArenaBattleSection:Toggle({
    Name = "Auto Arena Battle",
    Flag = "GFCAutoArenaBattle",
    Default = getgenv().Settings.Main.AutoArenaBattle,
    Callback = function(Value)
        getgenv().Settings.Main.AutoArenaBattle = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoArenaBattle", 12, function()
            local Data = ArenaData()

            if not (Data and ArenaOpen(Data)) then return end

            if Data.hasActiveMatch == true or ArenaBattleLive then return end

            if Data.incomplete == true or #(Data.team or { }) == 0 then
                ArenaEquipBest(Data)

                return
            end

            local Opponent = ArenaOpponent(Data)

            if not Opponent then return end

            local Bands = { }

            for _, Band in ipairs(getgenv().Settings.Main.ArenaSkipBands or { }) do
                Bands[Band] = true
            end

            if Bands[Opponent.band] and (Data.lifetimeMatches or 0) > 0 and (Data.skips or 0) > 0 then
                Claimed("ArenaSkip", Ask(Remotes.defs.ArenaSkip))

                return
            end

            if Claimed("ArenaFight", Ask(Remotes.defs.ArenaFight)) then
                ArenaBattleLive = true
            end
        end)
    end
})

ArenaBattleSection:Dropdown({
    Name = "Skip Bands",
    Flag = "GFCArenaSkipBands",
    Items = ArenaBands,
    Default = getgenv().Settings.Main.ArenaSkipBands,
    Multi = true,
    Callback = function(Value)
        getgenv().Settings.Main.ArenaSkipBands = Value
        SaveSetting()
    end
})

ArenaBattleSection:Toggle({
    Name = "Auto Ability",
    Flag = "GFCArenaAutoAbility",
    Default = getgenv().Settings.Main.ArenaAutoAbility,
    Callback = function(Value)
        getgenv().Settings.Main.ArenaAutoAbility = Value
        SaveSetting()

        Remotes.fire(Remotes.defs.SetArenaAutoAbility, Value)
    end
})

ArenaRewardSection:Toggle({
    Name = "Auto Claim Arena Rewards",
    Flag = "GFCAutoArenaClaim",
    Default = getgenv().Settings.Main.AutoArenaClaim,
    Callback = function(Value)
        getgenv().Settings.Main.AutoArenaClaim = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoArenaClaim", 20, function()
            local Data = ArenaData()

            if not (Data and ArenaOpen(Data)) then return end

            for _, Entry in ipairs(Data.claimable or { }) do
                if type(Entry) == "table" and Entry.rankId then
                    Claimed("ArenaClaim " .. tostring(Entry.rankId), Ask(Remotes.defs.ArenaClaim, Entry.rankId))

                    return
                end
            end
        end)
    end
})

ArenaTeamSection:Button({
    Name = "Equip Best Team",
    Callback = function()
        local Data = ArenaData()

        if not (Data and ArenaOpen(Data)) then return end

        ArenaEquipBest(Data)
    end
})

---- ============ Daily ============ ----

Elevate()

local DailySection = RewardsPage:Section({
    Name = "Daily",
    Description = "Daily reward claims",
    Icon = "109855212076373",
    Side = 1,
    EnableToggle = true
})

local function MissionSnapshot()
    local Rebirth = GetData("rebirth")
    local Scrap = GetData("scrap")

    return {
        roster = GetRoster(),
        towerBest = TowerBest(),
        rebirthCount = type(Rebirth) == "table" and (Rebirth.count or 0) or 0,
        recyclerLevel = type(Scrap) == "table" and (Scrap.recyclerLevel or 0) or 0,
        missions = GetData("missions")
    }
end

DailySection:Toggle({
    Name = "Auto Claim Daily Streak",
    Flag = "GFCAutoClaimDailyStreak",
    Default = getgenv().Settings.Main.AutoClaimDailyStreak,
    Callback = function(Value)
        getgenv().Settings.Main.AutoClaimDailyStreak = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoClaimDailyStreak", 5, function()
            local Daily = GetData("daily")

            if type(Daily) ~= "table" then return end

            local Taken = type(Daily.claimed) == "table" and Daily.claimed or { }
            local Streak = Daily.streak or 0

            if Taken[DailyView.DAY_KEY] == true then return end
            if Streak < 1 or not GameConfig.daily.days[Streak] then return end

            Claimed("DailyClaim day", Ask(Remotes.defs.DailyClaim, "day", nil))
        end)
    end
})

DailySection:Toggle({
    Name = "Auto Claim Play Today",
    Flag = "GFCAutoClaimPlayToday",
    Default = getgenv().Settings.Main.AutoClaimPlayToday,
    Callback = function(Value)
        getgenv().Settings.Main.AutoClaimPlayToday = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoClaimPlayToday", 5, function()
            local Daily = GetData("daily")

            if type(Daily) ~= "table" then return end

            local Taken = type(Daily.claimed) == "table" and Daily.claimed or { }
            local Played = Daily.played or 0

            for Index = 1, #GameConfig.daily.session do
                if DailyView.sessionReady(Played, Index) and not Taken[DailyView.sessionKey(Index)] then
                    Claimed("DailyClaim session " .. Index, Ask(Remotes.defs.DailyClaim, "session", Index))

                    return
                end
            end
        end)
    end
})

---- ============ Progress ============ ----

local ProgressSection = RewardsPage:Section({
    Name = "Progress",
    Description = "Mission and pass claims",
    Icon = "80451686744860",
    Side = 2,
    EnableToggle = true
})

ProgressSection:Toggle({
    Name = "Auto Claim Missions",
    Flag = "GFCAutoClaimMissions",
    Default = getgenv().Settings.Main.AutoClaimMissions,
    Callback = function(Value)
        getgenv().Settings.Main.AutoClaimMissions = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoClaimMissions", 3, function()
            local Snapshot = MissionSnapshot()

            if type(Snapshot.missions) ~= "table" then return end

            for _, Scope in ipairs(MissionView.SCOPES) do
                for _, Mission in ipairs(MissionView.active(Scope)) do
                    if Mission.kind == nil and MissionView.stateOf(Snapshot, Mission) == "ready" then
                        Claimed("MissionClaim " .. tostring(Mission.id), Ask(Remotes.defs.MissionClaim, Mission.id))

                        return
                    end
                end
            end
        end)
    end
})

local function PendingMilestone()
    local Rebirth = GetData("rebirth")

    if type(Rebirth) ~= "table" then return end

    local Count = Rebirth.count or 0
    local Taken = type(Rebirth.claimed) == "table" and Rebirth.claimed or { }
    local Reached = RebirthMilestones.reachedCount(Count) or 0

    for Index = 1, Reached do
        local Step = RebirthMilestones.nth(Index)

        if type(Step) == "table" and Taken[tostring(Step.at)] ~= true then
            return Step.at
        end
    end
end

RebirthSection:Toggle({
    Name = "Auto Claim Rebirth Milestones",
    Flag = "GFCAutoClaimRebirthMilestones",
    Default = getgenv().Settings.Main.AutoClaimRebirthMilestones,
    Callback = function(Value)
        getgenv().Settings.Main.AutoClaimRebirthMilestones = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoClaimRebirthMilestones", 8, function()
            local At = PendingMilestone()

            if not At then return end

            if Claimed("ClaimRebirthMilestones", Ask(Remotes.defs.ClaimRebirthMilestones)) then return end

            Claimed("ClaimRebirthMilestone " .. tostring(At), Ask(Remotes.defs.ClaimRebirthMilestone, At))
        end)
    end
})

ProgressSection:Toggle({
    Name = "Auto Claim Weekly Pass",
    Flag = "GFCAutoClaimWeeklyPass",
    Default = getgenv().Settings.Main.AutoClaimWeeklyPass,
    Callback = function(Value)
        getgenv().Settings.Main.AutoClaimWeeklyPass = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoClaimWeeklyPass", 5, function()
            local Pass = GetData("pass")

            if type(Pass) ~= "table" then return end

            for Level = 1, #GameConfig.premium.pass.levels do
                if PassView.state(Pass, Level) == "claimable" then
                    Claimed("PassClaim " .. Level, Ask(Remotes.defs.PassClaim, Level, PassView.track(Level)))

                    return
                end
            end
        end)
    end
})

---- ============ Interface ============ ----

Elevate()

local InterfaceSection = ConfigPage:Section({
    Name = "Interface",
    Description = "Window and executor options",
    Icon = "93142176757189",
    Side = 1
})

InterfaceSection:Toggle({
    Name = "Window Transparency",
    Flag = "GFCTransparent",
    Default = getgenv().ConfigurationTable.Transparent,
    Callback = function(Value)
        getgenv().ConfigurationTable.Transparent = Value
        SaveConfiguration()

        local Target = Value and 0.08 or 0
        if Library.SetFlags["BackgroundTransparency"] then
            Library.SetFlags["BackgroundTransparency"](Target)
        else
            Library.Flags["BackgroundTransparency"] = Target
            Window:SetTransparency()
        end
    end
})

-- Two things this deliberately does not do, both measured in this game rather than guessed at.
--
-- It does not move the character. The old version walked it four studs out and back every
-- couple of minutes, and a body that steps around on its own is replicated: with the farm
-- holding the character tweened or parked on a platform, that reads as a teleport.
--
-- It does not touch VirtualUser. Not the click, not the held button, not even the bare
-- CaptureController() -- calling that on its own, on an otherwise clean client with no hub
-- script loaded, was followed nine seconds later by "You have been removed for cheating,
-- please remove any cheats to play". The whole service is off the table here.
--
-- What is left is the camera, which is the one thing on the client the server is never told
-- about. That does mean this only answers an AFK check that watches the camera; Roblox's own
-- idle timer counts input, and nothing safe in this game generates input.
-- Shut in a block: nothing below reads any of these, and the main chunk is at Luau's
-- ceiling of two hundred active locals per function.

do
local AntiAfk = { Focused = true }

TrackConnection(game:GetService("UserInputService").WindowFocused:Connect(function()
    AntiAfk.Focused = true
end))

TrackConnection(game:GetService("UserInputService").WindowFocusReleased:Connect(function()
    AntiAfk.Focused = false
end))

-- A degree or two of yaw and back. Applied and undone relative to wherever the camera is at
-- the time rather than snapping back to a remembered angle, so it never fights a player who
-- is actually at the keyboard, and never leaves the view crooked if they moved mid-nudge.
local function AntiAfkStep()
    local Camera = workspace.CurrentCamera

    if not Camera then return end

    local Twist = CFrame.Angles(math.rad((math.random() - 0.5) * 1.6), math.rad((math.random() - 0.5) * 3), 0)

    Camera.CFrame = Camera.CFrame * Twist
    task.wait(0.2)

    local Current = workspace.CurrentCamera

    if Current then
        Current.CFrame = Current.CFrame * Twist:Inverse()
    end
end

-- 60 seconds give or take 40%, now and then a good deal longer, never under 8. The jitter is
-- there because a nudge landing on the same beat forever is a pattern in its own right, and
-- the interval tightens while the window is unfocused, which is when an AFK check is actually
-- watching.
local function AntiAfkWait()
    local Delay = 60 + (math.random() - 0.5) * 48

    if math.random() < 0.1 then
        Delay = Delay + 15 + math.random() * 30
    end

    if not AntiAfk.Focused then
        Delay = Delay * 0.7
    end

    return math.max(8, Delay)
end

InterfaceSection:Toggle({
    Name = "Anti-AFK",
    Flag = "GFCAntiAFK",
    Default = getgenv().ConfigurationTable.AntiAFK,
    Callback = function(Value)
        getgenv().ConfigurationTable.AntiAFK = Value
        SaveConfiguration()

        if Value then
            if AntiAfk.Connection then return end

            AntiAfk.Connection = TrackConnection(LocalPlayer.Idled:Connect(function()
                -- Idled fires the moment Roblox has decided we are away, and it fires from a
                -- context we should not be yielding in, hence the thread
                task.spawn(function()
                    pcall(AntiAfkStep)

                    if not AntiAfk.Focused then
                        task.wait(2 + math.random() * 2)
                        pcall(AntiAfkStep)
                    end
                end)
            end))

            AntiAfk.Thread = task.spawn(function()
                while getgenv().ValkyrieSession == SessionToken and getgenv().ConfigurationTable.AntiAFK do
                    task.wait(AntiAfkWait())

                    if not (getgenv().ValkyrieSession == SessionToken and getgenv().ConfigurationTable.AntiAFK) then break end

                    pcall(AntiAfkStep)
                end

                AntiAfk.Thread = nil
            end)
        elseif AntiAfk.Connection then
            AntiAfk.Connection:Disconnect()
            AntiAfk.Connection = nil
            AntiAfk.Thread = nil
        end
    end
})

end

local AutoRejoinConnection = nil

InterfaceSection:Toggle({
    Name = "Auto Rejoin",
    Flag = "GFCAutoRejoin",
    Default = getgenv().ConfigurationTable.AutoRejoin,
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoRejoin = Value
        SaveConfiguration()

        if Value then
            if AutoRejoinConnection then return end

            AutoRejoinConnection = TrackConnection(game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
                if child.Name == "ErrorPrompt" then
                    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
                end
            end))
        elseif AutoRejoinConnection then
            AutoRejoinConnection:Disconnect()
            AutoRejoinConnection = nil
        end
    end
})

InterfaceSection:Toggle({
    Name = "Auto Executor",
    Flag = "GFCAutoExecutor",
    Default = getgenv().ConfigurationTable.AutoExecutor,
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoExecutor = Value
        SaveConfiguration()
    end
})

local function KeyFromName(Name)
    local Ok, Key = pcall(function()
        return Enum.KeyCode[Name]
    end)

    return (Ok and Key) or Enum.KeyCode.End
end

InterfaceSection:Keybind({
    Name = "Minimize Bind",
    Flag = "GFCMinimizeBind",
    Default = KeyFromName(getgenv().ConfigurationTable.MinimizeBind),
    Mode = "Toggle",
    ShowModes = false,
    Callback = function()
        local Data = Library.Flags["GFCMinimizeBind"]
        local Key = Data and Data.Key

        if not Key then return end

        local KeyName = (tostring(Key):gsub("Enum%.KeyCode%.", ""))

        if getgenv().ConfigurationTable.MinimizeBind ~= KeyName then
            getgenv().ConfigurationTable.MinimizeBind = KeyName
            SaveConfiguration()
        end

        Library.MenuKeybind = tostring(Key)
        if type(Library.Flags["MenuBind"]) == "table" then
            Library.Flags["MenuBind"].Key = tostring(Key)
        end
    end
})

---- ============ FPS ============ ----

local FPSSection = ConfigPage:Section({
    Name = "FPS",
    Description = "Framerate and screen",
    Icon = "110273524101447",
    Side = 2
})

FPSSection:Slider({
    Name = "FPS Value",
    Flag = "GFCFPSValue",
    Min = 1,
    Max = 240,
    Default = getgenv().ConfigurationTable.FPSValue,
    Callback = function(Value)
        getgenv().ConfigurationTable.FPSValue = Value
        SaveConfiguration()
    end
})

FPSSection:Toggle({
    Name = "FPS Lock",
    Flag = "GFCFPSLock",
    Default = getgenv().ConfigurationTable.LockFPS,
    Callback = function(Value)
        getgenv().ConfigurationTable.LockFPS = Value
        SaveConfiguration()

        if Value then
            task.spawn(function()
                pcall(function()
                    while getgenv().ConfigurationTable.LockFPS do
                        task.wait()
                        setfpscap(tonumber(getgenv().ConfigurationTable.FPSValue))
                    end
                    setfpscap(240)
                end)
            end)
        end
    end
})

---- ============ Language ============ ----

local LanguageSection = ConfigPage:Section({
    Name = "Language",
    Icon = "90816903776498",
    Side = 2
})

LanguageSection:Dropdown({
    Name = "Select Language",
    Flag = "GFCLanguage",
    Items = { "English (US)", "Thai" },
    Default = getgenv().ConfigurationTable.Language,
    Multi = false,
    Callback = function(Value)
        getgenv().ConfigurationTable.Language = Value
        SaveConfiguration()
    end
})

LanguageSection:Button({
    Name = "Change Language",
    Callback = function()
        ApplyLanguage(getgenv().ConfigurationTable.Language)
    end
})

local queueteleport = queue_on_teleport
local TeleportCheck = false

while not Players.LocalPlayer do task.wait() end

LocalPlayer.OnTeleport:Connect(function(State)
    pcall(function()
        if getgenv().ConfigurationTable and getgenv().ConfigurationTable.AutoExecutor and (not TeleportCheck) and queueteleport then
            TeleportCheck = true

            queueteleport(BuildQueueChunk())
        end
    end)
end)

Window:Init()

task.spawn(function()
    TrackConnection(Remotes.onClient(Remotes.defs.TowerContinueOffer, function(Offer)
        if not getgenv().Settings.Main.AutoDeclineContinue then return end

        if type(Offer) == "table" and Offer.open == true and Offer.paid == true then
            Remotes.fire(Remotes.defs.TowerContinueDecline)
        end
    end))
end)

---- ============ Cleanup ============ ----

getgenv().ValkyrieCleanup = function()
    getgenv().ValkyrieSession = nil

    pcall(StopNoclip)
    pcall(Picker.Incubator.Close)

    for _, Connection in ipairs(SessionConnections) do
        pcall(function()
            Connection:Disconnect()
        end)
    end

    table.clear(SessionConnections)

    pcall(function()
        Library:Unload()
    end)

    getgenv().ValkyrieCleanup = nil
end

Library:Notification({
    Title = "Script | Loader",
    Description = "Script Loaded Successfully",
    Duration = 5,
    Icon = IconValkyrie
})