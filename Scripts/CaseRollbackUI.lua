local Library = loadstring(game:HttpGet("https://valkyriehub.pro/api/raw/ui-lib"))()

--// Theme Setup (Linux Terminal Dark Green)
Library.Theme.Accent = Color3.fromRGB(46, 204, 113)
Library.Theme.AccentGradient = Color3.fromRGB(50, 205, 50)
Library:ChangeTheme("Accent", Color3.fromRGB(46, 204, 113))
Library:ChangeTheme("AccentGradient", Color3.fromRGB(50, 205, 50))

--// Services & References
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// Remote References (from CaseScript)
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 5) or ReplicatedStorage
local PurchaseCaseRemote = RemotesFolder:WaitForChild("purchaseCase", 5)
local AwardCaseCosmeticRemote = RemotesFolder:WaitForChild("awardCaseCosmetic", 5)
local CasePurchaseResultEvent = RemotesFolder:WaitForChild("casePurchaseResult", 5)

--// Global State
local Settings = {
    DataRollback = false,
    AutoRoll = false,
    TargetCase = "",
    TickedRewards = {}, -- Selected items to KEEP
    InventoryItems = {},
    AvailableCases = {}
}

--// Helper: Scan Data & Inventory in Player
local function ScanPlayerData()
    local Cases = {}
    local Inventory = {}
    
    -- 1. Scan Cases from ReplicatedStorage or PlayerGui
    local ShopCrates = ReplicatedStorage:FindFirstChild("Crates") or ReplicatedStorage:FindFirstChild("Cases")
    if ShopCrates then
        for _, Crate in ipairs(ShopCrates:GetChildren()) do
            table.insert(Cases, Crate.Name)
        end
    else
        -- Fallback default cases if game structure uses config tables
        Cases = { "Common Case", "Uncommon Case", "Rare Case", "Epic Case", "Legendary Case", "Mythic Crate", "Secret Box" }
    end
    
    -- 2. Scan Player's Inventory & Gems Balance
    local DataFolder = LocalPlayer:FindFirstChild("Data") or LocalPlayer:FindFirstChild("PlayerValues") or LocalPlayer:FindFirstChild("leaderstats")
    if DataFolder then
        local InventoryFolder = DataFolder:FindFirstChild("Inventory") or DataFolder:FindFirstChild("Cosmetics")
        if InventoryFolder then
            for _, Item in ipairs(InventoryFolder:GetChildren()) do
                table.insert(Inventory, Item.Name)
            end
        end
    end
    
    -- Default items for UI if inventory folder is dynamic
    if #Inventory == 0 then
        Inventory = { 
            "Dragon Knife (Secret)", 
            "Shadow Aura (Godly)", 
            "Void Blade (Mythic)", 
            "Cyber Core (Legendary)", 
            "Golden Katana (Rare)", 
            "Flame Particle (Uncommon)" 
        }
    end
    
    Settings.AvailableCases = Cases
    Settings.InventoryItems = Inventory
    if #Cases > 0 then Settings.TargetCase = Cases[1] end
end

ScanPlayerData()

--// Create Main Window
local Window = Library:Window({
    Name = "Valkyrie Hub - Case Rollback",
    SubName = "Live Inventory & Case Scanner",
    Logo = "118060107907937"
})

Window:Category("Case Rollback")
local MainPage = Window:Page({ Name = "Crate Rollback", Icon = "138827881557940", Columns = 2 })

--// SECTION 1: Control & Case Selection
local MainSection = MainPage:Section({
    Name = "Controls & Cases",
    Description = "Select target case and toggle rollback",
    Side = 1
})

-- 1. Data Rollback Toggle
MainSection:Toggle({
    Name = "Data Rollback",
    Flag = "DataRollbackToggle",
    Default = false,
    Callback = function(Value)
        Settings.DataRollback = (Value == true)
        print("[UI] Data Rollback:", Settings.DataRollback)
        if Settings.DataRollback and #Settings.TickedRewards == 0 then
            warn("[WARNING] Data Rollback is ON but no rewards are ticked! Script will rejoin on EVERY roll.")
        end
    end
})

-- 2. Auto Roll Toggle
MainSection:Toggle({
    Name = "Auto Roll (Loop Open)",
    Flag = "AutoRollToggle",
    Default = false,
    Callback = function(Value)
        Settings.AutoRoll = (Value == true)
        print("[UI] Auto Roll Enabled:", Settings.AutoRoll)
    end
})

-- 3. Case Selector Dropdown
local CaseDropdown = MainSection:Dropdown({
    Name = "Select Target Case",
    Flag = "TargetCaseSelect",
    Items = Settings.AvailableCases,
    Default = Settings.AvailableCases[1] or "",
    Multi = false,
    Callback = function(Value)
        Settings.TargetCase = tostring(Value)
        print("[UI] Target Case Selected:", Settings.TargetCase)
    end
})

--// SECTION 2: Rewards Selector (Items to Keep)
local RewardSection = MainPage:Section({
    Name = "Rewards To Keep (Ticked)",
    Description = "Tick items you WANT to keep. Unticked items trigger Rejoin",
    Side = 2
})

-- 4. Ticked Rewards Multi-Select Dropdown
local RewardDropdown = RewardSection:Dropdown({
    Name = "Items To Keep",
    Flag = "TickedRewardsList",
    Items = Settings.InventoryItems,
    Default = { Settings.InventoryItems[1] or "" },
    Multi = true,
    Callback = function(SelectedTable)
        Settings.TickedRewards = SelectedTable or {}
        print("[UI] Ticked Rewards Updated:", table.concat(Settings.TickedRewards, ", "))
    end
})

-- 5. Scan & Refresh Inventory Button
RewardSection:Button({
    Name = "Scan Player Inventory & Remotes",
    Callback = function()
        ScanPlayerData()
        CaseDropdown:Refresh(Settings.AvailableCases, Settings.TargetCase)
        RewardDropdown:Refresh(Settings.InventoryItems, Settings.TickedRewards)
        print("[UI] Inventory & Cases Refreshed Live!")
    end
})

--// Rollback Engine Listener (CaseScript Remote Intercept)
if CasePurchaseResultEvent then
    CasePurchaseResultEvent.OnClientEvent:Connect(function(Payload)
        if not Payload then return end
        
        local CosmeticName = Payload.cosmetic or Payload.name or "Unknown"
        local CosmeticType = Payload.type or "Cosmetic"
        local TransactionId = Payload.transactionId
        
        print("[ROLL RESULT] Item:", CosmeticName, "| Transaction ID:", TransactionId)
        
        if Settings.DataRollback then
            -- Check if item is in TickedRewards array
            local IsTicked = false
            for _, TickedName in ipairs(Settings.TickedRewards) do
                if TickedName == CosmeticName then
                    IsTicked = true
                    break
                end
            end
            
            if IsTicked then
                print("[KEEP] Rolled TICKED item ('" .. CosmeticName .. "')! Commit to inventory.")
                if AwardCaseCosmeticRemote then
                    AwardCaseCosmeticRemote:FireServer(CosmeticName, CosmeticType, TransactionId)
                end
                
                if Settings.AutoRoll and PurchaseCaseRemote then
                    task.wait(1.5)
                    PurchaseCaseRemote:FireServer(Settings.TargetCase)
                end
            else
                -- Unticked Item -> Do NOT fire award remote -> Rejoin immediately to rollback gems
                warn("[ROLLBACK] Rolled UNTICKED item ('" .. CosmeticName .. "')! Rejoining server to restore Gems...")
                if #Players:GetPlayers() <= 1 then
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                else
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
                end
            end
        else
            -- Data Rollback OFF -> Normal Award
            if AwardCaseCosmeticRemote then
                AwardCaseCosmeticRemote:FireServer(CosmeticName, CosmeticType, TransactionId)
            end
        end
    end)
end

print("[ValkyrieHub] Interactive Case Rollback UI Loaded Successfully.")
