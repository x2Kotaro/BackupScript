-- CWS_Directory.modules.Spring
--
-- CWS uses this for camera recoil only: create() with no arguments, then update(dt)
-- once per frame and read the result as a Vector3.

local Spring = {}
Spring.__index = Spring

local ZERO = Vector3.zero

function Spring.create(mass: number?, force: number?, damping: number?, speed: number?)
	return setmetatable({
		Target = ZERO,
		Position = ZERO,
		Velocity = ZERO,
		Mass = mass or 5,
		Force = force or 50,
		Damping = damping or 4,
		Speed = speed or 4,
	}, Spring)
end

function Spring:shove(force: Vector3)
	self.Velocity += force
end

function Spring:update(deltaTime: number): Vector3
	local scaledDelta = math.min(deltaTime, 1) * self.Speed
	local pull = (self.Target - self.Position) * self.Force / self.Mass
	local acceleration = pull - self.Velocity * self.Damping

	self.Velocity += acceleration * scaledDelta
	self.Position += self.Velocity * scaledDelta

	return self.Position
end

return Spring
