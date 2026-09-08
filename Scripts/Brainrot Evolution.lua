local NotificationLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/IceMinisterq/Notification-Library/Main/Library.lua"))()

if game:GetService("CoreGui"):FindFirstChild("     ") then
    return
    NotificationLibrary:SendNotification("Info", "You already have a script.", 3)
end

------------------------Anti AFK---------------------------

local VirtualUser = game:service 'VirtualUser'
game:service 'Players'.LocalPlayer.Idled:connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

_G.SettingsTable = {}
local Folder = "Venuz Hub/Brainrot Evolution"
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local filename = Folder .. "/" .. LocalPlayer.Name .. ".json"

function loadSettings()
    if readfile and isfile and isfile(filename) then
        _G.SettingsTable = HttpService:JSONDecode(readfile(filename))
    else
        _G.SettingsTable = {
            ["Automatic"] = {
                ["Language"] = {
                    ["Language"] = "English",
                },
                ["AutoFarm"] = {
                    ["SelectMobs"] = {},
                    ["AutoFarm"] = false,
                    ["KillAura"] = false,
                },
                ["Eggs"] = {
                    ["SelectEggs"] = nil,
                    ["AutoEgg"] = false,
                    ["Delay"] = 1,
                }

            },
        }
    end
end

function saveSettings()
    if writefile and makefolder then
        if not isfolder("Venuz Hub") then makefolder("Venuz Hub") end
        if not isfolder(Folder) then makefolder(Folder) end
        local json = HttpService:JSONEncode(_G.SettingsTable)
        writefile(filename, json)
    end
end

loadSettings()

if getgenv().Configuration and next(getgenv().Configuration) then
    for key, value in pairs(getgenv().Configuration) do
        if _G.SettingsTable[key] ~= nil then
            _G.SettingsTable[key] = value
        end
    end
    saveSettings()
end

------------------------Translations---------------------------

local Translations = {
    ["English"] = {
        -- Tabs --
        Automatic = "Automatic",
        Settings = "Settings",
        -- Section AutoFarm --
        SelectMobs = "Select Mobs",
        SelectMobs_Desc = "Select Mobs to Auto Farm.",
        Refresh = "Refresh",
        Refresh_Desc = "Click to update the mob list.",
        AutoFarm = "Auto Farm",
        AutoFarm_Desc = "Start an automatic farm.",
        KillAura = "Auto Attack",
        KillAura_Desc = "Auto attacks nearby enemies.",
        -- Section Eggs --
        Eggs = "Eggs",
        AutoEgg = "Auto Egg",
        AutoEgg_Desc = "Automatically open eggs of your choice.",
        SelectEggs = "Select Eggs",
        SelectEggs_Desc = "Select the eggs you want.",
        DelayAutoEgg = "Delay Auto Egg",
        DelayAutoEgg_Desc = "Adjust the Delay to open Auto Egg.",
    },
    ["Thai"] = {
        -- Tabs --
        Automatic = "อัตโนมัติ",
        Settings = "ตั้งค่า",
        -- Section AutoFarm
        SelectMobs = "เลือกมอนสเตอร์",
        SelectMobs_Desc = "เลือกมอนสเตอร์ที่เราจะฟาร์มอัตโนมัติ",
        Refresh = "รีเฟรช",
        Refresh_Desc = "คลิกเพื่ออัปเดตรายชื่อมอนสเตอร์",
        AutoFarm = "ฟาร์มอัตโนมัติ",
        AutoFarm_Desc = "เริ่มฟาร์มโดยอัตโนมัติ",
        KillAura = "โจมตีอัตโนมัติ",
        KillAura_Desc = "โจมตีศัตรูที่อยู่ใกล้อัตโนมัติ",
        -- Section Eggs
        Eggs = "ไข่",
        AutoEgg = "เปิดไข่ออโต้",
        AutoEgg_Desc = "เปิดไข่อัตโนมัติที่เราเลือก",
        SelectEggs = "เลือกไข่",
        SelectEggs_Desc = "เลือกไข่ที่เราต้องการ",
        DelayAutoEgg = "ดีเลย์การเปิดไข่",
        DelayAutoEgg_Desc = "ปรับเวลาดีเลย์การเปิดไข่",
    }
}

local function L(key)
    local lang = _G.SettingsTable.Automatic.Language.Language or "English"
    return Translations[lang][key] or Translations["English"][key] or key
end

local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/x2Kotaro/API/refs/heads/main/Fluent.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/x2Kotaro/API/refs/heads/main/Interface.Lua"))()
local UserInputService = game:GetService("UserInputService")
local WindowSize
if UserInputService.TouchEnabled then
    WindowSize = UDim2.fromOffset(450, 300)
else
    WindowSize = UDim2.fromOffset(580, 460)
end

local Window = Fluent:CreateWindow({
    Title = "Venuz Hub  -",
    SubTitle = "Brainrot Evolution [Beta]",
    TabWidth = 150,
    Size = WindowSize,
    Acrylic = true,
    Transparency = false,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.End
})

local Tabs = {
    Automatic = Window:AddTab({Title = "Automatic", Icon = "code-2"}),
    Settings = Window:AddTab({Title = "Settings", Icon = "settings"})
}
--Element
local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:FindFirstChild("HumanoidRootPart")
local LocalPlayer = game:GetService("Players").LocalPlayer
local ActiveTween = nil
local PlaceId = game.PlaceId

------------------------Select Mobs and Refresh---------------------------

local General = Tabs.Automatic:AddSection("↪ Auto Farm")

local function getUniqueMobNames()
    local player = game.Players.LocalPlayer
    if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return {}
    end

    local origin = player.Character.HumanoidRootPart.Position
    local maxDistance = 1000

    local BlacklistName = {
        ["4Pets"] = true,
        ["BossInfo"] = true,
        ["VIP"] = true,
        ["x2Exp"] = true,
        ["Pass"] = true,
        ["Marchent"] = true,
        ["Merchent1"] = true,
        ["Potion"] = true,
        ["BunnyBossCD"] = true,
    }

    local nameSet = {}
    for _, v in pairs(workspace:GetChildren()) do
        if v:IsA("Model") and v.Name ~= "Model" and not v:FindFirstChild("Head") then
            local primaryPart = v.PrimaryPart or v:FindFirstChild("HumanoidRootPart") or v:FindFirstChildWhichIsA("BasePart")
            if primaryPart then
                local distance = (primaryPart.Position - origin).Magnitude
                if distance <= maxDistance and not BlacklistName[v.Name] then
                    nameSet[v.Name] = true
                end
            end
        end
    end

    local uniqueNames = {}
    for name in pairs(nameSet) do
        table.insert(uniqueNames, name)
    end

    table.sort(uniqueNames)
    return uniqueNames
end

local lastValues = getUniqueMobNames()

local SelectMobs = General:AddDropdown("SelectMobs", {
    Title = L("Select Mobs"),
    Values = lastValues,
    Multi = true,
    Default = _G.SettingsTable.Automatic.AutoFarm.SelectMobs,
    Description = "Select Mobs to Auto Farm.",
    Callback = function(Value)
        local Values = {}
        for Value, State in next, Value do
            table.insert(Values, Value)
        end
        _G.SettingsTable.Automatic.AutoFarm.SelectMobs = Values
        saveSettings()
    end
})

local function compareTables(oldList, newList)
    local added, removed = {}, {}
    local oldSet, newSet = {}, {}

    for _, v in ipairs(oldList) do oldSet[v] = true end
    for _, v in ipairs(newList) do newSet[v] = true end

    for v in pairs(newSet) do
        if not oldSet[v] then
            table.insert(added, v)
        end
    end

    for v in pairs(oldSet) do
        if not newSet[v] then
            table.insert(removed, v)
        end
    end

    return added, removed
end

Refresh = General:AddButton({
    Title = "Refresh",
    Description = "Click to update the mob list.",
    Callback = function()
        local currentValues = getUniqueMobNames()
        local added, removed = compareTables(lastValues, currentValues)
        SelectMobs:SetValues(currentValues)
        lastValues = currentValues
    end
})

-------------------Auto Farm----------------------

local AutoFarm = General:AddToggle("AutoFarm", {
    Title = "Auto Farm",
    Default = _G.SettingsTable.Automatic.AutoFarm.AutoFarm,
    Description = "Start an automatic farm"
})

local AutoFarmRunning = false

AutoFarm:OnChanged(function(enabled)
    _G.SettingsTable.Automatic.AutoFarm.AutoFarm = enabled
    saveSettings()
    AutoFarmRunning = enabled

    task.spawn(function()
        while AutoFarmRunning and task.wait() do
            for _, mob in ipairs(workspace:GetChildren()) do
                if not AutoFarmRunning then break end
                if mob:IsA("Model") and table.find(_G.SettingsTable.Automatic.AutoFarm.SelectMobs, mob.Name) then
                    if mob:IsDescendantOf(workspace) then
                        pcall(function()
                            while mob and mob.Parent and AutoFarmRunning and mob:IsDescendantOf(workspace) do
                                local playerHRP = game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                if playerHRP then
                                    local mobPivot = mob:GetPivot()
                                    playerHRP.CFrame = mobPivot * CFrame.new(0, 8, 0)
                                end
                                task.wait()
                            end
                        end)
                    end
                end
            end
        end
    end)
end)

---------------------KillAura-------------------------

local KillAura = General:AddToggle("KillAura", {
    Title = "Kill Aura",
    Default = _G.SettingsTable.Automatic.AutoFarm.KillAura,
    Description = "Auto attacks nearby enemies."
})

local ATTACK_DISTANCE = 10

KillAura:OnChanged(function(Han)
    _G.SettingsTable.Automatic.AutoFarm.KillAura = Han
    saveSettings()

    if Han then
        task.spawn(function()
            while _G.SettingsTable.Automatic.AutoFarm.KillAura do task.wait()
                local player = game.Players.LocalPlayer
                local char = player.Character
                local playerHRP = char and char:FindFirstChild("HumanoidRootPart")
                if not playerHRP then continue end

                for _, mob in ipairs(workspace:GetChildren()) do
                    if not Han then break end
                    if mob:IsA("Model") then
                        local hrp = mob:FindFirstChild("HumanoidRootPart")
                        if hrp and mob:IsDescendantOf(workspace) then
                            local distance = (playerHRP.Position - hrp.Position).Magnitude
                            if distance <= ATTACK_DISTANCE then
                                pcall(function()
                                    local args = { hrp.CFrame }
                                    game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("MonsterService"):WaitForChild("RF"):WaitForChild("RequestAttack"):InvokeServer(unpack(args))
                                end)
                                task.wait()
                            end
                        end
                    end
                end
            end
        end)
    end
end)

---------------------Eggs-------------------------

local Eggs = Tabs.Automatic:AddSection("↪ Eggs")
local EggsTable = {}

for i,v in pairs(workspace.GameAssets.Eggs:GetChildren()) do
    table.insert(EggsTable, v.Name)
end

local SelectEggs = Eggs:AddDropdown("SelectEggs", {
    Title = "SelectEggs",
    Values = EggsTable,
    Default = _G.SettingsTable.Automatic.Eggs.SelectEggs,
    Description = "Select the eggs you want",
    Callback = function(Value)
        _G.SettingsTable.Automatic.Eggs.SelectEggs = Value
        saveSettings()
    end
})

local AutoEggs = Eggs:AddToggle("AutoEgg", {
    Title = "AutoEgg",
    Default = _G.SettingsTable.Automatic.Eggs.AutoEgg,
    Description = "Automatically open eggs of your choice",
})

AutoEggs:OnChanged(function(enabled)
    _G.SettingsTable.Automatic.Eggs.AutoEgg = enabled
    saveSettings()
    if enabled then
        while _G.SettingsTable.Automatic.Eggs.AutoEgg do
    game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("EggService"):WaitForChild("RF"):WaitForChild("OpenEgg"):InvokeServer(unpack({_G.SettingsTable.Automatic.Eggs.SelectEggs,1,false,{}}))
    task.wait(_G.SettingsTable.Automatic.Eggs.Delay)    
end    
  end
end)

local DelayAutoEgg = Eggs:AddSlider("DelayAutoEgg", {
    Title = "Delay Auto Egg",
    Default = _G.SettingsTable.Automatic.Eggs.Delay,
    Min = 1,
    Max = 10,
    Rounding = 0,
    Description = "Adjust the Delay to open Auto Egg",
    Callback = function(Value)
        _G.SettingsTable.Automatic.Eggs.Delay = Value
        saveSettings()
    end
})
---------------------InterfaceManager-------------------------

InterfaceManager:SetLibrary(Fluent)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)

---------------------Language-------------------------

function updateLanguage()
    -- อัพเดตชื่อ Tab
    if Tabs.Automatic then
        Tabs.Automatic:SetTitleTabsVenuz(L("Automatic"))
    end
    if Tabs.Settings then
        Tabs.Settings:SetTitleTabsVenuz(L("Settings"))
    end

    --อัพเดตส่วน Auto Farm
    if General then
        General:SetTitle("↪ " .. L("AutoFarm"))
    end
    
    if SelectMobs then
        SelectMobs:SetTitle(L("SelectMobs"))
        SelectMobs:SetDesc(L("SelectMobs_Desc"))
    end
    
    if Refresh then
        Refresh:SetTitle(L("Refresh"))
        Refresh:SetDesc(L("Refresh_Desc"))
    end
    
    if AutoFarm then
        AutoFarm:SetTitle(L("AutoFarm"))
        AutoFarm:SetDesc(L("AutoFarm_Desc"))
    end
    
    if KillAura then
        KillAura:SetTitle(L("KillAura"))
        KillAura:SetDesc(L("KillAura_Desc"))
    end

    --อัพเดตส่วน Eggs

    if Eggs then
        Eggs:SetTitle("↪ " .. L("Eggs"))
    end

    if AutoEggs then
        AutoEggs:SetTitle(L("AutoEgg"))
        AutoEggs:SetDesc(L("AutoEgg_Desc"))
    end

    if SelectEggs then
        SelectEggs:SetTitle(L("SelectEggs"))
        SelectEggs:SetDesc(L("SelectEggs_Desc"))
    end
    if DelayAutoEgg then
        DelayAutoEgg:SetTitle(L("DelayAutoEgg"))
        DelayAutoEgg:SetDesc(L("DelayAutoEgg_Desc"))
    end
end

local ChangedLanguage = Tabs.Settings:AddSection("↪ Language")

local SelectLanguage = ChangedLanguage:AddDropdown("SelectLanguage", {
    Title = "Language",
    Values = {"English", "Thai"},
    Default = _G.SettingsTable.Automatic.Language.Language,
    Callback = function(Value)
        LanguageSelect = Value
        _G.SettingsTable.Automatic.Language.Language = Value
        saveSettings()
    end
})

local ChangedLanguageButton =  ChangedLanguage:AddButton({
    Title = "Changed Language",
    Callback = function()
        _G.SettingsTable.Automatic.Language.Language = LanguageSelect
        updateLanguage()
        Window:SelectTab(1)
    end
})

Window:SelectTab(1)

Fluent:Notify({
    Title = "Script | Loader",
    Content = "Script Loader Venuz Hub",
    SubContent = "Success",
    Duration = 5
})

-----------------------------------Mobile---------------------------------------

local UserInputService = game:GetService("UserInputService")
if UserInputService.TouchEnabled then
    local ScreenGui = Instance.new("ScreenGui")
    local ImageButton = Instance.new("ImageButton")
    local UICorner = Instance.new("UICorner")
    
    ScreenGui.Parent = game:GetService("CoreGui")
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    ImageButton.Parent = ScreenGui
    ImageButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ImageButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ImageButton.BorderSizePixel = 0
    ImageButton.Position = UDim2.new(0.155857742, 0, 0.213838667, 0)
    ImageButton.Size = UDim2.new(0, 50, 0, 50)
    ImageButton.Image = "http://www.roblox.com/asset/?id=72281500336017"
    
    UICorner.Parent = ImageButton

    local Fluent = getgenv().Fluent
    if Fluent and Fluent.Window then
        ImageButton.MouseButton1Click:Connect(function()
            Fluent.Window:Minimize()
        end)
    end
function dragify(Frame, object)
	dragToggle = nil
	dragSpeed = .10
	dragInput = nil
	dragStart = nil
	dragPos = nil
	function updateInput(input)
		Delta = input.Position - dragStart
		Position =
			UDim2.new(startPos.X.Scale, startPos.X.Offset + Delta.X, startPos.Y.Scale, startPos.Y.Offset + Delta.Y)
		game:GetService("TweenService"):Create(object, TweenInfo.new(dragSpeed), {Position = Position}):Play()
	end
	ImageButton.InputBegan:Connect(
		function(input)
			if
				(input.UserInputType == Enum.UserInputType.MouseButton1 or
					input.UserInputType == Enum.UserInputType.Touch)
			then
				dragToggle = true
				dragStart = input.Position
				startPos = object.Position
				input.Changed:Connect(
					function()
						if (input.UserInputState == Enum.UserInputState.End) then
							dragToggle = false
						end
					end
				)
			end
		end
	)
	ImageButton.InputChanged:Connect(
		function(input)
			if
				(input.UserInputType == Enum.UserInputType.MouseMovement or
					input.UserInputType == Enum.UserInputType.Touch)
			then
				dragInput = input
			end
		end
	)
	game:GetService("UserInputService").InputChanged:Connect(
		function(input)
			if (input == dragInput and dragToggle) then
				updateInput(input)
			end
		end
	)
end

dragify(ImageButton, ImageButton)
end
updateLanguage()
Window:SelectTab(2)
Window:SelectTab(1)