--[[
    Valkyrie Hub | Grow a Chicken Fighter -- detection probe

    One behaviour at a time, so the kick can be pinned on one of them.

        CODE BAC-9514

    Set TEST below, execute, and leave the character alone until the run ends or the kick
    lands. Every test writes what it did and when to

        Valkyrie Hub/GFC/TestLog.txt

    which survives the kick, so the last line in that file names whatever was running when
    the server pulled the plug. Run the tests in the order listed: the early ones do almost
    nothing, and if one of those gets kicked there is no point testing the later ones.

    Nothing here needs the UI library and nothing calls require.
]]

local TEST = "00_pure"
local RUN_SECONDS = 180

--[[
    TESTS, in the order worth running

    00_pure            nothing whatsoever: no getgc, no file, no CoreGui, no reads
    00_spy             logs every remote call leaving this client, so a detector that
                       reports us can be caught in the act
    01_baseline        the same idle wait, but with the module scan and the log file on
    02_read_data       reads the game's own tables out of memory, sends nothing
    03_walk            walks a small square with Humanoid:MoveTo, nothing else
    04_walkspeed       sets Humanoid.WalkSpeed = 18 (what the hub used to do)
    05_touch_eggs      firetouchinterest on nest eggs (what the hub used to do)
    06_walk_eggs       walks to nest eggs instead, no touch fired
    07_grab_scrap      walks to scrap, carries it to the recycler
    08_remote_far      buy / upgrade remotes fired from wherever the character stands
    09_remote_near     same remotes, but only from inside the prompt's own range
    10_hatch           HatchEgg / HatchEggs
    11_sell_fuse       SellChickens / FuseChickens
    12_claims          DailyClaim / MissionClaim / PassClaim
    13_chicken_order   SetChickenOrder chaos / coop
    14_tower           TowerStart / TowerSurrender
    15_encourage       EncourageChicken
]]

---- ============ Setup ============ ----

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

while not LocalPlayer do
    task.wait()

    LocalPlayer = Players.LocalPlayer
end

local LogFolder = "Valkyrie Hub"
local LogSubFolder = "Valkyrie Hub/GFC"
local LogFile = LogSubFolder .. "/TestLog.txt"

local StartedAt = os.clock()

-- 00_pure has to be exactly what its name says, so it writes no file and reads no CoreGui.
-- Anything the log does is itself a thing the client would not otherwise do.
local Pure = TEST == "00_pure"

local function Log(Text)
    local Line = string.format("[%s] %6.1fs  %s", TEST, os.clock() - StartedAt, Text)

    print("[probe] " .. Line)

    if Pure then return end

    if not (writefile and appendfile and isfolder and makefolder) then return end

    if not isfolder(LogFolder) then makefolder(LogFolder) end
    if not isfolder(LogSubFolder) then makefolder(LogSubFolder) end

    if isfile and isfile(LogFile) then
        pcall(appendfile, LogFile, Line .. "\n")
    else
        pcall(writefile, LogFile, Line .. "\n")
    end
end

Log("---- start ---- " .. os.date("%X"))

-- the kick itself: Roblox puts an ErrorPrompt into CoreGui a moment before the client is
-- dropped, which is long enough to get one more line into the log
task.spawn(function()
    if Pure then return end

    local Ok, Prompt = pcall(function()
        return game:GetService("CoreGui").RobloxPromptGui.promptOverlay
    end)

    if not Ok or not Prompt then return end

    Prompt.ChildAdded:Connect(function(Child)
        if Child.Name == "ErrorPrompt" then
            Log("!!!! KICKED while running " .. TEST)
        end
    end)
end)

---- ============ Game access, no require ============ ----

-- The scan is no longer done at startup. 01_baseline used to run it before it decided to do
-- nothing, so "nothing" still meant a full sweep of the Lua registry; the tests that need
-- the game's tables now ask for them and the ones that do not never touch getgc at all.
local Modules = { }
local Scanned = false

local function Scan()
    if Scanned then return end

    Scanned = true

    if type(getgc) ~= "function" then
        Log("executor has no getgc; only the tests that need no game data will work")
    else
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

            PitZone = function(Value)
                return typeof(rawget(Value, "center")) == "Vector3"
                    and type(rawget(Value, "contains")) == "function"
            end,
        }

        for _, Value in ipairs(getgc(true)) do
            if type(Value) == "table" then
                for Name, Test in pairs(Patterns) do
                    local Ok, Match = pcall(Test, Value)

                    if Ok and Match then
                        Modules[Name] = Value
                        Patterns[Name] = nil
                    end
                end
            end
        end

        local Missing = { }

        for Name in pairs(Patterns) do
            table.insert(Missing, Name)
        end

        Log("modules found, missing: " .. (#Missing > 0 and table.concat(Missing, ",") or "none"))
    end
end

local RemoteFolder = ReplicatedStorage:WaitForChild("Remotes")

local function Fire(Name, ...)
    local Remote = RemoteFolder:FindFirstChild(Name)

    if not Remote then
        Log("no remote named " .. Name)

        return
    end

    Log("fire " .. Name)

    Remote:FireServer(...)
end

local function Invoke(Name, ...)
    local Remote = RemoteFolder:FindFirstChild(Name)

    if not Remote then
        Log("no remote named " .. Name)

        return
    end

    Log("invoke " .. Name)

    local Ok, Reply = pcall(function(...)
        return Remote:InvokeServer(...)
    end, ...)

    if not Ok then
        Log("  " .. Name .. " errored: " .. tostring(Reply))
    elseif type(Reply) == "table" then
        Log("  " .. Name .. " -> ok=" .. tostring(Reply.ok) .. " error=" .. tostring(Reply.error))
    else
        Log("  " .. Name .. " -> " .. tostring(Reply))
    end

    return Reply
end

local function GetData(Key)
    Scan()

    if not Modules.DataService then return end

    local Ok, Value = pcall(function()
        return Modules.DataService.client:get(Key)
    end)

    if Ok then
        return Value
    end
end

local function GetRootPart()
    local Character = LocalPlayer.Character

    return Character and Character:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local Character = LocalPlayer.Character

    return Character and Character:FindFirstChildOfClass("Humanoid")
end

local function MyPlot()
    return LocalPlayer:GetAttribute("Plot")
end

local function PlotModel(FolderName, Prefix)
    local Folder = workspace:FindFirstChild(FolderName)
    local Plot = MyPlot()

    if not (Folder and Plot) then return end

    return Folder:FindFirstChild(Prefix .. tostring(Plot))
end

local function PartOf(Model)
    if not Model then return end

    return Model.PrimaryPart or Model:FindFirstChildWhichIsA("BasePart", true)
end

local function NearestPrompt(Container)
    local Root = GetRootPart()

    if not (Container and Root) then return end

    local Best, BestDistance

    for _, Prompt in ipairs(Container:GetDescendants()) do
        if Prompt:IsA("ProximityPrompt") and Prompt.Enabled then
            local Part = Prompt.Parent

            if Part and Part:IsA("BasePart") then
                local Distance = (Part.Position - Root.Position).Magnitude

                if not BestDistance or Distance < BestDistance then
                    Best = Prompt
                    BestDistance = Distance
                end
            end
        end
    end

    return Best, BestDistance
end

-- walks toward the prompt and answers true only once the character is standing inside the
-- distance the prompt itself would accept
local function AtPrompt(FolderName, UIName)
    local Folder = workspace:FindFirstChild(FolderName)
    local Container = Folder and Folder:FindFirstChild(UIName)
    local Prompt, Distance = NearestPrompt(Container)

    if not Prompt then return false end

    if Distance <= math.max(3, Prompt.MaxActivationDistance - 2) then return true end

    local Humanoid = GetHumanoid()

    if Humanoid then
        Humanoid:MoveTo(Prompt.Parent.Position)
    end

    return false
end

local function NearestStack(Origin)
    local Folder = workspace:FindFirstChild("PitScrap")

    if not Folder then return end

    local Mine = "player:" .. LocalPlayer.UserId
    local Best, BestDistance

    for _, Piece in ipairs(Folder:GetChildren()) do
        if Piece:IsA("BasePart") then
            local Owner = Piece:GetAttribute("DropOwner")

            if Piece:GetAttribute("StackKind") and (Owner == nil or Owner == Mine) then
                local Distance = (Piece.Position - Origin).Magnitude

                if not BestDistance or Distance < BestDistance then
                    Best = Piece
                    BestDistance = Distance
                end
            end
        end
    end

    return Best
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

---- ============ The tests ============ ----

local Tests = { }

-- Nothing whatsoever. No file, no CoreGui, no getgc, no reads, no movement, no remotes.
-- If this one is kicked then the script is not what the server is reacting to: the executor
-- being attached at all is, and no amount of rewriting this hub changes that. Run it with
-- the Dex bridge closed and every other script unloaded, or the result means nothing.
Tests["00_pure"] = function(Tick)
    if Tick % 40 == 0 then
        print(string.format("[probe] 00_pure alive %.0fs -- nothing has been touched", os.clock() - StartedAt))
    end
end

-- Everything leaving this client, logged as it goes.
--
-- If a client-side detector is what reports us, it has to reach the server somehow, and the
-- only way out is a remote. This hooks the namecall metamethod once and writes down every
-- FireServer / InvokeServer with the script that made the call, so whatever fires in the
-- seconds before the kick is named in the log.
do
    local Hooked = false

    local function Install()
        if Hooked then return end

        Hooked = true

        if not (hookmetamethod and getnamecallmethod and newcclosure) then
            Log("executor cannot hook __namecall (needs hookmetamethod + getnamecallmethod + newcclosure)")

            return
        end

        local Original

        Original = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local Method = getnamecallmethod()

            if (Method == "FireServer" or Method == "InvokeServer") and typeof(self) == "Instance" then
                local Parts = { }

                for Index, Value in ipairs({ ... }) do
                    if Index > 4 then
                        table.insert(Parts, "...")

                        break
                    end

                    table.insert(Parts, typeof(Value) == "table" and "table" or tostring(Value))
                end

                local Source = "?"

                if debug and debug.info then
                    local Ok, Name = pcall(debug.info, 2, "s")

                    if Ok and Name then Source = tostring(Name) end
                end

                Log(string.format("%s %s(%s)  from %s", Method, self.Name, table.concat(Parts, ", "), Source))
            end

            return Original(self, ...)
        end))

        Log("namecall hook installed; every outgoing remote from here on is logged")
    end

    Tests["00_spy"] = function(Tick)
        Install()

        if Tick % 40 == 0 then
            Log("watching outgoing remotes")
        end
    end
end

-- idle, but with the log file and the module scan running, which is what the first version
-- of this probe actually measured
Tests["01_baseline"] = function(Tick)
    Scan()

    if Tick % 40 == 0 then
        Log("sitting still, no remotes, no movement")
    end
end

-- reads only. Nothing leaves the client.
Tests["02_read_data"] = function(Tick)
    Scan()

    if Tick % 10 ~= 0 then return end

    local Money = GetData("money")
    local Roster = GetData("roster")
    local Scrap = GetData("scrap")

    Log(string.format("money=%s chickens=%s recyclerLevel=%s",
        tostring(Money),
        tostring(type(Roster) == "table" and type(Roster.chickens) == "table" and #Roster.chickens or "?"),
        tostring(type(Scrap) == "table" and Scrap.recyclerLevel or "?")))
end

-- ordinary walking, the same call the hub uses, nothing else touched
do
    local Corners = nil
    local Index = 1

    Tests["03_walk"] = function(Tick)
        if Tick % 5 ~= 0 then return end

        local Root = GetRootPart()
        local Humanoid = GetHumanoid()

        if not (Root and Humanoid) then return end

        if not Corners then
            local Origin = Root.Position

            Corners = {
                Origin + Vector3.new(14, 0, 0),
                Origin + Vector3.new(14, 0, 14),
                Origin + Vector3.new(0, 0, 14),
                Origin
            }

            Log("walking a 14 stud square from " .. tostring(Origin))
        end

        Humanoid:MoveTo(Corners[Index])

        Index = Index % #Corners + 1
    end
end

-- what the hub used to do: WalkSpeed written by the client, which replicates to the server
Tests["04_walkspeed"] = function(Tick)
    local Humanoid = GetHumanoid()

    if not Humanoid then return end

    if Humanoid.WalkSpeed ~= 18 then
        Humanoid.WalkSpeed = 18

        Log("set Humanoid.WalkSpeed = 18")
    end

    if Tick % 5 == 0 then
        local Root = GetRootPart()

        if Root then
            Humanoid:MoveTo(Root.Position + Vector3.new(12, 0, 0))
        end
    end
end

-- what the hub used to do: touches fired at eggs the character is not touching
Tests["05_touch_eggs"] = function(Tick)
    if Tick % 2 ~= 0 then return end

    if type(firetouchinterest) ~= "function" then
        Log("executor has no firetouchinterest")

        return
    end

    local Root = GetRootPart()
    local Folder = workspace:FindFirstChild("NestEggs")

    if not (Root and Folder) then return end

    local Fired = 0

    for _, Egg in ipairs(Folder:GetChildren()) do
        if Egg:IsA("BasePart") and Egg:GetAttribute("owner") == LocalPlayer.UserId then
            if (Egg.Position - Root.Position).Magnitude <= 6 then
                firetouchinterest(Root, Egg, 0)
                firetouchinterest(Root, Egg, 1)

                Fired = Fired + 1
            end
        end
    end

    if Fired > 0 then
        Log("fired " .. Fired .. " egg touches")
    end
end

-- the replacement: walk to the egg and let the server hand it over
Tests["06_walk_eggs"] = function(Tick)
    if Tick % 2 ~= 0 then return end

    local Root = GetRootPart()
    local Humanoid = GetHumanoid()
    local Folder = workspace:FindFirstChild("NestEggs")

    if not (Root and Humanoid and Folder) then return end

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

    if not Best or BestDistance <= 3 then return end

    Humanoid:MoveTo(Best.Position)

    if Tick % 20 == 0 then
        Log(string.format("walking to an egg %.1f studs away", BestDistance))
    end
end

-- scrap: walk to a piece, carry it to the recycler, repeat
Tests["07_grab_scrap"] = function(Tick)
    local Root = GetRootPart()
    local Humanoid = GetHumanoid()

    if not (Root and Humanoid) then return end

    local Carry = LocalPlayer:GetAttribute("scrapCarry") or 0
    local Target

    if Carry >= 6 then
        Target = PartOf(PlotModel("Recyclers", "Recycler"))
    else
        Target = NearestStack(Root.Position)
    end

    if not Target then return end

    Humanoid:MoveTo(Target.Position)

    if Tick % 20 == 0 then
        Log(string.format("carrying %d, walking to %s", Carry, Target:GetFullName()))
    end
end

-- what the hub used to do: plot remotes fired from wherever the character happens to be.
-- The coop buttons are ProximityPrompts with MaxActivationDistance 8.4, so a player can
-- only ever send these from right next to the coop.
Tests["08_remote_far"] = function(Tick)
    if Tick % 20 ~= 0 then return end

    local Coop = GetData("coop")
    local Root = GetRootPart()
    local CoopPart = PartOf(PlotModel("Coops", "Coop"))

    if Root and CoopPart then
        Log(string.format("standing %.1f studs from the coop", (CoopPart.Position - Root.Position).Magnitude))
    end

    if type(Coop) == "table" and type(Coop.generators) == "table" then
        local Slot = Coop.generators[1] and Coop.generators[1].slot

        if Slot then
            Invoke("UpgradeGenerator", Slot)
        else
            Invoke("BuyGenerator", 1)
        end
    end

    Invoke("UpgradeRecycler")
end

-- the replacement: the same remotes, but only once standing inside the prompt's range
Tests["09_remote_near"] = function(Tick)
    if Tick % 10 ~= 0 then return end

    if AtPrompt("Coops", "CoopUI") then
        local Coop = GetData("coop")

        if type(Coop) == "table" and type(Coop.generators) == "table" then
            local Slot = Coop.generators[1] and Coop.generators[1].slot

            if Slot then
                Invoke("UpgradeGenerator", Slot)
            else
                Invoke("BuyGenerator", 1)
            end
        end
    else
        if Tick % 40 == 0 then
            Log("walking to the coop prompt")
        end
    end
end

-- hatching, which is a 2d window in the real client and needs no position
Tests["10_hatch"] = function(Tick)
    if Tick % 20 ~= 0 then return end

    local Roster = GetData("roster")

    if not (type(Roster) == "table" and type(Roster.eggs) == "table") then return end

    for Tier, Count in pairs(Roster.eggs) do
        if type(Count) == "number" and Count > 0 then
            if Count > 1 then
                Invoke("HatchEggs", Tier, math.min(Count, 10))
            else
                Invoke("HatchEgg", Tier)
            end

            return
        end
    end

    Log("no eggs to hatch")
end

-- selling and fusing, also 2d window work
Tests["11_sell_fuse"] = function(Tick)
    if Tick % 20 ~= 0 then return end

    local Roster = GetData("roster")

    if type(Roster) ~= "table" then return end

    local Spare = { }

    for _, Chicken in ipairs(Roster.chickens or { }) do
        if Chicken.id ~= Roster.activeId and Chicken.favorite ~= true then
            table.insert(Spare, Chicken)
        end
    end

    Log("spare chickens: " .. #Spare)

    if #Spare >= 2 then
        Invoke("FuseChickens", Spare[1].id, Spare[2].id, { }, nil, "a")
    elseif #Spare == 1 then
        Invoke("SellChickens", { Spare[1].id })
    end
end

-- the reward claims
Tests["12_claims"] = function(Tick)
    Scan()

    if Tick % 20 ~= 0 then return end

    Invoke("DailyClaim", "day", nil)

    local Missions = GetData("missions")

    if Modules.MissionView and type(Missions) == "table" then
        local Snapshot = {
            roster = GetData("roster"),
            towerBest = type(GetData("tower")) == "table" and GetData("tower").best or 0,
            rebirthCount = type(GetData("rebirth")) == "table" and GetData("rebirth").count or 0,
            recyclerLevel = type(GetData("scrap")) == "table" and GetData("scrap").recyclerLevel or 0,
            missions = Missions
        }

        for _, Scope in ipairs(Modules.MissionView.SCOPES) do
            for _, Mission in ipairs(Modules.MissionView.active(Scope)) do
                if Mission.kind == nil and Modules.MissionView.stateOf(Snapshot, Mission) == "ready" then
                    Invoke("MissionClaim", Mission.id)

                    return
                end
            end
        end
    end

    local Pass = GetData("pass")

    if Modules.PassView and type(Pass) == "table" then
        for Level = 1, 30 do
            if Modules.PassView.state(Pass, Level) == "claimable" then
                Invoke("PassClaim", Level, Modules.PassView.track(Level))

                return
            end
        end
    end
end

-- ordering the chicken about, which is the one remote the hub fires most often
Tests["13_chicken_order"] = function(Tick)
    if Tick % 20 ~= 0 then return end

    local Body = MyChickenBody()

    if not Body then
        Log("no chicken body of ours in workspace")

        return
    end

    local State = Body:GetAttribute("ovState")

    Log("chicken state = " .. tostring(State))

    if State == "pit" then
        Fire("SetChickenOrder", "coop")
    else
        Fire("SetChickenOrder", "chaos")
    end
end

-- tower runs
Tests["14_tower"] = function(Tick)
    if Tick % 40 ~= 0 then return end

    local Arenas = workspace:FindFirstChild("Arenas")
    local Arena = Arenas and Arenas:FindFirstChild("Arena" .. tostring(MyPlot()))

    if not Arena then
        Log("no arena for this plot")

        return
    end

    if Arena:GetAttribute("TowerActive") == true then
        Invoke("TowerSurrender")
    else
        Invoke("TowerStart")
    end
end

-- cheering, which the hub fires while the chicken is in the pit
Tests["15_encourage"] = function(Tick)
    Scan()

    if Tick % 20 ~= 0 then return end

    local Body = MyChickenBody()

    if not (Body and Body:GetAttribute("ovState") == "pit") then
        Log("chicken is not in the pit; send it there first or this test does nothing")

        return
    end

    local Root = GetRootPart()

    if Root and Modules.PitZone then
        local Offset = Root.Position - Modules.PitZone.center

        Log(string.format("%.1f studs from the pit centre", Vector3.new(Offset.X, 0, Offset.Z).Magnitude))
    end

    Invoke("EncourageChicken")
end

---- ============ Runner ============ ----

local Step = Tests[TEST]

if not Step then
    local Names = { }

    for Name in pairs(Tests) do
        table.insert(Names, Name)
    end

    table.sort(Names)

    Log("unknown test " .. tostring(TEST) .. "; pick one of: " .. table.concat(Names, ", "))

    return
end

Log(string.format("running %s for %d seconds (plot %s)", TEST, RUN_SECONDS, tostring(MyPlot())))

task.spawn(function()
    local Tick = 0

    while os.clock() - StartedAt < RUN_SECONDS do
        Tick = Tick + 1

        local Ok, Err = pcall(Step, Tick)

        if not Ok then
            Log("step errored: " .. tostring(Err))
        end

        if Tick % 40 == 0 then
            Log("still connected")
        end

        task.wait(0.25)
    end

    Log("---- finished without a kick ----")
end)
