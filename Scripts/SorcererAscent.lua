pcall(function()
    game.Players.LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
end)

getgenv().ConfigurationTable = {}
getgenv().Settings = {}
 
local FolderConfiguration = "Venuz Hub"
local FolderSettings = "Venuz Hub/SORCERER_ASCENT"
local FolderSlots = "Venuz Hub/Slots"
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local chr = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local hrp = chr:WaitForChild("HumanoidRootPart")
local humanoid = chr:WaitForChild("Humanoid")

local HttpService = game:GetService("HttpService")
local VenuzIcon = "rbxassetid://92691624917972"
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local UserId = LocalPlayer.UserId
local currentTime = os.date("%H:%M:%S")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CollectionService = game:GetService("CollectionService")

local ConfigGame = require(game:GetService("ReplicatedStorage").Scripts.Config.Config)

local Village = {["Kitagawa Village"] = CFrame.new(-1962, 4, -2871),["Ruined Fuijihara Village"] = CFrame.new(-370, 78, -1864),["Hotarugawa Town"] = CFrame.new(431, 3, -272),["Jujutsu High"] = CFrame.new(-2110, 102, -381),["Minagata Village"] = CFrame.new(-3009, 3, -1750),["Kanazawa Town"] = CFrame.new(-3375, 4, 2156),["Kaito Village"] = CFrame.new(-1409, 17, 1475),["Yoshiwara City"] = CFrame.new(-5644, 3, -314),}

local NPCByVillage = {
    ["Kitagawa Village"] = {
        ["Emi"] = CFrame.new(-1664, 3, -2904),
        ["Genshiro"] = CFrame.new(-1735, 38, -2607),
        ["Hina"] = CFrame.new(-1552, 3, -2797),
        ["Ren"] = CFrame.new(-1731, 3, -3133),
        ["Tanosuke"] = CFrame.new(-1273, 3, -3107),
        ["Ui Ui"] = CFrame.new(-1980, 3, -2871),
    },

    ["Ruined Fuijihara Village"] = {
        ["Chiyeko"] = CFrame.new(159, 79, -1776),
        ["Dai"] = CFrame.new(-392, 88, -1721),
        ["Hirotaka"] = CFrame.new(-364, 103, -1598),
        ["Juro"] = CFrame.new(-920, 3, -1628),
        ["Masayoshi"] = CFrame.new(-175, 3, -1800),
        ["Norihide"] = CFrame.new(-57, 89, -1946),
        ["Ryobe"] = CFrame.new(-403, 78, -1852),
        ["Yui"] = CFrame.new(303, 23, -1758),
    },

    ["Hotarugawa Town"] = {
        ["Hosuzu"] = CFrame.new(566, 3, -89),
        ["Ijichi"] = CFrame.new(592, 6, -436),
        ["Juzo"] = CFrame.new(563, 3, -230),
        ["Kamlyn"] = CFrame.new(706, 3, -417),
        ["Kanna"] = CFrame.new(443, 3, 17),
        ["Masayoshi"] = CFrame.new(747, 3, -581),
        ["Satoshi"] = CFrame.new(239, 3, -73),
        ["Ui Ui"] = CFrame.new(394, 4, -307),
        ["Yudai"] = CFrame.new(289, 3, -530),
    },

    ["Jujutsu High"] = {
        ["Hatomi"] = CFrame.new(-2269, 102, -159),
        ["Ijichi"] = CFrame.new(-2349, 106, -296),
        ["Juzo"] = CFrame.new(-2380, 102, -540),
        ["Kusakabe"] = CFrame.new(-2897, 128, -15),
        ["Miwa"] = CFrame.new(-2891, 128, -176),
        ["Nakamaro"] = CFrame.new(-2401, 102, -2),
        ["Shlu Kong"] = CFrame.new(-2086, 92, -256),
        ["Takeji"] = CFrame.new(-2109, 102, -826),
        ["Ui Ui"] = CFrame.new(-2349, 106, -463),
        ["Yaga"] = CFrame.new(-2369, 102, -379),
    },

    ["Minagata Village"] = {
        ["Kiyonaga"] = CFrame.new(-3340, 4, -2261),
        ["Arata"] = CFrame.new(-3180, 3, -2574),
        ["Kozue"] = CFrame.new(-2847, 3, -1848),
        ["Sanako"] = CFrame.new(-2409, 3, -2311),
        ["Shigemori"] = CFrame.new(-3166, -1, -1779),
        ["Toyoharu"] = CFrame.new(-3006, 4, -2310),
        ["Ui Ui"] = CFrame.new(-3037, 17, -2142),
        ["Utemaro"] = CFrame.new(-3268, -1, -1729),
    },

    ["Kanazawa Town"] = {
        ["Asami"] = CFrame.new(-3861, 4, 2023),
        ["Kosaku"] = CFrame.new(-3283, 4, 2073),
        ["Kumiyo"] = CFrame.new(-3200, 4, 2293),
        ["Masayoshi"] = CFrame.new(-3389, 4, 2432),
        ["Roka"] = CFrame.new(-3481, 4, 1898),
        ["Tadashi"] = CFrame.new(-3320, 4, 2169),
        ["Toshi"] = CFrame.new(-3200, 4, 2300),
        ["Ui Ui"] = CFrame.new(-3382, 4, 2293),
    },

    ["Kaito Village"] = {
        ["Farmer Joe"] = CFrame.new(-1132, 3, 1270),
        ["Ichisake"] = CFrame.new(-1555, 3, 1586),
        ["Maro"] = CFrame.new(-2095, 23, 1075),
        ["Orihime"] = CFrame.new(-1181, 3, 1500),
        ["Shunsho"] = CFrame.new(-1559, 3, 1300),
        ["Ui Ui"] = CFrame.new(-1395, 5, 1446),
    },

    ["Yoshiwara City"] = {
        ["Tatsui"] = CFrame.new(-5088, 3, -638),
    },
}

local VillageOrder = {"Kitagawa Village","Ruined Fuijihara Village","Hotarugawa Town","Jujutsu High","Minagata Village","Kanazawa Town","Kaito Village","Yoshiwara City",}

local SelectEnemiesTable = {}
local SelectBossTable = {}

getgenv().IsDoingWorldEvent = false


local function CleanEnemyName(name)
    if not name then return "" end
    local baseName = name:match("^(.-)%s*<") or name
    return baseName:match("^%s*(.-)%s*$") or baseName
end

getgenv().EnemyZones = {}
getgenv().AvoidedZones = getgenv().AvoidedZones or {}

if game.PlaceId == 16997064928 then
    getgenv().PredefinedZones = {
        ["Fly Curse"] = CFrame.new(-2424, 3, -1237),
        ["Hotarugawa Soldier"] = CFrame.new(363, 3, -195),
        ["Kanazawa Soldier"] = CFrame.new(-3899, 3, 2197),
        ["Kato Soldier"] = CFrame.new(-5254, 3, -690),
        ["Kato Strong Soldier"] = CFrame.new(-6043, 3, -136),
        ["Log"] = CFrame.new(-1765, 3, -3060),
        ["Minagata Soldier"] = CFrame.new(-2965, 6, -1620),
        ["Skitterface Curse"] = CFrame.new(-102, 3, 546),
        ["Strong Kanazawa Soldier"] = CFrame.new(-3817, 42, 2113),
        ["Temple Curse"] = CFrame.new(-869, 149, 1630),
        ["Town Curse"] = CFrame.new(487, 3, -610),
        ["Village Invader"] = CFrame.new(-213, 93, -1695),
        ["Village Thief"] = CFrame.new(-1296, 3, -2821),
    }

    for name, cf in pairs(getgenv().PredefinedZones) do
        getgenv().EnemyZones[name] = cf.Position
    end

    getgenv().BossSpawnPoints = {
        ["Yasue Toru"] = {
            CFrame.new(-5574, 3, 85),
        },
        ["Village Invaders Leader"] = {
            CFrame.new(-26, 88, -2020),
        },
        ["Town Warden"] = {
            CFrame.new(717, 3, -135),
        },
        ["Lieutenant"] = {
            CFrame.new(-3263, -1, -2084),
        },
        ["Yuji Itadori"] = {
            CFrame.new(-2722, 82, -773),
        },
        ["Nanami Kento"] = {
            CFrame.new(-1543, 78, -114),
        },
        ["Vice-Captain"] = {
            CFrame.new(-3939, 146, 2356),
        },
        ["Ryoma's Soul"] = {
            CFrame.new(-570, 160, 1775),
        },
        ["Grasshopper Curse"] = {
            CFrame.new(-1437, 79, -475),
            CFrame.new(-3625, 3, 75),
            CFrame.new(-4293, 3, -525),
        },
        ["Kato Akumori"] = {
            CFrame.new(-6240, 156, -1397),
        },
        ["Wraithblue Curse"] = {
            CFrame.new(-3397, 3, 1294),
        },
    }

    getgenv().BossZones = {}
    for name, cfList in pairs(getgenv().BossSpawnPoints) do
        getgenv().BossZones[name] = cfList[1].Position
    end
end

local SilentVisuals = {
    CurrentHighlight = nil,
    CurrentBeam = nil,
    Attachment0 = nil,
    Attachment1 = nil,
    Billboard = nil
}

function SilentVisuals.Show(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    
    -- Create Highlight
    if not SilentVisuals.CurrentHighlight or SilentVisuals.CurrentHighlight.Parent ~= targetPlayer.Character then
        if SilentVisuals.CurrentHighlight then SilentVisuals.CurrentHighlight:Destroy() end
        local highlight = Instance.new("Highlight")
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = targetPlayer.Character
        SilentVisuals.CurrentHighlight = highlight
    end
    
    -- Create BillboardGui
    if not SilentVisuals.Billboard or SilentVisuals.Billboard.Parent ~= targetPlayer.Character:FindFirstChild("Head") then
        if SilentVisuals.Billboard then SilentVisuals.Billboard:Destroy() end
        
        local head = targetPlayer.Character:FindFirstChild("Head")
        if head then
            local bb = Instance.new("BillboardGui")
            bb.Adornee = head
            bb.Size = UDim2.new(0, 200, 0, 50)
            bb.StudsOffset = Vector3.new(0, 3, 0)
            bb.AlwaysOnTop = true
            
            local text = Instance.new("TextLabel")
            text.Size = UDim2.new(1, 0, 1, 0)
            text.BackgroundTransparency = 1
            text.Text = "AVOIDING"
            text.TextColor3 = Color3.fromRGB(255, 0, 0)
            text.TextStrokeTransparency = 0
            text.TextScaled = true
            text.Parent = bb
            
            bb.Parent = head
            SilentVisuals.Billboard = bb
        end
    end

    -- Update Highlight Color from Settings (Optional: User asked for indicator, maybe keep Highlight customizable but Beam RED)
    if getgenv().Settings.Automatic.AutoFarm.SilentColor then
        local color = getgenv().Settings.Automatic.AutoFarm.SilentColor
        if SilentVisuals.CurrentHighlight then
            SilentVisuals.CurrentHighlight.FillColor = Color3.fromRGB(color.r, color.g, color.b)
        end
    end
    
    -- Create Beam (Thin and Always Red)
    if not SilentVisuals.CurrentBeam then
        local att0 = Instance.new("Attachment")
        local att1 = Instance.new("Attachment")
        
        local beam = Instance.new("Beam")
        beam.FaceCamera = true
        beam.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0)) -- Always Red
        beam.Width0 = 0.05 -- Thin line
        beam.Width1 = 0.05
        beam.Attachment0 = att0
        beam.Attachment1 = att1
        beam.Parent = workspace.Terrain
        
        SilentVisuals.Attachment0 = att0
        SilentVisuals.Attachment1 = att1
        SilentVisuals.CurrentBeam = beam
    end
    
    -- Update Beam Positions
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and 
       targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        
        SilentVisuals.Attachment0.Parent = LocalPlayer.Character.HumanoidRootPart
        SilentVisuals.Attachment1.Parent = targetPlayer.Character.HumanoidRootPart
        -- Beam color remains Red as requested
    end
end

function SilentVisuals.Hide()
    if SilentVisuals.CurrentHighlight then
        SilentVisuals.CurrentHighlight:Destroy()
        SilentVisuals.CurrentHighlight = nil
    end
    
    if SilentVisuals.Billboard then
        SilentVisuals.Billboard:Destroy()
        SilentVisuals.Billboard = nil
    end
    
    if SilentVisuals.CurrentBeam then
        SilentVisuals.CurrentBeam:Destroy()
        SilentVisuals.CurrentBeam = nil
    end
    
    if SilentVisuals.Attachment0 then
        SilentVisuals.Attachment0:Destroy()
        SilentVisuals.Attachment0 = nil
    end
    
    if SilentVisuals.Attachment1 then
        SilentVisuals.Attachment1:Destroy()
        SilentVisuals.Attachment1 = nil
    end
end

local function IsInAvoidedZone(position)
    local currentTime = os.time()
    for zonePos, expireTime in pairs(getgenv().AvoidedZones) do
        -- ลบโซนที่หมดเวลาแล้ว
        if currentTime >= expireTime then
            getgenv().AvoidedZones[zonePos] = nil
        else
            -- เช็คระยะห่าง ถ้าอยู่ในรัศมี 50 studs ถือว่าอยู่ในโซนเดียวกัน
            local distance = (position - zonePos).Magnitude
            if distance < 50 then
                return true
            end
        end
    end
    return false
end

local function ServerHop()
    local PlaceId = game.PlaceId
    local list = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
    for _, v in ipairs(list.data) do
        if v.playing < v.maxPlayers and v.id ~= game.JobId then
            game:GetService("TeleportService"):TeleportToPlaceInstance(PlaceId, v.id, game.Players.LocalPlayer)
            break
        end
    end
end

local Enemies = {}
local addedNames = {}

local Bosses = {}
local addedBossNames = {}
task.spawn(function()
    if game.PlaceId == 16997064928 and getgenv().BossSpawnPoints then
        for name, _ in pairs(getgenv().BossSpawnPoints) do
            if not addedBossNames[name] then
                table.insert(Bosses, name)
                addedBossNames[name] = true
            end
        end
    end
    if #Bosses > 0 then
        table.sort(Bosses)
    end
end)
task.spawn(function()
    if game.PlaceId == 16997064928 and getgenv().PredefinedZones then
        for name, _ in pairs(getgenv().PredefinedZones) do
            if not addedNames[name] then
                table.insert(Enemies, name)
                addedNames[name] = true
            end
        end
    else
        local success, MobsModule = pcall(function()  
            return require(game:GetService("ReplicatedStorage").Scripts.Mobs.Mobs)
        end)
        if success and MobsModule and MobsModule.Mobs then
            for _, mob in pairs(MobsModule.Mobs) do
                if mob.Name and not table.find(Enemies, mob.Name) then
                    table.insert(Enemies, mob.Name)
                end
            end
        end
    end
    
    if #Enemies > 0 then
        table.sort(Enemies)
    end
end)

local PlayersTable = {}
local AddedPlayer = {}

local filenameConfiguration = FolderConfiguration .. "/" .. "Setting_".. LocalPlayer.Name .. ".json"
local filenameSetting = FolderSettings .. "/" .. "GameConfig_".. LocalPlayer.Name..".json"

---- ============ Configuration ============ ---- 

local DefaultConfiguration = {
    ["Themes"] = "Crimson",
    ["Transparent"] = true,
    ["AntiAFK"] = true,
    ["AutoRejoin"] = false,
    ["AutoExecutor"] = true,
    ["MinimizeBind"] = "End",
    ["Language"] = "English (US)",
    ["FPSValue"] = 144,
    ["LockFPS"] = false,
    ["WhileScreen"] = false,
}

local function MergeConfiguration(loaded, defaults)
    for key, defaultValue in pairs(defaults) do
        if type(defaultValue) == "table" then
            loaded[key] = MergeConfiguration(loaded[key] or {}, defaultValue)
        else
            if loaded[key] == nil then
                loaded[key] = defaultValue
            end
        end
    end
    return loaded
end

function LoadConfiguration()
    if readfile and isfile and isfile(filenameConfiguration) then
        local data = readfile(filenameConfiguration)
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(data)
        end)

        if success and type(decoded) == "table" then
            getgenv().ConfigurationTable = MergeConfiguration(decoded, DefaultConfiguration)
        else
            warn("[Configuration] Failed to decode, using default.")
            getgenv().ConfigurationTable = DefaultConfiguration
        end
    else
        getgenv().ConfigurationTable = DefaultConfiguration
    end
end

function SaveConfiguration()
    if writefile and makefolder then
        if not isfolder("Venuz Hub") then makefolder("Venuz Hub") end
        if not isfolder(FolderConfiguration) then makefolder(FolderConfiguration) end

        local json = HttpService:JSONEncode(getgenv().ConfigurationTable)
        writefile(filenameConfiguration, json)
    end
end

LoadConfiguration()

---- ============ SaveSettings ============ ----

local DefaultSettings = {
    ["Automatic"] = {
        ["FarmConfig"] = {
            ["TweenSpeed"] = 300,
            ["Distance"] = 0,
            ["KillAura"] = false,
        },

        ["AutoFarm"] = {
            ["AutoFarmEnemies"] = false,
            ["SelectEnemy"] = {},
            ["MethodEnemies"] = "Over",
            ["SilentMode"] = false,
            ["SilentDistance"] = 50,
            ["SilentColor"] = {r = 255, g = 0, b = 0},
            ["SelectBoxOfLuck"] = {},
            ["AutoBoxOfLuck"] = false,
        },

        ["AutoWorldEvents"] = false,

        ["AutoBoss"] = {
            ["AutoFarmBoss"] = false,
            ["SelectBoss"] = {},
            ["MethodBoss"] = "Over",
            ["HopIfNoBoss"] = false,
        },

        ["AutoStats"] = {
            ["Stats"] = {},
            ["Amount"] = 0,
            ["AutoStats"] = false,
        },
    },

    ["Player"] = {
        ["Modify"] = {
            ["WalkSpeed"] = 16,
            ["WalkSpeedE"] = false,
            ["JumpPower"] = 50,
            ["JumpPowerE"] = false,
            ["DashNoCooldown"] = false,
            ["InfiniteCE"] = true,
            ["StreamerMode"] = false,
        },
    },

    ["Premium"] = {
        ["AutoParry"] = false,
        ["Dungeons"] = {
            ["SelectDungeon"] = "Hotarugawa Dungeon",
            ["AutoDungeon"] = false,
        },
        ["Raid"] = {
            ["AutoRaid"] = false,
            ["ToSafeZone"] = 30,
        },
        ["Grade"] = {
            ["AutoJoinGrade"] = false,
            ["AutoGrade"] = false,
            ["ToSafeZone"] = 30,
        },
        ["Challenge"] = {
            ["SelectChallenge"] = {"Temple Challenge"},
            ["AutoChallenge"] = false,
            ["AutoJoinChallenge"] = false,
            ["ToSafeZone"] = 30,
        },
    }
}

local function MergeSettings(defaults, loaded)
    for k,v in pairs(defaults) do
        if type(v) == "table" then
            if type(loaded[k]) ~= "table" then
                loaded[k] = v
            else
                MergeSettings(v, loaded[k])
            end
        else
            if loaded[k] == nil then
                loaded[k] = v
            end
        end
    end
end

function LoadSettings()
    if readfile and isfile and isfile(filenameSetting) then
        local loaded = HttpService:JSONDecode(readfile(filenameSetting))
        MergeSettings(DefaultSettings, loaded)
        getgenv().Settings = loaded
    else
        getgenv().Settings = DefaultSettings
    end
end

function SaveSetting()
    if writefile and makefolder then
        if not isfolder("Venuz Hub") then makefolder("Venuz Hub") end
        if not isfolder(FolderSettings) then makefolder(FolderSettings) end
        local json = HttpService:JSONEncode(getgenv().Settings)
        writefile(filenameSetting, json)
    end
end

LoadSettings()

if getgenv().Configuration and next(getgenv().Configuration) then
    for key, value in pairs(getgenv().Configuration) do
        if getgenv().Settings[key] ~= nil then
            getgenv().Settings[key] = value
        end
    end
    SaveSetting()
end

---- ============ CheckRole ============ ----

local KeyFile = "Venuz Hub/KeySystem".."/".."VenuzKey"..".txt"
local api = loadstring(game:HttpGet("https://sdkapi-public.luarmor.net/library.lua"))()
api.script_id = "274209c355e95ffe3ba729826b475b88"

local status = api.check_key(readfile(KeyFile))

if status.code == "KEY_VALID" then
    if status.data.note == "Premium" then
        getgenv().Premium = false
        getgenv().IsPremium = "Premium Access"
    else
        getgenv().Premium = true
        getgenv().IsPremium = "Standard"
    end
end

---- ============ Interface ============ ----

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/x2Kotaro/API/main/test.lua"))()

local Device
if UserInputService.TouchEnabled then
    Device = UDim2.fromOffset(450, 300)
else
    Device = UDim2.fromOffset(650, 520)
end

WindUI:Localization({
    Enabled = true,
    Prefix = "tr:",
    DefaultLanguage = getgenv().ConfigurationTable.Language,
    Translations = {
        ["Thai"] = {
            --Tabs
            ["Automaic"] = "หน้าหลัก",
            ["AutoFarm"] = "หน้าหลัก",
            ["Teleport"] = "เทเลพอร์ต",
            ["Players"] = "ผู้เล่น",
            ["AutoStatsTab"] = "ออโต้อัพค่าสถานะ",
            --Automatic
             -- Main
             -- Farm Config
             ["FarmConfigTab"] = "ตั้งค่าฟาร์ม",
             ["TweenSpeed"] = "ความเร็วเคลื่อนที่",
             ["Distance"] = "ระยะห่าง",
             ["KillAura"] = "ฆ่ามอนรอบตัว",
             -- Auto Farm Enemies
             ["AutoFarmEnemiesTab"] = "ออโต้ฟาร์มมอน",
             ["SelectEnemies"] = "เลือกมอน",
             ["MethodEnemies"] = "วิธีการฟาร์มมอน",
             ["AutoFarm"] = "ฟาร์มออโต้",
             ["SilentMode"] = "โหมดเงียบ",
             ["SilentDistance"] = "ระยะตรวจจับผู้เล่น",
             ["SilentCircleColor"] = "ปรับสีวงกลม",
             ["BoxOfLuck"] = "กล่องโชค",
             ["SelectBoxOfLuck"] = "เลือกกล่องโชค",
             ["AutoBoxOfLuck"] = "ออโต้เปิดกล่องโชค",
             -- Auto Boss
             ["AutoFarmBossTab"] = "ออโต้ฟาร์มบอส",
             ["SelectBoss"] = "เลือกบอส",
             ["MethodBoss"] = "วิธีการฟาร์มบอส",
             ["AutoFarmBoss"] = "ฟาร์มบอสออโต้",
             ["HopIfNoBoss"] = "ย้ายเซิฟเมื่อไม่เจอบอส",
             ["HopIfNoBossDesc"] = "ย้ายเซิฟเวอร์ทันทีถ้าไม่เจอบอสที่เลือก",
             -- Auto World Events
             ["AutoWorldEventsTab"] = "อีเว้นท์โลก",
             ["AutoWorldEvents"] = "ออโต้ทำอีเว้นท์โลก",
             -- AutoStats
             ["Stats"] = "ค่าสถานะ",
             ["Amount"] = "จำนวน",
             ["AutoStats"] = "ออโต้อัพค่าสถานะ",
            -- Players
             -- Player
             ["SelectPlayer"] = "เลือกผู้เล่น",
             ["descriptsp"] = "จำกัดการค้นหาผู้เล่นอยู่ที่ 1000 ms",
             ["SpectatorPlayer"] = "ดูผู้เล่น",
             ["WalkSpeed"] = "ความเร็วเดิน",
             ["JumpPower"] = "พลังกระโดด",
             ["Enabled"] = "เปิดใช้งาน",
             ["DashNoCooldown"] = "แดชไม่มีคูลดาวน์",
             ["InfiniteCE"] = "พลังงานไสยเวทย์ไม่จำกัด",
             ["StreamerMode"] = "โหมดสตรีมเมอร์",
             -- Teleport
             ["Village"] = "หมู่บ้าน",
             ["Teleport"] = "วาป",
             ["NpcQuestNow"] = "เควสที่เราทำเควสปัจจุบัน",
            -- Premium
             -- AutoParry
             ["None"] = "ไม่มี",
             ["Premium"] = "พรีเมี่ยม",
             ["AutoParry"] = "ปัดป้องอัตโนมัติ",
             ["TargetStatus"] = "สถานะเป้าหมาย",
             ["Dungeons"] = "ดันเจี้ยน",
             ["SelectDungeon"] = "เลือกดันเจี้ยน",
             ["AutoDungeon"] = "ลงดันเจี้ยนอัตโนมัติ",
             ["Raid"] = "เรด",
             ["AutoRaid"] = "ลงเรดอัตโนมัติ",
             ["ToSafeZone"] = "เลือดตํ่ากว่า % หนีลงดิน",
             ["SafeHealth"] = "ปลอดภัย : กำลังฟื้นฟู",
             ["Grade"] = "เกรด",
             ["AutoJoinGrade"] = "รับภารกิจ",
             ["AutoGrade"] = "ลงเกรดอัตโนมัติ",
             ["Challenge"] = "ชาเลนจ์",
             ["SelectChallenge"] = "เลือกชาเลนจ์",
             ["AutoChallenge"] = "ลงชาเลนจ์อัตโนมัติ",
             ["AutoJoinChallenge"] = "ออโต้เข้าร่วมชาเลนจ์",
            -- Settings
            ["Interface"] = "การตั้งค่า",
            ["themeDropdown"] = "เลือก ธีม",
            ["ToggleTransparency"] = "UI โปรพื้นหลังโปร่งใส่",
            ["AntiAFK"] = "ป้องกันหลุดออกจากเกม (Anti-AFK)",
            ["AutoRejoin"] = "เข้าร่วมเกมอัตโนมัติเมื่อหลุด (AutoRejoin)",
            ["AutoExecutor"] = "รันโปรออโต้เมื่อย้ายเซิฟ (AutoExecutor)",
            ["MinimizeBind"] = "ปุ่มที่จะใช้เปิดปิดโปร",
            ["FPSIS"] = "FPS",
            ["FPSVALUE"] = "FPS",
            ["FPSLOCK"] = "ล็อค FPS",
            ["WhiteScreen"] = "จอขาว",
            ["LanguageTab"] = "ภาษา",
            ["Language"] = "เลือกภาษา",
            ["ChangedLanguage"] = "เปลี่ยนภาษา",
            ["Configuration"] = "ตั้งค่า",
            ["ScriptLoader"] = "สคริปต์ | โหลดเดอร์",
            ["ScriptLoaded"] = "โหลดสคริปต์สำเร็จ",
        },
        ["English (US)"] = {
            --Tabs
            ["Automaic"] = "Main",
            ["AutoFarm"] = "Main",
            ["Teleport"] = "Teleport",
            ["Players"] = "Players",
            ["AutoStatsTab"] = "Auto Stats",
            --Automatic
             -- Main
             -- Farm Config
             ["FarmConfigTab"] = "Farm Config",
             ["TweenSpeed"] = "Tween Speed",
             ["Distance"] = "Distance",
             ["KillAura"] = "Kill Aura",
             -- Auto Farm Enemies
             ["AutoFarmEnemiesTab"] = "Auto Farm Enemies",
             ["SelectEnemies"] = "Select Enemies",
             ["MethodEnemies"] = "Method Farm Enemies",
             ["AutoFarm"] = "Auto Farm",
             ["SilentMode"] = "Silent Mode",
             ["SilentDistance"] = "Player Detection Distance",
             ["SilentCircleColor"] = "Adjust Circle Color",
             ["BoxOfLuck"] = "Box of Luck",
             ["SelectBoxOfLuck"] = "Select Box of Luck",
             ["AutoBoxOfLuck"] = "Auto Open Box of Luck",
             -- Auto Boss
             ["AutoFarmBossTab"] = "Auto Farm Boss",
             ["SelectBoss"] = "Select Boss",
             ["MethodBoss"] = "Method Farm Boss",
             ["AutoFarmBoss"] = "Auto Farm Boss",
             ["HopIfNoBoss"] = "Hop Server",
             ["HopIfNoBossDesc"] = "Auto hop server if don't have boss select",
             -- Auto World Events
             ["AutoWorldEventsTab"] = "World Events",
             ["AutoWorldEvents"] = "Auto World Events",
             -- AutoStats
             ["Stats"] = "Stats",
             ["Amount"] = "Amount",
             ["AutoStats"] = "Auto Stats",
            -- Players
             ["SelectPlayer"] = "Select Player",
             ["descriptsp"] = "Limit player search to 1000 ms",
             ["SpectatorPlayer"] = "Spectator Player",
             ["WalkSpeed"] = "Walk Speed",
             ["JumpPower"] = "Jump Power",
             ["Enabled"] = "Enabled",
             ["DashNoCooldown"] = "Dash No Cooldown",
             ["InfiniteCE"] = "Infinite CE",
             ["StreamerMode"] = "Streamer Mode",
             -- Teleport
             ["Village"] = "Village",
             ["Teleport"] = "Teleport",
             ["NpcQuestNow"] = "Quest Now",
            -- Premium
             -- AutoParry
             ["None"] = "None",
             ["Premium"] = "Premium",
             ["AutoParry"] = "Auto Parry",
             ["TargetStatus"] = "Target Status",
             ["Dungeons"] = "Dungeons",
             ["SelectDungeon"] = "Select Dungeon",
             ["AutoDungeon"] = "Auto Dungeon",
             ["Raid"] = "Raid",
             ["AutoRaid"] = "Auto Colosseum Raid",
              ["ToSafeZone"] = "Health % To SafeZone",
              ["SafeHealth"] = "Safe : Regenerating",
              ["Grade"] = "Grade",
              ["AutoJoinGrade"] = "Auto Join Grade",
              ["AutoGrade"] = "Auto Grade",
              ["Challenge"] = "Challenge",
              ["SelectChallenge"] = "Select Challenge",
              ["AutoChallenge"] = "Auto Challenge",
              ["AutoJoinChallenge"] = "Auto Join Challenge",
            -- Settings
            ["Interface"] = "Interface Settings",
            ["themeDropdown"] = "Select Theme",
            ["ToggleTransparency"] = "Toggle Window Transparency",
            ["AntiAFK"] = "Anti-AFK",
            ["AutoRejoin"] = "AutoRejoin",
            ["AutoExecutor"] = "AutoExecutor",
            ["MinimizeBind"] = "Minimize Bind",
            ["FPSIS"] = "FPS",
            ["FPSVALUE"] = "FPS",
            ["FPSLOCK"] = "FPS Lock",
            ["WhiteScreen"] = "White Screen",
            ["LanguageTab"] = "LanguageTab",
            ["Language"] = "Select Language",
            ["ChangedLanguage"] = "Change Language",
            ["Configuration"] = "Configuration",
            ["ScriptLoader"] = "Script | Loader",
            ["ScriptLoaded"] = "Script Loader Successfully",
        },
    }
})

local CurrentLanguage = getgenv().ConfigurationTable.Language

if CurrentLanguage == "English (US)" then
    WindUI:SetLanguage("English (US)")
else
    WindUI:SetLanguage("Thai")
end

local Window = WindUI:CreateWindow({
    Title = "Venuz Hub",
    Icon = VenuzIcon,
    Author = "by Phoenix",
    Size = Device,
    Transparent = getgenv().ConfigurationTable.Transparent,
    Theme = getgenv().ConfigurationTable.Themes,
    SideBarWidth = 200,
    HasOutline = true,
    ScrollBarEnabled = true,
    Resizable = false,
})

Window:Tag({
    Title = getgenv().IsPremium,
    Color = Color3.fromHex("#30ff6a"),
    Radius = 13,
})

Window:Tag({
    Title = "Update Latest 2/19/2026",
    Color = Color3.fromHex("#f4fc02"),
    Radius = 13,
})

Window:EditOpenButton({
    Title = "Venuz Hub",
    Icon = VenuzIcon,
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromHex("FF0F7B"), 
        Color3.fromHex("F89B29")
    ),
    OnlyMobile = true,
    Enabled = true,
    Draggable = true,
})

---- ============ Funtion ============ ----

local function CheckItem(itemName, mode)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local success, DataPlayer = pcall(function() 
        return ReplicatedStorage.Remotes.GetData:InvokeServer(game.Players.LocalPlayer) 
    end)
    if not success or not DataPlayer then return nil end

    local successItems, Items = pcall(function()
        return require(ReplicatedStorage.Scripts.Items.Items)
    end)
    if not successItems or not Items then return nil end
    
    local IndexMap = {}
    for name, data in pairs(Items) do
        IndexMap[data.Index] = name
    end
    
    if DataPlayer.Inventory then
        for uuid, itemData in pairs(DataPlayer.Inventory) do
            local currentItemName = IndexMap[itemData.Index]
            if currentItemName == itemName then
                if mode == "value" then
                    return true
                elseif mode == "name" then
                    return uuid
                else
                    return uuid
                end
            end
        end
    end
    
    if mode == "value" then
        return false
    end
    
    return nil
end

local NoClipConnection = nil
local ActiveTween = nil

function StartNoClip()
    if NoClipConnection then return end
    
    NoClipConnection = RunService.Stepped:Connect(function()
        local character = game.Players.LocalPlayer.Character
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Velocity = Vector3.new(0, 0, 0)
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                hrp.RotVelocity = Vector3.new(0, 0, 0)
            end
        end
    end)
end

function StopNoClip()
    if NoClipConnection then
        NoClipConnection:Disconnect()
        NoClipConnection = nil
    end
end

function TweenFarm(P, speed)
    if ActiveTween then
        ActiveTween:Cancel()
        ActiveTween = nil
    end

    local undergroundDepth = -50
    local humanoidRootPart = game.Players.LocalPlayer.Character.HumanoidRootPart
    local tweenService = game:GetService("TweenService")

    -- เก็บ orientation เดิมของตัวละคร (แค่การหมุนแกน Y)
    local originalCFrame = humanoidRootPart.CFrame
    local _, originalY, _ = originalCFrame:ToOrientation()

    -- สร้าง CFrame ใหม่ที่เก็บเฉพาะ Position และ Y rotation
    local function createUpright(position, yRotation)
        return CFrame.new(position) * CFrame.Angles(0, yRotation or originalY, 0)
    end

    local dist = (Vector3.new(humanoidRootPart.Position.X, 0, humanoidRootPart.Position.Z) - Vector3.new(P.Position.X, 0, P.Position.Z)).Magnitude

    if dist < 50 then
        local tween = tweenService:Create(
            humanoidRootPart,
            TweenInfo.new(dist / speed, Enum.EasingStyle.Linear),
            {CFrame = createUpright(P.Position)}
        )
        ActiveTween = tween
        tween:Play()
        tween.Completed:Connect(function()
            if tween.PlaybackState == Enum.PlaybackState.Completed then
                ActiveTween = nil
            end
        end)
        return tween
    end

    -- ขั้นตอนที่ 1: ลงใต้ดิน (ตำแหน่งเริ่มต้น)
    local startPosUnderground = createUpright(
        Vector3.new(humanoidRootPart.Position.X, undergroundDepth, humanoidRootPart.Position.Z)
    )
    
    -- ขั้นตอนที่ 2: เดินใต้ดินไปยังตำแหน่ง X,Z ของเป้าหมาย
    local targetPosUnderground = createUpright(
        Vector3.new(P.Position.X, undergroundDepth, P.Position.Z)
    )
    
    -- ขั้นตอนที่ 3: ขึ้นมาที่ตำแหน่งจริงของเป้าหมาย
    local finalPosition = createUpright(P.Position)
    
    local undergroundDistance = (targetPosUnderground.Position - startPosUnderground.Position).Magnitude

    -- Tween 1: ลงใต้ดิน
    local tweenDown = tweenService:Create(
        humanoidRootPart,
        TweenInfo.new(0.5, Enum.EasingStyle.Sine),
        {CFrame = startPosUnderground}
    )

    -- Tween 2: เดินใต้ดิน
    local tweenUnderground = tweenService:Create(
        humanoidRootPart,
        TweenInfo.new(undergroundDistance / speed, Enum.EasingStyle.Linear),
        {CFrame = targetPosUnderground}
    )

    -- Tween 3: ขึ้นมาบนพื้น
    local tweenUp = tweenService:Create(
        humanoidRootPart,
        TweenInfo.new(0.5, Enum.EasingStyle.Sine),
        {CFrame = finalPosition}
    )

    -- เริ่ม Tween ลงใต้ดิน
    ActiveTween = tweenDown
    tweenDown:Play()

    tweenDown.Completed:Connect(function()
        if tweenDown.PlaybackState == Enum.PlaybackState.Completed then
            -- เริ่ม Tween ใต้ดิน
            ActiveTween = tweenUnderground
            tweenUnderground:Play()
            
            task.spawn(function()
                while ActiveTween == tweenUnderground do
                    task.wait()

                    local dist = (Vector3.new(humanoidRootPart.Position.X, 0, humanoidRootPart.Position.Z) - Vector3.new(P.Position.X, 0, P.Position.Z)).Magnitude
                    if dist <= 30 then
                        tweenUnderground:Cancel()
                        -- ข้ามไปขึ้นบนเลย
                        ActiveTween = tweenUp
                        tweenUp:Play()
                        break
                    end
                    
                    if humanoidRootPart.Position.Y < undergroundDepth then
                        local currentPos = humanoidRootPart.Position
                        humanoidRootPart.CFrame = createUpright(
                            Vector3.new(currentPos.X, undergroundDepth, currentPos.Z)
                        )
                    end
                end
            end)
        end
    end)

    tweenUnderground.Completed:Connect(function()
        if tweenUnderground.PlaybackState == Enum.PlaybackState.Completed then
            -- เมื่อเดินใต้ดินเสร็จ ให้ขึ้นมาบนพื้น
            ActiveTween = tweenUp
            tweenUp:Play()
        end
    end)

    tweenUp.Completed:Connect(function()
        if tweenUp.PlaybackState == Enum.PlaybackState.Completed then
            ActiveTween = nil
        end
    end)

    -- Return tweenUp เพื่อให้สามารถ .Completed:Wait() ได้ที่ตำแหน่งจริง
    return tweenUp
end

function UpdateEnemies()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")

    for _, enemy in ipairs(workspace.Enemies:GetChildren()) do
        local hitbox = enemy:FindFirstChild("HumanoidRootPart")
        
        if hitbox then
            local billboard = nil
            for _, attachment in ipairs(hitbox:GetChildren()) do
                if attachment:IsA("Attachment") then
                    billboard = attachment:FindFirstChild("HealthNameBillboard")
                    if billboard then
                        break
                    end
                end
            end
            
            if billboard then
                local title = billboard.TextLabel
                local fullText = title.Text
                
                -- ถ้ามี ⭐ ให้ข้ามไปเลย ไม่ต้อง insert
                if fullText:find("⭐") then
                    continue
                end
                
                local name = fullText:match("^(.-)%s*<") or fullText
                
                if hitbox then
                    getgenv().EnemyZones[name] = hitbox.Position
                end

                if not addedNames[name] then
                    table.insert(Enemies, name)
                    addedNames[name] = true
                end
            end
        end
    end
end

function UpdatePlayers()
    local foundPlayers = {}
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not rootPart then return end

    for _, enemy in ipairs(game.Players:GetPlayers()) do
        if enemy ~= player then
            local enemyCharacter = enemy.Character
            if enemyCharacter then
                local enemyRootPart = enemyCharacter:FindFirstChild("HumanoidRootPart")
                
                if enemyRootPart then
                    local distance = (rootPart.Position - enemyRootPart.Position).Magnitude
                    
                    if distance <= 1000 then
                        local name = enemy.Name
                        
                        if not AddedPlayer[name] then
                            table.insert(PlayersTable, name)
                            AddedPlayer[name] = true
                        end
                        foundPlayers[name] = true
                    end
                end
            end
        end
    end

    for i = #PlayersTable, 1, -1 do
        local enemyName = PlayersTable[i]
        if not foundPlayers[enemyName] then
            table.remove(PlayersTable, i)
            AddedPlayer[enemyName] = nil
        end
    end
end

local function KillAura(toggle)
    if toggle then
        task.spawn(function()
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local CombatRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CombatRemote")
            local Player = game:GetService("Players").LocalPlayer
            local lastAttackTime = 0
            
            while getgenv().Settings.Automatic.FarmConfig.KillAura do task.wait(0.05)
                local character = Player.Character
                if not character then continue end
                if character:GetAttribute("Stun") == true then continue end
                if character:GetAttribute("UsingSkill") == true then continue end
                if character:GetAttribute("CombatEquipped") == false then continue end
                local HRP = character:FindFirstChild("HumanoidRootPart")
                if not HRP then continue end
                local currentTime = tick()
                if currentTime - lastAttackTime < 0.4 then continue end
                local closestEnemy = nil
                local closestDistance = 50
                for _, v in pairs(workspace.Enemies:GetChildren()) do
                    if v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                        local enemyHRP = v:FindFirstChild("HumanoidRootPart")
                        if enemyHRP then
                            local distance = (enemyHRP.Position - HRP.Position).Magnitude
                            if distance < closestDistance then
                                closestDistance = distance
                                closestEnemy = v
                            end
                        end
                    end
                end
                if closestEnemy then
                    lastAttackTime = currentTime
                    pcall(function()
                        CombatRemote:FireServer({Action = "PunchBegin", Combo = 1, Air = false})
                    end)
                    task.wait(0.05)
                    pcall(function()
                        CombatRemote:FireServer({Action = "m1", Target = closestEnemy, HumCF = HRP.CFrame, Combo = 1, Air = nil})
                    end)
                end
            end
        end)
    end
end

UpdatePlayers()
UpdateEnemies()

-- setup hitbox

local P, R = game:GetService("Players"), game:GetService("ReplicatedStorage")
local LP = P.LocalPlayer
local U = require(R.Scripts.Utilities.Utilities)
local old = U._OldSetupHitbox or U.SetupHitbox
U._OldSetupHitbox = old
local function GetTarget()
    local t, d = nil, 30 -- Limit 30m
    if not LP.Character then return end
    local pos = LP.Character.PrimaryPart.Position
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
            local dist = (v.HumanoidRootPart.Position - pos).Magnitude
            if dist < d then d = dist; t = v.HumanoidRootPart end
        end
    end
    return t
end
U.SetupHitbox = function(ig, cf, sz, dur, off, dat)
    local t = GetTarget()
    return old(ig, t and t.CFrame or cf, t and Vector3.new(30,30,30) or Vector3.new(60,60,60), dur, t and CFrame.new() or off, dat)
end

---- ============ Silent Mode Helpers ============ ----

local SilentModeCircle = nil

function CreateSilentCircle(radius)
    if SilentModeCircle then
        SilentModeCircle:Destroy()
        SilentModeCircle = nil
    end
    
    local circle = Instance.new("Part")
    circle.Name = "SilentModeRadius"
    circle.Anchored = true
    circle.CanCollide = false
    circle.Transparency = 1
    circle.Size = Vector3.new(radius * 2, 0.1, radius * 2)
    circle.CastShadow = false
    
    local surfaceGui = Instance.new("SurfaceGui")
    surfaceGui.Face = Enum.NormalId.Top
    surfaceGui.AlwaysOnTop = true
    surfaceGui.LightInfluence = 0
    surfaceGui.Parent = circle
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    
    local colorData = getgenv().Settings.Automatic.AutoFarm.SilentColor
    frame.BackgroundColor3 = Color3.fromRGB(colorData.r, colorData.g, colorData.b)
    frame.BackgroundTransparency = 0.9
    frame.BorderSizePixel = 0
    frame.Parent = surfaceGui
    
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(1, 0)
    uiCorner.Parent = frame
    
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = Color3.fromRGB(colorData.r, colorData.g, colorData.b)
    uiStroke.Thickness = 4
    uiStroke.Transparency = 0.2
    uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    uiStroke.Parent = frame
    
    circle.Parent = workspace
    SilentModeCircle = circle
    
    task.spawn(function()
        while SilentModeCircle and getgenv().Settings.Automatic.AutoFarm.SilentMode do
            task.wait()
            local character = game.Players.LocalPlayer.Character
            if character then
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    circle.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y - 2.5, hrp.Position.Z)
                end
            end
        end
    end)
    
    return circle
end

function RemoveSilentCircle()
    if SilentModeCircle then
        SilentModeCircle:Destroy()
        SilentModeCircle = nil
    end
end

---- ============ Automatic ============ ----

local Tab = Window:Tab({
    Title = "tr:Automaic",
    Icon = "code-xml",
    Opened = true,
})

local SilentModeTab = Tab:Section({ Title = "tr:SilentMode", Icon = "eye-off", Opened = true})

local SilentMode = SilentModeTab:Toggle({
    Title = "tr:SilentMode",
    Value = getgenv().Settings.Automatic.AutoFarm.SilentMode,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoFarm.SilentMode = Value
        SaveSetting()
        
        if Value then
            local radius = getgenv().Settings.Automatic.AutoFarm.SilentDistance
            CreateSilentCircle(radius)
            
            WindUI:Notify({
                Title = "Silent Mode | Enabled",
                Content = "Detection radius: " .. radius .. " studs",
                Icon = VenuzIcon,
                Duration = 3,
            })
        else
            RemoveSilentCircle()
            SilentVisuals.Hide()
            
            WindUI:Notify({
                Title = "Silent Mode | Disabled",
                Content = "Detection radius hidden",
                Icon = VenuzIcon,
                Duration = 3,
            })
        end
    end
})

local SilentDistance = SilentModeTab:Slider({
    Title = "tr:SilentDistance",
    Value = {
        Min = 1,
        Max = 200,
        Default = getgenv().Settings.Automatic.AutoFarm.SilentDistance
    },
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoFarm.SilentDistance = Value
        SaveSetting()
        
        if getgenv().Settings.Automatic.AutoFarm.SilentMode then
            CreateSilentCircle(Value)
        end
    end
})

local SilentColorPicker = SilentModeTab:Colorpicker({
    Title = "tr:SilentCircleColor",
    Default = Color3.fromRGB(
        getgenv().Settings.Automatic.AutoFarm.SilentColor.r,
        getgenv().Settings.Automatic.AutoFarm.SilentColor.g,
        getgenv().Settings.Automatic.AutoFarm.SilentColor.b
    ),
    Transparency = 0,
    Locked = false,
    Callback = function(color) 
        getgenv().Settings.Automatic.AutoFarm.SilentColor = {
            r = math.floor(color.R * 255),
            g = math.floor(color.G * 255),
            b = math.floor(color.B * 255)
        }
        SaveSetting()
        
        if getgenv().Settings.Automatic.AutoFarm.SilentMode then
            if SilentModeCircle then
                local surfaceGui = SilentModeCircle:FindFirstChild("SurfaceGui")
                if surfaceGui then
                    local frame = surfaceGui:FindFirstChild("Frame")
                    if frame then
                        frame.BackgroundColor3 = color
                        local uiStroke = frame:FindFirstChildOfClass("UIStroke")
                        if uiStroke then
                            uiStroke.Color = color
                        end
                    end
                end
            end
            
            -- Update Visuals if active
            if SilentVisuals.CurrentHighlight then
                SilentVisuals.CurrentHighlight.FillColor = color
            end
            -- Beam color is always red, do not update
        end
    end
})

---- ============ Farm Config ============ ----

local FarmConfigTab = Tab:Section({ Title = "tr:FarmConfigTab", Icon = "settings", Opened = true})

FarmConfigTab:Slider({
    Title = "tr:TweenSpeed",
    Value = {
        Min = 50,
        Max = 1000,
        Default = getgenv().Settings.Automatic.FarmConfig.TweenSpeed
    },
    Callback = function(Value)
        getgenv().Settings.Automatic.FarmConfig.TweenSpeed = Value
        SaveSetting()
    end
})

FarmConfigTab:Slider({
    Title = "tr:Distance",
    Value = {
        Min = 1,
        Max = 50,
        Default = getgenv().Settings.Automatic.FarmConfig.Distance
    },
    Callback = function(Value)
        getgenv().Settings.Automatic.FarmConfig.Distance = Value
        SaveSetting()
    end
})

KillAuraToggle = FarmConfigTab:Toggle({
    Title = "tr:KillAura",
    Value = getgenv().Settings.Automatic.FarmConfig.KillAura,
    Icon = "check",
    Callback = function(Mon)
        getgenv().Settings.Automatic.FarmConfig.KillAura = Mon
        SaveSetting()
        KillAura(Mon)
    end
})

local AutoFarmEnemiesToggle
local AutoFarmBossToggle

---- ============ Auto Farm Enemies ============ ----

local AutoFarmEnemiesTab = Tab:Section({ Title = "tr:AutoFarmEnemiesTab", Icon = "skull", Opened = true})

do
    local savedEnemies = getgenv().Settings.Automatic.AutoFarm.SelectEnemy or {}
    local cleanedSaved = {}
    for _, name in ipairs(savedEnemies) do
        local cleanName = CleanEnemyName(name)
        if cleanName ~= "" and table.find(Enemies, cleanName) and not table.find(cleanedSaved, cleanName) then
            table.insert(cleanedSaved, cleanName)
        end
    end
    getgenv().Settings.Automatic.AutoFarm.SelectEnemy = cleanedSaved
    SelectEnemiesTable = cleanedSaved
end

local SelectEnemies = AutoFarmEnemiesTab:Dropdown({
    Title = "tr:SelectEnemies",
    Multi = true,
    AllowNone = true,
    Values = Enemies,
    Value = getgenv().Settings.Automatic.AutoFarm.SelectEnemy,
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoFarm.SelectEnemy = Value
        SelectEnemiesTable = Value
        SaveSetting()
    end
})

AutoFarmEnemiesTab:Dropdown({
    Title = "tr:MethodEnemies",
    Multi = false,
    AllowNone = false,
    Values = {"Over","Below","Behind"},
    Value = getgenv().Settings.Automatic.AutoFarm.MethodEnemies,
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoFarm.MethodEnemies = Value
        SaveSetting()
    end
})

AutoFarmEnemiesToggle = AutoFarmEnemiesTab:Toggle({
    Title = "tr:AutoFarm",
    Value = getgenv().Settings.Automatic.AutoFarm.AutoFarmEnemie,
    Icon = "check",
    Callback = function(Mon)
        getgenv().Settings.Automatic.AutoFarm.AutoFarmEnemie = Mon
        SaveSetting()

        if Mon then
            StartNoClip()
            AutoFarmBossToggle:Lock()
            task.spawn(function()
                while getgenv().Settings.Automatic.AutoFarm.AutoFarmEnemie do
                    if not getgenv().Settings.Automatic.AutoFarm.AutoFarmEnemie then hrp.Anchored = false break end
                    task.wait()

                    if getgenv().IsDoingWorldEvent then
                        hrp.Anchored = false
                        if ActiveTween then
                            ActiveTween:Cancel()
                            ActiveTween = nil
                        end
                        continue
                    end

                    local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not rootPart then continue end

                    local nearestEnemy = nil
                    local nearestDistance = 1000
                    local enemiesClient = workspace.Enemies
                    local AvoidingEnemies = getgenv().AvoidingEnemies or {}
                    getgenv().AvoidingEnemies = AvoidingEnemies

                    if not SelectEnemiesTable or #SelectEnemiesTable == 0 then
                        continue
                    end

                    for _, enemy in ipairs(enemiesClient:GetChildren()) do
                        local hitbox = enemy:FindFirstChild("HumanoidRootPart")
                        
                        if hitbox then
                            local billboard = nil
                            for _, attachment in ipairs(hitbox:GetChildren()) do
                                if attachment:IsA("Attachment") then
                                    billboard = attachment:FindFirstChild("HealthNameBillboard")
                                    if billboard then
                                        break
                                    end
                                end
                            end
                            
                            if billboard then
                                local title = billboard.TextLabel
                                local fullText = title.Text
                                local enemyName = CleanEnemyName(fullText)
                                
                                
                                if AvoidingEnemies[enemy] and os.time() < AvoidingEnemies[enemy] then
                                    continue
                                end
                            
                                if IsInAvoidedZone(hitbox.Position) then
                                    continue
                                end

                                if enemyName ~= "" and not getgenv().EnemyZones[enemyName] then
                                    getgenv().EnemyZones[enemyName] = hitbox.Position
                                end
                                
                                for _, selectedName in ipairs(SelectEnemiesTable) do
                                    if enemyName:lower():find(selectedName:lower(), 1, true) then
                                        local distance = (hitbox.Position - rootPart.Position).Magnitude
                                        
                                        if distance < nearestDistance then
                                            nearestEnemy = enemy
                                            nearestDistance = distance
                                        end
                                        break
                                    end
                                end
                            end
                        end
                    end

                    if not nearestEnemy then
                        hrp.Anchored = false
                        if not getgenv().SearchFailCount then getgenv().SearchFailCount = 0 end
                        getgenv().SearchFailCount = getgenv().SearchFailCount + 1
                        
                        if getgenv().SearchFailCount > 50 then
                            if not getgenv().SearchCheckIndex then getgenv().SearchCheckIndex = 1 end
                            local SearchSequence = {}
                            for _, enemyName in ipairs(SelectEnemiesTable or {}) do
                                local zonePos = getgenv().EnemyZones[enemyName]
                                if zonePos and not IsInAvoidedZone(zonePos) then
                                    table.insert(SearchSequence, CFrame.new(zonePos + Vector3.new(0, -50, 0)))
                                end
                            end
    
                            if #SearchSequence > 0 then
                                if getgenv().SearchCheckIndex > #SearchSequence then
                                    getgenv().SearchCheckIndex = 1
                                end
                                hrp.CFrame = SearchSequence[getgenv().SearchCheckIndex]
                                getgenv().SearchCheckIndex = getgenv().SearchCheckIndex + 1
                                getgenv().SearchFailCount = 0
                                task.wait(2.5)
                            end
                        end
                    else
                        getgenv().SearchFailCount = 0
                    end

                    if nearestEnemy and nearestEnemy:FindFirstChild("HumanoidRootPart") then
                        hrp.Anchored = false
                        local hitbox = nearestEnemy.HumanoidRootPart
                        
                        if (hitbox.Position - hrp.Position).Magnitude > 1000 then
                            hrp.CFrame = hitbox.CFrame * CFrame.new(0, -30, 0)
                            task.wait(0.1)
                        end

                        local shouldEscape = false
                        
                        repeat
                            task.wait()
                            
                            if getgenv().IsDoingWorldEvent then
                                hrp.Anchored = false
                                if ActiveTween then
                                    ActiveTween:Cancel()
                                    ActiveTween = nil
                                end
                                break
                            end
                            
                            if getgenv().Settings.Automatic.AutoFarm.SilentMode then
                                local silentDistance = tonumber(getgenv().Settings.Automatic.AutoFarm.SilentDistance)
                                for _, player in pairs(game.Players:GetPlayers()) do
                                    if player ~= game.Players.LocalPlayer and player.Character then
                                        local success, pivot = pcall(function()
                                            return player.Character:GetPivot()
                                        end)
                                        
                                        if success and pivot then
                                            local playerPos = pivot.Position
                                            local distanceToEnemy = (playerPos - hitbox.Position).Magnitude
                                            
                                            if distanceToEnemy <= silentDistance then
                                                shouldEscape = true
                                                SilentVisuals.Show(player)
                                                
                                                local zoneKey = Vector3.new(
                                                    math.floor(hitbox.Position.X / 10) * 10,
                                                    math.floor(hitbox.Position.Y / 10) * 10,
                                                    math.floor(hitbox.Position.Z / 10) * 10
                                                )
                                                getgenv().AvoidedZones[zoneKey] = os.time() + 10
                                                     
                                                if nearestEnemy then
                                                    AvoidingEnemies[nearestEnemy] = os.time() + 10
                                                end
                                                
                                                break
                                            end
                                        end
                                    end
                                end
                                
                                if not shouldEscape then
                                    SilentVisuals.Hide()
                                end
                                
                                if shouldEscape then
                                    if ActiveTween then
                                        ActiveTween:Cancel()
                                        ActiveTween = nil
                                    end
                                    hrp.CFrame = CFrame.new(hrp.Position.X, -70, hrp.Position.Z)
                                    task.wait(5)
                                    break
                                end
                            end
                            
                            if not chr:GetAttribute("CombatEquipped") then
                                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CombatRemote"):FireServer({Action = "EquipCombat"})
                            end

                            if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Right Arm") and not game.Players.LocalPlayer.Character["Right Arm"]:FindFirstChild("ArmCoating") then
                                game:GetService("ReplicatedStorage").Remotes.TranciverRemote:FireServer("Begin","CECoating")
                                task.wait(1)
                            end
                            
                            rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if not rootPart or not nearestEnemy.Parent then break end
                            
                            local method = getgenv().Settings.Automatic.AutoFarm.MethodEnemies
                            local distance = getgenv().Settings.Automatic.FarmConfig.Distance
                            local tweenSpeed = getgenv().Settings.Automatic.FarmConfig.TweenSpeed
                            local targetCFrame = hitbox.CFrame
                            
                            if method == "Over" then
                                targetCFrame = targetCFrame * CFrame.new(0, distance, 0)
                            elseif method == "Below" then
                                targetCFrame = targetCFrame * CFrame.new(0, -distance, 0)
                            elseif method == "Behind" then
                                targetCFrame = targetCFrame * CFrame.new(0, 0, distance)
                            end
                            
                            local tw = TweenFarm(targetCFrame, tweenSpeed)
                            while tw.PlaybackState ~= Enum.PlaybackState.Completed and tw.PlaybackState ~= Enum.PlaybackState.Cancelled and nearestEnemy.Parent and #workspace.Enemies:GetChildren() > 0 and getgenv().Settings.Automatic.AutoFarm.AutoFarmEnemie do
                                task.wait()
                            end
                            if not (nearestEnemy.Parent and #workspace.Enemies:GetChildren() > 0 and getgenv().Settings.Automatic.AutoFarm.AutoFarmEnemie) then
                                if ActiveTween then ActiveTween:Cancel() ActiveTween = nil end
                            end
                            
                        until not nearestEnemy.Parent or not getgenv().Settings.Automatic.AutoFarm.AutoFarmEnemie or shouldEscape
                    else
                        if getgenv().Settings.Automatic.AutoFarm.AutoFarmEnemie then
                            hrp.Anchored = true
                        else
                            hrp.Anchored = false
                        end
                    end
                end
            end)
        else
            AutoFarmBossToggle:Unlock()
            hrp.Anchored = false
            StopNoClip()
            if ActiveTween then
                ActiveTween:Cancel()
                ActiveTween = nil
            end
        end
    end
})

---- ============ Auto Boss ============ ----

local AutoFarmBossTab = Tab:Section({ Title = "tr:AutoFarmBossTab", Icon = "crown", Opened = true})

do
    local savedBoss = getgenv().Settings.Automatic.AutoBoss.SelectBoss or {}
    local cleanedSavedBoss = {}
    for _, name in ipairs(savedBoss) do
        local cleanName = CleanEnemyName(name)
        if cleanName ~= "" and table.find(Bosses, cleanName) and not table.find(cleanedSavedBoss, cleanName) then
            table.insert(cleanedSavedBoss, cleanName)
        end
    end
    getgenv().Settings.Automatic.AutoBoss.SelectBoss = cleanedSavedBoss
    SelectBossTable = cleanedSavedBoss
end

local SelectBoss = AutoFarmBossTab:Dropdown({
    Title = "tr:SelectBoss",
    Multi = true,
    AllowNone = true,
    Values = Bosses,
    Value = getgenv().Settings.Automatic.AutoBoss.SelectBoss,
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoBoss.SelectBoss = Value
        SelectBossTable = Value
        SaveSetting()
    end
})

AutoFarmBossTab:Dropdown({
    Title = "tr:MethodBoss",
    Multi = false,
    AllowNone = false,
    Values = {"Over","Below","Behind"},
    Value = getgenv().Settings.Automatic.AutoBoss.MethodBoss,
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoBoss.MethodBoss = Value
        SaveSetting()
    end
})

AutoFarmBossToggle = AutoFarmBossTab:Toggle({
    Title = "tr:AutoFarmBoss",
    Value = getgenv().Settings.Automatic.AutoBoss.AutoFarmBoss,
    Icon = "check",
    Callback = function(Mon)
        getgenv().Settings.Automatic.AutoBoss.AutoFarmBoss = Mon
        SaveSetting()

        if Mon then
            StartNoClip()
            AutoFarmEnemiesToggle:Lock()
            task.spawn(function()
                while getgenv().Settings.Automatic.AutoBoss.AutoFarmBoss do
                    if not getgenv().Settings.Automatic.AutoBoss.AutoFarmBoss then hrp.Anchored = false break end
                    task.wait()

                    if getgenv().IsDoingWorldEvent then
                        hrp.Anchored = false
                        if ActiveTween then
                            ActiveTween:Cancel()
                            ActiveTween = nil
                        end
                        continue
                    end

                    local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if not rootPart then continue end

                    local nearestBoss = nil
                    local nearestDistance = 1000
                    local enemiesClient = workspace.Enemies
                    local AvoidingEnemies = getgenv().AvoidingEnemies or {}
                    getgenv().AvoidingEnemies = AvoidingEnemies

                    if not SelectBossTable or #SelectBossTable == 0 then
                        continue
                    end

                    for _, enemy in ipairs(enemiesClient:GetChildren()) do
                        local hitbox = enemy:FindFirstChild("HumanoidRootPart")
                        
                        if hitbox then
                            local billboard = nil
                            for _, attachment in ipairs(hitbox:GetChildren()) do
                                if attachment:IsA("Attachment") then
                                    billboard = attachment:FindFirstChild("HealthNameBillboard")
                                    if billboard then
                                        break
                                    end
                                end
                            end
                            
                            if billboard then
                                local title = billboard.TextLabel
                                local fullText = title.Text
                                local enemyName = CleanEnemyName(fullText)
                                
                                if AvoidingEnemies[enemy] and os.time() < AvoidingEnemies[enemy] then
                                    continue
                                end
                            
                                if IsInAvoidedZone(hitbox.Position) then
                                    continue
                                end

                                if enemyName ~= "" and getgenv().BossZones and not getgenv().BossZones[enemyName] then
                                    getgenv().BossZones[enemyName] = hitbox.Position
                                end
                                
                                for _, selectedName in ipairs(SelectBossTable) do
                                    if enemyName:lower():find(selectedName:lower(), 1, true) then
                                        local distance = (hitbox.Position - rootPart.Position).Magnitude
                                        
                                        if distance < nearestDistance then
                                            nearestBoss = enemy
                                            nearestDistance = distance
                                        end
                                        break
                                    end
                                end
                            end
                        end
                    end

                    if not nearestBoss then
                        hrp.Anchored = false
                        if not getgenv().BossSearchFailCount then getgenv().BossSearchFailCount = 0 end
                        getgenv().BossSearchFailCount = getgenv().BossSearchFailCount + 1
                        
                        if getgenv().BossSearchFailCount > 50 then
                            if not getgenv().BossSearchCheckIndex then getgenv().BossSearchCheckIndex = 1 end
                            local SearchSequence = {}
                            for _, bossName in ipairs(SelectBossTable or {}) do
                                -- ดึง CFrame จาก BossSpawnPoints (หลายจุด)
                                if getgenv().BossSpawnPoints and getgenv().BossSpawnPoints[bossName] then
                                    for _, spawnCF in ipairs(getgenv().BossSpawnPoints[bossName]) do
                                        if not IsInAvoidedZone(spawnCF.Position) then
                                            table.insert(SearchSequence, CFrame.new(spawnCF.Position + Vector3.new(0, -50, 0)))
                                        end
                                    end
                                elseif getgenv().BossZones and getgenv().BossZones[bossName] then
                                    local zonePos = getgenv().BossZones[bossName]
                                    if not IsInAvoidedZone(zonePos) then
                                        table.insert(SearchSequence, CFrame.new(zonePos + Vector3.new(0, -50, 0)))
                                    end
                                end
                            end
    
                            if #SearchSequence > 0 then
                                if getgenv().BossSearchCheckIndex > #SearchSequence then
                                    if getgenv().Settings.Automatic.AutoBoss.HopIfNoBoss then
                                        ServerHop()
                                    end
                                    getgenv().BossSearchCheckIndex = 1
                                end
                                hrp.CFrame = SearchSequence[getgenv().BossSearchCheckIndex]
                                getgenv().BossSearchCheckIndex = getgenv().BossSearchCheckIndex + 1
                                getgenv().BossSearchFailCount = 0
                                task.wait(3.5)
                            end
                        end
                    else
                        getgenv().BossSearchFailCount = 0
                    end

                    if nearestBoss and nearestBoss:FindFirstChild("HumanoidRootPart") then
                        hrp.Anchored = false
                        local hitbox = nearestBoss.HumanoidRootPart
                        
                        if (hitbox.Position - hrp.Position).Magnitude > 1000 then
                            hrp.CFrame = hitbox.CFrame * CFrame.new(0, -30, 0)
                            task.wait(0.1)
                        end

                        local shouldEscape = false
                        
                        repeat
                            task.wait()
                            
                            if getgenv().IsDoingWorldEvent then
                                hrp.Anchored = false
                                if ActiveTween then
                                    ActiveTween:Cancel()
                                    ActiveTween = nil
                                end
                                break
                            end
                            
                            if getgenv().Settings.Automatic.AutoFarm.SilentMode then
                                local silentDistance = tonumber(getgenv().Settings.Automatic.AutoFarm.SilentDistance)
                                for _, player in pairs(game.Players:GetPlayers()) do
                                    if player ~= game.Players.LocalPlayer and player.Character then
                                        local success, pivot = pcall(function()
                                            return player.Character:GetPivot()
                                        end)
                                        
                                        if success and pivot then
                                            local playerPos = pivot.Position
                                            local distanceToEnemy = (playerPos - hitbox.Position).Magnitude
                                            
                                            if distanceToEnemy <= silentDistance then
                                                shouldEscape = true
                                                SilentVisuals.Show(player)
                                                
                                                local zoneKey = Vector3.new(
                                                    math.floor(hitbox.Position.X / 10) * 10,
                                                    math.floor(hitbox.Position.Y / 10) * 10,
                                                    math.floor(hitbox.Position.Z / 10) * 10
                                                )
                                                getgenv().AvoidedZones[zoneKey] = os.time() + 10
                                                
                                                if nearestBoss then
                                                    AvoidingEnemies[nearestBoss] = os.time() + 10
                                                end
                                                
                                                break
                                            end
                                        end
                                    end
                                end
                                
                                if not shouldEscape then
                                    SilentVisuals.Hide()
                                end

                                if shouldEscape then
                                    if ActiveTween then
                                        ActiveTween:Cancel()
                                        ActiveTween = nil
                                    end
                                    hrp.CFrame = CFrame.new(hrp.Position.X, -70, hrp.Position.Z)
                                    task.wait(5)
                                    break
                                end
                            end
                            
                            if not chr:GetAttribute("CombatEquipped") then
                                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CombatRemote"):FireServer({Action = "EquipCombat"})
                            end

                            if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Right Arm") and not game.Players.LocalPlayer.Character["Right Arm"]:FindFirstChild("ArmCoating") then
                                game:GetService("ReplicatedStorage").Remotes.TranciverRemote:FireServer("Begin","CECoating")
                                task.wait(1)
                            end
                            
                            rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if not rootPart or not nearestBoss.Parent then break end
                            
                            local method = getgenv().Settings.Automatic.AutoBoss.MethodBoss
                            local distance = getgenv().Settings.Automatic.FarmConfig.Distance
                            local tweenSpeed = getgenv().Settings.Automatic.FarmConfig.TweenSpeed
                            local targetCFrame = hitbox.CFrame
                            
                            if method == "Over" then
                                targetCFrame = targetCFrame * CFrame.new(0, distance, 0)
                            elseif method == "Below" then
                                targetCFrame = targetCFrame * CFrame.new(0, -distance, 0)
                            elseif method == "Behind" then
                                targetCFrame = targetCFrame * CFrame.new(0, 0, distance)
                            end
                            
                            local tw = TweenFarm(targetCFrame, tweenSpeed)
                            while tw.PlaybackState ~= Enum.PlaybackState.Completed and tw.PlaybackState ~= Enum.PlaybackState.Cancelled and nearestBoss.Parent and #workspace.Enemies:GetChildren() > 0 and getgenv().Settings.Automatic.AutoBoss.AutoFarmBoss do
                                task.wait()
                            end
                            if not (nearestBoss.Parent and #workspace.Enemies:GetChildren() > 0 and getgenv().Settings.Automatic.AutoBoss.AutoFarmBoss) then
                                if ActiveTween then ActiveTween:Cancel() ActiveTween = nil end
                            end
                            
                        until not nearestBoss.Parent or not getgenv().Settings.Automatic.AutoBoss.AutoFarmBoss or shouldEscape
                    else
                        if getgenv().Settings.Automatic.AutoBoss.AutoFarmBoss then
                            hrp.Anchored = true
                        else
                            hrp.Anchored = false
                        end
                    end
                end
            end)
        else
            AutoFarmEnemiesToggle:Unlock()
            hrp.Anchored = false
            StopNoClip()
            if ActiveTween then
                ActiveTween:Cancel()
                ActiveTween = nil
            end
        end
    end
})

AutoFarmBossTab:Toggle({
    Title = "tr:HopIfNoBoss",
    Desc = "tr:HopIfNoBossDesc",
    Value = getgenv().Settings.Automatic.AutoBoss.HopIfNoBoss,
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoBoss.HopIfNoBoss = Value
        SaveSetting()
    end
})

local AutoWorldEventsTab = Tab:Section({ Title = "tr:AutoWorldEventsTab", Icon = "globe", Opened = true})

AutoWorldEventsTab:Toggle({
    Title = "tr:AutoWorldEvents",
    Value = getgenv().Settings.Automatic.AutoWorldEvents,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoWorldEvents = Value
        SaveSetting()

        if Value then
            task.spawn(function()
                while getgenv().Settings.Automatic.AutoWorldEvents do
                    task.wait()
                    if not getgenv().Settings.Automatic.AutoWorldEvents then break end

                    local character = LocalPlayer.Character
                    local humanoid = character and character:FindFirstChild("Humanoid")
                    if not character or not humanoid or humanoid.Health <= 0 then
                        repeat
                            task.wait(0.5)
                            character = LocalPlayer.Character
                            humanoid = character and character:FindFirstChild("Humanoid")
                        until character and humanoid and humanoid.Health > 0
                        task.wait(1)
                        continue
                    end

                    local currentHRP = character:FindFirstChild("HumanoidRootPart")
                    if not currentHRP then continue end

                    local EventPart = nil

                    if workspace:FindFirstChild("WorldEvents") and workspace.WorldEvents:FindFirstChild("Normal") then
                        for _, child in ipairs(workspace.WorldEvents.Normal:GetChildren()) do
                            if child:IsA("BasePart") and child:FindFirstChild("DamageFolder") then
                                EventPart = child
                                break
                            end
                        end
                    end

                    if EventPart then
                        getgenv().IsDoingWorldEvent = true

                        local dist = (currentHRP.Position - EventPart.Position).Magnitude
                        if dist > 300 then
                            if ActiveTween then
                                ActiveTween:Cancel()
                                ActiveTween = nil
                            end
                            currentHRP.CFrame = EventPart.CFrame * CFrame.new(0, 50, 0)
                        end

                        repeat
                            task.wait()

                            if not EventPart.Parent or not EventPart:FindFirstChild("DamageFolder") then
                                break
                            end

                            character = LocalPlayer.Character
                            humanoid = character and character:FindFirstChild("Humanoid")
                            if not character or not humanoid or humanoid.Health <= 0 then
                                repeat
                                    task.wait(0.5)
                                    character = LocalPlayer.Character
                                    humanoid = character and character:FindFirstChild("Humanoid")
                                until character and humanoid and humanoid.Health > 0
                                task.wait(1)
                                currentHRP = character:FindFirstChild("HumanoidRootPart")
                                hrp = currentHRP
                                if currentHRP and EventPart and EventPart.Parent then
                                    currentHRP.CFrame = EventPart.CFrame * CFrame.new(0, 50, 0)
                                end
                                continue
                            end

                            currentHRP = character:FindFirstChild("HumanoidRootPart")
                            hrp = currentHRP
                            if not currentHRP then continue end

                            local nearestEnemy = nil
                            local nearestDist = 300

                            for _, enemy in ipairs(workspace.Enemies:GetChildren()) do
                                if enemy:FindFirstChild("HumanoidRootPart") then
                                    local distEvent = (enemy.HumanoidRootPart.Position - EventPart.Position).Magnitude
                                    if distEvent < 250 then
                                        local distPlayer = (enemy.HumanoidRootPart.Position - currentHRP.Position).Magnitude
                                        if distPlayer < nearestDist then
                                            nearestDist = distPlayer
                                            nearestEnemy = enemy
                                        end
                                    end
                                end
                            end

                            if nearestEnemy then
                                local hitbox = nearestEnemy.HumanoidRootPart
                                local method = getgenv().Settings.Automatic.AutoFarm.MethodEnemies
                                local distance = getgenv().Settings.Automatic.FarmConfig.Distance
                                local targetCFrame = hitbox.CFrame

                                local extraHeight = 0
                                if nearestEnemy.Name == "DogCurse" then
                                    extraHeight = 15
                                end

                                if method == "Over" then
                                    targetCFrame = targetCFrame * CFrame.new(0, distance + extraHeight, 0)
                                elseif method == "Below" then
                                    targetCFrame = targetCFrame * CFrame.new(0, -distance + extraHeight, 0)
                                elseif method == "Behind" then
                                    targetCFrame = targetCFrame * CFrame.new(0, extraHeight, distance)
                                end

                                currentHRP.CFrame = targetCFrame

                                if not character:GetAttribute("CombatEquipped") then
                                    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CombatRemote"):FireServer({Action = "EquipCombat"})
                                end

                                if character:FindFirstChild("Right Arm") and not character["Right Arm"]:FindFirstChild("ArmCoating") then
                                    game:GetService("ReplicatedStorage").Remotes.TranciverRemote:FireServer("Begin", "CECoating")
                                end
                            else
                                currentHRP.CFrame = EventPart.CFrame * CFrame.new(0, 50, 0)
                            end

                        until not EventPart.Parent or not EventPart:FindFirstChild("DamageFolder") or not getgenv().Settings.Automatic.AutoWorldEvents

                        getgenv().IsDoingWorldEvent = false
                    else
                        getgenv().IsDoingWorldEvent = false
                        task.wait(1)
                    end
                end
                getgenv().IsDoingWorldEvent = false
            end)
        else
            getgenv().IsDoingWorldEvent = false
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.Anchored = false
            end
        end
    end
})

local AutoStatsTab = Tab:Section({ Title = "tr:AutoStatsTab", Icon = "power", Opened = true})

AutoStatsTab:Dropdown({
    Title = "tr:Stats",
    Values = {"Strength", "Cursed Enerdy Amount", "Cursed Enerdy Output", "Defense", "Agility"},
    Value = (function()
        local savedStats = getgenv().Settings.Automatic.AutoStats.Stats
        local displayStats = {}
        for _, stat in ipairs(savedStats) do
            if stat == "Mind" then
                table.insert(displayStats, "Cursed Enerdy Amount")
            elseif stat == "Intelligence" then
                table.insert(displayStats, "Cursed Enerdy Output")
            else
                table.insert(displayStats, stat)
            end
        end
        return displayStats
    end)(),
    AllowNone = true,
    Multi = true,
    Callback = function(Value)
        local convertedStats = {}
        for _, stat in ipairs(Value) do
            if stat == "Cursed Enerdy Amount" then
                table.insert(convertedStats, "Mind")
            elseif stat == "Cursed Enerdy Output" then
                table.insert(convertedStats, "Intelligence")
            else
                table.insert(convertedStats, stat)
            end
        end
        getgenv().Settings.Automatic.AutoStats.Stats = convertedStats
        SaveSetting()
    end
})

AutoStatsTab:Slider({
    Title = "tr:Amount",
    Value = {
        Min = 1,
        Max = 100,
        Default = getgenv().Settings.Automatic.AutoStats.Amount
    },
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoStats.Amount = Value
        SaveSetting()
    end
})

AutoStatsTab:Toggle({
    Title = "tr:AutoStats",
    Value = getgenv().Settings.Automatic.AutoStats.AutoStats,
    Icon = "check",
    Callback = function(Mon)
        getgenv().Settings.Automatic.AutoStats.AutoStats = Mon
        SaveSetting()

        if Mon then
            task.spawn(function()
                while getgenv().Settings.Automatic.AutoStats.AutoStats do task.wait()
                    local selectedStats = getgenv().Settings.Automatic.AutoStats.Stats
                    local amount = getgenv().Settings.Automatic.AutoStats.Amount
                    
                    if selectedStats and #selectedStats > 0 then
                        for _, stat in ipairs(selectedStats) do
                            pcall(function()
                                game:GetService("ReplicatedStorage").Remotes.Stats:FireServer("AddPoints", amount, stat)
                            end)
                        end
                    end
                end
            end)
        end
    end
})

local AutoBoxOfLuckTab = Tab:Section({ Title = "tr:BoxOfLuck", Icon = "box", Opened = true})

AutoBoxOfLuckTab:Dropdown({
    Title = "tr:SelectBoxOfLuck",
    Multi = true,
    AllowNone = true,
    Values = {"Box of Luck I", "Box of Luck II", "Box of Luck III", "Box of Luck IV", "Box of Luck V"},
    Value = getgenv().Settings.Automatic.AutoFarm.SelectBoxOfLuck,
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoFarm.SelectBoxOfLuck = Value
        SaveSetting()
    end
})

AutoBoxOfLuckTab:Toggle({
    Title = "tr:AutoBoxOfLuck",
    Value = getgenv().Settings.Automatic.AutoFarm.AutoBoxOfLuck,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoFarm.AutoBoxOfLuck = Value
        SaveSetting()

        if Value then
            task.spawn(function()
                while getgenv().Settings.Automatic.AutoFarm.AutoBoxOfLuck do task.wait(0.2)
                    local selectedBoxes = getgenv().Settings.Automatic.AutoFarm.SelectBoxOfLuck
                    if selectedBoxes and #selectedBoxes > 0 then
                        for _, boxName in ipairs(selectedBoxes) do
                            local itemUuid = CheckItem(boxName, "name")
                            if itemUuid then
                                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Inventory"):FireServer(unpack({"UsableItem", itemUuid}))
                            end
                        end
                    end
                end
            end)
        end
    end
})

task.spawn(function()
    pcall(function()
        workspace.Enemies.ChildAdded:Connect(function(child)
            task.wait(0.1)
            local hitbox = child:WaitForChild("HumanoidRootPart", 5)
            if hitbox then
                local billboard = nil
                for _, attachment in ipairs(hitbox:GetChildren()) do
                    if attachment:IsA("Attachment") then
                        billboard = attachment:FindFirstChild("HealthNameBillboard")
                        if billboard then
                            break
                        end
                    end
                end
                
                if billboard then
                    local title = billboard.TextLabel
                    local fullText = title.Text
                    
                    local name = fullText:match("^(.-)%s*<") or fullText
                    name = name:gsub("⭐", ""):gsub("%s+$", ""):gsub("^%s+", "")
                    
                    if addedNames[name] then
                        return
                    end
                    
                    if hitbox then
                        getgenv().EnemyZones[name] = hitbox.Position
                    end

                    table.insert(Enemies, name)
                    addedNames[name] = true
                    
                    if SelectEnemies then
                        SelectEnemies:Refresh(Enemies)
                    end
                end
            end
        end)
    end)
end)

---- ============ Players ============ ----

local Tab = Window:Tab({
    Title = "tr:Players",
    Icon = "person-standing",
    Opened = true,
})

local Playerss = Tab:Section({ Title = "tr:Players", Icon = "person-standing", Opened = true})

local SelectPlayer = Playerss:Dropdown({
    Title = "tr:SelectPlayer",
    Desc = "tr:descriptsp",
    Multi = false,
    AllowNone = true,
    Values = PlayersTable,
    Value = nil,
    Callback = function(Value)
        SelectPlayer_true = Value
    end
})

Playerss:Toggle({
    Title = "tr:SpectatorPlayer",
    Value = false,
    Icon = "check",
    Callback = function(Value)
        pcall(function()
            if Value and SelectPlayer_true and game.Players:FindFirstChild(SelectPlayer_true) then
                local selectedPlayer = game.Players[SelectPlayer_true]
                local camera = workspace.CurrentCamera
                if selectedPlayer.Character and
                    selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    camera.CameraSubject = selectedPlayer.Character.Humanoid
                    camera.CameraType = Enum.CameraType.Follow
                end
            else
                local camera = workspace.CurrentCamera
                camera.CameraSubject = game.Players.LocalPlayer.Character.Humanoid
                camera.CameraType = Enum.CameraType.Custom
            end
        end)
    end
})

Playerss:Button({
    Title = "tr:Teleport",
    Callback = function(Value)
        hrp.CFrame = game.Players[SelectPlayer_true].Character.HumanoidRootPart.CFrame
    end
})

local Modify = Tab:Section({ Title = "tr:Players", Icon = "cog", Opened = true})

Modify:Slider({
    Title = "tr:WalkSpeed",
    Value = {
        Min = 16,
        Max = 200,
        Default = getgenv().Settings.Player.Modify.WalkSpeed
    },
    Callback = function(Value)
        getgenv().Settings.Player.Modify.WalkSpeed = Value
        SaveSetting()
    end
})

Modify:Toggle({
    Title = "tr:Enabled",
    Value = getgenv().Settings.Player.Modify.WalkSpeedE,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Player.Modify.WalkSpeedE = Value
        SaveSetting()
        
        if Value then
            task.spawn(function()
                while getgenv().Settings.Player.Modify.WalkSpeedE do task.wait()
                    if not getgenv().Settings.Player.Modify.WalkSpeedE then break end
                    pcall(function()
                        chr = game.Players.LocalPlayer.Character
                        if chr then
                            humanoid = chr:FindFirstChild("Humanoid")
                        end
                        
                        if not chr or not humanoid then return end
                        humanoid.WalkSpeed = getgenv().Settings.Player.Modify.WalkSpeed
                    end)
                end
            end)
        else
            humanoid.WalkSpeed = 24.5
        end
    end
})

Modify:Slider({
    Title = "tr:JumpPower",
    Value = {
        Min = 16,
        Max = 200,
        Default = getgenv().Settings.Player.Modify.JumpPower
    },
    Callback = function(Value)
        getgenv().Settings.Player.Modify.JumpPower = Value
        SaveSetting()
    end
})

Modify:Toggle({
    Title = "tr:Enabled",
    Value = getgenv().Settings.Player.Modify.JumpPowerE,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Player.Modify.JumpPowerE = Value
        SaveSetting()
        
        if Value then
            task.spawn(function()
                while getgenv().Settings.Player.Modify.JumpPowerE do task.wait()
                    if not getgenv().Settings.Player.Modify.JumpPowerE then break end
                    pcall(function()
                        chr = game.Players.LocalPlayer.Character
                        if chr then
                            humanoid = chr:FindFirstChild("Humanoid")
                        end

                        if not humanoid.UseJumpPower then
                            humanoid.UseJumpPower = true
                        end
                        
                        if not chr or not humanoid then return end
                        
                        if humanoid.UseJumpPower then
                            humanoid.JumpPower = getgenv().Settings.Player.Modify.JumpPower
                        end
                    end)
                end
            end)
        else
            pcall(function()
                chr = game.Players.LocalPlayer.Character
                if chr then
                    humanoid = chr:FindFirstChild("Humanoid")
                end
                
                if not chr or not humanoid then return end
                if humanoid.UseJumpPower then
                    humanoid.JumpPower = 50
                end
            end)
        end
    end
})

Modify:Toggle({
    Title = "tr:DashNoCooldown",
    Value = getgenv().Settings.Player.Modify.JumpPowerE,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Player.Modify.JumpPowerE = Value
        SaveSetting()
        
        if Value then
            ConfigGame.DashCD = 0
        else
            ConfigGame.DashCD = 3.5
        end
    end
})

local oldGetAttribute

Modify:Toggle({
    Title = "tr:InfiniteCE",
    Value = getgenv().Settings.Player.Modify.InfiniteCE,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Player.Modify.InfiniteCE = Value
        SaveSetting()
        
        if not oldGetAttribute then
            oldGetAttribute = hookmetamethod(game, "__namecall", function(self, ...)
                local args = {...}
                if getnamecallmethod() == "GetAttribute" then
                    if getgenv().Settings.Player.Modify.InfiniteCE then
                        if args[1] == "MaxCE" or args[1] == "CE" then
                            return 6
                        elseif args[1] == "StaminaSpent" then
                            return 0
                        end
                    end
                end
                return oldGetAttribute(self, ...)
            end)
        end
    end
})

Modify:Toggle({
    Title = "tr:StreamerMode",
    Value = getgenv().Settings.Player.Modify.StreamerMode,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Player.Modify.StreamerMode = Value
        SaveSetting()

        if Value then
            local connections = {}
            local processed = {}

            local function enforceText(label, targetText)
                if not label or processed[label] then return end
                processed[label] = true
                
                label.Text = targetText
                
                local conn = label:GetPropertyChangedSignal("Text"):Connect(function()
                    if getgenv().Settings.Player.Modify.StreamerMode then
                        if label.Text ~= targetText then
                            label.Text = targetText
                        end
                    else
                        if connections[label] then
                            connections[label]:Disconnect()
                            connections[label] = nil
                        end
                    end
                end)
                connections[label] = conn
            end

            task.spawn(function()
                while getgenv().Settings.Player.Modify.StreamerMode do
                    pcall(function()
                        local char = game.Players.LocalPlayer.Character
                        if char then
                            local head = char:FindFirstChild("Head")
                            if head then
                                local bb = head:FindFirstChild("HealthBillboardAtt") and head.HealthBillboardAtt:FindFirstChild("HealthNameBillboard")
                                local lbl = bb and bb:FindFirstChild("TextLabel")
                                
                                if lbl then
                                    local currentText = lbl.Text
                                    if not processed[lbl] then
                                        local strippedName = currentText:match("^(.-)%s*<") or currentText
                                        local cleanName = strippedName:match("^%s*(.-)%s*$") or strippedName
                                        
                                        if cleanName == game.Players.LocalPlayer.Name or cleanName == game.Players.LocalPlayer.DisplayName then
                                            local decoration = currentText:match("<.*") or ""
                                            local targetText = 'Venuz Hub' .. decoration
                                            enforceText(lbl, targetText)
                                        end
                                    end
                                end
                            end
                        end
                    end)

                    pcall(function()
                        local myName = game.Players.LocalPlayer.Name
                        local myDisplay = game.Players.LocalPlayer.DisplayName
                        
                        local function scanObj(obj)
                            if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and not processed[obj] then
                                if obj.Text == myName or obj.Text == myDisplay or obj.Text:find(myName) or obj.Text:find(myDisplay) then
                                    if #obj.Text < 50 then 
                                        enforceText(obj, "Venuz Hub")
                                    end
                                end
                            end
                        end

                        local pg = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
                        if pg then
                            for _, v in ipairs(pg:GetDescendants()) do
                                scanObj(v)
                            end
                        end

                        local cg = game:GetService("CoreGui")
                        local pl = cg:FindFirstChild("PlayerList")
                        if pl then
                            for _, v in ipairs(pl:GetDescendants()) do
                                scanObj(v)
                            end
                        end
                    end)
                    
                    task.wait(1)
                end

                for _, conn in pairs(connections) do
                    conn:Disconnect()
                end
            end)
        end
    end
})


workspace.ChildAdded:Connect(function(child)
    if child:IsA("Model") and Players:GetPlayerFromCharacter(child) then
        pcall(function()
            UpdatePlayers()
            if SelectPlayer then
                SelectPlayer:Refresh(PlayersTable)
            end
        end)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child:IsA("Model") then
        pcall(function()
            UpdatePlayers()
            if SelectPlayer then
                SelectPlayer:Refresh(PlayersTable)
            end
        end)
    end
end)

pcall(function()
    UpdatePlayers()
    if SelectPlayer then
        SelectPlayer:Refresh(PlayersTable)
    end
end)

---- ============ Teleport ============ ----

local Tab = Window:Tab({
    Title = "tr:Teleport",
    Icon = "door-closed",
    Opened = true,
})

-- ============ Teleport Setup ============ --

local Village = {["Kitagawa Village"] = CFrame.new(-1962, 4, -2871),["Ruined Fuijihara Village"] = CFrame.new(-370, 78, -1864),["Hotarugawa Town"] = CFrame.new(431, 3, -272),["Jujutsu High"] = CFrame.new(-2570, 102, -573),["Minagata Village"] = CFrame.new(-3009, 3, -1750),["Kanazawa Town"] = CFrame.new(-3375, 4, 2156),["Kaito Village"] = CFrame.new(-1409, 17, 1475),["Yoshiwara City"] = CFrame.new(-5644, 3, -314),}

local NPCByVillage = {
    ["Kitagawa Village"] = {
        ["Emi"] = CFrame.new(-1664, 3, -2904),
        ["Genshiro"] = CFrame.new(-1735, 38, -2607),
        ["Hina"] = CFrame.new(-1552, 3, -2797),
        ["Ren"] = CFrame.new(-1731, 3, -3133),
        ["Tanosuke"] = CFrame.new(-1273, 3, -3107),
        ["Ui Ui"] = CFrame.new(-1980, 3, -2871),
    },

    ["Ruined Fuijihara Village"] = {
        ["Chiyeko"] = CFrame.new(159, 79, -1776),
        ["Dai"] = CFrame.new(-392, 88, -1721),
        ["Hirotaka"] = CFrame.new(-364, 103, -1598),
        ["Juro"] = CFrame.new(-920, 3, -1628),
        ["Masayoshi"] = CFrame.new(-175, 3, -1800),
        ["Norihide"] = CFrame.new(-57, 89, -1946),
        ["Ryobe"] = CFrame.new(-403, 78, -1852),
        ["Yui"] = CFrame.new(303, 23, -1758),
    },

    ["Hotarugawa Town"] = {
        ["Hosuzu"] = CFrame.new(566, 3, -89),
        ["Ijichi"] = CFrame.new(592, 6, -436),
        ["Juzo"] = CFrame.new(563, 3, -230),
        ["Kamlyn"] = CFrame.new(706, 3, -417),
        ["Kanna"] = CFrame.new(443, 3, 17),
        ["Masayoshi"] = CFrame.new(747, 3, -581),
        ["Satoshi"] = CFrame.new(239, 3, -73),
        ["Ui Ui"] = CFrame.new(394, 4, -307),
        ["Yudai"] = CFrame.new(289, 3, -530),
    },

    ["Jujutsu High"] = {
        ["Hatomi"] = CFrame.new(-2269, 102, -159),
        ["Ijichi"] = CFrame.new(-2349, 106, -296),
        ["Juzo"] = CFrame.new(-2380, 102, -540),
        ["Kusakabe"] = CFrame.new(-2897, 128, -15),
        ["Miwa"] = CFrame.new(-2891, 128, -176),
        ["Nakamaro"] = CFrame.new(-2401, 102, -2),
        ["Shlu Kong"] = CFrame.new(-2086, 92, -256),
        ["Takeji"] = CFrame.new(-2109, 102, -826),
        ["Ui Ui"] = CFrame.new(-2349, 106, -463),
        ["Yaga"] = CFrame.new(-2369, 102, -379),
    },

    ["Minagata Village"] = {
        ["Kiyonaga"] = CFrame.new(-3340, 4, -2261),
        ["Arata"] = CFrame.new(-3180, 3, -2574),
        ["Kozue"] = CFrame.new(-2847, 3, -1848),
        ["Sanako"] = CFrame.new(-2409, 3, -2311),
        ["Shigemori"] = CFrame.new(-3166, -1, -1779),
        ["Toyoharu"] = CFrame.new(-3006, 4, -2310),
        ["Ui Ui"] = CFrame.new(-3037, 17, -2142),
        ["Utemaro"] = CFrame.new(-3268, -1, -1729),
    },

    ["Kanazawa Town"] = {
        ["Asami"] = CFrame.new(-3861, 4, 2023),
        ["Kosaku"] = CFrame.new(-3283, 4, 2073),
        ["Kumiyo"] = CFrame.new(-3200, 4, 2293),
        ["Masayoshi"] = CFrame.new(-3389, 4, 2432),
        ["Roka"] = CFrame.new(-3481, 4, 1898),
        ["Tadashi"] = CFrame.new(-3320, 4, 2169),
        ["Toshi"] = CFrame.new(-3200, 4, 2300),
        ["Ui Ui"] = CFrame.new(-3382, 4, 2293),
    },

    ["Kaito Village"] = {
        ["Farmer Joe"] = CFrame.new(-1132, 3, 1270),
        ["Ichisake"] = CFrame.new(-1555, 3, 1586),
        ["Maro"] = CFrame.new(-2095, 23, 1075),
        ["Orihime"] = CFrame.new(-1181, 3, 1500),
        ["Shunsho"] = CFrame.new(-1559, 3, 1300),
        ["Ui Ui"] = CFrame.new(-1395, 5, 1446),
    },

    ["Yoshiwara City"] = {
        ["Tatsui"] = CFrame.new(-5088, 3, -638),
    },
}

local VillageOrder = {"Kitagawa Village","Ruined Fuijihara Village","Hotarugawa Town","Jujutsu High","Minagata Village","Kanazawa Town","Kaito Village","Yoshiwara City",}

local VillageList = table.clone(VillageOrder)

local NpcQuestNow = Tab:Section({ Title = "tr:NpcQuestNow", Icon = "house", Opened = true})

NpcQuestNow:Button({
    Title = "tr:Teleport",
    Callback = function(Value)
        for i,v in pairs(workspace.QuestMarkers:GetChildren()) do
            if v:FindFirstChild("MarkerBillboard") then
                if v:FindFirstChild("MarkerBillboard").Enabled then
                    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = v.CFrame
                end
            end
        end
    end
})

local VillageSection = Tab:Section({ Title = "tr:Village", Icon = "house", Opened = true})

VillageSection:Dropdown({
    Title = "tr:Village",
    Multi = false,
    AllowNone = true,
    Values = VillageList,
    Value = nil,
    Callback = function(Value)
        SelectVillage = Value
    end
})

VillageSection:Button({
    Title = "tr:Teleport",
    Callback = function(Value)
        for i,v in pairs(Village) do
            if SelectVillage == i then
                game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = v
            end
        end
    end
})

local NPCSection = Tab:Section({ Title = "NPC", Icon = "person-standing", Opened = true})
local NPCDropdown

NPCSection:Dropdown({
    Title = "tr:Village",
    Multi = false,
    AllowNone = true,
    Values = VillageList,
    Value = nil,
    Callback = function(villageName)
        SelectVillage1 = villageName

        local npcList = {}
        local npcTable = NPCByVillage[villageName]

        if npcTable then
            for npcName in pairs(npcTable) do
                table.insert(npcList, npcName)
            end
        end

        NPCDropdown:Refresh(npcList)
    end
})

NPCDropdown = NPCSection:Dropdown({
    Title = "NPC",
    Multi = false,
    AllowNone = true,
    Values = nil,
    Value = nil,
    Callback = function(Value)
        SelectNPC = Value
    end
})

NPCSection:Button({
    Title = "tr:Teleport",
    Callback = function()
        if not SelectVillage1 or not SelectNPC then return end
        local cf = NPCByVillage[SelectVillage1] and NPCByVillage[SelectVillage1][SelectNPC]
        if not cf then return end
        local plr = game.Players.LocalPlayer
        local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        hrp.CFrame = cf
    end
})

---- ============ Premium ============ ----

local Tab = Window:Tab({
    Title = "tr:Premium",
    Icon = "diamond-plus",
    Opened = true,
    Locked = getgenv().Premium
})

local Parry = Tab:Section({ Title = "tr:AutoParry", Icon = "sword", Opened = true})
local Enemies = workspace:WaitForChild("Enemies")

local CONFIG = {
    ATTACK_RANGE = 25, 
    BASE_REACTION_TIME = 0.08, 
    SHIELD_COOLDOWN = 0.3,
    IGNORED_ANIMATIONS = {
        ["15586008306"] = true,
        ["15586005620"] = true,
        ["15460558520"] = true,
        ["15460571217"] = true,
        ["77530423631837"] = true,
        ["15279908183"] = true,
    },
    AUTO_DETECT_MODE = true
}

local State = {
    autoParryEnabled = false,
    lastShieldTime = 0,
    knownAnimations = {},
    connections = {},
    detectedAnimations = {}
}


local TargetStatus = Parry:Paragraph({
    Title = "tr:TargetStatus",
    Desc = "None"
})

local function updateTargetStatus()
    if not State.autoParryEnabled then 
        TargetStatus:SetDesc("None")
        return 
    end
    
    if not LocalPlayer.Character then 
        TargetStatus:SetDesc("None")
        return 
    end
    
    local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not localRoot then 
        TargetStatus:SetDesc("None")
        return 
    end
    
    local nearestTarget = nil
    local nearestDistance = math.huge
    
    for _, enemy in ipairs(Enemies:GetChildren()) do
        if enemy:IsA("Model") then
            local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
            if enemyRoot then
                local distance = (localRoot.Position - enemyRoot.Position).Magnitude
                if distance <= CONFIG.ATTACK_RANGE and distance < nearestDistance then
                    nearestDistance = distance
                    nearestTarget = {name = enemy.Name, distance = distance, type = "Enemy"}
                end
            end
        end
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local playerRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if playerRoot then
                local distance = (localRoot.Position - playerRoot.Position).Magnitude
                if distance <= CONFIG.ATTACK_RANGE and distance < nearestDistance then
                    nearestDistance = distance
                    nearestTarget = {name = player.Name, distance = distance, type = "Player"}
                end
            end
        end
    end
    
    if nearestTarget then
        TargetStatus:SetDesc(string.format("%s: %s (%.1f studs)", 
            nearestTarget.type, 
            nearestTarget.name, 
            nearestTarget.distance
        ))
    else
        TargetStatus:SetDesc("None")
    end
end

Parry:Toggle({
    Title = "tr:AutoParry",
    Value = getgenv().Settings.Premium.AutoParry,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Premium.AutoParry = Value
        State.autoParryEnabled = Value
        SaveSetting()
        
        local function activateShield(animId, targetType)
            local currentTime = os.clock()
            if currentTime - State.lastShieldTime < CONFIG.SHIELD_COOLDOWN then return end
            
            task.wait(CONFIG.BASE_REACTION_TIME)
            
            State.lastShieldTime = currentTime
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, nil)
            task.wait(0.1) 
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, nil)
        end

        local function logAnimation(animId, targetType)
            if not State.detectedAnimations[animId] then
                State.detectedAnimations[animId] = {
                    count = 0,
                    sources = {}
                }
            end
            
            State.detectedAnimations[animId].count = State.detectedAnimations[animId].count + 1
            State.detectedAnimations[animId].sources[targetType] = true
        end

        local function shouldParryAnimation(animId, animName)
            if CONFIG.IGNORED_ANIMATIONS[animId] then
                return false
            end
            
            if animName and string.lower(animName):find("idle") then
                return false
            end
            
            return true
        end

        local function setupAnimationTracking(character, targetType)
            local humanoid = character:WaitForChild("Humanoid", 5)
            if not humanoid then return end
            
            local animator = humanoid:WaitForChild("Animator", 5)
            if not animator then return end
            
            local function onAnimationPlayed(animTrack)
                local animId = tostring(animTrack.Animation.AnimationId):match("%d+")
                local animName = animTrack.Animation.Name
                
                if animId then
                    logAnimation(animId, targetType)
                    
                    if shouldParryAnimation(animId, animName) then
                        if LocalPlayer.Character then
                            local targetRoot = character:FindFirstChild("HumanoidRootPart")
                            local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            
                            if targetRoot and localRoot then
                                local distance = (localRoot.Position - targetRoot.Position).Magnitude
                                
                                if distance <= CONFIG.ATTACK_RANGE and State.autoParryEnabled then
                                    activateShield(animId, targetType)
                                end
                            end
                        end
                    end
                end
            end
            
            animator.AnimationPlayed:Connect(onAnimationPlayed)
        end

        local function disconnectAll()
            for _, connection in pairs(State.connections) do
                if connection then
                    connection:Disconnect()
                end
            end
            State.connections = {}
        end

        local function initializeAutoParry()
            disconnectAll()
            
            State.connections.enemyAdded = Enemies.ChildAdded:Connect(function(enemy)
                if enemy:IsA("Model") then
                    task.wait(0.1)
                    setupAnimationTracking(enemy, "Enemy")
                end
            end)
            
            State.connections.playerAdded = Players.PlayerAdded:Connect(function(player)
                if player ~= LocalPlayer then
                    player.CharacterAdded:Connect(function(character)
                        task.wait(0.1)
                        setupAnimationTracking(character, "Player: " .. player.Name)
                    end)
                end
            end)
            
            for _, enemy in ipairs(Enemies:GetChildren()) do
                if enemy:IsA("Model") then
                    setupAnimationTracking(enemy, "Enemy")
                end
            end
            
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    setupAnimationTracking(player.Character, "Player: " .. player.Name)
                end
            end
        end
        
        if Value then
            initializeAutoParry()
        else
            disconnectAll()
        end
    end
})

local DungeonsSection = Tab:Section({ Title = "tr:Dungeons", Icon = "castle", Opened = true})

local DungeonPlaceID = 92950585659247

local DungeonList = {
    ["Hotarugawa Dungeon"] = {
        DungeonKey = "Hotarugawa Dungeon Key",
    },
    ["Kanazawa Dungeon"] = {
        DungeonKey = "Kanazawa Dungeon Key",
    },
    ["Meadow Dungeon"] = {
        DungeonKey = "Meadow Dungeon Key",
    },
}

local SelectDungeon = DungeonsSection:Dropdown({
    Title = "tr:SelectDungeon",
    Multi = false,
    AllowNone = false,
    Value = getgenv().Settings.Premium.Dungeons.SelectDungeon,
    Values = {"Hotarugawa Dungeon", "Kanazawa Dungeon", "Meadow Dungeon"},
    Callback = function(dungeon)
        if DungeonList[dungeon] then
            getgenv().Settings.Premium.Dungeons.SelectDungeon = dungeon
            SaveSetting()
        end
    end,
})

local AutoDungeon = DungeonsSection:Toggle({
    Title = "tr:AutoDungeon",
    Value = getgenv().Settings.Premium.Dungeons.AutoDungeon,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Premium.Dungeons.AutoDungeon = Value
        SaveSetting()
        
        if Value then
            if game.PlaceId ~= DungeonPlaceID then
                return
            end

            if not getgenv().Settings.Automatic.AutoFarm.KillAura then
                KillAuraToggle:Set(true)
            end

            if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Right Arm") and not game.Players.LocalPlayer.Character["Right Arm"]:FindFirstChild("ArmCoating") then
                game:GetService("ReplicatedStorage").Remotes.TranciverRemote:FireServer("Begin","CECoating")
            end
            
            task.spawn(function()
                while getgenv().Settings.Premium.Dungeons.AutoDungeon do task.wait()
                    
                    local character = LocalPlayer.Character
                    if not character then continue end
                    
                    local rootPart = character:FindFirstChild("HumanoidRootPart")
                    if not rootPart then continue end

                    local selectedDungeon = getgenv().Settings.Premium.Dungeons.SelectDungeon
                    local dungeonData = DungeonList[selectedDungeon]
                    if not dungeonData then continue end
                    
                    if not character:GetAttribute("CombatEquipped") then
                        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CombatRemote"):FireServer({Action = "EquipCombat"})
                    end

                    
                    local currentDungeon = workspace:FindFirstChild(selectedDungeon)
                    if not currentDungeon then continue end
                    
                    local chestFound = false
                    for _, model in ipairs(workspace:GetChildren()) do
                        if model:IsA("Model") and model:GetAttribute("OpenAnim") then
                            chestFound = true
                            local chestRoot = model:FindFirstChild("RootPart")
                            if chestRoot then
                                rootPart.CFrame = chestRoot.CFrame * CFrame.new(0, 3, 0)
                                task.wait(0.5)
                                
                                local chest = chestRoot:FindFirstChild("Chest")
                                if chest then
                                    fireproximityprompt(chest)
                                    task.wait(2)
                                end
                                
                                local exitPart = currentDungeon:FindFirstChild("DungeonExit")
                                local exitPrompt = exitPart and exitPart:FindFirstChildOfClass("ProximityPrompt")
                                if exitPrompt and exitPrompt.Enabled then
                                    rootPart.CFrame = exitPart.CFrame * CFrame.new(0, 3, 0)
                                    task.wait(0.5)
                                    fireproximityprompt(exitPrompt)
                                    task.wait(1)
                                end
                            end
                            break
                        end
                    end
                    
                    if not chestFound then
                        local enemies = workspace.Enemies:GetChildren()
                        if currentDungeon then
                            for _, v in ipairs(currentDungeon:GetChildren()) do
                                if v:IsA("Model") and v:FindFirstChild("Humanoid") then
                                    table.insert(enemies, v)
                                end
                            end
                            if currentDungeon:FindFirstChild("Enemies") then
                                for _, v in ipairs(currentDungeon.Enemies:GetChildren()) do
                                    table.insert(enemies, v)
                                end
                            end
                        end

                        for _, enemy in ipairs(enemies) do
                            local hitbox = enemy:FindFirstChild("HumanoidRootPart")
                            if hitbox then
                                local enemyHumanoid = enemy:FindFirstChild("Humanoid")
                                if enemyHumanoid and enemyHumanoid.Health > 0 then
                                    local yOffset = 15
                                    if enemy.Name == "Bojaack" then
                                        yOffset = 30
                                    elseif enemy.Name == "MonkeyFilm0" then
                                        yOffset = -15
                                    end
                                    rootPart.CFrame = hitbox.CFrame * CFrame.new(0, yOffset, 0)
                                    break
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
})

local RaidSection = Tab:Section({ Title = "tr:Raid", Icon = "swords", Opened = true})

local function CreateSafeHealthOverhead(char)
    local head = char:FindFirstChild("Head")
    if not head then return end
    
    if head:FindFirstChild("SafeHealthUI") then return end

    local bb = Instance.new("BillboardGui")
    bb.Name = "SafeHealthUI"
    bb.Adornee = head
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 4, 0)
    bb.AlwaysOnTop = true
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    
    local textContent = "Safe : Regenerating"
    if getgenv().ConfigurationTable.Language == "Thai" then
        textContent = "ปลอดภัย : กำลังฟื้นฟู"
    end
    text.Text = textContent
    
    text.TextColor3 = Color3.fromRGB(0, 255, 0)
    text.TextStrokeTransparency = 0
    text.TextScaled = true
    text.Parent = bb
    
    bb.Parent = head
end

local function RemoveSafeHealthOverhead(char)
    if not char then return end
    local head = char:FindFirstChild("Head")
    if head and head:FindFirstChild("SafeHealthUI") then
        head.SafeHealthUI:Destroy()
    end
end

local AutoRaid = RaidSection:Toggle({
    Title = "tr:AutoRaid",
    Value = getgenv().Settings.Premium.Raid.AutoRaid,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Premium.Raid.AutoRaid = Value
        SaveSetting()

        if Value then

            if game.PlaceId ~= DungeonPlaceID then
                return
            end

            if not getgenv().Settings.Automatic.AutoFarm.KillAura then
                KillAuraToggle:Set(true)
            end

            if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Right Arm") and not game.Players.LocalPlayer.Character["Right Arm"]:FindFirstChild("ArmCoating") then
                game:GetService("ReplicatedStorage").Remotes.TranciverRemote:FireServer("Begin","CECoating")
            end

            task.spawn(function()
                while getgenv().Settings.Premium.Raid.AutoRaid do task.wait()
                    pcall(function()
                        local stats = game:GetService("Players").LocalPlayer.PlayerGui.DungeonGame.DungeonStats
                        if stats.Visible then
                             for _, v in pairs(getconnections(stats.Return.MouseButton1Down)) do
                                  v:Fire()
                             end
                        end
                    end)

                    local character = LocalPlayer.Character
                    if not character then continue end
                    
                    local rootPart = character:FindFirstChild("HumanoidRootPart")
                    local humanoid = character:FindFirstChild("Humanoid")
                    if not rootPart or not humanoid or (character:GetAttribute("HP") or 0) <= 0 then continue end
                    
                    if not character:GetAttribute("CombatEquipped") then
                        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CombatRemote"):FireServer({Action = "EquipCombat"})
                    end

                    local safeThreshold = getgenv().Settings.Premium.Raid.ToSafeZone
                    local healthPercent = ((character:GetAttribute("HP") or 0) / (character:GetAttribute("MaxHP") or 1)) * 100
                    
                    if healthPercent < safeThreshold then
                        rootPart.CFrame = CFrame.new(rootPart.Position.X, -70, rootPart.Position.Z)
                        rootPart.Velocity = Vector3.new(0,0,0)
                        CreateSafeHealthOverhead(character)
                        task.wait(0.1)
                        continue 
                    else
                        RemoveSafeHealthOverhead(character)
                    end
                    
                    local enemies = workspace:FindFirstChild("Enemies")
                    if not enemies then continue end
                    
                    local target = nil
                    local closestDist = math.huge
                    
                    for _, enemy in ipairs(enemies:GetChildren()) do
                        if enemy:FindFirstChild("HumanoidRootPart") and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
                            local dist = (rootPart.Position - enemy.HumanoidRootPart.Position).Magnitude
                            if dist < closestDist then
                                closestDist = dist
                                target = enemy
                            end
                        end
                    end
                    
                    if target then
                        local enemyRoot = target.HumanoidRootPart
                        local yOffset = 15
                        
                        if enemyRoot.Size.Y > 10 then
                             yOffset = 30
                        end
                        
                        rootPart.CFrame = enemyRoot.CFrame * CFrame.new(0, yOffset, 0)
                    else
                        if workspace:FindFirstChild("Raid") and workspace.Raid:FindFirstChild("PlayerPos") then
                            rootPart.CFrame = workspace.Raid.PlayerPos.CFrame
                        end
                    end
                end
                
                local char = LocalPlayer.Character
                if char then RemoveSafeHealthOverhead(char) end
            end)
        else
            local char = LocalPlayer.Character
            if char then RemoveSafeHealthOverhead(char) end
        end
    end
})

RaidSection:Slider({
    Title = "tr:ToSafeZone",
    Value = {
        Min = 1,
        Max = 100,
        Default = getgenv().Settings.Premium.Raid.ToSafeZone
    },
    Callback = function(Value)
        getgenv().Settings.Premium.Raid.ToSafeZone = Value
        SaveSetting()
    end
})

local ChallengeSection = Tab:Section({ Title = "tr:Challenge", Icon = "swords", Opened = true})

ChallengeSection:Dropdown({
    Title = "tr:SelectChallenge",
    Multi = true,
    AllowNone = false,
    Values = {"Temple Challenge", "Yoshiwara Challenge"},
    Value = getgenv().Settings.Premium.Challenge.SelectChallenge,
    Callback = function(Value)
        getgenv().Settings.Premium.Challenge.SelectChallenge = Value
        SaveSetting()
    end
})

ChallengeSection:Toggle({
    Title = "tr:AutoJoinChallenge",
    Value = getgenv().Settings.Premium.Challenge.AutoJoinChallenge,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Premium.Challenge.AutoJoinChallenge = Value
        SaveSetting()

        if Value then
            StartNoClip()
            task.spawn(function()
                while getgenv().Settings.Premium.Challenge.AutoJoinChallenge do task.wait(1)
                    if workspace:GetAttribute("Gamemode") == "Challenge" then continue end
                    
                    local selectedList = getgenv().Settings.Premium.Challenge.SelectChallenge
                    if #selectedList == 0 then continue end

                    local character = LocalPlayer.Character
                    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                    if rootPart then
                        local mainChallenge = selectedList[1]
                        if mainChallenge == "Temple Challenge" then
                            rootPart.CFrame = CFrame.new(-478, 100, 1885)
                        elseif mainChallenge == "Yoshiwara Challenge" then
                            rootPart.CFrame = CFrame.new(-6334, 100, -1499)
                        end
                    end

                    for _, name in ipairs(selectedList) do
                        local portal = workspace.Ignore:FindFirstChild(name)
                        if portal then
                            local billboard = portal:FindFirstChild("NameAtt") and portal.NameAtt:FindFirstChild("BillboardGui")
                            local timeLabel = billboard and (billboard:FindFirstChild("BeginTime") or billboard:FindFirstChildOfClass("TextLabel"))
                            if timeLabel and timeLabel.Text:find("Ends in") then
                                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Dungeon"):FireServer("StartChallenge", {ChallengeName = name})
                                task.wait(1)
                                break
                            end
                        end
                    end
                end
                StopNoClip()
            end)
        else
            StopNoClip()
        end
    end
})

ChallengeSection:Toggle({
    Title = "tr:AutoChallenge",
    Value = getgenv().Settings.Premium.Challenge.AutoChallenge,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Premium.Challenge.AutoChallenge = Value
        SaveSetting()

        if Value then
            if game.PlaceId ~= DungeonPlaceID and workspace:GetAttribute("Gamemode") ~= "Challenge" then
                return
            end

            if not getgenv().Settings.Automatic.AutoFarm.KillAura then
                KillAuraToggle:Set(true)
            end

            if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Right Arm") and not game.Players.LocalPlayer.Character["Right Arm"]:FindFirstChild("ArmCoating") then
                game:GetService("ReplicatedStorage").Remotes.TranciverRemote:FireServer("Begin","CECoating")
            end

            task.spawn(function()
                while getgenv().Settings.Premium.Challenge.AutoChallenge do task.wait()
                    local character = LocalPlayer.Character
                    if not character then continue end
                    
                    local rootPart = character:FindFirstChild("HumanoidRootPart")
                    local humanoid = character:FindFirstChild("Humanoid")
                    if not rootPart or not humanoid or (character:GetAttribute("HP") or 0) <= 0 then continue end
                    
                    if not character:GetAttribute("CombatEquipped") then
                        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CombatRemote"):FireServer({Action = "EquipCombat"})
                    end

                    local selectedList = getgenv().Settings.Premium.Challenge.SelectChallenge
                    local currentChallenge = nil
                    
                    for _, name in ipairs(selectedList) do
                        if workspace:FindFirstChild(name) then
                            currentChallenge = workspace[name]
                            break
                        end
                    end

                    if not currentChallenge and workspace:GetAttribute("Gamemode") == "Challenge" then
                        for _, v in ipairs(workspace:GetChildren()) do
                            if v:FindFirstChild("DungeonExit") then
                                currentChallenge = v
                                break
                            end
                        end
                    end

                    local exitPart = currentChallenge and currentChallenge:FindFirstChild("DungeonExit")
                    local exitPrompt = exitPart and exitPart:FindFirstChildOfClass("ProximityPrompt")
                    if exitPrompt and exitPrompt.Enabled then
                        rootPart.CFrame = exitPart.CFrame * CFrame.new(0, 3, 0)
                        task.wait(0.5)
                        fireproximityprompt(exitPrompt)
                        task.wait(1)
                        continue
                    end

                    local chestFound = false
                    for _, model in ipairs(workspace:GetChildren()) do
                        if model:IsA("Model") and model:GetAttribute("OpenAnim") then
                            chestFound = true
                            local chestRoot = model:FindFirstChild("RootPart")
                            if chestRoot then
                                rootPart.CFrame = chestRoot.CFrame * CFrame.new(0, 3, 0)
                                task.wait(0.5)

                                local chest = chestRoot:FindFirstChild("Chest")
                                if chest then
                                    fireproximityprompt(chest)
                                    task.wait(2)
                                end

                                if exitPrompt and exitPrompt.Enabled then
                                    rootPart.CFrame = exitPart.CFrame * CFrame.new(0, 3, 0)
                                    task.wait(0.5)
                                    fireproximityprompt(exitPrompt)
                                    task.wait(1)
                                end
                            end
                            break
                        end
                    end

                    if not chestFound then
                        local safeThreshold = getgenv().Settings.Premium.Challenge.ToSafeZone
                        local healthPercent = ((character:GetAttribute("HP") or 0) / (character:GetAttribute("MaxHP") or 1)) * 100
                        
                        if healthPercent < safeThreshold then
                            rootPart.CFrame = CFrame.new(rootPart.Position.X, -70, rootPart.Position.Z)
                            rootPart.Velocity = Vector3.new(0,0,0)
                            CreateSafeHealthOverhead(character)
                            task.wait(0.1)
                            continue 
                        else
                            RemoveSafeHealthOverhead(character)
                        end
                        
                        local enemies = {}
                        if workspace:FindFirstChild("Enemies") then
                            for _, v in ipairs(workspace.Enemies:GetChildren()) do
                                table.insert(enemies, v)
                            end
                        end

                        if currentChallenge then
                            for _, v in ipairs(currentChallenge:GetChildren()) do
                                if v:IsA("Model") and v:FindFirstChild("Humanoid") then
                                    table.insert(enemies, v)
                                end
                            end
                            if currentChallenge:FindFirstChild("Enemies") then
                                for _, v in ipairs(currentChallenge.Enemies:GetChildren()) do
                                    table.insert(enemies, v)
                                end
                            end
                        end

                        if #enemies == 0 then continue end
                        
                        local target = nil
                        local closestDist = math.huge
                        
                        for _, enemy in ipairs(enemies) do
                            if enemy:FindFirstChild("HumanoidRootPart") and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
                                local dist = (rootPart.Position - enemy.HumanoidRootPart.Position).Magnitude
                                if dist < closestDist then
                                    closestDist = dist
                                    target = enemy
                                end
                            end
                        end
                        
                        if target then
                            local enemyRoot = target.HumanoidRootPart
                            local yOffset = 15
                            
                            if target.Name == "MonkeyFilm0" then
                                yOffset = -15
                            elseif enemyRoot.Size.Y > 10 then
                                 yOffset = 30
                            end
                            
                            rootPart.CFrame = enemyRoot.CFrame * CFrame.new(0, yOffset, 0)
                        end
                    end
                end
                
                local char = LocalPlayer.Character
                if char then RemoveSafeHealthOverhead(char) end
            end)
        else
            local char = LocalPlayer.Character
            if char then RemoveSafeHealthOverhead(char) end
        end
    end
})

ChallengeSection:Slider({
    Title = "tr:ToSafeZone",
    Value = {
        Min = 1,
        Max = 100,
        Default = getgenv().Settings.Premium.Challenge.ToSafeZone
    },
    Callback = function(Value)
        getgenv().Settings.Premium.Challenge.ToSafeZone = Value
        SaveSetting()
    end
})

local GradeSection = Tab:Section({ Title = "tr:Grade", Icon = "medal", Opened = true})

local AutoJoinGrade = GradeSection:Toggle({
    Title = "tr:AutoJoinGrade",
    Value = getgenv().Settings.Premium.Grade.AutoJoinGrade,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Premium.Grade.AutoJoinGrade = Value
        SaveSetting()

        if Value then
            task.spawn(function()
                while getgenv().Settings.Premium.Grade.AutoJoinGrade do task.wait(1)
                    if game.PlaceId == 16997064928 then
                        task.wait(2)
                        if not getgenv().Settings.Premium.Grade.AutoJoinGrade then return end
                        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("SorcererSchool"):FireServer(unpack({"Get a Mission"}))
                    end
                end
            end)
        end
    end
})

local AutoGrade = GradeSection:Toggle({
    Title = "tr:AutoGrade",
    Value = getgenv().Settings.Premium.Grade.AutoGrade,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Premium.Grade.AutoGrade = Value
        SaveSetting()

        if Value then

            if game.PlaceId ~= DungeonPlaceID then
                return
            end

            if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Right Arm") and not game.Players.LocalPlayer.Character["Right Arm"]:FindFirstChild("ArmCoating") then
                game:GetService("ReplicatedStorage").Remotes.TranciverRemote:FireServer("Begin","CECoating")
            end

            task.spawn(function()
                while getgenv().Settings.Premium.Grade.AutoGrade do task.wait()

                    local character = LocalPlayer.Character
                    if not character then continue end
                    
                    local rootPart = character:FindFirstChild("HumanoidRootPart")
                    local humanoid = character:FindFirstChild("Humanoid")
                    if not rootPart or not humanoid or (character:GetAttribute("HP") or 0) <= 0 then continue end
                    
                    if not character:GetAttribute("CombatEquipped") then
                        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("CombatRemote"):FireServer({Action = "EquipCombat"})
                    end

                    local safeThreshold = getgenv().Settings.Premium.Grade.ToSafeZone
                    local healthPercent = ((character:GetAttribute("HP") or 0) / (character:GetAttribute("MaxHP") or 1)) * 100
                    
                    if healthPercent < safeThreshold then
                        rootPart.CFrame = CFrame.new(rootPart.Position.X, -70, rootPart.Position.Z)
                        rootPart.Velocity = Vector3.new(0,0,0)
                        CreateSafeHealthOverhead(character)
                        task.wait(0.1)
                        continue 
                    else
                        RemoveSafeHealthOverhead(character)
                    end
                    
                    local enemies = workspace:FindFirstChild("Enemies")
                    if not enemies then continue end
                    
                    local target = nil
                    local closestDist = math.huge
                    
                    for _, enemy in ipairs(enemies:GetChildren()) do
                        if enemy:FindFirstChild("HumanoidRootPart") and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
                            local dist = (rootPart.Position - enemy.HumanoidRootPart.Position).Magnitude
                            if dist < closestDist then
                                closestDist = dist
                                target = enemy
                            end
                        end
                    end
                    
                    if target then
                        local enemyRoot = target.HumanoidRootPart
                        local yOffset = 15
                        
                        if target.Name == "MonkeyFilm0" then
                            yOffset = -15
                        elseif enemyRoot.Size.Y > 10 then
                             yOffset = 30
                        end
                        
                        rootPart.CFrame = enemyRoot.CFrame * CFrame.new(0, yOffset, 0)
                    end
                end
                
                local char = LocalPlayer.Character
                if char then RemoveSafeHealthOverhead(char) end
            end)
        else
            local char = LocalPlayer.Character
            if char then RemoveSafeHealthOverhead(char) end
        end
    end
})

---- ============ Configuration ============ ----

Window:Divider()

local Tab = Window:Tab({
    Title = "tr:Configuration",
    Icon = "settings",
    Locked = false,
})

local Interface = Tab:Section({ Title = "tr:Interface", Icon = "settings-2"})

local themeValues = {}
for name, _ in pairs(WindUI:GetThemes()) do
    table.insert(themeValues, name)
end

local themeDropdown = Tab:Dropdown({
    Title = "tr:themeDropdown",
    Multi = false,
    AllowNone = false,
    Value = getgenv().ConfigurationTable.Themes,
    Values = themeValues,
    Callback = function(theme)
        getgenv().ConfigurationTable.Themes = theme
        SaveConfiguration()
        WindUI:SetTheme(theme)
    end
})

local ToggleTransparency = Tab:Toggle({
    Title = "tr:ToggleTransparency",
    Value = getgenv().ConfigurationTable.Transparent,
    Icon = "check",
    Callback = function(e)
        getgenv().ConfigurationTable.Transparent = e
        SaveConfiguration()
        Window:ToggleTransparency(e)
    end,
    Value = WindUI:GetTransparency()
})

local AntiAFK = Tab:Toggle({
    Title = "tr:AntiAFK",
    Value = getgenv().ConfigurationTable.AntiAFK,
    Icon = "check",
    Callback = function(enabled)
        local VirtualUser = game:service('VirtualUser')
        local antiAfkConnection = nil

        getgenv().ConfigurationTable.AntiAFK = enabled
        SaveConfiguration()

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

local AutoRejoin = Tab:Toggle({
    Title = "tr:AutoRejoin",
    Value = getgenv().ConfigurationTable.AutoRejoin,
    Icon = "check",
    Callback = function(enabled)
        getgenv().ConfigurationTable.AutoRejoin = enabled
        SaveConfiguration()

        if enabled then
            if not enabled then
                if getgenv().Settings.Automatic.AutoFarm.AutoFarmRock then
                    getgenv().Settings.Automatic.AutoFarm.AutoFarmRock:Disconnect()
                    getgenv().Settings.Automatic.AutoFarm.AutoFarmRock = nil
                end
                return
            end

            if getgenv().Settings.Automatic.AutoFarm.AutoFarmRock then
                return
            end

            getgenv().Settings.Automatic.AutoFarm.AutoFarmRock = game.CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
                if child.Name == "ErrorPrompt" then
                    game:GetService("TeleportService"):Teleport(game.PlaceId, game:GetService("Players").LocalPlayer)
                end
            end)
        end
    end
})

local AutoExecutor = Tab:Toggle({
    Title = "tr:AutoExecutor",
    Value = getgenv().ConfigurationTable.AutoExecutor,
    Icon = "check",
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoExecutor = Value
        SaveConfiguration()
    end
})

local MinimizeBind = Tab:Keybind({
    Title = "tr:MinimizeBind",
    Value = getgenv().ConfigurationTable.MinimizeBind,
    Callback = function(v)
        getgenv().ConfigurationTable.MinimizeBind = v
        SaveConfiguration()
        Window:SetToggleKey(Enum.KeyCode[v])
    end
})

local FPSIS = Tab:Section({ Title = "tr:FPSIS", Icon = "gamepad"})

local FPSVALUE = Tab:Slider({
    Title = "tr:FPSVALUE",
    Value = {
        Min = 1,
        Max = 240,
        Default = getgenv().ConfigurationTable.FPSValue
    },
    Callback = function(Value)
        getgenv().ConfigurationTable.FPSValue = Value
        SaveConfiguration()
    end
})

local FPSLOCK = Tab:Toggle({
    Title = "tr:FPSLOCK",
    Default = getgenv().ConfigurationTable.LockFPS,
    Icon = "check",
    Callback = function(v)
        getgenv().ConfigurationTable.LockFPS = v
        SaveConfiguration()

        if v then
            task.spawn(function()
                pcall(function()
                    while getgenv().ConfigurationTable.LockFPS do task.wait()
                        if getgenv().ConfigurationTable.LockFPS then
                            setfpscap(tonumber(getgenv().ConfigurationTable.FPSValue))
                        else
                            setfpscap(240)
                        end
                    end
                end)
            end)
        end
    end
})

local WhiteScreen = Tab:Toggle({
    Title = "tr:WhiteScreen",
    Default = getgenv().ConfigurationTable.WhileScreen,
    Icon = "check",
    Callback = function(v)
        getgenv().ConfigurationTable.WhileScreen = v
        SaveConfiguration()

        local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        local screenGui = playerGui:FindFirstChild("Venuz_White")

        if v then
            if not screenGui then
                screenGui = Instance.new("ScreenGui")
                screenGui.Name = "Venuz_White"
                screenGui.Enabled = true
                screenGui.IgnoreGuiInset = true
                screenGui.Parent = playerGui

                local frame = Instance.new("Frame")
                frame.Name = "Venuz_1"
                frame.Position = UDim2.new(0,0,0,0)
                frame.Size = UDim2.new(1,0,1,0)
                frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                frame.Parent = screenGui
            else
                screenGui.Enabled = true
            end
        else
            if screenGui then
                screenGui.Enabled = false
            end
        end
    end
})

local LanguageTab =  Tab:Section({ Title = "tr:LanguageTab", Icon = "languages"})

local Language = Tab:Dropdown({
    Title = "tr:Language",
    Multi = false,
    AllowNone = false,
    Values = {"English (US)","Thai"},
    Value = getgenv().ConfigurationTable.Language,
    Callback = function(Callback)
        getgenv().ConfigurationTable.Language = Callback
        SaveConfiguration()
    end
})

local ChangedLanguage = Tab:Button({
    Title = "tr:ChangedLanguage",
    Callback = function()
        if getgenv().ConfigurationTable.Language == "English (US)" then
            WindUI:SetLanguage("English (US)")
        else
            WindUI:SetLanguage("Thai")
        end
        Window:SelectTab(1)
    end
})

local queueteleport = queue_on_teleport
local TeleportCheck = false

while not Players.LocalPlayer do task.wait() end

LocalPlayer.OnTeleport:Connect(function(State)
    pcall(function()
        if getgenv().ConfigurationTable and getgenv().ConfigurationTable.AutoExecutor and (not TeleportCheck) and queueteleport then
            TeleportCheck = true
            queueteleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/x2Kotaro/Venuz-hub/main/Loader.lua"))()')
        end
    end)
end)

Window:SetToggleKey(Enum.KeyCode[getgenv().ConfigurationTable.MinimizeBind])
Window:SelectTab(1)

WindUI:Notify({
    Title = "tr:ScriptLoader",
    Content = "tr:ScriptLoaded",
    Icon = VenuzIcon,
    Duration = 5,
})

RunService.RenderStepped:Connect(function()
    updateTargetStatus()
    
    if game.PlaceId == 16997064928 then
        if not (getgenv().Settings.Automatic.AutoFarm.AutoFarmEnemie or getgenv().Settings.Automatic.AutoBoss.AutoFarmBoss or getgenv().Settings.Automatic.AutoWorldEvents) then
            return
        end
    end

    local plr = game.Players.LocalPlayer
    local char = plr.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")

    if not hrp or not hum or hum.Health <= 0 then
        return
    end

    local footer = workspace:FindFirstChild("Venuz_Footer")
    if not footer then
        footer = Instance.new("Part")
        footer.Name = "Venuz_Footer"
        footer.Parent = workspace
        footer.Size = Vector3.new(5, 0.5, 5)
        footer.Transparency = 1
        footer.Anchored = true
        footer.CanCollide = true
    end

    footer.CFrame = hrp.CFrame * CFrame.new(0, -3.5, 0)

    local cam = workspace.CurrentCamera
    if getgenv().Settings.Automatic.AutoFarm.AutoFarmEnemie then
        cam.CameraType = Enum.CameraType.Custom
    end
end)