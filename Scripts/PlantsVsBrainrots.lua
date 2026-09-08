local NotificationLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/IceMinisterq/Notification-Library/Main/Library.lua"))()

if game:GetService("CoreGui"):FindFirstChild("WindUI") then
    return
    NotificationLibrary:SendNotification("Info", "You already have a script.", 3)
end

getgenv().ConfigurationTable = {}
getgenv().Settings = {}

local FolderConfiguration = "Venuz Hub"
local FolderSettings = "Venuz Hub/PlantsVsBrainrots"
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
local filenameSetting = FolderSettings .. "/" .. "PlantsVsBrainrots".. LocalPlayer.Name .. ".json"

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
    ["AutoFarm"] = {
        ["AutoFarmBrainrots"] = false,
        ["AutoEquip"] = false,
    },

    ["AutoPlant"] = {
        ["SelectSeed"] = nil,
        ["AutoPlant"] = false,
        ["SelectSeedPlant"] = nil,
        ["AutoPlantPlant"] = false,
    },

    ["Collect"] = {
        ["AutoCollect"] = false,
        ["Delay"] = 5,
    },

    ["Purchases"] = {
        ["Seeds"] = {},
        ["BuySeeds"] = false,
        ["Gears"] = {},
        ["BuyGears"] = false,
        ["Garden"] = false,
        ["Brainrots"] = false,
    },

    ["AutoSell"] = {
        ["AutoSellBrainrots"] = false,
        ["Delay"] = 5,
    },

    ["Event"] = {
        ["Autoturnin"] = false,
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
    Device = UDim2.fromOffset(580, 460)
end

local Window = WindUI:CreateWindow({
    Title = "Venuz Hub",
    Icon = VenuzIcon,
    Author = "by Phoenix",
    Size = Device,
    Transparent = getgenv().ConfigurationTable.Transparent,
    Theme = getgenv().ConfigurationTable.Themes,
    SideBarWidth = 200,
    HasOutline = true,
})

local Tabs = {
    Automatic = Window:Tab({ Title = "Auto Attack", Icon = "swords", ShowTabTitle = true }),
    AutoPlant = Window:Tab({ Title = "Auto Plant", Icon = "flower", ShowTabTitle = true }),
    AutoCollect = Window:Tab({ Title = "Auto Collect", Icon = "handshake", ShowTabTitle = true }),
    AutoSell = Window:Tab({ Title = "Auto Sell", Icon = "shopping-cart", ShowTabTitle = true }),
    Purchase = Window:Tab({ Title = "Purchases", Icon = "shopping-basket", ShowTabTitle = true }),
    Event = Window:Tab({ Title = "Event", Icon = "gift", ShowTabTitle = true }),
    divider1 = Window:Divider(),
    Configuration = Window:Tab({ Title = "Configuration", Icon = "settings", Desc = "Manage window settings and themes.", ShowTabTitle = true}),
}

------------------------Translations---------------------------

local Translations = {
    ["English (US)"] = {
        -- Tabs --
        Automatic = "Auto Attack",
        AutoPlant = "Auto Plant",
        AutoCollect = "Auto Collect",
        AutoSell = "Auto Sell",
        Purchase = "Purchases",
        Event = "Event",
        Configuration = "Configuration",
        -- Section Auto Attack --
        AutoFarmTabs = "↪ Auto Farm",
        AutoFarm = "Auto Farm Brainrots",
        -- Section Auto Plant --
        AutoPlantTabs = "↪ Auto Plant",
        SelectSeed = "Select Seed",
        AutoPlant = "Auto Plant",
        AutoPlantTab2 = "↪ Auto Plant (Plant)",
        SelectSeed2 = "Select Plant",
        AutoPlant2 = "Auto Plant (Plant)",
        -- Section Auto Collect --
        AutoCollectTabs1 = "↪ Auto Collect",
        AutoEquipBest = "Auto Collect & Auto Equip Best",
        DelayEquipBest = "Delay",
        AutoCollectTabs2 = "↪ Plant",
        CollectAllPlant = "Collect All Plants",
        -- Section Auto Sell --
        AutoSellTab = "↪ Auto Sell",
        AutoSellBrainrots = "Auto Sell Brainrots",
        Delay = "Delay",
        -- Section Purchases --
        BuySeedTabs = "↪ Auto Buy Seeds",
        SelectSeeds = "Select Seeds",
        BuySeeds = "Buy Seeds",
        BuyGearTabs = "↪ Auto Buy Gears",
        SelectGears = "Select Gears",
        BuyGears = "Buy Gears",
        gardenandbrainrot = "↪ Garden & Brainrots",
        Garden = "Auto Buy Row Garden",
        Brainrots = "Auto Buy Plant Brainrots",
        -- Section Event --
        EventTabs = "↪ Event",
        AutoTrunin = "Auto Turn In Brainrot",
        -- Section Configuration --
        themeDropdown = "Select Theme",
        ToggleTransparency = "Toggle Window Transparency",
        AntiAFK = "Anti-AFK",
        AutoExecutor = "AutoExecutor",
        MinimizeBind = "Minimize Bind",
        LanguageTab = "↪ Language",
        Interface = "↪ Interface Settings",
        Language = "Language",
        ChangedLanguage = "Change Language",
    },
    ["Thai"] = {
        -- Tabs --
        Automatic = "โจมตีอัตโนมัติ",
        AutoPlant = "ปลูกอัตโนมัติ",
        AutoCollect = "เก็บเกี่ยวอัตโนมัติ",
        AutoSell = "ขายอัตโนมัติ",
        Purchase = "การซื้อ",
        Event = "กิจกรรม",
        Configuration = "การตั้งค่า",
        -- Section Auto Attack --
        AutoFarmTabs = "↪ ฟาร์มอัตโนมัติ",
        AutoFarm = "ฟาร์มเบรนรอตอัตโนมัติ",
        -- Section Auto Plant --
        AutoPlantTabs = "↪ ปลูกอัตโนมัติ",
        SelectSeed = "เลือกเมล็ดพันธุ์",
        AutoPlant = "ปลูกอัตโนมัติ",
        AutoPlantTab2 = "↪ ปลูกอัตโนมัติ (แบบพืช)",
        SelectSeed2 = "เลือกพืช",
        AutoPlant2 = "ปลูกอัตโนมัติ (พืช)",
        -- Section Auto Collect --
        AutoCollectTabs1 = "↪ เก็บเกี่ยวอัตโนมัติ",
        AutoEquipBest = "เก็บเงินและใส่เบรนรอต (ที่ดีที่สุด) อัตโนมัติ",
        DelayEquipBest = "ล่าช้า",
        AutoCollectTabs2 = "↪ พืช",
        CollectAllPlant = "เก็บเกี่ยวพืชทั้งหมด",
        -- Section Auto Sell --
        AutoSellTab = "↪ ขายอัตโนมัติ",
        AutoSellBrainrots = "ขายเบรนรอตอัตโนมัติ",
        Delay = "ล่าช้า",
        -- Section Purchases --
        BuySeedTabs = "↪ ซื้อเมล็ดพันธุ์อัตโนมัติ",
        SelectSeeds = "เลือกเมล็ดพันธุ์",
        BuySeeds = "ซื้อเมล็ดพันธุ์",
        BuyGearTabs = "↪ ซื้ออุปกรณ์อัตโนมัติ",
        SelectGears = "เลือกอุปกรณ์",
        BuyGears = "ซื้ออุปกรณ์",
        gardenandbrainrot = "↪ สวนและเบรนรอต",
        Garden = "ซื้อแถวสวนอัตโนมัติ",
        Brainrots = "ซื้อพืชเบรนรอตอัตโนมัติ",
        -- Section Event --
        EventTabs = "↪ กิจกรรม",
        AutoTrunin = "ส่งภารกิจเบรนรอตอัตโนมัติ",
        -- Section Configuration --
        themeDropdown = "เลือกธีม",
        ToggleTransparency = "เปิด/ปิดความโปร่งใสของหน้าต่าง",
        AntiAFK = "ป้องกันการหลุดออกจากแมป (Anti-AFK)",
        AutoExecutor = "รันอัตโนมัติ (Auto Executor)",
        MinimizeBind = "ปุ่มย่อหน้าต่าง",
        Interface = "↪ การตั้งค่าอินเทอร์เฟซ",
        LanguageTab = "↪ ภาษา",
        Language = "ภาษา",
        ChangedLanguage = "เปลี่ยนภาษา",
    },
    ["Vietnamese"] = {
        -- Tabs --
        Automatic = "โจมตีอัตโนมัติ",
        AutoPlant = "ปลูกอัตโนมัติ",
        AutoCollect = "เก็บเกี่ยวอัตโนมัติ",
        AutoSell = "ขายอัตโนมัติ",
        Purchase = "การซื้อ",
        Event = "กิจกรรม",
        Configuration = "การตั้งค่า",
        -- Section Auto Attack --
        AutoFarmTabs = "↪ ฟาร์มอัตโนมัติ",
        AutoFarm = "ฟาร์มเบรนรอตอัตโนมัติ",
        -- Section Auto Plant --
        AutoPlantTabs = "↪ ปลูกอัตโนมัติ",
        SelectSeed = "เลือกเมล็ดพันธุ์",
        AutoPlant = "ปลูกอัตโนมัติ",
        AutoPlantTab2 = "↪ ปลูกอัตโนมัติ (แบบพืช)",
        SelectSeed2 = "เลือกพืช",
        AutoPlant2 = "ปลูกอัตโนมัติ (พืช)",
        -- Section Auto Collect --
        AutoCollectTabs1 = "↪ เก็บเกี่ยวอัตโนมัติ",
        AutoEquipBest = "เก็บเกี่ยวและใส่อุปกรณ์ที่ดีที่สุดอัตโนมัติ",
        DelayEquipBest = "ล่าช้า",
        AutoCollectTabs2 = "↪ พืช",
        CollectAllPlant = "เก็บเกี่ยวพืชทั้งหมด",
        -- Section Auto Sell --
        AutoSellTab = "↪ ขายอัตโนมัติ",
        AutoSellBrainrots = "ขายเบรนรอตอัตโนมัติ",
        Delay = "ล่าช้า",
        -- Section Purchases --
        BuySeedTabs = "↪ ซื้อเมล็ดพันธุ์อัตโนมัติ",
        SelectSeeds = "เลือกเมล็ดพันธุ์",
        BuySeeds = "ซื้อเมล็ดพันธุ์",
        BuyGearTabs = "↪ ซื้ออุปกรณ์อัตโนมัติ",
        SelectGears = "เลือกอุปกรณ์",
        BuyGears = "ซื้ออุปกรณ์",
        gardenandbrainrot = "↪ สวนและเบรนรอต",
        Garden = "ซื้อแถวสวนอัตโนมัติ",
        Brainrots = "ซื้อพืชเบรนรอตอัตโนมัติ",
        -- Section Event --
        EventTabs = "↪ กิจกรรม",
        AutoTrunin = "ส่งภารกิจเบรนรอตอัตโนมัติ",
        -- Section Configuration --
        themeDropdown = "เลือกธีม",
        ToggleTransparency = "เปิด/ปิดความโปร่งใสของหน้าต่าง",
        AntiAFK = "ป้องกันการหลุดออกจากแมป (Anti-AFK)",
        AutoExecutor = "รันอัตโนมัติ (Auto Executor)",
        MinimizeBind = "ปุ่มย่อหน้าต่าง",
        Interface = "↪ การตั้งค่าอินเทอร์เฟซ",
        LanguageTab = "↪ ภาษา",
        Language = "ภาษา",
        ChangedLanguage = "เปลี่ยนภาษา",
    }
}

local function L(key)
    local lang = getgenv().ConfigurationTable.Language or "English"
    return Translations[lang][key] or Translations["English"][key] or key
end

-------------------------------- Function --------------------------------

function TeleportToWaypoint(Position)
    hrp.CFrame = Position
end

for i,v in pairs(workspace.Plots:GetChildren()) do
    if v:GetAttribute("Owner") == game.Players.LocalPlayer.Name then
        getgenv().MyPlots = v.Name
    end
end

local placeableParts = {}

for _, v in pairs(workspace.Plots:GetChildren()) do
    if v:GetAttribute("Owner") == game.Players.LocalPlayer.Name then
        getgenv().Plots = v
        break
    end
end

for _, folder in pairs(getgenv().Plots.Rows:GetChildren()) do
    local grassFolder = folder:FindFirstChild("Grass")
    if grassFolder then
        for _, part in pairs(grassFolder:GetChildren()) do
            table.insert(placeableParts, part)
        end
    end
end

-------------------------------- Automatic --------------------------------

local AutoFarmTabs = Tabs.Automatic:Section({ Title = "Auto Farm" })

local AutoFarm = Tabs.Automatic:Toggle({
    Title = "Auto Farm Brainrots",
    Value = getgenv().Settings.AutoFarm.AutoFarmBrainrots,
    Icon = "check",
    Callback = function(Callback)
        getgenv().Settings.AutoFarm.AutoFarmBrainrots = Callback
        SaveSetting()

        if Callback then
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.AutoFarm.AutoFarmBrainrots do task.wait()

                    for i, v in pairs(game:GetService("Players").LocalPlayer.Backpack:GetChildren()) do
                        if v.Name:lower():find("bat") then
                            if not game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool") or game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool").Name ~= "Bat" then
                                game.Players.LocalPlayer.Character.Humanoid:EquipTool(v)
                            end
                        end
                    end

                    local CurrentTarget = nil

                    if not CurrentTarget or not CurrentTarget.Parent then
                        CurrentTarget = nil
                        for i, v in pairs(workspace.ScriptedMap.Brainrots:GetChildren()) do
                            local Distance = (v.RootPart.Position - hrp.Position).Magnitude
                            if Distance < 70 then
                                CurrentTarget = v
                                break
                            end
                        end
                    end
            
                    if CurrentTarget then
                        repeat task.wait()
                            if CurrentTarget.Parent then
                                TeleportToWaypoint(CurrentTarget.RootPart.CFrame * CFrame.new(0,-5,0))
                                game:GetService("ReplicatedStorage").Remotes.AttacksServer.WeaponAttack:FireServer({[1] = CurrentTarget.Name})
                            end
                        until not CurrentTarget.Parent or not getgenv().Settings.AutoFarm.AutoFarmBrainrots
                    end
                end
                end)
            end)
        end
    end
})

-------------------------------- Auto Plant --------------------------------

local AutoPlantTabs = Tabs.AutoPlant:Section({ Title = "Auto Plant" })

local SelectSeed = Tabs.AutoPlant:Dropdown({
    Title = "Select Seed",
    Multi = false,
    AllowNone = true,
    Values = {"Cactus","Strawberry","Sunflower","Pumpkin","Dragon Fruit","Eggplant","Watermelon","Cocotank","Carnivorous Plant","Mr Carrot","Tomatrio"},
    Value = getgenv().Settings.AutoPlant.SelectSeed,
    Callback = function(Value)
        getgenv().Settings.AutoPlant.SelectSeed = Value
        SaveSetting()
    end
})

local AutoPlant = Tabs.AutoPlant:Toggle({
    Title = "Auto Plant",
    Value = getgenv().Settings.AutoPlant.AutoPlant,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.AutoPlant.AutoPlant = Value
        SaveSetting()

        task.spawn(function()
            pcall(function()
                if Value then
                    while getgenv().Settings.AutoPlant.AutoPlant do task.wait(.3)
                        for i, v in pairs(game:GetService("Players").LocalPlayer.Backpack:GetChildren()) do
                            if v:GetAttribute("Plant") == getgenv().Settings.AutoPlant.SelectSeed then
                                if v:GetAttribute("Uses") then
                                if not game.Players.LocalPlayer.Character:FindFirstChild(v.Name) then
                                    game.Players.LocalPlayer.Character.Humanoid:EquipTool(v)
                                end
                            end
                        end
    
                            for i,v in pairs(game.Players.LocalPlayer.Character:GetChildren()) do
                                if v:IsA("Tool") then
                                    local floorPart
                                    if #placeableParts > 0 then
                                        floorPart = placeableParts[math.random(1, #placeableParts)]
                                    end
    
                                    local ohTable1 = {
                                        ["ID"] = v:GetAttribute("ID"),
                                        ["CFrame"] = floorPart.CFrame,
                                        ["Item"] = v:GetAttribute("Plant"),
                                        ["Floor"] = floorPart
                                    }
    
                                    game:GetService("ReplicatedStorage").Remotes.PlaceItem:FireServer(ohTable1)
                                end
                            end
                        end
                    end
                end
            end)
        end)
    end
})

local AutoPlantTab2 = Tabs.AutoPlant:Section({ Title = "Auto Plant (Plant)" })

local SelectSeed2 = Tabs.AutoPlant:Dropdown({
    Title = "Select Seed",
    Multi = false,
    AllowNone = true,
    Values = {"Cactus","Strawberry","Sunflower","Pumpkin","Dragon Fruit","Eggplant","Watermelon","Cocotank","Carnivorous Plant","Mr Carrot","Tomatrio"},
    Value = getgenv().Settings.AutoPlant.SelectSeedPlant,
    Callback = function(Value)
        getgenv().Settings.AutoPlant.SelectSeedPlant = Value
        SaveSetting()
    end
})

local AutoPlant2 = Tabs.AutoPlant:Toggle({
    Title = "Auto Plant (Plant)",
    Value = getgenv().Settings.AutoPlant.AutoPlant,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.AutoPlant.AutoPlantPlant = Value
        SaveSetting()

        task.spawn(function()
            pcall(function()
                if Value then
                    while getgenv().Settings.AutoPlant.AutoPlantPlant do task.wait(.3)
                        if not chr:IsA("Tool") then
                        for i, v in pairs(game:GetService("Players").LocalPlayer.Backpack:GetChildren()) do
                            if v:GetAttribute("Plant") == getgenv().Settings.AutoPlant.SelectSeedPlant then
                                if not v:GetAttribute("Uses") then
                                if not game.Players.LocalPlayer.Character:FindFirstChild(v.Name) then
                                    game.Players.LocalPlayer.Character.Humanoid:EquipTool(v)
                                end
                            end
                        end
                    end
    
                            for i,v in pairs(game.Players.LocalPlayer.Character:GetChildren()) do
                                if v:IsA("Tool") then
                                    local floorPart
                                    if #placeableParts > 0 then
                                        floorPart = placeableParts[math.random(1, #placeableParts)]
                                    end
    
                                    local ohTable1 = {
                                        ["ID"] = v:GetAttribute("ID"),
                                        ["CFrame"] = floorPart.CFrame,
                                        ["Item"] = v:GetAttribute("Plant"),
                                        ["Floor"] = floorPart
                                    }
    
                                    game:GetService("ReplicatedStorage").Remotes.PlaceItem:FireServer(ohTable1)
                                end
                            end
                        end
                    end
                end
            end)
        end)
    end
})

-------------------------------- Auto Collect --------------------------------

local AutoCollectTabs1 = Tabs.AutoCollect:Section({ Title = "Auto Collect" })

local AutoEquipBest = Tabs.AutoCollect:Toggle({
    Title = "Auto Collect & Auto Equip Best",
    Value = getgenv().Settings.Collect.AutoCollect,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Collect.AutoCollect = Value
        SaveSetting()

        task.spawn(function()
            pcall(function()
                if Value then
                    while getgenv().Settings.Collect.AutoCollect do task.wait(getgenv().Settings.Collect.Delay)
                        game:GetService("ReplicatedStorage").Remotes.EquipBest:Fire()
                    end
                end
            end)
        end)
    end
})

local DelayEquipBest = Tabs.AutoCollect:Slider({
    Title = "Delay",
    Value = {
        Min = 1,
        Max = 20,
        Default = getgenv().Settings.Collect.Delay,
    },
    Callback = function(Value)
        getgenv().Settings.Collect.Delay = Value
        SaveSetting()
    end
})

local AutoCollectTabs2 = Tabs.AutoCollect:Section({ Title = "Plant" })

local CollectAllPlant = Tabs.AutoCollect:Button({
    Title = "Collect All Plants",
    Value = getgenv().Settings.Collect.CollectAllPlant,
    Icon = "check",
    Callback = function(Value)
        for i,v in pairs(workspace.Plots[getgenv().MyPlots].Hitboxes:GetChildren()) do
            game:GetService("ReplicatedStorage").Remotes.RemoveItem:FireServer(v.Name)
        end
    end
})

-------------------------------- AutoSell --------------------------------

local AutoSellTab = Tabs.AutoSell:Section({ Title = "Auto Sell" })

local AutoSellBrainrots = Tabs.AutoSell:Toggle({
    Title = "Auto Sell Brainrots",
    Value = getgenv().Settings.AutoSell.AutoSellBrainrots,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.AutoSell.AutoSellBrainrots = Value
        SaveSetting()

        task.spawn(function()
            pcall(function()
                if Value then
                    while getgenv().Settings.AutoSell.AutoSellBrainrots do task.wait(getgenv().Settings.AutoSell.Delay)
                        if getgenv().Settings.AutoSell.AutoSellBrainrots then
                            game:GetService("ReplicatedStorage").Remotes.ItemSell:FireServer()
                        end
                    end
                end
            end)
        end)
    end
})

local Delay = Tabs.AutoSell:Slider({
    Title = "Delay",
    Value = {
        Min = 1,
        Max = 20,
        Default = getgenv().Settings.AutoSell.Delay,
    },
    Callback = function(Value)
        getgenv().Settings.AutoSell.Delay = Value
        SaveSetting()
    end
})

-------------------------------- Purchases --------------------------------

local Seeds = {}
local Gears = {"Water Bucket", "Frost Grenade", "Banana Gun", "Frost Blower", "Carrot Launcher"}

for i,v in pairs(game:GetService("ReplicatedStorage").Assets.Seeds:GetChildren()) do
    table.insert(Seeds, v.Name)
end

local BuySeedTabs = Tabs.Purchase:Section({ Title = "Auto Buy Seeds" })

local SelectSeeds = Tabs.Purchase:Dropdown({
    Title = "Select Seeds",
    Multi = true,
    AllowNone = true,
    Values = Seeds,
    Value = getgenv().Settings.Purchases.Seeds,
    Callback = function(Seed)
        getgenv().Settings.Purchases.Seeds = Seed
        SaveSetting()
    end
})

local BuySeeds = Tabs.Purchase:Toggle({
    Title = "Buy Seeds",
    Value = getgenv().Settings.Purchases.BuySeeds,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Purchases.BuySeeds = Value
        SaveSetting()

        task.spawn(function()
            pcall(function()
                if Value then
                    while getgenv().Settings.Purchases.BuySeeds do task.wait(1)
                        for i,v in pairs(game:GetService("ReplicatedStorage").Assets.Seeds:GetChildren()) do
                            if table.find(getgenv().Settings.Purchases.Seeds, v.Name) then
                                game:GetService("ReplicatedStorage").Remotes.BuyItem:FireServer(v.Name)
                                task.wait(.5)
                            end
                        end
                    end
                end
            end)
        end)
    end
})

local BuyGearTabs = Tabs.Purchase:Section({ Title = "Auto Buy Gears" })

local SelectGears = Tabs.Purchase:Dropdown({
    Title = "Select Gears",
    Multi = true,
    AllowNone = true,
    Values = Gears,
    Value = getgenv().Settings.Purchases.Gears,
    Callback = function(Gears)
        getgenv().Settings.Purchases.Gears = Gears
        SaveSetting()
    end
})

local BuyGears = Tabs.Purchase:Toggle({
    Title = "Buy Gears",
    Value = getgenv().Settings.Purchases.BuyGears,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Purchases.BuyGears = Value
        SaveSetting()

        task.spawn(function()
            pcall(function()
                if Value then
                    while getgenv().Settings.Purchases.BuyGears do task.wait(1)
                        for i,v in pairs(game:GetService("ReplicatedStorage").Assets.Gears:GetChildren()) do
                            if table.find(getgenv().Settings.Purchases.Gears, v.Name) then
                                game:GetService("ReplicatedStorage").Remotes.BuyGear:FireServer(v.Name)
                                task.wait(.5)
                            end
                        end
                    end
                end
            end)
        end)
    end
})

local gardenandbrainrot = Tabs.Purchase:Section({ Title = "Garden & Brainrots" })

local Garden = Tabs.Purchase:Toggle({
    Title = "Auto Buy Row Garden",
    Value = getgenv().Settings.Purchases.Garden,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Purchases.Garden = Value
        SaveSetting()

        task.spawn(function()
            pcall(function()
                if Value then
                    while getgenv().Settings.Purchases.Garden do task.wait(1)
                        for i = 1, 7 do
                            local v = workspace.Plots[getgenv().MyPlots].Rows:FindFirstChild(i)
                            if v and not v:GetAttribute("Enabled") then
                                game:GetService("ReplicatedStorage").Remotes.BuyRow:FireServer(tonumber(i))
                                break
                            end
                        end
                    end
                end
            end)
        end)
    end
})

local Brainrots = Tabs.Purchase:Toggle({
    Title = "Auto Buy Plant Brainrots",
    Value = getgenv().Settings.Purchases.Brainrots,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Purchases.Brainrots = Value
        SaveSetting()

        task.spawn(function()
            pcall(function()
                if Value then
                    while getgenv().Settings.Purchases.Brainrots do task.wait(1)
                        for i = 1, 17 do
                            local v = workspace.Plots[getgenv().MyPlots].Brainrots:FindFirstChild(i)
                            if v and not v:GetAttribute("Enabled") then
                                game:GetService("ReplicatedStorage").Remotes.BuyPlatform:FireServer(tostring(i))
                                break
                            end
                        end
                    end
                end
            end)
        end)
    end
})

-------------------------------- Event --------------------------------

local EventTabs = Tabs.Event:Section({ Title = "Event" })

local AutoTrunin = Tabs.Event:Toggle({
    Title = "Auto Return Brainrot",
    Value = getgenv().Settings.Event.Autoturnin,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Event.Autoturnin = Value
        SaveSetting()

        task.spawn(function()
            pcall(function()
                if Value then
                    while getgenv().Settings.Event.Autoturnin do task.wait(1)
                        for i,v in pairs(workspace.Plots[getgenv().MyPlots].EventPlatforms:GetChildren()) do
                            for i2,v2 in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
                                if v:GetAttribute("Blackout") then
                                    if v:GetAttribute("VisualBrainrot") == v2:GetAttribute("Brainrot") then
                                        game.Players.LocalPlayer.Character.Humanoid:EquipTool(v2)
                                        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = v:FindFirstChild("Hitbox").CFrame
                                        task.wait(.5)
                                        fireproximityprompt(v:FindFirstChild("Hitbox"):FindFirstChild("ProximityPrompt"))
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end)
    end
})

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

function updateLanguage()
    -- อัพเดตชื่อ Tab
    if Tabs.Automatic then
        Tabs.Automatic:SetTabTitle(L("Automatic"))
    end
    if Tabs.AutoPlant then
        Tabs.AutoPlant:SetTabTitle(L("AutoPlant"))
    end
    if Tabs.AutoCollect then
        Tabs.AutoCollect:SetTabTitle(L("AutoCollect"))
    end
    if Tabs.AutoSell then
        Tabs.AutoSell:SetTabTitle(L("AutoSell"))
    end
    if Tabs.Purchase then
        Tabs.Purchase:SetTabTitle(L("Purchase"))
    end
    if Tabs.Event then
        Tabs.Event:SetTabTitle(L("Event"))
    end
    if Tabs.Configuration then
        Tabs.Configuration:SetTabTitle(L("Configuration"))
    end

    --อัพเดตส่วน Auto Farm
    if AutoFarmTabs then
        AutoFarmTabs:SetTitle(L("AutoFarmTabs"))
    end

    if AutoFarm then
        AutoFarm:SetTitle(L("AutoFarm"))
    end

    --อัพเดตส่วน Auto Plant
    if AutoPlantTabs then
        AutoPlantTabs:SetTitle(L("AutoPlantTabs"))
    end

    if SelectSeed then
        SelectSeed:SetTitle(L("SelectSeed"))
    end

    if AutoPlant then
        AutoPlant:SetTitle(L("AutoPlant"))
    end

    if AutoPlantTab2 then
        AutoPlantTab2:SetTitle(L("AutoPlantTab2"))
    end

    if SelectSeed2 then
        SelectSeed2:SetTitle(L("SelectSeed2"))
    end

    if AutoPlant2 then
        AutoPlant2:SetTitle(L("AutoPlant2"))
    end

    --อัพเดตส่วน Auto Collect
    if AutoCollectTabs1 then
        AutoCollectTabs1:SetTitle(L("AutoCollectTabs1"))
    end

    if AutoEquipBest then
        AutoEquipBest:SetTitle(L("AutoEquipBest"))
    end

    if DelayEquipBest then
        DelayEquipBest:SetTitle(L("DelayEquipBest"))
    end

    if AutoCollectTabs2 then
        AutoCollectTabs2:SetTitle(L("AutoCollectTabs2"))
    end

    if CollectAllPlant then
        CollectAllPlant:SetTitle(L("CollectAllPlant"))
    end

    --อัพเดตส่วน Auto Sell
    if AutoSellTab then
        AutoSellTab:SetTitle(L("AutoSellTab"))
    end

    if AutoSellBrainrots then
        AutoSellBrainrots:SetTitle(L("AutoSellBrainrots"))
    end

    if Delay then
        Delay:SetTitle(L("Delay"))
    end

    --อัพเดตส่วน Purchases
    if BuySeedTabs then
        BuySeedTabs:SetTitle(L("BuySeedTabs"))
    end

    if SelectSeeds then
        SelectSeeds:SetTitle(L("SelectSeeds"))
    end

    if BuySeeds then
        BuySeeds:SetTitle(L("BuySeeds"))
    end

    if BuyGearTabs then
        BuyGearTabs:SetTitle(L("BuyGearTabs"))
    end

    if SelectGears then
        SelectGears:SetTitle(L("SelectGears"))
    end

    if BuyGears then
        BuyGears:SetTitle(L("BuyGears"))
    end

    if gardenandbrainrot then
        gardenandbrainrot:SetTitle(L("gardenandbrainrot"))
    end

    if Garden then
        Garden:SetTitle(L("Garden"))
    end

    if Brainrots then
        Brainrots:SetTitle(L("Brainrots"))
    end

    --อัพเดตส่วน Event
    if EventTabs then
        EventTabs:SetTitle(L("EventTabs"))
    end

    if AutoTrunin then
        AutoTrunin:SetTitle(L("AutoTrunin"))
    end

    --อัพเดตส่วน Configuration

    if IS then
        IS:SetTitle(L("Interface"))
    end

    if themeDropdown then
        themeDropdown:SetTitle(L("themeDropdown"))
    end

    if ToggleTransparency then
        ToggleTransparency:SetTitle(L("ToggleTransparency"))
    end

    if AntiAFK then
        AntiAFK:SetTitle(L("AntiAFK"))
    end

    if AutoExecutor then
        AutoExecutor:SetTitle(L("AutoExecutor"))
    end

    if MinimizeBind then
        MinimizeBind:SetTitle(L("MinimizeBind"))
    end

    if LanguageTab then
        LanguageTab:SetTitle(L("LanguageTab"))
    end

    if Language then
        Language:SetTitle(L("Language"))
    end

    if ChangedLanguage then
        ChangedLanguage:SetTitle(L("ChangedLanguage"))
    end
end
LanguageTab =  Tabs.Configuration:Section({ Title = "↪ Language" })

Language = Tabs.Configuration:Dropdown({
    Title = "Language",
    Multi = false,
    AllowNone = false,
    Values = {"English (US)","Thai","Vietnamese"},
    Value = getgenv().ConfigurationTable.Language,
    Callback = function(Callback)
        LanguageSelect = Callback
        getgenv().ConfigurationTable.Language = Callback
        SaveConfiguration()
    end
})

ChangedLanguage = Tabs.Configuration:Button({
    Title = "Change Language",
    Icon = "check",
    Callback = function()
        getgenv().ConfigurationTable.Language = LanguageSelect
        updateLanguage()
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

updateLanguage()