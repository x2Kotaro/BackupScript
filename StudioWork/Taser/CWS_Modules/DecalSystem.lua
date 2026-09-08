-- CWS_Directory.modules.DecalSystem
--
-- Bullet holes / impact marks. CwsClient calls New() with:
--   { Alpha, DelayRemove, Texture, Size = { Can, Pic }, Color, raycastResult = { Position, Instance, Normal } }
-- `Can` caps how many marks one part may carry, `Pic` is the stud size of the mark.

local Debris = game:GetService("Debris")

local DecalSystem = {}

local MARK_NAME = "cws_decal"

local FACES = {
	{ normal = Vector3.new(1, 0, 0), face = Enum.NormalId.Right },
	{ normal = Vector3.new(-1, 0, 0), face = Enum.NormalId.Left },
	{ normal = Vector3.new(0, 1, 0), face = Enum.NormalId.Top },
	{ normal = Vector3.new(0, -1, 0), face = Enum.NormalId.Bottom },
	{ normal = Vector3.new(0, 0, 1), face = Enum.NormalId.Back },
	{ normal = Vector3.new(0, 0, -1), face = Enum.NormalId.Front },
}

local function faceFromNormal(part: BasePart, worldNormal: Vector3): Enum.NormalId
	local localNormal = part.CFrame:VectorToObjectSpace(worldNormal)
	local best, bestDot = Enum.NormalId.Top, -math.huge

	for _, candidate in ipairs(FACES) do
		local dot = localNormal:Dot(candidate.normal)
		if dot > bestDot then
			best, bestDot = candidate.face, dot
		end
	end

	return best
end

local function countMarks(part: BasePart): number
	local total = 0
	for _, child in ipairs(part:GetChildren()) do
		if child.Name == MARK_NAME then
			total += 1
		end
	end
	return total
end

function DecalSystem.New(config)
	if type(config) ~= "table" then
		return
	end

	local result = config.raycastResult
	local part = result and result.Instance
	if not part or not part:IsA("BasePart") or part:IsA("Terrain") then
		return
	end

	local size = config.Size or {}
	local cap = tonumber(size.Can) or 10
	if countMarks(part) >= cap then
		return
	end

	local normal = result.Normal or Vector3.new(0, 1, 0)
	local studs = tonumber(size.Pic) or 1

	local mark = Instance.new("Texture")
	mark.Name = MARK_NAME
	mark.Texture = config.Texture or ""
	mark.Face = faceFromNormal(part, normal)
	mark.StudsPerTileU = studs
	mark.StudsPerTileV = studs
	mark.Transparency = config.Alpha or 0

	if config.Color then
		mark.Color3 = config.Color
	end

	-- Offset the tiling so the mark lands on the hit point rather than the part origin.
	local localHit = part.CFrame:PointToObjectSpace(result.Position or part.Position)
	mark.OffsetStudsU = localHit.X
	mark.OffsetStudsV = localHit.Y

	mark.Parent = part

	local lifetime = tonumber(config.DelayRemove)
	if lifetime then
		Debris:AddItem(mark, lifetime)
	end

	return mark
end

return DecalSystem
