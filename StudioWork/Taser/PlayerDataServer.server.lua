--!strict
-- Minimal Replica bootstrap for placeId 96256228241730.
--
-- The place is a saved-instance dump, so ServerScriptService came back empty. Nothing
-- required Replica on the server, and ReplicaServer is what answers the client's
-- ReplicaRequestData handshake — so every client-side require(Replica) yielded forever.
-- That stalled Satchel (which builds BackpackGui), which stalled CwsClient, which is
-- why no CWS weapon could fire.
--
-- Requiring ReplicaServer here is what unblocks the chain; the per-player replica on
-- top of it exists so client code that reads player data has something to read. It is
-- session-only: the real game's DataStore layer is not part of this dump.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Replica = require(ReplicatedStorage.Modules.Shared.Replica)
local GameSettings = require(ReplicatedStorage.GameSettings)

local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, inner in pairs(value) do
		copy[key] = deepCopy(inner)
	end
	return copy
end

-- Token() errors on a duplicate name, and a player can rejoin inside one server.
local tokens: { [string]: any } = {}

local function tokenFor(name: string)
	local token = tokens[name]
	if not token then
		token = Replica.Token(name)
		tokens[name] = token
	end
	return token
end

local replicas: { [Player]: any } = {}

Replica.NewReadyPlayer:Connect(function(player: Player)
	local ok, err = pcall(function()
		local replica = Replica.New({
			Token = tokenFor(player.Name),
			Data = deepCopy(GameSettings.PLAYER_DATA_TEMPLATE),
		})
		replica:Subscribe(player)
		replica:Replicate()
		replicas[player] = replica
	end)

	if not ok then
		warn(("[PlayerData] could not build a replica for %s: %s"):format(player.Name, tostring(err)))
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local replica = replicas[player]
	replicas[player] = nil
	if replica and Replica.IsActive(replica) then
		pcall(function()
			replica:Destroy()
		end)
	end
end)
