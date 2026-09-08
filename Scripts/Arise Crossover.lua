local NotificationLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/IceMinisterq/Notification-Library/Main/Library.lua"))()

if game:GetService("CoreGui"):FindFirstChild("WindUI") then
    return
    NotificationLibrary:SendNotification("Info", "You already have a script.", 3)
end

_G.ConfigurationTable = {}
_G.Settings = {}

local FolderConfiguration = "Venuz Hub"
local FolderSettings = "Venuz Hub/Arise Crossover"
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local chr = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local hrp = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
local HttpService = game:GetService("HttpService")
local VenuzIcon = "rbxassetid://92691624917972"
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local filenameConfiguration = FolderConfiguration .. "/" .. "Setting" .. ".json"
local filenameSetting = FolderSettings .. "/" .. "AriseCrossover_".. LocalPlayer.Name .. ".json"

--------------------------- Configuration ---------------------------

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
            ["AutoFarm"] = {
                ["AutoFarmEnemie"] = false,
                ["KillAura"] = false,
                ["AutoFarmNearest"] = false,
                ["Distance"] = 500,
            },
            ["Storage"] = {
                ["CollectMode"] = "Arise",
                ["AutoCollect"] = true,
            },
            ["Shadows"] = {
                ["DistanceTarget"] = 25,
                ["SelectShadowsMode"] = "Nearest Enemy",
                ["SelectShadowsTable"] = {},
                ["AutosendShadow"] = false,
            },
            ["Mount"] = {
                ["AutoFarmMounts"] = false,
                ["SelectModeMounts"] = "In Server",
                ["SendNotifyMount"] = false,
                ["UrlWebhook"] = "",
            },
            ["Dungeon"] = {
                ["AutofindDungeon"] = false,
                ["SelectModeDungeon"] = "In Server",
                ["listDungeon"] = {
                    ["Leveling City"] = {},
                    ["Grass Village"] = {},
                    ["Brum Island"] = {},
                    ["Lucky Kingdom"] = {},
                    ["Faceheal Town"] = {},
                    ["Dragon City"] = {},
                    ["Chainsaw Man"] = {},
                },
                ["TeleportSelect"] = nil
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
        if _G.Settings[key] ~= nil then
            _G.Settings[key] = value
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
    Automatic = Window:Tab({ Title = "Automatic", Icon = "code-xml" }),
    Dungeon = Window:Tab({ Title = "Dungeon", Icon = "swords" }),
    Teleport = Window:Tab({ Title = "Teleport", Icon = "tree-palm" }),
    Webhook = Window:Tab({ Title = "Webhook", Icon = "send" }),
    divider1 = Window:Divider(),
    Configuration = Window:Tab({ Title = "Configuration", Icon = "settings", Desc = "Manage window settings and themes.", ShowTabTitle = true}),
}

-------------------------------- Funtion --------------------------------

function Hopserver()
    local TPS = game:GetService("TeleportService")
    local Api = "https://games.roblox.com/v1/games/"

    local _place,_id = game.PlaceId, game.JobId
    local _servers = Api.._place.."/servers/Public?sortOrder=Asc&limit=10"
    function ListServers(cursor)
        local Raw = game:HttpGet(_servers .. ((cursor and "&cursor="..cursor) or ""))
        return HttpService:JSONDecode(Raw)
    end

    time_to_wait = 1

    while wait(time_to_wait) do
        LocalPlayer.Character.HumanoidRootPart.Anchored = true
        local Servers = ListServers()
        local Server = Servers.data[math.random(1,#Servers.data)]
        TPS:TeleportToPlaceInstance(_place, Server.id, LocalPlayer)
    end
end

function SendMessageEMBED(url, embed)
    local headers = {
        ["Content-Type"] = "application/json"
    }
    local data = {
        ["embeds"] = {
            {
                ["title"] = embed.title,
                ["description"] = embed.description,
                ["color"] = embed.color,
                ["fields"] = embed.fields,
                ["footer"] = {
                    ["text"] = embed.footer.text
                }
            }
        }
    }
    local body = HttpService:JSONEncode(data)
    local response = request({
        Url = url,
        Method = "POST",
        Headers = headers,
        Body = body
    })
end

function teleportPlayer(position, delay)
    local startTime = tick()

    while tick() - startTime < delay do
        task.wait()

        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local rootPart = character:FindFirstChild("HumanoidRootPart")

        while not rootPart do
            character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            rootPart = character:FindFirstChild("HumanoidRootPart")
            task.wait()
        end

        if rootPart then
            if typeof(position) == "CFrame" then
                rootPart.CFrame = position
            elseif typeof(position) == "table" and #position == 3 then
                rootPart.CFrame = CFrame.new(unpack(position))
            end
        end
    end
end

function getRootPart()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

-------------------------------- AutoFarm --------------------------------

local AutoFarmSection = Tabs.Automatic:Section({ Title = "↪ Auto Farm" })

local Enemies = {}
local addedNames = {}

function UpdateEnemies()
    local foundEnemies = {}
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")

    for _, enemy in ipairs(workspace.__Main.__Enemies.Client:GetChildren()) do
        local hitbox = enemy:FindFirstChild("Hitbox")
        local title = enemy.HealthBar.Main.Title

        if hitbox and title then
            local distance = (rootPart.Position - hitbox.Position).Magnitude
            if distance <= 1000 then
                local name = title.Text
                if not addedNames[name] then
                    table.insert(Enemies, name)
                    addedNames[name] = true
                end
                foundEnemies[name] = true
            end
        end
    end

    for i = #Enemies, 1, -1 do
        local enemyName = Enemies[i]
        if not foundEnemies[enemyName] then
            table.remove(Enemies, i)
            addedNames[enemyName] = nil
        end
    end
end

UpdateEnemies()

local SelectEnemies = Tabs.Automatic:Dropdown({
    Title = "Select Enemies",
    Values = Enemies,
    Multi = true,
    Value = {},
    AllowNone = true,
    Callback = function(Value)
        SelectEnemiesTable = Value
    end
})

local AutoFarmEnemie = Tabs.Automatic:Toggle({
    Title = "Auto Farm",
    Value = _G.Settings.AutoFarm.AutoFarmEnemie,
    Icon = "check",
    Callback = function(Mon)
        _G.Settings.AutoFarm.AutoFarmEnemie = Mon
        SaveSetting()

        if Mon then
            task.spawn(function()
                pcall(function()
                    while _G.Settings.AutoFarm.AutoFarmEnemie do
                        task.wait(0.4)
    
                        local rootPart = getRootPart()
                        if not rootPart then continue end
    
                        if not SelectEnemiesTable or #SelectEnemiesTable == 0 then
                            return
                        end
    
                        local nearestEnemy = nil
                        local nearestDistance = 1000
                        local enemiesClient = workspace:FindFirstChild("__Main") and workspace.__Main:FindFirstChild("__Enemies") and workspace.__Main.__Enemies:FindFirstChild("Client")

                        if enemiesClient then
                            for _, v in pairs(enemiesClient:GetDescendants()) do
                                if v.Name == "Title" and v:IsA("TextLabel") then
                                    local enemyName = v.Text
                                    if table.find(SelectEnemiesTable, enemyName) then
                                        local enemy = v.Parent
                                        while enemy and not enemy:IsA("Model") do
                                            enemy = enemy.Parent
                                        end
    
                                        if enemy and enemy:FindFirstChild("Hitbox") then
                                            local healthAmount = enemy:FindFirstChild("HealthBar") and enemy.HealthBar.Main.Bar.Amount.Text or "0 HP"
                                            if healthAmount ~= "0 HP" then
                                                local enemyPos = enemy.Hitbox.Position
                                                local distance = (enemyPos - rootPart.Position).Magnitude
    
                                                if distance < nearestDistance then
                                                    nearestEnemy = enemy
                                                    nearestDistance = distance
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
    
                        if nearestEnemy then
                            repeat
                                task.wait()
                                teleportPlayer(nearestEnemy.Hitbox.CFrame * CFrame.new(5, 0, 0), 1)
                                rootPart.Velocity = Vector3.new(0, 0, 0)
                            until (nearestEnemy:FindFirstChild("HealthBar") and nearestEnemy.HealthBar.Main.Bar.Amount.Text == "0 HP") or _G.Settings.AutoFarm.AutoFarmEnemie == false
                        end
                    end
                end)
            end)
        end
    end
})

local nearestEnemy = nil

function getNearestEnemy()
    local shortestDistance = 20
    local foundEnemy = nil

    if not game.Players.LocalPlayer.Character or not game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        shortestDistance = 20
        foundEnemy = nil
        return nil
    end

    for _, enemy in pairs(workspace.__Main.__Enemies.Client:GetChildren()) do
        if enemy:FindFirstChild("Hitbox") then
            local distance = (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - enemy.Hitbox.Position).Magnitude
            if distance <= shortestDistance then
                shortestDistance = distance
                foundEnemy = enemy
            end
        end
    end

    nearestEnemy = foundEnemy
    return nearestEnemy
end

local KillAura = Tabs.Automatic:Toggle({
    Title = "Kill Aura",
    Value = _G.Settings.AutoFarm.KillAura,
    Icon = "check",
    Callback = function(Value)
        _G.Settings.AutoFarm.KillAura = Value
        SaveSetting()

        if Value then
            task.spawn(function()
                pcall(function()
                    while _G.Settings.AutoFarm.KillAura do task.wait()
                        local Target = getNearestEnemy()
                        if Target then
                            local args = {
                                {
                                    {
                                        Event = "PunchAttack",
                                        Enemy = Target.Name
                                    },
                                    "\004"
                                }
                            }
                            game:GetService("ReplicatedStorage"):WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent"):FireServer(unpack(args))                                               
                    end
                end
                end)
            end)
        end
    end
})

task.spawn(function()
    pcall(function()
        while task.wait(1) do
            UpdateEnemies()
            if SelectEnemies then
                SelectEnemies:Refresh(Enemies)
            end
        end
    end)
end)

-------------------------------- AutoFarm Nearest --------------------------------

local AutoFarmNearest = Tabs.Automatic:Section({ Title = "↪ Auto Farm Nearest" })

local AutoFarmMobNearest = Tabs.Automatic:Toggle({
    Title = "Auto Farm Mob Nearest",
    Value = _G.Settings.AutoFarm.AutoFarmNearest,
    Icon = "check",
    Callback = function(enabled)
        _G.Settings.AutoFarm.AutoFarmNearest = enabled
        SaveSetting()

        if enabled then
            task.spawn(function()
                pcall(function()
                    while _G.Settings.AutoFarm.AutoFarmNearest do task.wait(0.4)
    
                        local rootPart = getRootPart()
                        if not rootPart then continue end
    
                        local maxDistance = _G.Settings.AutoFarm.Distance
                        local nearestEnemy = nil
                        local nearestDistance = maxDistance
    
                        local enemiesClient = workspace:FindFirstChild("__Main") and workspace.__Main:FindFirstChild("__Enemies") and workspace.__Main.__Enemies:FindFirstChild("Client")
    
                        if enemiesClient then
                            for _, v in pairs(enemiesClient:GetDescendants()) do
                                if v.Name == "Title" and v:IsA("TextLabel") then
                                    local enemy = v.Parent
                                    while enemy and not enemy:IsA("Model") do
                                        enemy = enemy.Parent
                                    end
    
                                    if enemy and enemy:FindFirstChild("Hitbox") then
                                        local healthAmount = enemy:FindFirstChild("HealthBar") and enemy.HealthBar.Main.Bar.Amount.Text or "0 HP"
                                        if healthAmount ~= "0 HP" then
                                            local enemyPos = enemy.Hitbox.Position
                                            local distance = (enemyPos - rootPart.Position).Magnitude
    
                                            if distance <= maxDistance and distance < nearestDistance then
                                                nearestEnemy = enemy
                                                nearestDistance = distance
                                            end
                                        end
                                    end
                                end
                            end
                        end
    
                        if nearestEnemy then
                            repeat
                                task.wait()
                                teleportPlayer(nearestEnemy.Hitbox.CFrame * CFrame.new(5, 0, 0), 1)
                                rootPart.Velocity = Vector3.new(0, 0, 0)
                            until (nearestEnemy:FindFirstChild("HealthBar") and nearestEnemy.HealthBar.Main.Bar.Amount.Text == "0 HP") or _G.Settings.AutoFarm.AutoFarmNearest == false
                        end
                    end
                end)
            end)
        end
    end
})

local Distance = Tabs.Automatic:Slider({
    Title = "Distance",
    Value = {
        Min = 200,
        Max = 3000,
        Default = _G.Settings.AutoFarm.Distance
    },
    Callback = function(v)
        _G.Settings.AutoFarm.Distance = v
        SaveSetting()
    end
})

-------------------------------- Arise Collet --------------------------------

local Storage = Tabs.Automatic:Section({ Title = "↪ Collect" })

local CollectMode = Tabs.Automatic:Dropdown({
    Title = "Collect Mode",
    Values = {"Arise","Destroy"},
    Value = _G.Settings.Storage.CollectMode,
    Callback = function(Arise)
        _G.Settings.Storage.CollectMode = Arise
        SaveSetting()
    end
})

local EnableCollectMode = Tabs.Automatic:Toggle({
    Title = "Enable Collect Mode",
    Value = _G.Settings.Storage.AutoCollect,
    Icon = "check",
    Callback = function(AutoCollect)
        _G.Settings.Storage.AutoCollect = AutoCollect
        SaveSetting()

        task.spawn(function()
            pcall(function()
                while _G.Settings.Storage.AutoCollect do task.wait(0.5)
                    if _G.Settings.Storage.CollectMode == "Arise" then
                        for i,v in pairs(workspace.__Main.__Enemies.Client:GetDescendants()) do
                            if v.Name == "ArisePrompt" then
                                local args = {
                                    {
                                        {
                                            Event = "EnemyCapture",
                                            Enemy = v.Parent.Parent.Name
                                        },
                                        "\004"
                                    }
                                }

                                game:GetService("ReplicatedStorage"):WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent"):FireServer(unpack(args))
                            end
                        end
                    elseif _G.Settings.Storage.CollectMode == "Destroy" then
                        for i,v in pairs(workspace.__Main.__Enemies.Client:GetDescendants()) do
                            if v.Name == "DestroyPrompt" then
                                local args = {
                                    {
                                        {
                                            Event = "EnemyDestroy",
                                            Enemy = v.Parent.Parent.Name
                                        },
                                        "\004"
                                    }
                                }

                                game:GetService("ReplicatedStorage"):WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent"):FireServer(unpack(args))
                            end
                        end
                    end
                end
            end)
        end)
    end
})

-------------------------------- Shadows --------------------------------

local ShadowSection = Tabs.Automatic:Section({ Title = "↪ Shadows" })

local SelectMon

local ShadowsMode = Tabs.Automatic:Dropdown({
    Title = "Select Mode",
    Values = {"Select Enemy", "Nearest Enemy"},
    Value = _G.Settings.Shadows.SelectShadowsMode,
    Callback = function(Value)
        _G.Settings.Shadows.SelectShadowsMode = Value
        SaveSetting()

        if Value == "Nearest Enemy" then
            SelectMon:Lock()
        elseif Value == "Select Enemy" then
            SelectMon:Unlock()
        end
    end
})

SelectMon = Tabs.Automatic:Dropdown({
    Title = "Select Enemy",
    Values = Enemies,
    Multi = true,
    Value = _G.Settings.Shadows.SelectShadowsTable,
    Callback = function(Value)
        _G.Settings.Shadows.SelectShadowsTable = Value
    end
})

local AutosendShadow = Tabs.Automatic:Toggle({
    Title = "AutoSend Shadow",
    Value = _G.Settings.Shadows.AutosendShadow,
    Icon = "check",
    Callback = function(Mon)
        _G.Settings.Shadows.AutosendShadow = Mon
        SaveSetting()

        local nearestDistance = _G.Settings.Shadows.DistanceTarget
        local nearestEnemy = nil
    
        if Mon then
            task.spawn(function()
                while _G.Settings.Shadows.AutosendShadow do task.wait(0.5)
                    if not game.Players.LocalPlayer.Character or not game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        nearestDistance = math.huge
                        nearestEnemy = nil
                        return
                    end
    
                    local rootPart = game.Players.LocalPlayer.Character.HumanoidRootPart
                    local success, pets = pcall(function()
                        return workspace.__Main.__Pets[player.UserId]:GetDescendants()
                    end)
    
                    local hasTarget = false
                    for i, v in pairs(workspace.__Main.__Pets[game.Players.LocalPlayer.UserId]:GetDescendants()) do
                        if v:GetAttribute("Target") then
                            hasTarget = true
                            break
                        end
                    end
    
                    if success and pets then
                        for i, v in pairs(pets) do
                            if v:GetAttribute("Target") then
                                hasPets = true
                                break
                            end
                        end
                    end
    
                    pcall(function()
                        if not hasTarget or not rootPart then
                            nearestDistance = _G.Settings.Shadows.DistanceTarget
                            nearestEnemy = nil
                            
                            if _G.Settings.Shadows.SelectShadowsMode == "Select Enemy" then
                                if not _G.Settings.Shadows.SelectShadowsTable or #_G.Settings.Shadows.SelectShadowsTable == 0 then
                                    return
                                end
    
                                for i, v in pairs(workspace.__Main.__Enemies.Client:GetDescendants()) do
                                    if v.Name == "Title" and v:IsA("TextLabel") then
                                        local enemyName = v.Text
                                        if table.find(_G.Settings.Shadows.SelectShadowsTable, enemyName) then
                                            local enemy = v.Parent
                                            while enemy and not enemy:IsA("Model") do
                                                enemy = enemy.Parent
                                            end
    
                                            if enemy and enemy:FindFirstChild("Hitbox") then
                                                local enemyPos = enemy.Hitbox.Position
                                                local distance = (enemyPos - rootPart.Position).Magnitude
                                                if distance < nearestDistance then
                                                    nearestDistance = distance
                                                    nearestEnemy = enemy
                                                end
                                            end
                                        end
                                    end
                                end
    
                                if nearestEnemy then
                                    local healthAmount = nearestEnemy:FindFirstChild("HealthBar") and nearestEnemy.HealthBar.Main.Bar.Amount.Text or "0 HP"
                                    if healthAmount ~= "0 HP" then
                                        local Pets = game:GetService("Players").LocalPlayer.leaderstats.Equips.Pets:GetAttributes()
                                        local validValues = { "\5", "\t", "\4", "\n", "\8" }
                                        for key, value in pairs(Pets) do
                                            for i, v in ipairs(validValues) do
                                                local args = {
                                                    [1] = {
                                                        [1] = {
                                                            ["PetPos"] = {
                                                                [value] = nearestEnemy.Hitbox.CFrame
                                                            },
                                                            ["AttackType"] = "All",
                                                            ["Event"] = "Attack",
                                                            ["Enemy"] = nearestEnemy.Name
                                                        },
                                                        [2] = v
                                                    }
                                                }
                                                game:GetService("ReplicatedStorage").BridgeNet2.dataRemoteEvent:FireServer(unpack(args))
                                            end
                                        end
                                    end
                                end
    
                            elseif _G.Settings.Shadows.SelectShadowsMode == "Nearest Enemy" then
                                for i, v in pairs(workspace.__Main.__Enemies.Client:GetDescendants()) do
                                    if v.Name == "Title" and v:IsA("TextLabel") then
                                        local enemy = v.Parent
                                        while enemy and not enemy:IsA("Model") do
                                            enemy = enemy.Parent
                                        end
    
                                        if enemy and enemy:FindFirstChild("Hitbox") then
                                            local healthAmount = enemy:FindFirstChild("HealthBar") and enemy.HealthBar.Main.Bar.Amount.Text or "0 HP"
                                            if healthAmount ~= "0 HP" then
                                                local enemyPos = enemy.Hitbox.Position
                                                local distance = (enemyPos - rootPart.Position).Magnitude
                                                
                                                if distance < nearestDistance then
                                                    nearestDistance = distance
                                                    nearestEnemy = enemy
                                                end
                                            end
                                        end
                                    end
                                end
    
                                if nearestEnemy then
                                    local Pets = game:GetService("Players").LocalPlayer.leaderstats.Equips.Pets:GetAttributes()
                                    
                                    local validValues = { "\5", "\t", "\4", "\n", "\8" }
    
                                    for key, value in pairs(Pets) do
                                        for i, v in ipairs(validValues) do
                                        local args = {
                                            [1] = {
                                                [1] = {
                                                    ["PetPos"] = {
                                                        [value] = nearestEnemy.Hitbox.CFrame
                                                    },
                                                    ["AttackType"] = "All",
                                                    ["Event"] = "Attack",
                                                    ["Enemy"] = nearestEnemy.Name
                                                },
                                                [2] = v
                                            }
                                        }
                                        game:GetService("ReplicatedStorage").BridgeNet2.dataRemoteEvent:FireServer(unpack(args))
                                       end
                                    end
                                end
                            end
                        end
                    end)
                end
            end)
        end
    end
})

local DistanceTarget = Tabs.Automatic:Slider({
    Title = "Distance",
    Default = _G.Settings.Shadows.DistanceTarget,
    Value = {
        Min = 25,
        Max = 100,
        Default = _G.Settings.Shadows.DistanceTarget
    },
    Callback = function(v)
        _G.Settings.Shadows.DistanceTarget = v
        SaveSetting()
    end
})

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(2)
    if _G.Settings.AutoFarm then
        AutoFarmEnemie:Fire(_G.Settings.AutoFarm.AutoFarm)
    end
end)

if _G.Settings.Shadows.SelectShadowsMode == "Nearest Enemy" then
    SelectMon:Lock()
else
    SelectMon:Unlock()
end

task.spawn(function()
    pcall(function()
        while task.wait(1) do
            UpdateEnemies()
            if SelectMon then
                SelectMon:Refresh(Enemies)
            end
        end
    end)
end)

-------------------------------- Mount --------------------------------

local AutoMounts = Tabs.Automatic:Section({ Title = "↪ Auto Mounts" })

local SelectMode = Tabs.Automatic:Dropdown({
    Title = "Select Mode",
    Values = {"In Server", "HopServer"},
    Value = _G.Settings.Mount.SelectModeMounts,
    Callback = function(Value)
        _G.Settings.Mount.SelectModeMounts = Value
        SaveSetting()
    end
})

local previousPosition = nil

local locations = {
    CFrame.new(-6167, 135, 5532),
    CFrame.new(-5858, 81, 389),
    CFrame.new(-5431, 107, -5502),
    CFrame.new(-691, 108, -3556),
    CFrame.new(4323, 119, -4811),
    CFrame.new(3315, 83, 18),
    CFrame.new(466, 118, 3438)
}

local AutoFarmMounts = Tabs.Automatic:Toggle({
    Title = "AutoMounts",
    Value = _G.Settings.Mount.AutoFarmMounts,
    Icon = "check",
    Callback = function(Mounts)
        _G.Settings.Mount.AutoFarmMounts = Mounts
        SaveSetting()

        local CheckMount = false

        if Mounts then
            previousPosition = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
            task.spawn(function()
                pcall(function()
                    if _G.Settings.Mount.SelectModeMounts == "In Server" then
                        while _G.Settings.Mount.AutoFarmMounts do task.wait(0.5)
                        for _, location in ipairs(locations) do
                            if not _G.Settings.Mount.AutoFarmMounts then
                                teleportPlayer(previousPosition,1)
                                return
                            end
                            teleportPlayer(location,1)
                            for _, mount in pairs(workspace.__Extra.__Appear:GetChildren()) do
                                CheckMount = false
                                for _, owned in pairs(game:GetService("Players").LocalPlayer.leaderstats.Inventory.Mounts:GetChildren()) do
                                    if owned.Name:lower():find(mount.Name:lower()) then
                                        CheckMount = true
                                        WindUI:Notify({
                                            Title = "Venuz | Notify",
                                            Content = "You already have Mount : "..mount.Name,
                                            Icon = VenuzIcon,
                                            Duration = 2.5
                                        })
                                        break
                                    end
                                end
                                if not CheckMount then
                                local mountPosition = mount:GetPivot()
                                teleportPlayer(mountPosition,1)
                                task.wait(2.5)
                                game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
                                task.wait(1)
                                game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
                                local enbedmount = {
                                    ["title"] = "**Mount Collected!**",
                                    ["description"] = "```lua\nSuccessfully collected the mount: "..mount.Name.."```",
                                    ["color"] = 65280,
                                    ["fields"] = {
                                        {
                                            ["name"] = "**Mount Name**",
                                            ["value"] = "```"..mount.Name.."```",
                                            ["inline"] = true
                                        },
                                        {
                                            ["name"] = "**Time Collected**",
                                            ["value"] = "```"..os.date("%Y-%m-%d %H:%M:%S").."```",
                                            ["inline"] = true
                                        }
                                    },
                                    ["footer"] = {
                                        ["text"] = "Sent by Venuz Mount Collector Bot"
                                    }
                                }
                                if _G.Settings.Mount.SendNotifyMount then
                                SendMessageEMBED(_G.Settings.Mount.UrlWebhook, enbedmount)
                                end
                            end
                            end
                        end
                    end
                    elseif _G.Settings.Mount.SelectModeMounts == "HopServer" then
                        for _, location in ipairs(locations) do
                            if  not _G.Settings.Mount.AutoFarmMounts then
                                teleportPlayer(previousPosition, 1)
                                return
                            end
                            teleportPlayer(location, 1)
                            task.wait(1)
                            for _, mount in pairs(workspace.__Extra.__Appear:GetChildren()) do
                                CheckMount = false
                                for _, owned in pairs(game:GetService("Players").LocalPlayer.leaderstats.Inventory.Mounts:GetChildren()) do
                                    if owned.Name:lower():find(mount.Name:lower()) then
                                        CheckMount = true
                                        WindUI:Notify({
                                            Title = "Venuz | Notify",
                                            Content = "You already have Mount : "..mount.Name,
                                            Icon = VenuzIcon,
                                            Duration = 2.5
                                        })
                                        Hopserver()
                                        break
                                    end
                                end
                                if not CheckMount then
                                local mountPosition = mount:GetPivot()
                                teleportPlayer(mountPosition,1)
                                task.wait(2)
                                game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
                                task.wait(1)
                                game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
                                task.wait(1)
                                local enbedmount = {
                                    ["title"] = "**Mount Collected!**",
                                    ["description"] = "```lua\nSuccessfully collected the mount: "..mount.Name.."```",
                                    ["color"] = 65280,
                                    ["fields"] = {
                                        {
                                            ["name"] = "**Mount Name**",
                                            ["value"] = "```"..mount.Name.."```",
                                            ["inline"] = true
                                        },
                                        {
                                            ["name"] = "**Time Collected**",
                                            ["value"] = "```"..os.date("%Y-%m-%d %H:%M:%S").."```",
                                            ["inline"] = true
                                        }
                                    },
                                    ["footer"] = {
                                        ["text"] = "Sent by Venuz Mount Collector Bot"
                                    }
                                }
                                
                                if _G.Settings.Mount.SendNotifyMount then
                                SendMessageEMBED(_G.Settings.Mount.UrlWebhook, enbedmount)
                                end
                                end
                            end
                        end
                        if _G.Settings.Mount.AutoFarmMounts then
                        Hopserver()
                        end
                    end
                end)
            end)
        end
    end
})

-------------------------------- Dungeon --------------------------------

local locationChecking = {
    ["Leveling City"] = {128, 28, 53},
    ["Grass Village"] = {-3288, 160, 2737},
    ["Brum Island"] = {-3102, 170, -2480},
    ["Lucky Kingdom"] = {406, 160, 4576},
    ["Faceheal Town"] = {2562, 180, -2747},
    ["Dragon City"] = {-6928, 125, -75},
    ["Chainsaw Man"] = {237, 147, -5159},
}

local DungeonSection = Tabs.Dungeon:Section({ Title = "↪ Join Settings" })

for locationName, _ in pairs(locationChecking) do
    Tabs.Dungeon:Dropdown({
        Title = locationName,
        Values = {"E", "D", "C", "B", "A", "S", "SS"},
        Multi = true,
        Value = _G.Settings.Dungeon.listDungeon[locationName] or {},
        Callback = function(Value)
            _G.Settings.Dungeon.listDungeon[locationName] = Value
            SaveSetting()
        end
    })
end

local AutoDungeon = Tabs.Dungeon:Section({ Title = "↪ Auto Dungeon" })

local SelectMode = Tabs.Dungeon:Dropdown({
    Title = "Select Mode",
    Values = {"In Server", "HopServer"},
    Value = _G.Settings.Dungeon.SelectModeDungeon,
    Callback = function(Value)
        _G.Settings.Dungeon.SelectModeDungeon = Value
        SaveSetting()
    end
})

local Dungeonpath = workspace.__Main.__Dungeon:FindFirstChild("Dungeon")

local function getDungeonRankText()
    local player = game:GetService("Players").LocalPlayer
    local gui = player:FindFirstChild("PlayerGui")
    if not gui then return nil end

    local menus = gui:FindFirstChild("Menus")
    if not menus then return nil end

    local dungeonMenu = menus:FindFirstChild("Dungeon")
    if not dungeonMenu then return nil end

    local background = dungeonMenu:FindFirstChild("Background")
    if not background then return nil end

    local rankLabel = background:FindFirstChild("DungeonRank")
    if not rankLabel then return nil end

    return rankLabel.Text
end

local AutofindDungeon = Tabs.Dungeon:Toggle({
    Title = "Auto Find Dungeon",
    Value = _G.Settings.Dungeon.AutofindDungeon,
    Icon = "check",
    Callback = function(enabled)
        _G.Settings.Dungeon.AutofindDungeon = enabled
        SaveSetting()

        previousPosition = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
        if game.PlaceId == 87039211657390 then
            task.spawn(function()
                pcall(function()
                    while _G.Settings.Dungeon.AutofindDungeon do task.wait(1)
                        for island, pos in pairs(locationChecking) do
                            local selectedRanks = _G.Settings.Dungeon.listDungeon[island]
                            if selectedRanks and #selectedRanks > 0 then
                                if not _G.Settings.Dungeon.AutofindDungeon then
                                    teleportPlayer(previousPosition,1)
                                    return
                                end
                                teleportPlayer(pos, 1)
                                task.wait(1)
                                local dungeonFound = false
                                for _, dungeon in pairs(workspace.__Main.__Dungeon:GetChildren()) do
                                    if dungeon.Name == "Dungeon" then
                                        local targetDungeon = dungeon:GetPivot()
                                        teleportPlayer({targetDungeon.Position.X, targetDungeon.Position.Y, targetDungeon.Position.Z}, 1)

                                        local currentRank = getDungeonRankText()
                                        if currentRank then
                                            for _, rank in ipairs(selectedRanks) do
                                                if currentRank == rank then
                                                    dungeonFound = true
                                                    game:GetService("ReplicatedStorage"):WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent"):FireServer(unpack({{{Event = "DungeonAction",Action = "Create"},"\v"}}))
                                                    game:GetService("ReplicatedStorage"):WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent"):FireServer(unpack({{{Dungeon = 8553606839,Event = "DungeonAction",Action = "Start"},"\v"}})) 
                                                    break
                                                end
                                            end

                                            if not dungeonFound then
                                                teleportPlayer(pos, 1)
                                                task.wait(1)
                                                break
                                            end
                                        end
                                    end
                                end

                                if dungeonFound then
                                    return
                                end
                            end
                        end

                        if _G.Settings.Dungeon.SelectModeDungeon == "HopServer" then
                            Hopserver()
                            return
                        end
                    end
                end)
            end)
        end
    end
})

-------------------------------- Teleport --------------------------------

local Teleport = Tabs.Teleport:Section({ Title = "↪ Teleport" })

local SelectIsland = Tabs.Teleport:Dropdown({
    Title = "TeleportSelect",
    Values = {"Lucky Kingdom", "Faceheal Town", "Leveling City", "Grass Village", "Brum Island","Dragon City","Chainsaw Man"},
    Value = _G.Settings.TeleportSelect,
    Callback = function(Value)
        _G.Settings.TeleportSelect = Value
        SaveSetting()
    end
})

local TP = Tabs.Teleport:Button({
    Title = "Teleport",
    Callback = function()
        local validValues = { "\5", "\t", "\4", "\n", "\8", "\v"}
        for i,v in ipairs(validValues) do
        if _G.Settings.TeleportSelect == "Lucky Kingdom" then        
        game:GetService("ReplicatedStorage"):WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent"):FireServer(unpack({{{Event = "ChangeSpawn",Spawn = "BCWorld"},v}}))
        game.Players.LocalPlayer.Character.Humanoid.Health = die
        elseif _G.Settings.TeleportSelect == "Faceheal Town" then
        game:GetService("ReplicatedStorage"):WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent"):FireServer(unpack({{{Event = "ChangeSpawn",Spawn = "BleachWorld"},v}}))            
        game.Players.LocalPlayer.Character.Humanoid.Health = die
        elseif _G.Settings.TeleportSelect == "Leveling City" then
        game:GetService("ReplicatedStorage"):WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent"):FireServer(unpack({{{Event = "ChangeSpawn",Spawn = "SoloWorld"},v}}))        
        game.Players.LocalPlayer.Character.Humanoid.Health = die
        elseif _G.Settings.TeleportSelect == "Grass Village" then
        game:GetService("ReplicatedStorage"):WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent"):FireServer(unpack({{{Event = "ChangeSpawn",Spawn = "NarutoWorld"},v}}))        
        game.Players.LocalPlayer.Character.Humanoid.Health = die
        elseif _G.Settings.TeleportSelect == "Brum Island" then
        game:GetService("ReplicatedStorage"):WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent"):FireServer(unpack({{{Event = "ChangeSpawn",Spawn = "OPWorld"},v}}))        
        game.Players.LocalPlayer.Character.Humanoid.Health = die
        elseif _G.Settings.TeleportSelect == "Dragon City" then
        game:GetService("ReplicatedStorage"):WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent"):FireServer(unpack({{{Event = "ChangeSpawn",Spawn = "DBWorld"},v}}))      
        game.Players.LocalPlayer.Character.Humanoid.Health = die
        elseif _G.Settings.TeleportSelect == "Chainsaw Man" then
        game:GetService("ReplicatedStorage"):WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent"):FireServer(unpack({{{Event = "ChangeSpawn",Spawn = "ChainsawWorld"},v}}))           
        game.Players.LocalPlayer.Character.Humanoid.Health = die
        end    
    end
end
})

-------------------------------- Webhook --------------------------------

local Webhook = Tabs.Webhook:Section({ Title = "↪ Webhook" })

local UrlWebhook = Tabs.Webhook:Input({
    Title = "UrlWeebhook",
    Placeholder = "Enter UrlWebhook",
    Value = _G.Settings.Mount.UrlWebhook,
    Callback = function(Value)
        _G.Settings.Mount.UrlWebhook = Value
        SaveSetting()
    end
})

local sendembedmount = Tabs.Webhook:Toggle({
    Title = "SendNotifyMount",
    Value = _G.Settings.Mount.SendNotifyMount,
    Icon = "check",
    Callback = function(Value)
        _G.Settings.Mount.SendNotifyMount = Value
        SaveSetting()
    end
})

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