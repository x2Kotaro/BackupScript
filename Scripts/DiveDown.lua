pcall(function()
    
end)

getgenv().ConfigurationTable = {}
getgenv().Settings = {}
 
local FolderConfiguration = "Venuz Hub"
local FolderSettings = "Venuz Hub/Dive_Down"
local FolderSlots = "Venuz Hub/Slots"
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local chr = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local hrp = chr:WaitForChild("HumanoidRootPart")
local humanoid = chr:WaitForChild("Humanoid")
local HttpService = game:GetService("HttpService")
local VenuzIcon = "rbxassetid://92691624917972"
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local UserId = LocalPlayer.UserId
local currentTime = os.date("%H:%M:%S")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CollectionService = game:GetService("CollectionService")

local filenameConfiguration = FolderConfiguration .. "/" .. "Setting_".. LocalPlayer.Name .. ".json"
local filenameSetting = FolderSettings .. "/" .. "GameConfig_".. LocalPlayer.Name..".json"

---- ============ Configuration ============ ---- 

local DefaultConfiguration = {
    ["Themes"] = "Crimson",
    ["Transparent"] = true,
    ["AntiAFK"] = true,
    ["AutoRejoin"] = false,
    ["AutoExecutor"] = true,
    ["MinimizeBind"] = "End",
    ["Language"] = "English (US)",
    ["FPSValue"] = 144,
    ["LockFPS"] = false,
    ["WhileScreen"] = false,
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

---- ============ SaveSettings ============ ----

local DefaultSettings = {
    ["Main"] = {
        ["SelectFish"] = {},
        ["SelectFishF"] = {},
        ["SelectTreats"] = {},
        ["AutoFarmFish"] = false,
        ["AutoFavorite"] = false,
        ["AutoBuyTreats"] = false,
        ["ResetOxygen"] = 30,
        ["AutoBestFish"] = false,
        ["MinValue"] = 1,
        ["MaxValue"] = 100,
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

if getgenv().Configuration and next(getgenv().Configuration) then
    for key, value in pairs(getgenv().Configuration) do
        if getgenv().Settings[key] ~= nil then
            getgenv().Settings[key] = value
        end
    end
    SaveSetting()
end

---- ============ CheckRole ============ ----

local KeyFile = "Venuz Hub/KeySystem".."/".."VenuzKey"..".txt"
local api = loadstring(game:HttpGet("https://sdkapi-public.luarmor.net/library.lua"))()
api.script_id = "274209c355e95ffe3ba729826b475b88"

local status = api.check_key(readfile(KeyFile))

if status.code == "KEY_VALID" then
    if status.data.note == "Premium" then
        getgenv().Premium = false
        getgenv().IsPremium = "Premium Access"
    else
        getgenv().Premium = true
        getgenv().IsPremium = "Standard"
    end
end

---- ============ Interface ============ ----

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/x2Kotaro/API/main/test.lua"))()

local Device
if UserInputService.TouchEnabled then
    Device = UDim2.fromOffset(450, 300)
else
    Device = UDim2.fromOffset(650, 520)
end

WindUI:Localization({
    Enabled = true,
    Prefix = "tr:",
    DefaultLanguage = getgenv().ConfigurationTable.Language,
    Translations = {
        ["Thai"] = {
            -- Tabs
            ["Automaic"] = "หน้าหลัก",
            ["AutoFarm"] = "ฟาร์มปลา",
            ["AutoFarmTab"] = "ฟาร์มปลาอัตโนมัติ",
            ["FavoriteTab"] = "ตั้งค่าปลาโปรด",
            ["Shop"] = "ร้านค้า",
            ["TreatsTab"] = "ซื้อเหยื่อ",
            ["SelectFish"] = "เลือกปลาที่จะจับ",
            ["SelectTreats"] = "เลือกเหยื่อที่จะซื้อ",
            ["AutoFarmFish"] = "เปิดฟาร์มปลาอัตโนมัติ",
            ["AutoFavorite"] = "ล็อกปลาโปรดในกระเป๋าอัตโนมัติ",
            ["AutoBuyTreats"] = "ซื้อ Treats อัตโนมัติ",
            ["AutoEquipBestFish"] = "ยัดปลาที่ดีที่สุดลงตู้ Aquarium อัตโนมัติ",
            ["ResetOxygen"] = "เติมออกซิเจนอัตโนมัติ",
            ["Min"] = "ค่าน้ำหนักต่ำสุด",
            ["Max"] = "ค่าน้ำหนักสูงสุด",
            ["DescSelectFish"] = "เลือกชนิดปลาที่อยากจับ",
            ["DescSelectTreats"] = "เลือก Treat ที่ให้ระบบซื้ออัตโนมัติ",
            ["DescAutoFarmFish"] = "เปิดแล้วตัวละครจะไปจับปลาให้เอง และให้ความสำคัญปลา Secret ก่อน",
            ["DescAutoFavorite"] = "ล็อกปลาที่เลือกไว้ใน Backpack ตามช่วงน้ำหนักที่ตั้ง เพื่อกันเผลอขาย (สัญลักษณ์ล็อกจะขึ้นหลังรีตัวตาย 1 ครั้ง หรือออกเกมเข้าใหม่)",
            ["DescAutoBuyTreats"] = "ระบบจะซื้อ Treat ที่เลือกวนซ้ำอัตโนมัติ",
            ["DescAutoEquipBestFish"] = "ระบบจะเลือกปลาที่ดีที่สุดแล้วยัดลงตู้ Aquarium ให้อัตโนมัติ",
            ["DescResetOxygen"] = "ถ้าออกซิเจนน้อยกว่าค่านี้ จะวาร์ปขึ้นไปเติมก่อนแล้วค่อยลงมาฟาร์มต่อ",
            ["DescMin"] = "ตั้งค่าน้ำหนักปลาต่ำสุดที่ระบบจะเลือก",
            ["DescMax"] = "ตั้งค่าน้ำหนักปลาสูงสุดที่ระบบจะเลือก",
            -- Settings
            ["Interface"] = "ตั้งค่า",
            ["themeDropdown"] = "เลือกธีม",
            ["ToggleTransparency"] = "ทำหน้าต่างโปร่งใส",
            ["AntiAFK"] = "กันหลุด AFK",
            ["AutoRejoin"] = "เข้าเกมใหม่อัตโนมัติ",
            ["AutoExecutor"] = "รันสคริปต์ตอนย้ายเซิร์ฟ",
            ["MinimizeBind"] = "ปุ่มย่อ/เปิดเมนู",
            ["FPSIS"] = "FPS",
            ["FPSVALUE"] = "FPS",
            ["FPSLOCK"] = "ล็อก FPS",
            ["WhiteScreen"] = "จอขาว",
            ["LanguageTab"] = "ภาษา",
            ["Language"] = "เลือกภาษา",
            ["ChangedLanguage"] = "เปลี่ยนภาษา",
            ["Configuration"] = "ตั้งค่า",
            ["ScriptLoader"] = "สคริปต์ | โหลดเดอร์",
            ["ScriptLoaded"] = "โหลดสคริปต์สำเร็จ"
        },
        ["English (US)"] = {
            -- Tabs
            ["Automaic"] = "Main",
            ["AutoFarm"] = "Fish Farm",
            ["AutoFarmTab"] = "Auto Fish Farm",
            ["FavoriteTab"] = "Favorite Fish",
            ["Shop"] = "Shop",
            ["TreatsTab"] = "Buy Treats",
            ["SelectFish"] = "Select Fish",
            ["SelectTreats"] = "Select Treats",
            ["AutoFarmFish"] = "Auto Farm Fish",
            ["AutoFavorite"] = "Auto Favorite Lock (Backpack)",
            ["AutoBuyTreats"] = "Auto Buy Treats",
            ["AutoEquipBestFish"] = "Auto Put Best Fish In Aquarium",
            ["ResetOxygen"] = "Auto Oxygen Refill",
            ["Min"] = "Min Weight",
            ["Max"] = "Max Weight",
            ["DescSelectFish"] = "Choose fish types to target.",
            ["DescSelectTreats"] = "Choose treats for auto purchase.",
            ["DescAutoFarmFish"] = "Auto farms fish and prioritizes Secret fish first.",
            ["DescAutoFavorite"] = "Automatically marks selected fish in your Backpack as favorite by the configured weight range to prevent accidental selling (lock icon appears after one respawn or rejoin).",
            ["DescAutoBuyTreats"] = "Automatically buys selected treats in a loop.",
            ["DescAutoEquipBestFish"] = "Automatically selects and puts the best fish into the Aquarium.",
            ["DescResetOxygen"] = "If oxygen drops below this value, teleport to refill first, then continue farming.",
            ["DescMin"] = "Set the minimum fish weight the system should select.",
            ["DescMax"] = "Set the maximum fish weight the system should select.",

            -- Settings
            ["Interface"] = "Interface Settings",
            ["themeDropdown"] = "Select Theme",
            ["ToggleTransparency"] = "Toggle Window Transparency",
            ["AntiAFK"] = "Anti-AFK",
            ["AutoRejoin"] = "Auto Rejoin",
            ["AutoExecutor"] = "Auto Executor",
            ["MinimizeBind"] = "Minimize Bind",
            ["FPSIS"] = "FPS",
            ["FPSVALUE"] = "FPS",
            ["FPSLOCK"] = "FPS Lock",
            ["WhiteScreen"] = "White Screen",
            ["LanguageTab"] = "Language",
            ["Language"] = "Select Language",
            ["ChangedLanguage"] = "Change Language",
            ["Configuration"] = "Configuration",
            ["ScriptLoader"] = "Script | Loader",
            ["ScriptLoaded"] = "Script Loaded Successfully"
        }
    }
})

local CurrentLanguage = getgenv().ConfigurationTable.Language

if CurrentLanguage == "English (US)" then
    WindUI:SetLanguage("English (US)")
else
    WindUI:SetLanguage("Thai")
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
    ScrollBarEnabled = true,
    Resizable = false,
})

Window:Tag({
    Title = getgenv().IsPremium,
    Color = Color3.fromHex("#30ff6a"),
    Radius = 13,
})

Window:Tag({
    Title = "Update Latest 2/20/2026",
    Color = Color3.fromHex("#f4fc02"),
    Radius = 13,
})

Window:EditOpenButton({
    Title = "Venuz Hub",
    Icon = VenuzIcon,
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromHex("FF0F7B"), 
        Color3.fromHex("F89B29")
    ),
    OnlyMobile = true,
    Enabled = true,
    Draggable = true,
})

---- ============ Funtion ============ ----

local NoClipConnection = nil
local ActiveTween = nil

function StartNoClip()
    if NoClipConnection then return end
    
    NoClipConnection = RunService.Stepped:Connect(function()
        local character = game.Players.LocalPlayer.Character
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Velocity = Vector3.new(0, 0, 0)
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                hrp.RotVelocity = Vector3.new(0, 0, 0)
            end
        end
    end)
end

function StopNoClip()
    if NoClipConnection then
        NoClipConnection:Disconnect()
        NoClipConnection = nil
    end
end

function TweenFarm(P, speed)
    if ActiveTween then
        ActiveTween:Cancel()
        ActiveTween = nil
    end

    local humanoidRootPart = game.Players.LocalPlayer.Character.HumanoidRootPart
    local tweenService = game:GetService("TweenService")

    local _, originalY, _ = humanoidRootPart.CFrame:ToOrientation()

    local function createUpright(position)
        return CFrame.new(position) * CFrame.Angles(0, originalY, 0)
    end

    local dist = (
        Vector3.new(humanoidRootPart.Position.X, 0, humanoidRootPart.Position.Z) - 
        Vector3.new(P.Position.X, 0, P.Position.Z)
    ).Magnitude

    local tween = tweenService:Create(
        humanoidRootPart,
        TweenInfo.new(dist / speed, Enum.EasingStyle.Linear),
        {CFrame = createUpright(P.Position)}
    )

    ActiveTween = tween
    tween:Play()

    tween.Completed:Connect(function()
        if tween.PlaybackState == Enum.PlaybackState.Completed then
            ActiveTween = nil
        end
    end)

    return tween
end

---- ============ Main ============ ----

local FishTable = {}

for i,v in pairs(game:GetService("ReplicatedStorage").Assets.FishModels:GetChildren()) do
    if v:IsA("Model") then
        table.insert(FishTable, v.Name)
    end
end

local Tab = Window:Tab({
    Title = "tr:Automaic",
    Icon = "code-xml",
    Opened = true,
})

local AutoFarmTab = Tab:Section({ Title = "tr:AutoFarmTab", Icon = "fish", Opened = true})

local Zone = {
    ["CoralReef"] = CFrame.new(-1934, 2408, -1416),
    ["SunlightZone"] = CFrame.new(-1929, 2489, -1414),
    ["TwilightZone"] = CFrame.new(-1935, 2230, -1419),
    ["DeepOcean"] = CFrame.new(-1935, 1837, -1419),
    ["TheDeepDark"] = CFrame.new(-1933, 1108, -1420),
    ["TheTrenches"] = CFrame.new(-1929, 336, -1420),
    ["Atlantis"] = CFrame.new(-1889, 5, -1419),
}

local SelectFish = AutoFarmTab:Dropdown({
    Title = "tr:SelectFish",
    Desc = "tr:DescSelectFish",
    Multi = true,
    AllowNone = false,
    Value = getgenv().Settings.Main.SelectFish,
    Values = FishTable,
    Callback = function(e)
        getgenv().Settings.Main.SelectFish = e
        SaveSetting()
    end,
})

local AutoFarm = AutoFarmTab:Toggle({
    Title = "tr:AutoFarmFish",
    Desc = "tr:DescAutoFarmFish",
    Value = getgenv().Settings.Main.AutoFarmFish,
    Icon = "check",
    Callback = function(value)
        getgenv().Settings.Main.AutoFarmFish = value
        SaveSetting()

        if not value then
            getgenv().AutoFarmFishRunning = false
            return
        end

        if getgenv().AutoFarmFishRunning then
            return
        end

        getgenv().AutoFarmFishRunning = true
        task.spawn(function()
            while getgenv().Settings.Main.AutoFarmFish do
                local plr = game.Players.LocalPlayer
                local char = plr.Character
                if not char then
                    task.wait(0.2)
                    continue
                end

                local hrp = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if not hrp or not hum or hum.Health <= 0 then
                    task.wait(0.2)
                    continue
                end

                local oxygenText = nil
                pcall(function()
                    oxygenText = game:GetService("Players").LocalPlayer.PlayerGui.PersistentUI.OxygenBar.OxygenBar.Amount.Text
                end)

                if type(oxygenText) == "string" then
                    local oxygenPercent = tonumber(string.match(oxygenText, "(%d+)"))
                    local oxygenThreshold = tonumber(getgenv().Settings.Main.ResetOxygen) or 30
                    if oxygenPercent and oxygenPercent < oxygenThreshold then
                        hrp.CFrame = CFrame.new(-1930, 2532, -1428)
                        repeat
                            task.wait(0.25)
                            pcall(function()
                                oxygenText = game:GetService("Players").LocalPlayer.PlayerGui.PersistentUI.OxygenBar.OxygenBar.Amount.Text
                            end)
                            oxygenPercent = type(oxygenText) == "string" and tonumber(string.match(oxygenText, "(%d+)")) or oxygenPercent
                        until not getgenv().Settings.Main.AutoFarmFish or not hum.Parent or hum.Health <= 0 or (oxygenPercent and oxygenPercent >= 98)
                    end
                end

                local fishesFolder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Fishes")
                local selectedFish = getgenv().Settings.Main.SelectFish or {}
                local targetModel = nil

                if fishesFolder then
                    for _, model in ipairs(fishesFolder:GetChildren()) do
                        if model:IsA("Model") and model:GetAttribute("StartPos") ~= nil and not model:GetAttribute("Owner") then
                            local isSecret = false
                            for _, desc in ipairs(model:GetDescendants()) do
                                if desc:IsA("BillboardGui") then
                                    local frame = desc:FindFirstChild("Frame")
                                    local rarityContainer = frame and frame:FindFirstChild("Rarity")
                                    local rarityLabel = rarityContainer and rarityContainer:FindFirstChild("Rarity")
                                    local rarityText = rarityLabel and rarityLabel:IsA("TextLabel") and string.lower(tostring(rarityLabel.Text)) or ""
                                    if rarityText == "secret" or rarityText == "secut" then
                                        isSecret = true
                                        break
                                    end
                                end
                            end

                            if isSecret then
                                targetModel = model
                                break
                            end
                        end
                    end

                    if not targetModel then
                    for _, model in ipairs(fishesFolder:GetChildren()) do
                        if model:IsA("Model") and model:GetAttribute("Owner") == nil then
                            local fishName = model:GetAttribute("Name")
                            local startPos = model:GetAttribute("StartPos")
                            if fishName and startPos ~= nil then
                                local isMatch = false
                                if selectedFish[fishName] == true then
                                    isMatch = true
                                else
                                    for _, selectedName in ipairs(selectedFish) do
                                        if selectedName == fishName then
                                            isMatch = true
                                            break
                                        end
                                    end
                                end

                                if isMatch then
                                    targetModel = model
                                    break
                                end
                            end
                        end
                    end
                    end
                end

                if targetModel then
                    local modelRoot = targetModel:FindFirstChild("RootPart") or targetModel:FindFirstChildWhichIsA("BasePart")
                    if modelRoot then
                        hrp.CFrame = modelRoot.CFrame * CFrame.new(0, 2.5, 0)
                        task.wait(0.1)
                    end

                    local prompt = nil
                    if targetModel:FindFirstChild("RootPart") then
                        prompt = targetModel.RootPart:FindFirstChildOfClass("ProximityPrompt")
                    end
                    if not prompt and modelRoot then
                        prompt = modelRoot:FindFirstChildOfClass("ProximityPrompt")
                    end

                    if prompt then
                        pcall(function()
                            fireproximityprompt(prompt)
                        end)
                    end
                else
                    for _, zoneCFrame in pairs(Zone) do
                        if not getgenv().Settings.Main.AutoFarmFish then
                            break
                        end

                        hrp.CFrame = zoneCFrame
                        task.wait(0.85)

                        local refreshFolder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Fishes")
                        if refreshFolder then
                            local foundInZone = false
                            for _, model in ipairs(refreshFolder:GetChildren()) do
                                if model:IsA("Model") and model:GetAttribute("StartPos") ~= nil and model:GetAttribute("Owner") == nil then
                                    local isSecret = false
                                    for _, desc in ipairs(model:GetDescendants()) do
                                        if desc:IsA("BillboardGui") then
                                            local frame = desc:FindFirstChild("Frame")
                                            local rarityContainer = frame and frame:FindFirstChild("Rarity")
                                            local rarityLabel = rarityContainer and rarityContainer:FindFirstChild("Rarity")
                                            local rarityText = rarityLabel and rarityLabel:IsA("TextLabel") and string.lower(tostring(rarityLabel.Text)) or ""
                                            if rarityText == "secret" or rarityText == "secut" then
                                                isSecret = true
                                                break
                                            end
                                        end
                                    end

                                    if isSecret then
                                        foundInZone = true
                                        break
                                    end
                                end
                            end

                            if not foundInZone then
                            for _, model in ipairs(refreshFolder:GetChildren()) do
                                if model:IsA("Model") and model:GetAttribute("Owner") == nil then
                                    local fishName = model:GetAttribute("Name")
                                    local startPos = model:GetAttribute("StartPos")
                                    if fishName and startPos ~= nil then
                                        local isMatch = false
                                        if selectedFish[fishName] == true then
                                            isMatch = true
                                        else
                                            for _, selectedName in ipairs(selectedFish) do
                                                if selectedName == fishName then
                                                    isMatch = true
                                                    break
                                                end
                                            end
                                        end

                                        if isMatch then
                                            foundInZone = true
                                            break
                                        end
                                    end
                                end
                            end
                            end

                            if foundInZone then
                                break
                            end
                        end
                    end
                end

                task.wait()
            end

            getgenv().AutoFarmFishRunning = false
        end)
    end,
})

local ResetOxygen = Tab:Slider({
    Title = "tr:ResetOxygen",
    Desc = "tr:DescResetOxygen",
    Value = {
        Min = 1,
        Max = 100,
        Default = getgenv().Settings.Main.ResetOxygen,
    },
    Callback = function(Value)
        getgenv().Settings.Main.ResetOxygen = Value
        SaveSetting()
    end
})

local AutoEquipBestFishTab = Tab:Section({ Title = "tr:AutoEquipBestFish", Icon = "fish", Opened = true})

local AutoEquipBestFish = AutoEquipBestFishTab:Toggle({
    Title = "tr:AutoEquipBestFish",
    Desc = "tr:DescAutoEquipBestFish",
    Value = getgenv().Settings.Main.AutoBestFish,
    Icon = "check",
    Callback = function(value)
        getgenv().Settings.Main.AutoBestFish = value
        SaveSetting()

        if value then
            task.spawn(function()
                while getgenv().Settings.Main.AutoBestFish do
                    workspace:WaitForChild("Network"):WaitForChild("RequestEquipBestFish-RemoteFunction"):InvokeServer()
                    task.wait(3)
                end
            end)
        end
    end,
})

local FavoriteTab = Tab:Section({ Title = "tr:FavoriteTab", Icon = "fish", Opened = true})

local SelectFish = FavoriteTab:Dropdown({
    Title = "tr:SelectFish",
    Desc = "tr:DescSelectFish",
    Multi = true,
    AllowNone = false,
    Value = getgenv().Settings.Main.SelectFishF,
    Values = FishTable,
    Callback = function(e)
        getgenv().Settings.Main.SelectFishF = e
        SaveSetting()
    end,
})

local MinValue = Tab:Input({
    Title = "tr:Min",
    Desc = "tr:DescMin",
    Value = tostring(getgenv().Settings.Main.MinValue),
    Placeholder = "1",
    Callback = function(Value)
        local numberValue = tonumber(Value)
        if numberValue then
            getgenv().Settings.Main.MinValue = math.clamp(numberValue, 1, 1000000)
            SaveSetting()
        end
    end
})

local MaxValue = Tab:Input({
    Title = "tr:Max",
    Desc = "tr:DescMax",
    Value = tostring(getgenv().Settings.Main.MaxValue),
    Placeholder = "100",
    Callback = function(Value)
        local numberValue = tonumber(Value)
        if numberValue then
            getgenv().Settings.Main.MaxValue = math.clamp(numberValue, 1, 1000000)
            SaveSetting()
        end
    end
})

local AutoFarm = Tab:Toggle({
    Title = "tr:AutoFavorite",
    Desc = "tr:DescAutoFavorite",
    Value = getgenv().Settings.Main.AutoFavorite,
    Icon = "check",
    Callback = function(value)
        getgenv().Settings.Main.AutoFavorite = value
        SaveSetting()

        if value then
            task.spawn(function()
                while getgenv().Settings.Main.AutoFavorite do task.wait(1)
                    for i,v in pairs(game:GetService("Players").LocalPlayer.Backpack:GetChildren()) do
                        local fishName = v:GetAttribute("Name")
                        local selectedFish = getgenv().Settings.Main.SelectFishF or {}
                        local isSelected = false
                        if fishName then
                            if selectedFish[fishName] == true then
                                isSelected = true
                            else
                                isSelected = table.find(selectedFish, fishName) ~= nil
                            end
                        end

                        if isSelected then
                            local fishWeight = tonumber(v:GetAttribute("Weight"))
                            local minWeight = tonumber(getgenv().Settings.Main.MinValue) or 1
                            local maxWeight = tonumber(getgenv().Settings.Main.MaxValue) or 1000000
                            if fishWeight and fishWeight >= minWeight and fishWeight <= maxWeight then
                                game:GetService("ReplicatedStorage"):WaitForChild("Packets"):WaitForChild("Packet"):WaitForChild("RemoteEvent"):FireServer(unpack({buffer.fromstring("\014\r\014\001"),{game:GetService("Players").LocalPlayer:WaitForChild("Backpack"):WaitForChild(v.Name)}}))
                                workspace:WaitForChild("Network"):WaitForChild("GetInventorySnapshot-RemoteFunction"):InvokeServer(unpack({true,true}))
                                workspace:WaitForChild("Network"):WaitForChild("GetAquariumSnapshot-RemoteFunction"):InvokeServer(unpack({game:GetService("Players"):WaitForChild(game.Players.LocalPlayer.Name)}))
                                workspace:WaitForChild("Network"):WaitForChild("GetRebirthInfo-RemoteFunction"):InvokeServer()
                            end
                        end
                    end
                end
            end)
        end
    end,
})

local Tab = Window:Tab({
    Title = "tr:Shop",
    Icon = "code-xml",
    Opened = true,
})

local TreatsTab = Tab:Section({ Title = "tr:TreatsTab", Icon = "fish", Opened = true})

local SelectTreats = TreatsTab:Dropdown({
    Title = "tr:SelectTreats",
    Desc = "tr:DescSelectTreats",
    Multi = true,
    AllowNone = false,
    Value = getgenv().Settings.Main.SelectTreats,
    Values = {"Worm", "Cockroach", "Snail", "Spider", "Ladybug"},
    Callback = function(e)
        getgenv().Settings.Main.SelectTreats = e
        SaveSetting()
    end,
})

local AutoBuyTreats = TreatsTab:Toggle({
    Title = "tr:AutoBuyTreats",
    Desc = "tr:DescAutoBuyTreats",
    Value = getgenv().Settings.Main.AutoBuyTreats,
    Icon = "check",
    Callback = function(value)
        getgenv().Settings.Main.AutoBuyTreats = value
        SaveSetting()

        if not value then
            getgenv().AutoBuyTreatsRunning = false
            return
        end

        if getgenv().AutoBuyTreatsRunning then
            return
        end

        getgenv().AutoBuyTreatsRunning = true
        task.spawn(function()
            local remote = game:GetService("ReplicatedStorage"):WaitForChild("Packets"):WaitForChild("Packet"):WaitForChild("RemoteEvent")
            local treatPackets = {
                ["Worm"] = "\004\005Treat\004Worm",
                ["Cockroach"] = "\004\005Treat\tCockroach",
                ["Snail"] = "\004\005Treat\005Snail",
                ["Spider"] = "\004\005Treat\006Spider",
                ["Ladybug"] = "\004\005Treat\aLadybug",
            }

            while getgenv().Settings.Main.AutoBuyTreats do
                local selectedTreats = getgenv().Settings.Main.SelectTreats or {}
                for treatName, packetString in pairs(treatPackets) do
                    if not getgenv().Settings.Main.AutoBuyTreats then
                        break
                    end

                    local isSelected = false
                    if selectedTreats[treatName] == true then
                        isSelected = true
                    else
                        isSelected = table.find(selectedTreats, treatName) ~= nil
                    end

                    if isSelected then
                        remote:FireServer(unpack({buffer.fromstring(packetString)}))
                        task.wait(0.15)
                    end
                end
                task.wait(0.6)
            end

            getgenv().AutoBuyTreatsRunning = false
        end)
    end,
})
---- ============ Configuration ============ ----

Window:Divider()

local Tab = Window:Tab({
    Title = "tr:Configuration",
    Icon = "settings",
    Locked = false,
})

local Interface = Tab:Section({ Title = "tr:Interface", Icon = "settings-2"})

local themeValues = {}
for name, _ in pairs(WindUI:GetThemes()) do
    table.insert(themeValues, name)
end

local themeDropdown = Tab:Dropdown({
    Title = "tr:themeDropdown",
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

local ToggleTransparency = Tab:Toggle({
    Title = "tr:ToggleTransparency",
    Value = getgenv().ConfigurationTable.Transparent,
    Icon = "check",
    Callback = function(e)
        getgenv().ConfigurationTable.Transparent = e
        SaveConfiguration()
        Window:ToggleTransparency(e)
    end,
    Value = WindUI:GetTransparency()
})

local AntiAFK = Tab:Toggle({
    Title = "tr:AntiAFK",
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

local AutoRejoin = Tab:Toggle({
    Title = "tr:AutoRejoin",
    Value = getgenv().ConfigurationTable.AutoRejoin,
    Icon = "check",
    Callback = function(enabled)
        getgenv().ConfigurationTable.AutoRejoin = enabled
        SaveConfiguration()

        if enabled then
            if not enabled then
                if getgenv().Settings.Automatic.AutoFarm.AutoFarmRock then
                    getgenv().Settings.Automatic.AutoFarm.AutoFarmRock:Disconnect()
                    getgenv().Settings.Automatic.AutoFarm.AutoFarmRock = nil
                end
                return
            end

            if getgenv().Settings.Automatic.AutoFarm.AutoFarmRock then
                return
            end

            getgenv().Settings.Automatic.AutoFarm.AutoFarmRock = game.CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
                if child.Name == "ErrorPrompt" then
                    game:GetService("TeleportService"):Teleport(game.PlaceId, game:GetService("Players").LocalPlayer)
                end
            end)
        end
    end
})

local AutoExecutor = Tab:Toggle({
    Title = "tr:AutoExecutor",
    Value = getgenv().ConfigurationTable.AutoExecutor,
    Icon = "check",
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoExecutor = Value
        SaveConfiguration()
    end
})

local MinimizeBind = Tab:Keybind({
    Title = "tr:MinimizeBind",
    Value = getgenv().ConfigurationTable.MinimizeBind,
    Callback = function(v)
        getgenv().ConfigurationTable.MinimizeBind = v
        SaveConfiguration()
        Window:SetToggleKey(Enum.KeyCode[v])
    end
})

local FPSIS = Tab:Section({ Title = "tr:FPSIS", Icon = "gamepad"})

local FPSVALUE = Tab:Slider({
    Title = "tr:FPSVALUE",
    Value = {
        Min = 1,
        Max = 240,
        Default = getgenv().ConfigurationTable.FPSValue
    },
    Callback = function(Value)
        getgenv().ConfigurationTable.FPSValue = Value
        SaveConfiguration()
    end
})

local FPSLOCK = Tab:Toggle({
    Title = "tr:FPSLOCK",
    Default = getgenv().ConfigurationTable.LockFPS,
    Icon = "check",
    Callback = function(v)
        getgenv().ConfigurationTable.LockFPS = v
        SaveConfiguration()

        if v then
            task.spawn(function()
                pcall(function()
                    while getgenv().ConfigurationTable.LockFPS do task.wait()
                        if getgenv().ConfigurationTable.LockFPS then
                            setfpscap(tonumber(getgenv().ConfigurationTable.FPSValue))
                        else
                            setfpscap(240)
                        end
                    end
                end)
            end)
        end
    end
})

local WhiteScreen = Tab:Toggle({
    Title = "tr:WhiteScreen",
    Default = getgenv().ConfigurationTable.WhileScreen,
    Icon = "check",
    Callback = function(v)
        getgenv().ConfigurationTable.WhileScreen = v
        SaveConfiguration()

        local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        local screenGui = playerGui:FindFirstChild("Venuz_White")

        if v then
            if not screenGui then
                screenGui = Instance.new("ScreenGui")
                screenGui.Name = "Venuz_White"
                screenGui.Enabled = true
                screenGui.IgnoreGuiInset = true
                screenGui.Parent = playerGui

                local frame = Instance.new("Frame")
                frame.Name = "Venuz_1"
                frame.Position = UDim2.new(0,0,0,0)
                frame.Size = UDim2.new(1,0,1,0)
                frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                frame.Parent = screenGui
            else
                screenGui.Enabled = true
            end
        else
            if screenGui then
                screenGui.Enabled = false
            end
        end
    end
})

local LanguageTab =  Tab:Section({ Title = "tr:LanguageTab", Icon = "languages"})

local Language = Tab:Dropdown({
    Title = "tr:Language",
    Multi = false,
    AllowNone = false,
    Values = {"English (US)","Thai"},
    Value = getgenv().ConfigurationTable.Language,
    Callback = function(Callback)
        getgenv().ConfigurationTable.Language = Callback
        SaveConfiguration()
    end
})

local ChangedLanguage = Tab:Button({
    Title = "tr:ChangedLanguage",
    Callback = function()
        if getgenv().ConfigurationTable.Language == "English (US)" then
            WindUI:SetLanguage("English (US)")
        else
            WindUI:SetLanguage("Thai")
        end
        Window:SelectTab(1)
    end
})

local queueteleport = queue_on_teleport
local TeleportCheck = false

while not Players.LocalPlayer do task.wait() end

LocalPlayer.OnTeleport:Connect(function(State)
    pcall(function()
        if getgenv().ConfigurationTable and getgenv().ConfigurationTable.AutoExecutor and (not TeleportCheck) and queueteleport then
            TeleportCheck = true
            queueteleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/x2Kotaro/Venuz-hub/main/Loader.lua"))()')
        end
    end)
end)

Window:SetToggleKey(Enum.KeyCode[getgenv().ConfigurationTable.MinimizeBind])
Window:SelectTab(1)

WindUI:Notify({
    Title = "tr:ScriptLoader",
    Content = "tr:ScriptLoaded",
    Icon = VenuzIcon,
    Duration = 5,
})

RunService.RenderStepped:Connect(function()
    if game:GetService("Players").LocalPlayer.PlayerGui.DeathScreen.Enabled then
        for i,v in pairs(getconnections(game:GetService("Players").LocalPlayer.PlayerGui.DeathScreen.Frame.Frame.Buttons.Respawn.Button.MouseButton1Down)) do
            v:Fire()
        end

        for i,v in pairs(getconnections(game:GetService("Players").LocalPlayer.PlayerGui.DeathScreen.Frame.Frame.Buttons.Respawn.Button.MouseButton1Up)) do
            v:Fire()
        end
    end

    if not getgenv().Settings.Main.AutoFarmFish then
        return
    end

    local plr = game.Players.LocalPlayer
    local char = plr.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")

    if not hrp or not hum or hum.Health <= 0 then
        return
    end

    local footer = workspace:FindFirstChild("Venuz_Footer")
    if not footer then
        footer = Instance.new("Part")
        footer.Name = "Venuz_Footer"
        footer.Parent = workspace
        footer.Size = Vector3.new(5, 0.5, 5)
        footer.Transparency = 1
        footer.Anchored = true
        footer.CanCollide = true
    end

    footer.CFrame = hrp.CFrame * CFrame.new(0, -3.5, 0)
end)