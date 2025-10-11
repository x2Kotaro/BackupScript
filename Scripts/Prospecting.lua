local NotificationLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/IceMinisterq/Notification-Library/Main/Library.lua"))()

if game:GetService("CoreGui"):FindFirstChild("WindUI") then
    return
    NotificationLibrary:SendNotification("Info", "You already have a script.", 3)
end

_G.ConfigurationTable = {}
_G.Settings = {}

local FolderConfiguration = "Venuz Hub"
local FolderSettings = "Venuz Hub/Prospecting"
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

local filenameConfiguration = FolderConfiguration .. "/" .. "Setting" .. ".json"
local filenameSetting = FolderSettings .. "/" .. "Prospecting_".. LocalPlayer.Name .. ".json"

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
            ["SetupPosition"] = {
                ["PositionPan"] = nil,
                ["PositionShake"] = nil,
            },

            ["AutoFarm"] = {
                ["AutoFarm"] = false,
                ["AutoEquipPan"] = false,
            },

            ["SlotsManage"] = {
                ["SelectSlot"] = nil,
                ["Context"] = nil,
                ["SlotName"] = "",
            },

            ["InfernalHeart"] = {
                ["PositionPan"] = nil,
                ["PositionShake"] = nil,
                ["AutoInfernalHeart"] = false,
            },

            ["Shop"] = {
                AmountPotions = 1,
                AmountTotem = 1,
            },

            ["AutoSell"] = {
                ["Amount"] = 20,
                ["AutoSell"] = false,
                ["SelectPantoSell"] = nil,
                ["AutoChangedPan"] = false
            },

            ["Favorites"] = {
                ["Rarity"] = {"Epic", "Legendary", "Mythic"},
                ["ItemNames"] = {},
                ["ItemWeight"] = 0,
                ["Unlocklist"] = {},
                ["LockRarity"] = false,
                ["LockItemNames"] = false,
                ["LockItemWeight"] =false,
            },

            ["Enchants"] = {
                ["EnchantsSelcted"] = {},
                ["AutoEnchants"] = false,
                ["ItemToEnchants"] = "Aurorite",
            },

            ["Character"] = {
                ["EnabledWalkSpeed"] = false,
            },

            ["Webhook"] = {
                ["Url"] = "",
                ["Rarity_Webhook"] = {"Epic","Legendary", "Mythic"},
                ["SendNotify_Rarity"] = false,
                ["Ping"] = false,
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

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/x2Kotaro/API/refs/heads/main/WindUIVenuz.lua"))()

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
    Automatic = Window:Tab({ Title = "AutoFarm", Icon = "code-xml", ShowTabTitle = true }),
    SlotsManage = Window:Tab({ Title = "Slots Manage", Icon = "code-xml", ShowTabTitle = true }),
    Event = Window:Tab({ Title = "Events", Icon = "gift", ShowTabTitle = true }),
    Item = Window:Tab({ Title = "Favorites", Icon = "heart", ShowTabTitle = true }),
    Enchants = Window:Tab({ Title = "Enchants", Icon = "wand", ShowTabTitle = true }),
    Shop = Window:Tab({ Title = "Shop", Icon = "shovel", ShowTabTitle = true }),
    Character = Window:Tab({ Title = "Character", Icon = "user", ShowTabTitle = true }),
    divider1 = Window:Divider(),
    Webhook = Window:Tab({ Title = "Webhook", Icon = "send" }),
    Configuration = Window:Tab({ Title = "Configuration", Icon = "settings", Desc = "Manage window settings and themes.", ShowTabTitle = true}),
}

-------------------------------- Function --------------------------------

function WalkToWaypoint(posTable, andThen)
    if typeof(posTable) == "table" and #posTable > 0 then
        local posStr = table.concat(posTable, " ")
        local x, y, z = string.match(posStr, "([%d%-%.]+), ([%d%-%.]+), ([%d%-%.]+)")
        if x and y and z then
            local targetPosition = Vector3.new(tonumber(x), tonumber(y), tonumber(z))
            local character = game.Players.LocalPlayer.Character
            local humanoid = character:WaitForChild("Humanoid")
            local rootPart = character:WaitForChild("HumanoidRootPart")
            
            local lastPosition = rootPart.Position
            local stuckCheckInterval = 0.5
            local stuckThreshold = 1
            local jumpCooldown = 1
            local lastJumpTime = 0
            local isMovingToWaypoint = false
            
            local pathfindingService = game:GetService("PathfindingService")
            
            local path = pathfindingService:CreatePath({
                AgentRadius = 1.5,
                AgentHeight = 2,
                AgentCanJump = true,
                WaypointSpacing = 7,
                AgentCanClimb = true,
            })
            
            path:ComputeAsync(rootPart.Position, targetPosition)
            
            if path.Status == Enum.PathStatus.Success then
                local waypoints = path:GetWaypoints()
                
                local function checkIfStuck()
                    while _G.Settings.AutoFarm.AutoFarm do
                        wait(stuckCheckInterval)
                        
                        local currentPos = rootPart.Position
                        local distanceMoved = (currentPos - lastPosition).Magnitude
                        
                        -- เช็คว่ากำลังเดินไป waypoint แต่ติดอยู่
                        if isMovingToWaypoint and distanceMoved < stuckThreshold and (tick() - lastJumpTime) > jumpCooldown then
                            humanoid.Jump = true
                            lastJumpTime = tick()
                        end
                        
                        lastPosition = currentPos
                    end
                end                
                
                local stuckThread = coroutine.create(checkIfStuck)
                coroutine.resume(stuckThread)
                
                for i, waypoint in ipairs(waypoints) do
                    -- ลบการกระโดดออกจาก waypoint action
                    -- if waypoint.Action == Enum.PathWaypointAction.Jump then
                    --     humanoid.Jump = true
                    -- end
                    
                    isMovingToWaypoint = true
                    humanoid:MoveTo(waypoint.Position)
                    
                    local reachedEvent = humanoid.MoveToFinished:Wait()
                    isMovingToWaypoint = false
                    
                    if not reachedEvent then
                        coroutine.close(stuckThread)
                        if andThen then andThen(false) end
                        return
                    end
                end
                
                coroutine.close(stuckThread)
                
                if (rootPart.Position - targetPosition).Magnitude < 5 then
                    if andThen then andThen(true) end
                else
                    if andThen then andThen(false) end
                end
            else
                humanoid:MoveTo(targetPosition)
                humanoid.MoveToFinished:Once(function(reached)
                    if andThen then andThen(reached) end
                end)
            end
        end
    end
end

local function GetCharacter()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    return character, hrp
end

function SendMessageEMBED(url, embed)
    local http = game:GetService("HttpService")
    local headers = {
        ["Content-Type"] = "application/json"
    }
    local data = {
        ["content"] = embed.content or "",
        ["embeds"] = {
            {
                ["title"] = embed.title or "",
                ["description"] = embed.description or "",
                ["color"] = embed.color or 0,
                ["thumbnail"] = {
                    ["url"] = (embed.thumbnail and embed.thumbnail.url) or ""
                },
                ["image"] = {
                    ["url"] = (embed.image and embed.image.url) or ""
                },
                ["fields"] = embed.fields or {},
                ["footer"] = {
                    ["text"] = (embed.footer and embed.footer.text) or ""
                }
            }
        }
    }
    local body = http:JSONEncode(data)
    local response = request({
        Url = url,
        Method = "POST",
        Headers = headers,
        Body = body
    })
end

-------------------------------- Setup Position --------------------------------

local Setup = Tabs.Automatic:Section({ Title = "↪ Setup Position" })

PositionParagraph = Tabs.Automatic:Paragraph({
    Title = "Positions",
    Desc = "Position : Deposit " .. ((_G.Settings.SetupPosition.PositionPan and table.concat(_G.Settings.SetupPosition.PositionPan, " ")) or "Not set") .. "\n" .."Position : Shake " .. ((_G.Settings.SetupPosition.PositionShake and table.concat(_G.Settings.SetupPosition.PositionShake, " ")) or "Not set")
})

local PositionPan = Tabs.Automatic:Button({
    Title = "Save Position Deposit",
    Desc = "Set your Position to Deposit",
    Callback = function()
        local pos = hrp.Position
        _G.Settings.SetupPosition.PositionPan = {math.round(pos.X) .. ", " .. math.round(pos.Y) .. ", " .. math.round(pos.Z)}
        SaveSetting()
        PositionParagraph:SetDesc("Position : Deposit " .. table.concat(_G.Settings.SetupPosition.PositionPan, " ") .. "\n" .."Position : Shake " .. ((_G.Settings.SetupPosition.PositionShake and table.concat(_G.Settings.SetupPosition.PositionShake, " ")) or "Not set"))
    end
})

local PositionShake = Tabs.Automatic:Button({
    Title = "Save Position Shake",
    Desc = "Set your Position to Shake",
    Callback = function()
        local pos = hrp.Position
        _G.Settings.SetupPosition.PositionShake = {math.round(pos.X) .. ", " .. math.round(pos.Y) .. ", " .. math.round(pos.Z)}
        SaveSetting()
        PositionParagraph:SetDesc("Position : Deposit " .. ((_G.Settings.SetupPosition.PositionPan and table.concat(_G.Settings.SetupPosition.PositionPan, " ")) or "Not set") .. "\n" .."Position : Shake " .. table.concat(_G.Settings.SetupPosition.PositionShake, " "))
    end
})

-------------------------------- AutoFarm --------------------------------

local AutoFarmTab = Tabs.Automatic:Section({ Title = "↪ AutoFarm" })

local AutoFarm
local AutoSell
local animationId = game:GetService("ReplicatedStorage").Assets.Animations.Panning.DigHit.AnimationId
local animation2Id = game:GetService("ReplicatedStorage").Assets.Animations.Panning.Shake.AnimationId
_G.EnabledCollecting = false
_G.EnabledShake = false

function getHumanoid()
    local character = game:GetService("Players").LocalPlayer.Character
    if character then
        return character:WaitForChild("Humanoid")
    end
    return nil
end

function setupAnimations()
    local humanoid = getHumanoid()
    if not humanoid then return end

    local animation = Instance.new("Animation")
    animation.AnimationId = animationId

    local animation2 = Instance.new("Animation")
    animation2.AnimationId = animation2Id

    return humanoid:LoadAnimation(animation), humanoid:LoadAnimation(animation2)
end

local track, track2 = setupAnimations()

task.spawn(function()
    while true do
        local character = game:GetService("Players").LocalPlayer.Character
        if not character or not character:FindFirstChild("Humanoid") then
            track, track2 = setupAnimations()
            task.wait(1)
            continue
        end

        if _G.EnabledCollecting then
            if not track or not track.IsPlaying then
                if track then track:Play() end
                for i, v in pairs(character:GetChildren()) do
                    if v.Name:lower():find("pan") and v:IsA("Tool") then
                        character:WaitForChild(v.Name):WaitForChild("Scripts"):WaitForChild("ToggleShovelActive"):FireServer(unpack({true}))
                    end
                end                
            end
        else
            if track and track.IsPlaying then
                track:Stop()
                for i, v in pairs(character:GetChildren()) do
                    if v.Name:lower():find("pan") and v:IsA("Tool") then
                        character:WaitForChild(v.Name):WaitForChild("Scripts"):WaitForChild("ToggleShovelActive"):FireServer(unpack({false}))
                    end
                end   
            end
        end
        
        if _G.EnabledShake then
            if not track2 or not track2.IsPlaying then
                if track2 then track2:Play() end
            end
        else
            if track2 and track2.IsPlaying then
                track2:Stop()
            end
        end
        task.wait()
    end
end)

function GetClosestMerchantPosition(hrp)
    local towns = {
        "StarterTown",
        "RiverTown",
        "Cavern",
        "Delta",
        "Volcano",
        "Mountain"
    }

    local closestCFrame = nil
    local shortestDistance = math.huge

    for _, townName in ipairs(towns) do
        local npcFolder = workspace:FindFirstChild("NPCs")
        local townFolder = npcFolder and npcFolder:FindFirstChild(townName)

        if townName == "Delta" then
            merchantParent = workspace:FindFirstChild("NPCs") and workspace.NPCs:FindFirstChild(townName)
            if merchantParent then
                local shadyMerchant = merchantParent:FindFirstChild("Shady Merchant")
                if shadyMerchant and shadyMerchant:FindFirstChild("HumanoidRootPart") then
                    local merchantHRP = shadyMerchant.HumanoidRootPart
                    local distance = (hrp.Position - merchantHRP.Position).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closestCFrame = merchantHRP.CFrame * CFrame.new(0, 0, -5)
                    end
                end
            end
        else
            merchantParent = workspace:FindFirstChild("NPCs") and workspace.NPCs:FindFirstChild(townName)
            if merchantParent then
                for _, merchant in pairs(merchantParent:GetChildren()) do
                    if merchant.Name == "Merchant" and merchant:FindFirstChild("HumanoidRootPart") then
                        local merchantHRP = merchant.HumanoidRootPart
                        local distance = (hrp.Position - merchantHRP.Position).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            closestCFrame = merchantHRP.CFrame * CFrame.new(0, 0, -5)
                        end
                    end
                end
            end
        end
    end

    return closestCFrame
end

local AllPan = {}
for i,v in pairs(game:GetService("ReplicatedStorage").Items.Pans:GetChildren()) do
    table.insert(AllPan, v.Name)
end
local AutoFarmTabs
AutoFarmTabs = Tabs.Automatic:Toggle({
    Title = "Auto Farm",
    Icon = "check",
    Value = _G.Settings.AutoFarm.AutoFarm,
    Callback = function(Value)
        _G.Settings.AutoFarm.AutoFarm = Value
        SaveSetting()
        
        if not _G.AutoFarmState then
            _G.AutoFarmState = {
                selling = false,
                sellStartTime = 0,
                originalPan = nil,
                mainPan = nil,
                isSystemWalking = false
            }
        end

        function GetPanID(panName)
            for i,v in pairs(game:GetService("ReplicatedStorage").Items.Pans:GetChildren()) do
                if v.Name == panName and v:GetAttribute("ItemID") then
                    return tostring(v:GetAttribute("ItemID"))
                end
            end
            return nil
        end
        
        function GetCurrentEquippedPan()
            local character = workspace.Characters:FindFirstChild(game.Players.LocalPlayer.Name)
            if character then
                local tool = character:FindFirstChildWhichIsA("Tool")
                if tool and tool.Name:lower():find("pan") then
                    return tool.Name
                end
            end
            return nil
        end
        
        function EquipPanByName(panName)
            local panID = GetPanID(panName)
            if panID then
                local args = { panID }
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Inventory"):WaitForChild("EquipPan"):InvokeServer(unpack(args))

                local maxWaitTime = 5
                local startTime = tick()
                
                while tick() - startTime < maxWaitTime do
                    task.wait(0.1)
                    local currentPan = GetCurrentEquippedPan()
                    if currentPan == panName then
                        task.wait(0.2)
                        return true
                    end
                end
                
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Inventory"):WaitForChild("EquipPan"):InvokeServer(unpack(args))
                task.wait(1)
                return true
            end
            return false
        end

        function WalkToWaypointWithFlag(pos, callback)
            _G.AutoFarmState.isSystemWalking = true
            WalkToWaypoint(pos, function(reached)
                _G.AutoFarmState.isSystemWalking = false
                if callback then callback(reached) end
            end)
        end

        local function PlayerIsWalkingManually()
            return UserInputService:IsKeyDown(Enum.KeyCode.W)
                or UserInputService:IsKeyDown(Enum.KeyCode.A)
                or UserInputService:IsKeyDown(Enum.KeyCode.S)
                or UserInputService:IsKeyDown(Enum.KeyCode.D)
                or UserInputService:IsKeyDown(Enum.KeyCode.Up)
                or UserInputService:IsKeyDown(Enum.KeyCode.Down)
                or UserInputService:IsKeyDown(Enum.KeyCode.Left)
                or UserInputService:IsKeyDown(Enum.KeyCode.Right)
        end

        if Value then
            if not _G.Settings.SetupPosition.PositionPan or #_G.Settings.SetupPosition.PositionPan == 0 or not _G.Settings.SetupPosition.PositionShake or #_G.Settings.SetupPosition.PositionShake == 0 then
                WindUI:Notify({
                    Title = "Venuz | Notify",
                    Content = "Please Set Position To AutoFarm",
                    Icon = VenuzIcon,
                    Duration = 3,
                })
                task.wait(0.5)
                AutoFarmTabs:Set(false)
                return
            end
            
            _G.AutoFarmState.mainPan = GetCurrentEquippedPan()

            RunService.Heartbeat:Connect(function()
                if _G.Settings.AutoFarm.AutoFarm and not _G.AutoFarmState.selling then
                    if PlayerIsWalkingManually() then
                        _G.EnabledCollecting = false
                        _G.EnabledShake = false
                        _G.AutoFarmState.isSystemWalking = false
                        _G.AutoFarmState.manualWalkTime = tick()
                    else
                        if _G.AutoFarmState.manualWalkTime and tick() - _G.AutoFarmState.manualWalkTime > 1 then
                            if _G.LastFarmPosition and hrp then
                                WalkToWaypointWithFlag({
                                    tostring(_G.LastFarmPosition.Position.X)..", "..
                                    tostring(_G.LastFarmPosition.Position.Y)..", "..
                                    tostring(_G.LastFarmPosition.Position.Z)
                                }, function() end)
                            end
                            _G.AutoFarmState.manualWalkTime = nil
                        end
                    end
                end
            end)

            task.spawn(function()
                pcall(function()
                    while _G.Settings.AutoFarm.AutoFarm do task.wait()

                        if not _G.Settings.AutoFarm.AutoFarm then break end
                        
                        local character = workspace.Characters:FindFirstChild(LocalPlayer.Name)
                        if not character then
                            task.wait(1)
                            continue
                        end
                        
                        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                        local humanoid = character:FindFirstChild("Humanoid")
                        if not humanoidRootPart or not humanoid or humanoid.Health <= 0 then
                            task.wait(1)
                            continue
                        end
                        
                        chr = character
                        hrp = humanoidRootPart
                        
                        local isPanning = character:GetAttribute("Panning")

                        -- Auto Sell
                        if _G.Settings.AutoSell.AutoSell and not _G.AutoFarmState.selling then
                            local inventorySize = LocalPlayer:GetAttribute("InventorySize")
                            local items = LocalPlayer:WaitForChild("BackpackTwo"):GetChildren()
                            
                            if chr then
                                local tool = chr:FindFirstChildOfClass("Tool")
                                if tool then table.insert(items, tool) end
                            end
                            
                            local itemCount = 0
                            for _, item in ipairs(items) do
                                local itemType = item:GetAttribute("ItemType")
                                if itemType == "Equipment" or itemType == "Valuable" then
                                    itemCount = itemCount + 1
                                end
                            end
                            
                            if itemCount >= _G.Settings.AutoSell.Amount then
                                _G.AutoFarmState.selling = true
                                _G.AutoFarmState.sellStartTime = tick()
                                _G.EnabledCollecting = false
                                _G.EnabledShake = false
                                
                                _G.AutoFarmState.originalPan = GetCurrentEquippedPan()
                                
                                if _G.Settings.AutoSell.AutoChangedPan and _G.Settings.AutoSell.SelectPantoSell and _G.Settings.AutoSell.SelectPantoSell ~= "" then
                                    task.wait(0.5)
                                    local success = EquipPanByName(_G.Settings.AutoSell.SelectPantoSell)
                                    if not success then
                                        task.wait(1)
                                        EquipPanByName(_G.Settings.AutoSell.SelectPantoSell)
                                    end
                                end
                                
                                local function attemptSell()
                                    if not hrp or not hrp.Parent then
                                        local char = workspace.Characters:FindFirstChild(LocalPlayer.Name)
                                        if char then
                                            hrp = char:FindFirstChild("HumanoidRootPart")
                                        end
                                        if not hrp then
                                            task.wait(2)
                                            attemptSell()
                                            return
                                        end
                                    end
                                    if not _G.Settings.AutoFarm.AutoFarm then
                                        _G.AutoFarmState.selling = false
                                        return
                                    end
                                    
                                    local merchantCFrame = GetClosestMerchantPosition(hrp)
                                    
                                    if merchantCFrame then
                                        WalkToWaypointWithFlag({tostring(merchantCFrame.Position.X)..", "..tostring(merchantCFrame.Position.Y)..", "..tostring(merchantCFrame.Position.Z)}, function(reached)
                                            if reached then
                                                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Shop"):WaitForChild("SellAll"):InvokeServer()
                                                task.wait(1.5)
                                                local items = LocalPlayer:WaitForChild("BackpackTwo"):GetChildren()
                                                if chr then
                                                    local tool = chr:FindFirstChildOfClass("Tool")
                                                    if tool then table.insert(items, tool) end
                                                end
                                                
                                                local remainingItems = 0
                                                for _, item in ipairs(items) do
                                                    local itemType = item:GetAttribute("ItemType")
                                                    if itemType == "Equipment" or itemType == "Valuable" then
                                                        remainingItems = remainingItems + 1
                                                    end
                                                end
                                                
                                                if remainingItems >= _G.Settings.AutoSell.Amount then
                                                    task.wait(2)
                                                    attemptSell()
                                                else
                                                    if _G.Settings.AutoSell.AutoChangedPan and _G.AutoFarmState.originalPan then
                                                        task.wait(0.5)
                                                        local success = EquipPanByName(_G.AutoFarmState.originalPan)
                                                        if not success then
                                                            task.wait(1)
                                                            EquipPanByName(_G.AutoFarmState.originalPan)
                                                        end
                                                    end
                                                    _G.AutoFarmState.selling = false
                                                    _G.AutoFarmState.originalPan = nil
                                                end
                                            else
                                                task.wait(3)
                                                attemptSell()
                                            end
                                        end)
                                    else
                                        task.wait(2)
                                        attemptSell()
                                    end
                                end
                                
                                attemptSell()
                            end
                        end
                        
                        if _G.AutoFarmState.selling and (tick() - _G.AutoFarmState.sellStartTime) > 60 then
                            if _G.Settings.AutoSell.AutoChangedPan and _G.AutoFarmState.originalPan then
                                EquipPanByName(_G.AutoFarmState.originalPan)
                            end
                            _G.AutoFarmState.selling = false
                            _G.AutoFarmState.originalPan = nil
                        end
                        
                        if not _G.AutoFarmState.selling then
                            local panTool = chr:FindFirstChildWhichIsA("Tool")
                            if not panTool then
                                task.wait(1)
                                continue
                            end

                            local currentFill = panTool:GetAttribute("Fill")
                            local maxCapacity = game:GetService("Players").LocalPlayer.Stats:GetAttribute("Capacity")

                            function InfernalHeartIsOpen()
                                local rocks = workspace.Map.EventStuff:FindFirstChild("InfernalHeartRocks")
                                if not rocks then return false end
                                
                                for _, v in pairs(rocks:GetChildren()) do
                                    if v:IsA("BasePart") and v.Transparency == 1 then
                                        return true
                                    end
                                end
                                return false
                            end

                            local PosPan, PosShake
                            if _G.Settings.InfernalHeart.AutoInfernalHeart and InfernalHeartIsOpen() then
                                PosPan = _G.Settings.InfernalHeart.PositionPan
                                PosShake = _G.Settings.InfernalHeart.PositionShake
                            else
                                PosPan = _G.Settings.SetupPosition.PositionPan
                                PosShake = _G.Settings.SetupPosition.PositionShake
                            end

                            if currentFill >= maxCapacity and not isPanning then
                                _G.EnabledCollecting = false
                                _G.EnabledShake = false
                                WalkToWaypointWithFlag(PosShake, function(reached)
                                    if reached and _G.Settings.AutoFarm.AutoFarm then
                                        _G.LastFarmPosition = hrp.CFrame
                                        if panTool and panTool:FindFirstChild("Scripts") then
                                            panTool.Scripts.Pan:InvokeServer()
                                        end
                                    end
                                end)
                            end
                            
                            if not isPanning and currentFill < maxCapacity then
                                _G.EnabledShake = false
                                WalkToWaypointWithFlag(PosPan, function(reached)
                                    if reached and _G.Settings.AutoFarm.AutoFarm then
                                        _G.EnabledCollecting = true
                                        _G.LastFarmPosition = hrp.CFrame
                                        if panTool and panTool:FindFirstChild("Scripts") then
                                            panTool.Scripts.Collect:InvokeServer(1)
                                        end
                                    end
                                end)
                            else
                                _G.EnabledCollecting = false
                                WalkToWaypointWithFlag(PosShake, function(reached)
                                    if reached and _G.Settings.AutoFarm.AutoFarm then
                                        _G.EnabledShake = true
                                        _G.LastFarmPosition = hrp.CFrame
                                        if panTool and panTool:FindFirstChild("Scripts") then
                                            panTool.Scripts.Shake:FireServer()
                                        end
                                    end
                                end)
                            end
                        end
                    end
                end)
            end)
        else
            _G.EnabledCollecting = false
            _G.EnabledShake = false
            _G.AutoFarmState.selling = false
            _G.AutoFarmState.originalPan = nil

            if _G.ReturnConnection then
                _G.ReturnConnection:Disconnect()
                _G.ReturnConnection = nil
            end
            
            if _G.AutoFarmState.mainPan then
                EquipPanByName(_G.AutoFarmState.mainPan)
            end
            _G.AutoFarmState.mainPan = nil
        end
    end
})

local AutoEquip = Tabs.Automatic:Toggle({
    Title = "AutoEquip Pan",
    Icon = "check",
    Value = _G.Settings.AutoFarm.AutoEquipPan,
    Callback = function(Value)
        _G.Settings.AutoFarm.AutoEquipPan = Value
        SaveSetting()

        if Value then
            task.spawn(function()
                while _G.Settings.AutoFarm.AutoEquipPan do task.wait(1)
                    if _G.Settings.AutoFarm.AutoFarm then
                       for i,v in pairs(game.Players.LocalPlayer.BackpackTwo:GetChildren()) do
                           if v.Name:lower():find("pan") or v.Name:lower():find("world") then
                              game:GetService("ReplicatedStorage").Remotes.CustomBackpack.EquipRemote:FireServer(game:GetService("Players").LocalPlayer.BackpackTwo[v.Name])
                              break
                           end
                       end
                    end
                end
            end)
        end
    end
})

-------------------------------- Slots Manage --------------------------------

local PositionParagraphIH

function GetAllSlots()
    local slots = {}
    if isfolder and isfolder(FolderSlots) then
        local files = listfiles(FolderSlots)
        for _, file in ipairs(files) do
            local fileName = file:match("([^/\\]+)%.json$")
            if fileName then
                table.insert(slots, fileName)
            end
        end
    end
    return slots
end

function SaveSlotData(slotName, context)
    if not slotName or slotName == "" then
        WindUI:Notify({
            Title = "Warning",
            Content = "Please enter a slot name.",
            Icon = VenuzIcon,
            Duration = 3,
        })
        return false
    end
    
    if writefile and makefolder then
        if not isfolder("Venuz Hub") then makefolder("Venuz Hub") end
        if not isfolder(FolderSlots) then makefolder(FolderSlots) end
        
        local sourceSettings = context == "Event" and _G.Settings.InfernalHeart or _G.Settings.SetupPosition
        
        if not sourceSettings or 
        not sourceSettings.PositionPan or next(sourceSettings.PositionPan) == nil or
        not sourceSettings.PositionShake or next(sourceSettings.PositionShake) == nil then
        WindUI:Notify({
            Title = "Error",
            Content = "Postiton not found",
            Icon = VenuzIcon,
            Duration = 3,
        })
        return false
        end

        local slotData = {
            PositionPan = sourceSettings.PositionPan,
            PositionShake = sourceSettings.PositionShake,
            SavedAt = os.date("%Y-%m-%d %H:%M:%S")
        }
        
        local fileName = FolderSlots .. "/" .. slotName .. ".json"
        local json = HttpService:JSONEncode(slotData)
        writefile(fileName, json)
        
        local positionText = "Position : Deposit " .. ((slotData.PositionPan and table.concat(slotData.PositionPan, " ")) or "Not set") .. "\n" ..
                            "Position : Shake " .. ((slotData.PositionShake and table.concat(slotData.PositionShake, " ")) or "Not set")
        if context == "Event" then
            PositionParagraphIH:SetDesc(positionText)
        else
            PositionParagraph:SetDesc(positionText)
        end
        
        WindUI:Notify({
            Title = "Success",
            Content = "Slot '" .. slotName .. "' saved successfully!",
            Icon = VenuzIcon,
            Duration = 3,
        })
        return true
    else
        WindUI:Notify({
            Title = "Error",
            Content = "Cannot save slot data.",
            Icon = VenuzIcon,
            Duration = 3,
        })
        return false
    end
end

function LoadSlotData(slotName, context)
    if not slotName or slotName == "" then
        WindUI:Notify({
            Title = "Warning",
            Content = "Please select a slot to load.",
            Icon = VenuzIcon,
            Duration = 3,
        })
        return false
    end
    
    local fileName = FolderSlots .. "/" .. slotName .. ".json"
    
    if readfile and isfile and isfile(fileName) then
        local slotData = HttpService:JSONDecode(readfile(fileName))
        
        local targetSettings = context == "Event" and _G.Settings.InfernalHeart or _G.Settings.SetupPosition
        targetSettings.PositionPan = slotData.PositionPan
        targetSettings.PositionShake = slotData.PositionShake
        SaveSetting()
        
        local positionText = "Position : Deposit " .. ((slotData.PositionPan and table.concat(slotData.PositionPan, " ")) or "Not set") .. "\n" ..
                            "Position : Shake " .. ((slotData.PositionShake and table.concat(slotData.PositionShake, " ")) or "Not set")
        if context == "Event" then
            PositionParagraphIH:SetDesc(positionText)
        else
            PositionParagraph:SetDesc(positionText)
        end
        
        WindUI:Notify({
            Title = "Success",
            Content = "Slot '" .. slotName .. "' loaded successfully!",
            Icon = VenuzIcon,
            Duration = 3,
        })
        return true
    else
        WindUI:Notify({
            Title = "Error",
            Content = "Slot '" .. slotName .. "' not found.",
            Icon = VenuzIcon,
            Duration = 3,
        })
        return false
    end
end

function DeleteSlotData(slotName)
    if not slotName or slotName == "" then
        WindUI:Notify({
            Title = "Warning",
            Content = "Please select a slot to delete.",
            Icon = VenuzIcon,
            Duration = 3,
        })
        return false
    end
    
    local fileName = FolderSlots .. "/" .. slotName .. ".json"
    
    if delfile and isfile and isfile(fileName) then
        delfile(fileName)
        WindUI:Notify({
            Title = "Success",
            Content = "Slot '" .. slotName .. "' deleted successfully!",
            Icon = VenuzIcon,
            Duration = 3,
        })
        return true
    else
        WindUI:Notify({
            Title = "Error",
            Content = "Cannot delete slot '" .. slotName .. "'.",
            Icon = VenuzIcon,
            Duration = 3,
        })
        return false
    end
end

local SlotManage = Tabs.SlotsManage:Section({ Title = "↪ Slot Management" })

local ContextSelector = Tabs.SlotsManage:Dropdown({
    Title = "Saved From",
    Values = {"AutoFarm", "Event"},
    Multi = false,
    AllowNone = false,
    Value = "AutoFarm",
    Callback = function(Value)
        _G.Settings.SlotsManage.Context = Value
        SaveSetting()
    end
})

local SlotNameInput = Tabs.SlotsManage:Input({
    Title = "Name Slot",
    Value = nil,
    Placeholder = "Enter your Slot Name",
    Callback = function(Value)
        _G.Settings.SlotsManage.NameSlot = Value
        SaveSetting()
    end
})

local Slots = Tabs.SlotsManage:Dropdown({
    Title = "Select Slot",
    Multi = false,
    AllowNone = true,
    Values = GetAllSlots(),
    Value = _G.Settings.SlotsManage.SelectSlot,
    Callback = function(Value)
        _G.Settings.SlotsManage.SelectSlot = Value
        SaveSetting()
    end
})

local SaveSlotButton = Tabs.SlotsManage:Button({
    Title = "Save Slot",
    Callback = function()
        local slotName = _G.Settings.SlotsManage.NameSlot
        local context = _G.Settings.SlotsManage.Context
        if SaveSlotData(slotName, context) then
            local allSlots = GetAllSlots()
            Slots:Refresh(allSlots)
        end
    end
})

local LoadSlotButton = Tabs.SlotsManage:Button({
    Title = "Load Slot",
    Callback = function()
        local selectedSlot = _G.Settings.SlotsManage.SelectSlot
        local context = _G.Settings.SlotsManage.Context
        LoadSlotData(selectedSlot, context)
    end
})

local DeleteSlotButton = Tabs.SlotsManage:Button({
    Title = "Delete Slot",
    Callback = function()
        local selectedSlot = _G.Settings.SlotsManage.SelectSlot
        if DeleteSlotData(selectedSlot) then
            local allSlots = GetAllSlots()
            Slots:Refresh(allSlots)
            _G.Settings.SlotsManage.SelectSlot = nil
            SaveSetting()
        end
    end
})

-------------------------------- Event --------------------------------

local Setup = Tabs.Event:Section({ Title = "↪ Setup Position" })

PositionParagraphIH = Tabs.Event:Paragraph({
    Title = "Positions",
    Desc = "Position : Deposit " .. ((_G.Settings.InfernalHeart.PositionPan and table.concat(_G.Settings.InfernalHeart.PositionPan, " ")) or "Not set") .. "\n" .."Position : Shake " .. ((_G.Settings.InfernalHeart.PositionShake and table.concat(_G.Settings.InfernalHeart.PositionShake, " ")) or "Not set")
})

local PositionPan = Tabs.Event:Button({
    Title = "Save Position Deposit",
    Desc = "Set your Position to Deposit",
    Callback = function()
        local pos = hrp.Position
        _G.Settings.InfernalHeart.PositionPan = {math.round(pos.X) .. ", " .. math.round(pos.Y) .. ", " .. math.round(pos.Z)}
        SaveSetting()
        PositionParagraphIH:SetDesc("Position : Deposit " .. table.concat(_G.Settings.InfernalHeart.PositionPan, " ") .. "\n" .."Position : Shake " .. ((_G.Settings.InfernalHeart.PositionShake and table.concat(_G.Settings.InfernalHeart.PositionShake, " ")) or "Not set"))
    end
})

local PositionShake = Tabs.Event:Button({
    Title = "Save Position Shake",
    Desc = "Set your Position to Shake",
    Callback = function()
        local pos = hrp.Position
        _G.Settings.InfernalHeart.PositionShake = {math.round(pos.X) .. ", " .. math.round(pos.Y) .. ", " .. math.round(pos.Z)}
        SaveSetting()
        PositionParagraphIH:SetDesc("Position : Deposit " .. ((_G.Settings.InfernalHeart.PositionPan and table.concat(_G.Settings.InfernalHeart.PositionPan, " ")) or "Not set") .. "\n" .."Position : Shake " .. table.concat(_G.Settings.InfernalHeart.PositionShake, " "))
    end
})

local Setup = Tabs.Event:Section({ Title = "↪ Infernal Heart" })

local AutoInfernalHeart = Tabs.Event:Toggle({
    Title = "Auto Infernal Heart",
    Icon = "check",
    Value = _G.Settings.InfernalHeart.AutoInfernalHeart,
    Callback = function(Value)
        _G.Settings.InfernalHeart.AutoInfernalHeart = Value
        SaveSetting()
    end
})

-------------------------------- AutoSell --------------------------------

local AutoSellTab = Tabs.Automatic:Section({ Title = "↪ AutoSell" })

local ItemAmount Tabs.Automatic:Input({
    Title = "Amount",
    Value = _G.Settings.AutoSell.Amount,
    Placeholder = "Enter your Amount",
    Callback = function(input)
        _G.Settings.AutoSell.Amount = tonumber(input)
        SaveSetting()
    end
})

AutoSell = Tabs.Automatic:Toggle({
    Title = "Auto Sell",
    Icon = "check",
    Value = _G.Settings.AutoSell.AutoSell,
    Callback = function(Value)
        _G.Settings.AutoSell.AutoSell = Value
        SaveSetting()
    end
})

local AutoSellTab = Tabs.Automatic:Section({ Title = "↪ Select Pan To Sell" })

local Paragraph = Tabs.Automatic:Paragraph({
    Title = "How To Use : Select Pan",
    Desc = "Recommended: Pans enchant with (Midas or Greedy) for maximum profit"
})

local SelectPantoSell = Tabs.Automatic:Dropdown({
    Title = "Select Pan",
    Multi = false,
    AllowNone = true,
    Values = AllPan,
    Value = _G.Settings.AutoSell.SelectPantoSell,
    Callback = function(value)
        _G.Settings.AutoSell.SelectPantoSell = value
        SaveSetting()
    end
})

local AutoChangedPan = Tabs.Automatic:Toggle({
    Title = "Auto Change Pan",
    Icon = "check",
    Value = _G.Settings.AutoSell.AutoChangedPan,
    Callback = function(Value)
        _G.Settings.AutoSell.AutoChangedPan = Value
        SaveSetting()
    end
})
-------------------------------- Favorites --------------------------------

local Backpack = LocalPlayer:WaitForChild("BackpackTwo")

function LockItemIfMatches(tool)
    if not tool:IsA("Tool") then return end

    local rarity = tool:GetAttribute("Rarity")
    local locked = tool:GetAttribute("Locked")

    local shouldLockRarity = false
    local shouldLockName = false
    local shouldLockWeight = false

    if _G.Settings.Favorites.LockRarity and rarity then
        local RarityMap = {}
        for _, rarityName in ipairs(_G.Settings.Favorites.Rarity) do
            RarityMap[rarityName] = true
        end
        if RarityMap[rarity] then
            shouldLockRarity = true
        end
    end

    if _G.Settings.Favorites.LockItemNames then
        local NameMap = {}
        for _, itemName in ipairs(_G.Settings.Favorites.ItemNames) do
            NameMap[itemName] = true
        end
        if NameMap[tool.Name] then
            shouldLockName = true
        end
    end

    if _G.Settings.Favorites.LockItemWeight then
        local targetWeight = tonumber(_G.Settings.Favorites.ItemWeight)
        if targetWeight then
            local itemData = tool:FindFirstChild("ItemData")
            if itemData then
                local weight = itemData:GetAttribute("Weight")
                if weight and tonumber(weight) > targetWeight then
                    shouldLockWeight = true
                end
            end
        end
    end 

    if (shouldLockRarity or shouldLockName or shouldLockWeight) and (locked == nil or locked == false) then
        game:GetService("ReplicatedStorage").Remotes.Inventory.ToggleLock:FireServer(tool)
    end
end

function UnlockItems()
    local UnlockMap = {}
    for _, name in ipairs(_G.Settings.Favorites.Unlocklist or {}) do
        UnlockMap[name] = true
    end

    for _, tool in pairs(Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local isLocked = tool:GetAttribute("Locked")
            if UnlockMap[tool.Name] and isLocked == true then
                game:GetService("ReplicatedStorage").Remotes.Inventory.ToggleLock:FireServer(tool)
            end
        end
    end
end

local FavoritesTab = Tabs.Item:Section({ Title = "↪ Lock by Rarity" })

local Rarity = Tabs.Item:Dropdown({
    Title = "Select Rarity",
    Values = {"Common", "Uncommon", "Rare", "Epic","Legendary", "Mythic", "Exotic"},
    Multi = true,
    AllowNone = true,
    Value = _G.Settings.Favorites.Rarity,
    Callback = function(value)
        _G.Settings.Favorites.Rarity = value
        SaveSetting()
    end
})

local LockRarity = Tabs.Item:Toggle({
    Title = "Lock Rarity",
    Icon = "check",
    Value = _G.Settings.Favorites.LockRarity,
    Callback = function(Value)
        _G.Settings.Favorites.LockRarity = Value
        SaveSetting()
        if Value then
            task.spawn(function()
                while _G.Settings.Favorites.LockRarity do
                    for _, v in pairs(Backpack:GetChildren()) do
                        if v:IsA("Tool") and v:GetAttribute("Locked") ~= true then
                            LockItemIfMatches(v)
                        end
                    end
                    task.wait(1)
                end
            end)
        end
    end
})

local FavoritesTab1 = Tabs.Item:Section({ Title = "↪ Lock by Name" })

local items = {}

for i,v in pairs(game:GetService("ReplicatedStorage").Items.Valuables:GetChildren()) do
    table.insert(items, v.Name)
end

local NameDropdown = Tabs.Item:Dropdown({
    Title = "Select Items",
    Values = items,
    Multi = true,
    AllowNone = true,
    Value = _G.Settings.Favorites.ItemNames,
    Callback = function(value)
        _G.Settings.Favorites.ItemNames = value
        SaveSetting()
    end
})

local LockNameToggle = Tabs.Item:Toggle({
    Title = "Lock by Name",
    Icon = "check",
    Value = _G.Settings.Favorites.LockItemNames or false,
    Callback = function(Value)
        _G.Settings.Favorites.LockRarity = Value
        SaveSetting()
        if Value then
            task.spawn(function()
                while Value do task.wait(0.5)
                    for i,v in pairs(Backpack:GetChildren()) do
                        if v:GetAttribute("Locked") == true then
                            continue
                        else
                            LockItemIfMatches(v)
                        end
                    end
                end
            end)
        end
    end
})

local FavoritesTab11 = Tabs.Item:Section({ Title = "↪ Lock by Weight" })

local WeightDropdown = Tabs.Item:Input({
    Title = "Weight",
    Value = _G.Settings.Favorites.ItemWeight,
    Placeholder = "Input your Weight",
    Callback = function(value)
        _G.Settings.Favorites.ItemWeight = value
        SaveSetting()
    end
})

local LockWeightToggle = Tabs.Item:Toggle({
    Title = "Lock by Weight",
    Icon = "check",
    Value = _G.Settings.Favorites.LockItemWeight,
    Callback = function(Value)
        _G.Settings.Favorites.LockItemWeight = Value
        SaveSetting()
        if Value then
            task.spawn(function()
                while Value do task.wait(0.5)
                    for i,v in pairs(Backpack:GetChildren()) do
                        if v:GetAttribute("Locked") == true then
                            continue
                        else
                            LockItemIfMatches(v)
                        end
                    end
                end
            end)
        end
    end
})

local FavoritesTab2 = Tabs.Item:Section({ Title = "↪ Unlock" })

local UnlockDropdown = Tabs.Item:Dropdown({
    Title = "Select Items",
    Values = items,
    Multi = true,
    AllowNone = true,
    Value = _G.Settings.Favorites.Unlocklist,
    Callback = function(value)
        _G.Settings.Favorites.Unlocklist = value
        SaveSetting()
    end
})

local UnlockBtn = Tabs.Item:Button({
    Title = "Unlock (Select)",
    Callback = function()
        UnlockItems()
    end
})

local UnlockBtn = Tabs.Item:Button({
    Title = "UnlockAll",
    Callback = function()
        for i,v in pairs(Backpack:GetChildren()) do
            if v:IsA("Tool") then
                local locked = v:GetAttribute("Locked")
                if locked == true then
                    game:GetService("ReplicatedStorage").Remotes.Inventory.ToggleLock:FireServer(v)
                end
            end
        end
    end
})

-------------------------------- Shop - Pan & Shovel --------------------------------

local PanandShovelSection = Tabs.Shop:Section({ Title = "Pan & Shovel", TextXAlignment = "Center", TextSize = 22})

local PanData = {
    { Name = "Plastic Pan", Price = "$500" , Town = "StarterTown"},
    { Name = "Metal Pan", Price = "$12k" , Town = "StarterTown"},
    { Name = "Silver Pan", Price = "$55k" , Town = "StarterTown"},
    { Name = "Golden Pan", Price = "$333k" ,Town = "RiverTown"},
    { Name = "Magnetic Pan", Price = "$1M" ,Town = "RiverTown"},
    { Name = "Meteoric Pan", Price = "3.5M" ,Town = "RiverTown"},
    { Name = "Diamond Pan", Price = "$10M" ,Town = "RiverTown"},
    { Name = "Aurora Pan", Price = "$35M" ,Town = "Cavern"},
    { Name = "Worldshaker", Price = "$125M" ,Town = "Cavern"},
    { Name = "Dragonflame Pan", Price = "$400M" ,Town = "Volcano"},
    { Name = "Fossilized Pan", Price = "$1B" ,Town = "Volcano"},
    { Name = "Frostbite Pan", Price = "$10B" ,Town = "Frozen Peak"},
}

local ShovelData = {
    { Name = "Iron Shovel", Price = "$3k", Town = "StarterTown" },
    { Name = "Steel Shovel", Price = "$25k", Town = "StarterTown" },
    { Name = "Silver Shovel", Price = "$75k", Town = "StarterTown" },
    { Name = "Reinforced Shovel", Price = "$135k", Town = "StarterTown" },
    { Name = "The Excavator", Price = "$320k", Town = "RiverTown" },
    { Name = "Golden Shovel", Price = "$1.333M", Town = "RiverTown" },
    { Name = "Meteoric Shovel", Price = "$4M", Town = "RiverTown" },
    { Name = "Diamond Shovel", Price = "$12.5M", Town = "RiverTown" },
    { Name = "Divine Shovel", Price = "$40M", Town = "Cavern" },
    { Name = "Earthbreaker", Price = "$125M", Town = "Cavern" },
    { Name = "Dragonflame Shovel", Price = "$400M", Town = "Volcano" },
    { Name = "Fossilized Shovel", Price = "$1B", Town = "Volcano" },
    { Name = "Icebreaker", Price = "$10B", Town = "Frozen Peak" },
}

local PanNames = {}
local shovelName = {}
for i, pan in ipairs(PanData) do
    table.insert(PanNames, pan.Name)
end

for i, v in ipairs(ShovelData) do
    table.insert(shovelName, v.Name)
end

local DetailItemParagraph = Tabs.Shop:Paragraph({
    Title = "Detail Item",
    Desc = '<font color="#ff9900">Name</font> : N/A\n<font color="#00FF00">Price</font> : N/A'
})

local PanSection = Tabs.Shop:Section({ Title = "↪ Pan"})

local SelectPan = Tabs.Shop:Dropdown({
    Title = "Select Pan",
    Values = PanNames,
    Multi = false,
    AllowNone = true,
    Value = nil,
    Callback = function(value)
        selectpan = value
        local found = nil
        for _, pan in ipairs(PanData) do
            if pan.Name == value then
                found = pan
                break
            end
        end

        if found then
            DetailItemParagraph:SetDesc('<font color="#ff9900">Name</font> : ' .. found.Name .. '\n' ..'<font color="#00FF00">Price</font> : <font color="#FFFFFF">' .. found.Price .. '</font>')
        else
            DetailItemParagraph:SetDesc('<font color="#ff9900">Name</font> : N/A\n<font color="#00FF00">Price</font> : N/A')
        end
    end
})

local BuyPan = Tabs.Shop:Button({
    Title = "Buy Pan",
    Callback = function()
        if not selectpan then
            return
        end

        local selectedPan = nil
        for _, pan in ipairs(PanData) do
            if pan.Name == selectpan then
                selectedPan = pan
                break
            end
        end

        local success, err = pcall(function()
            local shopItem = workspace:WaitForChild("Purchasable"):WaitForChild(selectedPan.Town):WaitForChild(selectedPan.Name):WaitForChild("ShopItem")
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Shop"):WaitForChild("BuyItem"):InvokeServer(shopItem)
        end)
    end
})

local ShovelSection = Tabs.Shop:Section({ Title = "↪ Shovel"})

local SelectShovel = Tabs.Shop:Dropdown({
    Title = "Select Pan",
    Values = shovelName,
    Multi = false,
    AllowNone = true,
    Value = nil,
    Callback = function(value)
        selectshovel = value
        local foundshovel = nil
        for i,v in ipairs(ShovelData) do
            if v.Name == value then
                foundshovel = v
                break
            end
        end

        if foundshovel then
            DetailItemParagraph:SetDesc('<font color="#ff9900">Name</font> : <font color="#FFFFFF">' .. foundshovel.Name .. '</font>\n' ..'<font color="#00FF00">Price</font> : <font color="#FFFFFF">' .. foundshovel.Price .. '</font>')
        else
            DetailItemParagraph:SetDesc("Name : N/A\nPrice : N/A")
        end
    end
})

local BuyShovel = Tabs.Shop:Button({
    Title = "Buy Shovel",
    Callback = function()
        if not selectshovel then
            return
        end

        local BuyShovel = nil
        for _, pan in ipairs(ShovelData) do
            if pan.Name == selectshovel then
                BuyShovel = pan
                break
            end
        end

        local success, err = pcall(function()
            local shopItem = workspace:WaitForChild("Purchasable"):WaitForChild(BuyShovel.Town):WaitForChild(BuyShovel.Name):WaitForChild("ShopItem")
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Shop"):WaitForChild("BuyItem"):InvokeServer(shopItem)
        end)
    end
})

-------------------------------- Shop - Alchemist (Potion) --------------------------------

local AlchemistShoplist = {
    { Name = "Basic Luck Potion", Price = "$50,000", Town = "RiverTown"},
    { Name = "Basic Capacity Potion", Price = "$40,000", Town = "RiverTown"},
    { Name = "Greater Luck Potion", Price = "30 S", Town = "RiverTown"},
    { Name = "Greater Capacity Potion", Price = "20 S", Town = "RiverTown"},
    { Name = "Volcanic Luck Potion", Price = "$1M", Town = "Volcano"},
    { Name = "Volcanic Strength Potion", Price = "$1M", Town = "Volcano"},
    { Name = "Supreme Luck Potion", Price = "150 S", Town = "Volcano"},
}

local potionNames = {}
for i, potion in ipairs(AlchemistShoplist) do
    table.insert(potionNames, potion.Name)
end

local PotionSection = Tabs.Shop:Section({ Title = "Alchemist (Potion)", TextXAlignment = "Center", TextSize = 22})
local DetailItemParagraph = Tabs.Shop:Paragraph({
    Title = "Detail Item",
    Desc = '<font color="#ff9900">Name</font> : N/A\n<font color="#00FF00">Price</font> : N/A'
})

function calculateTotalPrice(price, amount)
    if not price or not amount then return "N/A" end
    
    local numericPrice = 0
    local priceUnit = ""
    
    if string.find(price, "%$") and string.find(price, "M") then
        local numberPart = string.match(price, "%$(%d+)M")
        numericPrice = tonumber(numberPart) or 0
        priceUnit = "$M"
    elseif string.find(price, "%$") then
        local priceStr = string.gsub(price, "[$,]", "")
        numericPrice = tonumber(priceStr) or 0
        priceUnit = "$"
    elseif string.find(price, " S") then
        local numberPart = string.match(price, "(%d+) S")
        numericPrice = tonumber(numberPart) or 0
        priceUnit = " S"
    end
    
    local totalPrice = numericPrice * amount
    
    if priceUnit == "$M" then
        return "$" .. tostring(totalPrice) .. "M"
    elseif priceUnit == "$" and totalPrice >= 1000 then
        return string.format("$%s", string.reverse(string.gsub(string.reverse(tostring(totalPrice)), "(%d%d%d)", "%1,")):gsub("^,", ""))
    else
        return tostring(totalPrice) .. priceUnit
    end
end

function updateDetailParagraph()
    if not selectPotion then
        DetailItemParagraph:SetDesc('<font color="#ff9900">Name</font> : N/A\n<font color="#00FF00">Price</font> : N/A')
        return
    end
    
    local found = nil
    for _, pan in ipairs(AlchemistShoplist) do
        if pan.Name == selectPotion then
            found = pan
            break
        end
    end
    
    if found then 
        local totalPrice = calculateTotalPrice(found.Price, _G.Settings.Shop.AmountPotions or 1)
        DetailItemParagraph:SetDesc(
            '<font color="#ff9900">Name</font> : ' .. found.Name .. '\n' ..
            '<font color="#00FF00">Price</font> : ' .. totalPrice 
        )
    else
        DetailItemParagraph:SetDesc('<font color="#ff9900">Name</font> : N/A\n<font color="#00FF00">Price</font> : N/A')
    end
end

local SelectTotem = Tabs.Shop:Dropdown({
    Title = "Select Potion",
    Values = potionNames,
    Multi = false,
    AllowNone = true,
    Value = nil,
    Callback = function(value)
        selectPotion = value
        updateDetailParagraph()
    end
})

local AmoutBuyTotem = Tabs.Shop:Slider({
    Title = "Amount",
    Value = {
        Min = 1,
        Max = 100,
        Default = _G.Settings.Shop.AmountPotions,
    },
    Callback = function(input)
        _G.Settings.Shop.AmountPotions = input
        SaveSetting()
        updateDetailParagraph()
    end
})

local BuyTotem = Tabs.Shop:Button({
    Title = "Buy Potion",
    Callback = function()
        if not selectPotion then
            return
        end
        local selectpotion = nil
        for _, pan in ipairs(AlchemistShoplist) do
            if pan.Name == selectPotion then
                selectpotion = pan
                break
            end
        end
        local success, err = pcall(function()
                local ohInstance1 = workspace:WaitForChild("Purchasable"):WaitForChild(selectpotion.Town):WaitForChild(selectpotion.Name):WaitForChild("ShopItem")
                local function generateBulkBuy(amount)
                    local buyList = {}
                    for i = 1, amount do
                        table.insert(buyList, ohInstance1)
                    end
                    return buyList
                end
                for i,v in ipairs(generateBulkBuy(_G.Settings.Shop.AmountPotions)) do
                    game:GetService("ReplicatedStorage").Remotes.Shop.BuyItem:InvokeServer(v)
                end
        end)
    end
})

-------------------------------- Shop - Shard Merchant (Totem) --------------------------------

local ShardMerchant = {
    { Name = "Luck Totem", Price = "300 S", Town = "RiverTown"},
    { Name = "Strength Totem", Price = "150 S", Town = "RiverTown"},
    { Name = "Merchant's Potion", Price = "200 S", Town = "RiverTown"},
}

local totem = {}

for i,v in ipairs(ShardMerchant) do
    table.insert(totem, v.Name)
end

local PotionSection1 = Tabs.Shop:Section({ Title = "Shard Merchant (Totem)", TextXAlignment = "Center", TextSize = 22})
local DetailItemParagraph1 = Tabs.Shop:Paragraph({
    Title = "Detail Item",
    Desc = '<font color="#ff9900">Name</font> : N/A\n<font color="#00FF00">Price</font> : N/A'
})

function updateDetailParagraph1()
    if not selectTotem then
        DetailItemParagraph1:SetDesc('<font color="#ff9900">Name</font> : N/A\n<font color="#00FF00">Price</font> : N/A\n<font color="#00BFFF">Total Price</font> : N/A')
        return
    end
    
    local found = nil
    for _, v in ipairs(ShardMerchant) do
        if v.Name == selectTotem then
            found = v
            break
        end
    end
    
    if found then 
        local totalPrice = calculateTotalPrice(found.Price, _G.Settings.Shop.AmountTotem)
        DetailItemParagraph1:SetDesc(
            '<font color="#ff9900">Name</font> : ' .. found.Name .. '\n' ..
            '<font color="#00FF00">Price</font> : ' .. totalPrice 
        )
    else
        DetailItemParagraph1:SetDesc('<font color="#ff9900">Name</font> : N/A\n<font color="#00FF00">Price</font> : N/A')
    end
end

local SelectTotem = Tabs.Shop:Dropdown({
    Title = "Select Totem",
    Values = totem,
    Multi = false,
    AllowNone = true,
    Value = nil,
    Callback = function(value)
        selectTotem = value
        updateDetailParagraph1()
    end
})

local AmoutBuy = Tabs.Shop:Slider({
    Title = "Amount",
    Value = {
        Min = 1,
        Max = 20,
        Default = _G.Settings.Shop.AmountTotem,
    },
    Callback = function(input)
        _G.Settings.Shop.AmountTotem = input
        SaveSetting()
        updateDetailParagraph1()
    end
})

local BuyPotion = Tabs.Shop:Button({
    Title = "Buy Totem",
    Callback = function()
        if not selectTotem then
            return
        end
        local selectTotems = nil
        for _, pan in ipairs(ShardMerchant) do
            if pan.Name == selectTotem then
                selectTotems = pan
                break
            end
        end
        local success, err = pcall(function()
                local ohInstance12 = workspace:WaitForChild("Purchasable"):WaitForChild(selectTotems.Town):WaitForChild(selectTotems.Name):WaitForChild("ShopItem")
                local function generateBulkBuy(amount)
                    local buyList1 = {}
                    for i = 1, amount do
                        table.insert(buyList1, ohInstance12)
                    end
                    return buyList1
                end
                for i,v in ipairs(generateBulkBuy(_G.Settings.Shop.AmountTotem)) do
                    game:GetService("ReplicatedStorage").Remotes.Shop.BuyItem:InvokeServer(v)
                end
        end)
    end
})

-------------------------------- Enchants --------------------------------

local EnchantsTab = Tabs.Enchants:Section({ Title = "↪ Enchants" })

local EnchantsSelct = Tabs.Enchants:Dropdown({
    Title = "Select Enchants",
    Values = {"Lucky", "Strong", "Gigantic", "Swift", "Glowing", "Forceful", "Destructive", "Boosting", "Titanic", "Greedy", "Midas", "Blessed", "Unstable", "Divine", "Cosmic", "Prismatic", "Infernal"},
    Value = _G.Settings.Enchants.EnchantsSelcted,
    AllowNone = true,
    Multi = true,
    Callback = function(value)
        _G.Settings.Enchants.EnchantsSelcted = value
        SaveSetting()
    end
})

local EnchantsSelct = Tabs.Enchants:Dropdown({
    Title = "Item To Enchants",
    Values = {"Aetherite", "Aurorite"},
    Value = _G.Settings.Enchants.ItemToEnchants,
    AllowNone = true,
    Callback = function(value)
        _G.Settings.Enchants.ItemToEnchants = value
        SaveSetting()
    end
})

local AutoEnchants = Tabs.Enchants:Toggle({
    Title = "Auto Enchants",
    Icon = "check",
    Value = _G.Settings.Enchants.AutoEnchants,
    Callback = function(Value)
        _G.Settings.Enchants.AutoEnchants = Value
        SaveSetting()
        if _G.Settings.Enchants.AutoEnchants then
            if not _G.Settings.Enchants.EnchantsSelcted then return end
            while _G.Settings.Enchants.AutoEnchants do task.wait(.1)
            for i,v in pairs(game.Players.LocalPlayer.BackpackTwo:GetChildren()) do
                if (v.Name:lower():find("pan") or v.Name:lower():find("world")) and v:IsA("Tool") then
                    if table.find(_G.Settings.Enchants.EnchantsSelcted, v:GetAttribute("Enchant")) then
                        return
                    else
                        local tool = LocalPlayer.BackpackTwo:FindFirstChild(_G.Settings.Enchants.ItemToEnchants) or LocalPlayer.Character:FindFirstChild(_G.Settings.Enchants.ItemToEnchants)

                        if tool then
                            game:GetService("ReplicatedStorage").Remotes.Crafting.Enchant:InvokeServer(tool)
                        end
                    end
                end
            end
        end
    end
end
})

-------------------------------- Character --------------------------------

local CharacterTabs = Tabs.Character:Section({ Title = "↪ Modify Character" })

local walkSpeedConnection

function enforceWalkSpeed(humanoid)
    if _G.Settings.Character.EnabledWalkSpeed then
        humanoid.WalkSpeed = 26
        if walkSpeedConnection then
            walkSpeedConnection:Disconnect()
        end
        walkSpeedConnection = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if _G.Settings.Character.EnabledWalkSpeed and humanoid.WalkSpeed ~= 26 then
                humanoid.WalkSpeed = 26
            end
        end)
    else
        humanoid.WalkSpeed = 16
        if walkSpeedConnection then
            walkSpeedConnection:Disconnect()
            walkSpeedConnection = nil
        end
    end
end

local EnabledWalkSpeed = Tabs.Character:Toggle({
    Title = "EnabledWalkSpeed",
    Icon = "check",
    Value = _G.Settings.Character.EnabledWalkSpeed,
    Callback = function(Value)
        _G.Settings.Character.EnabledWalkSpeed = Value
        SaveSetting()

        local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid", 5)

        if humanoid then
            enforceWalkSpeed(humanoid)
        end
    end
})

LocalPlayer.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        task.wait(0.5)
        enforceWalkSpeed(humanoid)
    end
end)

if LocalPlayer.Character then
    local humanoid = LocalPlayer.Character:WaitForChild("Humanoid", 5)
    if humanoid then
        enforceWalkSpeed(humanoid)
    end
end

-------------------------------- SetupWebhook --------------------------------

local SetupSection = Tabs.Webhook:Section({ Title = "↪ Setup" })

local executorName, executorVersion = identifyexecutor()

local TestWebhookEmbed = {
    ["title"] = "Account : ||"..LocalPlayer.Name.." ||",
    ["description"] = "ทดลองสำเร็จเวลา : " .. os.date("%H:%M:%S") ..
                      "\nตัวรันที่ใช้ : " .. (executorName or "ไม่พบ") .. " Version : " .. (executorVersion or "ไม่พบ"),
    ["color"] = 5763719,
    ["footer"] = {
        ["text"] = "VenuzHub By Phoenix"
    }
}

local WebhookURL = Tabs.Webhook:Input({
    Title = "Webhook Url",
    Value = _G.Settings.Webhook.Url,
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(input)
        SaveingWK = input
    end
})

local SaveWehook = Tabs.Webhook:Button({
    Title = "Saved Webhook",
    Callback = function()
        _G.Settings.Webhook.Url = SaveingWK
        SaveSetting()
        WindUI:Notify({
            Title = "Venuz | Notify",
            Content = "Saved Webhook Successfully",
            Icon = VenuzIcon,
            Duration = 5,
        })
    end
})

local TestWebhook = Tabs.Webhook:Button({
    Title = "Test Webhook",
    Callback = function()
        SendMessageEMBED(_G.Settings.Webhook.Url, TestWebhookEmbed)
    end
})

-------------------------------- Webhook --------------------------------

local ValuablesSection = Tabs.Webhook:Section({ Title = "↪ Valuables" })

local itemCollection = {}
local collectionTimer = nil
local COLLECTION_TIME = 5

function AddToCollection(itemName, rarity)
    local cleanName = itemName:gsub("%[.-%]%s*", "")
    
    local found = false
    for i, item in pairs(itemCollection) do
        if item.name == cleanName then
            item.count = item.count + 1
            found = true
            break
        end
    end
    
    if not found then
        table.insert(itemCollection, {
            name = cleanName,
            rarity = rarity,
            count = 1
        })
    end
    
    if not collectionTimer then
        collectionTimer = task.delay(COLLECTION_TIME, function()
            SendCollectedItems()
        end)
    end
end

function SendCollectedItems()

    collectionTimer = nil

    if #itemCollection == 0 then
        return
    end
    
    local itemsList = "```\n"
    local totalValue = 0
    
    local rarityOrder = {"Mythic", "Legendary", "Epic", "Rare", "Uncommon", "Common"}
    
    for _, rarityName in pairs(rarityOrder) do
        local hasItems = false
        for _, item in pairs(itemCollection) do
            if item.rarity == rarityName then
                if not hasItems then
                    itemsList = itemsList .. "\n"
                    hasItems = true
                end
                itemsList = itemsList .. item.name .. " x" .. item.count .. "\n"
                totalValue = totalValue + item.count
            end
        end
        if hasItems then
            itemsList = itemsList .. "\n"
        end
    end
    
    itemsList = itemsList .. "```"

    local content = ""
    if _G.Settings.Webhook.Ping then
        content = "@everyone"
    end
    
    local Valueableembed = {
        ["content"] = content,
        ["title"] = "[💰] Prospecting",
        ["description"] = "``🔐`` : **Account** ".."||"..LocalPlayer.Name.."||".."\n".."``📦`` : **ไอเท็มทั้งหมด** ``"..totalValue.."``".."\n".."``🕒`` : **เวลา** "..os.date("%H:%M:%S").."\n\n" .. itemsList,
        ["color"] = 5763719,
        ["thumbnail"] = {
            ["url"] = "https://tr.rbxcdn.com/180DAY-4570cbafe76142fa760b5484d1df11ac/256/256/Image/Webp/noFilter"
        },
        ["image"] = {
            ["url"] = "https://tr.rbxcdn.com/180DAY-dbc8ef776a0fc8771f68221b9e3600d7/768/432/Image/Webp/noFilter"
        },
        ["footer"] = {
            ["text"] = "VenuzHub By Phoenix"
        }
    }
    
    SendMessageEMBED(_G.Settings.Webhook.Url, Valueableembed)
    
    itemCollection = {}
    collectionTimer = nil
end

local processedTools = {}

function CheckRarity(tool)
    if not _G.Settings.Webhook.SendNotify_Rarity then return end
    if not tool:IsA("Tool") then return end

    if processedTools[tool] then return end
    processedTools[tool] = true

    if not tool:GetAttribute("Rarity") or not tool:GetAttribute("ItemType") then return end
    
    local rarity = tool:GetAttribute("Rarity")
    local itemType = tool:GetAttribute("ItemType")
    local itemName = tool.Name or "Unknown Item"
    
    if itemType == "Valuable" and table.find(_G.Settings.Webhook.Rarity_Webhook or {}, rarity) then
        AddToCollection(itemName, rarity)
    end
end

local SelelctRarity = Tabs.Webhook:Dropdown({
    Title = "Select Rarity",
    Values = {"Common", "Uncommon", "Rare", "Epic","Legendary", "Mythic"},
    Multi = true,
    AllowNone = true,
    Value = _G.Settings.Webhook.Rarity_Webhook,
    Callback = function(Select)
        _G.Settings.Webhook.Rarity_Webhook = Select
        SaveSetting()
    end
})

local Ping = Tabs.Webhook:Toggle({
    Title = "Ping (@everyone)",
    Icon = "check",
    Value = _G.Settings.Webhook.Ping,
    Callback = function(Value)
        _G.Settings.Webhook.Ping = Value
        SaveSetting()
    end
})

local SendNotify = Tabs.Webhook:Toggle({
    Title = "Send Notify",
    Icon = "check",
    Value = _G.Settings.Webhook.SendNotify_Rarity,
    Callback = function(Value)
        _G.Settings.Webhook.SendNotify_Rarity = Value
        SaveSetting()
    end
})

if BackpackConn then
    BackpackConn:Disconnect()
end

BackpackConn = LocalPlayer.BackpackTwo.ChildAdded:Connect(function(tool)
    if tool:IsA("Tool") then
        CheckRarity(tool)
    end
end)

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