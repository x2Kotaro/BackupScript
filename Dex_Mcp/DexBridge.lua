--[[
	DexBridge.lua
	Connects a running Dex++ (out.lua) instance to the local Dex_Mcp server,
	so Claude can read the instance tree, properties, and decompiled scripts.

	Run this inside your executor. It will:
	  1. Load Dex++ (patched so its internals are reachable), or reuse one already loaded.
	  2. Long-poll http://127.0.0.1:8790/cmd and execute whatever the MCP server sends.

	Stop it later with:  getgenv().DexBridgeStop()
]]

local CONFIG = {
	Host = "http://127.0.0.1:8790",
	Token = "", -- must match DEX_MCP_TOKEN on the server; "" = disabled
	Gap = 0.05, -- seconds between polls when idle
	MaxNodes = 2000, -- hard cap on nodes returned by dex_tree
	MaxDepth = 5, -- hard cap on dex_tree depth
	MaxString = 4000, -- truncate long string values (decompile output is exempt)
	AntiAFK = true, -- prevent 20-minute idle disconnects (set false to disable)

	-- Where to get the Dex++ source when it is not already loaded.
	-- Leave DexUrl empty to rely on getgenv().DexSource or a local out.lua file.
	DexUrl = "",
	DexFile = "out.lua",

	-- Where to get *this* file back from after a teleport. A teleport keeps the executor
	-- injected but throws away every Lua state it holds, so the bridge has to hand itself
	-- to queue_on_teleport to survive one. File is tried first, then URL.
	BridgeFile = "DexBridge.lua",
	BridgeUrl = "",
}

---------------------------------------------------------------------------
-- 1. Get Dex++ loaded with its internals exported
---------------------------------------------------------------------------

local ANCHOR = "Main.AppControls.Lib.InitAfterMain(appTable)"
local INJECT = "getgenv().DexMain = Main getgenv().DexApps = appTable "

local function patchAndLoad(src)
	local at = string.find(src, ANCHOR, 1, true)
	if not at then
		error("DexBridge: anchor not found in Dex source. Dex++ version changed - update ANCHOR in DexBridge.lua.")
	end
	src = string.sub(src, 1, at - 1) .. INJECT .. string.sub(src, at)

	local chunk, err = loadstring(src, "=DexPlusPlus")
	if not chunk then
		error("DexBridge: failed to compile patched Dex source: " .. tostring(err))
	end
	task.spawn(chunk)

	local deadline = os.clock() + 60
	while not getgenv().DexMain and os.clock() < deadline do
		task.wait(0.1)
	end
	if not getgenv().DexMain then
		error("DexBridge: Dex++ loaded but never reached LoadModules within 60s.")
	end
end

local function ensureDex()
	if getgenv().DexMain then
		return
	end

	local src = getgenv().DexSource

	if not src and CONFIG.DexFile ~= "" and isfile and isfile(CONFIG.DexFile) then
		src = readfile(CONFIG.DexFile)
	end

	if not src and CONFIG.DexUrl ~= "" then
		local ok, body = pcall(game.HttpGet, game, CONFIG.DexUrl, true)
		if ok then src = body end
	end

	if not src then
		error(
			"DexBridge: no Dex++ source found.\n"
				.. "Do one of these before running DexBridge.lua:\n"
				.. "  - set CONFIG.DexUrl to a raw URL of out.lua, or\n"
				.. "  - put out.lua in your executor's workspace folder, or\n"
				.. "  - set getgenv().DexSource = <the source string>."
		)
	end

	patchAndLoad(src)
end

ensureDex()

local Main = getgenv().DexMain
local deps = Main.GetInitDeps()
local API = deps.API
local env = deps.env
local service = deps.service
local Apps = deps.Apps
local Explorer = Apps.Explorer

local HttpService = service.HttpService
local LogService = (function()
	local ok, svc = pcall(function()
		return service.LogService
	end)
	if ok and svc then return svc end
	return game:GetService("LogService")
end)()
local request = env.request
	or (syn and syn.request)
	or http_request
	or (http and http.request)
	or request

if type(request) ~= "function" then
	error("DexBridge: your executor exposes no HTTP request function. Cannot bridge.")
end

---------------------------------------------------------------------------
-- 2. Serialization helpers (everything below must be JSON-safe)
---------------------------------------------------------------------------

local function safePath(inst)
	local ok, full = pcall(function()
		return inst:GetFullName()
	end)
	if ok then return full end
	return "<" .. tostring(inst) .. ">"
end

local function clampString(s)
	if #s > CONFIG.MaxString then
		return string.sub(s, 1, CONFIG.MaxString) .. ("... <truncated, %d chars total>"):format(#s)
	end
	return s
end

local function serialize(v)
	local t = typeof(v)

	if t == "boolean" then
		return v
	elseif t == "string" then
		return clampString(v)
	elseif t == "number" then
		-- JSON has no NaN / Infinity
		if v ~= v or v == math.huge or v == -math.huge then
			return tostring(v)
		end
		return v
	elseif t == "nil" then
		return { __type = "nil" }
	elseif t == "Instance" then
		return { __type = "Instance", Class = v.ClassName, Name = v.Name, Path = safePath(v) }
	elseif t == "EnumItem" then
		return { __type = "EnumItem", Value = tostring(v) }
	elseif t == "table" then
		local out, n = {}, 0
		for k, val in pairs(v) do
			n = n + 1
			if n > 200 then
				out.__truncated = true
				break
			end
			out[tostring(k)] = serialize(val)
		end
		return out
	else
		return { __type = t, Value = clampString(tostring(v)) }
	end
end

---------------------------------------------------------------------------
-- 3. Path resolution
---------------------------------------------------------------------------

local function resolve(args)
	local parts = args.path_parts

	if not parts then
		local path = args.path
		if path == nil or path == "" or path == "game" then
			return game
		end
		parts = string.split(path, ".")
	end

	local current = game
	local start = 1
	if parts[1] == "game" or parts[1] == "Game" then
		start = 2
	end

	for i = start, #parts do
		local name = parts[i]
		local nextInst = current:FindFirstChild(name)

		if not nextInst and current == game then
			local ok, svc = pcall(game.GetService, game, name)
			if ok then nextInst = svc end
		end

		if not nextInst then
			error(("path not found: %q under %s"):format(name, safePath(current)), 0)
		end
		current = nextInst
	end

	return current
end

---------------------------------------------------------------------------
-- 4. Operation handlers
---------------------------------------------------------------------------

local handlers = {}

function handlers.status()
	local placeInfo = {
		PlaceId = game.PlaceId,
		GameId = game.GameId,
		JobId = game.JobId,
	}
	local ok, name = pcall(function()
		return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
	end)

	return {
		connected = true,
		dex_elevated = Main.Elevated,
		place = placeInfo,
		place_name = ok and name or nil,
		local_player = game:GetService("Players").LocalPlayer
				and game:GetService("Players").LocalPlayer.Name
			or nil,
		decompiler_available = typeof(env.decompile) == "function",
	}
end

function handlers.tree(args)
	local root = resolve(args)
	local depth = math.clamp(tonumber(args.depth) or 2, 0, CONFIG.MaxDepth)
	local budget = CONFIG.MaxNodes
	local hitCap = false

	local function build(inst, d)
		local children = inst:GetChildren()
		local node = {
			Name = inst.Name,
			Class = inst.ClassName,
			ChildCount = #children,
		}

		if d > 0 and #children > 0 then
			node.Children = {}
			for _, child in ipairs(children) do
				if budget <= 0 then
					hitCap = true
					break
				end
				budget = budget - 1
				table.insert(node.Children, build(child, d - 1))
			end
		end

		return node
	end

	return {
		Path = safePath(root),
		Depth = depth,
		Truncated = hitCap,
		Root = build(root, depth),
	}
end

function handlers.props(args)
	local inst = resolve(args)
	local className = inst.ClassName
	local filter = args.filter and string.lower(args.filter) or nil
	local includeHidden = args.include_hidden == true

	local members = API.GetMember(className, "Properties")
	if not members then
		return { Path = safePath(inst), Class = className, Error = "class not present in API dump" }
	end

	local out = {}
	for _, member in ipairs(members) do
		local tags = member.Tags or {}
		local hidden = tags.Hidden or tags.Deprecated or tags.NotScriptable or tags.ReadOnly

		local pass = includeHidden or not (tags.Hidden or tags.Deprecated or tags.NotScriptable)
		if pass and filter then
			pass = string.find(string.lower(member.Name), filter, 1, true) ~= nil
		end

		if pass then
			local entry = {
				Name = member.Name,
				Category = member.Category,
				Type = member.ValueType and member.ValueType.Name or "unknown",
				Hidden = hidden or nil,
			}

			local ok, value = pcall(function()
				return inst[member.Name]
			end)

			if not ok and typeof(gethiddenproperty) == "function" then
				local ok2, value2 = pcall(gethiddenproperty, inst, member.Name)
				ok, value = ok2, value2
			end

			if ok then
				entry.Value = serialize(value)
			else
				entry.Error = clampString(tostring(value))
			end

			table.insert(out, entry)
		end
	end

	return { Path = safePath(inst), Class = className, Count = #out, Properties = out }
end

function handlers.decompile(args)
	local inst = resolve(args)

	if not inst:IsA("LuaSourceContainer") then
		error(("%s is a %s, not a script"):format(safePath(inst), inst.ClassName), 0)
	end
	if typeof(env.decompile) ~= "function" then
		error("no decompiler available in this executor / Dex configuration", 0)
	end

	local ok, source = pcall(env.decompile, inst)
	if not ok then
		error("decompile failed: " .. tostring(source), 0)
	end

	return { Path = safePath(inst), Class = inst.ClassName, Source = tostring(source) }
end

function handlers.exec(args)
	local code = args.code
	if type(code) ~= "string" or code == "" then
		error("exec requires a non-empty `code` string", 0)
	end

	local chunk, compileErr = loadstring(code, "=DexMcpExec")
	if not chunk then
		error("compile error: " .. tostring(compileErr), 0)
	end

	local results = table.pack(pcall(chunk))
	if not results[1] then
		error("runtime error: " .. tostring(results[2]), 0)
	end

	local returned = {}
	for i = 2, results.n do
		table.insert(returned, serialize(results[i]))
	end

	return { ReturnCount = #returned, Returned = returned }
end

function handlers.select(args)
	local inst = resolve(args)
	Explorer.ViewObj(inst)
	return { Path = safePath(inst), Revealed = true }
end

local MessageKind = {
	[Enum.MessageType.MessageOutput] = "print",
	[Enum.MessageType.MessageInfo] = "info",
	[Enum.MessageType.MessageWarning] = "warn",
	[Enum.MessageType.MessageError] = "error",
}

-- Injection. exec() runs a chunk inline and waits for it, which is fine for a one-liner and
-- useless for a real script: anything that builds a UI and then loops forever would hold the
-- bridge until the server's timeout. This runs the chunk on its own thread instead, and only
-- listens to the console for a moment to report back what came out of it.
function handlers.inject(args)
	local source = args.source
	if type(source) ~= "string" or source == "" then
		error("inject requires a non-empty `source` string", 0)
	end

	local chunkName = (type(args.chunk_name) == "string" and args.chunk_name ~= "") and args.chunk_name or "DexMcpInject"
	local captureMs = math.clamp(tonumber(args.capture_ms) or 1500, 0, 10000)

	local chunk, compileErr = loadstring(source, "=" .. chunkName)
	if not chunk then
		error("compile error: " .. tostring(compileErr), 0)
	end

	-- the scripts in this repo park their teardown in getgenv() (ValkyrieCleanup); calling it
	-- before the new copy runs is what keeps a re-inject from stacking two windows and two
	-- sets of loops on the same character
	local cleanupName = args.cleanup
	local cleanupRan = false

	if type(cleanupName) == "string" and cleanupName ~= "" then
		local fn = getgenv()[cleanupName]
		if type(fn) == "function" then
			cleanupRan = pcall(fn)
			task.wait(0.1)
		end
	end

	local lines = {}
	local connection

	if captureMs > 0 then
		connection = LogService.MessageOut:Connect(function(text, messageType)
			if #lines < 200 then
				table.insert(lines, {
					Type = MessageKind[messageType] or tostring(messageType),
					Text = clampString(tostring(text)),
				})
			end
		end)
	end

	local finished, ok, err = false, nil, nil

	task.spawn(function()
		ok, err = xpcall(chunk, function(e)
			return debug.traceback(tostring(e), 2)
		end)
		finished = true
	end)

	local deadline = os.clock() + captureMs / 1000
	while os.clock() < deadline and not (finished and not ok) do
		task.wait(0.05)
	end

	if connection then
		connection:Disconnect()
	end

	return {
		Chunk = chunkName,
		-- a script still running when the window closed is the normal result for anything
		-- with a UI; "returned" means it ran to the end, "errored" is the one to read
		Status = finished and (ok and "returned" or "errored") or "running",
		Error = (finished and not ok) and clampString(tostring(err)) or nil,
		CleanupCalled = cleanupRan and cleanupName or nil,
		CaptureMs = captureMs,
		OutputCount = #lines,
		Output = lines,
	}
end

-- Remote spy.
--
-- Every FireServer / InvokeServer the client makes, from any script, with the script that
-- made the call. This exists because a kick can arrive while the injected script is doing
-- nothing at all, and the only way to tell "we sent something" from "one of the game's own
-- client scripts reported us" is to watch the wire rather than the hub.
--
-- The hook is installed once and left in place; start / stop only decide whether records
-- are kept, because unhooking a namecall metamethod is the part that goes wrong.
local Spy = {
	installed = false,
	recording = false,
	incoming = false,
	seq = 0,
	dropped = 0,
	max = 600,
	records = {},
	connections = {},
	watched = {},
	growers = {},
	startedAt = 0,
}

local function spyShort(value, depth)
	depth = depth or 0
	local kind = typeof(value)

	if kind == "Instance" then
		return value.ClassName .. "(" .. value.Name .. ")"
	elseif kind == "table" then
		if depth > 1 then
			return "{...}"
		end

		local parts, n = {}, 0

		for k, v in pairs(value) do
			n = n + 1
			if n > 8 then
				table.insert(parts, "...")
				break
			end
			table.insert(parts, tostring(k) .. "=" .. spyShort(v, depth + 1))
		end

		return "{" .. table.concat(parts, ", ") .. "}"
	elseif kind == "string" then
		if #value > 120 then
			return string.format("%q(%d chars)", string.sub(value, 1, 120), #value)
		end
		return string.format("%q", value)
	end

	return tostring(value)
end

local function spyArgs(...)
	local parts = {}

	for i = 1, select("#", ...) do
		if i > 8 then
			table.insert(parts, "...")
			break
		end
		table.insert(parts, spyShort((select(i, ...))))
	end

	return table.concat(parts, ", ")
end

-- which script the call came from. A line naming one of the game's own scripts is the
-- interesting one: that is the game reporting, not us.
local function spyCaller()
	if not (debug and debug.info) then
		return "?"
	end

	for level = 2, 8 do
		local ok, src = pcall(debug.info, level, "s")

		if ok and type(src) == "string" and src ~= "" and src ~= "[C]" then
			if not string.find(src, "DexBridge", 1, true) and not string.find(src, "DexPlusPlus", 1, true) then
				return src
			end
		end
	end

	return "?"
end

local function spyRecord(direction, method, remote, ...)
	if not Spy.recording then
		return
	end

	Spy.seq = Spy.seq + 1

	local entry = {
		N = Spy.seq,
		At = math.floor((os.clock() - Spy.startedAt) * 100) / 100,
		Dir = direction,
		Method = method,
		Remote = remote and remote.Name or "?",
		Path = remote and safePath(remote) or "?",
		Class = remote and remote.ClassName or "?",
		Args = clampString(spyArgs(...)),
		From = direction == "out" and spyCaller() or nil,
	}

	table.insert(Spy.records, entry)

	while #Spy.records > Spy.max do
		table.remove(Spy.records, 1)
		Spy.dropped = Spy.dropped + 1
	end
end

local function spyInstall()
	if Spy.installed then
		return "already installed"
	end

	local notes = {}

	if hookmetamethod and getnamecallmethod and newcclosure then
		local original

		original = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
			local method = getnamecallmethod()

			if (method == "FireServer" or method == "InvokeServer") and typeof(self) == "Instance" then
				pcall(spyRecord, "out", method, self, ...)
			end

			return original(self, ...)
		end))

		table.insert(notes, "namecall hook")
	else
		table.insert(notes, "no namecall hook (executor lacks hookmetamethod/getnamecallmethod/newcclosure)")
	end

	-- remote.FireServer(remote, ...) never reaches __namecall, so the two functions are
	-- hooked directly as well where the executor allows it
	if hookfunction and newcclosure then
		local okFire = pcall(function()
			local proto = Instance.new("RemoteEvent").FireServer
			local old

			old = hookfunction(proto, newcclosure(function(self, ...)
				if typeof(self) == "Instance" then
					pcall(spyRecord, "out", "FireServer.", self, ...)
				end
				return old(self, ...)
			end))
		end)

		local okInvoke = pcall(function()
			local proto = Instance.new("RemoteFunction").InvokeServer
			local old

			old = hookfunction(proto, newcclosure(function(self, ...)
				if typeof(self) == "Instance" then
					pcall(spyRecord, "out", "InvokeServer.", self, ...)
				end
				return old(self, ...)
			end))
		end)

		table.insert(notes, ("direct hooks fire=%s invoke=%s"):format(tostring(okFire), tostring(okInvoke)))
	end

	Spy.installed = true

	return table.concat(notes, "; ")
end

-- Every RemoteEvent the client can reach, wherever it lives.
--
-- This used to look for one folder called "Remotes" and give up when there was none, which
-- meant it silently watched nothing in every game that names the folder something else --
-- Steal An Egg keeps its remotes in ReplicatedStorage.Network, and the spy reported zero
-- watched remotes there while the game was talking to the server the whole time.
--
-- So the services are swept whole, and DescendantAdded keeps up with remotes the game
-- creates later. The cap is there because a game with thousands of remotes would otherwise
-- cost thousands of live connections.
local SPY_SERVICES = { "ReplicatedStorage", "ReplicatedFirst", "Workspace", "Lighting" }
local SPY_WATCH_CAP = 600

local function spyIsListenable(instance)
	return instance:IsA("RemoteEvent") or instance:IsA("UnreliableRemoteEvent")
end

local function spyListen(remote)
	if Spy.watched[remote] then
		return false
	end

	if #Spy.connections >= SPY_WATCH_CAP then
		return false
	end

	local ok, conn = pcall(function()
		return remote.OnClientEvent:Connect(function(...)
			if Spy.incoming then
				pcall(spyRecord, "in", "OnClientEvent", remote, ...)
			end
		end)
	end)

	if not (ok and conn) then
		return false
	end

	Spy.watched[remote] = true
	table.insert(Spy.connections, conn)

	return true
end

local function spyWatchIncoming()
	local found = 0
	local places = {}

	for _, name in ipairs(SPY_SERVICES) do
		local ok, service = pcall(game.GetService, game, name)

		if ok and service then
			local before = #Spy.connections

			for _, instance in ipairs(service:GetDescendants()) do
				if spyIsListenable(instance) then
					found = found + 1
					spyListen(instance)
				end
			end

			local added = #Spy.connections - before

			if added > 0 then
				table.insert(places, string.format("%s=%d", name, added))
			end

			-- remotes the game parents in after the sweep are picked up as they appear
			if not Spy.growers[name] then
				local okGrow, grower = pcall(function()
					return service.DescendantAdded:Connect(function(instance)
						if spyIsListenable(instance) then
							spyListen(instance)
						end
					end)
				end)

				if okGrow and grower then
					Spy.growers[name] = grower
				end
			end
		end
	end

	return #Spy.connections, found, table.concat(places, ", ")
end

function handlers.spy(args)
	local action = type(args.action) == "string" and string.lower(args.action) or "read"

	if action == "start" then
		local note = spyInstall()

		Spy.recording = true
		Spy.incoming = args.incoming == true
		Spy.startedAt = os.clock()

		if type(args.max) == "number" then
			Spy.max = math.clamp(math.floor(args.max), 50, 2000)
		end

		table.clear(Spy.records)
		Spy.seq = 0
		Spy.dropped = 0

		local watched, found, places = 0, 0, ""

		if Spy.incoming then
			watched, found, places = spyWatchIncoming()
		end

		return {
			Action = "start",
			Hooks = note,
			Incoming = Spy.incoming,
			WatchedRemotes = watched,
			RemotesFound = found,
			WatchedIn = places ~= "" and places or nil,
			Buffer = Spy.max,
		}
	elseif action == "stop" then
		Spy.recording = false
		Spy.incoming = false

		return { Action = "stop", Recorded = #Spy.records }
	elseif action == "clear" then
		table.clear(Spy.records)
		Spy.seq = 0
		Spy.dropped = 0

		return { Action = "clear" }
	elseif action == "status" then
		return {
			Action = "status",
			Installed = Spy.installed,
			Recording = Spy.recording,
			Incoming = Spy.incoming,
			Held = #Spy.records,
			Dropped = Spy.dropped,
			Buffer = Spy.max,
			WatchedRemotes = #Spy.connections,
			SecondsRunning = Spy.recording and (math.floor((os.clock() - Spy.startedAt) * 10) / 10) or 0,
		}
	elseif action ~= "read" then
		error("unknown spy action: " .. tostring(args.action), 0)
	end

	local limit = math.clamp(tonumber(args.limit) or 50, 1, 300)
	local direction = type(args.direction) == "string" and string.lower(args.direction) or "both"
	local filter = (type(args.filter) == "string" and args.filter ~= "") and string.lower(args.filter) or nil
	local since = tonumber(args.since)

	local picked = {}

	-- newest first while picking so the cap keeps the latest, then flipped back
	for i = #Spy.records, 1, -1 do
		local entry = Spy.records[i]
		local pass = true

		if direction == "out" or direction == "in" then
			pass = entry.Dir == direction
		end

		if pass and since then
			pass = entry.N > since
		end

		if pass and filter then
			pass = string.find(string.lower(entry.Remote), filter, 1, true) ~= nil
				or string.find(string.lower(entry.Args), filter, 1, true) ~= nil
				or (entry.From ~= nil and string.find(string.lower(entry.From), filter, 1, true) ~= nil)
		end

		if pass then
			table.insert(picked, 1, entry)

			if #picked >= limit then
				break
			end
		end
	end

	return {
		Action = "read",
		Recording = Spy.recording,
		Held = #Spy.records,
		Dropped = Spy.dropped,
		Returned = #picked,
		Latest = Spy.seq,
		Calls = picked,
	}
end

-- the console backlog, for the error that lands after inject stopped listening
function handlers.console(args)
	local count = math.clamp(tonumber(args.count) or 50, 1, 300)
	local filter = (type(args.filter) == "string" and args.filter ~= "") and string.lower(args.filter) or nil
	local errorsOnly = args.errors_only == true

	local ok, history = pcall(function()
		return LogService:GetLogHistory()
	end)

	if not ok or type(history) ~= "table" then
		error("LogService:GetLogHistory() is not available here: " .. tostring(history), 0)
	end

	local picked = {}

	-- newest first while picking, so the cap keeps the most recent lines, then flipped back
	for i = #history, 1, -1 do
		local entry = history[i]
		local kind = MessageKind[entry.messageType] or tostring(entry.messageType)
		local text = tostring(entry.message)
		local pass = not errorsOnly or kind == "warn" or kind == "error"

		if pass and filter then
			pass = string.find(string.lower(text), filter, 1, true) ~= nil
		end

		if pass then
			table.insert(picked, 1, { Type = kind, Text = clampString(text), Time = entry.timestamp })
			if #picked >= count then
				break
			end
		end
	end

	return { Count = #picked, Total = #history, Lines = picked }
end

---------------------------------------------------------------------------
-- 5. Bridge loop
---------------------------------------------------------------------------

local function post(path, body)
	local headers = { ["Content-Type"] = "application/json" }
	if CONFIG.Token ~= "" then
		headers["X-Dex-Token"] = CONFIG.Token
	end
	return pcall(request, {
		Url = CONFIG.Host .. path,
		Method = "POST",
		Headers = headers,
		Body = body,
	})
end

local function get(path)
	local headers = {}
	if CONFIG.Token ~= "" then
		headers["X-Dex-Token"] = CONFIG.Token
	end
	return pcall(request, { Url = CONFIG.Host .. path, Method = "GET", Headers = headers })
end

if getgenv().DexBridgeStop then
	pcall(getgenv().DexBridgeStop)
	task.wait(0.2)
end

local running = true
local antiAfkConn

local function setupAntiAfk()
	local enable = CONFIG.AntiAFK
	if getgenv().DexAntiAFK ~= nil then
		enable = getgenv().DexAntiAFK
	end

	if not enable then return end

	local ok, err = pcall(function()
		local Players = game:GetService("Players")
		local VirtualUser = game:GetService("VirtualUser")
		local LocalPlayer = Players.LocalPlayer

		if not LocalPlayer then
			task.spawn(function()
				while not Players.LocalPlayer and running do
					task.wait(0.1)
				end
				if running and Players.LocalPlayer and not antiAfkConn then
					antiAfkConn = Players.LocalPlayer.Idled:Connect(function()
						pcall(function()
							VirtualUser:CaptureController()
							VirtualUser:ClickButton2(Vector2.new(0, 0))
						end)
					end)
					warn("[DexBridge] Anti-AFK enabled")
				end
			end)
			return
		end

		antiAfkConn = LocalPlayer.Idled:Connect(function()
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new(0, 0))
			end)
		end)
	end)

	if ok and antiAfkConn then
		warn("[DexBridge] Anti-AFK enabled")
	elseif not ok then
		warn("[DexBridge] Anti-AFK setup failed: " .. tostring(err))
	end
end

setupAntiAfk()

getgenv().DexBridgeStop = function()
	running = false
	getgenv().DexBridgeQueued = nil
	if antiAfkConn then
		pcall(function()
			antiAfkConn:Disconnect()
		end)
		antiAfkConn = nil
	end
	warn("[DexBridge] stopping")
end

---------------------------------------------------------------------------
-- Survive a teleport
--
-- Server hops, rejoins and the game's own TeleportService calls all end the Lua state the
-- bridge lives in, which is why the connection died on every session change. queue_on_teleport
-- hands the executor a chunk to run on the other side, so the bridge is back a second or two
-- after the new place loads without anyone re-pasting it.
--
-- This does not cover a crash or a fresh client launch - nothing survives those but an
-- autoexec entry, since the executor has to inject before any Lua of ours can run.
---------------------------------------------------------------------------

do
	local queueTeleport = queue_on_teleport or (syn and syn.queue_on_teleport)

	local function bridgeChunk()
		local parts = {}

		if CONFIG.BridgeFile ~= "" then
			table.insert(
				parts,
				string.format(
					"if isfile and isfile(%q) then Source = readfile(%q) end",
					CONFIG.BridgeFile,
					CONFIG.BridgeFile
				)
			)
		end

		if CONFIG.BridgeUrl ~= "" then
			table.insert(
				parts,
				string.format(
					"if type(Source) ~= 'string' then local Ok, Body = pcall(game.HttpGet, game, %q, true) if Ok then Source = Body end end",
					CONFIG.BridgeUrl
				)
			)
		end

		if #parts == 0 then
			return nil
		end

		return "local Source\n"
			.. table.concat(parts, "\n")
			.. "\nif type(Source) == 'string' and #Source > 0 then local Chunk = loadstring(Source, '=DexBridge') if Chunk then Chunk() end end"
	end

	if not queueTeleport then
		warn("[DexBridge] executor has no queue_on_teleport - the bridge will not survive a teleport")
	else
		local chunk = bridgeChunk()

		if not chunk then
			warn("[DexBridge] neither CONFIG.BridgeFile nor CONFIG.BridgeUrl is set - the bridge will not survive a teleport")
		else
			-- OnTeleport fires more than once per teleport, and every fire queues another copy
			getgenv().DexBridgeQueued = false

			local Players = game:GetService("Players")
			local LocalPlayer = Players.LocalPlayer

			LocalPlayer.OnTeleport:Connect(function()
				if getgenv().DexBridgeQueued then return end

				getgenv().DexBridgeQueued = true

				local ok, err = pcall(queueTeleport, chunk)

				if not ok then
					warn("[DexBridge] queue_on_teleport failed: " .. tostring(err))
				end
			end)

			warn("[DexBridge] armed for teleport")
		end
	end
end

task.spawn(function()
	warn("[DexBridge] connecting to " .. CONFIG.Host)
	local wasDown = true

	while running do
		local ok, res = get("/cmd")

		if not ok or not res then
			if not wasDown then
				warn("[DexBridge] server unreachable, retrying...")
				wasDown = true
			end
			task.wait(2)
		else
			if wasDown then
				warn("[DexBridge] connected")
				wasDown = false
			end

			local status = res.StatusCode or res.Status or 0

			if status == 200 and res.Body and #res.Body > 2 then
				local decoded
				local okDecode, err = pcall(function()
					decoded = HttpService:JSONDecode(res.Body)
				end)

				if okDecode and decoded and decoded.id then
					local handler = handlers[decoded.op]
					local okRun, result

					if handler then
						okRun, result = pcall(handler, decoded.args or {})
					else
						okRun, result = false, "unknown op: " .. tostring(decoded.op)
					end

					local payload
					local okEncode, encodeErr = pcall(function()
						payload = HttpService:JSONEncode({
							id = decoded.id,
							ok = okRun,
							data = okRun and result or tostring(result),
						})
					end)

					if not okEncode then
						payload = HttpService:JSONEncode({
							id = decoded.id,
							ok = false,
							data = "result was not JSON-encodable: " .. tostring(encodeErr),
						})
					end

					post("/result", payload)
				else
					warn("[DexBridge] bad command payload: " .. tostring(err))
				end
			elseif status == 401 then
				warn("[DexBridge] 401 - CONFIG.Token does not match DEX_MCP_TOKEN. Stopping.")
				running = false
			end

			task.wait(CONFIG.Gap)
		end
	end

	warn("[DexBridge] stopped")
end)

local opNames = {}
for name in pairs(handlers) do
	table.insert(opNames, name)
end
table.sort(opNames)
warn("[DexBridge] ready - ops: " .. table.concat(opNames, ", "))
