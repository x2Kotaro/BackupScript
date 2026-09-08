--!strict
-- Server-only weapon logic, keyed by Tool.Name.
--
-- Info.lua inside a Tool replicates to whichever client is holding it -- that is how
-- CWS ships spread/animations/effects to the client that needs to predict them. Any
-- code left in Info.custom_server would replicate the same way: an exploiter could
-- open the tool's ModuleScript and read the exact stun duration, knockback force and
-- damage thresholds, or call the function directly client-side. This module holds
-- that logic instead. It is never parented under a Tool, so it never reaches a client.
--
-- CwsServer looks a weapon up here after resolving damage; if there is no entry, the
-- weapon has no server-only behaviour and this module is skipped entirely.

local Debris = game:GetService("Debris")

type Hit = {
	player: Player,
	target: Humanoid,
	tool: Tool,
	damage: number,
	velocity: any,
	hit_name: string?,
}

local Weapons: { [string]: { damage: (info: any, hit: Hit) -> () } } = {}

-- "ปืนช็อตไฟฟ้ารัวเร็ว" (เทเซอร์) -- stun the target for 5s and shove them, once per stun.
Weapons["ปืนช็อตไฟฟ้ารัวเร็ว"] = {
	damage = function(_info, hit)
		local target = hit.target
		if target:GetAttribute("RagdollEnabled") ~= false then
			return
		end

		local zap = Instance.new("Sound")
		zap.SoundId = "rbxassetid://277635663"
		zap.Parent = hit.tool.Handle
		zap:Play()
		Debris:AddItem(zap, 6)

		target:SetAttribute("RagdollEnabled", true)

		local torso = target.Parent and target.Parent:FindFirstChild("Torso")
		if torso then
			torso.Velocity = Vector3.new(math.random(-100, 100), math.random(-100, 100), math.random(-100, 100))

			local attachment = Instance.new("Attachment")
			attachment.Parent = torso

			local force = Instance.new("VectorForce")
			force.Attachment0 = attachment
			force.Force = Vector3.new(0, 0, 3000)
			force.Parent = torso

			Debris:AddItem(force, 0.1)
			Debris:AddItem(attachment, 0.1)
		end

		task.wait(5)
		if target.Parent then
			target:SetAttribute("RagdollEnabled", false)
		end
	end,
}

return Weapons
