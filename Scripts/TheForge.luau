pcall(function()
    game.Players.LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
end)

getgenv().ConfigurationTable = {}
getgenv().Settings = {}
 
local FolderConfiguration = "Venuz Hub"
local FolderSettings = "Venuz Hub/The_Forge"
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

local filenameConfiguration = FolderConfiguration .. "/" .. "Setting_".. LocalPlayer.Name .. ".json"
local filenameSetting = FolderSettings .. "/" .. "GameConfig_".. LocalPlayer.Name..".json"

local World1 = 76558904092080
local World2 = 129009554587176
getgenv().UsePoint = false
getgenv().BuyPoint = false
getgenv().Golem = false
getgenv().Forge = false

local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local ImageLabel = Instance.new("ImageLabel")

ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

Frame.Parent = ScreenGui
Frame.AnchorPoint = Vector2.new(0.5, 0.5)
Frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Frame.BackgroundTransparency = 1.000
Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
Frame.BorderSizePixel = 0
Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
Frame.Size = UDim2.new(0.426136345, 0, 0.815926909, 0)

ImageLabel.Parent = Frame
ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
ImageLabel.BorderSizePixel = 0
ImageLabel.Size = UDim2.new(1, 0, 1, 0)
ImageLabel.Image = "rbxassetid://77253401370335"

hrp.CFrame = workspace.Proximity["Greedy Cey"].HumanoidRootPart.CFrame, tweenspeedstarat
task.wait(0.2)
fireproximityprompt(workspace.Proximity["Greedy Cey"].ProximityPrompt)
task.wait(0.5)
hrp.CFrame = workspace.Proximity["Greedy Cey"].HumanoidRootPart.CFrame, tweenspeedstarat
task.wait(0.2)
fireproximityprompt(workspace.Proximity["Greedy Cey"].ProximityPrompt)

task.wait(3)

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
    ["Automatic"] = {
        ["AutoFarm"] = {
            ["SelectRock"] = {},
            ["Method"] = "Below",
            ["AutoFarmRock"] = false,
            ["Zones"] = {},
            ["SelectMob"] = {},
            ["MethodMob"] = "Below",
            ["AutoFarmMob"] = false,
            ["SilentMode"] = false,
            ["SilentDistance"] = 10,
            ["SilentColor"] = {r = 255, g = 255, b = 255},
            ["KeepOres"] = {},
            ["NearbyMobs"] = false,
            ["CheckGolem"] = 120,
            ["AutoFarmGolem"] = false,
        },
        ["Priority"] = {
            ["PriorityRock"] = {},
            ["PriorityMobs"] = {},
        },
        ["AutoForge"] = {
            ["AutoForge"] = false,
        },
        ["AutoSell"] = {
            ["AutoSell"] = false,
            ["SelectOres"] = {},
            ["SelectMaterials"] = {},
            ["SelectRunes"] = {},
            ["TimeInterval"] = 120,
            ["SellInventoryFull"] = false,
        },
        ["Points"] = {
            ["SelectPoints"] = {},
            ["AutoUsePoints"] = false,
            ["AutoBuyPoints"] = false,
            ["BuyAmount"] = {},
        }
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
            --Tabs
            ["Automaic"] = "อัตโนมัติ",
            ["AutoFarm"] = "ฟาร์มอัตโนมัติ",
            ["Priority"] = "ลำดับความสำคัญ",
            ["AutoSell"] = "ขายอัตโนมัติ",
            ["AutoPoints"] = "ยา",
            ["Utility"] = "ทั่วไป",
            ["Misc"] = "อื่นๆ",
            --Automatic
             -- AutoFarm
             ["SilentMode"] = "โหมดเงียบ",
             ["SilentDistance"] = "ระยะตรวจจับผู้เล่น",
             ["SilentCircleColor"] = "ปรับสี",
             ["AutoFarmMobTab"] = "ฟาร์มม็อบอัตโนมัติ",
             ["AutoFarmGolemTab"] = "ฟาร์มโกเลมอัตโนมัติ",
             ["CheckGolemTimer"] = "ตรวจสอบเวลาโกเลมเข้าร่วมได้",
             ["AutoFarmGolem"] = "ฟาร์มโกเลมอัตโนมัติ",
             ["SelectMob"] = "เลือกม็อบที่จะฟาร์ม",
             ["MethodMob"] = "รูปแบบการฟาร์มม็อบ",
             ["ZonesRocks"] = "เลือกโซนในการฟาร์มหิน",
             ["AutoFarmMob"] = "ฟาร์มม็อบอัตโนมัติ",
             ["AutoFarmRocksTab"] = "ฟาร์มหินอัตโนมัติ",
             ["SelectRocks"] = "เลือกหินที่จะฟาร์ม",
             ["MethodRock"] = "รูปแบบการฟาร์มหิน",
             ["KeepOresTarget"] = "เก็บเฉพาะแร่ที่เลือก",
             ["NearbyMobs"] = "ฆ่าม็อบบริเวนใกล้ๆ",
             ["AutoFarmRocks"] = "ฟาร์มหินอัตโนมัติ",
             -- Priority
             ["PriorityTab"] = "หิน",
             ["PriorityTab1"] = "ม็อบ",
             -- AutoForge
             ["AutoForgeTab"] = "เตาหลอมอัตโนมัติ",
             ["StatsForge"] = "สถานะการหลอม",
             ["AutoForge"] = "หลอมอัตโนมัติ",
             ["OpenForgeUI"] = "เปิดหน้าต่างเตาหลอม",
             -- AutoSell
             ["AutoSellTab"] = "ขายอัตโนมัติ",
             ["SelectOresToSell"] = "เลือกแร่ที่จะขาย",
             ["SelectMaterialsToSell"] = "เลือกวัสดุที่จะขาย",
             ["SelectRunesToSell"] = "เลือกรูนที่จะขาย",
             ["AutoSellInterval"] = "ระยะเวลาขายอัตโนมัติ (วินาที)",
             ["SellWhenInventoryFull"] = "ขายเมื่อช่องเก็บของใกล้เต็ม",
             ["AutoSellByTime"] = "ขายอัตโนมัติ",
             -- AutoPoints
             ["PointsTab"] = "ยา",
             ["SelectPoints"] = "เลือกยา",
             ["AutoUsePoints"] = "ใช้ยาอัตโนมัติ",
             ["AutoBuyPoints"] = "ซื้อยาอัตโนมัติ",
             ["PointsTab1"] = "ตั้งค่าการซื้อยา",
            --Utility
             -- Teleport
             ["NPCTP"] = "เลือกที่จะวาปไป",
             ["TP"] = "เทเลพอร์ต",
             ["TelePort"] = "เทเลพอร์ต",
             -- Misc
             ["RedeemAllCodes"] = "แลกรหัสทั้งหมดในเกม",
            -- Settings
            ["Interface"] = "การตั้งค่า",
            ["themeDropdown"] = "เลือก ธีม",
            ["ToggleTransparency"] = "UI โปรพื้นหลังโปร่งใส่",
            ["AntiAFK"] = "ป้องกันหลุดออกจากเกม (Anti-AFK)",
            ["AutoRejoin"] = "เข้าร่วมเกมอัตโนมัติเมื่อหลุด (AutoRejoin)",
            ["AutoExecutor"] = "รันโปรออโต้เมื่อย้ายเซิฟ (AutoExecutor)",
            ["MinimizeBind"] = "ปุ่มที่จะใช้เปิดปิดโปร",
            ["FPSIS"] = "FPS",
            ["FPSVALUE"] = "FPS",
            ["FPSLOCK"] = "ล็อค FPS",
            ["WhiteScreen"] = "จอขาว",
            ["LanguageTab"] = "ภาษา",
            ["Language"] = "เลือกภาษา",
            ["ChangedLanguage"] = "เปลี่ยนภาษา",
        },
        ["English (US)"] = {
            --Tabs
            ["Automaic"] = "Automatic",
            ["AutoFarm"] = "Auto Farm",
            ["Priority"] = "Priority",
            ["AutoForgeTab"] = "Auto Forge",
            ["AutoSell"] = "Auto Sell",
            ["AutoPoints"] = "Potions",
            ["Utility"] = "Normally",
            ["Misc"] = "Misc",
            --Automatic
             -- AutoFarm
             ["SilentMode"] = "Silent Mode",
             ["SilentDistance"] = "Player Detection Distance",
             ["SilentCircleColor"] = "Adjust Color",
             ["AutoFarmMobTab"] = "Auto Farm Mobs",
             ["AutoFarmGolemTab"] = "Auto Farm Golem",
             ["CheckGolemTimer"] = "Check Golem Timer",
             ["AutoFarmGolem"] = "Auto Farm Golem",
             ["SelectMob"] = "Select Mobs",
             ["MethodMob"] = "Method",
             ["ZonesRocks"] = "Select Zone",
             ["AutoFarmMob"] = "Auto Farm Mobs",
             ["AutoFarmRocksTab"] = "Auto Farm Rocks",
             ["SelectRocks"] = "Select Rocks",
             ["MethodRock"] = "Method",
             ["KeepOresTarget"] = "Keep Ores Target",
             ["NearbyMobs"] = "Auto Kill Nearby Mobs",
             ["AutoFarmRocks"] = "Auto Farm Rocks",
             -- Priority
             ["PriorityTab"] = "Rocks",
             ["PriorityTab1"] = "Mobs",
             -- AutoForge
             ["StatsForge"] = "Forge Status",
             ["AutoForge"] = "Auto Forge",
             ["OpenForgeUI"] = "Open Forge UI",
             -- AutoSell
             ["AutoSellTab"] = "Auto Sell",
             ["SelectOresToSell"] = "Select Ores",
             ["SelectMaterialsToSell"] = "Select Materials",
             ["SelectRunesToSell"] = "Select Runes",
             ["AutoSellInterval"] = "Auto Sell Delay (Seconds)",
             ["SellWhenInventoryFull"] = "Sell When Inventory nearly is Full",
             ["AutoSellByTime"] = "Auto Sell",
             -- Potions
             ["PointsTab"] = "Potions",
             ["SelectPoints"] = "Select Potions",
             ["AutoUsePoints"] = "Automatic Potion Use",
             ["AutoBuyPoints"] = "Automatic Potion Purchase",
             ["PointsTab1"] = "Potions Auto Buy Settings",
            --Utility
             -- Teleport
             ["NPCTP"] = "Select To Teleport",
             ["TP"] = "Teleport",
             ["TelePort"] = "Teleport",
             -- Misc
             ["RedeemAllCodes"] = "Redeem All Codes",
            -- Settings
            ["Interface"] = "Interface Settings",
            ["themeDropdown"] = "Select Theme",
            ["ToggleTransparency"] = "Toggle Window Transparency",
            ["AntiAFK"] = "Anti-AFK",
            ["AutoRejoin"] = "AutoRejoin",
            ["AutoExecutor"] = "AutoExecutor",
            ["MinimizeBind"] = "Minimize Bind",
            ["FPSIS"] = "FPS",
            ["FPSVALUE"] = "FPS",
            ["FPSLOCK"] = "FPS Lock",
            ["WhiteScreen"] = "White Screen",
            ["LanguageTab"] = "LanguageTab",
            ["Language"] = "Select Language",
            ["ChangedLanguage"] = "Change Language",
        },
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
    Title = "Update Latest 1/3/2026",
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

---- ============ Function ============ ----
getgenv().Selling = false
local ActiveTween = nil
local lastSellTime = 0
local RunService = game:GetService("RunService")
local NoClipConnection = nil

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

    local undergroundDepth = game.PlaceId == World2 and -10 or -30
    local humanoidRootPart = game.Players.LocalPlayer.Character.HumanoidRootPart
    local tweenService = game:GetService("TweenService")

    -- เก็บ orientation เดิมของตัวละคร (แค่การหมุนแกน Y)
    local originalCFrame = humanoidRootPart.CFrame
    local _, originalY, _ = originalCFrame:ToOrientation()

    -- สร้าง CFrame ใหม่ที่เก็บเฉพาะ Position และ Y rotation
    local function createUpright(position, yRotation)
        return CFrame.new(position) * CFrame.Angles(0, yRotation or originalY, 0)
    end

    -- ขั้นตอนที่ 1: ลงใต้ดิน (ตำแหน่งเริ่มต้น)
    local startPosUnderground = createUpright(
        Vector3.new(humanoidRootPart.Position.X, undergroundDepth, humanoidRootPart.Position.Z)
    )
    
    -- ขั้นตอนที่ 2: เดินใต้ดินไปยังตำแหน่ง X,Z ของเป้าหมาย
    local targetPosUnderground = createUpright(
        Vector3.new(P.Position.X, undergroundDepth, P.Position.Z)
    )
    
    -- ขั้นตอนที่ 3: ขึ้นมาที่ตำแหน่งจริงของเป้าหมาย
    local finalPosition = createUpright(P.Position)
    
    local undergroundDistance = (targetPosUnderground.Position - startPosUnderground.Position).Magnitude

    -- Tween 1: ลงใต้ดิน
    local tweenDown = tweenService:Create(
        humanoidRootPart,
        TweenInfo.new(0.5, Enum.EasingStyle.Sine),
        {CFrame = startPosUnderground}
    )

    -- Tween 2: เดินใต้ดิน
    local tweenUnderground = tweenService:Create(
        humanoidRootPart,
        TweenInfo.new(undergroundDistance / speed, Enum.EasingStyle.Linear),
        {CFrame = targetPosUnderground}
    )

    -- Tween 3: ขึ้นมาบนพื้น
    local tweenUp = tweenService:Create(
        humanoidRootPart,
        TweenInfo.new(0.5, Enum.EasingStyle.Sine),
        {CFrame = finalPosition}
    )

    -- เริ่ม Tween ลงใต้ดิน
    ActiveTween = tweenDown
    tweenDown:Play()

    tweenDown.Completed:Connect(function()
        if tweenDown.PlaybackState == Enum.PlaybackState.Completed then
            -- เริ่ม Tween ใต้ดิน
            ActiveTween = tweenUnderground
            tweenUnderground:Play()
            
            task.spawn(function()
                while ActiveTween == tweenUnderground do
                    task.wait()

                    local dist = (humanoidRootPart.Position - P.Position).Magnitude
                    if dist <= 30 then
                        tweenUnderground:Cancel()
                        -- ข้ามไปขึ้นบนเลย
                        ActiveTween = tweenUp
                        tweenUp:Play()
                        break
                    end
                    
                    if humanoidRootPart.Position.Y < undergroundDepth then
                        local currentPos = humanoidRootPart.Position
                        humanoidRootPart.CFrame = createUpright(
                            Vector3.new(currentPos.X, undergroundDepth, currentPos.Z)
                        )
                    end
                end
            end)
        end
    end)

    tweenUnderground.Completed:Connect(function()
        if tweenUnderground.PlaybackState == Enum.PlaybackState.Completed then
            -- เมื่อเดินใต้ดินเสร็จ ให้ขึ้นมาบนพื้น
            ActiveTween = tweenUp
            tweenUp:Play()
        end
    end)

    tweenUp.Completed:Connect(function()
        if tweenUp.PlaybackState == Enum.PlaybackState.Completed then
            ActiveTween = nil
        end
    end)

    -- Return tweenUp เพื่อให้สามารถ .Completed:Wait() ได้ที่ตำแหน่งจริง
    return tweenUp
end

local function CheckNearbyPlayers(position, checkDistance)
    local localPlayer = game.Players.LocalPlayer
    
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local otherHRP = player.Character:FindFirstChild("HumanoidRootPart")
            if otherHRP then
                local distance = (otherHRP.Position - position).Magnitude
                if distance <= checkDistance then
                    return true, player.Name
                end
            end
        end
    end
    
    return false, nil
end

---- ============ Automatic ============ ----

local Section = Window:Section({
    Title = "tr:Automaic",
    Icon = "code-xml",
    Opened = false,
})

local Tab = Section:Tab({
    Title = "tr:AutoFarm",
    Icon = "play",
    Opened = true,
})

---- ============ AutoFarm ============ ----

-- ============ Silent Mode ============ --

local SilentModeTab = Tab:Section({ Title = "tr:SilentMode", Icon = "eye-off"})

local SilentModeCircle = nil

function CreateSilentCircle(radius)
    if SilentModeCircle then
        SilentModeCircle:Destroy()
        SilentModeCircle = nil
    end
    
    local circle = Instance.new("Part")
    circle.Name = "SilentModeRadius"
    circle.Anchored = true
    circle.CanCollide = false
    circle.Transparency = 1
    circle.Size = Vector3.new(radius * 2, 0.1, radius * 2)
    circle.CastShadow = false
    
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Face = Enum.NormalId.Top
    surfaceGui.AlwaysOnTop = true
    surfaceGui.LightInfluence = 0
    surfaceGui.Parent = circle
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    
    local colorData = getgenv().Settings.Automatic.AutoFarm.SilentColor
    frame.BackgroundColor3 = Color3.fromRGB(colorData.r, colorData.g, colorData.b)
    frame.BackgroundTransparency = 0.9
    frame.BorderSizePixel = 0
    frame.Parent = surfaceGui
    
    -- ทำให้เป็นวงกลม
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(1, 0)
    uiCorner.Parent = frame
    
    -- ขอบวงกลม
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = Color3.fromRGB(colorData.r, colorData.g, colorData.b)
    uiStroke.Thickness = 4
    uiStroke.Transparency = 0.2
    uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    uiStroke.Parent = frame
    
    circle.Parent = workspace
    SilentModeCircle = circle
    
    task.spawn(function()
        while SilentModeCircle and getgenv().Settings.Automatic.AutoFarm.SilentMode do
            task.wait()
            local character = game.Players.LocalPlayer.Character
            if character then
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    circle.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y - 2.5, hrp.Position.Z)
                end
            end
        end
    end)
    
    return circle
end

function RemoveSilentCircle()
    if SilentModeCircle then
        SilentModeCircle:Destroy()
        SilentModeCircle = nil
    end
end

local SilentMode = Tab:Toggle({
    Title = "tr:SilentMode",
    Value = getgenv().Settings.Automatic.AutoFarm.SilentMode,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoFarm.SilentMode = Value
        SaveSetting()
        
        if Value then
            local radius = getgenv().Settings.Automatic.AutoFarm.SilentDistance
            CreateSilentCircle(radius)
            
            WindUI:Notify({
                Title = "Silent Mode | Enabled",
                Content = "Detection radius: " .. radius .. " studs",
                Icon = VenuzIcon,
                Duration = 3,
            })
        else
            RemoveSilentCircle()
            
            WindUI:Notify({
                Title = "Silent Mode | Disabled",
                Content = "Detection radius hidden",
                Icon = VenuzIcon,
                Duration = 3,
            })
        end
    end
})

local SilentDistance = Tab:Slider({
    Title = "tr:SilentDistance",
    Value = {
        Min = 1,
        Max = 200,
        Default = getgenv().Settings.Automatic.AutoFarm.SilentDistance
    },
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoFarm.SilentDistance = Value
        SaveSetting()
        
        if getgenv().Settings.Automatic.AutoFarm.SilentMode then
            CreateSilentCircle(Value)
        end
    end
})

local SilentColorPicker = Tab:Colorpicker({
    Title = "tr:SilentCircleColor",
    Default = Color3.fromRGB(
        getgenv().Settings.Automatic.AutoFarm.SilentColor.r,
        getgenv().Settings.Automatic.AutoFarm.SilentColor.g,
        getgenv().Settings.Automatic.AutoFarm.SilentColor.b
    ),
    Transparency = 0,
    Locked = false,
    Callback = function(color) 
        getgenv().Settings.Automatic.AutoFarm.SilentColor = {
            r = math.floor(color.R * 255),
            g = math.floor(color.G * 255),
            b = math.floor(color.B * 255)
        }
        SaveSetting()
        
        if getgenv().Settings.Automatic.AutoFarm.SilentMode and SilentModeCircle then
            local surfaceGui = SilentModeCircle:FindFirstChild("SurfaceGui")
            if surfaceGui then
                local frame = surfaceGui:FindFirstChild("Frame")
                if frame then
                    frame.BackgroundColor3 = color
                    local uiStroke = frame:FindFirstChildOfClass("UIStroke")
                    if uiStroke then
                        uiStroke.Color = color
                    end
                end
            end
        end
    end
})

-- ============ AutoFarm Rocks ============ --

local AutoFarmRocksTab = Tab:Section({ Title = "tr:AutoFarmRocksTab", Icon = "pickaxe"})

local RocksList = {}
local Zones = {}
local OresSkip = {}
local MonsList = {}

for i,v in pairs(game:GetService("ReplicatedStorage").Assets.Rocks:GetChildren()) do
    table.insert(RocksList, v.Name)
end

for i, v in pairs(workspace.Rocks:GetChildren()) do
    local zone
    if game.PlaceId == World1 then
        zone = string.match(v.Name, "Island1(.+)")
    elseif game.PlaceId == World2 then
        zone = string.match(v.Name, "Island2(.+)")
    else
        zone = string.match(v.Name, "Island3(.+)")
    end
    if zone then
        local zoneName = zone
        if not table.find(Zones, zoneName) then
            table.insert(Zones, zoneName)
        end
    end
end

for i,v in pairs(game:GetService("ReplicatedStorage").Shared.Data.Ore:GetDescendants()) do
    if v:IsA("ModuleScript") then
        table.insert(OresSkip, v.Name)
    end
end

for i,v in pairs(game:GetService("ReplicatedStorage").Assets.Mobs:GetChildren()) do
    table.insert(MonsList, v.Name)
end

local SelectRocks = Tab:Dropdown({
    Title = "tr:SelectRocks",
    Multi = true,
    AllowNone = true,
    Values = RocksList,
    Value = getgenv().Settings.Automatic.AutoFarm.SelectRock,
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoFarm.SelectRock = Value
        SaveSetting()
    end
})

local Method = Tab:Dropdown({
    Title = "tr:MethodRock",
    Multi = false,
    AllowNone = false,
    Values = {"Over","Below","Behind"},
    Value = getgenv().Settings.Automatic.AutoFarm.Method,
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoFarm.Method = Value
        SaveSetting()
    end
})

local KeepOresTarget = Tab:Dropdown({
    Title = "tr:KeepOresTarget",
    Multi = true,
    AllowNone = true,
    Values = OresSkip,
    Value = getgenv().Settings.Automatic.AutoFarm.KeepOres,
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoFarm.KeepOres = Value
        SaveSetting()
    end
})

local KillNearbyMobs = Tab:Toggle({
    Title = "tr:NearbyMobs",
    Value = getgenv().Settings.Automatic.AutoFarm.NearbyMobs,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoFarm.NearbyMobs = Value
        SaveSetting()
    end
})

local ZonesDropdown = Tab:Dropdown({
    Title = "tr:ZonesRocks",
    Multi = true,
    AllowNone = true,
    Values = Zones,
    Value = getgenv().Settings.Automatic.AutoFarm.Zones,
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoFarm.Zones = Value
        SaveSetting()
    end
})

local AutoFarmRocks
local AutoFarmMob

AutoFarmRocks = Tab:Toggle({
    Title = "tr:AutoFarmRocks",
    Value = getgenv().Settings.Automatic.AutoFarm.AutoFarmRock,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoFarm.AutoFarmRock = Value
        SaveSetting()

        if Value then
            AutoFarmMob:Lock()
            task.spawn(function()
                pcall(function()
                    StartNoClip()
                    local tweenspeed = game.PlaceId == World2 and 25 or 35
                    local undergroundDepth = game.PlaceId == World2 and -10 or -20
                    
                    function GetPriorityValue(priorityName)
                        local priorityMap = {
                            ["Lower"] = 1,
                            ["Normal"] = 2,
                            ["High"] = 3,
                            ["Very High"] = 4
                        }
                        return priorityMap[priorityName] or 2
                    end
                    
                    function CheckDeathScreen()
                        local deathscreen = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("DeathScreen")
                        if deathscreen then
                            StopNoClip()
                            local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            local humanoid = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                            if hrp then hrp.Anchored = false end
                            if humanoid then humanoid.PlatformStand = false end
                            repeat task.wait(1) until not game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("DeathScreen")
                            task.wait(2)
                            StartNoClip()
                            return true
                        end
                        return false
                    end
                    
                    function IsRockOwnedByMe(rock)
                        if rock then
                            local owner = rock:GetAttribute("LastHitPlayer")
                            if owner and owner ~= game.Players.LocalPlayer.Name then
                                return false
                            end
                        end
                        return true
                    end
                    
                    while getgenv().Settings.Automatic.AutoFarm.AutoFarmRock do task.wait()
                        if not getgenv().Settings.Automatic.AutoFarm.AutoFarmRock then break end

                        if CheckDeathScreen() then continue end

                        local player = game.Players.LocalPlayer
                        local char = player.Character
                        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")

                        if not (char and humanoid and hrp) or humanoid.Health <= 0 then
                            StopNoClip()
                            if hrp then hrp.Anchored = false end
                            if humanoid then humanoid.PlatformStand = false end
                            task.wait(1)
                            continue
                        end

                        if getgenv().Settings.Automatic.AutoFarm.NearbyMobs then
                            local nearestMob = nil
                            local nearestMobDistance = math.huge
                            
                            for _, mob in ipairs(workspace.Living:GetChildren()) do
                                if mob:GetAttribute("IsNpc") then
                                    local mhrp = mob:FindFirstChild("HumanoidRootPart")
                                    local mh = mob:FindFirstChildOfClass("Humanoid")
                                    if mhrp and mh and mh.Health > 0 then
                                        local dist = (hrp.Position - mhrp.Position).Magnitude
                                        if dist <= 20 and dist < nearestMobDistance then
                                            nearestMobDistance = dist
                                            nearestMob = mob
                                        end
                                    end
                                end
                            end
                            
                            if nearestMob then
                                for _, v in ipairs(player.Backpack:GetChildren()) do
                                    if v.Name:lower():find("weapon") then
                                        humanoid:EquipTool(v)
                                        break
                                    end
                                end
                                
                                local mhrp = nearestMob:FindFirstChild("HumanoidRootPart")
                                local mh = nearestMob:FindFirstChildOfClass("Humanoid")
                                
                                if mhrp and mh and mh.Health > 0 then
                                    local monPos = mhrp.Position + Vector3.new(0, 7, 0)
                                    if (hrp.Position - mhrp.Position).Magnitude > 30 then
                                        local tween = TweenFarm(CFrame.new(monPos), tweenspeed)
                                        tween.Completed:Wait()
                                    end
                                    
                                    humanoid.PlatformStand = true
                                    
                                    repeat task.wait()
                                        if CheckDeathScreen() then break end
                                        
                                        mhrp = nearestMob:FindFirstChild("HumanoidRootPart")
                                        mh = nearestMob:FindFirstChildOfClass("Humanoid")
                                        
                                        if not (mhrp and mh) then break end
                                        if mh.Health <= 0 then break end
                                        
                                        local MobsPos
                                        if getgenv().Settings.Automatic.AutoFarm.MethodMob == "Over" then
                                            MobsPos = mhrp.Position + Vector3.new(0, 7, 0)
                                        elseif getgenv().Settings.Automatic.AutoFarm.MethodMob == "Below" then
                                            MobsPos = mhrp.Position + Vector3.new(0, -7, 0)
                                        elseif getgenv().Settings.Automatic.AutoFarm.MethodMob == "Behind" then
                                            MobsPos = mhrp.Position - (mhrp.CFrame.LookVector * 7)
                                        end
                                        hrp.CFrame = CFrame.lookAt(MobsPos, mhrp.Position)
                                        
                                        game:GetService("ReplicatedStorage").Shared.Packages.Knit.Services.ToolService.RF.ToolActivated:InvokeServer("Weapon")
                                    until not mh or mh.Health <= 0 or not getgenv().Settings.Automatic.AutoFarm.AutoFarmRock
                                    
                                    humanoid.PlatformStand = false
                                end
                            end
                        end

                        for i,v in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
                            if v.Name:lower():find("pickaxe") then
                                game.Players.LocalPlayer.Character.Humanoid:EquipTool(v)
                            end
                        end

                        if getgenv().UsePoint == true then
                            repeat task.wait(1) until getgenv().UsePoint == false
                            task.wait(1)
                        end

                        if getgenv().BuyPoint == true then
                            repeat task.wait(1) until getgenv().BuyPoint == false
                            task.wait(1)
                        end

                        if getgenv().Golem == true then
                            repeat task.wait() until getgenv().Golem == false
                            task.wait(1)
                        end

                        function IsRockSelected(rockName)
                            return table.find(getgenv().Settings.Automatic.AutoFarm.SelectRock, rockName) ~= nil
                        end

                        function ShouldSkipRock(rock)
                            local keepOres = getgenv().Settings.Automatic.AutoFarm.KeepOres

                            if not keepOres or #keepOres == 0 then
                                return false
                            end

                            local foundOre = false

                            for _, oreModel in pairs(rock:GetChildren()) do
                                if oreModel:IsA("Model") and oreModel.Name == "Ore" then
                                    foundOre = true

                                    local oreType = oreModel:GetAttribute("Ore")
                                    if oreType and table.find(keepOres, oreType) then
                                        return false
                                    end
                                end
                            end

                            if not foundOre then
                                return false
                            end

                            return true
                        end

                        local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart
                        
                        local selectedZones = getgenv().Settings.Automatic.AutoFarm.Zones
                        local zoneFolders = {}
                        local searchAllZones = false

                        if selectedZones and type(selectedZones) == "table" and #selectedZones > 0 then
                            for _, zoneName in ipairs(selectedZones) do
                                local zoneFolder
                                if game.PlaceId == World1 then
                                    zoneFolder = workspace.Rocks:FindFirstChild("Island1" .. zoneName)
                                elseif game.PlaceId == World2 then
                                    zoneFolder = workspace.Rocks:FindFirstChild("Island2" .. zoneName)
                                else
                                    zoneFolder = workspace.Rocks:FindFirstChild("Island3" .. zoneName)
                                end
                                
                                if zoneFolder then
                                    table.insert(zoneFolders, zoneFolder)
                                end
                            end
                        else
                            searchAllZones = true
                        end
                        
                        local availableRocks = {}
                        
                        if #zoneFolders > 0 and not searchAllZones then
                            for _, zoneFolder in ipairs(zoneFolders) do
                                for i,v in pairs(zoneFolder:GetDescendants()) do
                                    if IsRockSelected(v.Name) then
                                        if v:FindFirstChild("Hitbox") then
                                            local infoframe = v:FindFirstChild("infoFrame")
                                            local frame = infoframe and infoframe:FindFirstChild("Frame")
                                            local rockhp = frame and frame:FindFirstChild("rockHP")
                                            if infoframe and frame and rockhp and rockhp.Text ~= "0 HP" then
                                                if not ShouldSkipRock(v) and IsRockOwnedByMe(v) then
                                                    local distance = (hrp.Position - v.Hitbox.Position).Magnitude
                                                    local priority = getgenv().Settings.Automatic.Priority.PriorityRock[v.Name] or "Normal"
                                                    local priorityValue = GetPriorityValue(priority)
                                                    
                                                    table.insert(availableRocks, {
                                                        rock = v,
                                                        distance = distance,
                                                        priority = priorityValue,
                                                        priorityName = priority
                                                    })
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        elseif searchAllZones then
                            for i,v in pairs(workspace.Rocks:GetDescendants()) do
                                if IsRockSelected(v.Name) then
                                    if v:FindFirstChild("Hitbox") then
                                        local infoframe = v:FindFirstChild("infoFrame")
                                        local frame = infoframe and infoframe:FindFirstChild("Frame")
                                        local rockhp = frame and frame:FindFirstChild("rockHP")
                                        if infoframe and frame and rockhp and rockhp.Text ~= "0 HP" then
                                            if not ShouldSkipRock(v) and IsRockOwnedByMe(v) then
                                                local distance = (hrp.Position - v.Hitbox.Position).Magnitude
                                                local priority = getgenv().Settings.Automatic.Priority.PriorityRock[v.Name] or "Normal"
                                                local priorityValue = GetPriorityValue(priority)
                                                
                                                table.insert(availableRocks, {
                                                    rock = v,
                                                    distance = distance,
                                                    priority = priorityValue,
                                                    priorityName = priority
                                                })
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        
                        table.sort(availableRocks, function(a, b)
                            if a.priority == b.priority then
                                return a.distance < b.distance
                            end
                            return a.priority > b.priority
                        end)
                        
                        local nearestRock = nil
                        if #availableRocks > 0 then
                            nearestRock = availableRocks[1].rock
                        end
                        
                        if not nearestRock then
                            hrp.Anchored = true
                            if #zoneFolders > 0 and not searchAllZones then
                                for _, zoneFolder in ipairs(zoneFolders) do
                                    for i,v in pairs(zoneFolder:GetDescendants()) do
                                        if IsRockSelected(v.Name) then
                                            if v:FindFirstChild("Hitbox") then
                                                local infoframe = v:FindFirstChild("infoFrame")
                                                local frame = infoframe and infoframe:FindFirstChild("Frame")
                                                local rockhp = frame and frame:FindFirstChild("rockHP")
                                                if infoframe and frame and rockhp and rockhp.Text ~= "0 HP" then
                                                    if not ShouldSkipRock(v) and IsRockOwnedByMe(v) then
                                                        nearestRock = v
                                                        break
                                                    end
                                                end
                                            end
                                        end
                                    end
                                    if nearestRock then break end
                                end
                            elseif searchAllZones then
                                for i,v in pairs(workspace.Rocks:GetDescendants()) do
                                    if IsRockSelected(v.Name) then
                                        if v:FindFirstChild("Hitbox") then
                                            local infoframe = v:FindFirstChild("infoFrame")
                                            local frame = infoframe and infoframe:FindFirstChild("Frame")
                                            local rockhp = frame and frame:FindFirstChild("rockHP")
                                            if infoframe and frame and rockhp and rockhp.Text ~= "0 HP" then
                                                if not ShouldSkipRock(v) and IsRockOwnedByMe(v) then
                                                    nearestRock = v
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end

                        if nearestRock then
                            hrp.Anchored = false
                            local v = nearestRock
                            if not getgenv().Settings.Automatic.AutoFarm.AutoFarmRock then break end

                            if v:FindFirstChild("Hitbox") then
                                local infoframe = v:FindFirstChild("infoFrame")
                                local frame = infoframe and infoframe:FindFirstChild("Frame")
                                local rockhp = frame and frame:FindFirstChild("rockHP")
                                if infoframe and frame and rockhp then
                                    if rockhp.Text ~= "0 HP" then
                                        local rockDistance = (hrp.Position - v.Hitbox.Position).Magnitude
                                        
                                        if rockDistance <= 50 then
                                            local targetPosUnderground = v.Hitbox.CFrame * CFrame.new(0, undergroundDepth, 0)
                                            hrp.CFrame = CFrame.lookAt(targetPosUnderground.Position, v.Hitbox.Position)
                                        else
                                            local tween = TweenFarm(v.Hitbox.CFrame, tweenspeed)
                                            tween.Completed:Wait()
                                        end

                                        if not getgenv().Settings.Automatic.AutoFarm.AutoFarmRock then break end
                                        
                                        local targetPos
                                        if getgenv().Settings.Automatic.AutoFarm.Method == "Over" then
                                            targetPos = v.Hitbox.Position + Vector3.new(0, 7, 0)
                                        elseif getgenv().Settings.Automatic.AutoFarm.Method == "Below" then
                                            targetPos = v.Hitbox.Position + Vector3.new(0, -7, 0)
                                        elseif getgenv().Settings.Automatic.AutoFarm.Method == "Behind" then
                                            targetPos = v.Hitbox.Position - (v.Hitbox.CFrame.LookVector * 7)
                                        end
                                        hrp.CFrame = CFrame.lookAt(targetPos, v.Hitbox.Position)

                                        if getgenv().Settings.Automatic.AutoFarm.SilentMode then
                                            local hasPlayer = false
                                            
                                            for _, player in pairs(game.Players:GetPlayers()) do
                                                if player ~= game.Players.LocalPlayer and player.Character then
                                                    local success, pivot = pcall(function()
                                                        return player.Character:GetPivot()
                                                    end)
                                                    
                                                    if success and pivot then
                                                        local playerPos = pivot.Position
                                                        local distance = (playerPos - v.Hitbox.Position).Magnitude
                                                        
                                                        if distance <= tonumber(getgenv().Settings.Automatic.AutoFarm.SilentDistance) then
                                                            hasPlayer = true
                                                            break
                                                        end
                                                    end
                                                end
                                            end
                                            
                                            if hasPlayer then
                                                hrp.CFrame = CFrame.new(hrp.Position + Vector3.new(0, undergroundDepth, 0))
                                                continue
                                            end
                                        end

                                        local hr = game.Players.LocalPlayer.Character
                                        hr.Humanoid.PlatformStand = true

                                        local shouldEscape = false
                                        local foundMob = nil
                                        local checkConnection
                                        checkConnection = game:GetService("RunService").RenderStepped:Connect(function()
                                            if CheckDeathScreen() then
                                                shouldEscape = true
                                                checkConnection:Disconnect()
                                                return
                                            end
                                            
                                            if not getgenv().Settings.Automatic.AutoFarm.AutoFarmRock then
                                                shouldEscape = true
                                                checkConnection:Disconnect()
                                                return
                                            end

                                            if getgenv().Golem == true then
                                                shouldEscape = true
                                                checkConnection:Disconnect()
                                                return
                                            end

                                            local hitbox = v:FindFirstChild("Hitbox")
                                            if not hitbox then
                                                shouldEscape = true
                                                checkConnection:Disconnect()
                                                return
                                            end
                                            
                                            if not IsRockOwnedByMe(v) then
                                                shouldEscape = true
                                                checkConnection:Disconnect()
                                                return
                                            end

                                            if ShouldSkipRock(v) then
                                                shouldEscape = true
                                                checkConnection:Disconnect()
                                                return
                                            end

                                            if getgenv().Settings.Automatic.AutoFarm.SilentMode then
                                                for _, player in pairs(game.Players:GetPlayers()) do
                                                    if player ~= game.Players.LocalPlayer and player.Character then
                                                        local success, pivot = pcall(function()
                                                            return player.Character:GetPivot()
                                                        end)
                                                        
                                                        if success and pivot then
                                                            local playerPos = pivot.Position
                                                            local distance = (playerPos - hitbox.Position).Magnitude
                                                            
                                                            if distance <= tonumber(getgenv().Settings.Automatic.AutoFarm.SilentDistance) then
                                                                shouldEscape = true
                                                                checkConnection:Disconnect()
                                                                break
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                            
                                            if getgenv().Settings.Automatic.AutoFarm.NearbyMobs then
                                                for _, mob in ipairs(workspace.Living:GetChildren()) do
                                                    if mob:GetAttribute("IsNpc") then
                                                        local mhrp = mob:FindFirstChild("HumanoidRootPart")
                                                        local mh = mob:FindFirstChildOfClass("Humanoid")
                                                        if mhrp and mh and mh.Health > 0 then
                                                            local dist = (hrp.Position - mhrp.Position).Magnitude
                                                            if dist <= 20 then
                                                                foundMob = mob
                                                                shouldEscape = true
                                                                checkConnection:Disconnect()
                                                                break
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end)

                                        repeat task.wait()
                                            if CheckDeathScreen() then break end
                                            
                                            if not getgenv().Settings.Automatic.AutoFarm.AutoFarmRock or shouldEscape then 
                                                if checkConnection then
                                                    checkConnection:Disconnect()
                                                end
                                                break 
                                            end

                                            local hitbox = v:FindFirstChild("Hitbox")
                                            if not hitbox then 
                                                if checkConnection then
                                                    checkConnection:Disconnect()
                                                end
                                                break 
                                            end
                                            
                                            if not IsRockOwnedByMe(v) then
                                                if checkConnection then
                                                    checkConnection:Disconnect()
                                                end
                                                break
                                            end

                                            if getgenv().Settings.Automatic.AutoFarm.Method == "Over" then
                                                targetPos = v.Hitbox.Position + Vector3.new(0, 7, 0)
                                            elseif getgenv().Settings.Automatic.AutoFarm.Method == "Below" then
                                                targetPos = v.Hitbox.Position + Vector3.new(0, -7, 0)
                                            elseif getgenv().Settings.Automatic.AutoFarm.Method == "Behind" then
                                                targetPos = v.Hitbox.Position - (v.Hitbox.CFrame.LookVector * 7)
                                            end

                                            hrp.CFrame = CFrame.lookAt(targetPos, hitbox.Position)

                                            game:GetService("ReplicatedStorage").Shared.Packages.Knit.Services.ToolService.RF.ToolActivated:InvokeServer("Pickaxe")
                                        until rockhp.Text == "0 HP" or not getgenv().Settings.Automatic.AutoFarm.AutoFarmRock or shouldEscape or getgenv().BuyPoint == true or getgenv().Golem == true or getgenv().UsePoint == true or humanoid.Health == 0

                                        if checkConnection then
                                            checkConnection:Disconnect()
                                        end

                                        hr.Humanoid.PlatformStand = false

                                        if foundMob and getgenv().Settings.Automatic.AutoFarm.NearbyMobs then
                                            for _, tool in ipairs(player.Backpack:GetChildren()) do
                                                if tool.Name:lower():find("weapon") then
                                                    humanoid:EquipTool(tool)
                                                    break
                                                end
                                            end
                                            
                                            local mhrp = foundMob:FindFirstChild("HumanoidRootPart")
                                            local mh = foundMob:FindFirstChildOfClass("Humanoid")
                                            
                                            if mhrp and mh and mh.Health > 0 then
                                                local monPos = mhrp.Position + Vector3.new(0, 7, 0)
                                                if (hrp.Position - mhrp.Position).Magnitude > 30 then
                                                    local tween = TweenFarm(CFrame.new(monPos), tweenspeed)
                                                    tween.Completed:Wait()
                                                end
                                                
                                                humanoid.PlatformStand = true
                                                
                                                repeat task.wait()
                                                    if CheckDeathScreen() then break end
                                                    
                                                    mhrp = foundMob:FindFirstChild("HumanoidRootPart")
                                                    mh = foundMob:FindFirstChildOfClass("Humanoid")
                                                    
                                                    if not (mhrp and mh) then break end
                                                    if mh.Health <= 0 then break end
                                                    
                                                    local MobsPos
                                                    if getgenv().Settings.Automatic.AutoFarm.MethodMob == "Over" then
                                                        MobsPos = mhrp.Position + Vector3.new(0, 7, 0)
                                                    elseif getgenv().Settings.Automatic.AutoFarm.MethodMob == "Below" then
                                                        MobsPos = mhrp.Position + Vector3.new(0, -7, 0)
                                                    elseif getgenv().Settings.Automatic.AutoFarm.MethodMob == "Behind" then
                                                        MobsPos = mhrp.Position - (mhrp.CFrame.LookVector * 7)
                                                    end
                                                    hrp.CFrame = CFrame.lookAt(MobsPos, mhrp.Position)
                                                    
                                                    game:GetService("ReplicatedStorage").Shared.Packages.Knit.Services.ToolService.RF.ToolActivated:InvokeServer("Weapon")
                                                until not mh or mh.Health <= 0 or not getgenv().Settings.Automatic.AutoFarm.AutoFarmRock or shouldEscape or getgenv().BuyPoint == true or getgenv().Golem == true or getgenv().UsePoint == true or humanoid.Health == 0
                                                
                                                humanoid.PlatformStand = false
                                            end
                                            
                                            for _, tool in ipairs(player.Backpack:GetChildren()) do
                                                if tool.Name:lower():find("pickaxe") then
                                                    humanoid:EquipTool(tool)
                                                    break
                                                end
                                            end
                                        else
                                            local hitbox = v:FindFirstChild("Hitbox")
                                            if hitbox then
                                                hrp.CFrame = hitbox.CFrame * CFrame.new(0, undergroundDepth, 0)
                                            else
                                                hrp.CFrame = CFrame.new(hrp.Position - Vector3.new(0, 70, 0))
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end

                    local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart
                    game.Players.LocalPlayer.Character.Humanoid.PlatformStand = false

                    if ActiveTween then
                        ActiveTween:Cancel()
                        ActiveTween = nil
                    end

                    local surfacePosition = CFrame.new(hrp.Position.X, 50, hrp.Position.Z)
                    local tween = TweenFarm(surfacePosition, tweenspeed)
                    tween.Completed:Wait()

                    StopNoClip()
                end)
            end)
        else
            AutoFarmMob:Unlock()
            
            task.spawn(function()
                pcall(function()
                    local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart
                    game.Players.LocalPlayer.Character.Humanoid.PlatformStand = false
                    
                    if ActiveTween then
                        ActiveTween:Cancel()
                        ActiveTween = nil
                    end
                    
                    local tweenspeed = game.PlaceId == World2 and 25 or 35
                    local surfacePosition = CFrame.new(hrp.Position.X, 20, hrp.Position.Z)
                    TweenFarm(surfacePosition, tweenspeed).Completed:Wait()
                    
                    StopNoClip()
                end)
            end)
        end
    end
})

-- ============ AutoFarm Mob ============ --

local AutoFarmMobTab = Tab:Section({ Title = "tr:AutoFarmMobTab", Icon = "skull"})

local SelectMob = Tab:Dropdown({
    Title = "tr:SelectMob",
    Multi = true,
    AllowNone = true,
    Values = MonsList,
    Value = getgenv().Settings.Automatic.AutoFarm.SelectMob,
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoFarm.SelectMob = Value
        SaveSetting()
    end
})

local Method = Tab:Dropdown({
    Title = "tr:MethodMob",
    Multi = false,
    AllowNone = false,
    Values = {"Over","Below","Behind"},
    Value = getgenv().Settings.Automatic.AutoFarm.MethodMob,
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoFarm.MethodMob = Value
        SaveSetting()
    end
})

AutoFarmMob = Tab:Toggle({
    Title = "tr:AutoFarmMob",
    Value = getgenv().Settings.Automatic.AutoFarm.AutoFarmMob,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoFarm.AutoFarmMob = Value
        SaveSetting()

        if Value then
            AutoFarmRocks:Lock()
            task.spawn(function()
                pcall(function()
                    local tweenspeed = game.PlaceId == World2 and 25 or 35
                    local exit = game.PlaceId == World2 and -20 or -30

                    function GetPriorityValue(priorityName)
                        local priorityMap = {
                            ["Lower"] = 1,
                            ["Normal"] = 2,
                            ["High"] = 3,
                            ["Very High"] = 4
                        }
                        return priorityMap[priorityName] or 2
                    end

                    local function GetBaseMobName(mobName)
                        return mobName:match("^(.-)%d+$") or mobName
                    end
                    
                    function CheckDeathScreen()
                        local deathscreen = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("DeathScreen")
                        if deathscreen then
                            StopNoClip()
                            local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            local humanoid = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                            if hrp then hrp.Anchored = false end
                            if humanoid then humanoid.PlatformStand = false end
                            repeat task.wait(1) until not game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("DeathScreen")
                            task.wait(2)
                            return true
                        end
                        return false
                    end

                    while getgenv().Settings.Automatic.AutoFarm.AutoFarmMob do task.wait()
                        if not getgenv().Settings.Automatic.AutoFarm.AutoFarmMob then break end

                        if CheckDeathScreen() then continue end

                        local player = game.Players.LocalPlayer
                        local char = player.Character
                        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")

                        if not (char and humanoid and hrp) or humanoid.Health <= 0 then
                            StopNoClip()
                            if hrp then hrp.Anchored = false end
                            if humanoid then humanoid.PlatformStand = false end
                            task.wait(1)
                            continue
                        end

                        if getgenv().BuyPoint or getgenv().UsePoint or getgenv().Golem then
                            StopNoClip()
                            if hrp then hrp.Anchored = false end
                            if humanoid then humanoid.PlatformStand = false end
                            repeat task.wait(1) until not (getgenv().BuyPoint or getgenv().UsePoint or getgenv().Golem)
                            continue
                        end

                        StartNoClip()

                        for _,v in ipairs(player.Backpack:GetChildren()) do
                            if v.Name:lower():find("weapon") then
                                humanoid:EquipTool(v)
                            end
                        end

                        local availableMobs = {}

                        for _,mob in ipairs(workspace.Living:GetChildren()) do
                            if mob:GetAttribute("IsNpc") then
                                for _,name in ipairs(getgenv().Settings.Automatic.AutoFarm.SelectMob) do
                                    if mob.Name:find("^"..name.."%d") then
                                        local mhrp = mob:FindFirstChild("HumanoidRootPart")
                                        local mh = mob:FindFirstChildOfClass("Humanoid")
                                        if mhrp and mh and mh.Health > 0 then
                                            local dist = (hrp.Position - mhrp.Position).Magnitude
                                            local baseMobName = GetBaseMobName(mob.Name)
                                            local priority = getgenv().Settings.Automatic.Priority.PriorityMobs[baseMobName] or "Normal"
                                            local priorityValue = GetPriorityValue(priority)
                                            
                                            table.insert(availableMobs, {
                                                mob = mob,
                                                distance = dist,
                                                priority = priorityValue,
                                                priorityName = priority,
                                                baseName = baseMobName
                                            })
                                        end
                                        break
                                    end
                                end
                            end
                        end

                        table.sort(availableMobs, function(a, b)
                            if a.priority == b.priority then
                                return a.distance < b.distance
                            end
                            return a.priority > b.priority
                        end)

                        local nearestMob = nil
                        if #availableMobs > 0 then
                            nearestMob = availableMobs[1].mob
                        end

                        if not nearestMob then
                            hrp.Anchored = true
                            continue
                        else
                            hrp.Anchored = false
                        end

                        local mhrp = nearestMob:FindFirstChild("HumanoidRootPart")
                        local mh = nearestMob:FindFirstChildOfClass("Humanoid")
                        if not (mhrp and mh and mh.Health > 0) then continue end

                        local monPos
                        if getgenv().Settings.Automatic.AutoFarm.MethodMob == "Over" then
                            monPos = mhrp.Position + Vector3.new(0, 7, 0)
                        elseif getgenv().Settings.Automatic.AutoFarm.MethodMob == "Below" then
                            monPos = mhrp.Position - Vector3.new(0, 7, 0)
                        else
                            monPos = mhrp.Position - (mhrp.CFrame.LookVector * 7)
                        end

                        if monPos then
                            if (hrp.Position - mhrp.Position).Magnitude > 55 then
                                local tween = TweenFarm(CFrame.new(monPos), tweenspeed)
                                tween.Completed:Wait()
                            end
                        end

                        humanoid.PlatformStand = true

                        while getgenv().Settings.Automatic.AutoFarm.AutoFarmMob do task.wait()
                            if CheckDeathScreen() then break end
                            
                            char = player.Character
                            humanoid = char and char:FindFirstChildOfClass("Humanoid")
                            hrp = char and char:FindFirstChild("HumanoidRootPart")
                            mhrp = nearestMob and nearestMob:FindFirstChild("HumanoidRootPart")
                            mh = nearestMob and nearestMob:FindFirstChildOfClass("Humanoid")

                            if not (char and humanoid and hrp and mhrp and mh) then break end
                            if mh.Health <= 0 then break end
                            if getgenv().Selling or getgenv().BuyPoint or getgenv().UsePoint or getgenv().Golem then break end

                            if getgenv().Settings.Automatic.AutoFarm.SilentMode then
                                local escape = false
                                for _,plr in ipairs(game.Players:GetPlayers()) do
                                    if plr ~= player and plr.Character then
                                        local ok,pivot = pcall(function()
                                            return plr.Character:GetPivot()
                                        end)
                                        if ok and pivot then
                                            if (pivot.Position - mhrp.Position).Magnitude <= tonumber(getgenv().Settings.Automatic.AutoFarm.SilentDistance) then
                                                escape = true
                                                break
                                            end
                                        end
                                    end
                                end
                                if escape then break end
                            end

                            repeat task.wait()
                                if CheckDeathScreen() then break end

                                for _,v in ipairs(player.Backpack:GetChildren()) do
                                    if v.Name:lower():find("weapon") then
                                        humanoid:EquipTool(v)
                                    end
                                end

                                local targetPos
                                if getgenv().Settings.Automatic.AutoFarm.MethodMob == "Over" then
                                    targetPos = mhrp.Position + Vector3.new(0, 7, 0)
                                elseif getgenv().Settings.Automatic.AutoFarm.MethodMob == "Below" then
                                    targetPos = mhrp.Position + Vector3.new(0, -7, 0)
                                else
                                    targetPos = mhrp.Position - (mhrp.CFrame.LookVector * 7)
                                end

                                hrp.CFrame = CFrame.lookAt(targetPos, mhrp.Position)

                                game:GetService("ReplicatedStorage").Shared.Packages.Knit.Services.ToolService.RF.ToolActivated:InvokeServer("Weapon")
                            until mh.Health <= 0 or getgenv().BuyPoint or getgenv().UsePoint or getgenv().Golem or not hrp or not getgenv().Settings.Automatic.AutoFarm.AutoFarmMob
                        end

                        humanoid.PlatformStand = false

                        if mhrp then
                            hrp.CFrame = mhrp.CFrame * CFrame.new(0, exit, 0)
                        end
                    end

                    StopNoClip()
                    local player = game.Players.LocalPlayer
                    local char = player.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local humanoid = char and char:FindFirstChildOfClass("Humanoid")

                    if humanoid then humanoid.PlatformStand = false end
                    if hrp then hrp.Anchored = false end
                    if ActiveTween then ActiveTween:Cancel() ActiveTween = nil end
                    if hrp then TweenFarm(CFrame.new(hrp.Position.X, 20, hrp.Position.Z), tweenspeed).Completed:Wait() end
                end)
            end)
        else
            StopNoClip()
            AutoFarmRocks:Unlock()
            local char = game.Players.LocalPlayer.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if hrp then hrp.Anchored = false end
                if humanoid then humanoid.PlatformStand = false end
            end
        end
    end
})

-- ============ AutoFarm Golem ============ --

local AutoFarmGolemTab = Tab:Section({ Title = "tr:AutoFarmGolemTab", Icon = "skull"})

local CheckGolem = Tab:Slider({
    Title = "tr:CheckGolemTimer",
    Value = {
        Min = 120,
        Max = 2000,
        Default = getgenv().Settings.Automatic.AutoFarm.CheckGolem
    },
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoFarm.CheckGolem = Value
        SaveSetting()
    end
})

local AutoFarmGolem = Tab:Toggle({
    Title = "tr:AutoFarmGolem",
    Value = getgenv().Settings.Automatic.AutoFarm.AutoFarmGolem,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoFarm.AutoFarmGolem = Value
        SaveSetting()

        if Value then
            task.wait(3)
            task.spawn(function()
                pcall(function()
                    local tweenspeed = game.PlaceId == World2 and 25 or 35
                    local exit = game.PlaceId == World2 and -20 or -30

                    while getgenv().Settings.Automatic.AutoFarm.AutoFarmGolem do task.wait()
                        if not getgenv().Settings.Automatic.AutoFarm.AutoFarmGolem then 
                            if not getgenv().AutoFarm.AutoFarmMob or not getgenv().AutoFarm.AutoFarmRock then
                                StopNoClip()
                            end
                            break
                        end
                        StartNoClip()

                        local player = game.Players.LocalPlayer
                        local char = player.Character
                        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        
                        if not (char and humanoid and hrp) or humanoid.Health <= 0 then 
                            getgenv().Golem = false
                            StopNoClip()
                            task.wait(1)
                            continue 
                        end

                        if getgenv().BuyPoint or getgenv().UsePoint then
                            repeat task.wait(1) until not (getgenv().BuyPoint or getgenv().UsePoint)
                            continue
                        end

                        for _, v in ipairs(player.Backpack:GetChildren()) do
                            if v.Name:lower():find("weapon") then
                                humanoid:EquipTool(v)
                            end
                        end

                        local foundGolem
                        local nearestDistance = 200

                        for _, mob in ipairs(workspace.Living:GetChildren()) do
                            if mob:GetAttribute("IsNpc") then
                                local name = mob.Name:lower()
                                if name:sub(1,5) == "golem" then
                                    local mhrp = mob:FindFirstChild("HumanoidRootPart")
                                    local mh = mob:FindFirstChildOfClass("Humanoid")
                                    if mhrp and mh and mh.Health > 0 then
                                        local dist = (hrp.Position - mhrp.Position).Magnitude
                                        if dist < nearestDistance then
                                            nearestDistance = dist
                                            foundGolem = mob
                                        end
                                    end
                                end
                            end
                        end

                        if not foundGolem then
                            local PartyService = game:GetService("ReplicatedStorage").Shared.Packages.Knit.Services.PartyService.RF
                            local createPart = workspace.Proximity.CreateParty
                            local lock = workspace.Proximity.CreateParty.Golem.Timer.Lock

                            if lock and lock.Visible then
                                getgenv().Golem = false
                                task.wait(tonumber(getgenv().Settings.Automatic.AutoFarm.CheckGolem))
                                continue
                            end

                            getgenv().Golem = true

                            if ActiveTween then
                                ActiveTween:Cancel()
                                ActiveTween = nil
                            end

                            TweenFarm(createPart.CFrame, tweenspeed).Completed:Wait()

                            local ok, result = pcall(function()
                                return PartyService.CreateParty:InvokeServer("Golem")
                            end)

                            if not (ok and result == true) then
                                getgenv().Golem = false
                                task.wait(tonumber(getgenv().Settings.Automatic.AutoFarm.CheckGolem))
                                continue
                            end
                            
                            PartyService.Activate:InvokeServer()
                            task.wait(5)
                        end

                        if not foundGolem then continue end

                        local mhrp = foundGolem:FindFirstChild("HumanoidRootPart")
                        local mh = foundGolem:FindFirstChildOfClass("Humanoid")
                        if not (mhrp and mh and mh.Health > 0) then continue end

                        if (hrp.Position - mhrp.Position).Magnitude > 55 then
                            TweenFarm(CFrame.new(mhrp.Position + Vector3.new(0,7,0)), tweenspeed).Completed:Wait()
                        end

                        humanoid.PlatformStand = true

                        local golemAttackIds = {}
                        local success, golemAnimFolder = pcall(function()
                            return game:GetService("ReplicatedStorage").Assets.Animations.Golem
                        end)
                        
                        if success and golemAnimFolder then
                            for _, anim in ipairs(golemAnimFolder:GetChildren()) do
                                if anim:IsA("Animation") then
                                    table.insert(golemAttackIds, anim.AnimationId)
                                end
                            end
                        end

                        local golemHumanoid = foundGolem:FindFirstChildOfClass("Humanoid")
                        local golemAnimator = golemHumanoid and golemHumanoid:FindFirstChildOfClass("Animator")
                        local animConnection
                        
                        if golemAnimator then
                            animConnection = golemAnimator.AnimationPlayed:Connect(function(animTrack)
                                local animId = animTrack.Animation.AnimationId
                                
                                for _, attackId in ipairs(golemAttackIds) do
                                    if animId == attackId then
                                        if hrp and mhrp then
                                            hrp.CFrame = CFrame.new(mhrp.Position + Vector3.new(0, 25, 0))
                                        end
                                        break
                                    end
                                end
                            end)
                        end

                        while getgenv().Settings.Automatic.AutoFarm.AutoFarmGolem do
                            task.wait()
                            char = player.Character
                            humanoid = char and char:FindFirstChildOfClass("Humanoid")
                            hrp = char and char:FindFirstChild("HumanoidRootPart")
                            mhrp = foundGolem and foundGolem:FindFirstChild("HumanoidRootPart")
                            mh = foundGolem and foundGolem:FindFirstChildOfClass("Humanoid")
                            
                            if not (char and humanoid and hrp and mhrp and mh) or humanoid.Health <= 0 then 
                                getgenv().Golem = false
                                humanoid.PlatformStand = false
                                StopNoClip()
                                if animConnection then animConnection:Disconnect() end
                                break 
                            end
                            
                            if mh.Health <= 0 then break end
                            if getgenv().Selling or getgenv().BuyPoint or getgenv().UsePoint then break end

                            for _, v in ipairs(player.Backpack:GetChildren()) do
                                if v.Name:lower():find("weapon") then
                                    humanoid:EquipTool(v)
                                end
                            end

                            hrp.CFrame = CFrame.lookAt(mhrp.Position + Vector3.new(0,7,0), mhrp.Position)
                            game:GetService("ReplicatedStorage").Shared.Packages.Knit.Services.ToolService.RF.ToolActivated:InvokeServer("Weapon")
                        end

                        if animConnection then animConnection:Disconnect() end

                        humanoid.PlatformStand = false
                        getgenv().Golem = false

                        if mhrp then
                            hrp.CFrame = mhrp.CFrame * CFrame.new(0, exit, 0)
                        end
                    end

                    StopNoClip()
                    getgenv().Golem = false
                end)
            end)
        else
            if not getgenv().AutoFarm.AutoFarmMob or not getgenv().AutoFarm.AutoFarmRock then
                StopNoClip()
            end
            getgenv().Golem = false
            local char = game.Players.LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.Anchored = false
            end
        end
    end
})

---- ============ Priority ============ ----

local Tab = Section:Tab({
    Title = "tr:Priority",
    Icon = "flag",
    Opened = false,
})

local PriorityRock = Tab:Section({ Title = "tr:PriorityTab", Icon = "pickaxe", Opened = true})

for i, RockName in pairs(RocksList) do
    if getgenv().Settings.Automatic.Priority.PriorityRock[RockName] == nil then
        getgenv().Settings.Automatic.Priority.PriorityRock[RockName] = "Normal"
    end

    PriorityRock:Dropdown({
        Title = RockName,
        Value = getgenv().Settings.Automatic.Priority.PriorityRock[RockName],
        Values = {"Lower", "Normal", "High", "Very High"},
        Callback = function(Value)
            if not getgenv().Settings.Automatic.Priority.PriorityRock then
                getgenv().Settings.Automatic.Priority.PriorityRock = {}
            end
            getgenv().Settings.Automatic.Priority.PriorityRock[RockName] = Value
            pcall(SaveSetting)
        end
    })
end

local PriorityMobs = Tab:Section({ Title = "tr:PriorityTab1", Icon = "skull"})

for i, MobsName in pairs(MonsList) do
    if getgenv().Settings.Automatic.Priority.PriorityMobs[MobsName] == nil then
        getgenv().Settings.Automatic.Priority.PriorityMobs[MobsName] = "Normal"
    end
    PriorityMobs:Dropdown({
        Title = MobsName,
        Value = getgenv().Settings.Automatic.Priority.PriorityMobs[MobsName],
        Values = {"Lower", "Normal", "High", "Very High"},
        Callback = function(Value)
            if not getgenv().Settings.Automatic.Priority.PriorityMobs then
                getgenv().Settings.Automatic.Priority.PriorityMobs = {}
            end
            getgenv().Settings.Automatic.Priority.PriorityMobs[MobsName] = Value
            pcall(SaveSetting)
        end
    })
end

-- ============ Auto Sell ============ --

local Tab = Section:Tab({
    Title = "tr:AutoSell",
    Icon = "dollar-sign",
    Opened = true,
})

local ForgeTabs = Tab:Section({ Title = "tr:AutoSellTab", Icon = "dollar-sign"})

local SelectOres = {}
local SelectMaterials = {}
local SelectRunes = {}
local NPCSellPOS = CFrame.new(-109, 38, -47)

for i,v in pairs(game:GetService("ReplicatedStorage").Shared.Data.Ore:GetDescendants()) do
    if v:IsA("ModuleScript") then
        table.insert(SelectOres, v.Name)
    end
end

for _, module in game:GetService("ReplicatedStorage").Shared.Data.Runes.Runes:GetDescendants() do
    if module:IsA("ModuleScript") then
        local success, runeData = pcall(function()
            return require(module)
        end)
        
        if success and runeData then
            table.insert(SelectRunes, runeData.Name)
        end
    end
end

for i,v in ipairs(require(game:GetService("ReplicatedStorage").Shared.Data.Materials).Items) do
    table.insert(SelectMaterials, v.Name)
end

local SelectOresDropdown = Tab:Dropdown({
    Title = "tr:SelectOresToSell",
    Multi = true,
    AllowNone = false,
    Values = SelectOres,
    Value = getgenv().Settings.Automatic.AutoSell.SelectOres,
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoSell.SelectOres = Value
        SaveSetting()
    end
})

local SelectMaterialsDropdown = Tab:Dropdown({
    Title = "tr:SelectMaterialsToSell",
    Multi = true,
    AllowNone = false,
    Values = SelectMaterials,
    Value = getgenv().Settings.Automatic.AutoSell.SelectMaterials,
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoSell.SelectMaterials = Value
        SaveSetting()
    end
})

local SelectRunesDropdown = Tab:Dropdown({
    Title = "tr:SelectRunesToSell",
    Multi = true,
    AllowNone = false,
    Values = SelectRunes,
    Value = getgenv().Settings.Automatic.AutoSell.SelectRunes,
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoSell.SelectRunes = Value
        SaveSetting()
    end
})

local TimeInterval = Tab:Slider({
    Title = "tr:AutoSellInterval",
    Value = {
        Min = 30,
        Max = 600,
        Default = getgenv().Settings.Automatic.AutoSell.TimeInterval
    },
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoSell.TimeInterval = Value
        SaveSetting()
    end
})

local SellInventoryFull
local Knit = require(game:GetService("ReplicatedStorage").Shared.Packages.Knit)
local PC = Knit.GetController("PlayerController")
repeat task.wait() until PC.Replica

local AutoSell = Tab:Toggle({
    Title = "tr:AutoSellByTime",
    Value = getgenv().Settings.Automatic.AutoSell.AutoSell,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoSell.AutoSell = Value
        SaveSetting()

        if Value then
            SellInventoryFull:Lock()
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.Automatic.AutoSell.AutoSell do task.wait(getgenv().Settings.Automatic.AutoSell.TimeInterval)
                        
                        local tonpc = game.PlaceId == World2 and 20 or 20
                        local tweenspeed = game.PlaceId == World2 and 25 or 35
                        local undergroundDepth = game.PlaceId == World2 and -10 or -20

                        local success = pcall(function()
                            getgenv().Selling = true
                                
                            if not getgenv().Settings.Automatic.AutoSell.AutoSell then
                                return
                            end
                            
                            -- ขาย Materials
                            if #getgenv().Settings.Automatic.AutoSell.SelectMaterials > 0 then
                                for _, v in ipairs(getgenv().Settings.Automatic.AutoSell.SelectMaterials) do
                                    for _, item in pairs(PC.Replica.Data.Inventory.Misc) do
                                        if item.Name == v and (item.Amount or item.Quantity or 0) > 0 then
                                            game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("DialogueService"):WaitForChild("RF"):WaitForChild("RunCommand"):InvokeServer("SellConfirm", {Basket = {[v] = item.Amount or item.Quantity}})
                                            task.wait(0.05)
                                        end
                                    end
                                end
                                task.wait(1)
                            end

                            if #getgenv().Settings.Automatic.AutoSell.SelectOres > 0 then
                                for i, v in ipairs(getgenv().Settings.Automatic.AutoSell.SelectOres) do
                                    local quantity = PC.Replica.Data.Inventory[v] or 0
                                    if quantity > 0 then
                                        game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Knit")
                                            :WaitForChild("Services"):WaitForChild("DialogueService"):WaitForChild("RF")
                                            :WaitForChild("RunCommand"):InvokeServer("SellConfirm", {Basket = {[v] = quantity}})
                                        task.wait(0.05)
                                    end
                                end
                                task.wait(1)
                            end

                            if #getgenv().Settings.Automatic.AutoSell.SelectRunes > 0 then
                                for i, v in ipairs(getgenv().Settings.Automatic.AutoSell.SelectRunes) do
                                    local quantity = PC.Replica.Data.Inventory[v] or 0
                                    if quantity > 0 then
                                        game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Knit")
                                            :WaitForChild("Services"):WaitForChild("DialogueService"):WaitForChild("RF")
                                            :WaitForChild("RunCommand"):InvokeServer("SellConfirm", {Basket = {[v] = quantity}})
                                        task.wait(0.05)
                                    end
                                end
                            end
                        end)
                        
                        getgenv().Selling = false
                        
                        if not success then
                            warn("Auto sell error")
                        end
                    end
                end)
            end)
        else
            SellInventoryFull:Unlock()
            getgenv().Selling = false
        end
    end
})

SellInventoryFull = Tab:Toggle({
    Title = "tr:SellWhenInventoryFull",
    Value = getgenv().Settings.Automatic.AutoSell.SellInventoryFull,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoSell.SellInventoryFull = Value
        SaveSetting()

        if Value then
            AutoSell:Lock()
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.Automatic.AutoSell.SellInventoryFull do task.wait(1)
                        local stashCapacityText = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("Menu")
                            .Frame.Frame.Menus.Stash:WaitForChild("Capacity"):WaitForChild("Text").Text
                        
                        local isInventoryFull = string.find(stashCapacityText, "rgb%(255,0,0%)")
                        
                        if isInventoryFull then
                            local success = pcall(function()  
                                if #getgenv().Settings.Automatic.AutoSell.SelectMaterials > 0 then
                                    for _, v in ipairs(getgenv().Settings.Automatic.AutoSell.SelectMaterials) do
                                        for _, item in pairs(PC.Replica.Data.Inventory.Misc) do
                                            if item.Name == v and (item.Amount or item.Quantity or 0) > 0 then
                                                game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("DialogueService"):WaitForChild("RF"):WaitForChild("RunCommand"):InvokeServer("SellConfirm", {Basket = {[v] = item.Amount or item.Quantity}})
                                                task.wait(0.05)
                                            end
                                        end
                                    end
                                    task.wait(1)
                                end

                                if #getgenv().Settings.Automatic.AutoSell.SelectOres > 0 then
                                    for i, v in ipairs(getgenv().Settings.Automatic.AutoSell.SelectOres) do
                                        local quantity = PC.Replica.Data.Inventory[v] or 0
                                        if quantity > 0 then
                                            game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Knit")
                                                :WaitForChild("Services"):WaitForChild("DialogueService"):WaitForChild("RF")
                                                :WaitForChild("RunCommand"):InvokeServer("SellConfirm", {Basket = {[v] = quantity}})
                                            task.wait(0.05)
                                        end
                                    end
                                    task.wait(1)
                                end

                                if #getgenv().Settings.Automatic.AutoSell.SelectRunes > 0 then
                                    for i, v in ipairs(getgenv().Settings.Automatic.AutoSell.SelectRunes) do
                                        local quantity = PC.Replica.Data.Inventory[v] or 0
                                        if quantity > 0 then
                                            game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Knit")
                                                :WaitForChild("Services"):WaitForChild("DialogueService"):WaitForChild("RF")
                                                :WaitForChild("RunCommand"):InvokeServer("SellConfirm", {Basket = {[v] = quantity}})
                                            task.wait(0.05)
                                        end
                                    end
                                end
                            end)
                        end
                    end
                end)
            end)
        else
            getgenv().Selling = false
            AutoSell:Unlock()
        end
    end
})

---- ============ Auto Forge ============ ----

local Tab = Section:Tab({
    Title = "tr:AutoForge",
    Icon = "hammer",
    Opened = true,
})

local ForgeTabs = Tab:Section({ Title = "tr:AutoForgeTab", Icon = "anvil"})

local StatsForge = Tab:Paragraph({
    Title = "tr:StatsForge",
    Desc = "Idle"
})

local function UpdateStatus(text)
    task.spawn(function()
        pcall(function()
            StatsForge:SetDesc(text)
        end)
    end)
end

local AutoForge = Tab:Toggle({
    Title = "tr:AutoForge",
    Value = getgenv().Settings.Automatic.AutoForge.AutoForge,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoForge.AutoForge = Value
        SaveSetting()

        if Value then
            UpdateStatus("Starting...")
            getgenv().Forge = false

            local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
            local ForgeUI = PlayerGui:WaitForChild("Forge")

            function checkPerfectZone(frame)
                if not frame:FindFirstChild("Border") then return false, 0 end
                local c = frame.Border.ImageColor3
                
                local isPerfect = (c.G > 0.8 and c.R < 0.3 and c.B < 0.3)
                
                local qualityScore = 0
                if isPerfect then
                    qualityScore = 1.0
                elseif c.G > c.R and c.G > c.B then
                    qualityScore = 0.7 + (c.G - 0.5) * 0.4
                elseif c.R > 0.5 and c.G > 0.3 then
                    qualityScore = 0.4 + (c.G / c.R) * 0.3
                else
                    qualityScore = math.max(0, 0.4 - c.R * 0.4)
                end
                
                return isPerfect, qualityScore
            end

            function getZonePosition(frame)
                if not frame:FindFirstChild("Border") then return 0 end
                
                local pos = frame.Position.Y.Scale
                local centerOffset = math.abs(pos - 0.5)
                
                return centerOffset
            end

            _G.PerfectDelay = 0.1
            _G.MinCenterThreshold = 0.1
            _G.ForgeStatus = "Idle"
            _G.HammerStats = {
                totalHits = 0,
                perfectHits = 0,
                goodHits = 0,
                missedHits = 0
            }

            task.spawn(function()
                while getgenv().Settings.Automatic.AutoForge.AutoForge do 
                    task.wait()
                    
                    local isWorking = false

                    local MeltUI = ForgeUI:FindFirstChild("MeltMinigame")
                    if MeltUI and MeltUI.Visible then
                        isWorking = true
                        if _G.ForgeStatus ~= "Melting" then
                            _G.ForgeStatus = "Melting"
                            UpdateStatus("Auto Melting")
                        end
                    end

                    local PourUI = ForgeUI:FindFirstChild("PourMinigame")
                    if PourUI and PourUI.Visible then
                        isWorking = true
                        if _G.ForgeStatus ~= "Pouring" then
                            _G.ForgeStatus = "Pouring"
                            UpdateStatus("Auto Pouring")
                        end
                    end
                    
                    local hasMold = false
                    for _, mold in pairs(workspace.Debris:GetChildren()) do
                        if mold.Name == "Mold" and mold:FindFirstChild("ClickDetector") then
                            if not mold:GetAttribute("IsDestroyed") then
                                hasMold = true
                                isWorking = true
                                if _G.ForgeStatus ~= "Breaking Mold" then
                                    _G.ForgeStatus = "Breaking Mold"
                                    UpdateStatus("Breaking Mold")
                                end
                                for i = 1, 3 do
                                    fireclickdetector(mold.ClickDetector)
                                    task.wait(0.05)
                                end
                                task.wait(0.3)
                            end
                        end
                    end
                    
                    local isHammering = false
                    for i,v in pairs(PlayerGui.Forge:GetChildren()) do
                        if v.Name == "HammerMinigame" and v:IsA("Frame") and v.Visible then
                            isHammering = true
                            isWorking = true
                            local Frame1 = v:FindFirstChild("Frame")
                            if Frame1 then
                                local Frame2 = Frame1:FindFirstChild("Frame")
                                if Frame2 then
                                    local isPerfect, qualityScore = checkPerfectZone(Frame2)
                                    local centerOffset = getZonePosition(Frame2)
                                    
                                    if isPerfect and centerOffset < _G.MinCenterThreshold then
                                        if _G.ForgeStatus ~= "Hammering" then
                                            _G.ForgeStatus = "Hammering"
                                            UpdateStatus(string.format("Perfect Hammering (%.0f%% Quality)", qualityScore * 100))
                                        end
                                        
                                        task.wait(_G.PerfectDelay)
                                        
                                        pcall(function()
                                            for _, connection in pairs(getconnections(Frame1.MouseButton1Down)) do
                                                connection:Fire()
                                            end
                                            Frame1:Destroy()
                                        end)
                                        
                                        _G.HammerStats.totalHits = _G.HammerStats.totalHits + 1
                                        _G.HammerStats.perfectHits = _G.HammerStats.perfectHits + 1
                                        
                                        local avgQuality = (_G.HammerStats.perfectHits / _G.HammerStats.totalHits) * 100
                                        UpdateStatus(string.format("Hammering - Avg: %.1f%% (%d/%d Perfect)", 
                                            avgQuality, 
                                            _G.HammerStats.perfectHits, 
                                            _G.HammerStats.totalHits))
                                    elseif isPerfect then
                                        UpdateStatus(string.format("Waiting for center (offset: %.3f)", centerOffset))
                                    end
                                end
                            end
                        end
                    end
                    
                    -- อัพเดท getgenv().Forge ตามสถานะการทำงาน
                    if isWorking then
                        getgenv().Forge = true
                    else
                        getgenv().Forge = false
                    end
                    
                    if not hasMold and not isHammering and not (MeltUI and MeltUI.Visible) and not (PourUI and PourUI.Visible) then
                        if _G.ForgeStatus ~= "Ready" and _G.ForgeStatus ~= "Idle" then
                            _G.ForgeStatus = "Ready"
                            
                            if _G.HammerStats.totalHits > 0 then
                                UpdateStatus("Forge Complete")
                                
                                task.wait(3)
                                _G.HammerStats = {
                                    totalHits = 0,
                                    perfectHits = 0,
                                    goodHits = 0,
                                    missedHits = 0
                                }
                            else
                                UpdateStatus("Waiting for Forge")
                            end
                        end
                    end
                end
                
                -- เมื่อหยุดการทำงาน ให้ตั้งค่าเป็น false
                getgenv().Forge = false
            end)

            task.spawn(function()
                local ForgeController
                local attempts = 0
                
                repeat
                    task.wait(1)
                    attempts = attempts + 1
                    
                    local success, result = pcall(function()
                        return require(game:GetService("ReplicatedStorage")
                            :WaitForChild("Controllers")
                            :WaitForChild("ForgeController"))
                    end)
                    
                    if success then
                        ForgeController = result
                    end
                until ForgeController or attempts > 30
                
                if not ForgeController then
                    UpdateStatus("Failed to load ForgeController")
                    return
                end
                
                while not ForgeController.Minigames do
                    task.wait(1)
                end

                local OriginalMeltStart = ForgeController.Minigames.MeltMinigame.Start
                local OriginalPourStart = ForgeController.Minigames.PourMinigame.Start

                if ForgeController.Minigames.MeltMinigame then
                    ForgeController.Minigames.MeltMinigame.Start = function(self, minigameData)
                        if not getgenv().Settings.Automatic.AutoForge.AutoForge then
                            return OriginalMeltStart(self, minigameData)
                        end
                        
                        pcall(function()
                            ForgeUI:WaitForChild("MeltMinigame").Visible = false
                        end)
                        
                        local startTime = minigameData.StartTime
                        local endTime = minigameData.EndTime or (startTime + 10)
                        local perfectTime = startTime + ((endTime - startTime) * 0.3)
                        
                        return perfectTime, true
                    end
                end

                if ForgeController.Minigames.PourMinigame then
                    ForgeController.Minigames.PourMinigame.Start = function(self, minigameData)
                        if not getgenv().Settings.Automatic.AutoForge.AutoForge then
                            return OriginalPourStart(self, minigameData)
                        end
                        
                        pcall(function()
                            ForgeUI:WaitForChild("PourMinigame").Visible = false
                        end)
                        
                        local startTime = minigameData.StartTime
                        local endTime = minigameData.EndTime or (startTime + 10)
                        local perfectTime = startTime + ((endTime - startTime) * 0.3)
                        
                        return perfectTime, true
                    end
                end
            end)
        else
            getgenv().Settings.Automatic.AutoForge.AutoForge = false
            getgenv().Forge = false -- ตั้งค่าเป็น false เมื่อปิดระบบ
            _G.ForgeStatus = "Stopped"
            UpdateStatus("Stopped")
        end
    end
})

local OpenForgeUI = Tab:Button({
    Title = "tr:OpenForgeUI",
    Callback = function()
        game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("ProximityService"):WaitForChild("RF"):WaitForChild("Forge"):InvokeServer(unpack({workspace:WaitForChild("Proximity"):WaitForChild("Forge")}))
    end
})

-- ============ Points ============ --

local Tab = Section:Tab({
    Title = "tr:AutoPoints",
    Icon = "sparkles",
    Opened = true,
})

local PointsTab = Tab:Section({ Title = "tr:PointsTab", Icon = "wand"})

local Points = {}

for i,v in pairs(game:GetService("ReplicatedStorage").Assets.Extras.Potion:GetChildren()) do
    if v:IsA("Model") then
        if v.Name ~= "PotionLVL2" and v.Name ~= "HealthPotion12" then
            table.insert(Points, v.Name)
        end
    end
end

local SelectPoints = Tab:Dropdown({
    Title = "tr:SelectPoints",
    Multi = true,
    AllowNone = true,
    Values = Points,
    Value = getgenv().Settings.Automatic.Points.SelectPoints,
    Callback = function(Value)
        getgenv().Settings.Automatic.Points.SelectPoints = Value
        SaveSetting()
    end
})

local AutoUsePoints
local AutoBuyPoints

AutoUsePoints = Tab:Toggle({
    Title = "tr:AutoUsePoints",
    Value = getgenv().Settings.Automatic.Points.AutoUsePoints,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Automatic.Points.AutoUsePoints = Value
        SaveSetting()

        if Value then
            getgenv().UsePoint = false
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.Automatic.Points.AutoUsePoints do task.wait(1)
                        local perksFolder = game:GetService("Players").LocalPlayer.PlayerGui.Hotbar.Perks
                        
                        for _, pointName in ipairs(getgenv().Settings.Automatic.Points.SelectPoints) do
                            if not getgenv().Settings.Automatic.Points.AutoUsePoints then break end
                            
                            local hasEffect = false
                            
                            if not pointName:find("HealthPotion") then
                                for _, perk in pairs(perksFolder:GetChildren()) do
                                    if perk.Name == pointName or perk.Name:find(pointName) then
                                        hasEffect = true
                                        break
                                    end
                                end
                            end
                            
                            if not hasEffect then
                                local hasPotion = false
                                for _, item in pairs(PC.Replica.Data.Inventory.Misc) do
                                    if item.Name == pointName and (item.Amount or item.Quantity or 0) > 0 then
                                        hasPotion = true
                                        getgenv().UsePoint = true
                                        break
                                    end
                                end
                                
                                if hasPotion then
                                    game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("ToolService"):WaitForChild("RF"):WaitForChild("ToolActivated"):InvokeServer(pointName)
                                    task.wait(0.5)
                                    getgenv().UsePoint = false
                                end
                            end
                        end
                    end
                end)
            end)
        else
            getgenv().UsePoint = false
        end
    end
})

AutoBuyPoints = Tab:Toggle({
    Title = "tr:AutoBuyPoints",
    Value = getgenv().Settings.Automatic.Points.AutoBuyPoints,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Automatic.Points.AutoBuyPoints = Value
        SaveSetting()

        if Value then
            getgenv().BuyPoint = false
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.Automatic.Points.AutoBuyPoints do task.wait()
                        local tweenspeed = game.PlaceId == World2 and 25 or 35
                        local undergroundDepth = game.PlaceId == World2 and -10 or -15
                        
                        local itemsToBuy = {}
                        
                        for _, pointName in ipairs(getgenv().Settings.Automatic.Points.SelectPoints) do
                            if not getgenv().Settings.Automatic.Points.AutoBuyPoints then break end
                            
                            local hasPotion = false
                            for _, item in pairs(PC.Replica.Data.Inventory.Misc) do
                                if item.Name == pointName and (item.Amount or item.Quantity or 0) > 0 then
                                    hasPotion = true
                                    break
                                end
                            end
                            
                            if not hasPotion then
                                local targetAmount = getgenv().Settings.Automatic.Points.BuyAmount[pointName]
                                table.insert(itemsToBuy, {
                                    Name = pointName,
                                    Amount = tonumber(targetAmount)
                                })
                            end
                        end
                        
                        if #itemsToBuy > 0 then
                            local success = pcall(function()
                                getgenv().BuyPoint = true
                                
                                -- เปิด NoClip ก่อน Tween
                                StartNoClip()
                                
                                local npcMaria = workspace.Proximity:FindFirstChild("Maria")
                                if not npcMaria then
                                    StopNoClip()
                                    return
                                end
                                
                                local npcCFrame = npcMaria:GetPivot()
                                local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart

                                -- สร้าง thread แยกสำหรับมอง NPC ตลอดเวลา
                                local lookAtActive = true
                                local lookAtThread = task.spawn(function()
                                    while lookAtActive and getgenv().BuyPoint do
                                        pcall(function()
                                            local currentNpc = workspace.Proximity:FindFirstChild("Maria")
                                            if currentNpc and hrp then
                                                local currentNpcPos = currentNpc:GetPivot().Position
                                                local lookAt = CFrame.lookAt(hrp.Position, Vector3.new(currentNpcPos.X, hrp.Position.Y, currentNpcPos.Z))
                                                hrp.CFrame = CFrame.new(hrp.Position) * (lookAt - lookAt.Position)
                                            end
                                        end)
                                        task.wait(0.1)
                                    end
                                end)

                                -- Tween ไปที่ตำแหน่ง
                                local targetPosition = npcCFrame * CFrame.new(0,0,-5)
                                TweenFarm(targetPosition, tweenspeed).Completed:Wait()
                                
                                task.wait(0.5)
                                
                                if not getgenv().Settings.Automatic.Points.AutoBuyPoints then 
                                    lookAtActive = false
                                    StopNoClip()
                                    return 
                                end

                                for _, item in ipairs(itemsToBuy) do
                                    if not getgenv().Settings.Automatic.Points.AutoBuyPoints then break end
                                    
                                    game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("ProximityService"):WaitForChild("RF"):WaitForChild("Purchase"):InvokeServer(item.Name, item.Amount)
                                    task.wait(0.1)
                                end
                                
                                if getgenv().Settings.Automatic.AutoFarm.AutoFarmRock == false and getgenv().Settings.Automatic.AutoFarm.AutoFarmMob == false then
                                    StopNoClip()
                                end

                                lookAtActive = false
                                task.wait(0.1)
                                
                                table.clear(itemsToBuy)

                                task.wait(0.5)
                            end)
                            
                            getgenv().BuyPoint = false
                        end
                    end
                end)
            end)
        else
            getgenv().BuyPoint = false
        end
    end
})

local PointsTab1 = Tab:Section({ Title = "tr:PointsTab1", Icon = "sparkles"})

if not getgenv().Settings.Automatic.Points.BuyAmount then
    getgenv().Settings.Automatic.Points.BuyAmount = {}
end

for i, pointName in pairs(Points) do
    if getgenv().Settings.Automatic.Points.BuyAmount[pointName] == nil then
        getgenv().Settings.Automatic.Points.BuyAmount[pointName] = 1
    end
    
    local currentValue = tonumber(getgenv().Settings.Automatic.Points.BuyAmount[pointName]) or 1
    
    Tab:Slider({
        Title = pointName,
        Value = {
            Min = 1,
            Max = 100,
            Default = currentValue
        },
        Callback = function(Value)
            local numValue = tonumber(Value) or 1
            if not getgenv().Settings.Automatic.Points.BuyAmount then
                getgenv().Settings.Automatic.Points.BuyAmount = {}
            end
            getgenv().Settings.Automatic.Points.BuyAmount[pointName] = numValue
            pcall(SaveSetting)
        end
    })
end

---- ============ Utility ============ ----

local Section = Window:Section({
    Title = "tr:Utility",
    Icon = "folder-heart",
    Opened = false,
})

-- ============ Teleport ============ --

local Tab = Section:Tab({
    Title = "tr:TP",
    Icon = "door-open",
    Opened = true,
})

local TPTable = {}
getgenv().IsTeleport = false

for i,v in pairs(workspace.Proximity:GetChildren()) do
   table.insert(TPTable, v.Name)
end

local Teleport = Tab:Section({ Title = "tr:TelePort", Icon = "door-open"})
local SelectTp

local SelectNPC = Tab:Dropdown({
    Title = "tr:NPCTP",
    Value = nil,
    Values = TPTable,
    AllowNone = true,
    Multi = false,
    Callback = function(Value)
        SelectTp = Value
    end
})

local ButtonTP = Tab:Button({
    Title = "tr:TelePort",
    Callback = function()
        if not SelectTp then return end

        local prox = workspace.Proximity:FindFirstChild(SelectTp)
        if not prox then return end

        local tweenspeed = game.PlaceId == World2 and 25 or 35
        StartNoClip()
        getgenv().IsTeleport = true
        TweenFarm(prox:GetPivot() * CFrame.new(0,20,0), tweenspeed).Completed:Wait()
        getgenv().IsTeleport = false
        StopNoClip()
    end
})

local Tab = Section:Tab({
    Title = "tr:Misc",
    Icon = "info",
    Opened = true,
})

local ButtonTP = Tab:Button({
    Title = "tr:RedeemAllCodes",
    Callback = function()
        local Codes = {
            "RAVEN",
            "HAPPYNEWYEAR",
            "FORGE2M",
            "SORRYFORBUGS",
            "SORRYFORDELAY",
            "XMAS!"
        }

        for i,v in pairs(Codes) do
            game:GetService("ReplicatedStorage").Shared.Packages.Knit.Services.CodeService.RF.RedeemCode:InvokeServer(v)
        end
    end
})

---- ============ Configuration ============ ----

Window:Divider()

local Tab = Window:Tab({
    Title = "Configuration",
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
    Title = "Script | Loader",
    Content = "Script Loader Successfully",
    Icon = VenuzIcon,
    Duration = 5,
})

ScreenGui:Destroy()

RunService.RenderStepped:Connect(function()
    if not (getgenv().Settings.Automatic.AutoFarm.AutoFarmRock or getgenv().Settings.Automatic.AutoFarm.AutoFarmMob or getgenv().IsTeleport or getgenv().Settings.Automatic.Points.AutoBuyPoints) then
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
        footer.Size = Vector3.new(2, 0.2, 1.5)
        footer.Transparency = 1
        footer.Anchored = true
        footer.CanCollide = false
    end

    if PC.Replica.Data.Race == "Dwarf" then
        footer.CFrame = hrp.CFrame * CFrame.new(0, -2.5, 0)
    else
        footer.CFrame = hrp.CFrame * CFrame.new(0, -3.1, 0)
    end

    local cam = workspace.CurrentCamera
    if getgenv().Settings.Automatic.AutoFarm.AutoFarmRock or getgenv().Settings.Automatic.AutoFarm.AutoFarmMob or getgenv().Settings.Automatic.AutoFarm.AutoFarmGolem then
        cam.CameraType = Enum.CameraType.Custom
    end
end)