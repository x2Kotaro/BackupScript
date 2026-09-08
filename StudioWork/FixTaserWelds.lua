

local ServerStorage = game:GetService("ServerStorage")

local tool = ServerStorage:FindFirstChild("Tools")
	and ServerStorage.Tools:FindFirstChild("ปืนช็อตไฟฟ้ารัวเร็ว")
assert(tool, "ไม่พบ ServerStorage.Tools.ปืนช็อตไฟฟ้ารัวเร็ว")

local Handle = tool:FindFirstChild("Handle")
local Taser  = tool:FindFirstChild("Taser")
local ADS    = tool:FindFirstChild("ADS")
assert(Handle and Taser and ADS, "โครงสร้าง Tool ไม่ครบ (ต้องมี Handle / Taser / ADS)")

for _, parent in { Taser, ADS } do
	for _, c in parent:GetChildren() do
		if c:IsA("WeldConstraint") or c:IsA("Weld") or c:IsA("Motor6D") then
			c:Destroy()
		end
	end
end

local function makeWeld(name: string, parent: BasePart, part0: BasePart, part1: BasePart, c0: CFrame)
	local w = Instance.new("Weld")
	w.Name = name
	w.Part0 = part0
	w.Part1 = part1
	w.C0 = c0
	w.C1 = CFrame.identity
	w.Parent = parent
	return w
end

makeWeld("Handle", Taser, Taser, Handle,
	CFrame.new(0.142246246, -0.186261177, 0.0232601166,
		0, 0, 1,
		0, 1, 0,
		-1, 0, 0))

makeWeld("Taser", ADS, ADS, Taser,
	CFrame.new(0, -0.463863373, -1.3375473,
		0, 0, 1,
		0, 1, 0,
		-1, 0, 0))

Taser.Massless = false
ADS.Massless = false
Handle.CanCollide = true

if tool:GetAttribute("ToolName") == "연발 테이저건" then
	tool:SetAttribute("ToolName", "ปืนช็อตไฟฟ้ารัวเร็ว")
end

print("[FixTaserWelds] เสร็จแล้ว: เปลี่ยน WeldConstraint -> Weld + ตั้ง C0 ตรง live")
