pcall(function()
    game.Players.LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
end)

getgenv().ConfigurationTable = {}

local FolderConfiguration = "Valkyrie Hub"
local FolderSettings = "Valkyrie Hub/BSE"
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

local filenameConfiguration = FolderConfiguration .. "/" .. "Setting_BSE_" .. LocalPlayer.Name .. ".json"

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

    -- Auto Farm
    ["AutoBreakEgg"] = false,
    ["FarmBestZone"] = true,          -- โซนสูงสุดที่ดาเมจ Pickaxe ทุบไข่แตกไว (ปิด = ใช้ FarmZone - วาร์ปได้ทุกโซน)
    ["FarmZone"] = "Zone 1 (Common)",
    ["FarmEggTypes"] = { },           -- ว่าง = ไข่ทุกแบบ
    ["FarmEggPriority"] = "Lowest Health",   -- Lowest Health / Highest Luck / Heaviest / Nearest
    ["AutoCollect"] = false,
    ["CollectRarities"] = { },        -- ว่าง = ทุก rarity
    ["CollectMinWeight"] = "",        -- kg ("" = ไม่กรอง, รับ 2K / 1.5M)
    ["CollectMinCash"] = "",          -- เงิน/วิ ของสัตว์ตอนวางในคอก ("" = ไม่กรอง)
    ["AutoPlace"] = false,            -- Auto Equip Best (หน้า Pet & Egg) - ชื่อ key เดิมจากตอนอยู่หน้า Auto Farm
    ["AutoTitanic"] = false,

    -- Pet & Egg
    ["AutoMerge"] = false,
    ["MergeRarities"] = { "Common", "Uncommon" },
    ["AutoGrowEggs"] = false,
    ["AutoOpenEggs"] = false,
    ["AutoSell"] = false,
    ["SellRarities"] = { "Common" },  -- ว่าง = ไม่ขาย
    ["SellNameMode"] = "Any Name",    -- Any Name / Only Selected Names / All Except Selected Names
    ["SellNames"] = { },
    ["SellPriceMin"] = "",            -- ราคาขายต่อตัว ("" = ไม่จำกัด, รับ 2K / 1.5M)
    ["SellPriceMax"] = "",
    ["FavoriteAnimals"] = { },        -- ชื่อสัตว์ที่ไม่ขาย / ไม่เอาไป merge

    -- Movement & Tween
    ["TweenSpeed"] = 300,

    -- Steal & PVP
    ["BatAura"] = false,
    ["BatHunt"] = false,              -- วาร์ปไปหาคนถือสัตว์ทุกระยะ (ปิด = ตีแค่คนในระยะไม้)
    ["BatMinCash"] = "",              -- ตีเฉพาะคนที่ถือตัวเงิน/วิ อย่างน้อยเท่านี้
    ["AutoSnipe"] = false,
    ["SnipeRarities"] = { },
    ["SnipeMinCash"] = "",

    -- Treadmill
    ["AutoTrainSpeed"] = false,
    ["AutoUnlockTreadmill"] = false,
    ["AutoUpgradeTreadmill"] = false,

    -- Auto Upgrade
    ["AutoBuyPickaxe"] = false,
    ["AutoUpgradePen"] = false,
    ["AutoUpgradeSatchel"] = false,
    ["AutoBuyTrails"] = false,
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
        return "BSEAuto" .. AutoFlag
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

        -- ช่องพิมพ์ข้อความ
        -- Milenium ตั้ง LayoutOrder -1 = ขึ้นบนสุดของกล่องเสมอ -> คืนเป็น 0 ให้อยู่ตามลำดับที่สร้างเหมือน element อื่น
        function Section:Textbox(Box)
            local Handle = Item:textbox({
                name = Box.Name or "TextBox",
                placeholder = Box.Placeholder,
                default = Box.Default or "",
                flag = FlagOf(Box.Flag),
                callback = function(Text)
                    if Box.Callback then Box.Callback(Text) end
                end
            })
            pcall(function() Handle.items[ "textbox" ].LayoutOrder = 0 end)
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
            gameInfo = "Break and Steal an Egg",
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
    { "^Error: (.+)$", "ผิดพลาด: %1" },
}

local function ApplyLanguage(Name)
    Library:SetLocale(LocaleByLanguage[Name] or "en")
end

-- คำแปลไทยของ UI - Milenium จำข้อความอังกฤษเดิมแล้วสลับตามภาษาที่เลือก
Library:AddLanguage("th", {
    ["General"] = "ทั่วไป",
    ["Auto Farm"] = "ฟาร์มอัตโนมัติ",
    ["Egg"] = "ไข่",
    ["Auto Break Egg"] = "ทุบไข่อัตโนมัติ",
    ["Break eggs in the farm zone with your pickaxe"] = "ทุบไข่ในโซนที่ฟาร์มด้วยอีเตอร์",
    ["Auto Best Zone"] = "โซนดีสุดอัตโนมัติ",
    ["Use the highest zone your pickaxe damage breaks eggs fast in"] = "ใช้โซนสูงสุดที่ดาเมจอีเตอร์ทุบไข่แตกไว",
    ["Zone"] = "โซน",
    ["Used when Auto Best Zone is off - any zone works"] = "ใช้ตอนปิดโซนดีสุดอัตโนมัติ - เลือกได้ทุกโซน",
    ["Egg Types"] = "ชนิดไข่",
    ["None selected = any egg"] = "ไม่เลือก = ไข่ทุกแบบ",
    ["Egg Priority"] = "ลำดับไข่",
    ["Lowest Health"] = "เลือดน้อยสุด",
    ["Highest Luck"] = "โชคสูงสุด",
    ["Heaviest"] = "หนักสุด",
    ["Nearest"] = "ใกล้สุด",
    ["Titanic Egg"] = "ไข่ Titanic",
    ["Auto Titanic Egg"] = "ทุบไข่ Titanic อัตโนมัติ",
    ["Break the Titanic egg first whenever it spawns"] = "ไข่ Titanic เกิดเมื่อไหร่ไปทุบก่อนอย่างอื่น",
    ["Animals"] = "สัตว์",
    ["Auto Collect Animal"] = "เก็บสัตว์อัตโนมัติ",
    ["Steal hatched animals that match the filters"] = "ขโมยสัตว์ที่ฟักออกมาตามตัวกรอง",
    ["Rarities"] = "ระดับความหายาก",
    ["None selected = any rarity"] = "ไม่เลือก = ทุกระดับ",
    ["Min Weight (kg)"] = "น้ำหนักขั้นต่ำ (kg)",
    ["Min Cash/s"] = "เงินขั้นต่ำ/วิ",
    ["Any - e.g. 500 / 1.5K"] = "ไม่กรอง - เช่น 500 / 1.5K",
    ["Any - e.g. 100 / 2K / 1.5M"] = "ไม่กรอง - เช่น 100 / 2K / 1.5M",
    ["Steal hatched animals that match the filters - goes home to bank them when the satchel is full"] = "ขโมยสัตว์ที่ฟักออกมาตามตัวกรอง - กระเป๋าเต็มแล้วกลับไปฝากที่ฐาน",
    ["Pet & Egg"] = "สัตว์และไข่",
    ["Pets"] = "สัตว์",
    ["Auto Equip Best"] = "ใส่ตัวดีสุดอัตโนมัติ",
    ["Keep the best cash/s animals in your pen (game Equip Best)"] = "วางตัวที่เงิน/วิ สูงสุดไว้ในคอก (ปุ่ม Equip Best ของเกม)",
    ["Merge"] = "รวมร่าง",
    ["Auto Merge"] = "รวมร่างอัตโนมัติ",
    ["Merge 3 of the same animal from your backpack into an egg"] = "รวมสัตว์ชนิดเดียวกัน 3 ตัวในกระเป๋าเป็นไข่",
    ["Merge Rarities"] = "ระดับที่รวมร่าง",
    ["Eggs"] = "ไข่",
    ["Auto Grow Eggs"] = "ปลูกไข่อัตโนมัติ",
    ["Place merged eggs in your plot so they start growing"] = "วางไข่ที่รวมร่างแล้วในฐานให้เริ่มโต",
    ["Auto Open Eggs"] = "เปิดไข่อัตโนมัติ",
    ["Hatch eggs as soon as they finish growing"] = "ฟักไข่ทันทีที่โตเสร็จ",
    ["Sell"] = "ขาย",
    ["Auto Sell"] = "ขายอัตโนมัติ",
    ["Sell backpack animals of the chosen rarities - never ones better than your pen"] = "ขายสัตว์ในกระเป๋าตามระดับที่เลือก - ไม่ขายตัวที่ดีกว่าในคอก",
    ["Sell Rarities"] = "ระดับที่ขาย",
    ["None selected = sell nothing"] = "ไม่เลือก = ไม่ขาย",
    ["Favorite Animals"] = "สัตว์โปรด",
    ["Name Filter"] = "กรองตามชื่อ",
    ["Any Name"] = "ทุกชื่อ",
    ["Only Selected Names"] = "เฉพาะชื่อที่เลือก",
    ["All Except Selected Names"] = "ทุกชื่อยกเว้นที่เลือก",
    ["Sell Names"] = "ชื่อที่ใช้กรอง",
    ["Used by Only Selected / All Except Selected"] = "ใช้กับ เฉพาะชื่อที่เลือก / ทุกชื่อยกเว้นที่เลือก",
    ["Min Price"] = "ราคาต่ำสุด",
    ["Max Price"] = "ราคาสูงสุด",
    ["Any - e.g. 500 / 2K / 1.5M"] = "ไม่จำกัด - เช่น 500 / 2K / 1.5M",
    ["Never sold or merged"] = "ไม่ขายและไม่เอาไปรวมร่าง",
    ["Steal & PVP"] = "ขโมยและ PVP",
    ["Bat"] = "ไม้ตี",
    ["Bat Aura"] = "ออร่าไม้ตี",
    ["Hit players carrying an animal so it drops, then grab it"] = "ตีผู้เล่นที่ถือสัตว์ให้หล่น แล้วเก็บมาเอง",
    ["Hunt Carriers"] = "ไล่ล่าคนถือสัตว์",
    ["Teleport to carriers anywhere instead of only hitting ones in range"] = "วาร์ปไปหาคนถือสัตว์ทุกที่ แทนการตีแค่คนในระยะ",
    ["Snipe"] = "แย่งสัตว์",
    ["Snipe Pickups"] = "แย่งสัตว์อัตโนมัติ",
    ["Wait at eggs other players break and grab the animal the moment it appears"] = "ไปรอที่ไข่ที่คนอื่นทุบแตก แล้วคว้าสัตว์ทันทีที่โผล่",
    ["Snipe Rarities"] = "ระดับที่แย่ง",
    ["Snipe Min Cash/s"] = "เงินขั้นต่ำ/วิ ที่แย่ง",
    ["Auto Treadmill"] = "ลู่วิ่ง",
    ["Auto Upgrade"] = "อัปเกรดอัตโนมัติ",
    ["Upgrade"] = "อัปเกรด",
    ["Auto Buy Pickaxe"] = "ซื้ออีเตอร์อัตโนมัติ",
    ["Buy the best pickaxe you can afford (18 tiers) and keep it equipped"] = "ซื้ออีเตอร์ที่ดีสุดที่เงินพอ (18 ขั้น) และใส่ตัวดีสุดไว้เสมอ",
    ["Auto Upgrade Pen"] = "อัปเกรดคอกอัตโนมัติ",
    ["Upgrade your pen for more animal slots (9 levels)"] = "อัปเกรดคอกให้วางสัตว์ได้มากขึ้น (9 ระดับ)",
    ["Auto Upgrade Satchel"] = "อัปเกรดกระเป๋าอัตโนมัติ",
    ["Carry more animals (6 tiers) - needs a satchel station in the map"] = "ถือสัตว์ได้มากขึ้น (6 ขั้น) - ต้องมีสถานีกระเป๋าในแมพ",
    ["Auto Buy Trails"] = "ซื้อเทรลอัตโนมัติ",
    ["Buy the best trail you can afford and keep it equipped"] = "ซื้อเทรลที่ดีสุดที่เงินพอ และใส่ตัวดีสุดไว้เสมอ",
    ["Auto Train Speed"] = "ฝึกความเร็วอัตโนมัติ",
    ["Run on your plot treadmill whenever Auto Farm has nothing to do"] = "วิ่งบนลู่ในฐานเมื่อฟาร์มอัตโนมัติไม่มีอะไรทำ",
    ["Auto Unlock Treadmill"] = "ปลดล็อกลู่วิ่งอัตโนมัติ",
    ["Unlock the treadmill when you have $100"] = "ปลดล็อกลู่วิ่งเมื่อมีเงิน $100",
    ["Auto Upgrade Treadmill"] = "อัปเกรดลู่วิ่งอัตโนมัติ",
    ["Upgrade whenever you can afford the next level (9 levels, x1 to x256)"] = "อัปเกรดทุกครั้งที่เงินพอระดับถัดไป (9 ระดับ x1 ถึง x256)",
    ["Finish the game tutorial first - upgrades are blocked until then"] = "เล่น tutorial ของเกมให้จบก่อน - ระหว่างนี้เกมไม่ให้อัปเกรด",
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

---- ============ Game Data (วัดสดผ่าน dex 2026-10-04, place 114326934417838) ============ ----
--
-- remote ทุกตัวอยู่ตรง ReplicatedStorage (ไม่มีโฟลเดอร์ย่อย) - conch_networking = ของแอดมิน ไม่ใช้
-- config ของเกม = ModuleScript ใน ReplicatedStorage.Shared (ZonesConfig, PickaxeConfig, SatchelConfig ...)
-- โลก: workspace.Build.ZoneBuilds.Zone<n> (ไข่ใน .Eggs, ยาม ZoneGuard) / ฐานเรา = workspace.Plots.Base_<n> ที่
-- attr OwnerUserId ตรงกับเรา (ลูก: UpgradeBoard, PlacedAnimals, SpawnPoint, Hitbox = จุดปลอดภัย)
-- ค่าผู้เล่นเป็น attribute บน LocalPlayer: Cash, CashPerSecond, SpeedPower, SatchelCapacity/Tier, PickaxeTier,
-- OwnedPickaxes, MergeCooldownEndsAt, TutorialActive/TutorialStage ...
-- args ของ remote ที่วัดแล้ว: ดูหัวส่วน Auto Farm

local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared", 10)

-- ReplicatedStorage.<ชื่อ> - เรียก Remotes.EggHitRequest แล้วหาให้ตอนใช้ครั้งแรก (ยังไม่โหลด = nil)
local Remotes = setmetatable({ }, {
    __index = function(Self, Name)
        local Remote = ReplicatedStorage:FindFirstChild(Name)
        if Remote then rawset(Self, Name, Remote) end
        return Remote
    end
})

-- ชื่อ remote ที่วัดได้ (ไว้ดูอ้างอิง / เช็คว่าเกมเปลี่ยนชื่อไหม)
local RemoteNames = {
    -- ไข่ / สัตว์
    "EggHitRequest", "EggHitLanded", "EggHitRejected", "PlaceAnimalRemote", "AnimalBankedRemote",
    "DropCarriedRemote", "CatchFlingRemote", "MergeMachineRemote", "BatHitRequest",
    -- ร้าน / อัปเกรด
    "PickaxeShopRequest", "TrailShopRequest", "UpgradePlotRequest", "UpgradeTreadmillRequest",
    "UnlockTreadmillRequest", "BackpackSellRemote",
    -- ความเร็ว
    "SpeedGainRemote", "TreadmillSessionRemote",
    -- รางวัล / อื่น ๆ
    "PetsInventoryRemote", "IndexRemote", "OfflineRewardRemote", "GroupRewardRemote", "DiscordRewardRemote",
    "AntiAfkRejoinRemote", "SettingsRemote", "Notify",
}

-- CollectionService tag ของเกม
local Tags = {
    Egg = "BreakableEgg",          -- MeshPart "Egg" attrs: Health / MaxHealth / EggType / ZoneIndex / WeightKg / Broken
    Pickup = "AnimalPickup",       -- สัตว์ที่หล่น (ใครก็เก็บได้) attrs: Rarity / WeightKg / DespawnAtServerTime
    Placed = "PlacedAnimal",       -- สัตว์ในฐาน attrs: OwnerUserId / CashPerSecond
    Guard = "ZoneGuard",           -- ยามโซน attrs: ChaseState / CaughtRequiredPower
    MergePrompt = "MergeEggPrompt",
    AnimalTool = "AnimalTool",     -- สัตว์ที่ถืออยู่ (Tool)
}

-- require โมดูลใน Shared แบบจำผล (require ไม่ได้ = nil)
local SharedCache = { }

local function RequireShared(Name)
    if SharedCache[Name] ~= nil then return SharedCache[Name] or nil end

    local Module = Shared and Shared:FindFirstChild(Name)
    local Ok, Result = false, nil
    if Module then Ok, Result = pcall(require, Module) end

    SharedCache[Name] = (Ok and Result) or false
    return SharedCache[Name] or nil
end

-- โซน 1-9: เข้าได้เมื่อ SpeedPower >= RequiredPower (ไม่ถึง = ยามไล่จับแล้วเหวี่ยงออก ของที่ถือหล่น)
-- ค่าสำรองตรงกับ ZonesConfig.Zones ตอนเขียน
local Zones = {
    { Id = "Zone1", Rarity = "Common",    RequiredPower = 5 },
    { Id = "Zone2", Rarity = "Uncommon",  RequiredPower = 1e3 },
    { Id = "Zone3", Rarity = "Rare",      RequiredPower = 5e4 },
    { Id = "Zone4", Rarity = "Epic",      RequiredPower = 7.5e5 },
    { Id = "Zone5", Rarity = "Legendary", RequiredPower = 1.2e7 },
    { Id = "Zone6", Rarity = "Mythic",    RequiredPower = 1.5e8 },
    { Id = "Zone7", Rarity = "Divine",    RequiredPower = 1e9 },
    { Id = "Zone8", Rarity = "Cosmic",    RequiredPower = 5e9 },
    { Id = "Zone9", Rarity = "Secret",    RequiredPower = 2.5e10 },
}

do
    local Config = RequireShared("ZonesConfig")
    if type(Config) == "table" and type(Config.Zones) == "table" and #Config.Zones > 0 then
        local Loaded = { }
        for Index, Zone in ipairs(Config.Zones) do
            Loaded[Index] = {
                Id = Zone.Id or ("Zone" .. Index),
                Rarity = Zone.Rarity or tostring(Index),
                RequiredPower = tonumber(Zone.RequiredPower) or 0,
            }
        end
        Zones = Loaded
    end
end

---- ตัวช่วยทั่วไป ----

local function GetCharacter()
    return LocalPlayer.Character
end

local function GetRoot()
    local Character = LocalPlayer.Character
    return Character and Character:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local Character = LocalPlayer.Character
    return Character and Character:FindFirstChildOfClass("Humanoid")
end

local function IsAlive()
    local Humanoid = GetHumanoid()
    return Humanoid ~= nil and Humanoid.Health > 0 and GetRoot() ~= nil
end

-- attribute ของ LocalPlayer (ไม่มี = Default)
local function GetStat(Name, Default)
    local Value = LocalPlayer:GetAttribute(Name)
    if Value == nil then return Default end
    return Value
end

-- 1234567 -> 1.23M
local function FormatNumber(Value)
    Value = tonumber(Value) or 0
    local Suffixes = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }
    local Index = 1
    while math.abs(Value) >= 1000 and Index < #Suffixes do
        Value = Value / 1000
        Index = Index + 1
    end
    if Index == 1 then return tostring(math.floor(Value)) end
    return (string.format("%.2f", Value):gsub("%.?0+$", "")) .. Suffixes[Index]
end

-- ฐานของเรา (workspace.Plots.Base_<n>) จำไว้ เช็คซ้ำว่ายังเป็นของเรา
local MyPlot = nil

local function GetMyPlot()
    if MyPlot and MyPlot.Parent and MyPlot:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
        return MyPlot
    end

    MyPlot = nil
    local Plots = workspace:FindFirstChild("Plots")
    if not Plots then return nil end

    for _, Plot in ipairs(Plots:GetChildren()) do
        if Plot:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
            MyPlot = Plot
            break
        end
    end

    return MyPlot
end

-- โมเดลโซน workspace.Build.ZoneBuilds.Zone<n>
local function GetZoneFolder(Index)
    local Build = workspace:FindFirstChild("Build")
    local Builds = Build and Build:FindFirstChild("ZoneBuilds")
    local Zone = Zones[Index]
    return Builds and Zone and Builds:FindFirstChild(Zone.Id)
end

-- ไข่ที่ยังไม่แตก (ZoneIndex = nil = ทุกโซน)
local function GetEggs(ZoneIndex)
    local List = { }
    for _, Egg in ipairs(CollectionService:GetTagged(Tags.Egg)) do
        if Egg:IsDescendantOf(workspace) and not Egg:GetAttribute("Broken")
            and (ZoneIndex == nil or Egg:GetAttribute("ZoneIndex") == ZoneIndex) then
            table.insert(List, Egg)
        end
    end
    return List
end

---- ============ Treadmill session (ใช้ร่วมกับ Auto Farm) ============ ----
--
-- ยืนบนสายพานลู่วิ่งในฐาน = server เริ่ม session เอง: TreadmillSessionRemote ส่งเลข + CFrame มา (ดูดตัวไปกลางลู่)
-- แล้ว SpeedGainRemote(ที่ได้, SpeedPower ใหม่) ทุก 1 วิ (วัดสด ระดับ 1 x1: ~+5/วิ)
-- ระหว่าง session ตัวถูกล็อกไว้บนลู่ วาร์ปออกไม่หลุด (เด้งกลับ) - ออก = TreadmillSessionRemote:FireServer()
-- (ตัวเดียวกับที่เกมยิงตอนกดกระโดด) แล้ว server ส่ง nil กลับมา = จบ session

local Treadmill = {
    SessionOn = false,     -- ได้เลข session ล่าสุด (ยังไม่ได้ nil)
    LastGain = 0,          -- เวลาที่ได้ SpeedGainRemote ล่าสุด (รันสคริปต์ตอนอยู่บนลู่แล้ว = ไม่เห็นตอนเริ่ม)
}

if Remotes.TreadmillSessionRemote then
    TrackConnection(Remotes.TreadmillSessionRemote.OnClientEvent:Connect(function(Value)
        Treadmill.SessionOn = typeof(Value) == "number"
        if not Treadmill.SessionOn then Treadmill.LastGain = 0 end
    end))
end

if Remotes.SpeedGainRemote then
    TrackConnection(Remotes.SpeedGainRemote.OnClientEvent:Connect(function()
        Treadmill.LastGain = os.clock()
    end))
end

function Treadmill.Active()
    return Treadmill.SessionOn or os.clock() - Treadmill.LastGain < 2.5
end

function Treadmill.EndSession()
    if not (Treadmill.Active() and Remotes.TreadmillSessionRemote) then return end

    Remotes.TreadmillSessionRemote:FireServer()
    Treadmill.SessionOn = false
    Treadmill.LastGain = 0
    task.wait(0.3)
end

---- ============ Auto Farm ============ ----
--
-- วัดสดผ่าน dex 2026-10-04:
-- ทุบไข่ = Remotes.EggHitRequest:FireServer(ไข่) (ไข่ = MeshPart tag BreakableEgg) - server เช็ค:
--   ต้องถือ Pickaxe (EggConfig.UnequipHitGrace 0.75 วิหลังเก็บ) / ระยะจากผิวไข่ <= EggConfig.HitRange 8 (ไกล = EggHitRejected)
--   คูลดาวน์ EggConfig.HitCooldown 0.35 (ยิงทุก 0.38 วิ 12 ครั้ง ไม่โดน reject) / ดาเมจต่อครั้ง = PickaxeConfig.GetDamage(tier)
-- ไข่แตก = attr Hatching + HatchBreakerUserId (EggTargeting.IsLive: ไม่ Broken / Hatching / Despawning)
--   -> ~5 วิ สัตว์โผล่ใน workspace.AnimalPickups (Model attrs Rarity / WeightKg / ZoneId / DespawnAtServerTime /
--   ReservedUserId = คนทุบ) / ทุบโซนเกิน Speed ได้ ยามไม่ไล่ (ไล่เฉพาะคนถือสัตว์)
-- เก็บสัตว์ = fireproximityprompt(StealPrompt) - prompt ไม่ได้อยู่ในตัวสัตว์ อยู่ใน workspace.PromptAnchor (Part วางตรง
--   ตัวสัตว์ ห่าง 1-4 studs หาด้วยระยะใกล้สุด) / attr ReservedUserId ของคนอื่น = เกมปิด prompt ให้เรา
--   เก็บแล้ว: attr ผู้เล่น Carrying / CarryCount / BeingChased = true -> ยามโซนไล่ (โซน 7 จับได้ใน ~2.4 วิ
--   = เหวี่ยง + สัตว์หลุด) / Satchel เต็ม = CarryCount >= SatchelCapacity
-- เข้า Hitbox ของฐาน = เกมฝากสัตว์เอง (AnimalBankedRemote ใน 0.2 วิ) -> กลายเป็น Tool (tag AnimalTool) ใน Backpack
-- วางใน Pen แบบ Best = Remotes.PetsInventoryRemote:FireServer("EquipBest", nil) (ปุ่ม Equip Best ของหน้า Pets)
--   server เลือกตัว cash/s สูงสุดลงคอกเอง (วัดสด: คอกเต็ม 8/8 + Lizard 4548/s ใน Backpack -> Anteater 3/s ถูกเอา
--   ออกกลับ Backpack แล้ว Lizard ลงแทน) / ฐานรับได้ attr MaxAnimals (AnimalsPlaced = วางแล้ว)
--   (วางทีละตัว = PlaceAnimalRemote:FireServer(tool, จุดในกล่อง Hitbox, ลำดับ) - ไม่ใช้แล้ว)
-- เงิน/วิ ของสัตว์ = EggRewards.PlacedCashPerSecond(AnimalName, SizeMult, Mutation, WeightKg, Variant) (attr ของ
--   pickup / tool / สัตว์ในคอก) - ตรงกับ attr CashPerSecond ของสัตว์ในคอก 8/8 ตัว
-- Titanic: workspace attr TitanicNextAt / TitanicEndsAt / TitanicZoneIndex / TitanicEggName, ไข่ tag TitanicEgg
--   (TitanicEggConfig: ทุก 30 นาที อยู่ 600 วิ HP x10, โซน 2 ขึ้นไป) - ยังไม่เห็นเกิดจริง อ่านจาก config

local Farm = {
    Running = false,
    Thread = nil,
    Target = nil,          -- ไข่ที่กำลังทุบ (ทุบจนแตกค่อยเปลี่ยน)
    LastHit = 0,
    ChasedSince = nil,
    BestRetryAt = 0,       -- EquipBest แล้วคอกไม่เปลี่ยน = พักไม่วนกลับฐานซ้ำ
    BusyUntil = 0,         -- ฟาร์มกำลังใช้ตัวละคร (ทุบ / เก็บ / กลับฐาน) - Auto Train รอจนพ้นเวลานี้
    GrowRetryAt = 0,       -- วางไข่ merge ไม่ลง = พักไม่วนกลับฐานซ้ำ

    HitInterval = 0.38,    -- EggConfig.HitCooldown 0.35 + เผื่อ
    HitOffset = 2,         -- ยืนห่างผิวไข่ (HitRange 8)
    ChaseLimit = 1.5,      -- ถือสัตว์โดนไล่นานเกินนี้ = กลับฐาน (ยามโซน 7 จับได้ใน ~2.4 วิ)
    PromptRange = 15,      -- PromptAnchor ห่างตัวสัตว์ได้ไม่เกินนี้
    Priorities = { "Lowest Health", "Highest Luck", "Heaviest", "Nearest" },
}

Farm.ZoneNames = { }
for Index, Zone in ipairs(Zones) do
    Farm.ZoneNames[Index] = string.format("Zone %d (%s)", Index, Zone.Rarity)
end

-- rarity ของโซน 1-9 + 2 ขั้นที่มีแค่จาก merge / สัตว์พิเศษ (EggRewards.Pool: Celestial 8 ตัว, Inferno 1 ตัว)
Farm.Rarities = { }
Farm.RarityRank = { }
for Index, Zone in ipairs(Zones) do
    Farm.Rarities[Index] = Zone.Rarity
    Farm.RarityRank[Zone.Rarity] = Index
end
for _, Extra in ipairs({ "Celestial", "Inferno" }) do
    if not Farm.RarityRank[Extra] then
        table.insert(Farm.Rarities, Extra)
        Farm.RarityRank[Extra] = #Farm.Rarities
    end
end

-- ชื่อไข่ทุกแบบจาก EggConfig.Eggs (โหลดไม่ได้ = ไข่ที่เห็นในแมพตอนนี้)
Farm.EggTypes = { }
do
    local Seen = { }
    local Config = RequireShared("EggConfig")
    if type(Config) == "table" and type(Config.Eggs) == "table" then
        for Name in pairs(Config.Eggs) do Seen[Name] = true end
    end
    for _, Egg in ipairs(CollectionService:GetTagged(Tags.Egg)) do
        local Type = Egg:GetAttribute("EggType")
        if type(Type) == "string" then Seen[Type] = true end
    end
    for Name in pairs(Seen) do table.insert(Farm.EggTypes, Name) end
    table.sort(Farm.EggTypes)
end

local function Config()
    return getgenv().ConfigurationTable
end

-- "2K" / "1.5M" / "300" -> ตัวเลข ("" / อ่านไม่ได้ = nil)
local function ParseAmount(Text)
    Text = tostring(Text or ""):gsub("[%s,$]", ""):upper()
    local Number, Suffix = Text:match("^([%d%.]+)(%a*)$")
    Number = tonumber(Number)
    if not Number then return nil end

    local Scale = { [""] = 1, K = 1e3, M = 1e6, B = 1e9, T = 1e12, QA = 1e15, QI = 1e18 }
    return Scale[Suffix] and Number * Scale[Suffix] or nil
end

-- เงิน/วิ ตอนวางในคอก (สูตรเดียวกับเกม) จาก attr ของ pickup / tool / สัตว์ในคอก
function Farm.CashOf(Instance)
    local Name = Instance:GetAttribute("AnimalName")
    local Rewards = RequireShared("EggRewards")
    if type(Name) ~= "string" or type(Rewards) ~= "table" or type(Rewards.PlacedCashPerSecond) ~= "function" then
        return tonumber(Instance:GetAttribute("CashPerSecond")) or 0
    end

    local Ok, Value = pcall(Rewards.PlacedCashPerSecond, Name, Instance:GetAttribute("SizeMult") or 1,
        Instance:GetAttribute("Mutation"), Instance:GetAttribute("WeightKg"), Instance:GetAttribute("Variant"))
    return Ok and tonumber(Value) or 0
end

-- ลิสต์ -> set (ว่าง = nil = ไม่กรอง)
local function SetOf(List)
    if type(List) ~= "table" or #List == 0 then return nil end
    local Set = { }
    for _, Value in ipairs(List) do Set[Value] = true end
    return Set
end

-- ทุกงานที่ขยับตัวละครเรียกก่อนทำ = กันลูปลู่วิ่งดึงตัวกลับระหว่างนั้น
function Farm.MarkBusy()
    Farm.BusyUntil = os.clock() + 1.5
end

function Farm.Busy()
    return Farm.Running and os.clock() < Farm.BusyUntil
end

-- วิ่งไปจุดหมายแทนการวาร์ป (วาร์ปทันทีโดนเตะ) ใช้วิธีเดียวกับ STE.lua:
-- 1) clone Humanoid ใหม่ติด attribute ValkyrieTravelHum = true -> ไม่มีตัวดึงตัวกลับ (leash)
-- 2) ปิดการชนของตัวละครระหว่างวิ่ง (noclip) และสร้าง Valkyrie Platform ใต้เท้า
-- 3) ขยับ Root ทีละเฟรมด้วยความเร็วคงที่ RunSpeed (ไม่เกินเพดานที่วัดแล้ว)
Farm.RunSpeed = 300

local PlatformPart = nil

local function DestroyPlatform()
    if PlatformPart then
        pcall(function() PlatformPart:Destroy() end)
        PlatformPart = nil
    end
end

local function UpdatePlatform(Humanoid, Root)
    if not PlatformPart or not PlatformPart.Parent then
        DestroyPlatform()
        local Part = Instance.new("Part")
        Part.Name = "Valkyrie_Platform"
        Part.Size = Vector3.new(6, 1, 6)
        Part.Anchored = true
        Part.CanCollide = false
        Part.CanQuery = false
        Part.CanTouch = false
        Part.Transparency = 1
        Part.Parent = workspace
        PlatformPart = Part
    end

    local FootY = Root.Position.Y - 3
    PlatformPart.CFrame = CFrame.new(Root.Position.X, FootY - 0.5, Root.Position.Z)
end

local function EnsureTravelHumanoid(Character)
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid or Humanoid:GetAttribute("ValkyrieTravelHum") == true then return end

    local Fresh = Humanoid:Clone()
    Fresh:SetAttribute("ValkyrieTravelHum", true)
    Fresh.Sit = false
    Fresh.PlatformStand = false
    Fresh.AutoRotate = true

    Humanoid:Destroy()
    Fresh.Parent = Character

    -- หยุดท่าทางวิ่ง/เดิน (ไม่ให้ขาขยับขณะ Tween)
    local Animate = Character:FindFirstChild("Animate")
    if Animate and Animate:IsA("LuaSourceContainer") then
        pcall(function()
            Animate.Disabled = true
        end)
    end

    for _, Thing in ipairs(Character:GetDescendants()) do
        if Thing:IsA("LocalScript") and string.find(Thing.Name, "PushBack") then
            pcall(function()
                Thing.Disabled = true
                Thing:Destroy()
            end)
        end
    end

    pcall(function()
        Fresh:ChangeState(Enum.HumanoidStateType.Running)
    end)
end

local function RestoreHumanoid(Character)
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid or Humanoid:GetAttribute("ValkyrieTravelHum") ~= true then return end

    local Fresh = Humanoid:Clone()
    Fresh:SetAttribute("ValkyrieTravelHum", nil)
    Fresh.Sit = false
    Fresh.PlatformStand = false
    Fresh.AutoRotate = true

    Humanoid:Destroy()
    Fresh.Parent = Character

    local Animate = Character:FindFirstChild("Animate")
    if Animate and Animate:IsA("LuaSourceContainer") then
        task.spawn(function()
            pcall(function()
                Animate.Disabled = true
                task.wait()
                Animate.Disabled = false
            end)
        end)
    end

    pcall(function()
        local PlayerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
        local Module = PlayerScripts
            and PlayerScripts:FindFirstChild("PlayerModule")
            and PlayerScripts.PlayerModule:FindFirstChild("ControlModule")

        if Module then
            local Control = require(Module)
            if type(Control) == "table" then
                Control.humanoid = Fresh
            end
        end
    end)

    pcall(function()
        Fresh:ChangeState(Enum.HumanoidStateType.Running)
    end)
end

function Farm.Teleport(Position, LookAt)
    Farm.MarkBusy()
    local Root = GetRoot()
    if not Root then return end

    -- ลู่วิ่งล็อกตัวไว้ ต้องปล่อยก่อนถึงจะวิ่งได้
    Treadmill.EndSession()
    Root = GetRoot()
    local Character = GetCharacter()
    if not (Root and Character) then return end

    EnsureTravelHumanoid(Character)
    Root = GetRoot()
    Character = GetCharacter()
    if not (Root and Character) then return end

    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if Humanoid then
        for _, State in ipairs({ Enum.HumanoidStateType.Freefall, Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Flying }) do
            pcall(function() Humanoid:SetStateEnabled(State, false) end)
        end
        if Humanoid:GetState() ~= Enum.HumanoidStateType.Running then
            pcall(function() Humanoid:ChangeState(Enum.HumanoidStateType.Running) end)
        end
    end

    local Collide = {}
    for _, Part in ipairs(Character:GetDescendants()) do
        if Part:IsA("BasePart") then
            Collide[Part] = Part.CanCollide
        end
    end

    local Speed = math.clamp(tonumber(getgenv().ConfigurationTable.TweenSpeed) or 300, 16, 1000)
    local Done = false
    local Connection
    local Distance = (Position - Root.Position).Magnitude
    local Limit = os.clock() + Distance / math.max(Speed, 1) + 3

    Connection = RunService.Heartbeat:Connect(function(Delta)
        local Now = GetRoot()
        local Current = GetCharacter()
        local CurrentHum = Current and Current:FindFirstChildOfClass("Humanoid")
        if not (Now and Current) then
            Done = true
            return
        end

        for Part in pairs(Collide) do
            if Part.Parent then Part.CanCollide = false end
        end

        if CurrentHum then
            UpdatePlatform(CurrentHum, Now)
        end

        local Offset = Position - Now.Position
        local Remaining = Offset.Magnitude
        if Remaining < 0.5 then
            Done = true
            return
        end

        local CurrentSpeed = math.clamp(tonumber(getgenv().ConfigurationTable.TweenSpeed) or 300, 16, 1000)
        local Step = math.min(CurrentSpeed * Delta, Remaining)
        local Next = Now.Position + Offset.Unit * Step
        local Look = LookAt and Vector3.new(LookAt.X, Next.Y, LookAt.Z) or (Next + Offset)
        Now.CFrame = CFrame.lookAt(Next, Look)
        Now.AssemblyLinearVelocity = Vector3.zero
        Now.AssemblyAngularVelocity = Vector3.zero
    end)

    while not Done and os.clock() < Limit do
        task.wait()
    end
    Connection:Disconnect()
    DestroyPlatform()

    for Part, Was in pairs(Collide) do
        if Part.Parent then Part.CanCollide = Was end
    end

    if Humanoid then
        for _, State in ipairs({ Enum.HumanoidStateType.Freefall, Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Flying }) do
            pcall(function() Humanoid:SetStateEnabled(State, true) end)
        end
    end

    local Final = GetRoot()
    if Final then
        Final.AssemblyLinearVelocity = Vector3.zero
    end

    RestoreHumanoid(Character)
end

function Farm.Carry()
    return tonumber(GetStat("CarryCount", 0)) or 0, tonumber(GetStat("SatchelCapacity", 1)) or 1
end

---- ไข่ ----

local function EggIsLive(Egg)
    return Egg ~= nil and Egg.Parent ~= nil and not (Egg:GetAttribute("Broken") or Egg:GetAttribute("Hatching")
        or Egg:GetAttribute("Despawning"))
end

-- ตัวที่ยิง remote ได้ = ชิ้นที่มี tag BreakableEgg (tag TitanicEgg อาจติดที่ Model)
local function EggPart(Instance)
    if Instance:IsA("BasePart") then return Instance end
    for _, Child in ipairs(Instance:GetDescendants()) do
        if Child:IsA("BasePart") and CollectionService:HasTag(Child, Tags.Egg) then return Child end
    end
    return nil
end

-- ดาเมจต่อครั้งของ Pickaxe ที่ใส่ (ตัวเดียวกับที่ PickaxeController ส่งให้ EggLocalHits: tier ของ tool ก่อน แล้ว attr ผู้เล่น)
function Farm.Damage()
    local Pickaxe = RequireShared("PickaxeConfig")
    if type(Pickaxe) ~= "table" or type(Pickaxe.GetDamage) ~= "function" then return 1 end

    local Character = GetCharacter()
    local Tool = Character and Character:FindFirstChild(Pickaxe.ToolName or "Pickaxe")
    local Tier = Tool and Tool:GetAttribute("PickaxeTier")
    if type(Tier) ~= "number" then Tier = tonumber(GetStat("PickaxeTier", 1)) or 1 end

    local Ok, Damage = pcall(Pickaxe.GetDamage, Tier)
    return Ok and tonumber(Damage) or 1
end

-- Best Zone = โซนสูงสุดที่ไข่ "กลาง ๆ" (มัธยฐาน MaxHealth ของไข่ในโซนตอนนี้) แตกภายใน BestZoneHits ครั้ง
-- วัดสด: เลือดไข่โซนละ x15-x30 (EggConfig.ZoneHealthMult) ดาเมจ tier ละ x4 - เช่น tier 11 (1M) โซน 6 มัธยฐาน 13M
-- = 13 ครั้ง / โซน 7 411M = 411 ครั้ง (~2.6 นาทีต่อใบ) -> โซน 6 / ไม่ถึงสักโซน = โซน 1
Farm.BestZoneHits = 40           -- ~15 วิต่อใบ (ยิงทุก 0.38 วิ)
Farm.BestZoneCache = { Zone = 1, At = -math.huge }

function Farm.BestZone()
    if os.clock() - Farm.BestZoneCache.At < 3 then return Farm.BestZoneCache.Zone end

    local Healths = { }
    for _, Egg in ipairs(CollectionService:GetTagged(Tags.Egg)) do
        local Zone, Health = Egg:GetAttribute("ZoneIndex"), tonumber(Egg:GetAttribute("MaxHealth"))
        if Zone and Health and EggIsLive(Egg) then
            Healths[Zone] = Healths[Zone] or { }
            table.insert(Healths[Zone], Health)
        end
    end

    local Limit = Farm.Damage() * Farm.BestZoneHits
    local Best = 1
    for Zone = 1, #Zones do
        local List = Healths[Zone]
        if List and #List > 0 then
            table.sort(List)
            if List[math.ceil(#List / 2)] <= Limit then Best = Zone end
        end
    end

    Farm.BestZoneCache = { Zone = Best, At = os.clock() }
    return Best
end

function Farm.ZoneIndex()
    local C = Config()
    if C.FarmBestZone then return Farm.BestZone() end
    return tonumber(tostring(C.FarmZone):match("^Zone (%d+)")) or 1
end

function Farm.TitanicEgg()
    for _, Tagged in ipairs(CollectionService:GetTagged("TitanicEgg")) do
        local Egg = EggPart(Tagged)
        if EggIsLive(Egg) and Egg:IsDescendantOf(workspace) then return Egg end
    end
    return nil
end

function Farm.EggMatches(Egg, Zone, Types)
    return EggIsLive(Egg) and Egg:GetAttribute("ZoneIndex") == Zone
        and (Types == nil or Types[Egg:GetAttribute("EggType")] == true)
end

function Farm.PickEgg()
    local C = Config()
    local Zone, Types = Farm.ZoneIndex(), SetOf(C.FarmEggTypes)
    local Root = GetRoot()
    local Mode = C.FarmEggPriority
    local Best, BestScore = nil, nil

    for _, Egg in ipairs(GetEggs(Zone)) do
        if Farm.EggMatches(Egg, Zone, Types) then
            local Score
            if Mode == "Highest Luck" then
                Score = -(tonumber(Egg:GetAttribute("HatchLuck")) or 0)
            elseif Mode == "Heaviest" then
                Score = -(tonumber(Egg:GetAttribute("WeightKg")) or 0)
            elseif Mode == "Nearest" then
                Score = Root and (Egg.Position - Root.Position).Magnitude or 0
            else
                Score = tonumber(Egg:GetAttribute("Health")) or math.huge
            end
            if BestScore == nil or Score < BestScore then Best, BestScore = Egg, Score end
        end
    end

    return Best
end

function Farm.EquipPickaxe()
    local Character, Humanoid = GetCharacter(), GetHumanoid()
    if not (Character and Humanoid) then return false end

    local Config2 = RequireShared("PickaxeConfig")
    local Name = type(Config2) == "table" and Config2.ToolName or "Pickaxe"
    if Character:FindFirstChild(Name) then return true end

    local Tool = LocalPlayer.Backpack:FindFirstChild(Name)
    if not Tool then return false end
    Humanoid:EquipTool(Tool)
    return true
end

-- ทุบหนึ่งครั้ง (รอคูลดาวน์เอง) - ยืนข้างผิวไข่ระดับพื้น
function Farm.HitEgg(Egg)
    Farm.MarkBusy()
    if not Farm.EquipPickaxe() then
        task.wait(0.5)
        return
    end

    local Size = Egg.Size
    local Center = Egg.Position
    local Stand = Center + Vector3.new(math.max(Size.X, Size.Z) / 2 + Farm.HitOffset, 3 - Size.Y / 2, 0)
    local Root = GetRoot()
    if Root and (Root.Position - Stand).Magnitude > 4 then
        Farm.Teleport(Stand, Center)
        task.wait(0.1)
    end

    local Wait = Farm.LastHit + Farm.HitInterval - os.clock()
    if Wait > 0 then task.wait(Wait) end

    if EggIsLive(Egg) and Remotes.EggHitRequest then
        Remotes.EggHitRequest:FireServer(Egg)
        Farm.LastHit = os.clock()
    end
end

---- สัตว์ ----

function Farm.PromptFor(Pickup)
    local Position = Pickup:GetPivot().Position
    local Best, BestDistance = nil, Farm.PromptRange

    for _, Anchor in ipairs(workspace:GetChildren()) do
        if Anchor.Name == "PromptAnchor" and Anchor:IsA("BasePart") then
            local Prompt = Anchor:FindFirstChild("StealPrompt")
            local Distance = (Anchor.Position - Position).Magnitude
            if Prompt and Prompt.Enabled and Distance < BestDistance then Best, BestDistance = Prompt, Distance end
        end
    end

    return Best
end

local function ReservedForOther(Instance)
    local Reserved = Instance:GetAttribute("ReservedUserId")
    return type(Reserved) == "number" and Reserved ~= LocalPlayer.UserId
end

function Farm.PickPickup()
    local C = Config()
    local Folder = workspace:FindFirstChild("AnimalPickups")
    if not Folder then return nil end

    local Rarities = SetOf(C.CollectRarities)
    local MinWeight = ParseAmount(C.CollectMinWeight) or 0
    local MinCash = ParseAmount(C.CollectMinCash) or 0
    local Now = workspace:GetServerTimeNow()
    local Best, BestPrompt, BestScore = nil, nil, nil

    for _, Pickup in ipairs(Folder:GetChildren()) do
        local Rarity = Pickup:GetAttribute("Rarity")
        if (Rarities == nil or Rarities[Rarity]) and (tonumber(Pickup:GetAttribute("WeightKg")) or 0) >= MinWeight
            and (tonumber(Pickup:GetAttribute("DespawnAtServerTime")) or math.huge) - Now > 1
            and not ReservedForOther(Pickup) then
            local Cash = Farm.CashOf(Pickup)
            local Prompt = Cash >= MinCash and Farm.PromptFor(Pickup)
            if Prompt and not ReservedForOther(Prompt) then
                -- เงิน/วิ สูงสุดก่อน (เท่ากัน = rarity สูงกว่า)
                local Score = Cash + (Farm.RarityRank[Rarity] or 0) * 1e-3
                if BestScore == nil or Score > BestScore then Best, BestPrompt, BestScore = Pickup, Prompt, Score end
            end
        end
    end

    return Best, BestPrompt
end

function Farm.Collect(Pickup, Prompt)
    local Before = Farm.Carry()

    Farm.Teleport(Prompt.Parent.Position + Vector3.new(0, 2, 2), Prompt.Parent.Position)

    -- วาร์ปไกลแล้วกดทันที server ยังเห็นตัวอยู่ที่เดิม (ไกลเกิน prompt 10 studs) = กดไม่ติด -> รอแล้วลองซ้ำ 1 ครั้ง
    for _ = 1, 2 do
        task.wait(0.3)
        pcall(fireproximityprompt, Prompt)

        local Start = os.clock()
        repeat task.wait(0.05) until Farm.Carry() > Before or not Pickup.Parent or os.clock() - Start > 0.8
        if Farm.Carry() > Before or not Pickup.Parent then return end
    end
end

---- ฐาน ----

-- จุดบนพื้นกลางกล่อง Hitbox ของฐาน
function Farm.PenPoint(Plot)
    local Hitbox = Plot:FindFirstChild("Hitbox")
    if not Hitbox then return nil end

    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = { GetCharacter(), Plot:FindFirstChild("PlacedAnimals"), Hitbox }

    local Top = Hitbox.Position + Vector3.new(0, Hitbox.Size.Y / 2, 0)
    local Hit = workspace:Raycast(Top, Vector3.new(0, -Hitbox.Size.Y - 10, 0), Params)
    return Hit and Hit.Position or Hitbox.Position
end

function Farm.GoHome()
    local Plot = GetMyPlot()
    local Point = Plot and Farm.PenPoint(Plot)
    if not Point then
        task.wait(1)
        return
    end

    Farm.Teleport(Point + Vector3.new(0, 3, 0))

    local Start = os.clock()
    repeat task.wait(0.05) until Farm.Carry() == 0 or os.clock() - Start > 2
end

function Farm.AnimalTools()
    local List = { }
    for _, Holder in ipairs({ LocalPlayer:FindFirstChild("Backpack"), GetCharacter() }) do
        for _, Tool in ipairs(Holder and Holder:GetChildren() or { }) do
            if Tool:IsA("Tool") and CollectionService:HasTag(Tool, Tags.AnimalTool) then table.insert(List, Tool) end
        end
    end
    return List
end

-- มีสัตว์ใน Backpack ที่ควรลงคอก: คอกยังว่าง หรือมีตัวที่ cash/s มากกว่าตัวแย่สุดในคอก
function Farm.NeedsBest(Plot)
    if not Plot or os.clock() < Farm.BestRetryAt then return false end

    local Tools = Farm.AnimalTools()
    if #Tools == 0 then return false end

    local Placed = (tonumber(Plot:GetAttribute("AnimalsPlaced")) or 0)
    if Placed < (tonumber(Plot:GetAttribute("MaxAnimals")) or 0) then return true end

    local Worst = math.huge
    local Folder = Plot:FindFirstChild("PlacedAnimals")
    for _, Animal in ipairs(Folder and Folder:GetChildren() or { }) do
        Worst = math.min(Worst, tonumber(Animal:GetAttribute("CashPerSecond")) or Farm.CashOf(Animal))
    end

    for _, Tool in ipairs(Tools) do
        if Farm.CashOf(Tool) > Worst then return true end
    end
    return false
end

-- ปุ่ม Equip Best ของเกม (ยืนในฐานก่อน) แล้วรอคอกเปลี่ยน / ไม่เปลี่ยน = พัก 15 วิ ไม่วนกลับฐานซ้ำ
function Farm.EquipBest()
    local Plot = GetMyPlot()
    local Center = Plot and Farm.PenPoint(Plot)
    if not (Center and Remotes.PetsInventoryRemote) then return end

    local Root = GetRoot()
    if Root and (Root.Position - Center).Magnitude > 20 then
        Farm.Teleport(Center + Vector3.new(0, 3, 0))
        task.wait(0.3)
    end

    local Folder = Plot:FindFirstChild("PlacedAnimals")
    local Changed = false
    local Connections = { }
    if Folder then
        table.insert(Connections, Folder.ChildAdded:Connect(function() Changed = true end))
        table.insert(Connections, Folder.ChildRemoved:Connect(function() Changed = true end))
    end

    Remotes.PetsInventoryRemote:FireServer("EquipBest", nil)

    local Start = os.clock()
    repeat task.wait(0.1) until Changed or os.clock() - Start > 2
    task.wait(0.3)
    for _, Connection in ipairs(Connections) do Connection:Disconnect() end

    if not Changed then Farm.BestRetryAt = os.clock() + 15 end
end

---- ไข่ merge (ปลูกในฐาน) ----
--
-- วัดสดผ่าน dex 2026-10-04: MergeMachineRemote:FireServer("PlaceEgg", tool ไข่, ตำแหน่ง) (ตัวเดียวกับคลิกตอนถือไข่)
--   ยิงจากไกล / ไม่ได้ถือ = เงียบ ไม่วาง / ยืนในฐาน + ถือไข่ + จุดในกล่อง Hitbox = วางได้ (Model MergeEgg_<EggId>
--   ในฐาน tag MergeEggPlaced attrs OwnerUserId / ReadyAtServerTime / GrowthDuration) / ไข่ไม่นับช่องคอก
--   (BuildIndicatorController เช็ค MaxAnimals เฉพาะตอนถือสัตว์)

function Farm.EggTools()
    local List = { }
    for _, Holder in ipairs({ LocalPlayer:FindFirstChild("Backpack"), GetCharacter() }) do
        for _, Tool in ipairs(Holder and Holder:GetChildren() or { }) do
            if Tool:IsA("Tool") and CollectionService:HasTag(Tool, "MergeEggTool") then table.insert(List, Tool) end
        end
    end
    return List
end

-- จุดสุ่มบนพื้นในกล่อง Hitbox (เว้นขอบ 4 / ไม่ตกบนสัตว์หรือไข่ที่วางอยู่)
function Farm.RandomPenPoint(Plot)
    local Hitbox = Plot:FindFirstChild("Hitbox")
    if not Hitbox then return nil end

    local Ignore = { GetCharacter(), Plot:FindFirstChild("PlacedAnimals"), Hitbox }
    for _, Egg in ipairs(CollectionService:GetTagged("MergeEggPlaced")) do table.insert(Ignore, Egg) end

    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = Ignore

    local HalfX, HalfZ = math.max(Hitbox.Size.X / 2 - 4, 0), math.max(Hitbox.Size.Z / 2 - 4, 0)
    local Offset = Vector3.new((math.random() * 2 - 1) * HalfX, Hitbox.Size.Y / 2, (math.random() * 2 - 1) * HalfZ)
    local Hit = workspace:Raycast(Hitbox.Position + Offset, Vector3.new(0, -Hitbox.Size.Y - 10, 0), Params)
    return Hit and Hit.Position or nil
end

function Farm.NeedsGrow()
    return os.clock() >= Farm.GrowRetryAt and #Farm.EggTools() > 0
end

-- วางไข่ทุกใบที่ถือ (วางไม่ลง = พัก 30 วิ ไม่วนกลับฐานซ้ำ)
function Farm.PlaceEggs()
    local Plot = GetMyPlot()
    local Center = Plot and Farm.PenPoint(Plot)
    local Humanoid = GetHumanoid()
    if not (Center and Humanoid and Remotes.MergeMachineRemote) then return end

    local Root = GetRoot()
    if Root and (Root.Position - Center).Magnitude > 20 then
        Farm.Teleport(Center + Vector3.new(0, 3, 0))
        task.wait(0.4)
    end

    for _, Tool in ipairs(Farm.EggTools()) do
        Farm.MarkBusy()
        local Point = Farm.RandomPenPoint(Plot)
        if not Point then break end

        Humanoid:EquipTool(Tool)
        task.wait(0.3)
        Remotes.MergeMachineRemote:FireServer("PlaceEgg", Tool, Point)

        local Start = os.clock()
        repeat task.wait(0.1) until Tool.Parent == nil or os.clock() - Start > 1.5
        if Tool.Parent ~= nil then
            Farm.GrowRetryAt = os.clock() + 30
            break
        end
    end
end

---- ลูปหลัก (ตัวเดียวคุมการขยับตัวละคร: กลับฐาน > วาง > Titanic > เก็บสัตว์ > ทุบไข่) ----

function Farm.Step()
    local C = Config()

    if not IsAlive() then
        task.wait(1)
        return
    end

    local Count, Capacity = Farm.Carry()
    if Count > 0 and GetStat("BeingChased") then
        Farm.ChasedSince = Farm.ChasedSince or os.clock()
    else
        Farm.ChasedSince = nil
    end

    -- ถือสัตว์อยู่: กระเป๋าเต็ม / โดนยามไล่นาน / ไม่ได้เปิดเก็บต่อ = กลับฐานฝาก (ไม่งั้นโดนจับหลุดมือ)
    local Chased = Farm.ChasedSince and os.clock() - Farm.ChasedSince >= Farm.ChaseLimit
    if Count > 0 and (Count >= Capacity or Chased or not C.AutoCollect) then
        Farm.GoHome()
        return
    end

    -- หน้า Pet & Egg (ต้องยืนในฐาน = ลูปนี้คุมตัวละครอยู่แล้ว)
    if C.AutoPlace and Farm.NeedsBest(GetMyPlot()) then
        Farm.EquipBest()
        return
    end

    if C.AutoGrowEggs and Farm.NeedsGrow() then
        Farm.PlaceEggs()
        return
    end

    -- ไข่ที่ทุบอยู่แตกแล้ว = หาใหม่
    if Farm.Target and not EggIsLive(Farm.Target) then
        Farm.Target = nil
    end

    if C.AutoTitanic then
        local Egg = Farm.TitanicEgg()
        if Egg then
            Farm.Target = Egg
            Farm.HitEgg(Egg)
            return
        end
    end

    -- หน้า Steal & PVP (ตีคนถือสัตว์ / แย่งสัตว์จากไข่คนอื่น)
    if Farm.StealStep(Count, Capacity) then return end

    if C.AutoCollect and Count < Capacity then
        local Pickup, Prompt = Farm.PickPickup()
        if Pickup then
            Farm.Collect(Pickup, Prompt)
            return
        end
    end

    if C.AutoBreakEgg then
        local Zone = Farm.ZoneIndex()
        local Types = SetOf(C.FarmEggTypes)
        if not (Farm.Target and Farm.EggMatches(Farm.Target, Zone, Types)) then
            Farm.Target = Farm.PickEgg()
        end

        local Egg = Farm.Target
        if Egg then
            Farm.HitEgg(Egg)
            return
        end
    end

    task.wait(0.3)
end

function Farm.Start()
    if Farm.Running then return end
    Farm.Running = true

    Farm.Thread = task.spawn(function()
        while Farm.Running and getgenv().ValkyrieSession == SessionToken do
            local Ok, Err = pcall(Farm.Step)
            if not Ok then
                warn("[ValkyrieHub] Auto Farm: " .. tostring(Err))
                task.wait(1)
            end
        end
        Farm.Running = false
        Farm.Thread = nil
    end)
end

function Farm.Stop()
    Farm.Running = false
    Farm.Target = nil
    Farm.ChasedSince = nil
end

-- เปิดลูปเมื่อมี toggle ไหนเปิดอยู่ / ปิดหมด = หยุด
function Farm.Refresh()
    local C = Config()
    if C.AutoBreakEgg or C.AutoCollect or C.AutoPlace or C.AutoTitanic or C.AutoGrowEggs
        or C.BatAura or C.AutoSnipe then
        Farm.Start()
    else
        Farm.Stop()
    end
end

---- หน้า Auto Farm ----
--
-- จัดในกล่อง: toggle อยู่บน (ตัวสุดท้ายมีเส้นคั่น) -> dropdown / slider อยู่ล่างติดกันไม่มีเส้นคั่น

Window:Category("General")

local FarmPage = Window:Page({ Name = "Auto Farm", Icon = "activity", Columns = 2 })

local function FarmToggle(Section, Name, Key, Description, Seperator)
    Section:Toggle({
        Name = Name,
        Description = Description,
        Flag = "BSE" .. Key,
        Default = Config()[Key],
        Seperator = Seperator,
        Callback = function(Value)
            Config()[Key] = Value
            SaveConfiguration()
            Farm.Refresh()
        end
    })
end

local function FarmSetting(Key)
    return function(Value)
        Config()[Key] = Value
        Farm.Target = nil
        SaveConfiguration()
    end
end

local EggSection = FarmPage:Section({ Name = "Egg", Icon = "target", Side = 1 })

FarmToggle(EggSection, "Auto Break Egg", "AutoBreakEgg", "Break eggs in the farm zone with your pickaxe")
FarmToggle(EggSection, "Auto Best Zone", "FarmBestZone", "Use the highest zone your pickaxe damage breaks eggs fast in", true)

EggSection:Dropdown({
    Name = "Zone",
    Description = "Used when Auto Best Zone is off - any zone works",
    Flag = "BSEFarmZone",
    Items = Farm.ZoneNames,
    KeepOrder = true,
    Default = Config().FarmZone,
    Seperator = false,
    Callback = FarmSetting("FarmZone")
})

EggSection:Dropdown({
    Name = "Egg Types",
    Description = "None selected = any egg",
    Flag = "BSEFarmEggTypes",
    Items = Farm.EggTypes,
    Multi = true,
    Default = Config().FarmEggTypes,
    Seperator = false,
    Callback = FarmSetting("FarmEggTypes")
})

EggSection:Dropdown({
    Name = "Egg Priority",
    Flag = "BSEFarmEggPriority",
    Items = Farm.Priorities,
    KeepOrder = true,
    Default = Config().FarmEggPriority,
    Seperator = false,
    Callback = FarmSetting("FarmEggPriority")
})

local TitanicSection = FarmPage:Section({ Name = "Titanic Egg", Icon = "skull", Side = 1 })

FarmToggle(TitanicSection, "Auto Titanic Egg", "AutoTitanic", "Break the Titanic egg first whenever it spawns")

local AnimalSection = FarmPage:Section({ Name = "Animals", Icon = "users", Side = 2 })

FarmToggle(AnimalSection, "Auto Collect Animal", "AutoCollect", "Steal hatched animals that match the filters - goes home to bank them when the satchel is full", true)

AnimalSection:Dropdown({
    Name = "Rarities",
    Description = "None selected = any rarity",
    Flag = "BSECollectRarities",
    Items = Farm.Rarities,
    KeepOrder = true,
    Multi = true,
    Default = Config().CollectRarities,
    Seperator = false,
    Callback = FarmSetting("CollectRarities")
})

AnimalSection:Textbox({
    Name = "Min Weight (kg)",
    Placeholder = "Any - e.g. 500 / 1.5K",
    Flag = "BSECollectMinWeight",
    Default = tostring(Config().CollectMinWeight or ""),
    Callback = FarmSetting("CollectMinWeight")
})

AnimalSection:Textbox({
    Name = "Min Cash/s",
    Placeholder = "Any - e.g. 100 / 2K / 1.5M",
    Flag = "BSECollectMinCash",
    Default = tostring(Config().CollectMinCash or ""),
    Callback = FarmSetting("CollectMinCash")
})

---- ============ Pet & Egg ============ ----
--
-- วัดสดผ่าน dex 2026-10-04 (ยิงห่าง 1,290-1,360 studs ได้หมด ยกเว้นวางไข่ / Equip Best ที่ต้องอยู่ในฐาน):
-- Equip Best = PetsInventoryRemote:FireServer("EquipBest", nil) - ทำในลูปฟาร์ม (Farm.EquipBest วาร์ปเข้าฐานก่อน)
-- Merge = MergeMachineRemote:FireServer("Merge", { tool1, tool2, tool3 }) - ต้องเป็นสัตว์ "ชนิดเดียวกัน" (AnimalName)
--   (UI ของเครื่องกรองช่อง 2-3 ให้เหลือแค่ชื่อเดียวกับช่องแรก / ต่างชนิด = server เงียบ) / ไม่ต้องไปที่เครื่อง
--   ได้ tool ไข่ "<ชื่อ> Egg" tag MergeEggTool (attrs EggId / WeightKg / GrowthDuration) / คูลดาวน์ MergeConfig 0 วิ
--   (attr MergeCooldownEndsAt) / ใช้สัตว์ในคอกได้ด้วย แต่ตัวนี้ใช้แค่ในกระเป๋า (ไม่แตะคอก)
-- ปลูก = วางไข่ในฐาน (Farm.PlaceEggs) แล้วโตเองตาม GrowthDuration (MergeConfig.GrowthSeconds: 10 วิ x น้ำหนัก x rarity
--   สูงสุด 7 วัน) / ปุ่ม Grow All (SkipAll) กับ Skip Growth (SkipEgg) = จ่าย Robux (MergeConfig.GrowAllProducts /
--   SkipProducts) = ไม่ทำ
-- เปิด = MergeMachineRemote:FireServer("HatchEgg", EggId) เมื่อ attr Ready / ReadyAtServerTime ถึงแล้ว (ของในฐานเรา)
-- ขาย = BackpackSellRemote:InvokeServer({ tool ... }) (RemoteFunction, ทีละไม่เกิน BackpackSellConfig.MaxPerRequest 200)
--   คืนจำนวนที่ขาย / ราคา = cash/s x 60 / เกมไม่มีระบบ Favorite (ไม่มี attr / โค้ดไหนพูดถึง) -> ฮับเก็บรายชื่อเอง

local Pets = { Running = false, Thread = nil, Opened = { }, SellAt = 0, MergeAt = 0 }

-- ชื่อสัตว์ทั้งหมดของเกม (EggRewards.Pool 74 ตัว) สำหรับดรอปดาวน์ Favorite
Pets.Species = { }
do
    local Rewards = RequireShared("EggRewards")
    local Seen = { }
    if type(Rewards) == "table" and type(Rewards.Pool) == "table" then
        for _, Entry in ipairs(Rewards.Pool) do
            if type(Entry.Name) == "string" and not Seen[Entry.Name] then
                Seen[Entry.Name] = true
                table.insert(Pets.Species, Entry.Name)
            end
        end
    end
    table.sort(Pets.Species)
end

local function Favorites()
    return SetOf(Config().FavoriteAnimals) or { }
end

-- ตัวที่แย่สุดในคอก (คอกยังว่าง = 0 -> ไม่มีตัวไหนแย่กว่า = ไม่ขาย ให้ Equip Best วางก่อน)
local function WorstPlaced()
    local Plot = GetMyPlot()
    if not Plot then return 0 end
    if (tonumber(Plot:GetAttribute("AnimalsPlaced")) or 0) < (tonumber(Plot:GetAttribute("MaxAnimals")) or 0) then return 0 end

    local Worst = math.huge
    local Folder = Plot:FindFirstChild("PlacedAnimals")
    for _, Animal in ipairs(Folder and Folder:GetChildren() or { }) do
        Worst = math.min(Worst, tonumber(Animal:GetAttribute("CashPerSecond")) or Farm.CashOf(Animal))
    end
    return Worst == math.huge and 0 or Worst
end

-- รวมร่าง 1 ครั้ง: ชนิดที่ตัวถูกสุดสามตัวรวมกันมีค่าน้อยสุดก่อน (เก็บตัวดีไว้)
function Pets.Merge()
    if not Remotes.MergeMachineRemote then return false end
    if (tonumber(GetStat("MergeCooldownEndsAt", 0)) or 0) > workspace:GetServerTimeNow() then return false end

    local Rarities = SetOf(Config().MergeRarities)
    local Favorite = Favorites()
    local Groups = { }

    for _, Tool in ipairs(Farm.AnimalTools()) do
        local Name = Tool:GetAttribute("AnimalName")
        if type(Name) == "string" and not Favorite[Name] and (Rarities == nil or Rarities[Tool:GetAttribute("Rarity")]) then
            Groups[Name] = Groups[Name] or { }
            table.insert(Groups[Name], { Tool = Tool, Cash = Farm.CashOf(Tool) })
        end
    end

    local Best, BestCost = nil, nil
    for _, List in pairs(Groups) do
        if #List >= 3 then
            table.sort(List, function(A, B) return A.Cash < B.Cash end)
            local Cost = List[1].Cash + List[2].Cash + List[3].Cash
            if BestCost == nil or Cost < BestCost then Best, BestCost = List, Cost end
        end
    end
    if not Best then return false end

    local First = Best[1].Tool
    Remotes.MergeMachineRemote:FireServer("Merge", { Best[1].Tool, Best[2].Tool, Best[3].Tool })

    local Start = os.clock()
    repeat task.wait(0.1) until First.Parent == nil or os.clock() - Start > 2
    return First.Parent == nil
end

-- เปิดไข่ในฐานเราที่โตเสร็จ (ยิงซ้ำไข่เดิมได้ทุก 10 วิ ถ้ายังไม่หาย)
function Pets.OpenEggs()
    if not Remotes.MergeMachineRemote then return end
    local Now = workspace:GetServerTimeNow()

    for _, Egg in ipairs(CollectionService:GetTagged("MergeEggPlaced")) do
        local Id = Egg:GetAttribute("EggId")
        local Ready = Egg:GetAttribute("Ready") == true or (tonumber(Egg:GetAttribute("ReadyAtServerTime")) or math.huge) <= Now
        if Id and Ready and Egg:GetAttribute("OwnerUserId") == LocalPlayer.UserId
            and os.clock() - (Pets.Opened[Id] or -math.huge) > 10 then
            Pets.Opened[Id] = os.clock()
            Remotes.MergeMachineRemote:FireServer("HatchEgg", Id)
            task.wait(0.3)
        end
    end
end

-- ขายสัตว์ในกระเป๋า: rarity ที่เลือก, ไม่อยู่ใน Favorite, ไม่ดีกว่าตัวแย่สุดในคอก, ไม่ใช่ตัวที่ถืออยู่
Pets.NameModes = { "Any Name", "Only Selected Names", "All Except Selected Names" }

-- ราคาขายต่อตัว = ตัวเดียวกับที่หน้าขายของเกมโชว์ (BackpackSellConfig.ToolValue = cash/s x 60)
function Pets.PriceOf(Tool)
    local SellConfig = RequireShared("BackpackSellConfig")
    if type(SellConfig) == "table" and type(SellConfig.ToolValue) == "function" then
        local Ok, Value = pcall(SellConfig.ToolValue, Tool)
        if Ok and tonumber(Value) then return tonumber(Value) end
    end
    return Farm.CashOf(Tool) * 60
end

-- ต้องผ่านทุกตัวกรอง: rarity, ชื่อ, ราคา min/max, ไม่ใช่ Favorite, ไม่ดีกว่าตัวแย่สุดในคอก
function Pets.Sellable(Tool, Filter)
    local Name = Tool:GetAttribute("AnimalName")
    if not Filter.Rarities[Tool:GetAttribute("Rarity")] or Filter.Favorite[Name] then return false end

    if Filter.NameMode == "Only Selected Names" and not Filter.Names[Name] then return false end
    if Filter.NameMode == "All Except Selected Names" and Filter.Names[Name] then return false end

    local Price = Pets.PriceOf(Tool)
    if Filter.Min and Price < Filter.Min then return false end
    if Filter.Max and Price > Filter.Max then return false end

    return Farm.CashOf(Tool) < Filter.Worst
end

function Pets.Sell()
    local C = Config()
    local Rarities = SetOf(C.SellRarities)
    local Backpack = LocalPlayer:FindFirstChild("Backpack")
    if not (Rarities and Backpack and Remotes.BackpackSellRemote) then return end

    local Filter = {
        Rarities = Rarities,
        Favorite = Favorites(),
        NameMode = C.SellNameMode,
        Names = SetOf(C.SellNames) or { },
        Min = ParseAmount(C.SellPriceMin),
        Max = ParseAmount(C.SellPriceMax),
        Worst = WorstPlaced(),
    }
    local List = { }

    for _, Tool in ipairs(Backpack:GetChildren()) do
        if Tool:IsA("Tool") and CollectionService:HasTag(Tool, Tags.AnimalTool) and Pets.Sellable(Tool, Filter) then
            table.insert(List, Tool)
            if #List >= 200 then break end
        end
    end

    if #List > 0 then
        pcall(function() Remotes.BackpackSellRemote:InvokeServer(List) end)
    end
end

function Pets.Step()
    local C = Config()

    if C.AutoOpenEggs then Pets.OpenEggs() end

    if C.AutoMerge and os.clock() >= Pets.MergeAt then
        -- ไม่มีชุดให้รวม = พัก 5 วิ
        if not Pets.Merge() then Pets.MergeAt = os.clock() + 5 end
    end

    if C.AutoSell and os.clock() >= Pets.SellAt then
        Pets.SellAt = os.clock() + 10
        Pets.Sell()
    end

    task.wait(1)
end

function Pets.Start()
    if Pets.Running then return end
    Pets.Running = true

    Pets.Thread = task.spawn(function()
        while Pets.Running and getgenv().ValkyrieSession == SessionToken do
            local Ok, Err = pcall(Pets.Step)
            if not Ok then
                warn("[ValkyrieHub] Pet & Egg: " .. tostring(Err))
                task.wait(1)
            end
        end
        Pets.Running = false
        Pets.Thread = nil
    end)
end

function Pets.Stop()
    Pets.Running = false
end

function Pets.Refresh()
    local C = Config()
    if C.AutoMerge or C.AutoOpenEggs or C.AutoSell then
        Pets.Start()
    else
        Pets.Stop()
    end
    -- Equip Best / ปลูกไข่ อยู่ในลูปฟาร์ม
    Farm.Refresh()
end

local PetPage = Window:Page({ Name = "Pet & Egg", Icon = "flask-conical", Columns = 2 })

local function PetToggle(Section, Name, Key, Description, Seperator)
    Section:Toggle({
        Name = Name,
        Description = Description,
        Flag = "BSE" .. Key,
        Default = Config()[Key],
        Seperator = Seperator,
        Callback = function(Value)
            Config()[Key] = Value
            SaveConfiguration()
            Pets.Refresh()
        end
    })
end

local PetsSection = PetPage:Section({ Name = "Pets", Icon = "users", Side = 1 })

PetToggle(PetsSection, "Auto Equip Best", "AutoPlace", "Keep the best cash/s animals in your pen (game Equip Best)")

local MergeSection = PetPage:Section({ Name = "Merge", Icon = "wand-2", Side = 1 })

PetToggle(MergeSection, "Auto Merge", "AutoMerge", "Merge 3 of the same animal from your backpack into an egg", true)

MergeSection:Dropdown({
    Name = "Merge Rarities",
    Description = "None selected = any rarity",
    Flag = "BSEMergeRarities",
    Items = Farm.Rarities,
    KeepOrder = true,
    Multi = true,
    Default = Config().MergeRarities,
    Seperator = false,
    Callback = function(Value)
        Config().MergeRarities = Value
        SaveConfiguration()
    end
})

local EggsSection = PetPage:Section({ Name = "Eggs", Icon = "flask-conical", Side = 1 })

PetToggle(EggsSection, "Auto Grow Eggs", "AutoGrowEggs", "Place merged eggs in your plot so they start growing")
PetToggle(EggsSection, "Auto Open Eggs", "AutoOpenEggs", "Hatch eggs as soon as they finish growing")

local SellSection = PetPage:Section({ Name = "Sell", Icon = "coins", Side = 2 })

PetToggle(SellSection, "Auto Sell", "AutoSell", "Sell backpack animals of the chosen rarities - never ones better than your pen", true)

SellSection:Dropdown({
    Name = "Sell Rarities",
    Description = "None selected = sell nothing",
    Flag = "BSESellRarities",
    Items = Farm.Rarities,
    KeepOrder = true,
    Multi = true,
    Default = Config().SellRarities,
    Seperator = false,
    Callback = function(Value)
        Config().SellRarities = Value
        SaveConfiguration()
    end
})

SellSection:Dropdown({
    Name = "Name Filter",
    Flag = "BSESellNameMode",
    Items = Pets.NameModes,
    KeepOrder = true,
    Default = Config().SellNameMode,
    Seperator = false,
    Callback = function(Value)
        Config().SellNameMode = Value
        SaveConfiguration()
    end
})

SellSection:Dropdown({
    Name = "Sell Names",
    Description = "Used by Only Selected / All Except Selected",
    Flag = "BSESellNames",
    Items = Pets.Species,
    Multi = true,
    Default = Config().SellNames,
    Seperator = false,
    Callback = function(Value)
        Config().SellNames = Value
        SaveConfiguration()
    end
})

SellSection:Textbox({
    Name = "Min Price",
    Placeholder = "Any - e.g. 500 / 2K / 1.5M",
    Flag = "BSESellPriceMin",
    Default = tostring(Config().SellPriceMin or ""),
    Callback = function(Value)
        Config().SellPriceMin = Value
        SaveConfiguration()
    end
})

SellSection:Textbox({
    Name = "Max Price",
    Placeholder = "Any - e.g. 500 / 2K / 1.5M",
    Flag = "BSESellPriceMax",
    Default = tostring(Config().SellPriceMax or ""),
    Callback = function(Value)
        Config().SellPriceMax = Value
        SaveConfiguration()
    end
})

SellSection:Dropdown({
    Name = "Favorite Animals",
    Description = "Never sold or merged",
    Flag = "BSEFavoriteAnimals",
    Items = Pets.Species,
    Multi = true,
    Default = Config().FavoriteAnimals,
    Seperator = false,
    Callback = function(Value)
        Config().FavoriteAnimals = Value
        SaveConfiguration()
    end
})

---- ============ Steal & PVP ============ ----
--
-- อ่านจากโค้ดเกม 2026-10-04 (BatController / BatTargeting / BatConfig):
-- ตีด้วยไม้ = BatHitRequest:FireServer(ผู้เล่นเป้าหมาย) (BatController ยิง currentTarget() = ผู้เล่นใกล้สุดที่ผ่าน
--   BatTargeting.IsEligible) / ระยะ = BatConfig.Targeting.Range 15 x attr BatHitboxMultiplier + HitTolerance 2
--   / คูลดาวน์ server 0.7 วิ (client 0.6) / ตีไม่ได้: ล้มอยู่ (attr Ragdolled), BatImmune, ยังเล่น tutorial,
--   ยืนในฐานตัวเอง (SafeZoneQuery.IsBankable) - เราเองยืนในฐานก็ตีไม่ได้ (เกมขึ้น BatSafeZone)
-- คนถือสัตว์ = attr ผู้เล่น Carrying (ชื่อ) / CarryingKg / CarryingSizeMult (replicate ให้ทุกคน)
-- โดนตีแล้วสัตว์หลุด (ตามคำอธิบายฟีเจอร์) - ยังไม่ได้เห็นจริง: เซิร์ฟที่ทดสอบไม่มีใครถือสัตว์ช่วงที่เฝ้า
-- Snipe: ไข่ที่คนอื่นทุบแตก = attr Hatching / HatchBreakerUserId / HatchAnimal / WeightKg / HatchId ขึ้นทันที
--   แล้วสัตว์โผล่ ~5 วิ ตรงไข่ (HatchId เดียวกัน) -> รู้ค่าล่วงหน้า (EggRewards.PlacedCashPerSecond(ชื่อ, 1, nil, kg))
--   ไปยืนรอที่ไข่ แล้วกด StealPrompt ทันทีที่สัตว์โผล่

Farm.Steal = { LastSwing = 0, SnipeWait = 7 }

local function CashOfCarried(Player)
    local Name = Player:GetAttribute("Carrying")
    local Rewards = RequireShared("EggRewards")
    if type(Name) ~= "string" or type(Rewards) ~= "table" then return 0 end

    local Ok, Value = pcall(Rewards.PlacedCashPerSecond, Name, Player:GetAttribute("CarryingSizeMult") or 1, nil,
        Player:GetAttribute("CarryingKg"), nil)
    return Ok and tonumber(Value) or 0
end

local function BatRange()
    local Targeting = RequireShared("BatTargeting")
    if type(Targeting) == "table" and type(Targeting.MaxRange) == "function" then
        local Ok, Range = pcall(Targeting.MaxRange, LocalPlayer)
        if Ok and tonumber(Range) then return tonumber(Range) end
    end
    return 17
end

-- คนถือสัตว์ที่ตีได้ (เงื่อนไขเดียวกับเกม) ค่าสูงสุด / Range = nil -> ทุกระยะ (Hunt)
function Farm.BatTarget(Range)
    local Root = GetRoot()
    local Targeting = RequireShared("BatTargeting")
    if not (Root and type(Targeting) == "table" and type(Targeting.IsEligible) == "function") then return nil end

    local MinCash = ParseAmount(Config().BatMinCash) or 0
    local Best, BestCash = nil, nil
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player:GetAttribute("Carrying") then
            local Ok, Eligible = pcall(Targeting.IsEligible, Player, Root.Position, Range or math.huge)
            local Cash = CashOfCarried(Player)
            if Ok and Eligible and Cash >= MinCash and (BestCash == nil or Cash > BestCash) then
                Best, BestCash = Player, Cash
            end
        end
    end
    return Best
end

function Farm.EquipBat()
    local Character, Humanoid = GetCharacter(), GetHumanoid()
    local Bat = RequireShared("BatConfig")
    local Name = type(Bat) == "table" and Bat.ToolName or "Bat"
    if not (Character and Humanoid) then return false end
    if Character:FindFirstChild(Name) then return true end

    local Tool = LocalPlayer.Backpack:FindFirstChild(Name)
    if not Tool then return false end
    Humanoid:EquipTool(Tool)
    task.wait(0.1)
    return true
end

-- ตีคนถือสัตว์จนหลุด (สูงสุด 5 ครั้ง) แล้วเก็บสัตว์ที่หล่นแถวนั้น
function Farm.BatAttack(Target, Hunt)
    if not Farm.EquipBat() then return end

    for _ = 1, 5 do
        local Character = Target.Character
        local TargetRoot = Character and Character:FindFirstChild("HumanoidRootPart")
        if not (TargetRoot and Target:GetAttribute("Carrying")) then break end

        Farm.MarkBusy()
        if Hunt then
            -- ยืนหลังเป้า 6 studs หันหาเป้า
            local Behind = TargetRoot.Position - TargetRoot.CFrame.LookVector * 6 + Vector3.new(0, 1, 0)
            Farm.Teleport(Behind, TargetRoot.Position)
            task.wait(0.1)
        end

        local Wait = Farm.Steal.LastSwing + 0.75 - os.clock()
        if Wait > 0 then task.wait(Wait) end
        Farm.EquipBat()
        Remotes.BatHitRequest:FireServer(Target)
        Farm.Steal.LastSwing = os.clock()
        task.wait(0.35)
    end

    if Target:GetAttribute("Carrying") then return end

    -- สัตว์ที่หล่น = pickup ใหม่ใกล้ตัวเป้า
    local Character = Target.Character
    local Around = Character and Character:GetPivot().Position
    local Start = os.clock()
    while Around and os.clock() - Start < 2.5 do
        for _, Pickup in ipairs(workspace.AnimalPickups:GetChildren()) do
            if (Pickup:GetPivot().Position - Around).Magnitude < 30 then
                local Prompt = Farm.PromptFor(Pickup)
                if Prompt then
                    Farm.Collect(Pickup, Prompt)
                    return
                end
            end
        end
        task.wait(0.1)
    end
end

-- ค่าที่จะได้ของไข่ที่กำลังฟัก / rarity ของชื่อสัตว์
local function HatchValue(Egg)
    local Rewards = RequireShared("EggRewards")
    local Name = Egg:GetAttribute("HatchAnimal")
    if type(Name) ~= "string" or type(Rewards) ~= "table" then return 0, nil end

    local Ok, Value = pcall(Rewards.PlacedCashPerSecond, Name, 1, nil, Egg:GetAttribute("WeightKg"), nil)
    local OkR, Rarity = pcall(Rewards.RarityOf, Name)
    return Ok and tonumber(Value) or 0, OkR and Rarity or nil
end

function Farm.SnipeFilter()
    local C = Config()
    return SetOf(C.SnipeRarities), ParseAmount(C.SnipeMinCash) or 0
end

-- สัตว์ที่หล่นอยู่แล้ว (ตัวกรอง Snipe) ค่าสูงสุด
function Farm.SnipePickup()
    local Rarities, MinCash = Farm.SnipeFilter()
    local Now = workspace:GetServerTimeNow()
    local Best, BestPrompt, BestCash = nil, nil, nil

    for _, Pickup in ipairs(workspace.AnimalPickups:GetChildren()) do
        local Cash = Farm.CashOf(Pickup)
        if (Rarities == nil or Rarities[Pickup:GetAttribute("Rarity")]) and Cash >= MinCash
            and (tonumber(Pickup:GetAttribute("DespawnAtServerTime")) or math.huge) - Now > 1
            and (BestCash == nil or Cash > BestCash) then
            local Prompt = Farm.PromptFor(Pickup)
            if Prompt then Best, BestPrompt, BestCash = Pickup, Prompt, Cash end
        end
    end
    return Best, BestPrompt
end

-- ไข่ของคนอื่นที่กำลังฟัก (ยังไม่ Broken) ค่าสูงสุดที่ผ่านตัวกรอง
function Farm.SnipeEgg()
    local Rarities, MinCash = Farm.SnipeFilter()
    local Best, BestCash = nil, nil

    for _, Egg in ipairs(CollectionService:GetTagged(Tags.Egg)) do
        if Egg:GetAttribute("Hatching") and not Egg:GetAttribute("Broken")
            and Egg:GetAttribute("HatchBreakerUserId") ~= LocalPlayer.UserId then
            local Cash, Rarity = HatchValue(Egg)
            if (Rarities == nil or Rarities[Rarity]) and Cash >= MinCash and (BestCash == nil or Cash > BestCash) then
                Best, BestCash = Egg, Cash
            end
        end
    end
    return Best
end

-- ยืนรอข้างไข่จนสัตว์โผล่ (HatchId เดียวกัน) แล้วกดทันที
function Farm.SnipeCamp(Egg)
    local HatchId = Egg:GetAttribute("HatchId")
    local Side = Egg.Position + Vector3.new(math.max(Egg.Size.X, Egg.Size.Z) / 2 + 2, 3 - Egg.Size.Y / 2, 0)
    Farm.Teleport(Side, Egg.Position)

    local Start = os.clock()
    while os.clock() - Start < Farm.Steal.SnipeWait do
        Farm.MarkBusy()
        for _, Pickup in ipairs(workspace.AnimalPickups:GetChildren()) do
            if Pickup:GetAttribute("HatchId") == HatchId then
                local Prompt = Farm.PromptFor(Pickup)
                if Prompt then
                    Farm.Collect(Pickup, Prompt)
                    return
                end
            end
        end
        task.wait(0.05)
    end
end

-- เรียกจาก Farm.Step: คืน true = ทำอะไรไปแล้ว
function Farm.StealStep(Count, Capacity)
    local C = Config()
    if Count >= Capacity then return false end

    if C.BatAura and Remotes.BatHitRequest then
        local Root = GetRoot()
        local SafeZone = RequireShared("SafeZoneQuery")
        local InSafeZone = Root and type(SafeZone) == "table" and select(2, pcall(SafeZone.IsBankable, LocalPlayer.UserId, Root.Position)) == true
        local Target = Farm.BatTarget((C.BatHunt or InSafeZone) and nil or BatRange())
        if Target and (C.BatHunt or not InSafeZone) then
            Farm.BatAttack(Target, C.BatHunt or InSafeZone)
            return true
        end
    end

    if C.AutoSnipe then
        local Pickup, Prompt = Farm.SnipePickup()
        if Pickup then
            Farm.Collect(Pickup, Prompt)
            return true
        end

        local Egg = Farm.SnipeEgg()
        if Egg then
            Farm.SnipeCamp(Egg)
            return true
        end
    end

    return false
end

local StealPage = Window:Page({ Name = "Steal & PVP", Icon = "swords", Columns = 2 })

local function StealToggle(Section, Name, Key, Description, Seperator)
    Section:Toggle({
        Name = Name,
        Description = Description,
        Flag = "BSE" .. Key,
        Default = Config()[Key],
        Seperator = Seperator,
        Callback = function(Value)
            Config()[Key] = Value
            SaveConfiguration()
            Farm.Refresh()
        end
    })
end

local MovementSection = StealPage:Section({ Name = "Movement", Icon = "footprints", Side = 1 })

MovementSection:Slider({
    Name = "Tween Speed",
    Description = "Adjust travel speed during movement (studs/s)",
    Flag = "BSETweenSpeed",
    Min = 50,
    Max = 800,
    Default = Config().TweenSpeed or 300,
    Suffix = " studs/s",
    Seperator = true,
    Callback = function(Value)
        Config().TweenSpeed = Value
        SaveConfiguration()
    end
})

local BatSection = StealPage:Section({ Name = "Bat", Icon = "swords", Side = 1 })

StealToggle(BatSection, "Bat Aura", "BatAura", "Hit players carrying an animal so it drops, then grab it")
StealToggle(BatSection, "Hunt Carriers", "BatHunt", "Teleport to carriers anywhere instead of only hitting ones in range", true)

BatSection:Textbox({
    Name = "Min Cash/s",
    Placeholder = "Any - e.g. 100 / 2K / 1.5M",
    Flag = "BSEBatMinCash",
    Default = tostring(Config().BatMinCash or ""),
    Callback = function(Value)
        Config().BatMinCash = Value
        SaveConfiguration()
    end
})

local SnipeSection = StealPage:Section({ Name = "Snipe", Icon = "target", Side = 2 })

StealToggle(SnipeSection, "Snipe Pickups", "AutoSnipe", "Wait at eggs other players break and grab the animal the moment it appears", true)

SnipeSection:Dropdown({
    Name = "Snipe Rarities",
    Description = "None selected = any rarity",
    Flag = "BSESnipeRarities",
    Items = Farm.Rarities,
    KeepOrder = true,
    Multi = true,
    Default = Config().SnipeRarities,
    Seperator = false,
    Callback = function(Value)
        Config().SnipeRarities = Value
        SaveConfiguration()
    end
})

SnipeSection:Textbox({
    Name = "Snipe Min Cash/s",
    Placeholder = "Any - e.g. 100 / 2K / 1.5M",
    Flag = "BSESnipeMinCash",
    Default = tostring(Config().SnipeMinCash or ""),
    Callback = function(Value)
        Config().SnipeMinCash = Value
        SaveConfiguration()
    end
})

---- ============ Treadmill ============ ----
--
-- วัดสดผ่าน dex 2026-10-04:
-- ลู่วิ่ง = Model ในฐานที่มี attr SpeedMultiplier / TreadmillLevel (ชื่อเปลี่ยนตามระดับ: Basic Treadmill ...)
-- ปลดล็อก = UnlockTreadmillRequest:FireServer() (ปุ่มบน UpgradeBoard) ราคา TreadmillUnlockConfig.Cost $100 /
--   ปลดแล้ว = attr TreadmillUnlocked ของฐาน
-- อัปเกรด = UpgradeTreadmillRequest:FireServer() (ปุ่ม Purchase ของ TreadmillBoard) / ระดับ = attr TreadmillLevel ของฐาน
--   ราคา = TreadmillUpgradeConfig.Levels[ระดับปัจจุบัน].UpgradeCost (9 ระดับ ตัวคูณ 1, 2, 4 ... 256)
--   ยังเล่น tutorial ไม่จบ (attr TutorialActive) = server ตอบ Notify "Complete Tutorial First" ไม่อัปให้
--   (บัญชีทดสอบยังไม่จบ tutorial = ยังไม่ได้เห็นอัปผ่านจริง / ไม่รู้ว่าต้องยืนใกล้กระดานไหม)
-- Auto Farm มาก่อน: ฟาร์มกำลังทำงาน (ทุบ / เก็บ / กลับฐาน) = ไม่ดึงตัวไปลู่ / ฟาร์มว่าง (ไม่มีไข่-สัตว์ให้ทำ) = กลับไปวิ่ง
-- (ฟาร์มวาร์ปออกจากลู่ได้เพราะ Farm.Teleport จบ session ให้)

Treadmill.Running = false
Treadmill.Thread = nil
Treadmill.UnlockCost = 100
Treadmill.RetryAt = { Unlock = 0, Upgrade = 0 }
Treadmill.TutorialNoticed = false
Treadmill.Levels = { 850000, 1e7, 5e8, 9.5e9, 1.2e11, 1e12, 1.5e13, 2.5e14 }   -- ค่าสำรอง UpgradeCost ระดับ 1-8

do
    local Unlock = RequireShared("TreadmillUnlockConfig")
    if type(Unlock) == "table" and tonumber(Unlock.Cost) then Treadmill.UnlockCost = tonumber(Unlock.Cost) end

    local Upgrade = RequireShared("TreadmillUpgradeConfig")
    if type(Upgrade) == "table" and type(Upgrade.Levels) == "table" then
        local Costs = { }
        for Index, Level in ipairs(Upgrade.Levels) do Costs[Index] = tonumber(Level.UpgradeCost) end
        Treadmill.Levels = Costs
    end
end

function Treadmill.Model(Plot)
    for _, Child in ipairs(Plot:GetChildren()) do
        if Child:IsA("Model") and Child:GetAttribute("SpeedMultiplier") ~= nil then return Child end
    end
    return nil
end

function Treadmill.Step()
    local C = Config()
    local Plot = GetMyPlot()
    if not Plot then
        task.wait(1)
        return
    end

    local Cash = tonumber(GetStat("Cash", 0)) or 0
    local Unlocked = Plot:GetAttribute("TreadmillUnlocked") == true

    if C.AutoUnlockTreadmill and not Unlocked and Cash >= Treadmill.UnlockCost and os.clock() >= Treadmill.RetryAt.Unlock
        and Remotes.UnlockTreadmillRequest then
        Remotes.UnlockTreadmillRequest:FireServer()
        Treadmill.RetryAt.Unlock = os.clock() + 3
    end

    if C.AutoUpgradeTreadmill and Unlocked then
        if GetStat("TutorialActive") then
            if not Treadmill.TutorialNoticed then
                Treadmill.TutorialNoticed = true
                Library:Notify("Treadmill", "Finish the game tutorial first - upgrades are blocked until then", 6)
            end
        else
            local Level = tonumber(Plot:GetAttribute("TreadmillLevel")) or 1
            local Cost = Treadmill.Levels[Level]
            if Cost and Cash >= Cost and os.clock() >= Treadmill.RetryAt.Upgrade and Remotes.UpgradeTreadmillRequest then
                Remotes.UpgradeTreadmillRequest:FireServer()
                Treadmill.RetryAt.Upgrade = os.clock() + 3
            end
        end
    end

    if C.AutoTrainSpeed and Unlocked and not Farm.Busy() and IsAlive() and not Treadmill.Active() then
        local Model = Treadmill.Model(Plot)
        local Root = GetRoot()
        if Model and Root then
            -- ยืนบนสายพาน = server ดูดตัวเข้ากลางลู่แล้วเริ่ม session เอง
            local Center, Size = Model:GetBoundingBox()
            Root.CFrame = CFrame.new(Center.Position + Vector3.new(0, Size.Y / 2 + 3, 0))
            Root.AssemblyLinearVelocity = Vector3.zero

            local Start = os.clock()
            repeat task.wait(0.1) until Treadmill.Active() or os.clock() - Start > 2.5
        end
    end

    task.wait(0.5)
end

function Treadmill.Start()
    if Treadmill.Running then return end
    Treadmill.Running = true

    Treadmill.Thread = task.spawn(function()
        while Treadmill.Running and getgenv().ValkyrieSession == SessionToken do
            local Ok, Err = pcall(Treadmill.Step)
            if not Ok then
                warn("[ValkyrieHub] Treadmill: " .. tostring(Err))
                task.wait(1)
            end
        end
        Treadmill.Running = false
        Treadmill.Thread = nil
    end)
end

function Treadmill.Stop()
    Treadmill.Running = false
end

function Treadmill.Refresh()
    local C = Config()
    if C.AutoTrainSpeed or C.AutoUnlockTreadmill or C.AutoUpgradeTreadmill then
        Treadmill.Start()
    else
        Treadmill.Stop()
    end
end

local TreadmillPage = Window:Page({ Name = "Auto Treadmill", Icon = "trending-up", Columns = 2 })

local TreadmillSection = TreadmillPage:Section({ Name = "Auto Treadmill", Icon = "activity", Side = 1 })

local function TreadmillToggle(Name, Key, Description)
    TreadmillSection:Toggle({
        Name = Name,
        Description = Description,
        Flag = "BSE" .. Key,
        Default = Config()[Key],
        Callback = function(Value)
            Config()[Key] = Value
            SaveConfiguration()
            Treadmill.Refresh()

            -- ปิดเทรน = ลงจากลู่ (ถ้าฟาร์มไม่ได้ใช้ตัวอยู่)
            if Key == "AutoTrainSpeed" and not Value and not Farm.Busy() then
                task.spawn(Treadmill.EndSession)
            end
        end
    })
end

TreadmillToggle("Auto Train Speed", "AutoTrainSpeed", "Run on your plot treadmill whenever Auto Farm has nothing to do")
TreadmillToggle("Auto Unlock Treadmill", "AutoUnlockTreadmill", "Unlock the treadmill when you have $100")
TreadmillToggle("Auto Upgrade Treadmill", "AutoUpgradeTreadmill", "Upgrade whenever you can afford the next level (9 levels, x1 to x256)")

---- ============ Auto Upgrade ============ ----
--
-- วัดสดผ่าน dex 2026-10-04 (ยิงจากห่างร้าน/ฐาน 640-750 studs ผ่านหมด = ไม่ต้องเดินไปร้าน):
-- Pickaxe = PickaxeShopRequest:FireServer("Buy", tier) / ("Equip", tier) - ซื้อข้ามขั้นได้ (มี 2 ซื้อ 4 ได้เลย)
--   ซื้อแล้วเกมใส่ให้ทันที (ซื้อขั้นต่ำกว่าที่ใส่ = โดนเปลี่ยนเป็นตัวต่ำ) / ที่มี = attr OwnedPickaxes "1,2,4"
--   ราคา PickaxeConfig.GetPrice(tier) 18 ขั้น ($80 -> $20Qa) / ดาเมจ PickaxeConfig.GetDamage(tier)
-- Pen = UpgradePlotRequest:FireServer() / ระดับ = attr PlotLevel ของฐาน (MaxAnimals +1 ต่อระดับ)
--   ราคา PlotUpgradeConfig.UpgradeCost(ระดับปัจจุบัน) 9 ระดับ ($10K -> $150T)
-- Trails = TrailShopRequest:FireServer("Buy", Id) / ("Equip", Id) - ซื้อแล้วใส่ให้ทันที / ที่มี = attr OwnedTrails
--   ใส่อยู่ = attr EquippedTrail / TrailsConfig.Trails = { Id, Price, Multiplier } (ตัวคูณ Speed x2 -> x600+)
-- Satchel = ซื้อที่ "สถานี" ในแมพ (tag SatchelConfig.StationTag = "SatchelUpgrade" - ตาม AdminNotes ของเกม)
--   แต่ตอนเขียนไม่มีสถานีในแมพเลย (tag 0 ชิ้น, StreamingEnabled = false) ไม่มี remote / UI ฝั่ง client
--   = ยังซื้อไม่ได้ - ตัวนี้เฝ้ารอสถานี เจอแล้วกด prompt ในนั้น / ไม่มี prompt = วาร์ปไปยืนทับ (เดา ยังไม่ได้ลอง)
-- ระหว่าง tutorial server ปฏิเสธทุกอย่าง ("Complete Tutorial First") ยกเว้นขั้นที่ tutorial สั่ง (BuyPickaxe / BuyTrail)

local Upgrade = { Running = false, Thread = nil, RetryAt = { }, TutorialNoticed = false }

local function OwnedSet(Value)
    local Set, Best = { }, 0
    for Number in tostring(Value or ""):gmatch("%d+") do
        Number = tonumber(Number)
        Set[Number] = true
        Best = math.max(Best, Number)
    end
    return Set, Best
end

-- งานที่ทำได้ตอนนี้ { Key, Cost, Run } (ใส่ของที่ดีกว่า = Cost 0 ทำก่อน)
function Upgrade.Candidates(Cash, Tutorial)
    local C = Config()
    local List = { }
    local Stage = GetStat("TutorialStage")

    if C.AutoBuyPickaxe and (not Tutorial or Stage == "BuyPickaxe") then
        local Pickaxe = RequireShared("PickaxeConfig")
        if type(Pickaxe) == "table" and type(Pickaxe.GetPrice) == "function" then
            local Owned, Best = OwnedSet(GetStat("OwnedPickaxes"))
            local MaxTier = tonumber(Pickaxe.MaxTier) or 18

            -- ขั้นสูงสุดที่เงินพอ (ข้ามขั้นได้)
            for Tier = MaxTier, Best + 1, -1 do
                local Ok, Price = pcall(Pickaxe.GetPrice, Tier)
                Price = Ok and tonumber(Price)
                if Price and not Owned[Tier] and Price <= Cash then
                    table.insert(List, { Key = "Pickaxe", Cost = Price, Run = function()
                        Remotes.PickaxeShopRequest:FireServer("Buy", Tier)
                    end })
                    break
                end
            end

            if Best > 0 and tonumber(GetStat("PickaxeTier", 1)) ~= Best then
                table.insert(List, { Key = "PickaxeEquip", Cost = 0, Run = function()
                    Remotes.PickaxeShopRequest:FireServer("Equip", Best)
                end })
            end
        end
    end

    if C.AutoUpgradePen and not Tutorial then
        local Plot = GetMyPlot()
        local PlotConfig = RequireShared("PlotUpgradeConfig")
        if Plot and type(PlotConfig) == "table" and type(PlotConfig.UpgradeCost) == "function" then
            local Level = tonumber(Plot:GetAttribute("PlotLevel")) or 1
            local Ok, Price = pcall(PlotConfig.UpgradeCost, Level)
            Price = Ok and tonumber(Price)
            if Level < (tonumber(PlotConfig.MaxLevel) or 9) and Price and Price <= Cash then
                table.insert(List, { Key = "Pen", Cost = Price, Run = function()
                    Remotes.UpgradePlotRequest:FireServer()
                end })
            end
        end
    end

    if C.AutoBuyTrails and (not Tutorial or Stage == "BuyTrail") then
        local Trails = RequireShared("TrailsConfig")
        if type(Trails) == "table" and type(Trails.Trails) == "table" then
            local Owned = OwnedSet(GetStat(Trails.OwnedAttribute or "OwnedTrails"))
            local BestId, BestMult = nil, 0
            for _, Trail in ipairs(Trails.Trails) do
                if Owned[Trail.Id] and (tonumber(Trail.Multiplier) or 0) > BestMult then
                    BestId, BestMult = Trail.Id, tonumber(Trail.Multiplier) or 0
                end
            end

            -- ตัวคูณสูงสุดที่ยังไม่มีและเงินพอ (ไม่มีราคา = Robux อย่างเดียว ข้าม)
            local Target, TargetMult = nil, BestMult
            for _, Trail in ipairs(Trails.Trails) do
                local Price, Mult = tonumber(Trail.Price), tonumber(Trail.Multiplier) or 0
                if not Owned[Trail.Id] and Price and Price <= Cash and Mult > TargetMult then
                    Target, TargetMult = Trail, Mult
                end
            end

            if Target then
                table.insert(List, { Key = "Trail", Cost = tonumber(Target.Price), Run = function()
                    Remotes.TrailShopRequest:FireServer("Buy", Target.Id)
                end })
            end

            if BestId and GetStat(Trails.EquippedAttribute or "EquippedTrail") ~= BestId then
                table.insert(List, { Key = "TrailEquip", Cost = 0, Run = function()
                    Remotes.TrailShopRequest:FireServer("Equip", BestId)
                end })
            end
        end
    end

    if C.AutoUpgradeSatchel and not Tutorial then
        local Satchel = RequireShared("SatchelConfig")
        if type(Satchel) == "table" and type(Satchel.NextTier) == "function" then
            local _, Next = Satchel.NextTier(tonumber(GetStat(Satchel.TierAttribute or "SatchelTier", 1)) or 1)
            local Price = Next and tonumber(Next.Price)
            local Station = CollectionService:GetTagged(Satchel.StationTag or "SatchelUpgrade")[1]
            if Price and Price <= Cash and Station then
                table.insert(List, { Key = "Satchel", Cost = Price, Run = function()
                    local Prompt = Station:IsA("ProximityPrompt") and Station or Station:FindFirstChildWhichIsA("ProximityPrompt", true)
                    local Position
                    if Station:IsA("BasePart") then
                        Position = Station.Position
                    elseif Station:IsA("Model") then
                        Position = Station:GetPivot().Position
                    elseif Prompt and Prompt.Parent:IsA("BasePart") then
                        Position = Prompt.Parent.Position
                    end
                    if Position then
                        Farm.Teleport(Position + Vector3.new(0, 3, 0))
                        task.wait(0.3)
                    end
                    if Prompt then pcall(fireproximityprompt, Prompt) end
                end })
            end
        end
    end

    return List
end

function Upgrade.Step()
    local Cash = tonumber(GetStat("Cash", 0)) or 0
    local Tutorial = GetStat("TutorialActive") == true

    if Tutorial and not Upgrade.TutorialNoticed then
        Upgrade.TutorialNoticed = true
        Library:Notify("Auto Upgrade", "Finish the game tutorial first - upgrades are blocked until then", 6)
    end

    -- ถูกสุดก่อน (ใส่ของ = 0) ทีละอย่าง แล้วรอ attr อัปเดต / อย่างเดิมยิงซ้ำได้ทุก 3 วิ
    local List = Upgrade.Candidates(Cash, Tutorial)
    table.sort(List, function(A, B) return A.Cost < B.Cost end)

    for _, Item in ipairs(List) do
        if os.clock() >= (Upgrade.RetryAt[Item.Key] or 0) then
            Upgrade.RetryAt[Item.Key] = os.clock() + 3
            Item.Run()
            task.wait(0.8)
            return
        end
    end

    task.wait(1)
end

function Upgrade.Start()
    if Upgrade.Running then return end
    Upgrade.Running = true

    Upgrade.Thread = task.spawn(function()
        while Upgrade.Running and getgenv().ValkyrieSession == SessionToken do
            local Ok, Err = pcall(Upgrade.Step)
            if not Ok then
                warn("[ValkyrieHub] Auto Upgrade: " .. tostring(Err))
                task.wait(1)
            end
        end
        Upgrade.Running = false
        Upgrade.Thread = nil
    end)
end

function Upgrade.Stop()
    Upgrade.Running = false
end

function Upgrade.Refresh()
    local C = Config()
    if C.AutoBuyPickaxe or C.AutoUpgradePen or C.AutoUpgradeSatchel or C.AutoBuyTrails then
        Upgrade.Start()
    else
        Upgrade.Stop()
    end
end

local UpgradePage = Window:Page({ Name = "Auto Upgrade", Icon = "coins", Columns = 2 })

local UpgradeSection = UpgradePage:Section({ Name = "Upgrade", Icon = "trending-up", Side = 1 })

local function UpgradeToggle(Name, Key, Description)
    UpgradeSection:Toggle({
        Name = Name,
        Description = Description,
        Flag = "BSE" .. Key,
        Default = Config()[Key],
        Callback = function(Value)
            Config()[Key] = Value
            SaveConfiguration()
            Upgrade.Refresh()
        end
    })
end

UpgradeToggle("Auto Buy Pickaxe", "AutoBuyPickaxe", "Buy the best pickaxe you can afford (18 tiers) and keep it equipped")
UpgradeToggle("Auto Upgrade Pen", "AutoUpgradePen", "Upgrade your pen for more animal slots (9 levels)")
UpgradeToggle("Auto Upgrade Satchel", "AutoUpgradeSatchel", "Carry more animals (6 tiers) - needs a satchel station in the map")
UpgradeToggle("Auto Buy Trails", "AutoBuyTrails", "Buy the best trail you can afford and keep it equipped")

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
    Flag = "BSETheme",
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

-- เกมมี anti-AFK ของตัวเอง (AntiAfkController + AntiAfkConfig.IdleSeconds 1080): ไม่มี input จริงผ่าน
-- UserInputService.InputBegan (คีย์บอร์ด / เมาส์ / แตะ) 18 นาที = ยิง AntiAfkRejoinRemote ให้ server ส่งเข้าเซิร์ฟใหม่
-- (วัดจริง 2026-10-04: ฟาร์มอยู่โดนรีจอย 2 ครั้ง ฮับหาย) / คลิก VirtualUser ไม่ขึ้น InputBegan เลย (วัดแล้ว 0 ครั้ง)
-- -> กดปุ่ม F15 (ไม่มีอะไรผูก) ผ่าน VirtualInputManager = InputBegan แบบ Keyboard จริง ตัวจับเวลาของเกมรีเซ็ต
local VirtualInputManager = game:GetService("VirtualInputManager")

local function AntiAfkStep()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F15, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F15, false, game)
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
    Flag = "BSEAntiAFK",
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
    Flag = "BSEAutoRejoin",
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
    Flag = "BSEAutoExecutor",
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
    Flag = "BSEMinimizeBind",
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
    Flag = "BSEFPSValue",
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
    Flag = "BSEFPSLock",
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
    Flag = "BSELanguage",
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

    pcall(Farm.Stop)
    pcall(Treadmill.Stop)
    pcall(Pets.Stop)
    pcall(Upgrade.Stop)

    for _, Connection in ipairs(SessionConnections) do
        pcall(function() Connection:Disconnect() end)
    end
    table.clear(SessionConnections)

    pcall(function()
        Library:Unload()
    end)

    getgenv().ValkyrieCleanup = nil
end
