-- ServerScriptService.Combat.RagdollService
-- Owns the physical side of the knockdown ragdoll.
--
-- Humanoid attribute "RagdollEnabled" is the switch, and it was already the switch
-- used by the melee tools and read by CombatService, so setting it from anywhere on
-- the server knocks the character down. This script turns that flag into actual limp
-- joints; StarterPlayerScripts.Systems handles the victim's own input freeze and the
-- "RagdollVelocity" impulse.
--
-- Player characters are prepared up front, because RagdollMod.Setup needs a frame to
-- see every limb. Anything else with a Humanoid -- NPCs, dummies -- is prepared the
-- first time it is actually knocked down, so the taser works on them too.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RagdollMod = require(ReplicatedStorage.GameSettings.Modules.RagdollMod)

local READY_ATTRIBUTE = "PXRagdollReady"
local watched = {}

local function bind(character, humanoid)
	if watched[humanoid] then return end
	watched[humanoid] = true

	humanoid.AttributeChanged:Connect(function(name)
		if name ~= "RagdollEnabled" then return end
		local enabled = humanoid:GetAttribute("RagdollEnabled") == true
		if enabled and not character:GetAttribute(READY_ATTRIBUTE) then
			RagdollMod.Setup(character)
		end
		RagdollMod.SetRagdolled(character, enabled)
	end)

	-- Hand the corpse back to MakeCorpse with ordinary joints.
	humanoid.Died:Connect(function()
		RagdollMod.Cleanup(character)
	end)

	humanoid.Destroying:Connect(function()
		watched[humanoid] = nil
	end)
end

local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then return end
	if not character:WaitForChild("HumanoidRootPart", 10) then return end

	-- Accessories and limbs finish welding a frame after the character appears.
	task.wait()
	if not character.Parent then return end

	RagdollMod.Setup(character)
	humanoid:SetAttribute("RagdollEnabled", false)
	bind(character, humanoid)
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		task.spawn(onCharacterAdded, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- Non-player rigs: watch only, and build the constraints on first knockdown.
local function watchNonPlayer(humanoid)
	if not humanoid:IsA("Humanoid") then return end
	local character = humanoid.Parent
	if not character or not character:IsA("Model") then return end
	if Players:GetPlayerFromCharacter(character) then return end
	if humanoid:GetAttribute("RagdollEnabled") == nil then
		humanoid:SetAttribute("RagdollEnabled", false)
	end
	bind(character, humanoid)
end

for _, descendant in ipairs(workspace:GetDescendants()) do
	if descendant:IsA("Humanoid") then
		task.spawn(watchNonPlayer, descendant)
	end
end
workspace.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("Humanoid") then
		task.defer(watchNonPlayer, descendant)
	end
end)
