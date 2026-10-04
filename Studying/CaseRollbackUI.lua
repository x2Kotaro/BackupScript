local Library = loadstring(game:HttpGet("https://valkyriehub.pro/api/raw/ui-lib"))()

--// Theme Setup (Linux Terminal Dark Green Accent)
Library.Theme.Accent = Color3.fromRGB(46, 204, 113)
Library.Theme.AccentGradient = Color3.fromRGB(50, 205, 50)
Library:ChangeTheme("Accent", Color3.fromRGB(46, 204, 113))
Library:ChangeTheme("AccentGradient", Color3.fromRGB(50, 205, 50))

--// Services & References
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

--// Remote References (from CaseScript)
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 5) or ReplicatedStorage
local AwardCaseCosmeticRemote = RemotesFolder:WaitForChild("awardCaseCosmetic", 5)
local CasePurchaseResultEvent = RemotesFolder:WaitForChild("casePurchaseResult", 5)

--// Global State (Clean & Simple)
local DataRollback = false
local TickedRewards = {} -- Selected items to KEEP (string table)

--// Helper: Scan Items in Player Inventory / ReplicatedStorage
local function GetAvailableItems()
    local Items = {}
    
    -- 1. Scan Player Inventory / Data
    local DataFolder = LocalPlayer:FindFirstChild("Data") or LocalPlayer:FindFirstChild("PlayerValues") or LocalPlayer:FindFirstChild("leaderstats")
    if DataFolder then
        local InventoryFolder = DataFolder:FindFirstChild("Inventory") or DataFolder:FindFirstChild("Cosmetics")
        if InventoryFolder then
            for _, Item in ipairs(InventoryFolder:GetChildren()) do
                table.insert(Items, Item.Name)
            end
        end
    end
    
    -- 2. Fallback Default Items List if inventory folder is dynamic/empty
    if #Items == 0 then
        Items = { 
            "Dragon Knife (Secret)", 
            "Shadow Aura (Godly)", 
            "Void Blade (Mythic)", 
            "Cyber Core (Legendary)", 
            "Golden Katana (Rare)", 
            "Flame Particle (Uncommon)" 
        }
    end
    
    return Items
end

local ItemList = GetAvailableItems()

--// Create Minimal Window
local Window = Library:Window({
    Name = "Valkyrie Hub - Case Exploit",
    SubName = "Simple Data Rollback",
    Logo = "118060107907937"
})

Window:Category("Rollback")
local MainPage = Window:Page({ Name = "Data Rollback", Icon = "138827881557940", Columns = 1 })

local MainSection = MainPage:Section({
    Name = "Rollback Controls",
    Description = "Toggle Data Rollback & Select Rewards To Keep",
    Side = 1
})

-- 1. Toggle: Data Rollback (boolean)
MainSection:Toggle({
    Name = "Data Rollback",
    Flag = "DataRollbackToggle",
    Default = false,
    Callback = function(Value)
        DataRollback = (Value == true)
        print("[UI] Data Rollback Enabled:", DataRollback)
        
        if DataRollback and #TickedRewards == 0 then
            warn("[WARNING] Data Rollback is ON but no items are selected in Dropdown! Will rejoin on EVERY roll until an item is selected.")
        end
    end
})

-- 2. Multi-Dropdown: Select Items To Keep (string table)
MainSection:Dropdown({
    Name = "Select Items To Keep",
    Flag = "SelectItemsKeep",
    Items = ItemList,
    Default = { ItemList[1] or "" },
    Multi = true,
    Callback = function(SelectedItems)
        TickedRewards = SelectedItems or {}
        print("[UI] Items to Keep Updated:", table.concat(TickedRewards, ", "))
    end
})

--// Rollback Listener Engine (CaseScript Intercept)
if CasePurchaseResultEvent then
    CasePurchaseResultEvent.OnClientEvent:Connect(function(Payload)
        if not Payload then return end
        
        local CosmeticName = Payload.cosmetic or Payload.name or "Unknown"
        local CosmeticType = Payload.type or "Cosmetic"
        local TransactionId = Payload.transactionId
        
        print("[SERVER ROLL RESULT] Item:", CosmeticName, "| Transaction ID:", TransactionId)
        
        if DataRollback then
            -- Check if rolled item is in selected TickedRewards list
            local IsSelected = false
            for _, SelectedName in ipairs(TickedRewards) do
                if SelectedName == CosmeticName then
                    IsSelected = true
                    break
                end
            end
            
            if IsSelected then
                print("[KEEP] Rolled SELECTED item ('" .. CosmeticName .. "')! Commit to inventory.")
                if AwardCaseCosmeticRemote then
                    AwardCaseCosmeticRemote:FireServer(CosmeticName, CosmeticType, TransactionId)
                end
            else
                -- Not selected -> Skip award remote -> Rejoin immediately to prevent gem spend save
                warn("[ROLLBACK] Rolled UNSELECTED item ('" .. CosmeticName .. "')! Rejoining server to restore Gems...")
                if #Players:GetPlayers() <= 1 then
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                else
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
                end
            end
        else
            -- Data Rollback OFF -> Award item normally
            if AwardCaseCosmeticRemote then
                AwardCaseCosmeticRemote:FireServer(CosmeticName, CosmeticType, TransactionId)
            end
        end
    end)
end

print("[ValkyrieHub] Minimal Case Rollback UI Loaded.")