-- Rebuilds the "연발 테이저건" (repeating taser) Tool inside the Studio place.
-- Every value here was read off the live tool in placeId 96256228241730 via the
-- Dex bridge; the tool itself could not be copied out of the running client.
-- Run in Edit mode. Master copy lands in ServerStorage, test copy in StarterPack.

local AssetService = game:GetService("AssetService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local TOOL_NAME = "연발 테이저건"
local INFO_SOURCE = "__INFO_SOURCE__"

local function seq(points)
	local keys = {}
	for _, p in ipairs(points) do
		table.insert(keys, NumberSequenceKeypoint.new(p[1], p[2], p[3] or 0))
	end
	return NumberSequence.new(keys)
end

local function colorSeq(points)
	local keys = {}
	for _, p in ipairs(points) do
		table.insert(keys, ColorSequenceKeypoint.new(p[1], Color3.new(p[2], p[3], p[4])))
	end
	return ColorSequence.new(keys)
end

local recording = ChangeHistoryService:TryBeginRecording("Import " .. TOOL_NAME)

for _, container in ipairs({ game.ServerStorage, game.StarterPack }) do
	local old = container:FindFirstChild(TOOL_NAME)
	if old then
		old:Destroy()
	end
end

local tool = Instance.new("Tool")
tool.Name = TOOL_NAME
tool.Grip = CFrame.new(-0.22, -0.05, -0.3, -1, 0, 0, 0, 1, 0, 0, 0, -1)
tool.CanBeDropped = false
tool.RequiresHandle = true
tool.ToolTip = "테이저 [Safe]"
tool:SetAttribute("ToolType", "")
tool:SetAttribute("cws_enabled", true)
tool:SetAttribute("ammo", 3)
tool:SetAttribute("I_Name", "44bf512e-47b3-4a8e-baec-d340f2b21b5b")
tool:SetAttribute("vm_long", true)

local GUN_GREY = Color3.new(0.639216, 0.635294, 0.647059)

-- Handle: invisible anchor part the grip and effects hang off of.
local handle = Instance.new("Part")
handle.Name = "Handle"
handle.Size = Vector3.new(1, 1, 1)
handle.Transparency = 0.999
handle.Color = GUN_GREY
handle.Material = Enum.Material.Plastic
handle.CanCollide = false
handle.CanTouch = true
handle.CanQuery = true
handle.CFrame = CFrame.new(0, 0, 0)
handle.Parent = tool

-- Taser: the visible mesh.
local taser
local ok, meshPart = pcall(function()
	return AssetService:CreateMeshPartAsync("rbxassetid://8438694198", {
		CollisionFidelity = Enum.CollisionFidelity.Box,
		RenderFidelity = Enum.RenderFidelity.Automatic,
	})
end)
if ok and meshPart then
	taser = meshPart
else
	taser = Instance.new("MeshPart")
	pcall(function()
		taser.MeshId = "rbxassetid://8438694198"
	end)
end
taser.Name = "Taser"
taser.Size = Vector3.new(1.9445189, 0.9288976, 0.3539724)
taser.Color = GUN_GREY
taser.Material = Enum.Material.SmoothPlastic
taser.CanCollide = false
taser.CanTouch = false
taser.CanQuery = false
taser.CFrame = handle.CFrame * CFrame.new(0.02326965, 0.18626404, -0.14224243, 0, 0, -1, 0, 1, 0, 1, 0, 0)
taser.Parent = tool

local surface = Instance.new("SurfaceAppearance")
surface.ColorMap = "rbxassetid://135138988332211"
surface.NormalMap = "rbxassetid://8438700729"
surface.MetalnessMap = "rbxassetid://8438698669"
surface.RoughnessMap = "rbxassetid://8438701734"
surface.AlphaMode = Enum.AlphaMode.Overlay
surface.Parent = taser

-- ADS: aim-down-sights reference point.
local ads = Instance.new("Part")
ads.Name = "ADS"
ads.Size = Vector3.new(0.1, 0.1, 0.1)
ads.Transparency = 0.999
ads.Color = GUN_GREY
ads.Material = Enum.Material.Plastic
ads.CanCollide = false
ads.CanTouch = false
ads.CanQuery = false
ads.CFrame = handle.CFrame * CFrame.new(0.02326965, 0.65011597, -1.47979736, -1, 0, 0, 0, 1, 0, 0, 0, -1)
ads.Parent = tool

local handleWeld = Instance.new("Weld")
handleWeld.Name = "Handle"
handleWeld.Part0 = taser
handleWeld.Part1 = handle
handleWeld.C0 = CFrame.new(0.14224625, -0.18626118, 0.02326012, 0, 0, 1, 0, 1, 0, -1, 0, 0)
handleWeld.C1 = CFrame.new()
handleWeld.Parent = taser

local taserWeld = Instance.new("Weld")
taserWeld.Name = "Taser"
taserWeld.Part0 = ads
taserWeld.Part1 = taser
taserWeld.C0 = CFrame.new(0, -0.46386337, -1.3375473, 0, 0, 1, 0, 1, 0, -1, 0, 0)
taserWeld.C1 = CFrame.new()
taserWeld.Parent = ads

local casingPoint = Instance.new("Attachment")
casingPoint.Name = "casing_point"
casingPoint.CFrame = CFrame.new(-0.21394253, 0.67671108, -0.19311142)
casingPoint.Parent = handle

local firePoint = Instance.new("Attachment")
firePoint.Name = "fire_point"
firePoint.CFrame = CFrame.new(0.02181053, 0.33785439, 0.84410286)
firePoint.Parent = handle

-- Muzzle effects. All start disabled; CwsClient enables them per shot.
local spark = Instance.new("ParticleEmitter")
spark.Name = "Spark"
spark.Texture = "rbxassetid://7074780818"
spark.Color = colorSeq({ { 0, 0.643137, 0.905882, 1 }, { 1, 0.054902, 0.231373, 0.709804 } })
spark.Size = seq({ { 0, 0 }, { 1, 0.15 } })
spark.Transparency = seq({ { 0, 0 }, { 1, 0 } })
spark.Squash = seq({ { 0, -1 }, { 1, -3 } })
spark.Speed = NumberRange.new(50, 50)
spark.Lifetime = NumberRange.new(0.02, 0.02)
spark.Rotation = NumberRange.new(0, 0)
spark.RotSpeed = NumberRange.new(0, 0)
spark.SpreadAngle = Vector2.new(360, 360)
spark.Rate = 500
spark.Drag = 5
spark.Brightness = 10
spark.LightEmission = 0
spark.LightInfluence = 0
spark.Acceleration = Vector3.new(0, -300, 0)
spark.EmissionDirection = Enum.NormalId.Top
spark.Orientation = Enum.ParticleOrientation.VelocityParallel
spark.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
spark.LockedToPart = true
spark.ZOffset = 0
spark.Enabled = false
spark.Parent = firePoint

local smoke = Instance.new("ParticleEmitter")
smoke.Name = "Smoke2"
smoke.Texture = "http://www.roblox.com/asset/?id=6679645080"
smoke.Color = colorSeq({ { 0, 0.568627, 0.568627, 0.568627 }, { 1, 0.568627, 0.568627, 0.568627 } })
smoke.Size = seq({ { 0, 0.05 }, { 0.6, 0.3, 0.0625 }, { 1, 0.6 } })
smoke.Transparency = seq({ { 0, 1 }, { 0.1, 0.8, 0.082 }, { 1, 1 } })
smoke.Squash = seq({ { 0, 0 }, { 1, 0 } })
smoke.Speed = NumberRange.new(0.2, 0.3)
smoke.Lifetime = NumberRange.new(2, 3)
smoke.Rotation = NumberRange.new(0, 360)
smoke.RotSpeed = NumberRange.new(-20, 20)
smoke.SpreadAngle = Vector2.new(-25, 25)
smoke.Rate = 30
smoke.Drag = 1
smoke.Brightness = 5
smoke.LightEmission = 0
smoke.LightInfluence = 0.5
smoke.Acceleration = Vector3.new(0, 2, 0)
smoke.EmissionDirection = Enum.NormalId.Back
smoke.Orientation = Enum.ParticleOrientation.FacingCamera
smoke.ShapeInOut = Enum.ParticleEmitterShapeInOut.InAndOut
smoke.LockedToPart = false
smoke.ZOffset = 0.2
smoke.Enabled = false
smoke.Parent = firePoint

local flash = Instance.new("ParticleEmitter")
flash.Name = "ParticleEmitter"
flash.Texture = "rbxassetid://4862737357"
flash.Color = colorSeq({ { 0, 1, 0.847059, 0.670588 }, { 1, 1, 0.847059, 0.670588 } })
flash.Size = seq({ { 0, 0 }, { 0.495982, 5.3125 }, { 1, 0 } })
flash.Transparency = seq({ { 0, 0.91875 }, { 1, 1 } })
flash.Squash = seq({ { 0, 0 }, { 1, 0 } })
flash.Speed = NumberRange.new(0, 0)
flash.Lifetime = NumberRange.new(0.1, 0.1)
flash.Rotation = NumberRange.new(-180, 0)
flash.RotSpeed = NumberRange.new(-3, 3)
flash.SpreadAngle = Vector2.new(0, 0)
flash.Rate = 100
flash.Drag = 0
flash.Brightness = 1
flash.LightEmission = 1
flash.LightInfluence = 0.1
flash.Acceleration = Vector3.new(0, 0, 0)
flash.EmissionDirection = Enum.NormalId.Top
flash.Orientation = Enum.ParticleOrientation.FacingCamera
flash.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
flash.LockedToPart = false
flash.ZOffset = 0
flash.Enabled = false
flash.Parent = firePoint

local muzzle = Instance.new("ParticleEmitter")
muzzle.Name = "Muzzle"
muzzle.Texture = "rbxassetid://386535299"
muzzle.Color = colorSeq({
	{ 0, 0.580392, 1, 0.968627 },
	{ 0.673877, 0.313726, 0.843137, 1 },
	{ 1, 0.180392, 0.34902, 0.741176 },
})
muzzle.Size = seq({ { 0, 0 }, { 0.48, 1.3, 0.256 }, { 1, 0 } })
muzzle.Transparency = seq({ { 0, 0.3 }, { 1, 0.6 } })
muzzle.Squash = seq({ { 0, 0 }, { 1, 0 } })
muzzle.Speed = NumberRange.new(0, 0)
muzzle.Lifetime = NumberRange.new(0.03, 0.06)
muzzle.Rotation = NumberRange.new(-180, 0)
muzzle.RotSpeed = NumberRange.new(-3, 3)
muzzle.SpreadAngle = Vector2.new(0, 0)
muzzle.Rate = 50
muzzle.Drag = 0
muzzle.Brightness = 5
muzzle.LightEmission = 1
muzzle.LightInfluence = 0.1
muzzle.Acceleration = Vector3.new(0, 0, 0)
muzzle.EmissionDirection = Enum.NormalId.Top
muzzle.Orientation = Enum.ParticleOrientation.FacingCamera
muzzle.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
muzzle.LockedToPart = true
muzzle.ZOffset = 0.5
muzzle.Enabled = false
muzzle.Parent = firePoint

local light = Instance.new("PointLight")
light.Color = Color3.new(0.596078, 1, 0.976471)
light.Brightness = 1
light.Range = 12
light.Shadows = true
light.Enabled = false
light.Parent = firePoint

local SOUNDS = {
	{ name = "equip", id = "rbxassetid://7405483764", volume = 1, speed = 1.0408947, min = 10, max = 10000 },
	{ name = "empty", id = "rbxassetid://484110242", volume = 1, speed = 1, min = 15, max = 60 },
	{ name = "melee_attack", id = "rbxassetid://5835032207", volume = 0.5, speed = 1, min = 10, max = 10000 },
	{ name = "melee_attack", id = "rbxassetid://5835032207", volume = 1, speed = 1, min = 10, max = 10000 },
	{ name = "mag_out", id = "rbxassetid://9075616566", volume = 1, speed = 1, min = 10, max = 10000 },
	{ name = "mag_in", id = "rbxassetid://9075617151", volume = 1, speed = 1, min = 10, max = 10000 },
	{ name = "slide", id = "rbxassetid://4527565140", volume = 1, speed = 1, min = 10, max = 10000 },
	{ name = "fire", id = "rbxassetid://7554632797", volume = 1.1, speed = 1, min = 25, max = 200 },
}

for _, spec in ipairs(SOUNDS) do
	local sound = Instance.new("Sound")
	sound.Name = spec.name
	sound.SoundId = spec.id
	sound.Volume = spec.volume
	sound.PlaybackSpeed = spec.speed
	sound.RollOffMode = Enum.RollOffMode.Inverse
	sound.RollOffMinDistance = spec.min
	sound.RollOffMaxDistance = spec.max
	sound.Parent = handle
end

local info = Instance.new("ModuleScript")
info.Name = "Info"
info.Source = INFO_SOURCE
info.Parent = tool

tool.Parent = game.ServerStorage

local testCopy = tool:Clone()
testCopy.Parent = game.StarterPack

if recording then
	ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end

return string.format("built %s | mesh_ok=%s | descendants=%d", TOOL_NAME, tostring(ok), #tool:GetDescendants())
