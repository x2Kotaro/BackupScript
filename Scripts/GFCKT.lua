--[[
    Valkyrie Hub // Grow a Chicken Fighter -- KAITAN EDITION (GFCKT)

    GFC.lua is the menu build: every feature is a toggle the player flips.
    This file is the same engine with the menu taken out.

    "ไก่ตัน" means a fresh account is driven, unattended, from nothing to an
    account that already has everything worth having. There is no interface to
    operate -- the window only reports what the run is doing, what the account
    now holds, and how far each target still is.

    The plan the engine follows, and why, is written out in PLAN below.
--]]

--[[ ============================ PLAN ============================

    Read off the live client (Catalog, GameConfig, FusionRules, RebirthBonus,
    TowerFloor, RosterCap), not guessed:

    POWER
      hp  = 100 * 1.1^(level-1) * archetype.hp  * rarityMult * (1 + vigor/31 * 0.5)
      atk =  10 * 1.1^(level-1) * archetype.atk * rarityMult * (1 + furia/31 * 0.5)

      rarityMult: common 1.00  uncommon 1.08  rare 1.15  epic 1.24
                  legendary 1.35  mythic 1.50  divine 1.70
                  celestial 1.95  cosmic 2.25  secret 2.60

      Level is worth 10% compounding per point, so it dwarfs everything else:
      the whole secret-over-common rarity gap (2.6x) is only ten levels, and a
      full 31/31 power gene is worth four. Level is therefore what a tower run
      is for, and rarity plus genes are what survives a rebirth.

    TOWER
      floor N fields an enemy of level max(1, floor((N-1) * 1.2 + 0.5)), and
      TowerElevator can start a run at any floor up to best+1 for money. So the
      climb is gated by the chicken's level, and the run is what raises it.

    REBIRTH  (this is the part worth reading)
      Rebirth needs tower.best >= 25 + 5*ln(1 + 0.4*count), which is
        count  0 ->25   3 ->29   5 ->30   10 ->33   15 ->35   20 ->36
              25 ->37  50 ->40  75 ->42  100 ->44
      -- a log curve, so the requirement itself climbs only about one floor
      per several rebirths.

      tower.best IS RESET BY A REBIRTH. This file used to say the opposite and
      built a policy on it -- bank a floor once, chain the next ten rebirths
      free. Read off a live save at rebirth 34 the tower key is

        tower = { best = 0, bestTime = 0, peak = 53 }

      immediately after a rebirth. `best` is the current life's high and goes
      back to zero every time; `peak` is the all-time record and is the one
      that survives. Nothing reads peak, because nothing is gated on it.

      So every rebirth is paid for with a fresh climb from the bottom to
      requirementFloor(count) -- 38 floors at rebirth 34 -- and there is no
      headroom to bank. Config.Build.TowerFloor is therefore not a floor the
      run keeps in hand; it is only the point past which RebirthLevel stops
      being waited on.

      Rebirth also resets level, money, the coop and the recycler. The
      collection survives, at level 1. So genes and rarity are permanent,
      level is rented, and the plot is rebuilt every single time -- which is
      why the recycler install is the first purchase after one.

      What is banked:
        money multiplier = 1 + count * 0.15 + points * 0.02
        points          += floor(activeChickenLevel / 2)  at the moment of rebirth

      One rebirth = +15%. One active-chicken level held at the moment of the
      rebirth = +1%. Both add into the same multiplier, so rebirthing at level
      30 is worth 45% and rebirthing at level 1 is worth 15% -- and the level 1
      rebirth costs nothing but the coop rebuild, which the banked multiplier
      pays back in minutes.

      Hence the policy this file runs:
        * climb the tower until tower.best clears requirementFloor(count) --
          the floor THIS rebirth asks for, since there is no banking a higher
          one for later
        * rebirth as soon as that lands: RebirthLevel is 1 and the points a
          higher level would bank are worth less than the climb they cost
        * put the recycler back first, then the feeders, then everything else

    FUSION  (FusionRules.resolve, read directly)
      Every fuse takes max(geneA, geneB) per gene, so genes only ever go up.
      Fusing two chickens OF THE SAME RARITY additionally:
        * rolls the rarity up: common 25%, uncommon 18%, rare 12%, epic 8%,
          legendary 5%, mythic 3%, divine 2%, celestial 1%, cosmic 0.5%
        * guarantees one gene mutation (+1..2) and rolls 10% for each other
      Fusing across rarities does neither: it keeps the higher side's chassis
      and rarity, and is only worth doing when the low chicken actually holds a
      gene the champion is missing.

      Level, ability, look and the egg pool come from whichever side a lock
      says, and the account has 2 free lock slots. So every fuse this file
      sends locks LEVEL to the higher-level side and ABILITY to the better one.
      Eggs are deliberately left unlocked -- unlocked means both stashes are
      added together instead of one being dropped.

      GFC.lua fused Spare[1] with Spare[2] and sent no locks at all: mismatched
      rarities (no ascend, no mutation) and a coin flip on which level survived.
      That is the single biggest difference in this file.

      Gene caps are per rarity: common 8, uncommon 12, rare 16, epic 20,
      legendary 24, mythic 27, divine 29, celestial 30, cosmic/secret 31. A
      common cannot hold a gene above 8, which is why low-rarity partners stop
      being useful to a good champion.

    ARENA  (added 22 Aug)
      Ranked 3v3, one season every 28 days, opened by the game at rebirth 5.
      The server picks five opponents from the current team power -- two
      "even" (0.85x-1.15x), one "easier" (0.65x-0.85x), one "harder"
      (1.15x-1.4x), one "wildcard" (0.5x-1.75x) -- and a battle is a minute of
      server-side simulation the client only watches.

      Trophies: a win pays 35 + 18*log2(powerRatio) +- a rank modifier, clamped
      to 8..55; a loss costs 18 + 12*log2(1/powerRatio), clamped to 5..35. So
      beating something stronger pays roughly double beating something weaker,
      and the "harder" band is only worth taking with a team that can win it.

      Team power counts ATTACK ONLY, at 100x. Level is 10% compounding on
      attack, so the arena is scored by exactly the thing the tower raises --
      which is why the rank goal keeps the tower running past the last rebirth
      instead of parking it.

      Ranks run hatchling3 -> grandmaster1. Everything up to master5 is a
      trophy threshold and can be ground out; master4 and above are shares of
      the leaderboard (top 80%, 50%, 10%, 1%) and cannot.

      The run stays out of it until Goal.Rebirth is FINISHED, and then until
      Config.Arena.MinRarity lands on top of that. A rebirth resets the
      champion to level 1, and level is nearly all of team power, so fighting
      mid-climb wins trophies at level forty and hands them back at level one
      -- a hundred times over across a hundred rebirths. Trophies only stick
      once the resets stop.

    MUTATION  (added 22 Aug)
      Content.Mutations holds one, `inverted`: 0.5% on a hatch, x1.15 on hp and
      atk. There is no way to work towards one -- it is a hatch roll and
      nothing else -- so it is the only thing in the game the run treats as
      unsellable outright, whatever rarity is carrying it.

      GameConfig.fusion.mutationInherit is 0.5 and MutationView.fusionOdds
      returns a flat 1 when both sides carry the same one. Two things follow
      and the fusion planner runs on both:

        * a mutated common fused into a clean champion is an even chance of
          moving the mutation across, which makes it the cheapest mutation the
          champion will ever be offered -- so it goes to the top of the
          partner list rather than into a sell batch
        * a champion that ALREADY carries one loses it on any fuse where the
          partner does not, at the same 50%. So once the champion is mutated
          the only partner considered is one carrying the same mutation, and
          when there is none the champion is left alone entirely

      The mark is the game's own favourite flag, so it survives a rejoin. It
      means "never sold" and nothing else -- PlanFusion ignores it, because
      spending the chicken on the champion is the whole reason for keeping it.

    ARCHETYPE
      Same-rarity fusion picks the surviving chassis at random, so the body
      cannot be steered -- only scored. The best bodies in the catalog are
      nebula_hen and reaper_rooster (1.30/1.30, cosmic), error_chick
      (1.20/1.30, secret), crystal_hen and fenghuang (celestial), and at
      reachable rarities mecha_rooster, tank_rooster, champ_rooster,
      deepfried_hen and sniper_rooster.

    So what "ไก่ตัน" means here is one target and two things worth reporting:
    the rebirth count, the unhatched eggs the account is sitting on, and the
    rarity of the chicken laying them. The tower floor, the feeders and the
    recycler are means, not ends -- every one of them is deleted by the next
    rebirth -- so the run still builds them and no longer scores them.

  ============================================================== --]]

-- The clock the window counts from, taken before anything else runs so that
-- "uptime" means how long the executor has had this script rather than how long
-- the boot wait, the module scan and the interface took to get out of the way.
local StartedAt = os.clock()

getgenv().ConfigurationTable = {}
getgenv().Kaitan = getgenv().Kaitan or {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

while not LocalPlayer do
    task.wait()

    LocalPlayer = Players.LocalPlayer
end

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

-- The only asset this file draws: the logo in the window header.
--
-- This used to be one field of a `Where` table that also held the loader URL,
-- a cache path and the build's variant name -- all of them for the queued
-- teleport chunk, which is gone. Getting back onto a script after a teleport is
-- the executor's autoexec folder's job now, and it does it far more reliably
-- than queue_on_teleport ever did.
local IconAsset = "87057639235201"

---- ============ Configuration ============ ----

-- Everything the run aims at.
--
-- Override any of it by setting getgenv().Kaitan BEFORE executing this file:
--
--   getgenv().Kaitan = {
--       Goal = { Rebirth = 25 },
--       Server = { MaxPlayers = 2 },
--   }
--
-- Only the keys named are replaced and the rest keep the values below, so a
-- table with two keys in it changes two things and leaves everything else
-- alone. Nested tables merge the same way -- naming Goal.Rebirth does not wipe
-- Goal.Eggs -- with one deliberate exception: a LIST is replaced whole rather
-- than merged index by index, so Codes = { "RELEASE" } means that one code and
-- not that code plus whatever slot two used to hold.
local Config = {
    -- What the account is actually worth at the end of a run, and nothing else.
    --
    -- The tower floor, the feeder count and the recycler level used to be
    -- targets here. They are not what the account is worth -- they are what the
    -- account had to build on the way, and a rebirth throws two of the three
    -- away. So they are still built, because the run needs them, and they are
    -- no longer reported as though finishing them meant anything.
    --
    -- Rarity has no target at all. There is nothing above secret to stop at and
    -- no reason to stop below it, so the fusion planner climbs for as long as
    -- the run lasts and the rarity reached is reported rather than checked off.
    Goal = {
        Rebirth = 100,   -- rebirth count, and the one target the run stops at
        -- Unhatched eggs to sit on. 0 asks for none: the eggs are reported
        -- because the stash is what the account is holding, not because a
        -- number of them ends anything.
        Eggs    = 0,
        -- Arena rank to reach, by the game's own rank id, and "" asks for none.
        -- A rank is a real target rather than a by-product: it survives a
        -- rebirth, it is what the account is worth to anyone looking at it, and
        -- reaching it is the only thing in the run that depends on the chicken
        -- being genuinely strong rather than merely present.
        --
        --   hatchling3  hatchling2  hatchling1     0 / 100 / 200 trophies
        --   bronze3     bronze2     bronze1      300 / 400 / 500
        --   silver3     silver2     silver1      600 / 700 / 800
        --   gold3       gold2       gold1        900 / 1000 / 1100
        --   crystal3    crystal2    crystal1    1200 / 1350 / 1500
        --   diamond3    diamond2    diamond1    1650 / 1825 / 2000
        --   master5                             2200, then master4..master1,
        --   elite5..elite1, grandmaster3..grandmaster1  -- placement, not
        --   trophies: those are the top 80% / 50% / 10% / 1% of the league
        --
        -- Anything from master4 up is a share of the leaderboard rather than a
        -- number, so it cannot be reached by grinding alone. gold1 or crystal1
        -- is what an unattended run can actually finish.
        Rank    = "",
    },

    -- What the run builds in order to get there. None of this is a goal and
    -- none of it is reported as one -- a rebirth deletes the coop and resets
    -- the level, so a finished coop is worth nothing on its own. These are the
    -- levels the machine needs to keep turning, and they are here so they can
    -- still be tuned.
    Build = {
        TowerFloor    = 33,   -- floor to bank before chaining rebirths
        CoopSlots     = 6,    -- feeders; the game's own maximum is 6
        FeederLevel   = 20,   -- level every feeder is pushed to
        RecyclerLevel = 18,   -- 18 is the hard cap, reachable from rebirth 4
    },

    -- The champion level a rebirth waits for, and 1 means it never waits: the
    -- floor requirement being met is the whole condition.
    --
    -- Waiting for level costs more than it banks. A rebirth resets level, money
    -- AND the coop, so every feeder bought before one is thrown away, while
    -- tower.best is kept -- and the floor requirement only climbs by one per
    -- several rebirths. Holding out for level 20 buys 10 points, +20% money,
    -- for a climb that takes far longer than the ten rebirths the same time
    -- would have chained at +15% each.
    --
    -- Raise it only when the tower is already at its target and the run has
    -- nothing else to spend the time on.
    RebirthLevel = 1,

    -- Selling.
    --
    -- The line moves with the champion instead of naming rarities outright.
    -- Once the account is fusing legendaries a rare is fodder, and once it is
    -- fusing mythics a legendary is too -- a fixed list would have to be
    -- rewritten at every step and would be wrong in between.
    --
    -- Never sold whatever the arithmetic says: the champion, whatever is
    -- standing on the plot, anything favourited, anything holding a gene the
    -- champion still wants, and anything at Protect or above.
    Sell = {
        -- Two steps under the champion. A legendary champion makes commons
        -- and uncommons fodder; a mythic one adds rares. Below three the
        -- account is still climbing on whatever it has and nothing is sold at
        -- all, which is why an early roster fills up and then thins itself out
        -- once the first epic lands.
        Below   = 2,      -- sell what sits this many rarity steps under the champion
        Fodder  = 2,      -- ...but keep this many of each rarity, which is one fuse pair
        AtFrac  = 0.75,   -- start selling once the roster is this full
        Protect = "",     -- never sell at or above this rarity ("legendary", ...)
        -- Last resort. At this fill the roster is about to stop accepting
        -- hatches, and a run that cannot hatch cannot climb, so the weakest
        -- chickens go regardless of the rules above -- still never the
        -- champion, the plot chicken, a favourite, or anything at Protect.
        PanicFrac = 0.97,
        Batch   = 20,     -- most ids in one SellChickens call
    },

    -- Running speed, in studs per second. 0 leaves WalkSpeed alone, and 0 is
    -- what every one of these is set to, because writing WalkSpeed at all is
    -- what gets the account kicked.
    --
    -- This file used to hold 20 the whole time and reason about it from
    -- GameConfig.guard.speed: the distance check allows refWalk * mult +
    -- absolute, 16 * 1.5 + 4 = 28 studs a second, so 20 is comfortably inside
    -- it. That arithmetic is correct and it is about the wrong check.
    --
    -- The kick is not the distance guard. The character is network owned by the
    -- client, so a WalkSpeed written here replicates straight to the server, and
    -- the server never wrote anything but 16 -- lower still while scrap is being
    -- carried, out of scrap.weight. A property the server did not set, holding a
    -- value the game cannot produce, is the cheapest possible thing to kick for,
    -- and no value is small enough to hide in: GFC.lua carries the note that 18
    -- was tried and the kick still came.
    --
    -- The kick that arrives says the character's movement "didn't add up",
    -- which reads like the speed guard and sent this file chasing the threshold
    -- rather than the property.
    --
    -- Nothing is lost. Every errand here is a Humanoid:MoveTo, which walks at
    -- whatever speed the server set, and the run is not in a hurry -- it is
    -- unattended for hours.
    Speed = {
        Hold    = 0,     -- held at this the whole time, standing still included
        Collect = 0,     -- empty handed, on the way to a pickup
        Escape  = 0,     -- getting clear of a live pit fight
        Carry   = false, -- also write it while carrying scrap; never turn this on
    },

    -- a foreign chicken this close is treated as a fight in progress. Chickens
    -- reach 4 studs and a knockout costs scrap.stealPct, half of the load.
    PitDanger = 14,

    -- The plot is private, the pit is not. Every other player in the server is
    -- another champion in the pit knocking the load out of anyone standing
    -- there, another pair of hands on the same scrap under one shared
    -- scrap.looseCap, and another claim on the hot egg and the event drops.
    -- Servers here hold 8, so "quiet" means low single digits.
    Server = {
        Hop        = true,
        MaxPlayers = 4,    -- more than this in the server and the run leaves
        Recheck    = 30,   -- seconds between headcounts
    },

    -- Egg hunting. The chicken standing on the plot is the one that lays, and
    -- what it lays is decided by its own type, so chasing a better egg and
    -- putting the right chicken out are the same job.
    Eggs = {
        -- The best chicken in the bag stands on the plot. Best means rarity
        -- first -- rarity is permanent, level is not, and a rebirth wipes
        -- level while leaving rarity alone -- and among equals, whichever lays
        -- the better eggs. It is the same chicken either way; this only
        -- decides which of two mythics goes out.
        Hunt       = true,
        -- how much a chicken one further step down the egg chain still counts
        -- for. 0 scores only what hatches next; 0.6 sees three eggs ahead,
        -- which is what it takes to value the road to colossus
        Lookahead  = 0.6,
        -- a type the account has never hatched counts for this much more, so
        -- the run keeps opening what still holds something new
        Novelty    = 1.6,
        Target     = "",     -- pin one egg id ("crown", "golden", ...); empty picks
        -- Chase one named chicken instead of chasing rarity in general. The
        -- run works backwards from it -- which eggs drop it, which chicken in
        -- the bag lays those eggs -- and puts that chicken out, whatever its
        -- own rarity is. Empty leaves the ordinary rule alone.
        --
        -- What the live tables say is worth naming, with the odds the Index
        -- screen prints for each:
        --
        --   secret     golden_goose    Fortune 1.01%, Blazing 0.35%
        --              storm_colossus  Colossus 1.00%   (nothing else drops it)
        --              error_chick     Cursed 0.93%, Blazing 0.35%
        --   cosmic     reaper_rooster  Haunt 0.95%, Blazing 0.35%
        --              nebula_hen      Void 1.04%, Blazing 0.35%
        --   celestial  overclock       Circuit 2.60%, Blazing 0.35%
        --              fenghuang       Royal 1.15%, Blazing 0.35%
        --   divine     kitsune_hen     Royal 2.30%, Blazing 0.69%
        --              doll_hen        Haunt 1.90%, Blazing 0.69%
        Want       = "",
    },

    -- The ranked arena.
    --
    -- It is the last thing the run picks up, and it does not start until
    -- Goal.Rebirth is FINISHED. That is not caution, it is arithmetic: a loss
    -- costs trophies, and a rebirth resets the champion to level 1 -- which is
    -- most of team power, since the arena scores attack alone. A run that
    -- fights while it is still rebirthing wins a handful of trophies at level
    -- forty, rebirths, and hands them all back at level one, a hundred times
    -- over. Once the last rebirth is taken the level only ever climbs, and
    -- that is when trophies start sticking.
    --
    -- MinRarity is a second floor on top of that, for the case where the
    -- rebirth target is finished but the collection still is not worth
    -- fielding.
    --
    -- Skip names the opponent bands not worth spending a battle on. The game
    -- rolls five opponents -- two "even" (0.85x-1.15x of team power), one
    -- "easier" (0.65x-0.85x), one "harder" (1.15x-1.4x) and one "wildcard"
    -- (0.5x-1.75x) -- and skips refill five at a time every ten minutes, so
    -- skipping the ones that lose is free.
    Arena = {
        Enabled   = true,
        MinRarity = "epic",
        Skip      = { "harder" },
        Ability   = true,    -- let the server fire the team's abilities mid-fight
    },

    Tutorial   = true,   -- walk a brand new account through the onboarding steps
    Rewards    = true,   -- daily streak, play-today, missions, weekly pass, social
    Scrap      = true,   -- scrap runs into the recycler
    Events     = true,   -- boss, UFO, hot egg, event drops
    Incubator  = true,   -- buy and feed it once rebirth 3 unlocks it
    Codes      = { },    -- redeemed once at boot, e.g. { "RELEASE", "CLUCK" }

    -- Horst account manager, when the run is launched under one. Nothing here
    -- fails without it: the two functions are looked up every time and simply
    -- are not there on a normal executor.
    Horst = true,

    -- Live telemetry. Every account posts its own state to one endpoint, keyed
    -- by UserId, so one dashboard can hold the whole fleet. On or off, and
    -- nothing else: the endpoint, the posting interval and the licence key are
    -- not decisions a run has to make.
    --
    -- The key is whatever the loader already checked -- out of getgenv(), or
    -- out of the file whitelist_check.lua saved it in -- and the site resolves
    -- that to the Discord account whose dashboard this run belongs on.
    --
    -- Nothing here is allowed to slow the run down: a dead endpoint only makes
    -- the reporter back off.
    Web = true,

    -- Milestone messages, sent by this script straight to a Discord webhook.
    -- They deliberately do not travel through the site: the dashboard is a
    -- convenience that can be down or never set up at all, and an account that
    -- finished overnight still has to be able to say so.
    Discord = {
        Webhook    = "",
        Milestones = { 25, 50, 75, 100 },
    },


    -- Error 278 is Roblox's own twenty minute idle disconnect, and its timer
    -- counts INPUT -- nothing this run produces moves it on its own. See the
    -- Anti-AFK section for the exact shape of synthetic input that answers it
    -- without earning a kick from the game's own anti-cheat, and for the three
    -- things it deliberately does not do.
    AntiAFK      = true,
    AutoRejoin   = true,
    Language     = "English (US)",
}

local function MergeConfig(Into, From)
    for Key, Value in pairs(From) do
        -- a list is replaced whole, never merged index by index: overriding
        -- Codes with { "RELEASE" } has to mean only that code, not that code
        -- plus whatever the default list still had in slot two
        if type(Value) == "table" and type(Into[Key]) == "table" and #Value == 0 then
            MergeConfig(Into[Key], Value)
        else
            Into[Key] = Value
        end
    end
end

MergeConfig(Config, getgenv().Kaitan)

getgenv().ConfigurationTable = {
    Transparent = true,
    AntiAFK = Config.AntiAFK,
    AutoRejoin = Config.AutoRejoin,
    Language = Config.Language,
}

---- ============ Session ============ ----

local SessionToken = { }
local SessionConnections = { }

if type(getgenv().ValkyrieCleanup) == "function" then
    pcall(getgenv().ValkyrieCleanup)
end

getgenv().ValkyrieSession = SessionToken

-- require of a game ModuleScript comes back on a demoted thread, which then
-- cannot touch Instance at all. Nothing here requires anything, and where the
-- executor exposes an identity setter this puts the thread back to 8 anyway.
local SetIdentity = setthreadidentity or set_thread_identity or setidentity
    or (syn and syn.set_thread_identity)

local function Elevate()
    if SetIdentity then
        pcall(SetIdentity, 8)
    end
end

local function TrackConnection(Connection)
    if Connection then
        table.insert(SessionConnections, Connection)
    end

    return Connection
end

---- ============ Readiness ============ ----

-- The executor's autoexec folder re-runs this file the instant the next server
-- accepts the client, which is well before that client is a client. The module
-- scan below reads tables the game's own code has already required, the remote
-- sender needs ReplicatedStorage.Remotes, and every walking job needs a
-- character -- none of which exist yet at the moment autoexec fires. A run that
-- started two seconds after a teleport used to die on "could not find the
-- game's DataService table in memory", or come up with every view stubbed out
-- and quietly do nothing. So nothing starts until the client is actually up.

-- one table rather than three main-chunk locals: this file is already close
-- enough to Luau's per-function local ceiling that boot helpers are not worth
-- three slots of it
local Boot = { Deadline = os.clock() + 180 }

function Boot.TimeLeft()
    return Boot.Deadline - os.clock()
end

-- Waits for Test to answer true. Returns false when the boot deadline passes,
-- which is the run's signal to give up on this server and let AutoRejoin or the
-- server hopper put it somewhere healthier.
function Boot.WaitFor(What, Test, Every)
    local Told = false

    while Boot.TimeLeft() > 0 do
        local Ok, Ready = pcall(Test)

        if Ok and Ready then return true end

        if not Told then
            Told = true

            warn("[ValkyrieHub] waiting for " .. What)
        end

        task.wait(Every or 0.25)
    end

    warn("[ValkyrieHub] gave up waiting for " .. What)

    return false
end

do
    -- 1. the place itself. Everything else is meaningless before this.
    Boot.WaitFor("the place to finish loading", function()
        return game:IsLoaded()
    end)

    -- 2. the character. Movement, the pit, the arena and every walking job
    --    read it, and on a fresh join it lands several seconds after the
    --    place does.
    Boot.WaitFor("a character", function()
        local Character = LocalPlayer.Character

        return Character ~= nil
            and Character:FindFirstChildOfClass("Humanoid") ~= nil
            and Character:FindFirstChild("HumanoidRootPart") ~= nil
    end)

    -- 3. the game's own remote folder. RemoteByName is a FindFirstChild on it
    --    and warns for every remote it misses, so arriving before the folder
    --    replicates costs the run every remote it has.
    Boot.WaitFor("ReplicatedStorage.Remotes", function()
        local Folder = ReplicatedStorage:FindFirstChild("Remotes")

        return Folder ~= nil and #Folder:GetChildren() > 0
    end)

    -- 4. a beat for the client to get on with requiring its own modules.
    --
    --    This used to watch PlayerGui and wait for the ScreenGui count to stop
    --    growing, on the reasoning that the client requires its tables while
    --    it builds its screens. It worked, and it read a container this script
    --    has no business in: PlayerGui is the game's own, the game's scripts
    --    walk it, and every part of this file that draws anything is in CoreGui
    --    precisely so it never turns up in there. Reading it is quieter than
    --    writing to it and it is still a reason to be looking.
    --
    --    The same signal is available from the scan itself and costs nothing
    --    extra: the sweep below keeps going until the tables appear, and the
    --    optional views wait until the sweep stops finding new ones. So all
    --    that is left here is a short beat, and everything that used to be
    --    inferred from screens is now measured off what is actually wanted.
    task.wait(1)
end

---- ============ Game modules ============ ----

Elevate()

-- getgc(true) hands back every live table in the VM, which is how the client's
-- own already-required modules are reached without requiring anything. One
-- table per scan, walked in slices with a yield whenever a slice has held the
-- frame for more than eight milliseconds -- the unsliced walk is what used to
-- bounce phones out of the game.
local ScanSliceSeconds = 0.008
local ScanSliceStep = 512

local function ScanGarbage(Visit)
    if type(getgc) ~= "function" then return false end

    local Ok, Objects = pcall(getgc, true)

    if not (Ok and type(Objects) == "table") then return false end

    local Since = 0
    local SliceStart = os.clock()

    for Index = 1, #Objects do
        local Value = Objects[Index]

        if type(Value) == "table" then
            local Fine, Stop = pcall(Visit, Value)

            if Fine and Stop then return true end
        end

        Since = Since + 1

        if Since >= ScanSliceStep then
            Since = 0

            if os.clock() - SliceStart > ScanSliceSeconds then
                task.wait()

                SliceStart = os.clock()
            end
        end
    end

    return false
end

local Modules = { }

do
    if type(getgc) ~= "function" then
        error("[ValkyrieHub] this executor has no getgc, which is how the game's own modules are reached without require", 0)
    end

    local Patterns = {
        DataService = function(Value)
            local Client = rawget(Value, "client")

            return type(Client) == "table" and type(rawget(Client, "get")) == "function"
        end,

        GameConfig = function(Value)
            return type(rawget(Value, "guard")) == "table"
                and type(rawget(Value, "scrap")) == "table"
                and type(rawget(Value, "rebirth")) == "table"
        end,

        Catalog = function(Value)
            return type(rawget(Value, "chickenTypes")) == "table"
                and type(rawget(Value, "generators")) == "table"
        end,

        CoopView = function(Value)
            return type(rawget(Value, "canExpand")) == "function"
                and type(rawget(Value, "canBuyGenerator")) == "function"
        end,

        RecyclerView = function(Value)
            return rawget(Value, "LockedAttr") == "recyclerLocked"
                and type(rawget(Value, "floorUnlocked")) == "function"
        end,

        DailyView = function(Value)
            return rawget(Value, "DAY_KEY") == "d"
                and type(rawget(Value, "sessionReady")) == "function"
        end,

        MissionView = function(Value)
            return type(rawget(Value, "SCOPES")) == "table"
                and type(rawget(Value, "stateOf")) == "function"
        end,

        PassView = function(Value)
            return type(rawget(Value, "claimKey")) == "function"
                and type(rawget(Value, "state")) == "function"
                and type(rawget(Value, "track")) == "function"
        end,

        RebirthBonus = function(Value)
            return type(rawget(Value, "requirementFloor")) == "function"
                and type(rawget(Value, "pointsFor")) == "function"
        end,

        -- Core.Progression.RebirthExperiment: the game runs an A/B test on the
        -- rebirth requirement curve. The control arm keeps requirementFloor,
        -- the variant arm uses requirementFloorV2, which asks for up to two
        -- more tower floors past rebirth 240. Reading the floor without the
        -- arm called a rebirth ready that the server then refused.
        RebirthExperiment = function(Value)
            return rawget(Value, "ATTRIBUTE") == "rebirth_requirement_v2"
                and type(rawget(Value, "usesV2")) == "function"
                and type(rawget(Value, "armOf")) == "function"
        end,

        -- Content.RebirthMilestones, added by the 22 Aug update: the ladder of
        -- rewards handed out for passing a rebirth count. Authored up to 2000
        -- and generated every 100 after that, so the step's own "at" -- which
        -- is what the claim remote takes -- can only be read from here.
        RebirthMilestones = function(Value)
            return type(rawget(Value, "nth")) == "function"
                and type(rawget(Value, "reachedCount")) == "function"
                and type(rawget(Value, "indexAt")) == "function"
        end,

        PitZone = function(Value)
            return typeof(rawget(Value, "center")) == "Vector3"
                and type(rawget(Value, "contains")) == "function"
        end,

        RosterCap = function(Value)
            return rawget(Value, "PASS") == "rosterSlots"
                and type(rawget(Value, "of")) == "function"
        end,

        FusionRules = function(Value)
            return type(rawget(Value, "cost")) == "function"
                and type(rawget(Value, "ascendChance")) == "function"
                and type(rawget(Value, "RARITY_ORDER")) == "table"
        end,

        Genome = function(Value)
            return type(rawget(Value, "statMults")) == "function"
                and type(rawget(Value, "cap")) == "function"
        end,

        -- Content.Mutations: id -> { chance, boost = { hp, atk, speed }, ... }.
        -- Matched on that shape rather than on `inverted` by name, so the day a
        -- second one ships the run reads its multipliers instead of assuming
        -- the only one it knew about.
        Mutations = function(Value)
            local Found = 0

            for Key, Def in pairs(Value) do
                if type(Key) ~= "string" or type(Def) ~= "table" then return false end
                if rawget(Def, "id") ~= Key then return false end
                if type(rawget(Def, "chance")) ~= "number" then return false end
                if type(rawget(Def, "boost")) ~= "table" then return false end

                Found = Found + 1
            end

            return Found > 0
        end,

        Curve = function(Value)
            return type(rawget(Value, "at")) == "function"
                and type(rawget(Value, "rounded")) == "function"
        end,

        -- egg id -> { chickenTypeId = weight }: the table the server rolls a
        -- hatch against. Matched on shape rather than on any one egg's
        -- contents, so a balance pass that moves chickens around does not
        -- stop the run from finding it.
        EggPool = function(Value)
            local Barn = rawget(Value, "barn")
            local Feed = rawget(Value, "feed")
            local Crown = rawget(Value, "crown")

            if type(Barn) ~= "table" or type(Feed) ~= "table" or type(Crown) ~= "table" then
                return false
            end

            local Entries = 0

            for Key, Weight in pairs(Barn) do
                if type(Key) ~= "string" or type(Weight) ~= "number" then return false end

                Entries = Entries + 1
            end

            return Entries > 0
        end,

        -- The client's own view of the chicken's standing order and where it
        -- is: two Charm atoms and nothing else. RebirthController computes
        -- `atCoop = order() == "coop" and where() == "corral"` off exactly
        -- these two, so reading them is reading the same test the game runs.
        ChickenMode = function(Value)
            if type(rawget(Value, "order")) ~= "function" then return false end
            if type(rawget(Value, "where")) ~= "function" then return false end

            local Keys = 0

            for _ in pairs(Value) do
                Keys = Keys + 1
            end

            return Keys == 2
        end,

        ElevatorCatalog = function(Value)
            return type(rawget(Value, "elevatorCost")) == "function"
        end,

        -- the onboarding step machine. The server writes the current step onto
        -- the player as an attribute, but when it has not, this is the same
        -- derive the client itself falls back to.
        OnbSteps = function(Value)
            return rawget(Value, "Attr") == "onbStep"
                and type(rawget(Value, "derive")) == "function"
                and type(rawget(Value, "ORDER")) == "table"
        end,
    }

    local Required = { "DataService", "GameConfig", "Catalog" }

    local function MissingRequired()
        for _, Name in ipairs(Required) do
            if not Modules[Name] then return true end
        end

        return false
    end

    local function Sweep()
        local Left = 0

        for _ in pairs(Patterns) do
            Left = Left + 1
        end

        if Left == 0 then return end

        ScanGarbage(function(Value)
            for Name, Test in pairs(Patterns) do
                if Test(Value) then
                    Modules[Name] = Value
                    Patterns[Name] = nil
                    Left = Left - 1
                end
            end

            return Left == 0
        end)
    end

    -- Three sweeps four and a half seconds apart was enough for a manual
    -- execute, where the client has been running for a minute before anyone
    -- presses the button, and not remotely enough for an autoexec rejoin.
    -- The sweep now keeps going until the boot deadline: the required tables
    -- appear as the client requires them, and the only thing waiting costs is
    -- the wait.
    local Attempt = 0

    repeat
        Attempt = Attempt + 1

        Sweep()

        if not MissingRequired() then break end

        if Attempt == 3 then
            warn("[ValkyrieHub] the client has not required its modules yet; still waiting")
        end

        task.wait(1.5)
    until Boot.TimeLeft() <= 0

    -- one last sweep on the way out, in case the deadline landed mid-wait
    if MissingRequired() then
        Sweep()
    end

    for _, Name in ipairs(Required) do
        if not Modules[Name] then
            error("[ValkyrieHub] could not find the game's " .. Name .. " table in memory", 0)
        end
    end

    -- The optional views are what the run's individual features hang off, and
    -- on a rejoin they trail the required three. Nothing here is fatal, so it
    -- is not worth the whole deadline -- but a run that starts with
    -- RecyclerView and DailyView stubbed has silently lost scrap and daily
    -- rewards for the rest of the session, which is worth waiting on.
    --
    -- This is also what replaced the PlayerGui watch in boot step 4. A flat
    -- ten seconds was fine while something earlier had already waited for the
    -- client to settle; with that gone, the wait has to find its own end, so
    -- it sweeps until either every view is in hand or a few seconds pass with
    -- the sweep turning up nothing new. A client that is still loading keeps
    -- the wait alive by producing modules; one that has finished ends it.
    local ViewsQuiet = 6
    local ViewsUntil = os.clock() + math.min(45, math.max(0, Boot.TimeLeft()))
    local FoundAt = os.clock()

    local function ViewsLeft()
        local Left = 0

        for _ in pairs(Patterns) do
            Left = Left + 1
        end

        return Left
    end

    local Left = ViewsLeft()

    while Left > 0 and os.clock() < ViewsUntil and os.clock() - FoundAt < ViewsQuiet do
        task.wait(1)

        Sweep()

        local Now = ViewsLeft()

        if Now < Left then
            FoundAt = os.clock()
        end

        Left = Now
    end
end

Elevate()

local DataService = Modules.DataService
local GameConfig = Modules.GameConfig
local Catalog = Modules.Catalog

-- a missing view module costs its own feature and nothing else, so each one is
-- stubbed with something that always answers "no"
local function ViewOrStub(Name, Stub)
    local View = Modules[Name]

    if View then
        return View
    end

    warn("[ValkyrieHub] " .. Name .. " not loaded by the client; the features that use it stay off")

    return Stub
end

local CoopView = ViewOrStub("CoopView", {
    canExpand = function() return false end,
    canUpgrade = function() return false end,
    canBuyGenerator = function() return false end,
    expandCost = function() return math.huge end,
    upgradeCost = function() return math.huge end,
    buyGeneratorCost = function() return math.huge end
})

local RecyclerView = ViewOrStub("RecyclerView", {
    LockedAttr = "recyclerLocked",
    BusyAttr = "recyclerBusy",
    canUpgrade = function() return false end,
    floorUnlocked = function() return false end,
    upgradeCost = function() return math.huge end
})

local DailyView = ViewOrStub("DailyView", {
    DAY_KEY = "d",
    sessionKey = function(Index) return "s" .. tostring(Index) end,
    sessionReady = function() return false end
})

local MissionView = ViewOrStub("MissionView", {
    SCOPES = { },
    active = function() return { } end,
    stateOf = function() return "locked" end
})

local PassView = ViewOrStub("PassView", {
    state = function() return "locked" end,
    track = function() return "free" end
})

local RebirthBonus = ViewOrStub("RebirthBonus", {
    requirementFloor = function() return math.huge end,
    requirementFloorFor = function() return math.huge end,
    ready = function() return false end,
    pointsFor = function() return 0 end
})

local RebirthExperiment = ViewOrStub("RebirthExperiment", {
    VARIANT = "variant",
    usesV2 = function() return false end
})

-- reachedCount(count) is how many milestone steps the rebirth count has passed
-- and nth(index) is the step itself; rebirth.claimed is keyed by tostring(at),
-- which is the same number the claim remote takes
local RebirthMilestones = ViewOrStub("RebirthMilestones", {
    nth = function() return nil end,
    reachedCount = function() return 0 end,
    indexAt = function() return nil end
})

local RosterCap = ViewOrStub("RosterCap", {
    PASS = "rosterSlots",
    of = function() return math.huge end
})

local FusionRules = ViewOrStub("FusionRules", {
    cost = function() return nil end,
    ascendChance = function() return 0 end,
    RARITY_ORDER = { "common", "uncommon", "rare", "epic", "legendary", "mythic", "divine", "celestial", "cosmic", "secret" }
})

local Curve = Modules.Curve

local PitZone = Modules.PitZone or {
    center = Vector3.new(0, 0, 0),
    radius = GameConfig.pit.radius
}

local Rarities = FusionRules.RARITY_ORDER
local GeneKeys = FusionRules.GENE_KEYS or { "vigor", "furia", "velocidad", "impetu", "fertility" }
local GeneMax = GameConfig.fusion.geneMax or 31
local GeneCaps = GameConfig.fusion.geneCap or { }
-- GameConfig.roster.rarityMult used to be read here and multiplied into every
-- stat this file computed. It is not a combat multiplier -- see StatsOf -- and
-- reading it at all was what made a level 1 cosmic look stronger than a level
-- 60 epic, so the local is gone rather than left lying around to be used again.
local ScrapTravel = GameConfig.scrap.travel

local RarityRank = { }

for Index, Name in ipairs(Rarities) do
    RarityRank[Name] = Index
end

---- ============ Remotes ============ ----

local RemoteFolder = ReplicatedStorage:WaitForChild("Remotes")

local function RemoteByName(Name)
    local Remote = RemoteFolder:FindFirstChild(Name)

    if not Remote then
        warn("[ValkyrieHub] no remote named " .. tostring(Name))
    end

    return Remote
end

-- The budget, and it sits on the send itself rather than on the callers.
--
-- The server counts requests per remote and answers "rateLimited" when there
-- are too many, and a run of refused calls is what the account was kicked for.
-- Three rules, all slower than a human could click: half a second between any
-- two calls, a second and a half between two calls to the same remote, and no
-- more than 8 calls in any 10 second window. A call that has to wait waits.
--
-- One table rather than ten main-chunk locals. Luau allows two hundred per
-- function and this file's main chunk is at the ceiling, so anything that is
-- really one thing with ten fields is written as one thing with ten fields.
local Budget = {
    Gap        = 0.5,   -- between any two calls
    PerRemote  = 1.5,   -- between two calls to the same remote
    Window     = 10,    -- seconds the call ceiling is counted over
    Calls      = 8,     -- calls allowed in that window
    WaitFor    = 4,     -- how long a caller waits for a slot before giving up

    LastAt     = 0,
    LastRemote = { },
    Times      = { },
    HoldUntil  = 0,
    Warned     = false,
}

local function BudgetAllows(Name)
    local Now = os.clock()

    if Now < Budget.HoldUntil then return false end

    if Now - Budget.LastAt < Budget.Gap then return false end
    if Now - (Budget.LastRemote[Name] or 0) < Budget.PerRemote then return false end

    for Index = #Budget.Times, 1, -1 do
        if Now - Budget.Times[Index] > Budget.Window then
            table.remove(Budget.Times, Index)
        end
    end

    if #Budget.Times >= Budget.Calls then
        if not Budget.Warned then
            Budget.Warned = true

            warn(string.format("[ValkyrieHub] holding back: %d calls in the last %ds is the ceiling", Budget.Calls, Budget.Window))
        end

        return false
    end

    Budget.Warned = false

    Budget.LastAt = Now
    Budget.LastRemote[Name] = Now
    table.insert(Budget.Times, Now)

    return true
end

local function BudgetWait(Name)
    if BudgetAllows(Name) then return true end

    local Deadline = os.clock() + Budget.WaitFor

    while os.clock() < Deadline do
        task.wait(0.1)

        if BudgetAllows(Name) then return true end
    end

    return false
end

local function NoteReply(Name, Reply)
    if type(Reply) ~= "table" then return end

    if Reply.error == "rateLimited" then
        Budget.HoldUntil = os.clock() + 30

        warn("[ValkyrieHub] server answered rateLimited; every request is on hold for 30s")
    end
end

local Remotes = {
    defs = setmetatable({ }, {
        __index = function(_, Name)
            return Name
        end
    }),

    fire = function(Name, ...)
        local Remote = RemoteByName(Name)

        if not Remote then return false end
        if not BudgetWait(Name) then return false end

        Remote:FireServer(...)

        return true
    end,

    invoke = function(Name, ...)
        local Remote = RemoteByName(Name)

        if not Remote then return end
        if not BudgetWait(Name) then return end

        local Reply = Remote:InvokeServer(...)

        NoteReply(Name, Reply)

        return Reply
    end,

    onClient = function(Name, Handler)
        local Remote = RemoteByName(Name)

        if Remote then
            return Remote.OnClientEvent:Connect(Handler)
        end
    end
}

local AskAgainAt = { }
local AskFailures = { }

-- a refused request earns that remote a doubling backoff; a request the budget
-- swallowed is not a refusal and earns nothing
local function Ask(Name, ...)
    if os.clock() < (AskAgainAt[Name] or 0) then return end

    local Reply = Remotes.invoke(Name, ...)

    if Reply == nil then
        return nil
    end

    if type(Reply) == "table" and Reply.ok then
        AskAgainAt[Name] = nil
        AskFailures[Name] = nil
    else
        local Failures = (AskFailures[Name] or 0) + 1

        AskFailures[Name] = Failures
        AskAgainAt[Name] = os.clock() + math.min(120, 10 * 2 ^ (Failures - 1))
    end

    return Reply
end

---- ============ Data ============ ----

local function GetData(Key)
    local Ok, Value = pcall(function()
        return DataService.client:get(Key)
    end)

    if Ok then
        return Value
    end
end

-- The roster carries the SAVED level and xp, and for the chicken standing on the plot those are
-- stale between saves: a rebirth writes level 1, and the roster goes on saying 1 while the bird
-- eats its way back up to 38. The live pair is replicated under a key of its own, `vitals`, and
-- the game overlays it onto the active chicken before anything is allowed to read a level --
-- DataController.rosterView does exactly this, and so does every screen in the game.
--
-- Read straight, the roster told Auto Tower the fighter was level 1 forever, so a Min Level of
-- 10 was never satisfied and the run never started. It also fed a level of 1 to Fight.Stats, to
-- the fusion planner and to the arena team, which all price a chicken off its level.
local function GetRoster()
    local Roster = GetData("roster")

    if type(Roster) ~= "table" then return end
    if type(Roster.chickens) ~= "table" then return Roster end

    local Vitals = GetData("vitals")

    if not (type(Vitals) == "table" and Vitals.id ~= nil) then return Roster end

    -- copied rather than written through: what came back is the data service's own table, and
    -- the game is reading it too
    local Copy = table.clone(Roster)
    local Chickens = table.clone(Roster.chickens)

    for Index, Chicken in ipairs(Chickens) do
        if Chicken.id == Vitals.id then
            local Live = table.clone(Chicken)

            Live.level = Vitals.level or Live.level
            Live.xp = Vitals.xp or Live.xp
            Live.health = Vitals.health or Live.health

            Chickens[Index] = Live

            break
        end
    end

    Copy.chickens = Chickens

    return Copy
end

local function GetCoop()
    local Coop = GetData("coop")

    if type(Coop) == "table" and type(Coop.generators) == "table" then
        return Coop
    end
end

local function GetMoney()
    local Money = GetData("money")

    return type(Money) == "number" and Money or 0
end

local function CanAfford(Cost)
    if type(Cost) ~= "number" then return true end

    return GetMoney() >= Cost
end

-- The client having required DataService is not the same as the server having
-- sent this account's save down it. In between, every read answers nil: the
-- run reads zero money, an empty roster and no tower floor, and acts on it --
-- it re-does the tutorial, claims rewards it already has, and buys the first
-- generator on an account that owns forty. So the last thing boot waits on is
-- the profile itself.
--
-- money is the probe because it is the one key every account has from its
-- first second, including one that has never hatched anything.
do
    local Ready = Boot.WaitFor("this account's save to replicate", function()
        return type(GetData("money")) == "number"
    end, 0.5)

    if not Ready then
        warn("[ValkyrieHub] starting without a replicated save; the run will read what it can")
    end
end

local function RebirthCount()
    local Rebirth = GetData("rebirth")

    return type(Rebirth) == "table" and (Rebirth.count or 0) or 0
end

local function RebirthPoints()
    local Rebirth = GetData("rebirth")

    return type(Rebirth) == "table" and (Rebirth.points or 0) or 0
end

local function TowerBest()
    local Tower = GetData("tower")

    return type(Tower) == "table" and (Tower.best or 0) or 0
end

local function RecyclerLevel()
    local Scrap = GetData("scrap")

    return type(Scrap) == "table" and (Scrap.recyclerLevel or 0) or 0
end

local function RosterLimit()
    local Purchases = GetData("purchases")
    local Passes = type(Purchases) == "table" and Purchases.passes or nil
    local HasPass = type(Passes) == "table" and Passes[RosterCap.PASS] == true

    local Ok, Limit = pcall(RosterCap.of, HasPass)

    return Ok and tonumber(Limit) or math.huge
end

local function RarityOf(Chicken)
    if Chicken.rarity then
        return Chicken.rarity
    end

    local TypeDef = Catalog.chickenTypes[Chicken.typeId] or Catalog.defaultChickenType

    return TypeDef and TypeDef.rarity or "common"
end

local function GeneCapOf(Rarity)
    return GeneCaps[Rarity] or GeneMax
end

-- mean gene over the cap the chicken's own rarity allows: 1.0 means every gene
-- is already as high as this rarity can hold
local function GeneQuality(Chicken)
    local Cap = GeneCapOf(RarityOf(Chicken))

    if Cap <= 0 then return 0 end

    local Genome = Chicken.genome or { }
    local Total = 0

    for _, Key in ipairs(GeneKeys) do
        Total = Total + (tonumber(Genome[Key]) or 0)
    end

    return math.clamp(Total / (#GeneKeys * Cap), 0, 1)
end

-- A mutation, which is the one thing a bad chicken can carry that makes it
-- worth more than a good one.
--
-- Content.Mutations holds exactly one, `inverted`: it rolls at 0.5% on a hatch
-- and multiplies hp and atk by 1.15. Rarity is climbed a step at a time through
-- fusion and can always be climbed again; a mutation cannot be worked towards
-- at all, it is one hatch in two hundred, and losing one is losing something
-- that has no path back.
--
-- It also carries: GameConfig.fusion.mutationInherit is 0.5, so fusing a
-- mutated chicken into a clean one has an even chance of moving the mutation
-- across, and MutationView.fusionOdds makes it a certainty when both sides
-- already carry the same one. So a mutated common is not fodder -- it is the
-- cheapest way the champion is ever going to get a mutation of its own.
local function MutationOf(Chicken)
    local Id = Chicken and Chicken.mutation

    return (type(Id) == "string" and Id ~= "") and Id or nil
end

---- ============ Fighting stats ============ ----

-- The three numbers every fight in this game is decided by, worked out the way
-- the game works them out.
--
-- Taken straight off ArenaView.atk / .hp / .speed, which is the module the
-- arena's own battle simulation calls -- so these are not an approximation of
-- the game's stats, they are the game's stats:
--
--   hp    = 100 * 1.1^(level-1) * archetype.hp    * geneMult.hp    * mutation.hp
--   atk   =  10 * 1.1^(level-1) * archetype.atk   * geneMult.atk   * mutation.atk
--   speed = (1 + 0.02*(level-1)) * archetype.speed * geneMult.speed * mutation.speed
--
-- Genome.statMults, read live: vigor drives hp and furia drives atk, both to
-- x1.50 at 31; velocidad drives speed, to x1.15. impetu is stamina and does not
-- appear in a fight at all.
--
-- WHAT CHANGED, and it was wrong for as long as this file has existed:
-- GameConfig.roster.rarityMult is NOT a combat multiplier. The old PowerOf
-- multiplied by it, which inflated a cosmic by 2.25x and a secret by 2.6x over
-- what they actually hit for -- so the tower was regularly sent a high-rarity
-- chicken that a lower-rarity one at a higher level would have beaten.
--
-- Checked against the live client rather than argued: a cosmic sovereign_rooster
-- at level 89 with 31/31 genes reads
--
--   computed here          atk 138.3K   hp 1.45M
--   arena inventory        atk 138.3K   hp 1.4M
--   its own body in world  ovDmgText 139.7K   ovHpText 1.5M
--
-- and 2.25x of that is nowhere. Rarity still matters enormously, but through
-- the archetype (a secret body carries atk 2.40 where a common carries 1.00)
-- and through the gene cap, not through a multiplier of its own.
local function StatsOf(Chicken)
    if not Chicken then return 0, 0, 0 end

    local TypeDef = Catalog.chickenTypes[Chicken.typeId] or Catalog.defaultChickenType
    local Archetype = (TypeDef and TypeDef.archetype) or { hp = 1, atk = 1, speed = 1 }
    local Genome = Chicken.genome or { }
    local Base = GameConfig.chicken.base
    local Steps = math.max(0, (tonumber(Chicken.level) or 1) - 1)
    local Growth = (GameConfig.chicken.growth.atk or 1.1) ^ Steps

    local Strength = (GameConfig.fusion.geneBonus and GameConfig.fusion.geneBonus.strength) or 0.5
    local Pacing = (GameConfig.fusion.geneBonus and GameConfig.fusion.geneBonus.pacing) or 0.15

    local function Gene(Key, Weight)
        return 1 + math.clamp(tonumber(Genome[Key]) or 0, 0, GeneMax) / GeneMax * Weight
    end

    local Boost = { hp = 1, atk = 1, speed = 1 }
    local Mutation = MutationOf(Chicken)

    if Mutation and Modules.Mutations and Modules.Mutations[Mutation] then
        Boost = Modules.Mutations[Mutation].boost or Boost
    elseif Mutation then
        -- the table was not in memory; inverted is the only one that exists
        Boost = { hp = 1.15, atk = 1.15, speed = 1.05 }
    end

    local Hp = Base.hp * Growth * (Archetype.hp or 1) * Gene("vigor", Strength) * (Boost.hp or 1)
    local Atk = Base.atk * Growth * (Archetype.atk or 1) * Gene("furia", Strength) * (Boost.atk or 1)
    local Speed = (Base.speed + (GameConfig.chicken.perLevel.speed or 0.02) * Steps)
        * (Archetype.speed or 1) * Gene("velocidad", Pacing) * (Boost.speed or 1)

    return Hp, Atk, Speed
end

-- Damage and health combined geometrically, because every fight needs both and
-- neither is any use on its own. Kept under the old name because the window and
-- the reporters print it.
local function PowerOf(Chicken)
    if not Chicken then return 0 end

    local Hp, Atk = StatsOf(Chicken)

    return math.sqrt(Hp * Atk)
end

-- What one cast of a signature ability is worth, as a multiple of one ordinary
-- hit.
--
-- GameConfig.combat.abilities is the pit and tower combat system -- windups,
-- knockback, radii, and one or more damage multipliers per ability. A five-hit
-- ability at 0.5 each is worth 2.5 ordinary hits; blacksun's five ticks at 0.7
-- plus a 6.9 burst is worth 10.4. Read off the table rather than listed here,
-- so a balance pass moves it without this file being touched.
--
-- The arena does NOT use any of this -- its simulation reads hp, atk and speed
-- and nothing else, which is why this only ever weighs on the tower pick.
local AbilityPowerCache = { }

local function AbilityPower(Id)
    if type(Id) ~= "string" or Id == "" then return 0 end
    if AbilityPowerCache[Id] then return AbilityPowerCache[Id] end

    local Combat = GameConfig.combat and GameConfig.combat.abilities
    local Def = Combat and Combat[Id]

    if type(Def) ~= "table" then
        AbilityPowerCache[Id] = 0

        return 0
    end

    -- a multiplier whose name is one of these is a buff or a slow, not damage
    local NotDamage = {
        buffMult = true, debuffMult = true, hasteMult = true,
        slowMult = true, turnMult = true, surgeMult = true,
    }

    -- these land once however many times the ability ticks around them
    local Once = {
        burst = true, blast = true, final = true, execute = true, shot = true,
        toll = true, max = true, strike = true, slam = true, kick = true, bonk = true,
    }

    local Total = 0

    for Key, Value in pairs(Def) do
        if type(Value) == "number" and Key:sub(-4) == "Mult" and not NotDamage[Key] then
            local Name = Key:sub(1, -5)
            local Count = 1

            if not Once[Name] then
                local Found = Def[Name .. "s"] or Def.ticks or Def.waves or Def.hits
                    or Def.cuts or Def.pulls or Def.bites or Def.rockets
                    or Def.pearls or Def.bursts or Def.passes

                if type(Found) == "number" then
                    Count = Found
                end
            end

            Total = Total + Value * Count
        end
    end

    AbilityPowerCache[Id] = Total

    return Total
end

-- ranking for "which one do we keep": rarity first because it is permanent and
-- fusion-gated, then genes, then the body, and only then the level -- level is
-- reset by every rebirth, so it must never decide which chicken is thrown away
--
-- The mutation is worth a little over one rarity step here and no more. That
-- looks stingy for something this rare, and it is deliberate: this score also
-- decides which chicken is the CHAMPION, and a mutated common standing on the
-- plot in front of a cosmic would be a disaster -- 1.15x on top of a rarity
-- multiplier of 1.00 against one of 2.25. What keeps a mutation out of the sell
-- list is not this number, it is the outright exemption in the sell task, which
-- does not weigh anything at all.
local function KeepScore(Chicken)
    local TypeDef = Catalog.chickenTypes[Chicken.typeId] or Catalog.defaultChickenType
    local Archetype = (TypeDef and TypeDef.archetype) or { hp = 1, atk = 1 }

    return (MutationOf(Chicken) and 1200 or 0)
        + (RarityRank[RarityOf(Chicken)] or 1) * 1000
        + GeneQuality(Chicken) * 300
        + ((Archetype.hp or 1) + (Archetype.atk or 1)) * 30
        + math.min(tonumber(Chicken.level) or 1, 50) * 0.5
end

local function Chickens(Roster)
    return (Roster and type(Roster.chickens) == "table") and Roster.chickens or { }
end

local function ChampionOf(Roster)
    local Best, BestScore

    for _, Chicken in ipairs(Chickens(Roster)) do
        local Score = KeepScore(Chicken)

        if not BestScore or Score > BestScore then
            Best = Chicken
            BestScore = Score
        end
    end

    return Best
end

local function FirstEggTier(Roster)
    if type(Roster.eggs) ~= "table" then return end

    for Tier, Count in pairs(Roster.eggs) do
        if type(Count) == "number" and Count > 0 then
            return Tier, Count
        end
    end
end

local function EggTotal(Roster)
    local Total = 0

    if type(Roster.eggs) == "table" then
        for _, Count in pairs(Roster.eggs) do
            if type(Count) == "number" then
                Total = Total + Count
            end
        end
    end

    return Total
end

---- ============ Ranked arena ============ ----

-- Everything the arena is goes through ReplicatedStorage.Remotes, and the whole
-- state of it comes back from one call:
--
--   ArenaGetView()          -> { ok = true, data = { ... } }
--   ArenaSetTeam(ids)       -> up to data.teamSize roster ids
--   ArenaSkip()             -> spends one of data.skips, moves data.cursor on
--   ArenaFight()            -> fights opponents[cursor + 1]
--   ArenaClaim(rankId)      -> one entry of data.claimable
--   SetArenaAutoAbility(on) -> the server fires the team's abilities itself
--
-- The fight is simulated server side: ArenaBattleState arrives with phase
-- "started" and later "finished", ArenaBattleResult carries the outcome, and
-- data.hasActiveMatch is true for the whole minute in between. That flag plus
-- the two events are what stop a second ArenaFight going out mid-match.
--
-- Nothing here refreshes the view on its own. A view costs a send like anything
-- else, and the worker's rule is one send per pass, so the refresh happens
-- inside the arena task and every other reader -- the goal check, the status
-- line, the reporters -- reads whatever the last refresh left behind.
local Ranked = {
    Data = nil,
    ReadAt = 0,
    Refresh = 30,      -- seconds a cached view is trusted for
    Battling = false,
    BattleUntil = 0,   -- a started match cannot be over before this
    AbilitySent = false,
    Why = "off",
}

-- The rank ladder in order, as Content.Arena lists it. Hard-coded rather than
-- read out of the client: it is the one thing here that has to keep meaning the
-- same as what Config.Goal.Rank was written against, and a balance pass that
-- inserts a rank should not silently move the target.
local RankedLadder = {
    "hatchling3", "hatchling2", "hatchling1",
    "bronze3", "bronze2", "bronze1",
    "silver3", "silver2", "silver1",
    "gold3", "gold2", "gold1",
    "crystal3", "crystal2", "crystal1",
    "diamond3", "diamond2", "diamond1",
    "master5", "master4", "master3", "master2", "master1",
    "elite5", "elite4", "elite3", "elite2", "elite1",
    "grandmaster3", "grandmaster2", "grandmaster1",
}

local RankedIndex = { }

for Index, Id in ipairs(RankedLadder) do
    RankedIndex[Id] = Index
end

TrackConnection(Remotes.onClient(Remotes.defs.ArenaBattleState, function(State)
    if type(State) ~= "table" then return end

    if State.phase == "started" then
        Ranked.Battling = true
        -- startDelay 3 + duration 60 + endDelay 3, out of Content.Arena
        Ranked.BattleUntil = os.clock() + 66
    elseif State.phase == "finished" then
        Ranked.Battling = false
    end
end))

TrackConnection(Remotes.onClient(Remotes.defs.ArenaBattleResult, function()
    Ranked.Battling = false
    Ranked.ReadAt = 0
end))

-- true while a match is running. The events are the primary signal; the clock
-- is the backstop for a "finished" that never arrives, which would otherwise
-- park the arena for the rest of the session.
local function RankedBusy()
    if Ranked.Battling and os.clock() < Ranked.BattleUntil then return true end

    Ranked.Battling = false

    return type(Ranked.Data) == "table" and Ranked.Data.hasActiveMatch == true
end

local function RankedRankNow()
    local Data = Ranked.Data

    if type(Data) ~= "table" then return 0 end

    return RankedIndex[tostring(Data.rankId)] or 0
end

-- The arena does not open until the rebirth goal is finished, and that is the
-- important line in this file.
--
-- The game itself opens it at rebirth 5, and entering there is a trap. Trophies
-- are not a score that only goes up: a loss costs 18 + 12*log2(1/powerRatio),
-- five to thirty-five of them, and a rebirth resets the champion's level to one
-- -- which is most of what team power is, since the arena counts attack alone.
-- So a run that fights while it is still rebirthing spends the whole climb
-- feeding trophies back: it wins a few at level forty, rebirths, and then loses
-- them all again at level one, over and over, a hundred times.
--
-- Waiting costs nothing. Rank is not on a timer, the season is 28 days, and
-- once the last rebirth is taken the level stops being reset and only ever
-- climbs -- which is exactly when the arena starts paying.
local function RankedWorthEntering()
    if not Config.Arena.Enabled then
        Ranked.Why = "off"

        return false
    end

    -- the same test GoalRebirthDone runs, written out rather than called: the
    -- goals section is further down the file and this is the only place that
    -- needs the answer before it exists
    local Count = RebirthCount()

    if Count < Config.Goal.Rebirth then
        Ranked.Why = string.format("waiting for rebirth %d (%d now)",
            Config.Goal.Rebirth, Count)

        return false
    end

    -- the game's own gate, still checked: a Goal.Rebirth set below 5 would
    -- otherwise send the run at a feature the account does not have yet
    if Count < 5 then
        Ranked.Why = "opens at rebirth 5"

        return false
    end

    local Want = RarityRank[tostring(Config.Arena.MinRarity)] or 0

    if Want > 0 then
        local Champion = ChampionOf(GetRoster())
        local Have = Champion and (RarityRank[RarityOf(Champion)] or 0) or 0

        if Have < Want then
            Ranked.Why = "waiting for a " .. tostring(Config.Arena.MinRarity) .. " champion"

            return false
        end
    end

    return true
end

-- The rank target, and it is the only goal in this file that can be left
-- unreachable by its own config: an arena that is switched off, or a rank id
-- that does not exist, must not hold the run open forever.
local function GoalRankDone()
    local Want = Config.Goal.Rank

    if type(Want) ~= "string" or Want == "" then return true end
    if not Config.Arena.Enabled then return true end

    local Target = RankedIndex[Want]

    if not Target then return true end

    return RankedRankNow() >= Target
end

-- The arena team, and it is NOT the three biggest numbers the view hands back.
--
-- ArenaBattle.simulate is the whole fight, and it is short enough to state:
--
--   * every fighter swings once every  attackInterval * speedRef / speed
--     seconds, so SPEED IS A STRAIGHT MULTIPLIER ON DAMAGE
--   * a swing does  atk * damageMult(t) * random(0.92, 1.08), where damageMult
--     is 1.0, then 1.25 past 31 seconds, then 1.5 past 51
--   * everyone on both sides hits the enemy's FIRST LIVING SLOT
--   * at 60 seconds the winner is whoever kept the larger fraction of its
--     total hp, and failing that whoever dealt more damage
--   * abilities are not in it. Not one of the 146 is read. hp, atk and speed
--     are the entire model.
--
-- Which means the view's own `powerN` -- the number this used to sort on -- is
-- the wrong number. ArenaView.chickenPower is atk * 100 and nothing else, so it
-- is what the MATCHMAKER weighs the account by when it picks the five
-- opponents. It is not what wins the fight. hp and speed decide most of a
-- fight, and the matchmaker cannot see either of them.
--
-- So a chicken with hp and speed is strength the account is not charged for,
-- and the team is picked on what the simulation actually runs on:
--
--   team damage  = sum of atk * speed
--   team health  = sum of hp
--   strength     = sqrt(damage * health)
--
-- Picking the best three by that is not the same as picking the best three
-- individually -- it is a product of two sums -- so the shortlist is scored
-- individually and then every combination of the top handful is tried.
--
-- The order returned is by hp, heaviest first, and that is not cosmetic. The
-- slot order sent is the slot order fought, everything targets the first living
-- slot, and while slot one lives all three of ours are still swinging. Putting
-- the deepest hp pool in front is a free extra second or two of full team
-- damage in every battle.
local function RankedBestIds(Data)
    local Roster = GetRoster()
    local ById = { }

    for _, Chicken in ipairs(Chickens(Roster)) do
        if Chicken.id then
            ById[Chicken.id] = Chicken
        end
    end

    local Size = math.max(1, Data.teamSize or 3)
    local Bag = { }

    for _, Entry in ipairs(Data.inventory or { }) do
        if type(Entry) == "table" and Entry.id then
            local Mine = ById[Entry.id]
            local Hp, Atk, Speed

            if Mine then
                -- the roster carries genome and mutation, so the stats come out
                -- exact rather than out of the view's rounded display strings
                Hp, Atk, Speed = StatsOf(Mine)
            else
                -- not in the roster copy yet: the view's own numbers are exact
                -- for two of the three (powerN is atk * attackMult) and the hp
                -- string is only ever used to break a tie
                Atk = (tonumber(Entry.powerN) or 0) / 100
                Speed = tonumber(Entry.speed) or 1
                Hp = Atk * 10
            end

            table.insert(Bag, {
                id = Entry.id,
                hp = Hp,
                dps = Atk * Speed,
                solo = math.sqrt(Atk * Speed * Hp),
            })
        end
    end

    if #Bag == 0 then return { } end

    -- a roster with fewer chickens than the arena allows fields what it has;
    -- ArenaView.validTeam accepts anything from one up to team.size
    Size = math.min(Size, #Bag)

    table.sort(Bag, function(Left, Right)
        return Left.solo > Right.solo
    end)

    -- Only the top few are worth combining. Twelve of them is 220 teams of
    -- three, which costs nothing, and a chicken outside the top twelve on its
    -- own is not going to make a better trio with two others.
    local Pool = math.min(#Bag, 12)
    local Best, BestScore

    local Pick = { }

    local function Search(Start, Depth)
        if Depth > Size then
            local Damage, Health = 0, 0

            for _, Entry in ipairs(Pick) do
                Damage = Damage + Entry.dps
                Health = Health + Entry.hp
            end

            local Score = math.sqrt(Damage * Health)

            if not BestScore or Score > BestScore then
                BestScore = Score
                Best = table.clone(Pick)
            end

            return
        end

        for Index = Start, Pool do
            table.insert(Pick, Bag[Index])
            Search(Index + 1, Depth + 1)
            table.remove(Pick)
        end
    end

    Search(1, 1)

    if not Best then return { } end

    -- heaviest hp into slot one: it is the slot everything shoots at
    table.sort(Best, function(Left, Right)
        return Left.hp > Right.hp
    end)

    local Ids = { }

    for _, Entry in ipairs(Best) do
        table.insert(Ids, Entry.id)
    end

    return Ids
end

local function RankedSameTeam(Ids, Current)
    if #Ids ~= #(Current or { }) then return false end

    for Index = 1, #Ids do
        if Ids[Index] ~= Current[Index] then return false end
    end

    return true
end

local function RankedOpponent(Data)
    local Opponents = Data.opponents or { }

    if #Opponents == 0 then return nil end

    return Opponents[math.min((Data.cursor or 0) + 1, #Opponents)]
end

---- ============ Egg hunting ============ ----

-- The chicken standing on the plot is the one that lays, and what it lays is
-- decided by its own type: `chickenTypes[id].eggs` maps an egg id to the
-- percent of layings that produce it, and `layPeriod` is how long one laying
-- takes. Chasing a better egg and putting the right chicken out are therefore
-- not two jobs, they are one.
--
-- An egg is worth whatever comes out of it. `EggPool[egg]` is the table the
-- server rolls a hatch against, chicken type to weight, so an egg is scored
-- from that pool -- as the root mean square of what it holds, not the plain
-- average. A run hatches many eggs and keeps the best of them, so the value of
-- an egg is nearer the top of its pool than the middle of it, and squaring
-- before averaging is what says that without saying it twice: a secret at one
-- percent still pulls, but it pulls one percent's worth.
--
-- The plain average puts the Cursed Egg fourth of eighteen on the strength of
-- a one-in-a-hundred error_chick sitting on a pool of junk; taking the best
-- entry instead puts it fourth for the same bad reason. The root mean square
-- puts it eleventh, behind every egg that is actually better to open.
--
-- Read off the live tables rather than off a chart, the ladder runs
-- barn -> farmer_rooster -> feed -> crest_rooster -> crown, and crown is the
-- first egg holding a celestial (fenghuang) and a divine (kitsune_hen). Crown
-- also holds founder_rooster, which is the only chicken in the game that lays
-- colossus, and colossus and golden are the only two eggs with a secret in
-- them (storm_colossus and golden_goose). Nothing below hardcodes any of that
-- -- it is what the scoring arrives at on its own, and it moves if the game
-- rebalances.

local Hunt = { }

Hunt.Pool = Modules.EggPool or { }

-- solved values, filled in by Hunt.Solve and read by everything below
Hunt.Egg = { }
Hunt.Chick = { }

do
    -- A rarity is worth the square of its rank: ten steps from common to
    -- secret is a hundred times the chicken, which is roughly how the two
    -- trade in a fusion and exactly how they trade in a roster slot.
    local function Fighter(TypeId)
        local TypeDef = Catalog.chickenTypes[TypeId]

        if not TypeDef then return 0 end

        local Rank = RarityRank[TypeDef.rarity] or 1
        local Archetype = TypeDef.archetype or { }

        return Rank * Rank * (((Archetype.hp or 1) + (Archetype.atk or 1)) / 2)
    end

    local SolvedFor = nil

    -- Solve what every egg and every chicken is worth, together.
    --
    -- A chicken is worth what it can fight with plus what it can lay. What it
    -- lays is worth whatever hatches out of those eggs, which is worth what
    -- those chickens can fight with plus what they can lay. That is circular,
    -- so it is solved the way circular things are: start from fighting worth
    -- alone and let the lay value flow back through the table until it stops
    -- moving. Eight passes is well past where it settles.
    --
    -- `Lookahead` discounts each further step of the chain. At 0.6 a chicken
    -- three eggs away still counts for a fifth of itself, which is enough for
    -- the run to put out a crest_rooster -- a plain epic and a poor fighter --
    -- on the strength of where it leads: crest_rooster is the cheap way into
    -- crown, crown is the way to founder_rooster, and founder_rooster is the
    -- only chicken in the game that lays colossus at all. Greedy scoring
    -- cannot see any of that. It sees an epic that lays a middling egg.
    --
    -- `Novelty` is the other half of it: a type the account has never seen is
    -- worth more than the same type again, so a pool that has been exhausted
    -- stops pulling and the run moves to one still holding something new.
    function Hunt.Solve(Roster)
        local Seen = (type(Roster) == "table" and type(Roster.seen) == "table") and Roster.seen or { }
        local Known = 0

        for _ in pairs(Seen) do
            Known = Known + 1
        end

        -- the answer only moves when the account discovers something, so it is
        -- worked out once per discovery rather than once per status tick
        if SolvedFor == Known then return end

        SolvedFor = Known

        local Gamma = tonumber(Config.Eggs.Lookahead) or 0.6
        local Bonus = tonumber(Config.Eggs.Novelty) or 1.6

        local Base, Value = { }, { }

        for TypeId in pairs(Catalog.chickenTypes) do
            Base[TypeId] = Fighter(TypeId) * (Seen[TypeId] and 1 or Bonus)
            Value[TypeId] = Base[TypeId]
        end

        local Eggs = { }

        for _ = 1, 8 do
            -- an egg is the root mean square of its pool at the current
            -- values, not the plain average: a run hatches many eggs and keeps
            -- the best of them, so the worth of an egg sits nearer the top of
            -- its pool than the middle. Squaring before averaging says that
            -- without saying it twice -- a secret at one percent still pulls,
            -- but it pulls one percent's worth.
            --
            -- The plain average puts the Cursed Egg fourth of eighteen on the
            -- strength of a one-in-a-hundred error_chick sitting on a pool of
            -- junk, and taking the single best entry puts it fourth for the
            -- same bad reason. The root mean square puts it eleventh, behind
            -- every egg that is actually better to open.
            for Egg, Pool in pairs(Hunt.Pool) do
                local Weight, Sum = 0, 0

                for _, Share in pairs(Pool) do
                    Weight = Weight + (tonumber(Share) or 0)
                end

                if Weight > 0 then
                    for TypeId, Share in pairs(Pool) do
                        local Worth = Value[TypeId] or 0

                        Sum = Sum + (tonumber(Share) or 0) / Weight * Worth * Worth
                    end

                    Eggs[Egg] = math.sqrt(Sum)
                else
                    Eggs[Egg] = 0
                end
            end

            for TypeId, TypeDef in pairs(Catalog.chickenTypes) do
                local Lay = 0

                for Egg, Percent in pairs(TypeDef.eggs or { }) do
                    Lay = Lay + (tonumber(Percent) or 0) / 100 * (Eggs[Egg] or 0)
                end

                Value[TypeId] = (Base[TypeId] or 0) + Gamma * Lay
            end
        end

        Hunt.Egg = Eggs
        Hunt.Chick = Value
    end
end

function Hunt.Score(Egg)
    return (Egg and Hunt.Egg[Egg]) or 0
end

-- The tower borrows the plot.
--
-- TowerStart takes no chicken id: it sends whoever is standing there. Normally
-- that is the layer, which is not who should be climbing, so the tower puts the
-- champion back out and holds the plot while the run goes. This is how it says
-- "leave it alone for a moment" to the task that would otherwise swap the
-- layer straight back in.
Hunt.HoldUntil = 0

function Hunt.Hold(Seconds)
    Hunt.HoldUntil = os.clock() + (Seconds or 45)
end

function Hunt.Held()
    return os.clock() < Hunt.HoldUntil
end

-- eggs per second. Fertility shortens the wait the same way vigor and furia
-- lengthen a fight, so a well bred layer is worth more than its type alone.
function Hunt.Rate(Chicken)
    local TypeDef = Chicken and Catalog.chickenTypes[Chicken.typeId]
    local Period = TypeDef and tonumber(TypeDef.layPeriod) or 0

    if Period <= 0 then return 0 end

    local Bonus = (GameConfig.fusion.geneBonus and GameConfig.fusion.geneBonus.fertility) or 0.4
    local Fertility = math.clamp(tonumber((Chicken.genome or { }).fertility) or 0, 0, GeneMax)

    return (1 + Fertility / GeneMax * Bonus) / Period
end

-- what an hour of this chicken standing on the plot is worth, counting both
-- what its eggs hatch and where those hatches lead
function Hunt.Value(Chicken)
    local TypeDef = Chicken and Catalog.chickenTypes[Chicken.typeId]
    local Eggs = TypeDef and TypeDef.eggs

    if type(Eggs) ~= "table" then return 0 end

    local Sum = 0

    for Egg, Percent in pairs(Eggs) do
        Sum = Sum + (tonumber(Percent) or 0) / 100 * Hunt.Score(Egg)
    end

    return Sum * Hunt.Rate(Chicken) * 3600
end

-- Which eggs drop a given chicken, and how often.
--
-- This is the number the Index screen prints under each face: the chicken's
-- weight over its pool's total. It is why the Nest Egg reads 70/18/10/2 --
-- those four weights already sum to a hundred -- while the Scratch Egg reads
-- 12/12/12/11/11/8/8/8/8/5 off weights that sum to a hundred and sixty-three.
function Hunt.From(TypeId)
    local Found = { }

    if not TypeId or TypeId == "" then return Found end

    for Egg, Pool in pairs(Hunt.Pool) do
        local Share = tonumber(Pool[TypeId])

        if Share and Share > 0 then
            local Weight = 0

            for _, Other in pairs(Pool) do
                Weight = Weight + (tonumber(Other) or 0)
            end

            if Weight > 0 then
                table.insert(Found, { egg = Egg, chance = Share / Weight })
            end
        end
    end

    table.sort(Found, function(A, B)
        return A.chance > B.chance
    end)

    return Found
end

-- How much one laying by a chicken type moves the account toward a named
-- target, counting the chickens it might hatch on the way there.
--
-- The direct part is easy: the chance the egg it lays drops the target. The
-- rest is not, and the rest is most of it. Nothing in a fresh bag lays a Haunt
-- Egg, so reaper_rooster reads as unreachable when the road is really
-- feed -> slugger_hen -> arena -> clown_chick -> haunt -> reaper_rooster. So
-- this is solved the same way Hunt.Solve is: one laying is worth the chance of
-- the target itself, plus a discounted share of whatever the hatch could then
-- go on to lay. Five passes is past where it settles.
--
-- The discount is heavy on purpose. A chicken that might hatch is not a
-- chicken in hand, and at 0.35 a step a road four eggs long is worth about a
-- sixtieth of the direct drop -- enough to break a tie between two chickens
-- that both reach nothing directly, not enough to send the run chasing a
-- five-step story over a one-step chance.
do
    local Reach, ReachFor

    function Hunt.Reach(TypeId, Want)
        if not TypeId or not Want or Want == "" then return 0 end

        if ReachFor ~= Want then
            ReachFor = Want

            -- P(egg drops type), the same figure the Index screen prints
            local Share = { }

            for Egg, Pool in pairs(Hunt.Pool) do
                local Weight = 0

                for _, W in pairs(Pool) do
                    Weight = Weight + (tonumber(W) or 0)
                end

                if Weight > 0 then
                    local Row = { }

                    for Type, W in pairs(Pool) do
                        Row[Type] = (tonumber(W) or 0) / Weight
                    end

                    Share[Egg] = Row
                end
            end

            local Gamma = 0.35
            local Value = { }

            for _ = 1, 5 do
                local Next = { }

                for Type, Def in pairs(Catalog.chickenTypes) do
                    local Sum = 0

                    for Egg, Percent in pairs(Def.eggs or { }) do
                        local Row = Share[Egg]

                        if Row then
                            local Onward = 0

                            for Mid, Chance in pairs(Row) do
                                Onward = Onward + Chance * (Value[Mid] or 0)
                            end

                            Sum = Sum + (tonumber(Percent) or 0) / 100
                                * ((Row[Want] or 0) + Gamma * Onward)
                        end
                    end

                    Next[Type] = Sum
                end

                Value = Next
            end

            Reach = Value
        end

        return (Reach and Reach[TypeId]) or 0
    end
end

-- Expected progress toward one named chicken per hour, if this one stands on
-- the plot. Working backwards like this is the only way to chase something
-- specific: storm_colossus falls out of the Colossus Egg and out of nothing
-- else, and the Colossus Egg is laid by founder_rooster and by no other
-- chicken, so wanting the one means putting out the other.
function Hunt.Chase(Chicken, Want)
    if not Chicken then return 0 end

    return Hunt.Reach(Chicken.typeId, Want) * Hunt.Rate(Chicken) * 3600
end

-- How much of an egg's pool the account has still never hatched. Reported
-- rather than acted on -- the novelty bonus already acts on it -- because
-- "4 new" is the one number that says why the run is sitting on an egg it
-- already owns plenty of.
function Hunt.Fresh(Roster, Egg)
    local Pool = Egg and Hunt.Pool[Egg]

    if type(Pool) ~= "table" then return 0, 0 end

    local Seen = (type(Roster) == "table" and type(Roster.seen) == "table") and Roster.seen or { }
    local Fresh, Total = 0, 0

    for TypeId in pairs(Pool) do
        Total = Total + 1

        if not Seen[TypeId] then
            Fresh = Fresh + 1
        end
    end

    return Fresh, Total
end

-- Who stands on the plot: the best chicken in the bag, whatever its level.
--
-- Rarity decides it. Rarity is permanent, level is not -- a rebirth wipes
-- every level and leaves rarity untouched -- and the gene cap a rarity carries
-- is a ceiling nothing else can lift: a common tops out at 8 per gene where a
-- cosmic tops out at 31. A level one mythic is already the best chicken the
-- account owns. It simply has not been paid for yet, and standing on the plot
-- is how it gets paid: it lays, and it is the one in the pit earning levels.
--
-- Among equal rarity the tie goes to whichever lays the better eggs, which is
-- the only thing this adds over ChampionOf.
--
-- Nothing here worries about the chicken being weak. The tower does not send
-- whoever is standing here any more -- see Hunt.Fighter and the handover in
-- the tower task -- so putting a level one mythic out costs no floors.
function Hunt.Layer(Roster)
    if not (Config.Eggs and Config.Eggs.Hunt) then return end

    Hunt.Solve(Roster)

    -- A named target overrides everything: put out whoever gets closest to it
    -- per hour, whatever that chicken's own rarity is. If nothing in the bag
    -- can reach the target at all, this falls through to the ordinary rule
    -- rather than standing still.
    local Want = Config.Eggs.Want

    if type(Want) == "string" and Want ~= "" then
        local Chaser, ChaseRate

        for _, Chicken in ipairs(Chickens(Roster)) do
            local Rate = Hunt.Chase(Chicken, Want)

            if Rate > 0 and (not ChaseRate or Rate > ChaseRate) then
                Chaser, ChaseRate = Chicken, Rate
            end
        end

        if Chaser then return Chaser, ChaseRate end
    end

    local Best, BestValue, BestRank

    for _, Chicken in ipairs(Chickens(Roster)) do
        local Rank = RarityRank[RarityOf(Chicken)] or 1
        local Value = Hunt.Value(Chicken)

        if not Best or Rank > BestRank or (Rank == BestRank and Value > BestValue) then
            Best, BestValue, BestRank = Chicken, Value, Rank
        end
    end

    return Best, BestValue
end

-- Who climbs the tower, which is a different question from who the champion is
-- and often a different bird.
--
-- ChampionOf ranks by rarity because that is what the account is being built
-- towards. A tower floor does not care what the account is being built
-- towards. A level sixty-six epic carries fifteen thousand power; the level one
-- mythic that outranks it carries seventy. Sending the champion up would lose
-- the floor, and the floor is what the next rebirth is waiting on.
--
-- The tower is one chicken against one enemy, so the score is that chicken's
-- own fighting worth and nothing about a team:
--
--   damage per second   atk * speed        -- speed is how often it swings
--   staying power       hp
--   its signature       AbilityPower       -- the pit and tower run the real
--                                             combat system, abilities and all
--
-- combined as sqrt(dps * hp), which is the standard way of saying "neither is
-- any use without the other", and then nudged by the ability.
--
-- The ability is deliberately a nudge and not a factor. Its damage is known
-- exactly; how often it lands is not -- the cooldowns are the server's and are
-- not in any table this file can read -- so a full 10x ability is worth 25%
-- here rather than the 10x it would be if it fired every swing. It decides
-- between two chickens that are otherwise close and never overturns a real
-- difference in level.
function Hunt.Fighter(Roster)
    local Best, BestScore

    for _, Chicken in ipairs(Chickens(Roster)) do
        local Hp, Atk, Speed = StatsOf(Chicken)
        local Score = math.sqrt(Atk * Speed * Hp)
            * (1 + math.min(AbilityPower(Chicken.ability), 10) * 0.025)

        if not BestScore or Score > BestScore then
            Best, BestScore = Chicken, Score
        end
    end

    return Best, BestScore
end

-- Which held egg to open first. The old build took whatever `pairs` handed
-- back, which on a stash holding both a barn egg and a colossus egg is a coin
-- toss over the best thing the account will ever own.
function Hunt.Tier(Roster)
    if type(Roster) ~= "table" or type(Roster.eggs) ~= "table" then return end

    Hunt.Solve(Roster)

    local Best, BestScore, BestCount

    for Tier, Count in pairs(Roster.eggs) do
        if type(Count) == "number" and Count > 0 then
            local Score = Hunt.Score(Tier)

            if not BestScore or Score > BestScore then
                Best, BestScore, BestCount = Tier, Score, Count
            end
        end
    end

    return Best, BestCount
end

-- The egg the run is chasing: the best one anything in the roster can lay,
-- unless the config pinned one.
function Hunt.Target(Roster)
    if type(Config.Eggs.Target) == "string" and Config.Eggs.Target ~= "" then
        return Config.Eggs.Target
    end

    if type(Roster) ~= "table" then return end

    Hunt.Solve(Roster)

    local Best, BestScore

    for _, Chicken in ipairs(Chickens(Roster)) do
        local TypeDef = Catalog.chickenTypes[Chicken.typeId]

        for Egg in pairs((TypeDef and TypeDef.eggs) or { }) do
            local Score = Hunt.Score(Egg)

            if not BestScore or Score > BestScore then
                Best, BestScore = Egg, Score
            end
        end
    end

    return Best
end

-- display name for a log line or the panel, "Royal Egg" rather than "crown"
function Hunt.Name(Egg)
    local Def = Egg and Catalog.eggs and Catalog.eggs[Egg]

    return (Def and Def.name) or tostring(Egg or "-")
end

---- ============ Chicken body / arena ============ ----

local function GetRootPart()
    local Character = LocalPlayer.Character

    return Character and Character:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local Character = LocalPlayer.Character

    return Character and Character:FindFirstChildOfClass("Humanoid")
end

local function MyChickenBody()
    local Bodies = workspace:FindFirstChild("ChickenBodies")

    if not Bodies then return end

    local Owner = tostring(LocalPlayer.UserId)

    for _, Body in ipairs(Bodies:GetChildren()) do
        if tostring(Body:GetAttribute("ovOwner")) == Owner then
            return Body
        end
    end
end

-- ovState is only written when the chicken is away from its corral; unset
-- means "corral", exactly as the game's own ChickenBodyProxy reads it
local function ChickenStateOf(Body)
    if not Body then return nil end

    local State = Body:GetAttribute("ovState")

    if type(State) ~= "string" or State == "" then
        return "corral"
    end

    return State
end

-- What is loose in the pit, which is also where the scrap is.
--
-- GameConfig.pit.player is enabled: a chicken reaches pit.hitReach (4 studs)
-- every pit.attackInterval, knocks for pit.knock * knockScale, and a knockout
-- costs scrap.stealPct -- half of everything being carried -- plus
-- pit.player.koCooldown seconds face down on the floor. The chickens down there
-- are other people's champions, so "one hit" is not a figure of speech: the one
-- on the server while this was written was a secret at level 70 hitting for
-- 12.2K.
--
-- The Chicken Boss is the other thing down there, and this used to walk
-- straight through it. Two reasons, both in the filter that was here:
--
--   * the boss is a ChickenBody like any other, but it has no ovOwner at all.
--     It is found through workspace's BossBodyId attribute, which carries the
--     boss body's entityId -- the same handle the game's own
--     ChickenBossController claims its rig with.
--   * it does not stand in ovState "pit". Anything not mine and not parked in
--     a corral is worth keeping clear of, so the state test is now a list of
--     the states that mean "at home" rather than one state that means "loose".
--
-- Reach is per threat, because the boss's is not in the same league. A player's
-- chicken has to touch you: hitReach is 4 studs and PitDanger's 14 is already
-- generous. The boss lands skySlam in a 26 stud circle for playerKnock 30 and
-- a second of daze, charges 43 studs down a 9 wide lane, and throws five eggs
-- that splash 10. Read off ChickenBoss where the client has it, so a balance
-- pass moves this with it.
local BossReach = 30

do
    for _, Value in ipairs(getgc(true)) do
        if type(Value) == "table"
            and type(rawget(Value, "attacks")) == "table"
            and type(rawget(Value, "tiers")) == "table"
            and type(rawget(Value, "tierFor")) == "function" then
            local Attacks = Value.attacks
            local Slam = type(Attacks.skySlam) == "table" and tonumber(Attacks.skySlam.radius) or 0
            local Charge = type(Attacks.roosterCharge) == "table" and tonumber(Attacks.roosterCharge.reach) or 0

            -- the slam circle is what has to be stood outside of; the charge is
            -- long but narrow and is dodged sideways rather than outrun, so it
            -- only counts for its width
            BossReach = math.max(BossReach, Slam + 4, Charge * 0.25)

            break
        end
    end
end

-- corral is home, campaign is inside an arena, and hub is a chicken walking at
-- its owner's heel under a follow order. None of the three is in the pit or
-- fighting anything, so none of them is worth walking around.
local PitHarmless = { corral = true, campaign = true, hub = true }

-- Returns the nearest thing worth avoiding, how far off it is, and how close is
-- too close for that particular one.
local function PitThreat(Origin)
    local Bodies = workspace:FindFirstChild("ChickenBodies")

    if not (Bodies and Origin) then return end

    local Mine = tostring(LocalPlayer.UserId)
    local BossId = workspace:GetAttribute("BossBodyId")
    local PlayerReach = tonumber(Config.PitDanger) or 14

    local Best, BestDistance, BestReach

    for _, Body in ipairs(Bodies:GetChildren()) do
        if Body:IsA("BasePart") and tostring(Body:GetAttribute("ovOwner")) ~= Mine then
            local IsBoss = BossId ~= nil and BossId ~= "" and Body:GetAttribute("entityId") == BossId
            local State = ChickenStateOf(Body)

            -- the boss counts wherever it is standing; everything else only
            -- once it has left its corral or its arena
            if IsBoss or not PitHarmless[State] then
                local Distance = (Body.Position - Origin).Magnitude
                local Reach = IsBoss and BossReach or PlayerReach

                -- nearest by how far INSIDE its own reach it is, so a boss 25
                -- studs off outranks a chicken 20 studs off
                local Score = Distance - Reach

                if not BestDistance or Score < (BestDistance - BestReach) then
                    Best = Body
                    BestDistance = Distance
                    BestReach = Reach
                end
            end
        end
    end

    return Best, BestDistance, BestReach
end

local function MyArena()
    local Arenas = workspace:FindFirstChild("Arenas")
    local Plot = LocalPlayer:GetAttribute("Plot")

    if not (Arenas and Plot) then return end

    return Arenas:FindFirstChild("Arena" .. tostring(Plot))
end

local function TowerActive()
    local Arena = MyArena()

    return Arena and Arena:GetAttribute("TowerActive") == true or false
end

local function EventLive()
    return workspace:GetAttribute("EventPhase") == "live"
end

-- The requirement curve this account was actually assigned. Two accounts on the
-- same rebirth count can owe different floors, so the arm has to be read rather
-- than assumed.
local function RebirthFloor(Count)
    local UsesV2 = false

    pcall(function()
        UsesV2 = RebirthExperiment.usesV2(LocalPlayer) == true
    end)

    local Floor = RebirthBonus.requirementFloorFor(Count, UsesV2)

    if type(Floor) ~= "number" then
        Floor = RebirthBonus.requirementFloor(Count)
    end

    return Floor
end

-- The rail badge is the readiness the server enforces: ArenaRailController draws
-- "!" in it the moment RebirthBonus.ready passes with this account's own arm,
-- and a bare number when the badge is only carrying unclaimed milestones. So a
-- visible badge is not enough on its own -- the text has to be the "!".
--
-- nil when the rail is not mounted yet, so the caller falls back instead of
-- reading a missing badge as "not ready" and stalling the run on a fresh join
local function RebirthBadgeReady()
    local Node = LocalPlayer:FindFirstChild("PlayerGui")

    for _, Name in ipairs({ "ArenaSideRail", "Frame", "rail", "Frame", "Rebirth", "badge" }) do
        if not Node then return nil end

        Node = Node:FindFirstChild(Name)
    end

    if not Node then return nil end
    if Node.Visible ~= true then return false end

    local Text = Node:FindFirstChild("Txt")

    if not (Text and Text:IsA("TextLabel")) then return nil end

    return Text.Text == "!"
end

local function RebirthReady()
    local Badge = RebirthBadgeReady()

    if Badge ~= nil then return Badge end

    return TowerBest() >= RebirthFloor(RebirthCount())
end

---- ============ Movement ============ ----

local MoveHoldUntil = 0
local KoCooldown = (GameConfig.pit.player and GameConfig.pit.player.koCooldown) or 3

local function HoldMovement(Seconds)
    MoveHoldUntil = math.max(MoveHoldUntil, os.clock() + (Seconds or KoCooldown))
end

local function MovementBusy()
    if os.clock() < MoveHoldUntil then return true end

    local Humanoid = GetHumanoid()

    if not Humanoid or Humanoid.Health <= 0 then return true end

    local State = Humanoid:GetState()

    return State == Enum.HumanoidStateType.Dead
        or State == Enum.HumanoidStateType.Freefall
        or State == Enum.HumanoidStateType.FallingDown
        or State == Enum.HumanoidStateType.Ragdoll
end

-- WalkSpeed, and the two rules that keep it out of the movement guard.
--
-- GameConfig.guard.speed is { refWalk = 16, mult = 1.5, absolute = 4,
-- seconds = 1, warnings = 6 }, and Core.Guard.Travel.excess prices a sample as
-- distance - (refWalk * mult * seconds + absolute) -- so 28 studs covered in a
-- second is the line, and six crossings inside guard.kick.forgetSeconds is the
-- kick. 18 and 20 are nowhere near it.
--
-- The part that is dangerous is not the number, it is WHEN. While scrap is
-- being carried the server writes WalkSpeed itself, out of scrap.weight
-- (avatarBaseWalk 16, down to minMult 0.35 at fullLoad 20 pieces), and a client
-- that overwrites what the server just wrote is a mismatch the server can see
-- without measuring anything. So the boost is only ever applied empty handed,
-- and the carry trip runs at whatever speed the server decided.
--
-- It also lapses a second after the last walk, like noclip, so the character is
-- back at its own speed whenever it is standing still.
local Pace = { Base = nil, Until = 0 }

do
    local Guard = GameConfig.guard and GameConfig.guard.speed or { }

    Pace.Ceiling = math.max(16, (Guard.refWalk or 16) * (Guard.mult or 1.5) - 4)
end

local function CarryingScrap()
    return (LocalPlayer:GetAttribute("scrapCarry") or 0) > 0
end

local function ReleaseSpeed(Restore)
    if Pace.Base then
        local Humanoid = GetHumanoid()

        -- Restore is false when the server is the one driving WalkSpeed now,
        -- which is exactly the moment a restore would fight it
        if Restore and Humanoid then
            pcall(function()
                Humanoid.WalkSpeed = Pace.Base
            end)
        end

        Pace.Base = nil
    end
end

local function ApplySpeed(Value)
    if type(Value) ~= "number" or Value <= 0 then return end

    if CarryingScrap() and not Config.Speed.Carry then
        ReleaseSpeed(false)

        return
    end

    local Humanoid = GetHumanoid()

    if not Humanoid then return end

    local Wanted = math.clamp(Value, 1, Pace.Ceiling)

    if not Pace.Base then
        Pace.Base = Humanoid.WalkSpeed
    end

    Pace.Until = os.clock() + 1

    if math.abs(Humanoid.WalkSpeed - Wanted) > 0.01 then
        Humanoid.WalkSpeed = Wanted
    end
end

-- Called on the status tick, twice a second.
--
-- With Speed.Hold set this is what makes the speed constant rather than a
-- thing that happens during errands: the walk jobs each renew it for a second
-- and this renews it again in between, so standing still, walking to the
-- recycler and pacing out the tutorial all run at the same number. It also
-- covers a respawn for free -- a fresh character comes back at 16 and the next
-- tick puts it back.
--
-- With Hold at 0 the old behaviour is left: the boost lapses a second after
-- the last walk and the character stands about at its own speed.
local function SpeedTick()
    local Hold = tonumber(Config.Speed.Hold) or 0

    if Hold > 0 then
        ApplySpeed(Hold)

        return
    end

    if Pace.Base and os.clock() > Pace.Until then
        ReleaseSpeed(not CarryingScrap())
    end
end

-- The clip used to be taken out of the character: every BasePart under it had
-- CanCollide written to false while a walk was in progress. That is what the
-- movement kick was, and removing this block is what stopped it.
--
-- The reason is replication, not physics. The client owns its own character's
-- parts, so a CanCollide the client writes on them is sent to the server and
-- stands there -- an anti-cheat reading HumanoidRootPart.CanCollide, or just
-- connected to its changed signal, sees a solid character turn hollow every
-- time the run walks anywhere. Nothing subtle has to be inferred from position.
--
-- So the clip is taken out of the world instead. The fences, coop walls and
-- plot edges the errands walk into are anchored map geometry the client does
-- not own, and a property the client writes on those never leaves the client.
-- The character stays fully collidable on the server for the whole session,
-- which is the only thing the server was being told about.
--
-- The one thing this has to be careful about is the ground, which is also an
-- anchored collidable part and is the one part the character is standing on.
--
-- Measuring the feet off the root and calling anything above that a wall is
-- what sank the character. It is a test that feeds on its own result: one
-- frame where the root dips -- a jump landing, a slope, a MoveTo bumping a
-- kerb -- puts the ground above the line, the ground is turned off, the
-- character falls, and falling puts the ground further above the line still.
-- There is no way back out of it.
--
-- So the ground is found rather than inferred. A ray straight down says which
-- part is underneath and how far, a raycast ignores CanCollide so the answer
-- does not change once this loop has been at it, and that part is never
-- clipped. Anything topping out within a stud of the floor is left alone as
-- well, which covers steps and kerbs, and the whole clip drops the moment
-- there is nothing underneath to stand on. Unanchored parts are skipped
-- throughout, since those can be handed to the client for ownership and would
-- replicate exactly like the character did.
local Noclip = { Connection = nil, Parts = { }, Until = 0, Radius = 14, Drop = 24, Reach = 8 }

local function RestorePart(Part)
    local Was = Noclip.Parts[Part]

    if Was == nil then return end

    Noclip.Parts[Part] = nil

    if Part and Part.Parent then
        pcall(function() Part.CanCollide = Was end)
    end
end

local function StopNoclip()
    if Noclip.Connection then
        Noclip.Connection:Disconnect()
        Noclip.Connection = nil
    end

    for Part, Was in pairs(Noclip.Parts) do
        if Part and Part.Parent then
            pcall(function() Part.CanCollide = Was end)
        end
    end

    table.clear(Noclip.Parts)
end

-- How high the part reaches in world space, rotation included. A fence laid
-- at an angle has a Size.Y that says nothing about how tall it stands, so the
-- box is projected onto the world Y axis rather than read off one side of it.
local function TopOf(Part)
    local CF = Part.CFrame
    local Size = Part.Size
    local _, _, _, _, _, _, R10, R11, R12 = CF:GetComponents()

    return CF.Position.Y
        + math.abs(R10) * Size.X * 0.5
        + math.abs(R11) * Size.Y * 0.5
        + math.abs(R12) * Size.Z * 0.5
end

local function StartNoclip()
    Noclip.Until = os.clock() + 1

    if Noclip.Connection then return end

    local Around = OverlapParams.new()

    Around.FilterType = Enum.RaycastFilterType.Exclude
    Around.MaxParts = 0

    local Under = RaycastParams.new()

    Under.FilterType = Enum.RaycastFilterType.Exclude

    Noclip.Connection = TrackConnection(game:GetService("RunService").Stepped:Connect(function()
        if os.clock() > Noclip.Until then
            StopNoclip()

            return
        end

        local Character = LocalPlayer.Character
        local Root = Character and Character:FindFirstChild("HumanoidRootPart")

        if not Root then return end

        Around.FilterDescendantsInstances = { Character }
        Under.FilterDescendantsInstances = { Character }

        local Ground = workspace:Raycast(Root.Position, Vector3.new(0, -Noclip.Drop, 0), Under)

        -- nothing underneath, or a long way down: the character is already
        -- falling or standing over a hole, and that is exactly the moment a
        -- clip must not be on. Everything goes back and the loop lets go.
        if not Ground or Ground.Distance > Noclip.Reach then
            StopNoclip()

            return
        end

        local Floor = Ground.Position.Y

        -- whatever is being stood on is solid, even if an earlier pass turned
        -- it off while it was still off to one side
        RestorePart(Ground.Instance)

        local Ok, Found = pcall(function()
            return workspace:GetPartBoundsInRadius(Root.Position, Noclip.Radius, Around)
        end)

        if not Ok or not Found then return end

        for _, Part in ipairs(Found) do
            -- a stud of headroom over the floor, so a step or a kerb is walked
            -- over rather than through
            if Part.CanCollide
                and Part.Anchored
                and Part ~= Ground.Instance
                and TopOf(Part) > Floor + 1 then
                if Noclip.Parts[Part] == nil then
                    Noclip.Parts[Part] = true
                end

                Part.CanCollide = false
            end
        end
    end))
end

local WalkOwner = nil
local WalkUntil = 0

-- One character, several loops that all want to walk it somewhere. Lower
-- number wins, and a claim lapses on its own so a dead loop cannot hold it.
--
-- Nest eggs come before scrap. An egg is the account's own laying, one at a
-- time, and it is what everything downstream is built out of -- the hatch, the
-- next chicken, the next rarity. Scrap is a shared pool of a hundred and forty
-- pieces that respawns on its own and is only money. The egg errand is also
-- the shorter one: it drops its claim the moment the character is within three
-- studs, because the server hands the egg over on its own tick from there, so
-- taking the lead costs the scrap loop a second at most.
local WalkPriority = { tutorial = 0, hotegg = 1, event = 2, egg = 3, scrap = 4, afk = 5 }

local function ClaimWalk(Who, Seconds)
    local Now = os.clock()

    if WalkOwner and Now < WalkUntil and WalkOwner ~= Who then
        if (WalkPriority[Who] or 9) >= (WalkPriority[WalkOwner] or 9) then
            return false
        end
    end

    WalkOwner = Who
    WalkUntil = Now + (Seconds or 1)

    return true
end

-- Which errands may walk through geometry, named one by one.
--
-- Every job here walks into something eventually -- scrap stacks sit behind the
-- pit fence, the trial pieces are dropped inside it, nest eggs are behind the
-- coop wall, the recycler is up against the plot edge -- and a MoveTo that runs
-- into a fence does not fail, it stalls that loop forever. So the clip stays on
-- for all of them.
--
-- This was briefly cut back to the scrap grabber alone, while the movement kick
-- was being tracked down, and the cut was then undone on the theory that the
-- kick had been the WalkSpeed this file used to write. That was wrong twice
-- over: the clip really was the kick, and cutting which errands may clip was
-- the wrong lever for it. Removing the clip entirely stops the kick, and the
-- clip is what the errands need, so what changed instead is where the clip is
-- taken from -- the world rather than the character, for the replication
-- reason written out above StopNoclip. Every errand may clip again.
--
-- What keeps it bounded is StartNoclip's own one second lapse: the clip is on
-- while a walk is in progress and off within a second of the walking stopping,
-- rather than held open for the session.
--
-- Anti-AFK is the deliberate exception. It is a two step stroll on open ground
-- that needs no clip at all, and the whole point of it is to look like a player
-- standing about.
Noclip.For = {
    tutorial = true,
    hotegg   = true,
    event    = true,
    egg      = true,
    scrap    = true,
}

local function WalkTo(Who, Position, Seconds, Speed)
    if MovementBusy() then return false end
    if not ClaimWalk(Who, Seconds) then return false end

    local Humanoid = GetHumanoid()

    if not Humanoid then return false end

    if Noclip.For[Who] then
        StartNoclip()
    end

    -- anti-AFK is the one errand that must look like a player standing about,
    -- so it neither clips nor hurries
    if Who ~= "afk" then
        ApplySpeed(Speed or Config.Speed.Collect)
    end

    Humanoid:MoveTo(Position)

    return true
end

---- ============ Goals ============ ----

-- One target: the rebirth count. Everything the run builds on the way there is
-- a means, not an end, and is no longer checked off as though it were one.
local function GoalRebirthDone()
    return RebirthCount() >= Config.Goal.Rebirth
end

-- Two targets now, and the second one is optional: Config.Goal.Rank is "" on a
-- default run, and GoalRankDone answers true for that. A run that does name a
-- rank is not finished until it holds it, so the tower and the scrap keep
-- running -- the arena matches on team power, and team power is level, which is
-- what the tower is for.
local function AllGoalsDone()
    return GoalRebirthDone() and GoalRankDone()
end

-- Whether the tower has banked the floor the rebirth ladder is going to ask
-- for. Not a goal -- a precondition -- and the rebirth policy reads it to
-- decide whether waiting for champion level is worth it.
local function TowerBanked()
    return TowerBest() >= Config.Build.TowerFloor
end

-- Unhatched eggs held. This is what the account is sitting on rather than
-- something it is working towards, and it is what the run keeps producing once
-- the target is behind it.
local function EggsHeld()
    local Roster = GetRoster()

    return Roster and EggTotal(Roster) or 0
end

-- Reaching the target does not end the run, it changes what the run is for.
--
-- Two jobs stop, and only two. The tower raises a level that a rebirth resets,
-- so once the last rebirth is taken the climb buys nothing; and scrap is money,
-- which is only ever spent on the plot that the tower and the rebirth needed.
-- The recycler goes with the scrap, since it is what the scrap was carried to.
--
-- Everything else keeps running, forever, because everything else is what the
-- account is worth: the chicken sits in the coop laying, the eggs it lays are
-- hatched to see whether something better comes out, the better one is fused
-- upward, and the world events are still worth turning up to. That has no
-- finish line and is not supposed to have one -- it stops when the script is
-- closed and not before.
local function Parked()
    return AllGoalsDone()
end

---- ============ Interface ============ ----

Elevate()

-- The window is built here rather than fetched.
--
-- It used to be a hundred-kilobyte UI library pulled over HTTP at boot, which
-- bought a general purpose toolkit -- tabs, toggles, sliders, colour pickers --
-- for a build that has no controls at all. This one reports and takes no input,
-- so all it needs is text in the right places, and that is fewer lines than the
-- network round trip it replaces -- one that could and did fail before the run
-- had started.
--
-- Everything lives on one table rather than one local per label, because the
-- main chunk of a Luau script may hold two hundred locals and this file is
-- close to that ceiling.
local UI = { Log = { }, Rows = { }, Jobs = { } }

do
    local Ink = {
        Back   = Color3.fromRGB(13, 14, 18),
        Panel  = Color3.fromRGB(20, 22, 28),
        Line   = Color3.fromRGB(38, 41, 51),
        Text   = Color3.fromRGB(236, 238, 243),
        Dim    = Color3.fromRGB(125, 131, 148),
        Accent = Color3.fromRGB(255, 80, 80),
        Good   = Color3.fromRGB(74, 222, 128),
        Idle   = Color3.fromRGB(64, 69, 84),
    }

    UI.Ink = Ink

    local function New(Class, Props, Parent)
        local Object = Instance.new(Class)

        for Key, Value in pairs(Props) do
            Object[Key] = Value
        end

        if Parent then
            Object.Parent = Parent
        end

        return Object
    end

    local function Round(Object, Radius)
        New("UICorner", { CornerRadius = UDim.new(0, Radius or 8) }, Object)

        return Object
    end

    local function Edge(Object, Colour)
        New("UIStroke", {
            Color = Colour or Ink.Line,
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        }, Object)

        return Object
    end

    local function Text(Parent, Props)
        return New("TextLabel", {
            BackgroundTransparency = 1,
            Font = Props.Font or Enum.Font.Gotham,
            Text = Props.Text or "",
            TextColor3 = Props.TextColor3 or Ink.Text,
            TextSize = Props.TextSize or 13,
            TextXAlignment = Props.TextXAlignment or Enum.TextXAlignment.Left,
            TextYAlignment = Props.TextYAlignment or Enum.TextYAlignment.Top,
            TextTransparency = Props.TextTransparency or 0,
            TextWrapped = Props.TextWrapped or false,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Position = Props.Position or UDim2.new(0, 0, 0, 0),
            Size = Props.Size or UDim2.new(1, 0, 1, 0),
            LayoutOrder = Props.LayoutOrder or 0
        }, Parent)
    end

    ---- the screen itself ----

    -- CoreGui, never PlayerGui.
    --
    -- PlayerGui is the game's own container: the game's scripts walk it, its
    -- own UI lives in it, and anything parented there is replicated back and
    -- wiped on respawn unless ResetOnSpawn is off. CoreGui is outside all of
    -- that -- it is not replicated, it survives a respawn on its own, and the
    -- game's LocalScripts have no business reading it.
    --
    -- A zero width space for a name, so the one thing a listing of CoreGui
    -- would show for this is nothing.
    local Screen = New("ScreenGui", {
        Name = utf8.char(8203),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
        IgnoreGuiInset = true
    })

    Screen.Parent = game:GetService("CoreGui")

    UI.Screen = Screen

    -- Measured, not guessed. The body holds 88 + 52 + 235 + 36 + 112 of panel
    -- and four ten-pixel gaps, which is 563; the card adds the 62 pixel header,
    -- 12 above the body and 14 below it. A card short of that clips the feed at
    -- the bottom, which is the one panel whose whole job is being readable.
    local Open = UDim2.new(0, 430, 0, 651)
    local Shut = UDim2.new(0, 430, 0, 62)

    local Card = Round(New("Frame", {
        Name = "Card",
        BackgroundColor3 = Ink.Back,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 24, 0.5, -325),
        Size = Open,
        ClipsDescendants = true
    }, Screen), 14)

    Edge(Card, Ink.Line)

    UI.Card = Card

    ---- header ----

    local Header = New("Frame", {
        Name = "Header",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 62)
    }, Card)

    New("ImageLabel", {
        BackgroundTransparency = 1,
        Image = "rbxassetid://" .. IconAsset,
        Position = UDim2.new(0, 16, 0, 15),
        Size = UDim2.new(0, 32, 0, 32)
    }, Header)

    Text(Header, {
        Text = "VALKYRIE HUB",
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        Position = UDim2.new(0, 58, 0, 14),
        Size = UDim2.new(0, 200, 0, 16)
    })

    Text(Header, {
        Text = "KAITAN",
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = Ink.Accent,
        Position = UDim2.new(0, 58, 0, 32),
        Size = UDim2.new(0, 200, 0, 14)
    })

    -- Uptime counts from the top of the file rather than from here, so it says
    -- how long the executor has been running this script and not how long the
    -- window has existed. On a rejoin those differ by the whole boot wait.
    UI.Clock = Text(Header, {
        Text = "00:00:00",
        Font = Enum.Font.Code,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Right,
        Position = UDim2.new(1, -152, 0, 14),
        Size = UDim2.new(0, 100, 0, 16)
    })

    Text(Header, {
        Text = "since execute",
        TextSize = 10,
        TextColor3 = Ink.Dim,
        TextXAlignment = Enum.TextXAlignment.Right,
        Position = UDim2.new(1, -152, 0, 33),
        Size = UDim2.new(0, 100, 0, 12)
    })

    local Fold = Round(New("TextButton", {
        Name = "Fold",
        BackgroundColor3 = Ink.Panel,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Position = UDim2.new(1, -40, 0, 19),
        Size = UDim2.new(0, 24, 0, 24),
        Font = Enum.Font.GothamBold,
        Text = "-",
        TextColor3 = Ink.Dim,
        TextSize = 15
    }, Header), 7)

    Edge(Fold, Ink.Line)

    New("Frame", {
        BackgroundColor3 = Ink.Line,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 61),
        Size = UDim2.new(1, 0, 0, 1)
    }, Card)

    ---- body ----

    local Body = New("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 74),
        Size = UDim2.new(1, -28, 1, -88)
    }, Card)

    New("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, Body)

    local Order = 0

    local function Next()
        Order = Order + 1

        return Order
    end

    ---- the two numbers the run is actually for ----

    local Tiles = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 88),
        LayoutOrder = Next()
    }, Body)

    local function Tile(Index, Caption)
        local Frame = Round(New("Frame", {
            BackgroundColor3 = Ink.Panel,
            BorderSizePixel = 0,
            Position = UDim2.new((Index - 1) * 0.5, (Index - 1) * 5, 0, 0),
            Size = UDim2.new(0.5, -5, 1, 0)
        }, Tiles), 10)

        Edge(Frame, Ink.Line)

        Text(Frame, {
            Text = Caption,
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            TextColor3 = Ink.Dim,
            Position = UDim2.new(0, 14, 0, 12),
            Size = UDim2.new(1, -28, 0, 12)
        })

        local Value = Text(Frame, {
            Text = "0",
            Font = Enum.Font.GothamBold,
            TextSize = 30,
            Position = UDim2.new(0, 14, 0, 28),
            Size = UDim2.new(1, -28, 0, 34)
        })

        local Note = Text(Frame, {
            Text = "",
            Font = Enum.Font.Code,
            TextSize = 11,
            TextColor3 = Ink.Dim,
            Position = UDim2.new(0, 14, 1, -22),
            Size = UDim2.new(1, -28, 0, 14)
        })

        return Value, Note
    end

    UI.RebirthValue, UI.RebirthNote = Tile(1, "REBIRTH")
    UI.EggsValue, UI.EggsNote = Tile(2, "EGGS HELD")

    ---- the champion, which is the other half of what the account is worth ----

    local Champ = Round(New("Frame", {
        BackgroundColor3 = Ink.Panel,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 52),
        LayoutOrder = Next()
    }, Body), 10)

    Edge(Champ, Ink.Line)

    UI.Rarity = Text(Champ, {
        Text = "-",
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = Ink.Accent,
        Position = UDim2.new(0, 14, 0, 9),
        Size = UDim2.new(1, -28, 0, 17)
    })

    UI.Chicken = Text(Champ, {
        Text = "-",
        Font = Enum.Font.Code,
        TextSize = 11,
        TextColor3 = Ink.Dim,
        Position = UDim2.new(0, 14, 0, 29),
        Size = UDim2.new(1, -28, 0, 14)
    })

    ---- everything else, one line each ----

    local Detail = Round(New("Frame", {
        BackgroundColor3 = Ink.Panel,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 235),
        LayoutOrder = Next()
    }, Body), 10)

    Edge(Detail, Ink.Line)

    local Rows = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 10),
        Size = UDim2.new(1, -28, 1, -20)
    }, Detail)

    New("UIListLayout", {
        Padding = UDim.new(0, 1),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, Rows)

    -- Caption left, figure right, so the figures line up down the panel and the
    -- eye can run the column rather than reading each row end to end. The
    -- figures are monospaced for the same reason.
    local function Row(Key, Caption)
        local Line = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 17),
            LayoutOrder = Next()
        }, Rows)

        Text(Line, {
            Text = Caption,
            TextSize = 12,
            TextColor3 = Ink.Dim,
            TextYAlignment = Enum.TextYAlignment.Center,
            Size = UDim2.new(0.36, 0, 1, 0)
        })

        UI.Rows[Key] = Text(Line, {
            Text = "-",
            Font = Enum.Font.Code,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Right,
            TextYAlignment = Enum.TextYAlignment.Center,
            Position = UDim2.new(0.36, 0, 0, 0),
            Size = UDim2.new(0.64, 0, 1, 0)
        })
    end

    Row("phase", "Doing")
    Row("money", "Money")
    Row("mult", "Money x")
    Row("genes", "Genes")
    Row("power", "Power")
    Row("laying", "Laying")
    Row("hunting", "Hunting")
    Row("roster", "Roster")
    Row("tower", "Tower")
    Row("arena", "Arena")
    Row("plot", "Plot")
    Row("budget", "Requests")
    Row("server", "Server")

    ---- which jobs are live, as ones and zeroes ----

    local Strip = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 36),
        LayoutOrder = Next()
    }, Body)

    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, Strip)

    -- A job is on or it is off. There is nothing in between and nothing to
    -- read, so it is printed as the one character that says so and the colour
    -- carries it from across the room.
    local function Job(Key, Caption, Index)
        local Cell = Round(New("Frame", {
            BackgroundColor3 = Ink.Panel,
            BorderSizePixel = 0,
            Size = UDim2.new(0.2, -4, 1, 0),
            LayoutOrder = Index
        }, Strip), 8)

        Edge(Cell, Ink.Line)

        Text(Cell, {
            Text = Caption,
            Font = Enum.Font.GothamBold,
            TextSize = 9,
            TextColor3 = Ink.Dim,
            TextXAlignment = Enum.TextXAlignment.Center,
            Position = UDim2.new(0, 0, 0, 6),
            Size = UDim2.new(1, 0, 0, 10)
        })

        UI.Jobs[Key] = Text(Cell, {
            Text = "0",
            Font = Enum.Font.Code,
            TextSize = 15,
            TextColor3 = Ink.Idle,
            TextXAlignment = Enum.TextXAlignment.Center,
            Position = UDim2.new(0, 0, 0, 17),
            Size = UDim2.new(1, 0, 0, 15)
        })
    end

    Job("lay", "LAY", 1)
    Job("hatch", "HATCH", 2)
    Job("fuse", "FUSE", 3)
    Job("tower", "TOWER", 4)
    Job("event", "EVENT", 5)

    ---- what the run just did ----

    local Feed = Round(New("Frame", {
        BackgroundColor3 = Ink.Panel,
        BorderSizePixel = 0,
        -- six lines of 14 with two between them is 94, plus 9 above and below
        Size = UDim2.new(1, 0, 0, 112),
        LayoutOrder = Next(),
        ClipsDescendants = true
    }, Body), 10)

    Edge(Feed, Ink.Line)

    local Lines = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 9),
        Size = UDim2.new(1, -28, 1, -18)
    }, Feed)

    New("UIListLayout", {
        Padding = UDim.new(0, 2),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, Lines)

    for Index = 1, 6 do
        UI.Log[Index] = Text(Lines, {
            Text = "",
            Font = Enum.Font.Code,
            TextSize = 11,
            -- the newest line reads at full strength and the rest fade back, so
            -- what just happened is findable without reading the timestamps
            TextColor3 = Index == 1 and Ink.Text or Ink.Dim,
            TextTransparency = Index == 1 and 0 or math.min(0.55, (Index - 1) * 0.12),
            Size = UDim2.new(1, 0, 0, 14),
            LayoutOrder = Index
        })
    end

    ---- folding, dragging, and the key that hides the lot ----

    do
        local Shown = true

        Fold.MouseButton1Click:Connect(function()
            Shown = not Shown

            Card.Size = Shown and Open or Shut
            Fold.Text = Shown and "-" or "+"
            Body.Visible = Shown
        end)

        TrackConnection(game:GetService("UserInputService").InputBegan:Connect(function(Input, Typed)
            if Typed then return end

            if Input.KeyCode == Enum.KeyCode.RightShift then
                Screen.Enabled = not Screen.Enabled
            end
        end))
    end

    -- Dragging by hand rather than through Frame.Draggable: that property has
    -- been deprecated for years, does not follow a touch, and drops the frame
    -- the moment the pointer leaves it.
    do
        local Input = game:GetService("UserInputService")
        local Dragging, Grab, Origin

        local function Held(What)
            return What.UserInputType == Enum.UserInputType.MouseButton1
                or What.UserInputType == Enum.UserInputType.Touch
        end

        TrackConnection(Header.InputBegan:Connect(function(What)
            if not Held(What) then return end

            Dragging = true
            Grab = What.Position
            Origin = Card.Position
        end))

        TrackConnection(Input.InputChanged:Connect(function(What)
            if not Dragging then return end

            if What.UserInputType ~= Enum.UserInputType.MouseMovement
                and What.UserInputType ~= Enum.UserInputType.Touch then
                return
            end

            local Move = What.Position - Grab

            Card.Position = UDim2.new(
                Origin.X.Scale, Origin.X.Offset + Move.X,
                Origin.Y.Scale, Origin.Y.Offset + Move.Y)
        end))

        TrackConnection(Input.InputEnded:Connect(function(What)
            if Held(What) then
                Dragging = false
            end
        end))
    end
end

-- A notice that fades on its own, in place of the library's. It is the only
-- thing in the window that arrives and leaves, so it builds itself each time
-- rather than being held open and hidden.
local function Notify(Title, Body)
    local Ink = UI.Ink
    local Tween = game:GetService("TweenService")
    local Fade = TweenInfo.new(0.25)

    local Toast = Instance.new("Frame")
    Toast.BackgroundColor3 = Ink.Panel
    Toast.BackgroundTransparency = 1
    Toast.BorderSizePixel = 0
    Toast.Position = UDim2.new(0, 24, 1, -110)
    Toast.Size = UDim2.new(0, 340, 0, 66)
    Toast.Parent = UI.Screen

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Toast

    local Bar = Instance.new("Frame")
    Bar.BackgroundColor3 = Ink.Accent
    Bar.BorderSizePixel = 0
    Bar.Size = UDim2.new(0, 3, 1, 0)
    Bar.Parent = Toast

    local Head = Instance.new("TextLabel")
    Head.BackgroundTransparency = 1
    Head.Font = Enum.Font.GothamBold
    Head.Text = Title
    Head.TextColor3 = Ink.Text
    Head.TextSize = 13
    Head.TextXAlignment = Enum.TextXAlignment.Left
    Head.Position = UDim2.new(0, 16, 0, 11)
    Head.Size = UDim2.new(1, -28, 0, 15)
    Head.Parent = Toast

    local Line = Instance.new("TextLabel")
    Line.BackgroundTransparency = 1
    Line.Font = Enum.Font.Gotham
    Line.Text = Body
    Line.TextColor3 = Ink.Dim
    Line.TextSize = 11
    Line.TextWrapped = true
    Line.TextXAlignment = Enum.TextXAlignment.Left
    Line.TextYAlignment = Enum.TextYAlignment.Top
    Line.Position = UDim2.new(0, 16, 0, 29)
    Line.Size = UDim2.new(1, -28, 0, 30)
    Line.Parent = Toast

    Tween:Create(Toast, Fade, { BackgroundTransparency = 0 }):Play()

    task.delay(7, function()
        pcall(function()
            Tween:Create(Toast, Fade, { BackgroundTransparency = 1 }):Play()
            Tween:Create(Bar, Fade, { BackgroundTransparency = 1 }):Play()
            Tween:Create(Head, Fade, { TextTransparency = 1 }):Play()
            Tween:Create(Line, Fade, { TextTransparency = 1 }):Play()
        end)

        task.wait(0.4)
        pcall(function() Toast:Destroy() end)
    end)
end

---- ============ Status ============ ----

local CurrentPhase = "boot"
local CurrentAction = "starting"
local LogLines = { }

local function Log(Text)
    table.insert(LogLines, 1, os.date("%H:%M:%S") .. "  " .. Text)

    while #LogLines > #UI.Log do
        table.remove(LogLines)
    end

    for Index, Label in ipairs(UI.Log) do
        Label.Text = LogLines[Index] or ""
    end
end

local function SetPhase(Phase, Action)
    CurrentPhase = Phase or CurrentPhase
    CurrentAction = Action or CurrentAction
end

local function Fmt(Number)
    if type(Number) ~= "number" then return tostring(Number) end

    local Suffixes = { "", "K", "M", "B", "T", "Qa", "Qi" }
    local Index = 1

    while Number >= 1000 and Index < #Suffixes do
        Number = Number / 1000
        Index = Index + 1
    end

    if Index == 1 then
        return string.format("%d", Number)
    end

    return string.format("%.2f%s", Number, Suffixes[Index])
end

-- Egg counts are read, not skimmed: 1,204 is a number a person can hold and
-- 1.20K is one they have to convert. So the stash keeps its digits and gets
-- separators instead of a suffix.
local function Commas(Number)
    local Whole = string.format("%d", math.floor(tonumber(Number) or 0))
    local Out = Whole

    while true do
        local Swapped
        Out, Swapped = Out:gsub("^(-?%d+)(%d%d%d)", "%1,%2")

        if Swapped == 0 then break end
    end

    return Out
end

-- written by the tutorial task, read here: the step machine is defined further
-- down and the window is built before it
local TutorialText = "checking"

-- Why the run is not rebirthing this second.
--
-- "Doing: rebirth" says the run wants one and says nothing about what is
-- stopping it, and what is stopping it is usually quiet -- a refusal the
-- console mentioned once and is now inside a backoff, or a chicken that has
-- been walking home for longer than it should. The rebirth task writes the
-- blocked cases here and the status pass fills in the ones where a rebirth is
-- not available yet.
--
-- A field on a table rather than a local of its own: this chunk sits near
-- Luau's ceiling of two hundred locals per function, and a status string is not
-- worth a slot the reporters at the end of the file still need.
local RebirthState = { Why = "checking" }

local function RefreshStatus()
    local Roster = GetRoster()
    local Champion = Roster and ChampionOf(Roster)
    local Coop = GetCoop()
    local Count = RebirthCount()
    local Points = RebirthPoints()
    local Best = TowerBest()
    local Limit = RosterLimit()
    local Eggs = Roster and EggTotal(Roster) or 0

    ---- header clock ----

    local Elapsed = os.clock() - StartedAt

    UI.Clock.Text = string.format("%02d:%02d:%02d",
        Elapsed // 3600, (Elapsed % 3600) // 60, Elapsed % 60)

    ---- the two numbers the run is for ----

    UI.RebirthValue.Text = tostring(Count)

    do
        local Need = RebirthFloor(Count)
        local Why = RebirthState.Why

        if Count >= Config.Goal.Rebirth then
            Why = "target met"
        elseif Best < Need then
            Why = string.format("needs floor %d, best %d", Need, Best)
        elseif Config.RebirthLevel > 1
            and not TowerBanked()
            and Champion
            and (Champion.level or 1) < Config.RebirthLevel then
            Why = string.format("waiting for level %d", Config.RebirthLevel)
        end

        UI.RebirthValue.TextColor3 = Count >= Config.Goal.Rebirth and UI.Ink.Good or UI.Ink.Text
        UI.RebirthNote.Text = string.format("of %d  %s", Config.Goal.Rebirth, Why)
    end

    UI.EggsValue.Text = Commas(Eggs)

    do
        local Target = Roster and Hunt.Target(Roster)
        local Next = Roster and Hunt.Tier(Roster)

        UI.EggsNote.Text = Next and ("next " .. Hunt.Name(Next)) or "nothing to open"

        if type(Config.Eggs.Want) == "string" and Config.Eggs.Want ~= "" then
            local Route = Hunt.From(Config.Eggs.Want)[1]

            UI.Rows.hunting.Text = string.format("%s via %s %.2f%%",
                Config.Eggs.Want,
                Route and Hunt.Name(Route.egg) or "nothing",
                Route and Route.chance * 100 or 0)
        else
            local Fresh, Total = Hunt.Fresh(Roster, Target)

            UI.Rows.hunting.Text = string.format("%s  %d/%d new", Hunt.Name(Target), Fresh, Total)
        end
    end

    ---- champion ----

    if Champion then
        local TypeDef = Catalog.chickenTypes[Champion.typeId] or Catalog.defaultChickenType
        local Archetype = (TypeDef and TypeDef.archetype) or { }
        local Genome = Champion.genome or { }
        local Parts = { }

        for _, Key in ipairs(GeneKeys) do
            table.insert(Parts, string.format("%s %d", Key:sub(1, 3), tonumber(Genome[Key]) or 0))
        end

        UI.Rarity.Text = string.format("%s  \u{00B7}  level %d",
            RarityOf(Champion), Champion.level or 1)
        UI.Chicken.Text = string.format("%s   hp x%.2f  atk x%.2f",
            tostring(Champion.nickname or Champion.typeId),
            Archetype.hp or 1, Archetype.atk or 1)

        UI.Rows.genes.Text = string.format("%d%% of %s cap %d",
            math.floor(GeneQuality(Champion) * 100 + 0.5),
            RarityOf(Champion), GeneCapOf(RarityOf(Champion)))
        UI.Rows.power.Text = Fmt(math.floor(PowerOf(Champion)))
    else
        UI.Rarity.Text = "no chicken yet"
        UI.Chicken.Text = "-"
    end

    ---- the rest ----

    UI.Rows.phase.Text = string.format("%s \u{00B7} %s", CurrentPhase, CurrentAction)
    UI.Rows.money.Text = Fmt(GetMoney())
    UI.Rows.mult.Text = string.format("%.2f   corn %.2f",
        1 + Count * GameConfig.rebirth.baseMoneyBonus + Points * GameConfig.rebirth.scaleMoneyBonus,
        1 + Count * GameConfig.rebirth.baseCornBonus + Points * GameConfig.rebirth.scaleCornBonus)

    do
        local Layer = Roster and Hunt.Layer(Roster)

        UI.Rows.laying.Text = Layer and tostring(Layer.nickname or Layer.typeId) or "-"
    end

    UI.Rows.roster.Text = string.format("%d / %s",
        #Chickens(Roster), Limit == math.huge and "?" or tostring(Limit))
    UI.Rows.tower.Text = string.format("floor %d   rebirth needs %d",
        Best, RebirthFloor(Count))

    do
        local Data = Ranked.Data
        local Want = Config.Goal.Rank

        if type(Data) ~= "table" then
            UI.Rows.arena.Text = Ranked.Why
        else
            local Line = string.format("%s   %d trophies",
                tostring(Data.rank or "-"), Data.trophies or 0)

            if type(Want) == "string" and Want ~= "" and RankedIndex[Want] then
                Line = Line .. string.format("   of %s", Want)
            end

            UI.Rows.arena.Text = Line .. "   \u{00B7} " .. Ranked.Why
        end
    end
    UI.Rows.plot.Text = string.format("%d feeders   recycler %d",
        Coop and #Coop.generators or 0, RecyclerLevel())
    UI.Rows.budget.Text = string.format("%d / %d per %ds%s",
        #Budget.Times, Budget.Calls, Budget.Window,
        os.clock() < Budget.HoldUntil and "  held" or "")
    UI.Rows.server.Text = string.format("%d / %d players",
        #Players:GetPlayers(), Players.MaxPlayers)

    ---- ones and zeroes ----

    do
        local Resting = Parked()

        local State = {
            -- laying is the one that must never read 0 once there is a chicken
            lay = Champion ~= nil and Roster ~= nil and Roster.activeId ~= nil,
            hatch = Eggs > 0,
            fuse = Roster ~= nil and #Chickens(Roster) >= 2,
            tower = not Resting and TowerActive(),
            event = Config.Events and EventLive(),
        }

        for Key, Label in pairs(UI.Jobs) do
            local On = State[Key] == true

            Label.Text = On and "1" or "0"
            Label.TextColor3 = On and UI.Ink.Good or UI.Ink.Idle
        end

        UI.Rows.phase.TextColor3 = Resting and UI.Ink.Good or UI.Ink.Text
    end

    if TutorialText ~= "done" and TutorialText ~= "off" then
        UI.Rows.phase.Text = string.format("tutorial \u{00B7} %s", TutorialText)
    end
end

---- ============ Chicken claim ============ ----

-- One chicken, five jobs that all want to order it somewhere, so there has to
-- be a ladder rather than five loops each deciding for itself. Lower wins, and
-- this is the order ChickenOwner below actually asks in:
--
--   0 tutorial -- while the game's own onboarding is running it decides
--   1 rebirth  -- has to be standing in the corral, and nothing may pull it out
--   2 event    -- boss and UFO windows are on a timer and do not come back
--   3 fuse     -- fusing the active chicken needs it in the corral too
--   4 tower    -- a run can be started again any time, so it yields to the rest
--
-- The table itself is only used to check that a claimant is a name this ladder
-- knows; the order is the if-chain in ChickenOwner.
local ChickenPriority = { tutorial = 0, rebirth = 1, event = 2, fuse = 3, tower = 4 }

-- filled in by the tutorial section further down, which needs things declared
-- here; until then nothing claims the chicken on the tutorial's behalf
local TutorialWantsChicken = function() return false end

local FuseWantsCorral = false

-- The floor requirement is the whole condition: tower.best is not reset by a
-- rebirth, so once it clears the floor this account's arm asks for -- which is
-- what RebirthReady reads off the rail badge -- the rebirth is available and
-- there is nothing to gain by sitting on it.
local function RebirthPending()
    if GoalRebirthDone() then return false end
    if not RebirthReady() then return false end

    if Config.RebirthLevel > 1 and not TowerBanked() then
        local Roster = GetRoster()
        local Champion = Roster and ChampionOf(Roster)

        if (Champion and (Champion.level or 1) or 1) < Config.RebirthLevel then
            return false
        end
    end

    return true
end

local function RebirthWantsChicken()
    return RebirthPending()
end

local EventChickenFlags = { chickenBoss = true, ufo = true }

local function EventWantsChicken()
    if not Config.Events then return false end
    if not EventLive() then return false end

    return EventChickenFlags[workspace:GetAttribute("EventId")] == true
end

local TowerBlocked = false

local function TowerWantsChicken()
    -- the last rebirth is taken; the climb raises a level nothing will spend
    if Parked() then return false end

    local Arena = MyArena()

    if not Arena then return false end

    if Arena:GetAttribute("TowerActive") == true then return true end

    return not TowerBlocked
end

local function ChickenOwner()
    if TutorialWantsChicken() then return "tutorial" end
    if RebirthWantsChicken() then return "rebirth" end
    if EventWantsChicken() then return "event" end
    if FuseWantsCorral then return "fuse" end
    if TowerWantsChicken() then return "tower" end
end

local function ChickenClaim(Claimant)
    if ChickenPriority[Claimant] == nil then return false end

    return ChickenOwner() == Claimant
end

local RecallAt = 0
local RecallOrderedAt = 0
local RecallWalkHome = 6

-- the server's own atCoop test is `order == "coop" and where == "corral"`, so
-- the order has to be sent AND the walk home has to finish. Sending the order
-- and reading the state on the same pass is not enough.
local function RecallChicken()
    if os.clock() - RecallAt < RecallWalkHome then return false end

    RecallAt = os.clock()

    if Remotes.fire(Remotes.defs.SetChickenOrder, "coop") then
        RecallOrderedAt = os.clock()
    end

    return false
end

-- The test the game itself runs before it will let a rebirth through.
--
-- RebirthController builds its `atCoop` out of two atoms and nothing else:
--
--     atCoop = ChickenMode.order() == "coop" and ChickenMode.where() == "corral"
--
-- so both halves matter. Standing in the corral is not enough -- the standing
-- ORDER has to say coop as well, which is why a chicken that wandered home on
-- its own after a "chaos" order still cannot rebirth.
--
-- This used to infer the order from RecallOrderedAt, a flag meaning "this run
-- sent a coop order at some point". That is not the same thing: the event task
-- sends "chaos" and the tutorial sends "follow" and "coop", and after either of
-- those the flag was still set while the order was not coop at all -- so the
-- rebirth went out and came back refused. Now the order is read rather than
-- assumed, with the old inference kept only for the case where the module was
-- not found in memory.
local function ChickenAtCoop()
    local Body = MyChickenBody()

    if not Body then return false end
    if TowerActive() then return false end
    if ChickenStateOf(Body) ~= "corral" then return false end

    local Mode = Modules.ChickenMode

    if Mode then
        local Ok, Order = pcall(Mode.order)

        return Ok and Order == "coop"
    end

    return RecallOrderedAt > 0
end

---- ============ Tutorial ============ ----

-- A brand new account is not free to do anything it likes: the game runs an
-- onboarding of its own, and the rewards behind it (a x3 XP boost while it is
-- running, a free barn egg at the end, and the recycler and incubator which
-- stay attribute-locked until their step) are worth more than the few minutes
-- it takes. So the run does the tutorial first, properly, in the game's order.
--
-- ReplicatedStorage.Features.Onboarding.Steps, read directly:
--
--   hatch -> feeder -> level2 -> tower -> rest -> recycler -> scrap ->
--   deposit -> hatch2 -> fuse -> follow -> chaos -> recall -> done
--
-- The step is not something the client decides. The server writes it onto the
-- player as the "onbStep" attribute and Steps.derive is only the fallback, so
-- this reads the attribute first and derives only when it is missing. Nothing
-- here tries to advance a step by itself -- every step is finished by doing the
-- thing the step asks for, and the server moves the attribute on.

local OnbSteps = Modules.OnbSteps
local OnbAttr = (OnbSteps and OnbSteps.Attr) or "onbStep"

-- the trial scrap for the "scrap" step is not in workspace.PitScrap with the
-- rest: the server sends its positions down the OnbTrial remote and the client
-- draws them itself, so the ordinary grabber cannot see them at all
local TrialState = nil

TrackConnection(Remotes.onClient("OnbTrial", function(State)
    if type(State) == "table" then
        TrialState = State
    end
end))

local function TrialRemaining()
    if type(TrialState) ~= "table" or type(TrialState.taken) ~= "table" then return end

    local Left = 0

    for _, Taken in pairs(TrialState.taken) do
        if not Taken then
            Left = Left + 1
        end
    end

    return Left
end

local function TrialTarget()
    if type(TrialState) == "table" and type(TrialState.positions) == "table" then
        for Index, Position in pairs(TrialState.positions) do
            if not (TrialState.taken and TrialState.taken[Index]) then
                return Position
            end
        end
    end

    -- the drawn parts are the same thing seen from the other side, and they are
    -- there even when this session missed the remote that carried the payload
    local Folder = workspace:FindFirstChild("OnbTrialScrap")

    if not Folder then return end

    local Root = GetRootPart()

    if not Root then return end

    local Best, BestDistance

    for _, Part in ipairs(Folder:GetChildren()) do
        if Part:IsA("BasePart") then
            local Distance = (Part.Position - Root.Position).Magnitude

            if not BestDistance or Distance < BestDistance then
                Best = Part.Position
                BestDistance = Distance
            end
        end
    end

    return Best
end

local function OnboardingLive()
    if not Config.Tutorial then return false end

    local Onb = GetData("onboarding")

    if type(Onb) ~= "table" then return false end
    if Onb.completed == true then return false end

    return true
end

local function OnboardingStep()
    if not OnboardingLive() then return end

    local Step = LocalPlayer:GetAttribute(OnbAttr)

    if type(Step) == "string" and Step ~= "" then
        return Step ~= "done" and Step or nil
    end

    if not OnbSteps then return end

    local Onb = GetData("onboarding") or { }
    local Roster = GetRoster() or { }
    local Coop = GetCoop()
    local List = Chickens(Roster)
    local Active

    for _, Chicken in ipairs(List) do
        if Chicken.id == Roster.activeId then
            Active = Chicken
        end
    end

    Active = Active or List[1]

    local Where = ChickenStateOf(MyChickenBody()) or "corral"

    local Ok, Derived = pcall(OnbSteps.derive, {
        completed = Onb.completed == true,
        rewardGranted = Onb.rewardGranted == true,
        rosterCount = #List,
        hasFeeder = Coop and #Coop.generators > 0 or false,
        activeLevel = Active and (Active.level or 0) or 0,
        towerBest = TowerBest(),
        recyclerLevel = RecyclerLevel(),
        chickenFighting = Where == "pit" or Where == "campaign",
        restReady = Where == "corral",
        trialRemaining = TrialRemaining(),
        fused = Onb.fused == true,
        walked = Onb.walked == true,
        sentChaos = Onb.sentChaos == true,
        recalled = Onb.recalled == true
    })

    if Ok and type(Derived) == "string" and Derived ~= "done" then
        return Derived
    end
end

-- the steps that need the chicken pointed somewhere; while one of these is the
-- current step nothing else may give the chicken an order
-- While any step is live the tutorial owns the chicken, so the tower loop
-- cannot start a run in the middle of, say, the scrap trial and drag the
-- chicken off the plot. The one exception is the fuse step: that is the
-- ordinary fusion task's job, and it claims the chicken as "fuse" itself.
TutorialWantsChicken = function()
    local Step = OnboardingStep()

    return Step ~= nil and Step ~= "fuse"
end

---- ============ Fusion ============ ----

-- Fusing is the only thing in the game that raises rarity or genes, so this is
-- where the account is actually built. FusionRules.resolve, read off the live
-- client, says:
--
--   * every fuse takes max(geneA, geneB) per gene -- genes never go down
--   * SAME rarity also rolls an ascend and guarantees a gene mutation
--   * DIFFERENT rarity does neither: the higher side's chassis and rarity are
--     kept and the only gain is whatever gene the lower one happens to hold
--
-- so a same-rarity partner is always preferred, and a cross-rarity partner is
-- only worth the money when it strictly raises one of the champion's genes.

local function GeneOf(Chicken, Key)
    return tonumber((Chicken.genome or { })[Key]) or 0
end

-- how much of the champion's remaining gene headroom this partner fills
local function GeneGain(Champion, Partner)
    local Cap = GeneCapOf(RarityOf(Champion))
    local Gain = 0

    for _, Key in ipairs(GeneKeys) do
        local Mine = GeneOf(Champion, Key)
        local Theirs = math.min(GeneOf(Partner, Key), Cap)

        if Theirs > Mine then
            Gain = Gain + (Theirs - Mine)
        end
    end

    return Gain
end

local function FuseCost(A, B)
    local Ok, Cost = pcall(FusionRules.cost, {
        level = A.level or 1,
        rarity = RarityOf(A),
        genome = A.genome or { }
    }, {
        level = B.level or 1,
        rarity = RarityOf(B),
        genome = B.genome or { }
    })

    return (Ok and type(Cost) == "number") and Cost or nil
end

-- level and ability are the two lock slots every account has for free. Level
-- goes to the higher side or the fuse throws away the tower run that paid for
-- it; ability goes to whichever side has one at all. The egg pool is left
-- unlocked on purpose: unlocked means both stashes are summed rather than one
-- being dropped.
local function BuildLocks(A, B)
    local Locks = { }

    local LevelFrom = ((B.level or 1) > (A.level or 1)) and B or A

    table.insert(Locks, { field = "level", from = LevelFrom.id })

    local AbilityFrom

    if A.ability and not B.ability then
        AbilityFrom = A
    elseif B.ability and not A.ability then
        AbilityFrom = B
    elseif A.ability and B.ability then
        -- neither is objectively better from the client's tables, so the
        -- higher-scoring body keeps its own kit
        AbilityFrom = (KeepScore(A) >= KeepScore(B)) and A or B
    end

    if AbilityFrom then
        table.insert(Locks, { field = "ability", from = AbilityFrom.id })
    end

    return Locks
end

-- Picks the pair to send this pass, or nothing.
--
--   1. champion + a mutated partner       -- an even chance at a mutation
--   2. champion + a same-rarity partner   -- ascend roll and a free gene mutation
--   3. champion + a cross-rarity partner  -- only if it raises a gene
--   4. the fullest low bucket, paired up  -- breeds fodder toward the champion
--
-- What a favourite means here changed, and it is the point of the whole block.
--
-- This used to skip anything favourited, and the run favourites the chicken it
-- puts on the plot -- so a special common the run had marked to protect was
-- protected from being FUSED as well as from being sold, which is the opposite
-- of what marking it was for. A favourite now means "never sold" and nothing
-- else; what a fuse may not take is the champion and whatever is standing on
-- the plot, and those are checked by id.
local function PlanFusion(Roster)
    local List = Chickens(Roster)

    if #List < 2 then return end

    local Champion = ChampionOf(Roster)

    if not Champion then return end

    local ChampionRarity = RarityOf(Champion)
    local ChampionMutation = MutationOf(Champion)

    local Buckets = { }
    local Best, BestGain

    for _, Chicken in ipairs(List) do
        if Chicken.id ~= Champion.id and Chicken.id ~= Roster.activeId then
            local Rarity = RarityOf(Chicken)
            local Mutation = MutationOf(Chicken)

            -- a mutated chicken is never fodder: it is held back for the
            -- champion, which is the only fuse where the 50% carry is worth
            -- spending it on
            if not Mutation then
                Buckets[Rarity] = Buckets[Rarity] or { }
                table.insert(Buckets[Rarity], Chicken)
            end

            -- The champion already carries one, and MutationView.fusionOdds is
            -- blunt about what that means: a fuse where only one side has the
            -- mutation keeps it with probability mutationInherit, which is a
            -- half. So every ordinary fuse is a coin flip on losing the rarest
            -- thing the account owns -- and the only fuse that is not is one
            -- against the same mutation, which the same function returns a
            -- flat 1 for. So that is the only partner considered, and when
            -- there is none the champion is left alone and the fodder below
            -- gets the pass instead.
            local Allowed = (ChampionMutation == nil) or (Mutation == ChampionMutation)

            if Allowed then
                local Gain = GeneGain(Champion, Chicken)
                local Score

                if Mutation then
                    -- top of the list either way: an even chance at a mutation
                    -- the account cannot work towards, or a certainty of
                    -- keeping the one it has
                    Score = 3000 + Gain
                elseif Rarity == ChampionRarity then
                    -- same rarity is what rolls the ascend and guarantees a
                    -- gene mutation; among them the one that fills the most
                    -- gene headroom wins
                    Score = 1000 + Gain
                elseif Gain > 0 then
                    -- A cross-rarity partner neither ascends nor mutates, so it
                    -- is only worth the money when it strictly raises a gene
                    -- the champion is short of. It scores under a thousand, so
                    -- it can never take a fuse away from an ascend roll -- it
                    -- fills the passes where there is no same-rarity partner to
                    -- be had.
                    Score = Gain
                end

                if Score and (not BestGain or Score > BestGain) then
                    Best = Chicken
                    BestGain = Score
                end
            end
        end
    end

    if Best then
        return Champion, Best, "champion"
    end

    -- no partner for the champion: breed the fodder upward instead. The bucket
    -- with the most members is taken first because that is also the one making
    -- the roster full.
    local BucketName, BucketList

    for Rarity, Members in pairs(Buckets) do
        if #Members >= 2 then
            if not BucketList
                or #Members > #BucketList
                or (#Members == #BucketList and (RarityRank[Rarity] or 1) > (RarityRank[BucketName] or 1)) then
                BucketName = Rarity
                BucketList = Members
            end
        end
    end

    if not BucketList then return end

    -- greedy pairing: the best of the bucket, plus whichever partner adds the
    -- most on top of it
    table.sort(BucketList, function(Left, Right)
        return KeepScore(Left) > KeepScore(Right)
    end)

    local A = BucketList[1]
    local B, BGain

    for Index = 2, #BucketList do
        local Candidate = BucketList[Index]
        local Gain = GeneGain(A, Candidate)

        if not BGain or Gain > BGain then
            B = Candidate
            BGain = Gain
        end
    end

    if not B then return end

    return A, B, "fodder"
end

---- ============ Tasks ============ ----

-- Every remote-sending job lives here, checked in order, and the first one
-- with something to do this pass gets the send. One send per pass keeps the
-- whole run inside the budget no matter how many jobs are eligible at once.

local Tasks = { }

local function Task(Name, Phase, Step)
    table.insert(Tasks, { Name = Name, Phase = Phase, Step = Step })
end

-- a reply worth logging, and the answer to "did this pass do anything"
local function Claimed(Label, Reply)
    if type(Reply) == "table" and Reply.ok then
        Log(Label)

        return true
    end

    return false
end

--// the game's own onboarding, in the game's own order
do
local OrderSentAt = 0
local StepStartedAt = 0
local LastStep = nil

local function Order(Name)
    if os.clock() - OrderSentAt < 4 then return true end

    OrderSentAt = os.clock()

    Remotes.fire(Remotes.defs.SetChickenOrder, Name)

    return true
end

Task("tutorial", "tutorial", function()
    local Step = OnboardingStep()

    if not Step then
        if LastStep then
            Log("tutorial finished")

            LastStep = nil
        end

        TutorialText = Config.Tutorial and "done" or "off"

        return false
    end

    if Step ~= LastStep then
        LastStep = Step
        StepStartedAt = os.clock()

        Log("tutorial step: " .. Step)
    end

    do
        local Order = (OnbSteps and OnbSteps.ORDER) or { }
        local Index = 0

        for At, Name in ipairs(Order) do
            if Name == Step then
                Index = At
            end
        end

        TutorialText = Index > 0
            and string.format("%s  (%d / %d)", Step, Index, #Order)
            or Step
    end

    -- hatching, buying the feeder and fusing are all things the ordinary tasks
    -- already do correctly, so the step is handed to them rather than done
    -- twice. Everything else is the tutorial's own.
    if Step == "hatch" or Step == "hatch2" then
        local Roster = GetRoster()
        local Tier = Roster and FirstEggTier(Roster)

        -- no egg in hand means the chicken has to lay one and it has to be
        -- walked to, which the nest egg loop is already doing
        if not Tier then return false end

        return Claimed("tutorial hatch", Ask(Remotes.defs.HatchEgg, Tier))
    end

    if Step == "feeder" then
        local Coop = GetCoop()

        if not Coop then return false end

        local Feeders = #Coop.generators

        if not CanAfford(CoopView.buyGeneratorCost(Feeders)) then return false end

        return Claimed("tutorial feeder bought", Ask(Remotes.defs.BuyGenerator, Feeders + 1))
    end

    -- the chicken is eating from the feeder and the server is counting the XP.
    -- Nothing to send; the standing order only has to leave it at the coop.
    if Step == "level2" then
        local Body = MyChickenBody()

        if Body and ChickenStateOf(Body) ~= "corral" then
            return Order("coop")
        end

        return false
    end

    if Step == "tower" then
        if TowerActive() then return false end

        local Body = MyChickenBody()

        if not Body then return false end

        local State = ChickenStateOf(Body)

        if State == "campaign" then return false end

        if State ~= "corral" then
            return Order("coop")
        end

        -- the first floor is what the step asks for, so no elevator: it would
        -- only spend the money the feeder and the recycler still need
        if os.clock() - StepStartedAt < 3 then return false end

        return Claimed("tutorial tower run started", Ask(Remotes.defs.TowerStart))
    end

    if Step == "rest" then
        local Body = MyChickenBody()

        if Body and ChickenStateOf(Body) == "corral" then return false end

        return Order("coop")
    end

    if Step == "recycler" then
        if LocalPlayer:GetAttribute(RecyclerView.LockedAttr) == true then return false end
        if LocalPlayer:GetAttribute(RecyclerView.BusyAttr) == true then return false end
        if not CanAfford(RecyclerView.upgradeCost(0)) then return false end

        return Claimed("tutorial recycler installed", Ask(Remotes.defs.UpgradeRecycler))
    end

    -- the trial pieces are picked up by standing near them and the deposit is
    -- made by standing at the recycler, so both are walked, not sent
    if Step == "scrap" or Step == "deposit" then
        return false
    end

    if Step == "fuse" then
        return false
    end

    if Step == "follow" then
        local Body = MyChickenBody()

        -- "follow" first, then the walk, and the walk is the other loop's job
        if Body and ChickenStateOf(Body) == "hub" then return false end

        return Order("follow")
    end

    if Step == "chaos" then
        local Body = MyChickenBody()
        local State = Body and ChickenStateOf(Body)

        if State == "pit" or State == "campaign" then return false end

        return Order("chaos")
    end

    if Step == "recall" then
        local Body = MyChickenBody()

        if Body and ChickenStateOf(Body) == "corral" then return false end

        return Order("coop")
    end

    return false
end)
end

--// codes, once
do
local CodesDone = false

Task("codes", "boot", function()
    if CodesDone or type(Config.Codes) ~= "table" or #Config.Codes == 0 then
        CodesDone = true

        return false
    end

    local Code = table.remove(Config.Codes, 1)

    CodesDone = #Config.Codes == 0

    local Reply = Ask(Remotes.defs.RedeemCode, Code)

    if type(Reply) == "table" and Reply.ok then
        Log("redeemed code " .. tostring(Code))
    end

    return true
end)
end

--// rewards
Task("daily", "rewards", function()
    if not Config.Rewards then return false end

    local Daily = GetData("daily")

    if type(Daily) ~= "table" then return false end

    local Taken = type(Daily.claimed) == "table" and Daily.claimed or { }
    local Streak = Daily.streak or 0

    if Taken[DailyView.DAY_KEY] ~= true and Streak >= 1 and GameConfig.daily.days[Streak] then
        Claimed("daily streak claimed", Ask(Remotes.defs.DailyClaim, "day", nil))

        return true
    end

    local Played = Daily.played or 0

    for Index = 1, #GameConfig.daily.session do
        if DailyView.sessionReady(Played, Index) and not Taken[DailyView.sessionKey(Index)] then
            Claimed("play-today reward " .. Index, Ask(Remotes.defs.DailyClaim, "session", Index))

            return true
        end
    end

    return false
end)

Task("missions", "rewards", function()
    if not Config.Rewards then return false end

    local Missions = GetData("missions")

    if type(Missions) ~= "table" then return false end

    local Rebirth = GetData("rebirth")
    local Scrap = GetData("scrap")

    local Snapshot = {
        roster = GetRoster(),
        towerBest = TowerBest(),
        rebirthCount = type(Rebirth) == "table" and (Rebirth.count or 0) or 0,
        recyclerLevel = type(Scrap) == "table" and (Scrap.recyclerLevel or 0) or 0,
        missions = Missions
    }

    for _, Scope in ipairs(MissionView.SCOPES) do
        for _, Mission in ipairs(MissionView.active(Scope)) do
            if Mission.kind == nil and MissionView.stateOf(Snapshot, Mission) == "ready" then
                Claimed("mission " .. tostring(Mission.id), Ask(Remotes.defs.MissionClaim, Mission.id))

                return true
            end
        end
    end

    return false
end)

Task("pass", "rewards", function()
    if not Config.Rewards then return false end

    local Pass = GetData("pass")

    if type(Pass) ~= "table" then return false end

    for Level = 1, #GameConfig.premium.pass.levels do
        if PassView.state(Pass, Level) == "claimable" then
            Claimed("weekly pass level " .. Level, Ask(Remotes.defs.PassClaim, Level, PassView.track(Level)))

            return true
        end
    end

    return false
end)

-- Rebirth milestones, added by the same update as the arena.
--
-- rebirth.claimed is a set keyed by the step's "at" as a string, and the ladder
-- is Content.RebirthMilestones. ClaimRebirthMilestones takes nothing and claims
-- every pending step at once -- what the game's own CLAIM ALL button sends --
-- and ClaimRebirthMilestone(at) is the per-step fallback for when the bulk call
-- is refused. This run rebirths to three figures, so the bulk call is what it
-- almost always wants: a hundred rebirths is dozens of pending steps.
Task("milestone", "rewards", function()
    if not Config.Rewards then return false end

    local Rebirth = GetData("rebirth")

    if type(Rebirth) ~= "table" then return false end

    local Taken = type(Rebirth.claimed) == "table" and Rebirth.claimed or { }
    local Reached = RebirthMilestones.reachedCount(Rebirth.count or 0) or 0
    local Pending = nil

    for Index = 1, Reached do
        local Step = RebirthMilestones.nth(Index)

        if type(Step) == "table" and Taken[tostring(Step.at)] ~= true then
            Pending = Step.at

            break
        end
    end

    if not Pending then return false end

    if Claimed("rebirth milestones claimed", Ask(Remotes.defs.ClaimRebirthMilestones)) then
        return true
    end

    Claimed("rebirth milestone " .. tostring(Pending), Ask(Remotes.defs.ClaimRebirthMilestone, Pending))

    return true
end)

do
local SocialAt = 0

Task("social", "rewards", function()
    if not Config.Rewards then return false end
    if os.clock() - SocialAt < 300 then return false end

    SocialAt = os.clock()

    Ask(Remotes.defs.SocialClaim)

    return true
end)
end

--// the ranked arena
--
-- One task rather than five, because the worker's rule is one send per pass and
-- the arena's steps are strictly ordered anyway: the view has to be fresh
-- before anything can be decided from it, rank rewards are free and are taken
-- first, a team has to be fielded before a battle can start, and a battle
-- cannot start while one is running.
--
-- The battle itself takes the character to the arena stage for about a minute,
-- so the walking jobs lose that minute. That is the cost of the feature and it
-- is why Config.Arena.MinRarity holds the whole thing back until the collection
-- is worth fielding -- an early arena spends an hour of walking to lose.
Task("arena", "arena", function()
    if not RankedWorthEntering() then return false end

    -- a stale view is the pass's one send; everything below reads what it left
    if os.clock() - Ranked.ReadAt >= Ranked.Refresh or Ranked.Data == nil then
        local Reply = Ask(Remotes.defs.ArenaGetView)

        if type(Reply) == "table" and Reply.ok and type(Reply.data) == "table" then
            Ranked.Data = Reply.data
            Ranked.ReadAt = os.clock()
        else
            -- Ask is inside its own backoff, or the budget swallowed the call.
            -- Either way the cache is not refreshed and the next pass tries
            -- again; nothing below is allowed to act on a view this old.
            Ranked.ReadAt = os.clock() - Ranked.Refresh + 5

            return false
        end

        return true
    end

    local Data = Ranked.Data

    if Data.unlocked == false or Data.available == false then
        Ranked.Why = "not open on this account yet"

        return false
    end

    -- rank rewards are paid once per rank ever reached and do not depend on a
    -- battle, so they are taken before anything that costs a minute
    for _, Entry in ipairs(Data.claimable or { }) do
        if type(Entry) == "table" and Entry.rankId then
            Claimed("arena reward " .. tostring(Entry.rankId), Ask(Remotes.defs.ArenaClaim, Entry.rankId))

            Ranked.ReadAt = 0

            return true
        end
    end

    if GoalRankDone() then
        Ranked.Why = "rank target met"

        return false
    end

    if RankedBusy() then
        Ranked.Why = "battle running"

        return false
    end

    -- the server keeps this as an attribute on the player and fires the team's
    -- abilities itself, so it is one send for the whole session
    if Config.Arena.Ability and not Ranked.AbilitySent then
        Ranked.AbilitySent = true

        if Remotes.fire(Remotes.defs.SetArenaAutoAbility, true) then
            Log("arena auto ability on")

            return true
        end
    end

    -- incomplete means a saved team id is no longer in the roster, which the
    -- sell and fuse tasks cause on their own; the server refuses to fight with
    -- a team in that state
    local Best = RankedBestIds(Data)

    if #Best > 0 and (Data.incomplete == true or #(Data.team or { }) == 0 or not RankedSameTeam(Best, Data.teamIds)) then
        Claimed("arena team fielded", Ask(Remotes.defs.ArenaSetTeam, Best))

        Ranked.ReadAt = 0

        return true
    end

    local Opponent = RankedOpponent(Data)

    if not Opponent then
        Ranked.Why = "no opponent offered"

        return false
    end

    -- skips unlock after the first match, and the first match is forced to the
    -- easier band by the game itself, so nothing is skipped before then
    local Skip = { }

    for _, Band in ipairs(Config.Arena.Skip or { }) do
        Skip[Band] = true
    end

    if Skip[Opponent.band] and (Data.lifetimeMatches or 0) > 0 and (Data.skips or 0) > 0 then
        Claimed("arena skipped a " .. tostring(Opponent.band) .. " opponent", Ask(Remotes.defs.ArenaSkip))

        Ranked.ReadAt = 0

        return true
    end

    Ranked.Why = "fighting " .. tostring(Opponent.name or "?")

    if Claimed("arena battle started", Ask(Remotes.defs.ArenaFight)) then
        Ranked.Battling = true
        Ranked.BattleUntil = os.clock() + 66
        Ranked.ReadAt = 0
    end

    return true
end)

--// hatching
do
local HatchFullAt = nil

Task("hatch", "chicken", function()
    local Roster = GetRoster()

    if not Roster then return false end

    local Tier, Count = Hunt.Tier(Roster)

    if not Tier then return false end

    local Held = #Chickens(Roster)
    local Limit = RosterLimit()

    -- no room, no request: asking past the roster cap is what earned the kick
    if Held >= Limit then return false end
    if HatchFullAt and Held >= HatchFullAt then return false end

    local BatchMax = GameConfig.roster.hatch.batchMax or 10
    local Amount = math.min(Count, BatchMax, math.max(1, Limit - Held))

    local Reply

    if Amount > 1 then
        Reply = Ask(Remotes.defs.HatchEggs, Tier, Amount)
    else
        Reply = Ask(Remotes.defs.HatchEgg, Tier)
    end

    if type(Reply) == "table" and Reply.ok ~= true and Reply.error == "roster-full" then
        HatchFullAt = Held
    elseif type(Reply) == "table" and Reply.ok then
        HatchFullAt = nil

        local Fresh = Hunt.Fresh(Roster, Tier)

        Log(string.format("hatched %d %s%s%s", Amount, Hunt.Name(Tier),
            Amount > 1 and "s" or "",
            Fresh > 0 and string.format(" (%d types still new)", Fresh) or ""))
    end

    return true
end)
end

--// selling, only under roster pressure
Task("sell", "chicken", function()
    local Roster = GetRoster()

    if not Roster then return false end

    local Limit = RosterLimit()

    if Limit == math.huge then return false end

    local List = Chickens(Roster)
    local Held = #List
    local Fill = Held / Limit

    if Fill < (Config.Sell.AtFrac or 0.75) then return false end

    local Champion = ChampionOf(Roster)

    if not Champion then return false end

    local Guard = RarityRank[Config.Sell.Protect or ""] or math.huge
    local Cut = (RarityRank[RarityOf(Champion)] or 1) - (Config.Sell.Below or 3)

    -- Anything that may be sold at all. The exemptions are absolute and apply
    -- to the panic pass further down as well: nothing here ever sells the
    -- champion, whatever is standing on the plot, a favourite, a chicken at the
    -- protected rarity, or anything carrying a mutation.
    --
    -- The mutation is the one added here, and it is added at this level rather
    -- than in the ordinary pass below on purpose. A rule written in rarities
    -- cannot see it: a mutated common reads as fodder by every measure this
    -- task has, and one hatch in two hundred went into a batch of twenty ids
    -- without anything noticing. Rarity can be climbed again. A mutation
    -- cannot be worked towards at all.
    --
    -- Genes are NOT exempted here, only in the ordinary pass below. A chicken
    -- that raises one of the champion's genes is worth keeping while there is
    -- room, and on a roster that is 97% full there is no room -- exempting
    -- them from the panic pass as well would leave a full roster with nothing
    -- sellable in it, which stops the hatching, which stops the run.
    local Loose = { }

    for _, Chicken in ipairs(List) do
        if Chicken.id ~= Champion.id
            and Chicken.id ~= Roster.activeId
            and Chicken.favorite ~= true
            and not MutationOf(Chicken)
            and (RarityRank[RarityOf(Chicken)] or 1) < Guard then
            table.insert(Loose, Chicken)
        end
    end

    -- Fusing is the only way rarity goes up, and it takes two of the same
    -- rarity to raise one, so a pair of each bucket is kept back even under
    -- the floor. That pair is the ladder the next rarity climbs; selling it is
    -- selling the ladder to buy a look at the roof.
    local Buckets = { }

    for _, Chicken in ipairs(Loose) do
        local Rarity = RarityOf(Chicken)

        Buckets[Rarity] = Buckets[Rarity] or { }
        table.insert(Buckets[Rarity], Chicken)
    end

    local Ids = { }
    local Batch = Config.Sell.Batch or 20

    -- walked lowest rarity first, so when the batch cap bites it is the
    -- commons that went and not whichever bucket `pairs` happened to reach
    for Rank = 1, math.min(Cut - 1, #Rarities) do
        local Rarity = Rarities[Rank]
        local Members = Buckets[Rarity]

        if Members then
            -- best first, so the pair that stays behind is the pair worth
            -- fusing rather than whichever two the table happened to list
            table.sort(Members, function(A, B)
                return KeepScore(A) > KeepScore(B)
            end)

            for Index = (Config.Sell.Fodder or 2) + 1, #Members do
                local Chicken = Members[Index]

                -- a chicken that still raises one of the champion's genes is
                -- worth more fused into it than sold
                if GeneGain(Champion, Chicken) == 0 and #Ids < Batch then
                    table.insert(Ids, Chicken.id)
                end
            end
        end
    end

    -- Last resort. Everything above is about not throwing away something
    -- useful; this is about the roster refusing the next hatch, which stops
    -- the account climbing at all. The weakest go, exemptions still honoured.
    if #Ids == 0 and Fill >= (Config.Sell.PanicFrac or 0.97) then
        table.sort(Loose, function(A, B)
            return KeepScore(A) < KeepScore(B)
        end)

        local Room = math.max(1, math.floor(Limit * 0.1))

        for Index = 1, math.min(#Loose, Room, Batch) do
            table.insert(Ids, Loose[Index].id)
        end

        if #Ids > 0 then
            Log(string.format("roster %d/%d -- selling %d of the weakest to make room",
                Held, Limit, #Ids))
        end
    end

    if #Ids == 0 then return false end

    return Claimed(string.format("sold %d (roster %d/%d, under %s)",
        #Ids, Held, Limit, (Rarities[Cut] or "none")), Ask(Remotes.defs.SellChickens, Ids))
end)

--// marking the ones that must never be sold
--
-- The sell task already refuses to sell a mutated chicken, and that refusal
-- lives in this script and nowhere else. The game's own favourite flag does the
-- same job on the server's copy of the roster, so marking it there is what
-- makes the protection outlive this session: a rejoin, a crash, a hand-run of
-- some other script over the same account, none of them can turn a mutated
-- common into fodder once the game itself has it flagged.
--
-- The mark says "never sold" and nothing more. PlanFusion deliberately ignores
-- it, because spending a mutated common on the champion -- an even chance of
-- moving the mutation across, a certainty once the champion carries the same
-- one -- is the entire reason for keeping it.
do
local ProtectAt = 0
local ProtectTries = { }

Task("protect", "chicken", function()
    if os.clock() - ProtectAt < 5 then return false end

    local Roster = GetRoster()

    if not Roster then return false end

    for _, Chicken in ipairs(Chickens(Roster)) do
        local Mutation = MutationOf(Chicken)

        if Mutation and Chicken.favorite ~= true and (ProtectTries[Chicken.id] or 0) < 3 then
            ProtectAt = os.clock()
            ProtectTries[Chicken.id] = (ProtectTries[Chicken.id] or 0) + 1

            -- the remote answers { ok = true, data = ... }, so this goes
            -- through Ask like every other request and a refusal earns the
            -- ordinary backoff. Whether it actually took is still read off the
            -- roster on the next pass, by the favorite check above.
            Claimed(string.format("favourited %s %s (%s) -- kept for the champion",
                RarityOf(Chicken), tostring(Chicken.nickname or Chicken.typeId), Mutation),
                Ask(Remotes.defs.SetChickenFavorite, Chicken.id, true))

            return true
        end
    end

    return false
end)
end

--// fusion
do
local FuseTriedAt = 0

Task("fuse", "chicken", function()
    -- no rarity finish line: a better champion is worth having on the last
    -- rebirth as much as on the first, and after it as well
    if os.clock() - FuseTriedAt < 3 then return false end

    local Roster = GetRoster()

    if not Roster then
        FuseWantsCorral = false

        return false
    end

    local A, B, Kind = PlanFusion(Roster)

    if not (A and B) then
        FuseWantsCorral = false

        return false
    end

    local Cost = FuseCost(A, B)

    if Cost and not CanAfford(Cost) then
        FuseWantsCorral = false

        return false
    end

    -- fusing a chicken that is out on the plot is refused unless it is home,
    -- and the active one is the champion, so the recall has to happen first
    local NeedsCorral = (A.id == Roster.activeId) or (B.id == Roster.activeId)

    if NeedsCorral then
        FuseWantsCorral = true

        if not ChickenAtCoop() then
            if ChickenClaim("fuse") then
                if TowerActive() then
                    Remotes.fire(Remotes.defs.SetChickenOrder, "coop")
                    Remotes.invoke(Remotes.defs.TowerSurrender)

                    return true
                end

                RecallChicken()

                return true
            end

            return false
        end
    end

    FuseTriedAt = os.clock()

    local Reply = Ask(Remotes.defs.FuseChickens, A.id, B.id, BuildLocks(A, B), nil, "a")

    FuseWantsCorral = false

    if type(Reply) == "table" and Reply.ok and type(Reply.data) == "table" then
        Log(string.format("fused %s %s + %s%s",
            Kind == "champion" and "champion" or "fodder",
            RarityOf(A), RarityOf(B),
            Reply.data.ascended and "  ->  " .. tostring(Reply.data.rarity) .. " ASCENDED" or ""))
    end

    return true
end)
end

--// who stands on the plot
--
-- The best chicken in the bag, by rarity, tie-broken by what it lays. It sits
-- there doing both of the plot's jobs at once: laying the eggs the next
-- chicken comes out of, and taking the pit fights that turn its own level one
-- into something. See Hunt.Layer for why rarity and not power decides it.
--
-- A tower run does not take whoever is standing here. The tower borrows the
-- plot for its own pick -- the hardest hitter, Hunt.Fighter -- and gives it
-- back when the run ends, so nothing about this costs a floor.
do
local ActiveAt = 0

Task("active", "chicken", function()
    if os.clock() - ActiveAt < 10 then return false end

    local Roster = GetRoster()

    if not Roster then return false end

    local Champion = ChampionOf(Roster)

    if not Champion then return false end
    if TowerActive() then return false end

    -- the tower has the plot: a run is being lined up and the champion is
    -- walking out to it, so nothing swaps until it is done
    if Hunt.Held() then return false end

    local Want = Hunt.Layer(Roster) or Champion

    if Want.id == Roster.activeId then return false end

    ActiveAt = os.clock()

    local Note = Want == Champion
        and ("champion set to " .. tostring(Champion.nickname or Champion.typeId))
        or string.format("laying %s with %s",
            Hunt.Name(Hunt.Target(Roster)), tostring(Want.nickname or Want.typeId))

    if Claimed(Note, Ask(Remotes.defs.SetActiveChicken, Want.id)) then
        -- favourited so nothing downstream can sell or fuse it away by
        -- accident. The champion keeps its own mark whichever one is standing
        -- out there, because the fuse planner still builds around it.
        Remotes.invoke(Remotes.defs.SetChickenFavorite, Want.id, true)

        if Want.id ~= Champion.id then
            Remotes.invoke(Remotes.defs.SetChickenFavorite, Champion.id, true)
        end
    end

    return true
end)
end

--// economy
--
-- A rebirth resets level, money and the coop. Anything spent on the plot while
-- one is already available is spent on something that is about to be deleted,
-- so the coop tasks stand down until the rebirth has been taken. The recycler
-- is not part of that: its level survives, and its cap is what rises with the
-- rebirth count, so it keeps going.
Task("buyfeeder", "economy", function()
    if RebirthPending() then return false end

    local Coop = GetCoop()

    if not Coop then return false end

    local Feeders = #Coop.generators

    if Feeders >= Config.Build.CoopSlots then return false end
    if not CoopView.canBuyGenerator(Coop.slots, Feeders) then return false end
    if not CanAfford(CoopView.buyGeneratorCost(Feeders)) then return false end

    if Claimed("bought feeder " .. (Feeders + 1), Ask(Remotes.defs.BuyGenerator, Feeders + 1)) then
        return true
    end

    return true
end)

Task("expandcoop", "economy", function()
    if RebirthPending() then return false end

    local Coop = GetCoop()

    if not Coop then return false end
    if not CoopView.canExpand(Coop.slots) then return false end
    if not CanAfford(CoopView.expandCost(Coop.slots)) then return false end

    Claimed("coop expanded", Ask(Remotes.defs.ExpandCoop))

    return true
end)

Task("upgradefeeder", "economy", function()
    if RebirthPending() then return false end

    local Coop = GetCoop()

    if not Coop then return false end

    -- the CHEAPEST upgradable feeder, not the first in the list: feeder levels
    -- drift far apart, and "first in the list" means every pass prices the most
    -- expensive one on the plot, cannot pay, and nothing is ever upgraded
    local Wanted, WantedCost

    for _, Generator in ipairs(Coop.generators) do
        local Slot = tonumber(Generator.slot)
        local Level = tonumber(Generator.level) or 1

        if Slot and Level < Config.Build.FeederLevel and CoopView.canUpgrade(Level) then
            local Cost = CoopView.upgradeCost(Level)

            if type(Cost) ~= "number" then
                Cost = math.huge
            end

            if not WantedCost or Cost < WantedCost then
                Wanted = Slot
                WantedCost = Cost
            end
        end
    end

    if not Wanted then return false end
    if not CanAfford(WantedCost) then return false end

    Ask(Remotes.defs.UpgradeGenerator, Wanted)

    return true
end)

-- Installing the recycler is the first thing money is spent on after a
-- rebirth, and it is a different job from upgrading it.
--
-- A rebirth leaves the account with almost nothing -- fifty-odd money, two coop
-- slots, and a recycler that has to be put back. Until it is back, scrap cannot
-- be deposited at all, which means the run has no income and cannot afford the
-- feeders it would otherwise be queueing up to buy. Installing costs
-- scrap.recycler.installCost, which is four; the first feeder costs orders of
-- magnitude more. So this goes ahead of every other purchase and is over with
-- in one pass.
--
-- Upgrading past level one is the ordinary economy job it always was and stays
-- at the bottom of the order, because each step costs upgradeCost.base 75
-- growing at 1.55 and is gated behind a tower floor the run has to climb for.
Task("installrecycler", "economy", function()
    if not Config.Scrap then return false end
    if Parked() then return false end
    if RecyclerLevel() >= 1 then return false end

    if LocalPlayer:GetAttribute(RecyclerView.LockedAttr) == true then return false end
    if LocalPlayer:GetAttribute(RecyclerView.BusyAttr) == true then return false end
    if not CanAfford(RecyclerView.upgradeCost(0)) then return false end

    return Claimed("recycler installed", Ask(Remotes.defs.UpgradeRecycler))
end)

Task("recycler", "economy", function()
    if not Config.Scrap then return false end

    -- the recycler is where scrap is carried, and the scrap run stops with the
    -- last rebirth, so upgrading it past that buys nothing
    if Parked() then return false end

    local Level = RecyclerLevel()

    -- level zero is the install, which has its own task above and its own place
    -- in the order; this one only ever climbs
    if Level < 1 then return false end
    if Level >= Config.Build.RecyclerLevel then return false end

    if LocalPlayer:GetAttribute(RecyclerView.LockedAttr) == true then return false end
    if LocalPlayer:GetAttribute(RecyclerView.BusyAttr) == true then return false end
    if not RecyclerView.canUpgrade(Level, RebirthCount()) then return false end
    if not RecyclerView.floorUnlocked(Level, TowerBest()) then return false end
    if not CanAfford(RecyclerView.upgradeCost(Level)) then return false end

    if Claimed("recycler -> level " .. (Level + 1), Ask(Remotes.defs.UpgradeRecycler)) then
        return true
    end

    return true
end)

--// incubator, once rebirth 3 unlocks it
do
local IncubatorAt = 0

Task("incubator", "economy", function()
    if not Config.Incubator then return false end

    local Unlock = GameConfig.incubator and GameConfig.incubator.unlockRebirth or 3

    if RebirthCount() < Unlock then return false end

    -- the claim is a poll: whether anything has finished is not something the
    -- client's own table says plainly, so it is asked for on a slow timer
    -- rather than every pass
    if os.clock() - IncubatorAt < 60 then return false end

    IncubatorAt = os.clock()

    local State = GetData("incubator")

    if type(State) ~= "table" then return false end

    local Level = tonumber(State.level) or 0

    if Level < 1 then
        local Cost = (GameConfig.incubator.costBase or 300000)

        if not CanAfford(Cost) then return false end

        Claimed("incubator bought", Ask(Remotes.defs.IncubatorUpgrade))

        return true
    end

    -- anything finished is collected; a free slot is filled with the worst
    -- chicken on the roster, which is the one fusion is least likely to want
    local Reply = Ask(Remotes.defs.IncubatorClaim)

    if type(Reply) == "table" and Reply.ok then
        Log("incubator claimed")

        return true
    end

    local Roster = GetRoster()

    if not Roster then return false end

    local Champion = ChampionOf(Roster)
    local Worst, WorstScore

    for _, Chicken in ipairs(Chickens(Roster)) do
        -- the mutation guard is here as well as on the favourite, because the
        -- favourite is set by a task that may not have had its pass yet: a
        -- mutation hatched thirty seconds ago is still unmarked, and this is
        -- the one other place in the file that gives a chicken away
        if Chicken.id ~= Roster.activeId
            and Chicken.favorite ~= true
            and not MutationOf(Chicken)
            and (not Champion or Chicken.id ~= Champion.id)
            and (not Champion or GeneGain(Champion, Chicken) == 0) then
            local Score = KeepScore(Chicken)

            if not WorstScore or Score < WorstScore then
                Worst = Chicken
                WorstScore = Score
            end
        end
    end

    if not Worst then return false end

    Ask(Remotes.defs.IncubatorInsert, Worst.id)

    return true
end)
end

--// tower
do
local ElevatorCatalog = Modules.ElevatorCatalog
local ElevatorRescanAt = 0

local function ElevatorCost(Floor, Best)
    if not ElevatorCatalog and os.clock() >= ElevatorRescanAt then
        ElevatorRescanAt = os.clock() + 30

        ScanGarbage(function(Value)
            if type(rawget(Value, "elevatorCost")) == "function" then
                ElevatorCatalog = Value

                return true
            end
        end)
    end

    if not ElevatorCatalog then return end

    local Purchases = GetData("purchases")
    local Passes = type(Purchases) == "table" and Purchases.passes or nil

    local Ok, Cost = pcall(ElevatorCatalog.elevatorCost, {
        restricted = true,
        prices = { },
        towerBest = Best,
        rewardFloor = Best,
        owned = { elevatorVip = type(Passes) == "table" and Passes.elevatorVip == true },
        boosts = { money = 0, corn = 0 }
    }, Floor)

    return Ok and tonumber(Cost) or nil
end

-- the highest floor the elevator can be paid for, so a run starts where the
-- money actually is instead of walking up from the bottom every time
local function ElevatorFloor()
    local Best = TowerBest()
    local MinFloor = GameConfig.premium.elevator.minFloor or 2
    local Money = GetMoney()

    for Floor = Best + 1, MinFloor, -1 do
        local Cost = ElevatorCost(Floor, Best)

        if not Cost then return end

        if Cost <= Money then return Floor end
    end
end

local TowerStartedAt = 0
local TowerStartGrace = 12
local TowerPending = false
local TowerMinHealth = 0.8

Task("tower", "tower", function()
    if Parked() then return false end
    if not ChickenClaim("tower") then return false end

    local Arena = MyArena()

    if not Arena then
        TowerBlocked = true

        return false
    end

    local Body = MyChickenBody()

    if not Body then return false end

    local State = ChickenStateOf(Body)

    if Arena:GetAttribute("TowerActive") == true or State == "campaign" then
        TowerPending = false
        TowerBlocked = false

        return false
    end

    if TowerPending and os.clock() - TowerStartedAt > TowerStartGrace then
        TowerPending = false
        TowerBlocked = true
    end

    if os.clock() - TowerStartedAt < (TowerBlocked and 30 or TowerStartGrace) then return false end

    if State == "pit" then
        Remotes.fire(Remotes.defs.SetChickenOrder, "coop")

        return true
    end

    if (Body:GetAttribute("ovHpFrac") or 1) < TowerMinHealth then return false end

    -- Whoever is standing on the plot is who goes up, and while the run is
    -- hunting eggs that is the layer rather than the champion. The champion is
    -- put back out first and the run waits a pass for the swap to land, so the
    -- egg hunting never costs a floor.
    do
        local Roster = GetRoster()
        local Fighter = Roster and Hunt.Fighter(Roster)

        if Fighter and Roster.activeId ~= Fighter.id then
            if not Hunt.Held() then
                Hunt.Hold(45)

                if Claimed("champion sent up the tower", Ask(Remotes.defs.SetActiveChicken, Fighter.id)) then
                    Remotes.invoke(Remotes.defs.SetChickenFavorite, Fighter.id, true)
                end
            end

            return true
        end
    end

    TowerStartedAt = os.clock()
    TowerPending = true

    local Floor = ElevatorFloor()

    if Floor and Floor >= (GameConfig.premium.elevator.minFloor or 2) then
        Ask(Remotes.defs.TowerElevator, Floor)
    end

    Ask(Remotes.defs.TowerStart)

    return true
end)
end

--// rebirth
do
local RebirthTriedAt = 0
local RebirthGap = 5
local RebirthSaid = nil

Task("rebirth", "rebirth", function()
    if not ChickenClaim("rebirth") then
        RebirthState.Why = "the " .. tostring(ChickenOwner() or "?") .. " job has the chicken"

        return false
    end

    local Body = MyChickenBody()

    if not Body then
        RebirthState.Why = "no chicken body in the world yet"

        return false
    end

    -- a run in progress keeps the chicken in the arena, so it is given up first
    if TowerActive() then
        RebirthState.Why = "giving up the tower run first"

        if os.clock() - RecallAt >= RecallWalkHome then
            RecallAt = os.clock()

            if Remotes.fire(Remotes.defs.SetChickenOrder, "coop") then
                RecallOrderedAt = os.clock()
            end

            Remotes.invoke(Remotes.defs.TowerSurrender)
        end

        return true
    end

    -- Home AND under a coop order, which is what the game's own atCoop asks
    -- for. Either half missing means the order goes out and the next pass
    -- looks again.
    if not ChickenAtCoop() then
        local Mode = Modules.ChickenMode
        local Ok, Order = pcall(function()
            return Mode and Mode.order()
        end)

        RebirthState.Why = string.format("chicken is %s under order %s, needs corral under coop",
            tostring(ChickenStateOf(Body)),
            tostring((Ok and Order) or "?"))

        RecallChicken()

        return true
    end

    -- Keep asking until the count moves.
    --
    -- A single shot was tried and it did not land: the call goes out, the
    -- server does not take it, and the run then sat on its hands. So this
    -- retries, on its own fixed spacing, for as long as the rebirth is
    -- available and the chicken is where it has to be. The count going up is
    -- the only thing that stops it.
    --
    -- Two deliberate departures from how every other request in this file is
    -- sent:
    --
    --   * Remotes.invoke, not Ask. Ask answers a refusal with a doubling
    --     backoff that reaches two minutes, which is the right shape for a
    --     request that is wrong and will stay wrong. A rebirth refusal is
    --     usually the opposite -- the server's copy of the standing order has
    --     not caught up with the client's yet -- and it clears on its own in
    --     seconds. Backing off two minutes from a condition that fixes itself
    --     in three is how the run ended up stuck.
    --
    --   * RebirthGap, not one attempt. Five seconds is slower than a player
    --     clicking the button, and the send budget still holds any two calls
    --     to the same remote 1.5s apart underneath it, so the ceiling is the
    --     budget's and not this loop's.
    if os.clock() - RebirthTriedAt < RebirthGap then
        RebirthState.Why = string.format("trying again in %.0fs",
            RebirthGap - (os.clock() - RebirthTriedAt))

        return false
    end

    RebirthTriedAt = os.clock()

    local Roster = GetRoster()
    local Champion = Roster and ChampionOf(Roster)
    local Level = Champion and (Champion.level or 1) or 1

    local Reply = Remotes.invoke(Remotes.defs.Rebirth)

    if type(Reply) == "table" and Reply.ok then
        RecallOrderedAt = 0
        RecallAt = 0
        RebirthSaid = nil
        RebirthState.Why = "just rebirthed"

        Log(string.format("rebirth %d at level %d  (+%d points)",
            RebirthCount(), Level, RebirthBonus.pointsFor(Level)))
    elseif type(Reply) == "table" and Reply.error then
        RebirthState.Why = "server refused: " .. tostring(Reply.error) .. ", retrying"

        -- warned once per distinct reason. The retry is deliberate, so a
        -- console line every five seconds saying the same thing is noise; a
        -- line the first time each new reason appears is not.
        if RebirthSaid ~= Reply.error then
            RebirthSaid = Reply.error

            warn("[ValkyrieHub] rebirth refused: " .. tostring(Reply.error) .. " -- still trying")
        end
    else
        -- invoke hands back nil only when the send budget swallowed the call,
        -- which is a wait rather than a refusal: nothing reached the server
        RebirthState.Why = "request held by the send budget, retrying"
    end

    return true
end)
end

--// event windows
do
local PitSentAt = 0

Task("event", "event", function()
    if not Config.Events then return false end
    if not ChickenClaim("event") then return false end

    local Body = MyChickenBody()

    if not Body then return false end

    if TowerActive() then
        if os.clock() - PitSentAt >= 6 then
            PitSentAt = os.clock()

            Remotes.fire(Remotes.defs.SetChickenOrder, "coop")
            Remotes.invoke(Remotes.defs.TowerSurrender)
        end

        return true
    end

    local State = ChickenStateOf(Body)

    if State == "pit" or State == "campaign" then return false end

    local MinHealth = GameConfig.chicken.recovery.minHealth or 0.2

    if (Body:GetAttribute("ovHpFrac") or 1) < MinHealth then return false end
    if os.clock() - PitSentAt < 6 then return false end

    PitSentAt = os.clock()

    Remotes.fire(Remotes.defs.SetChickenOrder, "chaos")

    return true
end)
end

do
local EncouragedAt = 0

Task("encourage", "event", function()
    if not Config.Events then return false end

    local Body = MyChickenBody()

    if not Body or ChickenStateOf(Body) ~= "pit" then return false end

    -- cheering happens at the pit; from across the map it is a call the player
    -- could not have made, so it is skipped rather than walked to
    local Root = GetRootPart()

    if not Root then return false end

    local Flat = Root.Position - PitZone.center

    if Vector3.new(Flat.X, 0, Flat.Z).Magnitude > PitZone.radius then return false end
    if os.clock() - EncouragedAt < (GameConfig.pit.encourage.cooldown or 15) then return false end

    EncouragedAt = os.clock()

    Ask(Remotes.defs.EncourageChicken)

    return true
end)
end

---- ============ Walking jobs ============ ----

-- Nothing below sends a remote. Eggs are taken by the server on proximity and
-- scrap is picked up by touching it, so all of this is MoveTo -- the same thing
-- a player walking does, replicated the same way. The old build fired
-- firetouchinterest at every nest egg in reach instead, which won nothing (the
-- eggs are not collected by touch) and looked exactly like what an anti-cheat
-- is written to spot.

-- Avoid is a position, usually a chicken mid-fight, and AvoidRadius is how wide
-- a berth to give it: a piece lying under a fighting chicken is not worth the
-- half load a knockout takes off.
local function NearestStack(Origin, Wanted, Avoid, AvoidRadius)
    local Folder = workspace:FindFirstChild("PitScrap")

    if not Folder then return end

    local Mine = "player:" .. LocalPlayer.UserId
    local Best, BestDistance

    for _, Piece in ipairs(Folder:GetChildren()) do
        if Piece:IsA("BasePart") then
            local Kind = Piece:GetAttribute("StackKind")
            local Owner = Piece:GetAttribute("DropOwner")

            if Kind and (Wanted == nil or Wanted[Kind]) and (Owner == nil or Owner == Mine) then
                local Clear = true

                if Avoid and (Piece.Position - Avoid).Magnitude <= (AvoidRadius or 0) then
                    Clear = false
                end

                if Clear then
                    local Distance = (Piece.Position - Origin).Magnitude

                    if not BestDistance or Distance < BestDistance then
                        Best = Piece
                        BestDistance = Distance
                    end
                end
            end
        end
    end

    return Best
end

local function MyRecycler()
    local Folder = workspace:FindFirstChild("Recyclers")
    local Plot = LocalPlayer:GetAttribute("Plot")

    if not (Folder and Plot) then return end

    local Model = Folder:FindFirstChild("Recycler" .. tostring(Plot))

    if not Model then return end

    return Model.PrimaryPart or Model:FindFirstChildWhichIsA("BasePart", true)
end

local function CarriedPieces()
    return LocalPlayer:GetAttribute("scrapCarry") or 0
end

-- The two of them behind one block, with the clock they share inside it. This
-- chunk runs close to Luau's ceiling of two hundred active locals per function,
-- and nothing outside these two ever reads either value.
local TrackPickup, PickupReady

do

local LastCarry = nil
local LastPickupAt = 0

function TrackPickup(Carry)
    if LastCarry and Carry > LastCarry then
        LastPickupAt = os.clock()
    end

    LastCarry = Carry
end

-- the server's own travel guard counts how far a piece moved between pickups,
-- so a far stack is only walked to once the last pickup has settled
function PickupReady(Distance)
    if Distance <= (ScrapTravel.tolerance or 12) then
        return true
    end

    return os.clock() - LastPickupAt >= 0.1
end

end

-- The UFO sheds an egg pod every worldEvents.defs.ufo.eggEvery seconds, 22 of
-- them, into the same PitScrap folder it is shedding hull and circuit and core
-- into by the dozen. NearestStack takes the nearest of whatever it is given, so
-- one list containing all of it meant the pod was reached only when it happened
-- to land closest -- and it rarely does, because the scrap outnumbers it
-- roughly twenty to one.
--
-- A pod is a whole egg. The rest is scrap, which is money, and money is the one
-- thing the run is never short of once the rebirth multiplier is up. So the pod
-- goes first and the scrap is what is collected while there is no pod out.
local EggDropKinds = { eggPod = true }
local EventDropKinds = { tradeOre = true, meteorRock = true, ufoPart = true, goldCoin = true, eggPod = true }

local function HotEgg()
    local Egg = workspace:FindFirstChild("HotEgg")

    if Egg and Egg:IsA("BasePart") then
        return Egg
    end
end

local function HotEggBusy()
    return Config.Events and HotEgg() ~= nil
end

local function DodgePoint(Position)
    local Offset = Position - PitZone.center
    local Flat = Vector3.new(Offset.X, 0, Offset.Z)
    local Radius = math.clamp(Flat.Magnitude, 8, PitZone.radius - 8)
    local Angle = math.atan2(Offset.Z, Offset.X) + 0.7

    return PitZone.center + Vector3.new(math.cos(Angle) * Radius, Position.Y - PitZone.center.Y, math.sin(Angle) * Radius)
end

local Running = { }

local Startup = { At = os.clock(), Grace = 5, Stagger = 0.4, Slot = 0 }

-- every loop restored at boot used to fire its first pass on the same tick,
-- and that spike right after execute is what gets the kick. Each loop takes its
-- own slot after the grace instead, and a little jitter per pass keeps loops
-- that share a delay from drifting back into phase minutes later.
local function Loop(Key, Delay, Step)
    if Running[Key] then return end

    Running[Key] = true

    Startup.Slot = Startup.Slot + 1

    local Slot = Startup.Slot

    task.spawn(function()
        local Remaining = Startup.Grace + Slot * Startup.Stagger - (os.clock() - Startup.At)

        if Remaining > 0 then
            task.wait(Remaining)
        end

        while getgenv().ValkyrieSession == SessionToken do
            pcall(Step)

            task.wait(Delay + math.random() * math.min(Delay * 0.25, 0.5))
        end

        Running[Key] = nil
    end)
end

--// tutorial: the three steps that are finished by standing somewhere
do
local WalkAnchor = nil
local WalkFlip = false
local WalkFlipAt = 0

Loop("tutorial", 0.3, function()
    local Step = OnboardingStep()

    if not Step then
        WalkAnchor = nil

        return
    end

    local Root = GetRootPart()

    if not Root then return end

    if Step == "scrap" then
        local Target = TrialTarget()

        if Target then
            WalkTo("tutorial", Target, 1)
        end

        return
    end

    if Step == "deposit" then
        local Recycler = MyRecycler()

        if Recycler then
            WalkTo("tutorial", Recycler.Position, 1)
        end

        return
    end

    -- the follow step is finished by walking the studs the config asks for
    -- (onboarding.walkStuds, 25) with the chicken in tow, so the character
    -- paces between two points that far apart until the server says done
    if Step == "follow" then
        local Body = MyChickenBody()

        if not Body or ChickenStateOf(Body) ~= "hub" then
            WalkAnchor = nil

            return
        end

        local Studs = (GameConfig.onboarding and GameConfig.onboarding.walkStuds or 25) + 6

        if not WalkAnchor then
            WalkAnchor = Root.Position
            WalkFlip = false
            WalkFlipAt = 0
        end

        local Angle = math.pi * 0.25
        local Away = WalkAnchor + Vector3.new(math.cos(Angle), 0, math.sin(Angle)) * Studs
        local Target = WalkFlip and WalkAnchor or Away

        if (Root.Position - Target).Magnitude < 6 and os.clock() - WalkFlipAt > 1 then
            WalkFlip = not WalkFlip
            WalkFlipAt = os.clock()
        end

        WalkTo("tutorial", Target, 1)
    end
end)
end

--// hot egg: carry it away from the pit, or chase it
Loop("hotegg", 0.25, function()
    if not Config.Events then return end

    local Egg = HotEgg()

    if not Egg then return end

    local Root = GetRootPart()

    if not Root then return end

    if Egg:GetAttribute("Carrier") == LocalPlayer.UserId then
        WalkTo("hotegg", DodgePoint(Root.Position), 1)
    else
        WalkTo("hotegg", Egg.Position, 1)
    end
end)

--// event drops
Loop("eventdrops", 0.25, function()
    if not Config.Events then return end
    if not EventLive() then return end
    if HotEggBusy() then return end

    local Root = GetRootPart()

    if not Root then return end

    local Carry = CarriedPieces()

    TrackPickup(Carry)

    local Threat, ThreatDistance, ThreatReach = PitThreat(Root.Position)
    local Danger = Threat ~= nil and ThreatDistance <= ThreatReach
    local Target

    -- event drops are one at a time anyway, so a fight only decides how fast
    -- the run home is and which pieces are worth going for
    if Carry > 0 then
        Target = MyRecycler()
    else
        -- an egg pod anywhere beats scrap underfoot, so the pods are asked for
        -- on their own first and the rest of the drops only answer when there
        -- is no pod on the floor at all
        Target = NearestStack(Root.Position, EggDropKinds,
            Threat and Threat.Position or nil, ThreatReach)
            or NearestStack(Root.Position, EventDropKinds,
                Threat and Threat.Position or nil, ThreatReach)

        if Target and not PickupReady((Target.Position - Root.Position).Magnitude) then
            return
        end
    end

    if not Target then return end

    WalkTo("event", Target.Position, 1, Danger and Config.Speed.Escape or Config.Speed.Collect)
end)

--// scrap
Loop("scrap", 0.25, function()
    if not Config.Scrap then return end
    if HotEggBusy() then return end

    -- scrap is money and money is only ever spent on the plot the tower and the
    -- rebirth needed. With the last rebirth taken there is nothing left to buy,
    -- so the run stops carrying and stays out of the pit.
    if Parked() then return end

    local Root = GetRootPart()

    if not Root then return end

    local Carry = CarriedPieces()
    local PieceCap = 6

    TrackPickup(Carry)

    local Threat, ThreatDistance, ThreatReach = PitThreat(Root.Position)
    local Danger = Threat ~= nil and ThreatDistance <= ThreatReach

    local Target
    local Speed = Config.Speed.Collect

    -- A fight changes the trip, not the errand. A knockout costs
    -- scrap.stealPct -- half of whatever is being held -- so once a chicken is
    -- in range, what is already carried is worth more banked than topped up.
    if Danger and Carry > 0 then
        Target = MyRecycler()
        Speed = Config.Speed.Escape
    elseif Carry >= PieceCap then
        Target = MyRecycler()
    else
        -- empty handed with a fight on: still worth grabbing, but only what is
        -- lying clear of the chicken
        Target = NearestStack(Root.Position, nil,
            Threat and Threat.Position or nil, ThreatReach)

        if Danger then
            Speed = Config.Speed.Escape
        end

        if Target and not PickupReady((Target.Position - Root.Position).Magnitude) then
            return
        end
    end

    -- nothing safe to reach and nothing to bank: back off rather than stand
    -- inside the chicken's reach waiting for the next spawn
    if not Target then
        if Danger then
            local Away = Root.Position - Threat.Position
            local Flat = Vector3.new(Away.X, 0, Away.Z)

            if Flat.Magnitude > 0.1 then
                -- out to the far edge of whatever is chasing, not a fixed step:
                -- fourteen studs is clear of a chicken and still inside the
                -- boss's slam circle
                WalkTo("scrap", Root.Position + Flat.Unit * (ThreatReach + 4), 1, Config.Speed.Escape)
            end
        end

        return
    end

    WalkTo("scrap", Target.Position, 1, Speed)
end)

--// boss attacks
--
-- The boss telegraphs. Remotes.BossAttack arrives on the client with
-- { phase = "telegraph", kind, data } a beat before the hit lands, carrying the
-- exact ground the attack is about to cover -- the same payload the game's own
-- ChickenBossController uses to draw the warning decal on the floor. So this
-- does not have to guess or keep a nervous distance: it reads where the hit is
-- going and steps out of that, and only that.
--
--   skySlam       data.at, a point. ChickenBoss.attacks.skySlam.radius is 26
--                 and it knocks the player for playerKnock 30 with a second of
--                 daze, which is a second of standing still inside a fight.
--   eggThrow      data.targets, a list of points, splashing radius 10 each.
--   roosterCharge data.from and data.to, a lane roughly width 9 wide. Stepping
--                 sideways clears it; running down it does not.
--
-- The dodge takes the walk claim at hotegg's level, which outranks scrap and
-- the ordinary event drops and yields to the tutorial. It lasts as long as the
-- attack's own telegraph window and then lets go, so nothing is held.
do
local Slam, Egg, Charge = 26, 10, 9

do
    for _, Value in ipairs(getgc(true)) do
        if type(Value) == "table"
            and type(rawget(Value, "attacks")) == "table"
            and type(rawget(Value, "tierFor")) == "function" then
            local A = Value.attacks

            Slam = (type(A.skySlam) == "table" and tonumber(A.skySlam.radius)) or Slam
            Egg = (type(A.eggThrow) == "table" and tonumber(A.eggThrow.radius)) or Egg
            Charge = (type(A.roosterCharge) == "table" and tonumber(A.roosterCharge.width)) or Charge

            break
        end
    end
end

local function Point(Value)
    if typeof(Value) == "Vector3" then return Value end
    if typeof(Value) == "CFrame" then return Value.Position end
end

-- Where to stand instead. Away is the direction out of the hit, and the walk
-- goes a little past the edge rather than to it: the run is still moving when
-- the strike lands, and the edge is where the strike still reaches.
local function StepClear(Root, Away, Distance)
    local Flat = Vector3.new(Away.X, 0, Away.Z)

    if Flat.Magnitude < 0.1 then
        -- standing exactly on the mark, so any direction will do
        local Angle = math.random() * math.pi * 2

        Flat = Vector3.new(math.cos(Angle), 0, math.sin(Angle))
    end

    WalkTo("hotegg", Root.Position + Flat.Unit * Distance, 1.5, Config.Speed.Escape)
end

TrackConnection(Remotes.onClient("BossAttack", function(Payload)
    if not Config.Events then return end
    if type(Payload) ~= "table" or Payload.phase ~= "telegraph" then return end

    local Root = GetRootPart()

    if not Root then return end

    local Data = type(Payload.data) == "table" and Payload.data or { }
    local Here = Root.Position

    if Payload.kind == "skySlam" then
        local At = Point(Data.at)

        if not At then return end

        local Away = Here - At

        if Vector3.new(Away.X, 0, Away.Z).Magnitude > Slam then return end

        Log("boss sky slam incoming; stepping out of the circle")
        StepClear(Root, Away, Slam + 6)

        return
    end

    if Payload.kind == "eggThrow" then
        -- five eggs, and only the one aimed nearest matters: they are far
        -- enough apart that clearing the closest clears the throw
        local Near, NearDistance

        for _, Target in pairs(Data.targets or { }) do
            local At = Point(Target)

            if At then
                local Offset = Here - At
                local Distance = Vector3.new(Offset.X, 0, Offset.Z).Magnitude

                if Distance <= Egg and (not NearDistance or Distance < NearDistance) then
                    Near, NearDistance = At, Distance
                end
            end
        end

        if not Near then return end

        Log("boss egg throw incoming; stepping off the splash")
        StepClear(Root, Here - Near, Egg + 5)

        return
    end

    if Payload.kind == "roosterCharge" then
        local From, To = Point(Data.from), Point(Data.to)

        if not (From and To) then return end

        local Lane = Vector3.new(To.X - From.X, 0, To.Z - From.Z)

        if Lane.Magnitude < 0.1 then return end

        local Direction = Lane.Unit
        local Offset = Vector3.new(Here.X - From.X, 0, Here.Z - From.Z)
        local Along = Offset:Dot(Direction)

        -- behind the start or past the end is already clear of it
        if Along < -Charge or Along > Lane.Magnitude + Charge then return end

        local Sideways = Offset - Direction * Along

        if Sideways.Magnitude > Charge then return end

        -- out of the lane at a right angle, which is the short way off it;
        -- running ahead of a 70 stud per second charge is not
        local Side = Vector3.new(-Direction.Z, 0, Direction.X)

        if Sideways:Dot(Side) < 0 then
            Side = -Side
        end

        Log("boss charge incoming; stepping out of the lane")
        StepClear(Root, Side, Charge + 6)
    end
end))
end

--// nest eggs
-- The one loop that must never stop. Everything the account is worth after
-- the last rebirth arrives through here: the chicken lays, this walks to what
-- it laid, and the hatch task opens it. It carried a Done guard when Done meant
-- the run had finished, which turned a finished account into an idle one.
Loop("eggs", 0.4, function()
    if HotEggBusy() then return end

    local Root = GetRootPart()
    local Folder = workspace:FindFirstChild("NestEggs")

    if not (Root and Folder) then return end

    local Best, BestDistance

    for _, Egg in ipairs(Folder:GetChildren()) do
        if Egg:IsA("BasePart") and Egg:GetAttribute("owner") == LocalPlayer.UserId then
            local Distance = (Egg.Position - Root.Position).Magnitude

            if not BestDistance or Distance < BestDistance then
                Best = Egg
                BestDistance = Distance
            end
        end
    end

    -- already standing on it: the server hands it over on its own tick
    if not Best or BestDistance <= 3 then return end

    WalkTo("egg", Best.Position, 1)
end)

---- ============ Worker ============ ----

-- One thread owns every remote-sending job. The list is walked in order and the
-- first task that reports it did something ends the pass, so the run can never
-- send two things in one tick no matter how many are eligible.

local PhaseNames = {
    boot     = "boot",
    tutorial = "doing the tutorial",
    rewards  = "collecting rewards",
    chicken  = "building the chicken",
    economy  = "building the plot",
    tower    = "climbing the tower",
    rebirth  = "rebirthing",
    event    = "world event",
    arena    = "fighting in the arena",
}

-- Registration order is not run order. A pass stops at the first task that did
-- something, so anything cheap and always-available -- upgrading a feeder, say,
-- which is affordable on almost every pass once the money multiplier is up --
-- would starve everything under it forever. Time-critical work is therefore
-- ordered first: an event window closes on its own, a rebirth that is ready is
-- holding the chicken hostage, and a tower run is what raises the level the
-- rebirth is waiting for. The plot can always be built one pass later.
do
    local Order = {
        -- A rebirth that is available is checked before anything else.
        --
        -- It is the one thing in the run with compounding interest: every
        -- rebirth is a permanent +15% on money, the multiplier pays for
        -- everything after it, and tower.best is not reset -- so the floor
        -- that made this one possible has already paid for the next several.
        -- Every pass spent elsewhere while one is sitting available is a pass
        -- spent earning at the old rate.
        --
        -- Nothing is lost by putting it first. The task opens with
        -- ChickenClaim("rebirth"), and that ladder still puts the tutorial
        -- above it, so an onboarding account falls straight through to the
        -- tutorial task below. It could not fire there anyway: a rebirth needs
        -- tower floor 25 and the tutorial ends around floor 1.
        rebirth = 0,
        tutorial = 1,
        codes = 2,
        event = 3, encourage = 4,
        tower = 5,
        -- selling comes before hatching on purpose: freeing the slot has to
        -- happen before the hatch that needs it, or the pass is spent on a
        -- request the server answers with roster-full. Marking a mutation goes
        -- ahead of the selling for the same reason in reverse: the mark has to
        -- be on the server before a batch of ids is built that might have
        -- contained it.
        fuse = 6, active = 7, protect = 8, sell = 9, hatch = 10,
        daily = 11, missions = 12, pass = 13, social = 14, milestone = 15,
        -- The arena sits above the plot rather than below it. It throttles
        -- itself -- a battle it starts owns the next minute, and the view it
        -- reads is only refreshed every half minute -- so it cannot starve
        -- anything, while a feeder queued above it would be affordable on
        -- almost every pass and would starve the arena instead.
        arena = 16,
        -- the recycler goes back in before anything else is bought. It costs
        -- four, and until it is back the scrap run has nowhere to deposit, so
        -- every feeder queued ahead of it would be bought with money that the
        -- recycler is what earns.
        installrecycler = 17,
        buyfeeder = 18, expandcoop = 19, upgradefeeder = 20,
        recycler = 21, incubator = 22,
    }

    table.sort(Tasks, function(Left, Right)
        return (Order[Left.Name] or 99) < (Order[Right.Name] or 99)
    end)
end

-- An available rebirth does not merely go first, it takes the whole pass.
--
-- Being first in the order is only worth anything on the passes where the
-- rebirth task returns true. It returns false while it is inside its own retry
-- cooldown, and on those passes everything under it used to run -- feeders
-- bought with money the rebirth is about to delete, a tower run started with a
-- chicken that is supposed to be walking home. So while one is available the
-- other tasks are not asked at all.
--
-- The hold is not unconditional, because a rebirth the server keeps refusing
-- would otherwise freeze the entire run for good. It holds for RebirthHold
-- seconds, then lets everything else move again for a while, then takes the
-- pass back and tries again. Rebirth stays first in the order throughout, so
-- nothing is lost by letting go.
local WorkerPass

do

local RebirthHold = 120
local RebirthRelease = 60
local RebirthHeldSince = 0

function WorkerPass()
    local Only

    if RebirthPending() then
        if RebirthHeldSince == 0 then
            RebirthHeldSince = os.clock()
        end

        local Elapsed = os.clock() - RebirthHeldSince

        if Elapsed < RebirthHold then
            Only = "rebirth"
        elseif Elapsed > RebirthHold + RebirthRelease then
            -- long enough; take the pass back and try holding again
            RebirthHeldSince = os.clock()
        end
    elseif RebirthHeldSince ~= 0 then
        RebirthHeldSince = 0
    end

    for _, Entry in ipairs(Tasks) do
        if not Only or Entry.Name == Only then
            local Ok, Did = pcall(Entry.Step)

            if not Ok then
                warn("[ValkyrieHub] task " .. Entry.Name .. ": " .. tostring(Did))
            elseif Did then
                SetPhase(PhaseNames[Entry.Phase] or Entry.Phase, Entry.Name)

                return
            end
        end
    end

    if Only then
        SetPhase("rebirth", "held for the rebirth -- " .. tostring(RebirthState.Why))

        return
    end

    SetPhase("waiting", "nothing to do this pass")
end

end

Loop("worker", 1, WorkerPass)

---- ============ Horst ============ ----

-- When the run is launched by the Horst account manager, Horst owns the
-- account queue and the rejoin: this file only has to tell it what the account
-- now holds, and say when the account is finished so the next one can start.
--
-- Both functions are looked up on every call rather than cached, because a
-- manager that sets them a moment after the script starts is the normal case,
-- and a plain executor simply never has them.
-- One table rather than one local per entry point. This chunk runs close to
-- Luau's ceiling of two hundred registers per function, and the reporters are
-- the last thing in the file, so they are the ones that pay for it.
local Report = { }

do
    local function HorstFunction(Name)
        local Found = rawget(_G, Name)

        if type(Found) == "function" then return Found end

        local Env = getgenv and getgenv()

        if type(Env) == "table" then
            Found = rawget(Env, Name)

            if type(Found) == "function" then return Found end
        end
    end

    -- the two characters the description may never carry
    local function Clean(Text)
        return (tostring(Text):gsub("[|;]", " "))
    end

    local function Snapshot()
        local Roster = GetRoster()
        local Champion = Roster and ChampionOf(Roster)
        local Coop = GetCoop()
        local Count = RebirthCount()
        local Points = RebirthPoints()

        return {
            Rebirth   = Count,
            Points    = Points,
            MoneyMult = 1 + Count * GameConfig.rebirth.baseMoneyBonus
                + Points * GameConfig.rebirth.scaleMoneyBonus,
            Eggs      = EggsHeld(),
            Money     = GetMoney(),
            Roster    = #Chickens(Roster),
            -- still sent, because a run that is stuck is usually stuck on the
            -- tower and a dashboard should be able to see that; no longer a
            -- headline figure, because it is not what the account is worth
            Tower     = TowerBest(),
            Feeders   = Coop and #Coop.generators or 0,
            Recycler  = RecyclerLevel(),
            Rarity    = Champion and Clean(RarityOf(Champion)) or "none",
            Type      = Champion and Clean(Champion.typeId or "?") or "none",
            Level     = Champion and (Champion.level or 1) or 0,
            Gene      = Champion and math.floor(GeneQuality(Champion) * 100 + 0.5) or 0,
            Rank      = type(Ranked.Data) == "table" and Clean(Ranked.Data.rank or "-") or "-",
            Trophies  = type(Ranked.Data) == "table" and (Ranked.Data.trophies or 0) or 0,
            Done      = AllGoalsDone(),
        }
    end

    -- What the manager shows in one line, in the order it is read: the rebirth
    -- count the run is judged on, the eggs the account is holding, and the
    -- chicken doing the laying. The plot figures came out -- a rebirth deletes
    -- the coop, so a feeder count in a handover line is noise.
    local function Describe(State)
        local Line = Clean(string.format(
            "♻️ Rebirth %d (%d pts, x%.2f money) , 🥚 %d eggs , 🐔 %s %s Lv%d , 🧬 %d%% , 💰 %s",
            State.Rebirth, State.Points, State.MoneyMult,
            State.Eggs,
            State.Rarity, State.Type, State.Level, State.Gene,
            Fmt(State.Money)
        ))

        -- the rank joins the handover line only on a run that was asked for one
        if type(Config.Goal.Rank) == "string" and Config.Goal.Rank ~= "" then
            Line = Line .. Clean(string.format(" , 🏆 %s (%d)", State.Rank, State.Trophies))
        end

        return Line
    end

    local LastText = nil
    local LastSentAt = 0

    Report.Snapshot = Snapshot

    Report.Horst = function(Force)
        if not Config.Horst then return end

        local Send = HorstFunction("Horst_SetDescription")

        if not Send then return end

        local State = Snapshot()
        local Text = Describe(State)

        -- the manager is not a log: it is only told when something it shows
        -- has actually changed, or once a couple of minutes regardless
        if not Force and Text == LastText and os.clock() - LastSentAt < 120 then
            return
        end

        LastText = Text
        LastSentAt = os.clock()

        local Ok, Encoded = pcall(function()
            return HttpService:JSONEncode(State)
        end)

        pcall(Send, Text, Ok and Encoded or nil)
    end

    local Finished = false

    Report.Finish = function()
        if not Config.Horst or Finished then return end

        local Send = HorstFunction("Horst_AccountChangeDone")

        if not Send then return end

        Finished = true

        local Called, Ok, Err = pcall(Send)

        if Called and Ok then
            Log("Horst told the account is done")
        else
            -- the doc returns false plus a reason; a failed handover is worth
            -- seeing rather than silently sitting on a finished account
            warn("[ValkyrieHub] Horst handover failed: " .. tostring(Called and Err or Ok))

            Finished = false
        end
    end

end


---- ============ Progress ============ ----

-- One number a dashboard can put on a bar, and the parts it was made of so the
-- same dashboard can show why it sits where it does.
--
-- There used to be seven parts: rebirth, tower floor, feeders, recycler,
-- champion rarity, gene quality and the tutorial. Five of those are not what
-- the account is worth, they are what it had to build on the way -- and a
-- rebirth deletes the coop and resets the level, so a dashboard showing a
-- finished coop was showing something the next rebirth was about to undo. They
-- are still built. They are no longer scored.
--
-- What is left is what an account is actually judged on when the run is handed
-- over: how many rebirths it banked, how many eggs it is sitting on, and how
-- good the chicken in the coop is. Rarity carries the most because it is the
-- one thing a rebirth cannot take away and the one thing that cannot be bought
-- back with time.

do
    -- Rarity has no target, so it is scored against the top of the ladder --
    -- secret -- and reads as the fraction of the way there. An account at
    -- legendary is not finished and is not supposed to look finished.
    local RarityTop = #Rarities

    Report.Progress = function()
        local Roster = GetRoster()
        local Champion = Roster and ChampionOf(Roster)

        local Quality = Champion and GeneQuality(Champion) or 0
        local Rarity = Champion and RarityOf(Champion) or "none"
        local Rank = Champion and (RarityRank[Rarity] or 1) or 0
        local Eggs = EggsHeld()
        local Count = RebirthCount()

        -- Eggs with no target cannot be a fraction of anything, so the bar
        -- reads them against a working figure instead: enough of a stash that
        -- the hatcher has something to open for the rest of the night. Config
        -- can name a real one and then that is what is scored.
        local EggTarget = tonumber(Config.Goal.Eggs) or 0

        if EggTarget <= 0 then
            EggTarget = 250
        end

        local Parts = {
            {
                key = "rebirth", label = "Rebirth", weight = 45,
                current = Count, target = Config.Goal.Rebirth,
                text = string.format("%d of %d", Count, Config.Goal.Rebirth),
            },
            {
                key = "rarity", label = "Champion rarity", weight = 30,
                current = Rank, target = RarityTop,
                text = string.format("%s, %d of %d steps", Rarity, Rank, RarityTop),
            },
            {
                key = "eggs", label = "Eggs held", weight = 15,
                current = Eggs, target = EggTarget,
                text = string.format("%d unhatched", Eggs),
            },
            {
                key = "genes", label = "Gene quality", weight = 10,
                current = Quality, target = 1,
                text = string.format("%d%% of the %s cap", math.floor(Quality * 100 + 0.5), Rarity),
            },
        }

        -- The rank only scores when a rank was asked for. On a default run
        -- Config.Goal.Rank is "" and the arena is a side job, so putting a
        -- permanently-zero part on the bar would read as an account that is
        -- failing at something nobody asked it to do.
        do
            local Want = Config.Goal.Rank
            local Target = type(Want) == "string" and RankedIndex[Want] or nil

            if Target then
                local Now = RankedRankNow()
                local Data = Ranked.Data

                table.insert(Parts, {
                    key = "rank", label = "Arena rank", weight = 25,
                    current = Now, target = Target,
                    text = string.format("%s of %s",
                        type(Data) == "table" and tostring(Data.rankId or "-") or "unknown",
                        Want),
                })
            end
        end

        local Weight, Earned = 0, 0

        for _, Part in ipairs(Parts) do
            local Ratio = math.clamp((Part.current or 0) / math.max(Part.target or 1, 0.000001), 0, 1)

            Part.percent = math.floor(Ratio * 1000 + 0.5) / 10
            Part.done = Ratio >= 1

            Weight = Weight + Part.weight
            Earned = Earned + Part.weight * Ratio
        end

        return math.floor(Earned / Weight * 1000 + 0.5) / 10, Parts
    end

    ---- ---- live telemetry ---- ----
    --
    -- One POST per account to one endpoint. The body says who is reporting
    -- (UserId is the key a dashboard groups by), what the run is doing right
    -- now, and the same state the manager is shown. A dashboard being down is
    -- not the run's problem: a failed post backs the reporter off and the rest
    -- of the script never notices.
    local Wire = {
        Http   = request or http_request or (syn and syn.request) or (http and http.request),
        -- Where the report goes, and the longest it may go without saying
        -- anything. These were config once, back when the endpoint was
        -- something a run might point somewhere else. It is not: it is the
        -- site this script belongs to, so it lives here with the code that
        -- posts to it, and Config.Web is the on/off switch and nothing more.
        Url    = "https://www.valkyriehub.net/api/kaitan/report",
        Idle   = 60,   -- post at least this often even when nothing moved
        PostAt = 0,
        Quiet  = 0,
        Warned = false,
        -- highest milestone already announced, and whether the first tick has
        -- run: a rejoin restarts this script on an account that is already
        -- halfway, and it must not announce the lines it passed last session
        Sent   = 0,
        Primed = false,
        Final  = false,
        Key    = nil,
        -- shown on the dashboard so a run that misbehaves can be traced to the
        -- executor it is running under; it is not, and cannot be, a credential
        Executor = (function()
            if type(identifyexecutor) ~= "function" then return "unknown" end

            local Ok, Name, Version = pcall(identifyexecutor)

            if not Ok or type(Name) ~= "string" then return "unknown" end

            return type(Version) == "string" and Version ~= "" and (Name .. " " .. Version) or Name
        end)(),
    }

    -- The licence key, found once and remembered. The loader accepts it under
    -- four names and, once verified, writes it to its own key file, so a run
    -- launched the normal way already has one and nothing has to be told it.
    local function ResolveKey()
        if Wire.Key then return Wire.Key end

        local Env = (type(getgenv) == "function" and getgenv()) or _G

        for _, Name in ipairs({ "ValkyrieKey", "LicenseKey", "License", "Key" }) do
            local Ok, Value = pcall(function() return Env[Name] end)

            if Ok and type(Value) == "string" and Value ~= "" then
                Wire.Key = (Value:gsub("%s", ""))

                return Wire.Key
            end
        end

        local File = "Valkyrie Hub/MyKey/key.txt"

        if type(isfile) == "function" and type(readfile) == "function" and isfile(File) then
            local Ok, Value = pcall(readfile, File)

            if Ok and type(Value) == "string" and Value ~= "" then
                Wire.Key = (Value:gsub("%s", ""))

                return Wire.Key
            end
        end
    end

    Report.Web = function(Percent, Parts, Force)
        if not Config.Web then return end
        if not Wire.Http then return end

        local Now = os.clock()

        if not Force and Now < Wire.Quiet then return end

        local Payload = {
            userId      = LocalPlayer.UserId,
            name        = LocalPlayer.Name,
            displayName = LocalPlayer.DisplayName,
            placeId     = game.PlaceId,
            jobId       = game.JobId,
            players     = #Players:GetPlayers(),
            uptime      = math.floor(Now - StartedAt),
            phase       = CurrentPhase,
            action      = CurrentAction,
            onboarding  = OnboardingStep(),
            executor    = Wire.Executor,
            goal        = Config.Goal,
            progress    = Percent,
            parts       = Parts,
            state       = Report.Snapshot(),
            at          = os.time(),
        }

        local Made, Body = pcall(function()
            return HttpService:JSONEncode(Payload)
        end)

        if not Made then return end

        -- the uptime and the timestamp move on their own every single pass, so
        -- "nothing changed" is judged with both of them taken back out
        local Fingerprint = Body:gsub('"uptime":%-?%d+', ""):gsub('"at":%-?%d+', "")

        if not Force and Fingerprint == Wire.Body and Now - Wire.PostAt < Wire.Idle then
            return
        end

        local Headers = { ["Content-Type"] = "application/json" }
        local Key = ResolveKey()

        if Key then
            Headers["x-valkyrie-key"] = Key
        else
            -- without a key the site has no way to tell whose run this is, and
            -- would only answer 401 over and over
            if not Wire.Warned then
                Wire.Warned = true

                warn("[ValkyrieHub] telemetry off: no licence key found; run this under the loader.")
            end

            return
        end

        local Ok, Response = pcall(Wire.Http, {
            Url = Wire.Url,
            Method = "POST",
            Headers = Headers,
            Body = Body
        })

        local Code = Ok and type(Response) == "table"
            and tonumber(Response.StatusCode or Response.Status)

        if Ok and Code and Code >= 200 and Code < 300 then
            Wire.Body = Fingerprint
            Wire.PostAt = Now
            Wire.Quiet = 0
            Wire.Warned = false

            return
        end

        -- one line, once: an endpoint that is down is not worth a console full
        -- of the same warning every fifteen seconds
        if not Wire.Warned then
            Wire.Warned = true

            warn("[ValkyrieHub] telemetry post failed: "
                .. tostring(Code or (Ok and "no status" or Response)))
        end

        Wire.Quiet = Now + 60
    end

    ---- ---- Discord ---- ----
    --
    -- The milestone message is posted by this script, not by the site. The
    -- dashboard holds nothing: it shows what is being reported right now and
    -- forgets a run that stops. Anything that has to survive that -- an
    -- account that finished while nobody was watching -- goes to Discord,
    -- which keeps it.
    --
    -- A line is announced once. `Sent` remembers the highest one, and the very
    -- first tick after a rejoin only records where the account already stands
    -- rather than replaying every line it passed in the previous session.
    Report.Discord = function(Percent, Parts, Force)
        local Setup = Config.Discord

        if not (Setup and type(Setup.Webhook) == "string" and Setup.Webhook ~= "") then return end
        if not Wire.Http then return end

        local Lines = Setup.Milestones or { 25, 50, 75, 100 }
        local Reached = 0

        for _, Line in ipairs(Lines) do
            if Percent >= Line and Line > Wire.Sent then
                Reached = math.max(Reached, Line)
            end
        end

        -- a forced call comes from the goal watch when everything is done, and
        -- it is allowed to send once even if no line was crossed on this pass.
        -- Without the flag it would repeat the message the 100% line just sent.
        local Final = Force and not Wire.Final

        if not Wire.Primed then
            Wire.Primed = true
            Wire.Sent = math.max(Wire.Sent, Reached)

            if not Final then return end
        end

        if Reached == 0 and not Final then return end

        Wire.Sent = math.max(Wire.Sent, Reached)

        if Final then
            Wire.Final = true
        end

        local State = Report.Snapshot()
        local Breakdown = { }

        for _, Part in ipairs(Parts or { }) do
            table.insert(Breakdown, string.format("%s %s -- %s%%",
                Part.done and "[x]" or "[ ]", Part.label, tostring(Part.percent)))
        end

        -- Discord rejects an embed field with an empty value, so a run that
        -- reported no breakdown gets a dash rather than a 400
        if #Breakdown == 0 then
            table.insert(Breakdown, "-")
        end

        local Embed = {
            username = "Valkyrie Hub // Kaitan",
            embeds = { {
                title = (Reached >= 100 or State.Done) and "Kaitan finished" or (tostring(Reached) .. "% reached"),
                description = string.format("**%s** (`%d`)", LocalPlayer.DisplayName, LocalPlayer.UserId),
                color = 16777215,
                fields = {
                    { name = "Progress",  value = string.format("%.1f%%", Percent), inline = true },
                    { name = "Rebirth",   value = string.format("%d (x%.2f money)", State.Rebirth, State.MoneyMult), inline = true },
                    { name = "Tower",     value = "floor " .. tostring(State.Tower), inline = true },
                    { name = "Champion",  value = string.format("%s %s Lv%d, genes %d%%", State.Rarity, State.Type, State.Level, State.Gene), inline = true },
                    { name = "Money",     value = Fmt(State.Money), inline = true },
                    { name = "Doing",     value = tostring(CurrentPhase) .. " / " .. tostring(CurrentAction), inline = true },
                    { name = "Breakdown", value = table.concat(Breakdown, "\n"), inline = false },
                },
                footer = { text = "Valkyrie Hub" },
            } },
        }

        local Made, Body = pcall(function()
            return HttpService:JSONEncode(Embed)
        end)

        if not Made then return end

        local Ok, Response = pcall(Wire.Http, {
            Url = Setup.Webhook,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = Body
        })

        local Code = Ok and type(Response) == "table"
            and tonumber(Response.StatusCode or Response.Status)

        if not (Ok and Code and Code >= 200 and Code < 300) then
            -- the line is left unmarked so the next pass tries it again; a
            -- webhook that is briefly rate limited should not cost the message
            Wire.Sent = math.max(0, Reached - 1)
            Wire.Final = false

            warn("[ValkyrieHub] Discord post failed: "
                .. tostring(Code or (Ok and "no status" or Response)))
        end
    end

    -- One pass computes the progress once and hands the same numbers to both
    -- reporters, rather than each of them working it out for itself.
    Report.Tick = function(Force)
        local Percent, Parts = Report.Progress()

        pcall(Report.Web, Percent, Parts, Force)
        pcall(Report.Discord, Percent, Parts, Force)
    end
end

Loop("horst", 20, function()
    pcall(Report.Horst)
end)

-- fifteen seconds while the state keeps changing; Wire.Idle is what makes a
-- run that is sitting still still say so.
--
-- The random phase in front of it is for the rigs: fifty clients started
-- together would otherwise post on the same tick of the same second, forever,
-- and fifty TLS connections opened at once every fifteen seconds is what fills
-- a router's NAT table. Spread over the interval it is three or four a second
-- and nothing notices.
task.spawn(function()
    task.wait(math.random() * 15)

    Loop("web", 15, function()
        pcall(Report.Tick)
    end)
end)

--// goal watch
--
-- Reaching the target is announced once and then the run carries on. It used to
-- set Done and stop every loop in the file, which left an account standing in a
-- corner producing nothing for however many hours were left in the night. The
-- chicken keeps laying, the eggs keep hatching, and anything better that comes
-- out of them keeps being fused in -- see Parked for exactly which two jobs
-- stand down and why those two.
do
local Announced = false

Loop("goals", 10, function()
    if Announced then return end
    if not AllGoalsDone() then return end

    Announced = true

    SetPhase("kaitan", "target met -- laying from here")
    Log(string.format("KAITAN -- rebirth %d reached; laying from here", RebirthCount()))

    Notify("Kaitan", string.format(
        "Rebirth %d reached. The chicken stays in the coop laying from here.",
        RebirthCount()))

    -- the last report goes out before the handover, so the manager shows what
    -- the finished account actually holds rather than the state it was in
    -- twenty seconds ago
    pcall(Report.Horst, true)
    pcall(Report.Tick, true)
    pcall(Report.Finish)
end)
end

--// status, and the walk speed lapse that rides along with it
Loop("status", 0.5, function()
    pcall(SpeedTick)
    pcall(RefreshStatus)
end)

---- ============ Server hop ============ ----

-- Finding a quiet server is worth more here than it looks.
--
-- Everything the run fetches is contested: the pit is shared, and every other
-- player has a champion in it that knocks players down and takes half the load
-- (scrap.stealPct). The scrap on the floor is one pool under one
-- scrap.looseCap of 140 for the whole server, and the hot egg and the event
-- drops are one each. A server holding 8 is eight claims on all of it; a server
-- holding 1 is one.
--
-- The list comes from the public games endpoint, the same one the website uses
-- for the server browser, and the hop is TeleportToPlaceInstance. Nothing here
-- is a private API and nothing here is faster than a player clicking a server
-- in that list.
--
-- The anti-AFK section further down leaves through the same door, so what the
-- block below builds is published on this table rather than kept to itself.
local Hop = { }

do
    local HttpRequest = request or http_request
        or (syn and syn.request)
        or (http and http.request)

    local ServersUrl = "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"

    local HoppedAt = 0
    local HopCooldown = 45

    -- the quietest server that is not this one and still has a slot, or nothing
    local function QuietestServer()
        if not HttpRequest then return end

        local Ok, Response = pcall(HttpRequest, {
            Url = string.format(ServersUrl, game.PlaceId),
            Method = "GET"
        })

        if not (Ok and type(Response) == "table" and Response.Body) then return end

        local Fine, Data = pcall(function()
            return HttpService:JSONDecode(Response.Body)
        end)

        if not (Fine and type(Data) == "table" and type(Data.data) == "table") then return end

        local Best, BestCount

        for _, Server in ipairs(Data.data) do
            local Playing = tonumber(Server.playing)
            local Cap = tonumber(Server.maxPlayers)

            if type(Server.id) == "string"
                and Server.id ~= game.JobId
                and Playing and Cap
                and Playing < Cap then
                if not BestCount or Playing < BestCount then
                    Best = Server.id
                    BestCount = Playing
                end
            end
        end

        return Best, BestCount
    end

    -- Leave this server for the quietest one going, or for any server at all
    -- when the listing is unavailable. Reason is what goes in the log.
    function Hop.Now(Reason)
        if os.clock() - HoppedAt < HopCooldown then return false end

        HoppedAt = os.clock()

        local Target, Count = QuietestServer()

        Log(string.format("%s; hopping%s", Reason,
            Count and string.format(" to a server with %d", Count) or ""))

        -- the executor's autoexec folder fires on the far side, so the run
        -- picks itself back up there without anything else being done here
        return (pcall(function()
            if Target then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, Target, LocalPlayer)
            else
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            end
        end))
    end

    TrackConnection(TeleportService.TeleportInitFailed:Connect(function(Player, Result, Message)
        if Player ~= LocalPlayer then return end

        -- a server that filled up between the listing and the teleport is the
        -- ordinary case; the next tick picks a different one
        HoppedAt = 0

        warn("[ValkyrieHub] hop refused: " .. tostring(Message))
    end))

    Loop("server", Config.Server.Recheck, function()
        if not Config.Server.Hop then return end
        if os.clock() - HoppedAt < HopCooldown then return end

        local Here = #Players:GetPlayers()

        if Here <= Config.Server.MaxPlayers then return end

        -- a tower run is paid for and in progress; it finishes before the run
        -- goes anywhere
        if TowerActive() then return end

        local Target, Count = QuietestServer()

        -- only worth the loading screen if the other server is actually quieter
        if not Target or Count >= Here then return end

        Hop.Now(string.format("server has %d players", Here))
    end)
end

---- ============ Anti-AFK ============ ----

-- Error 278 is Roblox's own twenty minute idle disconnect, and the timer
-- behind it counts INPUT -- mouse, keyboard, touch. Nothing else. A character
-- walking the pit all night does not move it by a single second, so synthetic
-- input is the only thing that answers it.
--
-- This is the shape that survives here, and the three things it does NOT do
-- are the whole point. Each of them was in an earlier version of this file and
-- each of them ended in an anti-cheat kick:
--
--   * no CaptureController(). That call has VirtualUser take over the player's
--     controller, which routes the input through the character's own control
--     module -- the part the game can see. Button2Down and Button2Up on their
--     own are raw mouse buttons that never reach it.
--
--   * nothing on a timer. The input happens on Idled and only on Idled, which
--     is once every twenty minutes. A poke every four minutes, forever, at the
--     same coordinate, is a metronome, and a metronome is what a client side
--     check is written to find.
--
--   * Button2Down and Button2Up a second apart, not ClickButton2. Same two
--     events, but this is the pair a player's own right click produces, held
--     for a human length of time, and it carries the camera CFrame the real
--     one carries.
--
-- (0, 0) is left as it is rather than randomised. It is where every one of
-- these has pointed for years, which makes it the unremarkable value; a
-- wandering cursor that only ever moves at the idle threshold would stand out
-- more than a still one.

-- local AntiAfk = { Connection = nil }

-- local function SetAntiAfk(Enabled)
--     Config.AntiAFK = Enabled
--     getgenv().ConfigurationTable.AntiAFK = Enabled

--     if not Enabled then
--         if AntiAfk.Connection then
--             AntiAfk.Connection:Disconnect()
--             AntiAfk.Connection = nil
--         end

--         return
--     end

--     if AntiAfk.Connection then return end

--     -- the service is fetched here rather than at the top of the file, so a run
--     -- with anti-AFK off never asks for it at all
--     local User = game:GetService("VirtualUser")

--     AntiAfk.Connection = TrackConnection(LocalPlayer.Idled:Connect(function()
--         pcall(function()
--             local Camera = workspace.CurrentCamera

--             User:Button2Down(Vector2.new(0, 0), Camera.CFrame)
--             task.wait(1)
--             User:Button2Up(Vector2.new(0, 0), Camera.CFrame)
--         end)
--     end))
-- end

-- getgenv().ValkyrieSetAntiAfk = SetAntiAfk

-- if Config.AntiAFK then
--     SetAntiAfk(true)
-- end

---- ============ Session plumbing ============ ----

if Config.AutoRejoin then
    TrackConnection(game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(Child)
        if Child.Name == "ErrorPrompt" then
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end))
end

-- Nothing is queued for the far side of a teleport any more.
--
-- queue_on_teleport used to carry a chunk that re-fetched the loader and
-- re-declared every global the run was tuned with, because getgenv() does not
-- survive a teleport. It worked often enough to keep, and not often enough to
-- trust: an executor that dropped the queue, or ran it before the place was
-- ready, brought the far side up as the ordinary build on default settings --
-- which looks exactly like the script working.
--
-- The executor's own autoexec folder does the same job and does it every time,
-- because it fires on every join rather than only on teleports this script
-- started, and it carries the settings in the file rather than in a chunk that
-- has to reconstruct them. See Loader/Autoexec.lua.

-- the paid continue offer at the end of a tower run is always declined: it
-- costs Robux and the run is restarted for free on the next pass anyway
task.spawn(function()
    TrackConnection(Remotes.onClient(Remotes.defs.TowerContinueOffer, function(Offer)
        if type(Offer) == "table" and Offer.open == true and Offer.paid == true then
            Remotes.fire(Remotes.defs.TowerContinueDecline)
        end
    end))
end)

-- knocked out in the pit: the character stops being walked for the KO cooldown
-- rather than fighting the server over where it is standing
task.spawn(function()
    TrackConnection(Remotes.onClient(Remotes.defs.PitPlayerKo, function()
        HoldMovement()
    end))
end)

---- ============ Cleanup ============ ----

getgenv().ValkyrieCleanup = function()
    getgenv().ValkyrieSession = nil

    pcall(StopNoclip)
    pcall(ReleaseSpeed, true)

    for _, Connection in ipairs(SessionConnections) do
        pcall(function()
            Connection:Disconnect()
        end)
    end

    table.clear(SessionConnections)

    pcall(function()
        UI.Screen:Destroy()
    end)

    getgenv().ValkyrieCleanup = nil
end

Log("kaitan run started")

pcall(RefreshStatus)