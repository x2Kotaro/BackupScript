-- CWS_Directory.modules.RigidBody
--
-- Client-side projectile simulation. Only weapons with an `info.projectile` block
-- reach this (grenades, launchers); the taser never does. Fields come from the
-- CwsClient call site: position, velocity, acceleration, elasticity, obj, life,
-- hitremove, ignore, angle_physics, hitsound, on_hit, on_remove.

local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local RigidBody = {}

local function playHitSound(spec, position: Vector3)
	if type(spec) ~= "table" then
		return
	end

	local pool, pitchRange = spec[1], spec[2] or 0
	if type(pool) ~= "table" or #pool == 0 then
		return
	end

	local template = pool[math.random(1, #pool)]
	if not template or not template:IsA("Sound") then
		return
	end

	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.Transparency = 1
	holder.Size = Vector3.one
	holder.Position = position
	holder.Parent = workspace

	local sound = template:Clone()
	sound.PlaybackSpeed += (math.random() * 2 - 1) * pitchRange
	sound.Parent = holder
	sound:Play()

	Debris:AddItem(holder, sound.TimeLength / math.max(sound.PlaybackSpeed, 0.01) + 0.5)
end

function RigidBody.new(config)
	local object = config.obj
	if not object or not object:IsA("BasePart") then
		return
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = config.ignore or {}

	local position = config.position or object.Position
	local velocity = config.velocity or Vector3.zero
	local acceleration = config.acceleration or Vector3.new(0, -workspace.Gravity, 0)
	local elasticity = config.elasticity or 0
	local spin = config.angle_physics

	object.Anchored = true
	object.CanCollide = false
	object.CFrame = CFrame.new(position)
	object.Parent = workspace

	local body = { alive = true }
	local expiry = os.clock() + (tonumber(config.life) or 10)
	local connection

	local function finish(hitPosition: Vector3?)
		if not body.alive then
			return
		end
		body.alive = false

		if connection then
			connection:Disconnect()
		end
		if config.on_remove then
			config.on_remove(object, hitPosition or object.Position)
		end
		object:Destroy()
	end

	body.destroy = finish

	connection = RunService.Heartbeat:Connect(function(deltaTime)
		if not body.alive or not object.Parent then
			finish()
			return
		end

		if os.clock() >= expiry then
			finish()
			return
		end

		velocity += acceleration * deltaTime
		local step = velocity * deltaTime
		local result = workspace:Raycast(position, step, params)

		if result then
			playHitSound(config.hitsound, result.Position)

			if config.on_hit then
				config.on_hit(result.Instance, result.Position, result.Normal)
			end

			if config.hitremove or elasticity <= 0 then
				position = result.Position
				object.CFrame = CFrame.new(position)
				finish(result.Position)
				return
			end

			-- Bounce and keep going with the leftover energy.
			position = result.Position + result.Normal * 0.05
			velocity = (velocity - 2 * velocity:Dot(result.Normal) * result.Normal) * elasticity
		else
			position += step
		end

		if spin then
			object.CFrame = CFrame.new(position)
				* CFrame.Angles(spin.X * deltaTime, spin.Y * deltaTime, spin.Z * deltaTime)
		else
			object.CFrame = CFrame.new(position, position + (velocity.Magnitude > 0 and velocity or Vector3.new(0, 0, 1)))
		end
	end)

	return body
end

return RigidBody
