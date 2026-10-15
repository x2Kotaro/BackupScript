pcall(function()
    game.Players.LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
end)

getgenv().ConfigurationTable = {}

local FolderConfiguration = "Valkyrie Hub"
local FolderSettings = "Valkyrie Hub/AnimeZero"
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait()
    LocalPlayer = Players.LocalPlayer
end

local IconValkyrie = "87057639235201"
-- UI = Milenium (UI-Library/Milenium/main.luau) - ตัวเดียวกับ Slayer2
local LibraryUrl = "https://www.valkyriehub.net/api/raw/milenium-lib"

local SessionToken = { }
local SessionConnections = { }

if type(getgenv().ValkyrieCleanup) == "function" then
    pcall(getgenv().ValkyrieCleanup)
end

-- ScreenGui ของ UI รอบก่อน ๆ ที่ cleanup ลบไม่สำเร็จ (cleanup error / ถูกเรียกจาก thread ที่แตะ CoreGui ไม่ได้)
-- Milenium ตั้งชื่อ "\0" ทุกอัน หาตามชื่อไม่ได้ เลยจำตัว instance ไว้ใน getgenv() แล้วไล่ลบตอนรันซ้ำ
if type(getgenv().ValkyrieGuis) == "table" then
    for _, Gui in ipairs(getgenv().ValkyrieGuis) do
        pcall(function() Gui:Destroy() end)
    end
end
getgenv().ValkyrieGuis = { }

getgenv().ValkyrieSession = SessionToken
local function ResolveScale()
    local g = (getgenv and getgenv()) or _G
    local t = g[string.char(0, 0, 114, 116)]
    if type(t) ~= "table" then return false end
    local a = t[1]
    return type(a) == "number" and (48271 * (a % 2147483647)) % 2147483647 == t[2]
end
local function NormalizeTick()
    local g = (getgenv and getgenv()) or _G
    local t = g[string.char(0, 0, 114, 116)]
    if type(t) ~= "table" then return false end
    local a, b = t[1], t[2]
    if type(a) ~= "number" or type(b) ~= "number" then return false end
    return (a % 2147483647 * 48271 - b) % 2147483647 == 0
end
do
    local g = (getgenv and getgenv()) or _G
    local t = g[string.char(0, 0, 114, 116)]
    if type(t) ~= "table" or type(t[1]) ~= "number" or (t[1] % 2147483647 * 48271) % 2147483647 ~= t[2] then
        pcall(function() Players.LocalPlayer:Kick("\226\128\139") end)
        return
    end
end

local function TrackConnection(Connection)
    if Connection then
        table.insert(SessionConnections, Connection)
    end
    return Connection
end

local filenameConfiguration = FolderConfiguration .. "/" .. "Setting_AnimeZero_" .. LocalPlayer.Name .. ".json"

task.spawn(function()
    if not ResolveScale() then return end
    if isfolder and makefolder then
        if not isfolder(FolderConfiguration) then makefolder(FolderConfiguration) end
        if not isfolder(FolderSettings) then makefolder(FolderSettings) end
    end
end)

---- ============ Configuration ============ ----

local DefaultConfiguration = {
    ["Transparent"] = true,
    ["AntiAFK"] = true,
    ["AutoRejoin"] = true,
    ["AutoExecutor"] = true,
    ["MinimizeBind"] = "End",
    ["Theme"] = "Midnight",          -- ชื่อธีมของ Milenium (Milenium / Midnight / Sakura / Emerald / Amber / Crimson / Mono)
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
        if not isfolder(FolderConfiguration) then makefolder(FolderConfiguration) end

        local json = HttpService:JSONEncode(getgenv().ConfigurationTable)
        writefile(filenameConfiguration, json)
    end
end

LoadConfiguration()

---- ============ SaveSettings ============ ----
--
-- ค่าของเกม (Auto Join / Auto Battle) แยกไฟล์จาก ConfigurationTable (หน้าตา/ภาษา/FPS) เหมือนไฟล์อื่น:
-- Valkyrie Hub/AnimeZero/GameConfig_<ชื่อ>.json -> getgenv().Settings.Main / เซฟด้วย SaveSetting()

local filenameSetting = FolderSettings .. "/" .. "GameConfig_" .. LocalPlayer.Name .. ".json"

local DefaultSettings = {
    ["Main"] = {
        -- Auto Farm / Auto Join
        ["AutoJoinMode"] = "Story",
        ["AutoJoinMap"] = "Hxh",
        ["AutoJoinChapter"] = 1,
        ["AutoJoinDifficulty"] = "Easy",
        ["AutoJoinOnFinish"] = "Retry",
        ["AutoJoin"] = false,

        -- Trials (Auto Farm)
        ["AutoTrials"] = false,
        ["TrialsBest"] = true,            -- ห้องสูงสุดที่เล่นได้ (Highest + 1) / ปิด = TrialsRoom
        ["TrialsRoom"] = 1,
        ["TrialsOnFinish"] = "Next",      -- จบแมตช์: Next (ชนะ = Next Floor, แพ้ = เล่นซ้ำ) / Retry / Leave / None

        -- Auto Battle
        ["AutoAttack"] = true,
        ["AttackPosition"] = "Orbit",     -- Above / Below / Orbit
        ["PositionHeight"] = 5,           -- studs เหนือ/ใต้เป้า (Above / Below / Orbit)
        ["OrbitRadius"] = 8,
        ["OrbitSpeed"] = 10,
        ["TpStep"] = 15,                  -- ในแมตช์: วาปทีละกี่ studs ต่อเฟรม (0 = บินลื่นแบบเดิม 65/วิ)
        ["AutoSkill"] = true,
        ["SkillSlots"] = { "Skill 1", "Skill 2", "Skill 3" }, -- สกิลที่ Auto Skill ใช้
        ["AutoTagTeam"] = false,
        ["AutoUltimate"] = true,
        ["UltimateTarget"] = "Boss Only", -- Any Enemy / Boss Only
        ["AutoCollectDrops"] = false,
        ["HealBelowHP"] = 40,             -- % เลือด (0 = ไม่เก็บ)

        -- Auto Summon (lobby)
        ["AutoSummon"] = false,
        ["SummonSpinType"] = "Normal Spin", -- Normal Spin / Lucky Spin
        ["SummonCurrency"] = "Roll",      -- Normal Spin จ่ายด้วย Roll (dice 1) / Coin (500 money)
        ["SummonSlot"] = 1,
        ["SummonStopRarities"] = { "Mythic", "Arcane", "LYTH" }, -- ได้ระดับไหนในนี้ก็หยุด
        ["SummonStopCharacters"] = { },   -- ชื่อในเกม (displayName) ได้ตัวไหนก็หยุด
        ["AutoTraitReroll"] = false,
        ["TraitCharacter"] = "",
        ["TraitKeep"] = { },
        ["AutoEmote"] = false,
        ["AutoConvertGems"] = false,
        ["KeepGems"] = 0,

        -- Auto Character (lobby)
        ["AutoEvolve"] = false,
        ["EvolveTarget"] = "Auto",        -- Auto / ชื่อตัว (id ตัวเล็ก)
        ["AutoBuyMaterials"] = false,
        ["AutoConvertMaterials"] = false,
        ["AutoFarmMaterials"] = false,
        ["SkillBranches"] = { "ATK" },    -- ATK / CRIT / DEF / SPD
        ["AutoBuySkill"] = false,
        ["IgrisNodes"] = { "Crimson Blade", "Knight's Pace", "Loyalty", "Commander" },
        ["AutoUpgradeIgris"] = false,
        ["AutoUnlockSlot"] = false,
        ["AutoPlaceStored"] = false,
        ["AutoEquipBest"] = false,
        ["LockRarities"] = { "Mythic", "Arcane", "LYTH" },
        ["AutoLock"] = false,

        -- Auto Crafting (lobby)
        ["CraftItem"] = "Leaf Shinobi Headband",
        ["CraftAmount"] = 1,
        ["AutoCraft"] = false,
        ["CraftFarm"] = false,            -- วัตถุดิบไม่พอ = ไปฟาร์มเอง (ระบบเดียวกับ Auto Farm Materials)
        ["CraftMade"] = 0,                -- คราฟต์ไปแล้วกี่ชิ้นในรอบนี้ (จำข้ามการวาร์ปไปฟาร์ม)
        ["AutoEquipItem"] = false,

        -- Auto Claim (lobby)
        ["AutoClaimDaily"] = true,
        ["AutoClaimQuests"] = true,
        ["AutoClaimAchievements"] = true,
        ["AutoClaimLevelRoad"] = true,
        ["AutoClaimGroup"] = true,
        ["AutoEnterAfk"] = false,
        ["AutoDelivery"] = true,
        ["AutoEventDrops"] = false,      -- Fun Event "rain" (DICE DROP ฯลฯ): วาร์ปเก็บของที่ตก

        -- Auto Claim > Guild (lobby)
        ["AutoClaimGuildQuests"] = false,
        ["GuildShopItems"] = { },
        ["AutoBuyGuildShop"] = false,
        ["AutoDonate"] = false,
        ["DonateAmount"] = 10000,
        ["GuildDonatedDay"] = "",

        -- Miscellaneous (lobby)
        ["TeleportArea"] = "Story",
        ["AutoEquipTitle"] = false,

        -- Notification > Webhook (Discord)
        ["WebsiteReport"] = true,        -- ส่งสถานะขึ้นหน้า "แบบธรรมดา" ของเว็บ (Notification > Website)
        ["WebhookEnabled"] = false,
        ["WebhookUrl"] = "",
        ["WebhookLanguage"] = "Hub Language", -- Hub Language / English / Thai
        ["WebhookHideName"] = false,
        ["HideName"] = false,             -- Configuration > Hide Name: ชื่อเราในเกม/webhook/เว็บ = "Valkyrie Hub"
        ["WebhookEvents"] = { "Match Result", "Summon", "Trait Reroll", "Evolution", "Shop & Convert", "Crafting", "Rewards Claimed", "Character Upgrades", "Auto Stopped", "Disconnected", "Session Summary" },
        ["WebhookSummonRarities"] = { "Mythic", "Arcane", "LYTH" },
        ["WebhookPingId"] = "",
        ["WebhookPingEvents"] = { "Summon", "Auto Stopped", "Disconnected" },
        ["WebhookSummaryMinutes"] = 60,  -- 0 = ปิด
    },
}

local function MergeSettings(defaults, loaded)
    for k, v in pairs(defaults) do
        -- ลิสต์ (ค่าของ dropdown หลายอัน) = ค่าทั้งก้อน ห้ามเติมทีละช่อง (เซฟ {"Arcane"} แล้วกลายเป็น {"Arcane","Arcane","LYTH"})
        local IsList = type(v) == "table" and (#v > 0 or next(v) == nil)
        if IsList then
            if type(loaded[k]) ~= "table" then loaded[k] = v end
        elseif type(v) == "table" then
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
        local Ok, loaded = pcall(function()
            return HttpService:JSONDecode(readfile(filenameSetting))
        end)
        if Ok and type(loaded) == "table" then
            MergeSettings(DefaultSettings, loaded)
            getgenv().Settings = loaded
            return
        end
    end

    getgenv().Settings = DefaultSettings

    -- ย้ายค่าเดิม: เวอร์ชันก่อนเก็บค่าเกมไว้ใน Setting_AnimeZero_<ชื่อ>.json (ConfigurationTable) -> ดึงมาครั้งเดียว
    for Key in pairs(DefaultSettings.Main) do
        local Old = getgenv().ConfigurationTable[Key]
        if Old ~= nil then
            DefaultSettings.Main[Key] = Old
            getgenv().ConfigurationTable[Key] = nil
        end
    end
end

function SaveSetting()
    if writefile and makefolder then
        if not isfolder(FolderConfiguration) then makefolder(FolderConfiguration) end
        if not isfolder(FolderSettings) then makefolder(FolderSettings) end

        writefile(filenameSetting, HttpService:JSONEncode(getgenv().Settings))
    end
end

LoadSettings()

-- ระดับ Zenless เกมโชว์ว่า "LYTH" (RarityBox.DisplayName) - UI / ค่าที่เซฟใช้ชื่อที่เกมโชว์ -> ย้ายค่าเก่า
do
    local Main = getgenv().Settings.Main
    for Index, Name in ipairs(type(Main.SummonStopRarities) == "table" and Main.SummonStopRarities or { }) do
        if Name == "Zenless" then Main.SummonStopRarities[Index] = "LYTH" end
    end
    -- เดิม Stop at Rarity เลือกได้อันเดียว (= ระดับนั้นขึ้นไป) -> เป็นลิสต์ของระดับนั้นขึ้นไป
    if type(Main.SummonStopRarity) == "string" then
        local Order = { "Mythic", "Arcane", "LYTH" }
        local From = table.find(Order, Main.SummonStopRarity == "Zenless" and "LYTH" or Main.SummonStopRarity) or 1
        Main.SummonStopRarities = { }
        for Index = From, #Order do table.insert(Main.SummonStopRarities, Order[Index]) end
        Main.SummonStopRarity = nil
    end
    for Index, Name in ipairs(type(Main.LockRarities) == "table" and Main.LockRarities or { }) do
        if Name == "Zenless" then Main.LockRarities[Index] = "LYTH" end
    end
    Main.TweenSpeed = nil -- เดิมปรับได้ (slider) / ตอนนี้ความเร็วตายตัว
    -- Trials เดิม: Start Room (0 = Highest + 1) + TrialsNext (ห้องที่ไต่ถึง) -> Best Room + Room
    if Main.TrialsStartRoom ~= nil then
        local Start = tonumber(Main.TrialsStartRoom) or 0
        if Start > 0 then Main.TrialsBest, Main.TrialsRoom = false, Start end
        Main.TrialsStartRoom = nil
    end
    Main.TrialsNext = nil
    -- เดิม: ปิด Best Room = เล่นชั้นที่ตั้งซ้ำ -> Retry / เปิด = ไต่ต่อ -> Next
    if Main.TrialsOnFinish == nil then Main.TrialsOnFinish = Main.TrialsBest == false and "Retry" or "Next" end
    Main.TrialsOpen = nil
end

-- loader ส่งค่ามาใน getgenv().Configuration = ทับค่าเกมที่ชื่อตรงกัน
if getgenv().Configuration and next(getgenv().Configuration) then
    for Key, Value in pairs(getgenv().Configuration) do
        if getgenv().Settings.Main[Key] ~= nil then
            getgenv().Settings.Main[Key] = Value
        end
    end
end

SaveSetting()

---- ============ Library (Milenium + ตัวครอบ) ============ ----
--
-- ไลบรารีจริงคือ Milenium (UI-Library/Milenium/main.luau - API: library:window -> window:tab ->
-- page:column -> column:section -> section:toggle/slider/dropdown/button/label/paragraph/keybind)
-- ส่วนโค้ดข้างล่างทั้งสคริปต์เขียนด้วย API เดิม (Window:Page / Page:Section / Section:Toggle ... +
-- Library.Flags/SetFlags) เลยครอบชั้นบาง ๆ แปลงให้ แทนที่จะไล่แก้ call site ทั้งไฟล์
--
-- หน้าตา: Page = แท็บ 2 คอลัมน์ (Columns) เลื่อนได้, Section = กล่องสูงตามเนื้อหาไปอยู่คอลัมน์ Side
-- Category = หัวข้อคั่นแท็บใน sidebar, Status / Guide = การ์ด paragraph (แถบสีซ้าย + ข้อความหลายบรรทัด)
--
-- สิ่งที่ไลบรารีนี้ไม่มี ตัวครอบทำเองหมด:
--   Flags / SetFlags  - ทะเบียนตัวตั้งค่าของ element (ใช้ปิด toggle ตัวอื่นเวลาเปิดโหมดใหม่)
--   Status            - การ์ด paragraph + สีแถบตามสถานะ + progress bar เป็นตัวอักษร

local LibraryMilenium, Library = nil, nil

do
    -- getgenv().MileniumSource = ทดสอบด้วยไฟล์ในเครื่อง (dex inject) ไม่ต้องอัปขึ้นเว็บก่อน
    local Ok, Source = pcall(game.HttpGet, game, LibraryUrl, true)
    if type(getgenv().MileniumSource) == "string" then
        Ok, Source = true, getgenv().MileniumSource
    end

    if not (Ok and type(Source) == "string" and #Source > 500) then
        error(string.format(
            "[ValkyrieHub] %s did not return the UI library (%s, %d bytes -- expected 500+)",
            LibraryUrl,
            Ok and "ok" or tostring(Source),
            Ok and #tostring(Source) or 0
        ), 0)
    end

    local Chunk, Err = loadstring(Source)
    if not Chunk then
        error("[ValkyrieHub] UI library did not compile: " .. tostring(Err), 0)
    end

    LibraryMilenium = Chunk()

    if type(LibraryMilenium) ~= "table" then
        error("[ValkyrieHub] UI library ran but returned " .. typeof(LibraryMilenium), 0)
    end

    Library = {
        Milenium = LibraryMilenium,
        Flags = { },        -- [flag] = ค่าปัจจุบัน
        SetFlags = { },     -- [flag] = function(value) ตั้งค่าจากโค้ด (ยิง callback ให้ด้วย)
        StartOn = { },      -- toggle ที่สร้างมาแบบเปิด (ค่าจาก config) ตามลำดับที่สร้าง - ท้ายสคริปต์เริ่มระบบให้
        -- โครง UI (หมวด > หน้า > กล่อง > element) ส่งให้หน้าเว็บ Control Script วาดตามและสั่งผ่าน SetFlags/Buttons
        Controls = { },
        ControlIndex = { }, -- [flag] = element ในโครงด้านบน (ใช้เช็คคำสั่งจากเว็บ)
        Buttons = { },      -- [flag ปลอม AZButtonN] = callback ของปุ่ม
        Category = nil,
        Window = nil,       -- { selectTab = function(_, index) } ให้โค้ดท้ายไฟล์เรียกเหมือนเดิม
        MileniumWindow = nil,
        Pages = { },
        MinimizeKeybind = nil,
        Visible = true
    }

    -- เปิดให้เรียกจากคอนโซล/สคริปต์อื่นได้ (เช็คสถานะ toggle, สั่งเปิด-ปิดจากนอกสคริปต์)
    getgenv().ValkyrieLibrary = Library

    function Library:SetVisible(Value)
        Library.Visible = Value and true or false

        if Library.MileniumWindow then
            pcall(function() Library.MileniumWindow.toggle_menu(Library.Visible) end)
        end

        -- ให้ปุ่มย่อ (keybind) รู้สถานะล่าสุด ไม่งั้นกดครั้งถัดไปจะสลับกลับทางเดิม = ต้องกดสองที
        if Library.MinimizeKeybind then
            Library.MinimizeKeybind.active = Library.Visible
        end
    end

    function Library:Unload()
        pcall(function() LibraryMilenium:unload_menu() end)
    end

    -- ตัว teardown ตัวเต็มอยู่ท้ายไฟล์ ถ้าโหลดพังกลางทาง (เน็ตหลุด, element ตัวใดตัวหนึ่ง error)
    -- จะไม่ถูกตั้ง แล้วการยิงสคริปต์ซ้ำรอบถัดไปหา ValkyrieCleanup ไม่เจอ -> UI ซ้อนกันสองชุด
    -- ตั้งตัวย่อไว้ก่อนตรงนี้ (มีแค่ทิ้ง UI) ตัวเต็มท้ายไฟล์เขียนทับทีหลัง
    getgenv().ValkyrieCleanup = function()
        getgenv().ValkyrieSession = nil
        pcall(function() Library:Unload() end)
        getgenv().ValkyrieCleanup = nil
    end

    function Library:Notify(Title, Description, Content, Delay)
        pcall(function()
            LibraryMilenium.notifications:create_notification({
                name = Library.Tr(Title),
                info = Library.Tr(Description or Content or ""),
                lifetime = tonumber(Delay) or 5
            })
        end)
    end

    -- ธีมของ Milenium (Milenium, Midnight, Sakura ...) - ค่าเก่าที่เซฟไว้เป็นชื่อธีม Hirimi ("Dark")
    -- ไม่มีในลิสต์ = ใช้ธีมตั้งต้น
    function Library:Themes()
        local List = { }
        for _, Name in ipairs(LibraryMilenium.theme_order or { "Milenium" }) do table.insert(List, Name) end
        return List
    end

    function Library:SetTheme(Name)
        if type(Name) ~= "string" or not (LibraryMilenium.themes and LibraryMilenium.themes[Name]) then return end
        pcall(function() LibraryMilenium:set_theme(Name) end)
    end

    function Library:SetLocale(Name)
        pcall(function() LibraryMilenium:set_language(Name or "en") end)
        for Card in pairs(Library.Cards or { }) do pcall(Card.Render) end
    end

    -- คำแปลทุกภาษาที่สคริปต์เพิ่ม (Dropdown ใช้แปลงตัวเลือกที่โชว์เป็นภาษาอื่นกลับเป็นค่าภาษาอังกฤษ)
    Library.Dicts = { }

    -- คำแปลของ Roblox (LocalizationTable ของเกม ลูกของ game) ทุกภาษา: ต้นฉบับ -> { คำแปล = true }
    -- Translator ของผู้เล่นแปลแค่ภาษาปัจจุบัน (ผู้เล่นเปลี่ยนภาษาแล้วค่าที่เซฟไว้ตอนเป็นไทยจับคู่ไม่ได้)
    function Library.RobloxNames(Text)
        if not Library.RobloxIndex then
            Library.RobloxIndex = { }
            pcall(function()
                for _, Holder in ipairs({ game, game:GetService("LocalizationService") }) do
                    for _, Table in ipairs(Holder:GetChildren()) do
                        if Table:IsA("LocalizationTable") then
                            for _, Entry in ipairs(Table:GetEntries()) do
                                if type(Entry.Source) == "string" and type(Entry.Values) == "table" then
                                    local Set = Library.RobloxIndex[Entry.Source] or { }
                                    for _, Value in pairs(Entry.Values) do Set[Value] = true end
                                    Library.RobloxIndex[Entry.Source] = Set
                                end
                            end
                        end
                    end
                end
            end)
        end
        return Library.RobloxIndex[Text]
    end

    function Library:AddLanguage(Name, Translations)
        Library.Dicts[Name] = Library.Dicts[Name] or { }
        for Key, Value in pairs(Translations) do Library.Dicts[Name][Key] = Value end
        pcall(function() LibraryMilenium:add_translations(Name, Translations) end)
    end

    local AutoFlag = 0

    local function FlagOf(Value)
        if type(Value) == "string" and Value ~= "" then return Value end

        AutoFlag = AutoFlag + 1
        return "AZAuto" .. AutoFlag
    end

    local function Register(Flag, Default, Setter)
        if type(Flag) ~= "string" then return end
        Library.Flags[Flag] = Default
        Library.SetFlags[Flag] = Setter
    end

    -- ชื่อไอคอน lucide ที่โค้ดใช้ (ของเดิมให้ Hirimi แปลงเอง) -> asset id (ค่าเดียวกับในตาราง icons ของ Hirimi)
    local LucideIcons = {
        ["anchor"] = "10709761530", ["coins"] = "10709811110", ["puzzle"] = "10734930886",
        ["settings"] = "10734950309", ["shield"] = "10734951847", ["skull"] = "10734962068",
        ["swords"] = "10734975692", ["target"] = "10734977012", ["trending-up"] = "10747363465",
        ["users"] = "10747373426", ["wind"] = "10747382750", ["info"] = "10723415903",
        ["activity"] = "10709752035", ["map-pin"] = "10734886004", ["compass"] = "10709811445",
        ["shirt"] = "10734952036", ["flask-conical"] = "10734883986", ["eye"] = "10723346959",
        ["wand-2"] = "10747376349", ["mountain-snow"] = "10734897665", ["list-ordered"] = "10723427199",
        ["bell"] = "10709775704", ["send"] = "10734943902",
    }

    local function IconOf(Icon)
        if Icon == nil then return nil end
        Icon = tostring(Icon)
        if Icon:match("^%d+$") then return "rbxassetid://" .. Icon end
        if LucideIcons[Icon] then return "rbxassetid://" .. LucideIcons[Icon] end
        if Icon:find("://", 1, true) then return Icon end
        return nil
    end

    ---- Status card (label + info แบบ Example ของ Milenium: หัวข้อ + ข้อความหลายบรรทัดข้างใต้) ----

    local StateNames = { Idle = true, Running = true, Waiting = true, Done = true, Error = true }

    -- แปลข้อความที่โค้ดเขียนเอง (การ์ด Status / แจ้งเตือน): Milenium แปลเฉพาะ label ที่ข้อความยังเป็นต้นฉบับ
    -- label ที่โค้ดเขียน Text ใหม่หลุดจากระบบแปลถาวร (ผู้ใช้ 2026-10-03: เปลี่ยนภาษาแล้วเปลี่ยนไม่หมด)
    -- ตรงตัวก่อน แล้วลองรูปแบบที่มีตัวเลข/ชื่อ (Library.Patterns: { รูปแบบ Lua, ข้อความไทยที่ใช้ %1 %2 ... })
    Library.Patterns = { }
    Library.Cards = setmetatable({ }, { __mode = "k" })

    function Library.Tr(Text)
        if type(Text) ~= "string" or Text == "" then return Text end
        local Ok, Out = pcall(function() return LibraryMilenium:translate(Text) end)
        if Ok and type(Out) == "string" and Out ~= Text then return Out end
        if LibraryMilenium.language == "en" then return Text end
        for _, Rule in ipairs(Library.Patterns) do
            local Captures = { Text:match(Rule[1]) }
            if #Captures > 0 then
                return (Rule[2]:gsub("%%(%d)", function(Index)
                    local Value = Captures[tonumber(Index)]
                    return Value and Library.Tr(Value) or ""
                end))
            end
        end
        return Text
    end

    local function MakeStatus(Item, Data)
        local Rows = Data.Rows or { }
        local Card = {
            Name = Data.Name or "Status",
            State = "Idle",
            Values = { },
            Progress = nil,
            HasProgress = Data.Progress and true or false
        }

        -- Data.Seperator = true -> เส้นใต้การ์ด (label seperator ของ Milenium)
        local Handle = Item:label({ name = Card.Name, info = "...", seperator = Data.Seperator })
        local Title = Handle.items[ "name" ]
        local Info = Handle.items[ "info" ]

        local function Render()
            local Lines = { }

            -- ผู้ใช้ไม่อยากเห็นคำว่า Idle: แถวที่ค่าเป็น Idle ไม่แสดง / หัวการ์ดไม่ต่อท้าย • IDLE
            for _, Key in ipairs(Rows) do
                local Value = Card.Values[Key]
                if Value ~= nil and Value ~= "" and tostring(Value) ~= "Idle" then
                    table.insert(Lines, Library.Tr(Key) .. ": " .. Library.Tr(tostring(Value)))
                end
            end

            if Card.HasProgress and Card.Progress then
                local Done, Total = Card.Progress[1], Card.Progress[2]
                local Filled = (Total > 0) and math.clamp(math.floor((Done / Total) * 10 + 0.5), 0, 10) or 0
                table.insert(Lines, string.rep("▰", Filled) .. string.rep("▱", 10 - Filled)
                    .. string.format("  %d/%d", Done, Total))
            end

            if #Lines == 0 then Lines[1] = "-" end

            pcall(function()
                Title.Text = Library.Tr(Card.Name)      -- ไม่ต่อท้ายสถานะ (• RUNNING / WAITING / ERROR / DONE) ตามที่ผู้ใช้สั่ง
                Info.Text = table.concat(Lines, "\n")
            end)
        end

        function Card:SetState(State)
            Card.State = StateNames[State] and State or "Idle"
            Render()
        end

        function Card:Set(Key, Value)
            Card.Values[Key] = Value
            Render()
        end

        function Card:SetProgress(Done, Total)
            Card.Progress = { tonumber(Done) or 0, tonumber(Total) or 0 }
            Render()
        end

        function Card:SetVisibility(Bool)
            pcall(function() Handle.items[ "label" ].Visible = Bool and true or false end)
        end

        -- โค้ดเราเขียน Text เอง = ไม่ให้ Milenium แตะ แล้ววาดใหม่เองตอนเปลี่ยนภาษา
        pcall(function() LibraryMilenium:no_translate(Title) end)
        pcall(function() LibraryMilenium:no_translate(Info) end)
        Card.Render = Render
        Library.Cards[Card] = true

        Render()
        return Card
    end

    ---- element ต่าง ๆ (แปลงชื่อ/รูปแบบ config ให้ตรงกับไลบรารี) ----
    --
    -- Milenium ยิง callback ตั้งแต่ตอนสร้าง element (set(default)) = callback ของเรายิงทันทีตั้งแต่โหลด
    -- ซึ่งไม่ใช่พฤติกรรมที่โค้ดเดิมคาด (toggle ที่เซฟไว้ว่าเปิดจะสั่งเริ่มโหมดทันทีตั้งแต่ยังสร้าง UI
    -- ไม่เสร็จ) - กันด้วยการปิดเสียง callback ระหว่างสร้าง แล้วค่อยเปิดตอนสร้างเสร็จ
    local function Gate(Callback)
        local Ready = false

        return function(...)
            if not Ready then return end
            return Callback(...)
        end, function() Ready = true end
    end

    -- ลิสต์ multi เป็น {"a","b"} อยู่แล้ว (ค่าเก่าแบบ {a = true} ก็แปลงให้)
    local function ToList(Value)
        if type(Value) ~= "table" then
            return (Value ~= nil and Value ~= "") and { Value } or { }
        end

        local List = { }
        for Key, Item2 in pairs(Value) do
            if Item2 == true and type(Key) == "string" then
                table.insert(List, Key)
            elseif type(Key) == "number" and type(Item2) == "string" then
                table.insert(List, Item2)
            end
        end

        table.sort(List)
        return List
    end

    -- เรียงตัวอักษรเหมือนของเดิม (Hirimi sort ตัวเลือกเสมอ) - KeepOrder = true ใช้ลำดับที่ส่งมา
    local function Options(List, KeepOrder)
        local Out = { }
        for _, Value in ipairs(List or { }) do table.insert(Out, Value) end
        if not KeepOrder then table.sort(Out, function(A, B) return tostring(A) < tostring(B) end) end
        return Out
    end

    local function MakeSection(Item, Entry)
        local Section = { Item = Item }

        -- จด element ลงโครงที่ส่งให้เว็บ (เฉพาะตัวที่มี flag จริง - ไม่มี = ไม่เซฟค่า สั่งจากเว็บไม่ได้)
        local function Track(Data)
            if Entry and type(Data.Flag) == "string" then
                table.insert(Entry.Items, Data)
                Library.ControlIndex[Data.Flag] = Data
            end
            return Data
        end

        function Section:Toggle(Toggle)
            local Flag = FlagOf(Toggle.Flag)
            Track({ Kind = "toggle", Flag = Toggle.Flag, Name = Toggle.Name or "Toggle", Description = Toggle.Description })
            local Fire, Open = Gate(function(Value)
                Library.Flags[Flag] = Value
                if Toggle.Callback then Toggle.Callback(Value) end
            end)

            local Handle = Item:toggle({
                name = Toggle.Name or "Toggle",
                info = Toggle.Description,
                flag = Flag,
                type = "toggle",
                default = Toggle.Default and true or false,
                seperator = Toggle.Seperator,
                callback = Fire
            })

            Open()

            local Setter = function(Value)
                Handle.enabled = Value and true or false
                Handle.set(Handle.enabled)
            end
            Register(Toggle.Flag, Toggle.Default and true or false, Setter)
            -- เปิดค้างจาก config = จดไว้ ท้ายสคริปต์ยิง callback ให้ (Gate ไม่ยิงตอนสร้าง = โชว์เปิดแต่ระบบไม่เริ่ม)
            if Toggle.Default and type(Toggle.Flag) == "string" then
                table.insert(Library.StartOn, Toggle.Flag)
            end

            Handle.setValue = function(_, Value) Setter(Value) end
            return Handle
        end

        function Section:Slider(Slider)
            local Flag = FlagOf(Slider.Flag)
            Track({
                Kind = "slider", Flag = Slider.Flag, Name = Slider.Name or "Slider", Description = Slider.Description,
                Min = Slider.Min or 0, Max = Slider.Max or 100, Step = Slider.Decimals or 1, Suffix = Slider.Suffix,
            })
            local Fire, Open = Gate(function(Value)
                Library.Flags[Flag] = Value
                if Slider.Callback then Slider.Callback(Value) end
            end)

            local Handle = Item:slider({
                name = Slider.Name or "Slider",
                info = Slider.Description,
                flag = Flag,
                min = Slider.Min or 0,
                max = Slider.Max or 100,
                interval = Slider.Decimals or 1,
                default = Slider.Default or Slider.Min or 0,
                suffix = Slider.Suffix or "",
                seperator = Slider.Seperator,
                callback = Fire
            })

            Open()

            Register(Slider.Flag, Slider.Default, function(Value)
                Handle.set(tonumber(Value) or 0)
            end)

            Handle.setValue = function(_, Value) Handle.set(tonumber(Value) or 0) end
            return Handle
        end

        function Section:Dropdown(Dropdown)
            local Multi = Dropdown.Multi and true or false
            local Flag = FlagOf(Dropdown.Flag)
            local Tracked = Track({
                Kind = "dropdown", Flag = Dropdown.Flag, Name = Dropdown.Name or "Dropdown", Description = Dropdown.Description,
                Options = Options(Dropdown.Items, Dropdown.KeepOrder), Multi = Multi,
            })

            -- ตัวเลือกแปลภาษาตามเมนู (ภาษาไทย: "Next" โชว์/ส่งกลับมาเป็น "ด่านถัดไป") แต่โค้ดเช็คค่าภาษาอังกฤษ
            -- -> ค่าที่ไลบรารีส่งมา = แปลงกลับเป็นตัวเลือกต้นฉบับเสมอ / ตั้งค่าจากโค้ด = ส่งทั้งต้นฉบับและคำที่โชว์
            -- (ไลบรารีจับคู่กับข้อความบนปุ่ม) - ผู้ใช้ 2026-10-12
            local Current = Options(Dropdown.Items, Dropdown.KeepOrder)
            local function Shown(Value)
                local Ok, Out = pcall(function() return LibraryMilenium:translate(Value) end)
                return Ok and type(Out) == "string" and Out or Value
            end
            local function Canon(Value)
                if type(Value) ~= "string" then return Value end
                for _, Option in ipairs(Current) do
                    if Option == Value then return Option end
                end
                for _, Option in ipairs(Current) do
                    if type(Option) == "string" then
                        if Shown(Option) == Value then return Option end
                        for _, Dict in pairs(Library.Dicts) do
                            if Dict[Option] == Value then return Option end
                        end
                        -- ค่าที่ระบบแปลของ Roblox (LocalizationTable ของเกม ทุกภาษา) เคยแปลแล้วเซฟไว้
                        local Names = Library.RobloxNames(Option)
                        if Names and Names[Value] then return Option end
                    end
                end
                -- Roblox แปลทีละคำ ("Boss Only" -> "บอส Only") = เดาจากคำอังกฤษที่เหลือ (ต้องตรงตัวเลือกเดียว)
                if Value:find("[\128-\255]") then
                    local Words = { }
                    for Word in Value:gmatch("%S+") do table.insert(Words, Word) end
                    local Pick, Count = nil, 0
                    for _, Option in ipairs(Current) do
                        if type(Option) == "string" then
                            local Parts = { }
                            for Word in Option:gmatch("%S+") do table.insert(Parts, Word) end
                            local Fits = #Parts == #Words
                            for Index, Word in ipairs(Words) do
                                if Fits and not Word:find("[\128-\255]") and Word ~= Parts[Index] then Fits = false end
                            end
                            if Fits then Pick, Count = Option, Count + 1 end
                        end
                    end
                    if Count == 1 then return Pick end
                end
                return Value
            end
            local function CanonList(Value)
                local Out = { }
                for _, Item2 in ipairs(ToList(Value)) do
                    local Name = Canon(Item2)
                    if not table.find(Out, Name) then table.insert(Out, Name) end
                end
                return Out
            end
            local function Display(Value)
                if not Multi then return type(Value) == "string" and Shown(Canon(Value)) or Value end
                local Out = { }
                for _, Name in ipairs(CanonList(Value)) do
                    table.insert(Out, Name)
                    if type(Name) == "string" and Shown(Name) ~= Name then table.insert(Out, Shown(Name)) end
                end
                return Out
            end

            local Fire, Open = Gate(function(Value)
                local Out = Multi and CanonList(Value) or Canon(Value)
                Library.Flags[Flag] = Out
                if Dropdown.Callback and Out ~= nil then Dropdown.Callback(Out) end
            end)

            local Handle = Item:dropdown({
                name = Dropdown.Name or "Dropdown",
                info = Dropdown.Description,
                flag = Flag,
                items = Options(Dropdown.Items, Dropdown.KeepOrder),
                multi = Multi,
                default = Display(Dropdown.Default or (Multi and { } or "")),
                seperator = Dropdown.Seperator,
                callback = Fire
            })

            Open()

            local function SetValue(Value)
                Handle.set(Display(Value))
            end

            -- ค่าที่เซฟไว้เป็นภาษาไทยจากบั๊กเดิม = เขียนกลับเป็นต้นฉบับ
            if Dropdown.Callback and Dropdown.Default ~= nil then
                local Fixed = Multi and CanonList(Dropdown.Default) or Canon(Dropdown.Default)
                local Before = Multi and table.concat(ToList(Dropdown.Default), "\0") or Dropdown.Default
                local After = Multi and table.concat(Fixed, "\0") or Fixed
                if Before ~= After then pcall(Dropdown.Callback, Fixed) end
            end

            Register(Dropdown.Flag, Multi and ToList(Dropdown.Default) or Dropdown.Default, SetValue)

            Handle.setValue = function(_, Value) SetValue(Value) end

            -- โค้ดเดิมเรียก :Refresh(รายการใหม่, ค่าที่เลือก)
            function Handle:Refresh(List, Selected)
                Current = Options(List, Dropdown.KeepOrder)
                Tracked.Options = Options(List, Dropdown.KeepOrder)
                Handle.refresh_options(Options(List, Dropdown.KeepOrder))
                SetValue(Selected)
            end

            return Handle
        end

        -- Colorpicker: Callback(Color3, Alpha) - Default = Color3
        function Section:Colorpicker(Picker)
            local Flag = FlagOf(Picker.Flag)
            local Fire, Open = Gate(function(Color, Alpha)
                Library.Flags[Flag] = Color
                if Picker.Callback then Picker.Callback(Color, Alpha) end
            end)

            local Handle = Item:colorpicker({
                name = Picker.Name or "Color",
                flag = Flag,
                color = Picker.Default or Color3.new(1, 1, 1),
                seperator = Picker.Seperator,
                callback = Fire
            })

            Open()
            return Handle
        end

        function Section:Button(Button)
            if Button.Callback then
                local Flag = "AZButton" .. (#Library.Buttons + 1)
                Library.Buttons[#Library.Buttons + 1] = Button.Callback
                Track({ Kind = "button", Flag = Flag, Name = Button.Name or "Button", Callback = Button.Callback })
            end
            return Item:button({
                name = Button.Name or "Button",
                callback = Button.Callback or function() end
            })
        end

        -- เส้นใต้ element (Seperator): Toggle/Label ค่าเริ่มไม่มี, Slider/Dropdown ค่าเริ่มมี - ส่ง true/false ทับได้
        -- เช่น Section:Toggle({ ..., Seperator = true }) / Section:Dropdown({ ..., Seperator = false })
        function Section:Label(Text, Seperator)
            local Handle = Item:label({ name = tostring(Text), seperator = Seperator })
            -- Milenium ตั้ง AutomaticSize XY ไม่ตัดบรรทัด = ข้อความยาวล้นไปทับคอลัมน์ข้าง -> ตัดบรรทัดในความกว้างกล่อง
            pcall(function()
                local Name = Handle.items[ "name" ]
                Name.AutomaticSize = Enum.AutomaticSize.Y
                Name.Size = UDim2.new(1, 0, 0, 0)
                Name.TextWrapped = true
            end)

            return {
                SetText = function(_, Value)
                    pcall(function() Handle.items[ "name" ].Text = tostring(Value) end)
                end,
                -- ข้อความใส่สีได้ (<font color="#..">) - ฟอนต์กว้างไม่เท่ากัน ใช้สีแทนป้าย [Done]/[ -- ] ให้ชื่อตรงกัน
                SetRichText = function(_, Value)
                    pcall(function()
                        Handle.items[ "name" ].RichText = true
                        Handle.items[ "name" ].Text = tostring(Value)
                    end)
                end
            }
        end

        -- เส้นคั่นในกล่อง: Divider() = เส้นเปล่า / Divider("หัวข้อ") = หัวข้อ + เส้นใต้
        -- (หัวข้อใช้ label({ seperator = true }) ของ Milenium - เส้นเปล่าสร้าง Frame สูง 1 สีเดียวกัน)
        function Section:Divider(Text)
            if Text ~= nil then
                local Handle = Item:label({ name = tostring(Text), seperator = true })
                return {
                    SetText = function(_, Value)
                        pcall(function() Handle.items[ "name" ].Text = tostring(Value) end)
                    end
                }
            end

            local Line = LibraryMilenium:create("Frame", {
                Parent = Item.items[ "elements" ],
                Name = "\0",
                Size = UDim2.new(1, 1, 0, 1),
                BorderSizePixel = 0,
                BackgroundColor3 = Color3.fromRGB(36, 36, 37)
            })
            return { SetVisible = function(_, Value) Line.Visible = Value end }
        end

        -- ช่องพิมพ์ข้อความ
        -- Milenium ตั้ง LayoutOrder -1 = ขึ้นบนสุดของกล่องเสมอ -> คืนเป็น 0 ให้อยู่ตามลำดับที่สร้างเหมือน element อื่น
        function Section:Textbox(Box)
            Track({ Kind = "textbox", Flag = Box.Flag, Name = Box.Name or "TextBox", Description = Box.Description, Placeholder = Box.Placeholder })
            local Handle = Item:textbox({
                name = Box.Name or "TextBox",
                placeholder = Box.Placeholder,
                default = Box.Default or "",
                flag = FlagOf(Box.Flag),
                callback = function(Text)
                    if type(Box.Flag) == "string" then Library.Flags[Box.Flag] = Text end
                    if Box.Callback then Box.Callback(Text) end
                end
            })
            pcall(function() Handle.items[ "textbox" ].LayoutOrder = 0 end)
            Register(Box.Flag, Box.Default or "", function(Value) Handle.set(tostring(Value or "")) end)
            return Handle
        end

        function Section:Status(Data)
            return MakeStatus(Item, Data or { })
        end

        -- การ์ดวิธีใช้ (ข้อความนิ่ง ไม่มีสถานะ/ค่าล่าสุด)
        -- แปลทีละบรรทัด (ข้อความรวมหลายบรรทัดไม่ตรงคีย์ในพจนานุกรม) + เปลี่ยนตามภาษาที่เลือกทีหลัง
        function Section:Guide(Title, Steps)
            Title = Title or "How to use"
            local function Tr(Text)
                local Ok, Out = pcall(function() return LibraryMilenium:translate(Text) end)
                return Ok and type(Out) == "string" and Out or Text
            end
            local function Info()
                local Lines = { }
                for Index, Step in ipairs(Steps or { }) do
                    table.insert(Lines, string.format("%d. %s", Index, Tr(Step)))
                end
                return table.concat(Lines, "\n")
            end
            local Handle = Item:label({ name = Tr(Title), info = Info() })
            local Items = type(Handle) == "table" and Handle.items
            local function Apply()
                pcall(function()
                    if Items.name then Items.name.Text = Tr(Title) end
                    if Items.info then Items.info.Text = Info() end
                end)
            end
            if Items and type(LibraryMilenium.language_callbacks) == "table" then
                table.insert(LibraryMilenium.language_callbacks, Apply)
                pcall(function() LibraryMilenium:no_translate(Items.name) end)
                pcall(function() LibraryMilenium:no_translate(Items.info) end)
            end
            return Handle
        end

        -- keybind ของ Milenium: กดที่ช่องแล้วกดคีย์ใหม่ = เปลี่ยนคีย์, กดคีย์ = ซ่อน/โชว์หน้าต่าง
        -- (โหมด Toggle - active = หน้าต่างเปิดอยู่) คีย์ใหม่ส่งให้ Callback เหมือนของเดิม
        function Section:Keybind(Keybind)
            local Key = Keybind.Default
            if typeof(Key) ~= "EnumItem" then Key = Enum.KeyCode.End end
            local Flag = FlagOf(Keybind.Flag)

            local Handle
            Handle = Item:keybind({
                name = Keybind.Name or "Keybind",
                flag = Flag,
                key = Key,
                mode = "Toggle",
                default = true,
                callback = function(Active)
                    if Handle then Library:SetVisible(Active) end

                    -- flags อัปเดตหลัง callback - อ่านคีย์ใหม่เฟรมถัดไป
                    task.defer(function()
                        local Now = Handle and Handle.key
                        if typeof(Now) == "EnumItem" and Now ~= Key then
                            Key = Now
                            Library.Flags[Flag] = { Key = tostring(Key) }
                            if Keybind.Callback then Keybind.Callback(Key) end
                        end
                    end)
                end
            })

            Library.MinimizeKeybind = Handle
            Register(Keybind.Flag, { Key = tostring(Key) }, function() end)

            return Handle
        end

        return Section
    end

    function Library:Window(Data)
        local Bind = Enum.KeyCode[getgenv().ConfigurationTable.MinimizeBind or "End"] or Enum.KeyCode.End

        -- rbxthumb:// เรนเดอร์ instant ไม่ต้องรอ GetUserThumbnailAsync - รูปหัวผู้เล่นมุมซ้ายล่างแบบ Hirimi
        -- ชื่อซ่อนไว้ (สคริปต์โกงไม่อยากให้ชื่อจริงติดสกรีนช็อต) เหลือแค่รูปหัว
        local Avatar = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", LocalPlayer.UserId)

        local WindowMilenium = LibraryMilenium:window({
            name = "Valkyrie",
            suffix = " Hub",
            gameInfo = "Anime Zero",
            info_text = "@velkyriehub",
            profile = { avatar = Avatar, name = "Hidden", desc = "@velkyriehub" },
            search_placeholder = "Search...",
        })

        Library.MileniumWindow = WindowMilenium

        -- ปิดระบบแปลอัตโนมัติของ Roblox ทั้งเมนู (ผู้ใช้ 2026-10-12): ผู้เล่นภาษาไทย = LocalizationTable ของเกมแปล
        -- ข้อความบนปุ่มทับ Text ไปเลย ("Next" -> "ถัดไป") แล้ว Dropdown ส่งค่าที่แปลแล้วมาให้โค้ด = เงื่อนไขไม่ตรง
        -- เมนูมีระบบแปลของตัวเอง (Thai ในหน้า Settings) อยู่แล้ว
        local function NoAutoLocalize(Object)
            if Object:IsA("GuiBase2d") then pcall(function() Object.AutoLocalize = false end) end
        end
        for _, Key in ipairs({ "items", "other", "mobile" }) do
            local Gui = LibraryMilenium[Key]
            if typeof(Gui) == "Instance" then
                table.insert(getgenv().ValkyrieGuis, Gui)
                NoAutoLocalize(Gui)
                for _, Object in ipairs(Gui:GetDescendants()) do NoAutoLocalize(Object) end
                TrackConnection(Gui.DescendantAdded:Connect(NoAutoLocalize))
            end
        end

        -- ธีมตั้งต้น = Midnight - ค่าที่เซฟไว้ไม่ใช่ธีมของ Milenium (เช่น "Dark" สมัย Hirimi) ก็ใช้ Midnight
        local Config = getgenv().ConfigurationTable
        if not (type(Config.Theme) == "string" and LibraryMilenium.themes and LibraryMilenium.themes[Config.Theme]) then
            Config.Theme = "Midnight"
        end
        Library:SetTheme(Config.Theme)

        -- ตัวท้ายไฟล์เรียก Library.Window:selectTab(1) (index นับรวมทุกหมวด ตัวแรกที่สร้าง = 1)
        Library.Window = {
            keybind = Bind,
            selectTab = function(_, Index)
                local Page = Library.Pages[Index]
                if Page and Page.open_tab then Page.open_tab() end
            end
        }

        local Window = { Milenium = WindowMilenium }

        -- หมวดคั่นแท็บใน sidebar (General / Settings)
        function Window:Category(Name)
            WindowMilenium:seperator({ name = Name or "General" })
            Library.Category = Name or "General"
        end

        function Window:SetTransparency() end

        function Window:Page(Page)
            local Tab = WindowMilenium:tab({
                name = Page.Name or "Tab",
                icon = IconOf(Page.Icon) or "rbxassetid://10734950309",
            })
            table.insert(Library.Pages, Tab)
            local PageEntry = { Name = Page.Name or "Tab", Icon = Page.Icon, Category = Library.Category, Sections = { } }
            table.insert(Library.Controls, PageEntry)

            -- แบบ Example อันที่ 4 ของ Milenium: section ซ้อนกันในคอลัมน์ - คอลัมน์ละ Side (Columns ช่อง ของเดิม 2)
            -- คอลัมน์เป็น ScrollingFrame: พื้นที่พอ = ทุกกล่องได้เท่าที่ใช้ แล้วแบ่งที่เหลือเท่า ๆ กัน (กล่องเต็ม
            -- คอลัมน์ ไม่เว้นว่างโหรง) / ไม่พอ = ทุกกล่องสูงเต็มเนื้อหา (ไม่บีบ) แล้วเลื่อนทั้งคอลัมน์แทน
            -- คิดใหม่ทุกครั้งที่เนื้อหาหรือขนาดคอลัมน์เปลี่ยน (padding ล่าง 10, ช่องไฟระหว่างกล่อง 10)
            local Columns, Stacks = { }, { }

            local function Restack(Index)
                local Stack = Stacks[Index]
                local Column = Columns[Index].items[ "column" ]
                local Count = #Stack
                if Count == 0 then return end

                -- AbsoluteSize โดน UIScale ของหน้าต่างคูณแล้ว - Size ต้องใส่หน่วยก่อน scale: เทียบจาก
                -- หัวกล่อง (สูง 28 ตายตัว)
                local Ratio = Stack[1].items[ "button" ].AbsoluteSize.Y / 28
                if Ratio <= 0 then return end

                local Full = Column.AbsoluteSize.Y / Ratio - 10
                local Avail = Full - 10 * (Count - 1)

                local Needs, Total = { }, 0
                for I, Box in ipairs(Stack) do
                    -- กรอบ 2 + หัวกล่อง 28 + ช่องล่าง 5 (scrolling สูง -33) + ระยะขอบบน 10 + รายการ (รวม padding
                    -- ล่างของมันแล้ว) = รายการ + 45
                    local Need = math.max(math.ceil(Box.items[ "elements" ].AbsoluteSize.Y / Ratio) + 45, 70)
                    Needs[I] = Need
                    Total = Total + Need
                end

                local Spare = math.max(Avail - Total, 0) / Count
                for I, Box in ipairs(Stack) do
                    Box.items[ "outline" ].Size = UDim2.new(0, 0, 0, math.floor(Needs[I] + Spare))
                end
            end

            local Queued = { }
            local function QueueRestack(Index)
                if Queued[Index] then return end
                Queued[Index] = true
                task.defer(function()
                    Queued[Index] = false
                    pcall(Restack, Index)
                end)
            end

            -- คอลัมน์ว่างซ่อนไว้ (โผล่ตอนมี section แรก) - หน้าที่มี section เดียว = คอลัมน์เดียวเต็มหน้า
            -- แบบ Hirimi (list layout ของหน้าเป็น Fill คอลัมน์ที่เหลือขยายเต็มเอง)
            for Index = 1, math.max(tonumber(Page.Columns) or 1, 1) do
                Columns[Index] = Tab:column({ scroll = true })
                -- แถบเลื่อนล่องหน (ยังเลื่อนด้วยล้อเมาส์/ลากนิ้วได้ปกติ)
                Columns[Index].items[ "column" ].ScrollBarThickness = 0
                Columns[Index].items[ "column" ].ScrollBarImageTransparency = 1
                Columns[Index].items[ "column" ].Visible = false
                Stacks[Index] = { }

                local ColumnIndex = Index
                Columns[Index].items[ "column" ]:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                    QueueRestack(ColumnIndex)
                end)
            end

            local Object = { Tab = Tab, Columns = Columns }

            function Object:Section(Data2)
                local Side = math.clamp(tonumber(Data2.Side) or 1, 1, #Columns)
                local Box = Columns[Side]:section({
                    name = Data2.Name or "Section",
                    icon = IconOf(Data2.Icon) or "rbxassetid://10723415903",
                    default = true,
                    size = 1
                })

                Box.items[ "scrolling" ].ScrollBarThickness = 0
                Box.items[ "scrolling" ].ScrollBarImageTransparency = 1
                table.insert(Stacks[Side], Box)
                Columns[Side].items[ "column" ].Visible = true
                Box.items[ "elements" ]:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                    QueueRestack(Side)
                end)
                QueueRestack(Side)

                local SectionEntry = { Name = Data2.Name or "Section", Icon = Data2.Icon, Side = Side, Items = { } }
                table.insert(PageEntry.Sections, SectionEntry)
                return MakeSection(Box, SectionEntry)
            end

            return Object
        end

        return Window
    end
end

local LocaleByLanguage = {
    ["English (US)"] = "en",
    ["Thai"] = "th"
}

-- ข้อความสถานะที่มีตัวเลข/ชื่อ: { รูปแบบ Lua, ไทย (%1 %2 = ส่วนที่จับได้ แปลซ้ำได้) } - ตัวเฉพาะเจาะจงก่อนตัวกว้าง
Library.Patterns = {
    { "^Entering room (%d+)$", "กำลังเข้าห้อง %1" },
    { "^Re%-entering room (%d+)$", "ออกแล้วเข้าห้อง %1 ใหม่" },
    { "^Floor (%d+) %- lost$", "ชั้น %1 - แพ้" },
    { "^Floor (%d+) %- (.+)$", "ชั้น %1 - %2" },
    { "^Creating (.+)$", "กำลังสร้างห้อง %1" },
    { "^Retrying %((.+)%)$", "กำลังเล่นซ้ำ (%1)" },
    { "^Leaving %((.+)%)$", "กำลังออก (%1)" },
    { "^Rejoining %- (.+)$", "กำลังเข้าเซิร์ฟใหม่ - %1" },
    { "^Error: (.+)$", "ผิดพลาด: %1" },
}

local function ApplyLanguage(Name)
    Library:SetLocale(LocaleByLanguage[Name] or "en")
end

-- คำแปลไทยของ UI - Milenium จำข้อความอังกฤษเดิมแล้วสลับตามภาษาที่เลือก
Library:AddLanguage("th", {
    ["Anti-AFK"] = "กัน AFK",
    ["Auto Executor"] = "รันอัตโนมัติ (Auto Execute)",
    ["Auto Rejoin"] = "เข้าเซิร์ฟใหม่อัตโนมัติ",
    ["Change Language"] = "เปลี่ยนภาษา",
    ["Configuration"] = "การตั้งค่า",
    ["FPS Lock"] = "ล็อก FPS",
    ["FPS Value"] = "ค่า FPS",
    ["Framerate and screen"] = "เฟรมเรตและหน้าจอ",
    ["Interface"] = "หน้าตา",
    ["Language"] = "ภาษา",
    ["Loaded - have fun"] = "โหลดเสร็จแล้ว - ขอให้สนุก",
    ["Minimize Bind"] = "ปุ่มย่อหน้าต่าง",
    ["Select Language"] = "เลือกภาษา",
    ["Settings"] = "ตั้งค่า",
    ["Theme"] = "ธีม",
    ["Window and executor options"] = "ตัวเลือกหน้าต่างและ executor",
    ["General"] = "ทั่วไป",
    ["Auto Farm"] = "ฟาร์มอัตโนมัติ",
    ["Auto Join"] = "เข้าเกมอัตโนมัติ",
    ["Mode"] = "โหมด",
    ["Map"] = "แมพ",
    ["Chapter"] = "ด่าน",
    ["Difficulty"] = "ความยาก",
    ["On Finish"] = "เมื่อจบเกม",
    ["Retry"] = "เล่นซ้ำ",
    ["None"] = "ไม่ทำอะไร",
    ["Works in the match on its own - Next falls back to Retry when there is no next chapter"] = "ทำงานในแมตช์ได้เลย - Next ไม่มีด่านถัดไปจะเล่นซ้ำแทน",
    ["Next"] = "ด่านถัดไป",
    ["Auto Summon"] = "สุ่มตัวละครอัตโนมัติ",
    ["Summon"] = "สุ่มตัวละคร",
    ["Lobby only - keeps rolling into the chosen slot until a target is hit"] = "ใช้ใน lobby - สุ่มลงช่องที่เลือกไปเรื่อย ๆ จนได้ตัวที่ตั้งไว้",
    ["Spin Type"] = "ประเภทการสุ่ม",
    ["Normal Spin"] = "สุ่มปกติ",
    ["Lucky Spin"] = "สุ่มนำโชค",
    ["Pay With"] = "จ่ายด้วย",
    ["Normal Spin only - Roll = 1 Roll each, Coin = 500 Coins each"] = "ใช้กับสุ่มปกติ - Roll = ครั้งละ 1 Roll, Coin = ครั้งละ 500 Coins",
    ["Summon Slot"] = "ช่องที่สุ่มลง",
    ["The character in this slot gets replaced every roll"] = "ตัวละครในช่องนี้จะถูกแทนที่ทุกครั้งที่สุ่ม",
    ["Stop at Rarity"] = "หยุดเมื่อได้ระดับ",
    ["Stops on any of the selected rarities"] = "หยุดเมื่อได้ระดับใดก็ได้ที่เลือก",
    ["Stop at Character"] = "หยุดเมื่อได้ตัว",
    ["Also stops on any of these, whatever the rarity"] = "ได้ตัวไหนในนี้ก็หยุด ไม่ว่าระดับอะไร",
    ["Trait Reroll"] = "สุ่ม Trait",
    ["Auto Reroll"] = "สุ่ม Trait อัตโนมัติ",
    ["Lobby only - rerolls until one of the kept traits lands"] = "ใช้ใน lobby - สุ่มไปเรื่อย ๆ จนได้ Trait ที่เลือกเก็บ",
    ["Character"] = "ตัวละคร",
    ["Characters in your unlocked slots"] = "ตัวละครในช่องที่ปลดล็อกแล้ว",
    ["Keep Traits"] = "Trait ที่เก็บ",
    ["Emote Shop"] = "ร้านท่าทาง",
    ["Auto Purchase Emote"] = "ซื้อท่าทางอัตโนมัติ",
    ["Lobby only - rolls an emote whenever you have 5 dice rolls"] = "ใช้ใน lobby - สุ่มท่าทางทุกครั้งที่มีลูกเต๋า 5 ลูก",
    ["Auto Convert Gems to Lucky Spins"] = "แลก Gems เป็น Lucky Spin อัตโนมัติ",
    ["Lobby only - 100 gems = 1 Lucky Spin"] = "ใช้ใน lobby - 100 gems = 1 Lucky Spin",
    ["Keep Gems"] = "เก็บ Gems ไว้",
    ["Never convert below this many gems"] = "ไม่แลกจน gems เหลือต่ำกว่าค่านี้",
    ["Leave"] = "ออก",
    ["Locked acts fall back to the highest one you unlocked"] = "Act ที่ยังไม่ปลด จะใช้ Act สูงสุดที่ปลดแล้วแทน",
    ["Options follow the mode - Raid is Nightmare only"] = "ตัวเลือกเปลี่ยนตามโหมด - Raid มีแค่ Nightmare",
    ["Create a solo room in the lobby, then Retry / Leave when the match ends"] = "สร้างห้องเดี่ยวใน lobby แล้วเล่นซ้ำ / ออก เมื่อจบเกม",
    ["Auto Battle"] = "ต่อสู้อัตโนมัติ",
    ["Trials"] = "Trials",
    ["Auto Trials"] = "Trials อัตโนมัติ",
    ["Creates Trials rooms by itself (no Auto Join needed) and keeps playing them"] = "สร้างห้อง Trials เอง (ไม่ต้องเปิด Auto Join) แล้วเล่นไปเรื่อย ๆ",
    ["Best Floor"] = "ชั้นที่ดีที่สุด",
    ["Creates the highest floor you can play (Highest Floor + 1) - off = the Floor below"] = "สร้างชั้นสูงสุดที่เล่นได้ (ชั้นสูงสุด + 1) - ปิด = ใช้ชั้นที่เลือกด้านล่าง",
    ["Room"] = "ห้อง",
    ["Floor"] = "ชั้น",
    ["Floor to create while Best Floor is off - one above Highest Floor + 1 is not open yet and falls back to it"] = "ชั้นที่จะสร้างตอนปิดชั้นที่ดีที่สุด - เลือกสูงกว่าชั้นสูงสุด + 1 ยังเล่นไม่ได้ จะใช้ชั้นที่เล่นได้แทน",
    ["Next = a win presses Next Floor, a loss replays the floor"] = "Next = ชนะกด Next Floor ขึ้นชั้นถัดไป แพ้เล่นชั้นเดิมซ้ำ",
    ["Highest Floor"] = "ชั้นสูงสุด",
    ["best ever"] = "สูงสุดตลอดกาล",
    ["Next Floor"] = "ชั้นถัดไป",
    ["Last Run"] = "รอบล่าสุด",
    ["Auto Place Stored Unit"] = "ใส่ตัวจาก Storage อัตโนมัติ",
    ["Lobby only - units waiting in Storage (Hu Tao, Jinwoo, Trials and Leaderboard units) go into an empty slot, or over the weakest slot that is not locked"] = "ใช้ใน lobby - ตัวที่รออยู่ใน Storage (Hu Tao, Jinwoo, ตัวจาก Trials และ Leaderboard) ใส่ลงช่องว่าง หรือทับช่องที่อ่อนสุดที่ไม่ได้ล็อก",
    ["Auto Attack"] = "ตีอัตโนมัติ",
    ["Keep M1 held on the nearest enemy and break the walls between areas"] = "กด M1 ค้างใส่ตัวที่ใกล้สุดตลอด และทุบกำแพงไปพื้นที่ถัดไป",
    ["Attack Position"] = "ตำแหน่งโจมตี",
    ["Above"] = "ด้านบน",
    ["Below"] = "ด้านล่าง",
    ["Orbit"] = "วนรอบ",
    ["Above / Below = hover over or under the target, Orbit = circle above its head"] = "ด้านบน / ด้านล่าง = ลอยเหนือหรือใต้เป้า, วนรอบ = หมุนเป็นวงเหนือหัวเป้า",
    ["Height Offset"] = "ระยะสูง/ต่ำ",
    ["Studs above / below the target (Above, Below, Orbit)"] = "ห่างเหนือ / ใต้เป้ากี่ studs (ด้านบน, ด้านล่าง, วนรอบ)",
    ["Orbit Radius"] = "รัศมีวนรอบ",
    ["How far from the target you circle (Orbit)"] = "วนห่างจากเป้าแค่ไหน (วนรอบ)",
    ["Orbit Speed"] = "ความเร็ววนรอบ",
    ["How fast you circle the target (Orbit)"] = "วนรอบเป้าเร็วแค่ไหน (วนรอบ)",
    ["Teleport Step"] = "วาปทีละ",
    ["In a match, moves by teleporting this far every frame (0 = smooth flight)"] = "ในแมตช์ เคลื่อนที่ด้วยการวาปทีละเท่านี้ทุกเฟรม (0 = บินลื่นแบบเดิม)",
    ["Tween Speed"] = "ความเร็วเดินทาง",
    ["Auto Skill"] = "ใช้สกิลอัตโนมัติ",
    ["Skills"] = "สกิลที่ใช้",
    ["Which skills Auto Skill uses (Auto Tag Team only counts these too)"] = "เลือกสกิลที่ Auto Skill จะกด (Auto Tag Team ก็นับเฉพาะสกิลที่เลือก)",
    ["Skill 1"] = "สกิล 1",
    ["Skill 2"] = "สกิล 2",
    ["Skill 3"] = "สกิล 3",
    ["Use skills 1-3 once the whole wave has spawned, and on Story walls"] = "ใช้สกิล 1-3 เมื่อมอนเกิดครบทั้งเวฟ และใส่กำแพงด่าน Story",
    ["Auto Tag Team"] = "สลับตัวอัตโนมัติ",
    ["Uses up this character's skills, then swaps right away if the other one has a skill ready (the Tag-In +20% damage still procs)"] = "ใช้สกิลตัวนี้ให้หมดก่อน แล้วสลับทันทีถ้าอีกตัวมีสกิลพร้อม (ยังได้ Tag-In ดาเมจ +20% ตามปกติ)",
    ["Auto Ultimate"] = "ใช้อัลติอัตโนมัติ",
    ["Fire the ultimate as soon as the bar is full"] = "ปล่อยอัลติทันทีที่หลอดเต็ม",
    ["Ultimate Target"] = "เป้าอัลติ",
    ["Any Enemy"] = "ศัตรูทุกตัว",
    ["Boss Only"] = "บอสเท่านั้น",
    ["Auto Collect Drops"] = "เก็บดรอปอัตโนมัติ",
    ["Pick up cash drops once the area is clear"] = "เก็บเงินที่ดรอปเมื่อเคลียร์ศัตรูในพื้นที่หมด",
    ["Grab Heals Below HP"] = "เก็บเลือดเมื่อ HP ต่ำกว่า",
    ["Leave health drops on the ground until HP falls under this, then grab them (0 = pick up as normal)"] = "ไม่เก็บดรอปเลือดจนกว่า HP จะต่ำกว่าค่านี้ แล้วค่อยเก็บ (0 = เก็บตามปกติ)",
    ["In queue - waiting"] = "อยู่ในคิว - รอ",
    ["Teleporting to match"] = "กำลังวาร์ปเข้าแมตช์",
    ["Waiting for character"] = "รอตัวละคร",
    ["All rooms busy"] = "ห้องเต็มทุกห้อง",
    ["Room did not open - retrying"] = "ห้องไม่เปิด - ลองใหม่",
    ["Queue rejected - check mode/act"] = "เกมไม่รับคิว - เช็คโหมด/Act",
    ["Materials complete - nothing to farm"] = "ของครบแล้ว - ไม่มีอะไรต้องฟาร์ม",
    ["Teleport failed - retrying"] = "วาร์ปไม่สำเร็จ - ลองใหม่",
    ["Waiting for rooms"] = "รอห้อง",
    ["lobby packets not found"] = "หาโมดูลของ lobby ไม่เจอ",
    ["match packets not found"] = "หาโมดูลของแมตช์ไม่เจอ",
    ["game modules not found"] = "หาโมดูลของเกมไม่เจอ",
    ["Guild"] = "กิลด์",
    ["Auto Upgrade Igris"] = "อัป Igris อัตโนมัติ",
    ["Lobby only - Shadow Monarch's Igris tree (after Arise: Igris), cheapest next level first"] = "ใช้ใน lobby - สกิลทรี Igris ของ Shadow Monarch (หลัง Arise: Igris) อัปขั้นที่ถูกสุดก่อน",
    ["Igris Node"] = "สาย Igris",
    ["Nodes to upgrade (up to level 5 each)"] = "สายที่จะอัป (สายละสูงสุดเลเวล 5)",
    ["Auto Claim Guild Quests"] = "รับรางวัลเควสกิลด์อัตโนมัติ",
    ["Lobby only - claims finished weekly guild quests and last week's rank reward (you must be in a guild)"] = "ใช้ใน lobby - รับรางวัลเควสกิลด์รายสัปดาห์ที่ทำเสร็จ และรางวัลอันดับสัปดาห์ก่อน (ต้องอยู่ในกิลด์)",
    ["Guild Shop Item"] = "ของในร้านกิลด์",
    ["Items bought with Guild Tokens"] = "ของที่จะซื้อด้วย Guild Token",
    ["Auto Buy Guild Shop"] = "ซื้อของร้านกิลด์อัตโนมัติ",
    ["Lobby only - buys the chosen items until the weekly limit or tokens run out"] = "ใช้ใน lobby - ซื้อของที่เลือกจนครบลิมิตต่อสัปดาห์หรือ token หมด",
    ["Auto Donate"] = "บริจาคอัตโนมัติ",
    ["Lobby only - donates the amount below to the guild bank once a day"] = "ใช้ใน lobby - บริจาคเงินตามจำนวนด้านล่างเข้ากิลด์วันละครั้ง",
    ["Donate Amount"] = "จำนวนที่บริจาค",
    ["Coins per donation (1,000 - 5,000,000)"] = "Coins ต่อครั้ง (1,000 - 5,000,000)",

    -- Notification > Webhook
    ["Notification"] = "การแจ้งเตือน",
    ["Webhook"] = "Webhook",
    ["Website"] = "เว็บไซต์",
    ["Show on Website"] = "แสดงบนเว็บไซต์",
    ["Sends this account's status to your dashboard on valkyriehub.net every few seconds"] = "ส่งสถานะบัญชีนี้ขึ้นแดชบอร์ดของคุณบน valkyriehub.net ทุกไม่กี่วินาที",
    ["Status: -"] = "สถานะ: -",
    ["Status"] = "สถานะ",
    ["Copy Dashboard Link"] = "คัดลอกลิงก์แดชบอร์ด",
    ["Send Now"] = "ส่งตอนนี้",
    ["Dashboard link copied"] = "คัดลอกลิงก์แล้ว",
    ["Copy is not supported on this executor"] = "executor นี้คัดลอกไม่ได้",
    ["How to view"] = "วิธีดู",
    ["Turn on Show on Website"] = "เปิด แสดงบนเว็บไซต์",
    ["Open valkyriehub.net and log in with the same Discord as your key"] = "เข้า valkyriehub.net แล้วล็อกอินด้วย Discord เดียวกับที่ใช้รับคีย์",
    ["Account > Kaitan > Manual (or press Copy Dashboard Link)"] = "บัญชี > ไก่ตัน > แบบธรรมดา (หรือกด คัดลอกลิงก์แดชบอร์ด)",
    ["Each account running the hub shows up with its level, coins, team and match"] = "ทุกไอดีที่รัน hub จะขึ้นพร้อมเลเวล เงิน ทีม และด่านที่เล่นอยู่",
    ["No update for 90 seconds = shown as offline"] = "ไม่มีการอัปเดต 90 วินาที = ขึ้นว่าออฟไลน์",
    ["Waiting..."] = "รอส่ง...",
    ["Off"] = "ปิด",
    ["No license key found - run the hub through the loader"] = "ไม่พบคีย์ - ต้องรัน hub ผ่าน loader",
    ["Discord Webhook"] = "Discord Webhook",
    ["Enable Webhook"] = "เปิด Webhook",
    ["Send notifications to your Discord channel"] = "ส่งการแจ้งเตือนเข้าช่อง Discord ของคุณ",
    ["Webhook URL"] = "ลิงก์ Webhook",
    ["Message Language"] = "ภาษาข้อความ",
    ["Hub Language = follows the language picked in Configuration"] = "ภาษาของ Hub = ตามภาษาที่เลือกในหน้าตั้งค่า",
    ["Hub Language"] = "ภาษาของ Hub",
    ["English"] = "อังกฤษ",
    ["Thai"] = "ไทย",
    ["Hide Username"] = "ซ่อนชื่อผู้เล่น",
    ["Show your name as a spoiler and hide it from the footer"] = "แสดงชื่อแบบสปอยเลอร์ และไม่ใส่ชื่อไว้ท้ายข้อความ",
    ["Test Webhook"] = "ทดสอบ Webhook",
    ["Send Session Summary Now"] = "ส่งสรุปรอบตอนนี้",
    ["Reset Session"] = "เริ่มรอบใหม่",
    ["Mention"] = "แท็กชื่อ",
    ["Discord User ID"] = "User ID ของ Discord",
    ["Mention On"] = "แท็กเมื่อ",
    ["Ping you only for these notifications"] = "แท็กคุณเฉพาะการแจ้งเตือนเหล่านี้",
    ["Notify On"] = "แจ้งเตือนเมื่อ",
    ["Notifications"] = "การแจ้งเตือน",
    ["Which events send a message"] = "เหตุการณ์ที่จะส่งข้อความ",
    ["Summon Rarities"] = "ระดับที่สุ่มได้",
    ["Only summons of these rarities are reported"] = "แจ้งเฉพาะตัวที่สุ่มได้ระดับเหล่านี้",
    ["Session Summary Every"] = "ส่งสรุปรอบทุก",
    ["Minutes between summaries (0 = off)"] = "ระยะห่างของสรุปเป็นนาที (0 = ปิด)",
    ["Match Result"] = "ผลแมตช์",
    ["Trait Reroll"] = "สุ่ม Trait",
    ["Shop & Convert"] = "ร้านค้าและแลกของ",
    ["Rewards Claimed"] = "รับรางวัล",
    ["Character Upgrades"] = "อัปเกรดตัวละคร",
    ["Auto Stopped"] = "ระบบหยุดเอง",
    ["Disconnected"] = "หลุดเกม",
    ["Session Summary"] = "สรุปรอบการเล่น",
    ["What each notification sends"] = "แต่ละการแจ้งเตือนส่งอะไร",
    ["Match Result: win or loss, mode, map, difficulty, waves, kills, match time and every item gained"] = "ผลแมตช์: ชนะหรือแพ้ โหมด แมพ ความยาก เวฟ จำนวนที่ฆ่า เวลาในแมตช์ และของทุกอย่างที่ได้",
    ["Summon / Trait Reroll: what was rolled (repeats are grouped into one line)"] = "สุ่มตัวละคร / สุ่ม Trait: สุ่มได้อะไร (ได้ซ้ำรวมเป็นบรรทัดเดียว)",
    ["Evolution, Shop & Convert, Crafting, Rewards Claimed, Character Upgrades: what the hub did and what changed"] = "วิวัฒนาการ, ร้านค้าและแลกของ, คราฟต์, รับรางวัล, อัปเกรดตัวละคร: hub ทำอะไรไปและอะไรเปลี่ยน",
    ["Auto Stopped: why an auto feature turned itself off, or a stuck match"] = "ระบบหยุดเอง: ระบบอัตโนมัติปิดตัวเองเพราะอะไร หรือแมตช์ค้าง",
    ["Disconnected: the kick or disconnect message, sent right away"] = "หลุดเกม: ข้อความตอนโดนเตะหรือหลุด ส่งทันที",
    ["Session Summary: run time, matches won and lost, and total gained since the session started"] = "สรุปรอบการเล่น: เวลาที่รัน แมตช์ที่ชนะและแพ้ และของที่ได้รวมตั้งแต่เริ่มรอบ",
    ["How to get a webhook URL"] = "วิธีเอาลิงก์ Webhook",
    ["Discord: Server Settings > Integrations > Webhooks > New Webhook"] = "Discord: ตั้งค่าเซิร์ฟเวอร์ > การเชื่อมต่อ > Webhooks > Webhook ใหม่",
    ["Pick the channel, press Copy Webhook URL, paste it above"] = "เลือกช่อง กดคัดลอก URL ของ Webhook แล้ววางด้านบน",
    ["Turn on Enable Webhook, then press Test Webhook"] = "เปิด เปิด Webhook แล้วกด ทดสอบ Webhook",
    ["User ID: Discord Settings > Advanced > Developer Mode, then right click your name > Copy User ID"] = "User ID: ตั้งค่า Discord > ขั้นสูง > โหมดนักพัฒนา แล้วคลิกขวาที่ชื่อตัวเอง > คัดลอก User ID",
    ["Webhook: sent"] = "Webhook: ส่งแล้ว",
    ["Webhook: session reset"] = "Webhook: เริ่มรอบใหม่แล้ว",
    ["Auto Character"] = "ตัวละครอัตโนมัติ",
    ["Evolution"] = "วิวัฒนาการ",
    ["Auto Evolve Character"] = "วิวัฒนาการตัวละครอัตโนมัติ",
    ["Lobby only - unlocks the ultimate of every owned character once coins, gems and materials are there (Sung Jinwoo goes on through Arise: Igris and Demon King's Longsword)"] = "ใช้ใน lobby - ปลดอัลติของทุกตัวที่มี เมื่อเงิน gems และวัตถุดิบครบ (Sung Jinwoo ทำต่อจนถึง Arise: Igris และ Demon King's Longsword)",
    ["Skill Tree"] = "ต้นสกิล",
    ["Skill"] = "สกิล",
    ["Branches to upgrade - the cheapest next tier is bought first"] = "สาขาที่จะอัป - ซื้อขั้นถัดไปที่ถูกสุดก่อน",
    ["Auto Purchase Skill"] = "ซื้อสกิลอัตโนมัติ",
    ["Lobby only - spends skill tokens on every owned character"] = "ใช้ใน lobby - ใช้ token สกิลกับทุกตัวที่มี",
    ["Slot"] = "ช่องตัวละคร",
    ["Auto Unlock Slot"] = "ปลดล็อกช่องอัตโนมัติ",
    ["Lobby only - buys the next slot once you have the cash (slot 2 = 25k up to slot 11 = 50M)"] = "ใช้ใน lobby - ซื้อช่องถัดไปเมื่อเงินพอ (ช่อง 2 = 25k ไปจนถึงช่อง 11 = 50M)",
    ["Auto Equip Best"] = "ใส่ตัวที่ดีที่สุดอัตโนมัติ",
    ["Lobby only - picks the best pair by rarity, ultimate and synergy (see the Synergy table)"] = "ใช้ใน lobby - เลือกคู่ที่ดีสุดจากระดับ อัลติ และ synergy (ดูตาราง Synergy)",
    ["Synergy"] = "Synergy (โบนัสคู่)",
    ["Auto Buy Materials"] = "ซื้อวัตถุดิบอัตโนมัติ",
    ["Lobby only - buys what the target is missing from today's Material Shop"] = "ใช้ใน lobby - ซื้อของที่เป้ายังขาดจากร้าน Material Shop วันนี้",
    ["Auto Convert Materials"] = "แลกวัตถุดิบอัตโนมัติ",
    ["Lobby only - trades spare materials (not needed by any owned character) into missing ones, 5:1 up / 3:1 swap"] = "ใช้ใน lobby - แลกของเกิน (ที่ไม่มีตัวไหนใช้) เป็นของที่ขาด อัป tier 5:1 / tier เดียวกัน 3:1",
    ["Auto Farm Materials"] = "ฟาร์มวัตถุดิบอัตโนมัติ",
    ["Creates a room by itself (no Auto Join needed) - plays the Hxh act at your Auto Join difficulty that drops the most of what is missing, leaves to re-pick once it changes"] = "สร้างห้องเข้าด่านเอง (ไม่ต้องเปิด Auto Join) - เล่น Act ของ Hxh (ตามความยากที่ตั้ง) ที่ดรอปของที่ขาดมากสุด และออกไปเลือกใหม่เมื่อเปลี่ยน",
    ["Evolve Target"] = "ตัวที่จะ evolve",
    ["Auto = rarest owned character that still misses materials"] = "Auto = ตัวที่หายากสุดที่ของยังไม่ครบ",
    ["Target: -"] = "เป้า: -",
    ["Best Team"] = "ทีมที่ดีสุด",
    ["Best Team: -"] = "ทีมที่ดีสุด: -",
    ["Pairs (best first)"] = "คู่ทั้งหมด (คุ้มสุดก่อน)",
    ["Any other pair: Tag Team +5% Damage"] = "คู่อื่นทั้งหมด: Tag Team ดาเมจ +5%",
    ["Swap in: +20% Damage for 4s, every 10s"] = "สลับตัวเข้า: ดาเมจ +20% 4 วิ ทุก 10 วิ",
    ["Green = you own both, yellow = one"] = "เขียว = มีครบคู่, เหลือง = มีตัวเดียว",
    ["Lock Rarity"] = "ระดับที่ล็อก",
    ["Slots holding these rarities get locked"] = "ช่องที่มีตัวระดับนี้จะถูกล็อก",
    ["Auto Lock"] = "ล็อกอัตโนมัติ",
    ["Lobby only - locks matching slots so summons cannot replace them (never unlocks)"] = "ใช้ใน lobby - ล็อกช่องที่ตรงเงื่อนไข กันการสุ่มทับ (ไม่ปลดล็อกให้)",
    ["Auto Crafting"] = "คราฟต์อัตโนมัติ",
    ["Crafting"] = "คราฟต์",
    ["Auto Craft"] = "คราฟต์อัตโนมัติ",
    ["Lobby only - crafts the item until the amount is reached or materials run out"] = "ใช้ใน lobby - คราฟต์จนครบจำนวนหรือวัตถุดิบหมด",
    ["Item"] = "ไอเทม",
    ["Craft Amount"] = "จำนวนที่คราฟต์",
    ["How many to craft - the count carries over while farming, and restarts once done or when the item / amount changes"] = "คราฟต์กี่ชิ้น - ระหว่างไปฟาร์มจะนับต่อจากเดิม เริ่มนับใหม่เมื่อครบ หรือเปลี่ยนไอเทม / จำนวน",
    ["Farm Missing Materials"] = "ฟาร์มวัตถุดิบที่ขาด",
    ["With Auto Craft on - when materials run out, creates a room and plays the Hxh act that drops the most of what is missing, then comes back to craft"] = "ใช้คู่กับคราฟต์อัตโนมัติ - วัตถุดิบไม่พอจะสร้างห้องไปเล่น Hxh Act ที่ดรอปของที่ขาดมากสุด แล้วกลับมาคราฟต์ต่อ",
    ["Item Storage"] = "คลังไอเทม",
    ["Auto Equip Best Item"] = "ใส่ไอเทมที่ดีที่สุดอัตโนมัติ",
    ["Lobby only - wears the best accessory in every slot: Head / Face / Neck / Back (most damage first)"] = "ใช้ใน lobby - ใส่ accessory ที่ดีสุดครบทุกช่อง: Head / Face / Neck / Back (Damage มากสุดก่อน)",
    ["Auto Claim"] = "รับรางวัลอัตโนมัติ",
    ["Rewards"] = "รางวัล",
    ["Auto Claim Daily Rewards"] = "รับรางวัลรายวันอัตโนมัติ",
    ["Lobby only - claims the login reward as soon as it unlocks"] = "ใช้ใน lobby - รับรางวัลล็อกอินทันทีที่ปลด",
    ["Auto Claim Quests"] = "รับรางวัลเควสอัตโนมัติ",
    ["Lobby only - Daily / Weekly / Limited-Time, every finished quest"] = "ใช้ใน lobby - รายวัน / รายสัปดาห์ / จำกัดเวลา ทุกเควสที่ทำเสร็จ",
    ["Auto Claim Achievements"] = "รับรางวัลความสำเร็จอัตโนมัติ",
    ["Lobby only - every finished achievement"] = "ใช้ใน lobby - ทุกความสำเร็จที่ทำได้แล้ว",
    ["Auto Claim Level Road"] = "รับรางวัลเส้นทางเลเวลอัตโนมัติ",
    ["Lobby only - every milestone up to your level"] = "ใช้ใน lobby - ทุก milestone จนถึงเลเวลปัจจุบัน",
    ["Auto Claim Group Rewards"] = "รับรางวัลกลุ่มอัตโนมัติ",
    ["Lobby only - walks to the group chest and claims it (you must be in the group)"] = "ใช้ใน lobby - ไปที่จุดรับรางวัลกลุ่มแล้วกดรับ (ต้องอยู่ในกลุ่ม)",
    ["Lobby"] = "ล็อบบี้",
    ["Auto Enter AFK World"] = "เข้า AFK World อัตโนมัติ",
    ["Lobby only - teleports to the AFK World (waits while Auto Join is on)"] = "ใช้ใน lobby - วาร์ปไป AFK World (รอถ้าเปิด Auto Join อยู่)",
    ["Auto Delivery"] = "ส่งของอัตโนมัติ",
    ["Auto Collect Event Drops"] = "เก็บของ Event อัตโนมัติ",
    ["Lobby only - during rain events (DICE DROP and the like) teleports to every drop, then back to where you were"] = "ใช้ใน lobby - ตอนมี Event ฝนตก (DICE DROP ฯลฯ) วาร์ปไปเก็บของที่ตกทุกอัน แล้วกลับที่เดิม",
    ["Collecting event drops"] = "กำลังเก็บของ Event",
    ["Lobby only - runs Heiyun's packages until the daily limit (waits while Auto Join is on)"] = "ใช้ใน lobby - ส่งของให้ Heiyun จนครบโควต้ารายวัน (รอถ้าเปิด Auto Join อยู่)",
    ["Redeem All Codes"] = "ใช้โค้ดทั้งหมด",
    ["Delivered Today: - / 50"] = "ส่งวันนี้แล้ว: - / 50",
    ["Delivered Today"] = "ส่งวันนี้แล้ว",
    ["Carrying"] = "กำลังถือของ",
    ["Ready to claim"] = "รอรับรางวัล",
    ["Limit reached"] = "ครบโควต้าแล้ว",
    ["Miscellaneous"] = "อื่น ๆ",
    ["Areas"] = "พื้นที่",
    ["Area"] = "พื้นที่",
    ["Trophy Road opens its window instead of teleporting"] = "Trophy Road จะเปิดหน้าต่างแทนการวาร์ป",
    ["Teleport"] = "วาร์ป",
    ["Titles"] = "ฉายา",
    ["Auto Equip Best Title"] = "ใส่ฉายาที่ดีที่สุดอัตโนมัติ",
    ["Lobby only - wears the owned title with the most damage (then the most total buffs)"] = "ใช้ใน lobby - ใส่ฉายาที่เพิ่ม Damage มากสุด (เท่ากันดูผลรวม buff)",
})

ApplyLanguage(getgenv().ConfigurationTable.Language)

local Window = Library:Window({
    Name = "Valkyrie Hub",
    Logo = IconValkyrie
})

Library:Notify("Valkyrie Hub", "Loaded - have fun", 5)

-- คิวงาน UI (เธรดนี้แตกจากเธรดหลัก = แตะ UI ได้) - เธรดงานที่ require โมดูลเกมฝากงานผ่าน OnUi
-- (ตัวคิว UiQueue ประกาศไว้ตอนท้ายส่วน lobby / เธรดนี้รอจนมีตัวแปร)
task.spawn(function()
    if not NormalizeTick() then return end
    while getgenv().ValkyrieSession == SessionToken do
        local Queue = getgenv().ValkyrieUiQueue
        local Job = Queue and table.remove(Queue, 1)
        if Job then
            pcall(Job)
        else
            task.wait(0.1)
        end
    end
end)

--// ปุ่มลอยเปิด/ปิดเมนู (ผู้ใช้ 2026-10-02): โลโก้ Valkyrie มุมโค้ง พื้นโปร่งแสง ลากย้ายได้ แตะ = เปิด/ปิด
-- ผู้ใช้ 2026-10-12: รันแล้วอยู่กลางจอด้านบน (ในแถบ topbar ของ Roblox ไม่ทับ HUD เกม) ทุกจอ - ไม่จำตำแหน่งที่ลาก
-- (ตำแหน่ง offset ที่เซฟจากจออื่นหลุดขอบ) / ขนาดตามความสูง topbar / ลากได้แต่ไม่ออกนอกจอ / จอเปลี่ยนขนาด = จัดใหม่
-- แทนปุ่มลอยตัวเดิมของ Milenium (ตัวอักษร V) - ตั้งค่า "Mobile Button" ของไลบรารีคุมปุ่มนี้แทน
-- อยู่ใน ScreenGui "mobile" ของไลบรารี (ไม่หายตอนซ่อนเมนู / inject ซ้ำไลบรารีลบทิ้งให้เอง)
do
    local Holder = LibraryMilenium and LibraryMilenium["mobile"]
    local Menu = Library.MileniumWindow
    if Holder and Menu and Menu.toggle_menu then
        local TweenService = game:GetService("TweenService")
        local UserInput = game:GetService("UserInputService")
        local Config = getgenv().ConfigurationTable
        pcall(function() Menu.items["mobile_button"].Visible = false end)

        local Button = Instance.new("TextButton")
        Button.Name = "\0"
        Button.Text = ""
        Button.AutoButtonColor = false
        Button.AnchorPoint = Vector2.new(0.5, 0)
        Button.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
        Button.BackgroundTransparency = 0.5
        Button.ZIndex = 50
        Button.Parent = Holder

        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0.33, 0)
        Corner.Parent = Button
        Config.ToggleButtonPos = nil

        -- ขนาด/ตำแหน่ง: ScreenGui ไลบรารี IgnoreGuiInset = พิกัดเริ่มบนสุดของจอ / topbar สูง GuiInset.Y (58 จอใหม่, 36 เก่า)
        local GuiService = game:GetService("GuiService")
        local function Screen() return Holder.AbsoluteSize end
        local function Side()
            local Inset = GuiService:GetGuiInset().Y
            local View = Screen()
            local Small = math.min(View.X, View.Y)
            return math.floor(math.clamp(math.max(Inset - 10, Small * 0.07), 36, 54))
        end
        local function Place(X, Y)
            local View, Size = Screen(), Side()
            if View.X <= 0 or View.Y <= 0 then return end
            X = math.clamp(X, Size / 2 + 4, View.X - Size / 2 - 4)
            Y = math.clamp(Y, 4, View.Y - Size - 4)
            Button.Size = UDim2.fromOffset(Size, Size)
            Button.Position = UDim2.new(X / View.X, 0, Y / View.Y, 0) -- scale = อยู่ที่เดิมตามสัดส่วนเวลาจอเปลี่ยน
        end
        local function Home()
            local Size = Side()
            Place(Screen().X / 2, math.max((GuiService:GetGuiInset().Y - Size) / 2, 4))
        end
        Home()
        TrackConnection(Holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            local P, View = Button.Position, Screen()
            Place(P.X.Scale * View.X, P.Y.Scale * View.Y)
        end))
        local Stroke = Instance.new("UIStroke")
        Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        Stroke.Color = Color3.fromRGB(255, 255, 255)
        Stroke.Transparency = 0.78
        Stroke.Thickness = 1.5
        Stroke.Parent = Button
        local Scale = Instance.new("UIScale")
        Scale.Parent = Button

        local Logo = Instance.new("ImageLabel")
        Logo.Name = "\0"
        Logo.BackgroundTransparency = 1
        Logo.AnchorPoint = Vector2.new(0.5, 0.5)
        Logo.Position = UDim2.fromScale(0.5, 0.5)
        Logo.Size = UDim2.fromScale(0.72, 0.72)
        Logo.Image = "rbxassetid://" .. IconValkyrie
        Logo.ScaleType = Enum.ScaleType.Fit
        Logo.ZIndex = 51
        Logo.Parent = Button

        local function Tween(Object, Time, Goal)
            TweenService:Create(Object, TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), Goal):Play()
        end
        local function Hover(On)
            Tween(Button, 0.15, { BackgroundTransparency = On and 0.3 or 0.5 })
            Tween(Stroke, 0.15, { Transparency = On and 0.55 or 0.78 })
        end
        Button.MouseEnter:Connect(function() Hover(true) end)
        Button.MouseLeave:Connect(function() Hover(false) end)

        local function IsPress(Input)
            return Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch
        end
        local Start, StartPos, Moved = nil, nil, false
        Button.InputBegan:Connect(function(Input)
            if not IsPress(Input) then return end
            local View = Screen()
            Start, StartPos, Moved = Input.Position, Vector2.new(Button.Position.X.Scale * View.X, Button.Position.Y.Scale * View.Y), false
            Tween(Scale, 0.08, { Scale = 0.9 })
        end)
        TrackConnection(UserInput.InputChanged:Connect(function(Input)
            if not Start then return end
            if Input.UserInputType ~= Enum.UserInputType.MouseMovement and Input.UserInputType ~= Enum.UserInputType.Touch then return end
            local Delta = Input.Position - Start
            if Delta.Magnitude > 6 then Moved = true end
            if Moved then Place(StartPos.X + Delta.X, StartPos.Y + Delta.Y) end
        end))
        TrackConnection(UserInput.InputEnded:Connect(function(Input)
            if not (Start and IsPress(Input)) then return end
            Start = nil
            Tween(Scale, 0.12, { Scale = 1 })
            if not Moved then
                pcall(Menu.toggle_menu, not LibraryMilenium["items"].Enabled)
            end
        end))

        -- ตั้งค่า "Mobile Button" ในหน้า Settings ของไลบรารี = ซ่อน/โชว์ปุ่มนี้
        Menu.set_mobile_button = function(Bool) Button.Visible = Bool == true end
    end
end

---- ============ Game Data (วัดสดผ่าน dex 2026-10-06) ============ ----
--
-- lobby = place 114574503491412 (มี ReplicatedStorage.lobby) / แมตช์ = place 109151342576374 "AIO GAMEPLAY"
-- (มี ReplicatedStorage.game) - สคริปต์ต้องรันใหม่ทุกครั้งที่ย้าย place (Auto Executor / queue_on_teleport)
--
-- สร้างห้อง (QuqueWindowHandler ของเกม):
--   ห้อง = workspace.Systems.QuqueRooms.<1-6> / สถานะห้อง = ququeRoomStore.namespace:getStore("room N").state
--   (status idle / creating / active / teleporting) - JoinHitbox CanTouch = false = server เช็คตำแหน่งเอง
--   ยืนใน JoinHitbox ของห้อง idle -> server ส่ง toggleQuqueWindow { open = true, roomNumber = N } (วัด ~0.6 วิ)
--   -> packets.createQuque:fire({ gamemode, map, chapter, floor (0 unless Trials), difficulty, maxPlayers, friendsOnly, roomNumber })
--   -> updateClientQuqueStatus "inQuque" -> นับถอยหลัง 5 วิ -> "teleporting" (วัดจริง: Story/Hxh/1/Easy เดี่ยว)
--   ด่าน: Story/Hxh (Act 1-3), Infinite/Zzz, Raid/BathTub (FixedDifficulty 4) - Act ที่เข้าได้ = story.<map>.cleared + 1
--
-- ในแมตช์ (runPackets, u8 ทุกตัว):
--   endAction:fire(1 = Retry, 2 = Next, 3 = Leave) ตอนหน้าจบขึ้น = participants[UserId].status ~= "active"
--   และ travelStatus == "idle" (เงื่อนไขเดียวกับปุ่มใน endScreen ของเกม)

-- Auto Execute รันก่อนเกมโหลดเสร็จ = โฟลเดอร์ lobby / game ยังไม่มา -> IsLobby เป็น false แล้ว Auto Join ไม่เริ่มเลย
-- (ผู้ใช้ 2026-10-12: บางทีไม่วาร์ปไปสร้างห้อง) -> place ของเกม (lobby / แมตช์) รอโฟลเดอร์สูงสุด 15 วิ ไม่มา = Join.Start สั่ง rejoin
local GamePlaces = { [114574503491412] = "lobby", [109151342576374] = "game" }
if GamePlaces[game.PlaceId] then
    local Waited = 0
    while not ReplicatedStorage:FindFirstChild(GamePlaces[game.PlaceId]) and Waited < 15 do
        Waited = Waited + task.wait(0.25)
    end
end

local IsLobby = ReplicatedStorage:FindFirstChild("lobby") ~= nil
local IsMatch = (not IsLobby) and ReplicatedStorage:FindFirstChild("game") ~= nil

-- ค่าเกม (getgenv().Settings.Main) - ConfigurationTable เหลือแค่หน้าตา/ภาษา/FPS
local function Settings()
    return getgenv().Settings.Main
end

-- แจ้งเตือน Discord (ตัวระบบอยู่ช่วง "Webhook (Discord)" - ประกาศตรงนี้ให้โค้ดก่อนหน้านั้นเรียกได้)
local Webhook = { }

-- ฟาร์มวัตถุดิบเอง: ของ evolve (Auto Farm Materials) หรือของคราฟต์ (Auto Craft + Farm Missing Materials)
local function FarmingMaterials()
    if not NormalizeTick() then return false end
    return Settings().AutoFarmMaterials == true or (Settings().AutoCraft == true and Settings().CraftFarm == true)
end

-- สร้างห้องเองใน lobby: Auto Join / ฟาร์มวัตถุดิบ / Auto Trials (ไม่ต้องเปิด Auto Join - ผู้ใช้ 2026-10-06)
local function Joining()
    return Settings().AutoJoin == true or Settings().AutoTrials == true or FarmingMaterials()
end

local function SafeRequire(Parent, ...)
    local Node = Parent
    for _, Name in ipairs({ ... }) do
        Node = Node and Node:WaitForChild(Name, 10)
    end
    if not Node then return nil end
    local Ok, Result = pcall(require, Node)
    return Ok and Result or nil
end

-- อ่านค่าจาก store ของ dime (leaf:get()) - ค่าธรรมดาส่งคืนตรง ๆ
local function Read(Leaf)
    if type(Leaf) == "table" and type(Leaf.get) == "function" then
        local Ok, Value = pcall(Leaf.get, Leaf)
        return Ok and Value or nil
    end
    return Leaf
end

local DifficultyNames = { "Easy", "Medium", "Hard", "Nightmare" }

-- ค่าสำรองตอนอยู่ในแมตช์ (ไม่มี lobby.enums) - ตรงกับ gamemodeSelectEnum วันที่วัด / ใน lobby อ่านของจริงทับ
local Modes = {
    Order = { "Story", "Infinite", "Raid", "Trials" },
    List = {
        Story = { Selectable = true, Maps = { { Id = "Hxh", Name = "Hxh", Chapters = { 1, 2, 3 } } } },
        Infinite = { Selectable = true, Maps = { { Id = "Zzz", Name = "ZZZ World" } } },
        Raid = { Fixed = 4, Maps = { { Id = "BathTub", Name = "Spirit's Bathtub" }, { Id = "ShadowGate", Name = "Shadow Gate" } } },
        Trials = { Maps = { { Id = "Trials", Name = "Trials", Floors = true } } },
    }
}

if IsLobby then
    local Enum2 = SafeRequire(ReplicatedStorage, "lobby", "enums", "gamemodeSelectEnum")
    if Enum2 and type(Enum2.Gamemode) == "table" then
        -- ลำดับเดียวกับหน้าต่างของเกม: Story, Defend, Infinite, Raid แล้วโหมดอื่นเรียงตัวอักษร
        -- เลือกความยากได้เฉพาะ Story / Defend / Infinite (t4 ใน QuqueWindowHandler) ที่เหลือ = FixedDifficulty หรือ 1
        local Order, Rest = { }, { }
        for _, Id in ipairs({ "Story", "Defend", "Infinite", "Raid" }) do
            if Enum2.Gamemode[Id] then table.insert(Order, Id) end
        end
        for Id in pairs(Enum2.Gamemode) do
            if not table.find(Order, Id) then table.insert(Rest, Id) end
        end
        table.sort(Rest)
        for _, Id in ipairs(Rest) do table.insert(Order, Id) end

        local List = { }
        for _, Id in ipairs(Order) do
            local Mode = Enum2.Gamemode[Id]
            local Maps = { }
            for _, Map in ipairs(Mode.Maps or { }) do
                table.insert(Maps, {
                    Id = Map.Id,
                    Name = Map.DisplayName or Map.Id,
                    Chapters = Map.Chapters and table.clone(Map.Chapters) or nil,
                    Floors = Map.Floors == true or nil, -- Trials: floor = Room
                })
            end
            List[Id] = {
                Selectable = (Id == "Story" or Id == "Defend" or Id == "Infinite"),
                Fixed = Mode.FixedDifficulty,
                Maps = Maps
            }
        end

        if #Order > 0 then
            Modes.Order, Modes.List = Order, List
        end
    end
end

local function ModeOf(Name)
    return Modes.List[Name] or Modes.List[Modes.Order[1]]
end

local function MapOf(Mode, Name)
    for _, Map in ipairs(Mode.Maps) do
        if Map.Name == Name or Map.Id == Name then return Map end
    end
    return Mode.Maps[1]
end

local function MapNames(Mode)
    local Names = { }
    for _, Map in ipairs(Mode.Maps) do table.insert(Names, Map.Name) end
    return Names
end

-- ความยากที่โหมดนั้นเลือกได้ (ตรงกับหน้าต่างของเกม): FixedDifficulty = ตัวเดียว (Raid = Nightmare)
-- Story / Defend / Infinite = ทั้ง 4 / โหมดอื่น = Easy อย่างเดียว
local function DifficultyOptions(Mode)
    if Mode.Fixed then return { DifficultyNames[Mode.Fixed] or DifficultyNames[#DifficultyNames] } end
    if Mode.Selectable then return table.clone(DifficultyNames) end
    return { DifficultyNames[1] }
end

local function PickDifficulty(Mode)
    local Options = DifficultyOptions(Mode)
    return table.find(Options, Settings().AutoJoinDifficulty) and Settings().AutoJoinDifficulty or Options[1]
end

local function ChapterNames(Map)
    local Names = { }
    for _, Chapter in ipairs((Map and Map.Chapters) or { 1 }) do
        table.insert(Names, "Act " .. Chapter)
    end
    return Names
end

---- ============ Evolution Materials ============ ----
-- ของ evolve (evolutionConfig[ตัว].ultimate = "itemId,จำนวน|...") หาได้ 3 ทาง:
--   ร้าน (MaterialShopConfig): buyMaterial{itemId, amount, requestId} -> materialShopResult{requestId, success}
--     ของในร้านสุ่มใหม่ทุกวัน (GetStock(day) = tier ละ 2 ชิ้น, tier 4 = 1) / ซื้อได้วันละ tier1 10, tier2 5, tier3 2, tier4 1
--     ที่ซื้อไปแล้ววันนี้ = achievements.progress["matshop.<day>.<id>"] / ราคา tier 2.5k / 10k / 40k / 150k
--   แลก: convertMaterial{source, target, amount, requestId} -> materialShopResult / tier ต่ำกว่า 1 ขั้น 5:1 (upgrade),
--     tier เดียวกัน 3:1 (swap), ครั้งละไม่เกิน 100 / Ghost (113) กับ Staff of Homa (114) ซื้อ/แลกไม่ได้
--   ดรอป (materialDropConfig): Story Hxh Act 1/2/3 ดรอปคนละชุด, ของหายากต้อง Hard/Nightmare / Raid = 113, 114
-- ใช้ได้ทั้ง lobby และในแมตช์ (โมดูลอยู่ global / assets) - เรียกจากเธรดงานเท่านั้น
local Evo = { SlotCount = 15 } -- ช่องตัวละคร (economyConfig.characterSlotCount - อัปเดต 3: 4 -> 15)

do -- local ภายในบล็อกไม่กิน local ของ main chunk (ลิมิต 200 - tools/check-locals.py)
-- ความหายากของตัว (ใช้เลือกเป้า Auto) - ตรงกับ SummonPool (characterRollConfig.rarityByCharacter: Zenless = 5)
local EvoRank = {
    miyabi = 5, hutao = 5, sung_jinwoo = 5, astra_yao = 5, frieren = 5, rin = 5, ye_shunguang = 5,
    sukuna = 4, shanks = 4, katakuri = 4, saber = 3, guts = 3, alucard = 3,
    juuzou = 2, nagumo = 2, luffy = 1, goku = 1, killua = 1,
}

-- ในแมตช์ไม่มี evolutionConfig / MaterialShopConfig (วัดแล้ว) -> ของที่ต้องใช้สำรองไว้ตรงนี้ (evolutionConfig วันที่วัด)
local EvolveNeeds = {
    alucard = { ultimate = "101,30|106,12|108,6|110,3" }, shanks = { ultimate = "101,45|103,20|112,10|111,4" },
    goku = { ultimate = "101,8|102,3|106,3" }, nagumo = { ultimate = "101,20|107,10|105,5" },
    hutao = { ultimate = "101,20|110,8|113,25|114,10" }, miyabi = { ultimate = "101,60|103,30|108,12|112,10|110,4" },
    killua = { ultimate = "101,8|102,3|103,3" }, sukuna = { ultimate = "101,45|106,20|104,10|110,4" },
    saber = { ultimate = "101,30|107,12|105,6|109,3" }, guts = { ultimate = "101,30|106,12|104,6|110,3" },
    juuzou = { ultimate = "101,20|106,10|104,5" }, luffy = { ultimate = "101,8|102,3|106,3" },
    katakuri = { ultimate = "117,50|118,75" }, sung_jinwoo = { ultimate = "101,20|110,8|115,25|116,10" },
    -- update Void Arbiter (2026-10-11): Trials / Leaderboard units, 1M coins + 10k gems each like Hu Tao
    astra_yao = { ultimate = "101,20|103,20|108,12|110,10" }, frieren = { ultimate = "101,20|103,25|108,12|110,8" },
    rin = { ultimate = "101,20|107,25|104,12|109,8" }, ye_shunguang = { ultimate = "101,20|103,20|108,12|110,10" },
}

-- require แบบไม่รอ (โมดูลที่บาง place ไม่มี - SafeRequire รอทีละ 10 วิ)
local function TryRequire(...)
    local Node = ReplicatedStorage
    for _, Name in ipairs({ ... }) do
        Node = Node and Node:FindFirstChild(Name)
    end
    if not Node then return nil end
    local Ok, Result = pcall(require, Node)
    return Ok and Result or nil
end

function Evo.Load()
    if not NormalizeTick() then pcall(function() Players.LocalPlayer:Kick("\226\128\139") end) return false end
    if Evo.Loaded then return true end
    Evo.Account = SafeRequire(ReplicatedStorage, "global", "stores", "accountNamespace")
    Evo.Config = TryRequire("assets", "config", "evolutionConfig") or EvolveNeeds
    Evo.Items = TryRequire("assets", "config", "materialConfig")
    Evo.Shop = TryRequire("assets", "config", "MaterialShopConfig") -- lobby เท่านั้น (ซื้อ/แลก)
    Evo.Drops = TryRequire("assets", "config", "materialDropConfig")
    Evo.Loaded = Evo.Account and Evo.Items and true
    return Evo.Loaded
end

function Evo.Data()
    local Ok, Data = pcall(function() return Evo.Account.getLocalPlayerAccount():toTable() end)
    return Ok and type(Data) == "table" and Data or nil
end

function Evo.Tier(Id)
    local Info = Evo.Items and Evo.Items[tostring(Id)]
    return Info and tonumber(Info.Tier) or 1
end

function Evo.Name(Id)
    local Info = Evo.Items and Evo.Items[tostring(Id)]
    return Info and Info.Name or tostring(Id)
end

-- ขั้นของ Shadow Monarch (sung_jinwoo): achievements.progress["evo.sung_jinwoo"] 0-3 (MonarchPathConfig)
-- 0 = ยังไม่ปลด ult -> ขั้น I ใช้ evolve ปกติ (evolutionConfig) / 1-2 = ขั้น II-III ใช้ monarchEvolve (Stages[n].Materials/Currencies)
function Evo.Monarch()
    Evo.Path = Evo.Path or TryRequire("assets", "config", "MonarchPathConfig")
    return Evo.Path
end

function Evo.Stage()
    local Path = Evo.Monarch()
    if not (Path and Evo.Account) then return 0 end
    local Ok, Stage = pcall(Path.GetStage, Evo.Account.getLocalPlayerAccount())
    return Ok and tonumber(Stage) or 0
end

-- ค่า evolve ขั้นถัดไป { Materials = { [id] = n }, Currencies = { money = n }, Step, Monarch } / evolve ครบแล้ว = nil
function Evo.Cost(Character, Data)
    local Path = Evo.Monarch()
    if Path and Character == Path.Character then
        local Stage = Evo.Stage()
        if Stage >= 1 then
            local Next = Path.Stages and Path.Stages[Stage + 1]
            if not Next then return nil end
            local Cost = { Materials = { }, Currencies = { }, Step = ("%s %s"):format(tostring(Next.Numeral or (Stage + 1)), tostring(Next.Name or "")), Monarch = Stage + 1 }
            for Item, Amount in tostring(Next.Materials or ""):gmatch("(%d+),(%d+)") do Cost.Materials[Item] = (Cost.Materials[Item] or 0) + tonumber(Amount) end
            for Key, Amount in pairs(Next.Currencies or { }) do Cost.Currencies[Key] = tonumber(Amount) or 0 end
            return Cost
        end
    end
    local Info = Data and Data.CharactersData and Data.CharactersData[Character]
    if type(Info) == "table" and Info.IsUltimateUnlocked then return nil end
    local Config = Evo.Config and Evo.Config[Character]
    local Cost = { Materials = { }, Currencies = { }, Step = "Ultimate" }
    for Item, Amount in tostring(Config and Config.ultimate or ""):gmatch("(%d+),(%d+)") do
        Cost.Materials[Item] = (Cost.Materials[Item] or 0) + tonumber(Amount)
    end
    for _, Entry in ipairs(type(Config) == "table" and Config.currencies or { }) do
        if type(Entry) == "table" and Entry.currency then Cost.Currencies[Entry.currency] = tonumber(Entry.amount) or 0 end
    end
    return Cost
end

-- ของที่ขั้นถัดไปใช้ (Shadow Monarch = ตามขั้น) / evolve ครบแล้ว = ว่าง
function Evo.Need(Character, Data)
    local Cost = Evo.Cost(Character, Data or Evo.Data())
    return Cost and Cost.Materials or { }
end

-- ของที่ยังขาด { [itemId] = จำนวน } ของตัวนั้น
-- ของที่ยังขาด { [itemId] = จำนวน } จาก Need { [itemId] = จำนวน }
-- อัปเดต 3: อาหาร Trials (Caprese 121 / Ham 122 / Omurice 123 / Burger 124 = ของ tier 1-4) ใช้แทนของ awaken (ปลด ult) ที่ขาด
-- ใน tier เดียวกัน - MaterialShopConfig.GetFoodPlan({ { id, จำนวน } }, กระเป๋า) -> { Id, Need, Own, Food, FoodId }
-- (หน้าต่าง Evolve ของเกม: "Trials food covers the rest") / ไม่มีโมดูล (ในแมตช์) หรือขั้น Shadow Monarch = นับแต่ของจริง
function Evo.Short(Need, Bag, NoFood)
    Bag = Bag or { }
    if not NoFood and Evo.Shop and Evo.Shop.GetFoodPlan then
        local List = { }
        for Item, Amount in pairs(Need) do table.insert(List, { Item, Amount }) end
        local Ok, Rows = pcall(Evo.Shop.GetFoodPlan, List, Bag)
        if Ok and type(Rows) == "table" then
            local Missing = { }
            for _, Row in ipairs(Rows) do
                local Left = (tonumber(Row.Need) or 0) - (tonumber(Row.Own) or 0) - (tonumber(Row.Food) or 0)
                if Left > 0 then Missing[tostring(Row.Id)] = Left end
            end
            return Missing
        end
    end
    local Missing = { }
    for Item, Amount in pairs(Need) do
        local Left = Amount - (tonumber(Bag[Item]) or 0)
        if Left > 0 then Missing[Item] = Left end
    end
    return Missing
end

function Evo.Missing(Data, Character)
    local Cost = Evo.Cost(Character, Data)
    return Evo.Short(Cost and Cost.Materials or { }, Data and Data.material, Cost and Cost.Monarch ~= nil)
end

-- ตัวที่มีและยังไม่ evolve (ช่องที่ปลดแล้ว)
function Evo.Pending(Data)
    local List, Seen = { }, { }
    for Slot = 1, Evo.SlotCount do
        local Entry = Data and Data.UnlockedCharacters and Data.UnlockedCharacters["Slot" .. Slot]
        local Name = Entry and Entry.Unlocked and Entry.Character
        if type(Name) == "string" and Name ~= "" and not Seen[Name] and Evo.Config and Evo.Config[Name] then
            Seen[Name] = true
            if Evo.Cost(Name, Data) then table.insert(List, Name) end
        end
    end
    return List
end

-- เป้า: ตั้งเอง = ตัวนั้น (ถ้ายังไม่ evolve) / Auto = ตัวที่มีที่หายากสุดที่ของยังไม่ครบ (ครบแล้ว = รอ Auto Evolve)
function Evo.Target(Data)
    local Wanted = string.lower(tostring(Settings().EvolveTarget or "Auto"))
    if Wanted ~= "auto" then
        return (Evo.Config and Evo.Config[Wanted] and Evo.Cost(Wanted, Data)) and Wanted or nil
    end
    -- หายากเท่ากัน = ตัวที่ขาดน้อยกว่า (นับค่าเป็น 5^(tier-1) ต่อชิ้น เท่ากับค่าแลก)
    local Best, BestRank, BestLeft = nil, -1, math.huge
    for _, Name in ipairs(Evo.Pending(Data)) do
        local Missing = Evo.Missing(Data, Name)
        if next(Missing) then
            local Left = 0
            for Item, Amount in pairs(Missing) do Left = Left + Amount * 5 ^ (Evo.Tier(Item) - 1) end
            local Rank = EvoRank[Name] or 0
            if Rank > BestRank or (Rank == BestRank and Left < BestLeft) then
                Best, BestRank, BestLeft = Name, Rank, Left
            end
        end
    end
    return Best
end

-- ของที่ต้องเก็บไว้ = ที่ทุกตัวที่ยังไม่ evolve ต้องใช้ + เป้า (แลกได้เฉพาะส่วนเกินจากนี้)
function Evo.Reserved(Data, Target)
    local Reserved = { }
    local List = Evo.Pending(Data)
    if Target and not table.find(List, Target) then table.insert(List, Target) end
    for _, Name in ipairs(List) do
        for Item, Amount in pairs(Evo.Need(Name, Data)) do Reserved[Item] = (Reserved[Item] or 0) + Amount end
    end
    return Reserved
end

-- โอกาสดรอปต่อ 1 roll (ไล่ลงตาราง = ของบนสุดได้ก่อน เหมือน GetChance ของเกม)
local function RollChances(Table)
    local Out, Left = { }, 1
    for _, Entry in ipairs(Table or { }) do
        local Chance = tonumber(Entry.Chance) or 0
        Out[tostring(Entry.Item)] = Left * Chance
        Left = Left * (1 - Chance)
    end
    return Out
end

-- ด่านที่คุ้มสุดสำหรับของที่ขาด: { Mode, Map, Chapter, Difficulty, Key, Label }
-- คะแนน = Σ ของที่ได้ต่อรอบ (ไม่เกินที่ขาด) x 5^(tier-1) (เท่ากับค่าแลก upgrade 5:1) / ของที่ไม่ขาด = 1/5 (ไว้แลก)
-- Story ใช้ความยากตาม Auto Join / Act ที่ยังไม่ปลดไม่นับ / ของจาก Raid อย่างเดียว (Ghost, Staff of Homa) = Raid
function Evo.Plan(Data)
    if not (Evo.Load() and Evo.Drops) then return nil end
    Data = Data or Evo.Data()
    if not Data then return nil end
    -- ของที่ต้องหา = ของ evolve (Auto Farm Materials) + ของคราฟต์ที่เหลือ (Farm Missing Materials) - ที่มีในกระเป๋า
    local Target = Settings().AutoFarmMaterials and Evo.Target(Data) or nil
    local Need = Target and Evo.Need(Target, Data) or { }
    if Evo.CraftNeed then
        for Item, Amount in pairs(Evo.CraftNeed(Data)) do Need[Item] = (Need[Item] or 0) + Amount end
    end
    -- ของ evolve อย่างเดียว = นับอาหาร Trials แทนของที่ขาดด้วย (Evo.Missing) / มีของคราฟต์ด้วย = นับของจริงรวมกัน
    local Crafting = Evo.CraftNeed and next(Evo.CraftNeed(Data)) ~= nil
    local Missing = (Target and not Crafting) and Evo.Missing(Data, Target) or Evo.Short(Need, Data.material, true)
    if not next(Missing) then return nil end

    -- คะแนนของที่ขาด / คะแนนของแถม แยกกัน: ของแถมเอาไว้ตัดสินตอนเสมอเท่านั้น
    -- (เดิมรวมกัน = ขาด 103 ชิ้นเดียว Act 1 ที่ไม่ดรอป 103 ชนะ Act 3 -> ฟาร์มไม่จบทั้งที่ของอื่นครบแล้ว)
    local function Score(Chances, Rolls)
        local Wanted, Extra = 0, 0
        for Item, Chance in pairs(Chances) do
            local Value = 5 ^ (Evo.Tier(Item) - 1)
            local Expected = Chance * Rolls
            if Missing[Item] then
                Wanted = Wanted + math.min(Expected, Missing[Item]) * Value
            else
                Extra = Extra + Expected * Value * 0.2
            end
        end
        return Wanted, Extra
    end

    if Missing["113"] or Missing["114"] then
        return { Mode = "Raid", Map = "BathTub", Chapter = 0, Difficulty = 4, Key = "Raid:BathTub", Label = "Raid - Spirit's Bathtub", Target = Target }
    end
    -- ของ Shadow Monarch / Katakuri (115-120) ดรอปจาก Shadow Gate อย่างเดียว (materialDropConfig.sololevelingraid, เล่นได้ไม่จำกัด)
    for _, Item in ipairs({ "115", "116", "117", "118", "119", "120" }) do
        if Missing[Item] then
            return { Mode = "Raid", Map = "ShadowGate", Chapter = 0, Difficulty = 4, Key = "Raid:ShadowGate", Label = "Raid - Shadow Gate", Target = Target }
        end
    end

    local Unlocked = 1
    pcall(function()
        local Progress = Evo.Account.getLocalPlayerAccount().state.achievements.progress:get("story.hxh.cleared")
        Unlocked = (tonumber(Progress and Progress:get()) or 0) + 1
    end)

    -- ความยากตาม Auto Join ก่อน / ไม่มี Act ไหนดรอปของที่ขาด (Easy ดรอปแค่ 101-102) = ขยับขึ้นความยากถัดไป
    local Names = { "Easy", "Medium", "Hard", "Nightmare" }
    local Index = table.find(Names, tostring(Settings().AutoJoinDifficulty or "Easy")) or 1
    local Best, Difficulty = nil, nil
    for Try = Index, #Names do
        local Rolls = 1
        pcall(function() Rolls = Evo.Drops.GetClearRolls("hxh", Names[Try]) end)
        local BestWanted, BestExtra = 0, 0
        for Act = 1, math.min(Unlocked, 3) do
            local Ok, Table = pcall(Evo.Drops.GetTable, "hxh", Act, Names[Try])
            if Ok then
                local Wanted, Extra = Score(RollChances(Table), Rolls)
                if Wanted > BestWanted or (Wanted > 0 and Wanted == BestWanted and Extra > BestExtra) then
                    Best, BestWanted, BestExtra = Act, Wanted, Extra
                end
            end
        end
        if Best then Index, Difficulty = Try, Names[Try] break end
    end
    if not Best then return nil end
    return {
        Mode = "Story", Map = "Hxh", Chapter = Best, Difficulty = Index, Target = Target,
        Key = ("Story:Hxh:%d:%d"):format(Best, Index),
        Label = ("Story - Hxh Act %d (%s)"):format(Best, Difficulty),
    }
end
end

---- ============ Auto Join ============ ----

local Join = { Thread = nil, ClientStatus = "idle", RoomNumber = nil, Hooks = { } }

-- เธรดที่ require โมดูลเกม (ลูป Auto Join) capability ตก -> แตะ instance ของ UI ไม่ได้ (วัดแล้ว 2026-10-06:
-- "lacking capability Plugin") เลยเก็บแค่ข้อความ แล้วให้เธรดที่แตกจากเธรดหลักวาดการ์ดแทน (ท้ายแท็บ)
local function SetStatus(Text)
    Join.Text = Text
end

-- Act ที่เข้าได้ (ตาม GetUnlockedAct ของเกม): story.<map>.cleared + 1
local function UnlockedAct(MapId)
    local Account = SafeRequire(ReplicatedStorage, "global", "stores", "accountNamespace")
    local Ok, Value = pcall(function()
        local Progress = Account.getLocalPlayerAccount().state.achievements.progress:get("story." .. string.lower(MapId) .. ".cleared")
        return Progress and Progress:get() or 0
    end)
    return (Ok and tonumber(Value) or 0) + 1
end

-- ==== Trials (อัปเดต Void Arbiter 2026-10-11, วัดสดจาก QuqueWindowHandler) ====
-- Trials = ห้อง (Room) 1, 2, 3 ... ห้องละ 5 ชั้น ต้องเคลียร์รวดเดียว / เล่นได้ไม่จำกัด (ไม่อยู่ใน RaidAttemptsConfig)
-- ห้องสูงสุดที่ผ่าน = achievements.progress["trials.s<Season.Id>.room"] (LeaderboardSeasonConfig) / เล่นได้ถึงห้องนั้น + 1
-- สร้างห้องเหมือนโหมดอื่น: createQuque{ gamemode "Trials", map "Trials", chapter 0, floor = Room, difficulty 1 (ไม่มี
-- FixedDifficulty) } - เดี่ยวไม่ผ่าน MatchRemote / แท็บ Classes ในหน้าต่างแค่โชว์ตัวละครของ Trials ไม่มีอะไรให้เลือก
-- ของรางวัล: Astra Yao / Frieren / Ye-0 (RaidUnitConfig.Exclusive) / Rin = ชั้น 200 (small patch: ทุกคนได้, ท็อป 0.1% ได้ฉายา)
-- small patch 2026-10-11: ในเกมเรียกเลขใหญ่ว่า Floor (ชั้นละ 5 Room) - โค้ด/คีย์ยังชื่อ room เหมือนเดิม
-- ("trials.s1.room", TrialsRoom = เลขใหญ่, TrialsFloor = 1-5) / hub โชว์ว่า Floor ตามเกม
local Trials = { }

function Trials.Season()
    local Ok, Config = pcall(function() return require(ReplicatedStorage.assets.config.LeaderboardSeasonConfig) end)
    return Ok and type(Config) == "table" and Config.Season and Config.Season.Id or 1
end

-- ห้องสูงสุดที่ผ่าน: season นี้ = "trials.s<Season.Id>.room" (เล่นได้ถึง +1) / ตลอดกาล = "trials.room" (game.Trials.BestKey)
function Trials.Progress(Key)
    local Account = SafeRequire(ReplicatedStorage, "global", "stores", "accountNamespace")
    local Ok, Value = pcall(function()
        local Progress = Account.getLocalPlayerAccount().state.achievements.progress:get(Key)
        return Progress and Progress:get() or 0
    end)
    return Ok and tonumber(Value) or 0
end

function Trials.Highest()
    return Trials.Progress(("trials.s%s.room"):format(tostring(Trials.Season())))
end

-- ห้องที่จะเล่น: Best Room = ห้องสูงสุดที่เล่นได้ (Highest + 1 - ชนะแล้วขยับเอง) / ปิด = ห้องที่เลือก (Room)
-- ไม่เกินห้องที่เล่นได้
function Trials.Room()
    local Open = Trials.Highest() + 1
    if Settings().TrialsBest ~= false then return Open end
    return math.clamp(math.floor(tonumber(Settings().TrialsRoom) or 1), 1, Open)
end

-- ผลรอบล่าสุด (โชว์ในกล่อง Trials): เวลา = runStore finishedAt - startedAt / ระดับ = game.Trials.GetRank
-- (S <= 90 วิ, A <= 150, B <= 240, C <= 360, ไม่งั้น D)
function Trials.Record(State, Won)
    local Room = tonumber(workspace:GetAttribute("TrialsRoom")) or 0
    local Started, Finished = tonumber(Read(State.startedAt)), tonumber(Read(State.finishedAt))
    local Text = ("Floor %d - lost"):format(Room)
    if Won and Started and Finished then
        local Took = Finished - Started
        local Ok, Rank = pcall(function() return require(ReplicatedStorage.game.Trials).GetRank(Took) end)
        Text = ("Floor %d - %.1fs (%s)"):format(Room, Took, Ok and tostring(Rank) or "?")
    end
    if Settings().TrialsLast ~= Text then
        Settings().TrialsLast = Text
        SaveSetting()
    end
end

local function JoinArgs()
    -- ฟาร์มวัตถุดิบ: ด่านตามแผน (จำ Key ไว้ - ในแมตช์แผนเปลี่ยน = ออกมาเลือกด่านใหม่)
    if FarmingMaterials() then
        local Plan = Evo.Plan()
        Settings().MaterialFarmKey = Plan and Plan.Key or nil
        SaveSetting()
        if not Plan and not Settings().AutoJoin and not Settings().AutoTrials then return nil end -- ฟาร์มอย่างเดียว + ของครบ = ไม่เข้าด่าน
        if Plan then
            return {
                gamemode = Plan.Mode,
                map = Plan.Map,
                chapter = Plan.Chapter,
                difficulty = Plan.Difficulty,
                maxPlayers = 1,
                friendsOnly = true,
            }
        end
    end

    -- Auto Trials (มาก่อนโหมดของ Auto Join): ไต่ห้องไปเรื่อย ๆ
    if Settings().AutoTrials then
        return { gamemode = "Trials", map = "Trials", chapter = 0, floor = Trials.Room(), difficulty = 1, maxPlayers = 1, friendsOnly = true }
    end

    local Mode = ModeOf(Settings().AutoJoinMode)
    local ModeId = table.find(Modes.Order, Settings().AutoJoinMode) and Settings().AutoJoinMode or Modes.Order[1]
    local Map = MapOf(Mode, Settings().AutoJoinMap)

    local Chapter = 0
    if Map.Chapters then
        Chapter = tonumber(Settings().AutoJoinChapter) or Map.Chapters[1]
        if not table.find(Map.Chapters, Chapter) then Chapter = Map.Chapters[1] end
        Chapter = math.min(Chapter, math.max(Map.Chapters[1], UnlockedAct(Map.Id)))
    end

    local Difficulty = table.find(DifficultyNames, PickDifficulty(Mode)) or 1

    return {
        gamemode = ModeId,
        map = Map.Id,
        chapter = Chapter,
        floor = Map.Floors and Trials.Room() or 0,
        difficulty = Difficulty,
        maxPlayers = 1,
        friendsOnly = true,
    }
end

local function Root()
    local Character = LocalPlayer.Character
    return Character and Character:FindFirstChild("HumanoidRootPart")
end

-- เดินทางแบบ Tween (เหมือน HazeSea): ผู้ใช้ 2026-10-11 - วาร์ป CFrame ไปไกล ๆ ทีเดียว server ดึงกลับ
-- (วัดสด: วาร์ปไปกำแพง = ตีไม่เข้า 0 hit / บินไป = กำแพงพังใน 3 วิ) -> ทุกการเดินทาง (lobby / ตีมอน / กำแพง / ลิฟต์ /
-- เก็บของ) ขยับทีละ TweenSpeed x dt ต่อเฟรม (ทะลุสิ่งกีดขวาง) / ใกล้ถึงไม่เกิน SnapRange = วาปไปเลย (ผู้ใช้ 2026-10-11)
-- ความเร็ว = เร็วสุดที่ server ไม่ดึงกลับ - วัดสด บินไป-กลับ 15 วิ: 65 = 0 ครั้ง / 70 = 3 / 75 = 5 / 100 ขึ้นไปโดนตลอด
-- SnapRange วัดใน Trials 1 นาที: 30 = โดนดึงกลับ 24 ครั้ง ชั้นละ 19-22 วิ / 15 = 2 ครั้ง ชั้นละ 17 วิ
-- ผู้ใช้ 2026-10-13 ยังเห็นวาปกลับ อยากให้ลื่นสุด -> 5 (วาปตรงแค่ช่วงท้ายสั้น ๆ ที่เหลือ Tween ทั้งหมด)
-- (Clone Humanoid แบบ STE ไม่ช่วย - ดึงกลับฝั่ง server / WalkSpeed ระหว่าง M1 ตกเหลือ 14 แต่เพดานเท่าเดิม)
local TweenSpeed, SnapRange = 65, 5

-- Dash ของเกม (characterPackets.performDash แบบกดปุ่ม dash) = server ยอมให้ขยับไกลขึ้นชั่วคราว
-- วัดสด 2026-10-13: ไม่ dash เพดาน ~80/s / dash ทุก 0.8 วิ = 110/s 5 วิผ่าน, 125/s โดนดึง
-- BoostSpeed 90 (เดิม 100): เผื่อ ping สูงฝั่งผู้ใช้ (ผู้ใช้ยังเห็นวาปกลับ แม้เครื่องทดสอบ 40 วิไม่โดนเลย)
-- ไกลกว่า BoostRange = ยิง dash ทุก 0.8 วิ / ใกล้ (กำลังตี) = TweenSpeed เดิม ไม่ dash
-- เร่งเป็น BoostSpeed เฉพาะตอน server รับ dash จริง: server ตั้ง attribute DashingUntil ของตัวละคร (= เวลารับ + 0.27)
-- วัดสด 2026-10-13: server ปัด dash บางครั้ง (ติดท่า / cooldown) แต่เดิมเร่ง 90 ทุกครั้ง = โดนดึงกลับ 4 ครั้งใน 58 วิ
-- ทุกครั้งเกิดตอนเร่งหลังยิง dash 0.2-0.8 วิ / ที่ 65 ไม่โดนเลย
Join.BoostSpeed, Join.BoostRange, Join.LastDash = 90, 40, 0

-- ระยะที่ขยับได้ในเฟรมนี้: Teleport Step (ผู้ใช้ 2026-10-15 "ค่อย ๆ tp ไปทีละ 10-20 studs") = วาปทีละ TpStep ทุกเฟรม
-- (~600-1200 studs/วิ ที่ 60 fps) / 0 = บินแบบเดิม TravelSpeed x dt
-- วัดสด 2026-10-15: ไม่มี packet ดึงตำแหน่งกลับ / ตัวบนจอไม่โดนดึงกลับ / ระยะ <= ~75 server รับแทบทันที
-- (วาปทีเดียว 76 ไปกำแพง = ดาเมจใน 0.3 วิ) / 167 ทีเดียวเข้าโซน = มอนเกิดช้า > 4 วิ - ระยะไกลยังไม่ได้วัดแบบทีละนิด
function Join.TravelStep(Distance, Dt)
    local Step = tonumber(Settings().TpStep) or 0
    if IsMatch and Step > 0 then return Step end
    return Join.TravelSpeed(Distance) * math.min(Dt, 0.1)
end
function Join.TravelSpeed(Distance)
    if Distance <= Join.BoostRange then return TweenSpeed end
    local Character = LocalPlayer.Character
    if not Character then return TweenSpeed end
    if os.clock() - Join.LastDash >= 0.8 then
        Join.CharPackets = Join.CharPackets or SafeRequire(ReplicatedStorage, "game", "packets", "characterPackets")
        local Dash = Join.CharPackets and Join.CharPackets.performDash
        if Dash and pcall(Dash.fire, Dash, Character) then Join.LastDash = os.clock() end
    end
    local Until = tonumber(Character:GetAttribute("DashingUntil")) or 0
    return workspace:GetServerTimeNow() - Until < 0.55 and Join.BoostSpeed or TweenSpeed
end

local function TweenTo(Position, Timeout)
    -- lobby ไม่มี anti-cheat (ผู้ใช้ 2026-10-12) = วาร์ปทันที / Tween ใช้เฉพาะในแมตช์
    if IsLobby then
        local Hrp = Root()
        if not Hrp then return false end
        Hrp.AssemblyLinearVelocity = Vector3.zero
        Hrp.CFrame = CFrame.new(Position) * Hrp.CFrame.Rotation
        return true
    end
    local Deadline = os.clock() + (Timeout or 20)
    local Ghost = { } -- ปิดชนระหว่างบิน (ทะลุกำแพง) แล้วคืนตอนถึง ไม่งั้นยืนแล้วตกพื้น
    local Arrived = false
    while os.clock() < Deadline do
        local Hrp = Root()
        if not Hrp then break end
        for _, Part in ipairs(Hrp.Parent:GetDescendants()) do
            if Part:IsA("BasePart") and Part.CanCollide then
                Part.CanCollide = false
                table.insert(Ghost, Part)
            end
        end
        local Travel = Position - Hrp.Position
        local Step = Join.TravelStep(Travel.Magnitude, RunService.Heartbeat:Wait())
        Hrp = Root()
        if not Hrp then break end
        Hrp.AssemblyLinearVelocity = Vector3.zero
        if Travel.Magnitude <= math.max(Step, SnapRange) then
            Hrp.CFrame = CFrame.new(Position) * Hrp.CFrame.Rotation
            Arrived = true
            break
        end
        Hrp.CFrame = CFrame.new(Hrp.Position + Travel.Unit * Step) * Hrp.CFrame.Rotation
    end
    for _, Part in ipairs(Ghost) do
        if Part.Parent then Part.CanCollide = true end
    end
    return Arrived
end

-- อยู่ในกล่องห้องไหม (ลึกเข้าไป Margin) - Hold ใช้เช็คว่าหลุดจุดหรือยัง
-- กล่องห้องหมุนอยู่ (แกน Y ของกล่องเป็นแนวนอน - วัดสด) -> เช็คสองแกนที่เป็นแนวนอนจริง (ข้ามแกนที่ชี้ขึ้น)
function Join.InBox(Position, Box, Margin)
    local Local = Box.CFrame:PointToObjectSpace(Position)
    local Half = Box.Size / 2
    local Up = Box.CFrame:VectorToObjectSpace(Vector3.yAxis)
    local Axes = {
        { math.abs(Local.X), Half.X, math.abs(Up.X) },
        { math.abs(Local.Y), Half.Y, math.abs(Up.Y) },
        { math.abs(Local.Z), Half.Z, math.abs(Up.Z) },
    }
    table.sort(Axes, function(A, B) return A[3] < B[3] end) -- แกนที่ชี้ขึ้นสุดอยู่ท้าย = ไม่เช็ค
    return Axes[1][1] <= Axes[1][2] - Margin and Axes[2][1] <= Axes[2][2] - Margin
end

-- server เปิดหน้าต่างห้องตอน "เข้า" กล่องเท่านั้น (วัดสด 2026-10-12: เข้าแล้วบางทีไม่เปิด ยืนอยู่ในกล่องต่อก็ไม่เปิด
-- ออกแล้วเข้าใหม่ = เปิด) -> วาร์ปออกไปนอกกล่อง 4 studs แล้ววาร์ปกลับ
function Join.Reenter(Spot, Box)
    TweenTo(Spot + Vector3.new(math.max(Box.Size.X, Box.Size.Y, Box.Size.Z) / 2 + 4, 0, 0))
    task.wait(0.5)
    TweenTo(Spot)
end

local function LobbyStep(Packets, Rooms)
    if Join.ClientStatus == "inQuque" or Join.ClientStatus == "teleporting" then
        -- วาร์ปไม่สำเร็จ (เช่น Roblox ต้องอัปเดต) server ไม่ส่งสถานะกลับ = ค้าง "teleporting" ตลอดไป
        -- เกิน 45 วิ = ถือว่าล้ม ออกคิวแล้วเริ่มหาห้องใหม่
        if Join.StatusAt and os.clock() - Join.StatusAt > 45 then
            pcall(function() Packets.leaveQuque:fire() end)
            Join.ClientStatus, Join.StatusAt = "idle", nil
            SetStatus("Teleport failed - retrying")
            task.wait(3)
            return
        end
        SetStatus(Join.ClientStatus == "teleporting" and "Teleporting to match" or "In queue - waiting")
        return
    end

    -- เก็บของ Event อยู่ (Auto Collect Event Drops) = รอ (event ฝนตกสั้น ~8 วิ)
    if Join.EventBusy then
        SetStatus("Collecting event drops")
        return
    end

    -- ฟาร์มของ evolve อย่างเดียว (Auto Join ปิด) แต่ของครบแล้ว = ไม่ต้องเข้าห้อง
    if not Settings().AutoJoin and not Settings().AutoTrials and not Evo.Plan() then
        SetStatus("Materials complete - nothing to farm")
        if not Webhook.MaterialsDone then
            Webhook.MaterialsDone = true
            Webhook.Push("Auto Stopped", "materials", Webhook.T("MaterialsDone"), { Urgent = true })
        end
        return
    end

    local Hrp = Root()
    if not Hrp then
        SetStatus("Waiting for character")
        return
    end

    local Folder = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("QuqueRooms")
    if not Folder then
        SetStatus("Waiting for rooms")
        return
    end

    -- ห้องว่าง: ห้องเดิมที่ลองไว้ก่อน (ไม่สลับไปมาหลายห้อง) ไม่งั้นห้องว่างที่ใกล้สุด (เดินสั้นสุด)
    local function Idle(Index)
        local Store = Rooms:getStore("room " .. Index)
        return Store and Read(Store.state.status) == "idle"
    end
    local function HitboxOf(Index)
        local Model = Folder:FindFirstChild(tostring(Index))
        return Model and Model:FindFirstChild("JoinHitbox", true)
    end
    local Room = Join.LastRoom and Idle(Join.LastRoom) and HitboxOf(Join.LastRoom) and Join.LastRoom or nil
    if not Room then
        local Best
        for Index = 1, 6 do
            local Box = HitboxOf(Index)
            if Box and Idle(Index) then
                local Distance = (Box.Position - Hrp.Position).Magnitude
                if not Best or Distance < Best then Room, Best = Index, Distance end
            end
        end
    end

    local Hitbox = Room and HitboxOf(Room)
    if not Hitbox then
        SetStatus("All rooms busy")
        return
    end
    Join.LastRoom = Room

    -- ยืนตรงบนพื้นในกล่อง (เดิม CFrame = Hitbox.CFrame ทั้งก้อน = ลอยกลางกล่อง / เอียงตามกล่อง แล้ววาปซ้ำทุก 0.1 วิ = ตัวสั่น)
    local Spot = Hitbox.Position
    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = { LocalPlayer.Character, Hitbox }
    local Hit = workspace:Raycast(Hitbox.Position, Vector3.new(0, -(Hitbox.Size.Y / 2 + 6), 0), Params)
    if Hit then
        local Hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        Spot = Hit.Position + Vector3.new(0, (Hum and Hum.HipHeight or 2) + Hrp.Size.Y / 2, 0)
    end

    -- วาร์ปเข้ากล่องแล้วยืนอยู่ในนั้นจนเข้าคิว (ออกจากกล่อง = server ยกเลิกห้อง) - หลุดจุด = วาร์ปกลับ
    local function Hold()
        local Now = Root()
        if Now and not Join.InBox(Now.Position, Hitbox, 1) then TweenTo(Spot) end
    end

    SetStatus("Entering room " .. Room)
    Join.RoomNumber = nil
    TweenTo(Spot)

    -- ไม่เปิดใน 3 วิ = ออกแล้วเข้าใหม่ (ไม่เกิน 2 รอบ)
    for Try = 0, 2 do
        if Try > 0 then
            SetStatus("Re-entering room " .. Room)
            Join.Reenter(Spot, Hitbox)
        end
        local Waited = 0
        while not Join.RoomNumber and Waited < 3 do
            Waited = Waited + task.wait(0.1)
            Hold()
        end
        if Join.RoomNumber then break end
    end

    if not Join.RoomNumber then
        SetStatus("Room did not open - retrying")
        task.wait(2)
        return
    end

    local Args = JoinArgs()
    if not Args then
        pcall(function() Packets.playerCloseQuqueWindow:fire() end)
        SetStatus("Materials complete - nothing to farm")
        task.wait(10)
        return
    end
    Args.roomNumber = Join.RoomNumber
    -- update "Void Arbiter" (2026-10-11) added floor (u16, Trials room) to the packet: missing = the
    -- serializer errors and no room is ever made. The game sends 0 for every map without Floors
    Args.floor = Args.floor or 0
    Packets.createQuque:fire(Args)
    SetStatus(Args.floor > 0 and string.format("Creating Trials / Floor %d", Args.floor)
        or string.format("Creating %s / %s / Act %d / %s", Args.gamemode, Args.map, Args.chapter, DifficultyNames[Args.difficulty] or "?"))

    local Waited = 0
    while Join.ClientStatus ~= "inQuque" and Join.ClientStatus ~= "teleporting" and Waited < 6 do
        Waited = Waited + task.wait(0.2)
        Hold()
    end

    if Join.ClientStatus ~= "inQuque" and Join.ClientStatus ~= "teleporting" then
        -- server ไม่รับ (เช่น Act ยังไม่ปลด) - ปิดหน้าต่างเหมือนกดปุ่ม X แล้วลองใหม่
        pcall(function() Packets.playerCloseQuqueWindow:fire() end)
        SetStatus("Queue rejected - check mode/act")
        task.wait(3)
    elseif Join.ClientStatus == "inQuque" then
        -- ปุ่ม Start Now ของเกม (StartQuqueNow) = ข้ามนับถอยหลัง 5 วิ
        task.wait(0.3)
        pcall(function() Packets.startQuqueNow:fire() end)
    end
end

---- ในแมตช์: โหวตความยาก + จัดการหน้าจอจบ ----

local Match = { EndedAt = 0 }

-- ลูปต้องทำงานไหม: lobby = Auto Join / แมตช์ = On Finish (Retry / Leave) ทำงานเองไม่ต้องเปิด Auto Join
-- (ผู้ใช้ 2026-10-06: ตั้ง Retry ไว้แต่ Auto Join ปิด = เดิมไม่กดให้)
local function JoinWanted()
    if IsMatch then
        local Finish = Settings().AutoJoinOnFinish
        return Finish == "Retry" or Finish == "Next" or Finish == "Leave" or FarmingMaterials() or Settings().AutoTrials == true
    end
    return Joining()
end

local function MatchStep(Packets, State)
    local Key = tostring(LocalPlayer.UserId)

    local Finish = Settings().AutoJoinOnFinish
    local Trial = Settings().AutoTrials == true and workspace:GetAttribute("Mode") == "trials"
    if Trial and Settings().TrialsOnFinish == "None" then return end
    if Finish ~= "Retry" and Finish ~= "Next" and Finish ~= "Leave" and not FarmingMaterials() and not Trial then return end

    local Me = nil
    pcall(function() Me = State.participants:get(Key) end)
    if not Me then return end

    local Status = Read(Me.status)
    local Travel = Read(Me.travelStatus)
    local ResultAt = Read(State.resultEndsAt)

    -- หน้าจบ = มี resultEndsAt + เราไม่ active (ต้นแมตช์ status ยังไม่เป็น active = ห้ามยิง)
    -- กดโหวตเดิมซ้ำ = เกมถือว่ากดอีกที -> ยิงเฉพาะตอน resultVotes ของเรายังไม่ใช่ตัวที่ต้องการ
    if ResultAt and Status and Status ~= "active" and Travel == "idle" then
        -- endAction: 1 = Retry, 2 = Next (ปุ่มขึ้นเฉพาะ runStore.canNext = ชนะ + มีด่านถัดไป), 3 = Leave
        -- Next ใช้ไม่ได้ (แพ้ / Act สุดท้าย / โหมดไม่มีด่านต่อ) = เล่นซ้ำแทน
        local Action = 1
        if Trial then
            -- Auto Trials / On Finish ของ Trials (แยกจาก Auto Join) / Retry = ชั้นเดิม
            -- small patch 2026-10-11: ชนะแล้ว canNext = true -> ปุ่ม Next Floor (endAction 2) ขึ้นชั้นถัดไปในแมตช์เลย
            -- Next: ชนะ = Next Floor (ไม่มีปุ่ม = ออกไป lobby สร้างชั้นถัดไป), แพ้ = เล่นซ้ำ
            local Won = Read(State.status) == "victory"
            if not Match.Recorded then
                Match.Recorded = true
                Trials.Record(State, Won)
            end
            local OnFinish = Settings().TrialsOnFinish
            if OnFinish == "Leave" then
                Action = 3
            elseif OnFinish == "Next" and Won then
                Action = Read(State.canNext) == true and 2 or 3
            end
        elseif Finish == "Leave" then
            Action = 3
        elseif FarmingMaterials() and Settings().MaterialFarmKey then
            -- ฟาร์มของ evolve: เล่นซ้ำด่านเดิม / ของครบหรือด่านที่คุ้มสุดเปลี่ยน = ออกไป lobby (evolve + เลือกด่านใหม่)
            if not Match.FarmChecked then
                local Plan = Evo.Plan()
                Match.FarmLeave = not (Plan and Plan.Key == Settings().MaterialFarmKey)
                Match.FarmChecked = true
            end
            if Match.FarmLeave then Action = 3 end
        elseif Finish == "Next" and Read(State.canNext) == true then
            Action = 2
        end
        local Mine = nil
        pcall(function() Mine = Read(State.resultVotes:get(Key)) end)

        if Mine == Action then
            SetStatus(({ "Retrying", "Next chapter", "Leaving" })[Action] .. " (" .. tostring(Status) .. ")")
        elseif os.clock() - Match.EndedAt > 3 then
            Match.EndedAt = os.clock()
            Packets.endAction:fire(Action)
            SetStatus(({ "Retrying", "Next chapter", "Leaving" })[Action] .. " (" .. tostring(Status) .. ")")
        end
    elseif Status == "active" then
        Match.FarmChecked = nil -- รอบใหม่ (Retry) = เช็คแผนใหม่ตอนจบ
        Match.Recorded = nil
        SetStatus("In match")
    end
end

function Join.Stop()
    Join.Thread = nil
end

-- โมดูลของเกมหาไม่เจอ / require ไม่ผ่าน (เจอบางเซิร์ฟ - ผู้ใช้ 2026-10-12) = เข้า lobby เซิร์ฟใหม่ (Auto Executor รัน hub ต่อเอง)
-- กันวนไม่จบ: ไม่เกิน 3 ครั้งใน 10 นาที (จำในไฟล์ - getgenv ไม่ติดข้ามเซิร์ฟทุก executor)
function Join.Rejoin(Reason)
    local File = FolderSettings .. "/Rejoin_" .. LocalPlayer.Name .. ".json"
    local Ok, Data = pcall(function() return HttpService:JSONDecode(readfile(File)) end)
    Data = Ok and type(Data) == "table" and Data or { }
    if os.time() - (tonumber(Data.At) or 0) > 600 then Data = { Count = 0, At = os.time() } end
    if (tonumber(Data.Count) or 0) >= 3 then
        SetStatus("Error: " .. Reason)
        return
    end
    Data.Count = (tonumber(Data.Count) or 0) + 1
    pcall(writefile, File, HttpService:JSONEncode(Data))
    SetStatus("Rejoining - " .. Reason)
    task.wait(2)
    pcall(function() game:GetService("TeleportService"):Teleport(114574503491412, LocalPlayer) end)
end

function Join.Start()
    if not ResolveScale() then pcall(function() Players.LocalPlayer:Kick("\226\128\139") end) return end
    if Join.Thread then return end

    local Token = { }
    Join.Thread = Token

    task.spawn(function()
        if not ResolveScale() then return end
        if IsLobby then
            local Packets = SafeRequire(ReplicatedStorage, "lobby", "packets")
            local RoomStore = SafeRequire(ReplicatedStorage, "lobby", "stores", "ququeRoomStore")
            if not (Packets and RoomStore) then
                Join.Rejoin("lobby packets not found")
                Join.Thread = nil
                return
            end

            if not Join.Hooked then
                Join.Hooked = true
                table.insert(Join.Hooks, Packets.toggleQuqueWindow:on(function(Data)
                    if getgenv().ValkyrieSession ~= SessionToken then return end
                    if type(Data) == "table" and Data.open then Join.RoomNumber = Data.roomNumber end
                end))
                table.insert(Join.Hooks, Packets.updateClientQuqueStatus:on(function(Status)
                    if getgenv().ValkyrieSession ~= SessionToken then return end
                    Join.ClientStatus = tostring(Status)
                    Join.StatusAt = os.clock()
                end))
            end

            while Join.Thread == Token and getgenv().ValkyrieSession == SessionToken and JoinWanted() do
                local Ok, Err = pcall(LobbyStep, Packets, RoomStore.namespace)
                if not Ok then SetStatus("Error: " .. tostring(Err)) end
                task.wait(1)
            end
        elseif IsMatch then
            local Packets = SafeRequire(ReplicatedStorage, "game", "packets", "runPackets")
            local Run = SafeRequire(ReplicatedStorage, "game", "stores", "runStore")
            if not (Packets and Run and Run.store) then
                Join.Rejoin("match packets not found")
                Join.Thread = nil
                return
            end

            while Join.Thread == Token and getgenv().ValkyrieSession == SessionToken and JoinWanted() do
                local Ok, Err = pcall(MatchStep, Packets, Run.store.state)
                if not Ok then SetStatus("Error: " .. tostring(Err)) end
                task.wait(0.5)
            end
        end

        if not (IsLobby or IsMatch) and GamePlaces[game.PlaceId] then
            Join.Rejoin("game modules not found")
        end

        if Join.Thread == Token then Join.Thread = nil end
    end)
end

function Join.Refresh()
    if JoinWanted() then
        Join.Start()
    else
        Join.Stop()
        SetStatus("Idle")
    end
end

---- ============ Auto Battle (ในแมตช์) ============ ----
--
-- วัดสดผ่าน dex 2026-10-06 (Story / Hxh, ตัว nagumo):
--   ตี/สกิล/สลับตัว = ฟังก์ชันของ characterController ของเกมเอง (require ได้ตัวเดียวกับที่เกมใช้):
--     setTouchHeld("Attack", true/false) = กดค้าง M1 (ลูปของเกมยิง performM1 ตาม cooldown เอง)
--     performSkill(1-3) = สกิล / performSkill(4) = Ultimate (ต้อง ultProgress 100 และไม่มี attr UltimateLocked)
--       -> คืน false ถ้ายังไม่พร้อม (cooldown "<ตัวละคร>.skill<n>", กำลังใช้สกิลอื่น) ยิงซ้ำได้ปลอดภัย
--     performSwitch() = สลับตัว (server เลือกตัวถัดไปเอง - เราเลือกตัวไม่ได้) cooldown "characterSwitch"
--   ศัตรู = enemyStore.store.state (map id -> health/maxHealth/name/position) / โมเดล workspace.enemies.<id>
--     บอส = global.constants.enemies.enemiesByName[getBaseName(name)].boss
--   ตีโดนทุกระยะที่ลอง (ข้างตัว 3-8, บน 6-10, ใต้ 5-8 studs) = server ไม่เช็คระยะ M1 เข้ม
--   ดรอป = dropStore (kind "cash" / "health") - เกมดูดเข้าตัวเองเมื่อ HumanoidRootPart อยู่ใน 12 studs
--     ของจุดที่ดรอปตก แล้วยิง recoverDrop(id) ให้เอง -> เก็บดรอป = พาตัวไปใกล้ ๆ ก็พอ
--   ไปพื้นที่ถัดไป (area 1-5): เคลียร์ศัตรูหมดแล้วต้องทุบกำแพง workspace.World.Map.Border<n> (attr RubbleHealth /
--     RubbleMaxHealth, ผนังจริง = ลูก "Blocker") ด้วย M1/สกิล -> RubbleHealth 0 = area ขึ้นทันที (วัดแล้ว 213 hp)
--     เดิน/วาร์ปข้ามไปก่อนทุบ = โดนดึงกลับ
--   ทุบแล้วศัตรูพื้นที่ใหม่ยังไม่เกิด จนกว่าตัวเราจะเข้าไปในกล่องโซน workspace.World.Areas.<area> (Part ล่องหน)
--     แล้วศัตรูเกิดทันที (วัดแล้ว area 3: 0 -> 8 ตัวใน 1 วิ) / World.Spawns.<n> บางจุดอยู่ในโซนพื้นที่ก่อนหน้า ใช้ไม่ได้

local Battle = { Angle = 0, Target = nil, Override = nil, LastSwitch = 0, HealFired = { }, Seen = { } }
local NeedHeal, SendDrop -- ประกาศก่อน (ตัวเต็มอยู่ข้างล่างคู่กับตัวแทน recoverDrop)

local function Alive()
    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local Hrp = Character and Character:FindFirstChild("HumanoidRootPart")
    if Humanoid and Hrp and Humanoid.Health > 0 then return Humanoid, Hrp end
end

local function BattleOn()
    local C = Settings()
    return C.AutoAttack or C.AutoSkill or C.AutoTagTeam or C.AutoUltimate or C.AutoCollectDrops
end

-- โหลดโมดูลเกม (เรียกในเธรดลูปเท่านั้น - require ทำ capability ของเธรดตก แตะ UI ไม่ได้)
local function LoadBattle()
    if Battle.Loaded then return true end
    local Scripts = LocalPlayer:WaitForChild("PlayerScripts", 10)
    Battle.Controller = Scripts and SafeRequire(Scripts, "game", "controllers", "characterController")
    Battle.Input = Scripts and SafeRequire(Scripts, "global", "controllers", "inputController")
    Battle.Enemies = SafeRequire(ReplicatedStorage, "game", "stores", "enemyStore")
    Battle.Drops = SafeRequire(ReplicatedStorage, "game", "stores", "dropStore")
    Battle.Rewards = SafeRequire(ReplicatedStorage, "game", "packets", "rewardPackets")
    Battle.Run = SafeRequire(ReplicatedStorage, "game", "stores", "runStore")
    Battle.Players = SafeRequire(ReplicatedStorage, "game", "stores", "playerNamespace")
    Battle.EnemyInfo = SafeRequire(ReplicatedStorage, "global", "constants", "enemies")
    Battle.CharacterInfo = SafeRequire(ReplicatedStorage, "global", "constants", "characters")
    Battle.Account = SafeRequire(ReplicatedStorage, "global", "stores", "accountNamespace")
    Battle.Sukuna = SafeRequire(ReplicatedStorage, "game", "packets", "sukunaPackets")
    Battle.CharPackets = SafeRequire(ReplicatedStorage, "game", "packets", "characterPackets")
    pcall(function()
        local Config = SafeRequire(ReplicatedStorage, "assets", "config", "synergyConfig")
        if Config and type(Config.TagIn) == "table" then Battle.TagIn = Config.TagIn end
    end)
    -- สถานะท่าสกิลของ controller (upvalue "skill" ของ performSwitch: till = เวลาท่าจบ, pending = รอยิง)
    pcall(function()
        for _, Value in pairs(debug.getupvalues(Battle.Controller.performSwitch)) do
            if type(Value) == "table" and rawget(Value, "till") and rawget(Value, "pending") then Battle.SkillState = Value end
        end
    end)
    Battle.Loaded = Battle.Controller and Battle.Enemies and Battle.Drops and Battle.Run and Battle.Players and true
    return Battle.Loaded
end

local function EnemyPosition(Id, Enemy)
    local Model = workspace:FindFirstChild("enemies") and workspace.enemies:FindFirstChild(tostring(Id))
    local Root = Model and (Model.PrimaryPart or Model:FindFirstChild("HumanoidRootPart"))
    if Root then return Root.Position end
    return Read(Enemy.position)
end

local function IsBoss(Enemy)
    local Info = Battle.EnemyInfo
    if not Info then return false end
    local Name = Read(Enemy.name) or ""
    local Ok, Base = pcall(Info.getBaseName, Name)
    local Data = Info.enemiesByName[(Ok and Base) or Name] or Info.enemiesByName[Name]
    return Data and Data.boss == true or false
end

-- ลูกค้า 2026-10-08: วาร์ปไปตีบอสทั้งที่มอนยังเหลือ -> มีมอนธรรมดาเหลือ = ข้ามบอสไว้ก่อน (บอสตีทีหลังสุด)
-- Raid ไม่ใช้กฎนี้: Shadow Gate มี RaidPriority คุมเอง / BathTub ทุกตัวเป็นบอส
function Battle.SkipBosses(All)
    if tostring(workspace:GetAttribute("Mode") or ""):find("raid") then return false end
    for _, Enemy in pairs(All) do
        if (Read(Enemy.health) or 0) > 0 and not IsBoss(Enemy) then return true end
    end
    return false
end

-- ศัตรูที่ยังมีเลือดทั้งหมด { Id, Enemy, Position, Health } (ยังมีมอนธรรมดา = ไม่รวมบอส)
local function AliveEnemies(All)
    local List = { }
    local SkipBosses = Battle.SkipBosses(All)
    for Id, Enemy in pairs(All) do
        local Health = Read(Enemy.health) or 0
        if Health > 0 and not (SkipBosses and IsBoss(Enemy)) then
            local Position = EnemyPosition(Id, Enemy)
            if Position then
                table.insert(List, { Id = Id, Enemy = Enemy, Position = Position, Health = Health })
            end
        end
    end
    return List
end

-- Shadow Gate (Mode sololevelingraid) - workspace attribute บอกสถานการณ์ (วัดสด 2026-10-08):
--   RaidOathCount > 0 = "Break the Oath" ฆ่า soloOathKnight ให้ทันเวลา (Igris ไม่โดนดาเมจระหว่างนั้น) ไม่ทัน = Crimson Execution + Rank ตก
--   RaidQuestState active + RaidQuestGoal = เควส System (ทำทัน = buff): "Defeat 2 Blood-Red Knights" = soloKnight /
--   "Deal 8% of Igris's health" = soloIgris / อื่น ๆ (Slaughter, Take no damage) = ตีตามปกติ
-- คืนชุดชื่อมอนที่ต้องตีก่อน (nil = ไม่มี)
function Battle.RaidPriority()
    if workspace:GetAttribute("Mode") ~= "sololevelingraid" then return nil end
    if (tonumber(workspace:GetAttribute("RaidOathCount")) or 0) > 0 then
        return { soloOathKnight = true }
    end
    if workspace:GetAttribute("RaidQuestState") == "active" then
        local Goal = tostring(workspace:GetAttribute("RaidQuestGoal") or ""):lower()
        if Goal:find("blood%-red knight") then return { soloKnight = true } end
        if Goal:find("igris") and Goal:find("health") then return { soloIgris = true, soloIgrisShadow = true } end
    end
    return nil
end

function Battle.BaseName(Enemy)
    local Name = Read(Enemy.name) or ""
    local Info = Battle.EnemyInfo
    local Ok, Base = pcall(function() return Info.getBaseName(Name) end)
    return Ok and Base or Name
end

-- ศัตรูที่ตีได้: Shadow Gate มี soloIgris นั่งบัลลังก์ตั้งแต่ก่อนเริ่ม (เวฟ 0-2 เลือดเต็มไม่ลด - วัดสด 2026-10-09)
-- เดิม hub ไปยืนตี Igris (ใกล้สุด 18 studs) ระหว่างที่มอนเวฟ 1 ยังเดินมาจาก 400 studs = เสียเวลาเปล่า
-- -> ข้าม Igris / Shadow Igris จนถึงเวฟสุดท้าย (wave >= waveCount) / หลบท่า (ScanDangers) ยังเห็นทุกตัว
-- เวฟสุดท้ายก็ตีลูกน้อง (soldier / knight / oath knight) ให้หมดก่อนเสมอ แล้วค่อยตี Igris (ผู้ใช้ 2026-10-09)
function Battle.Targets()
    local All = Battle.Enemies.store.state:getAll()
    if workspace:GetAttribute("Mode") ~= "sololevelingraid" then return All end
    local State = Battle.Run and Battle.Run.store and Battle.Run.store.state
    local Wave, Waves = tonumber(State and Read(State.wave)) or 0, tonumber(State and Read(State.waveCount)) or 0
    local Out, Minions = { }, false
    for Id, Enemy in pairs(All) do
        local Name = Battle.BaseName(Enemy)
        if Name ~= "soloIgris" and Name ~= "soloIgrisShadow" then
            Out[Id] = Enemy
            if (Read(Enemy.health) or 0) > 0 then Minions = true end
        end
    end
    if Minions or Waves == 0 or Wave < Waves then return Out end
    return All
end

local function PickTarget(Hrp)
    local All = Battle.Targets()

    -- เป้าบังคับของ Raid: ตัวที่ใกล้สุดในชุดที่ต้องตี
    local Want = Battle.RaidPriority()
    if Want then
        -- ยึดตัวเดิมจนตาย (เดิมเลือกตัวใกล้สุดทุกรอบ = สลับไปมาระหว่าง 2 ตัวทุก 0.5 วิ ตัวโยกไม่หยุด)
        local Current = Battle.Target and All[Battle.Target]
        if Current and (Read(Current.health) or 0) > 0 and Want[Battle.BaseName(Current)] then
            return Battle.Target, Current
        end
        local BestId, Best, BestDistance = nil, nil, math.huge
        for Id, Enemy in pairs(All) do
            if (Read(Enemy.health) or 0) > 0 and Want[Battle.BaseName(Enemy)] then
                local Position = EnemyPosition(Id, Enemy)
                local Distance = Position and (Position - Hrp.Position).Magnitude or math.huge
                if Distance < BestDistance then BestId, Best, BestDistance = Id, Enemy, Distance end
            end
        end
        if BestId then
            Battle.Target, Battle.Rescored = BestId, os.clock()
            return BestId, Best
        end
    end

    -- ตีตัวที่ใกล้สุดเลย (ผู้ใช้ 2026-10-11: ไม่มี toggle รวมมอนแล้ว - ตีตัวที่เกิดก่อนระหว่างรอเกิดครบ
    -- สกิลรอจนเกิดครบ ดู BattleStep)
    local List = AliveEnemies(All)
    local Near, NearDistance = nil, math.huge
    for _, Entry in ipairs(List) do
        local Distance = (Entry.Position - Hrp.Position).Magnitude
        if Distance < NearDistance then Near, NearDistance = Entry, Distance end
    end
    if not Near then
        Battle.Target = nil
        return nil, nil
    end
    local Current = Battle.Target and All[Battle.Target]
    if Current and (Read(Current.health) or 0) > 0 and not (IsBoss(Current) and Battle.SkipBosses(All)) and Near.Id ~= Battle.Target then
        local Here = EnemyPosition(Battle.Target, Current)
        local Far = Here and (Here - Hrp.Position).Magnitude or math.huge
        -- ผู้ใช้ 2026-10-11 (Trials ต้องได้ S = ห้องละไม่เกิน 90 วิ): มอนเกิดกระจาย 50-150 studs เวลาหมดไปกับการบิน
        -- เดิมย้ายเมื่อใกล้กว่าครึ่งหนึ่ง + รอ 1 วิ = บินผ่านตัวที่ใกล้ไปหาตัวแรกที่เกิดไกล ๆ -> กำลังตีอยู่ (15 studs) = ตีให้ตาย /
        -- ไม่งั้นมีตัวที่ใกล้กว่า 10 studs ขึ้นไป = เปลี่ยนเลย
        if os.clock() - (Battle.Rescored or 0) < 0.3 or Far <= 15 or NearDistance > Far - 10 then return Battle.Target, Current end
    end
    if Near.Id ~= Battle.Target then Battle.Target, Battle.Rescored = Near.Id, os.clock() end
    return Near.Id, Near.Enemy
end

-- ดรอปที่ใกล้สุดตามชนิด ("cash" / "health")
local function NearestDrop(Hrp, Kind)
    local Best, BestDistance = nil, math.huge
    for _, Drop in pairs(Battle.Drops.store.state:getAll()) do
        if Read(Drop.kind) == Kind then
            local Position = Read(Drop.position)
            local Distance = Position and (Position - Hrp.Position).Magnitude or math.huge
            if Distance < BestDistance then Best, BestDistance = Position, Distance end
        end
    end
    return Best
end

-- กำแพงพื้นที่ที่ยังทุบไม่แตก -> จุดยืนฝั่งเรา (ห่างผนัง 5 studs ระดับพื้น) + จุดหันหน้า
local function FindRubble(Hrp)
    local Map = workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Map")
    if not Map then return end
    for _, Child in ipairs(Map:GetChildren()) do
        if (tonumber(Child:GetAttribute("RubbleHealth")) or 0) > 0 then
            local Wall = Child:FindFirstChild("Blocker")
            if not (Wall and Wall:IsA("BasePart")) then
                local Ok, Box, Size = pcall(Child.GetBoundingBox, Child)
                if not Ok then return end
                Wall = { CFrame = Box, Size = Size, Position = Box.Position }
            end
            -- แกนที่บางสุดของผนัง = ทิศที่ต้องยืนหน้าผนัง / เลือกฝั่งที่ตัวเราอยู่
            local Local = Wall.CFrame:PointToObjectSpace(Hrp.Position)
            local Size = Wall.Size
            local Offset
            if Size.X <= Size.Z then
                Offset = Vector3.new((Local.X >= 0 and 1 or -1) * (Size.X / 2 + 5), 0, 0)
            else
                Offset = Vector3.new(0, 0, (Local.Z >= 0 and 1 or -1) * (Size.Z / 2 + 5))
            end
            local Stand = Wall.CFrame:PointToWorldSpace(Offset)

            -- พื้นจริงใต้จุดยืน (ยิงลงจากบน ข้ามกองหิน/ตัวเรา/ศัตรู) - ขอบล่างผนังใช้ไม่ได้:
            -- Border3 ผนังจมลึกกว่าพื้น 8.5 studs -> ยืนใต้พื้นแล้ว M1 ไม่โดนกำแพง (วัดแล้ว ค้าง 63 hp)
            local Params = RaycastParams.new()
            Params.FilterType = Enum.RaycastFilterType.Exclude
            Params.FilterDescendantsInstances = { Child, LocalPlayer.Character, workspace:FindFirstChild("enemies"), Battle.Footer }
            local Hit = workspace:Raycast(Stand + Vector3.new(0, 60, 0), Vector3.new(0, -160, 0), Params)
            local Floor = (Hit and Hit.Position.Y or (Wall.Position.Y - Size.Y / 2)) + 3
            return Vector3.new(Stand.X, Floor, Stand.Z), Vector3.new(Wall.Position.X, Floor, Wall.Position.Z)
        end
    end
end

-- กล่องโซนของพื้นที่ปัจจุบัน -> จุดกลางโซนระดับพื้น ถ้าตัวยังไม่อยู่ข้างใน (อยู่แล้ว = nil)
-- Raid (Spirit's Bathtub) มี Areas ลูกเดียวชื่อ "1" ที่ย้ายตามชั้น -> ไม่เจอชื่อ area = ใช้ลูกที่มี
local function ZonePoint(Hrp)
    local Area = tostring(Read(Battle.Run.store.state.area) or "")
    local World = workspace:FindFirstChild("World")
    local Areas = World and World:FindFirstChild("Areas")
    local Zone = Areas and (Areas:FindFirstChild(Area) or Areas:FindFirstChildWhichIsA("BasePart"))
    if not (Zone and Zone:IsA("BasePart")) then return nil end
    local Local = Zone.CFrame:PointToObjectSpace(Hrp.Position)
    local Half = Zone.Size / 2
    if math.abs(Local.X) < Half.X - 4 and math.abs(Local.Z) < Half.Z - 4 then return nil end
    local Spawn = World:FindFirstChild("Spawns") and (World.Spawns:FindFirstChild(Area) or World.Spawns:FindFirstChild("Start"))
    local Floor = (Spawn and Spawn:IsA("BasePart") and math.abs(Spawn.Position.Y - Zone.Position.Y) < Half.Y and Spawn.Position.Y or Hrp.Position.Y - 3) + 3
    return Vector3.new(Zone.Position.X, Floor, Zone.Position.Z)
end

-- Trials: มอนเกิดที่ World.Markers.EnemySpawns (Gate1-13 วงรอบ ~90 studs) แบบสุ่ม -> ระหว่างรอเวฟถัดไป
-- ยืนกลางวง (ห่างจุดเกิดทุกจุดพอ ๆ กัน) แทนจุดที่ตีตัวสุดท้าย (บางทีขอบวง = ตัวต่อไปเกิดห่าง 150+)
function Battle.ArenaCenter()
    if workspace:GetAttribute("Mode") ~= "trials" then return nil end
    local World = workspace:FindFirstChild("World")
    local Spawns = World and World:FindFirstChild("Markers") and World.Markers:FindFirstChild("EnemySpawns")
    local Sum, Count = Vector3.zero, 0
    for _, Gate in ipairs(Spawns and Spawns:GetChildren() or { }) do
        if Gate:IsA("BasePart") then Sum, Count = Sum + Gate.Position, Count + 1 end
    end
    return Count > 0 and Sum / Count + Vector3.new(0, 4, 0) or nil
end

-- ลิฟต์ไปชั้นถัดไปของ Raid: workspace.World.Markers.Exit.ExitPrompt ("Enter Elevator", ระยะ 14, กดทันที)
-- วัดสด 2026-10-06: เคลียร์ครบทุก wave ของชั้นแล้วไม่มีกำแพง/ไม่ไปต่อเอง ต้องกดลิฟต์ -> วาร์ปไปชั้นถัดไป area +1
local function ElevatorPrompt()
    local World = workspace:FindFirstChild("World")
    local Markers = World and World:FindFirstChild("Markers")
    -- Trials (2026-10-11): ชั้นเคลียร์แล้วคันโยก Markers.Lift ("Ascend", ระยะ 14) เปิด / ไม่ดึง = รอ 15 วิแล้วขึ้นเอง
    local Exit = Markers and (Markers:FindFirstChild("Exit") or Markers:FindFirstChild("Lift"))
    local Prompt = Exit and Exit:FindFirstChildWhichIsA("ProximityPrompt")
    return Prompt and Prompt.Enabled and Prompt or nil
end

local function SkillReady(Store, Character, Slot)
    -- อัลติ = หลอดต้องเต็ม (ultProgress 100) + ไม่ติด attr UltimateLocked ด้วย - เดิมเช็คแค่คูลดาวน์ = หลอดยังไม่เต็มก็นับว่าพร้อม
    -- -> ตั้งท่าเล็งเปล่า ๆ แล้วพักเล็ง 2 วิ (สกิลช้า) + อัลติโดนพัก NoCast 3 วิ พอเต็มจริงเลยไม่ออกทันที
    if Slot == 4 then
        if LocalPlayer:GetAttribute("UltimateLocked") == true then return false end
        local Ok, Progress = pcall(function() return tonumber(Read(Store.state.ultProgress)) end)
        if Ok and Progress and Progress < 100 then return false end
    end
    local Cooldown = Store.state.cooldowns:get(Battle.Players.skillCooldownKey(Character, Slot))
    return not (Cooldown and workspace:GetServerTimeNow() < (Read(Cooldown) or 0))
end

-- สกิลช่องนี้เลือกไว้ใน Skills (Auto Battle) ไหม - ช่องที่ไม่เลือก = ไม่กด และไม่นับตอนสลับตัว
-- เทียบที่เลขช่อง ("Skill 2" / "สกิล 2" ที่ Roblox แปลแล้วเซฟไว้ = ช่อง 2 เหมือนกัน)
function Battle.SkillOn(Slot)
    local List = Settings().SkillSlots
    if type(List) ~= "table" then return true end
    for _, Name in pairs(List) do
        if tonumber(tostring(Name):match("%d+")) == Slot then return true end
    end
    return false
end

-- สกิลโบนัส (constants.characters: skills[n].bonus = ช่องที่กดซ้ำแล้วได้สกิลซ่อน): หลังใช้สกิลนั้น player attr
-- BonusUntil (server time) / BonusSlot = กดช่องเดิมอีกทีในช่วงนี้ performSkill ส่งสกิลโบนัสแทน
-- ผู้ใช้ 2026-10-12: อัลติ Sung (Monarch's Domain) กดซ้ำ = "Arise: Kaisel" (มังกร ค้างท่า 11.4 วิ) ไม่เอา -> ไม่กดช่องนั้นในช่วงโบนัส
Battle.NoBonus = { sung_jinwoo = { [4] = true } }

function Battle.BonusBlocked(Character, Slot)
    local Skip = Battle.NoBonus[Character]
    if not (Skip and Skip[Slot]) then return false end
    local Until = tonumber(LocalPlayer:GetAttribute("BonusUntil")) or 0
    return workspace:GetServerTimeNow() < Until and (tonumber(LocalPlayer:GetAttribute("BonusSlot")) or Slot) == Slot
end

-- ตัวอื่นในทีม (account.EquippedCharacterSlots = gameSlot -> ช่องตัวละคร) ไม่รวมตัวที่เล่นอยู่
local function TeamMates(Current)
    local List = { }
    pcall(function()
        local Data = Battle.Account.getLocalPlayerAccount():toTable()
        for _, Slot in pairs(Data.EquippedCharacterSlots or { }) do
            local Entry = tonumber(Slot) and Data.UnlockedCharacters["Slot" .. Slot]
            local Name = Entry and Entry.Unlocked and Entry.Character
            if type(Name) == "string" and Name ~= "" and Name ~= Current then table.insert(List, Name) end
        end
    end)
    return List
end

-- Tag-In (synergyConfig.TagIn): สลับตัวเข้ามา = ดาเมจ +20% 4 วิ (player attr TagInUntil) / ได้อีกครั้งหลัง 10 วิ
-- วัดสด: สลับห่าง 8 วิ = ไม่ได้ buff, ห่าง >= 10 วิ = TagInUntil +4 / ปุ่มสลับ (characterSwitch) cooldown ~3 วิ
-- คืน (buff ทำงานอยู่ไหม, อีกกี่วิ Tag-In ถัดไปพร้อม)
local function TagInState()
    local Config = Battle.TagIn or { Duration = 4, Cooldown = 10 }
    local Until = tonumber(LocalPlayer:GetAttribute("TagInUntil")) or 0
    local Now = workspace:GetServerTimeNow()
    return Now < Until, Until - (Config.Duration or 4) + (Config.Cooldown or 10) - Now
end

-- ท่าสกิลเล่นจบแล้ว (performSwitch ของเกมเงียบถ้าท่ายังไม่จบ / ยังรอยิงสกิล)
-- วัดสด 2026-10-15 (decompile performSwitch): เกมสลับได้เมื่อ stuns ว่าง + ไม่ block + ไม่ dash + ไม่เล็ง + till ผ่าน
-- stuns มี "m1" (ฟัน M1 ช้าลง ค้าง ~1 วิหลังฟันครั้งสุดท้าย) / "default" (ท่าสกิล) - เดิมเช็คแค่ till/pending
-- = ยิง performSwitch ตอน stun ยังอยู่ เกมทิ้งเงียบ สลับไม่ออก
local function SkillIdle()
    local Ok, Idle = pcall(function()
        local Store = Battle.Players and Battle.Players.getLocalPlayerStore()
        if Store and (next(Store.state.stuns:getAll()) ~= nil or Store.state.blocking:get()) then return false end
        local State = Battle.SkillState
        if not State then return true end
        return not State.pending:get() and State.till:get() <= workspace:GetServerTimeNow()
    end)
    return not Ok or Idle
end

-- กลางกลุ่มมอนรอบเป้า (ทุกตัวที่ยังไม่ตายใน 14 studs ของเป้า)
local function ClusterCenter(Around)
    if not Around then return nil end
    local Sum, Count = Vector3.zero, 0
    for _, Entry in ipairs(AliveEnemies(Battle.Targets())) do
        if (Entry.Position - Around).Magnitude <= 14 then
            Sum, Count = Sum + Entry.Position, Count + 1
        end
    end
    return Count > 0 and Sum / Count or Around
end

-- ==== หลบท่าศัตรู (ผู้ใช้ 2026-10-06: บอส Raid ท่าเยอะ ต้องหลบ + ตีจากที่สูงกว่า) ====
-- enemyStore ของศัตรูแต่ละตัว: attackIndex / attackStartedAt (server time) / attackCFrame / attackTarget
-- ท่า = constants.enemies.enemiesByName[ชื่อ].attacks[attackIndex] { offset, size (กล่อง), hitTime, duration, lunge, targeted }
-- กล่องวางแบบเดียวกับ indicator ใน enemyController ของเกม: targeted = ที่ attackTarget / lunge = attackTarget * หมุนตาม
-- attackCFrame * offset / ปกติ = attackCFrame * offset (attackCFrame อยู่ระดับเท้า)
-- ไม่รู้ว่า server วางกล่องกลางที่จุดหรือวางบนพื้น -> เผื่อสูงสุด = จุด + size.Y (บอส No-Face ท่า 3 = 20.8)
function Battle.AttackBox(Enemy)
    local Info = Battle.EnemyInfo
    local Started, Index = tonumber(Read(Enemy.attackStartedAt)), tonumber(Read(Enemy.attackIndex))
    if not (Info and Started and Index) then return nil end
    local Name = Read(Enemy.name) or ""
    local Ok, Base = pcall(Info.getBaseName, Name)
    local Data = Info.enemiesByName[(Ok and Base) or Name] or Info.enemiesByName[Name]
    local Attack = Data and type(Data.attacks) == "table" and Data.attacks[Index]
    if not (Attack and typeof(Attack.size) == "Vector3") then return nil end
    local Elapsed = workspace:GetServerTimeNow() - Started
    if Elapsed < 0 or Elapsed > (tonumber(Attack.duration) or (tonumber(Attack.hitTime) or 1) + 0.5) then return nil end
    local Origin = Read(Enemy.attackCFrame)
    if typeof(Origin) ~= "CFrame" then return nil end
    local Offset = typeof(Attack.offset) == "CFrame" and Attack.offset or CFrame.identity
    local Target = Read(Enemy.attackTarget)
    local Box
    if Attack.targeted and typeof(Target) == "Vector3" then
        Box = CFrame.new(Target)
    elseif Attack.lunge and typeof(Target) == "Vector3" then
        Box = CFrame.new(Target) * Origin.Rotation * Offset
    else
        Box = Origin * Offset
    end
    return Box, Attack.size
end

-- กล่องท่าที่กำลังเล่นอยู่ทั้งหมด (BattleStep ทุก 0.1 วิ) -> MoveStep ยกตัวพ้นกล่อง
function Battle.ScanDangers(All)
    local List = { }
    for _, Enemy in pairs(All) do
        if (Read(Enemy.health) or 0) > 0 and IsBoss(Enemy) then
            local Ok, Box, Size = pcall(Battle.AttackBox, Enemy)
            if Ok and Box then table.insert(List, { Box = Box, Size = Size }) end
        end
    end
    return List
end

-- จุดยืนอยู่ในกล่องท่า (เผื่อขอบ 3 studs) = ยกขึ้นเหนือกล่อง 5 studs (ตีต่อได้เมื่อท่าจบ)
function Battle.DodgeGoal(Goal)
    for _, Danger in ipairs(Battle.Dangers or { }) do
        local Local = Danger.Box:PointToObjectSpace(Goal)
        local Size = Danger.Size
        if math.abs(Local.X) < Size.X / 2 + 3 and math.abs(Local.Z) < Size.Z / 2 + 3
            and Local.Y > -Size.Y / 2 - 3 and Local.Y < Size.Y + 3 then
            Goal = Vector3.new(Goal.X, math.max(Goal.Y, Danger.Box.Position.Y + Size.Y + 5), Goal.Z)
        end
    end
    return Goal
end

-- ตีบอสจากที่สูง: เท้าบอส + กล่องท่าที่สูงสุด + 5 แต่ไม่เกิน +20 (ระยะ M1) / ไม่มีข้อมูลท่า = nil (ใช้ Height Offset)
function Battle.BossSafeY(Enemy)
    local Info = Battle.EnemyInfo
    local Feet = Read(Enemy.position)
    if not (Info and typeof(Feet) == "Vector3") then return nil end
    local Name = Read(Enemy.name) or ""
    local Ok, Base = pcall(Info.getBaseName, Name)
    local Data = Info.enemiesByName[(Ok and Base) or Name] or Info.enemiesByName[Name]
    local Top = nil
    for _, Attack in pairs(Data and type(Data.attacks) == "table" and Data.attacks or { }) do
        if typeof(Attack.size) == "Vector3" then Top = math.max(Top or 0, Attack.size.Y) end
    end
    -- สูงเกินไป M1 ไม่ถึง (วัดสด: เท้า +25.8 = ตีไม่โดนเลย / +22.7 ยังโดน) -> สูงสุด +20
    return Top and Feet.Y + math.min(Top + 5, 20) or nil
end

-- ตำแหน่งที่ยืนรอบเป้า: Above / Below = ลอยบน/ใต้เป้าตาม Height Offset, Orbit = วนเป็นวงเหนือหัวเป้า (สูง Height Offset)
local function StandPoint(TargetPosition, Dt)
    local C = Settings()
    local Height = tonumber(C.PositionHeight) or 6
    if C.AttackPosition == "Below" then
        return TargetPosition - Vector3.new(0, Height, 0)
    elseif C.AttackPosition == "Orbit" then
        local Radius = tonumber(C.OrbitRadius) or 6
        Battle.Angle = (Battle.Angle + Dt * (tonumber(C.OrbitSpeed) or 5) * 0.6) % (math.pi * 2)
        return TargetPosition + Vector3.new(math.cos(Battle.Angle) * Radius, Height, math.sin(Battle.Angle) * Radius)
    end
    return TargetPosition + Vector3.new(0, Height, 0)
end

-- ขยับตัวทุกเฟรม (Heartbeat): ไปเก็บของ (Override) ก่อน ไม่งั้นยืนที่จุดรอบเป้า หันหน้าเข้าเป้าแนวราบ
-- ฐานยืนใต้เท้า (ผู้ใช้ 2026-10-06): Part ล่องหน Anchored ตามตัวทุกเฟรม = Humanoid เจอพื้น (FloorMaterial)
-- ไม่ตกเป็นสถานะ Freefall ตอนลอยฟาร์ม / ตัวละครทะลุได้ (noclip) แต่ raycast หาพื้นของ Humanoid ยังเจอฐาน
local function PlaceFooter(Hrp, Humanoid)
    -- สกิลที่พาตัววิ่ง (Sung Jinwoo สกิล 2 Shadow Rush = rideSteered: AlignPosition "SungJinwooRide") ยิง ray หาพื้นทุกเฟรม
    -- แล้วตั้งความสูง = พื้น + ระยะตอนเริ่ม + ท่ากระโดด (สูงสุด +7) -> ray เจอฐานนี้ที่ตามตัวเรา = พื้นสูงขึ้นตามตัวทุกเฟรม
    -- ท่ากระโดดบวกซ้อนไปเรื่อย ๆ ลอยขึ้นฟ้า (ผู้ใช้ 2026-10-12) -> ระหว่างสกิลขยับตัวด้วย constraint = เอาฐานออก
    for _, Child in ipairs(Hrp:GetChildren()) do
        if Child:IsA("AlignPosition") or Child:IsA("LinearVelocity") or Child:IsA("BodyVelocity") or Child:IsA("BodyPosition") then
            if Battle.Footer then Battle.Footer.Parent = nil end
            return
        end
    end
    local Footer = Battle.Footer
    if not (Footer and Footer.Parent) then
        Footer = Instance.new("Part")
        Footer.Name = "\0"
        Footer.Size = Vector3.new(6, 1, 6)
        Footer.Anchored = true
        Footer.CanCollide = true
        Footer.CanTouch = false
        Footer.CanQuery = true
        Footer.Transparency = 1
        Footer.Parent = workspace
        Battle.Footer = Footer
    end
    -- R6 = HipHeight 0 ขายาว 2 / R15 = HipHeight คือระยะสะโพกถึงพื้น
    local Legs = (Humanoid and Humanoid.RigType == Enum.HumanoidRigType.R6) and 2 or (Humanoid and Humanoid.HipHeight or 2)
    local Drop = Hrp.Size.Y / 2 + Legs + Footer.Size.Y / 2
    Footer.CFrame = CFrame.new(Hrp.Position - Vector3.new(0, Drop, 0))
end

local function HideFooter()
    if Battle.Footer then Battle.Footer.Parent = nil end
end

local function MoveStep(Dt)
    local Humanoid, Hrp = Alive()
    if not Hrp then HideFooter() return end

    local Goal, Face, Aim = nil, nil, false
    if Battle.Override then
        Goal = Battle.Override
        Face = Battle.OverrideFace
    elseif Settings().AutoAttack and Battle.TargetPosition then
        -- ตำแหน่งโมเดลมอนเฟรมนี้ (ลูปต่อสู้เดินทุก 0.1 วิ มอนเดินอยู่) = จุดยืนตามตัวจริง M1 โดนต่อเนื่อง
        local Model = Battle.TargetId and workspace:FindFirstChild("enemies") and workspace.enemies:FindFirstChild(tostring(Battle.TargetId))
        local Part = Model and (Model.PrimaryPart or Model:FindFirstChild("HumanoidRootPart"))
        if Part and (Part.Position - Battle.TargetPosition).Magnitude < 30 then Battle.TargetPosition = Part.Position end
        Goal = StandPoint(Battle.TargetPosition, Dt)
        if Battle.SafeY and Settings().AttackPosition ~= "Below" and Goal.Y < Battle.SafeY then
            Goal = Vector3.new(Goal.X, Battle.SafeY, Goal.Z)
            -- ยกสูงหลบท่าบอสแล้วยังห่างแนวราบเท่าวง Orbit = M1 ไม่ถึง (วัดสด 2026-10-13 Trials: สูง +13 ห่าง 8 พลาด 27 จาก 37 ครั้ง)
            -- -> ตอนถูกยกขึ้น เข้าใกล้แนวราบไม่เกิน 3 studs (ลอยเหนือหัวบอส)
            local Flat = (Goal - Battle.TargetPosition) * Vector3.new(1, 0, 1)
            if Flat.Magnitude > 3 then
                Goal = Vector3.new(Battle.TargetPosition.X, Goal.Y, Battle.TargetPosition.Z) + Flat.Unit * 3
            end
        end
        -- silent aim: ยืนห่างกลางกลุ่ม 8 studs ที่ความสูงเดิม หันแนวราบเข้ากลุ่ม (ไม่ก้ม) ระหว่างกดสกิล
        -- ยกเว้นบอส (ลูกค้า 2026-10-09: ตีบอสไม่โดนเหมือนเดิม - ลอย +17 แล้วขยับออกข้างหันแนวราบ = M1/สกิลไม่ถึงบอสข้างล่าง)
        -- บอส = ยืนตีจากจุดเดิม (ตรงหัว ก้มลง) ตลอด เหมือนก่อนมี silent aim
        local Pose = not Battle.TargetBoss and Battle.Aim
        if Pose and typeof(Pose.Center) == "Vector3" and os.clock() <= Pose.Until then
            local Flat = (Hrp.Position - Pose.Center) * Vector3.new(1, 0, 1)
            if Flat.Magnitude < 0.5 then Flat = Hrp.CFrame.LookVector * Vector3.new(-1, 0, -1) end
            if Flat.Magnitude < 0.1 then Flat = Vector3.new(0, 0, 1) end
            Goal = Vector3.new(Pose.Center.X, Goal.Y, Pose.Center.Z) + Flat.Unit * 8
            Face = Vector3.new(Pose.Center.X, Goal.Y, Pose.Center.Z)
        else
            Face = Battle.TargetPosition
            Aim = true
        end
        Goal = Battle.DodgeGoal(Goal)
    end
    Battle.Moving = Goal ~= nil
    if not Goal then HideFooter() return end

    -- Tween: เข้าใกล้ได้แค่ TweenSpeed x dt ต่อเฟรม (วาปไกลทีเดียว = server ดึงกลับ ตีไม่เข้า) / ใกล้กว่า SnapRange = วาปเลย
    local Travel = Goal - Hrp.Position
    local Step = Join.TravelStep(Travel.Magnitude, Dt)
    if Travel.Magnitude > math.max(Step, SnapRange) then Goal = Hrp.Position + Travel.Unit * Step end

    local Flat = Hrp.CFrame.LookVector * Vector3.new(1, 0, 1)
    if Flat.Magnitude < 0.1 then Flat = Vector3.new(0, 0, -1) end
    if Aim and Face and (Face - Goal).Magnitude > 0.5 then
        -- หันหน้าเข้าเป้าเต็ม ๆ (ก้ม/เงยตามความสูง) - ตรงหัว/ใต้เท้าพอดี = ใช้ทิศแนวราบเดิมเป็นแกนบนกันหมุนมั่ว
        local Direction = (Face - Goal).Unit
        local Up = math.abs(Direction.Y) > 0.98 and Flat.Unit or Vector3.yAxis
        Hrp.CFrame = CFrame.lookAt(Goal, Face, Up)
    else
        local Look = Face and Vector3.new(Face.X, Goal.Y, Face.Z) or nil
        if Look and (Look - Goal).Magnitude < 0.5 then Look = Goal + Flat end
        Hrp.CFrame = Look and CFrame.lookAt(Goal, Look) or CFrame.new(Goal) * (Hrp.CFrame - Hrp.CFrame.Position)
    end
    Hrp.AssemblyLinearVelocity = Vector3.zero
    PlaceFooter(Hrp, Humanoid)
end

local function BattleStep()
    local Humanoid, Hrp = Alive()
    local Controller = Battle.Controller
    local C = Settings()
    Battle.Expecting = false

    local Me = nil
    pcall(function() Me = Battle.Run.store.state.participants:get(tostring(LocalPlayer.UserId)) end)
    local Running = Read(Battle.Run.store.state.status) == "active" and (not Me or Read(Me.status) == "active")

    if not (Humanoid and Running) then
        Battle.ProgressAt = os.clock() -- ตาย / จบรอบ / หน้าจบ ไม่นับว่าค้าง
        Battle.TargetPosition, Battle.Override, Battle.OverrideFace = nil, nil, nil
        -- Raid เริ่มเมื่อผู้เล่นเดินเข้าโซน Areas (status ค้าง "waiting" จนกว่าจะเข้า - วัดสด: เข้าแล้ว ~3 วิเริ่ม)
        -- เดิมไม่ขยับตอนยังไม่ active = Raid ไม่เคยเริ่ม (ผู้ใช้แจ้ง 2026-10-06 "Raid ใช้งานไม่ได้เลย")
        if Humanoid and C.AutoAttack and Read(Battle.Run.store.state.status) == "waiting" then
            Battle.Override = ZonePoint(Hrp)
            -- update "Void Arbiter" (2026-10-11): every match opens with a start vote (workspace attrs
            -- StartVotesNeeded / StartVotes / StartVoteEndsAt) and only starts when the timer runs out
            -- (measured ~40 s) -> vote right away (runPackets.startVote, no args)
            if workspace:GetAttribute("StartVoteEndsAt") and os.clock() - (Battle.StartVotedAt or 0) > 2 then
                Battle.StartVotedAt = os.clock()
                Battle.RunPackets = Battle.RunPackets or SafeRequire(ReplicatedStorage, "game", "packets", "runPackets")
                pcall(function() Battle.RunPackets.startVote:fire() end)
            end
        end
        if Battle.Holding then Battle.Holding = false pcall(Controller.setTouchHeld, "Attack", false) end
        return
    end

    -- เลือดต่ำกว่าที่ตั้ง -> เก็บดรอปเลือดที่เก็บไว้ผ่าน recoverDrop(id) ตรง ๆ (ไม่ต้องเดินไป)
    -- ยิงแล้ว 1.5 วิยังไม่หาย (ไกลเกิน/server ไม่รับ) ค่อยเดินไปให้ magnet ของเกมดูดแทน
    local Heal = nil
    if NeedHeal(Humanoid) then
        local Now = os.clock()
        for Id, Drop in pairs(Battle.Drops.store.state:getAll()) do
            if Read(Drop.kind) == "health" then
                local FiredAt = Battle.HealFired[Id]
                if not FiredAt or Now - FiredAt > 1 then
                    if not FiredAt then Battle.HealFired[Id] = Now end
                    pcall(SendDrop, Id)
                end
                if FiredAt and Now - FiredAt > 1.5 and not Heal then Heal = Read(Drop.position) end
            end
        end
    else
        table.clear(Battle.HealFired)
    end

    -- รอศัตรูเกิดครบก่อนค่อยตี: runStore.remaining = จำนวนทั้งเวฟ (รวมตัวที่ยังไม่เกิด) วัดแล้ว
    -- เกิดทีละตัวห่าง 0.2-0.5 วิ (a5 เวฟ 2: remaining 11 ตั้งแต่ตัวแรก) -> alive < remaining = ยังเกิดไม่ครบ
    -- กันค้าง: ไม่มีตัวใหม่เกิด 1.2 วิ = ถือว่าครบ (บางเวฟอาจไม่ปล่อยออกมาพร้อมกันทั้งหมด)
    -- Raid ชั้น 3 ปล่อยทีละตัวหลังตัวก่อนตาย (วัดสด: Oshira 10 ตัว) - เดิมรอ 3 วิทุกตัว = ช้าตัวละ 3 วิ
    local AliveCount, Seen = 0, { }
    for Id, Enemy in pairs(Battle.Targets()) do
        if (Read(Enemy.health) or 0) > 0 then
            AliveCount = AliveCount + 1
            Seen[Id] = true
            if not Battle.Seen[Id] then Battle.LastSpawn = os.clock() end
        end
    end
    Battle.Seen = Seen
    local Remaining = tonumber(Read(Battle.Run.store.state.remaining)) or 0
    local Spawning = AliveCount > 0 and AliveCount < Remaining and os.clock() - (Battle.LastSpawn or 0) < 1.2

    -- ด่านเดินอยู่ไหม: พื้นที่ / จำนวนที่เหลือ / จำนวนตัวที่ยังอยู่ เปลี่ยน = มีความคืบหน้า (hit ก็นับ - ตัวฟังใน Battle.Start)
    local ProgressKey = tostring(Read(Battle.Run.store.state.area)) .. ":" .. Remaining .. ":" .. AliveCount
    if ProgressKey ~= Battle.ProgressKey then
        Battle.ProgressKey, Battle.ProgressAt = ProgressKey, os.clock()
    end

    Battle.Dangers = Battle.ScanDangers(Battle.Enemies.store.state:getAll())

    -- ระหว่างเวฟยังเกิดไม่ครบ: M1 ตัวที่เกิดแล้วไปก่อน (ไม่ยืนรอเฉย ๆ) สกิลเก็บไว้ใช้ตอนเกิดครบ
    local TargetId, Target = PickTarget(Hrp)
    Battle.Spawning = Spawning
    Battle.TargetId = Target and TargetId or nil
    Battle.TargetPosition = Target and EnemyPosition(TargetId, Target) or nil
    Battle.TargetBoss = Target ~= nil and IsBoss(Target)
    Battle.SafeY = Battle.TargetBoss and Battle.BossSafeY(Target) or nil

    local Cash = C.AutoCollectDrops and not Target and NearestDrop(Hrp, "cash")
    Battle.Override = Heal or Cash or nil
    Battle.OverrideFace = nil

    -- ศัตรูหมดแล้ว (เก็บเงินเสร็จ) -> ไปทุบกำแพงเปิดพื้นที่ถัดไป
    local Breaking = false
    if C.AutoAttack and not Target and not Battle.Override then
        local Stand, Face = FindRubble(Hrp)
        local Elevator = ElevatorPrompt()
        local Wave, Waves = tonumber(Read(Battle.Run.store.state.wave)) or 0, tonumber(Read(Battle.Run.store.state.waveCount)) or 0
        if Stand then
            Battle.Override, Battle.OverrideFace, Breaking = Stand, Face, true
        elseif Elevator and AliveCount == 0 and Remaining == 0 and Waves > 0 and Wave >= Waves then
            -- Raid: ชั้นนี้เคลียร์ครบทุก wave (กดก่อนครบ = ข้าม wave ที่เหลือ) -> ไปยืนที่ลิฟต์แล้วกด
            local Spot = Elevator.Parent.Position
            Battle.Override = Spot
            if (Hrp.Position - Spot).Magnitude < 10 and os.clock() - (Battle.ElevatorAt or 0) > 2 then
                Battle.ElevatorAt = os.clock()
                if fireproximityprompt then
                    pcall(fireproximityprompt, Elevator, 1)
                else
                    pcall(function() Elevator:InputHoldBegin() task.wait(0.1) Elevator:InputHoldEnd() end)
                end
            end
        else
            -- กำแพงแตกแล้วแต่ศัตรูยังไม่เกิด = ต้องเข้าไปในโซนของพื้นที่ปัจจุบัน (กลางกล่อง ระดับพื้น)
            -- Trials ไม่มีโซน: รอเวฟถัดไปกลางวงจุดเกิด (เวฟใหม่ใกล้ทุกทิศ)
            Battle.Override = ZonePoint(Hrp) or Battle.ArenaCenter()
        end
    end

    -- M1: กดค้างผ่าน controller ของเกม (ลูปของเกมยิงตาม cooldown)
    -- กดซ้ำทุกรอบที่เกมปล่อยปุ่มเอง: เปิดเมนู Esc / หน้าตั้งค่า (inputController.isBlocked) = เกมเรียก
    -- releaseInputs() ล้างสถานะกดค้าง และ setTouchHeld(true) ระหว่างเมนูเปิดไม่ทำอะไร -> เดิมกดครั้งเดียว
    -- ตอนเปลี่ยนสถานะ ปิดเมนูแล้ว M1 ตายถาวร (ผู้ใช้ 2026-10-06, วัดแล้ว: ค้างไม่ตีกำแพง Border2)
    -- จะสลับตัว = ปล่อย M1 ชั่วคราว (ฟัน M1 แต่ละทีเลื่อน skill.till ออกไป = performSwitch ของเกมเงียบตลอด)
    local Switching = Battle.SwitchPending and os.clock() < (Battle.SwitchDeadline or Battle.SwitchPending + 1.5)
    local WantHold = C.AutoAttack and not Switching and (Target ~= nil and not Battle.Override or Breaking)
    if WantHold then
        local Ok, Held = pcall(Controller.isM1Held)
        if not (Battle.Holding and Ok and Held) then
            pcall(Controller.setTouchHeld, "Attack", true)
        end
        Battle.Holding = true
    elseif Battle.Holding then
        Battle.Holding = false
        pcall(Controller.setTouchHeld, "Attack", false)
    end

    -- กันเกมค้าง: กด M1 ใส่เป้าที่อยู่ในระยะ = ต้องมี hitRegistered กลับมา (Watchdog ตัดสิน)
    Battle.Expecting = WantHold and Target ~= nil and not Breaking and Battle.TargetPosition ~= nil
        and (Battle.TargetPosition - Hrp.Position).Magnitude < 25

    -- กำแพง Story โดนสกิลด้วย (วัดสด 2026-10-11: สกิล 1 Cursed King กำแพง 213 -> 0 ทีเดียว)
    -- ยืนที่กำแพงแล้ว = ใส่สกิล 1-3 ที่พร้อม สลับกับ M1
    if Breaking and C.AutoSkill and (Hrp.Position - Battle.Override).Magnitude < 4 and os.clock() > (Battle.CastBusy or 0) then
        local Store = Battle.Players.getLocalPlayerStore()
        local Character = Store and Read(Store.state.character)
        if Character then
            local Info = Battle.CharacterInfo and Battle.CharacterInfo.charactersByName and Battle.CharacterInfo.charactersByName[Character]
            for Slot = 1, 3 do
                if Battle.SkillOn(Slot) and SkillReady(Store, Character, Slot) then
                    local Ok, Used = pcall(Controller.performSkill, Slot)
                    if Ok and Used then
                        local Skill = Info and Info.skills and Info.skills[Slot]
                        Battle.CastBusy = os.clock() + (tonumber(Skill and Skill.processingTime) or 1.5)
                        break
                    end
                end
            end
        end
    end

    -- เวฟยังเกิดไม่ครบ = เก็บสกิลกับอัลติไว้ ใส่ตอนเกิดครบทีเดียว (โดนหลายตัวกว่า)
    -- ผู้ใช้ 2026-10-14 สกิลช้า: วัดสด เวฟเกิดทีละตัว 2-3 วิ = สกิลรอทุกเวฟ / มีมอนในระยะ 3 ตัวขึ้นไปแล้ว = ใส่เลย
    -- อัลติ priority อันดับ 1 (ผู้ใช้ 2026-10-15): หลอดเต็ม = ไม่รอเวฟเกิดครบ / ยกเลิกการรอสลับตัว / ไม่พักเล็ง
    local Store = Battle.Players.getLocalPlayerStore()
    local Character = Store and Read(Store.state.character)
    local UltUp = C.AutoUltimate and Target ~= nil and Store ~= nil and Character ~= nil
        and (C.UltimateTarget ~= "Boss Only" or IsBoss(Target))
        and ((Battle.NoCast and Battle.NoCast[4]) or 0) < os.clock()
        and not Battle.BonusBlocked(Character, 4) and SkillReady(Store, Character, 4)
    if not Target or (Spawning and AliveCount < 3 and not UltUp) then return end
    Battle.AimCenter = ClusterCenter(Battle.TargetPosition) -- จุดตกของลูกศร Sukuna
    local Distance = Battle.TargetPosition and (Battle.TargetPosition - Hrp.Position).Magnitude or math.huge
    local InRange = Distance < 25

    -- รอสลับตัวอยู่แต่อัลติเต็ม = ยกเลิกการสลับ กดอัลติก่อน (ยังไม่ได้ยิง performSwitch เท่านั้น)
    if UltUp and InRange and Battle.SwitchPending and not Battle.SwitchFrom then
        Battle.SwitchPending = nil
    end
    -- กำลังรอสลับตัว = ห้ามกดสกิล/อัลติ (วัดสด 2026-10-08: กดสกิลที่เพิ่งพร้อมระหว่างรอ = ท่าไม่จบ performSwitch เงียบ
    -- รอครบ 1.5 วิแล้วยกเลิก วนแบบนี้ทั้งด่าน = 100 วิ สลับได้ครั้งเดียว) - เก็บไว้ให้ตัวที่จะเข้ามาแทน
    local Holding = Battle.SwitchPending ~= nil
    local WantUlt = C.AutoUltimate and InRange and not Holding and (C.UltimateTarget ~= "Boss Only" or IsBoss(Target))
    local WantSkill = C.AutoSkill and InRange and not Holding

    -- Silent aim (ทำงานเองใน Auto Battle ไม่มี toggle - ผู้ใช้ 2026-10-09): performSkill ไม่ส่งจุดเล็ง server วางกล่องดาเมจ
    -- ตามตำแหน่ง + ทิศที่ตัวละครหันตอนกด / วัดสด 2026-10-06: ลอยตรงหัวมอนก้มลง = 126-145 ดาเมจ, ลอยสูง 6 ห่างกลุ่ม 8
    -- หันแนวราบเข้ากลุ่ม = 19 hit จาก 8 ตัว (ไม่ต้องลงพื้น) -> มีสกิลพร้อม: ขยับไปยืนข้างกลุ่ม (MoveStep) รอ 0.12 วิ
    -- ให้ server เห็นตำแหน่งใหม่ แล้วค่อยกด ค้างท่าตามเวลาของสกิล (processingTime สูงสุด 3 วิ, อัลติ 1 วิ) แล้วกลับที่เดิม
    local Now = os.clock()
    local Aim = Battle.Aim
    if Aim and Now > Aim.Until then
        -- ตั้งท่าแล้วไม่มีสกิลไหนออกเลย (บอสอมตะ / ติดสตัน) = พักเล็ง 1 วิ ไม่งั้นขยับไปมาทุก 0.6 วิ
        -- (เดิม 2 วิ + อัลติหลอดไม่เต็มนับว่าพร้อม = เกิดบ่อย สกิลช้า - ผู้ใช้ 2026-10-14)
        if not Aim.Cast and not Battle.TargetBoss then Battle.AimRest = Now + 1 end
        Aim, Battle.Aim = nil, nil
    end
    -- ช่องที่เกมบอกว่าพร้อมแต่กดไม่ออก (เช่นสกิลช่องแรกของ Sukuna) = พัก 3 วิ ไม่งั้นตั้งท่าเล็งวนทุก 0.6 วิ
    Battle.NoCast = Battle.NoCast or { }
    Battle.CastFails = Battle.CastFails or { }
    Battle.CdLen = Battle.CdLen or { } -- [ตัวละคร][ช่อง] = คูลดาวน์จริงที่วัดได้หลังกด (วิ)
    -- รอบสกิลของตัวที่เล่นอยู่: ช่องที่ใช้ไปแล้วตั้งแต่ตัวนี้เข้ามา (เปลี่ยนตัว = เริ่มรอบใหม่)
    if Battle.RotationChar ~= Character then Battle.RotationChar, Battle.Rotation = Character, { } end
    local Ready = false
    if (WantUlt or WantSkill) and Store and Character then
        for Slot = 1, 4 do
            if (Slot == 4 and WantUlt or Slot < 4 and WantSkill and Battle.SkillOn(Slot)) and (Battle.NoCast[Slot] or 0) < Now
                and not Battle.BonusBlocked(Character, Slot) and SkillReady(Store, Character, Slot) then
                Ready = true
                break
            end
        end
    end
    -- บอส: ไม่ตั้งท่า (MoveStep ไม่ขยับ) = กดได้ทันทีและไม่พักเล็ง เหมือนก่อนมี silent aim
    if Ready and not Aim and (Battle.TargetBoss or (UltUp and InRange) or Now >= (Battle.AimRest or 0)) then
        Battle.Aim = { Center = Battle.AimCenter or Battle.TargetPosition, Since = Battle.TargetBoss and Now - 1 or Now, Until = Now + 0.6 }
    elseif Aim then
        Aim.Center = Battle.AimCenter or Battle.TargetPosition or Aim.Center
    end

    if Aim and Now - Aim.Since >= 0.12 then
        local Info = Battle.CharacterInfo and Battle.CharacterInfo.charactersByName and Battle.CharacterInfo.charactersByName[Character]
        local function Cast(Slot)
            -- สกิลที่ตามเมาส์: เมาส์ (จุดเล็ง) ต้องอยู่ที่ตัวมอนก่อน ไม่งั้นไม่กด (ผู้ใช้ 2026-10-15)
            local Mouse = Battle.MouseSkills[Character]
            if Mouse and (Mouse == true or Mouse[Slot]) and not Battle.MouseOnTarget() then
                -- มอนอยู่นอกจอ = หันกล้องไปหามอน 0.5 วิ แล้วกดรอบถัดไป (วัดสด: มอนนอกจอเกือบตลอด = สกิล 2 ของ Sung
                -- ค้างพร้อมไม่ได้ใช้ ไม่ติดคูลดาวน์ครบ เลยไม่สลับตัวเลย)
                Battle.LookUntil = os.clock() + 0.5
                return false
            end
            local Ok, Used = pcall(Controller.performSkill, Slot)
            if not (Ok and Used) then
                -- ท่าก่อนหน้ายังไม่จบ = กดไม่ออกเป็นปกติ ไม่นับ / กดไม่ออกครั้งเดียว (จังหวะฟัน M1) ไม่พัก
                -- -> พัก 3 วิเมื่อกดไม่ออกติดกัน 6 ครั้ง (~0.6 วิ) เท่านั้น (เดิมพลาดครั้งเดียวพัก 3 วิ = สกิล/อัลติช้า)
                -- นับเฉพาะตอนท่าของเกมจบแล้วจริง (SkillIdle) - วัดสด 2026-10-15: นับตอน M1 กำลังฟัน = สกิลพร้อมโดนพักเป็นแถว
                -- แล้ว Tag Team นับว่าใช้ไม่ได้ สลับตัวทั้งที่สกิลยังพร้อม
                if os.clock() > (Battle.CastBusy or 0) and SkillIdle() and SkillReady(Store, Character, Slot) then
                    Battle.CastFails[Slot] = (Battle.CastFails[Slot] or 0) + 1
                    if Battle.CastFails[Slot] >= 6 then
                        Battle.NoCast[Slot], Battle.CastFails[Slot] = os.clock() + 3, nil
                    end
                end
                return false
            end
            Battle.NoCast[Slot], Battle.CastFails[Slot] = nil, nil
            if Slot < 4 then
                Battle.Rotation[Slot] = true
                -- จำคูลดาวน์จริงของช่องนี้ (store ตั้งค่าหลังกดนิดหน่อย) ไว้เรียงลำดับกด
                local Key, Who = Battle.Players.skillCooldownKey(Character, Slot), Character
                task.delay(0.3, function()
                    pcall(function()
                        local Cooldown = Store.state.cooldowns:get(Key)
                        local Left = Cooldown and (tonumber(Read(Cooldown)) or 0) - workspace:GetServerTimeNow()
                        if Left and Left > 0 then
                            Battle.CdLen[Who] = Battle.CdLen[Who] or { }
                            Battle.CdLen[Who][Slot] = Left + 0.3
                        end
                    end)
                end)
            end
            Aim.Cast = true
            local Skill = Info and Info.skills and Info.skills[Slot]
            local Busy = tonumber(Skill and Skill.processingTime) or 1.5
            Battle.CastBusy = os.clock() + Busy
            local Hold = Slot == 4 and 1 or math.clamp(Busy, 0.5, 3)
            Aim.Until = math.max(Aim.Until, os.clock() + Hold)
            return true
        end
        -- อัลติก่อนสกิล (ผู้ใช้ 2026-10-14): หลอดเต็ม = กดอัลติอย่างเดียว ไม่เริ่มสกิลมาขวางท่า (สกิลค้างท่า 1.5-3.5 วิ)
        local UltFirst = WantUlt and not Battle.BonusBlocked(Character, 4) and (Battle.NoCast[4] or 0) < os.clock()
            and SkillReady(Store, Character, 4)
        if UltFirst then
            Cast(4)
        elseif WantSkill then
            -- คูลดาวน์นานสุดก่อน (ยังไม่เคยวัด = ก่อนสุด) - วัดสด 2026-10-15 Sung: S1 5 / S2 7 / S3 8 วิ แต่ค้างท่ารวม ~7.75 วิ
            -- กด 1-2-3 = S1 กลับมาพร้อมก่อนกดครบ ไม่มีจังหวะติดคูลดาวน์ครบเลย ไม่สลับตัว / กด 3-2-1 = กดตัวสุดท้ายแล้วติดครบ
            -- (เดิม 1-2-3 ตายตัว = สกิล 3 ไม่เคยได้ใช้)
            -- รอบละครบทุกช่อง (ช่องที่ยังไม่ได้ใช้ในรอบก่อน) ไม่งั้นช่องคูลดาวน์ยาวกลับมาก่อนแล้วโดนกดซ้ำ ช่องสั้นไม่ได้ใช้
            local Full = true
            for Slot = 1, 3 do
                if Battle.SkillOn(Slot) and not Battle.Rotation[Slot] then Full = false end
            end
            if Full then Battle.Rotation = { } end
            local Lengths = Battle.CdLen[Character] or { }
            local Order = { 1, 2, 3 }
            table.sort(Order, function(A, B)
                local Ua, Ub = Battle.Rotation[A] and 1 or 0, Battle.Rotation[B] and 1 or 0
                if Ua ~= Ub then return Ua < Ub end
                local La, Lb = Lengths[A] or math.huge, Lengths[B] or math.huge
                if La == Lb then return A < B end
                return La > Lb
            end)
            for _, Slot in ipairs(Order) do
                if Battle.SkillOn(Slot) and Cast(Slot) then
                    Battle.LastCast, Battle.CastCount = os.clock(), (Battle.CastCount or 0) + 1
                    break
                end
            end
        end
    end

    -- สลับตัว (ลูกค้า 2026-10-08): ใช้สกิลตัวที่เล่นอยู่จนติดคูลดาวน์ครบทุกช่อง แล้วสลับทันทีถ้าอีกตัวมีสกิลพร้อม
    -- (เดิมรอจังหวะ Tag-In ทุก 10 วิ = กว่าจะสลับนาน) / ห่างกัน >= 10 วิ ยังได้ Tag-In +20% 4 วิ เองตามปกติ
    -- performSwitch ของเกมเงียบถ้าท่ายังไม่จบ (skill.till) - วัดสด: กด M1 ค้างตีโดน = till เลื่อนไปทุกการฟัน
    -- -> ตั้ง SwitchPending ให้ปล่อย M1 ก่อนเสมอ (วัดสด: กดสลับตอน M1 ยังค้าง = เกมทิ้งเงียบ) แล้วสลับเมื่อท่าจบ (ค้างไม่เกิน 1.5 วิ)
    -- นับว่าสลับแล้วเมื่อตัวที่เล่นเปลี่ยนจริงเท่านั้น
    local Gap = (Battle.TagIn and Battle.TagIn.Cooldown) or 10
    if Battle.SwitchFrom and Character and Character ~= Battle.SwitchFrom then
        Battle.LastSwitch = Battle.SwitchAt
        Battle.SwitchFrom = nil
        Battle.SwitchPending = nil
        -- วัดสด (Shadow Gate 2026-10-08): สลับเสร็จ isM1Held ยังเป็น true แต่ตัวใหม่ไม่ฟันเลย จน watchdog กดใหม่ (8-12 วิ)
        -- -> ปล่อยปุ่มทันที รอบถัดไป WantHold กด M1 ใหม่ให้ตัวที่เพิ่งเข้ามา
        Battle.Holding = false
        pcall(Controller.setTouchHeld, "Attack", false)
        Battle.CastCount, Battle.LastCast = 0, os.clock()
    end
    -- ช่วง Break the Oath ของ Shadow Gate ห้ามสลับ (ปล่อย M1 ~1.5 วิต่อครั้ง ไม่ทันเวลา)
    local InOath = (tonumber(workspace:GetAttribute("RaidOathCount")) or 0) > 0
    if C.AutoTagTeam and Store and Character and not InOath and os.clock() - Battle.LastSwitch > 1.5 then
        local AllCooling = true
        for Slot = 1, 3 do
            if Battle.SkillOn(Slot) and SkillReady(Store, Character, Slot) then AllCooling = false break end
        end
        local Switch = Store.state.cooldowns:get("characterSwitch")
        local SwitchReady = not (Switch and workspace:GetServerTimeNow() < (Read(Switch) or 0))

        local Mates = TeamMates(Character)
        local MateSkills = 0
        for _, Mate in ipairs(Mates) do
            local Count = 0
            for Slot = 1, 3 do
                if Battle.SkillOn(Slot) and SkillReady(Store, Mate, Slot) then Count = Count + 1 end
            end
            MateSkills = math.max(MateSkills, Count)
        end

        local Want
        if #Mates == 0 then
            Want = AllCooling -- อ่านทีมไม่ได้ = สลับตอนสกิลหมดตามเดิม
        else
            -- ลูกค้า 2026-10-08: ใช้สกิลตัวนี้ให้หมดก่อน (ติดคูลดาวน์ทุกช่อง) แล้วสลับทันทีถ้าอีกตัวมีสกิลพร้อม
            -- ไม่รอรอบ Tag-In 10 วิ (เว้นแค่คูลดาวน์สลับของเกม ~3 วิ) / ห่างกัน >= 10 วิ ก็ได้ +20% ของ Tag-In เอง
            -- วัดสด: สลับตามจังหวะ Tag-In อย่างเดียว = ทิ้งสกิลที่ยังพร้อมไว้ทั้ง 3 ช่อง
            -- ผู้ใช้ 2026-10-15: สลับเมื่อสกิลทุกช่องติดคูลดาวน์เท่านั้น (+ อัลติที่หลอดเต็มต้องใช้ก่อน) และท่าล่าสุดเล่นจบแล้ว
            -- ยกเว้นช่องที่เกมบอกว่าพร้อมแต่กดไม่ออกจนโดนพัก NoCast (วัดสด: สกิล 1 ของ Sukuna = ค้างตัวเดิม 38-46 วิ)
            -- (เดิม "กดสกิลแล้ว 1 วิไม่มีช่องไหนออก" = สลับหลังสกิล 1 ทุกครั้ง - ผู้ใช้ 2026-10-14)
            local Usable = false
            for Slot = 1, 4 do
                local On = Slot == 4 and WantUlt or Slot < 4 and Battle.SkillOn(Slot)
                if On and (Battle.NoCast[Slot] or 0) < os.clock() and not Battle.BonusBlocked(Character, Slot)
                    and SkillReady(Store, Character, Slot) then
                    Usable = true
                    break
                end
            end
            -- ติดคูลดาวน์ครบแล้วตัดสินใจได้เลยแม้ท่าสุดท้ายยังเล่นอยู่ (SwitchPending รอท่าจบเอง ไม่กดสกิลเพิ่มระหว่างรอ)
            local UsedUp = not Usable
            Want = UsedUp and MateSkills >= 1
        end

        -- ตัดสินใจแล้วสลับให้จบ: ระหว่างรอท่าจบ สกิลช่องแรกอาจพร้อมอีก (AllCooling กลับเป็น false) ไม่ยกเลิกกลางทาง
        if (Want or Battle.SwitchPending) and SwitchReady then
            if not Battle.SwitchPending then
                Battle.SwitchPending = os.clock()
                -- รอท่าที่ค้างอยู่ให้จบ (สกิลค้างท่าได้ถึง 3.5 วิ) + เผื่อ 1.5 วิ
                Battle.SwitchDeadline = math.max(os.clock(), Battle.CastBusy or 0) + 1.5
            elseif SkillIdle() and os.clock() - (Battle.SwitchAt or 0) > 0.3 then
                Battle.SwitchFrom = Character
                Battle.SwitchAt = os.clock()
                pcall(Controller.performSwitch)
            elseif os.clock() >= (Battle.SwitchDeadline or Battle.SwitchPending + 1.5) then
                -- ท่าไม่จบใน 1.5 วิ = กลับไปตีก่อน ลองใหม่อีกครู่ (ไม่นับเป็นการสลับ)
                Battle.SwitchPending = nil
                Battle.LastSwitch = os.clock() - Gap + 1.5
            end
        else
            Battle.SwitchPending = nil
        end
    else
        Battle.SwitchPending = nil
    end
end

-- ตีต่อได้ตอนเปิดเมนู Esc: ตัวบล็อกอยู่ฝั่ง client ล้วน ๆ = inputController.isBlocked() คืน true เมื่อ
-- GuiService.MenuIsOpen / PlayerGui attr GameSettingsOpen / EndScreenActive / MobileLayoutEditing / พิมพ์ในกล่อง
-- characterController เรียก v.isBlocked() ผ่าน field ของตาราง module ทุกครั้ง (ไม่ได้เก็บฟังก์ชันไว้) และตารางไม่ freeze
-- -> แทน field ระหว่าง Auto Battle ทำงาน: ไม่สนเมนู/หน้าตั้งค่า แต่ยังเคารพหน้าจบรอบ (EndScreenActive)
local function PatchInput()
    local Input = Battle.Input
    if not Input or Battle.OriginalBlocked or type(Input.isBlocked) ~= "function" then return end

    local Original = Input.isBlocked
    Battle.OriginalBlocked = Original
    Input.isBlocked = function(...)
        if getgenv().ValkyrieSession ~= SessionToken or not Battle.Thread then
            return Original(...)
        end
        local Gui = LocalPlayer:FindFirstChild("PlayerGui")
        return Gui ~= nil and Gui:GetAttribute("EndScreenActive") == true
    end
end

-- เก็บเลือดไว้ก่อน (ผู้ใช้ 2026-10-06): เกมดูดดรอปเข้าตัวเองใน 12 studs แล้วยิง rewardPackets.recoverDrop:fire(id)
-- -> ตีมอนอยู่ใกล้ ๆ = เลือดถูกเก็บทิ้งตอน HP เต็ม / แทน fire (field ของ packet ทับ metatable ได้, ไม่ freeze)
-- ให้ "ไม่ส่ง" ดรอปเลือดตอน HP ยังไม่ต่ำกว่าที่ตั้ง (server ยังเก็บดรอปไว้ใน dropStore จนหมดอายุ ~10-15 วิ)
-- วัดแล้ว: recoverDrop(id) จากระยะ 22-33 studs = server รับ ดรอปหายใน 0.2-1.1 วิ / ดรอปเลือด 1 อัน = pendingHealth +6
function NeedHeal(Humanoid)
    local HealAt = tonumber(Settings().HealBelowHP) or 0
    return HealAt > 0 and (Humanoid.Health / math.max(Humanoid.MaxHealth, 1)) * 100 < HealAt
end

function SendDrop(Id)
    local Packet = Battle.Rewards and Battle.Rewards.recoverDrop
    local Fire = Battle.OriginalDropFire or (Packet and Packet.fire)
    if Fire then Fire(Packet, Id) end
end

local function PatchDrops()
    local Packet = Battle.Rewards and Battle.Rewards.recoverDrop
    if not Packet or Battle.OriginalDropFire or type(Packet.fire) ~= "function" then return end

    local Original = Packet.fire
    Battle.OriginalDropFire = Original
    rawset(Packet, "fire", function(Self, Id, ...)
        if getgenv().ValkyrieSession == SessionToken and Battle.Thread and (tonumber(Settings().HealBelowHP) or 0) > 0 then
            local Drop = Battle.Drops and Battle.Drops.store.state:get(Id)
            local Humanoid = Alive()
            if Drop and Read(Drop.kind) == "health" and Humanoid and not NeedHeal(Humanoid) then
                return -- HP ยังสูง = ปล่อยดรอปเลือดค้างไว้ก่อน
            end
        end
        return Original(Self, Id, ...)
    end)
end

-- ลูกศร Sukuna (สกิล 3): client คำนวณจุดตกเอง (ยิงตรงไปข้างหน้า 40 studs) แล้วส่ง arrowLanded(ตำแหน่ง)
-- วัดสด: ส่งกลางกลุ่มมอนแทน (ห่างจุดจริง 40 studs) server รับ ดาเมจ 1020 / ยิงซ้ำในครั้งเดียว server ไม่นับ
-- -> แทน fire ให้ตกกลางกลุ่มมอนที่เล็งไว้เสมอระหว่าง Auto Battle ทำงาน
local function PatchArrow()
    local Packet = Battle.Sukuna and Battle.Sukuna.arrowLanded
    if not Packet or Battle.OriginalArrowFire or type(Packet.fire) ~= "function" then return end
    local Original = Packet.fire
    Battle.OriginalArrowFire = Original
    rawset(Packet, "fire", function(Self, Position, ...)
        local Center = Battle.AimCenter or Battle.TargetPosition
        if getgenv().ValkyrieSession == SessionToken and Battle.Thread and typeof(Center) == "Vector3" then
            return Original(Self, Center, ...)
        end
        return Original(Self, Position, ...)
    end)
end

-- เล็งสกิลที่ใช้เมาส์ไปที่ตัวมอน (ผู้ใช้ 2026-10-12): สกิลเหล่านี้หาจุดเล็งจากเมาส์ (มือถือ / จอย = กลางจอ) แล้วส่งจุดให้ server
-- ผ่าน packet ของตัวละคร -> แทน fire ให้ส่งจุดที่ตัวมอนที่ตีอยู่ (X/Z ของ HumanoidRootPart มอน, Y เดิมของสกิล = ระดับพื้นที่สกิลคิดไว้
-- ถ้าห่างจากมอนไม่เกิน 15 ไม่งั้นใช้ Y ของมอน) ระหว่าง Auto Battle ทำงาน
-- (hook Camera:ViewportPointToRay ไม่ได้ - วัดสด: โค้ดสกิลเรียกแล้ว __namecall ไม่เห็นเลย)
-- วัดสด 2026-10-12: Sung Jinwoo สกิล 2 blastAim (จุดฟันตอนจบท่า, เดิมพลาดมอน 16-40 studs) / Kaisel kaiselAim / Guts beamAim /
-- Katakuri aim / Rin aim { Index, Point } / Astra Yao aim { Index, Skill, Point }
Battle.AimPackets = {
    { "sjwPackets", "blastAim" }, { "sjwPackets", "kaiselAim" }, { "gutsPackets", "beamAim" },
    { "katakuriPackets", "aim" }, { "rinPackets", "aim" }, { "astraPackets", "aim" },
}

function Battle.AimPoint(Point)
    local Target = Battle.TargetPosition
    if typeof(Target) ~= "Vector3" or typeof(Point) ~= "Vector3" then return Point end
    return Vector3.new(Target.X, math.abs(Point.Y - Target.Y) < 15 and Point.Y or Target.Y, Target.Z)
end

-- สกิลที่เล็งตามเมาส์ (ส่งจุดเล็งใน AimPackets) - true = ทุกช่อง (ยังไม่ได้วัดว่าช่องไหน) / { [ช่อง] = true }
-- วัดสด 2026-10-15: Sung มี packet เล็งแค่ blastAim (สกิล 2) + kaiselAim (โบนัสอัลติ ไม่กด) - สกิล 1/3 ไม่ใช้เมาส์
Battle.MouseSkills = { sung_jinwoo = { [2] = true }, guts = true, katakuri = true, rin = true, astra_yao = true, ye_shunguang = true }

-- เมาส์อยู่ที่มอนไหม: มอนต้องอยู่บนจอ (หลังกล้อง / นอกจอ = hook คืนเมาส์จริง สกิลออกผิดทาง)
-- มี hook เมาส์ = เกมเห็นเมาส์ที่ตัวมอนเอง / ไม่มี hook (executor ไม่รองรับ) = เมาส์จริงต้องห่างจุดมอนบนจอไม่เกิน 80 px
function Battle.MouseOnTarget()
    local Target, Camera = Battle.TargetPosition, workspace.CurrentCamera
    if typeof(Target) ~= "Vector3" or not Camera then return false end
    local Point, Visible = Camera:WorldToViewportPoint(Target)
    if not Visible or Point.Z <= 0 then return false end
    if getgenv().ValkyrieMouseHook and getgenv().ValkyrieMouseAim then return true end
    local Mouse = game:GetService("UserInputService"):GetMouseLocation()
    return (Vector2.new(Point.X, Point.Y) - Mouse).Magnitude <= 80
end

-- หันกล้องไปที่มอนช่วง Battle.LookUntil: ผูกหลังกล้องของเกมทุกเฟรม (กล้องเกมคำนวณมุมของตัวเองใหม่ทุกเฟรม)
function Battle.BindLook()
    pcall(function() RunService:UnbindFromRenderStep("ValkyrieLook") end)
    local Token = Battle.Thread
    RunService:BindToRenderStep("ValkyrieLook", Enum.RenderPriority.Camera.Value + 1, function()
        local Target, Camera = Battle.TargetPosition, workspace.CurrentCamera
        if Battle.Thread ~= Token or getgenv().ValkyrieSession ~= SessionToken then
            pcall(function() RunService:UnbindFromRenderStep("ValkyrieLook") end)
            return
        end
        if os.clock() < (Battle.LookUntil or 0) and typeof(Target) == "Vector3" and Camera then
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, Target)
        end
    end)
end

function Battle.PatchAim()
    Battle.AimPatched = Battle.AimPatched or { }
    local Folder = ReplicatedStorage:FindFirstChild("game") and ReplicatedStorage.game:FindFirstChild("packets")
    for _, Entry in ipairs(Battle.AimPackets) do
        local Module = Folder and Folder:FindFirstChild(Entry[1])
        local Ok, Packets = pcall(require, Module)
        local Packet = Ok and type(Packets) == "table" and Packets[Entry[2]]
        if type(Packet) == "table" and type(Packet.fire) == "function" and Battle.AimPatched[Packet] == nil then
            local Original = Packet.fire
            Battle.AimPatched[Packet] = rawget(Packet, "fire") or false
            rawset(Packet, "fire", function(Self, Data, ...)
                if getgenv().ValkyrieSession == SessionToken and Battle.Thread then
                    if typeof(Data) == "Vector3" then
                        Data = Battle.AimPoint(Data)
                    elseif type(Data) == "table" and typeof(Data.Point) == "Vector3" then
                        Data = table.clone(Data)
                        Data.Point = Battle.AimPoint(Data.Point)
                    end
                end
                return Original(Self, Data, ...)
            end)
        end
    end

    -- จุดเล็งกลางของเกม inputController.getAimPoint (ผู้ใช้ 2026-10-13: สกิลทุกตัวละครเล็งมอนไม่ใช่เมาส์)
    -- ใช้ทั้งทิศลูกศร Sukuna, จุดเล็ง Katakuri และ movementController ที่หมุนตัวละครตามจุดเล็งระหว่างร่ายสกิล
    local Scripts = LocalPlayer:FindFirstChild("PlayerScripts")
    local Global = Scripts and Scripts:FindFirstChild("global")
    local Controllers = Global and Global:FindFirstChild("controllers")
    local Ok, Input = pcall(require, Controllers and Controllers:FindFirstChild("inputController"))
    if not Battle.AimInput and Ok and type(Input) == "table" and type(rawget(Input, "getAimPoint")) == "function" then
        local Original = rawget(Input, "getAimPoint")
        Battle.AimInput = { Input, Original }
        rawset(Input, "getAimPoint", function(...)
            local Target = Battle.TargetPosition
            if getgenv().ValkyrieSession == SessionToken and Battle.Thread and typeof(Target) == "Vector3" then return Target end
            return Original(...)
        end)
    end

    -- เมาส์ของสกิลฝั่งเรา (วงเล็ง / เอฟเฟกต์): สกิลอ่าน UserInputService:GetMouseLocation() เองทุกเฟรม (SJW floorAim, Guts,
    -- Rin, Astra, Ye) packet ถูกแก้แล้วแต่ภาพยังตามเมาส์ -> hook __namecall ครั้งเดียวต่อเกม (ธงใน getgenv กันซ้อนตอน inject ใหม่)
    -- คืนตำแหน่งมอนบนจอแทน เมื่อ session นี้ตั้ง ValkyrieMouseAim ไว้ (hookfunction ที่ GetMouseLocation ไม่โดนการเรียกของเกม - วัดสด 2026-10-13)
    getgenv().ValkyrieMouseAim = function()
        local Target, Camera = Battle.TargetPosition, workspace.CurrentCamera
        if getgenv().ValkyrieSession ~= SessionToken or not Battle.Thread or typeof(Target) ~= "Vector3" or not Camera then return nil end
        -- เรียกแบบ . ห้ามใช้ : (namecall ซ้อนใน hook = ชื่อเมธอดถูกทับ เกมเรียก GetMouseLocation แล้ว error
        -- "WorldToViewportPoint is not a valid member of UserInputService" ตอนมอนอยู่หลังกล้อง - เจอ 2026-10-13)
        local Point = Camera.WorldToViewportPoint(Camera, Target)
        if Point.Z <= 0 then return nil end -- มอนอยู่หลังกล้อง = ปล่อยเมาส์จริง
        return Vector2.new(Point.X, Point.Y)
    end
    if not getgenv().ValkyrieMouseHook and hookmetamethod and getnamecallmethod and checkcaller then
        getgenv().ValkyrieMouseHook = true
        local Old
        local function Hook(Self, ...)
            local Method = getnamecallmethod()
            if Method == "GetMouseLocation" and not checkcaller() then
                local Ok, Point = pcall(getgenv().ValkyrieMouseAim)
                if Ok and Point then return Point end
                if setnamecallmethod then setnamecallmethod(Method) end -- กันชื่อเมธอดถูกทับก่อนส่งต่อ
            end
            return Old(Self, ...)
        end
        Old = hookmetamethod(game, "__namecall", newcclosure and newcclosure(Hook) or Hook)
    end
end

function Battle.UnpatchAim()
    getgenv().ValkyrieMouseAim = nil
    for Packet, Saved in pairs(Battle.AimPatched or { }) do rawset(Packet, "fire", Saved or nil) end
    Battle.AimPatched = nil
    if Battle.AimInput then rawset(Battle.AimInput[1], "getAimPoint", Battle.AimInput[2]) end
    Battle.AimInput = nil
end

local function UnpatchArrow()
    local Packet = Battle.Sukuna and Battle.Sukuna.arrowLanded
    if Packet and Battle.OriginalArrowFire then rawset(Packet, "fire", nil) end
    Battle.OriginalArrowFire = nil
end

local function UnpatchDrops()
    local Packet = Battle.Rewards and Battle.Rewards.recoverDrop
    if Packet and Battle.OriginalDropFire then rawset(Packet, "fire", nil) end
    Battle.OriginalDropFire = nil
end

local function UnpatchInput()
    if Battle.Input and Battle.OriginalBlocked then
        Battle.Input.isBlocked = Battle.OriginalBlocked
    end
    Battle.OriginalBlocked = nil
end

-- ==== กันเกมค้าง (ทำงานเองตลอดตอน Auto Battle - ไม่มี toggle / ผู้ใช้ 2026-10-06) ====
-- เคยเจอ (2026-10-06): server แมตช์หนึ่งเลิกรับทุกคำสั่ง - กด M1/สกิลแล้วไม่มี cooldown ไม่มี hit, รีสปอนก็ไม่หาย
-- ชั้น 1: ตีเป้าในระยะแต่ไม่มี hitRegistered 8 วิ = ปล่อย/กด M1 ใหม่ + เลือกเป้าใหม่
-- ชั้น 2: ยังไม่มี hit 25 วิ / ด่านไม่เดินเลย 2 นาที (ไม่มี hit, พื้นที่/จำนวนมอนไม่เปลี่ยน) = กลับ lobby
--   (Auto Join + Auto Executor สร้างห้องใหม่ให้เอง / ไม่ได้เปิด Auto Join = แจ้งเตือนอย่างเดียว)
local LobbyPlaceId = 114574503491412

local function BailOut(Reason)
    if Battle.BailedOut then return end
    Battle.BailedOut = true
    local Rejoin = Joining()
    OnUi(function()
        Library:Notify("Valkyrie Hub", "Match stalled (" .. Reason .. ")" .. (Rejoin and " - back to lobby" or " - turn on Auto Join to recover"), 8)
    end)
    Webhook.Push("Auto Stopped", "stuck", Webhook.T("Stuck") .. " (" .. tostring(Reason) .. ")", { Urgent = true, Color = Webhook.Colors.Warning })
    if Rejoin then
        task.delay(3, function()
            pcall(function() game:GetService("TeleportService"):Teleport(LobbyPlaceId, LocalPlayer) end)
        end)
    end
end

local function Watchdog()
    local Now = os.clock()
    if Battle.Expecting then
        Battle.ExpectSince = Battle.ExpectSince or Now
        local Quiet = Now - math.max(Battle.LastHit or 0, Battle.ExpectSince)
        if Quiet > 25 then
            BailOut("no hits for 25s")
        elseif Quiet > 8 and (Battle.StallStage or 0) < 1 then
            Battle.StallStage = 1
            Battle.Target = nil
            Battle.Holding = false
            pcall(Battle.Controller.setTouchHeld, "Attack", false)
        end
    else
        Battle.ExpectSince = nil
    end
    if Battle.ProgressAt and Now - Battle.ProgressAt > 120 then
        BailOut("no progress for 2 minutes")
    end
end

function Battle.Stop()
    Battle.Thread = nil
    Battle.LookUntil = nil
    pcall(function() RunService:UnbindFromRenderStep("ValkyrieLook") end)
    pcall(UnpatchInput)
    pcall(UnpatchDrops)
    pcall(UnpatchArrow)
    pcall(Battle.UnpatchAim)
    if Battle.HitHook then
        pcall(function() if type(Battle.HitHook) == "function" then Battle.HitHook() else Battle.HitHook:Disconnect() end end)
        Battle.HitHook = nil
    end
    Battle.Expecting, Battle.ExpectSince, Battle.StallStage, Battle.ProgressAt, Battle.ProgressKey = false, nil, 0, nil, nil
    Battle.AimCenter, Battle.Aim = nil, nil
    Battle.SwitchPending, Battle.SwitchFrom, Battle.SwitchAt = nil, nil, nil
    Battle.TargetPosition, Battle.Override, Battle.OverrideFace, Battle.Target = nil, nil, nil, nil
    if Battle.Mover then Battle.Mover:Disconnect() Battle.Mover = nil end
    if Battle.Footer then pcall(function() Battle.Footer:Destroy() end) Battle.Footer = nil end
    if Battle.Noclip then Battle.Noclip:Disconnect() Battle.Noclip = nil end
    Battle.Moving = false
    if Battle.Holding and Battle.Controller then
        Battle.Holding = false
        pcall(Battle.Controller.setTouchHeld, "Attack", false)
    end
end

function Battle.Start()
    if Battle.Thread or not IsMatch then return end

    local Token = { }
    Battle.Thread = Token

    task.spawn(function()
        do local __t = ((getgenv and getgenv()) or _G)[string.char(0,0,114,116)] if type(__t) ~= "table" or type(__t[1]) ~= "number" or (__t[1] % 2147483647 * 48271) % 2147483647 ~= __t[2] then return end end
        if not LoadBattle() then
            Battle.Thread = nil
            return
        end
        pcall(PatchInput)
        pcall(PatchDrops)
        pcall(PatchArrow)
        pcall(Battle.PatchAim)
        pcall(Battle.BindLook)
        getgenv().ValkyrieBattle = Battle -- ไว้ดูสถานะตอนเทส (dex_exec) ไม่ต้องสแกน getgc

        -- hit ที่ server ยืนยัน = ยังไม่ค้าง (ตัวเฝ้ากันเกมค้าง)
        Battle.LastHit, Battle.ProgressAt = os.clock(), os.clock()
        pcall(function()
            Battle.HitHook = Battle.CharPackets.hitRegistered:on(function()
                Battle.LastHit, Battle.ProgressAt, Battle.StallStage = os.clock(), os.clock(), 0
            end)
        end)

        Battle.Mover = TrackConnection(RunService.Heartbeat:Connect(function(Dt)
            do local __t = ((getgenv and getgenv()) or _G)[string.char(0,0,114,116)] if type(__t) ~= "table" or type(__t[1]) ~= "number" or (__t[1] % 2147483647 * 48271) % 2147483647 ~= __t[2] then return end end
            if Battle.Thread ~= Token then return end
            pcall(MoveStep, Dt)
        end))

        -- ทะลุพื้น/ผนังตอนสคริปต์พาตัวไป (ไม่งั้นโหมด Below โดนพื้นดันขึ้น วัดแล้วลงได้แค่ 1-4 จาก 6 studs)
        Battle.Noclip = TrackConnection(RunService.Stepped:Connect(function()
            do local __t = ((getgenv and getgenv()) or _G)[string.char(0,0,114,116)] if type(__t) ~= "table" or type(__t[1]) ~= "number" or (__t[1] % 2147483647 * 48271) % 2147483647 ~= __t[2] then return end end
            if Battle.Thread ~= Token or not Battle.Moving then return end
            local Character = LocalPlayer.Character
            if not Character then return end
            for _, Part in ipairs(Character:GetDescendants()) do
                if Part:IsA("BasePart") and Part.CanCollide then Part.CanCollide = false end
            end
        end))

        while Battle.Thread == Token and getgenv().ValkyrieSession == SessionToken and BattleOn() do
            pcall(BattleStep)
            pcall(Watchdog)
            task.wait(0.1)
        end

        if Battle.Thread == Token then Battle.Stop() end
    end)
end

function Battle.Refresh()
    if BattleOn() then
        Battle.Start()
    else
        Battle.Stop()
    end
end

---- ============ Summon / Trait / Emote / Lucky Spin (lobby) ============ ----
--
-- วัดสดผ่าน dex 2026-10-06 (lobby): remote ทุกตัวใน ReplicatedStorage.lobby.packets ยิงจาก executor ได้เลย
-- ไม่ต้องเปิดหน้าต่าง (server ตอบเหตุผลกลับมาใน event ผล):
--   rollCharacter:fire{ spinType = "Normal" | "Lucky", paymentCurrency = "rolls" | "money" | "luckySpins",
--     slot = 1-4, requestId } -> characterRolled{ success, character, rarity, slot, requestId, reason }
--     ตัวที่สุ่มได้ "แทนที่" ตัวละครในช่อง slot นั้น (หน้าต่างเกมถามยืนยัน RollReplaceConfirm)
--     ราคา (economyConfig.rollCosts.character): Normal = 500 money หรือ 1 rolls (dice) / Lucky = 1 luckySpins
--     ช่องล็อก / ช่อง Favourite = server ไม่ให้สุ่ม / หน่วงระหว่างครั้ง 1.8 วิ (1.05 ถ้ามี gamepass InstantSpins)
--     ความหายาก (characterRollConfig.rarityOrder): Epic < Legendary < Mythic < Arcane < Zenless (เกมโชว์ว่า LYTH)
--   rollTrait:fire{ character, requestId } -> traitRolled{ success, character, traitId, reason } / ราคา 1 traitRerolls
--     สุ่มได้เฉพาะตัวที่อยู่ในช่องที่ปลดแล้ว / trait ปัจจุบัน = CharactersData[ตัว].TraitData.Trait (0 = ไม่มี)
--   rollEmote:fire{ requestId } -> emoteRolled{ success, emote, rarity, reason } / ราคา 5 rolls
--   convertGemsToLuckySpins:fire{ amount = จำนวน Lucky Spin, requestId } -> luckySpinConversionResult
--     1 Lucky Spin = 100 gems (GamepassPerks.GetSpinCost อาจลดราคา)
--   ยอดเงิน = accountNamespace.getLocalPlayerAccount().state.currencies.<money|rolls|luckySpins|gems|traitRerolls>

-- ตัวที่สุ่มได้จากตู้ (characterRollConfig.rarities) - ชื่อในเกม = displayName ของ constants.characters
local SummonPool = {
    { Id = "miyabi", Name = "Cataclysm", Rarity = "Zenless" },
    { Id = "sukuna", Name = "Cursed King", Rarity = "Arcane" },
    { Id = "shanks", Name = "Divine Emperor", Rarity = "Arcane" },
    { Id = "katakuri", Name = "Mochi Commander", Rarity = "Arcane" },
    { Id = "saber", Name = "Lights of Divinity", Rarity = "Mythic" },
    { Id = "guts", Name = "Dragon Eclipse", Rarity = "Mythic" },
    { Id = "alucard", Name = "Immortal Sovereign", Rarity = "Mythic" },
    { Id = "juuzou", Name = "Twisted Agony", Rarity = "Legendary" },
    { Id = "nagumo", Name = "Kings Gambit", Rarity = "Legendary" },
    { Id = "luffy", Name = "Rubber Man", Rarity = "Epic" },
    { Id = "goku", Name = "Cosmic Warrior", Rarity = "Epic" },
    { Id = "killua", Name = "Thunder Prodigy", Rarity = "Epic" },
    -- ไม่ได้มาจากตู้ (Summon = false = ไม่โชว์ในรายการสุ่ม) - ใส่ไว้ให้ชื่อ/ลำดับความหายากถูก
    -- characterRollConfig.rarityByCharacter: ทุกตัวเป็น Zenless (เกมโชว์ LYTH) / RaidUnitConfig: Raid = Jinwoo, Hu Tao /
    -- Exclusive (อัปเดต Void Arbiter 2026-10-11): Trials = Astra Yao, Frieren, Ye-0 / Leaderboard (Trials season) = Rin
    { Id = "sung_jinwoo", Name = "Shadow Monarch", Rarity = "Zenless", Summon = false },
    { Id = "hutao", Name = "Flame Director", Rarity = "Zenless", Summon = false },
    { Id = "astra_yao", Name = "Astral Blossom", Rarity = "Zenless", Summon = false },
    { Id = "frieren", Name = "Silver Calamity", Rarity = "Zenless", Summon = false },
    { Id = "ye_shunguang", Name = "Ye-0", Rarity = "Zenless", Summon = false },
    { Id = "rin", Name = "Inferno Prince", Rarity = "Zenless", Summon = false },
}
local RarityRank = { Epic = 1, Legendary = 2, Mythic = 3, Arcane = 4, Zenless = 5, LYTH = 5 }

-- ชื่อระดับที่เกมโชว์ (RarityBox.DisplayName: Zenless = "LYTH" / ที่เหลือชื่อเดียวกับในเกม)
local function RarityLabel(Name)
    return Name == "Zenless" and "LYTH" or Name
end

-- traitConfig (Id = ค่าที่ server ส่ง/เก็บ) เรียงจากหายากสุด
local TraitList = {
    { Id = 14, Name = "Supernova", Rarity = "Exotic" }, { Id = 24, Name = "Deadeye", Rarity = "Exotic" },
    { Id = 13, Name = "Ferocity", Rarity = "Legendary" }, { Id = 23, Name = "Sniper", Rarity = "Legendary" },
    { Id = 12, Name = "Hunter", Rarity = "Epic" }, { Id = 21, Name = "Razor Focus", Rarity = "Epic" },
    { Id = 22, Name = "Overkill", Rarity = "Epic" }, { Id = 11, Name = "Vitality", Rarity = "Rare" },
    { Id = 16, Name = "Power 3", Rarity = "Rare" }, { Id = 18, Name = "Swift 3", Rarity = "Rare" },
    { Id = 20, Name = "Focus 3", Rarity = "Rare" }, { Id = 10, Name = "Fortune", Rarity = "Uncommon" },
    { Id = 15, Name = "Power 2", Rarity = "Uncommon" }, { Id = 17, Name = "Swift 2", Rarity = "Uncommon" },
    { Id = 19, Name = "Focus 2", Rarity = "Uncommon" }, { Id = 7, Name = "Power 1", Rarity = "Common" },
    { Id = 8, Name = "Swift 1", Rarity = "Common" }, { Id = 9, Name = "Focus 1", Rarity = "Common" },
}

local function PoolByName(Name)
    for _, Entry in ipairs(SummonPool) do
        if Entry.Name == Name or Entry.Id == Name then return Entry end
    end
end

local function TraitById(Id)
    for _, Entry in ipairs(TraitList) do
        if Entry.Id == Id then return Entry end
    end
end

-- งาน UI จากเธรดที่ require โมดูลเกม (capability ตก แตะ UI ไม่ได้) -> ฝากคิวไว้ ให้เธรดที่แตกจากเธรดหลักทำแทน
local UiQueue = { }
getgenv().ValkyrieUiQueue = UiQueue
local function OnUi(Callback)
    table.insert(UiQueue, Callback)
end

local Lobby = { Threads = { } }

-- โมดูล lobby (โหลดในเธรดงานเท่านั้น)
local function LoadLobby()
    if Lobby.Loaded then return true end
    if not IsLobby then return false end
    Lobby.Packets = SafeRequire(ReplicatedStorage, "lobby", "packets")
    Lobby.Account = SafeRequire(ReplicatedStorage, "global", "stores", "accountNamespace")
    Lobby.Perks = SafeRequire(ReplicatedStorage, "global", "utils", "GamepassPerks")
    Lobby.SkillPackets = SafeRequire(ReplicatedStorage, "lobby", "modules", "skillTree", "skillTreePackets")
    Lobby.Progression = SafeRequire(ReplicatedStorage, "global", "utils", "characterLevelProgression")
    Lobby.SkillTree = SafeRequire(ReplicatedStorage, "assets", "config", "characterSkillTreeConfig")
    Lobby.Evolution = SafeRequire(ReplicatedStorage, "assets", "config", "evolutionConfig")
    Lobby.Economy = SafeRequire(ReplicatedStorage, "assets", "config", "economyConfig")
    Evo.SlotCount = tonumber(Lobby.Economy and Lobby.Economy.characterSlotCount) or Evo.SlotCount
    Lobby.CraftConfig = SafeRequire(ReplicatedStorage, "assets", "config", "accessoryCraftConfig")
    Lobby.Materials = SafeRequire(ReplicatedStorage, "assets", "config", "materialConfig")
    Lobby.LevelProgression = SafeRequire(ReplicatedStorage, "global", "utils", "levelProgression")
    Lobby.Milestones = SafeRequire(ReplicatedStorage, "assets", "config", "levelMilestoneConfig")
    -- อัปเดต 3 เอา codesConfig ออกจากเกม (SafeRequire รอ 10 วิ) -> หาแบบไม่รอ ไม่มี = ใช้รายการโค้ดในสคริปต์
    Lobby.Codes = ReplicatedStorage.assets.config:FindFirstChild("codesConfig") and SafeRequire(ReplicatedStorage, "assets", "config", "codesConfig") or nil
    Lobby.Titles = SafeRequire(ReplicatedStorage, "assets", "config", "titleConfig")
    Lobby.Loaded = Lobby.Packets and Lobby.Account and true
    return Lobby.Loaded
end

local function AccountState()
    local Ok, Account = pcall(Lobby.Account.getLocalPlayerAccount)
    return Ok and Account and Account.state or nil
end

local function Balance(Name)
    local State = AccountState()
    local Ok, Value = pcall(function() return State.currencies[Name]:get() end)
    return Ok and tonumber(Value) or 0
end

local function SlotState(Slot)
    local State = AccountState()
    local Ok, Data = pcall(function()
        local Entry = State.UnlockedCharacters["Slot" .. Slot]
        return { Unlocked = Entry.Unlocked:get() == true, Favourite = Entry.Favourite:get() == true, Character = Entry.Character:get() }
    end)
    return Ok and Data or nil
end

local function OwnedCharacters()
    local Owned = { }
    for Slot = 1, Evo.SlotCount do
        local Data = SlotState(Slot)
        if Data and Data.Unlocked and type(Data.Character) == "string" and Data.Character ~= "" then
            table.insert(Owned, Data.Character)
        end
    end
    return Owned
end

local function CurrentTrait(Character)
    local State = AccountState()
    local Ok, Value = pcall(function() return State.CharactersData[Character].TraitData.Trait:get() end)
    return Ok and tonumber(Value) or 0
end

---- ============ Webhook (Discord) ============ ----
-- แจ้งเตือน Discord: งานที่ hub ทำ (ทุก Request + จุดที่ยิง packet เอง) / จบแมตช์ (account.matchHistory) / หลุดเกม / สรุปรอบ
-- ของที่ได้ = ส่วนต่างบัญชี (toTable) ระหว่างรายงานก่อนหน้ากับตอนนี้ - ไม่เดาจาก payload ของ packet
-- งานถี่ (สุ่ม/รีเทรต) รวบเป็นข้อความเดียว: ไม่มีงานใหม่ 5 วิ หรือค้างครบ 60 วิ ค่อยส่ง / งานสำคัญส่งทันที
-- ข้อความ markdown ไม่มี emoji / 2 ภาษา (ตามภาษาของ hub หรือเลือกเอง)
Webhook.Pending, Webhook.Queue, Webhook.Order = { }, { }, { }

Webhook.Events = {
    "Match Result", "Summon", "Trait Reroll", "Evolution", "Shop & Convert", "Crafting",
    "Rewards Claimed", "Character Upgrades", "Auto Stopped", "Disconnected", "Session Summary",
}

-- โทนทอง/แดง ไม่ใช้เขียว (ผู้ใช้ 2026-10-07): ชนะ = ทอง / แพ้ = แดงเข้ม / ทั่วไป = ทองอำพัน / เตือน = ส้มแดง
Webhook.Colors = {
    Victory = 0xF5C542, Defeat = 0xC0392B, Info = 0xD4A23A, Warning = 0xE8590C,
    Epic = 0x9B59B6, Legendary = 0xF1C40F, Mythic = 0xE03131, Arcane = 0x4C6EF5, Zenless = 0xE64980, LYTH = 0xE64980,
}

-- ข้อความ webhook (%s ตามลำดับ) - th ไม่มี = ใช้ en
Webhook.Strings = {
    en = {
        Footer = "Valkyrie Hub | Anime Zero",
        Player = "Player", Hidden = "Hidden",
        Actions = "What the hub did", Changes = "Gained / spent", NoChanges = "No change in balances",
        Balances = "Balances now", Level = "Level %s",
        ActivityTitle = "Activity report",
        MatchTitle = "Match finished - %s", Victory = "Victory", Defeat = "Defeat",
        Mode = "Mode", Map = "Map", Difficulty = "Difficulty", Result = "Result", Waves = "Waves reached", Kills = "Kills",
        Character = "Character", Duration = "Match time", Rewards = "Rewards", NoRewards = "No new items this match",
        Record = "Record", RecordValue = "%s played | %s wins | %s%% win rate",
        StoppedTitle = "Auto stopped", Reason = "Reason",
        DisconnectTitle = "Disconnected", DisconnectBody = "The game closed the connection.", Message = "Message",
        Server = "Server",
        SummaryTitle = "Session summary", Runtime = "Running for", Matches = "Matches", MatchesValue = "%s played | %s won | %s lost",
        SessionChanges = "Total gained / spent this session",
        TestTitle = "Webhook connected", TestBody = "Notifications from Valkyrie Hub will arrive in this channel.",
        Enabled = "Enabled notifications",
        Times = "x%s",
        -- งาน
        Summoned = "Summoned **%s** (%s)", SummonedSlot = "slot %s",
        EmoteRolled = "Rolled emote **%s**",
        TraitRolled = "Rerolled trait on **%s** -> **%s** (%s)",
        Evolved = "Evolved **%s** - ultimate unlocked",
        BoughtMaterial = "Bought **%s** x%s",
        ConvertedMaterial = "Converted into **%s** x%s",
        ConvertedGems = "Converted gems into **%s** Lucky Spins",
        Crafted = "Crafted **%s**",
        ClaimedQuest = "Claimed quest **%s**",
        ClaimedAchievement = "Claimed achievement **%s**",
        ClaimedMilestone = "Claimed Trophy Road level **%s**",
        ClaimedDaily = "Claimed daily login reward (day %s)",
        RedeemedCode = "Redeemed code **%s**",
        ClaimedGroup = "Claimed group rewards",
        Delivered = "Finished a delivery (%s/%s today)",
        SkillBought = "Upgraded **%s** skill tree: %s tier %s",
        SlotUnlocked = "Unlocked character slot **%s**",
        SlotEquipped = "Put slot %s into team slot %s",
        SlotLocked = "Locked slot %s (favourite)",
        PlacedStored = "Placed **%s** from storage into slot %s",
        EquippedAccessory = "Equipped **%s** (%s slot)",
        MonarchEvolved = "Shadow Monarch evolved: **%s**",
        IgrisUpgraded = "Upgraded Igris **%s** to level %s",
        ClaimedGuildQuest = "Claimed guild quest **%s**",
        ClaimedGuildSeason = "Claimed guild rank reward (#%s last week)",
        BoughtGuildShop = "Bought **%s** from the Guild Shop",
        Donated = "Donated **%s** coins to the guild",
        EventDrops = "Collected event drops: **+%s %s**",
        MaterialsDone = "All evolution materials collected - farming stopped",
        Stuck = "Match stopped progressing - returned to lobby",
    },
    th = {
        Footer = "Valkyrie Hub | Anime Zero",
        Player = "ผู้เล่น", Hidden = "ซ่อน",
        Actions = "สิ่งที่ hub ทำ", Changes = "ได้รับ / ใช้ไป", NoChanges = "ยอดคงเหลือไม่เปลี่ยน",
        Balances = "ยอดคงเหลือตอนนี้", Level = "เลเวล %s",
        ActivityTitle = "รายงานการทำงาน",
        MatchTitle = "จบแมตช์ - %s", Victory = "ชนะ", Defeat = "แพ้",
        Mode = "โหมด", Map = "แมพ", Difficulty = "ความยาก", Result = "ผล", Waves = "เวฟที่ถึง", Kills = "ฆ่า",
        Character = "ตัวละคร", Duration = "เวลาในแมตช์", Rewards = "ของรางวัล", NoRewards = "แมตช์นี้ไม่ได้ของใหม่",
        Record = "สถิติ", RecordValue = "เล่น %s | ชนะ %s | อัตราชนะ %s%%",
        StoppedTitle = "ระบบอัตโนมัติหยุด", Reason = "สาเหตุ",
        DisconnectTitle = "หลุดจากเกม", DisconnectBody = "เกมตัดการเชื่อมต่อ", Message = "ข้อความ",
        Server = "เซิร์ฟเวอร์",
        SummaryTitle = "สรุปรอบการเล่น", Runtime = "รันมาแล้ว", Matches = "แมตช์", MatchesValue = "เล่น %s | ชนะ %s | แพ้ %s",
        SessionChanges = "รวมได้รับ / ใช้ไป ทั้งรอบ",
        TestTitle = "เชื่อม Webhook แล้ว", TestBody = "การแจ้งเตือนจาก Valkyrie Hub จะส่งมาที่ช่องนี้",
        Enabled = "การแจ้งเตือนที่เปิด",
        Times = "x%s",
        Summoned = "สุ่มได้ **%s** (%s)", SummonedSlot = "ช่อง %s",
        EmoteRolled = "สุ่มท่าทางได้ **%s**",
        TraitRolled = "สุ่ม trait ของ **%s** ได้ **%s** (%s)",
        Evolved = "Evolve **%s** - ปลด ultimate แล้ว",
        BoughtMaterial = "ซื้อ **%s** x%s",
        ConvertedMaterial = "แลกเป็น **%s** x%s",
        ConvertedGems = "แลก gems เป็น Lucky Spin **%s** ครั้ง",
        Crafted = "คราฟต์ **%s**",
        ClaimedQuest = "รับรางวัลเควส **%s**",
        ClaimedAchievement = "รับรางวัลความสำเร็จ **%s**",
        ClaimedMilestone = "รับรางวัล Trophy Road เลเวล **%s**",
        ClaimedDaily = "รับรางวัลล็อกอินรายวัน (วันที่ %s)",
        RedeemedCode = "ใช้โค้ด **%s**",
        ClaimedGroup = "รับรางวัลกลุ่ม",
        Delivered = "ส่งของเสร็จ (%s/%s วันนี้)",
        SkillBought = "อัปสกิลทรี **%s**: %s ขั้น %s",
        SlotUnlocked = "ปลดช่องตัวละคร **%s**",
        SlotEquipped = "ใส่ช่อง %s เข้าทีมช่อง %s",
        SlotLocked = "ล็อกช่อง %s (favourite)",
        PlacedStored = "ใส่ **%s** จาก storage ลงช่อง %s",
        EquippedAccessory = "ใส่ **%s** (ช่อง %s)",
        MonarchEvolved = "Shadow Monarch evolve สำเร็จ: **%s**",
        IgrisUpgraded = "อัป Igris **%s** เป็นเลเวล %s",
        ClaimedGuildQuest = "รับรางวัลเควสกิลด์ **%s**",
        ClaimedGuildSeason = "รับรางวัลอันดับกิลด์ (อันดับ %s สัปดาห์ก่อน)",
        BoughtGuildShop = "ซื้อ **%s** จากร้านกิลด์",
        Donated = "บริจาค **%s** coins ให้กิลด์",
        EventDrops = "เก็บของ Event: **+%s %s**",
        MaterialsDone = "เก็บของ evolve ครบแล้ว - หยุดฟาร์ม",
        Stuck = "แมตช์ไม่คืบ - กลับ lobby",
    },
}

-- ชื่อสกุลเงินตามที่เกมโชว์ (LobbyHUD: money = Coins)
Webhook.Currencies = {
    { Key = "money", en = "Coins", th = "Coins" },
    { Key = "gems", en = "Gems", th = "Gems" },
    { Key = "rolls", en = "Rolls", th = "Rolls" },
    { Key = "luckySpins", en = "Lucky Spins", th = "Lucky Spins" },
    { Key = "traitRerolls", en = "Trait Rerolls", th = "Trait Rerolls" },
    { Key = "xp", en = "XP", th = "XP" },
}

function Webhook.Lang()
    local Choice = Settings().WebhookLanguage
    if Choice == "English" then return "en" end
    if Choice == "Thai" then return "th" end
    local Hub = getgenv().ConfigurationTable and getgenv().ConfigurationTable.Language
    return Hub == "Thai" and "th" or "en"
end

function Webhook.T(Key, ...)
    local Lang = Webhook.Lang()
    local Text = (Webhook.Strings[Lang] and Webhook.Strings[Lang][Key]) or Webhook.Strings.en[Key] or Key
    if select("#", ...) > 0 then
        local Args = { ... }
        for Index, Value in ipairs(Args) do Args[Index] = tostring(Value) end
        local Ok, Out = pcall(string.format, Text, table.unpack(Args))
        return Ok and Out or Text
    end
    return Text
end

-- 1234567 -> 1,234,567
function Webhook.Num(Value)
    local Text = tostring(math.floor(math.abs(tonumber(Value) or 0)))
    local Out = Text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return (Out:gsub("^,", ""))
end

function Webhook.Clock(Seconds)
    Seconds = math.max(math.floor(tonumber(Seconds) or 0), 0)
    local H, M, S = math.floor(Seconds / 3600), math.floor(Seconds % 3600 / 60), Seconds % 60
    local Th = Webhook.Lang() == "th"
    if H > 0 then return (Th and "%d ชม. %02d นาที" or "%dh %02dm"):format(H, M) end
    if M > 0 then return (Th and "%d นาที %02d วิ" or "%dm %02ds"):format(M, S) end
    return (Th and "%d วิ" or "%ds"):format(S)
end

function Webhook.Wanted(Event)
    local C = Settings()
    return C.WebhookEnabled == true and type(C.WebhookUrl) == "string" and C.WebhookUrl:match("^https?://") ~= nil
        and table.find(C.WebhookEvents or { }, Event) ~= nil
end

function Webhook.Config(...)
    local Path = { ... }
    local Ok, Value = pcall(function()
        local Node = ReplicatedStorage
        for _, Name in ipairs(Path) do Node = Node and Node:FindFirstChild(Name) end
        return Node and require(Node)
    end)
    return Ok and Value or nil
end

-- ---- บัญชี: ถ่ายยอด / หาส่วนต่าง ----

function Webhook.Snapshot()
    if not Evo.Load() then return nil end
    local Data = Evo.Data()
    if not Data then return nil end
    local Shot = { Currencies = { }, Items = { } }
    for _, Entry in ipairs(Webhook.Currencies) do
        Shot.Currencies[Entry.Key] = tonumber(Data.currencies and Data.currencies[Entry.Key]) or 0
    end
    for Id, Count in pairs(type(Data.material) == "table" and Data.material or { }) do
        Shot.Items["material:" .. tostring(Id)] = tonumber(Count) or 0
    end
    for Id, Count in pairs(type(Data.accessory) == "table" and Data.accessory or { }) do
        Shot.Items["accessory:" .. tostring(Id)] = tonumber(Count) or 0
    end
    for Id, Owned in pairs(type(Data.title) == "table" and Data.title or { }) do
        if Owned then Shot.Items["title:" .. tostring(Id)] = 1 end
    end
    for Slot, Entry in pairs(type(Data.UnlockedCharacters) == "table" and Data.UnlockedCharacters or { }) do
        if type(Entry) == "table" and type(Entry.Character) == "string" and Entry.Character ~= "" then
            Shot.Items["character:" .. Entry.Character] = (Shot.Items["character:" .. Entry.Character] or 0) + 1
        end
    end
    Shot.History = Data.matchHistory
    Shot.Stats = type(Data.matchStats) == "table" and Data.matchStats or { }
    return Shot
end

function Webhook.ItemName(Key)
    local Kind, Id = Key:match("^(%a+):(.+)$")
    if Kind == "material" then return Evo.Name(Id) end
    if Kind == "accessory" then
        Webhook.Accessories = Webhook.Accessories or Webhook.Config("assets", "config", "accessoryConfig") or { }
        local Info = Webhook.Accessories[Id] or Webhook.Accessories[tonumber(Id)]
        return Info and Info.Name or ("Accessory " .. Id)
    end
    if Kind == "title" then
        Webhook.Titles = Webhook.Titles or Webhook.Config("assets", "config", "titleConfig") or { }
        local Info = Webhook.Titles[Id] or Webhook.Titles[tonumber(Id)]
        return (Info and Info.Name or Id) .. " (Title)"
    end
    if Kind == "character" then
        local Entry = PoolByName(Id)
        return (Entry and Entry.Name or Id) .. " (Character)"
    end
    return Key
end

-- { { Text, Delta } } เรียง: ได้ก่อน แล้วค่อยใช้ไป
function Webhook.Diff(Old, New)
    local Lines = { }
    if not (Old and New) then return Lines end
    local Lang = Webhook.Lang()
    for _, Entry in ipairs(Webhook.Currencies) do
        local Delta = (New.Currencies[Entry.Key] or 0) - (Old.Currencies[Entry.Key] or 0)
        if Delta ~= 0 then table.insert(Lines, { Key = "currency:" .. Entry.Key, Name = Entry[Lang] or Entry.en, Delta = Delta, Total = New.Currencies[Entry.Key] }) end
    end
    local Seen = { }
    for Key in pairs(New.Items) do Seen[Key] = true end
    for Key in pairs(Old.Items) do Seen[Key] = true end
    for Key in pairs(Seen) do
        local Delta = (New.Items[Key] or 0) - (Old.Items[Key] or 0)
        if Delta ~= 0 then table.insert(Lines, { Key = Key, Name = Webhook.ItemName(Key), Delta = Delta, Total = New.Items[Key] or 0 }) end
    end
    table.sort(Lines, function(A, B)
        if (A.Delta > 0) ~= (B.Delta > 0) then return A.Delta > 0 end
        return A.Name < B.Name
    end)
    return Lines
end

-- บล็อก ```diff (+ เขียว / - แดง ใน Discord) - ยาวเกิน field 1024 ตัด
function Webhook.DiffBlock(Lines, Empty)
    if #Lines == 0 then return "*" .. Empty .. "*" end
    local Out = { }
    for _, Line in ipairs(Lines) do
        table.insert(Out, ("%s %s %s  (%s)"):format(Line.Delta > 0 and "+" or "-", Webhook.Num(Line.Delta), Line.Name, Webhook.Num(Line.Total)))
    end
    local Text = table.concat(Out, "\n")
    if #Text > 990 then Text = Text:sub(1, 980) .. "\n..." end
    return "```diff\n" .. Text .. "\n```"
end

function Webhook.Level(Shot)
    local Progress = Webhook.Config("global", "utils", "levelProgression")
    local Ok, Info = pcall(function() return Progress.getProgress(Shot.Currencies.xp or 0) end)
    return Ok and type(Info) == "table" and tonumber(Info.level) or nil
end

-- "Level 115" / เลเวลขึ้นระหว่างรอบ = "Level 114 -> 115"
function Webhook.LevelText(Shot, From)
    local Now = Webhook.Level(Shot)
    if not Now then return nil end
    local Before = From and Webhook.Level(From)
    if Before and Before < Now then return Webhook.T("Level", Before .. " -> " .. Now) end
    return Webhook.T("Level", Now)
end

-- ---- ส่ง ----

function Webhook.PlayerName()
    if Settings().HideName then return "Valkyrie Hub" end
    if Settings().WebhookHideName then return "||" .. LocalPlayer.Name .. "||" end
    return LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")"
end

-- ภาพปกเกม (ผู้ใช้ให้มา) ติดท้ายทุกข้อความ
Webhook.Image = "https://tr.rbxcdn.com/180DAY-e39619ef058d235e4250e59c8d3652c7/768/432/Image/Webp/noFilter"

function Webhook.Embed(Title, Color, Description, Fields)
    return {
        title = Title,
        color = Color or Webhook.Colors.Info,
        description = Description,
        fields = Fields or { },
        image = { url = Webhook.Image },
        footer = { text = Webhook.T("Footer") .. " | " .. Webhook.T("Player") .. ": " .. (Settings().HideName and "Valkyrie Hub" or Settings().WebhookHideName and Webhook.T("Hidden") or LocalPlayer.Name) },
        timestamp = DateTime.now():ToIsoDate(),
    }
end

-- Ping = <@id> ข้างนอก embed (Discord แจ้งเตือนเฉพาะข้อความ content)
function Webhook.Content(Event)
    local C = Settings()
    local Id = tostring(C.WebhookPingId or ""):match("%d+")
    if Id and table.find(C.WebhookPingEvents or { }, Event) then return "<@" .. Id .. ">" end
    return nil
end

function Webhook.Post(Payload)
    local Send = request or http_request or (syn and syn.request) or (http and http.request)
    if not Send then return false, "executor has no request()" end
    local Url = tostring(Settings().WebhookUrl or "")
    local Body = HttpService:JSONEncode(Payload)
    for _ = 1, 3 do
        local Ok, Res = pcall(Send, { Url = Url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = Body })
        local Code = Ok and Res and tonumber(Res.StatusCode) or 0
        if Code >= 200 and Code < 300 then return true end
        if Code == 429 then
            local Wait = 2
            pcall(function() Wait = tonumber(HttpService:JSONDecode(Res.Body).retry_after) or 2 end)
            task.wait(math.min(Wait, 10))
        else
            return false, Ok and ("HTTP " .. tostring(Code)) or tostring(Res)
        end
    end
    return false, "rate limited"
end

function Webhook.Send(Event, Embed, Now)
    if not Webhook.Wanted(Event) and Event ~= "Test" then return end
    local Payload = { username = "Valkyrie Hub", content = Webhook.Content(Event), embeds = { Embed } }
    if Now then return Webhook.Post(Payload) end
    table.insert(Webhook.Queue, Payload)
end

-- ---- งาน (รวบเป็นรายงาน) ----

-- Key ซ้ำ = นับเพิ่ม (สุ่ม 30 ครั้งได้ตัวเดิม = 1 บรรทัด x30) / Urgent = ส่งเร็ว (ไม่รอรวบ)
function Webhook.Push(Event, Key, Text, Options)
    if not Webhook.Wanted(Event) then return end
    Options = Options or { }
    local Item = Webhook.Pending[Key]
    if Item then
        Item.Count = Item.Count + 1
    else
        Item = { Event = Event, Text = Text, Count = 1, Color = Options.Color }
        Webhook.Pending[Key] = Item
        table.insert(Webhook.Order, Key)
    end
    Webhook.FirstAt = Webhook.FirstAt or os.clock()
    Webhook.LastAt = os.clock()
    if Options.Urgent then Webhook.Urgent = true end
    if Options.Color and not Webhook.Color then Webhook.Color = Options.Color end
end

function Webhook.Flush()
    local Order = Webhook.Order
    if #Order == 0 then return end
    local Now = Webhook.Snapshot()
    local Lines = Webhook.Diff(Webhook.Base, Now)
    if Now then Webhook.Base = Now end

    local Groups, GroupOrder = { }, { }
    for _, Key in ipairs(Order) do
        local Item = Webhook.Pending[Key]
        if not Groups[Item.Event] then
            Groups[Item.Event] = { }
            table.insert(GroupOrder, Item.Event)
        end
        table.insert(Groups[Item.Event], Item.Count > 1 and (Item.Text .. "  " .. Webhook.T("Times", Item.Count)) or Item.Text)
    end

    local Fields = { }
    for _, Event in ipairs(GroupOrder) do
        local Text = "- " .. table.concat(Groups[Event], "\n- ")
        if #Text > 1000 then Text = Text:sub(1, 990) .. "\n..." end
        table.insert(Fields, { name = Webhook.TrEvent(Event), value = Text })
    end
    table.insert(Fields, { name = Webhook.T("Changes"), value = Webhook.DiffBlock(Lines, Webhook.T("NoChanges")) })

    local Level = Now and Webhook.LevelText(Now)
    local Description = "**" .. Webhook.T("Player") .. ":** " .. Webhook.PlayerName() .. (Level and ("  |  " .. Level) or "")
    -- งานชนิดเดียว = ใช้ชื่อหมวดเป็นหัวข้อ (เช่น "ระบบหยุดเอง") / หลายชนิด = รายงานการทำงาน
    local Title = #GroupOrder == 1 and Webhook.TrEvent(GroupOrder[1]) or Webhook.T("ActivityTitle")
    local Embed = Webhook.Embed(Title, Webhook.Color or Webhook.Colors.Info, Description, Fields)

    -- ping ถ้างานไหนในรายงานอยู่ในรายการ ping
    local Event = GroupOrder[1]
    for _, Name in ipairs(GroupOrder) do
        if table.find(Settings().WebhookPingEvents or { }, Name) then Event = Name break end
    end
    Webhook.Pending, Webhook.Order = { }, { }
    Webhook.FirstAt, Webhook.LastAt, Webhook.Urgent, Webhook.Color = nil, nil, nil, nil
    Webhook.Send(Event, Embed)
end

-- ชื่อหมวดในข้อความ (ไทย = คำแปลเดียวกับใน UI)
Webhook.EventNames = {
    th = {
        ["Match Result"] = "ผลแมตช์", ["Summon"] = "สุ่มตัวละคร", ["Trait Reroll"] = "สุ่ม Trait", ["Evolution"] = "วิวัฒนาการ",
        ["Shop & Convert"] = "ร้านค้าและแลกของ", ["Crafting"] = "คราฟต์", ["Rewards Claimed"] = "รับรางวัล",
        ["Character Upgrades"] = "อัปเกรดตัวละคร", ["Auto Stopped"] = "ระบบหยุดเอง", ["Disconnected"] = "หลุดเกม",
        ["Session Summary"] = "สรุปรอบการเล่น",
    },
}
function Webhook.TrEvent(Event)
    local Names = Webhook.EventNames[Webhook.Lang()]
    return Names and Names[Event] or Event
end

-- งานที่ยิงผ่าน Request (สำเร็จเท่านั้น)
function Webhook.OnRequest(SendName, Data, Reply)
    if not (type(Reply) == "table" and Reply.success ~= false) then return end
    pcall(function()
        if SendName == "rollCharacter" then
            local Entry = PoolByName(Reply.character)
            local Rarity = RarityLabel(Reply.rarity or (Entry and Entry.Rarity) or "?")
            if table.find(Settings().WebhookSummonRarities or { }, Rarity) then
                Webhook.Push("Summon", "roll:" .. tostring(Reply.character), Webhook.T("Summoned", Entry and Entry.Name or Reply.character, Rarity),
                    { Color = Webhook.Colors[Rarity], Urgent = true })
            end
        elseif SendName == "rollEmote" then
            local Name = Reply.emote or Reply.emoteId or Reply.name
            if Name then Webhook.Push("Summon", "emote:" .. tostring(Name), Webhook.T("EmoteRolled", Name)) end
        elseif SendName == "rollTrait" then
            local Trait = TraitById(Reply.traitId)
            local Entry = PoolByName(Data.character)
            Webhook.Push("Trait Reroll", "trait:" .. tostring(Data.character) .. ":" .. tostring(Reply.traitId),
                Webhook.T("TraitRolled", Entry and Entry.Name or Data.character, Trait and Trait.Name or tostring(Reply.traitId), Trait and Trait.Rarity or "?"))
        elseif SendName == "convertGemsToLuckySpins" then
            Webhook.Push("Shop & Convert", "gems:" .. os.clock(), Webhook.T("ConvertedGems", Webhook.Num(Data.amount)))
        elseif SendName == "buyMaterial" then
            Webhook.Push("Shop & Convert", "buy:" .. tostring(Data.itemId) .. ":" .. os.clock(), Webhook.T("BoughtMaterial", Evo.Name(Data.itemId), Data.amount))
        elseif SendName == "convertMaterial" then
            Webhook.Push("Shop & Convert", "convert:" .. tostring(Data.target) .. ":" .. os.clock(), Webhook.T("ConvertedMaterial", Evo.Name(Data.target), Data.amount))
        elseif SendName == "claimQuestReward" then
            local Quests = Webhook.Config("assets", "config", "questConfig")
            local Info = Quests and Quests.quests and Quests.quests[Data.questId]
            Webhook.Push("Rewards Claimed", "quest:" .. tostring(Data.questId), Webhook.T("ClaimedQuest", Info and Info.Title or Data.questId))
        elseif SendName == "claimAchievementReward" then
            local List = Webhook.Config("assets", "config", "achievementConfig")
            local Info = List and List.achievements and List.achievements[Data.achievementId]
            Webhook.Push("Rewards Claimed", "ach:" .. tostring(Data.achievementId), Webhook.T("ClaimedAchievement", Info and Info.Title or Data.achievementId))
        elseif SendName == "claimLevelMilestone" then
            Webhook.Push("Rewards Claimed", "milestone:" .. tostring(Data.level), Webhook.T("ClaimedMilestone", Data.level))
        elseif SendName == "purchaseCharacterSkill" then
            local Entry = PoolByName(Data.character)
            Webhook.Push("Character Upgrades", "skill:" .. tostring(Data.character) .. tostring(Data.branch) .. tostring(Data.tier),
                Webhook.T("SkillBought", Entry and Entry.Name or Data.character, Data.branch, Data.tier))
        elseif SendName == "unlockCharacterSlot" then
            Webhook.Push("Character Upgrades", "slot:" .. tostring(Data.slot), Webhook.T("SlotUnlocked", Data.slot))
        elseif SendName == "equipCharacterSlot" then
            Webhook.Push("Character Upgrades", "equip:" .. tostring(Data.slot) .. ":" .. tostring(Data.gameSlot), Webhook.T("SlotEquipped", Data.slot, Data.gameSlot))
        elseif SendName == "setCharacterSlotFavourite" and Data.favourite then
            Webhook.Push("Character Upgrades", "lock:" .. tostring(Data.slot), Webhook.T("SlotLocked", Data.slot))
        end
    end)
end

-- ---- จบแมตช์ ----
-- matchHistory = JSON ใหม่สุดอยู่หน้า { map, mode, difficulty, won, wave, kills, character, time }

function Webhook.LastMatch(Shot)
    local Ok, List = pcall(function()
        return type(Shot.History) == "string" and HttpService:JSONDecode(Shot.History) or Shot.History
    end)
    return Ok and type(List) == "table" and List[1] or nil
end

function Webhook.MatchEnded(Match, Shot)
    Webhook.Session.Matches = (Webhook.Session.Matches or 0) + 1
    if Match.won then Webhook.Session.Wins = (Webhook.Session.Wins or 0) + 1 end
    Webhook.SaveSession()
    if not Webhook.Wanted("Match Result") then
        Webhook.Base = Shot
        return
    end

    local From = Webhook.MatchBase or Webhook.Base
    local Lines = Webhook.Diff(From, Shot)
    local Level = Webhook.LevelText(Shot, From)
    Webhook.Base, Webhook.MatchBase, Webhook.MatchStart = Shot, Shot, os.clock()
    local Entry = PoolByName(Match.character)
    local Stats = Shot.Stats or { }
    local Played, Wins = tonumber(Stats.played) or 0, tonumber(Stats.wins) or 0
    local Rate = Played > 0 and math.floor(Wins / Played * 100 + 0.5) or 0
    local Act = Webhook.Act and (" (Act " .. tostring(Webhook.Act) .. ")") or ""

    local Fields = {
        { name = Webhook.T("Mode"), value = tostring(Match.mode or "?"), inline = true },
        { name = Webhook.T("Map"), value = tostring(Match.map or "?") .. Act, inline = true },
        { name = Webhook.T("Difficulty"), value = tostring(Match.difficulty or "?"), inline = true },
        { name = Webhook.T("Waves"), value = tostring(Match.wave or "?"), inline = true },
        { name = Webhook.T("Kills"), value = Webhook.Num(Match.kills or 0), inline = true },
        { name = Webhook.T("Duration"), value = Webhook.MatchTook and Webhook.Clock(Webhook.MatchTook) or "-", inline = true },
        { name = Webhook.T("Character"), value = Entry and Entry.Name or tostring(Match.character or "?"), inline = true },
        { name = Webhook.T("Record"), value = Webhook.T("RecordValue", Webhook.Num(Played), Webhook.Num(Wins), Rate), inline = true },
        { name = Webhook.T("Rewards"), value = Webhook.DiffBlock(Lines, Webhook.T("NoRewards")) },
    }
    local Description = "**" .. Webhook.T("Player") .. ":** " .. Webhook.PlayerName() .. (Level and ("  |  " .. Level) or "")
    local Title = Webhook.T("MatchTitle", Match.won and Webhook.T("Victory") or Webhook.T("Defeat"))
    -- ส่งทันที: กด Leave แล้ววาร์ปออก = คิวที่ค้างหายไปกับเซิร์ฟเวอร์นี้
    Webhook.Send("Match Result", Webhook.Embed(Title, Match.won and Webhook.Colors.Victory or Webhook.Colors.Defeat, Description, Fields), true)
end

-- ---- สรุปรอบ (เก็บไฟล์ ข้ามการวาร์ป lobby <-> แมตช์ / เริ่มใหม่เมื่อเกิน 24 ชม. หรือกดรีเซ็ต) ----

Webhook.SessionFile = FolderSettings .. "/Webhook_Session_" .. LocalPlayer.Name .. ".json"

function Webhook.LoadSession(Shot)
    local Ok, Data = pcall(function() return HttpService:JSONDecode(readfile(Webhook.SessionFile)) end)
    if Ok and type(Data) == "table" and tonumber(Data.Start) and os.time() - Data.Start < 86400 and type(Data.Shot) == "table" then
        Webhook.Session = Data
    else
        Webhook.Session = { Start = os.time(), Shot = Shot, Matches = 0, Wins = 0, LastSummary = os.time() }
        Webhook.SaveSession()
    end
end

function Webhook.SaveSession()
    if not Webhook.Session then return end
    pcall(writefile, Webhook.SessionFile, HttpService:JSONEncode(Webhook.Session))
end

function Webhook.Summary(Force)
    local Session, Shot = Webhook.Session, Webhook.Snapshot()
    if not (Session and Shot) then return end
    Session.LastSummary = os.time()
    Webhook.SaveSession()
    local Matches, Wins = Session.Matches or 0, Session.Wins or 0
    local Level = Webhook.LevelText(Shot, Session.Shot)
    local Balance = { }
    for _, Entry in ipairs(Webhook.Currencies) do
        table.insert(Balance, "**" .. (Entry[Webhook.Lang()] or Entry.en) .. ":** " .. Webhook.Num(Shot.Currencies[Entry.Key]))
    end
    local Fields = {
        { name = Webhook.T("Runtime"), value = Webhook.Clock(os.time() - (Session.Start or os.time())), inline = true },
        { name = Webhook.T("Matches"), value = Webhook.T("MatchesValue", Matches, Wins, Matches - Wins), inline = true },
        { name = Webhook.T("Balances"), value = table.concat(Balance, "\n") },
        { name = Webhook.T("SessionChanges"), value = Webhook.DiffBlock(Webhook.Diff(Session.Shot, Shot), Webhook.T("NoChanges")) },
    }
    local Description = "**" .. Webhook.T("Player") .. ":** " .. Webhook.PlayerName() .. (Level and ("  |  " .. Level) or "")
    Webhook.Send(Force and "Test" or "Session Summary", Webhook.Embed(Webhook.T("SummaryTitle"), Webhook.Colors.Info, Description, Fields))
end

function Webhook.Test()
    local Enabled = { }
    for _, Event in ipairs(Settings().WebhookEvents or { }) do table.insert(Enabled, Webhook.TrEvent(Event)) end
    local Embed = Webhook.Embed(Webhook.T("TestTitle"), Webhook.Colors.Info,
        Webhook.T("TestBody") .. "\n\n**" .. Webhook.T("Player") .. ":** " .. Webhook.PlayerName(), {
            { name = Webhook.T("Enabled"), value = #Enabled > 0 and table.concat(Enabled, ", ") or "-" },
        })
    return Webhook.Post({ username = "Valkyrie Hub", content = Webhook.Content("Test"), embeds = { Embed } })
end

-- ระบบหยุดเอง (StopToggle) - ส่งทันทีพร้อมของที่เปลี่ยนตั้งแต่รายงานก่อน
function Webhook.Stopped(Message)
    if not (Message and Webhook.Wanted("Auto Stopped")) then return end
    -- ข้อความหยุดเป็นอังกฤษจากโค้ด: ภาษาไทย = ใช้คำแปลของ hub (มีเมื่อ hub ตั้งไทยอยู่)
    local Text = tostring(Message)
    if Webhook.Lang() == "th" then
        local Ok, Out = pcall(Library.Tr, Text)
        if Ok and type(Out) == "string" then Text = Out end
    end
    Webhook.Push("Auto Stopped", "stop:" .. tostring(Message), "**" .. Text .. "**", { Urgent = true, Color = Webhook.Colors.Warning })
end

-- ---- เธรดหลัก: ส่งคิว / รวบรายงาน / ดูจบแมตช์ / สรุปรอบ ----

function Webhook.Start()
    if Webhook.Started then return end
    Webhook.Started = true

    -- หลุดเกม: ส่งทันที (เกมกำลังปิด รอคิวไม่ได้)
    pcall(function()
        TrackConnection(game:GetService("GuiService").ErrorMessageChanged:Connect(function(Message)
            if getgenv().ValkyrieSession ~= SessionToken or Webhook.Disconnected then return end
            if type(Message) ~= "string" or Message == "" or not Webhook.Wanted("Disconnected") then return end
            -- ปิดเกม / รีสตาร์ท Roblox เอง (อัปเดต) = ไม่ใช่โดนเตะ ไม่ต้องแจ้ง
            if Message:find("ClientInitiated") then return end
            Webhook.Disconnected = true
            task.spawn(function()
                Webhook.Send("Disconnected", Webhook.Embed(Webhook.T("DisconnectTitle"), Webhook.Colors.Defeat,
                    Webhook.T("DisconnectBody") .. "\n\n**" .. Webhook.T("Player") .. ":** " .. Webhook.PlayerName(), {
                        { name = Webhook.T("Message"), value = "```\n" .. Message:sub(1, 900) .. "\n```" },
                        { name = Webhook.T("Server"), value = "`" .. tostring(game.JobId) .. "`" },
                    }), true)
            end)
        end))
    end)

    task.spawn(function()
        if not ResolveScale() then return end
        while getgenv().ValkyrieSession == SessionToken and not Webhook.Session do
            local Shot = Webhook.Snapshot()
            if Shot then
                Webhook.Base, Webhook.MatchBase = Shot, Shot
                local Last = Webhook.LastMatch(Shot)
                Webhook.LastMatchTime = Last and Last.time
                Webhook.MatchStart = os.clock()
                Webhook.LoadSession(Shot)
            else
                task.wait(2)
            end
        end

        local LastCheck = 0
        local function Tick()
            -- คิวส่ง (เว้น 1.2 วิ ไม่ชน rate limit ของ Discord)
            local Payload = table.remove(Webhook.Queue, 1)
            if Payload then
                Webhook.Post(Payload)
                task.wait(1.2)
            else
                task.wait(0.5)
            end

            local Now = os.clock()
            if Webhook.FirstAt and ((Webhook.Urgent and Now - Webhook.LastAt > 1.5) or Now - Webhook.LastAt > 5 or Now - Webhook.FirstAt > 60) then
                Webhook.Flush()
            end

            -- จบแมตช์ = matchHistory มีรายการใหม่ (time เปลี่ยน) / เช็คทุก 2 วิ ในแมตช์
            if IsMatch and Now - LastCheck > 2 then
                LastCheck = Now
                local Shot = Webhook.Snapshot()
                local Last = Shot and Webhook.LastMatch(Shot)
                if Last and Last.time ~= Webhook.LastMatchTime then
                    Webhook.LastMatchTime = Last.time
                    Webhook.MatchTook = Now - (Webhook.MatchStart or Now)
                    -- runStore: chapter = Act / startedAt-finishedAt = เวลาจริงฝั่ง server (hub โหลดกลางแมตช์ก็ถูก)
                    pcall(function()
                        local State = Webhook.Config("game", "stores", "runStore").store.state
                        local Chapter = tonumber(State.chapter:get())
                        Webhook.Act = Chapter and Chapter > 0 and Chapter or nil
                        local Started, Finished = tonumber(State.startedAt:get()), tonumber(State.finishedAt:get())
                        if Started then Webhook.MatchTook = (Finished or workspace:GetServerTimeNow()) - Started end
                    end)
                    Webhook.MatchEnded(Last, Shot)
                end
            end

            local Every = tonumber(Settings().WebhookSummaryMinutes) or 0
            if Every > 0 and Webhook.Session and os.time() - (Webhook.Session.LastSummary or 0) >= Every * 60 then
                Webhook.Summary(false)
            end
        end
        -- error รอบเดียวห้ามฆ่าทั้งเธรด (เงียบหายไม่มีแจ้งเตือนอีกเลย)
        while getgenv().ValkyrieSession == SessionToken do
            local Ok, Err = pcall(Tick)
            if not Ok then
                warn("[Valkyrie Webhook] " .. tostring(Err))
                task.wait(2)
            end
        end
    end)
end

-- ยิง packet แล้วรอผลที่ requestId ตรงกัน (ไม่ตอบ 6 วิ = nil)
local RequestId = 40000
local function Request(SendName, ReplyName, Data, Packets)
    Packets = Packets or Lobby.Packets
    RequestId = RequestId % 65535 + 1
    local Id = RequestId
    Data.requestId = Id
    local Reply = nil
    local Hook = Packets[ReplyName]:on(function(Result)
        if type(Result) == "table" and Result.requestId == Id then Reply = Result end
    end)
    Packets[SendName]:fire(Data)
    local Waited = 0
    while not Reply and Waited < 6 do Waited = Waited + task.wait(0.1) end
    pcall(function() if type(Hook) == "function" then Hook() else Hook:Disconnect() end end)
    Webhook.OnRequest(SendName, Data, Reply)
    return Reply
end

-- ปิด toggle จากเธรดงาน (ผ่านคิว UI) + แจ้งเตือน
local function StopToggle(Flag, Key, Message)
    Settings()[Key] = false
    SaveSetting()
    Webhook.Stopped(Message)
    OnUi(function()
        local Set = Library.SetFlags[Flag]
        if Set then Set(false) end
        if Message then Library:Notify("Valkyrie Hub", Message, 6) end
    end)
end

-- เป้าหมายของ Auto Summon: ความหายากถึงที่ตั้ง หรือได้ตัวที่เลือก
local function SummonHit(Character, Rarity)
    local C = Settings()
    if Rarity and table.find(C.SummonStopRarities or { }, RarityLabel(Rarity)) then return true end
    local Entry = PoolByName(Character)
    for _, Name in ipairs(C.SummonStopCharacters or { }) do
        if Entry and (Name == Entry.Name or Name == Entry.Id) then return true end
    end
    return false
end

local function RarityOf(Character)
    local Entry = PoolByName(Character)
    return Entry and Entry.Rarity
end

-- คูลดาวน์ปุ่มสุ่มของเกม (RollWindowHandler.GetRollCooldownLeft): 1.8 วิ / gamepass InstantSpins 1.05 วิ นับจากตอนส่ง
local function RollCooldown()
    local Ok, Owned = pcall(function() return Lobby.Perks.Owns(LocalPlayer, "InstantSpins") end)
    return (Ok and Owned) and 1.05 or 1.8
end

local function SummonLoop()
    local Slot = tonumber(Settings().SummonSlot) or 1

    -- ช่องนี้มีตัวที่ต้องการอยู่แล้ว = ไม่สุ่มทับ
    local Data = SlotState(Slot)
    if not (Data and Data.Unlocked) then
        return StopToggle("AZAutoSummon", "AutoSummon", "Summon: slot " .. Slot .. " is locked")
    end
    if Data.Favourite then
        return StopToggle("AZAutoSummon", "AutoSummon", "Summon: slot " .. Slot .. " is favourited - unfavourite it first")
    end
    if Data.Character ~= "" and SummonHit(Data.Character, RarityOf(Data.Character)) then
        return StopToggle("AZAutoSummon", "AutoSummon", "Summon: slot " .. Slot .. " already has " .. (PoolByName(Data.Character) or { Name = Data.Character }).Name)
    end

    while Settings().AutoSummon and getgenv().ValkyrieSession == SessionToken do
        local Lucky = Settings().SummonSpinType == "Lucky Spin"
        local Currency
        if Lucky then
            Currency = Balance("luckySpins") >= 1 and "luckySpins" or nil
        elseif Settings().SummonCurrency == "Coin" then
            Currency = Balance("money") >= 500 and "money" or nil
        else
            Currency = Balance("rolls") >= 1 and "rolls" or nil
        end
        if not Currency then
            local Reason = Lucky and "Summon: out of Lucky Spins"
                or (Settings().SummonCurrency == "Coin" and "Summon: not enough coins (500 per roll)" or "Summon: out of Rolls")
            return StopToggle("AZAutoSummon", "AutoSummon", Reason)
        end

        local SentAt = os.clock()
        local Reply = Request("rollCharacter", "characterRolled", {
            spinType = Lucky and "Lucky" or "Normal",
            paymentCurrency = Currency,
            slot = Slot,
        })

        if Reply and Reply.success then
            if SummonHit(Reply.character, Reply.rarity) then
                local Entry = PoolByName(Reply.character)
                return StopToggle("AZAutoSummon", "AutoSummon", "Summon: got " .. (Entry and Entry.Name or Reply.character) .. " (" .. tostring(RarityLabel(Reply.rarity)) .. ")")
            end
        elseif Reply and (tostring(Reply.reason):lower():find("cooldown") or tostring(Reply.reason):lower():find("wait")) then
            -- server ตอบ "Roll is on cooldown" (วัดสด: ยิงห่าง 1 วิ) = ลองใหม่อีกนิด ไม่ปิด toggle
            -- เดิมเช็คแค่คำว่า "wait" = ข้อความนี้ถูกนับเป็น error แล้วปิด Auto Summon (ผู้ใช้ 2026-10-06)
            SentAt = os.clock() - RollCooldown() + 0.2
        elseif Reply then
            return StopToggle("AZAutoSummon", "AutoSummon", "Summon: " .. tostring(Reply.reason))
        end

        -- หน่วงเท่าปุ่มของเกม นับจากตอนส่ง (เดิมรอ server ตอบก่อนแล้วรออีก 1.85 วิ = ช้ากว่าเกมเท่าเวลาตอบทุกรอบ)
        -- +0.1 เผื่อเน็ตแกว่ง (server นับจากตอนได้รับ)
        task.wait(math.max(RollCooldown() + 0.1 - (os.clock() - SentAt), 0))
    end
end

local function TraitLoop()
    -- หน่วงระหว่างสุ่ม: เกมเว้น 0.8-0.9 วิ นับจากตอนส่ง (TraitRerollWindowHandler: 0.8 - (os.clock() - LastRequestAt))
    local TraitCooldown = 0.85
    local Character = Settings().TraitCharacter
    if type(Character) ~= "string" or Character == "" then
        return StopToggle("AZAutoTraitReroll", "AutoTraitReroll", "Trait Reroll: pick a character first")
    end

    local function Keep(TraitId)
        local Entry = TraitById(TraitId)
        if not Entry then return false end
        return table.find(Settings().TraitKeep or { }, Entry.Name) ~= nil
    end

    if #(Settings().TraitKeep or { }) == 0 then
        return StopToggle("AZAutoTraitReroll", "AutoTraitReroll", "Trait Reroll: pick at least one trait to keep")
    end
    if Keep(CurrentTrait(Character)) then
        return StopToggle("AZAutoTraitReroll", "AutoTraitReroll", "Trait Reroll: already has " .. TraitById(CurrentTrait(Character)).Name)
    end
    if not table.find(OwnedCharacters(), Character) then
        return StopToggle("AZAutoTraitReroll", "AutoTraitReroll", "Trait Reroll: " .. tostring(Character) .. " is not in an unlocked slot")
    end

    while Settings().AutoTraitReroll and getgenv().ValkyrieSession == SessionToken do
        if Balance("traitRerolls") < 1 then
            return StopToggle("AZAutoTraitReroll", "AutoTraitReroll", "Trait Reroll: out of rerolls")
        end

        local SentAt = os.clock()
        local Reply = Request("rollTrait", "traitRolled", { character = Character })
        if Reply and Reply.success then
            if Keep(Reply.traitId) then
                return StopToggle("AZAutoTraitReroll", "AutoTraitReroll", "Trait Reroll: got " .. TraitById(Reply.traitId).Name)
            end
        elseif Reply and (tostring(Reply.reason):lower():find("wait") or tostring(Reply.reason):lower():find("cooldown")) then
            -- "Roll is on cooldown" = เร็วไปนิด ลองใหม่อีก 0.2 วิ (ไม่ปิด toggle)
            SentAt = os.clock() - TraitCooldown + 0.2
        elseif Reply then
            return StopToggle("AZAutoTraitReroll", "AutoTraitReroll", "Trait Reroll: " .. tostring(Reply.reason))
        end

        -- นับจากตอนส่ง (เดิมรอ server ตอบแล้วรออีก 1.85 วิ = ช้ากว่าเกมเกินเท่าตัว - ผู้ใช้ 2026-10-12)
        task.wait(math.max(TraitCooldown - (os.clock() - SentAt), 0))
    end
end

local function EmoteLoop()
    while Settings().AutoEmote and getgenv().ValkyrieSession == SessionToken do
        if Balance("rolls") < 5 then
            task.wait(5) -- รอ rolls เข้ามา (ไม่ปิด toggle)
        else
            local Reply = Request("rollEmote", "emoteRolled", { })
            if Reply and not Reply.success and not (tostring(Reply.reason):lower():find("wait") or tostring(Reply.reason):lower():find("cooldown")) then
                task.wait(5)
            end
            task.wait(1.85)
        end
    end
end

local function GemLoop()
    while Settings().AutoConvertGems and getgenv().ValkyrieSession == SessionToken do
        local Cost = 100
        if Lobby.Perks then
            local Ok, Value = pcall(Lobby.Perks.GetSpinCost, LocalPlayer, 100)
            if Ok and tonumber(Value) and Value > 0 then Cost = Value end
        end
        local Amount = math.floor((Balance("gems") - (tonumber(Settings().KeepGems) or 0)) / Cost)
        if Amount >= 1 then
            Request("convertGemsToLuckySpins", "luckySpinConversionResult", { amount = Amount })
        end
        task.wait(3)
    end
end

-- ==== Auto Character ====
-- evolveCharacter(characterId) -> evolveCharacterResult{character, status} (ไม่มี requestId / ของไม่พอ = server เงียบ)
--   ของที่ต้องใช้ = evolutionConfig[c].ultimate "itemId,amount|..." (กระเป๋า account.material[itemId]) + currencies
-- purchaseCharacterSkill{character, branch, tier, requestId} (skillTreePackets) ต้องซื้อเรียง tier ทีละขั้น
--   token = level ตัวละคร (จาก Xp) - ราคาที่ใช้ไปแล้ว (tier 2-5 = 1/5/9/11)
-- unlockCharacterSlot{slot} ใช้เงิน economyConfig.characterSlotUnlockCosts (2 = 25k / 3 = 100k / 4 = 1M)
-- equipCharacterSlot{slot, gameSlot} / setCharacterSlotFavourite{slot, favourite} -> characterSlotActionResult
local SkillBranches = { "ATK", "CRIT", "DEF", "SPD" }

local function AccountTable()
    local Ok, Data = pcall(function() return Lobby.Account.getLocalPlayerAccount():toTable() end)
    return Ok and type(Data) == "table" and Data or nil
end

-- ช่องที่ปลดแล้วและมีตัว: { Slot, Character, Favourite, Rank, Awakened, Xp }
local function OwnedSlots()
    local Data = AccountTable()
    local List = { }
    for Slot = 1, Evo.SlotCount do
        local Entry = SlotState(Slot)
        if Entry and Entry.Unlocked and type(Entry.Character) == "string" and Entry.Character ~= "" then
            local Info = Data and Data.CharactersData and Data.CharactersData[Entry.Character] or { }
            table.insert(List, {
                Slot = Slot,
                Character = Entry.Character,
                Favourite = Entry.Favourite,
                Rank = RarityRank[RarityOf(Entry.Character) or ""] or 0,
                Awakened = Info.IsUltimateUnlocked == true,
                Xp = tonumber(Info.Progression and Info.Progression.Xp) or 0,
            })
        end
    end
    return List
end

-- ของ evolve ครบไหม (ไอเทมในกระเป๋า + สกุลเงิน)
local function CanEvolve(Character, Data)
    local Config = Lobby.Evolution and Lobby.Evolution[Character]
    if not (Config and Data) then return false end
    -- ของขาดแต่มีอาหาร Trials tier เดียวกันพอ = กดได้ (เกมใช้อาหารแทนให้เอง - Evo.Short)
    Evo.Load()
    local Need = { }
    for Item, Amount in tostring(Config.ultimate or ""):gmatch("(%d+),(%d+)") do
        Need[Item] = (Need[Item] or 0) + tonumber(Amount)
    end
    if next(Evo.Short(Need, Data.material)) then return false end
    for _, Cost in ipairs(Config.currencies or { }) do
        if Balance(Cost.currency) < (tonumber(Cost.amount) or 0) then return false end
    end
    return true
end

local function EvolveLoop()
    while Settings().AutoEvolve and getgenv().ValkyrieSession == SessionToken do
        local Data = AccountTable()
        for _, Entry in ipairs(OwnedSlots()) do
            if not Entry.Awakened and CanEvolve(Entry.Character, Data) then
                local Status = nil
                local Hook = Lobby.Packets.evolveCharacterResult:on(function(Result)
                    if type(Result) == "table" and Result.character == Entry.Character then Status = Result.status end
                end)
                Lobby.Packets.evolveCharacter:fire(Entry.Character)
                local Waited = 0
                while not Status and Waited < 5 do Waited = Waited + task.wait(0.1) end
                pcall(function() if type(Hook) == "function" then Hook() else Hook:Disconnect() end end)
                if Status == "success" then
                    local Pool = PoolByName(Entry.Character)
                    Webhook.Push("Evolution", "evolve:" .. Entry.Character, Webhook.T("Evolved", Pool and Pool.Name or Entry.Character), { Urgent = true })
                    OnUi(function() Library:Notify("Valkyrie Hub", "Evolve: " .. (Pool and Pool.Name or Entry.Character) .. " ultimate unlocked", 6) end)
                end
                Data = AccountTable()
            elseif Entry.Awakened then
                Evo.MonarchStep(Entry.Character, Data)
            end
        end
        task.wait(5)
    end
end

-- ซื้อ tier ถัดไปที่ถูกสุดในสาขาที่เลือก (ไล่ทุกตัวที่มี) จน token ไม่พอ
local function SkillLoop()
    if not (Lobby.SkillPackets and Lobby.Progression and Lobby.SkillTree) then
        return StopToggle("AZAutoBuySkill", "AutoBuySkill", "Skill Tree: game modules not found")
    end
    while Settings().AutoBuySkill and getgenv().ValkyrieSession == SessionToken do
        local Bought = false
        local Data = AccountTable()
        for _, Entry in ipairs(OwnedSlots()) do
            local Info = Data and Data.CharactersData and Data.CharactersData[Entry.Character]
            local Tree = Lobby.SkillTree.characters and Lobby.SkillTree.characters[Entry.Character]
            local Skills = Info and Info.Progression and Info.Progression.Skills
            if Tree and Skills then
                local Ok, Tokens = pcall(Lobby.Progression.getAvailableTokens, Entry.Character, Info.Progression.Xp, Skills)
                Tokens = Ok and tonumber(Tokens) or 0

                local Best, BestTier, BestCost = nil, nil, math.huge
                for _, Branch in ipairs(Settings().SkillBranches or { }) do
                    local Tier = (tonumber(Skills[Branch]) or 1) + 1
                    local Node = Tree.branches[Branch] and Tree.branches[Branch].tiers[Tier]
                    if Node and Node.cost <= Tokens and Node.cost < BestCost then
                        Best, BestTier, BestCost = Branch, Tier, Node.cost
                    end
                end

                if Best then
                    local Reply = Request("purchaseCharacterSkill", "characterSkillPurchaseResult", {
                        character = Entry.Character,
                        branch = Best,
                        tier = BestTier,
                    }, Lobby.SkillPackets)
                    if Reply and Reply.success then Bought = true end
                    task.wait(0.5)
                end
            end
        end
        task.wait(Bought and 0.5 or 5)
    end
end

local function UnlockSlotLoop()
    local Costs = Lobby.Economy and Lobby.Economy.characterSlotUnlockCosts or { [2] = 25000, [3] = 100000, [4] = 1000000 }
    while Settings().AutoUnlockSlot and getgenv().ValkyrieSession == SessionToken do
        local Next = nil
        for Slot = 2, Evo.SlotCount do
            local Entry = SlotState(Slot)
            if Entry and not Entry.Unlocked then Next = Slot break end
        end
        -- ช่อง 12-15 ไม่มีราคาเป็นเงินใน characterSlotUnlockCosts (อัปเดต 3: ช่อง 2-11 = 25k ... 50M)
        if Next and not Costs[Next] then
            return StopToggle("AZAutoUnlockSlot", "AutoUnlockSlot", "Unlock Slot: slot " .. Next .. " can't be bought with coins")
        end
        if not Next then
            return StopToggle("AZAutoUnlockSlot", "AutoUnlockSlot", "Unlock Slot: every slot is unlocked")
        end
        if Balance("money") >= (Costs[Next] or math.huge) then
            local Reply = Request("unlockCharacterSlot", "characterSlotActionResult", { slot = Next })
            if Reply and Reply.success then
                OnUi(function() Library:Notify("Valkyrie Hub", "Unlocked character slot " .. Next, 6) end)
            end
        end
        task.wait(5)
    end
end

-- Synergy (assets.config.synergyConfig): ทีม 2 ตัวได้โบนัสถาวรตามคู่ / คู่อื่นทั้งหมด = "Tag Team" ดาเมจ +5%
-- Value = แต้มเทียบคู่ (ดาเมจ 1 / cooldown 0.8 / HP 0.3 / ความเร็ว 0.3 / ult charge 0.25 ต่อ %) - เรียงจากคุ้มสุด
local SynergyPairs = {
    { Name = "Monster Kings", A = "sukuna", B = "alucard", Bonus = "+10% Damage", Value = 10 },
    { Name = "Battle Prodigies", A = "goku", B = "killua", Bonus = "-10% Cooldown", Value = 8 },
    { Name = "Oath of Steel", A = "guts", B = "saber", Bonus = "+5% Damage, +8% Health", Value = 7.4 },
    { Name = "Blade Dancers", A = "miyabi", B = "saber", Bonus = "+8% Speed, -5% Cooldown", Value = 6.4 },
    { Name = "Smiling Killers", A = "juuzou", B = "nagumo", Bonus = "+20% Ult Charge", Value = 5 },
    { Name = "Straw Hat Legacy", A = "luffy", B = "shanks", Bonus = "+15% Health", Value = 4.5 },
}
local GenericSynergy = { Name = "Tag Team", Bonus = "+5% Damage", Value = 5 }

local function SynergyOf(A, B)
    for _, Pair in ipairs(SynergyPairs) do
        if (Pair.A == A and Pair.B == B) or (Pair.A == B and Pair.B == A) then return Pair end
    end
    return GenericSynergy
end

-- คะแนนตัว = หายาก x10 + ปลด ultimate 6 / คะแนนทีม = 2 ตัว + synergy x3
-- (Monster Kings Arcane+Mythic 100 ชนะ Arcane+Arcane ทั่วไป 95 / คู่ Epic ไม่ชนะตัวหายากกว่า)
local function CharacterScore(Entry)
    return Entry.Rank * 10 + (Entry.Awakened and 6 or 0)
end

-- ทีมดีสุดจากตัวที่มี: { First, Second, Synergy } (First = คะแนนตัวสูงกว่า ออกก่อน)
local function BestTeam(List)
    List = List or OwnedSlots()
    local Best, BestScore, BestXp = nil, -math.huge, -1
    for I = 1, #List do
        for J = I + 1, #List do
            local A, B = List[I], List[J]
            if A.Character ~= B.Character then
                local Synergy = SynergyOf(A.Character, B.Character)
                local Score = CharacterScore(A) + CharacterScore(B) + Synergy.Value * 3
                local Xp = A.Xp + B.Xp
                if Score > BestScore or (Score == BestScore and Xp > BestXp) then
                    if CharacterScore(B) > CharacterScore(A) or (CharacterScore(B) == CharacterScore(A) and B.Xp > A.Xp) then A, B = B, A end
                    Best, BestScore, BestXp = { First = A, Second = B, Synergy = Synergy }, Score, Xp
                end
            end
        end
    end
    if not Best and List[1] then
        -- มีตัวเดียว (หรือซ้ำกันหมด) = ใส่ตัวดีสุดช่องแรก
        table.sort(List, function(A, B) return CharacterScore(A) > CharacterScore(B) end)
        Best = { First = List[1] }
    end
    return Best
end

-- ใส่ทีมตาม BestTeam / ทีมเดิมตรงแล้ว (สลับลำดับก็นับ) = ไม่ทำอะไร / ตัวที่อยู่ในทีมอยู่แล้วคงช่องเดิม เปลี่ยนแค่อีกช่อง
local function EquipBestLoop()
    local Failed = { }
    while Settings().AutoEquipBest and getgenv().ValkyrieSession == SessionToken do
        local Team = BestTeam()
        local Data = AccountTable()
        local Equipped = Data and Data.EquippedCharacterSlots or { }
        if Team then
            local Want = { [1] = Team.First and Team.First.Slot, [2] = Team.Second and Team.Second.Slot }
            local Now = { [1] = tonumber(Equipped.Slot1), [2] = tonumber(Equipped.Slot2) }
            if Want[1] == Now[2] or Want[2] == Now[1] then Want[1], Want[2] = Want[2], Want[1] end
            for GameSlot = 1, 2 do
                local Slot = Want[GameSlot]
                local Key = Slot and (Slot .. ":" .. GameSlot)
                if Slot and Now[GameSlot] ~= Slot and (os.clock() - (Failed[Key] or -60)) > 60 then
                    local Reply = Request("equipCharacterSlot", "characterSlotActionResult", { slot = Slot, gameSlot = GameSlot })
                    if not (Reply and Reply.success) then Failed[Key] = os.clock() end
                    task.wait(0.5)
                    Data = AccountTable()
                    Equipped = Data and Data.EquippedCharacterSlots or Equipped
                    Now = { [1] = tonumber(Equipped.Slot1), [2] = tonumber(Equipped.Slot2) }
                end
            end
        end
        task.wait(5)
    end
end

-- ตัวที่ไม่ได้มาจากตู้ (RaidUnitConfig: Raid = Jinwoo / Hu Tao, Trials = Astra Yao / Frieren / Ye-0, Leaderboard = Rin)
-- ได้มาแล้วไปรอใน storage = achievements.progress["storage.<id>"] (จำนวน) ค้างไว้จนกดใส่ช่องเองในหน้าต่าง Storage
-- placeStoredUnit{character, slot, requestId} -> storedUnitPlaced (UnitStorageWindowHandler.Send) = แทนตัวในช่องนั้น
-- ช่องที่ใส่: ช่องว่างที่ปลดแล้วก่อน / ไม่มี = ช่องที่อ่อนสุด (ระดับต่ำกว่าตัวที่ได้ -> ยังไม่ปลด ult -> XP น้อย)
-- ไม่แตะช่องที่ล็อก (Favourite - เกมไม่ให้ใส่) / มีตัวนั้นในช่องอยู่แล้ว = ไม่ใส่ซ้ำ
local function StoredSpot(Unit)
    local Rank = RarityRank[RarityOf(Unit) or ""] or 5
    local Best, BestEntry = nil, nil
    for Slot = 1, Evo.SlotCount do
        local State = SlotState(Slot)
        if State and State.Unlocked and State.Character == Unit then return nil end
        if State and State.Unlocked and not State.Favourite and (State.Character == nil or State.Character == "") then
            return Slot
        end
    end
    for _, Entry in ipairs(OwnedSlots()) do
        if not Entry.Favourite and Entry.Rank < Rank then
            local Weaker = not BestEntry or Entry.Rank < BestEntry.Rank
                or (Entry.Rank == BestEntry.Rank and (Entry.Awakened == false and BestEntry.Awakened == true
                    or (Entry.Awakened == BestEntry.Awakened and Entry.Xp < BestEntry.Xp)))
            if Weaker then Best, BestEntry = Entry.Slot, Entry end
        end
    end
    return Best
end

local function PlaceStoredLoop()
    local Units = SafeRequire(ReplicatedStorage, "assets", "config", "RaidUnitConfig")
    local Prefix = Units and Units.StoragePrefix or "storage."
    local Failed = { }
    while Settings().AutoPlaceStored and getgenv().ValkyrieSession == SessionToken do
        local Data = AccountTable()
        local Progress = Data and Data.achievements and Data.achievements.progress or { }
        for Key, Count in pairs(Progress) do
            local Unit = type(Key) == "string" and Key:sub(1, #Prefix) == Prefix and Key:sub(#Prefix + 1) or nil
            if Unit and (tonumber(Count) or 0) > 0 and os.clock() - (Failed[Unit] or -60) > 60 then
                local Slot = StoredSpot(Unit)
                if Slot then
                    local Reply = Request("placeStoredUnit", "storedUnitPlaced", { character = Unit, slot = Slot })
                    local Entry = PoolByName(Unit)
                    local Name = Entry and Entry.Name or Unit
                    if Reply and Reply.success ~= false then
                        Webhook.Push("Character Upgrades", "stored:" .. Unit, Webhook.T("PlacedStored", Name, Slot), { Urgent = true })
                        OnUi(function() Library:Notify("Valkyrie Hub", ("Placed %s into slot %d"):format(Name, Slot), 6) end)
                    else
                        Failed[Unit] = os.clock()
                        local Reason = Reply and tostring(Reply.reason or "rejected") or "no reply"
                        OnUi(function() Library:Notify("Valkyrie Hub", ("Place %s: %s"):format(Name, Reason), 6) end)
                    end
                    task.wait(1)
                    break -- อ่านช่องใหม่ก่อนใส่ตัวถัดไป
                end
            end
        end
        task.wait(5)
    end
end

-- ล็อก (Favourite) ช่องที่ตัวหายากถึงที่เลือก - ล็อกอย่างเดียว ไม่ปลดล็อกที่ผู้เล่นล็อกเอง
local function LockLoop()
    while Settings().AutoLock and getgenv().ValkyrieSession == SessionToken do
        for _, Entry in ipairs(OwnedSlots()) do
            local Rarity = RarityOf(Entry.Character)
            if not Entry.Favourite and Rarity and table.find(Settings().LockRarities or { }, RarityLabel(Rarity)) then
                Request("setCharacterSlotFavourite", "characterSlotActionResult", { slot = Entry.Slot, favourite = true })
                task.wait(0.5)
            end
        end
        task.wait(2)
    end
end

-- ซื้อของที่เป้ายังขาดจากร้านวันนี้ (เท่าที่ขาด / เหลือในร้าน / เงินพอ)
local function ShopLeft(Day, Item)
    local Bought = 0
    pcall(function()
        local Progress = AccountState().achievements.progress:get(Evo.Shop.GetKey(Day, Item))
        Bought = tonumber(Progress and Progress:get()) or 0
    end)
    return math.max(Evo.Shop.GetCap(Item) - Bought, 0)
end

local function BuyMaterialLoop()
    local Failed = { }
    while Settings().AutoBuyMaterials and getgenv().ValkyrieSession == SessionToken do
        if Evo.Load() and Evo.Shop then
            local Data = AccountTable()
            local Target = Data and Evo.Target(Data)
            local Day = Evo.Shop.GetDay(workspace:GetServerTimeNow())
            for Item, Missing in pairs(Target and Evo.Missing(Data, Target) or { }) do
                local Price = Evo.Shop.GetPrice(Item)
                local Key = Day .. ":" .. Item
                if Price and Evo.Shop.IsInStock(Item, Day) and not Failed[Key] then
                    local Amount = math.min(Missing, ShopLeft(Day, Item), math.floor(Balance("money") / Price))
                    if Amount > 0 then
                        local Reply = Request("buyMaterial", "materialShopResult", { itemId = Item, amount = Amount })
                        if Reply and Reply.success then
                            OnUi(function() Library:Notify("Valkyrie Hub", ("Bought %dx %s"):format(Amount, Evo.Name(Item)), 5) end)
                        else
                            Failed[Key] = true -- วันนี้ไม่ลองซ้ำ
                        end
                        task.wait(0.5)
                    end
                end
            end
        end
        task.wait(10)
    end
end

-- แลกของเกิน (ส่วนที่ไม่มีตัวไหนต้องใช้) เป็นของที่เป้ายังขาด: tier ต่ำกว่า 5:1 ก่อน แล้วค่อย tier เดียวกัน 3:1
local function ConvertMaterialLoop()
    while Settings().AutoConvertMaterials and getgenv().ValkyrieSession == SessionToken do
        local Done = false
        if Evo.Load() and Evo.Shop then
            local Data = AccountTable()
            local Target = Data and Evo.Target(Data)
            local Bag = Data and Data.material or { }
            local Reserved = Evo.Reserved(Data, Target)
            for Item, Missing in pairs(Target and Evo.Missing(Data, Target) or { }) do
                for _, Source in ipairs(Evo.Shop.GetSources(Item)) do
                    local Spare = (tonumber(Bag[tostring(Source.Id)]) or 0) - (Reserved[tostring(Source.Id)] or 0)
                    local Amount = math.min(Missing, math.floor(Spare / Source.Rate), Evo.Shop.MaxConvert or 100)
                    if Amount > 0 then
                        local Reply = Request("convertMaterial", "materialShopResult", { source = tostring(Source.Id), target = Item, amount = Amount })
                        if Reply and Reply.success then
                            Done = true
                            OnUi(function()
                                Library:Notify("Valkyrie Hub", ("Converted %dx %s -> %dx %s"):format(Amount * Source.Rate, Evo.Name(Source.Id), Amount, Evo.Name(Item)), 5)
                            end)
                        end
                        task.wait(0.5)
                        break -- อ่านกระเป๋าใหม่ก่อนแลกต่อ
                    end
                end
                if Done then break end
            end
        end
        task.wait(Done and 1 or 10)
    end
end

-- ==== Auto Crafting ====
-- craftAccessory(recipeKey) - recipeKey = accessoryCraftConfig key / ไอเทมที่ได้ = [key].CarftID (สะกดตามเกม)
--   1-14 = itemId - 100 แต่อัปเดต Void Arbiter (2026-10-11) เพิ่ม 15-27 ที่เลขไม่ตรง (15 = 118, 25 = 116, 27 = 128) -> จำ Recipe ไว้ทุกตัว
--   ของที่ใช้ = accessoryCraftConfig[key].Misc "materialId,amount|..." / ผลส่งทาง showNotification
--   ของที่คราฟต์แล้วอยู่ account.accessory[itemId] = จำนวน
-- setEquippedAccessory(itemId) ใส่ลงช่องของมันเอง (Head / Face / Neck / Back - ดู EquipItemLoop)
-- รายการ = accessoryCraftConfig + accessoryConfig (Damage % = buff Damage) วันที่วัด
local AccessoryList = {
    { Id = "101", Recipe = "1", Name = "Leaf Shinobi Headband", Tier = 1, Damage = 5 },
    { Id = "102", Recipe = "2", Name = "Gentleman's Top Hat", Tier = 1, Damage = 3 },
    { Id = "103", Recipe = "3", Name = "Capsule Scarf", Tier = 1, Damage = 4 },
    { Id = "104", Recipe = "4", Name = "8th Brigade Fire Hat", Tier = 1, Damage = 7 },
    { Id = "124", Recipe = "21", Name = "Order Assassin's Tie", Tier = 1, Damage = 5 },
    { Id = "105", Recipe = "5", Name = "SunGlasses", Tier = 2, Damage = 3 },
    { Id = "106", Recipe = "6", Name = "Kitsune Mask", Tier = 2, Damage = 8 },
    { Id = "107", Recipe = "7", Name = "Diva Headphones", Tier = 2, Damage = 6 },
    { Id = "108", Recipe = "8", Name = "Panther Hollow Mask", Tier = 2, Damage = 12 },
    { Id = "118", Recipe = "15", Name = "Wangsheng Director's Hat", Tier = 2, Damage = 8 },
    { Id = "120", Recipe = "17", Name = "Void Hunter's Eye", Tier = 2, Damage = 7 },
    { Id = "125", Recipe = "22", Name = "Zoldyck Collar", Tier = 2, Damage = 6 },
    { Id = "126", Recipe = "23", Name = "Strawhat Captain's Hat", Tier = 2, Damage = 6 },
    { Id = "109", Recipe = "9", Name = "Light Admiral Cloak", Tier = 3, Damage = 14 },
    { Id = "110", Recipe = "10", Name = "Wind Spirit Wing", Tier = 3, Damage = 12 },
    { Id = "111", Recipe = "11", Name = "Dark Captain Wings", Tier = 3, Damage = 17 },
    { Id = "112", Recipe = "12", Name = "Flame Pirate Hat", Tier = 3, Damage = 11 },
    { Id = "121", Recipe = "18", Name = "Red Emperor's Cloak", Tier = 3, Damage = 14 },
    { Id = "122", Recipe = "19", Name = "Cursed King's Collar", Tier = 3, Damage = 10 },
    { Id = "123", Recipe = "20", Name = "No-Life King's Shades", Tier = 3, Damage = 12 },
    { Id = "127", Recipe = "24", Name = "Otherworld Halo", Tier = 3, Damage = 12 },
    { Id = "128", Recipe = "27", Name = "Divine General's Wheel", Tier = 3, Damage = 13 },
    { Id = "113", Recipe = "13", Name = "Blast Archer Crown", Tier = 4, Damage = 20 },
    { Id = "114", Recipe = "14", Name = "Blast Archer Wings", Tier = 4, Damage = 16 },
    { Id = "116", Recipe = "25", Name = "Astral Wings", Tier = 4, Damage = 14 },
    { Id = "117", Recipe = "26", Name = "Spectral Wings", Tier = 4, Damage = 14 },
    { Id = "119", Recipe = "16", Name = "Shadow Monarch Coat", Tier = 4, Damage = 17 },
}

local function AccessoryByName(Name)
    for _, Entry in ipairs(AccessoryList) do
        if Entry.Name == Name then return Entry end
    end
end

local function AccessoryCount(Data, Id)
    return tonumber(Data and Data.accessory and Data.accessory[Id]) or 0
end

-- วัตถุดิบตัวแรกที่ไม่พอ (nil = คราฟต์ได้)
local function MissingMaterial(RecipeKey, Data)
    local Recipe = Lobby.CraftConfig and Lobby.CraftConfig[RecipeKey]
    if not Recipe then return "unknown recipe" end
    local Bag = Data and Data.material or { }
    for Item, Amount in tostring(Recipe.Misc or ""):gmatch("(%d+),(%d+)") do
        local Have = tonumber(Bag[Item]) or 0
        if Have < tonumber(Amount) then
            local Info = Lobby.Materials and Lobby.Materials[Item]
            return (Info and Info.Name or Item) .. " " .. Have .. "/" .. Amount
        end
    end
    return nil
end

-- วัตถุดิบที่ต้องใช้คราฟต์ชิ้นที่เหลือทั้งหมด { [itemId] = จำนวนรวม } (Evo.Plan เอาไปหักกระเป๋าแล้วเลือกด่านฟาร์ม)
-- เรียกได้ทั้งในแมตช์ (อ่าน accessoryCraftConfig เอง - Lobby.CraftConfig โหลดเฉพาะ lobby)
function Evo.CraftNeed(Data)
    if not (Settings().AutoCraft and Settings().CraftFarm) then return { } end
    local Entry = AccessoryByName(Settings().CraftItem)
    Evo.CraftConfig = Evo.CraftConfig or SafeRequire(ReplicatedStorage, "assets", "config", "accessoryCraftConfig")
    local Recipe = Entry and Evo.CraftConfig and Evo.CraftConfig[Entry.Recipe]
    local Left = math.max(1, math.floor(tonumber(Settings().CraftAmount) or 1)) - (tonumber(Settings().CraftMade) or 0)
    local Need = { }
    if not Recipe or Left <= 0 then return Need end
    for Item, Amount in tostring(Recipe.Misc or ""):gmatch("(%d+),(%d+)") do
        Need[Item] = (Need[Item] or 0) + tonumber(Amount) * Left
    end
    return Need
end

-- จำนวนที่คราฟต์แล้วเก็บใน Settings (CraftMade) - Farm Missing Materials วาร์ปไปฟาร์มแล้วกลับมา = นับต่อจากเดิม
-- เปลี่ยนไอเทม / จำนวน หรือคราฟต์ครบ = เริ่มนับใหม่
local function CraftLoop()
    local Entry = AccessoryByName(Settings().CraftItem)
    if not Entry then
        return StopToggle("AZAutoCraft", "AutoCraft", "Craft: pick an item first")
    end
    local RecipeKey = Entry.Recipe
    local Target = math.max(1, math.floor(tonumber(Settings().CraftAmount) or 1))
    local Made = tonumber(Settings().CraftMade) or 0
    local Waiting = false

    while Settings().AutoCraft and getgenv().ValkyrieSession == SessionToken do
        if Made >= Target then
            Settings().CraftMade = 0
            SaveSetting()
            return StopToggle("AZAutoCraft", "AutoCraft", "Craft: made " .. Made .. "x " .. Entry.Name)
        end
        local Data = AccountTable()
        local Missing = MissingMaterial(RecipeKey, Data)
        if Missing and Settings().CraftFarm then
            -- ของไม่พอ: Auto Join สร้างห้องไปฟาร์มด่านที่ดรอปของที่ขาดเอง (Evo.Plan) / ระหว่างนี้รอ ของพอเมื่อไหร่คราฟต์ต่อ
            if not Waiting then
                Waiting = true
                local Text = "Craft: " .. Made .. "/" .. Target .. " " .. Entry.Name .. " - farming " .. Missing
                OnUi(function() Library:Notify("Valkyrie Hub", Text, 6) end)
                Join.Refresh()
            end
            task.wait(3)
            continue
        elseif Missing then
            return StopToggle("AZAutoCraft", "AutoCraft", "Craft: made " .. Made .. "x " .. Entry.Name .. " - not enough " .. Missing)
        end
        Waiting = false

        -- สำเร็จ = จำนวนในกระเป๋าเพิ่ม / ไม่สำเร็จ = เอาข้อความแจ้งเตือนของเกมมาบอก
        local Before = AccessoryCount(Data, Entry.Id)
        local Notice = nil
        local Hook = Lobby.Packets.showNotification:on(function(Result)
            if type(Result) == "table" then Notice = Result.text end
        end)
        Lobby.Packets.craftAccessory:fire(RecipeKey)
        local Waited, Crafted = 0, false
        while Waited < 4 do
            Waited = Waited + task.wait(0.2)
            if AccessoryCount(AccountTable(), Entry.Id) > Before then Crafted = true break end
        end
        pcall(function() if type(Hook) == "function" then Hook() else Hook:Disconnect() end end)

        if Crafted then
            Made = Made + 1
            Settings().CraftMade = Made
            SaveSetting()
            Webhook.Push("Crafting", "craft:" .. Entry.Id, Webhook.T("Crafted", Entry.Name))
        else
            return StopToggle("AZAutoCraft", "AutoCraft", "Craft: " .. tostring(Notice or "no response from the server"))
        end
        task.wait(0.5)
    end
end

-- อัปเดต SHADOW MONARCH: ใส่ได้ 4 ช่อง (account.equippedAccessories { Head, Face, Neck, Back } = itemId / "")
-- ช่องของไอเทม = accessorySlotConfig.GetSlot(id) / setEquippedAccessory(id) ใส่ลงช่องของมันเอง (BackpackWindowHandler.EquipItem)
-- ดีสุดต่อช่อง = Damage % มากสุด -> Tier สูงกว่า -> ผลรวม buff % มากกว่า (อ่านจาก accessoryConfig ของเกม ไอเทมใหม่ได้ด้วย)
local function EquipItemLoop()
    local Items = SafeRequire(ReplicatedStorage, "assets", "config", "accessoryConfig")
    local Slots = SafeRequire(ReplicatedStorage, "assets", "config", "accessorySlotConfig")
    if not (Items and Slots) then
        return StopToggle("AZAutoEquipItem", "AutoEquipItem", "Equip Item: game modules not found")
    end

    local function Score(Info)
        local Damage, Total = 0, 0
        for _, Buff in ipairs(Info.Buffs or { }) do
            local Value = tonumber(Buff.Percent) or 0
            Total = Total + Value
            if Buff.Type == "Damage" then Damage = Damage + Value end
        end
        return Damage, tonumber(Info.Tier) or 0, Total
    end

    local function Better(A, B)
        local DamageA, TierA, TotalA = Score(A)
        local DamageB, TierB, TotalB = Score(B)
        if DamageA ~= DamageB then return DamageA > DamageB end
        if TierA ~= TierB then return TierA > TierB end
        return TotalA > TotalB
    end

    local LastTry = { }
    while Settings().AutoEquipItem and getgenv().ValkyrieSession == SessionToken do
        local Data = AccountTable()
        local Worn = Data and type(Data.equippedAccessories) == "table" and Data.equippedAccessories or { }
        local Best = { }
        for Id, Info in pairs(Items) do
            Id = tostring(Id)
            local Ok, Slot = pcall(Slots.GetSlot, Id)
            if Ok and Slot and type(Info) == "table" and AccessoryCount(Data, Id) > 0 then
                if not Best[Slot] or Better(Info, Best[Slot].Info) then Best[Slot] = { Id = Id, Info = Info } end
            end
        end
        for Slot, Pick in pairs(Best) do
            -- ใส่อยู่แล้ว = ข้าม / ยิงซ้ำได้ทุก 10 วิ (server ไม่ตอบกลับ)
            if tostring(Worn[Slot] or "") ~= Pick.Id and os.clock() - (LastTry[Pick.Id] or -30) > 10 then
                LastTry[Pick.Id] = os.clock()
                Lobby.Packets.setEquippedAccessory:fire(Pick.Id)
                Webhook.Push("Character Upgrades", "accessory:" .. Pick.Id, Webhook.T("EquippedAccessory", Pick.Info.Name or Pick.Id, Slot))
                task.wait(0.5)
            end
        end
        task.wait(3)
    end
end

-- ==== Auto Claim ====
-- claimDailyReward(day i8) - dailyReward.rewards[day] = available / claimed / unavailable (ไม่มี packet ตอบ)
-- claimQuestReward{questId} -> questActionResult / claimAchievementReward{achievementId} -> achievementActionResult
--   ของที่รอรับ = quests|achievements.completed[id] ที่ยังไม่อยู่ใน .claimed (ครอบ Daily / Weekly / Limited ทุกหมวด)
-- claimLevelMilestone{level} -> levelMilestoneClaimed / level = levelProgression.getProgress(currencies.xp).level
--   milestone = levelMilestoneConfig.order (0, 5, 10 ...) / รับแล้ว = claimedLevelMilestones[tostring(level)]
-- Group Rewards = ProximityPrompt ใน workspace.Systems.Zones.Group (ระยะ 16, กดค้าง 0.5) ต้องไปยืนใกล้ ๆ
-- enterAfk() = วาร์ปไป AFK World (place อื่น)
-- Delivery (Heiyun): deliveryAction{action = request / claim / abandon / refresh} -> deliveryState{status, target, dailyCount, dailyLimit, reason}
--   status none -> request -> carrying (target = CrowdN ใน Systems.ScatteredNPCS ยืนที่ DeliverySpawns ใกล้ตัวนั้น) -> delivered -> claim / capped = ครบวันละ 50
-- redeemCode(code) - codesConfig มีทุกโค้ด / ผลส่งทาง showNotification ("Code \"X\" redeemed!" / "already used")
local function Unhook(Hook)
    pcall(function() if type(Hook) == "function" then Hook() else Hook:Disconnect() end end)
end

-- ไอดีที่ completed แต่ยังไม่ claimed (รองรับทั้งแบบ map id = true และ array ของ id)
local function Claimable(Group)
    local List = { }
    if type(Group) ~= "table" or type(Group.completed) ~= "table" then return List end
    local Claimed = type(Group.claimed) == "table" and Group.claimed or { }
    for Key, Value in pairs(Group.completed) do
        local Id = type(Key) == "string" and Key or (type(Value) == "string" and Value) or nil
        if Id and Value and not Claimed[Id] and not table.find(Claimed, Id) then table.insert(List, Id) end
    end
    return List
end

local function ClaimDailyLoop()
    while Settings().AutoClaimDaily and getgenv().ValkyrieSession == SessionToken do
        local Data = AccountTable()
        local Rewards = Data and Data.dailyReward and Data.dailyReward.rewards
        for Day, Status in pairs(type(Rewards) == "table" and Rewards or { }) do
            if Status == "available" and tonumber(Day) then
                Lobby.Packets.claimDailyReward:fire(tonumber(Day))
                Webhook.Push("Rewards Claimed", "daily:" .. Day, Webhook.T("ClaimedDaily", Day))
                task.wait(1)
            end
        end
        task.wait(60)
    end
end

local function ClaimQuestLoop()
    while Settings().AutoClaimQuests and getgenv().ValkyrieSession == SessionToken do
        local Data = AccountTable()
        for _, Id in ipairs(Claimable(Data and Data.quests)) do
            Request("claimQuestReward", "questActionResult", { questId = Id })
            task.wait(0.5)
        end
        task.wait(30)
    end
end

local function ClaimAchievementLoop()
    while Settings().AutoClaimAchievements and getgenv().ValkyrieSession == SessionToken do
        local Data = AccountTable()
        for _, Id in ipairs(Claimable(Data and Data.achievements)) do
            Request("claimAchievementReward", "achievementActionResult", { achievementId = Id })
            task.wait(0.5)
        end
        task.wait(30)
    end
end

local function ClaimLevelRoadLoop()
    if not (Lobby.LevelProgression and Lobby.Milestones) then
        return StopToggle("AZAutoClaimLevelRoad", "AutoClaimLevelRoad", "Level Road: game modules not found")
    end
    while Settings().AutoClaimLevelRoad and getgenv().ValkyrieSession == SessionToken do
        local Data = AccountTable()
        local Ok, Progress = pcall(Lobby.LevelProgression.getProgress, Data and Data.currencies and Data.currencies.xp or 0)
        local Level = Ok and type(Progress) == "table" and tonumber(Progress.level) or 0
        local Claimed = Data and Data.claimedLevelMilestones or { }
        for _, Milestone in ipairs(Lobby.Milestones.order or { }) do
            if Milestone > Level then break end
            if not Claimed[tostring(Milestone)] then
                Request("claimLevelMilestone", "levelMilestoneClaimed", { level = Milestone })
                task.wait(0.5)
            end
        end
        task.wait(30)
    end
end

-- ยืนที่จุดหมาย (ค้างตำแหน่งไว้จน Done() เป็นจริง หรือหมดเวลา)
local function StandAt(Position, Seconds, Done)
    local Hrp = Root()
    if Hrp and (Hrp.Position - Position).Magnitude > 3 then TweenTo(Position) end
    local Waited = 0
    while Waited < Seconds do
        local Hrp = Root()
        if Hrp then
            Hrp.AssemblyLinearVelocity = Vector3.zero
            Hrp.CFrame = CFrame.new(Position)
        end
        if Done and Done() then return true end
        Waited = Waited + task.wait(0.25)
    end
    return Done == nil
end

-- เวลากดล่าสุดเก็บลงไฟล์ (os.time) - รันสคริปต์ใหม่ / กลับจากด่าน ไม่วาปไปกดซ้ำทุกครั้ง
-- ไม่อยู่กลุ่มของเกม (game.CreatorId) = กดไม่ได้อยู่แล้ว -> ไม่วาปไปเลย
local GroupClaimedAt = { File = FolderConfiguration .. "/AnimeZero_GroupClaim_" .. LocalPlayer.Name .. ".txt" }
function GroupClaimedAt.Get()
    local Ok, Value = pcall(function() return isfile(GroupClaimedAt.File) and tonumber(readfile(GroupClaimedAt.File)) end)
    return Ok and Value or GroupClaimedAt.Memory
end
function GroupClaimedAt.Set()
    GroupClaimedAt.Memory = os.time()
    pcall(writefile, GroupClaimedAt.File, tostring(GroupClaimedAt.Memory))
end
function GroupClaimedAt.InGroup()
    if game.CreatorType ~= Enum.CreatorType.Group then return true end
    local Ok, Value = pcall(LocalPlayer.IsInGroup, LocalPlayer, game.CreatorId)
    return not Ok or Value
end

local function ClaimGroupLoop()
    while Settings().AutoClaimGroup and getgenv().ValkyrieSession == SessionToken do
        local Zone = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("Zones") and workspace.Systems.Zones:FindFirstChild("Group")
        local Prompt = Zone and Zone:FindFirstChildWhichIsA("ProximityPrompt", true)
        local Hrp = Root()
        local Last = GroupClaimedAt.Get()
        if Joining() or not (Prompt and Hrp) or (Last and os.time() - Last < 1800) then
            task.wait(10)
            continue
        end
        if not GroupClaimedAt.InGroup() then
            if not GroupClaimedAt.Warned then
                GroupClaimedAt.Warned = true
                OnUi(function() Library:Notify("Valkyrie Hub", "Group Rewards: join the game's group first", 6) end)
            end
            task.wait(60)
            continue
        end

        local Anchor = Prompt.Parent
        local Spot = (Anchor:IsA("Attachment") and Anchor.WorldPosition) or (Anchor:IsA("BasePart") and Anchor.Position) or Zone.Position
        local Back = Hrp.CFrame
        local Notice = nil
        local Hook = Lobby.Packets.showNotification:on(function(Result)
            if type(Result) == "table" and not Notice then Notice = Result.text end
        end)

        StandAt(Spot + Vector3.new(0, 2, 0), 0.5)
        if fireproximityprompt then
            pcall(fireproximityprompt, Prompt, 1)
        else
            Prompt:InputHoldBegin()
            StandAt(Spot + Vector3.new(0, 2, 0), Prompt.HoldDuration + 0.2)
            Prompt:InputHoldEnd()
        end
        StandAt(Spot + Vector3.new(0, 2, 0), 2, function() return Notice ~= nil end)
        Unhook(Hook)
        if Back then TweenTo(Back.Position) end

        GroupClaimedAt.Set()
        if Notice then
            Webhook.Push("Rewards Claimed", "group", Webhook.T("ClaimedGroup") .. ": " .. tostring(Notice))
            OnUi(function() Library:Notify("Valkyrie Hub", "Group Rewards: " .. tostring(Notice), 6) end)
        end
        task.wait(10)
    end
end

local function EnterAfkLoop()
    task.wait(5) -- เผื่อเวลาปิด toggle / ให้ระบบอื่นเริ่มก่อน
    while Settings().AutoEnterAfk and getgenv().ValkyrieSession == SessionToken do
        if not Joining() then
            Lobby.Packets.enterAfk:fire()
        end
        task.wait(30) -- วาร์ปไม่ติด = ลองใหม่
    end
end

local function DeliveryLoop()
    local State = nil
    local Hook = Lobby.Packets.deliveryState:on(function(Result)
        if type(Result) == "table" then State = Result end
    end)
    local function Act(Action)
        State = nil
        RequestId = RequestId % 65535 + 1
        Lobby.Packets.deliveryAction:fire({ action = Action, requestId = RequestId })
        local Waited = 0
        while not State and Waited < 4 do Waited = Waited + task.wait(0.1) end
        return State
    end
    local function NearGiver()
        local Npc = workspace.Systems.NPCS:FindFirstChild("Heiyun")
        if Npc then StandAt(Npc:GetPivot().Position + Npc:GetPivot().LookVector * 4, 0.5) end
    end
    local function DropSpot(Target)
        local Crowd = workspace.Systems:FindFirstChild("ScatteredNPCS") and workspace.Systems.ScatteredNPCS:FindFirstChild(Target)
        if not Crowd then return nil end
        local Position = Crowd:GetPivot().Position
        local Best, BestDistance = nil, 40
        for _, Spawn in ipairs(workspace.Systems.DeliverySpawns:GetChildren()) do
            if Spawn:IsA("BasePart") and (Spawn.Position - Position).Magnitude < BestDistance then
                Best, BestDistance = Spawn, (Spawn.Position - Position).Magnitude
            end
        end
        return (Best and Best.Position or Position) + Vector3.new(0, 3, 0)
    end

    local Hrp = Root()
    local Back = Hrp and Hrp.CFrame
    local Fails = 0
    while Settings().AutoDelivery and getgenv().ValkyrieSession == SessionToken do
        if Joining() then task.wait(5) continue end
        local Now = Act("refresh")
        if not Now then
            task.wait(5)
        elseif Now.status == "capped" then
            StopToggle("AZAutoDelivery", "AutoDelivery", ("Delivery: %d/%d runs done today"):format(Now.dailyCount or 0, Now.dailyLimit or 0))
            break
        elseif Now.status == "delivered" then
            local After = Act("claim")
            if After and After.status == "delivered" then
                NearGiver() -- รับรางวัลจากไกลไม่ได้ = ไปหา Heiyun แล้วกดใหม่
                After = Act("claim")
            end
            if After and After.status ~= "delivered" then
                Webhook.Push("Rewards Claimed", "delivery", Webhook.T("Delivered", tonumber(After.dailyCount) or "?", tonumber(After.dailyLimit) or 50))
            end
            task.wait(0.5)
        elseif Now.status == "carrying" then
            local Spot = DropSpot(Now.target)
            if not Spot then
                Act("abandon")
            elseif not StandAt(Spot, 8, function() return Act("refresh") and State.status ~= "carrying" end) then
                Fails = Fails + 1
            end
        else
            local After = Act("request")
            if not (After and After.status == "carrying") then
                NearGiver()
                After = Act("request")
            end
            if not (After and After.status == "carrying") then Fails = Fails + 1 end
        end
        if Fails >= 3 then
            StopToggle("AZAutoDelivery", "AutoDelivery", "Delivery: " .. tostring(State and State.reason ~= "" and State.reason or "stuck - try a run by hand"))
            break
        end
    end
    Unhook(Hook)
    if Back then TweenTo(Back.Position) end
end

-- ปุ่ม Redeem All Codes (ทุกโค้ดใน codesConfig - ใช้ไปแล้ว server ปฏิเสธเอง)
local function RedeemAllCodes()
    if not (IsLobby and LoadLobby()) then
        return OnUi(function() Library:Notify("Valkyrie Hub", "Codes: lobby only", 5) end)
    end
    local Fresh, Total = 0, 0
    local Last = nil
    local Hook = Lobby.Packets.showNotification:on(function(Result)
        if type(Result) == "table" and type(Result.text) == "string" and Result.text:find("^Code ") then Last = Result.text end
    end)
    -- โค้ดจากประกาศอัปเดต (เกมไม่ส่งรายการโค้ดมาแล้ว) + ของเกมถ้ากลับมามี
    local Codes = { SORRY4DELAY = true, UPDATE3LEGACY = true, ["3TIMESACHARM"] = true }
    for Code in pairs(Lobby.Codes or { }) do Codes[Code] = true end
    for Code in pairs(Codes) do
        Total = Total + 1
        -- ยิงติดกันเร็วไป server เงียบ (วัดสด 2026-10-11: โค้ดที่ 3 ห่าง 0.5 วิไม่ได้ ยิงเดี่ยวได้) -> ไม่ตอบ = ลองอีกครั้ง
        for _ = 1, 2 do
            Last = nil
            Lobby.Packets.redeemCode:fire(Code)
            local Waited = 0
            while not Last and Waited < 3 do Waited = Waited + task.wait(0.1) end
            if Last then break end
            task.wait(2)
        end
        if Last and Last:find("redeemed") then
            Fresh = Fresh + 1
            Webhook.Push("Rewards Claimed", "code:" .. tostring(Code), Webhook.T("RedeemedCode", Code))
        end
        task.wait(1.5)
    end
    Unhook(Hook)
    OnUi(function() Library:Notify("Valkyrie Hub", ("Codes: %d new / %d tried"):format(Fresh, Total), 6) end)
end

-- ==== Miscellaneous ====
-- teleportToArea(name) = ปุ่มในเมนู Areas ของเกม (ชื่อจุด = workspace.Systems.AreasTeleportLocation)
-- Trophy Road ไม่ใช่จุดวาร์ป = เปิดหน้าต่าง "Milestones" ผ่าน WindowService
-- equipTitle(id) สลับใส่/ถอด (ยิง id ที่ใส่อยู่ = ถอด) / มี = account.title[id] / ใส่อยู่ = account.equippedTitle
local AreaTargets = {
    { Name = "Story", Teleport = "Story" },
    { Name = "Arsenal", Teleport = "Arsenal" },
    { Name = "Quests", Teleport = "Quests" },
    { Name = "Item Storage", Teleport = "Items" },
    { Name = "Titles", Teleport = "Titles" },
    { Name = "Traits", Teleport = "Traits" },
    { Name = "Trophy Road", Window = "Milestones" },
    { Name = "Evolution", Teleport = "Evolutions" },
    { Name = "Crafting", Teleport = "Crafting" },
    { Name = "Achievements", Teleport = "Achievements" },
}

local function TeleportArea()
    if not (IsLobby and LoadLobby()) then
        return OnUi(function() Library:Notify("Valkyrie Hub", "Teleport: lobby only", 5) end)
    end
    for _, Target in ipairs(AreaTargets) do
        if Target.Name == Settings().TeleportArea then
            if Target.Window then
                local Windows = SafeRequire(ReplicatedStorage, "global", "utils", "delightUtility", "ClientModules", "WindowService")
                pcall(function() Windows.GetWindow(Target.Window):Open() end)
            else
                Lobby.Packets.teleportToArea:fire(Target.Teleport)
            end
            return
        end
    end
end

-- title ดีสุด = Damage % มากสุด -> ผลรวม buff ทั้งหมดมากสุด (Tier ใช้ไม่ได้ - title ทีมงาน T5 ไม่มี buff)
local function TitleScore(Entry)
    local Damage, Total = 0, 0
    for _, Buff in ipairs(Entry.Buffs or { }) do
        local Value = tonumber(Buff.Percent or Buff.Amount) or 0
        Total = Total + Value
        if Buff.Percent and Lobby.Buffs and Buff.Type == Lobby.Buffs.Damage then Damage = Damage + Value end
    end
    return Damage, Total
end

local function EquipTitleLoop()
    Lobby.Buffs = Lobby.Buffs or SafeRequire(ReplicatedStorage, "global", "enums", "buffEnum")
    if not (Lobby.Titles and Lobby.Buffs) then
        return StopToggle("AZAutoEquipTitle", "AutoEquipTitle", "Titles: game modules not found")
    end
    local LastTry = { }
    while Settings().AutoEquipTitle and getgenv().ValkyrieSession == SessionToken do
        local Data = AccountTable()
        local Best, BestDamage, BestTotal = nil, -1, -1
        for Id, Owned in pairs(Data and Data.title or { }) do
            local Entry = Owned and Lobby.Titles[tostring(Id)]
            if Entry then
                local Damage, Total = TitleScore(Entry)
                if Damage > BestDamage or (Damage == BestDamage and Total > BestTotal) then
                    Best, BestDamage, BestTotal = tostring(Id), Damage, Total
                end
            end
        end
        -- ยิงเฉพาะตอนยังไม่ได้ใส่ (ยิง id เดิมซ้ำ = ถอด)
        if Best and Data and tostring(Data.equippedTitle) ~= Best and os.clock() - (LastTry[Best] or -30) > 10 then
            LastTry[Best] = os.clock()
            Lobby.Packets.equipTitle:fire(Best)
        end
        task.wait(5)
    end
end

-- ==== Shadow Monarch (sung_jinwoo) - MonarchPathConfig ====
-- ขั้น = achievements.progress["evo.sung_jinwoo"] (0 = ยังไม่ปลด ult -> 1 มาจาก Auto Evolve ปกติ) / MaxStage 3
-- monarchEvolve(ขั้นถัดไป) -> monarchEvolveResult{success, stage, reason} / ขั้น II-III ใช้ money + gems + ของ 115/116/119/120
-- Igris (ขั้น II ขึ้นไป): igrisUpgrade(node) -> igrisUpgradeResult{success, node, level, reason} / node Blade Speed Loyalty Command ขั้นละ 1-5
function Evo.PathConfig()
    Evo.Path = Evo.Path or SafeRequire(ReplicatedStorage, "assets", "config", "MonarchPathConfig")
    return Evo.Path
end

-- เงิน/ของพอไหม (Cost = { Currencies = { money = n }, Money = n, Materials = "id,amt|..." })
function Evo.Afford(Data, Cost)
    local Currencies = Data and Data.currencies or { }
    for Key, Amount in pairs(Cost.Currencies or { }) do
        if (tonumber(Currencies[Key]) or 0) < Amount then return false end
    end
    if Cost.Money and (tonumber(Currencies.money) or 0) < Cost.Money then return false end
    for Item, Amount in tostring(Cost.Materials or ""):gmatch("(%d+),(%d+)") do
        if (tonumber(Data and Data.material and Data.material[Item]) or 0) < tonumber(Amount) then return false end
    end
    return true
end

-- ยิงแล้วรอผล (packet ไม่มี requestId - เกมก็รอแบบนี้ 4 วิ)
function Evo.Await(SendName, ReplyName, Value)
    local Reply = nil
    local Hook = Lobby.Packets[ReplyName]:on(function(Result)
        if type(Result) == "table" then Reply = Result end
    end)
    Lobby.Packets[SendName]:fire(Value)
    local Waited = 0
    while not Reply and Waited < 5 do Waited = Waited + task.wait(0.1) end
    pcall(function() if type(Hook) == "function" then Hook() else Hook:Disconnect() end end)
    return Reply
end

-- Auto Evolve ขั้น II-III ของ Shadow Monarch (ขั้น I = evolve ปกติใน EvolveLoop): เงิน + gems + ของครบ = monarchEvolve
-- ตัวอื่น / evolve ครบแล้ว / ของไม่พอ = ไม่ทำอะไร / "Slow down a little" (วัดสด) = กดถี่ไป รอบหน้าลองใหม่
function Evo.MonarchStep(Character, Data)
    if not Evo.Load() then return end
    local Cost = Evo.Cost(Character, Data)
    if not (Cost and Cost.Monarch) then return end
    if not Evo.Afford(Data, { Currencies = Cost.Currencies }) then return end
    for Item, Amount in pairs(Cost.Materials) do
        if (tonumber(Data and Data.material and Data.material[Item]) or 0) < Amount then return end
    end
    local Reply = Evo.Await("monarchEvolve", "monarchEvolveResult", Cost.Monarch)
    if Reply and Reply.success then
        Webhook.Push("Evolution", "monarch:" .. tostring(Cost.Monarch), Webhook.T("MonarchEvolved", Cost.Step), { Urgent = true })
        OnUi(function() Library:Notify("Valkyrie Hub", "Evolve: Shadow Monarch - " .. Cost.Step, 6) end)
    elseif Reply and Reply.reason and Reply.reason ~= "" then
        local Reason = tostring(Reply.reason)
        if not (Reason:lower():find("slow") or Reason:lower():find("wait") or Reason:lower():find("cooldown")) then
            OnUi(function() Library:Notify("Valkyrie Hub", "Evolve: Shadow Monarch - " .. Reason, 6) end)
        end
    end
end

-- ชื่อ node ตามที่เกมโชว์ (dropdown) <-> คีย์ที่ส่ง server
Evo.IgrisNodes = {
    { Key = "Blade", Name = "Crimson Blade" }, { Key = "Speed", Name = "Knight's Pace" },
    { Key = "Loyalty", Name = "Loyalty" }, { Key = "Command", Name = "Commander" },
}

-- อัปขั้นถัดไปที่ถูกสุด (Money) ใน node ที่เลือก จนเงิน/ของไม่พอ / ครบ 5 ทุก node ที่เลือก = ปิดเอง
function Evo.IgrisLoop()
    local Path = Evo.PathConfig()
    if not (Path and Path.IgrisTree) then
        return StopToggle("AZAutoUpgradeIgris", "AutoUpgradeIgris", "Igris: game modules not found")
    end
    while Settings().AutoUpgradeIgris and getgenv().ValkyrieSession == SessionToken do
        local Account = Lobby.Account.getLocalPlayerAccount()
        local Data = AccountTable()
        local Ok, Stage = pcall(Path.GetStage, Account)
        local Best, Open = nil, false
        if Ok and (tonumber(Stage) or 0) >= 2 then
            for _, Node in ipairs(Evo.IgrisNodes) do
                if table.find(Settings().IgrisNodes or { }, Node.Name) then
                    local LevelOk, Level = pcall(Path.GetNodeLevel, Account, Node.Key)
                    Level = LevelOk and tonumber(Level) or 0
                    local Cost = Path.IgrisTree.Nodes[Node.Key] and Path.IgrisTree.Nodes[Node.Key].Levels[Level + 1]
                    if Cost then
                        Open = true
                        if Evo.Afford(Data, Cost) and (not Best or Cost.Money < Best.Cost.Money) then
                            Best = { Node = Node, Cost = Cost, Level = Level + 1 }
                        end
                    end
                end
            end
            if not Open and #(Settings().IgrisNodes or { }) > 0 then
                return StopToggle("AZAutoUpgradeIgris", "AutoUpgradeIgris", "Igris: chosen nodes are maxed")
            end
        end
        if Best then
            local Reply = Evo.Await("igrisUpgrade", "igrisUpgradeResult", Best.Node.Key)
            if Reply and Reply.success then
                Webhook.Push("Character Upgrades", "igris:" .. Best.Node.Key .. ":" .. Best.Level, Webhook.T("IgrisUpgraded", Best.Node.Name, Reply.level or Best.Level))
                task.wait(1)
            else
                task.wait(10)
            end
        else
            task.wait(15)
        end
    end
end

-- ==== Guild (อัปเดต SHADOW MONARCH) ====
-- GuildRemotes.Request:InvokeServer(คำสั่ง, ข้อมูล) -> { Ok, Error, Data / State } (GuildWindowHandler.Call)
-- Watch{On} = สถานะ: Guild{Quests{Key,Text,Goal,Progress,Done,Claimed}, Members{Id,WeekPts}}, Tokens, ShopBought{Key=n}, SeasonClaim
-- ClaimQuest{Key} (เกมให้กดได้เมื่อ Done + ยังไม่ Claimed + เรามี WeekPts > 0) / ClaimSeason{} / BuyShop{Item=Key} / Donate{Amount}
-- GuildConfig: Shop{Key,Name,Cost(tokens),Limit/สัปดาห์}, DonateMin 1k / DonateMax 5M / DonateCooldown 10
local Guild = { }

function Guild.Call(Command, Data)
    local Remote = ReplicatedStorage:FindFirstChild("GuildRemotes") and ReplicatedStorage.GuildRemotes:FindFirstChild("Request")
    if not Remote then return { Ok = false, Error = "guild remotes not found" } end
    local Ok, Reply = pcall(Remote.InvokeServer, Remote, Command, Data or { })
    return (Ok and type(Reply) == "table") and Reply or { Ok = false, Error = tostring(Reply) }
end

function Guild.State()
    local Reply = Guild.Call("Watch", { On = true })
    return Reply.Ok and type(Reply.Data) == "table" and Reply.Data or nil
end

function Guild.Config()
    Guild.Cfg = Guild.Cfg or SafeRequire(ReplicatedStorage, "assets", "config", "GuildConfig")
    return Guild.Cfg or { }
end

-- ชื่อสินค้าในร้าน (ตามที่เกมโชว์) - ใช้ใน dropdown
Guild.ShopNames = { "3 Lucky Spins", "250 Gems", "25,000 Coins", "2 Trait Crystals" }

function Guild.QuestLoop()
    while Settings().AutoClaimGuildQuests and getgenv().ValkyrieSession == SessionToken do
        local State = Guild.State()
        local Info = State and State.Guild
        if type(Info) ~= "table" then
            task.wait(60) -- ยังไม่มีกิลด์ = รอ (ไม่ปิด toggle เผื่อเข้ากิลด์ทีหลัง)
            continue
        end
        local Points = 0
        for _, Member in ipairs(Info.Members or { }) do
            if Member.Id == LocalPlayer.UserId then Points = tonumber(Member.WeekPts) or 0 end
        end
        for _, Quest in ipairs(Info.Quests or { }) do
            if Quest.Done and not Quest.Claimed and Points > 0 then
                local Reply = Guild.Call("ClaimQuest", { Key = Quest.Key })
                if Reply.Ok then
                    Webhook.Push("Rewards Claimed", "guildquest:" .. tostring(Quest.Key), Webhook.T("ClaimedGuildQuest", Quest.Text or Quest.Key))
                end
                task.wait(1)
            end
        end
        -- รางวัลอันดับกิลด์สัปดาห์ก่อน (ปุ่ม Claim ในหน้า Home)
        if type(State.SeasonClaim) == "table" then
            local Reply = Guild.Call("ClaimSeason", { })
            if Reply.Ok then
                Webhook.Push("Rewards Claimed", "guildseason", Webhook.T("ClaimedGuildSeason", State.SeasonClaim.Rank or "?"))
            end
        end
        task.wait(30)
    end
end

function Guild.ShopLoop()
    while Settings().AutoBuyGuildShop and getgenv().ValkyrieSession == SessionToken do
        local State = Guild.State()
        local Wanted = Settings().GuildShopItems or { }
        if State and #Wanted > 0 then
            local Tokens = tonumber(State.Tokens) or 0
            local Bought = type(State.ShopBought) == "table" and State.ShopBought or { }
            for _, Item in ipairs(Guild.Config().Shop or { }) do
                -- ซื้อทีละชิ้นจนครบลิมิตสัปดาห์หรือ token ไม่พอ
                while table.find(Wanted, Item.Name) and (tonumber(Bought[Item.Key]) or 0) < (tonumber(Item.Limit) or 0)
                    and Tokens >= (tonumber(Item.Cost) or math.huge) and Settings().AutoBuyGuildShop do
                    local Reply = Guild.Call("BuyShop", { Item = Item.Key })
                    if not Reply.Ok then break end
                    Tokens = Tokens - Item.Cost
                    Bought[Item.Key] = (tonumber(Bought[Item.Key]) or 0) + 1
                    Webhook.Push("Shop & Convert", "guildshop:" .. Item.Key, Webhook.T("BoughtGuildShop", Item.Name))
                    task.wait(1)
                end
            end
        end
        task.wait(60)
    end
end

-- บริจาควันละครั้ง (วันตาม UTC) ตามจำนวนใน slider - เกมกดได้ทุก 10 วิ ถ้ากดรัวเงินหมดตัว
function Guild.DonateLoop()
    while Settings().AutoDonate and getgenv().ValkyrieSession == SessionToken do
        local Today = os.date("!%Y-%m-%d")
        local Config = Guild.Config()
        local Amount = math.clamp(math.floor(tonumber(Settings().DonateAmount) or 0), Config.DonateMin or 1000, Config.DonateMax or 5000000)
        if Settings().GuildDonatedDay ~= Today then
            local State = Guild.State()
            if State and type(State.Guild) == "table" and Balance("money") >= Amount then
                local Reply = Guild.Call("Donate", { Amount = Amount })
                if Reply.Ok then
                    Settings().GuildDonatedDay = Today
                    SaveSetting()
                    Webhook.Push("Rewards Claimed", "donate:" .. Today, Webhook.T("Donated", Webhook.Num(Amount)))
                elseif Reply.Error then
                    OnUi(function() Library:Notify("Valkyrie Hub", "Guild Donate: " .. tostring(Reply.Error), 6) end)
                end
            end
        end
        task.wait(60)
    end
end

local LobbyLoops = {
    AutoSummon = SummonLoop,
    AutoTraitReroll = TraitLoop,
    AutoEmote = EmoteLoop,
    AutoConvertGems = GemLoop,
    AutoEvolve = EvolveLoop,
    AutoBuyMaterials = BuyMaterialLoop,
    AutoConvertMaterials = ConvertMaterialLoop,
    AutoBuySkill = SkillLoop,
    AutoUnlockSlot = UnlockSlotLoop,
    AutoPlaceStored = PlaceStoredLoop,
    AutoEquipBest = EquipBestLoop,
    AutoLock = LockLoop,
    AutoCraft = CraftLoop,
    AutoEquipItem = EquipItemLoop,
    AutoClaimDaily = ClaimDailyLoop,
    AutoClaimQuests = ClaimQuestLoop,
    AutoClaimAchievements = ClaimAchievementLoop,
    AutoClaimLevelRoad = ClaimLevelRoadLoop,
    AutoClaimGroup = ClaimGroupLoop,
    AutoEnterAfk = EnterAfkLoop,
    AutoDelivery = DeliveryLoop,
    AutoEquipTitle = EquipTitleLoop,
    AutoClaimGuildQuests = Guild.QuestLoop,
    AutoBuyGuildShop = Guild.ShopLoop,
    AutoDonate = Guild.DonateLoop,
    AutoUpgradeIgris = Evo.IgrisLoop,
}

-- เปิด/ปิดลูปตาม toggle (1 เธรดต่อ toggle / ลูปเช็คค่า setting เองทุกรอบ ปิดแล้วจบเอง)
function Lobby.Refresh(Key)
    if not Settings()[Key] or Lobby.Threads[Key] or not IsLobby then return end
    Lobby.Threads[Key] = true
    task.spawn(function()
        if not NormalizeTick() then return end
        if LoadLobby() then
            local Ok, Err = pcall(LobbyLoops[Key])
            if not Ok then warn("[ValkyrieHub] " .. Key .. ": " .. tostring(Err)) end
        end
        Lobby.Threads[Key] = nil
    end)
end

-- Auto Executor: hub ต้องรันใหม่ทุกครั้งที่ย้าย place (lobby <-> แมตช์ / AFK World) -> queue_on_teleport โค้ด loader
-- เดิม queue เฉพาะตอนมี getgenv().ValkyrieLoader (loader ไม่ได้ตั้ง = ไม่เคย queue) และเฉพาะตอนเปิด Auto Join
-- (ผู้ใช้ 2026-10-06: Auto Executor ไม่ทำงาน) -> ใช้ loader ของเว็บเสมอ (key อยู่ในไฟล์ MyKey หลังยืนยันครั้งแรก
-- ส่ง LicenseKey / Mode ที่ตั้งไว้ต่อให้ด้วย) / queue ตั้งแต่โหลด ไม่รอ OnTeleport: วาร์ปที่ server สั่ง
-- (กด Leave / หมดคิว) บาง executor ไม่ยิง OnTeleport ทัน
-- วัดสด: executor เก็บ queue ได้อันเดียว อันหลังทับ (DexBridge queue ตัวเองตอน OnTeleport = ของเราหาย)
-- -> queue ซ้ำตอนเริ่มวาร์ปด้วย (หน่วง 0.3 วิ ให้เป็นอันหลังสุด) / executor ที่เก็บได้หลายอัน = โค้ดกันรันซ้ำเอง
local QueueLoader
do
local LoaderUrl = "https://www.valkyriehub.net/api/raw/loading"
local LoaderQueuedAt = nil

local function LoaderSource()
    if type(getgenv().ValkyrieLoader) == "string" and getgenv().ValkyrieLoader ~= "" then
        return getgenv().ValkyrieLoader
    end
    local Lines = { }
    for _, Name in ipairs({ "LicenseKey", "License", "Key", "ValkyrieKey", "Mode", "ValkyrieProduct" }) do
        local Value = getgenv()[Name]
        if type(Value) == "string" and Value ~= "" then
            table.insert(Lines, ("getgenv().%s = %q"):format(Name, Value))
        end
    end
    table.insert(Lines, ("loadstring(game:HttpGet(%q))()"):format(LoaderUrl))
    return "if getgenv().ValkyrieBooted == game.JobId then return end getgenv().ValkyrieBooted = game.JobId\n" .. table.concat(Lines, "\n")
end

function QueueLoader()
    if not getgenv().ConfigurationTable.AutoExecutor then return end
    local Queue = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
    if type(Queue) ~= "function" then return end
    if pcall(Queue, LoaderSource()) then LoaderQueuedAt = os.clock() end
end

getgenv().ValkyrieBooted = game.JobId -- รันอยู่แล้วในเซิร์ฟนี้ (executor ที่ getgenv ติดข้ามเซิร์ฟ: JobId ใหม่ = รันได้)
QueueLoader()
TrackConnection(LocalPlayer.OnTeleport:Connect(function(State)
    if State ~= Enum.TeleportState.Started and State ~= Enum.TeleportState.InProgress then return end
    if LoaderQueuedAt and os.clock() - LoaderQueuedAt < 5 then return end -- วาร์ปเดียวยิง OnTeleport หลายครั้ง
    LoaderQueuedAt = os.clock()
    task.delay(0.3, QueueLoader)
end))
end

---- ============ Auto Farm Tab ============ ----

Window:Category("General")

local FarmPage = Window:Page({ Name = "Auto Farm", Icon = "activity", Columns = 2 })

-- จัดทุกกล่องเหมือนกัน: Toggle ทั้งหมด -> Dropdown ทั้งหมด -> Slider ทั้งหมด
-- เส้นคั่น (Seperator) อยู่ใต้ตัวสุดท้ายของแต่ละกลุ่มเท่านั้น ชนิดเดียวกันไม่คั่นกันเอง
local JoinSection = FarmPage:Section({ Name = "Auto Join", Icon = "compass", Side = 1 })

local function JoinSetting(Key)
    return function(Value)
        Settings()[Key] = Value
        SaveSetting()
    end
end

JoinSection:Toggle({
    Name = "Auto Join",
    Description = "Create a solo room in the lobby, then Retry / Leave when the match ends",
    Flag = "AZAutoJoin",
    Default = Settings().AutoJoin,
    Seperator = true,
    Callback = function(Value)
        Settings().AutoJoin = Value
        SaveSetting()
        Join.Refresh()
    end
})

local CurrentMode = ModeOf(Settings().AutoJoinMode)
local CurrentMap = MapOf(CurrentMode, Settings().AutoJoinMap)
local MapDropdown, ChapterDropdown, DifficultyDropdown

JoinSection:Dropdown({
    Name = "Mode",
    Flag = "AZAutoJoinMode",
    Seperator = false,
    Items = Modes.Order,
    KeepOrder = true,
    Default = table.find(Modes.Order, Settings().AutoJoinMode) and Settings().AutoJoinMode or Modes.Order[1],
    Callback = function(Value)
        if type(Value) ~= "string" or Value == "" then return end
        Settings().AutoJoinMode = Value
        local Mode = ModeOf(Value)
        local Map = MapOf(Mode, Settings().AutoJoinMap)
        Settings().AutoJoinMap = Map.Name
        SaveSetting()
        if MapDropdown then MapDropdown:Refresh(MapNames(Mode), Map.Name) end
        if ChapterDropdown then ChapterDropdown:Refresh(ChapterNames(Map), ChapterNames(Map)[1]) end
        if DifficultyDropdown then DifficultyDropdown:Refresh(DifficultyOptions(Mode), PickDifficulty(Mode)) end
    end
})

MapDropdown = JoinSection:Dropdown({
    Name = "Map",
    Flag = "AZAutoJoinMap",
    Seperator = false,
    Items = MapNames(CurrentMode),
    KeepOrder = true,
    Default = CurrentMap.Name,
    Callback = function(Value)
        if type(Value) ~= "string" or Value == "" then return end
        Settings().AutoJoinMap = Value
        SaveSetting()
        local Map = MapOf(ModeOf(Settings().AutoJoinMode), Value)
        if ChapterDropdown then
            local Wanted = "Act " .. tostring(Settings().AutoJoinChapter)
            ChapterDropdown:Refresh(ChapterNames(Map), table.find(ChapterNames(Map), Wanted) and Wanted or ChapterNames(Map)[1])
        end
    end
})

ChapterDropdown = JoinSection:Dropdown({
    Name = "Chapter",
    Description = "Locked acts fall back to the highest one you unlocked",
    Flag = "AZAutoJoinChapter",
    Seperator = false,
    Items = ChapterNames(CurrentMap),
    KeepOrder = true,
    Default = "Act " .. tostring(Settings().AutoJoinChapter),
    Callback = function(Value)
        if type(Value) ~= "string" then return end
        local Number = tonumber(Value:match("%d+"))
        if not Number then return end
        Settings().AutoJoinChapter = Number
        SaveSetting()
    end
})

DifficultyDropdown = JoinSection:Dropdown({
    Name = "Difficulty",
    Description = "Options follow the mode - Raid is Nightmare only",
    Flag = "AZAutoJoinDifficulty",
    Seperator = false,
    Items = DifficultyOptions(CurrentMode),
    KeepOrder = true,
    Default = PickDifficulty(CurrentMode),
    Callback = function(Value)
        if type(Value) ~= "string" or Value == "" then return end
        -- โหมดความยากตายตัว (Raid) = ตัวเลือกเดียว ไม่เซฟทับ - กลับไป Story/Infinite แล้วได้ค่าเดิม
        if ModeOf(Settings().AutoJoinMode).Fixed then return end
        Settings().AutoJoinDifficulty = Value
        SaveSetting()
    end
})

JoinSection:Dropdown({
    Name = "On Finish",
    Flag = "AZAutoJoinOnFinish",
    Seperator = false,
    Description = "Works in the match on its own - Next falls back to Retry when there is no next chapter",
    Items = { "None", "Retry", "Next", "Leave" },
    KeepOrder = true,
    Default = Settings().AutoJoinOnFinish,
    Callback = function(Value)
        if type(Value) ~= "string" or Value == "" then return end
        Settings().AutoJoinOnFinish = Value
        SaveSetting()
        Join.Refresh()
    end
})


do
local TrialsSection = FarmPage:Section({ Name = "Trials", Icon = "trending-up", Side = 1 })

TrialsSection:Toggle({
    Name = "Auto Trials",
    Description = "Creates Trials rooms by itself (no Auto Join needed) and keeps playing them",
    Flag = "AZAutoTrials",
    Default = Settings().AutoTrials,
    Callback = function(Value)
        Settings().AutoTrials = Value
        SaveSetting()
        Join.Refresh()
    end
})

TrialsSection:Toggle({
    Name = "Best Floor",
    Description = "Creates the highest floor you can play (Highest Floor + 1) - off = the Floor below",
    Flag = "AZTrialsBest",
    Default = Settings().TrialsBest ~= false,
    Seperator = true,
    Callback = function(Value)
        Settings().TrialsBest = Value
        SaveSetting()
    end
})

TrialsSection:Slider({
    Name = "Floor",
    Description = "Floor to create while Best Floor is off - one above Highest Floor + 1 is not open yet and falls back to it",
    Flag = "AZTrialsRoom",
    Min = 1,
    Max = 500,
    Default = Settings().TrialsRoom,
    Seperator = false,
    Callback = function(Value)
        Settings().TrialsRoom = tonumber(Value) or 1
        SaveSetting()
    end
})

TrialsSection:Dropdown({
    Name = "On Finish",
    Flag = "AZTrialsOnFinish",
    Seperator = false,
    Description = "Next = a win presses Next Floor, a loss replays the floor",
    Items = { "None", "Retry", "Next", "Leave" },
    KeepOrder = true,
    Default = Settings().TrialsOnFinish,
    Callback = function(Value)
        if type(Value) ~= "string" or Value == "" then return end
        Settings().TrialsOnFinish = Value
        SaveSetting()
    end
})

local TrialsLabel = TrialsSection:Label("Highest Floor: -")
task.spawn(function()
    while getgenv().ValkyrieSession == SessionToken do
        local Highest, Best = Trials.Highest(), Trials.Progress("trials.room")
        local Lines = {
            ("%s: %s  (%s: %s)"):format(Library.Tr("Highest Floor"), Highest > 0 and tostring(Highest) or "-", Library.Tr("best ever"), Best > 0 and tostring(Best) or "-"),
            ("%s: %d"):format(Library.Tr("Next Floor"), Trials.Room()),
        }
        if type(Settings().TrialsLast) == "string" then
            table.insert(Lines, ("%s: %s"):format(Library.Tr("Last Run"), Library.Tr(Settings().TrialsLast)))
        end
        local Text = table.concat(Lines, "\n")
        OnUi(function() TrialsLabel:SetText(Text) end)
        task.wait(5)
    end
end)
end

local BattleSection = FarmPage:Section({ Name = "Auto Battle", Icon = "swords", Side = 2 })

local function BattleToggle(Name, Key, Description, Seperator)
    BattleSection:Toggle({
        Name = Name,
        Description = Description,
        Flag = "AZ" .. Key,
        Default = Settings()[Key],
        Seperator = Seperator,
        Callback = function(Value)
            Settings()[Key] = Value
            SaveSetting()
            Battle.Refresh()
        end
    })
end

local function BattleSlider(Name, Key, Min, Max, Description, Suffix)
    BattleSection:Slider({
        Name = Name,
        Description = Description,
        Flag = "AZ" .. Key,
        Min = Min,
        Max = Max,
        Default = Settings()[Key],
        Suffix = Suffix,
        Seperator = false,
        Callback = function(Value)
            Settings()[Key] = Value
            SaveSetting()
        end
    })
end

-- Toggle
BattleToggle("Auto Attack", "AutoAttack", "Keep M1 held on the nearest enemy and break the walls between areas")
BattleToggle("Auto Skill", "AutoSkill", "Use skills 1-3 once the whole wave has spawned, and on Story walls")
BattleToggle("Auto Tag Team", "AutoTagTeam", "Uses up this character's skills, then swaps right away if the other one has a skill ready (the Tag-In +20% damage still procs)")
BattleToggle("Auto Ultimate", "AutoUltimate", "Fire the ultimate as soon as the bar is full")
BattleToggle("Auto Collect Drops", "AutoCollectDrops", "Pick up cash drops once the area is clear", true)

-- Dropdown
BattleSection:Dropdown({
    Name = "Skills",
    Description = "Which skills Auto Skill uses (Auto Tag Team only counts these too)",
    Flag = "AZSkillSlots",
    Seperator = false,
    Items = { "Skill 1", "Skill 2", "Skill 3" },
    KeepOrder = true,
    Multi = true,
    Default = Settings().SkillSlots,
    Callback = JoinSetting("SkillSlots")
})

BattleSection:Dropdown({
    Name = "Attack Position",
    Description = "Above / Below = hover over or under the target, Orbit = circle above its head",
    Flag = "AZAttackPosition",
    Seperator = false,
    Items = { "Above", "Below", "Orbit" },
    KeepOrder = true,
    Default = Settings().AttackPosition,
    Callback = JoinSetting("AttackPosition")
})

BattleSection:Dropdown({
    Name = "Ultimate Target",
    Flag = "AZUltimateTarget",
    Items = { "Any Enemy", "Boss Only" },
    KeepOrder = true,
    Default = Settings().UltimateTarget,
    Seperator = true,
    Callback = JoinSetting("UltimateTarget")
})

-- Slider
BattleSlider("Height Offset", "PositionHeight", 2, 15, "Studs above / below the target (Above, Below, Orbit)", " studs")
BattleSlider("Orbit Radius", "OrbitRadius", 2, 15, "How far from the target you circle (Orbit)", " studs")
BattleSlider("Orbit Speed", "OrbitSpeed", 1, 10, "How fast you circle the target (Orbit)", "")
BattleSlider("Teleport Step", "TpStep", 0, 20, "In a match, moves by teleporting this far every frame (0 = smooth flight)", " studs")
BattleSlider("Grab Heals Below HP", "HealBelowHP", 0, 100, "Leave health drops on the ground until HP falls under this, then grab them (0 = pick up as normal)", "%")


---- ============ Auto Summon Tab (lobby) ============ ----

local SummonPage = Window:Page({ Name = "Auto Summon", Icon = "users", Columns = 2 })

local function LobbyToggle(Section, Name, Key, Description, Seperator)
    Section:Toggle({
        Name = Name,
        Description = Description,
        Flag = "AZ" .. Key,
        Default = Settings()[Key],
        Seperator = Seperator,
        Callback = function(Value)
            Settings()[Key] = Value
            SaveSetting()
            Lobby.Refresh(Key)
        end
    })
end

local PoolNames = { }
for _, Entry in ipairs(SummonPool) do
    if Entry.Summon ~= false then table.insert(PoolNames, Entry.Name) end
end
local TraitNames = { }
for _, Entry in ipairs(TraitList) do table.insert(TraitNames, Entry.Name) end

-- Summon
local SummonSection = SummonPage:Section({ Name = "Summon", Icon = "users", Side = 1 })

LobbyToggle(SummonSection, "Auto Summon", "AutoSummon", "Lobby only - keeps rolling into the chosen slot until a target is hit", true)

SummonSection:Dropdown({
    Name = "Spin Type",
    Flag = "AZSummonSpinType",
    Items = { "Normal Spin", "Lucky Spin" },
    KeepOrder = true,
    Default = Settings().SummonSpinType,
    Seperator = false,
    Callback = JoinSetting("SummonSpinType")
})

SummonSection:Dropdown({
    Name = "Pay With",
    Description = "Normal Spin only - Roll = 1 Roll each, Coin = 500 Coins each",
    Flag = "AZSummonCurrency",
    Items = { "Roll", "Coin" },
    KeepOrder = true,
    Default = Settings().SummonCurrency,
    Seperator = false,
    Callback = JoinSetting("SummonCurrency")
})

SummonSection:Dropdown({
    Name = "Summon Slot",
    Description = "The character in this slot gets replaced every roll",
    Flag = "AZSummonSlot",
    Items = (function()
        local List = { }
        for Slot = 1, Evo.SlotCount do table.insert(List, "Slot " .. Slot) end
        return List
    end)(),
    KeepOrder = true,
    Default = "Slot " .. tostring(Settings().SummonSlot),
    Seperator = false,
    Callback = function(Value)
        local Number = type(Value) == "string" and tonumber(Value:match("%d+"))
        if not Number then return end
        Settings().SummonSlot = Number
        SaveSetting()
    end
})

SummonSection:Dropdown({
    Name = "Stop at Rarity",
    Description = "Stops on any of the selected rarities",
    Flag = "AZSummonStopRarities",
    Items = { "Mythic", "Arcane", "LYTH" },
    KeepOrder = true,
    Multi = true,
    Default = Settings().SummonStopRarities,
    Seperator = false,
    Callback = JoinSetting("SummonStopRarities")
})

SummonSection:Dropdown({
    Name = "Stop at Character",
    Description = "Also stops on any of these, whatever the rarity",
    Flag = "AZSummonStopCharacters",
    Items = PoolNames,
    KeepOrder = true,
    Multi = true,
    Default = Settings().SummonStopCharacters,
    Seperator = false,
    Callback = JoinSetting("SummonStopCharacters")
})

-- Trait Reroll
local TraitSection = SummonPage:Section({ Name = "Trait Reroll", Icon = "wand-2", Side = 1 })

LobbyToggle(TraitSection, "Auto Reroll", "AutoTraitReroll", "Lobby only - rerolls until one of the kept traits lands", true)

-- โชว์ชื่อตัว (Shadow Monarch) แต่เซฟ/ส่ง id (sung_jinwoo) - ตารางชื่อ -> id (Lobby.TraitIds) มาจากเธรดงานด้านล่าง
Lobby.TraitIds = { }

local TraitCharacterDropdown = TraitSection:Dropdown({
    Name = "Character",
    Description = "Characters in your unlocked slots",
    Flag = "AZTraitCharacter",
    Items = (Settings().TraitCharacter ~= "" and { Settings().TraitCharacter }) or { },
    KeepOrder = true,
    Default = Settings().TraitCharacter,
    Seperator = false,
    Callback = function(Value)
        Settings().TraitCharacter = Lobby.TraitIds[Value] or Value
        SaveSetting()
    end
})

TraitSection:Dropdown({
    Name = "Keep Traits",
    Flag = "AZTraitKeep",
    Items = TraitNames,
    KeepOrder = true,
    Multi = true,
    Default = Settings().TraitKeep,
    Seperator = false,
    Callback = JoinSetting("TraitKeep")
})

-- Emote Shop
local EmoteSection = SummonPage:Section({ Name = "Emote Shop", Icon = "shirt", Side = 2 })

LobbyToggle(EmoteSection, "Auto Purchase Emote", "AutoEmote", "Lobby only - rolls an emote whenever you have 5 dice rolls")

-- Lucky Spin
local LuckySection = SummonPage:Section({ Name = "Lucky Spin", Icon = "coins", Side = 2 })

LobbyToggle(LuckySection, "Auto Convert Gems to Lucky Spins", "AutoConvertGems", "Lobby only - 100 gems = 1 Lucky Spin", true)

LuckySection:Slider({
    Name = "Keep Gems",
    Description = "Never convert below this many gems",
    Flag = "AZKeepGems",
    Min = 0,
    Max = 100000,
    Default = Settings().KeepGems,
    Seperator = false,
    Callback = function(Value)
        Settings().KeepGems = Value
        SaveSetting()
    end
})

-- รายชื่อตัวใน Trait Reroll = ตัวที่อยู่ในช่องที่ปลดแล้ว (อ่านจาก account ในเธรดงาน แล้วส่งให้คิว UI อัปเดต)
-- เช็คทุก 2 วิ: สุ่มได้ตัวใหม่ลงช่อง = รายการอัปเดตเอง (เดิมโหลดครั้งเดียวตอนรัน = ตัวใหม่เลือกไม่ได้ - ผู้ใช้ 2026-10-12)
-- ไม่สร้างรายการใหม่ตอน dropdown เปิดอยู่ (ปุ่มถูกลบระหว่างกด = กดไม่ติด) รอบหน้าค่อยทำ
task.spawn(function()
    if not (IsLobby and LoadLobby()) then return end
    local Shown = nil
    while getgenv().ValkyrieSession == SessionToken do
        local Names, Ids = { }, { }
        for _, Id in ipairs(OwnedCharacters()) do
            local Entry = PoolByName(Id)
            local Name = Entry and Entry.Name or Id
            if Ids[Name] and Ids[Name] ~= Id then Name = Name .. " (" .. Id .. ")" end
            if not Ids[Name] then
                Ids[Name] = Id
                table.insert(Names, Name)
            end
        end
        local Key = table.concat(Names, "\0")
        if #Names > 0 and Key ~= Shown then
            OnUi(function()
                if Key == Shown or TraitCharacterDropdown.open then return end
                Shown = Key
                Lobby.TraitIds = Ids
                local Pick = Names[1]
                for Name, Id in pairs(Ids) do
                    if Id == Settings().TraitCharacter then Pick = Name end
                end
                TraitCharacterDropdown:Refresh(Names, Pick)
            end)
        end
        task.wait(2)
    end
end)

---- ============ Auto Character Tab (lobby) ============ ----

local CharacterPage = Window:Page({ Name = "Auto Character", Icon = "shield", Columns = 2 })

-- Evolution
local EvolutionSection = CharacterPage:Section({ Name = "Evolution", Icon = "flask-conical", Side = 1 })

LobbyToggle(EvolutionSection, "Auto Evolve Character", "AutoEvolve", "Lobby only - unlocks the ultimate of every owned character once coins, gems and materials are there (Sung Jinwoo goes on through Arise: Igris and Demon King's Longsword)")
LobbyToggle(EvolutionSection, "Auto Buy Materials", "AutoBuyMaterials", "Lobby only - buys what the target is missing from today's Material Shop")
LobbyToggle(EvolutionSection, "Auto Convert Materials", "AutoConvertMaterials", "Lobby only - trades spare materials (not needed by any owned character) into missing ones, 5:1 up / 3:1 swap")

EvolutionSection:Toggle({
    Name = "Auto Farm Materials",
    Description = "Creates a room by itself (no Auto Join needed) - plays the Hxh act at your Auto Join difficulty that drops the most of what is missing, leaves to re-pick once it changes",
    Flag = "AZAutoFarmMaterials",
    Default = Settings().AutoFarmMaterials,
    Seperator = true,
    Callback = function(Value)
        Settings().AutoFarmMaterials = Value
        SaveSetting()
        Join.Refresh()
    end
})

do
-- ชื่อในรายการ = id ตัวละคร (ตัวแรกพิมพ์ใหญ่, _ = เว้นวรรค) -> เก็บเป็น id (sung_jinwoo)
local EvolveTargets = { "Auto", "Sung Jinwoo", "Hutao", "Astra Yao", "Frieren", "Rin", "Ye Shunguang", "Miyabi", "Sukuna", "Shanks", "Katakuri", "Saber", "Guts", "Alucard", "Juuzou", "Nagumo", "Luffy", "Goku", "Killua" }
EvolutionSection:Dropdown({
    Name = "Evolve Target",
    Description = "Auto = rarest owned character that still misses materials",
    Flag = "AZEvolveTarget",
    Items = EvolveTargets,
    KeepOrder = true,
    Default = (tostring(Settings().EvolveTarget or "Auto"):gsub("_", " "):gsub("(%a)(%w*)", function(A, B) return A:upper() .. B end)),
    Callback = function(Value)
        if type(Value) ~= "string" or Value == "" then return end
        Settings().EvolveTarget = Value == "Auto" and "Auto" or (string.lower(Value):gsub(" ", "_"))
        SaveSetting()
    end
})

local EvolveLabel = EvolutionSection:Label("Target: -")

-- สถานะเป้า: ของที่มี/ต้องใช้ + ด่านที่ฟาร์ม (อ่านบัญชีทุก 5 วิ ทั้ง lobby และในแมตช์)
task.spawn(function()
    while getgenv().ValkyrieSession == SessionToken do
        if Evo.Load() then
            local Data = Evo.Data()
            local Target = Data and Evo.Target(Data)
            local Text = "Target: -"
            if Target then
                local Bag = Data.material or { }
                local Parts = { }
                local Cost = Evo.Cost(Target, Data) or { Materials = { }, Currencies = { } }
                local Need = Cost.Materials
                local Items = { }
                for Item in pairs(Need) do table.insert(Items, Item) end
                table.sort(Items, function(A, B) return tonumber(A) < tonumber(B) end)
                for _, Item in ipairs(Items) do
                    local Have = tonumber(Bag[Item]) or 0
                    local Color = Have >= Need[Item] and "#7CFC9A" or "#FFD166"
                    table.insert(Parts, ('<font color="%s">%s %d/%d</font>'):format(Color, Evo.Name(Item), Have, Need[Item]))
                end
                -- Coins / Gems ที่ขั้นนี้ใช้ (ทุกตัวมีค่า evolve เป็นเงินด้วย)
                for _, Key in ipairs({ "money", "gems" }) do
                    local Amount = Cost.Currencies[Key]
                    if Amount and Amount > 0 then
                        local Have = tonumber(Data.currencies and Data.currencies[Key]) or 0
                        local Color = Have >= Amount and "#7CFC9A" or "#FFD166"
                        table.insert(Parts, ('<font color="%s">%s %s/%s</font>'):format(Color, Key == "money" and "Coins" or "Gems", Webhook.Num(Have), Webhook.Num(Amount)))
                    end
                end
                local Name = (Target:gsub("_", " "):gsub("(%a)(%w*)", function(A, B) return A:upper() .. B end))
                Text = Name .. (Cost.Monarch and (" (" .. Cost.Step .. ")") or "") .. ": " .. table.concat(Parts, ", ")
                local Plan = Settings().AutoFarmMaterials and Evo.Plan(Data)
                if Plan then Text = Text .. "\nFarm: " .. Plan.Label end
            end
            OnUi(function() EvolveLabel:SetRichText(Text) end)
        end
        task.wait(5)
    end
end)
end

-- Skill Tree
local SkillTreeSection = CharacterPage:Section({ Name = "Skill Tree", Icon = "trending-up", Side = 1 })

LobbyToggle(SkillTreeSection, "Auto Purchase Skill", "AutoBuySkill", "Lobby only - spends skill tokens on every owned character", true)

SkillTreeSection:Dropdown({
    Name = "Skill",
    Description = "Branches to upgrade - the cheapest next tier is bought first",
    Flag = "AZSkillBranches",
    Items = SkillBranches,
    KeepOrder = true,
    Multi = true,
    Default = Settings().SkillBranches,
    Seperator = false,
    Callback = JoinSetting("SkillBranches")
})

-- Igris Tree (Shadow Monarch ขั้น II ขึ้นไป)
do
local IgrisNames = { }
for _, Node in ipairs(Evo.IgrisNodes) do table.insert(IgrisNames, Node.Name) end

LobbyToggle(SkillTreeSection, "Auto Upgrade Igris", "AutoUpgradeIgris", "Lobby only - Shadow Monarch's Igris tree (after Arise: Igris), cheapest next level first", true)

SkillTreeSection:Dropdown({
    Name = "Igris Node",
    Description = "Nodes to upgrade (up to level 5 each)",
    Flag = "AZIgrisNodes",
    Items = IgrisNames,
    KeepOrder = true,
    Multi = true,
    Default = Settings().IgrisNodes,
    Seperator = false,
    Callback = JoinSetting("IgrisNodes")
})
end

-- Slot
local SlotSection = CharacterPage:Section({ Name = "Slot", Icon = "anchor", Side = 2 })

LobbyToggle(SlotSection, "Auto Unlock Slot", "AutoUnlockSlot", "Lobby only - buys the next slot once you have the cash (slot 2 = 25k up to slot 11 = 50M)")
LobbyToggle(SlotSection, "Auto Place Stored Unit", "AutoPlaceStored", "Lobby only - units waiting in Storage (Hu Tao, Jinwoo, Trials and Leaderboard units) go into an empty slot, or over the weakest slot that is not locked")
LobbyToggle(SlotSection, "Auto Equip Best", "AutoEquipBest", "Lobby only - picks the best pair by rarity, ultimate and synergy (see the Synergy table)")
LobbyToggle(SlotSection, "Auto Lock", "AutoLock", "Lobby only - locks matching slots so summons cannot replace them (never unlocks)", true)

SlotSection:Dropdown({
    Name = "Lock Rarity",
    Description = "Slots holding these rarities get locked",
    Flag = "AZLockRarities",
    Items = { "Epic", "Legendary", "Mythic", "Arcane", "LYTH" },
    KeepOrder = true,
    Multi = true,
    Default = Settings().LockRarities,
    Seperator = false,
    Callback = JoinSetting("LockRarities")
})

-- Synergy: ตารางคู่ (คุ้มสุดก่อน) + ทีมที่ Auto Equip Best จะเลือก / สีตามตัวที่มี (lobby อ่านบัญชีทุก 10 วิ)
do
local SynergySection = CharacterPage:Section({ Name = "Synergy", Icon = "users", Side = 2 })

-- ชื่อเดียวกับหน้า Summon (displayName) เช่น sukuna = Cursed King
local function TitleCase(Id)
    local Entry = PoolByName(Id)
    return Entry and Entry.Name or (tostring(Id):gsub("^%l", string.upper))
end

local function PairText(Pair)
    return ("%s: %s + %s - %s"):format(Pair.Name, TitleCase(Pair.A), TitleCase(Pair.B), Pair.Bonus)
end

local BestTeamLabel = SynergySection:Label("Best Team: -", true)
SynergySection:Divider("Pairs (best first)")
local PairLabels = { }
for Index, Pair in ipairs(SynergyPairs) do
    PairLabels[Index] = SynergySection:Label(PairText(Pair))
end
SynergySection:Label("Any other pair: Tag Team +5% Damage")
SynergySection:Label("Swap in: +20% Damage for 4s, every 10s")
SynergySection:Label("Green = you own both, yellow = one")

task.spawn(function()
    if not (IsLobby and LoadLobby()) then return end
    while getgenv().ValkyrieSession == SessionToken do
        local List = OwnedSlots()
        local Owned = { }
        for _, Entry in ipairs(List) do Owned[Entry.Character] = true end
        local Team = BestTeam(List)
        OnUi(function()
            local function Tr(Text)
                local Ok, Out = pcall(function() return LibraryMilenium:translate(Text) end)
                return Ok and type(Out) == "string" and Out or Text
            end
            for Index, Pair in ipairs(SynergyPairs) do
                local Count = (Owned[Pair.A] and 1 or 0) + (Owned[Pair.B] and 1 or 0)
                local Color = Count == 2 and "#7CFC9A" or Count == 1 and "#FFD166" or "#8A8A8A"
                PairLabels[Index]:SetRichText(('<font color="%s">%s</font>'):format(Color, PairText(Pair)))
            end
            local Text = Tr("Best Team") .. ": -"
            if Team and Team.First then
                Text = Tr("Best Team") .. ": " .. TitleCase(Team.First.Character)
                if Team.Second then
                    Text = Text .. " + " .. TitleCase(Team.Second.Character) .. " (" .. Team.Synergy.Name .. " " .. Team.Synergy.Bonus .. ")"
                end
            end
            BestTeamLabel:SetText(Text)
        end)
        task.wait(10)
    end
end)
end

---- ============ Auto Crafting Tab (lobby) ============ ----

local CraftPage = Window:Page({ Name = "Auto Crafting", Icon = "puzzle", Columns = 2 })

local AccessoryNames = { }
for _, Entry in ipairs(AccessoryList) do table.insert(AccessoryNames, Entry.Name) end

-- Crafting
local CraftSection = CraftPage:Section({ Name = "Crafting", Icon = "puzzle", Side = 1 })

do
-- Auto Craft / Farm Missing Materials เปิดปิด = Join ต้องรู้ด้วย (สร้างห้องไปฟาร์มเอง)
local function CraftToggle(Name, Key, Description, Seperator)
    CraftSection:Toggle({
        Name = Name,
        Description = Description,
        Flag = "AZ" .. Key,
        Default = Settings()[Key],
        Seperator = Seperator,
        Callback = function(Value)
            Settings()[Key] = Value
            SaveSetting()
            Lobby.Refresh("AutoCraft") -- CraftFarm ไม่มีลูปของตัวเอง (เปิดทีหลัง = ปลุก Auto Craft ที่หยุดไป)
            Join.Refresh()
        end
    })
end

-- เปลี่ยนไอเทม / จำนวน = เริ่มนับที่คราฟต์ใหม่
local function CraftSetting(Key)
    return function(Value)
        if Settings()[Key] ~= Value then Settings().CraftMade = 0 end
        Settings()[Key] = Value
        SaveSetting()
    end
end

CraftToggle("Auto Craft", "AutoCraft", "Lobby only - crafts the item until the amount is reached or materials run out", false)
CraftToggle("Farm Missing Materials", "CraftFarm", "With Auto Craft on - when materials run out, creates a room and plays the Hxh act that drops the most of what is missing, then comes back to craft", true)

CraftSection:Dropdown({
    Name = "Item",
    Flag = "AZCraftItem",
    Items = AccessoryNames,
    KeepOrder = true,
    Default = Settings().CraftItem,
    Seperator = false,
    Callback = CraftSetting("CraftItem")
})

CraftSection:Slider({
    Name = "Craft Amount",
    Description = "How many to craft - the count carries over while farming, and restarts once done or when the item / amount changes",
    Flag = "AZCraftAmount",
    Min = 1,
    Max = 100,
    Default = Settings().CraftAmount,
    Seperator = false,
    Callback = CraftSetting("CraftAmount")
})
end

-- Item Storage
local StorageSection = CraftPage:Section({ Name = "Item Storage", Icon = "shirt", Side = 2 })

LobbyToggle(StorageSection, "Auto Equip Best Item", "AutoEquipItem", "Lobby only - wears the best accessory in every slot: Head / Face / Neck / Back (most damage first)")

---- ============ Auto Claim Tab (lobby) ============ ----

local ClaimPage = Window:Page({ Name = "Auto Claim", Icon = "coins", Columns = 2 })

-- Rewards
local RewardSection = ClaimPage:Section({ Name = "Rewards", Icon = "coins", Side = 1 })

LobbyToggle(RewardSection, "Auto Claim Daily Rewards", "AutoClaimDaily", "Lobby only - claims the login reward as soon as it unlocks")
LobbyToggle(RewardSection, "Auto Claim Quests", "AutoClaimQuests", "Lobby only - Daily / Weekly / Limited-Time, every finished quest")
LobbyToggle(RewardSection, "Auto Claim Achievements", "AutoClaimAchievements", "Lobby only - every finished achievement")
LobbyToggle(RewardSection, "Auto Claim Level Road", "AutoClaimLevelRoad", "Lobby only - every milestone up to your level")
LobbyToggle(RewardSection, "Auto Claim Group Rewards", "AutoClaimGroup", "Lobby only - walks to the group chest and claims it (you must be in the group)")

-- Guild
do
local GuildSection = ClaimPage:Section({ Name = "Guild", Icon = "users", Side = 1 })

LobbyToggle(GuildSection, "Auto Claim Guild Quests", "AutoClaimGuildQuests", "Lobby only - claims finished weekly guild quests and last week's rank reward (you must be in a guild)")

GuildSection:Dropdown({
    Name = "Guild Shop Item",
    Description = "Items bought with Guild Tokens",
    Flag = "AZGuildShopItems",
    Items = Guild.ShopNames,
    KeepOrder = true,
    Multi = true,
    Default = Settings().GuildShopItems,
    Callback = function(Value)
        Settings().GuildShopItems = Value
        SaveSetting()
    end
})

LobbyToggle(GuildSection, "Auto Buy Guild Shop", "AutoBuyGuildShop", "Lobby only - buys the chosen items until the weekly limit or tokens run out")
LobbyToggle(GuildSection, "Auto Donate", "AutoDonate", "Lobby only - donates the amount below to the guild bank once a day")

GuildSection:Slider({
    Name = "Donate Amount",
    Description = "Coins per donation (1,000 - 5,000,000)",
    Flag = "AZDonateAmount",
    Min = 1000,
    Max = 5000000,
    Decimals = 1000,
    Suffix = " coins",
    Default = Settings().DonateAmount,
    Callback = function(Value)
        Settings().DonateAmount = tonumber(Value) or 1000
        SaveSetting()
    end
})
end

-- Lobby
local LobbyActSection = ClaimPage:Section({ Name = "Lobby", Icon = "map-pin", Side = 2 })

-- ==== Fun Event "rain" (วัดสด 2026-10-12 จาก FunEventController / DropRenderer ของเกม) ====
-- ตอนมี event: workspace attr FunEventKind = "rain" (เช่น DICE DROP), FunEventCurrency = rolls / gems / money / luckySpins / traitRerolls
-- server ส่ง FunEventRemote OnClientEvent("Drops", eventId, currency, { { id, ตำแหน่ง, ?, delay วิ } }, หมดเวลา (server time))
-- ของตกลงพื้นหลัง delay + 1.1 วิ ที่ ตำแหน่ง + 3 / เกมเก็บให้เองเมื่อตัวอยู่ใน 12 studs = FireServer("Pick", eventId, id)
-- ได้ของ = OnClientEvent("Got", eventId, currency, จำนวน)
-- -> วาร์ปไปทีละอัน (ใกล้สุดก่อน, lobby ไม่มี anti-cheat) + ยิง Pick เองด้วย แล้วกลับที่เดิม / ระหว่างนี้ Auto Join รอ
--    (อยู่ในคิว / กำลังวาร์ปเข้าแมตช์ = ไม่ไป ออกจากกล่องห้อง = ห้องหลุด)
LobbyLoops.AutoEventDrops = function()
    local Remote = ReplicatedStorage:FindFirstChild("FunEventRemote")
    if not Remote then
        return StopToggle("AZAutoEventDrops", "AutoEventDrops", "Event Drops: game remote not found")
    end
    local Pending, Got, GotCount = { }, { }, 0
    local Hook = Remote.OnClientEvent:Connect(function(Kind, EventId, Currency, List, EndsAt)
        if Kind == "Drops" and type(List) == "table" then
            local Now = os.clock()
            local Expires = Now + (tonumber(EndsAt) or 0) - workspace:GetServerTimeNow()
            for _, Entry in pairs(List) do
                if type(Entry) == "table" and type(Entry[1]) == "number" and typeof(Entry[2]) == "Vector3" then
                    table.insert(Pending, {
                        Event = EventId, Id = Entry[1], Spot = Entry[2] + Vector3.new(0, 3, 0),
                        Ready = Now + (tonumber(Entry[4]) or 0) + 1.2, Expires = Expires,
                    })
                end
            end
        elseif Kind == "Got" and type(List) == "number" and type(Currency) == "string" then
            Got[Currency] = (Got[Currency] or 0) + List
            GotCount = GotCount + 1
        end
    end)

    while Settings().AutoEventDrops and getgenv().ValkyrieSession == SessionToken do
        local Queued = Join.ClientStatus == "inQuque" or Join.ClientStatus == "teleporting"
        if #Pending > 0 and not Queued then
            Join.EventBusy = true
            local Hrp = Root()
            local Back = Hrp and Hrp.Position
            while #Pending > 0 and Settings().AutoEventDrops do
                local Now, Pick = os.clock(), nil
                Hrp = Root()
                for Index = #Pending, 1, -1 do
                    local Drop = Pending[Index]
                    if Now > Drop.Expires then
                        table.remove(Pending, Index)
                    elseif Hrp and Now >= Drop.Ready
                        and (not Pick or (Drop.Spot - Hrp.Position).Magnitude < (Pick.Spot - Hrp.Position).Magnitude) then
                        Pick = Drop
                    end
                end
                if Pick then
                    table.remove(Pending, table.find(Pending, Pick))
                    TweenTo(Pick.Spot)
                    -- อยู่จนเซิร์ฟตอบ Got (สูงสุด 1.5 วิ, ยิง Pick ซ้ำทุก 0.5 วิ) - เดิมยิงหลังวาร์ป 0.15 วิแล้วไปต่อเลย
                    -- = ตำแหน่งฝั่งเซิร์ฟยังไม่ถึง / ตัวดูดของเกม (บินเข้าตัว 0.35 วิ) ยิง Pick ตอนเราไปแล้ว -> ของหาย
                    local Before, Until, Fire = GotCount, os.clock() + 1.5, 0
                    while GotCount == Before and os.clock() < Until do
                        if os.clock() >= Fire then
                            Fire = os.clock() + 0.5
                            pcall(function() Remote:FireServer("Pick", Pick.Event, Pick.Id) end)
                        end
                        task.wait(0.1)
                    end
                else
                    task.wait(0.1)
                end
            end
            task.wait(0.6) -- ตัวดูดของเกมเก็บอันสุดท้ายให้ทัน
            if Back then TweenTo(Back) end
            Join.EventBusy = nil
            task.wait(1)
        end
        -- สรุปที่ได้ (Got มาหลังยิง Pick นิดหน่อย)
        if not Join.EventBusy and next(Got) then
            for Currency, Amount in pairs(Got) do
                local Name = Currency
                for _, Entry in ipairs(Webhook.Currencies) do
                    if Entry.Key == Currency then Name = Entry.en end
                end
                Webhook.Push("Rewards Claimed", "event:" .. Currency .. ":" .. os.clock(), Webhook.T("EventDrops", Webhook.Num(Amount), Name))
                OnUi(function() Library:Notify("Valkyrie Hub", ("Event drops: +%s %s"):format(Webhook.Num(Amount), Name), 6) end)
            end
            table.clear(Got)
        end
        task.wait(0.2)
    end
    Hook:Disconnect()
    Join.EventBusy = nil
end

LobbyToggle(LobbyActSection, "Auto Collect Event Drops", "AutoEventDrops", "Lobby only - during rain events (DICE DROP and the like) teleports to every drop, then back to where you were")

LobbyToggle(LobbyActSection, "Auto Enter AFK World", "AutoEnterAfk", "Lobby only - teleports to the AFK World (waits while Auto Join is on)")
LobbyToggle(LobbyActSection, "Auto Delivery", "AutoDelivery", "Lobby only - runs Heiyun's packages until the daily limit (waits while Auto Join is on)")

local DeliveryLabel = LobbyActSection:Label("Delivered Today: - / 50", true)

LobbyActSection:Button({
    Name = "Redeem All Codes",
    Callback = function()
        task.spawn(RedeemAllCodes)
    end
})

-- จำนวนส่งของวันนี้ = deliveryState ที่ server ส่งมาทุกครั้งที่สถานะเปลี่ยน (ฟังตลอด ไม่ต้องเปิด toggle) + refresh ครั้งแรกตอนโหลด
task.spawn(function()
    if not (IsLobby and LoadLobby()) then return end
    local Phases = { carrying = "Carrying", delivered = "Ready to claim", capped = "Limit reached" }
    table.insert(Join.Hooks, Lobby.Packets.deliveryState:on(function(Info)
        if type(Info) ~= "table" or getgenv().ValkyrieSession ~= SessionToken then return end
        OnUi(function()
            local function Tr(Text)
                local Ok, Out = pcall(function() return LibraryMilenium:translate(Text) end)
                return Ok and type(Out) == "string" and Out or Text
            end
            local Text = ("%s: %d / %d"):format(Tr("Delivered Today"), tonumber(Info.dailyCount) or 0, tonumber(Info.dailyLimit) or 50)
            if Phases[Info.status] then Text = Text .. " - " .. Tr(Phases[Info.status]) end
            DeliveryLabel:SetText(Text)
        end)
    end))
    RequestId = RequestId % 65535 + 1
    Lobby.Packets.deliveryAction:fire({ action = "refresh", requestId = RequestId })
end)

---- ============ Miscellaneous Tab (lobby) ============ ----

local MiscPage = Window:Page({ Name = "Miscellaneous", Icon = "map-pin", Columns = 2 })

local AreaNames = { }
for _, Target in ipairs(AreaTargets) do table.insert(AreaNames, Target.Name) end

-- Areas
local AreaSection = MiscPage:Section({ Name = "Areas", Icon = "map-pin", Side = 1 })

AreaSection:Dropdown({
    Name = "Area",
    Description = "Trophy Road opens its window instead of teleporting",
    Flag = "AZTeleportArea",
    Items = AreaNames,
    KeepOrder = true,
    Default = Settings().TeleportArea,
    Callback = JoinSetting("TeleportArea")
})

AreaSection:Button({
    Name = "Teleport",
    Callback = function()
        task.spawn(TeleportArea)
    end
})

-- Titles
local TitleSection = MiscPage:Section({ Name = "Titles", Icon = "info", Side = 2 })

LobbyToggle(TitleSection, "Auto Equip Best Title", "AutoEquipTitle", "Lobby only - wears the owned title with the most damage (then the most total buffs)")

---- ============ Notification > Webhook ============ ----

Window:Category("Notification")

do
local WebhookPage = Window:Page({ Name = "Webhook", Icon = "bell", Columns = 2 })

-- งาน require โมดูลเกม (ถ่ายยอดบัญชี) ห้ามทำในเธรด UI -> แตกเธรดแล้วแจ้งผลผ่าน OnUi
local function Run(Work)
    task.spawn(function()
        local Ok, Done, Err = pcall(Work)
        local Text = (Ok and Done ~= false) and "Webhook: sent" or ("Webhook: failed - " .. tostring(Ok and Err or Done))
        OnUi(function() Library:Notify("Valkyrie Hub", Text, 5) end)
    end)
end

local SetupSection = WebhookPage:Section({ Name = "Discord Webhook", Icon = "send", Side = 1 })

SetupSection:Toggle({
    Name = "Enable Webhook",
    Description = "Send notifications to your Discord channel",
    Flag = "AZWebhookEnabled",
    Default = Settings().WebhookEnabled,
    Callback = function(Value)
        Settings().WebhookEnabled = Value
        SaveSetting()
    end
})

SetupSection:Textbox({
    Name = "Webhook URL",
    Placeholder = "https://discord.com/api/webhooks/...",
    Default = Settings().WebhookUrl,
    Flag = "AZWebhookUrl",
    Callback = function(Text)
        Settings().WebhookUrl = tostring(Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
        SaveSetting()
    end
})

SetupSection:Dropdown({
    Name = "Message Language",
    Description = "Hub Language = follows the language picked in Configuration",
    Flag = "AZWebhookLanguage",
    Items = { "Hub Language", "English", "Thai" },
    KeepOrder = true,
    Default = Settings().WebhookLanguage,
    Callback = function(Value)
        Settings().WebhookLanguage = Value
        SaveSetting()
    end
})

SetupSection:Toggle({
    Name = "Hide Username",
    Description = "Show your name as a spoiler and hide it from the footer",
    Flag = "AZWebhookHideName",
    Default = Settings().WebhookHideName,
    Callback = function(Value)
        Settings().WebhookHideName = Value
        SaveSetting()
    end
})

SetupSection:Button({ Name = "Test Webhook", Callback = function() Run(Webhook.Test) end })
SetupSection:Button({ Name = "Send Session Summary Now", Callback = function() Run(function() Webhook.Summary(true) end) end })
SetupSection:Button({
    Name = "Reset Session",
    Callback = function()
        task.spawn(function()
            Webhook.Session = nil
            pcall(delfile, Webhook.SessionFile)
            Webhook.LoadSession(Webhook.Snapshot())
            OnUi(function() Library:Notify("Valkyrie Hub", "Webhook: session reset", 5) end)
        end)
    end
})

local MentionSection = WebhookPage:Section({ Name = "Mention", Icon = "users", Side = 1 })

MentionSection:Textbox({
    Name = "Discord User ID",
    Placeholder = "123456789012345678",
    Default = Settings().WebhookPingId,
    Flag = "AZWebhookPingId",
    Callback = function(Text)
        Settings().WebhookPingId = tostring(Text or ""):match("%d+") or ""
        SaveSetting()
    end
})

MentionSection:Dropdown({
    Name = "Mention On",
    Description = "Ping you only for these notifications",
    Flag = "AZWebhookPingEvents",
    Items = Webhook.Events,
    KeepOrder = true,
    Multi = true,
    Default = Settings().WebhookPingEvents,
    Callback = function(Value)
        Settings().WebhookPingEvents = Value
        SaveSetting()
    end
})

local EventSection = WebhookPage:Section({ Name = "Notify On", Icon = "bell", Side = 2 })

EventSection:Dropdown({
    Name = "Notifications",
    Description = "Which events send a message",
    Flag = "AZWebhookEvents",
    Items = Webhook.Events,
    KeepOrder = true,
    Multi = true,
    Default = Settings().WebhookEvents,
    Callback = function(Value)
        Settings().WebhookEvents = Value
        SaveSetting()
    end
})

EventSection:Dropdown({
    Name = "Summon Rarities",
    Description = "Only summons of these rarities are reported",
    Flag = "AZWebhookSummonRarities",
    Items = { "Epic", "Legendary", "Mythic", "Arcane", "LYTH" },
    KeepOrder = true,
    Multi = true,
    Default = Settings().WebhookSummonRarities,
    Callback = function(Value)
        Settings().WebhookSummonRarities = Value
        SaveSetting()
    end
})

EventSection:Slider({
    Name = "Session Summary Every",
    Description = "Minutes between summaries (0 = off)",
    Flag = "AZWebhookSummaryMinutes",
    Min = 0,
    Max = 240,
    Decimals = 5,
    Suffix = " min",
    Default = Settings().WebhookSummaryMinutes,
    Callback = function(Value)
        Settings().WebhookSummaryMinutes = tonumber(Value) or 0
        SaveSetting()
    end
})

EventSection:Guide("What each notification sends", {
    "Match Result: win or loss, mode, map, difficulty, waves, kills, match time and every item gained",
    "Summon / Trait Reroll: what was rolled (repeats are grouped into one line)",
    "Evolution, Shop & Convert, Crafting, Rewards Claimed, Character Upgrades: what the hub did and what changed",
    "Auto Stopped: why an auto feature turned itself off, or a stuck match",
    "Disconnected: the kick or disconnect message, sent right away",
    "Session Summary: run time, matches won and lost, and total gained since the session started",
})

EventSection:Guide("How to get a webhook URL", {
    "Discord: Server Settings > Integrations > Webhooks > New Webhook",
    "Pick the channel, press Copy Webhook URL, paste it above",
    "Turn on Enable Webhook, then press Test Webhook",
    "User ID: Discord Settings > Advanced > Developer Mode, then right click your name > Copy User ID",
})

Webhook.Start()
end

-- Website: ส่งสถานะบัญชีขึ้นหน้า "แบบธรรมดา" ของเว็บ (valkyriehub.net/account/kaitan?mode=manual)
-- POST /api/kaitan/report แบบเดียวกับ GFCKT.lua: header x-valkyrie-key = license key ที่ loader ยืนยันแล้ว
-- (getgenv().ValkyrieKey / LicenseKey / License / Key หรือไฟล์ Valkyrie Hub/MyKey/key.txt) / mode = "manual"
-- เว็บเก็บในหน่วยความจำ: ไม่ส่งเกิน 90 วิ = ขึ้น offline / 30 นาที = ลบออก -> ส่งทุก 15 วิถ้ามีอะไรเปลี่ยน อย่างน้อยทุก 60 วิ
-- state.Game / Stats (การ์ดหน้ารวม 4 ช่อง) / Sections (หน้าข้อมูล) = รูปแบบกลางของเว็บสำหรับเกมที่ไม่ใช่ GFC
do
local WebsitePage = Window:Page({ Name = "Website", Icon = "globe", Columns = 2 })
local Site = {
    Url = "https://www.valkyriehub.net/api/kaitan/report",
    Page = "https://www.valkyriehub.net/account/kaitan?mode=manual",
    Http = request or http_request or (syn and syn.request) or (http and http.request),
    StartedAt = os.clock(), PostAt = 0, Quiet = 0, Text = "Waiting...",
    -- Control Script (หน้าเว็บสั่งเปิด/ปิด toggle): คำสั่งที่ทำแล้ว (กันทำซ้ำ) / id ที่ยังไม่ได้แจ้งเว็บ / เว็บเปิด popup อยู่ถึงเมื่อไหร่
    Control = "https://www.valkyriehub.net/api/kaitan/control",
    Done = { }, Acks = { }, FastUntil = 0, PollAt = 0,
    FlagAt = { }, -- [flag] = เวลาสร้างคำสั่งล่าสุดที่ทำ (ms ฝั่งเว็บ) - คำสั่งเก่ากว่าที่มาถึงทีหลัง (เว็บหลาย instance) ไม่ทับ
}

function Site.Key()
    if Site.CachedKey then return Site.CachedKey end
    for _, Name in ipairs({ "ValkyrieKey", "LicenseKey", "License", "Key" }) do
        local Value = getgenv()[Name]
        if type(Value) == "string" and Value ~= "" then
            Site.CachedKey = Value:gsub("%s", "")
            return Site.CachedKey
        end
    end
    local Ok, Value = pcall(function() return isfile("Valkyrie Hub/MyKey/key.txt") and readfile("Valkyrie Hub/MyKey/key.txt") end)
    if Ok and type(Value) == "string" and Value ~= "" then
        Site.CachedKey = Value:gsub("%s", "")
        return Site.CachedKey
    end
end

function Site.Executor()
    local Ok, Name, Version = pcall(function() return identifyexecutor() end)
    if not Ok or type(Name) ~= "string" then return "unknown" end
    return type(Version) == "string" and Version ~= "" and (Name .. " " .. Version) or Name
end

-- ชื่อตัวละครแบบในเกม (หน้า Summon) / ไม่มีในรายการ = id ตัวแรกพิมพ์ใหญ่
function Site.CharacterName(Id)
    local Entry = PoolByName(Id)
    return Entry and Entry.Name or (tostring(Id):gsub("^%l", string.upper))
end

-- แมตช์ตอนนี้: { Map, Detail } จาก workspace attribute + runStore (lobby = nil)
function Site.Match()
    local Mode = workspace:GetAttribute("Mode")
    if IsLobby or type(Mode) ~= "string" then return nil end
    local Names = { hxh = "Story - Hxh", sololevelingraid = "Raid - Shadow Gate", spiritedawayraid = "Raid - Spirit's Bathtub", sakamoto = "Defend", zzz = "Infinite - ZZZ World" }
    local Map = Names[Mode] or Mode
    local Run = Webhook.Config("game", "stores", "runStore")
    local State = Run and Run.store and Run.store.state
    local Parts = { }
    local Chapter = State and tonumber(Read(State.chapter))
    if Mode == "hxh" and Chapter and Chapter > 0 then Map = Map .. " Act " .. Chapter end
    local Difficulty = DifficultyNames[tonumber(workspace:GetAttribute("QueueDifficulty")) or 0]
    if Difficulty then table.insert(Parts, Difficulty) end
    if State then
        local Area, Wave, Waves = tonumber(Read(State.area)), tonumber(Read(State.wave)), tonumber(Read(State.waveCount))
        if Area and Area > 0 then table.insert(Parts, "Area " .. Area) end
        if Wave and Waves and Waves > 0 then table.insert(Parts, ("Wave %d/%d"):format(Wave, Waves)) end
    end
    return { Map = Map, Detail = table.concat(Parts, " - ") }
end

-- รายงานแบบ webhook (หน้าเว็บวาดเอง): ไอคอน = ชื่อไฟล์ใน public/games/anime-zero/<icon>.png ของเว็บ
-- (ดึงจากเกมไว้แล้ว: currency-<key> / material-<id> / accessory-<id>) - ไม่มีไฟล์ = เว็บโชว์ตัวอักษรแทน
-- ตัวเลขส่งเป็นตัวเลขดิบ ให้เว็บจัดรูปเอง / ข้อความภาษาอังกฤษ (หน้าเว็บเป็นไทย แปลชื่อหัวข้อเอง)
function Site.Payload()
    local Shot = Webhook.Snapshot()
    if not Shot then return nil end
    local Data = Evo.Data()
    local Money = Shot.Currencies
    local Match = Site.Match()
    local Session = Webhook.Session or { }
    local Matches, Wins = tonumber(Session.Matches) or 0, tonumber(Session.Wins) or 0
    -- เวลาเล่นนับจากต้น session ของ Webhook (ชุดเดียวกับจำนวนแมตช์ / ชนะ) - ยังไม่มี = นับจากเปิด hub
    local Runtime = tonumber(Session.Start) and os.time() - Session.Start or os.clock() - Site.StartedAt
    local Stats = type(Shot.Stats) == "table" and Shot.Stats or { }

    local Level = nil
    pcall(function()
        local Info = Webhook.Config("global", "utils", "levelProgression").getProgress(Money.xp or 0)
        Level = { level = tonumber(Info.level), xp = tonumber(Info.currentXp), need = tonumber(Info.requiredXp), max = Info.isMaxLevel == true }
    end)

    -- ยอดเงิน + เปลี่ยนไปเท่าไหร่ในรอบนี้ / ของที่ได้ - เสีย (ไม่รวมเงิน)
    local Base = type(Session.Shot) == "table" and Session.Shot or Shot
    local Currencies = { }
    for _, Entry in ipairs(Webhook.Currencies) do
        if Entry.Key ~= "xp" then
            local Value = tonumber(Money[Entry.Key]) or 0
            local Before = type(Base.Currencies) == "table" and tonumber(Base.Currencies[Entry.Key]) or Value
            table.insert(Currencies, { icon = "currency-" .. Entry.Key, label = Entry.en, value = Value, delta = Value - Before })
        end
    end
    local Gains = { }
    for _, Line in ipairs(Webhook.Diff(Base, Shot)) do
        if Line.Key and not Line.Key:find("^currency:") and #Gains < 24 then
            table.insert(Gains, { icon = (Line.Key:gsub(":", "-")), label = tostring(Line.Name), delta = Line.Delta, total = Line.Total })
        end
    end

    -- แมตช์ล่าสุด (matchHistory ใหม่สุดก่อน, time = unix)
    local Recent = { }
    local Ok, History = pcall(function() return HttpService:JSONDecode(Shot.History) end)
    for _, Entry in ipairs(Ok and type(History) == "table" and History or { }) do
        if #Recent >= 6 then break end
        if type(Entry) == "table" then
            table.insert(Recent, {
                won = Entry.won == true,
                mode = tostring(Entry.mode or "-"), map = tostring(Entry.map or "-"), difficulty = tostring(Entry.difficulty or "-"),
                wave = tonumber(Entry.wave) or 0, kills = tonumber(Entry.kills) or 0, at = tonumber(Entry.time) or 0,
                character = Entry.character and Site.CharacterName(Entry.character) or "-",
            })
        end
    end

    local Team = { }
    local ShownLocked = false
    for Slot = 1, Evo.SlotCount do
        local Entry = Data and Data.UnlockedCharacters and Data.UnlockedCharacters["Slot" .. Slot]
        local Row = { slot = Slot, locked = true }
        -- 15 ช่อง (อัปเดต 3): ส่งช่องที่ปลดแล้ว + ช่องล็อกช่องแรก (ช่องถัดไปที่ซื้อได้)
        if not (type(Entry) == "table" and Entry.Unlocked) then
            if ShownLocked then continue end
            ShownLocked = true
        end
        if type(Entry) == "table" and Entry.Unlocked then
            local Id = type(Entry.Character) == "string" and Entry.Character or ""
            local Pool = Id ~= "" and PoolByName(Id)
            local Info = Id ~= "" and Data.CharactersData and Data.CharactersData[Id]
            Row = {
                slot = Slot, locked = false,
                name = Id ~= "" and Site.CharacterName(Id) or nil,
                rarity = Pool and RarityLabel(Pool.Rarity) or nil,
                evolved = type(Info) == "table" and Info.IsUltimateUnlocked == true or false,
            }
        end
        table.insert(Team, Row)
    end

    local LevelText = Level and Level.level and tostring(Level.level) or "-"
    return {
        mode = "manual",
        userId = LocalPlayer.UserId,
        -- Hide Name: เว็บโชว์ "Valkyrie Hub" และไม่โชว์รูปหัว (hideName)
        name = Settings().HideName and "Valkyrie Hub" or LocalPlayer.Name,
        displayName = Settings().HideName and "Valkyrie Hub" or LocalPlayer.DisplayName,
        hideName = Settings().HideName or nil,
        placeId = game.PlaceId,
        jobId = game.JobId,
        players = #Players:GetPlayers(),
        uptime = math.floor(os.clock() - Site.StartedAt),
        phase = Match and "Match" or "Lobby",
        action = Join.Text or (Match and (Match.Map .. (Match.Detail ~= "" and (" - " .. Match.Detail) or ""))) or "Idle",
        executor = Site.Executor(),
        progress = 0,
        parts = { },
        state = {
            Game = "Anime Zero",
            -- การ์ดหน้ารวม (เว็บเก่าที่ยังไม่รู้จักรายงานก็ยังโชว์ได้)
            Stats = {
                { label = "Level", value = LevelText, hint = Webhook.Num(Money.gems) .. " gems" },
                { label = "Coins", value = Webhook.Num(Money.money), hint = Webhook.Num(Money.rolls) .. " rolls", icon = "currency-money" },
                { label = Match and "Match" or "Lobby", value = Match and Match.Map or "In lobby", hint = Match and Match.Detail or nil },
                { label = "Session", value = ("%d / %d wins"):format(Wins, Matches), hint = Webhook.Clock(Runtime) },
            },
            Report = {
                level = Level,
                location = Match and { inMatch = true, map = Match.Map, detail = Match.Detail } or { inMatch = false },
                currencies = Currencies,
                gains = Gains,
                recent = Recent,
                team = Team,
                session = { runtime = math.floor(Runtime), matches = Matches, wins = Wins },
                totals = { played = tonumber(Stats.played) or 0, wins = tonumber(Stats.wins) or 0, kills = tonumber(Stats.kills) or 0, deaths = tonumber(Stats.deaths) or 0 },
            },
        },
    }
end

-- โครง UI + ค่าตอนนี้ของทุก element (Library.Controls จด Page > Section > element ตอนสร้าง) ชื่อตามภาษาที่เลือกใน hub
-- ตัวเลือก dropdown ไม่แปล (เป็นค่าที่ส่งกลับมาตรงตัว) / ไม่ส่ง Show on Website (ปิดจากเว็บ = ตัดการควบคุมตัวเอง)
function Site.Controls()
    local Pages = { }
    for _, Page in ipairs(Library.Controls) do
        local Out = { name = Library.Tr(Page.Name), icon = Page.Icon, category = Page.Category and Library.Tr(Page.Category) or nil, sections = { } }
        for _, Section in ipairs(Page.Sections) do
            local Box = { name = Library.Tr(Section.Name), icon = Section.Icon, side = Section.Side, items = { } }
            for _, Item in ipairs(Section.Items) do
                if Item.Flag ~= "AZWebsiteReport" then
                    local Value = Library.Flags[Item.Flag]
                    local Row = {
                        flag = Item.Flag,
                        kind = Item.Kind,
                        name = Library.Tr(Item.Name),
                        desc = Item.Description and Library.Tr(Item.Description) or nil,
                    }
                    if Item.Kind == "toggle" then
                        Row.value = Value == true
                    elseif Item.Kind == "slider" then
                        Row.value, Row.min, Row.max, Row.step, Row.suffix = tonumber(Value) or Item.Min, Item.Min, Item.Max, Item.Step, Item.Suffix
                    elseif Item.Kind == "dropdown" then
                        Row.options, Row.multi = { }, Item.Multi
                        for _, Option in ipairs(Item.Options or { }) do table.insert(Row.options, tostring(Option)) end
                        if Item.Multi then
                            Row.value = { }
                            for _, Option in ipairs(type(Value) == "table" and Value or { }) do table.insert(Row.value, tostring(Option)) end
                        else
                            Row.value = Value ~= nil and tostring(Value) or ""
                        end
                    elseif Item.Kind == "textbox" then
                        Row.value, Row.placeholder = tostring(Value or ""), Item.Placeholder
                    end
                    table.insert(Box.items, Row)
                end
            end
            if #Box.items > 0 then table.insert(Out.sections, Box) end
        end
        if #Out.sections > 0 then table.insert(Pages, Out) end
    end
    return Pages
end

-- ค่าจากเว็บ -> ค่าที่ element นี้รับได้ (nil = ไม่รับ): toggle true/false, slider ตัวเลขในช่วง (ปัดตาม step),
-- dropdown ต้องอยู่ในตัวเลือกตอนนี้, textbox ข้อความ, ปุ่มไม่มีค่า
function Site.Accept(Item, Value)
    if Item.Kind == "toggle" then
        -- (ไม่ใช้ and/or: Value = false จะกลายเป็น nil = สั่งปิดไม่ได้)
        if type(Value) == "boolean" then return Value end
        return nil
    elseif Item.Kind == "slider" then
        local Number = tonumber(Value)
        if not Number or Number ~= Number then return nil end
        local Step = (tonumber(Item.Step) or 1) > 0 and tonumber(Item.Step) or 1
        Number = math.floor((Number - Item.Min) / Step + 0.5) * Step + Item.Min
        return math.clamp(Number, Item.Min, Item.Max)
    elseif Item.Kind == "dropdown" then
        local Has = { }
        for _, Option in ipairs(Item.Options or { }) do Has[tostring(Option)] = Option end
        if Item.Multi then
            if type(Value) ~= "table" then return nil end
            local List = { }
            for _, Option in ipairs(Value) do
                if Has[tostring(Option)] == nil then return nil end
                if not table.find(List, Has[tostring(Option)]) then table.insert(List, Has[tostring(Option)]) end
            end
            return List
        end
        return Has[tostring(Value)]
    elseif Item.Kind == "textbox" then
        return type(Value) == "string" and #Value <= 500 and Value or nil
    end
    return nil
end

function Site.Same(A, B)
    if type(A) == "table" and type(B) == "table" then
        if #A ~= #B then return false end
        for _, Value in ipairs(A) do
            if not table.find(B, Value) then return false end
        end
        return true
    end
    if type(A) == "number" and type(B) == "number" then return math.abs(A - B) < 1e-6 end
    return A == B
end

-- คำสั่งจากเว็บ { id, flag, value } -> ตั้งค่า/กดปุ่มแทนผู้ใช้ (SetFlags ยิง callback เหมือนกดเอง - ต้องทำในเธรด UI)
-- รับเฉพาะ element ที่มีใน UI จริง + ค่าที่ element นั้นรับได้ / id ซ้ำ (เว็บส่งซ้ำจนกว่าจะได้ ack) ไม่ทำซ้ำแต่ ack ใหม่
function Site.Apply(Reply)
    if type(Reply) ~= "table" then return end
    if Reply.fast then Site.FastUntil = os.clock() + 20 end
    local Applied = false
    for _, Command in ipairs(type(Reply.commands) == "table" and Reply.commands or { }) do
        local Id = type(Command) == "table" and type(Command.id) == "string" and Command.id
        if Id and not table.find(Site.Acks, Id) then
            table.insert(Site.Acks, Id)
        end
        if Id and not Site.Done[Id] then
            Site.Done[Id] = true
            local Item = Library.ControlIndex[tostring(Command.flag)]
            if Item and Item.Flag ~= "AZWebsiteReport" then
                if Item.Kind == "button" then
                    Applied = true
                    OnUi(function() task.spawn(Item.Callback) end)
                elseif (tonumber(Command.at) or 0) >= (Site.FlagAt[Item.Flag] or 0) then
                    Site.FlagAt[Item.Flag] = tonumber(Command.at) or 0
                    local Value = Site.Accept(Item, Command.value)
                    if Value ~= nil then
                        Applied = true
                        OnUi(function()
                            local Set = Library.SetFlags[Item.Flag]
                            if Set and not Site.Same(Library.Flags[Item.Flag], Value) then Set(Value) end
                        end)
                    end
                end
            end
        end
    end
    -- เปลี่ยนแล้วส่งสถานะใหม่ทันที (หน้าเว็บรอดูว่าค่าเปลี่ยนจริงไหม)
    if Applied then task.delay(0.6, function() pcall(Site.Report, true) end) end
end

function Site.Decode(Response)
    local Body = type(Response) == "table" and Response.Body
    local Ok, Data = pcall(function() return HttpService:JSONDecode(Body) end)
    return Ok and type(Data) == "table" and Data or nil
end

-- ถามคำสั่งอย่างเดียว (เบากว่ารายงาน) ทุก 2 วิ ตอนหน้าเว็บเปิด Control Script อยู่ (fast)
function Site.Poll()
    local Key = Site.Key()
    if not (Key and Site.Http) then return end
    local Acks = Site.Acks
    Site.Acks = { }
    local Ok, Response = pcall(Site.Http, {
        Url = Site.Control,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json", ["x-valkyrie-key"] = Key },
        Body = HttpService:JSONEncode({ userId = LocalPlayer.UserId, acks = Acks }),
    })
    local Code = Ok and type(Response) == "table" and tonumber(Response.StatusCode or Response.Status)
    if not (Code and Code >= 200 and Code < 300) then
        for _, Id in ipairs(Acks) do table.insert(Site.Acks, Id) end
        return
    end
    Site.Apply(Site.Decode(Response))
end

-- ส่ง (เธรดแยก): ไม่เปลี่ยน (ตัด uptime ออกก่อนเทียบ) = ไม่ส่งจนครบ 60 วิ / ส่งไม่ผ่าน = เว้น 60 วิ
function Site.Report(Force)
    if not Settings().WebsiteReport or not Site.Http then return end
    local Now = os.clock()
    if not Force and Now < Site.Quiet then return end
    local Key = Site.Key()
    if not Key then
        Site.Text = "No license key found - run the hub through the loader"
        return
    end
    local Payload = Site.Payload()
    if not Payload then return end
    -- โครง UI ส่งเป็นสตริง JSON ก้อนเดียว (2026-10-13): ส่งเป็น JSON ซ้อนแล้วเกิน 1000 key = ModSecurity ของเว็บตีกลับ
    -- (Apache บล็อกก่อนถึงเว็บ - รายงานไม่ขึ้นเลย) / เว็บแกะ ControlsJson กลับเป็น Controls เอง
    local ControlsOk, ControlsJson = pcall(HttpService.JSONEncode, HttpService, Site.Controls())
    Payload.state.ControlsJson = ControlsOk and ControlsJson or nil
    local Acks = Site.Acks
    Payload.acks = Acks
    -- ลายนิ้วมือ = payload ที่เอาค่าที่เดินเองทุกวินาที (เวลา) ออก -> มีอะไรเปลี่ยนจริงค่อยส่ง
    local Uptime, Runtime, Hint = Payload.uptime, Payload.state.Report.session.runtime, Payload.state.Stats[4].hint
    Payload.uptime, Payload.state.Report.session.runtime, Payload.state.Stats[4].hint = 0, 0, ""
    local Printed, Print = pcall(HttpService.JSONEncode, HttpService, Payload)
    Payload.uptime, Payload.state.Report.session.runtime, Payload.state.Stats[4].hint = Uptime, Runtime, Hint
    local Made, Body = pcall(HttpService.JSONEncode, HttpService, Payload)
    if not (Made and Printed) then return end
    if not Force and #Acks == 0 and Print == Site.Print and Now - Site.PostAt < 60 then return end
    Site.Acks = { }

    local Ok, Response = pcall(Site.Http, {
        Url = Site.Url,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json", ["x-valkyrie-key"] = Key },
        Body = Body,
    })
    local Code = Ok and type(Response) == "table" and tonumber(Response.StatusCode or Response.Status)
    if Code and Code >= 200 and Code < 300 then
        Site.Print, Site.PostAt, Site.Quiet = Print, Now, 0
        Site.Text = "Sent at " .. os.date("%H:%M:%S")
        Site.Apply(Site.Decode(Response))
    else
        for _, Id in ipairs(Acks) do table.insert(Site.Acks, Id) end
        Site.Quiet = Now + 60
        local Reason = Code == 401 and "license key was not accepted" or Code == 429 and "account limit reached" or tostring(Code or "no response")
        Site.Text = "Failed (" .. Reason .. ") - retrying in 60s"
    end
end

local SiteSection = WebsitePage:Section({ Name = "Website", Icon = "globe", Side = 1 })
SiteSection:Toggle({
    Name = "Show on Website",
    Description = "Sends this account's status to your dashboard on valkyriehub.net every few seconds",
    Flag = "AZWebsiteReport",
    Default = Settings().WebsiteReport,
    Seperator = true,
    Callback = function(Value)
        Settings().WebsiteReport = Value
        SaveSetting()
        if Value then task.spawn(Site.Report, true) else Site.Text = "Off" end
    end
})
local StatusLabel = SiteSection:Label("Status: -")
SiteSection:Button({
    Name = "Copy Dashboard Link",
    Callback = function()
        local Ok = pcall(setclipboard, Site.Page)
        Library:Notify("Valkyrie Hub", Ok and "Dashboard link copied" or "Copy is not supported on this executor", 4)
    end
})
SiteSection:Button({ Name = "Send Now", Callback = function() task.spawn(Site.Report, true) end })
-- ส่งรายงานทันทีจากหน้าอื่น (Site อยู่ใน block นี้ - เช่น Hide Name ให้เว็บเปลี่ยนชื่อทันที)
Library.ReportNow = function() pcall(Site.Report, true) end

local HelpSection = WebsitePage:Section({ Name = "How to view", Icon = "info", Side = 2 })
HelpSection:Guide("How to view", {
    "Turn on Show on Website",
    "Open valkyriehub.net and log in with the same Discord as your key",
    "Account > Kaitan > Manual (or press Copy Dashboard Link)",
    "Each account running the hub shows up with its level, coins, team and match",
    "No update for 90 seconds = shown as offline",
})

-- วนส่ง + อัปเดตข้อความสถานะ (ข้อความผ่าน OnUi - เธรดนี้ require โมดูลเกม)
task.spawn(function()
    local Tick = 0
    task.wait(3)
    if Settings().WebsiteReport then pcall(Site.Report) end
    while getgenv().ValkyrieSession == SessionToken do
        -- รายงานทุก 15 วิ / หน้าเว็บเปิด Control Script = ถามคำสั่งทุก 2 วิ
        repeat
            task.wait(1)
            Tick = Tick + 1
            if Settings().WebsiteReport and os.clock() < Site.FastUntil and os.clock() - Site.PollAt >= 2 then
                Site.PollAt = os.clock()
                pcall(Site.Poll)
            end
        until Tick % 15 == 0 or getgenv().ValkyrieSession ~= SessionToken
        -- ไม่มีอะไรเปลี่ยน = รายงานเว้นได้ถึง 60 วิ -> ถามคำสั่งแทน (คำสั่งจากเว็บช้าสุด ~15 วิ ไม่ใช่ 60)
        if Settings().WebsiteReport then
            local Posted = Site.PostAt
            pcall(Site.Report)
            if Site.PostAt == Posted then pcall(Site.Poll) end
        end
        local Text = Settings().WebsiteReport and Site.Text or "Off"
        OnUi(function() StatusLabel:SetText(Library.Tr("Status") .. ": " .. Library.Tr(Text)) end)
    end
end)
end

---- ============ Configuration Tab ============ ----

task.wait()

Window:Category("Settings")

local ConfigPage = Window:Page({ Name = "Configuration", Icon = "settings", Columns = 2 })

local InterfaceSection = ConfigPage:Section({
    Name = "Interface",
    Description = "Window and executor options",
    Icon = "93142176757189",
    Side = 1
})

-- ธีมของ Milenium (Milenium, Midnight, Sakura ...) เปลี่ยนแล้วเห็นผลทันที
InterfaceSection:Dropdown({
    Name = "Theme",
    Flag = "AZTheme",
    Items = Library:Themes(),
    Default = getgenv().ConfigurationTable.Theme,
    Multi = false,
    Callback = function(Value)
        if type(Value) ~= "string" or Value == "" then return end

        getgenv().ConfigurationTable.Theme = Value
        Library:SetTheme(Value)
        SaveConfiguration()
    end
})

-- เหมือน WizardWest: Roblox ยิง LocalPlayer.Idled ตอนไม่มี input ~20 นาที -> คลิกขวาผ่าน VirtualUser รีเซ็ตตัวจับเวลา
local AntiAfkConnection = nil

InterfaceSection:Toggle({
    Name = "Anti-AFK",
    Flag = "AZAntiAFK",
    Default = getgenv().ConfigurationTable.AntiAFK,
    Callback = function(Value)
        getgenv().ConfigurationTable.AntiAFK = Value
        SaveConfiguration()

        if Value then
            if AntiAfkConnection then return end

            local VirtualUser = game:GetService("VirtualUser")
            AntiAfkConnection = TrackConnection(LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end))
        elseif AntiAfkConnection then
            AntiAfkConnection:Disconnect()
            AntiAfkConnection = nil
        end
    end
})

local AutoRejoinConnection = nil

InterfaceSection:Toggle({
    Name = "Auto Rejoin",
    Flag = "AZAutoRejoin",
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
    Flag = "AZAutoExecutor",
    Default = getgenv().ConfigurationTable.AutoExecutor,
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoExecutor = Value
        SaveConfiguration()
        if Value then QueueLoader() end
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
    Flag = "AZMinimizeBind",
    Default = KeyFromName(getgenv().ConfigurationTable.MinimizeBind),
    Mode = "Toggle",
    ShowModes = false,
    Callback = function(Key)
        if typeof(Key) ~= "EnumItem" then return end

        local KeyName = Key.Name
        if getgenv().ConfigurationTable.MinimizeBind ~= KeyName then
            getgenv().ConfigurationTable.MinimizeBind = KeyName
            SaveConfiguration()
        end
    end
})

---- ============ FPS ============ ----

-- Hide Name (ผู้ใช้ 2026-10-10): ชื่อเรา (DisplayName / Name) ทุกจุดบนจอ = "Valkyrie Hub"
-- จุดที่เจอ: โปรไฟล์ซ้ายล่าง (LobbyHUD.Profile), หน้า Profile, ป้ายบนหัว (OverHead) + playerlist ของ Roblox
-- แก้เฉพาะเครื่องเรา (คนอื่นยังเห็นชื่อจริง) / จำข้อความเดิมไว้คืนตอนปิด / เกมเขียนข้อความใหม่ทับ = แทนอีกรอบ
-- ไม่แตะช่องพิมพ์ (TextBox) / webhook + หน้าเว็บใช้ค่าเดียวกัน (Webhook.PlayerName, Site.Payload)
do
    -- ตัวแปรรวมในตารางเดียว (local ของ main chunk ใกล้เพดาน 200)
    local H = {
        Masked = setmetatable({ }, { __mode = "k" }), -- [label] = ข้อความของเกมก่อนแทน
        Wrote = setmetatable({ }, { __mode = "k" }),  -- [label] = ข้อความที่เราเขียนเอง
        Hooked = setmetatable({ }, { __mode = "k" }),
        Watchers = { },
    }

    function H.Replace(Text)
        local Names = { LocalPlayer.Name, LocalPlayer.DisplayName }
        table.sort(Names, function(A, B) return #A > #B end) -- ยาวก่อน (ชื่อหนึ่งอาจอยู่ในอีกชื่อ)
        for _, Name in ipairs(Names) do
            if Name ~= "" then Text = Text:gsub(Name:gsub("%W", "%%%0"), "Valkyrie Hub") end
        end
        return Text
    end

    function H.Apply(Label)
        if not Settings().HideName then return end
        local Text = Label.Text
        local New = H.Replace(Text)
        if New == Text then return end
        H.Masked[Label], H.Wrote[Label] = Text, New
        Label.Text = New
        if not H.Hooked[Label] then
            -- signal ของ Roblox มาช้า 1 จังหวะ (deferred) = เทียบกับข้อความที่เราเขียนแทน flag
            -- ข้อความไม่ตรงที่เราเขียน = เกมเขียนใหม่ (เปลี่ยนตัว/เลเวล) -> จำอันใหม่ แล้วแทนอีกรอบ
            H.Hooked[Label] = TrackConnection(Label:GetPropertyChangedSignal("Text"):Connect(function()
                if Label.Text == H.Wrote[Label] then return end
                H.Masked[Label], H.Wrote[Label] = nil, nil
                H.Apply(Label)
            end))
        end
    end

    function H.Check(Object)
        if Object:IsA("TextLabel") or Object:IsA("TextButton") then pcall(H.Apply, Object) end
    end

    function Library.HideName(On)
        for _, Connection in ipairs(H.Watchers) do pcall(function() Connection:Disconnect() end) end
        table.clear(H.Watchers)
        if not On then
            for Label, Text in pairs(H.Masked) do
                H.Wrote[Label] = Text -- ข้อความคืน = ไม่ใช่เกมเขียนใหม่
                pcall(function() Label.Text = Text end)
            end
            table.clear(H.Masked)
            return
        end
        local Roots = { LocalPlayer:FindFirstChildOfClass("PlayerGui"), workspace }
        pcall(function() table.insert(Roots, game:GetService("CoreGui"):FindFirstChild("PlayerList")) end)
        for _, Root in ipairs(Roots) do
            for _, Object in ipairs(Root:GetDescendants()) do H.Check(Object) end
            -- ป้ายที่สร้างทีหลัง (เกิดใหม่, เปิดหน้า Profile) - ข้อความมักตั้งหลังสร้าง = รอเฟรมถัดไป
            table.insert(H.Watchers, TrackConnection(Root.DescendantAdded:Connect(function(Object)
                if Object:IsA("TextLabel") or Object:IsA("TextButton") then task.defer(H.Check, Object) end
            end)))
        end
    end
end

InterfaceSection:Toggle({
    Name = "Hide Name",
    Flag = "AZHideName",
    Description = "Shows Valkyrie Hub instead of your name on screen (profile, overhead, player list), in webhooks and on the website",
    Default = Settings().HideName,
    Callback = function(Value)
        Settings().HideName = Value
        SaveSetting()
        Library.HideName(Value)
        if Library.ReportNow then task.spawn(Library.ReportNow) end
    end
})

local FPSSection = ConfigPage:Section({
    Name = "FPS",
    Description = "Framerate and screen",
    Icon = "110273524101447",
    Side = 2
})

FPSSection:Slider({
    Name = "FPS Value",
    Flag = "AZFPSValue",
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
    Flag = "AZFPSLock",
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
    Flag = "AZLanguage",
    Items = { "English (US)", "Thai" },
    Default = getgenv().ConfigurationTable.Language,
    Multi = false,
    Seperator = false,
    Callback = function(Value)
        getgenv().ConfigurationTable.Language = Value
        SaveConfiguration()
    end
})

task.wait()

LanguageSection:Button({
    Name = "Change Language",
    Callback = function()
        ApplyLanguage(getgenv().ConfigurationTable.Language)
    end
})

-- ทุกแท็บสร้างครบแล้วตรงนี้ (ลำดับสุดท้ายของสคริปต์) - บังคับกลับไปแท็บแรกเสมอ (Main) กันเผลอ
-- ค้างอยู่แท็บ Configuration ที่เพิ่งสร้างเสร็จ (tab index นับรวมทุกกลุ่ม ตัวแรกที่สร้าง = index 1)
pcall(function() Library.Window:selectTab(1) end)

-- On Finish ไม่ใช่ toggle (StartOn ไม่ครอบ) -> ในแมตช์สั่งเริ่มเองถ้าตั้ง Retry / Leave ไว้
task.delay(1, function()
    if getgenv().ValkyrieSession == SessionToken then Join.Refresh() end
end)

---- ============ เริ่มระบบที่เซฟว่าเปิดไว้ ============ ----
--
-- ทุก toggle เซฟค่าลง config (Default = ค่าที่เซฟ) แต่ตอนสร้าง wrapper ไม่ยิง callback (Gate) = ปุ่มโชว์เปิด
-- แต่ระบบที่ต้องสั่งเริ่ม (Anti-AFK, Auto Rejoin, Lock FPS ฯลฯ) ไม่เริ่มจริง -> ยิง setter ของตัวที่ยังเปิดอยู่ทีละตัว
task.spawn(function()
    task.wait(1)
    for _, Flag in ipairs(Library.StartOn) do
        if getgenv().ValkyrieSession ~= SessionToken then break end
        if Library.Flags[Flag] == true then
            local Set = Library.SetFlags[Flag]
            if Set then pcall(Set, true) end
            task.wait()
        end
    end
end)

-- เมาส์ปกติ (ผู้ใช้ 2026-10-13): ในแมตช์เกมซ่อนลูกศรเมาส์ (MouseIconEnabled=false) แล้ววาด crosshair เอง ซึ่งตอนนี้ไปเกาะมอน
-- ตาม hook เล็งสกิล -> กด UI ยาก บังคับโชว์ลูกศรปกติทุกเฟรมหลังเกมตั้งค่า (RenderPriority.Last) ตลอดที่ hub รัน / ปิด hub = คืนค่าเดิม
Join.MouseSaved = { game:GetService("UserInputService").MouseIconEnabled, game:GetService("UserInputService").MouseIcon }
pcall(function()
    RunService:BindToRenderStep("ValkyrieCursor", Enum.RenderPriority.Last.Value, function()
        local Input = game:GetService("UserInputService")
        if not Input.MouseIconEnabled then Input.MouseIconEnabled = true end
        if Input.MouseIcon ~= "" then Input.MouseIcon = "" end
    end)
end)

---- ============ Cleanup ============ ----

getgenv().ValkyrieCleanup = function()
    getgenv().ValkyrieSession = nil

    pcall(Join.Stop)
    pcall(Battle.Stop)
    -- Hide Name: คืนชื่อจริงบนจอ (ไม่แตะค่าที่เซฟ - รันใหม่ก็ซ่อนต่อ)
    pcall(function() if Library.HideName then Library.HideName(false) end end)
    pcall(function()
        RunService:UnbindFromRenderStep("ValkyrieCursor")
        local Input = game:GetService("UserInputService")
        Input.MouseIconEnabled, Input.MouseIcon = Join.MouseSaved[1], Join.MouseSaved[2]
    end)
    for _, Hook in ipairs(Join.Hooks) do
        pcall(function()
            if type(Hook) == "function" then Hook() elseif Hook.Disconnect then Hook:Disconnect() end
        end)
    end

    for _, Connection in ipairs(SessionConnections) do
        pcall(function() Connection:Disconnect() end)
    end
    table.clear(SessionConnections)

    pcall(function()
        Library:Unload()
    end)

    getgenv().ValkyrieCleanup = nil
end
