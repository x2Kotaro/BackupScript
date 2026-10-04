getgenv().ConfigurationTable = {}

local FolderConfiguration = "Valkyrie Hub"
local FolderSettings = "Valkyrie Hub/DQR"
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait()
    LocalPlayer = Players.LocalPlayer
end

local IconValkyrie = "87057639235201"
local LibraryUrl = "https://www.valkyriehub.net/api/raw/ui-lib"

local SessionToken = { }
local SessionConnections = { }

if type(getgenv().ValkyrieCleanup) == "function" then
    pcall(getgenv().ValkyrieCleanup)
end

getgenv().ValkyrieSession = SessionToken

local function TrackConnection(Connection)
    if Connection then
        table.insert(SessionConnections, Connection)
    end
    return Connection
end

local filenameConfiguration = FolderConfiguration .. "/" .. "Setting_" .. LocalPlayer.Name .. ".json"

task.spawn(function()
    if isfolder and makefolder then
        if not isfolder(FolderConfiguration) then makefolder(FolderConfiguration) end
        if not isfolder(FolderSettings) then makefolder(FolderSettings) end
    end
end)

---- ============ Configuration ============ ----

local DefaultConfiguration = {
    ["Transparent"] = true,
    ["AntiAFK"] = true,
    ["AutoRejoin"] = true,
    ["AutoExecutor"] = true,
    ["MinimizeBind"] = "End",
    ["Language"] = "English (US)",
    ["FPSValue"] = 144,
    ["LockFPS"] = false,
    ["AutoJoinEnabled"] = false,
    ["AutoJoinOnStartup"] = false,
    ["AutoJoinDungeon"] = "Desert Temple",
    ["AutoJoinDifficulty"] = "Easy",
    ["AutoJoinLevelReq"] = 0,
    ["AutoJoinHardcore"] = false,
    ["AutoJoinPrivate"] = false,
    ["AutoJoinWaveDefence"] = false,
    ["AutoFarm"] = false,
    ["WalkSpeed"] = 16,
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
            getgenv().ConfigurationTable = DefaultConfiguration
        end
    else
        getgenv().ConfigurationTable = DefaultConfiguration
    end
end

function SaveConfiguration()
    if writefile and makefolder then
        if not isfolder(FolderConfiguration) then makefolder(FolderConfiguration) end

        local json = HttpService:JSONEncode(getgenv().ConfigurationTable)
        writefile(filenameConfiguration, json)
    end
end

LoadConfiguration()

---- ============ Library ============ ----

local Library do
    local Ok, Source = pcall(game.HttpGet, game, LibraryUrl, true)

    if not (Ok and type(Source) == "string" and #Source > 50000) then
        error(string.format(
            "[ValkyrieHub] %s did not return the UI library (%s, %d bytes -- expected 100000+)",
            LibraryUrl,
            Ok and "ok" or tostring(Source),
            Ok and #tostring(Source) or 0
        ), 0)
    end

    local Chunk, Err = loadstring(Source)

    if not Chunk then
        error("[ValkyrieHub] UI library did not compile: " .. tostring(Err), 0)
    end

    Library = Chunk()

    if type(Library) ~= "table" then
        error("[ValkyrieHub] UI library ran but returned " .. typeof(Library), 0)
    end
end

Library:AddLanguages({
    th = {
        ["Configuration"] = "ตั้งค่า",
        ["Interface"] = "ตั้งค่าหน้าต่าง",
        ["Window Transparency"] = "ทำหน้าต่างโปร่งใส",
        ["Anti-AFK"] = "กันหลุด AFK",
        ["Auto Rejoin"] = "เข้าเกมใหม่อัตโนมัติ",
        ["Auto Executor"] = "รันสคริปต์ตอนย้ายเซิร์ฟ",
        ["Minimize Bind"] = "ปุ่มย่อ/เปิดเมนู",
        ["FPS"] = "FPS",
        ["FPS Value"] = "ค่า FPS",
        ["FPS Lock"] = "ล็อก FPS",
        ["Language"] = "ภาษา",
        ["Select Language"] = "เลือกภาษา",
        ["Change Language"] = "เปลี่ยนภาษา",
        ["Automatic"] = "อัตโนมัติ",
        ["Settings"] = "ตั้งค่า",
        ["Dungeon Select"] = "เลือกดันเจี้ยน",
        ["Pick dungeon, difficulty and stage"] = "เลือกดันเจี้ยน ความยาก และด่าน",
        ["Dungeon"] = "ดันเจี้ยน",
        ["Difficulty"] = "ความยาก",
        ["Level Requirement"] = "เลเวลขั้นต่ำ",
        ["Lobby Options"] = "ตัวเลือกล็อบบี้",
        ["Hardcore, private and wave defence"] = "ฮาร์ดคอร์, ส่วนตัว และเวฟดีเฟนซ์",
        ["Hardcore"] = "ฮาร์ดคอร์",
        ["Private Lobby"] = "ล็อบบี้ส่วนตัว",
        ["Wave Defence"] = "เวฟดีเฟนซ์",
        ["Auto Start"] = "เริ่มอัตโนมัติ",
        ["Farm"] = "ฟาร์ม",
        ["Kite at range, dodge boss skills and cast"] = "ยืนยิงระยะไกล หลบสกิลบอส และร่ายสกิลอัตโนมัติ",
        ["Auto Farm"] = "ฟาร์มอัตโนมัติ",
        ["Walk Speed"] = "ความเร็วเดิน",
    }
})

local LocaleByLanguage = {
    ["English (US)"] = "en",
    ["Thai"] = "th"
}

local function ApplyLanguage(Name)
    Library:SetLocale(LocaleByLanguage[Name] or "en")
end

ApplyLanguage(getgenv().ConfigurationTable.Language)

local Window = Library:Window({
    Name = "Dungeon Quest Reborn",
    SubName = "by Phoenix",
    Logo = IconValkyrie
})

Window:Category("General")

---- ============ Automatic Tab ============ ----

local AutoJoinPage = Window:Page({ Name = "Automatic", Icon = "80758916183665", Columns = 2 })

local DungeonNames = {
    "Tutorial Dungeon", "Desert Temple", "Winter Outpost", "Pirate Island",
    "King's Castle", "The Underworld", "Samurai Palace", "The Canals",
    "Steampunk Sewers", "Ghastly Harbor", "Orbital Outpost", "Volcanic Chambers",
    "Enchanted Forest", "Aquatic Temple", "Northern Lands", "Oni Dungeon",
    "Krampus", "Gilded Skies", "Egg Island",
}

local DifficultyNames = { "Easy", "Medium", "Hard", "Insane", "Nightmare" }

-- ล็อบบี้เก่ายังค้างอยู่ (workspace.games.inGame/inLobby) ทำให้ createLobby ถูกปฏิเสธเงียบ ๆ ต้องออกก่อน
local function IsInLobbyOrGame()
    local Games = workspace:FindFirstChild("games")
    if not Games then return false end

    for _, Container in ipairs({ Games:FindFirstChild("inGame"), Games:FindFirstChild("inLobby") }) do
        if Container then
            for _, Lobby in ipairs(Container:GetChildren()) do
                if Lobby:FindFirstChild(LocalPlayer.Name) then
                    return true
                end
            end
        end
    end

    return false
end

-- ยิง remote สร้าง/เข้าดันเจี้ยนตามค่าที่ตั้งไว้ (ชื่อดันเจี้ยน, ความยาก, เลเวลขั้นต่ำ, ฮาร์ดคอร์, ส่วนตัว, เวฟดีเฟนซ์)
local function FireAutoJoinDungeon()
    local Remotes = ReplicatedStorage:FindFirstChild("remotes")
    local Remote = Remotes and Remotes:FindFirstChild("createLobby")
    if not Remote then return false, "createLobby remote not found" end

    if IsInLobbyOrGame() then
        local LeaveRemote = Remotes:FindFirstChild("leaveGame")
        if LeaveRemote then
            pcall(function() LeaveRemote:FireServer() end)
            task.wait(1)
        end
    end

    local Config = getgenv().ConfigurationTable

    local Ok, Result = pcall(function()
        return Remote:InvokeServer(
            Config.AutoJoinDungeon,
            Config.AutoJoinDifficulty,
            tonumber(Config.AutoJoinLevelReq) or 0,
            Config.AutoJoinHardcore,
            Config.AutoJoinPrivate,
            Config.AutoJoinWaveDefence
        )
    end)

    return Ok and Result, Result
end

local AutoJoinSection = AutoJoinPage:Section({
    Name = "Dungeon Select",
    Description = "Pick dungeon, difficulty and stage",
    Icon = "93142176757189",
    Side = 1
})

AutoJoinSection:Dropdown({
    Name = "Dungeon",
    Flag = "DQRAutoJoinDungeon",
    Items = DungeonNames,
    Default = getgenv().ConfigurationTable.AutoJoinDungeon,
    Multi = false,
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoJoinDungeon = Value
        SaveConfiguration()
    end
})

AutoJoinSection:Dropdown({
    Name = "Difficulty",
    Flag = "DQRAutoJoinDifficulty",
    Items = DifficultyNames,
    Default = getgenv().ConfigurationTable.AutoJoinDifficulty,
    Multi = false,
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoJoinDifficulty = Value
        SaveConfiguration()
    end
})

AutoJoinSection:Slider({
    Name = "Level Requirement",
    Flag = "DQRAutoJoinLevelReq",
    Min = 0,
    Max = 300,
    Default = getgenv().ConfigurationTable.AutoJoinLevelReq,
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoJoinLevelReq = Value
        SaveConfiguration()
    end
})

AutoJoinSection:Toggle({
    Name = "Hardcore",
    Flag = "DQRAutoJoinHardcore",
    Default = getgenv().ConfigurationTable.AutoJoinHardcore,
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoJoinHardcore = Value
        SaveConfiguration()
    end
})

AutoJoinSection:Toggle({
    Name = "Private Lobby",
    Flag = "DQRAutoJoinPrivate",
    Default = getgenv().ConfigurationTable.AutoJoinPrivate,
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoJoinPrivate = Value
        SaveConfiguration()
    end
})

AutoJoinSection:Toggle({
    Name = "Wave Defence",
    Flag = "DQRAutoJoinWaveDefence",
    Default = getgenv().ConfigurationTable.AutoJoinWaveDefence,
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoJoinWaveDefence = Value
        SaveConfiguration()
    end
})

AutoJoinSection:Toggle({
    Name = "Auto Start",
    Flag = "DQRAutoJoinOnStartup",
    Default = getgenv().ConfigurationTable.AutoJoinOnStartup,
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoJoinOnStartup = Value
        SaveConfiguration()

        if Value then
            task.spawn(FireAutoJoinDungeon)
        end
    end
})

if getgenv().ConfigurationTable.AutoJoinOnStartup then
    task.spawn(function()
        task.wait(3)
        if getgenv().ValkyrieSession == SessionToken then
            pcall(FireAutoJoinDungeon)
        end
    end)
end

---- ============ Auto Farm ============ ----

do
    local PathfindingService = game:GetService("PathfindingService")
    local RunService = game:GetService("RunService")

    local FarmSection = AutoJoinPage:Section({
        Name = "Farm",
        Description = "Kite at range, dodge boss skills and cast",
        Icon = "93142176757189",
        Side = 2
    })

    local Farm = {
        Active = false,
        InRange = false,
        Target = nil,
        Heartbeat = nil,
        Waypoints = nil,
        WaypointIndex = 1,
        PathAt = 0,
        TickAt = 0,
        StartPressAt = 0,
        GatherAt = 0,
        MoveDirection = nil,
        Approaching = false,
        SafeSpot = nil,
        Held = false,
        RallyAt = 0,
        MoveGoal = nil,
        StuckAt = 0,
        StuckFrom = nil,
        UnstickUntil = 0,
        UnstickDirection = nil,
        UnstickSign = 1,
        StandSpot = nil,
        StandAt = 0,
    }

    getgenv().DQRFarmDebug = Farm -- ชั่วคราว เอาไว้ตรวจสด ลบทิ้งทีหลัง

    -- ระยะยืนยิง: ไกลพอให้ม็อบประชิดตีไม่ถึง แต่ยังอยู่ในระยะสกิลจริง (วัดจากของจริง 15-23 studs)
    local StandoffMin = 16   -- ใกล้กว่านี้ = เดินวนออก
    local StandoffMax = 26   -- ไกลกว่านี้ = เดินเข้า
    local PathRefresh = 0.8

    local HazardPadding = 12   -- รัศมีเผื่อหลบของอันตราย บวกขนาดตัวมันเองอีกที

    local function Flat(V)
        return Vector3.new(V.X, 0, V.Z)
    end

    local function GetCharacter()
        local Character = LocalPlayer.Character
        if not Character then return nil end

        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        local Root = Character:FindFirstChild("HumanoidRootPart")

        if not Humanoid or Humanoid.Health <= 0 or not Root then return nil end

        return Character, Humanoid, Root
    end

    --// ล้างสิ่งกีดขวางในด่าน
    --
    -- ลบทุกอย่างที่ชนแล้วเดินไม่ผ่าน เหลือไว้แต่พื้นที่ยืน กันติดมุมตอนถอยหนีม็อบ
    --
    -- แยกพื้นด้วยรูปทรง ไม่ใช่ความสูงเทียบตัวละคร เพราะแต่ละห้องพื้นอยู่คนละระดับ
    -- พื้น = แบนและกว้าง, กำแพง/เสา/ทางลาด = ตั้งสูงหรือแคบ ลบหมด
    local ProtectedNames = {
        startPart = true, endPart = true,
        spawn = true, enemyFolder = true,
        borders = true, -- กำแพงขอบแมพ ลบแล้วเดินตกออกนอกแมพ
    }

    -- ต้นไม้/กองไฟ/ของตกแต่งอยู่ใน workspace.Map ไม่ได้อยู่ใน dungeon ต้องกวาดทั้งคู่
    local ObstacleContainers = { "dungeon", "Map" }

    -- กองเศษหินมักมีชิ้นแบนกว้างประกอบกัน เข้าเกณฑ์ "รูปทรงเหมือนพื้น" พอดี เลยกันด้วยชื่อแทน
    local ForceRemoveNames = {
        rubble = true,
    }

    local function IsForceRemoved(Instance)
        local Current = Instance

        while Current and Current ~= workspace do
            local Name = Current.Name:lower()

            for Prefix in pairs(ForceRemoveNames) do
                if Name:sub(1, #Prefix) == Prefix then return true end
            end

            Current = Current.Parent
        end

        return false
    end

    local function IsFloorLike(Part)
        if IsForceRemoved(Part) then return false end

        -- ทะลุได้ = ยืนไม่ได้ = ไม่ใช่พื้น (ใบไม้ต้นไม้แบนกว้างเข้าเกณฑ์รูปทรงพื้นพอดี เลยรอดมาตลอด)
        if not Part.CanCollide then return false end

        local Size = Part.Size

        -- แบน (สูงไม่เกิน 4) และกว้างพอจะยืนได้ทั้งสองแกน
        return Size.Y <= 4 and Size.X >= 8 and Size.Z >= 8
    end

    local function IsProtected(Instance)
        local Current = Instance

        while Current and Current ~= workspace do
            if ProtectedNames[Current.Name] then return true end
            Current = Current.Parent
        end

        return false
    end

    --// จำกำแพงไว้ก่อนลบ
    --
    -- พอลบ prop ทิ้งหมดแล้ว เรย์เช็คกำแพงใช้ไม่ได้เพราะไม่เหลืออะไรให้ชน เลยเก็บรูปทรงไว้ก่อนลบ
    -- แล้วเอากล่องที่จำไว้มาเช็คแทน
    local RemovedWalls = { }
    local RecordedDungeon = nil

    Farm.RemovedWalls = RemovedWalls -- ชั่วคราว เอาไว้ตรวจสด

    local function RememberWall(Part)
        local Size = Part.Size

        -- กำแพงจริงต้องตั้งสูงพอจะบัง และยาวพอจะกั้นทาง -- เสาเล็ก/กล่องเตี้ยไม่นับ
        if Size.Y >= 6 and math.max(Size.X, Size.Z) >= 10 then
            table.insert(RemovedWalls, { CFrame = Part.CFrame, Half = Size * 0.5 })
        end
    end

    -- ไม่เช็ค CanCollide: prop ตกแต่ง (Union) บางชิ้นตั้ง CanCollide=false แต่ยังต้องลบเหมือนกัน
    local function ClearObstaclesIn(Container)
        for _, Descendant in ipairs(Container:GetDescendants()) do
            if Descendant:IsA("BasePart") then
                if not IsFloorLike(Descendant) and not IsProtected(Descendant) then
                    RememberWall(Descendant)
                    pcall(function() Descendant:Destroy() end)
                end
            end
        end
    end

    local function ClearAllObstacles()
        local Dungeon = workspace:FindFirstChild("dungeon")

        -- ดันเจี้ยนคนละอันแล้ว (ด่านใหม่) กำแพงที่จำไว้ใช้ไม่ได้ ทิ้งของเก่า
        if Dungeon and RecordedDungeon ~= Dungeon then
            RecordedDungeon = Dungeon
            table.clear(RemovedWalls)
        end

        for _, Name in ipairs(ObstacleContainers) do
            local Container = workspace:FindFirstChild(Name)
            if Container then ClearObstaclesIn(Container) end
        end
    end

    -- ห้องถัด ๆ ไปโหลดเข้ามาทีหลังตอนเดินไปถึง เลยต้องกวาดซ้ำตอนมันโผล่
    do
        ClearAllObstacles()

        for _, Name in ipairs(ObstacleContainers) do
            local Container = workspace:FindFirstChild(Name)

            if Container then
                TrackConnection(Container.DescendantAdded:Connect(function(Descendant)
                    if not Descendant:IsA("BasePart") then return end

                    task.defer(function()
                        if Descendant.Parent then
                            if not IsFloorLike(Descendant) and not IsProtected(Descendant) then
                                RememberWall(Descendant)
                                pcall(function() Descendant:Destroy() end)
                            end
                        end
                    end)
                end))
            end
        end
    end

    -- กำแพงกันตกถูกลบไปด้วย เลยต้องเช็คเองว่าที่จะถอยไปยังมีพื้นรองอยู่ไหม ไม่งั้นถอยตกแมพ
    local GroundParams = RaycastParams.new()
    GroundParams.FilterType = Enum.RaycastFilterType.Exclude

    local function GroundAt(Position)
        local Character = LocalPlayer.Character
        GroundParams.FilterDescendantsInstances = Character and { Character } or { }

        local Hit = workspace:Raycast(Position + Vector3.new(0, 4, 0), Vector3.new(0, -30, 0), GroundParams)

        return Hit and Hit.Instance or nil
    end

    local function HasGroundAt(Position)
        return GroundAt(Position) ~= nil
    end

    -- ประกาศล่วงหน้า ตัวจริงอยู่ท้าย (ต้องรอ RaycastParams ของชั้นเดินก่อน)
    local SegmentClear

    --// ของอันตรายของศัตรู
    --
    -- เกมโคลนของอันตรายไปวางใน workspace โดยใช้ชื่อเดิมจาก ReplicatedStorage.enemyProjectiles
    -- เลยเทียบชื่อตรง ๆ ได้ ครอบคลุมทั้งของที่พุ่งและ AOE นิ่งบนพื้น
    local HazardNames = { }

    do
        local Templates = ReplicatedStorage:FindFirstChild("enemyProjectiles")

        if Templates then
            for _, Template in ipairs(Templates:GetChildren()) do
                HazardNames[Template.Name] = true
            end
        end

        -- พวก marker บอกพื้นที่ปลอดภัย ไม่ใช่ของอันตราย อย่าไปหลบมัน
        HazardNames["cyanSafeZoneMarker"] = nil
        HazardNames["purpleSafeZoneMarker"] = nil
    end

    -- ไล่สแกน workspace ทั้งก้อนทุก tick แพงเกินไป (ดันเจี้ยนมีหลายพันชิ้น) เลยดักเอาตอนมันถูกสร้าง
    -- กับตอนถูกลบแทน แล้วเก็บเป็นรายการสั้น ๆ ไว้ให้ลูปเดินอ่าน
    local ActiveHazards = { }

    local function TrackHazard(Instance)
        if not HazardNames[Instance.Name] then return end
        if not (Instance:IsA("BasePart") or Instance:IsA("Model")) then return end

        ActiveHazards[Instance] = true
    end

    for _, Descendant in ipairs(workspace:GetDescendants()) do
        TrackHazard(Descendant)
    end

    TrackConnection(workspace.DescendantAdded:Connect(TrackHazard))

    TrackConnection(workspace.DescendantRemoving:Connect(function(Instance)
        ActiveHazards[Instance] = nil
    end))

    --// รูปทรงของอันตราย
    --
    -- สกิลเส้นของบอสเป็น Model ที่มี Model ย่อยเส้นละอันข้างใน วางขนานเว้นช่องให้ยืนหลบ
    -- คิดทั้งก้อนด้วย GetExtentsSize() จะยุบเป็นวงกลมวงเดียว ช่องว่างระหว่างเส้นหายไป เลยต้องแตก
    -- ลงไปคิดทีละเส้นแทน
    local HazardPartsBuffer = { }

    -- สกิลจบแล้วเกมไม่ลบโมเดลทันที แค่ซ่อนด้วย Transparency ก่อน ต้องเช็คด้วยไม่งั้นจะยืนแช่ต่อ
    -- ดูทั้งโมเดล (เคยเห็นแล้วซ่อนหมด = จบ) เพราะ hitBox โปร่งใส 100% อยู่แล้วตลอดเวลา
    -- เช็คทีละชิ้นจะพลาด
    local HazardSeenVisible = setmetatable({ }, { __mode = "k" })

    local function CollectHazardParts()
        table.clear(HazardPartsBuffer)

        for Hazard in pairs(ActiveHazards) do
            if Hazard.Parent then
                local Parts = { }
                local AnyVisible = false

                if Hazard:IsA("BasePart") then
                    table.insert(Parts, Hazard)
                    if Hazard.Transparency < 0.95 then AnyVisible = true end
                else
                    for _, Descendant in ipairs(Hazard:GetDescendants()) do
                        if Descendant:IsA("BasePart") then
                            table.insert(Parts, Descendant)
                            if Descendant.Transparency < 0.95 then AnyVisible = true end
                        end
                    end
                end

                if AnyVisible then HazardSeenVisible[Hazard] = true end

                -- เคยเห็นมาก่อนแต่ตอนนี้ซ่อนหมด = จบแล้ว ข้ามไปได้เลย
                local Finished = HazardSeenVisible[Hazard] and not AnyVisible

                if not Finished then
                    for _, Part in ipairs(Parts) do
                        table.insert(HazardPartsBuffer, Part)
                    end
                end
            else
                ActiveHazards[Hazard] = nil
                HazardSeenVisible[Hazard] = nil
            end
        end

        return HazardPartsBuffer
    end

    -- เส้นแคบ (กว้าง 2 studs) เผื่อระยะเท่าของกลมจะทำให้ช่องระหว่างเส้นหายหมด เลยใช้ padding แคบกว่า
    local LinePadding = 2

    -- จุดที่เลือกยืนต้องเหลือเผื่อเกินนี้ ไม่ใช่แค่ "พ้นเส้น" เฉียดฉิว กันคลาดเคลื่อนตอนหยุดเดิน
    local LineSafeMargin = 2

    -- จุดบนชิ้นนั้นที่ใกล้ Origin ที่สุด + รัศมีเลี่ยง + เป็นเส้นหรือไม่
    --   เส้น (ยาว/บาง) = แคปซูล ผลักตั้งฉากออกจากเส้น ยืนข้าง ๆ หรือในช่องระหว่างเส้นได้
    --   ก้อนกลม = วงกลมรอบจุดศูนย์กลางตามเดิม
    local function PartBounds(Part, Origin)
        local Size = Part.Size
        local Long = math.max(Size.X, Size.Z)
        local Short = math.min(Size.X, Size.Z)

        if Long > 12 and Long / math.max(Short, 0.1) > 3 then
            local HalfLong = Long * 0.5
            local LocalAxis = (Size.X >= Size.Z) and Vector3.new(HalfLong, 0, 0) or Vector3.new(0, 0, HalfLong)

            local A = Flat((Part.CFrame * CFrame.new(-LocalAxis)).Position)
            local B = Flat((Part.CFrame * CFrame.new(LocalAxis)).Position)

            local AB = B - A
            local Denom = AB:Dot(AB)
            local T = (Denom > 0.001) and math.clamp((Flat(Origin) - A):Dot(AB) / Denom, 0, 1) or 0

            return A + AB * T, Short * 0.5, true
        end

        return Part.Position, Long * 0.5, false
    end

    -- potential field เดียวกับ SteerPastTraps ใน STE.lua: ของอันตรายทุกชิ้นที่อยู่ในระยะดันทิศทางเดิน
    -- ออกจากตัวมัน แรงขึ้นตามความใกล้ แล้วบวกรวมกับทิศที่ตั้งใจจะไปก่อนขยับจริง
    local function SteerAwayFromHazards(Origin, Direction)
        local Push = Vector3.zero

        for _, Part in ipairs(CollectHazardParts()) do
            local Position, Radius, IsLine = PartBounds(Part, Origin)
            local Avoid = Radius + (IsLine and LinePadding or HazardPadding)
            local Offset = Flat(Origin - Position)
            local Distance = Offset.Magnitude

            if Distance < Avoid then
                local Away

                if Distance > 0.1 then
                    Away = Offset / Distance
                else
                    -- ยืนทับเส้น/กลางวงพอดี: ออกด้านข้างดีกว่าอยู่เฉย ๆ
                    Away = Vector3.new(-Direction.Z, 0, Direction.X)
                end

                Push = Push + Away * ((Avoid - Distance) / Avoid)
            end
        end

        if Push.Magnitude < 0.01 then return Direction, false end

        -- หลบมาก่อน เป้าหมายค่อยว่ากัน: คูณแรงผลักให้ชนะทิศเดิมตอนของอันตรายจ่อตัว
        local Steered = Vector3.new(Direction.X + Push.X * 2.2, 0, Direction.Z + Push.Z * 2.2)

        if Steered.Magnitude < 0.01 then
            return Vector3.new(-Direction.Z, 0, Direction.X), true
        end

        return Steered.Unit, true
    end

    --// ล็อกหน้าใส่ม็อบ
    --
    -- เขียน Root.CFrame ทุกเฟรมโดยตรงจะไปรีเซ็ตตัวควบคุมการเดินของ Humanoid ทำให้เดินไม่ออก
    -- ใช้ AlignOrientation ออกแรงบิดผ่านฟิสิกส์แทน ล็อกหน้าได้โดยไม่กวนการเดิน
    local Aligner, AlignAttachment

    local function EnsureAligner(Root)
        if AlignAttachment and AlignAttachment.Parent ~= Root then
            AlignAttachment:Destroy()
            if Aligner then Aligner:Destroy() end
            AlignAttachment, Aligner = nil, nil
        end

        if not AlignAttachment then
            AlignAttachment = Instance.new("Attachment")
            AlignAttachment.Name = "ValkyrieAim"
            AlignAttachment.Parent = Root

            Aligner = Instance.new("AlignOrientation")
            Aligner.Name = "ValkyrieAimOrientation"
            Aligner.Mode = Enum.OrientationAlignmentMode.OneAttachment
            Aligner.Attachment0 = AlignAttachment
            Aligner.RigidityEnabled = true
            Aligner.Enabled = false
            Aligner.Parent = Root
        end

        return Aligner
    end

    local function ReleaseLock()
        if Aligner then Aligner.Enabled = false end

        local Character = LocalPlayer.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

        if Humanoid then Humanoid.AutoRotate = true end
    end

    -- ล็อกหน้าใส่เป้า ถ้าไม่มีเป้าก็ปลดล็อกคืนให้หมุนตามทางเดินเอง
    local function UpdateAimLock()
        local Character, Humanoid, Root = GetCharacter()

        if not Character then return end

        local Target = Farm.Target

        if not (Farm.Active and Target and Target.Parent) then
            ReleaseLock()
            return
        end

        local Look = Flat(Target.Position - Root.Position)
        if Look.Magnitude < 0.01 then return end

        -- ปิด AutoRotate ไม่งั้นมันหมุนตามทางที่เดิน ซึ่งตอนถอยหนีคือหันหลังให้ม็อบ
        if Humanoid.AutoRotate then Humanoid.AutoRotate = false end

        local Lock = EnsureAligner(Root)
        Lock.CFrame = CFrame.lookAt(Vector3.zero, Look.Unit)
        Lock.Enabled = true
    end

    --// สกิล
    --
    -- cooldown.Value มักไม่จบที่ 0 เป๊ะ ๆ ค้างเป็นเศษ float เล็กน้อย เทียบ <= 0 ตรง ๆ จะไม่ยิงซ้ำ
    local CooldownEpsilon = 0.05

    local WatchedTools = setmetatable({}, { __mode = "k" })

    local function TryFireTool(Tool)
        if not Farm.Active or not Farm.InRange then return end
        if not Tool.Parent then return end

        local Character = LocalPlayer.Character
        if not Character then return end

        -- ยิงตอน busyCasting ยัง true (คาถาก่อนหน้ายังเล่นแอนิเมชันไม่จบ) เกมเมินเงียบ ๆ ไม่แคสต์ให้
        local BusyCasting = Character:FindFirstChild("busyCasting")
        if BusyCasting and BusyCasting.Value == true then return end

        -- ตายกลางคาถา/กำลัง respawn แล้วยิงเข้าไป LocalScript ของไม้จะพัง เช็คก่อน
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid or Humanoid.Health <= 0 then return end
        if not Character:FindFirstChild("HumanoidRootPart") then return end

        local Cooldown = Tool:FindFirstChild("cooldown")

        if not Cooldown or Cooldown.Value <= CooldownEpsilon then
            pcall(UpdateAimLock)
            pcall(function() Tool.localEvent:Fire() end)
        end
    end

    -- ไม่เก็บรายชื่อไม้ไว้ล่วงหน้า เพราะ Backpack ถูกสร้างใหม่ทุกครั้งที่ตัวละครเกิดใหม่ ไล่หาสดทุกครั้งแทน
    local function ForEachAbilityTool(Callback)
        local Character = LocalPlayer.Character

        for _, Container in ipairs({ LocalPlayer:FindFirstChild("Backpack"), Character }) do
            if Container then
                for _, Tool in ipairs(Container:GetChildren()) do
                    if Tool:IsA("Tool") and Tool:FindFirstChild("localEvent") then
                        Callback(Tool)
                    end
                end
            end
        end
    end

    -- ดักค่า cooldown ของไม้ที่เจอไว้ด้วย เพื่อให้ยิงทันทีที่คูลดาวน์หมดโดยไม่ต้องรอ tick ถัดไป
    local function WatchTool(Tool)
        if WatchedTools[Tool] then return end
        WatchedTools[Tool] = true

        local Cooldown = Tool:FindFirstChild("cooldown")

        if Cooldown then
            TrackConnection(Cooldown:GetPropertyChangedSignal("Value"):Connect(function()
                TryFireTool(Tool)
            end))
        end
    end

    local function TryFireAllWatched()
        ForEachAbilityTool(function(Tool)
            WatchTool(Tool)
            TryFireTool(Tool)
        end)
    end

    --// ความเร็วเดิน
    local function ApplyWalkSpeed()
        local Character = LocalPlayer.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

        if Humanoid and Humanoid.Health > 0 then
            Humanoid.WalkSpeed = tonumber(getgenv().ConfigurationTable.WalkSpeed) or 16
        end
    end

    TrackConnection(LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        ApplyWalkSpeed()
    end))

    --// เป้าหมาย
    --
    -- ม็อบจริงอยู่ใน workspace.dungeon.<roomN>.enemyFolder แยกตามห้อง กับ workspace.bossLobbies
    -- ตอนสู้บอส (workspace.enemies ว่างเปล่าตลอด)
    local function NearestEnemy(FromPosition)
        local Best, BestDistance = nil, math.huge
        local Roots = { }

        local function Scan(Container)
            if not Container then return end

            for _, Descendant in ipairs(Container:GetDescendants()) do
                if Descendant:IsA("Humanoid") and Descendant.Health > 0 then
                    local Enemy = Descendant.Parent

                    if Enemy and not Players:GetPlayerFromCharacter(Enemy) then
                        local Root = Enemy:FindFirstChild("HumanoidRootPart") or Enemy.PrimaryPart

                        if Root then
                            table.insert(Roots, Root)

                            local Distance = Flat(Root.Position - FromPosition).Magnitude

                            if Distance < BestDistance then
                                Best, BestDistance = Root, Distance
                            end
                        end
                    end
                end
            end
        end

        Scan(workspace:FindFirstChild("dungeon"))
        Scan(workspace:FindFirstChild("bossLobbies"))
        Scan(workspace:FindFirstChild("enemies"))

        return Best, BestDistance, Roots
    end

    --// กันโดนม็อบตีตอนขยับ
    --
    -- กันระยะจากเป้าที่ล็อกอยู่ตัวเดียวไม่พอ ม็อบตัวอื่นเดินมาประชิดข้าง ๆ ได้ -- ผลักออกจากม็อบทุกตัว
    local MobClearance = 14 -- ใกล้กว่านี้ = เข้าระยะที่มันฟันถึง ต้องถูกผลักออก

    local function SteerAwayFromMobs(Origin, Direction, Enemies)
        local Push = Vector3.zero

        for _, EnemyRoot in ipairs(Enemies) do
            local Offset = Flat(Origin - EnemyRoot.Position)
            local Distance = Offset.Magnitude

            if Distance < MobClearance and Distance > 0.1 then
                Push = Push + (Offset / Distance) * ((MobClearance - Distance) / MobClearance)
            end
        end

        if Push.Magnitude < 0.01 then return Direction end

        local Steered = Vector3.new(Direction.X + Push.X * 1.8, 0, Direction.Z + Push.Z * 1.8)
        if Steered.Magnitude < 0.01 then return Push.Unit end

        return Steered.Unit
    end

    --// หลบสกิล: ไปยืนจุดปลอดภัย แล้วหยุดรอจนของนั้นหายไป
    --
    -- ใช้สนามผลักล้วน ๆ จะไถลไปเรื่อยไม่มีจุดหมาย เสี่ยงไถลเข้าเส้นอื่นหรือกองม็อบอื่น
    -- เปลี่ยนเป็นเล็งจุดปลอดภัยไว้ก่อน เดินไปให้ถึง แล้วยืนนิ่งรอ (ยิงต่อได้ระหว่างรอ)
    -- หยุดแช่เฉพาะสกิลเส้นเท่านั้น ของที่พุ่งเป็นลูกใช้สนามผลักหลบตามปกติพอ ไม่งั้นไม่ได้ฟาร์มเลย
    local LineDangerRange = 45 -- เส้นอยู่ในระยะนี้ = เข้าโหมดหาช่องยืน

    -- ระยะเผื่อที่เหลือจากเส้นที่ใกล้จุดนั้นที่สุด ติดลบ = จุดนั้นอยู่บนเส้นแล้ว
    local function LineClearance(Point)
        local Worst = math.huge

        for _, Part in ipairs(CollectHazardParts()) do
            local Position, Radius, IsLine = PartBounds(Part, Point)

            if IsLine then
                local Gap = Flat(Point - Position).Magnitude - (Radius + LinePadding)
                if Gap < Worst then Worst = Gap end
            end
        end

        return Worst
    end

    local function LineThreatNearby(Origin)
        for _, Part in ipairs(CollectHazardParts()) do
            local Position, Radius, IsLine = PartBounds(Part, Origin)

            if IsLine and Flat(Origin - Position).Magnitude < Radius + LineDangerRange then
                return true
            end
        end

        return false
    end

    -- ทิศที่จะก้าวไปต้องไม่พาไปเหยียบเส้น -- กันทิศที่คำนวณมาจากเรื่องอื่น (ไล่ม็อบ/เดินวน) พาเดินเข้าเส้น
    -- ไม่เจอทิศที่พ้นเลยก็ถอยออกจากเส้นที่ใกล้สุด ดีกว่ายืนนิ่งรอโดน
    local LineProbeStep = 10

    local function AwayFromNearestLine(Origin)
        local Best, BestGap = nil, math.huge

        for _, Part in ipairs(CollectHazardParts()) do
            local Position, Radius, IsLine = PartBounds(Part, Origin)

            if IsLine then
                local Offset = Flat(Origin - Position)
                local Gap = Offset.Magnitude - Radius

                if Gap < BestGap and Offset.Magnitude > 0.01 then
                    Best, BestGap = Offset.Unit, Gap
                end
            end
        end

        return Best
    end

    local function AvoidLineDirection(Origin, Direction)
        if Direction.Magnitude < 0.01 then return Direction end

        for _, Degrees in ipairs({ 0, 30, -30, 60, -60, 90, -90, 130, -130 }) do
            local Turned = (Degrees == 0) and Direction
                or (CFrame.Angles(0, math.rad(Degrees), 0) * Direction)

            if LineClearance(Origin + Turned.Unit * LineProbeStep) > LineSafeMargin then
                return Turned.Unit
            end
        end

        return AwayFromNearestLine(Origin) or Direction
    end

    -- กวาดหาช่องยืนรอบตัว (16 ทิศ x 5 ระยะ เริ่มจากใกล้ตัว) เลือกจุดที่ไม่โดนเส้นไหนเลย แล้วเดินไปแช่
    local function FindSafeSpot(Root, Enemies)
        local Origin = Root.Position
        local Best, BestScore = nil, -math.huge

        local Candidates = { Origin }

        for _, Radius in ipairs({ 6, 12, 18, 26, 34 }) do
            for Index = 0, 15 do
                local Angle = Index * math.pi / 8
                table.insert(Candidates, Origin + Vector3.new(math.cos(Angle) * Radius, 0, math.sin(Angle) * Radius))
            end
        end

        for _, Point in ipairs(Candidates) do
            local Clearance = LineClearance(Point)

            -- ต้องเดินไปถึงได้จริง จุดที่มีกำแพงคั่นอยู่เอามาใช้ไม่ได้ (กำแพงเป็น Terrain ลบไม่ออก)
            if Clearance > LineSafeMargin and HasGroundAt(Point) and SegmentClear(Origin, Point) then
                -- พ้นเส้นคือผ่าน/ไม่ผ่าน ให้ระยะเดินเป็นตัวตัดสินหลัก ไม่งั้นทิ้งช่องแคบข้าง ๆ
                -- แล้ววิ่งออกไปที่โล่งไกล ๆ แทน
                local Score = -Flat(Point - Origin).Magnitude * 3
                Score = Score + math.min(Clearance, 6) -- เผื่อเกินนิดหน่อยดีกว่าเฉียดขอบเส้น

                for _, EnemyRoot in ipairs(Enemies) do
                    local Gap = Flat(Point - EnemyRoot.Position).Magnitude
                    if Gap < MobClearance then
                        Score = Score - (MobClearance - Gap) * 4
                    end
                end

                if Score > BestScore then
                    Best, BestScore = Point, Score
                end
            end
        end

        return Best
    end

    --// ลากม็อบให้ครบทุกกลุ่มก่อนค่อยปิดทีเดียว
    --
    -- ม็อบที่ยังไม่ถูกปลุกจะยืนนิ่งสนิทอยู่จุดเกิด ดูจากความเร็วจริงว่าตื่นแล้วหรือยัง
    -- ลำดับ: เดินไปปลุกกลุ่มที่ยังหลับให้ครบ (ยังไม่ยิง) -> รอทุกตัวตามมารวม -> ยิงรวดเดียว
    local GroupLinkRange = 30  -- ม็อบห่างกันไม่เกินนี้ นับเป็นกลุ่มเดียวกัน
    local AggroRange = 30      -- เข้าใกล้เท่านี้ = ปลุกกลุ่มนั้นแล้ว
    local RallyTimeout = 25    -- ลากนานเกินนี้ยังไม่ครบ ก็ไม่รอแล้ว ยิงเลย

    -- ลากแค่กลุ่มที่อยู่ใกล้ ๆ พอ 1-2 กลุ่ม เดินไล่ปลุกทั้งห้องเสียเวลากว่าที่ได้กลับมามาก
    local RallyScanRange = 60  -- กลุ่มที่ไกลกว่านี้ ไม่ต้องไปลาก ปิดที่มีอยู่ก่อนแล้วค่อยเดินไปเก็บ
    local MaxRallyGroups = 2   -- ตื่นครบเท่านี้แล้วหยุดลาก จัดการที่มีอยู่เลย

    -- กลุ่มคนละห้องลากมาไม่ได้ (เดินมาติดกำแพง) -- เรย์เช็คใช้ไม่ได้เพราะกำแพงถูกลบไปแล้ว
    -- ใช้สังกัดห้องแทน: ม็อบอยู่ workspace.dungeon.<roomN>.enemyFolder ไหน เทียบกับห้องที่เรายืน
    local function RoomOf(Instance)
        local Dungeon = workspace:FindFirstChild("dungeon")
        if not Dungeon then return nil end

        local Current = Instance

        while Current and Current.Parent do
            if Current.Parent == Dungeon then return Current end
            Current = Current.Parent
        end

        return nil
    end

    local function CurrentRoom()
        local Character = LocalPlayer.Character
        local Root = Character and Character:FindFirstChild("HumanoidRootPart")
        if not Root then return nil end

        local Floor = GroundAt(Root.Position)
        if not Floor then return nil end

        return RoomOf(Floor)
    end

    -- เส้นตรงจากเราไปหาม็อบ ตัดผ่านกล่องกำแพงที่จำไว้ไหม (slab test ในพิกัดโลคอลของกล่อง)
    local function SegmentHitsBox(From, To, Box)
        local Start = Box.CFrame:PointToObjectSpace(From)
        local Finish = Box.CFrame:PointToObjectSpace(To)
        local Delta = Finish - Start

        local TMin, TMax = 0, 1

        for _, Axis in ipairs({ "X", "Y", "Z" }) do
            local Origin = Start[Axis]
            local Step = Delta[Axis]
            local Limit = Box.Half[Axis]

            if math.abs(Step) < 1e-6 then
                if Origin < -Limit or Origin > Limit then return false end
            else
                local T1 = (-Limit - Origin) / Step
                local T2 = (Limit - Origin) / Step

                if T1 > T2 then T1, T2 = T2, T1 end
                if T1 > TMin then TMin = T1 end
                if T2 < TMax then TMax = T2 end
                if TMin > TMax then return false end
            end
        end

        return true
    end

    -- มีกำแพงคั่นระหว่างเรากับม็อบตัวนั้นไหม เช็คจากกล่องกำแพงที่จำไว้ก่อนลบ
    local function WallBetween(Root, TargetPosition)
        local From = Root.Position + Vector3.new(0, 2, 0)
        local To = Vector3.new(TargetPosition.X, TargetPosition.Y + 2, TargetPosition.Z)

        for _, Box in ipairs(RemovedWalls) do
            if SegmentHitsBox(From, To, Box) then return true end
        end

        return false
    end

    -- คืนม็อบของกลุ่มที่ยัง "หลับ" และอยู่ใกล้ที่สุด -- ไม่มีแล้ว = ปลุกครบทุกกลุ่ม
    -- ระยะใกล้สุดจากจุด P ถึงเส้นตรง A-B (แนวราบ)
    local function DistanceToSegment(A, B, P)
        local AB = Flat(B - A)
        local AP = Flat(P - A)
        local Length = AB:Dot(AB)

        if Length < 1e-6 then return AP.Magnitude end

        local T = math.clamp(AP:Dot(AB) / Length, 0, 1)
        return (AP - AB * T).Magnitude
    end

    -- ทางเดินไปกลุ่มนั้นต้องไม่เฉียดม็อบตัวอื่น ไม่งั้นเดินผ่านแล้วโดนตีระหว่างทาง
    -- เผื่อเกินระยะฟันไว้ เพราะม็อบที่ตื่นแล้วเดินเข้าหาเส้นทางระหว่างเราเดินอยู่
    local RallyPassClearance = MobClearance + 6

    local function RouteHitsOtherMobs(Root, Destination, Group, Enemies)
        local InGroup = { }
        for _, Member in ipairs(Group) do InGroup[Member] = true end

        for _, EnemyRoot in ipairs(Enemies) do
            if not InGroup[EnemyRoot]
                and DistanceToSegment(Root.Position, Destination, EnemyRoot.Position) < RallyPassClearance then
                return true
            end
        end

        return false
    end

    local function SleepingGroupTarget(Root, Enemies)
        local MyRoom = CurrentRoom()
        local Groups = { }

        for _, EnemyRoot in ipairs(Enemies) do
            local Placed = false

            for _, Group in ipairs(Groups) do
                for _, Member in ipairs(Group) do
                    if Flat(EnemyRoot.Position - Member.Position).Magnitude <= GroupLinkRange then
                        table.insert(Group, EnemyRoot)
                        Placed = true
                        break
                    end
                end

                if Placed then break end
            end

            if not Placed then
                table.insert(Groups, { EnemyRoot })
            end
        end

        local Best, BestDistance = nil, math.huge
        local AwakeGroups = 0

        for _, Group in ipairs(Groups) do
            local Awake = false
            local Nearest, NearestDistance = nil, math.huge

            for _, EnemyRoot in ipairs(Group) do
                local Distance = Flat(EnemyRoot.Position - Root.Position).Magnitude

                -- ขยับอยู่ = ตื่นแล้วกำลังตามมา / อยู่ใกล้มากก็ถือว่าตื่นแน่นอน
                if EnemyRoot.AssemblyLinearVelocity.Magnitude > 1 or Distance < AggroRange then
                    Awake = true
                end

                if Distance < NearestDistance then
                    Nearest, NearestDistance = EnemyRoot, Distance
                end
            end

            if Awake then
                AwakeGroups = AwakeGroups + 1
            end

            -- คนละห้องหรือมีกำแพงคั่น = ลากมาไม่ได้ ข้ามไปก่อน เก็บทีหลังตอนเดินเข้าไปถึงฝั่งนั้น
            if not Awake and NearestDistance < RallyScanRange and NearestDistance < BestDistance then
                local SameRoom = (not MyRoom) or RoomOf(Nearest) == MyRoom

                -- ทางไปต้องไม่ผ่านม็อบกลุ่มอื่น -- ผ่านไม่ได้ก็ปล่อยให้สาขาสู้ปกติจัดการตัวที่ใกล้สุดก่อน
                if SameRoom and not WallBetween(Root, Nearest.Position)
                    and not RouteHitsOtherMobs(Root, Nearest.Position, Group, Enemies) then
                    Best, BestDistance = Nearest, NearestDistance
                end
            end
        end

        -- ตื่นครบโควตาแล้ว หยุดลาก จัดการที่มีอยู่ก่อน
        if AwakeGroups >= MaxRallyGroups then
            return nil
        end

        return Best, BestDistance
    end

    -- ComputeAsync ยิลด์นาน (~100ms) เรียกตรงในลูปเดินจะทำให้เดินสะดุด เลยโยนไป thread แยก
    -- มี Busy กันซ้อน ลูปเดินอ่านผลลัพธ์ที่คิดเสร็จแล้วอย่างเดียว ไม่รอ
    local PathBusy = false

    local function RequestPath(Root, TargetPosition)
        if PathBusy then return end

        local Now = os.clock()
        if Farm.Waypoints and Now - Farm.PathAt < PathRefresh then return end

        PathBusy = true
        Farm.PathAt = Now

        local Origin = Root.Position

        task.spawn(function()
            local Path = PathfindingService:CreatePath({
                AgentRadius = 2.5,
                AgentHeight = 5,
                AgentCanJump = true,
                WaypointSpacing = 4,
            })

            local Ok = pcall(function()
                Path:ComputeAsync(Origin, TargetPosition)
            end)

            if Ok and Path.Status == Enum.PathStatus.Success then
                Farm.Waypoints = Path:GetWaypoints()
                Farm.WaypointIndex = 2 -- index 1 คือจุดยืนปัจจุบัน ข้ามไปเลย
            else
                Farm.Waypoints = nil
            end

            PathBusy = false
        end)
    end

    --// สั่งเดิน
    --
    -- แยกเป็นสองชั้น: ลูปหนัก 10Hz แค่ "ตัดสินใจ" ทิศ (เก็บใน Farm.MoveDirection) ส่วน MoveTo
    -- สั่งทุกเฟรม ไม่งั้น humanoid เดินถึงเป้าแล้วหยุดรอ tick ถัดไป -- เป้าต้องวางไกลพอ (16 studs)
    -- ด้วย ไม่งั้นเดินถึงก่อนได้คำสั่งใหม่ก็หยุดกึกอีก
    local StepAhead = 16

    -- หมุนทิศทีละนิดแทนการพลิกทันที กันอาการกระตุกตอนสลับข้างวน/สลับเป้า
    local function BlendDirection(Current, Desired, Alpha)
        if not Current or Current.Magnitude < 0.01 then return Desired end
        if Desired.Magnitude < 0.01 then return Desired end

        local Mixed = Current * (1 - Alpha) + Desired * Alpha
        if Mixed.Magnitude < 0.01 then return Desired end

        return Mixed.Unit
    end

    local function RotateY(Direction, Degrees)
        local Angle = math.rad(Degrees)
        local Cos, Sin = math.cos(Angle), math.sin(Angle)

        return Vector3.new(
            Direction.X * Cos - Direction.Z * Sin,
            0,
            Direction.X * Sin + Direction.Z * Cos
        )
    end

    --// ข้างหน้าตันไหม
    --
    -- กำแพงห้องเป็น Terrain ลบไม่ได้ (Destroy ใช้ได้แต่กับ BasePart) เลยต้องเช็คเอาก่อนก้าว
    -- ไม่งั้นเดินอัดกำแพงค้าง เช็คสองระดับ: เข่ากับอก กันพลาดทั้งขอบเตี้ยและกำแพงลอย
    local BlockProbe = 7
    local BlockParams = RaycastParams.new()
    BlockParams.FilterType = Enum.RaycastFilterType.Exclude

    -- ม็อบก็บังเรย์เหมือนกัน แต่เดินชนม็อบได้ ไม่นับว่าตัน
    local function IsCreature(Instance)
        local Model = Instance and Instance:FindFirstAncestorOfClass("Model")

        while Model do
            if Model:FindFirstChildOfClass("Humanoid") then return true end
            Model = Model:FindFirstAncestorOfClass("Model")
        end

        return false
    end

    -- เส้นตรงจากจุดหนึ่งไปอีกจุด มีของขวางไหม (ม็อบไม่นับ เดี๋ยวมันก็ขยับ)
    function SegmentClear(From, To)
        local Character = LocalPlayer.Character
        BlockParams.FilterDescendantsInstances = Character and { Character } or { }

        local Delta = Vector3.new(To.X - From.X, 0, To.Z - From.Z)
        if Delta.Magnitude < 0.5 then return true end

        local Origin = Vector3.new(From.X, From.Y + 2, From.Z)
        local Hit = workspace:Raycast(Origin, Delta, BlockParams)

        return not Hit or IsCreature(Hit.Instance)
    end

    local function PathBlocked(Origin, Direction)
        local Character = LocalPlayer.Character
        BlockParams.FilterDescendantsInstances = Character and { Character } or { }

        local Step = Direction.Unit * BlockProbe

        for _, Height in ipairs({ 1, 3 }) do
            local Hit = workspace:Raycast(Origin + Vector3.new(0, Height, 0), Step, BlockParams)
            if Hit and not IsCreature(Hit.Instance) then return true end
        end

        return false
    end

    -- ข้างหน้าไม่มีพื้นรอง (กำแพงกันตกโดนลบไปแล้ว) หรือมีของขวางอยู่ ให้กวาดหาทิศข้าง ๆ แทนหยุดกึก
    -- ทิศที่เบนไปน้อยสุดชนะ เลยได้อาการ "ไถลไปตามกำแพง" แทนที่จะอัดค้างหรือเด้งกลับ
    local function SafeDirection(Root, Direction)
        if Direction.Magnitude < 0.01 then return nil end

        Direction = Direction.Unit

        local Origin = Root.Position
        local Angles = { 25, -25, 50, -50, 80, -80, 110, -110, 140, -140 }

        if HasGroundAt(Origin + Direction * StepAhead) and not PathBlocked(Origin, Direction) then
            return Direction
        end

        for _, Degrees in ipairs(Angles) do
            local Rotated = RotateY(Direction, Degrees)

            if HasGroundAt(Origin + Rotated * StepAhead) and not PathBlocked(Origin, Rotated) then
                return Rotated
            end
        end

        -- ตันทุกทิศ (มุมอับ) เอาทิศที่ยังมีพื้นรองไว้ก่อน ดันไปเรื่อย ๆ ดีกว่ายืนแช่ให้โดนตี
        for _, Degrees in ipairs(Angles) do
            local Rotated = RotateY(Direction, Degrees)
            if HasGroundAt(Origin + Rotated * StepAhead) then return Rotated end
        end

        return nil
    end

    local function StepTowards(Humanoid, Root, Direction)
        local Safe = SafeDirection(Root, Direction)

        if not Safe then
            Humanoid:MoveTo(Root.Position)
            return
        end

        Humanoid:MoveTo(Root.Position + Safe * StepAhead)
    end

    --// จุดยืนยิง แทนการเดินวนรอบเป้า
    --
    -- เดินวนใช้ทิศสัมผัสวงกลม ซึ่งไม่รู้จักกำแพงเลย ห้องที่มีผนัง (เป็น Terrain ลบไม่ได้) ก็วนไปอัดผนัง
    -- แล้วพอโดนเบนก็ส่ายซ้ายขวาไม่จบ เปลี่ยนเป็นเลือก "จุดยืน" ที่คัดแล้วว่ามีพื้น เดินถึงได้ ไม่ติดผนัง
    -- ระยะยิงพอดี ห่างม็อบ แล้วย้ายไปยืนนิ่งยิง -- ย้ายใหม่เฉพาะตอนจุดเดิมใช้ไม่ได้แล้ว
    local StandIdeal = (StandoffMin + StandoffMax) * 0.5
    local StandArrive = 3     -- ใกล้จุดเท่านี้ = ถึงแล้ว ยืนยิงได้
    local StandHold = 0.5     -- กันเปลี่ยนจุดรัว ๆ จนเดินไม่ถึงสักจุด
    local StandOpenProbe = 12 -- ระยะทดสอบว่ารอบจุดนั้นโล่งแค่ไหน

    -- ผูกจุดยืนไว้กับกลางกองม็อบ ไม่งั้นเลือกจุดใหม่ห่างออกไปทีละนิด ม็อบตามมา เลือกถอยอีก
    -- สะสมจนหนีข้ามห้อง จุดที่ไกลกลางกองเกินนี้ตัดทิ้ง
    local StandLeash = StandoffMax + 4
    local PackRadius = 45 -- ห่างจากเป้าเกินนี้ = คนละกอง

    local function PackCenter(EnemyRoot, Enemies)
        local Sum, Count = Vector3.zero, 0

        for _, Other in ipairs(Enemies) do
            if Flat(Other.Position - EnemyRoot.Position).Magnitude <= PackRadius then
                Sum = Sum + Other.Position
                Count = Count + 1
            end
        end

        if Count == 0 then return EnemyRoot.Position end
        return Sum / Count
    end

    local function SpotScore(Point, Origin, EnemyRoot, Enemies, Center)
        -- เช็คที่ไม่ต้องยิงเรย์ก่อน ตัดจุดส่วนใหญ่ทิ้งได้ถูก ๆ
        local ToCenter = Flat(Point - Center).Magnitude
        if ToCenter > StandLeash then return nil end

        local ToEnemy = Flat(Point - EnemyRoot.Position).Magnitude
        if ToEnemy < StandoffMin - 4 or ToEnemy > StandoffMax then return nil end

        -- เดินไปจุดนั้นต้องไม่ตัดผ่านกลางกอง ไปอีกฝั่งต้องอ้อมเป็นทอด ๆ แทน
        -- ตัวที่ประชิดเราอยู่แล้วไม่นับ ไม่งั้นหนีออกไม่ได้เลย
        for _, Other in ipairs(Enemies) do
            if Flat(Origin - Other.Position).Magnitude > MobClearance
                and DistanceToSegment(Origin, Point, Other.Position) < MobClearance * 0.6 then
                return nil
            end
        end

        local Clearance = LineClearance(Point)
        if Clearance <= LineSafeMargin then return nil end

        if not HasGroundAt(Point) then return nil end
        if not SegmentClear(Origin, Point) then return nil end

        local Score = -math.abs(ToEnemy - StandIdeal) * 3

        -- ยิ่งมีทางออกรอบตัวมาก ยิ่งดี -- จุดที่ซุกมุมผนังขยับต่อไม่ได้ พอม็อบมาประชิดก็จนมุม
        for Index = 0, 3 do
            local Angle = Index * math.pi / 2
            local Direction = Vector3.new(math.cos(Angle), 0, math.sin(Angle))

            if SegmentClear(Point, Point + Direction * StandOpenProbe) then
                Score = Score + 6
            end
        end

        for _, OtherRoot in ipairs(Enemies) do
            local Gap = Flat(Point - OtherRoot.Position).Magnitude
            if Gap < MobClearance then
                Score = Score - (MobClearance - Gap) * 5
            end
        end

        Score = Score + math.min(Clearance, 8)
        Score = Score - Flat(Point - Origin).Magnitude * 1.2 -- ใกล้ตัวไว้ก่อน ไม่ต้องวิ่งข้ามห้อง

        return Score
    end

    local function PickStandSpot(Root, EnemyRoot, Enemies, Center)
        local Origin = Root.Position
        local Best, BestScore = nil, -math.huge

        local Candidates = { Origin }

        -- จุดขยับเล็กน้อยรอบตัว
        for Index = 0, 7 do
            local Angle = Index * math.pi / 4
            table.insert(Candidates, Origin + Vector3.new(math.cos(Angle) * 8, 0, math.sin(Angle) * 8))
        end

        -- วงรอบกลางกองที่ระยะยิงพอดี -- ย้ายจุดทีไรก็ได้แค่ขยับไปตามวงนี้ ไม่ไหลออกไปไกล
        for _, Radius in ipairs({ StandIdeal - 3, StandIdeal, StandIdeal + 3 }) do
            for Index = 0, 15 do
                local Angle = Index * math.pi / 8
                table.insert(Candidates, Vector3.new(
                    Center.X + math.cos(Angle) * Radius,
                    Origin.Y,
                    Center.Z + math.sin(Angle) * Radius
                ))
            end
        end

        for _, Point in ipairs(Candidates) do
            local Score = SpotScore(Point, Origin, EnemyRoot, Enemies, Center)

            if Score and Score > BestScore then
                Best, BestScore = Point, Score
            end
        end

        return Best
    end

    --// ติดค้าง: สั่งเดินอยู่แต่ตัวไม่ขยับจริง
    --
    -- เช็คทางตันรายทิศยังหลุดมุมอับไม่ได้ทุกกรณี (เช่นซอกที่ทุกทิศมีพื้นแต่เดินออกไม่ได้)
    -- เลยวัดระยะที่ขยับได้จริงเป็นตัวตัดสิน ติดแล้วบังคับเดินขวางสักพัก สลับข้างทุกครั้งเผื่อข้างแรกก็ตัน
    local StuckWindow = 1      -- สั่งเดินครบเท่านี้แล้วยังไม่ขยับ = ติด
    local StuckDistance = 2    -- ขยับได้น้อยกว่านี้ถือว่าไม่ขยับ
    local UnstickTime = 0.8

    local function UpdateStuck(Root)
        local Now = os.clock()
        if Now < Farm.UnstickUntil then return end

        local Position = Root.Position
        local Commanded = Farm.MoveGoal ~= nil
            or (Farm.MoveDirection and Farm.MoveDirection.Magnitude > 0.05)

        -- ไม่ได้สั่งเดิน หรือขยับได้ตามปกติ = ไม่ติด นับใหม่
        if not Commanded or not Farm.StuckFrom
            or Flat(Position - Farm.StuckFrom).Magnitude > StuckDistance then
            Farm.StuckAt, Farm.StuckFrom = Now, Position
            return
        end

        if Now - Farm.StuckAt < StuckWindow then return end

        local Base = (Farm.MoveDirection and Farm.MoveDirection.Magnitude > 0.05)
            and Farm.MoveDirection.Unit or Root.CFrame.LookVector

        local Escape = RotateY(Flat(Base).Unit, Farm.UnstickSign * 90)

        -- ดีดออกข้าง ๆ ต้องไม่ดีดเข้าเส้นสกิลบอส
        if LineThreatNearby(Position) then
            Escape = AvoidLineDirection(Position, Escape)
        end

        Farm.UnstickDirection = Escape
        Farm.UnstickSign = -Farm.UnstickSign
        Farm.UnstickUntil = Now + UnstickTime
        Farm.Waypoints = nil -- เส้นทางเดิมพาไปชน คิดใหม่
        Farm.StuckAt, Farm.StuckFrom = Now, Position
    end

    --// ลูปหนัก (10 ครั้ง/วิ): หาเป้า, คิดเส้นทาง, ตัดสินใจเดิน/ถอย/ยิง
    local function FarmTick()
        local Character, Humanoid, Root = GetCharacter()

        if not Character then
            Farm.InRange = false
            Farm.Target = nil
            Farm.MoveGoal = nil
            return
        end

        UpdateStuck(Root)

        -- เฉพาะสาขาหลบเส้นตั้งค่านี้ เคลียร์ทุก tick ไม่งั้นค้างเดินไปจุดเก่าหลังเส้นหายแล้ว
        Farm.MoveGoal = nil

        -- ด่านยังไม่เริ่ม: ปุ่ม START ในเกม (PlayerGui.startButton) ก็แค่ยิง remote นี้เฉย ๆ
        -- ไม่เช็คระยะห่างเลย เลยไม่ต้องเดินไปหา startPart ก่อน ยิงตรงได้ทันที
        local Started = workspace:FindFirstChild("dungeonStarted")

        if Started and Started.Value == false then
            Farm.InRange = false
            Farm.Target = nil
            Farm.MoveDirection = nil

            local Now = os.clock()
            if Now - Farm.StartPressAt < 2 then return end -- กันยิงซ้ำทุก tick ระหว่างรอเซิร์ฟเวอร์ตอบ
            Farm.StartPressAt = Now

            local Remotes = ReplicatedStorage:FindFirstChild("remotes")
            local StartRemote = Remotes and Remotes:FindFirstChild("changeStartValue")

            if StartRemote then
                pcall(function() StartRemote:FireServer() end)
            end

            return
        end

        local EnemyRoot, Distance, Enemies = NearestEnemy(Root.Position)
        Farm.Target = EnemyRoot

        -- สกิลเส้นของบอสขึ้นในระยะ
        --
        -- ยืนบนเส้น/เฉียดเส้นอยู่ = ฉุกเฉิน ทิ้งงานอื่น ดีดออกไปช่องที่พ้นเส้นก่อน
        -- พ้นเส้นแล้วไม่ต้องแช่รอ ฟาร์มต่อได้เลย แค่กรองทิศเดินไม่ให้ก้าวกลับเข้าเส้น (AvoidLineDirection)
        local LineNear = LineThreatNearby(Root.Position)

        if LineNear and LineClearance(Root.Position) <= LineSafeMargin then
            local Spot = Farm.SafeSpot

            -- ยังไม่มีจุด หรือจุดที่เล็งไว้เริ่มไม่ปลอดภัย (เส้นใหม่พาดมา) -> หาใหม่ก่อนจะโดนจริง
            if not Spot or LineClearance(Spot) <= LineSafeMargin then
                Spot = FindSafeSpot(Root, Enemies)
                Farm.SafeSpot = Spot
            end

            if Spot then
                local ToSpot = Flat(Spot - Root.Position)

                -- เดินไปที่จุดนั้นเป๊ะ ๆ ห้ามใช้ StepAhead (เล็งไกลออกไปตามทิศ) ไม่งั้นเดินเลยจุด
                -- ปลอดภัยไปเหยียบเส้นถัดไป
                Farm.MoveDirection = nil
                Farm.MoveGoal = (ToSpot.Magnitude > 1.5) and Spot or nil

                Farm.InRange = EnemyRoot ~= nil and Distance <= StandoffMax

                if Farm.InRange then
                    TryFireAllWatched()
                end

                return
            end
        else
            Farm.SafeSpot = nil
        end

        if not EnemyRoot then
            Farm.InRange = false
            Farm.Waypoints = nil
            Farm.MoveDirection = nil
            Farm.RallyAt = 0
            Farm.StandSpot = nil

            return
        end

        -- ยังมีกลุ่มที่ยังไม่ตื่นอยู่ในห้อง: เดินไปปลุกให้ครบก่อน ยังไม่ยิง จะได้ปิดทีเดียวตอนรวมกันแล้ว
        local SleepingRoot, SleepingDistance = SleepingGroupTarget(Root, Enemies)

        if SleepingRoot then
            if Farm.RallyAt == 0 then Farm.RallyAt = os.clock() end
        else
            Farm.RallyAt = 0
        end

        -- ม็อบตัวใกล้สุดประชิดอยู่แล้ว เดินไปรวบต่อ = หันหลังให้มันตี ถอยไปจุดยืนยิงก่อน
        local Crowded = Distance < StandoffMin

        if SleepingRoot and not Crowded and os.clock() - Farm.RallyAt < RallyTimeout then
            Farm.InRange = false -- ยังไม่ยิง รวบให้ครบก่อน

            local Desired

            if SleepingDistance > AggroRange - 4 then
                RequestPath(Root, SleepingRoot.Position)

                local TargetPoint = SleepingRoot.Position
                local Waypoints = Farm.Waypoints

                if Waypoints and Waypoints[Farm.WaypointIndex] then
                    local Waypoint = Waypoints[Farm.WaypointIndex]
                    TargetPoint = Waypoint.Position

                    if Flat(Root.Position - Waypoint.Position).Magnitude < 4 then
                        Farm.WaypointIndex = Farm.WaypointIndex + 1
                    end
                end

                local ToPoint = Flat(TargetPoint - Root.Position)
                Desired = (ToPoint.Magnitude > 0.01) and ToPoint.Unit or Vector3.zero
            else
                -- ถึงระยะปลุกแล้ว รอบหน้ามันจะนับเป็นกลุ่มที่ตื่นแล้ว เดินวนกันโดนตีไปพลาง ๆ
                Farm.Waypoints = nil

                local ToGroup = Flat(SleepingRoot.Position - Root.Position)
                local ToGroupDirection = (ToGroup.Magnitude > 0.01) and ToGroup.Unit or Vector3.new(0, 0, 1)

                -- ปลุกแล้ว ถอยออกห่างนิดหน่อยระหว่างรอมันตามมา ไม่ต้องวน
                Desired = -ToGroupDirection
            end

            Desired = SteerAwayFromMobs(Root.Position, Desired, Enemies)

            local Steered = SteerAwayFromHazards(Root.Position, Desired)
            if LineNear then Steered = AvoidLineDirection(Root.Position, Steered) end

            Farm.MoveDirection = BlendDirection(Farm.MoveDirection, Steered, 0.35)

            return
        end

        -- รวบม็อบทั้งกองก่อนค่อยตี: ล่อให้ตัวที่ตามมาแล้วมารวมกันก่อน ค่อยยิงทีเดียว
        -- นับเฉพาะ "กองเดียวกับเป้า" ห้ามนับทั้งห้อง ไม่งั้นรอตัวที่ไม่ aggro ไปตลอดชาติ
        local PullRadius = StandoffMax + 20
        local GatherTimeout = 5        -- รอนานเกินนี้แล้วตัวที่เหลือยังไม่มา ก็ยิงเลย

        local PackGathered = true
        local MyRoom = CurrentRoom()

        for _, EnemyPos in ipairs(Enemies) do
            local FromTarget = Flat(EnemyPos.Position - EnemyRoot.Position).Magnitude

            -- คนละห้อง/มีกำแพงคั่น เดินข้ามมาไม่ได้ อย่าเอามานับ
            local SameRoom = (not MyRoom) or RoomOf(EnemyPos) == MyRoom
            local Reachable = SameRoom and not WallBetween(Root, EnemyPos.Position)

            if Reachable and FromTarget <= PackRadius then
                if Flat(EnemyPos.Position - Root.Position).Magnitude > PullRadius then
                    PackGathered = false
                    break
                end
            end
        end

        local Now = os.clock()

        if PackGathered then
            Farm.GatherAt = 0
        else
            if Farm.GatherAt == 0 then Farm.GatherAt = Now end

            -- ม็อบบางตัวติดมุม/ไม่ยอมมา อย่ารอค้าง
            if Now - Farm.GatherAt > GatherTimeout then
                PackGathered = true
            end
        end

        -- อยู่ในระยะยิงแล้ว ยิงได้ไม่ว่าจะกำลังถอยหรือยืนนิ่ง แต่รอให้รวบกองก่อน
        Farm.InRange = Distance <= StandoffMax and PackGathered

        local ToEnemy = Flat(EnemyRoot.Position - Root.Position)
        local ToEnemyDirection = (ToEnemy.Magnitude > 0.01) and ToEnemy.Unit or Vector3.new(0, 0, 1)

        local Desired

        -- dead zone กันสลับ "เดินเข้า"/"หยุด" ทุก tick ตอนม็อบขยับข้ามเส้นพอดี
        local Approaching = Farm.Approaching
        local EnterRange = Approaching and (StandoffMax - 2) or (StandoffMax + 4)

        if Distance > EnterRange then
            -- ไกลเกินยิงถึง: เดินเข้าไปตามเส้นทางที่คิดไว้ (คิดใน thread แยก ลูปนี้ไม่รอ)
            Farm.Approaching = true
            Farm.StandSpot = nil -- จุดยืนเก่าอยู่คนละที่กับเป้าใหม่แล้ว
            RequestPath(Root, EnemyRoot.Position)

            local TargetPoint = EnemyRoot.Position
            local Waypoints = Farm.Waypoints

            if Waypoints and Waypoints[Farm.WaypointIndex] then
                local Waypoint = Waypoints[Farm.WaypointIndex]
                TargetPoint = Waypoint.Position

                if Flat(Root.Position - Waypoint.Position).Magnitude < 4 then
                    Farm.WaypointIndex = Farm.WaypointIndex + 1
                end
            end

            local ToPoint = Flat(TargetPoint - Root.Position)
            Desired = (ToPoint.Magnitude > 0.01) and ToPoint.Unit or ToEnemyDirection
        else
            -- อยู่ในระยะสู้: ยืนจุดที่คัดไว้แล้วยิง ย้ายจุดใหม่เฉพาะตอนจุดเดิมใช้ไม่ได้
            Farm.Approaching = false
            Farm.Waypoints = nil

            local Now = os.clock()
            local Center = PackCenter(EnemyRoot, Enemies)
            local Spot = Farm.StandSpot
            local Stale = not Spot
                or (Now - Farm.StandAt > StandHold
                    and not SpotScore(Spot, Root.Position, EnemyRoot, Enemies, Center))

            if Stale then
                Spot = PickStandSpot(Root, EnemyRoot, Enemies, Center) or Spot
                Farm.StandSpot = Spot
                Farm.StandAt = Now
            end

            if Spot and Flat(Spot - Root.Position).Magnitude > StandArrive then
                -- เดินไปจุดนั้นเป๊ะ ๆ ไม่ใช้ทิศ+StepAhead ไม่งั้นเลยจุดแล้ววนกลับ
                Farm.MoveDirection = nil
                Farm.MoveGoal = Spot

                if Farm.InRange then TryFireAllWatched() end

                return
            end

            Desired = Vector3.zero
        end

        -- ม็อบตัวอื่นที่เดินมาประชิดข้าง ๆ ระหว่างวน ต้องถูกผลักออกด้วย ไม่ใช่กันแค่เป้าที่ล็อกอยู่
        Desired = SteerAwayFromMobs(Root.Position, Desired, Enemies)

        local Steered = SteerAwayFromHazards(Root.Position, Desired)

        -- มีเส้นอยู่ใกล้: บิดทิศให้ก้าวไปแล้วยังพ้นเส้น ไม่ต้องหยุดเดิน
        if LineNear then Steered = AvoidLineDirection(Root.Position, Steered) end

        -- ค่อย ๆ หมุนทิศแทนการพลิกทันที กันกระตุกตอนสลับข้างวน/สลับเป้า
        Farm.MoveDirection = BlendDirection(Farm.MoveDirection, Steered, 0.35)

        if Farm.InRange then
            TryFireAllWatched()
        end
    end

    FarmSection:Slider({
        Name = "Walk Speed",
        Flag = "DQRWalkSpeed",
        Min = 16,
        Max = 24,
        Default = getgenv().ConfigurationTable.WalkSpeed,
        Callback = function(Value)
            getgenv().ConfigurationTable.WalkSpeed = Value
            SaveConfiguration()
            ApplyWalkSpeed()
        end
    })

    FarmSection:Toggle({
        Name = "Auto Farm",
        Flag = "DQRAutoFarm",
        Default = getgenv().ConfigurationTable.AutoFarm,
        Callback = function(Value)
            getgenv().ConfigurationTable.AutoFarm = Value
            SaveConfiguration()

            Farm.Active = Value

            if Value then
                if Farm.Heartbeat then return end

                Farm.Waypoints = nil
                Farm.PathAt = 0
                Farm.TickAt = 0

                ApplyWalkSpeed()
                ClearAllObstacles()

                -- งานหนัก (หาเป้า/คิดเส้นทาง) จำกัด 10 ครั้ง/วิ ล็อกหน้าทำทุกเฟรมเพราะเบา
                local TickInterval = 0.1

                Farm.Heartbeat = TrackConnection(RunService.Heartbeat:Connect(function()
                    if getgenv().ValkyrieSession ~= SessionToken or not Farm.Active then return end

                    pcall(UpdateAimLock)

                    -- สั่งเดินทุกเฟรมจากทิศที่ลูปหนัก (10Hz) ตัดสินใจไว้ ลำดับความสำคัญ:
                    -- หลบเส้น (MoveGoal) > เดินตามทิศ (MoveDirection) > ยืนนิ่ง
                    --
                    -- MoveDirection เป็น Vector3 เสมอ (ไม่เคย nil) ต้องเช็คขนาดจริง ไม่ใช่แค่ truthy
                    -- ไม่งั้นเวกเตอร์ศูนย์ก็นับเป็น "มีทิศ" แล้วยิง MoveTo ซ้ำทุกเฟรมแทนหยุดจริงครั้งเดียว
                    pcall(function()
                        local Character, Humanoid, Root = GetCharacter()
                        if not Character then return end

                        -- เช็คของอันตรายทุกเฟรมตรงนี้เลย ไม่รอ FarmTick -- พอเส้นหาย ปลดแช่ทันที
                        if Farm.SafeSpot and not LineThreatNearby(Root.Position) then
                            Farm.SafeSpot = nil
                            Farm.MoveGoal = nil
                        end

                        local Moving = Farm.MoveDirection and Farm.MoveDirection.Magnitude > 0.05

                        -- ติดกำแพงอยู่: ดีดออกข้างก่อน ทิศที่คิดไว้เดิมมันพาไปอัดกำแพงซ้ำ
                        if os.clock() < Farm.UnstickUntil and Farm.UnstickDirection then
                            Farm.Held = false
                            StepTowards(Humanoid, Root, Farm.UnstickDirection)
                        elseif Farm.MoveGoal then
                            Farm.Held = false
                            Humanoid:MoveTo(Farm.MoveGoal)
                        elseif Moving then
                            Farm.Held = false
                            StepTowards(Humanoid, Root, Farm.MoveDirection)
                        elseif not Farm.Held then
                            -- สั่งหยุดครั้งเดียวตอนเปลี่ยนสถานะ ไม่ใช่ยิงคำสั่งหยุดรัวทุกเฟรม
                            Farm.Held = true
                            Humanoid:MoveTo(Root.Position)
                        end
                    end)

                    local Now = os.clock()
                    if Now - Farm.TickAt < TickInterval then return end
                    Farm.TickAt = Now

                    pcall(FarmTick)
                end))
            elseif Farm.Heartbeat then
                Farm.Heartbeat:Disconnect()
                Farm.Heartbeat = nil
                Farm.InRange = false
                Farm.Target = nil

                pcall(ReleaseLock)
            end
        end
    })
end

---- ============ Configuration Tab ============ ----

Window:Category("Settings")

local ConfigPage = Window:Page({ Name = "Configuration", Icon = "80758916183665", Columns = 2 })

local InterfaceSection = ConfigPage:Section({
    Name = "Interface",
    Description = "Window and executor options",
    Icon = "93142176757189",
    Side = 1
})

InterfaceSection:Toggle({
    Name = "Window Transparency",
    Flag = "DQRTransparent",
    Default = getgenv().ConfigurationTable.Transparent,
    Callback = function(Value)
        getgenv().ConfigurationTable.Transparent = Value
        SaveConfiguration()

        local Target = Value and 0.08 or 0
        if Library.SetFlags["BackgroundTransparency"] then
            Library.SetFlags["BackgroundTransparency"](Target)
        else
            Library.Flags["BackgroundTransparency"] = Target
            Window:SetTransparency()
        end
    end
})

do
local AntiAfk = { Focused = true }

TrackConnection(game:GetService("UserInputService").WindowFocused:Connect(function()
    AntiAfk.Focused = true
end))

TrackConnection(game:GetService("UserInputService").WindowFocusReleased:Connect(function()
    AntiAfk.Focused = false
end))

local VirtualUser = game:GetService("VirtualUser")

local function AntiAfkStep()
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

local function AntiAfkWait()
    local Delay = 60 + (math.random() - 0.5) * 48

    if math.random() < 0.1 then
        Delay = Delay + 15 + math.random() * 30
    end

    if not AntiAfk.Focused then
        Delay = Delay * 0.7
    end

    return math.max(8, Delay)
end

InterfaceSection:Toggle({
    Name = "Anti-AFK",
    Flag = "DQRAntiAFK",
    Default = getgenv().ConfigurationTable.AntiAFK,
    Callback = function(Value)
        getgenv().ConfigurationTable.AntiAFK = Value
        SaveConfiguration()

        if Value then
            if AntiAfk.Connection then return end

            AntiAfk.Connection = TrackConnection(LocalPlayer.Idled:Connect(function()
                task.spawn(function()
                    pcall(AntiAfkStep)

                    if not AntiAfk.Focused then
                        task.wait(2 + math.random() * 2)
                        pcall(AntiAfkStep)
                    end
                end)
            end))

            AntiAfk.Thread = task.spawn(function()
                while getgenv().ValkyrieSession == SessionToken and getgenv().ConfigurationTable.AntiAFK do
                    task.wait(AntiAfkWait())

                    if not (getgenv().ValkyrieSession == SessionToken and getgenv().ConfigurationTable.AntiAFK) then break end

                    pcall(AntiAfkStep)
                end

                AntiAfk.Thread = nil
            end)
        elseif AntiAfk.Connection then
            AntiAfk.Connection:Disconnect()
            AntiAfk.Connection = nil
            AntiAfk.Thread = nil
        end
    end
})

end

local AutoRejoinConnection = nil

InterfaceSection:Toggle({
    Name = "Auto Rejoin",
    Flag = "DQRAutoRejoin",
    Default = getgenv().ConfigurationTable.AutoRejoin,
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoRejoin = Value
        SaveConfiguration()

        if Value then
            if AutoRejoinConnection then return end

            AutoRejoinConnection = TrackConnection(game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
                if child.Name == "ErrorPrompt" then
                    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
                end
            end))
        elseif AutoRejoinConnection then
            AutoRejoinConnection:Disconnect()
            AutoRejoinConnection = nil
        end
    end
})

InterfaceSection:Toggle({
    Name = "Auto Executor",
    Flag = "DQRAutoExecutor",
    Default = getgenv().ConfigurationTable.AutoExecutor,
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoExecutor = Value
        SaveConfiguration()
    end
})

local function KeyFromName(Name)
    local Ok, Key = pcall(function()
        return Enum.KeyCode[Name]
    end)

    return (Ok and Key) or Enum.KeyCode.End
end

InterfaceSection:Keybind({
    Name = "Minimize Bind",
    Flag = "DQRMinimizeBind",
    Default = KeyFromName(getgenv().ConfigurationTable.MinimizeBind),
    Mode = "Toggle",
    ShowModes = false,
    Callback = function()
        local Data = Library.Flags["DQRMinimizeBind"]
        local Key = Data and Data.Key

        if not Key then return end

        local KeyName = (tostring(Key):gsub("Enum%.KeyCode%.", ""))

        if getgenv().ConfigurationTable.MinimizeBind ~= KeyName then
            getgenv().ConfigurationTable.MinimizeBind = KeyName
            SaveConfiguration()
        end

        Library.MenuKeybind = tostring(Key)
        if type(Library.Flags["MenuBind"]) == "table" then
            Library.Flags["MenuBind"].Key = tostring(Key)
        end
    end
})

---- ============ FPS ============ ----

local FPSSection = ConfigPage:Section({
    Name = "FPS",
    Description = "Framerate and screen",
    Icon = "110273524101447",
    Side = 2
})

FPSSection:Slider({
    Name = "FPS Value",
    Flag = "DQRFPSValue",
    Min = 1,
    Max = 240,
    Default = getgenv().ConfigurationTable.FPSValue,
    Callback = function(Value)
        getgenv().ConfigurationTable.FPSValue = Value
        SaveConfiguration()
    end
})

FPSSection:Toggle({
    Name = "FPS Lock",
    Flag = "DQRFPSLock",
    Default = getgenv().ConfigurationTable.LockFPS,
    Callback = function(Value)
        getgenv().ConfigurationTable.LockFPS = Value
        SaveConfiguration()

        if Value then
            task.spawn(function()
                pcall(function()
                    while getgenv().ConfigurationTable.LockFPS do
                        task.wait()
                        setfpscap(tonumber(getgenv().ConfigurationTable.FPSValue))
                    end
                    setfpscap(240)
                end)
            end)
        end
    end
})

---- ============ Language ============ ----

local LanguageSection = ConfigPage:Section({
    Name = "Language",
    Icon = "90816903776498",
    Side = 2
})

LanguageSection:Dropdown({
    Name = "Select Language",
    Flag = "DQRLanguage",
    Items = { "English (US)", "Thai" },
    Default = getgenv().ConfigurationTable.Language,
    Multi = false,
    Callback = function(Value)
        getgenv().ConfigurationTable.Language = Value
        SaveConfiguration()
    end
})

LanguageSection:Button({
    Name = "Change Language",
    Callback = function()
        ApplyLanguage(getgenv().ConfigurationTable.Language)
    end
})

---- ============ Cleanup ============ ----
--
-- inject ซ้ำโดยไม่เรียก cleanup เดิม จะทำให้ connection/UI เก่าค้างสะสม โดยเฉพาะ AlignOrientation
-- ของ Auto Farm ที่ตัวเก่าค้าง Enabled=true มาดึงหมุนสู้กับตัวใหม่

getgenv().ValkyrieCleanup = function()
    getgenv().ValkyrieSession = nil

    for _, Connection in ipairs(SessionConnections) do
        pcall(function() Connection:Disconnect() end)
    end
    table.clear(SessionConnections)

    -- กันเหนียว: กวาด AlignOrientation/Attachment ที่อาจค้างจากรอบก่อน ๆ
    local Character = LocalPlayer.Character
    if Character then
        for _, Name in ipairs({ "ValkyrieAim", "ValkyrieAimOrientation" }) do
            local Leftover = Character:FindFirstChild(Name, true)
            while Leftover do
                pcall(function() Leftover:Destroy() end)
                Leftover = Character:FindFirstChild(Name, true)
            end
        end
    end

    pcall(function()
        Library:Unload()
    end)

    getgenv().ValkyrieCleanup = nil
end
