-- Appended to ReplicatedStorage.GameSettings.Modules.RagdollMod, after the existing
-- MakeCorpse function. MakeCorpse also gained one line at the very top:
--
--     function module.MakeCorpse(character)
--         module.Cleanup(character)      <-- added
--         local humanoid = character.Humanoid

-- Temporary, reversible ragdoll used for knockdowns. MakeCorpse above is the
-- permanent death version; this one leaves the character intact so it can stand up.
--
-- The R6 RootJoint is left alone on purpose: HumanoidRootPart stays welded to the
-- Torso, so the Humanoid keeps a valid root and getting up is one state change.
-- Everything else (neck, shoulders, hips) goes limp on BallSocketConstraints.

local ATTACHMENT_PREFIX = "PXRagdollAttachment"
local CONSTRAINT_NAME = "PXRagdollConstraint"
local READY_ATTRIBUTE = "PXRagdollReady"

local function isRootJoint(motor)
	return motor.Name == "RootJoint"
		or (motor.Part0 and motor.Part0.Name == "HumanoidRootPart")
		or (motor.Part1 and motor.Part1.Name == "HumanoidRootPart")
end

-- Builds the constraints once per character and leaves them disabled.
function module.Setup(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or character:GetAttribute(READY_ATTRIBUTE) then return end

	-- A disabled neck Motor6D must not read as a broken neck.
	humanoid.RequiresNeck = false

	for _, motor in ipairs(character:GetDescendants()) do
		if motor:IsA("Motor6D") and motor.Part0 and motor.Part1 and not isRootJoint(motor) then
			local a0 = Instance.new("Attachment")
			a0.Name = ATTACHMENT_PREFIX .. "0"
			a0.CFrame = motor.C0
			a0.Parent = motor.Part0

			local a1 = Instance.new("Attachment")
			a1.Name = ATTACHMENT_PREFIX .. "1"
			a1.CFrame = motor.C1
			a1.Parent = motor.Part1

			local socket = Instance.new("BallSocketConstraint")
			socket.Name = CONSTRAINT_NAME
			socket.Attachment0 = a0
			socket.Attachment1 = a1
			socket.LimitsEnabled = true
			socket.TwistLimitsEnabled = false
			socket.UpperAngle = 60
			socket.Enabled = false
			socket.Parent = motor.Part0
		end
	end

	character:SetAttribute(READY_ATTRIBUTE, true)
end

-- The weapon rig re-enables the shoulder Motor6Ds every frame so it can drive the
-- arms, which would snap them straight again mid-ragdoll. While a character is down
-- we hold the joints off rather than trying to find and gate every writer.
local RunService = game:GetService("RunService")
local holds = {}

local function stopHold(character)
	local hold = holds[character]
	if hold then
		hold.active = false
		holds[character] = nil
	end
end

local function startHold(character, motors)
	stopHold(character)

	local hold = { active = true }
	holds[character] = hold

	task.spawn(function()
		while hold.active and character.Parent do
			for _, motor in ipairs(motors) do
				if motor.Parent and motor.Enabled then
					motor.Enabled = false
				end
			end
			RunService.Heartbeat:Wait()
		end
	end)
end

function module.SetRagdolled(character, enabled)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	if enabled and humanoid.Health <= 0 then return end

	if enabled and not character:GetAttribute(READY_ATTRIBUTE) then
		module.Setup(character)
	end

	local loosened = {}
	for _, item in ipairs(character:GetDescendants()) do
		if item:IsA("BallSocketConstraint") and item.Name == CONSTRAINT_NAME then
			item.Enabled = enabled
		elseif item:IsA("Motor6D") and not isRootJoint(item) then
			item.Enabled = not enabled
			if enabled then
				table.insert(loosened, item)
			end
		end
	end

	if enabled then
		startHold(character, loosened)
	else
		stopHold(character)
	end

	humanoid.PlatformStand = enabled
	humanoid:ChangeState(enabled and Enum.HumanoidStateType.Physics or Enum.HumanoidStateType.GettingUp)
end

-- Puts the joints back the way Roblox made them; safe to call on a dead character.
function module.Cleanup(character)
	stopHold(character)

	for _, item in ipairs(character:GetDescendants()) do
		if item.Name == CONSTRAINT_NAME or string.sub(item.Name, 1, #ATTACHMENT_PREFIX) == ATTACHMENT_PREFIX then
			item:Destroy()
		elseif item:IsA("Motor6D") then
			item.Enabled = true
		end
	end
	character:SetAttribute(READY_ATTRIBUTE, nil)
end

return module
