if game:GetService("CoreGui"):FindFirstChild("ScreenGui") then
    for i, v in pairs(game:GetService("CoreGui"):GetChildren()) do
        if v.Name == "ScreenGui" then
            for _, kom in pairs(v:GetChildren()) do
                if kom:IsA("Frame") then
                    kom.Visible = false
                end
            end
        end
    end
    game:GetService("CoreGui"):FindFirstChild("ScreenGui"):Destroy()
end

pcall(function()
    game.Players.LocalPlayer.PlayerScripts:FindFirstChild("Anti-Fly"):Destroy()
    game.Players.LocalPlayer.PlayerScripts:FindFirstChild("Anti-Speed"):Destroy()
end)

_G.SettingsTable = {
    Noclip = false,
    FullBrightness = false,
    EspSama = false,
    ESpScarar = false,
    EspKusonoki = false,
    EspHeartSama = false,
    Speed = 16,
    Jump = 50,
    ChangeJump = false,
    ChangeSpeed = false
}

for i, v in pairs(_G.SettingsTable) do

end

local Folder = "Venuz Hub"
local filename = Folder .. "/TheMimic.json"

function loadSettings()
    local HttpService = game:GetService("HttpService")
    if (readfile and isfile and isfile(filename)) then
        _G.SettingsTable = HttpService:JSONDecode(readfile(filename))
    end
end

function saveSettings()
    local json
    local HttpService = game:GetService("HttpService")
    if (writefile and makefolder) then
        if not isfolder(Folder) then
            makefolder(Folder)
        end
        json = HttpService:JSONEncode(_G.SettingsTable)
        writefile(filename, json)
    end
end

loadSettings()

function TPSuperlow(P)
    local Distance = (P.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
    local Speed = 45
    tweenService, tweenInfo = game:GetService("TweenService"), TweenInfo.new(Distance / Speed, Enum.EasingStyle.Linear)
    tween = tweenService:Create(game:GetService("Players")["LocalPlayer"].Character.HumanoidRootPart, tweenInfo, {
        CFrame = P
    })
    tween:Play()
end

function TPlow(P)
    local Distance = (P.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
    local Speed = 125
    tweenService, tweenInfo = game:GetService("TweenService"), TweenInfo.new(Distance / Speed, Enum.EasingStyle.Linear)
    tween = tweenService:Create(game:GetService("Players")["LocalPlayer"].Character.HumanoidRootPart, tweenInfo, {
        CFrame = P
    })
    tween:Play()
end

function TPFast(P)
    local Distance = (P.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
    local Speed = 244
    tweenService, tweenInfo = game:GetService("TweenService"), TweenInfo.new(Distance / Speed, Enum.EasingStyle.Linear)
    tween = tweenService:Create(game:GetService("Players")["LocalPlayer"].Character.HumanoidRootPart, tweenInfo, {
        CFrame = P
    })
    tween:Play()
end

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local InterfaceManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/x2Kotaro/API/refs/heads/main/Interface.Lua"))()

local Window = Fluent:CreateWindow({
    Title = "Venuz Hub  -",
    SubTitle = "The Mimic",
    TabWidth = 150,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({
        Title = "Chapters I - III",
        Icon = "book-open"
    }),
    Main1 = Window:AddTab({
        Title = "Chapter IV",
        Icon = "book-open"
    }),
    Players = Window:AddTab({
        Title = "Players",
        Icon = "user"
    }),
    Visuals = Window:AddTab({
        Title = "Visuals",
        Icon = "eye"
    }),
    Settings = Window:AddTab({
        Title = "Settings",
        Icon = "settings"
    })
}

local Options = Fluent.Options
-- function AutoChapter
local AllChapter = Tabs.Main:AddSection("Chapters I - III")

local Chapter1Toggle = AllChapter:AddButton({
    Title = "Chapter I",
    Callback = function(value)
        PlaceId = game.PlaceId
        if PlaceId == 6296321810 or PlaceId == 6479231833 then
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame =
                CFrame.new(3485.66748, 38.7796898, -1537.48657, -0.177830324, 0.207676932, -0.961897433,
                    -4.61665284e-09, 0.977477252, 0.211040676, 0.984061182, 0.037529435, -0.1738251)
        elseif PlaceId == 6301638949 or PlaceId == 6480994221 then
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame =
                CFrame.new(2139.72388, 257.123474, -2762.46191, -0.993020177, 5.59675373e-09, 0.117944762,
                    5.5795053e-09, 1, -4.76429729e-10, -0.117944762, 1.84969068e-10, -0.993020177)
            wait(3.89)
            local a = CFrame.new(2143.35522, 257.123505, -2968.86719, 0.837279916, -2.15588667e-08, -0.546774507,
                2.92742079e-08, 1, 5.39864153e-09, 0.546774507, -2.05265636e-08, 0.837279916)
            TPSuperlow(a)
            task.wait(5)
            Fluent:Notify({
                Title = "Please Select",
                Content = "Please choose back or continue.",
                SubContent = "Success",
                Duration = 3
            })
        else
            Fluent:Notify({
                Title = "You are not in Chapter I.",
                Content = "Please choose correctly.",
                Duration = 3
            })
        end
    end
})

local Chapter2Toggle = AllChapter:AddButton({
    Title = "Chapter II",
    Callback = function(value)
        local PlaceId = game.PlaceId
        if PlaceId == 6373539583 or PlaceId == 6485055338 then
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame =
                CFrame.new(68.3324432, 61.9521561, -1614.55261, 0, 0, 1, 1, 0, 0, 0, 1, 0)
        elseif PlaceId == 6406571212 or PlaceId == 6485055836 then
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame =
                CFrame.new(234.830933, 99.0160828, -588.336975, 0.99253881, -0.0515349619, 0.110502765, 1.35842928e-08,
                    0.906286836, 0.422663122, -0.121929131, -0.41950956, 0.899524868)
        elseif PlaceId == 6425178683 or PlaceId == 6485056556 then
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame =
                CFrame.new(867.300232, 76.848587, -352.897644, -0.0245152973, 0.206289828, -0.978183806,
                    -7.92620636e-09, 0.978477836, 0.206351846, 0.999699473, 0.0050587845, -0.0239876732)
            wait(3.79)
            local a = CFrame.new(1154.69983, 84.0730133, -353.02774, -0.869358778, -3.28493606e-08, -0.494181424,
                -7.61524035e-08, 1, 6.74942413e-08, 0.494181424, 9.63098188e-08, -0.869358778)
            TPSuperlow(a)
            task.wait(5)
            Fluent:Notify({
                Title = "Please Select",
                Content = "Please choose back or continue.",
                Duration = 3
            })
        else
            Fluent:Notify({
                Title = "You are not in Chapter II.",
                Content = "Please choose correctly.",
                Duration = 3
            })
        end
    end
})

local Chapter3Toggle = AllChapter:AddButton({
    Title = "Chapter III",
    Callback = function(value)
        local PlaceId = game.PlaceId
        if PlaceId == 6472459099 or PlaceId == 6688734180 then
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame =
                CFrame.new(2410.9585, -23.0311165, 2269.8667, -0.997892559, -3.77373155e-09, 0.064887546, 2.3885165e-09,
                    1, 9.48905381e-08, -0.064887546, 9.48455536e-08, -0.997892559)
        elseif PlaceId == 6682163754 or PlaceId == 6688734313 then
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame =
                CFrame.new(242.771713, 34.3152275, 449.323639, 0, 0, 1, 1, 0, 0, 0, 1, 0)
        elseif PlaceId == 6682164423 or PlaceId == 6688734395 then
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame =
                CFrame.new(-628.2852783203125, 947.80419921875, -1360.80078125)
            wait(3.78)
        else
            Fluent:Notify({
                Title = "You are not in Chapter III.",
                Content = "Please choose correctly.",
                Duration = 3
            })
        end
    end
})

local sectionIV = Tabs.Main1:AddSection("Section1")

local HomeIV = sectionIV:AddButton({
    Title = "AutoPlay",
    Callback = function()
        local PlaceId = game.PlaceId
        if PlaceId == 7251865082 or PlaceId == 7265396387 then
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame =
                CFrame.new(457.454285, 30.8038979, -833.072632, 0.999853671, 0.0170948412, -0.000591687858,
                    -0.0170868542, 0.999787033, 0.0115724346, 0.00078939076, -0.011560631, 0.999932885)
            for i, v in pairs(game:GetService("Workspace"):GetDescendants()) do
                if v.Name == "ProximityPrompt" then
                    fireproximityprompt(v, 50)
                end
            end
            wait(0.1)
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame =
                CFrame.new(433.45819091796875, 16.85248374938965, -835.5492553710938)
            for i, v in pairs(game:GetService("Workspace"):GetDescendants()) do
                if v.Name == "ProximityPrompt" then
                    fireproximityprompt(v, 50)
                end
            end
            wait(0.1)
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(505.3853454589844,
                18.919750213623047, -832.2984619140625)
            for i, v in pairs(game:GetService("Workspace"):GetDescendants()) do
                if v.Name == "ProximityPrompt" then
                    fireproximityprompt(v, 50)
                end
            end
            wait(0.1)
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame =
                CFrame.new(419.8941345214844, 8.80666446685791, -866.37890625)
            for i, v in pairs(game:GetService("Workspace"):GetDescendants()) do
                if v.Name == "ProximityPrompt" then
                    fireproximityprompt(v, 50)
                end
            end
            wait(0.1)
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame =
                CFrame.new(368.830322265625, 5.034653186798096, -863.2230834960938)
            for i, v in pairs(game:GetService("Workspace"):GetDescendants()) do
                if v.Name == "ProximityPrompt" then
                    fireproximityprompt(v, 50)
                end
            end
            wait(0.1)
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame =
                CFrame.new(436.849853515625, 5.032793998718262, -845.5335693359375)
            for i, v in pairs(game:GetService("Workspace"):GetDescendants()) do
                if v.Name == "ProximityPrompt" then
                    fireproximityprompt(v, 50)
                end
            end
            wait(0.1)
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame =
                CFrame.new(87.7054062, -50.9981918, -1414.53723, -2.66543809e-09, 1.62177685e-08, -1, -5.33502842e-09,
                    1, 1.62177685e-08, 1, 5.33502886e-09, -2.66543809e-09)
        else
            Fluent:Notify({
                Title = "You are not in Chapter IV Section1",
                Content = "Please choose correctly.",
                Duration = 1.5
            })
        end
    end
})

local sectionIV = Tabs.Main1:AddSection("Section2")

local HomeIV = sectionIV:AddButton({
    Title = "GetAllBetterfly",
    Callback = function(value)
        local PlaceId = game.PlaceId
        if PlaceId == 7251866503 or PlaceId == 7265396805 then
            local SafeZone = CFrame.new(891, 3, -2)
            local player = game.Players.LocalPlayer
            local humanoidRootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            spawn(function()
                while true do
                    wait(.1)
                    local scararNearby = false
                    for _, v in pairs(game:GetService("Workspace").GameAI:GetChildren()) do
                        if v.Name == "Scarar" then
                            local scarar = v
                            local distance = (scarar.HumanoidRootPart.Position - humanoidRootPart.Position).Magnitude
                            if distance < 10 then
                                scararNearby = true
                                break
                            end
                        end
                    end
                    if scararNearby then
                        player.Character:SetPrimaryPartCFrame(SafeZone)
                        wait(3)
                        scararNearby = false
                    else
                        for _, v in pairs(game:GetService("Workspace").Butterflies:GetDescendants()) do
                            if v.Name == "Butterfly" then
                                game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = v.CFrame
                                wait(.1)
                                for _, prompt in pairs(workspace.Butterflies:GetDescendants()) do
                                    if prompt.Name == "ProximityPrompt" and prompt.Enabled then
                                        fireproximityprompt(prompt)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        else
            Fluent:Notify({
                Title = "You are not in Chapter IV Section2",
                Content = "Please choose correctly.",
                Duration = 1.5
            })
        end
    end
})

local sectionIV = Tabs.Main1:AddSection("Section3")

local Toggle = sectionIV:AddButton({
    Title = "AutoGrabItem",
    Callback = function()
        spawn(function()
            while true do
                wait(.1)
                for _, v in pairs(workspace.GameInfo.PuzzleItems:GetDescendants()) do
                    if v.Name == "GrabItem" then
                        for _, item in pairs(v:GetChildren()) do
                            if item.Name == "Handle" and (item:IsA("Part") or item:IsA("MeshPart")) then
                                game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = item.CFrame
                                wait(.2)
                                for _, Grab in pairs(workspace.GameInfo.PuzzleItems:GetDescendants()) do
                                    if Grab.Name == "ProximityPrompt" and Grab.Enabled then
                                        fireproximityprompt(Grab)
                                    end
                                end
                            else
                                game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(680, 24, 2251)
                                for _, Grab in pairs(workspace.Well:GetDescendants()) do
                                    if Grab.Name == "ProximityPrompt" and Grab.Enabled then
                                        fireproximityprompt(Grab)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
})

local sectionIV = Tabs.Main1:AddSection("Section4")

local AutoKillSama = sectionIV:AddButton({
    Title = "AutoKillSama",
    Callback = function()
        _G.AutoKill = true
        local VIM = VirtualInputManager or game:GetService("VirtualInputManager")
        local function VM1Click(X, Y)
            VIM:SendMouseButtonEvent(X, Y, 0, true, game, 0)
            task.wait()
            VIM:SendMouseButtonEvent(X, Y, 0, false, game, 0)
        end

        equipKatana = function()
            local PlayerEquip = game:GetService("Players")
            local Local = PlayerEquip.LocalPlayer
            local Katana = Local.Character:FindFirstChild("Katana")
            if not Katana then
                local Eq = Local.Backpack:FindFirstChild("Katana")
                if Eq then
                    Local.Character.Humanoid:EquipTool(Eq)
                end
            end
        end

        for i, v in pairs(workspace.GameHearts:GetDescendants()) do
            if v.Name == "Heart" then
                for i, c in pairs(v:GetChildren()) do
                    if c.Name == "Root" and c:IsA("Part") then
                        c.Rotation = Vector3.new(0, 0, 0)
                    end
                end
            end
        end

        local function isSamaNearby()
            local humanoidRootPart = game.Players.LocalPlayer.Character and
                                         game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not humanoidRootPart then
                return false
            end

            for _, v in pairs(game:GetService("Workspace").GameAI:GetChildren()) do
                if v.Name == "Sama" then
                    local scarar = v
                    local distance = (scarar.HumanoidRootPart.Position - humanoidRootPart.Position).Magnitude
                    if distance < 50 then
                        return true
                    end
                end
            end
            return false
        end

        local function handleUnion()
            local humanoidRootPart = game.Players.LocalPlayer.Character and
                                         game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not humanoidRootPart then
                return
            end

            for _, v in pairs(workspace.GameHearts:GetDescendants()) do
                if v.Name == "Health" and v:IsA("IntValue") then
                    local Root = v.Parent:FindFirstChild("Root")
                    local Union = v.Parent:FindFirstChild("Union")

                    if Root and Root:IsA("Part") and Union and Union:IsA("UnionOperation") then
                        equipKatana()

                        local humanoid = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            humanoid.PlatformStand = false
                        end

                        if Union.Transparency == 0 then
                            humanoidRootPart.CFrame = Root.CFrame * CFrame.new(0, -5, 3)
                            task.wait(0.1)
                            humanoid.PlatformStand = true
                            while Union.Transparency == 0 and _G.AutoKill do
                                if isSamaNearby() then
                                    return "SamaNearby"
                                end

                                VM1Click(300, 500)
                                task.wait(0.1)
                            end
                        end
                        if humanoid then
                            humanoid.PlatformStand = false
                        end
                    end
                end
            end
        end

        while _G.AutoKill do
            local SafeZone = CFrame.new(2935, 132, 1741)
            if isSamaNearby() then
                game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(SafeZone)
                print("Sama detected! Warping to SafeZone...")
                wait(3)
                continue
            end
            local result = handleUnion()
            if result == "SamaNearby" then
                game.Players.LocalPlayer.Character:SetPrimaryPartCFrame(SafeZone)
                print("Sama detected during Union handling! Warping to SafeZone...")
                wait(3)
                continue
            end
            wait(0.1)
        end
    end
})

------------------funtionMore----------------------------

local EnabledSpeed = _G.SettingsTable.Speed
local EnabledJump = _G.SettingsTable.Jump
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local RunService = game:GetService("RunService")

LocalPlayer.CharacterAdded:Connect(function()
    character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    humanoid = character:WaitForChild("Humanoid")

    if _G.SettingsTable.ChangeSpeed then
        humanoid.WalkSpeed = _G.SettingsTable.Speed
    else
        humanoid.WalkSpeed = 16
    end

    if _G.SettingsTable.ChangeJump then
        humanoid.JumpPower = _G.SettingsTable.Jump
    else
        humanoid.JumpPower = 50
    end
end)

local CharacterScetion = Tabs.Players:AddSection("Character")

local isSpeedLooping = false
local isJumpLooping = false
local loopSpeedInterval = 0.1
local loopJumpInterval = 0.1

local WalkSpeedValue = CharacterScetion:AddSlider("Slider", {
    Title = "Speed",
    Default = _G.SettingsTable.Speed,
    Min = 16,
    Max = 200,
    Rounding = 0,
    Callback = function(value)
        _G.SettingsTable.Speed = value
        saveSettings()
        if _G.SettingsTable.ChangeSpeed then
            humanoid.WalkSpeed = value
        end
    end
})

local ToggleSpeed = CharacterScetion:AddToggle("MyToggle", {
    Title = "ChangeSpeed",
    Default = _G.SettingsTable.ChangeSpeed,
    Callback = function(value)
        _G.SettingsTable.ChangeSpeed = value
        saveSettings()
        if value then
            humanoid.WalkSpeed = _G.SettingsTable.Speed
            isSpeedLooping = true
        else
            humanoid.WalkSpeed = 16
            isSpeedLooping = false
        end
    end
})

local JumpValue = CharacterScetion:AddSlider("Slider", {
    Title = "Jump",
    Default = _G.SettingsTable.Jump,
    Min = 50,
    Max = 500,
    Rounding = 0,
    Callback = function(value)
        _G.SettingsTable.Jump = value
        saveSettings()
        if _G.SettingsTable.ChangeJump then
            humanoid.JumpPower = value
        end
    end
})

local ToggleJump = CharacterScetion:AddToggle("MyToggle", {
    Title = "ChangeJump",
    Default = _G.SettingsTable.ChangeJump,
    Callback = function(value)
        _G.SettingsTable.ChangeJump = value
        saveSettings()
        if value then
            humanoid.JumpPower = _G.SettingsTable.Jump
            isSpeedLooping = true
        else
            humanoid.JumpPower = 50
            isSpeedLooping = false
        end
    end
})

local CharacterMore = Tabs.Players:AddSection("More")

local ToggleJump = CharacterMore:AddToggle("MyToggle", {
    Title = "Noclip",
    Default = _G.SettingsTable.Noclip,
    Callback = function(value)
        _G.SettingsTable.Noclip = value
        saveSettings()
        if value == true then
            _G.SettingsTable.Noclip = true
        else
            _G.SettingsTable.Noclip = false

            RunService.Stepped:Connect(function()
                if _G.SettingsTable.Noclip then
                    for i, v in pairs(LocalPlayer.Character:GetChildren()) do
                        if v:IsA("BasePart") then
                            if v.CanCollide ~= not _G.SettingsTable.Noclip then
                                v.CanCollide = not _G.SettingsTable.Noclip
                            end
                        end
                    end
                end
            end)
        end
    end
})

local ESPVisuals = Tabs.Visuals:AddSection("EspMonster - Book1")

local EspSama = {}
local EspScarar = {}
local Heart = {}
local EspKusonokitable = {}

local ToggleJump = ESPVisuals:AddToggle("MyToggle", {
    Title = "Sama",
    Default = _G.SettingsTable.EspSama,
    Callback = function(value)
        _G.SettingsTable.EspSama = value
        saveSettings()
        _G.EnableEspsama = value

        for i, v in pairs(EspSama) do
            v.Enabled = value
        end
    end
})

local ToggleJump = ESPVisuals:AddToggle("MyToggle", {
    Title = "HeartSama",
    Default = _G.SettingsTable.EspHeartSama,
    Callback = function(value)
        _G.SettingsTable.EspHeartSama = value
        saveSettings()
        _G.EnabledHeart = value

        for i, v in pairs(Heart) do
            v.Enabled = value
        end
    end
})

local ToggleJump = ESPVisuals:AddToggle("MyToggle", {
    Title = "Daku",
    Default = _G.SettingsTable.ESpScarar,
    Callback = function(value)
        _G.SettingsTable.ESpScarar = value
        saveSettings()
        _G.EnabledScarar = value

        for i, v in pairs(EspScarar) do
            v.Enabled = value
        end
    end
})

local ToggleJump = ESPVisuals:AddToggle("MyToggle", {
    Title = "Kusonoki",
    Default = _G.SettingsTable.EspKusonoki,
    Callback = function(value)
        _G.SettingsTable.EspKusonoki = value
        saveSettings()
        _G.EnabledKusonoki = value

        for i, v in pairs(EspKusonokitable) do
            v.Enabled = value
        end
    end
})

local function ApplySama(inst)
    wait()
    local Cham = Instance.new("Highlight")
    Cham.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    Cham.FillColor = Color3.new(255, 0, 0)
    Cham.FillTransparency = 0.5
    Cham.OutlineColor = Color3.new(255, 0, 0)
    Cham.Parent = game:GetService("CoreGui")
    Cham.Adornee = inst
    Cham.Enabled = _G.EnableEspsama
    Cham.RobloxLocked = true
    return Cham
end

local KeyCoroutine = coroutine.create(function()
    workspace.DescendantAdded:Connect(function(inst)
        if inst.Name == "Sama" then
            table.insert(EspSama, ApplySama(inst))
        end
    end)
end)

for i, v in ipairs(workspace:GetDescendants()) do
    if v.Name == "Sama" then
        table.insert(EspSama, ApplySama(v))
    end
end

local function ApplyHeart(inst)
    wait()
    local Cham = Instance.new("Highlight")
    Cham.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    Cham.FillColor = Color3.new(255, 0, 0)
    Cham.FillTransparency = 0.5
    Cham.OutlineColor = Color3.new(255, 0, 0)
    Cham.Parent = game:GetService("CoreGui")
    Cham.Adornee = inst
    Cham.Enabled = _G.EnabledHeart
    Cham.RobloxLocked = true
    return Cham
end

local KeyCoroutine = coroutine.create(function()
    workspace.DescendantAdded:Connect(function(inst)
        if inst.Name == "Heart" then
            table.insert(Heart, ApplyHeart(inst))
        end
    end)
end)

for i, v in ipairs(workspace:GetDescendants()) do
    if v.Name == "Heart" then
        table.insert(Heart, ApplyHeart(v))
    end
end

local function ApplyEspScarar(inst)
    wait()
    local Cham = Instance.new("Highlight")
    Cham.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    Cham.FillColor = Color3.new(255, 0, 0)
    Cham.FillTransparency = 0.5
    Cham.OutlineColor = Color3.new(255, 0, 0)
    Cham.Parent = game:GetService("CoreGui")
    Cham.Adornee = inst
    Cham.Enabled = _G.EnabledScarar
    Cham.RobloxLocked = true
    return Cham
end

local KeyCoroutine = coroutine.create(function()
    workspace.DescendantAdded:Connect(function(inst)
        if inst.Name == "Scarar" then
            table.insert(EspScarar, ApplyEspScarar(inst))
        end
    end)
end)

for i, v in ipairs(workspace:GetDescendants()) do
    if v.Name == "Scarar" then
        table.insert(EspScarar, ApplyEspScarar(v))
    end
end

local function ApplyKusonoki(inst)
    wait()
    local Cham = Instance.new("Highlight")
    Cham.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    Cham.FillColor = Color3.new(255, 0, 0)
    Cham.FillTransparency = 0.5
    Cham.OutlineColor = Color3.new(255, 0, 0)
    Cham.Parent = game:GetService("CoreGui")
    Cham.Adornee = inst
    Cham.Enabled = _G.EnabledKusonoki
    Cham.RobloxLocked = true
    return Cham
end

local KeyCoroutine = coroutine.create(function()
    workspace.DescendantAdded:Connect(function(inst)
        if inst.Name == "Scarar" then
            table.insert(EspKusonokitable, ApplyKusonoki(inst))
        end
    end)
end)

for i, v in ipairs(workspace:GetDescendants()) do
    if v.Name == "Scarar" then
        table.insert(EspKusonokitable, ApplyKusonoki(v))
    end
end

coroutine.resume(KeyCoroutine)

local Lighting = Tabs.Visuals:AddSection("Lighting")

local orgLighting = {
    Brightness = game:GetService("Lighting").Brightness,
    Ambient = game:GetService("Lighting").Ambient,
    ColorShift_Bottom = game:GetService("Lighting").ColorShift_Bottom,
    ColorShift_Top = game:GetService("Lighting").ColorShift_Top,
    FogColor = game:GetService("Lighting").FogColor,
    FogEnd = game:GetService("Lighting").FogEnd,
    OutdoorAmbient = game:GetService("Lighting").OutdoorAmbient,
    ShadowColor = game:GetService("Lighting").ShadowColor
}

local ToggleJump = Lighting:AddToggle("MyToggle", {
    Title = "FullBrightness",
    Default = _G.SettingsTable.FullBrightness,
    Callback = function(value)
        _G.SettingsTable.FullBrightness = value
        saveSettings()
        if value then
            game:GetService("Lighting").Brightness = "5"
            game:GetService("Lighting").Ambient = Color3.fromRGB(255, 255, 255)
            game:GetService("Lighting").ColorShift_Bottom = Color3.fromRGB(255, 255, 255)
            game:GetService("Lighting").ColorShift_Top = Color3.fromRGB(255, 255, 255)
            game:GetService("Lighting").FogColor = Color3.fromRGB(255, 255, 255)
            game:GetService("Lighting").FogEnd = "100000000"
            game:GetService("Lighting").OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            game:GetService("Lighting").ShadowColor = Color3.fromRGB(255, 255, 255)
        else
            game:GetService("Lighting").Brightness = orgLighting.Brightness
            game:GetService("Lighting").Ambient = orgLighting.Ambient
            game:GetService("Lighting").ColorShift_Bottom = orgLighting.ColorShift_Bottom
            game:GetService("Lighting").ColorShift_Top = orgLighting.ColorShift_Top
            game:GetService("Lighting").FogColor = orgLighting.FogColor
            game:GetService("Lighting").FogEnd = orgLighting.FogEnd
            game:GetService("Lighting").OutdoorAmbient = orgLighting.OutdoorAmbient
            game:GetService("Lighting").ShadowColor = orgLighting.ShadowColor
        end
    end
})

InterfaceManager:SetLibrary(Fluent)
InterfaceManager:BuildInterfaceSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Script | Loader",
    Content = "Script Loader Venuz Hub",
    SubContent = "Success",
    Duration = 5
})
