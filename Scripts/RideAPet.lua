pcall(function()
    game.Players.LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
end)

getgenv().ConfigurationTable = {}

local FolderConfiguration = "Valkyrie Hub"
local FolderSettings = "Valkyrie Hub/RideAPet"
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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

local filenameConfiguration = FolderConfiguration .. "/" .. "Setting_RideAPet_" .. LocalPlayer.Name .. ".json"

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
    ["AutoCollectEggs"] = false,
    ["EggTypes"] = { },          -- ว่าง = Any
    ["EggRarities"] = { },       -- ว่าง = Any
    ["EggWeightMin"] = 0.9,
    ["EggWeightMax"] = 3,
    ["TweenSpeed"] = 250,
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

---- ============ Game Data ============ ----
--
-- ข้อมูลไข่อยู่ใน ReplicatedStorage.GameData.Eggs (ชื่อไข่ -> { Rarity, Luck, ... })
-- ไข่ที่เกิดอยู่ในเซิร์ฟอยู่ใน ReplicatedStorage.ServerData.ActiveEggs เป็น Configuration ต่ออัน
-- มี attribute: Egg (ชื่อไข่), Weight (น้ำหนักจริง 0.9-3), Position, Mutation, PrivateTo
-- โมเดลที่เรนเดอร์จริงอยู่ workspace.RenderedEggs มี ProximityPrompt "Pick Up" ระยะ 15 studs
-- กด prompt -> client ยิง Remotes.Game.EggPickup:FireServer(<uuid ของ ActiveEggs>)
-- ยิง remote จากระยะไกลเซิร์ฟเวอร์ปฏิเสธ (ทดสอบที่ 123 studs แล้วไข่ไม่หาย) ต้องเดินเข้าไปจริง

local RarityOrder = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Ethereal" }

local EggData = { }
local EggNames = { }

do
    local Ok, Module = pcall(function()
        return require(ReplicatedStorage:WaitForChild("GameData"):WaitForChild("Eggs"))
    end)

    if Ok and type(Module) == "table" then
        for Name, Info in pairs(Module) do
            if type(Info) == "table" then
                EggData[Name] = Info
                table.insert(EggNames, Name)
            end
        end
    end

    table.sort(EggNames, function(A, B)
        local RarityA = table.find(RarityOrder, EggData[A].Rarity or "") or 99
        local RarityB = table.find(RarityOrder, EggData[B].Rarity or "") or 99

        if RarityA ~= RarityB then return RarityA < RarityB end
        return A < B
    end)
end

-- น้ำหนักจริงในเกมคือ 0.9-3 แต่ UI ในเกมโชว์เป็น KG ที่โตแบบ exponential
-- ใช้ General.ShownEggKG แปลงเพื่อโชว์ให้ตรงกับที่เกมแสดง
local ShownKG do
    local Ok, General = pcall(function()
        return require(ReplicatedStorage:WaitForChild("GameData"):WaitForChild("General"))
    end)

    if Ok and type(General) == "table" and type(General.ShownEggKG) == "function" then
        ShownKG = function(Weight)
            local Fine, Value = pcall(General.ShownEggKG, Weight)
            return Fine and Value or nil
        end
    end
end

local function FormatKG(Weight)
    local Shown = ShownKG and ShownKG(Weight)
    if not Shown then return string.format("%.2f", Weight) end

    if Shown < 1000 then
        return string.format("%.1f KG", Shown)
    end

    -- ตัวเลขหลักหมื่นหลักแสน อ่านง่ายกว่าถ้าคั่นหลักพัน
    local Whole = tostring(math.floor(Shown))
    local Grouped = Whole:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")

    return Grouped .. " KG"
end

---- ============ Egg Basket (limit ถือไข่) ============ ----
--
-- ถือไข่ได้จำกัดจำนวนตามตะกร้าที่ใส่อยู่: ReplicatedStorage.GameData.EggBaskets
-- Wooden (ของเริ่มต้น) = ถือได้ 1 ใบ, Infinite (ผ่านเกมพาส) = ไม่จำกัด
-- ของจริงที่ถืออยู่คือ LocalPlayer.Basket (Folder ของ Tool ไข่แต่ละใบ) เต็มแล้วเก็บเพิ่มไม่ได้
-- (เซิร์ฟจะยิง EggPickup.OnClientEvent ส่งสตริง "BasketFull" กลับมาแทน)
-- อ้างอิงจาก Handler ของ PlayerGui.Main.BasketTracker ที่โชว์เลข "ถือ/จุ" ในเกม

local EggBaskets = { }

do
    local Ok, Module = pcall(function()
        return require(ReplicatedStorage:WaitForChild("GameData"):WaitForChild("EggBaskets"))
    end)

    if Ok and type(Module) == "table" then
        EggBaskets = Module
    end
end

local function GetBasketFolder()
    return LocalPlayer:FindFirstChild("Basket")
end

local function GetBasketCapacity()
    local SavedData = LocalPlayer:FindFirstChild("SavedData")
    local Equipped = SavedData and SavedData:FindFirstChild("EquippedEggBasket")
    local Info = Equipped and EggBaskets[Equipped.Value]

    return (Info and Info.Capacity) or 1
end

-- คืนค่า Held (จำนวนไข่ที่ถืออยู่), Capacity (ตัวเลข หรือ math.huge ถ้าไม่จำกัด), Full (bool)
local function GetBasketStatus()
    local Basket = GetBasketFolder()
    local Held = Basket and #Basket:GetChildren() or 0
    local Capacity = GetBasketCapacity()

    return Held, Capacity, Held >= Capacity
end

---- ============ Movement (Tween แบบเดียวกับ Haze Sea) ============ ----
--
-- ไม่ใช่ TweenService: ขยับ HumanoidRootPart ทีละเฟรมบน RenderStep ด้วยความเร็วคงที่ (studs/วิ)
-- ได้เส้นทางลื่นไม่มีกระตุก และไม่มีการวาร์ปกระโดดตำแหน่ง
-- ระหว่างเดินทางเปิด noclip + ล็อกสถานะยืน + วางแท่นใต้เท้า กันร่วง/กันติดของ

local Movement = { }

do
    local MaxStep = 40              -- เพดานระยะต่อเฟรม กันเฟรมตกแล้วกระโดดข้ามแผนที่
    local ArriveWithin = 3

    local NoclipParts = { }
    local NoclipIndex = { }
    local NoclipCharacter_Ref = nil
    local NoclipConnection = nil
    local NoclipRemovingConnection = nil
    local CollisionMemory = { }

    local function GetCharacter()
        local Character = LocalPlayer.Character
        if not Character or not Character.Parent then return nil end
        return Character
    end

    local function GetRoot()
        local Character = GetCharacter()
        return Character and Character:FindFirstChild("HumanoidRootPart")
    end

    local function GetHumanoid()
        local Character = GetCharacter()
        return Character and Character:FindFirstChildOfClass("Humanoid")
    end

    Movement.GetCharacter = GetCharacter
    Movement.GetRoot = GetRoot
    Movement.GetHumanoid = GetHumanoid

    local function NoclipUntrack(Part)
        local Index = NoclipIndex[Part]
        if not Index then return end

        local Last = #NoclipParts
        local Moved = NoclipParts[Last]

        NoclipParts[Index] = Moved
        NoclipIndex[Moved] = Index
        NoclipParts[Last] = nil
        NoclipIndex[Part] = nil
    end

    local function NoclipTrack(Part)
        if NoclipIndex[Part] or not Part:IsA("BasePart") then return end

        local Slot = #NoclipParts + 1
        NoclipParts[Slot] = Part
        NoclipIndex[Part] = Slot
    end

    local function NoclipCharacter(Character)
        if Character ~= NoclipCharacter_Ref then
            NoclipCharacter_Ref = Character
            table.clear(NoclipParts)
            table.clear(NoclipIndex)
            table.clear(CollisionMemory)

            if NoclipConnection then
                pcall(function() NoclipConnection:Disconnect() end)
                NoclipConnection = nil
            end

            if NoclipRemovingConnection then
                pcall(function() NoclipRemovingConnection:Disconnect() end)
                NoclipRemovingConnection = nil
            end

            for _, Part in ipairs(Character:GetDescendants()) do
                NoclipTrack(Part)
            end

            NoclipConnection = Character.DescendantAdded:Connect(NoclipTrack)
            NoclipRemovingConnection = Character.DescendantRemoving:Connect(NoclipUntrack)
        end

        local Index = 1
        while Index <= #NoclipParts do
            local Part = NoclipParts[Index]

            if not Part.Parent then
                NoclipUntrack(Part)
            else
                if Part.CanCollide then
                    CollisionMemory[Part] = true
                    Part.CanCollide = false
                end
                Index = Index + 1
            end
        end
    end

    -- คืนการชนให้ชิ้นที่เราปิดไว้เอง ไม่ยุ่งกับชิ้นที่เกมตั้ง CanCollide=false อยู่แล้ว
    local function RestoreCollision()
        for Part in pairs(CollisionMemory) do
            if Part.Parent then
                pcall(function() Part.CanCollide = true end)
            end
        end
        table.clear(CollisionMemory)
    end

    local GroundStates = {
        Enum.HumanoidStateType.Freefall,
        Enum.HumanoidStateType.FallingDown,
        Enum.HumanoidStateType.Flying,
    }

    local GroundActive = false
    local GroundHumanoid = nil

    local function SetGroundState(On)
        local Humanoid = GetHumanoid()
        if not Humanoid then
            GroundActive = false
            GroundHumanoid = nil
            return
        end

        if On then
            if GroundActive and GroundHumanoid == Humanoid then return end

            for _, State in ipairs(GroundStates) do
                pcall(function() Humanoid:SetStateEnabled(State, false) end)
            end

            if Humanoid:GetState() ~= Enum.HumanoidStateType.Running then
                pcall(function() Humanoid:ChangeState(Enum.HumanoidStateType.Running) end)
            end

            GroundActive = true
            GroundHumanoid = Humanoid
        elseif GroundActive then
            for _, State in ipairs(GroundStates) do
                pcall(function() Humanoid:SetStateEnabled(State, true) end)
            end

            GroundActive = false
            GroundHumanoid = nil
        end
    end

    local PlatformPart = nil
    local PlatformThickness = 1
    local PlatformSize = Vector3.new(8, PlatformThickness, 8)

    local function DestroyPlatform()
        if PlatformPart then
            pcall(function() PlatformPart:Destroy() end)
            PlatformPart = nil
        end
    end

    local function GetFootOffset(Humanoid, Root)
        if Humanoid.RigType == Enum.HumanoidRigType.R6 then return 3 end
        return Humanoid.HipHeight + (Root.Size.Y * 0.5)
    end

    local function UpdatePlatform(Humanoid, Root)
        if not PlatformPart or not PlatformPart.Parent then
            DestroyPlatform()

            local Part = Instance.new("Part")
            Part.Name = "Valkyrie_Platform"
            Part.Size = PlatformSize
            Part.Anchored = true
            Part.CanCollide = false
            Part.CanQuery = false
            Part.CanTouch = false
            Part.Transparency = 1
            Part.Parent = workspace
            PlatformPart = Part
        end

        local FootY = Root.Position.Y - GetFootOffset(Humanoid, Root)
        PlatformPart.CFrame = CFrame.new(Root.Position.X, FootY - (PlatformThickness * 0.5), Root.Position.Z)
    end

    local MoveTarget = nil
    local MoveDone = false
    local RenderBound = false
    local Sinking = false      -- โหมดกลับบ้าน: มุดลงดิน ห้ามวางแท่นใต้เท้า ไม่งั้นไม่จม

    local function OnStep(Delta)
        local Character = GetCharacter()
        local Root = GetRoot()
        local Humanoid = GetHumanoid()

        if not Character or not Root or not Humanoid or Humanoid.Health <= 0 then return end

        NoclipCharacter(Character)

        if not MoveTarget then return end

        local Origin = Root.Position
        local Goal = MoveTarget.Position
        local Offset = Goal - Origin
        local Remaining = Offset.Magnitude

        local Speed = tonumber(getgenv().ConfigurationTable.TweenSpeed) or 250
        local Step = math.min(Speed * Delta, MaxStep)

        if Remaining <= Step or Remaining < 1 then
            Root.CFrame = MoveTarget
            Root.AssemblyLinearVelocity = Vector3.zero
            MoveTarget = nil
            MoveDone = true
        else
            local Direction = Offset.Unit
            local NextPosition = Origin + Direction * Step

            Root.CFrame = CFrame.lookAt(NextPosition, NextPosition + Direction)
            Root.AssemblyLinearVelocity = Vector3.zero
            Root.AssemblyAngularVelocity = Vector3.zero
        end

        SetGroundState(true)

        if not Sinking then
            UpdatePlatform(Humanoid, Root)
        else
            DestroyPlatform()
        end
    end

    local function StartRender()
        if RenderBound then return end
        RenderBound = true
        RunService:BindToRenderStep("Valkyrie_Move", Enum.RenderPriority.Camera.Value - 1, OnStep)
    end

    local function StopRender()
        if not RenderBound then return end
        RenderBound = false
        pcall(function() RunService:UnbindFromRenderStep("Valkyrie_Move") end)
    end

    function Movement.Cancel()
        MoveTarget = nil
        MoveDone = true
        Sinking = false

        StopRender()
        SetGroundState(false)
        RestoreCollision()
        DestroyPlatform()
    end

    -- ขี่สัตว์อยู่แล้ว tween จะลากทั้งตัวขี่ทำให้เด้ง/หลุด ลงจากหลังสัตว์ก่อนเสมอ
    function Movement.Dismount()
        local Riding = LocalPlayer:GetAttribute("IsRiding") == true or LocalPlayer:GetAttribute("IsPassenger") == true
        if not Riding then return false end

        local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local Game = Remotes and Remotes:FindFirstChild("Game")
        local Remote = Game and Game:FindFirstChild("PetDismount")

        if not Remote then return false end

        pcall(function() Remote:FireServer() end)

        local Deadline = os.clock() + 1.5
        while os.clock() < Deadline do
            if LocalPlayer:GetAttribute("IsRiding") ~= true and LocalPlayer:GetAttribute("IsPassenger") ~= true then
                break
            end
            task.wait(0.05)
        end

        task.wait(0.15)
        return true
    end

    --// เดินทางไปหาจุดหมายแบบลื่น ๆ
    --
    -- คืนค่า true เมื่อถึงที่หมาย, false เมื่อหมดเวลา/ตัวละครหาย/ถูกสั่งยกเลิก
    function Movement.Travel(Target, Threshold, Timeout, ShouldContinue)
        local Root = GetRoot()
        if not Root then return false end

        Movement.Dismount()

        Root = GetRoot()
        if not Root then return false end

        if typeof(Target) == "Vector3" then
            Target = CFrame.new(Target)
        end

        Threshold = Threshold or ArriveWithin

        if (Root.Position - Target.Position).Magnitude <= Threshold then
            return true
        end

        MoveTarget = Target
        MoveDone = false
        Sinking = false

        StartRender()

        local Deadline = os.clock() + (Timeout or 20)

        while RenderBound and MoveTarget and not MoveDone do
            if os.clock() > Deadline then break end
            if ShouldContinue and not ShouldContinue() then break end
            if not GetRoot() then break end

            task.wait()
        end

        local Arrived = MoveDone
        Movement.Cancel()

        return Arrived
    end

    --// กลับบ้าน: มุดลงดิน
    --
    -- เกมเช็คว่าตัวละครหลุดใต้แมพแล้วส่งกลับ plot ให้เอง เร็วกว่าเดินกลับและไม่ต้องรู้พิกัดบ้าน
    function Movement.Home(Depth, Timeout)
        local Root = GetRoot()
        if not Root then return false end

        Movement.Dismount()

        Root = GetRoot()
        if not Root then return false end

        local StartPosition = Root.Position

        MoveTarget = CFrame.new(StartPosition - Vector3.new(0, Depth or 400, 0))
        MoveDone = false
        Sinking = true

        StartRender()

        local Deadline = os.clock() + (Timeout or 15)
        local Moved = false

        while os.clock() < Deadline do
            task.wait(0.05)

            local Current = GetRoot()

            -- ตัวละครถูกเกมย้าย (กลับบ้าน) หรือเกิดใหม่ = จบงาน
            if not Current then
                Moved = true
                break
            end

            local Flat = (Vector3.new(Current.Position.X, 0, Current.Position.Z) - Vector3.new(StartPosition.X, 0, StartPosition.Z)).Magnitude

            if Flat > 40 or Current.Position.Y > StartPosition.Y + 10 then
                Moved = true
                break
            end

            if not MoveTarget then
                -- ถึงก้นที่ตั้งไว้แล้วยังไม่ถูกส่งกลับ ดันลงต่ออีกชั้น
                MoveTarget = CFrame.new(Current.Position - Vector3.new(0, Depth or 400, 0))
                MoveDone = false
            end
        end

        Movement.Cancel()
        return Moved
    end
end

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
        ["Window and executor options"] = "ตัวเลือกหน้าต่างและตัวรัน",
        ["Window Transparency"] = "ทำหน้าต่างโปร่งใส",
        ["Anti-AFK"] = "กันหลุด AFK",
        ["Auto Rejoin"] = "เข้าเกมใหม่อัตโนมัติ",
        ["Auto Executor"] = "รันสคริปต์ตอนย้ายเซิร์ฟ",
        ["Minimize Bind"] = "ปุ่มย่อ/เปิดเมนู",
        ["FPS"] = "FPS",
        ["Framerate and screen"] = "เฟรมเรตและหน้าจอ",
        ["FPS Value"] = "ค่า FPS",
        ["FPS Lock"] = "ล็อก FPS",
        ["Language"] = "ภาษา",
        ["Select Language"] = "เลือกภาษา",
        ["Change Language"] = "เปลี่ยนภาษา",
        ["Auto Farm"] = "ฟาร์มอัตโนมัติ",
        ["Auto Eggs"] = "เก็บไข่อัตโนมัติ",
        ["Walk to eggs and pick them up"] = "เดินไปเก็บไข่ให้เอง",
        ["Auto Collect Eggs"] = "เก็บไข่อัตโนมัติ",
        ["Egg Type"] = "ชนิดไข่",
        ["Rarity"] = "ความหายาก",
        ["Minimum Weight"] = "น้ำหนักต่ำสุด",
        ["Maximum Weight"] = "น้ำหนักสูงสุด",
        ["Tween Speed"] = "ความเร็วเดินทาง",
        ["Return Home"] = "กลับบ้าน",
        ["Status"] = "สถานะ",
        ["Idle"] = "ว่าง",
        ["Any"] = "ทั้งหมด",
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
    Name = "Ride A Pet",
    SubName = "by Phoenix",
    Logo = IconValkyrie
})

Window:Category("General")

---- ============ Auto Farm Tab ============ ----

local AutoFarmPage = Window:Page({ Name = "Auto Farm", Icon = "80758916183665", Columns = 2 })

local EggSection = AutoFarmPage:Section({
    Name = "Auto Eggs",
    Description = "Walk to eggs and pick them up",
    Icon = "93142176757189",
    Side = 1
})

do
    local Collector = {
        Active = false,
        Thread = nil,
        Target = nil,        -- Configuration ใน ActiveEggs
        Model = nil,         -- โมเดลใน workspace.RenderedEggs
        Skip = { },          -- uuid -> เวลาที่จะลองใหม่
    }

    local function GetCharacter()
        local Character = LocalPlayer.Character
        if not Character then return nil end

        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        local Root = Character:FindFirstChild("HumanoidRootPart")

        if not Humanoid or Humanoid.Health <= 0 or not Root then return nil end

        return Character, Humanoid, Root
    end

    local function ActiveEggsFolder()
        local ServerData = ReplicatedStorage:FindFirstChild("ServerData")
        return ServerData and ServerData:FindFirstChild("ActiveEggs")
    end

    -- ไข่ชนิดที่เก็บไปแล้วจะถูกซ่อน (attribute CollectedEggs ของผู้เล่นเป็นสตริง "Egg,Egg,")
    -- ไม่ต้องเล็งไข่พวกนั้น เพราะเก็บซ้ำไม่ได้จนกว่าจะเอาไปฟักหรือวาง
    local function AlreadyHolding(EggName)
        local Collected = LocalPlayer:GetAttribute("CollectedEggs")
        if type(Collected) ~= "string" or Collected == "" then return false end

        return string.find(Collected, EggName .. ",", 1, true) ~= nil
    end

    local function SelectionHas(List, Value)
        if type(List) ~= "table" or #List == 0 then return true end -- ว่าง = Any
        return table.find(List, Value) ~= nil
    end

    local function PassesFilters(Config)
        local EggName = Config:GetAttribute("Egg")
        if not EggName then return false end

        local Private = Config:GetAttribute("PrivateTo")
        if Private and Private ~= LocalPlayer.UserId then return false end

        if AlreadyHolding(EggName) then return false end

        local Settings = getgenv().ConfigurationTable

        if not SelectionHas(Settings.EggTypes, EggName) then return false end

        local Info = EggData[EggName]
        local Rarity = Info and Info.Rarity or "Common"
        if not SelectionHas(Settings.EggRarities, Rarity) then return false end

        local Weight = Config:GetAttribute("Weight") or 0
        if Weight < (tonumber(Settings.EggWeightMin) or 0) then return false end
        if Weight > (tonumber(Settings.EggWeightMax) or 3) then return false end

        return true
    end

    -- จับคู่ Configuration กับโมเดลที่เรนเดอร์: ชื่อโมเดล = ชื่อไข่ และ pivot อยู่ใกล้ attribute Position
    -- (โมเดลถูกวางลงพื้นจริงทีหลัง ตำแหน่งเลยไม่ตรงเป๊ะกับ Position)
    local function FindModel(Config)
        local Folder = workspace:FindFirstChild("RenderedEggs")
        if not Folder then return nil end

        local EggName = Config:GetAttribute("Egg")
        local Position = Config:GetAttribute("Position")
        if not (EggName and Position) then return nil end

        local Best, BestDistance = nil, 24

        for _, Model in ipairs(Folder:GetChildren()) do
            if Model.Name == EggName and Model:IsA("Model") then
                local Ok, Pivot = pcall(function() return Model:GetPivot().Position end)

                if Ok then
                    local Distance = (Pivot - Position).Magnitude
                    if Distance < BestDistance then
                        Best, BestDistance = Model, Distance
                    end
                end
            end
        end

        return Best
    end

    local function FindPrompt(Model)
        return Model and Model:FindFirstChildWhichIsA("ProximityPrompt", true)
    end

    local function PickTarget(Root)
        local Folder = ActiveEggsFolder()
        if not Folder then return nil end

        -- ไม่จำกัดระยะค้นหา เอาไข่ที่ผ่านฟิลเตอร์ใกล้สุดในทั้งเซิร์ฟ
        local Now = os.clock()
        local Best, BestDistance = nil, math.huge

        for _, Config in ipairs(Folder:GetChildren()) do
            local Retry = Collector.Skip[Config.Name]

            if not Retry or Now >= Retry then
                if PassesFilters(Config) then
                    local Position = Config:GetAttribute("Position")
                    local Distance = Position and (Position - Root.Position).Magnitude

                    if Distance and Distance < BestDistance then
                        Best, BestDistance = Config, Distance
                    end
                end
            end
        end

        return Best, BestDistance
    end

    local function TryPickup(Config, Model)
        local Prompt = FindPrompt(Model)

        if Prompt and type(fireproximityprompt) == "function" then
            -- ทางปกติของเกม: กด prompt แล้ว client เป็นคนยิง EggPickup เอง
            local Enabled = Prompt.Enabled
            Prompt.Enabled = true
            pcall(fireproximityprompt, Prompt, 1)
            Prompt.Enabled = Enabled
            return true
        end

        local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local Game = Remotes and Remotes:FindFirstChild("Game")
        local Remote = Game and Game:FindFirstChild("EggPickup")

        if Remote then
            pcall(function() Remote:FireServer(Config.Name) end)
            return true
        end

        return false
    end

    --// ลูปหลัก: เลือกไข่ที่ผ่านฟิลเตอร์ -> tween เข้าไปหา -> กด prompt เก็บ
    --
    -- tween ใช้ตัวเดียวกับ Haze Sea (RenderStep + noclip) ไม่ใช้ Humanoid:MoveTo
    -- เพราะเดินจริงติดรั้ว/เนิน และช้ากว่ามาก
    local function RunCollector()
        while getgenv().ValkyrieSession == SessionToken and Collector.Active do
            task.wait(0.1)

            local Character, Humanoid, Root = GetCharacter()

            local Held, Capacity, Full = GetBasketStatus()

            if not Character then
                Collector.Target = nil
            elseif Full then
                -- ตะกร้าเต็มแล้ว เก็บเพิ่มไม่ได้ (เซิร์ฟตอบ "BasketFull" เฉย ๆ) เดินทางต่อไปก็เสียเวลาเปล่า
                Collector.Target = nil

                Movement.Home()

                -- รอสักพักให้ผู้เล่นเอาไข่ออกจากตะกร้า (วาง/ฟัก) ก่อนวนไปหาไข่ใหม่
                local Deadline = os.clock() + 30
                while getgenv().ValkyrieSession == SessionToken and Collector.Active and os.clock() < Deadline do
                    local _, _, StillFull = GetBasketStatus()
                    if not StillFull then break end
                    task.wait(1)
                end
            else
                local Target = Collector.Target

                -- เป้าหายไป (คนอื่นเก็บก่อน / ไม่ผ่านฟิลเตอร์แล้ว) หาใหม่
                if Target and (not Target.Parent or not PassesFilters(Target)) then
                    Target = nil
                    Collector.Target = nil
                end

                if not Target then
                    Target = PickTarget(Root)
                    Collector.Target = Target
                end

                if Target then
                    local EggName = Target:GetAttribute("Egg")
                    local Weight = Target:GetAttribute("Weight") or 0
                    local Model = FindModel(Target)
                    local Prompt = FindPrompt(Model)
                    local Goal = (Model and Model:GetPivot().Position) or Target:GetAttribute("Position")

                    if not Goal then
                        Collector.Skip[Target.Name] = os.clock() + 10
                        Collector.Target = nil
                    else
                        local Range = math.max((Prompt and Prompt.MaxActivationDistance or 15) - 4, 6)

                        if (Goal - Root.Position).Magnitude > Range then
                            -- ยืนสูงกว่าไข่นิดหน่อย prompt ยังติด แต่ไม่จมพื้น
                            local Stand = CFrame.new(Goal + Vector3.new(0, 4, 0))

                            Movement.Travel(Stand, Range, 20, function()
                                return getgenv().ValkyrieSession == SessionToken
                                    and Collector.Active
                                    and Target.Parent ~= nil
                            end)

                            Character, Humanoid, Root = GetCharacter()
                            if not Root then
                                Collector.Target = nil
                            end
                        end

                        if Root and Target.Parent then
                            Model = FindModel(Target) or Model

                            if (Goal - Root.Position).Magnitude <= Range + 6 then
                                if TryPickup(Target, Model) then
                                    -- ไม่ลองซ้ำทันที รอ 1 วิให้เซิร์ฟตอบ แล้วค่อยหาเป้าใหม่
                                    Collector.Skip[Target.Name] = os.clock() + 1

                                    -- รอให้ LocalPlayer.Basket อัปเดตจริงก่อนไปหาเป้าถัดไป
                                    -- ไม่งั้นเช็คตะกร้าเต็มรอบหน้าจะยังอ่านค่าเก่า แล้วออกไปหาไข่อีกลูกก่อนค่อยวกกลับ
                                    local BasketBefore = Held
                                    local WaitUntil = os.clock() + 2

                                    while os.clock() < WaitUntil do
                                        local NowHeld, _, NowFull = GetBasketStatus()
                                        if NowHeld ~= BasketBefore or NowFull then break end
                                        task.wait(0.1)
                                    end
                                else
                                    Collector.Skip[Target.Name] = os.clock() + 5
                                    task.wait(0.3)
                                end
                            else
                                -- ไปไม่ถึง (โดนยกเลิก/หมดเวลา) พักไข่ลูกนี้ไว้ก่อน
                                Collector.Skip[Target.Name] = os.clock() + 15
                            end

                            Collector.Target = nil
                        end
                    end
                end
            end
        end

        Movement.Cancel()
        Collector.Thread = nil
    end

    EggSection:Toggle({
        Name = "Auto Collect Eggs",
        Flag = "RAPAutoCollectEggs",
        Default = getgenv().ConfigurationTable.AutoCollectEggs,
        Callback = function(Value)
            getgenv().ConfigurationTable.AutoCollectEggs = Value
            SaveConfiguration()

            Collector.Active = Value
            table.clear(Collector.Skip)
            Collector.Target = nil

            if not Value then
                Movement.Cancel()
            end

            if Value and not Collector.Thread then
                Collector.Thread = task.spawn(RunCollector)
            end
        end
    })

    -- ไม่เลือกอะไรเลย = เอาทุกชนิด (เหมือน Steal an Egg)
    EggSection:Dropdown({
        Name = "Egg Type",
        Flag = "RAPEggTypes",
        Items = EggNames,
        Default = getgenv().ConfigurationTable.EggTypes,
        Multi = true,
        Callback = function(Value)
            getgenv().ConfigurationTable.EggTypes = type(Value) == "table" and Value or { }
            SaveConfiguration()
            Collector.Target = nil
        end
    })

    EggSection:Dropdown({
        Name = "Rarity",
        Flag = "RAPEggRarities",
        Items = RarityOrder,
        Default = getgenv().ConfigurationTable.EggRarities,
        Multi = true,
        Callback = function(Value)
            getgenv().ConfigurationTable.EggRarities = type(Value) == "table" and Value or { }
            SaveConfiguration()
            Collector.Target = nil
        end
    })

    -- น้ำหนักจริงของไข่ (attribute Weight) วิ่ง 0.9-2 ปกติ, ไข่อีเวนต์/Giant ขึ้นได้ถึง 3
    -- ยิ่งหนักยิ่งได้เพ็ตตัวใหญ่ (KG ที่เกมโชว์โตแบบ exponential ตาม General.WeightDisplay)
    EggSection:Slider({
        Name = "Minimum Weight",
        Flag = "RAPEggWeightMin",
        Min = 0.9,
        Max = 3,
        Default = getgenv().ConfigurationTable.EggWeightMin,
        Decimals = 0.01,
        Suffix = " kg",
        Callback = function(Value)
            getgenv().ConfigurationTable.EggWeightMin = Value
            SaveConfiguration()
            Collector.Target = nil
        end
    })

    EggSection:Slider({
        Name = "Maximum Weight",
        Flag = "RAPEggWeightMax",
        Min = 0.9,
        Max = 3,
        Default = getgenv().ConfigurationTable.EggWeightMax,
        Decimals = 0.01,
        Suffix = " kg",
        Callback = function(Value)
            getgenv().ConfigurationTable.EggWeightMax = Value
            SaveConfiguration()
            Collector.Target = nil
        end
    })

    EggSection:Slider({
        Name = "Tween Speed",
        Flag = "RAPTweenSpeed",
        Min = 50,
        Max = 600,
        Default = getgenv().ConfigurationTable.TweenSpeed,
        Suffix = " studs/s",
        Callback = function(Value)
            getgenv().ConfigurationTable.TweenSpeed = Value
            SaveConfiguration()
        end
    })

    -- กลับบ้าน = tween มุดลงดิน แล้วเกมส่งกลับ plot ให้เอง
    EggSection:Button({
        Name = "Return Home",
        Callback = function()
            task.spawn(function()
                local WasActive = Collector.Active
                Collector.Active = false
                Movement.Cancel()

                Movement.Home()

                Collector.Active = WasActive

                if WasActive and not Collector.Thread then
                    Collector.Thread = task.spawn(RunCollector)
                end
            end)
        end
    })

    if getgenv().ConfigurationTable.AutoCollectEggs then
        Collector.Active = true
        Collector.Thread = task.spawn(RunCollector)
    end
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
    Flag = "RAPTransparent",
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
    Flag = "RAPAntiAFK",
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
    Flag = "RAPAutoRejoin",
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
    Flag = "RAPAutoExecutor",
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
    Flag = "RAPMinimizeBind",
    Default = KeyFromName(getgenv().ConfigurationTable.MinimizeBind),
    Mode = "Toggle",
    ShowModes = false,
    Callback = function()
        local Data = Library.Flags["RAPMinimizeBind"]
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
    Flag = "RAPFPSValue",
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
    Flag = "RAPFPSLock",
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
    Flag = "RAPLanguage",
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

getgenv().ValkyrieCleanup = function()
    getgenv().ValkyrieSession = nil

    pcall(function() Movement.Cancel() end)

    for _, Connection in ipairs(SessionConnections) do
        pcall(function() Connection:Disconnect() end)
    end
    table.clear(SessionConnections)

    pcall(function()
        Library:Unload()
    end)

    getgenv().ValkyrieCleanup = nil
end
