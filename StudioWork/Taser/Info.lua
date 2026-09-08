-- Info config for the "연발 테이저건" (repeating taser) CWS weapon.
-- Recovered from the live place (placeId 96256228241730) and cleaned up.

return {
	fire_mode = 1,
	rpm = 200,
	equip_time = 0.2,
	reload_time = 2,
	max_ammo = 3,
	max_dist = 30,
	no_near_miss = true,

	damage = { max = 3, min = 1, headshot = 5 },

	spread = {
		min = 0,
		max = 0,
		min_running = 0,
		mult_running = 0,
		running = 0,
		jumping = 0,
		alpha = 1,
		decay_alpha = 1,
	},

	melee_attack = { damage = 30, ragdoll = 3, rate = 0.75 },

	-- Taser payload: ragdoll the target for 5s and shove them, once per stun.
	custom_server = {
		damage = function(_, hit)
			local target = hit.target
			if target:GetAttribute("RagdollEnabled") ~= false then
				return
			end

			local zap = Instance.new("Sound")
			zap.SoundId = "rbxassetid://277635663"
			zap.Parent = hit.tool.Handle
			zap:Play()
			game:GetService("Debris"):AddItem(zap, 6)

			target:SetAttribute("RagdollEnabled", true)

			local torso = target.Parent:FindFirstChild("Torso")
			if torso then
				torso.Velocity = Vector3.new(math.random(-100, 100), math.random(-100, 100), math.random(-100, 100))

				local attachment = Instance.new("Attachment")
				attachment.Parent = torso

				local force = Instance.new("VectorForce")
				force.Attachment0 = attachment
				force.Force = Vector3.new(0, 0, 3000)
				force.Parent = torso

				game:GetService("Debris"):AddItem(force, 0.1)
				game:GetService("Debris"):AddItem(attachment, 0.1)
			end

			task.wait(5)
			target:SetAttribute("RagdollEnabled", false)
		end,
	},

	icon = {
		id = "http://www.roblox.com/asset/?id=8451673209",
		ratio = 1.5,
		size = { 150, 50 },
		color = Color3.new(1, 1, 1),
	},

	aim = { fov = 50, delta = 0.1, inout = { 0.2, 0.3 } },

	recoil = {
		rotation = 0,
		dir = { X = { 0, 0 }, Y = { 0, 0 } },
		inout = { 0, 0 },
	},

	effects = { muzzle = "pulse", casing = nil, impact = "taser" },
	tracer = { name = "pulse", alpha = 0.05 },
	crosshair = { enabled = true, icon = "" },

	anim = {
		idle = { group = "pistol", fade = nil, weight = nil, speed = 1 },
		fire = { group = "pistol", fade = nil, weight = nil, speed = 1 },
		reload = { group = "pistol", fade = nil, weight = nil, speed = 1 },
		equip = { group = "pistol", fade = nil, weight = nil, speed = 1 },
		hold_down = { group = "pistol", fade = nil, weight = nil, speed = 1 },
		melee_attack = { group = "pistol", fade = nil, weight = nil, speed = 1 },
	},

	gui_text = {
		ammo_type = { Text = "Lithium Battery" },
		killable = { Text = "비살상무기" },
	},
}
