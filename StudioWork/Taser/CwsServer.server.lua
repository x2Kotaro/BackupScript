--!strict
-- CWS server — rebuilt for placeId 96256228241730.
--
-- The place is a saved-instance dump: every client-side piece of the CWS weapon
-- framework survived (ReplicatedStorage.Assets.Misc.CWS_Directory and
-- StarterPlayerScripts.Handlers.CwsClient + its CWS module), but ServerScriptService
-- was empty because server Scripts cannot be saved out of a running place.
--
-- This script is the missing server half. Its contract was read straight out of
-- CwsClient/CWS:
--
--   client -> server   Damage, Shoot, CastBullet, Tracer, HitEffect, BulletHole,
--                      BloodSplatter, PlaySound, SetHandleEffects, EmitHandleEffects
--   server -> client   RemoteSize (seed, once per player)
--                      every relayed event as (senderPlayer, payload)
--
-- CWS.FireRemote refuses to fire anything until the server has handed the client a
-- RemoteSize seed, so sending that seed is what switches every weapon on.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local remotes = ReplicatedStorage.Assets.Misc.CWS_Directory:WaitForChild("remos")

-- Events the server simply mirrors to everyone else for presentation. The client
-- drops the ones it sent itself, so FireAllClients is what the client expects.
local RELAYED = {
	Shoot = true,
	CastBullet = true,
	Tracer = true,
	HitEffect = true,
	BulletHole = true,
	BloodSplatter = true,
	PlaySound = true,
	SetHandleEffects = true,
	EmitHandleEffects = true,
}

-- Rate limits, in calls per second, per player per remote.
local RATE_LIMIT = {
	Damage = 30,
	Shoot = 25,
	CastBullet = 25,
	Tracer = 30,
	HitEffect = 40,
	BulletHole = 40,
	BloodSplatter = 20,
	PlaySound = 20,
	SetHandleEffects = 10,
	EmitHandleEffects = 40,
}
local DEFAULT_RATE = 20

-- Slack on top of the weapon's own numbers before a Damage packet is rejected.
local DAMAGE_TOLERANCE = 1.25
local RANGE_SLACK = 25

-- remote_size is CWS's replay guard: the client seeds Random.new(seed), burns one
-- number, then stamps every packet with the next one. Mirroring that sequence lets
-- us spot forged packets. Left non-strict by default: a desync would silently kill
-- every weapon in the game, which is worse than the exploit it blocks.
local STRICT_REMOTE_SIZE = false
local SEQUENCE_WINDOW = 64

type PlayerState = {
	seed: number,
	random: Random,
	expected: { number },
	buckets: { [string]: { tokens: number, last: number } },
}

local state: { [Player]: PlayerState } = {}

local function newState(player: Player): PlayerState
	local seed = math.floor(os.clock() * 1e6) % 2147483647 + player.UserId
	local random = Random.new(seed)
	random:NextNumber() -- the client burns the first draw too

	local expected = table.create(SEQUENCE_WINDOW)
	for i = 1, SEQUENCE_WINDOW do
		expected[i] = random:NextNumber()
	end

	return { seed = seed, random = random, expected = expected, buckets = {} }
end

local function allowed(player: Player, name: string): boolean
	local this = state[player]
	if not this then
		return false
	end

	local limit = RATE_LIMIT[name] or DEFAULT_RATE
	local bucket = this.buckets[name]
	local now = os.clock()

	if not bucket then
		bucket = { tokens = limit, last = now }
		this.buckets[name] = bucket
	end

	bucket.tokens = math.min(limit, bucket.tokens + (now - bucket.last) * limit)
	bucket.last = now

	if bucket.tokens < 1 then
		return false
	end

	bucket.tokens -= 1
	return true
end

-- Consumes the packet's remote_size out of the player's expected sequence.
local function verifySequence(player: Player, data: { [string]: any }): boolean
	local this = state[player]
	if not this then
		return false
	end

	local stamp = data.remote_size
	if typeof(stamp) ~= "number" then
		return not STRICT_REMOTE_SIZE
	end

	for index, value in ipairs(this.expected) do
		if math.abs(value - stamp) < 1e-9 then
			-- Anything before the match was dropped in flight. Slide the window past
			-- the value we just consumed and top it back up.
			for _ = 1, index do
				table.remove(this.expected, 1)
			end
			for _ = #this.expected + 1, SEQUENCE_WINDOW do
				table.insert(this.expected, this.random:NextNumber())
			end
			return true
		end
	end

	return not STRICT_REMOTE_SIZE
end

local function characterOf(player: Player): Model?
	local character = player.Character
	if not character or not character:FindFirstChildOfClass("Humanoid") then
		return nil
	end
	return character
end

-- The tool must actually be held by the sender.
local function heldTool(player: Player, tool: any): Tool?
	if typeof(tool) ~= "Instance" or not tool:IsA("Tool") then
		return nil
	end
	local character = characterOf(player)
	if not character or tool.Parent ~= character then
		return nil
	end
	return tool
end

local function weaponInfo(tool: Tool): { [string]: any }?
	local module = tool:FindFirstChild("Info")
	if not module or not module:IsA("ModuleScript") then
		return nil
	end

	local ok, info = pcall(require, module)
	if not ok or type(info) ~= "table" then
		warn(("[CWS] %s has an Info module that failed to load: %s"):format(tool.Name, tostring(info)))
		return nil
	end
	return info
end

local function maxDamageFor(info: { [string]: any }): number
	local best = 0
	local damage = info.damage
	if type(damage) == "table" then
		best = math.max(best, tonumber(damage.headshot) or 0, tonumber(damage.max) or 0)
	end
	local melee = info.melee_attack
	if type(melee) == "table" then
		best = math.max(best, tonumber(melee.damage) or 0)
	end
	return best * DAMAGE_TOLERANCE
end

local function tagCreator(humanoid: Humanoid, player: Player)
	local existing = humanoid:FindFirstChild("creator")
	if existing then
		existing:Destroy()
	end

	local tag = Instance.new("ObjectValue")
	tag.Name = "creator"
	tag.Value = player
	tag.Parent = humanoid
	Debris:AddItem(tag, 3)
end

local function onDamage(player: Player, data: any)
	if type(data) ~= "table" then
		return
	end

	local humanoid = data.target
	if typeof(humanoid) ~= "Instance" or not humanoid:IsA("Humanoid") or humanoid.Health <= 0 then
		return
	end

	local tool = heldTool(player, data.tool)
	if not tool then
		return
	end

	local info = weaponInfo(tool)
	if not info then
		return
	end

	local victim = humanoid.Parent
	if not victim or victim == player.Character then
		return
	end

	local damage = tonumber(data.damage)
	if not damage or damage <= 0 then
		return
	end

	local cap = maxDamageFor(info)
	if cap > 0 and damage > cap then
		warn(("[CWS] %s sent %.1f damage with %s, capped at %.1f"):format(player.Name, damage, tool.Name, cap))
		damage = cap
	end

	-- Range check against the shooter's reported head position.
	local origin = data.head
	local victimPart = victim:FindFirstChild("HumanoidRootPart") or victim.PrimaryPart
	if typeof(origin) == "Vector3" and victimPart and victimPart:IsA("BasePart") then
		local range = (tonumber(info.max_dist) or 100) + RANGE_SLACK
		if (origin - victimPart.Position).Magnitude > range then
			return
		end
	end

	tagCreator(humanoid, player)
	humanoid:TakeDamage(damage)

	-- Melee packets carry their own ragdoll duration.
	local ragdollTime = tonumber(data.ragdoll)
	if ragdollTime and ragdollTime > 0 and humanoid:GetAttribute("RagdollEnabled") == false then
		humanoid:SetAttribute("RagdollEnabled", true)
		task.delay(ragdollTime, function()
			if humanoid.Parent then
				humanoid:SetAttribute("RagdollEnabled", false)
			end
		end)
	end

	-- Weapon-specific server payload (the taser's stun lives here).
	local custom = info.custom_server
	if type(custom) == "table" and type(custom.damage) == "function" then
		task.spawn(function()
			local ok, err = pcall(custom.damage, info, {
				player = player,
				target = humanoid,
				tool = tool,
				damage = damage,
				velocity = data.velocity,
				hit_name = data.hit_name,
			})
			if not ok then
				warn(("[CWS] custom_server.damage for %s errored: %s"):format(tool.Name, tostring(err)))
			end
		end)
	end
end

local function bind(remote: RemoteEvent)
	local name = remote.Name

	if name == "Damage" then
		remote.OnServerEvent:Connect(function(player, data)
			if not allowed(player, name) then
				return
			end
			if type(data) == "table" and not verifySequence(player, data) then
				return
			end
			onDamage(player, data)
		end)
		return
	end

	if RELAYED[name] then
		remote.OnServerEvent:Connect(function(player, data)
			if not allowed(player, name) then
				return
			end
			if type(data) ~= "table" then
				return
			end
			if not verifySequence(player, data) then
				return
			end
			remote:FireAllClients(player, data)
		end)
	end
end

for _, remote in ipairs(remotes:GetChildren()) do
	if remote:IsA("RemoteEvent") then
		bind(remote)
	end
end
remotes.ChildAdded:Connect(function(child)
	if child:IsA("RemoteEvent") then
		bind(child)
	end
end)

-- RagdollEnabled has to exist and be false for the taser's stun branch to run.
local function onCharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid and humanoid:IsA("Humanoid") and humanoid:GetAttribute("RagdollEnabled") == nil then
		humanoid:SetAttribute("RagdollEnabled", false)
	end
end

local function onPlayerAdded(player: Player)
	state[player] = newState(player)
	remotes.RemoteSize:FireClient(player, state[player].seed)

	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	state[player] = nil
end)
