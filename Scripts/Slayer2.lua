pcall(function()
    game.Players.LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
end)

getgenv().ConfigurationTable = {}

local FolderConfiguration = "Valkyrie Hub"
local FolderSettings = "Valkyrie Hub/Slayer2"
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
-- UI = Milenium (UI-Library/Milenium/main.luau) - อัปไฟล์นั้นขึ้น endpoint นี้
local LibraryUrl = "https://www.valkyriehub.net/api/raw/milenium-lib"

local SessionToken = { }
local SessionConnections = { }

if type(getgenv().ValkyrieCleanup) == "function" then
    pcall(getgenv().ValkyrieCleanup)
end

getgenv().ValkyrieSession = SessionToken

--// ตัวกันยิง remote รัว (ผู้ใช้ 2026-09-30 หลังโดน kick: เช็คว่ามีการยิง event มั่วไหม)
-- ทุกระบบของฮับยิงผ่านตัวครอบนี้ (HubSignal(require(...SignalEvent / SignalFunction))) ไม่แตะ module ของเกมเอง
-- ชื่อ event เดียวกันเกิน Limit ครั้งใน 1 วิ = ทิ้งครั้งนั้น (คืน nil) - ลอจิกไหนพังวนยิงทุกเฟรมก็ไม่หลุดไปถึงเซิร์ฟ
-- ดูสถิติสดผ่าน dex: getgenv().ValkyrieSignalStats = { Sent = { [ชื่อ] = ครั้ง }, Dropped = { [ชื่อ] = ครั้ง } }
-- (ไม่เพิ่ม local ระดับไฟล์ - ไฟล์นี้ชนเพดาน 200 local ของ main chunk แล้ว: HubSignal เป็น global ของ chunk นี้)
do
local SignalLimits = {
    Default = 5,
    Combat_Service = 8,     -- M1 คอมโบห่างกัน ~0.25 วิ
    Tool_Mouse = 6,         -- กด/ปล่อยเป็นคู่
    AddQuest = 2,
    RemoveQuest = 2,
    QuestProgress = 3,
}
local SignalStats = { Sent = { }, Dropped = { } }
getgenv().ValkyrieSignalStats = SignalStats
local HubSignals = setmetatable({ }, { __mode = "k" })

function HubSignal(Module)
    if type(Module) ~= "table" or type(Module.ToServer) ~= "function" then return Module end
    if HubSignals[Module] then return HubSignals[Module] end

    local Stamps = { }
    local Proxy = setmetatable({ }, { __index = Module })
    Proxy.ToServer = function(Name, ...)
        local Key = tostring(Name)
        local Now = os.clock()
        local List = Stamps[Key]
        if not List then List = { } Stamps[Key] = List end
        while List[1] and Now - List[1] >= 1 do table.remove(List, 1) end
        if #List >= (SignalLimits[Key] or SignalLimits.Default) then
            SignalStats.Dropped[Key] = (SignalStats.Dropped[Key] or 0) + 1
            return nil
        end
        table.insert(List, Now)
        SignalStats.Sent[Key] = (SignalStats.Sent[Key] or 0) + 1
        return Module.ToServer(Name, ...)
    end
    HubSignals[Module] = Proxy
    return Proxy
end

--// ลำดับความสำคัญของท่า (ผู้ใช้ 2026-09-30: ไม่ให้ชนกัน / ไม่ยิงมั่ว) - ท่าต่อสู้ทำได้ทีละอย่าง
-- ตัวเลขน้อย = สำคัญกว่า: มีท่าที่สำคัญกว่าค้างอยู่ = ท่านี้ห้ามเริ่ม และที่ทำอยู่ต้องหยุด (Allowed = false)
--   Potion 1 ดื่มยา (เอาตัวรอด) > Dodge 2 หลบสกิลบอส > Skill 3 ใช้สกิล > Swap 4 สลับอาวุธ
--   > Parry 5 กันตามจังหวะ (แท็บ Combat) > M1 6 คอมโบ > Block 7 กันรอคูลดาวน์ M1 (M1 พร้อม = ปล่อยกันแล้วตี)
-- Claim(ชื่อ, วิ) = จอง (หมดอายุเองกันลืมปล่อย) / Release(ชื่อ) = ปล่อย / ท่าระดับเดียวกันไม่กันกัน
-- ดูสดผ่าน dex: HubAction.Active / HubAction.Current()
local Order = { Potion = 1, Dodge = 2, Skill = 3, Swap = 4, Parry = 5, M1 = 6, Block = 7 }
local Active = { }
HubAction = { Order = Order, Active = Active }

function HubAction.Allowed(Name)
    local Mine = Order[Name] or 99
    local Now = os.clock()
    for Other, Expire in pairs(Active) do
        if Now > Expire then
            Active[Other] = nil
        elseif Other ~= Name and (Order[Other] or 99) < Mine then
            return false
        end
    end
    return true
end

function HubAction.Claim(Name, Seconds)
    if not HubAction.Allowed(Name) then return false end
    Active[Name] = os.clock() + (Seconds or 5)
    return true
end

-- จองแบบบังคับ (ท่าที่ต้องทำแน่ ๆ เช่นดื่มยา/หลบ) - ท่าที่ต่ำกว่าเห็น Allowed = false แล้วหยุดเอง
function HubAction.Force(Name, Seconds)
    Active[Name] = os.clock() + (Seconds or 5)
end

function HubAction.Release(Name)
    Active[Name] = nil
end

function HubAction.Current()
    local Best, Rank = nil, math.huge
    local Now = os.clock()
    for Name, Expire in pairs(Active) do
        if Now <= Expire and (Order[Name] or 99) < Rank then Best, Rank = Name, Order[Name] or 99 end
    end
    return Best
end
end

local function TrackConnection(Connection)
    if Connection then
        table.insert(SessionConnections, Connection)
    end
    return Connection
end

local filenameConfiguration = FolderConfiguration .. "/" .. "Setting_Slayer2_" .. LocalPlayer.Name .. ".json"

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
    ["Theme"] = "Midnight",          -- ชื่อธีมของ Milenium (Milenium / Midnight / Sakura / Emerald / Amber / Crimson / Mono)
    ["Language"] = "English (US)",
    ["FPSValue"] = 144,
    ["LockFPS"] = false,

    -- Auto Farm
    ["AutoFarm"] = false,            -- ฟาร์มเองจน Level Max
    ["AutoAcceptQuest"] = false,     -- รับ quest ที่ผูกกับมอนที่กำลังฟาร์มอยู่ ให้ EXP ดันเลเวล
    ["AutoCollectDrops"] = false,    -- เก็บกล่อง (Chest) + ของที่มอน/บอสดรอปตามพื้น (LootDrop) อัตโนมัติ
    ["AutoRaidCache"] = false,       -- ตีการ์ดแคมป์ (Humanoids.Regions.Temporary) ปลดผนึก Sealed Cache แล้วเปิดเก็บของ
    -- tier ที่จะไปตี เก็บเป็น map ไม่ใช่ลิสต์ - MergeConfiguration เติมช่องที่ขาดจาก default
    -- ลิสต์ {"T1"} ที่เซฟไว้จะโดนเติมกลับเป็น {"T1","T2","T3"} ส่วน map ตัวที่ปิดเซฟเป็น false ค่าคงอยู่
    ["RaidCacheTiers"] = { T1 = true, T2 = true, T3 = true },
    ["CollectRadius"] = 60,          -- studs - ไกลกว่านี้ไม่วิ่งไปเก็บ (กันวิ่งข้ามแมพไปเก็บของคนอื่น)
    ["FarmPriority"] = { "Potion", "Sell", "Hunt", "Boss", "Camp", "Mob", "Level", "Fish" },   -- หน้า Priority: เปิดหลายโหมด = ทำตัวบนสุดที่มีงานก่อน
    ["FarmWeapon"] = "",             -- ชื่อไอเทมใน Toolbar, ว่าง = ไม่เปลี่ยนที่ถืออยู่ (ค่ากลาง - แต่ละแท็บมีคีย์ของตัวเองแล้ว)
    ["FarmMethod"] = "Above",        -- Above / Below / Behind
    ["FarmDistance"] = 4,
    ["AutoDodge"] = true,            -- บอสเริ่มใช้สกิล = บินหนีไกล ๆ แล้วกลับมาตีต่อ ปิด = ยืนเกาะมอนตลอด

    -- ตั้งค่าแยกต่อโหมด (Level / Mob / Boss) - แต่ละแท็บมีอาวุธ/ท่ายืน/ระยะ/เก็บกล่อง
    -- เป็นของตัวเอง (ModeSetting อ่านคีย์เหล่านี้ตาม getgenv().ValkyrieFarmSuffix ที่ SetMode ตั้งให้)
    ["FarmWeaponLevel"] = "",
    ["FarmMethodLevel"] = "Above",
    ["FarmDistanceLevel"] = 4,
    ["AutoDodgeLevel"] = true,
    ["AutoCollectDropsLevel"] = false,
    ["CollectRadiusLevel"] = 60,

    ["FarmWeaponMob"] = "",
    ["FarmMethodMob"] = "Above",
    ["FarmDistanceMob"] = 4,
    ["AutoDodgeMob"] = true,
    ["AutoCollectDropsMob"] = false,
    ["CollectRadiusMob"] = 60,

    ["FarmWeaponBoss"] = "",
    ["FarmMethodBoss"] = "Above",
    ["FarmDistanceBoss"] = 4,
    ["AutoDodgeBoss"] = true,
    ["AutoCollectDropsBoss"] = false,
    ["CollectRadiusBoss"] = 60,

    -- แท็บ Boss Hunt (โหมด Hunt - suffix "Hunt")
    ["FarmWeaponHunt"] = "",
    ["FarmMethodHunt"] = "Above",
    ["FarmDistanceHunt"] = 4,
    ["AutoDodgeHunt"] = true,
    ["AutoCollectDropsHunt"] = false,
    ["CollectRadiusHunt"] = 60,

    -- แท็บ Sealed Cache Raid (โหมด Camp - suffix "Raid") + Instant Kill การ์ดแคมป์
    ["FarmWeaponRaid"] = "",
    ["FarmMethodRaid"] = "Above",
    ["FarmDistanceRaid"] = 4,
    ["AutoDodgeRaid"] = true,
    ["RaidInstantKill"] = false,
    -- กติกา Instant Kill ทุกแท็บ (Raid / Breathing / Trial และที่จะเพิ่มทีหลัง): % เลือดตั้งได้สูงสุด 90
    -- (slider Max = 90 + clamp ตอนโหลด/ตอนใช้) ค่าเริ่มต้น = 90
    ["RaidInstantKillHealth"] = 90,   -- % เลือดการ์ดที่ต่ำกว่านี้ถึงจะ instant kill (กติกาข้างบน)

    -- Auto Farm Mob / Boss (เลือกตัวเองจาก LevelConfig - เปิดได้ทีละโหมดกับ Auto Farm)
    ["AutoFarmMob"] = false,
    ["FarmMobName"] = "",            -- MonName ใน LevelConfig (มอนธรรมดา)
    ["MobAcceptQuest"] = false,
    ["AutoFarmBoss"] = false,
    ["FarmBossName"] = "",           -- MonName ใน LevelConfig (บอส)
    ["BossAcceptQuest"] = false,
    ["AutoBossHunt"] = false,
    ["HuntTiers"] = { Mythic = true, Legendary = true, Epic = true, Rare = true, UnCommon = true, Common = true },
    ["HuntSides"] = { Crow = true, Muzan = true },   -- Crow = ฝั่ง Slayer / Muzan = ฝั่ง Demon (Hybrid รับได้ทั้งคู่)

    -- Players
    ["WalkSpeedEnabled"] = false,
    ["WalkSpeed"] = 60,
    ["JumpPowerEnabled"] = false,
    ["JumpPower"] = 80,
    ["InfiniteJump"] = false,
    ["Noclip"] = false,
    ["InfiniteDash"] = false,
    ["InfiniteStamina"] = false,
    ["AlwaysRun"] = false,
    ["InfiniteClimb"] = false,
    ["AntiKnockback"] = false,
    ["AntiStun"] = false,
    ["NoSunDamage"] = false,

    -- Auto Use Skill (คีย์สกิลที่เลือกไว้ เช่น { "Z", "X" } - ว่าง = ไม่ใช้อะไรเลย)
    -- เก็บเป็น "คีย์" ไม่ใช่ชื่อสกิล เพราะชื่อสกิลเปลี่ยนไปตามอาวุธ/ปราณที่ถือ แต่ช่องคีย์อยู่ที่เดิมเสมอ
    ["AutoUseSkill"] = false,
    ["AutoUseSkillKeys"] = { },
    ["SkillRange"] = 60,         -- ใช้เฉพาะตอนมีศัตรูในระยะนี้ (0 = ใช้ตลอด)
    ["AutoUseSkillHold"] = { },  -- { [คีย์] = วินาทีที่กดค้าง } 0/ไม่ตั้ง = ใช้จังหวะของสกิลเอง (Config ของสกิล)
    ["SmartWeapon"] = false,     -- สกิลของอาวุธที่ถืออยู่ติดคูลดาวน์หมด = สลับไปอาวุธช่องถัดไปใน Toolbar ที่มีสกิลพร้อม

    -- Auto Sell (ขายให้ Ginzo ที่ Mistfall Harbor) - รายชื่อไอเทม + ระดับความหายากที่จะขาย
    ["AutoSell"] = false,
    ["AutoSellItems"] = { },
    ["AutoSellRarities"] = { },
    ["AutoSellKeepEquipped"] = true,  -- ไม่ขายของที่ใส่อยู่ (Toolbar + ชุด/เครื่องประดับ)
    ["AutoSellInterval"] = 5,         -- นาที

    -- Auto Fishing
    ["FishingSpot"] = "Jeso Dock",    -- "Jeso Dock" / "Where I Stand" (จุดที่ยืนตอนเปิด หันหน้าลงน้ำ)
    ["FishingUseBait"] = false,       -- ปิด = เบ็ดเปล่า (ยังได้ปลา แค่กินช้ากว่านิดหน่อย)
    ["FishingBait"] = "Best Owned",   -- เหยื่อที่จะใส่ (Best Owned = ตัว BaitTier สูงสุดที่มี)
    ["FishingAutoBuyBait"] = false,   -- เหยื่อหมด: เปิด = ซื้อ Worm ที่ Jeso / ปิด = ตกเบ็ดเปล่าต่อ
    ["AutoBestTitle"] = false,        -- หน้า Equipment: ใส่ Title ดีสุดตามสถานการณ์ (ตกปลา = Title ตกปลา / ฟาร์ม = Title ดาเมจ)
    -- toggle ตกปลาเซฟไว้ = รันสคริปต์ใหม่เปิดกลับเอง
    ["AutoFishing"] = false,
    ["AutoUnlockFishing"] = false,
    ["AutoUpgradeFishing"] = false,
    ["AutoQuestShiori"] = false,      -- เควสยาของ Shiori (Lv 70) ครั้งเดียว - ปลดร้าน Fish Head ของ Nori
    -- Misc / เควส: เซฟไว้ = รันใหม่เปิดกลับเอง
    ["AutoJewelryBox"] = false,
    ["AutoPuzzle"] = false,
    ["AutoDiscovery"] = false,

    -- แท็บ Servers (Misc): กระโดดเซิร์ฟหาเซิร์ฟที่มี Boss Hunt ตรงเงื่อนไข
    ["AutoServerHop"] = false,        -- เซฟไว้ = หลังวาร์ปไปเซิร์ฟใหม่ hub รันขึ้นมาแล้ว hop ต่อเอง
    ["HopTiers"] = { Mythic = true, Legendary = false, Epic = false, Rare = false, UnCommon = false, Common = false },
    ["HopMySide"] = true,             -- นับเฉพาะ Hunt ฝั่งที่เผ่าเรารับได้ (Muzan = Demon/Hybrid, Crow = Slayer/Hybrid)
    ["HopMinMinutes"] = 5,            -- Hunt ต้องเหลือเวลาอย่างน้อยกี่นาที (ExpiresAt)
    ["HopRegion"] = "Any",            -- Any / NA-WEST / NA-CENTRAL / NA-EAST / SA / EU / AF / AS / OCE
    ["HopTargetPlayers"] = 5,         -- Quick Hop "Hop to Target Players" = เซิร์ฟที่จำนวนคนใกล้เลขนี้สุด

    -- Breathing (ชื่อปราณที่เปิด Auto อยู่ ว่าง = ไม่ได้เปิด - เปิดได้ทีละปราณ)
    ["AutoBreathing"] = "",
    ["SelectedBreathingStyle"] = "",  -- ปราณที่เลือกไว้ใน dropdown (คนละอันกับตัวที่ Auto อยู่)
    ["FarmWeaponBreathing"] = "",     -- อาวุธตอนตีระหว่างเรียนปราณ ว่าง = ใช้ FarmWeapon
    ["FarmMethodBreathing"] = "Above", -- ตำแหน่งยืนตีระหว่างเรียนปราณ (Above / Below / Behind)
    ["FarmDistanceBreathing"] = 4,
    ["AutoDodgeBreathing"] = true,
    -- แท็บ Travel (Misc) - ตัวที่เลือกค้างไว้ใน dropdown
    ["TravelZone"] = "",
    ["TravelNpc"] = "",
    ["TravelShrine"] = "",
    ["TravelWaypoints"] = { },         -- จุดที่เซฟเอง { { Name, X, Y, Z }, ... } เรียงตามที่เซฟ
    -- แท็บ Equipment (Players): ใส่ของ Stats 5 ช่องแบบดีที่สุดตามสายที่เลือก
    ["GearPriority"] = "Auto (Skill Tree)",
    ["AutoEquipGear"] = false,
    ["AutoEquipBestWeapon"] = false,  -- ใส่อาวุธค่าดีสุด (ActiveToolStats) ตามสายเดียวกันลงช่อง Toolbar เท่านั้น ไม่ทับ Select Weapon
    ["BestWeaponSlot"] = "Auto",      -- ช่อง Toolbar ที่ใส่อาวุธดีสุด: Auto = ช่องว่าง/ทับเล่มแย่สุด, One..Five = ย้ายไปช่องนั้น
    -- Auto Drink Potion (Players): ดื่มยาที่เลือกตามเลือด/stamina + ซื้อเพิ่มจากร้านใน place นี้เมื่อหมด
    ["AutoDrinkPotion"] = false,
    ["DrinkPotions"] = { "Health Elixir", "Health Potion", "Health Regen Elixir", "Health Regen Potion" },
    ["DrinkHealthPercent"] = 50,      -- เลือด <= กี่ % ถึงดื่มยาเลือด
    ["DrinkStaminaPercent"] = 25,     -- stamina <= กี่ % ถึงดื่มยา stamina
    ["AutoBuyPotion"] = false,
    ["BuyPotionAmount"] = 5,          -- ซื้อทีละกี่ขวด (เงินไม่พอ = ลดลงจนซื้อได้)

    ["AutoUpgradeBreathingTree"] = false, -- ปลดสกิลถัดไปใน skill tree ของปราณที่มีอยู่ เมื่อแต้ม/Mastery ถึง

    -- Final Selection (timed event ทุก 2 ชม.)
    ["AutoFinalSelection"] = false,
    ["FarmWeaponTrial"] = "",          -- อาวุธที่ถือในด่าน ว่าง = ไม่เปลี่ยนที่ถืออยู่
    ["FarmMethodTrial"] = "Above",     -- ตำแหน่งยืนตีในด่าน (ค่าเริ่ม Above - Behind โดนสวนหนัก)
    ["AutoDodgeTrial"] = true,         -- หลบสกิลบอสในด่าน (Fighter อ่านผ่าน ModeSetting("AutoDodge") suffix "Trial")
    ["TrialInstantKill"] = false,      -- ฆ่ามอนในด่านทันทีที่ตีโดนแล้วได้ owner (มอนไม่ดรอปของ)
    ["TrialInstantKillHealth"] = 90,   -- instant kill เมื่อเลือดมอนเหลือ <= กี่ % (สูงสุด/ค่าเริ่มต้น 90 - กติกา Instant Kill)

    -- Ouwigahara (หอคอยในเซิร์ฟ Minigames ที่ workspace.MinigameKey = "Ouwigahara")
    ["OuwiAutoClimb"] = false,         -- Ready Up ที่ StartPad แล้วปีนหอ ตีมอนทุกชั้น
    ["OuwiInstantKill"] = true,        -- ฆ่ามอนในหอทันทีที่ตีโดนแล้วได้ owner
    ["OuwiInstantKillHealth"] = 90,    -- instant kill เมื่อเลือดมอนเหลือ <= กี่ % (สูงสุด 90)
    ["OuwiBestCard"] = true,           -- เลือกการ์ดที่คุ้มที่สุด (คะแนนคิดจากค่าของเกมจริง)
    ["OuwiAutoReroll"] = true,         -- มือนี้แย่กว่ามือใหม่ที่คาดไว้ = ใช้ตั๋ว reroll
    ["OuwiRerollKeep"] = 0,            -- เก็บตั๋ว reroll ไว้อย่างน้อยเท่านี้
    ["OuwiSkipBreak"] = true,          -- โหวตข้ามช่วงพัก 10 วิระหว่างชั้น
    ["OuwiSafeEvents"] = true,         -- หัวใจเหลือ 1 = ไม่รับ event ที่ทำให้ตายง่าย
    ["OuwiAutoExchange"] = false,      -- จบรอบแล้วแลกแต้มหอที่ Changer Zeni
    ["OuwiExchangeItem"] = "Refinement Ore",
    ["OuwiAutoLeave"] = false,         -- แลกเสร็จแล้วเดินเข้า LeavePad กลับโลกหลัก
    ["FarmWeaponOuwi"] = "",
    ["FarmMethodOuwi"] = "Above",
    ["FarmDistanceOuwi"] = 4,
    ["AutoDodgeOuwi"] = true,
}

-- getgenv().LevelConfig แบบ Haze Sea (VenuzFarm.LevelConfig) - อยู่นอก ConfigurationTable
-- ไม่ผ่าน Save/Load JSON (มี Vector3 ข้างใน เข้ารหัส JSON ไม่ได้อยู่แล้ว) แก้ตรงนี้เองได้เลย
-- หรือ getgenv().LevelConfig = {...} ทับตอนรันไทม์ก็ได้ ไม่ต้องแก้ไฟล์
--
-- เลือกเป้าแบบเดียวกับ CheckLevel ของ Haze Sea: เอา entry ที่ Level ปัจจุบัน >= .Level แล้วค่าสูงสุด
-- (ด่านที่ "ปลดล็อกแล้ว" ตัวล่าสุด ไม่ใช่ "ยังไม่ถึง" แบบเดิม) - ตัวแรกในลิสต์ควรตั้ง Level = 1 เสมอ
-- กันไม่มี entry ไหนแมตช์เลยตอนเพิ่งเริ่มเกม
--
-- Level    = เลเวลปลดล็อกด่านนี้
-- QuestName = ชื่อเควสที่ผูกกับมอนตัวนี้ (ใช้หา Id ใน Quests.Holder แม่นกว่า MonName เฉย ๆ, เว้นว่างได้ถ้าไม่มีเควส)
-- MonName  = ชื่อมอนที่ต้องฟาร์ม (ตรงกับ Model.Name ใน workspace)
-- MonPOS   = จุดยืนตี/หามอน
-- WaitPOS  = จุดรอตอนมอนตายหมด รอ respawn (ไม่ตั้ง = ใช้ MonPOS แทน)
-- QuestPOS = จุดที่ต้องไปยืนถึงจะรับเควสได้ (Ouwland เช็คระยะฝั่ง server) ไม่ตั้ง = ใช้ MonPOS แทน
--
-- พิกัดด้านล่างเป็นของจริงที่สำรวจไว้ - MonPOS/WaitPOS ของมอนวัดใหม่ 2026-09-26 (teleport ไล่ทุกจุด
-- แล้วเอาค่าเฉลี่ยตำแหน่งมอนที่เกิดจริง) ถ้ามอน/NPC ย้ายจุด ให้แก้ใหม่เอง
getgenv().LevelConfig = {
    {
        Level = 1,
        QuestName = "Ill take 3 bandits",           -- โชว์ในเกมว่า "Defeat 3 bandits"
        MonName = "Bandit",
        MonPOS = Vector3.new(-290, 1224, -1035),     -- กลาง spawn cluster ของ Bandit (วัดสด)
        WaitPOS = Vector3.new(-290, 1224, -1035),
        QuestPOS = Vector3.new(-425, 1243, -951),    -- Krue คนให้เควส
    },
    {
        Level = 7,
        QuestName = "Ill take the bandit boss(Lv 7)",   -- โชว์ในเกมว่า "Defeat The Bandit Boss" (Id ต้องตรงตัว ไม่มี s หลัง bandit)
        MonName = "Zuko",
        MonPOS = Vector3.new(-283, 1224, -1031),
        WaitPOS = Vector3.new(-283, 1224, -1031),
        QuestPOS = Vector3.new(-425, 1243, -951),
    },
    {
        Level = 10,
        QuestName = "Ill drive the bears back(Lv 10)",   -- "Hunt the Bears" | Bamboo Grove - NPC Tom
        MonName = "Bear Cub",
        MonPOS = Vector3.new(540, 1121, -1023),
        WaitPOS = Vector3.new(485, 1130, -990),
        QuestPOS = Vector3.new(507, 1124, -972),
    },
    {
        Level = 18,
        QuestName = "Ill fell the Mother Bear(Lv 18)",   -- "Fell the Mother Bear" | Bamboo Grove - NPC Tom (บอส)
        MonName = "Mother Bear",
        MonPOS = Vector3.new(540, 1121, -1023),
        WaitPOS = Vector3.new(485, 1130, -990),
        QuestPOS = Vector3.new(507, 1124, -972),
    },
    {
        Level = 26,
        QuestName = "Ill clear out his subordinates(Lv 26)",   -- "Clear Kaiden's Subordinates" | Bamboo Grove - NPC Chaka
        MonName = "Kaiden Subordinate",
        MonPOS = Vector3.new(585, 1146, -1314),
        WaitPOS = Vector3.new(635, 1158, -1303),
        QuestPOS = Vector3.new(469, 1148, -1261),
    },
    {
        Level = 34,
        QuestName = "Ill deal with Kaiden(Lv 34)",   -- "Defeat Kaiden" | Bamboo Grove - NPC Chaka (บอส)
        MonName = "Kaiden",
        MonPOS = Vector3.new(585, 1146, -1314),
        WaitPOS = Vector3.new(635, 1158, -1303),
        QuestPOS = Vector3.new(469, 1148, -1261),
    },
    {
        Level = 40,
        QuestName = "I will clear out his guards(Lv 40)",   -- "Clear Hoyuzo's Guard" | Bamboo Grove - NPC Wagwan
        MonName = "Hoyuzo Subordinate",
        MonPOS = Vector3.new(590, 1001, -1158),     -- เดิม 533,1001,-1357 คลาด 206 studs (วัดสด)
        WaitPOS = Vector3.new(590, 1001, -1158),
        QuestPOS = Vector3.new(724, 1022, -800),
    },
    {
        Level = 50,
        QuestName = "I will take care of Hoyuzo(Lv 50)",   -- "Defeat Hoyuzo" | Bamboo Grove - NPC Wagwan (บอส)
        MonName = "Hoyuzo",
        MonPOS = Vector3.new(746, 1001, -1413),
        WaitPOS = Vector3.new(733, 1005, -1345),
        QuestPOS = Vector3.new(724, 1022, -800),
    },
    {
        Level = 62,
        QuestName = "Ill clear the cave(Lv 62)",   -- "Purge Dreamfall Hollow" | Mistfall Harbor (Dreamfall Hollow) - NPC Jugg
        MonName = "Blood Hounded Demon",
        MonPOS = Vector3.new(834, 827, 876),
        WaitPOS = Vector3.new(834, 827, 876),
        QuestPOS = Vector3.new(486, 876, 1007),
    },
    {
        Level = 75,
        QuestName = "Ill thin them out(Lv 75)",   -- "Thin the Cavern Floor" | Butterfly Estate (Veilfall Cavern) - NPC Demon Slayer Goro
        MonName = "Lesser Demon",
        MonPOS = Vector3.new(-627, 242, 415),
        WaitPOS = Vector3.new(-627, 242, 415),
        QuestPOS = Vector3.new(-872, 237, 322),
    },
    {
        Level = 83,
        QuestName = "Ill go up after the greater ones(Lv 83)",   -- "Hunt the Greater Demons" | Butterfly Estate (Veilfall Cavern) - NPC Demon Slayer Goro
        MonName = "Greater Demon",
        MonPOS = Vector3.new(-425, 287, 527),
        WaitPOS = Vector3.new(-425, 287, 527),
        QuestPOS = Vector3.new(-872, 237, 322),
    },
    {
        Level = 90,
        QuestName = "Ill help you defeat them(Lv 90)",   -- "Drive Off the High Demons" | Iceveil Valley - NPC Wounded Slayer Tomoi
        MonName = "High Demon",
        MonPOS = Vector3.new(346, 1261, -1968),
        WaitPOS = Vector3.new(346, 1261, -1968),
        QuestPOS = Vector3.new(484, 1225, -1813),
    },
    {
        Level = 105,
        QuestName = "Ill drive back the frost(Lv 105)",   -- "Drive Back the Frost" | Iceveil Valley - NPC Demon Slayer Mitsu
        MonName = "Ice Profound Demon",
        MonPOS = Vector3.new(-922, 1382, -2547),
        WaitPOS = Vector3.new(-922, 1382, -2547),
        QuestPOS = Vector3.new(-784, 1383, -2520),
    },
    {
        Level = 115,
        QuestName = "Ill put out the blaze(Lv 115)",   -- "Put Out the Blaze" | Iceveil Valley - NPC Demon Slayer Mitsu
        MonName = "Fire Profound Demon",
        MonPOS = Vector3.new(-866, 1364, -2384),
        WaitPOS = Vector3.new(-866, 1364, -2384),
        QuestPOS = Vector3.new(-784, 1383, -2520),
    },
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

-- getgenv().LevelConfig ไม่อยู่ใน ConfigurationTable แล้ว (ย้ายออกแบบ Haze Sea) - เซฟตรงนี้ปกติได้เลย
function SaveConfiguration()
    if writefile and makefolder then
        if not isfolder(FolderConfiguration) then makefolder(FolderConfiguration) end

        local json = HttpService:JSONEncode(getgenv().ConfigurationTable)
        writefile(filenameConfiguration, json)
    end
end

LoadConfiguration()

-- Breathing ไม่มี Instant Kill แล้ว - ล้างค่าจากเซฟเก่า
getgenv().ConfigurationTable.BreathingInstantKill = nil
getgenv().ConfigurationTable.BreathingInstantKillHealth = nil

-- Instant Kill At Health ตั้งได้สูงสุด 90% - ค่าที่เซฟไว้เกิน (เซฟเก่า 95/100) ดึงลงมา 90 ทุกครั้งที่รัน
for _, Key in ipairs({ "TrialInstantKillHealth", "RaidInstantKillHealth" }) do
    local Value = tonumber(getgenv().ConfigurationTable[Key])
    if not Value or Value > 90 then getgenv().ConfigurationTable[Key] = 90 end
end
getgenv().ConfigurationTable.InstantKillDefault95 = nil

-- ทุกครั้งที่รันสคริปต์: ทุกโหมด (หลัก/Level/Mob/Boss/Breathing/Trial) เริ่มที่ Method Above
-- เสมอ ไม่ว่าเซฟรอบก่อนตั้งไว้อะไร (เปลี่ยนใน UI ได้ แต่รันใหม่กลับเป็นค่านี้)
-- เดินทางมีแบบเดียว = Teleport (Tween โดน anti-cheat เซิร์ฟดึงกลับ) - ล้างคีย์ Mode/Tween Speed ที่เซฟค้างไว้
for _, Suffix in ipairs({ "", "Level", "Mob", "Boss", "Hunt", "Raid", "Breathing", "Trial", "Travel" }) do
    getgenv().ConfigurationTable["FarmMode" .. Suffix] = nil
    getgenv().ConfigurationTable["TweenSpeed" .. Suffix] = nil
    if Suffix ~= "Travel" then getgenv().ConfigurationTable["FarmMethod" .. Suffix] = "Above" end
end

-- อ่านค่าตั้งของโหมดฟาร์มที่กำลังทำงานอยู่ (Level/Mob/Boss แยกแท็บ แยกคีย์เป็นของตัวเอง)
-- getgenv().ValkyrieFarmSuffix ถูกตั้งโดย SetMode ตอนสลับโหมด ("" = Camp/ไม่มีโหมดฟาร์มทำงานอยู่ -
-- ใช้คีย์เดิมไม่มีคำต่อท้าย ยังใช้ร่วมกับแท็บ Sealed Cache Raid)
local function ModeSetting(Name)
    local Suffix = getgenv().ValkyrieFarmSuffix or ""
    local Config = getgenv().ConfigurationTable
    if Suffix ~= "" and Config[Name .. Suffix] ~= nil then
        return Config[Name .. Suffix]
    end
    return Config[Name]
end

---- ============ Movement ============ ----
--
-- เดินทาง = Teleport อย่างเดียว (Tween ถูก anti-cheat ฝั่งเซิร์ฟดึงกลับ - วัดสด 2026-09-29)
-- Lock/Hold ตรึง HumanoidRootPart ทุกเฟรมบน RenderStep + noclip + ล็อกสถานะยืน + แท่นใต้เท้า กันร่วง/กันติดของ

local Movement = { }

do
    local TeleportHold = 2.5        -- วิที่ตรึงหลังวาร์ปไกล (เซิร์ฟยอมที่ 2 วิ เผื่อ ping)
    local TeleportNear = 12         -- ใกล้กว่านี้ (studs) วาร์ปแล้วปล่อยเลย
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
            -- เช็คทุกครั้ง ไม่ใช่ครั้งเดียว: ระบบล้มของเกมเปิด state คืนตอนเราลุก (RagDoll หาย) = FallingDown กลับมา
            -- ตัวลอยค้างที่จุดตีแล้วหงายล้ม (วัดสด 2026-09-30)
            local Fresh = not (GroundActive and GroundHumanoid == Humanoid)
            for _, State in ipairs(GroundStates) do
                if Fresh or Humanoid:GetStateEnabled(State) then
                    pcall(function() Humanoid:SetStateEnabled(State, false) end)
                end
            end

            -- ดึงกลับเฉพาะ state ล้มจากฟิสิกส์ - Physics/GettingUp = เกมสั่งล้มจริง (โดนตี) ปล่อยให้เล่นจบเอง
            local Current = Humanoid:GetState()
            if Current == Enum.HumanoidStateType.FallingDown or Current == Enum.HumanoidStateType.Freefall
                or Current == Enum.HumanoidStateType.Flying then
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

    --// ห้ามลอยสูงจากพื้น (ผู้ใช้ 2026-09-30 หลังโดน kick: Above 4 เหนือหัวมอนไม่โดน - ที่โดนคือลอยสูงห่างพื้นมาก)
    -- จุดที่ตรึง (Lock/Hold/Teleport) สูงกว่าความสูงยืนปกติบนพื้นใต้มันเกิน MaxHover = ดึงลงมาเหลือ MaxHover
    -- ทุกเฟรม ไม่ว่าระบบไหนส่งจุดมา (ฟาร์ม/หลบ/รอบอส/ดื่มยา/เดินทาง) - Above 4 (สูงจากยืนปกติ ~4) ไม่โดนแตะ
    -- พื้น = ยิง ray ลงจากจุดนั้น ข้ามตัวละคร/NPC และ Part ที่ทะลุได้ (CanCollide ปิด - โซน/Telegraph/Region)
    -- ใต้จุดไม่มีพื้นเลยในระยะ GroundScan (เหว/นอกแมพ) = ใช้จุดเดิม
    local MaxHover = 10
    local GroundScan = 300
    local GroundParams = RaycastParams.new()
    GroundParams.FilterType = Enum.RaycastFilterType.Exclude
    GroundParams.IgnoreWater = false
    local GroundIgnoreAt = -math.huge

    local function GroundBelow(Position)
        if os.clock() - GroundIgnoreAt > 1 then
            GroundIgnoreAt = os.clock()
            local Ignore = { }
            local Npcs = workspace:FindFirstChild("Humanoids")
            if Npcs then table.insert(Ignore, Npcs) end
            for _, Player in ipairs(Players:GetPlayers()) do
                if Player.Character then table.insert(Ignore, Player.Character) end
            end
            GroundParams.FilterDescendantsInstances = Ignore
        end
        local From = Position + Vector3.new(0, 2, 0)
        for _ = 1, 6 do
            local Hit = workspace:Raycast(From, Vector3.new(0, -GroundScan, 0), GroundParams)
            if not Hit then return nil end
            local Part = Hit.Instance
            if Part:IsA("Terrain") or (Part:IsA("BasePart") and Part.CanCollide) then
                return Hit.Position.Y
            end
            From = Hit.Position - Vector3.new(0, 0.05, 0)
        end
        return nil
    end

    local function Grounded(Goal)
        local Humanoid, Root = GetHumanoid(), GetRoot()
        if not (Humanoid and Root and typeof(Goal) == "CFrame") then return Goal end
        local Floor = GroundBelow(Goal.Position)
        if not Floor then return Goal end
        local StandY = Floor + GetFootOffset(Humanoid, Root)
        if Goal.Position.Y - StandY <= MaxHover then return Goal end
        return Goal + Vector3.new(0, StandY + MaxHover - Goal.Position.Y, 0)
    end
    Movement.Grounded = Grounded

    --// ห้ามยืน/หลบเข้าไปในกำแพง (ผู้ใช้ 2026-09-30: ตัวอยู่ใน Part = นับเป็น noclip โดน kick)
    -- ตัวละครเราปิดชนตอนตรึง (NoclipCharacter) = วางตรงไหนก็เข้าไปได้ -> เช็คเองว่าจุดนั้นว่างก่อนวาง
    -- Blocked = กล่องขนาดลำตัว (ไม่รวมเท้า - ไม่นับพื้นที่ยืน) ทับ Part ที่ชนได้ (CanCollide) ไหม
    -- PathClear = เส้นตรงระดับอกจากจุดหนึ่งไปอีกจุดไม่ผ่านกำแพง/เนินดิน (Terrain นับด้วย)
    -- ใช้ GetPartsInPart (รูปทรงชนจริง) ไม่ใช่ GetPartBoundsInBox (กรอบสี่เหลี่ยมของ Part) - วัดสด: พื้น MeshPart
    -- สูง 33 studs กรอบครอบตัวที่ยืนอยู่บนมัน = นับว่าอยู่ในกำแพง 66% ของเฟรม / รูปทรงจริง 0%
    local SpaceParams = OverlapParams.new()
    SpaceParams.FilterType = Enum.RaycastFilterType.Exclude
    SpaceParams.RespectCanCollide = true
    local Probe = Instance.new("Part")
    Probe.Size = Vector3.new(2.5, 4.5, 1.5)
    Probe.Anchored, Probe.CanCollide, Probe.CanQuery, Probe.CanTouch = true, false, false, false

    local function Blocked(Position)
        GroundBelow(Position)     -- รีเฟรชรายการ NPC/ผู้เล่นที่ข้าม (ทุก 1 วิ)
        SpaceParams.FilterDescendantsInstances = GroundParams.FilterDescendantsInstances
        Probe.CFrame = CFrame.new(Position + Vector3.new(0, 0.5, 0))
        return #workspace:GetPartsInPart(Probe, SpaceParams) > 0
    end

    local function PathClear(From, To)
        local Start = From + Vector3.new(0, 1.5, 0)
        local Offset = (To + Vector3.new(0, 1.5, 0)) - Start
        for _ = 1, 6 do
            if Offset.Magnitude < 0.5 then return true end
            local Hit = workspace:Raycast(Start, Offset, GroundParams)
            if not Hit then return true end
            local Part = Hit.Instance
            if Part:IsA("Terrain") or (Part:IsA("BasePart") and Part.CanCollide) then return false end
            local Next = Hit.Position + Offset.Unit * 0.05
            Offset = Offset - (Next - Start)
            Start = Next
        end
        return true
    end

    Movement.Blocked = Blocked
    Movement.PathClear = PathClear

    -- จุดว่างที่ใกล้ Goal ที่สุด (Goal อยู่ในหิน/กำแพง): ยกขึ้นยืนบนผิวใต้จุดนั้นก่อน (ขาจม - มอนล้มนอนบนหิน
    -- วัดสด ราก 0.2 เหนือผิวหิน) แล้วค่อยวนหารอบ ๆ 3/6/10 studs ที่มีพื้นและพื้นต่างระดับไม่เกิน 8 / ไม่เจอ = nil
    -- (วัดสด 2026-09-30: จุดรอ/จุดเกิดในตาราง (-290, 1224, -1035) อยู่ในหิน CellArenaRocks วาร์ปไปแล้วจมหินค้าง 13 วิ)
    local function Clearance(Goal)
        if typeof(Goal) ~= "CFrame" or not Blocked(Goal.Position) then return Goal end
        local Root, Humanoid = GetRoot(), GetHumanoid()
        if not (Root and Humanoid) then return nil end
        local Foot = GetFootOffset(Humanoid, Root)
        local Rotation = Goal - Goal.Position
        local Base = Goal.Position

        for _, Up in ipairs({ 6, 12 }) do
            local Floor = GroundBelow(Base + Vector3.new(0, Up, 0))
            if Floor then
                local Lifted = Vector3.new(Base.X, Floor + Foot, Base.Z)
                if Lifted.Y >= Base.Y - 1 and Lifted.Y - Base.Y <= Up + 2 and not Blocked(Lifted) then
                    return CFrame.new(Lifted) * Rotation
                end
            end
        end

        for _, Radius in ipairs({ 3, 6, 10 }) do
            for Step = 0, 7 do
                local Angle = Step * math.pi / 4
                local Point = Base + Vector3.new(math.cos(Angle) * Radius, 0, math.sin(Angle) * Radius)
                local Floor = GroundBelow(Point + Vector3.new(0, 8, 0))
                if Floor then
                    local Stand = Vector3.new(Point.X, Floor + Foot, Point.Z)
                    if math.abs(Stand.Y - Base.Y) <= 8 and not Blocked(Stand) then
                        return CFrame.new(Stand) * Rotation
                    end
                end
            end
        end
        return nil
    end
    Movement.Clearance = Clearance

    -- จุดที่ตรึงเข้าไปอยู่ในกำแพง = จุดว่างใกล้สุดรอบ ๆ (Clearance) / ไม่มี = ถอยมาตามเส้นจากตัวเรา / ไม่มีเลย = ยืนที่เดิม
    local function Free(Goal)
        if typeof(Goal) ~= "CFrame" or not Blocked(Goal.Position) then return Goal end
        local Root = GetRoot()
        if not Root then return Goal end
        local Here = Root.Position
        local Rotation = Goal - Goal.Position
        local Clear = Clearance(Goal)
        if Clear then return Clear end
        for _, Fraction in ipairs({ 0.75, 0.5, 0.25 }) do
            local Point = Here:Lerp(Goal.Position, Fraction)
            if not Blocked(Point) then return CFrame.new(Point) * Rotation end
        end
        if not Blocked(Here) then return CFrame.new(Here) * Rotation end
        return Goal
    end
    Movement.Free = Free

    -- จุดยืนบนพื้นจริงใต้/รอบ Position (ไม่ลอยเลย - ใช้กับจุดรอนาน ๆ เช่นรอบอสเกิด) / หาพื้นไม่เจอ = Position เดิม
    function Movement.GroundSpot(Position)
        if typeof(Position) == "CFrame" then Position = Position.Position end
        local Root, Humanoid = GetRoot(), GetHumanoid()
        local Floor = GroundBelow(Position + Vector3.new(0, 6, 0))
        if not (Root and Humanoid and Floor) then return CFrame.new(Position) end
        local Stand = CFrame.new(Position.X, Floor + GetFootOffset(Humanoid, Root), Position.Z)
        return Clearance(Stand) or Stand
    end
    getgenv().ValkyrieMovement = Movement     -- ทดสอบสดผ่าน dex (Blocked / PathClear / Free / SafeGroundSpot)

    -- มอนที่ไล่เราอยู่ (ObjectValue ใน Character.NpcsFollowing) + ตำแหน่ง
    local function Chasers()
        local List = { }
        local Character = GetCharacter()
        local Folder = Character and Character:FindFirstChild("NpcsFollowing")
        for _, Value in ipairs(Folder and Folder:GetChildren() or { }) do
            local Model = Value:IsA("ObjectValue") and Value.Value
            local Root = Model and Model:FindFirstChild("HumanoidRootPart")
            local Humanoid = Model and Model:FindFirstChildOfClass("Humanoid")
            if Root and Humanoid and Humanoid.Health > 0 then table.insert(List, Root.Position) end
        end
        return List
    end

    -- มอนที่ไล่เราเข้ามาใกล้กว่า Radius (แนวราบ) = ต้องถอยใหม่
    function Movement.ChaserNear(Radius)
        local Root = GetRoot()
        if not Root then return false end
        for _, At in ipairs(Chasers()) do
            if ((At - Root.Position) * Vector3.new(1, 0, 1)).Magnitude < Radius then return true end
        end
        return false
    end

    --// จุดหลบบนพื้น ห่างจากตรงนี้ Distance studs ไปทางตรงข้ามมอน (แทนลอยขึ้นฟ้า 70 studs - ผู้ใช้ 2026-09-30:
    -- ลอยสูงห่างพื้นนาน = โดน kick) ลองทิศหนีมอนก่อน แล้วค่อยเอียงทีละ 45 องศา - รับเฉพาะจุดที่มีพื้น
    -- และพื้นสูง/ต่ำจากตรงนี้ไม่เกิน 25 studs (ไม่ไปตกเหว/ขึ้นหลังคา) / ไม่เจอเลย = nil
    function Movement.SafeGroundSpot(Distance)
        local Root, Humanoid = GetRoot(), GetHumanoid()
        if not (Root and Humanoid) then return nil end
        local Here = Root.Position
        local Foot = GetFootOffset(Humanoid, Root)

        local Threats = Chasers()
        if #Threats == 0 then
            local Npcs = workspace:FindFirstChild("Humanoids")
            for _, Model in ipairs(Npcs and Npcs:GetDescendants() or { }) do
                if Model:IsA("Model") and not Players:GetPlayerFromCharacter(Model) then
                    local MobRoot = Model:FindFirstChild("HumanoidRootPart")
                    local MobHumanoid = Model:FindFirstChildOfClass("Humanoid")
                    if MobRoot and MobHumanoid and MobHumanoid.Health > 0 and (MobRoot.Position - Here).Magnitude < 60 then
                        table.insert(Threats, MobRoot.Position)
                    end
                end
            end
        end

        local Away = Vector3.zero
        for _, At in ipairs(Threats) do
            local Flat = (Here - At) * Vector3.new(1, 0, 1)
            if Flat.Magnitude > 0.1 then Away = Away + Flat.Unit end
        end
        if Away.Magnitude < 0.1 then
            Away = -Root.CFrame.LookVector * Vector3.new(1, 0, 1)
        end
        Away = Away.Magnitude > 0.1 and Away.Unit or Vector3.new(1, 0, 0)

        for _, Angle in ipairs({ 0, 45, -45, 90, -90, 135, -135, 180 }) do
            local Direction = CFrame.Angles(0, math.rad(Angle), 0):VectorToWorldSpace(Away)
            local Spot = Here + Direction * Distance
            local Floor = GroundBelow(Vector3.new(Spot.X, Here.Y + 30, Spot.Z))
            if Floor and math.abs(Floor + Foot - Here.Y) <= 25 then
                local Stand = Vector3.new(Spot.X, Floor + Foot, Spot.Z)
                -- จุดว่าง (ไม่อยู่ในกำแพง) + ไปถึงได้โดยไม่ทะลุกำแพง
                if not Blocked(Stand) and PathClear(Here, Stand) then
                    return CFrame.lookAt(Stand, Stand - Direction)
                end
            end
        end
        return nil
    end

    local LockTarget = nil        -- ตำแหน่งที่บังคับ CFrame ทุกเฟรมต่อเนื่อง (โหมด "ตามติดไม่ปล่อย" แบบ Haze Sea)
    local HoldTarget = nil        -- จุดหลบ (Auto Drink Potion) ทับ Lock/Travel/Teleport ของทุกฟาร์มจนกว่าจะปล่อย
    local RenderBound = false

    local function OnStep(Delta)
        local Character = GetCharacter()
        local Root = GetRoot()
        local Humanoid = GetHumanoid()

        if not Character or not Root or not Humanoid or Humanoid.Health <= 0 then return end

        NoclipCharacter(Character)

        -- หลบอยู่ = ตรึงที่จุดหลบ Travel ที่ค้างอยู่หยุดรอ (ฟาร์มไหนสั่ง Lock/Go มาก็ไม่ขยับ)
        if HoldTarget then
            Root.CFrame = Free(Grounded(HoldTarget))
            Root.AssemblyLinearVelocity = Vector3.zero
            Root.AssemblyAngularVelocity = Vector3.zero
            SetGroundState(true)
            UpdatePlatform(Humanoid, Root)
            return
        end

        -- Lock ค้างไว้ = บังคับ CFrame ทุกเฟรมต่อเนื่อง (ตรึงไว้ตลอดจนกว่าจะสั่งปล่อยเอง)
        -- ส่งฟังก์ชันมาได้ = คำนวณจุดใหม่ทุกเฟรม (ใช้เกาะมอนที่กำลังเดิน ไม่ให้หลุด hitbox)
        if LockTarget then
            local Goal = LockTarget

            if type(Goal) == "function" then
                local Ok, Value = pcall(Goal)
                if not (Ok and typeof(Value) == "CFrame") then return end
                Goal = Value
            end

            Root.CFrame = Free(Grounded(Goal))
            Root.AssemblyLinearVelocity = Vector3.zero
            Root.AssemblyAngularVelocity = Vector3.zero

            SetGroundState(true)
            UpdatePlatform(Humanoid, Root)
        end
    end

    -- ตรึงซ้ำหลังฟิสิกส์ (Heartbeat): RenderStep ตั้ง CFrame ก่อนฟิสิกส์ แต่ท่าสกิลของเกมใส่แรงเคลื่อนตัว
    -- (พุ่ง/ดิ่งเข้าหาจุดเล็ง) ฟิสิกส์เลยลากตัวออกจากจุดยืนก่อนส่งตำแหน่งให้เซิร์ฟ - วัดสด Greater Demon
    -- Above 4: ระหว่างเงื้อสกิล 10% ของเฟรมตัวไปอยู่ต่ำกว่ามอน 2 studs = มอน M1/Asteroid โดนเต็ม ๆ
    -- (ปิดสกิลเฟรมหลุดแค่ 0.8%) ตั้งซ้ำตรงนี้ = ตำแหน่งที่ส่งออกไปคือจุดยืนเสมอ
    local PinConnection = nil

    local function PinAfterPhysics()
        if not HoldTarget and not LockTarget then return end
        local Root, Humanoid = GetRoot(), GetHumanoid()
        if not Root or not Humanoid or Humanoid.Health <= 0 then return end

        local Goal = HoldTarget or LockTarget
        if type(Goal) == "function" then
            local Ok, Value = pcall(Goal)
            if not (Ok and typeof(Value) == "CFrame") then return end
            Goal = Value
        end

        Root.CFrame = Free(Grounded(Goal))
        Root.AssemblyLinearVelocity = Vector3.zero
        Root.AssemblyAngularVelocity = Vector3.zero
    end

    local function StartRender()
        if RenderBound then return end
        RenderBound = true
        RunService:BindToRenderStep("Valkyrie_Move", Enum.RenderPriority.Camera.Value - 1, OnStep)
        PinConnection = TrackConnection(RunService.Heartbeat:Connect(PinAfterPhysics))
    end

    local function StopRender()
        if not RenderBound or HoldTarget then return end
        RenderBound = false
        pcall(function() RunService:UnbindFromRenderStep("Valkyrie_Move") end)
        if PinConnection then
            PinConnection:Disconnect()
            PinConnection = nil
        end
    end

    -- ปล่อยตัวแล้วไม่มีใครตรึงต่อ = คืนการชน + สถานะล้ม/ร่วง ให้ยืนบนพื้นเองตามฟิสิกส์
    -- (เดิม Lock(nil) ทิ้ง noclip + ปิด Freefall ค้าง - ระหว่างรอบอส/รอ Hunt/รอเควสตัวยืน noclip เป็นนาที)
    local function ReleaseBody()
        if HoldTarget or LockTarget then return end
        SetGroundState(false)
        RestoreCollision()
        DestroyPlatform()
    end

    -- ตั้ง/ถอน Lock: ส่ง CFrame หรือ Vector3 เพื่อตรึงตำแหน่งทุกเฟรม, ส่ง nil เพื่อปล่อย
    -- ใช้ตอนต่อสู้ (ตามติดมอนไม่ให้หลุด hitbox) ต้องปล่อยเองก่อนสั่ง Dash หรือ Travel ไปที่อื่น
    function Movement.Lock(Target)
        if Target then
            if typeof(Target) == "Vector3" then
                Target = CFrame.new(Target)
            end

            if type(Target) ~= "function" and typeof(Target) ~= "CFrame" then
                Target = nil
                LockTarget = nil
                StopRender()
                ReleaseBody()
                return
            end

            LockTarget = Target
            StartRender()
        else
            LockTarget = nil
            StopRender()
            ReleaseBody()
        end
    end

    -- ตั้ง/ปล่อยจุดหลบ (ส่ง nil = ปล่อย) - ฟาร์มที่ Lock ค้างไว้กลับไปตรึงที่เดิมเอง
    function Movement.Hold(Target)
        if typeof(Target) == "Vector3" then Target = CFrame.new(Target) end
        if typeof(Target) == "CFrame" then
            HoldTarget = Target
            StartRender()
        else
            HoldTarget = nil
            if not LockTarget then
                StopRender()
                ReleaseBody()
            end
        end
    end

    -- จุดที่ Lock ค้างอยู่ตอนนี้ (Prompts.Use ขยับเข้าระยะชั่วคราวแล้วคืนจุดเดิมให้คนเรียก)
    function Movement.GetLock()
        return LockTarget
    end

    -- สคริปต์คุมตัวละครอยู่ไหม (เดินทาง/ตรึงตำแหน่ง)
    function Movement.Active()
        return RenderBound
    end

    function Movement.Cancel()
        LockTarget = nil

        StopRender()
        SetGroundState(false)
        RestoreCollision()
        DestroyPlatform()
    end

    local LastGo = nil      -- { From = จุดที่ขอ, To = จุดที่ไปยืนจริง } ของการวาร์ปครั้งล่าสุด (Movement.Go เทียบ Threshold)

    -- วาร์ปทันที ไม่ผ่าน RenderStep
    -- Hold = ตรึง CFrame ที่ปลายทางทุกเฟรมต่ออีกกี่วิ (0/nil = วาร์ปแล้วปล่อยเลย)
    -- anti-cheat เซิร์ฟดึงกลับจุดเดิมถ้าวาร์ปแล้วปล่อยทันที (วัดสด 2026-09-29 ระยะ ~1700 studs:
    -- ตรึง 0.5-1.5 วิ = โดนดึงกลับ / 2 วิขึ้นไป = อยู่ต่อทุกครั้ง)
    function Movement.Teleport(Target, Hold, ShouldContinue)
        local Root = GetRoot()
        if not Root then return false end

        if typeof(Target) == "Vector3" then
            Target = CFrame.new(Target)
        end
        local Wanted = Target.Position
        -- ปลายทางไม่ลอยสูง + ไม่อยู่ในหิน/กำแพง (จุดในตารางบางจุดอยู่ในหิน)
        Target = Grounded(Target)
        Target = Clearance(Target) or Target

        Movement.Cancel()
        if HoldTarget then return true end
        -- ระหว่างตรึงหลังวาร์ป ห้ามล้ม (Cancel เพิ่งเปิด FallingDown คืน - วัดสด: ย้ายไปมอนตัวถัดไปแล้วหงายล้ม 2.5 วิ)
        SetGroundState(true)

        local Character = GetCharacter()
        if Character then
            NoclipCharacter(Character)
        end

        Root.CFrame = Target
        Root.AssemblyLinearVelocity = Vector3.zero

        local Deadline = os.clock() + (tonumber(Hold) or 0)
        while os.clock() < Deadline do
            RunService.Heartbeat:Wait()
            if HoldTarget or GetRoot() ~= Root then break end
            if ShouldContinue and not ShouldContinue() then break end
            -- พื้นปลายทางเพิ่งโหลด (streaming) = ดึงลงใหม่ทุกเฟรม + ออกจากหิน/กำแพงที่เพิ่งโหลดมา
            Target = Grounded(Target)
            Target = Clearance(Target) or Target
            Root.CFrame = Target
            Root.AssemblyLinearVelocity = Vector3.zero
            Root.AssemblyAngularVelocity = Vector3.zero
            SetGroundState(true)
        end

        -- วาร์ปเสร็จแล้วไม่มีใครตรึงต่อ = คืนการชน/สถานะล้มให้ตัว ยืนเองบนพื้นตามฟิสิกส์ปกติ
        -- (เดิมทิ้ง noclip + ปิด Freefall ค้างไว้จนกว่าคนเรียกจะ Cancel เอง - ลูปรอบอส/รอ Hunt ไม่เรียก
        -- ตัวเลยยืนแบบ noclip ค้างเป็นนาที ๆ ระหว่างรอ)
        if not HoldTarget and not LockTarget and GetRoot() == Root then
            RestoreCollision()
            SetGroundState(false)
            DestroyPlatform()
        end
        LastGo = { From = Wanted, To = Root.Position }

        return true
    end

    -- ไปที่จุดหมาย = วาร์ป + ตรึงไว้ TeleportHold วิ (ระยะใกล้ไม่ต้องตรึง - แค่ขยับเข้าหา prompt/มอน)
    -- Threshold = อยู่ใกล้จุดหมายไม่เกินเท่านี้แล้วไม่ต้องวาร์ปซ้ำ (เดิมไม่ใช้ = ลูปรอบอส/จุดเควสวาร์ปทับที่เดิม
    -- ทุกเฟรม) - จุดหมายเดิมที่เคยวาร์ปไปแล้วเทียบกับจุดที่ไปยืนจริง (Grounded/Clearance ขยับจุดให้)
    function Movement.Go(Target, Threshold, _, ShouldContinue)
        local Root = GetRoot()
        if not Root then return false end
        local Goal = typeof(Target) == "CFrame" and Target.Position or Target
        if typeof(Goal) ~= "Vector3" then return false end
        Threshold = tonumber(Threshold)
        if Threshold and not HoldTarget then
            local Near = Goal
            if LastGo and (LastGo.From - Goal).Magnitude < 1 then Near = LastGo.To end
            if (Root.Position - Near).Magnitude <= math.max(Threshold, 3) then
                if not LockTarget then Movement.Cancel() end
                return true
            end
        end
        local Far = (Root.Position - Goal).Magnitude > TeleportNear
        return Movement.Teleport(Target, Far and TeleportHold or 0, ShouldContinue)
    end
end

---- ============ Prompt (ProximityPrompt) ============ ----
--
-- กด prompt ทุกระบบต้องหันกล้องไปหามันก่อนเสมอ - บางเครื่อง/บางผู้เล่นกล้องไม่หัน prompt ไม่โชว์
-- (engine ไม่ยิง PromptShown) กดแล้วเกมไม่นับ (ดูโน้ต Parkour: คันโยกขึ้นเฉพาะตอนกล้องมองเห็น)
-- Prompts.Aim = ตรึงกล้องมองจุด prompt ทุกเฟรม (ผูกหลังกล้องของเกม Camera+1 เลยไม่โดนเขียนทับ)
-- Prompts.Use = หันกล้อง -> รอให้ขึ้น -> กด (HoldDuration > 0 = InputHoldBegin ค้างจริงครบเวลา
--              fireproximityprompt ข้ามเช็ค HoldBegan ของเกม) -> ปล่อยกล้องคืน
local Prompts = { }
do
    local AimCount = 0
    local AimTarget = nil
    local AimName = "Valkyrie_PromptAim"

    function Prompts.Position(Target, Fallback)
        local Holder = Target and Target.Parent
        if Holder and Holder:IsA("Attachment") then return Holder.WorldPosition end
        if Holder and Holder:IsA("BasePart") then return Holder.Position end
        if Holder and Holder:IsA("Model") then
            local Ok, Pivot = pcall(Holder.GetPivot, Holder)
            if Ok then return Pivot.Position end
        end
        return Fallback
    end

    local function OnAim()
        local Camera = workspace.CurrentCamera
        local Root = Movement.GetRoot()
        local At = AimTarget
        if typeof(At) == "Instance" then At = Prompts.Position(At) end
        if not (Camera and Root and typeof(At) == "Vector3") then return end

        -- กล้องอยู่หลังตัวละคร (ฝั่งตรงข้าม prompt) สูงขึ้นนิด มองตรงไปที่ prompt
        local Flat = Vector3.new(Root.Position.X - At.X, 0, Root.Position.Z - At.Z)
        local Back = Flat.Magnitude > 0.1 and Flat.Unit or Vector3.new(0, 0, 1)
        local Eye = Root.Position + Back * 6 + Vector3.new(0, 3, 0)
        Camera.CFrame = CFrame.lookAt(Eye, At)
    end

    -- คืนฟังก์ชันปล่อยกล้อง (เรียกซ้อนได้ - ปล่อยครบทุกคนค่อยคืนกล้องให้เกม)
    function Prompts.Aim(Target)
        AimTarget = Target
        AimCount += 1
        if AimCount == 1 then
            pcall(function()
                RunService:BindToRenderStep(AimName, Enum.RenderPriority.Camera.Value + 1, OnAim)
            end)
        end

        local Released = false
        return function()
            if Released then return end
            Released = true
            AimCount = math.max(AimCount - 1, 0)
            if AimCount == 0 then
                AimTarget = nil
                pcall(function() RunService:UnbindFromRenderStep(AimName) end)
            end
        end
    end

    local PromptService = game:GetService("ProximityPromptService")

    -- prompt ที่ engine โชว์อยู่ตอนนี้ (ทั้งเกม) - ต่อ Target.PromptShown ทีหลังพลาดตัวที่โชว์ค้างมาก่อน
    local Visible = setmetatable({ }, { __mode = "k" })
    table.insert(SessionConnections, PromptService.PromptShown:Connect(function(Prompt) Visible[Prompt] = true end))
    table.insert(SessionConnections, PromptService.PromptHidden:Connect(function(Prompt) Visible[Prompt] = nil end))

    function Prompts.Shown(Target)
        return Visible[Target] == true
    end

    -- เหมือน Farm.WaitFor (Farm ประกาศทีหลังบล็อกนี้) - รอทีละเฟรมจน Check จริง / หมดเวลา / Continue เท็จ
    local function Farm_WaitFor(Check, Timeout, Continue)
        local Deadline = os.clock() + (Timeout or 1)
        repeat
            if Check and Check() then return true end
            if Continue and not Continue() then return false end
            task.wait()
        until os.clock() >= Deadline
        return Check ~= nil and Check() == true
    end

    local function RootDistance(Target)
        local Root = Movement.GetRoot()
        local At = Prompts.Position(Target)
        if not (Root and At) then return math.huge end
        return (At - Root.Position).Magnitude
    end

    -- ให้ prompt เราโชว์แน่ ๆ ระหว่างกด (ตั้งค่าฝั่ง client ชั่วคราว คืนค่าเดิมตอนจบ):
    --   Exclusivity = AlwaysShow: ทุก prompt ในเกมเป็น T + OnePerButton ตัวใกล้กว่าแย่งโชว์ (เช่นร้าน Jeso)
    --     ยืนยันสด 2026-09-29: ตั้ง AlwaysShow แล้วโชว์ทันที ตัวที่โชว์อยู่ก่อนไม่หาย - ไม่ต้องปิด prompt อื่น
    --     (เดิมปิด Enabled ตัวอื่น = สแกนทั้ง workspace ทุกครั้งที่กด และตอนคืนเปิดทับตัวที่เซิร์ฟปิดไปแล้ว)
    --   RequiresLineOfSight = false: ของบังนิดเดียว prompt ไม่ขึ้น
    --   Reach = ขยาย MaxActivationDistance ฝั่ง client (ของที่แกว่งตรงขอบระยะ = prompt โชว์-ซ่อนรัว hold หลุด)
    -- คืนค่าเฉพาะ property ที่ยังเป็นค่าที่เราตั้ง (เซิร์ฟเปลี่ยนเองระหว่างกด = ใช้ค่าของเซิร์ฟ)
    local function Isolate(Target, Reach)
        local Changed = { }
        local function Set(Property, Value)
            local Ok, Old = pcall(function() return Target[Property] end)
            if not Ok or Old == Value then return end
            if pcall(function() Target[Property] = Value end) then
                table.insert(Changed, function()
                    if Target[Property] == Value then Target[Property] = Old end
                end)
            end
        end
        Set("Exclusivity", Enum.ProximityPromptExclusivity.AlwaysShow)
        Set("RequiresLineOfSight", false)
        if tonumber(Reach) and Reach > 0 then
            Set("MaxActivationDistance", Target.MaxActivationDistance + Reach)
        end
        return function()
            for Index = #Changed, 1, -1 do pcall(Changed[Index]) end
        end
    end

    -- กดทีละตัวทั้งสคริปต์: กดค้างสองตัวพร้อมกันติดแค่ตัวเดียว + กล้อง (Aim) มีเป้าเดียว
    -- (เดิมฟาร์ม/เก็บของ/ตกปลากดชนกัน = กล้องสลับไปมา hold ของอีกตัวหลุด)
    local Busy = false

    -- Options:
    --   Hold     = บังคับกดค้าง (ปกติดูจาก HoldDuration)
    --   Wait     = เวลารอ prompt ขึ้นก่อนกด (ค่าเริ่ม 0.4)
    --   Continue = ฟังก์ชัน คืน false = เลิกกลางคัน
    --   Check    = ฟังก์ชัน คืน true = กดติดแล้ว (เช่นของเข้ากระเป๋า) - ไม่ส่ง = prompt หาย/ถูกปิด/Triggered
    --   Tries    = จำนวนรอบที่ลองกด (ค่าเริ่ม 3) - hold หลุดเพราะ prompt ซ่อนแว้บไม่นับรอบ (จำกัด 6 ครั้ง)
    --   NoMove   = ห้ามขยับเข้าระยะเอง (ตัวถูกเซิร์ฟตรึงอยู่ เช่นตอนตกปลา)
    --   Reach    = ขยายระยะโชว์ฝั่ง client กี่ studs (ของแกว่งตรงขอบระยะ เช่นปลาห้อยสาย)
    -- กดไม่ติดเป็นบางครั้ง (ยืนยันสด: Triggered ฝั่ง client ไม่ขึ้นทั้งที่เซิร์ฟรับแล้ว / fireproximityprompt จาก
    -- ไกล Triggered ขึ้นแต่เซิร์ฟไม่รับเพราะเกินระยะ) = เชื่อผลจริงแทน แล้วลองซ้ำจนติด
    function Prompts.Use(Target, Options)
        if not (Target and Target.Parent) then return false end
        Options = Options or { }
        local Continue = Options.Continue
        local function Stopped() return Continue ~= nil and not Continue() end

        if Busy and not Farm_WaitFor(function() return not Busy end, 10, Continue) then return false end
        if not Target.Parent then return false end
        Busy = true

        local Tries = Options.Tries or 3
        local Duration = tonumber(Target.HoldDuration) or 0
        local IsHold = Duration > 0 or Options.Hold == true
        local Max = tonumber(Target.MaxActivationDistance) or 10

        local Triggered = false
        local Shown, ShownAt, Hides = Visible[Target] == true, 0, 0
        local Connections = {
            Target.Triggered:Connect(function() Triggered = true end),
            Target.PromptShown:Connect(function() Shown, ShownAt = true, os.clock() end),
            Target.PromptHidden:Connect(function() Shown, Hides = false, Hides + 1 end),
        }

        local function Done()
            if Options.Check then
                local Ok, Result = pcall(Options.Check)
                return Ok and Result == true
            end
            return Triggered or not Target.Parent or not Target.Enabled
        end

        local Release = Prompts.Aim(Target)
        local Restore = Isolate(Target, Options.Reach)
        local PreviousLock, Moved = nil, false

        local Ok, Success = pcall(function()
            local Try, Restarts = 0, 0
            while Try < Tries do
                Try += 1
                if Stopped() or not Target.Parent then return false end
                if not Target.Enabled then
                    -- ปิดอยู่ (เพิ่งกดติดไปแล้ว หรือยังไม่พร้อม) - รอสั้น ๆ ให้เปิด
                    Farm_WaitFor(function() return Target.Enabled or not Target.Parent end, 0.6, Continue)
                    if not (Target.Parent and Target.Enabled) then return false end
                end

                -- เกินระยะ (ตัวยังไหล/ยืนขอบ) = ขยับเข้าใกล้ชั่วคราว (ไม่เกินครึ่งระยะกด) แล้วคืนจุด Lock เดิม
                if not Options.NoMove and RootDistance(Target) > Max - 1.5 then
                    local At = Prompts.Position(Target)
                    local Root = Movement.GetRoot()
                    if At and Root then
                        if not Moved then PreviousLock, Moved = Movement.GetLock(), true end
                        local Flat = Vector3.new(Root.Position.X - At.X, 0, Root.Position.Z - At.Z)
                        local Side = Flat.Magnitude > 0.1 and Flat.Unit or Vector3.new(0, 0, 1)
                        local Stand = At + Side * math.min(3, Max * 0.4) + Vector3.new(0, 1, 0)
                        Movement.Lock(CFrame.lookAt(Stand, Vector3.new(At.X, Stand.Y, At.Z)))
                        Farm_WaitFor(function() return RootDistance(Target) <= Max - 1.5 end, 1, Continue)
                        Farm_WaitFor(nil, 0.15, Continue)    -- ให้เซิร์ฟเห็นตำแหน่งใหม่ก่อนกด
                    end
                end

                -- รอ prompt ขึ้นจริง (กล้องหัน + เข้าระยะ) - ไม่ขึ้นก็กดต่อ (engine อาจยังนับ hold ได้)
                Farm_WaitFor(function() return Shown end, Options.Wait or 0.4, Continue)
                if Stopped() then return false end

                Triggered = false
                if IsHold then
                    -- prompt ต้องนิ่งก่อนกด: Isolate (AlwaysShow / ปิด LOS / ขยายระยะ) ทำ engine ซ่อน-โชว์ใหม่ทีนึง
                    -- กดค้างตอนนั้น = hold หลุดทันที (วัดสดตอนเก็บปลา: holdBegan แล้ว hidden 0.1 วิ ต่อมา)
                    if Shown then
                        Farm_WaitFor(function() return Shown and os.clock() - ShownAt >= 0.12 end, 0.5, Continue)
                    end
                    -- กดค้างจริงครบเวลา (เซิร์ฟเช็คเวลาค้างผ่าน PromptHeld - fireproximityprompt ไม่ผ่าน)
                    local HidesBefore = Hides
                    pcall(function() Target:InputHoldBegin() end)
                    local HoldEnd = os.clock() + Duration + 0.25
                    while os.clock() < HoldEnd and Target.Parent and Target.Enabled and not Stopped()
                        and Hides == HidesBefore and not Triggered do
                        task.wait()
                    end
                    pcall(function() Target:InputHoldEnd() end)
                    -- prompt หายกลางกด = hold หลุดแล้ว เริ่มใหม่ทันทีที่โผล่ (ไม่นับเป็นรอบ ไม่งั้นรอบหมดไว
                    -- แล้วคนเรียกต้องวนกลับมาใหม่ช้า ~2 วิ - วัดสดตอนปลาแกว่งขอบระยะ)
                    if Hides ~= HidesBefore and not Triggered and not Done() then
                        if Restarts < 6 then Restarts, Try = Restarts + 1, Try - 1 end
                        Farm_WaitFor(function() return Shown or not Target.Parent end, 1, Continue)
                        continue
                    end
                else
                    -- กดแบบคน (InputHold) ก่อน - รอบหลังเสริม fireproximityprompt (ตอนนี้อยู่ในระยะแล้ว เซิร์ฟรับ)
                    pcall(function()
                        Target:InputHoldBegin()
                        task.wait(0.05)
                        Target:InputHoldEnd()
                    end)
                    if Try > 1 and fireproximityprompt then pcall(fireproximityprompt, Target) end
                end

                if Farm_WaitFor(Done, 0.6, Continue) then return true end
            end
            return false
        end)

        for _, Connection in ipairs(Connections) do Connection:Disconnect() end
        Restore()
        Release()
        if Moved then Movement.Lock(PreviousLock) end
        Busy = false
        if not Ok then warn("[Prompts.Use]", Success) end
        return (Ok and Success == true) or Done()
    end

    getgenv().ValkyriePrompts = Prompts     -- ดูสด/ทดสอบผ่าน dex
end

---- ============ Farm Helpers ============ ----
--
-- ศัตรูอยู่ workspace.Humanoids.Regions.<ภูมิภาค>.ActiveNpcs.<ชื่อ>.<โมเดล> (มี Humanoid)
-- Streaming เปิดอยู่ โมเดลโผล่เฉพาะที่อยู่ใกล้
-- ท่าโจมตีเป็นฝั่งเซิร์ฟ (SignalEvent "Combat_Service") เซิร์ฟคำนวณ hitbox จากตำแหน่งตัวละครเอง

local Farm = { }

-- ระบบฟาร์มรอด้วย task.wait() (ทีละเฟรม) อย่างเดียว - ไม่ task.wait(เลข) ค้างทั้งลูป
-- รอสถานะจากเซิร์ฟ = เช็คทุกเฟรมจนเปลี่ยน (จบทันทีที่ได้ ไม่รอเต็มเวลา) / Timeout = เพดานกันค้าง
-- Continue() เป็นเท็จ (ปิดฟาร์ม) = เลิกรอทันที
function Farm.WaitFor(Done, Timeout, Continue)
    local Deadline = os.clock() + (Timeout or 1)
    repeat
        if Done and Done() then return true end
        if Continue and not Continue() then return false end
        task.wait()
    until os.clock() >= Deadline
    return Done ~= nil and Done() == true
end

-- หน่วงเวลาที่เซิร์ฟต้องใช้จริง (ไม่มีสัญญาณให้เช็ค เช่นรอเซิร์ฟเห็นตำแหน่งใหม่) - ทีละเฟรม เลิกได้ทุกเฟรม
function Farm.Sleep(Seconds, Continue)
    return Farm.WaitFor(nil, Seconds, Continue)
end

do
    local function GlobalModule(Name)
        local Ok, Module = pcall(function()
            return require(ReplicatedStorage:WaitForChild("CAM"):WaitForChild("Global"):WaitForChild(Name))
        end)

        return Ok and Module or nil
    end

    local SlotNames = { "One", "Two", "Three", "Four", "Five" }

    -- อ่านไอเทมใน Toolbar (ช่อง 1-5) เป็น { [เลขช่อง] = ชื่อไอเทม } - ใช้ร่วมกันทั้ง
    -- GetWeaponNames (โชว์ dropdown) และ EquipWeapon (หาว่าอาวุธนี้อยู่ช่องไหน)
    function Farm.GetToolbar()
        local Utility = GlobalModule("Utility")
        local Provider = GlobalModule("Character_info_provider")
        local List = { }
        if not (Utility and Provider) then return List end

        local Ok, Toolbar = pcall(function()
            return Utility.GetData(LocalPlayer, true).Inventory.Toolbar
        end)
        if not Ok then return List end

        for _, Slot in ipairs(Toolbar:GetChildren()) do
            local SlotNumber = table.find(SlotNames, Slot.Name)
            local Ok2, Item = pcall(Provider.GetItemFromId, LocalPlayer, Slot.Value)
            if SlotNumber and Ok2 and Item and Item.Name then
                List[SlotNumber] = Item.Name
            end
        end

        return List
    end

    function Farm.GetWeaponNames()
        local Names = { }
        local Seen = { }

        for _, Name in pairs(Farm.GetToolbar()) do
            if not Seen[Name] then
                Seen[Name] = true
                table.insert(Names, Name)
            end
        end

        return Names
    end

    --// "Best Weapon" (ผู้ใช้ 2026-10-01): ตัวเลือกแรกของทุก Select Weapon = ถือเล่มที่ดีที่สุดใน Toolbar ตอนนี้
    -- (Farm.BestM1Weapon: dmg/s ของ M1 จากค่าจริง ActiveToolStats + จังหวะคอมโบ Combat_presets) เปลี่ยนตาม Toolbar เอง
    -- (หอ Ouwigahara ได้อาวุธใหม่จากการ์ดกลางรอบ = เปลี่ยนไปถือเล่มที่แรงกว่าทันที)
    Farm.BestChoice = "Best Weapon"
    function Farm.WeaponChoices()
        local Names = Farm.GetWeaponNames()
        table.sort(Names)   -- dropdown ใช้ KeepOrder (ไม่งั้นเรียงตัวอักษร Best Weapon หลุดจากบนสุด)
        table.insert(Names, 1, Farm.BestChoice)
        return Names
    end

    -- ดักการเปลี่ยนของ Toolbar/กระเป๋าให้ลิสต์อาวุธรีเฟรชเอง (ไม่ต้องกดปุ่ม) - คืน list connection
    -- Inventory.Inventory = ไอเทมที่ถืออยู่ (ChildAdded/ChildRemoved เมื่อได้/เสียของ)
    -- Inventory.Toolbar   = ช่อง 1-5 (NumberValue ต่อช่อง สลับอาวุธ = Value เปลี่ยน เลยต้องดัก .Changed ต่อช่อง)
    -- ข้อมูลเซฟอาจยังไม่โหลดตอนสคริปต์เริ่ม - คืน nil ถ้ายังหาโฟลเดอร์ไม่เจอ ให้ผู้เรียกลองใหม่
    function Farm.WatchWeapons(OnChange)
        local Utility = GlobalModule("Utility")
        if not Utility then return nil end

        local Ok, Inventory = pcall(function()
            return Utility.GetData(LocalPlayer, true).Inventory
        end)
        local Items = Ok and Inventory and Inventory:FindFirstChild("Inventory")
        local Toolbar = Ok and Inventory and Inventory:FindFirstChild("Toolbar")
        if not (Items and Toolbar) then return nil end

        local Connections = { }

        local function Watch(Folder, OnAdded)
            table.insert(Connections, Folder.ChildAdded:Connect(function(Child)
                if OnAdded then OnAdded(Child) end
                OnChange()
            end))
            table.insert(Connections, Folder.ChildRemoved:Connect(OnChange))
        end

        local function WatchSlot(Slot)
            if Slot:IsA("ValueBase") then
                table.insert(Connections, Slot.Changed:Connect(OnChange))
            end
        end

        Watch(Items)
        Watch(Toolbar, WatchSlot)

        for _, Slot in ipairs(Toolbar:GetChildren()) do
            WatchSlot(Slot)
        end

        return Connections
    end

    -- ถืออาวุธที่เลือก: ตั้ง Items_Config.Equipped เป็นเลขช่อง เกมยิง Item_Equip ให้เอง
    function Farm.EquipWeapon(Name)
        -- อาวุธ M1 จริงมาจาก Farm.M1Weapon (Select Weapon ของแท็บก่อน ไม่มีใน Toolbar = Best M1 Weapon)
        Name = Farm.M1Weapon and Farm.M1Weapon(Name) or Name
        -- Auto Equip Best Weapon (แท็บ Equipment) + ช่องที่ตั้งไว้ = ถือจากช่องนั้น (มีหลายเล่มชื่อเดียวกัน)
        if Name == Farm.BestWeapon and getgenv().ConfigurationTable.AutoEquipBestWeapon and type(Farm.BestWeapon) == "string" and Farm.BestWeapon ~= "" then
            local Slot = Farm.BestWeaponSlot
            if Slot and Farm.GetToolbar()[Slot] == Name then
                local Items = LocalPlayer:FindFirstChild("Items_Config")
                local Equipped = Items and Items:FindFirstChild("Equipped")
                if Equipped and not Farm.SwapLock and not (getgenv().ConfigurationTable.SmartWeapon and getgenv().ConfigurationTable.AutoUseSkill) then
                    if Equipped.Value ~= Slot then Equipped.Value = Slot end
                    return true
                end
            end
        end
        if type(Name) ~= "string" or Name == "" then return false end
        -- Smart Weapon คุมอาวุธในมือเอง (หมุนตามคูลดาวน์สกิล) - ลูปฟาร์มห้ามดึงกลับไปอาวุธที่ตั้งไว้
        local Config = getgenv().ConfigurationTable
        if Farm.SwapLock or (Config.SmartWeapon and Config.AutoUseSkill) then return false end

        local Config = LocalPlayer:FindFirstChild("Items_Config")
        local Equipped = Config and Config:FindFirstChild("Equipped")
        if not Equipped then return false end

        for Slot, ItemName in pairs(Farm.GetToolbar()) do
            if ItemName == Name then
                if Equipped.Value ~= Slot then
                    Equipped.Value = Slot
                end
                return true
            end
        end

        return false
    end

    local Directions = {
        ["Above"] = Vector3.new(0, 1, 0),
        ["Below"] = Vector3.new(0, -1, 0),
        ["Behind"] = Vector3.new(0, 0, 1),
    }

    Farm.Methods = { "Above", "Below", "Behind" }

    -- จุดห่างจากมอนตาม Method: Above/Below ใช้แกนโลก (ไม่ใช่แกน up ของมอน - มอนล้ม RagDoll ตัวเอียง
    -- แกน up ชี้ไปด้านข้าง จุด "เหนือหัว" เลยเหวี่ยงไปข้างตัว วัดสด Greater Demon: หันหน้าเพี้ยนกลางคอมโบ)
    -- Behind ใช้ทิศหน้ามอนแบบแบนราบ (ตัดแกน Y) - เอียงแค่ไหนก็ยังเป็นด้านหลังระดับเดียวกับมอน
    local function FlatLook(MobCFrame)
        local Look = MobCFrame.LookVector
        local Flat = Vector3.new(Look.X, 0, Look.Z)
        if Flat.Magnitude < 0.1 then
            Look = MobCFrame.UpVector
            Flat = Vector3.new(Look.X, 0, Look.Z)
        end
        return Flat.Magnitude < 0.1 and Vector3.new(0, 0, -1) or Flat.Unit
    end

    function Farm.OffsetFromMob(MobCFrame, Distance)
        local Method = ModeSetting("FarmMethod")
        if Method == "Behind" then
            return MobCFrame.Position - FlatLook(MobCFrame) * Distance
        end
        return MobCFrame.Position + (Directions[Method] or Directions.Above) * Distance
    end

    -- ตำแหน่งยืนโจมตีเทียบกับมอน หันหน้าเข้าหามอนเสมอ
    -- กำลังจะยิงสกิล (Auto Use Skill ตั้ง Farm.SkillClose) = ยืนหน้าเป้าระดับเดียวกันใกล้ ๆ แทนจุดตีปกติ
    -- (ยิงจากจุด Above ลอยเหนือหัว ท่าพุ่ง/ฟันแนวนอนออกไปไม่โดน) ตัวล็อกทุกตัวเรียกฟังก์ชันนี้ทุกเฟรม = ย้ายทันที
    Farm.SkillClose = false
    Farm.SkillCloseDistance = 3

    -- โซนที่ห้ามออก { Center = Vector3, Radius = studs แนวราบ } (Final Selection: Rescue and Hold the Zone -
    -- ออกนอกโซนหลอดรีเป็น 0) ตั้งไว้ = จุดยืนตี/จุดหลบทุกจุดถูกดึงกลับเข้าในโซน
    Farm.StandZone = nil

    function Farm.ClampToZone(Position)
        local Zone = Farm.StandZone
        if not Zone then return Position end
        local Flat = (Position - Zone.Center) * Vector3.new(1, 0, 1)
        if Flat.Magnitude <= Zone.Radius then return Position end
        return Vector3.new(Zone.Center.X, Position.Y, Zone.Center.Z) + Flat.Unit * Zone.Radius
    end

    function Farm.BuildStandCFrame(MobCFrame, Distance)
        if Farm.SkillClose then
            local Position = Farm.ClampToZone(MobCFrame.Position + FlatLook(MobCFrame) * Farm.SkillCloseDistance)
            return CFrame.lookAt(Position, Vector3.new(MobCFrame.Position.X, Position.Y, MobCFrame.Position.Z))
        end

        Distance = Distance or tonumber(ModeSetting("FarmDistance")) or 8

        local Position = Farm.ClampToZone(Farm.OffsetFromMob(MobCFrame, Distance))
        local Focus = MobCFrame.Position
        local Direction = Focus - Position

        if Direction.Magnitude < 0.1 then
            return CFrame.new(Position)
        end

        local Up = Vector3.new(0, 1, 0)
        if math.abs(Direction.Unit.Y) > 0.99 then
            Up = FlatLook(MobCFrame)
        end

        return CFrame.lookAt(Position, Focus, Up)
    end

    ---- combat + progression remotes ----

    local SignalEvent
    do
        local Ok, Module = pcall(function()
            return HubSignal(require(ReplicatedStorage.Communication.ServerAndClient.Signals.SignalEvent))
        end)
        SignalEvent = Ok and Module or nil
    end

    -- บั๊กเดิม: PlayerProgression.GetLevel(player) ไม่ใช่ Level ตัวละคร - เป็นระบบ tier
    -- perk แยกของ Slayer/Demon (สูงสุดแค่ 4 ชั้น) แถมต้องส่ง side ("Slayer"/"Demon") เป็น arg ที่ 2
    -- ไม่งั้น default คืน 1 เสมอ - Level จริงที่โชว์ในเกม ("Lv 10") ไม่มี NumberValue ฝั่ง client
    -- เลย ต้องอ่านจาก PlayerGui ตรง ๆ (HUD คำนวณเองจาก Data.Exp ฝั่ง server อยู่แล้ว เชื่อถือได้)
    -- โครง: PlayerGui.ComponentsHolder.LeftHudPortion.ExpFrame.Context.Level.Text = "Lv <n>"
    local function GetLevelLabel()
        local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local Holder = PlayerGui and PlayerGui:FindFirstChild("ComponentsHolder")
        local HudPortion = Holder and Holder:FindFirstChild("LeftHudPortion")
        local ExpFrame = HudPortion and HudPortion:FindFirstChild("ExpFrame")
        local Context = ExpFrame and ExpFrame:FindFirstChild("Context")
        local Label = Context and Context:FindFirstChild("Level")
        return Label and Label:IsA("TextLabel") and Label.Text or nil
    end

    function Farm.GetLevel()
        local Text = GetLevelLabel()
        if not Text then return 0 end
        return tonumber(Text:match("%d+")) or 0
    end

    -- ไม่มีสัญญาณ "ถึง Level Max" ที่เชื่อถือได้จาก client (ไม่เจอ cap เลข/ข้อความ MAX ใน HUD)
    -- ปล่อย false ไว้ก่อน - ปลอดภัยกว่าเดา (ของเดิมก็ false เสมออยู่แล้วเพราะบั๊ก GetLevel ค้างที่ 1)
    function Farm.IsMaxLevel()
        return false
    end

    -- มอนอยู่ workspace.Humanoids.Regions.<region>.ActiveNpcs.<name>.<model> (มี Humanoid)
    -- ลูปฟาร์มเรียกหลายรอบต่อเฟรม (เลือกเป้า/เช็คบอส/ประเมินภัยรอบตัว) - กวาดทั้งแมพครั้งเดียวต่อ
    -- MobScanTTL แล้วใช้ลิสต์เดิมซ้ำ (ผู้เรียกเช็ค Farm.IsMobAlive เองก่อนใช้อยู่แล้ว)
    local MobScan = { At = -1, List = nil }
    local MobScanTTL = 0.05

    local function IterMobs()
        if MobScan.List and os.clock() - MobScan.At < MobScanTTL then
            return MobScan.List
        end

        local List = { }
        MobScan.At, MobScan.List = os.clock(), List
        local Root = workspace:FindFirstChild("Humanoids")
        local Regions = Root and Root:FindFirstChild("Regions")
        if not Regions then return List end

        for _, Region in ipairs(Regions:GetChildren()) do
            local Active = Region:FindFirstChild("ActiveNpcs")
            if Active then
                for _, Folder in ipairs(Active:GetChildren()) do
                    local Model = Folder:FindFirstChildOfClass("Model")
                    local Humanoid = Model and Model:FindFirstChildOfClass("Humanoid")
                    local MobRoot = Model and Model:FindFirstChild("HumanoidRootPart")
                    if Humanoid and MobRoot and Humanoid.Health > 0 then
                        -- โฟลเดอร์ ActiveNpcs.<ชื่อ> ของบอสมี Configuration "BossInfo" ต่อท้าย
                        -- (มอนธรรมดาอย่าง Bandit/Civilian ไม่มี) - ยืนยันสดผ่าน dex_tree แล้ว (Zuko มี, Bandit ไม่มี)
                        local IsBoss = Folder:FindFirstChild("BossInfo") ~= nil
                        table.insert(List, { Model = Model, Root = MobRoot, Humanoid = Humanoid, IsBoss = IsBoss })
                    end
                end
            end
        end

        return List
    end
    Farm.IterMobs = IterMobs

    function Farm.IsMobAlive(Entry)
        return Entry and Entry.Model and Entry.Model.Parent
            and Entry.Humanoid and Entry.Humanoid.Health > 0
    end

    -- Instant kill (อัดจากสคริปต์ค่ายอื่นสด ๆ ตี Bandit): ตี M1 โดน 1 ที เซิร์ฟโยน network owner ของมอน
    -- มาให้คนตี (isnetworkowner(HumanoidRootPart) = true) ระหว่างนั้น state ของ Humanoid replicate จากเรา
    -- สั่ง ChangeState(Dead) = เซิร์ฟเห็นมอนตายทันที ไม่ผ่านดาเมจ = ไม่ดรอปของ (โมเดลโดนลบทิ้งเลย)
    -- ไม่ได้ owner = ทำอะไรไม่ได้ คืน false ให้ตีต่อตามปกติจนได้ owner ในจังหวะถัดไป
    function Farm.TryInstantKill(Entry)
        if not Farm.IsMobAlive(Entry) then return false end
        local Root = Entry.Root
        if not (Root and Root.Parent) or Root.Anchored then return false end

        local Ok, Owner = pcall(isnetworkowner, Root)
        if not (Ok and Owner) then return false end

        local Humanoid = Entry.Humanoid
        pcall(function()
            Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
            Humanoid.Health = 0
        end)
        -- เซิร์ฟไม่รับ (owner เพิ่งย้ายกลับไปเซิร์ฟพอดี - วัดสดในหอ Ouwigahara: มอน 3 ตัวเลือด 0 ฝั่งเรา
        -- แต่เซิร์ฟยังนับว่าเหลือ ชั้นค้าง) = โมเดลยังอยู่หลัง 1.5 วิ -> คืนเลือดฝั่งเรา ให้ฟาร์มตีตัวนี้ต่อ
        task.delay(1.5, function()
            if Humanoid.Parent and Humanoid.Parent.Parent and Humanoid.Health <= 0 then
                pcall(function() Humanoid.Health = Humanoid.MaxHealth end)
            end
        end)
        return true
    end

    -- มอนกำลังกันอยู่ไหม - เช็คแบบเดียวกับ Checker ของเกม: values folder ของมอนคือตัวโมเดลเอง
    -- (Utility.getvaluesfolder(model) คืนโมเดล) กันอยู่ = มีลูก "Blocking" และไม่มี "PierceBlock"
    function Farm.IsMobBlocking(Entry)
        local Model = Entry and Entry.Model
        if not Model then return false end
        return Model:FindFirstChild("Blocking") ~= nil and Model:FindFirstChild("PierceBlock") == nil
    end

    -- ตีตอนนี้เสียเปล่า/โดนสวน = ยืนรอที่จุดตี (เลขคอมโบค้างที่ server ต่อได้ทีหลัง)
    -- ยืนยันจาก Checker.check_victim + วัดสดตีบอส Akazo 40 วิ:
    --   Blocking (IntConstrainedValue เหลือ = Value - @D) หมัดผ่านแต่ดาเมจ 0 ขูดการ์ดแค่ ~0.8 จาก 26
    --     กันแค่ ~0.3-0.7 วิ รอให้หายเร็วกว่าตีทะลุ / มีลูก "Perfect" = คนตีโดน Strict_Stun ทันที
    --   @NpcCounter 1 = สวน M1, 3 = สวนสกิล, 2 = สวนทั้งคู่ (ตีเข้าไป = NpcCounterTriggered สวนกลับ)
    function Farm.IsMobGuarded(Entry, IsSkill)
        local Model = Entry and Entry.Model
        if not Model then return false end
        if Farm.IsMobBlocking(Entry) then return true end

        local Counter = Model:GetAttribute("NpcCounter")
        return Counter == 2 or Counter == (IsSkill and 3 or 1)
    end

    -- เป้าอมตะชั่วคราว (child "iframe" - วัดสด Greater Demon: ลุกจากล้มโดนสกิล ได้ iframe + Strict_Stun
    -- หมัดที่ยิงใส่ช่วงนั้นผ่าน server แต่ดาเมจ 0) - BoolValue เช็คค่าด้วย (บอสบางตัวถือค้างไว้เป็น false)
    function Farm.IsMobInvulnerable(Entry)
        local IFrame = Entry and Entry.Model and Entry.Model:FindFirstChild("iframe")
        if not IFrame then return false end
        return not IFrame:IsA("BoolValue") or IFrame.Value == true
    end

    -- ตัวเราโดนสตันอยู่ (values folder ของผู้เล่น = ReplicatedStorage.Player_Service.Values.<ชื่อ>
    -- ตาม Utility.getvaluesfolder) - ยิงหมัดตอนนี้ server ปัดตกหมด
    function Farm.SelfStunned()
        local Service = ReplicatedStorage:FindFirstChild("Player_Service")
        local Values = Service and Service:FindFirstChild("Values")
        local Folder = Values and Values:FindFirstChild(LocalPlayer.Name)
        if not Folder then return false end
        -- RagDoll = เราโดนตีล้มอยู่ (วัดสด: ยิงหมัดระหว่างนอน 5 หมัด เซิร์ฟปัดตกหมด)
        return Folder:FindFirstChild("Stun") ~= nil or Folder:FindFirstChild("CombatStun") ~= nil
            or Folder:FindFirstChild("Strict_Stun") ~= nil or Folder:FindFirstChild("RagDoll") ~= nil
    end

    -- บอสอมตะอยู่ (BoolValue "iframe" = true ตอนลูกน้องยังเหลือ - ยืนยันสด Hand Demon) คืนลูกน้อง
    -- ที่ใกล้บอสสุดให้ไปฆ่าก่อน / บอสไม่ได้อมตะ = nil (มอนธรรมดารอบบอสไม่ต้องสน ตีบอสต่อ)
    -- iframe สั้น ๆ หลังลุกจากล้ม (~0.6 วิ) ก็มี - นับว่าเป็นช่วงลูกน้องเฉพาะเมื่อค้างต่อเนื่องเกิน AddIFrameHold
    -- (ไม่งั้นบอสที่เกิดกลางฝูงมอนธรรมดา เช่น Zuko กับ Bandit สลับไปตีมอนข้าง ๆ ทุกครั้งที่ล้ม)
    -- (ล้างเฉพาะตอนเห็นบอสกลับมาตีได้ ระหว่างไปฆ่าลูกน้องระลอกแรก บอสยังอมตะอยู่ = ตัวถัดไปสลับทันที)
    local IFrameSince = setmetatable({ }, { __mode = "k" })   -- Model บอส -> os.clock() ที่เห็น iframe ครั้งแรก
    local AddIFrameHold = 1.5

    -- มอนที่ไม่ใช่ลูกน้องบอสแน่ ๆ: มอนเกิดประจำที่ (catalog ActiveNpcs ของเกม) + การ์ดแคมป์ Sealed Cache
    -- (Grove Raider / Lancer Captain ฯลฯ อยู่ Regions.Temporary เหมือนตัวที่ถูกเรียกออกมา แต่เป็นของแคมป์)
    local function IsRegularSpawn(Name)
        local Base = Name:gsub("%d+$", "")
        local Catalog = Farm.GetNpcCatalog and Farm.GetNpcCatalog()
        for _, Npc in pairs(type(Catalog) == "table" and Catalog or { }) do
            if Npc.Name == Name or Npc.Name == Base then return true end
        end
        local Cache = Farm.GetCacheInfo and Farm.GetCacheInfo()
        local Guards = type(Cache) == "table" and Cache.GuardTier or { }
        return Guards[(Base:gsub("%s", ""):lower())] ~= nil
    end

    function Farm.GetBossAdd(Boss)
        if not (Farm.IsMobAlive(Boss) and Boss.IsBoss) then return nil end
        if not Farm.IsMobInvulnerable(Boss) then
            IFrameSince[Boss.Model] = nil
            return nil
        end

        IFrameSince[Boss.Model] = IFrameSince[Boss.Model] or os.clock()
        if os.clock() - IFrameSince[Boss.Model] < AddIFrameHold then return nil end

        local Add, AddDistance = nil, 200
        for _, Entry in ipairs(IterMobs()) do
            local Distance = (Entry.Root.Position - Boss.Root.Position).Magnitude
            -- บอสตัวอื่นที่เกิดใกล้กันไม่ใช่ลูกน้อง (วัดสด: Gyutai ล้ม/iframe -> ไปตี Datai ห่าง 100 studs)
            -- มอนเกิดประจำที่ (มีใน catalog ActiveNpcs ของเกม เช่น Bandit / Bear Cub) ก็ไม่ใช่ - บอสมีท่าอมตะสั้น ๆ
            -- ระหว่างหลบแล้วไปเจอมอนแถวนั้น = สลับไปตีมันเฉย (วัดสด: Shinora อมตะช่วงหลบ -> ไปตี Lancer Captain
            -- การ์ดแคมป์ข้าง ๆ) ลูกน้องจริงเป็นตัวที่บอสเรียกออกมาเท่านั้น
            if Entry.Model ~= Boss.Model and not Entry.IsBoss and not IsRegularSpawn(Entry.Model.Name)
                and Distance < AddDistance and Farm.IsMobAlive(Entry) then
                Add, AddDistance = Entry, Distance
            end
        end
        return Add
    end

    function Farm.GetNearestMob(Origin)
        local Best, BestDistance = nil, math.huge
        for _, Entry in ipairs(IterMobs()) do
            local Distance = (Entry.Root.Position - Origin).Magnitude
            if Distance < BestDistance then
                Best, BestDistance = Entry, Distance
            end
        end
        return Best, BestDistance
    end

    -- มอนชนิดเดียวกับที่ config ไว้เท่านั้น (รองรับชื่อมีเลขต่อท้าย เช่น Bandit2, Bandit3)
    function Farm.GetMobsByName(MonName)
        local List = { }
        if type(MonName) ~= "string" or MonName == "" then return List end

        local Pattern = "^" .. MonName:gsub("%p", "%%%1") .. "%d*$"

        for _, Entry in ipairs(IterMobs()) do
            if Entry.Model.Name == MonName or Entry.Model.Name:match(Pattern) then
                table.insert(List, Entry)
            end
        end

        return List
    end

    function Farm.GetNearestMobByName(Origin, MonName)
        local Best, BestDistance = nil, math.huge
        for _, Entry in ipairs(Farm.GetMobsByName(MonName)) do
            local Distance = (Entry.Root.Position - Origin).Magnitude
            if Distance < BestDistance then
                Best, BestDistance = Entry, Distance
            end
        end
        return Best, BestDistance
    end

    --// เลือกเป้าปัจจุบันจาก getgenv().LevelConfig
    --
    -- แบบเดียวกับ CheckLevel ของ Haze Sea: เอา entry ที่ Level ปัจจุบัน >= .Level แล้วค่า .Level สูงสุด
    -- (ด่านที่ "ปลดล็อกแล้ว" ตัวล่าสุด) - ไม่มี entry ไหนแมตช์เลย (Level ผู้เล่นต่ำกว่าด่านแรก) = คืน nil
    function Farm.GetLevelEntry()
        local Levels = getgenv().LevelConfig
        if type(Levels) ~= "table" or #Levels == 0 then return nil end

        local Level = Farm.GetLevel()
        local Selected = nil

        for _, Entry in ipairs(Levels) do
            if type(Entry) == "table" and type(Entry.Level) == "number" and Level >= Entry.Level then
                if not Selected or Entry.Level > Selected.Level then
                    Selected = Entry
                end
            end
        end

        return Selected
    end

    -- อ่านชื่อไอเทมที่ถืออยู่จริงตอนนี้
    local InfoProvider = GlobalModule("Character_info_provider")

    function Farm.GetEquippedToolName()
        if not InfoProvider or type(InfoProvider.Get_equipped_tool) ~= "function" then return nil end
        local Ok, Tool = pcall(InfoProvider.Get_equipped_tool, LocalPlayer)
        return Ok and Tool and Tool.Name or nil
    end

    local CombatPresets = GlobalModule("Combat_presets")
    local ItemsModule
    do
        local Ok, Module = pcall(function()
            return require(ReplicatedStorage.CAM.Global.Collectibles.Items)
        end)
        ItemsModule = Ok and Module or nil
    end

    -- ชื่อไอเทมที่ถืออยู่ "ไม่ใช่" Style ที่ยิงเสมอ! เกมเช็ค Combat_presets.Presets[ToolName]
    -- ก่อน ถ้าไม่เจอ (อาวุธส่วนใหญ่ไม่มี preset เป็นของตัวเอง) ไปอ่าน Items[ToolName].CombatPreset
    -- แทน (เช่น Cutlass -> CombatPreset = "Regular Katana" - ยืนยันสดผ่าน dex_exec แล้ว)
    -- นี่คือ Style จริงที่ยิงใส่ remote ตรงกับ get_equipped_Combat()/punch() ใน PlayerScripts.CU.Combat
    -- ไม่มี preset ให้เลยจริง ๆ (ไอเทมไม่มี Breathing/HasCombat/CombatPreset) = ใช้ชื่อไอเทมดิบต่อไป
    -- ไม่มีอาวุธถือเลย (มือเปล่า) = fallback "Combat" (หมัด)
    function Farm.GetCombatStyle()
        local ToolName = Farm.GetEquippedToolName()
        if not ToolName then return "Combat" end

        if CombatPresets and CombatPresets.Presets[ToolName] then
            return ToolName
        end

        local Item = ItemsModule and ItemsModule[ToolName]
        if Item and (Item.CombatPreset or Item.Breathing ~= nil or Item.HasCombat) then
            return Item.CombatPreset or "Regular Katana"
        end

        return ToolName
    end

    --// อาวุธ M1 แรงสุดใน Toolbar (แทนอาวุธหลักที่เลือกในแต่ละแท็บ)
    -- ดาเมจต่อหมัดคิดฝั่งเซิร์ฟ ของที่ต่างกันระหว่างอาวุธคือ ActiveToolStats (ได้ตอนถือ):
    --   Additional Damage (บวกตรง) + Additional Damage Factor (คูณ) - เช่น Tanto 2 / 0.044, Nightfall Katana 5.75 / 0.138
    -- ความเร็วคอมโบต่างตาม preset: 1 ชุด = หมัด 2-5 (customDelay หรือ default) + final
    -- คะแนน = (ดาเมจพื้นฐาน + Additional Damage) x (1 + Factor) x 5 หมัด / เวลา 1 ชุด = ดาเมจ M1 ต่อวินาทีโดยประมาณ
    local M1BaseDamage = 8      -- ดาเมจพื้นฐานต่อหมัด (ประมาณจาก Bandit 45 HP ตาย ~5 หมัดตอนถือ Tanto)

    function Farm.M1Score(Name)
        local Item = ItemsModule and ItemsModule[Name]
        if type(Item) ~= "table" or not Item.HasCombat then return nil end

        local Stats = type(Item.ActiveToolStats) == "table" and Item.ActiveToolStats or { }
        local PerHit = (M1BaseDamage + (tonumber(Stats["Additional Damage"]) or 0))
            * (1 + (tonumber(Stats["Additional Damage Factor"]) or 0))

        local Style = (CombatPresets and CombatPresets.Presets[Name]) and Name
            or Item.CombatPreset or ((Item.Breathing ~= nil) and "Regular Katana") or Name
        local Preset = CombatPresets and (CombatPresets.Presets[Style] or CombatPresets.Presets.Combat)

        local Cycle = 0
        if Preset then
            for Combo = 2, 5 do
                Cycle = Cycle + (tonumber(Preset.customDelay and Preset.customDelay[Combo] or Preset.default) or 0.25)
            end
            Cycle = Cycle + (tonumber(Preset.final) or 1.65)
        end
        if Cycle <= 0 then Cycle = 2.65 end

        return PerHit * 5 / Cycle
    end

    -- เล่มที่ M1 แรงสุดใน Toolbar ตอนนี้ (แคช 3 วิ) - ไม่มีอาวุธเลย = nil
    local BestM1Cache = { At = -math.huge, Name = nil }

    function Farm.BestM1Weapon()
        if os.clock() - BestM1Cache.At < 3 then return BestM1Cache.Name end

        local Best, BestScore = nil, -math.huge
        for _, Name in pairs(Farm.GetToolbar()) do
            local Score = Farm.M1Score(Name)
            if Score and (Score > BestScore or (Score == BestScore and Name < Best)) then
                Best, BestScore = Name, Score
            end
        end
        BestM1Cache.At, BestM1Cache.Name = os.clock(), Best
        return Best
    end

    -- อาวุธที่ใช้ M1 จริง: Select Weapon ของแท็บ (อยู่ใน Toolbar) > เล่ม M1 แรงสุด (เมื่อเปิด Auto Equip Best Weapon)
    -- ผู้เล่นเลือกเองต้องชนะ (เดิม Best M1 มาก่อน = เปลี่ยน Select Weapon แล้วยังถือเล่มเดิม)
    function Farm.M1Weapon(Selected)
        if Selected == Farm.BestChoice then
            local Best = Farm.BestM1Weapon()
            if Best then return Best end
            Selected = nil
        end
        if type(Selected) == "string" and Selected ~= "" and Selected ~= "None" then
            for _, Name in pairs(Farm.GetToolbar()) do
                if Name == Selected then return Selected end
            end
        end
        local Config = getgenv().ConfigurationTable
        -- ผู้ใช้ 2026-10-02: รวมกับ Auto Equip Best Weapon (ปุ่ม Best M1 Weapon แยกเดิมเอาออกแล้ว)
        if Config.AutoEquipBestWeapon == true then
            local Best = Farm.BestM1Weapon()
            if Best then return Best end
        end
        return Selected
    end

    ---- คูลดาวน์คอมโบของจริง (ไม่ใช่เดาจาก preset.final) ----
    --
    -- ยืนยันจาก decompile Combat_presets (get_combat_cd_info / Check_can_do_combat_server ที่
    -- server เรียกทุกครั้งที่ได้ remote "Combat_Service") + ยิงทดสอบสดในเกม:
    --
    --   state ของคอมโบอยู่บน "attribute ของตัวละคร" ซึ่ง replicate มาถึง client อ่านได้ตรง ๆ
    --     last_cmbat = os.clock() ฝั่ง server ตอนหมัดล่าสุดผ่าน
    --     last_combo = เลขหมัดล่าสุดที่ผ่าน
    --
    --   หมัดเลข N จะผ่านก็ต่อเมื่อรอครบเวลานี้นับจาก last_cmbat:
    --     N == last_combo + 1 (หรือ N == 6 กับ last_combo == 4) -> preset.customDelay[N] หรือ preset.default
    --     N == 1                                                -> last_combo เป็น 5/7 ? preset.final : combo_duration (1.35)
    --     นอกนั้น (เลขไม่ต่อลำดับ)                                -> 10000 วิ = ไม่ผ่านแน่นอน
    --   ทั้งหมดหารด้วย attackSpeedMult = max(1 + stat "Attack Speed Factor", 0.25)
    --
    --   ยิงเร็วไปไม่ถูกทิ้งทันที: server ทำ task.wait(เวลาที่เหลือ แต่ clamp ไม่เกิน 1 วิ) แล้วเช็ค
    --   ratio >= 0.95 อีกรอบ -> ยิงล่วงหน้าได้ไม่เกิน ~1 วิ แล้วมันจะไปผ่านพอดีตอนคูลดาวน์หมด
    --   (วัดสด Regular Katana: หลัง combo 5 ผ่าน หมัด 1 ถัดไปผ่านที่ 1.665 วิ = final 1.65 + ping
    --    และคำขอที่ยิงไว้ก่อนหน้า 0.965 วิ คือตัวที่ถูกปล่อยผ่าน ณ วินาทีนั้นพอดี)
    --
    -- last_cmbat เป็น os.clock() คนละ epoch กับ client (วัดสด: server ~898 / client ~73000)
    -- เอามาลบกันตรง ๆ ไม่ได้ - จับเวลาฝั่งเราเองตอน attribute เปลี่ยนแทน
    local StatResolver = GlobalModule("PlayerStatResolver")

    local Combat = { AcceptedAt = 0, Combo = 0, Stamp = 0 }
    Farm.Combat = Combat

    local CombatWatch = nil

    local function WatchCombat(Character)
        if CombatWatch then
            pcall(function() CombatWatch:Disconnect() end)
            CombatWatch = nil
        end

        if not Character then return end

        Combat.Combo = Character:GetAttribute("last_combo") or 0
        -- ตัวละครเคยตีมาก่อนสคริปต์เริ่ม = ไม่รู้ว่าหมัดล่าสุดเมื่อไหร่ ถือว่า "เพิ่งตี" ไว้ก่อน
        -- (เสียแค่คูลดาวน์รอบแรกรอบเดียว ดีกว่าเดาว่าพร้อมแล้วยิงไปโดนตีฟรี)
        Combat.AcceptedAt = Character:GetAttribute("last_cmbat") and os.clock() or 0
        Combat.Stamp = Combat.Stamp + 1

        CombatWatch = TrackConnection(Character:GetAttributeChangedSignal("last_cmbat"):Connect(function()
            Combat.AcceptedAt = os.clock()
            Combat.Combo = Character:GetAttribute("last_combo") or 0
            Combat.Stamp = Combat.Stamp + 1
        end))
    end

    task.spawn(function() WatchCombat(LocalPlayer.Character) end)
    TrackConnection(LocalPlayer.CharacterAdded:Connect(WatchCombat))

    -- ComboCooldown ถูกเรียกทุกเฟรมในลูปฟาร์ม - อย่าให้วิ่งเข้า Character_info_provider ทุกครั้ง
    -- (เสียเวลา + เป็นโมดูลกลุ่มที่ทำ thread เสีย capability ชั่วคราวตามโน้ตที่ Select Weapon)
    local PresetCache = { At = 0, Preset = nil, Style = nil, Mult = 1 }

    function Farm.GetAttackSpeedMult()
        if not (StatResolver and type(StatResolver.GetStat) == "function") then return 1 end

        local Ok, Factor = pcall(StatResolver.GetStat, LocalPlayer, "Attack Speed Factor")
        return math.max(1 + ((Ok and tonumber(Factor)) or 0), 0.25)
    end

    -- คืน preset, style, attack speed mult (แคชรวมกัน 0.2 วิ - stat ไม่ได้เปลี่ยนทุกเฟรม)
    local function CurrentPreset()
        if PresetCache.Preset and os.clock() - PresetCache.At < 0.2 then
            return PresetCache.Preset, PresetCache.Style, PresetCache.Mult
        end

        local Style = Farm.GetCombatStyle()
        local Preset = CombatPresets and (CombatPresets.Presets[Style] or CombatPresets.Presets.Combat)

        PresetCache.At, PresetCache.Preset, PresetCache.Style = os.clock(), Preset, Style
        PresetCache.Mult = Farm.GetAttackSpeedMult()
        return Preset, Style, PresetCache.Mult
    end

    -- เพิ่งสลับอาวุธ = style/preset เปลี่ยน อย่าใช้ค่าที่แคชไว้ของอาวุธเก่า
    function Farm.InvalidatePreset()
        PresetCache.Preset = nil
    end

    -- เลขหมัดถัดไปที่ server จะยอมรับ - เอาจาก last_combo ของ server ไม่ใช่ตัวนับของเราเอง
    -- (คอมโบโดนตัดกลางชุดแล้วรอบหน้าเริ่มนับ 1 ใหม่ทั้งที่ server ค้างอยู่ที่ 3 = เลขไม่ต่อลำดับ
    --  โดนตีตก 10000 วิ ยืนเปล่าให้มอนตีฟรีทั้งชุด)
    function Farm.NextCombo()
        local Last = Combat.Combo or 0
        if Last >= 5 then return 1 end
        return Last + 1
    end

    -- เหลืออีกกี่วินาทีหมัดเลขนี้ถึงจะผ่าน (0 = ยิงได้เลย, nil = เลขหลุดลำดับ ยิงไปก็ไม่ผ่าน)
    function Farm.ComboCooldown(Combo)
        local Preset, _, Mult = CurrentPreset()
        if not Preset then return 0 end

        local Last = Combat.Combo or 0
        local Need

        if Combo == Last + 1 or (Combo == 6 and Combo - 2 == Last) then
            Need = (Preset.customDelay and Preset.customDelay[Combo]) or Preset.default
        elseif Combo == 1 then
            if Last == 5 or Last == 7 then
                Need = Preset.final
            else
                Need = (CombatPresets and CombatPresets.combo_duration) or 1.35
            end
        else
            return nil
        end

        if Combat.AcceptedAt == 0 then return 0 end

        Need = (tonumber(Need) or 0) / Mult
        return math.max(Need - (os.clock() - Combat.AcceptedAt), 0)
    end

    -- ยิง SignalEvent("Combat_Service", ...) ตรง ๆ เหมือนเดิม (ไม่ผ่าน Main_Combat_Script_Client.Do
    -- แล้ว - ตามที่สั่ง) แต่คำนวณ delay (arg ที่ 5) ด้วยสูตรเดียวกับที่ Do() ใช้จริง แทนตาราง
    -- ComboDelays ตายตัวเดิม เพื่อให้รองรับทุกอาวุธ (แต่ละ preset มี delay_before_swing/
    -- delay_before_hit ไม่เท่ากัน ตารางคงที่ค่าเดียวใช้ได้แค่บางอาวุธ):
    --   SwingWait = preset.delay_before_swing[Combo] or preset.default_before_swing or 0.15
    --   HitWait   = preset.delay_before_hit[Combo] or preset.default_before_hit or SwingWait
    --   Delay     = HitWait - SwingWait   (ระยะห่างจากจังหวะเงื้อถึงจังหวะลงดาบ ไม่รวม Speed mult)
    local DefaultSwingWait = 0.15

    local function ComputeSwingDelay(Preset, Combo)
        if not Preset then return 0 end

        local SwingWait = (Preset.delay_before_swing and Preset.delay_before_swing[Combo])
            or Preset.default_before_swing or DefaultSwingWait

        local HitWait = (Preset.delay_before_hit and Preset.delay_before_hit[Combo])
            or Preset.default_before_hit or SwingWait

        return math.max(HitWait - SwingWait, 0)
    end

    -- server ไม่มีเพดานเวลาต่อคอมโบ (get_combat_cd_info: หมัด last_combo+1 รอแค่ preset.default นับจาก
    -- หมัดล่าสุด จะห่างกี่วิก็ได้) = หลบ/เปลี่ยนเป้ากลางชุดแล้วกลับมายิงเลขถัดไปได้เลย คอมโบไม่หลุด
    -- ขอแค่เลขต่อลำดับ (Farm.NextCombo อ่านจาก attribute ของ server เสมอ)
    --
    -- คูลดาวน์เหลือไม่เกินเท่านี้ถึงจะต่อหมัดถัดไปในชุดเดียวกัน (ช่องว่างระหว่างหมัดของจริงคือ
    -- preset.default ~0.25-0.32) - ยาวกว่านี้แปลว่าต้องเริ่มชุดใหม่ (final 1.65 / combo_duration
    -- 1.35) ซึ่งต้องไป "ลอยรอ" ไม่ใช่ยืนติดมอนรอ เลย break ออกไปให้ผู้เรียกพาไปหลบ
    --
    -- ที่ยิงตอนคูลดาวน์ยังไม่หมดได้เลยไม่ต้องรอให้ครบ เพราะ server ถือคำขอที่มาเร็วไว้ได้ถึง 1 วิ
    -- (task.wait(เวลาที่เหลือ) แล้วเช็ค ratio >= 0.95) = หมัดจะผ่าน ณ วินาทีที่คูลดาวน์หมดพอดี
    local ChainWindow = 0.45
    -- เผื่อเวลา round-trip กว่า attribute จะ replicate กลับมาบอกว่าหมัดนั้นผ่านแล้ว
    local AcceptGrace = 0.6

    -- รอจน server รับหมัดที่เพิ่งยิงไป (attribute last_cmbat เปลี่ยน = Stamp ขยับ)
    local function WaitForHit(Mark, Timeout, ShouldContinue, Mob)
        local Deadline = os.clock() + math.max(Timeout, 0.15)

        while os.clock() < Deadline do
            if Combat.Stamp ~= Mark then return true end
            if ShouldContinue and not ShouldContinue() then return false end
            if not Farm.IsMobAlive(Mob) then return false end

            task.wait()
        end

        return Combat.Stamp ~= Mark
    end

    function Farm.FireCombo(Mob, ShouldContinue)
        if not SignalEvent then return false end

        -- Style จริงที่ยิงใส่ remote ต้องผ่าน resolve เหมือนเกม (ชื่อไอเทมดิบ != Style เสมอ
        -- เช่น Cutlass -> "Regular Katana") ไม่ใช่ชื่อไอเทมที่ถืออยู่ตรง ๆ
        local Preset, Style = CurrentPreset()

        -- เกาะมอนแบบคำนวณใหม่ทุกเฟรม: ส่งฟังก์ชันให้ Movement.Lock แทน CFrame นิ่ง ๆ
        -- (ของเดิมตั้งจุดใหม่รอบละ ~0.28 วิ มอนเดินหนีระหว่างนั้น = ดาบฟันไม่โดน)
        Movement.Lock(function()
            if not Farm.IsMobAlive(Mob) then return nil end
            return Farm.BuildStandCFrame(Mob.Root.CFrame)
        end)

        -- ของเดิมไล่ยิง 1->5 ตายตัวแล้ว task.wait(preset.default) คั่นเฉย ๆ โดยไม่สนว่า server
        -- รับจริงไหม - คอมโบโดนตัดกลางชุดเมื่อไหร่ (หลบสกิล/มอนตาย/เปลี่ยนเป้า) รอบถัดไปเลขไม่ต่อ
        -- ลำดับกับ last_combo ที่ server ค้างไว้ = ตกทุกหมัดที่เหลือ ยืนติดมอนเปล่า ๆ ให้มันตีฟรี
        -- ตอนนี้เลขหมัดมาจาก last_combo ของ server และรอให้หมัดนั้นผ่านจริงก่อนค่อยยิงตัวถัดไป
        local Landed = 0

        for _ = 1, 5 do
            if ShouldContinue and not ShouldContinue() then break end
            if not Farm.IsMobAlive(Mob) then break end
            -- โดนสตันอยู่ = server ปัดหมัดตกแน่ ๆ ไม่ต้องยิงไปรอ timeout (เลขคอมโบค้างที่เดิม ต่อได้ทีหลัง)
            if Farm.SelfStunned() then break end
            -- มอนยกการ์ด/ตั้งท่าสวนกลางชุด = หยุดยิงตรงนี้ ผู้เรียกยืนรอจนมันลดการ์ดแล้วต่อเลขเดิม
            if Farm.IsMobGuarded(Mob) then break end
            -- กำลังดื่มยา (หลบอยู่) - หมัดจะตัดการดื่มกลางคัน / ท่าที่สำคัญกว่า M1 ค้างอยู่ (HubAction) = หยุดชุด
            if Farm.Potions and Farm.Potions.Busy then break end
            if not HubAction.Claim("M1", 1.5) then break end

            local Combo = Farm.NextCombo()
            local Remaining = Farm.ComboCooldown(Combo)

            -- nil = เลขหลุดลำดับ (ยิงไปก็ตก) / ยาวเกิน ChainWindow = ต้องขึ้นชุดใหม่ ไปลอยรอก่อน
            if not Remaining or Remaining > ChainWindow then break end

            local Mark = Combat.Stamp
            local Delay = ComputeSwingDelay(Preset, Combo)

            Farm.LastSwingAt = os.clock()
            pcall(function()
                SignalEvent.ToServer("Combat_Service", Style, Combo, false, Delay, false, nil)
            end)

            if not WaitForHit(Mark, Remaining + AcceptGrace, ShouldContinue, Mob) then
                -- server ไม่รับ (โดนขัดจังหวะ/สถานะไม่ให้ตี) - เลิกชุดนี้แล้วไปตั้งหลักรอคูลดาวน์
                -- ดีกว่ายืนยิงหมัดที่ตกต่อไปเรื่อย ๆ
                break
            end

            Landed = Landed + 1
            -- หมัด 5 (ปิดคอมโบ) เข้า - นับไว้ให้มอนที่ไม่เคยล้ม (ดู Farm.NoteFinisher)
            if Combo == 5 then Farm.NoteFinisher(Mob) end
        end

        HubAction.Release("M1")
        return Landed > 0
    end

    --// จังหวะสกิล (Auto Use Skill): M1 จนมอนล้ม -> ยิง 1 สกิล -> รอตีล้มรอบใหม่ค่อยยิงท่าถัดไป
    -- วัดสด Bandit: หมัด 5 เข้า = ลูก "RagDoll" + CombatStun บนโมเดลมอน อยู่ ~1.0 วิ (หมัด 1-4 ได้แค่ CombatStun)
    -- ต้องล้มจริง (มี RagDoll อยู่ตอนเริ่มยิง) - วัดสดบอส Datai 45 วิ: ยิงตอนมี RagDoll โดนทุกท่า (25-59 ดาเมจ)
    -- ยิงตอนหมัด 5 เข้าแต่บอสไม่ล้ม = ดาเมจ 0 หลายท่า + บอสยังใช้ท่าได้ เราโดนหลบกลางท่าที่ปล่อยไปแล้ว
    -- (ท่าที่ปล่อยแล้วยกเลิกไม่ได้ - Skill_Controller.ForceCancel ใช้ได้แค่ตอนยังเงื้อค้าง)
    -- มอนที่ไม่เคยล้มเลย (ตีหมัด 5 เข้า FinisherFallback ครั้งแล้วไม่เห็น RagDoll) = ใช้หมัด 5 เป็นจังหวะแทน
    -- Used = ยิงไปแล้วในรอบล้มนี้ / ช่องเปิดแค่ KnockWindow วิหลังล้ม
    Farm.Knock = { Model = nil, At = -math.huge, Used = true }
    Farm.KnockWindow = 1.2
    local RagdollSeen = setmetatable({ }, { __mode = "k" })   -- Model -> เคยเห็นล้ม
    local Finishers = setmetatable({ }, { __mode = "k" })     -- Model -> หมัด 5 ที่เข้าไปกี่ครั้ง
    local FinisherFallback = 3

    function Farm.NoteKnock(Entry, FromRagdoll)
        local Model = Entry and Entry.Model
        if not Model then return end
        if FromRagdoll then RagdollSeen[Model] = true end
        local Knock = Farm.Knock
        if Knock.Model == Model and os.clock() - Knock.At < 0.6 then return end   -- ล้มครั้งเดียวกัน
        Knock.Model, Knock.At, Knock.Used = Model, os.clock(), false
    end

    function Farm.NoteFinisher(Entry)
        local Model = Entry and Entry.Model
        if not Model or RagdollSeen[Model] then return end
        Finishers[Model] = (Finishers[Model] or 0) + 1
        if Finishers[Model] >= FinisherFallback then Farm.NoteKnock(Entry) end
    end

    function Farm.SkillWindow(Entry)
        local Knock = Farm.Knock
        local Model = Entry and Entry.Model
        if not (Model and Knock.Model == Model and not Knock.Used and os.clock() - Knock.At <= Farm.KnockWindow) then
            return false
        end
        -- มอนที่ล้มได้ = ต้องยังนอนอยู่ตอนนี้ (ลุกแล้ว/ช่องจากหมัด 5 ที่ไม่ล้ม = ไม่ยิง)
        return not RagdollSeen[Model] or Model:FindFirstChild("RagDoll") ~= nil
    end

    ---- Quests ----

    local Quests
    do
        local Ok, Module = pcall(function()
            return require(ReplicatedStorage.CAM.Global.Subsets.Gameplay.Quests)
        end)
        Quests = Ok and Module or nil
    end

    -- หา quest ที่ผูกกับ entry นี้ - ใช้ QuestName (Entry.QuestName = Id ตรงตัวใน Quests.Holder ถ้าตั้งไว้)
    -- ก่อนเสมอเพราะแม่นสุด แล้วค่อย fallback ไปเทียบ MonName แบบ substring ถ้า QuestName ว่าง/ไม่ตั้ง
    -- คืนค่า Id (ใช้ยิง AddQuest), InstanceName (ใช้เช็คใน PlayerGui)
    -- ตัวอย่างจริง: Id = "Ill take 3 bandits", QuestInstance = "Defeat 3 bandits" (คนละสตริงกัน)
    function Farm.FindQuestIdForMob(QuestName, MonName)
        if not Quests or type(Quests.Holder) ~= "table" then return nil end

        -- ตรงตัว (Entry.QuestName ตั้งเป็น Id ของเควสจริง) - เร็วสุด แม่นสุด ไม่ต้อง scan
        if type(QuestName) == "string" and QuestName ~= "" then
            local Def = Quests.Holder[QuestName]
            if type(Def) == "table" then
                local InstanceName = Def.QuestInstance ~= nil and tostring(Def.QuestInstance) or nil
                return QuestName, InstanceName
            end
        end

        -- fallback: เทียบชื่อมอนกับ id ของ quest และ QuestInstance (ชื่อจริงที่ขึ้นในเกม)
        if type(MonName) ~= "string" or MonName == "" then return nil end
        local Needle = MonName:lower()

        for Id, Def in pairs(Quests.Holder) do
            if type(Def) == "table" then
                -- QuestInstance ไม่ใช่ string ธรรมดา (เป็น userdata ห่อสตริงแปลภาษา)
                -- ต้อง tostring ก่อนใช้ต่อ ไม่งั้น type-check ปลายทางเตะทิ้งเงียบ ๆ
                local InstanceName = Def.QuestInstance ~= nil and tostring(Def.QuestInstance) or nil
                local Haystack = (tostring(Id) .. " " .. (InstanceName or "")):lower()
                if Haystack:find(Needle, 1, true) then
                    return Id, InstanceName
                end
            end
        end

        return nil
    end

    -- เช็คว่า quest กำลัง active จริงผ่าน PlayerGui (ไม่เชื่อแค่ค่าที่ยิงไป เผื่อ server ปฏิเสธเงียบ ๆ)
    -- โครง: PlayerGui.ComponentsHolder.LeftCenterFramesHolder.zQuestsFrame.Panel.<QuestInstanceName>
    function Farm.IsQuestActive(QuestInstanceName)
        if type(QuestInstanceName) ~= "string" or QuestInstanceName == "" then return false end

        -- ข้อมูลผู้เล่นก่อน (ที่เดียวกับ Quests.GetPlayerQuestState ของเกม: GetData().Quests.Holder.<instance>)
        -- UI เควสไม่มี "Panel" แล้ว (วัดสด 2026-09-30) - อ่าน UI อย่างเดียว = ถือเควสอยู่แต่คิดว่าไม่ได้ถือ
        -- ยิง AddQuest ซ้ำ เกมปัด (CanAddQuest บล็อกด้วยเควสตัวเดียวกัน) ฟาร์มยืนค้างที่ NPC ตลอด
        local Utility = GlobalModule("Utility")
        local Ok, Held = pcall(function()
            return Utility.GetData(LocalPlayer).Quests.Holder:FindFirstChild(QuestInstanceName) ~= nil
        end)
        if Ok and Held then return true end

        local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
        local Holder = PlayerGui and PlayerGui:FindFirstChild("ComponentsHolder")
        local FramesHolder = Holder and Holder:FindFirstChild("LeftCenterFramesHolder")
        local QuestsFrame = FramesHolder and FramesHolder:FindFirstChild("zQuestsFrame")
        local Panel = QuestsFrame and QuestsFrame:FindFirstChild("Panel")

        return Panel ~= nil and Panel:FindFirstChild(QuestInstanceName) ~= nil
    end

    -- เซิร์ฟเช็คระยะจาก NPC ให้เควส (Quests.Holder[Id].OfferNpc) - วัดสด Mitsu: ยืน 43 studs ยิง AddQuest
    -- เงียบ ไม่ได้เควส / ยืน 4 studs ได้ทันที เลยบินไปยืนติด NPC ตัวจริงก่อนยิงทุกครั้ง (QuestPOS ใน
    -- LevelConfig คลาดได้) NPC อยู่ workspace.Debree.Regions.<โซน>.StationaryNpcs.<ชื่อ> - หลุด streaming = ข้าม
    local QuestNpcReach = 8

    -- NPC ใน StationaryNpcs โหลดตาม region (streaming) - อยู่ไกลจะไม่มีโมเดล (วัดสด 2026-09-28: ยืนนอก
    -- Mistfall Harbor = StationaryNpcs ว่าง ไม่เจอ Sofen เลย) -> ใช้จุดเกิดจาก ReplicatedStorage.Regions
    -- (GetNpcSpawn ไม่ติด streaming) บินไปก่อนแล้วค่อยหาโมเดลตัวจริง
    local RegionsModule = nil
    pcall(function() RegionsModule = require(ReplicatedStorage.Regions) end)

    local function FindStationaryNpc(NpcName)
        local Debree = workspace:FindFirstChild("Debree")
        local Regions = Debree and Debree:FindFirstChild("Regions")
        for _, Region in ipairs(Regions and Regions:GetChildren() or { }) do
            local Stationary = Region:FindFirstChild("StationaryNpcs")
            local Npc = Stationary and Stationary:FindFirstChild(NpcName)
            local NpcRoot = Npc and Npc:FindFirstChild("HumanoidRootPart")
            if NpcRoot then return NpcRoot end
        end
        return nil
    end

    -- CFrame ยืนหน้า NPC (โมเดลจริงก่อน / ไม่มีก็จุดเกิด) - nil = หาไม่เจอเลย
    function Farm.NpcStandCFrame(NpcName)
        if type(NpcName) ~= "string" then return nil end
        local NpcRoot = FindStationaryNpc(NpcName)
        if NpcRoot then return NpcRoot.CFrame * CFrame.new(0, 0, -4), true end

        local Ok, At = pcall(function() return RegionsModule.GetNpcSpawn(NpcName) end)
        if Ok and typeof(At) == "Vector3" then return CFrame.new(At + Vector3.new(0, 3, 0)), false end
        return nil
    end

    -- บินไปยืนติด NPC - อยู่นอกระยะโหลด = ไปจุดเกิดก่อน รอโมเดลโหลด แล้วขยับเข้าหาตัวจริง
    function Farm.GoToNpc(NpcName, ShouldRun)
        local Target, Live = Farm.NpcStandCFrame(NpcName)
        local Root = Movement.GetRoot()
        if not (Target and Root) then return false end

        if (Target.Position - Root.Position).Magnitude > QuestNpcReach then
            Movement.Lock(nil)
            Movement.Go(Target, 3, 15, ShouldRun)
            if not Live then
                Farm.WaitFor(function() return FindStationaryNpc(NpcName) ~= nil end, 3, ShouldRun)
                local Real = FindStationaryNpc(NpcName)
                if Real then Movement.Go(Real.CFrame * CFrame.new(0, 0, -4), 3, 15, ShouldRun) end
            end
            Farm.Sleep(0.3, ShouldRun)      -- ให้เซิร์ฟเห็นตำแหน่งใหม่ก่อนยิง AddQuest/QuestProgress
        end
        return true
    end

    local function GoToQuestNpc(Id)
        local Def = Quests and Quests.Holder[Id]
        Farm.GoToNpc(Def and Def.OfferNpc)
    end

    -- รับ quest ที่ผูกกับมอนตัวนี้ ถ้ายังไม่ active และเกมยอมให้รับ (CanAddQuest)
    -- คืนค่า true ถ้า active อยู่แล้ว หรือรับสำเร็จ (ยืนยันผ่าน PlayerGui จริง ไม่ใช่แค่ยิงแล้วเชื่อ)
    function Farm.TryAcceptQuestForMob(QuestName, MonName)
        if not (SignalEvent and Quests) then return false end

        local Id, InstanceName = Farm.FindQuestIdForMob(QuestName, MonName)
        if not Id then return false end

        if InstanceName and Farm.IsQuestActive(InstanceName) then
            return true
        end

        -- เควส Combat รับได้ทีละ 1 (Quests.MaxQuestsPerPlayer) - เลเวลข้ามด่านแล้วเควสด่านเก่าค้างอยู่
        -- CanAddQuest จะคืน false ตลอด ติดวนไม่ฟาร์ม ต้องทิ้งตัวเก่าก่อน (ยิง remote เดียวกับปุ่ม abandon
        -- ในเกม: IndividualQuest -> SignalEvent.ToServer("RemoveQuest", ชื่อ instance เควส))
        local Ok, CanAdd, OnCooldown, Blocking = pcall(Quests.CanAddQuest, Id)
        if Ok and not CanAdd and not OnCooldown and type(Blocking) == "string" and Blocking ~= InstanceName then
            pcall(function()
                SignalEvent.ToServer("RemoveQuest", Blocking)
            end)

            -- รอเซิร์ฟลบเควสเก่าเสร็จ (ช่องว่าง = CanAddQuest ผ่าน) ไม่รอเต็ม 1 วิแบบเดิม
            Farm.WaitFor(function()
                local Ok2, Can = pcall(Quests.CanAddQuest, Id)
                return Ok2 and Can == true
            end, 1)
            Ok, CanAdd = pcall(Quests.CanAddQuest, Id)
        end

        if not (Ok and CanAdd) then return false end

        GoToQuestNpc(Id)

        pcall(function()
            SignalEvent.ToServer("AddQuest", Id)
        end)

        -- รอเควสขึ้นจริง (เช็คทุกเฟรม) แทนหยุด 1 วิเต็ม
        Farm.WaitFor(function()
            return InstanceName ~= nil and Farm.IsQuestActive(InstanceName)
        end, 1)

        return InstanceName ~= nil and Farm.IsQuestActive(InstanceName)
    end

    ---- Story quests (เควสเนื้อเรื่องที่ล็อก NPC ให้เควส เช่น Chaka) ----

    -- "None" / "Doing" / "Done" - Done นับเฉพาะเควสที่มี LogCompletion (เกมไม่เก็บประวัติเควสอื่น)
    function Farm.GetQuestState(Id)
        if not Quests then return "None" end
        local Ok, State = pcall(Quests.GetPlayerQuestState, LocalPlayer, Id)
        return Ok and State or "None"
    end

    function Farm.HasItem(Name)
        local Utility = GlobalModule("Utility")
        local Ok, Found = pcall(function()
            return Utility.GetData(LocalPlayer, true).Inventory.Inventory:FindFirstChild(Name) ~= nil
        end)
        return Ok and Found or false
    end

    -- รับเควสด้วย Id ตรง ๆ (ไม่ต้องผูกกับมอน) - ใช้กติกาเดียวกับ TryAcceptQuestForMob: ถ้าช่องเควส
    -- category เดียวกันมีเควสอื่นขวางอยู่ ทิ้งก่อน (RemoveQuest) แล้วค่อยยิง AddQuest
    function Farm.AcceptQuestById(Id)
        if not (SignalEvent and Quests) then return false end
        if Farm.GetQuestState(Id) == "Doing" then return true end

        local Ok, CanAdd, OnCooldown, Blocking = pcall(Quests.CanAddQuest, Id)
        local Def = Quests.Holder[Id]
        local InstanceName = Def and Def.QuestInstance and Def.QuestInstance.Name

        if Ok and not CanAdd and not OnCooldown and type(Blocking) == "string" and Blocking ~= InstanceName then
            pcall(function()
                SignalEvent.ToServer("RemoveQuest", Blocking)
            end)

            -- รอเซิร์ฟลบเควสเก่าเสร็จ (ช่องว่าง = CanAddQuest ผ่าน) ไม่รอเต็ม 1 วิแบบเดิม
            Farm.WaitFor(function()
                local Ok2, Can = pcall(Quests.CanAddQuest, Id)
                return Ok2 and Can == true
            end, 1)
            Ok, CanAdd = pcall(Quests.CanAddQuest, Id)
        end

        if not (Ok and CanAdd) then return false end

        GoToQuestNpc(Id)

        pcall(function()
            SignalEvent.ToServer("AddQuest", Id)
        end)

        Farm.WaitFor(function() return Farm.GetQuestState(Id) == "Doing" end, 1)
        return Farm.GetQuestState(Id) == "Doing"
    end

    -- task แบบคุย/ส่งของ (TaskSpecs Type = "Deliver") - remote เดียวกับตัวเลือกในบทพูดของเกม
    -- (Quests.DeliverAction -> SignalEvent.ToServer("QuestProgress", Id, TaskName)) ต้องยืนใกล้ NPC เป้าหมาย
    -- Extra = ช่องของ task แบบ Pickup (PickupState ส่งเลขช่องของที่เก็บ เช่น 1) / Deliver ไม่ต้องส่ง
    function Farm.QuestProgress(Id, TaskName, Extra)
        if not SignalEvent then return end
        pcall(function()
            if Extra ~= nil then
                SignalEvent.ToServer("QuestProgress", Id, TaskName, Extra)
            else
                SignalEvent.ToServer("QuestProgress", Id, TaskName)
            end
        end)
    end

    -- ผ่านเงื่อนไขเควสไหม (Requirements.Level + Requirements.Race) - ไม่ผ่าน = CanAddQuest คืน nil
    -- รับไม่ได้แน่ ๆ ไม่ต้องไปยืนวนรอที่ NPC
    --   Level: เลือกมอน/บอสด่านสูงกว่าเลเวลตัวเองในโหมด Auto Farm Mob / Boss
    --   Race : Lv 62/75/83/90 = { "Slayer", "Hybrid" } เฉพาะหน่วย Slayer
    function Farm.QuestAllowed(Id)
        local Def = Quests and Quests.Holder[Id]
        local Requirements = Def and Def.Requirements
        if type(Requirements) ~= "table" then return true end

        if type(Requirements.Level) == "number" and Farm.GetLevel() < Requirements.Level then
            return false
        end

        local Races = Requirements.Race
        if type(Races) ~= "table" then return true end

        local Utility = GlobalModule("Utility")
        local Ok, Race = pcall(function()
            return Utility.GetData(LocalPlayer, true).Race.Value
        end)

        return Ok and table.find(Races, Race) ~= nil
    end

    -- รับเควส Id นี้ได้ตอนนี้ไหม (ไม่ติด cooldown 30 วิ) - ช่องเต็มก็นับว่าได้ถ้าเควสที่ขวางทิ้งได้
    -- ยกเว้นเควสที่ขวางคือ KeepInstance (เช่นเควสบอสที่ยังถืออยู่ ห้ามทิ้งเพื่อไปรับเควสด่านก่อนหน้า)
    function Farm.CanTakeQuest(Id, KeepInstance)
        if not Quests then return false end

        local Ok, CanAdd, OnCooldown, Blocking = pcall(Quests.CanAddQuest, Id)
        if not Ok then return false end
        if CanAdd then return true end

        return not OnCooldown and type(Blocking) == "string" and Blocking ~= KeepInstance
    end

    -- ยืนรอหลังเข้าถึงจุดตีให้เซิร์ฟเห็นตำแหน่งใหม่ก่อนหมัดแรก (ดู Attack) / EngageLead = ยิงหมัดแรก
    -- ล่วงหน้าได้เท่านี้ก่อนคูลดาวน์หมด (server ถือคำขอไว้ให้แล้วปล่อยผ่านตอนคูลดาวน์หมดพอดี)
    Farm.SettleTime = 0.25

    function Farm.EngageLead(Mob)
        return Farm.SettleTime + 0.05
    end

    ---- Chest + Loot Drop pickup ----
    --
    -- ทั้งกล่อง (Chest) และของที่มอน/บอสดรอปตามพื้น (LootDrop) ใช้ CollectionService tag
    -- เดียวกับที่เกมใช้เอง (gameSettings.Tags.Chest / Tags.LootDrop) แต่ละชิ้นมี ProximityPrompt
    -- ในตัว (ปิดอัตโนมัติถ้ายังไม่ใช่ของเรา/ยังผนึกอยู่) - แค่เดินเข้าไปแล้วกด prompt เกม
    -- จัดการที่เหลือเองฝั่ง server ไม่มี remote แยกให้ยิง

    local CollectionService = game:GetService("CollectionService")
    local GameSettings = GlobalModule("gameSettings")
    local Tags = (GameSettings and GameSettings.Tags) or {}

    Farm.PickupTags = { Tags.Chest or "Chest", Tags.LootDrop or "LootDrop" }

    -- หา ProximityPrompt ที่ยัง Enabled อยู่ในของแท็กเดียว (Chest หรือ LootDrop)
    local function GetPickupTargets(Tag)
        local List = { }

        local Ok, Tagged = pcall(function()
            return CollectionService:GetTagged(Tag)
        end)
        if not Ok then return List end

        for _, Inst in ipairs(Tagged) do
            if Inst.Parent then
                local Ok2, Prompt = pcall(function()
                    return Inst:FindFirstChildWhichIsA("ProximityPrompt", true)
                end)

                if Ok2 and Prompt and Prompt.Enabled then
                    local Position = nil

                    if Inst:IsA("Model") then
                        Position = Inst:GetPivot().Position
                    elseif Inst:IsA("BasePart") then
                        Position = Inst.Position
                    end

                    if Position then
                        table.insert(List, { Instance = Inst, Prompt = Prompt, Position = Position })
                    end
                end
            end
        end

        return List
    end

    -- ใกล้สุดในแท็กเดียว (ไว้ debug/ใช้แยกได้ถ้าต้องการเจาะเฉพาะ Chest หรือ LootDrop)
    function Farm.GetNearestPickup(Origin, Tag)
        local Best, BestDistance = nil, math.huge
        for _, Entry in ipairs(GetPickupTargets(Tag)) do
            local Distance = (Entry.Position - Origin).Magnitude
            if Distance < BestDistance then
                Best, BestDistance = Entry, Distance
            end
        end
        return Best, BestDistance
    end

    -- ใกล้สุดรวมทั้งสองแท็ก (Chest + LootDrop) - ใช้ตัวนี้ในลูปฟาร์มจริง
    function Farm.GetNearestAnyPickup(Origin)
        local Best, BestDistance = nil, math.huge
        for _, Tag in ipairs(Farm.PickupTags) do
            local Entry, Distance = Farm.GetNearestPickup(Origin, Tag)
            if Entry and Distance < BestDistance then
                Best, BestDistance = Entry, Distance
            end
        end
        return Best, BestDistance
    end

    -- กด ProximityPrompt ของกล่อง/ของดรอป (เหมือน fireproximityprompt ที่ใช้เก็บไข่ใน RideAPet)
    -- prompt แบบกดค้าง (LootDrop "Claim" HoldDuration 2 - เกมเปลี่ยนมาเป็นแบบนี้แล้ว fireproximityprompt
    -- ไม่นับ) = InputHoldBegin ค้างจริงจนครบเวลาแล้วค่อย InputHoldEnd ตรึงตัวไว้ข้างของตลอด
    -- (กดค้างหลายชิ้นพร้อมกันได้แค่ชิ้นเดียว เลยทีละชิ้น) - กดผ่าน Prompts.Use หันกล้องไปหาทุกครั้ง
    function Farm.CollectPickup(Entry)
        if not Entry or not Entry.Prompt or not Entry.Prompt.Enabled then return false end
        local Prompt = Entry.Prompt

        if Prompt.HoldDuration > 0 then
            local Holder = Prompt.Parent
            local At = (Holder and Holder:IsA("BasePart") and Holder.Position)
                or (Holder and Holder:IsA("Attachment") and Holder.WorldPosition) or Entry.Position
            if typeof(At) == "Vector3" then
                Movement.Lock(CFrame.new(At + Vector3.new(0, 2.5, 0)))
                task.wait(0.15)     -- ให้เซิร์ฟเห็นตำแหน่งใหม่ก่อนเริ่มกด (prompt ระยะ 10)
            end

            local Ok = Prompts.Use(Prompt)
            Movement.Lock(nil)
            return Ok
        end

        return Prompts.Use(Prompt, { Wait = 0.15 })
    end

    --// เก็บของหลังฆ่าบอส (เก็บเสมอ ไม่สน toggle Auto Collect Chest)
    --
    -- ยืนยันสด (Mother Bear): บอสตาย = เกิด "Common Chest" (tag Chest, ChestState = Spawned, prompt เปิด)
    -- ตรงจุดที่บอสตาย -> กด prompt แล้วกล่องพ่น LootDrop ออกมา (DropPrivate + DropOwnerUserId = เรา)
    -- วนเก็บทุกอย่างในรัศมีรอบจุดตายจนเงียบไป 3 วิ (กล่องใช้เวลาเกิดแป๊บนึงหลังบอสตาย รอได้สูงสุด 10 วิ)
    -- ของคนอื่น (DropOwnerUserId ไม่ใช่เรา) ข้าม / กล่องโลกที่ยังล็อก (prompt ปิด) GetPickupTargets กรองทิ้งให้แล้ว
    local BossLootRadius = 120

    -- Hurry = ฟังก์ชัน คืน true = มีงานรีบรออยู่ (เควสรอรับ) - ยังไม่เจอของเลยเกิน HurryAfter วิ = เลิกรอกล่อง
    -- (วัดสด Kaiden: ไม่มีกล่องเกิด ยืนรอเปล่าครบ 10 วิก่อนไปรับเควส)
    local HurryAfter = 3

    function Farm.CollectBossLoot(Center, ShouldContinue, Hurry)
        if typeof(Center) ~= "Vector3" then return 0 end

        local UserId = LocalPlayer.UserId
        local StartedAt = os.clock()
        local Deadline = os.clock() + 10
        local Collected = 0
        local Tried = { }

        while os.clock() < Deadline and (not ShouldContinue or ShouldContinue()) do
            local Root = Movement.GetRoot()
            if not Root then break end

            local Best, BestDistance = nil, math.huge
            for _, Tag in ipairs(Farm.PickupTags) do
                for _, Entry in ipairs(GetPickupTargets(Tag)) do
                    local Owner = Entry.Instance:GetAttribute("DropOwnerUserId")
                    local Distance = (Entry.Position - Center).Magnitude

                    if (Owner == nil or Owner == UserId) and Distance <= BossLootRadius
                        and (Tried[Entry.Instance] or 0) < 3 and Distance < BestDistance then
                        Best, BestDistance = Entry, Distance
                    end
                end
            end

            if Best then
                Tried[Best.Instance] = (Tried[Best.Instance] or 0) + 1
                Movement.Lock(nil)
                Movement.Go(Best.Position + Vector3.new(0, 3, 0), 4, 10, ShouldContinue)
                Farm.CollectPickup(Best)
                Collected = Collected + 1
                -- เก็บติดแล้วของหาย/prompt ปิด = ไปชิ้นต่อไปเลย ไม่รอ 0.4 วิเต็ม
                Farm.WaitFor(function()
                    return not Best.Instance.Parent or (Best.Prompt ~= nil and not Best.Prompt.Enabled)
                end, 0.4, ShouldContinue)
                Deadline = math.max(Deadline, os.clock() + 3)
            else
                if Collected == 0 and Hurry and os.clock() - StartedAt >= HurryAfter and Hurry() then break end
                task.wait()
            end
        end

        return Collected
    end

    --// เปิดกล่อง Sealed Cache แล้วเก็บของเล็ก ๆ ที่พ่นออกมาให้หมดก่อนไปต่อ
    --
    -- ยืนยันสด: กด prompt กล่อง -> ChestState = Opened แล้วพ่น LootDrop (Part ใน workspace.LootDrops,
    -- tag LootDrop, prompt ระยะ 10, บินลงพื้น ~0.57 วิ) ชิ้นละไอเทม เช่น Silk Thread / Refinement Ore /
    -- Coin Stack / Metal Scraps ตกรอบกล่องไม่เกิน ~20 studs - กด prompt ของแต่ละชิ้น = Part หายไปเลย
    -- ต่างจาก CollectBossLoot: รอของตกให้ครบก่อน, หยุดรอแป๊บหลังไปถึงให้ server อัปเดตตำแหน่งเรา
    -- ก่อนกด (กดทันทีที่ถึงโดนปัดตกว่าไกลเกิน), เช็คว่าชิ้นนั้นหายจริงก่อนไปชิ้นถัดไป,
    -- และจะไม่ออกจากกล่องจนกว่าไม่เหลือของในรัศมีแล้ว
    local CacheLootRadius = 40

    -- ยังมีของตกค้างรอบกล่องนี้ไหม (ใช้เช็คกล่องที่ Opened ไปแล้วแต่เก็บไม่ครบ - โดนขัดกลางคัน)
    function Farm.CacheLootLeft(Center)
        local UserId = LocalPlayer.UserId
        for _, Entry in ipairs(GetPickupTargets(Tags.LootDrop or "LootDrop")) do
            local Owner = Entry.Instance:GetAttribute("DropOwnerUserId")
            if (Owner == nil or Owner == UserId) and (Entry.Position - Center).Magnitude <= CacheLootRadius then
                return true
            end
        end
        return false
    end

    function Farm.CollectCacheLoot(Cache, ShouldContinue)
        if not (Cache and Cache.Prompt) then return 0 end

        local function Continue()
            return not ShouldContinue or ShouldContinue()
        end

        local Center = Cache.Position
        local UserId = LocalPlayer.UserId

        local OpenDeadline = os.clock() + 6
        while Continue() and Cache.Prompt.Enabled and Cache.Instance.Parent and os.clock() < OpenDeadline do
            Movement.Lock(nil)
            Movement.Go(Center + Vector3.new(0, 3, 0), 4, 15, ShouldContinue)
            Farm.Sleep(0.2, Continue)       -- ให้เซิร์ฟเห็นตำแหน่งใหม่ก่อนกด
            Farm.CollectPickup(Cache)
            Farm.WaitFor(function() return not Cache.Prompt.Enabled end, 0.5, Continue)
        end

        local Collected = 0
        local Tried = { }
        local Deadline = os.clock() + 25
        local QuietUntil = os.clock() + 3      -- ยังไม่เห็นของเลย รอให้พ่นออกมาได้สูงสุดเท่านี้

        while Continue() and os.clock() < Deadline do
            local Root = Movement.GetRoot()
            if not Root then break end

            local Best, BestDistance = nil, math.huge
            for _, Entry in ipairs(GetPickupTargets(Tags.LootDrop or "LootDrop")) do
                local Owner = Entry.Instance:GetAttribute("DropOwnerUserId")
                if (Owner == nil or Owner == UserId) and (Entry.Position - Center).Magnitude <= CacheLootRadius
                    and (Tried[Entry.Instance] or 0) < 5 then
                    local Distance = (Entry.Position - Root.Position).Magnitude
                    if Distance < BestDistance then
                        Best, BestDistance = Entry, Distance
                    end
                end
            end

            if Best then
                Tried[Best.Instance] = (Tried[Best.Instance] or 0) + 1
                Movement.Lock(nil)
                Movement.Go(Best.Instance.Position + Vector3.new(0, 2, 0), 3, 10, ShouldContinue)
                Farm.Sleep(0.15, Continue)      -- ให้เซิร์ฟเห็นตำแหน่งใหม่ก่อนกด
                Farm.CollectPickup(Best)

                Farm.WaitFor(function()
                    return not Best.Instance.Parent or not Best.Prompt.Enabled
                end, 1, Continue)
                if not Best.Instance.Parent or not Best.Prompt.Enabled then
                    Collected = Collected + 1
                end

                QuietUntil = os.clock() + 1.5
            elseif os.clock() > QuietUntil then
                break
            else
                task.wait()
            end
        end

        return Collected
    end

    ---- Sealed Cache camp ----
    --
    -- ยืนยันสด: แคมป์ = กล่อง "Sealed Cache T2" ใน workspace.Chests (ChestModel = "Sealed Chest",
    -- ChestState = Locked, prompt ปิด) มีการ์ดเฝ้าอยู่รอบ ๆ ใน Humanoids.Regions.Temporary.ActiveNpcs
    -- (Grove Raider / Raid Captain / Cache Lancer / Lancer Captain / Cache Prowler / Prowler Captain)
    -- ฆ่าการ์ดหมด = กล่องปลดผนึก (prompt เปิด) แล้วกดเก็บได้เหมือนกล่องบอส
    -- Spawning.Locations ของการ์ดเป็นค่า template เดียวกันหมด ใช้หาแคมป์ไม่ได้ ต้องยึดตำแหน่งกล่องแทน
    -- StreamingEnabled = กล่อง/การ์ดไกล ๆ ไม่โหลด เลยต้องบินไล่ดูจุดเกิดกล่องที่เกมตั้งไว้เอง
    -- (Ouwland.Content.Misc.Npcs."Sealed Chest T1/T2/T3".Spawns - T1 8 จุด, T2/T3 12 จุด, สุ่มเปิดทีละ 3-5 จุด)

    -- อ่าน config กล่องทุก tier ครั้งเดียว: จุดเกิด + ชื่อการ์ด -> tier
    -- (Guards[].Config บางตัวไม่มีช่องว่าง เช่น "GroveRaider" แต่ชื่อโมเดลจริงคือ "Grove Raider" เลยเทียบแบบตัดช่องว่าง)
    local CacheInfo = nil

    local function Squash(Name)
        return (tostring(Name):gsub("%s", ""):lower())
    end

    function Farm.GetCacheInfo()
        if CacheInfo then return CacheInfo end

        local Info = { Spawns = { }, GuardTier = { }, Tiers = { } }
        pcall(function()
            for _, Module in ipairs(ReplicatedStorage.Ouwland.Content.Misc.Npcs:GetChildren()) do
                local Tier = Module:IsA("ModuleScript") and Module.Name:match("^Sealed Chest (T%d+)$")
                local Ok, Config = false, nil
                if Tier then Ok, Config = pcall(require, Module) end

                if Ok and type(Config) == "table" then
                    table.insert(Info.Tiers, Tier)

                    for _, Spawn in ipairs(type(Config.Spawns) == "table" and Config.Spawns or { }) do
                        local Position = typeof(Spawn) == "CFrame" and Spawn.Position or Spawn
                        if typeof(Position) == "Vector3" then
                            table.insert(Info.Spawns, { Position = Position, Tier = Tier })
                        end
                    end

                    local Event = type(Config.WorldEvent) == "table" and Config.WorldEvent or { }
                    for _, Guard in ipairs(type(Event.Guards) == "table" and Event.Guards or { }) do
                        if Guard.Config then Info.GuardTier[Squash(Guard.Config)] = Tier end
                        if Guard.NpcCode then Info.GuardTier[Squash(Guard.NpcCode)] = Tier end
                    end
                end
            end
        end)

        -- โหลดไม่ขึ้น = อย่า cache ตารางเปล่า ลองใหม่รอบหน้า
        table.sort(Info.Tiers)
        if #Info.Spawns > 0 then CacheInfo = Info end
        return Info
    end

    -- Tiers = { T1 = true, ... } (nil = ทุก tier) - การ์ดที่ไม่รู้ tier ข้ามเมื่อมีการกรอง
    function Farm.GetNearestCampMob(Origin, Tiers)
        local GuardTier = Farm.GetCacheInfo().GuardTier
        local Humanoids = workspace:FindFirstChild("Humanoids")
        local Regions = Humanoids and Humanoids:FindFirstChild("Regions")
        local Temporary = Regions and Regions:FindFirstChild("Temporary")
        local Active = Temporary and Temporary:FindFirstChild("ActiveNpcs")
        if not Active then return nil end

        local Best, BestDistance = nil, math.huge
        for _, Folder in ipairs(Active:GetChildren()) do
            local Model = Folder:FindFirstChildOfClass("Model")
            local Humanoid = Model and Model:FindFirstChildOfClass("Humanoid")
            local MobRoot = Model and Model:FindFirstChild("HumanoidRootPart")
            local Tier = GuardTier[Squash(Folder.Name)]
            if Humanoid and MobRoot and Humanoid.Health > 0 and (not Tiers or (Tier and Tiers[Tier])) then
                local Distance = (MobRoot.Position - Origin).Magnitude
                if Distance < BestDistance then
                    Best = { Model = Model, Root = MobRoot, Humanoid = Humanoid, IsBoss = false }
                    BestDistance = Distance
                end
            end
        end
        return Best, BestDistance
    end

    function Farm.GetSealedCaches(Tiers)
        local List = { }
        local Chests = workspace:FindFirstChild("Chests")
        if not Chests then return List end

        for _, Chest in ipairs(Chests:GetChildren()) do
            local Tier = tostring(Chest:GetAttribute("ChestId") or Chest.Name):match("^Sealed Cache (T%d+)")
            if Chest:IsA("Model") and Tier and (not Tiers or Tiers[Tier]) then
                local Prompt = Chest:FindFirstChildWhichIsA("ProximityPrompt", true)
                if Prompt then
                    table.insert(List, {
                        Instance = Chest,
                        Prompt = Prompt,
                        Position = Chest:GetPivot().Position,
                        Open = Prompt.Enabled,
                        Opened = Chest:GetAttribute("ChestState") == "Opened",
                        Tier = Tier,
                    })
                end
            end
        end
        return List
    end

    ---- Boss respawn + filler (มอนด่านก่อนหน้า) ----

    --// รายชื่อ NPC ทั้งเกมจาก ReplicatedStorage.Ouwland.Content.<โซน>.ActiveNpcs.<module>
    -- module อยู่ครบเสมอไม่ติด streaming (โฟลเดอร์ใน workspace โหลดทีละโซน - สคริปต์รันตอนเข้าเกม
    -- ได้บอสแค่ไม่กี่ตัวแล้ว cache ค้าง) วัดสด: 49 module ตรงกับ workspace ทุกตัว ยกเว้นการ์ดแคมป์ (Temporary)
    -- Config.Name = ชื่อโฟลเดอร์/โมเดลจริง (module "Reaper Trainee" -> "Reaper Trainee Kuzan")
    -- SendOver.Boss มีเฉพาะบอส / SendOver.Spawning.Center = จุดเกิด / SpawnTime = วินาที
    local NpcCatalog = nil

    function Farm.GetNpcCatalog()
        if NpcCatalog then return NpcCatalog end

        local Catalog = { }
        pcall(function()
            for _, Region in ipairs(ReplicatedStorage.Ouwland.Content:GetChildren()) do
                local Active = Region:FindFirstChild("ActiveNpcs")
                for _, Module in ipairs(Active and Active:GetDescendants() or { }) do
                    if Module:IsA("ModuleScript") then
                        local Ok, Config = pcall(require, Module)
                        local SendOver = Ok and type(Config) == "table" and type(Config.SendOver) == "table" and Config.SendOver
                        local Name = SendOver and (type(Config.Name) == "string" and Config.Name or Module.Name)
                        if Name and not Catalog[Name] then
                            local Spawning = type(SendOver.Spawning) == "table" and SendOver.Spawning or { }

                            -- จุดเกิดจริงแต่ละจุด (Locations) เฉลี่ยแล้วใกล้ตัวจริงกว่า Center (Center บางตัวคลาด 100+ studs)
                            local Sum, Count = Vector3.zero, 0
                            for _, Location in ipairs(type(Spawning.Locations) == "table" and Spawning.Locations or { }) do
                                local Position = typeof(Location) == "CFrame" and Location.Position or Location
                                if typeof(Position) == "Vector3" then Sum, Count = Sum + Position, Count + 1 end
                            end

                            Catalog[Name] = {
                                Spawn = Count > 0 and Sum / Count or nil,
                                Name = Name,
                                Region = Region.Name,
                                IsBoss = SendOver.Boss ~= nil,
                                Center = typeof(Spawning.Center) == "Vector3" and Spawning.Center or nil,
                                SpawnTime = tonumber(Spawning.SpawnTime),
                            }
                        end
                    end
                end
            end
        end)

        -- โหลดไม่ขึ้น (อีก place ไม่มี Ouwland) = อย่า cache ตารางเปล่า
        if next(Catalog) then NpcCatalog = Catalog end
        return Catalog
    end

    -- บอส = SendOver.Boss ใน catalog / ไม่มีใน catalog = โฟลเดอร์ ActiveNpcs.<ชื่อ> มี Configuration
    -- "BossInfo" ใน workspace (โฟลเดอร์ค้างอยู่แม้โมเดลตาย/หลุด streaming) cache ไว้ เปลี่ยนไม่ได้ระหว่างเกม
    local BossNameCache = { }

    function Farm.IsBossName(MonName)
        if BossNameCache[MonName] ~= nil then return BossNameCache[MonName] end

        local Known = Farm.GetNpcCatalog()[MonName]
        if Known then
            BossNameCache[MonName] = Known.IsBoss
            return Known.IsBoss
        end

        local Humanoids = workspace:FindFirstChild("Humanoids")
        local Regions = Humanoids and Humanoids:FindFirstChild("Regions")
        if not Regions then return false end

        for _, Region in ipairs(Regions:GetChildren()) do
            local Active = Region:FindFirstChild("ActiveNpcs")
            local Folder = Active and Active:FindFirstChild(MonName)
            if Folder then
                BossNameCache[MonName] = Folder:FindFirstChild("BossInfo") ~= nil
                return BossNameCache[MonName]
            end
        end

        return false
    end

    --// บอสเฉพาะกลางคืน (Domae / Reaper / Sumari / Yahari - ยืนยันสด) ตอนกลางวันไม่เกิดเลย
    -- กฎเดียวกับ BossUI ของเกม: BossInfo attribute OnlyAtNight == true และ DayAndNightHandler.IsEnabled()
    -- และ not IsNight() = ยังไม่เกิด (ฟาร์มไปรอเปล่า ๆ) - คืนวินาทีที่เหลือจนถึงกลางคืนด้วย
    local DayNight = GlobalModule("DayAndNightHandler")

    function Farm.NightOnlyWaiting(MonName)
        if not DayNight then return false end

        local Humanoids = workspace:FindFirstChild("Humanoids")
        local Regions = Humanoids and Humanoids:FindFirstChild("Regions")
        for _, Region in ipairs(Regions and Regions:GetChildren() or { }) do
            local Active = Region:FindFirstChild("ActiveNpcs")
            local Info = Active and Active:FindFirstChild(MonName)
            Info = Info and Info:FindFirstChild("BossInfo")
            if Info then
                if Info:GetAttribute("OnlyAtNight") ~= true then return false end

                local Ok, Blocked = pcall(function()
                    return DayNight.IsEnabled() and not DayNight.IsNight()
                end)
                if not (Ok and Blocked) then return false end

                local Ok2, Left = pcall(DayNight.SecondsUntilPhaseChange)
                return true, Ok2 and tonumber(Left) or nil
            end
        end
        return false
    end

    --// cooldown บอสจากเกมเอง (วัดสด 2026-09-27): โฟลเดอร์ ActiveNpcs.<ชื่อ> มี attribute DespawnedAt
    -- = เวลาเซิร์ฟ (workspace:GetServerTimeNow) ตอนบอสตาย/หาย + BossInfo.SpawnTime = วินาทีจนเกิดใหม่ (300)
    -- โฟลเดอร์ replicate ทุกตัวไม่ติด streaming -> รู้ว่าบอสตัวไหนตายอยู่โดยไม่ต้องบินไปดู
    -- คืนวินาทีที่เหลือ (0 = เกิดอยู่) / nil = ไม่มีข้อมูล (ใช้วิธีเดาเดิม)
    function Farm.BossCooldown(MonName)
        local Humanoids = workspace:FindFirstChild("Humanoids")
        local Regions = Humanoids and Humanoids:FindFirstChild("Regions")
        for _, Region in ipairs(Regions and Regions:GetChildren() or { }) do
            local Active = Region:FindFirstChild("ActiveNpcs")
            local Folder = Active and Active:FindFirstChild(MonName)
            local Info = Folder and Folder:FindFirstChild("BossInfo")
            if Info then
                local At, Spawn = Folder:GetAttribute("DespawnedAt"), Info:GetAttribute("SpawnTime")
                if type(At) ~= "number" or type(Spawn) ~= "number" then return nil end

                -- เห็นตัวอยู่: ยังไม่ตาย = เกิดอยู่ / เลือดหมดแล้ว = เพิ่งตาย (DespawnedAt อัปเดตตอนโมเดลหาย)
                local Model = Folder:FindFirstChildOfClass("Model")
                local Humanoid = Model and Model:FindFirstChildOfClass("Humanoid")
                if Humanoid then return Humanoid.Health > 0 and 0 or Spawn end

                return math.max(0, At + Spawn - workspace:GetServerTimeNow())
            end
        end
        return nil
    end

    -- บอสทุกตัวในเกม (ไม่ใช่แค่ที่อยู่ใน LevelConfig) - ActiveNpcs.<ชื่อ>.BossInfo เป็น Configuration
    -- ที่มี attribute Center (จุดเกิด), Title (ฉายา เช่น "The Flame Hashira"), SpawnTime (วินาที)
    -- ใช้ทำรายชื่อใน dropdown ของ Auto Farm Boss และปั้น entry ให้ตัวที่ไม่มีใน LevelConfig
    local WorldBossCache = nil

    function Farm.GetWorldBosses()
        if WorldBossCache then return WorldBossCache end

        local Bosses = { }
        for Name, Npc in pairs(Farm.GetNpcCatalog()) do
            if Npc.IsBoss then
                Bosses[Name] = { Name = Name, Region = Npc.Region, SpawnTime = Npc.SpawnTime, Center = Npc.Center, Spawn = Npc.Spawn }
            end
        end

        local Humanoids = workspace:FindFirstChild("Humanoids")
        local Regions = Humanoids and Humanoids:FindFirstChild("Regions")

        for _, Region in ipairs(Regions and Regions:GetChildren() or { }) do
            local Active = Region:FindFirstChild("ActiveNpcs")
            if Active then
                for _, Folder in ipairs(Active:GetChildren()) do
                    local Info = Folder:FindFirstChild("BossInfo")
                    local Known = Info and Bosses[Folder.Name]
                    if Known then
                        -- มีใน catalog แล้ว - เติมฉายาจาก BossInfo (module ไม่มีเก็บไว้)
                        Known.Title = Known.Title or Info:GetAttribute("Title")
                    elseif Info then
                        local Center = Info:GetAttribute("Center")
                        Bosses[Folder.Name] = {
                            Name = Folder.Name,
                            Region = Region.Name,
                            Title = Info:GetAttribute("Title"),
                            SpawnTime = tonumber(Info:GetAttribute("SpawnTime")),
                            Center = typeof(Center) == "Vector3" and Center or nil,
                        }
                    end
                end
            end
        end

        -- cache เฉพาะตอน catalog โหลดแล้ว (workspace อย่างเดียวได้ไม่ครบตอนโซนยังไม่โหลด)
        if NpcCatalog and next(Bosses) then WorldBossCache = Bosses end
        return Bosses
    end

    -- entry ปลอมสำหรับมอน/บอสที่ไม่มีใน LevelConfig - ใช้จุดเกิด (catalog / BossInfo.Center) เป็น MonPOS
    -- ไม่มี QuestName (FindQuestIdForMob จะหาจากชื่อมอนเอง) และ Level = 1 เพื่อไม่ไปยุ่งกับการไล่ด่าน
    local WorldBossEntries = { }

    function Farm.GetCatalogEntry(MonName)
        if WorldBossEntries[MonName] then return WorldBossEntries[MonName] end

        local Boss = Farm.GetWorldBosses()[MonName] or Farm.GetNpcCatalog()[MonName]
        if not Boss or not Boss.Center then return nil end

        WorldBossEntries[MonName] = {
            Level = 1,
            QuestName = "",
            MonName = MonName,
            MonPOS = Boss.Spawn or Boss.Center,
            WaitPOS = Boss.Spawn or Boss.Center,
        }
        return WorldBossEntries[MonName]
    end

    -- เวลาเกิดใหม่จริงของมอน (วินาที) จาก ReplicatedStorage.Ouwland.Content.<Region>.ActiveNpcs.<ชื่อ>
    -- (SendOver.Spawning.SpawnTime เช่น Zuko 135, Mother Bear 150) - หาไม่เจอ = 120
    local SpawnTimeCache = { }
    local DefaultSpawnTime = 120

    function Farm.GetSpawnTime(MonName)
        if SpawnTimeCache[MonName] then return SpawnTimeCache[MonName] end

        local Found = nil
        pcall(function()
            for _, Region in ipairs(ReplicatedStorage.Ouwland.Content:GetChildren()) do
                local Active = Region:FindFirstChild("ActiveNpcs")
                local Module = Active and Active:FindFirstChild(MonName, true)
                if Module and Module:IsA("ModuleScript") then
                    local Config = require(Module)
                    Found = Config.SendOver.Spawning.SpawnTime
                    break
                end
            end
        end)

        -- หาใน module ไม่เจอ (บอสบางตัวเก็บไว้ที่ BossInfo.SpawnTime แทน) ค่อยตกมาใช้ค่า default
        if not Found then
            local Boss = Farm.GetWorldBosses()[MonName]
            Found = Boss and Boss.SpawnTime
        end

        SpawnTimeCache[MonName] = tonumber(Found) or DefaultSpawnTime
        return SpawnTimeCache[MonName]
    end

    function Farm.GetEntryByName(MonName)
        if type(MonName) ~= "string" or MonName == "" then return nil end

        local Levels = getgenv().LevelConfig
        if type(Levels) == "table" then
            for _, Entry in ipairs(Levels) do
                if type(Entry) == "table" and Entry.MonName == MonName then
                    return Entry
                end
            end
        end

        -- ไม่มีใน LevelConfig แต่มีในเกม = ปั้น entry จากจุดเกิดให้
        return Farm.GetCatalogEntry(MonName)
    end

    -- รายชื่อมอนธรรมดา / บอส (ไว้โชว์ใน dropdown): ตัวใน LevelConfig ก่อน (เรียงตาม Level) แล้วตามด้วยทั้งเกม
    function Farm.GetConfigMobNames(WantBoss)
        local Names = { }
        local Levels = getgenv().LevelConfig
        if type(Levels) ~= "table" then return Names end

        for _, Entry in ipairs(Levels) do
            if type(Entry) == "table" and type(Entry.MonName) == "string" and Entry.MonName ~= ""
                and Farm.IsBossName(Entry.MonName) == WantBoss and not table.find(Names, Entry.MonName) then
                table.insert(Names, Entry.MonName)
            end
        end

        -- ต่อท้ายด้วยตัวที่เหลือทั้งเกม (LevelConfig มีแค่ไม่กี่ตัว) เรียงตามโซน -> ชื่อ
        local Pool = WantBoss and Farm.GetWorldBosses() or Farm.GetNpcCatalog()
        local Extra = { }
        for Name, Npc in pairs(Pool) do
            if Npc.Center and (WantBoss or not Npc.IsBoss) and not table.find(Names, Name) then
                table.insert(Extra, Npc)
            end
        end

        table.sort(Extra, function(A, B)
            if A.Region ~= B.Region then return A.Region < B.Region end
            return A.Name < B.Name
        end)

        for _, Npc in ipairs(Extra) do
            table.insert(Names, Npc.Name)
        end

        return Names
    end

    -- entry ที่ Level สูงสุดแต่ต่ำกว่า Entry นี้ (ด่านก่อนหน้าใน LevelConfig) เช่น Zuko -> Bandit
    function Farm.GetPreviousEntry(Entry)
        local Levels = getgenv().LevelConfig
        if type(Levels) ~= "table" or not Entry then return nil end

        local Selected = nil
        for _, Other in ipairs(Levels) do
            if type(Other) == "table" and type(Other.Level) == "number" and Other.Level < Entry.Level
                and type(Other.MonName) == "string" and Other.MonName ~= "" then
                if not Selected or Other.Level > Selected.Level then
                    Selected = Other
                end
            end
        end

        return Selected
    end
end

---- ============ Fighter (ตีมอน + หลบ - ใช้ร่วม Auto Farm / Auto Trial) ============ ----
--
-- ย้ายออกมาจากบล็อก Auto Farm ให้ Auto Trial (ด่าน Final Selection ที่ไม่มี UI) ใช้ตัวเดียวกันเป๊ะ ๆ
-- Fighter.Continue = ฟังก์ชัน "ยังรันต่อไหม" ของคนที่กำลังใช้อยู่ (RunFarm / Trial) ตั้งตอนเริ่ม
-- เคลียร์เป็น nil ตอนเลิก - nil = ไม่มีใครใช้อยู่ ตัวดักหนีสกิล/โดนตีก็เงียบไปด้วย
-- AttackTarget = มอนที่กำลังยืนตีอยู่จริงตอนนี้ (nil ระหว่างหลบสกิลบอส/เดินทาง) - Auto Use Skill
-- ใช้เป็นเป้าเดียวที่ยอมยิงสกิลใส่ / SkillBusy = Auto Use Skill กำลังเงื้อท่าอยู่ ตัวตีต้องยืนนิ่ง
-- ที่จุดตีรอจนปล่อยท่า (ไม่ตีธรรมดาแทรกกลางท่า)
-- (SkillBusy เก็บเป็น os.clock() ตอนเริ่มเงื้อ - เกิน 8 วิถือว่าค้าง กันเธรดสกิลพังกลางทางแล้วตัวตียืนแข็งตลอดไป
-- เงื้อ ~0.3-3 วิ + รอท่าเล่นจบสูงสุด SkillRecoverMax)
local Fighter = { Continue = nil, AttackTarget = nil, SkillBusy = nil }

function Fighter.Casting()
    return Fighter.SkillBusy ~= nil and os.clock() - Fighter.SkillBusy < 8
end

-- Smart Weapon ถืออาวุธยืมมายิงสกิลอยู่ (ไม่ใช่อาวุธที่ผู้เล่นเลือก) = ห้าม M1 - M1 ใช้อาวุธที่เลือกเท่านั้น
-- HomeTool/HomeAt ลูปสกิลตั้งทุกรอบ (0.2 วิ + เวลาเงื้อสกิล) - เกิน 3 วิถือว่าลูปตาย ปล่อยให้ตีต่อ
-- อ่านอาวุธในมือสด ๆ ทุกครั้ง (ของเดิมเก็บผลไว้ในลูปสกิล = ช่วงยิงสกิลต่อกันผลค้าง M1 หลุดด้วยอาวุธยืม)
function Fighter.OffWeaponHold()
    local Config = getgenv().ConfigurationTable
    if not (Config.SmartWeapon and Config.AutoUseSkill and Fighter.HomeTool) then return false end
    if os.clock() - (Fighter.HomeAt or 0) > 3 then return false end
    local Current = Farm.GetEquippedToolName()
    return Current ~= nil and Current ~= Fighter.HomeTool
end

do
    --// ConfigFarm: state machine ฟาร์มหลัก (โครงเดียวกับ VenuzFarm ใน Haze Sea)
    --
    -- อ่านเป้าปัจจุบันจาก getgenv().LevelConfig ตาม Level ผู้เล่น
    -- ตีย้ำมอนชนิดเดียวกันซ้ำ ๆ (MonName) จนกว่า Level จะพ้น ReqLevel ค่อยขยับไปตัวถัดไปในลิสต์
    -- เปิด Auto Accept Quest = รับ quest ที่ผูกกับมอนตัวนั้นก่อนเสมอ ไม่รับ = ไม่ฟาร์ม (hard gate)
    -- ยืนเกาะมอนตีตลอด หลบเฉพาะตอนบอสเริ่มใช้สกิล (Auto Dodge - ดู Escape)
    Farm.ConfigFarm = {
        Running = false,
        Entry = nil,        -- Levels entry ที่กำลังฟาร์มอยู่
        Mob = nil,           -- มอนที่ล็อกเป้าอยู่ตอนนี้
        ComboStart = 0,      -- tick ที่เริ่มคอมโบชุดปัจจุบัน (0 = ยังไม่เริ่ม)
    }

    function Fighter.Reset()
        Farm.ConfigFarm.ArrivedAt = nil
        Farm.ConfigFarm.Entry = nil
        Farm.ConfigFarm.Mob = nil
        Farm.ConfigFarm.ComboStart = 0
    end

    local function Engaged()
        return Fighter.Continue ~= nil
    end

    local function ShouldRun()
        local Continue = Fighter.Continue
        return getgenv().ValkyrieSession == SessionToken and Continue ~= nil and Continue() and true or false
    end

    --// หลบสกิลบอส (Auto Dodge)
    --
    -- หลบ "เฉพาะ" ตอนบอส/มอนเริ่มใช้สกิล: บินหนีไกล ๆ -> ยกเลิก/จบท่า -> กลับเข้าไปตีต่อทันที
    -- ไม่หลบตอนมอนตีธรรมดา / ตอนรอคูลดาวน์คอมโบ / ตอนเลือดลด (ตามที่สั่ง - ยืนเกาะมอนตีตลอด)
    --
    -- สัญญาณ = EffectsEvent(ชื่อ, บอส, phase, ...) ชื่อไม่ตายตัวแต่ละบอส (วัดสดผ่าน dex) เลยดูที่ phase:
    --   Gyutai: ("Telegraph", บอส, "Start", Id, { Face = เป้า, Duration }) มาก่อน "<Skill>_effs" Windup ~0.5 วิ
    --           -> "<Skill>_effs" Start -> End / "Telegraph" Cancel
    --   Akazo : "<Skill> VFX" Start -> Cancel (Demon Core) / Start -> Cutscene -> UltimateCamera (Annihilation Type)
    --   เริ่มท่า = phase Start / Windup / Startup (หมัดธรรมดา "<Style>_Swings" phase เป็นเลขคอมโบ ไม่เข้า)
    --   จบท่า   = phase End / *Cancel* / *Miss* (TrapMiss) จากบอสตัวที่หลบอยู่
    --   "Telegraph" Cancel มาก่อนท่าจบจริงได้ (RotatingBloodScythe: Cancel 10.23 / End 10.88 กลับตอน Cancel
    --   = โดนฮิตสุดท้าย) เลยเชื่อ Telegraph Cancel เฉพาะตอนยังไม่เห็น FX ตัวท่าเอง
    --   ไม่มีสัญญาณจบเลย = กลับเองเมื่อครบ MaxTime (วัดสด Telegraph Start -> End 2.2-3.3 วิ)
    --
    -- หลบ "ข้าง ๆ บนพื้น" (ไม่ขึ้นฟ้าแล้ว - ลอยสูง 300 studs โดนเตะ): ยืนห่างบอสแนวราบเท่ารัศมีท่า + Margin
    -- ทิศตั้งฉากกับแนวบอส->เรา (ด้านข้าง) เลือกฝั่งที่มีพื้น (raycast) ตรึงทิศไว้ทั้งท่า ไม่กระตุกไปมา
    -- รัศมีท่ามาจาก 3 ที่ (เอาค่ามากสุด):
    --   1. Telegraph จริงของเกม (ยืนยัน decompile Effects.Core.Telegraph 2026-09-30): เซิร์ฟยิง
    --      EffectsEvent("Telegraph", บอส, "Start"/"Box"/"Circle"/"Cancel", Id, { Shape = { Width, Length |
    --      Radius, Offset, Live, FreezeAt }, Duration, StartedAt, Anchor, Face }) แล้ว client วาดโซนเป็น Part จริงใน
    --      workspace.Debree["<Id>-Telegraph"] -> อ่าน CFrame/Size ของแผ่นโซนตรง ๆ (Box = Block, Circle = Cylinder)
    --      แล้วยืนนอกโซนทุกอัน + Margin (โซนที่ Live ขยับตามบอส อ่านใหม่ทุกเฟรม)
    --   2. รัศมีที่เรียนรู้ต่อ (บอส|ท่า): หลบอยู่แล้วยังโดนดาเมจ = ระยะนั้นยังไม่พอ -> จำ ระยะที่โดน + LearnStep
    --      เก็บลงไฟล์ ใช้ต่อข้ามรอบ (บอสบางตัวไม่มี Telegraph เลย เช่น Hoyuzo: Scyther Vortex / Execution Scyther
    --      วัดสด 2026-09-30 ดาเมจ -3 ทุก 0.36 วิ ช่วง Tornado->End)
    --   3. ค่าเริ่มต้น Radius (บอส) / MobRadius (มอน) ตอนยังไม่เคยเรียน
    -- กลับทันทีที่: ท่าจบ-ยกเลิก / บอสปล่อยเป้า / ครบ MaxTime (+ บอสยังค้างท่า pause_gameplay = หลบต่อ)
    --
    -- มอนธรรมดาก็หลบด้วย (ทุกโหมดที่ใช้ Fighter: Level/Mob/Boss/Camp/Breathing/Trial) - วัดสด Ice Profound Demon
    -- ใช้ "Ground Slam" Startup -> Slam (Effects.DemonPhysicalAttacks: Ground Slam Startup/Slam,
    -- Asteroid Startup/Jump/Crash, Quick Attack Startup/Dash/Strike) ไม่มี End ส่งมา - phase ลงดาบคือจบท่า
    -- สนใจเฉพาะตัวที่ตามเราอยู่/ตัวที่เรากำลังตี ในระยะ MobReact (มอนฝูงอื่นใช้ท่าใส่คนอื่นไม่ต้องหนี)
    -- ไม่เชื่อการปล่อยเป้าของมอนธรรมดา (ขึ้นฟ้าแล้วมันปล่อยใน ~0.2 วิ ก่อนท่าลง) รอ phase ลงดาบหรือ MobMaxTime
    local Escape = {
        Radius = 40,            -- บอส: ยืนห่างเท่านี้ (แนวราบ) ตอนยังไม่รู้รัศมีท่า
        MobRadius = 24,         -- มอนธรรมดา (Ground Slam ฯลฯ ตีรอบตัว)
        Margin = 8,             -- เผื่อจากขอบโซน Telegraph / รัศมีที่เรียนรู้
        LearnStep = 10,         -- หลบแล้วยังโดน = รัศมีใหม่ = ระยะตอนโดน + เท่านี้
        MaxRadius = 110,        -- ไม่หนีไกลเกินนี้ (ยังอยู่ในระยะ streaming/เห็นท่าจบ)
        FxQuiet = 0.7,          -- บอสไม่ส่ง FX ของท่าเลยนานเท่านี้ (และไม่มี pause_gameplay) = ท่าจบ
        MinDodge = 0.5,         -- หลบอย่างน้อยเท่านี้ก่อนเช็คเงียบ (FX ถัดไปของท่ามาห่างกัน ~0.4-0.5 วิ)
        LastFxAt = 0,
        Zones = function() return { } end,   -- ตั้งเป็น TelegraphZones ข้างล่าง
        React = 90,             -- สนใจเฉพาะบอสที่ใช้สกิลในระยะนี้
        MobReact = 40,          -- มอนธรรมดา: ระยะที่สนใจ (ท่าพวก Ground Slam ตีรอบตัว)
        MaxTime = 8,            -- หลบนานสุดเท่านี้ถ้าไม่เห็นสัญญาณจบท่า/ปล่อยเป้า (วัดสด Domae: Telegraph ยาว 5.3 วิ)
        MobMaxTime = 1.5,       -- มอนธรรมดา: ไม่เห็น phase ลงดาบภายในเท่านี้ = ท่าโดนขัด/ยกเลิก กลับไปตีต่อ (วัดสด Ground Slam Startup -> Slam 0.49 วิ)
        Until = 0,
        CFrame = nil,           -- ฟังก์ชันคืน CFrame (Movement.Lock คำนวณใหม่ทุกเฟรม)
        Source = nil,           -- บอสตัวที่กำลังหลบอยู่
        Followed = false,       -- ตอนเริ่มหลบบอสตามเราอยู่ (อยู่ใน NpcsFollowing) = รอให้มันปล่อยได้
        SawSkillFx = false,     -- FX ตัวท่า (ไม่ใช่ Telegraph) ส่ง phase เริ่มมาแล้ว = รอ End ของมัน ไม่เชื่อ Telegraph Cancel
        Returning = false,      -- เพิ่งเลิกหลบ = รอบหน้าวาร์ปกลับจุดตีทันที ไม่ tween ช้า ๆ
    }

    -- Auto Dodge (แยกต่อแท็บเหมือนตั้งค่าอื่น) ปิด = ไม่หลบสกิลบอส ยืนเกาะมอนตลอด
    local function AutoDodge()
        return ModeSetting("AutoDodge") ~= false
    end

    -- NPC ที่กำลังตามเราอยู่ = ObjectValue ใน Character.NpcsFollowing ชี้ไปที่โมเดลมัน (ชื่อ = UniqueName)
    local function IsFollowingMe(Model)
        local Character = Movement.GetCharacter()
        local Folder = Character and Character:FindFirstChild("NpcsFollowing")
        if not Folder then return false end
        for _, Value in ipairs(Folder:GetChildren()) do
            if Value:IsA("ObjectValue") and Value.Value == Model then return true end
        end
        return false
    end

    --// บอส/มอนกำลังใช้ท่าอยู่จริง (วัดสด Datai 90 วิ): ระหว่างท่ามีลูก "pause_gameplay" บนโมเดลจนท่าจบจริง
    -- ท่า Box (Telegraph): สัญญาณจบมาแล้วเลิกหลบที่ 65.41 แต่บอสยังค้างท่าถึง 66.58 = กลับไปโดน
    -- CoreDetachment Throw ไม่ส่ง phase เริ่มเลย (Throw -> Cancel) แต่มี pause_gameplay 0.8 วิ
    -- pause_gameplay ที่มาพร้อม "noragdoll" (+ iframe ชื่อเรา) = บอสโดนท่าของเราจับอยู่ ไม่ใช่บอสใช้ท่า
    -- ForceStrafe ไม่นับแล้ว (ผู้ใช้ 2026-10-01: บอสเดินไม่ต้องรอ) - พายุ Vortex ใช้ SkillHazards (ของบนพื้น) แทน
    local function ModelCasting(Model)
        return typeof(Model) == "Instance" and Model.Parent ~= nil and Model:FindFirstChild("noragdoll") == nil
            and Model:FindFirstChild("pause_gameplay") ~= nil
    end
    Fighter.ModelCasting = ModelCasting
    local CastHoldMax = 10      -- หลบต่อเพราะบอสค้างท่านานสุดเท่านี้ (กันค้างถ้า pause_gameplay ไม่ยอมหาย)

    local EscapingRaw

    -- สถานะหลบ -> จอง/ปล่อย Dodge ใน HubAction (ท่าที่ต่ำกว่าเห็นแล้วหยุด)
    local function Escaping()
        local Now = EscapingRaw()
        if Now then HubAction.Force("Dodge", 0.5) else HubAction.Release("Dodge") end
        return Now
    end

    function EscapingRaw()
        if not (Escape.CFrame ~= nil and AutoDodge()) then return false end

        -- หมดเวลา/ได้สัญญาณจบท่า/บอสปล่อยเป้าแล้ว แต่บอสยังค้างท่าอยู่จริง = หลบต่อจนท่าจบ (อย่าเพิ่งกลับ)
        if ModelCasting(Escape.Source) and os.clock() - (Escape.StartedAt or 0) < CastHoldMax then
            return true
        end

        if not (os.clock() < Escape.Until) then return false end

        -- ท่าที่ไม่ส่ง End (Kaiden PredatorClaws: Slice1-3 -> Slash4 แล้วเงียบ - วัดสด 2026-09-30 หลบค้างรอครบ
        -- MaxTime 8 วิ ทั้งที่ท่าจบไปแล้ว) = บอสเงียบไม่ส่ง FX เลยเกิน FxQuiet + ไม่ค้างท่า (pause_gameplay) = จบท่า กลับไปตี
        -- ท่าที่เรียนไว้: ยังไม่เห็น phase สุดท้าย = เงียบต้องนานกว่าช่วงเงียบกลางท่าที่เคยเห็น (Execution Scyther ไล่ 2 วิ
        -- ก่อนจับ) / ของที่บอสวางบนพื้นยังอยู่ (พายุ Vortex) = หลบต่อจนมันหายไป
        -- (เดิมบังคับต้องเห็น phase สุดท้าย = ท่าเงื้อหลอก/ท่าโดนตัดกลางทาง ยืนหลบเปล่า ๆ ครบ 8 วิ วัดสด 2026-10-01)
        local Profile = Escape.Profile and Escape.Profile(Escape.Source, Escape.Skill)
        local Final = Profile and Escape.FinalPhase(Profile)
        local Quiet = (Final ~= nil and Escape.Phase == Final) and Escape.FxQuiet
            or math.clamp((Profile and tonumber(Profile.G) or 0) + 0.35, Escape.FxQuiet, 3)
        if Escape.IsBoss and os.clock() - (Escape.StartedAt or 0) >= Escape.MinDodge
            and os.clock() - (Escape.LastFxAt or 0) >= Quiet and not ModelCasting(Escape.Source)
            and #Escape.Zones() == 0 and #Escape.Hazards(Escape.Source) == 0 then
            -- หลบเพราะท่าเงื้อแต่บอสไม่ส่ง FX เลย = animation นั้นไม่ใช่ท่าเงื้อจริง (นับพลาด)
            if Escape.WindupKey and Escape.FalseWindup then Escape.FalseWindup(Escape.WindupKey) end
            Escape.WindupKey = nil
            Escape.Until = 0
            return false
        end

        -- บอสปล่อยเป้าแล้ว (หลุดระยะ = ท่าโดนยกเลิก) - กลับเข้าไปตีได้เลย
        if Escape.Followed and not IsFollowingMe(Escape.Source) then
            Escape.Until = 0
            return false
        end
        return true
    end

    --// รัศมีท่าที่เรียนรู้ { ["บอส|ท่า"] = studs } - เซฟลงไฟล์ ใช้ต่อทุกครั้งที่รัน
    local LearnFile = FolderSettings .. "/DodgeLearn.json"
    local Learned = { }
    pcall(function()
        if isfile and isfile(LearnFile) then
            local Data = HttpService:JSONDecode(readfile(LearnFile))
            if type(Data) == "table" then Learned = Data end
        end
    end)
    local LearnDirty = false
    Fighter.DodgeLearned = Learned      -- ดูสดผ่าน dex

    local function BaseName(Model)
        return typeof(Model) == "Instance" and (Model.Name:gsub("%d+$", "")) or "?"
    end

    local function LearnKey(Source, Skill)
        return BaseName(Source) .. "|" .. tostring(Skill or "?")
    end

    --// ท่าเงื้อของบอส = สัญญาณเร็วสุดก่อนโดน (วัดสด Kaiden PredatorClaws 2026-09-30: animation Action ยาว 2.00 วิ
    -- เริ่ม 0.19 วิก่อนดาเมจแรก + FX Slice1 ที่มาพร้อมดาเมจ) - หมัด M1 ของบอสเป็น Action4 สั้น 0.25-0.53 วิ
    -- เรียน: FX ท่าเริ่ม -> animation ยาว >= WindupMinLength ที่เพิ่งเริ่ม (<= 0.8 วิ) = ท่าเงื้อของท่านั้น
    -- ครั้งต่อไป animation นั้นเริ่มเล่นบนบอสที่ตีอยู่ = หลบทันที ไม่ต้องรอ FX/ดาเมจ
    -- เก็บใน Learned ด้วยคีย์ "@บอส:AnimationId" = ชื่อท่า
    local WindupMinLength = 1

    -- animation เคลื่อนที่ (วิ่ง/เดิน/dash/กระโดด/ตก/ลงพื้น) ไม่ใช่ท่าเงื้อ - ดูจากชื่อ track / Animation
    local MoveWords = { "run", "walk", "dash", "jump", "sprint", "fall", "land", "idle", "climb", "step", "strafe", "dodge", "roll" }
    local function MoveAnimation(Track)
        local Name = (Track.Name .. " " .. (Track.Animation and Track.Animation.Name or "")):lower()
        for _, Word in ipairs(MoveWords) do
            if Name:find(Word, 1, true) then return true end
        end
        return false
    end

    local function WindupTracks(Model)
        local List = { }
        local Humanoid = typeof(Model) == "Instance" and Model:FindFirstChildOfClass("Humanoid")
        local Animator = Humanoid and Humanoid:FindFirstChildOfClass("Animator")
        if not Animator then return List end
        for _, Track in ipairs(Animator:GetPlayingAnimationTracks()) do
            -- animation วนซ้ำ (วิ่ง/ยืน) TimePosition รีเซ็ตทุกรอบ = ไม่ใช่ท่าเงื้อ (วัดสด: เรียนผิดแล้วหลบรัว 18 ครั้ง/28 วิ)
            if not Track.Looped and Track.Priority.Value >= Enum.AnimationPriority.Action.Value
                and Track.Length >= WindupMinLength and not MoveAnimation(Track) then
                local Id = Track.Animation and Track.Animation.AnimationId:match("%d+")
                if Id then table.insert(List, { Id = Id, Track = Track }) end
            end
        end
        return List
    end

    -- เก็บเป็น { S = ชื่อท่า, Y = ครั้งที่ตามด้วยท่าจริง, N = ครั้งที่เล่นแล้วไม่มีท่าตาม } - คีย์แบบเก่า (string) ทิ้ง
    for Key, Value in pairs(Learned) do
        if Key:sub(1, 1) == "@" and type(Value) ~= "table" then Learned[Key] = nil LearnDirty = true end
    end

    local function NoteWindup(Source, Skill)
        if type(Skill) ~= "string" or Skill == "Telegraph" then return end
        for _, Windup in ipairs(WindupTracks(Source)) do
            -- เริ่มก่อน FX ไม่เกิน 0.8 วิ (Kaiden: ท่าเงื้อจริง 0.19 วิ / animation อื่นที่เล่นค้างมา 1.2 วิ ไม่นับ)
            if Windup.Track.TimePosition <= 0.8 then
                local Key = "@" .. BaseName(Source) .. ":" .. Windup.Id
                local Entry = type(Learned[Key]) == "table" and Learned[Key] or { S = Skill, Y = 0, N = 0 }
                Entry.S, Entry.Y = Skill, (Entry.Y or 0) + 1
                Learned[Key] = Entry
                LearnDirty = true
            end
        end
    end

    -- หลบเพราะท่าเงื้อแล้วบอสไม่ใช้ท่าตาม (ไม่มี FX เลยทั้งรอบหลบ) = นับพลาดให้ animation นั้น
    local function NoteFalseWindup(Key)
        local Entry = Key and Learned[Key]
        if type(Entry) == "table" then
            Entry.N = (Entry.N or 0) + 1
            LearnDirty = true
        end
    end

    Escape.FalseWindup = NoteFalseWindup

    --// โปรไฟล์ท่า { ["!บอส|ท่า"] = { G = ช่วงเงียบนานสุดระหว่าง phase, L = { phase สุดท้าย = ครั้ง } } }
    -- ท่าค้าง/ท่าไล่ล่า (วัดสด Hoyuzo 2026-09-30): Execution Scyther Startup -> บอสวิ่งไล่ 1.94 วิ ไม่มี FX
    -- -> Hit (จับตัว) -> Slam -> Cross - เลิกหลบตอนเงียบ 0.7 วิ = กลับเข้าไปให้จับพอดี (ตาย 2 รอบ)
    -- = หลบต่อจนเห็น phase สุดท้ายของท่า (L ที่เจอบ่อยสุด) / เงียบนานกว่าช่วงเงียบที่เคยเห็นในท่านั้น (G)
    local SkillDefaults = {
        ["!Hoyuzo|Execution Scyther_effs"] = { G = 2, L = { Cross = 1 } },
        ["!Hoyuzo|Scyther Vortex_effs"] = { G = 0.5, L = { End = 1 } },
        ["!Kaiden|PredatorClaws_effs"] = { G = 0.5, L = { Slash4 = 1 } },
    }
    for Key, Value in pairs(SkillDefaults) do
        if type(Learned[Key]) ~= "table" then Learned[Key] = Value end
    end

    local SkillGapMax = 4       -- เงียบนานกว่านี้ = จบท่าแล้ว (ไม่นับเป็นช่วงเงียบกลางท่า)
    local Sequences = setmetatable({ }, { __mode = "k" })   -- โมเดลบอส -> { Skill, Phase, At }

    local function SkillProfile(Source, Skill)
        local Profile = Learned["!" .. LearnKey(Source, Skill)]
        return type(Profile) == "table" and Profile or nil
    end

    -- Cancel/Miss = ท่าโดนตัดจบ (วัดสด: Execution Scyther Startup -> เราหนีไกล 58 studs -> Cancel) ไม่ใช่ phase จบปกติ
    local function IsCutPhase(Phase)
        return type(Phase) ~= "string" or Phase:find("Cancel") ~= nil or Phase:find("Miss") ~= nil
    end

    -- phase สุดท้ายที่เจอบ่อยสุดของท่า (ท่าโดนขัดกลางทางนับน้อยกว่า)
    local function FinalPhase(Profile)
        local Best, Count = nil, 0
        for Phase, N in pairs(type(Profile) == "table" and type(Profile.L) == "table" and Profile.L or { }) do
            if not IsCutPhase(Phase) and (N > Count or (N == Count and Phase < Best)) then Best, Count = Phase, N end
        end
        return Best
    end

    local function CloseSequence(Source, Seq)
        if IsCutPhase(Seq.Phase) then return end
        local Key = "!" .. LearnKey(Source, Seq.Skill)
        local Profile = type(Learned[Key]) == "table" and Learned[Key] or { G = 0, L = { } }
        Profile.L = type(Profile.L) == "table" and Profile.L or { }
        Profile.L[Seq.Phase] = (Profile.L[Seq.Phase] or 0) + 1
        Learned[Key] = Profile
        LearnDirty = true
    end

    local function NoteSkillPhase(Source, Skill, Phase)
        local Now = os.clock()
        local Seq = Sequences[Source]
        if Seq and Seq.Skill == Skill and Now - Seq.At < SkillGapMax then
            local Profile = SkillProfile(Source, Skill) or { G = 0, L = { } }
            local Gap = math.floor((Now - Seq.At) * 100 + 0.5) / 100
            if Gap > (Profile.G or 0) then
                Profile.G = Gap
                Learned["!" .. LearnKey(Source, Skill)] = Profile
                LearnDirty = true
            end
        elseif Seq then
            CloseSequence(Source, Seq)
            Seq = nil
        end
        Sequences[Source] = Seq or { Skill = Skill }
        Sequences[Source].Phase, Sequences[Source].At = Phase, Now
    end

    -- ปิดท่าที่เงียบไปนานแล้ว (phase ล่าสุด = phase สุดท้ายของท่า) - เรียกจากลูปเซฟไฟล์
    local function CloseStaleSequences()
        for Source, Seq in pairs(Sequences) do
            if os.clock() - Seq.At >= SkillGapMax then
                CloseSequence(Source, Seq)
                Sequences[Source] = nil
            end
        end
    end

    --// ของที่บอสวางค้างไว้บนพื้น (Hoyuzo Scyther Vortex: พายุ "<ชื่อบอส>_ScytherVortex" กว้าง 36 studs
    -- อยู่กับที่ 4 วิแล้วระเบิด 40x58 ขณะที่บอสกระโดดถอยหนี) = ยืนห่าง + หลบต่อจนมันหายไป
    -- ของที่ติดตัวบอส (ExecScytherLoop ผูก RigidConstraint กับบอส) ไม่นับ - ห่างบอสอยู่แล้ว
    local function SkillHazards(Source)
        local List = { }
        local Debree = workspace:FindFirstChild("Debree")
        local MobRoot = typeof(Source) == "Instance" and Source:FindFirstChild("HumanoidRootPart")
        if not (Debree and MobRoot) then return List end
        local Prefix = Source.Name .. "_"
        for _, Item in ipairs(Debree:GetChildren()) do
            if Item.Name:sub(1, #Prefix) == Prefix then
                local Model = Item:IsA("Model") and Item or Item:FindFirstChildWhichIsA("Model")
                local Ok, Pivot, Size = pcall(function() return Model:GetPivot(), Model:GetExtentsSize() end)
                if Ok and ((Pivot.Position - MobRoot.Position) * Vector3.new(1, 0, 1)).Magnitude >= 10 then
                    local Radius = math.clamp(math.max(Size.X, Size.Z) / 2 * 1.6, 10, 40)
                    table.insert(List, { Center = Pivot.Position, Radius = Radius })
                end
            end
        end
        return List
    end
    Escape.Hazards = SkillHazards
    Escape.Profile = SkillProfile
    Escape.FinalPhase = FinalPhase

    -- บอสเพิ่งเริ่มท่าเงื้อที่เรียนไว้ (ยืนยันแล้ว >= 2 ครั้ง และตามด้วยท่าจริงมากกว่าพลาด 2 เท่า) -> ชื่อท่า, คีย์
    local function LearnedWindup(Model)
        for _, Windup in ipairs(WindupTracks(Model)) do
            local Key = "@" .. BaseName(Model) .. ":" .. Windup.Id
            local Entry = Learned[Key]
            if type(Entry) == "table" and (Entry.Y or 0) >= 2 and (Entry.Y or 0) > (Entry.N or 0) * 2
                and Windup.Track.TimePosition < 0.5 then
                return Entry.S, Key
            end
        end
        return nil
    end

    -- โซน Telegraph ที่เกมวาดอยู่ตอนนี้ (แผ่นใหญ่สุดของแต่ละโฟลเดอร์ "<Id>-Telegraph" ที่ยังไม่ถูกยกเลิก)
    local function TelegraphZones()
        local Zones = { }
        local Debree = workspace:FindFirstChild("Debree")
        for _, Folder in ipairs(Debree and Debree:GetChildren() or { }) do
            if Folder.Name:sub(-10) == "-Telegraph" and not Folder:GetAttribute("Cancelled") then
                local Plate, Area = nil, 0
                for _, Part in ipairs(Folder:GetChildren()) do
                    if Part:IsA("BasePart") then
                        local Size = Part.Size
                        local Flat = Part.Shape == Enum.PartType.Cylinder and Size.Y * Size.Z or Size.X * Size.Z
                        if Flat > Area then Plate, Area = Part, Flat end
                    end
                end
                if Plate then table.insert(Zones, Plate) end
            end
        end
        return Zones
    end
    Escape.Zones = TelegraphZones
    Fighter.Escape = Escape     -- ดูสถานะหลบสดผ่าน dex

    -- จุด P (แนวราบ) อยู่ในโซนไหม + ต้องขยับออกไปทางไหนเท่าไหร่ถึงพ้นขอบ + Margin
    local function PushOut(Plate, P)
        local Margin = Escape.Margin
        if Plate.Shape == Enum.PartType.Cylinder then
            local Center = Plate.Position
            local Radius = math.max(Plate.Size.Y, Plate.Size.Z) / 2 + Margin
            local Flat = (P - Center) * Vector3.new(1, 0, 1)
            if Flat.Magnitude >= Radius then return P end
            local Dir = Flat.Magnitude > 0.1 and Flat.Unit or Vector3.new(1, 0, 0)
            return Center + Dir * Radius + Vector3.new(0, P.Y - Center.Y, 0)
        end
        local Local = Plate.CFrame:PointToObjectSpace(P)
        local HalfX, HalfZ = Plate.Size.X / 2 + Margin, Plate.Size.Z / 2 + Margin
        if math.abs(Local.X) >= HalfX or math.abs(Local.Z) >= HalfZ then return P end
        -- ออกทางขอบที่ใกล้สุด (มักเป็นด้านข้างของแนวยาว)
        local OutX, OutZ = HalfX - math.abs(Local.X), HalfZ - math.abs(Local.Z)
        if OutX <= OutZ then
            Local = Vector3.new((Local.X >= 0 and 1 or -1) * HalfX, Local.Y, Local.Z)
        else
            Local = Vector3.new(Local.X, Local.Y, (Local.Z >= 0 and 1 or -1) * HalfZ)
        end
        return Plate.CFrame:PointToWorldSpace(Local)
    end

    local GroundParams = RaycastParams.new()
    GroundParams.FilterType = Enum.RaycastFilterType.Exclude

    -- ความสูงพื้นใต้จุด (ไม่นับตัวละคร/NPC/โซน Telegraph) - ไม่มีพื้นในช่วง = nil
    local function GroundAt(Point, NearY)
        local Ignore = { }
        for _, Name in ipairs({ "Humanoids", "Debree" }) do
            local Folder = workspace:FindFirstChild(Name)
            if Folder then table.insert(Ignore, Folder) end
        end
        local Character = Movement.GetCharacter()
        if Character then table.insert(Ignore, Character) end
        GroundParams.FilterDescendantsInstances = Ignore
        local Hit = workspace:Raycast(Vector3.new(Point.X, NearY + 40, Point.Z), Vector3.new(0, -90, 0), GroundParams)
        return Hit and Hit.Position.Y or nil
    end

    --// ศัตรูที่กำลังใช้ท่าอยู่ทุกตัว { [โมเดล] = { At = FX ล่าสุด, Key } } (วัดสด 2026-10-01 หอ Ouwigahara: บอส/เทรนนี่
    -- หลายตัวพร้อมกัน หลบตัวหนึ่งแล้ววิ่งเข้า Water Wheel อีกตัว) = จุดหลบต้องห่างทุกตัว ไม่ใช่แค่ตัวที่หลบอยู่
    Escape.Casters = setmetatable({ }, { __mode = "k" })
    -- มอนธรรมดาที่ใช้ท่าชุดบอส (ดูตัวดัก EffectsEvent) = หลบแบบบอสตลอดไป
    Escape.KitUsers = setmetatable({ }, { __mode = "k" })

    function Escape.CasterHazards(Except)
        local List = { }
        for Model, Info in pairs(Escape.Casters) do
            local MobRoot = Model ~= Except and Model.Parent and Model:FindFirstChild("HumanoidRootPart")
            if MobRoot and (os.clock() - Info.At < 1.5 or ModelCasting(Model)) then
                local Radius = math.clamp(math.max(Escape.Radius, tonumber(Learned[Info.Key]) or 0), 10, Escape.MaxRadius)
                table.insert(List, { Center = MobRoot.Position, Radius = Radius })
            elseif Model ~= Except and (not MobRoot or os.clock() - Info.At > 10) then
                Escape.Casters[Model] = nil
            end
        end
        return List
    end

    -- สถิติต่อท่า Learned["#บอส|ท่า"] = { D = ครั้งที่หลบ, H = รอบหลบที่ยังโดน, P = รอบที่โดนทั้งที่กันค้างอยู่ }
    -- (B เดิมนับดาเมจ Bleeding Floor ปนมา - เลิกใช้)
    function Escape.Note(Key, Field)
        local Entry = type(Learned["#" .. Key]) == "table" and Learned["#" .. Key] or { D = 0, H = 0, P = 0 }
        Entry[Field] = (Entry[Field] or 0) + 1
        Learned["#" .. Key] = Entry
        LearnDirty = true
    end

    local function TriggerEscape(Source, IsBoss, Skill)
        local MobRoot = Source and Source:FindFirstChild("HumanoidRootPart")
        local Root = Movement.GetRoot()
        if not (Root and MobRoot) then return end

        local Key = LearnKey(Source, Skill)
        local Base = IsBoss and Escape.Radius or Escape.MobRadius
        local Radius = math.clamp(math.max(Base, tonumber(Learned[Key]) or 0), 10, Escape.MaxRadius)

        -- ทิศหลบ: ตั้งฉากกับแนวบอส->เรา (ข้าง ๆ) ฝั่งที่มีพื้น / ไม่มีทั้งสองฝั่ง = ถอยตรงออกมา / ไม่มีพื้นเลย = ฝั่งแรก
        local Away = (Root.Position - MobRoot.Position) * Vector3.new(1, 0, 1)
        Away = Away.Magnitude > 0.5 and Away.Unit or Vector3.new(1, 0, 0)
        local Side = Vector3.new(-Away.Z, 0, Away.X)
        local Options = { (Side + Away * 0.35).Unit, (-Side + Away * 0.35).Unit, Away, Side, -Side,
            (Side - Away * 0.5).Unit, (-Side - Away * 0.5).Unit }
        -- ฝั่งที่: มีพื้น + จุดยืนไม่อยู่ในกำแพง/Part + เส้นจากตัวเราไปถึงไม่ทะลุกำแพง (ผู้ใช้ 2026-09-30: หลบเข้า
        -- ไปใน Part = นับเป็น noclip โดน kick) / ไม่ผ่านสักฝั่ง = ฝั่งที่มีพื้น (Movement.Free กันเข้าไปในกำแพงอีกชั้น)
        local Dir, Fallback = nil, nil
        for _, Option in ipairs(Options) do
            local Spot = MobRoot.Position + Option * Radius
            local Ground = GroundAt(Spot, MobRoot.Position.Y)
            if Ground then
                local Stand = Vector3.new(Spot.X, Ground + 3, Spot.Z)
                Fallback = Fallback or Option
                if not Movement.Blocked(Stand) and Movement.PathClear(Root.Position, Stand) then Dir = Option break end
            end
        end
        Dir = Dir or Fallback or Options[1]

        local Last = MobRoot.Position
        local LastY = nil

        Escape.Source = Source
        Escape.WindupKey = nil
        Escape.LastFxAt = os.clock()
        Escape.Skill = Skill
        Escape.Phase = nil
        Escape.Key = Key
        Escape.HitKey = nil
        Escape.Note(Key, "D")
        Escape.Radius_ = Radius
        Escape.StartedAt = os.clock()
        Escape.IsBoss = IsBoss
        Escape.Followed = IsBoss and IsFollowingMe(Source)
        Escape.SawSkillFx = false
        Escape.Returning = true
        Escape.CFrame = function()
            if MobRoot.Parent then Last = MobRoot.Position end
            local R = math.clamp(math.max(Escape.Radius_, tonumber(Learned[Key]) or 0), 10, Escape.MaxRadius)
            local P = Last + Dir * R

            -- ยืนนอกโซน Telegraph + ของที่บอสวางบนพื้นทุกอัน (ดันออก 2 รอบ กันโซนซ้อน)
            local Hazards = SkillHazards(Source)
            for _, Other in ipairs(Escape.CasterHazards(Source)) do table.insert(Hazards, Other) end
            for _ = 1, 2 do
                for _, Plate in ipairs(TelegraphZones()) do
                    if Plate.Parent then P = PushOut(Plate, P) end
                end
                for _, Hazard in ipairs(Hazards) do
                    local Flat = (P - Hazard.Center) * Vector3.new(1, 0, 1)
                    local Need = Hazard.Radius + Escape.Margin
                    if Flat.Magnitude < Need then
                        local Out = Flat.Magnitude > 0.1 and Flat.Unit or Dir
                        P = Vector3.new(Hazard.Center.X, P.Y, Hazard.Center.Z) + Out * Need
                    end
                end
            end

            -- ห้ามหลบออกนอกโซนที่ตั้งไว้ (Rescue and Hold the Zone)
            P = Farm.ClampToZone(P)

            -- ยืนบนพื้น (สูงกว่าพื้น 3 studs) - หาพื้นไม่เจอใช้ความสูงบอส
            local Ground = GroundAt(P, Last.Y)
            LastY = Ground and (Ground + 3) or LastY or Last.Y
            local Stand = Vector3.new(P.X, LastY, P.Z)
            return CFrame.lookAt(Stand, Vector3.new(Last.X, LastY, Last.Z))
        end
        Escape.Until = os.clock() + (IsBoss and Escape.MaxTime or Escape.MobMaxTime)
        Movement.Lock(Escape.CFrame)
    end

    --// เรียนรู้: หลบอยู่ (ถึงจุดหลบแล้ว) แต่ยังโดนดาเมจ = รัศมีไม่พอ -> ขยายเป็นระยะที่โดน + LearnStep
    -- ไม่นับดาเมจตอนกำลังวาร์ปไปจุดหลบ (ยังอยู่ใกล้บอส) - นับเฉพาะตอนอยู่ห่าง >= รัศมีที่ตั้งไว้ - 4
    local function WatchLearning(Character)
        local Humanoid = Character and Character:WaitForChild("Humanoid", 10)
        if not Humanoid then return end
        local Last = Humanoid.Health
        local TickDrop, TickAt = 0, 0
        TrackConnection(Humanoid.HealthChanged:Connect(function(Health)
            local Drop = Last - Health
            Last = Health
            if Drop <= 0.5 then return end
            -- ดาเมจเป็นจังหวะคงที่ไม่ใช่ท่าบอส (วัดสด 2026-10-01: Bleeding Floor -1% เลือดทุก 1 วิ / Snow Frost Tick)
            -- = ไม่นับ ไม่งั้นนับเป็น "โดนทะลุกัน" แล้วเลิกกันท่านั้นผิด ๆ
            local Now = os.clock()
            local Periodic = math.abs(Drop - TickDrop) < 0.6 and math.abs(Now - TickAt - 1) < 0.2
            TickDrop, TickAt = Drop, Now
            if Periodic then return end
            local Pick = tostring(LocalPlayer:GetAttribute("OuwigaharaLastPick") or "")
            if Pick:find("Bleeding") and math.abs(Drop - Humanoid.MaxHealth * 0.01) < 1 then return end
            if not Escape.CFrame or os.clock() >= Escape.Until then return end
            local MobRoot = Escape.Source and Escape.Source:FindFirstChild("HumanoidRootPart")
            local Root = Movement.GetRoot()
            if not (MobRoot and Root and Escape.Key) then return end
            local Distance = ((Root.Position - MobRoot.Position) * Vector3.new(1, 0, 1)).Magnitude
            -- โดนระหว่างหลบ (นับครั้งเดียวต่อรอบ) / โดนทั้งที่กันค้างอยู่ = ท่านี้ทะลุกัน (PierceBlock)
            if Escape.HitKey ~= Escape.Key then
                Escape.HitKey = Escape.Key
                Escape.Note(Escape.Key, "H")
                if Escape.Guarded and Escape.Guarded() then Escape.Note(Escape.Key, "P") end
            end
            if Distance < (Escape.Radius_ or 0) - 4 then return end
            -- ดาเมจของท่ามาเฟรมเดียวกับ FX ของบอส (วัดสด Kaiden: HIT กับ Slice2/Slice3/Slash4 ห่างกัน < 0.01 วิ)
            -- = โดนท่านี้แน่ ไม่งั้น (ไม่มี FX ใกล้ ๆ) มีมอนอื่นยืนติดเรา = อาจเป็นหมัดมอนตัวนั้น ไม่นับ
            if os.clock() - (Escape.LastFxAt or 0) > 0.25 then
                local Npcs = workspace:FindFirstChild("Humanoids")
                for _, Model in ipairs(Npcs and Npcs:GetDescendants() or { }) do
                    if Model:IsA("Model") and Model ~= Escape.Source then
                        local Other = Model:FindFirstChild("HumanoidRootPart")
                        local Hum = Model:FindFirstChildOfClass("Humanoid")
                        if Other and Hum and Hum.Health > 0 and (Other.Position - Root.Position).Magnitude < 12 then return end
                    end
                end
            end
            local New = math.min(Escape.MaxRadius, Distance + Escape.LearnStep)
            if New > (tonumber(Learned[Escape.Key]) or 0) then
                Learned[Escape.Key] = math.floor(New)
                LearnDirty = true
            end
        end))
    end
    if LocalPlayer.Character then task.spawn(WatchLearning, LocalPlayer.Character) end
    TrackConnection(LocalPlayer.CharacterAdded:Connect(WatchLearning))

    task.spawn(function()
        while getgenv().ValkyrieSession == SessionToken do
            CloseStaleSequences()
            if LearnDirty then
                LearnDirty = false
                pcall(function()
                    if writefile then writefile(LearnFile, HttpService:JSONEncode(Learned)) end
                end)
            end
            task.wait(2)    -- เขียนไฟล์ ไม่ต้องทุกเฟรม
        end
    end)

    -- NPC ศัตรู = โมเดลที่มี Humanoid ใต้ workspace.Humanoids (ไม่ใช่ตัวผู้เล่น) - คืน nil ถ้าไม่ใช่
    -- คืน true ถ้าเป็นบอส (โฟลเดอร์ ActiveNpcs.<ชื่อ> มี Configuration "BossInfo" - ดู IterMobs) / false = มอนธรรมดา
    local NpcRoot = workspace:FindFirstChild("Humanoids")

    local function NpcKind(Model)
        if typeof(Model) ~= "Instance" or not Model:IsA("Model") or not Model.Parent then return nil end
        if Players:GetPlayerFromCharacter(Model) or not Model:FindFirstChildOfClass("Humanoid") then return nil end
        if Model.Parent:FindFirstChild("BossInfo") then return true end

        NpcRoot = NpcRoot or workspace:FindFirstChild("Humanoids")
        if NpcRoot and Model:IsDescendantOf(NpcRoot) then return false end
        return nil
    end

    local StartPhases = { Start = true, Windup = true, Startup = true }

    --// FX ที่ไม่ใช่ท่าโจมตี = ไม่หลบ (ผู้ใช้ 2026-10-01: ไม่ต้องหลบ animation วิ่ง/dash/กระโดด)
    -- วัดสด: บอสเดินยิง EffectsEvent("NpcMovementEffects", บอส, "Walk") ทุกก้าว - บอสรับทุก phase ที่เป็นตัวหนังสือ
    -- = หลบทุกครั้งที่บอสเดิน (เรียนผิดเป็นท่าเงื้อด้วย "@Hand Demon:...=NpcMovementEffects")
    -- ข้าม: ทุกอย่างใน Effects.Misc (dash_effect / Double_Jump_Effect / NpcMovementEffects / Stunned ...) + Core
    -- (ยกเว้น Telegraph) + NpcsRelated / Emotes / TickEffects / Progression / Server_Sided_Adjustements + FlashStepVFX
    -- ท่าเคลื่อนที่ของศัตรู (ผู้ใช้ 2026-10-01: พวกเดิน/dash ไม่ต้องรอ ตีไปเลย - วัดสด Reaper Phantom Step "ZigZag"
    -- ทำให้ยืนหลบเฉย ๆ 3 วิ) = Phantom Step / Sonido / Godspeed / Flash Step เป็นแค่การพุ่งไปมา ไม่หลบ
    local NonAttackFx = { FlashStepVFX = true, ["Phantom StepVFX"] = true, SonidoVFX = true, Godspeed_VFX = true }
    pcall(function()
        for _, Folder in ipairs({ "Misc", "Core", "NpcsRelated", "Emotes", "TickEffects", "Progression", "Server_Sided_Adjustements" }) do
            local Holder = ReplicatedStorage.Effects:FindFirstChild(Folder)
            for _, Child in ipairs(Holder and Holder:GetChildren() or { }) do
                if Child.Name ~= "Telegraph" then NonAttackFx[Child.Name] = true end
            end
        end
    end)
    -- phase ที่เป็นการเคลื่อนที่ ไม่ว่ามาจาก FX ตัวไหน
    local MovePhases = { Walk = true, Run = true, Sprint = true, Dash = true, Jump = true, DoubleJump = true, Land = true,
        Landed = true, Idle = true }

    -- เรียนท่าเงื้อ/รัศมี/โปรไฟล์ผิดจาก FX พวกนี้ไปแล้ว (เซฟเก่า) = ลบทิ้ง
    for Key, Value in pairs(Learned) do
        local Skill = Key:match("|(.+)$")
        if (Key:sub(1, 1) == "@" and type(Value) == "table" and NonAttackFx[Value.S]) or (Skill and NonAttackFx[Skill]) then
            Learned[Key] = nil
            LearnDirty = true
        end
    end

    -- phase ลงดาบของท่ามอนธรรมดา (Effects.DemonPhysicalAttacks) = ท่าจบแล้ว กลับได้
    local MobStrikePhases = { Slam = true, Crash = true, Strike = true }
    -- ท่าของมอนธรรมดาจริง ๆ (Effects.DemonPhysicalAttacks: Ground Slam / Asteroid / Quick Attack) - นอกนั้นเป็นท่าชุดบอส
    local MobSkillFx = { }
    pcall(function()
        for _, Child in ipairs(ReplicatedStorage.Effects.DemonPhysicalAttacks:GetChildren()) do MobSkillFx[Child.Name] = true end
    end)

    local function IsSkillEnd(Phase, IsBoss)
        if not IsBoss and MobStrikePhases[Phase] then return true end
        return Phase == "End" or Phase:find("Cancel") ~= nil or Phase:find("Miss") ~= nil
    end

    pcall(function()
        local EffectsEvent = ReplicatedStorage.Communication.ServerAndClient.Effects.EffectsEvent.Event

        TrackConnection(EffectsEvent.OnClientEvent:Connect(function(SkillName, Source, Phase)
            if type(Phase) ~= "string" then return end
            if NonAttackFx[SkillName] or MovePhases[Phase] then return end
            if not Engaged() or not AutoDodge() then return end

            local IsBoss = NpcKind(Source)
            if IsBoss == nil then return end

            -- มอนที่ใช้ท่าชุดเดียวกับบอส (หอ Ouwigahara: Thunder Trainee / Zentaro / Water Trainee ... IsMob=true -
            -- วัดสด 2026-10-01 phase แรก Init / Initiate / CreateSlash ไม่ใช่ Start = ไม่หลบเลย โดน Rice Spirit -28)
            -- = หลบแบบบอส เฉพาะตัวที่ตามเรา/ที่เราตี/อยู่ใกล้ (มอนฝูงใช้ท่าใส่คนอื่นไม่ต้องหนี)
            if IsBoss == false and Escape.KitUsers[Source] then
                IsBoss = true
            elseif IsBoss == false and type(SkillName) == "string" and not SkillName:find("Swings") and not MobSkillFx[SkillName] then
                local MobRoot, Root = Source:FindFirstChild("HumanoidRootPart"), Movement.GetRoot()
                local Target = Fighter.AttackTarget
                if MobRoot and Root and (IsFollowingMe(Source) or (Target and Target.Model == Source)
                    or (MobRoot.Position - Root.Position).Magnitude <= Escape.MobReact * 1.5) then
                    IsBoss = true
                    Escape.KitUsers[Source] = true
                end
            end

            local IsTelegraph = SkillName == "Telegraph"
            -- ตัวที่กำลังใช้ท่า (จุดหลบต้องห่างทุกตัว) - จบท่าแล้วเอาออก
            if IsBoss and type(SkillName) == "string" and not SkillName:find("Swings") then
                if IsSkillEnd(Phase, true) then
                    Escape.Casters[Source] = nil
                else
                    Escape.Casters[Source] = { At = os.clock(), Key = LearnKey(Source, SkillName) }
                end
            end

            -- เรียนลำดับ phase ของท่าบอส (ช่วงเงียบกลางท่า + phase สุดท้าย) - ไม่นับหมัด M1 / Telegraph
            local IsSkill = IsBoss and not IsTelegraph and type(SkillName) == "string" and not SkillName:find("Swings")
            if IsSkill then NoteSkillPhase(Source, SkillName, Phase) end
            if IsSkill and Source == Escape.Source and SkillName == Escape.Skill then Escape.Phase = Phase end

            -- บอสตัวที่หลบอยู่: จบ/ยกเลิกท่า = เลิกหลบ รอบถัดไป FightMob พากลับเข้าไปตีทันที
            -- เริ่มท่าใหม่ต่อกัน (SkillChainChance) = หลบต่อรอท่าใหม่จบ
            if Source == Escape.Source then
                Escape.LastFxAt = os.clock()
                -- หลบเพราะท่าเงื้อแล้ว FX ตามมาจริง = ยืนยัน animation นั้นอีกครั้ง
                local Entry = Escape.WindupKey and Learned[Escape.WindupKey]
                if type(Entry) == "table" and Escaping() then
                    Entry.Y = (Entry.Y or 0) + 1
                    LearnDirty = true
                end
                Escape.WindupKey = nil
            end
            if Escaping() and Source == Escape.Source then
                if IsSkillEnd(Phase, IsBoss) then
                    if not (IsTelegraph and Escape.SawSkillFx) then Escape.Until = 0 end
                elseif StartPhases[Phase] or IsBoss then
                    -- บอส: phase ระหว่างท่า (Tornado / JumpBack / Hit ...) = ท่ายังไม่จบ ต่อเวลาหลบ
                    Escape.Until = os.clock() + (IsBoss and Escape.MaxTime or Escape.MobMaxTime)
                end
                -- ท่าจริงโผล่ตามหลัง Telegraph / ต่อท่าใหม่ = เรียนรู้/ใช้รัศมีของท่านี้แทน
                if not IsTelegraph and (StartPhases[Phase] or IsBoss) and Escape.Skill ~= SkillName then
                    Escape.Skill, Escape.Key, Escape.Phase = SkillName, LearnKey(Source, SkillName), Phase
                    Escape.Radius_ = math.max(Escape.Radius_ or 0, tonumber(Learned[Escape.Key]) or 0)
                end
                -- นับเฉพาะ FX ที่ส่ง phase เริ่ม (Windup/Start) - ท่าพวกนี้ส่ง End ตามมา / FX ระหว่างท่า
                -- อย่าง "SpeedReflexVFX Clone" (Domae) ไม่มี End ต้องพึ่ง Telegraph Cancel
                if not IsTelegraph and StartPhases[Phase] then Escape.SawSkillFx = true end
                return
            end

            -- บอส: phase แรกของท่าชื่อไม่ตายตัว (Hoyuzo Scyther Vortex เริ่มที่ "Tornado" - วัดสด 2026-09-30)
            -- = phase ตัวหนังสืออะไรก็ได้ที่ไม่ใช่จบท่า (หมัด M1 "_Swings" phase เป็นเลข ไม่เข้า) / มอน = StartPhases เท่านั้น
            if IsBoss then
                if IsSkillEnd(Phase, true) or type(SkillName) ~= "string" or SkillName:find("Swings") then return end
            elseif not StartPhases[Phase] then
                return
            end

            local MobRoot = Source:FindFirstChild("HumanoidRootPart")
            local Root = Movement.GetRoot()
            if not (MobRoot and Root) then return end
            if IsBoss then
                if (MobRoot.Position - Root.Position).Magnitude > Escape.React then return end
            else
                local Target = Fighter.AttackTarget
                if (MobRoot.Position - Root.Position).Magnitude > Escape.MobReact then return end
                if not (IsFollowingMe(Source) or (Target and Target.Model == Source)) then return end
            end

            if IsBoss then NoteWindup(Source, SkillName) end
            TriggerEscape(Source, IsBoss, SkillName)
            Escape.SawSkillFx = not IsTelegraph
            Escape.Phase = Phase
        end))
    end)

    local function StandAt(Mob)
        return function()
            if not Farm.IsMobAlive(Mob) then return nil end
            return Farm.BuildStandCFrame(Mob.Root.CFrame)
        end
    end

    -- ยืนเกาะจุดตีมอนตัวนี้ (จับเวลาถึงจุดไว้ให้ settle นับต่อ - ยืนรอนานพอแล้วตีได้ทันที)
    local function HoldAt(Mob)
        local Farmer = Farm.ConfigFarm
        Fighter.AttackTarget = Mob
        -- เทียบที่ตัวโมเดล ไม่ใช่ entry: GetNearestMobByName สร้าง entry ใหม่ทุกครั้ง (DoFiller / สปาย
        -- เรียกทุกเฟรม) - เทียบ entry = นับเวลาถึงจุดใหม่ทุกเฟรม settle ไม่เคยครบ ไม่ตีเลย
        if not Farmer.ArrivedAt or Farmer.SettledOn ~= Mob.Model then
            Farmer.ArrivedAt, Farmer.SettledOn = os.clock(), Mob.Model
        end
        Movement.Lock(StandAt(Mob))
    end

    --// กันระหว่างรอคูลดาวน์ M1 (ผู้ใช้สั่ง 2026-09-30): ไม่ได้หลบ + รอคูลดาวน์ชุดคอมโบ = กดกัน (Blocking)
    -- คูลดาวน์ใกล้หมด = ปล่อยแล้วตี M1 ต่อทันที
    -- กัน = action "Skills_1st" ผ่าน InputHandler.VirtualPress/VirtualRelease (แบบเดียวกับแท็บ Combat - ดูโน้ตที่นั่น)
    --   คูลดาวน์ท่ากัน ~2 วิ นับจากตอนปล่อย / กดแล้ว ~0.27 วิแรก = PerfectNpc (หมัดมอนโดนสตัน)
    --   ปล่อยตอน SHC ยังรอเซิร์ฟ = คำสั่งปล่อยหาย ท่ากันค้าง -> ย้ำ UnHoldBoolean / StopHold จนหลุด
    -- รอสั้น (ระหว่างหมัด 1-4 ห่างกัน ~0.1-0.25 วิ) ไม่กด - กดแล้วเสียจังหวะคอมโบ + เผาคูลดาวน์ท่ากัน 2 วิ
    -- มอนล้มอยู่ (ตีเราไม่ได้ / ช่องยิงสกิล) ไม่กด / SHC ไม่ว่าง (สกิลของเรา) ไม่กด
    local BlockInput, BlockSkills = nil, nil
    pcall(function() BlockInput = require(ReplicatedStorage.CAM.Client.Components.Client.InputHandler) end)
    pcall(function() BlockSkills = require(ReplicatedStorage.CAM.Client.Controllers.Skill_Controller) end)
    local WaitBlock = { Holding = false, ReadyAt = 0, Since = 0, ReleasedAt = nil }
    local WaitBlockMin = 0.35       -- รอคูลดาวน์นานกว่านี้ถึงจะกด
    local WaitBlockLead = 0.12      -- ปล่อยก่อนถึงเวลายิงหมัดเท่านี้ (ให้ SHC ว่างทันหมัดแรก)
    local WaitBlockCooldown = 2.05
    local WaitBlockMax = 3          -- กันค้างนานสุด (กันลืมปล่อย)
    local WaitBlockAfterSwing = 0.45 -- หมัดล่าสุดต้องเก่ากว่านี้ (รอดูหมัด 5 ทำมอนล้มไหม - วัดสด: กดแล้วมอนล้มตาม 0.05 วิ
                                     -- ต้องปล่อยให้สกิล = เผาคูลดาวน์ท่ากันฟรี)
    Fighter.WaitBlock = WaitBlock   -- ดูสดผ่าน dex

    local function OwnSHC()
        local Character = Movement.GetCharacter()
        return Character and Character:FindFirstChild("SHC")
    end

    local function BlockUp()
        local SHC = OwnSHC()
        return SHC ~= nil and SHC.Value == "Blocking"
    end

    local function StartWaitBlock()
        if WaitBlock.Holding or not BlockInput or os.clock() < WaitBlock.ReadyAt then return end
        -- ผู้เล่น/Auto Parry กดกันอยู่เอง = ไม่แย่ง / สกิลของเราค้าง SHC อยู่ = ไม่กด
        local Down, Value = pcall(BlockInput.IsDown, "Skills_1st")
        if Down and Value then return end
        local SHC = OwnSHC()
        if SHC and (SHC.Value ~= "" or SHC:GetAttribute("en") == true) then return end
        -- ท่ากันรอคูลดาวน์สำคัญน้อยสุด (HubAction Block 7) - มีอะไรค้างอยู่ = ไม่กด
        if not HubAction.Claim("Block", WaitBlockMax + 1) then return end
        WaitBlock.Holding, WaitBlock.Since, WaitBlock.ReleasedAt = true, os.clock(), nil
        pcall(BlockInput.VirtualPress, "Skills_1st")
    end

    local function StopWaitBlock()
        if not WaitBlock.Holding then return end
        WaitBlock.Holding = false
        WaitBlock.ReadyAt = os.clock() + WaitBlockCooldown
        WaitBlock.ReleasedAt = os.clock()
        HubAction.Release("Block")
        pcall(BlockInput.VirtualRelease, "Skills_1st")
    end

    -- ปล่อยให้หลุดจริง + ปล่อยเองเมื่อเลิกสถานการณ์รอคูลดาวน์ (เริ่มหลบ / ช่องยิงสกิล / เลิกฟาร์ม / เปลี่ยนเป้า)
    TrackConnection(RunService.Heartbeat:Connect(function()
        if WaitBlock.Holding then
            local Mob = Fighter.AttackTarget
            if not Engaged() or (Escaping() and not Escape.TakeBlock()) or Fighter.SkillBusy or not Mob or Mob.Model ~= WaitBlock.Model
                or Farm.SkillWindow(Mob) or os.clock() - WaitBlock.Since > WaitBlockMax or not HubAction.Allowed("Block") then
                StopWaitBlock()
            end
            return
        end
        local Since = WaitBlock.ReleasedAt
        if not Since then return end
        if os.clock() - Since > 2 or not BlockUp() then
            if not BlockUp() then WaitBlock.ReleasedAt = nil end
            return
        end
        if BlockSkills then
            BlockSkills.UnHoldBoolean = true
            local SHC = OwnSHC()
            if os.clock() - Since > 0.3 and SHC and SHC:GetAttribute("en") ~= true then
                pcall(BlockSkills.StopHold, "Blocking")
            end
        end
    end))

    --// กันค้างระหว่างหลบท่า (วัดสด 2026-10-01 หอ Ouwigahara): ท่าพุ่ง/วาร์ปหาเป้า (Thunder Clap DashOrCancel,
    -- Rice Spirit TP, Execution Scyther จับ) ตามมาโดนถึง 24+ studs - หนีอย่างเดียวไม่พอ
    -- Checker.check_victim: เรามี Blocking + ท่าไม่มี PierceBlock = ไม่โดนดาเมจ -> หลบ + กดกันค้างจนท่าจบ
    -- ท่าที่โดนทะลุกันบ่อย (สถิติ "#บอส|ท่า" P >= 3 และ >= ครึ่งของครั้งที่หลบ) = ไม่กด ใช้ระยะอย่างเดียว
    -- ท่าต่อกัน (บอสใช้ท่าใหม่ทันทีหลังท่าเก่าจบ / ช่วงเงียบระหว่าง phase) = ปล่อยกันแล้วติดคูลดาวน์ 2 วิ
    -- โดนท่าถัดไปเต็ม ๆ (วัดสด 2026-10-01: ปล่อยตอน 14.5 กดใหม่ได้ 16.5) = ถือต่ออีก Tail วิหลังเลิกหลบ
    local DodgeGuard = { Holding = false, Since = 0, Max = 8, Tail = 0.8, WantAt = 0 }
    Fighter.DodgeGuard = DodgeGuard

    function Escape.Pierces(Key)
        local Stats = Key and Learned["#" .. Key]
        return type(Stats) == "table" and (Stats.P or 0) >= 3 and (Stats.P or 0) * 2 >= (Stats.D or 0)
    end

    function Escape.GuardWanted()
        return BlockInput ~= nil and Escape.CFrame ~= nil and Escaping() and not Escape.Pierces(Escape.Key)
            and os.clock() - (Escape.StartedAt or 0) < DodgeGuard.Max
    end

    -- กันค้างมาแล้ว (กันรอคูลดาวน์) ตอนเริ่มหลบ = รับช่วงต่อเลย ไม่ปล่อยแล้วติดคูลดาวน์ 2 วิ
    function Escape.TakeBlock()
        if not (WaitBlock.Holding and Escape.GuardWanted()) then return false end
        WaitBlock.Holding = false
        HubAction.Release("Block")
        DodgeGuard.Holding, DodgeGuard.Since = true, WaitBlock.Since
        return true
    end

    function Escape.Guarded()
        return DodgeGuard.Holding and os.clock() - DodgeGuard.Since >= 0.2 and BlockUp()
    end

    -- กดค้างจาก session ก่อน (inject ใหม่ตอนกันอยู่ - วัดสด 2026-10-01: IsDown ค้าง true ทั้งที่ไม่มีใครกด F
    -- = นึกว่าผู้เล่นกดเอง ไม่กดกันเลยครึ่งหนึ่งของเวลาหลบ) = ปล่อยทิ้งตอนโหลด
    if BlockInput then pcall(BlockInput.VirtualRelease, "Skills_1st") end

    -- ผู้เล่นกดปุ่มกันจริง ๆ (คีย์บอร์ด) - IsDown ของ InputHandler นับ VirtualPress ด้วย แยกไม่ออก
    local function PlayerHoldsBlock()
        local Ok, Held = pcall(function()
            return game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode[BlockInput.KeyLabel("Skills_1st")])
        end)
        return Ok and Held == true
    end

    TrackConnection(RunService.Heartbeat:Connect(function()
        local Want = Escape.GuardWanted()
        if Want then
            DodgeGuard.WantAt = os.clock()
        elseif DodgeGuard.Holding and os.clock() - DodgeGuard.WantAt < DodgeGuard.Tail
            and os.clock() - DodgeGuard.Since < DodgeGuard.Max then
            Want = true
        end
        if Want and not DodgeGuard.Holding then
            if WaitBlock.Holding or os.clock() < WaitBlock.ReadyAt then return end
            -- ผู้เล่นกดกันเอง / สกิลของเราค้าง SHC อยู่ = ไม่แย่ง / ค้างแค่ VirtualPress (ไม่มีคนกด) = ปล่อยก่อนกดใหม่
            local SHC = OwnSHC()
            if SHC and SHC.Value ~= "" and SHC.Value ~= "Blocking" then return end
            local Down, Value = pcall(BlockInput.IsDown, "Skills_1st")
            if Down and Value then
                if PlayerHoldsBlock() then return end
                pcall(BlockInput.VirtualRelease, "Skills_1st")
            end
            DodgeGuard.Holding, DodgeGuard.Since = true, os.clock()
            pcall(BlockInput.VirtualPress, "Skills_1st")
        elseif not Want and DodgeGuard.Holding then
            -- ปล่อย = ใช้ตัวย้ำปล่อยของกันรอคูลดาวน์ (ReleasedAt) + คูลดาวน์ร่วมกัน
            DodgeGuard.Holding = false
            WaitBlock.ReadyAt = os.clock() + WaitBlockCooldown
            WaitBlock.ReleasedAt = os.clock()
            pcall(BlockInput.VirtualRelease, "Skills_1st")
        end
    end))

    -- ยืนเกาะมอนตีตลอด ไม่ลอยหลบระหว่างคอมโบ/คูลดาวน์ - หลบอย่างเดียวคือหลบสกิลบอส (Escape)
    local function Attack(Mob)
        local Farmer = Farm.ConfigFarm

        if Escaping() then
            Fighter.AttackTarget = nil
            Farmer.ArrivedAt = nil
            Movement.Lock(Escape.CFrame)
            return
        end

        HoldAt(Mob)

        -- ยังตีไม่ได้ (Auto Use Skill กำลังเงื้อ / เราโดนสตัน / เป้าอมตะ / กันหรือตั้งท่าสวน / ติดคูลดาวน์)
        -- = ยืนรอที่จุดตี
        local Busy = Fighter.Casting() or Fighter.OffWeaponHold() or Farm.SelfStunned() or Farm.IsMobInvulnerable(Mob)
            or Farm.IsMobGuarded(Mob) or not HubAction.Allowed("M1")
        local Wait = (Farm.ComboCooldown(Farm.NextCombo()) or 0) - Farm.EngageLead(Mob)

        -- รอคูลดาวน์ M1 นานพอ = กดกันรอ / ใกล้หมด (หรือติดอย่างอื่น) = ปล่อย
        -- ในโซน Rescue: กันอยู่ = หลอดยึดโซนหยุด (ZoneRescue.holdBroken นับ Blocking) - ไม่กด
        -- บอส/มอนที่ใช้ท่าชุดบอส: ไม่กันรอคูลดาวน์ เก็บคูลดาวน์กัน (2 วิ) ไว้กันท่าของมัน (DodgeGuard)
        local SkillUser = AutoDodge() and (NpcKind(Mob.Model) == true or Escape.KitUsers[Mob.Model] ~= nil)
        if not Busy and not SkillUser and Wait > WaitBlockMin and not Farm.StandZone and not Mob.Model:FindFirstChild("RagDoll") and not Farm.SkillWindow(Mob)
            and os.clock() - (Farm.LastSwingAt or 0) >= WaitBlockAfterSwing then
            WaitBlock.Model = Mob.Model
            StartWaitBlock()
        elseif WaitBlock.Holding and (Busy or Wait <= WaitBlockLead) then
            StopWaitBlock()
        end

        if Busy or Wait > 0 then
            return
        end

        -- ท่ากันยังไม่หลุด (ปล่อยแล้วรอเซิร์ฟ) = ตีตอนนี้โดนปัดตก รอเฟรมถัดไป
        if WaitBlock.Holding then StopWaitBlock() end
        if BlockUp() then return end

        -- เพิ่งกลับมาจากหลบ/เดินทาง = เซิร์ฟยังเห็นเราอยู่จุดเดิม หมัดแรกลมเปล่า ยืนนิ่งให้เซิร์ฟตามทันก่อน
        -- (วัดสด: ตีผ่าน 28 ครั้ง โดนจริงแค่ 19 - หมัดที่ตกคือหมัดแรกหลังเข้ามา)
        -- ไม่หยุดทั้งลูปรอ - คืนไปก่อน (Lock ตรึงจุดตีไว้แล้ว) ลูปฟาร์มวนกลับมาเฟรมถัดไปแล้วเช็คใหม่
        if os.clock() - Farmer.ArrivedAt < Farm.SettleTime then
            return
        end

        if Farmer.ComboStart == 0 then
            Farmer.ComboStart = os.clock()
        end

        -- บอสเริ่มท่า/สกิลเรากำลังเงื้อกลางคอมโบ = ตัดออกมาก่อน เลขคอมโบค้างที่ server กลับมาต่อ
        -- หมัดถัดไปได้เลย (server ไม่มีเพดานเวลาต่อคอมโบ - ดูโน้ตที่ ChainWindow)
        Farm.FireCombo(Mob, function()
            return ShouldRun() and Farm.IsMobAlive(Mob) and not Escaping() and not Fighter.Casting()
                and not Fighter.OffWeaponHold() and not Farm.IsMobInvulnerable(Mob) and not Farm.IsMobGuarded(Mob)
        end)

        Farmer.ComboStart = 0

        if not ShouldRun() or not Farm.IsMobAlive(Mob) or Escaping() then
            Fighter.AttackTarget = nil
        end
    end

    -- เดินเข้าไปยืนตี (ถ้ายังไกล เช่นเพิ่งกลับจากหลบสกิลบอส) แล้วตี 1 ชุดคอมโบ
    local function FightMob(Mob, Root)
        local Farmer = Farm.ConfigFarm

        -- กำลังหลบสกิลบอสอยู่ อย่าเพิ่งกลับเข้าไปยืนตี
        if Escaping() then
            Movement.Lock(Escape.CFrame)
            task.wait()
            return
        end

        local Stand = Farm.BuildStandCFrame(Mob.Root.CFrame)
        local Distance = tonumber(ModeSetting("FarmDistance")) or 8

        -- เพิ่งหลบสกิลบอสเสร็จ = วาร์ปกลับจุดตีทันที (Attack -> HoldAt ล็อกตรงจุด) ไม่ tween 300 studs
        local Returning = Escape.Returning
        Escape.Returning = false
        local NearSwitch = 150

        -- มอนตัวถัดไปอยู่ใกล้ = ล็อกเข้าไปตีเลย (Lock ตรึงทุกเฟรมอยู่แล้ว) ไม่วาร์ปแล้วตรึงเฉย ๆ 2.5 วิ
        -- (วัดสด 2026-09-30: ฆ่าตัวเก่าแล้วยืนนิ่งไม่ M1 2.5 วิทุกตัว - ตรึงหลังวาร์ปไว้กันเซิร์ฟดึงกลับระยะไกลเท่านั้น
        -- หลบข้าง 45 studs ถือ 0.7 วิไม่โดนดึง)
        local Gap = (Root.Position - Stand.Position).Magnitude
        if not Returning and Gap > Distance + 4 and Gap > NearSwitch then
            Movement.Lock(nil)
            Movement.Go(Stand, Distance, 20, function()
                return ShouldRun() and Farm.IsMobAlive(Mob) and not Escaping()
            end)
        end

        if Farm.IsMobAlive(Mob) and ShouldRun() then
            --// ตามติดมอนตลอด ไม่ปล่อยตัว (Movement.Lock ตรึง CFrame ทุกเฟรม) แบบ Haze Sea
            Attack(Mob)
        else
            Fighter.AttackTarget = nil
            Movement.Lock(nil)
            Farmer.ComboStart = 0
        end
    end

    -- ตัวเฝ้าทุกเฟรม: ยืนตีอยู่ (ไม่ได้หลบ) แล้วเป้าเริ่มใช้ท่า (pause_gameplay) = วาร์ปหนีทันที
    -- ครอบท่าที่ไม่ส่ง phase เริ่มมาให้ตัวดัก EffectsEvent (เช่น CoreDetachment Throw) + ท่าที่เริ่มตอนเราเพิ่งกลับมาตี
    TrackConnection(RunService.Heartbeat:Connect(function()
        if not Engaged() or not AutoDodge() or Escaping() then return end
        local Mob = Fighter.AttackTarget
        local Model = Mob and Mob.Model
        if not Model then return end
        local IsBoss = NpcKind(Model)
        if IsBoss == nil then return end
        if Escape.KitUsers[Model] then IsBoss = true end
        -- ท่าเงื้อที่เรียนไว้เริ่มเล่น = หลบก่อนดาเมจแรก (ใช้รัศมีที่เรียนของท่านั้นเลย)
        local Windup, WindupKey = nil, nil
        if IsBoss then Windup, WindupKey = LearnedWindup(Model) end
        if Windup then
            TriggerEscape(Model, true, Windup)
            Escape.SawSkillFx = true
            Escape.WindupKey = WindupKey
            return
        end
        if ModelCasting(Model) then TriggerEscape(Model, IsBoss, "Cast") end
    end))

    Fighter.FightMob = FightMob
    Fighter.Escaping = Escaping

    -- เปิดให้ดูสถานะจากคอนโซล/dex (เป้าที่ตีอยู่ ConfigFarm.Mob, หลบอยู่ไหม Fighter.Escaping() ฯลฯ)
    getgenv().ValkyrieFarm = Farm
    getgenv().ValkyrieFighter = Fighter
end

--// Auto Use Skill (ตัวยิงสกิล - แยกออกมาก่อนบล็อก Final Selection Trial ให้ทำงานในด่านด้วย ไม่มี UI)
--
-- เลือกเป็น "คีย์" (F Z X C V ...) ไม่ใช่ชื่อสกิล
--
-- แถบสกิลของเกมมี 10 ช่อง ช่องที่ N ผูกกับ action ชื่อ Skills_<N>th และคีย์ของแต่ละ action อ่านได้
-- จาก InputHandler.KeyLabel (ตามคีย์ที่ผู้เล่นตั้งเอง ไม่ใช่ค่าตายตัว) ส่วนสกิลที่อยู่ในช่องนั้น
-- ตอนนี้คือ Skills_Provider.get_current_keys()[N] (ลำดับใน array = ลำดับช่องบน HUD เป๊ะ ๆ)
--
-- ของเดิมให้เลือกเป็น "ชื่อสกิล" ซึ่งเปลี่ยนไปตามอาวุธ/ปราณที่ถือ พอเก็บอาวุธลิสต์ก็หายเกลี้ยง
-- เลือกเป็นคีย์แทน = ลิสต์คงที่ตลอด ไม่ต้องรีเฟรชตามอาวุธ และสลับอาวุธแล้วยังยิงช่องเดิมต่อได้เลย
--
-- ใช้สกิล = Skill_Controller.Attempt_Hold(ชื่อ, คีย์) เงื้อ แล้ว StopHold(ชื่อ) ปล่อย (ยืนยันสดกับ
-- Double Cut: SHC.Value ขึ้นชื่อสกิล ปล่อยแล้วติด cooldown 12 วิจริง)
-- ก่อนยิงเช็คเหมือนเกม: Skills_Module.Can_Skill (cooldown/stamina) + Checker.check (stun/สถานะ)
-- เล็งเป้าเองผ่าน Platform_Handler.mousepos + จังหวะปล่อยอ่านจาก Config ของสกิล (ดูโน้ตข้างล่าง)
local SkillEngine = { }

do
    local Ok, Err = pcall(function()
        local Config = getgenv().ConfigurationTable

        local SkillsProvider = require(ReplicatedStorage.CAM.Client.Controllers.Skills_Provider)
        local SkillController = require(ReplicatedStorage.CAM.Client.Controllers.Skill_Controller)
        local SkillsModule = require(ReplicatedStorage.CAM.Global.Skills_Module)
        local Checker = require(ReplicatedStorage.CAM.Global.Checker)
        local PlatformHandler = require(ReplicatedStorage.CAM.Client.Controllers.Platform_Handler)
        local InputHandler = require(ReplicatedStorage.CAM.Client.Components.Client.InputHandler)

        local Busy = false

        -- [เลขช่อง] = action ของช่องนั้นบนแถบสกิล (ชื่อตรงกับที่ HUD ใช้) - เกมมี 10 ช่อง ใช้แค่ 2-6
        -- ช่อง 1 (F) = Blocking ท่ากันของทุกอาวุธ ไม่ใช่สกิลโจมตี / ช่อง 7-10 (N K L J) ว่างทุกอาวุธ (วัดสด)
        local SlotActions = {
            [2] = "Skills_2nd", [3] = "Skills_3rd", [4] = "Skills_4th", [5] = "Skills_5th", [6] = "Skills_6th"
        }
        local FirstSlot, LastSlot = 2, 6

        -- คีย์ของแต่ละช่องตามที่ผู้เล่นตั้งไว้ (ค่าเริ่มต้นของเกม: F Z X C V B N K L J)
        -- คืนลิสต์ป้ายคีย์เรียงตามช่อง + ตารางแปลงป้าย -> เลขช่อง
        local function SlotKeys()
            local Labels, ByLabel = { }, { }

            for Slot = FirstSlot, LastSlot do
                local Ok, Label = pcall(InputHandler.KeyLabel, SlotActions[Slot])
                if not (Ok and type(Label) == "string" and Label ~= "") then
                    Label = "Slot " .. Slot
                end

                -- คีย์ซ้ำกัน (ตั้งชนกันเอง) = เก็บช่องแรกที่เจอ
                if not ByLabel[Label] then
                    ByLabel[Label] = Slot
                    table.insert(Labels, Label)
                end
            end

            return Labels, ByLabel
        end

        -- สกิลที่อยู่ในแต่ละช่องตอนนี้ (index = เลขช่อง ตรงกับแถบสกิลบน HUD)
        local function SlotSkills()
            local Ok, Entries = pcall(SkillsProvider.get_current_keys)
            if not Ok or type(Entries) ~= "table" then return { } end
            return Entries
        end

        local function Selected()
            local List = Config.AutoUseSkillKeys
            return type(List) == "table" and List or { }
        end

        --// เล็งเป้า
        --
        -- ทุกสกิลอ่านจุดเล็งจาก Platform_Handler.mousepos (ยิง ray จากกล้องผ่านตำแหน่งเมาส์) ทุกเฟรม
        -- ระหว่างท่าเงื้อ แล้วส่งจุดนั้นให้เซิร์ฟตอนปล่อย - เมาส์ชี้ไปไหนสกิลไปทางนั้น ไม่เล็งเองก็ไม่โดน
        -- (ยืนยันสดจากโค้ด Double Cut: Hold ล็อกทิศตัวละครไปที่ mousepos, ดาเมจคิดฝั่งเซิร์ฟตอน UnHold)
        --
        -- แทน mousepos ด้วยตัวเราเอง: ระหว่างที่สคริปต์ยิงสกิลให้คืนจุดบนตัวเป้าแทนจุดที่เมาส์ชี้
        -- ยิง ray จากตัวเราไปหาเป้าก่อน โดนตัวเป้าจริง = ใช้จุดที่ ray โดน (ผิวตัวมอน) มีอะไรบัง = ใช้กลางตัวมอน
        -- ติดตั้งครั้งเดียวต่อเกม (inject ซ้ำไม่ซ้อน hook) ไม่ได้ยิงสกิลอยู่ = คืนค่าเดิมของเกมตามปกติ
        local AimParams = RaycastParams.new()
        AimParams.FilterType = Enum.RaycastFilterType.Exclude

        local function AimPointFor(Mob)
            local Root = Movement.GetRoot()
            if not (Root and Mob and Mob.Root and Mob.Root.Parent) then return nil end

            -- โมเดลยังค้างอยู่ไม่ได้แปลว่ายังไม่ตาย (ตายแล้วแต่ streaming ยังไม่เก็บ) - เล็งไปที่ศพ
            -- ท่าก็ลงพื้นเปล่า เช็คเลือดจริงเหมือนที่ลูปฟาร์มใช้
            if not Farm.IsMobAlive(Mob) then return nil end

            local Ignore = { Movement.GetCharacter() }
            local Debree = workspace:FindFirstChild("Debree")
            if Debree then table.insert(Ignore, Debree) end

            -- ผู้เล่นคนอื่นยืนขวาง = ray ไปโดนตัวเขาก่อน เลยตกไปใช้กลางตัวมอนแทนจุดบนผิวมอน
            -- ไม่ใช่เรื่องใหญ่แต่กันไว้ได้ฟรี ๆ (คนในเซิร์ฟมีไม่กี่คน วนทุกเฟรมไม่หนัก)
            for _, Other in ipairs(Players:GetPlayers()) do
                if Other ~= LocalPlayer and Other.Character then
                    table.insert(Ignore, Other.Character)
                end
            end

            AimParams.FilterDescendantsInstances = Ignore

            local Goal = Mob.Root.Position
            local Result = workspace:Raycast(Root.Position, Goal - Root.Position, AimParams)
            if Result and Result.Instance and Result.Instance:IsDescendantOf(Mob.Model) then
                return Result.Position
            end

            return Goal
        end

        -- ห่อจากตัวจริงของเกมเสมอ (ValkyrieAimOriginal) รันซ้ำ = ห่อใหม่ทับ ไม่ซ้อนชั้น
        -- จุดเล็ง: ValkyrieAimPoint (ฟาร์มยิงสกิล) ก่อน / ไม่มี = Silent Aim ของแท็บ Combat (ValkyrieSilentAim)
        do
            local Original = getgenv().ValkyrieAimOriginal or PlatformHandler.mousepos
            getgenv().ValkyrieAimOriginal = Original

            PlatformHandler.mousepos = function(Range, Params, Skill)
                local Point = getgenv().ValkyrieAimPoint
                if typeof(Point) ~= "Vector3" then
                    local Resolve = getgenv().ValkyrieSilentAim
                    if type(Resolve) == "function" then
                        local Ok, Value = pcall(Resolve, Range, Skill)
                        if Ok and typeof(Value) == "Vector3" then Point = Value end
                    end
                end
                if typeof(Point) ~= "Vector3" then
                    return Original(Range, Params, Skill)
                end

                -- เกมตัดระยะให้ไม่เกิน Range ของสกิลเอง ทำตามให้เหมือนกัน ไม่งั้นส่งจุดไกลเกินไป
                local Character = LocalPlayer.Character
                local Root = Character and Character:FindFirstChild("HumanoidRootPart")
                if Range and Root then
                    local Offset = Point - Root.Position
                    if Offset.Magnitude > Range then
                        Point = Root.Position + Offset.Unit * Range
                    end
                end

                return Point
            end

            getgenv().ValkyrieAimHooked = true
        end

        --// จังหวะปล่อยของแต่ละสกิล (ไม่เท่ากัน)
        -- ปล่อยเร็วไปท่ายังไม่ขึ้น ปล่อยช้าไปเสียเวลา - อ่านเวลาจริงจาก Config ของสกิลนั้น
        -- (HOLD_FREEZE_AT = ท่าเงื้อค้างที่เฟรมไหน, MIN_HOLD_DUR = ห้ามปล่อยก่อนเวลานี้)
        -- MAX_DISTANCE / MOUSE_RANGE = ระยะที่สกิลไปถึงจริง ไกลกว่านี้ไม่ต้องยิงให้เปลืองคูลดาวน์
        local TimingCache = { }

        local function SkillTiming(Name)
            if TimingCache[Name] then return TimingCache[Name] end

            local Timing = { Hold = 0.35, MaxDistance = nil }

            pcall(function()
                local Folder = nil
                for _, Node in ipairs(ReplicatedStorage.Skills:GetDescendants()) do
                    if Node.Name == Name and Node:FindFirstChild("Config") then
                        Folder = Node
                        break
                    end
                end
                if not Folder then return end

                local Values = require(Folder.Config)
                -- Flame Undulation มีแค่ HOLD_STARTUP_DUR=0.4 (ไม่มี 2 ตัวบน) - เดิมปล่อยที่ 0.2 วิ ท่ายังไม่ขึ้น ดาเมจ 0 (วัดสด 2026-09-30)
                local Hold = math.max(tonumber(Values.HOLD_FREEZE_AT) or 0, tonumber(Values.MIN_HOLD_DUR) or 0,
                    tonumber(Values.HOLD_STARTUP_DUR) or 0, tonumber(Values.HOLD_DURATION) or 0)
                Timing.Hold = math.clamp(Hold + 0.1, 0.2, 1.5)
                Timing.MaxDistance = tonumber(Values.MAX_DISTANCE) or tonumber(Values.MOUSE_RANGE)
            end)

            TimingCache[Name] = Timing
            return Timing
        end

        -- เป้าที่ยอมยิงสกิลใส่ (ในระยะที่ตั้งเองและระยะจริงของสกิล + มอนไม่ได้กันอยู่):
        --   เฉพาะเป้าของโหมดฟาร์มที่เปิดอยู่ (Fighter.AttackTarget = มอน/บอส/add ที่ตัวตีกำลังยืนตีจริง)
        --   ระหว่างหลบสกิลบอส / เดินทาง AttackTarget เป็น nil = ไม่ยิง
        --   ไม่ได้เปิดฟาร์ม = ไม่ยิงเลย (ของเดิมยิงใส่มอนใกล้สุด = โดนมอน/NPC ที่ไม่ได้เลือก)
        -- มอนกำลังกัน (Blocking) / ตั้งท่าสวนสกิล (NpcCounter) ยิงไปเปลืองคูลดาวน์หรือโดนสวน - ข้าม
        local function GetTarget(MaxDistance)
            local Root = Movement.GetRoot()
            if not Root then return nil end

            if Fighter.Continue == nil then return nil end

            local Mob = Fighter.AttackTarget
            if not Farm.IsMobAlive(Mob) or Fighter.Escaping() then
                return nil
            end
            local Distance = (Mob.Root.Position - Root.Position).Magnitude
            if Farm.IsMobGuarded(Mob, true) or Farm.IsMobInvulnerable(Mob) then return nil end

            local Range = tonumber(Config.SkillRange) or 0
            if Range > 0 and Distance > Range then return nil end
            if MaxDistance and Distance > MaxDistance then return nil end

            return Mob
        end

        -- ยิงได้ไหม: ไม่มีสกิลอื่นค้างอยู่ (SHC) + ผ่านด่านเช็คเดียวกับที่เกมใช้
        -- SHC เป็น StringValue ที่ Attempt_Hold สร้างตอนใช้สกิลครั้งแรก - เกิดใหม่แล้วยังไม่มี
        -- Can_Skill จะ error (index boolean) ไม่ใช่ "ใช้ไม่ได้" ปล่อยให้ลองยิงเลย (Attempt_Hold
        -- สร้าง SHC แล้วเช็คซ้ำเองอยู่ดี) ไม่งั้นจะไม่ยิงอะไรเลยจนกว่าจะกดสกิลเองสักครั้ง
        local function CanUse(Name)
            local Character = Movement.GetCharacter()
            if not Character then return false end

            local SHC = Character:FindFirstChild("SHC")
            if SHC and (SHC:GetAttribute("en") == true or SHC.Value ~= "") then return false end

            local Ok, Can = pcall(SkillsModule.Can_Skill, LocalPlayer, Name)
            if Ok and Can ~= true then return false end
            if not Ok and SHC then return false end

            local Ok2, Allowed = pcall(Checker.check, LocalPlayer, Name)
            if Ok2 and not Allowed then return false end

            return true
        end

        ---- การถือ/ปล่อยท่า (ยืนยันสดจาก decompile Skill_Controller + วัดในเกมจริง) ----
        --
        -- Attempt_Hold(ชื่อ, คีย์):
        --   เจอ SHC:GetAttribute("en") == true หรือ Can_Skill/Checker ไม่ผ่าน -> คืน nil เงียบ ๆ
        --   ไม่แตะ SHC เลย (วัดสด: ท่าติดคูลดาวน์ คืนใน 0.000 วิ) ของเดิมห่อ pcall ทิ้งค่าที่คืนมา
        --   เลยไม่รู้ว่ายิงไม่ออก แล้วไปรอเก้อทั้งช่วง Hold ก่อนจะ StopHold ท่าที่ไม่เคยถือ
        --   ยิงออกจริง -> ตั้ง SHC.Value = ชื่อท่า แล้วคืน true ภายใน ~13 ms (วัดสดกับ Blocking)
        --   ท่าพวกนี้มี UnHold ของตัวเองทุกตัว = Attempt_Hold ไม่เคลียร์ SHC.Value ให้ ต้องปล่อยเอง
        --
        -- StopHold(ชื่อ) คืน false เงียบ ๆ ได้หลายทาง ไม่ error สักนิด:
        --   SHC:GetAttribute("en") == true อยู่ (มี Attempt_Hold/Cancel ตัวอื่นคาอยู่)
        --   โมดูลล็อกตัวเองอยู่ (busy flag ข้างใน Skill_Controller ใช้ร่วมกันทั้งเกม)
        --   SHC.Value ไม่ใช่ท่านี้แล้ว
        --   ทุกเคสแปลว่า "UnHold ไม่ได้ถูกส่งไปหา server" - ท่าค้างต่อ CanUse เห็น SHC.Value
        --   ไม่ว่างก็ไม่ยอมยิงอะไรอีกเลย = อาการที่รายงานมา (วัดสดเจอค้างคา "Thunder Clap and Flash"
        --   อยู่ก่อนเริ่มทดสอบด้วยซ้ำ และค้างยาว ~3.5 วิ กว่าจะมีอย่างอื่นมาเคลียร์ให้)
        local HoldStartTimeout = 0.35       -- รอยืนยันว่าเข้าโหมดถือท่าจริงนานสุดเท่านี้
        local ReleaseTries = 4              -- ลองปล่อยซ้ำกี่รอบก่อนใช้ไม้แข็ง
        local AimHoldAfterRelease = 0.25    -- คาจุดเล็งไว้หลังปล่อยอีกเท่านี้ (UnHold ยิง remote ทีหลัง)
        local SkillSettle = 0.25            -- ย้ายไปยืนหน้าเป้าแล้วรอเท่านี้ก่อนเงื้อ (ให้เซิร์ฟเห็นตำแหน่งใหม่)
        local StuckHoldLimit = 2.5          -- ท่าค้างเกินนี้ทั้งที่เราไม่ได้ยิงอยู่ = ไปเคลียร์ให้
        -- เล่นแบบคน: สกิลกับ M1 ไม่ทับกัน
        --   ก่อนเงื้อ = รอหมัด M1 ที่เพิ่งยิงเหวี่ยงจบก่อน (หมัดในชุดห่างกัน ~0.25-0.3 วิ วัดสด 2026-09-30)
        --   หลังปล่อย = ห้าม M1 จนท่าสกิลเล่นจบจริง (animation ที่เริ่มระหว่างเงื้อหยุดครบ) + เว้นจังหวะคนนิดนึง
        --   (เดิมปล่อยปุ๊บ 0.25 วิ M1 หมัด 1 ยิงทับท่าสกิลที่ยังเล่นอยู่)
        -- วัดสด 2026-09-30 (Flame, Lesser Demon): ล้ม 1.0 วิ แต่ ล้ม -> กดสกิล 0.25 วิ + เงื้อ 0.4 วิ = ท่าออกตอนมอนลุก
        -- + หลังปล่อยรอ 1.5-2.5 วิ (นับ animation วนซ้ำด้วย) กว่าจะกลับมาตี = ช้า -> ย่อทุกช่วง
        local SwingRecover = 0.15           -- หมัด M1 ล่าสุดต้องเก่ากว่านี้ก่อนเริ่มเงื้อ (หมัด 5 เข้าแล้วมอนล้ม = เหวี่ยงจบแล้ว)
        local SkillRecoverMax = 1.2         -- รอท่าสกิลเล่นจบนานสุดเท่านี้ (กันท่าไม่ยอมหยุด)
        local SkillReaction = 0.08          -- ท่าจบแล้วเว้นเท่านี้ก่อนกลับไป M1
        local SkillHitGap = 0.85            -- ดาเมจของท่าเงียบนานเท่านี้ = ท่าจบ กลับจุดตีปกติ (Flame Tiger หมัด 4 -> Slam ห่าง 0.78 วิ)
        local SkillHitWait = 1.1            -- ปล่อยแล้วไม่มีดาเมจเลยภายในเท่านี้ = พลาด กลับจุดตีปกติ (ดาเมจแรกมาที่ ~0.6 วิ)
        local SkillCloseMax = 6             -- ยืนหน้ามอนหลังปล่อยนานสุด (กันค้าง)

        local function GetSHC()
            local Character = Movement.GetCharacter()
            return Character and Character:FindFirstChild("SHC")
        end

        local function WaitUntil(Check, Timeout)
            local Deadline = os.clock() + Timeout

            while os.clock() < Deadline do
                if Check() then return true end
                task.wait()
            end

            return Check() and true or false
        end

        local function NotHolding(Name)
            local SHC = GetSHC()
            return (not SHC) or SHC.Value ~= Name
        end

        -- ปล่อยให้จบจริง ไม่ใช่ยิง StopHold ครั้งเดียวแล้วเชื่อ - เช็คค่าที่คืนมา + อ่าน SHC.Value
        -- ซ้ำทุกรอบ ยังไม่หลุดก็ ForceCancel (ทางเดียวกับที่เกมใช้ตอนตัวละครตาย/โดนขัด)
        -- Running() = ท่าออกดาเมจแล้ว (เล่นต่อเองหลังปล่อย เช่น Flame Tiger คาบวิ่ง SHC ค้าง 4 วิ StopHold คืน false)
        -- = ปล่อยแล้ว ห้ามลองซ้ำ/ForceCancel (วัดสด: ตัด Tiger กลางท่า หมัด Slam 34 ไม่ออก)
        local function ReleaseHold(Name, Running)
            if type(Name) ~= "string" or Name == "" then return true end
            if NotHolding(Name) then return true end

            -- StopHold รอ remote ตอบ = คืนค่าหลังท่าปล่อยเล่นจบ (วัดสด Flame Undulation 1.3 วิ / Flame Tiger 2 วิ
            -- หลังดาเมจเข้า) - เรียกแยก thread แล้วดู SHC เอง ไม่ต้องรอมันคืน
            local Pending = false
            for _ = 1, ReleaseTries do
                -- en ยัง true = มีอย่างอื่นคาอยู่ ยิง StopHold ตอนนี้ยังไงก็ได้ false กลับมา
                WaitUntil(function()
                    local SHC = GetSHC()
                    return (not SHC) or SHC:GetAttribute("en") ~= true
                end, 0.25)

                local Result = nil
                if not Pending then
                    Pending = true
                    task.spawn(function()
                        local Ok, Released = pcall(SkillController.StopHold, Name)
                        Result = (Ok and Released) and true or false
                        Pending = false
                    end)
                end

                if WaitUntil(function() return NotHolding(Name) or Result == false end, 0.35) and NotHolding(Name) then
                    return true
                end
                -- StopHold ยังค้างรอ remote = ส่ง UnHold ไปแล้ว ท่ากำลังเล่นช่วงปล่อย (Flame Tiger คุมตัวต่อ 4 วิ)
                -- ห้าม ForceCancel ตัดท่ากลางทาง - นับว่าปล่อยแล้ว (ถ้าไม่หลุดจริง ยามเฝ้าท่าค้างเคลียร์ให้ทีหลัง)
                if Pending and Result == nil then return true end
                if Running and Running() then return true end

                task.wait(0.08)
                if NotHolding(Name) then return true end
            end

            pcall(SkillController.ForceCancel, Name)
            return WaitUntil(function() return NotHolding(Name) end, 0.35)
        end

        -- เงื้อ -> ตามจุดเล็งไปที่เป้าทุกเฟรม (มอนขยับระหว่างเงื้อได้) -> ปล่อยตอนท่าขึ้นครบ
        -- คืน true เฉพาะตอนที่ยิงออกจริง (ผู้เรียกจะได้ไม่เผาคิวรอบนั้นไปฟรี ๆ)
        local function UseSkillRaw(Name, Mob, Key)
            -- ไม่มีจุดเล็ง = ห้ามยิง! hook ของเรายอมคืนค่าเดิมของเกม (= ตำแหน่งเมาส์จริง) เมื่อ
            -- ValkyrieAimPoint ไม่ใช่ Vector3 ท่าเลยออกไปทางที่เมาส์ชี้แทนที่จะไปที่มอน
            -- (วัดสด: ตอนฮับยิง Thunder Clap and Flash จริง ๆ ValkyrieAimPoint เป็น nil อยู่)
            if Farm.Potions and Farm.Potions.Busy then return false end
            local Point = AimPointFor(Mob)
            if not Point then return false end

            Busy = true
            Fighter.SkillBusy = os.clock()

            -- หมัด M1 ที่เพิ่งยิงยังเหวี่ยงอยู่ = รอจบก่อน (SkillBusy ตั้งแล้ว ตัวตีไม่ยิงหมัดใหม่แทรก)
            WaitUntil(function()
                return os.clock() - (Farm.LastSwingAt or 0) >= SwingRecover
            end, SwingRecover)

            -- เก็บ animation ท่าสกิล (Priority Action ขึ้นไป) ที่เริ่มตั้งแต่ตอนนี้ ไว้รอให้เล่นจบก่อนคืน M1
            local SkillTracks, TrackConnection = { }, nil
            pcall(function()
                local Character = Movement.GetCharacter()
                local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
                local Animator = Humanoid and Humanoid:FindFirstChildOfClass("Animator")
                if not Animator then return end
                TrackConnection = Animator.AnimationPlayed:Connect(function(Track)
                    if Track.Priority.Value >= Enum.AnimationPriority.Action.Value then
                        table.insert(SkillTracks, Track)
                    end
                end)
            end)
            -- ดาเมจเข้ามอนครั้งล่าสุดระหว่างท่านี้ (ฟังตั้งแต่เริ่มท่า - Flame Tiger ดาเมจเข้าหมดตอนยังคุมตัวอยู่
            -- ก่อน SHC ว่าง เริ่มฟังหลังปล่อย = เห็นว่าไม่เข้าเลย ยืนหน้ามอนรอเก้อ 1.1 วิ)
            local LastHitAt, HitConnection, HoldStarted = nil, nil, false
            pcall(function()
                local Humanoid = Mob.Humanoid or Mob.Model:FindFirstChildOfClass("Humanoid")
                local Last = Humanoid.Health
                HitConnection = Humanoid.HealthChanged:Connect(function(Health)
                    -- นับเฉพาะหลังเข้าท่าจริง (หมัด M1 ก่อนหน้าไม่นับ ไม่งั้นกลับก่อนท่าตัวเองเข้า)
                    if Health < Last and HoldStarted then LastHitAt = os.clock() end
                    Last = Health
                end)
            end)
            local function StopTracking()
                if TrackConnection then TrackConnection:Disconnect() TrackConnection = nil end
                if HitConnection then HitConnection:Disconnect() HitConnection = nil end
            end

            -- ไม่รีบยิง: ขยับไปยืนหน้าเป้าใกล้ ๆ ก่อน (Farm.SkillClose) รอเซิร์ฟเห็นตำแหน่งใหม่ แล้วค่อยเงื้อ
            Farm.SkillClose = true
            -- หมัด 5 ดีดมอนกระเด็นตอนล้ม = จุดยืนตีกระโดดไปจากเรา (วัดสด: รอ SkillSettle ทุกครั้ง 0.25 วิ)
            -- วัดจากตัวมอนแทน - สกิลไปถึง 40+ studs (AIM_RANGE) ยังอยู่ใกล้ = เงื้อได้เลย
            local Here = Movement.GetRoot()
            local Near = Here and (Here.Position - Mob.Root.Position).Magnitude <= 12
            Movement.Lock(function()
                if not Farm.IsMobAlive(Mob) then return nil end
                return Farm.BuildStandCFrame(Mob.Root.CFrame)
            end)
            -- ยืนตีอยู่ตรงนั้นแล้ว (ปกติ - เพิ่งตีหมัด 5 ให้ล้ม) = เงื้อเลย ไม่ต้องรอเซิร์ฟเห็นตำแหน่งใหม่
            if not Near then task.wait(SkillSettle) end

            Point = AimPointFor(Mob) or Point
            getgenv().ValkyrieAimPoint = Point

            local Timing = SkillTiming(Name)
            local Attempted = nil

            task.spawn(function()
                -- ส่งคีย์ของช่องนั้นไปด้วยเหมือนตอนกดเอง (HUD ส่ง KeyCode.Name เข้า Attempt_Hold)
                local Ok, Result = pcall(SkillController.Attempt_Hold, Name, Key or "")
                Attempted = (Ok and Result == true) or false
            end)

            -- เข้าโหมดถือท่าจริงหรือเปล่า (SHC.Value = ชื่อท่า) - ไม่เข้าก็เลิกตั้งแต่ตรงนี้
            -- ไม่ต้องรอครบช่วง Hold แล้วไป StopHold ท่าที่ไม่เคยถือ
            WaitUntil(function()
                local SHC = GetSHC()
                return (SHC and SHC.Value == Name) or Attempted == false
            end, HoldStartTimeout)

            -- Attempted รู้ผลก่อน SHC.Value จะขยับได้นิดนึง (คนละ thread) - ให้โอกาสอีกเสี้ยว
            -- ก่อนจะสรุปว่ายิงไม่ออก
            if NotHolding(Name) then
                WaitUntil(function() return not NotHolding(Name) end, 0.08)
            end

            if NotHolding(Name) then
                StopTracking()
                getgenv().ValkyrieAimPoint = nil
                Farm.SkillClose = false
                Busy = false
                Fighter.SkillBusy = nil
                return false
            end

            -- เริ่มเงื้อแล้ว = นับว่าใช้ท่าของรอบล้มนี้ไปแล้ว (ถึงจะยกเลิก/คืน false ทีหลัง) - ล้มครั้งละ 1 ท่าเท่านั้น
            Farm.Knock.Used = true
            HoldStarted = true

            -- ตั้งเวลากดค้างเองต่อคีย์ (slider ในแท็บ Players) > 0 = ใช้ค่านั้นแทนจังหวะจาก Config ของสกิล
            local Holds = Config.AutoUseSkillHold
            local Custom = type(Holds) == "table" and tonumber(Holds[Key]) or nil
            local Deadline = os.clock() + ((Custom and Custom > 0) and Custom or Timing.Hold)
            while os.clock() < Deadline do
                -- ท่าจบเองก่อนครบเวลากดค้าง (ตั้ง Hold เอง 4 วิ แต่ Flame Tiger จบที่ 2.5 วิ) = เลิกถือ ไม่ยืนค้างหน้ามอนต่อ
                if NotHolding(Name) then break end
                -- ดาเมจของท่าเข้าครบแล้ว (เงียบ SkillHitGap) = ปล่อยเลย ไม่ถือค้างครบเวลาที่ตั้งเอง (วัดสด Tiger ยืนหน้ามอน 4.3 วิ)
                if LastHitAt and os.clock() - LastHitAt >= SkillHitGap then break end
                -- เริ่มหลบสกิลบอส / มอนตาย / มอนยกการ์ดกลางเงื้อ = ยกเลิกท่าทันที
                -- (ปล่อยตอนนี้ = ท่าโดนการ์ด ดาเมจ 0 / เคยลองถือท่าค้างรอการ์ดลงสูงสุด 1.2 วิ = ตัวแข็งค้างท่าเงื้อ
                -- ผู้ใช้เห็นเป็นตัวค้าง ไม่เอา - 2026-09-30)
                -- iframe ไม่นับ: Flame Tiger คาบมอนระหว่างถือท่า มอนได้ iframe (วัดสด - ยกเลิกแล้วท่าขาดกลางทาง)
                -- ท่าออกดาเมจแล้ว = ไม่ยกเลิก ปล่อยให้เล่นจบ
                if Fighter.Escaping() or not Farm.IsMobAlive(Mob) or (not LastHitAt and Farm.IsMobGuarded(Mob, true))
                    or (not LastHitAt and not HubAction.Allowed("Skill")) then
                    pcall(SkillController.ForceCancel, Name)
                    WaitUntil(function() return NotHolding(Name) end, 0.35)
                    StopTracking()
                    getgenv().ValkyrieAimPoint = nil
                    Farm.SkillClose = false
                    Busy = false
                    Fighter.SkillBusy = nil
                    return false
                end
                local Fresh = AimPointFor(Mob)
                if Fresh then getgenv().ValkyrieAimPoint = Fresh end
                task.wait()
            end

            ReleaseHold(Name, function() return LastHitAt ~= nil end)
            local ReleasedAt = os.clock()

            -- ยังต้องคาจุดเล็งไว้ต่ออีกหน่อย: StopHold ยิง UnHold ผ่าน task.spawn + SignalFunction
            -- (remote function มี round-trip) ฝั่งสกิลอ่าน mousepos ซ้ำตอนนั้น ของเดิมรอแค่ 0.1 วิ
            task.wait(AimHoldAfterRelease)
            getgenv().ValkyrieAimPoint = nil

            -- ท่าออกดาเมจจบแล้ว = กลับจุดตีปกติทันที ไม่ยืนหน้ามอนต่อระหว่างท่าเก็บตัว (วัดสด 2026-09-30:
            -- Flame Undulation ปล่อยแล้วยืนหน้ามอนอีก 1.6 วิ ดาเมจเข้าตั้งแต่ 0.6 วิ = โดนตีฟรี)
            -- จบ = ท่าไม่ได้คุมตัวอยู่ (SHC ว่าง - Flame Tiger คาบวิ่งค้าง SHC 4 วิ) และ
            --   ดาเมจเข้าแล้วเงียบ SkillHitGap (Unknowing Fire เข้าห่างกัน 0.55-0.6 วิ) / ไม่เข้าเลยใน SkillHitWait
            WaitUntil(function()
                if Fighter.Escaping() or not Farm.IsMobAlive(Mob) or Farm.SkillWindow(Mob) then return true end
                -- ดาเมจเข้าแล้วเงียบ = จบ ถึงท่ายังคุมตัวอยู่ (Flame Tiger ค้าง SHC ต่ออีก 1.6 วิหลังหมัดสุดท้าย)
                if LastHitAt then return os.clock() - LastHitAt >= SkillHitGap end
                local SHC = GetSHC()
                if SHC and SHC.Value ~= "" then return false end
                return os.clock() - ReleasedAt >= SkillHitWait
            end, SkillCloseMax)
            Farm.SkillClose = false
            Fighter.LastSkill = { Name = Name, Released = ReleasedAt, LastHit = LastHitAt, Back = os.clock() }  -- ดูสดผ่าน dex

            -- ท่าสกิลยังเล่นอยู่ = ยังไม่ M1 (คนกดสกิลแล้วต้องรอท่าจบก่อนตีต่อ) - หลบสกิลบอสเริ่ม = เลิกรอ
            -- animation วนซ้ำ (ท่ายืนถืออาวุธ/วิ่ง Priority Action) ไม่มีวันจบ = ไม่นับ (เดิมรอครบเพดานทุกครั้ง)
            -- ท่านี้ทำมอนล้มใหม่ (Flame Tiger / Blazing Universe RAGDOLL 1.5 วิ) = เลิกรอ ไปต่อท่าถัดไปในรอบล้มใหม่
            WaitUntil(function()
                if Fighter.Escaping() or Farm.SkillWindow(Mob) then return true end
                for _, Track in ipairs(SkillTracks) do
                    if Track.IsPlaying and not Track.Looped then return false end
                end
                return true
            end, SkillRecoverMax)
            StopTracking()
            if not Fighter.Escaping() then task.wait(SkillReaction) end

            Busy = false
            Fighter.SkillBusy = nil
            return true
        end

        -- จอง Skill ใน HubAction ก่อนเงื้อ (ดื่มยา/หลบ/ท่าที่สำคัญกว่าค้างอยู่ = ไม่ยิง) ปล่อยเมื่อจบ
        -- ระหว่างเงื้อมีท่าที่สำคัญกว่าจองเข้ามา (ดื่มยา) = ยกเลิกท่า (เช็คในลูปถือท่า)
        local function UseSkill(Name, Mob, Key)
            if not HubAction.Claim("Skill", 10) then return false end
            local Ok, Result = pcall(UseSkillRaw, Name, Mob, Key)
            HubAction.Release("Skill")
            if not Ok then
                Busy = false
                Fighter.SkillBusy = nil
                Farm.SkillClose = false
                return false
            end
            return Result
        end

        -- ยามเฝ้าท่าค้าง: ยิงแล้วโดนขัดกลางทาง (ตาย/โดน stun/เปลี่ยนตัวละคร) SHC.Value ค้างชื่อท่า
        -- ไว้โดยไม่มีใครปล่อย CanUse ก็ตันยาว - ไล่เคลียร์ให้เฉพาะตอนเราไม่ได้ยิงอยู่ (Busy) และ
        -- ปุ่มสกิลของเกมไม่ได้ถือคีย์ค้างอยู่เอง (Settings.HeldSkill) จะได้ไม่ไปตัดท่าที่คนเล่นถือเอง
        task.spawn(function()
            local StuckName, StuckSince = nil, 0

            while getgenv().ValkyrieSession == SessionToken do
                task.wait()

                local SHC = GetSHC()
                local Value = SHC and SHC.Value or ""
                local GameHeld = type(SkillController.HeldSkill) == "string" and SkillController.HeldSkill ~= ""

                if Busy or Value == "" or GameHeld or not Config.AutoUseSkill then
                    StuckName, StuckSince = nil, 0
                elseif StuckName ~= Value then
                    StuckName, StuckSince = Value, os.clock()
                elseif os.clock() - StuckSince > StuckHoldLimit then
                    ReleaseHold(Value)
                    StuckName, StuckSince = nil, 0
                end
            end
        end)

        --// Smart Weapon: สกิลของอาวุธที่ถืออยู่ติดคูลดาวน์หมด = สลับไปอาวุธช่องถัดไปใน Toolbar ที่มีสกิลพร้อม
        --
        -- ยืนยันสด (dex):
        --   สกิลบนแถบ = ของอาวุธที่ถืออยู่เท่านั้น (get_current_keys อ่าน Get_equipped_tool) - ปราณ/Demon Art
        --   ติดกับอาวุธประเภท Breathing ทุกเล่ม (ดาบคนละเล่มได้สกิลชุดเดิม) ต่างกันจริงคือ Clan Skills / Combat
        --   Can_Skill ฝั่งเซิร์ฟมี Stats.SourceCheck: ใช้สกิลที่ loadout ไม่มี = anti-cheat Tier1 ("Casted a
        --   skill their loadout does not provide") -> ต้องรอเซิร์ฟยืนยันการสลับก่อนยิงเสมอ
        --   เซิร์ฟยืนยันที่ Player.Items_ConfigServer.Equipped (replicate มา client) - วัดสด 0.07-0.08 วิ
        --   คูลดาวน์ = ลูกใน Character.SHC ชื่อ manage_cd.filter_cd_name(ชื่อสกิล) Value = วินาที
        --   attribute Started = os.clock() ตอนเริ่ม -> เช็คสกิลของอาวุธที่ไม่ได้ถือได้โดยไม่ต้องสลับ
        --   ยังไม่ปลดล็อก (Stats.GetRequirements ค่าที่ 2 = false) เช่น Clan Skills ที่ยังไม่ได้เรียน = ข้าม
        -- ใช้เฉพาะตอนฟาร์ม (Fighter.Continue) - เล่นเองไม่ไปสลับอาวุธในมือให้
        local ManageCd = require(ReplicatedStorage.CAM.Global.Subsets.Gameplay.manage_cd)
        local SkillStats = require(ReplicatedStorage.CAM.Global.SkillService.Stats)

        local SkillsByTool = { }        -- [ชื่อไอเทม] = { [เลขช่อง] = ชื่อสกิล } เรียนตอนถือจริง
        local ToolbarCache = { At = -math.huge, List = { } }
        local SwapAckTimeout = 1        -- เซิร์ฟยืนยันจริง ~0.08 วิ

        local function Learn(Entries)
            local Tool = Farm.GetEquippedToolName()
            if not Tool then return end

            local Map = { }
            for Slot, Entry in pairs(Entries) do
                if type(Entry) == "table" and type(Entry.Name) == "string" and Entry.Name ~= "" then
                    Map[Slot] = Entry.Name
                end
            end
            SkillsByTool[Tool] = Map
        end

        local function Toolbar()
            if os.clock() - ToolbarCache.At > 5 then
                ToolbarCache.At, ToolbarCache.List = os.clock(), Farm.GetToolbar()
                task.wait()     -- GetToolbar เรียก Utility.GetData = thread เสีย capability ชั่วคราว
            end
            return ToolbarCache.List
        end

        local function EquippedValues()
            local Client = LocalPlayer:FindFirstChild("Items_Config")
            local Server = LocalPlayer:FindFirstChild("Items_ConfigServer")
            return Client and Client:FindFirstChild("Equipped"), Server and Server:FindFirstChild("Equipped")
        end

        -- สลับช่องแล้วรอเซิร์ฟยืนยัน - ไม่เห็นค่าฝั่งเซิร์ฟ = ไม่สลับเลย (กัน SourceCheck)
        local function EquipSlot(Slot)
            local Client, Server = EquippedValues()
            if not (Client and Server) then return false end
            if Client.Value ~= Slot then Client.Value = Slot end
            return WaitUntil(function() return Server.Value == Slot end, SwapAckTimeout)
        end

        local function OffhandReady(Name)
            local Ok, _, Met = pcall(SkillStats.GetRequirements, LocalPlayer, Name)
            if not (Ok and Met) then return false end

            local SHC = GetSHC()
            if not SHC then return true end

            local Ok2, CdName = pcall(ManageCd.filter_cd_name, LocalPlayer, Name)
            local Cd = SHC:FindFirstChild(Ok2 and CdName or Name)
            if not Cd then return true end

            local Started = Cd:GetAttribute("Started")
            return type(Cd.Value) == "number" and type(Started) == "number" and os.clock() - Started >= Cd.Value
        end

        -- อาวุธอื่นใน Toolbar ที่ยังไม่รู้ว่ามีสกิลอะไร - สลับไปดูทีละชิ้น (~0.1 วิ) แล้วกลับ
        local function ScanOne(Home)
            for Slot, Tool in pairs(Toolbar()) do
                if not SkillsByTool[Tool] then
                    if EquipSlot(Slot) then
                        task.wait()
                        Learn(SlotSkills())
                        task.wait()
                    end
                    SkillsByTool[Tool] = SkillsByTool[Tool] or { }
                    EquipSlot(Home)
                    return true
                end
            end
            return false
        end

        -- สกิลตามคีย์ที่เลือกของอาวุธชิ้นนี้ที่พร้อมยิงกี่ท่า (ไม่นับ Blocking)
        local function ReadyCount(Tool, Keys, ByLabel)
            local Map = Tool and SkillsByTool[Tool]
            if not Map then return 0 end

            local Count = 0
            for _, Label in ipairs(Keys) do
                local Name = Map[ByLabel[Label]]
                if Name and Name ~= "Blocking" and OffhandReady(Name) then Count = Count + 1 end
            end
            return Count
        end

        -- สถานะให้การ์ดใน UI อ่าน (อ่านอย่างเดียว ไม่เรียก API เกม)
        local Rotation = { Weapon = "-", Ready = 0, Weapons = "-", Last = "-" }
        SkillEngine.Rotation = Rotation

        -- ช่องของอาวุธที่ผู้เล่นเลือก (Select Weapon ของโหมดที่รันอยู่) - ไม่ได้เลือก/ไม่อยู่ใน Toolbar = nil
        local function HomeSlot()
            -- อาวุธหลัก M1 = Select Weapon ของแท็บ (ไม่อยู่ใน Toolbar = เล่ม M1 แรงสุด) - Farm.M1Weapon
            local Name = Farm.M1Weapon(ModeSetting("FarmWeapon"))
            if type(Name) ~= "string" or Name == "" then return nil end
            for Slot, Tool in pairs(Toolbar()) do
                if Tool == Name then return Slot, Tool end
            end
            return nil
        end

        --// หมุนอาวุธ: สกิลของอาวุธในมือติดคูลดาวน์หมด -> สลับไปอาวุธที่มีสกิลพร้อม
        -- ลำดับ: อาวุธที่เลือก (Home) ก่อน แล้วไล่ช่องถัดไปใน Toolbar (วน 1-5) - ช่องไม่มีสกิล (ยา / Crow) ข้าม
        -- ทุกอันติดคูลดาวน์ = กลับไปถืออาวุธที่เลือกแล้ว M1 (M1 ใช้อาวุธที่เลือกเท่านั้น
        -- ระหว่างถืออาวุธยืม ตัวตีไม่ M1 - ดู Fighter.OffWeaponHold)
        -- ระหว่างสลับ SkillBusy ค้างไว้ ตัวตีไม่ยิง M1 ด้วย style ของอาวุธเก่า + ล้างแคช preset
        local function Rotate(Keys, ByLabel)
            local Current = Farm.GetEquippedToolName()
            local Home, HomeTool = HomeSlot()
            local Smart = Config.SmartWeapon and Config.AutoUseSkill

            Rotation.Weapon = Current or "-"
            Rotation.Ready = ReadyCount(Current, Keys, ByLabel)

            local Names = { }
            for Slot = 1, 5 do
                local Tool = Toolbar()[Slot]
                local Map = Tool and SkillsByTool[Tool]
                if Map then
                    for _, Label in ipairs(Keys) do
                        local Name = Map[ByLabel[Label]]
                        if Name and Name ~= "Blocking" then
                            table.insert(Names, Slot .. ":" .. Tool .. (Tool == HomeTool and "*" or ""))
                            break
                        end
                    end
                end
            end
            Rotation.Weapons = #Names > 0 and table.concat(Names, ", ") or "-"

            if not (Smart and Fighter.Continue ~= nil and Fighter.AttackTarget) then return end

            local Client = EquippedValues()
            local Here = Client and Client.Value
            if type(Here) ~= "number" then return end

            local Target, TargetSlot = nil, nil
            local Unknown = false
            for _, Tool in pairs(Toolbar()) do
                if not SkillsByTool[Tool] then Unknown = true end
            end

            if not Unknown then
                if Rotation.Ready > 0 then return end

                if Home and HomeTool ~= Current and ReadyCount(HomeTool, Keys, ByLabel) > 0 then
                    Target, TargetSlot = HomeTool, Home
                else
                    for Step = 1, 4 do
                        local Slot = (Here - 1 + Step) % 5 + 1
                        local Tool = Toolbar()[Slot]
                        if Tool and Tool ~= Current and ReadyCount(Tool, Keys, ByLabel) > 0 then
                            Target, TargetSlot = Tool, Slot
                            break
                        end
                    end
                end

                -- ไม่มีสกิลพร้อมสักอัน = กลับอาวุธที่เลือกไว้ M1
                if not Target and Home and HomeTool ~= Current then
                    Target, TargetSlot = HomeTool, Home
                end
                if not Target then return end
            end

            -- สลับอาวุธ = จอง Swap (ดื่มยา/หลบ/สกิลค้างอยู่ = ไม่สลับ)
            if not HubAction.Claim("Swap", 3) then return end
            Farm.SwapLock = true
            Busy = true
            Fighter.SkillBusy = os.clock()

            pcall(function()
                if Unknown then
                    ScanOne(Here)
                elseif EquipSlot(TargetSlot) then
                    Rotation.Last = tostring(Current) .. " -> " .. Target
                    Rotation.Weapon = Target
                end
            end)

            Farm.InvalidatePreset()
            task.wait(0.05)
            Farm.SwapLock = false
            Busy = false
            Fighter.SkillBusy = nil
            HubAction.Release("Swap")
        end

        SkillEngine.SlotKeys = SlotKeys
        SkillEngine.SlotSkills = SlotSkills
        SkillEngine.SkillsByTool = SkillsByTool
        getgenv().ValkyrieSkillEngine = SkillEngine
        SkillEngine.Selected = Selected

        -- ตัวเฝ้าล้ม: RagDoll โผล่บนเป้าที่ตีอยู่ = ล้ม (เช็คทุกเฟรม RagDoll อยู่แค่ ~1 วิ)
        task.spawn(function()
            local LastModel, Was = nil, false
            while getgenv().ValkyrieSession == SessionToken do
                task.wait()
                local Mob = Fighter.AttackTarget
                local Model = Mob and Mob.Model
                local Now = Model ~= nil and Model:FindFirstChild("RagDoll") ~= nil
                if Model == LastModel and Now and not Was then Farm.NoteKnock(Mob, true) end
                LastModel, Was = Model, Now
            end
        end)

        task.spawn(function()
            while getgenv().ValkyrieSession == SessionToken do
                task.wait()

                local _, HomeTool = HomeSlot()
                Fighter.HomeTool, Fighter.HomeAt = HomeTool, os.clock()

                -- ยิงได้เฉพาะช่องหลังมอนล้ม (Farm.SkillWindow) รอบละ 1 ท่า - นอกช่อง = กลับอาวุธหลักตี M1
                -- (ของเดิมยิงทุกท่าที่พร้อมทุก 0.2 วิ ต่อกันรัว ๆ ไม่รอ M1 ทำให้ล้มก่อน)
                local Window = Farm.SkillWindow(Fighter.AttackTarget)
                local Keys = Config.AutoUseSkill and not Busy and Window and Selected() or { }

                if #Keys > 0 then
                    local _, ByLabel = SlotKeys()
                    local Entries = SlotSkills()

                    -- get_current_keys เรียก Utility.GetData ข้างใน = thread เสีย capability สร้าง
                    -- Instance ชั่วคราว (บั๊กเอ็กซ์พลอยต์ ดูโน้ตที่ Select Weapon) - คั่นก่อนยิงสกิล
                    -- (สคริปต์สกิลสร้าง Attachment/LinearVelocity ในตัว ไม่คั่นแล้วพังเงียบ ๆ)
                    task.wait()

                    Learn(Entries)

                    -- ไล่ตามลำดับคีย์ที่เลือก - ช่องไหนมีสกิล + พร้อม + มีเป้าในระยะก่อน ใช้ช่องนั้น รอบละ 1 สกิล
                    -- ช่องว่าง (อาวุธนี้ไม่มีสกิลในช่องนั้น / ไม่ได้ถืออาวุธ) = ข้ามไปเฉย ๆ
                    local Cast = false
                    for _, Label in ipairs(Keys) do
                        local Slot = ByLabel[Label]
                        local Entry = Slot and Entries[Slot]
                        local Name = type(Entry) == "table" and Entry.Name or nil

                        if type(Name) == "string" and Name ~= "" and CanUse(Name) then
                            local Mob = GetTarget(SkillTiming(Name).MaxDistance)

                            -- ยิงไม่ออก (ติดคูลดาวน์จริง ๆ / เล็งไม่ได้) = ลองช่องถัดไปต่อในรอบเดียวกัน
                            -- ของเดิม break ทิ้งทั้งรอบไม่ว่าจะได้ยิงหรือไม่
                            -- Knock.Used ตั้งตอนเริ่มเงื้อแล้ว (UseSkill) - ห้ามตั้งซ้ำตรงนี้: สกิลทำมอนล้มรอบใหม่ระหว่างท่า
                            -- (วัดสด Flame Tiger / Blazing Universe) ตั้งทับ = เสียรอบล้มใหม่ไปฟรี กลับไปตี M1 แทน
                            if Mob and UseSkill(Name, Mob, Label) then
                                Cast = true
                                break
                            end
                        end
                    end

                    -- อาวุธที่ถืออยู่ไม่มีสกิลพร้อมเลย = หมุนไปอาวุธช่องถัดไป (Smart Weapon)
                    if not Cast then Rotate(Keys, ByLabel) end
                elseif not Busy then
                    -- ไม่ได้เลือกคีย์ / ปิด Auto Use Skill = ไม่มีสกิลให้ยิง -> Rotate พากลับอาวุธที่เลือกไว้ M1
                    Rotate({ }, { })
                end
            end
        end)
    end)

    if not Ok then
        warn("[Valkyrie] Auto Use Skill engine failed: " .. tostring(Err))
    end
end

-- ปิดทั้งระบบ Final Selection ไว้ก่อน (ทั้ง UI ในโลกหลักและตัวเล่นอัตโนมัติในด่าน) จนกว่าจะทดสอบ
-- สมบูรณ์ครบทุกขั้น (มินิเกมยังเล่นแทนไม่ได้ - รอบก่อนตายฟรีเพราะสคริปต์ยืนเฉยตอนถึงมินิเกม)
-- เปิดกลับคืนแค่ตั้งเป็น true บรรทัดเดียว โค้ดข้างล่างทั้งหมดไม่ต้องแตะ
local FinalSelectionEnabled = true

---- ============ Final Selection Trial (ไม่มี UI) ============ ----
--
-- ด่าน Final Selection เป็นอีก place (Minigames, PlaceId 75556147183481 - ยืนยันสดผ่าน dex_status)
-- เข้ามาแล้วเล่นอัตโนมัติแบบ event (เหมือนสายสปายตอน Farm Level): วาร์ปไปยืนใกล้ -> ยิง remote ตรง
-- (AddQuest / QuestProgress / MountainCheckpoint / training_signaler) -> รอ state เปลี่ยน
-- ไม่คุย NPC / ไม่กดบทสนทนา / ไม่กด prompt เก็บของ (ยืนยันจาก Minigames Place.Content["Final Selection"]
-- .NpcContents.Dialogues.Functions.QuestActions = ตัวเลือกในบทพูดยิง remote เดียวกันนี้)
--
local TrialPlaceId = 75556147183481

local function InFinalSelectionTrial()
    local Debree = workspace:FindFirstChild("Debree")
    local Regions = Debree and Debree:FindFirstChild("Regions")
    return (Regions and Regions:FindFirstChild("Final Selection")) ~= nil
end

-- อยู่ในด่าน = ตัวเล่นด่านข้างล่างทำงาน + โหลด UI ต่อตามปกติ (เดิมจบสคริปต์ตรงนี้ ไม่มี UI)
-- ระบบของโลกหลักที่เริ่มเองได้ (ลูปขายของ, Auto Breathing ค้างจากเซฟ, ลูปเข้าด่าน) เช็คตัวนี้แล้วไม่ทำงานในด่าน
local InTrialPlace = FinalSelectionEnabled and (game.PlaceId == TrialPlaceId or InFinalSelectionTrial())

if InTrialPlace then
    local TrialChain = {
        "Locate Rem", "Help Rem", "Find Vael", "Defeat Demons for Vael",
        "Find Klien", "Speak with Klien", "Find Rika", "Treat Klien",
        "Find Mizuto", "Defeat Lost", "The Dungeon", "Find Lavato",
        "Mountain Survival", "Rescue and Hold the Zone", "Find Steve",
        "Defeat the Hand Demon"
    }

    local ChainSet = { }
    for Index, Name in ipairs(TrialChain) do ChainSet[Name] = Index end

    local SignalEvent = HubSignal(require(ReplicatedStorage.Communication.ServerAndClient.Signals.SignalEvent))

    -- ในด่านใช้ค่าของตัวเอง (Trial Settings ในแท็บ Final Selection: FarmMethodTrial)
    -- ไม่ใช้ค่าฟาร์มหลักที่เซฟไว้ (Behind โดนตีสวนจนเลือดเหลือ 11%) - ค่าเริ่ม Above
    -- ModeSetting อ่าน Config[ชื่อ .. Suffix] ก่อน - ตั้ง suffix "Trial" ให้ทั้งด่าน
    do
        local Config = getgenv().ConfigurationTable
        if not table.find(Farm.Methods, Config.FarmMethodTrial) then Config.FarmMethodTrial = "Above" end
        getgenv().ValkyrieFarmSuffix = "Trial"
    end

    local InTrial = InFinalSelectionTrial

    local function Running()
        return getgenv().ValkyrieSession == SessionToken and InTrial()
    end

    local LastLog = nil

    local function Log(State, Step, Task, Detail)
        local Line = string.format("[Valkyrie Trial] %s | %s | %s | %s",
            tostring(State), tostring(Step), tostring(Task), tostring(Detail))
        if Line ~= LastLog then
            LastLog = Line
            print(Line)
        end
    end

    local function QuestDefs()
        local Ok, Module = pcall(function()
            return require(ReplicatedStorage.CAM.Global.Subsets.Gameplay.Quests)
        end)
        return Ok and Module or nil
    end

    -- เควสในลูกโซ่ที่ถืออยู่ตอนนี้ + โฟลเดอร์ Tasks ของมัน
    local function ActiveQuest()
        local Data = select(2, pcall(function()
            return require(ReplicatedStorage.CAM.Global.Utility).GetData(LocalPlayer, true)
        end))
        if typeof(Data) ~= "Instance" then return nil end

        local Holder = Data:FindFirstChild("Quests")
        Holder = Holder and Holder:FindFirstChild("Holder")
        if not Holder then return nil end

        local Best, BestIndex = nil, math.huge
        for _, Folder in ipairs(Holder:GetChildren()) do
            local Index = ChainSet[Folder.Name]
            if Index and Index < BestIndex then
                Best, BestIndex = Folder, Index
            end
        end
        return Best
    end

    -- งานย่อยที่ต้องทำตอนนี้ (Value < Max) - คืนชื่อ task + Code (ชื่อมอนแบบไม่มีช่องว่าง)
    -- ลำดับใน Tasks:GetChildren() สุ่มได้ - เลือกตัวที่ Markers[task].After ครบแล้วก่อน
    -- (เช่น Return to Rem ต้องหลังเก็บผลไม้ครบ / Speak with Levi หลัง Checkpoints) ส่งก่อนเวลาเซิร์ฟไม่นับ
    local function PendingTask(Folder, Def)
        local Tasks = Folder and Folder:FindFirstChild("Tasks")
        if not Tasks then return nil end

        local function Finished(Name)
            local Entry = Tasks:FindFirstChild(Name)
            if not Entry then return true end
            local Value, Max = Entry:FindFirstChild("Value"), Entry:FindFirstChild("Max")
            return Value ~= nil and Max ~= nil and Value.Value >= Max.Value
        end

        local Markers = Def and type(Def.Markers) == "table" and Def.Markers or { }
        local Fallback = nil
        for _, Task in ipairs(Tasks:GetChildren()) do
            if not Finished(Task.Name) then
                local Code = Task:FindFirstChild("Code")
                Code = Code and Code.Value or Task.Name
                local Ready = true
                local Marker = Markers[Task.Name]
                if type(Marker) == "table" and type(Marker.After) == "table" then
                    for _, Need in ipairs(Marker.After) do
                        if not Finished(Need) then Ready = false end
                    end
                end
                if Ready then return Task.Name, Code end
                Fallback = Fallback or { Task.Name, Code }
            end
        end
        if Fallback then return Fallback[1], Fallback[2] end
        return nil
    end

    -- จุดเกิด NPC ของด่าน (Minigames Place.Content["Final Selection"].Npcs.*.Spawns[1]) - ใช้ตอน NPC
    -- หลุด streaming (ยืนยันสด: Lavato ไม่อยู่ใน workspace ตอนอยู่ไกล) ไม่ต้องไล่ workspace:GetDescendants
    local NpcSpawns = { }
    pcall(function()
        local Place = ReplicatedStorage:FindFirstChild("Minigames Place", true)
        for _, Module in ipairs(Place.Content["Final Selection"].Npcs:GetChildren()) do
            local Ok, Def = pcall(require, Module)
            local Spawn = Ok and type(Def) == "table" and type(Def.Spawns) == "table" and Def.Spawns[1] or nil
            if typeof(Spawn) == "CFrame" then Spawn = Spawn.Position end
            if typeof(Spawn) == "Vector3" then NpcSpawns[Module.Name] = Spawn end
        end
    end)

    local function FindNpc(Name)
        local Regions = workspace.Debree:FindFirstChild("Regions")
        local Region = Regions and Regions:FindFirstChild("Final Selection")
        local Stationary = Region and Region:FindFirstChild("StationaryNpcs")
        return Stationary and Stationary:FindFirstChild(Name) or nil
    end

    local function NpcPosition(Name)
        local Model = FindNpc(Name)
        local Root = Model and Model:FindFirstChild("HumanoidRootPart")
        if Root then return Root.Position end
        return NpcSpawns[Name]
    end

    ---- บทสนทนา ----

    local function DialogueFrame()
        local Holder = LocalPlayer:FindFirstChild("PlayerGui")
        Holder = Holder and Holder:FindFirstChild("ComponentsHolder")
        local Frame = Holder and Holder:FindFirstChild("DialogueFrame")
        return (Frame and Frame.Visible) and Frame or nil
    end

    -- ปิดกล่องบทสนทนาที่เกมเปิดเอง (PendingDialogue ตอนมาถึง / NpcNotify) - ไม่ต้องกดไล่ข้อความ
    -- ทุกอย่างในเควสยิง event ตรงแทนตัวเลือกในบทพูดแล้ว (ยืนยันสด: Cancel:Fire() = กล่องหาย)
    local function CloseDialogue()
        pcall(function()
            require(ReplicatedStorage.CAM.Client.Modules.GamePlay.Dialogue).CurrentDialogue.Cancel:Fire()
        end)
    end

    local function GoTo(Position, Threshold)
        Movement.Lock(nil)
        Movement.Go(Position + Vector3.new(0, 4, 0), Threshold or 6, 45, Running)
        Movement.Cancel()       -- Teleport ทิ้ง noclip ไว้ = ร่วงทะลุพื้น
    end

    -- วาร์ปไปยืนใกล้จุด แล้วรอให้เซิร์ฟเห็นตำแหน่งใหม่ก่อนยิง event (เซิร์ฟเช็คระยะ)
    local function Near(Position)
        Movement.Lock(nil)
        Movement.Go(CFrame.new(Position + Vector3.new(0, 3, 0)))
        Movement.Cancel()
        pcall(function() LocalPlayer:RequestStreamAroundAsync(Position, 3) end)
        Farm.Sleep(0.35, Running)
    end

    ---- เควส (แบบ event เหมือนสายสปายตอน Farm Level: ยืนใกล้ -> ยิง remote -> รอ state เปลี่ยน) ----

    local function Held(Quest)
        local Ok, Folder = pcall(function()
            return require(ReplicatedStorage.CAM.Global.Utility).GetData(LocalPlayer, true).Quests.Holder:FindFirstChild(Quest)
        end)
        return Ok and Folder or nil
    end

    -- งานย่อยเสร็จแล้วไหม (Value >= Max) - เควสหายจาก Holder = จบทั้งเควส นับว่าเสร็จ
    local function TaskDone(Quest, Task)
        local Folder = Held(Quest)
        if not Folder then return true end
        local Entry = Folder:FindFirstChild("Tasks") and Folder.Tasks:FindFirstChild(Task)
        local Value = Entry and Entry:FindFirstChild("Value")
        local Max = Entry and Entry:FindFirstChild("Max")
        return Value ~= nil and Max ~= nil and Value.Value >= Max.Value
    end

    local function TaskCount(Quest, Task)
        local Folder = Held(Quest)
        local Entry = Folder and Folder:FindFirstChild("Tasks") and Folder.Tasks:FindFirstChild(Task)
        local Value = Entry and Entry:FindFirstChild("Value")
        return Value and Value.Value or 0
    end

    -- Deliver (คุย/ส่งของ): ยืนใกล้ NPC -> QuestProgress(เควส, task) = remote เดียวกับตัวเลือกในบทพูด
    -- (QuestActions.FoundRem / ReturnToVael / ... ยิงแบบเดียวกัน) - ยืนยันสด Locate Rem จบใน 0.12 วิ
    local function EventDeliver(Quest, Task, Spec)
        local Position = NpcPosition(Spec.TargetNpc)
        if not Position then return false, Spec.TargetNpc .. " position unknown" end

        Log("Event", Quest, Task, "Deliver -> " .. Spec.TargetNpc)
        Near(Position + Vector3.new(0, 0, 4))
        if not Running() then return false, "Stopped" end

        -- NPC ยังไม่โหลด (มาจากจุดเกิดใน module) = รอให้โผล่ก่อนยิง แล้วขยับไปยืนติดตัวจริง
        -- (ยืนยันสด: Lavato ยิงตอนยังไม่โหลดเซิร์ฟไม่นับ 2 รอบ)
        local Root = nil
        Farm.WaitFor(function()
            local Model = FindNpc(Spec.TargetNpc)
            Root = Model and Model:FindFirstChild("HumanoidRootPart")
            return Root ~= nil
        end, 3, Running)
        if Root and (Root.Position - Position).Magnitude > 6 then
            Near(Root.Position + Vector3.new(0, 0, 4))
        end
        Farm.QuestProgress(Quest, Task)
        if Farm.WaitFor(function() return TaskDone(Quest, Task) end, 2, Running) then return true end
        return false, Spec.TargetNpc .. " did not accept (" .. Task .. ")"
    end

    -- Pickup (เก็บของตามจุด): ยืนที่จุด -> QuestProgress(เควส, task, เลขช่อง) (MaxDistance 25)
    -- ไม่ต้องหา/กด prompt ของ - ยืนยันสด Help Rem: Apple/Grapes/Banana ติดทีละ ~0.07 วิ
    local function EventPickup(Quest, Task, Spec)
        local Positions = type(Spec.Positions) == "table" and Spec.Positions or { }
        if #Positions == 0 then return false, "No pickup points" end

        for Slot, Point in ipairs(Positions) do
            if not Running() or TaskDone(Quest, Task) then break end
            local Position = typeof(Point) == "CFrame" and Point.Position or Point
            if typeof(Position) == "Vector3" then
                Log("Event", Quest, Task, "Pickup " .. Slot .. "/" .. #Positions)
                local Before = TaskCount(Quest, Task)
                Near(Position)
                Farm.QuestProgress(Quest, Task, Slot)
                Farm.WaitFor(function() return TaskCount(Quest, Task) > Before or TaskDone(Quest, Task) end, 2, Running)
            end
        end
        if TaskDone(Quest, Task) then return true end
        return false, "Pickup not counted (" .. Task .. ")"
    end

    -- ของที่ task ต้องถือไปส่งขายอยู่ในร้าน NPC ในด่าน - ยืนยันสด: Bandage อยู่ที่
    -- StationaryNpcs.Rika."Rika's Shop".Bandage.PromptPart (ProximityPrompt ObjectText = "Bandage",
    -- ActionText = "Purchase") ใช้ prompt แค่หาตำแหน่งร้าน ตัวซื้อจริงยิง remote ด้านล่าง
    local function GetItem(Item)
        local Regions = workspace.Debree:FindFirstChild("Regions")
        local Region = Regions and Regions:FindFirstChild("Final Selection")
        if not Region then return false, "Region not loaded" end

        local Prompt = nil
        for _, Object in ipairs(Region:GetDescendants()) do
            if Object:IsA("ProximityPrompt") and Object.Enabled
                and (Object.ObjectText == Item or (Object.Parent and Object.Parent.Parent
                    and Object.Parent.Parent.Name == Item)) then
                Prompt = Object
                break
            end
        end
        if not Prompt then return false, "No shop prompt for " .. Item end

        local Part = Prompt.Parent
        local Position = (Part:IsA("BasePart") and Part.Position)
            or (Part:IsA("Attachment") and Part.WorldPosition) or nil
        if not Position then return false, "Shop prompt has no position" end

        -- เซิร์ฟเช็คระยะจากร้านด้วย (ยืนห่าง 30 studs ยิงไปเงียบ ๆ ไม่ได้ของ) - เข้าไปยืนติด PromptPart
        GoTo(Position, 3)
        if not Running() then return false, "Stopped" end
        task.wait(0.4)

        -- fireproximityprompt ไม่เปิด ShopDialogue ของเกม (prompt เป็น Style Custom) - ยิงตรงแบบเดียวกับ
        -- ปุ่ม Purchase ในบทสนทนา (Dialogue.ProceedWithPurchase): Shop.CanBuy ผ่านแล้วค่อย
        -- SignalEvent.ToServer("PurchaseFromShop", ชื่อของ, จำนวน) - ยืนยันสด: Bandage เข้ากระเป๋า Wen 86 -> 61
        local Ok, Why = pcall(function()
            local Shop = require(ReplicatedStorage.CAM.Global.Shop)
            local Amount = Shop.SanitizeAmount(1)
            local Can, Reason = Shop.CanBuy(LocalPlayer, Item, nil, Amount)
            if not Can then error(tostring(Reason or "cannot buy"), 0) end

            HubSignal(require(ReplicatedStorage.Communication.ServerAndClient.Signals.SignalEvent))
                .ToServer("PurchaseFromShop", Item, Amount)
        end)
        if not Ok then return false, "Could not buy " .. Item .. ": " .. tostring(Why) end

        local Deadline = os.clock() + 3
        while os.clock() < Deadline and not Farm.HasItem(Item) do task.wait() end

        if Farm.HasItem(Item) then return true end
        return false, "Bought " .. Item .. " but it did not arrive"
    end

    -- กันตาย: ตายครบ 3 ครั้ง (Hearts หมด) = ตก Final Selection โดนส่งกลับ ห้ามเสี่ยง
    -- เลือดต่ำกว่าเกณฑ์ = เลิกตี ถอยไปยืนบนพื้นห่างมอนรอเลือดฟื้น เหลือหัวใจน้อยยิ่งระวังมากขึ้น
    -- (เดิมลอยขึ้นฟ้า 70 studs ค้างจนเลือดเต็ม = โดน kick - ผู้ใช้ 2026-09-30)
    -- วัดสด 2026-10-01 Hand Demon: ถอย 80 / ถอยใหม่ที่ 25 = Rogue Demon 3 ตัววิ่งตามมาตีจนตาย (เสีย 1 Heart)
    -- ถอย 250 + ถอยใหม่ตอนตัวไล่เข้ามาใกล้ 80 = รอดจาก HP 17% (ไม่มีตัวไหนตามทัน)
    local RetreatDistances = { 250, 150, 80 }
    local RetreatAgain = 80         -- มอนที่ไล่อยู่เข้ามาใกล้กว่านี้ = ถอยใหม่

    local function HealthFraction()
        local Humanoid = Movement.GetHumanoid()
        if not Humanoid or Humanoid.MaxHealth <= 0 then return 1 end
        return Humanoid.Health / Humanoid.MaxHealth
    end

    local function SafeFloor()
        local Hearts = tonumber(LocalPlayer:GetAttribute("Hearts")) or 3
        if Hearts <= 1 then return 0.75 end
        if Hearts == 2 then return 0.55 end
        return 0.4
    end

    -- ยืนบนพื้นห่างมอนจนเลือดกลับมาเต็มพอ (RegenRate ของเกมคือ 2% ต่อจังหวะ) มอนตามมาใกล้ = ถอยต่อ
    local function Retreat()
        local Root = Movement.GetRoot()
        if not Root then return end

        local function Spot()
            for _, Distance in ipairs(RetreatDistances) do
                local Found = Movement.SafeGroundSpot(Distance)
                if Found then return Found end
            end
            return nil
        end

        Movement.Lock(Spot() or Root.CFrame)

        while Running() and HealthFraction() < 0.95 do
            if Movement.ChaserNear(RetreatAgain) then
                local Found = Spot()
                if Found then Movement.Lock(Found) end
            end
            Log("Waiting", "-", "Healing", string.format("HP %d%% - resting on the ground until 95%%", math.floor(HealthFraction() * 100)))
            task.wait()
        end

        Movement.Lock(nil)
    end

    local function Normalize(Text)
        return (tostring(Text):gsub("[^%w]", ""):lower())
    end

    -- มอนที่ตรงกับ Code / ชื่อ task (ใกล้สุด) - เทียบแบบตัดช่องว่าง/ตัวพิมพ์ทิ้ง ("LesserDemon" = "Lesser Demon")
    -- ชื่อ task เป็นพหูพจน์ได้ ("Lesser Demons") เลยยอมให้ชื่อมอนเป็นส่วนหนึ่งของมันด้วย
    local function FindTarget(Root, Code, TaskName)
        local Wants = { Normalize(Code), Normalize(TaskName) }
        local Best, BestDistance = nil, math.huge

        for _, Entry in ipairs(Farm.IterMobs()) do
            local Name = Normalize(Entry.Model.Name)
            for _, Want in ipairs(Wants) do
                if Want ~= "" and (Want == Name or Want:find(Name, 1, true)) then
                    local Distance = (Entry.Root.Position - Root.Position).Magnitude
                    if Distance < BestDistance then
                        Best, BestDistance = Entry, Distance
                    end
                    break
                end
            end
        end

        return Best
    end

    local function InstantKillReady(Mob)
        local Config = getgenv().ConfigurationTable
        if not Config.TrialInstantKill then return false end
        local Max = Mob.Humanoid.MaxHealth
        if not (Max and Max > 0) then return false end
        local Limit = math.min(tonumber(Config.TrialInstantKillHealth) or 90, 90)
        return Mob.Humanoid.Health / Max * 100 <= Limit
    end

    -- เควสสู้: ตัวตีเดียวกับ Auto Farm Level (Fighter.FightMob = 1 รอบ เดินเข้า/คอมโบ/หลบสกิลบอส)
    -- วนจนเป้าตาย - เลือดตกต่ำกว่าเกณฑ์กันตายเมื่อไหร่หลุดลูปทันที รอบหน้า Retreat ไปฟื้นเลือดก่อน
    local function Fight(Code, TaskName)
        local Root = Movement.GetRoot()
        if not Root then return false, "No character" end

        if HealthFraction() < SafeFloor() then
            Retreat()
            return true, "healing"
        end

        local Mob = FindTarget(Root, Code, TaskName)
        if not Mob then return false, "No " .. tostring(Code) .. " loaded" end

        -- บอสเรียกลูกน้องออกมาเป็นระลอก (ยืนยันสด Hand Demon: ตอนมี Rogue Demon อยู่ BoolValue "iframe" = true
        -- ตีบอส 15 hit ดาเมจ 0 แล้วบอสรีเลือดคืน) - ตัวเล็กรอบบอสต้องตายก่อนเสมอ เช็คทุกรอบ ไม่ใช่แค่ตอนเริ่ม
        -- (ระลอกใหม่โผล่กลางไฟต์ได้ตลอด) เจอเมื่อไหร่ทิ้งบอสไปเก็บตัวเล็กทันที
        local Boss = Mob

        -- ตัวเล็ก = มอนคนละชื่อกับเป้า (Rogue Demon รอบ Hand Demon) - ชื่อเดียวกันคือเป้าของ task เอง
        -- (ของเดิมนับ Lesser Demon ตัวอื่นเป็น "add" = สลับเป้าไปมาทุกตัว ตีตัวละ ~20 วิ)
        -- เช็คเฉพาะเป้าที่เป็นบอส (มี BoolValue iframe - Hand Demon) งานฆ่ามอนธรรมดาไม่ต้องไล่ตัวอื่น
        -- (ยืนยันสด: Lesser Demon / Lost ไม่มี iframe - ของเดิมไปไล่ Rogue Demon ที่เดินผ่าน)
        local BossName = Normalize(Boss.Model.Name)
        local Shield = Boss.Model:FindFirstChild("iframe", true)
        local IsBoss = Shield ~= nil

        -- iframe.Value = true ตอนลูกน้อง (Rogue Demon) ยังมีชีวิต = บอสอมตะ ตีไปดาเมจ 0
        local function Shielded()
            return Shield ~= nil and Shield.Parent ~= nil and Shield:IsA("BoolValue") and Shield.Value == true
        end

        -- ผู้ใช้ 2026-10-01: ลูกน้อง (Rogue Demon) ออกมาเมื่อไหร่ต้องฆ่าก่อนเสมอ - วัดสด: ลูกน้องวิ่งไล่เรา
        -- ห่างบอส 550+ studs (เกินรัศมี 400 จากบอส) iframe บอสค้าง แต่ hub ยังตีบอสอมตะต่อจนเลือดเหลือ 35%
        -- = ลูกน้องที่: ใกล้บอส <= 400 / ใกล้ตัวเรา <= 250 (ตามมาไล่) / บอสติด iframe อยู่ (ตัวไหนก็ได้ทั้งแมพ)
        -- เลือกตัวที่ใกล้ "ตัวเรา" ที่สุด (ไม่ต้องวาร์ปไกล ตัวที่ไล่เราอยู่ตายก่อน)
        local function FindAdd()
            if not IsBoss or not Farm.IsMobAlive(Boss) then return nil end
            local Here = Movement.GetRoot()
            local Anywhere = Shielded()

            local Add, AddDistance = nil, math.huge
            for _, Entry in ipairs(Farm.IterMobs()) do
                if Entry.Model ~= Boss.Model and not Entry.IsBoss and Farm.IsMobAlive(Entry)
                    and Normalize(Entry.Model.Name) ~= BossName then
                    local FromBoss = (Entry.Root.Position - Boss.Root.Position).Magnitude
                    local FromMe = Here and (Entry.Root.Position - Here.Position).Magnitude or FromBoss
                    if (Anywhere or FromBoss <= 400 or FromMe <= 250) and FromMe < AddDistance then
                        Add, AddDistance = Entry, FromMe
                    end
                end
            end
            return Add
        end

        local Add = FindAdd()
        if Add then
            Log("Running", "-", TaskName, "Killing add " .. Add.Model.Name .. " first")
            Mob = Add
        end

        -- อาวุธจาก dropdown "Select Weapon" ของแท็บ Final Selection (FarmWeaponTrial - suffix "Trial")
        local Weapon = ModeSetting("FarmWeapon")
        if type(Weapon) == "string" and Weapon ~= "" and Weapon ~= "None" then
            Farm.EquipWeapon(Weapon)
        end

        Fighter.Reset()
        -- เก็บไว้ใน local ด้วย - cleanup (inject ซ้ำ) ล้าง Fighter.Continue เป็น nil กลางลูปได้
        local Continue = function()
            return Running() and HealthFraction() >= SafeFloor() * 0.7
        end
        Fighter.Continue = Continue

        Log("Running", "-", TaskName, "Fighting " .. Mob.Model.Name)

        local NextAddCheck = 0

        while Continue() and Farm.IsMobAlive(Mob) do
            local Here = Movement.GetRoot()
            if not Here then break end

            -- กำลังตีบอสอยู่แล้วตัวเล็กระลอกใหม่โผล่ = ออกไปให้รอบหน้าเลือกตัวเล็กก่อน
            if Mob == Boss and (Shielded() or os.clock() >= NextAddCheck) then
                NextAddCheck = os.clock() + 0.3
                if FindAdd() then break end
            end

            Fighter.FightMob(Mob, Here)

            -- Instant Kill (toggle แท็บ Final Selection): เฉพาะมอนที่ไม่ใช่เป้าของเควส (ลูกน้องบอส เช่น
            -- Rogue Demon รอบ Hand Demon) - เป้าเควสตายแบบนี้เควสไม่นับ (ยืนยันจากผู้ใช้) ต้องตีจนตายปกติ
            -- เลือดลูกน้องเหลือ <= % ที่ตั้ง + ตีโดนจนได้ owner แล้ว = สั่งตายทันที iframe บอสหายเร็วขึ้น
            if Mob ~= Boss and InstantKillReady(Mob) and Farm.TryInstantKill(Mob) then
                Log("Running", "-", TaskName, "Instant kill " .. Mob.Model.Name)
            end
            task.wait()
        end

        Fighter.Continue = nil
        Movement.Lock(nil)
        return true, Mob.Model.Name
    end

    -- Value / Max ของ task ในเควสที่ถืออยู่ (ไม่มี = nil)
    local function TaskValues(QuestName, TaskName)
        local Ok, Task = pcall(function()
            return require(ReplicatedStorage.CAM.Global.Utility).GetData(LocalPlayer, true)
                .Quests.Holder[QuestName].Tasks[TaskName]
        end)
        local Value = Ok and Task and Task:FindFirstChild("Value")
        local Max = Ok and Task and Task:FindFirstChild("Max")
        if not (Value and Max) then return nil end
        return Value, Max
    end

    local function RunFastMinigame(Name, Task)
        -- Mountain Survival (ยืนยันสดจาก decompile "Minigames Place".MountainSurvival + MountainSurvivalUI):
        --   run เริ่มเองตอนได้เควส จับเวลา 115 วิ (attribute MountainTrialEndsAt) หมดเวลา = เสีย 1 Heart
        --   แล้วเควสรีเซ็ตกลับ Find Lavato (ของเดิมยิง StartMountainTrial/QuestProgress มั่ว ๆ = โดนหักหัวใจจริง)
        --   นับแท่นด้วย SignalEvent.ToServer("MountainCheckpoint", เลขแท่น) - ต้องเรียงลำดับ (Value + 1) และยืนห่าง
        --   TouchPart ไม่เกิน Size.Magnitude/2 + 20 / ครบ 4 แท่นแล้วค่อยไปคุย Levi (Deliver ปกติ)
        if Name == "Mountain Survival" and Task == "Checkpoints" then
            local Value, Max = TaskValues(Name, Task)
            local Pads = workspace.Debree:FindFirstChild("MountainCheckpoints")
            if not (Value and Pads) then
                Log("Waiting", Name, Task, "Mountain run not ready")
                task.wait()
                return true
            end

            for Index = Value.Value + 1, Max.Value do
                if not Running() then break end

                local Pad = Pads:FindFirstChild("Checkpoint" .. Index)
                local Touch = Pad and Pad:FindFirstChild("TouchPart")
                if not Touch then
                    Log("Waiting", Name, Task, "Pad " .. Index .. " not loaded")
                    pcall(function() LocalPlayer:RequestStreamAroundAsync(Pads:GetPivot().Position, 5) end)
                    task.wait()
                    return true
                end

                Log("Event", Name, Task, "Mountain pad " .. Index)
                Movement.Go(CFrame.new(Touch.Position + Vector3.new(0, 3, 0)))
                task.wait(0.8) -- ให้เซิร์ฟเห็นตำแหน่งใหม่ก่อน (เช็คระยะจากแท่น)
                pcall(function() SignalEvent.ToServer("MountainCheckpoint", Index) end)

                local Deadline = os.clock() + 2
                while os.clock() < Deadline and Value.Parent and Value.Value < Index do task.wait() end
                if not Value.Parent or Value.Value < Index then break end
            end
            return true
        end

        -- Rescue and Hold the Zone (ยืนยันสดจาก decompile "Minigames Place".ZoneRescue - ทดสอบสดผ่านครบ):
        --   RescueZonePos (attribute ผู้เล่น) = จุดโซน สุ่ม 10 จุด / เซิร์ฟเช็คแค่ระยะแนวราบ (x,z) เลยลอยสูง 40 เหนือโซน
        --   มอนที่เกิดเป็นระลอกตีไม่ถึง ไม่โดน stun (stun/ragdoll = หลอดหยุด) ~25 วิ -> Captured
        --   -> RescueCivilian โผล่ใน Debree (prompt hold 5 ไม่เช็ค LOS) -> Carrying -> ยืนห่าง Levi ไม่เกิน 12 = ส่ง
        --   ไม่มีบทลงโทษ (ไม่หักหัวใจ) - พังกลางทางเซิร์ฟ spawn พลเรือนใหม่ให้เอง
        if Name == "Rescue and Hold the Zone" then
            local State = LocalPlayer:GetAttribute("RescueZoneState")

            if State == "Carrying" then
                local Levi = FindNpc("Levi")
                local LeviRoot = Levi and Levi:FindFirstChild("HumanoidRootPart")
                local At = LeviRoot and LeviRoot.Position or Vector3.new(-5195.2, 38, 1006.4)
                Log("Event", Name, Task, "Carrying civilian to Levi")
                Movement.Go(CFrame.new(At + Vector3.new(0, 3, 4)))
                task.wait(2)
                return true
            end

            if State == "Captured" then
                local Civilian = workspace.Debree:FindFirstChild("RescueCivilian")
                local Prompt = Civilian and Civilian:FindFirstChildWhichIsA("ProximityPrompt", true)
                if not Prompt then
                    Log("Waiting", Name, Task, "Civilian not spawned")
                    task.wait()
                    return true
                end

                Log("Event", Name, Task, "Picking up civilian")
                local At = Civilian:GetPivot().Position
                Movement.Go(CFrame.new(At + Vector3.new(0, 2, 4), At))
                task.wait(0.6)
                local function Carrying() return LocalPlayer:GetAttribute("RescueZoneState") == "Carrying" end
                Prompts.Use(Prompt, { Check = Carrying })
                task.wait(1)

                if not Carrying() then
                    Prompts.Use(Prompt, { Hold = true, Check = Carrying })
                    task.wait(1)
                end
                return true
            end

            local Zone = LocalPlayer:GetAttribute("RescueZonePos")
            if typeof(Zone) ~= "Vector3" then
                Log("Waiting", Name, Task, "Zone not assigned")
                task.wait()
                return true
            end

            -- ยืนบนพื้นกลางโซน ตีปีศาจที่วิ่งเข้ามาหา (เดิมลอยสูง 40 เหนือโซน 25 วิ = โดน kick - ผู้ใช้ 2026-09-30)
            -- เซิร์ฟ (ZoneRescue.tick ทุก 0.25 วิ): อยู่ในรัศมีแนวราบ + ไม่ติด Stun/RagDoll/Blocking = หลอด +0.25 ครบ 25 = Captured
            -- ออกนอกโซน = หลอดรีเป็น 0 -> Farm.StandZone ดึงจุดยืนตี/จุดหลบทุกจุดให้อยู่ในโซน
            -- ปีศาจ (RogueDemon ล็อกเป้าเรา) เกิดห่าง 25-35 studs ทีละตัว ระลอกใหม่ทุก 18 วิถ้าตัวเก่าตายแล้ว
            local Radius = 20
            pcall(function()
                local Part = ReplicatedStorage.QuestStates["Rescue and Hold the Zone"].Checkpoint:FindFirstChild("TouchPart", true)
                if Part and Part:IsA("BasePart") then
                    local Size = Part.Size
                    Radius = (Part:IsA("Part") and Part.Shape == Enum.PartType.Cylinder) and math.max(Size.Y, Size.Z) / 2
                        or math.max(Size.X, Size.Z) / 2
                end
            end)

            local Center = CFrame.new(Zone + Vector3.new(0, 3, 0))
            Log("Event", Name, Task, ("Holding zone on the ground (radius %d)"):format(Radius))
            Movement.Lock(nil)
            Movement.Go(Center)

            Farm.StandZone = { Center = Zone, Radius = math.max(Radius - 3, 5) }
            Fighter.Reset()
            local Continue = function() return Running() end
            Fighter.Continue = Continue

            local Deadline = os.clock() + 90
            while Running() and os.clock() < Deadline
                and LocalPlayer:GetAttribute("RescueZoneState") ~= "Captured" do
                local Here = Movement.GetRoot()
                -- ปีศาจที่เข้ามาใกล้โซนแล้ว (ไม่วิ่งออกไปไล่ตัวที่ยังอยู่ไกล)
                local Mob, Best = nil, Radius + 8
                for _, Entry in ipairs(Farm.IterMobs()) do
                    local Flat = ((Entry.Root.Position - Zone) * Vector3.new(1, 0, 1)).Magnitude
                    if Flat < Best and Farm.IsMobAlive(Entry) then Mob, Best = Entry, Flat end
                end
                if Here and Mob then
                    Fighter.FightMob(Mob, Here)
                else
                    Fighter.AttackTarget = nil
                    Movement.Lock(Center)
                end
                task.wait()
            end

            if Fighter.Continue == Continue then Fighter.Continue = nil end
            Farm.StandZone = nil
            Movement.Lock(nil)
            return true
        end

        -- เฉพาะ task Complete Dungeon - Return to Mizuto ปล่อยให้ Deliver ปกติจัดการ
        if Task == "Complete Dungeon" then
            -- ยืนยันสดจาก decompile Training."Parkour Dungeon".Server/Client/lever:
            --   เซิร์ฟนับ "Complete" ตอน Stop เมื่อ (1) ดึงคันโยกใน Switchs ครบทุกอัน ระหว่างที่มี session
            --   (Values.Training) อยู่ และ (2) ตัวละครอยู่ในรัศมี 75 จาก Map.Final - แตะธงเฉย ๆ ไม่นับอะไรเลย
            --   (ของเดิมวาร์ปวนธง 1-2-3 ซ้ำ ตัวละครเลยเด้งไปมาที่ธงไม่จบ)
            --   session เริ่มจาก prompt "Train" ที่ Debree."Parkour Dungeon".Ref (โหลดเฉพาะตอนอยู่ใกล้)
            --   คันโยก = prompt hold 3 วิ ต้อง hold จริง (Triggered เช็ค HoldBegan) fireproximityprompt ไม่ผ่าน
            --   และต้องหันกล้องเข้าหาคันโยกด้วย / prompt เปิดทีละด่าน (Level ขึ้นทีละ 1/#คันโยกของด่าน)
            --   แตะ Final = client ยิง training_signaler "Stop" ทันที - ต้องไปยืนใกล้ก่อนให้เซิร์ฟเห็นตำแหน่ง
            local Map = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("DetachedMaps")
            Map = Map and Map:FindFirstChild("ParkourTraining")
            if not Map then
                Log("Waiting", Name, Task, "Parkour map not loaded")
                task.wait()
                return true
            end

            local Values = select(2, pcall(function()
                return require(ReplicatedStorage.CAM.Global.Utility).getvaluesfolder(LocalPlayer)
            end))
            local function InSession()
                return typeof(Values) == "Instance" and Values:FindFirstChild("Training") ~= nil
            end

            -- ปุ่ม Train ของดันเจี้ยนเช็ค Character_info_provider.HasUnlockedSkills({ "Double Jump", "Wall Climb" })
            -- (Training."Parkour Dungeon".Server) ไม่มีสกิล = กดแล้วเงียบ ไม่เริ่ม session (ยืนยันสด: ค้างหน้าประตู)
            -- ปลดใน skill tree ด้วย SignalFunction.ToServer("UnlockSkillTreeNode", ชื่อสกิล) แบบปุ่ม UNLOCK
            -- (ยืนยันสด: Double Jump 3 แต้ม, Wall Climb 6 แต้ม - ส่งชื่อหมวด "Innate Skills" เซิร์ฟคืน false)
            if not InSession() then
                local Stats = select(2, pcall(require, ReplicatedStorage.CAM.Global.SkillService.Stats))
                local SignalFunction = HubSignal(select(2, pcall(require, ReplicatedStorage.Communication.ServerAndClient.Signals.SignalFunction)))
                for _, Skill in ipairs({ "Double Jump", "Wall Climb" }) do
                    local Ok, Has = pcall(Stats.IsSkillUnlocked, LocalPlayer, Skill)
                    if Ok and not Has then
                        Log("Event", Name, Task, "Unlocking " .. Skill .. " (skill tree)")
                        local Sent, Done, Why = pcall(SignalFunction.ToServer, "UnlockSkillTreeNode", Skill)
                        if not (Sent and Done) then
                            Log("Waiting", Name, Task, "Need " .. Skill .. " in the skill tree: " .. tostring(Why or "not enough skill points"))
                            Farm.Sleep(3, Running)
                            return true
                        end
                    end
                end
            end

            -- สถานะข้ามรอบ (เก็บใน Farm - main chunk เต็ม 200 local): คันโยกที่เซิร์ฟนับแน่ ๆ ของ session นี้ + กันวนเริ่มใหม่
            local Dungeon = Farm.TrialDungeon or { Fails = 0, NextStartAt = 0, Session = nil, Pulled = { } }
            Farm.TrialDungeon = Dungeon

            -- จบไม่ผ่านติดกัน 3 รอบ = หยุดเริ่มใหม่ (เมื่อคืน: จบไม่ผ่านแล้ววนเริ่มใหม่ไม่หยุด วาร์ปเข้าออกแมพ
            -- ~6,000 studs ทุกไม่กี่วิ = โดน kick) - รอบที่ไม่ผ่านเว้น 8 วิก่อนเริ่มใหม่
            if not InSession() then
                if Dungeon.Fails >= 3 then
                    Log("Waiting", Name, Task, "Dungeon failed 3 times - stopped retrying (re-inject to try again)")
                    Farm.Sleep(5, Running)
                    return true
                end
                if os.clock() < Dungeon.NextStartAt then
                    Log("Waiting", Name, Task, "Waiting before restarting the dungeon")
                    task.wait(0.5)
                    return true
                end

                Log("Event", Name, Task, "Starting Parkour Dungeon")
                local Def = QuestDefs()
                Def = Def and Def.Holder and Def.Holder["The Dungeon"]
                local Marker = Def and Def.Markers and Def.Markers["Complete Dungeon"]
                local Entrance = (Marker and typeof(Marker.Position) == "Vector3" and Marker.Position)
                    or Vector3.new(-5730.5, 44.5, 1439.8)

                Movement.Go(CFrame.new(Entrance + Vector3.new(0, 3, 2)), 8)
                pcall(function() LocalPlayer:RequestStreamAroundAsync(Entrance, 5) end)

                local Folder = workspace.Debree:FindFirstChild("Parkour Dungeon")
                local Ref = Folder and Folder:WaitForChild("Ref", 5)
                local Prompt = Ref and Ref:FindFirstChildWhichIsA("ProximityPrompt", true)
                if not Prompt then
                    Log("Waiting", Name, Task, "Dungeon entrance not loaded")
                    task.wait()
                    return true
                end

                task.wait(0.5)
                Prompts.Use(Prompt, { Check = InSession })

                local Deadline = os.clock() + 5
                while os.clock() < Deadline and not InSession() do task.wait() end
                if not InSession() then
                    Dungeon.NextStartAt = os.clock() + 3
                    return true
                end

                task.wait(2.5) -- ฉากเปลี่ยน + client วาร์ปเข้าแมพ
            end

            -- session ใหม่ (Values.Training ตัวใหม่) = ล้างรายการคันโยกที่เซิร์ฟนับ (PulledSwitches ของเซิร์ฟเริ่มว่างทุก session)
            local Session = typeof(Values) == "Instance" and Values:FindFirstChild("Training") or nil
            if Dungeon.Session ~= Session then
                Dungeon.Session = Session
                Dungeon.Pulled = { }
            end

            local Camera = workspace.CurrentCamera
            local Switches = Map:FindFirstChild("Switchs")

            -- เงื่อนไขเซิร์ฟ (ถอด bytecode Training."Parkour Dungeon".Server 2026-10-01 - decompiler อ่านเวอร์ชันใหม่ไม่ได้):
            --   StateChanged(Switch) นับเมื่อตัวละคร (PrimaryPart) ห่าง Switch:GetPivot() < 20 studs เท่านั้น
            --   Stop = Complete เมื่อ ห่าง Map.Final <= 75 + PulledSwitches ครบทุกอันใน Switchs (นับใน session นี้)
            --   ผ่าน = Hearts +1 (ถ้ายังไม่เต็ม) + TrainingResults(true)
            -- A_.On เป็นแค่ภาพฝั่ง client (ติด On แม้เซิร์ฟไม่นับเพราะยืนไกล) - ใช้ Dungeon.Pulled ที่เราเช็คระยะเองแทน
            local SwitchRange = 14

            local function Pulled(Switch)
                local Handle = Switch:FindFirstChild("A_")
                return Handle and Handle:GetAttribute("On") == true
            end

            local function Counted(Switch)
                if Dungeon.Pulled[Switch] then return true end
                -- เปิดค้างมาก่อนเราเข้ามาคุม (prompt ปิดแล้ว ดึงซ้ำไม่ได้) = ถือว่านับแล้ว
                local Prompt = Switch:FindFirstChildWhichIsA("ProximityPrompt", true)
                return Pulled(Switch) and not (Prompt and Prompt.Enabled)
            end

            local function NearSwitch(Switch)
                local Root = Movement.GetRoot()
                return Root and (Root.Position - Switch:GetPivot().Position).Magnitude < SwitchRange
            end

            -- ดึงตามเลข Switch_1..7 = ลำดับด่านจริง (GetChildren ออกมาสลับ 4,5,6,7,2,1,3 - ต้องวนหลายรอบ
            -- เสียรอบละ ~4 วิต่อคันโยกที่ยังไม่ถึงด่าน)
            local SwitchList = Switches and Switches:GetChildren() or { }
            table.sort(SwitchList, function(A, B)
                return (tonumber(A.Name:match("%d+")) or 0) < (tonumber(B.Name:match("%d+")) or 0)
            end)

            -- ดึงคันโยก 1 อัน: prompt ต้อง "ขึ้น" ก่อน (RequiresLineOfSight + หันกล้องเข้าหา) ถึงจะ hold ติด
            -- บางอันยืนผิดฝั่งแล้วโดนบัง (ยืนยันสด Switch_5: ฝั่ง +Z ไม่ขึ้น ฝั่ง +X ขึ้น) เลยไล่ลองรอบตัว
            -- ยืนห่าง 5 studs ตรึงไว้ด้วย Movement.Lock (ปล่อยเฉย ๆ ตัวไหลไปทับคันโยกจน prompt บังตัวเอง)
            -- ฝั่งที่ Movement.Free ดันออกไปไกลเกิน SwitchRange (ติดกำแพง) = ข้ามไปฝั่งถัดไป ไม่ hold (เซิร์ฟไม่นับ)
            local function TryPull(Switch)
                local Prompt = Switch:FindFirstChildWhichIsA("ProximityPrompt", true)
                if not (Prompt and Prompt.Enabled and Prompt.Parent:IsA("BasePart")) then return false end

                local At = Prompt.Parent.Position
                local Face = At - Switch:GetPivot().Position
                Face = Vector3.new(Face.X, 0, Face.Z)

                local Sides = { }
                if Face.Magnitude > 0.1 then table.insert(Sides, Face.Unit) end
                for _, Side in ipairs({ Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) }) do
                    table.insert(Sides, Side)
                end

                Log("Event", Name, Task, "Pulling " .. Switch.Name)

                for Index, Side in ipairs(Sides) do
                    if Dungeon.Pulled[Switch] then break end
                    if not (Running() and InSession()) then break end

                    local Stand = At + Side * 5 + Vector3.new(0, 1, 0)
                    local View = Stand + Side * 6 + Vector3.new(0, 3, 0)

                    local Shown = false
                    local ShownConnection = Prompt.PromptShown:Connect(function() Shown = true end)
                    Movement.Lock(CFrame.lookAt(Stand, Vector3.new(At.X, Stand.Y, At.Z)))
                    local CameraConnection = RunService.RenderStepped:Connect(function()
                        Camera.CFrame = CFrame.lookAt(View, At)
                    end)

                    task.wait(0.6)
                    -- ฝั่งสุดท้ายลองกดเลยแม้ไม่เห็น event (prompt อาจขึ้นค้างมาจากฝั่งก่อน ไม่ยิง PromptShown ซ้ำ)
                    if (Shown or Index == #Sides) and NearSwitch(Switch) then
                        local WasOn = Pulled(Switch)
                        local Close = true
                        pcall(function() Prompt:InputHoldBegin() end)
                        local Deadline = os.clock() + Prompt.HoldDuration + 0.3
                        while os.clock() < Deadline do
                            if not NearSwitch(Switch) then Close = false end
                            task.wait()
                        end
                        pcall(function() Prompt:InputHoldEnd() end)
                        task.wait(0.4)
                        if Close and Pulled(Switch) and (not WasOn or not Prompt.Enabled) then
                            Dungeon.Pulled[Switch] = true
                        end
                    end

                    ShownConnection:Disconnect()
                    CameraConnection:Disconnect()
                end

                Movement.Lock(nil)
                return Dungeon.Pulled[Switch] == true
            end

            local Stalled = false

            for _ = 1, 6 do
                if not (Running() and InSession()) then break end

                local Left, Gained = 0, 0
                for _, Switch in ipairs(SwitchList) do
                    if not Counted(Switch) and InSession() then
                        Left = Left + 1

                        if TryPull(Switch) then
                            Gained = Gained + 1
                        else
                            -- เรียงตามด่านแล้ว อันนี้ดึงไม่ได้ อันหลังจากนี้ก็ยังไม่เปิดแน่ ๆ - จบรอบ
                            break
                        end
                    end
                end

                if Left == 0 then break end

                -- ไล่ครบรอบแล้วไม่ได้สักอัน = session ค้าง (เริ่มไว้ก่อน inject / client ไม่ได้ผูกคันโยก
                -- prompt ขึ้นแต่ดึงไม่ติด Level ค้าง 1) - ออกจากดันเจี้ยนแล้วเริ่มใหม่รอบหน้า
                if Gained == 0 then
                    Stalled = true
                    break
                end
            end

            if Stalled and InSession() then
                Log("Waiting", Name, Task, "Dungeon session stuck - restarting")
                Dungeon.Fails = Dungeon.Fails + 1
                Dungeon.NextStartAt = os.clock() + 8
                pcall(function() SignalEvent.ToServer("training_signaler", "Stop") end)
                local Deadline = os.clock() + 5
                while os.clock() < Deadline and InSession() do task.wait() end
                task.wait(1)
                return true
            end

            local FinalZone = Map:FindFirstChild("Final")
            if InSession() and FinalZone and FinalZone:IsA("BasePart") then
                local AllPulled = #SwitchList > 0
                for _, Switch in ipairs(SwitchList) do
                    if not Counted(Switch) then AllPulled = false end
                end

                if AllPulled then
                    Log("Event", Name, Task, "All levers pulled - finishing")
                    -- ยืนบนพื้นใต้โซน Final (โซนลอยกลางอากาศ CanCollide ปิด - เดิมตรึงที่กลางโซน Movement.Grounded
                    -- ดึงลงพื้นที่ต่ำกว่า 150 studs = ไกลเกิน 75 เซิร์ฟไม่นับ จบไม่ผ่านแล้ววนเริ่มใหม่)
                    local Center = FinalZone.Position
                    local Params = RaycastParams.new()
                    Params.FilterType = Enum.RaycastFilterType.Exclude
                    Params.FilterDescendantsInstances = { LocalPlayer.Character, workspace:FindFirstChild("Humanoids") }
                    Params.RespectCanCollide = true
                    local Spot = nil
                    for _, Offset in ipairs({ Vector3.zero, Vector3.new(12, 0, 0), Vector3.new(-12, 0, 0), Vector3.new(0, 0, 12), Vector3.new(0, 0, -12) }) do
                        local From = Center + Offset + Vector3.new(0, FinalZone.Size.Y / 2, 0)
                        local Hit = workspace:Raycast(From, Vector3.new(0, -(FinalZone.Size.Y + 60), 0), Params)
                        local Stand = Hit and Hit.Position + Vector3.new(0, 3, 0)
                        if Stand and (Stand - Center).Magnitude <= 60 and not Movement.Blocked(Stand) then
                            Spot = Stand
                            break
                        end
                    end
                    Spot = Spot or Center

                    Movement.Lock(CFrame.new(Spot))
                    -- ยืนในระยะต่อเนื่อง 1.5 วิ (เซิร์ฟเห็นตำแหน่งใหม่) ก่อนยิง Stop - ไม่ถึงภายใน 6 วิ = ไม่ยิง
                    local InRangeSince, Deadline = nil, os.clock() + 6
                    while Running() and InSession() and os.clock() < Deadline do
                        local Root = Movement.GetRoot()
                        if Root and (Root.Position - Center).Magnitude <= 65 then
                            InRangeSince = InRangeSince or os.clock()
                            if os.clock() - InRangeSince >= 1.5 then break end
                        else
                            InRangeSince = nil
                        end
                        task.wait()
                    end

                    -- ยืนในโซนแล้ว client แตะ Final ยิง Stop เอง (ยืนยันสด 2026-10-01: session จบก่อนครบ 1.5 วิ = ผ่าน)
                    local TouchedOut = not InSession() and InRangeSince ~= nil
                    if TouchedOut or (InSession() and InRangeSince and os.clock() - InRangeSince >= 1.5) then
                        -- Touched ของ Final ไม่ติดทุกรอบ (ยืนยันสด: ค้างในโซนไม่จบ) - ยิง Stop เองแบบเดียวกับ Leave ของเกม
                        if InSession() then
                            pcall(function() SignalEvent.ToServer("training_signaler", "Stop") end)
                        end
                        local Wait = os.clock() + 5
                        while os.clock() < Wait and InSession() do task.wait() end

                        Farm.WaitFor(function()
                            local Now = TaskValues(Name, Task)
                            return Now == nil or Now.Value >= 1
                        end, 3, Running)
                        local Value = TaskValues(Name, Task)
                        if Value == nil or Value.Value >= 1 then
                            Log("Event", Name, Task, "Dungeon complete")
                            Dungeon.Fails = 0
                        else
                            Dungeon.Fails = Dungeon.Fails + 1
                            Dungeon.NextStartAt = os.clock() + 8
                            Log("Waiting", Name, Task, "Dungeon not counted (" .. Dungeon.Fails .. "/3)")
                        end
                    else
                        Log("Waiting", Name, Task, "Could not stand within 75 of Final")
                    end
                    Movement.Lock(nil)
                    task.wait(1)
                end
            end

            return true
        end

        return false
    end

    local LastHeld = nil        -- เควสในลูกโซ่ที่ถือล่าสุด - จบแล้ว (หายจาก Holder) = รับ NextQuest ของมันต่อ
    local AddRetryAt = 0
    local StepGapAt = 0         -- event ไม่ติด = เว้นช่วงก่อนยิงซ้ำ (ไม่ยิงทุกเฟรม)

    -- เควสถัดไปที่ต้องรับ: เกมไม่รับให้เอง ตัวเลือกในบทพูดยิง AddQuest(NextQuest) (QuestActions / Yap)
    -- รู้เควสล่าสุด = NextQuest ของมัน / เพิ่ง inject กลางด่าน = ต่อจากเควสล่าสุดที่ Done (LogCompletion)
    local function NextToAdd(Defs)
        if LastHeld and not Held(LastHeld) then
            local Def = Defs.Holder[LastHeld]
            if Def and type(Def.NextQuest) == "string" then return Def.NextQuest end
        end
        for Index = #TrialChain, 1, -1 do
            local Ok, State = pcall(Defs.GetPlayerQuestState, LocalPlayer, TrialChain[Index])
            if Ok and State == "Done" then return TrialChain[Index + 1] end
        end
        return TrialChain[1]
    end

    local function AddQuest(Defs, Quest)
        if os.clock() < AddRetryAt then return end
        Log("Event", Quest, "-", "AddQuest")
        pcall(function() SignalEvent.ToServer("AddQuest", Quest) end)
        if Farm.WaitFor(function() return Held(Quest) ~= nil end, 1.5, Running) then return end

        -- ไม่ติด = ลองไปยืนที่จุดของเควสแล้วยิงซ้ำ (เผื่อเซิร์ฟเช็คระยะ) ไม่ได้อีก = เว้น 2 วิ
        local Def = Defs.Holder[Quest]
        if Def and typeof(Def.Position) == "Vector3" then
            Near(Def.Position)
            pcall(function() SignalEvent.ToServer("AddQuest", Quest) end)
            if Farm.WaitFor(function() return Held(Quest) ~= nil end, 1.5, Running) then return end
        end
        Log("Waiting", Quest, "-", "AddQuest not accepted - retrying")
        AddRetryAt = os.clock() + 2
    end

    -- จบด่าน: บทปิด (Dialogue.FianlSelection "FinalSelectionClosing_*") แจกของตอนแต่ละหน้าโชว์
    -- (OnShow -> SignalEvent.ToServer("FinalSelection_Completion_Helper", Give...)) แล้วหน้าสุดท้าย ClosingDone
    -- = เซิร์ฟส่งกลับ - ยิงเองตามลำดับ ห้ามปิดกล่องทิ้ง (ปิด = ไม่ได้ชุด/แร่/เหล็ก/อีกา)
    local ClosingSent = false
    local function ClaimRewards()
        if ClosingSent then return end
        ClosingSent = true
        for _, Action in ipairs({ "GiveClothing", "GiveOre", "GiveIngot", "GiveCrow", "ClosingDone" }) do
            Log("Event", "Closing", "-", Action)
            pcall(function() SignalEvent.ToServer("FinalSelection_Completion_Helper", Action) end)
            Farm.Sleep(0.6, Running)
        end
    end

    local function Step()
        local Defs = QuestDefs()
        local Finished = LocalPlayer:GetAttribute("TrialEnding") == true
        if not Finished and Defs then
            local Ok, State = pcall(Defs.GetPlayerQuestState, LocalPlayer, "Defeat the Hand Demon")
            Finished = Ok and State == "Done"
        end

        -- บทสนทนาที่เกมเปิดเอง (มาถึงด่าน / NpcNotify) ปิดทิ้ง - ทุกขั้นยิง event ตรงอยู่แล้ว
        -- ยกเว้นตอนจบด่าน (บทปิดแจกของ ดู ClaimRewards)
        if not Finished and DialogueFrame() then CloseDialogue() end

        -- จบด่านแล้ว (ฆ่า Hand Demon = เควสสุดท้าย Done / เซิร์ฟตั้ง TrialEnding รอส่งกลับ) - รับของแล้วรอ
        -- ไม่งั้นลูปเห็นว่าไม่มีเควสในลูกโซ่ แล้วไปรับ Locate Rem เริ่มลูกโซ่ใหม่วนซ้ำ (ยืนยันสดหลังจบด่าน)
        if not Defs then
            Farm.Sleep(1, Running)
            return
        end
        if Finished then
            Movement.Lock(nil)
            Farm.Sleep(1, Running)      -- ให้เซิร์ฟเปิดบทปิดก่อน
            ClaimRewards()
            Log("Done", "-", "-", "Final Selection complete - waiting to be sent back")
            Farm.Sleep(2, Running)
            return
        end

        local Folder = ActiveQuest()
        if not Folder then
            AddQuest(Defs, NextToAdd(Defs))
            return
        end

        local Name = Folder.Name
        LastHeld = Name
        local Def = Defs.Holder[Name]
        local Task, Code = PendingTask(Folder, Def)
        if not Task then
            -- งานครบแล้วแต่เควสยังค้าง = รอเซิร์ฟปิดเควส
            Log("Waiting", Name, "-", "All tasks done - waiting for the quest to close")
            Farm.WaitFor(function() return Held(Name) == nil end, 1, Running)
            return
        end
        if os.clock() < StepGapAt then return end

        local Spec = Def and Def.TaskSpecs and Def.TaskSpecs[Task]

        -- 1. มินิเกม (Checkpoints / Complete Dungeon / Capture the Zone)
        if RunFastMinigame(Name, Task) then
            return
        end

        -- 2. Deliver (คุย NPC / ส่งของ เช่น Treat Klien ต้องถือ Bandage) -> ยิง QuestProgress ตรง
        if Spec and Spec.Type == "Deliver" and Spec.TargetNpc then
            if type(Spec.RequiredItem) == "string" and not Farm.HasItem(Spec.RequiredItem) then
                Log("Running", Name, Task, "Getting " .. Spec.RequiredItem)
                local Ok, Why = GetItem(Spec.RequiredItem)
                if not Ok then
                    Log("Waiting", Name, Task, Why)
                    StepGapAt = os.clock() + 1
                end
                return
            end

            local Ok, Why = EventDeliver(Name, Task, Spec)
            if not Ok then
                Log("Waiting", Name, Task, Why)
                StepGapAt = os.clock() + 1
            end
            return
        end

        -- 3. Pickup (เก็บของตามจุด) -> ยิง QuestProgress พร้อมเลขช่อง
        if Spec and Spec.Type == "Pickup" then
            local Ok, Why = EventPickup(Name, Task, Spec)
            if not Ok then
                Log("Waiting", Name, Task, Why)
                StepGapAt = os.clock() + 1
            end
            return
        end

        -- 4. งานสู้ (Defeat Demons for Vael / Lost / Hand Demon)
        local Ok, Info = Fight(Code or Task, Task)
        if Ok then return end

        -- ยังไม่เห็นเป้า (ยังไม่เกิด / หลุด streaming) - ไปจุดของเควส/task ก่อน ไม่มีก็รอ
        local Marker = Def and Def.Markers and Def.Markers[Task]
        local Point = (Marker and typeof(Marker.Position) == "Vector3" and Marker.Position)
            or (Def and typeof(Def.Position) == "Vector3" and Def.Position) or nil
        if Point then
            Log("Running", Name, Task, "Going to quest point")
            GoTo(Point, 12)
        else
            Log("Waiting", Name, Task, Info)
        end
        StepGapAt = os.clock() + 1
    end

    getgenv().ValkyrieCleanup = function()
        getgenv().ValkyrieSession = nil
        Fighter.Continue = nil
        pcall(Movement.Cancel)

        for _, Connection in ipairs(SessionConnections) do
            pcall(function() Connection:Disconnect() end)
        end
        table.clear(SessionConnections)

        getgenv().ValkyrieCleanup = nil
    end

    print("[Valkyrie Trial] Final Selection place - auto playing")

    task.spawn(function()
        while getgenv().ValkyrieSession == SessionToken do
            if InTrial() then
                local Ok, Error = pcall(Step)
                Fighter.Continue = nil
                if not Ok then
                    Log("Error", "-", "-", Error)
                    Farm.Sleep(1, Running)
                end
            end
            task.wait()
        end
    end)
end

---- ============ Library (Milenium + ตัวครอบ) ============ ----
--
-- ไลบรารีจริงคือ Milenium (UI-Library/Milenium/main.luau - API: library:window -> window:tab ->
-- page:column -> column:section -> section:toggle/slider/dropdown/button/label/paragraph/keybind)
-- ส่วนโค้ดข้างล่างทั้งสคริปต์เขียนด้วย API เดิม (Window:Page / Page:Section / Section:Toggle ... +
-- Library.Flags/SetFlags) เลยครอบชั้นบาง ๆ แปลงให้ แทนที่จะไล่แก้ call site ทั้งไฟล์
--
-- หน้าตา: Page = แท็บ 2 คอลัมน์ (Columns) เลื่อนได้, Section = กล่องสูงตามเนื้อหาไปอยู่คอลัมน์ Side
-- Category = หัวข้อคั่นแท็บใน sidebar, Status / Guide = การ์ด paragraph (แถบสีซ้าย + ข้อความหลายบรรทัด)
--
-- สิ่งที่ไลบรารีนี้ไม่มี ตัวครอบทำเองหมด:
--   Flags / SetFlags  - ทะเบียนตัวตั้งค่าของ element (ใช้ปิด toggle ตัวอื่นเวลาเปิดโหมดใหม่)
--   Status            - การ์ด paragraph + สีแถบตามสถานะ + progress bar เป็นตัวอักษร

local LibraryMilenium, Library = nil, nil

do
    -- getgenv().MileniumSource = ทดสอบด้วยไฟล์ในเครื่อง (dex inject) ไม่ต้องอัปขึ้นเว็บก่อน
    local Ok, Source = pcall(game.HttpGet, game, LibraryUrl, true)
    if type(getgenv().MileniumSource) == "string" then
        Ok, Source = true, getgenv().MileniumSource
    end

    if not (Ok and type(Source) == "string" and #Source > 500) then
        error(string.format(
            "[ValkyrieHub] %s did not return the UI library (%s, %d bytes -- expected 500+)",
            LibraryUrl,
            Ok and "ok" or tostring(Source),
            Ok and #tostring(Source) or 0
        ), 0)
    end

    local Chunk, Err = loadstring(Source)
    if not Chunk then
        error("[ValkyrieHub] UI library did not compile: " .. tostring(Err), 0)
    end

    LibraryMilenium = Chunk()

    if type(LibraryMilenium) ~= "table" then
        error("[ValkyrieHub] UI library ran but returned " .. typeof(LibraryMilenium), 0)
    end

    Library = {
        Milenium = LibraryMilenium,
        Flags = { },        -- [flag] = ค่าปัจจุบัน
        SetFlags = { },     -- [flag] = function(value) ตั้งค่าจากโค้ด (ยิง callback ให้ด้วย)
        StartOn = { },      -- toggle ที่สร้างมาแบบเปิด (ค่าจาก config) ตามลำดับที่สร้าง - ท้ายสคริปต์เริ่มระบบให้
        Window = nil,       -- { selectTab = function(_, index) } ให้โค้ดท้ายไฟล์เรียกเหมือนเดิม
        MileniumWindow = nil,
        Pages = { },
        MinimizeKeybind = nil,
        Visible = true
    }

    -- เปิดให้เรียกจากคอนโซล/สคริปต์อื่นได้ (เช็คสถานะ toggle, สั่งเปิด-ปิดจากนอกสคริปต์)
    getgenv().ValkyrieLibrary = Library

    function Library:SetVisible(Value)
        Library.Visible = Value and true or false

        if Library.MileniumWindow then
            pcall(function() Library.MileniumWindow.toggle_menu(Library.Visible) end)
        end

        -- ให้ปุ่มย่อ (keybind) รู้สถานะล่าสุด ไม่งั้นกดครั้งถัดไปจะสลับกลับทางเดิม = ต้องกดสองที
        if Library.MinimizeKeybind then
            Library.MinimizeKeybind.active = Library.Visible
        end
    end

    function Library:Unload()
        pcall(function() LibraryMilenium:unload_menu() end)
    end

    -- ตัว teardown ตัวเต็มอยู่ท้ายไฟล์ ถ้าโหลดพังกลางทาง (เน็ตหลุด, element ตัวใดตัวหนึ่ง error)
    -- จะไม่ถูกตั้ง แล้วการยิงสคริปต์ซ้ำรอบถัดไปหา ValkyrieCleanup ไม่เจอ -> UI ซ้อนกันสองชุด
    -- ตั้งตัวย่อไว้ก่อนตรงนี้ (มีแค่ทิ้ง UI) ตัวเต็มท้ายไฟล์เขียนทับทีหลัง
    getgenv().ValkyrieCleanup = function()
        getgenv().ValkyrieSession = nil
        pcall(function() Library:Unload() end)
        getgenv().ValkyrieCleanup = nil
    end

    function Library:Notify(Title, Description, Content, Delay)
        pcall(function()
            LibraryMilenium.notifications:create_notification({
                name = Title,
                info = Description or Content or "",
                lifetime = tonumber(Delay) or 5
            })
        end)
    end

    -- ธีมของ Milenium (Milenium, Midnight, Sakura ...) - ค่าเก่าที่เซฟไว้เป็นชื่อธีม Hirimi ("Dark")
    -- ไม่มีในลิสต์ = ใช้ธีมตั้งต้น
    function Library:Themes()
        local List = { }
        for _, Name in ipairs(LibraryMilenium.theme_order or { "Milenium" }) do table.insert(List, Name) end
        return List
    end

    function Library:SetTheme(Name)
        if type(Name) ~= "string" or not (LibraryMilenium.themes and LibraryMilenium.themes[Name]) then return end
        pcall(function() LibraryMilenium:set_theme(Name) end)
    end

    function Library:SetLocale(Name)
        pcall(function() LibraryMilenium:set_language(Name or "en") end)
    end

    function Library:AddLanguage(Name, Translations)
        pcall(function() LibraryMilenium:add_translations(Name, Translations) end)
    end

    local AutoFlag = 0

    local function FlagOf(Value)
        if type(Value) == "string" and Value ~= "" then return Value end

        AutoFlag = AutoFlag + 1
        return "SL2Auto" .. AutoFlag
    end

    local function Register(Flag, Default, Setter)
        if type(Flag) ~= "string" then return end
        Library.Flags[Flag] = Default
        Library.SetFlags[Flag] = Setter
    end

    -- ชื่อไอคอน lucide ที่โค้ดใช้ (ของเดิมให้ Hirimi แปลงเอง) -> asset id (ค่าเดียวกับในตาราง icons ของ Hirimi)
    local LucideIcons = {
        ["anchor"] = "10709761530", ["coins"] = "10709811110", ["puzzle"] = "10734930886",
        ["settings"] = "10734950309", ["shield"] = "10734951847", ["skull"] = "10734962068",
        ["swords"] = "10734975692", ["target"] = "10734977012", ["trending-up"] = "10747363465",
        ["users"] = "10747373426", ["wind"] = "10747382750", ["info"] = "10723415903",
        ["activity"] = "10709752035", ["map-pin"] = "10734886004", ["compass"] = "10709811445",
        ["shirt"] = "10734952036", ["flask-conical"] = "10734883986", ["eye"] = "10723346959",
    }

    local function IconOf(Icon)
        if Icon == nil then return nil end
        Icon = tostring(Icon)
        if Icon:match("^%d+$") then return "rbxassetid://" .. Icon end
        if LucideIcons[Icon] then return "rbxassetid://" .. LucideIcons[Icon] end
        if Icon:find("://", 1, true) then return Icon end
        return nil
    end

    ---- Status card (label + info แบบ Example ของ Milenium: หัวข้อ + ข้อความหลายบรรทัดข้างใต้) ----

    local StateNames = { Idle = true, Running = true, Waiting = true, Done = true, Error = true }

    local function MakeStatus(Item, Data)
        local Rows = Data.Rows or { }
        local Card = {
            Name = Data.Name or "Status",
            State = "Idle",
            Values = { },
            Progress = nil,
            HasProgress = Data.Progress and true or false
        }

        -- Data.Seperator = true -> เส้นใต้การ์ด (label seperator ของ Milenium)
        local Handle = Item:label({ name = Card.Name, info = "...", seperator = Data.Seperator })
        local Title = Handle.items[ "name" ]
        local Info = Handle.items[ "info" ]

        local function Render()
            local Lines = { }

            -- ผู้ใช้ไม่อยากเห็นคำว่า Idle: แถวที่ค่าเป็น Idle ไม่แสดง / หัวการ์ดไม่ต่อท้าย • IDLE
            for _, Key in ipairs(Rows) do
                local Value = Card.Values[Key]
                if Value ~= nil and Value ~= "" and tostring(Value) ~= "Idle" then
                    table.insert(Lines, Key .. ": " .. tostring(Value))
                end
            end

            if Card.HasProgress and Card.Progress then
                local Done, Total = Card.Progress[1], Card.Progress[2]
                local Filled = (Total > 0) and math.clamp(math.floor((Done / Total) * 10 + 0.5), 0, 10) or 0
                table.insert(Lines, string.rep("▰", Filled) .. string.rep("▱", 10 - Filled)
                    .. string.format("  %d/%d", Done, Total))
            end

            if #Lines == 0 then Lines[1] = "-" end

            pcall(function()
                Title.Text = Card.Name      -- ไม่ต่อท้ายสถานะ (• RUNNING / WAITING / ERROR / DONE) ตามที่ผู้ใช้สั่ง
                Info.Text = table.concat(Lines, "\n")
            end)
        end

        function Card:SetState(State)
            Card.State = StateNames[State] and State or "Idle"
            Render()
        end

        function Card:Set(Key, Value)
            Card.Values[Key] = Value
            Render()
        end

        function Card:SetProgress(Done, Total)
            Card.Progress = { tonumber(Done) or 0, tonumber(Total) or 0 }
            Render()
        end

        function Card:SetVisibility(Bool)
            pcall(function() Handle.items[ "label" ].Visible = Bool and true or false end)
        end

        Render()
        return Card
    end

    ---- element ต่าง ๆ (แปลงชื่อ/รูปแบบ config ให้ตรงกับไลบรารี) ----
    --
    -- Milenium ยิง callback ตั้งแต่ตอนสร้าง element (set(default)) = callback ของเรายิงทันทีตั้งแต่โหลด
    -- ซึ่งไม่ใช่พฤติกรรมที่โค้ดเดิมคาด (toggle ที่เซฟไว้ว่าเปิดจะสั่งเริ่มโหมดทันทีตั้งแต่ยังสร้าง UI
    -- ไม่เสร็จ) - กันด้วยการปิดเสียง callback ระหว่างสร้าง แล้วค่อยเปิดตอนสร้างเสร็จ
    local function Gate(Callback)
        local Ready = false

        return function(...)
            if not Ready then return end
            return Callback(...)
        end, function() Ready = true end
    end

    -- ลิสต์ multi เป็น {"a","b"} อยู่แล้ว (ค่าเก่าแบบ {a = true} ก็แปลงให้)
    local function ToList(Value)
        if type(Value) ~= "table" then
            return (Value ~= nil and Value ~= "") and { Value } or { }
        end

        local List = { }
        for Key, Item2 in pairs(Value) do
            if Item2 == true and type(Key) == "string" then
                table.insert(List, Key)
            elseif type(Key) == "number" and type(Item2) == "string" then
                table.insert(List, Item2)
            end
        end

        table.sort(List)
        return List
    end

    -- เรียงตัวอักษรเหมือนของเดิม (Hirimi sort ตัวเลือกเสมอ) - KeepOrder = true ใช้ลำดับที่ส่งมา
    local function Options(List, KeepOrder)
        local Out = { }
        for _, Value in ipairs(List or { }) do table.insert(Out, Value) end
        if not KeepOrder then table.sort(Out, function(A, B) return tostring(A) < tostring(B) end) end
        return Out
    end

    local function MakeSection(Item)
        local Section = { Item = Item }

        function Section:Toggle(Toggle)
            local Flag = FlagOf(Toggle.Flag)
            local Fire, Open = Gate(function(Value)
                Library.Flags[Flag] = Value
                if Toggle.Callback then Toggle.Callback(Value) end
            end)

            local Handle = Item:toggle({
                name = Toggle.Name or "Toggle",
                info = Toggle.Description,
                flag = Flag,
                type = "toggle",
                default = Toggle.Default and true or false,
                seperator = Toggle.Seperator,
                callback = Fire
            })

            Open()

            local Setter = function(Value)
                Handle.enabled = Value and true or false
                Handle.set(Handle.enabled)
            end
            Register(Toggle.Flag, Toggle.Default and true or false, Setter)
            -- เปิดค้างจาก config = จดไว้ ท้ายสคริปต์ยิง callback ให้ (Gate ไม่ยิงตอนสร้าง = โชว์เปิดแต่ระบบไม่เริ่ม)
            if Toggle.Default and type(Toggle.Flag) == "string" then
                table.insert(Library.StartOn, Toggle.Flag)
            end

            Handle.setValue = function(_, Value) Setter(Value) end
            return Handle
        end

        function Section:Slider(Slider)
            local Flag = FlagOf(Slider.Flag)
            local Fire, Open = Gate(function(Value)
                Library.Flags[Flag] = Value
                if Slider.Callback then Slider.Callback(Value) end
            end)

            local Handle = Item:slider({
                name = Slider.Name or "Slider",
                info = Slider.Description,
                flag = Flag,
                min = Slider.Min or 0,
                max = Slider.Max or 100,
                interval = Slider.Decimals or 1,
                default = Slider.Default or Slider.Min or 0,
                suffix = Slider.Suffix or "",
                seperator = Slider.Seperator,
                callback = Fire
            })

            Open()

            Register(Slider.Flag, Slider.Default, function(Value)
                Handle.set(tonumber(Value) or 0)
            end)

            Handle.setValue = function(_, Value) Handle.set(tonumber(Value) or 0) end
            return Handle
        end

        function Section:Dropdown(Dropdown)
            local Multi = Dropdown.Multi and true or false
            local Flag = FlagOf(Dropdown.Flag)

            local Fire, Open = Gate(function(Value)
                local Out = Multi and ToList(Value) or Value
                Library.Flags[Flag] = Out
                if Dropdown.Callback and Out ~= nil then Dropdown.Callback(Out) end
            end)

            local Handle = Item:dropdown({
                name = Dropdown.Name or "Dropdown",
                info = Dropdown.Description,
                flag = Flag,
                items = Options(Dropdown.Items, Dropdown.KeepOrder),
                multi = Multi,
                default = Multi and ToList(Dropdown.Default) or (Dropdown.Default or ""),
                seperator = Dropdown.Seperator,
                callback = Fire
            })

            Open()

            local function SetValue(Value)
                Handle.set(Multi and ToList(Value) or Value)
            end

            Register(Dropdown.Flag, Multi and ToList(Dropdown.Default) or Dropdown.Default, SetValue)

            Handle.setValue = function(_, Value) SetValue(Value) end

            -- โค้ดเดิมเรียก :Refresh(รายการใหม่, ค่าที่เลือก)
            function Handle:Refresh(List, Selected)
                Handle.refresh_options(Options(List, Dropdown.KeepOrder))
                SetValue(Selected)
            end

            return Handle
        end

        -- Colorpicker: Callback(Color3, Alpha) - Default = Color3
        function Section:Colorpicker(Picker)
            local Flag = FlagOf(Picker.Flag)
            local Fire, Open = Gate(function(Color, Alpha)
                Library.Flags[Flag] = Color
                if Picker.Callback then Picker.Callback(Color, Alpha) end
            end)

            local Handle = Item:colorpicker({
                name = Picker.Name or "Color",
                flag = Flag,
                color = Picker.Default or Color3.new(1, 1, 1),
                seperator = Picker.Seperator,
                callback = Fire
            })

            Open()
            return Handle
        end

        function Section:Button(Button)
            return Item:button({
                name = Button.Name or "Button",
                callback = Button.Callback or function() end
            })
        end

        -- เส้นใต้ element (Seperator): Toggle/Label ค่าเริ่มไม่มี, Slider/Dropdown ค่าเริ่มมี - ส่ง true/false ทับได้
        -- เช่น Section:Toggle({ ..., Seperator = true }) / Section:Dropdown({ ..., Seperator = false })
        function Section:Label(Text, Seperator)
            local Handle = Item:label({ name = tostring(Text), seperator = Seperator })

            return {
                SetText = function(_, Value)
                    pcall(function() Handle.items[ "name" ].Text = tostring(Value) end)
                end,
                -- ข้อความใส่สีได้ (<font color="#..">) - ฟอนต์กว้างไม่เท่ากัน ใช้สีแทนป้าย [Done]/[ -- ] ให้ชื่อตรงกัน
                SetRichText = function(_, Value)
                    pcall(function()
                        Handle.items[ "name" ].RichText = true
                        Handle.items[ "name" ].Text = tostring(Value)
                    end)
                end
            }
        end

        -- เส้นคั่นในกล่อง: Divider() = เส้นเปล่า / Divider("หัวข้อ") = หัวข้อ + เส้นใต้
        -- (หัวข้อใช้ label({ seperator = true }) ของ Milenium - เส้นเปล่าสร้าง Frame สูง 1 สีเดียวกัน)
        function Section:Divider(Text)
            if Text ~= nil then
                local Handle = Item:label({ name = tostring(Text), seperator = true })
                return {
                    SetText = function(_, Value)
                        pcall(function() Handle.items[ "name" ].Text = tostring(Value) end)
                    end
                }
            end

            local Line = LibraryMilenium:create("Frame", {
                Parent = Item.items[ "elements" ],
                Name = "\0",
                Size = UDim2.new(1, 1, 0, 1),
                BorderSizePixel = 0,
                BackgroundColor3 = Color3.fromRGB(36, 36, 37)
            })
            return { SetVisible = function(_, Value) Line.Visible = Value end }
        end

        -- ช่องพิมพ์ข้อความ (textbox ของ Milenium ขึ้นบนสุดของกล่องเสมอ - LayoutOrder -1)
        function Section:Textbox(Box)
            return Item:textbox({
                name = Box.Name or "TextBox",
                placeholder = Box.Placeholder,
                default = Box.Default or "",
                flag = FlagOf(Box.Flag),
                callback = function(Text)
                    if Box.Callback then Box.Callback(Text) end
                end
            })
        end

        function Section:Status(Data)
            return MakeStatus(Item, Data or { })
        end

        -- การ์ดวิธีใช้ (ข้อความนิ่ง ไม่มีสถานะ/ค่าล่าสุด)
        -- แปลทีละบรรทัด (ข้อความรวมหลายบรรทัดไม่ตรงคีย์ในพจนานุกรม) + เปลี่ยนตามภาษาที่เลือกทีหลัง
        function Section:Guide(Title, Steps)
            Title = Title or "How to use"
            local function Tr(Text)
                local Ok, Out = pcall(function() return LibraryMilenium:translate(Text) end)
                return Ok and type(Out) == "string" and Out or Text
            end
            local function Info()
                local Lines = { }
                for Index, Step in ipairs(Steps or { }) do
                    table.insert(Lines, string.format("%d. %s", Index, Tr(Step)))
                end
                return table.concat(Lines, "\n")
            end
            local Handle = Item:label({ name = Tr(Title), info = Info() })
            local Items = type(Handle) == "table" and Handle.items
            local function Apply()
                pcall(function()
                    if Items.name then Items.name.Text = Tr(Title) end
                    if Items.info then Items.info.Text = Info() end
                end)
            end
            if Items and type(LibraryMilenium.language_callbacks) == "table" then
                table.insert(LibraryMilenium.language_callbacks, Apply)
                pcall(function() LibraryMilenium:no_translate(Items.name) end)
                pcall(function() LibraryMilenium:no_translate(Items.info) end)
            end
            return Handle
        end

        -- keybind ของ Milenium: กดที่ช่องแล้วกดคีย์ใหม่ = เปลี่ยนคีย์, กดคีย์ = ซ่อน/โชว์หน้าต่าง
        -- (โหมด Toggle - active = หน้าต่างเปิดอยู่) คีย์ใหม่ส่งให้ Callback เหมือนของเดิม
        function Section:Keybind(Keybind)
            local Key = Keybind.Default
            if typeof(Key) ~= "EnumItem" then Key = Enum.KeyCode.End end
            local Flag = FlagOf(Keybind.Flag)

            local Handle
            Handle = Item:keybind({
                name = Keybind.Name or "Keybind",
                flag = Flag,
                key = Key,
                mode = "Toggle",
                default = true,
                callback = function(Active)
                    if Handle then Library:SetVisible(Active) end

                    -- flags อัปเดตหลัง callback - อ่านคีย์ใหม่เฟรมถัดไป
                    task.defer(function()
                        local Now = Handle and Handle.key
                        if typeof(Now) == "EnumItem" and Now ~= Key then
                            Key = Now
                            Library.Flags[Flag] = { Key = tostring(Key) }
                            if Keybind.Callback then Keybind.Callback(Key) end
                        end
                    end)
                end
            })

            Library.MinimizeKeybind = Handle
            Register(Keybind.Flag, { Key = tostring(Key) }, function() end)

            return Handle
        end

        return Section
    end

    function Library:Window(Data)
        local Bind = Enum.KeyCode[getgenv().ConfigurationTable.MinimizeBind or "End"] or Enum.KeyCode.End

        -- rbxthumb:// เรนเดอร์ instant ไม่ต้องรอ GetUserThumbnailAsync - รูปหัวผู้เล่นมุมซ้ายล่างแบบ Hirimi
        -- ชื่อซ่อนไว้ (สคริปต์โกงไม่อยากให้ชื่อจริงติดสกรีนช็อต) เหลือแค่รูปหัว
        local Avatar = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", LocalPlayer.UserId)

        local WindowMilenium = LibraryMilenium:window({
            name = "Valkyrie",
            suffix = " Hub",
            gameInfo = "Ouwland",
            info_text = "@velkyriehub",
            profile = { avatar = Avatar, name = "Hidden", desc = "@velkyriehub" },
            search_placeholder = "Search...",
        })

        Library.MileniumWindow = WindowMilenium

        -- ธีมตั้งต้น = Midnight - ค่าที่เซฟไว้ไม่ใช่ธีมของ Milenium (เช่น "Dark" สมัย Hirimi) ก็ใช้ Midnight
        local Config = getgenv().ConfigurationTable
        if not (type(Config.Theme) == "string" and LibraryMilenium.themes and LibraryMilenium.themes[Config.Theme]) then
            Config.Theme = "Midnight"
        end
        Library:SetTheme(Config.Theme)

        -- ตัวท้ายไฟล์เรียก Library.Window:selectTab(1) (index นับรวมทุกหมวด ตัวแรกที่สร้าง = 1)
        Library.Window = {
            keybind = Bind,
            selectTab = function(_, Index)
                local Page = Library.Pages[Index]
                if Page and Page.open_tab then Page.open_tab() end
            end
        }

        local Window = { Milenium = WindowMilenium }

        -- หมวดคั่นแท็บใน sidebar (General / Settings)
        function Window:Category(Name)
            WindowMilenium:seperator({ name = Name or "General" })
        end

        function Window:SetTransparency() end

        function Window:Page(Page)
            local Tab = WindowMilenium:tab({
                name = Page.Name or "Tab",
                icon = IconOf(Page.Icon) or "rbxassetid://10734950309",
            })
            table.insert(Library.Pages, Tab)

            -- แบบ Example อันที่ 4 ของ Milenium: section ซ้อนกันในคอลัมน์ - คอลัมน์ละ Side (Columns ช่อง ของเดิม 2)
            -- คอลัมน์เป็น ScrollingFrame: พื้นที่พอ = ทุกกล่องได้เท่าที่ใช้ แล้วแบ่งที่เหลือเท่า ๆ กัน (กล่องเต็ม
            -- คอลัมน์ ไม่เว้นว่างโหรง) / ไม่พอ = ทุกกล่องสูงเต็มเนื้อหา (ไม่บีบ) แล้วเลื่อนทั้งคอลัมน์แทน
            -- คิดใหม่ทุกครั้งที่เนื้อหาหรือขนาดคอลัมน์เปลี่ยน (padding ล่าง 10, ช่องไฟระหว่างกล่อง 10)
            local Columns, Stacks = { }, { }

            local function Restack(Index)
                local Stack = Stacks[Index]
                local Column = Columns[Index].items[ "column" ]
                local Count = #Stack
                if Count == 0 then return end

                -- AbsoluteSize โดน UIScale ของหน้าต่างคูณแล้ว - Size ต้องใส่หน่วยก่อน scale: เทียบจาก
                -- หัวกล่อง (สูง 28 ตายตัว)
                local Ratio = Stack[1].items[ "button" ].AbsoluteSize.Y / 28
                if Ratio <= 0 then return end

                local Full = Column.AbsoluteSize.Y / Ratio - 10
                local Avail = Full - 10 * (Count - 1)

                local Needs, Total = { }, 0
                for I, Box in ipairs(Stack) do
                    -- กรอบ 2 + หัวกล่อง 28 + ช่องล่าง 5 (scrolling สูง -33) + ระยะขอบบน 10 + รายการ (รวม padding
                    -- ล่างของมันแล้ว) = รายการ + 45
                    local Need = math.max(math.ceil(Box.items[ "elements" ].AbsoluteSize.Y / Ratio) + 45, 70)
                    Needs[I] = Need
                    Total = Total + Need
                end

                local Spare = math.max(Avail - Total, 0) / Count
                for I, Box in ipairs(Stack) do
                    Box.items[ "outline" ].Size = UDim2.new(0, 0, 0, math.floor(Needs[I] + Spare))
                end
            end

            local Queued = { }
            local function QueueRestack(Index)
                if Queued[Index] then return end
                Queued[Index] = true
                task.defer(function()
                    Queued[Index] = false
                    pcall(Restack, Index)
                end)
            end

            -- คอลัมน์ว่างซ่อนไว้ (โผล่ตอนมี section แรก) - หน้าที่มี section เดียว = คอลัมน์เดียวเต็มหน้า
            -- แบบ Hirimi (list layout ของหน้าเป็น Fill คอลัมน์ที่เหลือขยายเต็มเอง)
            for Index = 1, math.max(tonumber(Page.Columns) or 1, 1) do
                Columns[Index] = Tab:column({ scroll = true })
                -- แถบเลื่อนล่องหน (ยังเลื่อนด้วยล้อเมาส์/ลากนิ้วได้ปกติ)
                Columns[Index].items[ "column" ].ScrollBarThickness = 0
                Columns[Index].items[ "column" ].ScrollBarImageTransparency = 1
                Columns[Index].items[ "column" ].Visible = false
                Stacks[Index] = { }

                local ColumnIndex = Index
                Columns[Index].items[ "column" ]:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                    QueueRestack(ColumnIndex)
                end)
            end

            local Object = { Tab = Tab, Columns = Columns }

            function Object:Section(Data2)
                local Side = math.clamp(tonumber(Data2.Side) or 1, 1, #Columns)
                local Box = Columns[Side]:section({
                    name = Data2.Name or "Section",
                    icon = IconOf(Data2.Icon) or "rbxassetid://10723415903",
                    default = true,
                    size = 1
                })

                Box.items[ "scrolling" ].ScrollBarThickness = 0
                Box.items[ "scrolling" ].ScrollBarImageTransparency = 1
                table.insert(Stacks[Side], Box)
                Columns[Side].items[ "column" ].Visible = true
                Box.items[ "elements" ]:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                    QueueRestack(Side)
                end)
                QueueRestack(Side)

                return MakeSection(Box)
            end

            return Object
        end

        return Window
    end
end

local LocaleByLanguage = {
    ["English (US)"] = "en",
    ["Thai"] = "th"
}

local function ApplyLanguage(Name)
    Library:SetLocale(LocaleByLanguage[Name] or "en")
end

-- คำแปลไทยของ UI ทั้งหมด (ผู้ใช้ 2026-10-02) - Milenium จำข้อความอังกฤษเดิมแล้วสลับตามภาษาที่เลือก
-- ข้อความที่เปลี่ยนตอนรัน (สถานะ / ค่า) ไม่แปล / ชื่อในเกม (NPC ไอเทม บอส) คงภาษาอังกฤษ
Library:AddLanguage("th", {
    ["Select Mob"] = "เลือกมอน",
    ["Select Boss"] = "เลือกบอส",
    ["Select Zone"] = "เลือกโซน",
    ["Select NPC"] = "เลือก NPC",
    ["Select Shrine"] = "เลือกศาลเจ้า",
    ["Teleport to Zone"] = "วาร์ปไปโซน",
    ["Teleport to NPC"] = "วาร์ปไปหา NPC",
    ["Teleport to Shrine"] = "วาร์ปไปศาลเจ้า",
    ["ESP Players"] = "ESP ผู้เล่น",
    ["ESP Mobs"] = "ESP มอน",
    ["ESP Bosses"] = "ESP บอส",
    ["ESP NPCs"] = "ESP NPC",
    ["ESP Chests & Loot"] = "ESP กล่องและของดรอป",
    ["ESP Sealed Caches"] = "ESP กล่อง Sealed Cache",
    ["ESP Boss Spawns"] = "ESP จุดเกิดบอส",
    ["No boss selected"] = "ยังไม่ได้เลือกบอส",
    ["No mob selected"] = "ยังไม่ได้เลือกมอน",
    ["0 is auto (the skill's own timing)"] = "0 คืออัตโนมัติ (ตามจังหวะของสกิล)",
    ["1st"] = "อันดับ 1",
    ["2nd"] = "อันดับ 2",
    ["3rd"] = "อันดับ 3",
    ["4th"] = "อันดับ 4",
    ["5th"] = "อันดับ 5",
    ["6th"] = "อันดับ 6",
    ["7th"] = "อันดับ 7",
    ["8th"] = "อันดับ 8",
    ["After a run, buy the item below with tower points until you can't"] = "จบรอบแล้วใช้แต้มหอซื้อไอเทมด้านล่างจนหมด",
    ["After exchanging, step on the Leave pad to go back"] = "แลกเสร็จแล้วเดินเข้าแผ่น Leave เพื่อกลับ",
    ["Aim At"] = "เล็งที่",
    ["Aim From"] = "เล็งจาก",
    ["Aim Part"] = "ส่วนที่เล็ง",
    ["Also parries skills, not just normal hits"] = "ปัดสกิลด้วย ไม่ใช่แค่หมัดธรรมดา",
    ["Always Run"] = "วิ่งตลอด",
    ["Anti Knockback"] = "กันกระเด็น",
    ["Anti Stun"] = "กันสตัน",
    ["Anti-AFK"] = "กัน AFK",
    ["Auto"] = "อัตโนมัติ",
    ["Auto is the mouse on PC and the screen center on mobile"] = "อัตโนมัติคือเมาส์บน PC และกลางจอบนมือถือ",
    ["Auto Accept Quest"] = "รับเควสอัตโนมัติ",
    ["Auto Best Card"] = "เลือกการ์ดดีสุดอัตโนมัติ",
    ["Auto Best Title"] = "ใส่ Title ดีสุดอัตโนมัติ",
    ["Auto Boss Hunt"] = "ล่าบอสอัตโนมัติ (Boss Hunt)",
    ["Auto Breathing"] = "ฝึกปราณอัตโนมัติ",
    ["Auto Buy Bait"] = "ซื้อเหยื่ออัตโนมัติ",
    ["Auto Buy Bait is optional"] = "ซื้อเหยื่ออัตโนมัติ จะเปิดหรือไม่ก็ได้",
    ["Auto Buy Potion"] = "ซื้อยาอัตโนมัติ",
    ["Auto Climb"] = "ปีนหออัตโนมัติ",
    ["Auto Collect Chest"] = "เก็บกล่องอัตโนมัติ",
    ["Auto Dodge"] = "หลบอัตโนมัติ",
    ["Auto Drink Potion"] = "ดื่มยาอัตโนมัติ",
    ["Auto Equip Best"] = "ใส่ของดีสุดอัตโนมัติ",
    ["Auto Equip Best Weapon"] = "ใส่อาวุธดีสุดอัตโนมัติ",
    ["Auto Exchange"] = "แลกของอัตโนมัติ",
    ["Auto Executor"] = "รันอัตโนมัติ (Auto Execute)",
    ["Auto Farm Boss"] = "ฟาร์มบอสอัตโนมัติ",
    ["Auto Farm Level"] = "ฟาร์มเลเวลอัตโนมัติ",
    ["Auto Farm Mob"] = "ฟาร์มมอนอัตโนมัติ",
    ["Auto Final Selection"] = "ลง Final Selection อัตโนมัติ",
    ["Auto Fishing"] = "ตกปลาอัตโนมัติ",
    ["Auto Fishing Status"] = "สถานะตกปลาอัตโนมัติ",
    ["Auto Leave"] = "ออกอัตโนมัติ",
    ["Auto Parry"] = "ปัดป้องอัตโนมัติ",
    ["Auto Puzzle"] = "ไขปริศนาอัตโนมัติ",
    ["Auto Quest Jewelry Box"] = "เควสกล่องเครื่องประดับอัตโนมัติ",
    ["Auto Quest Shiori"] = "เควส Shiori อัตโนมัติ",
    ["Auto Raid Sealed Cache"] = "ลุยแคมป์ Sealed Cache อัตโนมัติ",
    ["Auto Region Discovery"] = "สำรวจพื้นที่อัตโนมัติ",
    ["Auto Rejoin"] = "เข้าเซิร์ฟใหม่อัตโนมัติ",
    ["Auto Reroll"] = "Reroll อัตโนมัติ",
    ["Auto Sell"] = "ขายของอัตโนมัติ",
    ["Auto Sell / Buy Potions above a farm are done between kills when due"] = "ขายของ / ซื้อยา ที่อยู่สูงกว่าฟาร์ม จะแวะทำระหว่างตัวเมื่อถึงรอบ",
    ["Auto Server Hop"] = "ย้ายเซิร์ฟอัตโนมัติ",
    ["Auto Skill"] = "ใช้สกิลอัตโนมัติ",
    ["Auto Unlock Fishing"] = "ปลดล็อกตกปลาอัตโนมัติ",
    ["Auto Unlock Puzzle"] = "ปลดล็อกปริศนาอัตโนมัติ",
    ["Auto Upgrade Rod"] = "อัปเกรดเบ็ดอัตโนมัติ",
    ["Auto Upgrade Skill Tree"] = "อัปสกิลทรีอัตโนมัติ",
    ["Auto Use Skill"] = "ใช้สกิลอัตโนมัติ",
    ["Auto follows the stats you levelled in the skill tree"] = "อัตโนมัติคือตามสายที่อัปในสกิลทรี",
    ["Bait"] = "เหยื่อ",
    ["Best Card"] = "การ์ดดีสุด",
    ["Best Equipment"] = "อุปกรณ์ดีสุด",
    ["Best M1 Weapon"] = "อาวุธ M1 แรงสุด",
    ["Blocks right as an attack lands (perfect block) - learns each attacker's moves and timing"] = "กันตอนโดนตีพอดี (perfect block) - เรียนท่าและจังหวะของศัตรูแต่ละตัว",
    ["Body"] = "ลำตัว",
    ["Boss Hunt"] = "ล่าบอส (Boss Hunt)",
    ["Boss Hunts open here (ReplicatedStorage.BossHunts)"] = "Boss Hunt ที่เปิดในเซิร์ฟนี้",
    ["Boss Spawns"] = "จุดเกิดบอส",
    ["Boss adds only (e.g. Rogue Demon) - quest targets always take a normal kill so the quest counts"] = "เฉพาะลูกน้องบอส (เช่น Rogue Demon) - ตัวเป้าเควสตีปกติเสมอเพื่อให้เควสนับ",
    ["Bosses"] = "บอส",
    ["Bottom"] = "ล่าง",
    ["Box"] = "กล่อง",
    ["Box Style"] = "แบบกล่อง",
    ["Breathing"] = "ปราณ",
    ["Breathing Settings"] = "ตั้งค่าปราณ",
    ["Buy Amount"] = "จำนวนที่ซื้อ",
    ["Buy Potions"] = "ซื้อยา",
    ["Buy potions you run out of from a shop in this place"] = "ซื้อยาที่หมดจากร้านในแมพนี้",
    ["Buys bait when it runs out"] = "ซื้อเหยื่อเมื่อหมด",
    ["Camera Lock"] = "ล็อกกล้อง",
    ["Card values from the game's own weights"] = "คิดค่าการ์ดจากโอกาสจริงของเกม",
    ["Catches"] = "ปลาที่ได้",
    ["Center"] = "กลาง",
    ["Chams Transparency"] = "ความโปร่งใส Chams",
    ["Change Language"] = "เปลี่ยนภาษา",
    ["Chests & Loot"] = "กล่องและของดรอป",
    ["Chests and loot drops"] = "กล่องและของที่ดรอป",
    ["Clear camp guards · open caches"] = "เคลียร์ยามแคมป์ · เปิดกล่อง",
    ["Collect Radius"] = "ระยะเก็บของ",
    ["Color"] = "สี",
    ["Combat"] = "ต่อสู้",
    ["Configuration"] = "การตั้งค่า",
    ["Copy Current JobId"] = "คัดลอก JobId ปัจจุบัน",
    ["Corners"] = "มุม",
    ["Custom FOV"] = "FOV กำหนดเอง",
    ["Dash, stamina, stun and sun"] = "แดช, สตามินา, สตัน และแดด",
    ["Delete Waypoint"] = "ลบจุดวาร์ป",
    ["Detail"] = "รายละเอียด",
    ["Discovered regions (Archives)"] = "พื้นที่ที่สำรวจแล้ว (Archives)",
    ["Distance"] = "ระยะ",
    ["Drink At Health"] = "ดื่มเมื่อเลือดเหลือ",
    ["Drink At Stamina"] = "ดื่มเมื่อสตามินาเหลือ",
    ["Drink potions when health or stamina is low"] = "ดื่มยาเมื่อเลือดหรือสตามินาต่ำ",
    ["ESP Settings"] = "ตั้งค่า ESP",
    ["Enemy Range"] = "ระยะศัตรู",
    ["Enemy Range: cast only when the target is within this distance"] = "ระยะศัตรู: ใช้สกิลเมื่อเป้าอยู่ในระยะนี้เท่านั้น",
    ["Equip Best Now"] = "ใส่ของดีสุดตอนนี้",
    ["Equipment"] = "อุปกรณ์",
    ["Every skill you use aims at the target closest to your aim point inside the FOV circle"] = "ทุกสกิลเล็งไปที่เป้าที่ใกล้จุดเล็งที่สุดในวง FOV",
    ["FOV Radius"] = "รัศมี FOV",
    ["FPS Lock"] = "ล็อก FPS",
    ["FPS Value"] = "ค่า FPS",
    ["Farm Boss"] = "ฟาร์มบอส",
    ["Farm Level"] = "ฟาร์มเลเวล",
    ["Farm Mob"] = "ฟาร์มมอน",
    ["Farm Priority"] = "ลำดับการฟาร์ม",
    ["Farm a chosen boss"] = "ฟาร์มบอสที่เลือก",
    ["Farm a chosen mob"] = "ฟาร์มมอนที่เลือก",
    ["Farm until max level"] = "ฟาร์มจนเลเวลตัน",
    ["Field of View"] = "มุมมองกล้อง (FOV)",
    ["Fish nonstop with your best rod"] = "ตกปลาไม่หยุดด้วยเบ็ดที่ดีที่สุด",
    ["Fishing"] = "ตกปลา",
    ["Fishing Spot"] = "จุดตกปลา",
    ["Fishing Status"] = "สถานะตกปลา",
    ["Flies to each missing region until it is discovered, then flies back. Uses Travel settings. No in-game reward, it fills Archives and the map"] = "บินไปพื้นที่ที่ยังไม่สำรวจจนครบแล้วบินกลับ ใช้ตั้งค่า Travel ไม่มีของรางวัล แค่เติม Archives และแผนที่",
    ["Floor"] = "ชั้น",
    ["Fly away when a boss or mob starts a skill, return when it ends"] = "หลบออกเมื่อบอส/มอนเริ่มใช้สกิล แล้วกลับมาเมื่อท่าจบ",
    ["Fly to Ginzo and sell the list once"] = "บินไปหา Ginzo แล้วขายตามลิสต์หนึ่งครั้ง",
    ["Forget Learned Moves"] = "ลืมท่าที่เรียนไว้",
    ["Framerate and screen"] = "เฟรมเรตและหน้าจอ",
    ["Fullbright"] = "สว่างเต็มที่",
    ["Gear"] = "อุปกรณ์",
    ["Get the permit, then upgrade your rod"] = "รับใบอนุญาต แล้วอัปเกรดเบ็ด",
    ["Ginzo Quest"] = "เควส Ginzo",
    ["Head"] = "หัว",
    ["Hearts"] = "หัวใจ",
    ["Hidden"] = "ซ่อน",
    ["Hold Timing"] = "เวลากดค้าง",
    ["Hold sliders: seconds to hold each key (0 is the skill's own timing)"] = "สไลเดอร์กดค้าง: วินาทีที่กดค้างแต่ละปุ่ม (0 คือตามจังหวะของสกิล)",
    ["Hop Server (Random)"] = "ย้ายเซิร์ฟ (สุ่ม)",
    ["Hop Smallest Server"] = "ย้ายไปเซิร์ฟคนน้อยสุด",
    ["Hop servers until one has the Boss Hunt you want"] = "ย้ายเซิร์ฟจนเจอ Boss Hunt ที่ต้องการ",
    ["Hop to Target Players"] = "ย้ายไปเซิร์ฟผู้เล่นเป้าหมาย",
    ["Hop until a server has a matching Boss Hunt, then stop"] = "ย้ายเซิร์ฟจนเจอ Boss Hunt ที่ตรง แล้วหยุด",
    ["How long each key is held"] = "เวลากดค้างของแต่ละปุ่ม",
    ["How to use"] = "วิธีใช้",
    ["Hunt Side"] = "ฝั่ง Hunt",
    ["Hunt Tier"] = "ระดับ Hunt",
    ["Idle"] = "ว่าง",
    ["Ignore Idle NPCs"] = "ไม่สน NPC ที่ไม่ได้ตามเรา",
    ["Infinite Climb"] = "ปีนไม่จำกัด",
    ["Infinite Dash"] = "แดชไม่จำกัด",
    ["Infinite Jump"] = "กระโดดไม่จำกัด",
    ["Infinite Stamina"] = "สตามินาไม่จำกัด",
    ["Instant Kill"] = "ฆ่าทันที",
    ["Instant Kill At Health"] = "ฆ่าทันทีเมื่อเลือดเหลือ",
    ["Interface"] = "หน้าตา",
    ["It checks this server first; if no hunt matches, it joins a random unvisited server with room"] = "เช็คเซิร์ฟนี้ก่อน ถ้าไม่มี Hunt ที่ตรง จะเข้าเซิร์ฟสุ่มที่ยังไม่เคยไปและยังมีที่ว่าง",
    ["Item"] = "ไอเทม",
    ["Jewelry Box quest (Lv 45+, one time)"] = "เควสกล่องเครื่องประดับ (Lv 45+, ครั้งเดียว)",
    ["Join JobId"] = "เข้าด้วย JobId",
    ["Join by JobId"] = "เข้าเซิร์ฟด้วย JobId",
    ["Jump Power"] = "แรงกระโดด",
    ["Keep Equipped"] = "ไม่ขายของที่ใส่อยู่",
    ["Keep Equipped: when on, it never sells your toolbar weapons or worn outfit"] = "ไม่ขายของที่ใส่อยู่: เมื่อเปิด จะไม่ขายอาวุธใน Toolbar และชุดที่ใส่",
    ["Keep Reroll Tickets"] = "เก็บตั๋ว Reroll ไว้",
    ["Keep the camera on the target"] = "ให้กล้องจับเป้าไว้",
    ["Keeps the best 5 stat items on, re-checks when you get new equipment"] = "ใส่ของค่าดีสุด 5 ชิ้น เช็คใหม่เมื่อได้ของใหม่",
    ["Kill a tower enemy once your hit makes you its owner"] = "ฆ่าศัตรูในหอทันทีเมื่อตีโดนจนเป็นเจ้าของ",
    ["Kill camp guards instantly after the first hit (they drop nothing)"] = "ฆ่ายามแคมป์ทันทีหลังตีครั้งแรก (ไม่ดรอปของ)",
    ["Language"] = "ภาษา",
    ["Last Catch"] = "ตัวล่าสุด",
    ["Leads moving targets by this much time"] = "ยิงดักหน้าเป้าที่เคลื่อนที่ตามเวลานี้",
    ["Learn any breathing style automatically"] = "เรียนปราณแบบไหนก็ได้อัตโนมัติ",
    ["Lighting and camera"] = "แสงและกล้อง",
    ["Loaded - have fun"] = "โหลดเสร็จแล้ว - ขอให้สนุก",
    ["Lock Key"] = "ปุ่มล็อก",
    ["Lower is smoother, 100 is an instant snap"] = "ยิ่งต่ำยิ่งนุ่มนวล, 100 คือล็อกทันที",
    ["Lv 45+: accept from Ginzo, pick up the box, return it (240 Wen + 2700 Exp, once)"] = "Lv 45+: รับเควสจาก Ginzo เก็บกล่อง แล้วนำส่ง (240 Wen + 2700 Exp ครั้งเดียว)",
    ["M1 Range"] = "ระยะ M1",
    ["Max Distance"] = "ระยะสูงสุด",
    ["Method"] = "ตำแหน่งยืน",
    ["Min Time Left"] = "เวลาเหลือขั้นต่ำ",
    ["Minimize Bind"] = "ปุ่มย่อหน้าต่าง",
    ["Misc"] = "อื่นๆ",
    ["Mobs"] = "มอน",
    ["Mode"] = "โหมด",
    ["Mouse"] = "เมาส์",
    ["Move to another server right now"] = "ย้ายไปเซิร์ฟอื่นทันที",
    ["Movement"] = "การเคลื่อนที่",
    ["NPCs further than 10 studs only count when they are after you (players always count)"] = "NPC ที่ไกลกว่า 10 studs นับเฉพาะตัวที่ตามเรา (ผู้เล่นนับเสมอ)",
    ["Name, health and distance of the current target under the circle"] = "ชื่อ เลือด และระยะของเป้าใต้วงกลม",
    ["Need Lv 45+ and some Wen"] = "ต้องเลเวล 45+ และมี Wen",
    ["Needs the Fishing Permit and a rod"] = "ต้องมีใบอนุญาตตกปลาและเบ็ด",
    ["Never sell items in toolbar or worn outfit"] = "ไม่ขายของใน Toolbar หรือชุดที่ใส่",
    ["Next"] = "ถัดไป",
    ["No Fog"] = "ไม่มีหมอก",
    ["No Sun Damage"] = "ไม่โดนแดดเผา",
    ["Noclip"] = "ทะลุกำแพง",
    ["None"] = "ไม่มี",
    ["If there is nothing to do right now (no hunt, boss on cooldown), it does the next one, then comes back"] = "ถ้าตอนนี้ไม่มีงาน (ไม่มี Hunt, บอสติดคูลดาวน์) จะทำอันถัดไปก่อน แล้วค่อยกลับมา",
    ["On your last heart, skip events that make you easy to kill"] = "เมื่อเหลือหัวใจดวงสุดท้าย จะข้าม event ที่ทำให้ตายง่าย",
    ["Only My Side"] = "เฉพาะฝั่งของฉัน",
    ["Only My Side: only count hunts your race can take (Muzan is Demon/Hybrid, Crow is Slayer/Hybrid)"] = "เฉพาะฝั่งของฉัน: นับเฉพาะ Hunt ที่เผ่าเรารับได้ (Muzan คือ Demon/Hybrid, Crow คือ Slayer/Hybrid)",
    ["Only count hunts your race can accept"] = "นับเฉพาะ Hunt ที่เผ่าเรารับได้",
    ["Only parry a normal hit when the attacker is this close"] = "ปัดหมัดธรรมดาเมื่อศัตรูอยู่ใกล้เท่านี้เท่านั้น",
    ["Only parry a skill when the caster is this close"] = "ปัดสกิลเมื่อผู้ใช้สกิลอยู่ใกล้เท่านี้เท่านั้น",
    ["Ouwigahara - Automatically"] = "Ouwigahara - อัตโนมัติ",
    ["Ouwland - Automatically"] = "Ouwland - อัตโนมัติ",
    ["Parry Against"] = "ปัดป้องใส่",
    ["Parry Hold"] = "เวลากดปัด",
    ["Parry Skills"] = "ปัดสกิล",
    ["Paste a JobId from a friend or another client"] = "วาง JobId จากเพื่อนหรืออีกเครื่อง",
    ["Perfect-block incoming hits"] = "กันจังหวะพอดี (perfect block)",
    ["Pick a Fishing Spot and bait, then turn on Auto Fishing"] = "เลือกจุดตกปลาและเหยื่อ แล้วเปิดตกปลาอัตโนมัติ",
    ["Pick items or whole rarities"] = "เลือกไอเทมหรือทั้งระดับความหายาก",
    ["Pick the Boss Hunt tiers you want (Mythic by default), then turn on Auto Server Hop"] = "เลือกระดับ Boss Hunt ที่ต้องการ (ค่าเริ่มต้น Mythic) แล้วเปิดย้ายเซิร์ฟอัตโนมัติ",
    ["Pick the card worth the most tower points"] = "เลือกการ์ดที่ได้แต้มหอมากที่สุด",
    ["Player Modify"] = "ปรับแต่งตัวละคร",
    ["Players"] = "ผู้เล่น",
    ["Points"] = "แต้ม",
    ["Potions"] = "ยา",
    ["Potions > Sell > Boss Hunt > Farm Boss > Raid > Farm Mob > Farm Level > Fishing"] = "ยา > ขายของ > ล่าบอส > ฟาร์มบอส > แคมป์ > ฟาร์มมอน > ฟาร์มเลเวล > ตกปลา",
    ["Power"] = "พลัง",
    ["Prediction"] = "ยิงดักหน้า",
    ["Priority"] = "ลำดับความสำคัญ",
    ["Progress"] = "ความคืบหน้า",
    ["Puts your best weapon (same priority) into a toolbar slot, and M1 uses your strongest weapon when a tab's Select Weapon is not in the toolbar"] = "ใส่อาวุธดีสุด (ตามสายเดียวกัน) ลงช่อง Toolbar และถ้าอาวุธที่เลือกในแท็บไม่อยู่ใน Toolbar M1 จะใช้อาวุธที่แรงสุด",
    ["Puzzle Progress"] = "ความคืบหน้าปริศนา",
    ["Puzzles: study props, sickle levers, lantern plates"] = "ปริศนา: ของในห้องเรียน, คันโยกเคียว, แผ่นตะเกียง",
    ["Quest Status"] = "สถานะเควส",
    ["Quick Hop"] = "ย้ายเซิร์ฟด่วน",
    ["Raid Settings"] = "ตั้งค่าแคมป์",
    ["Rank"] = "อันดับ",
    ["Ready up in the lobby and clear floors until the hearts run out"] = "กดพร้อมใน lobby แล้วเคลียร์ชั้นจนหัวใจหมด",
    ["Ready up, clear every floor, pick the best cards"] = "กดพร้อม เคลียร์ทุกชั้น เลือกการ์ดดีสุด",
    ["Region"] = "พื้นที่",
    ["Region Discovery"] = "สำรวจพื้นที่",
    ["Regions"] = "พื้นที่",
    ["Rejoin This Server"] = "เข้าเซิร์ฟนี้ใหม่",
    ["Requirement"] = "เงื่อนไข",
    ["Reset Order"] = "รีเซ็ตลำดับ",
    ["Runs once through every puzzle, skips what you already have, then turns off"] = "ทำทุกปริศนาหนึ่งรอบ ข้ามอันที่มีแล้ว แล้วปิดเอง",
    ["Safe Events"] = "Event ปลอดภัย",
    ["Save your position, come back later"] = "บันทึกตำแหน่ง ไว้กลับมาทีหลัง",
    ["Schematics you already have"] = "พิมพ์เขียวที่มีแล้ว",
    ["Sealed Cache Raid"] = "แคมป์ Sealed Cache",
    ["Sealed Caches"] = "กล่อง Sealed Cache",
    ["Select Breathing"] = "เลือกปราณ",
    ["Select Language"] = "เลือกภาษา",
    ["Select Player"] = "เลือกผู้เล่น",
    ["Select Quest"] = "เลือกเควส",
    ["Select Tier"] = "เลือกระดับ",
    ["Select Waypoint"] = "เลือกจุดวาร์ป",
    ["Select Weapon"] = "เลือกอาวุธ",
    ["Sell Every"] = "ขายทุกๆ",
    ["Sell Every: minutes between selling trips"] = "ขายทุกๆ: นาทีระหว่างรอบขาย",
    ["Sell Items"] = "ไอเทมที่ขาย",
    ["Sell List"] = "ลิสต์ขาย",
    ["Sell List (right): pick items and/or whole rarities to sell"] = "ลิสต์ขาย (ขวา): เลือกไอเทม และ/หรือ ทั้งระดับความหายากที่จะขาย",
    ["Sell Now"] = "ขายตอนนี้",
    ["Sell Now: one selling trip right away"] = "ขายตอนนี้: ไปขายหนึ่งรอบทันที",
    ["Sell Rarity"] = "ขายตามความหายาก",
    ["Sell loot to Ginzo (Mistfall Harbor)"] = "ขายของให้ Ginzo (Mistfall Harbor)",
    ["Server Hop"] = "ย้ายเซิร์ฟ",
    ["Servers"] = "เซิร์ฟเวอร์",
    ["Servers already checked are skipped for 20 minutes"] = "เซิร์ฟที่เช็คแล้วข้าม 20 นาที",
    ["Set Waypoint"] = "ตั้งจุดวาร์ป",
    ["Settings"] = "ตั้งค่า",
    ["Shared by every ESP"] = "ใช้ร่วมกันทุก ESP",
    ["Shops: Rika (Windy Peak) sells Health Regen Potion 600 Wen and Stamina Regen Potion 900 Wen. Health Potion is not sold"] = "ร้าน: Rika (Windy Peak) ขาย Health Regen Potion 600 Wen และ Stamina Regen Potion 900 Wen ส่วน Health Potion ไม่มีขาย",
    ["Show"] = "แสดง",
    ["Show FOV Circle"] = "แสดงวง FOV",
    ["Silent Aim"] = "เล็งอัตโนมัติ (Silent Aim)",
    ["Skill Keys"] = "ปุ่มสกิล",
    ["Skill Keys: pick the keys to use (Z X C V B)"] = "ปุ่มสกิล: เลือกปุ่มที่จะใช้ (Z X C V B)",
    ["Skill Range"] = "ระยะสกิล",
    ["Skills fly to the target in your FOV"] = "สกิลพุ่งไปหาเป้าใน FOV",
    ["When skills are on cooldown, it borrows the next toolbar weapon with a ready skill; M1 always uses Select Weapon"] = "เมื่อสกิลติดคูลดาวน์ จะยืมอาวุธถัดไปใน Toolbar ที่สกิลพร้อม; M1 ใช้อาวุธที่เลือกเสมอ",
    ["Skip Wave Break"] = "ข้ามช่วงพัก",
    ["Skip targets behind walls"] = "ข้ามเป้าที่อยู่หลังกำแพง",
    ["Smart Weapon Swap"] = "สลับอาวุธอัจฉริยะ",
    ["Smart Weapon Swap: when every skill of the held weapon is on cooldown, borrow the next toolbar weapon that has a ready skill. M1 always uses your Select Weapon"] = "สลับอาวุธอัจฉริยะ: เมื่อสกิลของอาวุธในมือติดคูลดาวน์หมด จะยืมอาวุธถัดไปใน Toolbar ที่สกิลพร้อม M1 ใช้อาวุธที่เลือกเสมอ",
    ["Smoothness"] = "ความนุ่มนวล",
    ["Speed"] = "ความเร็ว",
    ["Speed, jump and collision"] = "ความเร็ว กระโดด และการชน",
    ["Spend a ticket when a fresh hand is worth more"] = "ใช้ตั๋วเมื่อมือใหม่คุ้มกว่า",
    ["State"] = "สถานะ",
    ["Stays on and keeps hopping after the teleport if the hub runs again on the new server (autoexec)"] = "เปิดค้างไว้และย้ายต่อหลังวาร์ป ถ้าฮับรันอีกครั้งในเซิร์ฟใหม่ (autoexec)",
    ["Step"] = "ขั้นตอน",
    ["Style"] = "สไตล์",
    ["Take a Boss Hunt, kill the boss, repeat"] = "รับ Boss Hunt ฆ่าบอส แล้ววนซ้ำ",
    ["Takes the quest of mobs that have one. Mobs without a quest are farmed anyway"] = "รับเควสของมอนที่มีเควส มอนที่ไม่มีเควสก็ฟาร์มตามปกติ",
    ["Target Info"] = "ข้อมูลเป้า",
    ["Target Players"] = "ผู้เล่นเป้าหมาย",
    ["Task"] = "งาน",
    ["Teleport"] = "วาร์ป",
    ["Teleport to Player"] = "วาร์ปไปหาผู้เล่น",
    ["Teleport to Quest Target"] = "วาร์ปไปเป้าเควส",
    ["Teleport to Waypoint"] = "วาร์ปไปจุดที่บันทึก",
    ["Teleport to players"] = "วาร์ปไปหาผู้เล่น",
    ["Text Size"] = "ขนาดตัวอักษร",
    ["The hub always does the highest one that has something to do"] = "ฮับจะทำอันที่อยู่สูงสุดที่มีงานให้ทำก่อนเสมอ",
    ["Theme"] = "ธีม",
    ["This Server"] = "เซิร์ฟนี้",
    ["Timed event & Event-based Trial Automator"] = "อีเวนต์ตามเวลา & ลงด่าน Trial อัตโนมัติ",
    ["Toggle only is always on while enabled (mobile); other keys lock while held"] = "Toggle only คือล็อกตลอดเมื่อเปิด (มือถือ); ปุ่มอื่นล็อกขณะกดค้าง",
    ["Toggle with the minimize bind"] = "เปิด/ปิดด้วยปุ่มย่อหน้าต่าง",
    ["Toolbar slot for the best weapon (Auto is an empty slot, or it replaces your worst weapon)"] = "ช่อง Toolbar ของอาวุธดีสุด (อัตโนมัติคือช่องว่าง หรือแทนอาวุธที่แย่สุด)",
    ["Top"] = "บน",
    ["Tower"] = "หอ",
    ["Tower Climb"] = "ปีนหอ",
    ["Tower Exchange"] = "แลกของหอ",
    ["Tracer From"] = "เส้นจาก",
    ["Trade tower points after a run"] = "แลกแต้มหอหลังจบรอบ",
    ["Travel"] = "การเดินทาง",
    ["Trial Settings"] = "ตั้งค่าด่าน",
    ["Turn on Auto Sell: flies to Ginzo (Mistfall Harbor), sells, then comes back. While farming it waits until the current target dies"] = "เปิดขายของอัตโนมัติ: บินไปหา Ginzo (Mistfall Harbor) ขาย แล้วกลับมา ระหว่างฟาร์มจะรอตัวที่ตีอยู่ตายก่อน",
    ["Turn on Auto Unlock Fishing to get the permit"] = "เปิดปลดล็อกตกปลาอัตโนมัติเพื่อรับใบอนุญาต",
    ["Turn on Auto Upgrade Rod to go Basic -> Rare -> Legendary (it fishes for the items itself)"] = "เปิดอัปเกรดเบ็ดอัตโนมัติ Basic -> Rare -> Legendary (ตกปลาหาของเอง)",
    ["Turn on Auto Use Skill: skills fire only at the mob/boss your running farm is attacking"] = "เปิดใช้สกิลอัตโนมัติ: ใช้สกิลใส่มอน/บอสที่ฟาร์มกำลังตีอยู่เท่านั้น",
    ["Turn on as many as you want in their own tabs (farms, Auto Fishing, Auto Sell, potions)"] = "เปิดได้หลายอย่างพร้อมกันในแท็บของมัน (ฟาร์ม, ตกปลา, ขายของ, ยา)",
    ["Turns the camera to the target (uses the Silent Aim targets and FOV)"] = "หันกล้องไปที่เป้า (ใช้เป้าและ FOV เดียวกับ Silent Aim)",
    ["Underwater Breathing Potion is drunk while swimming underwater"] = "Underwater Breathing Potion ดื่มตอนว่ายใต้น้ำ",
    ["Unlock & Upgrade"] = "ปลดล็อก & อัปเกรด",
    ["Unlocks the next skill of your breathing once you have the skill points and mastery"] = "ปลดสกิลถัดไปของปราณเมื่อมีแต้มสกิลและ mastery พอ",
    ["Use Bait"] = "ใช้เหยื่อ",
    ["Use skills on the active farm target only"] = "ใช้สกิลกับเป้าที่ฟาร์มอยู่เท่านั้น",
    ["Visible Check"] = "เช็คการมองเห็น",
    ["Visit every region you have not discovered yet"] = "ไปทุกพื้นที่ที่ยังไม่ได้สำรวจ",
    ["Visual"] = "การแสดงผล",
    ["Vote to skip the 10s break between floors"] = "โหวตข้ามช่วงพัก 10 วิระหว่างชั้น",
    ["Walk Speed"] = "ความเร็วเดิน",
    ["Waypoint Name"] = "ชื่อจุดวาร์ป",
    ["Waypoints"] = "จุดวาร์ป",
    ["Weapon Slot"] = "ช่องอาวุธ",
    ["Weapon and instant kill inside the trial"] = "อาวุธและฆ่าทันทีในด่าน",
    ["Weapon, method and mode while learning"] = "อาวุธ ตำแหน่ง และโหมดระหว่างฝึก",
    ["Weapon, position and instant kill"] = "อาวุธ ตำแหน่ง และฆ่าทันที",
    ["Weapon, position and movement"] = "อาวุธ ตำแหน่ง และการเคลื่อนที่",
    ["Wear the best stat equipment for your build"] = "ใส่อุปกรณ์ค่าดีสุดตามสายของคุณ",
    ["Wears your best titles for what you're doing: fishing titles while fishing, damage titles while farming"] = "ใส่ Title ดีสุดตามสิ่งที่ทำ: ตกปลาใส่ Title ตกปลา, ฟาร์มใส่ Title ดาเมจ",
    ["When a selected potion runs out, flies to the shop and buys more (farm waits between targets)"] = "เมื่อยาที่เลือกหมด จะบินไปร้านซื้อเพิ่ม (ฟาร์มรอระหว่างตัว)",
    ["When a tab's Select Weapon is not in your toolbar, M1 uses the weapon with the strongest M1 (damage x combo speed)"] = "ถ้าอาวุธที่เลือกในแท็บไม่อยู่ใน Toolbar M1 จะใช้อาวุธที่ M1 แรงสุด (ดาเมจ x ความเร็วคอมโบ)",
    ["Which auto farm goes first"] = "ฟาร์มอันไหนทำก่อน",
    ["Which potions to drink (Elixir first). Regen potions wait until the buff ends"] = "ยาที่จะดื่ม (Elixir ก่อน) ยาฟื้นฟูรอบัฟหมดก่อน",
    ["Window and executor options"] = "ตัวเลือกหน้าต่างและ executor",
    ["World"] = "โลก",
    ["Your executor has no Drawing API - only Chams will show"] = "executor ไม่มี Drawing API - จะแสดงแค่ Chams",
    ["Zones, NPCs and shrines"] = "โซน NPC และศาลเจ้า",
    ["Empty is Waypoint 1, 2, ..."] = "ว่างคือ Waypoint 1, 2, ...",
})

ApplyLanguage(getgenv().ConfigurationTable.Language)

local Window = Library:Window({
    Name = "Valkyrie Hub",
    Logo = IconValkyrie
})

Library:Notify("Valkyrie Hub", "Loaded - have fun", 5)

--// ปุ่มลอยเปิด/ปิดเมนู (ผู้ใช้ 2026-10-02): โลโก้ Valkyrie มุมโค้ง พื้นโปร่งแสง ลากย้ายได้ (จำตำแหน่ง) แตะ = เปิด/ปิด
-- แทนปุ่มลอยตัวเดิมของ Milenium (ตัวอักษร V) - ตั้งค่า "Mobile Button" ของไลบรารีคุมปุ่มนี้แทน
-- อยู่ใน ScreenGui "mobile" ของไลบรารี (ไม่หายตอนซ่อนเมนู / inject ซ้ำไลบรารีลบทิ้งให้เอง)
do
    local Holder = LibraryMilenium and LibraryMilenium["mobile"]
    local Menu = Library.MileniumWindow
    if Holder and Menu and Menu.toggle_menu then
        local TweenService = game:GetService("TweenService")
        local UserInput = game:GetService("UserInputService")
        local Config = getgenv().ConfigurationTable
        pcall(function() Menu.items["mobile_button"].Visible = false end)

        local Button = Instance.new("TextButton")
        Button.Name = "\0"
        Button.Text = ""
        Button.AutoButtonColor = false
        Button.Size = UDim2.fromOffset(54, 54)
        local Saved = Config.ToggleButtonPos
        Button.Position = type(Saved) == "table" and #Saved == 4 and UDim2.new(Saved[1], Saved[2], Saved[3], Saved[4])
            or UDim2.new(0, 24, 0.35, 0)
        Button.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
        Button.BackgroundTransparency = 0.5
        Button.ZIndex = 50
        Button.Parent = Holder

        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 18)
        Corner.Parent = Button
        local Stroke = Instance.new("UIStroke")
        Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        Stroke.Color = Color3.fromRGB(255, 255, 255)
        Stroke.Transparency = 0.78
        Stroke.Thickness = 1.5
        Stroke.Parent = Button
        local Scale = Instance.new("UIScale")
        Scale.Parent = Button

        local Logo = Instance.new("ImageLabel")
        Logo.Name = "\0"
        Logo.BackgroundTransparency = 1
        Logo.AnchorPoint = Vector2.new(0.5, 0.5)
        Logo.Position = UDim2.fromScale(0.5, 0.5)
        Logo.Size = UDim2.fromScale(0.72, 0.72)
        Logo.Image = "rbxassetid://" .. IconValkyrie
        Logo.ScaleType = Enum.ScaleType.Fit
        Logo.ZIndex = 51
        Logo.Parent = Button

        local function Tween(Object, Time, Goal)
            TweenService:Create(Object, TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), Goal):Play()
        end
        local function Hover(On)
            Tween(Button, 0.15, { BackgroundTransparency = On and 0.3 or 0.5 })
            Tween(Stroke, 0.15, { Transparency = On and 0.55 or 0.78 })
        end
        Button.MouseEnter:Connect(function() Hover(true) end)
        Button.MouseLeave:Connect(function() Hover(false) end)

        local function IsPress(Input)
            return Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch
        end
        local Start, StartPos, Moved = nil, nil, false
        Button.InputBegan:Connect(function(Input)
            if not IsPress(Input) then return end
            Start, StartPos, Moved = Input.Position, Button.Position, false
            Tween(Scale, 0.08, { Scale = 0.9 })
        end)
        TrackConnection(UserInput.InputChanged:Connect(function(Input)
            if not Start then return end
            if Input.UserInputType ~= Enum.UserInputType.MouseMovement and Input.UserInputType ~= Enum.UserInputType.Touch then return end
            local Delta = Input.Position - Start
            if Delta.Magnitude > 6 then Moved = true end
            if Moved then
                Tween(Button, 0.08, { Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y) })
            end
        end))
        TrackConnection(UserInput.InputEnded:Connect(function(Input)
            if not (Start and IsPress(Input)) then return end
            Start = nil
            Tween(Scale, 0.12, { Scale = 1 })
            if Moved then
                task.delay(0.1, function()
                    local P = Button.Position
                    Config.ToggleButtonPos = { P.X.Scale, P.X.Offset, P.Y.Scale, P.Y.Offset }
                    SaveConfiguration()
                end)
            else
                pcall(Menu.toggle_menu, not LibraryMilenium["items"].Enabled)
            end
        end))

        -- ตั้งค่า "Mobile Button" ในหน้า Settings ของไลบรารี = ซ่อน/โชว์ปุ่มนี้
        Menu.set_mobile_button = function(Bool) Button.Visible = Bool == true end
    end
end

Window:Category("Ouwland - Automatically")

---- ============ AutoFarm Tab ============ ----

-- Boss Hunt อยู่แท็บแรก (สร้างหน้าก่อน ส่วนตัวรันอยู่ในบล็อกตัวรันฟาร์มข้างล่าง)
local HuntPage = Window:Page({ Name = "Boss Hunt", Icon = "crosshair", Columns = 2 })

local HuntMainSection = HuntPage:Section({
    Name = "Auto Boss Hunt",
    Description = "Take a Boss Hunt, kill the boss, repeat",
    Icon = "80758916183665",
    Side = 1
})

local HuntCollectSection = HuntPage:Section({
    Name = "Auto Collect Chest",
    Description = "Chests and loot drops",
    Icon = "80758916183665",
    Side = 1
})

local HuntSettingsSection = HuntPage:Section({
    Name = "Settings",
    Description = "Weapon, position and movement",
    Icon = "93142176757189",
    Side = 2
})

local LevelPage = Window:Page({ Name = "Farm Level", Icon = "trending-up", Columns = 2 })
local MobPage = Window:Page({ Name = "Farm Mob", Icon = "swords", Columns = 2 })
local BossPage = Window:Page({ Name = "Farm Boss", Icon = "skull", Columns = 2 })
Farm.PriorityPage = Window:Page({ Name = "Priority", Icon = "list-ordered", Columns = 2 })   -- ใน Farm (main chunk local เต็ม)

local LevelSettingsSection = LevelPage:Section({
    Name = "Settings",
    Description = "Weapon, position and movement",
    Icon = "93142176757189",
    Side = 2
})

local LevelMainSection = LevelPage:Section({
    Name = "Auto Farm Level",
    Description = "Farm until max level",
    Icon = "80758916183665",
    Side = 1
})

local LevelCollectSection = LevelPage:Section({
    Name = "Auto Collect Chest",
    Description = "Chests and loot drops",
    Icon = "80758916183665",
    Side = 1
})

local MobSettingsSection = MobPage:Section({
    Name = "Settings",
    Description = "Weapon, position and movement",
    Icon = "93142176757189",
    Side = 2
})

local MobMainSection = MobPage:Section({
    Name = "Auto Farm Mob",
    Description = "Farm a chosen mob",
    Icon = "80758916183665",
    Side = 1
})

local MobCollectSection = MobPage:Section({
    Name = "Auto Collect Chest",
    Description = "Chests and loot drops",
    Icon = "80758916183665",
    Side = 1
})

local BossSettingsSection = BossPage:Section({
    Name = "Settings",
    Description = "Weapon, position and movement",
    Icon = "93142176757189",
    Side = 2
})

local BossMainSection = BossPage:Section({
    Name = "Auto Farm Boss",
    Description = "Farm a chosen boss",
    Icon = "80758916183665",
    Side = 1
})

local BossCollectSection = BossPage:Section({
    Name = "Auto Collect Chest",
    Description = "Chests and loot drops",
    Icon = "80758916183665",
    Side = 1
})

-- โหมดที่ขยับตัวละครเอง (Auto Farm / Mob / Boss / Breathing) รันพร้อมกันไม่ได้ - เปิดตัวหนึ่ง
-- ปิดตัวอื่นผ่าน Library.SetFlags ตาม flag ในลิสต์นี้ (Breathing ลงทะเบียน flag ของตัวเองตอนสร้าง toggle)
local ExclusiveFlags = {
    Farm = { "SL2AutoFarm", "SL2AutoFarmMob", "SL2AutoFarmBoss", "SL2AutoBossHunt", "SL2AutoRaidCache" },
    Breathing = { "SL2AutoBreathing" },
    Puzzle = { "SL2AutoPuzzle", "SL2AutoDiscovery" },   -- Auto Puzzle + Region Discovery (หน้า Misc)
    -- Auto Upgrade Rod ไม่อยู่ในลิสต์: แค่รอของครบแล้วไปซื้อ รันคู่กับอย่างอื่นได้
    Fishing = { "SL2AutoUnlockFishing", "SL2AutoFishing", "SL2AutoQuestShiori" },
    -- เควสส่งของ (วาร์ปไปมา) ฝากไว้กลุ่มเดียวกับ Fishing - ฟาร์ม/ปราณ/ตกปลาเปิดแล้วปิดตัวนี้ให้เอง
    Quest = { "SL2AutoJewelryBox" },
}

local function TurnOffFlags(List, Except)
    for _, Flag in ipairs(List) do
        if Flag ~= Except and Library.Flags and Library.Flags[Flag] then
            local Set = Library.SetFlags and Library.SetFlags[Flag]
            if Set then pcall(Set, false) end
        end
    end
end

local FinalSelectionPage = Window:Page({ Name = "Final Selection", Icon = "target", Columns = 2 })

local FinalSelectionSection = nil
local FinalTrialSection = nil
if FinalSelectionEnabled then
    FinalSelectionSection = FinalSelectionPage:Section({
        Name = "Final Selection",
        Description = "Timed event & Event-based Trial Automator",
        Icon = "80758916183665",
        Side = 1
    })

    -- ตั้งค่าที่ใช้ในด่าน แยกกล่องไปฝั่งขวา (กล่องเดียวเต็มหน้าเหลือที่ว่างครึ่งจอ)
    FinalTrialSection = FinalSelectionPage:Section({
        Name = "Trial Settings",
        Description = "Weapon and instant kill inside the trial",
        Icon = "93142176757189",
        Side = 2
    })
end

-- การ์ด Status (fallback เป็น Label ถ้าไลบรารีบนเว็บยังไม่มี Section:Status)
-- Seperator = true -> มีเส้นใต้การ์ด (ตัวที่ 5 ไม่ใส่ = ไม่มีเส้น)
local function MakeStatusCard(Section, Title, Rows, Progress, Seperator)
    if type(Section.Status) == "function" then
        return Section:Status({ Name = Title, Rows = Rows, Progress = Progress, Seperator = Seperator })
    end

    local Label = Section:Label("-")
    local State, Values = "Idle", { }
    for _, Key in ipairs(Rows) do Values[Key] = "-" end
    local function Render()
        local Parts = { }
        for _, Key in ipairs(Rows) do
            if Values[Key] ~= "Idle" then table.insert(Parts, Values[Key]) end
        end
        Label:SetText(table.concat(Parts, " | "))     -- ไม่ใส่ป้าย [State] นำหน้า
    end
    return {
        SetState = function(_, Value) State = Value Render() end,
        Set = function(_, Key, Value) Values[Key] = tostring(Value) Render() end,
        SetProgress = function() end,
    }
end

-- ตัวสลับโหมดฟาร์ม (SetMode ในบล็อกข้างล่าง) - เปิดให้ section นอกแท็บ AutoFarm ใช้ตัวรันเดียวกัน
-- (Sealed Cache Raid อยู่แท็บของตัวเอง แต่รันผ่าน RunFarm โหมด "Camp")
local SetFarmMode = nil

---- ============ Auto Sell ============ ----
--
-- ยืนยันสด (decompile Dialogues.Functions.MerchantActions.GinzoSell + ขายจริงผ่าน dex):
--   ขาย = SignalFunction.ToServer("SellItems", { [ชื่อไอเทม] = จำนวน }) คืน { [สกุลเงิน] = ได้เท่าไหร่ }
--   ต้องยืนใกล้ Ginzo (Mistfall Harbor) - 15 studs ขายได้, 40 studs เซิร์ฟคืน {} ไม่ขาย
--   ของที่ขายได้ = เงื่อนไขเดียวกับหน้าขายของเกม (GatherSellables ใน DialogueComponent.Components.Sell)
--   ราคาขาย = Shop.GetSellPayout(ชื่อ) บางชิ้นได้ Wen บางชิ้นได้วัตถุดิบ (Cutlass -> Metal Scraps)
--   ของที่ใส่อยู่ = Inventory.Toolbar + Inventory.Accessories.Vanity/Stats (เก็บเป็น Id ของชิ้นในกระเป๋า)
--   เซิร์ฟรับเป็นชื่อ ไม่ได้ระบุชิ้น - ชื่อที่ใส่อยู่ข้ามทั้งชื่อ (ไม่รู้ว่าเซิร์ฟหยิบชิ้นไหนไปขาย)
-- Keep = { [เจ้าของ] = { [ชื่อ] = จำนวนที่เก็บไว้ } } ระบบอื่นกันของที่ต้องใช้ไม่ให้โดนขาย (Golden Fish ไว้แลกเบ็ด)
-- Paused = มีระบบอื่นคุมการขายเอง (ตกปลาเรียก Seller.Run ระหว่างรอบเหวี่ยงเบ็ด ไม่ให้ลูปขายวาร์ปกลางคัน)
local Seller = { NextAt = 0, Busy = false, Status = "-", Last = "-", Earned = { }, Keep = { }, Paused = false }
Farm.Seller = Seller

do
    local function Require(Path)
        local Ok, Module = pcall(function() return require(Path()) end)
        return Ok and Module or nil
    end

    local Items = Require(function() return ReplicatedStorage.CAM.Global.Collectibles.Items end)
    local Shop = Require(function() return ReplicatedStorage.CAM.Global.Shop end)
    local Utility = Require(function() return ReplicatedStorage.CAM.Global.Utility end)
    local Rarities = Require(function() return ReplicatedStorage.CAM.Global.Rarities end)
    local SignalFunction = HubSignal(Require(function() return ReplicatedStorage.Communication.ServerAndClient.Signals.SignalFunction end))
    local Ginzo = Require(function() return ReplicatedStorage.Ouwland.Content["Mistfall Harbor"].Npcs.Ginzo end)

    local GinzoPos = nil
    pcall(function()
        local Spawn = Ginzo.Spawns[1]
        GinzoPos = typeof(Spawn) == "CFrame" and Spawn.Position or Spawn
    end)

    local SellOffset = Vector3.new(5, 0, 0)   -- ห่าง Ginzo 5 studs (ขายได้ถึง ~15)
    local RetryAfterFail = 30

    function Seller.RarityNames()
        local List = { }
        for _, Name in ipairs(Rarities and Rarities.Order or { }) do table.insert(List, Name) end
        return List
    end

    local function RarityName(Item)
        local Order = Rarities and Rarities.Order
        return Order and Order[Item.Rarity] or tostring(Item.Rarity)
    end

    local function GetInventory()
        local Ok, Data = pcall(function() return Utility.GetData(LocalPlayer) end)
        return Ok and Data and Data:FindFirstChild("Inventory") or nil
    end

    -- ชื่อไอเทมที่ใส่อยู่ (Toolbar + ชุด Vanity/Stats) จาก Id
    local function EquippedNames(Inventory)
        local ById = { }
        for _, Entry in ipairs(Inventory.Inventory:GetChildren()) do
            local Id = Entry:FindFirstChild("Id")
            if Id then ById[Id.Value] = Entry.Name end
        end

        local Names = { }
        local function Add(Folder)
            for _, Slot in ipairs(Folder and Folder:GetDescendants() or { }) do
                if Slot:IsA("ValueBase") and ById[Slot.Value] then Names[ById[Slot.Value]] = true end
            end
        end
        Add(Inventory:FindFirstChild("Toolbar"))
        local Accessories = Inventory:FindFirstChild("Accessories")
        Add(Accessories and Accessories:FindFirstChild("Vanity"))
        Add(Accessories and Accessories:FindFirstChild("Stats"))
        return Names
    end

    -- กฎเดียวกับหน้าขายของเกม (ระดับไอเทม ไม่รวม NoSave/QuestGrant ที่เป็นของแต่ละชิ้นในกระเป๋า)
    local function CanSell(Name, Item)
        return type(Item) == "table" and Item.NoDelete ~= true and Item.NoSell ~= true and Item.Requirements == nil
            and Item.NoSaveRequirements == nil and (Item.Price ~= nil or Shop.itemsforsale[Name] ~= nil)
    end

    -- ชื่อไอเทมทั้งเกมที่ขายได้ (ไม่ต้องมีในกระเป๋า - ไว้ตั้งล่วงหน้าใน dropdown) วัดสด 294 / 439 ชิ้น
    local AllNames = nil
    function Seller.AllSellableNames()
        if AllNames then return AllNames end
        local List = { }
        if Items and Shop then
            for Name, Item in pairs(Items) do
                if type(Name) == "string" and CanSell(Name, Item) then table.insert(List, Name) end
            end
            table.sort(List)
        end
        if #List > 0 then AllNames = List end
        return List
    end

    -- ของที่ขายได้ในกระเป๋า { { Name, Owned, Rarity, Equipped } } เรียงตามชื่อ
    -- เรียก Utility.GetData = thread เสีย capability ชั่วคราว - คนเรียกต้อง task.wait() ก่อนสร้าง Instance
    function Seller.Sellables()
        local List = { }
        local Inventory = Items and Shop and Utility and GetInventory()
        if not Inventory then return List end

        local Owned, Blocked = { }, { }
        for _, Entry in ipairs(Inventory.Inventory:GetChildren()) do
            local Name = Entry.Name
            if Entry:FindFirstChild("NoSave") == nil and Entry:FindFirstChild("QuestGrant") == nil then
                if CanSell(Name, Items[Name]) then
                    local Amount = Entry:FindFirstChild("Amount")
                    Owned[Name] = (Owned[Name] or 0) + (Amount and Amount.Value or 1)
                end
            else
                Blocked[Name] = true
            end
        end

        local Equipped = EquippedNames(Inventory)
        for Name, Count in pairs(Owned) do
            if not Blocked[Name] then
                table.insert(List, { Name = Name, Owned = Count, Rarity = RarityName(Items[Name]), Equipped = Equipped[Name] == true })
            end
        end
        table.sort(List, function(A, B) return A.Name < B.Name end)
        return List
    end

    -- ของที่จะขายรอบนี้ { [ชื่อ] = จำนวน } ตามรายชื่อ + ความหายากที่เลือก
    function Seller.BuildSelection()
        local Config = getgenv().ConfigurationTable
        local Names = type(Config.AutoSellItems) == "table" and Config.AutoSellItems or { }
        local Tiers = type(Config.AutoSellRarities) == "table" and Config.AutoSellRarities or { }

        local Kept = { }
        for _, List in pairs(Seller.Keep) do
            for Name, Amount in pairs(List) do
                Kept[Name] = math.max(Kept[Name] or 0, Amount)
            end
        end

        local Selection, Count = { }, 0
        for _, Item in ipairs(Seller.Sellables()) do
            local Wanted = table.find(Names, Item.Name) or table.find(Tiers, Item.Rarity)
            local Amount = math.min(Item.Owned - (Kept[Item.Name] or 0), 999)
            if Wanted and Amount > 0 and not (Config.AutoSellKeepEquipped and Item.Equipped) then
                Selection[Item.Name] = Amount
                Count = Count + Amount
            end
        end
        return Selection, Count
    end

    function Seller.Due()
        local Config = getgenv().ConfigurationTable
        return Config.AutoSell == true and not Seller.Busy and os.clock() >= Seller.NextAt
    end

    local function Summary(Result)
        local Parts = { }
        for Currency, Amount in pairs(Result) do
            table.insert(Parts, tostring(Amount) .. " " .. tostring(Currency))
        end
        table.sort(Parts)
        return #Parts > 0 and table.concat(Parts, ", ") or "-"
    end

    function Seller.EarnedText()
        return Summary(Seller.Earned)
    end

    -- บินไปหา Ginzo แล้วขายรอบเดียว - คืน true ถ้าได้ขาย (ไม่มีอะไรให้ขาย = false ไม่ขยับตัว)
    -- Force = กดปุ่ม Sell Now (ไม่สนว่าเปิด Auto Sell ไหม)
    function Seller.Run(ShouldContinue, Force)
        if Seller.Busy then return false end
        local Config = getgenv().ConfigurationTable
        Seller.NextAt = os.clock() + math.max(1, tonumber(Config.AutoSellInterval) or 5) * 60

        local Selection, Count = Seller.BuildSelection()
        task.wait()
        if Count == 0 then
            Seller.Status = "Nothing to sell"
            return false
        end
        if not (GinzoPos and SignalFunction) then
            Seller.Status = "Ginzo not found"
            return false
        end

        ShouldContinue = ShouldContinue or function() return true end
        local function Continue()
            return getgenv().ValkyrieSession == SessionToken and (Force or Config.AutoSell == true) and ShouldContinue()
        end

        Seller.Busy = true
        Seller.Status = "Going to Ginzo"
        Fighter.AttackTarget = nil
        Movement.Lock(nil)

        local Stand = CFrame.new(GinzoPos + SellOffset, GinzoPos)
        local Sold = false
        pcall(function()
            Movement.Go(Stand, 3, 60, Continue)
            local Root = Movement.GetRoot()
            if not (Continue() and Root and (Root.Position - GinzoPos).Magnitude <= 12) then return end

            Movement.Lock(Stand)
            Farm.Sleep(0.5, Continue)   -- ให้เซิร์ฟเห็นตำแหน่งใหม่ก่อน (ขายจากระยะไกลเซิร์ฟคืน {} เงียบ ๆ)
            Seller.Status = "Selling " .. Count .. " items"

            local Ok, Result = pcall(SignalFunction.ToServer, "SellItems", Selection)
            if Ok and type(Result) == "table" and next(Result) then
                for Currency, Amount in pairs(Result) do
                    if type(Amount) == "number" then
                        Seller.Earned[Currency] = (Seller.Earned[Currency] or 0) + Amount
                    end
                end
                Seller.Last = Count .. " items -> " .. Summary(Result)
                Sold = true
            end
        end)

        Movement.Lock(nil)
        Seller.Busy = false
        if Sold then
            Seller.Status = "Sold"
        else
            Seller.Status = "Sale failed"
            Seller.NextAt = os.clock() + RetryAfterFail
        end
        return Sold
    end

    -- ไม่มีฟาร์มไหนรันอยู่ (Fighter.Continue = nil) = ขายเองตามรอบ / มีฟาร์มรัน = ลูปฟาร์มเรียก Seller.Run
    -- ตอนว่างระหว่างตัว (ไม่ตัดกลางไฟต์)
    task.spawn(function()
        while getgenv().ValkyrieSession == SessionToken do
            task.wait()
            if Seller.Due() and Fighter.Continue == nil and not Seller.Paused and not InTrialPlace then
                pcall(Seller.Run)
            end
        end
    end)
end

--// Auto Drink Potion + Auto Buy Potion (หน้า Players)
--
-- ยืนยันผ่าน dex (ToolScripts["Health Potion"] ใช้ร่วมทุกขวด):
--   ดื่ม = ถือขวด (Items_Config.Equipped = เลขช่อง -> เซิร์ฟใส่ขวดใน Character.Tool_Accessories มี CapWeld)
--          แล้ว SignalEvent.ToServer("Tool_Mouse", "Down", Platform_Handler.mousepos()) -> ขวดลด ~2.0 วิ
--          ตามด้วย "Up" (แบบเดียวกับ HUD Toolbar ตอนคลิก) - ระหว่างดื่มห้าม M1/สลับอาวุธ (ManuelCancel ตัดกลางคัน)
--   ผล (Health PotionServer): Health Potion +25 / Health Elixir +60 เลือดทันที
--        Regen/Underwater = บัฟตามเวลา Utility.AddTimedValue(ValuesFolder, ชื่อ stat, วินาที) - Potion 10 วิ,
--        Elixir 20 วิ, Underwater 120 วิ -> มีลูกชื่อ stat ใน values folder = บัฟยังอยู่ ไม่ต้องดื่มซ้ำ
--   ซื้อ = ยืนติดร้าน (prompt ActionText "Purchase" ObjectText = ชื่อของ) แล้ว PurchaseFromShop(ชื่อ, จำนวน)
--          place หลักมีแค่ Rika (Windy Peak): Health Regen Potion 600 / Stamina Regen Potion 900 Wen
--          Health Potion ไม่มีขาย / Elixir ต้องใช้ Demon Horns (ยังไม่เจอร้าน) - หาร้านจาก prompt ใน place ปัจจุบันเลย
--   ช่องค้าง: วัดสด Health Potion ช่อง Three ถือแล้วเซิร์ฟไม่ใส่ขวดให้ พอย้ายช่องถึงถือได้ -> ไม่ขึ้นใน 1.5 วิ ใส่ช่องใหม่อีกรอบ
local Potions = {
    Order = { "Health Elixir", "Health Potion", "Health Regen Elixir", "Health Regen Potion",
        "Stamina Regen Elixir", "Stamina Regen Potion", "Underwater Breathing Potion" },
    Kinds = {
        ["Health Elixir"] = { Kind = "Health" },
        ["Health Potion"] = { Kind = "Health" },
        ["Health Regen Elixir"] = { Kind = "Health", Buff = "Health Regen Speed" },
        ["Health Regen Potion"] = { Kind = "Health", Buff = "Health Regen Speed" },
        ["Stamina Regen Elixir"] = { Kind = "Stamina", Buff = "Stamina Regen Speed" },
        ["Stamina Regen Potion"] = { Kind = "Stamina", Buff = "Stamina Regen Speed" },
        ["Underwater Breathing Potion"] = { Kind = "Breath", Buff = "Breath Duration Factor" },
    },
    Busy = false, Buying = false, NextBuyAt = 0, Status = "-", Last = "-",
    RetreatDistance = 50, -- ระหว่างฟาร์ม ถอยไปยืนบนพื้นห่างมอนก่อนดื่ม (เดิมลอยขึ้น 70 studs = โดน kick)
}
Farm.Potions = Potions

do
    local function Require(Path)
        local Ok, Module = pcall(function() return require(Path()) end)
        return Ok and Module or nil
    end

    local Utility = Require(function() return ReplicatedStorage.CAM.Global.Utility end)
    local Shop = Require(function() return ReplicatedStorage.CAM.Global.Shop end)
    local SignalEvent = HubSignal(Require(function() return ReplicatedStorage.Communication.ServerAndClient.Signals.SignalEvent end))
    local PlatformHandler = Require(function() return ReplicatedStorage.CAM.Client.Controllers.Platform_Handler end)

    local Slots = { "One", "Two", "Three", "Four", "Five" }

    local function Selected(Name)
        local List = getgenv().ConfigurationTable.DrinkPotions
        return type(List) == "table" and table.find(List, Name) ~= nil
    end

    local function Inventory()
        local Ok, Data = pcall(Utility.GetData, LocalPlayer, true)
        return Ok and Data and Data.Inventory or nil
    end

    function Potions.Amount(Name)
        local Inv = Inventory()
        local Folder = Inv and Inv.Inventory:FindFirstChild(Name)
        if not Folder then return 0 end
        local Amount = Folder:FindFirstChild("Amount")
        return Amount and Amount.Value or 1
    end

    local function BuffActive(Buff)
        local Ok, Values = pcall(Utility.getvaluesfolder, LocalPlayer)
        return Ok and Values ~= nil and Values:FindFirstChild(Buff) ~= nil
    end

    -- ยาที่ควรดื่มตอนนี้ (เรียงตาม Order = Elixir ก่อน Potion) ไม่มี = nil
    function Potions.Pick()
        local Config = getgenv().ConfigurationTable
        local Character = LocalPlayer.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        if not Humanoid or Humanoid.Health <= 0 then return nil end

        local Need = { }
        if Humanoid.MaxHealth > 0 and Humanoid.Health / Humanoid.MaxHealth * 100 <= (tonumber(Config.DrinkHealthPercent) or 50) then
            Need.Health = true
        end
        pcall(function()
            local Stamina = Utility.getvaluesfolder(LocalPlayer).Stamina
            if Stamina.MaxValue > 0 and Stamina.Value / Stamina.MaxValue * 100 <= (tonumber(Config.DrinkStaminaPercent) or 25) then
                Need.Stamina = true
            end
        end)
        if Character:GetAttribute("SwimUnderwater") == true then Need.Breath = true end
        if next(Need) == nil then return nil end

        for _, Name in ipairs(Potions.Order) do
            local Info = Potions.Kinds[Name]
            if Need[Info.Kind] and Selected(Name) and not (Info.Buff and BuffActive(Info.Buff))
                and Potions.Amount(Name) > 0 then
                return Name
            end
        end
        return nil
    end

    -- ดื่ม 1 ขวด: ไม่อยู่ใน Toolbar = ใส่ช่องว่าง (ไม่มี = ยืมช่อง Five แล้วคืนของเดิม)
    function Potions.Drink(Name)
        if Potions.Busy or not (Utility and SignalEvent and PlatformHandler) then return false end
        local Inv = Inventory()
        local Folder = Inv and Inv.Inventory:FindFirstChild(Name)
        local IdValue = Folder and Folder:FindFirstChild("Id")
        local Items = LocalPlayer:FindFirstChild("Items_Config")
        local Equipped = Items and Items:FindFirstChild("Equipped")
        if not (IdValue and Equipped) then return false end
        local Id, Toolbar = IdValue.Value, Inv.Toolbar

        local function SlotValue(Slot) local Value = Toolbar:FindFirstChild(Slot) return Value and Value.Value end
        local function Place(Slot, Value)
            pcall(SignalEvent.ToServer, "Toolbar_Equip", Slot, Value)
            return Farm.WaitFor(function() return SlotValue(Slot) == Value end, 1.5)
        end

        local Slot, Borrowed = nil, nil
        for _, Name2 in ipairs(Slots) do if SlotValue(Name2) == Id then Slot = Name2 end end
        if not Slot then
            for _, Name2 in ipairs(Slots) do if SlotValue(Name2) == 0 then Slot = Name2 break end end
            if not Slot then Slot, Borrowed = "Five", SlotValue("Five") end
            if not Place(Slot, Id) then return false end
        end

        local Before = Potions.Amount(Name)
        local Retreat = Fighter.Continue ~= nil or Movement.Active()
        -- ดื่มยาสำคัญสุด: จองบังคับ ท่าอื่นทั้งหมด (หลบ/สกิล/สลับ/กัน/M1) เห็นแล้วหยุด
        HubAction.Force("Potion", 15)
        Potions.Busy = true
        -- สกิลที่เงื้อค้างอยู่ปล่อยให้จบก่อน (ไม่งั้นท่าตัดการดื่ม)
        Farm.WaitFor(function() return not Fighter.Casting() end, 5)
        Farm.SwapLock = true
        Fighter.SkillBusy = os.clock()
        local Previous = Equipped.Value
        local Drank = false

        pcall(function()
            -- ฟาร์มอยู่ = ถอยไปยืนบนพื้นห่างมอนก่อนค่อยดื่ม แล้วฟาร์มกลับไปตีที่เดิมเอง
            if Retreat then
                local Spot = Movement.SafeGroundSpot(Potions.RetreatDistance)
                if Spot then
                    Potions.Status = "Retreating to drink " .. Name
                    Fighter.AttackTarget = nil
                    Movement.Hold(Spot)
                    task.wait(0.4)   -- ให้เซิร์ฟเห็นตำแหน่งใหม่ก่อน
                end
            end

            local Index = table.find(Slots, Slot)
            local function Holding()
                local Character = LocalPlayer.Character
                return Character and Character:FindFirstChild("CapWeld", true) ~= nil
            end
            Equipped.Value = Index
            if not Farm.WaitFor(Holding, 1.5) then
                Equipped.Value = 0
                task.wait(0.3)
                Place(Slot, 0)
                Place(Slot, Id)
                Equipped.Value = Index
                if not Farm.WaitFor(Holding, 1.5) then return end
            end

            Potions.Status = "Drinking " .. Name
            pcall(SignalEvent.ToServer, "Tool_Mouse", "Down", PlatformHandler.mousepos(nil, nil))
            Drank = Farm.WaitFor(function() return Potions.Amount(Name) < Before end, 3.5)
            pcall(SignalEvent.ToServer, "Tool_Mouse", "Up", PlatformHandler.mousepos(nil, nil))
        end)

        Movement.Hold(nil)
        Equipped.Value = Previous ~= table.find(Slots, Slot) and Previous or 0
        if Borrowed and Borrowed ~= 0 then Place(Slot, Borrowed) end
        Farm.SwapLock = false
        Fighter.SkillBusy = nil
        Potions.Busy = false
        HubAction.Release("Potion")

        if Drank then
            Potions.Last = Name .. " (" .. (Before - 1) .. " left)"
            Potions.Status = "Drank " .. Name
        else
            Potions.Status = "Could not drink " .. Name
        end
        return Drank
    end

    -- ร้านใน place นี้ที่ขายของชื่อนี้ (prompt Purchase) -> ตำแหน่ง PromptPart
    -- ไม่เจอ = จำไว้ 30 วิ (สแกนทั้งแมพหนัก ลูปสถานะเรียกทุกวิ)
    local ShopCache, NoShopUntil = { }, { }
    function Potions.FindShop(Name)
        local Cached = ShopCache[Name]
        if Cached and Cached.Parent then return Cached.Position end
        if os.clock() < (NoShopUntil[Name] or 0) then return nil end
        NoShopUntil[Name] = os.clock() + 30
        local Regions = workspace:FindFirstChild("Debree") and workspace.Debree:FindFirstChild("Regions")
        for _, Object in ipairs((Regions or workspace):GetDescendants()) do
            if Object:IsA("ProximityPrompt") and Object.ActionText == "Purchase" and Object.ObjectText == Name
                and Object.Parent and Object.Parent:IsA("BasePart") then
                ShopCache[Name] = Object.Parent
                return Object.Parent.Position
            end
        end
        return nil
    end

    -- ยาที่เลือกไว้แต่หมด + มีร้านใน place นี้ + เงินพอสักขวด
    function Potions.WantToBuy()
        if not Shop then return nil end
        for _, Name in ipairs(Potions.Order) do
            if Selected(Name) and Potions.Amount(Name) == 0 and Potions.FindShop(Name) then
                local Ok, Can = pcall(Shop.CanBuy, LocalPlayer, Name, nil, 1)
                if Ok and Can then return Name end
            end
        end
        return nil
    end

    function Potions.BuyDue()
        local Config = getgenv().ConfigurationTable
        return Config.AutoBuyPotion == true and not Potions.Buying and os.clock() >= Potions.NextBuyAt
            and not InTrialPlace and Potions.WantToBuy() ~= nil
    end

    -- บินไปร้าน ซื้อ แล้วปล่อยให้ลูปที่เรียกบินกลับเอง (แบบเดียวกับ Seller.Run)
    function Potions.Buy(ShouldContinue)
        if Potions.Buying then return false end
        Potions.NextBuyAt = os.clock() + 20
        local Name = Potions.WantToBuy()
        local At = Name and Potions.FindShop(Name)
        if not At then return false end

        local Config = getgenv().ConfigurationTable
        ShouldContinue = ShouldContinue or function() return true end
        local function Continue()
            return getgenv().ValkyrieSession == SessionToken and Config.AutoBuyPotion == true and ShouldContinue()
        end

        Potions.Buying = true
        Potions.Status = "Going to buy " .. Name
        Fighter.AttackTarget = nil
        Movement.Lock(nil)

        local Bought = false
        pcall(function()
            local Stand = CFrame.new(At + Vector3.new(0, 3, 0))
            Movement.Go(Stand, 3, 60, Continue)
            local Root = Movement.GetRoot()
            if not (Continue() and Root and (Root.Position - At).Magnitude <= 10) then return end

            Movement.Lock(Stand)
            Farm.Sleep(0.5, Continue)   -- ให้เซิร์ฟเห็นตำแหน่งก่อน (ซื้อจากไกลเซิร์ฟเงียบ)

            -- เงินไม่พอตามจำนวนที่ตั้ง = ลดลงจนซื้อได้
            local Amount = math.clamp(math.floor(tonumber(Config.BuyPotionAmount) or 5), 1, 50)
            while Amount > 1 do
                local Ok, Can = pcall(Shop.CanBuy, LocalPlayer, Name, nil, Shop.SanitizeAmount(Amount))
                if Ok and Can then break end
                Amount = Amount - 1
            end

            local Before = Potions.Amount(Name)
            pcall(SignalEvent.ToServer, "PurchaseFromShop", Name, Shop.SanitizeAmount(Amount))
            Bought = Farm.WaitFor(function() return Potions.Amount(Name) > Before end, 3, Continue)
            if Bought then Potions.Last = "Bought " .. (Potions.Amount(Name) - Before) .. "x " .. Name end
        end)

        Movement.Lock(nil)
        Potions.Buying = false
        Potions.Status = Bought and "Bought " .. Name or "Could not buy " .. Name
        return Bought
    end

    -- ลูปดื่ม (ทุกโหมด) - รอ Smart Weapon สลับเสร็จก่อน (SwapLock) ดื่มแล้วพัก 1 วิ
    task.spawn(function()
        while getgenv().ValkyrieSession == SessionToken do
            task.wait()
            local Config = getgenv().ConfigurationTable
            if Config.AutoDrinkPotion and not Potions.Busy and not Farm.SwapLock then
                local Ok, Name = pcall(Potions.Pick)
                if Ok and Name then
                    pcall(Potions.Drink, Name)
                    task.wait(1)
                end
            end
        end
    end)

    -- ไม่มีฟาร์มรัน = ไปซื้อเอง / มีฟาร์ม = ลูปฟาร์มเรียก Potions.Buy ตอนว่างระหว่างตัว
    task.spawn(function()
        while getgenv().ValkyrieSession == SessionToken do
            task.wait()
            if Fighter.Continue == nil and not Seller.Busy and Potions.BuyDue() then
                pcall(Potions.Buy)
            end
        end
    end)
end

do
    local Runner = {
        Active = false,
        Thread = nil,
        Mode = "Level",     -- "Level" = Auto Farm ตาม LevelConfig / "Mob" / "Boss" = เลือกตัวเองจาก dropdown
    }

    -- โหมด -> key ใน ConfigurationTable (เปิดอยู่ไหม / รับเควสไหม / ชื่อมอนที่เลือก) + Flag ของ toggle
    -- Suffix = คำต่อท้ายชื่อคีย์ตั้งค่าที่แยกต่อโหมด (FarmWeapon<Suffix> ฯลฯ อ่านผ่าน ModeSetting)
    -- Camp = แท็บ Sealed Cache Raid (Raid Settings) ใช้คีย์ต่อท้าย "Raid"
    local ModeKeys = {
        Level = { Enabled = "AutoFarm", Quest = "AutoAcceptQuest", Flag = "SL2AutoFarm", Suffix = "Level" },
        Mob = { Enabled = "AutoFarmMob", Quest = "MobAcceptQuest", Name = "FarmMobName", Names = "FarmMobNames", Flag = "SL2AutoFarmMob", Suffix = "Mob" },
        Boss = { Enabled = "AutoFarmBoss", Quest = "BossAcceptQuest", Name = "FarmBossName", Names = "FarmBossNames", Flag = "SL2AutoFarmBoss", Suffix = "Boss" },
        -- Hunt = ตีบอสของ Boss Hunt ที่รับอยู่ (HuntTargets ตัวจัดการ Hunt เขียนเองตอนรัน ไม่ได้เลือกจาก UI)
        Hunt = { Enabled = "AutoBossHunt", Names = "HuntTargets", Flag = "SL2AutoBossHunt", Suffix = "Hunt" },
        Camp = { Enabled = "AutoRaidCache", Flag = "SL2AutoRaidCache", Suffix = "Raid" },
    }

    -- BossWaiting / BossReadyIn / NoteAbsentBosses ประกาศตัวจริงข้างล่าง (ต้องใช้ BossReadyAt ที่อยู่ตรงนั้น)
    -- ประกาศชื่อไว้ก่อนให้ GetModeEntry เรียกได้
    local BossWaiting, BossReadyIn, NoteAbsentBosses, BossProbeOrder

    -- เป้าของโหมดปัจจุบัน: Level = ตามเลเวล (GetLevelEntry) / Mob, Boss = เลือกได้หลายตัวจาก dropdown
    -- เลือกหลายตัว: ตัวที่ล็อกอยู่ยังมีมอนโหลดอยู่ = ตีต่อ (ไม่สลับไปมาจนรีเซ็ต state) / ไม่งั้นเอาตัวที่มีมอน
    -- ใกล้สุด / ไม่มีตัวไหนโหลดเลย = ตัวที่ไม่ติดคูลดาวน์ที่จุดเกิดใกล้สุด (ไม่ใช่ตามลำดับในลิสต์)
    -- ทุกตัวติดคูลดาวน์ = ตัวที่จะเกิดเร็วสุด (ของเดิมเอาตัวแรกในลิสต์ = ไปยืนรอตัวที่อาจอีกนานแทน)
    local function GetModeEntry()
        local Keys = ModeKeys[Runner.Mode]
        if not (Keys and Keys.Names) then
            return Farm.GetLevelEntry()
        end

        local Names = getgenv().ConfigurationTable[Keys.Names]
        if type(Names) ~= "table" or #Names == 0 then return nil end

        local Root = Movement.GetRoot()
        local Current = Farm.ConfigFarm.Entry

        Farm.ConfigFarm.Probe = false

        -- ล็อกบอสตัวที่ตีอยู่: ไม่เปลี่ยนตัวจนกว่าเกมบอกว่าตัวนี้ติด cooldown (= ตายแล้ว) - ระหว่างหลบลอยไกล
        -- โมเดลหลุด streaming ก็ยังตัวเดิม (ของเดิมเช็คจากโมเดลที่เห็น หลุดเมื่อไหร่ไปเลือกตัวใกล้สุดใหม่ = ตีมั่ว)
        local Lock = Farm.ConfigFarm.BossLock
        if Lock then
            if table.find(Names, Lock) and not BossWaiting(Lock) then
                local Entry = Farm.GetEntryByName(Lock)
                if Entry then return Entry end
            end
            Farm.ConfigFarm.BossLock = nil
        end

        if Root then
            -- ตีทีละตัว: ตัวที่ล็อกไว้ยังไม่ตาย (โมเดลยังโหลดอยู่ ระหว่างหลบลอยไกล ๆ ก็ด้วย) = ตีต่อจนตาย
            if Current and table.find(Names, Current.MonName)
                and Farm.GetNearestMobByName(Root.Position, Current.MonName) then
                return Current
            end

            local Best, BestDistance = nil, math.huge
            for _, Name in ipairs(Names) do
                local Mob, Distance = Farm.GetNearestMobByName(Root.Position, Name)
                if Mob and Distance < BestDistance then
                    Best, BestDistance = Name, Distance
                end
            end
            if Best then return Farm.GetEntryByName(Best) end

            NoteAbsentBosses(Names, Root)
        end

        local Ready, ReadyDistance = nil, math.huge
        local Soonest, SoonestIn = nil, math.huge
        for _, Name in ipairs(Names) do
            local Entry = Farm.GetEntryByName(Name)
            if Entry then
                if not BossWaiting(Name) then
                    local Spawn = Entry.WaitPOS or Entry.MonPOS
                    local Distance = (Root and Spawn) and (Spawn - Root.Position).Magnitude or 0
                    if Distance < ReadyDistance then Ready, ReadyDistance = Entry, Distance end
                else
                    local In = BossReadyIn(Name)
                    if In < SoonestIn then Soonest, SoonestIn = Entry, In end
                end
            end
        end

        if Ready then return Ready end

        -- ไม่มีตัวไหนให้ตี: TP ไล่เช็คจุดเกิดตัวที่ไม่รู้ว่าตายตอนไหน (คนอื่นฆ่า) ตัวที่เช็คนานสุดก่อน
        -- ตัวที่เราฆ่าเอง (รู้เวลาเกิดแน่) / บอสกลางคืนตอนกลางวัน ไม่ต้องเช็ค รอเวลาเฉย ๆ
        local Probe = BossProbeOrder(Names)
        if Probe then
            Farm.ConfigFarm.Probe = true
            return Probe
        end

        return Soonest or Farm.GetEntryByName(Names[1])
    end

    local function ResetFarmState()
        Farm.ConfigFarm.Entry = nil
        Farm.ConfigFarm.Mob = nil
        Farm.ConfigFarm.ComboStart = 0
        Farm.ConfigFarm.BossLock = nil
    end

    local function ShouldRun()
        return getgenv().ValkyrieSession == SessionToken and Runner.Active
    end

    -- เก็บกล่อง/ของดรอปก่อนเสมอถ้าอยู่ในระยะ (ลำดับความสำคัญสูงสุด กันของหมดเวลา/โดนคนอื่นเก็บ)
    -- อ่านค่า Auto Collect Chest / Collect Radius ของโหมดที่กำลังรันอยู่ (แต่ละแท็บตั้งแยกกัน)
    -- GetTagged + ไล่หา prompt ทุกชิ้นหนักเกินจะทำทุกเฟรม - กวาดทุก PickupScanEvery วิพอ
    -- (เก็บได้ 1 ชิ้นแล้วกวาดใหม่ทันทีรอบหน้า ของที่กองอยู่ด้วยกันไม่ต้องรอ)
    -- กำลังหนีสกิลมอนอยู่ = ไม่วิ่งไปเก็บ (ทิ้งจุดหลบไปยืนกลางท่า)
    local NextPickupScan = 0
    local PickupScanEvery = 0.4

    local function TryCollectDrops(Root)
        if not ModeSetting("AutoCollectDrops") or Fighter.Escaping() then return false end
        if os.clock() < NextPickupScan then return false end
        NextPickupScan = os.clock() + PickupScanEvery

        local Pickup, PickupDistance = Farm.GetNearestAnyPickup(Root.Position)
        local Radius = tonumber(ModeSetting("CollectRadius")) or 60
        if not Pickup or PickupDistance > Radius then return false end

        Movement.Lock(nil)
        Movement.Go(Pickup.Position, 5, 15, ShouldRun)
        Farm.CollectPickup(Pickup)

        -- รอจน prompt ปิด/ของหาย (เก็บติดจริง) แทนรอตายตัว - ไม่ติดก็ไม่ค้างเกินครึ่งวิ
        local Deadline = os.clock() + 0.5
        while ShouldRun() and os.clock() < Deadline and Pickup.Instance.Parent and Pickup.Prompt.Enabled do
            task.wait()
        end

        NextPickupScan = 0
        return true
    end

    -- toggle Auto Accept Quest ของโหมดที่รันอยู่ (แต่ละ section มีของตัวเอง)
    local function AcceptQuestEnabled()
        if Runner.Mode == "Boss" then return false end   -- Farm Boss ไม่รับเควส (ลบ toggle ออกแล้ว)
        local Keys = ModeKeys[Runner.Mode] or ModeKeys.Level
        return getgenv().ConfigurationTable[Keys.Quest] == true
    end

    -- เปิด Auto Accept Quest = เควสเป็นเงื่อนไขบังคับก่อนฟาร์ม (รับไม่ได้ = ไม่ฟาร์ม, มอนตัวไหนหาเควส
    -- ที่ผูกไว้ไม่เจอก็ไม่ฟาร์ม) / ปิด = ไม่รับเควสเลย ปล่อยผ่านไปฟาร์มมอนตรง ๆ
    -- ยิง AddQuest ไม่ผ่าน = เว้นช่วงก่อนยิงใหม่ (กันยิง remote ทุกเฟรม)
    local QuestRetryAt = 0
    local QuestRetryGap = 1

    local function EnsureQuestAccepted(Entry)
        if not AcceptQuestEnabled() then return true end

        local QuestId, InstanceName = Farm.FindQuestIdForMob(Entry.QuestName, Entry.MonName)
        -- มอนนี้ไม่มีเควสให้รับ = ฟาร์มเลย (ของเดิมคืน false = ไม่ฟาร์มมอนที่ไม่มีเควสเลยถ้าเปิด Auto Accept Quest)
        if not QuestId then
            return true
        end

        -- เควสที่เลเวล/race ไม่ผ่าน (เช่นเฉพาะหน่วย Slayer) รับไม่ได้แน่ ๆ - ฟาร์มมอนเปล่า ๆ ไปเลย ไม่วนรอที่ NPC
        if not Farm.QuestAllowed(QuestId) then return true end

        if InstanceName and Farm.IsQuestActive(InstanceName) then return true end

        Movement.Lock(nil)

        if Entry.QuestPOS or Entry.MonPOS then
            Movement.Go(Entry.QuestPOS or Entry.MonPOS, 5, 20, ShouldRun)
        end

        -- server ปฏิเสธ/ติด cooldown = เว้น QuestRetryGap ก่อนยิงใหม่ (จับเวลา ไม่หยุดลูป - ลูปยังวนทุกเฟรม)
        if os.clock() < QuestRetryAt then return false end

        local Accepted = Farm.TryAcceptQuestForMob(Entry.QuestName, Entry.MonName)
        if not Accepted then
            QuestRetryAt = os.clock() + QuestRetryGap
        end
        return Accepted
    end

    -- เควสของเป้านี้จบแล้ว (ไม่ได้ถือ) และรับใหม่ได้ทันที = เลิกตีตัวที่ตีอยู่ ไปรับก่อน
    -- วัดสด 2026-09-30 (Hoyuzo Subordinate): มอนตัวที่ปิดเควสตายพร้อมเควสหายจากข้อมูล ลูปนอกยังเห็นว่าถือเควสอยู่
    -- เลยล็อกมอนตัวถัดไปตีจนตาย (~20 วิ) ค่อยไปรับ = เสียเวลา ~23 วิทุกรอบ
    -- รับได้ = Quests.CanAddQuest ผ่าน (เกมกัน QuestCD 30 วินับจากรับครั้งก่อน - ยังไม่พ้นก็ตีต่อไปก่อน)
    local QuestReadyCache = { At = 0, Entry = nil, Ready = false }

    local function QuestReadyToTake(Entry)
        if not (Entry and AcceptQuestEnabled()) then return false end
        local Cache = QuestReadyCache
        if Cache.Entry == Entry and os.clock() - Cache.At < 0.25 then return Cache.Ready end

        local QuestId, InstanceName = Farm.FindQuestIdForMob(Entry.QuestName, Entry.MonName)
        local Ready = QuestId ~= nil and InstanceName ~= nil and Farm.QuestAllowed(QuestId)
            and not Farm.IsQuestActive(InstanceName) and Farm.CanTakeQuest(QuestId, InstanceName)
        Cache.At, Cache.Entry, Cache.Ready = os.clock(), Entry, Ready == true
        return Cache.Ready
    end

    local FightMob = Fighter.FightMob

    --// รอบอสเกิดใหม่
    --
    -- BossReadyAt[MonName] = os.clock() ที่ควรกลับไปจุดบอส - ก่อนหน้านั้นไปตีอย่างอื่นรอ (DoFiller)
    -- ฆ่าบอสเอง = รู้เวลาตายแน่นอน ตั้ง = ตาย + SpawnTime จริง - BossEarly (กลับไปรอก่อนเกิดนิดนึง)
    -- ไปถึงจุดแล้วไม่เจอบอส (ไม่รู้ว่าตายตอนไหน) = ออกไปตีอย่างอื่นแล้วกลับมาเช็คใหม่ทุก BossRecheck
    local BossReadyAt = { }
    local BossEarly = 5
    local BossRecheck = 45       -- ไม่รู้ว่าตายตอนไหน (คนอื่นฆ่า) - บอสเกิดระหว่างนี้ในระยะ streaming ก็เห็นเองอยู่แล้ว

    local BossKnown = { }        -- [ชื่อ] = true ถ้า BossReadyAt มาจากที่เราฆ่าเอง (เวลาเกิดแม่น) ไม่ใช่แค่ไปแล้วไม่เจอ

    -- ติด cooldown ไหม: ใช้ข้อมูลจากเกม (Farm.BossCooldown) ก่อนเสมอ - ไม่มีข้อมูลค่อยใช้เวลาที่เดาเอง
    -- (ไปถึงจุดแล้วไม่เจอทั้งที่เกมบอกว่าเกิดอยู่ = MarkAbsent พักไว้ BossRecheck กันยืนรอค้าง)
    function BossWaiting(MonName)
        if Farm.NightOnlyWaiting(MonName) then return true end
        local Cooldown = Farm.BossCooldown(MonName)
        if Cooldown ~= nil then
            return Cooldown > 0 or (not BossKnown[MonName] and os.clock() < (BossReadyAt[MonName] or 0))
        end
        return os.clock() < (BossReadyAt[MonName] or 0)
    end

    local function MarkAbsent(MonName)
        BossReadyAt[MonName] = os.clock() + BossRecheck
        BossKnown[MonName] = nil
    end

    -- บอสที่ควร TP ไปเช็ค: ไม่รู้เวลาตาย + ไม่ใช่บอสกลางคืนตอนกลางวัน - เอาตัวที่เช็คล่าสุดนานสุด
    function BossProbeOrder(Names)
        local Best, BestAt = nil, math.huge
        for _, Name in ipairs(Names) do
            -- เกมบอก cooldown ให้แล้ว (Farm.BossCooldown) = รู้สถานะอยู่แล้ว ไม่ต้อง TP ไปเช็ค
            local Entry = Farm.IsBossName(Name) and not BossKnown[Name] and Farm.BossCooldown(Name) == nil
                and not Farm.NightOnlyWaiting(Name) and Farm.GetEntryByName(Name)
            if Entry and (BossReadyAt[Name] or 0) < BestAt then
                Best, BestAt = Entry, BossReadyAt[Name] or 0
            end
        end
        return Best
    end

    -- อีกกี่วิถึงควรกลับไปเช็คบอสตัวนี้ (บอสกลางคืนตอนกลางวัน = ถึงกลางคืน)
    function BossReadyIn(MonName)
        local In = Farm.BossCooldown(MonName) or ((BossReadyAt[MonName] or 0) - os.clock())
        local Night, NightIn = Farm.NightOnlyWaiting(MonName)
        if Night then In = math.max(In, tonumber(NightIn) or math.huge) end
        return math.max(In, 0)
    end

    --// ดูบอสตายจากระยะไกลด้วย streaming: โมเดล NPC โหลดมาให้ไกลถึง ~1100 studs (วัดสด) - ยืนอยู่ในระยะ
    -- AbsentRadius ของจุดเกิดนานพอให้โหลดทัน (AbsentSettle) แล้วไม่เห็นบอส = ตายอยู่ ติดคูลดาวน์ไว้เลย
    -- ไม่ต้องบินไปยืนเช็คถึงจุด (ของเดิมบินไปทีละตัวตามลำดับลิสต์ ถึงแล้วค่อยรู้ว่าไม่มี)
    local AbsentRadius = 600
    local AbsentSettle = 2
    local NearSince = { }

    function NoteAbsentBosses(Names, Root)
        for _, Name in ipairs(Names) do
            local Entry = Farm.IsBossName(Name) and Farm.GetEntryByName(Name)
            local Spawn = Entry and (Entry.WaitPOS or Entry.MonPOS)
            if Spawn and (Spawn - Root.Position).Magnitude <= AbsentRadius then
                NearSince[Name] = NearSince[Name] or os.clock()
                if os.clock() - NearSince[Name] >= AbsentSettle and not BossWaiting(Name)
                    and #Farm.GetMobsByName(Name) == 0 then
                    MarkAbsent(Name)
                end
            else
                NearSince[Name] = nil
            end
        end
    end

    -- ระหว่างรอบอส: ตีมอนด่านก่อนหน้า + รับเควสของด่านนั้นด้วย (ได้ EXP เควสเพิ่ม)
    -- เควส Combat ถือได้ทีละ 1 - ถ้ายังถือเควสบอสอยู่ (ยังไม่ได้ฆ่า) ไม่ทิ้ง ตีเปล่าไปก่อน
    -- ติด cooldown รับเควส (30 วิ) ก็ตีเปล่าไปก่อนเหมือนกัน ไม่บินวนไปหา NPC ซ้ำ ๆ
    -- ตอนบอสใกล้เกิด EnsureQuestAccepted(บอส) ทิ้งเควสด่านก่อนหน้าให้เอง (TryAcceptQuestForMob)
    -- ทำทีละ 1 ขั้นแล้วคืนให้ลูปหลักเช็คบอสใหม่
    local FillerMob = nil

    local function DoFiller(Entry, Root)
        local function StillWaiting()
            return ShouldRun() and BossWaiting(Entry.MonName)
        end

        local Previous = Farm.GetPreviousEntry(Entry)
        if Previous then
            local QuestId, InstanceName = Farm.FindQuestIdForMob(Previous.QuestName, Previous.MonName)
            local _, BossInstance = Farm.FindQuestIdForMob(Entry.QuestName, Entry.MonName)

            if AcceptQuestEnabled() and QuestId and Farm.QuestAllowed(QuestId)
                and not (InstanceName and Farm.IsQuestActive(InstanceName))
                and Farm.CanTakeQuest(QuestId, BossInstance) then
                EnsureQuestAccepted(Previous)
                return
            end

            -- ตีทีละตัวจนตาย (เหมือนลูปหลัก) - ไม่เลือกตัวใกล้สุดใหม่ทุกเฟรม
            local Mob = FillerMob
            if not (Farm.IsMobAlive(Mob) and (Mob.Model.Name:gsub("%d+$", "")) == Previous.MonName) then
                Mob = Farm.GetNearestMobByName(Root.Position, Previous.MonName)
                FillerMob = Mob
            end
            if Mob then
                FightMob(Mob, Root)
                return
            end

            local WaitAt = Previous.WaitPOS or Previous.MonPOS
            if WaitAt then
                Movement.Lock(nil)
                Movement.Go(WaitAt, 5, 20, function()
                    return StillWaiting() and #Farm.GetMobsByName(Previous.MonName) == 0
                end)
                return
            end
        end

        Movement.Lock(nil)
        task.wait()
    end

    --// เควสเนื้อเรื่องปลดล็อก Chaka (Lv 26/34)
    --
    -- บทพูด Chaka (Dialogues.Yap.Chaka) ไม่ยอมให้เควสจนกว่า "Ill get this letter delivered" จะ Done
    -- สาย: Kazu ฆ่าสปาย 4 ตัว (ได้ Suspicious Note) -> Kazu รับเควสเอาโน้ตไปให้ Noote -> คุย Noote
    --      -> Noote ให้จดหมาย (Letter) -> ส่งจดหมายให้ Chaka
    -- ถึง Level RequiredLevel เมื่อไหร่ทำสายนี้ให้จบก่อน แล้วกลับไปฟาร์มตาม LevelConfig ต่อ
    local Story = {
        RequiredLevel = 26,

        SpyQuest = "Ill help clear them out",
        SpyMob = "*Civilian*",                             -- สปายปลอมตัวเป็นชาวบ้าน (code VillageSpy)
        SpyPOS = Vector3.new(-687, 1260, -1103),           -- กลางจุดเกิดสปาย

        NotesQuest = "Ill bring him the notes",
        NotesTask = "Speak with Noote",

        LetterQuest = "Ill get this letter delivered",
        LetterTask = "Deliver the Letter to Chaka",

        KazuPOS = Vector3.new(-626, 1242, -1138),          -- Windy Peak
        NootePOS = Vector3.new(-515, 1243, -1251),         -- Windy Peak
        ChakaPOS = Vector3.new(471, 1146, -1260),          -- Bamboo Grove
    }

    local function GoTo(Position)
        Movement.Lock(nil)
        Movement.Go(Position, 5, 30, ShouldRun)
    end

    -- ทำสายเนื้อเรื่องทีละ 1 ขั้น - คืน true ถ้ายังทำอยู่ (ลูปหลักข้ามการฟาร์มรอบนี้), false ถ้าจบแล้ว/ยังไม่ถึงเลเวล
    local function DoStoryStep(Root)
        -- สายเนื้อเรื่องมีไว้ปลดล็อกเควส Chaka - ไม่รับเควสก็ไม่ต้องทำ / ทำเฉพาะโหมดฟาร์มตามเลเวล
        -- (Mob/Boss ผู้ใช้เลือกเป้าเอง ไม่ไปแย่งเวลาทำสายเนื้อเรื่องให้)
        if Runner.Mode ~= "Level" or not AcceptQuestEnabled() then return false end
        if Farm.GetLevel() < Story.RequiredLevel then return false end
        if Farm.GetQuestState(Story.LetterQuest) == "Done" then return false end

        -- 5) ถือจดหมายอยู่ -> ส่งให้ Chaka
        if Farm.GetQuestState(Story.LetterQuest) == "Doing" then
            GoTo(Story.ChakaPOS)
            Farm.QuestProgress(Story.LetterQuest, Story.LetterTask)
            -- รอเซิร์ฟปิดเควส (เช็คทุกเฟรม) ไม่ผ่านใน 1.5 วิ = รอบหน้ายิงใหม่
            Farm.WaitFor(function() return Farm.GetQuestState(Story.LetterQuest) ~= "Doing" end, 1.5, ShouldRun)
            return true
        end

        local NotesState = Farm.GetQuestState(Story.NotesQuest)

        -- 4) คุยกับ Noote แล้ว -> รับจดหมายจาก Noote (ใช้ Suspicious Note แลก)
        if NotesState == "Done" then
            GoTo(Story.NootePOS)
            Farm.AcceptQuestById(Story.LetterQuest)
            return true
        end

        -- 3) กำลังเอาโน้ตไปให้ Noote -> คุยกับ Noote
        if NotesState == "Doing" then
            GoTo(Story.NootePOS)
            Farm.QuestProgress(Story.NotesQuest, Story.NotesTask)
            Farm.WaitFor(function() return Farm.GetQuestState(Story.NotesQuest) ~= "Doing" end, 1.5, ShouldRun)
            return true
        end

        -- 2) ได้ Suspicious Note แล้ว (ฆ่าสปายครบ) -> รับเควสเอาโน้ตไปให้ Noote จาก Kazu
        if Farm.HasItem("Suspicious Note") then
            GoTo(Story.KazuPOS)
            Farm.AcceptQuestById(Story.NotesQuest)
            return true
        end

        -- 1b) ถือเควสฆ่าสปายอยู่ -> ตีสปาย
        if Farm.GetQuestState(Story.SpyQuest) == "Doing" then
            local Spy = Farm.GetNearestMobByName(Root.Position, Story.SpyMob)
            if Spy then
                FightMob(Spy, Root)
            else
                Movement.Lock(nil)
                Movement.Go(Story.SpyPOS, 5, 20, function()
                    return ShouldRun() and #Farm.GetMobsByName(Story.SpyMob) == 0
                end)
            end
            return true
        end

        -- 1a) เริ่มสาย -> รับเควสฆ่าสปายจาก Kazu
        -- ติด cooldown รับเควส (30 วิ) = เว้นช่วงก่อนยิงใหม่ (จับเวลา ไม่หยุดลูป)
        GoTo(Story.KazuPOS)
        if os.clock() >= QuestRetryAt and not Farm.AcceptQuestById(Story.SpyQuest) then
            QuestRetryAt = os.clock() + QuestRetryGap
        end
        return true
    end

    --// Raid Sealed Cache (โหมด "Camp")
    --
    -- ทีละ 1 ขั้น: เห็นการ์ดแคมป์ = ตี / กล่องปลดผนึกแล้ว = ไปเปิด + เก็บ LootDrop รอบ ๆ (CollectBossLoot)
    -- / กล่องยังล็อกแต่ไม่เห็นการ์ด (หลุด streaming) = บินไปที่กล่องให้การ์ดโผล่
    -- ไปถึงแล้วยังล็อกและไม่มีการ์ด = ข้ามกล่องนั้นไป CacheRecheck วิ (ไม่วนค้างอยู่ที่กล่องเดียว)
    -- / ไม่เห็นอะไรเลย (หลุด streaming) = บินไล่จุดเกิดกล่องที่ใกล้สุดที่ยังไม่ได้ดู จุดที่ไปดูแล้วว่าง
    -- พักไว้ SpawnRecheck วิ (กล่องเกิดใหม่ทุก ~25 นาทีแบบสุ่มจุด เลยต้องวนกลับมาดูซ้ำเรื่อย ๆ)
    local CacheSkipUntil = { }
    local CacheRecheck = 30
    local SpawnSkipUntil = { }
    local SpawnRecheck = 90
    local UnlockWaited = setmetatable({ }, { __mode = "k" })   -- os.clock() ที่รอปลดผนึกกล่องนี้ล่าสุด (กล่องเดิมเกิดใหม่ได้ เลยจับเวลาแทนธงถาวร)
    local UnlockWait = 3

    -- tier ที่เลือกใน dropdown (World > Sealed Cache Raid) อ่านสดทุกรอบ เปลี่ยนระหว่างรันได้เลย
    local function RaidTiers()
        local Saved = getgenv().ConfigurationTable.RaidCacheTiers
        local Tiers = { }
        if type(Saved) == "table" then
            for Tier, On in pairs(Saved) do
                if On == true then Tiers[Tier] = true end
            end
        end
        return Tiers
    end

    local function ScoutCacheSpawn(Root, Tiers)
        local Spawns = Farm.GetCacheInfo().Spawns
        local Target, TargetDistance = nil, math.huge
        for Index, Spawn in ipairs(Spawns) do
            local Distance = (Spawn.Position - Root.Position).Magnitude
            if Tiers[Spawn.Tier] and os.clock() >= (SpawnSkipUntil[Index] or 0) and Distance < TargetDistance then
                Target, TargetDistance = Index, Distance
            end
        end

        if not Target then
            task.wait()
            return
        end

        local Position = Spawns[Target].Position
        local function NothingLoaded()
            if not ShouldRun() or Farm.GetNearestCampMob(Position, Tiers) then return false end
            for _, Cache in ipairs(Farm.GetSealedCaches(Tiers)) do
                if Cache.Open or (not Cache.Opened and os.clock() >= (CacheSkipUntil[Cache.Instance] or 0)) then return false end
            end
            return true
        end

        Movement.Go(Position + Vector3.new(0, 5, 0), 10, 60, NothingLoaded)

        local Here = Movement.GetRoot()
        if Here and (Here.Position - Position).Magnitude <= 30 then
            Farm.Sleep(1, ShouldRun) -- รอ streaming โหลดกล่อง/การ์ดรอบจุดเข้ามา
            SpawnSkipUntil[Target] = os.clock() + SpawnRecheck
        end
    end

    -- Instant Kill ของแท็บ Sealed Cache Raid: ตีโดนแล้ว (ได้ network ownership) + เลือดต่ำกว่าเกณฑ์ = ฆ่าทันที
    local function RaidInstantKillReady(Mob)
        local Config = getgenv().ConfigurationTable
        if not Config.RaidInstantKill then return false end
        local Max = Mob.Humanoid and Mob.Humanoid.MaxHealth
        if not (Max and Max > 0) then return false end
        local Limit = math.min(tonumber(Config.RaidInstantKillHealth) or 90, 90)
        return Mob.Humanoid.Health / Max * 100 <= Limit
    end

    -- ได้ network ownership ของการ์ดเป็นช่วงสั้น ๆ หลังตีโดน (วัดสด: own สลับ true/false ทุกวิ) - เช็คแค่ตอน
    -- FightMob คืนค่าพลาดจังหวะ (การ์ด T3 ตีทั้งนาทีไม่ตาย) เลยเฝ้าทุกเฟรมระหว่างโหมด Camp แทน
    task.spawn(function()
        while getgenv().ValkyrieSession == SessionToken do
            if Runner.Active and Runner.Mode == "Camp" then
                local Mob = Farm.ConfigFarm.Mob
                if Mob and Farm.IsMobAlive(Mob) and RaidInstantKillReady(Mob) then
                    Farm.TryInstantKill(Mob)
                end
            end
            task.wait()
        end
    end)

    local function DoCampStep(Root)
        -- อาวุธจาก Select Weapon ของแท็บ Sealed Cache Raid (FarmWeaponRaid - suffix "Raid")
        local Weapon = ModeSetting("FarmWeapon")
        if type(Weapon) == "string" and Weapon ~= "" and Weapon ~= "None" then
            Farm.EquipWeapon(Weapon)
        end

        local Tiers = RaidTiers()
        if not next(Tiers) then
            -- ไม่ได้เลือก tier ไหนเลย - ยืนเฉย ๆ
            Movement.Lock(nil)
            task.wait()
            return
        end

        local Open, OpenDistance, Locked, LockedDistance = nil, math.huge, nil, math.huge
        for _, Cache in ipairs(Farm.GetSealedCaches(Tiers)) do
            local Distance = (Cache.Position - Root.Position).Magnitude
            -- เปิดไปแล้วแต่ของยังตกค้าง (เก็บโดนขัด) นับเป็นงานค้างที่ต้องเก็บให้จบเหมือนกล่องที่ยังไม่เปิด
            if (Cache.Open or (Cache.Opened and Farm.CacheLootLeft(Cache.Position))) and Distance < OpenDistance then
                Open, OpenDistance = Cache, Distance
            elseif not Cache.Open and not Cache.Opened and Distance < LockedDistance
                and os.clock() >= (CacheSkipUntil[Cache.Instance] or 0) then
                Locked, LockedDistance = Cache, Distance
            end
        end

        -- กล่องปลดผนึกแล้ว (ChestState = Spawned, prompt เปิด) = เปิดก่อนเสมอ ก่อนไปไล่ตีการ์ด
        -- ยืนยันสด: เคลียร์แคมป์เสร็จแล้วการ์ดของอีกแคมป์ (~250 studs) ยังโหลดค้างอยู่ ถ้าตีการ์ดก่อน
        -- จะบินหนีไปแคมป์นั้นทิ้งกล่องที่เปิดได้ไว้ / กด prompt แล้วกล่องเป็น Opened พ่น LootDrop 4 ชิ้นรอบ ๆ
        if Open then
            Movement.Lock(nil)
            Farm.ConfigFarm.ComboStart = 0

            Movement.Go(Open.Position + Vector3.new(0, 3, 0), 4, 30, ShouldRun)
            Farm.CollectCacheLoot(Open, ShouldRun)
            return
        end

        local Mob = Farm.GetNearestCampMob(Root.Position, Tiers)
        Farm.ConfigFarm.Mob = Mob

        -- เพิ่งเคลียร์แคมป์ตรงนี้ (กล่องข้าง ๆ ยังล็อก แต่การ์ดที่เหลืออยู่ไกลคนละแคมป์) - กล่องปลดผนึก
        -- ช้ากว่าการ์ดตัวสุดท้ายตายนิดนึง รอสักครู่ก่อนบินไปแคมป์อื่น ไม่งั้นทิ้งกล่องไว้
        if Mob and Locked and os.clock() - (UnlockWaited[Locked.Instance] or -math.huge) > 60
            and (Locked.Position - Root.Position).Magnitude <= 80
            and (Mob.Root.Position - Locked.Position).Magnitude > 150 then
            UnlockWaited[Locked.Instance] = os.clock()
            Movement.Lock(nil)

            local Deadline = os.clock() + UnlockWait
            while ShouldRun() and os.clock() < Deadline and not Locked.Prompt.Enabled do
                task.wait()
            end
            if Locked.Prompt.Enabled then return end -- รอบหน้าเข้าทาง Open เปิดกล่อง
        end

        if Mob then
            FightMob(Mob, Root)
            return
        end

        Movement.Lock(nil)
        Farm.ConfigFarm.ComboStart = 0

        if Locked then
            Movement.Go(Locked.Position + Vector3.new(0, 3, 0), 8, 30, function()
                return ShouldRun() and Farm.GetNearestCampMob(Locked.Position, Tiers) == nil
            end)

            local Here = Movement.GetRoot()
            if Here and (Here.Position - Locked.Position).Magnitude <= 20
                and not Farm.GetNearestCampMob(Here.Position, Tiers) and not Locked.Prompt.Enabled then
                Farm.WaitFor(function() -- เผื่อการ์ดกำลังเกิด/เพิ่งโหลดเข้ามา (เห็นเมื่อไหร่ไปต่อทันที)
                    return Farm.GetNearestCampMob(Here.Position, Tiers) ~= nil or Locked.Prompt.Enabled
                end, 2, ShouldRun)
                if not Farm.GetNearestCampMob(Here.Position, Tiers) and not Locked.Prompt.Enabled then
                    CacheSkipUntil[Locked.Instance] = os.clock() + CacheRecheck
                end
            end
        else
            ScoutCacheSpawn(Root, Tiers)
        end
    end

    --// ลำดับความสำคัญ (หน้า Priority - ผู้ใช้ 2026-10-02): เปิดหลายโหมดพร้อมกันได้ ตัวรันทำโหมดที่อยู่สูงสุด
    -- ที่ "มีงาน" ตอนนี้ / ไม่มีงาน (Hunt ไม่มีให้รับ / บอสที่เลือกติด cooldown หมด / แคมป์ว่างนาน) = ลงไปโหมดถัดไป
    -- สลับเฉพาะตอนว่างระหว่างตัว (ไม่ทิ้งมอนที่ตีอยู่) - Level / Mob มีงานเสมอ เป็นตัวรองรับ
    Farm.Runner = Runner    -- ดูสดผ่าน dex
    -- Fish = Auto Fishing (มีงานเสมอ - ตกรอบอสเกิดได้) / Sell, Potion = งานแทรก (ขาย/ซื้อยาตอนถึงรอบ) อยู่สูงกว่าโหมด
    -- ที่ทำอยู่ = แวะทำระหว่างตัว / อยู่ต่ำกว่า = รอจนโหมดที่สูงกว่าว่าง
    Runner.Default = { "Potion", "Sell", "Hunt", "Boss", "Camp", "Mob", "Level", "Fish" }
    Runner.Labels = { Hunt = "Boss Hunt", Boss = "Farm Boss", Camp = "Sealed Cache Raid", Mob = "Farm Mob", Level = "Farm Level",
        Fish = "Auto Fishing", Sell = "Auto Sell", Potion = "Buy Potions" }
    Runner.Errands = { Sell = true, Potion = true }
    Runner.IdleUntil = { }
    Runner.IdleAfter = 45       -- Hunt/Boss/Raid ไม่มีอะไรให้ตีนานเท่านี้ = พักโหมดนี้ไว้ IdleFor วิ
    Runner.IdleFor = 60
    Runner.WorkAt = 0

    function Runner.Order()
        local Saved = getgenv().ConfigurationTable.FarmPriority
        local List, Seen = { }, { }
        for _, Mode in ipairs(type(Saved) == "table" and Saved or { }) do
            if Runner.Labels[Mode] and not Seen[Mode] then Seen[Mode] = true table.insert(List, Mode) end
        end
        -- เซฟเก่าที่ยังไม่มีบางตัว (เพิ่ม Fish / Sell / Potion ทีหลัง) = แทรกตามตำแหน่งค่าเริ่มต้น
        for Index, Mode in ipairs(Runner.Default) do
            if not Seen[Mode] then table.insert(List, math.min(Index, #List + 1), Mode) end
        end
        return List
    end

    function Runner.Enabled(Mode)
        if Mode == "Fish" then return getgenv().ConfigurationTable.AutoFishing == true end
        local Keys = ModeKeys[Mode]
        return Keys ~= nil and getgenv().ConfigurationTable[Keys.Enabled] == true
    end

    -- เปิดโหมดฟาร์ม (ที่ขยับตัวไปตี) อยู่สักตัวไหม (ไม่นับ Auto Fishing)
    function Runner.AnyFarm()
        for Mode in pairs(ModeKeys) do
            if Runner.Enabled(Mode) then return true end
        end
        return false
    end

    -- A อยู่สูงกว่า B ในหน้า Priority
    function Runner.Before(A, B)
        local Order = Runner.Order()
        return (table.find(Order, A) or 99) < (table.find(Order, B) or 99)
    end

    -- โหมดนี้มีงานตอนนี้ไหม (+ เหตุผลถ้าไม่มี)
    function Runner.Ready(Mode)
        if Mode == "Fish" then return true end
        local Keys = ModeKeys[Mode]
        if not Keys then return false, "unknown" end
        if os.clock() < (Runner.IdleUntil[Mode] or 0) then return false, "nothing found - checking again soon" end
        if Mode == "Hunt" then
            if Farm.HuntReady then return Farm.HuntReady() end
            return true
        elseif Mode == "Camp" then
            if next(RaidTiers()) == nil then return false, "no cache tier picked" end
            return true
        elseif Keys.Names then
            local Names = getgenv().ConfigurationTable[Keys.Names]
            if type(Names) ~= "table" or #Names == 0 then return false, "nothing selected" end
            if Mode == "Boss" then
                local Soonest = math.huge
                for _, Name in ipairs(Names) do
                    if not BossWaiting(Name) then return true end
                    Soonest = math.min(Soonest, BossReadyIn(Name))
                end
                if Soonest < math.huge then
                    return false, string.format("respawn in %d:%02d", Soonest // 60, math.floor(Soonest % 60))
                end
                return false, "bosses on cooldown"
            end
        end
        return true
    end

    -- โหมดที่ควรทำตอนนี้ = ตัวบนสุดที่เปิดและมีงาน / ไม่มีตัวไหนมีงาน = ตัวบนสุดที่เปิด (รอที่จุดเกิดแบบเดิม)
    function Runner.Pick()
        local Fallback = nil
        for _, Mode in ipairs(Runner.Order()) do
            if not Runner.Errands[Mode] and Runner.Enabled(Mode) then
                Fallback = Fallback or Mode
                if Runner.Ready(Mode) then return Mode end
            end
        end
        return Fallback
    end

    function Runner.Switch(Mode)
        if not Mode or Mode == Runner.Mode then return end
        Runner.Mode = Mode
        Runner.WorkAt = os.clock()
        getgenv().ValkyrieFarmSuffix = ModeKeys[Mode] and ModeKeys[Mode].Suffix or ""
        Farm.ConfigFarm.BossLock = nil
        pcall(ResetFarmState)
        pcall(Movement.Lock, nil)
    end

    -- ตาของ Auto Fishing ไหม: ไม่มีโหมดฟาร์มรัน / Priority เลือก Fish (โหมดฟาร์มที่สูงกว่าไม่มีงาน)
    function Farm.FishTurn()
        return not (Runner.Active and Runner.Thread) or Runner.Mode == "Fish"
    end

    local function RunFarm()
        local Farmer = Farm.ConfigFarm
        Farmer.Running = true
        ResetFarmState()

        -- ตัวตี (Fighter) ใช้ร่วมกับ Auto Trial - บอกมันว่าตอนนี้ใครเป็นคนคุมอยู่
        Fighter.Continue = ShouldRun

        while ShouldRun() do
            task.wait()

            -- เลเวลตัน = ปิดแค่ Farm Level (โหมดอื่นที่เปิดอยู่ทำต่อตาม Priority)
            if Runner.Mode == "Level" and Farm.IsMaxLevel() then
                getgenv().ConfigurationTable.AutoFarm = false
                local Next = not Runner.Borrowed and Runner.Pick() or nil
                if Next then Runner.Switch(Next) end
                local Set = Library.SetFlags and Library.SetFlags.SL2AutoFarm
                if Set then pcall(Set, false) end
                SaveConfiguration()
                if not Next then
                    Runner.Active = false
                    break
                end
            end

            -- Priority: ว่างระหว่างตัว = โหมดที่สำคัญกว่ามีงานแล้ว -> สลับไปเลย / Hunt-Boss-Raid ไม่มีอะไรให้ตีนาน
            -- เกิน IdleAfter = พักโหมดนั้นไว้ ให้โหมดถัดไปทำก่อน (ยืมตัวฟาร์ม = ไม่ยุ่ง)
            if not Runner.Borrowed then
                if Farm.IsMobAlive(Farmer.Mob) then
                    Runner.WorkAt = os.clock()
                elseif not Fighter.Escaping() then
                    if (Runner.Mode == "Hunt" or Runner.Mode == "Boss" or Runner.Mode == "Camp") and os.clock() - Runner.WorkAt > Runner.IdleAfter then
                        Runner.IdleUntil[Runner.Mode] = os.clock() + Runner.IdleFor
                        Runner.WorkAt = os.clock()
                    end
                    Runner.Switch(Runner.Pick())
                end
            end

            local Root = Movement.GetRoot()
            if not Root then
                -- รอตัวละครเกิดใหม่
            elseif Runner.Mode == "Fish" then
                -- ตาของ Auto Fishing (Priority) - ตัวตกปลาคุมตัวละครเอง (ขายของเองด้วย) ฟาร์มรอเฉย ๆ
                task.wait(0.25)
            elseif TryCollectDrops(Root) then
                -- เก็บของไปแล้วรอบนี้ วนใหม่เช็คว่ามีของเหลืออีกไหมก่อนค่อยกลับไปฟาร์ม
            elseif Runner.Before("Sell", Runner.Mode) and Seller.Due() and not Farm.IsMobAlive(Farm.ConfigFarm.Mob) and Seller.Run(ShouldRun) then
                -- ถึงรอบ Auto Sell ระหว่างว่าง (ไม่ได้ล็อกตัวไหนอยู่) - ขายเสร็จวนใหม่ บินกลับไปฟาร์มเอง
            elseif Runner.Before("Potion", Runner.Mode) and Potions.BuyDue() and not Farm.IsMobAlive(Farm.ConfigFarm.Mob) and Potions.Buy(ShouldRun) then
                -- ยาที่เลือกหมด + มีร้านใน place นี้ - ซื้อระหว่างว่างแบบเดียวกับ Auto Sell
            elseif DoStoryStep(Root) then
                -- กำลังทำเควสเนื้อเรื่องปลดล็อก NPC อยู่ - จบแล้วค่อยกลับไปฟาร์มตาม LevelConfig
            elseif Runner.Mode == "Camp" then
                DoCampStep(Root)
            else
                local Entry = GetModeEntry()

                if not Entry or type(Entry.MonName) ~= "string" or Entry.MonName == "" then
                    Movement.Lock(nil)
                    ResetFarmState()
                    task.wait()
                else
                    if Farmer.Entry ~= Entry then
                        -- เปลี่ยนเป้าตาม LevelConfig (ปลดล็อกด่านใหม่แล้ว) - เคลียร์ state คอมโบ/หลบของตัวเก่าทิ้ง
                        ResetFarmState()
                        Farmer.Entry = Entry
                    end

                    if ModeSetting("FarmWeapon") ~= "" then
                        Farm.EquipWeapon(ModeSetting("FarmWeapon"))
                    end

                    local IsBossEntry = Farm.IsBossName(Entry.MonName)

                    if IsBossEntry and BossWaiting(Entry.MonName) and Runner.Mode == "Level"
                        and not Farm.GetNearestMobByName(Root.Position, Entry.MonName) then
                        -- บอสยังไม่เกิด - ไปตีมอนด่านก่อนหน้ารอ (ถ้าเห็นบอสเกิดก่อนเวลา หลุดเงื่อนไขนี้ไปตีเลย)
                        -- เฉพาะ Auto Farm Level: Farm Boss ตีแค่บอสที่เลือก (ด่านก่อนหน้าของบอสมักเป็นลูกน้องชื่อคล้าย ๆ
                        -- เช่น Hoyuzo -> Hoyuzo Subordinate ผู้ใช้เห็นเป็น "ตีมอนผิดตัว") - รอที่จุดเกิดบอสแทน
                        DoFiller(Entry, Root)
                    elseif not Farmer.Probe and not EnsureQuestAccepted(Entry) then
                        -- (Probe = แค่ TP ไปดูว่าบอสเกิดไหม ยังไม่ต้องบินไปรับเควส)
                        -- ยังไม่ผ่านเงื่อนไขเควส - ข้ามการฟาร์มรอบนี้ทั้งหมดตามที่สั่ง (ไม่รับ = ไม่ฟาร์ม)
                    else
                        -- ตีทีละตัวจนตาย: ตัวที่ล็อกไว้ยังไม่ตายและยังอยู่ใกล้ = ตีตัวเดิมต่อ ไม่สลับไปตัวที่
                        -- ใกล้กว่าทุกรอบ (ของเดิมเลือกใหม่ทุกรอบ คอมโบกลางชุดไปลงอีกตัว เลขคอมโบหลุด ตีช้า/ไม่โดน)
                        -- ตีทีละตัวจนตาย: ไม่ตัดที่ระยะ (ของเดิมตัดที่ 200 studs - หลบสกิลลอยไป ~300 studs แล้วเลือก
                        -- ตัวชื่อเดียวกันที่ใกล้จุดหลบแทน = ทิ้งตัวที่ตีค้างไว้) ปล่อยเมื่อตาย/หลุด streaming/เปลี่ยนเป้าเท่านั้น
                        local Mob = Farmer.Mob
                        -- (Farmer.Mob ถูกล้างตอนเปลี่ยนเป้าใน ResetFarmState - ลูกน้องบอสที่ล็อกไว้ก็ตีจนตายเหมือนกัน)
                        if not Farm.IsMobAlive(Mob) then
                            Mob = Farm.GetNearestMobByName(Root.Position, Entry.MonName)
                        end

                        -- บอสอมตะ (iframe) ระหว่างลูกน้องยังอยู่ = ตีไปดาเมจ 0 บอสรีเลือดคืน - ฆ่าลูกน้องก่อน
                        -- เช็คทุกรอบเพราะลูกน้องโผล่มาเป็นระลอกกลางไฟต์ (ตัวที่ล็อกเป็นลูกน้องอยู่ = ตีจนตายก่อน)
                        local Add = Farm.GetBossAdd(Mob)
                        if Add then Mob = Add end
                        Farmer.Mob = Mob

                        if not Mob then
                            Movement.Lock(nil)
                            Farmer.ComboStart = 0

                            local WaitAt = Entry.WaitPOS or Entry.MonPOS
                            if WaitAt and Farmer.Probe and IsBossEntry then
                                -- ไม่มีบอสให้ตี: TP ไปจุดเกิดแล้วลอยค้างรอ streaming โหลดโมเดล
                                -- เจอ = รอบหน้า GetModeEntry เห็นแล้วตีเลย / ไม่เจอ = ติดเวลาเช็คใหม่ ไปจุดถัดไป
                                -- ระหว่างนี้บอสตัวอื่นในระยะ ~600 studs ก็ถูกเช็คไปด้วย (NoteAbsentBosses)
                                -- รายชื่อของโหมดที่รันอยู่ (Boss = ที่เลือกไว้ / Hunt = บอสของ Hunt) - เดิมอ่านของ Boss ตลอด
                                local Keys = ModeKeys[Runner.Mode]
                                local Names = getgenv().ConfigurationTable[(Keys and Keys.Names) or ModeKeys.Boss.Names]
                                Names = type(Names) == "table" and Names or { }

                                -- ยืนบนพื้นจริงที่จุดเกิด (จุดเกิดในข้อมูลเกมบางจุดลอย/จมหิน) ตรึงแค่ช่วงรอ streaming
                                local Spot = Movement.GroundSpot(WaitAt)
                                Movement.Go(Spot, 5, 20, ShouldRun)
                                Movement.Lock(Movement.GroundSpot(WaitAt))     -- พื้นโหลดมาแล้วหลังวาร์ป
                                NoteAbsentBosses(Names, Movement.GetRoot() or Root)

                                -- ยืนนิ่งที่จุด รอทีละเฟรม (task.wait) ไม่ตั้งเวลาตายตัว: จบเมื่อเจอบอส หรือ NoteAbsentBosses
                                -- ยืนอยู่ในรัศมีครบ AbsentSettle แล้วยังไม่เห็น = ตีตราว่าไม่อยู่ (BossWaiting เป็นจริง)
                                while ShouldRun() and #Farm.GetMobsByName(Entry.MonName) == 0
                                    and not BossWaiting(Entry.MonName) do
                                    NoteAbsentBosses({ Entry.MonName }, Movement.GetRoot() or Root)
                                    task.wait()
                                end
                            elseif WaitAt then
                                -- ระหว่างบินไปจุดบอส: เข้าระยะ streaming แล้วไม่เห็นบอส = ตายอยู่ เลิกบินกลับไปเลือกตัวอื่น
                                -- (ไปรอตัวที่ติดคูลดาวน์อยู่แล้วตั้งแต่แรก = ทุกตัวติด บินไปรอตามปกติ)
                                local WasWaiting = IsBossEntry and BossWaiting(Entry.MonName)
                                Movement.Go(WaitAt, 5, 20, function()
                                    if IsBossEntry and not WasWaiting then
                                        local Here = Movement.GetRoot()
                                        if Here then NoteAbsentBosses({ Entry.MonName }, Here) end
                                        if BossWaiting(Entry.MonName) then return false end
                                    end
                                    return ShouldRun() and #Farm.GetMobsByName(Entry.MonName) == 0
                                end)

                                -- ยืนที่จุดบอสแล้วยังไม่มี = บอสตายอยู่ (ไม่รู้เวลาตาย) ออกไปตีอย่างอื่นแล้วค่อยกลับมาเช็ค
                                -- (ติดคูลดาวน์อยู่แล้ว = มาดักรอเพราะทุกตัวติด ไม่ต่อเวลาทับ - เวลาจากที่ฆ่าเองแม่นกว่า
                                -- ยืนรอเฉย ๆ ทีละ 0.5 วิ บอสเกิดเมื่อไหร่ GetModeEntry เห็นแล้วเลือกเอง)
                                local Here = Movement.GetRoot()
                                if IsBossEntry and Here and (Here.Position - WaitAt).Magnitude <= 20
                                    and #Farm.GetMobsByName(Entry.MonName) == 0 then
                                    if BossWaiting(Entry.MonName) then
                                        task.wait()
                                    else
                                        MarkAbsent(Entry.MonName)
                                    end
                                end
                            else
                                task.wait()
                            end
                        else
                            -- ตีตัวนี้วนจนตายจริง (repeat ... until ตาย) ค่อยกลับไปลูปนอกเลือกเป้า/งานใหม่
                            -- ของเดิมตี 1 ชุดแล้ววนกลับลูปนอกทุกรอบ = เก็บของดรอป/เปลี่ยนเป้าตาม LevelConfig แทรกกลางไฟต์ได้
                            -- ทิ้งตัวที่ตีค้างไว้ ตอนนี้ออกจากลูปเมื่อ ตาย / หลุด streaming / ตัวเราตาย / ปิดหรือเปลี่ยนโหมดเท่านั้น
                            -- ลูกน้องบอสยังเช็คทุกรอบในลูปนี้ (บอส iframe ระหว่างลูกน้องอยู่) - ตีลูกน้องจนตายแล้ววนกลับมาตีบอสต่อ
                            local ModeNow = Runner.Mode
                            if Mob.IsBoss and Farm.IsBossName(Entry.MonName) then Farmer.BossLock = Entry.MonName end
                            repeat
                                local Here = Movement.GetRoot()
                                if not Here then break end

                                local Target = Mob
                                local Add = Farm.IsMobAlive(Mob) and Farm.GetBossAdd(Mob) or nil
                                if Add then Target = Add end
                                if not Farm.IsMobAlive(Target) then break end

                                Farmer.Mob = Target
                                FightMob(Target, Here)
                                task.wait()
                            until not ShouldRun() or Runner.Mode ~= ModeNow or not Farm.IsMobAlive(Mob)
                                or QuestReadyToTake(Entry)

                            -- ฆ่าบอสเองได้ = รู้เวลาตายแน่นอน ใช้ SpawnTime จริงของเกม + เก็บกล่อง/ของดรอปเสมอ
                            if Mob.IsBoss and not Farm.IsMobAlive(Mob) then
                                BossReadyAt[Entry.MonName] = os.clock() + Farm.GetSpawnTime(Entry.MonName) - BossEarly
                                BossKnown[Entry.MonName] = true
                                -- มีเควสรอรับอยู่ (ฆ่าบอสแล้วเควสจบ) = ไม่ยืนรอกล่องที่ยังไม่เกิดนานเกิน 3 วิ
                                Farm.CollectBossLoot(Mob.Root.Position, ShouldRun, function()
                                    return QuestReadyToTake(Entry) or QuestReadyToTake(Farm.GetPreviousEntry(Entry))
                                end)
                            end
                        end
                    end
                end
            end
        end

        Farmer.Running = false
        if Fighter.Continue == ShouldRun then Fighter.Continue = nil end
        ResetFarmState()
        Movement.Cancel()
        Runner.Thread = nil
    end

    -- RunFarm error กลางลูป (เดิม thread ตายเงียบ Runner.Thread ค้าง = ฟาร์มหยุดถาวร เปิดปิด toggle ก็ไม่ฟื้น)
    -- = จับ error เก็บกวาดสถานะ แล้วเริ่มลูปใหม่เองใน 2 วิ ตราบใดที่ toggle ยังเปิด (ไม่ปิด toggle ให้)
    local function StartFarm()
        Runner.Active = true
        if Runner.Thread then return end
        Runner.Thread = task.spawn(function()
            while getgenv().ValkyrieSession == SessionToken and Runner.Active do
                local Ok, Err = pcall(RunFarm)
                if Ok or not Runner.Active then break end
                warn("[Valkyrie] Farm error, restarting: " .. tostring(Err))
                Farm.ConfigFarm.Running = false
                if Fighter.Continue == ShouldRun then Fighter.Continue = nil end
                pcall(ResetFarmState)
                pcall(Movement.Cancel)
                Runner.Thread = true
                task.wait(2)
            end
            Runner.Thread = nil
        end)
    end

    local function StopFarm()
        Runner.Active = false
        Movement.Cancel()
    end

    --// เปิด/ปิดโหมดฟาร์ม - รันได้ทีละโหมด (ใช้ตัวรัน RunFarm ตัวเดียวกัน แค่เปลี่ยนวิธีเลือกเป้า)
    -- เปิดโหมดหนึ่ง = ปิด toggle โหมดอื่นให้เอง (SetFlags ยิง callback ของโหมดนั้นด้วยค่า false
    -- แต่ Runner.Mode เปลี่ยนไปแล้วเลยไม่ไปหยุดตัวรัน) ลูปที่รันอยู่อ่าน Runner.Mode ใหม่รอบถัดไปเอง
    local function SetMode(Mode, Value)
        local Config = getgenv().ConfigurationTable
        Config[ModeKeys[Mode].Enabled] = Value

        if Value then
            -- โหมดฟาร์มเปิดพร้อมกันได้แล้ว (หน้า Priority ตัดสินว่าทำตัวไหนก่อน) - ปิดแค่กลุ่มอื่นที่ขยับตัวละคร
            TurnOffFlags(ExclusiveFlags.Breathing)
            TurnOffFlags(ExclusiveFlags.Puzzle)
            TurnOffFlags(ExclusiveFlags.Fishing, "SL2AutoFishing")     -- Auto Fishing อยู่ใน Priority ด้วย
            TurnOffFlags(ExclusiveFlags.Quest)

            Runner.IdleUntil[Mode] = nil
            local WasBorrowed = Runner.Borrowed
            Runner.Borrowed = false
            if Runner.Active and Runner.Thread then
                -- รันโหมดอื่นอยู่: ว่างอยู่ = สลับทันที / กำลังตี = ลูปสลับเองหลังตัวนี้ตาย
                if WasBorrowed or not Farm.IsMobAlive(Farm.ConfigFarm.Mob) then Runner.Switch(Runner.Pick() or Mode) end
            else
                Runner.Mode = Runner.Pick() or Mode
                getgenv().ValkyrieFarmSuffix = ModeKeys[Runner.Mode].Suffix or ""
                StartFarm()
            end
        elseif Runner.Mode == Mode then
            local Next = not Runner.Borrowed and Runner.AnyFarm() and Runner.Pick() or nil
            if Next then
                Runner.Switch(Next)
            else
                StopFarm()
                getgenv().ValkyrieFarmSuffix = ""
            end
        end
        -- ปิดโหมดฟาร์มตัวสุดท้ายตอนตัวรันรอตา Auto Fishing อยู่ = หยุดตัวรัน (ตกปลาต่อเอง)
        if not Value and Runner.Active and not Runner.Borrowed and not Runner.AnyFarm() then
            StopFarm()
            getgenv().ValkyrieFarmSuffix = ""
        end

        SaveConfiguration()
    end

    -- ให้ระบบอื่นยืมตัวฟาร์ม Level ไปเก็บเลเวล (Auto Quest Shiori เลเวลไม่ถึง) โดยไม่แตะ toggle
    -- Suffix = ชุดตั้งค่าของคนยืม (ModeSetting อ่าน FarmMethod<Suffix> ฯลฯ) / Stop หยุดเฉพาะตอนที่ยืมอยู่
    -- (ผู้ใช้เปิด Auto Farm เองทีหลัง = SetMode ล้าง Borrowed คนยืมหยุดไม่ได้)
    Farm.LevelFarm = {
        Start = function(Suffix)
            if Runner.Active and not Runner.Borrowed then return end
            Runner.Borrowed = true
            Runner.Mode = "Level"
            getgenv().ValkyrieFarmSuffix = Suffix or "Level"
            StartFarm()
        end,
        Stop = function()
            if not Runner.Borrowed then return end
            Runner.Borrowed = false
            if Runner.Active then StopFarm() end
            getgenv().ValkyrieFarmSuffix = ""
        end,
    }

    LevelMainSection:Toggle({
        Name = "Auto Farm Level",
        Flag = "SL2AutoFarm",
        Default = getgenv().ConfigurationTable.AutoFarm,
        Callback = function(Value)
            SetMode("Level", Value)
        end
    })

    -- เปิด = รับเควสของด่านก่อนฟาร์ม (+ เควสด่านก่อนหน้าตอนรอบอส + สายเนื้อเรื่อง Chaka)
    -- ปิด = ไม่รับเควสเลย ฟาร์มมอนตาม LevelConfig ตรง ๆ - อ่านค่าสดทุกรอบลูป ไม่ต้องรีสตาร์ทฟาร์ม
    LevelMainSection:Toggle({
        Name = "Auto Accept Quest",
        Flag = "SL2AutoAcceptQuest",
        Default = getgenv().ConfigurationTable.AutoAcceptQuest,
        Callback = function(Value)
            getgenv().ConfigurationTable.AutoAcceptQuest = Value
            SaveConfiguration()
        end
    })

    -- เก็บกล่อง (Chest) + ของที่มอน/บอสดรอปตามพื้น (LootDrop) อัตโนมัติระหว่างฟาร์ม - แยกต่อแท็บ
    -- (Level/Mob/Boss มีคีย์เก็บกล่อง/รัศมีเป็นของตัวเอง อ่านผ่าน ModeSetting ใน TryCollectDrops)
    local function BuildCollectSection(Section, Suffix)
        local Config2 = getgenv().ConfigurationTable
        local EnabledKey, RadiusKey = "AutoCollectDrops" .. Suffix, "CollectRadius" .. Suffix

        Section:Toggle({
            Name = "Auto Collect Chest",
            Flag = "SL2" .. EnabledKey,
            Default = Config2[EnabledKey],
            Callback = function(Value)
                Config2[EnabledKey] = Value
                SaveConfiguration()
            end
        })

        Section:Slider({
            Name = "Collect Radius",
            Flag = "SL2" .. RadiusKey,
            Min = 10,
            Max = 150,
            Default = Config2[RadiusKey],
            Suffix = " studs",
            Seperator = false,
            Callback = function(Value)
                Config2[RadiusKey] = Value
                SaveConfiguration()
            end
        })
    end

    --// สร้าง section ตั้งค่าฟาร์ม (Weapon/Method/Distance/Mode/Speed) แยกต่อแท็บ - แต่ละแท็บมีคีย์
    -- ของตัวเอง (ต่อท้ายด้วย Suffix เช่น FarmWeaponLevel) ไม่ชนกัน คืน handle ของ Weapon dropdown
    -- ไว้รีเฟรชรายชื่ออาวุธเวลากระเป๋า/ Toolbar เปลี่ยน
    local function BuildSettingsSection(Section, Suffix)
        local Config2 = getgenv().ConfigurationTable
        local WeaponKey, MethodKey = "FarmWeapon" .. Suffix, "FarmMethod" .. Suffix
        local DistanceKey = "FarmDistance" .. Suffix
        local DodgeKey = "AutoDodge" .. Suffix

        -- Items ห้ามส่งเป็น {} ว่างเปล่า (ไลบรารีพังตอน render ถ้า list ว่าง ตอน Toolbar ยังโหลดไม่ทัน)
        local InitialWeapons = Farm.WeaponChoices()
        if #InitialWeapons == 0 then InitialWeapons = { "None" } end

        -- บั๊กเอ็กซ์พลอยต์ (ยืนยันสดผ่าน dex_inject bisect หลายสิบรอบ): เรียก Utility.GetData /
        -- Provider.GetItemFromId (ข้างใน Farm.GetWeaponNames) ทำให้ thread เสีย capability สร้าง
        -- Instance ชั่วคราว - แค่ task.wait() คั่นสักครั้งก่อนสร้าง Instance/Dropdown ตัวถัดไปก็หายแล้ว
        task.wait()

        -- Default ห้ามเป็น nil (ไลบรารีพังตอน render ถ้าไม่มี default) - ไม่มีค่าที่เซฟไว้ = ใช้ตัวแรกในลิสต์
        local WeaponDropdown = Section:Dropdown({
            Name = "Select Weapon",
            Flag = "SL2" .. WeaponKey,
            Items = InitialWeapons,
            KeepOrder = true,
            Default = (Config2[WeaponKey] ~= "" and Config2[WeaponKey]) or InitialWeapons[1],
            Seperator = false,
            Multi = false,
            Callback = function(Value)
                if type(Value) ~= "string" then return end

                Config2[WeaponKey] = Value
                SaveConfiguration()
                if getgenv().ValkyrieFarmSuffix == Suffix then Farm.EquipWeapon(Value) end
            end
        })
        -- ยังไม่เคยเลือก: dropdown โชว์อาวุธแรกแต่ callback ไม่ยิงตอนสร้าง - เซฟตัวที่โชว์ไว้ ใช้ตรงกับที่เห็น
        if Config2[WeaponKey] == "" and InitialWeapons[1] ~= "None" then
            Config2[WeaponKey] = InitialWeapons[1]
            SaveConfiguration()
        end

        Section:Dropdown({
            Name = "Method",
            Flag = "SL2" .. MethodKey,
            Items = Farm.Methods,
            Default = Config2[MethodKey],
            Multi = false,
            Seperator = false,
            Callback = function(Value)
                if type(Value) ~= "string" then return end

                Config2[MethodKey] = Value
                SaveConfiguration()
            end
        })

        Section:Slider({
            Name = "Distance",
            Flag = "SL2" .. DistanceKey,
            Min = 1,
            Max = 50,
            Default = Config2[DistanceKey],
            Suffix = " studs",
            Callback = function(Value)
                Config2[DistanceKey] = Value
                SaveConfiguration()
            end
        })


        -- เปิด = บอสเริ่มใช้สกิลเมื่อไหร่บินหนีไกล ๆ แล้วกลับเข้ามาตีต่อทันทีที่ท่าจบ/โดนยกเลิก
        -- ปิด = ไม่หลบเลย ยืนเกาะจุดตีตลอด (อ่านสดทุกเฟรม เปลี่ยนระหว่างฟาร์มได้เลย)
        Section:Toggle({
            Name = "Auto Dodge",
            Description = "Fly away when a boss or mob starts a skill, return when it ends",
            Flag = "SL2" .. DodgeKey,
            Default = Config2[DodgeKey] ~= false,
            Callback = function(Value)
                Config2[DodgeKey] = Value
                SaveConfiguration()
            end
        })

        return WeaponDropdown
    end
    -- แท็บ Sealed Cache Raid (สร้างทีหลังนอกบล็อกนี้) ใช้ section ตั้งค่าชุดเดียวกัน
    Farm.BuildSettingsSection = BuildSettingsSection

    --// Auto Farm Mob / Auto Farm Boss - เลือกตัวเองจากรายชื่อใน LevelConfig
    -- ฟาร์มตัวที่เลือกตลอดไม่สนเลเวล / เควสของด่านนั้นรับเฉพาะตอนเปิด Auto Accept Quest ของ section
    -- และเลเวล/race ผ่าน (Farm.QuestAllowed) ไม่ผ่าน = ตีเปล่า ๆ ไม่วนรอที่ NPC
    -- โหมด Boss ระหว่างรอบอสเกิดใหม่ยังไปตีมอนด่านก่อนหน้าเหมือน Auto Farm ปกติ
    local function BuildModeSection(Section, Mode, Label, WantBoss)
        local Keys = ModeKeys[Mode]
        local Names = Farm.GetConfigMobNames(WantBoss)
        if #Names == 0 then Names = { "None" } end

        -- เซฟเก่าเก็บชื่อเดียว (Keys.Name) - ครั้งแรกที่ยังไม่มีลิสต์ ย้ายมาเป็นลิสต์ (ไม่มีอะไรเลย = ตัวแรก)
        -- ลิสต์ว่างที่เซฟไว้แล้วคือ "ไม่ได้เลือกอะไร" จริง ๆ ห้ามเติมกลับ
        local Config2 = getgenv().ConfigurationTable
        if type(Config2[Keys.Names]) ~= "table" then
            local Old = Config2[Keys.Name]
            Config2[Keys.Names] = { table.find(Names, Old) and Old or (Names[1] ~= "None" and Names[1] or nil) }
        end

        local Saved = { }
        for _, Name in ipairs(Config2[Keys.Names]) do
            if table.find(Names, Name) then table.insert(Saved, Name) end
        end
        Config2[Keys.Names] = Saved

        -- สถานะบนสุด: ตอนนี้ตีอะไรอยู่ + (บอส) cooldown จากเกมของแต่ละตัวที่เลือก
        local TargetLabel = Section:Label("Target: -")
        local ListLabel = Section:Label("-", true)

        -- Farm Mob: มอนที่เลือกตัวไหนมีเควสให้รับ (แคช 5 วิ - FindQuestIdForMob ไล่ทั้ง Quests.Holder)
        local QuestInfo, QuestInfoAt = { }, -math.huge
        local function MobQuestState(Name)
            if os.clock() - QuestInfoAt > 5 then QuestInfo, QuestInfoAt = { }, os.clock() end
            if QuestInfo[Name] == nil then
                local Entry = Farm.GetEntryByName(Name)
                local QuestId = Farm.FindQuestIdForMob(Entry and Entry.QuestName, Name)
                if not QuestId then
                    QuestInfo[Name] = { "no quest (farms anyway)", "#8C8C8C" }
                elseif not Farm.QuestAllowed(QuestId) then
                    QuestInfo[Name] = { "quest locked (level/race)", "#DCAA50" }
                else
                    QuestInfo[Name] = { "quest: " .. QuestId, "#78DC78" }
                end
            end
            return QuestInfo[Name][1], QuestInfo[Name][2]
        end

        local function Clock(Seconds)
            Seconds = math.max(0, math.floor(Seconds))
            return string.format("%d:%02d", Seconds // 60, Seconds % 60)
        end

        task.spawn(function()
            while getgenv().ValkyrieSession == SessionToken do
                local Text = "Target:"
                if Runner.Active and Runner.Mode == Mode then
                    local Farmer = Farm.ConfigFarm
                    local Mob, Entry = Farmer.Mob, Farmer.Entry
                    if Farm.IsMobAlive(Mob) then
                        Text = string.format("Target: %s %d/%d HP%s%s", (Mob.Model.Name:gsub("%d+$", "")),
                            math.floor(Mob.Humanoid.Health), math.floor(Mob.Humanoid.MaxHealth),
                            Fighter.Escaping() and " · dodging" or "",
                            Farmer.BossLock and " · locked until it dies" or "")
                    elseif Entry and WantBoss and BossWaiting(Entry.MonName) then
                        Text = string.format("Target: waiting for %s (%s)", Entry.MonName, Clock(BossReadyIn(Entry.MonName)))
                    elseif Entry then
                        Text = "Target: going to " .. Entry.MonName
                    else
                        Text = "Target: nothing selected"
                    end
                end

                local Lines = { }
                if not WantBoss then
                    for _, Name in ipairs(Config2[Keys.Names] or { }) do
                        local State, Color = MobQuestState(Name)
                        table.insert(Lines, string.format('%s <font color="%s">%s</font>', Name, Color, State))
                    end
                end
                if WantBoss then
                    for _, Name in ipairs(Config2[Keys.Names] or { }) do
                        local State, Color
                        if Farm.NightOnlyWaiting(Name) then
                            State, Color = "night only", "#8C8C8C"
                        else
                            local Cooldown = Farm.BossCooldown(Name)
                            if Cooldown == nil then
                                State, Color = "unknown", "#8C8C8C"
                            elseif Cooldown > 0 then
                                State, Color = "respawn " .. Clock(Cooldown), "#DCAA50"
                            else
                                State, Color = "alive", "#78DC78"
                            end
                        end
                        table.insert(Lines, string.format('%s <font color="%s">%s</font>%s', Name, Color, State,
                            Farm.ConfigFarm.BossLock == Name and " · fighting" or ""))
                    end
                end

                task.wait()
                pcall(function()
                    TargetLabel:SetText(Text)
                    ListLabel:SetRichText(#Lines > 0 and table.concat(Lines, "\n") or (WantBoss and "No boss selected" or "No mob selected"))
                end)
                task.wait()
            end
        end)

        -- Dropdown ต้องมี task.wait() คั่นก่อน/หลังเสมอ (บั๊ก capability ของเอ็กซ์พลอยต์ ดูโน้ตที่ Select Weapon)
        task.wait()

        Section:Dropdown({
            Name = "Select " .. Label,
            Flag = "SL2Farm" .. Mode .. "Name",
            Items = Names,
            Default = Saved,
            Multi = true,
            Seperator = false,
            Callback = function(Value)
                if type(Value) ~= "table" then return end

                local List = { }
                for _, Name in ipairs(Value) do
                    if Name ~= "None" then table.insert(List, Name) end
                end

                Config2[Keys.Names] = List
                SaveConfiguration()
            end
        })

        task.wait()

        Section:Toggle({
            Name = "Auto Farm " .. Label,
            Flag = Keys.Flag,
            Default = getgenv().ConfigurationTable[Keys.Enabled],
            Callback = function(Value)
                SetMode(Mode, Value)
            end
        })

        -- Farm Boss ไม่มีรับเควส (ตามที่สั่ง - ตีบอสอย่างเดียว) / Farm Mob รับเฉพาะมอนที่มีเควส
        if WantBoss then return end

        Section:Toggle({
            Name = "Auto Accept Quest",
            Description = "Takes the quest of mobs that have one. Mobs without a quest are farmed anyway",
            Flag = "SL2" .. Mode .. "AcceptQuest",
            Default = getgenv().ConfigurationTable[Keys.Quest],
            Callback = function(Value)
                getgenv().ConfigurationTable[Keys.Quest] = Value
                SaveConfiguration()
            end
        })
    end

    BuildModeSection(MobMainSection, "Mob", "Mob", false)
    BuildModeSection(BossMainSection, "Boss", "Boss", true)

    BuildCollectSection(LevelCollectSection, "Level")
    BuildCollectSection(MobCollectSection, "Mob")
    BuildCollectSection(BossCollectSection, "Boss")

    local LevelWeaponDropdown = BuildSettingsSection(LevelSettingsSection, "Level")
    local MobWeaponDropdown = BuildSettingsSection(MobSettingsSection, "Mob")
    local BossWeaponDropdown = BuildSettingsSection(BossSettingsSection, "Boss")

    --// Auto Boss Hunt - รับ Hunt -> ตีบอส (ตัวรันโหมด "Hunt" ใช้ระบบตีบอสเดียวกับ Farm Boss) -> จบ -> รับตัวใหม่
    -- ยืนยันสดผ่าน dex 2026-09-29:
    --   Hunt ที่เปิดในเซิร์ฟ = ReplicatedStorage.BossHunts.<Id> attribute Boss / Side / Tier / Quest / ExpiresAt
    --     (หมุนเวียน ~8-9 อัน) - Id = ชื่อ child (ตัวเดียวกับที่หน้า CrowTasks ของเกมอ่าน: readHunt)
    --   รับ = การ์ด HuntCard ในบทพูดอีกา (Kasugai Crow): Quests.CanAddQuest(LocalPlayer, Quest) ผ่าน
    --     -> SignalEvent.ToServer("BossHuntsRequest", { action = "Claim", id = Id }) ไม่ต้องไปหา NPC
    --   CanAddQuest ไม่ผ่าน: nil = race/เลเวลไม่ถึง (Muzan = Demon/Hybrid, Crow = Slayer/Hybrid)
    --     / false,true = cooldown ("Take a breath") / false,_,ชื่อ = ถือ Hunt อื่นอยู่ (ทีละ 1)
    --   เควส = "Eliminate <บอส>" (Timer 1800, NoCancel, KillCreditShare 0.1 = ต้องตีเอง 10%)
    --     task "Defeat <บอส>" x1 - ถืออยู่ = Quests.GetPlayerQuestState = "Doing"
    --   บอสทุกตัวของ Hunt (30 ตัว) อยู่ใน Farm.GetWorldBosses (จุดเกิด Center/Spawn) ครบ
    do
        local HuntInfo, Quests, HuntSignal = nil, nil, nil
        pcall(function() HuntInfo = require(ReplicatedStorage.CAM.Global.Subsets.Gameplay.Quests.BossHunts) end)
        pcall(function() Quests = require(ReplicatedStorage.CAM.Global.Subsets.Gameplay.Quests) end)
        pcall(function() HuntSignal = HubSignal(require(ReplicatedStorage.Communication.ServerAndClient.Signals.SignalEvent)) end)
        local HuntTiers = { "Common", "UnCommon", "Rare", "Epic", "Legendary", "Mythic" }
        local Config2 = getgenv().ConfigurationTable
        Config2.HuntTargets = { }
        Config2.HuntMinTier = nil       -- เซฟเก่า (Min Tier) - เปลี่ยนเป็นเลือกหลาย Tier แล้ว
        if type(Config2.HuntTiers) ~= "table" then Config2.HuntTiers = { } end
        if type(Config2.HuntSides) ~= "table" then Config2.HuntSides = { Crow = true, Muzan = true } end

        -- ฝั่งของ Hunt: Crow = Slayer (Race Slayer/Hybrid) / Muzan = Demon (Race Demon/Hybrid) - Quests.BossHunts.Sides
        local SideLabel = { Crow = "Slayer (Crow)", Muzan = "Demon (Muzan)" }
        local HuntUtility = nil
        pcall(function() HuntUtility = require(ReplicatedStorage.CAM.Global.Utility) end)

        -- race เรารับฝั่งนี้ได้ไหม (ไม่รู้ = ถือว่าได้ ให้ CanAddQuest ตัดสินตอนรับ)
        local function SideAllowed(Side)
            local Info = HuntInfo and HuntInfo.Sides and HuntInfo.Sides[Side]
            local Ok, Race = pcall(function() return HuntUtility.GetData(LocalPlayer).Race.Value end)
            if not (Info and Ok and Race) then return true end
            return table.find(Info.Race, Race) ~= nil
        end

        local Hunt = { Step = "-", Current = nil, Done = 0, NextClaimAt = 0 }

        local function Running()
            return getgenv().ValkyrieSession == SessionToken and Runner.Active and Runner.Mode == "Hunt"
        end

        local function TierRank(Tier)
            return table.find(HuntTiers, Tier) or 0
        end

        -- Hunt ที่ถืออยู่ (เควส Eliminate ตัวไหน Doing) - คืนชื่อบอส
        local function ActiveHunt()
            if not HuntInfo then return nil end
            for _, Entry in ipairs(HuntInfo.Hunts) do
                local Boss = HuntInfo.Npc(Entry)
                if Farm.GetQuestState(HuntInfo.QuestName(Boss)) == "Doing" then
                    return Boss, Entry.Tier
                end
            end
            return nil
        end

        -- Hunt ที่เปิดอยู่และรับได้ (race/เลเวลผ่าน + Tier ถึงขั้นต่ำ + บอสมีจุดเกิด) เรียง: Tier สูงก่อน
        -- -> บอสเกิดอยู่ก่อนตัวที่ติด cooldown -> cooldown เหลือน้อยก่อน
        local function OpenHunts()
            local Folder = ReplicatedStorage:FindFirstChild("BossHunts")
            local Now = workspace:GetServerTimeNow()
            local List, Why = { }, nil
            for _, Child in ipairs(Folder and Folder:GetChildren() or { }) do
                local Boss, Tier, Quest = Child:GetAttribute("Boss"), Child:GetAttribute("Tier"), Child:GetAttribute("Quest")
                local Left = (tonumber(Child:GetAttribute("ExpiresAt")) or 0) - Now
                if Boss and Quest and Left > 5 and Config2.HuntTiers[Tier] == true
                    and Config2.HuntSides[Child:GetAttribute("Side")] == true and Farm.GetEntryByName(Boss) then
                    local Ok, Can, Reason = true, true, nil
                    if Quests and Quests.CanAddQuest then Ok, Can, Reason = pcall(Quests.CanAddQuest, LocalPlayer, Quest) end
                    if Ok and Can then
                        table.insert(List, { Id = Child.Name, Boss = Boss, Tier = Tier, Side = Child:GetAttribute("Side"),
                            Quest = Quest, Wait = Farm.BossCooldown(Boss) or 0 })
                    elseif Ok and Can == false and Reason == true then
                        Why = "Hunt cooldown - the crow says take a breath"
                    end
                end
            end
            table.sort(List, function(A, B)
                local Ra, Rb = TierRank(A.Tier), TierRank(B.Tier)
                if Ra ~= Rb then return Ra > Rb end
                return A.Wait < B.Wait
            end)
            return List, Why
        end

        -- หน้า Priority: Hunt มีงานไหม = ถือ Hunt อยู่และบอสไม่ติด cooldown / มี Hunt เปิดให้รับ (แคช 1 วิ)
        Hunt.ReadyAt = -math.huge
        function Farm.HuntReady()
            if os.clock() - Hunt.ReadyAt < 1 then return Hunt.Ready, Hunt.Why end
            local Ready, Why = false, nil
            local Boss = ActiveHunt()
            if Boss then
                local Wait = Farm.BossCooldown(Boss) or 0
                Ready = Wait <= 0
                if not Ready then Why = string.format("%s respawn in %d:%02d", Boss, Wait // 60, math.floor(Wait % 60)) end
            elseif os.clock() < Hunt.NextClaimAt then
                Why = "retrying the claim"
            else
                local List, Reason = OpenHunts()
                Ready, Why = #List > 0, Reason or "no open hunt in the picked tiers/sides"
            end
            Hunt.ReadyAt, Hunt.Ready, Hunt.Why = os.clock(), Ready, (not Ready) and Why or nil
            return Hunt.Ready, Hunt.Why
        end

        local function Claim(Entry)
            pcall(function()
                HuntSignal.ToServer("BossHuntsRequest", { action = "Claim", id = Entry.Id })
            end)
            return Farm.WaitFor(function() return Farm.GetQuestState(Entry.Quest) == "Doing" end, 3, Running)
        end

        -- ตัวจัดการ: ถือ Hunt อยู่ = ป้อนชื่อบอสให้ตัวรัน / ไม่มี = เลือกตัวดีสุดแล้วรับ (เว้น 2 วิถ้ารับไม่ติด)
        local function Step()
            local Boss, Tier = ActiveHunt()
            if Boss then
                if Hunt.Current and Hunt.Current ~= Boss then Hunt.Done += 1 end
                Hunt.Current = Boss
                if Config2.HuntTargets[1] ~= Boss then Config2.HuntTargets = { Boss } end
                Hunt.Step = string.format("Hunting %s (%s)", Boss, tostring(Tier))
                return
            end

            -- เพิ่งจบ (เควสหายไปแล้ว) = นับ 1 แล้วหาตัวใหม่
            if Hunt.Current then
                Hunt.Done += 1
                Hunt.Current = nil
            end
            if #Config2.HuntTargets > 0 then Config2.HuntTargets = { } end

            if os.clock() < Hunt.NextClaimAt then return end
            local List, Why = OpenHunts()
            local Pick = List[1]
            if not Pick then
                Hunt.Step = Why or "No open hunt in the selected tiers/sides - waiting for the next roll"
                Hunt.NextClaimAt = os.clock() + 2
                return
            end

            Hunt.Step = string.format("Taking %s (%s)", Pick.Boss, Pick.Tier)
            if Claim(Pick) then
                Hunt.Current = Pick.Boss
                Config2.HuntTargets = { Pick.Boss }
            else
                Hunt.Step = "The server refused " .. Pick.Boss .. " - trying again"
                Hunt.NextClaimAt = os.clock() + 2
            end
        end

        local HuntTargetLabel = HuntMainSection:Label("Status: -")
        local HuntListLabel = HuntMainSection:Label("-", true)

        -- เลือกได้หลาย Tier (Mythic บนสุด) - Hunt ที่ Tier ไม่ได้เลือกไม่รับ
        local TierItems, SavedTiers = { }, { }
        for Index = #HuntTiers, 1, -1 do
            local Tier = HuntTiers[Index]
            table.insert(TierItems, Tier)
            if Config2.HuntTiers[Tier] == true then table.insert(SavedTiers, Tier) end
        end

        HuntMainSection:Dropdown({
            Name = "Hunt Tier",
            Flag = "SL2HuntTiers",
            Items = TierItems,
            Default = SavedTiers,
            Multi = true,
            KeepOrder = true,
            Seperator = false,
            Callback = function(Value)
                if type(Value) ~= "table" then return end
                for _, Tier in ipairs(HuntTiers) do
                    Config2.HuntTiers[Tier] = table.find(Value, Tier) ~= nil
                end
                SaveConfiguration()
            end
        })

        local SavedSides = { }
        for _, Side in ipairs({ "Crow", "Muzan" }) do
            if Config2.HuntSides[Side] == true then table.insert(SavedSides, SideLabel[Side]) end
        end

        HuntMainSection:Dropdown({
            Name = "Hunt Side",
            Flag = "SL2HuntSides",
            Items = { SideLabel.Crow, SideLabel.Muzan },
            Default = SavedSides,
            Multi = true,
            KeepOrder = true,
            Seperator = false,
            Callback = function(Value)
                if type(Value) ~= "table" then return end
                for Side, Label in pairs(SideLabel) do
                    Config2.HuntSides[Side] = table.find(Value, Label) ~= nil
                end
                SaveConfiguration()
            end
        })

        HuntMainSection:Toggle({
            Name = "Auto Boss Hunt",
            Flag = "SL2AutoBossHunt",
            Default = Config2.AutoBossHunt,
            Callback = function(Value)
                Config2.HuntTargets = { }
                Hunt.Current, Hunt.NextClaimAt = nil, 0
                SetMode("Hunt", Value)
            end
        })

        local function Clock(Seconds)
            Seconds = math.max(0, math.floor(Seconds))
            return string.format("%d:%02d", Seconds // 60, Seconds % 60)
        end

        task.spawn(function()
            while getgenv().ValkyrieSession == SessionToken do
                if Running() then
                    local Ok, Err = pcall(Step)
                    if not Ok then Hunt.Step = "Error: " .. tostring(Err) end
                else
                    Hunt.Step = "-"
                end

                -- สถานะ + Hunt ที่เปิดในเซิร์ฟตอนนี้
                local Text = "Status: " .. Hunt.Step .. " · done " .. Hunt.Done
                local Farmer = Farm.ConfigFarm
                if Running() and Hunt.Current then
                    if Farm.IsMobAlive(Farmer.Mob) then
                        Text = Text .. string.format("\nTarget: %s %d/%d HP", (Farmer.Mob.Model.Name:gsub("%d+$", "")),
                            math.floor(Farmer.Mob.Humanoid.Health), math.floor(Farmer.Mob.Humanoid.MaxHealth))
                    elseif BossWaiting(Hunt.Current) then
                        Text = Text .. string.format("\nTarget: waiting for %s (%s)", Hunt.Current, Clock(BossReadyIn(Hunt.Current)))
                    end
                end
                pcall(function() HuntTargetLabel:SetText(Text) end)

                local Lines = { }
                local Folder = ReplicatedStorage:FindFirstChild("BossHunts")
                local Now = workspace:GetServerTimeNow()
                local Rows = { }
                for _, Child in ipairs(Folder and Folder:GetChildren() or { }) do
                    local Left = (tonumber(Child:GetAttribute("ExpiresAt")) or 0) - Now
                    if Child:GetAttribute("Boss") and Left > 0 then table.insert(Rows, { Child, Left }) end
                end
                table.sort(Rows, function(A, B) return TierRank(A[1]:GetAttribute("Tier")) > TierRank(B[1]:GetAttribute("Tier")) end)
                -- แยกเป็น 2 กลุ่มตามฝั่ง - ฝั่งที่ race เรารับไม่ได้บอกไว้ที่หัวกลุ่ม
                for _, Side in ipairs({ "Crow", "Muzan" }) do
                    local Group = { }
                    for _, Row in ipairs(Rows) do
                        local Child = Row[1]
                        if Child:GetAttribute("Side") == Side then
                            table.insert(Group, string.format("  %s · %s · %s", tostring(Child:GetAttribute("Tier")),
                                tostring(Child:GetAttribute("Boss")), Clock(Row[2])))
                        end
                    end
                    if #Group > 0 then
                        local Head = SideLabel[Side] .. (SideAllowed(Side) and "" or " - your race can't take these")
                            .. (Config2.HuntSides[Side] == true and "" or " - off")
                        table.insert(Lines, Head)
                        for _, Line in ipairs(Group) do table.insert(Lines, Line) end
                    end
                end
                pcall(function() HuntListLabel:SetText(#Lines > 0 and table.concat(Lines, "\n") or "No open hunts") end)

                task.wait()
            end
        end)
    end

    BuildCollectSection(HuntCollectSection, "Hunt")
    local HuntWeaponDropdown = BuildSettingsSection(HuntSettingsSection, "Hunt")

    SetFarmMode = SetMode

    --// หน้า Priority: เรียงลำดับโหมดฟาร์ม (ช่อง 1 = ทำก่อน)
    do
        local Page = Farm.PriorityPage
        local Labels = Runner.Labels
        local Section = Page:Section({ Name = "Farm Priority", Description = "Which auto farm goes first", Icon = "80758916183665", Side = 1 })
        Section:Guide("How to use", {
            "Turn on as many as you want in their own tabs (farms, Auto Fishing, Auto Sell, potions)",
            "The hub always does the highest one that has something to do",
            "If there is nothing to do right now (no hunt, boss on cooldown), it does the next one, then comes back",
            "Auto Sell / Buy Potions above a farm are done between kills when due",
        })

        local Items, ModeOf = { }, { }
        for _, Mode in ipairs(Runner.Default) do
            table.insert(Items, Labels[Mode])
            ModeOf[Labels[Mode]] = Mode
        end

        local Slots, Syncing = { }, false
        local function Sync()
            Syncing = true
            local Order = Runner.Order()
            for Index, Dropdown in ipairs(Slots) do
                pcall(function() Dropdown:Refresh(Items, Labels[Order[Index]]) end)
            end
            Syncing = false
        end

        -- เลือกโหมดในช่องไหน = สลับที่กับช่องที่โหมดนั้นอยู่เดิม (ไม่มีโหมดซ้ำ/หาย)
        for Index, Rank in ipairs({ "1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th" }) do
            Slots[Index] = Section:Dropdown({
                Name = Rank,
                Flag = "SL2FarmPriority" .. Index,
                Items = Items,
                Default = Labels[Runner.Order()[Index]],
                Multi = false,
                Seperator = false,
                Callback = function(Value)
                    if Syncing or type(Value) ~= "string" or not ModeOf[Value] then return end
                    local Order = Runner.Order()
                    local From = table.find(Order, ModeOf[Value])
                    if not From or From == Index then return end
                    Order[From], Order[Index] = Order[Index], Order[From]
                    getgenv().ConfigurationTable.FarmPriority = Order
                    SaveConfiguration()
                    task.defer(Sync)
                end
            })
        end

        Section:Button({
            Name = "Reset Order",
            Description = "Potions > Sell > Boss Hunt > Farm Boss > Raid > Farm Mob > Farm Level > Fishing",
            Callback = function()
                getgenv().ConfigurationTable.FarmPriority = table.clone(Runner.Default)
                SaveConfiguration()
                Sync()
            end
        })
    end

    -- รีเฟรชรายชื่ออาวุธของทั้ง 3 แท็บอัตโนมัติเมื่อ Toolbar/กระเป๋าเปลี่ยน (ChildAdded/ChildRemoved
    -- ดูที่ Farm.WatchWeapons) ตอนโหลดเซฟ/เก็บของหลายชิ้นจะยิง event รัวเป็นชุด - รวมเป็นรีเฟรชครั้งเดียว
    local RefreshQueued = false
    local WeaponDropdowns = {
        { Dropdown = LevelWeaponDropdown, Key = "FarmWeaponLevel" },
        { Dropdown = MobWeaponDropdown, Key = "FarmWeaponMob" },
        { Dropdown = BossWeaponDropdown, Key = "FarmWeaponBoss" },
        { Dropdown = HuntWeaponDropdown, Key = "FarmWeaponHunt" },
    }
    -- แท็บ Final Selection เพิ่ม dropdown ของตัวเองเข้ามาทีหลัง (สร้างหลังบล็อกนี้)
    Farm.WeaponDropdowns = WeaponDropdowns

    local function RefreshWeapons()
        if RefreshQueued then return end
        RefreshQueued = true

        task.delay(0.2, function()
            RefreshQueued = false
            if getgenv().ValkyrieSession ~= SessionToken then return end

            local Names = Farm.WeaponChoices()

            -- GetWeaponNames ทำให้ thread เสีย capability ชั่วคราว (ดูโน้ตที่ BuildSettingsSection)
            task.wait()

            for _, Entry in ipairs(WeaponDropdowns) do
                local Saved = getgenv().ConfigurationTable[Entry.Key]
                pcall(function()
                    Entry.Dropdown:Refresh(Names, table.find(Names, Saved) and Saved or nil)
                end)
            end
        end)
    end

    task.spawn(function()
        local Deadline = os.clock() + 60     -- รอทีละเฟรม นานสุด 60 วิ (เดิมนับ 60 รอบ x 1 วิ)
        while os.clock() < Deadline do
            if getgenv().ValkyrieSession ~= SessionToken then return end

            local Connections = Farm.WatchWeapons(RefreshWeapons)
            if Connections then
                for _, Connection in ipairs(Connections) do
                    TrackConnection(Connection)
                end
                return
            end

            task.wait()
        end
    end)

    -- เซฟเปิดไว้หลายโหมดพร้อมกัน (ไฟล์เก่า/แก้มือ) - เอาโหมดแรกตามลำดับนี้โหมดเดียว
    for _, Mode in ipairs({ "Hunt", "Level", "Mob", "Boss", "Camp" }) do
        if getgenv().ConfigurationTable[ModeKeys[Mode].Enabled] then
            SetMode(Mode, true)
            break
        end
    end
end

-- การ์ด Status ของบล็อก "Final Selection" (โลกหลัก: นับถอยหลัง/เข้าด่าน) - ในด่านเองไม่มี UI
-- (ดูบล็อก "Final Selection Trial" ก่อนสร้าง Library ข้างบน สคริปต์จบตรงนั้นเลยถ้าอยู่ในด่าน)
-- Detail อยู่ในการ์ดใบเดียวกัน (แถวสุดท้าย) - ตัดความยาวไว้ไม่ให้ข้อความ error ยาว ๆ ดันการ์ดทั้งใบ
local FinalSelectionCard = nil

--// Final Selection - timed event ของเซิร์ฟ (TimedEvents.FinalSelection: Every 7200, Human Lv 45)
-- นับถอยหลังแบบเดียวกับป้ายเกม (UITimedEvent): Every - ServerTimeNow % Every
-- Toggle เปิด = ก่อนเริ่ม JoinBefore วิ พักโหมดฟาร์ม/ปราณที่เปิดอยู่ บินไปรอกลางที่ราบ
-- (part "Final Selection Situation") พอเริ่มแล้ว 25 วิยังอยู่ที่ราบ = ไม่ถูกดึงเข้า -> ปล่อยโหมดเดิม
-- ถูกย้ายออกไป = อยู่ในด่าน รอจนกลับมาที่ราบ (ผ่าน/ตายเกิดใหม่) แล้วคืนโหมดเดิม
-- ในด่านเป็นอีก place - ออโต้แบบไม่มี UI ในบล็อก "Final Selection Trial" ด้านบน
if FinalSelectionEnabled then
    local Event = { Every = 7200, Level = 45, Race = "Human" }
    pcall(function()
        local Def = require(ReplicatedStorage.CAM.Global.Subsets.Gameplay.TimedEvents).FinalSelection
        Event.Every = Def.Every or Event.Every
        Event.Level = Def.Requirements and Def.Requirements.Level or Event.Level
        Event.Race = Def.Requirements and Def.Requirements.Race or Event.Race
    end)

    local JoinBefore = 90
    local PullCheck = 25
    local TrialCap = 45 * 60
    local PlainsRadius = 220
    local PlainsFallback = Vector3.new(-2625.25, 275.55, -78)

    local Hold = { Flags = nil }
    local Phase = "Wait"        -- Wait / Join / Started / Trial
    local CycleStart = 0        -- ServerTime ที่รอบนี้เริ่ม
    local TrialSince = 0

    local function PlainsCenter()
        local Part = workspace:FindFirstChild("Debree")
        Part = Part and Part:FindFirstChild("Final Selection Assets")
        Part = Part and Part:FindFirstChild("Final Selection Situation")
        return (Part and Part:IsA("BasePart")) and Part.Position or PlainsFallback
    end

    local function InPlains()
        local Character = LocalPlayer.Character
        local Root = Character and Character:FindFirstChild("HumanoidRootPart")
        if not Root then return nil end
        local Offset = Root.Position - PlainsCenter()
        return Vector3.new(Offset.X, 0, Offset.Z).Magnitude <= PlainsRadius
    end

    local function ReadProfile()
        local Profile = { Race = "?", Rank = "?", Level = Farm.GetLevel() }
        pcall(function()
            local Data = require(ReplicatedStorage.CAM.Global.Utility).GetData(LocalPlayer, true)
            Profile.Race = Data.Race.Value
            Profile.Rank = Data:FindFirstChild("SlayerRank") and Data.SlayerRank.Value or "-"
        end)
        return Profile
    end

    local function FormatTime(Seconds)
        Seconds = math.max(0, math.floor(Seconds))
        return string.format("%02d:%02d:%02d", Seconds // 3600, Seconds % 3600 // 60, Seconds % 60)
    end

    -- พัก/คืนโหมดที่ขยับตัวละคร (Auto Farm / Mob / Boss / Breathing)
    local function HoldModes()
        if Hold.Flags then return end
        Hold.Flags = { }
        for _, List in ipairs({ ExclusiveFlags.Farm, ExclusiveFlags.Breathing }) do
            for _, Flag in ipairs(List) do
                if Library.Flags and Library.Flags[Flag] then
                    table.insert(Hold.Flags, Flag)
                end
            end
        end
        TurnOffFlags(ExclusiveFlags.Farm)
        TurnOffFlags(ExclusiveFlags.Breathing)
        TurnOffFlags(ExclusiveFlags.Quest)
    end

    local function ReleaseModes()
        local Flags = Hold.Flags
        Hold.Flags = nil
        if not Flags then return end
        for _, Flag in ipairs(Flags) do
            local Set = Library.SetFlags and Library.SetFlags[Flag]
            if Set then pcall(Set, true) end
        end
    end

    local function Show(State, Detail)
        if not FinalSelectionCard then return end
        pcall(function()
            FinalSelectionCard:SetState(State)
            FinalSelectionCard:Set("Detail", Detail)
        end)
    end

    local function Tick()
        -- ในด่านเอง: ตัวเล่นด่าน (บล็อก Final Selection Trial) ทำงานอยู่ ลูปรอเข้าด่านของโลกหลักพักไว้
        if InTrialPlace then
            Show("Running", "In trial · auto trial is playing")
            return
        end

        local Now = workspace:GetServerTimeNow()
        local Remaining = Event.Every - Now % Event.Every
        local Profile = ReadProfile()
        local Eligible = Profile.Race == Event.Race and Profile.Level >= Event.Level

        pcall(function()
            FinalSelectionCard:Set("Next", FormatTime(Remaining))
            FinalSelectionCard:Set("Requirement", string.format("%s Lv %d · you: %s Lv %d %s",
                Event.Race, Event.Level, Profile.Race, Profile.Level, Eligible and "✓" or "✗"))
            FinalSelectionCard:Set("Rank", Profile.Rank)
            FinalSelectionCard:SetProgress(Event.Every - Remaining, Event.Every)
        end)

        if not getgenv().ConfigurationTable.AutoFinalSelection then
            Phase = "Wait"
            ReleaseModes()
            Show("Idle", "-")
            return
        end

        if Phase == "Wait" then
            if not Eligible then
                Show("Error", "Not eligible - need " .. Event.Race .. " Lv " .. Event.Level)
            elseif Remaining > JoinBefore then
                Show("Waiting", "Auto join at T-" .. JoinBefore .. "s")
            else
                Phase = "Join"
                CycleStart = Now + Remaining
            end
        end

        if Phase == "Join" then
            if Now >= CycleStart then
                Phase = "Started"
                return
            end

            HoldModes()
            if InPlains() then
                Show("Running", string.format("At plains · starts in %ds", math.ceil(CycleStart - Now)))
            else
                Show("Running", "Going to plains")
                Movement.Go(PlainsCenter() + Vector3.new(0, 4, 0), 6, 60, function()
                    return getgenv().ValkyrieSession == SessionToken and getgenv().ConfigurationTable.AutoFinalSelection
                end)
            end
        elseif Phase == "Started" then
            if Now - CycleStart < PullCheck then
                Show("Running", string.format("Started · checking %ds", math.ceil(CycleStart + PullCheck - Now)))
            elseif InPlains() == false then
                Phase = "Trial"
                TrialSince = Now
            else
                Phase = "Wait"
                ReleaseModes()
                Show("Error", "Not pulled in this round")
            end
        elseif Phase == "Trial" then
            if InPlains() or Now - TrialSince > TrialCap then
                Phase = "Wait"
                ReleaseModes()
                Show("Done", "Trial over · rank " .. Profile.Rank)
            else
                Show("Running", "In trial " .. FormatTime(Now - TrialSince) .. " · auto trial runs inside")
            end
        end
    end

    -- ลำดับในกล่อง Final Selection: Status (รวม Detail) -> Auto Final
    FinalSelectionCard = MakeStatusCard(FinalSelectionSection, "Final Selection",
        { "Next", "Requirement", "Rank", "Detail" }, true)

    do
        local Set = FinalSelectionCard.Set
        local DetailLimit = 160

        function FinalSelectionCard:Set(Key, Value)
            if Key == "Detail" and type(Value) == "string" and #Value > DetailLimit then
                Value = Value:sub(1, DetailLimit) .. "..."
            end
            return Set(self, Key, Value)
        end
    end

    FinalSelectionSection:Toggle({
        Name = "Auto Final Selection",
        Flag = "SL2AutoFinalSelection",
        Default = getgenv().ConfigurationTable.AutoFinalSelection,
        Callback = function(Value)
            getgenv().ConfigurationTable.AutoFinalSelection = Value
            SaveConfiguration()
            if not Value then Movement.Cancel() end
        end
    })

    -- ตั้งค่าที่ใช้ในด่าน (ด่านเป็นอีก place ไม่มี UI - อ่านค่าที่เซฟไว้จากตรงนี้)
    task.wait()
    local TrialWeapons = Farm.WeaponChoices()
    if #TrialWeapons == 0 then TrialWeapons = { "None" } end
    -- GetWeaponNames ทำให้ thread เสีย capability ชั่วคราว (ดูโน้ตที่ BuildSettingsSection)
    task.wait()

    local TrialWeaponDropdown = FinalTrialSection:Dropdown({
        Name = "Select Weapon",
        Flag = "SL2FarmWeaponTrial",
        Items = TrialWeapons,
        KeepOrder = true,
        Default = (getgenv().ConfigurationTable.FarmWeaponTrial ~= "" and getgenv().ConfigurationTable.FarmWeaponTrial) or TrialWeapons[1],
        Multi = false,
        Seperator = false,
        Callback = function(Value)
            if type(Value) ~= "string" then return end
            getgenv().ConfigurationTable.FarmWeaponTrial = Value
            SaveConfiguration()
        end
    })
    -- ยังไม่เคยเลือก: เซฟอาวุธที่ dropdown โชว์อยู่ ด่านจะได้ถือตัวเดียวกับที่เห็น
    if getgenv().ConfigurationTable.FarmWeaponTrial == "" and TrialWeapons[1] ~= "None" then
        getgenv().ConfigurationTable.FarmWeaponTrial = TrialWeapons[1]
        SaveConfiguration()
    end
    if Farm.WeaponDropdowns then
        table.insert(Farm.WeaponDropdowns, { Dropdown = TrialWeaponDropdown, Key = "FarmWeaponTrial" })
    end

    task.wait()

    FinalTrialSection:Dropdown({
        Name = "Method",
        Flag = "SL2FarmMethodTrial",
        Items = Farm.Methods,
        Default = getgenv().ConfigurationTable.FarmMethodTrial,
        Multi = false,
        KeepOrder = true,
        Seperator = false,
        Callback = function(Value)
            if type(Value) ~= "string" then return end
            getgenv().ConfigurationTable.FarmMethodTrial = Value
            SaveConfiguration()
        end
    })

    -- เหมือน Auto Dodge ของแท็บฟาร์ม: บอส/มอนเริ่มใช้สกิล = บินหนีแล้วกลับมาตีต่อ / ปิด = ยืนเกาะตลอด
    FinalTrialSection:Toggle({
        Name = "Auto Dodge",
        Description = "Fly away when a boss or mob starts a skill, return when it ends",
        Flag = "SL2AutoDodgeTrial",
        Default = getgenv().ConfigurationTable.AutoDodgeTrial ~= false,
        Seperator = true,
        Callback = function(Value)
            getgenv().ConfigurationTable.AutoDodgeTrial = Value
            SaveConfiguration()
        end
    })

    FinalTrialSection:Toggle({
        Name = "Instant Kill",
        Description = "Boss adds only (e.g. Rogue Demon) - quest targets always take a normal kill so the quest counts",
        Flag = "SL2TrialInstantKill",
        Default = getgenv().ConfigurationTable.TrialInstantKill,
        Callback = function(Value)
            getgenv().ConfigurationTable.TrialInstantKill = Value
            SaveConfiguration()
        end
    })

    FinalTrialSection:Slider({
        Name = "Instant Kill At Health",
        Flag = "SL2TrialInstantKillHealth",
        Min = 1,
        Max = 90,
        Default = getgenv().ConfigurationTable.TrialInstantKillHealth,
        Suffix = "%",
        Seperator = false,
        Callback = function(Value)
            getgenv().ConfigurationTable.TrialInstantKillHealth = Value
            SaveConfiguration()
        end
    })

    task.spawn(function()
        while getgenv().ValkyrieSession == SessionToken do
            local Ok, Error = pcall(Tick)
            if not Ok then Show("Error", tostring(Error)) end
            task.wait(0.5)
        end
    end)
end

-- เดิมรวมอยู่แท็บ World แท็บเดียว - แยกเป็นแท็บของตัวเอง (ลำดับแท็บ = ลำดับที่สร้างตรงนี้)
local BreathingPage = Window:Page({ Name = "Breathing", Icon = "wind", Columns = 2 })
local RaidPage = Window:Page({ Name = "Sealed Cache Raid", Icon = "shield", Columns = 2 })
local FishingPage = Window:Page({ Name = "Fishing", Icon = "anchor", Columns = 2 })

do
    local Config = getgenv().ConfigurationTable
    local Utility = require(ReplicatedStorage.CAM.Global.Utility)
    local Quests = require(ReplicatedStorage.CAM.Global.Subsets.Gameplay.Quests)
    local SignalEvent = HubSignal(require(ReplicatedStorage.Communication.ServerAndClient.Signals.SignalEvent))

    -- Final Selection เป็นอีก place (Minigames Place) ที่ไม่มีโฟลเดอร์ Ouwland - อย่าให้ทั้งสคริปต์ล้ม
    local MiscContent = nil
    pcall(function() MiscContent = ReplicatedStorage.Ouwland.Content.Misc end)

    local Styles = { "Serpent", "Wind", "Insect", "Sound", "Flame", "Thunder", "Water", "Stone" }

    -- สถานีเทรนแต่ละแบบ (Code ใน task -> โฟลเดอร์ใน workspace.Training + จุดยืนใกล้สถานีให้ streaming โหลด)
    local Stations = {
        ["Meditation"] = { Folder = "Meditation", Near = { Vector3.new(-1635, 316, -193), Vector3.new(-1890, 316, 35) } },
        ["Pushups"] = { Folder = "Pushups", Near = { Vector3.new(-1679, 316, -195), Vector3.new(-1886, 316, 78) } },
        ["Squat"] = { Folder = "Squat Rack", Near = { Vector3.new(-1861, 320, -77), Vector3.new(-1797, 320, 231) } },
        ["Target Shooting"] = { Folder = "Aim Training", Near = { Vector3.new(-1475, 318, -97), Vector3.new(-1482, 318, -169) } },
        ["Cup Game"] = { Folder = "Cup Game", Near = { Vector3.new(-1894, 319, -6), Vector3.new(-1594, 320, -200) } },
        ["Boulder Split"] = { Folder = "Boulder Split", Near = { Vector3.new(-1040, 1133, -616) } },
        ["Boulder Push"] = { Folder = "Boulder Push", Near = { Vector3.new(-311, 1074, -569) } },
        -- ป้าย Train ของ Parkour Dungeon (Training."Parkour Dungeon".Ref) - เข้าด่านแล้วไปต่อที่ RunParkour
        ["Parkour Dungeon"] = { Folder = "Parkour Dungeon", Near = { Vector3.new(116, 1066, -1290) } },
    }

    local Runner = { Active = false, Style = nil, Thread = nil }

    -- Section เดียว การ์ดเดียว - SelectedStyle คือปราณที่ dropdown เลือกอยู่ตอนนี้ (ไม่จำเป็นต้อง
    -- ตรงกับ Runner.Style เผื่อ toggle ปิดอยู่แล้วผู้ใช้กำลังดูปราณอื่นเฉย ๆ) Report กรองด้วยตัวนี้
    -- กัน progress ของปราณที่ไม่ได้เลือกมาทับการ์ดที่กำลังโชว์อยู่ (ปกติมีแค่ตัวเดียวรันอยู่แล้ว
    -- เพราะ exclusive แต่กันไว้เผื่อรอยต่อตอนสลับ)
    local Card = nil
    local SelectedStyle = nil

    local function ShouldRun(Style)
        return getgenv().ValkyrieSession == SessionToken and Runner.Active and Runner.Style == Style
    end

    local function GetData()
        local Ok, Data = pcall(Utility.GetData, LocalPlayer, true)
        return Ok and Data or nil
    end

    local function GetValues()
        local Ok, Folder = pcall(Utility.getvaluesfolder, LocalPlayer)
        return Ok and Folder or nil
    end

    local function QuestId(Style)
        return "Ill learn " .. Style .. " Breathing(Lv 25)"
    end

    local function GetDef(Style)
        return Quests.Holder[QuestId(Style)]
    end

    local function CurrentBreathing()
        local Data = GetData()
        local Ok, Value = pcall(function()
            return Data.Powers.Breathing.Value
        end)
        return Ok and Value or ""
    end

    local function ItemAmount(Name)
        local Data = GetData()
        local Ok, Amount = pcall(function()
            return Data.Inventory.Inventory[Name].Amount.Value
        end)
        return Ok and Amount or 0
    end

    local function HasItem(Name)
        local Data = GetData()
        local Ok, Found = pcall(function()
            return Data.Inventory.Inventory:FindFirstChild(Name) ~= nil
        end)
        return Ok and Found
    end

    -- task เรียงตาม Need (ตัวแรก = ไม่มี Need) ของเควสที่กำลังทำอยู่
    local function GetTasks(Style)
        local Def = GetDef(Style)
        local Data = GetData()
        local Holder = Def and Data and Data.Quests:FindFirstChild("Holder")
        local Instance = Holder and Holder:FindFirstChild(Def.QuestInstance.Name)
        local Folder = Instance and Instance:FindFirstChild("Tasks")
        if not Folder then return nil end

        local ByNeed, First = { }, nil
        for _, Task in ipairs(Folder:GetChildren()) do
            local Need = Task:FindFirstChild("Need")
            if Need then ByNeed[Need.Value] = Task else First = Task end
        end

        local List, Current = { }, First
        while Current and #List < 20 do
            local Code = Current:FindFirstChild("Code")
            table.insert(List, {
                Name = Current.Name,
                Code = Code and Code.Value or Current.Name,
                Value = Current.Value.Value,
                Max = Current.Max.Value,
            })
            Current = ByNeed[Current.Name]
        end

        return List
    end

    -- ขาดอะไรบ้างก่อนรับเควส (เลเวล / Wen / ไอเทมจ่าย / อาวุธที่ต้องมี) - คืนข้อความ หรือ nil ถ้าพร้อม
    local function MissingRequirement(Style)
        local Def = GetDef(Style)
        if not Def then return "Quest not found" end

        local Requirements = Def.Requirements or { }
        if Farm.GetLevel() < (Requirements.Level or 0) then
            return "Need Lv " .. Requirements.Level
        end

        local Data = GetData()
        local Wen = Data and Data.Wen.Value or 0
        if Wen < (Def.WenCostOnAccept or 0) then
            return string.format("Need %d Wen (have %d)", Def.WenCostOnAccept, Wen)
        end

        for Item, Amount in pairs(Def.ItemCostOnAccept or { }) do
            local Have = ItemAmount(Item)
            if Have < Amount then
                return string.format("Need %s x%d (have %d)", Item, Amount, Have), Item, Amount
            end
        end

        if type(Requirements.Items) == "table" then
            local Found = false
            for _, Item in ipairs(Requirements.Items) do
                if HasItem(Item) then Found = true break end
            end
            if not Found then
                return "Need " .. Requirements.Items[1]
            end
        end

        return nil
    end

    ---- card helpers (fallback เป็น Label ถ้าไลบรารีบนเว็บยังไม่มี Section:Status) ----

    local function MakeCard(Section, Title)
        return MakeStatusCard(Section, Title, { "Style", "Task", "Detail" }, true)
    end

    local function Report(Style, State, Task, Detail, Done, Total)
        if not Card or Style ~= SelectedStyle then return end
        pcall(function()
            Card:SetState(State)
            Card:Set("Style", Style .. " Breathing")
            if Task then Card:Set("Task", Task) end
            if Detail then Card:Set("Detail", Detail) end
            if Done and Total then Card:SetProgress(Done, Total) end
        end)
    end

    ---- movement / training ----

    local function GoTo(Style, Position, Timeout)
        Movement.Lock(nil)
        return Movement.Go(Position, 4, Timeout or 60, function()
            return ShouldRun(Style)
        end)
    end

    local function FindPrompt(Folder, Near)
        local Best, BestDistance = nil, math.huge
        local Parent = workspace:FindFirstChild("Training")
        Parent = Parent and Parent:FindFirstChild(Folder)
        if not Parent then return nil end

        for _, Model in ipairs(Parent:GetChildren()) do
            local Prompt = Model:FindFirstChildWhichIsA("ProximityPrompt", true)
            if Prompt and Prompt.Enabled then
                local Holder = Prompt.Parent
                local Position = Holder:IsA("BasePart") and Holder.Position
                    or (Holder:IsA("Attachment") and Holder.WorldPosition) or Model:GetPivot().Position
                local Distance = (Position - Near).Magnitude
                if Distance < BestDistance then
                    Best, BestDistance = { Prompt = Prompt, Position = Position }, Distance
                end
            end
        end

        return Best
    end

    local function WaitFor(Check, Timeout)
        local Deadline = os.clock() + Timeout
        while os.clock() < Deadline do
            if Check() then return true end
            task.wait()
        end
        return Check()
    end

    -- Boulder Push: เซิร์ฟนับตอน boulder ที่เชื่อมกับตัว (Debree.Boulder, Weld.Part0 = HRP) "แตะ" Goal
    -- (Training."Boulder Push".Server: WeldedBoulder.Touched) - boulder อยู่หน้าตัว ~7 studs (วัดสด C0 =
    -- 0, 1.2, -7.17) ตัวละครไปยืนทับ Goal เฉย ๆ boulder เลยไม่โดน (ของเดิมวนเริ่มใหม่ไม่จบ)
    -- ยืนยันสด: หันหน้าเข้า Goal แล้วเลื่อนให้ boulder กวาดผ่าน Goal ช้า ๆ 1.5 วิ = ได้ task ทันที
    local function CarryBoulder(Style, Training)
        local Goal = Training:GetAttribute("GoalPosition")
        if typeof(Goal) ~= "Vector3" then
            local Model = workspace.Training["Boulder Push"]:FindFirstChild("Goal")
            Goal = Model and Model:GetPivot().Position
        end
        if not Goal then return false end

        local Root = Movement.GetRoot()
        if not Root then return false end

        local Offset = Vector3.new(0, 1.2, -7.17)
        pcall(function()
            for _, Part in ipairs(workspace.Debree:GetChildren()) do
                local Weld = Part.Name == "Boulder" and Part:FindFirstChild("Weld")
                if Weld and Weld.Part0 == Root then Offset = Weld.C0.Position break end
            end
        end)

        local Dir = Vector3.new(Goal.X - Root.Position.X, 0, Goal.Z - Root.Position.Z)
        Dir = Dir.Magnitude > 1 and Dir.Unit or Vector3.new(-1, 0, 0)

        -- จุดยืนของตัวละครที่ทำให้ boulder อยู่ที่ Center (หันหน้าไปทาง Dir)
        local function StandFor(Center)
            local Position = Center + Dir * Offset.Z - Vector3.new(0, Offset.Y, 0)
            return CFrame.lookAt(Position, Position + Dir)
        end

        local function Continue() return ShouldRun(Style) and Training.Parent ~= nil end

        -- ไปจุดที่ boulder ห่าง Goal 8 studs (ยกสูง 6 กันครูดพื้นระหว่างทาง)
        Movement.Lock(nil)
        Movement.Go(StandFor(Goal - Dir * 8 + Vector3.new(0, 6, 0)), 3, 30, Continue)
        Movement.Cancel()
        if not Continue() then return Training.Parent == nil end

        -- กวาด boulder ผ่าน Goal (จาก -4 ถึง +4 ตามแนว Dir) ให้ Touched ของเซิร์ฟติด
        local Start = os.clock()
        local Sweep = RunService.Heartbeat:Connect(function()
            local Here = Movement.GetRoot()
            if not Here then return end
            local Alpha = math.min((os.clock() - Start) / 1.5, 1)
            Here.CFrame = StandFor(Goal + Dir * (Alpha * 8 - 4) + Vector3.new(0, 0.5, 0))
            Here.AssemblyLinearVelocity = Dir * 6
        end)
        WaitFor(function() return not Continue() end, 4)
        Sweep:Disconnect()
        Movement.Cancel()

        return Training.Parent == nil
    end

    -- Parkour Dungeon (task แรกของ Water Breathing) - ยืนยันสดผ่าน dex (ทำจบจริง ได้ task 1/1):
    --   Training."Parkour Dungeon".Server: เริ่มได้เมื่อปลดสกิล Double Jump + Wall Climb แล้ว
    --   StateChanged(Switch) นับคันโยกเมื่อตัวละครห่าง Switch <= 20 studs (ไม่เช็ค hold/ลำดับด่าน)
    --   Stop นับ "Complete" เมื่อดึงครบทุกอันใน Switchs + ตัวละครห่าง Map.Final <= 75
    --   แตะ Final = client ของเกมยิง Stop ให้เอง แล้ววาร์ปกลับจุดเดิม (Final โหลดเฉพาะตอนอยู่ใกล้)
    local ParkourSkills = { "Double Jump", "Wall Climb" }

    -- ปลดสกิลที่ด่านต้องใช้ (UnlockSkillTreeNode แบบปุ่ม UNLOCK ใน skill tree) - คืนข้อความถ้าปลดไม่ได้
    local function EnsureParkourSkills()
        local Stats = select(2, pcall(require, ReplicatedStorage.CAM.Global.SkillService.Stats))
        local SignalFunction = HubSignal(select(2, pcall(require, ReplicatedStorage.Communication.ServerAndClient.Signals.SignalFunction)))
        if type(Stats) ~= "table" then return nil end

        for _, Skill in ipairs(ParkourSkills) do
            local Ok, Has = pcall(Stats.IsSkillUnlocked, LocalPlayer, Skill)
            if Ok and not Has then
                local Sent, Done, Why = pcall(SignalFunction.ToServer, "UnlockSkillTreeNode", Skill)
                if not (Sent and Done) then
                    return "Need " .. Skill .. " (skill tree): " .. tostring(Why or "not enough skill points")
                end
            end
        end
        return nil
    end

    local function RunParkour(Style, Training)
        local Map = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("DetachedMaps")
        Map = Map and Map:FindFirstChild("ParkourTraining")
        local Switches = Map and Map:FindFirstChild("Switchs")
        if not Switches then return false, "Parkour map not loaded" end

        local function InSession() return Training.Parent ~= nil and ShouldRun(Style) end

        task.wait(1.5) -- ฉากเปลี่ยน + client วาร์ปเข้าแมพ

        local List = Switches:GetChildren()
        table.sort(List, function(A, B)
            return (tonumber(A.Name:match("%d+")) or 0) < (tonumber(B.Name:match("%d+")) or 0)
        end)

        -- ตรึงตัวไว้ที่คันโยกตลอดตอนดึง (Movement.Lock) - วาร์ปแล้วปล่อยตัว บางอันตกลงไป/โดนดีดกลับ checkpoint
        -- (วัดสด 2026-09-27: Switch_5 วาร์ปไป 1.2 วิตัวไปอยู่ห่าง 236 studs เซิร์ฟไม่นับ -> TrainingResults false วนไม่จบ)
        for _, Switch in ipairs(List) do
            if not InSession() then Movement.Lock(nil) return false, "Parkour session ended" end
            Report(Style, "Running", nil, "Parkour: " .. Switch.Name)
            Movement.Lock(CFrame.new(Switch:GetPivot().Position + Vector3.new(0, 3, 0)))
            task.wait(0.6)  -- ให้เซิร์ฟเห็นตำแหน่งใหม่ก่อน (เช็คระยะ 20)
            pcall(SignalEvent.ToServer, "training_signaler", "StateChanged", Switch)
            task.wait(0.3)
        end
        Movement.Lock(nil)

        local Final = nil
        WaitFor(function()
            Final = Map:FindFirstChild("Final")
            return Final ~= nil and Final:IsA("BasePart")
        end, 5)
        if not Final then
            pcall(SignalEvent.ToServer, "training_signaler", "Stop")
            return false, "Parkour finish not found"
        end

        Report(Style, "Running", nil, "Parkour: finish")
        Movement.Go(CFrame.new(Final.Position + Vector3.new(0, 5, 0)))
        if not WaitFor(function() return Training.Parent == nil end, 3) then
            pcall(SignalEvent.ToServer, "training_signaler", "Stop")
            WaitFor(function() return Training.Parent == nil end, 5)
        end
        task.wait(1) -- client วาร์ปกลับจุดก่อนเข้าด่าน
        return Training.Parent == nil
    end

    local function DoTraining(Style, Code)
        local Station = Stations[Code]
        if not Station then return false, "Unsupported: " .. Code end

        local Values = GetValues()
        if not Values then return false, "No values folder" end

        -- training ค้างจากรอบก่อน (เช่นหลุดกลางคัน) ปิดก่อนเริ่มใหม่
        if Values:FindFirstChild("Training") then
            pcall(SignalEvent.ToServer, "training_signaler", "Stop", false)
            WaitFor(function() return not Values:FindFirstChild("Training") end, 3)
        end

        local Found = nil
        for _, Near in ipairs(Station.Near) do
            Report(Style, "Running", nil, "Moving to " .. Station.Folder)
            GoTo(Style, Near)
            if not ShouldRun(Style) then return false end

            WaitFor(function()
                Found = FindPrompt(Station.Folder, Near)
                return Found ~= nil
            end, 5)
            if Found then break end
        end
        if not Found then return false, "Station busy/not loaded" end

        Movement.Go(CFrame.new(Found.Position + Vector3.new(0, 3, 3)))
        task.wait(0.4)

        Report(Style, "Running", nil, "Training at " .. Station.Folder)
        Prompts.Use(Found.Prompt, { Check = function() return Values:FindFirstChild("Training") ~= nil end })

        if not WaitFor(function() return Values:FindFirstChild("Training") ~= nil end, 4) then
            return false, "Training did not start"
        end
        local Training = Values:FindFirstChild("Training")

        if Code == "Boulder Push" then
            Report(Style, "Running", nil, "Carrying boulder to goal")
            return CarryBoulder(Style, Training), "Boulder did not reach goal"
        end

        if Code == "Parkour Dungeon" then
            return RunParkour(Style, Training)
        end

        task.wait(1)
        pcall(SignalEvent.ToServer, "training_signaler", "Stop", true)

        -- Boulder Split เล่นคัตซีน ~12 วิ ก่อนจบ
        WaitFor(function() return Training.Parent == nil end, Code == "Boulder Split" and 16 or 5)
        return true
    end

    ---- pickup (เช่น Underwater Rocks ของ Water Breathing: เก็บ Sea Crystal 5 จุด) ----
    -- PickupState ของเกม: กด prompt ที่จุด = SignalEvent.ToServer("QuestProgress", เควส, task, เลขช่อง)
    -- ยิงเองหลังวาร์ปไปถึง (แบบ Jewelry Box / Permit Stamp) - ช่องที่เก็บแล้วจำไว้ ไม่ต้องยิงซ้ำ
    local PickedSlots = { }

    local function TaskValue(Style, Name)
        for _, Task in ipairs(GetTasks(Style) or { }) do
            if Task.Name == Name then return Task.Value, Task.Max end
        end
        return nil
    end

    local function DoPickup(Style, Task, Spec)
        local Positions = Spec.Positions
        if type(Positions) ~= "table" or #Positions == 0 then return false, "No pickup positions" end

        local Key = QuestId(Style) .. "/" .. Task.Name
        PickedSlots[Key] = PickedSlots[Key] or { }
        local Picked = PickedSlots[Key]

        for Slot, Position in ipairs(Positions) do
            if not ShouldRun(Style) then return false end
            local Value, Max = TaskValue(Style, Task.Name)
            if not Value or Value >= Max then return true end

            if not Picked[Slot] and typeof(Position) == "Vector3" then
                Report(Style, "Running", nil, string.format("Pickup %d/%d (spot %d)", Value, Max, Slot))
                GoTo(Style, Position + Vector3.new(0, 3, 0))
                task.wait(0.4)
                Farm.QuestProgress(QuestId(Style), Task.Name, Slot)
                WaitFor(function() return (TaskValue(Style, Task.Name) or 0) > Value end, 2)
                -- เก็บได้ หรือยิงแล้วไม่ขึ้น (ช่องนี้เก็บไปแล้วจากรอบก่อน) = ข้ามช่องนี้
                Picked[Slot] = true
            end
        end

        local Value, Max = TaskValue(Style, Task.Name)
        if Value and Value < Max then
            -- ครบทุกช่องแล้วยังไม่ถึง = ล้างที่จำไว้ รอบหน้าลองใหม่หมด
            PickedSlots[Key] = nil
            return false, "Pickup not counted, retrying"
        end
        return true
    end

    ---- trainee ----

    local function FindTrainee(Style)
        local Regions = workspace:FindFirstChild("Humanoids") and workspace.Humanoids:FindFirstChild("Regions")
        if not Regions then return nil end

        for _, Region in ipairs(Regions:GetChildren()) do
            local Active = Region:FindFirstChild("ActiveNpcs")
            if Active then
                for _, Folder in ipairs(Active:GetChildren()) do
                    if Folder.Name:sub(1, #Style + 8) == Style .. " Trainee" then
                        local Model = Folder:FindFirstChildOfClass("Model")
                        local Humanoid = Model and Model:FindFirstChildOfClass("Humanoid")
                        local Root = Model and Model:FindFirstChild("HumanoidRootPart")
                        if Humanoid and Root and Humanoid.Health > 0 then
                            return { Model = Model, Humanoid = Humanoid, Root = Root }
                        end
                    end
                end
            end
        end

        return nil
    end

    local function TraineeSpawn(Style)
        if not MiscContent then return nil end

        for _, Module in ipairs(MiscContent.ActiveNpcs:GetChildren()) do
            if Module.Name:sub(1, #Style + 8) == Style .. " Trainee" then
                local Ok, Npc = pcall(require, Module)
                if Ok then return Npc.SendOver.Spawning.Center end
            end
        end
        return nil
    end

    -- ตีเป้าจนตาย (ใช้ทั้งลูกศิษย์ และมอนที่ฟาร์มหาไอเทม) - คืนตำแหน่งที่มันตาย ถ้าฆ่าได้
    local function FightTarget(Style, Mob, Label)
        -- ทั้งฟังก์ชัน (จุดยืน/เดินเข้าหา/ตี) ใช้ Method/Mode ของ Breathing Settings - ModeSetting อ่านตาม
        -- suffix "Breathing" (FarmMethodBreathing / FarmModeBreathing) แล้วคืน suffix เดิมตอนจบ
        local PreviousSuffix = getgenv().ValkyrieFarmSuffix
        getgenv().ValkyrieFarmSuffix = "Breathing"

        -- อาวุธจาก Breathing Settings ก่อน ไม่ได้เลือก = อาวุธฟาร์มหลักแบบเดิม
        local Weapon = Config.FarmWeaponBreathing
        if type(Weapon) ~= "string" or Weapon == "" or Weapon == "None" then Weapon = Config.FarmWeapon end
        if type(Weapon) == "string" and Weapon ~= "" and Weapon ~= "None" then
            Farm.EquipWeapon(Weapon)
        end

        local Alive = function() return ShouldRun(Style) and Farm.IsMobAlive(Mob) end
        local Stand = Farm.BuildStandCFrame(Mob.Root.CFrame)

        if (Movement.GetRoot().Position - Stand.Position).Magnitude > 15 then
            Report(Style, "Running", nil, "Moving to " .. Label)
            Movement.Lock(nil)
            Movement.Go(Stand, 6, 30, Alive)
        end

        -- ตัวตีเดียวกับ Auto Farm (Fighter.FightMob: ต่อคอมโบตามเลขของ server / หลบสกิลบอส)
        Fighter.Reset()
        Fighter.Continue = Alive

        local ShownHealth = nil
        while Alive() do
            local Root = Movement.GetRoot()
            if not Root then break end

            local Health = math.floor(Mob.Humanoid.Health)
            if Health ~= ShownHealth then
                ShownHealth = Health
                Report(Style, "Running", nil, string.format("Fighting %s %d/%d HP", Label, Health, Mob.Humanoid.MaxHealth))
            end

            Fighter.FightMob(Mob, Root)
            -- Breathing ไม่มี Instant Kill (ลบออกตามที่สั่ง - ฆ่าแบบนั้นเควสไม่นับ/ไม่ดรอปของ)
            task.wait()
        end

        getgenv().ValkyrieFarmSuffix = PreviousSuffix
        if Fighter.Continue == Alive then Fighter.Continue = nil end
        Fighter.AttackTarget = nil
        Movement.Lock(nil)

        if not Farm.IsMobAlive(Mob) then
            local Ok, Position = pcall(function() return Mob.Root.Position end)
            return Ok and Position or nil
        end
        return nil
    end

    local function FightTrainee(Style)
        local Mob = FindTrainee(Style)
        if not Mob then
            local Spawn = TraineeSpawn(Style)
            Report(Style, "Waiting", nil, "Trainee respawning")
            if Spawn then GoTo(Style, Spawn + Vector3.new(0, 4, 0)) end
            task.wait()
            return
        end

        -- ลูกศิษย์เป็นบอส (มี BossInfo) ตายแล้วเกิดกล่องเหมือนบอสทั่วไป - เก็บเสมอ
        local DiedAt = FightTarget(Style, Mob, "trainee")
        if DiedAt then
            Report(Style, "Running", nil, "Collecting trainee chest")
            Farm.CollectBossLoot(DiedAt, function() return ShouldRun(Style) end)
        end
    end

    --// ไอเทมจ่ายตอนรับเควสไม่พอ -> ไปฟาร์มเองจนครบ แล้วค่อยกลับไปรับเควส
    -- Demon Horns: ยืนยันสด Blood Hounded Demon ดรอปเข้ากระเป๋าตรง ๆ (~3 อัน / 2.5 นาที)
    -- Beast Core: หาแหล่งในโค้ด client ไม่เจอ (ตารางดรอปอยู่ฝั่งเซิร์ฟ) - ใช้ตัวเดียวกันไปก่อน
    -- แก้ getgenv().BreathingItemSources = { ["Beast Core"] = "<MonName>" } ทับได้ถ้ารู้แหล่งที่แน่กว่า
    local ItemSources = getgenv().BreathingItemSources or {
        ["Demon Horns"] = "Blood Hounded Demon",
        ["Beast Core"] = "Blood Hounded Demon",
    }

    local function FarmItem(Style, Item, Need)
        local MonName = ItemSources[Item]
        local Entry = MonName and Farm.GetEntryByName(MonName)
        if not Entry then return false end

        local Have = ItemAmount(Item)
        Report(Style, "Running", "Farm " .. Item, string.format("%d/%d from %s", Have, Need, MonName), Have, Need)

        local Root = Movement.GetRoot()
        local Mob = Root and Farm.GetNearestMobByName(Root.Position, MonName)
        if not Mob then
            GoTo(Style, Entry.WaitPOS or Entry.MonPOS)
            task.wait()
            return true
        end

        local DiedAt = FightTarget(Style, Mob, MonName)
        if DiedAt and Mob.IsBoss then
            Farm.CollectBossLoot(DiedAt, function() return ShouldRun(Style) end)
        end
        return true
    end

    ---- main loop ----

    local function Step(Style)
        local Def = GetDef(Style)

        if CurrentBreathing() == Style then
            Report(Style, "Done", "Learned", Style .. " Breathing", 1, 1)
            return "Done"
        end

        local State = Quests.GetPlayerQuestState(LocalPlayer, QuestId(Style))
        local Tasks = State == "Doing" and GetTasks(Style)

        if not Tasks then
            local Missing, Item, Need = MissingRequirement(Style)
            if Missing and Item and FarmItem(Style, Item, Need) then
                return
            elseif Missing then
                Report(Style, "Error", "Requirement", Missing, 0, 1)
                return "Stop"
            end

            if not MiscContent then
                Report(Style, "Error", "Requirement", "Not in the main world", 0, 1)
                return "Stop"
            end

            local Trainer = require(MiscContent.Npcs[Style .. " Trainer"])
            Report(Style, "Running", "Accept quest", "Going to " .. Trainer.Name, 0, 1)
            GoTo(Style, Trainer.Spawns[1].Position + Vector3.new(0, 3, 0))
            if not ShouldRun(Style) then return end

            if not Farm.AcceptQuestById(QuestId(Style)) then
                Report(Style, "Waiting", "Accept quest", "Quest cooldown, retrying")
                task.wait()
            end
            return
        end

        local Done, Current = 0, nil
        for _, Task in ipairs(Tasks) do
            if Task.Value >= Task.Max then
                Done = Done + 1
            elseif not Current then
                Current = Task
            end
        end

        if not Current then
            -- ทุก task ครบแต่ Power ยังไม่เปลี่ยน = เซิร์ฟกำลังให้รางวัล รอแป๊บ
            Report(Style, "Waiting", "Finishing", "Waiting for reward", Done, #Tasks)
            task.wait()
            return
        end

        Report(Style, "Running", Current.Name, nil, Done, #Tasks)

        local Spec = Def and Def.TaskSpecs and Def.TaskSpecs[Current.Name]

        if Current.Code:find("Trainee$") then
            FightTrainee(Style)
        elseif Spec and Spec.Type == "Pickup" then
            local Ok, Reason = DoPickup(Style, Current, Spec)
            if not Ok and ShouldRun(Style) then
                Report(Style, "Waiting", Current.Name, Reason or "Retrying", Done, #Tasks)
                task.wait(2)
            end
        elseif Current.Code == "Parkour Dungeon" and EnsureParkourSkills() then
            Report(Style, "Error", Current.Name, EnsureParkourSkills(), Done, #Tasks)
            return "Stop"
        elseif Stations[Current.Code] then
            local Ok, Reason = DoTraining(Style, Current.Code)
            if not Ok and ShouldRun(Style) then
                Report(Style, "Waiting", Current.Name, Reason or "Retrying", Done, #Tasks)
                task.wait(2)
            end
        else
            Report(Style, "Error", Current.Name, "Not automated yet", Done, #Tasks)
            return "Stop"
        end
    end

    local SetBreathing

    local function RunBreathing()
        while getgenv().ValkyrieSession == SessionToken and Runner.Active do
            local Style = Runner.Style
            -- ทั้งลูป (เดินไปหา trainer/station/ลูกศิษย์ + ตี) ใช้ Breathing Settings - ModeSetting อ่านตาม
            -- suffix นี้ ตั้งทุกรอบเพราะ TurnOffFlags ปิดโหมดฟาร์มทีหลังแล้ว SetMode คืน suffix เป็น "" ได้
            getgenv().ValkyrieFarmSuffix = "Breathing"
            local Ok, Result = pcall(Step, Style)

            -- error/ติดเงื่อนไข ("Stop") = ไม่ปิด toggle เอง (ผู้ใช้สั่ง) - โชว์เหตุผลค้างไว้แล้วลองใหม่ทุก 10 วิ
            -- ปิดเองเฉพาะเรียนจบจริง ("Done")
            if not Ok then
                Report(Style, "Error", nil, tostring(Result):sub(1, 60))
                task.wait(2)
            elseif Result == "Done" and Runner.Style == Style then
                SetBreathing(Style, false, true)
                break
            elseif Result == "Stop" then
                local Until = os.clock() + 10
                while os.clock() < Until and Runner.Active and Runner.Style == Style
                    and getgenv().ValkyrieSession == SessionToken do
                    task.wait()
                end
            end

            task.wait()
        end

        if getgenv().ValkyrieFarmSuffix == "Breathing" then getgenv().ValkyrieFarmSuffix = "" end
        Movement.Cancel()
        Runner.Thread = nil
    end

    -- เปิดได้ทีละปราณ + ปิดโหมดฟาร์ม (ขยับตัวละครชนกัน) / KeepToggle = ไม่ต้องสั่งปิด toggle เอง
    -- (จบเอง - Done/Stop ใน RunBreathing เรียกมาแล้วอยาก sync ปุ่มให้ตรงตามจริง)
    SetBreathing = function(Style, Value, KeepToggle)
        SelectedStyle = Style

        if Value then
            Runner.Style = Style
            Runner.Active = true
            Config.AutoBreathing = Style

            TurnOffFlags(ExclusiveFlags.Farm)
            TurnOffFlags(ExclusiveFlags.Puzzle)
            TurnOffFlags(ExclusiveFlags.Fishing)
            TurnOffFlags(ExclusiveFlags.Quest)

            if not Runner.Thread then
                Runner.Thread = task.spawn(RunBreathing)
            end
        elseif Runner.Style == Style and Runner.Active then
            Runner.Active = false
            Config.AutoBreathing = ""
            Movement.Cancel()

            if KeepToggle then
                -- หยุดเอง (เรียนจบ/error ค้าง) - ปุ่ม toggle ยังค้างโชว์ ON อยู่ สั่งปิดให้ตรงกับจริง
                local Set = Library.SetFlags and Library.SetFlags["SL2AutoBreathing"]
                if Set then pcall(Set, false) end
            else
                Report(Style, "Idle", "-", "Stopped")
            end
        end

        SaveConfiguration()
    end

    -- ชื่อ Trainer + ค่าใช้จ่ายของปราณนั้น (สำหรับ description ของ dropdown) - เหมือนเดิมทุกอย่าง
    -- แค่คำนวณตามปราณที่เลือกอยู่ ไม่ใช่สร้างไว้ล่วงหน้าทั้ง 8 ตัวแบบเดิม
    local function TrainerInfo(Style)
        local Def = GetDef(Style)
        local Trainer = MiscContent and select(2, pcall(require, MiscContent.Npcs[Style .. " Trainer"])) or nil

        local Costs = { string.format("%d Wen", Def and Def.WenCostOnAccept or 0) }
        for Item, Amount in pairs(Def and Def.ItemCostOnAccept or { }) do
            table.insert(Costs, string.format("%d %s", Amount, Item))
        end

        return (type(Trainer) == "table" and Trainer.Name or "Trainer") .. " · " .. table.concat(Costs, " · ")
    end

    -- โชว์สถานะปัจจุบันของปราณที่เลือกอยู่บนการ์ด (ไม่ยุ่งตอนกำลังฟาร์มปราณนี้อยู่จริง - RunBreathing
    -- อัปเดตสดของมันเองอยู่แล้ว เรียกซ้ำตรงนี้แค่ทับด้วยข้อมูลเก่าเปล่า ๆ)
    local function RefreshCard()
        local Style = SelectedStyle
        if not Style then return end

        if Runner.Active and Runner.Style == Style then return end

        if CurrentBreathing() == Style then
            Report(Style, "Done", "Learned", Style .. " Breathing", 1, 1)
            return
        end

        local Tasks = Quests.GetPlayerQuestState(LocalPlayer, QuestId(Style)) == "Doing" and GetTasks(Style)
        if Tasks then
            local Done = 0
            for _, Task in ipairs(Tasks) do
                if Task.Value >= Task.Max then Done = Done + 1 end
            end
            Report(Style, "Idle", "Quest in progress", string.format("%d/%d tasks done", Done, #Tasks), Done, #Tasks)
        else
            local Missing = MissingRequirement(Style)
            Report(Style, "Idle", "-", Missing or "Ready", 0, 1)
        end
    end

    local BreathingSection = BreathingPage:Section({
        Name = "Breathing",
        Description = "Learn any breathing style automatically",
        Icon = "80758916183665",
        Side = 1
    })

    -- ตั้งค่าตอนตี (อาวุธ + Method + Mode) กล่องขวา แบบ Trial Settings ของ Final Selection (ไม่มี instant kill)
    local BreathingSettingsSection = BreathingPage:Section({
        Name = "Breathing Settings",
        Description = "Weapon, method and mode while learning",
        Icon = "93142176757189",
        Side = 2
    })

        SelectedStyle = (Config.SelectedBreathingStyle ~= "" and table.find(Styles, Config.SelectedBreathingStyle) and Config.SelectedBreathingStyle)
        or (Config.AutoBreathing ~= "" and table.find(Styles, Config.AutoBreathing) and Config.AutoBreathing)
        or Styles[1]

    local InfoLabel = BreathingSection:Label(TrainerInfo(SelectedStyle))

    -- การ์ดสถานะอยู่บนสุดของ section (สร้างก่อน = LayoutOrder แรก)
    Card = MakeCard(BreathingSection, "Breathing")

    -- เริ่มที่ปราณตัวที่เคยเลือกไว้ (เซฟไว้) -> ตัวที่กำลัง Auto อยู่ (โหลดสคริปต์ใหม่ระหว่างฟาร์ม)
    -- -> ตัวแรกในลิสต์ ตามลำดับ

    task.wait()

    BreathingSection:Dropdown({
        Name = "Select Breathing",
        Flag = "SL2BreathingStyle",
        Items = Styles,
        Default = SelectedStyle,
        Multi = false,
        Seperator = false,
        Callback = function(Value)
            if type(Value) ~= "string" or Value == "" then return end

            local Was = SelectedStyle
            SelectedStyle = Value
            Config.SelectedBreathingStyle = Value
            SaveConfiguration()

            InfoLabel:SetText(TrainerInfo(Value))

            -- สลับปราณระหว่าง Auto เปิดอยู่ = ย้ายไปฟาร์มตัวใหม่ทันที ไม่ต้องปิดเปิด toggle เอง
            if Runner.Active and Was ~= Value then
                SetBreathing(Was, false, true)
                SetBreathing(Value, true)
            else
                RefreshCard()
            end
        end
    })

    BreathingSection:Toggle({
        Name = "Auto Breathing",
        Flag = "SL2AutoBreathing",
        Default = Config.AutoBreathing ~= "",
        Seperator = true,
        Callback = function(Value)
            SetBreathing(SelectedStyle, Value)
        end
    })

    -- Breathing Settings = section ตั้งค่าชุดเดียวกับแท็บฟาร์มอื่น (Weapon/Method/Mode/Distance/Speed/Dodge)
    -- คีย์ต่อท้าย "Breathing" - RunBreathing ตั้ง suffix นี้ทั้งลูป ModeSetting เลยอ่านชุดนี้
    task.wait()
    if Farm.BuildSettingsSection then
        local BreathingWeaponDropdown = Farm.BuildSettingsSection(BreathingSettingsSection, "Breathing")
        if Farm.WeaponDropdowns then
            table.insert(Farm.WeaponDropdowns, { Dropdown = BreathingWeaponDropdown, Key = "FarmWeaponBreathing" })
        end
    end

    task.wait()

    --// Auto Upgrade Skill Tree - ปลดสกิลของปราณที่เรียนแล้วใน skill tree ทีละขั้นเมื่อถึงเงื่อนไข
    -- ยืนยันผ่าน dex (หน้า Menu."Skill Tree" CenterEquipped + SkillService):
    --   SkillTreeholder.GetBranches(ผู้เล่น) มี branch ชื่อเดียวกับปราณ (เช่น "Water") ลูกคือสกิลเรียงตามลำดับ
    --   (Water Surface Slash > Whirl Pool > Water Wheel > Constant Flux > Dead Calm) ต้องปลดตัวก่อนหน้าก่อน
    --   เงื่อนไข = Stats.GetRequirements(ผู้เล่น, สกิล) เช่น { SkillPoints = 6, Mastery = 14 } / Boss = "Giyen"
    --   เช็คแต่ละข้อด้วย SkillTreeholder.RequirementsSolver[ชื่อ].CanBuy(ผู้เล่น, ชื่อสกิล, ค่า) แบบปุ่ม UNLOCK
    --   (Mastery เทียบ MasteryProgressionList[หมวดของสกิล].Goal / exp ต่อ Mastery)
    --   ปลด = SignalFunction.ToServer("UnlockSkillTreeNode", ชื่อสกิล) คืน false, เหตุผล ถ้าไม่ผ่าน
    task.wait()
    local TreeLabel = BreathingSection:Label("Skill Tree: -")

    BreathingSection:Toggle({
        Name = "Auto Upgrade Skill Tree",
        Description = "Unlocks the next skill of your breathing once you have the skill points and mastery",
        Flag = "SL2AutoUpgradeBreathingTree",
        Default = Config.AutoUpgradeBreathingTree,
        Callback = function(Value)
            Config.AutoUpgradeBreathingTree = Value
            SaveConfiguration()
        end
    })

    task.spawn(function()
        local Tree, Stats, SignalFunction = nil, nil, nil
        pcall(function()
            Tree = require(ReplicatedStorage.CAM.Global.SkillService.SkillTreeholder)
            Stats = require(ReplicatedStorage.CAM.Global.SkillService.Stats)
            SignalFunction = HubSignal(require(ReplicatedStorage.Communication.ServerAndClient.Signals.SignalFunction))
        end)
        if not (Tree and Stats and SignalFunction) then return end

        local Shown = nil
        local function Show(Text)
            if Text == Shown then return end
            Shown = Text
            task.wait() -- เรียก API เกมมาก่อน = thread เสีย capability ชั่วคราว คั่นก่อนแตะ UI
            pcall(function() TreeLabel:SetText(Text) end)
        end

        -- คืน ชื่อสกิลถัดไปที่ยังไม่ปลด, เงื่อนไขที่ยังขาด (ว่าง = ปลดได้) / nil ถ้าครบหมดแล้ว
        local function NextNode(Style)
            local Ok, Branches = pcall(Tree.GetBranches, LocalPlayer)
            if not Ok or type(Branches) ~= "table" then return nil end

            for _, Branch in ipairs(Branches) do
                if type(Branch) == "table" and Branch.Name == Style then
                    for _, Node in ipairs(Branch) do
                        local Unlocked = select(2, pcall(Stats.IsSkillUnlocked, LocalPlayer, Node.Name))
                        if not Unlocked then
                            local Missing = { }
                            local Requirements = select(2, pcall(Stats.GetRequirements, LocalPlayer, Node.Name))
                            for Key, Value in pairs(type(Requirements) == "table" and Requirements or { }) do
                                local Solver = Tree.RequirementsSolver and Tree.RequirementsSolver[Key]
                                local Can = Solver and select(2, pcall(Solver.CanBuy, LocalPlayer, Node.Name, Value))
                                if Can ~= true then
                                    table.insert(Missing, tostring(Key) .. " " .. tostring(Value))
                                end
                            end
                            table.sort(Missing)
                            return Node.Name, Missing
                        end
                    end
                    return nil
                end
            end
            return nil
        end

        while getgenv().ValkyrieSession == SessionToken do
            local Style = CurrentBreathing()
            if Style == "" then
                Show("Skill Tree: no breathing learned yet")
            else
                local Name, Missing = NextNode(Style)
                if not Name then
                    Show("Skill Tree: " .. Style .. " - all skills unlocked")
                elseif #Missing > 0 then
                    Show(string.format("Skill Tree: next %s - need %s", Name, table.concat(Missing, ", ")))
                elseif Config.AutoUpgradeBreathingTree then
                    local Sent, Done, Why = pcall(SignalFunction.ToServer, "UnlockSkillTreeNode", Name)
                    if Sent and Done ~= false then
                        Show("Skill Tree: unlocked " .. Name)
                        pcall(function() Library:Notify("Skill Tree", "Unlocked " .. Name, 5) end)
                    else
                        Show(string.format("Skill Tree: %s failed - %s", Name, tostring(Why or Done)))
                        task.wait(10)
                    end
                else
                    Show("Skill Tree: " .. Name .. " ready to unlock")
                end
            end
            task.wait(3)
        end
    end)

    RefreshCard()

    -- เปิดค้างไว้จากเซฟรอบก่อน (SetBreathing ในนี้ตั้ง SelectedStyle ให้ตรงกับตัวที่กำลังฟาร์มเองอยู่แล้ว)
    if Config.AutoBreathing ~= "" and table.find(Styles, Config.AutoBreathing) and not InTrialPlace then
        SetBreathing(Config.AutoBreathing, true)
    end
end

--// Sealed Cache Raid - ตัวรันจริงอยู่ในบล็อก AutoFarm (RunFarm โหมด "Camp" / DoCampStep)
-- ที่นี่มีแค่ UI: เลือก tier + toggle เปิดโหมด (ชนกับโหมดฟาร์ม/ปราณอื่นเหมือนกัน SetFarmMode ปิดให้เอง)
do
    local Config = getgenv().ConfigurationTable

    -- บล็อก Breathing ข้างบนเรียก API เกม (Utility.GetData ฯลฯ) ทำให้ thread เสีย capability - คั่นก่อนสร้าง Instance
    task.wait()

    local RaidCacheSection = RaidPage:Section({
        Name = "Sealed Cache Raid",
        Description = "Clear camp guards · open caches",
        Icon = "80758916183665",
        Side = 1
    })

    local Tiers = Farm.GetCacheInfo().Tiers
    if #Tiers == 0 then Tiers = { "T1", "T2", "T3" } end

    if type(Config.RaidCacheTiers) ~= "table" then Config.RaidCacheTiers = { } end

    local Saved = { }
    for _, Tier in ipairs(Tiers) do
        if Config.RaidCacheTiers[Tier] == true then table.insert(Saved, Tier) end
    end

    task.wait()

    RaidCacheSection:Dropdown({
        Name = "Select Tier",
        Flag = "SL2RaidCacheTiers",
        Items = Tiers,
        Default = Saved,
        Multi = true,
        Seperator = false,
        Callback = function(Value)
            if type(Value) ~= "table" then return end

            -- ทุก tier ที่รู้จักเซฟค่าไว้เสมอ (ตัวที่ไม่เลือก = false) ให้ MergeConfiguration ไม่เติมกลับเป็น true
            for _, Tier in ipairs(Tiers) do
                Config.RaidCacheTiers[Tier] = table.find(Value, Tier) ~= nil
            end
            SaveConfiguration()
        end
    })

    task.wait()

    RaidCacheSection:Toggle({
        Name = "Auto Raid Sealed Cache",
        Flag = "SL2AutoRaidCache",
        Default = Config.AutoRaidCache,
        Callback = function(Value)
            if SetFarmMode then SetFarmMode("Camp", Value) end
        end
    })

    -- Settings แบบแท็บฟาร์มอื่น (อาวุธ/Method/Mode/Distance/Speed/Dodge - คีย์ต่อท้าย "Raid")
    -- + Instant Kill การ์ดแคมป์ (ตีโดน 1 ครั้งได้ ownership แล้วฆ่าทันที - มอนที่โดน instant kill ไม่ดรอปของ)
    local RaidSettingsSection = RaidPage:Section({
        Name = "Raid Settings",
        Description = "Weapon, position and instant kill",
        Icon = "93142176757189",
        Side = 2
    })

    if Farm.BuildSettingsSection then
        local RaidWeaponDropdown = Farm.BuildSettingsSection(RaidSettingsSection, "Raid")
        if Farm.WeaponDropdowns then
            table.insert(Farm.WeaponDropdowns, { Dropdown = RaidWeaponDropdown, Key = "FarmWeaponRaid" })
        end
    end

    task.wait()

    RaidSettingsSection:Toggle({
        Name = "Instant Kill",
        Description = "Kill camp guards instantly after the first hit (they drop nothing)",
        Flag = "SL2RaidInstantKill",
        Default = Config.RaidInstantKill,
        Callback = function(Value)
            Config.RaidInstantKill = Value
            SaveConfiguration()
        end
    })

    RaidSettingsSection:Slider({
        Name = "Instant Kill At Health",
        Flag = "SL2RaidInstantKillHealth",
        Min = 1,
        Max = 90,
        Default = Config.RaidInstantKillHealth,
        Suffix = "%",
        Seperator = false,
        Callback = function(Value)
            Config.RaidInstantKillHealth = Value
            SaveConfiguration()
        end
    })
end

-- การ์ดสถานะเดียวของ Unlock Quest + Upgrade Rod: โหมดที่รันอยู่เป็นเจ้าของการ์ด (Owner)
-- โหมดอื่น/ตัวอัปเดตตอนว่างเขียนทับไม่ได้จนกว่าเจ้าของจะหยุด (สองโหมดนี้รันพร้อมกันไม่ได้อยู่แล้ว)
local FishingStatus = { Card = nil, Section = nil, Owner = nil }

function FishingStatus.Write(Owner, State, Rows)
    if FishingStatus.Owner and FishingStatus.Owner ~= Owner then return end
    local Card = FishingStatus.Card
    if not Card then return end
    pcall(function()
        Card:SetState(State or "Running")
        for Key, Value in pairs(Rows) do Card:Set(Key, Value) end
    end)
end

--// Auto Unlock Fishing - เควส "Ill find the permit stamp(Lv 45)" ของ Dock Master Sofen (Mistfall Harbor)
--
-- ยืนยันจาก Quests.Holder + QuestStates["Earn a Fishing Permit"] (PickupState) ผ่าน dex:
--   รับเควส: Lv 45+, จ่าย 5000 Wen ตอนรับ (WenCostOnAccept) - AddQuest ต้องยืนใกล้ Sofen
--   1) "Permit Stamp found" (Pickup): เกมสร้างของ + ProximityPrompt ที่ Positions[1] ฝั่ง client
--      กดแล้วยิง SignalEvent.ToServer("QuestProgress", เควส, task, เลขช่อง) - MaxDistance 25 = ต้องยืนใกล้
--      เลยยิง event เองหลังวาร์ปไปถึง (แบบเดียวกับสายเนื้อเรื่องสปาย) ไม่ต้องรอ prop/กด prompt
--   2) "Return to Sofen" (Deliver ต้องถือ Permit Stamp): คุยกับ Sofen = QuestProgress(เควส, task)
--   รางวัล: Fishing Permit + 2700 Exp (LogCompletion = GetQuestState "Done" ถาวร)
-- ทำทีละขั้น วนทุกเฟรม (task.wait()) จนเควส Done แล้วปิดตัวเอง
do
    local Config = getgenv().ConfigurationTable
    local Quests = nil
    pcall(function() Quests = require(ReplicatedStorage.CAM.Global.Subsets.Gameplay.Quests) end)

    local QuestId = "Ill find the permit stamp(Lv 45)"
    local PickupTask = "Permit Stamp found"
    local ReturnTask = "Return to Sofen"
    local Def = Quests and Quests.Holder[QuestId]
    local NpcName = Def and Def.OfferNpc or "Dock Master Sofen"
    local NeedLevel = Def and Def.Requirements and Def.Requirements.Level or 45
    local NeedWen = Def and Def.WenCostOnAccept or 5000
    local StampPos = nil
    pcall(function() StampPos = Def.TaskSpecs[PickupTask].Positions[1] end)

    local Fishing = { Active = false, Thread = nil, Status = "-" }
    local StepGapAt = 0     -- ยิง event ไม่ผ่าน = เว้นช่วงก่อนยิงใหม่ (ไม่ยิงทุกเฟรม)

    local function ShouldRun()
        return getgenv().ValkyrieSession == SessionToken and Fishing.Active
    end

    local function Wen()
        local Ok, Value = pcall(function()
            return require(ReplicatedStorage.CAM.Global.Utility).GetData(LocalPlayer).Wen.Value
        end)
        return Ok and tonumber(Value) or 0
    end

    local function Report(Status, State)
        Fishing.Status = Status
        local Level, Money = Farm.GetLevel(), Wen()
        local Quest = Farm.GetQuestState(QuestId)
        -- GetData ข้างบน = thread เสีย capability ชั่วคราว (ดูโน้ตที่ Select Weapon) - คั่นก่อนแตะ UI
        task.wait()
        FishingStatus.Write("Unlock", State, {
            Mode = "Unlock Quest",
            Step = Status,
            Progress = string.format("Quest %s | Lv %d/%d | Wen %d/%d", tostring(Quest), Level, NeedLevel, Money, NeedWen),
        })
    end

    local function GoTo(Target)
        Movement.Lock(nil)
        Movement.Go(Target, 4, 30, ShouldRun)
        Movement.Cancel()               -- Teleport ทิ้ง noclip ไว้ = ร่วงทะลุท่าเรือ (ดู Fishing engine)
        Farm.Sleep(0.3, ShouldRun)      -- ให้เซิร์ฟเห็นตำแหน่งใหม่ก่อนยิง event (เซิร์ฟเช็คระยะ)
    end

    -- Sofen โหลดตาม region (streaming) - อยู่ไกลไม่มีโมเดล -> ไปจุดเกิด (Regions.GetNpcSpawn) รอโหลด
    -- แล้วขยับไปยืนหน้าตัวจริง (เดิมหาโมเดลไม่เจอ = ไม่บินไป ยิง AddQuest จากไกล เซิร์ฟเงียบ วนไม่จบ)
    local function GoToSofen()
        local Target, Live = Farm.NpcStandCFrame(NpcName)
        if not Target then return false end
        GoTo(Target)
        if not Live then
            Farm.WaitFor(function() return select(2, Farm.NpcStandCFrame(NpcName)) == true end, 3, ShouldRun)
            local Real, IsLive = Farm.NpcStandCFrame(NpcName)
            if Real and IsLive then GoTo(Real) end
        end
        return true
    end

    -- ทำ 1 ขั้น - คืน true = จบ (ปลดล็อกแล้ว / ทำต่อไม่ได้) พร้อมสถานะ
    local function Step()
        local State = Farm.GetQuestState(QuestId)

        if State == "Done" or Farm.HasItem("Fishing Permit") then
            return true, "Unlocked - you have the Fishing Permit", "Done"
        end

        if State ~= "Doing" then
            if Farm.GetLevel() < NeedLevel then
                return true, string.format("Need Lv %d (you are Lv %d)", NeedLevel, Farm.GetLevel()), "Error"
            end
            if Wen() < NeedWen then
                return true, string.format("Need %d Wen to accept the quest", NeedWen), "Error"
            end
            if os.clock() < StepGapAt then return false end

            Report("Talking to " .. NpcName .. " (accept quest)")
            if not GoToSofen() then return true, NpcName .. " position not found", "Error" end
            if not Farm.AcceptQuestById(QuestId) then StepGapAt = os.clock() + 2 end
            return false
        end

        -- 1) เก็บ Permit Stamp (ของเควส GrantItem) - มีในกระเป๋าแล้ว = ข้าม
        if not Farm.HasItem("Permit Stamp") then
            if not StampPos then return true, "Stamp position not found", "Error" end
            if os.clock() < StepGapAt then return false end

            Report("Picking up Permit Stamp at the docks")
            GoTo(CFrame.new(StampPos + Vector3.new(0, 3, 0)))
            Farm.QuestProgress(QuestId, PickupTask, 1)
            if not Farm.WaitFor(function() return Farm.HasItem("Permit Stamp") end, 2, ShouldRun) then
                StepGapAt = os.clock() + 2
            end
            return false
        end

        -- 2) ถือ Stamp แล้ว -> ส่งให้ Sofen
        if os.clock() < StepGapAt then return false end
        Report("Returning the stamp to " .. NpcName)
        if not GoToSofen() then return true, NpcName .. " position not found", "Error" end
        Farm.QuestProgress(QuestId, ReturnTask)
        if not Farm.WaitFor(function() return Farm.GetQuestState(QuestId) ~= "Doing" end, 2, ShouldRun) then
            StepGapAt = os.clock() + 2
        end
        return false
    end

    local SetFishing

    local function RunFishing()
        while ShouldRun() do
            task.wait()
            -- error / ติดเงื่อนไข (เลเวล/เงินไม่ถึง) = ไม่ปิด toggle เอง ลองใหม่ทุก 5 วิ - ปิดเฉพาะปลดล็อกแล้ว
            local Ok, Finished, Message, State = pcall(Step)
            if not Ok then
                Report("Error: " .. tostring(Finished):sub(1, 80) .. " - retrying", "Error")
                Farm.Sleep(5, ShouldRun)
            elseif Finished then
                Report(Message, State)
                if State == "Done" then
                    Library:Notify("Fishing", "Fishing unlocked", 5)
                    break
                end
                Farm.Sleep(5, ShouldRun)
            end
        end

        Movement.Lock(nil)
        Fishing.Thread = nil
        if FishingStatus.Owner == "Unlock" then FishingStatus.Owner = nil end
        if Fishing.Active then SetFishing(false, true) end
    end

    SetFishing = function(Value, SyncToggle)
        if Value then
            TurnOffFlags(ExclusiveFlags.Farm)
            TurnOffFlags(ExclusiveFlags.Breathing)
            TurnOffFlags(ExclusiveFlags.Puzzle)
            TurnOffFlags(ExclusiveFlags.Fishing, "SL2AutoUnlockFishing")
            TurnOffFlags(ExclusiveFlags.Quest)
            FishingStatus.Owner = "Unlock"
            Fishing.Active = true
            StepGapAt = 0
            if not Fishing.Thread then Fishing.Thread = task.spawn(RunFishing) end
        else
            Fishing.Active = false
            Movement.Lock(nil)
            if SyncToggle then
                local Set = Library.SetFlags and Library.SetFlags["SL2AutoUnlockFishing"]
                if Set then pcall(Set, false) end
            end
        end
    end

    task.wait()

    local FishingSection = FishingPage:Section({
        Name = "Unlock & Upgrade",
        Description = "Get the permit, then upgrade your rod",
        Icon = "80758916183665",
        Side = 1
    })
    FishingStatus.Section = FishingSection

    FishingSection:Guide("How to use", {
        "Need Lv 45+ and some Wen",
        "Turn on Auto Unlock Fishing to get the permit",
        "Turn on Auto Upgrade Rod to go Basic -> Rare -> Legendary (it fishes for the items itself)",
    })

    FishingStatus.Card = MakeStatusCard(FishingSection, "Fishing Status", { "Mode", "Step", "Progress", "Gear" }, false, true)

    task.wait()

    FishingSection:Toggle({
        Name = "Auto Unlock Fishing",
        Flag = "SL2AutoUnlockFishing",
        Default = getgenv().ConfigurationTable.AutoUnlockFishing == true,
        Callback = function(Value)
            getgenv().ConfigurationTable.AutoUnlockFishing = Value == true   -- รันใหม่เปิดกลับเอง (ดูท้ายแท็บ Fishing)
            SaveConfiguration()
            SetFishing(Value)
        end
    })
end

--// Fishing engine - Auto Upgrade Rod (Basic -> Rare -> Legendary) / Auto Fishing
--
-- ยืนยันสดผ่าน dex (decompile ToolScripts["Rare Fishing Rod"] ทั้งฝั่ง client + Server ที่อยู่ใน ReplicatedStorage):
--   ซื้อ: เบ็ด = SignalEvent.ToServer("PurchaseFromShop", ชื่อ, 1) (Basic 3500 Wen)
--         Worm = ตะกร้าร้าน Jeso: SignalFunction.ToServer("PurchaseSelection", { Worm = n }) ต้องยืนใกล้ Jeso
--         (ยืน 21 studs คืน false เงียบ ๆ / 5 studs ได้ของ)
--   ใส่เบ็ดลง Toolbar = ToServer("Toolbar_Equip", ชื่อช่อง, Id) / ใส่เหยื่อ = ToServer("EquipBait", Id) (0 = ถอด)
--   เหวี่ยง = ToServer("Tool_Mouse", "Down"/"Up", จุดน้ำ) (MouseUp ฝั่งเซิร์ฟ: ยังไม่เหวี่ยง = เหวี่ยง,
--     เหวี่ยงอยู่ = ม้วนเก็บ, มีปลาห้อยสาย = ปล่อยปลาลงพื้น)
--   ปลากิน: เซิร์ฟยิง portal "FishingRod" ("Bite", token) -> ตอบ portal:Server(token, true)
--     เซิร์ฟนับว่าได้ปลาเฉพาะตอบหลังกิน >= 4.5 วิ (BiteVerdict = os.clock() - BiteAt >= 4.5) ไม่มี timeout
--     = ดึงทันทีไม่ได้ / มินิเกม BarKeepup ของเกมตอบ false เองตอน ~3.9 วิถ้าไม่มีคนเล่น
--     เลยแทน Callback ของ portal ไม่ให้เปิดมินิเกม แล้วตอบเองตอนครบ 4.5 วิ
--   ไม่ใส่เหยื่อก็ตกได้ (วัดสด 3 รอบ: Sea Horse, ว่าง, OuwFwesh - กินช้ากว่า Worm นิดหน่อย 8.8-11 วิ)
--   ได้ปลา = โมเดล workspace.Debree.FishingCatch_N (attribute CatchItem) ห้อยสาย -> คลิกปล่อยลงพื้น
--     แล้วกด prompt "Collect" (HoldDuration 2, เซิร์ฟเช็คเวลากดค้าง) ถึงเข้ากระเป๋า / ปล่อยทิ้งไว้ 20 วิหาย
--     ตอนปลาห้อยสาย prompt ไม่ขึ้น (วัดสด) - ต้องปล่อยก่อน ปลาจมลงพื้นน้ำ เลยวาร์ปตามไปเก็บ
--   Rare Fishing Rod = Golden Fish 5 + 10000 Wen ที่ Jeso
--   Legendary (Isao, NightOnly): ถือ Drowned Lure + Crustadon 2 + Krathulon 2 ตอนกลางคืน คุยกับ Isao
--     = ToServer("IsaoTakeToll") (DockActions) -> WorldEvents.DrownedLine_Paid แล้วค่อยไปงมเบ็ดที่ท้ายน้ำ
--     ที่มาของ Drowned Lure + จุดงมเบ็ดอยู่ฝั่งเซิร์ฟ (SAM.WorldEvents.DrownedLine) อ่านไม่ได้ - ยังไม่ทำอัตโนมัติ
do
    local function Require(Path)
        local Ok, Module = pcall(function() return require(Path()) end)
        return Ok and Module or nil
    end

    local Config = getgenv().ConfigurationTable
    local SignalEvent = HubSignal(Require(function() return ReplicatedStorage.Communication.ServerAndClient.Signals.SignalEvent end))
    local SignalFunction = HubSignal(Require(function() return ReplicatedStorage.Communication.ServerAndClient.Signals.SignalFunction end))
    local Portals = Require(function() return ReplicatedStorage.CAM.Global.ServerClientPortal end)
    local Shop = Require(function() return ReplicatedStorage.CAM.Global.Shop end)
    local Items = Require(function() return ReplicatedStorage.CAM.Global.Collectibles.Items end)
    local Utility = Require(function() return ReplicatedStorage.CAM.Global.Utility end)
    local DayNight = Require(function() return ReplicatedStorage.CAM.Global.DayAndNightHandler end)

    local Rods = { "Basic Fishing Rod", "Rare Fishing Rod", "Legendary Fishing Rod" }
    local SlotNames = { "One", "Two", "Three", "Four", "Five" }
    local Spots = { "Jeso Dock", "Where I Stand" }

    -- ตัวเลือกเหยื่อ = ไอเทมทุกตัวที่มี BaitTier (ตัดแพ็ก Robux ที่เป็นกล่องรวม) เรียงตาม tier
    local BaitChoices = { "Best Owned" }
    pcall(function()
        local Names = { }
        for Name, Def in pairs(Items) do
            if type(Def) == "table" and Def.BaitTier and not Def.PackContents then
                table.insert(Names, Name)
            end
        end
        table.sort(Names, function(A, B)
            if Items[A].BaitTier ~= Items[B].BaitTier then return Items[A].BaitTier < Items[B].BaitTier end
            return A < B
        end)
        for _, Name in ipairs(Names) do table.insert(BaitChoices, Name) end
    end)
    local StarterBait = "Worm"
    local BaitBatch = 50                -- ซื้อทีละ 50 ตัว (6 Wen/ตัว)
    -- เซิร์ฟรับว่าดึงสำเร็จเมื่อตอบหลังปลากิน >= 4.5 วิ (decompile RodServer: ตอบเร็วกว่า = AntiCheat.Report
    -- "FishingWin" + นับว่าหลุด) = ดึงทันที/hook ข้ามไม่ได้ เผื่อ 0.1 วิกันโดน report บัญชี
    local BiteHold = 4.6
    local BiteTimeout = 30              -- รอปลากินสูงสุด (สุ่ม 4-9 วิ / BiteSpeed)
    local TollFish = { Crustadon = 2, Krathulon = 2 }
    local IsaoSpawn = Vector3.new(-214.58, 797, 61.06)  -- Npcs.Isao.Spawns[1]
    local PermitQuest = "Ill find the permit stamp(Lv 45)"

    local RarePrice = { ["Golden Fish"] = 5, Wen = 10000 }
    pcall(function() RarePrice = Items["Rare Fishing Rod"].Price end)
    local BasicPrice = 3500
    pcall(function() BasicPrice = Items["Basic Fishing Rod"].Price.Wen end)

    -- Mode = "Fish" (Auto Fishing) / Upgrade = รอของครบแล้วไปซื้อ-แลกเบ็ด
    -- Busy = กำลังเหวี่ยง/เก็บปลาอยู่ / Hold = Upgrade ขอหยุด Auto Fishing ชั่วคราวระหว่างไปซื้อ
    local Engine = {
        Mode = nil, Thread = nil, Upgrade = false, UpgradeThread = nil,
        Busy = false, Hold = false, Stand = nil, LastCatch = "-", Caught = 0,
    }
    getgenv().ValkyrieFishing = Engine      -- ดูสถานะสด (Engine.Status) ผ่าน dex
    -- Missed = os.clock() ตอนเซิร์ฟยิง BiteMissed/BiteCancel มา (ปลาหลุด/ผู้เล่นม้วนเบ็ดเอง) - ใช้เลิกรอทันที
    local Bite = { Token = nil, At = 0, Missed = 0 }
    local Hooked = nil                  -- { Portal, Original, Callback } portal ที่แทน Callback ไว้
    local AutoCard = nil
    local StepGapAt = 0                 -- Auto Fishing เว้นช่วงหลัง error
    local UpgradeGapAt = 0              -- Auto Upgrade Rod เช็คของทุก 1 วิ (แยกกัน ไม่ถ่วงกัน)

    local function Session()
        return getgenv().ValkyrieSession == SessionToken
    end

    local function ShouldRun()
        -- Auto Fishing ไม่ใช่ตาของมัน (Priority: โหมดฟาร์มที่สูงกว่ามีงาน) = ปล่อยตัวละครให้ฟาร์ม
        if Engine.Mode == "Fish" and not Engine.Upgrade and Farm.FishTurn and not Farm.FishTurn() then return false end
        return Session() and (Engine.Mode ~= nil or Engine.Upgrade)
    end

    local function Data()
        return Utility.GetData(LocalPlayer, true)
    end

    local function Inventory()
        local Ok, Folder = pcall(function() return Data().Inventory.Inventory end)
        return Ok and Folder or nil
    end

    local function Count(Name)
        local Total = 0
        local Folder = Inventory()
        for _, Entry in ipairs(Folder and Folder:GetChildren() or { }) do
            if Entry.Name == Name then
                local Amount = Entry:FindFirstChild("Amount")
                Total = Total + (Amount and Amount.Value or 1)
            end
        end
        return Total
    end

    local function ItemId(Name)
        local Folder = Inventory()
        local Entry = Folder and Folder:FindFirstChild(Name)
        local Id = Entry and Entry:FindFirstChild("Id")
        return Id and Id.Value or nil
    end

    local function Wen()
        local Ok, Value = pcall(function() return Data().Wen.Value end)
        return Ok and tonumber(Value) or 0
    end

    local function HasPermit()
        return Farm.HasItem("Fishing Permit") or Farm.GetQuestState(PermitQuest) == "Done"
    end

    local function BestRod()
        for Index = #Rods, 1, -1 do
            if Count(Rods[Index]) > 0 then return Rods[Index] end
        end
        return nil
    end

    -- เหยื่อที่ดีที่สุดที่มี (BaitTier สูงสุด) - Drowned Lure (BaitTier 99) เก็บไว้ขั้น Legendary ไม่ใช้ตกปลาปกติ
    local function BestBait()
        local Best, BestTier = nil, -1
        local Folder = Inventory()
        for _, Entry in ipairs(Folder and Folder:GetChildren() or { }) do
            local Def = Items[Entry.Name]
            local Tier = Def and Def.BaitTier
            if Tier and Tier < 99 and Tier > BestTier then
                Best, BestTier = Entry.Name, Tier
            end
        end
        return Best
    end

    local function EquippedBaitId()
        local Ok, Value = pcall(function() return Data():FindFirstChild("EquippedBaitId", true).Value end)
        return Ok and Value or nil
    end

    local function EquippedBaitName()
        local Id = EquippedBaitId()
        if not Id or Id == 0 then return nil end
        local Folder = Inventory()
        for _, Entry in ipairs(Folder and Folder:GetChildren() or { }) do
            local EntryId = Entry:FindFirstChild("Id")
            if EntryId and EntryId.Value == Id then return Entry.Name end
        end
        return nil
    end

    -- เวลาปลากิน (RodServer): task.wait(สุ่ม 4-9 / max(BiteSpeedMultiplier x (1 + "Bite Speed Factor"), 0.05))
    --   BiteSpeedMultiplier = Items.Fishing.<เบ็ด>.FishingStats (Basic ไม่ระบุ = 1 / Rare 1.5 / Legendary 3)
    --     + เหยื่อ (Worm +0.25) - รวมกันฝั่งเซิร์ฟ (FishingHandler.GetCombinedStats อยู่ ServerStorage อ่านไม่ได้
    --     เลยบวกกันตามที่เห็น: ใช้แค่แสดงผล/ตั้งเวลารอ เผื่อเกินไว้แล้ว)
    --   "Bite Speed Factor" = Title (Titles.GetStatBonus: Title ที่ใส่ช่อง Boost 3 ช่อง + โบนัสสะสมจาก Title
    --     ที่ปลดล็อก) เช่น angler +3% / deep_water_angler +5% / legendary_fisherman +5%
    local TitlesModule = Require(function() return ReplicatedStorage.CAM.Global.Titles end)

    local function FishingStats(Name)
        local Module = Name and ReplicatedStorage.Items.Fishing:FindFirstChild(Name)
        local Ok, Def = pcall(require, Module)
        return Ok and type(Def) == "table" and type(Def.FishingStats) == "table" and Def.FishingStats or { }
    end

    -- คืน { Min, Max (วินาที), Factor (buff Title), Multiplier } ของเบ็ด+เหยื่อที่ใช้อยู่
    local function BiteWindow(Rod)
        local Multiplier = (FishingStats(Rod or BestRod()).BiteSpeedMultiplier or 1)
            + (FishingStats(EquippedBaitName()).BiteSpeedMultiplier or 0)
        local Factor = 0
        pcall(function() Factor = tonumber(TitlesModule.GetStatBonus(LocalPlayer, "Bite Speed Factor")) or 0 end)
        local Speed = math.max(Multiplier * (1 + Factor), 0.05)
        return { Min = 4 / Speed, Max = 9 / Speed, Factor = Factor, Multiplier = Multiplier }
    end
    Engine.BiteWindow = BiteWindow

    local function BiteText(Window)
        local Buff = Window.Factor > 0 and string.format(", title +%d%%", math.floor(Window.Factor * 100 + 0.5)) or ", no title buff"
        return string.format("%.1f-%.1fs%s", Window.Min, Window.Max, Buff)
    end

    --// Auto Equip Best Title - ใส่ Title ตกปลาที่ดีที่สุดลงช่อง Boost ระหว่าง Auto Fishing
    -- remote (TitleController ของเกม): SignalEvent.ToServer("TitleRequest", { action = "equipBoost", titleId, slot })
    --   / { action = "unequipBoost", slot } - ช่องอยู่ที่ GetData().EquippedTitles.Boost.Slot1-3 (Value = id / "")
    -- ใส่ได้เฉพาะ Title ที่ปลดล็อกแล้ว (PlayerTitles.Unlocked) เรียงตาม Bite Speed Factor ก่อน แล้วค่อย Fishing Luck
    -- ก่อนใส่ = จดของเดิมทั้ง 3 ช่องลง Config (FishingSavedTitles - reinject ก็คืนได้) / เลิกตกหรือปิด toggle
    -- = ใส่อันเก่ากลับก่อน ช่องที่เดิมว่างค่อยถอดออก
    local TitleSlots = 3
    pcall(function() TitleSlots = TitlesModule.BoostSlots or 3 end)

    local function BoostSlots()
        local Slots = { }
        pcall(function()
            local Boost = Data().EquippedTitles.Boost
            for Index = 1, TitleSlots do
                local Slot = Boost:FindFirstChild("Slot" .. Index)
                Slots[Index] = Slot and Slot.Value or ""
            end
        end)
        for Index = 1, TitleSlots do Slots[Index] = Slots[Index] or "" end
        return Slots
    end

    local function FishingTitleScore(Def)
        local Bite, Luck = 0, 0
        for _, Buff in ipairs(type(Def) == "table" and Def.buffs or { }) do
            if Buff.stat == "Bite Speed Factor" then Bite = Bite + (tonumber(Buff.amount) or 0) end
            if Buff.stat == "Fishing Luck Factor" then Luck = Luck + (tonumber(Buff.amount) or 0) end
        end
        return Bite, Luck
    end

    --// Title สายต่อสู้ (ผู้ใช้ 2026-10-02: ฟาร์มอยู่ = ใส่ Title ดาเมจ) - ดาเมจก่อน (Breathing = Slayer / Evil Art = Demon)
    -- แล้วค่อยเลือด/ป้องกัน/สตามินา ฯลฯ - ค่าแต่ละ stat เทียบกับค่าสูงสุดของ Title ทั้งเกม (Titles.Definitions)
    local TitleStatMax = nil
    local function CombatTitleScore(Def, Race)
        if not TitleStatMax then
            TitleStatMax = { }
            pcall(function()
                for _, Other in pairs(TitlesModule.Definitions) do
                    for _, Buff in ipairs(type(Other) == "table" and Other.buffs or { }) do
                        local Amount = tonumber(Buff.amount) or 0
                        if Amount > (TitleStatMax[Buff.stat] or 0) then TitleStatMax[Buff.stat] = Amount end
                    end
                end
            end)
        end
        local Damage = {
            ["Additional Damage"] = true, ["Additional Damage Factor"] = true, ["Attack Speed Factor"] = true,
            ["Breathing Damage Factor"] = Race ~= "Demon", ["Evil Art Damage Factor"] = Race ~= "Slayer",
        }
        -- รอง: เลือด/ป้องกัน > กัน > สตามินา > ความเร็ว (วัดสด: น้ำหนักเท่ากันเลือก prospector วิ่งเร็วแทน highclimber +20 HP)
        local Support = { ["Max Health"] = 1, ["Damage Reduction"] = 1, ["Damage Reduction Factor"] = 1, ["Block Regen"] = 0.5,
            ["Max Stamina"] = 0.3, ["Stamina Regen Speed"] = 0.25, ["Movement Speed Factor"] = 0.1 }
        local Main, Rest = 0, 0
        for _, Buff in ipairs(type(Def) == "table" and Def.buffs or { }) do
            local Max = TitleStatMax[Buff.stat] or 0
            local Value = Max > 0 and (tonumber(Buff.amount) or 0) / Max or 0
            if Damage[Buff.stat] then Main = Main + Value else Rest = Rest + Value * (Support[Buff.stat] or 0) end
        end
        return Main * 10 + Rest
    end

    -- Title ที่ปลดล็อกแล้วของสายนั้น ("Fishing" / "Combat") เรียงดีสุดก่อน (สูงสุดเท่าจำนวนช่อง)
    local function BestTitles(Kind)
        local List = { }
        pcall(function()
            local Stats, Profile = Utility.GetData(LocalPlayer, true)
            local Race = Stats and Stats:FindFirstChild("Race") and Stats.Race.Value
            for _, Unlocked in ipairs(Profile.PlayerTitles.Unlocked:GetChildren()) do
                local Def = TitlesModule.Get(Unlocked.Name)
                if Kind == "Fishing" then
                    local Bite, Luck = FishingTitleScore(Def)
                    if Bite > 0 or Luck > 0 then table.insert(List, { Id = Unlocked.Name, Score = Bite * 100 + Luck }) end
                else
                    local Score = CombatTitleScore(Def, Race)
                    if Score > 0 then table.insert(List, { Id = Unlocked.Name, Score = Score }) end
                end
            end
        end)
        table.sort(List, function(A, B)
            if A.Score ~= B.Score then return A.Score > B.Score end
            return A.Id < B.Id
        end)
        while #List > TitleSlots do table.remove(List) end
        return List
    end

    local function TitleRequest(Payload)
        pcall(function() SignalEvent.ToServer("TitleRequest", Payload) end)
    end

    local function WaitSlot(Index, Value)
        Farm.WaitFor(function() return BoostSlots()[Index] == Value end, 2)
    end

    -- ใส่ Title ดีสุดของสายนั้น: ตัวที่ใส่อยู่แล้วคงไว้ / ลงช่องว่างก่อน แล้วค่อยทับช่องที่ไม่ใช่ตัวที่ต้องการ
    local function ApplyBestTitles(Kind)
        local Best = BestTitles(Kind)
        if #Best == 0 then return false, "No title unlocked" end

        local Slots = BoostSlots()
        if type(Config.FishingSavedTitles) ~= "table" then
            Config.FishingSavedTitles = table.clone(Slots)
            SaveConfiguration()
        end

        local Wanted = { }
        for _, Title in ipairs(Best) do Wanted[Title.Id] = true end
        local Placed = { }
        for Index, Id in ipairs(Slots) do
            if Wanted[Id] then Placed[Id] = Index end
        end

        for _, Title in ipairs(Best) do
            if not Placed[Title.Id] then
                local Target = nil
                for Index, Id in ipairs(Slots) do          -- ช่องว่างก่อน
                    if Id == "" then Target = Index break end
                end
                if not Target then
                    for Index, Id in ipairs(Slots) do      -- ไม่มีช่องว่าง = ทับช่องที่ไม่ใช่ตัวที่ต้องการ
                        if not Wanted[Id] then Target = Index break end
                    end
                end
                if not Target then break end
                TitleRequest({ action = "equipBoost", titleId = Title.Id, slot = Target })
                WaitSlot(Target, Title.Id)
                Slots[Target] = Title.Id
                Placed[Title.Id] = Target
            end
        end
        return true
    end

    -- คืน Title เดิม: ใส่อันเก่ากลับก่อน แล้วช่องที่เดิมว่างค่อยถอด
    local function RestoreTitles()
        local Saved = Config.FishingSavedTitles
        if type(Saved) ~= "table" then return end

        local Slots = BoostSlots()
        for Index = 1, TitleSlots do
            local Old = Saved[Index] or ""
            if Old ~= "" and Slots[Index] ~= Old then
                TitleRequest({ action = "equipBoost", titleId = Old, slot = Index })
                WaitSlot(Index, Old)
            end
        end
        Slots = BoostSlots()
        for Index = 1, TitleSlots do
            if (Saved[Index] or "") == "" and Slots[Index] ~= "" then
                TitleRequest({ action = "unequipBoost", slot = Index })
                WaitSlot(Index, "")
            end
        end

        Config.FishingSavedTitles = nil
        SaveConfiguration()
    end
    Engine.RestoreTitles = RestoreTitles

    -- ตัวคุม Auto Best Title (หน้า Equipment): ตกปลาอยู่ = Title ตกปลา / ฟาร์ม-ตีอยู่ (Fighter.Continue - ฟาร์มทุกแท็บ
    -- ด่าน หอ) = Title ดาเมจ / ว่าง = คงที่ใส่อยู่ / ปิด toggle = คืน Title เดิม
    if Config.FishingBestTitle == true then Config.AutoBestTitle = true end   -- เซฟเก่า (toggle เดิมในหน้า Fishing)
    Config.FishingBestTitle = nil
    local TitleBusy = false
    local function SyncTitles()
        if TitleBusy then return end
        TitleBusy = true
        local Kind = nil
        if Session() and Config.AutoBestTitle == true then
            if (Engine.Mode == "Fish" and (not Farm.FishTurn or Farm.FishTurn())) or Engine.Mode == "Legendary" then
                Kind = "Fishing"
            elseif Fighter.Continue ~= nil then
                Kind = "Combat"
            end
        end
        pcall(function()
            if Kind then
                ApplyBestTitles(Kind)
            elseif Config.AutoBestTitle ~= true and type(Config.FishingSavedTitles) == "table" then
                RestoreTitles()
            end
        end)
        TitleBusy = false
    end
    Farm.SyncTitles = SyncTitles
    Engine.SyncTitles = SyncTitles

    local function GearText()
        local Rod, Bait = BestRod(), EquippedBaitName()
        return string.format("%s | %s", Rod or "No rod", Bait and string.format("%s x%d", Bait, Count(Bait)) or "No bait")
    end

    local function IsNight()
        if not DayNight then return false end
        local Ok, Night = pcall(function() return not DayNight.IsEnabled() or DayNight.IsNight() end)
        return Ok and Night == true
    end

    local function WorldEvent(Name)
        local Ok, Found = pcall(function()
            local Events = Data():FindFirstChild("WorldEvents")
            return Events ~= nil and Events:FindFirstChild(Name) ~= nil
        end)
        return Ok and Found
    end

    local function TollPaid()
        return WorldEvent("DrownedLine_Paid")
    end

    local function Goal(Rod)
        if not HasPermit() then return "Fishing locked - no Fishing Permit" end
        if not Rod then return string.format("Basic Fishing Rod: Wen %d/%d", Wen(), BasicPrice) end
        if Rod == "Basic Fishing Rod" then
            return string.format("Rare: Golden Fish %d/%d, Wen %d/%d",
                Count("Golden Fish"), RarePrice["Golden Fish"] or 5, Wen(), RarePrice.Wen or 10000)
        elseif Rod == "Rare Fishing Rod" then
            return string.format("Legendary: Crustadon %d/2, Krathulon %d/2, Drowned Lure %s",
                Count("Crustadon"), Count("Krathulon"), Count("Drowned Lure") > 0 and "yes" or "no")
        end
        return "Legendary Fishing Rod - max rod"
    end

    -- Auto Fishing เขียนการ์ดของตัวเอง (Upgrade ใช้ UpgradeReport เขียนการ์ดรวม)
    local function Report(Status, State)
        if not (Session() and Engine.Mode) then return end     -- หยุดแล้ว = ไม่เขียนทับ Stopped
        Engine.Status = Status
        local Gear = GearText()
        task.wait()     -- GetData = thread เสีย capability ชั่วคราว - คั่นก่อนแตะ UI
        if AutoCard then
            pcall(function()
                AutoCard:SetState(State or "Running")
                AutoCard:Set("Step", Status)
                AutoCard:Set("Gear", Gear)
                AutoCard:Set("Catches", tostring(Engine.Caught))
                AutoCard:Set("Last Catch", Engine.LastCatch)
            end)
        end
    end

    local function NpcPivot(Name)
        local Regions = workspace:FindFirstChild("Debree") and workspace.Debree:FindFirstChild("Regions")
        for _, Region in ipairs(Regions and Regions:GetChildren() or { }) do
            local Stationary = Region:FindFirstChild("StationaryNpcs")
            local Npc = Stationary and Stationary:FindFirstChild(Name)
            if Npc then
                local Ok, Pivot = pcall(Npc.GetPivot, Npc)
                if Ok then return Pivot end
            end
        end
        return nil
    end

    -- จุดเกิด Jeso จาก Npcs module (ใช้ตอน region ท่าเรือยังไม่โหลด เช่นเพิ่งเกิดใหม่ไกล ๆ)
    local JesoSpawn = nil
    pcall(function()
        JesoSpawn = require(ReplicatedStorage.Ouwland.Content["Mistfall Harbor"].Npcs["Fisherman Jeso"]).Spawns[1]
    end)
    if typeof(JesoSpawn) ~= "CFrame" then
        JesoSpawn = CFrame.new(-192.001, 806.932, 602.667) * CFrame.Angles(0, math.pi / 2, 0)
    end

    -- ท่าหน้า Jeso 4 studs หันออกทะเล (Jeso หัน -X ไปทางน้ำ วัดสด: เหวี่ยงลงน้ำได้)
    local function JesoStand()
        local Pivot = NpcPivot("Fisherman Jeso") or JesoSpawn
        return Pivot * CFrame.new(0, 0, -4)
    end

    -- จุดตกปลาบนท่า (-196, 803, 566) หันออกทะเล (-X) - จุดที่ผู้ใช้เลือกเอง (ยืนบนพื้นไม้ท่าเรือ)
    -- ยืนหน้า Jeso ไม่ได้: prompt คุยกับ Jeso (5 studs) + ป้ายร้านเบ็ด (ปุ่ม T เดียวกัน, OnePerButton)
    -- แย่งโชว์ prompt Collect ของปลา = กดเก็บตอนปลาห้อยสายไม่ติด (ต้องยืนห่าง Jeso ออกมาแบบนี้)
    local DockPosition = Vector3.new(-196, 803, 566)

    local function DockStand()
        return CFrame.new(DockPosition, DockPosition + Vector3.new(-1, 0, 0))
    end

    -- จุดยืน + จุดเหวี่ยง (ข้างหน้า 15 studs ต่ำลง 10 - เซิร์ฟ raycast หาน้ำจากข้างบนจุดนี้เอง)
    -- Engine.Job = งานตกปลาพิเศษของ Auto Legendary Rod { Stand, Target, Bait, Lose } ทับจุด/เหยื่อ/วิธีดึงปกติ
    -- ผิวน้ำใต้จุดนี้ (สูงสุดที่ไม่สูงกว่าตัวเรา) จากกรอบก้อนน้ำ SwimParts (client CanQuery = false raycast ไม่โดน)
    -- เซิร์ฟ findWater ยิง ray จากบนลงไปถึงแค่ "Y ของเป้า - 25" -> เป้าต้องอยู่ที่ผิวน้ำ ยืนสูงกว่าน้ำเกิน ~35 studs
    -- (หน้าผาจุด Legendary น้ำต่ำลงไป 132) แล้วเป้า "ข้างหน้า 15 ต่ำลง 10" แบบเดิม = หาน้ำไม่เจอ เหวี่ยงไม่ลง
    local SwimService = game:GetService("CollectionService")
    local function WaterBelow(Point, Ceiling)
        local Best = nil
        for _, Water in ipairs(SwimService:GetTagged("SwimParts")) do
            if Water:IsA("BasePart") then
                local Local = Water.CFrame:PointToObjectSpace(Point)
                local Half = Water.Size / 2
                local Surface = Water.Position.Y + Half.Y
                if math.abs(Local.X) <= Half.X and math.abs(Local.Z) <= Half.Z and Surface <= Ceiling + 2
                    and (not Best or Surface > Best) then
                    Best = Surface
                end
            end
        end
        return Best
    end

    local function Spot()
        if Engine.Job then return Engine.Job.Stand, Engine.Job.Target end
        local Stand = DockStand()
        if Engine.Mode == "Fish" and Config.FishingSpot == "Where I Stand" and Engine.Stand then
            Stand = Engine.Stand
        end
        if not Stand then return nil end
        -- เป้า = ผิวน้ำตรงข้างหน้า (ไล่ 15 -> 30 studs หาจุดแรกที่มีน้ำ) ไม่เจอ = ต่ำลง 10 แบบเดิม
        for _, Reach in ipairs({ 15, 20, 25, 30, 10 }) do
            local Ahead = Stand.Position + Stand.LookVector * Vector3.new(1, 0, 1) * Reach
            local Surface = WaterBelow(Ahead, Stand.Position.Y)
            if Surface then return Stand, Vector3.new(Ahead.X, Surface, Ahead.Z) end
        end
        return Stand, Stand.Position + Stand.LookVector * 15 - Vector3.new(0, 10, 0)
    end

    local function GoTo(Target)
        Movement.Lock(nil)
        Movement.Go(Target, 3, 30, ShouldRun)
        -- Teleport ทิ้งตัวละครไว้แบบ noclip = ร่วงทะลุท่าเรือลงน้ำ (วัดสด) - คืนการชนก่อนยืนตกปลา
        Movement.Cancel()
        Farm.Sleep(0.4, ShouldRun)      -- ให้เซิร์ฟเห็นตำแหน่งใหม่ก่อนยิง (ร้าน/NPC เช็คระยะ)
    end

    -- ไปยืนที่จุด - คืน false ถ้าไปไม่ถึง (ตัวละครหาย)
    local function GoNear(Stand)
        if not Stand then return false end
        local Root = Movement.GetRoot()
        if not Root then return false end
        if (Root.Position - Stand.Position).Magnitude > 5 then GoTo(Stand) end
        Root = Movement.GetRoot()
        if not Root or (Root.Position - Stand.Position).Magnitude > 8 then return false end
        -- ยืนใกล้จุดอยู่แล้ว (ไม่วาร์ป) = ยังหันทางเดิม -> หมุนอยู่กับที่ให้หันตามจุดยืน (ลงน้ำ)
        -- วัดสด (จุด Legendary): ตั้ง CFrame ครั้งเดียว anti-cheat ดึงกลับ แล้วเหวี่ยงรอบถัดไปเซิร์ฟ pinCharacter
        -- (FishingReelPin anchored ที่ CFrame ฝั่งเซิร์ฟ) ล็อกตัวหันทางเก่าตลอด -> รอ pin เก่าหลุด แล้วค้างหมุน 2.2 วิ
        -- แบบเดียวกับวาร์ป (Movement.Teleport) พอเซิร์ฟเห็นทิศใหม่ pin รอบต่อไปก็หันทางนี้เอง
        local Want = Stand.LookVector * Vector3.new(1, 0, 1)
        local Have = Root.CFrame.LookVector * Vector3.new(1, 0, 1)
        if Want.Magnitude > 0.1 and Have.Magnitude > 0.1 and Want.Unit:Dot(Have.Unit) < 0.97 then
            Farm.WaitFor(function()
                local Debree = workspace:FindFirstChild("Debree")
                for _, Pin in ipairs(Debree and Debree:GetChildren() or { }) do
                    local Weld = Pin.Name == "FishingReelPin" and Pin:FindFirstChildOfClass("Weld")
                    if Weld and Weld.Part1 == Root then return false end
                end
                return true
            end, 3, ShouldRun)
            Movement.Teleport(CFrame.new(Root.Position, Root.Position + Want), 2.2, ShouldRun)
            Movement.Cancel()
        end
        return true
    end

    local function BuyRod(Name)
        if not GoNear(JesoStand()) then return false, "Fisherman Jeso not found" end
        local Can, Why = Shop.CanBuy(LocalPlayer, Name, nil, 1)
        if not Can then return false, "Cannot buy " .. Name .. ": " .. tostring(Why or "?") end
        SignalEvent.ToServer("PurchaseFromShop", Name, 1)
        if Farm.WaitFor(function() return Count(Name) > 0 end, 3, ShouldRun) then return true end
        return false, "Bought " .. Name .. " but it did not arrive"
    end

    -- ร้านเหยื่อ: Worm = Fisherman Jeso / Fish Head = Baitmonger Nori (Hidden Mist Village - ปลดเมื่อเควสยาของ
    -- Shiori Done) ทั้งคู่เป็นตะกร้า PurchaseSelection ต้องยืนติด NPC / ตัวที่ดีกว่าอยู่หน้า (Best Owned หมด = ซื้อตัวนี้ก่อน)
    local BaitShops = { { Name = "Fish Head", Npc = "Baitmonger Nori" }, { Name = StarterBait, Npc = "Fisherman Jeso" } }

    local function BaitShop(Name)
        for _, Shop2 in ipairs(BaitShops) do
            if Shop2.Name == Name then return Shop2 end
        end
        return nil
    end

    -- ซื้อได้ไหม (ร้านปลดแล้ว + เงินพอสักตัว) - ไม่ได้ = nil, เหตุผล
    local function CanBuyBait(Name)
        if not BaitShop(Name) then return nil, Name .. " is not sold in a shop" end
        local Ok, Can, Why = pcall(Shop.CanBuy, LocalPlayer, Name, nil, 1)
        if not (Ok and Can) then
            return nil, "Cannot buy " .. Name .. (Why and ": " .. tostring(Why):gsub("<[^>]+>", "") or "")
        end
        return true
    end

    local function BuyBait(Name)
        Name = Name or StarterBait
        local Can, Reason = CanBuyBait(Name)
        if not Can then return false, Reason end
        local Npc = BaitShop(Name).Npc
        if Npc == "Fisherman Jeso" then
            if not GoNear(JesoStand()) then return false, "Fisherman Jeso not found" end
        else
            Movement.Lock(nil)
            local Found = Farm.GoToNpc(Npc, ShouldRun)
            Movement.Cancel()           -- Teleport ทิ้ง noclip = ร่วงทะลุพื้น
            if not Found then return false, Npc .. " not found" end
            Farm.Sleep(0.4, ShouldRun)  -- ให้เซิร์ฟเห็นตำแหน่งใหม่ก่อนซื้อ (ไกลเซิร์ฟคืน false เงียบ)
        end
        local Price = 6
        pcall(function() Price = Items[Name].Price.Wen end)
        local Amount = math.min(BaitBatch, math.floor(Wen() / math.max(Price, 1)))
        if Amount < 1 then return false, "Not enough Wen for " .. Name end
        local Before = Count(Name)
        local Ok, Result = pcall(SignalFunction.ToServer, "PurchaseSelection", { [Name] = Amount })
        if Ok and Result and Farm.WaitFor(function() return Count(Name) > Before end, 3, ShouldRun) then
            return true
        end
        return false, "Could not buy " .. Name
    end

    -- ช่อง Toolbar ของเบ็ด: มีเบ็ดอยู่แล้ว (ตัวเก่าตอนอัป) = ใช้ช่องเดิม / ไม่งั้นช่องว่างแรก
    local function RodSlot(Rod)
        local Id = ItemId(Rod)
        local Ok, Toolbar = pcall(function() return Data().Inventory.Toolbar end)
        if not (Ok and Toolbar and Id) then return nil, "Toolbar not found" end

        local RodIds = { }
        for _, Name in ipairs(Rods) do
            local RodId = ItemId(Name)
            if RodId then RodIds[RodId] = true end
        end

        local Free, Old = nil, nil
        for Index, SlotName in ipairs(SlotNames) do
            local Slot = Toolbar:FindFirstChild(SlotName)
            if Slot then
                if Slot.Value == Id then return Index end
                if Slot.Value == 0 and not Free then Free = Index end
                if RodIds[Slot.Value] then Old = Index end
            end
        end

        local Index = Old or Free
        if not Index then return nil, "No free hotbar slot for the rod" end
        SignalEvent.ToServer("Toolbar_Equip", SlotNames[Index], Id)
        local Slot = Toolbar:FindFirstChild(SlotNames[Index])
        if Farm.WaitFor(function() return Slot.Value == Id end, 3, ShouldRun) then return Index end
        return nil, "Could not put the rod on the hotbar"
    end

    local function EquipRod(Rod)
        local Index, Why = RodSlot(Rod)
        if not Index then return false, Why end
        local ItemsConfig = LocalPlayer:FindFirstChild("Items_Config")
        local Equipped = ItemsConfig and ItemsConfig:FindFirstChild("Equipped")
        if not Equipped then return false, "Items_Config missing" end
        -- ถืออยู่จริง = โมเดลเบ็ดชื่อนี้ใน Character.Tool_Accessories + portal "FishingRod" เปิดอยู่
        -- (portal ใช้ร่วมทุกเบ็ด - ถือ Basic อยู่ตอนเพิ่งได้ Rare ต้องสลับเอง)
        local function Holding()
            local Character = LocalPlayer.Character
            local Accessories = Character and Character:FindFirstChild("Tool_Accessories")
            return Accessories ~= nil and Accessories:FindFirstChild(Rod) ~= nil and Portals.CurrentListeners.FishingRod ~= nil
        end
        if Holding() then return true end

        -- ค่าเดิมเท่ากันไม่ยิง Changed (เกมไม่ถือให้) - ถอดก่อนแล้วค่อยถือช่องเบ็ด
        if Equipped.Value == Index then
            Equipped.Value = 0
            Farm.WaitFor(function() return Portals.CurrentListeners.FishingRod == nil end, 1, ShouldRun)
        end
        Equipped.Value = Index
        if Farm.WaitFor(Holding, 3, ShouldRun) then return true end
        return false, "Rod did not equip"
    end

    local function RemoveBait()
        local Id = EquippedBaitId()
        if Id and Id ~= 0 then
            SignalEvent.ToServer("EquipBait", 0)
            Farm.WaitFor(function() local Now = EquippedBaitId() return not Now or Now == 0 end, 2, ShouldRun)
        end
        return true
    end

    -- UseBait = false -> ถอดเหยื่อ (เบ็ดเปล่า) / true -> ใส่ตัวที่ดีที่สุด
    -- เหยื่อหมด: Auto Buy Bait เปิด = ซื้อ Worm ที่ Jeso / ปิด = ถอดเหยื่อ ตกเบ็ดเปล่าต่อ
    local function EnsureBait(UseBait)
        -- Job.Bait: false = เบ็ดเปล่า / ชื่อ = ใส่ตัวนั้นเท่านั้น (Drowned Lure ไม่หมด - NoDelete)
        local Job = Engine.Job
        if Job and Job.Bait ~= nil then
            if Job.Bait == false then return RemoveBait() end
            local Id = ItemId(Job.Bait)
            if not Id then return false, "No " .. Job.Bait end
            if EquippedBaitId() ~= Id then
                SignalEvent.ToServer("EquipBait", Id)
                Farm.WaitFor(function() return EquippedBaitId() == Id end, 2, ShouldRun)
            end
            return true
        end
        if not UseBait then return RemoveBait() end
        local AutoBuy = Config.FishingAutoBuyBait == true

        -- เลือกเหยื่อไว้ใน dropdown: มี = ใช้ตัวนั้น / หมด + Auto Buy = ซื้อที่ร้านของมัน (Worm = Jeso,
        -- Fish Head = Nori) / ซื้อไม่ได้ (ร้านยังไม่ปลด, Golden Tentacle ซื้อด้วย Robux) = ใช้ตัวที่ดีที่สุดที่มีแทน
        local Wanted = Config.FishingBait
        local Bait, Tried = nil, false
        if type(Wanted) == "string" and Wanted ~= "Best Owned" then
            if Count(Wanted) > 0 then
                Bait = Wanted
            elseif AutoBuy and BaitShop(Wanted) then
                Report("Buying " .. Wanted .. " from " .. BaitShop(Wanted).Npc)
                local Ok, Why = BuyBait(Wanted)
                Tried = true
                if Ok then Bait = Wanted else Report(Why .. " - using your best bait instead") end
            else
                Report("No " .. Wanted .. " - using your best bait instead")
            end
        end

        Bait = Bait or BestBait()
        if not Bait then
            if not AutoBuy or Tried then
                Report("Out of bait - fishing with a bare hook")
                return RemoveBait()
            end
            -- Best Owned หมดเกลี้ยง = ซื้อตัวที่ดีที่สุดที่ซื้อได้ (Fish Head ถ้าร้าน Nori ปลดแล้ว ไม่งั้น Worm)
            -- ซื้อไม่ได้ (Wen ไม่พอ ฯลฯ) = ไม่ค้าง ตกเบ็ดเปล่าไปก่อน รอบหน้าลองซื้อใหม่
            local Buy = StarterBait
            for _, Shop2 in ipairs(BaitShops) do
                if CanBuyBait(Shop2.Name) then Buy = Shop2.Name break end
            end
            Report("Buying " .. Buy .. " from " .. BaitShop(Buy).Npc)
            local Ok, Why = BuyBait(Buy)
            if not Ok then
                Report(Why .. " - fishing with a bare hook")
                return RemoveBait()
            end
            Bait = Buy
        end
        local Id = ItemId(Bait)
        if Id and EquippedBaitId() ~= Id then
            SignalEvent.ToServer("EquipBait", Id)
            Farm.WaitFor(function() return EquippedBaitId() == Id end, 2, ShouldRun)
        end
        return true
    end

    -- แทน Callback ของ portal: จด token ตอนปลากินเอง ไม่เปิดมินิเกม (มินิเกมไม่มีคนเล่น = ตอบ false ก่อน 4.5 วิ)
    local function Hook()
        local Portal = Portals.CurrentListeners.FishingRod
        if not Portal or (Hooked and Hooked.Portal == Portal and Portal.Callback == Hooked.Callback) then return Portal end

        local Original = Portal.Callback
        local function Callback(Kind, Token, ...)
            if Kind == "Bite" then
                Bite.Token, Bite.At = Token, os.clock()
                return
            end
            if Kind == "BiteMissed" or Kind == "BiteCancel" then Bite.Missed = os.clock() end
            if Original then return Original(Kind, Token, ...) end
        end
        Portal.Callback = Callback
        Hooked = { Portal = Portal, Original = Original, Callback = Callback }
        return Portal
    end

    -- ปล่อย portal คืนเกม (มินิเกมกลับมา) เมื่อไม่มีโหมดไหนใช้แล้ว
    local function Release()
        if Engine.Mode then return end
        if Hooked and Hooked.Portal.Callback == Hooked.Callback then
            Hooked.Portal.Callback = Hooked.Original
        end
        Hooked = nil
        Bite.Token = nil
        pcall(function() LocalPlayer:SetAttribute("FishingBite", nil) end)
    end

    -- เบ็ดค้างฝั่งเซิร์ฟ (Uncasting / BiteToken ค้าง): คลิกถูกเมิน หรือคลิกแล้วปลาที่ห้อยสายร่วงลงพื้นไม่ได้เก็บ
    -- วน "Could not cast" -> ถอดเบ็ด รอ portal หาย แล้วรอ forceCleanup ฝั่งเซิร์ฟจบอีก 2 วิ ค่อยให้รอบหน้าถือใหม่
    -- (วัดสด 2026-09-29: ถือกลับทันทีหลัง portal หาย = ยังค้างเหมือนเดิม / ถอดทิ้ง 3 วิแล้วถือ = เหวี่ยงได้ปกติ)
    local function ResetRod(Continue)
        pcall(function() LocalPlayer.Items_Config.Equipped.Value = 0 end)
        Farm.WaitFor(function() return Portals.CurrentListeners.FishingRod == nil end, 3, Continue)
        Farm.Sleep(2, Continue)
        Bite.Token = nil
    end

    -- ยิงสคริปต์ซ้ำ (ValkyrieCleanup) = คืน portal ให้เกมเสมอ ไม่งั้น Callback ตัวเก่าค้างกลืนมินิเกม
    FishingStatus.Cleanup = function()
        Engine.Mode, Engine.Upgrade, Engine.Hold = nil, false, false
        Release()
    end

    local function Click(Target)
        SignalEvent.ToServer("Tool_Mouse", "Down", Target)
        task.wait()
        SignalEvent.ToServer("Tool_Mouse", "Up", Target)
    end

    local function IsCatch(Model)
        return Model.Name:find("^FishingCatch_") ~= nil and Model:GetAttribute("CatchItem") ~= nil
    end

    local function Snapshot()
        local Set = { }
        local Debree = workspace:FindFirstChild("Debree")
        for _, Model in ipairs(Debree and Debree:GetChildren() or { }) do Set[Model] = true end
        return Set
    end

    -- ปลาตัวใหม่ (ไม่อยู่ใน Before) ที่ใกล้ Near (ทุ่นของเรา) ที่สุด - คนอื่นตกอยู่ข้าง ๆ ไม่หยิบของเขา
    -- ปลาเกิดที่ทุ่นแล้วค่อยถูกดึงเข้าหาตัว ทุ่นลอยไกลจากจุดยืนได้ถึง ~CastRadius (40-60) - รัศมีต้องกว้าง
    local function FindCatch(Near, Before)
        local Best, BestDistance = nil, 70
        local Debree = workspace:FindFirstChild("Debree")
        for _, Model in ipairs(Debree and Debree:GetChildren() or { }) do
            if not Before[Model] and IsCatch(Model) then
                local Ok, Pivot = pcall(Model.GetPivot, Model)
                -- วัดแนวราบ: ปลาโผล่ที่ผิวน้ำ ยืนบนหน้าผาสูงกว่าน้ำเป็นร้อย studs ได้
                local Offset = Ok and (Pivot.Position - Near) * Vector3.new(1, 0, 1)
                local Distance = Offset and Offset.Magnitude or math.huge
                if Distance < BestDistance then Best, BestDistance = Model, Distance end
            end
        end
        return Best
    end

    -- ปลาห้อยปลายเบ็ดห่างตัว 7.4-8.7 studs แกว่งเข้า-ออกขอบระยะ prompt (MaxActivationDistance 8) = engine
    -- ซ่อน-โชว์รัว hold หลุด-กดใหม่ 2-6 รอบต่อตัว (วัดสด 2026-09-29) -> ขยายระยะฝั่ง client +4 ระหว่างกด
    -- ยืนยันสด: ขยายเป็น 12 = กดค้างรอบเดียวติด 4/4 ตัว เซิร์ฟรับ (ปลาหาย เข้ากระเป๋า) เก็บ ~2.6 วิ/ตัว
    local CatchReach = 4

    local function Holding(Prompt)
        local Root = Movement.GetRoot()
        local Part = Prompt.Parent
        return Root ~= nil and Part ~= nil and Part:IsA("BasePart")
            and (Part.Position - Root.Position).Magnitude <= Prompt.MaxActivationDistance + CatchReach - 1.5
    end

    -- กด prompt Collect ค้างครบ HoldDuration แบบคนกด (PromptHeld ฝั่งเซิร์ฟเช็คเวลาค้าง)
    -- ปุ่มเดียวกัน (T) ที่อยู่ใกล้กว่า เช่นป้ายร้านเบ็ดของ Jeso แย่งโชว์ (OnePerButton) - Prompts.Use ตั้ง
    -- AlwaysShow ให้เองแล้ว ไม่ต้องปิดตัวอื่น
    local function HoldCollect(Prompt, Name, Before)
        -- Wait สั้น: ปลาโผล่ = กดค้างทันที (hold 2 วิเป็นกติกาเซิร์ฟ PromptHeld ลดไม่ได้ อย่าเสียเวลารอ PromptShown)
        -- NoMove: ปลาห้อยจากปลายเบ็ดที่ติดตัว ขยับตัวปลาก็ตามมา / Check = ปลาเข้ากระเป๋าจริง
        Prompts.Use(Prompt, {
            Hold = true, Wait = 0.05, Continue = ShouldRun, NoMove = true, Tries = 3, Reach = CatchReach,
            Check = function() return Count(Name) > Before or not Prompt.Parent end,
        })
        return Farm.WaitFor(function() return Count(Name) > Before end, 1.5, ShouldRun)
    end

    -- เก็บปลา: ปกติปลาถูกดึงมาห้อยปลายเบ็ดข้างตัว (finishCatchPull) กดเก็บได้เลยไม่ต้องปล่อยลงน้ำ
    -- เก็บไม่ติด 2 รอบ = สำรอง: คลิกปล่อยลงพื้น (dropCatch) แล้วตามไปกด / คืน true ถ้าเข้ากระเป๋า
    local function Collect(Model, Name, Target)
        local Prompt = Model:FindFirstChildWhichIsA("ProximityPrompt", true)
        if not (Prompt and Prompt.Parent and Prompt.Parent:IsA("BasePart")) then return false end
        local Before = Count(Name)

        -- ผู้เล่นคลิกม้วนเบ็ดตอนปลาห้อยสาย = เซิร์ฟปล่อยปลาลงพื้น (dropCatch ลบ FishingLine) - ไม่ต้องรอปลา
        -- ห้อยเข้าระยะอีก (เดิมรอ 6 วิ x 2 รอบ สถานะค้าง Collecting) ข้ามไปวาร์ปเก็บบนพื้นเลย
        local function Dropped() return Model.Parent ~= nil and not Model:FindFirstChild("FishingLine", true) end

        for Try = 1, 2 do
            -- ดึงขึ้นใช้เวลา ~0.5-4 วิ กดทันทีที่เข้าระยะ ปลายังแกว่งหลุดระยะกลางกด = Prompts.Use เริ่มกดใหม่ทันที
            -- (วัดสด: กดเลย เฉลี่ย 3.4 วิ/ตัว / รอให้ห้อยนิ่งก่อน (เชือก 0.3 ของ finishCatchPull) 4.2 วิ/ตัว)
            Farm.WaitFor(function() return not Model.Parent or Holding(Prompt) or Dropped() end, 6, ShouldRun)
            if not (ShouldRun() and Model.Parent) or Dropped() then break end
            if HoldCollect(Prompt, Name, Before) then return true end
        end
        if not (ShouldRun() and Model.Parent) then return Count(Name) > Before end

        Report("Dropping " .. tostring(Name) .. " to pick it up")
        -- คลิก 1 ที แล้วรอเซิร์ฟลบสายจริง (เดิมคลิกทุก 0.4 วิ สายลบช้ากว่านั้น = คลิกเกินกลายเป็นเหวี่ยงเบ็ด)
        for _ = 1, 3 do
            if not (ShouldRun() and Model.Parent) or Dropped() then break end
            Click(Target)
            Farm.WaitFor(function() return not Model.Parent or Dropped() end, 1.5, ShouldRun)
        end
        Farm.Sleep(1.2, ShouldRun)      -- ให้ปลาตกถึงพื้นก่อน

        local Part = Prompt.Parent
        for _ = 1, 2 do
            if not (ShouldRun() and Model.Parent and Part.Parent) then break end
            Movement.Lock(CFrame.new(Part.Position + Vector3.new(0, 2, 0)))
            Farm.Sleep(0.3, ShouldRun)
            local Ok = HoldCollect(Prompt, Name, Before)
            Movement.Lock(nil)
            if Ok then return true end
        end
        Movement.Lock(nil)
        return Count(Name) > Before
    end

    -- หลังปลากิน: รอครบ 4.5 วิ -> ตอบ -> รอปลาโผล่ -> เก็บ / คืนชื่อปลา หรือ nil + เหตุผล
    -- ปลากินตัวนี้ตายแล้ว: เซิร์ฟยกเลิก (BiteCancel - ผู้เล่นม้วนเบ็ด/ถอดเบ็ด/กระโดด) หรือมีปลากินตัวใหม่
    -- มาแทน (ผู้เล่นเหวี่ยงใหม่ไวกว่าเรา) - เลิกรอทันที ไม่ค้างสถานะ
    local function BiteDead(At)
        return Bite.Missed >= At or (Bite.Token ~= nil and Bite.At > At)
    end

    local function Land(Portal, Token, At, Near, Target)
        -- Job.Lose = ตั้งใจไม่ดึงปลา (จุดยกเบ็ด Isao: "the rod won't rise for someone trying to catch a fish")
        -- ตอบ false ทันที = เซิร์ฟนับ Lost -> DrownedLine.ReportBite / มีของโผล่ (เบ็ดของ Isao) = เก็บ
        if Engine.Job and Engine.Job.Lose then
            local Before = Snapshot()
            local SentAt = os.clock()
            pcall(function() Portal:Server(Token, false) end)
            local Model = nil
            Farm.WaitFor(function()
                Model = FindCatch(Near, Before)
                return Model ~= nil
            end, 2.5, ShouldRun)
            if Model then
                local Name = Model:GetAttribute("CatchItem")
                if Collect(Model, Name, Target) then
                    Engine.LastCatch = Name
                    return Name
                end
            end
            Farm.WaitFor(function() return Bite.Missed >= SentAt end, 1, ShouldRun)
            return nil, "Let the fish go"
        end
        Farm.WaitFor(function() return os.clock() - At >= BiteHold or BiteDead(At) end, BiteHold + 1, ShouldRun)
        if not ShouldRun() then return nil end
        if BiteDead(At) then return nil, "Line reeled in" end
        local Before = Snapshot()
        local SentAt = os.clock()
        pcall(function() Portal:Server(Token, true) end)

        -- ได้ของ = โมเดลโผล่ตอนม้วนสาย (ไม่ได้ = Empty/Slipped ไม่มีโมเดล - เซิร์ฟยิง BiteMissed = เลิกรอเลย)
        local Model = nil
        Farm.WaitFor(function()
            Model = FindCatch(Near, Before)
            return Model ~= nil or Bite.Missed >= SentAt
        end, 4, ShouldRun)
        if not Model then
            return nil, "Nothing on the hook"
        end
        local Name = Model:GetAttribute("CatchItem")

        Report("Collecting " .. tostring(Name))
        if Collect(Model, Name, Target) then
            Engine.LastCatch = Name
            Engine.Caught = Engine.Caught + 1
            return Name
        end
        return nil, "Could not collect " .. tostring(Name)
    end

    -- ทุ่น/สายเบ็ดของเราโผล่ (เซิร์ฟสร้าง workspace.Debree.FishingLine_N ~0.3 วิหลังเหวี่ยง) - คืนโมเดลทุ่น
    -- วัดระยะแนวราบ: ยืนบนหน้าผา ทุ่นลงไปอยู่ที่น้ำต่ำกว่าเป็นร้อย studs - วัด 3 มิติ = หาไม่เจอ แล้วคลิกซ้ำ
    -- (คลิกตอนสายออกแล้ว = ม้วนเก็บ) กลายเป็นเหวี่ยงแล้วดึงขึ้นทันทีทุกรอบ
    local function LineOut(Near, Before)
        local Debree = workspace:FindFirstChild("Debree")
        for _, Model in ipairs(Debree and Debree:GetChildren() or { }) do
            if not Before[Model] and Model.Name:find("^FishingLine_") then
                local Ok, Pivot = pcall(Model.GetPivot, Model)
                if Ok and ((Pivot.Position - Near) * Vector3.new(1, 0, 1)).Magnitude < 60 then return Model end
            end
        end
        return nil
    end

    -- เหวี่ยง 1 รอบที่จุด Spot() -> คืนชื่อปลาที่ได้ / nil + เหตุผล
    local function FishOnce(Rod, UseBait)
        local Stand, Target = Spot()
        if not Stand then return nil, "Fisherman Jeso not found" end

        local Ok, Why = EquipRod(Rod)
        if not Ok then return nil, Why end
        Ok, Why = EnsureBait(UseBait)
        if not Ok then return nil, Why end
        if not GoNear(Stand) then return nil, "Could not reach the fishing spot" end
        local Portal = Hook()
        if not Portal then return nil, "Rod portal missing" end

        -- ปลากินค้างจากรอบก่อน (สายออกไปแล้วแต่เราหาสายไม่เจอ) = ห้ามทิ้ง token - เซิร์ฟรอคำตอบตลอดไป
        -- (RodServer ไม่มี timeout) และระหว่างนั้นคลิกเหวี่ยง/ม้วนถูกเมินหมด = ค้างวนคลิก "Could not cast"
        -- (เจอผ่าน spy: คลิก Tool_Mouse ทุก 3-5 วิ ไม่มีสายใหม่ มี FishingReelPin ติดตัว) -> ดึงตัวนั้นขึ้นเลย
        local function Pending()
            if Bite.Token == nil or BiteDead(Bite.At) then return nil end
            local Token, At = Bite.Token, Bite.At
            Bite.Token = nil
            return Token, At
        end

        local Token, At = Pending()
        if Token then
            Report("Fish on the line - reeling")
            return Land(Portal, Token, At, Stand.Position, Target)
        end

        -- เหวี่ยง: สายค้างจากรอบก่อน (คลิกแรก = ม้วนเก็บ) = ไม่มีสายใหม่โผล่ -> คลิกซ้ำอีกที
        Bite.Token = nil
        Report("Casting")
        local Bobber = nil
        for _ = 1, 2 do
            local Before = Snapshot()
            Click(Target)
            if Farm.WaitFor(function()
                Bobber = LineOut(Stand.Position, Before)
                return Bobber ~= nil or Bite.Token ~= nil
            end, 1.5, ShouldRun) then
                break
            end
            Farm.Sleep(1.5, ShouldRun)  -- รอม้วนเก็บจบ (uncast ~1.4 วิ)
            if Bite.Token ~= nil then break end
        end
        if not ShouldRun() then return nil end
        -- หาสายไม่เจอแต่ปลากินแล้ว (สายออกจริงแค่เราไม่เห็น) = ดึงเลย
        Token, At = Pending()
        if Token then
            Report("Fish on the line - reeling")
            return Land(Portal, Token, At, Stand.Position, Target)
        end
        if not Bobber then return nil, "Could not cast" end

        -- รอปลากินตามเวลาที่คำนวณจากเบ็ด+เหยื่อ+Title (เผื่อ 30% + 2 วิ ไม่เกิน BiteTimeout)
        -- สายหาย (ผู้เล่นกดม้วนเบ็ดเอง / เซิร์ฟ uncast) = เลิกรอเหวี่ยงใหม่เลย
        local Window = BiteWindow(Rod)
        Report("Waiting for a bite (" .. BiteText(Window) .. ")")
        Farm.WaitFor(function() return Bite.Token ~= nil or not Bobber.Parent end,
            math.min(Window.Max * 1.3 + 2, BiteTimeout), ShouldRun)
        if Bite.Token == nil and ShouldRun() and not Bobber.Parent then
            return nil, "Line reeled in - casting again"
        end
        if Bite.Token == nil then
            if ShouldRun() then Click(Target) end    -- ไม่กินนาน = ม้วนเก็บแล้วเหวี่ยงใหม่
            Farm.Sleep(1.5, ShouldRun)
            return nil, "No bite - face open water"
        end

        Report("Fish on the line - reeling")
        local Token, At = Bite.Token, Bite.At
        Bite.Token = nil
        local Ok, Pivot = pcall(Bobber.GetPivot, Bobber)
        return Land(Portal, Token, At, (Ok and Bobber.Parent) and Pivot.Position or Stand.Position, Target)
    end

    local function HasToll()
        for Name, Need in pairs(TollFish) do
            if Count(Name) < Need then return false end
        end
        return true
    end

    -- ของที่ต้องใช้อัปเบ็ด กันไม่ให้ Auto Sell ขาย (Golden Fish เฉพาะตอนยังไม่มี Rare)
    local function KeepUpgradeItems(Rod)
        Seller.Keep.Fishing = {
            ["Golden Fish"] = (Rod == nil or Rod == "Basic Fishing Rod") and (RarePrice["Golden Fish"] or 5) or nil,
            Crustadon = TollFish.Crustadon,
            Krathulon = TollFish.Krathulon,
        }
    end

    -- ระหว่างรอบ: ถึงรอบขาย (Auto Sell) = ไปขายก่อน
    local function MaybeSell()
        if Seller.Due() then
            Report("Selling (Auto Sell)")
            pcall(Seller.Run, ShouldRun)
        end
    end

    -- Upgrade ไม่ตกปลาเอง: รอของครบ (จาก Auto Fishing / ตกเอง / ฟาร์ม Wen) แล้วค่อยไปซื้อ-แลกเบ็ด
    -- เขียนการ์ดรวม Unlock & Upgrade - Unlock รันอยู่ = Unlock เป็นเจ้าของการ์ด ว่างเมื่อไหร่ค่อยยึดคืน
    local function UpgradeReport(Status, State, Progress)
        if not (Session() and Engine.Upgrade) then return end
        local Gear = GearText()
        task.wait()     -- GetData = thread เสีย capability ชั่วคราว - คั่นก่อนแตะ UI
        if FishingStatus.Owner == nil then FishingStatus.Owner = "Upgrade" end
        FishingStatus.Write("Upgrade", State, { Mode = "Upgrade Rod", Step = Status, Progress = Progress, Gear = Gear })
    end

    -- ทำ 1 อย่างที่ต้องขยับตัว (ซื้อเบ็ด/จ่าย Isao): รอ Auto Fishing จบรอบก่อน (Hold = ห้ามเริ่มรอบใหม่)
    -- ไม่มี Auto Fishing รัน = ทำเสร็จแล้วพากลับจุดเดิม
    local function Act(Status, Progress, Action)
        if Fighter.Continue ~= nil then
            UpgradeReport("Ready - waiting for the farm to stop (" .. Status .. ")", "Idle", Progress)
            return false
        end
        Engine.Hold = true
        UpgradeReport("Waiting for the current cast", nil, Progress)
        Farm.WaitFor(function() return not Engine.Busy end, 60, ShouldRun)

        local Root = Movement.GetRoot()
        local Home = Engine.Mode == nil and Root and Root.CFrame or nil
        UpgradeReport(Status, nil, Progress)
        local Ok, Result, Message = pcall(Action)
        if Home and Session() then
            local Now = Movement.GetRoot()
            if Now and (Now.Position - Home.Position).Magnitude > 5 then GoTo(Home) end
        end
        Engine.Hold = false
        if not Ok then return false, tostring(Result) end
        if Result == false then return false, Message end
        return true
    end

    -- Upgrade: เช็ค 1 รอบ - คืน true = จบ พร้อมข้อความ/สถานะ
    local function UpgradeStep()
        if os.clock() < UpgradeGapAt then return false end
        UpgradeGapAt = os.clock() + 1      -- ไม่ต้องเช็คทุกเฟรม (อ่าน GetData)

        if not HasPermit() then
            UpgradeReport("Waiting for the Fishing Permit (Auto Unlock Fishing)", "Idle", Goal(nil))
            return false
        end

        local Rod = BestRod()
        KeepUpgradeItems(Rod)
        if Rod == "Legendary Fishing Rod" then
            return true, "Done - you have the Legendary Fishing Rod", "Done"
        end
        local Progress = Goal(Rod)

        if not Rod then
            if Wen() < BasicPrice then
                UpgradeReport(string.format("Waiting for %d Wen (Basic Fishing Rod)", BasicPrice), "Idle", Progress)
                return false
            end
            local Ok, Why = Act("Buying the Basic Fishing Rod", Progress, function() return BuyRod("Basic Fishing Rod") end)
            if not Ok and Why then UpgradeReport(Why, "Error", Progress) UpgradeGapAt = os.clock() + 3 end
            return false
        end

        if Rod == "Basic Fishing Rod" then
            if Count("Golden Fish") >= (RarePrice["Golden Fish"] or 5) and Wen() >= (RarePrice.Wen or 10000) then
                local Ok, Why = Act("Trading Golden Fish for the Rare Fishing Rod", Progress, function() return BuyRod("Rare Fishing Rod") end)
                if not Ok and Why then UpgradeReport(Why, "Error", Progress) UpgradeGapAt = os.clock() + 3 end
                return false
            end
            UpgradeReport("Waiting for Golden Fish + Wen", "Idle", Progress)
            return false
        end

        -- Rare -> Legendary (ลำดับความสำคัญ):
        --   ไม่มีโหมดไหนคุมเบ็ด = ตัว Legendary รันเองทุกขั้น
        --   Auto Fishing รันอยู่ = ขั้นพิเศษ (Sofen / ตก Lure / จ่าย Isao / ยกเบ็ด) แซงไปทำก่อน แล้วคืนให้ตกต่อ
        --     ขั้นที่แค่ตกปลาหา Crustadon-Krathulon / รอกลางคืน = ปล่อย Auto Fishing ตกไปตามปกติ
        --   ฟาร์ม / โหมดอื่น (Unlock, Shiori) = รอ
        if Engine.LegendActive and Engine.LegendActive() then return false end
        if Fighter.Continue ~= nil then
            UpgradeReport("Ready - waiting for the farm to stop (Legendary steps)", "Idle", Progress)
            return false
        end
        if not Engine.SetLegend then return false end
        if Engine.Mode == nil then
            Engine.SetLegend(true)
        elseif Engine.Mode == "Fish" then
            local Need = Engine.LegendNeed()
            if Engine.LegendSpecial[Need] then
                if Engine.LegendReady() then Engine.SetLegend(true, true) end
            else
                UpgradeReport(Need == "Night" and "Waiting for night to pay Isao (Auto Fishing keeps going)"
                    or "Auto Fishing is catching Crustadon / Krathulon", "Idle", Progress)
            end
        else
            UpgradeReport("Waiting - turn off " .. tostring(Engine.Mode) .. " for the Legendary steps", "Idle", Progress)
        end
        return false
    end

    -- Auto Fishing: ตกไปเรื่อย ๆ ด้วยเบ็ดที่ดีที่สุดที่มี (อัปเบ็ดแล้วรอบถัดไปถือเบ็ดใหม่เอง)
    local function FishStep()
        if not HasPermit() then
            return true, "No Fishing Permit - run Auto Unlock Fishing first", "Error"
        end
        local Rod = BestRod()
        if not Rod then
            return true, "No fishing rod - buy one at Fisherman Jeso or use Auto Upgrade Rod", "Error"
        end
        if os.clock() < StepGapAt then return false end
        if Engine.Hold then
            Report("Paused - Auto Upgrade Rod goes first")
            Farm.WaitFor(function() return not Engine.Hold end, 60, ShouldRun)
            return false
        end

        MaybeSell()
        if not ShouldRun() then return false end

        Engine.Busy = true
        local Ok, Name, Why = pcall(FishOnce, Rod, Config.FishingUseBait == true)
        Engine.Busy = false
        if not Ok then error(Name, 0) end

        -- เหวี่ยงไม่ออก 2 รอบติด = เซิร์ฟค้างรอคำตอบปลากินที่ token หายไปแล้ว (คลิกถูกเมิน) - ถอดเบ็ด
        -- (เซิร์ฟ UnEquipped -> forceCleanup ล้าง BiteToken) รอบหน้า EquipRod ถือใหม่ เหวี่ยงได้ปกติ
        Engine.CastFails = Why == "Could not cast" and (Engine.CastFails or 0) + 1 or 0
        if Engine.CastFails >= 2 then
            Engine.CastFails = 0
            Report("Rod stuck - re-equipping")
            ResetRod(ShouldRun)
            return false
        end
        -- ผู้เล่นม้วนเบ็ดเอง / ปลาหลุด = ไม่ใช่ error ไม่เว้นช่วง - รอบหน้าเหวี่ยงใหม่ทันที
        local Normal = Why == "Nothing on the hook" or (type(Why) == "string" and Why:find("^Line reeled in") ~= nil)
        if Name then
            Report("Caught " .. Name)
        elseif Why and Normal then
            Report(Why)
        elseif Why then
            Report(Why, "Error")
            StepGapAt = os.clock() + 2
        end
        return false
    end

    local function RunFish()
        while Session() and Engine.Mode == "Fish" do
            task.wait()
            -- Priority: โหมดฟาร์มที่สูงกว่ามีงาน = พักตกปลา (ไม่แตะ Movement - ตัวฟาร์มคุมอยู่) รอจนกลับมาเป็นตาเรา
            if Farm.FishTurn and not Farm.FishTurn() then
                Report("Paused - a higher Priority farm is running")
                while Session() and Engine.Mode == "Fish" and not Farm.FishTurn() do task.wait(0.5) end
                continue
            end
            -- ไม่มี Permit / ไม่มีเบ็ด ฯลฯ = ไม่ปิด toggle เอง โชว์เหตุผลแล้วรอลองใหม่ทุก 5 วิ
            local Ok, Finished, Message, State = pcall(FishStep)
            if not Ok then
                Report("Error: " .. tostring(Finished):sub(1, 80), "Error")
                Farm.Sleep(2, ShouldRun)
            elseif Finished then
                Report(tostring(Message) .. " - retrying", State)
                Farm.Sleep(5, ShouldRun)
            end
        end

        Movement.Lock(nil)
        Engine.Thread = nil
        if Engine.Mode == "Fish" then
            local Set = Library.SetFlags and Library.SetFlags["SL2AutoFishing"]
            if Set then pcall(Set, false) end
        end
    end

    local function SetFish(Value)
        if Value then
            -- โหมดฟาร์มไม่ปิดแล้ว: หน้า Priority ตัดสินว่าตกปลาหรือฟาร์มก่อน (Farm.FishTurn)
            TurnOffFlags(ExclusiveFlags.Breathing)
            TurnOffFlags(ExclusiveFlags.Puzzle)
            TurnOffFlags(ExclusiveFlags.Fishing, "SL2AutoFishing")
            TurnOffFlags(ExclusiveFlags.Quest)
            local Root = Movement.GetRoot()
            -- จุดยืนตอนเปิด (หันแนวราบ) - ใช้กับ Fishing Spot = Where I Stand
            Engine.Stand = Root and CFrame.new(Root.Position, Root.Position + Root.CFrame.LookVector * Vector3.new(1, 0, 1)) or nil
            Engine.Mode = "Fish"
            Seller.Paused = true
            StepGapAt = 0
            task.spawn(function()
                -- รอบเก่ายังค้างอยู่ใน FishOnce = รอมันออกก่อน
                while Engine.Thread and Engine.Mode == "Fish" do task.wait() end
                if Engine.Mode ~= "Fish" then return end
                Engine.Thread = true
                RunFish()
            end)
        elseif Engine.Mode == "Fish" then
            Engine.Mode = nil
            Movement.Lock(nil)
            Seller.Paused = false
            Release()
            -- การ์ดยังค้าง Running ของรอบที่แล้ว - บอกว่าหยุดแล้ว
            if AutoCard then
                pcall(function()
                    AutoCard:SetState("Idle")
                    AutoCard:Set("Step", "Stopped")
                end)
            end
        end
    end

    local function RunUpgrade()
        while Session() and Engine.Upgrade do
            task.wait()
            local Ok, Finished, Message, State = pcall(UpgradeStep)
            if not Ok then
                Engine.Hold = false
                UpgradeReport("Error: " .. tostring(Finished):sub(1, 80), "Error")
                Farm.Sleep(2, ShouldRun)
            elseif Finished then
                UpgradeReport(Message, State, Goal(BestRod()))
                -- ปิดเองเฉพาะได้เบ็ดสูงสุดแล้ว / error = ค้างไว้ ลองใหม่ทุก 5 วิ
                if State == "Done" then
                    Library:Notify("Fishing", Message, 5)
                    break
                end
                Farm.Sleep(5, ShouldRun)
            end
        end

        Engine.Hold = false
        Engine.UpgradeThread = nil
        if Engine.Upgrade then
            Engine.Upgrade = false
            local Set = Library.SetFlags and Library.SetFlags["SL2AutoUpgradeFishing"]
            if Set then pcall(Set, false) end
        end
        Seller.Keep.Fishing = nil
        if FishingStatus.Owner == "Upgrade" then FishingStatus.Owner = nil end
    end

    local function SetUpgrade(Value)
        if Value then
            Engine.Upgrade = true
            UpgradeGapAt = 0
            if not Engine.UpgradeThread then Engine.UpgradeThread = task.spawn(RunUpgrade) end
        elseif Engine.Upgrade then
            Engine.Upgrade = false
            Engine.Hold = false
            if Engine.SetLegend then Engine.SetLegend(false) end
            Seller.Keep.Fishing = nil
            if FishingStatus.Owner == "Upgrade" then FishingStatus.Owner = nil end
            FishingStatus.Write("Upgrade", "Idle", { Mode = "Idle", Step = "Stopped" })
        end
    end

    --// Auto Quest Shiori (Butterfly Estate) - ทำเควสปลดล็อกร้านเหยื่อ Baitmonger Nori (Fish Head) ครั้งเดียว
    -- ยืนยันสดผ่าน dex 2026-09-29 (Quests.Shiori / Yap.Shiori / QuestStates / DepositState / InfirmaryActions):
    --   "Ill restock the infirmary(Lv 70)" (LogCompletion = Done ถาวร): ยาอย่างละ 10 - Health Elixir /
    --   Health Regen Elixir / Stamina Regen Elixir ซื้อที่ Alchemist Meku (Mistfall Harbor) ตะกร้า
    --   PurchaseSelection ต้องยืนติด NPC - ราคาต่อขวด Demon Horns 2 + Wen 350/500/750
    --   ส่งของ (Deposit) = ยืนที่ลังพยาบาล (-1848, 315, -119) ยิง QuestProgress(เควส, task) ทีละชิ้นทุก 0.15 วิ
    --   ส่งเควส = คุยกับ Shiori: QuestProgress(เควส, "Return to Shiori") (DeliverAction)
    --   รางวัล 7200 Exp + 810 Wen + ร้าน Nori ขาย Fish Head (Shop.CanBuy ติด "Restock the Infirmary completed")
    --   เลเวลไม่ถึง = ยืมตัวฟาร์ม Level (Farm.LevelFarm) ท่า Above เท่านั้น อาวุธเอาจากแท็บฟาร์มอื่น
    --   ปลดแล้ว = ปิด toggle เอง และเปิดใหม่ไม่ได้
    local QuestsModule = Require(function() return ReplicatedStorage.CAM.Global.Subsets.Gameplay.Quests end)
    local ShioriName = "Shiori"
    local RestockId = "Ill restock the infirmary(Lv 70)"
    local CratePos = Vector3.new(-1848.23, 315.086, -119.539)
    local Shiori = { Active = false, GapAt = 0, Leveling = false }

    local function ShioriDone()
        return Farm.GetQuestState(RestockId) == "Done"
    end

    local function NeedLevel()
        local Def = QuestsModule and QuestsModule.Holder[RestockId]
        return Def and Def.Requirements and tonumber(Def.Requirements.Level) or 70
    end

    -- task ส่งของของเควส { Task, Item, Value, Max } (Value/Max จากข้อมูลผู้เล่น - ยังไม่รับ = 0/nil)
    local function DepositTasks()
        local Def = QuestsModule and QuestsModule.Holder[RestockId]
        local Folder = nil
        pcall(function() Folder = Data().Quests.Holder:FindFirstChild(Def.QuestInstance.Name) end)
        local List = { }
        for TaskName, Spec in pairs(Def and Def.TaskSpecs or { }) do
            if Spec.Type == "Deposit" and Spec.RequiredItem then
                local Value, Max = 0, nil
                pcall(function()
                    local Task = Folder.Tasks:FindFirstChild(TaskName)
                    Value, Max = Task.Value.Value, Task.Max.Value
                end)
                table.insert(List, { Task = TaskName, Item = Spec.RequiredItem, Value = Value, Max = Max })
            end
        end
        table.sort(List, function(A, B) return A.Item < B.Item end)
        return List
    end

    -- ของที่ยังขาด { [ชื่อ] = ต้องส่งอีกกี่ชิ้น } / รวม Value, Max ทั้งเควส
    local function Missing(Tasks)
        local Need, Done, Total = { }, 0, 0
        for _, Task in ipairs(Tasks) do
            local Max = Task.Max or 0
            Done, Total = Done + math.min(Task.Value, Max), Total + Max
            if Task.Value < Max then Need[Task.Item] = Max - Task.Value end
        end
        return Need, Done, Total
    end

    local function ShioriRun()
        return Session() and Shiori.Active
    end

    -- เขียนการ์ดรวม Fishing Status (section Unlock & Upgrade) - Shiori เป็นเจ้าของการ์ดตอนรัน
    local function ShioriReport(Status, State, Progress)
        if not ShioriRun() then return end
        Shiori.Status = Status
        Shiori.Progress = Progress or Shiori.Progress or "-"
        local Gear = GearText()
        task.wait()     -- GetData = thread เสีย capability ชั่วคราว - คั่นก่อนแตะ UI
        FishingStatus.Write("Shiori", State, { Mode = "Shiori Quest", Step = Status, Progress = Shiori.Progress, Gear = Gear })
    end

    -- ไปยืนหน้า NPC แล้วคืนการชน (Teleport ทิ้ง noclip = ร่วงทะลุพื้น) รอเซิร์ฟเห็นตำแหน่งก่อนยิง event
    local function GoToNpc(Name)
        Movement.Lock(nil)
        local Ok = Farm.GoToNpc(Name, ShouldRun)
        Movement.Cancel()
        Farm.Sleep(0.4, ShouldRun)
        return Ok
    end

    -- ค่าของที่ต้องจ่าย: Wen = เงิน / อื่น ๆ (Demon Horns) = นับในกระเป๋า
    local function Balance(Name)
        return Name == "Wen" and Wen() or Count(Name)
    end

    local function CartShort(Cart)
        local Ok, Totals = pcall(Shop.GetCartTotals, Cart)
        if not (Ok and type(Totals) == "table") then return nil end
        for Currency, Amount in pairs(Totals) do
            if Balance(Currency) < Amount then
                return string.format("%s %d/%d", Currency, Balance(Currency), Amount)
            end
        end
        return nil
    end

    -- ซื้อตะกร้า (PurchaseSelection) ที่ร้าน NPC - ต้องยืนติด NPC (ไกลเซิร์ฟคืน false เงียบ)
    local function BuyCart(Npc, Cart)
        if not GoToNpc(Npc) then return false, Npc .. " not found" end
        local Before = { }
        for Name in pairs(Cart) do Before[Name] = Count(Name) end
        local Ok, Result = pcall(SignalFunction.ToServer, "PurchaseSelection", Cart)
        local Got = Farm.WaitFor(function()
            for Name, Amount in pairs(Cart) do
                if Count(Name) < Before[Name] + Amount then return false end
            end
            return true
        end, 4, ShouldRun)
        if Got then return true end
        return false, "Could not buy at " .. Npc .. (Ok and "" or ": " .. tostring(Result))
    end

    -- รับเควสที่ Shiori - ช่องเควสมีเควสอื่นขวาง = ไม่ทิ้งเควสผู้เล่นเอง บอกให้รู้แล้วรอ
    local function AcceptShiori()
        local Ok, CanAdd, OnCooldown, Blocking = pcall(QuestsModule.CanAddQuest, RestockId)
        if Ok and not CanAdd then
            if OnCooldown then return false, "Quest on cooldown - waiting" end
            if type(Blocking) == "string" then
                return false, "Quest slot busy with '" .. Blocking .. "' - finish or abandon it"
            end
            return false, "Shiori cannot give this quest yet"
        end
        if not GoToNpc(ShioriName) then return false, "Shiori not found" end
        SignalEvent.ToServer("AddQuest", RestockId)
        if Farm.WaitFor(function() return Farm.GetQuestState(RestockId) == "Doing" end, 3, ShouldRun) then return true end
        return false, "Shiori did not give the quest"
    end

    local function TurnIn()
        if not GoToNpc(ShioriName) then return false, "Shiori not found" end
        Farm.QuestProgress(RestockId, "Return to Shiori")
        if Farm.WaitFor(function() return Farm.GetQuestState(RestockId) ~= "Doing" end, 3, ShouldRun) then return true end
        return false, "Shiori did not take the delivery"
    end

    -- ส่งของเข้าลังทีละชิ้น (แบบ DepositState ของเกม) จนครบ/ของหมด
    local function DepositAll()
        GoTo(CFrame.new(CratePos + Vector3.new(0, 3, 4), CratePos))
        for _, Task in ipairs(DepositTasks()) do
            local Value, Max = Task.Value, Task.Max or 0
            local function Current()
                for _, Now in ipairs(DepositTasks()) do
                    if Now.Task == Task.Task then return Now.Value end
                end
                return Value
            end
            while ShioriRun() and Value < Max and Count(Task.Item) > 0 do
                Farm.QuestProgress(RestockId, Task.Task)
                local Before = Value
                Farm.WaitFor(function()
                    Value = Current()
                    return Value > Before
                end, 1.5, ShouldRun)
                if Value <= Before then return false, "Crate did not take " .. Task.Item end
                task.wait(0.15)
            end
        end
        return true
    end

    -- อาวุธฟาร์มเลเวล: ตัวที่ตั้งไว้ในแท็บฟาร์มอื่น (Level > Mob > Boss > ค่ากลาง)
    local function BorrowedWeapon()
        for _, Key in ipairs({ "FarmWeaponLevel", "FarmWeaponMob", "FarmWeaponBoss", "FarmWeapon", "FarmWeaponBreathing" }) do
            local Name = Config[Key]
            if type(Name) == "string" and Name ~= "" and Name ~= "None" then return Name end
        end
        return ""
    end

    -- เลเวลไม่ถึง = ยืมตัวฟาร์ม Level (ท่า Above เท่านั้น) จนถึงเลเวล - วนเช็คทุก 2 วิ
    local function LevelUp(Need)
        if not Farm.LevelFarm then return true, string.format("Need Lv %d", Need), "Error" end
        if not Shiori.Leveling then
            Config.FarmMethodShiori = "Above"
            Config.FarmWeaponShiori = BorrowedWeapon()
            Config.FarmDistanceShiori = Config.FarmDistanceLevel or Config.FarmDistance or 4
            Config.AutoDodgeShiori = Config.AutoDodgeLevel ~= false
            Config.AutoCollectDropsShiori = false
            Shiori.Leveling = true
            Farm.LevelFarm.Start("Shiori")
        end
        ShioriReport(string.format("Leveling to Lv %d (Level farm, Above)", Need), nil,
            string.format("Lv %d/%d", Farm.GetLevel(), Need))
        Farm.WaitFor(function() return Farm.GetLevel() >= Need end, 2, ShioriRun)
        return false
    end

    local function StopLeveling()
        if not Shiori.Leveling then return end
        Shiori.Leveling = false
        if Farm.LevelFarm then Farm.LevelFarm.Stop() end
        Movement.Cancel()
    end

    -- ทำ 1 ขั้น - คืน true = จบ (ปลดแล้ว) / ติดเงื่อนไข (รอ 5 วิแล้วลองใหม่ ไม่ปิด toggle)
    local function ShioriStep()
        if not QuestsModule then return true, "Quest data not found", "Error" end
        local State = Farm.GetQuestState(RestockId)
        if State == "Done" then
            return true, "Unlocked - Baitmonger Nori sells Fish Head", "Done"
        end
        if os.clock() < Shiori.GapAt then return false end
        Seller.Keep.Shiori = { ["Health Elixir"] = 10, ["Health Regen Elixir"] = 10, ["Stamina Regen Elixir"] = 10 }

        local Need = NeedLevel()
        if Farm.GetLevel() < Need then return LevelUp(Need) end
        StopLeveling()

        if State ~= "Doing" then
            ShioriReport("Accepting the quest from Shiori", nil, "Restock the Infirmary")
            local Ok, Why = AcceptShiori()
            if not Ok then ShioriReport(Why, "Error") Shiori.GapAt = os.clock() + 5 end
            return false
        end

        local Need2, Done, Total = Missing(DepositTasks())
        local Progress = string.format("Restock the Infirmary %d/%d", Done, Total)
        if next(Need2) == nil then
            ShioriReport("Returning to Shiori", nil, Progress)
            local Ok, Why = TurnIn()
            if not Ok then ShioriReport(Why, "Error") Shiori.GapAt = os.clock() + 3 end
            return false
        end

        -- ขาดยาอะไร = ซื้อส่วนที่ขาดทีเดียวที่ Meku / ครบแล้วค่อยไปลัง
        local Cart = { }
        for Item, Amount in pairs(Need2) do
            local Short = Amount - Count(Item)
            if Short > 0 then Cart[Item] = Short end
        end
        if next(Cart) then
            local Short = CartShort(Cart)
            if Short then return true, "Not enough to buy the elixirs (" .. Short .. ")", "Error" end
            ShioriReport("Buying elixirs at Alchemist Meku", nil, Progress)
            local Ok, Why = BuyCart("Alchemist Meku", Cart)
            if not Ok then ShioriReport(Why, "Error") Shiori.GapAt = os.clock() + 5 end
            return false
        end

        ShioriReport("Stocking the infirmary crates", nil, Progress)
        local Ok, Why = DepositAll()
        if not Ok then ShioriReport(Why, "Error") Shiori.GapAt = os.clock() + 3 end
        return false
    end

    local SetShiori

    local function RunShiori()
        while ShioriRun() do
            task.wait()
            local Ok, Finished, Message, State = pcall(ShioriStep)
            if not Ok then
                ShioriReport("Error: " .. tostring(Finished):sub(1, 80), "Error")
                Farm.Sleep(3, ShioriRun)
            elseif Finished then
                ShioriReport(tostring(Message), State)
                if State == "Done" then
                    Library:Notify("Fishing", Message, 5)
                    break
                end
                Farm.Sleep(5, ShioriRun)
            end
        end
        StopLeveling()
        Movement.Lock(nil)
        Engine.Thread = nil
        if Shiori.Active then SetShiori(false, true) end
    end

    SetShiori = function(Value, SyncToggle)
        if Value then
            TurnOffFlags(ExclusiveFlags.Farm)
            TurnOffFlags(ExclusiveFlags.Breathing)
            TurnOffFlags(ExclusiveFlags.Puzzle)
            TurnOffFlags(ExclusiveFlags.Fishing, "SL2AutoQuestShiori")
            TurnOffFlags(ExclusiveFlags.Quest)
            Engine.Mode = "Shiori"
            FishingStatus.Owner = "Shiori"
            Shiori.Progress = nil
            Shiori.Active = true
            Shiori.GapAt = 0
            Seller.Paused = true
            task.spawn(function()
                -- รอบเก่า (Auto Fishing) ยังค้างอยู่ = รอมันออกก่อน
                while Engine.Thread and Shiori.Active do task.wait() end
                if not Shiori.Active then return end
                Engine.Thread = true
                RunShiori()
            end)
        elseif Shiori.Active then
            Shiori.Active = false
            if Engine.Mode == "Shiori" then Engine.Mode = nil end
            StopLeveling()
            Movement.Lock(nil)
            Seller.Paused = false
            Seller.Keep.Shiori = nil
            if FishingStatus.Owner == "Shiori" then FishingStatus.Owner = nil end
            if SyncToggle then
                Config.AutoQuestShiori = false
                SaveConfiguration()
                local Set = Library.SetFlags and Library.SetFlags["SL2AutoQuestShiori"]
                if Set then pcall(Set, false) end
            end
        end
    end

    --// Auto Legendary Rod (Rare -> Legendary) - ลำดับตามที่ผู้ใช้ยืนยัน 2026-09-29 + โค้ดเกม (Yap.Sofen / Yap.Isao /
    -- DockActions / RodServer):
    --   1) ตก Crustadon 1 + Krathulon 1 (ปลาหายากสุ่มจากการตกปกติ - "The water gives one up when it feels like it")
    --   2) ถือทั้งคู่ไปคุย Dock Master Sofen -> "Pay to hear it" = ToServer("SofenPullLedger") จ่าย 2500 Wen
    --      (Sofen ไม่เอาปลาไป) บอกจุดตกของ Isao
    --   3) ตกแบบไม่ใส่เหยื่อที่ LureSpot จนได้ Drowned Lure (ไม่หมด - NoDelete)
    --   4) ตก Crustadon/Krathulon ให้ครบอย่างละ 2 -> กลางคืนคุย Isao ถือ Lure = ToServer("IsaoTakeToll")
    --      -> WorldEvents.DrownedLine_Paid (บทพูดตอนปลาไม่ครบไม่มี action - ข้ามได้)
    --   5) ตกที่ RaiseSpot ใส่ Drowned Lure แล้วม้วนเบ็ดตามปกติ (ตอบ true หลัง 4.5 วิ) จนได้ Legendary Fishing Rod
    --      Drowned Lure: "the river favors empty reels around it" (CatchChance 0.25 -> ม้วนแล้วส่วนใหญ่ได้ Slipped/Empty)
    --      Isao: "Anything you pull up out there is the water telling you no" / RodServer ส่ง outcome
    --      (Caught/Empty/Slipped/Lost) ให้ DrownedLine.ReportBite - เดิมตอบ false ทันที = Lost (ไม่ได้ม้วน) หลายสิบรอบ
    --      วันที่ 2026-09-29 ไม่ได้เบ็ด -> เปลี่ยนเป็นม้วนจริง (ตรงกับ "empty reels") ยังไม่ยืนยันว่าได้เบ็ด
    --   จุดตกพิเศษ: วาร์ปไปยืนที่พิกัด แล้วหาผิวน้ำ (SwimParts) รอบตัวในระยะ CastRadius แบบเดียวกับ findWater ฝั่งเซิร์ฟ
    local CollectionService = game:GetService("CollectionService")
    local LureSpot = Vector3.new(-144, 862, 201)
    local RaiseSpot = Vector3.new(-2037, 158, 285)
    local LedgerCost = 2500
    local SofenName = "Dock Master Sofen"
    local Legend = { Active = false, GapAt = 0, Spots = { } }
    Engine.Legend = Legend      -- ดูสด/ทดสอบผ่าน dex (Legend.SpotJob)

    local function HasLegendary()
        return Count("Legendary Fishing Rod") > 0
    end

    -- รันเอง (Mode = Legendary) หรือแซง Auto Fishing (Preempt - Mode ยังเป็น Fish แต่ Engine.Hold พักไว้)
    -- ฟาร์มเริ่ม / โหมดอื่นแย่ง = หยุดเอง Auto Upgrade Rod รอให้ว่างแล้วค่อยเริ่มใหม่
    local function LegendRun()
        if not (Session() and Legend.Active and Fighter.Continue == nil) then return false end
        return Engine.Mode == "Legendary" or (Legend.Preempt and Engine.Mode == "Fish")
    end

    local function LegendProgress()
        return string.format("Crustadon %d/2 | Krathulon %d/2 | Lure %s | Toll %s",
            Count("Crustadon"), Count("Krathulon"), Count("Drowned Lure") > 0 and "yes" or "no", TollPaid() and "paid" or "no")
    end

    local function LegendReport(Status, State)
        if not LegendRun() then return end
        Legend.Status = Status
        local Progress, Gear = LegendProgress(), GearText()
        task.wait()     -- GetData = thread เสีย capability ชั่วคราว - คั่นก่อนแตะ UI
        FishingStatus.Write("Upgrade", State, { Mode = "Upgrade Rod (Legendary)", Step = Status, Progress = Progress, Gear = Gear })
    end

    -- ผิวน้ำรอบจุดยืน (ไม่เกิน 36 studs < CastRadius 40 ของ Rare) แบบเดียวกับ findWater ฝั่งเซิร์ฟ: จุดต้องอยู่เหนือ
    -- ก้อนน้ำ (SwimParts) และ ray จากข้างบนต้องไม่ชนของแข็งเหนือผิวน้ำ -> CFrame ยืนหันหาน้ำ + จุดเหวี่ยง
    -- ก้อนน้ำฝั่ง client CanQuery = false (วัดสด) raycast ไม่เคยโดน - เลยเทียบกรอบของ part เอาเอง
    local function WaterAround(Origin)
        local Waters, Ignore = { }, { }
        for _, Tagged in ipairs(CollectionService:GetTagged("SwimParts")) do
            if Tagged:IsA("BasePart") then table.insert(Waters, Tagged) end
            table.insert(Ignore, Tagged.Parent or Tagged)
        end
        if #Waters == 0 then return nil end
        for _, Thing in ipairs({ workspace:FindFirstChild("Debree"), LocalPlayer.Character }) do table.insert(Ignore, Thing) end
        local Exclude = RaycastParams.new()
        Exclude.FilterType = Enum.RaycastFilterType.Exclude
        Exclude.FilterDescendantsInstances = Ignore

        local function SurfaceAt(Point)
            for _, Water in ipairs(Waters) do
                local Local = Water.CFrame:PointToObjectSpace(Point)
                local Half = Water.Size / 2
                if math.abs(Local.X) <= Half.X and math.abs(Local.Z) <= Half.Z then return Water.Position.Y + Half.Y end
            end
            return nil
        end

        local function Direction(Step)
            local Angle = Step * math.pi / 12
            return Vector3.new(math.cos(Angle), 0, math.sin(Angle))
        end

        -- ผิวน้ำที่เหวี่ยงลงได้ตรงนี้ไหม (มีน้ำข้างล่าง + ไม่มีของแข็งบัง) -> ความสูงผิวน้ำ
        local function OpenAt(Point)
            local Surface = SurfaceAt(Point)
            if not Surface then return nil end
            local Top = Vector3.new(Point.X, math.max(Origin.Y, Surface) + 50, Point.Z)
            local Block = workspace:Raycast(Top, Vector3.new(0, -400, 0), Exclude)
            if not Block or Block.Position.Y <= Surface + 0.5 then return Surface end
            return nil
        end

        -- หันไป "กลาง" ช่วงน้ำเปิดที่กว้างที่สุด ไม่ใช่ทิศแรกที่เจอ (จุด Legendary บนหน้าผา: น้ำเปิด 30°-210°
        -- ทิศแรก = 30° ขอบหน้าผา หันเฉียงเข้าฝั่ง) แล้วเหวี่ยงไกลสุดที่ยังเปิดตามทิศนั้น (ไม่เกิน 30 < CastRadius 40)
        for _, Radius in ipairs({ 8, 12, 18, 24, 30, 36 }) do
            local Open = { }
            for Step = 0, 23 do Open[Step] = OpenAt(Origin + Direction(Step) * Radius) ~= nil end
            local BestStart, BestLength = nil, 0
            for Start = 0, 23 do
                if Open[Start] and not Open[(Start - 1) % 24] or (Start == 0 and Open[0]) then
                    local Length = 0
                    while Length < 24 and Open[(Start + Length) % 24] do Length = Length + 1 end
                    if Length > BestLength then BestStart, BestLength = Start, Length end
                end
            end
            if BestStart then
                local Center = BestStart + (BestLength - 1) / 2
                local Facing = Direction(Center)
                for _, Reach in ipairs({ 30, 24, 18, 12, Radius }) do
                    local Point = Origin + Facing * math.max(Reach, Radius)
                    local Surface = OpenAt(Point)
                    if Surface then
                        return CFrame.new(Origin, Origin + Facing), Vector3.new(Point.X, Surface, Point.Z)
                    end
                end
            end
        end
        return nil
    end

    -- งานตกที่จุดพิเศษ: ไปยืนครั้งแรกแล้วจำจุดยืน/จุดเหวี่ยงไว้ (น้ำโหลดตาม streaming ต้องไปถึงก่อนถึงหาเจอ)
    local function SpotJob(Position, Bait, Lose)
        local Key = tostring(Position)
        local Known = Legend.Spots[Key]
        if not Known then
            -- โหลดพื้น/น้ำรอบจุดก่อนวาร์ป (ไม่งั้นร่วงลงช่องว่าง เซิร์ฟดึงกลับ - วัดสดจุดยกเบ็ด)
            pcall(function() LocalPlayer:RequestStreamAroundAsync(Position, 5) end)
            GoTo(CFrame.new(Position + Vector3.new(0, 3, 0)))
            Farm.Sleep(1, ShouldRun)
            local Root = Movement.GetRoot()
            if not Root then return nil, "No character" end
            local Stand, Target = WaterAround(Root.Position)
            if not Stand then return nil, "No water found around " .. tostring(Position) end
            Known = { Stand = Stand, Target = Target }
            Legend.Spots[Key] = Known
        end
        return { Stand = Known.Stand, Target = Known.Target, Bait = Bait, Lose = Lose }
    end
    Legend.SpotJob = SpotJob
    Legend.WaterAround = WaterAround
    getgenv().ValkyrieFishing = { Engine = Engine, Legend = Legend }     -- ดูสดผ่าน dex

    -- เหวี่ยง 1 รอบ (Job = nil = ตกปกติที่ท่า Jeso ตามตั้งค่าเหยื่อของ Auto Fishing)
    local function LegendCast(Job)
        -- Hold ตอนแซง Auto Fishing = ของเราเอง (พัก Auto Fishing) ไม่ต้องรอ
        if Engine.Hold and not Legend.Preempt then
            Farm.WaitFor(function() return not Engine.Hold end, 60, LegendRun)
            return
        end
        Engine.Job = Job
        Engine.Busy = true
        local Ok, Name, Why = pcall(FishOnce, BestRod(), Config.FishingUseBait == true)
        Engine.Busy = false
        Engine.Job = nil
        if not Ok then error(Name, 0) end

        -- เหวี่ยงไม่ออก 2 รอบติด = ถอดเบ็ดล้าง token ค้าง (เหมือน Auto Fishing)
        Engine.CastFails = Why == "Could not cast" and (Engine.CastFails or 0) + 1 or 0
        if Engine.CastFails >= 2 then
            Engine.CastFails = 0
            LegendReport("Rod stuck - re-equipping")
            ResetRod(LegendRun)
        end
        if Name then
            LegendReport("Caught " .. Name)
        elseif Why and Why ~= "Nothing on the hook" and Why ~= "Let the fish go" then
            LegendReport(tostring(Why), "Error")
            Farm.Sleep(2, LegendRun)
        end
    end

    -- ทำ 1 ขั้น - คืน true = จบ (ได้ Legendary) / ติดเงื่อนไข (รอ 5 วิแล้วลองใหม่ ไม่ปิด toggle)
    -- ขั้นที่ต้องทำตอนนี้: Sofen / Lure / Toll / Raise = งานพิเศษ (ต้องไปที่อื่น) / Fish = แค่ตกปลาปกติหา
    -- Crustadon-Krathulon / Night = รอกลางคืน / Done
    local function LegendNeed()
        if HasLegendary() then return "Done" end
        local HasLure = Count("Drowned Lure") > 0
        if TollPaid() and HasLure then return "Raise" end
        if not HasLure then
            -- จ่าย Sofen แล้ว = เซิร์ฟตั้ง WorldEvents.DrownedLine_Told (วัดสด) - ไม่จ่ายซ้ำ
            if WorldEvent("DrownedLine_Told") then return "Lure" end
            return (Count("Crustadon") >= 1 and Count("Krathulon") >= 1) and "Sofen" or "Fish"
        end
        if not HasToll() then return "Fish" end
        return IsNight() and "Toll" or "Night"
    end
    Engine.LegendNeed = LegendNeed
    Engine.LegendSpecial = { Sofen = true, Lure = true, Toll = true, Raise = true }

    local function LegendStep()
        if HasLegendary() then return true, "Done - you have the Legendary Fishing Rod", "Done" end
        if not HasPermit() then return true, "Need the Fishing Permit (Auto Unlock Fishing)", "Error" end
        if Count("Rare Fishing Rod") == 0 then return true, "Need the Rare Fishing Rod (Auto Upgrade Rod)", "Error" end
        if os.clock() < Legend.GapAt then return false end
        KeepUpgradeItems("Rare Fishing Rod")

        local Need = LegendNeed()
        -- แซง Auto Fishing อยู่ แล้วเหลือแค่ตกปลาปกติ/รอกลางคืน = คืนให้ Auto Fishing ทำต่อ
        if Legend.Preempt and not Engine.LegendSpecial[Need] then
            return true, "Back to Auto Fishing", "Handoff"
        end

        -- 5) จ่ายค่าผ่านแล้ว = ยกเบ็ดที่ RaiseSpot (ใส่ Lure ม้วนเบ็ดปกติ หวัง reel เปล่า)
        if Need == "Raise" then
            local Job, Why = SpotJob(RaiseSpot, "Drowned Lure", false)
            if not Job then LegendReport(Why, "Error") Legend.GapAt = os.clock() + 5 return false end
            LegendReport("Raising Isao's rod (Drowned Lure, reeling for empty reels)")
            LegendCast(Job)
            return false
        end

        -- 1) ตก Crustadon + Krathulon (อย่างละ 1 ก่อนไป Sofen / อย่างละ 2 ก่อนจ่าย Isao)
        if Need == "Fish" then
            local Target = Count("Drowned Lure") > 0 and "2 Crustadon + 2 Krathulon (Isao's toll)" or "1 Crustadon + 1 Krathulon (for Sofen)"
            LegendReport("Fishing for " .. Target)
            LegendCast(nil)
            return false
        end

        -- 2) ถือปลาอย่างละ 1 -> ฟังประวัติจาก Sofen (จ่ายครั้งเดียว)
        if Need == "Sofen" then
            if Wen() < LedgerCost then return true, string.format("Need %d Wen for Sofen's ledger", LedgerCost), "Error" end
            LegendReport("Paying Dock Master Sofen for Isao's file")
            if not GoToNpc(SofenName) then LegendReport(SofenName .. " not found", "Error") Legend.GapAt = os.clock() + 5 return false end
            SignalEvent.ToServer("SofenPullLedger")
            if not Farm.WaitFor(function() return WorldEvent("DrownedLine_Told") end, 3, LegendRun) then
                LegendReport("Sofen did not open the ledger", "Error")
                Legend.GapAt = os.clock() + 5
            end
            return false
        end

        -- 3) ตกเบ็ดเปล่าที่จุดของ Isao จนได้ Drowned Lure
        if Need == "Lure" then
            local Job, Why = SpotJob(LureSpot, false, false)
            if not Job then LegendReport(Why, "Error") Legend.GapAt = os.clock() + 5 return false end
            LegendReport("Fishing for the Drowned Lure (no bait)")
            LegendCast(Job)
            return false
        end

        -- 4) กลางคืนจ่าย Isao (ปลาอย่างละ 2 + ถือ Lure)
        if Need == "Night" then
            LegendReport("Waiting for night to pay Isao", "Idle")
            Farm.Sleep(5, LegendRun)
            return false
        end
        LegendReport("Paying Isao's toll (night)")
        local Pivot = NpcPivot("Legendary Fisherman Isao")
        GoTo(Pivot and Pivot * CFrame.new(0, 0, -4) or CFrame.new(IsaoSpawn + Vector3.new(0, 3, 0)))
        SignalEvent.ToServer("IsaoTakeToll")
        if not Farm.WaitFor(TollPaid, 3, LegendRun) then
            LegendReport("Isao did not take the toll", "Error")
            Legend.GapAt = os.clock() + 5
        end
        return false
    end

    local SetLegend

    local function RunLegend()
        while LegendRun() do
            task.wait()
            -- แซงอยู่แล้วขั้นพิเศษ error (เว้นช่วง) = คืน Auto Fishing ไปก่อน ไม่กักไว้รอ
            if Legend.Preempt and os.clock() < Legend.GapAt then break end
            local Ok, Finished, Message, State = pcall(LegendStep)
            if not Ok then
                Engine.Job = nil
                LegendReport("Error: " .. tostring(Finished):sub(1, 80), "Error")
                -- แซงอยู่ = ไม่กัก Auto Fishing ไว้ตอน error คืนให้ตกต่อ แล้วค่อยลองใหม่ทีหลัง
                if Legend.Preempt then Legend.GapAt = os.clock() + 10 break end
                Farm.Sleep(3, LegendRun)
            elseif Finished then
                if State ~= "Handoff" then LegendReport(tostring(Message), State) end
                if State == "Done" or State == "Handoff" then break end   -- Auto Upgrade Rod เห็นเบ็ด Legendary แล้วจบเอง
                if Legend.Preempt then Legend.GapAt = os.clock() + 10 break end
                Farm.Sleep(5, LegendRun)
            end
        end
        Engine.Job = nil
        Movement.Lock(nil)
        if not Legend.Preempt then Engine.Thread = nil end
        if Legend.Active then SetLegend(false) end
    end

    -- เริ่ม/หยุดโดย Auto Upgrade Rod (ขั้น Rare -> Legendary)
    --   Preempt = false: ไม่มีโหมดไหนคุมเบ็ด = รันเองทุกขั้น (Mode = Legendary)
    --   Preempt = true : Auto Fishing รันอยู่ = พักมัน (Engine.Hold) รอเหวี่ยงรอบที่ค้างจบ ทำงานพิเศษ แล้วคืน
    SetLegend = function(Value, Preempt)
        if Value then
            if Legend.Active then return end
            FishingStatus.Owner = "Upgrade"
            Legend.Active = true
            Legend.Preempt = Preempt == true
            if Legend.Preempt then
                Engine.Hold = true
                task.spawn(function()
                    Farm.WaitFor(function() return not Engine.Busy end, 60, LegendRun)
                    if not Legend.Active then return end
                    RunLegend()
                end)
                return
            end
            Engine.Mode = "Legendary"
            Seller.Paused = true
            task.spawn(function()
                while Engine.Thread and Legend.Active do task.wait() end
                if not Legend.Active then return end
                Engine.Thread = true
                RunLegend()
            end)
        elseif Legend.Active then
            Legend.Active = false
            Engine.Job = nil
            Movement.Lock(nil)
            if Legend.Preempt then
                Legend.Preempt = false
                Engine.Hold = false         -- Auto Fishing ตกต่อ (กลับไปจุดตกเอง)
                return
            end
            if Engine.Mode == "Legendary" then Engine.Mode = nil end
            Seller.Paused = false
            Release()
        end
    end
    Engine.SetLegend = SetLegend
    Engine.LegendReady = function() return os.clock() >= Legend.GapAt end
    Engine.LegendActive = function() return Legend.Active end

    -- Auto Best Title: เช็คทุก 1 วิ (เปิด/ปิด toggle, เปลี่ยนตกปลา-ฟาร์ม, reinject ค้าง Title ไว้ = คืนให้)
    task.spawn(function()
        while Session() do
            SyncTitles()
            task.wait(1)
        end
    end)

    task.wait()

    -- ปุ่ม Upgrade อยู่ใต้การ์ดรวมใน section Unlock & Upgrade
    local UpgradeSection = FishingStatus.Section
    if UpgradeSection then
        UpgradeSection:Toggle({
            Name = "Auto Upgrade Rod",
            Flag = "SL2AutoUpgradeFishing",
            Default = Config.AutoUpgradeFishing == true,
            Callback = function(Value)
                Config.AutoUpgradeFishing = Value == true
                SaveConfiguration()
                SetUpgrade(Value)
            end
        })

        -- สถานะตอนว่าง (ยังไม่มีโหมดไหนเป็นเจ้าของการ์ด)
        task.spawn(function()
            task.wait(1)
            local Permit, Progress, Gear = HasPermit(), Goal(BestRod()), GearText()
            local Level = Farm.GetLevel()
            task.wait()
            FishingStatus.Write("Idle", "Idle", {
                Mode = "Idle",
                Step = Permit and "Fishing unlocked" or string.format("Fishing locked (Lv %d)", Level),
                Progress = Progress,
                Gear = Gear,
            })
        end)
    end

    task.wait()

    local AutoSection = FishingPage:Section({
        Name = "Auto Fishing",
        Description = "Fish nonstop with your best rod",
        Icon = "80758916183665",
        Side = 2
    })

    AutoSection:Guide("How to use", {
        "Needs the Fishing Permit and a rod",
        "Pick a Fishing Spot and bait, then turn on Auto Fishing",
        "Auto Buy Bait is optional",
    })

    AutoCard = MakeStatusCard(AutoSection, "Auto Fishing Status", { "Step", "Gear", "Catches", "Last Catch" }, false)

    task.spawn(function()
        task.wait(1)
        if not Engine.Mode then
            local Gear = GearText()
            task.wait()
            pcall(function()
                AutoCard:SetState("Idle")
                AutoCard:Set("Step", "-")
                AutoCard:Set("Gear", Gear)
                AutoCard:Set("Catches", "0")
                AutoCard:Set("Last Catch", "-")
            end)
        end
    end)

    task.wait()

    AutoSection:Dropdown({
        Name = "Fishing Spot",
        Flag = "SL2FishingSpot",
        Items = Spots,
        Default = table.find(Spots, Config.FishingSpot) and Config.FishingSpot or Spots[1],
        Multi = false,
        Callback = function(Value)
            if type(Value) ~= "string" then return end
            Config.FishingSpot = Value
            SaveConfiguration()
        end
    })

    AutoSection:Toggle({
        Name = "Use Bait",
        Flag = "SL2FishingUseBait",
        Default = Config.FishingUseBait == true,
        Callback = function(Value)
            Config.FishingUseBait = Value == true
            SaveConfiguration()
        end
    })

    AutoSection:Dropdown({
        Name = "Bait",
        Flag = "SL2FishingBait",
        Items = BaitChoices,
        Default = table.find(BaitChoices, Config.FishingBait) and Config.FishingBait or BaitChoices[1],
        Multi = false,
        Callback = function(Value)
            if type(Value) ~= "string" then return end
            Config.FishingBait = Value
            SaveConfiguration()
        end
    })

    AutoSection:Toggle({
        Name = "Auto Buy Bait",
        Description = "Buys bait when it runs out",
        Flag = "SL2FishingAutoBuyBait",
        Default = Config.FishingAutoBuyBait == true,
        Callback = function(Value)
            Config.FishingAutoBuyBait = Value == true
            SaveConfiguration()
        end
    })

    AutoSection:Toggle({
        Name = "Auto Fishing",
        Flag = "SL2AutoFishing",
        Default = Config.AutoFishing == true,
        Callback = function(Value)
            Config.AutoFishing = Value == true
            SaveConfiguration()
            SetFish(Value)
        end
    })

    task.wait()

    -- อยู่ section เดียวกับ Unlock & Upgrade ใช้การ์ด Fishing Status ร่วมกัน
    local ShioriSection = FishingStatus.Section
    if ShioriSection then ShioriSection:Toggle({
        Name = "Auto Quest Shiori",
        Flag = "SL2AutoQuestShiori",
        Default = Config.AutoQuestShiori == true,
        Callback = function(Value)
            -- ปลดแล้ว = เปิดไม่ได้ (ดีดกลับเป็นปิด)
            if Value and ShioriDone() then
                Config.AutoQuestShiori = false
                SaveConfiguration()
                task.defer(function()
                    local Set = Library.SetFlags and Library.SetFlags["SL2AutoQuestShiori"]
                    if Set then pcall(Set, false) end
                    Library:Notify("Fishing", "Shiori quest already done - Fish Head is unlocked", 4)
                end)
                return
            end
            Config.AutoQuestShiori = Value == true
            SaveConfiguration()
            SetShiori(Value)
        end
    }) end
end

---- ============ Players Tab ============ ----

local PlayersCleanup = nil

task.wait()

---- ============ Auto Sell (UI) ============ ----
do
    local Config = getgenv().ConfigurationTable
    local SellPage = Window:Page({ Name = "Auto Sell", Icon = "coins", Columns = 2 })

    local SellMainSection = SellPage:Section({
        Name = "Auto Sell",
        Description = "Sell loot to Ginzo (Mistfall Harbor)",
        Icon = "80758916183665",
        Side = 1
    })

    local SellListSection = SellPage:Section({
        Name = "Sell List",
        Description = "Pick items or whole rarities",
        Icon = "80758916183665",
        Side = 2
    })

    for _, Key in ipairs({ "AutoSellItems", "AutoSellRarities" }) do
        if type(Config[Key]) ~= "table" then Config[Key] = { } end
    end

    SellMainSection:Guide("How to use", {
        "Sell List (right): pick items and/or whole rarities to sell",
        "Turn on Auto Sell: flies to Ginzo (Mistfall Harbor), sells, then comes back. While farming it waits until the current target dies",
        "Sell Every: minutes between selling trips",
        "Keep Equipped: when on, it never sells your toolbar weapons or worn outfit",
        "Sell Now: one selling trip right away",
    })

    -- ของทั้งเกมที่ขายได้ (ไม่ใช่แค่ที่อยู่ในกระเป๋า - ตั้งล่วงหน้าไว้ ได้มาเมื่อไหร่ขายเลย)
    -- + ชื่อที่เคยเลือกไว้แต่ไม่อยู่ในลิสต์แล้ว (อัปเดตเกม) ไม่ให้ค่าที่เซฟหาย
    local function ItemOptions()
        local List, Seen = { }, { }
        for _, Name in ipairs(Seller.AllSellableNames()) do
            table.insert(List, Name)
            Seen[Name] = true
        end
        for _, Name in ipairs(Config.AutoSellItems) do
            if not Seen[Name] then table.insert(List, Name) end
        end
        table.sort(List)
        return List
    end

    task.wait()

    SellMainSection:Toggle({
        Name = "Auto Sell",
        Flag = "SL2AutoSell",
        Default = Config.AutoSell,
        Callback = function(Value)
            Config.AutoSell = Value
            if Value then Seller.NextAt = 0 end     -- เปิดแล้วขายรอบแรกเลย
            SaveConfiguration()
        end
    })

    SellMainSection:Slider({
        Name = "Sell Every",
        Flag = "SL2AutoSellInterval",
        Min = 1,
        Max = 30,
        Default = Config.AutoSellInterval,
        Suffix = " min",
        Callback = function(Value)
            Config.AutoSellInterval = Value
            SaveConfiguration()
        end
    })

    SellMainSection:Toggle({
        Name = "Keep Equipped",
        Description = "Never sell items in toolbar or worn outfit",
        Flag = "SL2AutoSellKeepEquipped",
        Default = Config.AutoSellKeepEquipped,
        Callback = function(Value)
            Config.AutoSellKeepEquipped = Value
            SaveConfiguration()
        end
    })

    SellMainSection:Button({
        Name = "Sell Now",
        Description = "Fly to Ginzo and sell the list once",
        Callback = function()
            if Seller.Busy then return end
            task.spawn(function()
                local Farming = Fighter.Continue ~= nil
                if Farming then
                    -- ฟาร์มรันอยู่ = ให้ลูปฟาร์มขายตอนว่าง (ไม่ตัดกลางไฟต์)
                    Seller.NextAt = 0
                    if not Config.AutoSell then Seller.Status = "Turn on Auto Sell while farming" end
                else
                    Seller.Run(nil, true)
                end
            end)
        end
    })

    task.wait()

    SellListSection:Dropdown({
        Name = "Sell Rarity",
        Flag = "SL2AutoSellRarities",
        Items = Seller.RarityNames(),
        Default = Config.AutoSellRarities,
        Multi = true,
        KeepOrder = true,
        Seperator = false,
        Callback = function(Value)
            if type(Value) ~= "table" then return end
            Config.AutoSellRarities = Value
            SaveConfiguration()
        end
    })

    task.wait()

    local Options = ItemOptions()
    task.wait()

    SellListSection:Dropdown({
        Name = "Sell Items",
        Flag = "SL2AutoSellItems",
        Items = Options,
        Default = Config.AutoSellItems,
        Multi = true,
        Seperator = false,
        Callback = function(Value)
            if type(Value) ~= "table" then return end
            Config.AutoSellItems = Value
            SaveConfiguration()
        end
    })

    task.wait()

    --// Auto Quest Jewelry Box - เควส "Ill find the jewelry box(Lv 45)" ของ Ginzo (Mistfall Harbor)
    --
    -- ยืนยันสดผ่าน dex (ทำจบจริง 1 รอบ):
    --   รับเควส: Lv 45+ ไม่เสียเงิน - AddQuest ต้องยืนใกล้ Ginzo
    --   1) "Jewelry Box found" (Pickup): วาร์ปไป Positions[1] แล้ว QuestProgress(เควส, task, 1) ได้ Jewelry Box
    --   2) "Return to Ginzo" (Deliver ต้องมี Jewelry Box): ยืนใกล้ Ginzo แล้ว QuestProgress(เควส, task)
    --   รางวัล 240 Wen + 2700 Exp - LogCompletion = ทำได้ครั้งเดียว (Done แล้ว CanAddQuest คืน false, 2 ถาวร)
    -- ทำทีละขั้นจนเควส Done แล้วปิดตัวเอง
    local QuestSection = SellPage:Section({
        Name = "Ginzo Quest",
        Description = "Jewelry Box quest (Lv 45+, one time)",
        Icon = "80758916183665",
        Side = 1
    })

    local Quests = nil
    pcall(function() Quests = require(ReplicatedStorage.CAM.Global.Subsets.Gameplay.Quests) end)

    local QuestId = "Ill find the jewelry box(Lv 45)"
    local PickupTask = "Jewelry Box found"
    local ReturnTask = "Return to Ginzo"
    local Def = Quests and Quests.Holder[QuestId]
    local NeedLevel = Def and Def.Requirements and Def.Requirements.Level or 45
    local BoxPos = nil
    pcall(function() BoxPos = Def.TaskSpecs[PickupTask].Positions[1] end)
    local GinzoPos = nil
    pcall(function()
        local Spawn = require(ReplicatedStorage.Ouwland.Content["Mistfall Harbor"].Npcs.Ginzo).Spawns[1]
        GinzoPos = typeof(Spawn) == "CFrame" and Spawn.Position or Spawn
    end)

    local Box = { Active = false, Thread = nil }
    local StepGapAt = 0
    local QuestCard = MakeStatusCard(QuestSection, "Quest Status", { "Step", "Progress" }, false)

    local function ShouldRun()
        return getgenv().ValkyrieSession == SessionToken and Box.Active
    end

    local function Report(Step, State)
        local Level, QuestState = Farm.GetLevel(), Farm.GetQuestState(QuestId)
        task.wait()
        pcall(function()
            if State then QuestCard:SetState(State) end
            QuestCard:Set("Step", Step)
            QuestCard:Set("Progress", string.format("Quest %s | Lv %d/%d", tostring(QuestState), Level, NeedLevel))
        end)
    end

    local function GoTo(Target)
        Movement.Lock(nil)
        Movement.Go(Target, 4, 30, ShouldRun)
        Movement.Cancel()               -- Teleport ทิ้ง noclip ไว้ = ร่วงทะลุพื้น (เหมือน Auto Unlock Fishing)
        Farm.Sleep(0.5, ShouldRun)      -- ให้เซิร์ฟเห็นตำแหน่งใหม่ก่อนยิง event (เซิร์ฟเช็คระยะ)
    end

    local function GinzoStand()
        return CFrame.new(GinzoPos + Vector3.new(5, 0, 0), GinzoPos)
    end

    -- ทำ 1 ขั้น - คืน true = จบ (เควสเสร็จ / ทำต่อไม่ได้) พร้อมข้อความ + สถานะ
    local function Step()
        local State = Farm.GetQuestState(QuestId)
        if State == "Done" then
            return true, "Completed (one-time quest)", "Done"
        end
        if not (Def and BoxPos and GinzoPos) then
            return true, "Quest data not found", "Error"
        end
        if os.clock() < StepGapAt then return false end

        if State ~= "Doing" then
            if Farm.GetLevel() < NeedLevel then
                return true, string.format("Need Lv %d (you are Lv %d)", NeedLevel, Farm.GetLevel()), "Error"
            end
            Report("Talking to Ginzo (accept quest)", "Running")
            GoTo(GinzoStand())
            if not Farm.AcceptQuestById(QuestId) then StepGapAt = os.clock() + 2 end
            return false
        end

        -- 1) เก็บ Jewelry Box - มีในกระเป๋าแล้ว = ข้าม
        if not Farm.HasItem("Jewelry Box") then
            Report("Picking up the Jewelry Box", "Running")
            GoTo(CFrame.new(BoxPos + Vector3.new(0, 3, 0)))
            Farm.QuestProgress(QuestId, PickupTask, 1)
            if not Farm.WaitFor(function() return Farm.HasItem("Jewelry Box") end, 3, ShouldRun) then
                StepGapAt = os.clock() + 2
            end
            return false
        end

        -- 2) ได้กล่องแล้ว -> ส่งคืน Ginzo
        Report("Returning the box to Ginzo", "Running")
        GoTo(GinzoStand())
        Farm.QuestProgress(QuestId, ReturnTask)
        if not Farm.WaitFor(function() return Farm.GetQuestState(QuestId) ~= "Doing" end, 3, ShouldRun) then
            StepGapAt = os.clock() + 2
        end
        return false
    end

    local SetJewelryBox

    local function RunJewelryBox()
        while ShouldRun() do
            task.wait()
            -- error / ติดเงื่อนไข = ไม่ปิด toggle เอง ลองใหม่ทุก 5 วิ - ปิดเฉพาะเควสจบแล้ว
            local Ok, Finished, Message, State = pcall(Step)
            if not Ok then
                Report("Error: " .. tostring(Finished):sub(1, 80) .. " - retrying", "Error")
                Farm.Sleep(5, ShouldRun)
            elseif Finished then
                Report(Message, State)
                if State == "Done" then
                    Library:Notify("Ginzo Quest", "Jewelry Box quest completed", 5)
                    break
                end
                Farm.Sleep(5, ShouldRun)
            end
        end

        Movement.Lock(nil)
        Box.Thread = nil
        if Box.Active then SetJewelryBox(false, true) end
    end

    SetJewelryBox = function(Value, SyncToggle)
        if Value then
            TurnOffFlags(ExclusiveFlags.Farm)
            TurnOffFlags(ExclusiveFlags.Breathing)
            TurnOffFlags(ExclusiveFlags.Puzzle)
            TurnOffFlags(ExclusiveFlags.Fishing)
            Box.Active = true
            StepGapAt = 0
            if not Box.Thread then Box.Thread = task.spawn(RunJewelryBox) end
        else
            Box.Active = false
            Movement.Lock(nil)
            if SyncToggle then
                local Set = Library.SetFlags and Library.SetFlags["SL2AutoJewelryBox"]
                if Set then pcall(Set, false) end
            end
        end
    end

    QuestSection:Toggle({
        Name = "Auto Quest Jewelry Box",
        Description = "Lv 45+: accept from Ginzo, pick up the box, return it (240 Wen + 2700 Exp, once)",
        Flag = "SL2AutoJewelryBox",
        Default = getgenv().ConfigurationTable.AutoJewelryBox == true,
        Callback = function(Value)
            getgenv().ConfigurationTable.AutoJewelryBox = Value == true   -- เซฟ = รันใหม่เปิดกลับเอง
            SaveConfiguration()
            SetJewelryBox(Value)
        end
    })

    task.spawn(function()
        if Farm.GetQuestState(QuestId) == "Done" then
            Report("Completed (one-time quest)", "Done")
        else
            Report("Idle", "Idle")
        end
    end)
end

task.wait()

---- ============ Ouwigahara - Automatically ============ ----
--
-- หอคอย Ouwigahara = เซิร์ฟ Minigames (PlaceId เดียวกับ Final Selection) ที่ workspace.MinigameKey = "Ouwigahara"
-- ยืนยันสด 2026-10-01 (ถอด bytecode Minigames Place.Minigames.Ouwigahara.* + เล่นจริงบน Komqfq ถึงชั้น 12):
--   Lobby: StartPad.ReadyUp (prompt) -> Readied -> 20 วิ -> MinigameState = "Climbing"
--   ชั้น: มอนอยู่ Humanoids.Regions.Temporary.ActiveNpcs / workspace.MinigameEnemiesLeft = เหลือกี่ตัว
--   เคลียร์ชั้น = เซิร์ฟสร้าง Player.OuwigaharaOffers (Folder) ลูกเป็นการ์ด (ชื่อ = id) attribute
--     Type / Title / Rarity / Guaranteed + ข้อมูลของการ์ด (Points / Amount+Stat / Rerolls / Event)
--     เลือก = SignalEvent.ToServer("OuwigaharaRequest", { action = "Pick", id = ชื่อการ์ด })
--     ตั๋วใหม่ทั้งมือ = { action = "Reroll" } (Player.OuwigaharaRerolls) / ไม่เลือก 30 วิ = เซิร์ฟสุ่มให้
--     ชั้นละ 2 มือ: มือของรางวัล (Heal + Stat การันตี + สุ่ม 3) แล้วมือ event (มี Skip)
--   พักระหว่างชั้น 10 วิ (MinigameWaveBreak) โหวตข้ามได้ { action = "Skip" }
--   หัวใจหมด -> Shops (Changer Zeni แลกแต้มหอ / LeavePad กลับโลกหลัก)
-- คะแนนการ์ด (หน่วย = แต้มหอ RunPoints): ถ้วย = KillPoints.Normal (15) x จำนวนตัว (Trophy 5 ... Supreme 100)
--   ค่าอื่นเทียบกับ "มือเฉลี่ย" ที่จำลองจากน้ำหนักจริงของเกม (MinigameSettings.Ouwigahara.RewardRarities +
--   RewardRarity.Weight + RewardRarityBiasPerFloor + RarityFirstFloor) - ใช้ตัดสิน reroll ด้วย
Window:Category("Ouwigahara - Automatically")

do
    local Config = getgenv().ConfigurationTable
    if (tonumber(Config.OuwiInstantKillHealth) or 90) > 90 then Config.OuwiInstantKillHealth = 90 end

    local function Require(Path)
        local Ok, Module = pcall(function() return require(Path()) end)
        return Ok and Module or nil
    end

    local Settings = Require(function() return ReplicatedStorage.CAM.Global.MinigameSettings end)
    Settings = Settings and Settings.Settings and Settings.Settings.Ouwigahara or { }
    local RewardRarity = Require(function() return ReplicatedStorage["Minigames Place"].Minigames.Ouwigahara.RewardRarity end)
    local SignalEvent = HubSignal(Require(function() return ReplicatedStorage.Communication.ServerAndClient.Signals.SignalEvent end))
    local SignalFunction = HubSignal(Require(function() return ReplicatedStorage.Communication.ServerAndClient.Signals.SignalFunction end))

    local Ouwi = { Status = "-", Card = "-", Kpf = 20, FloorStartPoints = nil, FloorSeen = nil, Voted = nil, Hand = nil }
    Farm.Ouwigahara = Ouwi

    local function InTower()
        return workspace:GetAttribute("MinigameKey") == "Ouwigahara"
    end

    local function Attr(Name)
        return LocalPlayer:GetAttribute(Name)
    end

    ---- น้ำหนักจริงของเกม ----

    local FallbackWeight = { 60, 20, 10, 8, 6, 3, 1 }
    local function Weight(Rarity)
        Rarity = tonumber(Rarity) or 1
        local Ok, Value = pcall(function() return RewardRarity.Weight(Rarity) end)
        return (Ok and tonumber(Value)) or FallbackWeight[Rarity] or 1
    end

    local function Bias(Floor)
        return 1 + (tonumber(Settings.RewardRarityBiasPerFloor) or 0.012) * math.max((Floor or 1) - 1, 0)
    end

    local function RarityOpen(Rarity, Floor)
        local First = Settings.RarityFirstFloor and Settings.RarityFirstFloor[Rarity]
        return (tonumber(First) or 1) <= (Floor or 1)
    end

    local KillPoints = (Settings.KillPoints and tonumber(Settings.KillPoints.Normal)) or 15
    local TrophyKills = { 5, 10, 25, 50, 100 }      -- Rewards.Score.Points: Trophy / Fine / Greater / Grand / Supreme

    -- ชนิดการ์ดสุ่มในมือ (ไม่รวม Heal/Stat ที่การันตี) - Roguelike มีการ์ดสร้างตัวเพิ่ม (RoguelikeOnly)
    local function DrawPool(Floor, Roguelike, Party)
        local Rarities = Settings.RewardRarities or { }
        local Pool = { }
        local function Add(Name, MinFloor)
            if (MinFloor or 1) <= Floor and Rarities[Name] then
                local Rarity = Rarities[Name]
                table.insert(Pool, { Name = Name, W = Weight(Rarity) * Bias(Floor) ^ (Rarity - 1), Rarity = Rarity })
            end
        end
        Add("Points") Add("SwapMap") Add("Reroll") Add("ExtraLife") Add("Fortune", 5)
        if Party then Add("Revive") end
        if Roguelike then
            Add("Skill") Add("Clan") Add("SkillSwap", 5) Add("AscendClan", 8) Add("Forge", 8) Add("Potion") Add("Weapon") Add("Trade")
        end
        return Pool
    end

    local function RollTrophy(Floor)
        local Total, Options = 0, { }
        for Rarity = 1, 5 do
            if RarityOpen(Rarity, Floor) then
                local W = Weight(Rarity) * Bias(Floor) ^ (Rarity - 1)
                Total = Total + W
                table.insert(Options, { Rarity = Rarity, W = W })
            end
        end
        local Roll = math.random() * Total
        for _, Option in ipairs(Options) do
            Roll = Roll - Option.W
            if Roll <= 0 then return TrophyKills[Option.Rarity] * KillPoints end
        end
        return TrophyKills[1] * KillPoints
    end

    ---- คุณค่าการ์ด ----

    local function Context()
        local Humanoid = Movement.GetHumanoid()
        local Floor = tonumber(workspace:GetAttribute("MinigameFloor")) or 1
        return {
            Floor = Floor,
            Hearts = tonumber(Attr("Hearts")) or 3,
            Points = tonumber(Attr("RunPoints")) or 0,
            Rerolls = tonumber(Attr("OuwigaharaRerolls")) or 0,
            Health = Humanoid and Humanoid.MaxHealth > 0 and Humanoid.Health / Humanoid.MaxHealth or 1,
            Roguelike = workspace:GetAttribute("MinigameRunFreshStart") == true,
            Party = (tonumber(workspace:GetAttribute("MinigameRunSize")) or 1) > 1,
            Kpf = Ouwi.Kpf,
            FloorsLeft = 12,
            HandEV = 100,
            Ticket = 30,
        }
    end

    -- คะแนนเพิ่มของ stat ต่อหน่วย (เทียบเป็นสัดส่วนของ "มือเฉลี่ย")
    local StatWorth = {
        ["Additional Damage Factor"] = 8, ["Damage Reduction Factor"] = 9, ["Max Health Factor"] = 6,
        ["Attack Speed Factor"] = 5, ["Cooldown Reduction Factor"] = 2, ["Movement Speed Factor"] = 1,
        ["Max Health"] = 0.01, ["Max Stamina"] = 0.002, ["Block Points"] = 0.03, ["Additional Damage"] = 0.04,
    }

    -- event ที่ทำให้ตายง่าย (หัวใจเหลือ 1 ไม่รับ) / ที่เสียของถาวร
    -- โอกาสเสียหัวใจเพิ่ม (โดยประมาณ) ต่อชั้นของ event ที่ทำให้ชั้นอันตรายขึ้น - หักเป็นค่าหัวใจ (เท่าการ์ด Extra Life)
    -- วัดสด 2026-10-01: Bleeding Floor (เสีย 1% เลือด/วิ ทั้งชั้น) โดนรวม ~360/นาที มากกว่าดาเมจท่าบอสทั้งหมด
    local Risky = {
        BleedingFloor = 0.35, GlassFloor = 0.3, BloodMoon = 0.35, Berserkers = 0.12, TheHorde = 0.15,
        TwinBosses = 0.2, BossRush = 0.25, Champion = 0.15, BossHunt = 0.15, DoubleTime = 0.12, FairFight = 0.1,
        HeavyAir = 0.05, GlassCannon = 0.3, Featherweight = 0.2, Sacrifice = 0.1, BloodPact = 0.1, Wager = 0.1, TimeAttack = 0.1,
    }

    local function EventValue(Card, Ctx)
        local Name = tostring(Card:GetAttribute("Event") or "")
        local Title = tostring(Card:GetAttribute("Title") or "")
        if Config.OuwiSafeEvents and Ctx.Hearts <= 1 and Risky[Name] then return -1e6 end
        local Risk = (Risky[Name] or 0) * Ctx.HandEV * (Ctx.Hearts <= 1 and 8 or 5)

        local Mult = tonumber(Title:match("x(%d+%.?%d*) points"))
        local Floors = tonumber(Card:GetAttribute("Floors")) or 0
        local Value = 0
        if Mult then
            Value = (Mult - 1) * Ctx.Kpf * (Floors > 0 and Floors or Ctx.FloorsLeft)
        end

        local Special = {
            TollGate = -Ctx.HandEV * 5 + Ctx.HandEV * 1.2,
            Tribute = -500 + Ctx.HandEV * 1.2,
            Sacrifice = Ctx.HandEV * 1.5 - Ctx.HandEV * 0.5,
            BloodPact = Ctx.HandEV * 0.6 - (Ctx.Health < 0.6 and Ctx.HandEV or 0),
            CheapSeats = Ctx.HandEV * 0.15,
            TicketPack = Ctx.Ticket + Ctx.HandEV * 0.3,
            Mulligan = Ctx.Ticket * 2 + Ctx.HandEV * 0.8,
            JackpotFloor = Ctx.HandEV * 2,
            RushHour = Ctx.HandEV * 0.3,
            Handoff = Ctx.Party and Ctx.Ticket * 2 or -1,
            Adrenaline = Ctx.HandEV * (1 - Ctx.Health) * 1.5,
            Bulwark = Ctx.HandEV * (1 - Ctx.Health) * 1.5,
            SecondChance = Ctx.HandEV * 3,
            Reincarnation = Ctx.HandEV * 2,
            Reincarnated = -1e6,
            LuckyDraw = Ctx.HandEV * 0.1 * Ctx.FloorsLeft,
            LoadedDice = Ctx.Ticket * Ctx.FloorsLeft,
            Streak = Ctx.Kpf * 0.25 * Ctx.FloorsLeft,
            Bounty = Ctx.Kpf * 0.3,
            Headhunter = Ctx.Kpf * 0.5,
            Vampiric = Ctx.HandEV * 0.5,
            IronTower = Value - Ctx.HandEV * 2,      -- ไม่มี Extra Life อีกเลย
            Pacifist = -1e6,                          -- ห้ามใช้ทุกอย่างรวมตี
            -- ผู้ใช้ 2026-10-01: เล่นไปเรื่อย ๆ ใช้ดาบไม่ได้ = Bare Hands (ชั้นถัดไปถอดอาวุธ ใช้หมัดเท่านั้น) / No Guard
            -- (กันไม่ได้ = Auto Dodge กันท่าพุ่งตามไม่ได้) - มือ Event มี Skip ให้เลือกแทนเสมอ
            BareHands = -1e6,
            NoGuard = -1e6,
            IronDiscipline = -Value * 0.5,            -- ใช้สกิลไม่ได้ ตีช้าลง
        }
        if Special[Name] ~= nil then Value = Value + Special[Name] end
        return Value - Risk * math.max(Floors, 1)
    end

    local function CardValue(Card, Ctx)
        local Type = Card:GetAttribute("Type")
        local Rarity = tonumber(Card:GetAttribute("Rarity")) or 1
        if Type == "Points" then
            return tonumber(Card:GetAttribute("Points")) or (TrophyKills[Rarity] or 5) * KillPoints
        elseif Type == "Fortune" then
            local Fixed = tonumber(Card:GetAttribute("Points"))
            return Fixed or math.min(Ctx.Points * 0.09, 25 * KillPoints)
        elseif Type == "ExtraLife" then
            return Ctx.HandEV * (Ctx.Hearts <= 1 and 8 or 5)
        elseif Type == "Revive" then
            return Ctx.Party and Ctx.HandEV * 4 or 0
        elseif Type == "Heal" then
            -- หัวใจเยอะ = เลือดหายไม่น่ากลัวเท่าหัวใจเหลือ 1 (ถ้วยใหญ่ยังคุ้มกว่า)
            local Missing = 1 - Ctx.Health
            local Danger = Ctx.Hearts <= 1 and 2 or (Ctx.Hearts == 2 and 1.4 or 1)
            return Ctx.HandEV * Missing * (Missing > 0.4 and Danger or 0.4)
        elseif Type == "Potion" then
            return Ctx.HandEV * 0.5
        elseif Type == "Reroll" then
            return (tonumber(Card:GetAttribute("Rerolls")) or 2) * Ctx.Ticket
        elseif Type == "Stat" then
            local Per = StatWorth[tostring(Card:GetAttribute("Stat"))] or 0.5
            return Ctx.HandEV * math.min((tonumber(Card:GetAttribute("Amount")) or 0) * Per, 2)
        elseif Type == "Forge" then
            return Ctx.Roguelike and Ctx.HandEV * 0.3 or 1500
        elseif Type == "Skill" or Type == "SkillSwap" or Type == "Clan" or Type == "AscendClan" then
            return Ctx.HandEV * 0.12 * Rarity
        elseif Type == "Weapon" or Type == "Trade" then
            return 0    -- เปลี่ยนอาวุธกลางรอบ = ฟาร์มถืออาวุธผิด
        elseif Type == "SwapMap" then
            return 1
        elseif Type == "SkipFloor" then
            return -Ctx.Kpf
        elseif Type == "Skip" then
            return 0
        elseif Type == "Event" then
            return EventValue(Card, Ctx)
        end
        return Rarity
    end

    -- ค่าเฉลี่ยของการ์ดที่ดีที่สุดในมือใหม่ (จำลองการแจกจริง: สุ่มชนิดไม่ซ้ำตามน้ำหนัก RewardHandSize ใบ)
    -- คิดเฉพาะการ์ดที่วัดเป็นแต้มได้ตรง ๆ (ถ้วย / Fortune / Extra Life / ตั๋ว) - รอบแรกใช้ HandEV ประมาณก่อน
    local function SimulateHand(Ctx, Samples)
        local Pool = DrawPool(Ctx.Floor, Ctx.Roguelike, Ctx.Party)
        local HandSize = tonumber(Settings.RewardHandSize) or 3
        local Total = 0
        for _ = 1, Samples do
            local Left = table.clone(Pool)
            local Best = 0
            for _ = 1, math.min(HandSize, #Left) do
                local Sum = 0
                for _, Entry in ipairs(Left) do Sum = Sum + Entry.W end
                local Roll, Index = math.random() * Sum, #Left
                for I, Entry in ipairs(Left) do
                    Roll = Roll - Entry.W
                    if Roll <= 0 then Index = I break end
                end
                local Name = table.remove(Left, Index).Name
                local Value = 0
                if Name == "Points" then Value = RollTrophy(Ctx.Floor)
                elseif Name == "Fortune" then Value = math.min(Ctx.Points * 0.09, 25 * KillPoints)
                elseif Name == "ExtraLife" then Value = Ctx.HandEV * (Ctx.Hearts <= 1 and 8 or 5)
                elseif Name == "Reroll" then Value = 2 * Ctx.Ticket
                elseif Name == "Forge" then Value = Ctx.Roguelike and Ctx.HandEV * 0.3 or 1500
                elseif Name == "Skill" or Name == "Clan" or Name == "SkillSwap" or Name == "AscendClan" then Value = Ctx.HandEV * 0.25
                end
                if Value > Best then Best = Value end
            end
            Total = Total + Best
        end
        return Total / math.max(Samples, 1)
    end

    local function Evaluate(Folder)
        local Ctx = Context()
        -- 2 รอบ: HandEV / ค่าตั๋ว ขึ้นกับกันและกัน
        Ctx.HandEV = SimulateHand(Ctx, 150)
        Ctx.Ticket = math.max(Ctx.HandEV * 0.25, 5)
        Ctx.HandEV = SimulateHand(Ctx, 250)
        Ctx.Ticket = math.max(Ctx.HandEV * 0.25, 5)

        local Cards = { }
        for _, Card in ipairs(Folder:GetChildren()) do
            if Card:GetAttribute("Type") and Card:GetAttribute("Picked") ~= true then
                table.insert(Cards, { Card = Card, Value = CardValue(Card, Ctx), Title = tostring(Card:GetAttribute("Title") or Card.Name) })
            end
        end
        table.sort(Cards, function(A, B) return A.Value > B.Value end)
        return Cards, Ctx
    end

    ---- หน้า UI ----

    local ClimbPage = Window:Page({ Name = "Tower Climb", Icon = "trending-up", Columns = 2 })
    local ClimbSection = ClimbPage:Section({
        Name = "Auto Climb",
        Description = "Ready up, clear every floor, pick the best cards",
        Icon = "80758916183665",
        Side = 1
    })
    local CardSection = ClimbPage:Section({
        Name = "Best Card",
        Description = "Card values from the game's own weights",
        Icon = "80758916183665",
        Side = 1
    })
    local ClimbSettings = ClimbPage:Section({
        Name = "Settings",
        Description = "Weapon, position and movement",
        Icon = "93142176757189",
        Side = 2
    })
    local ExchangePage = Window:Page({ Name = "Tower Exchange", Icon = "coins", Columns = 2 })
    local ExchangeSection = ExchangePage:Section({
        Name = "Changer Zeni",
        Description = "Trade tower points after a run",
        Icon = "80758916183665",
        Side = 1
    })

    local StatusCard = MakeStatusCard(ClimbSection, "Tower", { "State", "Floor", "Hearts", "Points" }, false, false)
    local CardLabel = CardSection:Label("-", true)

    local function Toggle(Section, Name, Key, Description)
        Section:Toggle({
            Name = Name,
            Description = Description,
            Flag = "SL2" .. Key,
            Default = Config[Key] == true,
            Callback = function(Value)
                Config[Key] = Value
                SaveConfiguration()
            end
        })
    end

    Toggle(ClimbSection, "Auto Climb", "OuwiAutoClimb", "Ready up in the lobby and clear floors until the hearts run out")
    Toggle(ClimbSection, "Instant Kill", "OuwiInstantKill", "Kill a tower enemy once your hit makes you its owner")
    ClimbSection:Slider({
        Name = "Instant Kill At Health",
        Flag = "SL2OuwiInstantKillHealth",
        Min = 1,
        Max = 90,
        Default = math.min(tonumber(Config.OuwiInstantKillHealth) or 90, 90),
        Suffix = "%",
        Callback = function(Value)
            Config.OuwiInstantKillHealth = math.min(Value, 90)
            SaveConfiguration()
        end
    })
    Toggle(ClimbSection, "Skip Wave Break", "OuwiSkipBreak", "Vote to skip the 10s break between floors")

    Toggle(CardSection, "Auto Best Card", "OuwiBestCard", "Pick the card worth the most tower points")
    Toggle(CardSection, "Auto Reroll", "OuwiAutoReroll", "Spend a ticket when a fresh hand is worth more")
    CardSection:Slider({
        Name = "Keep Reroll Tickets",
        Flag = "SL2OuwiRerollKeep",
        Min = 0,
        Max = 10,
        Default = tonumber(Config.OuwiRerollKeep) or 0,
        Callback = function(Value)
            Config.OuwiRerollKeep = Value
            SaveConfiguration()
        end
    })
    Toggle(CardSection, "Safe Events", "OuwiSafeEvents", "On your last heart, skip events that make you easy to kill")

    -- อาวุธในหอมาจากการ์ดกลางรอบ = ลงทะเบียนให้ลิสต์รีเฟรชตาม Toolbar เหมือนแท็บอื่น
    if Farm.BuildSettingsSection then
        local Ok, OuwiWeaponDropdown = pcall(Farm.BuildSettingsSection, ClimbSettings, "Ouwi")
        if Ok and OuwiWeaponDropdown and Farm.WeaponDropdowns then
            table.insert(Farm.WeaponDropdowns, { Dropdown = OuwiWeaponDropdown, Key = "FarmWeaponOuwi" })
        end
    end

    local ShopItems = { "Refinement Ore", "Mythic Refinement Ore", "1,000 Wen" }
    Toggle(ExchangeSection, "Auto Exchange", "OuwiAutoExchange", "After a run, buy the item below with tower points until you can't")
    ExchangeSection:Dropdown({
        Name = "Item",
        Flag = "SL2OuwiExchangeItem",
        Items = ShopItems,
        Default = table.find(ShopItems, Config.OuwiExchangeItem) and Config.OuwiExchangeItem or ShopItems[1],
        Multi = false,
        Seperator = false,
        Callback = function(Value)
            if type(Value) ~= "string" then return end
            Config.OuwiExchangeItem = Value
            SaveConfiguration()
        end
    })
    Toggle(ExchangeSection, "Auto Leave", "OuwiAutoLeave", "After exchanging, step on the Leave pad to go back")
    local ExchangeLabel = ExchangeSection:Label("-", true)

    ---- ตัวเล่นในหอ ----

    local function Running()
        return getgenv().ValkyrieSession == SessionToken and InTower() and Config.OuwiAutoClimb == true
    end

    local function SetStatus(State)
        Ouwi.Status = State
        pcall(function()
            StatusCard:Set("State", State)
            StatusCard:Set("Floor", "Floor " .. tostring(workspace:GetAttribute("MinigameFloor") or "-"))
            StatusCard:Set("Hearts", tostring(Attr("Hearts") or "-") .. " hearts")
            StatusCard:Set("Points", tostring(Attr("RunPoints") or 0) .. " pts")
        end)
    end

    -- เลือก/ reroll การ์ด: มือละ 1 การกระทำ แล้วรอเซิร์ฟเปลี่ยนมือ (ไม่ยิงซ้ำ)
    local function HandleOffers(Folder)
        task.wait(0.6)      -- ให้ attribute ของการ์ดมาครบ
        if not Folder.Parent then return end
        local Cards, Ctx = Evaluate(Folder)
        local Lines = { }
        for Index, Entry in ipairs(Cards) do
            table.insert(Lines, string.format("%s %s = %d", Index == 1 and ">" or " ", Entry.Title, math.floor(Entry.Value)))
        end
        table.insert(Lines, string.format("fresh hand ~%d  ·  tickets %d", math.floor(Ctx.HandEV), Ctx.Rerolls))
        Ouwi.Card = table.concat(Lines, "\n")
        pcall(function() CardLabel:SetText(Ouwi.Card) end)

        if not (Config.OuwiBestCard and Running()) or #Cards == 0 then return end

        -- มือรางวัล (ไม่ใช่มือ event) แย่กว่ามือใหม่ที่คาดไว้ชัด ๆ = ใช้ตั๋ว
        local EventHand = false
        for _, Entry in ipairs(Cards) do
            local Type = Entry.Card:GetAttribute("Type")
            if Type == "Event" or Type == "Skip" then EventHand = true end
        end
        if Config.OuwiAutoReroll and not EventHand and Ctx.Rerolls > (tonumber(Config.OuwiRerollKeep) or 0)
            and Cards[1].Value < Ctx.HandEV * 0.8 then
            SetStatus("Reroll (best " .. math.floor(Cards[1].Value) .. " < fresh " .. math.floor(Ctx.HandEV) .. ")")
            pcall(function() SignalEvent.ToServer("OuwigaharaRequest", { action = "Reroll" }) end)
            return
        end

        SetStatus("Pick " .. Cards[1].Title)
        pcall(function() SignalEvent.ToServer("OuwigaharaRequest", { action = "Pick", id = Cards[1].Card.Name }) end)
    end

    task.spawn(function()
        local Handled = { }
        while getgenv().ValkyrieSession == SessionToken do
            local Folder = InTower() and LocalPlayer:FindFirstChild("OuwigaharaOffers")
            if Folder then
                -- มือเดิมแต่การ์ดเปลี่ยน (reroll / milestone หยิบได้หลายใบ) = ประเมินใหม่
                local Key = { }
                for _, Card in ipairs(Folder:GetChildren()) do
                    table.insert(Key, Card.Name .. ":" .. tostring(Card:GetAttribute("Title")) .. ":" .. tostring(Card:GetAttribute("Picked")))
                end
                table.sort(Key)
                local Signature = table.concat(Key, "|")
                if Handled[Folder] ~= Signature and #Key > 0 then
                    Handled[Folder] = Signature
                    local Ok, Error = pcall(HandleOffers, Folder)
                    if not Ok then warn("[Valkyrie Ouwigahara] cards: " .. tostring(Error)) end
                    task.wait(1)
                end
            end
            task.wait(0.2)
        end
    end)

    -- คะแนนจากการตีต่อชั้น (ใช้คิดค่า event คูณแต้ม) - วัดจาก RunPoints ตั้งแต่เริ่มชั้นจนมือการ์ดขึ้น
    local function TrackFloorPoints()
        local Floor = workspace:GetAttribute("MinigameFloor")
        if Floor ~= Ouwi.FloorSeen then
            Ouwi.FloorSeen = Floor
            Ouwi.FloorStartPoints = tonumber(Attr("RunPoints")) or 0
        elseif Ouwi.FloorStartPoints and LocalPlayer:FindFirstChild("OuwigaharaOffers") then
            local Gained = (tonumber(Attr("RunPoints")) or 0) - Ouwi.FloorStartPoints
            if Gained > 0 then Ouwi.Kpf = Ouwi.Kpf * 0.7 + Gained * 0.3 end
            Ouwi.FloorStartPoints = nil
        end
    end

    local function NearestEnemy(Root)
        local Best, BestDistance = nil, math.huge
        for _, Entry in ipairs(Farm.IterMobs()) do
            if Farm.IsMobAlive(Entry) then
                local Distance = (Entry.Root.Position - Root.Position).Magnitude
                if Distance < BestDistance then Best, BestDistance = Entry, Distance end
            end
        end
        return Best
    end

    local function InstantKillReady(Mob)
        if not Config.OuwiInstantKill then return false end
        local Humanoid = Mob and Mob.Humanoid
        if not (Humanoid and Humanoid.MaxHealth > 0) then return false end
        local Limit = math.min(tonumber(Config.OuwiInstantKillHealth) or 90, 90)
        return Humanoid.Health / Humanoid.MaxHealth * 100 <= Limit
    end

    local function ReadyUp()
        local Pad = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Minigame Map")
        Pad = Pad and Pad:FindFirstChild("StartPad")
        local Prompt = Pad and Pad:FindFirstChild("ReadyUp")
        if not (Pad and Prompt and Prompt.Enabled) then return end
        Movement.Go(CFrame.new(Pad.Position + Vector3.new(0, 4, 3)), 6, 20, Running)
        task.wait(0.4)
        if not Prompts.Use(Prompt, { Check = function() return Attr("Readied") == true end }) then
            pcall(fireproximityprompt, Prompt)
        end
        Farm.WaitFor(function() return Attr("Readied") == true end, 3, Running)
    end

    -- ราคาแต้มหอของของที่ Changer Zeni ขาย (Content.Ouwigahara.Npcs[*].Shop[ชื่อ].Price.RunPoints)
    local ZeniShop = nil
    local function ZeniPrice(Item)
        if not ZeniShop then
            local Content = Require(function() return ReplicatedStorage["Minigames Place"].Content.Ouwigahara end)
            for _, Npc in pairs(Content and Content.Npcs or { }) do
                if type(Npc) == "table" and Npc.Name == "Changer Zeni" then ZeniShop = Npc.Shop end
            end
        end
        local Entry = ZeniShop and ZeniShop[Item]
        return Entry and Entry.Price and tonumber(Entry.Price.RunPoints) or nil
    end

    -- จบรอบ: แลกแต้มที่ Changer Zeni แล้ว (ถ้าเปิด) เดินเข้า LeavePad
    local Exchanged = false
    local function ShopStep()
        if Config.OuwiAutoExchange and not Exchanged then
            local Zeni = nil
            pcall(function()
                local Region = workspace.Debree.Regions.Ouwigahara.StationaryNpcs
                Zeni = Region:FindFirstChild("Changer Zeni")
            end)
            local At = Zeni and Zeni:GetPivot().Position or Vector3.new(-2290.3, 1141.7, -2634.8)
            Movement.Go(CFrame.new(At + Vector3.new(4, 2, 0), At), 6, 20, Running)
            task.wait(0.6)
            -- แต้มที่ใช้ซื้อ = RunPoints ของรอบที่เพิ่งจบ (Shop.Cashiers.RunPoints อ่าน Score ของหอ) ราคาจาก
            -- Content.Ouwigahara.Npcs (Changer Zeni) - ซื้อทีเดียวทั้งตะกร้า { [ชื่อ] = จำนวน } แบบปุ่ม "Buy the selection"
            local Item = Config.OuwiExchangeItem
            local Price = ZeniPrice(Item)
            local Points = tonumber(Attr("RunPoints")) or 0
            local Count = Price and math.floor(Points / Price) or 0
            local Bought = 0
            if Count > 0 then
                local Before = Points
                pcall(function() SignalFunction.ToServer("PurchaseSelection", { [Item] = math.min(Count, 99) }) end)
                Farm.WaitFor(function() return (tonumber(Attr("RunPoints")) or 0) < Before end, 4, Running)
                Bought = math.floor((Before - (tonumber(Attr("RunPoints")) or 0)) / Price + 0.5)
            end
            Exchanged = true
            pcall(function() ExchangeLabel:SetText(string.format("Last run: bought %d x %s", Bought, Item)) end)
        end

        if Config.OuwiAutoLeave then
            local Pad = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Shops")
            Pad = Pad and Pad:FindFirstChild("LeavePad", true)
            local Prompt = Pad and Pad:FindFirstChildWhichIsA("ProximityPrompt", true)
            if Pad and Prompt then
                SetStatus("Leaving")
                Movement.Go(CFrame.new(Pad.Position + Vector3.new(0, 4, 0)), 6, 20, Running)
                task.wait(0.4)
                if not Prompts.Use(Prompt) then pcall(fireproximityprompt, Prompt) end
                Farm.Sleep(5, Running)
            end
        end
    end

    task.spawn(function()
        local OwnContinue = function() return Running() and workspace:GetAttribute("MinigameState") == "Climbing" end
        while getgenv().ValkyrieSession == SessionToken do
            if Running() then
                local State = workspace:GetAttribute("MinigameState")
                TrackFloorPoints()

                -- จบรอบแล้วอยู่ร้าน (InShops) = แลกของก่อน ห้าม Ready Up (วัดสด 2026-10-01: หัวใจหมด -> MinigameState
                -- กลับเป็น Lobby ทันทีขณะที่ตัวยังอยู่ร้าน แต้มรอบเก่ายังไม่ได้ใช้)
                if Attr("InShops") or State == "Ended" then
                    if Fighter.Continue == OwnContinue then Fighter.Continue = nil end
                    SetStatus("Run over - shops")
                    ShopStep()
                    task.wait(1)
                elseif State == "Lobby" or State == "Starting" then
                    Exchanged = false
                    SetStatus(Attr("Readied") and "Ready - waiting for the climb" or "Ready up")
                    if not Attr("Readied") then ReadyUp() end
                    task.wait(0.5)
                elseif State == "Climbing" and not Attr("Spectating") and not Attr("InShops") then
                    getgenv().ValkyrieFarmSuffix = "Ouwi"
                    Fighter.Continue = OwnContinue

                    -- พักระหว่างชั้น: โหวตข้ามครั้งเดียวต่อช่วงพัก
                    local Break = workspace:GetAttribute("MinigameWaveBreak")
                    if Config.OuwiSkipBreak and workspace:GetAttribute("MinigameSkipNeeded") and Break and Ouwi.Voted ~= Break then
                        Ouwi.Voted = Break
                        pcall(function() SignalEvent.ToServer("OuwigaharaRequest", { action = "Skip" }) end)
                    end

                    local Root = Movement.GetRoot()
                    local Mob = Root and NearestEnemy(Root)
                    if Mob then
                        SetStatus("Fighting " .. Mob.Model.Name)
                        -- ตีตัวนี้จนตาย (เลือกใหม่เมื่อตาย / หลุด)
                        while OwnContinue() and Farm.IsMobAlive(Mob) do
                            local Here = Movement.GetRoot()
                            if not Here then break end
                            Fighter.FightMob(Mob, Here)
                            if InstantKillReady(Mob) then Farm.TryInstantKill(Mob) end
                            task.wait()
                        end
                    else
                        Fighter.AttackTarget = nil
                        Movement.Lock(nil)
                        SetStatus(LocalPlayer:FindFirstChild("OuwigaharaOffers") and "Choosing a card" or "Waiting for the next wave")
                        task.wait(0.2)
                    end
                else
                    SetStatus(Attr("Spectating") and "Out of hearts - spectating" or tostring(State or "-"))
                    task.wait(0.5)
                end
            else
                if Fighter.Continue == OwnContinue then
                    Fighter.Continue = nil
                    Fighter.AttackTarget = nil
                    Movement.Lock(nil)
                end
                if InTower() then SetStatus(Config.OuwiAutoClimb and "-" or "Off") end
                task.wait(0.5)
            end
        end
    end)
end

Window:Category("Players")

local PlayersPage = Window:Page({ Name = "Players", Icon = "users", Columns = 2 })

local LocalPlayerSection = PlayersPage:Section({
    Name = "Player Modify",
    Description = "Dash, stamina, stun and sun",
    Icon = "80758916183665",
    Side = 1
})

local MovementSection = PlayersPage:Section({
    Name = "Movement",
    Description = "Speed, jump and collision",
    Icon = "80758916183665",
    Side = 2
})

local TeleportSection = PlayersPage:Section({
    Name = "Teleport",
    Description = "Teleport to players",
    Icon = "93142176757189",
    Side = 1
})

-- Auto Use Skill ยาวสุดในหน้า (10 ตัว) แยกเป็นหน้าของตัวเอง - เวลากดค้างต่อคีย์ไปกล่องขวา
local SkillPage = Window:Page({ Name = "Auto Skill", Icon = "target", Columns = 2 })

local SkillSection = SkillPage:Section({
    Name = "Auto Use Skill",
    Description = "Use skills on the active farm target only",
    Icon = "93142176757189",
    Side = 1
})

local SkillHoldSection = SkillPage:Section({
    Name = "Hold Timing",
    Description = "How long each key is held",
    Icon = "80758916183665",
    Side = 2
})

do
    local Config = getgenv().ConfigurationTable

    -- เกมรีเซ็ต Humanoid.WalkSpeed กลับทันทีที่เราตั้ง (ระบบวิ่งของเกม - ยืนยันสดผ่าน dex_exec)
    -- เลยต้องบังคับค่าทุกเฟรมบน Heartbeat แทนตั้งครั้งเดียว ปิดแล้วเกมคืนค่าเดิมให้เอง
    -- JumpPower ใช้วิธีเดียวกัน (UseJumpPower = true ในเกมนี้) แต่ต้องคืนค่าเดิมเองตอนปิด
    local DefaultJumpPower = nil

    TrackConnection(RunService.Heartbeat:Connect(function()
        if getgenv().ValkyrieSession ~= SessionToken then return end

        local Humanoid = Movement.GetHumanoid()
        if not Humanoid or Humanoid.Health <= 0 then return end

        if Config.WalkSpeedEnabled then
            Humanoid.WalkSpeed = tonumber(Config.WalkSpeed) or 60
        end

        if Config.JumpPowerEnabled then
            DefaultJumpPower = DefaultJumpPower or Humanoid.JumpPower
            Humanoid.UseJumpPower = true
            Humanoid.JumpPower = tonumber(Config.JumpPower) or 80
        elseif DefaultJumpPower then
            Humanoid.JumpPower = DefaultJumpPower
            DefaultJumpPower = nil
        end
    end))

    -- Noclip: ปิดการชนทุกชิ้นของตัวละครทุก Stepped (ก่อน physics) จำไว้ว่าปิดชิ้นไหนไปบ้าง
    -- ปิด toggle แล้วคืนเฉพาะชิ้นที่เราปิดเอง ไม่ยุ่งกับชิ้นที่เกมตั้ง CanCollide = false อยู่แล้ว
    local NoclipMemory = { }

    local function RestoreNoclip()
        for Part in pairs(NoclipMemory) do
            if Part.Parent then
                pcall(function() Part.CanCollide = true end)
            end
        end
        table.clear(NoclipMemory)
    end

    TrackConnection(RunService.Stepped:Connect(function()
        if not Config.Noclip or getgenv().ValkyrieSession ~= SessionToken then return end

        local Character = Movement.GetCharacter()
        if not Character then return end

        for _, Part in ipairs(Character:GetDescendants()) do
            if Part:IsA("BasePart") and Part.CanCollide then
                NoclipMemory[Part] = true
                Part.CanCollide = false
            end
        end
    end))

    TrackConnection(game:GetService("UserInputService").JumpRequest:Connect(function()
        if not Config.InfiniteJump or getgenv().ValkyrieSession ~= SessionToken then return end

        local Humanoid = Movement.GetHumanoid()
        if Humanoid and Humanoid.Health > 0 then
            Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end))

    local function SetFlag(Key)
        return function(Value)
            Config[Key] = Value
            SaveConfiguration()
        end
    end

    MovementSection:Toggle({
        Name = "Walk Speed",
        Flag = "SL2WalkSpeedEnabled",
        Default = Config.WalkSpeedEnabled,
        Callback = SetFlag("WalkSpeedEnabled")
    })

    MovementSection:Slider({
        Name = "Speed",
        Flag = "SL2WalkSpeed",
        Min = 16,
        Max = 40,
        Default = Config.WalkSpeed,
        Callback = SetFlag("WalkSpeed")
    })

    MovementSection:Toggle({
        Name = "Jump Power",
        Flag = "SL2JumpPowerEnabled",
        Default = Config.JumpPowerEnabled,
        Callback = SetFlag("JumpPowerEnabled")
    })

    MovementSection:Slider({
        Name = "Power",
        Flag = "SL2JumpPower",
        Min = 50,
        Max = 300,
        Default = Config.JumpPower,
        Callback = SetFlag("JumpPower")
    })

    MovementSection:Toggle({
        Name = "Infinite Jump",
        Flag = "SL2InfiniteJump",
        Default = Config.InfiniteJump,
        Callback = SetFlag("InfiniteJump")
    })

    MovementSection:Toggle({
        Name = "Noclip",
        Flag = "SL2Noclip",
        Default = Config.Noclip,
        Callback = function(Value)
            Config.Noclip = Value
            SaveConfiguration()
            if not Value then RestoreNoclip() end
        end
    })

    ---- Dash / Run / Climb / Knockback / Stun ----
    --
    -- ทุกอย่างอ่านจากโค้ดเกมจริง (dex_decompile):
    --   Dash  : Skills_Module.Can_Skill เช็ค cooldown = NumberValue ชื่อ "Dash" ใต้ Character.SHC
    --           (manage_cd.set_skill_cd สร้าง) แรงพุ่งเป็น LinearVelocity ฝั่ง client เอง (Skills.Misc.Dashes.Dash)
    --           แดชยังกิน Stamina 10 ต่อครั้ง - เปิด Infinite Stamina คู่กันถึงจะแดชรัวได้ไม่หมด
    --   Stamina: Player_Service.Values.<ชื่อ>.Stamina (IntConstrainedValue) Can_Skill เช็คฝั่ง client เติมเต็มทุกเฟรม
    --   Sun   : StarterGui.UCS.Game_Play.SunDamage (LocalScript) raycast หาแดดเองแล้วบอกเซิร์ฟ
    --           SignalFunction.ToServer("SunDamage", true/false) = Function:InvokeServer("SunDamage", bool)
    --           เซิร์ฟเชื่อค่าที่ client ส่ง - ดักแก้ true -> false ก่อนออก
    --   Run   : Run_Handler.Toggled = true คือปุ่มวิ่งค้างของมือถือ ใช้บน PC ได้ด้วย (ยืนยันสด ws 17 -> 26.8)
    --   Climb : สคริปต์ Character Scripts.Climbing เก็บแรงปีนใน local { CurrentStamina, MaxClimbTime = 7 }
    --           หาเจอผ่าน getgc แล้วเติมเต็มทุกเฟรม
    --   Knockback: แรงกระเด็นเป็นของชื่อ "combat_knockback" / "air_combo_bp" ใต้ HumanoidRootPart (ตัว Dash เกมก็ลบแบบนี้)
    --   Stun  : Checker.check บล็อกทุกท่าถ้า Values folder มี Stun / CombatStun / Strict_Stun
    local Utility = require(ReplicatedStorage.CAM.Global.Utility)
    local RunHandler = nil
    pcall(function()
        RunHandler = require(ReplicatedStorage.CAM.Client.Modules.GamePlay.Run_Handler)
    end)

    local DashCooldownName = "Dash"
    pcall(function()
        local Info = require(ReplicatedStorage.CAM.Global.PlayerProfile).skill_info.Dash
        DashCooldownName = Info.CoolDownName or "Dash"
    end)

    local StunNames = { Stun = true, CombatStun = true, Strict_Stun = true }

    -- ยืนยันสดจากโดน Bandit ตีจริง: combat_knockback = Attachment + LinearVelocity (ผลักกระเด็น)
    -- air_combo_bp = Attachment + AlignPosition (ยกตัวลอยขึ้นโดนคอมโบกลางอากาศ)
    local KnockbackNames = { combat_knockback = true, air_combo_bp = true }

    local function GetValuesFolder()
        local Ok, Folder = pcall(Utility.getvaluesfolder, LocalPlayer)
        return Ok and Folder or nil
    end

    -- ตาราง climb stamina เป็น local ของสคริปต์ตัวละคร - เกิดใหม่ทุกครั้งที่ตัวละครเกิด ต้องหาใหม่
    local ClimbTables = setmetatable({ }, { __mode = "k" })

    local function ScanClimbTables()
        if type(getgc) ~= "function" then return end
        local Ok, Objects = pcall(getgc, true)
        if not Ok then return end

        for _, Object in ipairs(Objects) do
            if type(Object) == "table" and rawget(Object, "CurrentStamina") ~= nil
                and rawget(Object, "MaxClimbTime") ~= nil then
                ClimbTables[Object] = true
            end
        end
    end

    local RunWasForced = false

    TrackConnection(RunService.Heartbeat:Connect(function()
        if getgenv().ValkyrieSession ~= SessionToken then return end

        if Config.InfiniteStamina then
            local Values = GetValuesFolder()
            local Stamina = Values and Values:FindFirstChild("Stamina")
            if Stamina and Stamina.Value < Stamina.MaxValue then
                Stamina.Value = Stamina.MaxValue
            end
        end

        if Config.InfiniteDash then
            local Character = Movement.GetCharacter()
            local SHC = Character and Character:FindFirstChild("SHC")
            local Cooldown = SHC and SHC:FindFirstChild(DashCooldownName)
            if Cooldown then Cooldown:Destroy() end
        end

        if RunHandler then
            if Config.AlwaysRun then
                RunHandler.Toggled = true
                RunWasForced = true
            elseif RunWasForced then
                RunHandler.Toggled = false
                RunWasForced = false
            end
        end

        if Config.InfiniteClimb then
            for Climb in pairs(ClimbTables) do
                local Max = rawget(Climb, "MaxClimbTime")
                if type(Max) == "number" then
                    Climb.CurrentStamina = Max
                end
            end
        end

        if Config.AntiStun then
            local Values = GetValuesFolder()
            if Values then
                for Name in pairs(StunNames) do
                    local Stun = Values:FindFirstChild(Name)
                    if Stun then pcall(Stun.Destroy, Stun) end
                end
            end
        end

        if Config.AntiKnockback then
            local Root = Movement.GetRoot()
            if Root then
                for _, Child in ipairs(Root:GetChildren()) do
                    if KnockbackNames[Child.Name] then
                        pcall(Child.Destroy, Child)
                    end
                end
            end
        end
    end))

    -- ลบทันทีที่โผล่ (ChildAdded) ก่อน physics step ถัดไป - Heartbeat ด้านบนเป็นแค่ตัวกวาดสำรอง
    -- ต้องผูกใหม่ทุกครั้งที่ตัวละครเกิดใหม่ (HumanoidRootPart ตัวใหม่)
    local KnockbackConnection = nil

    local function WatchKnockback(Character)
        if KnockbackConnection then
            pcall(function() KnockbackConnection:Disconnect() end)
            KnockbackConnection = nil
        end

        local Root = Character and Character:WaitForChild("HumanoidRootPart", 10)
        if not Root then return end

        -- Destroy ใน ChildAdded ตรง ๆ ไม่ได้ (Parent ยังล็อกอยู่) ต้อง defer - แต่ defer ช้าไป 1 physics step
        -- (วัดสด: ยังโดนผลัก 22 studs) เลยปิดแรงทันทีด้วย Enabled = false / MaxForce = 0 ก่อน แล้วค่อยลบ
        local function Neutralize(Object)
            if Object:IsA("Constraint") then
                Object.Enabled = false
                if Object:IsA("LinearVelocity") then
                    Object.MaxForce = 0
                    Object.VectorVelocity = Vector3.zero
                    Object.LineVelocity = 0
                end
            elseif Object:IsA("BodyMover") then
                Object.Parent = nil
            end
        end

        KnockbackConnection = TrackConnection(Root.ChildAdded:Connect(function(Child)
            if not (Config.AntiKnockback and KnockbackNames[Child.Name]) then return end

            for _, Object in ipairs(Child:GetDescendants()) do
                pcall(Neutralize, Object)
            end
            Child.DescendantAdded:Connect(function(Object)
                pcall(Neutralize, Object)
            end)

            task.defer(pcall, Child.Destroy, Child)
            Root.AssemblyLinearVelocity = Vector3.zero
        end))
    end

    task.spawn(WatchKnockback, LocalPlayer.Character)
    TrackConnection(LocalPlayer.CharacterAdded:Connect(WatchKnockback))

    TrackConnection(LocalPlayer.CharacterAdded:Connect(function()
        task.wait(2)
        if Config.InfiniteClimb and getgenv().ValkyrieSession == SessionToken then
            ScanClimbTables()
        end
    end))

    LocalPlayerSection:Toggle({
        Name = "Infinite Dash",
        Flag = "SL2InfiniteDash",
        Default = Config.InfiniteDash,
        Callback = SetFlag("InfiniteDash")
    })

    LocalPlayerSection:Toggle({
        Name = "Infinite Stamina",
        Flag = "SL2InfiniteStamina",
        Default = Config.InfiniteStamina,
        Callback = SetFlag("InfiniteStamina")
    })

    LocalPlayerSection:Toggle({
        Name = "Always Run",
        Flag = "SL2AlwaysRun",
        Default = Config.AlwaysRun,
        Callback = SetFlag("AlwaysRun")
    })

    LocalPlayerSection:Toggle({
        Name = "Infinite Climb",
        Flag = "SL2InfiniteClimb",
        Default = Config.InfiniteClimb,
        Callback = function(Value)
            Config.InfiniteClimb = Value
            SaveConfiguration()
            if Value then task.spawn(ScanClimbTables) end
        end
    })

    LocalPlayerSection:Toggle({
        Name = "Anti Knockback",
        Flag = "SL2AntiKnockback",
        Default = Config.AntiKnockback,
        Callback = SetFlag("AntiKnockback")
    })

    LocalPlayerSection:Toggle({
        Name = "Anti Stun",
        Flag = "SL2AntiStun",
        Default = Config.AntiStun,
        Callback = SetFlag("AntiStun")
    })

    local SunRemote = nil
    pcall(function()
        SunRemote = ReplicatedStorage.Communication.ServerAndClient.Signals.SignalFunction.Function
    end)

    local function SunBlocked(Self, Name)
        local Current = getgenv().ConfigurationTable
        return Self == getgenv().ValkyrieSunRemote and Name == "SunDamage"
            and type(Current) == "table" and Current.NoSunDamage == true
    end

    if SunRemote and not getgenv().ValkyrieSunHooked then
        getgenv().ValkyrieSunRemote = SunRemote

        pcall(function()
            local OldNamecall
            OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(Self, ...)
                if getnamecallmethod() == "InvokeServer" then
                    local Name = ...
                    if SunBlocked(Self, Name) then
                        return OldNamecall(Self, "SunDamage", false)
                    end
                end
                return OldNamecall(Self, ...)
            end))
        end)

        pcall(function()
            local OldInvoke
            OldInvoke = hookfunction(SunRemote.InvokeServer, newcclosure(function(Self, ...)
                local Name = ...
                if SunBlocked(Self, Name) then
                    return OldInvoke(Self, "SunDamage", false)
                end
                return OldInvoke(Self, ...)
            end))
        end)

        getgenv().ValkyrieSunHooked = true
    end

    LocalPlayerSection:Toggle({
        Name = "No Sun Damage",
        Flag = "SL2NoSunDamage",
        Default = Config.NoSunDamage,
        Callback = function(Value)
            Config.NoSunDamage = Value
            SaveConfiguration()

            -- สคริปต์เกมส่งแค่ตอนสถานะเปลี่ยน - ถ้ากำลังโดนแดดอยู่ตอนเปิด ต้องบอกเซิร์ฟเองว่าไม่โดนแล้ว
            if Value and SunRemote then
                task.spawn(pcall, SunRemote.InvokeServer, SunRemote, "SunDamage", false)
            end
        end
    })

    if Config.InfiniteClimb then task.spawn(ScanClimbTables) end

    ---- Teleport ----

    local SelectedPlayer = nil

    -- StreamingEnabled: ชิ้นส่วนตัวละครที่อยู่ไกลหลุดโหลด (ไม่มี HumanoidRootPart) แต่โมเดลเปลือก
    -- workspace.Humanoids.<ชื่อ> ยังอยู่ และ pivot ยังอัปเดตตามตัวจริง (วัดสด: ขยับ 34 studs ใน 3 วิ
    -- ทั้งที่ไม่มี HRP) - อ่านตำแหน่งจาก GetPivot() แทน ลิสต์โชว์แค่คนที่มีโมเดลนี้ (วาร์ปไปได้จริง)
    local function PlayerModel(Player)
        local Folder = workspace:FindFirstChild("Humanoids")
        local Model = Folder and Folder:FindFirstChild(Player.Name)
        return (Model and Model:IsA("Model")) and Model or nil
    end

    local function PlayerPivot(Player)
        local Model = PlayerModel(Player)
        if not Model then return nil end
        local Ok, Pivot = pcall(Model.GetPivot, Model)
        return Ok and Pivot or nil
    end

    local function GetPlayerNames()
        local Names = { }
        for _, Player in ipairs(Players:GetPlayers()) do
            if Player ~= LocalPlayer and PlayerModel(Player) then
                table.insert(Names, Player.Name)
            end
        end
        table.sort(Names)
        if #Names == 0 then Names = { "None" } end
        return Names
    end

    local function GetSelected()
        return SelectedPlayer and Players:FindFirstChild(SelectedPlayer)
    end

    local InitialNames = GetPlayerNames()
    SelectedPlayer = InitialNames[1] ~= "None" and InitialNames[1] or nil

    task.wait()

    local PlayerDropdown = TeleportSection:Dropdown({
        Name = "Select Player",
        Flag = "SL2SelectPlayer",
        Items = InitialNames,
        Default = InitialNames[1],
        Multi = false,
        Callback = function(Value)
            if type(Value) ~= "string" or Value == "None" then
                SelectedPlayer = nil
                return
            end

            SelectedPlayer = Value
        end
    })

    task.wait()

    -- คนเข้า/ออกเซิร์ฟ = รีเฟรชลิสต์เอง คนที่เลือกไว้ออกไป = ล้างที่เลือก
    local function RefreshPlayers()
        task.defer(function()
            if getgenv().ValkyrieSession ~= SessionToken then return end

            local Names = GetPlayerNames()
            if SelectedPlayer and not table.find(Names, SelectedPlayer) then
                SelectedPlayer = nil
            end

            task.wait()
            pcall(function()
                PlayerDropdown:Refresh(Names, SelectedPlayer)
            end)
        end)
    end

    TrackConnection(Players.PlayerAdded:Connect(RefreshPlayers))
    TrackConnection(Players.PlayerRemoving:Connect(RefreshPlayers))

    -- ตัวละครเกิด/หาย (ตาย, เข้าออกเซิร์ฟ) ไม่มี event เดียวให้ฟัง - เช็คทุก 2 วิ รายชื่อเปลี่ยนค่อยรีเฟรช dropdown
    task.spawn(function()
        local Last = ""
        while getgenv().ValkyrieSession == SessionToken do
            task.wait()
            local Key = table.concat(GetPlayerNames(), "|")
            if Key ~= Last then
                Last = Key
                RefreshPlayers()
            end
        end
    end)

    TeleportSection:Button({
        Name = "Teleport to Player",
        Callback = function()
            local Target = GetSelected()
            if not Target then
                Library:Notify("Teleport", "Select a player first", 3)
                return
            end

            local Pivot = PlayerPivot(Target)
            if not Pivot then
                Library:Notify("Teleport", Target.Name .. " has no character right now", 4)
                return
            end

            -- วาร์ปแล้วตรึงไว้ให้เซิร์ฟยอมก่อน (ปล่อยทันที = anti-cheat ดึงกลับ) - ปุ่มกดอยู่ thread UI เลยแยก spawn
            task.spawn(Movement.Go, Pivot * CFrame.new(0, 0, 3))
        end
    })

    PlayersCleanup = function()
        RestoreNoclip()
        if RunWasForced and RunHandler then RunHandler.Toggled = false end
    end
end

--// Auto Use Skill (UI) - ตัวยิงจริงอยู่ SkillEngine ด้านบน
do
    local Config = getgenv().ConfigurationTable

    local SlotKeys, Selected = SkillEngine.SlotKeys, SkillEngine.Selected

    if SlotKeys then
        -- การ์ดวิธีใช้ บนสุดของ section (ข้อความนิ่ง ไม่มีสถานะ)
        SkillSection:Guide("How to use", {
            "Skill Keys: pick the keys to use (Z X C V B)",
            "Turn on Auto Use Skill: skills fire only at the mob/boss your running farm is attacking",
            "Smart Weapon Swap: when every skill of the held weapon is on cooldown, borrow the next toolbar weapon that has a ready skill. M1 always uses your Select Weapon",
            "Enemy Range: cast only when the target is within this distance",
            "Hold sliders: seconds to hold each key (0 is the skill's own timing)",
        })

        task.wait()

        local KeyLabels = SlotKeys()

        local Saved = { }
        for _, Label in ipairs(Selected()) do
            if type(Label) == "string" and table.find(KeyLabels, Label) then
                table.insert(Saved, Label)
            end
        end

        -- ลิสต์คีย์คงที่ตลอด (ไม่ขึ้นกับอาวุธที่ถือ) เลยสร้างครั้งเดียวจบ ไม่ต้องมีลูปรีเฟรชแบบเดิม
        SkillSection:Dropdown({
            Name = "Skill Keys",
            Flag = "SL2AutoUseSkillKeys",
            Items = KeyLabels,
            KeepOrder = true,
            Default = Saved,
            Multi = true,
            Callback = function(Value)
                if type(Value) ~= "table" then return end

                Config.AutoUseSkillKeys = Value
                SaveConfiguration()
            end
        })

        task.wait()

        SkillSection:Toggle({
            Name = "Auto Use Skill",
            Flag = "SL2AutoUseSkill",
            Default = Config.AutoUseSkill,
            Callback = function(Value)
                Config.AutoUseSkill = Value
                SaveConfiguration()
                if not Value then getgenv().ValkyrieAimPoint = nil end
            end
        })

        SkillSection:Toggle({
            Name = "Smart Weapon Swap",
            Description = "When skills are on cooldown, it borrows the next toolbar weapon with a ready skill; M1 always uses Select Weapon",
            Flag = "SL2SmartWeapon",
            Default = Config.SmartWeapon,
            Callback = function(Value)
                Config.SmartWeapon = Value
                SaveConfiguration()
            end
        })

        SkillSection:Slider({
            Name = "Enemy Range",
            Flag = "SL2SkillRange",
            Min = 0,
            Max = 200,
            Default = Config.SkillRange,
            Suffix = " studs",
            Callback = function(Value)
                Config.SkillRange = Value
                SaveConfiguration()
            end
        })

        -- เวลากดค้างต่อคีย์ (วินาที) - 0 = ใช้จังหวะของสกิลเอง (HOLD_FREEZE_AT / MIN_HOLD_DUR)
        -- เพดาน 4 วิ: Fighter.Casting ถือว่าท่าค้างเมื่อเกิน 5 วิ ตัวตีจะกลับไปตีแทรกกลางท่า
        if type(Config.AutoUseSkillHold) ~= "table" then Config.AutoUseSkillHold = { } end

        task.wait()

        for _, Label in ipairs(KeyLabels) do
            SkillHoldSection:Slider({
                Name = "Hold " .. Label,
                Description = "0 is auto (the skill's own timing)",
                Flag = "SL2SkillHold" .. Label,
                Min = 0,
                Max = 4,
                Decimals = 0.1,
                Default = tonumber(Config.AutoUseSkillHold[Label]) or 0,
                Suffix = " s",
                Callback = function(Value)
                    Config.AutoUseSkillHold[Label] = tonumber(Value) or 0
                    SaveConfiguration()
                end
            })
        end
    end
end

---- ============ World Tab ============ ----
--
-- Breathing: เรียนปราณ = เควส "Ill learn <X> Breathing(Lv 25)" จาก Trainer (จ่าย Wen + ไอเทมตอนรับ)
-- เควสมี 5 task เรียงตาม Need + ตีลูกศิษย์ (Trainee) ปิดท้าย - อ่านลำดับจากข้อมูลเควสจริงของผู้เล่น
-- Data.Quests.Holder.<QuestInstance>.Tasks.<Task>.{Value, Max, Code, Need}
--
-- Training (ยืนยันสดกับ Serpent ทุกขั้น):
--   กด ProximityPrompt ของสถานีใน workspace.Training -> เซิร์ฟใส่ Configuration "Training" ใน Values folder
--   -> ยิง training_signaler("Stop", true) = ผ่าน (เซิร์ฟ Stop คืน true เฉย ๆ ไม่เช็คผล minigame)
--   Boulder Push ต่างออกไป: เซิร์ฟเชื่อม boulder ไว้กับตัว ต้องแบกไปแตะ Goal เอง ถึงจะได้เครดิต
--   Parkour Dungeon (Water/Stone) = ดันเจี้ยนจริง ต้องมีสกิล Wall Climb + Double Jump - ยังไม่รองรับ
--
-- ทั้ง 8 ปราณเหมือนกันหมดทั้งขั้นตอน (แค่ Trainer/ค่าใช้จ่าย/ท่าฝึกต่างกัน) เลยรวมเป็น section
-- เดียว: การ์ด Status ใบเดียว + Dropdown เลือกปราณ + Toggle Auto Breathing ตัวเดียว (เดิมแยก
-- 8 section คนละใบ ซ้ำซ้อนกันหมด) เปลี่ยน dropdown ระหว่างที่ Auto เปิดอยู่ = สลับไปฟาร์มปราณ
-- ตัวใหม่ทันที ไม่ต้องปิดเปิด toggle เอง

---- ============ Misc Tab ============ ----

task.wait()

--// Equipment - ใส่ของช่อง Stats (5 ช่อง) แบบดีที่สุดตามสายที่เลือก
--
-- ยืนยันสดผ่าน dex (decompile Menu.Pages.Inventory.Accessories + ใส่จริง: MaxHealth 397 -> 517):
--   ของที่ใส่ได้ = Items[ชื่อ].EquipType Accessory/Costume/Clothing (3/4/5) - ค่าอยู่ใน Items[ชื่อ].Stats
--     เช่น { Max Health = 105, Max Stamina = 35, Movement Speed Factor = 0.05, Sun Immunity = true }
--   ใส่ = SignalEvent.ToServer("AccessoryEquip", ช่อง "One".."Five", Id ของชิ้น, "Stats") / Id 0 = ถอด
--   ช่องที่ใส่อยู่ = Data.Inventory.Accessories.Stats.<ช่อง>.Value (Id) / Id ของชิ้น = Inventory.<ชื่อ>.Id
--   Class (Titan/Technician ฯลฯ) เป็นแค่ตัวกรองในหน้ากระเป๋า ไม่เจอโบนัสเซ็ต
-- คะแนน: ทุกค่าหารด้วยค่าสูงสุดของ stat นั้นทั้งเกม (0-1) - สายที่เลือกคูณ 10 + ค่าอื่นรวมไว้ตัดสินตอนเสมอ
-- "Auto (Skill Tree)" = น้ำหนักตามจำนวนขั้นที่อัปแต่ละสายใน skill tree (SkillTreeUnlockedList)
do
    local Config = getgenv().ConfigurationTable
    local GearPage = Window:Page({ Name = "Equipment", Icon = "shirt", Columns = 2 })

    local Items, Utility, SignalEvent = nil, nil, nil
    pcall(function()
        Items = require(ReplicatedStorage.CAM.Global.Collectibles.Items)
        Utility = require(ReplicatedStorage.CAM.Global.Utility)
        SignalEvent = HubSignal(require(ReplicatedStorage.Communication.ServerAndClient.Signals.SignalEvent))
    end)

    local Slots = { "One", "Two", "Three", "Four", "Five" }
    local Wearable = { [3] = true, [4] = true, [5] = true }

    -- สาย -> stat ใน Items.Stats (ชื่อสายตาม Stats branch ของ skill tree)
    local Groups = {
        ["Damage"] = { "Additional Damage", "Additional Damage Factor" },
        ["Health"] = { "Max Health", "Max Health Factor" },
        ["Health Regen"] = { "Health Regen Speed" },
        ["Stamina"] = { "Max Stamina" },
        ["Stamina Regen"] = { "Stamina Regen Speed" },
        ["Block"] = { "Block Points", "Block Regen" },
        ["Defense"] = { "Damage Reduction", "Damage Reduction Factor" },
        ["Speed"] = { "Movement Speed Factor" },
    }
    local Priorities = { "Auto (Skill Tree)", "Damage", "Health", "Health Regen", "Stamina", "Stamina Regen", "Block", "Defense", "Speed", "Balanced" }

    -- branch ใน SkillTreeUnlockedList -> สาย
    local TreeBranches = {
        ["Additional Damage"] = "Damage", ["Max Health"] = "Health", ["Health Regen Speed"] = "Health Regen",
        ["Max Stamina"] = "Stamina", ["Stamina Regen Speed"] = "Stamina Regen",
        ["Block Points"] = "Block", ["Block Regen"] = "Block",
    }

    -- ค่าสูงสุดของแต่ละ stat ทั้งเกม (ไว้ทำให้ค่าต่างหน่วยเทียบกันได้)
    local StatMax = { }
    for _, Info in pairs(type(Items) == "table" and Items or { }) do
        if type(Info) == "table" and type(Info.Stats) == "table" then
            for Key, Value in pairs(Info.Stats) do
                if type(Value) == "number" and Value > (StatMax[Key] or 0) then StatMax[Key] = Value end
            end
        end
    end

    local function GetData()
        local Ok, Data = pcall(function() return Utility.GetData(LocalPlayer, true) end)
        return Ok and Data or nil
    end

    -- น้ำหนักต่อสาย: เลือกสายเดียว = 1 / Balanced = ทุกสายเท่ากัน / Auto = ตามขั้นที่อัปใน skill tree
    local function Weights(Data)
        local Priority = Config.GearPriority
        local Result = { }
        if Groups[Priority] then
            Result[Priority] = 1
        elseif Priority == "Auto (Skill Tree)" then
            local Total = 0
            local List = Data and Data:FindFirstChild("SkillTreeUnlockedList")
            for _, Node in ipairs(List and List:GetChildren() or { }) do
                local Group = TreeBranches[Node.Name]
                local Level = Node:IsA("ValueBase") and tonumber(Node.Value) or 0
                if Group and Level > 0 then
                    Result[Group] = (Result[Group] or 0) + Level
                    Total = Total + Level
                end
            end
            if Total == 0 then Result = { Health = 1, Damage = 1 } Total = 2 end
            for Group, Level in pairs(Result) do Result[Group] = Level / Total end
        end
        return Result
    end

    local function Score(Stats, Weight)
        local Main, Rest = 0, 0
        for Key, Value in pairs(Stats) do
            if type(Value) == "number" and (StatMax[Key] or 0) > 0 then Rest = Rest + Value / StatMax[Key] end
        end
        for Group, W in pairs(Weight) do
            for _, Key in ipairs(Groups[Group]) do
                local Value = Stats[Key]
                if type(Value) == "number" and (StatMax[Key] or 0) > 0 then Main = Main + W * Value / StatMax[Key] end
            end
        end
        return Main * 10 + Rest
    end

    -- ของในกระเป๋าที่มี Stats ทุกชิ้น (ชิ้นละ Id) เรียงคะแนนมาก -> น้อย
    local function Candidates(Data, Weight)
        local List = { }
        local Inventory = Data and Data.Inventory and Data.Inventory:FindFirstChild("Inventory")
        for _, Folder in ipairs(Inventory and Inventory:GetChildren() or { }) do
            local Info = Items[Folder.Name]
            if type(Info) == "table" and type(Info.Stats) == "table" and Wearable[Info.EquipType] then
                local Value = Score(Info.Stats, Weight)
                for _, Child in ipairs(Folder:GetDescendants()) do
                    if Child.Name == "Id" and Child:IsA("ValueBase") and tonumber(Child.Value) and Child.Value ~= 0 then
                        table.insert(List, { Name = Folder.Name, Id = Child.Value, Score = Value, Stats = Info.Stats })
                    end
                end
            end
        end
        table.sort(List, function(A, B)
            if A.Score ~= B.Score then return A.Score > B.Score end
            return A.Name < B.Name
        end)
        return List
    end

    local Gear = { Busy = false }
    local GearLabel = nil
    local GearStatus = nil

    local function Show(Text, Detail)
        task.wait() -- GetData = thread เสีย capability ชั่วคราว - คั่นก่อนแตะ UI
        pcall(function()
            if GearStatus then GearStatus:SetText(Text) end
            if GearLabel and Detail then GearLabel:SetText(Detail) end
        end)
    end

    -- ใส่ 5 ชิ้นที่ดีที่สุด - ชิ้นที่ใส่อยู่แล้วคงช่องเดิม เปลี่ยนเฉพาะช่องที่ต้องเปลี่ยน คืนจำนวนช่องที่เปลี่ยน
    -- Preview = แค่คำนวณแล้วโชว์ว่าชุดไหนดีสุด ไม่ใส่ (ตอนไม่ได้เปิด Auto)
    local function EquipBest(Preview)
        if Gear.Busy or not (Items and SignalEvent) then return 0 end
        local Data = GetData()
        local Holder = Data and Data.Inventory and Data.Inventory:FindFirstChild("Accessories")
        Holder = Holder and Holder:FindFirstChild("Stats")
        if not Holder then return 0 end

        Gear.Busy = true
        local Weight = Weights(Data)
        local Best = { }
        for Index, Entry in ipairs(Candidates(Data, Weight)) do
            if Index > #Slots then break end
            Best[Entry.Id] = Entry
        end

        -- ช่องที่ของไม่อยู่ในชุดที่ดีที่สุด = ว่างให้ใส่ใหม่
        local Free, Worn = { }, { }
        for _, Slot in ipairs(Slots) do
            local Value = Holder:FindFirstChild(Slot)
            local Id = Value and Value.Value or 0
            if Id ~= 0 and Best[Id] then Worn[Id] = true else table.insert(Free, Slot) end
        end

        local Changed = 0
        for Id, Entry in pairs(Best) do
            if not Worn[Id] and not Preview then
                local Slot = table.remove(Free, 1)
                if not Slot then break end
                pcall(SignalEvent.ToServer, "AccessoryEquip", Slot, Id, "Stats")
                Farm.WaitFor(function()
                    local Value = Holder:FindFirstChild(Slot)
                    return Value ~= nil and Value.Value == Id
                end, 1.5)
                Changed = Changed + 1
            end
        end

        -- ช่องที่เหลือ (ของไม่พอ 5 ชิ้น) มีของเก่าคะแนนต่ำค้างอยู่ = ถอดออกไม่ต้อง ปล่อยไว้ได้ (ยังให้ค่าเพิ่ม)
        Gear.Busy = false

        local Names = { }
        for _, Slot in ipairs(Slots) do
            local Value = Holder:FindFirstChild(Slot)
            local Id = Value and Value.Value or 0
            if Id ~= 0 then
                local Found = "#" .. Id
                for _, Entry in pairs(Best) do if Entry.Id == Id then Found = Entry.Name end end
                table.insert(Names, Found)
            end
        end

        local WeightText = { }
        for Group, W in pairs(Weight) do table.insert(WeightText, string.format("%s %d%%", Group, math.floor(W * 100 + 0.5))) end
        table.sort(WeightText)

        -- ชุดที่ดีที่สุดที่ยังไม่ได้ใส่ (โหมด Preview)
        local Missing = { }
        for Id, Entry in pairs(Best) do
            if not Worn[Id] and Preview then table.insert(Missing, Entry.Name) end
        end
        table.sort(Missing)

        local Detail = #Names > 0 and ("Worn: " .. table.concat(Names, ", ")) or "Worn: -"
        if #Missing > 0 then Detail = Detail .. "\nBetter: " .. table.concat(Missing, ", ") end
        if next(Best) == nil then Detail = "No stat equipment in inventory" end
        Show(string.format("Equipment: %d/5 worn · %s", #Names, table.concat(WeightText, ", ")), Detail)
        return Changed
    end

    --// Best Weapon - อาวุธ (EquipType 2 + HasCombat) ค่า ActiveToolStats (ได้ตอนถือ) เช่น Tornadic Katana
    -- { Additional Damage = 4, Additional Damage Factor = 0.065, Block Points = 3.75 } ให้คะแนนแบบเดียวกับชุด
    -- ใช้ได้เฉพาะเล่มที่ผ่าน EquipRequirements (ItemRequirements.Passes - เช่น Claws/Scythe ต้องเป็น Demon)
    -- ยืนยันสด: ใส่ลง Toolbar = SignalEvent.ToServer("Toolbar_Equip", ช่อง "One".."Five", Id) / Id 0 = เอาออก
    -- ถือ = Farm.EquipWeapon (ลูปฟาร์มทุกแท็บเรียกตัวนี้ - เปิด Auto แล้วจะถือเล่มนี้แทน Select Weapon)
    local ItemRequirements = nil
    pcall(function() ItemRequirements = require(ReplicatedStorage.CAM.Global.Collectibles.ItemRequirements) end)

    local WeaponMax = { }
    for _, Info in pairs(type(Items) == "table" and Items or { }) do
        if type(Info) == "table" and type(Info.ActiveToolStats) == "table" then
            for Key, Value in pairs(Info.ActiveToolStats) do
                if type(Value) == "number" and Value > (WeaponMax[Key] or 0) then WeaponMax[Key] = Value end
            end
        end
    end

    local function WeaponScore(Stats, Weight)
        local Main, Rest = 0, 0
        for Key, Value in pairs(Stats) do
            if type(Value) == "number" and (WeaponMax[Key] or 0) > 0 then Rest = Rest + Value / WeaponMax[Key] end
        end
        for Group, W in pairs(Weight) do
            for _, Key in ipairs(Groups[Group]) do
                local Value = Stats[Key]
                if type(Value) == "number" and (WeaponMax[Key] or 0) > 0 then Main = Main + W * Value / WeaponMax[Key] end
            end
        end
        return Main * 10 + Rest
    end

    local function WeaponInfo(Name)
        local Info = Items and Items[Name]
        if type(Info) ~= "table" or Info.EquipType ~= 2 or not Info.HasCombat then return nil end
        return Info
    end

    -- คืนเล่มที่ดีที่สุด { Name, Id, Score } ที่ใส่ได้ (ไม่มีค่าเลยสักเล่ม = nil)
    local function BestWeaponOf(Data, Weight)
        local Best = nil
        local Inventory = Data and Data.Inventory and Data.Inventory:FindFirstChild("Inventory")
        for _, Folder in ipairs(Inventory and Inventory:GetChildren() or { }) do
            local Info = WeaponInfo(Folder.Name)
            local Stats = Info and Info.ActiveToolStats
            local Allowed = Info ~= nil and (Info.EquipRequirements == nil or ItemRequirements == nil
                or select(2, pcall(ItemRequirements.Passes, Data, Info.EquipRequirements)) == true)
            local IdValue = Folder:FindFirstChild("Id")
            if Allowed and type(Stats) == "table" and IdValue and IdValue.Value ~= 0 then
                local Value = WeaponScore(Stats, Weight)
                if Value > 0 and (not Best or Value > Best.Score or (Value == Best.Score and Folder.Name < Best.Name)) then
                    Best = { Name = Folder.Name, Id = IdValue.Value, Score = Value }
                end
            end
        end
        return Best
    end

    local WeaponLabel = nil

    -- Preview = แค่หาเล่มที่ดีที่สุดแล้วโชว์ / ไม่งั้นใส่ลง Toolbar (ถ้ายังไม่อยู่) แล้วถือ
    local function EquipBestWeapon(Preview)
        if not (Items and SignalEvent) then return end
        local Data = GetData()
        local Toolbar = Data and Data.Inventory and Data.Inventory:FindFirstChild("Toolbar")
        if not Toolbar then return end

        local Best = BestWeaponOf(Data, Weights(Data))
        Farm.BestWeapon = Best and Best.Name or nil

        local Text = "Weapon: -"
        if Best then
            -- เทียบด้วยชื่อ ไม่ใช่ Id: มีหลายเล่มชื่อเดียวกัน (วัดสด Tanto Id 41 + 52) เล่มไหนอยู่ใน Toolbar
            -- แล้วก็ใช้เล่มนั้น ไม่งั้นเอาอีกเล่มไปวางซ้ำช่องว่าง
            local NameOfId = { }
            local Inventory = Data.Inventory:FindFirstChild("Inventory")
            for _, Folder in ipairs(Inventory and Inventory:GetChildren() or { }) do
                local IdValue = Folder:FindFirstChild("Id")
                if IdValue then NameOfId[IdValue.Value] = Folder.Name end
            end

            local Fixed = table.find(Slots, Config.BestWeaponSlot) and Config.BestWeaponSlot or nil
            local InSlot, InSlotId = nil, nil
            for _, Slot in ipairs(Slots) do
                local Value = Toolbar:FindFirstChild(Slot)
                if Value and Value.Value ~= 0 and NameOfId[Value.Value] == Best.Name and (InSlot ~= Fixed or InSlot == nil) then
                    InSlot, InSlotId = Slot, Value.Value
                end
            end

            -- เลือกช่องเอง: ย้ายเล่มที่อยู่ช่องอื่นมา (เอาออกจากช่องเดิมก่อน ไม่ให้เล่มเดียวอยู่ 2 ช่อง)
            if Fixed and InSlot ~= Fixed and not Preview then
                local Id = InSlotId or Best.Id
                if InSlot then
                    local Old = InSlot
                    pcall(SignalEvent.ToServer, "Toolbar_Equip", Old, 0)
                    Farm.WaitFor(function()
                        local Value = Toolbar:FindFirstChild(Old)
                        return Value ~= nil and Value.Value == 0
                    end, 1.5)
                end
                pcall(SignalEvent.ToServer, "Toolbar_Equip", Fixed, Id)
                if Farm.WaitFor(function()
                    local Value = Toolbar:FindFirstChild(Fixed)
                    return Value ~= nil and Value.Value == Id
                end, 1.5) then InSlot = Fixed else InSlot = nil end
            end

            if not InSlot and not Preview and not Fixed then
                -- ช่องว่างก่อน ไม่มี = ทับอาวุธที่คะแนนต่ำสุดใน Toolbar (ไม่ทับยา/เบ็ด/ของอื่นที่ไม่ใช่อาวุธ)
                local Weight = Weights(Data)
                local Target, TargetScore = nil, math.huge
                for _, Slot in ipairs(Slots) do
                    local Value = Toolbar:FindFirstChild(Slot)
                    if Value and Value.Value == 0 then Target, TargetScore = Slot, -math.huge break end
                end
                if not Target then
                    local Inventory = Data.Inventory:FindFirstChild("Inventory")
                    for _, Slot in ipairs(Slots) do
                        local Value = Toolbar:FindFirstChild(Slot)
                        for _, Folder in ipairs(Inventory and Inventory:GetChildren() or { }) do
                            local IdValue = Folder:FindFirstChild("Id")
                            local Info = WeaponInfo(Folder.Name)
                            if Value and IdValue and IdValue.Value == Value.Value and Info then
                                local Worth = type(Info.ActiveToolStats) == "table" and WeaponScore(Info.ActiveToolStats, Weight) or 0
                                if Worth < TargetScore then Target, TargetScore = Slot, Worth end
                            end
                        end
                    end
                end

                if Target then
                    pcall(SignalEvent.ToServer, "Toolbar_Equip", Target, Best.Id)
                    Farm.WaitFor(function()
                        local Value = Toolbar:FindFirstChild(Target)
                        return Value ~= nil and Value.Value == Best.Id
                    end, 1.5)
                    InSlot = Target
                end
            end

            -- ผู้ใช้ 2026-10-02: แค่ใส่ลงช่อง Toolbar ไม่ถือแทนอาวุธที่ตั้งไว้ในแท็บฟาร์ม (Select Weapon / Best Weapon คุมเอง)
            Farm.BestWeaponSlot = InSlot and table.find(Slots, InSlot) or nil
            Text = string.format("Weapon: %s%s", Best.Name, InSlot and (" · Slot " .. InSlot) or " (not in toolbar)")
        end

        task.wait() -- GetData = thread เสีย capability ชั่วคราว - คั่นก่อนแตะ UI
        pcall(function() if WeaponLabel then WeaponLabel:SetText(Text) end end)
    end

    task.wait()

    local GearSection = GearPage:Section({
        Name = "Best Equipment",
        Description = "Wear the best stat equipment for your build",
        Icon = "80758916183665",
        Side = 1
    })

    GearStatus = GearSection:Label("Equipment: -")
    WeaponLabel = GearSection:Label("Weapon: -")
    local M1Label = GearSection:Label("M1 Weapon: -")
    GearLabel = GearSection:Label("-", true)

    GearSection:Dropdown({
        Name = "Priority",
        Description = "Auto follows the stats you levelled in the skill tree",
        Flag = "SL2GearPriority",
        Items = Priorities,
        Default = table.find(Priorities, Config.GearPriority) and Config.GearPriority or Priorities[1],
        Multi = false,
        KeepOrder = true,
        Seperator = false,
        Callback = function(Value)
            if type(Value) ~= "string" then return end
            Config.GearPriority = Value
            SaveConfiguration()
            task.spawn(EquipBest, not Config.AutoEquipGear)
            task.spawn(EquipBestWeapon, not Config.AutoEquipBestWeapon)
        end
    })

    local WeaponSlots = { "Auto", "One", "Two", "Three", "Four", "Five" }
    GearSection:Dropdown({
        Name = "Weapon Slot",
        Description = "Toolbar slot for the best weapon (Auto is an empty slot, or it replaces your worst weapon)",
        Flag = "SL2BestWeaponSlot",
        Items = WeaponSlots,
        Default = table.find(WeaponSlots, Config.BestWeaponSlot) and Config.BestWeaponSlot or "Auto",
        Multi = false,
        KeepOrder = true,
        Callback = function(Value)
            if type(Value) ~= "string" then return end
            Config.BestWeaponSlot = Value
            SaveConfiguration()
            task.spawn(EquipBestWeapon, not Config.AutoEquipBestWeapon)
        end
    })

    GearSection:Toggle({
        Name = "Auto Equip Best",
        Description = "Keeps the best 5 stat items on, re-checks when you get new equipment",
        Flag = "SL2AutoEquipGear",
        Default = Config.AutoEquipGear,
        Seperator = false,
        Callback = function(Value)
            Config.AutoEquipGear = Value
            SaveConfiguration()
            task.spawn(EquipBest, not Value)
        end
    })

    GearSection:Toggle({
        Name = "Auto Equip Best Weapon",
        Description = "Puts your best weapon (same priority) into a toolbar slot, and M1 uses your strongest weapon when a tab's Select Weapon is not in the toolbar",
        Flag = "SL2AutoEquipBestWeapon",
        Default = Config.AutoEquipBestWeapon,
        Seperator = false,
        Callback = function(Value)
            Config.AutoEquipBestWeapon = Value
            SaveConfiguration()
            task.spawn(EquipBestWeapon, not Value)
        end
    })

    -- Title ดีสุดตามสถานการณ์ (ตัวคุม SyncTitles อยู่ในบล็อก Fishing เช็คทุก 1 วิ)
    GearSection:Toggle({
        Name = "Auto Best Title",
        Description = "Wears your best titles for what you're doing: fishing titles while fishing, damage titles while farming",
        Flag = "SL2AutoBestTitle",
        Default = Config.AutoBestTitle == true,
        Seperator = false,
        Callback = function(Value)
            Config.AutoBestTitle = Value == true
            SaveConfiguration()
            if Farm.SyncTitles then task.spawn(Farm.SyncTitles) end
        end
    })

    -- บรรทัด M1 Weapon: เล่มที่ใช้ M1 ตอนนี้ + คะแนน (ดาเมจ M1 ต่อวิโดยประมาณ)
    task.spawn(function()
        while getgenv().ValkyrieSession == SessionToken do
            -- เล่มที่ M1 ใช้จริงตอนนี้ (Select Weapon ของโหมดที่รันอยู่ก่อน - ไม่มีใน Toolbar = Best M1)
            local Name = Farm.M1Weapon(ModeSetting("FarmWeapon"))
            local Score = type(Name) == "string" and Name ~= "" and Farm.M1Score(Name)
            local Text = (type(Name) == "string" and Name ~= "")
                and string.format("M1 Weapon: %s (~%.1f dmg/s)", Name, Score or 0) or "M1 Weapon: no weapon in toolbar"
            task.wait() -- GetToolbar = GetData เสีย capability ชั่วคราว
            pcall(function() M1Label:SetText(Text) end)
            task.wait()
        end
    end)

    -- เปิด Auto ไว้ = เช็คทุก 5 วิ (ของใหม่เข้ากระเป๋า / skill tree เปลี่ยนสาย) ใส่ใหม่เฉพาะตอนชุดที่ดีที่สุดเปลี่ยน
    task.spawn(function()
        task.wait(3)
        while getgenv().ValkyrieSession == SessionToken do
            pcall(EquipBest, not Config.AutoEquipGear)
            pcall(EquipBestWeapon, not Config.AutoEquipBestWeapon)
            task.wait(5)
        end
    end)
end

--// Potions - ดื่มยาอัตโนมัติ (ซ้าย) + ซื้อยาที่หมดจากร้านใน place นี้ (ขวา) / ตัวทำงานอยู่ที่ Farm.Potions
do
    local PotionPage = Window:Page({ Name = "Potions", Icon = "flask-conical", Columns = 2 })

    local PotionSection = PotionPage:Section({
        Name = "Auto Drink Potion",
        Description = "Drink potions when health or stamina is low",
        Icon = "80758916183665",
        Side = 1
    })

    local BuySection = PotionPage:Section({
        Name = "Auto Buy Potion",
        Description = "Buy potions you run out of from a shop in this place",
        Icon = "80758916183665",
        Side = 2
    })

    local Config = getgenv().ConfigurationTable
    if type(Config.DrinkPotions) ~= "table" then Config.DrinkPotions = { } end

    local PotionStatus = PotionSection:Label("Status: -")
    local PotionStock = PotionSection:Label("Stock: -", true)

    PotionSection:Dropdown({
        Name = "Potions",
        Description = "Which potions to drink (Elixir first). Regen potions wait until the buff ends",
        Flag = "SL2DrinkPotions",
        Items = Potions.Order,
        Default = Config.DrinkPotions,
        Multi = true,
        KeepOrder = true,
        Callback = function(Value)
            if type(Value) ~= "table" then return end
            Config.DrinkPotions = Value
            SaveConfiguration()
        end
    })

    PotionSection:Slider({
        Name = "Drink At Health",
        Flag = "SL2DrinkHealthPercent",
        Min = 5,
        Max = 95,
        Default = Config.DrinkHealthPercent,
        Suffix = "%",
        Seperator = false,
        Callback = function(Value)
            Config.DrinkHealthPercent = Value
            SaveConfiguration()
        end
    })

    PotionSection:Slider({
        Name = "Drink At Stamina",
        Flag = "SL2DrinkStaminaPercent",
        Min = 5,
        Max = 95,
        Default = Config.DrinkStaminaPercent,
        Suffix = "%",
        Callback = function(Value)
            Config.DrinkStaminaPercent = Value
            SaveConfiguration()
        end
    })

    PotionSection:Toggle({
        Name = "Auto Drink Potion",
        Description = "Underwater Breathing Potion is drunk while swimming underwater",
        Flag = "SL2AutoDrinkPotion",
        Default = Config.AutoDrinkPotion,
        Callback = function(Value)
            Config.AutoDrinkPotion = Value
            SaveConfiguration()
        end
    })

    BuySection:Label("Shops: Rika (Windy Peak) sells Health Regen Potion 600 Wen and Stamina Regen Potion 900 Wen. Health Potion is not sold", true)

    BuySection:Toggle({
        Name = "Auto Buy Potion",
        Description = "When a selected potion runs out, flies to the shop and buys more (farm waits between targets)",
        Flag = "SL2AutoBuyPotion",
        Default = Config.AutoBuyPotion,
        Callback = function(Value)
            Config.AutoBuyPotion = Value
            SaveConfiguration()
        end
    })

    BuySection:Slider({
        Name = "Buy Amount",
        Flag = "SL2BuyPotionAmount",
        Min = 1,
        Max = 20,
        Default = Config.BuyPotionAmount,
        Seperator = false,
        Callback = function(Value)
            Config.BuyPotionAmount = Value
            SaveConfiguration()
        end
    })

    -- สถานะ + จำนวนยาที่เลือก (ร้านใน place นี้ไม่มี = บอกไว้ข้างชื่อ)
    task.spawn(function()
        while getgenv().ValkyrieSession == SessionToken do
            local Parts = { }
            for _, Name in ipairs(Potions.Order) do
                if table.find(Config.DrinkPotions, Name) then
                    local Amount = Potions.Amount(Name)
                    local Tag = (Amount == 0 and not Potions.FindShop(Name)) and " (no shop)" or ""
                    table.insert(Parts, string.format("%s %d%s", Name, Amount, Tag))
                end
            end
            local Status = string.format("Status: %s · Last: %s", Potions.Status, Potions.Last)
            local Stock = #Parts > 0 and table.concat(Parts, "\n") or "No potion selected"
            task.wait() -- GetData = thread เสีย capability ชั่วคราว - คั่นก่อนแตะ UI
            pcall(function()
                PotionStatus:SetText(Status)
                PotionStock:SetText(Stock)
            end)
            task.wait()
        end
    end)
end

---- ============ Visual (ESP) ============ ----
--
-- วาดด้วย Drawing API ของ executor (กรอบ / เส้น / ชื่อ / ระยะ / หลอดเลือด) + Highlight (chams) มองทะลุกำแพง
-- เป้า: Players / Mobs + Bosses (workspace.Humanoids.Regions.*.ActiveNpcs ผ่าน Farm.IterMobs - บอส = มี BossInfo) /
--       NPCs (workspace.Debree.Regions.*.StationaryNpcs) / Chests & Loot (tag Chest, LootDrop ที่ prompt เปิดอยู่) /
--       Sealed Caches (workspace.Chests) / Boss Spawns (จุดเกิดบอสที่ตายอยู่ + เวลาเกิดใหม่จาก Farm.BossCooldown)
-- กวาดลิสต์เป้าทุก 0.25 วิ วาดทุกเฟรม - ของที่ไม่อยู่ในลิสต์แล้วซ่อน หายเกิน 3 วิลบทิ้ง
-- Highlight ของ Roblox โชว์พร้อมกันได้ไม่เกิน 31 อัน -> chams เอาเฉพาะตัวใกล้สุด 30 ตัว
-- World: Fullbright / No Fog (เก็บค่าเดิมไว้คืนตอนปิด - ไม่แตะ ClockTime เพราะระบบกลางวัน/กลางคืนของเกมอ่านอยู่) / FOV
local VisualCleanup = nil
do
    local Config = getgenv().ConfigurationTable
    local Lighting = game:GetService("Lighting")
    local CollectionService = game:GetService("CollectionService")
    local UserInputService = game:GetService("UserInputService")
    local HasDrawing = typeof(Drawing) == "table" and pcall(function() Drawing.new("Line"):Remove() end)

    local Kinds = {
        { Key = "Players", Name = "Players", Color = Color3.fromRGB(90, 170, 255),
            Options = { "Box", "Tracer", "Name", "Distance", "Health", "Chams", "Info" }, Default = { "Box", "Name", "Distance", "Health" } },
        { Key = "Mobs", Name = "Mobs", Color = Color3.fromRGB(255, 190, 80),
            Options = { "Box", "Tracer", "Name", "Distance", "Health", "Chams" }, Default = { "Name", "Distance", "Health" } },
        { Key = "Bosses", Name = "Bosses", Color = Color3.fromRGB(255, 70, 70),
            Options = { "Box", "Tracer", "Name", "Distance", "Health", "Chams" }, Default = { "Box", "Tracer", "Name", "Distance", "Health" } },
        { Key = "Npcs", Name = "NPCs", Color = Color3.fromRGB(120, 255, 150),
            Options = { "Box", "Tracer", "Name", "Distance", "Chams" }, Default = { "Name", "Distance" } },
        { Key = "Loot", Name = "Chests & Loot", Color = Color3.fromRGB(255, 225, 90),
            Options = { "Box", "Tracer", "Name", "Distance", "Chams" }, Default = { "Tracer", "Name", "Distance" } },
        { Key = "Caches", Name = "Sealed Caches", Color = Color3.fromRGB(200, 120, 255),
            Options = { "Box", "Tracer", "Name", "Distance", "Chams" }, Default = { "Name", "Distance" } },
        { Key = "Spawns", Name = "Boss Spawns", Color = Color3.fromRGB(255, 130, 130),
            Options = { "Tracer", "Name", "Distance" }, Default = { "Name", "Distance" } },
    }
    local KindByKey = { }
    for _, Kind in ipairs(Kinds) do KindByKey[Kind.Key] = Kind end

    -- ค่าตั้ง (เซฟใน Config.Visual) - ของที่ยังไม่มีเติมค่าเริ่มให้
    local V = type(Config.Visual) == "table" and Config.Visual or { }
    Config.Visual = V
    local Defaults = {
        MaxDistance = 2000, TextSize = 14, BoxStyle = "Box", TracerFrom = "Bottom", ChamsFill = 60,
        Fullbright = false, NoFog = false, FOVEnabled = false, FOV = 90,
    }
    for Key, Value in pairs(Defaults) do
        if V[Key] == nil then V[Key] = Value end
    end
    for _, Kind in ipairs(Kinds) do
        local Entry = type(V[Kind.Key]) == "table" and V[Kind.Key] or { }
        if Entry.Enabled == nil then Entry.Enabled = false end
        if type(Entry.Show) ~= "table" then Entry.Show = table.clone(Kind.Default) end
        if type(Entry.Color) ~= "string" then Entry.Color = Kind.Color:ToHex() end
        V[Kind.Key] = Entry
    end

    -- ค่าที่ใช้ตอนวาด (แปลงจาก config ครั้งเดียวตอนเปลี่ยน ไม่แปลงทุกเฟรม)
    local ShowSet, Colors = { }, { }
    local function Refresh(Key)
        local Set = { }
        for _, Name in ipairs(V[Key].Show) do Set[Name] = true end
        ShowSet[Key] = Set
        local Ok, Color = pcall(Color3.fromHex, V[Key].Color)
        Colors[Key] = Ok and Color or KindByKey[Key].Color
    end
    for _, Kind in ipairs(Kinds) do Refresh(Kind.Key) end

    local function Enabled(Key)
        return V[Key].Enabled == true
    end

    local function AnyEnabled()
        for _, Kind in ipairs(Kinds) do
            if V[Kind.Key].Enabled then return true end
        end
        return false
    end

    ---- เป้า ----

    local function Origin()
        local Root = Movement.GetRoot()
        return Root and Root.Position or workspace.CurrentCamera.CFrame.Position
    end

    local function FirstPart(Inst)
        if Inst:IsA("BasePart") then return Inst end
        if Inst:IsA("Model") then return Inst.PrimaryPart or Inst:FindFirstChildWhichIsA("BasePart", true) end
        return nil
    end

    local function Scan()
        local List, Seen = { }, { }
        local From, Max = Origin(), tonumber(V.MaxDistance) or 2000

        local function Add(Target)
            if Seen[Target.Key] then return end
            local Position = Target.Point or (Target.Part and Target.Part.Position)
            if not Position then return end
            Target.Distance = (Position - From).Magnitude
            if Target.Distance > Max then return end
            Seen[Target.Key] = true
            table.insert(List, Target)
        end

        if Enabled("Players") then
            for _, Player in ipairs(Players:GetPlayers()) do
                local Character = Player ~= LocalPlayer and Player.Character
                local Part = Character and Character:FindFirstChild("HumanoidRootPart")
                local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
                if Part and Humanoid and Humanoid.Health > 0 then
                    local Name = Player.DisplayName ~= Player.Name and (Player.DisplayName .. " (@" .. Player.Name .. ")") or Player.Name
                    Add({ Key = Character, Kind = "Players", Model = Character, Part = Part, Humanoid = Humanoid, Name = Name, Player = Player })
                end
            end
        end

        if Enabled("Mobs") or Enabled("Bosses") then
            for _, Mob in ipairs(Farm.IterMobs()) do
                local Kind = Mob.IsBoss and "Bosses" or "Mobs"
                if Enabled(Kind) and Mob.Model.Parent then
                    Add({ Key = Mob.Model, Kind = Kind, Model = Mob.Model, Part = Mob.Root, Humanoid = Mob.Humanoid, Name = Mob.Model.Parent.Name })
                end
            end
        end

        if Enabled("Npcs") then
            local Debree = workspace:FindFirstChild("Debree")
            local Regions = Debree and Debree:FindFirstChild("Regions")
            for _, Region in ipairs(Regions and Regions:GetChildren() or { }) do
                local Stationary = Region:FindFirstChild("StationaryNpcs")
                for _, Npc in ipairs(Stationary and Stationary:GetChildren() or { }) do
                    local Part = Npc:FindFirstChild("HumanoidRootPart") or FirstPart(Npc)
                    if Part then Add({ Key = Npc, Kind = "Npcs", Model = Npc, Part = Part, Name = Npc.Name }) end
                end
            end
        end

        -- Sealed Cache ก่อน Loot (กล่องใน workspace.Chests อาจติด tag Chest ด้วย - ไม่ให้ซ้ำ)
        if Enabled("Caches") then
            for _, Cache in ipairs(Farm.GetSealedCaches()) do
                local Part = FirstPart(Cache.Instance)
                local State = Cache.Opened and " (opened)" or (not Cache.Open and " (sealed)" or "")
                if Part then
                    Add({ Key = Cache.Instance, Kind = "Caches", Model = Cache.Instance, Part = Part, Name = "Sealed Cache " .. Cache.Tier .. State })
                end
            end
        elseif Enabled("Loot") then
            local Chests = workspace:FindFirstChild("Chests")
            for _, Cache in ipairs(Chests and Chests:GetChildren() or { }) do Seen[Cache] = true end
        end

        if Enabled("Loot") then
            for _, Tag in ipairs(Farm.PickupTags or { "Chest", "LootDrop" }) do
                for _, Inst in ipairs(CollectionService:GetTagged(Tag)) do
                    local Prompt = Inst.Parent and Inst:FindFirstChildWhichIsA("ProximityPrompt", true)
                    local Part = Prompt and Prompt.Enabled and FirstPart(Inst)
                    if Part then
                        local Name = Prompt.ObjectText ~= "" and Prompt.ObjectText or Inst.Name
                        Add({ Key = Inst, Kind = "Loot", Model = Inst, Part = Part, Name = Name })
                    end
                end
            end
        end

        if Enabled("Spawns") then
            for Name, Boss in pairs(Farm.GetWorldBosses()) do
                local Left = Farm.BossCooldown(Name)
                if Left and Left > 0 and typeof(Boss.Center) == "Vector3" then
                    Add({ Key = "Spawn:" .. Name, Kind = "Spawns", Point = Boss.Center, Name = Name, Timer = Left })
                end
            end
        end

        -- chams เฉพาะ 30 ตัวใกล้สุด (Highlight โชว์ได้ไม่เกิน 31)
        local Chams = { }
        for _, Target in ipairs(List) do
            if ShowSet[Target.Kind].Chams and Target.Model then table.insert(Chams, Target) end
        end
        table.sort(Chams, function(A, B) return A.Distance < B.Distance end)
        for Index = 1, math.min(#Chams, 30) do Chams[Index].Chams = true end
        return List
    end

    ---- ของที่วาด (pool ต่อเป้า) ----

    local Holder = Instance.new("Folder")
    Holder.Name = "ValkyrieVisual"
    pcall(function() Holder.Parent = gethui and gethui() or game:GetService("CoreGui") end)
    if not Holder.Parent then Holder.Parent = game:GetService("CoreGui") end

    local Pool = { }

    local function NewDrawing(Class, Props)
        local Object = Drawing.new(Class)
        for Key, Value in pairs(Props) do Object[Key] = Value end
        return Object
    end

    local function Objects(Key)
        local Set = Pool[Key]
        if Set then return Set end
        Set = { }
        if HasDrawing then
            Set.BoxOutline = NewDrawing("Square", { Thickness = 3, Filled = false, Color = Color3.new(0, 0, 0), Visible = false })
            Set.Box = NewDrawing("Square", { Thickness = 1, Filled = false, Visible = false })
            Set.Corners = { }
            for Index = 1, 8 do Set.Corners[Index] = NewDrawing("Line", { Thickness = 1, Visible = false }) end
            Set.Tracer = NewDrawing("Line", { Thickness = 1, Visible = false })
            Set.Name = NewDrawing("Text", { Center = true, Outline = true, Visible = false })
            Set.Info = NewDrawing("Text", { Center = true, Outline = true, Visible = false })
            Set.BarBack = NewDrawing("Square", { Filled = true, Color = Color3.new(0, 0, 0), Visible = false })
            Set.Bar = NewDrawing("Square", { Filled = true, Visible = false })
        end
        Pool[Key] = Set
        return Set
    end

    local function HideDrawings(Set)
        for _, Name in ipairs({ "BoxOutline", "Box", "Tracer", "Name", "Info", "BarBack", "Bar" }) do
            if Set[Name] then Set[Name].Visible = false end
        end
        for _, Line in ipairs(Set.Corners or { }) do Line.Visible = false end
    end

    local function Hide(Set)
        HideDrawings(Set)
        if Set.Highlight then Set.Highlight.Enabled = false end
    end

    local function Destroy(Set)
        for _, Name in ipairs({ "BoxOutline", "Box", "Tracer", "Name", "Info", "BarBack", "Bar" }) do
            if Set[Name] then pcall(function() Set[Name]:Remove() end) end
        end
        for _, Line in ipairs(Set.Corners or { }) do pcall(function() Line:Remove() end) end
        if Set.Highlight then pcall(function() Set.Highlight:Destroy() end) end
    end

    -- กรอบ 3D ของเป้า: GetBoundingBox (จำไว้ 2 วิ เทียบกับ Part หลัก เป้าเดินได้กรอบตามไป)
    local BoundsCache = setmetatable({ }, { __mode = "k" })
    local Signs = {
        Vector3.new(-1, -1, -1), Vector3.new(-1, -1, 1), Vector3.new(-1, 1, -1), Vector3.new(-1, 1, 1),
        Vector3.new(1, -1, -1), Vector3.new(1, -1, 1), Vector3.new(1, 1, -1), Vector3.new(1, 1, 1),
    }

    local function Bounds(Target)
        local Cached = BoundsCache[Target.Key]
        if not Cached or os.clock() - Cached.At > 2 then
            local Ok, Frame, Size = pcall(function()
                if Target.Model:IsA("Model") then return Target.Model:GetBoundingBox() end
                return Target.Part.CFrame, Target.Part.Size
            end)
            if not Ok then return nil end
            -- ตัวคน/มอน: อาวุธ/เอฟเฟกต์ทำกรอบบวม - จำกัดความกว้างไม่เกินความสูง
            if Target.Humanoid then
                Size = Vector3.new(math.min(Size.X, Size.Y * 0.8), Size.Y, math.min(Size.Z, Size.Y * 0.8))
            end
            Cached = { Offset = Target.Part.CFrame:ToObjectSpace(Frame), Size = Size, At = os.clock() }
            BoundsCache[Target.Key] = Cached
        end
        return Target.Part.CFrame * Cached.Offset, Cached.Size
    end

    local function Project(Camera, Frame, Size)
        local Half = Size / 2
        local MinX, MinY, MaxX, MaxY = math.huge, math.huge, -math.huge, -math.huge
        for _, Sign in ipairs(Signs) do
            local Screen = Camera:WorldToViewportPoint(Frame:PointToWorldSpace(Half * Sign))
            if Screen.Z <= 0 then return nil end
            MinX, MaxX = math.min(MinX, Screen.X), math.max(MaxX, Screen.X)
            MinY, MaxY = math.min(MinY, Screen.Y), math.max(MaxY, Screen.Y)
        end
        return MinX, MinY, MaxX, MaxY
    end

    local function Clock(Seconds)
        Seconds = math.max(0, math.floor(Seconds))
        return string.format("%d:%02d", Seconds // 60, Seconds % 60)
    end

    local function SetCorners(Set, Color, X1, Y1, X2, Y2)
        local Width, Height = X2 - X1, Y2 - Y1
        local W, H = Width * 0.25, Height * 0.25
        local Points = {
            { X1, Y1, X1 + W, Y1 }, { X1, Y1, X1, Y1 + H }, { X2, Y1, X2 - W, Y1 }, { X2, Y1, X2, Y1 + H },
            { X1, Y2, X1 + W, Y2 }, { X1, Y2, X1, Y2 - H }, { X2, Y2, X2 - W, Y2 }, { X2, Y2, X2, Y2 - H },
        }
        for Index, Line in ipairs(Set.Corners) do
            local P = Points[Index]
            Line.From, Line.To = Vector2.new(P[1], P[2]), Vector2.new(P[3], P[4])
            Line.Color = Color
            Line.Visible = true
        end
    end

    local function Chams(Set, Target, Color)
        if not (Target.Chams and Target.Model) then
            if Set.Highlight then Set.Highlight.Enabled = false end
            return
        end
        local Highlight = Set.Highlight
        if not Highlight then
            Highlight = Instance.new("Highlight")
            Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            Highlight.Parent = Holder
            Set.Highlight = Highlight
        end
        if Highlight.Adornee ~= Target.Model then Highlight.Adornee = Target.Model end
        Highlight.FillColor, Highlight.OutlineColor = Color, Color
        Highlight.FillTransparency = math.clamp((tonumber(V.ChamsFill) or 60) / 100, 0, 1)
        Highlight.OutlineTransparency = 0
        Highlight.Enabled = true
    end

    local function Draw(Camera, Target, Set)
        local Show, Color = ShowSet[Target.Kind], Colors[Target.Kind]
        Chams(Set, Target, Color)
        if not HasDrawing then return end

        local X1, Y1, X2, Y2
        if Target.Point then
            local Screen = Camera:WorldToViewportPoint(Target.Point)
            if Screen.Z > 0 then X1, Y1, X2, Y2 = Screen.X, Screen.Y, Screen.X, Screen.Y end
        elseif Target.Part and Target.Part.Parent then
            local Frame, Size = Bounds(Target)
            if Frame then X1, Y1, X2, Y2 = Project(Camera, Frame, Size) end
        end
        if not X1 then HideDrawings(Set) return end     -- อยู่หลังกล้อง - chams ยังโชว์ต่อ

        local TextSize = tonumber(V.TextSize) or 14
        local IsBox = Show.Box and not Target.Point
        local Corner = V.BoxStyle == "Corners"

        Set.Box.Visible, Set.BoxOutline.Visible = false, false
        for _, Line in ipairs(Set.Corners) do Line.Visible = false end
        if IsBox then
            if Corner then
                SetCorners(Set, Color, X1, Y1, X2, Y2)
            else
                local Position, Size = Vector2.new(X1, Y1), Vector2.new(X2 - X1, Y2 - Y1)
                Set.BoxOutline.Position, Set.BoxOutline.Size, Set.BoxOutline.Visible = Position, Size, true
                Set.Box.Position, Set.Box.Size, Set.Box.Color, Set.Box.Visible = Position, Size, Color, true
            end
        end

        -- หลอดเลือดซ้ายกรอบ (ไล่สีแดง -> เขียว)
        local Humanoid = Target.Humanoid
        local Ratio = Humanoid and Humanoid.MaxHealth > 0 and math.clamp(Humanoid.Health / Humanoid.MaxHealth, 0, 1) or nil
        if Show.Health and Ratio and not Target.Point then
            local Height = math.max(Y2 - Y1, 4)
            Set.BarBack.Position, Set.BarBack.Size, Set.BarBack.Visible = Vector2.new(X1 - 6, Y1 - 1), Vector2.new(4, Height + 2), true
            Set.Bar.Position = Vector2.new(X1 - 5, Y1 + Height * (1 - Ratio))
            Set.Bar.Size = Vector2.new(2, Height * Ratio)
            Set.Bar.Color = Color3.fromRGB(255, 60, 60):Lerp(Color3.fromRGB(80, 255, 90), Ratio)
            Set.Bar.Visible = true
        else
            Set.BarBack.Visible, Set.Bar.Visible = false, false
        end

        local Center = (X1 + X2) / 2
        if Show.Name then
            Set.Name.Text = Target.Name
            Set.Name.Size, Set.Name.Color = TextSize, Color
            Set.Name.Position = Vector2.new(Center, Y1 - TextSize - 2)
            Set.Name.Visible = true
        else
            Set.Name.Visible = false
        end

        -- บรรทัดล่าง: ระยะ / เลือด / ข้อมูลผู้เล่น (Clan + ของที่ถือ) / เวลาเกิดบอส
        local Parts = { }
        if Target.Timer then table.insert(Parts, "respawn " .. Clock(Target.Timer)) end
        if Show.Distance then
            local Position = Target.Point or Target.Part.Position
            table.insert(Parts, string.format("%dm", math.floor((Position - Origin()).Magnitude)))
        end
        if Show.Health and Humanoid then
            table.insert(Parts, string.format("%d/%d", math.floor(Humanoid.Health), math.floor(Humanoid.MaxHealth)))
        end
        if Show.Info and Target.Model then
            local Clan = Target.Model:GetAttribute("Clan")
            if Clan and Clan ~= "" then table.insert(Parts, tostring(Clan)) end
            local Tool = Target.Model:FindFirstChildOfClass("Tool")
            if Tool then table.insert(Parts, Tool.Name) end
        end
        if #Parts > 0 then
            Set.Info.Text = table.concat(Parts, " | ")
            Set.Info.Size, Set.Info.Color = TextSize - 1, Color3.fromRGB(230, 230, 230)
            Set.Info.Position = Vector2.new(Center, Y2 + 2)
            Set.Info.Visible = true
        else
            Set.Info.Visible = false
        end

        if Show.Tracer then
            local View = Camera.ViewportSize
            local From = V.TracerFrom
            local Start = From == "Center" and Vector2.new(View.X / 2, View.Y / 2)
                or From == "Top" and Vector2.new(View.X / 2, 0)
                or From == "Mouse" and UserInputService:GetMouseLocation()
                or Vector2.new(View.X / 2, View.Y)
            Set.Tracer.From, Set.Tracer.To = Start, Vector2.new(Center, Y2)
            Set.Tracer.Color, Set.Tracer.Visible = Color, true
        else
            Set.Tracer.Visible = false
        end
    end

    local Targets, LastScan = { }, 0
    getgenv().ValkyrieVisual = { Pool = Pool, Targets = function() return Targets end }     -- ดูสดผ่าน dex

    TrackConnection(RunService.RenderStepped:Connect(function()
        if getgenv().ValkyrieSession ~= SessionToken then return end
        local Camera = workspace.CurrentCamera
        if not Camera then return end
        if V.FOVEnabled then Camera.FieldOfView = tonumber(V.FOV) or 90 end

        local Now = os.clock()
        if not AnyEnabled() then
            if next(Pool) then
                for Key, Set in pairs(Pool) do Destroy(Set) Pool[Key] = nil end
            end
            return
        end
        if Now - LastScan >= 0.25 then
            LastScan = Now
            local Ok, List = pcall(Scan)
            Targets = Ok and List or { }
        end

        for _, Target in ipairs(Targets) do
            local Set = Objects(Target.Key)
            Set.Seen = Now
            local Ok = pcall(Draw, Camera, Target, Set)
            if not Ok then Hide(Set) end
        end
        for Key, Set in pairs(Pool) do
            if Set.Seen ~= Now then
                Hide(Set)
                if Now - (Set.Seen or 0) > 3 then
                    Destroy(Set)
                    Pool[Key] = nil
                end
            end
        end
    end))

    ---- World: Fullbright / No Fog (คืนค่าเดิมตอนปิด) ----

    local Saved = { Light = nil, Fog = nil, Atmospheres = { }, FOV = nil }

    local function ApplyWorld()
        if V.Fullbright then
            if not Saved.Light then
                Saved.Light = { Brightness = Lighting.Brightness, Ambient = Lighting.Ambient,
                    OutdoorAmbient = Lighting.OutdoorAmbient, GlobalShadows = Lighting.GlobalShadows }
            end
            Lighting.Brightness = 2
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
            Lighting.GlobalShadows = false
        elseif Saved.Light then
            for Key, Value in pairs(Saved.Light) do pcall(function() Lighting[Key] = Value end) end
            Saved.Light = nil
        end

        if V.NoFog then
            if not Saved.Fog then Saved.Fog = { FogStart = Lighting.FogStart, FogEnd = Lighting.FogEnd } end
            Lighting.FogStart, Lighting.FogEnd = 1e6, 1e6
            for _, Atmosphere in ipairs(Lighting:GetChildren()) do
                if Atmosphere:IsA("Atmosphere") then
                    if not Saved.Atmospheres[Atmosphere] then
                        Saved.Atmospheres[Atmosphere] = { Density = Atmosphere.Density, Haze = Atmosphere.Haze }
                    end
                    Atmosphere.Density, Atmosphere.Haze = 0, 0
                end
            end
        elseif Saved.Fog then
            for Key, Value in pairs(Saved.Fog) do pcall(function() Lighting[Key] = Value end) end
            for Atmosphere, Values in pairs(Saved.Atmospheres) do
                pcall(function() Atmosphere.Density, Atmosphere.Haze = Values.Density, Values.Haze end)
            end
            Saved.Fog, Saved.Atmospheres = nil, { }
        end
    end

    -- เกมเปลี่ยนแสงตาม biome/กลางวัน-คืนเรื่อย ๆ - ทับซ้ำทุก 0.5 วิระหว่างเปิด
    task.spawn(function()
        while getgenv().ValkyrieSession == SessionToken do
            pcall(ApplyWorld)
            task.wait()
        end
    end)

    VisualCleanup = function()
        for Key, Set in pairs(Pool) do Destroy(Set) Pool[Key] = nil end
        pcall(function() Holder:Destroy() end)
        -- คืนแสง/หมอกเดิม แต่ค่าที่เซฟยังเปิดไว้ (รันใหม่เปิดกลับเอง)
        local Fullbright, NoFog = V.Fullbright, V.NoFog
        V.Fullbright, V.NoFog = false, false
        pcall(ApplyWorld)
        V.Fullbright, V.NoFog = Fullbright, NoFog
        if Saved.FOV then pcall(function() workspace.CurrentCamera.FieldOfView = Saved.FOV end) end
    end

    ---- UI ----

    local VisualPage = Window:Page({ Name = "Visual", Icon = "eye", Columns = 2 })

    local SettingsSection = VisualPage:Section({
        Name = "ESP Settings",
        Description = "Shared by every ESP",
        Icon = "93142176757189",
        Side = 1
    })

    if not HasDrawing then
        SettingsSection:Label("Your executor has no Drawing API - only Chams will show")
    end

    SettingsSection:Slider({
        Name = "Max Distance", Flag = "SL2VisualMaxDistance", Min = 100, Max = 10000,
        Default = V.MaxDistance, Suffix = " studs",
        Callback = function(Value) V.MaxDistance = Value SaveConfiguration() end
    })

    SettingsSection:Slider({
        Name = "Text Size", Flag = "SL2VisualTextSize", Min = 10, Max = 24, Default = V.TextSize,
        Callback = function(Value) V.TextSize = Value SaveConfiguration() end
    })

    task.wait()

    SettingsSection:Dropdown({
        Name = "Box Style", Flag = "SL2VisualBoxStyle", Items = { "Box", "Corners" }, KeepOrder = true,
        Default = V.BoxStyle, Multi = false,
        Callback = function(Value)
            if type(Value) ~= "string" then return end
            V.BoxStyle = Value
            SaveConfiguration()
        end
    })

    SettingsSection:Dropdown({
        Name = "Tracer From", Flag = "SL2VisualTracerFrom", Items = { "Bottom", "Center", "Top", "Mouse" }, KeepOrder = true,
        Default = V.TracerFrom, Multi = false,
        Callback = function(Value)
            if type(Value) ~= "string" then return end
            V.TracerFrom = Value
            SaveConfiguration()
        end
    })

    SettingsSection:Slider({
        Name = "Chams Transparency", Flag = "SL2VisualChamsFill", Min = 0, Max = 100, Default = V.ChamsFill, Suffix = "%",
        Callback = function(Value) V.ChamsFill = Value SaveConfiguration() end
    })

    task.wait()

    local WorldSection = VisualPage:Section({
        Name = "World",
        Description = "Lighting and camera",
        Icon = "93142176757189",
        Side = 1
    })

    WorldSection:Toggle({
        Name = "Fullbright", Flag = "SL2VisualFullbright", Default = V.Fullbright == true,
        Callback = function(Value) V.Fullbright = Value == true SaveConfiguration() task.spawn(ApplyWorld) end
    })

    WorldSection:Toggle({
        Name = "No Fog", Flag = "SL2VisualNoFog", Default = V.NoFog == true,
        Callback = function(Value) V.NoFog = Value == true SaveConfiguration() task.spawn(ApplyWorld) end
    })

    WorldSection:Toggle({
        Name = "Custom FOV", Flag = "SL2VisualFOVEnabled", Default = V.FOVEnabled == true,
        Callback = function(Value)
            local Camera = workspace.CurrentCamera
            if Value and Camera and not Saved.FOV then Saved.FOV = Camera.FieldOfView end
            V.FOVEnabled = Value == true
            SaveConfiguration()
            if not Value and Saved.FOV and Camera then
                Camera.FieldOfView = Saved.FOV
                Saved.FOV = nil
            end
        end
    })

    WorldSection:Slider({
        Name = "Field of View", Flag = "SL2VisualFOV", Min = 30, Max = 120, Default = V.FOV,
        Callback = function(Value) V.FOV = Value SaveConfiguration() end
    })

    -- 1 section ต่อชนิดเป้า: เปิด/ปิด + เลือกสิ่งที่โชว์ + สี (สลับคอลัมน์ขวา/ซ้าย)
    for Index, Kind in ipairs(Kinds) do
        task.wait()
        local Entry = V[Kind.Key]
        local Section = VisualPage:Section({
            Name = Kind.Name,
            Description = "ESP",
            Icon = "93142176757189",
            Side = Index <= 4 and 2 or 1
        })

        Section:Toggle({
            Name = "ESP " .. Kind.Name, Flag = "SL2VisualOn" .. Kind.Key, Default = Entry.Enabled == true,
            Callback = function(Value) Entry.Enabled = Value == true SaveConfiguration() end
        })

        Section:Dropdown({
            Name = "Show", Flag = "SL2VisualShow" .. Kind.Key, Items = Kind.Options, KeepOrder = true,
            Default = Entry.Show, Multi = true,
            Callback = function(Value)
                if type(Value) ~= "table" then return end
                Entry.Show = Value
                Refresh(Kind.Key)
                SaveConfiguration()
            end
        })

        local Ok, Default = pcall(Color3.fromHex, Entry.Color)
        Section:Colorpicker({
            Name = "Color", Flag = "SL2VisualColor" .. Kind.Key, Default = Ok and Default or Kind.Color,
            Callback = function(Color)
                if typeof(Color) ~= "Color3" then return end
                Entry.Color = Color:ToHex()
                Refresh(Kind.Key)
                SaveConfiguration()
            end
        })
    end
end

---- ============ Combat (Auto Parry / Silent Aim / Camera Lock) ============ ----
--
-- ออกแบบให้ใช้กับผู้เล่นเป็นหลัก (NPC/บอสใช้ได้ด้วย) - ยืนยันสดผ่าน dex 2026-09-29:
--   กัน = ท่า "Blocking" ช่อง 1 (action "Skills_1st" คีย์ F) - InputHandler.VirtualPress/VirtualRelease("Skills_1st")
--         เหมือนปุ่มบนจอมือถือ ใช้ได้ทั้ง PC/มือถือ (Skill_Controller.Attempt_Hold ตรง ๆ = เซิร์ฟปล่อยเองใน 0.09 วิ)
--   กดแล้ว ~0.09 วิ values ของเรามี Blocking + ลูก Perfect (~0.1 วิ = parry ผู้เล่น) และ PerfectNpc (~0.27 วิ = parry NPC)
--   ศัตรู: ท่าตี (animation เล่นครั้งเดียว) เริ่มก่อนโดนจริง 0.08-0.3 วิ แล้ว EffectsEvent "<สไตล์>_Swings" (เลขคอมโบ) มาตอนโดน
--        สกิล: phase Startup/Windup/Start -> phase ตีจริง (Asteroid Startup -> Crash 1.27 วิ)
--   ท่าสะดุ้งตอนโดนตีก็เป็น animation เล่นครั้งเดียวเหมือนกัน -> "เรียนรู้" id ท่าตีจริง + เวลาถึงโดน จาก animation
--   ที่มี _Swings / phase สกิลตามมา (เก็บไว้ใน config) / เวลาสกิลเรียนจาก Start -> phase ตีครั้งแรกของสกิลนั้น
-- Silent Aim = ทุกสกิลเล็งผ่าน Platform_Handler.mousepos -> hook ของเรา (ValkyrieSilentAim) คืนจุดของเป้าใน FOV
local CombatCleanup = nil
do
    local Config = getgenv().ConfigurationTable
    local UserInputService = game:GetService("UserInputService")
    local InputHandler = nil
    pcall(function() InputHandler = require(ReplicatedStorage.CAM.Client.Components.Client.InputHandler) end)
    local SkillController = nil
    pcall(function() SkillController = require(ReplicatedStorage.CAM.Client.Controllers.Skill_Controller) end)
    local HasDrawing = typeof(Drawing) == "table" and pcall(function() Drawing.new("Line"):Remove() end)

    local C = type(Config.Combat) == "table" and Config.Combat or { }
    Config.Combat = C
    local Defaults = {
        Parry = false, ParryRange = 12, SkillRange = 30, ParryTargets = { "Players", "Mobs", "Bosses" },
        ParryHold = 0.25, ParrySkills = true, OnlyTargetingMe = true,
        LearnedAnims = { }, SkillTimings = { },
        SilentAim = false, AimTargets = { "Players", "Mobs", "Bosses" }, AimPart = "Body", FOV = 180,
        ShowFOV = true, AimFrom = "Auto", VisibleCheck = false, Prediction = 0,
        CamLock = false, LockKey = "Toggle only", LockSmooth = 35, TargetHud = true,
    }
    for Key, Value in pairs(Defaults) do
        if C[Key] == nil then C[Key] = type(Value) == "table" and table.clone(Value) or Value end
    end

    local function ToSet(List)
        local Set = { }
        for _, Name in ipairs(type(List) == "table" and List or { }) do Set[Name] = true end
        return Set
    end
    local ParrySet, AimSet = ToSet(C.ParryTargets), ToSet(C.AimTargets)
    -- Auto Block ถูกลบ (เหลือ Auto Parry อย่างเดียว) - เคลียร์ค่าเก่าในไฟล์เซฟ
    C.Block, C.BlockRelease = nil, nil
    C.ParryDelay = nil          -- Extra Delay ถูกลบ (เวลากดมาจาก preset ของเกมแล้ว)
    -- v4: LearnedAnims[id] = { K = "M1"/"Skill", T = วิจากท่าเริ่มถึงโดน } (เดิม true/"Skill" ไม่มีเวลา) - ล้างเรียนใหม่
    if C.LearnVersion ~= 4 then
        C.LearnedAnims, C.SkillTimings, C.LearnVersion = { }, { }, 4
    end

    local function Session() return getgenv().ValkyrieSession == SessionToken end

    -- โมเดลนี้เป็นศัตรูชนิดไหน: Players / Mobs / Bosses (nil = ไม่ใช่)
    local function Classify(Model)
        if typeof(Model) ~= "Instance" or not Model:IsA("Model") then return nil end
        local Player = Players:GetPlayerFromCharacter(Model)
        if Player then return Player ~= LocalPlayer and "Players" or nil end
        local Folder = Model.Parent
        if Folder and Folder.Parent and Folder.Parent.Name == "ActiveNpcs" then
            return Folder:FindFirstChild("BossInfo") and "Bosses" or "Mobs"
        end
        return nil
    end

    local function RootOf(Model)
        return Model and (Model:FindFirstChild("HumanoidRootPart") or Model.PrimaryPart)
    end

    local function Alive(Model)
        local Humanoid = Model and Model:FindFirstChildOfClass("Humanoid")
        return Humanoid ~= nil and Humanoid.Health > 0
    end

    ---- Auto Parry ----

    -- Parry = แตะสั้น ๆ (Parry Hold) แล้วปล่อยเลย ไม่ค้างตลอดคอมโบ: คูลดาวน์นับจากตอนปล่อย ค้างนาน = พร้อมช้า
    -- ติดคูลดาวน์ตอนหมัดแรกของชุดถัดไปทุกรอบ (วัดกับ Zuko: ค้างตามคอมโบ perfect 2/30 วิ) / Perfect = ศัตรูติดสตั้นคอมโบหยุดเอง
    -- วัดใหม่ 2026-09-29: คูลดาวน์นับจากตอน "ปล่อย" ~2.0 วิ (ค้าง 1.2 วิแล้วกดใหม่หลังปล่อย 1.8 = ไม่ขึ้น / 2.2 = ขึ้น,
    -- แตะ 0.3 วิ + 1.8 = ไม่ขึ้น / แตะ 0.6 + 2.0 = ขึ้น) -> ReadyAt ตั้งตอนปล่อย
    local GuardCooldown = 2.05
    local Guard = { Holding = false, Until = 0, Parries = 0, Last = "-", ReadyAt = 0, Since = 0, PauseUntil = 0 }
    local Learn = { LastAnim = { } }        -- [โมเดล] = { Id, At } animation ท่าล่าสุดของศัตรูตัวนั้น
    local Pending = { }                      -- [โมเดล .. สกิล] = เวลาเริ่มท่า (Start phase)
    local LearnDirty = false

    -- action ของ InputHandler ที่เป็นท่าของเราเอง (Combat = M1, Skills_2nd.. = สกิลช่อง 2-10, Skills_1st = ท่ากัน)
    local OwnActions = { "Combat", "Dash" }
    for _, Slot in ipairs({ "2nd", "3rd", "4th", "5th", "6th", "7th", "8th", "9th", "10th" }) do
        table.insert(OwnActions, "Skills_" .. Slot)
    end
    local MaxHold = 1.5      -- กันค้างต่อเนื่องได้นานสุด (วิ) สำหรับหมัดธรรมดา แล้วปล่อยเสมอ ไม่ค้างยาวจนตีไม่ได้
    -- เจอสกิล = ค้างจนสกิลจบ แล้วค้างต่อถ้าตัวเดิมเข้ามาตี M1 ต่อ (สกิลมักพลาดแล้วตามด้วยคอมโบ - ปล่อยหลังสกิล
    -- = คอมโบมาตอนติดคูลดาวน์ 2 วิพอดี) เงียบเกิน SkillTail ถึงปล่อย / ค้างรวมไม่เกิน SkillHoldMax
    local SkillTail = 0.7
    local SkillHoldMax = 4

    -- ถือเบ็ด / ดื่มยา / กำลังใช้สกิลของเราเอง = ไม่กัน (กันแล้วตัดท่าตัวเอง / เบ็ดไม่มีท่ากัน)
    local function CanGuard()
        local Character = LocalPlayer.Character
        if not (Character and Alive(Character)) then return false end
        if Farm.Potions and Farm.Potions.Busy then return false end
        local Accessories = Character:FindFirstChild("Tool_Accessories")
        if Accessories then
            for _, Item in ipairs(Accessories:GetChildren()) do
                if Item.Name:find("Fishing Rod") then return false end
            end
        end
        local Ok, Casting = pcall(Fighter.Casting)
        if Ok and Casting then return false end
        -- ดื่มยา/หลบ/สกิล/สลับอาวุธค้างอยู่ (HubAction ที่สำคัญกว่า Parry) = ไม่กัน
        if not HubAction.Allowed("Parry") then return false end
        if InputHandler == nil then return false end
        -- เรากำลังตี/ใช้สกิล/dash เอง (กดคีย์หรือปุ่มจอ) = ไม่กัน กันแล้วตัดท่าตัวเอง
        if os.clock() < Guard.PauseUntil then return false end
        for _, Action in ipairs(OwnActions) do
            local Down, Value = pcall(InputHandler.IsDown, Action)
            if Down and Value then return false end
        end
        return true
    end

    -- กดค้าง (หรือยืดเวลาที่ค้างอยู่) - ปล่อยใน Heartbeat เมื่อหมดเวลา
    local function Guarding(Seconds, Reason, Cap)
        if not CanGuard() then return end
        local Now = os.clock()
        if not Guard.Holding and Now < Guard.ReadyAt then return end     -- ติดคูลดาวน์ กดไปก็ไม่ขึ้น
        if not Guard.Holding then
            -- ผู้เล่นกดกันเองอยู่ (คีย์ F / ปุ่มจอ) = ไม่แย่ง
            local Down, Value = pcall(InputHandler.IsDown, "Skills_1st")
            if Down and Value then return end
            Guard.Since = Now
            Guard.Cap = MaxHold
        end
        Guard.Cap = math.max(Guard.Cap or MaxHold, Cap or MaxHold)
        Guard.Until = math.min(math.max(Guard.Until, Now + Seconds), Guard.Since + Guard.Cap)
        Guard.Last = Reason or Guard.Last
        if not Guard.Holding then
            if not HubAction.Claim("Parry", (Guard.Cap or MaxHold) + 1) then return end
            Guard.Holding = true
            Guard.Parries = Guard.Parries + 1
            pcall(InputHandler.VirtualPress, "Skills_1st")
        else
            HubAction.Claim("Parry", (Guard.Cap or MaxHold) + 1)
        end
    end

    -- ปล่อยเฉพาะที่เรากดเอง (VirtualPress = Input Touch ไม่มี Object) - ผู้เล่นกด F ค้างเองไม่ไปปล่อยให้
    local function ReleaseGuard()
        if not Guard.Holding then return end
        HubAction.Release("Parry")
        Guard.Holding = false
        Guard.Until = 0
        Guard.Focus = nil
        Guard.ReadyAt = os.clock() + GuardCooldown
        local Ok, Input = pcall(InputHandler.HeldInput, "Skills_1st")
        if Ok and Input ~= nil and Input ~= Enum.UserInputType.Touch then return end
        pcall(InputHandler.VirtualRelease, "Skills_1st")
        Guard.ReleasedAt = os.clock()
    end

    -- ตัวกันค้าง: HUD เกมตอนได้ "Up" (ไม่มี input object) สั่งปล่อยผ่าน Skill_Controller.UnHoldBoolean
    -- เฉพาะตอน SHC.Value == "Blocking" แล้วเท่านั้น - ปล่อยตอนท่ายังรอเซิร์ฟ (SHC en) = คำสั่งปล่อยหาย
    -- ท่ากันค้างไม่มีวันปล่อย (วัดสด: Blocking ขึ้นช้า 2 วิหลังปล่อยแล้วค้าง) -> ปล่อยไปแล้วยังเห็น
    -- SHC = Blocking อยู่ ย้ำ UnHoldBoolean (ทางปล่อยของเกมเอง) ไม่หลุดใน 0.4 วิ StopHold ตรง ๆ
    local function EnforceRelease()
        local Since = Guard.ReleasedAt
        if Guard.Holding or not Since or not SkillController then return end
        local Now = os.clock()
        if Now - Since > 4 then Guard.ReleasedAt = nil return end
        local Character = LocalPlayer.Character
        local SHC = Character and Character:FindFirstChild("SHC")
        if not (SHC and SHC.Value == "Blocking") then return end
        local Down, Value = pcall(InputHandler.IsDown, "Skills_1st")
        if Down and Value then Guard.ReleasedAt = nil return end      -- ผู้เล่นกดกันเองต่อ
        SkillController.UnHoldBoolean = true
        if Now - Since > 0.4 and SHC:GetAttribute("en") ~= true then
            pcall(SkillController.StopHold, "Blocking")
        end
    end

    -- เรากดตี/สกิล/dash เอง = ปล่อยกันทันที แล้วพักกันอัตโนมัติสั้น ๆ ให้ท่าออก (ทั้งคีย์ PC และปุ่มจอมือถือ)
    if InputHandler then
        for _, Action in ipairs(OwnActions) do
            pcall(function()
                TrackConnection(InputHandler.ListenTo(Action, function(State)
                    if State ~= "Down" then return end
                    Guard.PauseUntil = os.clock() + 0.45
                    ReleaseGuard()
                end))
            end)
        end
    end

    -- ระยะที่ท่าตีถึงตัวเรา: M1 = ParryRange / สกิล = SkillRange - ศัตรูเล่นท่าอยู่ไกลกว่านี้ตีไม่โดน ยังไม่กด
    local function RangeFor(Kind)
        if Kind == "Skill" then return tonumber(C.SkillRange) or 30 end
        return tonumber(C.ParryRange) or 12
    end

    -- ศัตรูตัวนี้ตีเราถึงไหม: อยู่ในระยะ Range (ผู้เล่นนับเสมอ) / NPC ไกลกว่า 10 studs ต้องไล่เราอยู่
    -- (อยู่ใน NpcsFollowing ของเรา) ถ้าเปิด Ignore Idle NPCs
    local function Threat(Model, Range)
        local Kind = Classify(Model)
        if not (Kind and ParrySet[Kind]) or not Alive(Model) then return nil end
        local Root, Mine = RootOf(Model), Movement.GetRoot()
        if not (Root and Mine) then return nil end
        local Distance = (Root.Position - Mine.Position).Magnitude
        if Distance > (Range or RangeFor("M1")) then return nil end
        if Kind ~= "Players" and C.OnlyTargetingMe and Distance > 10 then
            local Following = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("NpcsFollowing")
            local Chasing = false
            for _, Value in ipairs(Following and Following:GetChildren() or { }) do
                if Value:IsA("ObjectValue") and Value.Value == Model then Chasing = true break end
            end
            if not Chasing then return nil end
        end
        return Kind
    end

    -- เวลาค้างกัน = Parry Hold (ครอบหน้าต่าง Perfect + กันธรรมดาต่ออีกนิดถ้าจังหวะพลาด)
    local function HoldTime(Minimum)
        return math.max(tonumber(C.ParryHold) or 0.25, Minimum or 0)
    end

    -- กดก่อนโดนเท่าไร: กดแล้วถึงเซิร์ฟ ~ping + ให้จังหวะโดนตกกลางหน้าต่าง Perfect
    -- (ผู้เล่น Perfect ~0.1 วิ / NPC PerfectNpc ~0.27 วิ) - ภาพท่าที่เราเห็นช้ากว่าเซิร์ฟ ~ping/2 อยู่แล้ว
    local function LeadFor(Model)
        local Ping = 0.06
        pcall(function() Ping = math.clamp(LocalPlayer:GetNetworkPing(), 0.02, 0.3) end)
        local Window = Players:GetPlayerFromCharacter(Model) and 0.1 or 0.27
        return Ping + Window / 2
    end

    -- ท่า M1 ทุกสไตล์ของเกม (ไม่ต้องเรียน): Assets.Animations.<สไตล์>_Combat_Anims มี Swing_1..7 + Run_Hit
    --   Swing_6 = Updraft (กดกระโดดค้าง + ตี = งัดขึ้นฟ้า) / Swing_7 = ท่าจบกลางอากาศ / Run_Hit = วิ่ง/dash มาตีหมัดแรก
    -- เวลาโดนจริงตามโค้ดเกม (Main_Combat_Script_Client): เล่นท่าทันที รอ delay_before_swing แล้วส่ง Combat_Service
    -- ให้เซิร์ฟรออีก (delay_before_hit - run_swing_remove_on_first - delay_before_swing) / ความเร็วตี
    -- ผู้เล่น: _Swings มาถึงเราตอนเซิร์ฟได้รับคำสั่ง (= ช่วง swing) ไม่ใช่ตอนโดน -> เรียนเวลาจาก _Swings = กดเร็วไป
    local CombatPresets, ItemsInfo = nil, nil
    pcall(function() CombatPresets = require(ReplicatedStorage.CAM.Global.Combat_presets) end)
    pcall(function() ItemsInfo = require(ReplicatedStorage.CAM.Global.Collectibles.Items) end)
    local SwingAnims = { }       -- [id] = { Preset, Index, Run }
    pcall(function()
        local Folder = ReplicatedStorage.Assets.Animations
        for _, Set in ipairs(Folder:GetChildren()) do
            local Style = Set.Name:match("^(.*)_Combat_Anims$")
            local Preset = Style and CombatPresets and CombatPresets.Presets[Style]
            if Style and not Preset and CombatPresets then
                -- โฟลเดอร์ตั้งชื่อตามไอเท็ม (เช่น Cutlass) -> ใช้ CombatPreset ของไอเท็มนั้น
                local Info = ItemsInfo and ItemsInfo[Style]
                Preset = CombatPresets.Presets[type(Info) == "table" and Info.CombatPreset or "Regular Katana"]
            end
            if Preset then
                for _, Anim in ipairs(Set:GetChildren()) do
                    local Id = Anim:IsA("Animation") and tostring(Anim.AnimationId):match("%d+")
                    local Index = tonumber(Anim.Name:match("^Swing_(%d+)$"))
                    local Run = Anim.Name == "Run_Hit"
                    if Id and (Index or Run) and not SwingAnims[Id] then
                        SwingAnims[Id] = { Preset = Preset, Index = Index or 1, Run = Run }
                    end
                end
            end
        end
    end)

    local function SwingHitTime(Info, Model)
        local Preset = Info.Preset
        local Swing = (type(Preset.delay_before_swing) == "table" and Preset.delay_before_swing[Info.Index])
            or Preset.default_before_swing or CombatPresets.Default_Swing_Wait or 0
        local Hit = (type(Preset.delay_before_hit) == "table" and Preset.delay_before_hit[Info.Index])
            or Preset.default_before_hit or Swing
        local Remove = Info.Run and (Preset.run_swing_remove_on_first or 0) or 0
        local Speed = 1
        pcall(function() Speed = CombatPresets.attackSpeedMult(Players:GetPlayerFromCharacter(Model) or Model) end)
        return Swing + math.max(0, Hit - Remove - Swing) / math.max(tonumber(Speed) or 1, 0.25)
    end

    local function SwingLabel(Info)
        if Info.Run then return "Run Hit" end
        if Info.Index == 6 then return "Updraft" end
        return "M1 #" .. Info.Index
    end

    -- จำท่า: เวลาท่าเริ่มถึงโดน (เฉลี่ยกับที่เคยเห็น ให้นิ่งขึ้นเรื่อย ๆ)
    local function LearnAnim(Id, Kind, Delay)
        local Old = C.LearnedAnims[Id]
        if type(Old) == "table" and tonumber(Old.T) then
            Old.T = math.floor(((Old.T * 3 + Delay) / 4) * 1000) / 1000
        else
            C.LearnedAnims[Id] = { K = Kind, T = math.floor(Delay * 1000) / 1000 }
        end
        LearnDirty = true
    end

    -- ท่าที่กำลังมา (ต่อศัตรู 1 ตัว): ถึงเวลา From แล้วต้องอยู่ในระยะของท่านั้นก่อนถึงกด - ยังไกลก็รอดูต่อ
    -- จนหมดหน้าต่าง Until (ศัตรูพุ่งเข้ามากลางท่าก็ยังกันทัน / ท่าจบแล้วยังไกล = ไม่กดเสียคูลดาวน์เปล่า)
    local Strikes = { }
    local function StrikeStep()
        local Now = os.clock()
        for Model, Strike in pairs(Strikes) do
            if Now > Strike.Until or not Model.Parent then
                Strikes[Model] = nil
            elseif Now >= Strike.From and Threat(Model, Strike.Range) then
                Strikes[Model] = nil
                if Strike.Skill then
                    -- สกิล: ค้างโหมดสกิล จับตาตัวนี้ (ท่า/เอฟเฟกต์ของมันยืดเวลาค้างใน SkillFocus)
                    Guarding(HoldTime(math.max(Strike.Hold or 0, SkillTail)), Model.Name .. " · " .. Strike.Label, SkillHoldMax)
                    if Guard.Holding then Guard.Focus = { Model = Model, Track = Strike.Track } end
                else
                    Guarding(HoldTime(Strike.Hold), Model.Name .. " · " .. Strike.Label)
                end
            end
        end
    end

    -- ค้างโหมดสกิลอยู่: ตัวที่ปล่อยสกิลยังเล่นท่า / มีเอฟเฟกต์ / ตี M1 ต่อในระยะ = ยืดออกไปอีก SkillTail
    -- Swing = หมัดของคอมโบที่ตามมาถึงแล้ว -> จากนี้ยืดทีละ ComboTail (ปล่อยทันทีหลังหมัดสุดท้าย ให้คูลดาวน์
    -- เริ่มนับเร็ว ชุดถัดไปจะได้กดทัน) และเลิกค้างเพราะแค่ยืนใกล้/เดินเข้ามา
    local ComboTail = 0.45
    local function SkillFocus(Model, Track, Swing)
        local Focus = Guard.Holding and Guard.Focus
        if not (Focus and Focus.Model == Model) then return end
        if not Threat(Model, RangeFor("Skill")) then return end
        if Swing then Focus.Swung = true end
        if Track and not Focus.Swung then Focus.Track = Track end
        local Tail = Focus.Swung and ComboTail or SkillTail
        Guard.Until = math.min(math.max(Guard.Until, os.clock() + Tail), Guard.Since + Guard.Cap)
    end

    local function Arm(Model, Label, Kind, Lead, Window, Hold, Track)
        if not C.Parry then return end
        local From = os.clock() + math.max(0, Lead or 0)
        local Old = Strikes[Model]
        -- ท่าเดิมยังรออยู่และถึงก่อน = เก็บตัวเดิม (สกิลรู้เวลาไม่ให้หมัดที่มาทีหลังเลื่อนจังหวะออกไป)
        if Old and Old.From <= From and Old.Until >= From then return end
        Strikes[Model] = {
            Label = Label, Range = RangeFor(Kind), From = From, Until = From + (Window or 0.4), Hold = Hold,
            Skill = Kind == "Skill", Track = Track,
        }
        StrikeStep()
    end

    local StartPhases = { Start = true, Windup = true, Startup = true }

    local EffectsEvent = nil
    pcall(function() EffectsEvent = ReplicatedStorage.Communication.ServerAndClient.Effects.EffectsEvent.Event end)
    if EffectsEvent then
        TrackConnection(EffectsEvent.OnClientEvent:Connect(function(Name, Source, Phase)
            if not C.Parry or typeof(Source) ~= "Instance" then return end
            -- เรียนรู้ได้ไกลกว่าระยะกด (ท่าที่ตีพลาดก็ยังจำ id/เวลาไว้ใช้รอบหน้า) - กดจริงเช็คระยะใน Arm
            if not Threat(Source, math.max(RangeFor("M1"), RangeFor("Skill")) + 25) then return end
            Name = tostring(Name)
            local Now = os.clock()
            if Name == "Stunned_Effect" then
                -- ตัวที่เราค้างกันสกิลอยู่โดน Perfect จนติดสตั้น = คอมโบขาดแล้ว ปล่อยให้ตีกลับได้เลย
                if Phase == true and Guard.Focus and Guard.Focus.Model == Source then ReleaseGuard() end
                return
            end
            SkillFocus(Source, nil, Name:find("_Swings$") ~= nil)

            -- หมัดธรรมดา: animation ก่อนหน้า (ไม่เกิน 0.35 วิ) = ท่าตีจริง จำ id ไว้ รอบหน้ากันตั้งแต่ท่าเริ่ม
            if Name:find("_Swings$") then
                local Last = Learn.LastAnim[Source]
                local Fresh = Last and Now - Last.At <= 0.35
                local Preset = Fresh and SwingAnims[Last.Id]
                local Known = Fresh and (Preset or C.LearnedAnims[Last.Id])
                -- ท่า M1 ของเกมรู้เวลาจาก preset อยู่แล้ว ไม่ต้องเรียน (ผู้เล่น _Swings มาก่อนโดนจริง = เวลาผิด)
                if Fresh and not Preset then LearnAnim(Last.Id, "M1", Now - Last.At) end
                -- ยังไม่รู้จักท่านี้ = กันตอนนี้เลยถ้าอยู่ในระยะ (ช้าไปสำหรับ Perfect แต่กันหมัดต่อ ๆ ไปในคอมโบ)
                if not Known then Arm(Source, Name, "M1", 0, 0.25) end
                return
            end
            if not C.ParrySkills then return end

            local Key = Name
            if StartPhases[Phase] then
                Pending[Source] = { Key = Key, At = Now }
                local Timing = tonumber(C.SkillTimings[Key])
                if Timing then
                    -- รู้เวลาแล้ว: กดก่อนโดน LeadFor (ping + ครึ่งหน้าต่าง Perfect ของผู้เล่น/NPC)
                    -- ตอนนั้นต้องอยู่ในระยะสกิล ไม่งั้นรอดูต่ออีก 0.45 วิ
                    Arm(Source, Key, "Skill", math.max(0, Timing - LeadFor(Source)), 0.45)
                else
                    -- ยังไม่รู้เวลา: กันค้างสูงสุด MaxHold ตั้งแต่ศัตรูเข้าระยะสกิล (รอได้ 2.5 วิ) รอบหน้าค่อยตรงจังหวะ
                    Arm(Source, Key, "Skill", 0, 2.5, MaxHold)
                end
            else
                local Started = Pending[Source]
                if Started and Started.Key == Key and type(Phase) == "string" then
                    Pending[Source] = nil
                    if not C.SkillTimings[Key] then
                        C.SkillTimings[Key] = math.floor((Now - Started.At) * 1000) / 1000
                        LearnDirty = true
                    end
                elseif type(Phase) == "string" then
                    -- สกิลที่ไม่มี phase เริ่ม (QuickDraw_effs Slice -> โดนหลายทีใน 0.4 วิ): animation ที่มาก่อน
                    -- (ไม่เกิน 0.8 วิ) = ท่าสกิล จำเป็น "Skill" (ใช้ระยะสกิล) รอบหน้ากันตั้งแต่ท่าเริ่ม / รอบนี้กันเลย
                    local Last = Learn.LastAnim[Source]
                    local Fresh = Last and Now - Last.At <= 0.8
                    local Known = Fresh and C.LearnedAnims[Last.Id]
                    if Fresh and not Known then LearnAnim(Last.Id, "Skill", Now - Last.At) end
                    if not Known then Arm(Source, Key, "Skill", 0, 0.3, 0.5) end
                end
            end
        end))
    end

    -- ติด AnimationPlayed ให้ศัตรูที่อยู่ใกล้ (กวาดทุก 0.5 วิ) - id ที่เรียนแล้ว = parry ตั้งแต่ท่าเริ่ม
    local Watched = { }
    local function Watch(Model)
        if Watched[Model] then return end
        local Humanoid = Model:FindFirstChildOfClass("Humanoid")
        local Animator = Humanoid and Humanoid:FindFirstChildOfClass("Animator")
        if not Animator then return end
        Watched[Model] = Animator.AnimationPlayed:Connect(function(Track)
            if not C.Parry then return end
            -- ท่าตีไม่ได้แยกด้วย priority (วัดสด Raid Captain: หมัดแรก = Movement มาก่อน _Swings 0.18 วิ,
            -- หมัดอื่นมี Action4) -> เอาแค่ท่าเล่นครั้งเดียว (เดิน/วิ่ง/ยืนเป็น loop) ที่ไม่ใช่ Core
            local Ok, Skip = pcall(function() return Track.Looped or Track.Priority == Enum.AnimationPriority.Core end)
            if not Ok or Skip then return end
            local Id = tostring(Track.Animation.AnimationId):match("%d+")
            if not Id then return end
            Learn.LastAnim[Model] = { Id = Id, At = os.clock() }
            SkillFocus(Model, Track)
            -- ท่าที่จำไว้เริ่มเล่น -> กดก่อนจังหวะโดนที่จำไว้ LeadFor วิ (ต้องอยู่ในระยะของท่านั้นตอนกด รอได้ 0.5 วิ)
            local Learned = C.LearnedAnims[Id]
            local Swing = SwingAnims[Id]
            if Swing then
                -- ท่า M1 ของเกม (รวม Run Hit ที่เดิน/วิ่งมาตีเลย และ Updraft): กดก่อนเวลาโดนจริงตาม preset
                Arm(Model, SwingLabel(Swing), "M1", math.max(0, SwingHitTime(Swing, Model) - LeadFor(Model)), 0.5)
            elseif type(Learned) == "table" then
                local Kind = Learned.K == "Skill" and "Skill" or "M1"
                if Kind == "M1" or C.ParrySkills then
                    Arm(Model, Kind, Kind, math.max(0, (tonumber(Learned.T) or 0) - LeadFor(Model)), 0.5, nil, Track)
                end
            end
        end)
    end

    local function Unwatch(Model)
        if Watched[Model] then Watched[Model]:Disconnect() end
        Watched[Model] = nil
        Learn.LastAnim[Model] = nil
        Pending[Model] = nil
        Strikes[Model] = nil
    end

    task.spawn(function()
        while Session() do
            if C.Parry then
                local Mine = Movement.GetRoot()
                local Keep = { }
                if Mine then
                    local Range = math.max(RangeFor("M1"), RangeFor("Skill")) + 25
                    for _, Player in ipairs(Players:GetPlayers()) do
                        local Character = Player ~= LocalPlayer and Player.Character
                        local Root = RootOf(Character)
                        if Root and (Root.Position - Mine.Position).Magnitude <= Range then Keep[Character] = true end
                    end
                    for _, Mob in ipairs(Farm.IterMobs()) do
                        if (Mob.Root.Position - Mine.Position).Magnitude <= Range then Keep[Mob.Model] = true end
                    end
                end
                for Model in pairs(Keep) do Watch(Model) end
                for Model in pairs(Watched) do
                    if not Keep[Model] or not Model.Parent then Unwatch(Model) end
                end
            elseif next(Watched) then
                for Model in pairs(Watched) do Unwatch(Model) end
            end
            if LearnDirty then
                LearnDirty = false
                SaveConfiguration()
            end
            task.wait()
        end
    end)

    ---- Silent Aim / Camera Lock ----

    local Target = { Model = nil, Part = nil, Kind = nil }
    local LockHeld = false

    local function AimOrigin(Camera)
        local From = C.AimFrom
        if From == "Auto" then
            From = (UserInputService.TouchEnabled and not UserInputService.MouseEnabled) and "Center" or "Mouse"
        end
        if From == "Mouse" then return UserInputService:GetMouseLocation() end
        local View = Camera.ViewportSize
        return Vector2.new(View.X / 2, View.Y / 2)
    end

    local VisibleParams = RaycastParams.new()
    VisibleParams.FilterType = Enum.RaycastFilterType.Exclude

    local function AimPart(Model)
        if C.AimPart == "Head" then
            local Head = Model:FindFirstChild("Head")
            if Head then return Head end
        end
        return RootOf(Model)
    end

    local function Candidates()
        local List = { }
        if AimSet.Players then
            for _, Player in ipairs(Players:GetPlayers()) do
                local Character = Player ~= LocalPlayer and Player.Character
                if Character and Alive(Character) then table.insert(List, { Model = Character, Kind = "Players" }) end
            end
        end
        if AimSet.Mobs or AimSet.Bosses then
            for _, Mob in ipairs(Farm.IterMobs()) do
                local Kind = Mob.IsBoss and "Bosses" or "Mobs"
                if AimSet[Kind] then table.insert(List, { Model = Mob.Model, Kind = Kind }) end
            end
        end
        return List
    end

    -- เป้าที่ใกล้จุดเล็ง (เมาส์ / กลางจอ) ที่สุดในวง FOV
    local function PickTarget(Camera)
        local Origin = AimOrigin(Camera)
        local Radius = tonumber(C.FOV) or 180
        local Best, BestDistance = nil, math.huge
        local Ignore = { LocalPlayer.Character, workspace:FindFirstChild("Debree") }
        VisibleParams.FilterDescendantsInstances = Ignore
        for _, Entry in ipairs(Candidates()) do
            local Part = AimPart(Entry.Model)
            if Part then
                local Screen, OnScreen = Camera:WorldToViewportPoint(Part.Position)
                if OnScreen and Screen.Z > 0 then
                    local Distance = (Vector2.new(Screen.X, Screen.Y) - Origin).Magnitude
                    if Distance <= Radius and Distance < BestDistance then
                        local Visible = true
                        if C.VisibleCheck then
                            local From = Camera.CFrame.Position
                            local Hit = workspace:Raycast(From, Part.Position - From, VisibleParams)
                            Visible = not Hit or Hit.Instance:IsDescendantOf(Entry.Model)
                        end
                        if Visible then Best, BestDistance = { Model = Entry.Model, Part = Part, Kind = Entry.Kind }, Distance end
                    end
                end
            end
        end
        return Best
    end

    local function AimPoint()
        local Part = Target.Part
        if not (Part and Part.Parent and Alive(Target.Model)) then return nil end
        local Lead = (tonumber(C.Prediction) or 0) / 1000
        local Velocity = Part.AssemblyLinearVelocity
        return Part.Position + Vector3.new(Velocity.X, 0, Velocity.Z) * Lead
    end

    getgenv().ValkyrieSilentAim = function()
        if not (Session() and C.SilentAim) then return nil end
        local Camera = workspace.CurrentCamera
        if Camera and not (Target.Part and Target.Part.Parent) then
            local Picked = PickTarget(Camera)
            if Picked then Target.Model, Target.Part, Target.Kind = Picked.Model, Picked.Part, Picked.Kind end
        end
        return AimPoint()
    end

    local LockKeys = {
        ["Right Mouse (hold)"] = Enum.UserInputType.MouseButton2,
        ["Q (hold)"] = Enum.KeyCode.Q, ["E (hold)"] = Enum.KeyCode.E, ["C (hold)"] = Enum.KeyCode.C,
        ["X (hold)"] = Enum.KeyCode.X, ["Left Alt (hold)"] = Enum.KeyCode.LeftAlt,
    }
    local LockKeyNames = { "Toggle only", "Right Mouse (hold)", "Q (hold)", "E (hold)", "C (hold)", "X (hold)", "Left Alt (hold)" }

    local function IsLockInput(Input)
        local Want = LockKeys[C.LockKey]
        return Want ~= nil and (Input.KeyCode == Want or Input.UserInputType == Want)
    end
    TrackConnection(UserInputService.InputBegan:Connect(function(Input, Processed)
        if not Processed and IsLockInput(Input) then LockHeld = true end
    end))
    TrackConnection(UserInputService.InputEnded:Connect(function(Input)
        if IsLockInput(Input) then LockHeld = false end
    end))

    local function LockActive()
        if not C.CamLock then return false end
        return C.LockKey == "Toggle only" or LockHeld
    end

    -- วง FOV + ป้ายเป้า (Drawing)
    local Circle, Hud = nil, nil
    if HasDrawing then
        Circle = Drawing.new("Circle")
        Circle.Thickness, Circle.NumSides, Circle.Filled, Circle.Visible = 1.5, 64, false, false
        Circle.Color = Color3.fromRGB(255, 255, 255)
        Hud = Drawing.new("Text")
        Hud.Center, Hud.Outline, Hud.Size, Hud.Visible = true, true, 15, false
        Hud.Color = Color3.fromRGB(255, 220, 120)
    end

    TrackConnection(RunService.Heartbeat:Connect(function()
        StrikeStep()
        -- ท่าสกิลยังเล่นอยู่ = สกิลยังไม่จบ / ตัวนั้นยังประชิด (ระยะ M1) หรือกำลังเดินเข้าหาเรา = คอมโบกำลังตามมา ค้างต่อ
        -- (วัดกับ Zuko: QuickDraw จาก 12 studs -> เดินกลับมาตี M1 หลังสกิลจบ 1.4 วิ ไม่มีท่า/เอฟเฟกต์ระหว่างเดิน)
        local Focus = Guard.Holding and Guard.Focus
        if Focus and not Focus.Swung then
            local Ok, Playing = pcall(function() return Focus.Track and Focus.Track.IsPlaying end)
            local Root, Mine = RootOf(Focus.Model), Movement.GetRoot()
            local Distance = Root and Mine and (Root.Position - Mine.Position).Magnitude
            local Closing = Distance and Focus.Distance and Distance < Focus.Distance - 0.03
            if (Ok and Playing) or (Distance and Distance <= RangeFor("M1")) or Closing then SkillFocus(Focus.Model) end
            Focus.Distance = Distance
        end
        -- หมดเวลา / ท่าที่สำคัญกว่าจองเข้ามา (ดื่มยา/หลบ/สกิล) = ปล่อยกัน
        if Guard.Holding and (os.clock() >= Guard.Until or not HubAction.Allowed("Parry")) then ReleaseGuard() end
        if Guard.Holding and not CanGuard() then ReleaseGuard() end
        EnforceRelease()
    end))

    TrackConnection(RunService.RenderStepped:Connect(function()
        if not Session() then return end
        local Camera = workspace.CurrentCamera
        if not Camera then return end
        local Aiming = C.SilentAim or C.CamLock

        -- เลือกเป้าใหม่ทุกเฟรมตอนเล็งอยู่ (Camera Lock ค้างตัวเดิมจนตาย/หลุดวง)
        if Aiming then
            local Keep = LockActive() and Target.Part and Target.Part.Parent and Alive(Target.Model)
            if not Keep then
                local Picked = PickTarget(Camera)
                Target.Model, Target.Part, Target.Kind = Picked and Picked.Model, Picked and Picked.Part, Picked and Picked.Kind
            end
        else
            Target.Model, Target.Part, Target.Kind = nil, nil, nil
        end

        if LockActive() then
            local Point = AimPoint()
            if Point then
                local Alpha = math.clamp((tonumber(C.LockSmooth) or 35) / 100, 0.02, 1)
                local Goal = CFrame.lookAt(Camera.CFrame.Position, Point)
                Camera.CFrame = Camera.CFrame:Lerp(Goal, Alpha)
            end
        end

        if Circle then
            local Origin = AimOrigin(Camera)
            Circle.Visible = Aiming and C.ShowFOV == true
            Circle.Position, Circle.Radius = Origin, tonumber(C.FOV) or 180
            Circle.Color = Target.Part and Color3.fromRGB(255, 90, 90) or Color3.fromRGB(255, 255, 255)
            local Humanoid = Target.Model and Target.Model:FindFirstChildOfClass("Humanoid")
            if Aiming and C.TargetHud and Humanoid then
                local Mine = Movement.GetRoot()
                local Distance = (Mine and Target.Part) and (Target.Part.Position - Mine.Position).Magnitude or 0
                local Name = Target.Model.Name
                if Target.Kind ~= "Players" and Target.Model.Parent then Name = Target.Model.Parent.Name end
                Hud.Text = string.format("%s | %d/%d | %dm", Name, math.floor(Humanoid.Health), math.floor(Humanoid.MaxHealth), math.floor(Distance))
                Hud.Position = Origin + Vector2.new(0, (tonumber(C.FOV) or 180) + 8)
                Hud.Visible = true
            else
                Hud.Visible = false
            end
        end
    end))

    CombatCleanup = function()
        ReleaseGuard()
        for Model in pairs(Watched) do Unwatch(Model) end
        getgenv().ValkyrieSilentAim = nil
        if Circle then pcall(function() Circle:Remove() end) end
        if Hud then pcall(function() Hud:Remove() end) end
    end
    getgenv().ValkyrieCombat = { Guard = Guard, Target = Target, Config = C, Press = Guarding, CanGuard = CanGuard }     -- ดูสดผ่าน dex

    ---- UI ----

    local CombatPage = Window:Page({ Name = "Combat", Icon = "swords", Columns = 2 })

    local ParrySection = CombatPage:Section({ Name = "Auto Parry", Description = "Perfect-block incoming hits", Icon = "93142176757189", Side = 1 })

    local GuardLabel = ParrySection:Label("Parries: 0 · Learned: 0 moves")

    ParrySection:Toggle({
        Name = "Auto Parry", Description = "Blocks right as an attack lands (perfect block) - learns each attacker's moves and timing",
        Flag = "SL2CombatParry", Default = C.Parry == true,
        Callback = function(Value) C.Parry = Value == true SaveConfiguration() if not Value then ReleaseGuard() end end
    })

    ParrySection:Toggle({
        Name = "Parry Skills", Description = "Also parries skills, not just normal hits",
        Flag = "SL2CombatParrySkills", Default = C.ParrySkills == true,
        Callback = function(Value) C.ParrySkills = Value == true SaveConfiguration() end
    })

    ParrySection:Toggle({
        Name = "Ignore Idle NPCs", Description = "NPCs further than 10 studs only count when they are after you (players always count)",
        Flag = "SL2CombatOnlyMe", Default = C.OnlyTargetingMe == true,
        Callback = function(Value) C.OnlyTargetingMe = Value == true SaveConfiguration() end
    })

    task.wait()

    ParrySection:Dropdown({
        Name = "Parry Against", Flag = "SL2CombatParryTargets", Items = { "Players", "Mobs", "Bosses" }, KeepOrder = true,
        Default = C.ParryTargets, Multi = true,
        Callback = function(Value)
            if type(Value) ~= "table" then return end
            C.ParryTargets = Value
            ParrySet = ToSet(Value)
            SaveConfiguration()
        end
    })

    ParrySection:Slider({
        Name = "M1 Range", Description = "Only parry a normal hit when the attacker is this close",
        Flag = "SL2CombatParryRange", Min = 4, Max = 40, Default = C.ParryRange, Suffix = " studs",
        Callback = function(Value) C.ParryRange = Value SaveConfiguration() end
    })

    ParrySection:Slider({
        Name = "Skill Range", Description = "Only parry a skill when the caster is this close",
        Flag = "SL2CombatSkillRange", Min = 5, Max = 80, Default = C.SkillRange, Suffix = " studs",
        Callback = function(Value) C.SkillRange = Value SaveConfiguration() end
    })

    ParrySection:Slider({
        Name = "Parry Hold", Flag = "SL2CombatParryHold", Min = 0.1, Max = 1, Decimals = 0.05, Default = C.ParryHold, Suffix = "s",
        Callback = function(Value) C.ParryHold = Value SaveConfiguration() end
    })

    ParrySection:Button({
        Name = "Forget Learned Moves",
        Callback = function()
            C.LearnedAnims, C.SkillTimings = { }, { }
            SaveConfiguration()
            Library:Notify("Combat", "Learned attack moves cleared", 3)
        end
    })

    task.wait()

    local AimSection = CombatPage:Section({ Name = "Silent Aim", Description = "Skills fly to the target in your FOV", Icon = "93142176757189", Side = 2 })

    AimSection:Toggle({
        Name = "Silent Aim", Description = "Every skill you use aims at the target closest to your aim point inside the FOV circle",
        Flag = "SL2CombatSilentAim", Default = C.SilentAim == true,
        Callback = function(Value) C.SilentAim = Value == true SaveConfiguration() end
    })

    AimSection:Dropdown({
        Name = "Aim At", Flag = "SL2CombatAimTargets", Items = { "Players", "Mobs", "Bosses" }, KeepOrder = true,
        Default = C.AimTargets, Multi = true,
        Callback = function(Value)
            if type(Value) ~= "table" then return end
            C.AimTargets = Value
            AimSet = ToSet(Value)
            SaveConfiguration()
        end
    })

    AimSection:Dropdown({
        Name = "Aim Part", Flag = "SL2CombatAimPart", Items = { "Body", "Head" }, KeepOrder = true,
        Default = C.AimPart, Multi = false,
        Callback = function(Value) if type(Value) == "string" then C.AimPart = Value SaveConfiguration() end end
    })

    AimSection:Dropdown({
        Name = "Aim From", Description = "Auto is the mouse on PC and the screen center on mobile",
        Flag = "SL2CombatAimFrom", Items = { "Auto", "Mouse", "Center" }, KeepOrder = true,
        Default = C.AimFrom, Multi = false,
        Callback = function(Value) if type(Value) == "string" then C.AimFrom = Value SaveConfiguration() end end
    })

    task.wait()

    AimSection:Slider({
        Name = "FOV Radius", Flag = "SL2CombatFOV", Min = 30, Max = 800, Default = C.FOV, Suffix = " px",
        Callback = function(Value) C.FOV = Value SaveConfiguration() end
    })

    AimSection:Slider({
        Name = "Prediction", Description = "Leads moving targets by this much time",
        Flag = "SL2CombatPrediction", Min = 0, Max = 300, Default = C.Prediction, Suffix = " ms",
        Callback = function(Value) C.Prediction = Value SaveConfiguration() end
    })

    AimSection:Toggle({
        Name = "Visible Check", Description = "Skip targets behind walls",
        Flag = "SL2CombatVisible", Default = C.VisibleCheck == true,
        Callback = function(Value) C.VisibleCheck = Value == true SaveConfiguration() end
    })

    AimSection:Toggle({
        Name = "Show FOV Circle", Flag = "SL2CombatShowFOV", Default = C.ShowFOV == true,
        Callback = function(Value) C.ShowFOV = Value == true SaveConfiguration() end
    })

    AimSection:Toggle({
        Name = "Target Info", Description = "Name, health and distance of the current target under the circle",
        Flag = "SL2CombatHud", Default = C.TargetHud == true,
        Callback = function(Value) C.TargetHud = Value == true SaveConfiguration() end
    })

    task.wait()

    local LockSection = CombatPage:Section({ Name = "Camera Lock", Description = "Keep the camera on the target", Icon = "93142176757189", Side = 2 })

    LockSection:Toggle({
        Name = "Camera Lock", Description = "Turns the camera to the target (uses the Silent Aim targets and FOV)",
        Flag = "SL2CombatCamLock", Default = C.CamLock == true,
        Callback = function(Value) C.CamLock = Value == true SaveConfiguration() end
    })

    LockSection:Dropdown({
        Name = "Lock Key", Description = "Toggle only is always on while enabled (mobile); other keys lock while held",
        Flag = "SL2CombatLockKey", Items = LockKeyNames, KeepOrder = true, Default = C.LockKey, Multi = false,
        Callback = function(Value) if type(Value) == "string" then C.LockKey = Value LockHeld = false SaveConfiguration() end end
    })

    LockSection:Slider({
        Name = "Smoothness", Description = "Lower is smoother, 100 is an instant snap",
        Flag = "SL2CombatLockSmooth", Min = 2, Max = 100, Default = C.LockSmooth, Suffix = "%",
        Callback = function(Value) C.LockSmooth = Value SaveConfiguration() end
    })

    -- สถานะ: นับครั้งที่กัน + ท่าที่เรียนแล้ว
    task.spawn(function()
        while Session() do
            local Moves = 0
            for _ in pairs(C.LearnedAnims) do Moves = Moves + 1 end
            local Skills = 0
            for _ in pairs(C.SkillTimings) do Skills = Skills + 1 end
            pcall(function()
                GuardLabel:SetText(string.format("Parries: %d · Last: %s · Learned: %d moves, %d skills",
                    Guard.Parries, tostring(Guard.Last), Moves, Skills))
            end)
            task.wait()
        end
    end)
end

Window:Category("Misc")

local MiscPage = Window:Page({ Name = "Auto Puzzle", Icon = "puzzle", Columns = 2 })

--// Travel - วาร์ป/บินไป Zone / NPC / Shrine
--
-- ยืนยันผ่าน dex: ReplicatedStorage.Regions (โมดูลเดียวกับแผนที่ย่อของเกม) มีครบทุกอย่างไม่ติด streaming
--   Regions.Regions[โซน] = { Spawns = { Vector3 }, CrystalAt = CFrame, Shrines = { { Name, At = CFrame } },
--     Npcs = { { Name, Type } }, Area = { Grid = { { Center = Vector2 (X,Z), YLimits } } } }
--   Npcs.Type: 1 = NPC คุยได้ / 3 = NPC พิเศษ (Muzan, Ren) / 2 = มอน-บอส / nil = ของ (กล่อง ฯลฯ) - เอาแค่ 1, 3
--   Regions.GetNpcSpawn(ชื่อ) = ตำแหน่ง NPC (Vector3) ทุกตัว
--   จุดของโซน: Spawns[1] > CrystalAt > Shrine แรก > NPC ตัวแรก > กลาง Area (ยิง ray หาพื้นหลังโหลดรอบจุด)
do
    local Config = getgenv().ConfigurationTable
    local TravelPage = Window:Page({ Name = "Travel", Icon = "map-pin", Columns = 2 })

    local Regions = nil
    pcall(function() Regions = require(ReplicatedStorage.Regions) end)

    local Zones, Npcs, Shrines = { }, { }, { }   -- ชื่อ -> เป้าหมาย (ดูรูปแบบข้างล่าง)

    -- โซนที่ไม่มีจุดเกิด (Verdant Cliffs / Stone Sanctuary / Forgotten Ruins / Final Selection Plains) มีแค่ Area
    -- วัดสด: RequestStreamAroundAsync จากไกล ๆ คืนทันทีแต่ไม่โหลดอะไร - ต้องพาตัวไปลอยเหนือกลางโซนก่อน
    -- (ตรึงไว้ให้ streaming โหลดรอบตัว) แล้วยิง ray หาพื้น: กลาง Area + 8 จุดรอบ ๆ ที่ครึ่งรัศมี
    -- ray ข้ามของที่เดินทะลุได้ (RespectCanCollide) - วัดสด Verdant Cliffs: โดนใบไม้ Y ~1200 ก่อน พื้นจริง ~595
    -- (ต่ำกว่า YLimits ของโซนเอง ใช้ YLimits แค่เป็นความสูงลอยรอ ไม่ใช้กรองพื้น)
    local function AreaInfo(Area)
        local Grid = Area and Area.Grid and Area.Grid[1]
        if not (Grid and typeof(Grid.Center) == "Vector2") then return nil end
        local Limits = typeof(Grid.YLimits) == "Vector2" and Grid.YLimits or nil
        return {
            Center = Grid.Center,
            Radius = typeof(Grid.Radius) == "Vector2" and Grid.Radius or Vector2.new(300, 300),
            Limits = Limits,
            HoverY = Limits and Limits.Y or 1500,
        }
    end

    local function FindGround(Info)
        local Params = RaycastParams.new()
        Params.FilterType = Enum.RaycastFilterType.Exclude
        Params.FilterDescendantsInstances = { LocalPlayer.Character }
        Params.RespectCanCollide = true

        for Index = 0, 8 do
            local Angle = Index / 8 * math.pi * 2
            local X = Info.Center.X + (Index == 0 and 0 or math.cos(Angle) * Info.Radius.X * 0.5)
            local Z = Info.Center.Y + (Index == 0 and 0 or math.sin(Angle) * Info.Radius.Y * 0.5)
            local Hit = workspace:Raycast(Vector3.new(X, Info.HoverY + 50, Z), Vector3.new(0, -(Info.HoverY + 1000), 0), Params)
            if Hit then return Hit.Position end
        end
        return nil
    end

    -- Zones[ชื่อ] = { At = Vector3 } (จุดตายตัว) หรือ { Area = AreaInfo, Npc = Vector3? } (หาพื้นตอนไปถึง)
    -- Npcs / Shrines [ชื่อ] = { At = Vector3 }
    if type(Regions) == "table" and type(Regions.Regions) == "table" then
        for ZoneName, Region in pairs(Regions.Regions) do
            local FirstNpc = nil

            for _, Npc in ipairs(Region.Npcs or { }) do
                if type(Npc) == "table" and type(Npc.Name) == "string" and (Npc.Type == 1 or Npc.Type == 3) then
                    local Ok, At = pcall(Regions.GetNpcSpawn, Npc.Name)
                    if Ok and typeof(At) == "Vector3" then
                        Npcs[Npc.Name] = { At = At }
                        FirstNpc = FirstNpc or At
                    end
                end
            end

            local FirstShrine = nil
            for _, Shrine in ipairs(Region.Shrines or { }) do
                if type(Shrine) == "table" and type(Shrine.Name) == "string" and typeof(Shrine.At) == "CFrame" then
                    Shrines[Shrine.Name] = { At = Shrine.At.Position }
                    FirstShrine = FirstShrine or Shrine.At.Position
                end
            end

            if ZoneName ~= "Misc" then
                local Spawn = Region.Spawns and Region.Spawns[1]
                local Fixed = (typeof(Spawn) == "Vector3" and Spawn)
                    or (typeof(Region.CrystalAt) == "CFrame" and Region.CrystalAt.Position)
                    or FirstShrine
                local Info = AreaInfo(Region.Area)
                if Fixed then
                    Zones[ZoneName] = { At = Fixed }
                elseif Info then
                    -- NPC ของโซนบางทีอยู่ขอบโซน (Final Selection Plains ห่างกลาง ~1,300) - ใช้เมื่อหาพื้นไม่เจอเท่านั้น
                    Zones[ZoneName] = { Area = Info, Npc = FirstNpc }
                elseif FirstNpc then
                    Zones[ZoneName] = { At = FirstNpc }
                end
            end
        end
    end

    local function Names(Map)
        local List = { }
        for Name in pairs(Map) do table.insert(List, Name) end
        table.sort(List)
        if #List == 0 then List = { "None" } end
        return List
    end

    local Travel = { Token = 0 }

    -- ปิดโหมดที่ขยับตัวละครอยู่ก่อน (ไม่งั้นลูปฟาร์มดึงกลับ) แล้ววาร์ปไป
    local function TravelTo(Label, Target)
        if type(Target) ~= "table" then return end
        Travel.Token = Travel.Token + 1
        local Token = Travel.Token

        TurnOffFlags(ExclusiveFlags.Farm)
        TurnOffFlags(ExclusiveFlags.Breathing)
        TurnOffFlags(ExclusiveFlags.Puzzle)
        TurnOffFlags(ExclusiveFlags.Fishing)
        TurnOffFlags(ExclusiveFlags.Quest)

        task.spawn(function()
            local function Continue()
                return Token == Travel.Token and getgenv().ValkyrieSession == SessionToken
            end

            Movement.Lock(nil)

            local Position = Target.At
            if not Position and Target.Area then
                -- ลอยเหนือกลางโซนรอ streaming แล้วหาพื้น (สูงสุด ~4 วิ)
                local Info = Target.Area
                local Hover = CFrame.new(Info.Center.X, Info.HoverY, Info.Center.Y)
                pcall(Movement.Go, Hover, 8, 180, Continue)
                Movement.Lock(Hover)
                local Deadline = os.clock() + 4
                while Continue() and os.clock() < Deadline and not Position do
                    task.wait()
                    Position = FindGround(Info)
                end
                Movement.Lock(nil)
                Position = Position or Target.Npc
            end

            if Continue() and typeof(Position) == "Vector3" then
                pcall(function() LocalPlayer:RequestStreamAroundAsync(Position, 5) end)
                pcall(Movement.Go, CFrame.new(Position + Vector3.new(0, 4, 0)), 4, 180, Continue)
            end
            Movement.Cancel()   -- Teleport ทิ้ง noclip ไว้ = ร่วงทะลุพื้น (เหมือน Auto Unlock Fishing)

            if Continue() and typeof(Position) ~= "Vector3" then
                task.wait() -- เพิ่งเรียก API เกม - คั่นก่อนสร้าง UI แจ้งเตือน
                Library:Notify("Travel", Label .. ": position not found", 4)
            end
        end)
    end

    task.wait()

    local TravelSection = TravelPage:Section({
        Name = "Teleport",
        Description = "Zones, NPCs and shrines",
        Icon = "80758916183665",
        Side = 1
    })

    -- dropdown + ปุ่มวาร์ป 1 ชุดต่อหมวด (Zone / NPC / Shrine) - เลือกค้างไว้เซฟลง config
    local function TeleportRow(Title, Flag, Key, Map, Last)
        local List = Names(Map)
        local Saved = Config[Key]
        if not table.find(List, Saved) then Saved = List[1] end
        Config[Key] = Saved

        TravelSection:Dropdown({
            Name = "Select " .. Title,
            Flag = Flag,
            Items = List,
            Default = Saved,
            Multi = false,
            Seperator = false,
            Callback = function(Value)
                if type(Value) ~= "string" then return end
                Config[Key] = Value
                SaveConfiguration()
            end
        })

        TravelSection:Button({
            Name = "Teleport to " .. Title,
            Callback = function()
                local Name = Config[Key]
                TravelTo(tostring(Name), Map[Name])
            end
        })

        if not Last then TravelSection:Divider() end
        task.wait()
    end

    TeleportRow("Zone", "SL2TravelZone", "TravelZone", Zones)
    TeleportRow("NPC", "SL2TravelNpc", "TravelNpc", Npcs)
    TeleportRow("Shrine", "SL2TravelShrine", "TravelShrine", Shrines, true)

    --// Quest Target - ไปจุดของ task ที่ทำอยู่ในเควสที่รับไว้
    --
    -- ยืนยันผ่าน dex (ไล่ครบ 203 task ในเกม - หาจุดได้ทุก task ยกเว้นแบบนับดาเมจ/นับรอบ):
    --   Quests.GetTaskMarker(ข้อมูลเควส, task) = { Position } หรือ { Npc = ชื่อ } (+ จุดสถานีเทรนของเกมเอง)
    --   ไม่มี marker: TaskSpecs.Positions (Pickup) / TaskSpecs.TargetNpc / Code เป็นชื่อมอน (เช่น "BearCub"
    --   -> "Bear Cub" เทียบแบบตัดช่องว่าง) / สุดท้าย OfferNpc (task ส่งของ Deposit ส่งที่คนให้เควส)
    --   task ปัจจุบัน = ตัวแรกที่ยังไม่ครบและ Need (task ก่อนหน้า) ครบแล้ว / ครบทุก task = กลับไปส่งที่ OfferNpc
    local Quests, Utility = nil, nil
    pcall(function() Quests = require(ReplicatedStorage.CAM.Global.Subsets.Gameplay.Quests) end)
    pcall(function() Utility = require(ReplicatedStorage.CAM.Global.Utility) end)

    local function SquashName(Text)
        return (tostring(Text):lower():gsub("[^%w]", ""))
    end

    local SpawnIndex = nil
    local function SpawnByName(Name)
        if not (Regions and type(Name) == "string" and Name ~= "") then return nil end
        local Ok, At = pcall(Regions.GetNpcSpawn, Name)
        if Ok and typeof(At) == "Vector3" then return At end

        if not SpawnIndex then
            SpawnIndex = { }
            for SpawnName, Position in pairs(Regions.NpcSpawns or { }) do
                if typeof(Position) == "Vector3" then SpawnIndex[SquashName(SpawnName)] = Position end
            end
        end
        local Key = SquashName(Name)
        if Key == "" then return nil end
        if SpawnIndex[Key] then return SpawnIndex[Key] end
        for SpawnKey, Position in pairs(SpawnIndex) do
            if SpawnKey:sub(1, #Key) == Key then return Position end
        end
        return nil
    end

    local function QuestHolder()
        local Ok, Holder = pcall(function() return Utility.GetData(LocalPlayer, true).Quests.Holder end)
        return Ok and Holder or nil
    end

    local function ActiveQuests()
        local List = { }
        local Holder = QuestHolder()
        for _, Quest in ipairs(Holder and Holder:GetChildren() or { }) do
            local IdValue = Quest:FindFirstChild("QuestString")
            List[Quest.Name] = { Instance = Quest, Id = IdValue and IdValue.Value or Quest.Name }
        end
        return List
    end

    local function TaskDone(Task)
        local Value, Max = Task:FindFirstChild("Value"), Task:FindFirstChild("Max")
        return Value ~= nil and Max ~= nil and Value.Value >= Max.Value
    end

    local function CurrentTask(Quest)
        local Tasks = Quest:FindFirstChild("Tasks")
        for _, Task in ipairs(Tasks and Tasks:GetChildren() or { }) do
            local Need = Task:FindFirstChild("Need")
            local Before = Need and Tasks:FindFirstChild(Need.Value)
            if not TaskDone(Task) and (not Before or TaskDone(Before)) then return Task end
        end
        return nil
    end

    -- คืน ตำแหน่ง, ข้อความ (ชื่อ task ที่จะไปทำ)
    local function QuestTarget(Entry)
        local Def = Quests and select(2, pcall(Quests.GetQuestInfo, Entry.Id))
        if type(Def) ~= "table" then return nil, "Quest data not found" end

        local Task = CurrentTask(Entry.Instance)
        if not Task then
            return SpawnByName(Def.OfferNpc), "Turn in at " .. tostring(Def.OfferNpc)
        end

        local Ok, Marker = pcall(Quests.GetTaskMarker, Def, Task)
        if Ok and type(Marker) == "table" then
            if typeof(Marker.Position) == "Vector3" then return Marker.Position, Task.Name end
            local At = SpawnByName(Marker.Npc)
            if At then return At, Task.Name end
        end

        local Spec = Def.TaskSpecs and Def.TaskSpecs[Task.Name]
        if type(Spec) == "table" then
            if type(Spec.Positions) == "table" then
                for Slot, Position in ipairs(Spec.Positions) do
                    if typeof(Position) == "Vector3" and not Task:GetAttribute("Picked" .. Slot) then
                        return Position, Task.Name
                    end
                end
            end
            local At = SpawnByName(Spec.TargetNpc)
            if At then return At, Task.Name end
        end

        local Code = Task:FindFirstChild("Code")
        local Plain = Task.Name:gsub("^Defeat%s+", ""):gsub("^[Tt]he%s+", "")
        local At = SpawnByName(Code and Code.Value) or SpawnByName(Task.Name) or SpawnByName(Plain)
        if At then return At, Task.Name end

        return SpawnByName(Def.OfferNpc), Task.Name .. " (at " .. tostring(Def.OfferNpc) .. ")"
    end

    TravelSection:Divider()

    local SelectedQuest = nil
    local QuestDropdown = TravelSection:Dropdown({
        Name = "Select Quest",
        Flag = "SL2TravelQuest",
        Items = { "None" },
        Default = "None",
        Multi = false,
        Seperator = false,
        Callback = function(Value)
            if type(Value) == "string" then SelectedQuest = Value end
        end
    })

    local QuestLabel = TravelSection:Label("Target: -")

    TravelSection:Button({
        Name = "Teleport to Quest Target",
        Callback = function()
            task.spawn(function()
                local Quests2 = ActiveQuests()
                local Entry = Quests2[SelectedQuest or ""]
                if not Entry then
                    -- ยังไม่ได้เลือก / เควสที่เลือกจบไปแล้ว = เอาเควสแรกที่รับอยู่
                    local Names2 = { }
                    for Name in pairs(Quests2) do table.insert(Names2, Name) end
                    table.sort(Names2)
                    Entry = Quests2[Names2[1] or ""]
                end

                local Position, Text = nil, "No active quest"
                if Entry then Position, Text = QuestTarget(Entry) end
                task.wait() -- GetData = thread เสีย capability ชั่วคราว - คั่นก่อนแตะ UI
                QuestLabel:SetText("Target: " .. tostring(Text))

                if typeof(Position) == "Vector3" then
                    TravelTo(tostring(Text), { At = Position })
                else
                    Library:Notify("Travel", tostring(Text) .. ": position not found", 4)
                end
            end)
        end
    })

    -- รายชื่อเควสใน dropdown ตามที่รับอยู่จริง (รับ/ส่ง/ทิ้งเควส = รีเฟรชเอง)
    local function RefreshQuests()
        local List = { }
        for Name in pairs(ActiveQuests()) do table.insert(List, Name) end
        table.sort(List)
        if #List == 0 then List = { "None" } end
        if not table.find(List, SelectedQuest) then SelectedQuest = List[1] ~= "None" and List[1] or nil end
        task.wait()
        pcall(function() QuestDropdown:Refresh(List, SelectedQuest or "None") end)
    end

    task.spawn(function()
        local Holder = nil
        local Deadline = os.clock() + 60     -- รอทีละเฟรม นานสุด 60 วิ (เดิมนับ 60 รอบ x 1 วิ)
        while os.clock() < Deadline do
            Holder = QuestHolder()
            if Holder or getgenv().ValkyrieSession ~= SessionToken then break end
            task.wait()
        end
        if not Holder then return end
        RefreshQuests()
        local function Queue()
            if getgenv().ValkyrieSession ~= SessionToken then return end
            task.defer(RefreshQuests)
        end
        TrackConnection(Holder.ChildAdded:Connect(Queue))
        TrackConnection(Holder.ChildRemoved:Connect(Queue))
    end)

    --// Waypoints - เซฟจุดที่ยืนอยู่ตอนนี้ตั้งชื่อเอง แล้ววาร์ปกลับทีหลัง (เซฟลง config ข้าม session)
    task.wait()

    local WaypointSection = TravelPage:Section({
        Name = "Waypoints",
        Description = "Save your position, come back later",
        Icon = "80758916183665",
        Side = 2
    })

    if type(Config.TravelWaypoints) ~= "table" then Config.TravelWaypoints = { } end

    local PendingName = ""
    local SelectedWaypoint = nil

    local function WaypointNames()
        local List = { }
        for _, Point in ipairs(Config.TravelWaypoints) do
            if type(Point) == "table" and type(Point.Name) == "string" then table.insert(List, Point.Name) end
        end
        if #List == 0 then List = { "None" } end
        return List
    end

    local function FindWaypoint(Name)
        for Index, Point in ipairs(Config.TravelWaypoints) do
            if type(Point) == "table" and Point.Name == Name then return Point, Index end
        end
        return nil
    end

    local NameBox = WaypointSection:Textbox({
        Name = "Waypoint Name",
        Placeholder = "Empty is Waypoint 1, 2, ...",
        Flag = "SL2WaypointName",
        Callback = function(Text)
            PendingName = tostring(Text or "")
        end
    })

    local WaypointDropdown = nil

    local function RefreshWaypoints(Select)
        local List = WaypointNames()
        SelectedWaypoint = (Select and table.find(List, Select) and Select)
            or (table.find(List, SelectedWaypoint) and SelectedWaypoint) or (List[1] ~= "None" and List[1] or nil)
        if WaypointDropdown then
            pcall(function() WaypointDropdown:Refresh(List, SelectedWaypoint or "None") end)
        end
    end

    WaypointSection:Button({
        Name = "Set Waypoint",
        Callback = function()
            local Root = Movement.GetRoot()
            if not Root then return end

            -- อ่านจากช่องตรง ๆ ด้วย (callback ของ textbox ยิงตอน FocusLost - พิมพ์แล้วกดปุ่มเลยอาจยังไม่ได้ค่า)
            local Typed = PendingName
            pcall(function() Typed = NameBox.items[ "input" ].Text end)
            local Name = tostring(Typed or ""):gsub("^%s+", ""):gsub("%s+$", "")
            if Name == "" or Name == "None" then
                local Index = #Config.TravelWaypoints + 1
                repeat
                    Name = "Waypoint " .. Index
                    Index = Index + 1
                until not FindWaypoint(Name)
            end

            local Position = Root.Position
            local Point = FindWaypoint(Name)
            if Point then
                Point.X, Point.Y, Point.Z = Position.X, Position.Y, Position.Z -- ชื่อเดิม = ย้ายจุด
            else
                table.insert(Config.TravelWaypoints, { Name = Name, X = Position.X, Y = Position.Y, Z = Position.Z })
            end
            SaveConfiguration()
            RefreshWaypoints(Name)
            Library:Notify("Waypoint", string.format("Saved %s (%.0f, %.0f, %.0f)", Name, Position.X, Position.Y, Position.Z), 4)
        end
    })

    WaypointSection:Divider()

    WaypointDropdown = WaypointSection:Dropdown({
        Name = "Select Waypoint",
        Flag = "SL2TravelWaypoint",
        Items = WaypointNames(),
        Default = WaypointNames()[1],
        Multi = false,
        KeepOrder = true,
        Seperator = false,
        Callback = function(Value)
            if type(Value) == "string" then SelectedWaypoint = Value end
        end
    })
    SelectedWaypoint = WaypointNames()[1] ~= "None" and WaypointNames()[1] or nil

    WaypointSection:Button({
        Name = "Teleport to Waypoint",
        Callback = function()
            local Point = FindWaypoint(SelectedWaypoint)
            if not Point then return end
            TravelTo(Point.Name, { At = Vector3.new(Point.X, Point.Y, Point.Z) })
        end
    })

    WaypointSection:Button({
        Name = "Delete Waypoint",
        Callback = function()
            local _, Index = FindWaypoint(SelectedWaypoint)
            if not Index then return end
            table.remove(Config.TravelWaypoints, Index)
            SaveConfiguration()
            SelectedWaypoint = nil
            RefreshWaypoints()
        end
    })
end

--// Auto Puzzle - workspace.Map.Puzzles (ปลดล็อก Schematic อาวุธ/หน้ากาก Nightfall / Firstlight)
--
-- ยืนยันสดทุกแบบ (dex_exec + decompile PlayerScripts.Ouwland.WorldEvents):
--   StudyProp (tag) = ของโชว์ attribute Item เช่น "Nightfall Katana" มี ProximityPrompt "Study" hold 3 วิ
--     ระยะ 10 - ถือจนครบ = ได้ "<Item> Schematic" เข้ากระเป๋า (ทดสอบสด: Nightfall Katana Schematic)
--     prompt ปิดเองถ้ามี schematic แล้ว หรือ attribute Locked (ตอนนี้มีแค่ Nightfall Sickles)
--   Sickles Levers (tag SicklesLever) 10 อัน กระจายทั้งแมพ - prompt "Pull" hold 3 วิ ระยะ 15
--     ต้อง hold จริง (Triggered เช็คว่า PromptButtonHoldBegan มาก่อน) ดึงครบ = ท่อระบายเลื่อนเปิด
--     ปลด Locked ของ NF sickles (ฝั่ง client ทั้งหมด - นับเฉพาะ session นี้ rejoin ต้องดึงใหม่)
--   FLLanternPlates (tag SimonPlate, SimonIndex 1-9) = เควส "Ill walk the order" ของ Lamplighter Isamu
--     รับผ่านบทสนทนาเท่านั้น (ยิง AddQuest ตรง ๆ เซิร์ฟเงียบ) แล้วเซิร์ฟส่ง SimonSaysController.handle
--     { Action = "Show", Plates = {...}, Lead, Step } ทีละรอบ 5 รอบ -> กระโดดลงแผ่นตามลำดับ (ต้อง "ตกลง"
--     บนแผ่นจริง วาร์ปวางเฉย ๆ ไม่นับ) เซิร์ฟตอบ Step / Fail (เควสรีเซ็ต) / Win -> Firstlight Lantern Schematic
--     บางทีเซิร์ฟตอบช้า > 2 วิ ห้ามรีบไปแผ่นถัดไปก่อนได้ Step ไม่งั้นลำดับเพี้ยน Fail
--   Serpent Box (tag SerpentBox) ต้องถือ "Serpent Key" (tag SerpentKey) - จุดเกิดกุญแจไม่มีใน config
--     (โฟลเดอร์ Serpent Keys ว่างถ้าไม่ได้อยู่ใกล้) เลยเก็บเฉพาะกุญแจที่โหลดอยู่ตอนนั้น
--   IceveilFootPrints ยังไม่รู้กลไก - ข้าม
--
-- ตำแหน่งทุกอย่างใช้ WorldPivot ของโมเดลเปลือก (streaming เอาชิ้นส่วนออกแต่เปลือก + tag + attribute อยู่ครบ)
-- toggle ทำรอบเดียวจบแล้วปิดตัวเอง - ของที่ได้แล้วข้ามหมด เปิดใหม่ได้เรื่อย ๆ
do
    local CollectionService = game:GetService("CollectionService")
    local VirtualInput = game:GetService("VirtualInputManager")
    local GuiService = game:GetService("GuiService")

    -- Step = กำลังทำอะไร / Log = ที่ทำสำเร็จในรอบนี้ (โชว์ในหน้า Auto Puzzle)
    local Puzzle = { Active = false, Thread = nil, Step = "-", Log = { } }

    local function Note(Text)
        table.insert(Puzzle.Log, 1, os.date("%H:%M") .. " " .. Text)
        while #Puzzle.Log > 8 do table.remove(Puzzle.Log) end
    end

    local function ShouldRun()
        return getgenv().ValkyrieSession == SessionToken and Puzzle.Active
    end

    local function PuzzleFolder()
        local Map = workspace:FindFirstChild("Map")
        return Map and Map:FindFirstChild("Puzzles")
    end

    local function Tagged(Tag)
        local List = { }
        local Folder = PuzzleFolder()
        if not Folder then return List end
        for _, Inst in ipairs(Folder:GetDescendants()) do
            if Inst:IsA("Model") and CollectionService:HasTag(Inst, Tag) then
                table.insert(List, Inst)
            end
        end
        return List
    end

    local function PromptPosition(Prompt, Fallback)
        local Holder = Prompt.Parent
        if Holder and Holder:IsA("Attachment") then return Holder.WorldPosition end
        if Holder and Holder:IsA("BasePart") then return Holder.Position end
        return Fallback
    end

    -- บินไปที่เปลือก ขอ stream รอบจุดนั้น แล้วรอ prompt ของมันโหลด (คืน prompt หรือ nil)
    local function Reach(Shell, Timeout)
        local Position = Shell.WorldPivot.Position
        Movement.Lock(nil)
        Movement.Go(Position + Vector3.new(0, 5, 0), 8, 120, ShouldRun)
        if not ShouldRun() then return nil end

        pcall(function() LocalPlayer:RequestStreamAroundAsync(Position, 5) end)

        local Deadline = os.clock() + (Timeout or 6)
        while ShouldRun() and os.clock() < Deadline do
            local Prompt = Shell:FindFirstChildWhichIsA("ProximityPrompt", true)
            if Prompt then return Prompt end
            task.wait()
        end
        return nil
    end

    -- ถือ prompt จนครบ HoldDuration แบบคนกดจริง (PromptButtonHoldBegan -> Triggered)
    local function HoldPrompt(Prompt, Fallback)
        local Position = PromptPosition(Prompt, Fallback)
        Movement.Lock(CFrame.new(Position + Vector3.new(0, 2, 3), Position))
        task.wait(0.4)

        Prompts.Use(Prompt, { Hold = true })

        task.wait(0.6)
        Movement.Lock(nil)
    end

    local function WaitFor(Check, Timeout)
        local Deadline = os.clock() + Timeout
        while ShouldRun() and os.clock() < Deadline do
            if Check() then return true end
            task.wait()
        end
        return Check()
    end

    ---- Sickles Levers ----

    local function PullLevers()
        local Pulled = 0
        local Levers = Tagged("SicklesLever")
        for Index, Lever in ipairs(Levers) do
            if not ShouldRun() then break end

            Puzzle.Step = string.format("Pulling sickle lever %d/%d", Index, #Levers)
            local Prompt = Reach(Lever)
            local Handle = Lever:FindFirstChild("A_")
            if Prompt and Handle and not Handle:GetAttribute("On") and Prompt.Enabled then
                HoldPrompt(Prompt, Lever.WorldPivot.Position)
                WaitFor(function() return Handle:GetAttribute("On") == true end, 2)
            end
            if Handle and Handle:GetAttribute("On") then Pulled = Pulled + 1 end
        end
        Note(string.format("Sickle levers %d/%d", Pulled, #Levers))
        return Pulled
    end

    ---- Study props ----

    local function StudyAll(Missing)
        local Props = Tagged("StudyProp")
        local Done = 0

        for _, Prop in ipairs(Props) do
            if not ShouldRun() then break end

            local Item = Prop:GetAttribute("Item")
            if type(Item) == "string" and not Farm.HasItem(Item .. " Schematic") then
                if Item == "Nightfall Sickles" then
                    local Pulled = PullLevers()
                    if Pulled < #Tagged("SicklesLever") then
                        table.insert(Missing, string.format("%s (levers %d/%d)", Item, Pulled, #Tagged("SicklesLever")))
                    end
                end

                Puzzle.Step = "Studying " .. Item
                local Prompt = Reach(Prop)
                -- Sickles: ท่อระบายเลื่อนเปิด 3 วิหลังดึงคันโยกครบ แล้ว prompt ค่อยเปิด
                if Prompt then WaitFor(function() return Prompt.Enabled end, 6) end

                if Prompt and Prompt.Enabled then
                    HoldPrompt(Prompt, Prop.WorldPivot.Position)
                    WaitFor(function() return Farm.HasItem(Item .. " Schematic") end, 3)
                end

                if Farm.HasItem(Item .. " Schematic") then
                    Done = Done + 1
                    Note("Studied " .. Item)
                elseif Item ~= "Nightfall Sickles" then
                    table.insert(Missing, Item)
                end
            end
        end

        return Done
    end

    ---- Simon plates (Lamplighter Isamu) ----

    local SimonQuest = "Ill walk the order"
    local SimonReward = "Firstlight Lantern Schematic"

    -- ดัก SimonSaysController.handle ครั้งเดียวต่อเกม (inject ซ้ำไม่ซ้อน) เก็บ event ลงคิวแล้วส่งต่อของเดิม
    local function SimonQueue()
        local Queue = getgenv().ValkyrieSimonQueue
        if type(Queue) ~= "table" then
            Queue = { }
            getgenv().ValkyrieSimonQueue = Queue
        end

        if not getgenv().ValkyrieSimonHooked then
            local Ok, Controller = pcall(function()
                return require(ReplicatedStorage.CAM.Client.Controllers.SimonSaysController)
            end)
            if Ok and type(Controller) == "table" and type(Controller.handle) == "function" then
                local Original = Controller.handle
                Controller.handle = function(Data, ...)
                    if type(Data) == "table" then
                        table.insert(getgenv().ValkyrieSimonQueue, Data)
                    end
                    return Original(Data, ...)
                end
                getgenv().ValkyrieSimonHooked = true
            end
        end

        return Queue
    end

    local function DialogueFrame()
        local Holder = LocalPlayer.PlayerGui:FindFirstChild("ComponentsHolder")
        local Frame = Holder and Holder:FindFirstChild("DialogueFrame")
        return (Frame and Frame.Visible) and Frame or nil
    end

    local function RealClick(Button)
        local Inset = GuiService:GetGuiInset()
        local Point = Button.AbsolutePosition + Button.AbsoluteSize / 2
        pcall(function()
            VirtualInput:SendMouseButtonEvent(Point.X + Inset.X, Point.Y + Inset.Y, 0, true, game, 1)
            task.wait(0.08)
            VirtualInput:SendMouseButtonEvent(Point.X + Inset.X, Point.Y + Inset.Y, 0, false, game, 1)
        end)
    end

    -- กดบทสนทนาไปจนเจอตัวเลือกที่ต้องการ (ตัวอื่นกดตัวแรกที่ไม่ใช่ Close / Not yet)
    local function TalkAndPick(Choice)
        for _ = 1, 14 do
            local Frame = DialogueFrame()
            if not Frame then return false end

            local Holder = nil
            for _, Child in ipairs(Frame:GetDescendants()) do
                if Child.Name == "ButtonHolder" then Holder = Child end
            end

            local Pick, Fallback = nil, nil
            for _, Child in ipairs(Holder and Holder:GetChildren() or { }) do
                local Button = Child:IsA("GuiObject") and Child:FindFirstChildOfClass("TextButton")
                if Button and Button.Visible then
                    local Label = Child:FindFirstChild("Actual")
                    Label = Label and Label:FindFirstChild("TextLabel")
                    local Text = Label and Label.Text or Child.Name
                    if Text:find(Choice, 1, true) then
                        Pick = Button
                    elseif not Fallback and Text ~= "Close" and Text ~= "Not yet" then
                        Fallback = Button
                    end
                end
            end

            if Pick then
                RealClick(Pick)
                task.wait(1)
                return true
            end

            local Target = Fallback
            if not Target then
                for _, Child in ipairs(Frame:GetDescendants()) do
                    if Child:IsA("TextButton") and Child.Name == "ClickDetector" then Target = Child end
                end
            end
            if Target then RealClick(Target) end
            task.wait(0.7)
        end
        return false
    end

    local function SimonState()
        return Farm.GetQuestState(SimonQuest)
    end

    local function AcceptSimon()
        local Npc = workspace:FindFirstChild("Debree")
        Npc = Npc and Npc:FindFirstChild("Regions")
        Npc = Npc and Npc:FindFirstChild("Misc")
        Npc = Npc and Npc:FindFirstChild("StationaryNpcs")
        Npc = Npc and Npc:FindFirstChild("Lamplighter Isamu")
        local Root = Npc and Npc:FindFirstChild("HumanoidRootPart")
        if not Root then return false end

        Movement.Lock(nil)
        Movement.Go(Root.Position + Root.CFrame.LookVector * 4, 4, 60, ShouldRun)
        Movement.Cancel()

        local Prompt = Root:FindFirstChildOfClass("ProximityPrompt")
        if Prompt and not DialogueFrame() then
            Prompts.Use(Prompt, { Check = function() return DialogueFrame() ~= nil end, Continue = ShouldRun })
            task.wait(1.2)
        end

        TalkAndPick(SimonQuest)
        return WaitFor(function() return SimonState() == "Doing" end, 3)
    end

    local function SimonPlate(Index)
        for _, Plate in ipairs(Tagged("SimonPlate")) do
            if Plate:GetAttribute("SimonIndex") == Index then
                return Plate:FindFirstChild("Base")
            end
        end
        return nil
    end

    -- ตกลงบนแผ่น (สูง 6 studs ใส่ความเร็วลง) - ต้องปล่อยตัวละครอิสระ (Movement.Cancel คืน Freefall ให้)
    -- ไม่งั้น humanoid ไม่ "ลงพื้น" เซิร์ฟไม่นับ
    local function DropOn(Plate)
        local Root = Movement.GetRoot()
        if not Root then return end
        Root.CFrame = CFrame.new(Plate.Position + Vector3.new(0, 6, 0))
        Root.AssemblyLinearVelocity = Vector3.new(0, -30, 0)
    end

    -- เล่น 1 ครั้ง (5 รอบ) คืน "Win" / "Fail" / nil (หมดเวลา/ถูกสั่งหยุด)
    -- เควสค้าง Doing จากรอบก่อน (ลำดับที่โชว์ไปแล้วหายไป) = ไม่มี Show มาอีก - เงียบเกิน 8 วิ
    -- เหยียบแผ่นมั่วให้มัน Fail แล้วรับเควสใหม่ได้ลำดับสด ๆ
    local function PlaySimon(Queue)
        local Deadline = os.clock() + 120
        local LastEvent = os.clock()

        while ShouldRun() and os.clock() < Deadline do
            local Event = table.remove(Queue, 1)
            if Event then LastEvent = os.clock() end

            if not Event then
                if os.clock() - LastEvent > 8 then
                    local Plate = SimonPlate(1)
                    if Plate then DropOn(Plate) end
                    LastEvent = os.clock()
                end
                task.wait()
            elseif Event.Action == "Win" or Event.Action == "Fail" then
                return Event.Action
            elseif Event.Action == "Show" and type(Event.Plates) == "table" then
                local Step = tonumber(Event.Step) or 0.8
                task.wait((tonumber(Event.Lead) or 1) + #Event.Plates * Step + 0.2)

                for _, Index in ipairs(Event.Plates) do
                    local Plate = SimonPlate(Index)
                    if not Plate or not ShouldRun() then return nil end

                    -- รอคำตอบของแผ่นนี้ก่อน (Step / Show รอบถัดไป / Win / Fail) - ช้าก็รอ ไม่ข้าม
                    local Mark = #Queue
                    DropOn(Plate)
                    if not WaitFor(function() return #Queue > Mark end, 4) then
                        DropOn(Plate)
                        WaitFor(function() return #Queue > Mark end, 4)
                    end

                    -- Step ของแผ่นนี้ตัดทิ้งได้ ที่เหลือ (Show/Win/Fail) ปล่อยให้ลูปนอกจัดการ
                    while Queue[1] and Queue[1].Action == "Step" do table.remove(Queue, 1) end
                    local Next = Queue[1]
                    if Next and (Next.Action == "Fail" or Next.Action == "Win" or Next.Action == "Show") then break end
                end
            end
        end
        return nil
    end

    local function DoSimon()
        if Farm.HasItem(SimonReward) or SimonState() == "Done" then return true end

        local Queue = SimonQueue()

        for _ = 1, 3 do
            if not ShouldRun() then return false end

            table.clear(Queue)
            Puzzle.Step = "Lantern plates: talking to Lamplighter Isamu"
            if SimonState() ~= "Doing" and not AcceptSimon() then
                task.wait(1)
            else
                Puzzle.Step = "Lantern plates: following the order"
                local Result = PlaySimon(Queue)
                if Result == "Win" then
                    WaitFor(function() return Farm.HasItem(SimonReward) end, 3)
                    Note("Solved lantern plates")
                    return true
                end
                if Result == "Fail" then Note("Lantern plates failed, retrying") end
            end
        end
        return Farm.HasItem(SimonReward)
    end

    ---- Serpent Box ----

    local SerpentReward = "Nightfall Serpent Katana Schematic"

    local function DoSerpent()
        if Farm.HasItem(SerpentReward) then return true end

        -- จุดเกิดกุญแจไม่รู้ล่วงหน้า - เอาเฉพาะดอกที่โหลดอยู่ (prompt เปิด = ยังไม่มีกุญแจในกระเป๋า)
        Puzzle.Step = "Serpent Box: looking for a Serpent Key"
        if not Farm.HasItem("Serpent Key") then
            for _, Key in ipairs(CollectionService:GetTagged("SerpentKey")) do
                local Prompt = Key:FindFirstChildWhichIsA("ProximityPrompt", true)
                if Prompt and Prompt.Enabled and ShouldRun() then
                    local Position = Key:IsA("Model") and Key:GetPivot().Position or Key.Position
                    Movement.Go(Position + Vector3.new(0, 4, 0), 6, 120, ShouldRun)
                    HoldPrompt(Prompt, Position)
                    if WaitFor(function() return Farm.HasItem("Serpent Key") end, 3) then break end
                end
            end
        end
        if not Farm.HasItem("Serpent Key") then return false end

        local Folder = PuzzleFolder()
        local Box = Folder and Folder:FindFirstChild("Serpent Box")
        if not Box then return false end

        Puzzle.Step = "Serpent Box: opening"
        local Prompt = Reach(Box)
        if Prompt then WaitFor(function() return Prompt.Enabled end, 3) end
        if Prompt and Prompt.Enabled then
            HoldPrompt(Prompt, Box.WorldPivot.Position)
            if WaitFor(function() return Farm.HasItem(SerpentReward) end, 3) then Note("Opened Serpent Box") end
        end
        return Farm.HasItem(SerpentReward)
    end

    ---- runner ----

    local SetPuzzle

    -- วนจนเก็บครบ: error / ยังไม่ครบ (เช่นกุญแจ Serpent ยังไม่เกิด) = ไม่ปิด toggle เอง รอ 15 วิแล้วไล่ใหม่
    -- ปิดเองเฉพาะเก็บครบทุกอย่างแล้ว
    local function RunPuzzle()
        Fighter.Continue = nil
        local Notified = nil

        while ShouldRun() do
            local Missing = { }
            local Ok, Err = pcall(function()
                local Studied = StudyAll(Missing)
                if ShouldRun() and not DoSimon() then table.insert(Missing, (SimonReward:gsub(" Schematic", ""))) end
                if ShouldRun() and not DoSerpent() then table.insert(Missing, "Serpent Box (no Serpent Key loaded)") end
                return Studied
            end)

            Movement.Cancel()
            if not ShouldRun() then break end

            if Ok and #Missing == 0 then
                Puzzle.Step = "All collected"
                Library:Notify("Auto Puzzle", "All puzzle schematics collected", 6)
                break
            end

            local Why = not Ok and ("Error: " .. tostring(Err):sub(1, 60)) or ("Not done: " .. table.concat(Missing, ", "))
            Puzzle.Step = Why .. " - retrying in 15s"
            if Notified ~= Why then       -- แจ้งเตือนครั้งเดียวต่อเหตุผลเดิม ไม่เด้งทุกรอบ
                Notified = Why
                Library:Notify("Auto Puzzle", Why .. " - will keep trying", 8)
            end
            Farm.Sleep(15, ShouldRun)
        end

        Puzzle.Thread = nil
        if Puzzle.Active then SetPuzzle(false, true) end
    end

    SetPuzzle = function(Value, SyncToggle)
        if Value then
            TurnOffFlags(ExclusiveFlags.Farm)
            TurnOffFlags(ExclusiveFlags.Breathing)
            TurnOffFlags(ExclusiveFlags.Fishing)
            TurnOffFlags(ExclusiveFlags.Quest)
            TurnOffFlags(ExclusiveFlags.Puzzle, "SL2AutoPuzzle")
            Puzzle.Active = true
            if not Puzzle.Thread then Puzzle.Thread = task.spawn(RunPuzzle) end
        else
            Puzzle.Active = false
            Movement.Cancel()
            if SyncToggle then
                local Set = Library.SetFlags and Library.SetFlags["SL2AutoPuzzle"]
                if Set then pcall(Set, false) end
            end
        end
    end

    task.wait()

    local PuzzleSection = MiscPage:Section({
        Name = "Auto Puzzle",
        Description = "Puzzles: study props, sickle levers, lantern plates",
        Icon = "80758916183665",
        Side = 1
    })

    local ProgressSection = MiscPage:Section({
        Name = "Puzzle Progress",
        Description = "Schematics you already have",
        Icon = "80758916183665",
        Side = 2
    })

    local StepLabel = PuzzleSection:Label("Status: -")
    local CountLabel = PuzzleSection:Label("Collected: -", true)

    PuzzleSection:Toggle({
        Name = "Auto Unlock Puzzle",
        Description = "Runs once through every puzzle, skips what you already have, then turns off",
        Flag = "SL2AutoPuzzle",
        Default = getgenv().ConfigurationTable.AutoPuzzle == true,
        Seperator = true,
        Callback = function(Value)
            getgenv().ConfigurationTable.AutoPuzzle = Value == true   -- เซฟ = รันใหม่เปิดกลับเอง
            SaveConfiguration()
            SetPuzzle(Value)
        end
    })

    local LogLabel = PuzzleSection:Label("This session: -")
    local ChecklistLabel = ProgressSection:Label("-")

    -- รายการ puzzle ทั้งหมด = StudyProp ในแมพ (ได้ "<Item> Schematic") + Lantern plates + Serpent Box
    -- ของได้เข้ากระเป๋าถาวร เช็คจากกระเป๋า / คันโยกเป็นของฝั่ง client นับเฉพาะรอบนี้
    local StudyItems = nil
    task.spawn(function()
        while getgenv().ValkyrieSession == SessionToken do
            if not StudyItems or #StudyItems == 0 then
                StudyItems = { }
                for _, Prop in ipairs(Tagged("StudyProp")) do
                    local Item = Prop:GetAttribute("Item")
                    if type(Item) == "string" and not table.find(StudyItems, Item) then table.insert(StudyItems, Item) end
                end
                table.sort(StudyItems)
            end

            local Entries = { }
            for _, Item in ipairs(StudyItems) do table.insert(Entries, { Item, Item .. " Schematic" }) end
            table.insert(Entries, { "Firstlight Lantern (plates)", SimonReward })
            table.insert(Entries, { "Nightfall Serpent Katana (box)", SerpentReward })

            local Lines, Have = { }, 0
            for _, Entry in ipairs(Entries) do
                local Owned = Farm.HasItem(Entry[2])
                if Owned then Have = Have + 1 end
                table.insert(Lines, string.format('<font color="%s">%s</font>', Owned and "#78DC78" or "#8C8C8C", Entry[1]))
            end

            local Levers, On = Tagged("SicklesLever"), 0
            for _, Lever in ipairs(Levers) do
                local Handle = Lever:FindFirstChild("A_")
                if Handle and Handle:GetAttribute("On") then On = On + 1 end
            end

            local Step = "Status: " .. Puzzle.Step
            local Count = string.format("Collected: %d/%d · Sickle levers: %d/%d", Have, #Entries, On, #Levers)
            local Log = "This session: " .. (#Puzzle.Log > 0 and ("\n" .. table.concat(Puzzle.Log, "\n")) or "-")
            local Checklist = #StudyItems > 0 and ('<font color="#78DC78">Green</font> is collected · <font color="#8C8C8C">Gray</font> is not yet\n\n'
                .. table.concat(Lines, "\n")) or "Puzzle area not loaded"

            task.wait() -- GetData = thread เสีย capability ชั่วคราว - คั่นก่อนแตะ UI
            pcall(function()
                StepLabel:SetText(Step)
                CountLabel:SetText(Count)
                LogLabel:SetText(Log)
                ChecklistLabel:SetRichText(Checklist)
            end)
            task.wait()
        end
    end)
end

--// Region Discovery - เก็บโซนใน Archives.Regions ให้ครบ (หน้า Archives + หมุดบนแผนที่ย่อ)
--
-- ยืนยันสด (dex):
--   รายชื่อ = Regions.Regions ที่มี Area.Grid (โซนหลัก) + ChildAreas ของทุกช่อง Grid (โซนย่อย/ถ้ำ)
--   ที่ค้นพบแล้ว = Player_Service.Data.<ชื่อผู้เล่น>.Archives.Regions (StringValue คั่นด้วย ",")
--   เซิร์ฟเช็คตำแหน่งเอง (AreaLocator) ไม่มี remote - ไปยืนในโซนแล้วติดใน ~0.6 วิ (Veilfall Cavern)
--   Center ของโซนย่อยในตารางไม่ตรงกับที่ Locator ใช้จริง (Veilfall Cavern: ตาราง -600,457 แต่ Locate
--   ตรงจริงแถว -850,290,450) -> หาจุดในโซนด้วย Locator.Locate สแกนทั้งแมพ ใช้จุดที่ตรงซึ่งใกล้จุดเฉลี่ยสุด
--   ไม่มีรางวัล: Titles.DefaultConfigs / Quests / BadgeRewards ไม่มีอะไรนับโซน - ได้แค่แจ้งเตือน + หมุดแผนที่
do
    local DiscoveryPage = Window:Page({ Name = "Region Discovery", Icon = "compass", Columns = 2 })

    local Regions, Locator = nil, nil
    pcall(function()
        Regions = require(ReplicatedStorage.Regions)
        Locator = require(ReplicatedStorage.CAM.Global.Subsets.Areas.AreaLocator.Locator)
    end)

    local Discovery = { Active = false, Thread = nil, Step = "-", Log = { } }

    local function ShouldRun()
        return getgenv().ValkyrieSession == SessionToken and Discovery.Active
    end

    local function Note(Text)
        table.insert(Discovery.Log, 1, os.date("%H:%M") .. " " .. Text)
        while #Discovery.Log > 8 do table.remove(Discovery.Log) end
    end

    local function ArchiveValue()
        local Service = ReplicatedStorage:FindFirstChild("Player_Service")
        local Data = Service and Service:FindFirstChild("Data")
        local Mine = Data and Data:FindFirstChild(LocalPlayer.Name)
        local Archives = Mine and Mine:FindFirstChild("Archives")
        return Archives and Archives:FindFirstChild("Regions")
    end

    local function Discovered()
        local Set = { }
        local Value = ArchiveValue()
        for Name in string.gmatch(Value and Value.Value or "", "[^,]+") do Set[Name] = true end
        return Set
    end

    -- ทุกโซน { Name, Parent, YLimits } เรียงโซนหลักแล้วตามด้วยโซนย่อยของมัน
    local function AllAreas()
        local List = { }
        for Name, Info in pairs(Regions and Regions.Regions or { }) do
            local Grid = type(Info) == "table" and Info.Area and Info.Area.Grid
            if type(Grid) == "table" and Grid[1] then
                table.insert(List, { Name = Name, Key = Name })
                local Seen = { }
                for _, Cell in ipairs(Grid) do
                    for Child, Area in pairs(Cell.ChildAreas or { }) do
                        if not Seen[Child] then
                            Seen[Child] = true
                            local First = type(Area.Grid) == "table" and Area.Grid[1]
                            table.insert(List, { Name = Child, Parent = Name, Key = Name .. "\1" .. Child,
                                YLimits = First and First.YLimits })
                        end
                    end
                end
            end
        end
        table.sort(List, function(A, B) return A.Key < B.Key end)
        return List
    end

    -- สแกนแมพด้วย Locator ของเกม: เก็บจุดที่ตรงแต่ละโซน แล้วเลือกจุดที่ใกล้จุดเฉลี่ยสุด (โซนทรงแปลกเฉลี่ยตกนอกโซนได้)
    -- โซนที่มี YLimits (ถ้ำ) ต้องสุ่มที่ความสูงในช่วงนั้น โซนหลักไม่มี YLimits ความสูงไหนก็ได้
    local function FindPoints(Wanted)
        local Hits, Levels = { }, { 0 }
        for _, Area in ipairs(Wanted) do
            Hits[Area.Name] = { }
            if typeof(Area.YLimits) == "Vector2" then
                table.insert(Levels, math.floor((Area.YLimits.X + Area.YLimits.Y) / 2))
            end
        end

        local Count = 0
        for X = -3600, 2600, 40 do
            for Z = -3600, 2600, 40 do
                for _, Y in ipairs(Levels) do
                    local Ok, Name, Parent = pcall(Locator.Locate, Vector3.new(X, Y, Z))
                    local List = Ok and (Hits[Name] or Hits[Parent])
                    if List and #List < 4000 then table.insert(List, Vector3.new(X, Y, Z)) end
                end
                Count = Count + 1
                if Count % 300 == 0 then
                    if not ShouldRun() then return { } end
                    task.wait()
                end
            end
        end

        local Points = { }
        for Name, List in pairs(Hits) do
            if #List > 0 then
                local Sum = Vector3.zero
                for _, Point in ipairs(List) do Sum = Sum + Point end
                local Mean = Sum / #List
                local Best, BestDistance = nil, math.huge
                for _, Point in ipairs(List) do
                    local Distance = (Point - Mean).Magnitude
                    if Distance < BestDistance then Best, BestDistance = Point, Distance end
                end
                Points[Name] = Best
            end
        end
        return Points
    end

    local function Visit(Area, Point)
        Discovery.Step = "Going to " .. Area.Name
        Movement.Lock(nil)
        pcall(Movement.Go, CFrame.new(Point), 8, 180, ShouldRun)
        if not ShouldRun() then return false end

        Discovery.Step = "Discovering " .. Area.Name
        Movement.Lock(CFrame.new(Point))
        local Ok = Farm.WaitFor(function() return Discovered()[Area.Name] == true end, 8, ShouldRun)
        Movement.Lock(nil)
        return Ok
    end

    local SetDiscovery

    local function RunDiscovery()
        Fighter.Continue = nil
        local Root = Movement.GetRoot()
        local Start = Root and Root.CFrame
        local Missing = { }
        local Ok, Err = true, nil

        -- วนจนครบ: error / ยังไม่ครบ = ไม่ปิด toggle เอง รอ 15 วิแล้วไล่โซนที่ขาดใหม่ (ปิดเองเฉพาะค้นพบครบ)
        while ShouldRun() do
            Missing = { }
            Ok, Err = pcall(function()
                local Have = Discovered()
                local Wanted = { }
                for _, Area in ipairs(AllAreas()) do
                    if not Have[Area.Name] then table.insert(Wanted, Area) end
                end
                if #Wanted == 0 then return end

                Discovery.Step = "Scanning the map for " .. #Wanted .. " region(s)"
                local Points = FindPoints(Wanted)

                for _, Area in ipairs(Wanted) do
                    if not ShouldRun() then break end
                    local Point = Points[Area.Name]
                    if not Point then
                        table.insert(Missing, Area.Name .. " (no spot found)")
                    elseif Visit(Area, Point) then
                        Note("Discovered " .. Area.Name)
                    else
                        table.insert(Missing, Area.Name)
                    end
                end
            end)

            Movement.Cancel()
            if not ShouldRun() or (Ok and #Missing == 0) then break end

            Discovery.Step = (not Ok and ("Error: " .. tostring(Err):sub(1, 50)) or ("Not done: " .. table.concat(Missing, ", ")))
                .. " - retrying in 15s"
            Farm.Sleep(15, ShouldRun)
        end

        Movement.Cancel()
        -- เสร็จแล้วกลับจุดเริ่ม
        if Start and ShouldRun() then
            Discovery.Step = "Flying back"
            pcall(Movement.Go, Start, 8, 180, ShouldRun)
            Movement.Cancel()
        end

        if not Ok then
            Discovery.Step = "Error: " .. tostring(Err):sub(1, 60)
        elseif #Missing == 0 then
            Discovery.Step = "All regions discovered"
        else
            Discovery.Step = "Not done: " .. table.concat(Missing, ", ")
        end

        Discovery.Thread = nil
        if Discovery.Active then SetDiscovery(false, true) end
    end

    SetDiscovery = function(Value, SyncToggle)
        if Value then
            TurnOffFlags(ExclusiveFlags.Farm)
            TurnOffFlags(ExclusiveFlags.Breathing)
            TurnOffFlags(ExclusiveFlags.Fishing)
            TurnOffFlags(ExclusiveFlags.Quest)
            TurnOffFlags(ExclusiveFlags.Puzzle, "SL2AutoDiscovery")
            Discovery.Active = true
            if not Discovery.Thread then Discovery.Thread = task.spawn(RunDiscovery) end
        else
            Discovery.Active = false
            Movement.Cancel()
            if SyncToggle then
                local Set = Library.SetFlags and Library.SetFlags["SL2AutoDiscovery"]
                if Set then pcall(Set, false) end
            end
        end
    end

    task.wait()

    local DiscoverySection = DiscoveryPage:Section({
        Name = "Region Discovery",
        Description = "Visit every region you have not discovered yet",
        Icon = "80758916183665",
        Side = 1
    })

    local ListSection = DiscoveryPage:Section({
        Name = "Regions",
        Description = "Discovered regions (Archives)",
        Icon = "80758916183665",
        Side = 2
    })

    local StepLabel = DiscoverySection:Label("Status: -")
    local CountLabel = DiscoverySection:Label("Discovered: -", true)

    DiscoverySection:Toggle({
        Name = "Auto Region Discovery",
        Description = "Flies to each missing region until it is discovered, then flies back. Uses Travel settings. No in-game reward, it fills Archives and the map",
        Flag = "SL2AutoDiscovery",
        Default = getgenv().ConfigurationTable.AutoDiscovery == true,
        Seperator = true,
        Callback = function(Value)
            getgenv().ConfigurationTable.AutoDiscovery = Value == true   -- เซฟ = รันใหม่เปิดกลับเอง
            SaveConfiguration()
            SetDiscovery(Value)
        end
    })

    local LogLabel = DiscoverySection:Label("This session: -")
    local ListLabel = ListSection:Label("-")

    task.spawn(function()
        local Areas = AllAreas()
        while getgenv().ValkyrieSession == SessionToken do
            local Have = Discovered()
            local Lines, Count = { }, 0
            for _, Area in ipairs(Areas) do
                local Done = Have[Area.Name] == true
                if Done then Count = Count + 1 end
                -- ชิดซ้ายทุกแถว (เยื้องด้วยช่องว่างฟอนต์กว้างไม่เท่ากัน แถวเลยไม่ตรง) โซนย่อยบอกโซนหลักต่อท้ายแบบจาง
                table.insert(Lines, string.format('<font color="%s">%s</font>%s', Done and "#78DC78" or "#8C8C8C",
                    Area.Name, Area.Parent and ('<font color="#5A5A5A"> · ' .. Area.Parent .. '</font>') or ""))
            end

            local Step = "Status: " .. Discovery.Step
            local Total = string.format("Discovered: %d/%d", Count, #Areas)
            local Log = "This session: " .. (#Discovery.Log > 0 and ("\n" .. table.concat(Discovery.Log, "\n")) or "-")
            local List = #Lines > 0 and ('<font color="#78DC78">Green</font> is discovered · <font color="#8C8C8C">Gray</font> is not yet\n\n'
                .. table.concat(Lines, "\n")) or "Region data not loaded"

            task.wait()
            pcall(function()
                StepLabel:SetText(Step)
                CountLabel:SetText(Total)
                LogLabel:SetText(Log)
                ListLabel:SetRichText(List)
            end)
            task.wait()
        end
    end)
end

---- ============ Servers Tab (Misc) ============ ----
--
-- ยืนยันสดผ่าน dex (2026-09-28):
--   Boss Hunt ที่เปิดอยู่ในเซิร์ฟ = ReplicatedStorage.BossHunts.<n> (Configuration) attribute
--     Boss / Side (Muzan|Crow) / Tier (Mythic|Legendary|Epic|Rare|UnCommon|Common) / Quest / ExpiresAt (server time)
--   Mythic = Saneri / Shinora / Rengu (Muzan) + Gyutai / Akazo / Reaper (Crow) - Quests.BossHunts.Hunts
--   ฝั่งที่รับได้ = Quests.BossHunts.Sides[Side].Race (Muzan = Demon/Hybrid, Crow = Slayer/Hybrid)
--   รายชื่อเซิร์ฟ = ServerBrowserController ของเกม: Browse(placeId, region) -> SignalEvent "ServerBrowserRequest"
--     -> Updated { Servers = { Name, JobId, PlaceId, Players, MaxPlayers, Region, Version, StartTime } } (สูงสุด 100)
--     ข้อมูลเซิร์ฟไม่บอก Hunt -> ต้องเข้าไปดูเอง: เข้าเซิร์ฟ -> อ่าน BossHunts -> ไม่มี = กระโดดต่อ
--   เข้าเซิร์ฟ = ServerBrowserController.Join(server) (Teleporter.Request ของเกม)
--   เซิร์ฟที่เคยเข้าแล้วจำลงไฟล์ (ข้ามวาร์ปได้) 20 นาทีค่อยกลับไปดูใหม่ / Auto Server Hop เซฟใน config
--   -> hub รันที่เซิร์ฟใหม่ (autoexec หรือ getgenv().ValkyrieLoader ที่ queue_on_teleport ให้) แล้ว hop ต่อเอง
do
    local Config = getgenv().ConfigurationTable
    local ServersPage = Window:Page({ Name = "Servers", Icon = "server", Columns = 2 })

    local Browser, HuntInfo, Utility = nil, nil, nil
    pcall(function() Browser = require(ReplicatedStorage.CAM.Client.Controllers.ServerBrowserController) end)
    pcall(function() HuntInfo = require(ReplicatedStorage.CAM.Global.Subsets.Gameplay.Quests.BossHunts) end)
    pcall(function() Utility = require(ReplicatedStorage.CAM.Global.Utility) end)

    local Tiers = { "Mythic", "Legendary", "Epic", "Rare", "UnCommon", "Common" }
    local TierColor = { Mythic = "#FF5A5A", Legendary = "#FFC83C", Epic = "#B478FF", Rare = "#50A0FF", UnCommon = "#78DC78", Common = "#8C8C8C" }
    local Regions = { "Any", "NA-WEST", "NA-CENTRAL", "NA-EAST", "SA", "EU", "AF", "AS", "OCE" }
    local VisitedFile = FolderSettings .. "/ServerHop_" .. LocalPlayer.Name .. ".json"
    local VisitedMinutes = 20

    local Hop = { Active = false, Thread = nil, Step = "-", Hops = 0 }
    if type(Config.HopTiers) ~= "table" then Config.HopTiers = { Mythic = true } end

    local function ShouldRun()
        return getgenv().ValkyrieSession == SessionToken and Hop.Active
    end

    -- เซิร์ฟที่เคยเข้าแล้ว { [JobId] = os.time() } - ลบตัวที่เกิน VisitedMinutes ทิ้ง
    local function LoadVisited()
        local Visited = { }
        pcall(function()
            if isfile and isfile(VisitedFile) then
                Visited = HttpService:JSONDecode(readfile(VisitedFile))
            end
        end)
        if type(Visited) ~= "table" then Visited = { } end
        local Now = os.time()
        for JobId, At in pairs(Visited) do
            if type(At) ~= "number" or Now - At > VisitedMinutes * 60 then Visited[JobId] = nil end
        end
        return Visited
    end

    local function SaveVisited(Visited)
        pcall(function()
            if writefile then writefile(VisitedFile, HttpService:JSONEncode(Visited)) end
        end)
    end

    local function MyRace()
        local Ok, Race = pcall(function() return Utility.GetData(LocalPlayer).Race.Value end)
        return Ok and Race or nil
    end

    local function CanTake(Side)
        local Info = HuntInfo and HuntInfo.Sides and HuntInfo.Sides[Side]
        local Race = MyRace()
        return Info ~= nil and Race ~= nil and table.find(Info.Race, Race) ~= nil
    end

    -- Hunt ที่เปิดอยู่ในเซิร์ฟนี้ { Boss, Side, Tier, Left (วินาที), Match }
    local function OpenHunts()
        local List = { }
        local Folder = ReplicatedStorage:FindFirstChild("BossHunts")
        local Now = workspace:GetServerTimeNow()
        for _, Hunt in ipairs(Folder and Folder:GetChildren() or { }) do
            local Boss, Side, Tier = Hunt:GetAttribute("Boss"), Hunt:GetAttribute("Side"), Hunt:GetAttribute("Tier")
            local Left = (tonumber(Hunt:GetAttribute("ExpiresAt")) or 0) - Now
            if Boss and Left > 0 then
                local Match = Config.HopTiers[Tier] == true
                    and Left >= (tonumber(Config.HopMinMinutes) or 0) * 60
                    and (Config.HopMySide ~= true or CanTake(Side))
                table.insert(List, { Boss = Boss, Side = Side, Tier = Tier, Left = Left, Match = Match })
            end
        end
        table.sort(List, function(A, B)
            local Ra, Rb = table.find(Tiers, A.Tier) or 99, table.find(Tiers, B.Tier) or 99
            if Ra ~= Rb then return Ra < Rb end
            return A.Left > B.Left
        end)
        return List
    end

    local function Matching()
        local Found = { }
        for _, Hunt in ipairs(OpenHunts()) do
            if Hunt.Match then table.insert(Found, Hunt) end
        end
        return Found
    end

    -- ขอรายชื่อเซิร์ฟผ่าน ServerBrowserController ของเกม (รอผล Updated/Failed สูงสุด 10 วิ)
    local BrowseOnce
    -- ขอถี่ ๆ ติดกัน (กดปุ่มรัว) เซิร์ฟตอบไม่ทัน/ไม่ตอบ = รอ 2 วิแล้วขอใหม่อีกรอบ (วัดสด: ครั้งที่ 3 ติดกันได้ nil)
    local function Browse()
        local Servers, Why = BrowseOnce()
        if Servers then return Servers end
        task.wait(2)
        return BrowseOnce()
    end

    BrowseOnce = function()
        if not Browser then return nil, "ServerBrowser missing" end
        local Result, Failed = nil, nil
        local A = Browser.Updated:Connect(function(State)
            if type(State) == "table" and State.Kind == "Browse" then Result = State end
        end)
        local B = Browser.Failed:Connect(function(Why) Failed = Why end)
        pcall(Browser.Browse, game.PlaceId, Config.HopRegion ~= "Any" and Config.HopRegion or nil)
        Farm.WaitFor(function() return Result ~= nil or Failed ~= nil end, 10)
        A:Disconnect()
        B:Disconnect()
        if not Result then return nil, "Server list failed: " .. tostring(Failed or "timeout") end
        return Result.Servers or { }
    end

    -- hub รันต่อที่เซิร์ฟใหม่: ถ้า loader ตั้ง getgenv().ValkyrieLoader (โค้ด string) ไว้ = queue_on_teleport ให้
    local function QueueLoader()
        local Loader = getgenv().ValkyrieLoader
        local Queue = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
        if type(Loader) == "string" and Queue then pcall(Queue, Loader) end
    end

    -- เข้าเซิร์ฟที่เลือก (ใช้ Teleporter ของเกมผ่าน ServerBrowserController / สำรอง TeleportService)
    local function JoinServer(Server)
        QueueLoader()
        Hop.Hops = Hop.Hops + 1
        local Ok, Result, Reason = pcall(Browser.Join, Server)
        if Ok and Result == false then return false, tostring(Reason) end
        if not Ok then
            local Sent = pcall(function()
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, Server.JobId, LocalPlayer)
            end)
            if not Sent then return false, "Teleport failed" end
        end
        return true
    end

    -- กระโดด 1 ครั้ง: เซิร์ฟที่ไม่เคยเข้า ไม่เต็ม (สุ่ม) - คืน false + เหตุผลถ้าไม่ได้ย้าย
    local function HopOnce()
        local Servers, Why = Browse()
        if not Servers then return false, Why end

        local Visited = LoadVisited()
        Visited[game.JobId] = os.time()
        local Pool = { }
        for _, Server in ipairs(Servers) do
            if type(Server) == "table" and Server.JobId ~= game.JobId and not Visited[Server.JobId]
                and (tonumber(Server.Players) or 0) < (tonumber(Server.MaxPlayers) or 20) - 1 then
                table.insert(Pool, Server)
            end
        end
        SaveVisited(Visited)
        if #Pool == 0 then return false, "No unvisited server with room (" .. #Servers .. " listed)" end

        local Target = Pool[math.random(1, #Pool)]
        Visited[Target.JobId] = os.time()
        SaveVisited(Visited)
        Hop.Step = string.format("Joining %s (%s, %d/%d)", tostring(Target.Name), tostring(Target.Region),
            tonumber(Target.Players) or 0, tonumber(Target.MaxPlayers) or 0)

        local Ok, Reason = JoinServer(Target)
        if not Ok then return false, "Join refused: " .. tostring(Reason) end
        -- วาร์ปจริง = สคริปต์นี้หายไปกับเซิร์ฟเก่า / ยังอยู่หลัง 15 วิ = วาร์ปไม่สำเร็จ ลองเซิร์ฟอื่น
        Farm.Sleep(15, ShouldRun)
        return false, "Teleport did not go through"
    end

    -- Quick Hop (ไม่สนรายการเคยเข้า): Random / Smallest (คนน้อยสุด) / Target (ใกล้จำนวนคนที่ตั้งสุด)
    -- เฉพาะเซิร์ฟที่ยังมีที่ว่าง และไม่ใช่เซิร์ฟนี้
    local function PickQuick(Mode)
        local Servers, Why = Browse()
        if not Servers then return nil, Why end

        local Pool = { }
        for _, Server in ipairs(Servers) do
            if type(Server) == "table" and Server.JobId ~= game.JobId
                and (tonumber(Server.Players) or 0) < (tonumber(Server.MaxPlayers) or 20) then
                table.insert(Pool, Server)
            end
        end
        if #Pool == 0 then return nil, "no server with room" end

        local Target = Pool[math.random(1, #Pool)]
        if Mode == "Smallest" or Mode == "Target" then
            local Want = Mode == "Target" and (tonumber(Config.HopTargetPlayers) or 5) or 0
            local BestGap = math.huge
            local Ties = { }
            for _, Server in ipairs(Pool) do
                local Gap = math.abs((tonumber(Server.Players) or 0) - Want)
                if Gap < BestGap then BestGap, Ties = Gap, { Server }
                elseif Gap == BestGap then table.insert(Ties, Server) end
            end
            Target = Ties[math.random(1, #Ties)]
        end
        return Target
    end

    local function QuickHop(Mode)
        Hop.Step = "Quick Hop: getting the server list"
        local Target, Why = PickQuick(Mode)
        if not Target then Hop.Step = "Quick Hop: " .. tostring(Why) return end

        Hop.Step = string.format("Quick Hop (%s): joining %s (%s, %d/%d)", Mode, tostring(Target.Name),
            tostring(Target.Region), tonumber(Target.Players) or 0, tonumber(Target.MaxPlayers) or 0)
        local Ok, Reason = JoinServer(Target)
        if not Ok then Hop.Step = "Quick Hop: " .. tostring(Reason) end
    end

    local function JoinJobId(JobId)
        JobId = tostring(JobId or ""):gsub("%s", "")
        if not JobId:match("^%x+%-%x+%-%x+%-%x+%-%x+$") then
            Hop.Step = "Join: not a valid JobId"
            return
        end
        if JobId == game.JobId then
            Hop.Step = "Join: you are already in this server"
            return
        end
        Hop.Step = "Join: teleporting to " .. JobId
        local Ok, Reason = JoinServer({ PlaceId = game.PlaceId, JobId = JobId, Name = JobId })
        if not Ok then Hop.Step = "Join: " .. tostring(Reason) end
    end

    getgenv().ValkyrieServerHop = { State = Hop, OpenHunts = OpenHunts, Browse = Browse, PickQuick = PickQuick }   -- ดูสดผ่าน dex

    local SetHop

    local function RunHop()
        -- เพิ่งเข้าเซิร์ฟ = รอ BossHunts replicate ให้ครบก่อนตัดสิน
        Hop.Step = "Checking this server's Boss Hunts"
        Farm.WaitFor(function() return ReplicatedStorage:FindFirstChild("BossHunts") ~= nil end, 10, ShouldRun)
        Farm.Sleep(3, ShouldRun)

        while ShouldRun() do
            local Found = Matching()
            if #Found > 0 then
                local Names = { }
                for _, Hunt in ipairs(Found) do table.insert(Names, Hunt.Tier .. " " .. Hunt.Boss) end
                Hop.Step = "Found: " .. table.concat(Names, ", ")
                pcall(function() Library:Notify("Server Hop", "Found " .. table.concat(Names, ", "), 8) end)
                break
            end

            local _, Why = HopOnce()
            if not ShouldRun() then break end
            Hop.Step = "Retry in 5s - " .. tostring(Why)
            Farm.Sleep(5, ShouldRun)
        end

        Hop.Thread = nil
        if Hop.Active then SetHop(false, true) end
    end

    SetHop = function(Value, SyncToggle)
        Config.AutoServerHop = Value == true
        SaveConfiguration()
        if Value then
            Hop.Active = true
            if not Hop.Thread then Hop.Thread = task.spawn(RunHop) end
        else
            Hop.Active = false
            if SyncToggle then
                local Set = Library.SetFlags and Library.SetFlags["SL2AutoServerHop"]
                if Set then pcall(Set, false) end
            end
        end
    end

    task.wait()

    local HopSection = ServersPage:Section({
        Name = "Server Hop",
        Description = "Hop servers until one has the Boss Hunt you want",
        Icon = "80758916183665",
        Side = 1
    })

    local InfoSection = ServersPage:Section({
        Name = "This Server",
        Description = "Boss Hunts open here (ReplicatedStorage.BossHunts)",
        Icon = "80758916183665",
        Side = 2
    })

    HopSection:Guide("How to use", {
        "Pick the Boss Hunt tiers you want (Mythic by default), then turn on Auto Server Hop",
        "It checks this server first; if no hunt matches, it joins a random unvisited server with room",
        "Only My Side: only count hunts your race can take (Muzan is Demon/Hybrid, Crow is Slayer/Hybrid)",
        "Stays on and keeps hopping after the teleport if the hub runs again on the new server (autoexec)",
        "Servers already checked are skipped for 20 minutes",
    })

    local StepLabel = HopSection:Label("Status: -")

    local SavedTiers = { }
    for _, Tier in ipairs(Tiers) do
        if Config.HopTiers[Tier] == true then table.insert(SavedTiers, Tier) end
    end

    HopSection:Dropdown({
        Name = "Hunt Tier",
        Flag = "SL2HopTiers",
        Items = Tiers,
        Default = SavedTiers,
        Multi = true,
        KeepOrder = true,
        Seperator = false,
        Callback = function(Value)
            if type(Value) ~= "table" then return end
            for _, Tier in ipairs(Tiers) do
                Config.HopTiers[Tier] = table.find(Value, Tier) ~= nil
            end
            SaveConfiguration()
        end
    })

    HopSection:Dropdown({
        Name = "Region",
        Flag = "SL2HopRegion",
        Items = Regions,
        Default = table.find(Regions, Config.HopRegion) and Config.HopRegion or "Any",
        Multi = false,
        KeepOrder = true,
        Seperator = false,
        Callback = function(Value)
            if type(Value) ~= "string" then return end
            Config.HopRegion = Value
            SaveConfiguration()
        end
    })

    HopSection:Slider({
        Name = "Min Time Left",
        Flag = "SL2HopMinMinutes",
        Min = 0,
        Max = 30,
        Default = tonumber(Config.HopMinMinutes) or 5,
        Suffix = " min",
        Seperator = false,
        Callback = function(Value)
            Config.HopMinMinutes = Value
            SaveConfiguration()
        end
    })

    HopSection:Toggle({
        Name = "Only My Side",
        Description = "Only count hunts your race can accept",
        Flag = "SL2HopMySide",
        Default = Config.HopMySide ~= false,
        Callback = function(Value)
            Config.HopMySide = Value == true
            SaveConfiguration()
        end
    })

    HopSection:Toggle({
        Name = "Auto Server Hop",
        Description = "Hop until a server has a matching Boss Hunt, then stop",
        Flag = "SL2AutoServerHop",
        Default = Config.AutoServerHop == true,
        Seperator = true,
        Callback = function(Value)
            SetHop(Value)
        end
    })

    task.wait()

    -- Quick Hop: ย้ายเซิร์ฟทันทีตามแบบที่เลือก (ไม่สน Boss Hunt / ไม่สนรายการเคยเข้า)
    local QuickSection = ServersPage:Section({
        Name = "Quick Hop",
        Description = "Move to another server right now",
        Icon = "80758916183665",
        Side = 1
    })

    QuickSection:Button({
        Name = "Hop Server (Random)",
        Callback = function() task.spawn(QuickHop, "Random") end
    })

    QuickSection:Button({
        Name = "Hop Smallest Server",
        Callback = function() task.spawn(QuickHop, "Smallest") end
    })

    QuickSection:Slider({
        Name = "Target Players",
        Flag = "SL2HopTargetPlayers",
        Min = 1,
        Max = 20,
        Default = tonumber(Config.HopTargetPlayers) or 5,
        Suffix = " players",
        Seperator = false,
        Callback = function(Value)
            Config.HopTargetPlayers = Value
            SaveConfiguration()
        end
    })

    QuickSection:Button({
        Name = "Hop to Target Players",
        Callback = function() task.spawn(QuickHop, "Target") end
    })

    QuickSection:Button({
        Name = "Rejoin This Server",
        Callback = function()
            QueueLoader()
            pcall(function()
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
            end)
        end
    })

    task.wait()

    -- JobId: section แยก (textbox ของ Milenium ขึ้นบนสุดของกล่องเสมอ)
    local JobSection = ServersPage:Section({
        Name = "Join by JobId",
        Description = "Paste a JobId from a friend or another client",
        Icon = "80758916183665",
        Side = 2
    })

    local TypedJobId = ""
    JobSection:Textbox({
        Name = "JobId",
        Placeholder = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
        Default = "",
        Callback = function(Text)
            TypedJobId = tostring(Text or "")
        end
    })

    JobSection:Button({
        Name = "Join JobId",
        Callback = function() task.spawn(JoinJobId, TypedJobId) end
    })

    JobSection:Button({
        Name = "Copy Current JobId",
        Callback = function()
            local Copy = setclipboard or toclipboard or (syn and syn.write_clipboard)
            if Copy and pcall(Copy, game.JobId) then
                Library:Notify("Servers", "JobId copied", 3)
            else
                Library:Notify("Servers", "Clipboard not supported - JobId is shown under This Server", 5)
            end
        end
    })

    local ServerLabel = InfoSection:Label("-")
    local HuntLabel = InfoSection:Label("-")


    task.spawn(function()
        while getgenv().ValkyrieSession == SessionToken do
            local Lines = { }
            for _, Hunt in ipairs(OpenHunts()) do
                table.insert(Lines, string.format('<font color="%s">%s</font> %s <font color="#8C8C8C">· %s · %dm left</font>%s',
                    TierColor[Hunt.Tier] or "#FFFFFF", tostring(Hunt.Tier), tostring(Hunt.Boss), tostring(Hunt.Side),
                    math.floor(Hunt.Left / 60), Hunt.Match and ' <font color="#78DC78">✓</font>' or ""))
            end
            local Name = workspace:GetAttribute("ServerName")
            local Region = workspace:GetAttribute("ServerRegion")
            local Server = string.format("Server: %s (%s) · %d/%d players\nJobId: %s\nRace: %s · Hops this session: %d",
                tostring(Name or "?"), tostring(Region or "?"), #Players:GetPlayers(), Players.MaxPlayers,
                game.JobId, tostring(MyRace() or "?"), Hop.Hops)
            local Hunts = #Lines > 0 and table.concat(Lines, "\n") or "No Boss Hunt open"

            task.wait()
            pcall(function()
                StepLabel:SetText("Status: " .. Hop.Step)
                ServerLabel:SetText(Server)
                HuntLabel:SetRichText(Hunts)
            end)
            task.wait()
        end
    end)
end

---- ============ Configuration Tab ============ ----

task.wait()

Window:Category("Settings")

local ConfigPage = Window:Page({ Name = "Configuration", Icon = "settings", Columns = 2 })

local InterfaceSection = ConfigPage:Section({
    Name = "Interface",
    Description = "Window and executor options",
    Icon = "93142176757189",
    Side = 1
})

-- ธีมของ Milenium (Milenium, Midnight, Sakura ...) เปลี่ยนแล้วเห็นผลทันที
InterfaceSection:Dropdown({
    Name = "Theme",
    Flag = "SL2Theme",
    Items = Library:Themes(),
    Default = getgenv().ConfigurationTable.Theme,
    Multi = false,
    Callback = function(Value)
        if type(Value) ~= "string" or Value == "" then return end

        getgenv().ConfigurationTable.Theme = Value
        Library:SetTheme(Value)
        SaveConfiguration()
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
    Flag = "SL2AntiAFK",
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
    Flag = "SL2AutoRejoin",
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
    Flag = "SL2AutoExecutor",
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
    Flag = "SL2MinimizeBind",
    Default = KeyFromName(getgenv().ConfigurationTable.MinimizeBind),
    Mode = "Toggle",
    ShowModes = false,
    Callback = function(Key)
        if typeof(Key) ~= "EnumItem" then return end

        local KeyName = Key.Name
        if getgenv().ConfigurationTable.MinimizeBind ~= KeyName then
            getgenv().ConfigurationTable.MinimizeBind = KeyName
            SaveConfiguration()
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
    Flag = "SL2FPSValue",
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
    Flag = "SL2FPSLock",
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
    Flag = "SL2Language",
    Items = { "English (US)", "Thai" },
    Default = getgenv().ConfigurationTable.Language,
    Multi = false,
    Seperator = false,
    Callback = function(Value)
        getgenv().ConfigurationTable.Language = Value
        SaveConfiguration()
    end
})

task.wait()

LanguageSection:Button({
    Name = "Change Language",
    Callback = function()
        ApplyLanguage(getgenv().ConfigurationTable.Language)
    end
})

-- ทุกแท็บสร้างครบแล้วตรงนี้ (ลำดับสุดท้ายของสคริปต์) - บังคับกลับไปแท็บแรกเสมอ (AutoFarm) กันเผลอ
-- ค้างอยู่แท็บ Configuration ที่เพิ่งสร้างเสร็จ (tab index นับรวมทุกกลุ่ม ตัวแรกที่สร้าง = index 1)
pcall(function() Library.Window:selectTab(1) end)

---- ============ เริ่มระบบที่เซฟว่าเปิดไว้ ============ ----
--
-- ทุก toggle เซฟค่าลง config (Default = ค่าที่เซฟ) แต่ตอนสร้าง wrapper ไม่ยิง callback (Gate) = ปุ่มโชว์เปิด
-- แต่ระบบที่ต้องสั่งเริ่ม (Auto Farm/Mob/Boss/Raid, Anti-AFK, Auto Rejoin, Lock FPS, Jewelry Box, Puzzle,
-- Discovery, ตกปลา ฯลฯ) ไม่เริ่มจริง -> ยิง setter ของตัวที่ยังเปิดอยู่ทีละตัว เหมือนผู้ใช้กดเปิดเอง
-- (ตัวที่ชนกันเปิดแล้วจะปิดอีกตัวให้เอง ตัวที่โดนปิดไปแล้วข้าม) / Breathing มีตัวเริ่มของตัวเอง ข้าม
task.spawn(function()
    task.wait(1)
    local Skip = { SL2AutoBreathing = true }
    for _, Flag in ipairs(Library.StartOn) do
        if getgenv().ValkyrieSession ~= SessionToken then break end
        if not Skip[Flag] and Library.Flags[Flag] == true then
            local Set = Library.SetFlags[Flag]
            if Set then pcall(Set, true) end
            task.wait()
        end
    end
end)

---- ============ Cleanup ============ ----

getgenv().ValkyrieCleanup = function()
    getgenv().ValkyrieSession = nil

    pcall(function() Movement.Cancel() end)
    pcall(function() RunService:UnbindFromRenderStep("Valkyrie_PromptAim") end)   -- Prompts.Aim ค้าง = กล้องล็อก
    if PlayersCleanup then pcall(PlayersCleanup) end
    if VisualCleanup then pcall(VisualCleanup) end
    if CombatCleanup then pcall(CombatCleanup) end
    if FishingStatus.Cleanup then pcall(FishingStatus.Cleanup) end

    for _, Connection in ipairs(SessionConnections) do
        pcall(function() Connection:Disconnect() end)
    end
    table.clear(SessionConnections)

    pcall(function()
        Library:Unload()
    end)

    getgenv().ValkyrieCleanup = nil
end