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

	-- The taser's stun/ragdoll logic used to live here as `custom_server.damage`, but
	-- this module is a child of the Tool -- it replicates to whoever is holding the
	-- gun, so any exploiter could read the stun duration and knockback straight out
	-- of its Source, or call the function themselves. That logic now lives in
	-- ServerScriptService.Combat.WeaponServerLogic, which is never parented under a
	-- Tool and so never reaches a client.

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
		ammo_type = { Text = "แบตเตอรี่ลิเธียม" },
		killable = { Text = "อาวุธไม่สังหาร" },
	},
}
