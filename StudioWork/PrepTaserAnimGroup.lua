

local IDS = {
	idle         = "",
	fire         = "",
	reload       = "",
	equip        = "",
	hold_down    = "",
	melee_attack = "",
}

local RS = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local animRoot = RS.GameSettings.Assets.Misc.CWS_Directory.anim
local pistol = animRoot:FindFirstChild("pistol")
assert(pistol, "no pistol group")

local taser = animRoot:FindFirstChild("taser")
if not taser then
	taser = pistol:Clone()
	taser.Name = "taser"
	taser.Parent = animRoot
end

local missing = {}
for slot, id in pairs(IDS) do
	if id == "" then
		missing[#missing+1] = slot
	else
		local a = taser:FindFirstChild(slot)
		if a and a:IsA("Animation") then a.AnimationId = id end
		if slot == "fire" then
			local lf = taser:FindFirstChild("last_fire")
			if lf then lf.AnimationId = id end
		end
	end
end

if #missing > 0 then
	warn("[Prep] ยังไม่ได้ใส่ id: " .. table.concat(missing, ", ") .. "  (ยังไม่ flip Info)")
	return
end

local info = ServerStorage.Tools["ปืนช็อตไฟฟ้ารัวเร็ว"].Info
local src, n = info.Source:gsub('group = "pistol"', 'group = "taser"')
info.Source = src
print(("[Prep] เสร็จ: taser group อัปเดต + Info.anim %d slot -> group \"taser\""):format(n))
