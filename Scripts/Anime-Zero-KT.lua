--[[
    Valkyrie Hub // Anime Zero -- KAITAN EDITION (Anime-Zero-KT)

    Anime-Zero.lua is the menu build. This file is the unattended run: no menu,
    only a status panel. A fresh account is taken from nothing to end game, and
    the only thing a customer sets is which character they want in each slot.

    THE RUN
      Lobby (every visit)
        codes (once, remembered on disk) -> daily / quests / achievements /
        level road -> raid units waiting in storage go into their slot ->
        Lucky Spin the starter -> skill tree -> buy / convert materials ->
        evolve (+ Shadow Monarch stages, Igris) -> equip the two best -> join
      Match
        orbit the target (Height 5, Radius 8, Speed 10), minions before the
        boss, break walls, raid mechanics. On the result screen go back to the
        lobby when there is something to spend, else Next / Retry.

    SLOT TARGETS
      The four targets are a set: one is met when ANY slot holds a fitting
      character (Cursed King in slot 3 meets the slot 1 target). New units go
      into a slot no target uses. A target lists alternatives with "|". Each alternative is a character
      (display name "Cursed King" or id "sukuna") or a rarity ("Mythic" =
      Mythic or better). Where it comes from is worked out per alternative:
        rolled character / rarity  -> Lucky Spin into that slot
        raid unit (Sung Jinwoo, Hu Tao) -> farm its raid, then placeStoredUnit
      Default slot 1 "Cursed King": Lucky Spin until it lands. Out of spins ->
      farm (every gem goes to Lucky Spins meanwhile) -> back to spin again. Then
      grow it and farm Shadow Gate for Jinwoo.

    MEASURED 2026-10-10 (dex)
      Lucky weights: Legendary 70 / Mythic 12 / Arcane 1 / LYTH 0.01, pity
      Mythic 175 / Arcane 350. Cursed King = 1 of 3 Arcanes (~0.33%).
      RaidUnitConfig: Shadow Gate -> sung_jinwoo 3% pity 32, Bathtub -> hutao
      2% pity 35. Drops land in achievements.progress["storage.<char>"],
      placeStoredUnit{character, slot, requestId} -> storedUnitPlaced (replaces
      the slot's character, same as the game's Storage window).
      Clear rewards (QuqueWindowHandler): Story gems 50/100/200/350 by
      difficulty, Shadow Gate 710 gems + 35,425 coins.
      Skill tree: branches ATK/CRIT/DEF/SPD, tiers cost 0/1/5/9/11, 1 token per
      character level (max 110). Evolve = one step (gems + Story HxH mats);
      Jinwoo also needs Shadow Gate mats and has Monarch stages II/III.

    Override by setting getgenv().Kaitan BEFORE executing, e.g.
      getgenv().Kaitan = { Slots = { "Cursed King", "Sung Jinwoo", "Hu Tao", "LYTH" },
                           Raid = { MinLevel = 40 } }
--]]

local StartedAt = os.clock()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait()
    LocalPlayer = Players.LocalPlayer
end

---- ============ Configuration ============ ----

local Config = {
    -- character slot 1-4 -> target ("" = leave the slot alone)
    -- slot 1 starter (Lucky Spin), 2-3 raid units (Shadow Gate, then Bathtub),
    -- 4 = player's pick; "LYTH" = any Zenless, i.e. Miyabi (the only rollable one),
    -- Normal Spin at 500 coins once everything else is evolved (end-game coin sink)
    Slots = { "Cursed King", "Sung Jinwoo", "Hu Tao", "LYTH" },

    Summon = {
        -- gems -> Lucky Spins (100 each): "auto" = only while slot 1 still misses
        -- its target (starter); afterwards gems are kept for evolving.
        -- true = always, false = never
        ConvertGems = "auto",
        KeepGems    = 0,
        -- end game (every raid unit owned, everything evolved): Lucky Spins
        -- already held first, then Normal Spin - dice rolls, then 500 coins each.
        -- Normal Zenless weight 0.005 (Lucky 0.01), pity 3500.
        KeepMoney   = 0,        -- never spin below this (the next Igris level is kept too)
        NormalBatch = 100000,   -- coins worth a lobby trip for Normal Spins
        Protect     = "Zenless", -- never roll over this rarity or better
        Favourite   = true,      -- favourite a slot once it hits its target
        Unfavourite = true,      -- un-favourite a slot that misses its target (so it can be re-rolled)
        SpinBatch   = 10,        -- starter: Lucky Spins (+ gems/100) worth a lobby trip
    },

    Farm = {
        Map        = "Hxh",
        -- highest difficulty whose level the main character has reached. All 0 = always
        -- Nightmare (most gems, rare mats): the orbit clears any stage, and two losses
        -- in a row still drop that stage a difficulty (Farm.Losses / Unblock)
        Difficulty = { Easy = 0, Medium = 0, Hard = 0, Nightmare = 0 },
        Height     = 5,   -- orbit height above the target
        Radius     = 8,   -- orbit radius
        Speed      = 10,  -- orbit speed (same scale as the hub's Orbit mode)
        Skills     = true,
        Ultimate   = "Boss",  -- "Boss" = only on a boss, true = whenever charged, false = never
        CollectCash = false,  -- walk over to cash drops after a wave (off: go straight on)
        HealBelow  = 40,  -- % HP: below it pick up the health drops kept back (0 = the game's own pickup)
        TagTeam    = true,
        Losses     = 2,   -- losses in a row that block a stage...
        Unblock    = 10,  -- ...until the main character gains this many levels
    },

    Raid = {
        -- build the main first (user 2026-10-10: a Lv21 Cursed King took 6.5 min per Shadow
        -- Gate): raids open at this level AND once its ultimate is evolved (or MaxWait reached)
        MinLevel = 40,
        MaxWait  = 60,    -- level at which raids open even without the evolve
    },

    Lobby = {
        Every   = 10,     -- matches between visits even with nothing to spend
        MinGap  = 1,      -- matches between visits for skill points alone
        -- strict order, each to tier 5: damage first (ATK +15/25/40/60%, then CRIT chance);
        -- tokens are saved for the next damage node rather than spent on a cheaper branch
        Skills  = { "ATK", "CRIT", "DEF", "SPD" },
        Shop    = true,   -- buy missing evolve materials with coins
        Convert = true,   -- convert spare materials into missing ones
        Evolve  = true,
        Igris   = true,   -- Shadow Monarch Igris tree (stage II+)
    },

    -- trait rerolls: main first, then the other team members; stop at the first of these
    -- (Ferocity +18% dmg / Supernova +24% / Deadeye +20% & crit - Legendary pity 250, Exotic 1000)
    Trait = { Keep = { "Supernova", "Deadeye", "Ferocity" } },
    Gear  = true,     -- equip the best damage title + accessories already owned
    -- accessories (all 14 are crafted from Story Hxh materials): craft the best piece of every slot
    -- that is on - highest tier, then most Damage %, then the other buffs. Materials an evolve or the next
    -- Igris level still needs are never spent; Farm = the planner farms what a craft is missing
    -- (after the evolves / Igris)
    Craft = { Enabled = true, Farm = true, Head = true, Face = true, Neck = true, Back = true },

    -- while farming (user 2026-10-10: as light as possible for many accounts on one PC)
    Performance = {
        Boost       = true,  -- lowest graphics: no shadows / effects / particles / textures, plastic materials
        WhiteScreen = true,  -- stop drawing the 3D world (Set3dRenderingEnabled): blank screen, the game's UI and mouse still show
        FpsCap      = 30,    -- setfpscap while farming (0 = leave the executor's cap)
    },
    -- hide this account's name on screen: the panel (the avatar picture stays), the game's UI
    -- (boss damage list...) and the Roblox player list (this PC only - others still see the name)
    HideName = true,

    Codes   = true,
    -- codes the client's codesConfig does not list yet (codesConfig carries MinimumLevel per code)
    ExtraCodes = { "50KCCU" },
    Claims  = true,
    AntiAFK = true,
    -- new accounts start in a tutorial match (workspace Mode "tutorial"): "skip" = press the
    -- game's Skip button (TutorialRemote "skip" -> back to the lobby), "play" = fight through it
    Tutorial = "skip",
    DryRun  = false,
    -- testing: pin one stage, e.g. "Raid:BathTub", "Raid:ShadowGate", "Story:Hxh:3:4" ("" = planner)
    Force   = "",  -- lobby: report the plan only (no spins / spending / joining)
    -- Lua source queued with queue_on_teleport so the run continues in the
    -- next place. "" = getgenv().KaitanLoader, else valkyriehub.net/api/raw/anime-zero-kaitan
    Loader  = "",
    -- dashboard: valkyriehub.net/account/kaitan?mode=kaitan (status, progress %, Global Settings)
    Web     = true,
    SiteUrl = "https://www.valkyriehub.net/api/kaitan/report",
    -- wait for "Start farm" on the website before doing anything (the choice is kept on disk,
    -- so a rejoin carries on); false = start right away. Ignored when Web is off.
    WaitForStart = true,
    DashboardUrl = "https://www.valkyriehub.net/account/kaitan?mode=kaitan&game=anime-zero",
    DiscordUrl   = "https://discord.gg/PNnMkTRnuB",
}

local function MergeConfig(Into, From)
    for Key, Value in pairs(From) do
        if type(Value) == "table" and type(Into[Key]) == "table" and #Value == 0 then
            MergeConfig(Into[Key], Value)
        else
            Into[Key] = Value
        end
    end
end

-- only the customer's own overrides travel with the teleport queue (carrying the whole
-- Config let an old build's defaults override a newer build after an update)
local Overrides = type(getgenv().Kaitan) == "table" and getgenv().Kaitan or { }
MergeConfig(Config, Overrides)

---- ============ Session ============ ----

local SessionToken = { }
local SessionConnections = { }

-- Kaitan keeps its own session: the menu hub (Anime-Zero.lua, often in the executor's
-- autoexec) calls getgenv().ValkyrieCleanup when it starts - sharing that name let the hub
-- silently kill a running Kaitan (measured 2026-10-10: lobby stuck on "Loading").
-- Kaitan stops an older Kaitan AND the hub, and keeps stopping the hub if it loads later.
if type(getgenv().KaitanCleanup) == "function" then
    pcall(getgenv().KaitanCleanup)
end
if type(getgenv().ValkyrieCleanup) == "function" then
    pcall(getgenv().ValkyrieCleanup)
end
getgenv().KaitanSession = SessionToken
getgenv().KaitanBooted = game.JobId

local function Live()
    return getgenv().KaitanSession == SessionToken
end

local function TrackConnection(Connection)
    if Connection then table.insert(SessionConnections, Connection) end
    return Connection
end

local LobbyPlaceId = 114574503491412

-- the copy queued for the next place can start before ReplicatedStorage has replicated: one
-- check found neither folder, the panel said "Idle" and nothing ran (user 2026-10-10, a Hu Tao
-- Bathtub run standing still) -> wait for the place's folder
local IsLobby, IsMatch = game.PlaceId == LobbyPlaceId, false
for _ = 1, 120 do
    IsLobby = IsLobby or ReplicatedStorage:FindFirstChild("lobby") ~= nil
    IsMatch = (not IsLobby) and ReplicatedStorage:FindFirstChild("game") ~= nil
    if IsLobby or IsMatch then break end
    task.wait(0.5)
end

-- What the panel shows. Workers write, the main-spawned render thread reads
-- (a thread that required a game module loses the capability to touch UI).
local Status = { Phase = "Booting", Text = "", Log = { }, Slots = { }, Stats = { }, Plan = "", Gains = { } }

local function Say(Phase, Text)
    Status.Phase = Phase or Status.Phase
    Status.Text = Text or ""
end

local function Note(Text)
    table.insert(Status.Log, 1, os.date("%H:%M:%S ") .. Text)
    if #Status.Log > 7 then table.remove(Status.Log) end
    print("[Kaitan AZ] " .. Text)
end

---- ============ Saved state (per account) ============ ----

local SaveFolder = "Valkyrie Hub/AnimeZeroKT"
local SavePath = SaveFolder .. "/" .. LocalPlayer.Name .. ".json"
-- Codes: tried codes / SinceLobby: matches since the last lobby visit /
-- PlanKey: stage joined last / Loss: losses in a row on one stage /
-- Blocked: stage key -> main level it unblocks at
local Saved = { Codes = { }, CodeTried = { }, SinceLobby = 0, PlanKey = "", Loss = { Key = "", Count = 0 }, Blocked = { } }

pcall(function()
    if isfile and isfile(SavePath) then
        local Data = HttpService:JSONDecode(readfile(SavePath))
        if type(Data) == "table" then MergeConfig(Saved, Data) end
    end
end)

-- Global Settings from the website (Kaitan page), kept in the save file so a site restart or
-- a report landing on another server instance changes nothing. Applied over the defaults
-- and getgenv().Kaitan: the page is where the owner sets every account at once.
local function ApplyGlobal(Values)
    if type(Values) ~= "table" then return end
    local Copy = HttpService:JSONDecode(HttpService:JSONEncode(Values))
    if type(Copy.Farm) == "table" then
        local Ult = Copy.Farm.Ultimate
        Copy.Farm.Ultimate = (Ult == "Always" and true) or (Ult == "Never" and false) or "Boss"
    end
    MergeConfig(Config, Copy)
    -- an emptied list would merge as "nothing to change": set it outright
    if type(Copy.Trait) == "table" and type(Copy.Trait.Keep) == "table" then Config.Trait.Keep = Copy.Trait.Keep end
    if type(Copy.Slots) == "table" then
        for Slot = 1, 4 do Config.Slots[Slot] = tostring(Copy.Slots[Slot] or "") end
    end
end
if type(Saved.Global) == "table" then pcall(ApplyGlobal, Saved.Global) end

-- v1 saved level-gated codes as done when the server only refused them (account too low)
if Saved.CodesVersion ~= 2 then
    Saved.Codes, Saved.CodesVersion = { }, 2
end

local function Save()
    pcall(function()
        if not isfolder("Valkyrie Hub") then makefolder("Valkyrie Hub") end
        if not isfolder(SaveFolder) then makefolder(SaveFolder) end
        writefile(SavePath, HttpService:JSONEncode(Saved))
    end)
end

-- Start / Stop farm from the website (Saved.Farm, newest Saved.FarmAt wins)
local function Farming()
    return Saved.Farm == true or not Config.WaitForStart or not Config.Web
end

---- ============ Game helpers ============ ----

local function SafeRequire(Parent, ...)
    local Node = Parent
    for _, Name in ipairs({ ... }) do
        Node = Node and Node:WaitForChild(Name, 10)
    end
    if not Node then return nil end
    local Ok, Result = pcall(require, Node)
    return Ok and Result or nil
end

-- modules some places do not have (the match has no evolutionConfig) - no 10s wait
local function TryRequire(...)
    local Node = ReplicatedStorage
    for _, Name in ipairs({ ... }) do
        Node = Node and Node:FindFirstChild(Name)
    end
    if not Node then return nil end
    local Ok, Result = pcall(require, Node)
    return Ok and Result or nil
end

local function Read(Leaf)
    if type(Leaf) == "table" and type(Leaf.get) == "function" then
        local Ok, Value = pcall(Leaf.get, Leaf)
        return Ok and Value or nil
    end
    return Leaf
end

local function Unhook(Hook)
    pcall(function() if type(Hook) == "function" then Hook() else Hook:Disconnect() end end)
end

local DifficultyNames = { "Easy", "Medium", "Hard", "Nightmare" }
local RarityRank = { Epic = 1, Legendary = 2, Mythic = 3, Arcane = 4, Zenless = 5, LYTH = 5 }

-- characterRollConfig.rarityByCharacter + displayName (fallback when a module is missing)
local Characters = {
    miyabi = { Name = "Cataclysm", Rarity = "Zenless" },
    hutao = { Name = "Flame Director", Rarity = "Zenless" },
    sung_jinwoo = { Name = "Shadow Monarch", Rarity = "Zenless" },
    sukuna = { Name = "Cursed King", Rarity = "Arcane" },
    shanks = { Name = "Divine Emperor", Rarity = "Arcane" },
    katakuri = { Name = "Mochi Commander", Rarity = "Arcane" },
    saber = { Name = "Lights of Divinity", Rarity = "Mythic" },
    guts = { Name = "Dragon Eclipse", Rarity = "Mythic" },
    alucard = { Name = "Immortal Sovereign", Rarity = "Mythic" },
    juuzou = { Name = "Twisted Agony", Rarity = "Legendary" },
    nagumo = { Name = "Kings Gambit", Rarity = "Legendary" },
    luffy = { Name = "Rubber Man", Rarity = "Epic" },
    goku = { Name = "Cosmic Warrior", Rarity = "Epic" },
    killua = { Name = "Thunder Prodigy", Rarity = "Epic" },
}

-- raid-only units: character -> raid map (RaidUnitConfig.Raids, drop key -> gamemodeSelectEnum map)
local RaidMaps = { sololevelingraid = "ShadowGate", spiritedawayraid = "BathTub" }
local RaidUnits = { sung_jinwoo = "ShadowGate", hutao = "BathTub" }

local function LoadCharacterData()
    local Roll = TryRequire("assets", "config", "characterRollConfig")
    local Info = TryRequire("global", "constants", "characters")
    local Units = TryRequire("assets", "config", "RaidUnitConfig")
    for Id, Rarity in pairs(Roll and Roll.rarityByCharacter or { }) do
        Characters[Id] = Characters[Id] or { Name = Id }
        Characters[Id].Rarity = Rarity
    end
    for Id, Data in pairs(Info and Info.charactersByName or { }) do
        if type(Data) == "table" and type(Data.displayName) == "string" then
            Characters[Id] = Characters[Id] or { }
            Characters[Id].Name = Data.displayName
        end
    end
    for Drop, Data in pairs(Units and Units.Raids or { }) do
        if type(Data) == "table" and Data.Character and RaidMaps[Drop] then RaidUnits[Data.Character] = RaidMaps[Drop] end
    end
end

local function NameOf(Id)
    return (Characters[Id] and Characters[Id].Name) or tostring(Id)
end

local function RankOf(Id)
    return RarityRank[(Characters[Id] or { }).Rarity or ""] or 0
end

local function Norm(Text)
    return (tostring(Text or ""):lower():gsub("[%s_%-']", ""))
end

-- alternative -> { Rank = n } for a rarity, { Id = "sukuna" } for a character
local function ParseAlt(Text)
    local Key = Norm(Text)
    if Key == "lyth" then return { Rank = 5 } end
    for Name, Rank in pairs(RarityRank) do
        if Norm(Name) == Key then return { Rank = Rank } end
    end
    if Key == "curvedking" then Key = "cursedking" end
    for Id, Data in pairs(Characters) do
        if Norm(Id) == Key or Norm(Data.Name) == Key then return { Id = Id } end
    end
    return { Id = Text }
end

local function Alternatives(Target)
    local List = { }
    for Part in tostring(Target or ""):gmatch("[^|]+") do
        local Trimmed = Part:match("^%s*(.-)%s*$")
        if Trimmed ~= "" then table.insert(List, ParseAlt(Trimmed)) end
    end
    return List
end

local function Satisfies(Id, Target)
    if type(Id) ~= "string" or Id == "" then return false end
    local List = Alternatives(Target)
    if #List == 0 then return true end
    for _, Alt in ipairs(List) do
        if Alt.Rank and RankOf(Id) >= Alt.Rank then return true end
        if Alt.Id == Id then return true end
    end
    return false
end

-- can a Lucky Spin satisfy this target? (a rarity, or a character that is not raid-only)
local function Rollable(Target)
    for _, Alt in ipairs(Alternatives(Target)) do
        if Alt.Rank or (Alt.Id and not RaidUnits[Alt.Id]) then return true end
    end
    return false
end

local function RaidAlt(Target)
    for _, Alt in ipairs(Alternatives(Target)) do
        if Alt.Id and RaidUnits[Alt.Id] then return Alt.Id end
    end
end

local Account -- accountNamespace (lobby + match)

local function AccountTable()
    local Ok, Data = pcall(function() return Account.getLocalPlayerAccount():toTable() end)
    return Ok and Data or nil
end

local function Currency(Name, Data)
    Data = Data or AccountTable()
    return tonumber(Data and Data.currencies and Data.currencies[Name]) or 0
end

local function Progress(Key, Data)
    local P = Data and Data.achievements and Data.achievements.progress
    return type(P) == "table" and tonumber(P[Key]) or 0
end

local function SlotData(Slot, Data)
    Data = Data or AccountTable()
    local Entry = Data and Data.UnlockedCharacters and Data.UnlockedCharacters["Slot" .. Slot]
    if type(Entry) ~= "table" then return nil end
    return { Unlocked = Entry.Unlocked == true, Favourite = Entry.Favourite == true, Character = Entry.Character or "" }
end

local function Owns(Id, Data)
    for Slot = 1, 4 do
        local S = SlotData(Slot, Data)
        if S and S.Unlocked and S.Character == Id then return true end
    end
    return false
end

local function UnlockCost(Slot)
    return ({ [2] = 25000, [3] = 100000, [4] = 1000000 })[Slot] or 0
end

local function Root()
    local Character = LocalPlayer.Character
    return Character and Character:FindFirstChild("HumanoidRootPart")
end

---- ============ Progression (levels, skill tree, evolve) ============ ----
-- usable in the lobby and in the match (match: fallbacks where a config is missing)

local Grow = { }

do
    local SkillCosts = { 0, 1, 5, 9, 11 }
    local EvolveNeeds = {
        alucard = "101,30|106,12|108,6|110,3", shanks = "101,45|103,20|112,10|111,4", goku = "101,8|102,3|106,3",
        nagumo = "101,20|107,10|105,5", hutao = "101,20|110,8|113,25|114,10", miyabi = "101,60|103,30|108,12|112,10|110,4",
        killua = "101,8|102,3|103,3", sukuna = "101,45|106,20|104,10|110,4", saber = "101,30|107,12|105,6|109,3",
        guts = "101,30|106,12|104,6|110,3", juuzou = "101,20|106,10|104,5", luffy = "101,8|102,3|106,3",
        katakuri = "117,50|118,75", sung_jinwoo = "101,20|110,8|115,25|116,10",
    }
    local EvolveGems = { sukuna = 1750, shanks = 1750, saber = 1250, guts = 1250, alucard = 1250 }

    function Grow.Load()
        if Grow.Loaded then return end
        Grow.Loaded = true
        Grow.Levels = TryRequire("global", "utils", "characterLevelProgression")
        Grow.Tree = TryRequire("assets", "config", "characterSkillTreeConfig")
        Grow.Evolution = TryRequire("assets", "config", "evolutionConfig")
        Grow.Items = TryRequire("assets", "config", "materialConfig")
        Grow.Shop = TryRequire("assets", "config", "MaterialShopConfig")
        Grow.Drops = TryRequire("assets", "config", "materialDropConfig")
        Grow.Path = TryRequire("assets", "config", "MonarchPathConfig")
        Grow.Gear = TryRequire("assets", "config", "accessoryConfig")
        Grow.GearSlots = TryRequire("assets", "config", "accessorySlotConfig")
        Grow.Recipes = TryRequire("assets", "config", "accessoryCraftConfig")
    end

    function Grow.Level(Id, Data)
        local Info = Data and Data.CharactersData and Data.CharactersData[Id]
        local Xp = Info and Info.Progression and Info.Progression.Xp or 0
        local Ok, Level = pcall(function() return Grow.Levels.getLevel(Xp) end)
        return Ok and tonumber(Level) or 1
    end

    function Grow.Tier(Id)
        local Info = Grow.Items and Grow.Items[tostring(Id)]
        return Info and tonumber(Info.Tier) or 1
    end

    function Grow.ItemName(Id)
        local Info = Grow.Items and Grow.Items[tostring(Id)]
        return Info and Info.Name or tostring(Id)
    end

    -- next skill node in strict branch order: { Branch, Tier, Cost } and tokens left
    function Grow.NextSkill(Id, Data)
        local Info = Data and Data.CharactersData and Data.CharactersData[Id]
        local Skills = Info and Info.Progression and Info.Progression.Skills
        if type(Skills) ~= "table" then return nil, 0 end
        local Spent = 0
        for _, Branch in ipairs({ "ATK", "CRIT", "DEF", "SPD" }) do
            for Tier = 1, tonumber(Skills[Branch]) or 0 do Spent = Spent + (SkillCosts[Tier] or 0) end
        end
        local Tokens = Grow.Level(Id, Data) - Spent
        pcall(function()
            local Value = Grow.Levels.getAvailableTokens(Id, Info.Progression.Xp, Skills)
            if tonumber(Value) then Tokens = tonumber(Value) end
        end)
        for _, Branch in ipairs(Config.Lobby.Skills) do
            local Tier = (tonumber(Skills[Branch]) or 0) + 1
            local Node = Grow.Tree and Grow.Tree.characters and Grow.Tree.characters[Id]
                and Grow.Tree.characters[Id].branches[Branch] and Grow.Tree.characters[Id].branches[Branch].tiers[Tier]
            local Cost = Node and tonumber(Node.cost) or SkillCosts[Tier]
            if Tier <= 5 and Cost then return { Branch = Branch, Tier = Tier, Cost = Cost }, Tokens end
        end
        return nil, Tokens
    end

    function Grow.Stage()
        if not (Grow.Path and Account) then return 0 end
        local Ok, Stage = pcall(Grow.Path.GetStage, Account.getLocalPlayerAccount())
        return Ok and tonumber(Stage) or 0
    end

    -- next evolve step: { Materials = { [id] = n }, Currencies = { gems = n }, Step, Monarch } / nil = done
    function Grow.Cost(Id, Data)
        if Grow.Path and Id == Grow.Path.Character then
            local Stage = Grow.Stage()
            if Stage >= 1 then
                local Next = Grow.Path.Stages and Grow.Path.Stages[Stage + 1]
                if not Next then return nil end
                local Cost = { Materials = { }, Currencies = { }, Step = "Monarch " .. tostring(Next.Numeral or Stage + 1), Monarch = Stage + 1 }
                for Item, Amount in tostring(Next.Materials or ""):gmatch("(%d+),(%d+)") do Cost.Materials[Item] = (Cost.Materials[Item] or 0) + tonumber(Amount) end
                for Key, Amount in pairs(Next.Currencies or { }) do Cost.Currencies[Key] = tonumber(Amount) or 0 end
                return Cost
            end
        end
        local Info = Data and Data.CharactersData and Data.CharactersData[Id]
        if type(Info) == "table" and Info.IsUltimateUnlocked then return nil end
        local Entry = Grow.Evolution and Grow.Evolution[Id]
        local Cost = { Materials = { }, Currencies = { }, Step = "Ultimate" }
        for Item, Amount in tostring(Entry and Entry.ultimate or EvolveNeeds[Id] or ""):gmatch("(%d+),(%d+)") do
            Cost.Materials[Item] = (Cost.Materials[Item] or 0) + tonumber(Amount)
        end
        if Entry then
            for _, C in ipairs(Entry.currencies or { }) do
                if type(C) == "table" and C.currency then Cost.Currencies[C.currency] = tonumber(C.amount) or 0 end
            end
        elseif EvolveGems[Id] then
            Cost.Currencies.gems = EvolveGems[Id]
        end
        if not next(Cost.Materials) and not next(Cost.Currencies) then return nil end
        return Cost
    end

    function Grow.Missing(Id, Data)
        local Cost = Grow.Cost(Id, Data)
        local Bag = Data and Data.material or { }
        local Missing = { }
        for Item, Amount in pairs(Cost and Cost.Materials or { }) do
            local Left = Amount - (tonumber(Bag[Item]) or 0)
            if Left > 0 then Missing[Item] = Left end
        end
        return Missing, Cost
    end

    function Grow.Affordable(Id, Data)
        local Missing, Cost = Grow.Missing(Id, Data)
        if not Cost or next(Missing) then return false end
        for Key, Amount in pairs(Cost.Currencies) do
            if Currency(Key, Data) < Amount then return false end
        end
        return true
    end

    -- owned characters (unique), best rank first
    function Grow.Owned(Data)
        local List, Seen = { }, { }
        for Slot = 1, 4 do
            local S = SlotData(Slot, Data)
            if S and S.Unlocked and S.Character ~= "" and not Seen[S.Character] then
                Seen[S.Character] = true
                table.insert(List, { Id = S.Character, Slot = Slot, Rank = RankOf(S.Character) })
            end
        end
        table.sort(List, function(A, B)
            if A.Rank ~= B.Rank then return A.Rank > B.Rank end
            return A.Slot < B.Slot
        end)
        return List
    end

    -- the character evolve materials are farmed for: best rank that is not evolved yet
    function Grow.Target(Data)
        for _, Entry in ipairs(Grow.Owned(Data)) do
            if Grow.Cost(Entry.Id, Data) then return Entry.Id end
        end
    end

    -- Igris tree (Shadow Monarch stage II+): next level of every node that is not maxed
    function Grow.IgrisNodes()
        local List = { }
        local Path = Grow.Path
        if not (Path and Path.IgrisTree and Account and Grow.Stage() >= 2) then return List end
        for _, Node in ipairs({ "Blade", "Command", "Speed", "Loyalty" }) do
            local Ok, Level = pcall(Path.GetNodeLevel, Account.getLocalPlayerAccount(), Node)
            Level = Ok and tonumber(Level) or 0
            local Cost = Path.IgrisTree.Nodes[Node] and Path.IgrisTree.Nodes[Node].Levels[Level + 1]
            if Cost then table.insert(List, { Node = Node, Level = Level + 1, Cost = Cost }) end
        end
        return List
    end

    -- accessory worth: tier first (user 2026-10-11: the Legendary Blast Archer Wings on the back,
    -- not the T3 Dark Captain Wings with 1% more damage), then Damage %, then every other buff %
    function Grow.GearScore(Info)
        local Damage, Total = 0, 0
        for _, Buff in ipairs(type(Info) == "table" and Info.Buffs or { }) do
            local Value = tonumber(Buff.Percent) or 0
            Total = Total + Value
            if tostring(Buff.Type) == "Damage" then Damage = Damage + Value end
        end
        return (tonumber(Info and Info.Tier) or 0) * 100000 + Damage * 1000 + Total
    end

    -- best piece per slot (Head / Face / Neck / Back) with its recipe: { [slot] = { Id, Key, Name, Recipe } }
    function Grow.BestGear()
        if Grow.BestCache then return Grow.BestCache end
        if not (Grow.Gear and Grow.GearSlots and Grow.Recipes) then return { } end
        local Best = { }
        for Key, Recipe in pairs(Grow.Recipes) do
            local Id = type(Recipe) == "table" and tostring(Recipe.CarftID or "") or ""
            local Info = Grow.Gear[Id] or Grow.Gear[tonumber(Id)]
            local Ok, Slot = pcall(Grow.GearSlots.GetSlot, Id)
            if Info and Ok and Slot and (not Best[Slot] or Grow.GearScore(Info) > Grow.GearScore(Best[Slot].Info)) then
                local Needs = { }
                for Item, Amount in tostring(Recipe.Misc or ""):gmatch("(%d+),(%d+)") do Needs[Item] = (Needs[Item] or 0) + tonumber(Amount) end
                Best[Slot] = { Id = Id, Key = tostring(Key), Name = tostring(Info.Name or Id), Info = Info, Recipe = Needs }
            end
        end
        Grow.BestCache = Best
        return Best
    end

    -- materials the next evolve of every owned character and the next Igris levels still use
    function Grow.Reserved(Data)
        local Reserved = { }
        for _, Entry in ipairs(Grow.Owned(Data)) do
            local Cost = Grow.Cost(Entry.Id, Data)
            for Item, Amount in pairs(Cost and Cost.Materials or { }) do Reserved[Item] = (Reserved[Item] or 0) + Amount end
        end
        for _, Next in ipairs(Grow.IgrisNodes()) do
            for Item, Amount in tostring(Next.Cost.Materials or ""):gmatch("(%d+),(%d+)") do Reserved[Item] = (Reserved[Item] or 0) + tonumber(Amount) end
        end
        return Reserved
    end

    -- slots (on in Config.Craft) whose best piece is not owned yet, with what the craft still
    -- misses out of the spare materials: { { Slot, Id, Key, Name, Missing } }
    function Grow.CraftTargets(Data)
        local List = { }
        local C = Config.Craft or { }
        if not (C.Enabled and Data) then return List end
        local Bag = Data.material or { }
        local Reserved = Grow.Reserved(Data)
        local Used = { }
        for _, Slot in ipairs({ "Head", "Face", "Neck", "Back" }) do
            local Pick = Grow.BestGear()[Slot]
            if C[Slot] ~= false and Pick and (tonumber(Data.accessory and Data.accessory[Pick.Id]) or 0) <= 0 then
                local Missing = { }
                for Item, Amount in pairs(Pick.Recipe) do
                    local Spare = (tonumber(Bag[Item]) or 0) - (Reserved[Item] or 0) - (Used[Item] or 0)
                    if Amount > Spare then Missing[Item] = Amount - math.max(Spare, 0) end
                    Used[Item] = (Used[Item] or 0) + Amount
                end
                table.insert(List, { Slot = Slot, Id = Pick.Id, Key = Pick.Key, Name = Pick.Name, Missing = Missing })
            end
        end
        return List
    end

    -- everything still to buy, in order: evolves (best rank first), Igris levels, then crafts
    -- { Name, Missing = { [item] = n }, Currencies = { money = n }, Evolve = id | Igris = node | Craft = recipe key }
    function Grow.Projects(Data)
        local List = { }
        local Bag = Data and Data.material or { }
        for _, Entry in ipairs(Grow.Owned(Data)) do
            local Missing, Cost = Grow.Missing(Entry.Id, Data)
            if Cost then
                table.insert(List, { Name = NameOf(Entry.Id) .. " " .. Cost.Step, Missing = Missing, Currencies = Cost.Currencies, Evolve = Entry.Id })
            end
        end
        for _, Next in ipairs(Grow.IgrisNodes()) do
            local Missing = { }
            for Item, Amount in tostring(Next.Cost.Materials or ""):gmatch("(%d+),(%d+)") do
                local Left = tonumber(Amount) - (tonumber(Bag[Item]) or 0)
                if Left > 0 then Missing[Item] = Left end
            end
            table.insert(List, { Name = "Igris " .. Next.Node .. " " .. Next.Level, Missing = Missing,
                Currencies = { money = tonumber(Next.Cost.Money) or 0 }, Igris = Next.Node })
        end
        if Config.Craft and Config.Craft.Farm then
            for _, Target in ipairs(Grow.CraftTargets(Data)) do
                table.insert(List, { Name = "Craft " .. Target.Name, Missing = Target.Missing, Currencies = { }, Craft = Target.Key })
            end
        end
        return List
    end

    -- end game = no raid unit left to farm and nothing left to evolve (gems are free to spin)
    function Grow.EndGame(Data)
        for _, Entry in ipairs(Grow.Owned(Data)) do
            if Grow.Cost(Entry.Id, Data) then return false end
        end
        return true
    end

    local function RollChances(Table)
        local Out, Left = { }, 1
        for _, Entry in ipairs(Table or { }) do
            local Chance = tonumber(Entry.Chance) or 0
            Out[tostring(Entry.Item)] = Left * Chance
            Left = Left * (1 - Chance)
        end
        return Out
    end

    -- best Story act for the missing materials at one difficulty (nil = nothing to gain)
    function Grow.BestAct(Missing, Difficulty, Unlocked)
        if not (Grow.Drops and next(Missing)) then return nil end
        local Rolls = 1
        pcall(function() Rolls = Grow.Drops.GetClearRolls("hxh", Difficulty) end)
        local Best, BestScore = nil, 0
        for Act = 1, math.min(Unlocked, 3) do
            local Ok, Table = pcall(Grow.Drops.GetTable, "hxh", Act, Difficulty)
            local Score = 0
            for Item, Chance in pairs(Ok and RollChances(Table) or { }) do
                if Missing[Item] then
                    Score = Score + math.min(Chance * Rolls, Missing[Item]) * 5 ^ (Grow.Tier(Item) - 1)
                end
            end
            if Score > BestScore then Best, BestScore = Act, Score end
        end
        return Best
    end
end

---- ============ Carry (แบกไก่) ============ ----
-- Groups make themselves (user 2026-10-10: no picking on the website): the site puts every
-- running account of one owner that has Sung Jinwoo down as a carrier ("mother") and spreads the
-- accounts without him over them, 5 per carrier (rooms hold 6, Shadow Gate attempts are
-- unlimited). The carrier opens a Shadow Gate room for its group and clears it alone. A kaitan
-- ("child") skips its starter spins and trait rolls, moves into the carrier's lobby server
-- (TeleportToPlaceInstance + its JobId), walks into the room (friendsOnly off, joined by standing
-- in its JoinHitbox like the host) and hides above the map through the match, voting whatever the
-- carrier votes. A kaitan that gets Jinwoo becomes a carrier on the next report; a carrier with
-- nobody to carry farms its own plan. Every report says state.Carry.jinwoo; the reply says which
-- group this account is in and where the other side is (reply.carry).

local Carry = { Unit = "sung_jinwoo", Live = nil, LiveAt = 0, UrgentUntil = 0, HopAt = 0 }

function Carry.Info()
    return Carry.Live or (type(Saved.Carry) == "table" and Saved.Carry) or nil
end

function Carry.Role()
    local Info = Carry.Info()
    return Info and Info.role or nil
end

function Carry.ChildDone(Data)
    Data = Data or AccountTable()
    return Data ~= nil and (Owns(Carry.Unit, Data) or Progress("storage." .. Carry.Unit, Data) > 0)
end

-- the site says a group for this account is about to form (the other side has not pressed
-- Start yet): hold off a little instead of running off alone - 45 s at most
function Carry.Waiting()
    return Carry.Live ~= nil and not Carry.Live.role and Carry.Live.wait == true
        and Carry.WaitSince ~= nil and os.clock() - Carry.WaitSince < 45
end

-- a child still waiting for the unit (or about to be one): no starter spins, no trait rolling
function Carry.Child(Data)
    if Carry.ChildDone(Data) then return false end
    return Carry.Role() == "child" or Carry.Waiting()
end

function Carry.Mother()
    local Info = Carry.Info()
    return Info and type(Info.mother) == "table" and Info.mother or nil
end

-- children the mother must group with before any room: online and not done, Start farm
-- pressed or not (one still waiting for the button gets it any moment - "เริ่มทั้งหมด" starts
-- the whole group at once, and the mother's reply can still show it as not started)
function Carry.Pending()
    local List = { }
    local Info = Carry.Live
    if not (Info and Info.role == "mother" and type(Info.children) == "table") then return List end
    for _, Kid in ipairs(Info.children) do
        if type(Kid) == "table" and Kid.online and not Kid.done then table.insert(List, Kid) end
    end
    return List
end

-- group ids as last seen (kept on disk: a match boots before its first report)
function Carry.ChildIds()
    local Info = Carry.Info()
    local List = { }
    for _, Kid in ipairs(Info and type(Info.children) == "table" and Info.children or { }) do
        if type(Kid) == "table" and Kid.id then table.insert(List, tostring(Kid.id)) end
    end
    return List
end

-- report every 2 s while the two sides are lining up
function Carry.Urgent() Carry.UrgentUntil = os.clock() + 20 end
function Carry.Busy() return os.clock() < Carry.UrgentUntil end

function Carry.Apply(Value)
    if type(Value) ~= "table" then return end
    Carry.Live, Carry.LiveAt = Value, os.clock()
    if Value.wait == true and not Value.role then
        Carry.WaitSince = Carry.WaitSince or os.clock()
    else
        Carry.WaitSince = nil
    end
    local Keep = { role = Value.role }
    if type(Value.mother) == "table" then Keep.mother = { id = tostring(Value.mother.id) } end
    if type(Value.children) == "table" then
        Keep.children = { }
        for _, Kid in ipairs(Value.children) do table.insert(Keep.children, { id = tostring(Kid.id) }) end
    end
    local Ok, Old = pcall(HttpService.JSONEncode, HttpService, Saved.Carry or { })
    local Ok2, New = pcall(HttpService.JSONEncode, HttpService, Keep)
    if Ok and Ok2 and Old ~= New then
        if (type(Saved.Carry) == "table" and Saved.Carry.role or nil) ~= Keep.role then
            Note(Keep.role == "mother" and "Carry: this account is the carrier" or Keep.role == "child" and "Carry: this account is being carried"
                or "Carry: not in a group")
        end
        Saved.Carry = Keep
        Save()
    end
end

-- match: is the mother / how many children are in this run
function Carry.MotherHere(State)
    local Mother = Carry.Mother()
    if not (Mother and Mother.id) then return false end
    local Ok, Entry = pcall(function() return State.participants:get(tostring(Mother.id)) end)
    return Ok and Entry ~= nil
end

-- children of the group (online, not done) that are not in this run. One the mother already
-- gave up waiting for (MotherStep, 3 minutes) is left out for 10 minutes - otherwise a kaitan
-- that never makes it in would send her back to the lobby after every match
function Carry.Missing(State)
    local List = { }
    local Skip = type(Saved.CarrySkip) == "table" and Saved.CarrySkip or { }
    for _, Kid in ipairs(Carry.Pending()) do
        local Ok, Entry = pcall(function() return State.participants:get(tostring(Kid.id)) end)
        if not (Ok and Entry ~= nil) and (tonumber(Skip[tostring(Kid.id)]) or 0) < os.time() then table.insert(List, Kid) end
    end
    return List
end

function Carry.KidsHere(State)
    local Count = 0
    local Done = { }
    for _, Kid in ipairs(Carry.Live and type(Carry.Live.children) == "table" and Carry.Live.children or { }) do
        if type(Kid) == "table" and Kid.done then Done[tostring(Kid.id)] = true end
    end
    for _, Id in ipairs(Carry.ChildIds()) do
        local Ok, Entry = pcall(function() return State.participants:get(Id) end)
        if Ok and Entry ~= nil and not Done[Id] then Count = Count + 1 end
    end
    return Count
end

---- ============ Plan (which stage to farm) ============ ----

local Plan = { }

-- main = highest-level owned character (rarity breaks ties); its level gates difficulty and raids
-- (a freshly placed Lv1 Jinwoo must not drag the farm down to Easy)
function Plan.Main(Data)
    local Best, BestLevel = nil, -1
    for _, Entry in ipairs(Grow.Owned(Data)) do
        local Level = Grow.Level(Entry.Id, Data)
        if Level > BestLevel then Best, BestLevel = Entry.Id, Level end
    end
    return Best
end

-- player (account) level = levelProgression of currencies.xp - what code MinimumLevel checks
function Plan.PlayerLevel(Data)
    Plan.Levels = Plan.Levels or TryRequire("global", "utils", "levelProgression")
    local Ok, P = pcall(function() return Plan.Levels.getProgress(Data.currencies.xp or 0) end)
    return Ok and type(P) == "table" and tonumber(P.level) or 0
end

-- every known code -> MinimumLevel (codesConfig + Config.ExtraCodes)
function Plan.Codes()
    Plan.CodeConfig = Plan.CodeConfig or TryRequire("assets", "config", "codesConfig") or { }
    local List = { }
    for Code, Info in pairs(Plan.CodeConfig) do
        List[Code] = type(Info) == "table" and tonumber(Info.MinimumLevel) or 0
    end
    for _, Code in ipairs(Config.ExtraCodes or { }) do
        if List[Code] == nil then List[Code] = 0 end
    end
    return List
end

-- a code the account just became able to redeem
function Plan.PendingCode(Data)
    if not Config.Codes then return nil end
    local Level = Plan.PlayerLevel(Data)
    for Code, Need in pairs(Plan.Codes()) do
        if not Saved.Codes[Code] and Level >= Need and (tonumber(Saved.CodeTried[Code]) or -1) < Level then return Code end
    end
end

-- trait ids by name (traitConfig - same Ids in lobby and match)
local TraitIds = { Supernova = 14, Deadeye = 24, Ferocity = 13, Sniper = 23, Hunter = 12 }

function Plan.TraitKeep(Id)
    for _, Name in ipairs(Config.Trait.Keep or { }) do
        if TraitIds[Name] == tonumber(Id) then return true end
    end
    return false
end

-- first team character (main first) whose trait is not kept yet, while rerolls last
-- rerolls come last (user 2026-10-10): only at end game - every raid unit owned and nothing
-- left to evolve - the rerolls pile up until then
function Plan.TraitWanted(Data)
    if Currency("traitRerolls", Data) < 1 or #(Config.Trait.Keep or { }) == 0 then return nil end
    if Plan.UnitsPending(Data) or not Grow.EndGame(Data) then return nil end
    local Main = Plan.Main(Data)
    local List = { Main }
    for _, Entry in ipairs(Grow.Owned(Data)) do
        if Entry.Id ~= Main then table.insert(List, Entry.Id) end
    end
    for _, Id in ipairs(List) do
        local Info = Data.CharactersData and Data.CharactersData[Id]
        local Trait = type(Info) == "table" and Info.TraitData and Info.TraitData.Trait or 0
        if not Plan.TraitKeep(Trait) then return Id end
    end
end

function Plan.Blocked(Key, Level)
    local Until = tonumber(Saved.Blocked[Key])
    if Until and Level < Until then return true end
    if Until then Saved.Blocked[Key] = nil end
    return false
end

-- Slot targets are a set, not positions (user 2026-10-10: Cursed King can sit in any slot): a
-- target is met when some unlocked slot holds a character that satisfies it. Assign matches
-- targets to the slots holding them (each slot counts once, its own slot first, the pickiest
-- target first): Assign[target] = slot, Used[slot] = target.
function Plan.Assign(Data)
    local Holds = { }
    for Slot = 1, 4 do
        local S = SlotData(Slot, Data)
        Holds[Slot] = S and S.Unlocked and S.Character or ""
    end
    local Candidates, Order = { }, { }
    for T = 1, 4 do
        local Target = Config.Slots[T] or ""
        Candidates[T] = { }
        if Target ~= "" then
            table.insert(Order, T)
            if Holds[T] ~= "" and Satisfies(Holds[T], Target) then table.insert(Candidates[T], T) end
            for Slot = 1, 4 do
                if Slot ~= T and Holds[Slot] ~= "" and Satisfies(Holds[Slot], Target) then table.insert(Candidates[T], Slot) end
            end
        end
    end
    table.sort(Order, function(A, B)
        if #Candidates[A] ~= #Candidates[B] then return #Candidates[A] < #Candidates[B] end
        return A < B
    end)
    local Assign, Used = { }, { }
    local function Try(T, Seen)
        for _, Slot in ipairs(Candidates[T]) do
            if not Seen[Slot] then
                Seen[Slot] = true
                if not Used[Slot] or Try(Used[Slot], Seen) then
                    Used[Slot], Assign[T] = T, Slot
                    return true
                end
            end
        end
        return false
    end
    for _, T in ipairs(Order) do Try(T, { }) end
    return Assign, Used
end

-- slot a raid unit from storage goes into (never one another target uses, never a favourite):
-- its own slot (unlocked, or locked and the coins are there), an empty one, another slot the
-- coins can unlock, and only once no slot is left to buy over a character no target wants (the
-- weakest) - a starter that is still the main is not thrown away for a Lv1 unit
function Plan.PlaceSpot(T, Data, Used)
    local Money = Currency("money", Data)
    local function Ok(Slot)
        local S = SlotData(Slot, Data)
        return S and not Used[Slot] and not S.Favourite and S or nil
    end
    local Own = Ok(T)
    if Own and (Own.Unlocked or Money >= UnlockCost(T)) then return T end
    for Slot = 1, 4 do local S = Ok(Slot) if S and S.Unlocked and S.Character == "" then return Slot end end
    for Slot = 1, 4 do local S = Ok(Slot) if S and not S.Unlocked and Money >= UnlockCost(Slot) then return Slot end end
    -- a slot still to buy: wait for the coins rather than overwrite a character
    for Slot = 1, 4 do local S = Ok(Slot) if S and not S.Unlocked then return nil end end
    local Best, BestRank = nil, math.huge
    for Slot = 1, 4 do
        local S = Ok(Slot)
        if S and S.Unlocked and RankOf(S.Character) < BestRank then Best, BestRank = Slot, RankOf(S.Character) end
    end
    return Best
end

-- slot a Lucky / Normal Spin rolls for an unmet target: unlocked (or one Plan.UnlockForSpin may
-- buy), not used by another target, spinnable - its own slot first
function Plan.SpinSpot(T, Data, Used)
    local Order = { T }
    for Slot = 1, 4 do if Slot ~= T then table.insert(Order, Slot) end end
    for _, Slot in ipairs(Order) do
        local S = SlotData(Slot, Data)
        if S and not Used[Slot] and (S.Unlocked or Plan.UnlockForSpin(Slot, Data)) and Plan.Spinnable(S) then return Slot end
    end
end

-- a slot Lucky / Normal Spin may roll over: not protected, not favourite (unless un-favouriting is on)
function Plan.Spinnable(S)
    return (not S.Favourite or Config.Summon.Unfavourite) and RankOf(S.Character) < (RarityRank[Config.Summon.Protect] or 99)
end

-- raid unit a target still waits for (not owned, not sitting in storage)
function Plan.RaidWanted(Data)
    local Assign = Plan.Assign(Data)
    for T = 1, 4 do
        local Id = RaidAlt(Config.Slots[T])
        if Id and not Assign[T] and not Owns(Id, Data) and Progress("storage." .. Id, Data) <= 0 then
            return Id
        end
    end
end

function Plan.Current(Data)
    Data = Data or AccountTable()
    if not Data then return nil end
    if Config.Force ~= "" then
        local Mode, Map, Act, Diff = Config.Force:match("^(%a+):(%a+):?(%d*):?(%d*)$")
        if Mode then
            return { Mode = Mode, Map = Map, Chapter = tonumber(Act) or 0, Difficulty = tonumber(Diff) or (Mode == "Raid" and 4 or 1),
                Key = Config.Force, Label = "Forced " .. Config.Force }
        end
    end
    local Main = Plan.Main(Data)
    local Level = Main and Grow.Level(Main, Data) or 1
    local Info = Main and Data.CharactersData and Data.CharactersData[Main]
    local Evolved = type(Info) == "table" and Info.IsUltimateUnlocked == true
    local RaidOk = Level >= (Config.Raid.MinLevel or 0) and (Evolved or Level >= (Config.Raid.MaxWait or 0))

    local function Raid(Map, Why)
        return { Mode = "Raid", Map = Map, Chapter = 0, Difficulty = 4, Key = "Raid:" .. Map, Label = "Raid " .. Map .. " (" .. Why .. ")" }
    end

    -- 1. a raid unit a slot asks for
    local Unit = Plan.RaidWanted(Data)
    if Unit and RaidOk and not Plan.Blocked("Raid:" .. RaidUnits[Unit], Level) then
        return Raid(RaidUnits[Unit], NameOf(Unit))
    end

    -- difficulty: highest the main's level reached and not blocked
    local Index = 1
    for I, Name in ipairs(DifficultyNames) do
        if Level >= (tonumber(Config.Farm.Difficulty[Name]) or math.huge) then Index = I end
    end
    local Unlocked = Progress("story." .. Config.Farm.Map:lower() .. ".cleared", Data) + 1
    local function Story(Act, Why)
        local I = Index
        while I > 1 and Plan.Blocked(("Story:%s:%d:%d"):format(Config.Farm.Map, Act, I), Level) do I = I - 1 end
        return {
            Mode = "Story", Map = Config.Farm.Map, Chapter = Act, Difficulty = I,
            Key = ("Story:%s:%d:%d"):format(Config.Farm.Map, Act, I),
            Label = ("Story Act %d %s (%s)"):format(Act, DifficultyNames[I], Why),
        }
    end

    -- 2. unlock every act first (Next carries the run from act to act)
    if Unlocked <= 2 then
        local P = Story(Unlocked, "unlock acts")
        P.Key, P.Next = ("Story:%s:progress:%d"):format(Config.Farm.Map, P.Difficulty), true
        return P
    end

    -- 3. materials for the first project that can be farmed right now (evolves, then Igris);
    --    a project short only on coins/gems is skipped - every stage pays those
    for _, Project in ipairs(Plan.Starter(Data) and { } or Grow.Projects(Data)) do
        local Missing = Project.Missing
        for _, Item in ipairs({ "115", "116", "117", "118", "119", "120" }) do
            if Missing[Item] and RaidOk and not Plan.Blocked("Raid:ShadowGate", Level) then return Raid("ShadowGate", "mats " .. Project.Name) end
        end
        if (Missing["113"] or Missing["114"]) and RaidOk and not Plan.Blocked("Raid:BathTub", Level) then
            return Raid("BathTub", "mats " .. Project.Name)
        end
        local Act = Grow.BestAct(Missing, DifficultyNames[Index], Unlocked)
        if Act then return Story(Act, "mats " .. Project.Name) end
    end

    -- 4. nothing left to chase / starter: gems (Shadow Gate 710 per clear vs Story 50-350 by difficulty)
    if RaidOk and not Plan.Blocked("Raid:ShadowGate", Level) then return Raid("ShadowGate", "gems") end
    return Story(3, "gems / xp")
end

-- a slot still waits for its raid unit (farming it or not yet placed from storage)
function Plan.UnitsPending(Data)
    local Assign = Plan.Assign(Data)
    for T = 1, 4 do
        local Id = RaidAlt(Config.Slots[T])
        if Id and not Assign[T] and not Owns(Id, Data) then return true end
    end
    return false
end

-- starter = slot 1 still misses its Lucky Spin target: every gem goes to spins, nothing is
-- spent on the characters passing through (they get rolled away)
function Plan.Starter(Data)
    if Carry.Child(Data) then return false end -- carried: the mother farms Jinwoo first
    -- the Lucky Spin starter (Cursed King) only matters until Sung Jinwoo is in (user 2026-10-10:
    -- it is the fallback for an account nobody carries); with him the run builds him, never
    -- turns every gem into spins for slot 1 again
    if Carry.ChildDone(Data) then return false end
    local Target = Config.Slots[1] or ""
    if Target == "" or not Rollable(Target) then return false end
    return Plan.Assign(Data)[1] == nil
end

-- may gems be turned into Lucky Spins now?
function Plan.Convert(Data)
    local Mode = Config.Summon.ConvertGems
    if Mode == true then return true end
    if Mode ~= "auto" and Mode ~= "starter" then return false end
    return Plan.Starter(Data)
end

-- coins Normal Spins may use now (0 before end game); the dearest next Igris level is kept back
function Plan.NormalBudget(Data)
    if Plan.UnitsPending(Data) or not Grow.EndGame(Data) then return 0 end
    local Keep = tonumber(Config.Summon.KeepMoney) or 0
    if Config.Lobby.Igris then
        for _, Next in ipairs(Grow.IgrisNodes()) do Keep = math.max(Keep, tonumber(Next.Cost.Money) or 0) end
    end
    return math.max(Currency("money", Data) - Keep, 0)
end

-- a locked slot with a Lucky Spin target is only bought at end game
-- (slot 4 is 1M coins - that money goes to Jinwoo / Hu Tao evolves first)
function Plan.UnlockForSpin(Slot, Data)
    return not Plan.UnitsPending(Data) and Grow.EndGame(Data) and Currency("money", Data) >= UnlockCost(Slot)
end

-- something in the lobby is worth a trip back (checked from the match too)
function Plan.LobbyWork(Data)
    Data = Data or AccountTable()
    if not Data then return false end
    local Code = Plan.PendingCode(Data)
    if Code then return "code " .. Code end
    local Spins = Currency("luckySpins", Data)
    local Gems = Currency("gems", Data) - (Config.Summon.KeepGems or 0)
    local EndGame = not Plan.UnitsPending(Data) and Grow.EndGame(Data)
    local Starter = Plan.Starter(Data)
    local CanSpin = (Starter and Spins + (Plan.Convert(Data) and math.floor(math.max(Gems, 0) / 100) or 0) >= (Config.Summon.SpinBatch or 10))
        or (not Starter and Spins >= 1)
        or (EndGame and (Currency("rolls", Data) >= 1 or Plan.NormalBudget(Data) >= (Config.Summon.NormalBatch or 100000)))

    local Assign, Used = Plan.Assign(Data)
    for T = 1, 4 do
        local Target = Config.Slots[T] or ""
        if Target ~= "" and not Assign[T] then
            local Unit = RaidAlt(Target)
            local Place = Unit and Progress("storage." .. Unit, Data) > 0 and Plan.PlaceSpot(T, Data, Used)
            if Place and (SlotData(Place, Data).Unlocked or Currency("money", Data) >= UnlockCost(Place)) then
                return NameOf(Unit) .. " ready to place"
            end
            local Spin = Rollable(Target) and CanSpin and Plan.SpinSpot(T, Data, Used)
            if Spin then return "spin slot " .. Spin end
        end
    end

    for _, Project in ipairs(Grow.Projects(Data)) do
        local Afford = not next(Project.Missing)
        for Key, Amount in pairs(Project.Currencies or { }) do
            if Currency(Key, Data) < Amount then Afford = false end
        end
        if Afford and not Starter and ((Project.Evolve and Config.Lobby.Evolve) or (Project.Igris and Config.Lobby.Igris) or Project.Craft) then
            return "upgrade " .. Project.Name
        end
    end
    if (Saved.SinceLobby or 0) >= (Config.Lobby.MinGap or 2) then
        for _, Entry in ipairs(Grow.Owned(Data)) do
            local Node, Tokens = Grow.NextSkill(Entry.Id, Data)
            if Node and Node.Cost <= Tokens then return ("skill %s %s %d"):format(NameOf(Entry.Id), Node.Branch, Node.Tier) end
        end
    end
    local Trait = Plan.TraitWanted(Data)
    if Trait then return "trait " .. NameOf(Trait) end
    local Next = Plan.Current(Data)
    if Next and Next.Key ~= Saved.PlanKey then return "next stage: " .. Next.Label end
    if (Saved.SinceLobby or 0) >= (Config.Lobby.Every or 10) then return "claims" end
    return false
end

local function UpdateSlotStatus()
    local Data = AccountTable()
    if not Data then return end
    local _, Used = Plan.Assign(Data)
    for Slot = 1, 4 do
        local S = SlotData(Slot, Data)
        -- the target this slot meets, else the one set for this slot
        local Target = Used[Slot] and Config.Slots[Used[Slot]] or Config.Slots[Slot] or ""
        local Text
        if not S or not S.Unlocked then
            Text = "locked"
        else
            Text = S.Character ~= "" and ("%s Lv%d"):format(NameOf(S.Character), Grow.Level(S.Character, Data)) or "empty"
            if S.Favourite then Text = Text .. " *" end
        end
        local Done = Used[Slot] ~= nil
        Status.Slots[Slot] = ("%s  ->  %s%s"):format(Text, Target ~= "" and Target or "-", Target ~= "" and (Done and "  OK" or "") or "")
    end
    local C = Data.currencies or { }
    Status.Stats = {
        ("Player Lv%d  Coins %s  Gems %s  Lucky %s"):format(Plan.PlayerLevel(Data),tostring(C.money or 0), tostring(C.gems or 0), tostring(C.luckySpins or 0)),
        ("Pity M %s/175 A %s/350  Jinwoo %s/32"):format(tostring(C.mythicPity or 0), tostring(C.arcanePity or 0), tostring(Progress("raidPity.sung_jinwoo", Data))),
    }
    local Ok, Next = pcall(Plan.Current, Data)
    Status.Plan = Ok and Next and Next.Label or ""
    local Main = Plan.Main(Data)
    Status.Main = Main and ("%s Lv%d"):format(NameOf(Main), Grow.Level(Main, Data)) or nil
end

---- ============ Lobby ============ ----

local Lobby = { }
local RequestId = 0

local function Request(SendName, ReplyName, Data, Packets)
    Packets = Packets or Lobby.Packets
    RequestId = RequestId % 65535 + 1
    local Id = RequestId
    Data.requestId = Id
    local Reply = nil
    local Hook = Packets[ReplyName]:on(function(Result)
        if type(Result) == "table" and Result.requestId == Id then Reply = Result end
    end)
    Packets[SendName]:fire(Data)
    local Waited = 0
    while not Reply and Waited < 6 do Waited = Waited + task.wait(0.1) end
    Unhook(Hook)
    return Reply
end

-- packets with no requestId: fire and take the next reply (the game waits the same way)
local function Await(SendName, ReplyName, Value)
    local Reply = nil
    local Hook = Lobby.Packets[ReplyName]:on(function(Result)
        if type(Result) == "table" then Reply = Result end
    end)
    Lobby.Packets[SendName]:fire(Value)
    local Waited = 0
    while not Reply and Waited < 5 do Waited = Waited + task.wait(0.1) end
    Unhook(Hook)
    return Reply
end

local function RedeemCodes()
    local Data = AccountTable()
    local Level = Plan.PlayerLevel(Data)
    local Last = nil
    local Hook = Lobby.Packets.showNotification:on(function(Result)
        -- "Code \"X\" redeemed!" / "You have already used this code." / level refusals
        if type(Result) == "table" and type(Result.text) == "string" and Result.text:lower():find("code") then Last = Result.text end
    end)
    local Fresh, Gated = 0, { }
    for Code, Need in pairs(Plan.Codes()) do
        if not Saved.Codes[Code] and Live() then
            if Level < Need then
                table.insert(Gated, ("%s Lv%d"):format(Code, Need))
            else
                Say("Codes", "Redeeming " .. tostring(Code))
                Last = nil
                Lobby.Packets.redeemCode:fire(Code)
                local Waited = 0
                while not Last and Waited < 3 do Waited = Waited + task.wait(0.1) end
                local Text = Last and Last:lower() or ""
                if Text:find("redeemed") then Fresh = Fresh + 1 end
                -- done for good only when redeemed / already used / gone; anything else (level,
                -- no reply) = try again next visit
                if Text:find("redeemed") or Text:find("already") or Text:find("invalid") or Text:find("expired")
                    or Text:find("not exist") or Text:find("not found") then
                    Saved.Codes[Code] = true
                else
                    -- no answer / unknown refusal: retried every visit, but only worth a trip
                    -- back to the lobby again once the player level has gone up
                    Saved.CodeTried[Code] = Level
                    if Last then Note(("Code %s: %s"):format(Code, Last)) end
                end
                task.wait(0.4)
            end
        end
    end
    Unhook(Hook)
    Save()
    if Fresh > 0 then Note(("Codes: %d redeemed"):format(Fresh)) end
    if #Gated > 0 then Note("Codes waiting for player level: " .. table.concat(Gated, ", ")) end
end

local function Claimable(Group)
    local List = { }
    if type(Group) ~= "table" or type(Group.completed) ~= "table" then return List end
    local Claimed = type(Group.claimed) == "table" and Group.claimed or { }
    for Key, Value in pairs(Group.completed) do
        local Id = type(Key) == "string" and Key or (type(Value) == "string" and Value) or nil
        if Id and Value and not Claimed[Id] and not table.find(Claimed, Id) then table.insert(List, Id) end
    end
    return List
end

local function ClaimAll()
    Say("Claims", "Daily / quests / achievements / level road")
    local Data = AccountTable()
    if not Data then return end
    local Before = Currency("gems", Data)
    local Daily = Data.dailyReward and Data.dailyReward.rewards
    for Day, State in pairs(type(Daily) == "table" and Daily or { }) do
        if State == "available" and tonumber(Day) then
            pcall(function() Lobby.Packets.claimDailyReward:fire(tonumber(Day)) end)
            task.wait(0.8)
        end
    end
    for _, Id in ipairs(Claimable(Data.quests)) do
        Request("claimQuestReward", "questActionResult", { questId = Id })
        task.wait(0.4)
    end
    for _, Id in ipairs(Claimable(Data.achievements)) do
        Request("claimAchievementReward", "achievementActionResult", { achievementId = Id })
        task.wait(0.4)
    end
    local Progression = TryRequire("global", "utils", "levelProgression")
    local Milestones = TryRequire("assets", "config", "levelMilestoneConfig")
    if Progression and Milestones then
        local Ok, P = pcall(Progression.getProgress, Data.currencies and Data.currencies.xp or 0)
        local Level = Ok and type(P) == "table" and tonumber(P.level) or 0
        local Claimed = Data.claimedLevelMilestones or { }
        for _, Milestone in ipairs(Milestones.order or { }) do
            if Milestone > Level then break end
            if not Claimed[tostring(Milestone)] then
                Request("claimLevelMilestone", "levelMilestoneClaimed", { level = Milestone })
                task.wait(0.4)
            end
        end
    end
    local Gained = Currency("gems") - Before
    if Gained > 0 then Note("Claims: +" .. Gained .. " gems") end
end

local function Perks()
    Lobby.Perks = Lobby.Perks or TryRequire("global", "utils", "GamepassPerks")
    return Lobby.Perks
end

local function RollCooldown()
    local Ok, Owned = pcall(function() return Perks().Owns(LocalPlayer, "InstantSpins") end)
    return (Ok and Owned) and 1.05 or 1.8
end

local function SpinCost()
    local Ok, Value = pcall(function() return Perks().GetSpinCost(LocalPlayer, 100) end)
    return (Ok and tonumber(Value) and Value > 0) and Value or 100
end

local function Favourite(Slot)
    if not Config.Summon.Favourite then return end
    local S = SlotData(Slot)
    if S and not S.Favourite then
        Request("setCharacterSlotFavourite", "characterSlotActionResult", { slot = Slot, favourite = true })
    end
end

local function UnlockSlot(Slot)
    local S = SlotData(Slot)
    if not S or S.Unlocked then return S and S.Unlocked end
    if Currency("money") < UnlockCost(Slot) then return false end
    Say("Slots", "Unlocking slot " .. Slot)
    local Reply = Request("unlockCharacterSlot", "characterSlotActionResult", { slot = Slot })
    Note(("Unlock slot %d: %s"):format(Slot, Reply and (Reply.success and "ok" or tostring(Reply.reason)) or "no reply"))
    task.wait(0.5)
    S = SlotData(Slot)
    return S and S.Unlocked
end

-- one spin into Slot; false = cannot spin any more right now
-- Lucky Spins held -> Lucky / starter -> gems into Lucky Spins / end game -> Normal (dice, then 500 coins)
local function SpinOnce(Slot, Target)
    local Data = AccountTable()
    local Spin = { spinType = "Lucky", paymentCurrency = "luckySpins", slot = Slot }
    if Currency("luckySpins", Data) < 1 then
        local Cost = SpinCost()
        local Amount = math.floor((Currency("gems", Data) - (Config.Summon.KeepGems or 0)) / Cost)
        if Plan.Convert(Data) and Amount >= 1 then
            Say("Summon", ("Converting %d gems -> %d Lucky Spins"):format(Amount * Cost, Amount))
            Request("convertGemsToLuckySpins", "luckySpinConversionResult", { amount = Amount })
            task.wait(0.5)
            if Currency("luckySpins") < 1 then return false, "gem conversion failed" end
        elseif Currency("rolls", Data) >= 1 and not Plan.UnitsPending(Data) and Grow.EndGame(Data) then
            Spin = { spinType = "Normal", paymentCurrency = "rolls", slot = Slot }
        elseif Plan.NormalBudget(Data) >= 500 then
            Spin = { spinType = "Normal", paymentCurrency = "money", slot = Slot }
        else
            return false, "out of spins"
        end
    end

    local SentAt = os.clock()
    local Reply = Request("rollCharacter", "characterRolled", Spin)
    local Reason = Reply and tostring(Reply.reason or ""):lower() or ""
    if Reply and Reply.success then
        Lobby.Spins = (Lobby.Spins or 0) + 1
        Say("Summon", ("Slot %d %s #%d: %s (%s) -- want %s"):format(Slot, Spin.spinType, Lobby.Spins, NameOf(Reply.character), tostring(Reply.rarity), Target))
        if RankOf(Reply.character) >= 3 then Note(("Slot %d rolled %s (%s)"):format(Slot, NameOf(Reply.character), tostring(Reply.rarity))) end
    elseif Reply and (Reason:find("cooldown") or Reason:find("wait")) then
        SentAt = os.clock() - RollCooldown() + 0.2
    elseif Reply then
        return false, tostring(Reply.reason)
    end
    task.wait(math.max(RollCooldown() + 0.1 - (os.clock() - SentAt), 0))
    return true
end

-- every target not met in any slot: raid unit waiting in storage -> place it into a slot no
-- other target uses / rollable target -> Lucky Spin such a slot; a met target's slot is favourited
local function FillSlots()
    for T = 1, 4 do
        local Target = Config.Slots[T] or ""
        local Assign, Used = Plan.Assign(AccountTable())
        if Target ~= "" and Live() and not Assign[T] then
            local Unit = RaidAlt(Target)
            if Unit and Progress("storage." .. Unit, AccountTable()) > 0 then
                local Slot = Plan.PlaceSpot(T, AccountTable(), Used)
                if Slot and UnlockSlot(Slot) then
                    Say("Slots", ("Placing %s into slot %d"):format(NameOf(Unit), Slot))
                    local Reply = Request("placeStoredUnit", "storedUnitPlaced", { character = Unit, slot = Slot })
                    Note(("Place %s -> slot %d: %s"):format(NameOf(Unit), Slot, Reply and (Reply.success == false and tostring(Reply.reason) or "ok") or "no reply"))
                    task.wait(0.5)
                end
                Assign, Used = Plan.Assign(AccountTable())
            end
            local Slot = not Assign[T] and Rollable(Target) and not Carry.Child() and Plan.SpinSpot(T, AccountTable(), Used)
            local S = Slot and SlotData(Slot)
            -- a locked Lucky Spin slot (slot 4 LYTH) is bought only at end game
            if S and not S.Unlocked and Plan.UnlockForSpin(Slot, AccountTable()) then
                UnlockSlot(Slot)
                S = SlotData(Slot)
            end
            while S and S.Unlocked and Live() do
                if Satisfies(S.Character, Target) then break end
                if S.Favourite then
                    if not Config.Summon.Unfavourite then break end
                    Request("setCharacterSlotFavourite", "characterSlotActionResult", { slot = Slot, favourite = false })
                    Note(("Slot %d: un-favourited %s to re-roll"):format(Slot, NameOf(S.Character)))
                    task.wait(0.4)
                    S = SlotData(Slot)
                    if not S or S.Favourite then break end
                end
                if RankOf(S.Character) >= (RarityRank[Config.Summon.Protect] or 99) then
                    Note(("Slot %d holds %s - protected"):format(Slot, NameOf(S.Character)))
                    break
                end
                UpdateSlotStatus()
                local Ok, Why = SpinOnce(Slot, Target)
                if not Ok then
                    Note(("Slot %d: %s"):format(Slot, Why))
                    break
                end
                S = SlotData(Slot)
                if S and Satisfies(S.Character, Target) then Note(("Slot %d done: %s"):format(Slot, NameOf(S.Character))) end
            end
        end
        Assign = Plan.Assign(AccountTable())
        if Assign[T] then Favourite(Assign[T]) end
    end
end

local function BuySkills()
    local SkillPackets = TryRequire("lobby", "modules", "skillTree", "skillTreePackets")
    if not SkillPackets then return end
    for _, Entry in ipairs(Grow.Owned(AccountTable())) do
        for _ = 1, 25 do
            if not Live() then return end
            local Node, Tokens = Grow.NextSkill(Entry.Id, AccountTable())
            if not (Node and Node.Cost <= Tokens) then break end
            Say("Skills", ("%s %s %d (%d tokens)"):format(NameOf(Entry.Id), Node.Branch, Node.Tier, Tokens))
            local Reply = Request("purchaseCharacterSkill", "characterSkillPurchaseResult",
                { character = Entry.Id, branch = Node.Branch, tier = Node.Tier }, SkillPackets)
            if not (Reply and Reply.success) then
                Note(("Skill %s %s %d: %s"):format(NameOf(Entry.Id), Node.Branch, Node.Tier, Reply and tostring(Reply.reason) or "no reply"))
                break
            end
            Note(("Skill %s %s %d"):format(NameOf(Entry.Id), Node.Branch, Node.Tier))
            task.wait(0.4)
        end
    end
end

-- materials every project (evolves + Igris) still misses, merged
local function MissingAll(Data)
    local All = { }
    for _, Project in ipairs(Data and Grow.Projects(Data) or { }) do
        for Item, Amount in pairs(Project.Missing) do All[Item] = (All[Item] or 0) + Amount end
    end
    return All
end

-- coins -> missing materials, then spare materials -> missing ones
local function ShopMaterials()
    local Shop = Grow.Shop
    local Data = AccountTable()
    if Data and Plan.Starter(Data) then return end -- slot 1 not settled: nothing worth materials yet
    if not (Shop and Data and next(MissingAll(Data))) then return end
    local Day = Shop.GetDay(workspace:GetServerTimeNow())

    if Config.Lobby.Shop then
        for Item, Missing in pairs(MissingAll(Data)) do
            local Price = Shop.GetPrice(Item)
            if Price and Shop.IsInStock(Item, Day) then
                local Bought = Progress(Shop.GetKey(Day, Item), Data)
                local Amount = math.min(Missing, math.max(Shop.GetCap(Item) - Bought, 0), math.floor(Currency("money", Data) / Price))
                if Amount > 0 then
                    local Reply = Request("buyMaterial", "materialShopResult", { itemId = Item, amount = Amount })
                    Note(("Shop %dx %s: %s"):format(Amount, Grow.ItemName(Item), Reply and Reply.success and "ok" or "failed"))
                    task.wait(0.5)
                    Data = AccountTable()
                end
            end
        end
    end

    if Config.Lobby.Convert then
        -- keep what every unevolved owned character still needs
        for _ = 1, 10 do
            Data = AccountTable()
            -- evolves, Igris levels and the gear still to craft keep what they use (a craft
            -- recipe left out here got converted back and forth: Broken Blade <-> Mana Feather)
            local Reserved = Grow.Reserved(Data)
            for _, Target in ipairs(Grow.CraftTargets(Data)) do
                local Pick = Grow.BestGear()[Target.Slot]
                for Item, Amount in pairs(Pick and Pick.Recipe or { }) do Reserved[Item] = (Reserved[Item] or 0) + Amount end
            end
            -- Shadow Gate materials feed the Igris tree too - never convert them away
            for Item = 115, 120 do Reserved[tostring(Item)] = math.huge end
            local Bag = Data and Data.material or { }
            local Done = false
            for Item, Missing in pairs(MissingAll(Data)) do
                for _, Source in ipairs(Shop.GetSources(Item) or { }) do
                    local Spare = (tonumber(Bag[tostring(Source.Id)]) or 0) - (Reserved[tostring(Source.Id)] or 0)
                    local Amount = math.min(Missing, math.floor(Spare / Source.Rate), Shop.MaxConvert or 100)
                    if Amount > 0 then
                        local Reply = Request("convertMaterial", "materialShopResult", { source = tostring(Source.Id), target = Item, amount = Amount })
                        Note(("Convert %dx %s -> %dx %s: %s"):format(Amount * Source.Rate, Grow.ItemName(Source.Id), Amount, Grow.ItemName(Item), Reply and Reply.success and "ok" or "failed"))
                        Done = Reply and Reply.success
                        task.wait(0.5)
                        break
                    end
                end
                if Done then break end
            end
            if not Done then break end
        end
    end
end

local function EvolveAll()
    if Plan.Starter(AccountTable()) then return end -- gems are for Lucky Spins until slot 1 is settled
    for _, Entry in ipairs(Grow.Owned(AccountTable())) do
        local Data = AccountTable()
        local Cost = Grow.Cost(Entry.Id, Data)
        if Cost and Grow.Affordable(Entry.Id, Data) and Live() then
            Say("Evolve", NameOf(Entry.Id) .. " " .. Cost.Step)
            local Reply
            if Cost.Monarch then
                Reply = Await("monarchEvolve", "monarchEvolveResult", Cost.Monarch)
            else
                Reply = Await("evolveCharacter", "evolveCharacterResult", Entry.Id)
            end
            local Ok = Reply and (Reply.success == true or Reply.status == "success")
            Note(("Evolve %s %s: %s"):format(NameOf(Entry.Id), Cost.Step, Ok and "ok" or tostring(Reply and (Reply.reason or Reply.status) or "no reply")))
            task.wait(0.8)
        end
    end
end

-- Igris tree (Shadow Monarch stage II+): cheapest next node while affordable
local function UpgradeIgris()
    local Path = Grow.Path
    if not (Config.Lobby.Igris and Path and Path.IgrisTree and Grow.Stage() >= 2) then return end
    local Nodes = { "Blade", "Command", "Speed", "Loyalty" }
    for _ = 1, 20 do
        local Data = AccountTable()
        local Best = nil
        for _, Node in ipairs(Nodes) do
            local Ok, Level = pcall(Path.GetNodeLevel, Account.getLocalPlayerAccount(), Node)
            Level = Ok and tonumber(Level) or 0
            local Cost = Path.IgrisTree.Nodes[Node] and Path.IgrisTree.Nodes[Node].Levels[Level + 1]
            if Cost then
                local Afford = Currency("money", Data) >= (tonumber(Cost.Money) or 0)
                for Item, Amount in tostring(Cost.Materials or ""):gmatch("(%d+),(%d+)") do
                    if (tonumber(Data.material and Data.material[Item]) or 0) < tonumber(Amount) then Afford = false end
                end
                if Afford and (not Best or (Cost.Money or 0) < (Best.Cost.Money or 0)) then Best = { Node = Node, Cost = Cost } end
            end
        end
        if not Best or not Live() then return end
        local Reply = Await("igrisUpgrade", "igrisUpgradeResult", Best.Node)
        Note(("Igris %s: %s"):format(Best.Node, Reply and Reply.success and ("lv " .. tostring(Reply.level)) or tostring(Reply and Reply.reason or "no reply")))
        if not (Reply and Reply.success) then return end
        task.wait(1)
    end
end

-- reroll traits until a kept one (main first) - 1.85s between rolls like the game's button
local function RollTraits()
    local Names = { }
    for Name, Id in pairs(TraitIds) do Names[Id] = Name end
    local Config2 = TryRequire("assets", "config", "Traits", "traitConfig")
    for _, Entry in ipairs(Config2 or { }) do
        if type(Entry) == "table" and Entry.Id then Names[Entry.Id] = Entry.Name end
    end
    for _ = 1, 2000 do
        if not Live() then return end
        local Data = AccountTable()
        local Id = Plan.TraitWanted(Data)
        if not Id then return end
        local SentAt = os.clock()
        local Reply = Request("rollTrait", "traitRolled", { character = Id })
        local Reason = Reply and tostring(Reply.reason or ""):lower() or ""
        if Reply and Reply.success then
            local Got = tonumber(Reply.traitId) or 0
            Say("Traits", ("%s: %s (%d rerolls left)"):format(NameOf(Id), Names[Got] or ("#" .. Got), Currency("traitRerolls") ))
            if Plan.TraitKeep(Got) then Note(("Trait %s rolled %s"):format(NameOf(Id), Names[Got] or Got)) end
        elseif Reply and not (Reason:find("wait") or Reason:find("cooldown")) then
            return Note(("Trait %s: %s"):format(NameOf(Id), tostring(Reply.reason)))
        end
        task.wait(math.max(1.9 - (os.clock() - SentAt), 0))
    end
end

-- craftAccessory(recipe key "1".."14") - the answer only comes as showNotification text;
-- done = account.accessory[item] went up
local function CraftGear()
    for _, Target in ipairs(Grow.CraftTargets(AccountTable())) do
        if not Live() then return end
        if not next(Target.Missing) then
            Say("Craft", ("%s (%s)"):format(Target.Name, Target.Slot))
            local Notice = nil
            local Hook = Lobby.Packets.showNotification:on(function(Result)
                if type(Result) == "table" then Notice = Result.text end
            end)
            Lobby.Packets.craftAccessory:fire(Target.Key)
            local Waited, Done = 0, false
            while Waited < 4 and not Done do
                Waited = Waited + task.wait(0.2)
                local Data = AccountTable()
                Done = (tonumber(Data and Data.accessory and Data.accessory[Target.Id]) or 0) > 0
            end
            Unhook(Hook)
            Note(("Craft %s (%s): %s"):format(Target.Name, Target.Slot, Done and "ok" or tostring(Notice or "no reply")))
            task.wait(0.5)
        end
    end
end

-- best Damage% title owned (equipTitle toggles: only fire when another one is worn) and the
-- best damage accessory per slot (Head/Face/Neck/Back)
local function EquipGear()
    if not Config.Gear then return end
    local Data = AccountTable()
    if not Data then return end
    local Buffs = TryRequire("global", "enums", "buffEnum")
    local Titles = TryRequire("assets", "config", "titleConfig")
    if Titles then
        local Best, BestDamage, BestTotal = nil, -1, -1
        for Id, Owned in pairs(Data.title or { }) do
            local Entry = Owned and Titles[tostring(Id)]
            if type(Entry) == "table" then
                local Damage, Total = 0, 0
                for _, Buff in ipairs(Entry.Buffs or { }) do
                    local Value = tonumber(Buff.Percent or Buff.Amount) or 0
                    Total = Total + Value
                    if Buff.Percent and (Buff.Type == "Damage" or (Buffs and Buff.Type == Buffs.Damage)) then Damage = Damage + Value end
                end
                if Damage > BestDamage or (Damage == BestDamage and Total > BestTotal) then
                    Best, BestDamage, BestTotal = tostring(Id), Damage, Total
                end
            end
        end
        if Best and tostring(Data.equippedTitle) ~= Best then
            Lobby.Packets.equipTitle:fire(Best)
            Note(("Title %s (+%d%% dmg)"):format(tostring(Titles[Best].Name or Best), BestDamage))
            task.wait(0.5)
        end
    end
    local Items = TryRequire("assets", "config", "accessoryConfig")
    local Slots = TryRequire("assets", "config", "accessorySlotConfig")
    if Items and Slots then
        local Score = Grow.GearScore
        local Worn = type(Data.equippedAccessories) == "table" and Data.equippedAccessories or { }
        local Best = { }
        for RawId, Info in pairs(Items) do
            local Id = tostring(RawId)
            local Ok, Slot = pcall(Slots.GetSlot, Id)
            if Ok and Slot and type(Info) == "table" and (tonumber(Data.accessory and Data.accessory[Id]) or 0) > 0 then
                if not Best[Slot] or Score(Info) > Score(Best[Slot].Info) then Best[Slot] = { Id = Id, Info = Info } end
            end
        end
        for Slot, Pick in pairs(Best) do
            if tostring(Worn[Slot] or "") ~= Pick.Id then
                Lobby.Packets.setEquippedAccessory:fire(Pick.Id)
                Note(("Accessory %s -> %s"):format(tostring(Pick.Info.Name or Pick.Id), tostring(Slot)))
                task.wait(0.5)
            end
        end
    end
end

-- game slots 1-2 = two best owned characters, the main (highest level) leads
local function EquipTeam()
    local Data = AccountTable()
    if not Data then return end
    local List = Grow.Owned(Data)
    local Main = Plan.Main(Data)
    if List[3] and Main and List[1].Id ~= Main and List[2].Id ~= Main then
        for I, Entry in ipairs(List) do if Entry.Id == Main then table.insert(List, 2, table.remove(List, I)) break end end
    end
    for I, Entry in ipairs(List) do
        if Entry.Id == Main and I == 2 then List[1], List[2] = List[2], List[1] end
    end
    -- Sung Jinwoo owned: he is always team slot 1, so every match starts as him (user 2026-10-10)
    local Jinwoo = false
    for I, Entry in ipairs(List) do
        if Entry.Id == "sung_jinwoo" then
            Jinwoo = true
            if I > 1 then table.insert(List, 1, table.remove(List, I)) end
            break
        end
    end
    local function Now()
        local Equipped = (AccountTable() or Data).EquippedCharacterSlots or { }
        return { tonumber(Equipped.Slot1), tonumber(Equipped.Slot2) }
    end
    local Want, Current = { List[1] and List[1].Slot, List[2] and List[2].Slot }, Now()
    -- otherwise either order is fine: skip a swap that changes nothing
    if not Jinwoo and (Want[1] == Current[2] or Want[2] == Current[1]) then Want[1], Want[2] = Want[2], Want[1] end
    for GameSlot = 1, 2 do
        -- equipping a unit already in the other team slot swaps the two (tested 2026-10-10)
        if Want[GameSlot] and Now()[GameSlot] ~= Want[GameSlot] then
            Say("Team", ("Equipping slot %d -> team %d"):format(Want[GameSlot], GameSlot))
            Request("equipCharacterSlot", "characterSlotActionResult", { slot = Want[GameSlot], gameSlot = GameSlot })
            task.wait(0.5)
        end
    end
end

local Join = { ClientStatus = "idle", Hooks = { } }

-- stand point inside a room's JoinHitbox (the server checks the position)
local function RoomSpot(Room, Hrp)
    local Folder = workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("QuqueRooms")
    local Hitbox = Folder and Folder:FindFirstChild(tostring(Room)) and Folder[tostring(Room)]:FindFirstChild("JoinHitbox", true)
    if not Hitbox then return nil end
    local Spot = Hitbox.Position
    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = { LocalPlayer.Character, Hitbox }
    local Hit = workspace:Raycast(Hitbox.Position, Vector3.new(0, -(Hitbox.Size.Y / 2 + 6), 0), Params)
    if Hit then
        local Hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        Spot = Hit.Position + Vector3.new(0, (Hum and Hum.HipHeight or 2) + Hrp.Size.Y / 2, 0)
    end
    return Hitbox, Spot
end

local function HoldAt(Spot)
    local Now = Root()
    if Now and (Now.Position - Spot).Magnitude > 2.5 then
        Now.AssemblyLinearVelocity = Vector3.zero
        Now.CFrame = CFrame.new(Spot)
    end
end

-- Options (mother): { Plan = stage, Players = room size } -> public room, start once it is full
local function JoinStep(Rooms, Options)
    if Join.ClientStatus == "inQuque" or Join.ClientStatus == "teleporting" then
        if Join.StatusAt and os.clock() - Join.StatusAt > 45 then
            pcall(function() Lobby.Packets.leaveQuque:fire() end)
            Join.ClientStatus, Join.StatusAt = "idle", nil
            Say("Join", "Teleport failed - retrying")
            task.wait(3)
        else
            Say("Join", Join.ClientStatus == "teleporting" and "Teleporting to match" or "In queue")
        end
        return
    end

    local Hrp = Root()
    if not Hrp then return Say("Join", "Waiting for character") end

    local function Idle(Index)
        local Store = Rooms:getStore("room " .. Index)
        return Store and Read(Store.state.status) == "idle"
    end
    local Room = Join.LastRoom and Idle(Join.LastRoom) and Join.LastRoom or nil
    for Index = 1, 6 do
        if Room then break end
        if Idle(Index) then Room = Index end
    end
    local Folder = Room and workspace:FindFirstChild("Systems") and workspace.Systems:FindFirstChild("QuqueRooms")
    local Hitbox = Folder and Folder:FindFirstChild(tostring(Room)) and Folder[tostring(Room)]:FindFirstChild("JoinHitbox", true)
    if not Hitbox then return Say("Join", "All rooms busy") end
    Join.LastRoom = Room

    local Spot = Hitbox.Position
    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = { LocalPlayer.Character, Hitbox }
    local Hit = workspace:Raycast(Hitbox.Position, Vector3.new(0, -(Hitbox.Size.Y / 2 + 6), 0), Params)
    if Hit then
        local Hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        Spot = Hit.Position + Vector3.new(0, (Hum and Hum.HipHeight or 2) + Hrp.Size.Y / 2, 0)
    end
    local Stand = CFrame.new(Spot)
    local function Hold()
        local Now = Root()
        if Now and (Now.Position - Spot).Magnitude > 2.5 then
            Now.AssemblyLinearVelocity = Vector3.zero
            Now.CFrame = Stand
        end
    end

    Say("Join", "Entering room " .. Room)
    Join.RoomNumber = nil
    Hrp.AssemblyLinearVelocity = Vector3.zero
    Hrp.CFrame = Stand
    local Waited = 0
    while not Join.RoomNumber and Waited < 5 do
        Waited = Waited + task.wait(0.1)
        Hold()
    end
    if not Join.RoomNumber then
        -- window left open by an earlier run (re-inject while standing in a room) = server never
        -- sends toggleQuqueWindow again -> close it like the X button and step out of the box
        Say("Join", "Room did not open - retrying")
        pcall(function() Lobby.Packets.playerCloseQuqueWindow:fire() end)
        pcall(function() Lobby.Packets.leaveQuque:fire() end)
        local Now = Root()
        if Now then Now.CFrame = Stand + Vector3.new(0, 0, Hitbox.Size.Z / 2 + 12) end
        task.wait(2)
        return
    end

    local P = Options and Options.Plan or Plan.Current()
    if not P then return Say("Join", "No plan (account not loaded)") end
    Lobby.Packets.createQuque:fire({
        gamemode = P.Mode, map = P.Map, chapter = P.Chapter, difficulty = P.Difficulty,
        maxPlayers = Options and Options.Players or 1, friendsOnly = not Options, roomNumber = Join.RoomNumber,
    })
    Saved.PlanKey, Saved.PlanLabel = P.Key, P.Label
    Save()
    Say("Join", P.Label)

    Waited = 0
    while Join.ClientStatus ~= "inQuque" and Join.ClientStatus ~= "teleporting" and Waited < 6 do
        Waited = Waited + task.wait(0.2)
        Hold()
    end
    if Join.ClientStatus ~= "inQuque" and Join.ClientStatus ~= "teleporting" then
        pcall(function() Lobby.Packets.playerCloseQuqueWindow:fire() end)
        Note("Queue rejected: " .. P.Label)
        task.wait(3)
    elseif Join.ClientStatus == "inQuque" then
        if Options then
            -- carry: tell the children which room (next report), wait for them to walk in
            Carry.Room = Room
            local Store = Rooms:getStore("room " .. Room)
            local Since = os.clock()
            local Full = false
            while Live() and Join.ClientStatus == "inQuque" and os.clock() - Since < 90 do
                Carry.Urgent()
                local Players = Store and tonumber(Read(Store.state.players)) or 0
                Say("Carry", ("Room %d open - kaitan in %d/%d"):format(Room, math.max(Players - 1, 0), Options.Players - 1))
                if Players >= Options.Players then Full = true break end
                Hold()
                task.wait(0.5)
            end
            if not Full then
                -- never start without the whole group: close the room and gather again
                if Join.ClientStatus == "inQuque" then pcall(function() Lobby.Packets.leaveQuque:fire() end) end
                Note("Carry: kaitan did not enter the room - reopening")
                Carry.Room, Carry.GatherSince = nil, nil
                task.wait(3)
                return
            end
        end
        task.wait(0.3)
        pcall(function() Lobby.Packets.startQuqueNow:fire() end)
        Carry.Room, Carry.GatherSince = nil, nil
    end
end

-- mother: gather the children in this server, open a Shadow Gate room for them, start when full
local function MotherStep(Rooms)
    Carry.Urgent()
    if Join.ClientStatus == "inQuque" or Join.ClientStatus == "teleporting" then return JoinStep(Rooms) end
    local Kids = Carry.Pending()
    local Here, Idle = 0, 0
    for _, Kid in ipairs(Kids) do
        if Kid.farming == false then Idle = Idle + 1 end
        if Kid.farming ~= false and tostring(Kid.jobId) == game.JobId and tostring(Kid.placeId) == tostring(LobbyPlaceId) then Here = Here + 1 end
    end
    -- lobby servers hold 20 and most are nearly full: no room for the children = move to a quiet one
    local Free = Players.MaxPlayers - #Players:GetPlayers()
    local Http = request or http_request or (syn and syn.request) or (http and http.request)
    if Free < #Kids - Here and Http and os.clock() - (Carry.MovedAt or -1e9) > 60 then
        Carry.MovedAt = os.clock()
        local Ok, Response = pcall(Http, { Method = "GET",
            Url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=25&sortOrder=Asc&excludeFullGames=true"):format(LobbyPlaceId) })
        local Decoded, Data = pcall(function() return HttpService:JSONDecode(Response.Body) end)
        for _, Server in ipairs(Ok and Decoded and type(Data) == "table" and Data.data or { }) do
            if Server.id ~= game.JobId and (tonumber(Server.maxPlayers) or 0) - (tonumber(Server.playing) or 99) >= #Kids + 2 then
                Note(("Carry: this server has room for %d - moving to a quieter one"):format(Free))
                pcall(TeleportService.TeleportToPlaceInstance, TeleportService, LobbyPlaceId, Server.id, LocalPlayer)
                return Say("Carry", "Moving to a quieter server for the kaitan")
            end
        end
    end
    -- the group always forms first: no room (and no solo match) until every kaitan is here;
    -- after 3 minutes go with the ones that made it, never with none
    Carry.GatherSince = Carry.GatherSince or os.clock()
    local Waited = os.clock() - Carry.GatherSince
    if Here < #Kids and (Here == 0 or Waited < 180) then
        return Say("Carry", ("Grouping - kaitan in this server %d/%d%s  ·  %ds"):format(Here, #Kids,
            Idle > 0 and ("  ·  %d waiting for Start farm"):format(Idle) or "", math.floor(Waited)))
    end
    if Here < #Kids then
        Saved.CarrySkip = type(Saved.CarrySkip) == "table" and Saved.CarrySkip or { }
        local Fresh = false
        for _, Kid in ipairs(Kids) do
            local Id = tostring(Kid.id)
            if not (Kid.farming ~= false and tostring(Kid.jobId) == game.JobId) and (tonumber(Saved.CarrySkip[Id]) or 0) < os.time() then
                Saved.CarrySkip[Id], Fresh = os.time() + 600, true
            end
        end
        if Fresh then
            Save()
            Note(("Carry: going with %d/%d - the rest are skipped for 10 minutes"):format(Here, #Kids))
        end
    end
    JoinStep(Rooms, {
        Players = 1 + Here,
        Plan = { Mode = "Raid", Map = "ShadowGate", Chapter = 0, Difficulty = 4, Key = "Raid:ShadowGate",
            Label = ("Raid ShadowGate (carrying %d)"):format(Here) },
    })
end

-- child: move into the mother's lobby server, walk into her room, wait for her to start
local function ChildStep(Rooms)
    Carry.Urgent()
    local Mother = Carry.Mother()
    local Hrp = Root()
    if Join.ClientStatus == "inQuque" or Join.ClientStatus == "teleporting" then
        if Join.ChildSpot and Join.ClientStatus == "inQuque" then HoldAt(Join.ChildSpot) end
        if Join.ClientStatus == "inQuque" and Join.StatusAt and os.clock() - Join.StatusAt > 150 then
            pcall(function() Lobby.Packets.leaveQuque:fire() end)
            Join.ClientStatus, Join.ChildSpot = "idle", nil
        end
        return Say("Carry", Join.ClientStatus == "teleporting" and "Going in with carrier" or "In carrier's room - waiting for start")
    end
    if tostring(Mother.placeId) ~= tostring(LobbyPlaceId) then return Say("Carry", "Carrier is in a match - waiting") end
    if Mother.jobId and Mother.jobId ~= game.JobId then
        if os.clock() - Carry.HopAt > 30 then
            Carry.HopAt = os.clock()
            Note("Carry: moving to carrier's server")
            pcall(TeleportService.TeleportToPlaceInstance, TeleportService, LobbyPlaceId, Mother.jobId, LocalPlayer)
        end
        return Say("Carry", "Moving to carrier's server")
    end
    local Room = tonumber(Mother.room)
    if not Room then return Say("Carry", "Same server as carrier - waiting for room") end
    local Store = Rooms:getStore("room " .. Room)
    if not Store or Read(Store.state.status) == "idle" then return Say("Carry", "Waiting for carrier's room") end
    if not Hrp then return Say("Carry", "Waiting for character") end
    local Hitbox, Spot = RoomSpot(Room, Hrp)
    if not Hitbox then return Say("Carry", "Room " .. Room .. " not found") end
    Say("Carry", "Walking into carrier's room " .. Room)
    Join.ChildSpot = Spot
    local Waited = 0
    while Join.ClientStatus ~= "inQuque" and Join.ClientStatus ~= "teleporting" and Waited < 6 do
        HoldAt(Spot)
        Waited = Waited + task.wait(0.2)
    end
    if Join.ClientStatus ~= "inQuque" and Join.ClientStatus ~= "teleporting" then
        Join.ChildSpot = nil
        local Now = Root()
        if Now then Now.CFrame = CFrame.new(Spot + Vector3.new(0, 0, Hitbox.Size.Z / 2 + 12)) end
        Note("Carry: could not get into room " .. Room .. " - retrying")
        task.wait(2)
    end
end

local function LobbyMain()
    Lobby.Packets = SafeRequire(ReplicatedStorage, "lobby", "packets")
    Account = SafeRequire(ReplicatedStorage, "global", "stores", "accountNamespace")
    local RoomStore = SafeRequire(ReplicatedStorage, "lobby", "stores", "ququeRoomStore")
    if not (Lobby.Packets and Account and RoomStore) then
        return Say("Error", "lobby modules not found")
    end
    LoadCharacterData()
    Grow.Load()

    local Waited = 0
    while not AccountTable() and Waited < 20 do Waited = Waited + task.wait(0.5) end
    UpdateSlotStatus()

    local Steps = {
        { "Codes", Config.Codes and RedeemCodes },
        { "Claims", Config.Claims and ClaimAll },
        { "Slots", FillSlots },
        { "Skills", BuySkills },
        { "Shop", ShopMaterials },
        { "Evolve", Config.Lobby.Evolve and EvolveAll },
        { "Igris", UpgradeIgris },
        { "Craft", CraftGear },
        { "Gear", EquipGear },
        { "Team", EquipTeam },
        { "Traits", function() if not Carry.Child() then RollTraits() end end },
    }
    if Config.DryRun then
        local Data = AccountTable()
        local P = Plan.Current(Data)
        Note("Dry run - plan: " .. (P and P.Label or "none"))
        Note("Lobby work: " .. tostring(Plan.LobbyWork(Data)))
        Note(("Starter %s  end game %s  convert gems %s"):format(tostring(Plan.Starter(Data)), tostring(Grow.EndGame(Data)), tostring(Plan.Convert(Data))))
        for _, Project in ipairs(Grow.Projects(Data)) do
            local Missing = { }
            for Item, Amount in pairs(Project.Missing) do table.insert(Missing, Grow.ItemName(Item) .. " x" .. Amount) end
            for Key, Amount in pairs(Project.Currencies or { }) do
                if Currency(Key, Data) < Amount then table.insert(Missing, ("%s %d"):format(Key, Amount - Currency(Key, Data))) end
            end
            Note("Project " .. Project.Name .. ": " .. (#Missing > 0 and table.concat(Missing, ", ") or "affordable"))
        end
        for _, Entry in ipairs(Grow.Owned(Data)) do
            local Node, Tokens = Grow.NextSkill(Entry.Id, Data)
            Note(("%s Lv%d tokens %d next %s"):format(NameOf(Entry.Id), Grow.Level(Entry.Id, Data), Tokens, Node and (Node.Branch .. Node.Tier .. " cost " .. Node.Cost) or "maxed"))
        end
        return Say("Dry run", "done")
    end
    while Live() and not Farming() do
        Say("Waiting", "รอสั่งการจากเว็บ")
        task.wait(1)
    end
    -- group info as of now (a kaitan must know it is one before the starter spins)
    local Asked = os.clock()
    Carry.Urgent()
    while Live() and Config.Web and Carry.LiveAt < Asked and os.clock() - Asked < 15 do
        Say("Carry", "Checking carry groups")
        task.wait(0.5)
    end
    for _, Step in ipairs(Steps) do
        if Step[2] and Live() and Farming() then
            local Ok, Err = pcall(Step[2])
            if not Ok then Note(Step[1] .. " error: " .. tostring(Err)) end
            UpdateSlotStatus()
        end
    end

    Saved.SinceLobby = 0
    Save()

    table.insert(Join.Hooks, Lobby.Packets.toggleQuqueWindow:on(function(Data)
        if Live() and type(Data) == "table" and Data.open then Join.RoomNumber = Data.roomNumber end
    end))
    table.insert(Join.Hooks, Lobby.Packets.updateClientQuqueStatus:on(function(Value)
        if not Live() then return end
        Join.ClientStatus = tostring(Value)
        Join.StatusAt = os.clock()
    end))

    while Live() do
        if Farming() then
            local Step = JoinStep
            if Carry.Role() and not Carry.Live and os.clock() - StartedAt < 40 then
                Step = function() Say("Carry", "Waiting for the website (group info)") end
            elseif Carry.Child() and Carry.Mother() and Carry.Mother().online then
                Step = ChildStep
            elseif #Carry.Pending() > 0 then
                Step = MotherStep
            elseif Carry.Waiting() then
                Step = function()
                    Carry.Urgent()
                    Say("Carry", Carry.ChildDone() and "Kaitan starting - waiting to carry them" or "Carrier starting - waiting for the group")
                end
            end
            local Ok, Err = pcall(Step, RoomStore.namespace)
            if not Ok then Say("Join", "Error: " .. tostring(Err)) end
        else
            if Join.ClientStatus == "inQuque" then
                pcall(function() Lobby.Packets.leaveQuque:fire() end)
                Join.ClientStatus = "idle"
            end
            Say("Waiting", "หยุดฟาร์มแล้ว - รอสั่งการจากเว็บ")
        end
        task.wait(1)
    end
end

---- ============ Match ============ ----

local Battle = { Angle = 0 }

local function Alive()
    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local Hrp = Character and Character:FindFirstChild("HumanoidRootPart")
    if Humanoid and Hrp and Humanoid.Health > 0 then return Humanoid, Hrp end
end

local function LoadBattle()
    local Scripts = LocalPlayer:WaitForChild("PlayerScripts", 10)
    Battle.Controller = Scripts and SafeRequire(Scripts, "game", "controllers", "characterController")
    Battle.Input = Scripts and SafeRequire(Scripts, "global", "controllers", "inputController")
    Battle.Rewards = SafeRequire(ReplicatedStorage, "game", "packets", "rewardPackets")
    Battle.Sukuna = SafeRequire(ReplicatedStorage, "game", "packets", "sukunaPackets")
    Battle.CharacterInfo = SafeRequire(ReplicatedStorage, "global", "constants", "characters")
    Battle.Enemies = SafeRequire(ReplicatedStorage, "game", "stores", "enemyStore")
    Battle.Drops = SafeRequire(ReplicatedStorage, "game", "stores", "dropStore")
    Battle.Run = SafeRequire(ReplicatedStorage, "game", "stores", "runStore")
    Battle.Players = SafeRequire(ReplicatedStorage, "game", "stores", "playerNamespace")
    Battle.EnemyInfo = SafeRequire(ReplicatedStorage, "global", "constants", "enemies")
    Battle.CharPackets = SafeRequire(ReplicatedStorage, "game", "packets", "characterPackets")
    Battle.RunPackets = SafeRequire(ReplicatedStorage, "game", "packets", "runPackets")
    Account = SafeRequire(ReplicatedStorage, "global", "stores", "accountNamespace")
    pcall(function()
        for _, Value in pairs(debug.getupvalues(Battle.Controller.performSwitch)) do
            if type(Value) == "table" and rawget(Value, "till") and rawget(Value, "pending") then Battle.SkillState = Value end
        end
    end)
    return Battle.Controller and Battle.Enemies and Battle.Drops and Battle.Run and Battle.Players and Battle.RunPackets
end

local function EnemyPosition(Id, Enemy)
    local Model = workspace:FindFirstChild("enemies") and workspace.enemies:FindFirstChild(tostring(Id))
    local Part = Model and (Model.PrimaryPart or Model:FindFirstChild("HumanoidRootPart"))
    if Part then return Part.Position end
    return Read(Enemy.position)
end

local function EnemyData(Enemy)
    local Info = Battle.EnemyInfo
    if not Info then return nil, "" end
    local Name = Read(Enemy.name) or ""
    local Ok, Base = pcall(Info.getBaseName, Name)
    Base = Ok and Base or Name
    return Info.enemiesByName[Base] or Info.enemiesByName[Name], Base
end

local function IsBoss(Enemy)
    local Data = EnemyData(Enemy)
    return Data and Data.boss == true or false
end

-- enemies worth hitting (same as the hub): Shadow Gate keeps Igris on his throne from the
-- start (full health, no damage through waves 0-2) -> hidden until the last wave, and even
-- then his minions (soldiers / knights / oath knights) go first
function Battle.Targets()
    local All = Battle.Enemies.store.state:getAll()
    if workspace:GetAttribute("Mode") ~= "sololevelingraid" then return All end
    local State = Battle.Run and Battle.Run.store and Battle.Run.store.state
    local Wave, Waves = tonumber(State and Read(State.wave)) or 0, tonumber(State and Read(State.waveCount)) or 0
    local Out, Minions = { }, false
    for Id, Enemy in pairs(All) do
        local _, Base = EnemyData(Enemy)
        if Base ~= "soloIgris" and Base ~= "soloIgrisShadow" then
            Out[Id] = Enemy
            if (Read(Enemy.health) or 0) > 0 then Minions = true end
        end
    end
    if Minions or Waves == 0 or Wave < Waves then return Out end
    return All
end

-- Shadow Gate events: Break the Oath (kill oath knights in time) / System quest targets
function Battle.Priority()
    if workspace:GetAttribute("Mode") ~= "sololevelingraid" then return nil end
    if (tonumber(workspace:GetAttribute("RaidOathCount")) or 0) > 0 then return { soloOathKnight = true } end
    if workspace:GetAttribute("RaidQuestState") == "active" then
        local Goal = tostring(workspace:GetAttribute("RaidQuestGoal") or ""):lower()
        if Goal:find("blood%-red knight") then return { soloKnight = true } end
        if Goal:find("igris") and Goal:find("health") then return { soloIgris = true, soloIgrisShadow = true } end
    end
end

-- target: raid priority, then gather, then the biggest bunch (user 2026-10-10: Bathtub floors
-- spawn on three levels - floor, middle walkway, top balcony - and nearest-first left them
-- spread out). Gather = hit every enemy once so it chases us ("tagged": took damage, targets
-- us, or 2 s spent on it); then fight the enemy with the most others within 12 studs, so M1
-- and skills land on the whole pack, sticky until dead unless a clearly bigger pack forms.
-- Story keeps minions before the boss. Enemy ids are reused after death (0-255).
Battle.Tagged = { }

local function ClusterScore(Entry, List)
    local Count = 0
    for _, Other in ipairs(List) do
        if (Other.Position - Entry.Position).Magnitude <= 12 then Count = Count + 1 end
    end
    return Count
end

local function PickTarget(Hrp)
    local All = Battle.Targets()
    local Want = Battle.Priority()
    local Raid = tostring(workspace:GetAttribute("Mode") or ""):find("raid") ~= nil
    local Me = tostring(LocalPlayer.UserId)
    local Minions = false
    for _, Enemy in pairs(All) do
        if (Read(Enemy.health) or 0) > 0 and not IsBoss(Enemy) then Minions = true break end
    end
    local function Allowed(Enemy)
        if (Read(Enemy.health) or 0) <= 0 then return false end
        if Want then
            local _, Base = EnemyData(Enemy)
            return Want[Base] == true
        end
        return Raid or not (Minions and IsBoss(Enemy))
    end
    local function Nearest(Filter)
        local BestId, Best, BestDistance = nil, nil, math.huge
        for Id, Enemy in pairs(All) do
            if Filter(Id, Enemy) then
                local Position = EnemyPosition(Id, Enemy)
                local Distance = Position and (Position - Hrp.Position).Magnitude or math.huge
                if Distance < BestDistance then BestId, Best, BestDistance = Id, Enemy, Distance end
            end
        end
        return BestId, Best
    end
    Battle.Gathering = false

    -- raid events: nearest of the wanted ones, sticky until dead
    if Want then
        local Current = Battle.Target and All[Battle.Target]
        if Current and Allowed(Current) then return Battle.Target, Current end
        local Id, Enemy = Nearest(function(_, Enemy) return Allowed(Enemy) end)
        if Id then
            Battle.Target, Battle.Rescored = Id, os.clock()
            return Id, Enemy
        end
        Want = nil
    end

    -- gather: tag whatever does not chase us yet, nearest first
    for Id in pairs(Battle.Tagged) do
        local Enemy = All[Id]
        if not Enemy or (Read(Enemy.health) or 0) <= 0 then Battle.Tagged[Id] = nil end
    end
    local Tagging = Battle.Tagging
    if Tagging then
        local Enemy = All[Tagging.Id]
        local Health = Enemy and (Read(Enemy.health) or 0) or 0
        if Health <= 0 or Health < Tagging.Health or Read(Enemy.target) == Me or os.clock() - Tagging.Since > 2 or not Allowed(Enemy) then
            Battle.Tagged[Tagging.Id], Battle.Tagging = true, nil
        else
            Battle.Target, Battle.Gathering = nil, true
            return Tagging.Id, Enemy
        end
    end
    local GatherId, Gather = Nearest(function(Id, Enemy)
        if Battle.Tagged[Id] or not Allowed(Enemy) then return false end
        if Read(Enemy.target) == Me then Battle.Tagged[Id] = true return false end
        return true
    end)
    if GatherId then
        Battle.Tagging = { Id = GatherId, Health = Read(Gather.health) or 0, Since = os.clock() }
        Battle.Target, Battle.Gathering = nil, true
        return GatherId, Gather
    end

    -- fight: the biggest pack (ties: lower health)
    local List = { }
    for Id, Enemy in pairs(All) do
        local Position = Allowed(Enemy) and EnemyPosition(Id, Enemy)
        if Position then table.insert(List, { Id = Id, Enemy = Enemy, Position = Position, Health = Read(Enemy.health) or 0 }) end
    end
    local Best, BestScore = nil, -1
    for _, Entry in ipairs(List) do
        local Score = ClusterScore(Entry, List)
        if Score > BestScore or (Score == BestScore and Entry.Health < Best.Health) then Best, BestScore = Entry, Score end
    end
    if not Best then
        Battle.Target = nil
        return nil, nil
    end
    local Current = Battle.Target and All[Battle.Target]
    if Current and Allowed(Current) then
        if os.clock() - (Battle.Rescored or 0) < 1.5 then return Battle.Target, Current end
        Battle.Rescored = os.clock()
        for _, Entry in ipairs(List) do
            if Entry.Id == Battle.Target and ClusterScore(Entry, List) + 2 > BestScore then return Battle.Target, Current end
        end
    end
    Battle.Target, Battle.Rescored = Best.Id, os.clock()
    return Best.Id, Best.Enemy
end

local function NearestCash(Hrp)
    local Best, BestDistance = nil, math.huge
    for _, Drop in pairs(Battle.Drops.store.state:getAll()) do
        if Read(Drop.kind) == "cash" then
            local Position = Read(Drop.position)
            local Distance = Position and (Position - Hrp.Position).Magnitude or math.huge
            if Distance < BestDistance then Best, BestDistance = Position, Distance end
        end
    end
    return Best
end

-- unbroken area wall -> stand point on our side + face point
local function FindRubble(Hrp)
    local Map = workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Map")
    if not Map then return end
    for _, Child in ipairs(Map:GetChildren()) do
        if (tonumber(Child:GetAttribute("RubbleHealth")) or 0) > 0 then
            local Wall = Child:FindFirstChild("Blocker")
            if not (Wall and Wall:IsA("BasePart")) then
                local Ok, Box, Size = pcall(Child.GetBoundingBox, Child)
                if not Ok then return end
                Wall = { CFrame = Box, Size = Size, Position = Box.Position }
            end
            local Local = Wall.CFrame:PointToObjectSpace(Hrp.Position)
            local Size = Wall.Size
            local Offset
            if Size.X <= Size.Z then
                Offset = Vector3.new((Local.X >= 0 and 1 or -1) * (Size.X / 2 + 5), 0, 0)
            else
                Offset = Vector3.new(0, 0, (Local.Z >= 0 and 1 or -1) * (Size.Z / 2 + 5))
            end
            local Stand = Wall.CFrame:PointToWorldSpace(Offset)
            local Params = RaycastParams.new()
            Params.FilterType = Enum.RaycastFilterType.Exclude
            Params.FilterDescendantsInstances = { Child, LocalPlayer.Character, workspace:FindFirstChild("enemies"), Battle.Footer }
            local Hit = workspace:Raycast(Stand + Vector3.new(0, 60, 0), Vector3.new(0, -160, 0), Params)
            local Floor = (Hit and Hit.Position.Y or (Wall.Position.Y - Size.Y / 2)) + 3
            return Vector3.new(Stand.X, Floor, Stand.Z), Vector3.new(Wall.Position.X, Floor, Wall.Position.Z)
        end
    end
end

-- new area spawns (and a raid starts) only once we stand inside World.Areas.<area>
local function ZonePoint(Hrp)
    local Area = tostring(Read(Battle.Run.store.state.area) or "")
    local World = workspace:FindFirstChild("World")
    local Areas = World and World:FindFirstChild("Areas")
    local Zone = Areas and (Areas:FindFirstChild(Area) or Areas:FindFirstChildWhichIsA("BasePart"))
    if not (Zone and Zone:IsA("BasePart")) then return nil end
    local Local = Zone.CFrame:PointToObjectSpace(Hrp.Position)
    local Half = Zone.Size / 2
    if math.abs(Local.X) < Half.X - 4 and math.abs(Local.Z) < Half.Z - 4 then return nil end
    local Spawn = World:FindFirstChild("Spawns") and (World.Spawns:FindFirstChild(Area) or World.Spawns:FindFirstChild("Start"))
    local Floor = (Spawn and Spawn:IsA("BasePart") and math.abs(Spawn.Position.Y - Zone.Position.Y) < Half.Y and Spawn.Position.Y or Hrp.Position.Y - 3) + 3
    return Vector3.new(Zone.Position.X, Floor, Zone.Position.Z)
end

-- Bathtub: floor cleared -> World.Markers.Exit.ExitPrompt ("Enter Elevator")
local function ElevatorPrompt()
    local World = workspace:FindFirstChild("World")
    local Exit = World and World:FindFirstChild("Markers") and World.Markers:FindFirstChild("Exit")
    local Prompt = Exit and Exit:FindFirstChildWhichIsA("ProximityPrompt")
    return Prompt and Prompt.Enabled and Prompt or nil
end

-- boss attack boxes in progress (enemyStore attackIndex/attackStartedAt/attackCFrame/attackTarget)
local function Dangers()
    local List = { }
    for _, Enemy in pairs(Battle.Enemies.store.state:getAll()) do
        local Started, Index = tonumber(Read(Enemy.attackStartedAt)), tonumber(Read(Enemy.attackIndex))
        if (Read(Enemy.health) or 0) > 0 and Started and Index and IsBoss(Enemy) then
            local Data = EnemyData(Enemy)
            local Attack = Data and type(Data.attacks) == "table" and Data.attacks[Index]
            local Elapsed = workspace:GetServerTimeNow() - Started
            local Origin = Read(Enemy.attackCFrame)
            if Attack and typeof(Attack.size) == "Vector3" and typeof(Origin) == "CFrame" and Elapsed >= 0
                and Elapsed <= (tonumber(Attack.duration) or (tonumber(Attack.hitTime) or 1) + 0.5) then
                local Offset = typeof(Attack.offset) == "CFrame" and Attack.offset or CFrame.identity
                local Target = Read(Enemy.attackTarget)
                local Box = Origin * Offset
                if Attack.targeted and typeof(Target) == "Vector3" then
                    Box = CFrame.new(Target)
                elseif Attack.lunge and typeof(Target) == "Vector3" then
                    Box = CFrame.new(Target) * Origin.Rotation * Offset
                end
                table.insert(List, { Box = Box, Size = Attack.size })
            end
        end
    end
    return List
end

-- orbit point inside an attack box -> lift above it
local function DodgeGoal(Goal)
    for _, Danger in ipairs(Battle.Dangers or { }) do
        local Local = Danger.Box:PointToObjectSpace(Goal)
        local Size = Danger.Size
        if math.abs(Local.X) < Size.X / 2 + 3 and math.abs(Local.Z) < Size.Z / 2 + 3
            and Local.Y > -Size.Y / 2 - 3 and Local.Y < Size.Y + 3 then
            Goal = Vector3.new(Goal.X, math.max(Goal.Y, Danger.Box.Position.Y + Size.Y + 5), Goal.Z)
        end
    end
    return Goal
end

local function SkillReady(Store, Character, Slot)
    local Cooldown = Store.state.cooldowns:get(Battle.Players.skillCooldownKey(Character, Slot))
    return not (Cooldown and workspace:GetServerTimeNow() < (Read(Cooldown) or 0))
end

local function SkillIdle()
    local State = Battle.SkillState
    if not State then return true end
    local Ok, Idle = pcall(function()
        return not State.pending:get() and State.till:get() <= workspace:GetServerTimeNow()
    end)
    return not Ok or Idle
end

local function TeamMates(Current)
    local List = { }
    local Data = AccountTable()
    for _, Slot in pairs(Data and Data.EquippedCharacterSlots or { }) do
        local S = tonumber(Slot) and SlotData(tonumber(Slot), Data)
        if S and S.Unlocked and S.Character ~= "" and S.Character ~= Current then table.insert(List, S.Character) end
    end
    return List
end

local function PlaceFooter(Hrp, Humanoid)
    local Footer = Battle.Footer
    if not (Footer and Footer.Parent) then
        Footer = Instance.new("Part")
        Footer.Name = "\0"
        Footer.Size = Vector3.new(6, 1, 6)
        Footer.Anchored = true
        Footer.CanCollide = true
        Footer.CanTouch = false
        Footer.Transparency = 1
        Footer.Parent = workspace
        Battle.Footer = Footer
    end
    local Legs = (Humanoid and Humanoid.RigType == Enum.HumanoidRigType.R6) and 2 or (Humanoid and Humanoid.HipHeight or 2)
    Footer.CFrame = CFrame.new(Hrp.Position - Vector3.new(0, Hrp.Size.Y / 2 + Legs + Footer.Size.Y / 2, 0))
end

-- centre of the pack around a point (every live target within 14 studs)
local function ClusterCenter(Around)
    if not Around then return nil end
    local Sum, Count = Vector3.zero, 0
    for Id, Enemy in pairs(Battle.Targets()) do
        local Position = (Read(Enemy.health) or 0) > 0 and EnemyPosition(Id, Enemy)
        if Position and (Position - Around).Magnitude <= 14 then Sum, Count = Sum + Position, Count + 1 end
    end
    return Count > 0 and Sum / Count or Around
end

-- hit a boss from above: feet + its tallest attack box + 5, at most +20 (M1 misses from +25.8)
local function BossSafeY(Enemy)
    local Feet = Read(Enemy.position)
    local Data = EnemyData(Enemy)
    if typeof(Feet) ~= "Vector3" then return nil end
    local Top = nil
    for _, Attack in pairs(Data and type(Data.attacks) == "table" and Data.attacks or { }) do
        if typeof(Attack.size) == "Vector3" then Top = math.max(Top or 0, Attack.size.Y) end
    end
    return Top and Feet.Y + math.min(Top + 5, 20) or nil
end

-- every frame (same as the hub): go to the override spot, else orbit the target and look at it.
-- Silent aim: while a skill goes off, stand 8 studs beside the pack centre at the same height
-- facing it flat (19 hits on 8 enemies vs ~1 looking straight down); bosses are hit from above
local function MoveStep(Dt)
    local Humanoid, Hrp = Alive()
    if not Hrp then return end

    local Goal, Face, Aim = nil, nil, false
    if Battle.Override then
        Goal, Face = Battle.Override, Battle.OverrideFace
    elseif Battle.TargetPosition then
        local F = Config.Farm
        Battle.Angle = (Battle.Angle + Dt * (tonumber(F.Speed) or 10) * 0.6) % (math.pi * 2)
        Goal = Battle.TargetPosition + Vector3.new(math.cos(Battle.Angle) * F.Radius, F.Height, math.sin(Battle.Angle) * F.Radius)
        if Battle.SafeY and Goal.Y < Battle.SafeY then Goal = Vector3.new(Goal.X, Battle.SafeY, Goal.Z) end
        local Pose = not Battle.TargetBoss and Battle.Aim
        if Pose and typeof(Pose.Center) == "Vector3" and os.clock() <= Pose.Until then
            local Flat = (Hrp.Position - Pose.Center) * Vector3.new(1, 0, 1)
            if Flat.Magnitude < 0.5 then Flat = Hrp.CFrame.LookVector * Vector3.new(-1, 0, -1) end
            if Flat.Magnitude < 0.1 then Flat = Vector3.new(0, 0, 1) end
            Goal = Vector3.new(Pose.Center.X, Goal.Y, Pose.Center.Z) + Flat.Unit * 8
            Face = Vector3.new(Pose.Center.X, Goal.Y, Pose.Center.Z)
        else
            Face, Aim = Battle.TargetPosition, true
        end
        Goal = DodgeGoal(Goal)
    end
    Battle.Moving = Goal ~= nil
    if not Goal then
        if Battle.Footer then Battle.Footer.Parent = nil end
        return
    end

    local Flat = Hrp.CFrame.LookVector * Vector3.new(1, 0, 1)
    if Flat.Magnitude < 0.1 then Flat = Vector3.new(0, 0, -1) end
    if Aim and Face and (Face - Goal).Magnitude > 0.5 then
        local Direction = (Face - Goal).Unit
        Hrp.CFrame = CFrame.lookAt(Goal, Face, math.abs(Direction.Y) > 0.98 and Flat.Unit or Vector3.yAxis)
    else
        local Look = Face and Vector3.new(Face.X, Goal.Y, Face.Z) or nil
        if Look and (Look - Goal).Magnitude < 0.5 then Look = Goal + Flat end
        Hrp.CFrame = Look and CFrame.lookAt(Goal, Look) or CFrame.new(Goal) * Hrp.CFrame.Rotation
    end
    Hrp.AssemblyLinearVelocity = Vector3.zero
    PlaceFooter(Hrp, Humanoid)
end

-- health drops (same as the hub): the game picks up every drop within 12 studs and fires
-- rewardPackets.recoverDrop(id), wasting them at full HP -> hold them back until HP is below
-- Farm.HealBelow, then send recoverDrop for each one directly (the server takes it from 22-33 studs)
local function NeedHeal(Humanoid)
    local HealAt = tonumber(Config.Farm.HealBelow) or 0
    return Humanoid ~= nil and HealAt > 0 and (Humanoid.Health / math.max(Humanoid.MaxHealth, 1)) * 100 < HealAt
end

local function SendDrop(Id)
    local Packet = Battle.Rewards and Battle.Rewards.recoverDrop
    local Fire = Battle.OriginalDropFire or (Packet and Packet.fire)
    if Fire then Fire(Packet, Id) end
end

-- game patches while we run, undone by KaitanCleanup:
--   inputController.isBlocked: keep fighting with the Esc menu / settings open (end screen still blocks)
--   recoverDrop: keep health drops for later (above)
--   Sukuna arrowLanded: land the arrow on the pack centre (the server accepts it, 1020 damage)
function Battle.Patch()
    local Input = Battle.Input
    if Input and not Battle.OriginalBlocked and type(Input.isBlocked) == "function" then
        local Original = Input.isBlocked
        Battle.OriginalBlocked = Original
        Input.isBlocked = function(...)
            if not Live() then return Original(...) end
            local Gui = LocalPlayer:FindFirstChild("PlayerGui")
            return Gui ~= nil and Gui:GetAttribute("EndScreenActive") == true
        end
    end
    local Drop = Battle.Rewards and Battle.Rewards.recoverDrop
    if Drop and not Battle.OriginalDropFire and type(Drop.fire) == "function" then
        local Original = Drop.fire
        Battle.OriginalDropFire = Original
        rawset(Drop, "fire", function(Self, Id, ...)
            if Live() and (tonumber(Config.Farm.HealBelow) or 0) > 0 then
                local Entry = Battle.Drops and Battle.Drops.store.state:get(Id)
                local Humanoid = Alive()
                if Entry and Read(Entry.kind) == "health" and Humanoid and not NeedHeal(Humanoid) then return end
            end
            return Original(Self, Id, ...)
        end)
    end
    local Arrow = Battle.Sukuna and Battle.Sukuna.arrowLanded
    if Arrow and not Battle.OriginalArrowFire and type(Arrow.fire) == "function" then
        local Original = Arrow.fire
        Battle.OriginalArrowFire = Original
        rawset(Arrow, "fire", function(Self, Position, ...)
            local Center = Battle.AimCenter or Battle.TargetPosition
            if Live() and typeof(Center) == "Vector3" then return Original(Self, Center, ...) end
            return Original(Self, Position, ...)
        end)
    end
end

function Battle.Unpatch()
    if Battle.Input and Battle.OriginalBlocked then Battle.Input.isBlocked = Battle.OriginalBlocked end
    local Drop = Battle.Rewards and Battle.Rewards.recoverDrop
    if Drop and Battle.OriginalDropFire then rawset(Drop, "fire", nil) end
    local Arrow = Battle.Sukuna and Battle.Sukuna.arrowLanded
    if Arrow and Battle.OriginalArrowFire then rawset(Arrow, "fire", nil) end
    Battle.OriginalBlocked, Battle.OriginalDropFire, Battle.OriginalArrowFire = nil, nil, nil
end

local function SetHold(On)
    local Controller = Battle.Controller
    if On then
        local Ok, Held = pcall(Controller.isM1Held)
        if not (Battle.Holding and Ok and Held) then pcall(Controller.setTouchHeld, "Attack", true) end
        Battle.Holding = true
    elseif Battle.Holding then
        Battle.Holding = false
        pcall(Controller.setTouchHeld, "Attack", false)
    end
end

local function TagTeam(Store, Character, InRange)
    local Switch = Store.state.cooldowns:get("characterSwitch")
    local SwitchReady = not (Switch and workspace:GetServerTimeNow() < (Read(Switch) or 0))
    -- Sung Jinwoo owned (user 2026-10-10): always play him, no tag team. Whoever the match
    -- starts with (he can sit in team slot 2) switches to him once, then he never switches out
    if Owns("sung_jinwoo") then
        Battle.SwitchPending = nil
        if Character ~= "sung_jinwoo" and table.find(TeamMates(Character), "sung_jinwoo") and SwitchReady and SkillIdle()
            and os.clock() - (Battle.SwitchAt or 0) > 1 then
            Battle.SwitchFrom, Battle.SwitchAt = Character, os.clock()
            pcall(Battle.Controller.performSwitch)
        end
        return
    end
    if not Config.Farm.TagTeam or os.clock() - (Battle.LastSwitch or 0) < 1.5
        or (tonumber(workspace:GetAttribute("RaidOathCount")) or 0) > 0 then
        Battle.SwitchPending = nil
        return
    end
    local Mates = TeamMates(Character)
    if #Mates == 0 then
        Battle.SwitchPending = nil
        return
    end
    local AllCooling = true
    for Slot = 1, 3 do
        if SkillReady(Store, Character, Slot) then AllCooling = false break end
    end
    local MateSkills = 0
    for _, Mate in ipairs(Mates) do
        local Count = 0
        for Slot = 1, 3 do
            if SkillReady(Store, Mate, Slot) then Count = Count + 1 end
        end
        MateSkills = math.max(MateSkills, Count)
    end
    local UsedUp = AllCooling or (InRange and (Battle.CastCount or 0) >= 1 and os.clock() - (Battle.LastCast or 0) > 1)
    if ((UsedUp and MateSkills >= 1) or Battle.SwitchPending) and SwitchReady then
        if not Battle.SwitchPending then
            Battle.SwitchPending = os.clock()
        elseif SkillIdle() and os.clock() - (Battle.SwitchAt or 0) > 0.3 then
            Battle.SwitchFrom, Battle.SwitchAt = Character, os.clock()
            pcall(Battle.Controller.performSwitch)
        elseif os.clock() - Battle.SwitchPending >= 1.5 then
            Battle.SwitchPending = nil
            Battle.LastSwitch = os.clock() - 8.5
        end
    else
        Battle.SwitchPending = nil
    end
end

-- one battle tick (0.1 s), the hub's farm logic for every stage plus the carry / Jinwoo rules
local function BattleStep()
    local Humanoid, Hrp = Alive()
    local State = Battle.Run.store.state
    Battle.Expecting = false
    local Me = nil
    pcall(function() Me = State.participants:get(tostring(LocalPlayer.UserId)) end)
    local RunStatus = Read(State.status)
    local Running = RunStatus == "active" and (not Me or Read(Me.status) == "active")

    if not (Humanoid and Running) then
        Battle.ProgressAt = os.clock()
        Battle.TargetPosition, Battle.Override, Battle.OverrideFace, Battle.Aim = nil, nil, nil, nil
        -- a raid stays "waiting" until we walk into its zone
        if Humanoid and RunStatus == "waiting" then Battle.Override = ZonePoint(Hrp) end
        SetHold(false)
        return
    end

    -- low HP: send recoverDrop for the health drops held back; still there after 1.5 s = go to it
    local Heal = nil
    Battle.HealFired = Battle.HealFired or { }
    if NeedHeal(Humanoid) then
        local Now = os.clock()
        for Id, Drop in pairs(Battle.Drops.store.state:getAll()) do
            if Read(Drop.kind) == "health" then
                local FiredAt = Battle.HealFired[Id]
                if not FiredAt or Now - FiredAt > 1 then
                    if not FiredAt then Battle.HealFired[Id] = Now end
                    pcall(SendDrop, Id)
                end
                if FiredAt and Now - FiredAt > 1.5 and not Heal then Heal = Read(Drop.position) end
            end
        end
    else
        table.clear(Battle.HealFired)
    end

    -- let the wave finish spawning first: runStore.remaining counts the whole wave, enemies come
    -- out 0.2-0.5 s apart -> alive < remaining = still spawning; no new one for 1.2 s = all out
    -- (Bathtub floor 3 sends one at a time after the last one dies)
    local Count, Seen = 0, { }
    Battle.Seen = Battle.Seen or { }
    for Id, Enemy in pairs(Battle.Targets()) do
        if (Read(Enemy.health) or 0) > 0 then
            Count = Count + 1
            Seen[Id] = true
            if not Battle.Seen[Id] then Battle.LastSpawn = os.clock() end
        end
    end
    Battle.Seen = Seen
    local Remaining = tonumber(Read(State.remaining)) or 0
    local Spawning = Count > 0 and Count < Remaining and os.clock() - (Battle.LastSpawn or 0) < 1.2
    local Key = tostring(Read(State.area)) .. ":" .. Remaining .. ":" .. Count
    if Key ~= Battle.ProgressKey then Battle.ProgressKey, Battle.ProgressAt = Key, os.clock() end

    -- carried child: hide above the map while the mother clears it
    if Carry.Child() and Carry.MotherHere(State) then
        Battle.TargetPosition, Battle.OverrideFace, Battle.Aim = nil, nil, nil
        Battle.HideSpot = Battle.HideSpot or (Hrp.Position + Vector3.new(0, 120, 0))
        Battle.Override = Battle.HideSpot
        SetHold(false)
        return Say("Hide", ("Hiding while carrier clears  ·  wave %s/%s  enemies %d"):format(tostring(Read(State.wave)), tostring(Read(State.waveCount)), Count))
    end

    Battle.Dangers = Dangers()
    local TargetId, Target
    if Spawning then
        -- wait at the nearest one: no tagging, no hits, no skills yet
        local Best = math.huge
        Battle.Gathering = false
        for Id, Enemy in pairs(Battle.Targets()) do
            local Position = (Read(Enemy.health) or 0) > 0 and EnemyPosition(Id, Enemy)
            local Distance = Position and (Position - Hrp.Position).Magnitude or math.huge
            if Distance < Best then TargetId, Target, Best = Id, Enemy, Distance end
        end
    else
        TargetId, Target = PickTarget(Hrp)
    end
    Battle.Spawning = Spawning
    Battle.TargetPosition = Target and EnemyPosition(TargetId, Target) or nil
    Battle.TargetBoss = Target ~= nil and IsBoss(Target)
    Battle.SafeY = Battle.TargetBoss and BossSafeY(Target) or nil

    local Cash = Config.Farm.CollectCash and not Target and NearestCash(Hrp)
    Battle.Override, Battle.OverrideFace = Heal or Cash or nil, nil

    -- enemies gone: break the next area's wall / take the Bathtub elevator / walk into the zone
    local Breaking = false
    if not Target and not Battle.Override then
        local Stand, Face = FindRubble(Hrp)
        local Elevator = ElevatorPrompt()
        local Wave, Waves = tonumber(Read(State.wave)) or 0, tonumber(Read(State.waveCount)) or 0
        if Stand then
            Battle.Override, Battle.OverrideFace, Breaking = Stand, Face, true
        elseif Elevator and Count == 0 and Remaining == 0 and Waves > 0 and Wave >= Waves then
            local Spot = Elevator.Parent.Position
            Battle.Override = Spot
            if (Hrp.Position - Spot).Magnitude < 10 and os.clock() - (Battle.ElevatorAt or 0) > 2 then
                Battle.ElevatorAt = os.clock()
                if fireproximityprompt then
                    pcall(fireproximityprompt, Elevator, 1)
                else
                    pcall(function() Elevator:InputHoldBegin() task.wait(0.1) Elevator:InputHoldEnd() end)
                end
            end
        else
            Battle.Override = ZonePoint(Hrp)
        end
    end
    Say("Farm", ("Area %s  wave %s/%s  enemies %d%s"):format(tostring(Read(State.area)), tostring(Read(State.wave)), tostring(Read(State.waveCount)), Count,
        Breaking and "  (breaking wall)" or Spawning and "  (spawning)" or Battle.Gathering and "  (gathering)" or Battle.TargetBoss and "  (boss)" or ""))

    -- M1 held through the game's controller; released while a switch waits (every swing pushes
    -- the skill timer and the game drops performSwitch)
    local Switching = Battle.SwitchPending and os.clock() - Battle.SwitchPending < 1.5
    local WantHold = not Switching and ((Target ~= nil and not Battle.Override and not Spawning) or Breaking)
    SetHold(WantHold)
    Battle.Expecting = WantHold and Target ~= nil and not Breaking and Battle.TargetPosition ~= nil
        and (Battle.TargetPosition - Hrp.Position).Magnitude < 25
    if not Target or Spawning then return end

    local Store = Battle.Players.getLocalPlayerStore()
    local Character = Store and Read(Store.state.character)
    if not (Store and Character) then return end
    local InRange = Battle.TargetPosition and (Battle.TargetPosition - Hrp.Position).Magnitude < 25

    -- switch confirmed: the new character does not swing until M1 is pressed again
    if Battle.SwitchFrom and Character ~= Battle.SwitchFrom then
        Battle.LastSwitch, Battle.SwitchFrom, Battle.SwitchPending = Battle.SwitchAt, nil, nil
        Battle.Holding = false
        pcall(Battle.Controller.setTouchHeld, "Attack", false)
        Battle.CastCount, Battle.LastCast = 0, os.clock()
    end

    -- tagging the pack together: skills and the ultimate wait for it (Jinwoo still switches in)
    if Battle.Gathering then
        if Owns("sung_jinwoo") then TagTeam(Store, Character, InRange) end
        return
    end
    Battle.AimCenter = ClusterCenter(Battle.TargetPosition) -- where the Sukuna arrow lands

    -- skills (same as the hub): a ready skill -> step beside the pack (MoveStep), give the server
    -- 0.12 s to see it, cast, hold the pose for the skill's processingTime (ult 1 s), then back.
    -- Not while a switch waits (a fresh cast keeps the old move running and the switch never fires)
    local Holding = Battle.SwitchPending ~= nil
    local Ult = Config.Farm.Ultimate
    local WantUlt = InRange and not Holding and (Ult == true or (Ult == "Boss" and Battle.TargetBoss))
    local WantSkill = Config.Farm.Skills and InRange and not Holding
    local Now = os.clock()
    local Aim = Battle.Aim
    if Aim and Now > Aim.Until then
        -- posed and nothing went off (immune boss / stunned / ult not full) = rest 2 s
        if not Aim.Cast and not Battle.TargetBoss then Battle.AimRest = Now + 2 end
        Aim, Battle.Aim = nil, nil
    end
    -- Jinwoo's ult key casts its bonus skill (Arise: Kaisel, 11.4 s) while the player attribute
    -- BonusUntil runs after Monarch's Domain (characterController.performSkill) - never wanted
    -- (user 2026-10-10)
    if WantUlt and Character == "sung_jinwoo" and workspace:GetServerTimeNow() < (tonumber(LocalPlayer:GetAttribute("BonusUntil")) or 0) then
        WantUlt = false
    end
    -- a slot the game calls ready that will not fire (Sukuna's first skill) rests 3 s
    Battle.NoCast = Battle.NoCast or { }
    local Ready = false
    if WantUlt or WantSkill then
        for Slot = 1, 4 do
            if (Slot == 4 and WantUlt or Slot < 4 and WantSkill) and (Battle.NoCast[Slot] or 0) < Now and SkillReady(Store, Character, Slot) then
                Ready = true
                break
            end
        end
    end
    -- bosses: no pose (hit from above), cast right away
    if Ready and not Aim and (Battle.TargetBoss or Now >= (Battle.AimRest or 0)) then
        Battle.Aim = { Center = Battle.AimCenter or Battle.TargetPosition, Since = Battle.TargetBoss and Now - 1 or Now, Until = Now + 0.6 }
    elseif Aim then
        Aim.Center = Battle.AimCenter or Battle.TargetPosition or Aim.Center
    end
    Aim = Battle.Aim
    if Aim and Now - Aim.Since >= 0.12 then
        local Info = Battle.CharacterInfo and Battle.CharacterInfo.charactersByName and Battle.CharacterInfo.charactersByName[Character]
        local function Cast(Slot)
            local Ok, Used = pcall(Battle.Controller.performSkill, Slot)
            if not (Ok and Used) then
                -- the previous move still playing is a normal miss, not a dead slot
                if os.clock() > (Battle.CastBusy or 0) and SkillReady(Store, Character, Slot) then Battle.NoCast[Slot] = os.clock() + 3 end
                return false
            end
            Battle.NoCast[Slot] = nil
            Aim.Cast = true
            local Skill = Info and Info.skills and Info.skills[Slot]
            local Busy = tonumber(Skill and Skill.processingTime) or 1.5
            Battle.CastBusy = os.clock() + Busy
            Aim.Until = math.max(Aim.Until, os.clock() + (Slot == 4 and 1 or math.clamp(Busy, 0.5, 3)))
            return true
        end
        if WantUlt then Cast(4) end
        if WantSkill then
            for Slot = 1, 3 do
                if Cast(Slot) then
                    Battle.LastCast, Battle.CastCount = os.clock(), (Battle.CastCount or 0) + 1
                    break
                end
            end
        end
    end
    TagTeam(Store, Character, InRange)
end

-- stalled server: no hits for 25s or no progress for 2 minutes -> back to the lobby
local function Watchdog()
    local Now = os.clock()
    if Battle.Expecting then
        Battle.ExpectSince = Battle.ExpectSince or Now
        local Quiet = Now - math.max(Battle.LastHit or 0, Battle.ExpectSince)
        if Quiet > 25 then
            Battle.Bail = "no hits for 25s"
        elseif Quiet > 8 and not Battle.Repressed then
            Battle.Repressed, Battle.Target = true, nil
            SetHold(false)
        end
    else
        Battle.ExpectSince = nil
    end
    if Battle.ProgressAt and Now - Battle.ProgressAt > 120 then Battle.Bail = "no progress for 2 minutes" end
    if Battle.Bail and not Battle.BailedOut then
        Battle.BailedOut = true
        Note("Stalled (" .. Battle.Bail .. ") - back to lobby")
        task.delay(2, function() pcall(TeleportService.Teleport, TeleportService, LobbyPlaceId, LocalPlayer) end)
    end
end

-- result screen: record the result, then Leave (lobby work / stage change), Next or Retry
local function EndStep()
    local State = Battle.Run.store.state
    local Key = tostring(LocalPlayer.UserId)
    local Me = nil
    pcall(function() Me = State.participants:get(Key) end)
    if not Me then return end
    local MyStatus, Travel = Read(Me.status), Read(Me.travelStatus)
    if Read(State.resultEndsAt) and MyStatus and MyStatus ~= "active" and Travel == "idle" then
        if not Battle.Counted then
            Battle.Counted = true
            local Data = AccountTable()
            local Main = Plan.Main(Data)
            local Level = Main and Grow.Level(Main, Data) or 1
            Saved.SinceLobby = (Saved.SinceLobby or 0) + 1
            if MyStatus == "victory" then
                Saved.Loss = { Key = "", Count = 0 }
            else
                local Stage = Saved.PlanKey ~= "" and Saved.PlanKey or "?"
                if Saved.Loss.Key == Stage then Saved.Loss.Count = Saved.Loss.Count + 1 else Saved.Loss = { Key = Stage, Count = 1 } end
                if Saved.Loss.Count >= (Config.Farm.Losses or 2) then
                    -- progress key blocks the act being played
                    local Blocked = Stage:gsub("progress", tostring(tonumber(Read(State.chapter)) or 1))
                    Saved.Blocked[Blocked] = Level + (Config.Farm.Unblock or 10)
                    Note(("Blocked %s until main Lv%d"):format(Blocked, Saved.Blocked[Blocked]))
                    Saved.Loss = { Key = "", Count = 0 }
                end
            end
            Save()
            local Work = Plan.LobbyWork(Data)
            local Next = false
            pcall(function() Next = Read(State.canNext) == true and Saved.PlanKey:find("progress") ~= nil end)
            Battle.Action = Work and 3 or (Next and 2 or 1)
            -- Sung Jinwoo owned = strong enough (user 2026-10-10): Retry straight away; the lobby
            -- (spending) only on the regular visit every Lobby.Every matches. A unit waiting to be
            -- placed or a new stage still leaves now (user 2026-10-10: it kept retrying Bathtub
            -- with Hu Tao already dropped)
            local Must = type(Work) == "string" and (Work:find("ready to place", 1, true) or Work:find("next stage", 1, true))
            if Owns("sung_jinwoo", Data) and not Must and (Saved.SinceLobby or 0) < (Config.Lobby.Every or 10) then
                Battle.Action, Work = 1, nil
            end
            -- mother with children in this run: Retry together (Leave only for the regular lobby visit)
            if Carry.Role() == "mother" and Carry.KidsHere(State) > 0 and (Saved.SinceLobby or 0) < (Config.Lobby.Every or 10) then
                Battle.Action, Work = 1, "carrying"
            end
            -- a kaitan of the group is not in this run (started before the group was set up, or a new
            -- one came online while carrying the others): back to the lobby to group everyone up
            if Carry.Role() == "mother" and #Carry.Missing(State) > 0 then
                Battle.Action, Work = 3, "grouping"
            elseif Carry.Child() and not Carry.MotherHere(State) and Carry.Mother() and Carry.Mother().online then
                Battle.Action, Work = 3, "join carrier"
            end
            Note(("Match %s -> %s%s"):format(tostring(MyStatus), ({ "Retry", "Next", "Leave" })[Battle.Action], Work and (" (" .. Work .. ")") or ""))
        end
        -- carried child: vote what the mother votes; done (has Jinwoo) = leave the group
        if Carry.Role() == "child" and Carry.MotherHere(State) then
            if Carry.ChildDone() then
                Battle.Action = 3
            else
                local Vote = nil
                pcall(function() Vote = tonumber(Read(State.resultVotes:get(tostring(Carry.Mother().id)))) end)
                Battle.Action = Vote
            end
        end
        local Mine = nil
        pcall(function() Mine = Read(State.resultVotes:get(Key)) end)
        if Battle.Action and Mine ~= Battle.Action and os.clock() - (Battle.EndedAt or 0) > 3 then
            Battle.EndedAt = os.clock()
            Battle.RunPackets.endAction:fire(Battle.Action)
        end
        Say("Result", Battle.Action and ({ "Retrying", "Next act", "Leaving to lobby" })[Battle.Action] or "Waiting for carrier's vote")
    elseif MyStatus == "active" then
        Battle.Counted = nil
    end
end

-- a new kaitan came online mid-match (user 2026-10-10): the carrier it was given leaves right
-- away to carry it - unless kaitan are already in this run (then it Leaves at the result screen,
-- EndStep "grouping", and they follow its vote). A kaitan farming alone while its carrier is
-- online leaves too, to be in the lobby when the carrier opens the room.
local function CarryStep()
    -- one teleport at a time (a failed one is tried again after 30 s)
    if (Battle.Leaving and os.clock() - Battle.Leaving < 30) or not (Carry.Live and os.clock() - Carry.LiveAt < 60) then return end
    local State = Battle.Run.store.state
    local Why = nil
    if Carry.Role() == "mother" and Carry.KidsHere(State) == 0 and #Carry.Missing(State) > 0 then
        Why = ("%d kaitan to carry"):format(#Carry.Missing(State))
    elseif Carry.Child() and Carry.Role() == "child" and Carry.Mother() and Carry.Mother().online and not Carry.MotherHere(State) then
        Why = "carrier is waiting"
    end
    if not Why then return end
    Battle.Leaving = os.clock()
    Note("Carry: " .. Why .. " - leaving the match")
    Say("Carry", "Leaving to the lobby (" .. Why .. ")")
    task.delay(1, function() pcall(TeleportService.Teleport, TeleportService, LobbyPlaceId, LocalPlayer) end)
end

local function SkipTutorial()
    local Remote = ReplicatedStorage:WaitForChild("TutorialRemote", 15)
    if not Remote then return Note("Tutorial: TutorialRemote not found - fighting through") end
    Note("Tutorial: skipping")
    task.wait(3) -- let the server register the player first
    while Live() do
        Say("Tutorial", "Skipping (TutorialRemote skip)")
        pcall(Remote.FireServer, Remote, "skip")
        task.wait(8) -- still here = not taken; fire again (the battle loop keeps fighting meanwhile)
    end
end

local function MatchMain()
    if Config.Tutorial == "skip" then
        task.spawn(function()
            -- Mode is set by the server shortly after load
            for _ = 1, 20 do
                if workspace:GetAttribute("Mode") ~= nil then break end
                task.wait(0.5)
            end
            if workspace:GetAttribute("Mode") == "tutorial" then SkipTutorial() end
        end)
    end
    if not LoadBattle() then return Say("Error", "match modules not found") end
    pcall(Battle.Patch)
    LoadCharacterData()
    Grow.Load()
    UpdateSlotStatus()

    Battle.LastHit, Battle.ProgressAt = os.clock(), os.clock()
    pcall(function()
        Battle.HitHook = Battle.CharPackets.hitRegistered:on(function()
            Battle.LastHit, Battle.ProgressAt, Battle.Repressed = os.clock(), os.clock(), false
        end)
    end)

    TrackConnection(RunService.Heartbeat:Connect(function(Dt)
        if Live() then pcall(MoveStep, Dt) end
    end))
    TrackConnection(RunService.Stepped:Connect(function()
        if not (Live() and Battle.Moving) then return end
        local Character = LocalPlayer.Character
        if not Character then return end
        for _, Part in ipairs(Character:GetDescendants()) do
            if Part:IsA("BasePart") and Part.CanCollide then Part.CanCollide = false end
        end
    end))

    local Tick = 0
    while Live() do
        local Ok, Err = pcall(BattleStep)
        if not Ok then Say("Farm", "Error: " .. tostring(Err)) end
        pcall(Watchdog)
        pcall(EndStep)
        pcall(CarryStep)
        if not Farming() and not Battle.Stopped then
            Battle.Stopped = true
            Note("Stop farm from the website - back to lobby")
            task.delay(1, function() pcall(TeleportService.Teleport, TeleportService, LobbyPlaceId, LocalPlayer) end)
        end
        Tick = Tick + 1
        if Tick % 50 == 0 then pcall(UpdateSlotStatus) end
        task.wait(0.1)
    end
end


---- ============ Website (valkyriehub.net/account/kaitan?mode=kaitan) ============ ----
-- POST /api/kaitan/report like the hub's Website page, mode = "kaitan": progress % + weighted
-- parts (the page draws bar / ring / breakdown / history), state.Stats + state.Report cards.
-- The reply may carry `global` = Global Settings for this game, newest `at` wins.

local Site = { StartedAt = os.clock(), PostAt = 0, Quiet = 0, Text = "-", Acks = { }, Seen = { }, Fast = false,
    Http = request or http_request or (syn and syn.request) or (http and http.request) }

function Site.Key()
    if Site.CachedKey then return Site.CachedKey end
    for _, Name in ipairs({ "ValkyrieKey", "LicenseKey", "License", "Key" }) do
        local Value = getgenv()[Name]
        if type(Value) == "string" and Value ~= "" then
            Site.CachedKey = Value:gsub("%s", "")
            return Site.CachedKey
        end
    end
    local Ok, Value = pcall(function() return isfile("Valkyrie Hub/MyKey/key.txt") and readfile("Valkyrie Hub/MyKey/key.txt") end)
    if Ok and type(Value) == "string" and Value ~= "" then
        Site.CachedKey = Value:gsub("%s", "")
        return Site.CachedKey
    end
end

-- weighted progress towards end game; parts that do not apply (no raid unit asked for...) drop out
function Site.Parts(Data)
    local Parts = { }
    local function Add(Key, Label, Weight, Current, Target, Text)
        local Percent = Target > 0 and math.clamp(Current / Target, 0, 1) or 0
        table.insert(Parts, { key = Key, label = Label, weight = Weight, current = Current, target = Target,
            percent = math.floor(Percent * 100 + 0.5), done = Percent >= 1, text = Text })
    end
    local Main = Plan.Main(Data)
    local Owned = Grow.Owned(Data)

    -- slot 1's Lucky Spin starter (Cursed King) is only the fallback for an account nobody
    -- with Sung Jinwoo carries (user 2026-10-10): no part of its own, and slot 1 counts for
    -- skills / evolve only once it actually holds its target
    local Assign = Plan.Assign(Data)
    local function Counted(Slot)
        local Target = Config.Slots[Slot] or ""
        if Target == "" then return false end
        return Slot ~= 1 or not Rollable(Target) or Assign[1] ~= nil
    end
    -- character data of whatever slot meets a target (targets are not tied to positions)
    local function Holder(T)
        local S = Assign[T] and SlotData(Assign[T], Data)
        return S and Data.CharactersData and Data.CharactersData[S.Character] or nil
    end
    if Main then
        local Level = Grow.Level(Main, Data)
        Add("level", "Main level", 10, Level, 110, NameOf(Main) .. " Lv" .. Level)
    end
    -- per slot target (not per owned character) so the bar never steps back
    local Tiers, Chars = 0, 0
    for Slot = 1, 4 do
        local Target = Config.Slots[Slot] or ""
        if Counted(Slot) then
            Chars = Chars + 1
            local Info = Holder(Slot)
            local Skills = type(Info) == "table" and Info.Progression and Info.Progression.Skills or { }
            for _, Branch in ipairs({ "ATK", "CRIT", "DEF", "SPD" }) do Tiers = Tiers + math.min(tonumber(Skills[Branch]) or 0, 5) end
        end
    end
    if Chars > 0 then Add("skills", "Skill trees", 10, Tiers, Chars * 20, ("%d/%d tiers"):format(Tiers, Chars * 20)) end
    if Main and #(Config.Trait.Keep or { }) > 0 then
        local Info = Data.CharactersData and Data.CharactersData[Main]
        local Trait = Info and Info.TraitData and Info.TraitData.Trait or 0
        Add("trait", "Trait (main)", 5, Plan.TraitKeep(Trait) and 1 or 0, 1, nil)
    end
    for Slot = 2, 4 do
        local Target = Config.Slots[Slot] or ""
        local Unit = RaidAlt(Target)
        if Unit then
            local Have = Owns(Unit, Data) or Progress("storage." .. Unit, Data) > 0
            local Pity = Progress("raidPity." .. Unit, Data)
            local Max = Unit == "hutao" and 35 or 32
            Add("unit" .. Slot, ("Slot %d: %s"):format(Slot, NameOf(Unit)), 15, Have and Max or math.min(Pity, Max - 1), Max,
                Have and "owned" or ("pity %d/%d"):format(Pity, Max))
        end
    end
    -- counted against the slot targets, not what is owned, so the bar never steps back when
    -- a new unit arrives
    local Evolved, Total, WantsJinwoo = 0, 0, false
    for Slot = 1, 4 do
        local Target = Config.Slots[Slot] or ""
        if Counted(Slot) then
            Total = Total + 1
            if RaidAlt(Target) == "sung_jinwoo" then WantsJinwoo = true end
            local Info = Holder(Slot)
            if type(Info) == "table" and Info.IsUltimateUnlocked then Evolved = Evolved + 1 end
        end
    end
    if Total > 0 then Add("evolve", "Evolve (ultimate)", 15, Evolved, Total, ("%d/%d slots"):format(Evolved, Total)) end
    if WantsJinwoo then
        if not Owns("sung_jinwoo", Data) then
            Add("monarch", "Shadow Monarch stages", 10, 0, 2, "needs Sung Jinwoo")
            Add("igris", "Igris tree", 5, 0, 20, "needs Sung Jinwoo")
        else
            local Stage = Grow.Stage()
            Add("monarch", "Shadow Monarch stages", 10, math.max(Stage - 1, 0), 2, "stage " .. Stage .. "/3")
            local Levels = 0
            if Grow.Path and Grow.Path.IgrisTree then
                for _, Node in ipairs({ "Blade", "Command", "Speed", "Loyalty" }) do
                    local Ok, Level = pcall(Grow.Path.GetNodeLevel, Account.getLocalPlayerAccount(), Node)
                    Levels = Levels + (Ok and tonumber(Level) or 0)
                end
            end
            Add("igris", "Igris tree", 5, Levels, 20, ("%d/20 levels"):format(Levels))
        end
    end
    local Last = Config.Slots[4] or ""
    if Last ~= "" and Rollable(Last) then
        local Held = Assign[4] and SlotData(Assign[4], Data)
        local S = SlotData(4, Data)
        Add("slot4", "Slot 4: " .. Last, 5, Held and 1 or 0, 1, Held and NameOf(Held.Character) or (S and S.Unlocked and "spinning" or "locked"))
    end

    -- re-scale the weights that apply to 100
    local Sum = 0
    for _, Part in ipairs(Parts) do Sum = Sum + Part.weight end
    local Overall, AllDone = 0, #Parts > 0
    for _, Part in ipairs(Parts) do
        if not Part.done then AllDone = false end
        Part.weight = Sum > 0 and math.floor(Part.weight / Sum * 1000 + 0.5) / 10 or 0
        Overall = Overall + Part.weight * Part.percent / 100
    end
    -- weights are rounded to 0.1: a finished run must still read exactly 100
    return Parts, AllDone and 100 or math.min(math.floor(Overall * 10 + 0.5) / 10, 99.9), AllDone
end

function Site.Payload()
    local Data = AccountTable()
    if not Data then return nil end
    local Parts, Percent, AllDone = Site.Parts(Data)
    local Main = Plan.Main(Data)
    local C = Data.currencies or { }
    local Mode = workspace:GetAttribute("Mode")
    local Maps = { hxh = "Story - Hxh", sololevelingraid = "Raid - Shadow Gate", spiritedawayraid = "Raid - Spirit's Bathtub", tutorial = "Tutorial" }
    local Where = IsMatch and (Maps[Mode] or tostring(Mode or "Match")) or nil
    local function Num(N)
        N = tonumber(N) or 0
        for _, Unit in ipairs({ { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }) do
            if math.abs(N) >= Unit[1] then return ("%.2f"):format(N / Unit[1]):gsub("%.?0+$", "") .. Unit[2] end
        end
        return tostring(math.floor(N))
    end

    local Level = nil
    Plan.PlayerLevel(Data) -- loads Plan.Levels
    pcall(function()
        local Info = Plan.Levels.getProgress(C.xp or 0)
        Level = { level = tonumber(Info.level), xp = tonumber(Info.currentXp), need = tonumber(Info.requiredXp), max = Info.isMaxLevel == true }
    end)
    local Currencies = { }
    for _, Key in ipairs({ "money", "gems", "luckySpins", "rolls", "traitRerolls" }) do
        table.insert(Currencies, { icon = "currency-" .. Key, label = ({ money = "Coins", gems = "Gems", luckySpins = "Lucky Spins", rolls = "Rolls", traitRerolls = "Trait Rerolls" })[Key],
            value = tonumber(C[Key]) or 0, delta = 0 })
    end
    local Recent = { }
    local Ok, History = pcall(function() return HttpService:JSONDecode(Data.matchHistory) end)
    for _, Entry in ipairs(Ok and type(History) == "table" and History or { }) do
        if #Recent >= 6 then break end
        if type(Entry) == "table" then
            table.insert(Recent, { won = Entry.won == true, mode = tostring(Entry.mode or "-"), map = tostring(Entry.map or "-"),
                difficulty = tostring(Entry.difficulty or "-"), wave = tonumber(Entry.wave) or 0, kills = tonumber(Entry.kills) or 0,
                at = tonumber(Entry.time) or 0, character = Entry.character and NameOf(Entry.character) or "-" })
        end
    end
    local Team = { }
    for Slot = 1, 4 do
        local S = SlotData(Slot, Data)
        if S and S.Unlocked then
            local Info = S.Character ~= "" and Data.CharactersData and Data.CharactersData[S.Character]
            table.insert(Team, { slot = Slot, locked = false, name = S.Character ~= "" and NameOf(S.Character) or nil,
                rarity = S.Character ~= "" and (Characters[S.Character] or { }).Rarity or nil,
                evolved = type(Info) == "table" and Info.IsUltimateUnlocked == true })
        else
            table.insert(Team, { slot = Slot, locked = true })
        end
    end
    local Stats = Data.matchStats or { }
    local Runtime = math.floor(os.clock() - StartedAt)

    -- what the run has gained since "Start farm" (kept on disk, so teleports do not reset it)
    local MainLevel = Main and Grow.Level(Main, Data) or 0
    local PlayerLevel = Plan.PlayerLevel(Data)
    local Base = Saved.Base
    if type(Base) ~= "table" then
        Base = { At = os.time(), money = tonumber(C.money) or 0, gems = tonumber(C.gems) or 0, luckySpins = tonumber(C.luckySpins) or 0,
            level = PlayerLevel, main = MainLevel, mainId = Main, wins = tonumber(Stats.wins) or 0, played = tonumber(Stats.played) or 0 }
        Saved.Base = Base
        Save()
    end
    local function Signed(N) N = tonumber(N) or 0 return (N >= 0 and "+" or "-") .. Num(math.abs(N)) end
    local Took = math.max(os.time() - (tonumber(Base.At) or os.time()), 0)
    Status.Gains = {
        ("เวลาฟาร์ม  %dh %02dm"):format(Took // 3600, Took % 3600 // 60),
        ("Coins  %s"):format(Signed((tonumber(C.money) or 0) - (Base.money or 0))),
        ("Gems  %s"):format(Signed((tonumber(C.gems) or 0) - (Base.gems or 0))),
        ("Player  Lv%d → Lv%d"):format(Base.level or 0, PlayerLevel),
        ("%s  Lv%d → Lv%d"):format(Main and NameOf(Main) or "Main", Base.mainId == Main and (Base.main or 0) or MainLevel, MainLevel),
        ("ชนะ  %d / %d ด่าน"):format((tonumber(Stats.wins) or 0) - (Base.wins or 0), (tonumber(Stats.played) or 0) - (Base.played or 0)),
    }

    return {
        mode = "kaitan",
        userId = LocalPlayer.UserId,
        name = LocalPlayer.Name,
        displayName = LocalPlayer.DisplayName,
        placeId = game.PlaceId,
        jobId = game.JobId,
        players = #Players:GetPlayers(),
        uptime = Runtime,
        phase = Status.Phase,
        action = Status.Text ~= "" and Status.Text or Status.Plan,
        executor = (function() local Ok2, Name = pcall(identifyexecutor) return Ok2 and tostring(Name) or "unknown" end)(),
        progress = Percent,
        done = AllDone == true,
        parts = Parts,
        goal = { Slots = Config.Slots },
        acks = Site.Acks,
        state = {
            Game = "Anime Zero",
            Farming = Farming(),
            Carry = { jinwoo = Carry.ChildDone(Data), role = Carry.Role(), room = Carry.Room,
                done = Carry.Role() == "child" and Carry.ChildDone(Data) or nil },
            Stats = {
                { label = "Main", value = Main and ("%s Lv%d"):format(NameOf(Main), Grow.Level(Main, Data)) or "-", hint = Status.Plan ~= "" and ("Next: " .. Status.Plan) or nil },
                { label = "Player", value = "Lv" .. Plan.PlayerLevel(Data), hint = Num(C.gems) .. " gems" },
                { label = "Coins", value = Num(C.money), hint = Num(C.luckySpins) .. " lucky spins", icon = "currency-money" },
                { label = Where and "Match" or "Lobby", value = Where or "In lobby", hint = Status.Text },
            },
            Report = {
                level = Level,
                location = Where and { inMatch = true, map = Where, detail = Status.Text } or { inMatch = false },
                currencies = Currencies,
                gains = { },
                recent = Recent,
                team = Team,
                session = { runtime = Runtime, matches = 0, wins = 0 },
                totals = { played = tonumber(Stats.played) or 0, wins = tonumber(Stats.wins) or 0, kills = tonumber(Stats.kills) or 0, deaths = tonumber(Stats.deaths) or 0 },
            },
        },
    }
end

function Site.Apply(Reply)
    if type(Reply) == "table" and type(Reply.carry) == "table" then pcall(Carry.Apply, Reply.carry) end
    local Global = type(Reply) == "table" and Reply.global
    if type(Global) ~= "table" or type(Global.values) ~= "table" then return end
    local At = tonumber(Global.at) or 0
    if At <= (tonumber(Saved.GlobalAt) or 0) then return end
    local Ok, Err = pcall(ApplyGlobal, Global.values)
    if not Ok then return Note("Global settings rejected: " .. tostring(Err)) end
    Saved.Global, Saved.GlobalAt = Global.values, At
    Save()
    Note("Global settings from the website applied")
    pcall(UpdateSlotStatus)
end

-- Start / Stop farm: commands queued by the website ride back on the reply (the Control Script
-- queue). Each id is applied once and acknowledged on the next report.
function Site.Commands(Reply)
    Site.Fast = type(Reply) == "table" and Reply.fast == true
    local List = type(Reply) == "table" and type(Reply.commands) == "table" and Reply.commands or { }
    for _, Command in ipairs(List) do
        if type(Command) == "table" and type(Command.id) == "string" then
            table.insert(Site.Acks, Command.id)
            if not Site.Seen[Command.id] then
                Site.Seen[Command.id] = true
                local At = tonumber(Command.at) or 0
                if Command.flag == "KaitanFarm" and type(Command.value) == "boolean" and At > (tonumber(Saved.FarmAt) or 0) then
                    Saved.Farm, Saved.FarmAt = Command.value, At
                    if Command.value then
                        Saved.Base = nil -- "gained so far" counts from this start
                        Carry.Urgent() -- the group forms on the next reports
                    end
                    Save()
                    Note(Command.value and "Start farm (website)" or "Stop farm (website)")
                end
            end
        end
    end
end

-- every loop while something changed or a command may be waiting, at least every 30 s;
-- a failed post waits 60 s
function Site.Report()
    if not (Config.Web and Site.Http) or not Account then return end
    local Now = os.clock()
    if Now < Site.Quiet then return end
    local Key = Site.Key()
    if not Key then
        Site.Text = "no licence key"
        return
    end
    local Payload = Site.Payload()
    if not Payload then return end
    local Uptime, Runtime = Payload.uptime, Payload.state.Report.session.runtime
    Payload.uptime, Payload.state.Report.session.runtime = 0, 0
    local Printed, Print = pcall(HttpService.JSONEncode, HttpService, Payload)
    Payload.uptime, Payload.state.Report.session.runtime = Uptime, Runtime
    local Made, Body = pcall(HttpService.JSONEncode, HttpService, Payload)
    if not (Made and Printed) then return end
    if Print == Site.Print and Now - Site.PostAt < 30 and Farming() and not Site.Fast and not Carry.Busy() and #Site.Acks == 0 then return end

    local Ok, Response = pcall(Site.Http, {
        Url = Config.SiteUrl, Method = "POST",
        Headers = { ["Content-Type"] = "application/json", ["x-valkyrie-key"] = Key },
        Body = Body,
    })
    local Code = Ok and type(Response) == "table" and tonumber(Response.StatusCode or Response.Status)
    if Code and Code >= 200 and Code < 300 then
        Site.Print, Site.PostAt = Print, Now
        Site.Acks = { }
        Status.Percent = Payload.progress
        Site.Text = "sent " .. os.date("%H:%M:%S")
        local Decoded, Reply = pcall(HttpService.JSONDecode, HttpService, Response.Body)
        if Decoded then
            Site.Apply(Reply)
            Site.Commands(Reply)
        end
    else
        Site.Quiet = Now + 60
        Site.Text = "failed (" .. (Code == 401 and "key not accepted" or Code == 429 and "account limit" or tostring(Code or "no response")) .. ")"
    end
end

---- ============ Status panel ============ ----
-- fixed card in the middle of the screen, black and white: Welcome + logo, Dashboard / Discord
-- buttons, then one card: avatar + name + main character, STATUS (what it is doing now, next)

local Panel = { }

local Theme = {
    Back = Color3.fromRGB(12, 12, 12), Card = Color3.fromRGB(20, 20, 20), Line = Color3.fromRGB(38, 38, 38),
    Text = Color3.fromRGB(245, 245, 245), Dim = Color3.fromRGB(165, 165, 165), Muted = Color3.fromRGB(110, 110, 110),
    Track = Color3.fromRGB(36, 36, 36),
}

-- Montserrat for headings and numbers, Gotham for reading text (Thai falls back to the system font)
local function Family(Name, Weight)
    local Ok, Value = pcall(Font.new, "rbxasset://fonts/families/" .. Name .. ".json", Weight or Enum.FontWeight.Regular)
    return Ok and Value or Font.fromEnum(Enum.Font.Gotham)
end
local function Heading(Weight) return Family("Montserrat", Weight or Enum.FontWeight.SemiBold) end
local function Body(Weight) return Family("GothamSSm", Weight) end

local function New(Class, Props, Children)
    local Object = Instance.new(Class)
    for Key, Value in pairs(Props or { }) do Object[Key] = Value end
    for _, Child in ipairs(Children or { }) do Child.Parent = Object end
    return Object
end

-- what the screen shows instead of this account's name (Config.HideName)
local HiddenName = "Valkyrie On Top"

local function Corner(Radius) return New("UICorner", { CornerRadius = UDim.new(0, Radius) }) end
local function Pad(V, H)
    return New("UIPadding", { PaddingTop = UDim.new(0, V), PaddingBottom = UDim.new(0, V), PaddingLeft = UDim.new(0, H), PaddingRight = UDim.new(0, H) })
end

local function Label(Props)
    local Object = New("TextLabel", {
        BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        TextColor3 = Theme.Text, FontFace = Body(), TextSize = 14, RichText = true, TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
    })
    for Key, Value in pairs(Props) do Object[Key] = Value end
    return Object
end

local function CardFrame(Props)
    local Frame = New("Frame", { BackgroundColor3 = Theme.Card, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y },
        { Corner(10), New("UIStroke", { Color = Theme.Line, Thickness = 1 }), Pad(14, 16),
            New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
    for Key, Value in pairs(Props) do Frame[Key] = Value end
    return Frame
end

local function BuildPanel()
    local Parent = (gethui and gethui()) or game:GetService("CoreGui")
    local Gui = New("ScreenGui", { Name = "\0", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })

    local Main = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(560, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Back, BorderSizePixel = 0, Parent = Gui,
    }, { Corner(14), New("UIStroke", { Color = Theme.Line, Thickness = 1 }), Pad(22, 22),
        New("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }) })

    local Header = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 88), LayoutOrder = 1, Parent = Main })
    New("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, -110, 0, 40), Text = "Welcome",
        TextXAlignment = Enum.TextXAlignment.Left, FontFace = Heading(Enum.FontWeight.Bold), TextSize = 34, TextColor3 = Theme.Text, Parent = Header })
    New("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(1, 48), Size = UDim2.new(1, -110, 0, 22), Text = "Valkyrie Hub",
        TextXAlignment = Enum.TextXAlignment.Left, FontFace = Heading(Enum.FontWeight.Medium), TextSize = 19, TextColor3 = Theme.Dim, Parent = Header })
    New("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(1, 72), Size = UDim2.new(1, -110, 0, 14), Text = "Anime Zero · Kaitan",
        TextXAlignment = Enum.TextXAlignment.Left, FontFace = Body(), TextSize = 13, TextColor3 = Theme.Muted, Parent = Header })
    New("ImageLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(88, 88), BackgroundTransparency = 1,
        Image = "rbxassetid://87057639235201", ScaleType = Enum.ScaleType.Fit, Parent = Header })

    local Buttons = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 38), LayoutOrder = 2, Parent = Main },
        { New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10) }) })
    local function Button(Text, Filled, Url)
        local B = New("TextButton", { Size = UDim2.new(0.5, -5, 1, 0), Text = Text, AutoButtonColor = true,
            BackgroundColor3 = Filled and Theme.Text or Theme.Back, TextColor3 = Filled and Theme.Back or Theme.Text,
            FontFace = Heading(Enum.FontWeight.SemiBold), TextSize = 14, Parent = Buttons }, { Corner(8) })
        if not Filled then New("UIStroke", { Color = Theme.Line, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = B }) end
        B.MouseButton1Click:Connect(function()
            pcall(setclipboard or toclipboard, Url)
            B.Text = "Copied"
            task.delay(1.5, function() if B.Parent then B.Text = Text end end)
        end)
    end
    Button("Copy Dashboard", true, Config.DashboardUrl)
    Button("Copy Discord", false, Config.DiscordUrl)

    -- one card (user 2026-10-10: no "gained" card): who is farming, then what it is doing now
    local Card = CardFrame({ LayoutOrder = 3, Parent = Main })
    local Profile = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 52), LayoutOrder = -2, Parent = Card })
    New("ImageLabel", { Size = UDim2.fromOffset(52, 52), BackgroundColor3 = Theme.Track, BorderSizePixel = 0,
        Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(LocalPlayer.UserId), Parent = Profile },
        { Corner(26), New("UIStroke", { Color = Theme.Line, Thickness = 1 }) })
    Panel.Name = New("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(66, 7), Size = UDim2.new(1, -66, 0, 20), Text = "",
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, FontFace = Heading(Enum.FontWeight.SemiBold), TextSize = 17,
        TextColor3 = Theme.Text, Parent = Profile })
    Panel.Who = New("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(66, 29), Size = UDim2.new(1, -66, 0, 16), Text = "",
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, FontFace = Body(), TextSize = 13, TextColor3 = Theme.Muted, Parent = Profile })
    New("Frame", { BackgroundColor3 = Theme.Line, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 1), LayoutOrder = -1, Parent = Card })
    local Row = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 1, Parent = Card })
    Panel.Badge = New("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -80, 1, 0), Text = "STATUS", TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Theme.Muted, FontFace = Body(Enum.FontWeight.Medium), TextSize = 12, Parent = Row })
    Panel.Percent = New("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(80, 16),
        Text = "--%", TextXAlignment = Enum.TextXAlignment.Right, FontFace = Heading(Enum.FontWeight.SemiBold), TextSize = 15, TextColor3 = Theme.Text, Parent = Row })
    Panel.Headline = Label({ LayoutOrder = 2, FontFace = Heading(Enum.FontWeight.SemiBold), TextSize = 20, Parent = Card })
    Panel.Sub = Label({ LayoutOrder = 3, TextSize = 14, TextColor3 = Theme.Dim, Parent = Card })
    local Track = New("Frame", { BackgroundColor3 = Theme.Track, Size = UDim2.new(1, 0, 0, 4), LayoutOrder = 4, Parent = Card }, { Corner(2) })
    Panel.Fill = New("Frame", { BackgroundColor3 = Theme.Text, Size = UDim2.new(0, 0, 1, 0), Parent = Track }, { Corner(2) })
    Panel.Next = Label({ LayoutOrder = 5, TextSize = 14, TextColor3 = Theme.Dim, Parent = Card })

    Gui.Parent = Parent
    Panel.Gui = Gui
end

local function Escape(Text)
    return (tostring(Text):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function Gray(Text)
    return '<font color="#8a8a8a">' .. Text .. "</font>"
end

local function RenderPanel()
    local Waiting = not Farming()
    local Up = math.floor(os.clock() - StartedAt)
    local Where = IsLobby and "Lobby" or (IsMatch and "Match" or "?")

    Panel.Badge.Text = (Waiting and "WAITING" or (Status.Phase == "Error" and "ERROR" or (IsMatch and "IN MATCH" or "FARMING")))
        .. ("  ·  %s  ·  %02d:%02d:%02d  ·  website %s"):format(Where, Up // 3600, Up % 3600 // 60, Up % 60, Site.Text)

    local Percent = tonumber(Status.Percent)
    Panel.Percent.Text = Percent and ("%.1f%%"):format(Percent) or "--%"
    Panel.Fill.Size = UDim2.new(math.clamp((Percent or 0) / 100, 0, 1), 0, 1, 0)

    if Waiting then
        Panel.Headline.Text = "รอสั่งการจากเว็บ"
        Panel.Sub.Text = "กด เริ่มฟาร์ม ที่ valkyriehub.net › ข้อมูลสคริปต์ › ไก่ตัน" .. (Config.Web and "" or "  (Web ปิดอยู่)")
    else
        Panel.Headline.Text = Escape(Status.Phase)
        Panel.Sub.Text = Escape(Status.Text ~= "" and Status.Text or "-")
    end
    Panel.Next.Text = Status.Plan ~= "" and (Gray("ต่อไป  ") .. Escape(Status.Plan)) or ""
    Panel.Next.Visible = Status.Plan ~= ""

    -- HideName can change from the website at any time
    Panel.Name.Text = Config.HideName and HiddenName or LocalPlayer.DisplayName
    local Parts = { Config.HideName and "Valkyrie Hub" or ("@" .. LocalPlayer.Name), Status.Main }
    Panel.Who.Text = table.concat(Parts, "  ·  ")
end

---- ============ Performance (FPS boost / white screen) ============ ----
-- Only while farming. Boost is client-side only (what this PC draws; the server and the game's
-- logic see nothing) and stays for the session; the blank screen and the FPS cap follow
-- Start / Stop farm and are undone by KaitanCleanup.

local Perf = { Boosted = false }

local function Lighten(Object)
    if Object:IsA("ParticleEmitter") or Object:IsA("Trail") or Object:IsA("Beam") or Object:IsA("Smoke")
        or Object:IsA("Fire") or Object:IsA("Sparkles") then
        Object.Enabled = false
    elseif Object:IsA("Decal") or Object:IsA("Texture") then
        Object.Transparency = 1
    elseif Object:IsA("BasePart") then
        Object.Material = Enum.Material.Plastic
        Object.Reflectance = 0
        Object.CastShadow = false
    elseif Object:IsA("PostEffect") or Object:IsA("Atmosphere") or Object:IsA("Clouds") then
        pcall(function() Object.Enabled = false end)
        if Object:IsA("Atmosphere") then Object.Density = 0 end
    elseif Object:IsA("Explosion") then
        Object.Visible = false
    end
end

function Perf.Boost()
    if Perf.Boosted then return end
    Perf.Boosted = true
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    local Lighting = game:GetService("Lighting")
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e9
        Lighting.EnvironmentDiffuseScale, Lighting.EnvironmentSpecularScale = 0, 0
    end)
    pcall(function()
        local Terrain = workspace:FindFirstChildOfClass("Terrain")
        Terrain.WaterWaveSize, Terrain.WaterWaveSpeed, Terrain.WaterReflectance, Terrain.WaterTransparency = 0, 0, 0, 0
        Terrain.Decoration = false
    end)
    for _, Root in ipairs({ workspace, Lighting }) do
        for _, Object in ipairs(Root:GetDescendants()) do pcall(Lighten, Object) end
        -- skill VFX, drops and new areas keep spawning: light those too
        TrackConnection(Root.DescendantAdded:Connect(function(Object)
            if Live() then task.defer(pcall, Lighten, Object) end
        end))
    end
end

-- no overlay (user 2026-10-10: the game's UI and mouse must stay visible) - with 3D rendering
-- off the world is simply not drawn and every ScreenGui still is
function Perf.Screen(On)
    if Perf.Rendering ~= On then
        Perf.Rendering = On
        pcall(RunService.Set3dRenderingEnabled, RunService, not On)
    end
end

-- name -> HiddenName in every text of the game's UI (checked each second: the boss bar rewrites
-- its damage list all the time) + the Roblox player list off
local function Plain(Text) return (Text:gsub("[%p]", "%%%0")) end
function Perf.HideName()
    local Hide = Config.HideName == true
    if Hide ~= (Perf.ListOff == true) then
        local Ok = pcall(function() game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, not Hide) end)
        if Ok then Perf.ListOff = Hide end
    end
    if not Hide then return end
    local Gui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not Gui then return end
    local Names = { Plain(LocalPlayer.Name) }
    if LocalPlayer.DisplayName ~= LocalPlayer.Name then table.insert(Names, Plain(LocalPlayer.DisplayName)) end
    for _, Object in ipairs(Gui:GetDescendants()) do
        if Object:IsA("TextLabel") or Object:IsA("TextButton") then
            local Text = Object.Text
            for _, Name in ipairs(Names) do Text = Text:gsub(Name, HiddenName) end
            if Text ~= Object.Text then Object.Text = Text end
        end
    end
end

function Perf.Step()
    local On = Farming() and Live()
    local P = Config.Performance or { }
    pcall(Perf.HideName)
    if On and P.Boost then pcall(Perf.Boost) end
    pcall(Perf.Screen, On and P.WhiteScreen == true)
    local Cap = On and tonumber(P.FpsCap) or 0
    if Cap ~= Perf.Cap and setfpscap then
        Perf.Cap = Cap
        pcall(setfpscap, Cap > 0 and Cap or 240)
    end
end

function Perf.Stop()
    pcall(Perf.Screen, false)
    if Perf.Cap and Perf.Cap > 0 and setfpscap then pcall(setfpscap, 240) end
    if Perf.ListOff then pcall(function() game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true) end) end
end

---- ============ Re-run after teleport ============ ----

local function Serialize(Value)
    if type(Value) == "table" then
        local Parts = { }
        for Key, Item in pairs(Value) do
            table.insert(Parts, ("[%s]=%s"):format(type(Key) == "number" and tostring(Key) or ("%q"):format(Key), Serialize(Item)))
        end
        return "{" .. table.concat(Parts, ",") .. "}"
    elseif type(Value) == "string" then
        return ("%q"):format(Value)
    end
    return tostring(Value)
end

-- this file as served by the site (the queued chunk re-runs it in the next place)
local KaitanUrl = "https://www.valkyriehub.net/api/raw/anime-zero-kaitan"

local function QueueSelf()
    local Queue = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
    if type(Queue) ~= "function" then return end
    local Source = Config.Loader ~= "" and Config.Loader or getgenv().KaitanLoader
    if type(Source) ~= "string" or Source == "" then
        Source = ('loadstring(game:HttpGet(%q))()'):format(KaitanUrl)
    end
    local Keys = { }
    for _, Name in ipairs({ "LicenseKey", "License", "Key", "ValkyrieKey", "Mode", "ValkyrieProduct" }) do
        local Value = getgenv()[Name]
        if type(Value) == "string" and Value ~= "" then table.insert(Keys, ("getgenv().%s = %q"):format(Name, Value)) end
    end
    -- executor autoexec may load the same file too: first one per server wins
    pcall(Queue, ("if getgenv().KaitanBooted == game.JobId then return end getgenv().KaitanBooted = game.JobId\ngetgenv().Kaitan = %s\ngetgenv().KaitanLoader = %q\n%s\n%s"):format(
        Serialize(Overrides), getgenv().KaitanLoader or "", table.concat(Keys, "\n"), Source))
end

---- ============ Boot ============ ----

if Config.AntiAFK then
    pcall(function()
        local VirtualUser = game:GetService("VirtualUser")
        TrackConnection(LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.zero)
        end))
    end)
end

local QueuedAt = nil
TrackConnection(LocalPlayer.OnTeleport:Connect(function(State)
    if State ~= Enum.TeleportState.Started and State ~= Enum.TeleportState.InProgress then return end
    if QueuedAt and os.clock() - QueuedAt < 5 then return end
    QueuedAt = os.clock()
    QueueSelf()
end))

pcall(BuildPanel)
task.spawn(function()
    while Live() and Panel.Gui do
        pcall(RenderPanel)
        task.wait(0.25)
    end
end)
task.spawn(function()
    while Live() do
        Perf.Step()
        task.wait(1)
    end
end)

getgenv().KaitanCleanup = function()
    getgenv().KaitanSession = nil
    for _, Connection in ipairs(SessionConnections) do pcall(function() Connection:Disconnect() end) end
    for _, Hook in ipairs(Join.Hooks) do Unhook(Hook) end
    if Battle.HitHook then Unhook(Battle.HitHook) end
    pcall(Battle.Unpatch)
    if Battle.Controller and Battle.Holding then pcall(Battle.Controller.setTouchHeld, "Attack", false) end
    if Battle.Footer then pcall(function() Battle.Footer:Destroy() end) end
    if Panel.Gui then pcall(function() Panel.Gui:Destroy() end) end
    Perf.Stop()
    getgenv().KaitanCleanup = nil
end

-- the menu hub loaded after us (autoexec / its own teleport queue) = stop it, one driver only
task.spawn(function()
    while Live() do
        if type(getgenv().ValkyrieCleanup) == "function" then
            pcall(getgenv().ValkyrieCleanup)
            getgenv().ValkyrieCleanup = nil
            Note("Stopped the Valkyrie Hub menu - Kaitan runs alone")
        end
        task.wait(2)
    end
end)

task.spawn(function()
    task.wait(5)
    while Live() do
        pcall(Site.Report)
        -- a waiting account polls faster so "Start farm" lands within seconds
        task.wait((Site.Fast or Carry.Busy()) and 2 or (Farming() and 15 or 4))
    end
end)

getgenv().AZKaitan = { Site = Site, Config = Config, Status = Status, Battle = Battle, Saved = Saved, Plan = Plan, Grow = Grow, Satisfies = Satisfies }

task.spawn(function()
    if IsLobby then
        Say("Lobby", "Loading")
        LobbyMain()
    elseif IsMatch then
        Say("Match", "Loading")
        MatchMain()
    else
        Say("Idle", "Not an Anime Zero lobby or match place")
    end
end)
