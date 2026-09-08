getgenv().ConfigurationTable = {}
getgenv().Settings = {}

-- Every path this session writes to, in one table rather than four locals, and the same for
-- the three URLs the hub boots itself from. The main chunk is a function like any other and
-- Luau allows it two hundred live locals; tools/check-locals.py counts what is left, and a
-- constant that only ever gets read is the cheapest kind to fold away.
local File = {
    Folder = "Valkyrie Hub",
    Settings = "Valkyrie Hub/STE",
}

local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

while not LocalPlayer do
    task.wait()
    LocalPlayer = Players.LocalPlayer
end

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IconValkyrie = "87057639235201"

local Boot = {
    Library = "https://www.valkyriehub.net/api/raw/ui-lib",
    Icons = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua",
    Loader = "https://www.valkyriehub.net/api/raw/loading",

    -- what the loader looks for on the other side of a teleport to know it is a rejoin
    FastLoadKey = "ValkyrieFastLoaded",
}

---- ============ Session ============ ----

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

File.Configuration = File.Folder .. "/" .. "Setting_" .. LocalPlayer.Name .. ".json"
File.Game = File.Settings .. "/" .. "GameConfig_" .. LocalPlayer.Name .. ".json"

---- ============ Icons ============ ----

local IconPack = { }

do
    local Ok, Pack = pcall(function()
        return loadstring(game:HttpGet(Boot.Icons))()
    end)

    if Ok and type(Pack) == "table" then
        IconPack = Pack
    else
        warn("[ValkyrieHub] icon pack unavailable: " .. tostring(Pack))
    end
end

local function Icon(Name, Fallback)
    local Asset = IconPack[Name]

    if type(Asset) == "string" then
        return (string.gsub(Asset, "^rbxassetid://", ""))
    end

    return Fallback
end

---- ============ Configuration ============ ----

local DefaultConfiguration = {
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
    if readfile and isfile and isfile(File.Configuration) then
        local data = readfile(File.Configuration)
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
        if not isfolder(File.Folder) then makefolder(File.Folder) end

        writefile(File.Configuration, HttpService:JSONEncode(getgenv().ConfigurationTable))
    end
end

LoadConfiguration()

---- ============ SaveSettings ============ ----

local DefaultSettings = {
    ["Main"] = {
        ["AutoFarmSpeed"] = false,
        ["AutoUpgradeTreadmill"] = false,
        ["AutoBuyPen"] = false,
        ["AutoSell"] = false,
        ["SellRarities"] = {},
        ["SellCategories"] = {},
        ["SellEggCategories"] = {},
        ["SellBelowRate"] = "0",
        ["AutoStealEgg"] = false,
        ["AutoDeliver"] = true,
        ["StealAreas"] = { "Forest" },
        ["StealRarities"] = {},
        ["StealPriority"] = "Rarest",
        ["SpeedMargin"] = 5,
        ["TweenSpeed"] = 300,
        ["StealDelay"] = 0.5,
        ["CarryRetry"] = 3,
        ["DropRecovery"] = 3,
        ["RecoverStolenEgg"] = true,
        ["StealFromPlayers"] = false,
        ["AutoAttackPlayers"] = false,
        ["AttackRange"] = 15,
        ["AttackDelay"] = 0.7,
        ["AttackTarget"] = "",
        ["AttackPlayer"] = false,
        ["AutoFuse"] = false,
        ["FuseCategories"] = {},
        ["FuseSkipMutated"] = true,
        ["FuseDelay"] = 1,
        ["AutoPlaceEgg"] = false,
        ["AutoOpenEgg"] = false,
        ["PlaceEggs"] = {},
        ["PlaceRarities"] = {},
        ["PlotDelay"] = 2,
        ["AutoEquipBest"] = false,
        ["AutoFavoriteEquipped"] = false,
        ["EquipDelay"] = 5,
        ["AutoMonsterParasite"] = false,
        ["ParasiteFeed"] = true,
        ["ParasiteChest"] = true,
        ["ParasiteFeedMutated"] = false,
        ["ParasiteSteal"] = true,
        ["AutoClaimIndex"] = false,
        ["AutoRebirth"] = false,
        ["EspAreaEggs"] = false,
        ["EspPenEggs"] = false,
        ["EspPenPets"] = false,
        ["EspTraps"] = false,
        ["EspMonsters"] = false,
        ["EspAreaEggColor"] = "ffd166",
        ["EspPenEggColor"] = "6ee7ff",
        ["EspPenPetColor"] = "b06cff",
        ["EspTrapColor"] = "ff3b3b",
        ["EspMonsterColor"] = "ff5470",
        ["EspMaxDistance"] = 2000,
        ["EspLimit"] = 30,
        ["HidePenPets"] = false,
        ["InventoryValue"] = false,
        ["InventoryValueEggs"] = true,
        ["BuyTrails"] = {},
        ["AutoBuyTrails"] = false,
    },
}

local function MergeSettings(defaults, loaded)
    for k, v in pairs(defaults) do
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
    if readfile and isfile and isfile(File.Game) then
        local loaded = HttpService:JSONDecode(readfile(File.Game))
        MergeSettings(DefaultSettings, loaded)
        getgenv().Settings = loaded
    else
        getgenv().Settings = DefaultSettings
    end
end

function SaveSetting()
    if writefile and makefolder then
        if not isfolder(File.Folder) then makefolder(File.Folder) end
        if not isfolder(File.Settings) then makefolder(File.Settings) end

        writefile(File.Game, HttpService:JSONEncode(getgenv().Settings))
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

---- ============ Game ============ ----

-- The update split ReplicatedStorage.Library into Client and Shared, renamed Directory to
-- Data, and took the Network folder away: every remote now lives under Packages.Networking
-- as an instance named "RE/<Namespace>/<Name>" or "RF/<Namespace>/<Name>". Library2 points at
-- Shared, so Library2.Util / Types / Modules / Globals still read the way they did.
--
-- The game renamed its client modules and every function on them at the same time, so each
-- one is wrapped below in a table that keeps the old names. Doing it here rather than at the
-- hundred call sites also keeps the main chunk under Luau's ceiling of 200 locals.
local Library2 = ReplicatedStorage:WaitForChild("Shared")
local Directory = ReplicatedStorage:WaitForChild("Data")

-- Forward-declared: the Interface block far below assigns it. Combat code above that block
-- (the chase notifier) needs the name to resolve to this local rather than a nil global.
local Library

local NetworkFolder = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Networking")

local Network = {
    Invoke = function(Name, ...)
        local Remote = NetworkFolder:FindFirstChild(Name)

        if not (Remote and Remote:IsA("RemoteFunction")) then
            error("[ValkyrieHub] missing remote function " .. tostring(Name), 0)
        end

        return Remote:InvokeServer(...)
    end,

    Fire = function(Name, ...)
        local Remote = NetworkFolder:FindFirstChild(Name)

        if not (Remote and Remote:IsA("RemoteEvent")) then
            error("[ValkyrieHub] missing remote event " .. tostring(Name), 0)
        end

        return Remote:FireServer(...)
    end,

    Fired = function(Name)
        local Remote = NetworkFolder:WaitForChild(Name, 10)

        return Remote and Remote.OnClientEvent
    end,
}

local EggCmds = (function()
    local State = require(ReplicatedStorage:WaitForChild("Client").EggState)

    return {
        GetAreaEggSnapshot = State.ReadFieldEggs,
        GetOwnerRuntimeRecords = State.ReadOwnerEggs,
        RequestEquipTool = State.WearEggTool,
        IsLocalEggReady = State.IsReadyToHatch,
        RequestPlaceEgg = State.PlantEgg,
        RequestHatchEgg = State.BeginHatch,
        RequestCompleteHatchEgg = State.FinishHatch,
        RequestCarryAreaEgg = State.CarryFieldEgg,
        RequestAreaEggRareSpawnPresentations = State.FetchRarityShows,
        AreaEggRareSpawnsRevealed = State.RarityRevealed,
    }
end)()

local AssetCmds = (function()
    local Roster = require(ReplicatedStorage:WaitForChild("Client").AssetRoster)

    return { RequestUnequipAsset = Roster.DoffAsset }
end)()

local PlotCmds = (function()
    local State = require(ReplicatedStorage:WaitForChild("Client").PlotState)

    return { GetPlotData = State.ResolvePlot }
end)()

local Save = require(Library2.Save)

local SlotIdentity = (function()
    local Identity = require(Library2.Util.AreaEggSlotIdentity)

    return {
        ResolveNest = Identity.NestFor,
        IsFirstAreaUid = Identity.LooksLikeFirstAreaUid,
        BuildSlotKey = Identity.SlotKey,
    }
end)()

-- GuardAreaLookupUtil is gone; the same test is a signed distance against the line part
local GuardLookup = {
    IsInGameplaySide = require(Library2.Util.GuardAreaGeometry).IsPastLine,
    DepthPastLine = require(Library2.Util.GuardAreaGeometry).SignedDistanceToLine,
}

local BaseUpgradeClient = (function()
    local Upgrade = require(ReplicatedStorage:WaitForChild("Client").BaseUpgrade)

    return {
        GetNextConfig = Upgrade.ResolveNextTier,
        RequestCashUpgrade = Upgrade.PurchaseNextTier,
    }
end)()

local AssetItemSerialization = (function()
    local Items = require(Library2.Util.AssetItems)

    return {
        Deserialize = Items.Decode,
        -- the lump the seller NPC pays for one pet, before the VIP doubling -- see
        -- AssetSellerNpc.promptSellHeld / promptSellAll
        SalePrice = Items.SalePrice,
        -- "2,565Kg", which is the half of a backpack slot's label that identifies which of
        -- three Triceratops it is
        WeightLabel = Items.WeightLabel,
    }
end)()

local AssetGeneration = (function()
    local Earnings = require(Library2.Util.AssetEarnings)

    -- the rate no longer takes a rebirth count; the extra argument is a player for
    -- monetization bonuses, so it has to be dropped rather than passed through
    return {
        GetRate = function(Item)
            return Earnings.RatePerSecond(Item)
        end,
    }
end)()

local EggItemUtil = (function()
    local Records = require(Library2.Util.EggRecords)

    return {
        DeserializeSavedEgg = Records.Decode,
        GetDisplayName = Records.DisplayName,
        -- what the seller NPC pays for one unplaced egg
        SellPrice = Records.SellPrice,
        -- exactly what the backpack slot prints, which is how an egg slot is matched to its
        -- record: "Prehistoric Egg (126,536Kg)"
        DisplayNameWithWeight = Records.DisplayNameWithWeight,
    }
end)()

local FuseKernelUtil = (function()
    local Kernel = require(Library2.Util.FuseKernel)

    return {
        CanSelectPet = Kernel.MayEnterFuse,
        CalculateFusePrice = Kernel.PriceFor,
    }
end)()

local EggsType = require(Library2.Types.Eggs)
local TreadmillUtil = require(Library2.Util.TreadmillUtil)
local AssetsDir = require(Directory.Assets)
local Compact = require(ReplicatedStorage:WaitForChild("Packages").FormatNumber.Simple)
local TreadmillsDir = require(Directory.Treadmills)
local TrailsDir = require(Directory.Trails)

-- Rebirth left the game with this update: no module, no remote, no namespace. Both entry
-- points return nil so RebirthReady() below reads it as "not available" and stays off.
local RebirthUtil = {
    GetMaxRebirth = function() return nil end,
    RebirthToRequiredSpeedPower = function() return nil end,
}

local Areas = require(Directory.Areas)
local Guards = require(Directory.Guards)

local AreaObjects = workspace:WaitForChild("__OBJECTS"):WaitForChild("Areas")
local GuardAreas = AreaObjects:WaitForChild("GuardAreas")
local SeparationLine = AreaObjects:WaitForChild("SeparationLine")
local StartArea = AreaObjects:WaitForChild("StartArea")

-- Rebirth has no namespace under Packages.Networking any more, so both of its names are left
-- here as strings that will never resolve: InvokeRemote reports them absent and stops.
local Endpoint = {
    IndexClaimAll = "RF/Codex/AskRedeemAll",
    TrailPurchase = "RF/Trailwear/AskPurchase",
    RebirthRequest = "RF/Rebirth/AskRebirth",
    RebirthCommit = "RF/Rebirth/AskRebirthCommit",
}

local function InvokeRemote(Name, ...)
    local Remote = NetworkFolder:FindFirstChild(Name)

    if not (Remote and Remote:IsA("RemoteFunction")) then return false end

    local Ok, Result, Reason = pcall(Network.Invoke, Name, ...)

    return true, Ok, Result, Reason
end

local SpeedSuffix = {
    [""] = 1,
    ["K"] = 1e3,
    ["M"] = 1e6,
    ["B"] = 1e9,
    ["T"] = 1e12,
    ["Qa"] = 1e15,
    ["Qi"] = 1e18,
}

local function ParseSpeed(Text)
    if type(Text) ~= "string" then return end

    local Number, Suffix = string.match(Text, "^%s*([%d%.]+)%s*(%a*)%s*$")

    if not Number then return end

    return tonumber(Number) * (SpeedSuffix[Suffix] or SpeedSuffix[string.upper(Suffix)] or 1)
end

local function FormatSpeed(Value)
    local Ok, Text = pcall(Compact.FormatCompact, Value, ".#")

    return Ok and Text or tostring(math.floor(Value))
end

local function SpeedPowerForWalkSpeed(WalkSpeed)
    if not (type(WalkSpeed) == "number" and WalkSpeed > 0) then return 0 end

    local Ok, Value = pcall(TreadmillUtil.WalkSpeedToSpeedPower, math.min(WalkSpeed, TreadmillUtil.MAX_WALK_SPEED))

    return (Ok and type(Value) == "number") and Value or 0
end

local function ReadRequiredSpeed(AreaModel)
    local Sign = AreaModel:FindFirstChild("RequiredSpeedSign")

    if not Sign then return end

    for _, Label in ipairs(Sign:GetDescendants()) do
        if Label:IsA("TextLabel") and Label.Name == "Speed" then
            return ParseSpeed(Label.Text), Label.Text
        end
    end
end

local AreaList = { }
local AreaInfo = { }

-- Each area has a RequiredSpeedSign, and the sign is where Info.Required comes from. It is
-- the game's own number but it is only a recommendation -- the label next to it literally
-- reads "recommended" -- and it is not always a sane one.
--
-- Measured against the number the guard's own walk speed works out to
-- (TreadmillUtil.WalkSpeedToSpeedPower), every area sits between half and twice its sign:
--
--   Forest 11 vs 10   Lake 900 vs 2K    Desert 10K vs 18K   Jungle 40K vs 80K
--   Snow 170K vs 250K Volcano 700K vs 700K   Abyss Ocean 2.5M vs 2.5M   Cosmic 700M vs 350M
--
-- and then Prehistoric, whose sign reads 450B while its guard walks at 152, which is 11M.
-- Forty thousand times out. RequiredSpeed takes the larger of the two, so the picker decided
-- Prehistoric needed 450B and never chose an egg there, and the Farm First If Too Slow toggle
-- that used to exist put the character on the treadmill chasing a number that cannot be
-- reached. The picker no longer gates on these numbers at all -- see PickTarget -- but they
-- still drive the Speed label and the sanity fix below is what keeps that label honest.
--
-- A sign more than ten times the guard's own figure is therefore thrown away. Cosmic's
-- genuine 2x survives; Prehistoric's does not.
--
-- ---------------------------------------------------------------------------------------
-- A dead end, written down so it does not get tried twice.
--
-- GuardChasePolicy.GetWakingDuration() is 0.63, and GuardEscapePrediction short-circuits on
-- it before any speed comparison happens at all:
--
--     local v6 = p4.ExitDistance / p5              -- ExitDistance / PlayerWalkSpeed
--     if v6 <= GuardChasePolicy.GetWakingDuration() then
--         return { Outcome = "EscapedSafely", ... }
--     end
--
-- ResolveExitDistance measures to the area's own Bounds along the direction travelled, and
-- the areas are 500 to 676 studs wide but only 130 to 151 deep, so leaving sideways through
-- the near Z face reads as 30 to 45 studs out of any nest in the game -- a fifth of a second,
-- comfortably inside the window, at any speed. Leaving along -X towards the gate reads about
-- 500 studs out of a Cosmic nest instead.
--
-- It does not work, because there is no Z face to leave through. Both sides of the whole row
-- are sealed:
--
--     Build.1.COLLISIONS."GUARD NO COLLIDE"."WALL LEFT"    9 parts, all CanCollide, z = -439
--     Build.1.COLLISIONS."GUARD NO COLLIDE"."WALL RIGHT"   9 parts, all CanCollide, z = -289
--
-- and -439 and -289 are exactly the Bounds Z faces (centre -364, half-depth 75). Nine parts,
-- one per area. A run aimed past them noclips through on the way out and then gets its
-- collisions back inside solid geometry, which kills the character.
--
-- So the prediction module is a calculator for the sign, not a description of a way out that
-- exists. The only exit is -X back down the row, which is what Route.Plan already does.

for Name, Config in pairs(Areas.Directory) do
    local Model = GuardAreas:FindFirstChild(Name)

    if Model then
        local Required, RequiredText = ReadRequiredSpeed(Model)
        local Guard = Guards.Directory[Name]
        local Bounds = Model:FindFirstChild("Bounds")

        local Info = {
            Id = Name,
            Model = Model,
            Display = Config.DisplayName or Name,
            Emoji = Config.Emoji,
            RarityNumber = Config.Rarity and Config.Rarity.RarityNumber or 0,
            Required = Required or 0,
            RequiredText = RequiredText or "?",
            GuardSpeed = Guard and Guard.WalkSpeed or 0,
            Drops = { },

            -- the flat footprint the game itself draws the area on, and the spot it marks as
            -- the way out of it. Both are used by the route planner down in Movement.
            Bounds = Bounds,
            Exit = Model:FindFirstChild("ClosestExitPoint"),
        }

        Info.GuardRequired = SpeedPowerForWalkSpeed(Info.GuardSpeed)

        if Info.Required > math.max(Info.GuardRequired, 1) * 10 then
            warn(string.format(
                "[ValkyrieHub] %s sign reads %s but its guard only asks for %s; using the guard",
                Name,
                FormatSpeed(Info.Required),
                FormatSpeed(Info.GuardRequired)
            ))

            Info.Required = Info.GuardRequired
            Info.RequiredText = FormatSpeed(Info.GuardRequired)
        end

        for _, Entry in ipairs(Config.DropTable or { }) do
            Info.Drops[Entry[1]] = Entry[2]
        end

        AreaInfo[Name] = Info
        table.insert(AreaList, Info)
    end
end

table.sort(AreaList, function(a, b)
    return math.max(a.Required, a.GuardRequired) < math.max(b.Required, b.GuardRequired)
end)

local AreaItems = { }
local AreaByLabel = { }

for _, Info in ipairs(AreaList) do
    local Label = string.format("%s (Speed %s | Monster %d)", Info.Display, FormatSpeed(math.max(Info.Required, Info.GuardRequired)), Info.GuardSpeed)

    table.insert(AreaItems, Label)
    AreaByLabel[Label] = Info.Id
    Info.Label = Label
end

do
    local Fixed = { }
    local ByDisplay = { }

    for _, Info in ipairs(AreaList) do
        ByDisplay[Info.Display] = Info
    end

    for _, Saved in ipairs(getgenv().Settings.Main.StealAreas or { }) do
        local Info = AreaInfo[AreaByLabel[Saved] or Saved]
            or ByDisplay[string.match(Saved, "^(.-)%s*%(") or Saved]

        if Info then
            table.insert(Fixed, Info.Label)
        end
    end

    if #Fixed == 0 and AreaList[1] then
        table.insert(Fixed, AreaList[1].Label)
    end

    getgenv().Settings.Main.StealAreas = Fixed
end

local EggChance = { }

for _, Info in ipairs(AreaList) do
    for Species, Chance in pairs(Info.Drops) do
        if EggChance[Species] == nil or Chance < EggChance[Species] then
            EggChance[Species] = Chance
        end
    end
end

local RarityItems = { }
local CategoryItems = { }
local RarityOfCategory = { }

local AnnouncedCategory = { }

do
    local Seen = { }
    local Ordered = { }

    for Category, Config in pairs(AssetsDir.Directory) do
        table.insert(CategoryItems, Category)

        local Rarity = Config.Rarity
        local Name = Rarity and (Rarity.DisplayName or Rarity.Name)

        if Rarity and Rarity.Announce == true then
            AnnouncedCategory[Category] = true
        end

        if Name then
            RarityOfCategory[Category] = Name

            if not Seen[Name] then
                Seen[Name] = true
                table.insert(Ordered, { Name = Name, Number = Rarity.RarityNumber or 0 })
            end
        end
    end

    table.sort(CategoryItems)
    table.sort(Ordered, function(a, b)
        return a.Number < b.Number
    end)

    for _, Entry in ipairs(Ordered) do
        table.insert(RarityItems, Entry.Name)
    end
end

local EggCategoryName = { }
local EggItems = { }

for _, Info in ipairs(AreaList) do
    table.insert(EggItems, Info.Display .. " Egg")
end

do
    local Names = { }

    for Category, Config in pairs(AssetsDir.Directory) do
        local Egg = Config.Egg
        local Name = type(Egg) == "table" and Egg.DisplayName or nil

        if type(Name) == "string" then
            EggCategoryName[Category] = Name
            table.insert(Names, Name)
        end
    end

    table.sort(Names)

    for _, Name in ipairs(Names) do
        table.insert(EggItems, Name)
    end
end

-- Two ceilings, and which one applies is decided by whether the Humanoid in the character is
-- the one the game put there. See the Rig block for what that means and why it works.
--
-- With the game's own Humanoid, the corrector leashes travel to twice WalkSpeed and kills a
-- couple of seconds above it. Measured on a WalkSpeed 16 character, eight second legs, base
-- side, nothing hooked and nothing disabled:
--
--     20 studs/s  = 1.25x   0 snap-backs, drift 6      alive
--     24 studs/s  = 1.50x   0 snap-backs, drift 6      alive
--     28 studs/s  = 1.75x   0 snap-backs, drift 3      alive
--     32 studs/s  = 2.00x   0 snap-backs, drift 0      alive
--     36 studs/s  = 2.25x  84 snap-backs, drift 108    dead at 3.4s
--
-- Above the line the corrector drags the root back toward where the server last had it, the
-- engine writes the next frame anyway, and a couple of seconds of that is read as tampering:
-- health goes 0, then -1000, then -100999.
--
-- 1.9 rather than a clean 2 because WalkSpeed can change under the engine mid-leg (a trail, a
-- treadmill payout, a stat purchase landing between frames) and the frame that reads the old
-- value must not end up over the line.
local TravelFactor = 1.9

-- With the Humanoid swapped there is no leash at all, and this is what the slider may ask for.
-- Five hundred rather than the thousand another hub's slider offers, because five hundred is
-- what was measured: 5006 studs in ten seconds, no snap-backs, drift 4. Eight hundred and a
-- thousand both ran off the end of the map inside the leg -- the row of areas is about 4000
-- studs long -- so what they measured is the terrain, not the anti-cheat, and a ceiling is not
-- set on a number nothing verified.
local TravelHardMax = 1000

-- The attribute the swapped Humanoid carries. Read in two places that cannot see each other,
-- hence the string in both rather than a local: the main chunk is at Luau's ceiling of 200
-- locals per function.
local function SpeedRoof()
    local Player = game:GetService("Players").LocalPlayer
    local Character = Player and Player.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

    if Humanoid and Humanoid:GetAttribute("ValkyrieTravelHum") == true then
        return TravelHardMax
    end

    local Walk = Humanoid and tonumber(Humanoid.WalkSpeed) or 16

    return math.clamp(Walk * TravelFactor, 16, TravelHardMax)
end

local TrailList = { }
local TrailItems = { }

for Id, Config in pairs(TrailsDir.Directory) do
    if Config.DisplayInShop ~= false then
        table.insert(TrailList, {
            Id = Id,
            Price = Config.Price or 0,
            Label = string.format("%s (x%s)", Config.DisplayName or Id, tostring(Config.SpeedMultiplier or 1)),
        })
    end
end

table.sort(TrailList, function(a, b)
    return a.Price < b.Price
end)

for _, Info in ipairs(TrailList) do
    table.insert(TrailItems, Info.Label)
end

do
    getgenv().Settings.Main.StealEggs = nil
    getgenv().Settings.Main.StealMutations = nil
    getgenv().Settings.Main.PlaceMutations = nil

    -- travel outruns every guard on the map, so the speed gates these three drove are gone:
    -- every selected area is raided whatever the sign on it says
    getgenv().Settings.Main.OnlyReachableAreas = nil
    getgenv().Settings.Main.FarmBeforeSteal = nil
    getgenv().Settings.Main.BlockRelocate = nil

    -- a settings file edited by hand can carry anything; the engine clamps what it reads
    -- anyway, and this only keeps the slider from opening on a number it cannot show
    if (tonumber(getgenv().Settings.Main.TweenSpeed) or 0) > TravelHardMax then
        getgenv().Settings.Main.TweenSpeed = 300
    end

    -- the server bat cooldown is 0.7s; a hand-edited file asking for less just wastes swings on
    -- REQUEST_COOLDOWN_ACTIVE, so the floor is pinned here too
    if (tonumber(getgenv().Settings.Main.AttackDelay) or 0) < 0.7 then
        getgenv().Settings.Main.AttackDelay = 0.7
    end

    if getgenv().Settings.Main.StealPriority == "Mutated" then
        getgenv().Settings.Main.StealPriority = "Rarest"
    end

    local Known = { }

    for _, Name in ipairs(EggItems) do
        Known[Name] = true
    end

    local Clean = { }

    for _, Value in ipairs(getgenv().Settings.Main.PlaceEggs or { }) do
        if Known[Value] then
            table.insert(Clean, Value)
        end
    end

    getgenv().Settings.Main.PlaceEggs = Clean

    local ByName = { }

    for _, Info in ipairs(TrailList) do
        ByName[string.match(Info.Label, "^(.-)%s*%(") or Info.Label] = Info.Label
    end

    local Trails = { }

    for _, Value in ipairs(getgenv().Settings.Main.BuyTrails or { }) do
        local Label = ByName[string.match(Value, "^(.-)%s*%(") or Value]

        if Label then
            table.insert(Trails, Label)
        end
    end

    getgenv().Settings.Main.BuyTrails = Trails

    SaveSetting()
end

---- ============ Character ============ ----

local function GetCharacter()
    return LocalPlayer.Character
end

local function GetRootPart()
    local Character = GetCharacter()

    return Character and Character:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local Character = GetCharacter()

    return Character and Character:FindFirstChildWhichIsA("Humanoid")
end

local function Alive()
    local Humanoid = GetHumanoid()

    return GetRootPart() ~= nil and Humanoid ~= nil and Humanoid.Health > 0
end

local function InGameplaySide(Position)
    return GuardLookup.IsInGameplaySide(SeparationLine, Position)
end

---- ============ Night (area reset) ============ ----

-- The map runs on a cycle of AreaEggCycle.ResetPeriodSeconds, which is 300, and the
-- tail of every period is night: Workspace.__OBJECTS.Areas.WallStartVisual rises out of the
-- ground, WallStartCollision turns solid for anyone standing on the base side, and every area
-- egg in the game is rerolled. Night is GetNightDurationSeconds() long -- Workspace's own
-- AreaEggCycleNightSeconds when the server has set one, and ten seconds when it has not.
--
-- Two things follow from that. A run started with less than a trip's worth of daylight left
-- arrives at an egg that no longer exists. And the travel engine noclips, so with no rule of
-- its own it walks straight through a closed wall and stands on the gameplay side while the
-- wall is up, which is not a place the game can put a player.
--
-- Behind one local, like the travel engine, because the main chunk is at Luau's ceiling of
-- 200 locals per function.
local Night = { }

do
    local ResetTime = require(Library2.Util.AreaEggCycle)
    local ResetWall = require(ReplicatedStorage:WaitForChild("Client").AreaEggResetWall)

    -- How much daylight a fresh steal run wants before it is worth starting. Fifteen rather
    -- than eight because the trip itself is twice as long as it used to be: the travel engine
    -- is capped at 200 studs/s now, and Cherry Blossom and back from the gate is 6700 studs,
    -- which is thirty-four seconds of the five minute period.
    Night.Margin = 15

    function Night.Now()
        local Ok, IsNight = pcall(ResetTime.IsNightPhase, workspace:GetServerTimeNow())

        return Ok and IsNight == true
    end

    -- seconds left in the phase we are in: daylight left during the day, night left during it
    function Night.PhaseLeft()
        local Ok, Left = pcall(ResetTime.SecondsUntilPhaseEnd, workspace:GetServerTimeNow())

        return (Ok and type(Left) == "number") and Left or math.huge
    end

    -- the client module the game itself drives, with the clock as the backstop for the moment
    -- between the wall going up and the module hearing about it
    function Night.WallClosed()
        local Ok, Closed = pcall(ResetWall.IsSealed)

        if Ok and Closed == true then return true end

        return Night.Now()
    end
end

local function GetSpeedPower()
    local Data = Save.Get()

    if Data and type(Data.SpeedPower) == "number" then
        return Data.SpeedPower
    end

    local Stats = LocalPlayer:FindFirstChild("leaderstats")
    local Value = Stats and Stats:FindFirstChild("Speed")

    return Value and (tonumber(Value.Value) or ParseSpeed(tostring(Value.Value))) or 0
end

local function RequiredSpeed(Info)
    if not Info then return math.huge end

    local Margin = 1 + math.max(getgenv().Settings.Main.SpeedMargin or 0, 0) / 100

    return math.max(Info.Required, SpeedPowerForWalkSpeed(Info.GuardSpeed * Margin))
end

local function TargetSpeed()
    local Main = getgenv().Settings.Main
    local Highest = 0

    for _, Label in ipairs(Main.StealAreas or { }) do
        local Info = AreaInfo[AreaByLabel[Label] or Label]

        if Info then
            Highest = math.max(Highest, RequiredSpeed(Info))
        end
    end

    return Highest
end

---- ============ Relocate ============ ----

-- The game's anti-cheat lives in ReplicatedFirst.UGI.ContentCatalog -- ModuleScripts parented to
-- nil, four of their functions connected to RunService. One of the two on PreSimulation and
-- PostSimulation whose source reads exactly "ReplicatedFirst.UGI.ContentCatalog" is the corrector:
-- disable it and the engine below can run at 400 studs/s, leave it and 200 is the ceiling.
--
-- The update put a watchdog next to it, and the watchdog is why this block is a pulse rather than
-- a switch. Decompiled, it reads four counters that only advance while those handlers run:
--
--     v48 = (v49 ~= v44 and v50 ~= v45 and v51 - v46 <= v52 - v47) and 0 or v48 + 1
--
--     if u34 <= v48 then
--         RootPart.Anchored = true
--         Humanoid.WalkSpeed = 0
--         Humanoid.Health = 0
--         u37.RigSync.SeedSatchel:FireServer("Character integrity execution was interrupted")
--         error("Character integrity execution was interrupted", 0)
--     end
--
-- Three numbers were measured against it, and every one of them is a hard edge:
--
--   handlers off, character standing perfectly still     dead at 3.25s and again at 3.31s.
--                                                        Position and speed have nothing to do
--                                                        with it -- only how long they were off
--
--   handing them back while the character is moving,     dead on two runs out of five. Standing
--   with the off-window kept down at 1.5s                still first is the only safe release
--
--   what the death costs                                 SeedSatchel and AskRigWipe both fire,
--                                                        and the server then refuses to respawn:
--                                                        CharacterAutoLoads true, RespawnTime 2,
--                                                        and the corpse was still anchored
--                                                        twenty-three seconds later. Only a
--                                                        rejoin clears it
--
-- Hence the shape below. The corrector goes off for BlockFor, the run is frozen where it stands,
-- the handlers go back on once the root part has actually stopped, they stay on for RestFor, and
-- the cycle repeats -- so the counters never stall for longer than the watchdog tolerates and no
-- release ever happens under a moving character.
--
-- What that buys, measured over forty-one seconds and thirteen pulses rather than predicted:
-- 8407 studs against the 8137 that 200 flat covers in the same time. Two hundred and seven
-- studs a second, so about three per cent, and the character stops dead every three seconds
-- to pay for it.
--
-- ALL OF THE ABOVE IS THE OLD ANTI-CHEAT AND THE PULSE NO LONGER SURVIVES IT.
--
-- The block is off by default now. What the game does today is give the server the position
-- outright, so switching the corrector off does not buy the run anything the server will keep:
-- the handlers come off, the character travels 600 studs at 400 studs/s, it stands perfectly
-- still for the full 1.1 second settle, the handlers go back on -- and it is dead inside a
-- tenth of a second, on the first pulse, every time. The same test with the release skipped
-- shows why: the 600 studs are only ever local, and the frame the corrector wakes up it drags
-- the root back and reads the difference as tampering.
--
--     shipped 1.5 / 1.1 / 0.3        pulse 1 done at 3.0s, 600 studs local, health 0, DIED
--     disable, 200 studs/s 2.5s,     500 studs kept while off, drift 4, health 100 --
--     then release with no settle    then dead 0.1s after the handlers went back
--
-- Everything below still works as written and is left in place because it costs nothing while
-- Enabled() is false. What replaced it is the Rig block: the corrector does not have to be
-- switched off if it is holding a Humanoid that is no longer in the character. Sixteen thousand
-- studs in forty seconds against this pulse's eight thousand, and nothing ever stops.
--
-- Four other ways round the watchdog were tried and none of them work:
--
--   hooking __namecall / __newindex to swallow the drag    dead, punish routine ran 825 times --
--                                                          a hooked metamethod is noticed
--   blocking whatever the server sends to drive it         nothing to block: six RigSync remotes
--                                                          across a 400 studs/s run, zero packets
--   hookfunction on the punish closure                     not detected, but the drag lives
--                                                          somewhere else and stayed
--   overwriting the snap-back from a held position         dead, 79 snap-backs in three seconds,
--                                                          and the same with every punish closure
--                                                          hooked: more than one kill site
--
-- Switches, all read live:
--
--   getgenv().ValkyrieRelocate       = true    opt in to the pulse. Measured lethal on the first
--                                              pulse against the current anti-cheat; the default
--                                              is off and travel runs on WalkSpeed * 1.9 instead
--   getgenv().ValkyrieRelocateBlock  = 1.5     seconds off per pulse, and the settle behind it
--                                              still has to fit under 3.25 -- raising this only
--                                              shortens the settle, it cannot buy more time
--   getgenv().ValkyrieRelocateSettle = 1.1     seconds of stillness before the handlers go back
--   getgenv().ValkyrieRelocateRest   = 0.3     seconds they stay on before the next pulse
local Relocate = { }

do
    local RunService = game:GetService("RunService")

    -- the corrector's own source. Its sibling on the same signal reads "...ContentCatalog.Surface"
    -- and is left alone.
    local CorrectorSource = "ReplicatedFirst.UGI.ContentCatalog"

    -- opt-in, not opt-out. It used to be the other way round; see the measurements above for why
    -- it is not any more.
    local function Enabled()
        return getgenv().ValkyrieRelocate == true
    end

    -- The whole of a pulse -- the seconds off plus however long the character takes to come to a
    -- stop afterwards -- has to finish inside the 3.25 seconds the watchdog allows, and this is
    -- what that leaves once the stop is paid for.
    --
    -- Two and a half was tried first and it is dead: two off plus a second and a half of settling
    -- is 3.5, and the run died at 3.1 without completing a single pulse. These numbers ran
    -- forty-one seconds and thirteen pulses with the character untouched.
    local Deadline = 3.25

    local function SettleFor()
        return math.clamp(tonumber(getgenv().ValkyrieRelocateSettle) or 1.1, 1, 1.6)
    end

    local function BlockFor()
        local Asked = math.clamp(tonumber(getgenv().ValkyrieRelocateBlock) or 1.5, 0.5, 2)

        -- whatever was asked for, the settle still has to fit under the deadline behind it
        return math.min(Asked, Deadline - SettleFor() - 0.5)
    end

    local function RestFor()
        return math.max(tonumber(getgenv().ValkyrieRelocateRest) or 0.3, 0.25)
    end

    local Blocked = false
    local Want = false

    -- true while the run has to hold still: the settle before a release, and the rest after one
    local Holding = false

    local BlockedAt = 0
    local RestUntil = 0

    -- Stillness, sampled on the same tick as everything else. Three studs is wider than a
    -- standing character's jitter and narrower than one frame of travel.
    local StillRadius = 3
    local LastPosition = nil
    local StillSince = 0

    local function TrackStillness(Now)
        local Root = GetRootPart()

        if not Root then
            LastPosition = nil
            StillSince = Now

            return
        end

        local Position = Root.Position

        if not LastPosition or (Position - LastPosition).Magnitude > StillRadius then
            StillSince = Now
        end

        LastPosition = Position
    end

    local function Still(Now)
        return Now - StillSince >= SettleFor()
    end

    local function EachCorrector(Apply)
        if not getconnections then return false end

        local Found = false

        for _, Signal in ipairs({ RunService.PostSimulation, RunService.PreSimulation }) do
            local Ok, List = pcall(getconnections, Signal)

            if Ok and type(List) == "table" then
                for _, Connection in ipairs(List) do
                    local Named, Source = pcall(debug.info, Connection.Function, "s")

                    if Named and Source == CorrectorSource then
                        if pcall(Apply, Connection) then
                            Found = true
                        end
                    end
                end
            end
        end

        return Found
    end

    -- whether the engine may ignore the WalkSpeed roof this frame
    function Relocate.Blocking()
        return Blocked
    end

    -- the travel engine reads this every frame and holds the character where it is
    function Relocate.Holding()
        return Holding
    end

    function Relocate.Want(On)
        Want = On == true

        if not Want then
            Holding = false
        end
    end

    local function Block()
        local Found = EachCorrector(function(Connection)
            if Connection.Enabled then
                Connection:Disable()
            end
        end)

        if Found and not Blocked then
            BlockedAt = os.clock()
        end

        Blocked = Blocked or Found

        return Blocked
    end

    -- Never called from anywhere but the tick and the cleanup below. Releasing under a moving
    -- character killed it on two runs out of five, so every caller has to have made it stand
    -- still first.
    local function Release()
        EachCorrector(function(Connection)
            if not Connection.Enabled then
                Connection:Enable()
            end
        end)

        Blocked = false
    end

    -- for cleanup, which cannot stand around waiting: the release goes to a thread that waits for
    -- the character to stop and gives up after eight seconds rather than leave the handlers off
    function Relocate.SafeRelease()
        Want = false
        Holding = false

        if not Blocked then return end

        task.spawn(function()
            local Deadline = os.clock() + 8

            while os.clock() < Deadline do
                local Now = os.clock()

                TrackStillness(Now)

                if Still(Now) then break end

                task.wait(0.1)
            end

            Release()
        end)
    end

    -- One pulse, one tick at a time. Called ten times a second, which is what keeps the off-window
    -- honest: at four times a second a single late tick is a quarter of the margin.
    function Relocate.Tick()
        local Now = os.clock()

        TrackStillness(Now)

        if not (Want and Enabled()) then
            Holding = false

            if Blocked and Still(Now) then
                Release()
            end

            return Blocked
        end

        -- resting: the handlers are on, the run is still frozen, and when the rest is over the
        -- next pulse starts
        if not Blocked and Now < RestUntil then
            Holding = true

            return false
        end

        -- Settling: the handlers are still off and the run has been told to stop. The release
        -- normally waits for the root part to have actually stopped, because letting go under a
        -- moving character killed it on two runs out of five.
        --
        -- Normally, and not past Deadline. Waiting there is the worse of the two deaths: a release
        -- under a moving character is a coin flip, and a pulse that outlives the watchdog is a
        -- certainty -- plus a report to the server and a corpse the server will not respawn. So
        -- the deadline releases whatever the character is doing.
        if Blocked and Now - BlockedAt >= BlockFor() then
            Holding = true

            if Still(Now) or Now - BlockedAt >= Deadline - 0.4 then
                Release()

                RestUntil = os.clock() + RestFor()
            end

            return Blocked
        end

        Holding = false

        return Block()
    end
end

-- Ten times a second rather than four. The tick is what ends a pulse before the watchdog does,
-- and the whole margin is 1.25 seconds -- a quarter second between checks spends a fifth of it.
-- It is also what re-blocks the handler the game reconnects when the character is rebuilt.
task.spawn(function()
    while getgenv().ValkyrieSession == SessionToken do
        pcall(Relocate.Tick)

        task.wait(0.1)
    end
end)

---- ============ Rig ============ ----

-- The corrector holds a reference to the Humanoid, and a reference is not a lookup.
--
-- Everything above this block fought the leash and lost. This does not fight it: the character's
-- Humanoid is cloned, the original is destroyed, and the clone is parented in its place. The
-- corrector, the watchdog and the character's own PushBack script all captured the original when
-- the character was built -- ContentCatalog's kill writes Humanoid.WalkSpeed = 0 and
-- Humanoid.Health = 0 straight at it -- so after the swap every one of them is holding an
-- instance that is no longer in the game, and the character they are writing at is not the
-- character that is walking around.
--
-- AntiCollisionHighSeedPushBack is the other half, and it is a LocalScript inside the character
-- rather than anything hidden. Decompiled, it is eight lines: on PostSimulation, if the humanoid
-- is Running and WalkSpeed >= 50 and the root is moving faster than 10, add -50 * delta to the
-- root's Y velocity. A downforce, aimed at flight rather than at travel, and it goes with the
-- humanoid because it captured that one too.
--
-- Measured on a WalkSpeed 16 character, in a server where thirty-two studs a second was lethal
-- four minutes earlier:
--
--     300 studs/s, 12s     3621 studs   0 snap-backs   drift 4   health 100
--     500 studs/s, 10s     5006 studs   0 snap-backs   drift 4   health 100
--     400 studs/s, 40s    16026 studs   0 snap-backs   drift 4   health 100
--
-- Against 8407 studs in 41 seconds for the pulse this replaces, and the pulse had to stand the
-- character still every three seconds to get them.
--
-- What it costs. Animate, Health and the game's own control module all captured the original
-- Humanoid the same way everything else did, so after a swap the character does not play its
-- walk animation, does not regenerate, and is not driven by the player's own input any more --
-- the engine moves the root part directly, which is what it was already doing. The swap is
-- redone after every respawn because the game builds a fresh Humanoid with it, and it is marked
-- with an attribute so a frame that has already swapped costs one GetAttribute.
--
-- getgenv().ValkyrieHumanoidSwap = false turns it off, and travel falls back to WalkSpeed * 1.9.
local Rig = { }

do
    function Rig.Swapped()
        local Humanoid = GetHumanoid()

        return Humanoid ~= nil and Humanoid:GetAttribute("ValkyrieTravelHum") == true
    end

    -- Idempotent and cheap on the frames that have nothing to do, because this is called from
    -- the render step: the attribute is on the Humanoid itself, so a character that has already
    -- been swapped is one property read.
    function Rig.Swap()
        if getgenv().ValkyrieHumanoidSwap == false then return false end

        local Character = GetCharacter()

        if not Character then return false end

        local Humanoid = Character:FindFirstChildOfClass("Humanoid")

        if not Humanoid then return false end
        if Humanoid:GetAttribute("ValkyrieTravelHum") == true then return true end

        local Fresh = Humanoid:Clone()

        Fresh:SetAttribute("ValkyrieTravelHum", true)
        Fresh.Sit = false
        Fresh.PlatformStand = false
        Fresh.AutoRotate = true

        Humanoid:Destroy()
        Fresh.Parent = Character

        -- the downforce, which captured the humanoid that has just gone but is still connected
        -- to PostSimulation and still holding the root part
        for _, Thing in ipairs(Character:GetDescendants()) do
            if Thing:IsA("LocalScript") and string.find(Thing.Name, "PushBack") then
                pcall(function()
                    Thing.Disabled = true
                    Thing:Destroy()
                end)
            end
        end

        pcall(function()
            Fresh:ChangeState(Enum.HumanoidStateType.Running)
        end)

        return true
    end

    -- The other direction. Everything Rig.Swap costs -- no walk animation, no health regen,
    -- no player input -- lasts exactly as long as the swapped Humanoid is in the character,
    -- and there is no reason to keep paying it once a steal run is over. Auto Farm Speed in
    -- particular reads a swapped Humanoid as a broken one: the treadmill still mounts, but the
    -- character stands on the pad in a T-pose and the run feels stuck, which is the "farm
    -- speed bug".
    --
    -- So the travel engine calls this on every leg that does not need the speed roof (see
    -- DecideRig): a fresh Humanoid the game's own scripts can bind to again goes back in, the
    -- animation driver and the control module are pointed at it, and the character looks and
    -- behaves normally until the next steal leg swaps it out once more.
    --
    -- Safe against the anti-cheat for the same reason the swap is: the corrector and the
    -- integrity watchdog captured the very first Humanoid the character was built with and
    -- never look it up again, so the instance they keep writing at stays destroyed through
    -- this swap too.
    function Rig.Restore()
        local Character = GetCharacter()

        if not Character then return false end

        local Humanoid = Character:FindFirstChildOfClass("Humanoid")

        if not Humanoid then return false end
        if Humanoid:GetAttribute("ValkyrieTravelHum") ~= true then return true end

        local Fresh = Humanoid:Clone()

        Fresh:SetAttribute("ValkyrieTravelHum", nil)
        Fresh.Sit = false
        Fresh.PlatformStand = false
        Fresh.AutoRotate = true

        Humanoid:Destroy()
        Fresh.Parent = Character

        -- the animation driver grabbed the Humanoid that has just gone; restarting the script
        -- is what makes it bind to the new one and play walk / run / idle again. Off the
        -- caller's thread so a restore from inside StartRender does not stall the leg.
        local Animate = Character:FindFirstChild("Animate")

        if Animate and Animate:IsA("LuaSourceContainer") then
            task.spawn(function()
                pcall(function()
                    Animate.Disabled = true
                    task.wait()
                    Animate.Disabled = false
                end)
            end)
        end

        -- the player's own control module caches the Humanoid on spawn and drives it every
        -- frame; hand it the replacement so WASD works between runs
        pcall(function()
            local PlayerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
            local Module = PlayerScripts
                and PlayerScripts:FindFirstChild("PlayerModule")
                and PlayerScripts.PlayerModule:FindFirstChild("ControlModule")

            if Module then
                local Control = require(Module)

                if type(Control) == "table" then
                    Control.humanoid = Fresh
                end
            end
        end)

        pcall(function()
            Fresh:ChangeState(Enum.HumanoidStateType.Running)
        end)

        return true
    end
end

---- ============ Movement ============ ----

local ArriveRadius = 6

local ApproachRadius = 15

local function Flat(Offset)
    return Vector3.new(Offset.X, 0, Offset.Z).Magnitude
end

local function Reached(Position, Radius)
    local Root = GetRootPart()

    return Root ~= nil and Flat(Root.Position - Position) <= (Radius or ArriveRadius)
end

-- The travel engine, the same one HazeSea.lua runs: a RenderStep that walks the root part
-- along a straight line one frame at a time, with the character noclipped, its falling
-- states switched off and an invisible platform kept under its feet so the humanoid never
-- decides it is airborne mid-flight.
--
-- One thing is deliberately different from HazeSea's copy.
--
-- The step distance used to be Humanoid.WalkSpeed * Delta, on the grounds that a frame of
-- travel should cover what a frame of walking covers. It runs off the Tween Speed slider now,
-- the same as HazeSea. WalkSpeed is a stat on a logarithmic curve here -- TreadmillUtil turns
-- 76M of Speed into 179 and nine billion into 247 -- so pinning travel to it means the trip
-- out to Cosmic and back is slow however much has been farmed, while the guard that wakes when
-- the egg leaves the nest walks at a flat 200.
--
-- The endpoint names this comment used to cite (`ClientCharacter: IntegrityHeartbeat`,
-- `ClientCharacter: IntegrityViolation`) do not exist. Constants.NETWORK_MAP.ClientCharacter
-- holds Ready, Update, Sync, CorrectionStarted, RequestCharacterReset, CheckInventory and
-- IntInventory, and the only one seen on the wire in a quiet session is CheckInventory, fired
-- every four seconds with the character model and a counter.
--
-- How fast the slider may be turned up is the anti-cheat's decision and not the server's, and
-- the answer it gives today is WalkSpeed * 2 -- so the slider asks for whatever it likes and
-- gets SpeedRoof(), which is that number with a margin. The two-ceiling arrangement that used
-- to live here went with the Relocate pulse; see TravelFactor at the top of the file.
--
-- Which puts WalkSpeed back in charge of travel after all, by a different road: not because a
-- frame of travel should cover a frame of walking, but because the corrector will not let it
-- cover more than two.
--
-- And HazeSea holds the character in place forever once it arrives (HoldCFrame) because the
-- farm never gives the character back. This one hands it back: the render step unbinds on
-- arrival and every part gets its CanCollide returned, otherwise the character would be left
-- standing on nothing the moment the platform went away.
--
-- The whole thing lives behind one local because the main chunk is close to Luau's ceiling
-- of 200 locals per function and thirty more would not fit.
local Travel = { }

do
    -- The travel engine, the same one HazeSea.lua runs: a RenderStep that walks the root part
    -- along a straight line one frame at a time, with the character noclipped, its falling
    -- states switched off and an invisible platform kept under its feet so the humanoid never
    -- decides it is airborne mid-flight.
    --
    -- The step distance comes off the Tween Speed slider, not Humanoid.WalkSpeed. See the note
    -- above the local for why.
    --
    -- And HazeSea holds the character in place forever once it arrives (HoldCFrame) because the
    -- farm never gives the character back. This one hands it back: the render step unbinds on
    -- arrival and every part gets its CanCollide returned, otherwise the character would be left
    -- standing on nothing the moment the platform went away.

    local RunService = game:GetService("RunService")
    local CollectionService = game:GetService("CollectionService")

    local MaxStep = 40

    -- The floor raycast is allowed to lift the character by this much in one frame and no
    -- more. See the clamp in OnStep.
    local MaxRise = 6

    local MoveTarget = nil
    local MoveDone = false
    local RenderBound = false

    -- Who the engine currently belongs to.
    --
    -- There is one render step and one MoveTarget for the whole file, and there is more than
    -- one loop that walks. The walk order is supposed to keep them apart, but it is checked
    -- inside MoveLoop rather than by the engine, and that leaves a hole big enough to hang the
    -- script on: the farm notices it has been preempted one frame after the steal run has
    -- already bound the engine and aimed it at an egg, and the first thing it does about it is
    -- call Travel.Stop -- which unbinds the render step out from under the steal run. The
    -- steal run keeps calling Travel.Aim at a target nothing is reading any more and stands
    -- perfectly still until its timeout runs out.
    --
    -- Measured, with the farm and the steal loop both on: sixty-five seconds parked at
    -- 618, -313 in the middle of Forest, not anchored, not moving, health full -- which is the
    -- farm's own sixty second Walk-to-the-treadmill timeout plus change.
    --
    -- So the engine hands out a token. Start takes one and stores it, Aim and Stop from
    -- anything else are refused, and a caller whose Aim comes back false has lost the engine
    -- and gives its leg up instead of fighting for it. Stop with no token is the forced
    -- version, for cleanup.
    local Owner = nil

    -- where the run was standing when the pulse asked it to hold. Held exactly, because a
    -- release is only survivable if the character really has stopped.
    local HoldAt = nil

    -- last time this asked the server to let the character off the treadmill; see OnStep
    local UnequipAt = 0

    -- A leg that must never sit on the plot treadmill, whatever the distance to its target.
    -- The chase sets this: it re-aims on the target every frame, so a target standing next to
    -- our own pad keeps the leg's target inside ApproachRadius and the OnStep doff exemption
    -- (meant for the farm mounting its own pad) would leave the chase anchored there.
    local NoMount = false

    -- Whether the current leg is worth the Humanoid swap. The swap lifts the speed roof from
    -- WalkSpeed * 1.9 to TravelHardMax, and it costs the character its animations, its health
    -- regen and its input for as long as it is in place -- so it only earns its keep on a leg
    -- that crosses to, or runs home from, the gameplay side. A base-side hop (the treadmill,
    -- the pen, the fuse machine) is short and slow enough to run on the game's own Humanoid,
    -- and Auto Farm Speed needs it that way: a swapped Humanoid on the treadmill stands in a
    -- T-pose and the run reads as stuck.
    --
    -- Decided once per leg in StartRender, off the leg's target and the character's position
    -- at that moment; OnStep only reads the flag, so a respawn mid-leg re-swaps on a steal
    -- leg and is left alone on a base-side one.
    local LegWantsRig = false

    local function DecideRig()
        local Root = GetRootPart()

        LegWantsRig = (MoveTarget ~= nil and InGameplaySide(MoveTarget))
            or (Root ~= nil and InGameplaySide(Root.Position))

        if LegWantsRig then
            Rig.Swap()
        else
            Rig.Restore()
        end
    end

    local function CancelTween()
        MoveTarget = nil
        MoveDone = true
    end

    --// Noclip
    local NoclipSaved = { }

    local function NoclipCharacter(Character)
        for _, Part in ipairs(Character:GetDescendants()) do
            if Part:IsA("BasePart") and Part.CanCollide then
                NoclipSaved[Part] = true
                Part.CanCollide = false
            end
        end
    end

    local function NoclipRestore()
        for Part in pairs(NoclipSaved) do
            if typeof(Part) == "Instance" and Part:IsA("BasePart") and Part.Parent then
                Part.CanCollide = true
            end
        end

        table.clear(NoclipSaved)
    end

    --// Ground state
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
                pcall(function()
                    Humanoid:SetStateEnabled(State, false)
                end)
            end

            if Humanoid:GetState() ~= Enum.HumanoidStateType.Running then
                pcall(function()
                    Humanoid:ChangeState(Enum.HumanoidStateType.Running)
                end)
            end

            GroundActive = true
            GroundHumanoid = Humanoid
        elseif GroundActive then
            for _, State in ipairs(GroundStates) do
                pcall(function()
                    Humanoid:SetStateEnabled(State, true)
                end)
            end

            GroundActive = false
            GroundHumanoid = nil
        end
    end

    --// Platform
    local PlatformPart = nil
    local PlatformThickness = 1
    local PlatformSize = Vector3.new(8, PlatformThickness, 8)

    local function DestroyPlatform()
        if PlatformPart then
            pcall(function()
                PlatformPart:Destroy()
            end)

            PlatformPart = nil
        end
    end

    local function GetFootOffset(Humanoid, Root)
        if Humanoid.RigType == Enum.HumanoidRigType.R6 then
            return 3
        end

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

    --// Traps
    --
    -- A trap freezes the character for seven seconds and empties its hands -- the gear's own
    -- description is "Place traps that freeze thieves for 7 seconds (3 Max)" -- so walking over
    -- one on the way home is how a carried egg gets dropped in front of whoever placed it.
    --
    -- They are BaseParts under workspace.__DEBRIS named PlayerTrap, each carrying the game's own
    -- PlacedTrap tag and a 2.9 x 1.6 x 2.8 Hitbox that catches by touch. The tag is what the
    -- game's own TrapGameplayHighlightController listens to, so that is the list used here; the
    -- folder is swept as well in case a freshly placed trap replicates before its tag does.
    local TrapTag = "PlacedTrap"

    -- steering starts at AvoidRadius and no step is ever taken inside ClearRadius. The hitbox
    -- half-diagonal is about 2, and the character is about 2 wide, so 5.5 clears it with room
    -- for a frame of drift.
    local TrapAvoidRadius = 10
    local TrapClearRadius = 5.5

    -- Two things the avoidance below could not do, and both of them ended the same way: the
    -- render step still running, the character standing perfectly still, and nothing noticing
    -- until the leg's own hundred and twenty second timeout ran out.
    --
    -- It only ever tried three headings -- the steered one and ninety degrees either side of
    -- it. Two traps set down at an angle to each other cover all three at once, and the step
    -- that "stayed put for this frame" then stayed put for every frame after it. That is the
    -- diagonal pair that freezes the run.
    --
    -- And it could not walk out of a trap it was already inside, because every candidate from
    -- in there is inside it too.
    --
    -- What replaces it: a fan of headings rather than three, an escape step that ignores the
    -- target entirely while the character is on a hitbox, and -- when the floor really is
    -- walled off -- a lift straight over the top. A trap is an ankle-high box that catches by
    -- touch, and the character is noclipped with its own platform under its feet, so flying
    -- the step over the lids is the one bypass no arrangement of traps on the ground can
    -- block.
    local TrapLiftClearance = 3

    -- a lift is held this long past the last blocked frame, so a run crossing a field of them
    -- does not bob up and down through it
    local TrapLiftHold = 0.6

    local LiftUntil = 0

    -- The headings tried when the steered one is blocked: straight on, then out to sixty
    -- degrees either side. It stops there on purpose. Wider than that is not a dodge, it is a
    -- detour around the whole line -- and the traps that cause this are laid down in a
    -- diagonal line for exactly that reason. Past sixty degrees the lift is both shorter and
    -- certain, so that is what happens instead.
    local TrapFan = { 0 }

    for Degrees = 20, 60, 20 do
        table.insert(TrapFan, math.rad(Degrees))
        table.insert(TrapFan, -math.rad(Degrees))
    end

    local function Rotate(Direction, Angle)
        local Cos, Sin = math.cos(Angle), math.sin(Angle)

        return Vector3.new(
            Direction.X * Cos - Direction.Z * Sin,
            0,
            Direction.X * Sin + Direction.Z * Cos
        )
    end

    local TrapList, TrapListAt = nil, 0

    local function PlacedTraps()
        local Now = os.clock()

        if TrapList and Now - TrapListAt < 0.5 then return TrapList end

        local List = { }
        local Seen = { }

        for _, Trap in ipairs(CollectionService:GetTagged(TrapTag)) do
            if Trap:IsA("BasePart") and Trap:IsDescendantOf(workspace) and not Seen[Trap] then
                Seen[Trap] = true

                table.insert(List, Trap)
            end
        end

        local Debris = workspace:FindFirstChild("__DEBRIS")

        if Debris then
            for _, Child in ipairs(Debris:GetChildren()) do
                if Child:IsA("BasePart") and Child.Name == "PlayerTrap" and not Seen[Child] then
                    Seen[Child] = true

                    table.insert(List, Child)
                end
            end
        end

        TrapList, TrapListAt = List, Now

        return List
    end

    -- a potential field: every trap inside AvoidRadius pushes the heading away from itself,
    -- harder the closer it is, and the pushes are added to the heading before the step is taken.
    -- Walking straight at one bends the path around it instead of stopping the run.
    local function SteerPastTraps(Origin, Direction)
        local Traps = PlacedTraps()

        if #Traps == 0 then return Direction end

        local Push = Vector3.zero

        for _, Trap in ipairs(Traps) do
            local Offset = Vector3.new(Origin.X - Trap.Position.X, 0, Origin.Z - Trap.Position.Z)
            local Distance = Offset.Magnitude

            if Distance < TrapAvoidRadius then
                local Away

                if Distance > 0.1 then
                    Away = Offset / Distance
                else
                    -- standing on top of one: step out sideways rather than nowhere
                    Away = Vector3.new(-Direction.Z, 0, Direction.X)
                end

                Push = Push + Away * ((TrapAvoidRadius - Distance) / TrapAvoidRadius)
            end
        end

        if Push.Magnitude < 0.01 then return Direction end

        local Steered = Vector3.new(Direction.X + Push.X * 1.5, 0, Direction.Z + Push.Z * 1.5)

        if Steered.Magnitude < 0.01 then
            return Vector3.new(-Direction.Z, 0, Direction.X)
        end

        return Steered.Unit
    end

    local function TrapAt(Position)
        for _, Trap in ipairs(PlacedTraps()) do
            if Flat(Position - Trap.Position) < TrapClearRadius then return Trap end
        end
    end

    -- A step is only clear if the whole of it is. Testing the endpoint alone walks straight
    -- through a trap sitting between here and there, which at 400 studs/s is most of them.
    local function StepClear(Origin, Direction, Step)
        for Index = 1, 3 do
            local At = Origin + Direction * (Step * Index / 3)

            if TrapAt(At) then return false end
        end

        return true
    end

    -- The way out of a trap the character is already standing on. The target does not come
    -- into it: nothing else matters until the hitbox is behind us.
    local function TrapEscape(Origin)
        local Push = Vector3.zero
        local Inside = false

        for _, Trap in ipairs(PlacedTraps()) do
            local Offset = Vector3.new(Origin.X - Trap.Position.X, 0, Origin.Z - Trap.Position.Z)
            local Distance = Offset.Magnitude

            if Distance < TrapClearRadius then
                Inside = true

                if Distance > 0.1 then
                    Push = Push + (Offset / Distance) * (TrapClearRadius - Distance + 1)
                else
                    Push = Push + Vector3.new(1, 0, 0)
                end
            end
        end

        if not Inside then return nil end
        if Push.Magnitude < 0.01 then return Vector3.new(1, 0, 0) end

        return Push.Unit
    end

    -- The highest trap lid within steering range of a point, which is the height a lift has to
    -- clear. It is the Hitbox child that has to be cleared and not the mesh: measured on a
    -- placed trap, the MeshPart is 0.58 tall and its top sits at y 68.07, while the Hitbox
    -- welded to it is 1.61 tall and reaches 69.09 -- and the Hitbox is the part carrying the
    -- TouchTransmitter.
    local function TrapTopNear(Position)
        local Top = nil

        for _, Trap in ipairs(PlacedTraps()) do
            if Flat(Position - Trap.Position) < TrapAvoidRadius then
                local Box = Trap:FindFirstChild("Hitbox")
                local Lid

                if Box and Box:IsA("BasePart") then
                    Lid = Box.Position.Y + Box.Size.Y * 0.5
                else
                    Lid = Trap.Position.Y + Trap.Size.Y * 0.5
                end

                if not Top or Lid > Top then Top = Lid end
            end
        end

        return Top
    end

    --// Ground follow
    local GroundParams = RaycastParams.new()

    GroundParams.FilterType = Enum.RaycastFilterType.Exclude

    local function GroundHeight(X, Z, FromY)
        local Ignore = { }
        local Character = GetCharacter()

        if Character then table.insert(Ignore, Character) end
        if PlatformPart then table.insert(Ignore, PlatformPart) end

        -- never land on a trap, and never let one count as the floor
        local Debris = workspace:FindFirstChild("__DEBRIS")

        if Debris then table.insert(Ignore, Debris) end

        GroundParams.FilterDescendantsInstances = Ignore

        local Hit = workspace:Raycast(Vector3.new(X, FromY + 12, Z), Vector3.new(0, -240, 0), GroundParams)

        return Hit and Hit.Position.Y or nil
    end

    --// Progress watchdog
    --
    -- Every way this engine has ever hung looks identical from outside: the render step keeps
    -- running, the character does not move, and MoveLoop sits on its own deadline -- a hundred
    -- and twenty seconds for a leg of a steal run -- before anything at all notices. The trap
    -- deadlock was one cause; an untagged trap, a hitbox that replicated late, or a piece of
    -- scenery the floor raycast will not let go of are others, and there is no reason to
    -- enumerate them.
    --
    -- So the step reports its distance to the target on every frame and the run is measured on
    -- whether that distance is still falling. Nothing for LiftAfter and the next step goes
    -- over the top whatever the traps say; nothing for GiveUpAfter and the leg is declared
    -- lost, which turns a two minute freeze into one retry.
    local StallAt = 0
    local StallBest = math.huge
    local StallLift = false

    local StallLiftAfter = 1.5
    local StallGiveUpAfter = 8

    local function ResetStall()
        StallAt = os.clock()
        StallBest = math.huge
        StallLift = false
    end

    -- Caught in somebody's trap. The gear's own line is "Place traps that freeze thieves for
    -- 7 seconds (3 Max)", and the client is told about it through one attribute on the
    -- character: TrappedBackpackController watches IsTrapped and locks the backpack off it.
    --
    -- The hold itself is the server's, so nothing written during it survives the next
    -- replication tick. It is worth knowing about anyway -- a run that cannot tell a seven
    -- second freeze from a hang treats one as the other.
    local function Trapped()
        local Character = GetCharacter()

        return Character ~= nil and Character:GetAttribute("IsTrapped") == true
    end

    local function Progress(Distance)
        local Now = os.clock()

        -- half a stud, so a character jittering in place is not mistaken for one making
        -- headway
        if Distance < StallBest - 0.5 then
            StallBest = Distance
            StallAt = Now
            StallLift = false

            return
        end

        if Now - StallAt > StallLiftAfter then
            StallLift = true
        end
    end

    local function OnStep(Delta)
        local Target = MoveTarget

        if not Target then return end

        -- Before the Humanoid is read, not after: a respawn mid-leg puts the game's own Humanoid
        -- back and the leash with it, and the frame that notices has to be the frame that fixes
        -- it. One GetAttribute on every frame that has nothing to do. Only on a leg that wants
        -- the swap, though -- a base-side hop keeps the game's Humanoid so the character keeps
        -- its animations and the treadmill mount behaves.
        if LegWantsRig then
            Rig.Swap()
        end

        local Character = GetCharacter()
        local Root = GetRootPart()
        local Humanoid = GetHumanoid()

        -- no character to move: a respawn is on its way and takes a few seconds, which is not
        -- the leg's fault and is not counted against it
        if not (Character and Root and Humanoid and Humanoid.Health > 0) then
            StallAt = os.clock()

            return
        end

        NoclipCharacter(Character)
        SetGroundState(true)

        -- Caught. The hold is the server's and it lasts seven seconds, so every CFrame written
        -- into it is thrown away on the next replication tick -- there is nothing to do but sit
        -- it out. The noclip, the ground state and the platform all stay, and the watchdog's
        -- clock is pushed along so a legitimate freeze is not counted as a hang.
        if Trapped() then
            StallAt = os.clock()

            UpdatePlatform(Humanoid, Root)

            return
        end

        -- The game puts the character on the treadmill by itself. TreadmillStaticController
        -- runs tryEnterStaticTreadmill on RunService.Heartbeat, and it equips the moment a
        -- ray straight down from the root part hits the plot's own treadmill model -- no
        -- button, no remote from us, just standing there. Mounting anchors the root, and an
        -- anchored root belongs to the server: the CFrame written below is thrown away on the
        -- next replication tick and the run stops dead on the pad with the character in its
        -- running animation, going nowhere. Crossing the plot on the way to the pen is enough
        -- to trigger it.
        --
        -- Measured: dropped on TreadmillBottom without touching a single remote, anchored by
        -- itself 1.5 seconds later.
        --
        -- So a run that finds itself anchored asks to be let off. Once a second is plenty --
        -- the controller puts a 1.25 second cooldown on re-entry anyway -- and the invoke goes
        -- to its own thread because this is a render step.
        -- and the leg that is deliberately arriving at the treadmill is left alone: the farm
        -- walks onto the pad on purpose, and the auto-mount landing a frame before MoveLoop
        -- notices it has arrived is the mount it wanted, not one to escape from -- unless the
        -- leg set NoMount, which the chase does: it never wants a mount at any distance.
        if Root.Anchored and (NoMount or Flat(Target - Root.Position) > ApproachRadius) then
            local Now = os.clock()

            if Now - UnequipAt > 1 then
                UnequipAt = Now

                task.spawn(function()
                    pcall(Network.Invoke, "RF/Treadmill/AskDoff")
                end)
            end

            return
        end

        -- The pulse is between handing the corrector back and picking the run up again, and
        -- standing still is the whole reason that release does not kill the character. Nothing is
        -- unbound and nothing is unnoclipped: the leg carries on from here.
        if Relocate.Holding() then
            HoldAt = HoldAt or Root.Position

            -- standing still is the point of the hold, so it is not a stall
            StallAt = os.clock()

            Root.CFrame = CFrame.new(HoldAt) * (Root.CFrame - Root.CFrame.Position)
            Root.AssemblyLinearVelocity = Vector3.zero
            Root.AssemblyAngularVelocity = Vector3.zero

            UpdatePlatform(Humanoid, Root)

            return
        end

        HoldAt = nil

        local Origin = Root.Position
        local Offset = Vector3.new(Target.X - Origin.X, 0, Target.Z - Origin.Z)
        local Remaining = Offset.Magnitude

        if Remaining < 0.05 then
            MoveDone = true

            ResetStall()

            return
        end

        Progress(Remaining)

        -- The Tween Speed slider asks, and what it gets depends on whose Humanoid is in the
        -- character. Swapped, there is no leash and the slider may have what it asked for.
        -- Not swapped -- the swap turned off, or a respawn a frame ago -- the corrector allows
        -- twice WalkSpeed and kills a couple of seconds above it, so the roof is read fresh
        -- every frame off the Humanoid this frame actually has.
        --
        -- Clamped here as well as on the slider because a settings file edited by hand reaches
        -- the engine without passing through the callback.
        local Roof = (Rig.Swapped() or Relocate.Blocking()) and TravelHardMax
            or math.min(Humanoid.WalkSpeed * TravelFactor, TravelHardMax)

        local Speed = math.clamp(tonumber(getgenv().Settings.Main.TweenSpeed) or 300, 1, math.max(Roof, 16))
        local Step = math.min(Speed * Delta, MaxStep, Remaining)

        local Heading = Offset / Remaining
        local Direction = nil
        local Lift = false

        local Escape = TrapEscape(Origin)

        if Escape then
            -- On a hitbox. Off it first, and at a stride worth taking -- a frame's worth at a
            -- low Tween Speed is not enough to get clear of one.
            Direction = Escape
            Step = math.min(math.max(Step, 3), MaxStep)
            Lift = true
        else
            -- the gentle bend first, because a path that curves around a trap is shorter than
            -- one that turns off it at an angle
            local Steered = SteerPastTraps(Origin, Heading)

            if StepClear(Origin, Steered, Step) then
                Direction = Steered
            else
                -- straight on, then wider and wider to either side, then straight back
                for _, Angle in ipairs(TrapFan) do
                    local Candidate = Rotate(Heading, Angle)

                    if StepClear(Origin, Candidate, Step) then
                        Direction = Candidate

                        break
                    end
                end
            end
        end

        -- Every heading on the floor is covered, which is what a pair of traps set down at an
        -- angle to each other does. The old version stood still here and stayed standing; this
        -- keeps the heading it wanted and flies the step over the lids instead.
        if not Direction then
            Direction = Heading
            Lift = true
        end

        -- and the same bypass for anything the trap list cannot see -- an untagged trap, a
        -- hitbox that replicated late, a rock the floor raycast will not let go of. Whatever it
        -- is, a run that has not moved for a second and a half goes over it.
        if StallLift then
            Lift = true
        end

        local Now = os.clock()

        if Lift then
            LiftUntil = Now + TrapLiftHold
        end

        local Next = Vector3.new(Origin.X + Direction.X * Step, 0, Origin.Z + Direction.Z * Step)

        local Ground = GroundHeight(Next.X, Next.Z, Origin.Y)
        local NextY = Ground and (Ground + GetFootOffset(Humanoid, Root)) or Origin.Y

        -- Never climb onto the thing the run is meant to pass through. The character is
        -- noclipped, so a wall, a rock or a guard's hut in the way is not an obstacle -- but
        -- the floor raycast lands on its lid, the run rides up on top of it, and from up
        -- there it is off the flat ground and inside the scenery. That is what looks like
        -- getting stuck on a wall. A rise of more than one step's worth is scenery, not
        -- floor: hold the height we are at and walk straight through it.
        if NextY > Origin.Y + MaxRise then
            NextY = Origin.Y
        end

        -- The lift. Feet clear the highest lid within steering range by TrapLiftClearance, and
        -- the height is held for a moment past the last blocked frame so a run crossing a field
        -- of traps does not bob through it. GetFootOffset is the distance from the root part's
        -- centre down to the soles, which is what turns a foot height into a root height.
        if Now < LiftUntil then
            local Lid = TrapTopNear(Next) or TrapTopNear(Origin)

            if Lid then
                NextY = math.max(NextY, Lid + TrapLiftClearance + GetFootOffset(Humanoid, Root))
            elseif StallLift then
                -- nothing in the trap list to clear, and the run is getting nowhere anyway.
                -- Whatever is holding it is on the ground, so leave the ground.
                NextY = math.max(NextY, Origin.Y + MaxRise)
            end
        end

        local Position = Vector3.new(Next.X, NextY, Next.Z)

        Root.CFrame = CFrame.lookAt(Position, Position + Vector3.new(Direction.X, 0, Direction.Z))
        Root.AssemblyLinearVelocity = Vector3.zero
        Root.AssemblyAngularVelocity = Vector3.zero

        UpdatePlatform(Humanoid, Root)
    end

    local function StartRender()
        if RenderBound then return end

        RenderBound = true
        MoveDone = false

        -- the first frame of the leg should already be off the leash rather than one frame
        -- behind it -- or, on a base-side leg, already back on the game's own Humanoid so the
        -- character has its animations and the treadmill mount works
        DecideRig()

        -- the pulse starts here and nowhere else, and the tick is called on the spot rather than
        -- left to its own tenth of a second so the first frame of the run is already clear
        Relocate.Want(true)
        pcall(Relocate.Tick)

        RunService:BindToRenderStep("Valkyrie_Travel", Enum.RenderPriority.Camera.Value - 1, OnStep)
    end

    local function StopRender()
        if not RenderBound then
            MoveTarget = nil

            -- nothing was bound, but the want flag may still be up from a start that never got a
            -- frame; drop it either way so the corrector does not sit off for nothing
            Relocate.Want(false)
            pcall(Relocate.Tick)

            return
        end

        RenderBound = false
        MoveTarget = nil
        HoldAt = nil

        -- a leg that ended abnormally must not leave the farm unable to mount its own pad
        NoMount = false

        -- The want flag drops here and the handlers come back a moment later, once the tick has
        -- seen the character stop. A next leg that starts inside that moment simply keeps the
        -- pulse running, which is what a planned route wants.
        Relocate.Want(false)
        pcall(Relocate.Tick)

        pcall(function()
            RunService:UnbindFromRenderStep("Valkyrie_Travel")
        end)

        SetGroundState(false)
        NoclipRestore()
        DestroyPlatform()

        -- put the character back on the floor it is standing over, so letting go of it does not
        -- start a fall through the map
        local Root = GetRootPart()
        local Humanoid = GetHumanoid()

        if Root and Humanoid then
            Root.AssemblyLinearVelocity = Vector3.zero
            Humanoid:MoveTo(Root.Position)
        end
    end
    -- Taking the engine. The last caller in wins, which is what the walk order already
    -- decided; the point of the token is that the loser finds out.
    function Travel.Start(Position, Token)
        Owner = Token or { }
        MoveTarget = Position

        ResetStall()
        StartRender()

        return Owner
    end

    -- The chase turns this on so OnStep escapes any auto-mount at any distance; every other
    -- leg leaves it off so the farm can still mount its own pad on purpose.
    function Travel.NoMount(Value)
        NoMount = Value == true
    end

    -- false means somebody else owns the engine now. The caller's leg is over.
    function Travel.Aim(Position, Token)
        if Token ~= nil and Owner ~= Token then return false end

        -- MoveLoop re-aims at the same spot every pass, and only a real change of target is a
        -- reason to start the watchdog's clock again
        if MoveTarget == nil or (MoveTarget - Position).Magnitude > 0.1 then
            ResetStall()
        end

        MoveTarget = Position

        return true
    end

    -- True once the leg has been getting nowhere long enough that finishing it is not going to
    -- happen. Ending on this rather than on the leg's own timeout is the difference between one
    -- retry and two minutes of standing in a field.
    function Travel.Stalled()
        if not (RenderBound and MoveTarget) then return false end

        return os.clock() - StallAt > StallGiveUpAfter
    end

    -- A stop from anything but the current owner is ignored, because it is the loser of a
    -- handover tidying up after a leg that already belongs to somebody else. Cleanup passes no
    -- token and stops it regardless.
    function Travel.Stop(Token)
        if Token ~= nil and Owner ~= Token then return false end

        Owner = nil

        StopRender()

        return true
    end

    function Travel.Cancel()
        CancelTween()
    end
end

---- ============ Walk order ============ ----

local ManualKey = "Manual"

local WalkRank = { }

for Index, Key in ipairs({
    ManualKey,

    -- Attack Player is one name off a dropdown and a toggle the player reached for on purpose,
    -- so it takes the character off every automatic loop the same way a button press does.
    "AttackPlayer",

    "AutoStealEgg",

    -- Under stealing, and that is the way round it goes: an infested egg in a nest is gone the
    -- moment somebody else reaches it, while the monster stands on our own plot and the chest it
    -- owes us is not going anywhere. Above the plot chores for the same reason they sit below
    -- everything -- placing and fusing keep.
    "AutoMonsterParasite",
    "AutoPlaceEgg",
    "AutoFuse",
    "AutoFarmSpeed",
}) do
    WalkRank[Key] = Index
end

local WalkOwner = nil

local function ClaimWalk(Key)
    local Rank = WalkRank[Key]

    if not Rank then return true end

    local Held = WalkOwner and WalkRank[WalkOwner]

    if Held and Held < Rank then return false end

    WalkOwner = Key

    return true
end

local function ReleaseWalk(Key)
    if WalkOwner == Key then
        WalkOwner = nil
    end
end

local function Preempted(Key)
    local Rank = WalkRank[Key]

    if not Rank then return false end
    if WalkOwner == nil or WalkOwner == Key then return false end

    return (WalkRank[WalkOwner] or math.huge) < Rank
end

local function Active(Key)
    if getgenv().ValkyrieSession ~= SessionToken then return false end
    if Key == nil then return true end

    if Key ~= ManualKey and getgenv().Settings.Main[Key] ~= true then return false end

    return not Preempted(Key)
end

-- Same signature the walking version had, so every call site below is untouched: it drives
-- the render step above instead of Humanoid:MoveTo, and gives the character back the moment
-- it arrives, is aborted, or runs out of time.
local function MoveLoop(Position, Key, Timeout, Abort, StopRadius)
    local Deadline = tick() + (Timeout or 120)
    local Stop = StopRadius or ArriveRadius

    local Root = GetRootPart()

    if not Root then return false end
    if Flat(Root.Position - Position) <= Stop then return true end

    -- asked to go somewhere it is already meant to give up on: binding the render step for
    -- one frame just to unbind it would toggle the character's collisions for nothing. The
    -- egg recovery leans on this, because it walks home with an abort that is already true.
    if Abort and Abort() then return false end
    if not (Active(Key) and Alive()) then return false end

    -- one token per leg, so a leg can only ever stop the engine it started itself
    local Token = Travel.Start(Position, { })

    local Arrived = false

    while tick() < Deadline do
        if not (Active(Key) and Alive()) then break end
        if Abort and Abort() then break end

        -- the engine says this leg is going nowhere. Give it up here instead of standing
        -- through the rest of the timeout: the caller's next pass replans the route, and by
        -- then whoever set the traps down has usually moved on.
        if Travel.Stalled() then break end

        Root = GetRootPart()

        if not Root then break end

        if Flat(Root.Position - Position) <= Stop then
            Arrived = true

            break
        end

        -- the character can be respawned or shoved by the game between frames; keeping the
        -- target on every pass is what makes the run pick itself back up. A refusal means a
        -- higher ranked loop has taken the engine, and this leg is over.
        if not Travel.Aim(Position, Token) then return false end

        task.wait()
    end

    Travel.Stop(Token)

    return Arrived or Reached(Position, Stop)
end

-- ============ Route planning ============
--
-- The ten gameplay areas sit in a single row along +X -- Forest at x 600, Cherry Blossom at
-- x 3928 -- and every one of them is 150 studs deep in Z around the same centre line, which
-- is StartArea's own Z. Their nests are scattered across that depth.
--
-- Sweeping the row with a raycast at head height shows the middle of it is empty: from the
-- gate at x 555 to the far wall past Cherry Blossom at x 4234 there is nothing on that line
-- at all. Every wall, rock, hut and guard in the game is off it.
--
-- The travel engine walks a straight line, so a run aimed at a nest at the back of a far
-- area leaves that empty line in its first hundred studs and spends the rest of the trip
-- inside other areas' scenery. That is the "stuck on a wall".
--
-- So a run is planned as legs instead of aimed as one shot: onto the centre line, back to
-- the gate at the base, along the line to the target area's own X, and only then across the
-- area's depth to the egg. Behind one local, like Travel and Night, because the main chunk
-- is at Luau's ceiling of 200 locals per function.
local Route = { }

do
    local CorridorZ = StartArea.Position.Z
    local CorridorY = StartArea.Position.Y

    -- inside this much of the centre line there is nothing to route around
    local CorridorBand = 12

    -- a move no longer than this is a nudge, not a trip, and planning one costs more than it
    -- saves -- TryCarry's hop onto an egg is the one that matters
    local NearEnough = 80

    -- the footprints stop a little short of the scenery that belongs to them, and a nest at
    -- the very back of an area can sit just outside its own Bounds. Without this, an egg out
    -- there reads as "no area" and every retry on it plans a fresh trip to the base.
    local BoundsMargin = 20

    -- the area whose footprint a point is standing on, or nil for the base side and the gaps
    function Route.AreaAt(Position)
        for _, Info in ipairs(AreaList) do
            local Bounds = Info.Bounds

            if Bounds and Bounds:IsA("BasePart") then
                local Local = Bounds.CFrame:PointToObjectSpace(Position)
                local Size = Bounds.Size

                if math.abs(Local.X) <= Size.X * 0.5 + BoundsMargin
                    and math.abs(Local.Z) <= Size.Z * 0.5 + BoundsMargin
                then
                    return Info
                end
            end
        end
    end

    -- the waypoints to touch before the final leg, in order
    function Route.Plan(From, To)
        local Plan = { }

        local FromOut = InGameplaySide(From)
        local ToOut = InGameplaySide(To)

        -- both ends on the base side: open ground, nothing to plan
        if not (FromOut or ToOut) then return Plan end

        -- a step onto something we are already standing next to, on our own side of the line
        if FromOut == ToOut and Flat(To - From) <= NearEnough then return Plan end

        -- already standing in the area the egg is in: the last leg is all that is left, and
        -- a trip back to the gate for it would only cost daylight
        if FromOut and ToOut then
            local FromArea = Route.AreaAt(From)

            if FromArea and FromArea == Route.AreaAt(To) then return Plan end
        end

        -- out of whatever area we are standing in, sideways onto the centre line first
        if FromOut and math.abs(From.Z - CorridorZ) > CorridorBand then
            table.insert(Plan, Vector3.new(From.X, CorridorY, CorridorZ))
        end

        -- The gate, and only when the separation line is actually being crossed.
        --
        -- It used to go into every plan, whatever the two ends were. So a hop from one area
        -- to the one next door became a trip all the way home and back out again: the run
        -- walking away from the egg it had just been sent for, touching the gate, then walking
        -- back out past where it started. From Cosmic to Prehistoric that is 2600 studs in the
        -- wrong direction before the first stud in the right one, and with the picker changing
        -- its mind between passes it reads as the character tweening back and forth doing
        -- nothing.
        --
        -- Nothing needs it. Sweeping the centre line with a raycast at head height, from the
        -- gate at x 560 to x 4230 in twenty stud steps, returns exactly one hit in the whole
        -- run -- Workspace.IncubatorDead.Gems2 at x 4220, at the far end of Cherry Blossom and
        -- past every nest. So any two areas are joined along that line without the base coming
        -- into it at all, and the line only has to be crossed at the gate, which is the one
        -- case left here.
        if FromOut ~= ToOut then
            table.insert(Plan, StartArea.Position)
        end

        -- along the centre line to the target's X, and only then off it
        if ToOut and math.abs(To.Z - CorridorZ) > CorridorBand then
            table.insert(Plan, Vector3.new(To.X, CorridorY, CorridorZ))
        end

        return Plan
    end
end

local function Walk(Position, Key, Timeout, Abort, StopRadius)
    local Root = GetRootPart()

    if not Root then return false end

    -- the wall is up and we are on the wrong side of it. Walking home is always allowed;
    -- walking in is not, because the only way in right now is the noclip.
    if Night.WallClosed() and InGameplaySide(Position) and not InGameplaySide(Root.Position) then
        return false
    end

    local Deadline = tick() + (Timeout or 120)

    for _, Point in ipairs(Route.Plan(Root.Position, Position)) do
        local Left = Deadline - tick()

        if Left <= 0 then return false end
        if not MoveLoop(Point, Key, Left, Abort) then return false end
    end

    return MoveLoop(Position, Key, math.max(Deadline - tick(), 0), Abort, StopRadius)
end

-- The last few studs onto the exact spot. This used to anchor the root and hand the move to
-- TweenService at a clamped 40-300 speed, which is both a speed the character cannot walk at
-- and an anchored root the server never sees move. It runs on the same render step as
-- everything else now, at the character's own WalkSpeed, and it dodges traps on the way in.
local function TweenTo(Position, Key)
    local Root = GetRootPart()

    if not (Root and Active(Key) and Alive()) then return false end

    local Distance = Flat(Position - Root.Position)

    if Distance <= 0.5 then return true end

    if Distance > ApproachRadius + ArriveRadius then return false end

    return MoveLoop(Position, Key, 15, nil, 0.5)
end

local function Approach(Position, Key, Timeout)
    if not Walk(Position, Key, Timeout, nil, ApproachRadius) then return false end

    TweenTo(Position, Key)

    return true
end

---- ============ Treadmill (Auto Pen) ============ ----

local OnTreadmill = false

TrackConnection(Network.Fired("RE/Treadmill/AssignedBeltShifted"):Connect(function(TreadmillId)
    OnTreadmill = TreadmillId ~= nil
end))

local function GetTreadmillBottom()
    local Data = PlotCmds.GetPlotData()

    if not Data then return end

    local Bottom = Data.PlotFolder:FindFirstChild("TreadmillBottom")

    return Bottom and Bottom:IsA("BasePart") and Bottom or nil
end

local function StartTreadmill()
    local Ok, Result, Reason = pcall(Network.Invoke, "RF/Treadmill/AskWearStill")

    if not Ok then return false end

    if Result == true then
        OnTreadmill = true

        return true
    end

    if Reason == "Already using treadmill" then
        OnTreadmill = true

        return true
    end

    return false
end

local function OffTreadmill()
    local Root = GetRootPart()

    return Root == nil or not Root.Anchored
end

-- The signal is the fast answer and the anchored root is the honest one. `Treadmills:
-- ActiveTreadmillChanged` is the only thing that used to set OnTreadmill, so a signal that
-- never arrived -- or one that arrived before a respawn put the character back on the belt --
-- left the script believing it was free while the server had the root nailed down. An
-- anchored root cannot be moved by the travel engine, which is what a walk that goes nowhere
-- for its whole timeout actually is.
local function StopTreadmill()
    -- kept inline rather than as another top level local: the main chunk is close to Luau's
    -- ceiling of 200 locals per function
    local Root = GetRootPart()

    if not (OnTreadmill or (Root ~= nil and Root.Anchored)) then return true end

    for Attempt = 1, 3 do
        -- a throwing invoke costs this attempt and nothing more. It used to abort the whole
        -- dismount, and every caller reads that as "still on the treadmill, give up the
        -- pass" -- which is a farm that never lets go and a steal run that never starts.
        local Ok, Result, Reason = pcall(Network.Invoke, "RF/Treadmill/AskDoff")

        if Ok and (Result == true or Reason == "Not using treadmill") then
            OnTreadmill = false
        end

        local Deadline = tick() + (Attempt == 3 and 3 or 1.5)

        while tick() < Deadline do
            if OffTreadmill() then
                OnTreadmill = false

                return true
            end

            task.wait(0.1)
        end
    end

    return false
end

local function UpgradeTreadmill()
    local Data = Save.Get()

    if not Data then return end

    while Active("AutoUpgradeTreadmill") do
        local Level = (Data.TreadmillUpgradeLevel or 0) + 1
        local Config = TreadmillsDir.GetByUpgradeLevel(Level)

        if not Config or (Data.Money or 0) < Config.Price then return end

        local Ok, Result = pcall(Network.Invoke, "RF/Treadmill/AskTierRaise", Config._id)

        if not (Ok and Result == true) then return end

        task.wait(0.3)

        Data = Save.Get()

        if not Data then return end
    end
end

local function BuyPen()
    local Data = Save.Get()

    if not Data then return false end

    local _, Config = BaseUpgradeClient.GetNextConfig(Data)

    if not Config or (Data.Money or 0) < Config.Cost then return false end

    local Ok, Started = pcall(BaseUpgradeClient.RequestCashUpgrade)

    return Ok and Started == true
end

-- The farm and everything that walks share one character, and this is the half that lets
-- go of it.
--
-- Two things were wrong with the way it used to let go.
--
-- It only got off the treadmill when it had finished. Every other way out -- and the one
-- that matters is `Active(Key)` going false, which is exactly what a higher ranked loop
-- claiming the walk order does -- was a bare `return false` with the character still
-- anchored to the belt. The travel engine moves a root part; it cannot move an anchored
-- one. So the steal run that had just preempted the farm walked nowhere at all, for the
-- whole of its sixty or hundred and twenty second timeout, and then tried again. That is
-- the treadmill and the egg run refusing to work together.
--
-- And it treated every claim as a reason to get off. AutoPlaceEgg and AutoFuse claim the
-- walk order once per pass whether or not they have anything to do, so with either of them
-- on the farm was off the belt and back on it every couple of seconds forever. A claim is
-- waited out now: anything that really is taking the character somewhere dismounts us
-- itself first -- every walking loop in this file opens with StopTreadmill -- so a claim
-- that outlives the grace is a real trip and the farm hands the character over, off the
-- belt.
local function FarmSpeed(Key, Target, StopWhen)
    local function Reached()
        return Target ~= nil and Target > 0 and GetSpeedPower() >= Target
    end

    local function Done()
        return Reached() or (StopWhen ~= nil and StopWhen() == true)
    end

    local function Leave(Result)
        StopTreadmill()

        return Result
    end

    if Done() then return Leave(true) end

    local Bottom = GetTreadmillBottom()

    -- no treadmill on this base yet, so nothing was ever mounted and there is nothing to
    -- get off
    if not Bottom then return false end

    local function Mount()
        if OnTreadmill then return true end

        -- twenty-five, not sixty. The treadmill is on our own plot and the trip to it is a
        -- base-side hop; a minute of it is a minute of holding a pass open on a walk that has
        -- already gone wrong.
        if not Walk(Bottom.Position, Key, 25) then return false end

        return StartTreadmill()
    end

    local YieldGrace = 2.5
    local YieldedAt = nil

    while true do
        if not Alive() then
            OnTreadmill = false

            return false
        end

        if Done() then return Leave(true) end

        -- the two halves of Active, minus the preemption test, which is handled below
        if getgenv().ValkyrieSession ~= SessionToken then return Leave(false) end
        if Key ~= ManualKey and getgenv().Settings.Main[Key] ~= true then return Leave(false) end

        if Preempted(Key) then
            YieldedAt = YieldedAt or tick()

            -- still held after the grace: that is a trip, not a no-op pass
            if tick() - YieldedAt > YieldGrace then return Leave(false) end

            task.wait(0.1)
        else
            YieldedAt = nil

            if not Mount() then return Leave(false) end

            task.wait(0.5)
        end
    end
end

---- ============ Egg selection ============ ----

-- The game's own state table, not a copy of the two values this file used to know about.
-- It has five: Slot, Carried, Dropped, GuardCarried and Claimed. Only knowing Slot and
-- Carried is what made a stolen egg look like a finished job -- see ReturnToSafe below.
local States = require(Library2.Types.AreaEggs).States

-- ============ Announced rare spawns ============
--
-- Once per reset period the server picks out a handful of the eggs it has just rolled and
-- shouts about them: it fires `Eggs: AreaEggRareSpawnsRevealed` carrying
-- { PeriodIndex, DayStartsAt, RareSpawns }, and every entry in RareSpawns is
-- { EggUid, Message, RarityId, SoundId } -- Message being the line that lands in the chat
-- window. Those are the eggs worth walking across the map for, and the payload names them by
-- uid, so nothing has to be guessed from the chat text.
--
-- This is also the answer to the picker never going for them. "Rarest" scored an egg by its
-- drop chance inside its own area, which is a number that only means anything within one
-- area: a 1% roll in Forest is a Common, and it beat every Divine in Cherry Blossom. The
-- game's own AssetItems.RarityRankForCategory reads the asset's RarityNumber -- Common 1 up to the new
-- Divine 10 -- and that is what ranks them now.
--
-- Nothing here polls. EggCmds re-fires the signal for every reveal, and the presentations
-- endpoint is asked once at load so a script started mid-period still knows what was called.
-- Behind one local, like Travel and Night, because the main chunk is at Luau's ceiling of
-- 200 locals per function.
local Rare = { }

do
    local Priority = { FromAssetCategory = require(Library2.Util.AssetItems).RarityRankForCategory }

    local Uids = { }
    local Period = nil

    local function Apply(Payload)
        if type(Payload) ~= "table" then return end

        -- a new period is a fresh roll: last period's uids are gone from the map
        if Payload.PeriodIndex ~= Period then
            Period = Payload.PeriodIndex

            table.clear(Uids)
        end

        for _, Entry in ipairs(Payload.RareSpawns or { }) do
            if type(Entry) == "table" and type(Entry.EggUid) == "string" then
                Uids[Entry.EggUid] = Entry.RarityId or true
            end
        end
    end

    -- was this exact egg one of the ones the server called out
    function Rare.Announced(Uid)
        return Uid ~= nil and Uids[Uid] ~= nil
    end

    -- the asset's own rarity, 1 for Common through 10 for Divine, and 0 for anything the
    -- directory has never heard of
    function Rare.Number(Category)
        if type(Category) ~= "string" then return 0 end

        local Ok, Number = pcall(Priority.FromAssetCategory, Category)

        return (Ok and type(Number) == "number") and Number or 0
    end

    TrackConnection(EggCmds.AreaEggRareSpawnsRevealed:Connect(Apply))

    task.spawn(function()
        local Ok, Sent, Payload = pcall(EggCmds.RequestAreaEggRareSpawnPresentations)

        if Ok and Sent and Payload then
            Apply(Payload)
        end
    end)
end

-- Both assigned down in the Combat block and declared here, because the egg recovery and the
-- interception above it are written first and both need them: SwingAt to swing, Harass to run
-- somebody down in real time.
local SwingAt, Harass

local function RecordMutations(Record)
    local List = { }

    if type(Record.Mutations) == "table" then
        for _, Name in ipairs(Record.Mutations) do
            List[Name] = true
        end
    end

    if Record.BaseMutation then
        List[Record.BaseMutation] = true
    end

    return List
end

local function ToSet(List)
    local Set = { }
    local Count = 0

    for _, Value in ipairs(List or { }) do
        Set[Value] = true
        Count = Count + 1
    end

    return Set, Count
end

local function RecordPosition(Record)
    -- A dropped egg lies wherever it landed, not in the nest it came out of. The game renders
    -- a first-area egg from the record's own BottomCFrame and everything else from a
    -- server-owned Workspace model named after the uid (AreaEggs.renderDropped), so the model
    -- is the truth whenever it is there and BottomCFrame covers the rest.
    local Model = workspace:FindFirstChild(Record.Uid)

    if Model and Model:IsA("Model") then
        return Model:GetPivot().Position
    end

    if Record.BottomCFrame then
        return Record.BottomCFrame.Position
    end

    local Info = AreaInfo[Record.AreaId]

    if not Info then return end

    local Ok, Nest = pcall(SlotIdentity.ResolveNest, Info.Model, Record.NestId)

    if not Ok or not Nest then return end

    local Spot = Nest:FindFirstChild("EggSpotBottom", true)

    return Spot and Spot.Position
end

local function RecordChance(Record)
    local Info = AreaInfo[Record.AreaId]

    if Info and Info.Drops[Record.AssetCategory] then
        return Info.Drops[Record.AssetCategory]
    end

    return EggChance[Record.AssetCategory] or 100
end

-- Every area that has been selected is raided, whatever speed its sign asks for. The gate
-- that used to sit here -- and the Only Areas I Can Escape toggle that drove it -- existed
-- because the character left an area at Humanoid.WalkSpeed, which is 179 at 76M of Speed and
-- only 247 at nine billion, against a guard that wakes and walks at a flat 200. Travel runs on
-- the Tween Speed slider now, so leaving Cosmic is the same 200 studs/s as leaving Forest and
-- the sign is not a speed limit -- 200 is the anti-cheat's ceiling and it is the same
-- everywhere on the map.
local function PickTarget()
    local Root = GetRootPart()

    if not Root then return end

    local Main = getgenv().Settings.Main

    local Rarities, RarityCount = ToSet(Main.StealRarities)

    local WantedAreas = { }

    for _, Label in ipairs(Main.StealAreas or { }) do
        local Info = AreaInfo[AreaByLabel[Label] or Label]

        if Info then
            WantedAreas[Info.Id] = true
        end
    end

    -- the areas that were not picked. An egg the server shouted about, or one lying on the
    -- floor, is worth crossing into one of these for; a nest egg is not. This used to be
    -- gated on the area's speed sign as well, for the same escape reason the selection gate
    -- was, and comes off with it.
    local ChaseAreas = { }

    for _, Info in ipairs(AreaList) do
        if not WantedAreas[Info.Id] then
            ChaseAreas[Info.Id] = true
        end
    end

    if not (next(WantedAreas) or next(ChaseAreas)) then return end

    local Best, BestScore, BestPosition, BestTier

    for _, Record in ipairs(EggCmds.GetAreaEggSnapshot().Records) do
        local Announced = AnnouncedCategory[Record.AssetCategory or ""] == true
        local Mutated = next(RecordMutations(Record)) ~= nil

        -- this exact egg was named in the reveal the game put in chat
        local Called = Rare.Announced(Record.Uid)

        -- An egg on the floor. Somebody was carrying it and got slapped, or a guard hit them,
        -- or they logged out mid-run. It is already out of its nest and nobody owns it, so it
        -- is the cheapest egg on the map -- and when it is the one we just lost, this is what
        -- makes the loop go back for it instead of walking past it to raid a fresh nest.
        local Dropped = Record.State == States.Dropped

        -- What the Hungry Monster eats, and five of them is a Monster Chest. While Steal
        -- Infested Eggs First is on these are chased the way an announced egg is: out of an
        -- area we did not pick, and past a rarity filter that was written for something else.
        -- The event only spawns them from Snow out, so leaving them to the area list would mean
        -- seeing none of them on a Forest run.
        local Infested = Record.HasParasite == true and Main.ParasiteSteal == true

        local InArea = WantedAreas[Record.AreaId]
            or ((Announced or Dropped or Called or Infested) and ChaseAreas[Record.AreaId])

        -- an egg the server shouted about is the one the rarity filter was there to find, so
        -- it goes through the filter rather than into it. Everything else is filtered.
        local RarityOk = Called
            or Infested
            or RarityCount == 0
            or Rarities[RarityOfCategory[Record.AssetCategory or ""] or ""] == true

        if (Record.State == States.Slot or Dropped) and InArea and RarityOk then
            local Position = RecordPosition(Record)

            if Position then
                local Score

                if Main.StealPriority == "Nearest" then
                    Score = (Position - Root.Position).Magnitude
                elseif Main.StealPriority == "Largest" then
                    Score = -(Record.AssetScale or 0)
                else
                    -- rarity first, and the area's own drop chance only to split a tie
                    -- inside one rarity. Lower is better all the way down.
                    Score = RecordChance(Record) - Rare.Number(Record.AssetCategory) * 1000
                end

                -- an egg the game announced outranks free loot, free loot outranks a rare or
                -- infested nest egg, and those outrank the rest
                local Tier = Called and 3
                    or (Dropped and 2 or ((Announced or Mutated or Infested) and 1 or 0))
                local Better

                if not BestScore then
                    Better = true
                elseif Tier ~= BestTier then
                    Better = Tier > BestTier
                else
                    Better = Score < BestScore
                end

                if Better then
                    Best = Record
                    BestScore = Score
                    BestPosition = Position
                    BestTier = Tier
                end
            end
        end
    end

    return Best, BestPosition
end

-- ============ Somebody else's hands ============
--
-- A record in States.Carried whose CarrierUserId is not ours is an egg that was sitting in a
-- nest we had selected until a moment ago. It is not gone: the bat's own shop line is "Fling
-- players and steal their eggs!", and a hit drops what the target is holding onto the floor as
-- DropReasons.PlayerSlap, where it lies as an ordinary Dropped record for whoever is standing
-- over it. So the answer to being beaten to an egg is to run the thief down and swing.
--
-- Filtered exactly like PickTarget, and for the same reasons: an egg out of an area we did not
-- pick is not worth a chase unless the server shouted about it, and the rarity filter applies
-- the same way. Two extra rules that PickTarget does not need:
--
--   they have to still be on the gameplay side. Past the separation line they are home, the
--   egg is banked, and the game's own ToolGameplayGuard throws the swing away anyway
--
--   the score is the distance to them rather than the drop chance of the egg, because the
--   thing being chosen here is a chase and not a walk -- less what the egg is worth, so a
--   Divine two areas over still beats a Common standing next to us
local function PickThief()
    local Root = GetRootPart()

    if not Root then return end

    local Main = getgenv().Settings.Main

    if Main.StealFromPlayers ~= true then return end

    local Rarities, RarityCount = ToSet(Main.StealRarities)

    local Wanted = { }

    for _, Label in ipairs(Main.StealAreas or { }) do
        local Info = AreaInfo[AreaByLabel[Label] or Label]

        if Info then
            Wanted[Info.Id] = true
        end
    end

    local Best, BestScore, BestPlayer

    for _, Record in ipairs(EggCmds.GetAreaEggSnapshot().Records) do
        if Record.State == States.Carried
            and Record.CarrierUserId ~= nil
            and Record.CarrierUserId ~= LocalPlayer.UserId
        then
            local Called = Rare.Announced(Record.Uid)
            local Announced = AnnouncedCategory[Record.AssetCategory or ""] == true
            local Mutated = next(RecordMutations(Record)) ~= nil
            local Special = Called or Announced or Mutated

            -- an egg like that is worth crossing into an area we did not pick for, the same
            -- way a dropped one is in PickTarget
            local InArea = Wanted[Record.AreaId] == true or Special

            local RarityOk = Called
                or RarityCount == 0
                or Rarities[RarityOfCategory[Record.AssetCategory or ""] or ""] == true

            if InArea and RarityOk then
                local Carrier = Players:GetPlayerByUserId(Record.CarrierUserId)
                local Character = Carrier and Carrier ~= LocalPlayer and Carrier.Character
                local Target = Character and Character:FindFirstChild("HumanoidRootPart")

                if Target and InGameplaySide(Target.Position) then
                    local Score = (Target.Position - Root.Position).Magnitude
                        - Rare.Number(Record.AssetCategory) * 250
                        - (Special and 2000 or 0)

                    if BestScore == nil or Score < BestScore then
                        Best, BestScore, BestPlayer = Record, Score, Carrier
                    end
                end
            end
        end
    end

    return Best, BestPlayer
end

-- True while the steal loop owns the character in spirit if not in fact: a run is out past
-- the separation line right now, or there is an egg on the board and the next pass is about
-- to set off for it.
--
-- Auto Place Egg, Auto Fuse and Auto Farm Speed all walk to something on the base side, and
-- all three sit below Auto Steal Egg in the walk order. That stops them preempting a run and
-- does nothing at all about the half second between two steal passes, which is when the walk
-- order is nobody's. In that gap one of them claimed the character and set off for the pen or
-- the treadmill, the steal loop took it back on its next pass and set off for the egg, and
-- the two of them walked it back and forth across the map with neither one ever arriving.
--
-- So the rule the run actually wants: while there is stealing to do, the only thing that
-- walks the character home is a delivery -- ReturnToSafe, with an egg in its hands.
local function StealBusy()
    if getgenv().Settings.Main.AutoStealEgg ~= true then return false end

    local Root = GetRootPart()

    if Root and InGameplaySide(Root.Position) then return true end

    -- somebody walking off with an egg we wanted is a chase this loop is about to start, and
    -- the farm setting off for the treadmill in the gap before it does is the same shuttle
    if (PickThief()) ~= nil then return true end

    return (PickTarget()) ~= nil
end

local function CarryKeyFor(Record)
    if SlotIdentity.IsFirstAreaUid(Record.Uid) then
        return SlotIdentity.BuildSlotKey(Record.AreaId, Record.NestId)
    end

    return nil
end

local function IsCarrying()
    for _, Record in ipairs(EggCmds.GetAreaEggSnapshot().Records) do
        if Record.State == States.Carried and Record.CarrierUserId == LocalPlayer.UserId then
            return true, Record
        end
    end

    return false
end

local function UnplacedEggCount()
    local Data = Save.Get()
    local Count = 0

    if Data and type(Data.EggInventory) == "table" then
        for _, Egg in pairs(Data.EggInventory) do
            if Egg.Placement == nil then
                Count = Count + 1
            end
        end
    end

    return Count
end

local function TryCarry(Record, Key)
    local SlotKey = CarryKeyFor(Record)
    local Deadline = tick() + math.max(getgenv().Settings.Main.CarryRetry or 3, 1)
    local Position = RecordPosition(Record)

    while tick() < Deadline do
        if not Active(Key) then return false end

        local Ok, Reason = EggCmds.RequestCarryAreaEgg(Record.Uid, SlotKey)

        if Ok then return true end

        if Reason ~= "Get closer to the egg" and Reason ~= "Enter the gameplay area first" then
            return false, Reason
        end

        -- a nudge onto the egg, on the travel engine rather than a raw MoveTo. TweenTo only
        -- answers false when the egg is further off than a short hop, and then the full run
        -- handles it -- including the side crossing when the refusal was "enter the
        -- gameplay area first".
        if Position then
            if not TweenTo(Position, Key) then
                Walk(Position, Key, 10, nil, ArriveRadius)
            end
        end

        task.wait(0.25)
    end

    return false
end

-- The record as it stands right now, whatever state it is in. The old version answered nil
-- for anything Carried, which meant an egg somebody had slapped out of our hands and picked
-- up looked exactly like an egg that no longer existed, and ReturnToSafe reported success.
local function FindEggRecord(Uid)
    if not Uid then return end

    for _, Record in ipairs(EggCmds.GetAreaEggSnapshot().Records) do
        if Record.Uid == Uid then return Record end
    end
end

local SafeStep = StartArea.Position - SeparationLine.CFrame.LookVector * 25

local function ReturnToSafe(Key, Uid)
    local Carrying, Carried = IsCarrying()

    Uid = Uid or (Carrying and Carried.Uid) or nil

    local Recoveries = math.max(getgenv().Settings.Main.DropRecovery or 3, 0)

    local Seen = Carrying and true or false
    local Grace = tick() + 2

    local function Lost()
        if IsCarrying() then
            Seen = true

            return false
        end

        return Seen or tick() > Grace
    end

    while true do
        Walk(StartArea.Position, Key, 120, Lost)

        -- Standing on the drop-off is not always enough for the server to take the egg, so
        -- the character is walked onto the spot again and then a little further past the
        -- separation line. Both legs go through the travel engine, which is what keeps the
        -- last stretch home clear of traps -- this is exactly where they get placed.
        for Attempt = 1, 2 do
            local Spot = Attempt == 1 and StartArea.Position or SafeStep
            local Deadline = tick() + 5

            while IsCarrying() do
                if tick() >= Deadline then break end
                if not (Active(Key) and Alive()) then return false end

                MoveLoop(Spot, Key, math.max(Deadline - tick(), 0.5), function()
                    return not IsCarrying()
                end, 2)

                task.wait(0.2)
            end

            if not IsCarrying() then break end
        end

        if IsCarrying() then return false end
        if not (Active(Key) and Alive()) then return false end
        if Recoveries <= 0 then return true end

        local Record = FindEggRecord(Uid)

        -- gone from the snapshot, already banked by whoever took it, or a guard is walking it
        -- back to its nest. Chasing a guard is a fight that cannot be won, and once the guard
        -- gets it home the record turns back into Slot and the normal picker sees it again.
        if not Record
            or Record.State == States.Claimed
            or Record.State == States.GuardCarried
        then
            return true
        end

        Recoveries = Recoveries - 1

        if Record.State == States.Carried then
            -- Somebody slapped it out of our hands and picked it up. The bat's own shop line
            -- is "Fling players and steal their eggs!", and a hit puts the egg back on the
            -- floor as DropReasons.PlayerSlap -- so the way to get it back is to run them
            -- down and swing. Seen stays true, which makes the next pass's walk home abort at
            -- once and come straight back here to collect what they dropped.
            --
            -- Harass is the same real-time follow Intercept uses, given the same stop
            -- condition: the moment this egg is out of this player's hands the chase is over.
            -- The answer is not checked, because a chase that ends any other way -- they died,
            -- they logged out -- also ends with the egg on the floor, and the record read at
            -- the top of the next pass is what decides.
            local Carrier = Record.CarrierUserId and Players:GetPlayerByUserId(Record.CarrierUserId)

            if not (Carrier and Carrier ~= LocalPlayer) then return true end
            if getgenv().Settings.Main.RecoverStolenEgg ~= true then return true end

            local Held = Carrier.UserId
            local CheckedAt = 0
            local Loose = false

            Harass(Key, Carrier, function()
                local Now = os.clock()

                if Now - CheckedAt < 0.15 then return Loose end

                CheckedAt = Now

                local Live = FindEggRecord(Uid)

                Loose = Live == nil
                    or Live.State ~= States.Carried
                    or Live.CarrierUserId ~= Held

                return Loose
            end, 15)

            -- give the server its moment to publish the drop before the record is re-read
            task.wait(0.4)
        else
            -- Slot or Dropped: it is lying somewhere and can just be walked to
            local Position = RecordPosition(Record)

            if not Position then return false end
            if not Approach(Position, Key, 120) then return false end
            if not TryCarry(Record, Key) then return false end

            Seen = false
            Grace = tick() + 2
        end
    end
end

-- Run the thief down, knock the egg out of their hands, and take it off the floor.
--
-- The chase is Harass, the same real-time follow the Attack Player toggle and the delivery
-- leg both run: the travel engine re-aimed at their live position every frame. That is the
-- whole feature. A thief is running for the separation line at the moment they are worth
-- chasing, and the hop-and-re-read chase this replaced spent every hop aiming at ground they
-- had already left -- at the 247 WalkSpeed measured on a live server, 372 studs of it per hop
-- against a bat that reaches 17.
--
-- Harass is given a stop condition instead of being left to swing until its clock runs out:
-- the moment the egg is out of that player's hands there is nothing left to hit them for, and
-- the drop is on the floor for whoever stands over it -- which is a race.
--
-- One swing is not a guarantee. A hit whose rewound sample was out of range is rejected
-- outright, and a hit that lands while somebody else is also swinging can put the egg in that
-- third player's hands instead of on the floor. Hence three attempts and then the pass gives
-- up -- the next pass re-picks, and by then the egg is either lying on the floor, which
-- PickTarget already ranks above any nest egg, or over the line and gone.
local function Intercept(Key, Record, Carrier)
    if not (Record and Carrier and Carrier ~= LocalPlayer) then return false end
    if not StopTreadmill() then return false end

    -- Whether this exact egg has left this exact player. Read off the snapshot rather than off
    -- the swing, because the drop is the server's to publish and a swing that looked like it
    -- connected may not have.
    --
    -- Throttled, because Harass asks this once per frame while it is closing and the snapshot
    -- is every area egg on the map.
    local Held = Carrier.UserId
    local CheckedAt = 0
    local Loose = false

    local function Gone()
        local Now = os.clock()

        if Now - CheckedAt < 0.15 then return Loose end

        CheckedAt = Now

        local Live = FindEggRecord(Record.Uid)

        Loose = Live == nil
            or Live.State ~= States.Carried
            or Live.CarrierUserId ~= Held

        return Loose
    end

    for _ = 1, 3 do
        if not (Active(Key) and Alive()) then return false end

        Held = Carrier.UserId
        CheckedAt = 0
        Loose = false

        -- fifteen seconds a try, three tries. Longer than that and they are either unreachable
        -- or already home, and the walk order has been held long enough.
        --
        -- The answer is not checked. A chase that ends without Gone having fired is usually a
        -- timeout, but it is also what a target dying or logging out looks like -- and that
        -- puts the egg on the floor, which is the outcome we wanted. The record below is what
        -- decides, not the chase.
        Harass(Key, Carrier, Gone, 15)

        -- the server's moment to publish the drop before the record is re-read
        task.wait(0.4)

        local Now = FindEggRecord(Record.Uid)

        -- gone from the snapshot, or a guard has picked it up and is walking it back to its
        -- nest -- which is a fight that cannot be won, and the record turns back into Slot
        -- once the guard gets there
        if not Now then return false end
        if Now.State == States.Claimed or Now.State == States.GuardCarried then return false end

        if Now.State == States.Dropped or Now.State == States.Slot then
            local Position = RecordPosition(Now)

            if not Position then return false end
            if not Approach(Position, Key, 60) then return false end

            return TryCarry(Now, Key) == true
        end

        -- still in somebody's hands. Ours is the win; a third player's is worth another swing
        -- while they are on this side of the line.
        if Now.CarrierUserId == LocalPlayer.UserId then return true end

        Carrier = Players:GetPlayerByUserId(Now.CarrierUserId)

        if not (Carrier and Carrier ~= LocalPlayer) then return false end
    end

    return false
end

local EggNameOfCategory = { }

local function EggDisplayName(Record)
    local Category = Record.AssetCategory

    if Category and EggNameOfCategory[Category] then return EggNameOfCategory[Category] end

    local Ok, Item = pcall(EggItemUtil.DeserializeSavedEgg, Record)

    if not Ok then return end

    local Named, Name = pcall(EggItemUtil.GetDisplayName, Item)

    if not (Named and type(Name) == "string") then return end

    if Category then
        EggNameOfCategory[Category] = Name
    end

    return Name
end

local function EggNamePicked(Record, Wanted)
    local Category = Record.AssetCategory

    if Category and Wanted[EggCategoryName[Category] or ""] then return true end

    return Wanted[EggDisplayName(Record) or ""] == true
end

---- ============ Auto Sell ============ ----

-- What one brainrot actually pays, in money per second, and it is the game's own number rather
-- than anything worked out here: AssetGenerationUtil.GetRate is the function the billboard over
-- the pen prints from. Checked against three of them on a live plot -- 7406471 against
-- "$7.4M/s", 7893133 against "$7.8M/s", 21465262 against "$21M/s".
--
-- Rebirth is an argument because it belongs inside the number: computeRate multiplies by
-- RebirthToMultiplier, so the same pet pays more after one, and a threshold judged against a
-- rate read without it would sell things it should have kept.
local function AssetRate(Item, Rebirth)
    if type(Item) ~= "table" then return end

    local Ok, Rate = pcall(AssetGeneration.GetRate, Item, Rebirth or 0)

    return (Ok and type(Rate) == "number") and Rate or nil
end

local function SellableUids()
    local Main = getgenv().Settings.Main
    local Rarities, RarityCount = ToSet(Main.SellRarities)
    local Categories, CategoryCount = ToSet(Main.SellCategories)

    -- "5M" and "1.2B" both read, because this is the same parser the area speed signs go
    -- through. Zero, blank or anything unreadable is off.
    local Below = ParseSpeed(tostring(Main.SellBelowRate or "")) or tonumber(Main.SellBelowRate) or 0

    if RarityCount == 0 and CategoryCount == 0 and Below <= 0 then return end

    local Data = Save.Get()

    if not Data then return end

    local Rebirth = Data.Rebirth or 0

    local Equipped = { }

    for _, Uid in ipairs(Data.EquippedAssets or { }) do
        Equipped[Uid] = true
    end

    local function Named(Category)
        if Category == nil then return false end

        return Categories[Category] == true or Rarities[RarityOfCategory[Category] or ""] == true
    end

    local Uids = { }

    for Uid, Record in pairs(Data.Inventory or { }) do
        if not Equipped[Uid] then
            local Ok, Item = pcall(AssetItemSerialization.Deserialize, Record)

            if Ok and type(Item) == "table"
                and Item.IsFavorite ~= true
                and Item.InFuse ~= true
            then
                -- The two filters are reasons of their own rather than a pair of conditions
                -- that both have to hold. Naming a rarity and setting a floor means "sell the
                -- commons, and separately sell anything that does not pay its way" -- which is
                -- what the floor is for, and it would do nothing at all if it could only ever
                -- narrow a list of rarities that was already chosen.
                local Take = Named(Item.Category)

                if not Take and Below > 0 then
                    local Rate = AssetRate(Item, Rebirth)

                    Take = Rate ~= nil and Rate < Below
                end

                if Take then
                    table.insert(Uids, Uid)
                end
            end
        end
    end

    return Uids
end

local function SellableEggUids()
    local Main = getgenv().Settings.Main
    local Wanted, Count = ToSet(Main.SellEggCategories)

    if Count == 0 then return end

    local Data = Save.Get()

    if not Data then return end

    local Rarities, RarityCount = ToSet(Main.SellRarities)

    local Uids = { }

    for Uid, Record in pairs(Data.EggInventory or { }) do
        if type(Record) == "table" and Record.Placement == nil and EggNamePicked(Record, Wanted) then
            local Rarity = RarityOfCategory[Record.AssetCategory or ""]

            if RarityCount == 0 or Rarities[Rarity or ""] then
                table.insert(Uids, Uid)
            end
        end
    end

    return Uids
end

local function EquipUid(Uid)
    local Character = GetCharacter()
    local Humanoid = GetHumanoid()

    if not (Character and Humanoid) then return false end

    for _, Tool in ipairs(Character:GetChildren()) do
        if Tool:IsA("Tool") and Tool:GetAttribute("UID") == Uid then return true end
    end

    local Backpack = LocalPlayer:FindFirstChildOfClass("Backpack")

    if Backpack then
        for _, Tool in ipairs(Backpack:GetChildren()) do
            if Tool:IsA("Tool") and Tool:GetAttribute("UID") == Uid then
                Humanoid:EquipTool(Tool)

                return true
            end
        end
    end

    local Ok, Made = pcall(EggCmds.RequestEquipTool, Uid)

    return Ok and Made == true
end

local function SellSweep()
    local Uids = SellableUids() or { }

    for _, Uid in ipairs(SellableEggUids() or { }) do
        table.insert(Uids, Uid)
    end

    if #Uids == 0 then return end

    for Index = 1, math.min(#Uids, 10) do
        local Uid = Uids[Index]

        if EquipUid(Uid) then
            task.wait(0.15)

            pcall(Network.Fire, "RE/PetSatchel/SellPet", { Uid })

            task.wait(0.2)
        end
    end
end

---- ============ Fuse Machine ============ ----

local FuseMachinePart = workspace:WaitForChild("__OBJECTS"):WaitForChild("Machines"):WaitForChild("FuseMachine"):WaitForChild("Machine")

local function ApproachMachine(Key)
    local Root = GetRootPart()

    if not Root then return false end
    if Flat(Root.Position - FuseMachinePart.Position) <= 12 then return true end

    -- the machine is on the base side and a steal run is not finished with the character
    if StealBusy() then return false end

    if not StopTreadmill() then return false end

    return Walk(FuseMachinePart.Position, Key, 60)
end

local function FuseSlotUids()
    local Data = Save.Get()
    local Slots = Data and Data.FusionSlots or { }
    local Uids = { }

    for Index = 1, 3 do
        if Slots[Index] then
            table.insert(Uids, Slots[Index])
        end
    end

    return Uids
end

local function ReturnFusedPets()
    for _, Uid in ipairs(FuseSlotUids()) do
        pcall(Network.Invoke, "RF/Fusery/EjectPet", Uid)

        task.wait(0.1)
    end
end

local function FuseGroups()
    local Main = getgenv().Settings.Main
    local Wanted, Count = ToSet(Main.FuseCategories)

    if Count == 0 then return { } end

    local Data = Save.Get()

    if not Data then return { } end

    local Equipped = { }

    for _, Uid in ipairs(Data.EquippedAssets or { }) do
        Equipped[Uid] = true
    end

    local Groups = { }

    for Uid, Record in pairs(Data.Inventory or { }) do
        if Wanted[Record.Category] and not Equipped[Uid] then
            local Ok, Allowed = pcall(FuseKernelUtil.CanSelectPet, Uid, Record, nil, false)

            if Ok and Allowed then
                local Mutated = (type(Record.Mutations) == "table" and #Record.Mutations > 0)
                    or Record.BaseMutation ~= nil

                if not (Mutated and Main.FuseSkipMutated) then
                    local List = Groups[Record.Category] or { }

                    Groups[Record.Category] = List
                    table.insert(List, { Uid = Uid, Scale = Record.Scale or 0 })
                end
            end
        end
    end

    for _, List in pairs(Groups) do
        table.sort(List, function(a, b)
            return a.Scale < b.Scale
        end)
    end

    return Groups
end

local function FuseFill(Category, Needed)
    for Name, List in pairs(FuseGroups()) do
        if Category == nil or Name == Category then
            if #List >= Needed then
                local Picked = { }

                for Index = 1, Needed do
                    table.insert(Picked, List[Index].Uid)
                end

                return Picked
            end
        end
    end
end

local function InsertFused(Uid, Key)
    local Ok, Inserted = pcall(Network.Invoke, "RF/Fusery/LoadPet", Uid)

    if Ok and Inserted == true then return true end

    if not ApproachMachine(Key) then return false end

    local Retried, Done = pcall(Network.Invoke, "RF/Fusery/LoadPet", Uid)

    return Retried and Done == true
end

local function FuseSweep(Key)
    local Data = Save.Get()

    if not Data then return end

    if Data.FusionEggReward == true then
        pcall(Network.Invoke, "RF/Fusery/FinishReveal")

        return
    end

    if Data.FusionLocked == true then return end

    if IsCarrying() then return end

    local EggCount = 0

    for _ in pairs(Data.EggInventory or { }) do
        EggCount = EggCount + 1
    end

    if EggCount >= EggsType.MAX_INVENTORY then return end

    if Data.FusionInfoAcknowledged ~= true then
        pcall(Network.Invoke, "RF/Fusery/ConfirmBriefing")
    end

    local Slots = FuseSlotUids()
    local Needed = 3 - #Slots

    if Needed > 0 then
        local Category

        if #Slots > 0 then
            local Record = Data.Inventory[Slots[1]]

            Category = Record and Record.Category
        end

        local Picked = FuseFill(Category, Needed)

        if not Picked then
            if #Slots > 0 then
                ReturnFusedPets()
            end

            return
        end

        for _, Uid in ipairs(Picked) do
            if not InsertFused(Uid, Key) then return end

            task.wait(0.1)
        end
    end

    Data = Save.Get()

    if not Data then return end

    local Items = { }

    for _, Uid in ipairs(FuseSlotUids()) do
        local Record = Data.Inventory[Uid]
        local Ok, Item = pcall(AssetItemSerialization.Deserialize, Record)

        if Ok and type(Item) == "table" then
            table.insert(Items, Item)
        end
    end

    if #Items < 3 then return end

    local Priced, Price = pcall(FuseKernelUtil.CalculateFusePrice, Items)

    if Priced and (Data.Money or 0) < tonumber(Price or 0) then return end

    local Ok, Started = pcall(Network.Invoke, "RF/Fusery/BeginFuse")

    if not (Ok and Started == true) then return end

    task.wait(0.5)
    pcall(Network.Invoke, "RF/Fusery/FinishReveal")
end

---- ============ Combat ============ ----

local AttackSweep

do
    local GearsDir = require(Directory.Gears)
    local Ragdoll = require(Library2.Modules.Ragdoll)

    -- last time the chase told the user its target had gone to the safe zone. Local to this
    -- block so the 0.25s outer Loop that restarts Harass cannot turn it into a spam.
    local SafeZoneNoticeAt = 0

    local BAT_ACTIVATE = "RE/BatSwing/Trigger"

    local BatReach = 17

    local Sequence = 0

    local function BatData(Tool)
        if not Tool:IsA("Tool") then return end

        local Name = Tool:GetAttribute("GearName")

        if type(Name) ~= "string" then return end

        local Ok, Config = pcall(function()
            return GearsDir.Directory[Name]
        end)

        return (Ok and type(Config) == "table") and Config.BatControllerData or nil
    end

    local function FindBat()
        local Character = GetCharacter()

        for _, Tool in ipairs(Character and Character:GetChildren() or { }) do
            local Data = BatData(Tool)

            if Data then return Tool, Data, true end
        end

        local Backpack = LocalPlayer:FindFirstChildOfClass("Backpack")

        for _, Tool in ipairs(Backpack and Backpack:GetChildren() or { }) do
            local Data = BatData(Tool)

            if Data then return Tool, Data, false end
        end
    end

    local function NearestPlayer(Root, Range)
        local Best, BestDistance

        for _, Other in ipairs(Players:GetPlayers()) do
            if Other ~= LocalPlayer then
                local Character = Other.Character
                local Target = Character and Character:FindFirstChild("HumanoidRootPart")
                local Humanoid = Character and Character:FindFirstChildWhichIsA("Humanoid")

                if Target and Humanoid and Humanoid.Health > 0 and not Ragdoll.IsRagdolled(Character) then
                    local Distance = (Target.Position - Root.Position).Magnitude

                    if Distance <= Range and (BestDistance == nil or Distance < BestDistance) then
                        Best = Other
                        BestDistance = Distance
                    end
                end
            end
        end

        return Best
    end

    -- One swing at one named player, which is what the egg chase needs: AttackSweep picks
    -- whoever is nearest, and whoever is nearest is very often not the person holding our
    -- egg. Everything the game's own controller checks before it sends the request is checked
    -- here too -- equipped, alive, in the gameplay area, target not already ragdolled, target
    -- inside the bat's reach -- because the server checks all of it again and a rejected
    -- swing still costs the 0.6s cooldown.
    function SwingAt(Target)
        local Root = GetRootPart()
        local Humanoid = GetHumanoid()

        if not (Root and Humanoid and Alive() and Target) then return false end
        if not InGameplaySide(Root.Position) then return false end

        local Character = Target.Character
        local TargetRoot = Character and Character:FindFirstChild("HumanoidRootPart")
        local TargetHumanoid = Character and Character:FindFirstChildWhichIsA("Humanoid")

        if not (TargetRoot and TargetHumanoid and TargetHumanoid.Health > 0) then return false end

        -- a ragdolled player is not an eligible target, so the swing would be wasted
        if Ragdoll.IsRagdolled(Character) then return false end

        local Tool, Data, Held = FindBat()

        if not Tool then return false end

        if (TargetRoot.Position - Root.Position).Magnitude > BatReach + (Data.RangeBonus or 0) then
            return false
        end

        if not Held then
            Humanoid:EquipTool(Tool)

            task.wait(0.1)
        end

        Sequence = Sequence + 1

        local Sent = pcall(Network.Fire, BAT_ACTIVATE, Target, string.format(
            "%d:%d:%d",
            LocalPlayer.UserId,
            Sequence,
            math.floor(workspace:GetServerTimeNow() * 1000)
        ))

        return Sent
    end

    function AttackSweep()
        local Root = GetRootPart()

        if not (Root and Alive()) then return end
        if not InGameplaySide(Root.Position) then return end

        local Tool, Data = FindBat()

        if not Tool then return end

        local Reach = BatReach + (Data.RangeBonus or 0)
        local Wanted = getgenv().Settings.Main.AttackRange or BatReach

        SwingAt(NearestPlayer(Root, math.min(Wanted, Reach)))
    end

    -- ============ Attack Player ============
    --
    -- Attack Aura swings at whoever happens to be nearest and never moves a stud. This one
    -- picks one player out of the list and does not let go: it drives the travel engine at
    -- their live position, re-aimed every frame the way MoveLoop keeps its own target, so a
    -- running target is followed rather than walked to where they used to be. It ends up
    -- standing on top of them and swinging on the bat's own cooldown.
    --
    -- Two things it does not do in a straight line.
    --
    -- A target in a different area, or on the far side of the separation line, is reached
    -- through Route.Plan instead. The travel engine walks a straight line and the areas sit in
    -- a row with walls, rocks and huts between them, so aiming across four of them is a run
    -- that climbs scenery for the length of the map. Once we are in the same area the plan is
    -- pointless and the tight follow takes over -- and the plan is abandoned early when they
    -- have moved far enough that it was a plan for somewhere else.
    --
    -- And the wall. A chase does not walk through a closed reset wall, for the same reason a
    -- steal run does not: the far side is not a place the game can put a player while it is up.
    -- Who is the player to run down. The Attack Player toggle passes nothing and the name in
    -- the dropdown is used; Intercept passes the thief it just picked.
    --
    -- Until, when given, is asked once a pass and ends the chase the moment it answers true --
    -- for Intercept that is the egg leaving the thief's hands, which is the whole point of the
    -- swing and is not worth another second of chasing once it has happened. It is also the
    -- return value: true means Until fired, false means the pass ran out of reasons or time.
    function Harass(Key, Who, Until, Seconds)
        local Main = getgenv().Settings.Main
        local Target = Who

        if not Target then
            local Name = Main.AttackTarget

            Target = type(Name) == "string" and Name ~= "" and Players:FindFirstChild(Name)
        end

        if not (Target and Target ~= LocalPlayer) then return false end
        if not Alive() then return false end
        if not StopTreadmill() then return false end

        -- the chase crosses its own plot to reach a target standing near the pad; NoMount
        -- keeps the travel engine escaping the auto-mount there instead of anchoring on it
        Travel.NoMount(true)

        -- 2 studs under the server's accepted 17 (Config.Range 15 + HitTolerance 2), with
        -- room for the target to keep moving before a swing is refused for range
        local Reach = 15

        -- Below this the follow is always a straight line, whatever the area footprints say,
        -- and that is a freeze fix rather than a shortcut.
        --
        -- The route branch calls Walk, and Walk returns instantly whenever its first leg is
        -- already inside the stop radius. Two players standing next to each other on opposite
        -- sides of an area boundary -- or either side of the gate, where the separation line
        -- flips over a few studs -- therefore hit a branch that neither moves nor yields, and
        -- the while loop below spun on it: twenty seconds of a render thread that never gives
        -- the frame back, which is a frozen client and then a timeout off the server.
        --
        -- A hundred and twenty studs is also further than the scenery that made the route
        -- branch necessary. Inside it there is nothing to route around.
        local PlanBeyond = 120

        -- BatController's history compensation (AntiCheatService.GetHistoricalPosition) rewinds
        -- the target, not the attacker: the range check uses our live root. So the only thing
        -- this window has to cover is our own root replicating out to the server, which is
        -- short. A longer settle only delayed swings that would already have landed.
        local Settle = 0.15

        -- The server bat cooldown is 0.7s (BatController.Server _applyHits / _finishMiss both
        -- return 0.7). A swing sent inside it comes back REQUEST_COOLDOWN_ACTIVE, so the slider
        -- can only ever ask for a slower one.
        local Cooldown = math.max(tonumber(Main.AttackDelay) or 0.7, 0.7)

        local Deadline = tick() + (Seconds or 20)
        local Token = nil
        local Done = false

        -- Both of these are clocks rather than sleeps, and that is the whole point of the
        -- follow. Waiting out the cooldown with task.wait(0.6) stops re-aiming the travel
        -- engine for six tenths of a second, and a target at the 247 WalkSpeed measured on a
        -- live server covers a hundred and forty-eight studs in that time -- eight times the
        -- bat's reach. So the loop gives the frame back with a bare task.wait() every pass,
        -- re-aims on every one of them, and simply does not send a swing until the clocks say
        -- one would land.
        local InReachSince = nil
        local OutSince = nil
        local SwungAt = 0

        local function Spot()
            local Character = Target.Character

            return Character and Character:FindFirstChild("HumanoidRootPart")
        end

        while tick() < Deadline do
            if not (Active(Key) and Alive()) then break end

            -- re-asserted every pass: the route branch's Walk legs each clear NoMount when
            -- they hand the engine back, and the tight follow that takes over near the target
            -- is the part that actually crosses our plot
            Travel.NoMount(true)

            -- what the chase was for has happened
            if Until and Until() then
                Done = true

                break
            end

            local Root = GetRootPart()
            local At = Spot()

            -- they died, respawned or left. The pass ends here and the next one picks them
            -- back up the moment their character is back.
            if not (Root and At) then break end

            local Here, There = Root.Position, At.Position

            if Night.WallClosed() and InGameplaySide(There) and not InGameplaySide(Here) then break end

            local Away = Flat(There - Here)

            -- Target on the base side of the separation line. The server refuses every swing
            -- there, for the attacker and the target both, so there is nothing to chase: hand
            -- the engine back, stand still, and end the pass. The 0.25s outer Loop re-picks
            -- the moment they cross back out.
            if not InGameplaySide(There) then
                local Now = os.clock()

                if Now - SafeZoneNoticeAt > 10 then
                    SafeZoneNoticeAt = Now

                    Library:Notification({
                        Title = "Combat",
                        Description = Library:Translate("Target is in the safe zone, waiting at the line"),
                        Duration = 4,
                        Icon = IconValkyrie
                    })
                end

                if Token then
                    Travel.Stop(Token)

                    Token = nil
                end

                break
            -- Far enough for the scenery to matter, and on the other side of something. Near
            -- enough and it is always the tight follow: see PlanBeyond.
            elseif Away > PlanBeyond
                and (InGameplaySide(Here) ~= InGameplaySide(There)
                    or Route.AreaAt(Here) ~= Route.AreaAt(There))
            then
                -- the engine is handed back before Walk takes it, because Walk's own legs take
                -- their own token and ours would be stale from the first frame
                if Token then
                    Travel.Stop(Token)

                    Token = nil
                end

                InReachSince = nil

                local Walked = Walk(There, Key, 20, function()
                    local Now = Spot()

                    return Now == nil or (Now.Position - There).Magnitude > 150
                end, Reach)

                -- Walk can come back without having yielded once -- a closed wall refuses on
                -- the spot, and so does a leg that was already inside its stop radius. Nothing
                -- below this yields either, so without the wait the loop spins the client flat
                -- for the rest of the pass.
                if Walked then
                    task.wait()
                else
                    task.wait(0.25)
                end
            else
                -- Aim just behind the target rather than at it. The engine writes the root
                -- CFrame straight at whatever it is aimed at every frame, so aiming at the
                -- target's own position drops our root inside theirs -- the "standing on
                -- their head / possessing them" look. Behind is the target's own CFrame
                -- pushed +Z (opposite its LookVector); 3 studs is well inside Reach (15) and
                -- the server's 17, so every swing still lands.
                local StandOff = 3
                local Aim = (At.CFrame * CFrame.new(0, 0, StandOff)).Position

                Token = Token or Travel.Start(Aim, { })

                -- a refusal means a higher ranked loop has taken the engine
                if not Travel.Aim(Aim, Token) then
                    Token = nil

                    break
                end

                local Now = os.clock()

                if Away <= Reach then
                    OutSince = nil
                    InReachSince = InReachSince or Now

                    if Now - InReachSince >= Settle and Now - SwungAt >= Cooldown then
                        SwungAt = Now

                        SwingAt(Target)
                    end
                else
                    -- one stray frame past the reach must not reset the settle window -- a
                    -- target skirting the edge would then never let a swing through. Only a
                    -- quarter second continuously outside counts as really out of reach.
                    OutSince = OutSince or Now

                    if Now - OutSince > 0.25 then
                        InReachSince = nil
                    end
                end

                task.wait()
            end
        end

        Travel.NoMount(false)

        if Token then
            Travel.Stop(Token)
        end

        return Done
    end
end

---- ============ Monster Parasite ============ ----

-- The Hungry Monster, which is what the game runs in place of the Sakura event. Directory.
-- MonsterParasite is the whole of it, and the shape is different from the bloom's: EndsAt is one
-- fixed timestamp rather than a window that comes back every half hour, so there is no next one
-- to wait for. The server's own snapshot is what says whether it is still running.
--
-- What the event is: some area eggs spawn infested and carry HasParasite on their record, at the
-- percentages in SpawnChanceByArea -- Snow 29, Volcano 26, Abyss Ocean 18, Prehistoric 15,
-- Cosmic 13, Cherry Blossom 11, Titan Temple 9, and nothing at all in Forest, Lake, Desert or
-- Jungle. The game says the same thing in its own tutorial: "Infested Eggs spawn from the Snow
-- onwards".
-- Steal one, carry it home, hand it to the monster standing on our own plot: a feed is
-- ChargePerFeed (20) of MaxCharge (100), so five infested eggs is one Monster Chest.
--
-- The chest pays one of five things by weight: 1.25x egg growth 43.5, 1.25x speed 30, 2x
-- treadmill 20, the Flyswatter 5, and a guaranteed-parasite egg at 1.5.
--
-- Two things measured here rather than read off the game's own dialogue:
--
--   "I will eat the parasite without harming what is inside" is not what happens. Fed one egg
--   out of a nineteen egg inventory and came back with eighteen -- the egg is gone. That is why
--   Feed Mutated Eggs defaults to off: a Rainbow egg that happens to be infested is worth more
--   than a fifth of a chest.
--
--   The prompt on the monster is not the only way in. AskFeed takes no arguments at all -- it
--   reads whichever egg tool is equipped -- and the server does the distance check itself,
--   answering { Success = false, Message = "Get closer to your monster." } from anywhere else.
--   So a feed is three steps: wear the tool, stand inside FeedDistance (14), invoke.
--
-- Behind one local, like Travel and Route, because the main chunk is at Luau's ceiling of 200
-- locals per function.
local Parasite = { }

do
    local Config = require(Directory.MonsterParasite)
    local Eligibility = require(Library2.Util.MonsterParasiteEligibility)

    local Endpoints = {
        SNAPSHOT = "RF/MonsterParasite/AskSnapshot",
        FEED = "RF/MonsterParasite/AskFeed",
        CHEST_TAKE = "RF/MonsterParasite/AskChestTake",
        CHEST_CLAIM = "RF/MonsterParasite/AskChestClaim",
        CHEST_DONE = "RF/MonsterParasite/AskChestRevealComplete",
    }

    -- The server answers a refused action with a message rather than an error, and these two are
    -- the only ones worth reading: the first is a walk, the second is a wait.
    local TooFar = "Get closer to your monster."
    local Busy = "Another Monster Parasite action is still finishing."

    local Cached = { Active = false, EndsAt = 0, At = 0 }

    -- Ours. The folder holds one model per player in the server, each named Monster_<UserId> and
    -- carrying OwnerUserId, Charge and PendingChests as attributes -- which is why the state
    -- below is two attribute reads and not a round trip.
    function Parasite.Monster()
        local Folder = workspace:FindFirstChild(Config.WorldFolderName)

        if not Folder then return end

        for _, Model in ipairs(Folder:GetChildren()) do
            if Model:GetAttribute("OwnerUserId") == LocalPlayer.UserId then return Model end
        end
    end

    local function Snapshot()
        local Ok, Result = pcall(Network.Invoke, Endpoints.SNAPSHOT)

        if not (Ok and type(Result) == "table" and type(Result.Event) == "table") then return end

        Cached.Active = Result.Event.Active == true
        Cached.EndsAt = tonumber(Result.Event.EndsAt) or 0
        Cached.At = os.clock()

        return Result
    end

    -- Whether the event is running, asked again every thirty seconds. A stale yes costs one
    -- refused remote; a stale no would park the whole section for half a minute.
    function Parasite.Live()
        if os.clock() - Cached.At > 30 then
            Snapshot()
        end

        return Cached.Active and workspace:GetServerTimeNow() < Cached.EndsAt
    end

    -- What the event is gated behind: MonsterParasiteEligibility turns our SpeedPower into a
    -- walk speed and holds it against the Jungle guard's. Under it the monster refuses to eat,
    -- which is worth saying on the label rather than discovering one refused feed at a time.
    function Parasite.Eligible()
        local Ok, Allowed = pcall(Eligibility.IsEligible, GetSpeedPower())

        return Ok and Allowed == true
    end

    function Parasite.State()
        local Monster = Parasite.Monster()

        if Monster then
            return tonumber(Monster:GetAttribute("Charge")) or 0,
                tonumber(Monster:GetAttribute("PendingChests")) or 0
        end

        local Result = Snapshot()

        if Result and type(Result.State) == "table" then
            return tonumber(Result.State.Charge) or 0, tonumber(Result.State.PendingChests) or 0
        end

        return 0, 0
    end

    -- Every infested egg in the bag that is not planted. A planted one cannot be equipped, and a
    -- mutated one is left alone unless the toggle says otherwise -- see the header for why.
    function Parasite.Eggs()
        local Data = Save.Get()
        local List = { }

        if not Data then return List end

        local Mutated = getgenv().Settings.Main.ParasiteFeedMutated == true

        for Uid, Record in pairs(Data.EggInventory or { }) do
            if type(Record) == "table" and Record.Placement == nil and Record.HasParasite == true then
                if Mutated or next(Record.Mutations or { }) == nil then
                    table.insert(List, Uid)
                end
            end
        end

        return List
    end

    -- inside FeedDistance with room for the character to drift a couple of studs while it stands
    local function Reach()
        return math.max(Config.FeedDistance - 4, 4)
    end

    -- The trip home, made once for the whole bag rather than once per egg. Five feeds is five
    -- seconds of standing next to a monster on our own plot, and walking back to it between each
    -- of them is the shuttle the pen and the fuse machine already learned not to do.
    function Parasite.Feed(Key)
        if not (Parasite.Live() and Parasite.Eligible()) then return end

        -- an egg in our hands is a delivery in progress; the monster is not going anywhere
        if IsCarrying() then return end

        local Charge = Parasite.State()

        if Charge >= Config.MaxCharge then return end

        local Eggs = Parasite.Eggs()

        if #Eggs == 0 then return end

        local Monster = Parasite.Monster()

        if not Monster then return end
        if StealBusy() then return end
        if not StopTreadmill() then return end

        local Point = Monster:GetPivot().Position

        if not Walk(Point, Key, 60, nil, Reach()) then return end

        for _, Uid in ipairs(Eggs) do
            if not (Active(Key) and Alive()) then return end

            Charge = Parasite.State()

            -- full: the rest of the bag keeps until the chest has been claimed, and a feed sent
            -- now is refused anyway
            if Charge >= Config.MaxCharge then return end

            local Called, Worn = pcall(EggCmds.RequestEquipTool, Uid)

            if Called and Worn then
                local Ok, Result = pcall(Network.Invoke, Endpoints.FEED)

                if Ok and type(Result) == "table" and not Result.Success then
                    -- shoved off the plot between two feeds, by a slap or a respawn: walk back
                    -- rather than burn the rest of the bag on refusals
                    if Result.Message == TooFar then
                        if not Walk(Point, Key, 30, nil, Reach()) then return end
                    elseif Result.Message ~= Busy then
                        warn("[ValkyrieHub] the monster refused the egg: " .. tostring(Result.Message))

                        return
                    end
                end
            end

            task.wait(Config.RequestCooldown + 0.15)
        end
    end

    -- A full charge is a chest waiting on the plot rather than a reward in hand. PendingChests is
    -- what the server counts them with: AskChestTake picks the model up, AskChestClaim opens it
    -- under a ticket the client generates, and AskChestRevealComplete is the acknowledgement that
    -- lets the next one through. The claim is tried three times because the fifth feed is still
    -- playing its animation when the chest appears, and the server says so rather than queueing.
    function Parasite.Chest(Key)
        local _, Pending = Parasite.State()

        if Pending <= 0 then return false end
        if IsCarrying() then return false end

        local Monster = Parasite.Monster()

        if not Monster then return false end
        if StealBusy() then return false end
        if not StopTreadmill() then return false end
        if not Walk(Monster:GetPivot().Position, Key, 60, nil, Reach()) then return false end

        pcall(Network.Invoke, Endpoints.CHEST_TAKE)

        local Ticket = HttpService:GenerateGUID(false)

        for _ = 1, 3 do
            if not Active(Key) then return false end

            local Ok, Result = pcall(Network.Invoke, Endpoints.CHEST_CLAIM, Ticket)

            if Ok and type(Result) == "table" then
                if Result.Success then
                    -- an unacknowledged chest holds the next claim, so this is not optional
                    pcall(Network.Invoke, Endpoints.CHEST_DONE, Ticket)

                    return true
                end

                if Result.Message ~= Busy then
                    warn("[ValkyrieHub] the monster chest refused: " .. tostring(Result.Message))

                    return false
                end
            end

            task.wait(0.4)
        end

        return false
    end

    -- Takes the translator rather than reaching for it: the UI library is a local declared
    -- further down the file, so a reference to it from up here would compile as a global read
    -- and come back nil.
    function Parasite.Status(Translate)
        local function Word(Text)
            return Translate and Translate(Text) or Text
        end

        if not Parasite.Live() then return Word("The monster event has ended") end
        if not Parasite.Eligible() then return Word("Too slow for the monster - farm speed first") end

        local Charge, Pending = Parasite.State()
        local Left = math.max(Cached.EndsAt - workspace:GetServerTimeNow(), 0)
        local Days = math.floor(Left / 86400)
        local Clock = Days > 0 and string.format("%dd %dh", Days, math.floor(Left % 86400 / 3600))
            or string.format("%d:%02d", math.floor(Left / 3600), math.floor(Left % 3600 / 60))

        return string.format(
            "%s %s | %s %d%% | %s %d | %s %d",
            Word("Event ends in"),
            Clock,
            Word("Charge"),
            Charge,
            Word("Chests"),
            Pending,
            Word("Infested eggs"),
            #Parasite.Eggs()
        )
    end
end

---- ============ Plot ============ ----

local function PlotParts()
    local Data = PlotCmds.GetPlotData()

    if not Data then return end

    return Data.PetArea, Data.CenterPoint
end

local function PlacedEggPositions(Center)
    local Positions = { }

    for _, Record in pairs(EggCmds.GetOwnerRuntimeRecords(LocalPlayer.UserId)) do
        if Record.Placement and Record.Placement.LocalCFrame then
            table.insert(Positions, (Center.CFrame * Record.Placement.LocalCFrame).Position)
        end
    end

    return Positions
end

local function FreeEggSpots(Area, Center)
    local EggSpacing = 3.4
    local EggGridStep = 3.6
    local EggGridInset = 2

    local Taken = PlacedEggPositions(Center)
    local Top = Area.Position.Y + Area.Size.Y / 2
    local HalfX = Area.Size.X / 2 - EggGridInset
    local HalfZ = Area.Size.Z / 2 - EggGridInset
    local Spots = { }

    local X = -HalfX

    while X <= HalfX do
        local Z = -HalfZ

        while Z <= HalfZ do
            local Point = (Area.CFrame * CFrame.new(X, 0, Z)).Position

            Point = Vector3.new(Point.X, Top, Point.Z)

            local Clear = true

            for _, Used in ipairs(Taken) do
                if Flat(Point - Used) < EggSpacing then
                    Clear = false
                    break
                end
            end

            if Clear then
                table.insert(Spots, Point)
            end

            Z = Z + EggGridStep
        end

        X = X + EggGridStep
    end

    return Spots
end

local function EggFilter()
    local Main = getgenv().Settings.Main
    local Names, NameCount = ToSet(Main.PlaceEggs)
    local Rarities, RarityCount = ToSet(Main.PlaceRarities)

    return function(Record)
        if NameCount > 0 and not EggNamePicked(Record, Names) then return false end

        if RarityCount > 0 and not Rarities[RarityOfCategory[Record.AssetCategory or ""] or ""] then return false end

        return true
    end
end

local function ApproachPen(Key)
    local Area = PlotParts()

    if not Area then return false end

    local Root = GetRootPart()

    if Root and Flat(Root.Position - Area.Position) <= 20 then return true end

    -- same as the fuse machine: the pen is at the base, and walking to it in the gap between
    -- two steal passes is what turned a run into a shuttle
    if StealBusy() then return false end

    if not StopTreadmill() then return false end

    return Walk(Area.Position, Key, 60)
end

local function PlaceSweep(Key)
    if IsCarrying() then return end

    local Data = Save.Get()

    if not Data then return end

    local Passes = EggFilter()
    local Waiting = { }

    for Uid, Record in pairs(Data.EggInventory or { }) do
        if type(Record) == "table" and Record.Placement == nil and Passes(Record) then
            table.insert(Waiting, Uid)
        end
    end

    if #Waiting == 0 then return end

    local Area, Center = PlotParts()

    if not (Area and Center) then return end

    local Spots = FreeEggSpots(Area, Center)

    if #Spots == 0 then return end
    if not ApproachPen(Key) then return end

    local Index = 1

    for _, Uid in ipairs(Waiting) do
        if not Active(Key) then return end
        if Index > #Spots then return end

        local Held = EggCmds.RequestEquipTool(Uid)

        if Held then
            task.wait(0.2)

            while Index <= #Spots do
                local Ok, Reason = EggCmds.RequestPlaceEgg(Uid, Center.CFrame:ToObjectSpace(CFrame.new(Spots[Index])))

                Index = Index + 1

                if Ok then break end

                if Reason == nil or not string.find(Reason, "too close") then return end
            end

            task.wait(0.15)
        end
    end
end

local function OpenSweep(Key)
    if IsCarrying() then return end

    local Passes = EggFilter()
    local Ready = { }

    for Uid, Record in pairs(EggCmds.GetOwnerRuntimeRecords(LocalPlayer.UserId)) do
        if Record.Placement ~= nil and Passes(Record) and EggCmds.IsLocalEggReady(Uid) then
            table.insert(Ready, Uid)
        end
    end

    for _, Uid in ipairs(Ready) do
        if not Active(Key) then return end

        local Started = EggCmds.RequestHatchEgg(Uid)

        if Started then
            task.wait(0.4)
            pcall(EggCmds.RequestCompleteHatchEgg, Uid)
            task.wait(0.2)
        end
    end
end

local function PlotChoresPending()
    local Main = getgenv().Settings.Main

    if not Main.AutoPlaceEgg then return false end

    local Passes = EggFilter()
    local Data = Save.Get()

    for _, Record in pairs(Data and Data.EggInventory or { }) do
        if type(Record) == "table" and Record.Placement == nil and Passes(Record) then
            return true
        end
    end

    return false
end

---- ============ Visual ============ ----

-- Everything the ESP draws it draws itself rather than borrowing the game's own renders, and
-- that is not a preference. An area egg has no model in Workspace at all -- the record carries
-- BoundsCFrame and BoundsSize and the mesh is built on demand -- so there is nothing for a
-- Highlight to adorn. Every entry therefore owns an invisible marker part sized to whatever it
-- is marking; the Highlight goes on the entity's real model when there is one and on the marker
-- when there is not, and the label hangs off the marker either way.
--
-- Nothing is created or destroyed on a refresh. There is a pool, entries are handed out and
-- handed back, and the pool never grows past the Max Shown slider -- which is also what keeps
-- the ESP inside the engine's own ceiling of thirty-one Highlights drawn at once. Past that the
-- extra ones are silently not drawn, so a hundred eggs across ten areas is not more ESP, it is
-- the same ESP with the count wasted.
--
-- Behind one local, like Travel and Route, because the main chunk is at Luau's ceiling of 200
-- locals per function.
local Visual = { }

do
    local CollectionService = game:GetService("CollectionService")

    -- Roblox stops drawing Highlights past this many, so the pool is capped here whatever the
    -- slider says
    local HighlightCap = 30

    local Holder = nil
    local Pool = { }
    local Used = 0

    local function Colour(Key, Fallback)
        local Hex = getgenv().Settings.Main[Key]

        if type(Hex) == "string" and Hex ~= "" then
            local Ok, Value = pcall(Color3.fromHex, Hex)

            if Ok then return Value end
        end

        return Fallback
    end

    local function GetHolder()
        if Holder and Holder.Parent then return Holder end

        Holder = Instance.new("Folder")
        Holder.Name = tostring(math.random(1e11, 1e12 - 1))
        Holder.Parent = workspace

        return Holder
    end

    local function NewEntry()
        local Part = Instance.new("Part")
        Part.Name = "\0"
        Part.Anchored = true
        Part.CanCollide = false
        Part.CanQuery = false
        Part.CanTouch = false
        Part.CastShadow = false
        Part.Transparency = 1
        Part.Size = Vector3.new(1, 1, 1)
        Part.Parent = GetHolder()

        local Glow = Instance.new("Highlight")
        Glow.FillTransparency = 0.65
        Glow.OutlineTransparency = 0
        Glow.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        Glow.Parent = Part

        local Board = Instance.new("BillboardGui")
        Board.Size = UDim2.new(0, 210, 0, 52)
        Board.AlwaysOnTop = true
        Board.LightInfluence = 0
        Board.Parent = Part

        local Text = Instance.new("TextLabel")
        Text.BackgroundTransparency = 1
        Text.Size = UDim2.fromScale(1, 1)
        Text.Font = Enum.Font.GothamBold
        Text.TextSize = 12
        Text.TextStrokeTransparency = 0.25
        Text.TextStrokeColor3 = Color3.new(0, 0, 0)
        Text.Parent = Board

        return { Part = Part, Glow = Glow, Board = Board, Text = Text }
    end

    local function Release(From)
        for Index = From, #Pool do
            local Entry = Pool[Index]

            Entry.Glow.Enabled = false
            Entry.Glow.Adornee = nil
            Entry.Board.Enabled = false
        end

        Used = math.max(From - 1, 0)
    end

    function Visual.Clear()
        Release(1)

        if Holder then
            pcall(function()
                Holder:Destroy()
            end)

            Holder = nil
        end

        table.clear(Pool)
        Used = 0
    end

    -- one drawn thing. Model may be nil, in which case the marker itself is what glows.
    local function Draw(Position, Size, Model, Tint, Label)
        Used = Used + 1

        local Entry = Pool[Used]

        if not Entry then
            Entry = NewEntry()
            Pool[Used] = Entry
        end

        if not Entry.Part.Parent then
            Entry.Part.Parent = GetHolder()
        end

        Entry.Part.Size = Size
        Entry.Part.CFrame = CFrame.new(Position)

        Entry.Glow.Adornee = Model or Entry.Part
        Entry.Glow.FillColor = Tint
        Entry.Glow.OutlineColor = Tint
        Entry.Glow.Enabled = true

        Entry.Board.StudsOffsetWorldSpace = Vector3.new(0, math.max(Size.Y, 1) * 0.5 + 1.6, 0)
        Entry.Board.Enabled = true

        Entry.Text.Text = Label
        Entry.Text.TextColor3 = Tint
    end

    ---- ---- what there is to draw ---- ----

    local function EggLabel(Record, Distance)
        local Info = AreaInfo[Record.AreaId]
        local Marks = { }

        if Record.State == States.Dropped then
            table.insert(Marks, "DROPPED")
        end

        if Rare.Announced(Record.Uid) then
            table.insert(Marks, "CALLED")
        end

        for Mutation in pairs(RecordMutations(Record)) do
            table.insert(Marks, string.upper(tostring(Mutation)))
        end

        return string.format(
            "%s  [%s]\n%s%s  %.0fm",
            EggDisplayName(Record) or tostring(Record.AssetCategory or "Egg"),
            RarityOfCategory[Record.AssetCategory or ""] or "?",
            Info and Info.Display or tostring(Record.AreaId),
            #Marks > 0 and ("  " .. table.concat(Marks, " ")) or "",
            Distance
        )
    end

    local function AreaEggs(Origin, Wanted, Tint, Add)
        for _, Record in ipairs(EggCmds.GetAreaEggSnapshot().Records) do
            if Record.State == States.Slot or Record.State == States.Dropped then
                local Position = RecordPosition(Record)

                if Position then
                    local Distance = (Position - Origin).Magnitude

                    if Distance <= Wanted then
                        local Middle = Record.BoundsCFrame and Record.BoundsCFrame.Position or Position

                        Add(Distance, Middle, Record.BoundsSize or Vector3.new(3, 3, 3), nil, Tint,
                            EggLabel(Record, Distance))
                    end
                end
            end
        end
    end

    local function PenEggs(Origin, Wanted, Tint, Add)
        local Renders = { }

        for _, Folder in ipairs(workspace:GetChildren()) do
            if Folder.Name == "PlacedEggRenders" then
                for _, Model in ipairs(Folder:GetChildren()) do
                    Renders[Model.Name] = Model
                end
            end
        end

        for Uid, Record in pairs(EggCmds.GetOwnerRuntimeRecords(LocalPlayer.UserId)) do
            if Record.Placement ~= nil then
                local Model = Renders[tostring(LocalPlayer.UserId) .. "_" .. tostring(Uid)]
                local Root = Model and (Model.PrimaryPart or Model:FindFirstChildWhichIsA("BasePart"))

                if Root then
                    local Distance = (Root.Position - Origin).Magnitude

                    if Distance <= Wanted then
                        Add(Distance, Root.Position, Vector3.new(3, 3, 3), Model, Tint, string.format(
                            "%s  [%s]\n%s  %.0fm",
                            EggDisplayName(Record) or tostring(Record.AssetCategory or "Egg"),
                            RarityOfCategory[Record.AssetCategory or ""] or "?",
                            EggCmds.IsLocalEggReady(Uid) and "READY" or "hatching",
                            Distance
                        ))
                    end
                end
            end
        end
    end

    local function PenPets(Origin, Wanted, Tint, Add)
        local Data = Save.Get()
        local Inventory = (Data and Data.Inventory) or { }

        for _, Folder in ipairs(workspace:GetChildren()) do
            if Folder.Name == "ClientRenderedAssets" then
                for _, Model in ipairs(Folder:GetChildren()) do
                    if Model:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
                        local Root = Model.PrimaryPart or Model:FindFirstChild("HumanoidRootPart")

                        if Root then
                            local Distance = (Root.Position - Origin).Magnitude

                            if Distance <= Wanted then
                                local Record = Inventory[Model:GetAttribute("UID") or ""]
                                local Category = type(Record) == "table" and Record.Category or nil
                                local Rate

                                if type(Record) == "table" then
                                    local Fine, Item = pcall(AssetItemSerialization.Deserialize, Record)

                                    if Fine then
                                        Rate = AssetRate(Item, Data and Data.Rebirth or 0)
                                    end
                                end

                                Add(Distance, Root.Position, Vector3.new(4, 4, 4), Model, Tint, string.format(
                                    "%s  [%s]\n%s  %.0fm",
                                    tostring(Category or "Pet"),
                                    RarityOfCategory[Category or ""] or "?",
                                    Rate and ("$" .. FormatSpeed(Rate) .. "/s") or "-",
                                    Distance
                                ))
                            end
                        end
                    end
                end
            end
        end
    end

    local function Traps(Origin, Wanted, Tint, Add)
        local Seen = { }

        local function Take(Part)
            if Seen[Part] or not Part:IsDescendantOf(workspace) then return end

            Seen[Part] = true

            local Distance = (Part.Position - Origin).Magnitude

            if Distance > Wanted then return end

            local Box = Part:FindFirstChild("Hitbox")

            Add(Distance, Part.Position, (Box and Box:IsA("BasePart")) and Box.Size or Vector3.new(3, 2, 3),
                Part, Tint, string.format(
                    "TRAP  freezes 7s\n%s  %.0fm",
                    tostring(Part:GetAttribute("Owner") or "?"),
                    Distance
                ))
        end

        for _, Part in ipairs(CollectionService:GetTagged("PlacedTrap")) do
            if Part:IsA("BasePart") then Take(Part) end
        end

        local Debris = workspace:FindFirstChild("__DEBRIS")

        if Debris then
            for _, Child in ipairs(Debris:GetChildren()) do
                if Child:IsA("BasePart") and Child.Name == "PlayerTrap" then Take(Child) end
            end
        end
    end

    -- Guards.Directory is where the numbers on a monster come from, and it is the same table
    -- the game's own chase code reads: WalkSpeed is what it runs at once awake, HitDistance is
    -- how close it has to be to take the egg out of our hands, and the area's own Rarity is the
    -- tier printed on it. Humanoid.WalkSpeed on the model is the live figure and it is not the
    -- same number -- a guard chasing in Cherry Blossom measured 452 against a table value of
    -- 222 -- so both go on the label, next to the Speed the area asks for.
    local function Monsters(Origin, Wanted, Tint, Add)
        for _, Info in ipairs(AreaList) do
            local Area = GuardAreas:FindFirstChild(Info.Id)

            if Area then
                for _, Guard in ipairs(Area:GetChildren()) do
                    local Humanoid = Guard:IsA("Model") and Guard:FindFirstChildWhichIsA("Humanoid")
                    local Root = Humanoid and (Guard.PrimaryPart or Guard:FindFirstChild("HumanoidRootPart"))

                    if Root then
                        local Distance = (Root.Position - Origin).Magnitude

                        if Distance <= Wanted then
                            local Config = Guards.Directory[Info.Id] or { }
                            local Rarity = Config.Rarity and (Config.Rarity.DisplayName or Config.Rarity._id) or "?"
                            local State = Guard:GetAttribute("GuardState")

                            if type(State) ~= "string" or State == "" then
                                State = Guard:GetAttribute("Sleeping") == true and "Sleeping" or "?"
                            end

                            Add(Distance, Root.Position, Vector3.new(6, 9, 6), Guard, Tint, string.format(
                                "%s Guard  [%s]\nspeed %s (live %.0f)   hit %.1f\nneeds %s   %s   %.0fm",
                                Info.Display,
                                Rarity,
                                tostring(Config.WalkSpeed or "?"),
                                Humanoid.WalkSpeed,
                                tonumber(Config.HitDistance) or 0,
                                FormatSpeed(math.max(Info.Required, Info.GuardRequired)),
                                State,
                                Distance
                            ))
                        end
                    end
                end
            end
        end
    end

    ---- ---- the pass ---- ----

    function Visual.Refresh()
        local Main = getgenv().Settings.Main
        local Root = GetRootPart()

        local Any = Main.EspAreaEggs or Main.EspPenEggs or Main.EspPenPets
            or Main.EspTraps or Main.EspMonsters

        if not (Any and Root) then
            if Used > 0 then Release(1) end

            return
        end

        local Origin = Root.Position
        local Wanted = math.max(tonumber(Main.EspMaxDistance) or 2000, 50)
        local Limit = math.clamp(tonumber(Main.EspLimit) or HighlightCap, 1, HighlightCap)

        -- Collected first and drawn second, because what matters is the nearest Limit things
        -- across every category rather than the first Limit of whichever category happened to
        -- be swept first: the trap two studs away must not lose its slot to a nest egg in
        -- Cosmic.
        local Found = { }

        local function Add(Distance, Position, Size, Model, Tint, Label)
            table.insert(Found, {
                Distance = Distance,
                Position = Position,
                Size = Size,
                Model = Model,
                Tint = Tint,
                Label = Label
            })
        end

        if Main.EspAreaEggs then
            AreaEggs(Origin, Wanted, Colour("EspAreaEggColor", Color3.fromRGB(255, 209, 102)), Add)
        end

        if Main.EspPenEggs then
            PenEggs(Origin, Wanted, Colour("EspPenEggColor", Color3.fromRGB(110, 231, 255)), Add)
        end

        if Main.EspPenPets then
            PenPets(Origin, Wanted, Colour("EspPenPetColor", Color3.fromRGB(176, 108, 255)), Add)
        end

        if Main.EspTraps then
            Traps(Origin, Wanted, Colour("EspTrapColor", Color3.fromRGB(255, 59, 59)), Add)
        end

        if Main.EspMonsters then
            Monsters(Origin, Wanted, Colour("EspMonsterColor", Color3.fromRGB(255, 84, 112)), Add)
        end

        table.sort(Found, function(Left, Right)
            return Left.Distance < Right.Distance
        end)

        Used = 0

        for Index = 1, math.min(#Found, Limit) do
            local Entry = Found[Index]

            Draw(Entry.Position, Entry.Size, Entry.Model, Entry.Tint, Entry.Label)
        end

        Release(Used + 1)
    end

    ---- ---- the pen, emptied ---- ----
    --
    -- Eighty-two rendered pets on a busy server is 2431 parts, 492 billboard GUIs and 25
    -- particle emitters, and ActiveAssetsController writes a CFrame to every one of them every
    -- frame through its own movement batch. That is the frame rate, and almost none of it is
    -- the player's own plot -- most of it belongs to the other six bases on the map.
    --
    -- Destroying the models is what "delete" sounds like and it does not work. Measured: the
    -- controller keeps a registry keyed on the model, and the next reconcile throws
    -- "Asset model <uid> is not registered in the movement batch" -- once per reconcile per
    -- dead model, forever, until the client rejoins.
    --
    -- Reparenting them out of Workspace instead costs nothing and throws nothing -- measured
    -- over four seconds with five models moved out, not one error on any of them -- because
    -- every instance is still there for the controller to find. They stop being rendered and
    -- stop being simulated, and putting them back is one more reparent.
    --
    -- Our own plot is left alone, and that is the one judgement call in here. It is a sixth of
    -- the cost on a busy server -- 14 of the 82 models measured -- and it is the sixth the
    -- player actually looks at: hiding it would empty the pen on screen and blank the Pen Pets
    -- ESP with it, since a Highlight adorned to something outside Workspace draws nothing.
    local Parked = nil

    -- where each model was taken from, so switching the toggle back off puts it exactly there.
    -- Workspace carries more than one folder of a given name on this map -- two PlacedEggRenders
    -- were counted on a live server -- so "the first folder called ClientRenderedAssets" is a
    -- guess, and a model handed back to the wrong one is a model the controller stops finding.
    local Homes = { }

    local function RenderHome()
        for _, Folder in ipairs(workspace:GetChildren()) do
            if Folder.Name == "ClientRenderedAssets" then return Folder end
        end
    end

    function Visual.HidePets(On)
        if not On then
            if not Parked then return 0 end

            for _, Model in ipairs(Parked:GetChildren()) do
                local Home = Homes[Model]

                if not (Home and Home.Parent) then
                    Home = RenderHome() or workspace
                end

                Model.Parent = Home
            end

            pcall(function()
                Parked:Destroy()
            end)

            Parked = nil

            table.clear(Homes)

            return 0
        end

        if not Parked then
            Parked = Instance.new("Folder")
            Parked.Name = "\0"
        end

        local Moved = 0

        for _, Folder in ipairs(workspace:GetChildren()) do
            if Folder.Name == "ClientRenderedAssets" then
                for _, Model in ipairs(Folder:GetChildren()) do
                    if Model:GetAttribute("OwnerUserId") ~= LocalPlayer.UserId then
                        Homes[Model] = Folder
                        Model.Parent = Parked
                        Moved = Moved + 1
                    end
                end
            end
        end

        return Moved
    end
end

---- ============ Inventory value ============ ----
--
-- What each pet earns, printed in the corner of every slot of the game's own backpack.
--
-- The tag used to be the seller NPC's price. It is the rate now -- AssetGenerationUtil.GetRate
-- with the rebirth folded in, the same number the billboard over the pen prints -- because that
-- is the one that answers what a slot is worth keeping: two pets with the same sale price can
-- be an order of magnitude apart on money per second, and the pen only holds so many.
--
-- The price is still worked out per item, for two reasons. It is what an egg's tag falls back
-- to, since an egg pays nothing until it hatches and what it will pay is not known until then.
-- And the total on the hub's own label is a Sell All total, which has to stay a price: it reads
-- the same two functions the NPC's prompt reads -- AssetItems.SalePrice for a pet,
-- EggRecords.SellPrice for an unplaced egg -- and doubles them while the VIP attribute is on,
-- exactly as promptSellHeld does, so the number is the money that lands in the counter. The
-- label prints the bag's whole rate next to it.
--
-- Binding a slot to a uid is the only awkward part, because the slot carries no uid of its
-- own: BackpackGui.Backpack.Main.Inventory.ScrollingFrame holds one TextButton per item whose
-- ToolName label reads "<name> (<weight>)" and nothing else identifies it. So the lookup is
-- built on that string from the side that does have uids --
--
--   pets   the Tool instances in the player's Backpack, which carry UID and ItemType
--          attributes and whose Name already includes the mutation prefix ("Golden Mammoth")
--          that the save's own DisplayName does not
--
--   eggs   the EggInventory records, through EggRecords.DisplayNameWithWeight, because eggs
--          do not all have a Tool in the Backpack -- measured with three egg slots on screen
--          and one egg Tool in the bag
--
-- Measured against all forty-five slots on a live bag: forty-two pets matched off the Tools,
-- three eggs off the records, nothing missed.
--
-- Equipped, favourited and in-fuse pets are the ones the seller refuses, so their tag is
-- greyed and they are left out of the total.
--
-- Behind one local like Visual because the main chunk is at Luau's ceiling of 200 locals.
local Inventory = { }

do
    local TagSellable = Color3.fromRGB(120, 255, 140)
    local TagLocked = Color3.fromRGB(150, 158, 172)

    -- Slot -> our label on it.
    --
    -- A map rather than FindFirstChild by name, because the trick the rest of this file uses to
    -- keep its instances unreadable does not survive here: Name = "\0" is accepted and then
    -- stored as "", so the lookup missed every time and a fresh label stacked onto every slot
    -- on every pass -- sixteen of them deep after a few seconds.
    --
    -- The empty name is still what lands, and it is what Sweep below keys on: every child the
    -- game itself puts in a slot has a real name (ToolName, Weight, FavIcon, Shadow ...), so a
    -- nameless one in there is ours and nobody else's.
    local Tagged = { }
    local LastAt = 0

    -- what a Sell All would pay right now, and what the whole bag earns per second, both read
    -- by the hub's own label
    Inventory.Total = 0
    Inventory.Count = 0
    Inventory.Rate = 0

    local function Slots()
        local Gui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        local Backpack = Gui and Gui:FindFirstChild("BackpackGui")
        local Frame = Backpack and Backpack:FindFirstChild("Backpack")
        local Main = Frame and Frame:FindFirstChild("Main")
        local Panel = Main and Main:FindFirstChild("Inventory")

        return Panel and Panel:FindFirstChild("ScrollingFrame") or nil
    end

    -- The NPC doubles what it pays for a VIP, and the doubling is on the player rather than on
    -- the item, so it is read once per pass rather than per row.
    local function VipFactor()
        return LocalPlayer:GetAttribute("VIP") and 2 or 1
    end

    -- "<ToolName text>" -> { Value, Rate, Locked }, for every item in the bag
    local function Prices()
        local Data = Save.Get()

        if not Data then return nil end

        local Factor = VipFactor()

        -- the rate belongs to the pet with the rebirth already inside it -- see AssetRate --
        -- and the rebirth is on the player, so it is read once per pass rather than per row
        local Rebirth = Data.Rebirth or 0
        local Equipped = { }

        for _, Uid in ipairs(Data.EquippedAssets or { }) do
            Equipped[Uid] = true
        end

        local Table = { }
        local Total, Count, Earned = 0, 0, 0

        local Backpack = LocalPlayer:FindFirstChildOfClass("Backpack")

        for _, Tool in ipairs(Backpack and Backpack:GetChildren() or { }) do
            local Uid = Tool:GetAttribute("UID")

            if type(Uid) == "string" and Tool:GetAttribute("ItemType") == "Asset" then
                local Record = (Data.Inventory or { })[Uid]

                -- not `Record ~= nil and pcall(...)`: an `and` keeps only the first return, so
                -- the decoded item is thrown away and every lookup comes back empty
                local Ok, Item = false, nil

                if Record ~= nil then
                    Ok, Item = pcall(AssetItemSerialization.Deserialize, Record)
                end

                if Ok and type(Item) == "table" then
                    local Weighed, Weight = pcall(AssetItemSerialization.WeightLabel, Item)
                    local Priced, Price = pcall(AssetItemSerialization.SalePrice, Item)

                    local Value = (Priced and type(Price) == "number") and Price * Factor or 0
                    local Rate = AssetRate(Item, Rebirth)
                    local Locked = Equipped[Uid] == true
                        or Item.IsFavorite == true
                        or Item.InFuse == true

                    if Weighed then
                        Table[Tool.Name .. " (" .. tostring(Weight) .. ")"] = {
                            Value = Value,
                            Rate = Rate,
                            Locked = Locked,
                        }
                    end

                    -- Every pet in the bag counts toward the rate, equipped and favourited
                    -- ones included: a pet pays what it pays whether or not the seller would
                    -- take it, and leaving those out would print a number smaller than what
                    -- the pen is actually earning. The sell total is the one with a reason to
                    -- skip them.
                    if type(Rate) == "number" then
                        Earned = Earned + Rate
                    end

                    if not Locked then
                        Total = Total + Value
                        Count = Count + 1
                    end
                end
            end
        end

        -- Eggs come off the records rather than off the Tools, because the bag does not hold a
        -- Tool for every egg it shows a slot for. Nothing makes an egg unsellable, so every one
        -- of them counts toward the total whether the tags are switched on or not.
        for _, Record in pairs(Data.EggInventory or { }) do
            if type(Record) == "table" and Record.Placement == nil then
                local Ok, Decoded = pcall(EggItemUtil.DeserializeSavedEgg, Record)

                if Ok then
                    local Named, Name = pcall(EggItemUtil.DisplayNameWithWeight, Decoded)
                    local Priced, Price = pcall(EggItemUtil.SellPrice, Decoded)

                    local Value = (Priced and type(Price) == "number") and Price * Factor or 0

                    -- no Rate on an egg: it pays nothing until it hatches, and what it will
                    -- pay is not known until then. Its tag falls back to the sale price.
                    if Named then
                        Table[tostring(Name)] = { Value = Value, Locked = false }
                    end

                    Total = Total + Value
                    Count = Count + 1
                end
            end
        end

        Inventory.Total = Total
        Inventory.Count = Count
        Inventory.Rate = Earned

        return Table
    end

    -- Top-left of the slot, which is the one corner the game leaves empty: ToolName runs along
    -- the bottom, the favourite star sits top-right, and Weight -- top-right as well -- is
    -- blank on every slot measured. ZIndex 31 because the star is 30.
    local function Tag(Slot)
        local Label = Tagged[Slot]

        -- the slot survives but its children do not always: the game rebuilds the grid when
        -- the bag changes, and a handle to a label whose parent has gone is a leak
        if Label and Label.Parent == Slot then return Label end

        Label = Instance.new("TextLabel")
        Label.Name = ""
        Label.AnchorPoint = Vector2.new(0, 0)
        Label.Position = UDim2.fromScale(0.04, 0.04)
        Label.Size = UDim2.fromScale(0.7, 0.18)
        Label.BackgroundTransparency = 1
        Label.Font = Enum.Font.GothamBold
        Label.TextScaled = true
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.TextYAlignment = Enum.TextYAlignment.Top
        Label.ZIndex = 31
        Label.Parent = Slot

        local Stroke = Instance.new("UIStroke")
        Stroke.Thickness = 1.4
        Stroke.Color = Color3.new(0, 0, 0)
        Stroke.Transparency = 0.15
        Stroke.Parent = Label

        Tagged[Slot] = Label

        return Label
    end

    -- Every nameless label in the grid, whether this session put it there or a previous one
    -- did. A re-execute keeps the game's own UI, so a tag left behind by the copy that just
    -- got torn down would sit on the slot forever with a stale price on it.
    local function Sweep()
        local List = Slots()

        if not List then return end

        for _, Slot in ipairs(List:GetChildren()) do
            if Slot:IsA("TextButton") then
                for _, Child in ipairs(Slot:GetChildren()) do
                    if Child:IsA("TextLabel") and Child.Name == "" then
                        pcall(function()
                            Child:Destroy()
                        end)
                    end
                end
            end
        end
    end

    function Inventory.Clear()
        for _, Label in pairs(Tagged) do
            pcall(function()
                Label:Destroy()
            end)
        end

        table.clear(Tagged)

        pcall(Sweep)

        Inventory.Total = 0
        Inventory.Count = 0
        Inventory.Rate = 0
    end

    function Inventory.Refresh()
        local Main = getgenv().Settings.Main

        if Main.InventoryValue ~= true then
            if next(Tagged) then Inventory.Clear() end

            return
        end

        -- the caller's loop runs three times a second for the ESP; decoding the whole bag and
        -- walking every slot does not need to
        if os.clock() - LastAt < 0.5 then return end

        LastAt = os.clock()

        local List = Slots()

        if not List then return end

        local Table = Prices()

        if not Table then return end

        for _, Slot in ipairs(List:GetChildren()) do
            -- Template is the hidden prototype the game clones slots from; tagging it would
            -- put a stale price on every slot made after this pass
            if Slot:IsA("TextButton") and Slot.Name ~= "Template" and Slot:GetAttribute("IsInventorySlot") then
                local Name = Slot:FindFirstChild("ToolName")
                local Entry = Name and Name:IsA("TextLabel") and Table[Name.Text] or nil
                local Egg = Slot:GetAttribute("HasEggOverlay") == true

                if Entry and not (Egg and Main.InventoryValueEggs == false) then
                    local Label = Tag(Slot)

                    -- what the pet earns, not what it sells for: the money per second is the
                    -- number that decides whether a pet is worth a pen slot, and the sale price
                    -- follows from it anyway. An egg has no rate, so its tag stays the price.
                    Label.Text = Entry.Rate and ("$" .. FormatSpeed(Entry.Rate) .. "/s")
                        or ("$" .. FormatSpeed(Entry.Value))
                    Label.TextColor3 = Entry.Locked and TagLocked or TagSellable
                    Label.Visible = true
                else
                    -- a gear slot, an egg with the egg tags switched off, or an item whose
                    -- record has not replicated yet: the tag is kept and hidden rather than
                    -- destroyed, because the slot is reused for the next item that lands in it
                    local Label = Tagged[Slot]

                    if Label and Label.Parent == Slot then
                        Label.Visible = false
                    end
                end
            end
        end
    end
end

-- Its own thread rather than a Loop: nothing here walks, so it has no business claiming the
-- walk order, and a pass that is only reading positions does not want to wait behind a steal
-- run either.
task.spawn(function()
    while getgenv().ValkyrieSession == SessionToken do
        pcall(Visual.Refresh)
        pcall(Inventory.Refresh)

        -- the game re-renders a pet the moment its owner's plot changes, so the sweep repeats
        -- rather than running once off the toggle
        if getgenv().Settings.Main.HidePenPets == true then
            pcall(Visual.HidePets, true)
        end

        task.wait(0.35)
    end
end)

---- ============ Pet ============ ----

local function EquipBest()
    local Ok, Done = pcall(Network.Invoke, "RF/Haul/WearBest")

    return Ok and Done == true
end

local function FavoriteEquipped()
    local Data = Save.Get()

    if not Data then return end

    for _, Uid in ipairs(Data.EquippedAssets or { }) do
        local Record = (Data.Inventory or { })[Uid]

        if type(Record) == "table" and Record.IsFavorite ~= true then
            pcall(Network.Fire, "RE/PetSatchel/WriteFavourite", Uid, true)

            task.wait(0.1)
        end
    end
end

local function UnequipAll()
    local Data = Save.Get()

    if not Data then return end

    local Uids = { }

    for _, Uid in ipairs(Data.EquippedAssets or { }) do
        table.insert(Uids, Uid)
    end

    for _, Uid in ipairs(Uids) do
        pcall(AssetCmds.RequestUnequipAsset, Uid)

        task.wait(0.1)
    end
end

---- ============ Misc ============ ----

local function ClaimIndex()
    local Present, Ok, Result = InvokeRemote(Endpoint.IndexClaimAll)

    return Present and Ok and Result ~= false
end

local function RebirthReady()
    local Data = Save.Get()

    if not Data then return false end

    local Current = Data.Rebirth or 0
    local Ok, Max = pcall(RebirthUtil.GetMaxRebirth)

    if Ok and type(Max) == "number" and Current >= Max then return false end

    local Priced, Need = pcall(RebirthUtil.RebirthToRequiredSpeedPower, Current + 1)

    if not (Priced and type(Need) == "number") then return false end

    return (Data.SpeedPower or 0) >= Need
end

local function DoRebirth()
    if not RebirthReady() then return false end

    local Present = NetworkFolder:FindFirstChild(Endpoint.RebirthRequest) ~= nil

    if not Present then return false end

    StopTreadmill()

    local _, Ok, Result = InvokeRemote(Endpoint.RebirthRequest)

    if not (Ok and Result ~= false) then return false end

    task.wait(0.3)
    InvokeRemote(Endpoint.RebirthCommit)

    return true
end

local function BuyTrails()
    local Wanted, Count = ToSet(getgenv().Settings.Main.BuyTrails)

    if Count == 0 then return end

    local Data = Save.Get()

    if not Data then return end

    for _, Info in ipairs(TrailList) do
        if Wanted[Info.Label] and not (Data.TrailInventory or { })[Info.Id] then
            if (Data.Money or 0) < Info.Price then return end

            local Present, Ok, Result = InvokeRemote(Endpoint.TrailPurchase, Info.Id)

            if not (Present and Ok and Result == true) then return end

            task.wait(0.2)

            Data = Save.Get()

            if not Data then return end
        end
    end
end

-- Both behind one forward declaration, with the five values they run on shut inside the block
-- below rather than standing in the main chunk. Luau allows a function two hundred active
-- locals and this chunk is at that ceiling: seven names here is seven the rest of the file
-- cannot have, and only two of them are ever read from outside.
local Loop, RunManual

do

local Running = { }

-- Every toggle restored from config calls Loop within the same few frames of boot, so
-- without this they all fire their first remote on the same tick right after execute.
-- That spike is what gets the kick when a lot of features are left on. Each loop waits
-- out the grace and then takes its own slot after it.
local StartupAt = os.clock()
local StartupGrace = 5
local StartupStagger = 0.4
local StartupSlot = 0

-- Guard, when given, is asked before the walk order is claimed rather than inside the step.
-- That ordering is the whole point: claiming preempts every lower-ranked loop that is mid-run,
-- so a pass that was only going to decide it had nothing to do has to decide it beforehand.
function Loop(Key, Delay, Step, Guard)
    if Running[Key] then return end

    Running[Key] = true

    StartupSlot = StartupSlot + 1

    local Slot = StartupSlot

    task.spawn(function()
        local Remaining = StartupGrace + Slot * StartupStagger - (os.clock() - StartupAt)

        if Remaining > 0 then
            task.wait(Remaining)
        end

        while getgenv().ValkyrieSession == SessionToken and (getgenv().Settings.Main or { })[Key] do
            if (Guard == nil or Guard() ~= false) and ClaimWalk(Key) then
                pcall(Step)
                ReleaseWalk(Key)
            end

            -- loops that share a delay drift back into phase and re-form the spike a few
            -- minutes in, so each pass gets a little jitter on top
            task.wait(Delay + math.random() * math.min(Delay * 0.25, 0.5))
        end

        Running[Key] = nil
    end)
end

function RunManual(Step)
    task.spawn(function()
        if not ClaimWalk(ManualKey) then return end

        pcall(Step, ManualKey)
        ReleaseWalk(ManualKey)
    end)
end

end

---- ============ Interface ============ ----

do
    local Ok, Source = pcall(game.HttpGet, game, Boot.Library, true)

    if not (Ok and type(Source) == "string" and #Source > 50000) then
        error(string.format(
            "[ValkyrieHub] %s did not return the UI library (%s, %d bytes -- expected 100000+)",
            Boot.Library,
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

local Accent = Color3.fromRGB(255, 190, 70)
local Gradient = Color3.fromRGB(140, 90, 20)

Library.Theme.Accent = Accent
Library.Theme.AccentGradient = Gradient
Library:ChangeTheme("Accent", Accent)
Library:ChangeTheme("AccentGradient", Gradient)

Library:AddLanguages({
    th = {
        ["Configuration"] = "ตั้งค่า",
        ["Interface"] = "ตั้งค่าหน้าต่าง",
        ["Window and executor options"] = "ตั้งค่าหน้าต่างและตัวรันสคริปต์",
        ["Framerate and screen"] = "เฟรมเรตและหน้าจอ",
        ["Script Loaded Successfully"] = "โหลดสคริปต์สำเร็จแล้ว",
        ["Window Transparency"] = "ทำหน้าต่างโปร่งใส",
        ["Anti-AFK"] = "กันหลุด AFK",
        ["Auto Rejoin"] = "เข้าเกมใหม่อัตโนมัติ",
        ["Auto Executor"] = "รันสคริปต์ตอนย้ายเซิร์ฟ",
        ["Minimize Bind"] = "ปุ่มย่อ/เปิดเมนู",
        ["FPS"] = "FPS",
        ["FPS Value"] = "ค่า FPS",
        ["FPS Lock"] = "ล็อก FPS",
        ["White Screen"] = "จอขาว",
        ["Language"] = "ภาษา",
        ["Select Language"] = "เลือกภาษา",
        ["Change Language"] = "เปลี่ยนภาษา",
        ["Search"] = "ค้นหา",
        ["Close"] = "ปิด",
        ["Any"] = "ทั้งหมด",
        ["Automatic"] = "อัตโนมัติ",
        ["Farm Speed"] = "ฟาร์มความเร็ว",
        ["Run on the ped your base"] = "วิ่งลู่ที่ฐานจนความเร็วพอ",
        ["Auto Farm Speed"] = "ฟาร์มความเร็วอัตโนมัติ",
        ["Auto Upgrade Treadmill"] = "อัปเกรดลู่วิ่งอัตโนมัติ",
        ["Speed Margin"] = "เผื่อความเร็วเกินมอนกี่ %",
        ["Auto Sell"] = "ขายอัตโนมัติ",
        ["Sells only what you name here"] = "ขายเฉพาะที่เลือกไว้เท่านั้น",
        ["Sell Rarity"] = "ขายตามระดับความหายาก",
        ["Sell Brainrot"] = "ขายตามตัวที่เลือก",
        ["Sell Egg"] = "ขายไข่ตามที่เลือก",
        ["Sell Below $/s"] = "ขายตัวที่ปั่นเงินต่ำกว่า ($/วิ)",
        ["0 = off, or 5M / 1.2B"] = "0 = ปิด หรือพิมพ์ 5M / 1.2B",
        ["Sell Below:"] = "ขายต่ำกว่า:",
        ["off"] = "ปิด",
        ["No treadmill at your base yet, upgrade your base first"] = "ยังไม่มีลู่วิ่งที่ฐาน ต้องอัปเกรดฐานก่อน",
        ["Steal Egg"] = "ขโมยไข่",
        ["Steal eggs from the monster areas"] = "ขโมยไข่จากโซนที่มีมอนสเตอร์",
        ["Auto Steal Egg"] = "ขโมยไข่อัตโนมัติ",
        ["Auto Deliver"] = "ส่งไข่กลับโซนปลอดภัยอัตโนมัติ",
        ["Select Area"] = "เลือกโซน (เลือกได้ทุกโซน ไม่ต้องดูความเร็ว)",
        ["Select Rarity To Steal"] = "ขโมยตามระดับความหายาก",
        ["Pick Egg By"] = "เลือกไข่แบบไหนก่อน (ไข่ที่ประกาศในแชทและไข่ที่ตกอยู่ ตามข้ามโซนที่ไม่ได้เลือก)",
        ["Rarest"] = "หายากสุด",
        ["Nearest"] = "ใกล้สุด",
        ["Largest"] = "ตัวใหญ่สุด",
        ["Tween Speed"] = "ความเร็วในการเดินทาง (ไม่เกี่ยวกับ Speed ในเกม)",
        ["Steal Delay"] = "พักกี่วินาทีต่อรอบ",
        ["Grab Retry Time"] = "ลองหยิบไข่ซ้ำกี่วินาที",
        ["Chase Egg Thief"] = "ไล่ตีคนที่แย่งไข่เราไป",
        ["Steal From Players"] = "แย่งไข่จากคนอื่น (ไล่ตีให้ไข่หล่นแล้วเก็บ)",
        ["Steal Nearest Egg Now"] = "ขโมยไข่ใบใกล้สุดตอนนี้",
        ["Drop Egg"] = "วางไข่ที่ถืออยู่",
        ["Return To Safe Zone"] = "กลับโซนปลอดภัย",
        ["Fuse Machine"] = "เครื่องหลอมรวม",
        ["Fuse three same brainrots into an egg"] = "หลอมตัวเหมือนกัน 3 ตัวเป็นไข่ 1 ฟอง",
        ["Auto Fuse"] = "หลอมอัตโนมัติ",
        ["Fuse Brainrot"] = "หลอมเฉพาะตัวที่เลือก",
        ["Skip Mutated"] = "ข้ามตัวที่มีมิวเทชัน",
        ["Pick a brainrot first"] = "เลือกตัวที่จะหลอมก่อน",
        ["Not enough to fuse yet"] = "ตัวยังไม่พอหลอม",
        ["Ready to fuse"] = "หลอมได้",
        ["Fuse Delay"] = "พักกี่วินาทีต่อรอบหลอม",
        ["Return Pets"] = "เอาตัวออกจากเครื่อง",
        ["Combat"] = "ต่อสู้",
        ["Monster Parasite"] = "อีเวนต์ไข่ติดเชื้อ",
        ["Feed infested eggs to the Hungry Monster"] = "เอาไข่ติดเชื้อไปให้มอนสเตอร์กิน ครบ 5 ฟองได้ 1 หีบ",
        ["Auto Monster Parasite"] = "ลุยอีเวนต์ไข่ติดเชื้ออัตโนมัติ",
        ["Auto Feed Infested Eggs"] = "ป้อนไข่ติดเชื้ออัตโนมัติ",
        ["Auto Claim Monster Chest"] = "เปิดหีบมอนสเตอร์อัตโนมัติ",
        ["Feed Mutated Eggs"] = "ป้อนไข่ที่มีมิวเทชันด้วย (ไข่โดนกินหายไปเลย ปิดไว้ดีกว่า)",
        ["Steal Infested Eggs First"] = "ขโมยไข่ติดเชื้อก่อนเสมอ (ข้ามโซน/ข้ามฟิลเตอร์ระดับ)",
        ["Feed The Monster Now"] = "ป้อนมอนสเตอร์ตอนนี้",
        ["Event ends in"] = "อีเวนต์เหลืออีก",
        ["Charge"] = "ชาร์จ",
        ["Chests"] = "หีบค้าง",
        ["Infested eggs"] = "ไข่ติดเชื้อในกระเป๋า",
        ["The monster event has ended"] = "อีเวนต์จบไปแล้ว",
        ["Too slow for the monster - farm speed first"] = "ความเร็วยังไม่ถึงเกณฑ์ (ต้องเท่ายาม Jungle) ไปฟาร์มก่อน",
        ["Bat the nearest player"] = "ตีคนที่ใกล้สุด",
        ["Auto Attack Players"] = "ตีผู้เล่นอัตโนมัติ",
        ["Attack Aura"] = "ตีอัตโนมัติรอบตัว",
        ["Select Player"] = "เลือกผู้เล่น",
        ["Attack Player"] = "ไล่ตีผู้เล่นที่เลือก",
        ["Pick a player first"] = "เลือกผู้เล่นก่อน",
        ["Attack Range"] = "ระยะตี (เกินระยะไม้จริงจะถูกหั่นลงอัตโนมัติ)",
        ["Attack Delay"] = "พักกี่วินาทีต่อการตี",
        ["Target is in the safe zone, waiting at the line"] = "เป้าหมายอยู่ในเซฟโซน รออยู่ที่เส้นแบ่ง",
        ["Plot"] = "ฐาน",
        ["Egg"] = "ไข่",
        ["Place and hatch eggs on your plot"] = "วางไข่และฟักไข่ที่ฐาน",
        ["Auto Place Egg"] = "วางไข่อัตโนมัติ",
        ["Auto Open Egg"] = "ฟักไข่อัตโนมัติ",
        ["Select Egg To Place"] = "เลือกไข่ที่จะวาง",
        ["Select Rarity To Place"] = "วางตามระดับความหายาก",
        ["Plot Delay"] = "พักกี่วินาทีต่อรอบวาง/ฟัก",
        ["Place All Now"] = "วางไข่ทั้งหมดตอนนี้",
        ["Hatch All Ready Now"] = "ฟักไข่ที่พร้อมทั้งหมดตอนนี้",
        ["Pet"] = "สัตว์เลี้ยง",
        ["Fill the pen with your best brainrots"] = "เอาตัวที่ดีที่สุดใส่คอก",
        ["Auto Equip Best"] = "ใส่ตัวที่ดีที่สุดอัตโนมัติ",
        ["Auto Favorite Equipped"] = "ติดดาวตัวที่อยู่ในคอกอัตโนมัติ",
        ["Auto Buy +1 Equip"] = "ซื้อ +1 ช่องใส่ตัวอัตโนมัติ",
        ["Equip Delay"] = "พักกี่วินาทีต่อรอบใส่",
        ["Unequip All"] = "เอาตัวออกจากคอกทั้งหมด",
        ["Equip Best Now"] = "ใส่ตัวที่ดีที่สุดตอนนี้",
        ["Misc"] = "อื่น ๆ",
        ["Player"] = "ตัวละคร",
        ["Index rewards, rebirth and the pen"] = "รับรางวัล Index, รีเบิร์ธ และอัปเกรดคอก",
        ["Auto Claim Index"] = "รับรางวัล Index อัตโนมัติ",
        ["Auto Rebirth"] = "รีเบิร์ธอัตโนมัติ (ความเร็วรีเซ็ต)",
        ["Auto Upgrade Pen"] = "อัปเกรดคอกอัตโนมัติ",
        ["Rebirth"] = "รีเบิร์ธ",
        ["Ready"] = "พร้อมรีเบิร์ธ",
        ["Not on this server"] = "เซิร์ฟนี้ยังไม่เปิด",
        ["Visual"] = "ภาพ",
        ["ESP"] = "ESP",
        ["See eggs, pets, traps and monsters through the map"] = "มองทะลุกำแพง เห็นไข่ สัตว์ กับดัก และมอน",
        ["ESP Area Eggs"] = "มองทะลุไข่ในโซนมอน",
        ["ESP Pen Eggs"] = "มองทะลุไข่ในคอก",
        ["ESP Pen Pets"] = "มองทะลุสัตว์ในคอก",
        ["ESP Traps"] = "มองทะลุกับดัก",
        ["ESP Monsters"] = "มองทะลุมอน",
        ["ESP Range"] = "ระยะ ESP",
        ["How much of it is drawn"] = "จะวาดไกลแค่ไหน กี่ชิ้น",
        ["ESP Distance"] = "ระยะมองไกลสุด",
        ["ESP Max Shown"] = "วาดพร้อมกันกี่ชิ้น (เกมจำกัดที่ 30)",
        ["Monsters show rarity, walk speed and hit range"] = "ป้ายมอนบอกระดับ ความเร็ววิ่ง และระยะตี",
        ["Inventory ESP"] = "ดูราคาของในกระเป๋า",
        ["Price tag on every backpack slot"] = "ติดราคาขายไว้ที่ช่องของในกระเป๋าทุกช่อง",
        ["Show Inventory $/s"] = "แสดงเงินต่อวิของตัวในกระเป๋า (ไข่ยังเป็นราคาขาย)",
        ["Include Eggs"] = "ติดป้ายไข่ด้วย",
        ["Bag:"] = "ขายทั้งกระเป๋าได้:",
        ["Grey = can't sell (equipped / favorite / in fuse)"] = "สีเทา = ขายไม่ได้ (อยู่ในคอก / ติดดาว / อยู่ในเครื่องหลอม)",
        ["Delete Pet in Pen"] = "ลบสัตว์ในคอกคนอื่นทั้งแมพ (แก้ FPS ตก คอกเราไม่หาย)",
        ["Shop"] = "ร้านค้า",
        ["Buy trails with money"] = "ซื้อเทรลด้วยเงินในเกม",
        ["Select Trails"] = "เลือกเทรลที่จะซื้อ",
        ["Auto Buy Trails"] = "ซื้อเทรลอัตโนมัติ",
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
    Name = "Valkyrie Hub",
    SubName = "by Phoenix",
    Logo = IconValkyrie
})

Window:Category("General")

---- ============ Automatic ============ ----

-- The whole Automatic page sits in its own do block. An executor that compiles with full
-- debug info (-g2) keeps every local in its own register for the life of the function, so
-- the page's twenty-odd element handles were what pushed the main chunk past Luau's ceiling
-- of 200 -- the compile failed on LanguageSection down in the Configuration page. Only the
-- four names the Boot thread and the later pages still reach for by name are hoisted out.
local SpeedLabel, FusePreview, ShowTextWhenEmpty
local AnyDropdownText = "Any"

do

local AutomaticPage = Window:Page({ Name = "Automatic", Icon = Icon("bot", "80451686744860"), Columns = 2 })

local FarmSection = AutomaticPage:Section({
    Name = "Farm Speed",
    Description = "Run on the ped your base",
    Icon = Icon("footprints", "117851493400222"),
    Side = 1,
    EnableToggle = true
})

SpeedLabel = FarmSection:Label("Speed: 0")

FarmSection:Toggle({
    Name = "Auto Farm Speed",
    Flag = "STEAutoFarmSpeed",
    Default = getgenv().Settings.Main.AutoFarmSpeed,
    Callback = function(Value)
        getgenv().Settings.Main.AutoFarmSpeed = Value
        SaveSetting()

        if not Value then
            StopTreadmill()

            return
        end

        -- This used to stand itself down entirely whenever Auto Steal Egg was on, and hand
        -- the treadmill to a copy of FarmSpeed nested inside the steal loop. That copy only
        -- ran on the one branch where the steal loop had found no egg, so with both toggles
        -- on there was no farming at night, none while the daylight left was too short for a
        -- trip, and none while the steal loop was busy walking -- and the treadmill it did
        -- mount was held under the steal loop's own walk order, which blocked the plot and
        -- fuse loops behind it.
        --
        -- The farm owns the treadmill now. It sits at the bottom of the walk order, so it
        -- runs whenever nothing above it wants the character, and FarmSpeed hands the
        -- character over -- off the belt -- the moment something does.
        Loop("AutoFarmSpeed", 1, function()
            -- an egg in hand, or eggs waiting for the plot, both need the character
            -- somewhere the treadmill is not
            if IsCarrying() then return end
            if PlotChoresPending() then return end

            -- Do not start a trip to the treadmill in the gap between two steal passes.
            --
            -- The steal loop releases the walk order at the end of every pass and claims it
            -- again half a second later, and without this the farm spent that half second
            -- setting off for the plot from wherever the steal run had got to. Measured with
            -- both toggles on: the character bouncing between 545, 595, 540 and the treadmill
            -- pad, and the pad itself mounted and dismounted four times in eight seconds.
            if StealBusy() then return end

            FarmSpeed("AutoFarmSpeed")
        end)
    end
})

FarmSection:Slider({
    Name = "Speed Margin",
    Flag = "STESpeedMargin",
    Min = 0,
    Max = 25,
    Decimals = 1,
    Default = getgenv().Settings.Main.SpeedMargin,
    Suffix = " %",
    Callback = function(Value)
        getgenv().Settings.Main.SpeedMargin = Value
        SaveSetting()
    end
})

FarmSection:Toggle({
    Name = "Auto Upgrade Treadmill",
    Flag = "STEAutoUpgradeTreadmill",
    Default = getgenv().Settings.Main.AutoUpgradeTreadmill,
    Callback = function(Value)
        getgenv().Settings.Main.AutoUpgradeTreadmill = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoUpgradeTreadmill", 5, UpgradeTreadmill)
    end
})

local SellSection = AutomaticPage:Section({
    Name = "Auto Sell",
    Description = "Sells only what you name here",
    Icon = Icon("coins", "117851493400222"),
    Side = 1,
    EnableToggle = true
})

SellSection:Toggle({
    Name = "Auto Sell",
    Flag = "STEAutoSell",
    Default = getgenv().Settings.Main.AutoSell,
    Callback = function(Value)
        getgenv().Settings.Main.AutoSell = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoSell", 3, SellSweep)
    end
})

local SellRarityDropdown = SellSection:Dropdown({
    Name = "Sell Rarity",
    Flag = "STESellRarities",
    Items = RarityItems,
    Default = getgenv().Settings.Main.SellRarities,
    Multi = true,
    Callback = function(Value)
        getgenv().Settings.Main.SellRarities = Value
        SaveSetting()
    end
})

local SellCategoryDropdown = SellSection:Dropdown({
    Name = "Sell Brainrot",
    Flag = "STESellCategories",
    Items = CategoryItems,
    Default = getgenv().Settings.Main.SellCategories,
    Multi = true,
    Callback = function(Value)
        getgenv().Settings.Main.SellCategories = Value
        SaveSetting()
    end
})

local SellEggDropdown = SellSection:Dropdown({
    Name = "Sell Egg",
    Flag = "STESellEggCategories",
    Items = EggItems,
    Default = getgenv().Settings.Main.SellEggCategories,
    Multi = true,
    Callback = function(Value)
        getgenv().Settings.Main.SellEggCategories = Value
        SaveSetting()
    end
})

local SellRateLabel = SellSection:Label("Sell Below: off")

local function SellRateShow(Value)
    local Below = ParseSpeed(tostring(Value or "")) or tonumber(Value) or 0

    SellRateLabel:SetText(string.format(
        "%s %s",
        Library:Translate("Sell Below:"),
        Below > 0 and ("$" .. FormatSpeed(Below) .. "/s") or Library:Translate("off")
    ))
end

-- Not Numeric, on purpose: the numbers this compares against run to tens of millions and
-- typing 21000000 into a phone is not a feature. The box takes 5M, 1.2B, 900K or a plain
-- number, all through the same parser the area speed signs go through, and the label above it
-- reads the parse back so a typo is visible before the loop acts on it.
SellSection:Textbox({
    Name = "Sell Below $/s",
    Flag = "STESellBelowRate",
    Placeholder = "0 = off, or 5M / 1.2B",
    Default = tostring(getgenv().Settings.Main.SellBelowRate or "0"),
    Numeric = false,
    Finished = false,
    Callback = function(Value)
        getgenv().Settings.Main.SellBelowRate = tostring(Value or "")
        SaveSetting()

        pcall(SellRateShow, Value)
    end
})

-- the box does not fire its callback on load, so the label would sit on its placeholder text
-- until the first keystroke and a saved threshold would look like it was not set
pcall(SellRateShow, getgenv().Settings.Main.SellBelowRate)

local StealSection = AutomaticPage:Section({
    Name = "Steal Egg",
    Description = "Steal eggs from the monster areas",
    Icon = Icon("egg", "117851493400222"),
    Side = 2,
    EnableToggle = true
})

StealSection:Toggle({
    Name = "Auto Steal Egg",
    Flag = "STEAutoStealEgg",
    Default = getgenv().Settings.Main.AutoStealEgg,
    Callback = function(Value)
        getgenv().Settings.Main.AutoStealEgg = Value
        SaveSetting()

        if not Value then
            -- turned off: hand the character its own Humanoid back so it has animations,
            -- regen and input again. A steal run that swapped it out has no other reason to
            -- put it back once stealing stops.
            task.spawn(Rig.Restore)

            return
        end

        Loop("AutoStealEgg", getgenv().Settings.Main.StealDelay or 0.5, function()
            local Main = getgenv().Settings.Main

            if IsCarrying() then
                if Main.AutoDeliver then
                    StopTreadmill()
                    ReturnToSafe("AutoStealEgg")
                end

                return
            end

            -- Not carrying anything, so there is nothing to rescue: a run started now walks
            -- into the reroll and comes back with nothing, and the wall shuts on the way in.
            -- Farming keeps running through the night; it happens at the base.
            if Night.Now() or Night.PhaseLeft() < Night.Margin then return end

            -- Somebody is walking off with an egg we wanted. That is a chase rather than a
            -- walk, and it comes first: a carried egg is over the line and gone in a matter of
            -- seconds, while the nest egg this pass would otherwise have gone for is still
            -- there on the next one.
            local Thief, Carrier = PickThief()

            if Thief and Carrier then
                if Intercept("AutoStealEgg", Thief, Carrier) and Main.AutoDeliver then
                    ReturnToSafe("AutoStealEgg", Thief.Uid)
                end

                return
            end

            local Record, Position = PickTarget()

            -- Nothing to steal right now. The pass just ends: the walk order is released
            -- on the way out and the Auto Farm Speed loop, which sits below this one, picks
            -- the treadmill up on its own. It used to farm from in here instead, which meant
            -- the treadmill only ever ran on this one branch -- never at night, never while
            -- the daylight was too short, never while this loop was walking.
            if not (Record and Position) then return end

            -- and again now the target is known: the trip out and back, at this character's
            -- own walk speed, has to fit inside the daylight that is left. Prehistoric and
            -- Cosmic are far enough out that a run started late arrives after the reroll.
            local Root = GetRootPart()

            if Root then
                -- What the trip costs at the speed the engine will actually be allowed to move
                -- at. With the Humanoid swapped that is the slider; with the swap turned off it
                -- is this character's WalkSpeed doubled, and a fresh character travelling at 32
                -- studs/s cannot make Cosmic before the reroll -- the estimate has to say so
                -- rather than promise the slider's 300.
                local Speed = math.clamp(tonumber(Main.TweenSpeed) or 300, 1, SpeedRoof())
                local Trip = (Position - Root.Position).Magnitude * 2 / Speed

                if Night.PhaseLeft() < Trip + Night.Margin then return end
            end

            if not StopTreadmill() then return end
            if not Approach(Position, "AutoStealEgg", 120) then return end

            local Carried, Reason = TryCarry(Record, "AutoStealEgg")

            if Carried then
                if Main.AutoDeliver then
                    ReturnToSafe("AutoStealEgg", Record.Uid)
                end

                return
            end

            if Reason == "Your egg inventory is full!" and Main.AutoFarmSpeed and not PlotChoresPending() then
                local Full = UnplacedEggCount()

                FarmSpeed("AutoStealEgg", nil, function()
                    return UnplacedEggCount() < Full
                end)
            end
        end)
    end
})

StealSection:Toggle({
    Name = "Auto Deliver",
    Flag = "STEAutoDeliver",
    Default = getgenv().Settings.Main.AutoDeliver,
    Callback = function(Value)
        getgenv().Settings.Main.AutoDeliver = Value
        SaveSetting()
    end
})

StealSection:Toggle({
    Name = "Chase Egg Thief",
    Flag = "STERecoverStolenEgg",
    Default = getgenv().Settings.Main.RecoverStolenEgg,
    Callback = function(Value)
        getgenv().Settings.Main.RecoverStolenEgg = Value
        SaveSetting()
    end
})

-- The other half of Chase Egg Thief: that one goes after an egg somebody slapped out of our
-- hands, this one goes after an egg that was never in them. Same routine either way -- run
-- them down, swing, pick up what falls -- so it wants a bat in the backpack.
StealSection:Toggle({
    Name = "Steal From Players",
    Flag = "STEStealFromPlayers",
    Default = getgenv().Settings.Main.StealFromPlayers,
    Callback = function(Value)
        getgenv().Settings.Main.StealFromPlayers = Value
        SaveSetting()
    end
})

StealSection:Dropdown({
    Name = "Select Area",
    Flag = "STEStealAreas",
    Items = AreaItems,
    Default = getgenv().Settings.Main.StealAreas,
    Multi = true,
    Callback = function(Value)
        getgenv().Settings.Main.StealAreas = Value
        SaveSetting()
    end
})

local StealRarityDropdown = StealSection:Dropdown({
    Name = "Select Rarity To Steal",
    Flag = "STEStealRarities",
    Items = RarityItems,
    Default = getgenv().Settings.Main.StealRarities,
    Multi = true,
    Callback = function(Value)
        getgenv().Settings.Main.StealRarities = Value
        SaveSetting()
    end
})

StealSection:Dropdown({
    Name = "Pick Egg By",
    Flag = "STEStealPriority",
    Items = { "Rarest", "Nearest", "Largest" },
    Default = getgenv().Settings.Main.StealPriority,
    Multi = false,
    Callback = function(Value)
        getgenv().Settings.Main.StealPriority = Value
        SaveSetting()
    end
})

local Placeholders = { }
local PlaceholderCount = 0
local PlaceholderWatcher = false

-- Holder:GetDescendants() is the whole menu tree. Walking it without a yield is quick
-- enough on a PC and long enough on a phone to stop the client answering, and this ran once
-- a second forever. It now walks in slices, giving the frame back whenever a slice has held
-- it for more than eight milliseconds.
local function ScanPlaceholders()
    local ScanSliceSeconds = 0.008
    local ScanSliceStep = 128

    local Holder = Library.Holder and Library.Holder.Instance

    if not Holder then return end

    local Wanted = { }

    for Name, Entry in pairs(Placeholders) do
        Wanted[Library:Translate(Name)] = { Name = Name, Entry = Entry }
    end

    local Descendants = Holder:GetDescendants()
    local Since = 0
    local SliceStart = os.clock()

    for Index = 1, #Descendants do
        local Title = Descendants[Index]

        Since = Since + 1

        if Since >= ScanSliceStep then
            Since = 0

            if os.clock() - SliceStart > ScanSliceSeconds then
                task.wait()

                SliceStart = os.clock()
            end
        end

        if Title:IsA("TextLabel") then
            local Found = Wanted[Title.Text]

            local Button = Found and Title.Parent and Title.Parent:FindFirstChildWhichIsA("TextButton")
            local Value = Button and Button:FindFirstChildWhichIsA("TextLabel")

            if Value then
                Placeholders[Found.Name] = nil
                PlaceholderCount = PlaceholderCount - 1

                local Element = Found.Entry.Element
                local Placeholder = Found.Entry.Placeholder

                local function Relabel()
                    local Current = Element:Get()
                    local Empty = type(Current) ~= "table" or #Current == 0
                    local Text = Library:Translate(Placeholder)

                    if Empty and Value.Text ~= Text then
                        Value.Text = Text
                    end
                end

                Relabel()

                TrackConnection(Value:GetPropertyChangedSignal("Text"):Connect(Relabel))
            end
        end
    end
end

function ShowTextWhenEmpty(Element, DropdownName, Placeholder)
    if Placeholders[DropdownName] then return end

    Placeholders[DropdownName] = { Element = Element, Placeholder = Placeholder or "..." }
    PlaceholderCount = PlaceholderCount + 1

    if PlaceholderWatcher then return end

    PlaceholderWatcher = true

    task.spawn(function()
        -- a dropdown whose label never turns up is not going to turn up on the hundredth
        -- pass either, so the watcher gives up instead of walking the tree for the rest of
        -- the session
        local Passes = 0

        while PlaceholderCount > 0 and Passes < 20 and getgenv().ValkyrieSession == SessionToken do
            Passes = Passes + 1

            pcall(ScanPlaceholders)

            task.wait(Passes < 5 and 1 or 3)
        end

        PlaceholderWatcher = false
    end)
end

ShowTextWhenEmpty(SellRarityDropdown, "Sell Rarity")
ShowTextWhenEmpty(SellCategoryDropdown, "Sell Brainrot")
ShowTextWhenEmpty(SellEggDropdown, "Sell Egg")
ShowTextWhenEmpty(StealRarityDropdown, "Select Rarity To Steal", AnyDropdownText)

-- Five hundred is what was measured clean with the Humanoid swapped, and the whole of it is
-- available to any character whatever its Speed stat. With the swap turned off the slider is
-- still only an ask: the roof falls back to this character's WalkSpeed doubled.
StealSection:Slider({
    Name = "Tween Speed",
    Flag = "STETweenSpeed",
    Min = 50,
    Max = TravelHardMax,
    Decimals = 10,
    Default = getgenv().Settings.Main.TweenSpeed,
    Suffix = " studs/s",
    Callback = function(Value)
        getgenv().Settings.Main.TweenSpeed = Value
        SaveSetting()
    end
})

StealSection:Slider({
    Name = "Steal Delay",
    Flag = "STEStealDelay",
    Min = 0.1,
    Max = 5,
    Decimals = 0.1,
    Default = getgenv().Settings.Main.StealDelay,
    Suffix = " s",
    Callback = function(Value)
        getgenv().Settings.Main.StealDelay = Value
        SaveSetting()
    end
})

StealSection:Slider({
    Name = "Grab Retry Time",
    Flag = "STECarryRetry",
    Min = 1,
    Max = 8,
    Decimals = 0.5,
    Default = getgenv().Settings.Main.CarryRetry,
    Suffix = " s",
    Callback = function(Value)
        getgenv().Settings.Main.CarryRetry = Value
        SaveSetting()
    end
})

local FuseSection = AutomaticPage:Section({
    Name = "Fuse Machine",
    Description = "Fuse three same brainrots into an egg",
    Icon = Icon("combine", "117851493400222"),
    Side = 2,
    EnableToggle = true
})

function FusePreview()
    local Main = getgenv().Settings.Main

    if #(Main.FuseCategories or { }) == 0 then
        return Library:Translate("Pick a brainrot first")
    end

    local Names = { }
    local Total = 0

    for Name, List in pairs(FuseGroups()) do
        local Fuses = math.floor(#List / 3)

        if Fuses > 0 then
            Total = Total + Fuses
            table.insert(Names, string.format("%s %d", Name, Fuses))
        end
    end

    if Total == 0 then
        return Library:Translate("Not enough to fuse yet")
    end

    table.sort(Names)

    if #Names > 3 then
        Names = { Names[1], Names[2], Names[3], string.format("+%d", #Names - 3) }
    end

    return string.format("%s %d (%s)", Library:Translate("Ready to fuse"), Total, table.concat(Names, ", "))
end

FuseSection:Toggle({
    Name = "Auto Fuse",
    Flag = "STEAutoFuse",
    Default = getgenv().Settings.Main.AutoFuse,
    Callback = function(Value)
        getgenv().Settings.Main.AutoFuse = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoFuse", getgenv().Settings.Main.FuseDelay or 1, function()
            FuseSweep("AutoFuse")
        end)
    end
})

local FuseCategoryDropdown = FuseSection:Dropdown({
    Name = "Fuse Brainrot",
    Flag = "STEFuseCategories",
    Items = CategoryItems,
    Default = getgenv().Settings.Main.FuseCategories,
    Multi = true,
    Callback = function(Value)
        getgenv().Settings.Main.FuseCategories = Value
        SaveSetting()

        pcall(function()
            FuseReadyLabel:SetText(FusePreview())
        end)
    end
})

ShowTextWhenEmpty(FuseCategoryDropdown, "Fuse Brainrot")

FuseSection:Toggle({
    Name = "Skip Mutated",
    Flag = "STEFuseSkipMutated",
    Default = getgenv().Settings.Main.FuseSkipMutated,
    Callback = function(Value)
        getgenv().Settings.Main.FuseSkipMutated = Value
        SaveSetting()

        pcall(function()
            FuseReadyLabel:SetText(FusePreview())
        end)
    end
})

FuseSection:Slider({
    Name = "Fuse Delay",
    Flag = "STEFuseDelay",
    Min = 0.5,
    Max = 10,
    Decimals = 0.5,
    Default = getgenv().Settings.Main.FuseDelay,
    Suffix = " s",
    Callback = function(Value)
        getgenv().Settings.Main.FuseDelay = Value
        SaveSetting()
    end
})

FuseSection:Button({
    Name = "Return Pets",
    Callback = function()
        task.spawn(ReturnFusedPets)
    end
})

do

local CombatSection = AutomaticPage:Section({
    Name = "Combat",
    Description = "Bat the nearest player",
    Icon = Icon("swords", "117851493400222"),
    Side = 1,
    EnableToggle = true
})

-- Renamed from Auto Attack Players; the flag and the settings key are untouched so a config
-- file written by an older build still turns it on.
CombatSection:Toggle({
    Name = "Attack Aura",
    Flag = "STEAutoAttackPlayers",
    Default = getgenv().Settings.Main.AutoAttackPlayers,
    Callback = function(Value)
        getgenv().Settings.Main.AutoAttackPlayers = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoAttackPlayers", getgenv().Settings.Main.AttackDelay or 0.7, AttackSweep)
    end
})

local function PlayerNames()
    local Names = { }

    for _, Other in ipairs(Players:GetPlayers()) do
        if Other ~= LocalPlayer then
            table.insert(Names, Other.Name)
        end
    end

    table.sort(Names)

    return Names
end

local TargetDropdown = CombatSection:Dropdown({
    Name = "Select Player",
    Flag = "STEAttackTarget",
    Items = PlayerNames(),
    Default = getgenv().Settings.Main.AttackTarget,
    Multi = false,
    Callback = function(Value)
        getgenv().Settings.Main.AttackTarget = type(Value) == "string" and Value or ""
        SaveSetting()
    end
})

-- The list belongs to the server, so it changes under the box: a name left in it after that
-- player has gone is a button that walks somewhere and swings at nobody. The current pick is
-- kept when it is still a player on this server and cleared when it is not.
local function RefreshTargets()
    local Chosen = getgenv().Settings.Main.AttackTarget

    if type(Chosen) ~= "string" or Chosen == "" or Players:FindFirstChild(Chosen) == nil then
        Chosen = nil

        -- Refresh only clears what the box is showing. The saved name has to go with it or a
        -- player who left is still what the button reads, and it would walk to the notification
        -- rather than to anybody.
        if getgenv().Settings.Main.AttackTarget ~= "" then
            getgenv().Settings.Main.AttackTarget = ""
            SaveSetting()
        end
    end

    pcall(function()
        TargetDropdown:Refresh(PlayerNames(), Chosen)
    end)
end

TrackConnection(Players.PlayerAdded:Connect(RefreshTargets))

-- PlayerRemoving fires while they are still in Players:GetPlayers(), so the rebuild waits a
-- frame or the name it just dropped goes straight back into the list
TrackConnection(Players.PlayerRemoving:Connect(function()
    task.defer(RefreshTargets)
end))

-- Held rather than fired: while it is on the character follows the one name in the box and
-- swings on the bat's cooldown, and it outranks every automatic loop so nothing walks off
-- mid-chase. A quarter of a second between passes, because each pass runs for twenty seconds
-- of its own and this only decides whether there is another one.
CombatSection:Toggle({
    Name = "Attack Player",
    Flag = "STEAttackPlayer",
    Default = getgenv().Settings.Main.AttackPlayer,
    Callback = function(Value)
        getgenv().Settings.Main.AttackPlayer = Value
        SaveSetting()

        if not Value then
            -- the chase swaps the Humanoid for the travel speed roof; hand the real one back
            -- on the way out so the character has its animations, regen and input again, the
            -- same as the Auto Steal Egg toggle does
            task.spawn(Rig.Restore)

            return
        end

        if type(getgenv().Settings.Main.AttackTarget) ~= "string"
            or getgenv().Settings.Main.AttackTarget == ""
        then
            Library:Notification({
                Title = "Combat",
                Description = Library:Translate("Pick a player first"),
                Duration = 4,
                Icon = IconValkyrie
            })
        end

        Loop("AttackPlayer", 0.25, function()
            Harass("AttackPlayer")
        end)
    end
})

CombatSection:Slider({
    Name = "Attack Range",
    Flag = "STEAttackRange",
    Min = 5,
    Max = 50,
    Decimals = 5,
    Default = getgenv().Settings.Main.AttackRange,
    Suffix = " studs",
    Callback = function(Value)
        getgenv().Settings.Main.AttackRange = Value
        SaveSetting()
    end
})

CombatSection:Slider({
    Name = "Attack Delay",
    Flag = "STEAttackDelay",
    Min = 0.7,
    Max = 5,
    Decimals = 0.1,
    Default = getgenv().Settings.Main.AttackDelay,
    Suffix = " s",
    Callback = function(Value)
        getgenv().Settings.Main.AttackDelay = Value
        SaveSetting()
    end
})

end

do

-- The whole event behind one master toggle with its two halves under it: feeding is the only
-- thing that moves the charge, the chest is what the charge was for, and both of them want the
-- character standing in the same spot on our own plot. One loop, chest first.
local MonsterSection = AutomaticPage:Section({
    Name = "Monster Parasite",
    Description = "Feed infested eggs to the Hungry Monster",
    Icon = Icon("bug", "117851493400222"),
    Side = 2,
    EnableToggle = true
})

local MonsterLabel = MonsterSection:Label("Monster Parasite")

task.spawn(function()
    while getgenv().ValkyrieSession == SessionToken do
        pcall(function()
            MonsterLabel:SetText(Parasite.Status(function(Text)
                return Library:Translate(Text)
            end))
        end)

        task.wait(1)
    end
end)

MonsterSection:Toggle({
    Name = "Auto Monster Parasite",
    Flag = "STEAutoMonsterParasite",
    Default = getgenv().Settings.Main.AutoMonsterParasite,
    Callback = function(Value)
        getgenv().Settings.Main.AutoMonsterParasite = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoMonsterParasite", 2, function()
            local Main = getgenv().Settings.Main

            -- the chest first: on a full charge every feed is refused, so claiming is what
            -- makes room for the rest of the bag
            if Main.ParasiteChest == true then
                Parasite.Chest("AutoMonsterParasite")
            end

            if Main.ParasiteFeed == true then
                Parasite.Feed("AutoMonsterParasite")
            end
        end)
    end
})

MonsterSection:Toggle({
    Name = "Auto Feed Infested Eggs",
    Flag = "STEParasiteFeed",
    Default = getgenv().Settings.Main.ParasiteFeed,
    Callback = function(Value)
        getgenv().Settings.Main.ParasiteFeed = Value
        SaveSetting()
    end
})

MonsterSection:Toggle({
    Name = "Auto Claim Monster Chest",
    Flag = "STEParasiteChest",
    Default = getgenv().Settings.Main.ParasiteChest,
    Callback = function(Value)
        getgenv().Settings.Main.ParasiteChest = Value
        SaveSetting()
    end
})

MonsterSection:Toggle({
    Name = "Feed Mutated Eggs",
    Flag = "STEParasiteFeedMutated",
    Default = getgenv().Settings.Main.ParasiteFeedMutated,
    Callback = function(Value)
        getgenv().Settings.Main.ParasiteFeedMutated = Value
        SaveSetting()
    end
})

MonsterSection:Toggle({
    Name = "Steal Infested Eggs First",
    Flag = "STEParasiteSteal",
    Default = getgenv().Settings.Main.ParasiteSteal,
    Callback = function(Value)
        getgenv().Settings.Main.ParasiteSteal = Value
        SaveSetting()
    end
})

MonsterSection:Button({
    Name = "Feed The Monster Now",
    Callback = function()
        RunManual(function(Key)
            Parasite.Chest(Key)
            Parasite.Feed(Key)
        end)
    end
})

end

end

---- ============ Plot ============ ----

do

local Syncing = false

function SyncAutoBuyPen(Value, OtherFlag)
    getgenv().Settings.Main.AutoBuyPen = Value
    SaveSetting()

    if not Syncing then
        local Setter = Library.SetFlags[OtherFlag]

        if Setter then
            Syncing = true
            pcall(Setter, Value)
            Syncing = false
        end
    end

    if not Value then return end

    Loop("AutoBuyPen", 5, BuyPen)
end

end

do

local PlotPage = Window:Page({ Name = "Plot", Icon = Icon("house", "80451686744860"), Columns = 2 })

local EggSection = PlotPage:Section({
    Name = "Egg",
    Description = "Place and hatch eggs on your plot",
    Icon = Icon("egg", "117851493400222"),
    Side = 1,
    EnableToggle = true
})

EggSection:Toggle({
    Name = "Auto Place Egg",
    Flag = "STEAutoPlaceEgg",
    Default = getgenv().Settings.Main.AutoPlaceEgg,
    Callback = function(Value)
        getgenv().Settings.Main.AutoPlaceEgg = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoPlaceEgg", getgenv().Settings.Main.PlotDelay or 2, function()
            PlaceSweep("AutoPlaceEgg")
        end)
    end
})

EggSection:Toggle({
    Name = "Auto Open Egg",
    Flag = "STEAutoOpenEgg",
    Default = getgenv().Settings.Main.AutoOpenEgg,
    Callback = function(Value)
        getgenv().Settings.Main.AutoOpenEgg = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoOpenEgg", getgenv().Settings.Main.PlotDelay or 2, function()
            OpenSweep("AutoOpenEgg")
        end)
    end
})

local PlaceEggDropdown = EggSection:Dropdown({
    Name = "Select Egg To Place",
    Flag = "STEPlaceEggs",
    Items = EggItems,
    Default = getgenv().Settings.Main.PlaceEggs,
    Multi = true,
    Callback = function(Value)
        getgenv().Settings.Main.PlaceEggs = Value
        SaveSetting()
    end
})

local PlaceRarityDropdown = EggSection:Dropdown({
    Name = "Select Rarity To Place",
    Flag = "STEPlaceRarities",
    Items = RarityItems,
    Default = getgenv().Settings.Main.PlaceRarities,
    Multi = true,
    Callback = function(Value)
        getgenv().Settings.Main.PlaceRarities = Value
        SaveSetting()
    end
})

ShowTextWhenEmpty(PlaceEggDropdown, "Select Egg To Place", AnyDropdownText)
ShowTextWhenEmpty(PlaceRarityDropdown, "Select Rarity To Place", AnyDropdownText)

EggSection:Slider({
    Name = "Plot Delay",
    Flag = "STEPlotDelay",
    Min = 0.5,
    Max = 10,
    Decimals = 0.5,
    Default = getgenv().Settings.Main.PlotDelay,
    Suffix = " s",
    Callback = function(Value)
        getgenv().Settings.Main.PlotDelay = Value
        SaveSetting()
    end
})

EggSection:Button({
    Name = "Place All Now",
    Callback = function()
        RunManual(PlaceSweep)
    end
})

EggSection:Button({
    Name = "Hatch All Ready Now",
    Callback = function()
        task.spawn(OpenSweep)
    end
})

local PetSection = PlotPage:Section({
    Name = "Pet",
    Description = "Fill the pen with your best brainrots",
    Icon = Icon("paw-print", "117851493400222"),
    Side = 2,
    EnableToggle = true
})

PetSection:Toggle({
    Name = "Auto Equip Best",
    Flag = "STEAutoEquipBest",
    Default = getgenv().Settings.Main.AutoEquipBest,
    Callback = function(Value)
        getgenv().Settings.Main.AutoEquipBest = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoEquipBest", getgenv().Settings.Main.EquipDelay or 5, EquipBest)
    end
})

PetSection:Toggle({
    Name = "Auto Favorite Equipped",
    Flag = "STEAutoFavoriteEquipped",
    Default = getgenv().Settings.Main.AutoFavoriteEquipped,
    Callback = function(Value)
        getgenv().Settings.Main.AutoFavoriteEquipped = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoFavoriteEquipped", 5, FavoriteEquipped)
    end
})

PetSection:Toggle({
    Name = "Auto Buy +1 Equip",
    Flag = "STEAutoBuyEquip",
    Default = getgenv().Settings.Main.AutoBuyPen,
    Callback = function(Value)
        SyncAutoBuyPen(Value, "STEAutoBuyPen")
    end
})

PetSection:Slider({
    Name = "Equip Delay",
    Flag = "STEEquipDelay",
    Min = 1,
    Max = 30,
    Decimals = 1,
    Default = getgenv().Settings.Main.EquipDelay,
    Suffix = " s",
    Callback = function(Value)
        getgenv().Settings.Main.EquipDelay = Value
        SaveSetting()
    end
})

PetSection:Button({
    Name = "Equip Best Now",
    Callback = function()
        task.spawn(EquipBest)
    end
})

PetSection:Button({
    Name = "Unequip All",
    Callback = function()
        task.spawn(UnequipAll)
    end
})

end

---- ============ Visual ============ ----

do

local VisualPage = Window:Page({ Name = "Visual", Icon = Icon("eye", "80451686744860"), Columns = 2 })

local EspSection = VisualPage:Section({
    Name = "ESP",
    Description = "See eggs, pets, traps and monsters through the map",
    Icon = Icon("scan-eye", "117851493400222"),
    Side = 1,
    EnableToggle = true
})

-- Settings has to survive a JSON round trip and Color3 does not, so what is saved is the hex
-- string the library hands back and what the picker is built with is that string turned back
-- into a colour. A file written by an older build has no string at all, hence the fallback.
local function Saved(Key, Fallback)
    local Hex = getgenv().Settings.Main[Key]

    if type(Hex) == "string" and Hex ~= "" then
        local Ok, Colour = pcall(Color3.fromHex, Hex)

        if Ok then return Colour end
    end

    return Fallback
end

local function EspToggle(Name, Flag, Key, ColorKey, Fallback)
    local Toggle = EspSection:Toggle({
        Name = Name,
        Flag = Flag,
        Default = getgenv().Settings.Main[Key],
        Callback = function(Value)
            getgenv().Settings.Main[Key] = Value
            SaveSetting()

            if not Value then
                pcall(Visual.Refresh)
            end
        end
    })

    Toggle:SubColorpicker({
        Flag = Flag .. "Color",
        Default = Saved(ColorKey, Fallback),
        Callback = function(Value)
            if typeof(Value) ~= "Color3" then return end

            getgenv().Settings.Main[ColorKey] = Value:ToHex()
            SaveSetting()
        end
    })

    return Toggle
end

EspToggle("ESP Area Eggs", "STEEspAreaEggs", "EspAreaEggs", "EspAreaEggColor", Color3.fromRGB(255, 209, 102))
EspToggle("ESP Pen Eggs", "STEEspPenEggs", "EspPenEggs", "EspPenEggColor", Color3.fromRGB(110, 231, 255))
EspToggle("ESP Pen Pets", "STEEspPenPets", "EspPenPets", "EspPenPetColor", Color3.fromRGB(176, 108, 255))
EspToggle("ESP Traps", "STEEspTraps", "EspTraps", "EspTrapColor", Color3.fromRGB(255, 59, 59))
EspToggle("ESP Monsters", "STEEspMonsters", "EspMonsters", "EspMonsterColor", Color3.fromRGB(255, 84, 112))

local RangeSection = VisualPage:Section({
    Name = "ESP Range",
    Description = "How much of it is drawn",
    Icon = Icon("ruler", "117851493400222"),
    Side = 2
})

RangeSection:Slider({
    Name = "ESP Distance",
    Flag = "STEEspMaxDistance",
    Min = 100,
    Max = 4000,
    Decimals = 50,
    Default = getgenv().Settings.Main.EspMaxDistance,
    Suffix = " studs",
    Callback = function(Value)
        getgenv().Settings.Main.EspMaxDistance = Value
        SaveSetting()
    end
})

-- Thirty is the engine's own limit, not a taste: Roblox draws thirty-one Highlights and
-- silently ignores every one after that, so a higher number here would only mean the nearest
-- thirty drawn and the rest counted.
RangeSection:Slider({
    Name = "ESP Max Shown",
    Flag = "STEEspLimit",
    Min = 5,
    Max = 30,
    Decimals = 1,
    Default = getgenv().Settings.Main.EspLimit,
    Suffix = "",
    Callback = function(Value)
        getgenv().Settings.Main.EspLimit = Value
        SaveSetting()
    end
})

RangeSection:Label("Monsters show rarity, walk speed and hit range")

-- The price the seller NPC would pay, printed in the corner of the game's own backpack slots
-- rather than in a window of ours -- which is where the player is already looking when the
-- question comes up.
local InventorySection = VisualPage:Section({
    Name = "Inventory ESP",
    Description = "Price tag on every backpack slot",
    Icon = Icon("wallet", "117851493400222"),
    Side = 2,
    EnableToggle = true
})

local InventoryLabel = InventorySection:Label("Bag: $0")

InventorySection:Toggle({
    Name = "Show Inventory $/s",
    Flag = "STEInventoryValue",
    Default = getgenv().Settings.Main.InventoryValue,
    Callback = function(Value)
        getgenv().Settings.Main.InventoryValue = Value
        SaveSetting()

        pcall(Inventory.Refresh)
    end
})

InventorySection:Toggle({
    Name = "Include Eggs",
    Flag = "STEInventoryValueEggs",
    Default = getgenv().Settings.Main.InventoryValueEggs,
    Callback = function(Value)
        getgenv().Settings.Main.InventoryValueEggs = Value
        SaveSetting()
    end
})

-- greyed out is a pet the seller will not take: equipped, favourited, or sitting in the fuse
-- machine. Those are tagged but left out of the total, because the total is what a Sell All
-- would actually pay.
InventorySection:Label("Grey = can't sell (equipped / favorite / in fuse)")

-- The total is worked out by the refresh pass anyway, so this only prints what is already
-- there. Once a second, on its own thread, because the pass runs twice as often as that and
-- a label redrawn on every one of them is redraws nobody asked for.
task.spawn(function()
    while getgenv().ValkyrieSession == SessionToken do
        pcall(function()
            InventoryLabel:SetText(string.format(
                "%s $%s   (%d)   $%s/s",
                Library:Translate("Bag:"),
                FormatSpeed(Inventory.Total),
                Inventory.Count,
                FormatSpeed(Inventory.Rate)
            ))
        end)

        task.wait(1)
    end
end)

end

---- ============ Misc ============ ----

do

local MiscPage = Window:Page({ Name = "Misc", Icon = Icon("ellipsis", "80451686744860"), Columns = 2 })

local PlayerSection = MiscPage:Section({
    Name = "Player",
    Description = "Index rewards, rebirth and the pen",
    Icon = Icon("user", "117851493400222"),
    Side = 1,
    EnableToggle = true
})

PlayerSection:Toggle({
    Name = "Auto Claim Index",
    Flag = "STEAutoClaimIndex",
    Default = getgenv().Settings.Main.AutoClaimIndex,
    Callback = function(Value)
        getgenv().Settings.Main.AutoClaimIndex = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoClaimIndex", 10, ClaimIndex)
    end
})

PlayerSection:Toggle({
    Name = "Auto Rebirth",
    Flag = "STEAutoRebirth",
    Default = getgenv().Settings.Main.AutoRebirth,
    Callback = function(Value)
        getgenv().Settings.Main.AutoRebirth = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoRebirth", 10, DoRebirth)
    end
})

PlayerSection:Toggle({
    Name = "Auto Upgrade Pen",
    Flag = "STEAutoBuyPen",
    Default = getgenv().Settings.Main.AutoBuyPen,
    Callback = function(Value)
        SyncAutoBuyPen(Value, "STEAutoBuyEquip")
    end
})

PlayerSection:Toggle({
    Name = "Delete Pet in Pen",
    Flag = "STEHidePenPets",
    Default = getgenv().Settings.Main.HidePenPets,
    Callback = function(Value)
        getgenv().Settings.Main.HidePenPets = Value
        SaveSetting()

        pcall(Visual.HidePets, Value)
    end
})

local ShopSection = MiscPage:Section({
    Name = "Shop",
    Description = "Buy trails with money",
    Icon = Icon("shopping-cart", "117851493400222"),
    Side = 2,
    EnableToggle = true
})

local TrailDropdown = ShopSection:Dropdown({
    Name = "Select Trails",
    Flag = "STEBuyTrails",
    Items = TrailItems,
    Default = getgenv().Settings.Main.BuyTrails,
    Multi = true,
    Callback = function(Value)
        getgenv().Settings.Main.BuyTrails = Value
        SaveSetting()
    end
})

ShowTextWhenEmpty(TrailDropdown, "Select Trails")

ShopSection:Toggle({
    Name = "Auto Buy Trails",
    Flag = "STEAutoBuyTrails",
    Default = getgenv().Settings.Main.AutoBuyTrails,
    Callback = function(Value)
        getgenv().Settings.Main.AutoBuyTrails = Value
        SaveSetting()

        if not Value then return end

        Loop("AutoBuyTrails", 5, BuyTrails)
    end
})

end

---- ============ Boot ============ ----

task.spawn(function()
    while getgenv().ValkyrieSession == SessionToken do
        local Target = TargetSpeed()
        local Text = "Speed: " .. FormatSpeed(GetSpeedPower())

        if Target > 0 then
            Text = Text .. " / " .. FormatSpeed(Target)
        end

        pcall(function()
            SpeedLabel:SetText(Text)
            FuseReadyLabel:SetText(FusePreview())
        end)

        task.wait(1)
    end
end)

getgenv().ValkyrieAPI = {
    Window = Window,
    Library = Library,
}

---- ============ Configuration ============ ----

do

local ConfigPage = Window:Page({ Name = "Configuration", Icon = Icon("settings", "80758916183665"), Columns = 2 })

local InterfaceSection = ConfigPage:Section({
    Name = "Interface",
    Description = "Window and executor options",
    Icon = Icon("app-window", "93142176757189"),
    Side = 1
})

InterfaceSection:Toggle({
    Name = "Window Transparency",
    Flag = "GFCTransparent",
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

local AntiAfkConnection = nil
local AntiAfkThread = nil

-- this used to be VirtualUser:CaptureController() plus a synthetic right click on Idled. The
-- game runs its own AFK reporting (Analytics:ReportAfkState) next to the character integrity
-- heartbeat, and a session whose only sign of life is a click at the idle threshold, with the
-- character never leaving the spot it stood on, reads as AFK farming and ends in a kick. The
-- character takes a short walk instead: a MoveTo out and a MoveTo back, the same primitive the
-- farm loops use, replicated exactly like a player walking.
local function AntiAfkStep()
    if not Alive() then return end

    local Humanoid = GetHumanoid()
    local Root = GetRootPart()

    if not (Humanoid and Root) then return end

    -- a farm task already has the humanoid walking somewhere; stepping now would fight it
    if Humanoid.MoveDirection.Magnitude > 0.1 then return end

    local Origin = Root.Position
    local Angle = math.random() * math.pi * 2
    local Target = Origin + Vector3.new(math.cos(Angle), 0, math.sin(Angle)) * 4

    Humanoid:MoveTo(Target)
    task.wait(0.6)

    if not Alive() then return end

    -- back to where the step started, so a farm loop finds the character where it left it
    GetHumanoid():MoveTo(Origin)
    task.wait(0.6)
end

InterfaceSection:Toggle({
    Name = "Anti-AFK",
    Flag = "GFCAntiAFK",
    Default = getgenv().ConfigurationTable.AntiAFK,
    Callback = function(Value)
        getgenv().ConfigurationTable.AntiAFK = Value
        SaveConfiguration()

        if Value then
            if AntiAfkConnection then return end

            AntiAfkConnection = TrackConnection(LocalPlayer.Idled:Connect(function()
                pcall(AntiAfkStep)
            end))

            -- Idled only fires at the 20 minute mark. The character moves well before that so
            -- the server never sees a long stretch of a player standing perfectly still.
            AntiAfkThread = task.spawn(function()
                while getgenv().ValkyrieSession == SessionToken and getgenv().ConfigurationTable.AntiAFK do
                    task.wait(math.random(90, 150))

                    if not (getgenv().ValkyrieSession == SessionToken and getgenv().ConfigurationTable.AntiAFK) then break end

                    pcall(AntiAfkStep)
                end

                AntiAfkThread = nil
            end)
        elseif AntiAfkConnection then
            AntiAfkConnection:Disconnect()
            AntiAfkConnection = nil
            AntiAfkThread = nil
        end
    end
})

local AutoRejoinConnection = nil

InterfaceSection:Toggle({
    Name = "Auto Rejoin",
    Flag = "GFCAutoRejoin",
    Default = getgenv().ConfigurationTable.AutoRejoin,
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoRejoin = Value
        SaveConfiguration()

        if Value then
            if AutoRejoinConnection then return end

            AutoRejoinConnection = TrackConnection(game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
                if child.Name ~= "ErrorPrompt" then return end

                -- Why the client is going away, written down before it goes. This prompt is
                -- the only place the reason exists: a server Kick puts its own message in it,
                -- a dropped connection puts a Roblox error code in it instead, and from the
                -- outside the two are identical -- an ErrorPrompt followed by a rejoin. The
                -- labels are not parented yet on the frame the prompt is added, hence the wait.
                task.wait(0.4)

                local Lines = { }

                for _, Label in ipairs(child:GetDescendants()) do
                    if Label:IsA("TextLabel") and #Label.Text > 0 then
                        table.insert(Lines, Label.Text)
                    end
                end

                local Reason = #Lines > 0 and table.concat(Lines, " | ") or "no text on the prompt"

                warn("[ValkyrieHub] disconnected: " .. Reason)

                -- to a file as well, because the warn goes with the client that printed it
                pcall(function()
                    if not (writefile and isfile and makefolder and isfolder) then return end

                    if not isfolder(File.Folder) then makefolder(File.Folder) end
                    if not isfolder(File.Settings) then makefolder(File.Settings) end

                    local Path = File.Settings .. "/Disconnects.txt"
                    local Line = os.date("%Y-%m-%d %H:%M:%S") .. "  " .. Reason .. "\n"

                    if isfile(Path) and appendfile then
                        appendfile(Path, Line)
                    else
                        writefile(Path, (isfile(Path) and readfile(Path) or "") .. Line)
                    end
                end)

                game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
            end))
        elseif AutoRejoinConnection then
            AutoRejoinConnection:Disconnect()
            AutoRejoinConnection = nil
        end
    end
})

InterfaceSection:Toggle({
    Name = "Auto Executor",
    Flag = "GFCAutoExecutor",
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
    Flag = "GFCMinimizeBind",
    Default = KeyFromName(getgenv().ConfigurationTable.MinimizeBind),
    Mode = "Toggle",
    ShowModes = false,
    Callback = function()
        local Data = Library.Flags["GFCMinimizeBind"]
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

local WhiteScreenGui = nil

local FPSSection = ConfigPage:Section({
    Name = "FPS",
    Description = "Framerate and screen",
    Icon = Icon("monitor", "110273524101447"),
    Side = 2
})

FPSSection:Slider({
    Name = "FPS Value",
    Flag = "GFCFPSValue",
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
    Flag = "GFCFPSLock",
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

FPSSection:Toggle({
    Name = "White Screen",
    Flag = "GFCWhiteScreen",
    Default = getgenv().ConfigurationTable.WhileScreen,
    Callback = function(Value)
        getgenv().ConfigurationTable.WhileScreen = Value
        SaveConfiguration()

        -- this used to sit in PlayerGui under the name "Valkyrie_White". Any LocalScript the
        -- game runs can walk PlayerGui and read the names in it, so that was a plain label
        -- saying which hub is loaded. It goes wherever the executor hides things instead,
        -- under a name that means nothing, and the handle is kept here rather than looked
        -- up by name.
        if Value then
            if not WhiteScreenGui then
                local Parent = LocalPlayer:FindFirstChildOfClass("PlayerGui")

                if gethui then
                    local Ok, Hidden = pcall(gethui)

                    if Ok and typeof(Hidden) == "Instance" then
                        Parent = Hidden
                    end
                end

                local Name = tostring(math.random(1e11, 1e12 - 1))

                WhiteScreenGui = Instance.new("ScreenGui")
                WhiteScreenGui.Name = Name
                WhiteScreenGui.Enabled = true
                WhiteScreenGui.IgnoreGuiInset = true
                WhiteScreenGui.ResetOnSpawn = false
                WhiteScreenGui.DisplayOrder = 1
                WhiteScreenGui.Parent = Parent

                if protect_gui then
                    pcall(protect_gui, WhiteScreenGui)
                end

                local Frame = Instance.new("Frame")
                Frame.Name = Name
                Frame.Position = UDim2.new(0, 0, 0, 0)
                Frame.Size = UDim2.new(1, 0, 1, 0)
                Frame.BorderSizePixel = 0
                Frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Frame.Parent = WhiteScreenGui
            else
                WhiteScreenGui.Enabled = true
            end
        elseif WhiteScreenGui then
            WhiteScreenGui.Enabled = false
        end
    end
})

local LanguageSection = ConfigPage:Section({
    Name = "Language",
    Icon = Icon("languages", "90816903776498"),
    Side = 2
})

LanguageSection:Dropdown({
    Name = "Select Language",
    Flag = "GFCLanguage",
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

end

local queueteleport = queue_on_teleport
local TeleportCheck = false

while not Players.LocalPlayer do task.wait() end

-- ============ Teleport diagnostics ============
--
-- Nothing in this file teleports except Auto Rejoin, and that only fires on an ErrorPrompt.
-- A session that moves anyway, with Auto Rejoin off, is being moved by the game -- and the
-- game has the endpoints for it: Constants.NETWORK_MAP.Analytics holds REPORT_AFK_STATE,
-- REPORT_AFK_TELEPORT and REQUEST_AFK_TELEPORT_FLUSH.
--
-- Which is why this writes down the state at the moment of the teleport rather than guessing
-- from the outside. The character walking is not the question: the render step moves the root
-- part directly, so the character can cross the whole map without the client ever producing an
-- input event, and an AFK check that reads input rather than position sees a player who has
-- not touched anything since the script started. That gap is what the file measures.
local TeleportLog = { }

do
    local UserInputService = game:GetService("UserInputService")

    TeleportLog.LastInput = os.clock()
    TeleportLog.Inputs = 0
    TeleportLog.IdledAt = nil
    TeleportLog.Idles = 0
    TeleportLog.StartedAt = os.clock()

    local function Touched()
        TeleportLog.LastInput = os.clock()
        TeleportLog.Inputs = TeleportLog.Inputs + 1
    end

    TrackConnection(UserInputService.InputBegan:Connect(Touched))
    TrackConnection(UserInputService.LastInputTypeChanged:Connect(Touched))

    TrackConnection(LocalPlayer.Idled:Connect(function()
        TeleportLog.IdledAt = os.clock()
        TeleportLog.Idles = TeleportLog.Idles + 1
    end))

    -- the game's own AFK channel, if it is on this server. Seeing one of these fire is the
    -- difference between a guess and an answer.
    for _, Name in ipairs({
        "RE/Telemetry/SubmitIdleState",
        "RF/Telemetry/SubmitIdleHop",
        "RF/Telemetry/AskIdleHopFlush",
    }) do
        local Remote = NetworkFolder:FindFirstChild(Name)

        if Remote and Remote:IsA("RemoteEvent") then
            TrackConnection(Remote.OnClientEvent:Connect(function(...)
                TeleportLog.Afk = Name .. " at " .. string.format("%.0f", os.clock() - TeleportLog.StartedAt) .. "s"

                warn("[ValkyrieHub] " .. TeleportLog.Afk)
            end))
        end
    end

    -- The last forty remotes the client sent, kept in a ring and dumped with the teleport line.
    -- A server that reaches for TeleportService reached for it because of something, and the
    -- something is either a report this client sent or the last request it made before the
    -- server stopped agreeing with it.
    --
    -- Off unless getgenv().ValkyrieTrace = true is set before executing, because this is a
    -- __namecall hook on every call the client makes: it costs a little on all of them, and a
    -- hooked namecall is exactly the shape an anti-cheat looks for. It is a switch for a
    -- diagnostic run, not something to leave on.
    local Ring, RingAt, RingSize = { }, 0, 40

    if getgenv().ValkyrieTrace == true and hookmetamethod and getnamecallmethod and newcclosure then
        local Old

        Old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local Method = getnamecallmethod()

            if Method == "FireServer" or Method == "InvokeServer" then
                pcall(function()
                    RingAt = RingAt % RingSize + 1
                    Ring[RingAt] = string.format(
                        "%.1fs %s:%s",
                        os.clock() - TeleportLog.StartedAt,
                        tostring(self.Name),
                        Method
                    )
                end)
            end

            return Old(self, ...)
        end))
    end

    local function RingText()
        if RingAt == 0 then return "" end

        local Ordered = { }

        for Step = 1, RingSize do
            local Entry = Ring[(RingAt + Step - 1) % RingSize + 1]

            if Entry then
                table.insert(Ordered, Entry)
            end
        end

        return "\n    last remotes: " .. table.concat(Ordered, ", ")
    end

    -- Anything else loaded into this client that could be the one teleporting. Every hub keeps
    -- its state on getgenv, so a name that is not ours and reads like a hub or a server hopper
    -- is the difference between "the server moved us" and "the other script running next to
    -- this one moved us", which the teleport state alone does not settle.
    local function Neighbours()
        local Found = { }

        local Ok = pcall(function()
            for Key in pairs(getgenv()) do
                local Name = tostring(Key)

                if not Name:find("Valkyrie") and (
                    Name:find("Ouro") or Name:find("Hub") or Name:find("Hop")
                    or Name:find("Crazy") or Name:find("Steal") or Name:find("Settings")
                ) then
                    table.insert(Found, Name)
                end
            end
        end)

        if not Ok then return "?" end

        table.sort(Found)

        return #Found > 0 and table.concat(Found, ",") or "none"
    end

    function TeleportLog.Write(Header)
        local Root = GetRootPart()

        -- place and job go on every line so two consecutive lines say whether the server put
        -- this client somewhere else or handed it back to the same experience on a new server
        local Text = string.format(
            "%s  %s | uptime %.0fs | last input %.0fs ago (%d seen) | idled %d%s | afk %s | blocked %s | others %s | pos %s | place %d job %s",
            os.date("%Y-%m-%d %H:%M:%S"),
            Header,
            os.clock() - TeleportLog.StartedAt,
            os.clock() - TeleportLog.LastInput,
            TeleportLog.Inputs,
            TeleportLog.Idles,
            TeleportLog.IdledAt and string.format(" (last %.0fs ago)", os.clock() - TeleportLog.IdledAt) or "",
            tostring(TeleportLog.Afk or "none"),
            tostring(Relocate.Blocking()),
            Neighbours(),
            Root and tostring(Root.Position) or "no root",
            game.PlaceId,
            tostring(game.JobId)
        ) .. RingText()

        warn("[ValkyrieHub] " .. Text)

        pcall(function()
            if not (writefile and isfile and makefolder and isfolder) then return end

            if not isfolder(File.Folder) then makefolder(File.Folder) end
            if not isfolder(File.Settings) then makefolder(File.Settings) end

            local Path = File.Settings .. "/Disconnects.txt"

            if isfile(Path) and appendfile then
                appendfile(Path, Text .. "\n")
            else
                writefile(Path, (isfile(Path) and readfile(Path) or "") .. Text .. "\n")
            end
        end)
    end
end

-- one line per execute, so the file reads as a session log rather than a pile of teleports:
-- the LOAD line after a TELEPORT line is where the client came back, and its place and job
-- say whether the server sent it somewhere else or to a fresh server of the same experience
pcall(TeleportLog.Write, "LOAD")

LocalPlayer.OnTeleport:Connect(function(State)
    pcall(TeleportLog.Write, "TELEPORT state=" .. tostring(State))

    pcall(function()
        if getgenv().ConfigurationTable and getgenv().ConfigurationTable.AutoExecutor and (not TeleportCheck) and queueteleport then
            TeleportCheck = true

            queueteleport(string.format(
                "getgenv().%s = true\nloadstring(game:HttpGet(%q))()",
                Boot.FastLoadKey,
                Boot.Loader
            ))
        end
    end)
end)

Window:Init()

---- ============ Cleanup ============ ----
getgenv().ValkyrieCleanup = function()
    getgenv().ValkyrieSession = nil

    for _, Connection in ipairs(SessionConnections) do
        pcall(function()
            Connection:Disconnect()
        end)
    end

    table.clear(SessionConnections)

    -- unbind the travel render step and give the character its collisions back, otherwise a
    -- re-execute leaves it noclipped with no platform under it
    pcall(Travel.Cancel)
    pcall(Travel.Stop)

    -- the ESP holder and every pet parked out of Workspace. The pets especially: a re-execute
    -- that left them parked would leave the plot empty with nothing left running to put them
    -- back, and only a rejoin would fix it.
    pcall(Visual.Clear)
    pcall(Visual.HidePets, false)

    -- the value panel lives in the executor's hidden container, which a re-execute does not
    -- clear, so a second copy would stack on top of the first
    pcall(Inventory.Clear)

    -- hand the corrector back, otherwise a re-execute leaves the client ignoring the server and
    -- the watchdog kills the character three seconds later. Not the tick's release: cleanup runs
    -- the instant a re-execute starts, which is very often mid-pulse.
    pcall(Relocate.SafeRelease)

    -- and the swapped Humanoid, so a re-execute or a plain unload leaves the character with
    -- its animations, regen and input back rather than mute and T-posing
    pcall(Rig.Restore)

    pcall(StopTreadmill)

    pcall(function()
        Library:Unload()
    end)

    getgenv().ValkyrieCleanup = nil
end

Library:Notification({
    Title = "Script | Loader",
    Description = "Script Loaded Successfully",
    Duration = 5,
    Icon = IconValkyrie
})