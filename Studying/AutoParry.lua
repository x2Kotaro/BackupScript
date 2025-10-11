local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer

local CONFIG = {
    ATTACK_RANGE = 25, 
    PREDICTION_THRESHOLD = 0.65, 
    BASE_REACTION_TIME = 0.08, 
    SHIELD_COOLDOWN = 0.3, 
    VELOCITY_THRESHOLD = 8, 
    ANIMATION_TRACK_NAMES = {
        "slash", "swing", "attack", "punch", "kick"
    },
    DEBUG_MODE = true
}


local State = {
    autoParryEnabled = true,
    lastShieldTime = 0,
    knownAnimations = {},
    threatLevels = {},
    recentAttackers = {}
}

local PredictionSystem = {
    velocityHistory = {}, 
    maxHistoryLength = 10,
    
    updateVelocityHistory = function(self, player, velocity)
        if not self.velocityHistory[player] then
            self.velocityHistory[player] = {}
        end
        
        table.insert(self.velocityHistory[player], velocity)
        if #self.velocityHistory[player] > self.maxHistoryLength then
            table.remove(self.velocityHistory[player], 1)
        end
    end,
    
    predictNextPosition = function(self, player)
        local history = self.velocityHistory[player]
        if not history or #history < 2 then return nil end
        
        local averageVelocity = Vector3.new(0, 0, 0)
        local weightSum = 0
        
        for i, velocity in ipairs(history) do
            local weight = i / #history 
            averageVelocity = averageVelocity + (velocity * weight)
            weightSum = weightSum + weight
        end
        
        averageVelocity = averageVelocity / weightSum
        return player.Character.HumanoidRootPart.Position + (averageVelocity * 0.1)
    end
}

local function activateShield(threatLevel)
    local currentTime = os.clock()
    if currentTime - State.lastShieldTime < CONFIG.SHIELD_COOLDOWN then return end
    
    local adjustedReactionTime = CONFIG.BASE_REACTION_TIME * (1 - threatLevel * 0.3)
    task.wait(adjustedReactionTime)
    
    State.lastShieldTime = currentTime
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, nil)
    task.wait(0.05) 
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, nil)
    
    if CONFIG.DEBUG_MODE then
        print(string.format("[mushroom0162 System]: Shield activated (Threat Level: %.2f)", threatLevel))
    end
end


local function setupAnimationTracking(character)
    local humanoid = character:WaitForChild("Humanoid")
    local animator = humanoid:WaitForChild("Animator")
    
    local function onAnimationPlayed(animTrack)
        local animName = animTrack.Animation.Name:lower()
        
        for _, attackName in ipairs(CONFIG.ANIMATION_TRACK_NAMES) do
            if animName:find(attackName) then
                State.knownAnimations[animTrack] = {
                    name = animName,
                    timeStarted = os.clock()
                }
                break
            end
        end
    end
    
    animator.AnimationPlayed:Connect(onAnimationPlayed)
end

local function calculateThreatLevel(player)
    local character = player.Character
    if not character or not LocalPlayer.Character then return 0 end
    
    local targetRoot = character:FindFirstChild("HumanoidRootPart")
    local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot or not localRoot then return 0 end
    
    local distance = (localRoot.Position - targetRoot.Position).Magnitude
    if distance > CONFIG.ATTACK_RANGE then return 0 end
    
    local threatLevel = 0
    

    threatLevel = threatLevel + (1 - (distance / CONFIG.ATTACK_RANGE)) * 0.4
    

    local velocity = targetRoot.Velocity
    local speedThreat = math.clamp(velocity.Magnitude / 20, 0, 1) * 0.3
    threatLevel = threatLevel + speedThreat
    

    local directionToLocal = (localRoot.Position - targetRoot.Position).Unit
    local movementAlignment = directionToLocal:Dot(velocity.Unit)
    if movementAlignment > CONFIG.PREDICTION_THRESHOLD then
        threatLevel = threatLevel + 0.3
    end
    

    local animator = character:FindFirstChild("Humanoid"):FindFirstChild("Animator")
    if animator then
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            if State.knownAnimations[track] then
                threatLevel = threatLevel + 0.4
                break
            end
        end
    end
    
    return math.clamp(threatLevel, 0, 1)
end


RunService.Heartbeat:Connect(function()
    if not State.autoParryEnabled then return end
    
    local highestThreat = 0
    local mostDangerousPlayer = nil
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local threatLevel = calculateThreatLevel(player)
            
            if threatLevel > highestThreat then
                highestThreat = threatLevel
                mostDangerousPlayer = player
            end
            

            if player.Character:FindFirstChild("HumanoidRootPart") then
                PredictionSystem:updateVelocityHistory(player, player.Character.HumanoidRootPart.Velocity)
            end
        end
    end
    

    if highestThreat > 0.6 then
        activateShield(highestThreat)
    end
end)


Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        setupAnimationTracking(character)
    end)
end)


game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.P then
        State.autoParryEnabled = not State.autoParryEnabled
        if CONFIG.DEBUG_MODE then
            print("[mushroom0162 System]: System " .. (State.autoParryEnabled and "enabled" or "disabled"))
        end
    end
end)


for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        setupAnimationTracking(player.Character)
    end
    player.CharacterAdded:Connect(function(character)
        setupAnimationTracking(character)
    end)
end