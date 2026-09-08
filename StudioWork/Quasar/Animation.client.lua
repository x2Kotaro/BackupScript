-- Quasar — client-side animation driver.
-- Cleaned rewrite of the decompiled LocalScript from the live place.

local tool = script.Parent :: Tool
local attackAnim = script:WaitForChild("AttackAnim1") :: Animation
local idleAnim = script:WaitForChild("Idle") :: Animation

local attackTrack: AnimationTrack? = nil
local idleTrack: AnimationTrack? = nil
local swinging = false

local function getAnimator(): Animator?
	local character = tool.Parent
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end
	return humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
end

tool.Equipped:Connect(function()
	local animator = getAnimator()
	if not animator then
		return
	end

	attackTrack = animator:LoadAnimation(attackAnim)
	idleTrack = animator:LoadAnimation(idleAnim)

	if idleTrack then
		idleTrack.Looped = true
		idleTrack:Play()
	end
end)

tool.Unequipped:Connect(function()
	if idleTrack then
		idleTrack:Stop()
	end
	if attackTrack then
		attackTrack:Stop()
	end
	swinging = false
end)

tool.Activated:Connect(function()
	if swinging or not attackTrack then
		return
	end
	swinging = true

	attackTrack:Play()

	task.wait((tool:GetAttribute("Speed") or 0.7) :: number)
	swinging = false
end)
