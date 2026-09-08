local NotificationLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/IceMinisterq/Notification-Library/Main/Library.lua"))()

if game:GetService("CoreGui"):FindFirstChild("WindUI") then
    return
    NotificationLibrary:SendNotification("Info", "You already have a script.", 3)
end

_G.ConfigurationTable = {}
_G.Settings = {}

local FolderConfiguration = "Venuz Hub"
local FolderSettings = "Venuz Hub/Wizard West"
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local chr = LocalPlayer.Character
local hrp = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
local HttpService = game:GetService("HttpService")
local VenuzIcon = "rbxassetid://92691624917972"
local UserInputService = game:GetService("UserInputService")
local PlaceId = game.PlaceId

local filenameConfiguration = FolderConfiguration .. "/" .. "Setting" .. ".json"
local filenameSetting = FolderSettings .. "/" .. "Wizard West_".. LocalPlayer.Name .. ".json"

--------------------------- Configuration Save ---------------------------

function LoadConfiguration()
    if readfile and isfile and isfile(filenameConfiguration) then
        _G.ConfigurationTable = HttpService:JSONDecode(readfile(filenameConfiguration))
    else
        _G.ConfigurationTable = {
            Themes = "Dark",
            Transparent = true,
            AntiAFK = true,
            AutoExecutor = false,
            MinimizeBind = "End"
        }
    end
end

function saveConfiguration()
    if writefile and makefolder then
        if not isfolder("Venuz Hub") then makefolder("Venuz Hub") end
        if not isfolder(FolderConfiguration) then makefolder(FolderConfiguration) end
        local json = HttpService:JSONEncode(_G.ConfigurationTable)
        writefile(filenameConfiguration, json)
    end
end

LoadConfiguration()

--------------------------- SaveSettings ---------------------------

function LoadSettings()
    if readfile and isfile and isfile(filenameSetting) then
        _G.Settings = HttpService:JSONDecode(readfile(filenameSetting))
    else
        _G.Settings = {
            ["Main"] = {
                ["PlayerModify"] = {
                    ["DashNoCooldown"] = false,
                    ["AttackNoCooldown"] = false,
                    ["NoRecoil"] = false,
                    ["InfAmmo"] = false,
                }
            },

            ["Aimbot"] = {
                ["Aimbot"] = false,
                ["AimbotNPC"] = false,
                ["SelientAim"] = {
                    ["EnableSilent"] = false,
                    ["TeamCheck"] = false,
                    ["VisibleCheck"] = false,
                    ["TargetPart"] = "Random",
                    ["ShowTarget"] = false,
                    ["HitChance"] = 100,
                    ["MouseHitPrediction"] = false
                }
            }
        }
    end
end

function SaveSetting()
    if writefile and makefolder then
        if not isfolder("Venuz Hub") then makefolder("Venuz Hub") end
        if not isfolder(FolderSettings) then makefolder(FolderSettings) end
        local json = HttpService:JSONEncode(_G.Settings)
        writefile(filenameSetting, json)
    end
end

LoadSettings()

if getgenv().Configuration and next(getgenv().Configuration) then
    for key, value in pairs(getgenv().Configuration) do
        if _G.SettingsTable[key] ~= nil then
            _G.SettingsTable[key] = value
        end
    end
    SaveSetting()
end

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/x2Kotaro/API/main/Backup.lua"))()

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
    Transparent = _G.ConfigurationTable.Transparent,
    Theme = _G.ConfigurationTable.Themes,
    SideBarWidth = 200,
    HasOutline = true,
})

local Tabs = {
    Main = Window:Tab({ Title = "Main", Icon = "code-xml" }),
    Aimbot = Window:Tab({ Title = "PVP", Icon = "bot" }),
    divider1 = Window:Divider(),
    Configuration = Window:Tab({ Title = "Configuration", Icon = "settings", Desc = "Manage window settings and themes.", ShowTabTitle = true}),
}

-------------------------------- Function --------------------------------

function TeleportToWaypoint(Position)
    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = Position
end

local ActiveTween = nil
local lastSellTime = 0

function TweenFarm(P, speed)
    if ActiveTween then
        ActiveTween:Cancel()
        ActiveTween = nil
    end

    local Distance = (P.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
    local Speed = speed
    local tweenService = game:GetService("TweenService")
    local tweenInfo = TweenInfo.new(Distance / Speed, Enum.EasingStyle.Linear)

    local humanoidRootPart = game.Players.LocalPlayer.Character.HumanoidRootPart
    local tween = tweenService:Create(humanoidRootPart, tweenInfo, {CFrame = P})

    ActiveTween = tween
    tween:Play()
    task.spawn(function()
        while tween.PlaybackState == Enum.PlaybackState.Playing do task.wait()
            local CurrentDistance = (P.Position - humanoidRootPart.Position).Magnitude
            if CurrentDistance < 5 then
                tween:Cancel()
                humanoidRootPart.CFrame = P
                ActiveTween = nil
                break
            end
        end
    end)

    return tween
end

-------------------------------- Player Modify --------------------------------

local PlayerModify = Tabs.Main:Section({ Title = "Player Modify" })

local oldGetAttribute
local oldNamecall
local InfAmmoChecking
local NoRecoilChecking

local DashNoCooldown = Tabs.Main:Toggle({
    Title = "DashNoCooldown",
    Value = _G.Settings.Main.PlayerModify.DashNoCooldown,
    Icon = "check",
    Callback = function(Cooldown)
        _G.Settings.Main.PlayerModify.DashNoCooldown = Cooldown
        SaveSetting()

        if not oldGetAttribute then
            oldGetAttribute = hookmetamethod(game, "__namecall", function(self, ...)
                local args = {...}
                if getnamecallmethod() == "GetAttribute" and args[1] == "DashStamina" then
                    if _G.Settings.Main.PlayerModify.DashNoCooldown then
                        return 100
                    end
                end
                return oldGetAttribute(self, ...)
            end)
        end
    end
})

local AttackNoCooldown = Tabs.Main:Toggle({
    Title = "AttackNoCooldown",
    Value = _G.Settings.Main.PlayerModify.AttackNoCooldown,
    Icon = "check",
    Callback = function(Cooldown)
        _G.Settings.Main.PlayerModify.AttackNoCooldown = Cooldown
        SaveSetting()

        if not oldNamecall then
            local mt = getrawmetatable(game)
            setreadonly(mt, false)
    
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local args = {...}
                local method = getnamecallmethod()
    
                if _G.Settings.Main.PlayerModify.AttackNoCooldown and method == "GetAttribute" and args[1] == "FireRate" then
                    if math.random(1, 100) > 5 then
                        return 900 
                    else
                        return oldNamecall(self, ...)
                    end
                end
    
                return oldNamecall(self, ...)
            end)
    
            setreadonly(mt, true)
        end
    end
})

local InfAmmo = Tabs.Main:Toggle({
    Title = "InfAmmo",
    Value = _G.Settings.Main.PlayerModify.InfAmmo,
    Icon = "check",
    Callback = function(Cooldown)
        _G.Settings.Main.PlayerModify.InfAmmo = Cooldown
        SaveSetting()

        if not InfAmmoChecking then
            local mt = getrawmetatable(game)
            setreadonly(mt, false)
    
            InfAmmoChecking = hookmetamethod(game, "__namecall", function(self, ...)
                local args = {...}
                local method = getnamecallmethod()
    
                if _G.Settings.Main.PlayerModify.InfAmmo and method == "GetAttribute" and args[1] == "Ammo" then
                    return 200000 
                end
    
                if _G.Settings.Main.PlayerModify.InfAmmo and method == "GetAttribute" and args[1] == "MaxAmmo" then
                    return 2000 
                end
    
                return InfAmmoChecking(self, ...)
            end)
    
            setreadonly(mt, true)
        end
    end
})

local NoRecoil = Tabs.Main:Toggle({
    Title = "NoRecoil",
    Value = _G.Settings.Main.PlayerModify.NoRecoil,
    Icon = "check",
    Callback = function(Cooldown)
        _G.Settings.Main.PlayerModify.NoRecoil = Cooldown
        SaveSetting()

        if not NoRecoilChecking then
            local mt = getrawmetatable(game)
            setreadonly(mt, false)
    
            NoRecoilChecking = hookmetamethod(game, "__namecall", function(self, ...)
                local args = {...}
                local method = getnamecallmethod()
    
                if attackNoCooldownEnabled and method == "GetAttribute" and args[1] == "Recoil" then
                    return CFrame.new(0,0,0) 
                end
    
                return NoRecoilChecking(self, ...)
            end)
    
            setreadonly(mt, true)
        end
    end
})

local DeleteAmmoGUI = Tabs.Main:Button({
    Title = "DeleteAmmoGUI",
    Callback = function()
        game:GetService("Players").LocalPlayer.PlayerGui.Hotbar.AmmoBar:Destroy()
    end
})

-------------------------------- Aimbot --------------------------------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local FOV_RADIUS = 150
local aimbotEnabled = false
local aimbotNPCEnabled = false
local target = nil
local aimKey = Enum.UserInputType.MouseButton2

function isInFOV(position)
    local mousePos = UserInputService:GetMouseLocation()
    local screenPosition = Vector2.new(position.X, position.Y)
    return (screenPosition - mousePos).Magnitude <= FOV_RADIUS
end

function isEnemy(player)
    if player == LocalPlayer then return false end
    local localTeam = LocalPlayer.Team
    local playerTeam = player.Team

    if not localTeam or not playerTeam then return true end

    if localTeam.Name == "Wizards" or localTeam.Name == "Royal Wizards" then
        return playerTeam.Name == "Shadow Wizards"
    end

    if localTeam.Name == "Shadow Wizards" then
        return true
    end

    return localTeam ~= playerTeam
end

local function getClosestEnemy()
    if not aimbotEnabled then return nil end
    local closestEnemy = nil
    local shortestDistance = FOV_RADIUS

    for _, player in pairs(Players:GetPlayers()) do
        if isEnemy(player) then
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") then
                if character.Humanoid.Health > 0 then
                    local rootPart = character.HumanoidRootPart
                    local rootPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)

                    if onScreen and isInFOV(rootPos) then
                        local distance = (Vector2.new(rootPos.X, rootPos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude

                        if distance < shortestDistance then
                            closestEnemy = rootPart
                            shortestDistance = distance
                        end
                    end
                end
            end
        end
    end

    return closestEnemy
end

local function getClosestNPC()
    if not aimbotNPCEnabled then return nil end
    local closestNPC = nil
    local shortestDistance = FOV_RADIUS

    for _, mission in pairs(workspace.Missions:GetDescendants()) do
        if mission:IsA("Model") and mission:FindFirstChild("HumanoidRootPart") and mission:FindFirstChild("Humanoid") then
            if mission.Humanoid.Health > 0 then
                local rootPart = mission.HumanoidRootPart
                local rootPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)

                if onScreen and isInFOV(rootPos) then
                    local distance = (Vector2.new(rootPos.X, rootPos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude

                    if distance < shortestDistance then
                        closestNPC = rootPart
                        shortestDistance = distance
                    end
                end
            end
        end
    end

    return closestNPC
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.UserInputType == aimKey or input.UserInputType == Enum.UserInputType.Touch then
        aimbotEnabled = _G.Settings.Aimbot.Aimbot
        aimbotNPCEnabled = _G.Settings.Aimbot.AimbotNPC
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == aimKey or input.UserInputType == Enum.UserInputType.Touch then
        aimbotEnabled = false
        aimbotNPCEnabled = false
        target = nil
    end
end)

RunService.RenderStepped:Connect(function()
    if aimbotEnabled or aimbotNPCEnabled then
        if not target or not target.Parent or not isInFOV(Camera:WorldToViewportPoint(target.Position)) then
            target = getClosestEnemy() or getClosestNPC()
        end

        if target then
            local adjustedTargetPosition = target.Position - Vector3.new(0, 1.5, 0)
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, adjustedTargetPosition)
        end
    end
end)

local Aimbot = Tabs.Aimbot:Section({ Title = "Aimbot" })

local EnableAimbot = Tabs.Aimbot:Toggle({
    Title = "Enabled Aimbot",
    Value = _G.Settings.Aimbot.Aimbot,
    Icon = "check",
    Callback = function(state)
        _G.Settings.Aimbot.Aimbot = state
        aimbotEnabled = state
        SaveSetting()
    end
})

local EnableAimbotNPC = Tabs.Aimbot:Toggle({
    Title = "Enabled Aimbot NPC",
    Value = _G.Settings.Aimbot.AimbotNPC,
    Icon = "check",
    Callback = function(state)
        _G.Settings.Aimbot.AimbotNPC = state
        aimbotNPCEnabled = state
        SaveSetting()
    end
})

-------------------------------- Slient Aim --------------------------------

local Camera = workspace.CurrentCamera
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local GetChildren = game.GetChildren
local GetPlayers = Players.GetPlayers
local WorldToScreen = Camera.WorldToScreenPoint
local WorldToViewportPoint = Camera.WorldToViewportPoint
local GetPartsObscuringTarget = Camera.GetPartsObscuringTarget
local FindFirstChild = game.FindFirstChild
local RenderStepped = RunService.RenderStepped
local GuiInset = GuiService.GetGuiInset
local GetMouseLocation = UserInputService.GetMouseLocation

local resume = coroutine.resume 
local create = coroutine.create

local ValidTargetParts = {"Head", "HumanoidRootPart"}
local PredictionAmount = 1

local CoreESP = Instance.new("BillboardGui")
local Text = Instance.new("TextLabel")

CoreESP.Name = "CoreESP"
CoreESP.Parent = game.CoreGui
CoreESP.Active = true
CoreESP.AlwaysOnTop = true
CoreESP.LightInfluence = 1.000
CoreESP.Size = UDim2.new(5, 0, 5, 0)

Text.Name = "Text"
Text.Parent = CoreESP
Text.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Text.BackgroundTransparency = 1.000
Text.BorderColor3 = Color3.fromRGB(27, 42, 53)
Text.Size = UDim2.new(1, 0, 1, 0)
Text.Font = Enum.Font.SourceSansBold
Text.Text = "."
Text.TextColor3 = Color3.fromRGB(255, 0, 0)
Text.TextScaled = true
Text.TextSize = 35.000
Text.TextStrokeTransparency = 0.000
Text.TextWrapped = true
Text.TextYAlignment = Enum.TextYAlignment.Top

local ExpectedArguments = {
    Raycast = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Vector3", "Vector3", "RaycastParams"
        }
    }
}

function CalculateChance(Percentage)
    Percentage = math.floor(Percentage)
    local chance = math.floor(Random.new().NextNumber(Random.new(), 0, 1) * 100) / 100
    return chance <= Percentage / 100
end

local function getPositionOnScreen(Vector)
    local Vec3, OnScreen = WorldToScreen(Camera, Vector)
    return Vector2.new(Vec3.X, Vec3.Y), OnScreen
end

local function ValidateArguments(Args, RayMethod)
    local Matches = 0
    if #Args < RayMethod.ArgCountRequired then
        return false
    end
    for Pos, Argument in next, Args do
        if typeof(Argument) == RayMethod.Args[Pos] then
            Matches = Matches + 1
        end
    end
    return Matches >= RayMethod.ArgCountRequired
end

local function getDirection(Origin, Position)
    return (Position - Origin).Unit * 1000
end

local function IsPlayerVisible(Player)
    local PlayerCharacter = Player.Character
    local LocalPlayerCharacter = LocalPlayer.Character
    
    if not (PlayerCharacter or LocalPlayerCharacter) then return end 
    
    local PlayerRoot = FindFirstChild(PlayerCharacter, _G.Settings.Aimbot.SelientAim.TargetPart) or FindFirstChild(PlayerCharacter, "HumanoidRootPart")
    
    if not PlayerRoot then return end 
    
    local CastPoints, IgnoreList = {PlayerRoot.Position, LocalPlayerCharacter, PlayerCharacter}, {LocalPlayerCharacter, PlayerCharacter}
    local ObscuringObjects = #GetPartsObscuringTarget(Camera, CastPoints, IgnoreList)
    
    return ((ObscuringObjects == 0 and true) or (ObscuringObjects > 0 and false))
end

local AlliedTeams = {
    ["Wizards"] = { "Royal Wizards" },
    ["Royal Wizards"] = { "Wizards" }
}

local function AreAllies(team1, team2)
    if team1 == team2 then
        return true
    end
    local allies = AlliedTeams[team1]
    if allies then
        for _, ally in pairs(allies) do
            if ally == team2 then
                return true
            end
        end
    end
    return false
end

local function getClosestPlayer()
    if not _G.Settings.Aimbot.SelientAim.TargetPart then return end
    local Closest
    local ShortestDistance = math.huge
    for _, Player in next, GetPlayers(Players) do
        if Player == LocalPlayer then continue end
        if _G.Settings.Aimbot.SelientAim.TeamCheck and AreAllies(Player.Team.Name, LocalPlayer.Team.Name) then continue end

        local Character = Player.Character
        if not Character then continue end
        
        if _G.Settings.Aimbot.SelientAim.VisibleCheck and not IsPlayerVisible(Player) then continue end

        local HumanoidRootPart = FindFirstChild(Character, "HumanoidRootPart")
        local Humanoid = FindFirstChild(Character, "Humanoid")
        if not HumanoidRootPart or not Humanoid or Humanoid and Humanoid.Health <= 0 then continue end

        local Distance = (LocalPlayer.Character.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
        if Distance < ShortestDistance then
            Closest = ((_G.Settings.Aimbot.SelientAim.TargetPart == "Random" and Character[ValidTargetParts[math.random(1, #ValidTargetParts)]]) or Character[_G.Settings.Aimbot.SelientAim.TargetPart])
            ShortestDistance = Distance
        end
    end
    return Closest
end

local SlientAim = Tabs.Aimbot:Section({ Title = "Slient Aim" })

local EnabledSlientAim = Tabs.Aimbot:Toggle({
    Title = "Enabled",
    Value = _G.Settings.Aimbot.SelientAim.EnableSilent,
    Icon = "check",
    Callback = function(value)
        _G.Settings.Aimbot.SelientAim.EnableSilent = value
        SaveSetting()
    end
})

local TeamCheckSlientAim = Tabs.Aimbot:Toggle({
    Title = "Team Check",
    Value = _G.Settings.Aimbot.SelientAim.TeamCheck,
    Icon = "check",
    Callback = function(value)
        _G.Settings.Aimbot.SelientAim.TeamCheck = value
        SaveSetting()
    end
})

local VisibleCheckSlientAim = Tabs.Aimbot:Toggle({
    Title = "Visible Check",
    Value = _G.Settings.Aimbot.SelientAim.VisibleCheck,
    Icon = "check",
    Callback = function(value)
        _G.Settings.Aimbot.SelientAim.VisibleCheck = value
        SaveSetting()
    end
})

local TargetPartSlientAim = Tabs.Aimbot:Dropdown({
    Title = "Target Part",
    Values = {"Random", "Head", "HumanoidRootPart"},
    Value = _G.Settings.Aimbot.SelientAim.TargetPart,
    AllowNone = true,
    Callback = function(value)
        _G.Settings.Aimbot.SelientAim.TargetPart = value
        SaveSetting()
    end
})

local ShowTargetSlientAim = Tabs.Aimbot:Toggle({
    Title = "Show Target",
    Value = _G.Settings.Aimbot.SelientAim.ShowTarget,
    Icon = "check",
    Callback = function(value)
        CoreESP.Enabled = value
        _G.Settings.Aimbot.SelientAim.ShowTarget = value
        SaveSetting()
    end
})

resume(create(function()
    RenderStepped:Connect(function()
        if _G.Settings.Aimbot.SelientAim.ShowTarget and _G.Settings.Aimbot.SelientAim.EnableSilent then
            local closestPlayer = getClosestPlayer()
            if closestPlayer then 
                local Root = closestPlayer.Parent.PrimaryPart or closestPlayer
                local RootToViewportPoint, IsOnScreen = WorldToViewportPoint(Camera, Root.Position)
                
                if IsOnScreen then
                    CoreESP.Enabled = true
                    CoreESP.Adornee = Root
                else 
                    CoreESP.Enabled = false 
                end
            else 
                CoreESP.Enabled = false 
            end
        end
    end)
end))

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local Method = getnamecallmethod()
    local Arguments = {...}
    local self = Arguments[1]
    local chance = CalculateChance(_G.Settings.Aimbot.SelientAim.HitChance)
    if _G.Settings.Aimbot.SelientAim.EnableSilent and self == workspace and not checkcaller() and chance == true then
        if Method == "Raycast" then
            if ValidateArguments(Arguments, ExpectedArguments.Raycast) then
                local A_Origin = Arguments[2]

                local HitPart = getClosestPlayer()
                if HitPart then
                    Arguments[3] = getDirection(A_Origin, HitPart.Position)

                    return oldNamecall(unpack(Arguments))
                end
            end
        end
    end
    return oldNamecall(...)
end))

local oldIndex = nil 
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, Index)
    if self == Mouse and not checkcaller() and _G.Settings.Aimbot.SelientAim.EnableSilent and _G.Settings.Aimbot.SelientAim.TargetPart == "Mouse.Hit/Target" and getClosestPlayer() then
        local HitPart = getClosestPlayer()
        
        if Index == "Target" or Index == "target" then 
            return HitPart
        elseif Index == "Hit" or Index == "hit" then 
            return ((_G.Settings.Aimbot.SelientAim.MouseHitPrediction and (HitPart.CFrame + (HitPart.Velocity * PredictionAmount))) or (not _G.Settings.Aimbot.SelientAim.MouseHitPrediction and HitPart.CFrame))
        elseif Index == "X" or Index == "x" then 
            return self.X 
        elseif Index == "Y" or Index == "y" then 
            return self.Y 
        elseif Index == "UnitRay" then 
            return Ray.new(self.Origin, (self.Hit - self.Origin).Unit)
        end
    end

    return oldIndex(self, Index)
end))

-------------------------------- Configuration --------------------------------

Tabs.Configuration:Section({ Title = "Interface Settings" })

local themeValues = {}
for name, _ in pairs(WindUI:GetThemes()) do
    table.insert(themeValues, name)
end

local themeDropdown = Tabs.Configuration:Dropdown({
    Title = "Select Theme",
    Multi = false,
    AllowNone = false,
    Value = _G.ConfigurationTable.Themes,
    Values = themeValues,
    Callback = function(theme)
        _G.ConfigurationTable.Themes = theme
        saveConfiguration()
        WindUI:SetTheme(theme)
    end
})

themeDropdown:Select(WindUI:GetCurrentTheme())

local ToggleTransparency = Tabs.Configuration:Toggle({
    Title = "Toggle Window Transparency",
    Value = _G.ConfigurationTable.Transparent,
    Icon = "check",
    Callback = function(e)
        _G.ConfigurationTable.Transparent = e
        saveConfiguration()
        Window:ToggleTransparency(e)
    end,
    Value = WindUI:GetTransparency()
})

local AntiAFK = Tabs.Configuration:Toggle({
    Title = "Anti-AFK",
    Value = _G.ConfigurationTable.AntiAFK,
    Icon = "check",
    Callback = function(enabled)
        local VirtualUser = game:service('VirtualUser')
        local antiAfkConnection = nil

        _G.ConfigurationTable.AntiAFK = enabled
        saveConfiguration()

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
    Value = _G.ConfigurationTable.AutoExecutor,
    Icon = "check",
    Callback = function(Value)
        _G.ConfigurationTable.AutoExecutor = Value
        saveConfiguration()
    end
})

local MinimizeBind = Tabs.Configuration:Keybind({
    Title = "Minimize Bind",
    Value = _G.ConfigurationTable.MinimizeBind,
    Callback = function(v)
        _G.ConfigurationTable.MinimizeBind = v
        saveConfiguration()
        Window:SetToggleKey(Enum.KeyCode[v])
    end
})

local queueteleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
local TeleportCheck = false

while not Players.LocalPlayer do task.wait() end

LocalPlayer.OnTeleport:Connect(function(State)
    pcall(function()
        if _G.ConfigurationTable and _G.ConfigurationTable.AutoExecutor and (not TeleportCheck) and queueteleport then
            TeleportCheck = true
            queueteleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/x2Kotaro/Venuz-hub/main/Loader.lua'))()")
        end
    end)
end)

Window:SetToggleKey(Enum.KeyCode[_G.ConfigurationTable.MinimizeBind])
Window:SelectTab(1)

WindUI:Notify({
    Title = "Script | Loader",
    Content = "Script Loader Successfully",
    Icon = VenuzIcon,
    Duration = 5,
})

local TweenService = game:GetService("TweenService")

local function tweenButton(button, targetSize, duration)
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(button, tweenInfo, {Size = targetSize})
    tween:Play()
end

if UserInputService.TouchEnabled then
    local ScreenGui = Instance.new("ScreenGui")
    local ImageButton = Instance.new("ImageButton")
    local UICorner = Instance.new("UICorner")

    ScreenGui.Parent = game:GetService("CoreGui"):FindFirstChild("WindUI")
    ScreenGui.Name = "Venuz-Toggle"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    ImageButton.Parent = ScreenGui
    ImageButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ImageButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ImageButton.BorderSizePixel = 0
    ImageButton.Position = UDim2.new(0.155857742, 0, 0.213838667, 0)
    ImageButton.Size = UDim2.new(0, 50, 0, 50)
    ImageButton.Image = "http://www.roblox.com/asset/?id=72281500336017"

    UICorner.Parent = ImageButton

    ImageButton.MouseButton1Click:Connect(function()
        tweenButton(ImageButton, UDim2.new(0, 42, 0, 42), 0.05)
        task.delay(0.05, function()
            tweenButton(ImageButton, UDim2.new(0, 50, 0, 50), 0.1)
        end)

        local Frame = game:GetService("CoreGui"):FindFirstChild("WindUI")
            and game:GetService("CoreGui").WindUI:FindFirstChild("Window")
            and game:GetService("CoreGui").WindUI.Window:FindFirstChild("Frame")
        
        if Frame and Frame.Visible then
            Window:Close()()
        else
            Window:Open()
        end
    end)

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