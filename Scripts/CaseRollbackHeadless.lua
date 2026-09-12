--[[
    Case Rollback Automation Script (Headless / No-UI Version)
    Target Script: Players.<LocalPlayer>.PlayerGui.mainInterface.shop.crates.CaseScript
    
    Mechanism:
    1. Intercept / Hook remotes.purchaseCase:FireServer(caseName) or fire directly.
    2. Wait for casePurchaseResult.OnClientEvent payload (payload.cosmetic, payload.rarity, payload.transactionId).
    3. Check payload against TickedRewards config:
       - If Rolled Cosmetic IS IN TickedRewards -> Fire remotes.awardCaseCosmetic:FireServer(payload.name, payload.type, payload.transactionId) to commit.
       - If Rolled Cosmetic IS NOT IN TickedRewards AND DataRollback IS TRUE -> Skip award remote & Teleport/Rejoin immediately to rollback gem spend.
--]]

--// Configuration (Edit values directly in script)
local Config = {
    DataRollback = true,               -- Boolean: true = Rejoin if reward is not ticked
    AutoRoll = true,                   -- Boolean: true = Loop opening crates automatically
    TargetCase = "Cyber Case",          -- String: Name of the case to buy/open
    
    -- Ticked Rewards (String Array): Item names/IDs you WANT to keep. Anything NOT in this table triggers a rejoin/rollback.
    TickedRewards = {
        ["Dragon Knife (Secret)"] = true,
        ["Shadow Aura (Godly)"] = true,
        ["Void Blade (Mythic)"] = true,
    }
}

--// Services & References
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Locating Remotes based on CaseScript scope
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 5) or ReplicatedStorage
local PurchaseCaseRemote = RemotesFolder:WaitForChild("purchaseCase")
local AwardCaseCosmeticRemote = RemotesFolder:WaitForChild("awardCaseCosmetic")
local CasePurchaseResultEvent = RemotesFolder:WaitForChild("casePurchaseResult")

--// Helper Function: Rejoin Game (Rollback Execution)
local function ExecuteRollback(Reason)
    warn("[ROLLBACK ENGINE] " .. Reason .. " -> Rejoining server immediately!")
    
    if #Players:GetPlayers() <= 1 then
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
end

--// Core Event Listener: Listening to Server Roll Result before Client Spin
local Connection
Connection = CasePurchaseResultEvent.OnClientEvent:Connect(function(Payload)
    if not Payload then return end
    
    local CosmeticName = Payload.cosmetic or Payload.name or "Unknown"
    local CosmeticType = Payload.type or "Cosmetic"
    local TransactionId = Payload.transactionId
    
    print("[SERVER ROLL RESULT] Item:", CosmeticName, "| Transaction ID:", TransactionId)
    
    if Config.DataRollback then
        local IsTicked = Config.TickedRewards[CosmeticName] == true
        
        if IsTicked then
            print("[KEEP REWARD] Item '" .. CosmeticName .. "' is TICKED! Firing awardCaseCosmetic to commit to inventory...")
            AwardCaseCosmeticRemote:FireServer(CosmeticName, CosmeticType, TransactionId)
            
            -- If AutoRoll is active, trigger next case after brief delay
            if Config.AutoRoll then
                task.wait(1.5)
                PurchaseCaseRemote:FireServer(Config.TargetCase)
            end
        else
            -- Item is UNTICKED -> Do NOT fire award remote -> Rejoin immediately to prevent gem spend save
            ExecuteRollback("Rolled unticked item '" .. CosmeticName .. "'")
        end
    else
        -- Data Rollback is OFF -> Always commit item normally
        AwardCaseCosmeticRemote:FireServer(CosmeticName, CosmeticType, TransactionId)
    end
end)

--// Trigger Logic / Main Loop
local function StartRollbackEngine()
    print("[CASE ROLLBACK HEADLESS] Script Started.")
    print(" - Data Rollback:", Config.DataRollback)
    print(" - Target Case:", Config.TargetCase)
    
    -- Check warning condition: DataRollback ON but zero ticked rewards
    local HasTicked = false
    for _ in pairs(Config.TickedRewards) do HasTicked = true break end
    
    if Config.DataRollback and not HasTicked then
        warn("[WARNING] Data Rollback is ON but NO rewards are ticked! Script will rejoin on EVERY roll.")
    end
    
    -- Fire initial case purchase if AutoRoll is true
    if Config.AutoRoll then
        print("[AUTO ROLL] Buying case:", Config.TargetCase)
        PurchaseCaseRemote:FireServer(Config.TargetCase)
    end
end

-- Run Headless Script
task.spawn(StartRollbackEngine)
