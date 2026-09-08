--[[
    Valkyrie Hub | outgoing traffic spy

    Run this FIRST, on its own, then run whatever you want to test (GFC.lua, the hub, or
    nothing at all). It writes down every single thing this client sends to the server, no
    matter which script sent it -- the game's own scripts included.

    That last part is the point. The trace inside GFC.lua only sees calls GFC makes. If the
    kick comes while GFC is sitting there with every automation off, then either nothing is
    being sent (and the server is reacting to something else entirely) or one of the game's
    own client scripts is sending a report about us. This tells the two apart.

    Log file:  Valkyrie Hub/GFC/SpyLog.txt
    Console:   every line is printed as well

    After the kick, open the log and read the last few lines.
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

while not LocalPlayer do
    task.wait()

    LocalPlayer = Players.LocalPlayer
end

local LogFolder = "Valkyrie Hub"
local LogSubFolder = "Valkyrie Hub/GFC"
local LogFile = LogSubFolder .. "/SpyLog.txt"
local StartedAt = os.clock()

local function Log(Text)
    local Line = string.format("[spy] %6.1fs  %s", os.clock() - StartedAt, Text)

    print(Line)

    if not (writefile and isfolder and makefolder) then return end

    pcall(function()
        if not isfolder(LogFolder) then makefolder(LogFolder) end
        if not isfolder(LogSubFolder) then makefolder(LogSubFolder) end

        if appendfile and isfile and isfile(LogFile) then
            appendfile(LogFile, Line .. "\n")
        else
            writefile(LogFile, Line .. "\n")
        end
    end)
end

Log("---- spy start ---- " .. os.date("%X"))

---- ============ what the kick looks like ============ ----

task.spawn(function()
    local Ok, Overlay = pcall(function()
        return game:GetService("CoreGui").RobloxPromptGui.promptOverlay
    end)

    if Ok and Overlay then
        Overlay.ChildAdded:Connect(function(Child)
            if Child.Name == "ErrorPrompt" then
                Log("!!!! KICKED")
            end
        end)
    end
end)

---- ============ argument printing ============ ----

local function Short(Value, Depth)
    Depth = Depth or 0

    local Kind = typeof(Value)

    if Kind == "Instance" then
        return Value.ClassName .. "(" .. Value.Name .. ")"
    end

    if Kind == "table" then
        if Depth > 1 then return "{...}" end

        local Parts = { }
        local Count = 0

        for Key, Item in pairs(Value) do
            Count = Count + 1

            if Count > 6 then
                table.insert(Parts, "...")

                break
            end

            table.insert(Parts, tostring(Key) .. "=" .. Short(Item, Depth + 1))
        end

        return "{" .. table.concat(Parts, ", ") .. "}"
    end

    if Kind == "string" and #Value > 60 then
        return string.format("%q(%d chars)", Value:sub(1, 60), #Value)
    end

    return tostring(Value)
end

local function Args(...)
    local Parts = { }

    for Index = 1, select("#", ...) do
        if Index > 6 then
            table.insert(Parts, "...")

            break
        end

        table.insert(Parts, Short((select(Index, ...))))
    end

    return table.concat(Parts, ", ")
end

-- which script made the call. A line from the game's own client is the interesting case:
-- it would mean one of its scripts is reporting this session to the server.
local function Caller()
    if not (debug and debug.info) then return "?" end

    for Level = 2, 6 do
        local Ok, Source = pcall(debug.info, Level, "s")

        if Ok and type(Source) == "string" and Source ~= "" and not Source:find("spy", 1, true) then
            return Source
        end
    end

    return "?"
end

---- ============ the hook ============ ----

local Sent = 0

if hookmetamethod and getnamecallmethod and newcclosure then
    local Original

    Original = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local Method = getnamecallmethod()

        if (Method == "FireServer" or Method == "InvokeServer") and typeof(self) == "Instance" then
            Sent = Sent + 1

            Log(string.format("%s %s(%s)   from %s", Method, self:GetFullName(), Args(...), Caller()))
        end

        return Original(self, ...)
    end))

    Log("namecall hook installed")
else
    Log("no hookmetamethod/getnamecallmethod/newcclosure on this executor -- trying the plain hooks")
end

-- Some scripts call remote.FireServer(remote, ...) rather than remote:FireServer(...), and
-- that route never touches __namecall, so the two functions are hooked directly as well.
if hookfunction and newcclosure then
    local FireProto = Instance.new("RemoteEvent").FireServer
    local InvokeProto = Instance.new("RemoteFunction").InvokeServer

    local OldFire, OldInvoke

    OldFire = hookfunction(FireProto, newcclosure(function(self, ...)
        if typeof(self) == "Instance" then
            Sent = Sent + 1

            Log(string.format("FireServer. %s(%s)   from %s", self:GetFullName(), Args(...), Caller()))
        end

        return OldFire(self, ...)
    end))

    OldInvoke = hookfunction(InvokeProto, newcclosure(function(self, ...)
        if typeof(self) == "Instance" then
            Sent = Sent + 1

            Log(string.format("InvokeServer. %s(%s)   from %s", self:GetFullName(), Args(...), Caller()))
        end

        return OldInvoke(self, ...)
    end))

    Log("direct FireServer / InvokeServer hooks installed")
end

---- ============ the other half: what the server sends us ============ ----

-- A client-side detector usually gets its orders from somewhere, and a kick is often
-- preceded by the server asking a question. Every remote in the game's Remotes folder is
-- listened to, so anything arriving in the seconds before the disconnect is on record.
task.spawn(function()
    local Folder = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 20)

    if not Folder then
        Log("no ReplicatedStorage.Remotes folder")

        return
    end

    local Watched = 0

    for _, Remote in ipairs(Folder:GetChildren()) do
        if Remote:IsA("RemoteEvent") or Remote:IsA("UnreliableRemoteEvent") then
            Watched = Watched + 1

            Remote.OnClientEvent:Connect(function(...)
                Log(string.format("<- %s(%s)", Remote.Name, Args(...)))
            end)
        end
    end

    Log("listening to " .. Watched .. " server -> client remotes")
end)

---- ============ heartbeat ============ ----

task.spawn(function()
    while true do
        task.wait(10)

        Log(string.format("alive, %d calls sent so far", Sent))
    end
end)
