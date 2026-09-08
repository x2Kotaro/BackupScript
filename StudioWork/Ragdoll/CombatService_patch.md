# CombatService edits

Two insertions in `ServerScriptService.Combat.CombatService`.

## 1. After `local hitscan = require(modules.Hitscan)`

```lua
-- Knockdown on a non-fatal hit. RagdollService turns the attribute into limp joints;
-- a fresh hit refreshes the timer instead of stacking timers on the same humanoid.
local knockdownTokens = {}

local function WeaponKnocksDown(tool)
	if typeof(tool) ~= "Instance" then return false end
	if tool:GetAttribute("HitRagdoll") then return true end
	local list = config.hitRagdollTools
	return (list and list[tool.Name]) == true
end

local function KnockDown(humanoid, direction, tool)
	if not config.hitRagdoll or not WeaponKnocksDown(tool) then return end
	if humanoid.Health <= 0 or humanoid:GetAttribute("RagdollEnabled") == nil then return end

	local force = config.hitRagdollForce or 12
	local lift = config.hitRagdollLift or 6
	local push = (direction or Vector3.zero) * force + Vector3.new(0, lift, 0)

	humanoid:SetAttribute("RagdollVelocity", push)
	humanoid:SetAttribute("RagdollEnabled", true)

	local token = (knockdownTokens[humanoid] or 0) + 1
	knockdownTokens[humanoid] = token

	task.delay(config.hitRagdollDuration or 5, function()
		if knockdownTokens[humanoid] ~= token then return end
		knockdownTokens[humanoid] = nil
		if humanoid.Parent and humanoid.Health > 0 then
			humanoid:SetAttribute("RagdollEnabled", false)
		end
	end)
end
```

## 2. Right after `humanoid:TakeDamage(damage)` and the hit-feedback block

```lua
		if not willKill then
			local shooterHead = player.Character and player.Character:FindFirstChild("Head")
			local targetRoot = humanoid.Parent and humanoid.Parent:FindFirstChild("HumanoidRootPart")
			local pushDirection
			if shooterHead and targetRoot then
				local offset = targetRoot.Position - shooterHead.Position
				if offset.Magnitude > 0 then pushDirection = offset.Unit end
			end
			KnockDown(humanoid, pushDirection, tool)
		end
```

## MapConfig additions

```lua
Config.ragdolls = true
-- Knockdown ragdoll when a shot lands but does not kill.
-- Only the weapons listed here do it; anything else damages normally. A tool can
-- also opt in on its own by carrying a HitRagdoll attribute set to true.
Config.hitRagdoll = true
Config.hitRagdollDuration = 5
Config.hitRagdollForce = 12
Config.hitRagdollLift = 6
Config.hitRagdollTools = {
	["ปืนช็อตไฟฟ้ารัวเร็ว"] = true,
	["연발 테이저건"] = true,
}
```

and inside `Config.PX_ITEMS`, before the `JETPACK` block:

```lua
	TASER = {
		DAMAGE = 3,
		RANGE = 120,
		RPM = 200,
		MAG = 3,
		RELOAD_TIME = 2,
		STUN_TIME = 5,
		STUN_KNOCKBACK = 12,
		STUN_LIFT = 0.5,
		MSG_RELOAD = "กำลังชาร์จเทเซอร์...",
	},
```
