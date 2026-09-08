--!strict
-- Quasar — server-side melee combat handler.
-- Rebuilt from the saved instance dump (ServerStorage.Quasar); the original
-- server Script could not be extracted from the live place.
--
-- Tool attributes drive the numbers:
--   Damage       base damage per hit
--   Speed        seconds between swings
--   BonusDamage  extra damage accumulated from kills (Pros: 적 처치시 공격력 증가)
--   IsSword/Type/Pale  metadata kept from the original tool

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local tool = script.Parent :: Tool
local handle = tool:WaitForChild("Handle") :: BasePart
local swingSound = handle:FindFirstChild("Swing") :: Sound?
local hitSound = handle:FindFirstChild("Oof") :: Sound?

local BONUS_PER_KILL = 5
local MAX_BONUS = 100
local HIT_WINDOW = 0.45 -- seconds after activation that the blade stays live
local FRIENDLY_FIRE = false

local swinging = false
local cooling = false
local hitThisSwing: { [Humanoid]: boolean } = {}

local function getCharacter(): Model?
	local parent = tool.Parent
	return (parent and parent:IsA("Model") and parent:FindFirstChildOfClass("Humanoid")) and parent or nil
end

local function getOwner(): Player?
	local character = getCharacter()
	return character and Players:GetPlayerFromCharacter(character) or nil
end

local function sameTeam(a: Player, b: Player): boolean
	return a.Team ~= nil and a.Team == b.Team and not a.Neutral and not b.Neutral
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

local function currentDamage(): number
	local base = tool:GetAttribute("Damage") or 0
	local bonus = tool:GetAttribute("BonusDamage") or 0
	return (base :: number) + (bonus :: number)
end

local function rewardKill()
	local bonus = (tool:GetAttribute("BonusDamage") or 0) :: number
	tool:SetAttribute("BonusDamage", math.min(bonus + BONUS_PER_KILL, MAX_BONUS))
end

handle.Touched:Connect(function(hit: BasePart)
	if not swinging then
		return
	end

	local character = getCharacter()
	if not character then
		return
	end

	local target = hit:FindFirstAncestorOfClass("Model")
	if not target or target == character then
		return
	end

	local humanoid = target:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or hitThisSwing[humanoid] then
		return
	end

	local owner = getOwner()
	local victim = Players:GetPlayerFromCharacter(target)
	if owner and victim and not FRIENDLY_FIRE and sameTeam(owner, victim) then
		return
	end

	hitThisSwing[humanoid] = true

	if owner then
		tagCreator(humanoid, owner)
	end

	humanoid:TakeDamage(currentDamage())

	if hitSound then
		hitSound:Play()
	end

	if humanoid.Health <= 0 then
		rewardKill()
	end
end)

tool.Activated:Connect(function()
	if cooling then
		return
	end
	cooling = true

	table.clear(hitThisSwing)
	swinging = true

	if swingSound then
		swingSound:Play()
	end

	task.delay(HIT_WINDOW, function()
		swinging = false
	end)

	task.wait((tool:GetAttribute("Speed") or 0.7) :: number)
	cooling = false
end)

tool.Unequipped:Connect(function()
	swinging = false
	table.clear(hitThisSwing)
end)
