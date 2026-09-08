pcall(function()
    if game:GetService("CoreGui"):FindFirstChild("Folder"):FindFirstChild("WindUI") then
        return
    end
end)

getgenv().ConfigurationTable = {}
getgenv().Settings = {}

local FolderConfiguration = "Venuz Hub"
local FolderSettings = "Venuz Hub/Violence District"
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

local filenameConfiguration = FolderConfiguration .. "/" .. "Setting" .. ".json"
local filenameSetting = FolderSettings .. "/" .. "Violence_District".. LocalPlayer.Name .. ".json"

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
        ["AutoSkillCheck"] = false,
        ["ShowAllHitbox"] = false,
        ["HitboxSize"] = 1,
        ["ChangeHitbox"] = false,
        ["GrabGift"] = false
    },

    ["ESP"] = {
        ["Survivor"] = false,
        ["Killer"] = false,
        ["Generator"] = false,
        ["Pallets"] = false,
        ["Name"] = false,
        ["Distance"] = false,
        ["slelecrosshair"] = nil,
        ["crosshaircolor"] = {255, 255, 255},
        ["crosshairsize"] = 15,
        ["crosshairthickness"] = 2,
        ["crosshairtransparency"] = 0.5,
        ["crsshairoutline"] = true,
        ["crosshairopacity"] = 1,
        ["crosshairdynamic"] = true,
        ["crosshairdynamicamount"] = 5,
        ["crosshairenabled"] = true,
    },

    ["Lighting"] = {
        "FullBright",
    },

    ["ModifyCharacter"] = {
        ["SpeedBoot"] = false,
        ["SpeedBootValue"] = 1,
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

--------------------------- CheckingRole ---------------------------

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
    DefaultLanguage = getgenv().ConfigurationTable.Language,
    Translations = {
        ["Thai"] = {
            -- Tabs --
            ["Main"] = "หน้าหลัก",
            ["Visual"] = "ภาพและแสง",
            ["Modify"] = "ปรับแต่ง",
            ["Configuration"] = "ตั้งค่า",

            -- Main --
            ["MainTabs1"] = "↪ หน้าหลัก",
            ["MainTabs2"] = "↪ ระยะการตี",
            ["MainTabs3"] = "↪ อีเว้น",
            ["AutoSkillCheck"] = "ตรวจเช็กสกิลอัตโนมัติ",
            ["FindGenerator"] = "ค้นหาเครื่องปั่นไฟ",
            ["ShowAllHitbox"] = "แสดง Hitbox ทั้งหมด",
            ["ChangeHitboxSize"] = "ปรับขนาด Hitbox",
            ["ChangeHitbox"] = "เปลี่ยนขนาด Hitbox",
            ["GrabGift"] = "เก็บกล่องของขวัญทั้งหมด",

            -- ESP --
            ["ESPSettings"] = "ตั้งค่ามองทะลุ (ESP)",
            ["SurvivorName"] = "แสดงชื่อผู้รอดชีวิต",
            ["SurvivorDistance"] = "แสดงระยะทางผู้รอดชีวิต",
            ["ESPMain"] = "↪ ผู้รอดชีวิต & ฆาตกร",
            ["SurvivorESP"] = "มองทะลุผู้รอดชีวิต",
            ["KillerESP"] = "มองทะลุฆาตกร",
            ["ESPMain2"] = "↪ เครื่องปั่นไฟ & พาเลต",
            ["GeneratorToggle"] = "มองทะลุเครื่องปั่นไฟ",
            ["PalletToggle"] = "มองทะลุสิ่งของที่ใช้ขวางทาง (Pallet)",
            ["ESPMain3"] = "↪ แสงสว่าง",
            ["FullBrightTab"] = "เปิดความสว่างสูงสุด",
            ["ModifyCharacter"] = "↪ ปรับแต่งตัวละคร",
            ["SpeedBoost"] = "เพิ่มความเร็ว",
            ["SpeedValue"] = "ระดับความเร็ว",
            ["SpeedValueDesc"] = "ตั้งค่าระดับความเร็ว (ค่าเริ่มต้น 1.1) - สูงสุด 2",

            -- Crosshair --
            ["EnableCrosshair"] = "เปิดใช้งานเป้าเล็ง",
            ["CrosshairColor"] = "สีเป้าเล็ง",
            ["CrosshairSize"] = "ขนาดเป้าเล็ง",
            ["CrosshairThickness"] = "ความหนาเป้าเล็ง",
            ["CrosshairTransparency"] = "ความโปร่งใสเป้าเล็ง",

            -- Configuration --
            ["themeDropdown"] = "เลือกธีม",
            ["ToggleTransparency"] = "เปิด/ปิดความโปร่งใสหน้าต่าง",
            ["AntiAFK"] = "ป้องกันการหลุด (Anti-AFK)",
            ["AutoExecutor"] = "รันอัตโนมัติ (Auto Executor)",
            ["MinimizeBind"] = "ปุ่มย่อหน้าต่าง",
            ["LanguageTab"] = "↪ ภาษา",
            ["Interface"] = "↪ ตั้งค่าอินเทอร์เฟส",
            ["CreditLanguageTab"] = "แปลโดย : Spy (spypath)",
            ["Language"] = "ภาษา",
            ["ChangedLanguage"] = "เปลี่ยนภาษา",
        },
        ["English (US)"] = {
            -- Tabs --
            ["Main"] = "Main",
            ["Visual"] = "Visual",
            ["Modify"] = "Modify",
            ["Configuration"] = "Configuration",

            -- Main --
            ["MainTabs1"] = "↪ Main",
            ["MainTabs3"] = "↪ Event",
            ["AutoSkillCheck"] = "Auto Skill Check",
            ["FindGenerator"] = "Find Generator",
            ["ShowAllHitbox"] = "Show All Hitbox",
            ["MainTabs2"] = "↪ Hitbox",
            ["ChangeHitboxSize"] = "Change Hitbox Size",
            ["ChangeHitbox"] = "Change Hitbox",
            ["GrabGift"] = "Grab All Gift",

            -- ESP --
            ["ESPSettings"] = "ESP Settings",
            ["SurvivorName"] = "Show Name",
            ["SurvivorDistance"] = "Show Distance",
            ["ESPMain"] = "Survivor & Killer",
            ["SurvivorESP"] = "Survivor ESP",
            ["KillerESP"] = "Killer ESP",
            ["ESPMain2"] = "Generator & Pallet",
            ["GeneratorToggle"] = "Generator ESP",
            ["PalletToggle"] = "Pallet ESP (Objects to block path)",
            ["ESPMain3"] = "Lighting",
            ["FullBrightTab"] = "Full Bright",
            ["ModifyCharacter"] = "Modify Character",
            ["SpeedBoost"] = "Speed Boost",
            ["SpeedValue"] = "Speed",
            ["SpeedValueDesc"] = "Set the speed level (default 1.1) - maximum 2",

            -- Crosshair --
            ["EnableCrosshair"] = "Enable Crosshair",
            ["CrosshairColor"] = "Crosshair Color",
            ["CrosshairSize"] = "Crosshair Size",
            ["CrosshairThickness"] = "Crosshair Thickness",
            ["CrosshairTransparency"] = "Crosshair Transparency",

            -- Configuration --
            ["themeDropdown"] = "Select Theme",
            ["ToggleTransparency"] = "Toggle Window Transparency",
            ["AntiAFK"] = "Anti-AFK",
            ["AutoExecutor"] = "Auto Executor",
            ["MinimizeBind"] = "Minimize Bind",
            ["LanguageTab"] = "↪ Language",
            ["Interface"] = "↪ Interface Settings",
            ["CreditLanguageTab"] = "Translated by: Spy (spypath)",
            ["Language"] = "Language",
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
    Title = "Update Latest 12/10/2025",
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

local Tabs = {
    Main = Window:Tab({ Title = "tr:Main", Icon = "house", ShowTabTitle = true}),
    Visual = Window:Tab({ Title = "tr:Visual", Icon = "eye", ShowTabTitle = true}),
    Modify = Window:Tab({ Title = "tr:Modify", Icon = "user", ShowTabTitle = true}),
    divider1 = Window:Divider(),
    Configuration = Window:Tab({ Title = "tr:Configuration", Icon = "settings", Desc = "Manage window settings and themes.", ShowTabTitle = true}),
}

-------------------------------- Main --------------------------------

local MainTabs1 = Tabs.Main:Section({ Title = "tr:Main" })

local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local AutoSkillCheck = Tabs.Main:Toggle({
    Title = "tr:AutoSkillCheck",
    Value = getgenv().Settings.Main.AutoSkillCheck,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Main.AutoSkillCheck = Value
        SaveSetting()

        task.spawn(function()
            pcall(function()
                if Value then
                    while getgenv().Settings.Main.AutoSkillCheck do 
                        task.wait()

                        local player = game.Players.LocalPlayer
                        local char = player.Character or player.CharacterAdded:Wait()
                        local root = char:WaitForChild("HumanoidRootPart")
                        local skillGui = player:WaitForChild("PlayerGui"):WaitForChild("SkillCheckPromptGui")
                        local check = skillGui:FindFirstChild("Check")

                        -- เช็ค Platform
                        local platform = player:GetAttribute("platform")
                        local isPC = (platform == "PC")
                        local isMobile = (platform == "Mobile")

                        if check and check.Visible == true then
                            local Line = check:FindFirstChild("Line")
                            local Goal = check:FindFirstChild("Goal")
                            if Line and Goal then
                                Goal.Rotation = Line.Rotation - 110
                            end

                            -- ========== Generator SkillCheck ==========
                            local closestGen, closestGenDist = nil, math.huge
                            for _, v in pairs(workspace.Map:GetDescendants()) do
                                if v:IsA("Model") and v.Name == "Generator" then
                                    local genPart = v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
                                    if genPart then
                                        local distance = (root.Position - genPart.Position).Magnitude
                                        if distance < closestGenDist then
                                            closestGenDist = distance
                                            closestGen = v
                                        end
                                    end
                                end
                            end

                            if closestGen then
                                for _, point in pairs(closestGen:GetDescendants()) do
                                    if point:IsA("BasePart") and point.Name:lower():find("generatorpoint") then
                                        if isPC then
                                            -- PC: ใช้ VirtualInputManager
                                            local VirtualInputManager = game:GetService("VirtualInputManager")
                                            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                                            task.wait()
                                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                                        elseif isMobile then
                                            -- Mobile: ใช้ Mobile UI Control
                                            local GuiService = game:GetService("GuiService")
                                            local actionButton = player.PlayerGui["Survivor-mob"].Controls.action
                                            
                                            GuiService.SelectedObject = actionButton
                                            
                                            local VirtualInputManager = game:GetService("VirtualInputManager")
                                            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                                            task.wait()
                                            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                                            GuiService.SelectedObject = nil
                                        end
                                        break
                                    end
                                end
                            end

                            -- ========== Healing SkillCheck ==========
                            local closestPlayer, closestPlayerDist = nil, math.huge
                            for _, otherPlayer in pairs(game.Players:GetPlayers()) do
                                if otherPlayer ~= player and otherPlayer.Character then
                                    local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                                    if otherRoot then
                                        local distance = (root.Position - otherRoot.Position).Magnitude
                                        if distance < closestPlayerDist and distance < 30 then
                                            closestPlayerDist = distance
                                            closestPlayer = otherPlayer
                                        end
                                    end
                                end
                            end

                            if closestPlayer and closestPlayer.Character then
                                if isPC then
                                    -- PC: ใช้ VirtualInputManager
                                    local VirtualInputManager = game:GetService("VirtualInputManager")
                                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                                    task.wait()
                                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                                elseif isMobile then
                                    -- Mobile: ใช้ Mobile UI Control
                                    local GuiService = game:GetService("GuiService")
                                    local actionButton = player.PlayerGui["Survivor-mob"].Controls.action
                                    
                                    GuiService.SelectedObject = actionButton
                                    
                                    local VirtualInputManager = game:GetService("VirtualInputManager")
                                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                                    task.wait()
                                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                                    GuiService.SelectedObject = nil
                                end
                            end
                        end
                    end
                end
            end)
        end)
    end
})

local FindGenerator = Tabs.Main:Button({
    Title = "tr:FindGenerator",
    Callback = function(Callback)
        for i,v in pairs(workspace.Map:GetDescendants()) do
            if v.Name == "Generator" then
                if v:GetAttribute("RepairProgress") ~= 100 then
                    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = v.HitBox.CFrame * CFrame.new(-5,0,0)
                end
            end
        end
    end
})

local MainTabs1 = Tabs.Main:Section({ Title = "tr:MainTabs2" })

local ShowAllHitbox = Tabs.Main:Toggle({
    Title = "tr:ShowAllHitbox",
    Value = getgenv().Settings.Main.ShowAllHitbox,
    Icon = "check",
    Callback = function(Callback)
        getgenv().Settings.Main.ShowAllHitbox = Callback
        SaveSetting()

        local function AddHighlight(character)
            if not character then return end
            local hrp = character:WaitForChild("HumanoidRootPart", 5)
            if hrp and getgenv().Settings.Main.ShowAllHitbox then
                task.wait(0.1)
                if not hrp:FindFirstChild("Hitbox_Hig") then
                    hrp.Transparency = 0.8
                    local Highlight = Instance.new("Highlight")
                    Highlight.Parent = hrp
                    Highlight.FillColor = Color3.fromRGB(255, 170, 0)
                    Highlight.FillTransparency = 0.5
                    Highlight.Name = "Hitbox_Hig"
                    Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    Highlight.OutlineTransparency = 1
                end
            end
        end

        local function RemoveHighlight(character)
            if not character then return end
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local hig = hrp:FindFirstChild("Hitbox_Hig")
                if hig then
                    hig:Destroy()
                end
                hrp.Transparency = 1
            end
        end

        if Callback then
            for i,v in pairs(game.Players:GetChildren()) do
                if v.Name ~= game.Players.LocalPlayer.Name and v.Character then
                    AddHighlight(v.Character)
                end
                
                v.CharacterAdded:Connect(function(character)
                    if getgenv().Settings.Main.ShowAllHitbox and v.Name ~= game.Players.LocalPlayer.Name then
                        AddHighlight(character)
                    end
                end)
            end

            game.Players.PlayerAdded:Connect(function(player)
                if player.Name ~= game.Players.LocalPlayer.Name then
                    player.CharacterAdded:Connect(function(character)
                        if getgenv().Settings.Main.ShowAllHitbox then
                            AddHighlight(character)
                        end
                    end)
                    
                    if player.Character then
                        AddHighlight(player.Character)
                    end
                end
            end)

            task.spawn(function()
                while getgenv().Settings.Main.ShowAllHitbox do 
                    task.wait(1)
                    for i,v in pairs(game.Players:GetChildren()) do
                        if v.Name ~= game.Players.LocalPlayer.Name and v.Character then
                            local hrp = v.Character:FindFirstChild("HumanoidRootPart")
                            if hrp and not hrp:FindFirstChild("Hitbox_Hig") then
                                AddHighlight(v.Character)
                            end
                        end
                    end
                end
            end)
        else
            for i,v in pairs(game.Players:GetChildren()) do
                if v.Character then
                    RemoveHighlight(v.Character)
                end
            end
        end
    end
})

local HitboxSize = Tabs.Main:Slider({
    Title = "tr:ChangeHitboxSize",
    Value = {
        Min = 2,
        Max = 200,
        Default = getgenv().Settings.Main.HitboxSize,
    },
    Callback = function(Callback)
        getgenv().Settings.Main.HitboxSize = Callback
        SaveSetting()
    end
})

local ChangeHitbox = Tabs.Main:Toggle({
    Title = "tr:ChangeHitbox",
    Value = getgenv().Settings.Main.ChangeHitbox,
    Icon = "check",
    Callback = function(Callback)
        getgenv().Settings.Main.ChangeHitbox = Callback
        SaveSetting()

        if Callback then
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.Main.ChangeHitbox do task.wait(1)
                        for i,v in pairs(game.Players:GetChildren()) do
                            if v.Name ~= game.Players.LocalPlayer.Name then
                                if v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                                v.Character.HumanoidRootPart.Size = Vector3.new(getgenv().Settings.Main.HitboxSize,getgenv().Settings.Main.HitboxSize,getgenv().Settings.Main.HitboxSize)
                                end
                            end
                        end
                    end
                end)
            end)
        end
    end
})

local MainTabs1 = Tabs.Main:Section({ Title = "tr:MainTabs3" })

local GrabGift = Tabs.Main:Toggle({
    Title = "tr:GrabGift",
    Value = getgenv().Settings.Main.GrabGift,
    Icon = "check",
    Callback = function(Callback)
        getgenv().Settings.Main.GrabGift = Callback
        SaveSetting()

        if Callback then
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.Main.GrabGift do task.wait(1)
                        local LocalPlayer = game.Players.LocalPlayer
                        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                        local rootpart = char:WaitForChild("HumanoidRootPart")

                        if not char then continue end
                        if not rootpart then continue end

                        if char:FindFirstChild("Gift") then
                            for i,v in pairs(workspace.Map:GetDescendants()) do
                                if v.Name:lower():find("christmastree") then
                                    rootpart.CFrame = v:GetPivot() * CFrame.new(0,5,0)
                                    repeat task.wait() until not char:FindFirstChild("Gift")
                                end
                            end
                        else
                            for i,v in pairs(workspace.Map:GetDescendants()) do
                                if v.Name:lower():find("gift") then
                                    if v.Name == "Gift" then
                                        rootpart.CFrame = v:GetPivot() * CFrame.new(0,5,0)
                                        task.wait(0.5)
                                        game:GetService("ReplicatedStorage").Remotes.Events.Christmas.gift:FireServer(v.GiftHandle)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end)
            end)
        end
    end
})

-------------------------------- ESP --------------------------------

local ESPSettings = Tabs.Visual:Section({ Title = "tr:ESPSettings" })

local SurvivorName = Tabs.Visual:Toggle({
    Title = "tr:SurvivorName",
    Value = getgenv().Settings.ESP.Name,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.ESP.Name = Value
        SaveSetting()
    end
})

local SurvivorDistance = Tabs.Visual:Toggle({
    Title = "tr:SurvivorDistance",
    Value = getgenv().Settings.ESP.Distance,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.ESP.Distance = Value
        SaveSetting()
    end
})

local ESPMain = Tabs.Visual:Section({ Title = "tr:ESPMain" })

local SurvivorESP = Tabs.Visual:Toggle({
    Title = "tr:SurvivorESP",
    Value = getgenv().Settings.ESP.Survivor,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.ESP.Survivor = Value
        SaveSetting()

        task.spawn(function()
            pcall(function()
                local localPlayer = game.Players.LocalPlayer

                while getgenv().Settings.ESP.Survivor do task.wait()

                    local localChar = localPlayer.Character
                    local localHRP = localChar and localChar:FindFirstChild("HumanoidRootPart")

                    for _, v in pairs(game.Players:GetPlayers()) do
                        if v ~= localPlayer and v.Character and v.Character:FindFirstChild("Head") and v.Team and v.Team.Name == "Survivors" then
                            local head = v.Character.Head
                            local esp = head:FindFirstChild("ESP_Venuz")
                            local highlight = v.Character:FindFirstChild("Venuz_Hightlight")

                            if not esp then
                                local BillboardGui = Instance.new("BillboardGui")
                                local TextLabel = Instance.new("TextLabel")
                                local Highlight = Instance.new("Highlight")

                                BillboardGui.Parent = head
                                BillboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                                BillboardGui.AlwaysOnTop = true
                                BillboardGui.Size = UDim2.new(0, 200, 0, 50)
                                BillboardGui.StudsOffset = Vector3.new(0, 2.5, 0)
                                BillboardGui.Name = "ESP_Venuz"

                                TextLabel.Parent = BillboardGui
                                TextLabel.BackgroundTransparency = 1
                                TextLabel.Size = UDim2.new(1, 0, 1, 0)
                                TextLabel.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
                                TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                                TextLabel.TextSize = 14
                                TextLabel.TextWrapped = true
                                TextLabel.Name = "ESP_Text"

                                Highlight.Parent = v.Character
                                Highlight.FillColor = Color3.fromRGB(85, 255, 0)
                                Highlight.FillTransparency = 0.5
                                Highlight.Name = "Venuz_Hightlight"
                                Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                                Highlight.OutlineTransparency = 1
                            end

                            if localHRP and v.Character:FindFirstChild("HumanoidRootPart") then
                                local distance = math.floor((localHRP.Position - v.Character.HumanoidRootPart.Position).Magnitude)
                                local textLabel = head.ESP_Venuz:FindFirstChild("ESP_Text")

                                if textLabel then
                                    local showName = getgenv().Settings.ESP.Name
                                    local showDist = getgenv().Settings.ESP.Distance
                                    local nameText = showName and v.Name or ""
                                    local distText = showDist and (" [ " .. distance .. "m ]") or ""

                                    textLabel.Text = nameText .. distText
                                end
                            end

                            if not getgenv().Settings.ESP.Survivor then
                                if esp then esp.Enabled = false end
                                if highlight then highlight.Enabled = false end
                            else
                                if esp then esp.Enabled = true end
                                if highlight then highlight.Enabled = true end
                            end
                        end
                    end
                end

                for _, v in pairs(game.Players:GetPlayers()) do
                    if v.Character then
                        local esp = v.Character:FindFirstChild("Head") and v.Character.Head:FindFirstChild("ESP_Venuz")
                        local highlight = v.Character:FindFirstChild("Venuz_Hightlight")
                        if esp then esp:Destroy() end
                        if highlight then highlight:Destroy() end
                    end
                end
            end)
        end)
    end
})

local KillerESP = Tabs.Visual:Toggle({
    Title = "tr:KillerESP",
    Value = getgenv().Settings.ESP.Killer,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.ESP.Killer = Value
        SaveSetting()

        task.spawn(function()
            pcall(function()
                local localPlayer = game.Players.LocalPlayer

                while getgenv().Settings.ESP.Killer do task.wait()

                    local localChar = localPlayer.Character
                    local localHRP = localChar and localChar:FindFirstChild("HumanoidRootPart")

                    for _, v in pairs(game.Players:GetPlayers()) do
                        if v ~= localPlayer and v.Character and v.Character:FindFirstChild("Head") and v.Team and v.Team.Name == "Killer" then
                            local head = v.Character.Head
                            local esp = head:FindFirstChild("ESP_Venuz")
                            local highlight = v.Character:FindFirstChild("Venuz_Hightlight")

                            if not esp then
                                local BillboardGui = Instance.new("BillboardGui")
                                local TextLabel = Instance.new("TextLabel")
                                local Highlight = Instance.new("Highlight")

                                BillboardGui.Parent = head
                                BillboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                                BillboardGui.AlwaysOnTop = true
                                BillboardGui.Size = UDim2.new(0, 200, 0, 50)
                                BillboardGui.StudsOffset = Vector3.new(0, 2.5, 0)
                                BillboardGui.Name = "ESP_Venuz"

                                TextLabel.Parent = BillboardGui
                                TextLabel.BackgroundTransparency = 1
                                TextLabel.Size = UDim2.new(1, 0, 1, 0)
                                TextLabel.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
                                TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                                TextLabel.TextSize = 14
                                TextLabel.TextWrapped = true
                                TextLabel.Name = "ESP_Text"

                                Highlight.Parent = v.Character
                                Highlight.Adornee = v.Character
                                Highlight.FillColor = Color3.fromRGB(255, 0, 0)
                                Highlight.FillTransparency = 0.5
                                Highlight.Name = "Venuz_Hightlight"
                                Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                                Highlight.OutlineTransparency = 1
                            end

                            if localHRP and v.Character:FindFirstChild("HumanoidRootPart") then
                                local distance = math.floor((localHRP.Position - v.Character.HumanoidRootPart.Position).Magnitude)
                                local textLabel = head.ESP_Venuz:FindFirstChild("ESP_Text")

                                if textLabel then
                                    local showName = getgenv().Settings.ESP.Name
                                    local showDist = getgenv().Settings.ESP.Distance
                                    local nameText = showName and v.Name or ""
                                    local distText = showDist and (" [ " .. distance .. "m ]") or ""

                                    textLabel.Text = nameText .. distText
                                end
                            end

                            if not getgenv().Settings.ESP.Killer then
                                if esp then esp.Enabled = false end
                                if highlight then highlight.Enabled = false end
                            else
                                if esp then esp.Enabled = true end
                                if highlight then highlight.Enabled = true end
                            end
                        end
                    end
                end

                for _, v in pairs(game.Players:GetPlayers()) do
                    if v.Character then
                        local esp = v.Character:FindFirstChild("Head") and v.Character.Head:FindFirstChild("ESP_Venuz")
                        local highlight = v.Character:FindFirstChild("Venuz_Hightlight")
                        if esp then esp:Destroy() end
                        if highlight then highlight:Destroy() end
                    end
                end
            end)
        end)
    end
})

local ESPMain2 = Tabs.Visual:Section({ Title = "tr:ESPMain2" })

local GeneratorToggle = Tabs.Visual:Toggle({
    Title = "tr:GeneratorToggle",
    Value = getgenv().Settings.ESP.Generator,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.ESP.Generator = Value
        SaveSetting()

        task.spawn(function()
            pcall(function()
                if Value then
                    while getgenv().Settings.ESP.Generator do task.wait(0.5)
                        for _, v in pairs(workspace.Map:GetChildren()) do
                            if v.Name == "Generator" then

                                if v:FindFirstChild("Venuz_Hightlight_Generator") then
                                    if not getgenv().Settings.ESP.Generator then
                                        v.Venuz_Hightlight_Generator.Enabled = false
                                        else
                                        v.Venuz_Hightlight_Generator.Enabled = true
                                    end
                                end

                                if v:GetAttribute("RepairProgress") == 100 then
                                    local highlight = v:FindFirstChild("Venuz_Hightlight_Generator")
                                    if highlight then
                                        highlight:Destroy()
                                    end
                                else
                                    if not v:FindFirstChild("Venuz_Hightlight_Generator") then
                                        local Highlight = Instance.new("Highlight")
                                        Highlight.Parent = v
                                        Highlight.FillColor = Color3.fromRGB(0, 150, 255)
                                        Highlight.FillTransparency = 0.5
                                        Highlight.Name = "Venuz_Hightlight_Generator"
                                        Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                                        Highlight.OutlineTransparency = 1
                                    end
                                end

                            elseif v:FindFirstChild("Generator") then
                                for _, v2 in pairs(v:GetChildren()) do
                                    if v2.Name == "Generator" then

                                        if v2:FindFirstChild("Venuz_Hightlight_Generator") then
                                            if not getgenv().Settings.ESP.Generator then
                                                v2.Venuz_Hightlight_Generator.Enabled = false
                                                else
                                                v2.Venuz_Hightlight_Generator.Enabled = true
                                            end
                                        end

                                        if v2:GetAttribute("RepairProgress") == 100 then
                                            local highlight = v2:FindFirstChild("Venuz_Hightlight_Generator")
                                            if highlight then
                                                highlight:Destroy()
                                            end
                                        else
                                            if not v2:FindFirstChild("Venuz_Hightlight_Generator") then
                                                local Highlight = Instance.new("Highlight")
                                                Highlight.Parent = v2
                                                Highlight.FillColor = Color3.fromRGB(0, 150, 255)
                                                Highlight.FillTransparency = 0.5
                                                Highlight.Name = "Venuz_Hightlight_Generator"
                                                Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                                            end
                                        end
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

local PalletToggle = Tabs.Visual:Toggle({
    Title = "tr:PalletToggle",
    Value = getgenv().Settings.ESP.Pallets,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.ESP.Pallets = Value
        SaveSetting()

        task.spawn(function()
            pcall(function()
                while getgenv().Settings.ESP.Pallets do task.wait(5)

                    for _, v in pairs(workspace.Map:GetDescendants()) do
                        if v.Name:lower():find("pallet") and v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") then
                            local highlight = v:FindFirstChild("Venuz_Hightlight_Generator")

                            if not highlight then
                                local Highlight = Instance.new("Highlight")
                                Highlight.Name = "Venuz_Hightlight_Generator"
                                Highlight.Parent = v
                                Highlight.FillColor = Color3.fromRGB(255, 234, 0)
                                Highlight.FillTransparency = 0.5
                                Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                                Highlight.OutlineTransparency = 1
                            end

                            v.Venuz_Hightlight_Generator.Enabled = getgenv().Settings.ESP.Pallets
                        end
                    end
                end

                -- 🔹 ปิด toggle → ลบ highlight ออกทั้งหมด
                for _, v in pairs(workspace.Map:GetDescendants()) do
                    local highlight = v:FindFirstChild("Venuz_Hightlight_Generator")
                    if highlight then
                        highlight:Destroy()
                    end
                end
            end)
        end)
    end
})

local ESPMain3 = Tabs.Visual:Section({ Title = "tr:ESPMain3" })

local FullBrightTab = Tabs.Visual:Toggle({
    Title = "tr:FullBrightTab",
    Value = getgenv().Settings.Lighting.FullBright,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Lighting.FullBright = Value
        SaveSetting()

        task.spawn(function()
            pcall(function()
                local lighting = game:GetService("Lighting")

                local oldAmbient = lighting.Ambient
                local oldBrightness = lighting.Brightness

                if Value then
                    while getgenv().Settings.Lighting.FullBright do task.wait(.5)
                        lighting.Ambient = Color3.fromRGB(255, 255, 255)
                        lighting.Brightness = 4
                    end

                    lighting.Ambient = oldAmbient
                    lighting.Brightness = oldBrightness
                end
            end)
        end)
    end
})

local ModifyCharacter = Tabs.Modify:Section({ Title = "tr:ModifyCharacter" })

local currentConnection = nil
local repairingConnection = nil
local teamConnection = nil
local isResetting = false
local lastResetTime = 0
local RESET_COOLDOWN = 5
local isCurrentlyRepairing = false
local isMapLoading = false

-- ✅ ฟังก์ชันตรวจสอบว่าเป็น Team Survivors หรือไม่
function IsSurvivorTeam()
    local player = LocalPlayer
    if not player.Team then return false end
    return player.Team.Name == "Survivors"
end

function SetSpeedAttribute(char, value)
    if not char or not char.Parent then return end
    
    -- ⭐ ตรวจสอบ Team ก่อนเปลี่ยนความเร็ว
    if not IsSurvivorTeam() then 
        return 
    end
    
    local finalValue = tonumber(string.format("%.2f", value))
    
    if char:GetAttribute("speedboost") == finalValue then
        return
    end
    
    char:SetAttribute("speedboost", nil)
    task.wait(0.05)
    char:SetAttribute("speedboost", finalValue)
end

function ClearConnection()
    if currentConnection then
        currentConnection:Disconnect()
        currentConnection = nil
    end
    if repairingConnection then
        repairingConnection:Disconnect()
        repairingConnection = nil
    end
    if teamConnection then
        teamConnection:Disconnect()
        teamConnection = nil
    end
    isResetting = false
    isCurrentlyRepairing = false
end

-- ⭐ ฟังก์ชันตรวจสอบสถานะโหลดแมพ
function CheckMapLoading(char)
    isMapLoading = true
    
    -- รอให้โหลดเสร็จ (รอ Humanoid และ HumanoidRootPart)
    local humanoid = char:WaitForChild("Humanoid", 5)
    local rootPart = char:WaitForChild("HumanoidRootPart", 5)
    
    if humanoid and rootPart then
        -- รอให้ตัวละครพร้อมใช้งาน
        task.wait(2)
    end
    
    isMapLoading = false
end

function MonitorSpeedBoost(char)
    if not char or not char.Parent then return end
    
    -- ⭐ ตรวจสอบ Team ก่อนเริ่ม Monitor
    if not IsSurvivorTeam() then 
        return 
    end
    
    ClearConnection()

    -- ตรวจจับการเปลี่ยนแปลงของค่า repairing
    repairingConnection = char:GetAttributeChangedSignal("repairing"):Connect(function()
        local repairValue = char:GetAttribute("repairing")
        
        if repairValue and repairValue > 0 then
            isCurrentlyRepairing = true
        else
            isCurrentlyRepairing = false
        end
    end)

    currentConnection = char:GetAttributeChangedSignal("speedboost"):Connect(function()
        if not getgenv().Settings.ModifyCharacter.SpeedBoot then 
            return 
        end

        -- ⭐ ตรวจสอบ Team อีกครั้ง
        if not IsSurvivorTeam() then
            return
        end

        if isResetting then 
            return 
        end
        
        -- ⭐ ถ้ากำลังโหลดแมพ ไม่ต้องปรับความเร็ว
        if isMapLoading then
            return
        end
        
        -- ถ้ากำลังปั่นไฟอยู่ ไม่ต้องปรับความเร็ว
        if isCurrentlyRepairing then
            return
        end
        
        local currentTime = tick()
        if currentTime - lastResetTime < RESET_COOLDOWN then
            return
        end
        
        local currentSpeed = char:GetAttribute("speedboost")
        local targetSpeed = getgenv().Settings.ModifyCharacter.SpeedBootValue or 1.1

        currentSpeed = tonumber(string.format("%.2f", currentSpeed or 0))
        targetSpeed = tonumber(string.format("%.2f", targetSpeed))

        if math.abs(currentSpeed - targetSpeed) > 0.01 then
            isResetting = true
            lastResetTime = currentTime

            task.wait(math.random(30, 40) / 10)

            if char.Parent and getgenv().Settings.ModifyCharacter.SpeedBoot and IsSurvivorTeam() then
                -- เช็คอีกครั้งก่อนเปลี่ยนความเร็ว
                if not isCurrentlyRepairing and not isMapLoading then
                    SetSpeedAttribute(char, targetSpeed)
                end
            end
            
            task.wait(0.5)
            isResetting = false
        end
    end)

    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.Died:Once(function()
            ClearConnection()
        end)
    end

    char.AncestryChanged:Once(function()
        if not char.Parent then
            ClearConnection()
        end
    end)
end

-- ⭐ ฟังก์ชันจัดการเมื่อเปลี่ยน Team
function OnTeamChanged()
    local char = LocalPlayer.Character
    if not char then return end
    
    if IsSurvivorTeam() then
        -- เข้า Team Survivors - เปิดใช้งาน Speed Boost
        if getgenv().Settings.ModifyCharacter.SpeedBoot then
            local targetValue = getgenv().Settings.ModifyCharacter.SpeedBootValue or 1.1
            SetSpeedAttribute(char, targetValue)
            MonitorSpeedBoost(char)
        end
    else
        -- ไม่ได้อยู่ Team Survivors - ปิดการทำงานและรีเซ็ตความเร็ว
        ClearConnection()
        if char:GetAttribute("speedboost") then
            char:SetAttribute("speedboost", 1)
        end
    end
end

local SpeedBoost = Tabs.Modify:Toggle({
    Title = "tr:SpeedBoost",
    Value = getgenv().Settings.ModifyCharacter.SpeedBoot,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.ModifyCharacter.SpeedBoot = Value
        SaveSetting()

        local char = LocalPlayer.Character
        if not char then return end

        -- ⭐ ตรวจสอบ Team ก่อนเปิดใช้งาน
        if not IsSurvivorTeam() then
            return
        end

        if Value then
            local targetValue = getgenv().Settings.ModifyCharacter.SpeedBootValue or 1.1
            SetSpeedAttribute(char, targetValue)
            MonitorSpeedBoost(char)
        else
            ClearConnection()
            SetSpeedAttribute(char, 1)
        end
    end
})

local SpeedValue = Tabs.Modify:Input({
    Title = "tr:SpeedValue",
    Desc = "tr:SpeedValueDesc",
    Placeholder = "1.1",
    Value = tostring(getgenv().Settings.ModifyCharacter.SpeedBootValue),
    Callback = function(Value)
        getgenv().Settings.ModifyCharacter.SpeedBootValue = Value
        SaveSetting()

        local char = LocalPlayer.Character
        
        -- ⭐ ตรวจสอบ Team ก่อนเปลี่ยนความเร็ว
        if getgenv().Settings.ModifyCharacter.SpeedBoot and char and IsSurvivorTeam() then
            isResetting = true
            SetSpeedAttribute(char, Value)
            task.wait(0.5)
            isResetting = false
        end
    end
})

-- ⭐ ตรวจจับการเปลี่ยน Team
LocalPlayer:GetPropertyChangedSignal("Team"):Connect(OnTeamChanged)

LocalPlayer.CharacterAdded:Connect(function(char)
    ClearConnection()
    lastResetTime = 0
    
    -- ⭐ ตรวจสอบสถานะโหลดแมพ
    CheckMapLoading(char)
    
    char:WaitForChild("Humanoid")
    task.wait(1)
    
    -- ⭐ ตรวจสอบ Team ก่อนเปิดใช้งาน
    if not IsSurvivorTeam() then
        return
    end
    
    if getgenv().Settings.ModifyCharacter.SpeedBoot then
        local targetValue = getgenv().Settings.ModifyCharacter.SpeedBootValue or 1.1
        SetSpeedAttribute(char, targetValue)
        MonitorSpeedBoost(char)
    else
        SetSpeedAttribute(char, 1)
    end
end)

if getgenv then
    getgenv().CleanupSpeedBoost = function()
        ClearConnection()
    end
end

local CrosshairSection = Tabs.Visual:Section({ Title = "Crosshair" })

local CrosshairLines = {}
local ScreenGui = nil

local function CreateCrosshair()
    if ScreenGui then
        ScreenGui:Destroy()
    end
    
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "VenuzCrosshair"
    ScreenGui.Parent = game:GetService("CoreGui")
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false
    
    local center = UDim2.new(0.5, 0, 0.5, 0)
    local size = getgenv().Settings.ESP.crosshairsize or 15
    local thickness = getgenv().Settings.ESP.crosshairthickness or 2
    local color = getgenv().Settings.ESP.crosshaircolor or {255, 255, 255}
    local transparency = getgenv().Settings.ESP.crosshairtransparency or 0.5
    
    -- เส้นบน
    local top = Instance.new("Frame")
    top.Name = "Top"
    top.Size = UDim2.new(0, thickness, 0, size)
    top.Position = center
    top.AnchorPoint = Vector2.new(0.5, 1)  -- จุดยึดที่ขอบล่าง
    top.BackgroundColor3 = Color3.fromRGB(color[1], color[2], color[3])
    top.BackgroundTransparency = transparency
    top.BorderSizePixel = 0
    top.Parent = ScreenGui
    
    -- เส้นล่าง
    local bottom = Instance.new("Frame")
    bottom.Name = "Bottom"
    bottom.Size = UDim2.new(0, thickness, 0, size)
    bottom.Position = center
    bottom.AnchorPoint = Vector2.new(0.5, 0)  -- จุดยึดที่ขอบบน
    bottom.BackgroundColor3 = Color3.fromRGB(color[1], color[2], color[3])
    bottom.BackgroundTransparency = transparency
    bottom.BorderSizePixel = 0
    bottom.Parent = ScreenGui
    
    -- เส้นซ้าย
    local left = Instance.new("Frame")
    left.Name = "Left"
    left.Size = UDim2.new(0, size, 0, thickness)
    left.Position = center
    left.AnchorPoint = Vector2.new(1, 0.5)  -- จุดยึดที่ขอบขวา
    left.BackgroundColor3 = Color3.fromRGB(color[1], color[2], color[3])
    left.BackgroundTransparency = transparency
    left.BorderSizePixel = 0
    left.Parent = ScreenGui
    
    -- เส้นขวา
    local right = Instance.new("Frame")
    right.Name = "Right"
    right.Size = UDim2.new(0, size, 0, thickness)
    right.Position = center
    right.AnchorPoint = Vector2.new(0, 0.5)  -- จุดยึดที่ขอบซ้าย
    right.BackgroundColor3 = Color3.fromRGB(color[1], color[2], color[3])
    right.BackgroundTransparency = transparency
    right.BorderSizePixel = 0
    right.Parent = ScreenGui
    
    if getgenv().Settings.ESP.crsshairoutline then
        for _, line in pairs({top, bottom, left, right}) do
            local outline = Instance.new("UIStroke")
            outline.Color = Color3.fromRGB(0, 0, 0)
            outline.Thickness = 1
            outline.Parent = line
        end
    end
    
    CrosshairLines = {top, bottom, left, right}
    ScreenGui.Enabled = getgenv().Settings.ESP.crosshairenabled
end

local function UpdateCrosshair()
    if not ScreenGui then return end
    
    local size = getgenv().Settings.ESP.crosshairsize or 15
    local thickness = getgenv().Settings.ESP.crosshairthickness or 2
    local color = getgenv().Settings.ESP.crosshaircolor or {255, 255, 255}
    local transparency = getgenv().Settings.ESP.crosshairtransparency or 0.5
    
    for _, line in pairs(CrosshairLines) do
        if line and line.Parent then
            line.BackgroundColor3 = Color3.fromRGB(color[1], color[2], color[3])
            line.BackgroundTransparency = transparency
            
            if line.Name == "Top" or line.Name == "Bottom" then
                line.Size = UDim2.new(0, thickness, 0, size)
            elseif line.Name == "Left" or line.Name == "Right" then
                line.Size = UDim2.new(0, size, 0, thickness)
            end
        end
    end
end

local CrosshairToggle = Tabs.Visual:Toggle({
    Title = "tr:EnableCrosshair",
    Value = getgenv().Settings.ESP.crosshairenabled,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.ESP.crosshairenabled = Value
        SaveSetting()
        
        if Value then
            CreateCrosshair()
        else
            if ScreenGui then
                ScreenGui.Enabled = false
            end
        end
    end
})

local CrosshairColor = Tabs.Visual:Colorpicker({
    Title = "tr:CrosshairColor",
    Value = Color3.fromRGB(
        getgenv().Settings.ESP.crosshaircolor[1],
        getgenv().Settings.ESP.crosshaircolor[2],
        getgenv().Settings.ESP.crosshaircolor[3]
    ),
    Callback = function(Value)
        getgenv().Settings.ESP.crosshaircolor = {
            math.floor(Value.R * 255),
            math.floor(Value.G * 255),
            math.floor(Value.B * 255)
        }
        SaveSetting()
        UpdateCrosshair()
    end
})

local CrosshairSize = Tabs.Visual:Slider({
    Title = "tr:CrosshairSize",
    Value = {
        Min = 5,
        Max = 50,
        Default = getgenv().Settings.ESP.crosshairsize,
    },
    Callback = function(Value)
        getgenv().Settings.ESP.crosshairsize = Value
        SaveSetting()
        UpdateCrosshair()
    end
})

local CrosshairThickness = Tabs.Visual:Slider({
    Title = "tr:CrosshairThickness",
    Value = {
        Min = 0,
        Max = 5,
        Default = getgenv().Settings.ESP.crosshairthickness,
    },
    Callback = function(Value)
        getgenv().Settings.ESP.crosshairthickness = Value
        SaveSetting()
        UpdateCrosshair()
    end
})

local CrosshairTransparency = Tabs.Visual:Slider({
    Title = "tr:CrosshairTransparency",
    Step = 0.1,
    Value = {
        Min = 0,
        Max = 1,
        Default = getgenv().Settings.ESP.crosshairtransparency,
    },
    Callback = function(Value)
        getgenv().Settings.ESP.crosshairtransparency = Value
        SaveSetting()
        UpdateCrosshair()
    end
})

-------------------------------- Configuration --------------------------------

local IS = Tabs.Configuration:Section({ Title = "tr:InterfaceSettings" })


local themeValues = {}
for name, _ in pairs(WindUI:GetThemes()) do
    table.insert(themeValues, name)
end

local themeDropdown = Tabs.Configuration:Dropdown({
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

themeDropdown:Select(WindUI:GetCurrentTheme())

local ToggleTransparency = Tabs.Configuration:Toggle({
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

local AntiAFK = Tabs.Configuration:Toggle({
    Title = "tr:AntiAFK",
    Value = getgenv().ConfigurationTable.AntiAFK,
    Icon = "check",
    Callback = function(enabled)
        getgenv().ConfigurationTable.AntiAFK = enabled
        SaveConfiguration()

        if enabled then
            task.spawn(function()
                while getgenv().ConfigurationTable.AntiAFK do task.wait(500)
                    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                    task.wait(0.1)
                    game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                end
            end)
        end
    end
})

local AutoExecutor = Tabs.Configuration:Toggle({
    Title = "tr:AutoExecutor",
    Value = getgenv().ConfigurationTable.AutoExecutor,
    Icon = "check",
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoExecutor = Value
        SaveConfiguration()
    end
})

local MinimizeBind = Tabs.Configuration:Keybind({
    Title = "tr:MinimizeBind",
    Value = getgenv().ConfigurationTable.MinimizeBind,
    Callback = function(v)
        getgenv().ConfigurationTable.MinimizeBind = v
        SaveConfiguration()
        Window:SetToggleKey(Enum.KeyCode[v])
    end
})

local LanguageTab =  Tabs.Configuration:Section({ Title = "tr:LanguageTab", Icon = "languages"})

local Language = Tabs.Configuration:Dropdown({
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

local ChangedLanguage = Tabs.Configuration:Button({
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