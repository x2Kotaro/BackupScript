local Library = loadstring(game:HttpGet("https://valkyriehub.pro/api/raw/ui-lib"))()

--// Theme
local Accent = Color3.fromRGB(255, 80, 80)
local Gradient = Color3.fromRGB(120, 20, 20)

Library.Theme.Accent = Accent
Library.Theme.AccentGradient = Gradient
Library:ChangeTheme("Accent", Accent)
Library:ChangeTheme("AccentGradient", Gradient)

--// Languages (WindUI style) — keys are the English text used when building the UI
Library:AddLanguages({
    th = {
        ["Legit"] = "ฟีเจอร์หลัก",
        ["Toggles"] = "สวิตช์",
        ["Every toggle variant"] = "ตัวอย่างสวิตช์ทุกแบบ",
        ["Inputs"] = "ช่องกรอกค่า",
        ["Enabled"] = "เปิดใช้งาน",
        ["Auto Farm"] = "ฟาร์มอัตโนมัติ",
        ["Speed Hack"] = "เร่งความเร็ว",
        ["Hitbox Type"] = "ชนิดฮิตบ็อกซ์",
        ["Head"] = "หัว",
        ["Torso"] = "ลำตัว",
        ["Arms"] = "แขน",
        ["Legs"] = "ขา",
        ["Test Notification"] = "ทดสอบแจ้งเตือน",
        ["Language"] = "ภาษา",
        ["Close"] = "ปิด",
        ["Search.."] = "ค้นหา..",
        ["Toggle"] = "สลับ",
        ["Hold"] = "กดค้าง",
        ["Always"] = "ตลอดเวลา"
    },
    ru = {
        ["Enabled"] = "Включено",
        ["Auto Farm"] = "Автофарм",
        ["Speed Hack"] = "Скорость",
        ["Language"] = "Язык",
        ["Close"] = "Закрыть",
        ["Search.."] = "Поиск..",
        ["Toggle"] = "Переключение",
        ["Hold"] = "Удержание",
        ["Always"] = "Всегда"
    }
})

-- Library:SetLocale("th") -- switch at any time, every registered text updates live

--// Window
local Window = Library:Window({
    Name = "Valkyrie Hub",
    SubName = "discord.gg/PNnMkTRnuB",
    Logo = "118060107907937"
})

--// Keybind list + watermark + notification
local KeybindList = Library:KeybindList("Keybinds")

--============================================================
-- CATEGORY: Main
--============================================================
Window:Category("General")

local LegitPage = Window:Page({Name = "Legit", Icon = "138827881557940", Columns = 2})

--// SECTION 1 : Toggles (every toggle variant)
local ToggleSection = LegitPage:Section({
    Name = "Toggles",
    Description = "Every toggle variant",
    Icon = "123944728972740",
    Side = 1,
    EnableToggle = true -- pill switch on the section header
})

-- plain toggle
local PlainToggle = ToggleSection:Toggle({
    Name = "Enabled",
    Flag = "LegitEnabled",
    Default = true,
    Callback = function(Value)
        print("Legit Enabled:", Value)
    end
})

-- toggle + sub keybind (small key chip inside the row)
local SubKeyToggle = ToggleSection:Toggle({
    Name = "Toggle + SubKeybind",
    Flag = "SubKeybindToggle",
    Default = false,
    Callback = function(Value)
        print("SubKeybind Toggle:", Value)
    end
})
local SubKeybind = SubKeyToggle:SubKeybind({
    Flag = "SubKeybindToggleKey",
    Default = Enum.KeyCode.V,
    Mode = "Toggle" -- "Toggle" | "Hold"
})

-- toggle + keybind row underneath
local KeybindToggle = ToggleSection:Toggle({
    Name = "Toggle + Keybind",
    Flag = "AutoFarm",
    Default = false,
    Callback = function(Value)
        print("Auto Farm:", Value)
    end
})
KeybindToggle:Keybind({
    Flag = "AutoFarmKey",
    Default = Enum.KeyCode.F,
    Mode = "Toggle"
})

-- toggle + colorpicker row underneath
local ColorToggle = ToggleSection:Toggle({
    Name = "Toggle + Colorpicker",
    Flag = "EspToggle",
    Default = false,
    Callback = function(Value)
        print("ESP:", Value)
    end
})
ColorToggle:Colorpicker({
    Flag = "EspRowColor",
    Default = Color3.fromRGB(255, 100, 100),
    Alpha = true,
    Callback = function(Value)
        print("ESP row color:", Value)
    end
})

-- toggle + inline colorpicker chip (right side of the row)
local SubColorToggle = ToggleSection:Toggle({
    Name = "Toggle + SubColorpicker",
    Flag = "SubColorToggle",
    Default = false,
    Callback = function(Value)
        print("Sub Color:", Value)
    end
})
SubColorToggle:SubColorpicker({
    Flag = "SubColor1",
    Default = Color3.fromRGB(255, 100, 100),
    Callback = function(Value)
        print("Sub color 1:", Value)
    end
})
SubColorToggle:SubColorpicker({
    Flag = "SubColor2",
    Default = Color3.fromRGB(100, 200, 255),
    Alpha = true
})

-- everything at once
local FullToggle = ToggleSection:Toggle({
    Name = "Full Feature",
    Flag = "FullFeature",
    Default = false,
    Callback = function(Value)
        print("Full Feature:", Value)
    end
})
FullToggle:SubColorpicker({ Flag = "FullFeatureColor1", Default = Color3.fromRGB(100, 200, 255) })
FullToggle:SubColorpicker({ Flag = "FullFeatureColor2", Default = Color3.fromRGB(255, 200, 100) })
FullToggle:SubKeybind({ Flag = "FullFeatureKey", Default = Enum.KeyCode.Backspace, Mode = "Hold" })

-- toggle + settings popup (gear icon, holds its own elements)
local SettingsToggle = ToggleSection:Toggle({
    Name = "Toggle + Settings",
    Flag = "SettingsToggle",
    Default = false,
    Callback = function(Value)
        print("Settings Toggle:", Value)
    end
})
local ToggleSettings = SettingsToggle:Settings(200) -- 200 = popup height
ToggleSettings:Toggle({
    Name = "Inner Toggle",
    Flag = "InnerToggle",
    Default = true,
    Callback = function(Value) print("Inner toggle:", Value) end
})
ToggleSettings:Slider({
    Name = "Inner Slider",
    Flag = "InnerSlider",
    Min = 0,
    Max = 100,
    Default = 50,
    Suffix = "%",
    Callback = function(Value) print("Inner slider:", Value) end
})
ToggleSettings:Dropdown({
    Name = "Inner Dropdown",
    Flag = "InnerDropdown",
    Items = { "One", "Two", "Three" },
    Default = "One",
    Callback = function(Value) print("Inner dropdown:", Value) end
})

--// SECTION 2 : Inputs (slider / dropdown / listbox / textbox / keybinds / label / button)
local InputSection = LegitPage:Section({
    Name = "Inputs",
    Description = "Sliders, dropdowns, keybinds, textbox",
    Side = 2
})

local SpeedSlider = InputSection:Slider({
    Name = "Speed Hack",
    Flag = "SpeedSlider",
    Min = 1,
    Max = 100,
    Default = 16,
    Decimals = 1,
    Suffix = " studs",
    Callback = function(Value)
        print("Speed set to:", Value)
    end
})

InputSection:Slider({
    Name = "Precision Slider",
    Flag = "PrecisionSlider",
    Min = 0,
    Max = 1,
    Default = 0.5,
    Decimals = 0.01,
    Suffix = "x",
    Callback = function(Value)
        print("Precision:", Value)
    end
})

-- single select dropdown
local SingleDropdown = InputSection:Dropdown({
    Name = "Target Part",
    Flag = "TargetPart",
    Items = { "Head", "HumanoidRootPart", "Torso" },
    Default = "Head",
    Size = 125,
    OptionHolderSize = 125,
    Multi = false,
    Callback = function(Value)
        print("Target Part:", Value)
    end
})

-- multi select dropdown
InputSection:Dropdown({
    Name = "Hitbox Type",
    Flag = "HitboxType",
    Items = { "Head", "Torso", "Arms", "Legs" },
    Default = { "Head" },
    Multi = true,
    Callback = function(Value)
        print("Selected Hitboxes:", table.concat(Value, ", "))
    end
})

-- listbox (dropdown always expanded, with search)
local ListBox = InputSection:Listbox({
    Name = "Player List",
    Flag = "PlayerList",
    Items = { "Player1", "Player2", "Player3" },
    Size = 125,
    Multi = false,
    Callback = function(Value)
        print("Listbox selected:", Value)
    end
})

-- textbox
InputSection:Textbox({
    Name = "Player Name",
    Flag = "TextboxValue",
    Placeholder = "Type something..",
    Default = "",
    Numeric = false,
    Finished = false, -- true = callback only on Enter
    Callback = function(Value)
        print("Textbox:", Value)
    end
})

-- numeric textbox
InputSection:Textbox({
    Name = "Amount",
    Flag = "NumericBox",
    Placeholder = "Numbers only",
    Numeric = true,
    Finished = true,
    Callback = function(Value)
        print("Numeric box:", Value)
    end
})

-- standalone keybind (with mode menu: Toggle / Hold / Always)
InputSection:Keybind({
    Name = "Test Keybind",
    Flag = "testkeybind",
    Default = Enum.KeyCode.Delete,
    Callback = function(Value)
        print("Keybind pressed:", Value)
    end
})

-- compact keybind row
InputSection:Sub2keybind({
    Name = "Action Key",
    Flag = "actionkey",
    Default = Enum.KeyCode.G,
    Mode = "Toggle",
    Callback = function(Toggled)
        print("Sub2keybind toggled:", Toggled)
    end
})

-- label
local MyLabel = InputSection:Label("Plain label")

-- label + colorpicker
InputSection:Label("ESP Color"):Colorpicker({
    Flag = "EspMainColor",
    Default = Color3.fromRGB(255, 255, 255),
    Alpha = true,
    Callback = function(Value)
        print("Label color:", Value)
    end
})

-- buttons
InputSection:Button({
    Name = "Test Notification",
    Callback = function()
        Library:Notification({
            Title = "System",
            Description = "This is a test notification!",
            Duration = 5,
            Icon = "85279746515974"
        })
    end
})

InputSection:Button({
    Name = "Button With Icon",
    Icon = "85279746515974",
    Callback = function()
        print("Button with icon pressed")
    end
})

--============================================================
-- CATEGORY: Extra
--============================================================
Window:Category("Extra")

local ApiPage = Window:Page({Name = "API", Icon = "138827881557940", Columns = 2})
local ApiSection = ApiPage:Section({Name = "Element Methods", Side = 1})

ApiSection:Button({
    Name = "Toggle:Set(true)",
    Callback = function()
        PlainToggle:Set(true)
        print("Toggle:Get() =", PlainToggle:Get())
    end
})

ApiSection:Button({
    Name = "Slider:Set(50)",
    Callback = function()
        SpeedSlider:Set(50)
        print("Slider:Get() =", SpeedSlider:Get())
    end
})

ApiSection:Button({
    Name = "Dropdown:Add / Remove / Refresh",
    Callback = function()
        SingleDropdown:Add("NewPart")
        task.wait(1)
        SingleDropdown:Remove("NewPart")
        task.wait(1)
        SingleDropdown:Refresh({ "Head", "Torso", "LeftArm", "RightArm" }, "Head")
        print("Dropdown:Get() =", SingleDropdown:Get())
    end
})

ApiSection:Button({
    Name = "Listbox:Refresh (players)",
    Callback = function()
        local Names = { }
        for _, Player in game:GetService("Players"):GetPlayers() do
            table.insert(Names, Player.Name)
        end
        ListBox:Refresh(Names)
    end
})

ApiSection:Button({
    Name = "Label:SetText",
    Callback = function()
        MyLabel:SetText("Label changed at " .. os.date("%X"))
    end
})

ApiSection:Button({
    Name = "SubKeybind:Set / SetMode",
    Callback = function()
        SubKeybind:Set(Enum.KeyCode.B)
        SubKeybind:SetMode("Hold")
        print("SubKeybind:Get() =", SubKeybind:Get())
    end
})

ApiSection:Button({
    Name = "Hide element (SetVisibility)",
    Callback = function()
        KeybindToggle:SetVisibility(false)
        task.wait(2)
        KeybindToggle:SetVisibility(true)
    end
})

local WindowSection = ApiPage:Section({Name = "Window / Library", Side = 1})

WindowSection:Button({
    Name = "Close UI (SetOpen false)",
    Callback = function()
        Window:SetOpen(false)
        task.wait(2)
        Window:SetOpen(true)
    end
})

WindowSection:Button({
    Name = "Center window",
    Callback = function()
        Window:SetCenter()
    end
})

WindowSection:Toggle({
    Name = "Show Keybind List",
    Flag = "KeybindListVisible",
    Default = true,
    Callback = function(Value)
        KeybindList:SetVisibility(Value)
    end
})

WindowSection:Dropdown({
    Name = "Language",
    Flag = "LanguagePicker",
    Items = Library:GetLanguages(),
    Default = Library:GetLocale(),
    Callback = function(Value)
        Library:SetLocale(Value)
    end
})

WindowSection:Button({
    Name = "Change Accent (random)",
    Callback = function()
        local NewColor = Color3.fromHSV(math.random(), 0.8, 1)
        Library:ChangeTheme("Accent", NewColor)
        Library:ChangeTheme("AccentGradient", NewColor)
    end
})

WindowSection:Button({
    Name = "Unload",
    Callback = function()
        Library:Unload()
    end
})

--// Global chat panel (takes a whole column)
ApiPage:GlobalChat(2)

if Library.GlobalChatt then
    Library.GlobalChatt:SetStatus("Connected", Color3.fromRGB(90, 220, 120))
    Library.GlobalChatt:OnMessageSendPressed(function()
        local Message = Library.GlobalChatt:GetTypedMessage()
        if Message ~= "" then
            Library.GlobalChatt:SendMessage(85279746515974, "You", Message, true)
            Library.GlobalChatt:ClearText()
        end
    end)
end

--============================================================
-- CATEGORY: Settings (configs / UI settings page built by the library)
--============================================================
Window:Category("Settings")
local SettingsPage = Library:CreateSettingsPage(Window, KeybindList)

local SilentLoadEnabled = false
pcall(function()
    local path = Library.Folders.Configs .. "/silentload.txt"
    if isfile and isfile(path) and readfile then
        local ok, content = pcall(readfile, path)
        if ok and content == "true" then
            SilentLoadEnabled = true
        end
    end
end)

Window:Init()

if SilentLoadEnabled and Window.SetOpen then
    Window:SetOpen(false)
end

Library:Notification({
    Title = "JX",
    Description = "Script Has Been Successfully Loaded!",
    Duration = 5,
    Icon = "85279746515974"
})
