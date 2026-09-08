
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

-- UI Library (Simple version for this utility)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/Library.lua"))()
local Window = Library:CreateWindow({
    Title = "Mob Position Recorder - Sorcerer Ascent",
    Center = true,
    AutoShow = true,
})

local Tabs = {
    Main = Window:AddTab("Recorder"),
}

local Group = Tabs.Main:AddLeftGroupbox("Controls")
local MobListGroup = Tabs.Main:AddRightGroupbox("Mob List Status")

-- Get Mob List
local MobsModule = require(ReplicatedStorage.Scripts.Mobs.Mobs)
local AllMobs = {}
local RecordedData = {}

-- Populate Mob List
for _, mob in pairs(MobsModule.Mobs) do
    if mob.Name then
        if not AllMobs[mob.Name] then
            AllMobs[mob.Name] = {
                Name = mob.Name,
                Recorded = false,
                Positions = {}
            }
        end
    end
end

-- UI Elements Storage
local MobLabels = {}

-- Update UI Function
local function UpdateUI()
    for name, data in pairs(AllMobs) do
        if not MobLabels[name] then
            MobLabels[name] = MobListGroup:AddLabel(name .. ": [MISSING]")
        end
        
        if data.Recorded then
            MobLabels[name]:SetText(name .. ": [RECORDED (" .. #data.Positions .. ")]")
        end
    end
end

-- Initial UI Population (Sorted)
local sortedNames = {}
for name in pairs(AllMobs) do table.insert(sortedNames, name) end
table.sort(sortedNames)

for _, name in ipairs(sortedNames) do
    if not MobLabels[name] then
        MobLabels[name] = MobListGroup:AddLabel(name .. ": [MISSING]")
    end
end
UpdateUI()


-- Copy Function
Group:AddButton("Copy Data to Clipboard", function()
    local outputStr = "getgenv().PredefinedZones = {\n"
    
    local sortedOutput = {}
    for name, data in pairs(AllMobs) do
        if data.Recorded then
             table.insert(sortedOutput, name)
        end
    end
    table.sort(sortedOutput)

    for _, name in ipairs(sortedOutput) do
        local data = AllMobs[name]
        local pos = data.Positions[1]
        outputStr = outputStr .. string.format('    ["%s"] = CFrame.new(%d, %d, %d),\n', name, math.floor(pos.X), math.floor(pos.Y), math.floor(pos.Z))
    end
    
    outputStr = outputStr .. "}"
    
    setclipboard(outputStr)
    Library:Notify("Data copied to clipboard! Send this to the dev.")
end)

Group:AddLabel("Walk around the map.")
Group:AddLabel("Script auto-records mobs.")

-- Loop to find mobs
task.spawn(function()
    while true do
        task.wait(1)
        
        -- Scan Workspace for Enemies
        local EnemiesFolder = workspace:FindFirstChild("Enemies")
        if EnemiesFolder then
            for _, enemy in pairs(EnemiesFolder:GetChildren()) do
                if enemy:FindFirstChild("HumanoidRootPart") then
                    local hrp = enemy.HumanoidRootPart
                    local enemyName = nil

                    -- Identify mob name using HealthNameBillboard (Same logic as AutoFarm)
                    for _, attachment in ipairs(hrp:GetChildren()) do
                        if attachment:IsA("Attachment") then
                            local billboard = attachment:FindFirstChild("HealthNameBillboard")
                            if billboard and billboard:FindFirstChild("TextLabel") then
                                local fullText = billboard.TextLabel.Text
                                -- Extract name: "Name <Lv. X>" -> "Name"
                                local rawName = fullText:match("^(.-)%s*<") or fullText
                                -- Remove Stars/Emojis and trim whitespace
                                -- This pattern removes any non-alphanumeric characters at the end (like stars) and trims spaces
                                enemyName = rawName:gsub("[%p%c%s]+$", ""):gsub("[⭐★]", ""):match("^%s*(.-)%s*$")
                                break
                            end
                        end
                    end

                    -- If name not found by billboard, try checking object name (fallback)
                    if not enemyName and AllMobs[enemy.Name] then
                        enemyName = enemy.Name
                    end

                    if enemyName and AllMobs[enemyName] then
                        local pos = hrp.Position
                        
                        -- Try Raycast to get ground position perfectly, but fallback to HRP position if fails
                        local params = RaycastParams.new()
                        params.FilterType = Enum.RaycastFilterType.Include
                        if workspace:FindFirstChild("Map") then
                             params.FilterDescendantsInstances = {workspace.Map}
                        else
                             -- If "Map" folder doesn't exist, try to ignore characters and grab anything else
                             params.FilterType = Enum.RaycastFilterType.Exclude
                             params.FilterDescendantsInstances = {workspace.Enemies, workspace.Players}
                        end
                        
                        local ray = workspace:Raycast(hrp.Position, Vector3.new(0, -500, 0), params)
                        if ray and ray.Position then
                            pos = ray.Position + Vector3.new(0, 3, 0) -- Add slight offset up
                        end
                        
                        -- Check if we already have a position close to this one
                        local isNewPos = true
                        for _, recordedPos in ipairs(AllMobs[enemyName].Positions) do
                            if (recordedPos - pos).Magnitude < 20 then
                                isNewPos = false
                                break
                            end
                        end
                        
                        if isNewPos then
                            table.insert(AllMobs[enemyName].Positions, pos)
                            AllMobs[enemyName].Recorded = true
                            print("Recorded: " .. enemyName) -- Debug print
                            UpdateUI()
                        end
                    end
                end
            end
        end
    end
end)

Library:Notify("Recorder Started. Go find them!")
