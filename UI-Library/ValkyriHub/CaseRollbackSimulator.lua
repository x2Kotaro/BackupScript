local Library = loadstring(game:HttpGet("https://valkyriehub.pro/api/raw/ui-lib"))()

--// Theme Setup (Linux Terminal Style)
Library.Theme.Accent = Color3.fromRGB(46, 204, 113)
Library.Theme.AccentGradient = Color3.fromRGB(50, 205, 50)
Library:ChangeTheme("Accent", Color3.fromRGB(46, 204, 113))
Library:ChangeTheme("AccentGradient", Color3.fromRGB(50, 205, 50))

--// Window Initialization
local Window = Library:Window({
    Name = "Valkyrie Hub - Case Exploit",
    SubName = "Ticked Rewards & Auto-Rollback Engine",
    Logo = "118060107907937"
})

Window:Category("Main Exploit")
local MainPage = Window:Page({ Name = "Crate Rollback", Icon = "138827881557940", Columns = 2 })

--// Global State
local Settings = {
    DataRollback = false,
    AutoRoll = false,
    TickedRewards = {} -- Stores rewards user wants to KEEP (string keys)
}

--// SECTION 1: Toggles & Settings
local MainSection = MainPage:Section({
    Name = "Exploit Toggles",
    Description = "Data Rollback & Auto Roll Controls",
    Side = 1
})

-- 1. Data Rollback Toggle (boolean)
MainSection:Toggle({
    Name = "Data Rollback",
    Flag = "DataRollbackToggle",
    Default = false,
    Callback = function(Value)
        Settings.DataRollback = (Value == true)
        print("[Exploit] Data Rollback set to:", Settings.DataRollback)
        
        -- Warning check if turned on with no rewards selected
        if Settings.DataRollback and #Settings.TickedRewards == 0 then
            print("[Warning] 'Data Rollback' is ON but no rewards are ticked! Script will rejoin on EVERY roll until you tick a reward.")
        end
    end
})

-- 2. Auto Roll / Enabled Toggle (boolean)
MainSection:Toggle({
    Name = "Enabled (Auto Roll)",
    Flag = "AutoRollEnabledToggle",
    Default = false,
    Callback = function(Value)
        Settings.AutoRoll = (Value == true)
        print("[Exploit] Auto Roll Enabled:", Settings.AutoRoll)
    end
})

-- Target Case Selection (string)
local SelectedCase = "Cyber Case"
MainSection:Dropdown({
    Name = "Target Case",
    Flag = "TargetCase",
    Items = { "Cyber Case", "Mythic Crate", "Dragon Box", "Godly Chest" },
    Default = "Cyber Case",
    Multi = false,
    Callback = function(Value)
        SelectedCase = tostring(Value)
        print("[Exploit] Target Case Selected:", SelectedCase)
    end
})


--// SECTION 2: Rewards Selector (Ticked Rewards)
local RewardSection = MainPage:Section({
    Name = "Rewards (Ticked List)",
    Description = "Tick rewards you want to keep. Unticked = Rejoin & Rollback",
    Side = 2
})

-- Rewards Multi-Select Dropdown (String array)
RewardSection:Dropdown({
    Name = "Keep Rewards",
    Flag = "TickedRewardsList",
    Items = { 
        "Dragon Knife (Secret)", 
        "Cyber Core (Legendary)", 
        "Shadow Aura (Godly)", 
        "Void Blade (Mythic)",
        "1,000,000 Gems"
    },
    Default = { "Dragon Knife (Secret)" },
    Multi = true,
    Callback = function(SelectedTable)
        Settings.TickedRewards = SelectedTable or {}
        print("[Exploit] Ticked Rewards Updated:", table.concat(Settings.TickedRewards, ", "))
    end
})

--// Roll Simulation Trigger
MainSection:Button({
    Name = "Simulate Case Roll",
    Callback = function()
        print("\n==========================================")
        print("[CRATE OPENING STARTED]")
        print("Selected Case:", SelectedCase)
        print("Data Rollback:", Settings.DataRollback)
        print("Auto Roll Active:", Settings.AutoRoll)
        print("Ticked Rewards to KEEP:", #Settings.TickedRewards > 0 and table.concat(Settings.TickedRewards, ", ") or "NONE (Will Rejoin Always)")

        -- Simulate random outcome roll from server
        local Pool = { 
            "Dragon Knife (Secret)", 
            "Cyber Core (Legendary)", 
            "Common Wooden Sword", 
            "100 Gems", 
            "Shadow Aura (Godly)" 
        }
        local RolledReward = Pool[math.random(1, #Pool)]
        print("[Server Result] Rolled:", RolledReward)

        -- Exploit Logic Verification
        if Settings.DataRollback then
            local IsTicked = false
            for _, Reward in ipairs(Settings.TickedRewards) do
                if Reward == RolledReward then
                    IsTicked = true
                    break
                end
            end

            if IsTicked then
                print("[SUCCESS] Rolled Ticked Reward ('" .. RolledReward .. "')! Script lets you keep it & commits awardCaseCosmetic.")
            else
                print("[ROLLBACK EXPLOIT] Rolled Unticked Reward ('" .. RolledReward .. "'). Rejoining game before roll ends to prevent gem deduction & save state!")
            end
        else
            print("[NORMAL] Data Rollback is OFF. Spent gems and kept item normally.")
        end
        print("==========================================")
    end
})

print("[ValkyrieHub] Rollback Engine Loaded Successfully.")
