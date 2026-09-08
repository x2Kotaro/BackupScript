local NotificationLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/IceMinisterq/Notification-Library/Main/Library.lua"))()

if game:GetService("CoreGui"):FindFirstChild("WindUI") then
    return
    NotificationLibrary:SendNotification("Info", "You already have a script.", 3)
end

getgenv().ConfigurationTable = {}
getgenv().Settings = {}

local FolderConfiguration = "Venuz Hub"
local FolderSettings = "Venuz Hub/Raise_Animals"
local FolderSlots = "Venuz Hub/Slots"
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local chr = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local hrp = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
local humanoid = chr:WaitForChild("Humanoid")
local HttpService = game:GetService("HttpService")
local VenuzIcon = "rbxassetid://92691624917972"
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local UserId = LocalPlayer.UserId

local filenameConfiguration = FolderConfiguration .. "/" .. "Setting" .. ".json"
local filenameSetting = FolderSettings .. "/" .. "Raise_Animals".. LocalPlayer.Name .. ".json"

--------------------------- Configuration ---------------------------

local DefaultConfiguration = {
    Themes = "Dark",
    Transparent = true,
    AntiAFK = true,
    AutoExecutor = true,
    MinimizeBind = "End",
    Language = "English",
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
            warn("[Configuration] Failed to decode, using default.")
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

--------------------------- SaveSettings ---------------------------

local DefaultSettings = {
    ["Main"] = {
        ["SelectFood"] = "",
        ["SelectAnimal"] = {},
        ["AutoFeed"] = false,
        ["SelectAnimalPickup"] = {},
        ["PickupAnimal"] = false,
    }
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

if getgenv().Configuration and next(getgenv().Configuration) then
    for key, value in pairs(getgenv().Configuration) do
        if getgenv().Settings[key] ~= nil then
            getgenv().Settings[key] = value
        end
    end
    SaveSetting()
end

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/x2Kotaro/API/refs/heads/main/test.lua"))()

local Device
if UserInputService.TouchEnabled then
    Device = UDim2.fromOffset(450, 300)
else
    Device = UDim2.fromOffset(650, 520)
end

WindUI:Localization({
    Enabled = true,
    Prefix = "tr:",
    DefaultLanguage = "en",
    Translations = {
        ["th"] = {
            ["Home"] = "สัตว์",
            ["Configuration"] = "การตั้งค่า",
            ["AutoFeedTab"] = "ให้อาหารออโต้",
            ["StatusFeed"] = "สถานะ",
            ["SelectFood"] = "SelectFood",
            ["SelectAnimals"] = "SelectAnimals",
        },
        ["en"] = {
            ["Home"] = "Pet",
            ["Configuration"] = "Configuration",
            ["AutoFeedTab"] = "Auto Feed",
            ["StatusFeed"] = "Status",
            ["SelectFood"] = "เลือกอาหาร",
            ["SelectAnimals"] = "เลือกสัตว์ที่จะให้อาหาร",
        },
    }
})

local Window = WindUI:CreateWindow({
    Title = "Venuz Hub",
    Icon = VenuzIcon,
    Author = "by Phoenix",
    Size = Device,
    Transparent = getgenv().ConfigurationTable.Transparent,
    Theme = getgenv().ConfigurationTable.Themes,
    SideBarWidth = 200,
    HasOutline = true,
    ScrollBarEnabled = true,
    Resizable = false,
})

local Tabs = {
    Home = Window:Tab({ Title = "tr:Home", Icon = "star", ShowTabTitle = true}),
    divider1 = Window:Divider(),
    Configuration = Window:Tab({ Title = "tr:Configuration", Icon = "settings", Desc = "Manage window settings and themes.", ShowTabTitle = true}),
}

-------------------------------- Pet --------------------------------

------------- AutoFeed -------------

local Data = game:GetService("ReplicatedStorage").Shared.Info.ItemsStockData
local sucess, moduledata = pcall(getscriptclosure(Data))
local FoodTable = {}
local AnimalTable = {}
local AutoFeed

for i,v in pairs(moduledata["Food"]) do
   table.insert(FoodTable, i)
end

for _, module in ipairs(game:GetService("ReplicatedStorage").Shared.Info.Animals:GetChildren()) do
	if module:IsA("ModuleScript") then
		local success, data = pcall(require, module)
		if success and type(data) == "table" then
			for name, info in pairs(data) do
				if type(info) == "table" and info.DisplayName then
					table.insert(AnimalTable, info.DisplayName)
				end
			end
		end
	end
end

local AutoFeedTab = Tabs.Home:Section({ Title = "tr:AutoFeedTab", Opened = true,})

local StatusFeed = Tabs.Home:Paragraph({
    Title = "tr:StatusFeed",
    Desc = "<font color='#E53E3E'>Status: Not Feeding</font>",
})

local SelectFood = Tabs.Home:Dropdown({
    Title = "Select Food",
    Desc = "Select food to feed animals",
    Value = getgenv().Settings.Main.SelectFood,
    Values = FoodTable,
    Multi = false,
    AllowNone = false,
    Callback = function(Value)
        getgenv().Settings.Main.SelectFood = Value
        SaveSetting()
    end
})

local SelectAnimals = Tabs.Home:Dropdown({
    Title = "Select Animals",
    Desc = "Select animals to feed",
    Value = getgenv().Settings.Main.SelectAnimal,
    Values = AnimalTable,
    Multi = true,
    AllowNone = false,
    Callback = function(Value)
        getgenv().Settings.Main.SelectAnimal = Value
        SaveSetting()
    end
})

AutoFeed = Tabs.Home:Toggle({
    Title = "Auto Feed",
    Desc = "Feed automatically when equip food",
    Value = getgenv().Settings.Main.AutoFeed,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Main.AutoFeed = Value
        SaveSetting()

        task.spawn(function()
            pcall(function()
                if Value then
                    while getgenv().Settings.Main.AutoFeed do task.wait()

                        if getgenv().Settings.Main.SelectFood == "" then
                            WindUI:Notify({Title = "Venuz | Error",Content = "Please Select your Food",Icon = VenuzIcon,Duration = 5,})
                            task.wait(1)
                            AutoFeed:Set(false)
                            StatusFeed:SetDesc("<font color='#E53E3E'>Status: Not Feeding</font>")
                            return
                        elseif #getgenv().Settings.Main.SelectAnimal == 0 then
                            WindUI:Notify({Title = "Venuz | Error",Content = "Please Select your Animal",Icon = VenuzIcon,Duration = 5,})
                            task.wait(1)
                            AutoFeed:Set(false)
                            StatusFeed:SetDesc("<font color='#E53E3E'>Status: Not Feeding</font>")
                            return
                        end

                        local tool = LocalPlayer.Character:FindFirstChild(getgenv().Settings.Main.SelectFood)
                        local AmountFood = 0

                        if tool then
                            local amountObj = tool:FindFirstChild("Amount")
                            if amountObj then
                                AmountFood = amountObj.Value
                            end
                        end

                        if tool and tool:IsA("Tool") then
                            for i,v in pairs(game:GetService("ReplicatedStorage").Player_Data[LocalPlayer.Name].Tycoons:GetChildren()) do
                                if table.find(getgenv().Settings.Main.SelectAnimal, v.Name:split("|")[1]) then
                                    game:GetService("ReplicatedStorage").Remote.Events.ManagementEvent:FireServer("Feed", v.Name)
                                    StatusFeed:SetDesc("<font color='#FF69B4'>Pet Name : </font>"..v.Name:split("|")[1].."\n".."<font color='#4299E1'>Food Amount : </font>"..tostring(AmountFood))
                                end
                            end
                        else
                            StatusFeed:SetDesc("<font color='#E53E3E'>Status: Not Feeding</font>")
                            humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild(getgenv().Settings.Main.SelectFood))
                        end
                    end
                else
                    StatusFeed:SetDesc("<font color='#E53E3E'>Status: Not Feeding</font>")
                end
            end)
        end)
    end
})

------------- PickUp -------------

local PickUpTab = Tabs.Home:Section({ Title = "Pick Up"})
local SelectAnimal
local AnimalDropdownTable = {}
local AnimalNameMap = {}

local PlayerData = game:GetService("ReplicatedStorage").Player_Data[game.Players.LocalPlayer.Name]
local AnimalsInventory = PlayerData:WaitForChild("AnimalsInventory")
local Tycoons = PlayerData:WaitForChild("Tycoons")

local function UpdateDropdown()
    -- สร้าง Set ของชื่อจริงใน Tycoons
    local TycoonSet = {}
    for _, v in pairs(Tycoons:GetChildren()) do
        local nameOnly = v.Name:split("|")[1]
        TycoonSet[nameOnly] = true
    end

    -- ตรวจสอบ AnimalDropdownTable และ AnimalNameMap
    -- ลบรายการที่ไม่อยู่ใน Tycoons
    for displayName, realName in pairs(AnimalNameMap) do
        local animalName = realName:split("|")[1]
        if not TycoonSet[animalName] then
            -- ลบจาก Map
            AnimalNameMap[displayName] = nil
            -- ลบจาก Dropdown Table
            for i, name in ipairs(AnimalDropdownTable) do
                if name == displayName then
                    table.remove(AnimalDropdownTable, i)
                    break
                end
            end
        end
    end

    -- เพิ่มรายการใหม่ที่อยู่ใน Tycoons แต่ยังไม่มีใน Map
    for _, v in pairs(AnimalsInventory:GetChildren()) do
        local nickObj = v:FindFirstChild("Nicknames")
        local levelObj = v:FindFirstChild("Level")
        if nickObj and levelObj then
            local animalName = v.Name:split("|")[1]
            local displayName = animalName.." ("..nickObj.Value..") (Lv."..levelObj.Value..")"

            if TycoonSet[animalName] and not AnimalNameMap[displayName] then
                table.insert(AnimalDropdownTable, displayName)
                AnimalNameMap[displayName] = v.Name
            end
        end
    end

    if SelectAnimal then
        SelectAnimal:Refresh(AnimalDropdownTable)
        -- กำหนดค่า Value ปัจจุบันให้ตรงกับ Settings
        if getgenv().Settings.Main.SelectAnimal then
            SelectAnimal:Select(getgenv().Settings.Main.SelectAnimal)
        end
    end
end

SelectAnimal = Tabs.Home:Dropdown({
    Title = "Select Animal",
    Desc = "Select animals to pick up",
    Value = getgenv().Settings.Main.SelectAnimal,
    Values = AnimalDropdownTable,
    Multi = true,
    AllowNone = false,
    Callback = function(Value)
        getgenv().Settings.Main.SelectAnimal = Value
        SaveSetting()
    end
})

UpdateDropdown()

local PickupSelected = Tabs.Home:Button({
    Title = "Pick Up [Select]",
    Desc = "Pick up the animals you selected",
    Callback = function()
        for _, displayName in pairs(getgenv().Settings.Main.SelectAnimal) do
            local realName = AnimalNameMap[displayName]
            if realName then
                game:GetService("ReplicatedStorage").Remote.Events.ManagementEvent:FireServer("PickUp", realName)
            end
        end
    end
})

local PickupAll = Tabs.Home:Button({
    Title = "Pick Up [All]",
    Desc = "Pick up the animals you all",
    Callback = function()
        for i,v in pairs(game:GetService("ReplicatedStorage").Player_Data[LocalPlayer.Name].Tycoons:GetChildren()) do
            game:GetService("ReplicatedStorage").Remote.Events.ManagementEvent:FireServer("PickUp", v.Name)
        end
    end
})

Tycoons.ChildAdded:Connect(UpdateDropdown)
Tycoons.ChildRemoved:Connect(UpdateDropdown)

-------------------------------- Configuration --------------------------------

local IS = Tabs.Configuration:Section({ Title = "Interface Settings" })

local themeValues = {}
for name, _ in pairs(WindUI:GetThemes()) do
    table.insert(themeValues, name)
end

local themeDropdown = Tabs.Configuration:Dropdown({
    Title = "Select Theme",
    Multi = false,
    AllowNone = false,
    Value = getgenv().ConfigurationTable.Themes,
    Values = themeValues,
    Callback = function(theme)
        getgenv().ConfigurationTable.Themes = theme
        SaveConfiguration()
        WindUI:SetTheme(theme)
    end
})

themeDropdown:Select(WindUI:GetCurrentTheme())

local ToggleTransparency = Tabs.Configuration:Toggle({
    Title = "Toggle Window Transparency",
    Value = getgenv().ConfigurationTable.Transparent,
    Icon = "check",
    Callback = function(e)
        getgenv().ConfigurationTable.Transparent = e
        SaveConfiguration()
        Window:ToggleTransparency(e)
    end,
    Value = WindUI:GetTransparency()
})

local AntiAFK = Tabs.Configuration:Toggle({
    Title = "Anti-AFK",
    Value = getgenv().ConfigurationTable.AntiAFK,
    Icon = "check",
    Callback = function(enabled)
        local VirtualUser = game:service('VirtualUser')
        local antiAfkConnection = nil

        getgenv().ConfigurationTable.AntiAFK = enabled
        SaveConfiguration()

        if enabled then
            antiAfkConnection = game:GetService("Players").LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        elseif antiAfkConnection then
            antiAfkConnection:Disconnect()
        end
    end
})

local AutoExecutor = Tabs.Configuration:Toggle({
    Title = "AutoExecutor",
    Value = getgenv().ConfigurationTable.AutoExecutor,
    Icon = "check",
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoExecutor = Value
        SaveConfiguration()
    end
})

local MinimizeBind = Tabs.Configuration:Keybind({
    Title = "Minimize Bind",
    Value = getgenv().ConfigurationTable.MinimizeBind,
    Callback = function(v)
        getgenv().ConfigurationTable.MinimizeBind = v
        SaveConfiguration()
        Window:SetToggleKey(Enum.KeyCode[v])
    end
})

local Language
local ChangedLanguage
local LanguageTab

LanguageTab =  Tabs.Configuration:Section({ Title = "↪ Language" })

Language = Tabs.Configuration:Dropdown({
    Title = "Language",
    Multi = false,
    AllowNone = false,
    Values = {"English (US)","Thai",},
    Value = getgenv().ConfigurationTable.Language,
    Callback = function(Callback)
        LanguageSelect = Callback
        getgenv().ConfigurationTable.Language = Callback
        SaveConfiguration()
    end
})

ChangedLanguage = Tabs.Configuration:Button({
    Title = "Change Language",
    Callback = function()
        if LanguageSelect == "English (US)" then
            WindUI:SetLanguage("en")
        elseif LanguageSelect == "Thai" then
            WindUI:SetLanguage("th")
        end
        Window:SelectTab(1)
    end
})

local queueteleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
local TeleportCheck = false

while not Players.LocalPlayer do task.wait() end

LocalPlayer.OnTeleport:Connect(function(State)
    pcall(function()
        if getgenv().ConfigurationTable and getgenv().ConfigurationTable.AutoExecutor and (not TeleportCheck) and queueteleport then
            TeleportCheck = true
            queueteleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/x2Kotaro/Venuz-hub/main/Loader.lua'))()")
        end
    end)
end)

Window:SetToggleKey(Enum.KeyCode[getgenv().ConfigurationTable.MinimizeBind])
Window:SelectTab(1)

WindUI:Notify({
    Title = "Script | Loader",
    Content = "Script Loader Successfully",
    Icon = VenuzIcon,
    Duration = 5,
})

local LanguageStartup = getgenv().ConfigurationTable.Language

if LanguageStartup == "English (US)" then
    WindUI:SetLanguage("en")
elseif LanguageStartup == "Thai" then
    WindUI:SetLanguage("th")
end