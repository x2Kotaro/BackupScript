pcall(function()
    game.Players.LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
end)

getgenv().ConfigurationTable = {}

local FolderConfiguration = "Valkyrie Hub"
local FolderSettings = "Valkyrie Hub/LTF"
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

local function TrackConnection(Connection)
    if Connection then
        table.insert(SessionConnections, Connection)
    end
    return Connection
end

local filenameConfiguration = FolderConfiguration .. "/" .. "Setting_LTF_" .. LocalPlayer.Name .. ".json"

task.spawn(function()
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

    -- Auto Train
    ["AutoTrain"] = false,
    ["TrainZone"] = "Best Unlocked",

    -- Auto Rebirth
    ["AutoRebirth"] = false,

    -- Enhance (ตีบวก)
    ["AutoEnhant"] = false,
    ["EnhantSlots"] = { "Weapon" },   -- ช่องที่ใส่อยู่: Weapon / Armor / Hat
    ["EnhantTarget"] = 10,
    ["EnhantProtect"] = false,

    -- Frostbound Tower
    ["TowerStartRound"] = 1,          -- 1 ถึง Highest Round + 1
    ["TowerStopRound"] = 30,          -- เคลียร์ Round นี้แล้วออก
    ["TowerClaimDaily"] = true,
    ["TowerAutoEnter"] = false,
    ["TowerAutoSkill"] = true,

    -- Auto Sell (ของต้องตรงทุกตัวกรองถึงขาย)
    ["AutoSell"] = false,
    ["SellTypes"] = { "Weapon", "Armor", "Ore" },
    ["SellRarities"] = { "Common", "UnCommon", "Rare" },
    ["SellPriceMin"] = "",            -- ราคาขายพื้นฐานต่อชิ้น ("" = ไม่จำกัด, รับ 2K / 1.5M)
    ["SellPriceMax"] = "",
    ["SellNameMode"] = "Any Name",    -- Any Name / Only Selected Names / All Except Selected Names
    ["SellNames"] = { },
    ["SellKeepAmount"] = 0,           -- เก็บไว้อย่างน้อยกี่ชิ้นต่อไอเทม
    ["SellKeepEnhanced"] = true,
    ["SellKeepEnchanted"] = true,
    ["SellInterval"] = 30,

    -- Auto Upgrade
    ["AutoUpgrade"] = false,
    ["UpgradeKinds"] = { "Train", "Luck", "OrePack" },
    ["UpgradeOrder"] = "Cheapest First",
    ["UpgradeKeepCoins"] = "",

    -- Equipment
    ["EquipWeapon"] = false,
    ["EquipArmor"] = false,
    ["EquipHat"] = false,
    ["EquipInterval"] = 10,

    -- Miscellaneous
    ["AutoClaimOnline"] = false,
    ["AutoClaimIndex"] = false,

    -- Priority: ระบบที่ขยับตัวละคร ตัวบนทำก่อน
    ["Priority"] = { "Tower", "Forge", "Stage", "Train" },

    -- Auto Enchant (ใส่หิน Enchant)
    ["AutoEnchant"] = false,
    ["EnchantSlots"] = { "Weapon", "Armor", "Hat" },
    ["EnchantTypes"] = { "Fire", "Ice", "Poison", "Thunder" },   -- ลำดับ = ธาตุไหนก่อนเมื่อขั้นเท่ากัน

    -- Auto Forge
    ["AutoForge"] = false,
    ["ForgeType"] = "Weapon",         -- Weapon / Armor
    ["ForgeOreCount"] = 4,            -- 4 (Katana ล้วน) -> 13 (Great ล้วน)

    -- Auto Stage
    ["AutoStage"] = false,
    ["StageTarget"] = 1,              -- 1-27
    ["StageAutoNext"] = false,        -- เลื่อนเป้าเมื่อ Damage ถึง Recommend ของด่านถัดไป
    ["StageAutoBest"] = false,        -- เป้า = ด่านสูงสุดที่ Damage ถึง Recommend (ขึ้น/ลงตาม Damage)
    ["StageBankOres"] = true,         -- ฝากแร่แล้วกลับ Lobby ก่อนตาย
    ["StageReturnHP"] = 35,           -- % เลือดที่สั่งกลับ
    ["StageFarmDistance"] = 10,       -- ลอยเหนือหัวมอน (studs) - เกิน 6 = AI มอนไม่ตี / ท่าตีเรายังถึง ~11
    ["StageAutoSkill"] = true,        -- ใช้สกิลอาวุธทุกครั้งที่คูลดาวน์หมดระหว่างตี
    ["StageAutoDodge"] = true,  -- "Best Unlocked" หรือชื่อโซนในดรอปดาวน์ ("Zone 3 (Rebirth 5)", "Zone 9 (Paid)")
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

    function Library:AddLanguage(Name, Translations)
        pcall(function() LibraryMilenium:add_translations(Name, Translations) end)
    end

    local AutoFlag = 0

    local function FlagOf(Value)
        if type(Value) == "string" and Value ~= "" then return Value end

        AutoFlag = AutoFlag + 1
        return "LTFAuto" .. AutoFlag
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

    local function MakeSection(Item)
        local Section = { Item = Item }

        function Section:Toggle(Toggle)
            local Flag = FlagOf(Toggle.Flag)
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

            local Fire, Open = Gate(function(Value)
                local Out = Multi and ToList(Value) or Value
                Library.Flags[Flag] = Out
                if Dropdown.Callback and Out ~= nil then Dropdown.Callback(Out) end
            end)

            local Handle = Item:dropdown({
                name = Dropdown.Name or "Dropdown",
                info = Dropdown.Description,
                flag = Flag,
                items = Options(Dropdown.Items, Dropdown.KeepOrder),
                multi = Multi,
                default = Multi and ToList(Dropdown.Default) or (Dropdown.Default or ""),
                seperator = Dropdown.Seperator,
                callback = Fire
            })

            Open()

            local function SetValue(Value)
                Handle.set(Multi and ToList(Value) or Value)
            end

            Register(Dropdown.Flag, Multi and ToList(Dropdown.Default) or Dropdown.Default, SetValue)

            Handle.setValue = function(_, Value) SetValue(Value) end

            -- โค้ดเดิมเรียก :Refresh(รายการใหม่, ค่าที่เลือก)
            function Handle:Refresh(List, Selected)
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
            return Item:button({
                name = Button.Name or "Button",
                callback = Button.Callback or function() end
            })
        end

        -- เส้นใต้ element (Seperator): Toggle/Label ค่าเริ่มไม่มี, Slider/Dropdown ค่าเริ่มมี - ส่ง true/false ทับได้
        -- เช่น Section:Toggle({ ..., Seperator = true }) / Section:Dropdown({ ..., Seperator = false })
        function Section:Label(Text, Seperator)
            local Handle = Item:label({ name = tostring(Text), seperator = Seperator })

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

        -- ช่องพิมพ์ข้อความ (textbox ของ Milenium ขึ้นบนสุดของกล่องเสมอ - LayoutOrder -1)
        function Section:Textbox(Box)
            return Item:textbox({
                name = Box.Name or "TextBox",
                placeholder = Box.Placeholder,
                default = Box.Default or "",
                flag = FlagOf(Box.Flag),
                callback = function(Text)
                    if Box.Callback then Box.Callback(Text) end
                end
            })
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
            gameInfo = "LTF",
            info_text = "@velkyriehub",
            profile = { avatar = Avatar, name = "Hidden", desc = "@velkyriehub" },
            search_placeholder = "Search...",
        })

        Library.MileniumWindow = WindowMilenium

        for _, Key in ipairs({ "items", "other", "mobile" }) do
            local Gui = LibraryMilenium[Key]
            if typeof(Gui) == "Instance" then table.insert(getgenv().ValkyrieGuis, Gui) end
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
        end

        function Window:SetTransparency() end

        function Window:Page(Page)
            local Tab = WindowMilenium:tab({
                name = Page.Name or "Tab",
                icon = IconOf(Page.Icon) or "rbxassetid://10734950309",
            })
            table.insert(Library.Pages, Tab)

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

                return MakeSection(Box)
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
    { "^Paused %- (.+) first$", "พัก - ให้ %1 ทำก่อน" },
    { "^Fighting %((%d+) left%)$", "กำลังตี (เหลือ %1)" },
    { "^Dodging %((%d+) left%)$", "กำลังหลบ (เหลือ %1)" },
    { "^Collecting ores %((%d+)%)$", "กำลังเก็บแร่ (%1)" },
    { "^Moving to stage (%d+) %(on foot%)$", "กำลังเดินเข้าด่าน %1" },
    { "^Moving to stage (%d+)$", "กำลังไปด่าน %1" },
    { "^Waiting for respawn %((%d+)s%)$", "รอมอนเกิดใหม่ (%1 วิ)" },
    { "^Waiting for enemies %((%d+)s%)$", "รอมอน (%1 วิ)" },
    { "^No enemies in stage (%d+) %- back to restart$", "ด่าน %1 ไม่มีมอน - กลับไปเริ่มใหม่" },
    { "^Cleared stage (%d+) %- back to restart the loop$", "เคลียร์ด่าน %1 แล้ว - กลับไปวนใหม่" },
    { "^Damage below stage (%d+) Recommend %- returned to farm again$", "Damage ไม่ถึง Recommend ด่าน %1 - กลับไปฟาร์มใหม่" },
    { "^(%d+) / target (%d+) %(stage (%d+) too strong, retry in (%d+)s%)$", "%1 / เป้า %2 (ด่าน %3 ยังไม่ไหว ลองใหม่ใน %4 วิ)" },
    { "^(%d+) / target (%d+)$", "%1 / เป้า %2" },
    { "^(.+) %(next needs (.+)%)$", "%1 (ด่านถัดไปต้องการ %2)" },
    { "^(%d+)/(%d+) carried, (%d+) banked$", "ถือ %1/%2, ฝากแล้ว %3" },
    { "^Round (%d+) %- fighting %((%d+) left%)$", "รอบ %1 - กำลังตี (เหลือ %2)" },
    { "^Round (%d+) %- dodging %((%d+) left%)$", "รอบ %1 - กำลังหลบ (เหลือ %2)" },
    { "^Round (%d+) %- collecting ores %((%d+)%)$", "รอบ %1 - กำลังเก็บแร่ (%2)" },
    { "^Round (%d+) %- waiting for enemies$", "รอบ %1 - รอมอน" },
    { "^Entering at Round (%d+)$", "กำลังเข้าที่รอบ %1" },
    { "^Cleared Round (%d+) %- leaving the Tower$", "เคลียร์รอบ %1 แล้ว - ออกจากหอ" },
    { "^Could not enter %- retry in (%d+)s$", "เข้าไม่ได้ - ลองใหม่ใน %1 วิ" },
    { "^Could not enter %((.*)%)$", "เข้าไม่ได้ (%1)" },
    { "^(%d+) %(start (%d+) / stop (%d+)%)$", "%1 (เริ่ม %2 / หยุด %3)" },
    { "^start (%d+) / stop (%d+)$", "เริ่ม %1 / หยุด %2" },
    { "^(%d+) %(daily (%a+)%)$", "%1 (รายวัน: %2)" },
    { "^Enhance unlocks at Rebirth (%d+)$", "ตีบวกปลดที่ Rebirth %1" },
    { "^Enchanting (%a+) slot (%d+) with (.+)$", "กำลังใส่ %3 ที่ %1 ช่อง %2" },
    { "^Need at least 4 ores %(have (%d+)%)$", "ต้องมีแร่อย่างน้อย 4 (มี %1)" },
    { "^(%d+) %(best: (.+) x(%d+), power (.+)%)$", "%1 (ดีสุด: %2 x%3, พลัง %4)" },
    { "^Selling (.+) x(%d+)$", "กำลังขาย %1 x%2" },
    { "^Sold (%d+) items$", "ขายแล้ว %1 ชิ้น" },
    { "^(%d+) items %(base (.+) coin%)$", "%1 ชิ้น (ราคาพื้นฐาน %2 เหรียญ)" },
    { "^(%d+) items, %+(.+) coin$", "%1 ชิ้น, +%2 เหรียญ" },
    { "^Upgrading (.+)$", "กำลังอัปเกรด %1" },
    { "^Lv (%d+)/(%d+) %- next (.+) coin$", "Lv %1/%2 - ถัดไป %3 เหรียญ" },
    { "^Lv (%d+)/(%d+) %- max$", "Lv %1/%2 - เต็มแล้ว" },
    { "^Not enough coins %(keeping (.+)%)$", "เหรียญไม่พอ (เก็บไว้ %1)" },
    { "^Equipped (%d+) better item%(s%)$", "เปลี่ยนเป็นของที่ดีกว่า %1 ชิ้น" },
    { "^Equipped (.+) %((.+)%)$", "ใส่ %1 แล้ว (%2)" },
    { "^(.+) %((.+)%) %- best$", "%1 (%2) - ดีสุดแล้ว" },
    { "^(.+) %((.+)%) %- better one in backpack$", "%1 (%2) - ในกระเป๋ามีที่ดีกว่า" },
    { "^Claimed (%d+) reward%(s%)$", "รับรางวัลแล้ว %1 อัน" },
    { "^Claimed (%d+) item%(s%), (%d+) level%(s%)$", "รับแล้ว %1 ไอเทม, %2 ระดับ" },
    { "^(%d+) min$", "%1 นาที" },
    { "^in (%d+) s$", "อีก %1 วิ" },
    { "^(%d+) / (%d+) %(next: (.+)%)$", "%1 / %2 (ถัดไป: %3)" },
    { "^(.+) %(max level%)$", "%1 (ระดับสูงสุด)" },
    { "^#(%d+) %- (.+)$", "#%1 - %2" },
    { "^Error: (.+)$", "ผิดพลาด: %1" },
}

local function ApplyLanguage(Name)
    Library:SetLocale(LocaleByLanguage[Name] or "en")
end

-- คำแปลไทยของ UI - Milenium จำข้อความอังกฤษเดิมแล้วสลับตามภาษาที่เลือก
Library:AddLanguage("th", {
    ["General"] = "ทั่วไป",
    ["Auto Train"] = "ฝึกอัตโนมัติ",
    ["Auto Train Status"] = "สถานะฝึกอัตโนมัติ",
    ["Stand in a train zone and let the game train"] = "ยืนในโซนฝึกแล้วให้เกมฝึกเอง",
    ["Status"] = "สถานะ",
    ["Train Zone"] = "โซนฝึก",
    ["Best Unlocked"] = "โซนดีสุดที่ปลดแล้ว",
    ["Best Unlocked picks the strongest zone your rebirth opens"] = "โซนดีสุดที่ปลดแล้ว คือโซนแรงสุดที่ Rebirth ของคุณเปิดได้",
    ["How to use"] = "วิธีใช้",
    ["Pick a Train Zone (Best Unlocked is the default)"] = "เลือกโซนฝึก (ค่าเริ่มต้นคือโซนดีสุดที่ปลดแล้ว)",
    ["Turn on Auto Train: it moves you into the zone and the game trains on its own"] = "เปิดฝึกอัตโนมัติ: พาตัวไปยืนในโซนแล้วเกมจะฝึกให้เอง",
    ["Paid zones (9-11) need the Robux purchase - if not owned it falls back to the best unlocked zone"] = "โซนเสียเงิน (9-11) ต้องซื้อด้วย Robux - ถ้ายังไม่ได้ซื้อจะใช้โซนดีสุดที่ปลดแล้วแทน",
    ["Turning it off moves you back to where you started"] = "ปิดแล้วจะพากลับไปจุดเดิม",
    ["Auto Rebirth"] = "รีเบิร์ธอัตโนมัติ",
    ["Enhance"] = "ตีบวก",
    ["Auto Forge"] = "ตีของอัตโนมัติ (Forge)",
    ["Auto Stage"] = "ลงด่านอัตโนมัติ",
    ["Method: Air (forced) - stays above enemy reach"] = "ตำแหน่ง: ลอยฟ้า (บังคับ) - อยู่นอกระยะที่มอนตี",
    ["Farm Distance"] = "ระยะฟาร์ม",
    ["Studs above the enemy - enemies only swing at you within 6 studs"] = "ความสูงเหนือมอน (studs) - มอนจะตีเมื่อเราอยู่ใกล้ไม่เกิน 6 studs",
    ["Auto Dodge"] = "หลบอัตโนมัติ",
    ["Step out of an enemy skill's real hitbox while it plays, then come back"] = "ออกจากระยะท่าของมอนตาม hitbox จริงระหว่างที่มันใช้ แล้วกลับมาตีต่อ",
    ["Stage Status"] = "สถานะด่าน",
    ["Target Stage"] = "ด่านเป้าหมาย",
    ["Stage to farm - lower stages are cleared on the way"] = "ด่านที่จะฟาร์ม - ด่านก่อนหน้าจะเคลียร์ไปตามทาง",
    ["Auto Next Stage"] = "เลื่อนด่านอัตโนมัติ",
    ["Auto Best Stage"] = "ด่านที่ดีที่สุดอัตโนมัติ",
    ["Target Stage follows the highest stage your Damage meets the Recommend for - after clearing it, go back and loop from stage 1"] = "ตั้งด่านเป้าหมายเป็นด่านสูงสุดที่ Damage ถึง Recommend - เคลียร์แล้วกด Back กลับมาวนใหม่จากด่าน 1",
    ["Raise Target Stage when your Damage reaches the next stage's Recommend"] = "เลื่อนด่านเป้าหมายเมื่อ Damage ถึงค่า Recommend ของด่านถัดไป",
    ["Bank Ores on Return"] = "ฝากแร่ก่อนกลับ",
    ["Bank carried ores and return to the lobby before you die"] = "ฝากแร่ที่ถือแล้วกลับ Lobby ก่อนตาย",
    ["Return At HP"] = "กลับเมื่อเลือดเหลือ",
    ["Set Target Stage, then turn on Auto Stage: it clears each stage up to the target and keeps farming it"] = "ตั้งด่านเป้าหมาย แล้วเปิดลงด่านอัตโนมัติ: เคลียร์ทีละด่านจนถึงเป้าแล้วฟาร์มด่านนั้นต่อ",
    ["Ores are picked up after each clear and banked whenever the ore pack is full"] = "เก็บแร่หลังเคลียร์ทุกครั้ง และฝากทันทีเมื่อแพ็กแร่เต็ม",
    ["Bank Ores on Return: below Return At HP it banks the ores and goes back to the lobby (stages restart from 1)"] = "ฝากแร่ก่อนกลับ: เลือดต่ำกว่าที่ตั้งจะฝากแร่แล้วกลับ Lobby (ด่านเริ่มใหม่จาก 1)",
    ["With Auto Train / Forge / Tower also on, the Priority tab decides who goes first"] = "เปิด Auto Train / Forge / Tower คู่กันได้ - แท็บ Priority ตัดสินว่าใครทำก่อน",
    ["No enemies for 10 seconds inside a stage = it presses Back and starts over"] = "อยู่ในด่านแต่มอนไม่เกิด 10 วินาที = กด Back แล้วเริ่มใหม่",
    ["Forge Status"] = "สถานะ Forge",
    ["Forge Type"] = "ประเภทที่ Forge",
    ["Forge Once"] = "Forge 1 ครั้ง",
    ["Ores Per Forge"] = "จำนวนแร่ต่อครั้ง",
    ["4 is all Katana, 13 is all Great - power comes from the ores' average"] = "4 คือ Katana ล้วน, 13 คือ Great ล้วน - พลังมาจากค่าเฉลี่ยของแร่",
    ["Pick Forge Type and Ores Per Forge"] = "เลือกประเภทที่ Forge และจำนวนแร่ต่อครั้ง",
    ["Turn on Auto Forge: it fills the forge with your highest power ores (up to 4 kinds) and forges until fewer than 4 ores are left"] = "เปิด Forge อัตโนมัติ: ใส่แร่พลังสูงสุดที่มี (ไม่เกิน 4 ชนิด) แล้ว Forge จนเหลือแร่ไม่ถึง 4 ชิ้น",
    ["It moves to the forge table for each batch, then back to where you were"] = "วาร์ปไปโต๊ะ Forge ทุกรอบ แล้วกลับที่เดิม",
    ["Auto Enhance"] = "ตีบวกอัตโนมัติ",
    ["Auto Enchant"] = "ใส่ Enchant อัตโนมัติ",
    ["Auto Tower"] = "หอคอยอัตโนมัติ",
    ["Auto Skill"] = "ใช้สกิลอัตโนมัติ",
    -- ชื่อแถวในการ์ด Status + ข้อความสถานะที่ตายตัว (การ์ดแปลเองตอนวาด - Library.Tr)
    ["State"] = "สถานะ", ["Stage"] = "ด่าน", ["Damage"] = "ดาเมจ", ["Ores"] = "แร่", ["Zone"] = "โซน",
    ["Rebirth"] = "รีเบิร์ธ", ["Item"] = "ไอเทม", ["Level"] = "ระดับ", ["Chance"] = "โอกาส", ["Cost"] = "ค่าใช้จ่าย",
    ["Have"] = "มีอยู่", ["Slots"] = "ช่อง", ["Stones"] = "หิน", ["Coin"] = "เหรียญ", ["Forged"] = "Forge แล้ว",
    ["Last"] = "ล่าสุด", ["Round"] = "รอบ", ["Highest"] = "สูงสุด", ["Tickets"] = "ตั๋ว", ["Matching"] = "ตรงเงื่อนไข",
    ["Sold"] = "ขายแล้ว", ["Train"] = "ฝึก", ["Luck"] = "โชค", ["Ore Pack"] = "กระเป๋าแร่", ["Weapon"] = "อาวุธ",
    ["Armor"] = "เกราะ", ["Hat"] = "หมวก", ["Online"] = "ออนไลน์", ["Claimed"] = "รับแล้ว", ["Next"] = "ถัดไป",
    ["Exp"] = "Exp", ["Unclaimed"] = "ยังไม่รับ", ["Now"] = "ตอนนี้", ["Bonus"] = "โบนัส",
    ["Waiting for character"] = "รอตัวละคร", ["Waiting for character / zone"] = "รอตัวละคร / โซน",
    ["Training"] = "กำลังฝึก", ["Moving to zone"] = "กำลังไปโซนฝึก", ["Rebirthing"] = "กำลังรีเบิร์ธ",
    ["Max rebirth"] = "รีเบิร์ธสูงสุดแล้ว", ["Waiting for level"] = "รอเลเวลถึง", ["Enhancing"] = "กำลังตีบวก",
    ["All selected items reached the target"] = "ของที่เลือกถึงเป้าหมดแล้ว", ["Not enough coins"] = "เหรียญไม่พอ",
    ["Not enough Enhance Stone"] = "หินตีบวกไม่พอ", ["Not enough Enhance Stone II"] = "หินตีบวก II ไม่พอ",
    ["Every enchant slot is filled"] = "ช่อง Enchant เต็มหมดแล้ว", ["No stones of the selected types"] = "ไม่มีหินธาตุที่เลือก",
    ["Waiting to retry"] = "รอลองใหม่", ["None (drops in the Dungeon)"] = "ไม่มี (ดรอปใน Dungeon)",
    ["Forging"] = "กำลัง Forge", ["Forge refused (backpack full?)"] = "Forge ไม่สำเร็จ (กระเป๋าเต็ม?)",
    ["Stage point not found"] = "ไม่พบจุดของด่าน", ["Low HP - banked ores and returned"] = "เลือดต่ำ - ฝากแร่แล้วกลับ Lobby",
    ["Executor has no getconnections"] = "Executor ไม่มี getconnections", ["Auto Enter Tower is off"] = "ปิดเข้าหอคอยอัตโนมัติอยู่",
    ["No Tower Ticket"] = "ไม่มี Tower Ticket", ["Claimed the daily Tower Ticket"] = "รับ Tower Ticket รายวันแล้ว",
    ["Died - giving up"] = "ตาย - กด Give up", ["Nothing to sell"] = "ไม่มีของให้ขาย",
    ["Selected upgrades are maxed"] = "อัปเกรดที่เลือกเต็มแล้ว", ["Wearing the best"] = "ใส่ของดีสุดอยู่แล้ว",
    ["Nothing to equip"] = "ไม่มีของให้ใส่", ["Waiting for the next reward"] = "รอรางวัลถัดไป",
    ["Waiting for new items"] = "รอไอเทมใหม่", ["All claimed"] = "รับครบแล้ว", ["Nothing has work"] = "ไม่มีระบบไหนมีงาน",
    ["running"] = "กำลังทำ", ["off"] = "ปิด", ["waiting for its turn"] = "รอตา", ["nothing to do"] = "ไม่มีงาน",
    ["claimed"] = "รับแล้ว", ["ready"] = "พร้อมรับ", ["Waiting"] = "รอ",
    ["Auto Sell"] = "ขายของอัตโนมัติ",
    ["Equipment"] = "อุปกรณ์สวมใส่",
    ["Priority"] = "ลำดับความสำคัญ",
    ["Priority Status"] = "สถานะลำดับ",
    ["Reset Order"] = "รีเซ็ตลำดับ",
    ["Turn on as many as you want in their own tabs - this page decides which one moves your character"] = "เปิดได้หลายระบบในแท็บของมัน - หน้านี้ตัดสินว่าระบบไหนได้คุมตัวละคร",
    ["The highest one that has something to do goes first; the rest wait without touching your character"] = "ระบบที่อยู่สูงสุดที่มีงานทำก่อน ระบบอื่นรอโดยไม่แตะตัวละคร",
    ["Tower has work while you hold a ticket, Forge while you have enough ores; Stage and Train always have work"] = "Tower มีงานเมื่อมีตั๋ว, Forge มีงานเมื่อแร่พอ; Stage และ Train มีงานเสมอ",
    ["A Tower run and a forge trip always finish first; Stage finishes the enemy it is hitting before it hands over"] = "รอบใน Tower และการไป Forge ทำจนจบก่อนเสมอ; Stage ตีมอนตัวที่ตีอยู่ให้ตายก่อนส่งต่อ",
    ["Rebirth, Enhance, Enchant, Sell, Upgrade, Equip and claims run alongside everything"] = "Rebirth, ตีบวก, Enchant, ขาย, อัปเกรด, ใส่ของ และรับรางวัล ทำงานคู่กันได้ตลอด",
    ["Auto Equip"] = "ใส่ของอัตโนมัติ",
    ["Equipment Status"] = "สถานะอุปกรณ์",
    ["Auto Equip Best Weapon"] = "ใส่อาวุธที่ดีที่สุดอัตโนมัติ",
    ["Wear the weapon with the highest power (enhance level counted)"] = "ใส่อาวุธที่พลังสูงสุด (นับระดับตีบวกด้วย)",
    ["Auto Equip Best Armor"] = "ใส่เกราะที่ดีที่สุดอัตโนมัติ",
    ["Wear the armor with the highest defence"] = "ใส่เกราะที่ป้องกันสูงสุด",
    ["Auto Equip Best Hat"] = "ใส่หมวกที่ดีที่สุดอัตโนมัติ",
    ["Wear the hat with the highest defence"] = "ใส่หมวกที่ป้องกันสูงสุด",
    ["Check Every"] = "เช็คทุก ๆ",
    ["Seconds between equipment checks"] = "วินาทีระหว่างการเช็คอุปกรณ์",
    ["Equip Best Now"] = "ใส่ของดีสุดตอนนี้",
    ["Turn on the slots you want: it swaps in a stronger item as soon as you get one"] = "เปิดช่องที่ต้องการ: ได้ของที่แรงกว่าเมื่อไหร่จะเปลี่ยนให้ทันที",
    ["Power is the game's own stat value, so enhance levels are counted"] = "พลังใช้ค่าสเตตัสของเกมเอง จึงนับระดับตีบวกด้วย",
    ["Turn off Auto Sell for Weapon / Armor rarities you may want to wear"] = "ปิดขายอัตโนมัติสำหรับความหายากของอาวุธ / เกราะที่อาจอยากใส่",
    ["Miscellaneous"] = "อื่น ๆ",
    ["Online Rewards"] = "รางวัลออนไลน์",
    ["Online Status"] = "สถานะออนไลน์",
    ["Auto Claim Online"] = "รับรางวัลออนไลน์อัตโนมัติ",
    ["Claim each online-time reward as soon as it is ready"] = "รับรางวัลเวลาออนไลน์ทันทีที่พร้อม",
    ["Index"] = "สมุดสะสม (Index)",
    ["Index Status"] = "สถานะ Index",
    ["Auto Claim Index"] = "รับรางวัล Index อัตโนมัติ",
    ["Claim Index exp for every new item, then level the Index up whenever the exp is enough"] = "รับ exp Index ของไอเทมใหม่ทุกชิ้น แล้วเลื่อนระดับ Index เมื่อ exp พอ",
    ["Sell Status"] = "สถานะการขาย",
    ["Filters"] = "ตัวกรอง",
    ["Item Types"] = "ประเภทไอเทม",
    ["Kinds of items that can be sold"] = "ประเภทของที่ขายได้",
    ["Rarities"] = "ความหายาก",
    ["Only items of these rarities are sold"] = "ขายเฉพาะของที่มีความหายากตามนี้",
    ["Min Price"] = "ราคาต่ำสุด",
    ["Max Price"] = "ราคาสูงสุด",
    ["No minimum (e.g. 500, 2K, 1.5M)"] = "ไม่จำกัด (เช่น 500, 2K, 1.5M)",
    ["No maximum (e.g. 50K, 2M)"] = "ไม่จำกัด (เช่น 50K, 2M)",
    ["Name Filter"] = "กรองตามชื่อ",
    ["How the selected item names are used"] = "วิธีใช้ชื่อไอเทมที่เลือก",
    ["Any Name"] = "ทุกชื่อ",
    ["Only Selected Names"] = "เฉพาะชื่อที่เลือก",
    ["All Except Selected Names"] = "ทุกชื่อยกเว้นที่เลือก",
    ["Item Names"] = "ชื่อไอเทม",
    ["Names from your backpack - press Refresh Names after looting new items"] = "ชื่อจากกระเป๋า - กด Refresh Names หลังได้ของใหม่",
    ["Refresh Names"] = "รีเฟรชรายชื่อ",
    ["Keep Amount"] = "จำนวนที่เก็บไว้",
    ["Always keep at least this many of each item"] = "เก็บไว้อย่างน้อยเท่านี้ต่อไอเทม",
    ["Keep Enhanced Items"] = "เก็บของที่ตีบวกแล้ว",
    ["Never sell items with an enhance level (+1 or more)"] = "ไม่ขายของที่ตีบวกแล้ว (+1 ขึ้นไป)",
    ["Keep Enchanted Items"] = "เก็บของที่ใส่ Enchant แล้ว",
    ["Never sell items that hold an enchant stone"] = "ไม่ขายของที่มีหิน Enchant อยู่",
    ["Sell Every"] = "ขายทุก ๆ",
    ["Seconds between sell checks"] = "วินาทีระหว่างการเช็คขาย",
    ["Sell Now"] = "ขายตอนนี้",
    ["Pick Item Types and Rarities - an item must match every filter to be sold"] = "เลือกประเภทและความหายาก - ของต้องตรงทุกตัวกรองถึงจะขาย",
    ["Min / Max Price use the item's base sell price (K, M, B work)"] = "ราคาต่ำสุด / สูงสุด ใช้ราคาขายพื้นฐานของไอเทม (ใช้ K, M, B ได้)",
    ["Name Filter: sell only the selected names, or everything except them"] = "กรองตามชื่อ: ขายเฉพาะชื่อที่เลือก หรือทุกอย่างยกเว้นชื่อที่เลือก",
    ["Equipped items and items the game marks as unsellable are never sold"] = "ของที่ใส่อยู่และของที่เกมห้ามขายจะไม่ถูกขาย",
    ["Matching shows what would be sold right now - check it before turning on Auto Sell"] = "Matching แสดงของที่จะถูกขายตอนนี้ - เช็คก่อนเปิดขายอัตโนมัติ",
    ["Auto Upgrade"] = "อัปเกรดอัตโนมัติ",
    ["Upgrade Status"] = "สถานะอัปเกรด",
    ["Upgrades"] = "อัปเกรด",
    ["Train = training gain, Luck = drop luck, Ore Pack = ores you can carry"] = "Train = ค่าฝึก, Luck = โชคดรอป, Ore Pack = จำนวนแร่ที่ถือได้",
    ["Order"] = "ลำดับ",
    ["Cheapest First buys whatever costs least next; List Order saves up for the first one"] = "Cheapest First ซื้อตัวที่ถูกสุดก่อน; List Order เก็บเงินซื้อตัวแรกก่อน",
    ["Cheapest First"] = "ถูกสุดก่อน",
    ["List Order"] = "ตามลำดับรายการ",
    ["Keep Coins"] = "เก็บเหรียญไว้",
    ["Coins to never spend (e.g. 100K, 5M)"] = "เหรียญที่ไม่ใช้ (เช่น 100K, 5M)",
    ["Upgrade Once"] = "อัปเกรด 1 ครั้ง",
    ["Pick the upgrades and the Order, then turn on Auto Upgrade"] = "เลือกอัปเกรดและลำดับ แล้วเปิดอัปเกรดอัตโนมัติ",
    ["It buys a level whenever you have the coins, up to level 12"] = "ซื้อระดับทันทีที่เหรียญพอ จนถึงระดับ 12",
    ["Keep Coins leaves that much unspent (for Enhance / Enchant)"] = "เก็บเหรียญไว้ตามที่ตั้ง (ไว้ใช้ตีบวก / Enchant)",
    ["Use your weapon skills whenever they are off cooldown while fighting"] = "ใช้สกิลอาวุธทุกครั้งที่คูลดาวน์หมดระหว่างตี",
    ["Frostbound Tower"] = "Frostbound Tower",
    ["Tower Status"] = "สถานะหอคอย",
    ["Start Round"] = "Round เริ่มต้น",
    ["Round to start from - capped at your Highest Round + 1"] = "Round ที่จะเริ่ม - สูงสุดได้ Highest Round + 1",
    ["Stop at Round"] = "หยุดที่ Round",
    ["Leave the Tower after clearing this round"] = "เคลียร์ Round นี้แล้วออกจากหอ",
    ["Auto Claim Daily Ticket"] = "รับตั๋วรายวันอัตโนมัติ",
    ["Claim the free Tower Ticket once a day"] = "รับ Tower Ticket ฟรีวันละครั้ง",
    ["Auto Enter Tower"] = "เข้าหอคอยอัตโนมัติ",
    ["Spend a Tower Ticket to enter, fight each round, and leave at Stop at Round"] = "ใช้ Tower Ticket เข้าหอ ตีทุก Round แล้วออกเมื่อถึง Round ที่ตั้งหยุด",
    ["Set Start Round and Stop at Round, then turn on Auto Enter Tower"] = "ตั้ง Round เริ่มต้นและ Round ที่หยุด แล้วเปิดเข้าหอคอยอัตโนมัติ",
    ["Each run spends 1 Tower Ticket - turn on Auto Claim Daily Ticket for the free ones"] = "เข้าแต่ละรอบใช้ Tower Ticket 1 ใบ - เปิดรับตั๋วรายวันเพื่อเอาตั๋วฟรี",
    ["Fighting uses Auto Stage's Farm Distance and Auto Dodge - the Priority tab decides Tower vs Stage"] = "การตีใช้ Farm Distance และ Auto Dodge ของลงด่าน - แท็บ Priority ตัดสินว่า Tower หรือ Stage ก่อน",
    ["Dying in the Tower presses Give up"] = "ตายในหอจะกด Give up",
    ["Enchant Status"] = "สถานะ Enchant",
    ["Enchant Once"] = "ใส่ Enchant 1 ครั้ง",
    ["Equipped items to enchant"] = "ของที่ใส่อยู่ที่จะใส่ Enchant",
    ["Stone Types"] = "ธาตุของหิน",
    ["Elements to use - on equal tier, the one higher in this list goes first"] = "ธาตุที่จะใช้ - ขั้นเท่ากันใช้ธาตุที่อยู่บนก่อน",
    ["Pick the equipped items and the stone elements to use"] = "เลือกของที่ใส่อยู่และธาตุของหินที่จะใช้",
    ["Turn on Auto Enchant: it fills every empty enchant slot with your highest tier stone"] = "เปิดใส่ Enchant อัตโนมัติ: ใส่หินขั้นสูงสุดที่มีลงทุกช่องที่ว่าง",
    ["Stones drop in the Dungeon - each one costs 200 / 1,500 / 5,000 coins to put in (tier 1 / 2 / 3)"] = "หินดรอปใน Dungeon - ใส่ครั้งละ 200 / 1,500 / 5,000 เหรียญ (ขั้น 1 / 2 / 3)",
    ["Slots that already hold a stone are left as they are"] = "ช่องที่มีหินอยู่แล้วจะไม่แตะ",
    ["Enhance Status"] = "สถานะตีบวก",
    ["Enhance Once"] = "ตีบวก 1 ครั้ง",
    ["Equipment"] = "อุปกรณ์",
    ["Equipped items to enhance"] = "ของที่ใส่อยู่ที่จะตีบวก",
    ["Target Level"] = "ระดับเป้าหมาย",
    ["Stop at this enhance level"] = "หยุดเมื่อถึงระดับนี้",
    ["Use Protection Scroll"] = "ใช้ Protection Scroll",
    ["Spend a scroll on each try while you have one"] = "ใช้สกรอลทุกครั้งที่ตีถ้ายังมี",
    ["Pick the equipped items and a Target Level"] = "เลือกของที่ใส่อยู่และระดับเป้าหมาย",
    ["Turn on Auto Enhance: it tries until the target or until coins / stones run out"] = "เปิดตีบวกอัตโนมัติ: ตีจนถึงเป้าหรือจนเหรียญ / หินหมด",
    ["Chance drops from 100% (+1) to 1% (+20) - a Protection Scroll is used per try when turned on"] = "โอกาสลดจาก 100% (+1) ถึง 1% (+20) - เปิดใช้สกรอลแล้วจะใช้ 1 ใบต่อครั้ง",
    ["Auto Rebirth Status"] = "สถานะรีเบิร์ธอัตโนมัติ",
    ["Rebirth Now"] = "รีเบิร์ธตอนนี้",
    ["Turn on Auto Rebirth: it rebirths as soon as your level reaches the next requirement"] = "เปิดรีเบิร์ธอัตโนมัติ: รีเบิร์ธทันทีที่เลเวลถึงเงื่อนไขรอบถัดไป",
    ["Each rebirth raises your Exp and Coin multiplier and unlocks new train zones"] = "รีเบิร์ธแต่ละรอบเพิ่มตัวคูณ Exp และ Coin และปลดโซนฝึกใหม่",
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
})

ApplyLanguage(getgenv().ConfigurationTable.Language)

local Window = Library:Window({
    Name = "Valkyrie Hub",
    Logo = IconValkyrie
})

Library:Notify("Valkyrie Hub", "Loaded - have fun", 5)

--// ปุ่มลอยเปิด/ปิดเมนู (ผู้ใช้ 2026-10-02): โลโก้ Valkyrie มุมโค้ง พื้นโปร่งแสง ลากย้ายได้ (จำตำแหน่ง) แตะ = เปิด/ปิด
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
        Button.Size = UDim2.fromOffset(54, 54)
        local Saved = Config.ToggleButtonPos
        Button.Position = type(Saved) == "table" and #Saved == 4 and UDim2.new(Saved[1], Saved[2], Saved[3], Saved[4])
            or UDim2.new(0, 24, 0.35, 0)
        Button.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
        Button.BackgroundTransparency = 0.5
        Button.ZIndex = 50
        Button.Parent = Holder

        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 18)
        Corner.Parent = Button
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
            Start, StartPos, Moved = Input.Position, Button.Position, false
            Tween(Scale, 0.08, { Scale = 0.9 })
        end)
        TrackConnection(UserInput.InputChanged:Connect(function(Input)
            if not Start then return end
            if Input.UserInputType ~= Enum.UserInputType.MouseMovement and Input.UserInputType ~= Enum.UserInputType.Touch then return end
            local Delta = Input.Position - Start
            if Delta.Magnitude > 6 then Moved = true end
            if Moved then
                Tween(Button, 0.08, { Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y) })
            end
        end))
        TrackConnection(UserInput.InputEnded:Connect(function(Input)
            if not (Start and IsPress(Input)) then return end
            Start = nil
            Tween(Scale, 0.12, { Scale = 1 })
            if Moved then
                task.delay(0.1, function()
                    local P = Button.Position
                    Config.ToggleButtonPos = { P.X.Scale, P.X.Offset, P.Y.Scale, P.Y.Offset }
                    SaveConfiguration()
                end)
            else
                pcall(Menu.toggle_menu, not LibraryMilenium["items"].Enabled)
            end
        end))

        -- ตั้งค่า "Mobile Button" ในหน้า Settings ของไลบรารี = ซ่อน/โชว์ปุ่มนี้
        Menu.set_mobile_button = function(Bool) Button.Visible = Bool == true end
    end
end

---- ============ Movement (แบบ Slayer2) ============ ----
--
-- ตรึงตัวทุกเฟรม: RenderStep (ก่อนกล้อง) + Heartbeat (หลังฟิสิกส์ - ท่าตีของเกมใส่แรงเคลื่อนตัว ฟิสิกส์ลาก
-- ออกจากจุดยืนก่อนส่งตำแหน่ง) / Lock = จุดตี (ฟังก์ชัน = คำนวณใหม่ทุกเฟรม เกาะมอนที่เดินอยู่)
-- Hold = จุดหลบ ทับ Lock จนกว่าจะปล่อย (ปล่อยแล้วกลับไปตรึงที่ Lock เดิมเอง)
-- ระหว่างตรึง: ปิดชนชิ้นส่วนตัวละคร (noclip - ลอยเหนือหัวมอนไม่โดนดันออก) + ปิดสถานะร่วง/ล้ม + ความเร็วเป็น 0
-- ปล่อยหมด = คืนการชนเฉพาะชิ้นที่เราปิด + คืนสถานะ ให้ตัวยืนเองตามฟิสิกส์

local Movement = { }
do
    local LockTarget, HoldTarget, Bound, PinConnection = nil, nil, false, nil
    local Collide = { }
    local FallStates = { Enum.HumanoidStateType.Freefall, Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Flying }
    local Grounded = false

    local function Body()
        local Character = LocalPlayer.Character
        local Root = Character and Character:FindFirstChild("HumanoidRootPart")
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        return Character, Root, Humanoid
    end

    local function Noclip(Character)
        for _, Part in ipairs(Character:GetDescendants()) do
            if Part:IsA("BasePart") and Part.CanCollide then
                Collide[Part] = true
                Part.CanCollide = false
            end
        end
    end

    local function SetGround(On, Humanoid)
        if not Humanoid then return end
        if On then
            for _, State in ipairs(FallStates) do
                if not Grounded or Humanoid:GetStateEnabled(State) then pcall(Humanoid.SetStateEnabled, Humanoid, State, false) end
            end
            local Current = Humanoid:GetState()
            if Current == Enum.HumanoidStateType.Freefall or Current == Enum.HumanoidStateType.FallingDown then
                pcall(Humanoid.ChangeState, Humanoid, Enum.HumanoidStateType.Running)
            end
            Grounded = true
        elseif Grounded then
            for _, State in ipairs(FallStates) do pcall(Humanoid.SetStateEnabled, Humanoid, State, true) end
            Grounded = false
        end
    end

    local function Goal()
        local Target = HoldTarget or LockTarget
        if type(Target) == "function" then
            local Ok, Value = pcall(Target)
            return Ok and typeof(Value) == "CFrame" and Value or nil
        end
        return Target
    end

    local function Pin(Full)
        local Character, Root, Humanoid = Body()
        if not (Root and Humanoid) or Humanoid.Health <= 0 then return end
        local Target = Goal()
        if not Target then return end
        if Full then
            Noclip(Character)
            SetGround(true, Humanoid)
        end
        Root.CFrame = Target
        Root.AssemblyLinearVelocity = Vector3.zero
        Root.AssemblyAngularVelocity = Vector3.zero
    end

    local function Start()
        if Bound then return end
        Bound = true
        RunService:BindToRenderStep("Valkyrie_LTFMove", Enum.RenderPriority.Camera.Value - 1, function() Pin(true) end)
        PinConnection = TrackConnection(RunService.Heartbeat:Connect(function() Pin(false) end))
    end

    local function Stop()
        if not Bound or LockTarget or HoldTarget then return end
        Bound = false
        pcall(function() RunService:UnbindFromRenderStep("Valkyrie_LTFMove") end)
        if PinConnection then PinConnection:Disconnect() PinConnection = nil end
        for Part in pairs(Collide) do
            if Part.Parent then pcall(function() Part.CanCollide = true end) end
        end
        table.clear(Collide)
        local _, _, Humanoid = Body()
        SetGround(false, Humanoid)
    end

    function Movement.Lock(Target)
        LockTarget = Target
        if Target then Start() else Stop() end
    end

    function Movement.Hold(Target)
        HoldTarget = Target
        if Target then Start() else Stop() end
    end

    function Movement.Release()
        LockTarget, HoldTarget = nil, nil
        Stop()
    end

    -- วาร์ปไปจุดเดียว (เดินทาง/เก็บแร่) - ปล่อย Lock ก่อน ไม่งั้นเฟรมถัดไปโดนดึงกลับจุดตี
    function Movement.Teleport(Target)
        Movement.Release()
        local Character = Body()
        if Character then pcall(function() Character:PivotTo(Target) end) end
    end

    function Movement.Locked()
        return LockTarget ~= nil
    end
end

-- ลำดับความสำคัญของระบบที่ขยับตัวละคร (หน้า Priority) - ประกาศไว้ก่อนทุกระบบ ฟังก์ชันอยู่ท้ายส่วน Miscellaneous
local Runner = { }

---- ============ Auto Train ============ ----
--
-- โซนฝึกของเกม = workspace.CanAttackFolder.TrainArea.Train_<id> (11 โซน) ค่าอยู่ใน Config.TrainArea.Config:
--   1-8  ปลดด้วย Rebirth (0, 2, 5, 9, 12, 15, 18, 21) - Basic 1.5 / 2 / 4 / 6 / 8 / 10 / 15 / 25
--   9-11 IsPay (ซื้อด้วย Robux: dev product AutoTrainArea_<id>) - Basic 100 / 10 / 20
-- เกมทำเองหมดเมื่อตัวละครยืนในโซน: server ตั้ง attribute AutoTrainAreaID ให้ผู้เล่น ->
-- TrainCTRL ของเกมยิง IntoAutoTrainRE(id) แล้ว TrainOnceRE(uuid) ทุก 0.2 วิ / ออกจากโซน = ExitAutoTrainRE()
-- ฮับเลยแค่พาตัวไปยืนในโซนแล้วเฝ้าไว้ ไม่ยิง remote เอง (เหมือนผู้เล่นเดินเข้าไปเอง)

local Train = { Running = false, Thread = nil, Status = nil, Return = nil }

-- ค่าสำรองถ้า require config ของเกมไม่ได้ (ตรงกับ Config.TrainArea.Config ตอนเขียน)
Train.Zones = {
    { NeedRebirth = 0, Basic = 1.5 }, { NeedRebirth = 2, Basic = 2 }, { NeedRebirth = 5, Basic = 4 },
    { NeedRebirth = 9, Basic = 6 }, { NeedRebirth = 12, Basic = 8 }, { NeedRebirth = 15, Basic = 10 },
    { NeedRebirth = 18, Basic = 15 }, { NeedRebirth = 21, Basic = 25 },
    { NeedRebirth = 0, Basic = 100, IsPay = true }, { NeedRebirth = 0, Basic = 10, IsPay = true },
    { NeedRebirth = 0, Basic = 20, IsPay = true },
}

pcall(function()
    local Zones = require(ReplicatedStorage.Config.TrainArea.Config)
    if type(Zones) == "table" and #Zones > 0 then Train.Zones = Zones end
end)

-- ชื่อในดรอปดาวน์ -> id โซน ("Best Unlocked" = 0)
Train.Labels, Train.LabelToId = { "Best Unlocked" }, { ["Best Unlocked"] = 0 }
for Id, Zone in ipairs(Train.Zones) do
    local Label = Zone.IsPay and string.format("Zone %d (Paid)", Id)
        or string.format("Zone %d (Rebirth %d)", Id, Zone.NeedRebirth or 0)
    table.insert(Train.Labels, Label)
    Train.LabelToId[Label] = Id
end

function Train.Rebirth()
    local Eco = LocalPlayer:FindFirstChild("Eco")
    local Value = Eco and Eco:FindFirstChild("rebirth")
    return Value and tonumber(Value.Value) or 0
end

-- โซนเสียเงินไม่มีทางรู้ล่วงหน้าว่าซื้อแล้วไหม - Best เลยเลือกแค่โซน Rebirth (Basic สูงสุดที่ปลดแล้ว)
function Train.BestZone()
    local Rebirth, Best, BestBasic = Train.Rebirth(), 1, -1
    for Id, Zone in ipairs(Train.Zones) do
        if not Zone.IsPay and Rebirth >= (Zone.NeedRebirth or 0) and (Zone.Basic or 0) > BestBasic then
            Best, BestBasic = Id, Zone.Basic or 0
        end
    end
    return Best
end

function Train.Target()
    local Id = Train.LabelToId[getgenv().ConfigurationTable.TrainZone] or 0
    if Id == 0 then return Train.BestZone() end
    return Id
end

function Train.Area(Id)
    local Folder = workspace:FindFirstChild("CanAttackFolder")
    Folder = Folder and Folder:FindFirstChild("TrainArea")
    return Folder and Folder:FindFirstChild("Train_" .. Id)
end

function Train.Root()
    local Character = LocalPlayer.Character
    return Character and Character:FindFirstChild("HumanoidRootPart")
end

function Train.Controller()
    local Ok, Module = pcall(function() return require(ReplicatedStorage.CTRL.TrainCTRL) end)
    return Ok and type(Module) == "table" and Module or nil
end

function Train.Set(Key, Value)
    if Train.Status then Train.Status:Set(Key, Value) end
end

function Train.Stop()
    Train.Running = false
    if Train.Status then Train.Status:SetState("Idle") end

    -- ออกจากโซน = server ล้าง AutoTrainAreaID แล้ว TrainCTRL ของเกมยิง ExitAutoTrainRE เอง
    local Root, Back = Train.Root(), Train.Return
    Train.Return = nil
    if Root and Back and LocalPlayer:GetAttribute("AutoTrainAreaID") ~= nil then
        pcall(function() LocalPlayer.Character:PivotTo(Back) end)
    end
end

function Train.Start()
    if Train.Running then return end
    Train.Running = true

    local Token = SessionToken
    Train.Thread = task.spawn(function()
        local Failed = { }       -- โซนที่ยืนแล้ว server ไม่ยอมให้ (ยังไม่ปลด / ยังไม่ได้ซื้อ)

        while Train.Running and getgenv().ValkyrieSession == Token do
            local Id = Train.Target()
            if Failed[Id] then Id = Train.BestZone() end

            local Root, Area = Train.Root(), Train.Area(Id)
            local Current = LocalPlayer:GetAttribute("AutoTrainAreaID")

            Train.Set("Zone", Id)
            Train.Set("Rebirth", Train.Rebirth())

            local Turn, Owner = Runner.Turn("Train")
            if not Turn then
                -- ระบบที่สำคัญกว่ามีงาน (หน้า Priority) - ไม่แตะตัวละคร ให้ตัวนั้นพาไปเอง
                Train.Return = nil
                Train.Status:SetState("Waiting")
                Train.Set("State", "Paused - " .. Runner.Label(Owner) .. " first")
            elseif not (Root and Area) then
                Train.Status:SetState("Waiting")
                Train.Set("State", "Waiting for character / zone")
            elseif Current == Id then
                Train.Status:SetState("Running")
                Train.Set("State", "Training")

                -- ยืนในโซนแล้วแต่ TrainCTRL ไม่ได้เริ่ม (เช่นรีสปอนกลางโซน) = สั่งเริ่มผ่านโค้ดของเกมเอง
                local Controller = Train.Controller()
                if Controller and Controller.GetIsAutoing and not Controller.GetIsAutoing() and Controller.StartAutoTrain then
                    pcall(Controller.StartAutoTrain)
                end
            else
                Train.Return = Train.Return or Root.CFrame
                Train.Status:SetState("Running")
                Train.Set("State", "Moving to zone")

                local Zone = Train.Zones[Id] or { }
                pcall(function() LocalPlayer.Character:PivotTo(Area:GetPivot() + Vector3.new(0, 4, 0)) end)

                -- server ตั้ง attribute ภายใน ~1 วิ (วัดจริง) - รอ 4 วิไม่มา = โซนนี้เข้าไม่ได้
                local Waited = 0
                while Waited < 4 and LocalPlayer:GetAttribute("AutoTrainAreaID") ~= Id do
                    Waited = Waited + task.wait(0.25)
                end

                if LocalPlayer:GetAttribute("AutoTrainAreaID") ~= Id and Id ~= Train.BestZone() then
                    Failed[Id] = true
                    Library:Notify("Auto Train", string.format(Zone.IsPay and "Zone %d is not owned - using the best unlocked zone"
                        or "Zone %d is locked - using the best unlocked zone", Id), 5)
                end
            end

            task.wait(1)
        end
    end)
end

Window:Category("General")

local TrainPage = Window:Page({ Name = "Auto Train", Icon = "activity", Columns = 2 })

local TrainMainSection = TrainPage:Section({
    Name = "Auto Train",
    Description = "Stand in a train zone and let the game train",
    Side = 1
})

local TrainInfoSection = TrainPage:Section({
    Name = "Status",
    Side = 2
})

Train.Status = TrainInfoSection:Status({
    Name = "Auto Train Status",
    Rows = { "State", "Zone", "Rebirth" }
})

TrainMainSection:Dropdown({
    Name = "Train Zone",
    Description = "Best Unlocked picks the strongest zone your rebirth opens",
    Flag = "LTFTrainZone",
    Items = Train.Labels,
    KeepOrder = true,
    Default = getgenv().ConfigurationTable.TrainZone,
    Multi = false,
    Callback = function(Value)
        if type(Value) ~= "string" or Value == "" then return end
        getgenv().ConfigurationTable.TrainZone = Value
        SaveConfiguration()
    end
})

TrainMainSection:Toggle({
    Name = "Auto Train",
    Flag = "LTFAutoTrain",
    Default = getgenv().ConfigurationTable.AutoTrain,
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoTrain = Value
        SaveConfiguration()

        if Value then Train.Start() else Train.Stop() end
    end
})

TrainInfoSection:Guide("How to use", {
    "Pick a Train Zone (Best Unlocked is the default)",
    "Turn on Auto Train: it moves you into the zone and the game trains on its own",
    "Paid zones (9-11) need the Robux purchase - if not owned it falls back to the best unlocked zone",
    "Turning it off moves you back to where you started",
})

---- ============ Auto Rebirth ============ ----
--
-- Config.Rebirth.Config = 41 รอบ: รอบที่ n ต้อง Level >= NeedLevel (25, 50, 75 ...) ได้ตัวคูณ ExpBasic / CoinBasic
-- ปุ่ม Rebirth ของเกม (RebirthGUI) เช็ค Level >= GetNeedLevel(rebirth + 1) แล้วยิง TryRebirthRE
-- ฮับเรียก handler ตัวเดียวกันของปุ่มนั้น (ผ่าน getconnections) = args ตรงกับที่เกมส่งเสมอ / ไม่มี = ยิง TryRebirthRE() เอง
-- UpdateAutoRebirthRE มีอยู่ใน Remote.Rebirth แต่ไม่มีโค้ด client ไหนของเกมเรียก (args ไม่รู้) เลยไม่ใช้

local Rebirth = { Running = false, Status = nil, LastTry = 0 }

Rebirth.Config = { }
pcall(function()
    local Config = require(ReplicatedStorage.Config.Rebirth.Config)
    if type(Config) == "table" then Rebirth.Config = Config end
end)

function Rebirth.Eco(Name)
    local Eco = LocalPlayer:FindFirstChild("Eco")
    local Value = Eco and Eco:FindFirstChild(Name)
    return Value and tonumber(Value.Value) or 0
end

-- ระดับที่ต้องมีสำหรับรอบถัดไป (nil = ตันแล้ว)
function Rebirth.NeedLevel()
    local Next = Rebirth.Config[Rebirth.Eco("rebirth") + 1]
    return Next and tonumber(Next.NeedLevel) or nil
end

function Rebirth.Multiplier()
    local Current = Rebirth.Config[Rebirth.Eco("rebirth")]
    if not Current then return "x1 Exp / x1 Coin" end
    return string.format("x%s Exp / x%s Coin", tostring(Current.ExpBasic or 1), tostring(Current.CoinBasic or 1))
end

function Rebirth.Fire()
    local Remote = ReplicatedStorage:FindFirstChild("Remote")
    Remote = Remote and Remote:FindFirstChild("Rebirth")
    Remote = Remote and Remote:FindFirstChild("TryRebirthRE")
    if not Remote then return false end

    -- handler ของปุ่ม Rebirth ในเกม (upvalue มี TryRebirthRE)
    if typeof(getconnections) == "function" then
        local Ok, Done = pcall(function()
            local Button = LocalPlayer.PlayerGui.Main.Rebirth.Main.Info.Bottom.Button.Rebirth.Button
            for _, Connection in ipairs(getconnections(Button.MouseButton1Click)) do
                local Handler = Connection.Function
                if Handler then
                    for _, Value in pairs(debug.getupvalues(Handler)) do
                        if Value == Remote then
                            Handler()
                            return true
                        end
                    end
                end
            end
            return false
        end)
        if Ok and Done then return true end
    end

    Remote:FireServer()
    return true
end

function Rebirth.Update()
    if not Rebirth.Status then return end
    local Need = Rebirth.NeedLevel()
    Rebirth.Status:Set("Rebirth", string.format("%d / %d", Rebirth.Eco("rebirth"), #Rebirth.Config))
    Rebirth.Status:Set("Level", Need and string.format("%d / %d", Rebirth.Eco("level"), Need) or tostring(Rebirth.Eco("level")))
    Rebirth.Status:Set("Bonus", Rebirth.Multiplier())
end

-- คืน true = ยิงไปแล้ว
function Rebirth.Try()
    local Need = Rebirth.NeedLevel()
    if not Need or Rebirth.Eco("level") < Need then return false end
    if os.clock() - Rebirth.LastTry < 3 then return false end

    Rebirth.LastTry = os.clock()
    return Rebirth.Fire()
end

function Rebirth.Start()
    if Rebirth.Running then return end
    Rebirth.Running = true

    local Token = SessionToken
    task.spawn(function()
        while Rebirth.Running and getgenv().ValkyrieSession == Token do
            Rebirth.Update()

            if not Rebirth.NeedLevel() then
                Rebirth.Status:SetState("Done")
                Rebirth.Status:Set("State", "Max rebirth")
            elseif Rebirth.Eco("level") >= Rebirth.NeedLevel() then
                Rebirth.Status:SetState("Running")
                Rebirth.Status:Set("State", "Rebirthing")

                local Before = Rebirth.Eco("rebirth")
                if Rebirth.Try() then
                    -- รอ server อัปค่า rebirth (ไม่ขึ้นใน 5 วิ = รอบหน้าลองใหม่)
                    local Waited = 0
                    while Waited < 5 and Rebirth.Eco("rebirth") == Before do
                        Waited = Waited + task.wait(0.25)
                    end
                end
            else
                Rebirth.Status:SetState("Waiting")
                Rebirth.Status:Set("State", "Waiting for level")
            end

            task.wait(1)
        end
    end)
end

function Rebirth.Stop()
    Rebirth.Running = false
    if Rebirth.Status then
        Rebirth.Status:SetState("Idle")
        Rebirth.Status:Set("State", nil)
    end
end

local RebirthPage = Window:Page({ Name = "Auto Rebirth", Icon = "trending-up", Columns = 2 })

local RebirthMainSection = RebirthPage:Section({
    Name = "Auto Rebirth",
    Side = 1
})

local RebirthInfoSection = RebirthPage:Section({
    Name = "Status",
    Side = 2
})

Rebirth.Status = RebirthInfoSection:Status({
    Name = "Auto Rebirth Status",
    Rows = { "State", "Rebirth", "Level", "Bonus" }
})

RebirthMainSection:Toggle({
    Name = "Auto Rebirth",
    Flag = "LTFAutoRebirth",
    Default = getgenv().ConfigurationTable.AutoRebirth,
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoRebirth = Value
        SaveConfiguration()

        if Value then Rebirth.Start() else Rebirth.Stop() end
    end
})

RebirthMainSection:Button({
    Name = "Rebirth Now",
    Callback = function()
        local Need = Rebirth.NeedLevel()
        if not Need then
            Library:Notify("Auto Rebirth", "Max rebirth", 4)
        elseif Rebirth.Eco("level") < Need then
            Library:Notify("Auto Rebirth", string.format("Need Lv.%d (now Lv.%d)", Need, Rebirth.Eco("level")), 4)
        else
            Rebirth.LastTry = 0
            Rebirth.Try()
        end
    end
})

RebirthInfoSection:Guide("How to use", {
    "Turn on Auto Rebirth: it rebirths as soon as your level reaches the next requirement",
    "Each rebirth raises your Exp and Coin multiplier and unlocks new train zones",
})

-- การ์ดสถานะอัปเดตเองแม้ไม่ได้เปิด (เห็นเลเวลที่ต้องการก่อนเปิด)
task.spawn(function()
    local Token = SessionToken
    while getgenv().ValkyrieSession == Token do
        if not Rebirth.Running then Rebirth.Update() end
        task.wait(2)
    end
end)

---- ============ Enhant (ตีบวก) ============ ----
--
-- Config.Enhant.Config[n] = ค่าตีจาก +(n-1) -> +n (20 ระดับ): Percent 1.0 (+1) ร่วงถึง 0.01 (+20),
-- NeedCoin 200 -> 6,000,000, EnhantStone_1 5 -> 15,000, EnhantStone_2 เริ่มที่ +12 (5 -> 600)
-- ปุ่ม Yes ของ EnhantGUI = BackpackData.TryEnhantEquipment(uuid, state) -> EnhantEquipmentRF:InvokeServer(uuid, state)
-- state = { UseProtect = true } เมื่อกดใช้ Protection Scroll (ไอเทม EnhantProtect, Type Material)
-- ระดับปัจจุบัน = BackpackData.GetItemData(uuid).Level (nil = 0) / ของที่ใส่ = GetData().equiped[Weapon|Armor|Hat]
-- เกมโชว์ "You have unlocked the Enhance." ตอน rebirth ถึง 6 = ตีบวกเปิดที่ Rebirth 6

local Enhant = { Running = false, Status = nil, Slots = { "Weapon", "Armor", "Hat" }, UnlockRebirth = 6 }

Enhant.Config = { }
pcall(function()
    local Config = require(ReplicatedStorage.Config.Enhant.Config)
    if type(Config) == "table" then Enhant.Config = Config end
end)

function Enhant.Backpack()
    local Ok, Module = pcall(function() return require(ReplicatedStorage.LocalData.BackpackData) end)
    return Ok and type(Module) == "table" and Module or nil
end

function Enhant.Count(Id)
    local Backpack = Enhant.Backpack()
    local Ok, Value = pcall(function() return Backpack.GetNumberByIDType(Id, "Material") end)
    return Ok and tonumber(Value) or 0
end

function Enhant.Coin()
    local Eco = LocalPlayer:FindFirstChild("Eco")
    local Value = Eco and Eco:FindFirstChild("coin")
    return Value and tonumber(Value.Value) or 0
end

-- ของที่ใส่อยู่ในช่องนั้น: uuid, ระดับ, ID
function Enhant.Equipped(Slot)
    local Backpack = Enhant.Backpack()
    if not Backpack then return nil end
    local Ok, Uuid, Level, Id = pcall(function()
        local Uuid = Backpack.GetData().equiped[Slot]
        if not Uuid then return nil end
        local Item = Backpack.GetItemData(Uuid) or { }
        return Uuid, tonumber(Item.Level) or 0, Item.ID
    end)
    if Ok then return Uuid, Level, Id end
    return nil
end

function Enhant.Short(Number)
    Number = tonumber(Number) or 0
    if Number >= 1e6 then return string.format("%.1fM", Number / 1e6) end
    if Number >= 1e3 then return string.format("%.1fK", Number / 1e3) end
    return tostring(Number)
end

-- ตีได้ไหม: คืน true / false, เหตุผล
function Enhant.CanAfford(Next)
    if Enhant.Coin() < (Next.NeedCoin or 0) then return false, "Not enough coins" end
    if Enhant.Count("EnhantStone_1") < (Next.EnhantStone_1 or 0) then return false, "Not enough Enhance Stone" end
    if Enhant.Count("EnhantStone_2") < (Next.EnhantStone_2 or 0) then return false, "Not enough Enhance Stone II" end
    return true
end

function Enhant.Set(Key, Value)
    if Enhant.Status then Enhant.Status:Set(Key, Value) end
end

function Enhant.Show(Slot, Level, Next)
    Enhant.Set("Item", Slot)
    Enhant.Set("Level", string.format("+%d -> +%d", Level, tonumber(getgenv().ConfigurationTable.EnhantTarget) or 10))
    if Next then
        Enhant.Set("Chance", string.format("%d%%", math.floor((Next.Percent or 0) * 100 + 0.5)))
        Enhant.Set("Cost", string.format("%s coin / %s stone%s", Enhant.Short(Next.NeedCoin), Enhant.Short(Next.EnhantStone_1),
            (Next.EnhantStone_2 or 0) > 0 and (" / " .. Enhant.Short(Next.EnhantStone_2) .. " stone II") or ""))
    else
        Enhant.Set("Chance", nil)
        Enhant.Set("Cost", nil)
    end
    Enhant.Set("Have", string.format("%s coin / %d stone / %d stone II / %d scroll", Enhant.Short(Enhant.Coin()),
        Enhant.Count("EnhantStone_1"), Enhant.Count("EnhantStone_2"), Enhant.Count("EnhantProtect")))
end

-- ตีหนึ่งครั้งที่ช่องนั้น: คืน "done" (ถึงเป้า/ไม่มีของ) / "wait" (ของไม่พอ) / "hit" (ยิงไปแล้ว)
function Enhant.Once(Slot)
    local Config = getgenv().ConfigurationTable
    local Target = tonumber(Config.EnhantTarget) or 10
    local Uuid, Level = Enhant.Equipped(Slot)
    if not Uuid then return "done" end

    local Next = Enhant.Config[Level + 1]
    Enhant.Show(Slot, Level, Next)
    if Level >= Target or not Next then return "done" end

    local Can, Why = Enhant.CanAfford(Next)
    if not Can then
        Enhant.Set("State", Why)
        return "wait"
    end

    local State = { }
    if Config.EnhantProtect and Enhant.Count("EnhantProtect") > 0 then State.UseProtect = true end

    Enhant.Set("State", "Enhancing")
    local Backpack = Enhant.Backpack()
    pcall(function() Backpack.TryEnhantEquipment(Uuid, State) end)
    return "hit"
end

function Enhant.Start()
    if Enhant.Running then return end
    Enhant.Running = true

    local Token = SessionToken
    task.spawn(function()
        while Enhant.Running and getgenv().ValkyrieSession == Token do
            local Slots = getgenv().ConfigurationTable.EnhantSlots or { }
            local Hit, Waiting = false, false

            if Rebirth.Eco("rebirth") < Enhant.UnlockRebirth then
                Enhant.Status:SetState("Waiting")
                Enhant.Set("State", string.format("Enhance unlocks at Rebirth %d", Enhant.UnlockRebirth))
                task.wait(3)
            else
                for _, Slot in ipairs(Enhant.Slots) do
                    if not (Enhant.Running and getgenv().ValkyrieSession == Token) then break end
                    if table.find(Slots, Slot) then
                        local Result = Enhant.Once(Slot)
                        if Result == "hit" then
                            Hit = true
                            task.wait(0.6)       -- RemoteFunction ตอบกลับก่อนแล้ว - เว้นจังหวะไม่ให้ยิงรัว
                            break
                        elseif Result == "wait" then
                            Waiting = true
                        end
                    end
                end

                if Hit then
                    Enhant.Status:SetState("Running")
                elseif Waiting then
                    Enhant.Status:SetState("Waiting")
                    task.wait(2)
                else
                    Enhant.Status:SetState("Done")
                    Enhant.Set("State", "All selected items reached the target")
                    task.wait(2)
                end
            end
        end
    end)
end

function Enhant.Stop()
    Enhant.Running = false
    if Enhant.Status then
        Enhant.Status:SetState("Idle")
        Enhant.Set("State", nil)
    end
end

local EnhantPage = Window:Page({ Name = "Auto Enhance", Icon = "shield", Columns = 2 })

local EnhantMainSection = EnhantPage:Section({
    Name = "Auto Enhance",
    Side = 1
})

local EnhantInfoSection = EnhantPage:Section({
    Name = "Status",
    Side = 2
})

Enhant.Status = EnhantInfoSection:Status({
    Name = "Enhance Status",
    Rows = { "State", "Item", "Level", "Chance", "Cost", "Have" }
})

EnhantMainSection:Dropdown({
    Name = "Equipment",
    Description = "Equipped items to enhance",
    Flag = "LTFEnhantSlots",
    Items = Enhant.Slots,
    KeepOrder = true,
    Default = getgenv().ConfigurationTable.EnhantSlots,
    Multi = true,
    Callback = function(Value)
        getgenv().ConfigurationTable.EnhantSlots = Value
        SaveConfiguration()
    end
})

EnhantMainSection:Slider({
    Name = "Target Level",
    Description = "Stop at this enhance level",
    Flag = "LTFEnhantTarget",
    Min = 1,
    Max = #Enhant.Config > 0 and #Enhant.Config or 20,
    Default = getgenv().ConfigurationTable.EnhantTarget,
    Callback = function(Value)
        getgenv().ConfigurationTable.EnhantTarget = Value
        SaveConfiguration()
    end
})

EnhantMainSection:Toggle({
    Name = "Use Protection Scroll",
    Description = "Spend a scroll on each try while you have one",
    Flag = "LTFEnhantProtect",
    Default = getgenv().ConfigurationTable.EnhantProtect,
    Callback = function(Value)
        getgenv().ConfigurationTable.EnhantProtect = Value
        SaveConfiguration()
    end
})

EnhantMainSection:Toggle({
    Name = "Auto Enhance",
    Flag = "LTFAutoEnhant",
    Default = getgenv().ConfigurationTable.AutoEnhant,
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoEnhant = Value
        SaveConfiguration()

        if Value then Enhant.Start() else Enhant.Stop() end
    end
})

EnhantMainSection:Button({
    Name = "Enhance Once",
    Callback = function()
        for _, Slot in ipairs(Enhant.Slots) do
            if table.find(getgenv().ConfigurationTable.EnhantSlots or { }, Slot) and Enhant.Once(Slot) == "hit" then return end
        end
        Library:Notify("Enhance", "Nothing to enhance (target reached or not enough materials)", 4)
    end
})

EnhantInfoSection:Guide("How to use", {
    "Pick the equipped items and a Target Level",
    "Turn on Auto Enhance: it tries until the target or until coins / stones run out",
    "Chance drops from 100% (+1) to 1% (+20) - a Protection Scroll is used per try when turned on",
})

task.spawn(function()
    local Token = SessionToken
    while getgenv().ValkyrieSession == Token do
        if not Enhant.Running then
            local Slots = getgenv().ConfigurationTable.EnhantSlots or { }
            for _, Slot in ipairs(Enhant.Slots) do
                if table.find(Slots, Slot) then
                    local Uuid, Level = Enhant.Equipped(Slot)
                    if Uuid then Enhant.Show(Slot, Level, Enhant.Config[Level + 1]) break end
                end
            end
        end
        task.wait(2)
    end
end)

---- ============ Auto Enchant (ใส่หิน Enchant) ============ ----
--
-- คนละระบบกับ Enhance (ตีบวก): ของแต่ละชิ้นมีช่อง Enchant = GetItemData(uuid).EnchanceNum (เช่น Weapon G_17 = 2)
-- ช่องเก็บที่ EnchanceList[ช่อง] ({ } = ว่าง) / หิน = ไอเทมใน GetData().have ที่ Type "EnchStone" (ID เช่น Fire_2, Number = จำนวน)
-- หิน 4 ธาตุ x 3 ขั้น (Config.EnchStone.EnchStoneConfig): Fire / Ice / Poison / Thunder _1 UnCommon, _2 Rare, _3 Epic
-- ได้จาก loot ของ Dungeon (Frostbound Tower) / ค่าใส่ = EnchStone.Helper.GetEnchancePrice(ID) coin (200 / 1500 / 5000)
-- ปุ่ม Enchant ของ EnchanceGUI = BackpackData.EnchantEquipment(ของ uuid, หิน uuid, ช่อง) -> Remote.Backpack.EnchantRE:FireServer
-- (วัดสด: upvalue ของปุ่ม = ของ uuid / หินที่เลือก / เลขช่องจากปุ่ม Button1-2 ตรงกลาง - ยังไม่ได้ลองใส่จริง บัญชีทดสอบไม่มีหิน)

local Enchant = {
    Running = false,
    Status = nil,
    Slots = { "Weapon", "Armor", "Hat" },
    Types = { "Fire", "Ice", "Poison", "Thunder" },
    Failed = { },        -- ["ของ uuid|ช่อง|หิน ID"] = os.clock() ที่ใส่แล้วช่องยังว่าง (เซิร์ฟไม่รับ) - ข้ามชั่วคราว
    Retry = 60
}

Enchant.Helper = nil
pcall(function() Enchant.Helper = require(ReplicatedStorage.Config.EnchStone.Helper) end)

function Enchant.Price(Id)
    local Ok, Value = pcall(function() return Enchant.Helper.GetEnchancePrice(Id) end)
    return Ok and tonumber(Value) or 0
end

-- หินที่มี: { { Uuid, Id, Type, Tier, Number } ... } เรียงขั้นสูงก่อน แล้วตามลำดับธาตุที่เลือก
function Enchant.Stones()
    local Backpack = Enhant.Backpack()
    local Types = getgenv().ConfigurationTable.EnchantTypes or { }
    local Stones = { }
    pcall(function()
        for Uuid, Item in pairs(Backpack.GetData().have or { }) do
            if type(Item) == "table" and Item.Type == "EnchStone" and (tonumber(Item.Number) or 1) > 0 then
                local Kind, Tier = tostring(Item.ID):match("^(%a+)_(%d+)$")
                local Order = Kind and table.find(Types, Kind)
                if Order then
                    table.insert(Stones, { Uuid = Uuid, Id = Item.ID, Type = Kind, Tier = tonumber(Tier), Order = Order,
                        Number = tonumber(Item.Number) or 1 })
                end
            end
        end
    end)
    table.sort(Stones, function(A, B)
        if A.Tier ~= B.Tier then return A.Tier > B.Tier end
        return A.Order < B.Order
    end)
    return Stones
end

-- ของที่ใส่อยู่: uuid, ID, จำนวนช่อง, รายการช่อง
function Enchant.Item(Slot)
    local Backpack = Enhant.Backpack()
    local Ok, Uuid, Id, Count, List = pcall(function()
        local Uuid = Backpack.GetData().equiped[Slot]
        if not Uuid then return nil end
        local Item = Backpack.GetItemData(Uuid) or { }
        return Uuid, Item.ID, tonumber(Item.EnchanceNum) or 0, Item.EnchanceList or { }
    end)
    if Ok and Uuid then return Uuid, Id, Count, List end
    return nil
end

function Enchant.Empty(Entry)
    return type(Entry) ~= "table" or next(Entry) == nil
end

function Enchant.Set(Key, Value)
    if Enchant.Status then Enchant.Status:Set(Key, Value) end
end

function Enchant.Show()
    local Selected = getgenv().ConfigurationTable.EnchantSlots or { }
    local Items = { }
    for _, Slot in ipairs(Enchant.Slots) do
        if table.find(Selected, Slot) then
            local Uuid, _, Count, List = Enchant.Item(Slot)
            if Uuid then
                local Used = 0
                for Index = 1, Count do
                    if not Enchant.Empty(List[Index]) then Used = Used + 1 end
                end
                table.insert(Items, string.format("%s %d/%d", Slot, Used, Count))
            end
        end
    end
    Enchant.Set("Slots", #Items > 0 and table.concat(Items, " · ") or "-")

    local Counts = { }
    for _, Stone in ipairs(Enchant.Stones()) do
        Counts[Stone.Id] = (Counts[Stone.Id] or 0) + Stone.Number
    end
    local Have = { }
    for Id, Number in pairs(Counts) do table.insert(Have, Id .. " x" .. Number) end
    table.sort(Have)
    Enchant.Set("Stones", #Have > 0 and table.concat(Have, ", ") or "None (drops in the Dungeon)")
    Enchant.Set("Coin", Enhant.Short(Enhant.Coin()))
end

-- ใส่หินหนึ่งก้อน: คืน "hit" (ยิงแล้ว) / "wait" (มีช่องว่างแต่หิน/เหรียญไม่พอ) / "done" (ไม่มีช่องว่าง)
function Enchant.Once()
    local Selected = getgenv().ConfigurationTable.EnchantSlots or { }
    local Stones = Enchant.Stones()
    local Waiting = nil

    for _, Slot in ipairs(Enchant.Slots) do
        if table.find(Selected, Slot) then
            local Uuid, Id, Count, List = Enchant.Item(Slot)
            for Index = 1, Uuid and Count or 0 do
                if Enchant.Empty(List[Index]) then
                    for _, Stone in ipairs(Stones) do
                        local Key = Uuid .. "|" .. Index .. "|" .. Stone.Id
                        local FailedAt = Enchant.Failed[Key]
                        if not (FailedAt and os.clock() - FailedAt < Enchant.Retry) then
                            if Enhant.Coin() < Enchant.Price(Stone.Id) then
                                Waiting = Waiting or "Not enough coins"
                            else
                                Enchant.Set("State", string.format("Enchanting %s slot %d with %s", Slot, Index, Stone.Id))
                                Enchant.Set("Item", tostring(Id))
                                pcall(function() Enhant.Backpack().EnchantEquipment(Uuid, Stone.Uuid, Index) end)

                                -- รอข้อมูลของอัปเดต: ช่องยังว่าง = เซิร์ฟไม่รับหินนี้ที่ช่องนี้ พักไว้ก่อน
                                local Deadline = os.clock() + 2
                                repeat task.wait(0.2) until os.clock() > Deadline
                                    or not Enchant.Empty(select(4, Enchant.Item(Slot))[Index])
                                local _, _, _, After = Enchant.Item(Slot)
                                if not After or Enchant.Empty(After[Index]) then Enchant.Failed[Key] = os.clock() end
                                return "hit"
                            end
                        end
                    end
                    Waiting = Waiting or (#Stones == 0 and "No stones of the selected types" or "Waiting to retry")
                end
            end
        end
    end

    if Waiting then
        Enchant.Set("State", Waiting)
        return "wait"
    end
    return "done"
end

function Enchant.Start()
    if Enchant.Running then return end
    Enchant.Running = true

    local Token = SessionToken
    task.spawn(function()
        while Enchant.Running and getgenv().ValkyrieSession == Token do
            Enchant.Show()
            local Result = Enchant.Once()
            if Result == "hit" then
                Enchant.Status:SetState("Running")
                task.wait(0.5)
            elseif Result == "wait" then
                Enchant.Status:SetState("Waiting")
                task.wait(3)
            else
                Enchant.Status:SetState("Done")
                Enchant.Set("State", "Every enchant slot is filled")
                task.wait(3)
            end
        end
    end)
end

function Enchant.Stop()
    Enchant.Running = false
    if Enchant.Status then
        Enchant.Status:SetState("Idle")
        Enchant.Set("State", nil)
    end
end

local EnchantPage = Window:Page({ Name = "Auto Enchant", Icon = "wand-2", Columns = 2 })

local EnchantMainSection = EnchantPage:Section({
    Name = "Auto Enchant",
    Side = 1
})

local EnchantInfoSection = EnchantPage:Section({
    Name = "Status",
    Side = 2
})

Enchant.Status = EnchantInfoSection:Status({
    Name = "Enchant Status",
    Rows = { "State", "Item", "Slots", "Stones", "Coin" }
})

EnchantMainSection:Dropdown({
    Name = "Equipment",
    Description = "Equipped items to enchant",
    Flag = "LTFEnchantSlots",
    Items = Enchant.Slots,
    KeepOrder = true,
    Default = getgenv().ConfigurationTable.EnchantSlots,
    Multi = true,
    Callback = function(Value)
        getgenv().ConfigurationTable.EnchantSlots = Value
        SaveConfiguration()
    end
})

EnchantMainSection:Dropdown({
    Name = "Stone Types",
    Description = "Elements to use - on equal tier, the one higher in this list goes first",
    Flag = "LTFEnchantTypes",
    Items = Enchant.Types,
    KeepOrder = true,
    Default = getgenv().ConfigurationTable.EnchantTypes,
    Multi = true,
    Callback = function(Value)
        getgenv().ConfigurationTable.EnchantTypes = Value
        SaveConfiguration()
    end
})

EnchantMainSection:Toggle({
    Name = "Auto Enchant",
    Flag = "LTFAutoEnchant",
    Default = getgenv().ConfigurationTable.AutoEnchant,
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoEnchant = Value
        SaveConfiguration()

        if Value then Enchant.Start() else Enchant.Stop() end
    end
})

EnchantMainSection:Button({
    Name = "Enchant Once",
    Callback = function()
        if Enchant.Once() ~= "hit" then
            Library:Notify("Enchant", "Nothing to enchant (no empty slot, stone or coins)", 4)
        end
        Enchant.Show()
    end
})

EnchantInfoSection:Guide("How to use", {
    "Pick the equipped items and the stone elements to use",
    "Turn on Auto Enchant: it fills every empty enchant slot with your highest tier stone",
    "Stones drop in the Dungeon - each one costs 200 / 1,500 / 5,000 coins to put in (tier 1 / 2 / 3)",
    "Slots that already hold a stone are left as they are",
})

task.spawn(function()
    local Token = SessionToken
    while getgenv().ValkyrieSession == Token do
        if not Enchant.Running then pcall(Enchant.Show) end
        task.wait(3)
    end
end)

---- ============ Auto Forge ============ ----
--
-- ปุ่ม Forge ของ ForgeGUI = Remote.Forge.ForgeRF:InvokeServer({ ConfigType = "Weapon" | "Armor", UUIDList = { [uuid] = จำนวน } })
-- (จับจาก spy + ยิงตรงแล้ว forge สำเร็จ - ตอบกลับเป็นลิสต์ของที่ได้) ต้องใส่รวม >= 4 ชิ้น และไม่เกิน 4 ชนิด
-- จำนวนชิ้น 4 -> 13 เปลี่ยนแค่โอกาส Katana / Great (Config.Weapon.ForgePercent) - พลังของที่ได้มาจากค่าเฉลี่ย
-- Power ของ ore ที่ใส่ (GetOreAvgPower) เลยใส่ ore Power สูงสุดที่มีซ้ำ ๆ ก่อนเสมอ
-- โต๊ะ Forge = workspace.WorldModel.ForgeTable.Part (มี ProximityPrompt) - วาร์ปไปยืนข้างโต๊ะตอน forge แล้วกลับที่เดิม

local Forge = { Running = false, Status = nil, Count = 0, Types = { "Weapon", "Armor" } }

Forge.OreConfig = { }
pcall(function()
    local Config = require(ReplicatedStorage.Config.Ore.Config)
    if type(Config) == "table" then Forge.OreConfig = Config end
end)

function Forge.OreName(Id)
    local Ok, Name = pcall(function() return require(ReplicatedStorage.Config.Ore.Helper).GetDisName(Id) end)
    return Ok and type(Name) == "string" and Name or tostring(Id)
end

-- ore ทั้งหมดในกระเป๋า เรียง Power มากไปน้อย (เท่ากัน = Quality)
function Forge.Ores()
    local List = { }
    local Backpack = Enhant.Backpack()
    if not Backpack then return List end

    pcall(function()
        for Uuid, Item in pairs(Backpack.GetData().have) do
            if Item.Type == "Ore" and (tonumber(Item.Number) or 0) > 0 then
                local Config = Forge.OreConfig[Item.ID] or { }
                table.insert(List, {
                    Uuid = Uuid, Id = Item.ID, Number = tonumber(Item.Number) or 0,
                    Power = tonumber(Config.Power) or 0, Quality = tonumber(Config.Quality) or 0
                })
            end
        end
    end)

    table.sort(List, function(A, B)
        if A.Power ~= B.Power then return A.Power > B.Power end
        return A.Quality > B.Quality
    end)
    return List
end

-- เลือก ore ชุดหนึ่ง: ไล่จาก Power สูงสุด ได้สูงสุด 4 ชนิด รวม Count ชิ้น (ไม่ถึง 4 ชิ้น = nil)
function Forge.Pick(Count)
    local Picked, Total, Types, Best = { }, 0, 0, nil
    for _, Ore in ipairs(Forge.Ores()) do
        if Types >= 4 or Total >= Count then break end
        local Take = math.min(Ore.Number, Count - Total)
        Picked[Ore.Uuid] = Take
        Total, Types = Total + Take, Types + 1
        Best = Best or Ore
    end
    if Total < 4 then return nil, Total end
    return Picked, Total, Best
end

function Forge.Table()
    local World = workspace:FindFirstChild("WorldModel")
    local Desk = World and World:FindFirstChild("ForgeTable")
    return Desk and Desk:FindFirstChild("Part")
end

function Forge.Remote()
    local Remote = ReplicatedStorage:FindFirstChild("Remote")
    Remote = Remote and Remote:FindFirstChild("Forge")
    return Remote and Remote:FindFirstChild("ForgeRF")
end

function Forge.Set(Key, Value)
    if Forge.Status then Forge.Status:Set(Key, Value) end
end

function Forge.Show()
    local Total, Best = 0, nil
    for _, Ore in ipairs(Forge.Ores()) do
        Total = Total + Ore.Number
        Best = Best or Ore
    end
    Forge.Set("Ores", Best and string.format("%d (best: %s x%d, power %s)", Total, Forge.OreName(Best.Id), Best.Number, tostring(Best.Power)) or "0")
    Forge.Set("Forged", Forge.Count)
end

-- forge หนึ่งครั้ง (ต้องยืนข้างโต๊ะอยู่แล้ว): คืน true = ได้ของ
function Forge.Once()
    local Config = getgenv().ConfigurationTable
    local Picked = Forge.Pick(math.clamp(tonumber(Config.ForgeOreCount) or 4, 4, 13))
    local Remote = Forge.Remote()
    if not (Picked and Remote) then return false end

    local Ok, Result = pcall(Remote.InvokeServer, Remote, {
        ConfigType = table.find(Forge.Types, Config.ForgeType) and Config.ForgeType or "Weapon",
        UUIDList = Picked
    })

    if Ok and type(Result) == "table" and Result[1] then
        Forge.Count = Forge.Count + #Result
        Forge.Set("Last", tostring(Result[1].ID))
        return true
    end
    return false
end

-- ไปโต๊ะ forge แล้ว forge จน ore ไม่พอ (หรือ Limit ครั้ง) แล้วกลับที่เดิม
function Forge.Visit(Limit)
    local Root, Desk = Train.Root(), Forge.Table()
    if not (Root and Desk) then return 0 end

    local Back = Root.CFrame
    local Far = (Root.Position - Desk.Position).Magnitude > 12
    if Far then
        -- Hold ทับ Lock ของฟาร์มอื่น (Auto Stage) ระหว่าง forge - ปล่อยแล้วกลับไปตรึงจุดเดิมเอง
        local Spot = CFrame.new(Desk.Position + Vector3.new(0, 1, 6), Desk.Position)
        if Movement.Locked() then Movement.Hold(Spot) else pcall(function() LocalPlayer.Character:PivotTo(Spot) end) end
        task.wait(0.5)
    end

    local Done, Fails = 0, 0
    while Done < (Limit or math.huge) and Forge.Pick(math.clamp(tonumber(getgenv().ConfigurationTable.ForgeOreCount) or 4, 4, 13)) do
        if Limit == nil and not Forge.Running then break end
        if Forge.Once() then
            Done, Fails = Done + 1, 0
            Forge.Show()
        else
            Fails = Fails + 1
            if Fails >= 2 then break end      -- server ไม่ยอม 2 ครั้งติด (กระเป๋าเต็ม ฯลฯ) = เลิกรอบนี้
        end
        task.wait(0.5)
    end

    if Far then
        if Movement.Locked() then Movement.Hold(nil) else pcall(function() LocalPlayer.Character:PivotTo(Back) end) end
    end
    return Done
end

function Forge.Start()
    if Forge.Running then return end
    Forge.Running = true

    local Token = SessionToken
    task.spawn(function()
        while Forge.Running and getgenv().ValkyrieSession == Token do
            Forge.Show()
            local Picked, Total = Forge.Pick(math.clamp(tonumber(getgenv().ConfigurationTable.ForgeOreCount) or 4, 4, 13))

            local Turn, Owner = Runner.Turn("Forge")
            if Picked and not Turn then
                Forge.Status:SetState("Waiting")
                Forge.Set("State", "Paused - " .. Runner.Label(Owner) .. " first")
                task.wait(1)
            elseif Picked then
                Forge.Status:SetState("Running")
                Forge.Set("State", "Forging")
                -- ระหว่างไปโต๊ะ Forge ห้ามระบบอื่นแย่งตัว (Stage ปล่อยตัวแล้วรอ) - รอ Stage ปล่อยก่อนออกเดิน
                Runner.Locked = "Forge"
                local Wait = os.clock() + 3
                while Movement.Locked() and os.clock() < Wait do task.wait(0.1) end
                local Ok, Done = pcall(Forge.Visit)
                Runner.Locked = nil
                if not Ok or Done == 0 then
                    Forge.Status:SetState("Waiting")
                    Forge.Set("State", "Forge refused (backpack full?)")
                    task.wait(5)
                end
            else
                Forge.Status:SetState("Waiting")
                Forge.Set("State", string.format("Need at least 4 ores (have %d)", Total or 0))
                task.wait(3)
            end
            task.wait(0.5)
        end
    end)
end

function Forge.Stop()
    Forge.Running = false
    if Forge.Status then
        Forge.Status:SetState("Idle")
        Forge.Set("State", nil)
    end
end

local ForgePage = Window:Page({ Name = "Auto Forge", Icon = "swords", Columns = 2 })

local ForgeMainSection = ForgePage:Section({
    Name = "Auto Forge",
    Side = 1
})

local ForgeInfoSection = ForgePage:Section({
    Name = "Status",
    Side = 2
})

Forge.Status = ForgeInfoSection:Status({
    Name = "Forge Status",
    Rows = { "State", "Ores", "Forged", "Last" }
})

ForgeMainSection:Dropdown({
    Name = "Forge Type",
    Flag = "LTFForgeType",
    Items = Forge.Types,
    KeepOrder = true,
    Default = getgenv().ConfigurationTable.ForgeType,
    Multi = false,
    Callback = function(Value)
        if type(Value) ~= "string" or Value == "" then return end
        getgenv().ConfigurationTable.ForgeType = Value
        SaveConfiguration()
    end
})

ForgeMainSection:Slider({
    Name = "Ores Per Forge",
    Description = "4 is all Katana, 13 is all Great - power comes from the ores' average",
    Flag = "LTFForgeOreCount",
    Min = 4,
    Max = 13,
    Default = getgenv().ConfigurationTable.ForgeOreCount,
    Callback = function(Value)
        getgenv().ConfigurationTable.ForgeOreCount = Value
        SaveConfiguration()
    end
})

ForgeMainSection:Toggle({
    Name = "Auto Forge",
    Flag = "LTFAutoForge",
    Default = getgenv().ConfigurationTable.AutoForge,
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoForge = Value
        SaveConfiguration()

        if Value then Forge.Start() else Forge.Stop() end
    end
})

ForgeMainSection:Button({
    Name = "Forge Once",
    Callback = function()
        if not Forge.Pick(math.clamp(tonumber(getgenv().ConfigurationTable.ForgeOreCount) or 4, 4, 13)) then
            Library:Notify("Auto Forge", "Need at least 4 ores", 4)
            return
        end
        task.spawn(function() Forge.Visit(1) end)
    end
})

ForgeInfoSection:Guide("How to use", {
    "Pick Forge Type and Ores Per Forge",
    "Turn on Auto Forge: it fills the forge with your highest power ores (up to 4 kinds) and forges until fewer than 4 ores are left",
    "It moves to the forge table for each batch, then back to where you were",
})

task.spawn(function()
    local Token = SessionToken
    while getgenv().ValkyrieSession == Token do
        if not Forge.Running then Forge.Show() end
        task.wait(3)
    end
end)

---- ============ Auto Dodge ============ ----
--
-- มอน/บอสตีด้วย DamageUtils (SkillSystemNew.Utils) = overlap กล่อง/ลูกบอล 3D ฝั่ง client แล้วลด HP เราผ่าน
-- CTRL.HPCTRL (ไม่มี remote) - เลยคำนวณ hitbox เองได้แม่นตรงกับเกม:
--   ท่าที่มอนกำลังเล่น = animation บนตัวมัน / Assets.Animation.Enemy_Action.<EnemyID>.<ชื่อสกิล> (ชื่อ Animation
--   = ชื่อสกิลใน Config.Enemy.SkillConfig เช่น Boss_2_S1) -> Phase[].DamageConfig -> DamageUtils.TryGetTouchConfig(มอน,
--   DamageConfig) = { CFrame, Size, Shape } ของจริง (วัดสด: ATK = Block สูง 60 หน้าตัว, S1 = Ball Ø12-30)
--   ท่าพุ่ง (FlightSpeed) = ลูกบอลวิ่งไปตามทิศหน้ามอน -> นับเป็นกล่องยาว FlightReach ไปข้างหน้า
-- จุดยืนตี (Above หลังมอน) อยู่ในกล่องของท่าที่กำลังเล่น = ย้ายไปจุดว่างใกล้สุดรอบเป้า (วงละ 8 ทิศ ห่างขึ้นเรื่อย ๆ)
-- จนท่าจบ (TimePosition เกิน ActionTime) / ไม่รู้จักท่าแต่โดนดาเมจ = หลบออกห่างตัวที่ใกล้สุด Fallback วิ

local Dodge = {
    Margin = 3, React = 70, FlightReach = 70, Fallback = 1.2, FallbackRadius = 25,
    Until = 0, Spot = nil, LastHP = nil, Anim = { }, Skills = { },
}

pcall(function()
    Dodge.Skills = require(ReplicatedStorage.Config.Enemy.SkillConfig)
end)

-- AnimationId -> ชื่อสกิล (ทุกมอน)
pcall(function()
    for _, Folder in ipairs(ReplicatedStorage.Assets.Animation.Enemy_Action:GetChildren()) do
        for _, Animation in ipairs(Folder:GetChildren()) do
            if Animation:IsA("Animation") and Dodge.Skills[Animation.Name] then
                local Id = tostring(Animation.AnimationId):match("%d+")
                if Id then Dodge.Anim[Id] = Animation.Name end
            end
        end
    end
end)

function Dodge.Enabled()
    return getgenv().ConfigurationTable.StageAutoDodge ~= false
end

function Dodge.Health()
    local Ok, Value = pcall(function() return require(ReplicatedStorage.CTRL.HPCTRL).GetCurrentHP(LocalPlayer) end)
    return Ok and tonumber(Value) or nil
end

function Dodge.Utils()
    local Ok, Module = pcall(function() return require(ReplicatedStorage.SkillSystemNew.Utils.DamageUtils) end)
    return Ok and Module or nil
end

-- hitbox ของท่าที่มอนตัวนี้กำลังเล่นอยู่ (ยังไม่จบ ActionTime) { { CFrame, Size, Shape } }
function Dodge.Boxes(Model)
    local Boxes = { }
    local Humanoid = Model:FindFirstChildOfClass("Humanoid")
    local Animator = Humanoid and Humanoid:FindFirstChildOfClass("Animator")
    local Utils = Dodge.Utils()
    if not (Animator and Utils) then return Boxes end

    for _, Track in ipairs(Animator:GetPlayingAnimationTracks()) do
        local Name = Track.Animation and Dodge.Anim[tostring(Track.Animation.AnimationId):match("%d+") or ""]
        local Skill = Name and Dodge.Skills[Name]
        if Skill and Track.TimePosition <= (tonumber(Skill.ActionTime) or 2) + 0.1 then
            for _, Phase in ipairs(Skill.Phase or { }) do
                local Config = Phase.DamageConfig
                if Config then
                    local Ok, Touch = pcall(Utils.TryGetTouchConfig, Model, Config)
                    if Ok and type(Touch) == "table" and typeof(Touch.CFrame) == "CFrame" and typeof(Touch.Size) == "Vector3" then
                        local Box = { CFrame = Touch.CFrame, Size = Touch.Size, Ball = Touch.Shape == Enum.PartType.Ball }
                        if Config.FlightSpeed then
                            -- ลูกพุ่งไปตามทิศหน้ามอน = กล่องยาวไปข้างหน้า กว้างเท่าลูก
                            local Look = Model:GetPivot().LookVector
                            Box = { CFrame = CFrame.lookAt(Touch.CFrame.Position + Look * Dodge.FlightReach / 2, Touch.CFrame.Position + Look * Dodge.FlightReach),
                                Size = Vector3.new(Touch.Size.X, Touch.Size.Y, Dodge.FlightReach), Ball = false }
                        end
                        table.insert(Boxes, Box)
                    end
                end
            end
        end
    end
    return Boxes
end

function Dodge.Inside(Point, Box)
    local Margin = Dodge.Margin
    if Box.Ball then
        return (Point - Box.CFrame.Position).Magnitude <= Box.Size.X / 2 + Margin
    end
    local Local = Box.CFrame:PointToObjectSpace(Point)
    return math.abs(Local.X) <= Box.Size.X / 2 + Margin and math.abs(Local.Y) <= Box.Size.Y / 2 + Margin
        and math.abs(Local.Z) <= Box.Size.Z / 2 + Margin
end

function Dodge.Danger(Point, Boxes)
    for _, Box in ipairs(Boxes) do
        if Dodge.Inside(Point, Box) then return true end
    end
    return false
end

-- จุดว่างใกล้ Stand ที่สุด รอบตัวเป้า (ระดับความสูงเดียวกับ Stand) / ไม่เจอ = nil
function Dodge.SafeSpot(Stand, Center, Boxes)
    for _, Radius in ipairs({ 6, 10, 15, 20, 26, 34, 44 }) do
        for Step = 0, 7 do
            local Angle = Step * math.pi / 4
            local Point = Vector3.new(Center.X + math.cos(Angle) * Radius, Stand.Y, Center.Z + math.sin(Angle) * Radius)
            if not Dodge.Danger(Point, Boxes) then return Point end
        end
    end
    return nil
end

function Dodge.Finish()
    Dodge.Until, Dodge.Spot = 0, nil
    Movement.Hold(nil)
end

function Dodge.Place(Point, Center)
    Dodge.Spot = Point
    Movement.Hold(CFrame.lookAt(Point, Center))
end

-- เรียกทุกรอบของลูปฟาร์ม: Stand = จุดตีตอนนี้ (CFrame) / Center = ตำแหน่งเป้า / Enemies = { Model, Position }
-- คืน true = กำลังหลบ
function Dodge.Update(Stand, Center, Enemies)
    local Health = Dodge.Health()
    local Hit = Health and Dodge.LastHP and Health < Dodge.LastHP - 0.01
    Dodge.LastHP = Health

    if not (Dodge.Enabled() and Stand and Center) then
        if Dodge.Spot then Dodge.Finish() end
        return false
    end

    local Boxes = { }
    for _, Enemy in ipairs(Enemies) do
        if (Enemy.Position - Center).Magnitude < Dodge.React then
            for _, Box in ipairs(Dodge.Boxes(Enemy.Model)) do table.insert(Boxes, Box) end
        end
    end

    -- จุดตีอยู่ในท่าที่กำลังมา = ไปจุดว่าง
    if Dodge.Danger(Stand.Position, Boxes) then
        if not (Dodge.Spot and not Dodge.Danger(Dodge.Spot, Boxes)) then
            local Spot = Dodge.SafeSpot(Stand.Position, Center, Boxes)
            if Spot then Dodge.Place(Spot, Center) end
        else
            Movement.Hold(CFrame.lookAt(Dodge.Spot, Center))
        end
        Dodge.Until = os.clock() + 0.15
        return Dodge.Spot ~= nil
    end

    -- โดนดาเมจจากท่าที่ไม่รู้จัก = ถอยออกจากมอนที่ใกล้สุดแนวราบ Fallback วิ
    if Hit and os.clock() >= Dodge.Until then
        local Root = Train.Root()
        local Near, Gap = nil, math.huge
        for _, Enemy in ipairs(Enemies) do
            local Distance = Root and (Enemy.Position - Root.Position).Magnitude or math.huge
            if Distance < Gap then Near, Gap = Enemy, Distance end
        end
        if Near and Root then
            local Away = (Root.Position - Near.Position) * Vector3.new(1, 0, 1)
            if Away.Magnitude < 0.5 then Away = Vector3.new(1, 0, 0) end
            Dodge.Place(Near.Position + Away.Unit * Dodge.FallbackRadius + Vector3.new(0, Stand.Position.Y - Center.Y, 0), Center)
            Dodge.Until = os.clock() + Dodge.Fallback
            return true
        end
    end

    if os.clock() < Dodge.Until and Dodge.Spot then return true end
    if Dodge.Spot then Dodge.Finish() end
    return false
end

---- ============ Auto Skill ============ ----
--
-- ปุ่มสกิลของเกม = PlayerScripts.Manager.PlrManager.TryUseSkill(ช่อง) (require จาก executor ไม่ได้ - ดึง closure จาก getgc)
-- ช่อง = ลำดับใน SkillList ของอาวุธที่ใส่ (GetItemData(uuid).SkillList[i].ID เช่น K_Skill_11)
-- คูลดาวน์ = attr ผู้เล่น "<ช่อง>_SkillNextTick" เทียบ workspace:GetServerTimeNow() (วัดสด: ใช้แล้ว +6 วิ)

local Skill = { Use = nil, SearchedAt = 0 }

function Skill.Find()
    if Skill.Use then return Skill.Use end
    if os.clock() - Skill.SearchedAt < 10 or typeof(getgc) ~= "function" then return nil end
    Skill.SearchedAt = os.clock()
    for _, Function in ipairs(getgc()) do
        if type(Function) == "function" and islclosure(Function) then
            local Ok, Info = pcall(debug.getinfo, Function)
            if Ok and Info and Info.name == "TryUseSkill" and tostring(Info.source):find("PlrManager") then
                Skill.Use = Function
                break
            end
        end
    end
    return Skill.Use
end

function Skill.Count()
    local Ok, Count = pcall(function()
        local Backpack = Enhant.Backpack()
        local Item = Backpack.GetItemData(Backpack.GetData().equiped.Weapon) or { }
        return #(Item.SkillList or { })
    end)
    return Ok and Count or 0
end

-- ใช้สกิลช่องแรกที่คูลดาวน์หมดแล้ว (เรียกทุกรอบของลูปตี) คืน true = กดไปแล้ว
function Skill.Cast()
    local Use = Skill.Find()
    if not Use then return false end
    local Now = workspace:GetServerTimeNow()
    for Index = 1, Skill.Count() do
        if (tonumber(LocalPlayer:GetAttribute(Index .. "_SkillNextTick")) or 0) <= Now then
            pcall(Use, Index)
            return true
        end
    end
    return false
end

-- Frostbound Tower ประกาศไว้ก่อน Auto Stage - ฟังก์ชันอยู่ท้ายส่วน Auto Stage
local Tower = { Running = false, Status = nil, Max = 30, Target = nil, Entering = false, RetryAt = 0, Fought = nil, Arena = nil }

---- ============ Auto Stage ============ ----
--
-- 27 ด่านเรียงต่อกันตามแกน -Z (workspace.WorldModel.StageMap.EnemyPoint.Stage_<n> = จุดเกิดมอน)
-- เดินเข้า AreaPart ของด่าน = StageManager (PlayerScripts - require ไม่ได้ เข้าถึงผ่าน listener ของ ExitFightBE)
-- ตั้ง StageID แล้วสร้างมอนใน workspace.EnemyFolder (HPValue) / ตี = Remote.Attack.ATKOnceBE:Fire() (ตัวเดียวกับ
-- Auto Click ของเกม) / เคลียร์ด่าน = เกมยิง StageFinishedRF เอง แล้วแร่ตกใน workspace.OreCache (ProximityPrompt "Collect")
-- ด่านถัดไปเปิดเมื่อเคลียร์ด่านก่อนหน้าในรอบนั้น (state.IsCanInto) - กลับ Lobby = รีเซ็ตกลับไปด่าน 1
-- มอนเกิดใหม่ 30 วิ (state.RebirthTick เทียบ workspace:GetAttribute("ServerTime"))
-- แร่ที่ถืออยู่ (OrePack, จุ 4 เริ่มต้น) หายถ้าตาย - ฝากด้วย Remote.Stage.ClaimedAllOreRE:FireServer() (ทำในด่านได้)
-- แล้วรีเซ็ตตัวนับฝั่ง client LeftInfoGUI.UpdateOrePack(0) (ExitFightBE ของปุ่ม Return ไม่ยิง Claimed ให้ - วัดจริง)
-- Damage = CalculateUtils.CCPlrOnceDamage(LocalPlayer) (ค่าเดียวกับ "Damage:" บน HUD) เทียบ RecommendConfig

local Stage = { Running = false, Status = nil, Banked = 0, Max = 27, Module = nil, MinHeight = 7, Paused = false,
    EmptySince = nil, StuckAfter = 10, MoveTries = 0 }

Stage.Recommend = { }
pcall(function()
    local Config = require(ReplicatedStorage.Config.Stage.RecommendConfig)
    if type(Config) == "table" then Stage.Recommend = Config end
end)

function Stage.Need(Number)
    local Entry = Stage.Recommend["Stage_" .. Number]
    return Entry and tonumber(Entry.Recommend) or math.huge
end

function Stage.Short(Number)
    Number = tonumber(Number) or 0
    local Units = { { 1e18, "Qi" }, { 1e15, "Qa" }, { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
    for _, Unit in ipairs(Units) do
        if Number >= Unit[1] then return string.format("%.2f%s", Number / Unit[1], Unit[2]) end
    end
    return tostring(math.floor(Number))
end

-- StageManager ของเกม (ตารางที่มี ExitFight / StartStage ...) - ผ่าน listener ของ ExitFightBE
function Stage.Manager()
    if Stage.Module then return Stage.Module end
    if typeof(getconnections) ~= "function" then return nil end
    pcall(function()
        for _, Connection in ipairs(getconnections(ReplicatedStorage.Remote.Stage.ExitFightBE.Event)) do
            local Handler = Connection.Function
            local Module = Handler and debug.getupvalues(Handler)[1]
            if type(Module) == "table" and type(rawget(Module, "StartStage")) == "function" then
                Stage.Module = Module
                return
            end
        end
    end)
    return Stage.Module
end

-- สถานะของทุกด่าน { Stage_1 = { IsCanInto, IsFinished, IsWaitRebirth, RebirthTick, EnemyTab ... } }
function Stage.States()
    local Manager = Stage.Manager()
    local Ok, States = pcall(function() return debug.getupvalues(Manager.StartStage)[1] end)
    return Ok and type(States) == "table" and States or { }
end

function Stage.Unlocked(Number)
    if Number <= 1 then return true end
    -- IsCanInto เป็น true แค่ด่านถัดจากที่เคลียร์ล่าสุด - ด่านที่เคลียร์แล้วกลับเป็น nil (วัดสด) เลยนับ IsFinished ด้วย
    local State = Stage.States()["Stage_" .. Number]
    return State ~= nil and (State.IsCanInto == true or State.IsFinished == true)
end

function Stage.Damage()
    local Ok, Value = pcall(function()
        return require(ReplicatedStorage.Utils.CalculateUtils).CCPlrOnceDamage(LocalPlayer)
    end)
    return Ok and tonumber(Value) or 0
end

function Stage.Point(Number)
    local Map = workspace:FindFirstChild("WorldModel")
    Map = Map and Map:FindFirstChild("StageMap")
    local Points = Map and Map:FindFirstChild("EnemyPoint")
    local Point = Points and Points:FindFirstChild("Stage_" .. Number)
    return Point and Point:GetPivot().Position or nil
end

function Stage.Pack()
    local Ok, Count, Max = pcall(function()
        return require(ReplicatedStorage.GuiUtils.LeftInfoGUI).GetOrePack(),
            require(ReplicatedStorage.LocalData.UpgradeData).GetMaxNum("OrePack")
    end)
    if Ok then return tonumber(Count) or 0, tonumber(Max) or 4 end
    return 0, 4
end

function Stage.HealthPercent()
    local Ok, Current, Max = pcall(function()
        local HP = require(ReplicatedStorage.CTRL.HPCTRL)
        return HP.GetCurrentHP(LocalPlayer), HP.GetMaxHP(LocalPlayer)
    end)
    if Ok and tonumber(Current) and tonumber(Max) and Max > 0 then return Current / Max * 100 end
    return 100
end

-- ฝากแร่ที่ถือ (ทำได้ทั้งในด่านและ Lobby) แล้วรีเซ็ตตัวนับฝั่ง client ไม่งั้นเกมขึ้น "Pack is full." ทั้งที่ว่าง
function Stage.Bank()
    local Count = Stage.Pack()
    if Count <= 0 then return end
    pcall(function() ReplicatedStorage.Remote.Stage.ClaimedAllOreRE:FireServer() end)
    pcall(function() require(ReplicatedStorage.GuiUtils.LeftInfoGUI).UpdateOrePack(0) end)
    Stage.Banked = Stage.Banked + Count
end

function Stage.Return()
    pcall(function() ReplicatedStorage.Remote.Stage.ExitFightBE:Fire() end)
end

function Stage.SetTarget(Target)
    local Config = getgenv().ConfigurationTable
    if Target == Config.StageTarget then return end
    Config.StageTarget = Target
    local Set = Library.SetFlags and Library.SetFlags.LTFStageTarget
    if Set then pcall(Set, Target) else SaveConfiguration() end
end

-- ด่านสูงสุดที่ Damage ถึง Recommend (RecommendConfig เรียงจากน้อยไปมากทุกด่าน - วัดสด)
function Stage.Best()
    local Damage = Stage.Damage()
    local Best = 1
    while Best < Stage.Max and Damage >= Stage.Need(Best + 1) do Best = Best + 1 end
    return Best
end

-- ด่านที่อยากอยู่:
-- Auto Best = ด่านสูงสุดที่ Damage ถึง Recommend ตามที่หน้า Stage ของเกมแนะนำ (ขึ้นและลงตาม Damage)
-- Auto Next = ไล่ขึ้นตราบที่ Damage ถึง Recommend ของด่านถัดไป (ไม่ลด)
function Stage.Desired()
    local Config = getgenv().ConfigurationTable
    local Target = math.clamp(tonumber(Config.StageTarget) or 1, 1, Stage.Max)
    if Config.StageAutoBest then
        Target = Stage.Best()
        Stage.SetTarget(Target)
    elseif Config.StageAutoNext then
        local Damage = Stage.Damage()
        while Target < Stage.Max and Damage >= Stage.Need(Target + 1) do Target = Target + 1 end
        Stage.SetTarget(Target)
    end
    return Target
end

-- ด่านที่จะสู้ตอนนี้: ด่านสูงสุดที่เปิดแล้วแต่ไม่เกินเป้า (ต่ำกว่าเป้า = ไล่เคลียร์ขึ้นไปก่อน)
-- เพิ่งเลือดต่ำจนต้องกลับที่ด่านไหน = พักด่านนั้น ฟาร์มด่านก่อนหน้าแทน แล้วลองใหม่เมื่อครบ FailCooldown วิ
-- หรือ Damage โตขึ้น FailGrowth เท่าจากตอนแพ้ (ผู้ใช้ 2026-10-02: พัก 5 นาทีนานไป Damage ขึ้นแล้วไม่ไปต่อ)
Stage.FailCooldown = 90
Stage.FailGrowth = 1.25

-- Damage ถึง Recommend ของด่านนั้นแล้ว = แพ้เพราะจังหวะ (โดนรุมตอนลงด่าน ฯลฯ) ไม่ใช่ด่านเกินกำลัง - ไม่พัก
function Stage.Resting(Fail)
    if not Fail or os.clock() - Fail.At >= Stage.FailCooldown then return false end
    local Damage = Stage.Damage()
    return Damage < Stage.Need(Fail.Number) and Damage < (Fail.Damage or 0) * Stage.FailGrowth
end

function Stage.Fight(Desired)
    local Fail = Stage.Fail
    if Stage.Resting(Fail) and Desired >= Fail.Number then
        Desired = math.max(Fail.Number - 1, 1)
    end
    local Current = 1
    for Number = 2, Desired do
        if Stage.Unlocked(Number) then Current = Number else break end
    end
    return Current
end

function Stage.Enemies(Center)
    local List = { }
    local Folder = workspace:FindFirstChild("EnemyFolder")
    if not (Folder and Center) then return List end
    for _, Enemy in ipairs(Folder:GetChildren()) do
        local HP = Enemy:FindFirstChild("HPValue")
        local Ok, Position = pcall(function() return Enemy:GetPivot().Position end)
        if HP and HP.Value > 0 and Ok and (Position - Center).Magnitude < 90 then
            table.insert(List, { Model = Enemy, Position = Position })
        end
    end
    return List
end

function Stage.Ores(Center)
    local List = { }
    local Folder = workspace:FindFirstChild("OreCache")
    if not (Folder and Center) then return List end
    for _, Ore in ipairs(Folder:GetChildren()) do
        local Prompt = Ore:FindFirstChildWhichIsA("ProximityPrompt", true)
        local Ok, Position = pcall(function() return Ore:GetPivot().Position end)
        if Prompt and Prompt.Enabled and Ok and (Position - Center).Magnitude < 130 then
            table.insert(List, { Prompt = Prompt, Position = Position })
        end
    end
    return List
end

function Stage.Set(Key, Value)
    if Stage.Status then Stage.Status:Set(Key, Value) end
end

function Stage.Show(Number, Desired)
    local Count, Max = Stage.Pack()
    local Fail = Stage.Fail
    local Capped = Stage.Resting(Fail) and Number and Number < Desired and Fail.Number <= Desired
    Stage.Set("Stage", Number and (Capped and string.format("%d / target %d (stage %d too strong, retry in %ds)", Number, Desired,
        Fail.Number, math.ceil(Stage.FailCooldown - (os.clock() - Fail.At))) or string.format("%d / target %d", Number, Desired)) or nil)
    Stage.Set("Damage", string.format("%s (next needs %s)", Stage.Short(Stage.Damage()),
        Desired and Desired < Stage.Max and Stage.Short(Stage.Need(Desired + 1)) or "-"))
    Stage.Set("Ores", string.format("%d/%d carried, %d banked", Count, Max, Stage.Banked))
end

-- จุดตี Air (บังคับ): ลอยตรงเหนือมอน Farm Distance studs หันลงหามอน - ไม่ลงพื้นตลอดการฟาร์ม
-- เหตุผล (วัดสด): AI มอน (BT node MoveToPlayer) เทียบ (pivot เรา - pivot มอน).Magnitude แบบ 3D กับ MinDistance ของท่า
--   ท่าตีธรรมดา (*_ATK) ไม่มี MinDistance = ใช้ 6 / Boss S1: 8-10, Boss_5/6_S1 50, Boss_3_S1 999 (Auto Dodge จัดการ)
--   ลอยสูง > 6 ตรงหัว = มอนเดินวนอยู่ใต้ตัวแต่ไม่เคยเข้าเงื่อนไขตี (มอนเดินแค่แนวราบ ระยะแนวตั้งไม่ลด)
-- กล่องท่าตีเรา (DamageUtils.TryGetTouchConfig) หมุนตามทิศมอง - มองลงตรง ๆ = ยื่นลงล่าง:
--   Great ATK_1/2 Ball Ø23 กลาง 5 = ถึง 16.5 / Katana ATK ลึก 12-15 กลาง 5-7 = ถึง ~11-14.5 (เลยตั้งได้ไม่เกิน 14)
function Stage.Height()
    return math.max(tonumber(getgenv().ConfigurationTable.StageFarmDistance) or 10, Stage.MinHeight)
end

function Stage.Stand(Target)
    if not (Target and Target.Parent) then return nil end
    local Mob = Target:GetPivot()
    local Look = Mob.LookVector * Vector3.new(1, 0, 1)
    if Look.Magnitude < 0.1 then Look = Vector3.new(0, 0, -1) end
    return CFrame.lookAt(Mob.Position + Vector3.new(0, Stage.Height(), 0), Mob.Position, Look.Unit)
end

-- ลอยค้างที่จุดนี้ + ความสูงฟาร์ม (รอมอนเกิด / ระหว่างย้ายด่าน) - ไม่ปล่อยให้ตกลงพื้นไปให้มอนตี
function Stage.Hover(Point)
    Movement.Lock(CFrame.new(Point + Vector3.new(0, Stage.Height(), 0)))
end

-- เก็บแร่ (ไม่มีมอนแล้ว): ลอยเหนือแร่ 4 studs ทีละก้อน แพ็กเต็มฝากก่อน
function Stage.Collect(Ores, Running)
    for _, Ore in ipairs(Ores) do
        if not Running() then break end
        local Count, Max = Stage.Pack()
        if Count >= Max then Stage.Bank() end
        Movement.Lock(CFrame.new(Ore.Position + Vector3.new(0, 4, 0)))
        task.wait(0.3)
        pcall(fireproximityprompt, Ore.Prompt)
        task.wait(0.35)
    end
end

function Stage.Step()
    local Config = getgenv().ConfigurationTable
    local Root = Train.Root()
    if not Root or not Stage.Manager() then
        Stage.Status:SetState("Waiting")
        Stage.Set("State", Stage.Manager() and "Waiting for character" or "Executor has no getconnections")
        task.wait(1)
        return
    end

    -- ระบบที่สำคัญกว่ามีงาน (หน้า Priority) = พัก - แต่ตีตัวที่ล็อกอยู่ให้ตายก่อน (สลับระหว่างตัว แบบ Slayer2)
    -- ยกเว้นตัวที่ไม่รอ (Tower อยู่ในหอแล้ว / Forge กำลังตีของ) = พักทันที
    local Turn, Owner = Runner.Turn("Stage")
    local Holding = Stage.Target and Stage.Target.Parent and (function()
        local HP = Stage.Target:FindFirstChild("HPValue")
        return HP and HP.Value > 0
    end)()
    if not Turn and not (Holding and not Runner.Committed()) then
        Stage.Target = nil
        -- ปล่อยตัวครั้งเดียวตอนเริ่มพัก (ไม่งั้นจุดลอยของ Stage ตรึงตัวไว้ ตอนเกมวาร์ปเข้าหอ / ไปโต๊ะ Forge)
        -- หลังจากนั้นห้ามแตะ Movement - ระบบที่ได้ตาใช้อยู่
        if not Stage.Paused then
            Stage.Paused = true
            Dodge.Finish()
            Movement.Release()
        end
        Stage.EmptySince = nil
        Stage.Status:SetState("Waiting")
        Stage.Set("State", "Paused - " .. Runner.Label(Owner) .. " first")
        task.wait(1)
        return
    end

    Stage.Paused = false

    local Desired = Stage.Desired()
    local Number = Stage.Fight(Desired)
    local Center = Stage.Point(Number)
    Stage.Show(Number, Desired)

    -- เลือดต่ำ: ฝากแร่ก่อน แล้วกลับ Lobby (เกมเติมเลือดเต็มตอนกลับ) - รอบหน้าไล่ด่านใหม่จาก 1
    if Config.StageBankOres and LocalPlayer:GetAttribute("IntoFight") and not Tower.Inside()
        and Stage.HealthPercent() <= (tonumber(Config.StageReturnHP) or 35) then
        local Current = tonumber(tostring(LocalPlayer:GetAttribute("StageID") or ""):match("%d+"))
        if Current then Stage.Fail = { Number = Current, At = os.clock(), Damage = Stage.Damage() } end
        Stage.Target = nil
        Dodge.Finish()
        Movement.Release()
        Stage.Bank()
        Stage.Return()
        Stage.Status:SetState("Waiting")
        Stage.Set("State", "Low HP - banked ores and returned")
        task.wait(2)
        return
    end

    -- Auto Best: อยู่ด่านที่ Damage ไม่ถึง Recommend = ฝากแร่ กลับ Lobby แล้วไล่ฟาร์มใหม่ถึงด่านที่ถึง
    -- รอให้เกินต่อเนื่อง 3 วิก่อน กัน Damage ตกชั่วคราว (เปลี่ยนอาวุธ ฯลฯ) แล้วโดนรีเซ็ตด่านเหลือ 1 ฟรี ๆ
    local Current = tonumber(tostring(LocalPlayer:GetAttribute("StageID") or ""):match("%d+"))
    if Config.StageAutoBest and Current and Current > Desired and LocalPlayer:GetAttribute("IntoFight") and not Tower.Inside() then
        Stage.PastBest = Stage.PastBest or os.clock()
        if os.clock() - Stage.PastBest >= 3 then
            Stage.PastBest = nil
            Stage.Target = nil
            Dodge.Finish()
            Movement.Release()
            Stage.Bank()
            Stage.Return()
            Stage.Status:SetState("Waiting")
            Stage.Set("State", "Damage below stage " .. Current .. " Recommend - returned to farm again")
            task.wait(2)
            return
        end
    else
        Stage.PastBest = nil
    end

    if not Center then
        Stage.Set("State", "Stage point not found")
        task.wait(1)
        return
    end

    if LocalPlayer:GetAttribute("StageID") ~= "Stage_" .. Number then
        Stage.Target = nil
        Stage.Status:SetState("Running")
        Stage.Set("State", "Moving to stage " .. Number)
        -- ลอยเข้าฝั่งทางเข้า (+Z) ห่างจุดเกิดมอน 30 studs สูงเท่าความสูงฟาร์ม - ยังอยู่ใน AreaPart
        -- (สูง 47 กลาง y18 = ครอบ y -5..41, จุดเกิด y6) Touched ยังทำงาน / ลงกลางจุดเกิดบนพื้น
        -- = มอนทั้งด่านตีพร้อมกันก่อนตรึงตำแหน่งทัน (วัดสด ด่าน 7: -58 HP ทันทีที่ถึง)
        -- ลอยค้างนานแล้วเกมยังไม่นับว่าเข้าด่าน (Touched ไม่ทำงาน) = ลงพื้นจุดเดิมให้ชน AreaPart จริง
        Stage.MoveTries = (Stage.MoveTries or 0) + 1
        if Stage.MoveTries % 6 == 0 then
            Movement.Teleport(CFrame.new(Center + Vector3.new(0, 3, 30)))
            Stage.Set("State", "Moving to stage " .. Number .. " (on foot)")
        else
            Stage.Hover(Center + Vector3.new(0, 0, 30))
        end
        task.wait(1)
        return
    end
    Stage.MoveTries = 0

    local Enemies = Stage.Enemies(Center)
    if #Enemies > 0 then
        Stage.EmptySince = nil
        -- เกาะเป้าเดิมจนตาย (แบบ Slayer2) - ไม่สลับเป้าทุกเฟรมตามระยะ
        local Target = Stage.Target
        local Alive = false
        for _, Enemy in ipairs(Enemies) do
            if Enemy.Model == Target then Alive = true break end
        end
        if not Alive then
            local Distance = math.huge
            for _, Enemy in ipairs(Enemies) do
                local Gap = (Enemy.Position - Root.Position).Magnitude
                if Gap < Distance then Target, Distance = Enemy.Model, Gap end
            end
            Stage.Target = Target
            Movement.Lock(function() return Stage.Stand(Target) end)
        end

        -- ตีต่อแม้ระหว่างหลบ (จุดหลบวงใน 6-10 studs ยังอยู่ในระยะท่าตีเรา ~11)
        if Config.StageAutoSkill then Skill.Cast() end
        pcall(function() ReplicatedStorage.Remote.Attack.ATKOnceBE:Fire() end)
        Stage.Status:SetState("Running")
        local Ok, Mob = pcall(function() return Target:GetPivot().Position end)
        if Dodge.Update(Stage.Stand(Target), Ok and Mob or nil, Enemies) then
            Stage.Set("State", string.format("Dodging (%d left)", #Enemies))
            task.wait(0.05)
            return
        end

        Stage.Set("State", string.format("Fighting (%d left)", #Enemies))
        task.wait(0.1)
        return
    end

    Stage.Target = nil
    Dodge.Finish()
    Dodge.LastHP = nil
    Stage.Hover(Center)

    -- ด่านเคลียร์แล้ว: เก็บแร่ (แพ็กเต็มฝากก่อน) แล้วลอยรอมอนเกิดใหม่เหนือจุดเกิด
    local Ores = Stage.Ores(Center)
    if #Ores > 0 then
        Stage.Status:SetState("Running")
        Stage.Set("State", string.format("Collecting ores (%d)", #Ores))
        Stage.Collect(Ores, function() return Stage.Running end)
        Stage.Hover(Center)
        Stage.Show(Number, Desired)
        return
    end

    local State = Stage.States()["Stage_" .. Number] or { }
    local Left = (tonumber(State.RebirthTick) or 0) - (tonumber(workspace:GetAttribute("ServerTime")) or 0)

    -- Auto Best: เคลียร์ด่านสูงสุดที่ Damage ถึงแล้ว (ด่านถัดไปไม่ไหว) = กด Back ทันที ไม่รอมอนเกิดใหม่
    -- เกมรีเซ็ตด่านทั้งหมดตอนกลับ เลยวนไล่เคลียร์ 1 -> ด่านสูงสุดใหม่เป็น loop (ผู้ใช้ 2026-10-02)
    if Config.StageAutoBest and Number >= Desired and (State.IsFinished == true or Left > 0) then
        Stage.Bank()
        Stage.Return()
        Stage.Status:SetState("Running")
        Stage.Set("State", "Cleared stage " .. Number .. " - back to restart the loop")
        task.wait(2)
        return
    end

    -- อยู่ในด่านแต่ไม่มีมอน และไม่ได้นับถอยหลังเกิดใหม่ = ด่านค้าง (มอนไม่เกิด) นาน StuckAfter วิ
    -- = ฝากแร่ กด Back แล้วเริ่มไล่ด่านใหม่ (ผู้ใช้ 2026-10-02: เปิดหลายระบบแล้ว Stage บัค มอนไม่เกิด ต้อง back)
    if Left > 0 then
        Stage.EmptySince = nil
    else
        Stage.EmptySince = Stage.EmptySince or os.clock()
        if os.clock() - Stage.EmptySince >= Stage.StuckAfter then
            Stage.EmptySince = nil
            Stage.Target = nil
            Dodge.Finish()
            Movement.Release()
            Stage.Bank()
            Stage.Return()
            Stage.Status:SetState("Running")
            Stage.Set("State", "No enemies in stage " .. Number .. " - back to restart")
            task.wait(2)
            return
        end
    end

    Stage.Status:SetState("Waiting")
    Stage.Set("State", Left > 0 and string.format("Waiting for respawn (%ds)", math.ceil(Left))
        or string.format("Waiting for enemies (%ds)", math.floor(os.clock() - (Stage.EmptySince or os.clock()))))
    task.wait(0.5)
end

function Stage.Start()
    if Stage.Running then return end
    Stage.Running = true

    local Token = SessionToken
    task.spawn(function()
        while Stage.Running and getgenv().ValkyrieSession == Token do
            local Ok, Error = pcall(Stage.Step)
            if not Ok then
                Stage.Set("State", "Error: " .. tostring(Error))
                task.wait(1)
            end
        end
    end)
end

function Stage.Stop()
    if Stage.Running and getgenv().ConfigurationTable.StageBankOres then pcall(Stage.Bank) end
    Stage.Running = false
    Stage.Target = nil
    pcall(Dodge.Finish)
    pcall(Movement.Release)
    if Stage.Status then
        Stage.Status:SetState("Idle")
        Stage.Set("State", nil)
    end
end

local StagePage = Window:Page({ Name = "Auto Stage", Icon = "target", Columns = 2 })

local StageMainSection = StagePage:Section({
    Name = "Auto Stage",
    Side = 1
})

local StageInfoSection = StagePage:Section({
    Name = "Status",
    Side = 2
})

Stage.Status = StageInfoSection:Status({
    Name = "Stage Status",
    Rows = { "State", "Stage", "Damage", "Ores" }
})

StageMainSection:Slider({
    Name = "Target Stage",
    Description = "Stage to farm - lower stages are cleared on the way",
    Flag = "LTFStageTarget",
    Min = 1,
    Max = Stage.Max,
    Default = getgenv().ConfigurationTable.StageTarget,
    Callback = function(Value)
        getgenv().ConfigurationTable.StageTarget = Value
        SaveConfiguration()
    end
})

StageMainSection:Toggle({
    Name = "Auto Best Stage",
    Description = "Target Stage follows the highest stage your Damage meets the Recommend for - after clearing it, go back and loop from stage 1",
    Flag = "LTFStageAutoBest",
    Default = getgenv().ConfigurationTable.StageAutoBest,
    Callback = function(Value)
        getgenv().ConfigurationTable.StageAutoBest = Value
        SaveConfiguration()
    end
})

StageMainSection:Label("Method: Air (forced) - stays above enemy reach")

-- config เก่า (Above 3-9, ค่าเดิม 6) ต่ำกว่าความสูงขั้นต่ำของ Air = ย้ายเป็นค่าใหม่
if (tonumber(getgenv().ConfigurationTable.StageFarmDistance) or 0) < Stage.MinHeight then
    getgenv().ConfigurationTable.StageFarmDistance = 10
end

StageMainSection:Slider({
    Name = "Farm Distance",
    Description = "Studs above the enemy - enemies only swing at you within 6 studs",
    Flag = "LTFStageFarmDistance",
    Min = Stage.MinHeight,
    Max = 14,
    Default = getgenv().ConfigurationTable.StageFarmDistance,
    Callback = function(Value)
        getgenv().ConfigurationTable.StageFarmDistance = Value
        SaveConfiguration()
    end
})

StageMainSection:Toggle({
    Name = "Auto Dodge",
    Description = "Step out of an enemy skill's real hitbox while it plays, then come back",
    Flag = "LTFStageAutoDodge",
    Default = getgenv().ConfigurationTable.StageAutoDodge,
    Callback = function(Value)
        getgenv().ConfigurationTable.StageAutoDodge = Value
        SaveConfiguration()
        if not Value then pcall(Dodge.Finish) end
    end
})

StageMainSection:Toggle({
    Name = "Auto Skill",
    Description = "Use your weapon skills whenever they are off cooldown while fighting",
    Flag = "LTFStageAutoSkill",
    Default = getgenv().ConfigurationTable.StageAutoSkill,
    Callback = function(Value)
        getgenv().ConfigurationTable.StageAutoSkill = Value
        SaveConfiguration()
    end
})

StageMainSection:Toggle({
    Name = "Auto Next Stage",
    Description = "Raise Target Stage when your Damage reaches the next stage's Recommend",
    Flag = "LTFStageAutoNext",
    Default = getgenv().ConfigurationTable.StageAutoNext,
    Callback = function(Value)
        getgenv().ConfigurationTable.StageAutoNext = Value
        SaveConfiguration()
    end
})

StageMainSection:Toggle({
    Name = "Bank Ores on Return",
    Description = "Bank carried ores and return to the lobby before you die",
    Flag = "LTFStageBankOres",
    Default = getgenv().ConfigurationTable.StageBankOres,
    Callback = function(Value)
        getgenv().ConfigurationTable.StageBankOres = Value
        SaveConfiguration()
    end
})

StageMainSection:Slider({
    Name = "Return At HP",
    Flag = "LTFStageReturnHP",
    Min = 10,
    Max = 90,
    Suffix = "%",
    Default = getgenv().ConfigurationTable.StageReturnHP,
    Callback = function(Value)
        getgenv().ConfigurationTable.StageReturnHP = Value
        SaveConfiguration()
    end
})

StageMainSection:Toggle({
    Name = "Auto Stage",
    Flag = "LTFAutoStage",
    Default = getgenv().ConfigurationTable.AutoStage,
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoStage = Value
        SaveConfiguration()

        if Value then Stage.Start() else Stage.Stop() end
    end
})

StageInfoSection:Guide("How to use", {
    "Set Target Stage, then turn on Auto Stage: it clears each stage up to the target and keeps farming it",
    "Ores are picked up after each clear and banked whenever the ore pack is full",
    "Bank Ores on Return: below Return At HP it banks the ores and goes back to the lobby (stages restart from 1)",
    "With Auto Train / Forge / Tower also on, the Priority tab decides who goes first",
    "No enemies for 10 seconds inside a stage = it presses Back and starts over",
})

task.spawn(function()
    local Token = SessionToken
    while getgenv().ValkyrieSession == Token do
        if not Stage.Running then pcall(Stage.Show, nil, Stage.Desired()) end
        task.wait(3)
    end
end)

---- ============ Frostbound Tower ============ ----
--
-- ระบบ Dungeon ของเกม (ชื่อที่ผู้เล่นเห็น = "Frostbound Tower") 30 Round - LocalData.DungeonData:
--   TryIntoDungeon(round) -> TryIntoDungeonRF (ใช้ Tower Ticket 1 ใบ = Material "Dungeon_Ticket")
--   เริ่มได้ที่ Round 1 ถึง GetMaxRound() + 1 (CheckCanUnlock) / TryClaimDailyDunTic() = ตั๋วฟรีรายวัน (วัดสด +2 ใบ)
--   CheckTodayClaimed() / ExitDungeon() = ออกจาก Tower
-- เข้าแล้ว DungeonManager ของเกมเดิน Round เอง (StartRound -> สร้างมอน -> CompleteRound -> Round ถัดไป)
-- attr ผู้เล่น: Dungeoning = อยู่ใน Tower, CurrentRound, Dead (ตาย = จอ Revive / Give up -> DungeonGiveUpBE:Fire())
-- มอนอยู่ใน workspace.EnemyFolder (HPValue) ตีด้วย ATKOnceBE เหมือน Stage (วัดสด Round 1 ไม่ตี = ตายใน ~20 วิ)

function Tower.Data()
    local Ok, Module = pcall(function() return require(ReplicatedStorage.LocalData.DungeonData) end)
    return Ok and type(Module) == "table" and Module or nil
end

function Tower.Highest()
    local Ok, Value = pcall(function() return Tower.Data().GetMaxRound() end)
    return Ok and tonumber(Value) or 0
end

function Tower.Tickets()
    return Enhant.Count("Dungeon_Ticket")
end

-- อยู่ในหอไหม: เดิมเกมตั้ง attr Dungeoning = true (วัดสด 2026-10-02) - อัปเดตเกม 2026-10-03 ไม่มีแล้ว
-- เหลือ IntoFight = "Dungeon" (วัดสด ระหว่าง Round 2) / StageID = -1 ใช้ไม่ได้ - ค้างอยู่หลังออกจากหอ (วัดสด)
function Tower.Inside()
    return LocalPlayer:GetAttribute("Dungeoning") == true or LocalPlayer:GetAttribute("IntoFight") == "Dungeon"
end

-- Round ที่จะเริ่ม: ตามที่ตั้ง แต่ไม่เกิน Highest + 1 (เกมไม่ให้ข้าม)
function Tower.StartRound()
    local Start = tonumber(getgenv().ConfigurationTable.TowerStartRound) or 1
    return math.clamp(Start, 1, math.min(Tower.Highest() + 1, Tower.Max))
end

-- มีงานให้ Tower ไหม (หน้า Priority): อยู่ในหอ / กำลังเข้า / มีตั๋วและไม่ติดพักหลังเข้าไม่สำเร็จ
function Tower.Ready()
    if Tower.Inside() or Tower.Entering then return true end
    return Tower.Tickets() > 0 and os.clock() >= (Tower.RetryAt or 0)
end

-- กลางลานหอ = ค่าเฉลี่ยจุดเกิดมอน WorldModel.DungeonMap.EnemyPoint (วัดสด ~(3482, 24, 100), จุดเริ่ม StartPoint ห่าง ~104)
function Tower.Center()
    if Tower.Arena then return Tower.Arena end
    local Ok, Center = pcall(function()
        local Sum, Count = Vector3.zero, 0
        for _, Point in ipairs(workspace.WorldModel.DungeonMap.EnemyPoint:GetChildren()) do
            Sum, Count = Sum + Point:GetPivot().Position, Count + 1
        end
        return Count > 0 and Sum / Count or nil
    end)
    Tower.Arena = Ok and Center or nil
    return Tower.Arena
end

-- มอนในหอเท่านั้น: มอนของ Stage ที่เคยเข้าค้างอยู่ใน EnemyFolder ด้วย (ไม่มี attr แยก) - ไม่กรองตามระยะ
-- = ล็อกเป้ามอน Stage แล้วลากตัวออกจากหอ (วัดสด)
function Tower.Enemies()
    local List = { }
    local Folder = workspace:FindFirstChild("EnemyFolder")
    local Center = Tower.Center()
    if not (Folder and Center) then return List end
    for _, Enemy in ipairs(Folder:GetChildren()) do
        local HP = Enemy:FindFirstChild("HPValue")
        local Ok, Position = pcall(function() return Enemy:GetPivot().Position end)
        if HP and HP.Value > 0 and Ok and (Position - Center).Magnitude < 250 then
            table.insert(List, { Model = Enemy, Position = Position })
        end
    end
    return List
end

function Tower.Set(Key, Value)
    if Tower.Status then Tower.Status:Set(Key, Value) end
end

function Tower.Show()
    local Config = getgenv().ConfigurationTable
    local Round = Tower.Inside() and tonumber(LocalPlayer:GetAttribute("CurrentRound")) or nil
    Tower.Set("Round", Round and string.format("%d (start %d / stop %d)", Round, Tower.StartRound(),
        tonumber(Config.TowerStopRound) or Tower.Max) or string.format("start %d / stop %d", Tower.StartRound(),
        tonumber(Config.TowerStopRound) or Tower.Max))
    Tower.Set("Highest", tostring(Tower.Highest()) .. " / " .. Tower.Max)
    local Claimed = false
    pcall(function() Claimed = Tower.Data().CheckTodayClaimed() end)
    Tower.Set("Tickets", string.format("%d (daily %s)", Tower.Tickets(), Claimed and "claimed" or "ready"))
end

function Tower.ClaimDaily()
    local Data = Tower.Data()
    local Ok, Claimed = pcall(function() return Data.CheckTodayClaimed() end)
    if Ok and Claimed == false then
        pcall(function() Data.TryClaimDailyDunTic() end)
        return true
    end
    return false
end

function Tower.Leave()
    Tower.Target = nil
    pcall(Dodge.Finish)
    pcall(Movement.Release)
    pcall(Stage.Bank)
    pcall(function() Tower.Data().ExitDungeon() end)
end

function Tower.Step()
    local Config = getgenv().ConfigurationTable
    Tower.Show()

    if Config.TowerClaimDaily and Tower.ClaimDaily() then
        Tower.Set("State", "Claimed the daily Tower Ticket")
        task.wait(1.5)
        return
    end

    if not Config.TowerAutoEnter then
        Tower.Status:SetState("Idle")
        Tower.Set("State", "Auto Enter Tower is off")
        task.wait(2)
        return
    end

    if not Tower.Inside() then
        -- เพิ่งออกจากหอ: ตายหรือไม่ได้ตีสักตัว = รอบเสีย / เสีย 2 รอบติด = ปิด Auto Enter กันตั๋วหมดฟรี
        -- (วัดสด: บั๊กลากตัวออกจากหอ -> หอปิดเอง -> เข้าใหม่วน ตั๋วหมด 3 ใบ)
        if Tower.WasInside then
            Tower.WasInside = false
            -- หอจบเอง (ครบ Round / หมดเวลา) ไม่ผ่าน Tower.Leave = จุดลอยเหนือลานยังตรึงตัวอยู่
            pcall(Dodge.Finish)
            pcall(Movement.Release)
            if Tower.Died or not Tower.Fought then
                Tower.Fails = (Tower.Fails or 0) + 1
            else
                Tower.Fails = 0
            end
            Tower.Died = false
            if Tower.Fails >= 2 then
                Tower.Fails = 0
                Library:Notify("Frostbound Tower", "Two runs in a row failed - Auto Enter Tower turned off. Lower Start Round.", 8)
                if Library.SetFlags.LTFTowerAutoEnter then pcall(Library.SetFlags.LTFTowerAutoEnter, false) end
                return
            end
        end
        Tower.Target = nil
        Tower.Fought = nil
        Tower.ClearedAt = nil
        Tower.LastRound = nil
        if Tower.Tickets() <= 0 then
            Tower.Status:SetState("Waiting")
            Tower.Set("State", "No Tower Ticket")
            task.wait(3)
            return
        end
        if os.clock() < (Tower.RetryAt or 0) then
            Tower.Status:SetState("Waiting")
            Tower.Set("State", string.format("Could not enter - retry in %ds", math.ceil(Tower.RetryAt - os.clock())))
            task.wait(1)
            return
        end
        local Turn, Owner = Runner.Turn("Tower")
        if not Turn then
            Tower.Status:SetState("Waiting")
            Tower.Set("State", "Paused - " .. Runner.Label(Owner) .. " first")
            task.wait(1)
            return
        end

        Tower.Entering = true
        -- ปล่อยตัวก่อนเสมอ ให้เกมวาร์ปเข้าหอได้ (จุดลอยค้างของ Stage ตรึงตัวไว้)
        pcall(Dodge.Finish)
        pcall(Movement.Release)
        -- อยู่ใน Stage อยู่ = ฝากแร่แล้วออกก่อน (แร่ที่ยังไม่ฝากหายตอนออก)
        if LocalPlayer:GetAttribute("IntoFight") then
            Stage.Target = nil
            Stage.Bank()
            Stage.Return()
            task.wait(2)
        end

        local Round = Tower.StartRound()
        Tower.Status:SetState("Running")
        Tower.Set("State", "Entering at Round " .. Round)
        local Ok, Result = pcall(function() return Tower.Data().TryIntoDungeon(Round) end)
        local Deadline = os.clock() + 8
        while os.clock() < Deadline and not Tower.Inside() do task.wait(0.25) end
        Tower.Entering = false
        if not Tower.Inside() then
            Tower.RetryAt = os.clock() + 30
            Tower.Set("State", "Could not enter (" .. tostring(Ok and Result or "error") .. ")")
        end
        return
    end

    Tower.WasInside = true

    -- ตาย = Give up (ยังไม่ได้เช็คว่า Revive เสียอะไร)
    if LocalPlayer:GetAttribute("Dead") then
        Tower.Died = true
        Tower.Target = nil
        pcall(Dodge.Finish)
        pcall(Movement.Release)
        Tower.Status:SetState("Waiting")
        Tower.Set("State", "Died - giving up")
        pcall(function() ReplicatedStorage.Remote.Dungeon.DungeonGiveUpBE:Fire() end)
        task.wait(3)
        return
    end

    local Root = Train.Root()
    if not Root then
        Tower.Set("State", "Waiting for character")
        task.wait(0.5)
        return
    end

    local Round = tonumber(LocalPlayer:GetAttribute("CurrentRound")) or 0
    local Stop = math.max(tonumber(Config.TowerStopRound) or Tower.Max, Tower.StartRound())

    -- เลข Round ขึ้น = Round ก่อนหน้าเคลียร์แล้ว (เกมขึ้นเลขทันทีที่เคลียร์ และมอนรอบใหม่เกิดต่อเลย
    -- วัดสด: ไม่มีช่วงว่างให้เช็ค ตั้งหยุด 3 แต่ตีไปถึง 12) = เคลียร์ Round ที่ตั้งหยุดแล้วออกทันที
    if Tower.LastRound and Round > Tower.LastRound and Tower.LastRound >= Stop then
        Tower.Status:SetState("Done")
        Tower.Set("State", "Cleared Round " .. Tower.LastRound .. " - leaving the Tower")
        Tower.Fought = Tower.LastRound
        Tower.LastRound = nil
        Tower.Leave()
        task.wait(3)
        return
    end
    Tower.LastRound = Round

    local Enemies = Tower.Enemies()
    if #Enemies > 0 then
        Tower.Fought = Round
        Tower.ClearedAt = nil
        local Target = Tower.Target
        local Alive = false
        for _, Enemy in ipairs(Enemies) do
            if Enemy.Model == Target then Alive = true break end
        end
        if not Alive then
            local Distance = math.huge
            for _, Enemy in ipairs(Enemies) do
                local Gap = (Enemy.Position - Root.Position).Magnitude
                if Gap < Distance then Target, Distance = Enemy.Model, Gap end
            end
            Tower.Target = Target
            Movement.Lock(function() return Stage.Stand(Target) end)
        end

        if Config.TowerAutoSkill then Skill.Cast() end
        pcall(function() ReplicatedStorage.Remote.Attack.ATKOnceBE:Fire() end)
        Tower.Status:SetState("Running")
        local Ok, Mob = pcall(function() return Target:GetPivot().Position end)
        if Dodge.Update(Stage.Stand(Target), Ok and Mob or nil, Enemies) then
            Tower.Set("State", string.format("Round %d - dodging (%d left)", Round, #Enemies))
            task.wait(0.05)
            return
        end
        Tower.Set("State", string.format("Round %d - fighting (%d left)", Round, #Enemies))
        task.wait(0.1)
        return
    end

    Tower.Target = nil
    Dodge.Finish()
    Dodge.LastHP = nil

    -- Round เคลียร์แล้ว: เก็บแร่ที่ดรอป (แพ็กเต็มฝากก่อน) แล้วลอยรอ Round ถัดไปเหนือลาน
    local Ores = Stage.Ores(Tower.Center())
    if #Ores > 0 then
        Tower.Set("State", string.format("Round %d - collecting ores (%d)", Round, #Ores))
        Stage.Collect(Ores, function() return Tower.Running end)
        Stage.Hover(Tower.Center())
        return
    end
    if Tower.Center() then Stage.Hover(Tower.Center()) end

    -- เคลียร์ Round ที่ตั้งหยุดแล้ว = ออก
    -- CurrentRound ขึ้นเป็นเลข Round ถัดไปทันทีที่เคลียร์ (วัดสด: ตั้งหยุด 2 แต่รอดูมอนรอบ 3 = ตีเกินไป 1 รอบ)
    -- เลยออกตอนเลข Round เกิน Stop / หรือเคลียร์ Round สุดท้ายแล้วมอนไม่มาอีก 8 วิ (เลขไม่ขึ้นต่อ - มอนทยอยเกิด ~5 วิ)
    if Tower.Fought and Tower.Fought >= Stop then
        Tower.ClearedAt = Tower.ClearedAt or os.clock()
    else
        Tower.ClearedAt = nil
    end
    if (Tower.Fought and Round > Tower.Fought and Tower.Fought >= Stop)
        or (Tower.ClearedAt and os.clock() - Tower.ClearedAt >= 8) then
        Tower.ClearedAt = nil
        Tower.Status:SetState("Done")
        Tower.Set("State", "Cleared Round " .. tostring(Tower.Fought) .. " - leaving the Tower")
        Tower.Leave()
        task.wait(3)
        return
    end

    Tower.Status:SetState("Waiting")
    Tower.Set("State", string.format("Round %d - waiting for enemies", Round))
    task.wait(0.25)
end

function Tower.Start()
    if Tower.Running then return end
    Tower.Running = true

    local Token = SessionToken
    task.spawn(function()
        while Tower.Running and getgenv().ValkyrieSession == Token do
            local Ok, Error = pcall(Tower.Step)
            if not Ok then
                Tower.Entering = false
                Tower.Set("State", "Error: " .. tostring(Error))
                task.wait(1)
            end
        end
    end)
end

function Tower.Stop()
    Tower.Running = false
    Tower.Entering = false
    Tower.Target = nil
    pcall(Dodge.Finish)
    pcall(Movement.Release)
    if Tower.Status then
        Tower.Status:SetState("Idle")
        Tower.Set("State", nil)
    end
end

-- ระบบเดียวทำทั้ง Claim และ Enter: เปิดตัวไหนก็วิ่ง ปิดครบทั้งสองค่อยหยุด
function Tower.Refresh()
    local Config = getgenv().ConfigurationTable
    if Config.TowerAutoEnter or Config.TowerClaimDaily then Tower.Start() else Tower.Stop() end
end

local TowerPage = Window:Page({ Name = "Auto Tower", Icon = "mountain-snow", Columns = 2 })

local TowerMainSection = TowerPage:Section({
    Name = "Frostbound Tower",
    Side = 1
})

local TowerInfoSection = TowerPage:Section({
    Name = "Status",
    Side = 2
})

Tower.Status = TowerInfoSection:Status({
    Name = "Tower Status",
    Rows = { "State", "Round", "Highest", "Tickets" }
})

TowerMainSection:Slider({
    Name = "Start Round",
    Description = "Round to start from - capped at your Highest Round + 1",
    Flag = "LTFTowerStartRound",
    Min = 1,
    Max = Tower.Max,
    Default = getgenv().ConfigurationTable.TowerStartRound,
    Callback = function(Value)
        getgenv().ConfigurationTable.TowerStartRound = Value
        SaveConfiguration()
    end
})

TowerMainSection:Slider({
    Name = "Stop at Round",
    Description = "Leave the Tower after clearing this round",
    Flag = "LTFTowerStopRound",
    Min = 1,
    Max = Tower.Max,
    Default = getgenv().ConfigurationTable.TowerStopRound,
    Callback = function(Value)
        getgenv().ConfigurationTable.TowerStopRound = Value
        SaveConfiguration()
    end
})

TowerMainSection:Toggle({
    Name = "Auto Skill",
    Description = "Use your weapon skills whenever they are off cooldown while fighting",
    Flag = "LTFTowerAutoSkill",
    Default = getgenv().ConfigurationTable.TowerAutoSkill,
    Callback = function(Value)
        getgenv().ConfigurationTable.TowerAutoSkill = Value
        SaveConfiguration()
    end
})

TowerMainSection:Toggle({
    Name = "Auto Claim Daily Ticket",
    Description = "Claim the free Tower Ticket once a day",
    Flag = "LTFTowerClaimDaily",
    Default = getgenv().ConfigurationTable.TowerClaimDaily,
    Callback = function(Value)
        getgenv().ConfigurationTable.TowerClaimDaily = Value
        SaveConfiguration()
        Tower.Refresh()
    end
})

TowerMainSection:Toggle({
    Name = "Auto Enter Tower",
    Description = "Spend a Tower Ticket to enter, fight each round, and leave at Stop at Round",
    Flag = "LTFTowerAutoEnter",
    Default = getgenv().ConfigurationTable.TowerAutoEnter,
    Callback = function(Value)
        getgenv().ConfigurationTable.TowerAutoEnter = Value
        SaveConfiguration()
        Tower.Refresh()
    end
})

TowerInfoSection:Guide("How to use", {
    "Set Start Round and Stop at Round, then turn on Auto Enter Tower",
    "Each run spends 1 Tower Ticket - turn on Auto Claim Daily Ticket for the free ones",
    "Fighting uses Auto Stage's Farm Distance and Auto Dodge - the Priority tab decides Tower vs Stage",
    "Dying in the Tower presses Give up",
})

task.spawn(function()
    local Token = SessionToken
    while getgenv().ValkyrieSession == Token do
        if not Tower.Running then pcall(Tower.Show) end
        task.wait(3)
    end
end)

---- ============ Auto Sell ============ ----
--
-- ปุ่มขายของ SellGUI = BackpackData.TrySellItem(uuid, จำนวน) -> Remote.Backpack.TrySellItemRE (วัดสด: ไม่ส่งจำนวน = ขาย 1,
-- ส่ง 2 = ขาย 2 จาก stack / ขายได้จากทุกที่ ไม่ต้องอยู่ใกล้ NPC) / SellGUI ข้ามของที่ใส่อยู่ (IsEquipedUUID)
-- ข้อมูลของ: Config.AnyHelper.GetRarity / GetSellPrice / GetDisName / CheckIsUnSell (Type, ID)
-- ราคาที่ได้จริง = GetSellPrice x boost เหรียญ (วัดสด Ore_1 ราคา 8 ได้ 20.8)
-- ลำดับ Rarity = Config.Rarity.Helper.GetRarityLevel: Common 1 ... Mythic 6, Eternal 7, Secret 8, Ancient 9, Infinite 10

local function ParseAmount(Text)
    Text = tostring(Text or ""):gsub("[,%s]", ""):lower()
    if Text == "" then return nil end
    local Number, Unit = Text:match("^([%d%.e%+]+)(%a*)$")
    Number = tonumber(Number)
    if not Number then return nil end
    local Units = { k = 1e3, m = 1e6, b = 1e9, t = 1e12, qa = 1e15, qi = 1e18 }
    return Number * (Units[Unit] or 1)
end

local Sell = {
    Running = false,
    Status = nil,
    Types = { "Weapon", "Armor", "Hat", "Ore", "EnchStone", "Material" },
    Rarities = { },
    NameModes = { "Any Name", "Only Selected Names", "All Except Selected Names" },
    Sold = 0,
    Earned = 0,
    NamesDropdown = nil
}

pcall(function()
    local Rarity = require(ReplicatedStorage.Config.Rarity.Helper)
    for Level = 1, 20 do
        local Name = Rarity.GetRarityByLevel(Level)
        if type(Name) ~= "string" or Name == "" then break end
        table.insert(Sell.Rarities, Name)
    end
end)
if #Sell.Rarities == 0 then
    Sell.Rarities = { "Common", "UnCommon", "Rare", "Epic", "Legendary", "Mythic", "Eternal", "Secret", "Ancient", "Infinite" }
end

function Sell.Helper()
    local Ok, Module = pcall(function() return require(ReplicatedStorage.Config.AnyHelper) end)
    return Ok and Module or nil
end

-- ของทั้งหมดในกระเป๋า + ข้อมูลที่ใช้กรอง
function Sell.Items()
    local Backpack, Helper = Enhant.Backpack(), Sell.Helper()
    local List = { }
    if not (Backpack and Helper) then return List end
    pcall(function()
        local Data = Backpack.GetData()
        local Equipped = { }
        for _, Uuid in pairs(Data.equiped or { }) do Equipped[Uuid] = true end
        for Uuid, Item in pairs(Data.have or { }) do
            if type(Item) == "table" and Item.ID then
                local Enchanted = false
                for _, Entry in pairs(Item.EnchanceList or { }) do
                    if type(Entry) == "table" and next(Entry) ~= nil then Enchanted = true break end
                end
                table.insert(List, {
                    Uuid = Uuid,
                    Type = Item.Type,
                    Id = Item.ID,
                    Name = tostring(Helper.GetDisName(Item.Type, Item.ID) or Item.ID),
                    Rarity = Helper.GetRarity(Item.Type, Item.ID),
                    Price = tonumber(Helper.GetSellPrice(Item.Type, Item.ID)) or 0,
                    Number = tonumber(Item.Number) or 1,
                    Level = tonumber(Item.Level) or 0,
                    Enchanted = Enchanted,
                    Equipped = Equipped[Uuid] == true,
                    Locked = Helper.CheckIsUnSell(Item.Type, Item.ID) == true
                })
            end
        end
    end)
    return List
end

-- ของที่ตรงทุกตัวกรอง: { { Item, Count } } (Count = จำนวนที่จะขายจาก stack นั้น)
function Sell.Matches()
    local Config = getgenv().ConfigurationTable
    local Types = Config.SellTypes or { }
    local Rarities = Config.SellRarities or { }
    local Names = Config.SellNames or { }
    local Mode = Config.SellNameMode or "Any Name"
    local Min = ParseAmount(Config.SellPriceMin)
    local Max = ParseAmount(Config.SellPriceMax)
    local Keep = tonumber(Config.SellKeepAmount) or 0

    local Candidates = { }
    for _, Item in ipairs(Sell.Items()) do
        local Ok = not Item.Equipped and not Item.Locked
            and table.find(Types, Item.Type) ~= nil
            and table.find(Rarities, Item.Rarity) ~= nil
            and (not Min or Item.Price >= Min)
            and (not Max or Item.Price <= Max)
            and not (Config.SellKeepEnhanced and Item.Level > 0)
            and not (Config.SellKeepEnchanted and Item.Enchanted)
        if Ok and Mode == "Only Selected Names" then Ok = table.find(Names, Item.Name) ~= nil end
        if Ok and Mode == "All Except Selected Names" then Ok = table.find(Names, Item.Name) == nil end
        if Ok then table.insert(Candidates, Item) end
    end

    -- Keep Amount: เก็บไว้อย่างน้อย N ชิ้นต่อไอดี (stack แร่ = นับใน stack / อาวุธซ้ำ = เก็บตัวที่ตีบวกสูงสุดไว้)
    table.sort(Candidates, function(A, B)
        if A.Id ~= B.Id then return A.Id < B.Id end
        return A.Level > B.Level
    end)
    local Kept = { }
    local Result = { }
    for _, Item in ipairs(Candidates) do
        local Left = math.max(Keep - (Kept[Item.Id] or 0), 0)
        local Hold = math.min(Left, Item.Number)
        Kept[Item.Id] = (Kept[Item.Id] or 0) + Hold
        local Count = Item.Number - Hold
        if Count > 0 then table.insert(Result, { Item = Item, Count = Count }) end
    end
    return Result
end

function Sell.Set(Key, Value)
    if Sell.Status then Sell.Status:Set(Key, Value) end
end

function Sell.Preview(Matches)
    local Total, Count = 0, 0
    for _, Match in ipairs(Matches) do
        Total = Total + Match.Item.Price * Match.Count
        Count = Count + Match.Count
    end
    Sell.Set("Matching", string.format("%d items (base %s coin)", Count, Stage.Short(Total)))
    Sell.Set("Sold", string.format("%d items, +%s coin", Sell.Sold, Stage.Short(Sell.Earned)))
end

-- ขายทุกชิ้นที่ตรงตัวกรอง คืนจำนวนที่ขาย
function Sell.Once()
    local Matches = Sell.Matches()
    Sell.Preview(Matches)
    if #Matches == 0 then return 0 end

    local Backpack = Enhant.Backpack()
    local Before = Enhant.Coin()
    local Count = 0
    for _, Match in ipairs(Matches) do
        if getgenv().ValkyrieSession ~= SessionToken then break end
        Sell.Set("State", string.format("Selling %s x%d", Match.Item.Name, Match.Count))
        pcall(function() Backpack.TrySellItem(Match.Item.Uuid, Match.Count) end)
        Count = Count + Match.Count
        task.wait(0.25)
    end
    task.wait(0.5)
    Sell.Sold = Sell.Sold + Count
    Sell.Earned = Sell.Earned + math.max(Enhant.Coin() - Before, 0)
    Sell.Preview(Sell.Matches())
    return Count
end

function Sell.Start()
    if Sell.Running then return end
    Sell.Running = true

    local Token = SessionToken
    task.spawn(function()
        while Sell.Running and getgenv().ValkyrieSession == Token do
            local Ok, Count = pcall(Sell.Once)
            Sell.Status:SetState(Ok and "Running" or "Error")
            Sell.Set("State", Ok and (Count > 0 and string.format("Sold %d items", Count) or "Nothing to sell")
                or ("Error: " .. tostring(Count)))
            local Wait = os.clock() + (tonumber(getgenv().ConfigurationTable.SellInterval) or 30)
            while Sell.Running and getgenv().ValkyrieSession == Token and os.clock() < Wait do task.wait(0.5) end
        end
    end)
end

function Sell.Stop()
    Sell.Running = false
    if Sell.Status then
        Sell.Status:SetState("Idle")
        Sell.Set("State", nil)
    end
end

-- ชื่อของที่มีในกระเป๋า (ตามประเภทที่เลือก) + ชื่อที่เลือกไว้แล้ว (ไม่หายตอนขายหมด)
function Sell.NameList()
    local Config = getgenv().ConfigurationTable
    local Types = Config.SellTypes or { }
    local Seen, List = { }, { }
    for _, Item in ipairs(Sell.Items()) do
        if table.find(Types, Item.Type) and not Seen[Item.Name] then
            Seen[Item.Name] = true
            table.insert(List, Item.Name)
        end
    end
    for _, Name in ipairs(Config.SellNames or { }) do
        if not Seen[Name] then Seen[Name] = true table.insert(List, Name) end
    end
    table.sort(List)
    return List
end

local SellPage = Window:Page({ Name = "Auto Sell", Icon = "coins", Columns = 2 })

local SellMainSection = SellPage:Section({
    Name = "Auto Sell",
    Side = 1
})

local SellFilterSection = SellPage:Section({
    Name = "Filters",
    Side = 1
})

local SellInfoSection = SellPage:Section({
    Name = "Status",
    Side = 2
})

Sell.Status = SellInfoSection:Status({
    Name = "Sell Status",
    Rows = { "State", "Matching", "Sold" }
})

SellFilterSection:Dropdown({
    Name = "Item Types",
    Description = "Kinds of items that can be sold",
    Flag = "LTFSellTypes",
    Items = Sell.Types,
    KeepOrder = true,
    Default = getgenv().ConfigurationTable.SellTypes,
    Multi = true,
    Callback = function(Value)
        getgenv().ConfigurationTable.SellTypes = Value
        SaveConfiguration()
    end
})

SellFilterSection:Dropdown({
    Name = "Rarities",
    Description = "Only items of these rarities are sold",
    Flag = "LTFSellRarities",
    Items = Sell.Rarities,
    KeepOrder = true,
    Default = getgenv().ConfigurationTable.SellRarities,
    Multi = true,
    Callback = function(Value)
        getgenv().ConfigurationTable.SellRarities = Value
        SaveConfiguration()
    end
})

SellFilterSection:Textbox({
    Name = "Min Price",
    Placeholder = "No minimum (e.g. 500, 2K, 1.5M)",
    Default = getgenv().ConfigurationTable.SellPriceMin,
    Flag = "LTFSellPriceMin",
    Callback = function(Text)
        getgenv().ConfigurationTable.SellPriceMin = Text
        SaveConfiguration()
    end
})

SellFilterSection:Textbox({
    Name = "Max Price",
    Placeholder = "No maximum (e.g. 50K, 2M)",
    Default = getgenv().ConfigurationTable.SellPriceMax,
    Flag = "LTFSellPriceMax",
    Callback = function(Text)
        getgenv().ConfigurationTable.SellPriceMax = Text
        SaveConfiguration()
    end
})

SellFilterSection:Dropdown({
    Name = "Name Filter",
    Description = "How the selected item names are used",
    Flag = "LTFSellNameMode",
    Items = Sell.NameModes,
    KeepOrder = true,
    Default = getgenv().ConfigurationTable.SellNameMode,
    Multi = false,
    Callback = function(Value)
        getgenv().ConfigurationTable.SellNameMode = Value
        SaveConfiguration()
    end
})

Sell.NamesDropdown = SellFilterSection:Dropdown({
    Name = "Item Names",
    Description = "Names from your backpack - press Refresh Names after looting new items",
    Flag = "LTFSellNames",
    Items = Sell.NameList(),
    Default = getgenv().ConfigurationTable.SellNames,
    Multi = true,
    Callback = function(Value)
        getgenv().ConfigurationTable.SellNames = Value
        SaveConfiguration()
    end
})

SellFilterSection:Button({
    Name = "Refresh Names",
    Callback = function()
        pcall(function() Sell.NamesDropdown:Refresh(Sell.NameList(), getgenv().ConfigurationTable.SellNames) end)
    end
})

SellFilterSection:Slider({
    Name = "Keep Amount",
    Description = "Always keep at least this many of each item",
    Flag = "LTFSellKeepAmount",
    Min = 0,
    Max = 50,
    Default = getgenv().ConfigurationTable.SellKeepAmount,
    Callback = function(Value)
        getgenv().ConfigurationTable.SellKeepAmount = Value
        SaveConfiguration()
    end
})

SellFilterSection:Toggle({
    Name = "Keep Enhanced Items",
    Description = "Never sell items with an enhance level (+1 or more)",
    Flag = "LTFSellKeepEnhanced",
    Default = getgenv().ConfigurationTable.SellKeepEnhanced,
    Callback = function(Value)
        getgenv().ConfigurationTable.SellKeepEnhanced = Value
        SaveConfiguration()
    end
})

SellFilterSection:Toggle({
    Name = "Keep Enchanted Items",
    Description = "Never sell items that hold an enchant stone",
    Flag = "LTFSellKeepEnchanted",
    Default = getgenv().ConfigurationTable.SellKeepEnchanted,
    Callback = function(Value)
        getgenv().ConfigurationTable.SellKeepEnchanted = Value
        SaveConfiguration()
    end
})

SellMainSection:Slider({
    Name = "Sell Every",
    Description = "Seconds between sell checks",
    Flag = "LTFSellInterval",
    Min = 5,
    Max = 300,
    Default = getgenv().ConfigurationTable.SellInterval,
    Callback = function(Value)
        getgenv().ConfigurationTable.SellInterval = Value
        SaveConfiguration()
    end
})

SellMainSection:Toggle({
    Name = "Auto Sell",
    Flag = "LTFAutoSell",
    Default = getgenv().ConfigurationTable.AutoSell,
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoSell = Value
        SaveConfiguration()

        if Value then Sell.Start() else Sell.Stop() end
    end
})

SellMainSection:Button({
    Name = "Sell Now",
    Callback = function()
        task.spawn(function()
            local Count = Sell.Once()
            Sell.Set("State", Count > 0 and string.format("Sold %d items", Count) or "Nothing to sell")
        end)
    end
})

SellInfoSection:Guide("How to use", {
    "Pick Item Types and Rarities - an item must match every filter to be sold",
    "Min / Max Price use the item's base sell price (K, M, B work)",
    "Name Filter: sell only the selected names, or everything except them",
    "Equipped items and items the game marks as unsellable are never sold",
    "Matching shows what would be sold right now - check it before turning on Auto Sell",
})

task.spawn(function()
    local Token = SessionToken
    while getgenv().ValkyrieSession == Token do
        if not Sell.Running then pcall(function() Sell.Preview(Sell.Matches()) end) end
        task.wait(3)
    end
end)

---- ============ Auto Upgrade ============ ----
--
-- UpgradeGUI ปุ่มอัป = UpgradeData.UpgradeOnce("Train" | "Luck" | "OrePack") -> Remote.Upgrade.UpgradeOnceRE
-- Config.Upgrade.Config[ชนิด][ระดับ] = { Number = ค่าที่ได้, Price = coin } 12 ระดับ / ระดับปัจจุบัน = UpgradeData.GetLevel(ชนิด)
-- ราคาอัปครั้งถัดไป = Config[ชนิด][ระดับ + 1].Price (วัดสด ระดับ 4 ทั้งสามอย่าง)

local Upgrade = {
    Running = false,
    Status = nil,
    Kinds = { "Train", "Luck", "OrePack" },
    Labels = { Train = "Train", Luck = "Luck", OrePack = "Ore Pack" },
    Orders = { "Cheapest First", "List Order" },
    Config = { },
    Failed = { }
}

pcall(function()
    local Config = require(ReplicatedStorage.Config.Upgrade.Config)
    if type(Config) == "table" then Upgrade.Config = Config end
end)

function Upgrade.Level(Kind)
    local Ok, Level = pcall(function() return require(ReplicatedStorage.LocalData.UpgradeData).GetLevel(Kind) end)
    return Ok and tonumber(Level) or 0
end

function Upgrade.Next(Kind)
    local List = Upgrade.Config[Kind] or { }
    local Level = Upgrade.Level(Kind)
    return List[Level + 1], Level, #List
end

function Upgrade.Set(Key, Value)
    if Upgrade.Status then Upgrade.Status:Set(Key, Value) end
end

function Upgrade.Show()
    for _, Kind in ipairs(Upgrade.Kinds) do
        local Next, Level, Max = Upgrade.Next(Kind)
        Upgrade.Set(Upgrade.Labels[Kind], Next and string.format("Lv %d/%d - next %s coin", Level, Max, Stage.Short(Next.Price))
            or string.format("Lv %d/%d - max", Level, Max))
    end
    Upgrade.Set("Coin", Stage.Short(Enhant.Coin()))
end

-- อัปหนึ่งครั้ง: คืน "hit" / "wait" (เหรียญไม่พอ) / "done" (ตันหมดแล้ว)
function Upgrade.Once()
    local Config = getgenv().ConfigurationTable
    local Selected = Config.UpgradeKinds or { }
    local Reserve = ParseAmount(Config.UpgradeKeepCoins) or 0
    local Options = { }
    for Order, Kind in ipairs(Upgrade.Kinds) do
        local Next = Upgrade.Next(Kind)
        local FailedAt = Upgrade.Failed[Kind]
        if table.find(Selected, Kind) and Next and not (FailedAt and os.clock() - FailedAt < 30) then
            table.insert(Options, { Kind = Kind, Price = tonumber(Next.Price) or math.huge, Order = Order })
        end
    end
    if #Options == 0 then return "done" end
    if Config.UpgradeOrder ~= "List Order" then
        table.sort(Options, function(A, B) return A.Price < B.Price end)
    end

    local Coin = Enhant.Coin()
    for _, Option in ipairs(Options) do
        if Coin - Option.Price >= Reserve then
            local Before = Upgrade.Level(Option.Kind)
            Upgrade.Set("State", "Upgrading " .. Upgrade.Labels[Option.Kind])
            pcall(function() require(ReplicatedStorage.LocalData.UpgradeData).UpgradeOnce(Option.Kind) end)
            local Deadline = os.clock() + 2
            repeat task.wait(0.2) until os.clock() > Deadline or Upgrade.Level(Option.Kind) > Before
            if Upgrade.Level(Option.Kind) <= Before then Upgrade.Failed[Option.Kind] = os.clock() end
            return "hit"
        end
        -- List Order = รอตัวแรกให้เงินพอก่อน ไม่ข้ามไปอัปตัวถัดไป
        if Config.UpgradeOrder == "List Order" then break end
    end
    Upgrade.Set("State", "Not enough coins" .. (Reserve > 0 and (" (keeping " .. Stage.Short(Reserve) .. ")") or ""))
    return "wait"
end

function Upgrade.Start()
    if Upgrade.Running then return end
    Upgrade.Running = true

    local Token = SessionToken
    task.spawn(function()
        while Upgrade.Running and getgenv().ValkyrieSession == Token do
            local Ok, Result = pcall(Upgrade.Once)
            pcall(Upgrade.Show)
            if not Ok then
                Upgrade.Status:SetState("Error")
                Upgrade.Set("State", "Error: " .. tostring(Result))
                task.wait(3)
            elseif Result == "hit" then
                Upgrade.Status:SetState("Running")
                task.wait(0.5)
            elseif Result == "wait" then
                Upgrade.Status:SetState("Waiting")
                task.wait(3)
            else
                Upgrade.Status:SetState("Done")
                Upgrade.Set("State", "Selected upgrades are maxed")
                task.wait(5)
            end
        end
    end)
end

function Upgrade.Stop()
    Upgrade.Running = false
    if Upgrade.Status then
        Upgrade.Status:SetState("Idle")
        Upgrade.Set("State", nil)
    end
end

local UpgradePage = Window:Page({ Name = "Auto Upgrade", Icon = "trending-up", Columns = 2 })

local UpgradeMainSection = UpgradePage:Section({
    Name = "Auto Upgrade",
    Side = 1
})

local UpgradeInfoSection = UpgradePage:Section({
    Name = "Status",
    Side = 2
})

Upgrade.Status = UpgradeInfoSection:Status({
    Name = "Upgrade Status",
    Rows = { "State", "Train", "Luck", "Ore Pack", "Coin" }
})

UpgradeMainSection:Dropdown({
    Name = "Upgrades",
    Description = "Train = training gain, Luck = drop luck, Ore Pack = ores you can carry",
    Flag = "LTFUpgradeKinds",
    Items = Upgrade.Kinds,
    KeepOrder = true,
    Default = getgenv().ConfigurationTable.UpgradeKinds,
    Multi = true,
    Callback = function(Value)
        getgenv().ConfigurationTable.UpgradeKinds = Value
        SaveConfiguration()
    end
})

UpgradeMainSection:Dropdown({
    Name = "Order",
    Description = "Cheapest First buys whatever costs least next; List Order saves up for the first one",
    Flag = "LTFUpgradeOrder",
    Items = Upgrade.Orders,
    KeepOrder = true,
    Default = getgenv().ConfigurationTable.UpgradeOrder,
    Multi = false,
    Callback = function(Value)
        getgenv().ConfigurationTable.UpgradeOrder = Value
        SaveConfiguration()
    end
})

UpgradeMainSection:Textbox({
    Name = "Keep Coins",
    Placeholder = "Coins to never spend (e.g. 100K, 5M)",
    Default = getgenv().ConfigurationTable.UpgradeKeepCoins,
    Flag = "LTFUpgradeKeepCoins",
    Callback = function(Text)
        getgenv().ConfigurationTable.UpgradeKeepCoins = Text
        SaveConfiguration()
    end
})

UpgradeMainSection:Toggle({
    Name = "Auto Upgrade",
    Flag = "LTFAutoUpgrade",
    Default = getgenv().ConfigurationTable.AutoUpgrade,
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoUpgrade = Value
        SaveConfiguration()

        if Value then Upgrade.Start() else Upgrade.Stop() end
    end
})

UpgradeMainSection:Button({
    Name = "Upgrade Once",
    Callback = function()
        task.spawn(function()
            if Upgrade.Once() ~= "hit" then
                Library:Notify("Upgrade", "Nothing to upgrade (maxed or not enough coins)", 4)
            end
            Upgrade.Show()
        end)
    end
})

UpgradeInfoSection:Guide("How to use", {
    "Pick the upgrades and the Order, then turn on Auto Upgrade",
    "It buys a level whenever you have the coins, up to level 12",
    "Keep Coins leaves that much unspent (for Enhance / Enchant)",
})

task.spawn(function()
    local Token = SessionToken
    while getgenv().ValkyrieSession == Token do
        if not Upgrade.Running then pcall(Upgrade.Show) end
        task.wait(3)
    end
end)

---- ============ Equipment ============ ----
--
-- ใส่ของ = BackpackData.EquipedItem(uuid, Type) -> TryEquipItemRE (วัดสด: ไม่ส่ง Type = ไม่เปลี่ยน)
-- ค่าความแรงที่เกมใช้คิดสเตตัส (Stats GetEquipmentAdd / GetEquipmentBoost) = Utils.BalanceUtils:
--   GetWeaponTrainValue(_, ItemData, BackpackData.GetData()) / GetArmorValue(_, ItemData, ทั้งหมด) (Armor และ Hat)
--   นับระดับตีบวกแล้ว (วัดสด G_17 +5 = 2.77M, G_17 +0 = 2.22M) / ช่องที่ใส่ = GetData().equiped[Weapon|Armor|Hat]

local Equip = {
    Running = false,
    Status = nil,
    Slots = { Weapon = "EquipWeapon", Armor = "EquipArmor", Hat = "EquipHat" },
    Order = { "Weapon", "Armor", "Hat" }
}

function Equip.Value(Item, Data)
    local Ok, Value = pcall(function()
        local Balance = require(ReplicatedStorage.Utils.BalanceUtils)
        if Item.Type == "Weapon" then return Balance.GetWeaponTrainValue(LocalPlayer, Item, Data) end
        return Balance.GetArmorValue(LocalPlayer, Item, Data)
    end)
    return Ok and tonumber(Value) or 0
end

-- ของที่ดีสุดในช่องนั้น: uuid ที่ใส่อยู่, ค่าที่ใส่อยู่, uuid ดีสุด, ค่าดีสุด, ID ดีสุด
function Equip.Best(Slot)
    local Backpack = Enhant.Backpack()
    local Ok, Data = pcall(function() return Backpack.GetData() end)
    if not (Ok and Data) then return nil end
    local Current = (Data.equiped or { })[Slot]
    local CurrentValue = Current and Data.have[Current] and Equip.Value(Data.have[Current], Data) or -1
    local Best, BestValue, BestId = Current, CurrentValue, Current and Data.have[Current] and Data.have[Current].ID
    for Uuid, Item in pairs(Data.have or { }) do
        if type(Item) == "table" and Item.Type == Slot then
            local Value = Equip.Value(Item, Data)
            if Value > BestValue then Best, BestValue, BestId = Uuid, Value, Item.ID end
        end
    end
    return Current, CurrentValue, Best, BestValue, BestId
end

function Equip.Set(Key, Value)
    if Equip.Status then Equip.Status:Set(Key, Value) end
end

-- ตรวจทุกช่องที่เปิดไว้ (All = ทุกช่องไม่สนสวิตช์ สำหรับปุ่ม) คืนจำนวนช่องที่เปลี่ยน
function Equip.Once(All)
    local Config = getgenv().ConfigurationTable
    local Helper = Sell.Helper()
    local Changed = 0
    for _, Slot in ipairs(Equip.Order) do
        local Current, CurrentValue, Best, BestValue, BestId = Equip.Best(Slot)
        local Name = BestId and Helper and tostring(Helper.GetDisName(Slot, BestId) or BestId) or "-"
        if Best == nil then
            Equip.Set(Slot, "Nothing to equip")
        elseif Best ~= Current and (All or Config[Equip.Slots[Slot]]) then
            pcall(function() Enhant.Backpack().EquipedItem(Best, Slot) end)
            Changed = Changed + 1
            Equip.Set(Slot, string.format("Equipped %s (%s)", Name, Stage.Short(BestValue)))
            task.wait(0.5)
        else
            Equip.Set(Slot, string.format("%s (%s)%s", Name, Stage.Short(BestValue), Best == Current and " - best" or ""))
        end
    end
    return Changed
end

function Equip.Start()
    if Equip.Running then return end
    Equip.Running = true

    local Token = SessionToken
    task.spawn(function()
        while Equip.Running and getgenv().ValkyrieSession == Token do
            local Ok, Changed = pcall(Equip.Once, false)
            Equip.Status:SetState(Ok and "Running" or "Error")
            Equip.Set("State", Ok and (Changed > 0 and ("Equipped " .. Changed .. " better item(s)") or "Wearing the best")
                or ("Error: " .. tostring(Changed)))
            local Wait = os.clock() + (tonumber(getgenv().ConfigurationTable.EquipInterval) or 10)
            while Equip.Running and getgenv().ValkyrieSession == Token and os.clock() < Wait do task.wait(0.5) end
        end
    end)
end

function Equip.Stop()
    Equip.Running = false
    if Equip.Status then
        Equip.Status:SetState("Idle")
        Equip.Set("State", nil)
    end
end

-- ระบบเดียววิ่งให้ทุกช่อง: เปิดช่องไหนก็วิ่ง ปิดครบทุกช่องค่อยหยุด
function Equip.Refresh()
    local Config = getgenv().ConfigurationTable
    if Config.EquipWeapon or Config.EquipArmor or Config.EquipHat then Equip.Start() else Equip.Stop() end
end

local EquipPage = Window:Page({ Name = "Equipment", Icon = "shirt", Columns = 2 })

local EquipMainSection = EquipPage:Section({
    Name = "Auto Equip",
    Side = 1
})

local EquipInfoSection = EquipPage:Section({
    Name = "Status",
    Side = 2
})

Equip.Status = EquipInfoSection:Status({
    Name = "Equipment Status",
    Rows = { "State", "Weapon", "Armor", "Hat" }
})

EquipMainSection:Toggle({
    Name = "Auto Equip Best Weapon",
    Description = "Wear the weapon with the highest power (enhance level counted)",
    Flag = "LTFEquipWeapon",
    Default = getgenv().ConfigurationTable.EquipWeapon,
    Callback = function(Value)
        getgenv().ConfigurationTable.EquipWeapon = Value
        SaveConfiguration()
        Equip.Refresh()
    end
})

EquipMainSection:Toggle({
    Name = "Auto Equip Best Armor",
    Description = "Wear the armor with the highest defence",
    Flag = "LTFEquipArmor",
    Default = getgenv().ConfigurationTable.EquipArmor,
    Callback = function(Value)
        getgenv().ConfigurationTable.EquipArmor = Value
        SaveConfiguration()
        Equip.Refresh()
    end
})

EquipMainSection:Toggle({
    Name = "Auto Equip Best Hat",
    Description = "Wear the hat with the highest defence",
    Flag = "LTFEquipHat",
    Default = getgenv().ConfigurationTable.EquipHat,
    Callback = function(Value)
        getgenv().ConfigurationTable.EquipHat = Value
        SaveConfiguration()
        Equip.Refresh()
    end
})

EquipMainSection:Slider({
    Name = "Check Every",
    Description = "Seconds between equipment checks",
    Flag = "LTFEquipInterval",
    Min = 3,
    Max = 120,
    Default = getgenv().ConfigurationTable.EquipInterval,
    Callback = function(Value)
        getgenv().ConfigurationTable.EquipInterval = Value
        SaveConfiguration()
    end
})

EquipMainSection:Button({
    Name = "Equip Best Now",
    Callback = function()
        task.spawn(function()
            local Changed = Equip.Once(true)
            Equip.Set("State", Changed > 0 and ("Equipped " .. Changed .. " better item(s)") or "Wearing the best")
        end)
    end
})

EquipInfoSection:Guide("How to use", {
    "Turn on the slots you want: it swaps in a stronger item as soon as you get one",
    "Power is the game's own stat value, so enhance levels are counted",
    "Turn off Auto Sell for Weapon / Armor rarities you may want to wear",
})

task.spawn(function()
    local Token = SessionToken
    while getgenv().ValkyrieSession == Token do
        if not Equip.Running then
            pcall(function()
                local Helper = Sell.Helper()
                for _, Slot in ipairs(Equip.Order) do
                    local Current, _, Best, BestValue, BestId = Equip.Best(Slot)
                    local Name = BestId and Helper and tostring(Helper.GetDisName(Slot, BestId) or BestId) or nil
                    Equip.Set(Slot, Name and string.format("%s (%s)%s", Name, Stage.Short(BestValue),
                        Best == Current and " - best" or " - better one in backpack") or "Nothing to equip")
                end
            end)
        end
        task.wait(5)
    end
end)

---- ============ Miscellaneous ============ ----
--
-- Online: Config.Online.Reward[i] = { Time = วินาทีออนไลน์, Type, ID, Number } / LocalData.OnlineData:
--   GetData() = { StartTick, PassTime, Reward = { ["i"] = true } } / TryClaim(i) -> Online.TryClaimRE
--   เวลาที่ใช้นับ (ตาม OnlineGift.update ของเกม) = PassTime (สะสมจากเซสชันก่อนในรอบนี้) + (ServerTime - StartTick)
--   ห้ามใช้ GetOnlineTimes() = นับแค่เซสชันนี้ ไม่รวม PassTime (วัดสด: 1706 วิ ทั้งที่เกมนับ 22996 = รับได้ครบแล้ว)
--   รับครบทั้ง 12 อัน = เกมเริ่มรอบใหม่ (StartTick ใหม่, PassTime 0, Reward ว่าง - วัดสด)
-- Index: LocalData.IndexData: GetData() = { unlocked = { ["Type-ID"] = { } }, claimed = { ["Type-ID"] = true }, exp, level }
--   TryClaimedExp(Type, ID) = รับ exp ของไอเทมที่ปลดแล้ว (วัดสด Ore +50) / TryClaimedLevel() = เลื่อนระดับ Index
--   ใช้ exp ตาม Config.Index.Config[level + 1].NeedExp (วัดสด exp 60 -> 10 ตอนขึ้นระดับ 1 ที่ต้องการ 50)

local Misc = { Online = nil, Index = nil, OnlineRunning = false, IndexRunning = false, OnlineStatus = nil, IndexStatus = nil }

Misc.OnlineConfig = { }
pcall(function() Misc.OnlineConfig = require(ReplicatedStorage.Config.Online.Reward) end)
Misc.IndexConfig = { }
pcall(function() Misc.IndexConfig = require(ReplicatedStorage.Config.Index.Config) end)

function Misc.OnlineData()
    local Ok, Module = pcall(function() return require(ReplicatedStorage.LocalData.OnlineData) end)
    return Ok and Module or nil
end

-- วินาทีออนไลน์ที่เกมใช้ตัดสินว่ารับรางวัลได้ไหม
function Misc.OnlineSeconds(Data)
    local Info = Data.GetData() or { }
    local Now = tonumber(workspace:GetAttribute("ServerTime")) or os.time()
    local Start = tonumber(Info.StartTick) or Now
    return (tonumber(Info.PassTime) or 0) + math.max(Now - Start, 0)
end

function Misc.IndexData()
    local Ok, Module = pcall(function() return require(ReplicatedStorage.LocalData.IndexData) end)
    return Ok and Module or nil
end

-- รับรางวัลออนไลน์ที่ถึงเวลาแล้วทั้งหมด คืน จำนวนที่รับ, วินาทีถึงรางวัลถัดไป (nil = รับครบแล้ว)
function Misc.ClaimOnline()
    local Data = Misc.OnlineData()
    if not Data then return 0, nil end
    local Online = Misc.OnlineSeconds(Data)
    local Claimed = (Data.GetData() or { }).Reward or { }
    local Count, Next = 0, nil
    for Index, Reward in pairs(Misc.OnlineConfig) do
        if type(Reward) == "table" and not Claimed[Index] and not Claimed[tostring(Index)] then
            local Time = tonumber(Reward.Time) or 0
            if Online >= Time then
                pcall(Data.TryClaim, Index)
                Count = Count + 1
                task.wait(0.3)
            elseif not Next or Time - Online < Next then
                Next = Time - Online
            end
        end
    end
    return Count, Next
end

function Misc.ShowOnline(Next)
    local Data = Misc.OnlineData()
    if not (Data and Misc.OnlineStatus) then return end
    local Claimed = (Data.GetData() or { }).Reward or { }
    local Total, Done = 0, 0
    for Index in pairs(Misc.OnlineConfig) do
        Total = Total + 1
        if Claimed[Index] or Claimed[tostring(Index)] then Done = Done + 1 end
    end
    Misc.OnlineStatus:Set("Online", string.format("%d min", math.floor(Misc.OnlineSeconds(Data) / 60)))
    Misc.OnlineStatus:Set("Claimed", string.format("%d / %d", Done, Total))
    Misc.OnlineStatus:Set("Next", Next and string.format("in %d s", math.ceil(Next)) or (Done >= Total and "All claimed" or "-"))
end

-- รับ exp ของไอเทมที่ปลดใน Index ทั้งหมด แล้วเลื่อนระดับตาม exp ที่มี คืน จำนวนไอเทม, จำนวนระดับ
function Misc.ClaimIndex()
    local Data = Misc.IndexData()
    if not Data then return 0, 0 end
    local Info = Data.GetData() or { }
    local Items, Levels = 0, 0
    for Key in pairs(Info.unlocked or { }) do
        if not (Info.claimed or { })[Key] then
            local Type, Id = tostring(Key):match("^(%a+)%-(.+)$")
            if Type then
                pcall(Data.TryClaimedExp, Type, Id)
                Items = Items + 1
            end
        end
    end
    for _ = 1, 50 do
        Info = Data.GetData() or { }
        local Next = Misc.IndexConfig[(tonumber(Info.level) or 0) + 1]
        if not (Next and (tonumber(Info.exp) or 0) >= (tonumber(Next.NeedExp) or math.huge)) then break end
        local Before = Info.level
        pcall(Data.TryClaimedLevel)
        Levels = Levels + 1
        task.wait(0.3)
        if (Data.GetData() or { }).level == Before then break end
    end
    return Items, Levels
end

function Misc.ShowIndex()
    local Data = Misc.IndexData()
    if not (Data and Misc.IndexStatus) then return end
    local Info = Data.GetData() or { }
    local Level = tonumber(Info.level) or 0
    local Next = Misc.IndexConfig[Level + 1]
    local Waiting = 0
    for Key in pairs(Info.unlocked or { }) do
        if not (Info.claimed or { })[Key] then Waiting = Waiting + 1 end
    end
    Misc.IndexStatus:Set("Level", string.format("%d / %d", Level, #Misc.IndexConfig))
    Misc.IndexStatus:Set("Exp", Next and string.format("%d / %d (next: %s)", tonumber(Info.exp) or 0, tonumber(Next.NeedExp) or 0,
        tostring(Next.Text or "-")) or tostring(Info.exp or 0) .. " (max level)")
    Misc.IndexStatus:Set("Unclaimed", tostring(Waiting))
end

function Misc.Loop(Key, Step)
    if Misc[Key] then return end
    Misc[Key] = true
    local Token = SessionToken
    task.spawn(function()
        while Misc[Key] and getgenv().ValkyrieSession == Token do
            pcall(Step)
            task.wait(3)
        end
    end)
end

local MiscPage = Window:Page({ Name = "Miscellaneous", Icon = "puzzle", Columns = 2 })

local OnlineSection = MiscPage:Section({
    Name = "Online Rewards",
    Side = 1
})

local IndexSection = MiscPage:Section({
    Name = "Index",
    Side = 2
})

Misc.OnlineStatus = OnlineSection:Status({
    Name = "Online Status",
    Rows = { "State", "Online", "Claimed", "Next" }
})

OnlineSection:Toggle({
    Name = "Auto Claim Online",
    Description = "Claim each online-time reward as soon as it is ready",
    Flag = "LTFAutoClaimOnline",
    Default = getgenv().ConfigurationTable.AutoClaimOnline,
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoClaimOnline = Value
        SaveConfiguration()
        if Value then
            Misc.Loop("OnlineRunning", function()
                local Count, Next = Misc.ClaimOnline()
                Misc.OnlineStatus:SetState("Running")
                Misc.OnlineStatus:Set("State", Count > 0 and ("Claimed " .. Count .. " reward(s)") or "Waiting for the next reward")
                Misc.ShowOnline(Next)
            end)
        else
            Misc.OnlineRunning = false
            Misc.OnlineStatus:SetState("Idle")
            Misc.OnlineStatus:Set("State", nil)
        end
    end
})

Misc.IndexStatus = IndexSection:Status({
    Name = "Index Status",
    Rows = { "State", "Level", "Exp", "Unclaimed" }
})

IndexSection:Toggle({
    Name = "Auto Claim Index",
    Description = "Claim Index exp for every new item, then level the Index up whenever the exp is enough",
    Flag = "LTFAutoClaimIndex",
    Default = getgenv().ConfigurationTable.AutoClaimIndex,
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoClaimIndex = Value
        SaveConfiguration()
        if Value then
            Misc.Loop("IndexRunning", function()
                local Items, Levels = Misc.ClaimIndex()
                Misc.IndexStatus:SetState("Running")
                Misc.IndexStatus:Set("State", (Items > 0 or Levels > 0)
                    and string.format("Claimed %d item(s), %d level(s)", Items, Levels) or "Waiting for new items")
                Misc.ShowIndex()
            end)
        else
            Misc.IndexRunning = false
            Misc.IndexStatus:SetState("Idle")
            Misc.IndexStatus:Set("State", nil)
        end
    end
})

task.spawn(function()
    local Token = SessionToken
    while getgenv().ValkyrieSession == Token do
        if not Misc.OnlineRunning then
            pcall(function()
                local Data = Misc.OnlineData()
                local Online, Next = Misc.OnlineSeconds(Data), nil
                local Claimed = (Data.GetData() or { }).Reward or { }
                for Index, Reward in pairs(Misc.OnlineConfig) do
                    local Left = (tonumber(Reward.Time) or 0) - Online
                    if not (Claimed[Index] or Claimed[tostring(Index)]) and Left > 0 and (not Next or Left < Next) then Next = Left end
                end
                Misc.ShowOnline(Next)
            end)
        end
        if not Misc.IndexRunning then pcall(Misc.ShowIndex) end
        task.wait(5)
    end
end)

---- ============ Priority ============ ----
--
-- แบบหน้า Priority ของ Slayer2 (ผู้ใช้ 2026-10-02): ระบบที่ขยับตัวละคร (Tower / Forge / Stage / Train) เปิดพร้อมกันได้
-- ตัวที่อยู่สูงสุดที่ "มีงาน" ตอนนี้ได้ตา ตัวอื่นพักโดยไม่แตะตัวละคร / ไม่มีงาน = ลงไปตัวถัดไป
--   Tower มีงาน = อยู่ในหอ / มีตั๋ว, Forge = แร่พอ forge, Stage / Train = มีงานเสมอ (เป็นตัวรองรับ)
-- ทำงานค้างที่ทิ้งกลางทางไม่ได้ = ถือตาไว้จนจบไม่สนลำดับ: อยู่ในหอแล้ว (ออกกลางทาง = เสียรอบ) / กำลังตีของที่โต๊ะ Forge
-- Stage สลับระหว่างตัว: ตีมอนที่ล็อกอยู่ให้ตายก่อนค่อยปล่อยตา (ยกเว้นงานที่ถือตาไว้ = ปล่อยทันที)
-- ระบบที่ไม่ขยับตัว (Rebirth / Enhance / Enchant / Sell / Upgrade / Equip / Claim) รันคู่กันได้เสมอ ไม่อยู่ในหน้านี้

Runner.Default = { "Tower", "Forge", "Stage", "Train" }
Runner.Labels = { Tower = "Frostbound Tower", Forge = "Auto Forge", Stage = "Auto Stage", Train = "Auto Train" }
Runner.Locked = nil
Runner.ForgeCache = { At = 0, Ready = false }

function Runner.Label(Mode)
    return Runner.Labels[Mode] or tostring(Mode or "-")
end

function Runner.Order()
    local Saved = getgenv().ConfigurationTable.Priority
    local List, Seen = { }, { }
    for _, Mode in ipairs(type(Saved) == "table" and Saved or { }) do
        if Runner.Labels[Mode] and not Seen[Mode] then Seen[Mode] = true table.insert(List, Mode) end
    end
    for Index, Mode in ipairs(Runner.Default) do
        if not Seen[Mode] then table.insert(List, math.min(Index, #List + 1), Mode) end
    end
    return List
end

-- งานที่ทิ้งกลางทางไม่ได้ (ถือตาไว้ไม่สนลำดับ)
function Runner.Committed()
    if Runner.Locked then return Runner.Locked end
    if Tower.Running and getgenv().ConfigurationTable.TowerAutoEnter and (Tower.Inside() or Tower.Entering) then return "Tower" end
    return nil
end

function Runner.Ready(Mode)
    local Config = getgenv().ConfigurationTable
    if Mode == "Tower" then
        return Tower.Running and Config.TowerAutoEnter == true and Tower.Ready()
    elseif Mode == "Forge" then
        if not (Forge.Running and Config.AutoForge) then return false end
        -- Forge.Pick ไล่กระเป๋าทั้งใบ - แคช 2 วิ (Stage ถามทุก 0.1 วิ)
        if os.clock() - Runner.ForgeCache.At > 2 then
            Runner.ForgeCache.At = os.clock()
            Runner.ForgeCache.Ready = Forge.Pick(math.clamp(tonumber(Config.ForgeOreCount) or 4, 4, 13)) ~= nil
        end
        return Runner.ForgeCache.Ready
    elseif Mode == "Stage" then
        return Stage.Running and Config.AutoStage == true
    elseif Mode == "Train" then
        return Train.Running and Config.AutoTrain == true
    end
    return false
end

-- ระบบที่ได้ตาตอนนี้ (nil = ไม่มีระบบไหนมีงาน)
function Runner.Current()
    local Committed = Runner.Committed()
    if Committed then return Committed end
    for _, Mode in ipairs(Runner.Order()) do
        local Ok, Ready = pcall(Runner.Ready, Mode)
        if Ok and Ready then return Mode end
    end
    return nil
end

-- ตาของ Mode ไหม: true / false, ระบบที่ได้ตา
function Runner.Turn(Mode)
    local Current = Runner.Current()
    return Current == nil or Current == Mode, Current
end

local PriorityPage = Window:Page({ Name = "Priority", Icon = "list-ordered", Columns = 2 })

local PrioritySection = PriorityPage:Section({
    Name = "Priority",
    Side = 1
})

local PriorityInfoSection = PriorityPage:Section({
    Name = "Status",
    Side = 2
})

Runner.Status = PriorityInfoSection:Status({
    Name = "Priority Status",
    Rows = { "Now", "Frostbound Tower", "Auto Forge", "Auto Stage", "Auto Train" }
})

do
    local Items, ModeOf = { }, { }
    for _, Mode in ipairs(Runner.Default) do
        table.insert(Items, Runner.Labels[Mode])
        ModeOf[Runner.Labels[Mode]] = Mode
    end

    local Slots, Syncing = { }, false
    local function Sync()
        Syncing = true
        local Order = Runner.Order()
        for Index, Dropdown in ipairs(Slots) do
            pcall(function() Dropdown:Refresh(Items, Runner.Labels[Order[Index]]) end)
        end
        Syncing = false
    end

    -- เลือกระบบในช่องไหน = สลับที่กับช่องที่ระบบนั้นอยู่เดิม (ไม่มีซ้ำ/หาย)
    for Index, Rank in ipairs({ "1st", "2nd", "3rd", "4th" }) do
        Slots[Index] = PrioritySection:Dropdown({
            Name = Rank,
            Flag = "LTFPriority" .. Index,
            Items = Items,
            KeepOrder = true,
            Default = Runner.Labels[Runner.Order()[Index]],
            Multi = false,
            Callback = function(Value)
                if Syncing or type(Value) ~= "string" or not ModeOf[Value] then return end
                local Order = Runner.Order()
                local From = table.find(Order, ModeOf[Value])
                if not From or From == Index then return end
                Order[From], Order[Index] = Order[Index], Order[From]
                getgenv().ConfigurationTable.Priority = Order
                SaveConfiguration()
                task.defer(Sync)
            end
        })
    end

    PrioritySection:Button({
        Name = "Reset Order",
        Callback = function()
            getgenv().ConfigurationTable.Priority = table.clone(Runner.Default)
            SaveConfiguration()
            Sync()
        end
    })
end

PriorityInfoSection:Guide("How to use", {
    "Turn on as many as you want in their own tabs - this page decides which one moves your character",
    "The highest one that has something to do goes first; the rest wait without touching your character",
    "Tower has work while you hold a ticket, Forge while you have enough ores; Stage and Train always have work",
    "A Tower run and a forge trip always finish first; Stage finishes the enemy it is hitting before it hands over",
    "Rebirth, Enhance, Enchant, Sell, Upgrade, Equip and claims run alongside everything",
})

task.spawn(function()
    local Token = SessionToken
    while getgenv().ValkyrieSession == Token do
        pcall(function()
            local Current = Runner.Current()
            Runner.Status:SetState(Current and "Running" or "Idle")
            Runner.Status:Set("Now", Current and Runner.Label(Current) or "Nothing has work")
            for _, Mode in ipairs(Runner.Default) do
                local Config = getgenv().ConfigurationTable
                local On = ({ Tower = Config.TowerAutoEnter, Forge = Config.AutoForge, Stage = Config.AutoStage, Train = Config.AutoTrain })[Mode]
                local Rank = table.find(Runner.Order(), Mode)
                Runner.Status:Set(Runner.Label(Mode), string.format("#%d - %s", Rank or 0,
                    not On and "off" or (Mode == Current and "running") or (Runner.Ready(Mode) and "waiting for its turn") or "nothing to do"))
            end
        end)
        task.wait(1)
    end
end)

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
    Flag = "LTFTheme",
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

do
local AntiAfk = { Focused = true }

TrackConnection(game:GetService("UserInputService").WindowFocused:Connect(function()
    AntiAfk.Focused = true
end))

TrackConnection(game:GetService("UserInputService").WindowFocusReleased:Connect(function()
    AntiAfk.Focused = false
end))

local VirtualUser = game:GetService("VirtualUser")

local function AntiAfkStep()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

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
    Flag = "LTFAntiAFK",
    Default = getgenv().ConfigurationTable.AntiAFK,
    Callback = function(Value)
        getgenv().ConfigurationTable.AntiAFK = Value
        SaveConfiguration()

        if Value then
            if AntiAfk.Connection then return end

            AntiAfk.Connection = TrackConnection(LocalPlayer.Idled:Connect(function()
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
    Flag = "LTFAutoRejoin",
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
    Flag = "LTFAutoExecutor",
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
    Flag = "LTFMinimizeBind",
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

local FPSSection = ConfigPage:Section({
    Name = "FPS",
    Description = "Framerate and screen",
    Icon = "110273524101447",
    Side = 2
})

FPSSection:Slider({
    Name = "FPS Value",
    Flag = "LTFFPSValue",
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
    Flag = "LTFFPSLock",
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
    Flag = "LTFLanguage",
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

---- ============ Cleanup ============ ----

getgenv().ValkyrieCleanup = function()
    getgenv().ValkyrieSession = nil

    pcall(Train.Stop)
    pcall(Rebirth.Stop)
    pcall(Enhant.Stop)
    pcall(Enchant.Stop)
    pcall(Forge.Stop)
    pcall(Stage.Stop)
    pcall(Tower.Stop)
    pcall(Sell.Stop)
    pcall(Upgrade.Stop)
    pcall(Equip.Stop)
    Misc.OnlineRunning = false
    Misc.IndexRunning = false
    pcall(Movement.Release)

    for _, Connection in ipairs(SessionConnections) do
        pcall(function() Connection:Disconnect() end)
    end
    table.clear(SessionConnections)

    pcall(function()
        Library:Unload()
    end)

    getgenv().ValkyrieCleanup = nil
end
