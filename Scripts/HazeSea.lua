local Players = game:GetService("Players")

if not game:IsLoaded() then
	game.Loaded:Wait()
end

repeat
	task.wait()
until Players.LocalPlayer
local LocalPlayer = Players.LocalPlayer

local function BootWait(Parent, Name, Timeout)
	if not Parent then
		return nil
	end
	local Child = Parent:FindFirstChild(Name)
	local Deadline = os.clock() + (Timeout or 120)
	while not Child do
		if os.clock() > Deadline then
			return nil
		end
		task.wait(0.1)
		Child = Parent:FindFirstChild(Name)
	end
	return Child
end

pcall(function()
	game:GetService("ReplicatedStorage")
		:WaitForChild("Replication")
		:WaitForChild("ClientEvents")
		:WaitForChild("ChooseTeam")
		:InvokeServer(unpack({ "Pirates" }))
end)

local BootData = BootWait(LocalPlayer, "PlayerData", 180)
if not BootData then
	return warn("[Valkyrie Hub] PlayerData never replicated - aborted")
end

local BootExperience = BootWait(BootData, "Experience", 120)
if not BootExperience then
	return warn("[Valkyrie Hub] PlayerData.Experience never replicated - aborted")
end

BootWait(BootExperience, "Level", 60)
BootWait(BootExperience, "Points", 60)
BootWait(BootData, "Currency", 60)
BootWait(BootWait(BootData, "Sword", 60), "OwnedSwords", 60)
BootWait(LocalPlayer, "PlayerGui", 60)
BootWait(LocalPlayer, "leaderstats", 60)

if not LocalPlayer.Character then
	LocalPlayer.CharacterAdded:Wait()
end

getgenv().ConfigurationTable = {}
getgenv().Settings = {}

local FolderConfiguration = "Valkyrie Hub"
local FolderSettings = "Valkyrie Hub/Haze Seas"

task.spawn(function()
	local StartPlayerGui = LocalPlayer:WaitForChild("PlayerGui")

	local function ClickStart()
		local Button = StartPlayerGui:FindFirstChild("StartMenu")
		for _, Name in ipairs({ "MainFrame", "Middle", "Play", "Holder", "PlayButton", "Button" }) do
			Button = Button and Button:FindFirstChild(Name)
		end
		if not Button then
			return
		end

		local Fired = false
		if getconnections then
			for _, Signal in ipairs({ "MouseButton1Click", "MouseButton1Down", "MouseButton1Up", "Activated" }) do
				local Ok, Connections = pcall(function()
					return getconnections(Button[Signal])
				end)
				if Ok and Connections then
					for _, Connection in ipairs(Connections) do
						if pcall(function()
							Connection:Fire()
						end) then
							Fired = true
						end
					end
				end
			end
		end

		if not Fired then
			pcall(function()
				local VirtualUser = game:GetService("VirtualUser")
				local Inset = game:GetService("GuiService"):GetGuiInset()
				local Center = Button.AbsolutePosition + (Button.AbsoluteSize / 2) + Inset
				VirtualUser:Button1Down(Center)
				task.wait(0.05)
				VirtualUser:Button1Up(Center)
			end)
		end
	end

	local SawMenu = false
	for _ = 1, 240 do
		local Menu = StartPlayerGui:FindFirstChild("StartMenu")
		if Menu then
			SawMenu = true
			if Menu.Enabled then
				pcall(ClickStart)
			end
		elseif SawMenu then
			break
		end
		task.wait(0.5)
	end
end)

local HttpService = game:GetService("HttpService")
local VenuzIcon = "rbxassetid://92691624917972"
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local filenameConfiguration = FolderConfiguration .. "/" .. "Setting_" .. LocalPlayer.Name .. ".json"
local filenameSetting = FolderSettings .. "/" .. "Config_" .. LocalPlayer.Name .. ".json"

local DefaultConfiguration = {
	["Themes"] = "Crimson",
	["Transparent"] = true,
	["AntiAFK"] = true,
	["AutoRejoin"] = false,
	["AutoExecutor"] = true,
	["MinimizeBind"] = "End",
	["Language"] = "English (US)",
	["FPSValue"] = 144,
	["LockFPS"] = false,
	["WhileScreen"] = false,
	["ScreenColor"] = "White",
}

local function MergeConfiguration(loaded, defaults)
	for key, defaultValue in pairs(defaults) do
		if type(defaultValue) == "table" then
			loaded[key] = MergeConfiguration(loaded[key] or {}, defaultValue)
		else
			if loaded[key] == nil then
				loaded[key] = defaultValue
			end
		end
	end
	return loaded
end

function LoadConfiguration()
	if readfile and isfile and isfile(filenameConfiguration) then
		local data = readfile(filenameConfiguration)
		local success, decoded = pcall(function()
			return HttpService:JSONDecode(data)
		end)

		if success and type(decoded) == "table" then
			getgenv().ConfigurationTable = MergeConfiguration(decoded, DefaultConfiguration)
		else
			warn("[Configuration] Failed to decode, using default.")
			getgenv().ConfigurationTable = DefaultConfiguration
		end
	else
		getgenv().ConfigurationTable = DefaultConfiguration
	end
end

function SaveConfiguration()
	if not (writefile and makefolder) then
		return false
	end

	local ok, err = pcall(function()
		if not isfolder("Venuz Hub") then
			makefolder("Venuz Hub")
		end
		if not isfolder(FolderConfiguration) then
			makefolder(FolderConfiguration)
		end
		writefile(filenameConfiguration, HttpService:JSONEncode(getgenv().ConfigurationTable))
	end)

	if not ok then
		warn("[Configuration] Save failed: " .. tostring(err))
	end

	return ok
end

LoadConfiguration()

local DefaultSettings = {
	["Main"] = {},
	["AutoFarmLevel"] = {
		["Enabled"] = false,
		["AutoQuest"] = true,
		["Weapon"] = "",
		["BossWeapon"] = "",
		["AttackPosition"] = "Over",
		["Distance"] = 6,
		["TweenSpeed"] = 300,
	},
	["AutoUpgradeStats"] = {
		["Enabled"] = false,
		["Stats"] = {},
		["PointsPerUpgrade"] = 1,
	},
	["AutoCollectChest"] = false,
	["AutoMerchant"] = {
		["Enabled"] = false,
	},
	["AutoSetSpawn"] = false,
	["SelectedIsland"] = "",
	["IslandTeleportMode"] = "Tween",
	["SelectedFruit"] = "",
	["AutoHaki"] = {
		["Buso"] = false,
		["Observation"] = false,
	},
	["AutoBuyHaki"] = {
		["Buso"] = false,
		["Observation"] = false,
	},
	["SelectedSword"] = "",
	["SwordSpots"] = {},
	["AutoSea2"] = false,
	["AutoSea3"] = false,

	["ManualSeaTarget"] = 0,
	["AutoSharkBlade"] = false,
	["Auto2SS"] = false,
	["AutoGoldenStaff"] = false,
	["AutoShushi"] = false,
	["AutoRaiu"] = false,
	["AutoFishmanTrident"] = false,
	["AutoMace"] = false,
	["AutoBlackLegV2"] = false,
	["AutoFishmanV2"] = false,
	["AutoCyborgV2"] = false,
	["AutoElectroV2"] = false,
	["AutoDragonClawV2"] = false,

	["AutoAwakening"] = {
		["Gear2"] = false,
		["Gear4"] = false,
		["Gear5"] = false,
		["Electricity"] = false,
		["Dragon"] = false,
	},
	["FruitSniper"] = {
		["Enabled"] = false,
		["StoreToBag"] = true,
		["Whitelist"] = {},
	},
	["FruitDealer"] = {
		["Enabled"] = false,
		["Whitelist"] = {},
		["StoreToBag"] = true,
	},
	["AutoSpinFruit"] = {
		["Enabled"] = false,
		["Currency"] = "Beli",
		["StoreToBag"] = true,
	},
	["AutoEatFruit"] = {
		["Enabled"] = false,
		["Fruit"] = "",
	},
	["AutoFish"] = {
		["Enabled"] = false,
		["CastDistance"] = 25,
	},

	["AutoFarmBoss"] = {
		["Enabled"] = false,
		["Bosses"] = {},
		["Dodge"] = true,

		["Spots"] = {},
	},

	["AutoFarmMob"] = {
		["Enabled"] = false,
		["AutoQuest"] = true,
		["Mobs"] = {},
	},
	["AutoDragonHydra"] = {
		["Summon"] = false,
		["Kill"] = false,
	},
	["AutoRaijin"] = {
		["Summon"] = false,
		["Kill"] = false,
	},
	["AutoDoughBoss"] = {
		["Fragment"] = false,
		["Unlock"] = false,
		["Spawn"] = false,
		["Kill"] = false,
	},
	["AutoDragonBoss"] = {
		["Summon"] = false,
		["Kill"] = false,
	},

	["AutoZenithBoss"] = {
		["Enabled"] = false,
	},
	["AutoSaturnBoss"] = {
		["Enabled"] = false,
	},
	["AutoEnmaBoss"] = {
		["Enabled"] = false,
	},
	["AutoVaultChest"] = {
		["Enabled"] = false,
	},
	["AutoRedEmperor"] = {
		["Enabled"] = false,
		["WaitAtThrone"] = true,
		["WaitBefore"] = 120,
	},
	["AutoGhostShip"] = {
		["Enabled"] = false,
		["Summon"] = false,
		["Source"] = "Fruit Bag",
		["Fruits"] = {},
		["Rarities"] = {},
	},
	["AutoSeaBeast"] = {
		["Enabled"] = false,
		["Find"] = false,
		["Interval"] = 20,
		["Duration"] = 1,
	},
	["AutoCthulhu"] = {
		["Enabled"] = false,
		["Summon"] = false,
		["Craft"] = true,
	},

	["AutoBossQuest"] = true,

	["BossPriority"] = {
		"Cthulhu",
		"Hydra",
		"Raijin",
		"Dough",
		"Dragon",
		"Zenith",
		"Saturn",
		"Enma",
		"Vault",
		"RedEmperor",
		"GhostShip",
		"Beast",
	},

	["AutoHopServer"] = {
		["Enabled"] = false,
		["Wait"] = 10,
		["Bosses"] = {},
	},

	["AutoSkill"] = {
		["Enabled"] = false,
		["Melee"] = {},
		["Fruit"] = {},
		["Sword"] = {},
		["HoldDuration"] = 0,
		["Delay"] = 0.5,

		["UseOn"] = { "Mob", "Boss" },
		["Range"] = 150,
	},

	["Misc"] = {
		["DashNoCooldown"] = false,
		["SkyJumpInf"] = false,
		["InfiniteJump"] = false,
	},

	["Webhook"] = {
		["Url"] = "",
		["UserId"] = "",
		["HideName"] = false,
		["Events"] = {
			["ScriptStart"] = true,
			["Merchant"] = true,
			["BossKill"] = true,
			["Fruit"] = true,
			["Sword"] = true,
			["Accessory"] = false,
			["LevelUp"] = false,
			["SeaUnlock"] = true,
			["Death"] = false,
			["ServerHop"] = false,
		},
		["PingOn"] = {},
		["LevelStep"] = 25,
		["Heartbeat"] = false,
		["HeartbeatMinutes"] = 30,
	},
}

local function MergeSettings(defaults, loaded)
	for k, v in pairs(defaults) do
		if type(v) == "table" then
			if type(loaded[k]) ~= "table" then
				loaded[k] = v
			else
				MergeSettings(v, loaded[k])
			end
		else
			if loaded[k] == nil then
				loaded[k] = v
			end
		end
	end
end

function NormalizeList(Value)
	local List, Seen = {}, {}

	if type(Value) == "string" then
		if Value ~= "" then
			table.insert(List, Value)
		end
		return List
	end

	if type(Value) ~= "table" then
		return List
	end

	for Key, Item in pairs(Value) do
		local Name = nil
		if type(Item) == "string" then
			Name = Item
		elseif Item == true and type(Key) == "string" then
			Name = Key
		end

		if Name and not Seen[Name] then
			Seen[Name] = true
			table.insert(List, Name)
		end
	end

	table.sort(List)
	return List
end

function SanitizeSettings()
	local Settings = getgenv().Settings
	if type(Settings) ~= "table" then
		return
	end

	local MultiFields = {
		{ "AutoUpgradeStats", "Stats" },
		{ "FruitSniper", "Whitelist" },
		{ "FruitDealer", "Whitelist" },
		{ "AutoFarmBoss", "Bosses" },
		{ "AutoHopServer", "Bosses" },
		{ "AutoFarmMob", "Mobs" },
		{ "AutoGhostShip", "Fruits" },
		{ "AutoGhostShip", "Rarities" },
		{ "AutoSkill", "Melee" },
		{ "AutoSkill", "Fruit" },
		{ "AutoSkill", "Sword" },
		{ "AutoSkill", "UseOn" },
		{ "Webhook", "PingOn" },
	}

	for _, Path in ipairs(MultiFields) do
		local Parent = Settings[Path[1]]
		if type(Parent) == "table" then
			Parent[Path[2]] = NormalizeList(Parent[Path[2]])
		end
	end
end

function LoadSettings()
	local loaded = nil

	if readfile and isfile and isfile(filenameSetting) then
		local ok, decoded = pcall(function()
			return HttpService:JSONDecode(readfile(filenameSetting))
		end)

		if ok and type(decoded) == "table" then
			loaded = decoded
		else
			warn("[Settings] Failed to decode, using default.")
		end
	end

	if loaded then
		if type(loaded.AutoGhostShip) == "table" then
			local Old = loaded.AutoGhostShip.Source

			if type(Old) == "table" then
				Old = NormalizeList(Old)[1]
			end

			if Old ~= "Fruit Bag" and Old ~= "In Backpack" and Old ~= "Buy Fruit" then
				loaded.AutoGhostShip.Source = "Fruit Bag"
			else
				loaded.AutoGhostShip.Source = Old
			end
		end

		MergeSettings(DefaultSettings, loaded)

		if loaded.AutoFarmLevel and loaded.AutoFarmLevel.AttackPosition == "Top" then
			loaded.AutoFarmLevel.AttackPosition = "Over"
		end
		getgenv().Settings = loaded
	else
		getgenv().Settings = DefaultSettings
	end

	SanitizeSettings()
end

ConfigApplying = false

function SaveSetting()
	if ConfigApplying then
		return false
	end

	if not (writefile and makefolder) then
		return false
	end

	local ok, err = pcall(function()
		SanitizeSettings()
		if not isfolder("Venuz Hub") then
			makefolder("Venuz Hub")
		end
		if not isfolder(FolderSettings) then
			makefolder(FolderSettings)
		end
		writefile(filenameSetting, HttpService:JSONEncode(getgenv().Settings))
	end)

	if not ok then
		warn("[Settings] Save failed: " .. tostring(err))
	end

	return ok
end

SaveQueued = false

function QueueSave()
	if SaveQueued then
		return
	end

	SaveQueued = true

	task.delay(5, function()
		SaveQueued = false
		SaveSetting()
	end)
end

LoadSettings()

VenuzToggle = {}

getgenv().ValkyrieInstance = (tonumber(getgenv().ValkyrieInstance) or 0) + 1
local ThisInstance = getgenv().ValkyrieInstance

function IsCurrentInstance()
	return getgenv().ValkyrieInstance == ThisInstance
end

if getgenv().Configuration and next(getgenv().Configuration) then
	for key, value in pairs(getgenv().Configuration) do
		if getgenv().Settings[key] ~= nil then
			getgenv().Settings[key] = value
		end
	end
	SaveSetting()
end

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/x2Kotaro/API/main/test.lua"))()

local Device
if UserInputService.TouchEnabled then
	Device = UDim2.fromOffset(450, 300)
else
	Device = UDim2.fromOffset(650, 520)
end

WindUI:Localization({
	Enabled = true,
	Prefix = "tr:",
	DefaultLanguage = getgenv().ConfigurationTable.Language,
	Translations = {
		["Thai"] = {
			["GroupMain"] = "ทั่วไป",
			["GroupFarm"] = "ฟาร์ม",
			["GroupItem"] = "ไอเทมและร้านค้า",
			["GroupTravel"] = "เดินทาง",
			["GroupSystem"] = "ระบบ",
			["Configuration"] = "การตั้งค่า",
			["Interface"] = "การตั้งค่าหน้าจอ",
			["themeDropdown"] = "เลือกธีม",
			["themeDropdownDesc"] = "สีของหน้าต่างสคริปต์",
			["ToggleTransparency"] = "พื้นหลังโปร่งใส",
			["ToggleTransparencyDesc"] = "ทำให้พื้นหลังหน้าต่างโปร่ง",
			["AntiAFK"] = "ป้องกันการหลุดจากเกม",
			["AntiAFKDesc"] = "กันโดนเตะออกจากเกมตอนอยู่เฉย ๆ",
			["AutoRejoin"] = "เข้าเกมใหม่อัตโนมัติ",
			["AutoRejoinDesc"] = "หลุดแล้วเข้าเกมเดิมให้เอง",
			["AutoExecutor"] = "รันสคริปต์อัตโนมัติ",
			["AutoExecutorDesc"] = "ย้ายเซิร์ฟแล้วสคริปต์เปิดเอง",
			["MinimizeBind"] = "ปุ่มซ่อน/แสดงเมนู",
			["MinimizeBindDesc"] = "ปุ่มเปิด/ปิดหน้าต่างสคริปต์",
			["FPSIS"] = "การตั้งค่า FPS",
			["FPSVALUE"] = "ค่า FPS",
			["FPSVALUEDesc"] = "เพดานเฟรมเรตที่ใช้ตอนล็อก FPS",
			["FPSLOCK"] = "ล็อกค่า FPS",
			["FPSLOCKDesc"] = "ล็อกเฟรมเรตตามค่าด้านบน",
			["WhiteScreen"] = "ครอบจอทึบ",
			["WhiteScreenDesc"] = "ครอบจอทึบ หยุดเรนเดอร์เกม ลดหน่วง",
			["ScreenColor"] = "สีที่ใช้ครอบจอ",
			["ScreenColorDesc"] = "เลือกสีที่ใช้ครอบจอ ขาว หรือ ดำ เปลี่ยนได้ทันทีขณะเปิดอยู่",
			["LanguageTab"] = "ภาษา",
			["Language"] = "เลือกภาษา",
			["LanguageDesc"] = "ภาษาของสคริปต์",
			["ChangedLanguage"] = "เปลี่ยนภาษา",
			["ChangedLanguageDesc"] = "ใช้ภาษาที่เลือกทันที",
			["ScriptLoader"] = "ตัวโหลดสคริปต์",
			["ScriptLoaded"] = "โหลดสคริปต์เสร็จสมบูรณ์",
			["ConfigSection"] = "คอนฟิก",
			["ConfigName"] = "ชื่อคอนฟิก",
			["ConfigNameDesc"] = "ตั้งชื่อก่อนกดสร้าง ถ้าเว้นว่างจะตั้งชื่อตามวันเวลาให้เอง",
			["ConfigCreate"] = "สร้างคอนฟิก",
			["ConfigCreateDesc"] = "บันทึกการตั้งค่าทั้งหมดตอนนี้เป็นคอนฟิกใหม่",
			["ConfigList"] = "เลือกคอนฟิก",
			["ConfigListDesc"] = "คอนฟิกที่บันทึกไว้ทั้งหมด",
			["ConfigLoad"] = "โหลดคอนฟิก",
			["ConfigLoadDesc"] = "ใช้ค่าจากคอนฟิกที่เลือกทันที ปุ่มทุกอันในเมนูเปลี่ยนตามให้เอง ไม่ต้องรีโหลดสคริปต์",
			["ConfigDelete"] = "ลบคอนฟิก",
			["ConfigDeleteDesc"] = "ลบคอนฟิกที่เลือกออกจากเครื่อง",
			["ConfigRefresh"] = "รีเฟรชรายชื่อ",
			["ConfigRefreshDesc"] = "อ่านรายชื่อคอนฟิกใหม่อีกครั้ง",
			["InfoTab"] = "ข้อมูล",
			["InfoPlayerSection"] = "ข้อมูลตัวละคร",
			["InfoPlayer"] = "โปรไฟล์",
			["InfoFruitSection"] = "ผลปีศาจ",
			["InfoFruit"] = "ผลปีศาจที่มี",
			["InfoSwordSection"] = "ดาบ",
			["InfoSword"] = "ดาบทั้งหมดในเกม",
			["InfoAccessorySection"] = "เครื่องประดับ",
			["InfoAccessory"] = "เครื่องประดับทั้งหมดในเกม",
			["InfoStyleSection"] = "ท่าต่อสู้",
			["InfoStyle"] = "ท่าต่อสู้ทั้งหมดในเกม",
			["InfoHakiSection"] = "ฮาคิ",
			["InfoHaki"] = "ฮาคิและสีฮาคิ",
			["Automatic"] = "ระบบอัตโนมัติ",
			["AutoFarmSection"] = "ฟาร์มเลเวล",
			["SelectWeapon"] = "เลือกอาวุธ",
			["SelectWeaponDesc"] = "ประเภทอาวุธที่ทุกระบบฟาร์มใช้ตี (Melee / Sword / Fruit) เปลี่ยนดาบหรือผลในเกมได้เลย ไม่ต้องมาเลือกใหม่",
			["SelectBossWeapon"] = "เลือกอาวุธสำหรับบอส",
			["SelectBossWeaponDesc"] = "ประเภทอาวุธที่แท็บ บอส ใช้ตี ถ้าไม่เลือกจะเปิดระบบในแท็บ บอส ไม่ได้",
			["AutoQuestAccept"] = "รับเควสอัตโนมัติ",
			["AutoQuestAcceptDesc"] = "จัดการเควสให้ตรงกับมอนที่ฟาร์ม",
			["AutoFarmLevel"] = "ฟาร์มเลเวลอัตโนมัติ",
			["AutoFarmLevelDesc"] = "ฟาร์มมอนตามเลเวลให้อัตโนมัติ",
			["FarmTab"] = "ตั้งค่าการฟาร์ม",
			["WeaponSection"] = "อาวุธ",
			["FarmSettings"] = "การเคลื่อนที่และตำแหน่งตี",
			["AttackPosition"] = "ตำแหน่งที่ยืนตี",
			["AttackPositionDesc"] = "มุมที่ยืนตีมอน",
			["Distance"] = "ระยะห่างจากมอน",
			["DistanceDesc"] = "ระยะห่างจากมอนตอนตี",
			["TweenSpeed"] = "ความเร็วในการเดินทาง",
			["TweenSpeedDesc"] = "ความเร็วบินและวาร์ปของทุกระบบ",
			["AutoUpgradeSection"] = "อัพสเตตัสอัตโนมัติ",
			["SelectStats"] = "เลือกสเตตัสที่จะอัพ",
			["SelectStatsDesc"] = "สเตตัสที่จะอัพ",
			["PointsPerUpgrade"] = "จำนวนแต้มต่อครั้ง",
			["PointsPerUpgradeDesc"] = "จำนวนแต้มที่ใช้ต่อครั้ง",
			["AutoUpgradeToggle"] = "อัพสเตตัสอัตโนมัติ",
			["AutoUpgradeToggleDesc"] = "อัพสเตตัสให้เองเมื่อมีแต้ม",
			["Teleport"] = "วาร์ป",
			["SpawnSection"] = "จุดเกิด",
			["AutoSetSpawn"] = "ตั้งจุดเกิดอัตโนมัติ",
			["AutoSetSpawnDesc"] = "ตั้งจุดเกิดตามเกาะที่อยู่ให้เอง",
			["SetSpawnNow"] = "ตั้งจุดเกิดตรงนี้",
			["SetSpawnNowDesc"] = "ตั้งจุดเกิดเป็นเกาะใกล้สุด ครั้งเดียว",
			["IslandSection"] = "วาร์ปเกาะ",
			["SelectIsland"] = "เลือกเกาะ",
			["SelectIslandDesc"] = "เกาะปลายทาง",
			["IslandMode"] = "รูปแบบการวาร์ป",
			["IslandModeDesc"] = "Tween = บินไปเอง, Set Spawn = ตั้งจุดเกิดแล้วรีเซ็ตตัวละคร",
			["TeleportGo"] = "วาร์ปไป",
			["TeleportGoDesc"] = "วาร์ปไปเกาะที่เลือก",
			["FruitTeleportGoDesc"] = "วาร์ปไปผลที่เลือก",
			["ShopTab"] = "ร้านค้า",
			["HakiShopSection"] = "ซื้อฮาคิอัตโนมัติ",
			["SwordShopSection"] = "ซื้อดาบ",
			["SelectSword"] = "เลือกดาบ",
			["SelectSwordDesc"] = "ดาบที่จะซื้อ พร้อมราคาและเลเวล",
			["BuySword"] = "ซื้อดาบ",
			["BuySwordDesc"] = "ซื้อดาบที่เลือกให้",
			["AutoBuyBuso"] = "ซื้อ Buso Haki",
			["AutoBuyBusoDesc"] = "ซื้อ Buso Haki ให้เมื่อเลเวลและเงินถึง",
			["AutoBuyObservation"] = "ซื้อ Observation Haki",
			["AutoBuyObservationDesc"] = "ซื้อ Observation Haki ให้เมื่อเลเวลและเงินถึง",
			["MerchantSection"] = "พ่อค้าเร่ (Wandering Merchant)",
			["MerchantAuto"] = "ซื้อของพ่อค้าเร่อัตโนมัติ",
			["MerchantAutoDesc"] = "เปิดค้างไว้ได้ตลอด ใช้ร่วมกับ Auto Farm ทุกตัว พ่อค้าเร่โผล่เมื่อไหร่ไปซื้อของให้ ซื้อเสร็จคืนตัวละครให้ระบบเดิม เงินไม่พอจะไม่ออกจากที่ฟาร์ม",
			["ChestSection"] = "เก็บหีบอัตโนมัติ",
			["AutoCollectChest"] = "เก็บหีบอัตโนมัติ",
			["AutoCollectChestDesc"] = "ไล่เก็บหีบทั่วแมพ",
			["AutoHakiSection"] = "เปิดฮาคิอัตโนมัติ",
			["AutoBuso"] = "เปิด Buso อัตโนมัติ",
			["AutoBusoDesc"] = "เปิด Buso ค้างไว้ให้",
			["AutoObservation"] = "เปิด Observation อัตโนมัติ",
			["AutoObservationDesc"] = "เปิด Observation ค้างไว้ให้",
			["SeaTeleportSection"] = "ข้ามทะเล",
			["TeleportSea1"] = "วาร์ปกลับ Sea 1",
			["TeleportSea1Desc"] = "ข้ามกลับ Sea 1",
			["TeleportSea2"] = "วาร์ปไป Sea 2",
			["TeleportSea2Desc"] = "ข้ามไป Sea 2 ต้องปลดล็อกแล้ว",
			["TeleportSea3"] = "วาร์ปไป Sea 3",
			["TeleportSea3Desc"] = "ข้ามไป Sea 3 ต้องปลดล็อกแล้ว",
			["SeaSection"] = "ไปทะเลถัดไป",
			["AutoSea2"] = "ไป Sea 2 อัตโนมัติ",
			["AutoSea2Desc"] = "ปลดล็อกและข้ามไป Sea 2 ให้ ใช้ใน Place ของ Sea 1 เลเวล 2200",
			["AutoSea3"] = "ไป Sea 3 อัตโนมัติ",
			["AutoSea3Desc"] = "ปลดล็อกและข้ามไป Sea 3 ให้ ใช้ใน Place ของ Sea 2 เลเวล 4200",
			["SwordTab"] = "ดาบ",
			["SwordSea1Section"] = "ดาบ อื่นๆ",
			["SwordSea1Status"] = "สถานะการหาดาบ",
			["SharkBladeDesc"] = "ไล่ตี Shark Boss จนได้ดาบ Shark Blade",
			["TwoSwordStyleDesc"] = "ไล่ตี Dual Swordsman เอา Book ไปแลกดาบ 2 Sword Style (2SS) กับ Doctor White",
			["GoldenStaffDesc"] = "ไล่ตี Thunder God จนได้ดาบ Golden Staff",
			["ShushiDesc"] = "ไล่ตี Ryummy จนได้ดาบ Shushi",
			["RaiuDesc"] = "ไล่ตี Shiryu จนได้ Scroll (ดรอป 5%) แล้วเอาไปแลกดาบ Raiu กับ Scroll Merchant ใช้เงิน 75,000",
			["FishmanTridentDesc"] = "ไล่ตี Neptune จนได้ Fork (ดรอป 5%) แล้วเอาไปแลกดาบ Fishman Trident กับ Fork Merchant ใช้เงิน 50,000",
			["MaceDesc"] = "ไล่ตี Marine Captain จนได้ Lava Ore (ดรอป 5%) เอาไปใส่หม้อใน Marine Base เพื่อเรียก Mace Boss แล้วตีจนได้ดาบ Mace ถ้ากรงยังไม่เปิดจะไปเก็บ Lava Key มาเปิดให้เอง",
			["FightStyleTab"] = "ท่าต่อสู้",
			["StyleV2Section"] = "ท่าต่อสู้ V2 (Sea 3)",
			["StyleV2Status"] = "สถานะการอัปเกรด V2",
			["BlackLegV2Desc"] = "ยังไม่มี Black Leg จะไปซื้อกับเทรนเนอร์ที่ Sea 3 ให้ก่อน (50,000 ไม่จำกัดเลเวล) ของขาดจะเปิด Ghost Ship ในแท็บ บอส ฟาร์ม Phantom Lantern 2 ชิ้น + เงิน 5,000,000 ให้เอง ครบแล้วไปอัป V2 กับ Sage Of Combat (สลับมาใช้ท่านี้ให้เอง ต้อง Mastery 300 และต้องเลือกอาวุธสำหรับบอสไว้)",
			["FishmanV2Desc"] = "ยังไม่มี Fishman จะไปซื้อกับเทรนเนอร์ที่ Sea 3 ให้ก่อน (450,000 เลเวล 2200) ของขาดจะเปิด Sea Beast ในแท็บ บอส ฟาร์ม Seabeast Heart 2 ชิ้น + เงิน 5,000,000 ให้เอง ครบแล้วไปอัป V2 กับ Sage Of Combat (สลับมาใช้ท่านี้ให้เอง ต้อง Mastery 300 และต้องเลือกอาวุธสำหรับบอสไว้)",
			["CyborgV2Desc"] = "ยังไม่มี Cyborg จะไปซื้อกับเทรนเนอร์ที่ Sea 3 ให้ก่อน (800,000 เลเวล 2200) ของขาดจะเปิด Saturn Boss ในแท็บ บอส ฟาร์ม Saturn's Ring 2 ชิ้น + เงิน 5,000,000 ให้เอง ครบแล้วไปอัป V2 กับ Sage Of Combat (สลับมาใช้ท่านี้ให้เอง ต้อง Mastery 300 และต้องเลือกอาวุธสำหรับบอสไว้)",
			["ElectroV2Desc"] = "ยังไม่มี Electro จะไปซื้อกับเทรนเนอร์ที่ Sea 3 ให้ก่อน (450,000 เลเวล 2200) ของขาดจะเปิด Raijin ในแท็บ บอส ฟาร์ม Raijin's Core 2 ชิ้น + 500 Gems ให้เอง ครบแล้วไปอัป V2 กับ Sage Of Combat (สลับมาใช้ท่านี้ให้เอง ต้อง Mastery 300 และต้องเลือกอาวุธสำหรับบอสไว้)",
			["DragonClawV2Desc"] = "ยังไม่มี Dragon Claw จะไปซื้อกับเทรนเนอร์ที่ Sea 3 ให้ก่อน (150 เลเวล 2200) ของขาดจะเปิด Dragon Hybrid Boss ในแท็บ บอส ฟาร์ม Dragon Heart 2 ชิ้น + 250 Gems ให้เอง ครบแล้วไปอัป V2 กับ Sage Of Combat (สลับมาใช้ท่านี้ให้เอง ต้อง Mastery 300 และต้องเลือกอาวุธสำหรับบอสไว้)",
			["AwakeningTab"] = "ปลดปล่อยพลัง (Awakening)",
			["AwakenGumSection"] = "ผล Gum (Gear 2 / 4 / 5)",
			["AwakenGumStatus"] = "สถานะการปลดพลัง Gum",
			["AwakenGear2"] = "ปลด Gear 2 อัตโนมัติ",
			["AwakenGear2Desc"] = "ไปหา Gearman Puzrat ที่ Sea 1 แล้วซื้อ Gear 2 ให้เอง ต้องกินผล Gum เลเวล 750 ขึ้นไป Gum Mastery 300 และมีเงินพอ อยู่ทะเลอื่นจะข้ามกลับ Sea 1 ให้เอง",
			["AwakenGear4"] = "ปลด Gear 4 อัตโนมัติ",
			["AwakenGear4Desc"] = "ไล่ตี G4 Boss ที่ Sea 1 เอา Gear 4 Book (ดรอป 5%) แล้วข้ามไป Sea 2 ไปปลดสกิลที่ Poneglyph ทีละสกิลจนครบ 6 สกิล ต้องกินผล Gum และ Gum Mastery 300 ต้องเลือกอาวุธสำหรับบอสไว้",
			["AwakenGear5"] = "ปลด Gear 5 อัตโนมัติ",
			["AwakenGear5Desc"] = "เปิดระบบ Dragon Boss ในแท็บ บอส ให้เอง (Sea 2) เก็บ Drums of Liberation ดรอป 100% แล้วไปปลดสกิลที่ Poneglyph จนครบ 7 สกิล ต้องกินผล Gum และ Gum Mastery 300 ต้องเลือกอาวุธสำหรับบอสไว้",
			["AwakenFruitSection"] = "ผล Electricity / Dragon (Sea 3)",
			["AwakenFruitStatus"] = "สถานะการปลดพลัง Sea 3",
			["AwakenElectricity"] = "ปลดพลัง Electricity อัตโนมัติ",
			["AwakenElectricityDesc"] = "เปิดระบบ Raijin ในแท็บ บอส ให้เอง (Sea 3) เก็บ Raijin Core ให้ครบ 7 อัน แล้วไปปลดสกิลที่ Poneglyph จนครบ 7 สกิล ต้องกินผล Electricity และ Mastery 300 ต้องเลือกอาวุธสำหรับบอสไว้ ทำได้เฉพาะ Sea 3",
			["AwakenDragon"] = "ปลดพลัง Dragon อัตโนมัติ",
			["AwakenDragonDesc"] = "เปิดระบบ Dragon Hybrid Boss ในแท็บ บอส ให้เอง (Sea 3) เก็บ Dragon's Heart ให้ครบ 6 อัน แล้วไปปลดสกิลที่ Poneglyph จนครบ 6 สกิล ต้องกินผล Dragon และ Mastery 300 ต้องเลือกอาวุธสำหรับบอสไว้ ทำได้เฉพาะ Sea 3",
			["FruitsTab"] = "ผลปีศาจ",
			["FruitSniperSection"] = "ดักเก็บผลปีศาจ",
			["FruitSniper"] = "ดักเก็บผลปีศาจอัตโนมัติ",
			["FruitSniperDesc"] = "ดักเก็บผลที่เกิดบนแมพ",
			["FruitStoreToBag"] = "เก็บใส่ Fruit Bag ทันที",
			["FruitStoreToBagDesc"] = "เก็บผลที่ได้เข้ากระเป๋าให้",
			["FruitWhitelist"] = "เลือกผลที่ต้องการ",
			["FruitWhitelistDesc"] = "ผลที่ต้องการ ไม่เลือกคือเก็บทุกชนิด",
			["FruitRefresh"] = "รีเฟรชข้อมูล",
			["FruitRefreshDesc"] = "อัปเดตรายชื่อผลบนแมพ",
			["FruitTeleportSection"] = "วาร์ปหาผลปีศาจ",
			["FruitSelect"] = "เลือกผลที่เกิดอยู่",
			["FruitSelectDesc"] = "ผลที่อยู่บนแมพตอนนี้",
			["DealerSection"] = "ซื้อผลจาก Fruit Dealer",
			["DealerAuto"] = "ซื้อผลอัตโนมัติ",
			["DealerAutoDesc"] = "เฝ้าร้านแล้วซื้อผลที่เลือกให้",
			["DealerWhitelist"] = "เลือกผลที่จะซื้อ",
			["DealerWhitelistDesc"] = "ผลที่จะซื้อ",
			["DealerStore"] = "ซื้อแล้วเก็บใส่ Fruit Bag ทันที",
			["DealerStoreDesc"] = "ซื้อแล้วเก็บเข้ากระเป๋าให้",
			["DealerTeleport"] = "วาร์ปไปหา Fruit Dealer ก่อนซื้อ",
			["DealerRefresh"] = "เช็คของในร้านตอนนี้",
			["DealerRefreshDesc"] = "ดูของที่มีในร้านตอนนี้",
			["DealerGoto"] = "วาร์ปไปหา Fruit Dealer",
			["SpinFruitSection"] = "สุ่มผลปีศาจอัตโนมัติ",
			["SpinFruitCurrency"] = "สกุลเงินที่ใช้สุ่ม",
			["SpinFruitCurrencyDesc"] = "สกุลเงินที่ใช้สุ่ม",
			["SpinFruitStore"] = "เก็บใส่ Fruit Bag หลังสุ่มได้",
			["SpinFruitStoreDesc"] = "สุ่มได้แล้วเก็บเข้ากระเป๋าให้",
			["SpinFruitAuto"] = "สุ่มผลปีศาจอัตโนมัติ",
			["SpinFruitAutoDesc"] = "สุ่มผลปีศาจวนไปเรื่อย ๆ",
			["EatSection"] = "กินผลปีศาจอัตโนมัติ",
			["EatStatus"] = "สถานะ",
			["EatSelect"] = "เลือกผลที่จะกิน",
			["EatSelectDesc"] = "ผลที่จะกิน ระบบจะเช็คในกระเป๋าและ Fruit Bag ถ้ามีจะเอาออกมาแล้วกินให้",
			["EatToggle"] = "กินผลปีศาจอัตโนมัติ",
			["EatToggleDesc"] = "ผลที่เลือกอยู่ใน Fruit Bag จะดึงออกมาใส่ช่องของ แล้วกินให้เอง กินเสร็จปิดสวิตช์ให้เอง ถ้าไม่มีผลจะรอจนกว่าจะได้มา",
			["FishingTab"] = "ตกปลา",
			["FishMainSection"] = "ตกปลาอัตโนมัติ",
			["AutoFish"] = "ตกปลาอัตโนมัติ",
			["AutoFishDesc"] = "ตกปลาวนให้อัตโนมัติ",
			["FishCastDistance"] = "ระยะเหวี่ยงเบ็ด",
			["FishCastDistanceDesc"] = "ระยะเหวี่ยงเบ็ดไปข้างหน้า",
			["BossTab"] = "บอส",
			["BossListSection"] = "บอสที่เกิดอยู่ตอนนี้",
			["BossList"] = "รายชื่อบอส",
			["BossRefresh"] = "สแกนบอสใหม่",
			["BossRefreshDesc"] = "สแกนบอสที่ยังมีชีวิตอยู่ตอนนี้",
			["BossFarmSection"] = "ตีบอสอัตโนมัติ",
			["BossSelect"] = "เลือกบอส",
			["BossSelectDesc"] = "บอสที่จะไล่ตี",
			["BossDodge"] = "หลบท่าบอส",
			["BossDodgeDesc"] = "ตีครบคอมโบแล้วลอยหลบท่าบอส",
			["AutoFarmBoss"] = "ตีบอสอัตโนมัติ",
			["AutoFarmBossDesc"] = "ไล่ตีบอสที่เลือกให้อัตโนมัติ",
			["BossTeleport"] = "วาร์ปไปหาบอส",
			["BossTeleportDesc"] = "วาร์ปไปหาบอสตัวแรกที่เลือก",
			["MobFarmSection"] = "ฟาร์มมอนอัตโนมัติ",
			["MobSelect"] = "เลือกมอน",
			["MobSelectDesc"] = "มอนที่จะฟาร์ม เฉพาะทะเลที่อยู่ตอนนี้",
			["MobAutoQuest"] = "รับเควสอัตโนมัติ",
			["MobAutoQuestDesc"] = "ตีมอนตัวไหน รับเควสของมอนตัวนั้นให้เลย",
			["AutoFarmMob"] = "ฟาร์มมอนอัตโนมัติ",
			["AutoFarmMobDesc"] = "ฟาร์มมอนที่เลือกให้ ไม่สนเลเวล",
			["BossSetupSection"] = "ตั้งค่าบอสรวม",
			["BossAutoQuest"] = "รับเควสมอนตอนฟาร์มเสกบอส",
			["BossAutoQuestDesc"] = "ตอนฟาร์มมอนเพื่อเสกบอส รับเควสของมอนตัวนั้นให้ด้วย จะได้เลเวลไปพร้อมกัน",
			["HydraSection"] = "Dragon Hybrid Boss",
			["HydraStatus"] = "สถานะ",
			["AutoSummon"] = "เรียกบอสอัตโนมัติ",
			["AutoSummonDesc"] = "เรียก Dragon Hybrid Boss ให้ ใช้ได้เฉพาะ Sea 3",
			["AutoKill"] = "ตีบอสอัตโนมัติ",
			["AutoKillDesc"] = "บอสเกิดเมื่อไหร่เข้าตีให้ทันที",
			["RaijinSection"] = "Raijin Boss",
			["RaijinStatus"] = "สถานะ",
			["RaijinSummon"] = "เรียก Raijin อัตโนมัติ",
			["RaijinSummonDesc"] = "เรียก Raijin ให้ ใช้ได้เฉพาะ Sea 3",
			["RaijinKill"] = "ตี Raijin อัตโนมัติ",
			["RaijinKillDesc"] = "Raijin เกิดเมื่อไหร่เข้าตีให้ทันที",
			["DoughSection"] = "Dough Boss",
			["DoughStatus"] = "สถานะ",
			["DoughFragment"] = "ฟาร์ม Mirror Fragment",
			["DoughFragmentDesc"] = "ฟาร์ม Mirror Fragment ให้ ใช้ได้เฉพาะ Sea 2",
			["DoughUnlock"] = "ปลดล็อค Mirror World",
			["DoughUnlockDesc"] = "ปลดล็อก Mirror World ให้",
			["DoughSpawn"] = "เรียก Dough Boss อัตโนมัติ",
			["DoughSpawnDesc"] = "จ่ายเจมเรียก Dough Boss ให้",
			["DoughKill"] = "ตี Dough Boss อัตโนมัติ",
			["DoughKillDesc"] = "Dough Boss เกิดเมื่อไหร่เข้าตีให้ทันที",
			["DragonSection"] = "Dragon Boss",
			["DragonStatus"] = "สถานะ",
			["DragonSummon"] = "เรียก Dragon Boss อัตโนมัติ",
			["DragonSummonDesc"] = "เรียก Dragon Boss ให้ ใช้ได้เฉพาะ Sea 2",
			["DragonKill"] = "ตี Dragon Boss อัตโนมัติ",
			["DragonKillDesc"] = "Dragon Boss เกิดเมื่อไหร่เข้าตีให้ทันที",
			["ZenithSection"] = "Zenith Boss",
			["ZenithStatus"] = "สถานะ",
			["ZenithKill"] = "ตี Zenith Boss อัตโนมัติ",
			["ZenithKillDesc"] = "เฝ้าจุดเกิด Zenith Boss แล้วเข้าตีให้ ใช้ได้เฉพาะ Sea 2",
			["SaturnSection"] = "Saturn Boss",
			["SaturnStatus"] = "สถานะ",
			["SaturnKill"] = "ตี Saturn Boss อัตโนมัติ",
			["SaturnKillDesc"] = "มีอีเวนต์ที่ Egg Island เมื่อไหร่ไปไล่เก็บเวฟจนถึง Saturn Boss ใช้ได้เฉพาะ Sea 3",
			["EnmaSection"] = "Enma Boss",
			["EnmaStatus"] = "สถานะ",
			["EnmaKill"] = "ตี Enma Boss อัตโนมัติ",
			["EnmaKillDesc"] = "เฝ้าจุดเกิด Enma Boss แล้วเข้าตีให้ ใช้ได้เฉพาะ Sea 2",
			["VaultSection"] = "Vault Chest",
			["VaultStatus"] = "สถานะ",
			["VaultKill"] = "ตี Vault Chest อัตโนมัติ",
			["VaultKillDesc"] = "คอยสแกนหา Vault Chest ที่เกิดเอง แล้วเข้าตีให้ ใช้ได้เฉพาะ Sea 2",
			["RedEmperorSection"] = "Red Emperor Boss",
			["RedEmperorStatus"] = "สถานะ",
			["RedEmperorKill"] = "ตี Red Emperor Boss อัตโนมัติ",
			["RedEmperorKillDesc"] = "บอสเกิดเมื่อไหร่เข้าตีให้ทันที ใช้ได้เฉพาะ Sea 3",
			["RedEmperorWait"] = "ไปรอที่ Throne Room ก่อนบอสเกิด",
			["RedEmperorWaitDesc"] = "ใกล้เวลาบอสเกิดแล้วไปรอที่จุดเกิดให้ ปิดไว้ = ไม่ออกจากที่ฟาร์ม รอให้บอสโผล่ใกล้ ๆ เอง",
			["RedEmperorBefore"] = "ไปรอก่อนกี่วินาที",
			["RedEmperorBeforeDesc"] = "เหลือเวลาน้อยกว่านี้ถึงจะไปรอ",
			["GhostSection"] = "Ghost Ship",
			["GhostStatus"] = "สถานะ",
			["GhostKill"] = "ตี Ghost Ship อัตโนมัติ",
			["GhostKillDesc"] = "เรือผีโผล่เมื่อไหร่เข้าตีทันที ไม่ว่าใครจะเป็นคนเรียก เปิดทิ้งไว้ได้",
			["GhostSummon"] = "เรียก Ghost Ship อัตโนมัติ",
			["GhostSummonDesc"] = "เรียกเรือผีให้เอง ใช้ผลปีศาจเป็นค่าเรียก ต้องเลือกผลที่ยอมให้ใช้ด้านล่างก่อน",
			["GhostSource"] = "เอาผลมาจากไหน",
			["GhostSourceDesc"] = "เลือกได้อย่างเดียว Fruit Bag = ใช้ผลในกระเป๋า, In Backpack = ใช้ผลที่พกติดตัว, Buy Fruit = ซื้อผลจากร้าน Fruit Dealer ตอนนั้นมาใช้เลย",
			["GhostFruits"] = "ผลที่ยอมให้ใช้เรียกเรือ",
			["GhostFruitsDesc"] = "เลือกชนิดผลที่จะเอาไปใช้เรียกเรือ ใช้เฉพาะที่เลือกไว้ ชนิดอื่นไม่แตะ ต้องเลือกอย่างน้อย 1 ชนิด ไม่งั้นเปิดเรียกเรืออัตโนมัติไม่ได้ โหมด Buy Fruit ไม่ใช้ช่องนี้ ดูแค่ระดับผลด้านล่างอย่างเดียว",
			["GhostRarity"] = "ระดับผลที่ยอมให้ใช้",
			["GhostRarityDesc"] = "กรองเพิ่มจากรายชื่อผลด้านบน ใช้เฉพาะระดับที่เลือก เว้นว่าง = ใช้ได้ทุกระดับของผลที่เลือกไว้ โหมด Buy Fruit ใช้ช่องนี้อย่างเดียว เลือกระดับไหนซื้อระดับนั้น เช่น Common, Uncommon และต้องเลือกอย่างน้อย 1 ระดับ",
			["CthulhuSection"] = "Cthulhu",
			["CthulhuStatus"] = "สถานะ",
			["CthulhuKill"] = "ตี Cthulhu อัตโนมัติ",
			["CthulhuKillDesc"] = "รอข้อความประกาศจากเซิร์ฟเวอร์ (Something ancient has awakened beneath the sea) แล้วค่อยบินออกทะเลไปตี ไม่ว่าใครจะเป็นคนเรียก ยังไม่มีประกาศจะไม่ออกจากที่ฟาร์ม บอสมี 2 หลอดเลือด ไม่หายไปเองจนกว่าจะตาย ใช้ได้เฉพาะ Sea 3 เปิดทิ้งไว้ได้",
			["CthulhuSummon"] = "เรียก Cthulhu อัตโนมัติ",
			["CthulhuSummonDesc"] = "รอพายุ (ทุก 2 ชม. 35 นาที) ก่อนถึงจะออกจากที่ฟาร์ม พายุมาแล้วค่อยไปคราฟ Shard แล้วต่อไปโยนใส่น้ำวนใต้ Rainbow Sky Islands ใน Sea 3 รวดเดียว ยืนลอยเหนือน้ำและล็อกตัวไว้กันตกน้ำตาย ไม่มี Shard จะไปคราฟที่ Doran the Forge ให้ถ้าเปิดสวิตช์ด้านล่าง",
			["CthulhuCraft"] = "คราฟ Prismatic Shard อัตโนมัติ",
			["CthulhuCraftDesc"] = "ไม่มี Shard จะบินไปคราฟกับ Doran the Forge ให้ ใช้ Phantom Lantern, Dragon Heart, Seabeast Heart, Raijin's Core, Saturn's Ring อย่างละ 1 ชิ้น ของไม่ครบจะไม่คราฟ",
			["BeastSection"] = "Sea Beast",
			["BeastStatus"] = "สถานะ",
			["BeastKill"] = "ตี Sea Beast อัตโนมัติ",
			["BeastKillDesc"] = "เจอ Sea Beast ใกล้ ๆ เข้าตีให้ทันที ไม่ออกไปหาเอง",
			["BeastFind"] = "ออกไปหา Sea Beast อัตโนมัติ",
			["BeastFindDesc"] = "ออกไปหา Sea Beast ให้เอง หาไม่เจอก็เลิกหา คืนตัวละครให้ระบบเดิม แล้วรอรอบถัดไป",
			["BeastInterval"] = "ออกไปหาทุกกี่นาที",
			["BeastIntervalDesc"] = "เว้นระยะกี่นาทีถึงจะออกไปหารอบใหม่ นับใหม่หลังฆ่า Sea Beast ได้ หรือหลังหาไม่เจอ",
			["BeastDuration"] = "ออกไปหานานกี่นาที",
			["BeastDurationDesc"] = "หานานสุดกี่นาทีต่อรอบ หมดเวลาแล้วยังไม่เจอก็เลิกหา คืนตัวละครให้ระบบเดิม",
			["PrioritySection"] = "ลำดับความสำคัญของบอส",
			["PriorityStatus"] = "ลำดับตอนนี้",
			["PrioritySelect"] = "เลือกบอส",
			["PrioritySelectDesc"] = "เลือกบอสที่จะเลื่อนลำดับ แล้วกดปุ่มเลื่อนขึ้น/ลง ดูลำดับจริงที่ช่อง ลำดับตอนนี้ ด้านบน เปิดบอสพร้อมกันได้หมด เกิดพร้อมกันตัวลำดับสูงกว่าได้ตีก่อน",
			["PriorityUp"] = "เลื่อนขึ้น",
			["PriorityUpDesc"] = "เลื่อนบอสที่เลือกขึ้น 1 ลำดับ",
			["PriorityDown"] = "เลื่อนลง",
			["PriorityDownDesc"] = "เลื่อนบอสที่เลือกลง 1 ลำดับ",
			["PriorityReset"] = "รีเซ็ตลำดับ",
			["PriorityResetDesc"] = "กลับไปใช้ลำดับเริ่มต้น",
			["HopSection"] = "Hop Server",
			["HopEnable"] = "Hop Server อัตโนมัติ",
			["HopEnableDesc"] = "บอสที่เลือกไว้ไม่เกิดสักตัว ย้ายเซิร์ฟไปหาใหม่",
			["HopBosses"] = "Hop รอบอสตัวไหน",
			["HopBossesDesc"] = "บอสที่จะรอ ไม่เลือก = รอทุกตัวที่เปิดไว้",
			["HopStatus"] = "สถานะ",
			["HopWait"] = "รอกี่วินาทีก่อนย้าย",
			["HopWaitDesc"] = "ไม่เจอบอสนานเท่านี้แล้วค่อยย้ายเซิร์ฟ",
			["SkillTab"] = "สกิล",
			["SkillSection"] = "กดสกิลอัตโนมัติ",
			["SkillMelee"] = "ปุ่มสกิลหมัด/ท่าต่อสู้",
			["SkillMeleeDesc"] = "ปุ่มท่าต่อสู้ที่จะกดให้",
			["SkillFruit"] = "ปุ่มสกิลผลปีศาจ",
			["SkillFruitDesc"] = "ปุ่มท่าผลปีศาจที่จะกดให้",
			["SkillSword"] = "ปุ่มสกิลดาบ",
			["SkillSwordDesc"] = "ปุ่มท่าดาบที่จะกดให้",
			["SkillHold"] = "ระยะเวลากดค้าง",
			["SkillHoldDesc"] = "เวลากดค้างต่อหนึ่งปุ่ม",
			["SkillDelay"] = "ดีเลย์ระหว่างรอบ",
			["SkillDelayDesc"] = "เวลาหน่วงระหว่างรอบ",
			["SkillUseOn"] = "ใช้กับ",
			["SkillUseOnDesc"] = "ใช้สกิลกับมอน บอส หรือทั้งคู่",
			["SkillRange"] = "ระยะเล็งเป้า",
			["SkillRangeDesc"] = "ระยะที่มองหาศัตรูก่อนปล่อยสกิล",
			["SkillToggle"] = "กดสกิลอัตโนมัติ",
			["SkillToggleDesc"] = "กดสกิลให้เองเมื่อมีศัตรูอยู่ในระยะ",
			["MiscTab"] = "อื่น ๆ",
			["MiscSection"] = "ลูกเล่นการเคลื่อนที่",
			["DashNoCooldown"] = "แดชไม่มีคูลดาวน์",
			["DashNoCooldownDesc"] = "แดชได้รัว ไม่ต้องรอคูลดาวน์",
			["SkyJumpInf"] = "กระโดดอากาศไม่จำกัด (เกปโป)",
			["SkyJumpInfDesc"] = "กระโดดอากาศ (เกปโป) ได้ไม่จำกัด",
			["InfiniteJump"] = "กระโดดกลางอากาศไม่จำกัด",
			["InfiniteJumpDesc"] = "กระโดดกลางอากาศได้ไม่จำกัด",
			["CodeSection"] = "โค้ด",
			["RedeemAllCodes"] = "แลกโค้ดทั้งหมด",
			["RedeemAllCodesDesc"] = "ไล่แลกโค้ดทุกตัวในลิสต์ให้เอง ตัวที่แลกไปแล้วหรือหมดอายุจะข้ามให้",
			["WebhookTab"] = "แจ้งเตือน",
			["WebhookSetupSection"] = "ตั้งค่า Webhook",
			["WebhookStatus"] = "สถานะ Webhook",
			["WebhookUrl"] = "ลิงก์ Webhook",
			["WebhookUrlDesc"] = "วางลิงก์ Webhook ของห้อง Discord ที่จะให้ส่งไปหา ต้องขึ้นต้นด้วย https://discord.com/api/webhooks/",
			["WebhookUserId"] = "ไอดี Discord ที่จะแท็ก",
			["WebhookUserIdDesc"] = "ไอดีตัวเลขของคุณ ใส่แล้วเหตุการณ์ที่เลือกไว้ในช่องแท็กจะแท็กหาคุณ เว้นว่างได้",
			["WebhookHideName"] = "ซ่อนชื่อผู้เล่น",
			["WebhookHideNameDesc"] = "ปิดชื่อ Roblox ในข้อความ เหลือแค่ตัวอักษรหน้ากับหลัง",
			["WebhookTest"] = "ทดสอบส่ง",
			["WebhookTestDesc"] = "ส่งข้อความทดสอบไปที่ลิงก์ที่ใส่ไว้ทันที ใช้เช็กว่าลิงก์ใช้ได้จริง",
			["WebhookEventSection"] = "เลือกเหตุการณ์ที่จะแจ้ง",
			["WebhookEvStart"] = "เปิดสคริปต์",
			["WebhookEvStartDesc"] = "ส่งข้อมูลตัวละครทุกครั้งที่สคริปต์เริ่มทำงาน",
			["WebhookEvMerchant"] = "ซื้อของพ่อค้าเร่",
			["WebhookEvMerchantDesc"] = "ซื้อของจาก Wandering Merchant ได้เมื่อไหร่ส่งรายการกับราคาให้",
			["WebhookEvBoss"] = "ฆ่าบอส",
			["WebhookEvBossDesc"] = "บอสที่อยู่ใกล้ตัวละครตายเมื่อไหร่ส่งชื่อบอส โซน และเวลาที่ใช้ให้",
			["WebhookEvFruit"] = "ได้ผลปีศาจ",
			["WebhookEvFruitDesc"] = "มีผลปีศาจเข้ากระเป๋าเมื่อไหร่ส่งชื่อผลให้",
			["WebhookEvSword"] = "ได้ดาบใหม่",
			["WebhookEvSwordDesc"] = "ได้ดาบที่ยังไม่เคยมีเมื่อไหร่ส่งชื่อดาบให้",
			["WebhookEvAccessory"] = "ได้เครื่องประดับใหม่",
			["WebhookEvAccessoryDesc"] = "ได้เครื่องประดับที่ยังไม่เคยมีเมื่อไหร่ส่งชื่อให้",
			["WebhookEvLevel"] = "เลเวลอัป",
			["WebhookEvLevelDesc"] = "ส่งตอนเลเวลถึงหลักที่ตั้งไว้ด้านล่าง ไม่ได้ส่งทุกเลเวล",
			["WebhookEvSea"] = "ปลดล็อกทะเลใหม่",
			["WebhookEvSeaDesc"] = "ปลดล็อก Sea 2 หรือ Sea 3 ได้เมื่อไหร่ส่งให้",
			["WebhookEvDeath"] = "ตัวละครตาย",
			["WebhookEvDeathDesc"] = "ตัวละครตายเมื่อไหร่ส่งโซนที่ตายให้",
			["WebhookEvHop"] = "ย้ายเซิร์ฟเวอร์",
			["WebhookEvHopDesc"] = "ส่งตอนสคริปต์ย้ายเซิร์ฟหรือถูกเตะไปเซิร์ฟอื่น",
			["WebhookLevelStep"] = "ส่งเลเวลอัปทุกกี่เลเวล",
			["WebhookLevelStepDesc"] = "ส่งเฉพาะตอนเลเวลหารด้วยเลขนี้ลงตัว กัน Discord เด้งรัว",
			["WebhookPing"] = "เหตุการณ์ที่จะแท็กหาคุณ",
			["WebhookPingDesc"] = "เหตุการณ์ที่เลือกไว้จะแท็กไอดีด้านบน ต้องใส่ไอดีก่อนถึงจะแท็กได้",
			["WebhookHeartSection"] = "รายงานตามเวลา",
			["WebhookHeart"] = "ส่งสรุปเป็นระยะ",
			["WebhookHeartDesc"] = "ส่งสรุปรอบการเล่นให้เองทุก ๆ กี่นาทีตามที่ตั้งไว้",
			["WebhookHeartMinutes"] = "ส่งทุกกี่นาที",
			["WebhookHeartMinutesDesc"] = "ระยะห่างระหว่างสรุปแต่ละรอบ",
			["WebhookViewSection"] = "กดดูข้อมูลเอง",
			["WebhookViewPlayer"] = "ดูข้อมูลตัวละคร",
			["WebhookViewPlayerDesc"] = "ส่งเลเวล เงิน เจม ผลที่กิน ดาบที่ถือ ไปที่ Discord ทันที",
			["WebhookViewFruit"] = "ดูผลปีศาจในกระเป๋า",
			["WebhookViewFruitDesc"] = "ส่งรายการผลปีศาจทั้งหมดในกระเป๋าไปที่ Discord ทันที",
			["WebhookViewSword"] = "ดูดาบที่มี",
			["WebhookViewSwordDesc"] = "ส่งรายชื่อดาบที่มีแล้วไปที่ Discord ทันที",
			["WebhookViewBoss"] = "ดูบอสที่เกิดอยู่",
			["WebhookViewBossDesc"] = "ส่งรายชื่อบอสที่ยังมีชีวิตในเซิร์ฟตอนนี้กับระยะห่างไปที่ Discord ทันที",
			["WebhookViewRunner"] = "ดูระบบที่กำลังทำงาน",
			["WebhookViewRunnerDesc"] = "ส่งรายชื่อระบบที่เปิดอยู่และตัวที่กำลังคุมตัวละครไปที่ Discord ทันที",
			["WebhookViewSession"] = "ดูสรุปรอบนี้",
			["WebhookViewSessionDesc"] = "ส่งสรุปเวลาเล่น เลเวลที่ขึ้น เงินที่ได้ บอสที่ฆ่า ไปที่ Discord ทันที",
		},
		["English (US)"] = {
			["GroupMain"] = "General",
			["GroupFarm"] = "Farming",
			["GroupItem"] = "Items & Shop",
			["GroupTravel"] = "Travel",
			["GroupSystem"] = "System",
			["Configuration"] = "Configuration",
			["Interface"] = "Interface Settings",
			["themeDropdown"] = "Select Theme",
			["themeDropdownDesc"] = "Window color scheme.",
			["ToggleTransparency"] = "Window Transparency",
			["ToggleTransparencyDesc"] = "Makes the window background see-through.",
			["AntiAFK"] = "Anti-AFK",
			["AntiAFKDesc"] = "Keeps the idle kick from landing.",
			["AutoRejoin"] = "Auto Rejoin",
			["AutoRejoinDesc"] = "Rejoins the same place after a disconnect.",
			["AutoExecutor"] = "Auto Executor",
			["AutoExecutorDesc"] = "Runs the script again after a server change.",
			["MinimizeBind"] = "Minimize Bind",
			["MinimizeBindDesc"] = "Key that shows and hides the window.",
			["FPSIS"] = "FPS",
			["FPSVALUE"] = "FPS Value",
			["FPSVALUEDesc"] = "Frame cap used by FPS Lock.",
			["FPSLOCK"] = "FPS Lock",
			["FPSLOCKDesc"] = "Locks the frame rate to the value above.",
			["WhiteScreen"] = "Blank Screen",
			["WhiteScreenDesc"] = "Solid overlay that stops the game rendering, for less lag.",
			["ScreenColor"] = "Screen Color",
			["ScreenColorDesc"] = "Colour of the overlay, white or black. Changes right away while it is on.",
			["LanguageTab"] = "Language",
			["Language"] = "Select Language",
			["LanguageDesc"] = "Script language.",
			["ChangedLanguage"] = "Change Language",
			["ChangedLanguageDesc"] = "Applies the selected language.",
			["ScriptLoader"] = "Script Loader",
			["ScriptLoaded"] = "Script has been loaded successfully.",
			["ConfigSection"] = "Config",
			["ConfigName"] = "Config Name",
			["ConfigNameDesc"] = "Name it before creating. Left empty, it is named after the date and time.",
			["ConfigCreate"] = "Create Config",
			["ConfigCreateDesc"] = "Save every current setting as a new config.",
			["ConfigList"] = "Select Config",
			["ConfigListDesc"] = "Every config saved on this device.",
			["ConfigLoad"] = "Load Config",
			["ConfigLoadDesc"] = "Apply the selected config right away. Every menu widget follows, no script reload.",
			["ConfigDelete"] = "Delete Config",
			["ConfigDeleteDesc"] = "Remove the selected config from this device.",
			["ConfigRefresh"] = "Refresh List",
			["ConfigRefreshDesc"] = "Read the config list again.",
			["InfoTab"] = "Info",
			["InfoPlayerSection"] = "Player",
			["InfoPlayer"] = "Profile",
			["InfoFruitSection"] = "Devil Fruits",
			["InfoFruit"] = "Fruits Owned",
			["InfoSwordSection"] = "Swords",
			["InfoSword"] = "Every Sword In Game",
			["InfoAccessorySection"] = "Accessories",
			["InfoAccessory"] = "Every Accessory In Game",
			["InfoStyleSection"] = "Fighting Styles",
			["InfoStyle"] = "Every Fighting Style In Game",
			["InfoHakiSection"] = "Haki",
			["InfoHaki"] = "Haki And Haki Colors",
			["Automatic"] = "Automatic",
			["AutoFarmSection"] = "Auto Farm Level",
			["SelectWeapon"] = "Select Weapon",
			["SelectWeaponDesc"] = "Weapon type every farm swings (Melee / Sword / Fruit). Swap sword or fruit in game, no need to pick again.",
			["SelectBossWeapon"] = "Select Boss Weapon",
			["SelectBossWeaponDesc"] = "Weapon type the Boss tab swings. Nothing in the Boss tab runs until this is set.",
			["AutoQuestAccept"] = "Auto Accept Quest",
			["AutoQuestAcceptDesc"] = "Keeps the quest matching the mob being farmed.",
			["AutoFarmLevel"] = "Auto Farm Level",
			["AutoFarmLevelDesc"] = "Farms the mob for your level automatically.",
			["FarmTab"] = "Farm Settings",
			["WeaponSection"] = "Weapon",
			["FarmSettings"] = "Movement & Attack Position",
			["AttackPosition"] = "Method",
			["AttackPositionDesc"] = "Where you stand relative to the mob.",
			["Distance"] = "Distance From Mob",
			["DistanceDesc"] = "Distance kept from the mob while attacking.",
			["TweenSpeed"] = "Tween Speed",
			["TweenSpeedDesc"] = "Travel speed for every flight and teleport.",
			["AutoUpgradeSection"] = "Auto Upgrade Stats",
			["SelectStats"] = "Select Stats",
			["SelectStatsDesc"] = "Stats to upgrade.",
			["PointsPerUpgrade"] = "Points Per Upgrade",
			["PointsPerUpgradeDesc"] = "Points spent per upgrade.",
			["AutoUpgradeToggle"] = "Auto Upgrade",
			["AutoUpgradeToggleDesc"] = "Spends stat points as they come in.",
			["Teleport"] = "Teleport",
			["SpawnSection"] = "Spawn Point",
			["AutoSetSpawn"] = "Auto Set Spawn",
			["AutoSetSpawnDesc"] = "Keeps your spawn set to the island you are on.",
			["SetSpawnNow"] = "Set Spawn Here",
			["SetSpawnNowDesc"] = "Sets your spawn to the nearest island once.",
			["IslandSection"] = "Island Teleport",
			["SelectIsland"] = "Select Island",
			["SelectIslandDesc"] = "Island to travel to.",
			["IslandMode"] = "Teleport Mode",
			["IslandModeDesc"] = "Tween flies you there. Set Spawn sets the spawn point then resets your character.",
			["TeleportGo"] = "Teleport",
			["TeleportGoDesc"] = "Teleports to the selected island.",
			["FruitTeleportGoDesc"] = "Teleports to the selected fruit.",
			["ShopTab"] = "Shop",
			["HakiShopSection"] = "Auto Buy Haki",
			["SwordShopSection"] = "Buy Sword",
			["SelectSword"] = "Select Sword",
			["SelectSwordDesc"] = "Sword to buy, with price and required level.",
			["BuySword"] = "Buy Sword",
			["BuySwordDesc"] = "Buys the selected sword.",
			["AutoBuyBuso"] = "Buy Buso Haki",
			["AutoBuyBusoDesc"] = "Buys Buso Haki once your level and Beli are enough.",
			["AutoBuyObservation"] = "Buy Observation Haki",
			["AutoBuyObservationDesc"] = "Buys Observation Haki once your level and Beli are enough.",
			["MerchantSection"] = "Wandering Merchant",
			["MerchantAuto"] = "Auto Buy Wandering Merchant",
			["MerchantAutoDesc"] = "Safe to leave on next to any Auto Farm. Buys from the merchant the moment it shows up, then hands the character back. Stays put if you cannot afford anything.",
			["ChestSection"] = "Auto Collect Chest",
			["AutoCollectChest"] = "Auto Collect Chest",
			["AutoCollectChestDesc"] = "Collects chests around the map.",
			["AutoHakiSection"] = "Auto Haki",
			["AutoBuso"] = "Auto Buso",
			["AutoBusoDesc"] = "Keeps Buso turned on.",
			["AutoObservation"] = "Auto Observation",
			["AutoObservationDesc"] = "Keeps Observation turned on.",
			["SeaTeleportSection"] = "Sea Travel",
			["TeleportSea1"] = "Teleport To Sea 1",
			["TeleportSea1Desc"] = "Crosses back to Sea 1.",
			["TeleportSea2"] = "Teleport To Sea 2",
			["TeleportSea2Desc"] = "Crosses to Sea 2 once it is unlocked.",
			["TeleportSea3"] = "Teleport To Sea 3",
			["TeleportSea3Desc"] = "Crosses to Sea 3 once it is unlocked.",
			["SeaSection"] = "Next Sea",
			["AutoSea2"] = "Auto Sea 2",
			["AutoSea2Desc"] = "Unlocks and crosses to Sea 2. Sea 1 place, level 2200.",
			["AutoSea3"] = "Auto Sea 3",
			["AutoSea3Desc"] = "Unlocks and crosses to Sea 3. Sea 2 place, level 4200.",
			["SwordTab"] = "Sword",
			["SwordSea1Section"] = "Sword other",
			["SwordSea1Status"] = "Sword Hunt Status",
			["SharkBladeDesc"] = "Farms Shark Boss until Shark Blade drops.",
			["TwoSwordStyleDesc"] = "Farms Dual Swordsman for the Book, then trades it to Doctor White for 2 Sword Style (2SS).",
			["GoldenStaffDesc"] = "Farms Thunder God until Golden Staff drops.",
			["ShushiDesc"] = "Farms Ryummy until Shushi drops.",
			["RaiuDesc"] = "Farms Shiryu for the Scroll (5% drop), then trades it to the Scroll Merchant for Raiu. Costs 75,000 Beli.",
			["FishmanTridentDesc"] = "Farms Neptune for the Fork (5% drop), then trades it to the Fork Merchant for Fishman Trident. Costs 50,000 Beli.",
			["MaceDesc"] = "Farms Marine Captain for the Lava Ore (5% drop), burns it in the Marine Base cauldron and kills the Mace Boss it summons for the Mace. Grabs the Lava Key and opens the cage first if it is still locked.",
			["FightStyleTab"] = "Fighting Style",
			["StyleV2Section"] = "Fighting Style V2 (Sea 3)",
			["StyleV2Status"] = "V2 Upgrade Status",
			["BlackLegV2Desc"] = "Buys Black Leg from its Sea 3 trainer if you do not own it (50,000 Beli, no level gate), then turns Ghost Ship on in the Boss tab until 2x Phantom Lantern and 5,000,000 Beli are in, and evolves it at the Sage Of Combat. Equips the style for you. Needs mastery 300 and a Boss Weapon selected.",
			["FishmanV2Desc"] = "Buys Fishman from its Sea 3 trainer if you do not own it (450,000 Beli at level 2200), then turns Sea Beast on in the Boss tab until 2x Seabeast Heart and 5,000,000 Beli are in, and evolves it at the Sage Of Combat. Equips the style for you. Needs mastery 300 and a Boss Weapon selected.",
			["CyborgV2Desc"] = "Buys Cyborg from its Sea 3 trainer if you do not own it (800,000 Beli at level 2200), then turns Saturn Boss on in the Boss tab until 2x Saturn's Ring and 5,000,000 Beli are in, and evolves it at the Sage Of Combat. Equips the style for you. Needs mastery 300 and a Boss Weapon selected.",
			["ElectroV2Desc"] = "Buys Electro from its Sea 3 trainer if you do not own it (450,000 Beli at level 2200), then turns Raijin on in the Boss tab until 2x Raijin's Core and 500 Gems are in, and evolves it at the Sage Of Combat. Equips the style for you. Needs mastery 300 and a Boss Weapon selected.",
			["DragonClawV2Desc"] = "Buys Dragon Claw from its Sea 3 trainer if you do not own it (150 Beli at level 2200), then turns Dragon Hybrid Boss on in the Boss tab until 2x Dragon Heart and 250 Gems are in, and evolves it at the Sage Of Combat. Equips the style for you. Needs mastery 300 and a Boss Weapon selected.",
			["AwakeningTab"] = "Awakening",
			["AwakenGumSection"] = "Gum Fruit (Gear 2 / 4 / 5)",
			["AwakenGumStatus"] = "Gum Awakening Status",
			["AwakenGear2"] = "Auto Gear 2",
			["AwakenGear2Desc"] = "Flies to Gearman Puzrat in Sea 1 and buys Gear 2. Needs the Gum fruit eaten, level 750, 300 Gum mastery and the Beli. Crosses back to Sea 1 on its own.",
			["AwakenGear4"] = "Auto Gear 4",
			["AwakenGear4Desc"] = "Farms G4 Boss in Sea 1 for the Gear 4 Book (5% drop), then crosses to Sea 2 and spends one book per skill at the Poneglyph until all 6 are awakened. Needs the Gum fruit eaten, 300 Gum mastery and a Boss Weapon selected.",
			["AwakenGear5"] = "Auto Gear 5",
			["AwakenGear5Desc"] = "Turns the Dragon Boss module on in the Boss tab (Sea 2) for Drums of Liberation at 100%, then spends one per skill at the Poneglyph until all 7 are awakened. Needs the Gum fruit eaten, 300 Gum mastery and a Boss Weapon selected.",
			["AwakenFruitSection"] = "Electricity / Dragon Fruit (Sea 3)",
			["AwakenFruitStatus"] = "Sea 3 Awakening Status",
			["AwakenElectricity"] = "Auto Electricity Awakening",
			["AwakenElectricityDesc"] = "Turns the Raijin module on in the Boss tab (Sea 3) until 7x Raijin Core are in, then spends one per skill at the Poneglyph until all 7 are awakened. Needs the Electricity fruit eaten, 300 mastery and a Boss Weapon selected. Sea 3 only.",
			["AwakenDragon"] = "Auto Dragon Awakening",
			["AwakenDragonDesc"] = "Turns the Dragon Hybrid Boss module on in the Boss tab (Sea 3) until 6x Dragon's Heart are in, then spends one per skill at the Poneglyph until all 6 are awakened. Needs the Dragon fruit eaten, 300 mastery and a Boss Weapon selected. Sea 3 only.",
			["FruitsTab"] = "Fruits",
			["FruitSniperSection"] = "Fruit Sniper",
			["FruitSniper"] = "Auto Fruit Sniper",
			["FruitSniperDesc"] = "Grabs fruits as they spawn on the map.",
			["FruitStoreToBag"] = "Store Into Fruit Bag",
			["FruitStoreToBagDesc"] = "Stores picked up fruit into the bag.",
			["FruitWhitelist"] = "Wanted Fruits",
			["FruitWhitelistDesc"] = "Fruits to grab. Empty means every fruit.",
			["FruitRefresh"] = "Refresh",
			["FruitRefreshDesc"] = "Refreshes the list of fruits on the map.",
			["FruitTeleportSection"] = "Fruit Teleport",
			["FruitSelect"] = "Select Spawned Fruit",
			["FruitSelectDesc"] = "Fruits on the map right now.",
			["DealerSection"] = "Fruit Dealer Shop",
			["DealerAuto"] = "Auto Buy Fruit",
			["DealerAutoDesc"] = "Watches the shop and buys the fruits you picked.",
			["DealerWhitelist"] = "Fruits To Buy",
			["DealerWhitelistDesc"] = "Fruits to buy.",
			["DealerStore"] = "Store Into Fruit Bag After Buying",
			["DealerStoreDesc"] = "Stores each purchase into the bag.",
			["DealerTeleport"] = "Teleport To Dealer Before Buying",
			["DealerRefresh"] = "Check Current Stock",
			["DealerRefreshDesc"] = "Shows what the shop has in stock.",
			["DealerGoto"] = "Teleport To Fruit Dealer",
			["SpinFruitSection"] = "Auto Spin Fruit",
			["SpinFruitCurrency"] = "Spin Currency",
			["SpinFruitCurrencyDesc"] = "Currency used per spin.",
			["SpinFruitStore"] = "Store Into Fruit Bag After Spinning",
			["SpinFruitStoreDesc"] = "Stores the fruit you roll into the bag.",
			["SpinFruitAuto"] = "Auto Spin Fruit",
			["SpinFruitAutoDesc"] = "Keeps spinning for Devil Fruits.",
			["EatSection"] = "Auto Eat Fruit",
			["EatStatus"] = "Status",
			["EatSelect"] = "Fruit To Eat",
			["EatSelectDesc"] = "Fruit it eats. It checks your backpack and the Fruit Bag, takes the fruit out and eats it.",
			["EatToggle"] = "Auto Eat Fruit",
			["EatToggleDesc"] = "Pulls the picked fruit out of the Fruit Bag and eats it, then switches itself off. With no copy anywhere it waits until one turns up.",
			["FishingTab"] = "Fishing",
			["FishMainSection"] = "Auto Fishing",
			["AutoFish"] = "Auto Fish",
			["AutoFishDesc"] = "Fishes on a loop.",
			["FishCastDistance"] = "Cast Distance",
			["FishCastDistanceDesc"] = "How far the line is cast in front of you.",
			["BossTab"] = "Boss",
			["BossListSection"] = "Bosses Alive Right Now",
			["BossList"] = "Boss List",
			["BossRefresh"] = "Rescan Bosses",
			["BossRefreshDesc"] = "Scans for bosses that are alive right now.",
			["BossFarmSection"] = "Auto Boss Farm",
			["BossSelect"] = "Select Bosses",
			["BossSelectDesc"] = "Bosses to hunt.",
			["BossDodge"] = "Dodge Boss Moves",
			["BossDodgeDesc"] = "Floats away between combos to dodge boss moves.",
			["AutoFarmBoss"] = "Auto Farm Boss",
			["AutoFarmBossDesc"] = "Hunts the selected bosses automatically.",
			["BossTeleport"] = "Teleport To Boss",
			["BossTeleportDesc"] = "Teleports to the first selected boss.",
			["MobFarmSection"] = "Auto Farm Mob",
			["MobSelect"] = "Select Mobs",
			["MobSelectDesc"] = "Mobs to farm, from this sea only.",
			["MobAutoQuest"] = "Auto Accept Quest",
			["MobAutoQuestDesc"] = "Takes the quest of whichever mob is being farmed.",
			["AutoFarmMob"] = "Auto Farm Mob",
			["AutoFarmMobDesc"] = "Farms the selected mobs, no level gate.",
			["BossSetupSection"] = "Boss Settings",
			["BossAutoQuest"] = "Auto Accept Quest While Summoning",
			["BossAutoQuestDesc"] = "Takes the quest of the mob a summon farm is grinding, so those kills pay level progress too.",
			["HydraSection"] = "Dragon Hybrid Boss",
			["HydraStatus"] = "Status",
			["AutoSummon"] = "Auto Summon",
			["AutoSummonDesc"] = "Summons Dragon Hybrid Boss. Sea 3 only.",
			["AutoKill"] = "Auto Kill",
			["AutoKillDesc"] = "Fights the boss as soon as it spawns.",
			["RaijinSection"] = "Raijin Boss",
			["RaijinStatus"] = "Status",
			["RaijinSummon"] = "Auto Summon Raijin",
			["RaijinSummonDesc"] = "Summons Raijin. Sea 3 only.",
			["RaijinKillDesc"] = "Fights Raijin as soon as it spawns.",
			["RaijinKill"] = "Auto Kill Raijin",
			["DoughSection"] = "Dough Boss",
			["DoughStatus"] = "Status",
			["DoughFragment"] = "Auto Farm Mirror Fragment",
			["DoughFragmentDesc"] = "Farms a Mirror Fragment. Sea 2 only.",
			["DoughUnlock"] = "Auto Unlock Mirror World",
			["DoughUnlockDesc"] = "Unlocks Mirror World for you.",
			["DoughSpawn"] = "Auto Spawn Dough Boss",
			["DoughSpawnDesc"] = "Pays the gems to call Dough Boss.",
			["DoughKill"] = "Auto Kill Dough Boss",
			["DoughKillDesc"] = "Fights Dough Boss as soon as it spawns.",
			["DragonSection"] = "Dragon Boss",
			["DragonStatus"] = "Status",
			["DragonSummon"] = "Auto Summon Dragon Boss",
			["DragonSummonDesc"] = "Summons Dragon Boss. Sea 2 only.",
			["DragonKill"] = "Auto Kill Dragon Boss",
			["DragonKillDesc"] = "Fights Dragon Boss as soon as it spawns.",
			["ZenithSection"] = "Zenith Boss",
			["ZenithStatus"] = "Status",
			["ZenithKill"] = "Auto Kill Zenith Boss",
			["ZenithKillDesc"] = "Waits at the Zenith Boss spot and fights it. Sea 2 only.",
			["SaturnSection"] = "Saturn Boss",
			["SaturnStatus"] = "Status",
			["SaturnKill"] = "Auto Kill Saturn Boss",
			["SaturnKillDesc"] = "Clears the Egg Island waves up to Saturn Boss whenever the event runs. Sea 3 only.",
			["EnmaSection"] = "Enma Boss",
			["EnmaStatus"] = "Status",
			["EnmaKill"] = "Auto Kill Enma Boss",
			["EnmaKillDesc"] = "Waits at the Enma Boss spot and fights it. Sea 2 only.",
			["VaultSection"] = "Vault Chest",
			["VaultStatus"] = "Status",
			["VaultKill"] = "Auto Kill Vault Chest",
			["VaultKillDesc"] = "Keeps finding for the Vault Chest raid and fights it wherever it spawns. Sea 2 only.",
			["RedEmperorSection"] = "Red Emperor Boss",
			["RedEmperorStatus"] = "Status",
			["RedEmperorKill"] = "Auto Kill Red Emperor Boss",
			["RedEmperorKillDesc"] = "Fights the boss as soon as it spawns. Sea 3 only.",
			["RedEmperorWait"] = "Wait At The Throne Room",
			["RedEmperorWaitDesc"] = "Goes to the spawn spot when the boss is due. Off, it never leaves your farm and only fights a boss that turns up nearby.",
			["RedEmperorBefore"] = "Go Wait With (seconds) Left",
			["RedEmperorBeforeDesc"] = "How little has to be left before it goes to wait.",
			["GhostSection"] = "Ghost Ship",
			["GhostStatus"] = "Status",
			["GhostKill"] = "Auto Kill Ghost Ship",
			["GhostKillDesc"] = "Kills the Ghost Ship as soon as it appears, whoever summoned it. Safe to leave on.",
			["GhostSummon"] = "Auto Summon Ghost Ship",
			["GhostSummonDesc"] = "Summons the ship yourself. Spends Devil Fruits to do it. Pick the fruits it may spend below first.",
			["GhostSource"] = "Take Fruits From",
			["GhostSourceDesc"] = "Pick one. Fruit Bag uses stored copies, In Backpack uses the fruit you are carrying, Buy Fruit buys what the Fruit Dealer has in stock right now.",
			["GhostFruits"] = "Fruits Allowed To Spend",
			["GhostFruitsDesc"] = "Only the fruits picked here get spent, everything else is left alone. Pick at least one or Auto Summon will not run. Buy Fruit ignores this list and goes by the rarities below instead.",
			["GhostRarity"] = "Rarities Allowed To Use",
			["GhostRarityDesc"] = "Extra filter on top of the fruit list above. Empty means every rarity of the fruits you picked. Buy Fruit goes by this alone - it buys the rarities picked here, for example Common and Uncommon, and needs at least one.",
			["CthulhuSection"] = "Cthulhu",
			["CthulhuStatus"] = "Status",
			["CthulhuKill"] = "Auto Kill Cthulhu",
			["CthulhuKillDesc"] = "Waits for the server call (Something ancient has awakened beneath the sea), then flies out to fight it, whoever summoned it. It never leaves your farm before that call. Two health bars, never despawns on its own. Sea 3 only. Safe to leave on.",
			["CthulhuSummon"] = "Auto Summon Cthulhu",
			["CthulhuSummonDesc"] = "Stays at your farm until the storm is up (every 2h 35m), then forges the shard and feeds it to the whirlpool under the Rainbow Sky Islands in Sea 3 in one run. Parks above the water line and anchors so it cannot drop in and drown. Crafts the shard first if the toggle below is on.",
			["CthulhuCraft"] = "Auto Craft Prismatic Shard",
			["CthulhuCraftDesc"] = "Flies to Doran the Forge and forges the shard when you have none. Costs 1x Phantom Lantern, Dragon Heart, Seabeast Heart, Raijin's Core and Saturn's Ring. Never crafts with materials missing.",
			["BeastSection"] = "Sea Beast",
			["BeastStatus"] = "Status",
			["BeastKill"] = "Auto Kill Sea Beast",
			["BeastKillDesc"] = "Fights a Sea Beast that turns up nearby. Never goes looking.",
			["BeastFind"] = "Auto Find Sea Beast",
			["BeastFindDesc"] = "Goes out looking for a Sea Beast on a timer. Nothing found and it hands the character back until the next round.",
			["BeastInterval"] = "Search Every (minutes)",
			["BeastIntervalDesc"] = "Minutes between searches. Restarts after a kill and after a search that found nothing.",
			["BeastDuration"] = "Search For (minutes)",
			["BeastDurationDesc"] = "How long one search may run. Time is up with nothing found and the character goes back to whatever was running.",
			["PrioritySection"] = "Boss Priority",
			["PriorityStatus"] = "Current Order",
			["PrioritySelect"] = "Select Boss",
			["PrioritySelectDesc"] = "Pick the boss to move, then use the buttons below. The live order is in Current Order above. Every boss can be on at once; when two are up the higher one gets the character.",
			["PriorityUp"] = "Move Up",
			["PriorityUpDesc"] = "Moves the selected boss up one place.",
			["PriorityDown"] = "Move Down",
			["PriorityDownDesc"] = "Moves the selected boss down one place.",
			["PriorityReset"] = "Reset Order",
			["PriorityResetDesc"] = "Puts the default order back.",
			["HopSection"] = "Hop Server",
			["HopEnable"] = "Auto Hop Server",
			["HopEnableDesc"] = "Hops to another server when none of the bosses you picked are up.",
			["HopBosses"] = "Hop For Which Bosses",
			["HopBossesDesc"] = "Bosses the hop waits for. Empty means every boss you have turned on.",
			["HopStatus"] = "Status",
			["HopWait"] = "Seconds Before Hopping",
			["HopWaitDesc"] = "How long nothing has to be up before hopping.",
			["SkillTab"] = "Skill",
			["SkillSection"] = "Auto Skill",
			["SkillMelee"] = "Melee Skill Keys",
			["SkillMeleeDesc"] = "Fighting style keys to press.",
			["SkillFruit"] = "Devil Fruit Skill Keys",
			["SkillFruitDesc"] = "Devil Fruit keys to press.",
			["SkillSword"] = "Sword Skill Keys",
			["SkillSwordDesc"] = "Sword keys to press.",
			["SkillHold"] = "Hold Duration",
			["SkillHoldDesc"] = "How long each key is held.",
			["SkillDelay"] = "Delay Between Casts",
			["SkillDelayDesc"] = "Delay between rounds of presses.",
			["SkillUseOn"] = "Use On",
			["SkillUseOnDesc"] = "Use skills on mobs, bosses, or both.",
			["SkillRange"] = "Target Range",
			["SkillRangeDesc"] = "Range to look for an enemy before casting.",
			["SkillToggle"] = "Auto Skill",
			["SkillToggleDesc"] = "Presses the skill keys whenever an enemy is in range.",
			["MiscTab"] = "Misc",
			["MiscSection"] = "Movement Tweaks",
			["DashNoCooldown"] = "Dash No Cooldown",
			["DashNoCooldownDesc"] = "Removes the dash cooldown.",
			["SkyJumpInf"] = "Infinite Sky Jump (Geppo)",
			["SkyJumpInfDesc"] = "Unlimited Geppo air jumps.",
			["InfiniteJump"] = "Infinite Jump",
			["InfiniteJumpDesc"] = "Jump again in mid-air as many times as you want.",
			["CodeSection"] = "Codes",
			["RedeemAllCodes"] = "Redeem All Codes",
			["RedeemAllCodesDesc"] = "Walks the whole code list one by one. Already used or expired codes are skipped.",
			["WebhookTab"] = "Webhook",
			["WebhookSetupSection"] = "Webhook Setup",
			["WebhookStatus"] = "Webhook Status",
			["WebhookUrl"] = "Webhook URL",
			["WebhookUrlDesc"] = "Paste the webhook URL of the Discord channel reports go to. It has to start with https://discord.com/api/webhooks/",
			["WebhookUserId"] = "Discord User ID",
			["WebhookUserIdDesc"] = "Your numeric Discord ID. Events picked in the ping list mention this ID. Leave empty for no mentions.",
			["WebhookHideName"] = "Hide Player Name",
			["WebhookHideNameDesc"] = "Masks the Roblox name in every report, keeping only the first and last letter.",
			["WebhookTest"] = "Send Test",
			["WebhookTestDesc"] = "Sends a test report to the URL above right now, so you can see whether the link works.",
			["WebhookEventSection"] = "Events To Report",
			["WebhookEvStart"] = "Script Started",
			["WebhookEvStartDesc"] = "Sends your character sheet every time the script loads.",
			["WebhookEvMerchant"] = "Wandering Merchant Purchase",
			["WebhookEvMerchantDesc"] = "Reports what was bought from the Wandering Merchant and what it cost.",
			["WebhookEvBoss"] = "Boss Killed",
			["WebhookEvBossDesc"] = "Reports the boss name, zone and fight length whenever a boss dies next to your character.",
			["WebhookEvFruit"] = "Devil Fruit Obtained",
			["WebhookEvFruitDesc"] = "Reports every devil fruit that lands in your fruit bag.",
			["WebhookEvSword"] = "Sword Obtained",
			["WebhookEvSwordDesc"] = "Reports every sword you did not own before.",
			["WebhookEvAccessory"] = "Accessory Obtained",
			["WebhookEvAccessoryDesc"] = "Reports every accessory you did not own before.",
			["WebhookEvLevel"] = "Level Up",
			["WebhookEvLevelDesc"] = "Only fires on the milestone set below, not on every single level.",
			["WebhookEvSea"] = "Sea Unlocked",
			["WebhookEvSeaDesc"] = "Reports unlocking Sea 2 or Sea 3.",
			["WebhookEvDeath"] = "Character Died",
			["WebhookEvDeathDesc"] = "Reports where your character died.",
			["WebhookEvHop"] = "Server Hop",
			["WebhookEvHopDesc"] = "Reports when the script hops servers or the game teleports you out.",
			["WebhookLevelStep"] = "Level Milestone",
			["WebhookLevelStepDesc"] = "Only levels divisible by this number are reported, so Discord is not spammed.",
			["WebhookPing"] = "Ping Me On",
			["WebhookPingDesc"] = "Picked events mention the ID above. The ID has to be filled in first.",
			["WebhookHeartSection"] = "Timed Report",
			["WebhookHeart"] = "Periodic Summary",
			["WebhookHeartDesc"] = "Sends a session summary on its own every few minutes.",
			["WebhookHeartMinutes"] = "Every X Minutes",
			["WebhookHeartMinutesDesc"] = "Gap between two summaries.",
			["WebhookViewSection"] = "Send Now",
			["WebhookViewPlayer"] = "View Character",
			["WebhookViewPlayerDesc"] = "Sends level, beli, gems, eaten fruit and held sword to Discord right now.",
			["WebhookViewFruit"] = "View Fruit Bag",
			["WebhookViewFruitDesc"] = "Sends every devil fruit in your bag to Discord right now.",
			["WebhookViewSword"] = "View Swords",
			["WebhookViewSwordDesc"] = "Sends the swords you own to Discord right now.",
			["WebhookViewBoss"] = "View Live Bosses",
			["WebhookViewBossDesc"] = "Sends the bosses alive in this server and how far away they are to Discord right now.",
			["WebhookViewRunner"] = "View Running Features",
			["WebhookViewRunnerDesc"] = "Sends which features are on and which one is driving the character to Discord right now.",
			["WebhookViewSession"] = "View Session",
			["WebhookViewSessionDesc"] = "Sends uptime, levels gained, beli gained and bosses killed to Discord right now.",
		},
	},
})

if getgenv().ConfigurationTable.Language == "English (US)" then
	WindUI:SetLanguage("English (US)")
else
	WindUI:SetLanguage("Thai")
end

local Window = WindUI:CreateWindow({
	Title = "Valkyrie Hub",
	Author = "by Phoenix",
	Size = Device,
	Transparent = getgenv().ConfigurationTable.Transparent,
	Theme = getgenv().ConfigurationTable.Themes,
	SideBarWidth = 200,
	HasOutline = true,
	ScrollBarEnabled = true,
	Resizable = false,
})

Window:EditOpenButton({
	Title = "Valkyrie Hub",
	CornerRadius = UDim.new(0, 16),
	StrokeThickness = 2,
	Color = ColorSequence.new(Color3.fromHex("FF0F7B"), Color3.fromHex("F89B29")),
	OnlyMobile = true,
	Enabled = true,
	Draggable = true,
})

Window:Divider()

ConfigWidgets = {}

function TrackWidget(Widget, Config)
	if type(Widget) == "table" and type(Config) == "table" and type(Config.Path) == "string" then
		table.insert(ConfigWidgets, {
			Widget = Widget,
			Path = Config.Path,
			Callback = Config.Callback,
		})
	end

	return Widget
end

function TrackContainer(Object)
	if type(Object) ~= "table" or rawget(Object, "ValkyrieTracked") then
		return Object
	end

	rawset(Object, "ValkyrieTracked", true)

	for _, Name in ipairs({ "Tab", "Section" }) do
		local Original = Object[Name]
		if type(Original) == "function" then
			Object[Name] = function(self, ...)
				return TrackContainer(Original(self, ...))
			end
		end
	end

	for _, Name in ipairs({ "Toggle", "Dropdown", "Slider", "Input", "Keybind" }) do
		local Original = Object[Name]
		if type(Original) == "function" then
			Object[Name] = function(self, Config, ...)
				return TrackWidget(Original(self, Config, ...), Config)
			end
		end
	end

	return Object
end

TrackContainer(Window)

TabGroups = {}

function MakeTabGroup(Key, Title, Icon, Opened)
	local Ok, Section = pcall(function()
		return Window:Section({ Title = Title, Icon = Icon, Opened = Opened == true })
	end)

	TabGroups[Key] = (Ok and type(Section) == "table" and Section.Tab) and Section or Window
end

function SetTabOrder(Tab, Order)
	pcall(function()
		Tab.UIElements.Main.LayoutOrder = Order
	end)
	return Tab
end

MakeTabGroup("Main", "tr:GroupMain", "house", true)
MakeTabGroup("Farm", "tr:GroupFarm", "swords", true)
MakeTabGroup("Item", "tr:GroupItem", "package", true)
MakeTabGroup("Travel", "tr:GroupTravel", "map", false)
MakeTabGroup("System", "tr:GroupSystem", "settings", false)

RT = {
	Text = "#EDEDED",
	Muted = "#8A8F98",
	Faint = "#3A3F45",
	Blue = "#0070F3",
	Cyan = "#79FFE1",
	Green = "#4ADE80",
	Red = "#FF4D4F",
	Amber = "#F5A623",
	Purple = "#B36BFF",
	Pink = "#FF4D9D",
}

RT.Escapes = { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;", ['"'] = "&quot;" }

function RT.Escape(Text)
	return (tostring(Text):gsub('[&<>"]', RT.Escapes))
end

function RT.Paint(Text, Color)
	return '<font color="' .. (Color or RT.Text) .. '">' .. RT.Escape(Text) .. "</font>"
end

function RT.Bold(Text, Color)
	return "<b>" .. RT.Paint(Text, Color) .. "</b>"
end

function RT.Field(Name, Value, Color)
	return RT.Paint(Name .. ": ", RT.Muted) .. RT.Bold(Value, Color)
end

function RT.Head(Text, Color)
	return RT.Bold("▎ " .. string.upper(Text), Color or RT.Blue)
end

function RT.Mark(Has)
	return Has and RT.Paint("✅", RT.Green) or RT.Paint("❌", RT.Red)
end

function RT.Item(Name, Has)
	return RT.Paint("• ", RT.Faint) .. RT.Paint(Name, Has and RT.Text or RT.Muted) .. " " .. RT.Mark(Has)
end

function RT.Progress(Owned, Total)
	return RT.Bold(Owned .. "/" .. Total, Owned >= Total and RT.Green or RT.Amber)
end

RT.Sep = RT.Paint("  │  ", RT.Faint)

function RT.Num(Value)
	local Text = tostring(math.floor(tonumber(Value) or 0))
	local Count
	repeat
		Text, Count = string.gsub(Text, "^(-?%d+)(%d%d%d)", "%1,%2")
	until Count == 0
	return Text
end

function RT.Grade(Ratio)
	if Ratio > 0.5 then
		return RT.Green
	elseif Ratio > 0.25 then
		return RT.Amber
	end
	return RT.Red
end

function RT.Studs(Distance)
	if not Distance then
		return RT.Bold("-", RT.Muted)
	end
	local Color = Distance <= 150 and RT.Green or (Distance <= 1000 and RT.Amber or RT.Red)
	return RT.Bold(RT.Num(Distance) .. " studs", Color)
end

function RT.Clock(Seconds)
	Seconds = math.max(math.floor(tonumber(Seconds) or 0), 0)
	if Seconds >= 3600 then
		return math.floor(Seconds / 3600) .. "h " .. math.floor(Seconds % 3600 / 60) .. "m " .. (Seconds % 60) .. "s"
	elseif Seconds >= 60 then
		return math.floor(Seconds / 60) .. "m " .. (Seconds % 60) .. "s"
	end
	return Seconds .. "s"
end

function RT.State(Text, Running)
	return RT.Paint("State: ", RT.Muted) .. RT.Bold(Text, Running and RT.Green or RT.Muted)
end

function RT.Flag(Name, On)
	return RT.Paint(Name .. " ", RT.Muted) .. RT.Mark(On and true or false)
end

RT.Said = {}

function RT.Debug(Tag, Message)
	local Line = tostring(Tag) .. ": " .. tostring(Message)
	if RT.Said[Line] then
		return
	end

	RT.Said[Line] = true
	warn("[Valkyrie Hub] " .. Line)
end

function RT.Frame(Paragraph)
	if type(Paragraph) ~= "table" then
		return Paragraph
	end

	return Paragraph.ParagraphFrame or Paragraph
end

RT.Labels = setmetatable({}, { __mode = "k" })
RT.Written = setmetatable({}, { __mode = "k" })

function RT.DescLabel(Paragraph)
	local Cached = RT.Labels[Paragraph]
	if Cached and Cached.Parent then
		return Cached
	end

	local Frame = RT.Frame(Paragraph)
	local Root = Frame and Frame.UIElements and Frame.UIElements.Container

	if typeof(Root) ~= "Instance" then
		return nil
	end

	local function Keep(Label)
		if Label and Label:IsA("TextLabel") then
			RT.Labels[Paragraph] = Label
			return Label
		end
		return nil
	end

	local Wrapper = Root:FindFirstChild("DescWrapper")
	local Found = Keep(Wrapper and Wrapper:FindFirstChild("Desc"))
	if Found then
		return Found
	end

	for _, Child in ipairs(Root:GetDescendants()) do
		if Child:IsA("TextLabel") and Child.Name == "Desc" then
			return Keep(Child)
		end
	end

	local Holder = Root:FindFirstChild("TitleFrame")
	Holder = (Holder and Holder:FindFirstChild("TitleFrame")) or Holder

	if Holder then
		for _, Child in ipairs(Holder:GetChildren()) do
			if Child:IsA("TextLabel") and Child.LayoutOrder ~= -1 and Child.TextTransparency > 0.3 then
				return Keep(Child)
			end
		end
	end

	return nil
end

function RT.Push(Tag, Paragraph, Build)
	if not Paragraph then
		RT.Debug(Tag, "paragraph was never created")
		return
	end

	local Ok, Result = pcall(Build)

	if not Ok then
		RT.Debug(Tag, "build failed - " .. tostring(Result))

		Result = RT.Bold("status error", RT.Red) .. "\n" .. RT.Paint(tostring(Result), RT.Muted)
	end

	if type(Result) ~= "string" or Result == "" then
		Result = RT.Bold("no status", RT.Muted)
	end

	if RT.Written[Paragraph] == Result then
		return
	end
	RT.Written[Paragraph] = Result

	local Frame = RT.Frame(Paragraph)
	local Sent = pcall(function()
		Frame:SetDesc(Result)
	end)

	local FoundLabel, Label = pcall(RT.DescLabel, Paragraph)
	local Written = false

	if FoundLabel and Label then
		Written = pcall(function()
			Label.RichText = true
			Label.Text = Result
			Label.Visible = true

			local Holder = Label.Parent
			if Holder and Holder:IsA("GuiObject") then
				Holder.Visible = true
			end
		end)
	end

	if not (Sent or Written) then
		RT.Debug(Tag, "no way to write the description on this WindUI build")
	end
end

function RT.Add(Lines, ...)
	for _, Line in ipairs({ ... }) do
		if type(Line) == "table" then
			for _, Inner in ipairs(Line) do
				Lines[#Lines + 1] = Inner
			end
		elseif Line then
			Lines[#Lines + 1] = Line
		end
	end
	return Lines
end

function RT.Target(Label, Target)
	local Lines = {}

	if Target and Target.Humanoid then
		local Humanoid = Target.Humanoid
		local Max = Humanoid.MaxHealth > 0 and Humanoid.MaxHealth or Humanoid.Health
		local Ratio = Max > 0 and (Humanoid.Health / Max) or 0

		Lines[#Lines + 1] = RT.Flag(Label, true)
			.. RT.Sep
			.. RT.Paint("HP: ", RT.Muted)
			.. RT.Bold(RT.Num(Humanoid.Health) .. " / " .. RT.Num(Max), RT.Grade(Ratio))
			.. RT.Paint(" (" .. math.floor(Ratio * 100 + 0.5) .. "%)", RT.Muted)
		Lines[#Lines + 1] = RT.Paint("Distance: ", RT.Muted) .. RT.Studs(Target.Distance)

		return Lines
	end

	Lines[#Lines + 1] = RT.Flag(Label, false) .. RT.Sep .. RT.Bold("not spawned", RT.Muted)

	return Lines
end

function RT.Enable(Paragraph)
	if not Paragraph then
		return
	end
	pcall(function()
		local Frame = Paragraph.ParagraphFrame or Paragraph
		local Root = Frame.UIElements and Frame.UIElements.Container or Frame.Frame or Frame
		if typeof(Root) ~= "Instance" then
			return
		end
		for _, Child in ipairs(Root:GetDescendants()) do
			if Child:IsA("TextLabel") then
				Child.RichText = true
			end
		end
	end)
end

function RT.Status(Section, Title)
	local Paragraph = nil

	local Ok = pcall(function()
		Paragraph = Section:Paragraph({ Title = Title, Desc = "-" })
	end)

	if not (Ok and Paragraph) then
		pcall(function()
			Paragraph = Section:Paragraph({ Title = Title })
		end)
	end

	if Paragraph then
		RT.Enable(Paragraph)
	else
		RT.Debug(tostring(Title), "paragraph could not be created")
	end

	return Paragraph
end

Webhook = {
	Queue = {},
	Sending = false,
	Sent = 0,
	Failed = 0,
	LastError = "",
	LastSentAt = 0,
	Watching = false,
}

local WH = Webhook

WH.ESC = string.char(27)

WH.Color = {
	Info = 0x3B82F6,
	Good = 0x22C55E,
	Loot = 0xA855F7,
	Boss = 0xEF4444,
	Money = 0xF59E0B,
	Quiet = 0x64748B,
}

WH.Ink = {
	Grey = 30,
	Red = 31,
	Green = 32,
	Amber = 33,
	Blue = 34,
	Pink = 35,
	Cyan = 36,
	White = 37,
}

WH.Session = {
	Start = os.clock(),
	Level = nil,
	Beli = nil,
	Bosses = 0,
	BossList = {},
	Fruits = 0,
	Swords = 0,
	Merchant = 0,
	Spent = 0,
	Deaths = 0,
}

function WH.Config()
	local Store = getgenv().Settings
	local Config = type(Store) == "table" and Store.Webhook or nil
	return type(Config) == "table" and Config or nil
end

function WH.Trim(Text)
	return tostring(Text or ""):match("^%s*(.-)%s*$")
end

function WH.ValidUrl(Url)
	Url = WH.Trim(Url)
	return Url:match("^https://[%w%.%-]+/api/webhooks/%d+/[%w%-%._]+$") ~= nil
end

function WH.Url()
	local Config = WH.Config()
	local Url = Config and WH.Trim(Config.Url) or ""
	return WH.ValidUrl(Url) and Url or nil
end

function WH.On(Event)
	local Config = WH.Config()
	local Events = Config and Config.Events
	return type(Events) == "table" and Events[Event] == true
end

function WH.PingFor(Event)
	local Config = WH.Config()
	if not Config then
		return nil
	end

	local Id = WH.Trim(Config.UserId):match("^%d+$")
	if not Id then
		return nil
	end

	for _, Name in ipairs(NormalizeList(Config.PingOn)) do
		if Name == Event then
			return Id
		end
	end

	return nil
end

function WH.Sender()
	return (syn and syn.request) or (http and http.request) or http_request or request
end

function WH.Num(Value)
	local Number = tonumber(Value)
	if not Number then
		return tostring(Value)
	end

	local Text = tostring(math.floor(Number))
	local Done
	repeat
		Text, Done = Text:gsub("^(%-?%d+)(%d%d%d)", "%1,%2")
	until Done == 0

	return Text
end

function WH.Clock(Seconds)
	Seconds = math.max(0, math.floor(tonumber(Seconds) or 0))

	return string.format("%02d:%02d:%02d", math.floor(Seconds / 3600), math.floor((Seconds % 3600) / 60), Seconds % 60)
end

function WH.Mask(Name)
	Name = tostring(Name or "")
	if #Name <= 2 then
		return string.rep("*", #Name)
	end
	return Name:sub(1, 1) .. string.rep("*", #Name - 2) .. Name:sub(-1)
end

function WH.Who()
	local Config = WH.Config()
	if Config and Config.HideName then
		return WH.Mask(LocalPlayer.Name)
	end
	return LocalPlayer.Name
end

WH.Text = {
	Lv = { "เลเวล", "Lv" },
	Up = { "เล่นมา", "up" },
	None = { "ไม่มี", "None" },
	Nobody = { "ไม่มี", "nobody" },
	Unknown = { "ไม่ทราบ", "unknown" },
	Unlocked = { "ปลดล็อกแล้ว", "unlocked" },
	Locked = { "ยังไม่ปลดล็อก", "locked" },
	NothingShow = { "> _ไม่มีข้อมูล_", "> _nothing to show_" },
	AndMore = { "-# และอีก %d รายการ", "-# and %d more" },
	Studs = { "%d studs", "%d studs" },

	RowPlayer = { "ผู้เล่น", "Player" },
	RowLevel = { "เลเวล", "Level" },
	RowBeli = { "เงิน", "Beli" },
	RowGems = { "เจม", "Gems" },
	RowWallet = { "เงินคงเหลือ", "Wallet" },
	RowUptime = { "เวลาเล่น", "Uptime" },
	RowServer = { "เซิร์ฟเวอร์", "Server" },
	RowNew = { "ที่ได้", "New" },

	MerchantTitle = { "พ่อค้าเร่", "Wandering Merchant" },
	MerchantNote = {
		"ซื้อของจากพ่อค้าเร่ได้แล้ว",
		"Bought from the merchant before the visit ran out.",
	},
	RowBought = { "ซื้อได้", "Bought" },
	RowSpent = { "จ่ายไป", "Spent" },
	ItemCount = { "%d ชิ้น", "%d item(s)" },

	BossTitle = { "ฆ่าบอสได้", "Boss Defeated" },
	BossNote = { "%s ตายแล้ว", "%s went down." },
	RowBoss = { "บอส", "Boss" },
	RowZone = { "โซน", "Zone" },
	RowFight = { "ใช้เวลา", "Fight" },
	RowKilled = { "ฆ่าไปแล้ว", "Killed" },
	KilledRun = { "%d ตัวรอบนี้", "%d this run" },

	KindFruit = { "ผลปีศาจ", "Devil Fruit" },
	KindSword = { "ดาบ", "Sword" },
	KindAccessory = { "เครื่องประดับ", "Accessory" },
	GotTitle = { "ได้%sใหม่", "%s Obtained" },
	GotOne = { "ได้ %s มาแล้ว", "Picked up %s." },
	GotMany = { "ได้%sใหม่ %d ชิ้น", "Picked up %s x%d." },

	SessionTitle = { "สรุปรอบนี้", "Session Summary" },
	SessionNote = {
		"สถานะรอบการเล่นตอนนี้",
		"Where this run stands right now.",
	},
	RowBosses = { "บอส", "Bosses" },
	RowFruits = { "ผลปีศาจ", "Fruits" },
	RowSwords = { "ดาบ", "Swords" },
	RowMerchant = { "พ่อค้าเร่", "Merchant" },
	RowDeaths = { "ตาย", "Deaths" },
	RowReports = { "ส่งไปแล้ว", "Reports" },
	ReportCount = { "สำเร็จ %d / พลาด %d", "%d sent / %d failed" },
	BossKillHead = { "**บอสที่ฆ่าไป**", "**Bosses killed**" },

	PlayerTitle = { "ข้อมูลตัวละคร", "Character" },
	PlayerNote = {
		"ข้อมูลตัวละครทั้งหมดตอนนี้",
		"Everything the game reports about this character right now.",
	},
	RowRace = { "เผ่า", "Race" },
	RowTitleName = { "ฉายา", "Title" },
	RowFruit = { "ผลที่กิน", "Fruit" },
	RowStyle = { "ท่าต่อสู้", "Style" },
	RowSword = { "ดาบที่ถือ", "Sword" },

	BagTitle = { "ผลปีศาจในกระเป๋า", "Fruit Bag" },
	BagNote = { "เก็บผลปีศาจไว้ %d ชนิด", "%d kind(s) of devil fruit stored." },
	BagEmpty = {
		"> _กระเป๋าผลปีศาจว่างเปล่า_",
		"> _the fruit bag is empty_",
	},

	SwordTitle = { "ดาบที่มี", "Swords Owned" },
	SwordNote = {
		"ปลดล็อกดาบไปแล้ว %d เล่ม",
		"%d sword(s) unlocked on this account.",
	},

	BossListTitle = { "บอสที่เกิดอยู่", "Live Bosses" },
	BossListNote = {
		"มีบอสในเซิร์ฟเวอร์นี้ %d ตัว",
		"%d boss(es) alive in this server.",
	},
	BossListNone = {
		"> _ตอนนี้ไม่มีบอสเกิดอยู่_",
		"> _no boss is up right now_",
	},
	BossScanWait = {
		"ตัวสแกนบอสยังโหลดไม่เสร็จ เปิดแท็บ บอส สักครั้งแล้วลองใหม่",
		"The boss scanner has not finished loading yet. Open the Boss tab once, then try again.",
	},

	RunTitle = { "ระบบที่กำลังทำงาน", "Running Features" },
	RunNote = {
		"ตอนนี้สคริปต์กำลังทำอะไรกับตัวละครอยู่",
		"What the hub is doing with the character at this moment.",
	},
	RowDriving = { "ตัวที่คุมอยู่", "Driving" },
	RowWorking = { "กำลังทำงาน", "Working" },
	RowWaiting = { "กำลังรอ", "Waiting" },
	WorkHead = { "**กำลังทำงาน**", "**Working**" },
	WaitHead = { "**กำลังรอ**", "**Waiting**" },
	RunNone = {
		"> _ยังไม่ได้เปิดระบบไหนเลย_",
		"> _nothing is switched on_",
	},

	TestTitle = { "ทดสอบ Webhook", "Webhook Test" },
	TestNote = {
		"ถ้าเห็นข้อความนี้แปลว่าลิงก์ใช้ได้ รายงานอื่น ๆ จะส่งมาหน้าตาแบบนี้",
		"If you can read this, the URL works and every report below will arrive the same way.",
	},
	SampleHead = { "**ตัวอย่างรายการ**", "**Sample list**" },

	LevelTitle = { "ถึงเลเวลที่ตั้งไว้", "Level Milestone" },
	LevelNote = { "ถึงเลเวล %s แล้ว", "Reached level %s." },
	RowGained = { "ขึ้นมา", "Gained" },
	GainedRun = { "+%s รอบนี้", "+%s this run" },

	SeaTitle = { "ปลดล็อกทะเลใหม่", "Sea Unlocked" },
	SeaNote = { "เปิด %s แล้ว", "%s is open." },
	RowSea = { "ทะเล", "Sea" },
	Sea2Name = { "ทะเลที่สอง", "Second Sea" },
	Sea3Name = { "ทะเลที่สาม", "Third Sea" },

	DeathTitle = { "ตัวละครตาย", "Character Died" },
	DeathNote = {
		"ตัวละครตายแล้ว กำลังเกิดใหม่",
		"The character went down and is respawning.",
	},
	DeathsRun = { "%d ครั้งรอบนี้", "%d this run" },
	RowSpot = { "จุดที่ตาย", "Spot" },

	HopTitle = { "กำลังออกจากเซิร์ฟเวอร์", "Leaving Server" },
	HopNote = {
		"ตัวละครกำลังถูกย้ายไปเซิร์ฟเวอร์อื่น",
		"The character is being moved to another server.",
	},
	RowReason = { "สาเหตุ", "Reason" },
	HopDriven = { "ระบบ %s สั่งย้าย", "driven by %s" },
	HopOther = { "ย้ายเซิร์ฟหรือถูกเตะออก", "hop or kick" },
	BossCount = { "ฆ่าไป %s ตัว", "%s killed" },

	StartTitle = { "เปิดสคริปต์แล้ว", "Script Loaded" },
	StartNote = {
		"Valkyrie Hub กำลังทำงานอยู่ในบัญชีนี้",
		"Valkyrie Hub is running on this account.",
	},
}

function WH.Thai()
	local Config = getgenv().ConfigurationTable
	return type(Config) == "table" and Config.Language == "Thai"
end

function WH.T(Key, ...)
	local Entry = WH.Text[Key]

	if not Entry then
		return tostring(Key)
	end

	local Line = WH.Thai() and Entry[1] or Entry[2]

	if select("#", ...) == 0 then
		return Line
	end

	local Ok, Result = pcall(string.format, Line, ...)
	return Ok and Result or Line
end

WH.Stacked = {
	[0x0E31] = true,
	[0x0E47] = true,
	[0x0E48] = true,
	[0x0E49] = true,
	[0x0E4A] = true,
	[0x0E4B] = true,
	[0x0E4C] = true,
	[0x0E4D] = true,
	[0x0E4E] = true,
}

function WH.Width(Text)
	Text = tostring(Text)

	local Ok, Count = pcall(function()
		local Total = 0

		for _, Code in utf8.codes(Text) do
			if not (WH.Stacked[Code] or (Code >= 0x0E34 and Code <= 0x0E3A)) then
				Total = Total + 1
			end
		end

		return Total
	end)

	return Ok and Count or #Text
end

function WH.Data()
	return LocalPlayer:FindFirstChild("PlayerData")
end

function WH.Read(Parent, Name, Default)
	local Object = Parent and Parent:FindFirstChild(Name)
	if Object and Object:IsA("ValueBase") then
		return Object.Value
	end
	return Default
end

function WH.Level()
	local Data = WH.Data()
	return tonumber(WH.Read(Data and Data:FindFirstChild("Experience"), "Level", 0)) or 0
end

function WH.Beli()
	return tonumber(WH.Read(WH.Data(), "Currency", 0)) or 0
end

function WH.Gems()
	return tonumber(WH.Read(WH.Data(), "Gems", 0)) or 0
end

function WH.FruitBag()
	local Counts, Order = {}, {}
	local Raw = WH.Read(WH.Data(), "CollectedFruits", "")

	if type(Raw) ~= "string" then
		return Counts, Order
	end

	for Name in Raw:gmatch("[^,]+") do
		Name = WH.Trim(Name)
		if Name ~= "" then
			if not Counts[Name] then
				table.insert(Order, Name)
			end
			Counts[Name] = (Counts[Name] or 0) + 1
		end
	end

	table.sort(Order)
	return Counts, Order
end

function WH.SwordSet()
	local Set = {}
	local Data = WH.Data()
	local Raw = WH.Read(Data and Data:FindFirstChild("Sword"), "OwnedSwords", "")

	if type(Raw) ~= "string" or Raw == "" then
		return Set
	end

	local Ok, Decoded = pcall(function()
		return HttpService:JSONDecode(Raw)
	end)

	if Ok and type(Decoded) == "table" then
		for Key, Item in pairs(Decoded) do
			if type(Item) == "string" then
				Set[Item] = true
			elseif Item == true and type(Key) == "string" then
				Set[Key] = true
			end
		end
		return Set
	end

	for Name in Raw:gmatch("[^,]+") do
		Name = WH.Trim(Name):gsub('^"', ""):gsub('"$', "")
		if Name ~= "" then
			Set[Name] = true
		end
	end

	return Set
end

function WH.AccessorySet()
	local Set = {}
	local Data = WH.Data()
	local Store = Data and (Data:FindFirstChild("Accessory") or Data:FindFirstChild("Accessories"))

	for _, Root in ipairs({ Store, Data }) do
		if Root then
			for _, Key in ipairs({ "OwnedAccessories", "OwnedAccessory", "Accessories" }) do
				local Raw = WH.Read(Root, Key, nil)
				if type(Raw) == "string" and Raw ~= "" then
					local Ok, Decoded = pcall(function()
						return HttpService:JSONDecode(Raw)
					end)

					if Ok and type(Decoded) == "table" then
						for ItemKey, Item in pairs(Decoded) do
							if type(Item) == "string" then
								Set[Item] = true
							elseif Item == true and type(ItemKey) == "string" then
								Set[ItemKey] = true
							end
						end
					else
						for Name in Raw:gmatch("[^,]+") do
							Name = WH.Trim(Name)
							if Name ~= "" then
								Set[Name] = true
							end
						end
					end
				end
			end
		end
	end

	if Store then
		for _, Object in ipairs(Store:GetChildren()) do
			if Object:IsA("BoolValue") and Object.Value then
				Set[Object.Name] = true
			elseif Object:IsA("Folder") then
				Set[Object.Name] = true
			end
		end
	end

	return Set
end

function WH.Keys(Set)
	local List = {}
	for Name in pairs(Set) do
		table.insert(List, Name)
	end
	table.sort(List)
	return List
end

function WH.Paint(Text, Ink, Bold)
	return WH.ESC
		.. "["
		.. (Bold and 1 or 0)
		.. ";"
		.. (Ink or WH.Ink.White)
		.. "m"
		.. tostring(Text)
		.. WH.ESC
		.. "[0m"
end

function WH.Panel(Rows)
	local Width = 0
	for _, Row in ipairs(Rows) do
		Width = math.max(Width, WH.Width(Row[1]))
	end

	local Lines = {}
	for _, Row in ipairs(Rows) do
		local Label = tostring(Row[1])
		Label = Label .. string.rep(" ", Width - WH.Width(Label))
		table.insert(
			Lines,
			WH.Paint(Label, WH.Ink.Grey, true) .. "  " .. WH.Paint(Row[2], Row[3] or WH.Ink.White, true)
		)
	end

	return "```ansi\n" .. table.concat(Lines, "\n") .. "\n```"
end

function WH.Table(Rows)
	local Width = 0
	for _, Row in ipairs(Rows) do
		Width = math.max(Width, WH.Width(Row[1]))
	end

	local Lines = {}
	for _, Row in ipairs(Rows) do
		local Label = tostring(Row[1])
		table.insert(Lines, Label .. string.rep(" ", Width - WH.Width(Label)) .. "   " .. tostring(Row[2]))
	end

	return "```\n" .. table.concat(Lines, "\n") .. "\n```"
end

function WH.Bullets(Items, Limit)
	Limit = Limit or 20

	local Lines = {}
	for Index, Item in ipairs(Items) do
		if Index > Limit then
			table.insert(Lines, WH.T("AndMore", #Items - Limit))
			break
		end
		table.insert(Lines, "- " .. tostring(Item))
	end

	if #Lines == 0 then
		return WH.T("NothingShow")
	end

	return table.concat(Lines, "\n")
end

function WH.Quote(Text)
	local Lines = {}
	for Line in (tostring(Text) .. "\n"):gmatch("(.-)\n") do
		table.insert(Lines, "> " .. Line)
	end
	return table.concat(Lines, "\n")
end

function WH.Rule()
	return "-# " .. string.rep("\u{2500}", 24)
end

function WH.Uptime()
	return WH.Clock(os.clock() - WH.Session.Start)
end

function WH.Post(Url, Body)
	local Send = WH.Sender()
	if not Send then
		return false, "executor has no HTTP request function"
	end

	local Encoded
	local Packed = pcall(function()
		Encoded = HttpService:JSONEncode(Body)
	end)

	if not Packed then
		return false, "could not encode the payload"
	end

	local Ok, Response = pcall(Send, {
		Url = Url,
		Method = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body = Encoded,
	})

	if not Ok then
		return false, tostring(Response)
	end

	local Code = tonumber(Response and (Response.StatusCode or Response.Status)) or 0

	if Code == 429 then
		local Wait = 3
		pcall(function()
			local Data = HttpService:JSONDecode(Response.Body)
			local After = tonumber(Data.retry_after)
			if After then
				Wait = After > 100 and (After / 1000) or After
			end
		end)
		return false, "rate limited by Discord", math.clamp(Wait, 1, 60)
	end

	if Code < 200 or Code > 299 then
		return false, "Discord answered HTTP " .. Code
	end

	return true
end

function WH.Pump()
	if WH.Sending then
		return
	end

	WH.Sending = true

	task.spawn(function()
		while #WH.Queue > 0 do
			local Job = table.remove(WH.Queue, 1)
			local Ok, Reason, Retry = WH.Post(Job.Url, Job.Body)

			if not Ok and Retry then
				task.wait(Retry)
				Ok, Reason = WH.Post(Job.Url, Job.Body)
			end

			if Ok then
				WH.Sent = WH.Sent + 1
				WH.LastSentAt = os.time()
			else
				WH.Failed = WH.Failed + 1
				WH.LastError = tostring(Reason)
			end

			if Job.Done then
				pcall(Job.Done, Ok, Reason)
			end

			task.wait(1.2)
		end

		WH.Sending = false
	end)
end

function WH.Push(Body, Url, Done)
	Url = Url or WH.Url()
	if not Url then
		if Done then
			pcall(Done, false, "no webhook URL set")
		end
		return false
	end

	if #WH.Queue > 40 then
		table.remove(WH.Queue, 1)
	end

	table.insert(WH.Queue, { Url = Url, Body = Body, Done = Done })
	WH.Pump()
	return true
end

function WH.Report(Options)
	local Url = Options.Url or WH.Url()
	if not Url then
		return false, "no webhook URL set"
	end

	if Options.Event and not Options.Force and not WH.On(Options.Event) then
		return false, "event is switched off"
	end

	local Parts = {}

	if Options.Note then
		table.insert(Parts, WH.Quote(Options.Note))
	end

	if Options.Rows and #Options.Rows > 0 then
		table.insert(Parts, WH.Panel(Options.Rows))
	end

	if Options.Body then
		table.insert(Parts, Options.Body)
	end

	local Embed = {
		author = { name = "Valkyrie Hub  -  Haze Seas" },
		title = Options.Title,
		description = table.concat(Parts, "\n"),
		color = Options.Color or WH.Color.Info,
		footer = {
			text = WH.Who()
				.. "  -  "
				.. WH.T("Lv")
				.. " "
				.. WH.Num(WH.Level())
				.. "  -  "
				.. WH.T("Up")
				.. " "
				.. WH.Uptime(),
		},
		timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
	}

	local Payload = {
		username = "Valkyrie Hub",
		embeds = { Embed },
	}

	local Ping = Options.Event and WH.PingFor(Options.Event) or nil
	if Ping then
		Payload.content = "<@" .. Ping .. ">"
		Payload.allowed_mentions = { parse = {}, users = { Ping } }
	else
		Payload.allowed_mentions = { parse = {} }
	end

	WH.Push(Payload, Url, Options.Done)
	return true
end

function WH.Merchant(Items, Spent)
	WH.Session.Merchant = WH.Session.Merchant + #Items
	WH.Session.Spent = WH.Session.Spent + (Spent or 0)

	local Rows = {
		{ WH.T("RowBought"), WH.T("ItemCount", #Items), WH.Ink.Green },
		{ WH.T("RowSpent"), "$" .. WH.Num(Spent or 0), WH.Ink.Amber },
		{ WH.T("RowWallet"), "$" .. WH.Num(WH.Beli()), WH.Ink.Amber },
	}

	WH.Report({
		Event = "Merchant",
		Title = WH.T("MerchantTitle"),
		Note = WH.T("MerchantNote"),
		Rows = Rows,
		Body = WH.Bullets(Items),
		Color = WH.Color.Money,
	})
end

function WH.BossKilled(Name, Zone, Seconds)
	WH.Session.Bosses = WH.Session.Bosses + 1
	WH.Session.BossList[Name] = (WH.Session.BossList[Name] or 0) + 1

	WH.Report({
		Event = "BossKill",
		Title = WH.T("BossTitle"),
		Note = WH.T("BossNote", Name),
		Rows = {
			{ WH.T("RowBoss"), Name, WH.Ink.Red },
			{ WH.T("RowZone"), Zone or "?", WH.Ink.Cyan },
			{ WH.T("RowFight"), WH.Clock(Seconds or 0), WH.Ink.White },
			{ WH.T("RowKilled"), WH.T("KilledRun", WH.Session.BossList[Name]), WH.Ink.Grey },
		},
		Color = WH.Color.Boss,
	})
end

function WH.Obtained(KindKey, Names, Event, Color)
	local Kind = WH.T(KindKey)

	WH.Report({
		Event = Event,
		Title = WH.T("GotTitle", Kind),
		Note = #Names == 1 and WH.T("GotOne", Names[1]) or WH.T("GotMany", Kind, #Names),
		Rows = {
			{ WH.T("RowNew"), table.concat(Names, ", "), WH.Ink.Pink },
			{ WH.T("RowLevel"), WH.Num(WH.Level()), WH.Ink.Blue },
			{ WH.T("RowWallet"), "$" .. WH.Num(WH.Beli()), WH.Ink.Amber },
		},
		Color = Color or WH.Color.Loot,
	})
end

function WH.SessionRows()
	local Session = WH.Session
	local Rows = {
		{ WH.T("RowUptime"), WH.Uptime(), WH.Ink.Cyan },
		{
			WH.T("RowLevel"),
			WH.Num(WH.Level()) .. (Session.Level and ("  (+" .. WH.Num(WH.Level() - Session.Level) .. ")") or ""),
			WH.Ink.Blue,
		},
		{
			WH.T("RowBeli"),
			"$"
				.. WH.Num(WH.Beli())
				.. (
					Session.Beli
						and ("  (" .. (WH.Beli() >= Session.Beli and "+" or "") .. WH.Num(WH.Beli() - Session.Beli) .. ")")
					or ""
				),
			WH.Ink.Amber,
		},
		{ WH.T("RowBosses"), WH.Num(Session.Bosses), WH.Ink.Red },
		{ WH.T("RowFruits"), WH.Num(Session.Fruits), WH.Ink.Pink },
		{ WH.T("RowSwords"), WH.Num(Session.Swords), WH.Ink.White },
		{ WH.T("RowMerchant"), WH.T("ItemCount", Session.Merchant), WH.Ink.Green },
		{ WH.T("RowDeaths"), WH.Num(Session.Deaths), WH.Ink.Grey },
		{ WH.T("RowReports"), WH.T("ReportCount", WH.Sent, WH.Failed), WH.Ink.Grey },
	}
	return Rows
end

function WH.SendSession(Force)
	local Kills = {}
	for Name, Count in pairs(WH.Session.BossList) do
		table.insert(Kills, Name .. "  x" .. Count)
	end
	table.sort(Kills)

	return WH.Report({
		Event = "Heartbeat",
		Force = Force ~= false,
		Title = WH.T("SessionTitle"),
		Note = WH.T("SessionNote"),
		Rows = WH.SessionRows(),
		Body = #Kills > 0 and (WH.T("BossKillHead") .. "\n" .. WH.Bullets(Kills, 15)) or nil,
		Color = WH.Color.Quiet,
	})
end

function WH.SendPlayer()
	local Data = WH.Data()
	local Fruit = tostring(WH.Read(Data, "CurrentSuperPower", "") or "")
	local Sword = tostring(WH.Read(Data, "CurrentSword", "") or "")

	local Sea2 = WH.Read(Data, "Sea2Unlocked", false) == true
	local Sea3 = WH.Read(Data, "Sea3Unlocked", false) == true

	return WH.Report({
		Force = true,
		Title = WH.T("PlayerTitle"),
		Note = WH.T("PlayerNote"),
		Rows = {
			{ WH.T("RowPlayer"), WH.Who(), WH.Ink.Cyan },
			{ WH.T("RowLevel"), WH.Num(WH.Level()), WH.Ink.Blue },
			{ WH.T("RowBeli"), "$" .. WH.Num(WH.Beli()), WH.Ink.Amber },
			{ WH.T("RowGems"), WH.Num(WH.Gems()), WH.Ink.Pink },
			{ WH.T("RowRace"), tostring(WH.Read(Data, "Race", WH.T("None"))), WH.Ink.White },
			{ WH.T("RowTitleName"), tostring(WH.Read(Data, "Title", WH.T("None"))), WH.Ink.White },
			{ WH.T("RowFruit"), Fruit ~= "" and Fruit or WH.T("None"), WH.Ink.Pink },
			{ WH.T("RowStyle"), tostring(WH.Read(Data, "FightingStyle", "Combat")), WH.Ink.White },
			{ WH.T("RowSword"), Sword ~= "" and Sword or WH.T("None"), WH.Ink.White },
			{
				"Sea 2",
				Sea2 and WH.T("Unlocked") or WH.T("Locked"),
				Sea2 and WH.Ink.Green or WH.Ink.Grey,
			},
			{
				"Sea 3",
				Sea3 and WH.T("Unlocked") or WH.T("Locked"),
				Sea3 and WH.Ink.Green or WH.Ink.Grey,
			},
		},
		Color = WH.Color.Info,
	})
end

function WH.SendFruitBag()
	local Counts, Order = WH.FruitBag()
	local Rows = {}

	for _, Name in ipairs(Order) do
		table.insert(Rows, { Name, "x" .. Counts[Name] })
	end

	return WH.Report({
		Force = true,
		Title = WH.T("BagTitle"),
		Note = WH.T("BagNote", #Order),
		Body = #Rows > 0 and WH.Table(Rows) or WH.T("BagEmpty"),
		Color = WH.Color.Loot,
	})
end

function WH.SendSwords()
	local Owned = WH.Keys(WH.SwordSet())

	return WH.Report({
		Force = true,
		Title = WH.T("SwordTitle"),
		Note = WH.T("SwordNote", #Owned),
		Body = WH.Bullets(Owned, 30),
		Color = WH.Color.Info,
	})
end

function WH.LiveBosses()
	if type(ValkyrieScanBosses) ~= "function" then
		return nil
	end

	local Ok, Found = pcall(ValkyrieScanBosses)
	return (Ok and type(Found) == "table") and Found or nil
end

function WH.SendBosses()
	local Found = WH.LiveBosses()

	if not Found then
		return WH.Report({
			Force = true,
			Title = WH.T("BossListTitle"),
			Note = WH.T("BossScanWait"),
			Color = WH.Color.Quiet,
		})
	end

	local Rows = {}
	for _, Entry in ipairs(Found) do
		table.insert(Rows, { Entry.Name, Entry.Zone .. "   " .. WH.T("Studs", math.floor(Entry.Distance)) })
	end

	return WH.Report({
		Force = true,
		Title = WH.T("BossListTitle"),
		Note = WH.T("BossListNote", #Rows),
		Body = #Rows > 0 and WH.Table(Rows) or WH.T("BossListNone"),
		Color = WH.Color.Boss,
	})
end

function WH.SendRunners()
	local Active, Idle = {}, {}

	if type(VenuzRun) == "table" then
		for Name in pairs(VenuzRun.Active or {}) do
			if VenuzRun.Idle and VenuzRun.Idle[Name] then
				table.insert(Idle, Name)
			else
				table.insert(Active, Name)
			end
		end
	end

	table.sort(Active)
	table.sort(Idle)

	local Body = {}
	if #Active > 0 then
		table.insert(Body, WH.T("WorkHead") .. "\n" .. WH.Bullets(Active, 20))
	end
	if #Idle > 0 then
		table.insert(Body, WH.T("WaitHead") .. "\n" .. WH.Bullets(Idle, 20))
	end
	if #Body == 0 then
		table.insert(Body, WH.T("RunNone"))
	end

	return WH.Report({
		Force = true,
		Title = WH.T("RunTitle"),
		Note = WH.T("RunNote"),
		Rows = {
			{
				WH.T("RowDriving"),
				tostring((type(VenuzRun) == "table" and VenuzRun.Owner) or WH.T("Nobody")),
				WH.Ink.Cyan,
			},
			{ WH.T("RowWorking"), WH.Num(#Active), WH.Ink.Green },
			{ WH.T("RowWaiting"), WH.Num(#Idle), WH.Ink.Grey },
		},
		Body = table.concat(Body, "\n"),
		Color = WH.Color.Info,
	})
end

function WH.SendTest(Url)
	return WH.Report({
		Force = true,
		Url = Url,
		Title = WH.T("TestTitle"),
		Note = WH.T("TestNote"),
		Rows = {
			{ WH.T("RowPlayer"), WH.Who(), WH.Ink.Cyan },
			{ WH.T("RowLevel"), WH.Num(WH.Level()), WH.Ink.Blue },
			{ WH.T("RowBeli"), "$" .. WH.Num(WH.Beli()), WH.Ink.Amber },
			{ WH.T("RowServer"), tostring(game.JobId ~= "" and game.JobId or "studio"), WH.Ink.Grey },
		},
		Body = WH.T("SampleHead") .. "\n" .. WH.Bullets({
			WH.T("BossTitle"),
			WH.T("MerchantTitle"),
			WH.T("GotTitle", WH.T("KindFruit")),
		}) .. "\n" .. WH.Rule(),
		Color = WH.Color.Good,
	})
end

function WH.StartWatchers()
	if WH.Watching then
		return
	end
	WH.Watching = true

	local Session = WH.Session
	Session.Level = WH.Level()
	Session.Beli = WH.Beli()

	local Data = WH.Data()

	task.spawn(function()
		local Experience = Data and Data:FindFirstChild("Experience")
		local Value = Experience and Experience:FindFirstChild("Level")
		if not Value then
			return
		end

		local Last = tonumber(Value.Value) or 0

		Value.Changed:Connect(function(New)
			New = tonumber(New) or 0
			if New <= Last then
				Last = New
				return
			end

			local Config = WH.Config()
			local Step = math.max(1, math.floor(tonumber(Config and Config.LevelStep) or 25))

			local Crossed = math.floor(New / Step) > math.floor(Last / Step)
			Last = New

			if Crossed then
				WH.Report({
					Event = "LevelUp",
					Title = WH.T("LevelTitle"),
					Note = WH.T("LevelNote", WH.Num(New)),
					Rows = {
						{ WH.T("RowLevel"), WH.Num(New), WH.Ink.Blue },
						{ WH.T("RowGained"), WH.T("GainedRun", WH.Num(New - (Session.Level or New))), WH.Ink.Green },
						{ WH.T("RowBeli"), "$" .. WH.Num(WH.Beli()), WH.Ink.Amber },
						{ WH.T("RowUptime"), WH.Uptime(), WH.Ink.Grey },
					},
					Color = WH.Color.Info,
				})
			end
		end)
	end)

	task.spawn(function()
		local Value = Data and Data:FindFirstChild("CollectedFruits")
		if not Value then
			return
		end

		local Known = select(1, WH.FruitBag())

		Value.Changed:Connect(function()
			local Counts = WH.FruitBag()
			local New = {}

			for Name, Count in pairs(Counts) do
				local Before = Known[Name] or 0
				for _ = 1, Count - Before do
					table.insert(New, Name)
				end
			end

			Known = Counts

			if #New > 0 then
				Session.Fruits = Session.Fruits + #New
				WH.Obtained("KindFruit", New, "Fruit", WH.Color.Loot)
			end
		end)
	end)

	task.spawn(function()
		local Folder = Data and Data:FindFirstChild("Sword")
		local Value = Folder and Folder:FindFirstChild("OwnedSwords")
		if not Value then
			return
		end

		local Known = WH.SwordSet()

		Value.Changed:Connect(function()
			local Owned = WH.SwordSet()
			local New = {}

			for Name in pairs(Owned) do
				if not Known[Name] then
					table.insert(New, Name)
				end
			end

			Known = Owned
			table.sort(New)

			if #New > 0 then
				Session.Swords = Session.Swords + #New
				WH.Obtained("KindSword", New, "Sword", WH.Color.Money)
			end
		end)
	end)

	task.spawn(function()
		local Known = WH.AccessorySet()
		local Seas = {
			Sea2Unlocked = WH.Read(Data, "Sea2Unlocked", false) == true,
			Sea3Unlocked = WH.Read(Data, "Sea3Unlocked", false) == true,
		}

		while true do
			task.wait(15)

			local Owned = WH.AccessorySet()
			local New = {}

			for Name in pairs(Owned) do
				if not Known[Name] then
					table.insert(New, Name)
				end
			end

			Known = Owned
			table.sort(New)

			if #New > 0 then
				WH.Obtained("KindAccessory", New, "Accessory", WH.Color.Loot)
			end

			for Flag, Was in pairs(Seas) do
				local Now = WH.Read(Data, Flag, false) == true
				if Now and not Was then
					Seas[Flag] = true
					WH.Report({
						Event = "SeaUnlock",
						Title = WH.T("SeaTitle"),
						Note = WH.T("SeaNote", Flag == "Sea2Unlocked" and "Sea 2" or "Sea 3"),
						Rows = {
							{ WH.T("RowSea"), WH.T(Flag == "Sea2Unlocked" and "Sea2Name" or "Sea3Name"), WH.Ink.Cyan },
							{ WH.T("RowLevel"), WH.Num(WH.Level()), WH.Ink.Blue },
							{ WH.T("RowUptime"), WH.Uptime(), WH.Ink.Grey },
						},
						Color = WH.Color.Good,
					})
				end
			end
		end
	end)

	task.spawn(function()
		local function Hook(Character)
			local Humanoid = Character:WaitForChild("Humanoid", 10)
			if not Humanoid then
				return
			end

			Humanoid.Died:Connect(function()
				Session.Deaths = Session.Deaths + 1

				local Root = Character:FindFirstChild("HumanoidRootPart")
				local Where = WH.T("Unknown")
				if Root then
					Where = string.format(
						"%d, %d, %d",
						math.floor(Root.Position.X),
						math.floor(Root.Position.Y),
						math.floor(Root.Position.Z)
					)
				end

				WH.Report({
					Event = "Death",
					Title = WH.T("DeathTitle"),
					Note = WH.T("DeathNote"),
					Rows = {
						{ WH.T("RowDeaths"), WH.T("DeathsRun", Session.Deaths), WH.Ink.Red },
						{ WH.T("RowSpot"), Where, WH.Ink.Grey },
						{
							WH.T("RowDriving"),
							tostring((type(VenuzRun) == "table" and VenuzRun.Owner) or WH.T("Nobody")),
							WH.Ink.Cyan,
						},
						{ WH.T("RowLevel"), WH.Num(WH.Level()), WH.Ink.Blue },
					},
					Color = WH.Color.Boss,
				})
			end)
		end

		if LocalPlayer.Character then
			pcall(Hook, LocalPlayer.Character)
		end

		LocalPlayer.CharacterAdded:Connect(function(Character)
			pcall(Hook, Character)
		end)
	end)

	task.spawn(function()
		LocalPlayer.OnTeleport:Connect(function(State)
			if State ~= Enum.TeleportState.Started then
				return
			end

			local Owner = type(VenuzRun) == "table" and VenuzRun.Owner or nil

			WH.Report({
				Event = "ServerHop",
				Title = WH.T("HopTitle"),
				Note = WH.T("HopNote"),
				Rows = {
					{ WH.T("RowReason"), Owner and WH.T("HopDriven", Owner) or WH.T("HopOther"), WH.Ink.Cyan },
					{ WH.T("RowUptime"), WH.Uptime(), WH.Ink.Grey },
					{ WH.T("RowLevel"), WH.Num(WH.Level()), WH.Ink.Blue },
					{ WH.T("RowBosses"), WH.T("BossCount", WH.Num(Session.Bosses)), WH.Ink.Red },
				},
				Color = WH.Color.Quiet,
			})

			task.wait(1.5)
		end)
	end)

	task.spawn(function()
		local Tracked = {}

		while true do
			task.wait(1)

			local Found = WH.LiveBosses()

			if Found then
				local Seen = {}

				for _, Entry in ipairs(Found) do
					Seen[Entry.Mob] = true

					local Record = Tracked[Entry.Mob]
					if not Record then
						Record = {
							Name = Entry.Name,
							Zone = Entry.Zone,
							Humanoid = Entry.Humanoid,
							First = os.clock(),
							Near = 0,
						}
						Tracked[Entry.Mob] = Record
					end

					Record.Zone = Entry.Zone

					if Entry.Distance <= 250 then
						Record.Near = os.clock()
					end
				end

				for Mob, Record in pairs(Tracked) do
					local Dead = (not Mob.Parent) or (Record.Humanoid and Record.Humanoid.Health <= 0)

					if Dead or not Seen[Mob] then
						Tracked[Mob] = nil

						local Credited = Record.Near > 0 and (os.clock() - Record.Near) <= 20
						local ReallyDead = Record.Humanoid and Record.Humanoid.Health <= 0

						if Credited and ReallyDead then
							WH.BossKilled(Record.Name, Record.Zone, os.clock() - Record.First)
						end
					end
				end
			end
		end
	end)

	task.spawn(function()
		local Next = os.clock() + 60

		while true do
			task.wait(20)

			local Config = WH.Config()
			if Config and Config.Heartbeat and WH.Url() then
				if os.clock() >= Next then
					Next = os.clock() + math.max(60, (tonumber(Config.HeartbeatMinutes) or 30) * 60)
					WH.SendSession(true)
				end
			else
				Next = os.clock() + 60
			end
		end
	end)
end
(function()
	local InfoTab = TabGroups.Main:Tab({
		Title = "tr:InfoTab",
		Icon = "info",
		Locked = false,
	})

	local InfoData = LocalPlayer:WaitForChild("PlayerData")

	local Paint, Bold, Field, Head, Mark, Item, Progress, Sep =
		RT.Paint, RT.Bold, RT.Field, RT.Head, RT.Mark, RT.Item, RT.Progress, RT.Sep

	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local function Collect(Adder)
		local Names, Seen = {}, {}

		Adder(function(Name)
			if type(Name) == "string" and Name ~= "" and not Seen[Name] then
				Seen[Name] = true
				table.insert(Names, Name)
			end
		end)

		return Names
	end

	local function Grab(Path, Timeout)
		local Node = ReplicatedStorage
		for Part in Path:gmatch("[^%.]+") do
			local ok, Child = pcall(function()
				return Node:WaitForChild(Part, Timeout or 5)
			end)
			if not ok or not Child then
				return nil
			end
			Node = Child
		end
		return Node
	end

	local function Required(Path)
		local Module = Grab(Path)
		if not Module then
			return nil
		end
		local ok, Result = pcall(require, Module)
		return ok and type(Result) == "table" and Result or nil
	end

	local SwordRarity = (Required("Weapons.SwordRarities") or {}).SwordRarities or {}

	local SwordNames = Collect(function(Add)
		local Viewport = Grab("ViewportModels.Swords")
		if Viewport then
			for _, Model in ipairs(Viewport:GetChildren()) do
				Add(Model.Name)
			end
		end

		local Weapons = Grab("Weapons")
		if Weapons then
			for _, Tool in ipairs(Weapons:GetChildren()) do
				if Tool:IsA("Tool") then
					Add(Tool.Name)
				end
			end
		end

		for Name in pairs(SwordRarity) do
			Add(Name)
		end
	end)

	do
		local Order = { Common = 1, Uncommon = 2, Rare = 3, Legendary = 4, Mythical = 5, Godly = 6, Unobtainable = 7 }
		table.sort(SwordNames, function(a, b)
			local ra = Order[SwordRarity[a]] or 99
			local rb = Order[SwordRarity[b]] or 99
			if ra == rb then
				return a < b
			end
			return ra < rb
		end)
	end

	local FightStyleNames = Collect(function(Add)
		Add("Combat")

		local Sellers = workspace:FindFirstChild("Npc_Workspace")
		Sellers = Sellers and Sellers:FindFirstChild("FightingStyle")
		if Sellers then
			for _, Npc in ipairs(Sellers:GetChildren()) do
				Add(Npc.Name)
			end
		end

		local V2 = Required("Config.FightStyleV2Data") or {}
		for Name in pairs(V2) do
			Add(Name)
			Add(Name .. " V2")
		end

		local ok, Owned = pcall(function()
			return HttpService:JSONDecode(InfoData:WaitForChild("OwnedFightingStyles", 5).Value)
		end)
		if ok and type(Owned) == "table" then
			for _, Name in ipairs(Owned) do
				Add(Name)
			end
		end
	end)

	table.sort(FightStyleNames)

	local HakiColorNames = Collect(function(Add)
		for Name in pairs(Required("Config.HakiColor") or {}) do
			Add(Name)
		end
	end)

	table.sort(HakiColorNames)

	local function Peek(Path)
		local Node = ReplicatedStorage
		for Part in Path:gmatch("[^%.]+") do
			Node = Node:FindFirstChild(Part)
			if not Node then
				return nil
			end
		end
		return Node
	end

	local function PeekRequire(Path)
		local Module = Peek(Path)
		if not Module or not Module:IsA("ModuleScript") then
			return nil
		end
		local ok, Result = pcall(require, Module)
		return ok and type(Result) == "table" and Result or nil
	end

	local AccessoryFolders = {
		"ViewportModels.Accessories",
		"ViewportModels.Accessory",
		"Accessories",
		"Accessory",
		"Assets.Accessories",
	}

	local AccessoryModules = {
		"Config.AccessoryData",
		"Config.Accessories",
		"Config.Accessory",
		"Accessories.AccessoryData",
	}

	local AccessoryNames = Collect(function(Add)
		for _, Path in ipairs(AccessoryFolders) do
			local Folder = Peek(Path)
			if Folder then
				for _, Object in ipairs(Folder:GetChildren()) do
					Add(Object.Name)
				end
			end
		end

		for _, Path in ipairs(AccessoryModules) do
			for Key, Entry in pairs(PeekRequire(Path) or {}) do
				if type(Key) == "string" then
					Add(Key)
				elseif type(Entry) == "table" and type(Entry.Name) == "string" then
					Add(Entry.Name)
				elseif type(Entry) == "string" then
					Add(Entry)
				end
			end
		end
	end)

	table.sort(AccessoryNames)

	local function Comma(Number)
		local Text = tostring(math.floor(tonumber(Number) or 0))
		local Done
		repeat
			Text, Done = Text:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		until Done == 0
		return Text
	end

	local function ValueOf(Parent, Name, Default)
		local Object = Parent and Parent:FindFirstChild(Name)
		if Object == nil then
			return Default
		end
		return Object.Value
	end

	local function JsonList(RawValue)
		local Set = {}
		if type(RawValue) ~= "string" or RawValue == "" then
			return Set
		end
		local ok, Decoded = pcall(function()
			return HttpService:JSONDecode(RawValue)
		end)
		if ok and type(Decoded) == "table" then
			for Key, Item in pairs(Decoded) do
				if type(Item) == "string" then
					Set[Item] = true
				elseif type(Key) == "string" then
					Set[Key] = true
				end
			end
		end
		return Set
	end

	local function CommaList(RawValue, Set)
		if type(RawValue) ~= "string" then
			return Set
		end
		for Name in RawValue:gmatch("[^,]+") do
			Name = Name:match("^%s*(.-)%s*$")
			if Name ~= "" then
				Set[Name] = true
			end
		end
		return Set
	end

	local function AccessoryStore()
		return InfoData:FindFirstChild("Accessory") or InfoData:FindFirstChild("Accessories")
	end

	local function StringValue(Parent, Name)
		local Object = Parent and Parent:FindFirstChild(Name)
		if not Object or not Object:IsA("ValueBase") then
			return nil
		end
		return type(Object.Value) == "string" and Object.Value or nil
	end

	local function AccessoryOwned()
		local Set = {}
		local Store = AccessoryStore()

		for _, Root in ipairs({ Store, InfoData }) do
			if Root then
				for _, Key in ipairs({ "OwnedAccessories", "OwnedAccessory", "Accessories" }) do
					local Raw = StringValue(Root, Key)
					if Raw and Raw ~= "" then
						local Decoded = JsonList(Raw)
						if next(Decoded) then
							for Name in pairs(Decoded) do
								Set[Name] = true
							end
						else
							CommaList(Raw, Set)
						end
					end
				end
			end
		end

		if Store then
			for _, Object in ipairs(Store:GetChildren()) do
				if Object:IsA("BoolValue") then
					if Object.Value then
						Set[Object.Name] = true
					end
				elseif Object:IsA("Folder") then
					Set[Object.Name] = true
				end
			end
		end

		return Set
	end

	local function AccessoryEquipped()
		local Store = AccessoryStore()
		for _, Root in ipairs({ Store, InfoData }) do
			if Root then
				for _, Key in ipairs({ "CurrentAccessory", "EquippedAccessory", "Accessory" }) do
					local Value = StringValue(Root, Key)
					if Value and Value ~= "" then
						return Value
					end
				end
			end
		end
		return "None"
	end

	local function FruitCounts()
		local Counts = {}
		local Raw = ValueOf(InfoData, "CollectedFruits", "")
		if type(Raw) ~= "string" then
			return Counts
		end
		for Name in Raw:gmatch("[^,]+") do
			Name = Name:match("^%s*(.-)%s*$")
			if Name ~= "" then
				Counts[Name] = (Counts[Name] or 0) + 1
			end
		end
		return Counts
	end

	local function MasteryLevel(Category, Name)
		local Mastery = InfoData:FindFirstChild("Mastery")
		if not Mastery then
			return 0
		end
		local Folder = Mastery
		if Category ~= "" then
			Folder = Mastery:FindFirstChild(Category)
		end
		local Entry = Folder and Folder:FindFirstChild(Name)
		local Level = Entry and Entry:FindFirstChild(Name .. "Level")
		return Level and math.max(0, Level.Value) or 0
	end

	local function Checklist(Names, HasFunction)
		local Lines, Owned = {}, 0
		for _, Name in ipairs(Names) do
			local Has = HasFunction(Name)
			if Has then
				Owned = Owned + 1
			end
			table.insert(Lines, Item(Name, Has))
		end
		return table.concat(Lines, "\n"), Owned
	end

	local function MakeParagraph(Section, Title)
		local ok, Paragraph = pcall(function()
			return Section:Paragraph({ Title = Title, Desc = "..." })
		end)
		if ok and Paragraph then
			RT.Enable(Paragraph)
			return Paragraph
		end
		local ok2, Fallback = pcall(function()
			return InfoTab:Paragraph({ Title = Title, Desc = "..." })
		end)
		if ok2 and Fallback then
			RT.Enable(Fallback)
			return Fallback
		end
		return nil
	end

	local PlayerSection = InfoTab:Section({ Title = "tr:InfoPlayerSection", Icon = "user", Opened = true })
	local PlayerParagraph = MakeParagraph(PlayerSection, "tr:InfoPlayer")

	local FruitSection = InfoTab:Section({ Title = "tr:InfoFruitSection", Icon = "apple", Opened = true })
	local FruitParagraph = MakeParagraph(FruitSection, "tr:InfoFruit")

	local SwordSectionInfo = InfoTab:Section({ Title = "tr:InfoSwordSection", Icon = "sword", Opened = true })
	local SwordParagraph = MakeParagraph(SwordSectionInfo, "tr:InfoSword")

	local AccessorySection = InfoTab:Section({ Title = "tr:InfoAccessorySection", Icon = "shirt", Opened = true })
	local AccessoryParagraph = MakeParagraph(AccessorySection, "tr:InfoAccessory")

	local StyleSection = InfoTab:Section({ Title = "tr:InfoStyleSection", Icon = "hand", Opened = true })
	local StyleParagraph = MakeParagraph(StyleSection, "tr:InfoStyle")

	local HakiSection = InfoTab:Section({ Title = "tr:InfoHakiSection", Icon = "sparkles", Opened = true })
	local HakiParagraph = MakeParagraph(HakiSection, "tr:InfoHaki")

	local function SetDesc(Paragraph, Text)
		RT.Push("Info panel", Paragraph, function()
			return Text
		end)
	end

	local function BuildPlayer()
		local Level = ValueOf(InfoData:FindFirstChild("Experience"), "Level", 0)
		local Exp = ValueOf(InfoData:FindFirstChild("Experience"), "Experience", nil)
		local Fruit = ValueOf(InfoData, "CurrentSuperPower", "")
		local Style = ValueOf(InfoData, "FightingStyle", "Combat")
		local Sword = ValueOf(InfoData, "CurrentSword", nil)

		local function Mastery(Value)
			return Paint("  ·  ", RT.Faint) .. Paint("Mastery ", RT.Muted) .. Bold(Value, RT.Purple)
		end

		local Lines = {
			Head("Profile"),
			Field("Player", LocalPlayer.Name, RT.Cyan),
			Field("Level", Comma(Level), RT.Blue),
			Field("Beli", "$" .. Comma(ValueOf(InfoData, "Currency", 0)), RT.Amber),
			Field("Gems", Comma(ValueOf(InfoData, "Gems", 0)), RT.Pink),
		}
		if Exp then
			table.insert(Lines, Field("EXP", Comma(Exp), RT.Muted))
		end

		table.insert(Lines, Field("Race", tostring(ValueOf(InfoData, "Race", "None"))))
		table.insert(Lines, Field("Title", tostring(ValueOf(InfoData, "Title", "None"))))

		table.insert(
			Lines,
			Paint("Sea 2 ", RT.Muted)
				.. Mark(ValueOf(InfoData, "Sea2Unlocked", false))
				.. Sep
				.. Paint("Sea 3 ", RT.Muted)
				.. Mark(ValueOf(InfoData, "Sea3Unlocked", false))
		)

		table.insert(Lines, Head("Loadout", RT.Purple))
		table.insert(
			Lines,
			Field("Devil Fruit", Fruit ~= "" and Fruit or "None", Fruit ~= "" and RT.Text or RT.Muted)
				.. (Fruit ~= "" and Mastery(MasteryLevel("Fruit", Fruit)) or "")
		)
		table.insert(Lines, Field("Fighting Style", tostring(Style)) .. Mastery(MasteryLevel("", tostring(Style))))

		if Sword and Sword ~= "" then
			table.insert(Lines, Field("Sword", tostring(Sword)) .. Mastery(MasteryLevel("Sword", tostring(Sword))))
		end

		local Accessory = AccessoryEquipped()
		table.insert(Lines, Field("Accessory", Accessory, Accessory ~= "None" and RT.Cyan or RT.Muted))

		SetDesc(PlayerParagraph, table.concat(Lines, "\n"))
	end

	local function BuildFruit()
		local Counts = FruitCounts()
		local Current = ValueOf(InfoData, "CurrentSuperPower", "")

		local Names = {}
		for Name in pairs(Counts) do
			table.insert(Names, Name)
		end
		table.sort(Names)

		local Lines = {}
		for _, Name in ipairs(Names) do
			table.insert(
				Lines,
				Paint("• ", RT.Faint) .. Paint(Name, RT.Text) .. Paint("  x", RT.Muted) .. Bold(Counts[Name], RT.Cyan)
			)
		end

		local Header = table.concat({
			Head("Devil Fruits", RT.Purple),
			Field("Eaten", Current ~= "" and Current or "None", Current ~= "" and RT.Purple or RT.Muted)
				.. Sep
				.. Field("In bag", #Names .. " type(s)", RT.Text),
		}, "\n") .. "\n"

		SetDesc(
			FruitParagraph,
			Header .. (#Lines > 0 and table.concat(Lines, "\n") or Paint("Fruit Bag is empty.", RT.Muted))
		)
	end

	local function BuildSword()
		local SwordFolder = InfoData:FindFirstChild("Sword")
		local OwnedSet = JsonList(ValueOf(SwordFolder, "OwnedSwords", ""))
		local Text, Owned = Checklist(SwordNames, function(Name)
			return OwnedSet[Name] == true
		end)

		SetDesc(
			SwordParagraph,
			table.concat({
				Head("Swords", RT.Amber),
				Paint("Owned: ", RT.Muted)
					.. Progress(Owned, #SwordNames)
					.. Sep
					.. Field("Equipped", tostring(ValueOf(InfoData, "CurrentSword", "None")), RT.Amber),
				Text,
			}, "\n")
		)
	end

	local function BuildAccessory()
		local OwnedSet = AccessoryOwned()
		local Equipped = AccessoryEquipped()

		local Names = AccessoryNames
		if #Names == 0 then
			Names = {}
			for Name in pairs(OwnedSet) do
				table.insert(Names, Name)
			end
			table.sort(Names)
		end

		local Text, Owned = Checklist(Names, function(Name)
			return OwnedSet[Name] == true or Name == Equipped
		end)

		SetDesc(
			AccessoryParagraph,
			table.concat({
				Head("Accessories", RT.Cyan),
				Paint("Owned: ", RT.Muted)
					.. Progress(Owned, math.max(#Names, 1))
					.. Sep
					.. Field("Equipped", Equipped, RT.Cyan),
				#Names > 0 and Text or Paint("No accessory data found.", RT.Muted),
			}, "\n")
		)
	end

	local function BuildStyle()
		local Current = tostring(ValueOf(InfoData, "FightingStyle", "Combat"))

		local OwnedSet = JsonList(ValueOf(InfoData, "OwnedFightingStyles", ""))

		local Text, Owned = Checklist(FightStyleNames, function(Name)
			return Name == "Combat" or OwnedSet[Name] == true
		end)

		SetDesc(
			StyleParagraph,
			table.concat({
				Head("Fighting Styles", RT.Pink),
				Field("Using", Current, RT.Pink) .. Sep .. Paint("Owned: ", RT.Muted) .. Progress(
					Owned,
					#FightStyleNames
				),
				Text,
			}, "\n")
		)
	end

	local function BuildHaki()
		local Buso = ValueOf(InfoData:FindFirstChild("Buso"), "BusoLevel", 0)
		local Obs = ValueOf(InfoData:FindFirstChild("Haki"), "ObservationHakiLevel", 0)
		local Hao = ValueOf(InfoData, "HaoLevel", 0)
		local Geppo = ValueOf(InfoData, "GeppoLevel", 0)
		local Flash = ValueOf(InfoData, "FlashStepLevel", 0)

		local ColorSet = JsonList(ValueOf(InfoData, "OwnedHakiColors", ""))
		local Current = tostring(ValueOf(InfoData, "HakiColorString", "Black"))
		local ColorText, ColorOwned = Checklist(HakiColorNames, function(Name)
			return ColorSet[Name] == true or Name == Current
		end)

		local function Ability(Name, Level)
			local Value = Level > 0 and (Mark(true) .. " " .. Bold("Lv" .. Level, RT.Green)) or Mark(false)
			return Paint(Name .. ": ", RT.Muted) .. Value
		end

		local Lines = {
			Head("Haki", RT.Cyan),
			Ability("Buso (Armament)", Buso)
				.. Sep
				.. Field("Strikes", Comma(ValueOf(InfoData, "BusoStrikes", 0)), RT.Text)
				.. Sep
				.. Field("Hits Taken", Comma(ValueOf(InfoData:FindFirstChild("Buso"), "BusoHitsTaken", 0)), RT.Text),
			Ability("Observation", Obs) .. Sep .. Ability("Conqueror (Hao)", Hao),
			Ability("Geppo", Geppo) .. Sep .. Ability("Flash Step", Flash),
			Head("Colors", RT.Purple),
			Field("Haki Color", Current, RT.Purple) .. Sep .. Paint("Owned: ", RT.Muted) .. Progress(
				ColorOwned,
				#HakiColorNames
			),
			ColorText,
		}

		SetDesc(HakiParagraph, table.concat(Lines, "\n"))
	end

	local function RefreshInfo()
		pcall(BuildPlayer)
		pcall(BuildFruit)
		pcall(BuildSword)
		pcall(BuildAccessory)
		pcall(BuildStyle)
		pcall(BuildHaki)
	end

	local RefreshQueued = false

	local function QueueRefresh()
		if RefreshQueued then
			return
		end
		RefreshQueued = true

		task.delay(2, function()
			RefreshQueued = false
			RefreshInfo()
		end)
	end

	local Hooked = setmetatable({}, { __mode = "k" })

	local function HookValue(Object)
		if Hooked[Object] or not Object:IsA("ValueBase") then
			return
		end
		Hooked[Object] = Object.Changed:Connect(QueueRefresh)
	end

	local function UnhookValue(Object)
		local Connection = Hooked[Object]
		if Connection then
			pcall(function()
				Connection:Disconnect()
			end)
			Hooked[Object] = nil
		end
	end

	for _, Object in ipairs(InfoData:GetDescendants()) do
		HookValue(Object)
	end

	InfoData.DescendantAdded:Connect(function(Object)
		HookValue(Object)
		QueueRefresh()
	end)

	InfoData.DescendantRemoving:Connect(function(Object)
		UnhookValue(Object)
		QueueRefresh()
	end)

	LocalPlayer.CharacterAdded:Connect(QueueRefresh)

	RefreshInfo()
end)()

local Automatic = TabGroups.Farm:Tab({
	Title = "tr:Automatic",
	Icon = "swords",
	Locked = false,
})
SetTabOrder(Automatic, 1)

local NPCZones = workspace:WaitForChild("NPC Zones")

do
	local NPCCache, NPCCacheAt = {}, 0
	local NPCAlive, NPCAliveAt = {}, 0
	local NPCSeen = {}
	local NPCHooked = false

	local function RootFor(Humanoid, Mob)
		return Humanoid.RootPart
			or Mob:FindFirstChild("HumanoidRootPart")
			or Mob.PrimaryPart
			or Mob:FindFirstChild("UpperTorso")
			or Mob:FindFirstChild("Torso")
			or Mob:FindFirstChild("Head")
			or Mob:FindFirstChildWhichIsA("BasePart")
	end

	local function AddNPC(Humanoid)
		if NPCSeen[Humanoid] then
			return true
		end

		local Mob = Humanoid.Parent
		if not (Mob and Mob:IsA("Model")) or Players:GetPlayerFromCharacter(Mob) then
			return false
		end

		local MobRoot = RootFor(Humanoid, Mob)
		if not MobRoot then
			return false
		end

		NPCSeen[Humanoid] = true

		NPCCache[#NPCCache + 1] = { Mob = Mob, Root = MobRoot, Humanoid = Humanoid, ModelName = Mob.Name }
		return true
	end

	local function TrackNPC(Humanoid)
		for _ = 1, 5 do
			if AddNPC(Humanoid) or not Humanoid.Parent then
				return
			end
			task.wait(0.2)
		end
	end

	local function RebuildNPCCache()
		table.clear(NPCCache)
		table.clear(NPCSeen)

		for _, Object in ipairs(NPCZones:GetDescendants()) do
			if Object:IsA("Humanoid") then
				AddNPC(Object)
			end
		end
	end

	function IterNPCs()
		if not NPCHooked then
			NPCHooked = true

			NPCZones.DescendantAdded:Connect(function(Object)
				if Object:IsA("Humanoid") then
					task.spawn(TrackNPC, Object)
				end
			end)
		end

		local Now = tick()

		if Now - NPCCacheAt > 12 then
			NPCCacheAt = Now
			RebuildNPCCache()
		end

		if Now - NPCAliveAt <= 0.1 then
			return NPCAlive
		end

		NPCAliveAt = Now

		local Alive = {}
		local Index = 1

		while Index <= #NPCCache do
			local Entry = NPCCache[Index]

			if not Entry.Mob.Parent then
				NPCSeen[Entry.Humanoid] = nil
				local Last = #NPCCache
				NPCCache[Index] = NPCCache[Last]
				NPCCache[Last] = nil
			else
				if Entry.Root.Parent and Entry.Humanoid.Health > 0 then
					Alive[#Alive + 1] = Entry
				end
				Index = Index + 1
			end
		end

		NPCAlive = Alive
		return Alive
	end
end

local QuestGivers = workspace:WaitForChild("Npc_Workspace"):WaitForChild("QuestGivers")
local PlayerData = LocalPlayer:WaitForChild("PlayerData")
local LevelValue = PlayerData:WaitForChild("Experience"):WaitForChild("Level")

task.spawn(function()
	local Logic = workspace:WaitForChild("Logic", 30)
	local Positions = Logic and Logic:WaitForChild("QuestGiverPositions", 30)
	if not Positions then
		return
	end

	local function Evict(Item)
		if Item:IsA("Attachment") then
			pcall(function()
				Item.Parent = nil
			end)
		end
	end

	for _, Item in ipairs(Positions:GetDescendants()) do
		Evict(Item)
	end

	Positions.DescendantAdded:Connect(Evict)
end)

getgenv().LevelConfig = {
	{
		Level = 1,
		QuestName = "Kill 4 Thiefs",
		MonName = "Thief",
		MonPOS = Vector3.new(-2445.7, 44.8, -3257.9),
		WaitPOS = Vector3.new(-2524, 45, -3369),
	},
	{
		Level = 10,
		QuestName = "Kill 4 Bandits",
		MonName = "Bandit",
		MonPOS = Vector3.new(-1973.6, 44.7, -3214.0),
		WaitPOS = Vector3.new(-1969, 74, -3326),
	},
	{
		Level = 25,
		QuestName = "Kill 1 Bandit Boss",
		MonName = "Bandit Boss",
		MonPOS = Vector3.new(-1934.6, 66.9, -3443.1),
		WaitPOS = Vector3.new(-1833, 93, -3505),
	},
	{
		Level = 40,
		QuestName = "Kill 4 Pirate Clowns",
		MonName = "Pirate Clown",
		MonPOS = Vector3.new(-2344, 15, -732),
		WaitPOS = Vector3.new(-2273, 38, -618),
	},
	{
		Level = 60,
		QuestName = "Kill 1 Clown Boss",
		MonName = "Clown Boss",
		MonPOS = Vector3.new(-2267, 34, -447),
		WaitPOS = Vector3.new(-2273, 38, -618),
	},
	{
		Level = 90,
		QuestName = "Kill 5 Fishmans",
		MonName = "Fishman",
		MonPOS = Vector3.new(-4293.5, 12.1, -3340.6),
		WaitPOS = Vector3.new(-4120, 30, -3453),
	},
	{
		Level = 120,
		QuestName = "Kill 1 Shark Boss",
		MonName = "Shark Boss",
		MonPOS = Vector3.new(-4237.3, 7.5, -3043.7),
		WaitPOS = Vector3.new(-4272, 37, -3064),
	},
	{
		Level = 160,
		QuestName = "Kill 4 Desert Thies",
		MonName = "Desert Thief",
		MonPOS = Vector3.new(-4389.6, 14.2, -592.0),
		WaitPOS = Vector3.new(-4495, 58, -685),
	},
	{
		Level = 200,
		QuestName = "Kill 1 Bomb Boss",
		MonName = "Bomb Boss",
		MonPOS = Vector3.new(-4398.6, 13.8, -369.9),
		WaitPOS = Vector3.new(-4495, 58, -685),
	},
	{
		Level = 250,
		QuestName = "Kill 4 Krieg Pirates",
		MonName = "Krieg Pirate",
		MonPOS = Vector3.new(-5376.5, 7.2, 1778.1),
		WaitPOS = Vector3.new(-5371, 60, 1869),
	},
	{
		Level = 300,
		QuestName = "Kill 1 Krieg Boss",
		MonName = "Krieg Boss",
		MonPOS = Vector3.new(-5370.7, 14.8, 2032.6),
		WaitPOS = Vector3.new(-5371, 60, 1869),
	},
	{
		Level = 350,
		QuestName = "Kill 5 Marine Recruits",
		MonName = "Marine Recruit",
		MonPOS = Vector3.new(-2886, 77, 1612),
		WaitPOS = Vector3.new(-2886, 77, 1612),
	},
	{
		Level = 400,
		QuestName = "Kill 1 Tashii",
		MonName = "Tashii",
		IsBoss = true,
		MonPOS = Vector3.new(-3066, 21, 1886),
		WaitPOS = Vector3.new(-3141, 30, 1926),
	},
	{
		Level = 450,
		QuestName = "Kill 4 Monkeys",
		MonName = "Monkey",
		MonPOS = Vector3.new(-828, 11, 1876),
		WaitPOS = Vector3.new(-903, 110, 1752),
	},
	{
		Level = 500,
		QuestName = "Kill 4 Gorillas",
		MonName = "Gorilla",
		MonPOS = Vector3.new(-166, 14, 1711),
		WaitPOS = Vector3.new(-69, 16, 1925),
	},
	{
		Level = 550,
		QuestName = "Kill 1 King Gorilla",
		MonName = "King Gorilla",
		IsBoss = true,
		MonPOS = Vector3.new(-664, 24, 2357),
		WaitPOS = Vector3.new(-726, 43, 2286),
	},
	{
		Level = 600,
		QuestName = "Kill 4 Marine Grunts",
		MonName = "Marine Grunt",
		MonPOS = Vector3.new(-305, 13, 4878),
		WaitPOS = Vector3.new(-366, 63, 5060),
	},
	{
		Level = 650,
		QuestName = "Kill 1 Marine Captain",
		MonName = "Marine Captain",
		MonPOS = Vector3.new(-334, 130, 5403),
		WaitPOS = Vector3.new(-281, 152, 5418),
	},
	{
		Level = 700,
		QuestName = "Kill 3 Satyrs",
		MonName = "Satyr",
		MonPOS = Vector3.new(-2481, 856, 5026),
		WaitPOS = Vector3.new(-2598, 902, 4985),
	},
	{
		Level = 750,
		QuestName = "Kill 1 Minotaur",
		MonName = "Minotaur",
		MonPOS = Vector3.new(-2819, 870, 4810),
		WaitPOS = Vector3.new(-2819, 870, 4810),
	},
	{
		Level = 800,
		QuestName = "Kill 4 Elite Marines",
		MonName = "Elite Marine",
		MonPOS = Vector3.new(-5482, 21, 5906),
		WaitPOS = Vector3.new(-5502, 60, 5777),
	},
	{
		Level = 850,
		QuestName = "Kill 1 Vice Admiral",
		MonName = "Vice Admiral",
		IsBoss = true,
		MonPOS = Vector3.new(-5233, 21, 6002),
		WaitPOS = Vector3.new(-5164, 53, 6137),
	},
	{
		Level = 900,
		QuestName = "Kill 1 Ice Admiral",
		MonName = "Ice Admiral",
		IsBoss = true,
		MonPOS = Vector3.new(-6123, 207, 5991),
		WaitPOS = Vector3.new(-6273, 244, 6008),
	},
	{
		Level = 950,
		QuestName = "Kill 4 Sandorian Warriors",
		MonName = "Sandorian Warrior",
		MonPOS = Vector3.new(1857, 1098, -329),
		WaitPOS = Vector3.new(1727, 1139, -193),
	},
	{
		Level = 1000,
		QuestName = "Kill 4 Divine Soldiers",
		MonName = "Divine Soldier",
		MonPOS = Vector3.new(1699, 1100, -157),
		WaitPOS = Vector3.new(1727, 1139, -193),
	},
	{
		Level = 1050,
		QuestName = "Kill 5 Holy Soldiers",
		MonName = "Holy Soldier",
		MonPOS = Vector3.new(2015, 2031, 916),
		WaitPOS = Vector3.new(2027, 2161, 1066),
	},
	{
		Level = 1100,
		QuestName = "Kill 1 Thunder God",
		MonName = "Thunder God",
		IsBoss = true,
		MonPOS = Vector3.new(2015, 2031, 916),
		WaitPOS = Vector3.new(2027, 2161, 1066),
	},
	{
		Level = 1150,
		QuestName = "Kill 4 Revolutionarys",
		MonName = "Revolutionary",
		MonPOS = Vector3.new(2497, 36, 3283),
		WaitPOS = Vector3.new(2412, 53, 3192),
	},
	{
		Level = 1200,
		QuestName = "Kill 4 Revolutionary Elites",
		MonName = "Revolutionary Elite",
		IsBoss = true,
		MonPOS = Vector3.new(2497, 36, 3283),
		WaitPOS = Vector3.new(2412, 53, 3192),
	},
	{
		Level = 1250,
		QuestName = "Kill 1 Revolutionary Boss",
		MonName = "Revolutionary Boss",
		MonPOS = Vector3.new(2497, 36, 3283),
		WaitPOS = Vector3.new(2412, 53, 3192),
	},
	{
		Level = 1300,
		QuestName = "Kill 4 Impel Guards",
		MonName = "Impel Guard",
		MonPOS = Vector3.new(2685, 11, 6122),
		WaitPOS = Vector3.new(2659, 52, 5982),
	},
	{
		Level = 1350,
		QuestName = "Kill 4 Impel Elites",
		MonName = "Impel Elite",
		MonPOS = Vector3.new(2685, 11, 6122),
		WaitPOS = Vector3.new(2659, 52, 5982),
	},
	{
		Level = 1400,
		QuestName = "Kill 1 Warden",
		MonName = "Warden",
		IsBoss = true,
		MonPOS = Vector3.new(2740, 11, 6271),
		WaitPOS = Vector3.new(2659, 52, 5982),
	},
	{
		Level = 1450,
		QuestName = "Kill 4 Corrupt Marines",
		MonName = "Corrupt Marine",
		MonPOS = Vector3.new(1829, 18, -2441),
		WaitPOS = Vector3.new(1827, 44, -2315),
	},
	{
		Level = 1500,
		QuestName = "Kill 1 Vergo",
		MonName = "Vergo",
		IsBoss = true,
		MonPOS = Vector3.new(
			2369.99194,
			30.4018364,
			-3117.1333,
			0.100726545,
			-0.00273034163,
			0.994910419,
			-0.00132148073,
			0.999994993,
			0.00287808431,
			-0.99491328,
			-0.00160465436,
			0.100722432
		),
		WaitPOS = Vector3.new(2410, 56, -3126),
	},
	{
		Level = 1550,
		QuestName = "Kill 1 Snow Harpy",
		MonName = "Snow Harpy",
		IsBoss = true,
		MonPOS = Vector3.new(2431, 42, -2418),
		WaitPOS = Vector3.new(2467, 64, -2382),
	},
	{
		Level = 1600,
		QuestName = "Kill 5 Island Fishmans",
		MonName = "Island Fishman",
		MonPOS = Vector3.new(4979, 48, -3205),
		WaitPOS = Vector3.new(5088, 87, -3279),
	},
	{
		Level = 1650,
		QuestName = "Kill 4 Fishman Elites",
		MonName = "Fishman Elite",
		MonPOS = Vector3.new(5033, 35, -2845),
		WaitPOS = Vector3.new(5033, 35, -2845),
	},
	{
		Level = 1700,
		QuestName = "Kill 1 Neptune",
		MonName = "Neptune",
		IsBoss = true,
		IsBoss = true,
		MonPOS = Vector3.new(5336, 194, -2425),
		WaitPOS = Vector3.new(5336, 194, -2425),
	},
	{
		Level = 1750,
		QuestName = "Kill 4 Skull Pirates",
		MonName = "Skull Pirate",
		MonPOS = Vector3.new(4786, 42, -19),
		WaitPOS = Vector3.new(4786, 42, -19),
	},
	{
		Level = 1800,
		QuestName = "Kill 4 Pirate Elites",
		MonName = "Pirate Elite",
		MonPOS = Vector3.new(5199, 64, -258),
		WaitPOS = Vector3.new(5199, 64, -258),
	},
	{
		Level = 1850,
		QuestName = "Kill 1 Shiryu",
		MonName = "Shiryu",
		IsBoss = true,
		MonPOS = Vector3.new(5277, 135, 115),
		WaitPOS = Vector3.new(5277, 135, 115),
	},
	{
		Level = 1900,
		QuestName = "Kill 4 Pirates",
		MonName = "Pirate",
		MonPOS = Vector3.new(5292, 64, 2576),
		WaitPOS = Vector3.new(5292, 64, 2576),
	},
	{
		Level = 1950,
		QuestName = "Kill 4 Armored Marines",
		MonName = "Armored Marine",
		MonPOS = Vector3.new(5278, 31, 1997),
		WaitPOS = Vector3.new(5278, 31, 1997),
	},
	{
		Level = 2000,
		QuestName = "Kill 1 G4 Boss",
		MonName = "G4 Boss",
		IsBoss = true,
		MonPOS = Vector3.new(4938, 90, 2849),
		WaitPOS = Vector3.new(4938, 90, 2849),
	},
	{
		Level = 2050,
		QuestName = "Kill 4 Skeletons",
		MonName = "Skeleton",
		MonPOS = Vector3.new(5359, 23, 5692),
		WaitPOS = Vector3.new(5359, 23, 5692),
	},
	{
		Level = 2100,
		QuestName = "Kill 4 Mummys",
		MonName = "Mummy",
		MonPOS = Vector3.new(5667, 83, 6040),
		WaitPOS = Vector3.new(5667, 83, 6040),
	},
	{
		Level = 2150,
		QuestName = "Kill 1 Ryummy",
		MonName = "Ryummy",
		IsBoss = true,
		MonPOS = Vector3.new(5538, 175, 6246),
		WaitPOS = Vector3.new(5538, 175, 6246),
	},
	{
		Level = 2200,
		QuestName = "Kill 4 Samurais",
		MonName = "Samurai",
		MonPOS = Vector3.new(2313, 69, 16440),
		WaitPOS = Vector3.new(2313, 69, 16440),
	},
	{
		Level = 2250,
		QuestName = "Kill 4 Strong Samurais",
		MonName = "Strong Samurai",
		MonPOS = Vector3.new(2833, 71, 16710),
		WaitPOS = Vector3.new(2833, 71, 16710),
	},
	{
		Level = 2300,
		QuestName = "Kill 4 Shinobis",
		MonName = "Shinobi",
		MonPOS = Vector3.new(2040, 71, 16088),
		WaitPOS = Vector3.new(2040, 71, 16088),
	},
	{
		Level = 2350,
		QuestName = "Kill 4 Shinobi Elites",
		MonName = "Shinobi Elite",
		MonPOS = Vector3.new(2040, 71, 16088),
		WaitPOS = Vector3.new(2040, 71, 16088),
	},
	{
		Level = 2400,
		QuestName = "Kill 4 Officer Guards",
		MonName = "Officer Guard",
		MonPOS = Vector3.new(1870, 86, 11645),
		WaitPOS = Vector3.new(1870, 86, 11645),
	},
	{
		Level = 2450,
		QuestName = "Kill 4 Sergeant Guards",
		MonName = "Sergeant Guard",
		MonPOS = Vector3.new(2185, 115, 11414),
		WaitPOS = Vector3.new(2185, 115, 11414),
	},
	{
		Level = 2500,
		QuestName = "Kill 1 Mammoth Boss",
		MonName = "Mammoth Boss",
		IsBoss = true,
		MonPOS = Vector3.new(2185, 115, 11414),
		WaitPOS = Vector3.new(2185, 115, 11414),
	},
	{
		Level = 2550,
		QuestName = "Kill 4 Graverobbers",
		MonName = "Graverobber",
		MonPOS = Vector3.new(6804, 54, 15858),
		WaitPOS = Vector3.new(6804, 54, 15858),
	},
	{
		Level = 2600,
		QuestName = "Kill 4 Elite Graverobbers",
		MonName = "Elite Graverobber",
		MonPOS = Vector3.new(7218, 81, 16410),
		WaitPOS = Vector3.new(7218, 81, 16410),
	},
	{
		Level = 2650,
		QuestName = "Kill 1 3SS Boss",
		MonName = "3SS Boss",
		IsBoss = true,
		MonPOS = Vector3.new(7726, 71, 15460),
		WaitPOS = Vector3.new(7726, 71, 15460),
	},
	{
		Level = 2700,
		QuestName = "Kill 4 Desert Pirates",
		MonName = "Desert Pirate",
		MonPOS = Vector3.new(7284, 79, 11696),
		WaitPOS = Vector3.new(7284, 79, 11696),
	},
	{
		Level = 2750,
		QuestName = "Kill 4 Desert Captains",
		MonName = "Desert Captain",
		MonPOS = Vector3.new(6835, 79, 12168),
		WaitPOS = Vector3.new(6835, 79, 12168),
	},
	{
		Level = 2800,
		QuestName = "Kill 1 Desert Boss",
		MonName = "Desert Boss",
		IsBoss = true,
		MonPOS = Vector3.new(7319, 48, 12308),
		WaitPOS = Vector3.new(7319, 48, 12308),
	},
	{
		Level = 2850,
		QuestName = "Kill 4 Beast Pirates",
		MonName = "Beast Pirate",
		MonPOS = Vector3.new(6696, 1131, 7413),
		WaitPOS = Vector3.new(6696, 1131, 7413),
	},
	{
		Level = 2900,
		QuestName = "Kill 4 Elite Beasts",
		MonName = "Elite Beast",
		MonPOS = Vector3.new(7353, 1137, 7227),
		WaitPOS = Vector3.new(7353, 1137, 7227),
	},
	{
		Level = 2950,
		QuestName = "Kill 1 MaceV2 Boss",
		MonName = "MaceV2 Boss",
		IsBoss = true,
		MonPOS = Vector3.new(7197, 1157, 6542),
		WaitPOS = Vector3.new(7197, 1157, 6542),
	},
	{
		Level = 3000,
		QuestName = "Kill 4 Shadow Pirates",
		MonName = "Shadow Pirate",
		MonPOS = Vector3.new(1903, 39, 7789),
		WaitPOS = Vector3.new(1903, 39, 7789),
	},
	{
		Level = 3050,
		QuestName = "Kill 4 Shadow Commanders",
		MonName = "Shadow Commander",
		MonPOS = Vector3.new(1535, 847, 7148),
		WaitPOS = Vector3.new(1535, 847, 7148),
	},
	{
		Level = 3100,
		QuestName = "Kill 1 Shadow Boss",
		MonName = "Shadow Boss",
		IsBoss = true,
		MonPOS = Vector3.new(1246, 1103, 6720),
		WaitPOS = Vector3.new(1246, 1103, 6720),
	},
	{
		Level = 3150,
		QuestName = "Kill 4 Peanut Pirates",
		MonName = "Peanut Pirate",
		MonPOS = Vector3.new(-3165, 211, 6651),
		WaitPOS = Vector3.new(-3165, 211, 6651),
	},
	{
		Level = 3200,
		QuestName = "Kill 4 Peanut Captains",
		MonName = "Peanut Captain",
		MonPOS = Vector3.new(-2304, 118, 6766),
		WaitPOS = Vector3.new(-2304, 118, 6766),
	},
	{
		Level = 3250,
		QuestName = "Kill 1 Peanut Boss",
		MonName = "Peanut Boss",
		IsBoss = true,
		MonPOS = Vector3.new(-2970, 278, 5818),
		WaitPOS = Vector3.new(-2970, 278, 5818),
	},
	{
		Level = 3300,
		QuestName = "Kill 4 Dough Pirates",
		MonName = "Dough Pirate",
		MonPOS = Vector3.new(-2603, 52, 10870),
		WaitPOS = Vector3.new(-2603, 52, 10870),
	},
	{
		Level = 3350,
		QuestName = "Kill 4 Dough Captains",
		MonName = "Dough Captain",
		MonPOS = Vector3.new(-2657, 40, 11359),
		WaitPOS = Vector3.new(-2599, 39, 11090),
	},
	{
		Level = 3400,
		QuestName = "Kill 1 Tree Boss",
		MonName = "Tree Boss",
		IsBoss = true,
		MonPOS = Vector3.new(-3083, 244, 10893),
		WaitPOS = Vector3.new(-3083, 244, 10893),
	},
	{
		Level = 3450,
		QuestName = "Level 3450",
		MonName = "Chocolate Pirate",
		MonPOS = Vector3.new(-3030, 82, 15669),
		WaitPOS = Vector3.new(-3030, 82, 15669),
	},
	{
		Level = 3500,
		QuestName = "Level 3500",
		MonName = "Candy Guard",
		MonPOS = Vector3.new(-3514, 163, 16275),
		WaitPOS = Vector3.new(-3514, 163, 16275),
	},
	{
		Level = 3550,
		QuestName = "Level 3550",
		MonName = "Soul Boss",
		IsBoss = true,
		MonPOS = Vector3.new(-4396, 271, 16871),
		WaitPOS = Vector3.new(-4396, 271, 16871),
	},
	{
		Level = 3600,
		QuestName = "Level 3600",
		MonName = "Baboon",
		MonPOS = Vector3.new(-8824, 75, 17675),
		WaitPOS = Vector3.new(-8824, 75, 17675),
	},
	{
		Level = 3650,
		QuestName = "Level 3650",
		MonName = "Strong Baboon",
		MonPOS = Vector3.new(-10309, 420, 17833),
		WaitPOS = Vector3.new(-10309, 420, 17833),
	},
	{
		Level = 3700,
		QuestName = "Level 3700",
		MonName = "Baboon Boss",
		IsBoss = true,
		MonPOS = Vector3.new(-11196, 504, 17299),
		WaitPOS = Vector3.new(-11196, 504, 17299),
	},
	{
		Level = 3750,
		QuestName = "Level 3750",
		MonName = "Snowman",
		MonPOS = Vector3.new(-8665, 31, 10939),
		WaitPOS = Vector3.new(-8665, 31, 10939),
	},
	{
		Level = 3800,
		QuestName = "Level 3800",
		MonName = "Snow Elite",
		MonPOS = Vector3.new(-8921, 144, 10427),
		WaitPOS = Vector3.new(-8921, 144, 10427),
	},
	{
		Level = 3850,
		QuestName = "Level 3850",
		MonName = "Snow Boss",
		IsBoss = true,
		MonPOS = Vector3.new(-9515, 208, 10873),
		WaitPOS = Vector3.new(-9515, 208, 10873),
	},
	{
		Level = 3900,
		QuestName = "Level 3900",
		MonName = "Love Warrior",
		MonPOS = Vector3.new(-9332, 109, 5701),
		WaitPOS = Vector3.new(-9332, 109, 5701),
	},
	{
		Level = 3950,
		QuestName = "Level 3950",
		MonName = "Snake Man",
		MonPOS = Vector3.new(-9930, 124, 5737),
		WaitPOS = Vector3.new(-9930, 124, 5737),
	},
	{
		Level = 4000,
		QuestName = "Level 4000",
		MonName = "Love Boss",
		IsBoss = true,
		MonPOS = Vector3.new(-9570, 174, 5445),
		WaitPOS = Vector3.new(-9570, 174, 5445),
	},
	{
		Level = 4050,
		QuestName = "Level 4050",
		MonName = "Venom Monster",
		MonPOS = Vector3.new(-10161, 131, 479),
		WaitPOS = Vector3.new(-10161, 131, 479),
	},
	{
		Level = 4100,
		QuestName = "Level 4100",
		MonName = "Venom Poacher",
		MonPOS = Vector3.new(-9618, 108, 34),
		WaitPOS = Vector3.new(-9618, 108, 34),
	},
	{
		Level = 4150,
		QuestName = "Level 4150",
		MonName = "Venom Boss",
		IsBoss = true,
		MonPOS = Vector3.new(-9800, 223, -521),
		WaitPOS = Vector3.new(-9800, 223, -521),
	},
	{
		Level = 4200,
		Sea = 3,
		QuestName = "Level 4200",
		MonName = "Celestial Guard",
		MonPOS = Vector3.new(-5177, 513, -1164),
		WaitPOS = Vector3.new(-5177, 513, -1164),
	},
	{
		Level = 4250,
		Sea = 3,
		QuestName = "Level 4250",
		MonName = "Celestial Captain",
		MonPOS = Vector3.new(-5790, 515, -1161),
		WaitPOS = Vector3.new(-5790, 515, -1161),
	},
	{
		Level = 4300,
		Sea = 3,
		QuestName = "Level 4300",
		MonName = "Barren Rebel",
		MonPOS = Vector3.new(-5027, 503, -95),
		WaitPOS = Vector3.new(-5027, 503, -95),
	},
	{
		Level = 4350,
		Sea = 3,
		QuestName = "Level 4350",
		MonName = "Enslaved Pirate",
		MonPOS = Vector3.new(-5904, 501, -102),
		WaitPOS = Vector3.new(-5904, 501, -102),
	},
	{
		Level = 4400,
		Sea = 3,
		QuestName = "Level 4400",
		MonName = "God's Knight",
		MonPOS = Vector3.new(-3220, 914, 2433),
		WaitPOS = Vector3.new(-3220, 914, 2433),
	},
	{
		Level = 4450,
		Sea = 3,
		QuestName = "Level 4450",
		MonName = "Leopard Boss",
		IsBoss = true,
		MonPOS = Vector3.new(-2556, 1007, 2446),
		WaitPOS = Vector3.new(-2556, 1007, 2446),
	},
	{
		Level = 4500,
		Sea = 3,
		QuestName = "Level 4500",
		MonName = "Thunder Disciple",
		MonPOS = Vector3.new(-4734, 991, 7415),
		WaitPOS = Vector3.new(-4734, 991, 7415),
	},
	{
		Level = 4550,
		Sea = 3,
		QuestName = "Level 4550",
		MonName = "Thunder Soldier",
		MonPOS = Vector3.new(-3867, 1043, 8048),
		WaitPOS = Vector3.new(-3867, 1043, 8048),
	},
	{
		Level = 4600,
		Sea = 3,
		QuestName = "Level 4600",
		MonName = "Raigo Priest",
		IsBoss = true,
		MonPOS = Vector3.new(-5084, 1754, 8198),
		WaitPOS = Vector3.new(-5084, 1754, 8198),
	},
	{
		Level = 4650,
		Sea = 3,
		QuestName = "Level 4650",
		MonName = "Authority Agent",
		MonPOS = Vector3.new(3653, 159, 634),
		WaitPOS = Vector3.new(3653, 159, 634),
	},
	{
		Level = 4700,
		Sea = 3,
		QuestName = "Level 4700",
		MonName = "Execution Unit",
		MonPOS = Vector3.new(4074, 83, 1153),
		WaitPOS = Vector3.new(4074, 83, 1153),
	},
	{
		Level = 4750,
		Sea = 3,
		QuestName = "Kill 1 Control Sentinel",
		MonName = "Control Sentinel",
		IsBoss = true,
		MonPOS = Vector3.new(3419, 88, 1141),
		WaitPOS = Vector3.new(3419, 88, 1141),
	},
}

function SeaOfEntry(Entry)
	return Entry.Sea or (Entry.Level >= 2200 and 2 or 1)
end

function CheckLevel(Level)
	Level = Level or LevelValue.Value

	local Sea = ({ [6918802270] = 1, [14979402479] = 2, [99664616626491] = 3 })[game.PlaceId] or 1
	local Selected = nil

	for _, Entry in ipairs(getgenv().LevelConfig) do
		local EntrySea = SeaOfEntry(Entry)

		if EntrySea == Sea and Level >= Entry.Level and (not Selected or Entry.Level > Selected.Level) then
			Selected = Entry
		end
	end

	return Selected
end

local function GetCharacter()
	local Character = LocalPlayer.Character
	if not Character or not Character.Parent then
		return nil
	end
	return Character
end

local function GetRoot()
	local Character = GetCharacter()
	return Character and Character:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
	local Character = GetCharacter()
	return Character and Character:FindFirstChildOfClass("Humanoid")
end

local function IsAlive()
	local Humanoid = GetHumanoid()
	return Humanoid ~= nil and Humanoid.Health > 0
end

local NoclipParts = {}
local NoclipIndex = {}
local NoclipCharacter_Ref = nil
local NoclipConnection = nil
local NoclipRemovingConnection = nil

local function NoclipUntrack(Part)
	local Index = NoclipIndex[Part]
	if not Index then
		return
	end

	local Last = #NoclipParts
	local Moved = NoclipParts[Last]

	NoclipParts[Index] = Moved
	NoclipIndex[Moved] = Index
	NoclipParts[Last] = nil
	NoclipIndex[Part] = nil
end

local function NoclipTrack(Part)
	if NoclipIndex[Part] or not Part:IsA("BasePart") then
		return
	end

	local Slot = #NoclipParts + 1
	NoclipParts[Slot] = Part
	NoclipIndex[Part] = Slot
end

local function NoclipCharacter(Character)
	if Character ~= NoclipCharacter_Ref then
		NoclipCharacter_Ref = Character
		table.clear(NoclipParts)
		table.clear(NoclipIndex)

		if NoclipConnection then
			pcall(function()
				NoclipConnection:Disconnect()
			end)
			NoclipConnection = nil
		end

		if NoclipRemovingConnection then
			pcall(function()
				NoclipRemovingConnection:Disconnect()
			end)
			NoclipRemovingConnection = nil
		end

		for _, Part in ipairs(Character:GetDescendants()) do
			NoclipTrack(Part)
		end

		NoclipConnection = Character.DescendantAdded:Connect(NoclipTrack)
		NoclipRemovingConnection = Character.DescendantRemoving:Connect(NoclipUntrack)
	end

	local Index = 1
	while Index <= #NoclipParts do
		local Part = NoclipParts[Index]

		if not Part.Parent then
			NoclipUntrack(Part)
		else
			if Part.CanCollide then
				Part.CanCollide = false
			end
			Index = Index + 1
		end
	end
end

local GroundStates = {
	Enum.HumanoidStateType.Freefall,
	Enum.HumanoidStateType.FallingDown,
	Enum.HumanoidStateType.Flying,
}
local GroundActive = false
local GroundHumanoid = nil

local function SetGroundState(On)
	local Humanoid = GetHumanoid()
	if not Humanoid then
		GroundActive = false
		GroundHumanoid = nil
		return
	end

	if On then
		if GroundActive and GroundHumanoid == Humanoid then
			return
		end

		for _, State in ipairs(GroundStates) do
			pcall(function()
				Humanoid:SetStateEnabled(State, false)
			end)
		end
		if Humanoid:GetState() ~= Enum.HumanoidStateType.Running then
			pcall(function()
				Humanoid:ChangeState(Enum.HumanoidStateType.Running)
			end)
		end
		GroundActive = true
		GroundHumanoid = Humanoid
	elseif GroundActive then
		for _, State in ipairs(GroundStates) do
			pcall(function()
				Humanoid:SetStateEnabled(State, true)
			end)
		end
		GroundActive = false
		GroundHumanoid = nil
	end
end

local LockCFrame = nil
local MoveTarget = nil
local MoveDone = false

local HoldCFrame = nil
local MaxStep = 40
local FarmRunning = false

FlyCruiseY = nil

local function CancelTween()
	MoveTarget = nil
	MoveDone = true
	FlyCruiseY = nil
end

local function Teleport(Target)
	if not IsCurrentInstance() then
		return false
	end

	local Root = GetRoot()
	if not Root then
		return false
	end
	CancelTween()

	local Character = GetCharacter()
	if Character then
		NoclipCharacter(Character)
	end

	Root.CFrame = Target
	Root.AssemblyLinearVelocity = Vector3.zero
	return true
end

local function GetQuestGui()
	local Gui = LocalPlayer:FindFirstChild("PlayerGui")
	return Gui and Gui:FindFirstChild("QuestGui")
end

local function GetQuestFolder()
	return LocalPlayer:FindFirstChild("Quest")
end

local function GetActiveQuest()
	local Quest = GetQuestFolder()
	if not Quest then
		return nil
	end

	local NPCName = Quest:FindFirstChild("NPCName")
	if not NPCName or NPCName.Value == "" then
		return nil
	end

	local QuestName = Quest:FindFirstChild("QuestName")
	return NPCName.Value, QuestName and QuestName.Value or ""
end

local function QuestMatches(Entry)
	local MobName, QuestName = GetActiveQuest()
	if not MobName then
		return false
	end
	return MobName == Entry.MonName or (QuestName ~= "" and QuestName == Entry.QuestName)
end

function FindEntryByMob(MonName)
	for _, Entry in ipairs(getgenv().LevelConfig) do
		if Entry.MonName == MonName then
			return Entry
		end
	end
	return nil
end

function FindQuestGiver(QuestName, MonName)
	for _, Giver in ipairs(QuestGivers:GetChildren()) do
		local Configuration = Giver:FindFirstChild("Configuration")
		local Quests = Configuration and Configuration:FindFirstChild("Quests")

		if Quests then
			if Quests:FindFirstChild(QuestName) then
				return Giver, QuestName
			end

			if MonName then
				for _, Quest in ipairs(Quests:GetChildren()) do
					if Quest:FindFirstChild(MonName) then
						return Giver, Quest.Name
					end
				end
			end
		end
	end
	return nil
end

local ClickSignals = { "MouseButton1Click", "MouseButton1Down", "MouseButton1Up", "Activated" }

local function FireButton(Button)
	if not Button then
		return false
	end

	local Fired = false

	if getconnections then
		for _, SignalName in ipairs(ClickSignals) do
			local Ok, Connections = pcall(function()
				return getconnections(Button[SignalName])
			end)

			if Ok and Connections then
				for _, Connection in ipairs(Connections) do
					if pcall(function()
						Connection:Fire()
					end) then
						Fired = true
					end
				end
			end
		end
	end

	if not Fired and firesignal then
		for _, SignalName in ipairs(ClickSignals) do
			pcall(function()
				firesignal(Button[SignalName])
				Fired = true
			end)
		end
	end

	if not Fired then
		pcall(function()
			local Inset = game:GetService("GuiService"):GetGuiInset()
			local Center = Button.AbsolutePosition + (Button.AbsoluteSize / 2) + Inset

			local VIM = game:GetService("VirtualInputManager")
			VIM:SendMouseButtonEvent(Center.X, Center.Y, 0, true, game, 1)
			task.wait(0.05)
			VIM:SendMouseButtonEvent(Center.X, Center.Y, 0, false, game, 1)
			Fired = true
		end)
	end

	if not Fired then
		pcall(function()
			local VirtualUser = game:GetService("VirtualUser")
			local Inset = game:GetService("GuiService"):GetGuiInset()
			local Center = Button.AbsolutePosition + (Button.AbsoluteSize / 2) + Inset

			VirtualUser:MoveMouse(Center)
			VirtualUser:Button1Down(Center)
			task.wait(0.05)
			VirtualUser:Button1Up(Center)
			Fired = true
		end)
	end

	return Fired
end

function FirePrompt(Prompt)
	if not Prompt then
		return false
	end

	pcall(function()
		Prompt.Enabled = true
		Prompt.HoldDuration = 0
		Prompt.RequiresLineOfSight = false

		if Prompt.MaxActivationDistance < 30 then
			Prompt.MaxActivationDistance = 30
		end
	end)

	if fireproximityprompt and pcall(fireproximityprompt, Prompt) then
		return true
	end

	return pcall(function()
		Prompt:InputHoldBegin()
		task.wait(0.05)
		Prompt:InputHoldEnd()
	end)
end

function CancelQuest()
	if not GetActiveQuest() then
		return true
	end

	local QuestGui = GetQuestGui()
	local MainFrame = QuestGui and QuestGui:FindFirstChild("MainFrame")
	local CloseButton = MainFrame and MainFrame:FindFirstChild("CloseButton")

	if CloseButton then
		local WasVisible = MainFrame.Visible
		MainFrame.Visible = true
		FireButton(CloseButton)

		local Deadline = tick() + 1
		while tick() < Deadline do
			if not GetActiveQuest() then
				return true
			end
			task.wait(0.05)
		end

		MainFrame.Visible = WasVisible
	end

	return not GetActiveQuest()
end

function AcceptQuest(Entry)
	local QuestGui = GetQuestGui()
	local QuestFunction = QuestGui and QuestGui:FindFirstChild("QuestFunction")
	if not QuestFunction then
		return false
	end

	LockCFrame = nil

	local Giver, RealQuestName = FindQuestGiver(Entry.QuestName, Entry.MonName)

	if not Giver then
		local Spot = Entry.WaitPOS or Entry.MonPOS
		if not Spot then
			return false
		end

		TravelTo(CFrame.new(Spot + Vector3.new(0, 20, 0)), 25)

		local Deadline = tick() + 4
		repeat
			task.wait(0.1)
			Giver, RealQuestName = FindQuestGiver(Entry.QuestName, Entry.MonName)
		until Giver or tick() > Deadline

		if not Giver then
			return false
		end
	end

	local function Invoke()
		local Result = nil
		pcall(function()
			Result = QuestFunction:InvokeServer(Giver, RealQuestName)
		end)
		return Result == true
	end

	if Invoke() then
		return true
	end

	task.wait(0.15)
	return Invoke()
end

BossQuest = { Name = nil, CancelTried = false, Fails = 0, BlockedAt = 0 }

function ResetBossQuest()
	BossQuest.Name = nil
	BossQuest.CancelTried = false
	BossQuest.Fails = 0
	BossQuest.BlockedAt = 0
end

function KeepBossQuest(MonName)
	if getgenv().Settings.AutoBossQuest ~= true or not MonName then
		return false
	end

	local Entry = FindEntryByMob(MonName)
	if not Entry then
		return false
	end

	if BossQuest.Name ~= MonName then
		BossQuest.Name = MonName
		BossQuest.CancelTried = false
		BossQuest.Fails = 0
		BossQuest.BlockedAt = 0
	end

	if not GetActiveQuest() then
		BossQuest.CancelTried = false

		if BossQuest.BlockedAt > 0 and tick() - BossQuest.BlockedAt >= VenuzFarm.AcceptRetryTime then
			BossQuest.Fails = 0
			BossQuest.BlockedAt = 0
		end

		if BossQuest.Fails >= VenuzFarm.MaxAcceptTries then
			return false
		end

		if AcceptQuest(Entry) then
			BossQuest.Fails = 0
			BossQuest.BlockedAt = 0
		else
			BossQuest.Fails = BossQuest.Fails + 1
			if BossQuest.Fails >= VenuzFarm.MaxAcceptTries then
				BossQuest.BlockedAt = tick()
			end
			task.wait(0.2)
		end

		return true
	end

	if not QuestMatches(Entry) and not BossQuest.CancelTried then
		BossQuest.CancelTried = true
		if CancelQuest() then
			return true
		end
	end

	return false
end

MobNameCache = setmetatable({}, { __mode = "k" })

function GetMobName(Mob)
	local Cached = MobNameCache[Mob]
	if Cached then
		return Cached
	end

	local Nickname = Mob:GetAttribute("Nickname")
	if Nickname and Nickname ~= "" then
		MobNameCache[Mob] = Nickname
		return Nickname
	end

	local NPCName = Mob:FindFirstChild("NPCName")
	if NPCName and NPCName.Value ~= "" then
		MobNameCache[Mob] = NPCName.Value
		return NPCName.Value
	end

	return Mob.Name
end

function IsMobDead(Mob)
	if not Mob or not Mob.Parent then
		return true
	end

	local Humanoid = Mob:FindFirstChildOfClass("Humanoid")
	if not Humanoid then
		return true
	end

	return Humanoid.Health <= 0
end

function ByDistance(A, B)
	return A.Distance < B.Distance
end

function FindMobs(MonName, Origin, Radius)
	local List = {}

	local Pattern = "^" .. MonName .. "%d*$"
	local RadiusSquared = Radius and (Radius * Radius) or nil

	for _, Entry in ipairs(IterNPCs()) do
		local Mob, MobRoot, Humanoid = Entry.Mob, Entry.Root, Entry.Humanoid

		if GetMobName(Mob) == MonName or string.match(Entry.ModelName or Mob.Name, Pattern) ~= nil then
			local Position = MobRoot.Position
			local Squared = 0

			if Origin then
				local DX, DY, DZ = Position.X - Origin.X, Position.Y - Origin.Y, Position.Z - Origin.Z
				Squared = DX * DX + DY * DY + DZ * DZ
			end

			if not RadiusSquared or Squared <= RadiusSquared then
				local Health = Humanoid.Health

				List[#List + 1] = {
					Mob = Mob,
					Root = MobRoot,
					Position = Position,
					Humanoid = Humanoid,
					Distance = Origin and math.sqrt(Squared) or 0,
					Health = Health,
					FullHealth = Health >= Humanoid.MaxHealth,
				}
			end
		end
	end

	table.sort(List, ByDistance)

	return List
end

local TaggedMobs = {}
local CurrentTag = nil
local TagDeadline = 0
local TagHoldTime = 0.6

function ResetTags()
	table.clear(TaggedMobs)
	CurrentTag = nil
	TagDeadline = 0
end

function PickTarget(List)
	for _, Data in ipairs(List) do
		if Data.FullHealth and not TaggedMobs[Data.Mob] then
			return Data, true
		end
	end

	local Weakest = nil
	for _, Data in ipairs(List) do
		if not Weakest or Data.Health < Weakest.Health then
			Weakest = Data
		end
	end

	return Weakest, false
end

local ClusterPositions = {}

function PickCluster(List, Radius)
	local Total = #List
	if Total == 0 then
		return nil, 0, nil
	end

	local Positions = ClusterPositions
	table.clear(Positions)

	for Index = 1, Total do
		local Data = List[Index]
		Positions[Index] = Data.Position or Data.Root.Position
	end

	local RadiusSquared = Radius * Radius
	local Best, BestCount, BestCenter = nil, 0, nil

	for Index = 1, Total do
		local Lead = Positions[Index]
		local LeadX, LeadY, LeadZ = Lead.X, Lead.Y, Lead.Z
		local Sum, Count = Vector3.zero, 0

		for Other = 1, Total do
			local Point = Positions[Other]
			local DX, DY, DZ = Point.X - LeadX, Point.Y - LeadY, Point.Z - LeadZ

			if DX * DX + DY * DY + DZ * DZ <= RadiusSquared then
				Sum = Sum + Point
				Count = Count + 1
			end
		end

		if Count > BestCount then
			Best, BestCount, BestCenter = List[Index], Count, Sum / Count
		end
	end

	return Best, BestCount, BestCenter
end

function FindMob(MonName)
	local Root = GetRoot()
	local List = FindMobs(MonName, Root and Root.Position, nil)
	local Closest = List[1]
	return Closest and Closest.Mob or nil
end

function FindFallbackTarget(BossEntry)
	if not BossEntry.Level then
		return nil, nil
	end

	local BossSea = SeaOfEntry(BossEntry)
	local Best = nil

	for _, Item in ipairs(getgenv().LevelConfig) do
		local ItemSea = SeaOfEntry(Item)

		if ItemSea == BossSea and Item.Level < BossEntry.Level and not IsBoss(Item) then
			if not Best or Item.Level > Best.Level then
				Best = Item
			end
		end
	end

	if not Best then
		return nil, nil
	end

	return Best, FindMob(Best.MonName)
end

local AttackDirections = {
	["Over"] = Vector3.new(0, 1, 0),
	["Below"] = Vector3.new(0, -1, 0),
	["Behind"] = Vector3.new(0, 0, 1),
}

local AttackPositions = { "Over", "Below", "Behind" }

local function BuildStandCFrame(MobCFrame, Distance)
	local Setting = getgenv().Settings.AutoFarmLevel
	local Vector = AttackDirections[Setting.AttackPosition] or AttackDirections.Over
	local Position = (MobCFrame * CFrame.new(Vector * Distance)).Position
	local Focus = MobCFrame.Position
	local Direction = Focus - Position

	if Direction.Magnitude < 0.1 then
		return CFrame.new(Position)
	end

	local Up = Vector3.new(0, 1, 0)
	if math.abs(Direction.Unit.Y) > 0.99 then
		Up = MobCFrame.LookVector
	end

	return CFrame.lookAt(Position, Focus, Up)
end

function GetAttackCFrame(MobCFrame)
	return BuildStandCFrame(MobCFrame, getgenv().Settings.AutoFarmLevel.Distance)
end

local DodgeHeight = 25
local ComboHits = 5
local DodgeTime = 1.2

function GetDodgeCFrame(MobCFrame)
	return BuildStandCFrame(MobCFrame, getgenv().Settings.AutoFarmLevel.Distance + DodgeHeight)
end

function IsBoss(Entry, Mob)
	if Entry.IsBoss then
		return true
	end
	if string.find(Entry.MonName, "Boss") then
		return true
	end
	return Mob ~= nil and string.find(GetMobName(Mob), "Boss") ~= nil
end

local PlatformPart = nil
local RenderBound = false

local PlatformThickness = 1
local PlatformSize = Vector3.new(8, PlatformThickness, 8)

function DestroyPlatform()
	if PlatformPart then
		pcall(function()
			PlatformPart:Destroy()
		end)
		PlatformPart = nil
	end
end

local function GetFootOffset(Humanoid, Root)
	if Humanoid.RigType == Enum.HumanoidRigType.R6 then
		return 3
	end
	return Humanoid.HipHeight + (Root.Size.Y * 0.5)
end

local function UpdatePlatform(Humanoid, Root)
	if not PlatformPart or not PlatformPart.Parent then
		DestroyPlatform()

		local Part = Instance.new("Part")
		Part.Name = "Venuz_Platform"
		Part.Size = PlatformSize
		Part.Anchored = true
		Part.CanCollide = false
		Part.CanQuery = false
		Part.CanTouch = false
		Part.Transparency = 1
		Part.Material = Enum.Material.Neon
		Part.Color = Color3.fromRGB(120, 170, 255)
		Part.TopSurface = Enum.SurfaceType.Smooth
		Part.BottomSurface = Enum.SurfaceType.Smooth
		Part.Parent = workspace
		PlatformPart = Part
	end

	local FootY = Root.Position.Y - GetFootOffset(Humanoid, Root)
	PlatformPart.CFrame = CFrame.new(Root.Position.X, FootY - (PlatformThickness * 0.5), Root.Position.Z)
end

WaterDropIn = 60

do
	local WaterList, WaterListAt = nil, 0

	local WaterClearance = 20

	local function WaterParts()
		local Now = os.clock()
		if WaterList and (Now - WaterListAt) < 10 then
			return WaterList
		end

		local List = {}

		local function Add(Part)
			if not (Part and Part:IsA("BasePart")) then
				return
			end

			local Frame = Part.CFrame
			local Half = Part.Size * 0.5
			local Reach = math.abs(Frame.RightVector.Y) * Half.X
				+ math.abs(Frame.UpVector.Y) * Half.Y
				+ math.abs(Frame.LookVector.Y) * Half.Z

			table.insert(List, {
				Inverse = Frame:Inverse(),
				HalfX = Half.X,
				HalfZ = Half.Z,
				Top = Part.Position.Y + Reach,
			})
		end

		local Logic = workspace:FindFirstChild("Logic")
		local Water = Logic and Logic:FindFirstChild("Water")
		local Folder = Water and Water:FindFirstChild("Water")

		if Folder then
			Add(Folder)

			for _, Part in ipairs(Folder:GetDescendants()) do
				Add(Part)
			end
		end

		WaterList = List
		WaterListAt = Now
		return List
	end

	function CruiseHeight(From, To)
		local Parts = WaterParts()
		if #Parts == 0 then
			return nil
		end

		local Distance = (To - From).Magnitude
		local Samples = math.clamp(math.ceil(Distance / 150), 1, 60)
		local Top = nil

		for Index = 0, Samples do
			local Point = From:Lerp(To, Index / Samples)

			for _, Slab in ipairs(Parts) do
				if not Top or Slab.Top > Top then
					local Local = Slab.Inverse * Point
					if math.abs(Local.X) <= Slab.HalfX and math.abs(Local.Z) <= Slab.HalfZ then
						Top = Slab.Top
					end
				end
			end
		end

		if not Top then
			return nil
		end

		return Top + WaterClearance
	end
end

local function OnStep(Delta)
	local Character = GetCharacter()
	local Root = GetRoot()
	local Humanoid = GetHumanoid()

	if not Character or not Root or not Humanoid or Humanoid.Health <= 0 then
		return
	end

	NoclipCharacter(Character)

	if MoveTarget then
		local Origin = Root.Position
		local Goal = MoveTarget.Position

		local Climbing = false

		if FlyCruiseY then
			local Flat = (Vector3.new(Goal.X, 0, Goal.Z) - Vector3.new(Origin.X, 0, Origin.Z)).Magnitude

			if Flat > WaterDropIn then
				if Origin.Y < FlyCruiseY - 5 then
					Climbing = true
					Goal = Vector3.new(Origin.X, FlyCruiseY, Origin.Z)
				else
					Goal = Vector3.new(Goal.X, math.max(Goal.Y, FlyCruiseY), Goal.Z)
				end
			end
		end

		local Offset = Goal - Origin
		local Remaining = Offset.Magnitude

		local Speed = getgenv().Settings.AutoFarmLevel.TweenSpeed
		local Step = math.min(Speed * Delta, MaxStep)

		HoldCFrame = nil

		if not Climbing and (Remaining <= Step or Remaining < 1) then
			Root.CFrame = MoveTarget
			Root.AssemblyLinearVelocity = Vector3.zero

			LockCFrame = MoveTarget
			MoveTarget = nil
			MoveDone = true
		else
			local Direction = Offset.Unit
			local NextPos = Origin + Direction * Step

			if Climbing then
				Root.CFrame = CFrame.new(NextPos) * (Root.CFrame - Root.CFrame.Position)
			else
				Root.CFrame = CFrame.lookAt(NextPos, NextPos + Direction)
			end

			Root.AssemblyLinearVelocity = Vector3.zero
			Root.AssemblyAngularVelocity = Vector3.zero
		end

		SetGroundState(true)
		UpdatePlatform(Humanoid, Root)
		return
	end

	if LockCFrame then
		HoldCFrame = nil
		Root.CFrame = LockCFrame
		Root.AssemblyLinearVelocity = Vector3.zero
		Root.AssemblyAngularVelocity = Vector3.zero
		SetGroundState(true)
		UpdatePlatform(Humanoid, Root)
	else
		if not HoldCFrame then
			HoldCFrame = Root.CFrame
		end

		Root.CFrame = HoldCFrame
		Root.AssemblyLinearVelocity = Vector3.zero
		Root.AssemblyAngularVelocity = Vector3.zero
		SetGroundState(true)
		UpdatePlatform(Humanoid, Root)
	end
end

function StartRender()
	if not IsCurrentInstance() then
		return
	end

	if RenderBound then
		return
	end
	RenderBound = true
	RunService:BindToRenderStep("Venuz_Farm", Enum.RenderPriority.Camera.Value - 1, OnStep)
end

function StopRender()
	if not RenderBound then
		return
	end
	RenderBound = false

	if not IsCurrentInstance() then
		LockCFrame = nil
		MoveTarget = nil
		FlyCruiseY = nil
		HoldCFrame = nil
		return
	end
	LockCFrame = nil
	MoveTarget = nil
	FlyCruiseY = nil
	HoldCFrame = nil
	SetGroundState(false)
	DestroyPlatform()
	pcall(function()
		RunService:UnbindFromRenderStep("Venuz_Farm")
	end)
end

VenuzRun = { Active = {}, Idle = {}, Owner = nil, Level = 0, Until = 0, Epoch = 0, MobEpoch = 0, BossEpoch = 0 }

function ClaimDrive(Name, Level)
	if not IsCurrentInstance() then
		return false
	end

	local Now = tick()

	if VenuzRun.Owner == Name then
		VenuzRun.Level, VenuzRun.Until = Level, Now + 1
		VenuzRun.Idle[Name] = nil
		return true
	end

	local Free = VenuzRun.Owner == nil or Now > VenuzRun.Until
	local Outranks

	if VenuzRun.Owner and table.find(BossModules, Name) and table.find(BossModules, VenuzRun.Owner) then
		Outranks = PriorityOf(Name) < PriorityOf(VenuzRun.Owner)
	else
		Outranks = Level > VenuzRun.Level or (Level == VenuzRun.Level and PriorityOf(Name) < PriorityOf(VenuzRun.Owner))
	end

	if Free or Outranks then
		VenuzRun.Owner, VenuzRun.Level, VenuzRun.Until = Name, Level, Now + 1
		VenuzRun.Idle[Name] = nil
		return true
	end

	return false
end

function ReleaseDrive(Name)
	if VenuzRun.Owner == Name then
		VenuzRun.Owner, VenuzRun.Level, VenuzRun.Until = nil, 0, 0
		return true
	end
	return false
end

function HandBackDrive()
	VenuzRun.Epoch = VenuzRun.Epoch + 1
	LockCFrame = nil
	HoldCFrame = nil
	CancelTween()
end

function FarmerBusy()
	local Active = VenuzRun.Active
	return (Active.Level or Active.Mob or Active.Boss or Active.Sea3) and true or false
end

function BossDriving()
	local Owner = VenuzRun.Owner

	return Owner ~= nil and tick() <= VenuzRun.Until and table.find(BossModules, Owner) ~= nil
end

function BeginRunner(Name)
	VenuzRun.Active[Name] = true
	VenuzRun.Idle[Name] = nil
	FarmRunning = true
	StartRender()
end

function IdleRunner(Name)
	local HadDrive = ReleaseDrive(Name)

	VenuzRun.Idle[Name] = true

	for Other in pairs(VenuzRun.Active) do
		if Other ~= Name and not VenuzRun.Idle[Other] then
			if HadDrive then
				HandBackDrive()
			end
			return
		end
	end

	LockCFrame = nil
	HoldCFrame = nil
	CancelTween()
	StopRender()
end

BossModules = {
	"Cthulhu",
	"Hydra",
	"Raijin",
	"Dough",
	"Dragon",
	"Zenith",
	"Saturn",
	"Enma",
	"Vault",
	"RedEmperor",
	"GhostShip",
	"Beast",
}

BossPriorityIndex = nil

function BossPriorityList()
	local Saved = getgenv().Settings.BossPriority
	local Order, Seen = {}, {}

	if type(Saved) == "table" then
		for _, Name in ipairs(Saved) do
			if type(Name) == "string" and not Seen[Name] and table.find(BossModules, Name) then
				Seen[Name] = true
				table.insert(Order, Name)
			end
		end
	end

	for _, Name in ipairs(BossModules) do
		if not Seen[Name] then
			Seen[Name] = true
			table.insert(Order, Name)
		end
	end

	getgenv().Settings.BossPriority = Order
	return Order
end

function InvalidateBossPriority()
	BossPriorityIndex = nil
end

VenuzHopTargets = {}

function RegisterHopTarget(Entry)
	VenuzHopTargets[Entry.Key] = Entry
end

function HopTargetList()
	local List = {}

	for _, Name in ipairs(BossModules) do
		local Entry = VenuzHopTargets[Name]
		if Entry then
			table.insert(List, Entry)
		end
	end

	return List
end

function PriorityOf(Name)
	if not BossPriorityIndex then
		BossPriorityIndex = {}
		for Index, Boss in ipairs(BossPriorityList()) do
			BossPriorityIndex[Boss] = Index
		end
	end

	return BossPriorityIndex[Name] or 999
end

function StopAllBosses()
	for _, Name in ipairs(BossModules) do
		local Stop = VenuzToggle["Stop" .. Name]
		if Stop then
			pcall(Stop)
		end
	end
end

function StopDrivingBosses()
	for _, Name in ipairs(BossModules) do
		local Needs = VenuzToggle["Needs" .. Name]
		local Stop = VenuzToggle["Stop" .. Name]

		if Stop then
			local Driving = true
			if Needs then
				local Ok, Result = pcall(Needs)
				Driving = Ok and Result == true
			end

			if Driving then
				pcall(Stop)
			end
		end
	end
end

function EndRunner(Name)
	VenuzRun.Active[Name] = nil
	VenuzRun.Idle[Name] = nil
	local HadDrive = ReleaseDrive(Name)

	if next(VenuzRun.Active) == nil then
		FarmRunning = false
		CancelTween()
		StopRender()
		DestroyPlatform()
	elseif HadDrive then
		HandBackDrive()
	end
end

function TravelTo(Target, Threshold)
	local Root = GetRoot()
	if not Root then
		return false
	end

	if (Root.Position - Target.Position).Magnitude <= (Threshold or 25) then
		return Teleport(Target)
	end

	local Owner = VenuzRun.Owner

	LockCFrame = nil

	local Ok, Cruise = pcall(CruiseHeight, Root.Position, Target.Position)
	FlyCruiseY = Ok and Cruise or nil

	MoveTarget = Target
	MoveDone = false

	StartRender()

	local Deadline = tick() + 15
	while RenderBound and MoveTarget and not MoveDone and tick() < Deadline do
		if Owner then
			if VenuzRun.Owner ~= Owner then
				if MoveTarget == Target then
					MoveTarget = nil
					FlyCruiseY = nil
				end
				return false
			end

			VenuzRun.Until = tick() + 1
		end

		task.wait()
	end

	MoveTarget = nil
	FlyCruiseY = nil
	return true
end

function GetWeaponList()
	local List = {}
	local Character = GetCharacter()

	local Backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	if Backpack then
		for _, Tool in ipairs(Backpack:GetChildren()) do
			if Tool:IsA("Tool") then
				table.insert(List, Tool.Name)
			end
		end
	end

	if Character then
		for _, Tool in ipairs(Character:GetChildren()) do
			if Tool:IsA("Tool") then
				table.insert(List, Tool.Name)
			end
		end
	end

	table.sort(List)
	return List
end

WeaponModes = { "Melee", "Sword", "Fruit" }

function WeaponMode(Value)
	for _, Name in ipairs(WeaponModes) do
		if Name == Value then
			return Name
		end
	end

	return ""
end

function PlayerDataString(Name, Default)
	local Data = LocalPlayer:FindFirstChild("PlayerData")
	local Object = Data and Data:FindFirstChild(Name)
	if Object and Object:IsA("ValueBase") and type(Object.Value) == "string" then
		return Object.Value
	end

	return Default
end

function ToolNamed(Name)
	if type(Name) ~= "string" or Name == "" then
		return nil
	end

	local Character = GetCharacter()
	local Found = Character and Character:FindFirstChild(Name)
	if Found and Found:IsA("Tool") then
		return Found
	end

	local Backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	Found = Backpack and Backpack:FindFirstChild(Name)
	if Found and Found:IsA("Tool") then
		return Found
	end

	return nil
end

NotWeaponNames = {
	["Divine Spark"] = true,
	["Mirror Fragment"] = true,
	["Poneglyph Scroll"] = true,
	["Fork"] = true,
	["Lava Ore"] = true,
	["Lava Key"] = true,
}

NotWeaponWords = {
	"spark",
	"fragment",
	"scroll",
	"trumpet",
	"horn",
	"fishing rod",
	"relic",
	"chest",
	"doughnut",
}

FishPrefixes = { "Common", "Rare", "Legendary", "Mythical" }

function IsWeaponTool(Name)
	if type(Name) ~= "string" or Name == "" then
		return false
	end

	if NotWeaponNames[Name] then
		return false
	end

	local Lower = string.lower(Name)
	for _, Word in ipairs(NotWeaponWords) do
		if string.find(Lower, Word, 1, true) then
			return false
		end
	end

	for _, Prefix in ipairs(FishPrefixes) do
		if string.sub(Name, 1, #Prefix + 1) == Prefix .. " " then
			return false
		end
	end

	local Tool = ToolNamed(Name)
	if Tool and Tool:FindFirstChild("Droppable") then
		local Ok, Power = pcall(Tool.GetAttribute, Tool, "FruitPower")
		if not (Ok and Power == true) then
			return false
		end
	end

	return true
end

function WeaponNameFor(Mode)
	local Melee = PlayerDataString("FightingStyle", "Combat")
	local Fruit = PlayerDataString("CurrentSuperPower", "")
	local Sword = PlayerDataString("CurrentSword", "")

	if Mode == "Melee" then
		if ToolNamed(Melee) then
			return Melee
		end
		return ToolNamed("Combat") and "Combat" or ""
	end

	if Mode == "Fruit" then
		if ToolNamed(Fruit) then
			return Fruit
		end
		for _, Name in ipairs(GetWeaponList()) do
			if Name:find("Fruit") and IsWeaponTool(Name) then
				return Name
			end
		end
		return ""
	end

	if Mode == "Sword" then
		if ToolNamed(Sword) then
			return Sword
		end
		for _, Name in ipairs(GetWeaponList()) do
			if Name ~= Melee and Name ~= Fruit and Name ~= "Combat" and IsWeaponTool(Name) then
				return Name
			end
		end
		return ""
	end

	return ""
end

function FarmWeaponMode()
	return WeaponMode(getgenv().Settings.AutoFarmLevel.Weapon)
end

function FarmWeaponName()
	return WeaponNameFor(FarmWeaponMode())
end

WeaponEquipAt = {}

function EquipWeapon(WeaponName)
	if not WeaponName or WeaponName == "" then
		return nil
	end

	local Character = GetCharacter()
	local Humanoid = GetHumanoid()
	if not Character or not Humanoid then
		return nil
	end

	local Equipped = Character:FindFirstChild(WeaponName)
	if Equipped and Equipped:IsA("Tool") then
		WeaponEquipAt[WeaponName] = nil
		return Equipped
	end

	local Now = tick()
	if Now - (WeaponEquipAt[WeaponName] or 0) < 0.35 then
		return nil
	end

	local Backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	local Tool = Backpack and Backpack:FindFirstChild(WeaponName)
	if Tool and Tool:IsA("Tool") then
		WeaponEquipAt[WeaponName] = Now
		Humanoid:EquipTool(Tool)
		return Character:FindFirstChild(WeaponName)
	end

	return nil
end

function HasWeaponPicked()
	return FarmWeaponMode() ~= ""
end

function BossWeaponMode()
	return WeaponMode(getgenv().Settings.AutoFarmLevel.BossWeapon)
end

function BossWeaponName()
	return WeaponNameFor(BossWeaponMode())
end

function HasBossWeaponPicked()
	return BossWeaponMode() ~= ""
end

function WeaponFor(Owner)
	if Owner then
		for _, Name in ipairs(BossModules) do
			if Name == Owner then
				return BossWeaponName()
			end
		end
	end

	return FarmWeaponName()
end

LocalPlayer.CharacterAdded:Connect(function(Character)
	task.spawn(function()
		Character:WaitForChild("Humanoid", 10)

		local Deadline = tick() + 10
		while tick() < Deadline do
			if not HasWeaponPicked() then
				return
			end

			if EquipWeapon(FarmWeaponName()) then
				return
			end

			task.wait(0.25)
		end
	end)
end)

function WeaponWarning()
	if getgenv().ConfigurationTable.Language == "Thai" then
		return "เลือกอาวุธก่อน (แท็บ ตั้งค่าการฟาร์ม > อาวุธ > เลือกอาวุธ)"
	end
	return "Select a weapon first (Farm Settings tab > Weapon > Select Weapon)."
end

function BossWeaponWarning()
	if getgenv().ConfigurationTable.Language == "Thai" then
		return "เลือกอาวุธสำหรับบอสก่อน (แท็บ ตั้งค่าการฟาร์ม > อาวุธ > เลือกอาวุธสำหรับบอส)"
	end
	return "Select a boss weapon first (Farm Settings tab > Weapon > Select Boss Weapon)."
end

function SetToggleValue(Toggle, Value)
	if type(Toggle) ~= "table" then
		return false
	end

	for _, Name in ipairs({ "SetValue", "Set" }) do
		local Found, Method = pcall(function()
			return Toggle[Name]
		end)

		if Found and type(Method) == "function" then
			pcall(Method, Toggle, Value)
			return true
		end
	end

	return false
end

function RequireWeapon(Label, Toggle)
	if HasWeaponPicked() then
		return true
	end

	WindUI:Notify({
		Title = Label or "Auto Farm",
		Content = WeaponWarning(),
		Duration = 6,
	})

	if Toggle then
		SetToggleValue(Toggle, false)
	end

	return false
end

function RequireBossWeapon(Label, ...)
	if HasBossWeaponPicked() then
		return true
	end

	WindUI:Notify({
		Title = Label or "Boss",
		Content = BossWeaponWarning(),
		Duration = 6,
	})

	for Index = 1, select("#", ...) do
		SetToggleValue(select(Index, ...), false)
	end

	return false
end

function AttackWith(Tool, MobRoot)
	if not Tool or not Tool.Parent then
		return
	end

	local SwordServer = Tool:FindFirstChild("SwordServer")
	local UpdateMousePosition = SwordServer and SwordServer:FindFirstChild("UpdateMousePosition")
	if UpdateMousePosition and MobRoot then
		pcall(function()
			UpdateMousePosition:FireServer(MobRoot.Position)
		end)
	end

	pcall(function()
		Tool:Activate()
	end)
end

VenuzGrind = { Last = {} }

function FarmMobsAround(Owner, Origin, Radius)
	local Root = GetRoot()
	if not Root then
		return false
	end

	local Alive = {}

	local Here = Root.Position
	local RangeSquared = (Radius or 300) ^ 2

	for _, Entry in ipairs(IterNPCs()) do
		local MobRoot, Humanoid = Entry.Root, Entry.Humanoid
		local Position = MobRoot.Position

		local InRange = true
		if Origin then
			local DX, DY, DZ = Position.X - Origin.X, Position.Y - Origin.Y, Position.Z - Origin.Z
			InRange = (DX * DX + DY * DY + DZ * DZ) <= RangeSquared
		end

		if InRange then
			local Health = Humanoid.Health

			Alive[#Alive + 1] = {
				Mob = Entry.Mob,
				Root = MobRoot,
				Position = Position,
				Humanoid = Humanoid,
				Distance = (Position - Here).Magnitude,
				Health = Health,
				FullHealth = Health >= Humanoid.MaxHealth,
			}
		end
	end

	if #Alive == 0 then
		return false
	end

	table.sort(Alive, ByDistance)

	local Closest = Alive[1]
	local MobRoot = Closest.Root
	local Focus = Closest.Position
	local Anchor = nil

	local AggroSquared = VenuzFarm.AggroRadius * VenuzFarm.AggroRadius
	local Nearby = {}

	for _, Data in ipairs(Alive) do
		local Position = Data.Position
		local DX, DY, DZ = Position.X - Focus.X, Position.Y - Focus.Y, Position.Z - Focus.Z

		if DX * DX + DY * DY + DZ * DZ <= AggroSquared then
			Nearby[#Nearby + 1] = Data
		end
	end

	for Tagged in pairs(TaggedMobs) do
		if not Tagged.Parent then
			TaggedMobs[Tagged] = nil
		end
	end

	local Lead, Count, Center = PickCluster(Nearby, VenuzFarm.PackRadius)

	if Lead and Count > 1 and Center then
		MobRoot = Lead.Root
		Anchor = CFrame.new(Center)
		CurrentTag = nil
	else
		local Picked, Tagging = PickTarget(Nearby)
		if Picked then
			MobRoot = Picked.Root
		end

		if Tagging and Picked then
			if CurrentTag ~= Picked.Mob then
				CurrentTag = Picked.Mob
				TagDeadline = tick() + TagHoldTime
			elseif tick() >= TagDeadline then
				TaggedMobs[Picked.Mob] = true
				CurrentTag = nil
			end
		else
			CurrentTag = nil
		end
	end

	local Stand = GetAttackCFrame(Anchor or MobRoot.CFrame)

	if (Here - Stand.Position).Magnitude > 30 then
		LockCFrame = nil
		TravelTo(Stand, 30)
		return true
	end

	CancelTween()
	LockCFrame = Stand

	local Now = tick()
	if Now - (VenuzGrind.Last[Owner] or 0) >= VenuzFarm.AttackDelay then
		VenuzGrind.Last[Owner] = Now
		task.spawn(AttackWith, EquipWeapon(WeaponFor(Owner)), MobRoot)
	end

	return true
end

function BossSpotFor(Name)
	local Spots = getgenv().Settings.AutoFarmBoss and getgenv().Settings.AutoFarmBoss.Spots
	local Saved = type(Spots) == "table" and Spots[Name] or nil

	if type(Saved) == "table" and #Saved == 3 then
		return Vector3.new(Saved[1], Saved[2], Saved[3])
	end

	return nil
end

function RememberBossSpot(Name, Position)
	local Settings = getgenv().Settings.AutoFarmBoss
	if type(Settings) ~= "table" then
		return
	end

	if type(Settings.Spots) ~= "table" then
		Settings.Spots = {}
	end

	local Saved = Settings.Spots[Name]
	if type(Saved) == "table" and #Saved == 3 then
		if (Vector3.new(Saved[1], Saved[2], Saved[3]) - Position).Magnitude < 20 then
			return
		end
	end

	Settings.Spots[Name] = { Position.X, Position.Y, Position.Z }
	QueueSave()
end

BossWaitHeight = 25
BossWaitRange = 400
BossWaitRadius = 300

-- Same waiting behaviour the Auto Farm Boss module uses: hover over the spot and
-- grind the mobs around it while the target is dead.
-- BossOnly skips the mob grinding, so the runner only ever hits its boss.
function BossWaitAt(Owner, Spot, Radius, BossOnly)
	local Root = GetRoot()
	if not Root then
		return "None"
	end

	StartRender()

	local Wait = CFrame.new(Spot + Vector3.new(0, BossWaitHeight, 0))

	if (Root.Position - Wait.Position).Magnitude > BossWaitRange then
		LockCFrame = nil
		TravelTo(Wait, BossWaitHeight)
		return "Flying"
	end

	if not BossOnly and FarmMobsAround(Owner, Spot, Radius or BossWaitRadius) then
		return "Farming"
	end

	LockCFrame = Wait
	return "Waiting"
end

local SweepStep = 0
local SweepRing = 400
local SweepRings = 3
local SweepPoints = 8

function SweepForMob(MonName, Center)
	SweepStep = SweepStep + 1

	local Angle = (SweepStep % SweepPoints) * (math.pi * 2 / SweepPoints)
	local Ring = (math.floor(SweepStep / SweepPoints) % SweepRings) + 1
	local Offset = Vector3.new(math.cos(Angle), 0, math.sin(Angle)) * (SweepRing * Ring)
	local Spot = Center + Offset + Vector3.new(0, 40, 0)

	TravelTo(CFrame.new(Spot), 25)
	task.wait(0.4)

	return FindMob(MonName)
end

local ArriveRadius = 40

function ArrivedAtSpot(Entry)
	local Spot = Entry.WaitPOS or Entry.MonPOS
	if not Spot then
		return true
	end

	local Root = GetRoot()
	if not Root then
		return false
	end

	return (Root.Position - (Spot + Vector3.new(0, 20, 0))).Magnitude <= ArriveRadius
end

VenuzFarm = {
	Entry = nil,
	Until = 0,
	Hold = 45,
	Mob = nil,

	Primed = false,
	PrimeUntil = 0,
	DriveEpoch = 0,

	PrimeTime = 1.5,

	FarmLoop = nil,
	LastAttack = 0,
	AttackDelay = 0.15,
	AggroRadius = 120,
	PackRadius = 20,
	SwingTime = 0.34,
	CancelTried = false,
	ComboStart = 0,
	DodgeUntil = 0,
	LastTargetName = nil,

	BossMissingSince = 0,
	BossWaitTime = 5,
	BossCancelTried = false,

	AcceptFails = 0,
	MaxAcceptTries = 3,
	AcceptRetryTime = 30,
	AcceptBlockedAt = 0,
}

local AutoFarmSection = Automatic:Section({ Title = "tr:AutoFarmSection", Icon = "sword", Opened = true })

AutoFarmSection:Toggle({
	Title = "tr:AutoQuestAccept",
	Path = "AutoFarmLevel.AutoQuest",
	Desc = "tr:AutoQuestAcceptDesc",
	Value = getgenv().Settings.AutoFarmLevel.AutoQuest,
	Icon = "check",
	Callback = function(Value)
		getgenv().Settings.AutoFarmLevel.AutoQuest = Value
		SaveSetting()
	end,
})

VenuzToggle.AutoFarm = function(Value)
	if Value and not RequireWeapon("Auto Farm Level", VenuzToggle.FarmToggle) then
		getgenv().Settings.AutoFarmLevel.Enabled = false
		SaveSetting()
		return
	end

	getgenv().Settings.AutoFarmLevel.Enabled = Value
	SaveSetting()

	if not Value then
		VenuzFarm.Running = false
		VenuzFarm.CancelTried = false
		VenuzFarm.ComboStart = 0
		VenuzFarm.DodgeUntil = 0
		VenuzFarm.BossMissingSince = 0
		VenuzFarm.BossCancelTried = false
		VenuzFarm.Entry = nil
		VenuzFarm.Until = 0
		VenuzFarm.Mob = nil
		VenuzFarm.Primed = false
		VenuzFarm.PrimeUntil = 0
		ResetTags()
		if VenuzFarm.FarmLoop then
			pcall(function()
				task.cancel(VenuzFarm.FarmLoop)
			end)
			VenuzFarm.FarmLoop = nil
		end
		EndRunner("Level")
		return
	end

	SetToggleValue(VenuzToggle.MobToggle, false)
	SetToggleValue(VenuzToggle.BossToggle, false)
	StopDrivingBosses()

	if VenuzFarm.Running then
		return
	end

	VenuzFarm.Running = true
	VenuzFarm.Primed = false
	VenuzFarm.PrimeUntil = 0
	VenuzFarm.DriveEpoch = VenuzRun.Epoch
	BeginRunner("Level")
	VenuzFarm.FarmLoop = task.spawn(function()
		while VenuzFarm.Running do
			task.wait()

			if not IsCurrentInstance() then
				VenuzFarm.Running = false
				EndRunner("Level")
				break
			end

			local Success = pcall(function()
				if not IsAlive() then
					LockCFrame = nil

					HoldCFrame = nil
					CancelTween()

					VenuzFarm.Entry = nil
					VenuzFarm.Mob = nil
					task.wait(1)
					return
				end

				if not VenuzRun.Active.Level then
					BeginRunner("Level")
				end

				if not ClaimDrive("Level", 1) then
					task.wait(0.3)
					return
				end

				StartRender()

				if VenuzFarm.DriveEpoch ~= VenuzRun.Epoch then
					VenuzFarm.DriveEpoch = VenuzRun.Epoch
					VenuzFarm.Primed = false
					VenuzFarm.PrimeUntil = 0
					VenuzFarm.Entry = nil
					VenuzFarm.Mob = nil
					VenuzFarm.Until = 0
					VenuzFarm.ComboStart = 0
					VenuzFarm.DodgeUntil = 0
					VenuzFarm.BossMissingSince = 0
					LockCFrame = nil
					HoldCFrame = nil
					CancelTween()
					ResetTags()
				end

				local Entry = CheckLevel(LevelValue.Value)
				if not Entry then
					task.wait(1)
					return
				end

				if not VenuzFarm.Primed then
					local Spot = Entry.WaitPOS or Entry.MonPOS

					if not Spot then
						VenuzFarm.Primed = true
					else
						local WaitCFrame = CFrame.new(Spot)
						local Root = GetRoot()

						if Root and (Root.Position - WaitCFrame.Position).Magnitude > 25 then
							LockCFrame = nil
							VenuzFarm.PrimeUntil = 0
							TravelTo(WaitCFrame, 25)
						else
							LockCFrame = WaitCFrame

							if FindMob(Entry.MonName) then
								VenuzFarm.Primed = true
								VenuzFarm.BossMissingSince = 0
							elseif VenuzFarm.PrimeUntil == 0 then
								VenuzFarm.PrimeUntil = tick() + VenuzFarm.PrimeTime
							elseif tick() >= VenuzFarm.PrimeUntil then
								VenuzFarm.Primed = true
								VenuzFarm.BossMissingSince = 0
							end
						end

						if not VenuzFarm.Primed then
							task.wait(0.15)
							return
						end
					end
				end

				local Mob = FindMob(Entry.MonName)
				local TargetEntry = Entry

				if not Mob and IsBoss(Entry) then
					if VenuzFarm.Entry and VenuzFarm.Mob and IsMobDead(VenuzFarm.Mob) then
						VenuzFarm.Entry = nil
						VenuzFarm.Mob = nil
						VenuzFarm.Until = 0
						VenuzFarm.BossMissingSince = 0
					end

					if VenuzFarm.Entry and tick() < VenuzFarm.Until then
						TargetEntry = VenuzFarm.Entry
						Mob = FindMob(VenuzFarm.Entry.MonName)

						if Mob then
							VenuzFarm.Mob = Mob
						end
					else
						VenuzFarm.Entry = nil
						VenuzFarm.Mob = nil

						if not ArrivedAtSpot(Entry) then
							VenuzFarm.BossMissingSince = 0
						elseif VenuzFarm.BossMissingSince == 0 then
							VenuzFarm.BossMissingSince = tick()
						end

						if
							VenuzFarm.BossMissingSince > 0
							and tick() - VenuzFarm.BossMissingSince >= VenuzFarm.BossWaitTime
						then
							if
								getgenv().Settings.AutoFarmLevel.AutoQuest
								and not VenuzFarm.BossCancelTried
								and QuestMatches(Entry)
							then
								VenuzFarm.BossCancelTried = true

								task.spawn(CancelQuest)
							end

							local Fallback, FoundMob = FindFallbackTarget(Entry)
							if Fallback then
								TargetEntry = Fallback
								Mob = FoundMob
								VenuzFarm.Entry = Fallback
								VenuzFarm.Mob = FoundMob
								VenuzFarm.Until = tick() + VenuzFarm.Hold
								VenuzFarm.BossMissingSince = 0
							end
						end
					end
				else
					VenuzFarm.BossMissingSince = 0
					VenuzFarm.BossCancelTried = false
					VenuzFarm.Entry = nil
					VenuzFarm.Mob = nil
				end

				local InFallback = VenuzFarm.Entry ~= nil and TargetEntry == VenuzFarm.Entry

				if TargetEntry.MonName ~= VenuzFarm.LastTargetName then
					VenuzFarm.LastTargetName = TargetEntry.MonName
					VenuzFarm.CancelTried = false
					VenuzFarm.ComboStart = 0
					VenuzFarm.DodgeUntil = 0
					VenuzFarm.AcceptFails = 0
					VenuzFarm.AcceptBlockedAt = 0
					ResetTags()
				end

				local Active = GetActiveQuest()

				if not Active then
					VenuzFarm.CancelTried = false

					if
						VenuzFarm.AcceptBlockedAt > 0
						and tick() - VenuzFarm.AcceptBlockedAt >= VenuzFarm.AcceptRetryTime
					then
						VenuzFarm.AcceptFails = 0
						VenuzFarm.AcceptBlockedAt = 0
					end

					local SkipAccept = (not Mob and IsBoss(TargetEntry))
						or VenuzFarm.AcceptFails >= VenuzFarm.MaxAcceptTries

					if getgenv().Settings.AutoFarmLevel.AutoQuest and not SkipAccept then
						if AcceptQuest(TargetEntry) then
							VenuzFarm.AcceptFails = 0
							VenuzFarm.AcceptBlockedAt = 0
						else
							VenuzFarm.AcceptFails = VenuzFarm.AcceptFails + 1
							if VenuzFarm.AcceptFails >= VenuzFarm.MaxAcceptTries then
								VenuzFarm.AcceptBlockedAt = tick()
							end
							task.wait(0.2)
						end
						return
					end
				elseif not QuestMatches(TargetEntry) then
					if getgenv().Settings.AutoFarmLevel.AutoQuest and not VenuzFarm.CancelTried then
						VenuzFarm.CancelTried = true
						if CancelQuest() then
							return
						end
					end

					if not InFallback then
						TargetEntry = FindEntryByMob(Active)
							or {
								MonName = Active,
								QuestName = Active,
								WaitPOS = Entry.WaitPOS,
								MonPOS = Entry.MonPOS,
							}
						Mob = FindMob(TargetEntry.MonName)
					end
				end

				if not Mob then
					VenuzFarm.ComboStart = 0
					VenuzFarm.DodgeUntil = 0

					local WaitPos = TargetEntry.WaitPOS or BossSpotFor(TargetEntry.MonName) or TargetEntry.MonPOS

					if WaitPos then
						local WaitCFrame = CFrame.new(WaitPos)
						local Root = GetRoot()

						if Root and (Root.Position - WaitCFrame.Position).Magnitude > 25 then
							LockCFrame = nil
							TravelTo(WaitCFrame, 25)
						else
							LockCFrame = WaitCFrame
						end
					else
						LockCFrame = nil
					end

					task.wait(0.15)
					return
				end

				local MobRoot = Mob:FindFirstChild("HumanoidRootPart")
				if not MobRoot then
					return
				end

				local Nearby = FindMobs(TargetEntry.MonName, MobRoot.Position, VenuzFarm.AggroRadius)

				for Tagged in pairs(TaggedMobs) do
					if not Tagged.Parent then
						TaggedMobs[Tagged] = nil
					end
				end

				local Setting = getgenv().Settings.AutoFarmLevel
				local Anchor = nil

				local Lead, Count, Center = PickCluster(Nearby, VenuzFarm.PackRadius)
				if Lead and Count > 1 and Center then
					Mob = Lead.Mob
					MobRoot = Lead.Root
					Anchor = CFrame.new(Center)
					CurrentTag = nil
				else
					local Picked, Tagging = PickTarget(Nearby)
					if Picked then
						Mob = Picked.Mob
						MobRoot = Picked.Root
					end

					if Tagging then
						if CurrentTag ~= Mob then
							CurrentTag = Mob
							TagDeadline = tick() + TagHoldTime
						elseif tick() >= TagDeadline then
							TaggedMobs[Mob] = true
							CurrentTag = nil
						end
					else
						CurrentTag = nil
					end
				end

				local Tool = EquipWeapon(FarmWeaponName())
				local Target = GetAttackCFrame(Anchor or MobRoot.CFrame)
				local Root = GetRoot()

				if Root and (Root.Position - Target.Position).Magnitude > 30 then
					LockCFrame = nil
					TravelTo(Target, 30)
					return
				end

				CancelTween()

				local BossFight = IsBoss(TargetEntry, Mob)

				if BossFight then
					RememberBossSpot(TargetEntry.MonName, MobRoot.Position)
				end

				if BossFight and tick() < VenuzFarm.DodgeUntil then
					LockCFrame = GetDodgeCFrame(MobRoot.CFrame)
					VenuzFarm.ComboStart = 0
					return
				end

				LockCFrame = Target

				if VenuzFarm.ComboStart == 0 then
					VenuzFarm.ComboStart = tick()
				end

				if tick() - VenuzFarm.LastAttack >= VenuzFarm.AttackDelay then
					VenuzFarm.LastAttack = tick()

					task.spawn(AttackWith, Tool, MobRoot)
				end

				if BossFight and tick() - VenuzFarm.ComboStart >= ComboHits * VenuzFarm.SwingTime then
					VenuzFarm.DodgeUntil = tick() + DodgeTime
					VenuzFarm.ComboStart = 0
				end
			end)

			if not Success then
				task.wait(0.25)
			end
		end
	end)
end

local AutoFarmToggle = AutoFarmSection:Toggle({
	Title = "tr:AutoFarmLevel",
	Path = "AutoFarmLevel.Enabled",
	Desc = "tr:AutoFarmLevelDesc",

	Value = getgenv().Settings.AutoFarmLevel.Enabled,
	Icon = "check",
	Callback = VenuzToggle.AutoFarm,
})

VenuzToggle.FarmToggle = AutoFarmToggle

VenuzSections = {
	Boss = Automatic:Section({ Title = "tr:BossFarmSection", Icon = "swords", Opened = true }),
	Mob = Automatic:Section({ Title = "tr:MobFarmSection", Icon = "crosshair", Opened = true }),
}

do
	local StatsEvent = game:GetService("ReplicatedStorage").Replication.ClientEvents:WaitForChild("Stats_Event")
	local Experience = PlayerData:WaitForChild("Experience")
	local PointsValue = Experience:WaitForChild("Points")

	local StatNames = { "Combat", "Defense", "Sword", "Fruit" }

	local function NormalizeStats(Value)
		local List = {}
		if type(Value) ~= "table" then
			if type(Value) == "string" and Value ~= "" then
				table.insert(List, Value)
			end
			return List
		end

		local Seen = {}
		for Key, Item in pairs(Value) do
			local Name = nil
			if type(Item) == "string" then
				Name = Item
			elseif Item == true and type(Key) == "string" then
				Name = Key
			end

			if Name and not Seen[Name] then
				Seen[Name] = true
				table.insert(List, Name)
			end
		end

		return List
	end

	local UpgradeRunning = false
	local UpgradeLoop = nil

	local AutoUpgradeSection =
		Automatic:Section({ Title = "tr:AutoUpgradeSection", Icon = "trending-up", Opened = true })

	AutoUpgradeSection:Dropdown({
		Title = "tr:SelectStats",
		Path = "AutoUpgradeStats.Stats",
		Desc = "tr:SelectStatsDesc",
		Multi = true,
		AllowNone = true,
		Values = StatNames,
		Value = NormalizeStats(getgenv().Settings.AutoUpgradeStats.Stats),
		Callback = function(Value)
			getgenv().Settings.AutoUpgradeStats.Stats = NormalizeList(Value)
			SaveSetting()
		end,
	})

	AutoUpgradeSection:Slider({
		Title = "tr:PointsPerUpgrade",
		Path = "AutoUpgradeStats.PointsPerUpgrade",
		Desc = "tr:PointsPerUpgradeDesc",
		Value = {
			Min = 1,
			Max = 100,
			Default = getgenv().Settings.AutoUpgradeStats.PointsPerUpgrade,
		},
		Callback = function(Value)
			getgenv().Settings.AutoUpgradeStats.PointsPerUpgrade = Value
			SaveSetting()
		end,
	})

	VenuzToggle.AutoUpgrade = function(Value)
		getgenv().Settings.AutoUpgradeStats.Enabled = Value
		SaveSetting()

		if not Value then
			UpgradeRunning = false
			if UpgradeLoop then
				pcall(function()
					task.cancel(UpgradeLoop)
				end)
				UpgradeLoop = nil
			end
			return
		end

		if UpgradeRunning then
			return
		end

		UpgradeRunning = true
		UpgradeLoop = task.spawn(function()
			while UpgradeRunning do
				task.wait(0.5)

				pcall(function()
					local Setting = getgenv().Settings.AutoUpgradeStats
					local Selected = NormalizeStats(Setting.Stats)

					if #Selected == 0 or PointsValue.Value <= 0 then
						return
					end

					for _, StatName in ipairs(Selected) do
						if not UpgradeRunning then
							break
						end

						local Available = PointsValue.Value
						if Available <= 0 then
							break
						end

						local Stat = Experience:FindFirstChild(StatName)
						if Stat and Stat.Value or 0 then
							local Amount = math.clamp(math.floor(Setting.PointsPerUpgrade), 1, Available)
							StatsEvent:FireServer(StatName, Amount)
							task.wait(0.15)
						end
					end
				end)
			end
		end)
	end

	local AutoUpgradeToggle = AutoUpgradeSection:Toggle({
		Title = "tr:AutoUpgradeToggle",
		Path = "AutoUpgradeStats.Enabled",
		Desc = "tr:AutoUpgradeToggleDesc",

		Value = getgenv().Settings.AutoUpgradeStats.Enabled,
		Icon = "check",
		Callback = VenuzToggle.AutoUpgrade,
	})

	if getgenv().Settings.AutoUpgradeStats.Enabled then
		task.defer(VenuzToggle.AutoUpgrade, true)
	end
end

local BossTab = TabGroups.Farm:Tab({
	Title = "tr:BossTab",
	Icon = "skull",
	Locked = false,
})
SetTabOrder(BossTab, 2)

local FarmTab = TabGroups.Farm:Tab({
	Title = "tr:FarmTab",
	Icon = "sliders-horizontal",
	Locked = false,
})
SetTabOrder(FarmTab, 999)

local WeaponSection = FarmTab:Section({ Title = "tr:WeaponSection", Icon = "sword", Opened = true })
local FarmSettingsSection = FarmTab:Section({ Title = "tr:FarmSettings", Icon = "sliders-horizontal", Opened = true })

getgenv().Settings.AutoFarmLevel.Weapon = FarmWeaponMode()
getgenv().Settings.AutoFarmLevel.BossWeapon = BossWeaponMode()

WeaponSection:Dropdown({
	Title = "tr:SelectWeapon",
	Path = "AutoFarmLevel.Weapon",
	Desc = "tr:SelectWeaponDesc",
	Multi = false,
	AllowNone = true,
	Values = WeaponModes,
	Value = FarmWeaponMode() ~= "" and FarmWeaponMode() or nil,
	Callback = function(Value)
		getgenv().Settings.AutoFarmLevel.Weapon = WeaponMode(Value)
		SaveSetting()
	end,
})

BossWeaponDropdown = WeaponSection:Dropdown({
	Title = "tr:SelectBossWeapon",
	Path = "AutoFarmLevel.BossWeapon",
	Desc = "tr:SelectBossWeaponDesc",
	Multi = false,
	AllowNone = true,
	Values = WeaponModes,
	Value = BossWeaponMode() ~= "" and BossWeaponMode() or nil,
	Callback = function(Value)
		getgenv().Settings.AutoFarmLevel.BossWeapon = WeaponMode(Value)
		SaveSetting()
	end,
})

FarmSettingsSection:Dropdown({
	Title = "tr:AttackPosition",
	Path = "AutoFarmLevel.AttackPosition",
	Desc = "tr:AttackPositionDesc",
	Multi = false,
	AllowNone = false,
	Values = AttackPositions,
	Value = getgenv().Settings.AutoFarmLevel.AttackPosition,
	Callback = function(Value)
		getgenv().Settings.AutoFarmLevel.AttackPosition = Value
		SaveSetting()
	end,
})

FarmSettingsSection:Slider({
	Title = "tr:Distance",
	Path = "AutoFarmLevel.Distance",
	Desc = "tr:DistanceDesc",
	Value = {
		Min = 1,
		Max = 40,
		Default = getgenv().Settings.AutoFarmLevel.Distance,
	},
	Callback = function(Value)
		getgenv().Settings.AutoFarmLevel.Distance = Value
		SaveSetting()
	end,
})

FarmSettingsSection:Slider({
	Title = "tr:TweenSpeed",
	Path = "AutoFarmLevel.TweenSpeed",
	Desc = "tr:TweenSpeedDesc",
	Value = {
		Min = 50,
		Max = 1000,
		Default = getgenv().Settings.AutoFarmLevel.TweenSpeed,
	},
	Callback = function(Value)
		getgenv().Settings.AutoFarmLevel.TweenSpeed = Value
		SaveSetting()
	end,
})

if getgenv().Settings.AutoFarmLevel.Enabled then
	task.defer(VenuzToggle.AutoFarm, true)
end

local TeleportTab = TabGroups.Travel:Tab({
	Title = "tr:Teleport",
	Icon = "map-pin",
	Locked = false,
})

local NpcWorkspace = workspace:WaitForChild("Npc_Workspace")
local SpawnSetters = NpcWorkspace:WaitForChild("Spawn Setters")
local SetSpawnPoint = game:GetService("ReplicatedStorage").Replication.ClientEvents:WaitForChild("SetSpawnPoint")

local function ResolvePosition(Instance)
	if not Instance then
		return nil
	end

	local Position
	local ok = pcall(function()
		if Instance:IsA("Model") then
			local Primary = Instance.PrimaryPart or Instance:FindFirstChild("HumanoidRootPart")
			Position = Primary and Primary.Position or Instance:GetPivot().Position
		elseif Instance:IsA("BasePart") then
			Position = Instance.Position
		end
	end)

	if ok and Position and Position.Magnitude > 1 then
		return Position
	end

	for _, Part in ipairs(Instance:GetDescendants()) do
		if Part:IsA("BasePart") and Part.Position.Magnitude > 1 then
			return Part.Position
		end
	end

	return nil
end

local TpActive = false

local function TeleportTo(Position)
	if not Position then
		return false
	end

	TpActive = false
	task.wait()

	local Root = GetRoot()
	if not Root then
		return false
	end

	local Goal = Position + Vector3.new(0, 5, 0)
	TpActive = true

	task.spawn(function()
		while TpActive do
			local Current = GetRoot()
			if not Current then
				break
			end

			local Character = GetCharacter()
			if Character then
				NoclipCharacter(Character)
			end

			local Offset = Goal - Current.Position
			local Remaining = Offset.Magnitude

			if Remaining < 3 then
				Current.CFrame = CFrame.new(Goal)
				Current.AssemblyLinearVelocity = Vector3.zero
				break
			end

			local Delta = RunService.Heartbeat:Wait()
			local Speed = getgenv().Settings.AutoFarmLevel.TweenSpeed
			local Step = math.min(Speed * Delta, 40)
			local Direction = Offset.Unit
			local NextPos = Current.Position + Direction * Step
			Current.CFrame = CFrame.lookAt(NextPos, NextPos + Direction)
			Current.AssemblyLinearVelocity = Direction * Speed
		end

		local Hold = tick() + 0.6
		while tick() < Hold do
			local Character = GetCharacter()
			if Character then
				NoclipCharacter(Character)
			end
			RunService.Heartbeat:Wait()
		end

		TpActive = false
	end)

	return true
end

local function NearestSpawnSetter()
	local Root = GetRoot()
	if not Root then
		return nil
	end

	local Closest, ClosestDistance = nil, math.huge
	for _, Setter in ipairs(SpawnSetters:GetChildren()) do
		local Position = ResolvePosition(Setter)
		if Position then
			local Distance = (Position - Root.Position).Magnitude
			if Distance < ClosestDistance then
				Closest, ClosestDistance = Setter, Distance
			end
		end
	end

	return Closest
end

local SpawnSection = TeleportTab:Section({ Title = "tr:SpawnSection", Icon = "flag", Opened = true })

local AutoSpawnConnection = nil

AutoSpawnHoldUntil = 0

VenuzToggle.AutoSpawn = function(Value)
	getgenv().Settings.AutoSetSpawn = Value
	SaveSetting()

	if AutoSpawnConnection then
		AutoSpawnConnection:Disconnect()
		AutoSpawnConnection = nil
	end

	if Value then
		local LastName = nil
		local NextCheck = 0
		AutoSpawnConnection = RunService.Heartbeat:Connect(function()
			if tick() < NextCheck or tick() < AutoSpawnHoldUntil then
				return
			end
			NextCheck = tick() + 2

			local Setter = NearestSpawnSetter()
			if Setter and Setter.Name ~= LastName then
				LastName = Setter.Name
				pcall(function()
					SetSpawnPoint:FireServer(Setter.Name)
				end)
			end
		end)
	end
end

local AutoSpawnToggle = SpawnSection:Toggle({
	Title = "tr:AutoSetSpawn",
	Path = "AutoSetSpawn",
	Desc = "tr:AutoSetSpawnDesc",

	Value = getgenv().Settings.AutoSetSpawn,
	Icon = "check",
	Callback = VenuzToggle.AutoSpawn,
})

if getgenv().Settings.AutoSetSpawn then
	task.defer(VenuzToggle.AutoSpawn, true)
end

SpawnSection:Button({
	Title = "tr:SetSpawnNow",
	Desc = "tr:SetSpawnNowDesc",
	Callback = function()
		local Setter = NearestSpawnSetter()
		if Setter then
			pcall(function()
				SetSpawnPoint:FireServer(Setter.Name)
			end)
			WindUI:Notify({ Title = "Spawn Point", Content = Setter.Name, Duration = 3 })
		end
	end,
})

local IslandSection = TeleportTab:Section({ Title = "tr:IslandSection", Icon = "map", Opened = true })

local SelectedIsland = getgenv().Settings.SelectedIsland ~= "" and getgenv().Settings.SelectedIsland or nil

IslandSection:Dropdown({
	Title = "tr:SelectIsland",
	Path = "SelectedIsland",
	Desc = "tr:SelectIslandDesc",
	Multi = false,
	AllowNone = false,
	Values = (function()
		local Names = {}
		for _, Setter in ipairs(SpawnSetters:GetChildren()) do
			table.insert(Names, Setter.Name)
		end
		table.sort(Names)
		return Names
	end)(),
	Value = SelectedIsland,
	Callback = function(Value)
		SelectedIsland = Value
		getgenv().Settings.SelectedIsland = Value or ""
		SaveSetting()
	end,
})

IslandSection:Dropdown({
	Title = "tr:IslandMode",
	Path = "IslandTeleportMode",
	Desc = "tr:IslandModeDesc",
	Multi = false,
	AllowNone = false,
	Values = { "Tween", "Set Spawn" },
	Value = getgenv().Settings.IslandTeleportMode == "Set Spawn" and "Set Spawn" or "Tween",
	Callback = function(Value)
		getgenv().Settings.IslandTeleportMode = Value == "Set Spawn" and "Set Spawn" or "Tween"
		SaveSetting()
	end,
})

IslandSection:Button({
	Title = "tr:TeleportGo",
	Desc = "tr:TeleportGoDesc",
	Callback = function()
		if not SelectedIsland then
			return
		end

		local Setter = SpawnSetters:FindFirstChild(SelectedIsland)

		if getgenv().Settings.IslandTeleportMode == "Set Spawn" then
			if not Setter then
				WindUI:Notify({ Title = "Teleport", Content = "Island not loaded yet, get closer first.", Duration = 4 })
				return
			end

			TpActive = false
			AutoSpawnHoldUntil = tick() + 8

			local Fired = pcall(function()
				SetSpawnPoint:FireServer(Setter.Name)
			end)
			if not Fired then
				AutoSpawnHoldUntil = 0
				WindUI:Notify({ Title = "Teleport", Content = "Could not set the spawn point.", Duration = 4 })
				return
			end

			WindUI:Notify({ Title = "Spawn Point", Content = Setter.Name .. ", resetting.", Duration = 3 })
			task.wait(0.4)

			local Character = GetCharacter()
			local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
			if Humanoid then
				pcall(function()
					Humanoid.Health = 0
				end)
			elseif Character then
				pcall(function()
					Character:BreakJoints()
				end)
			end

			task.spawn(function()
				LocalPlayer.CharacterAdded:Wait()
				task.wait(1)
				AutoSpawnHoldUntil = 0
			end)
			return
		end

		local Position = Setter and ResolvePosition(Setter)
		if Position then
			TeleportTo(Position)
		else
			WindUI:Notify({ Title = "Teleport", Content = "Island not loaded yet, get closer first.", Duration = 4 })
		end
	end,
})

local ShopTab = TabGroups.Item:Tab({
	Title = "tr:ShopTab",
	Icon = "store",
	Locked = false,
})

local ClientEvents = game:GetService("ReplicatedStorage"):WaitForChild("Replication"):WaitForChild("ClientEvents")

local HakiTypes = {
	{
		Key = "Buso",
		Label = "Buso Haki",
		Folder = "Buso",
		Remote = "Buso",
		Flag = "BusoEnabled",
		OwnedParent = "Buso",
		OwnedValue = "BusoLevel",
		NeedLevel = 350,

		NeedBeli = 50000,

		Spot = Vector3.new(-2871.4, 18.4, 1412.7),
		Island = "Logue City",
	},
	{
		Key = "Observation",
		Label = "Observation Haki",
		Folder = "ObsHaki",
		Remote = "ObsHaki",
		Flag = "ObservationHaki",
		OwnedParent = "Haki",
		OwnedValue = "ObservationHakiLevel",
		NeedLevel = 600,

		NeedBeli = 50000,

		Spot = Vector3.new(-61.4, 101.6, 4855.4),
		Island = "Marine Base Town",
	},
}

local CurrencyValue = PlayerData:WaitForChild("Currency")

local function HasHaki(Entry)
	local Folder = PlayerData:FindFirstChild(Entry.OwnedParent)
	local Value = Folder and Folder:FindFirstChild(Entry.OwnedValue)
	return Value ~= nil and Value.Value > 0
end

local function CanBuyHaki(Entry)
	return LevelValue.Value >= Entry.NeedLevel and CurrencyValue.Value >= Entry.NeedBeli
end

local function GetHakiNpc(Entry)
	local Folder = NpcWorkspace:FindFirstChild(Entry.Folder)
	if not Folder then
		return nil
	end

	local Root = GetRoot()
	local Best, BestRank = nil, math.huge

	for _, Npc in ipairs(Folder:GetChildren()) do
		local Rank = tonumber(Npc.Name)
		if not Rank then
			local Position = ResolvePosition(Npc)
			Rank = (Root and Position) and (Position - Root.Position).Magnitude or math.huge
		end

		if Rank < BestRank then
			Best, BestRank = Npc, Rank
		end
	end

	return Best
end

local function WaitForHakiNpc(Entry, Timeout)
	local Deadline = tick() + (Timeout or 6)

	while tick() < Deadline do
		local Npc = GetHakiNpc(Entry)
		if Npc and ResolvePosition(Npc) then
			return Npc
		end
		task.wait(0.2)
	end

	return GetHakiNpc(Entry)
end

local function HoldAt(Position, Duration)
	local Goal = CFrame.new(Position + Vector3.new(0, 5, 0))
	local Deadline = tick() + (Duration or 1)

	Teleport(Goal)
	while tick() < Deadline do
		local Root = GetRoot()
		if not Root then
			break
		end
		Root.CFrame = Goal
		Root.AssemblyLinearVelocity = Vector3.zero
		RunService.Heartbeat:Wait()
	end
end

function HakiSpawnJump(Spot, Island)
	local Root = GetRoot()
	if not Root or (Root.Position - Spot).Magnitude <= 1500 then
		return false
	end

	local Setter = Island and SpawnSetters:FindFirstChild(Island)

	if not Setter then
		local Best = math.huge

		for _, Item in ipairs(SpawnSetters:GetChildren()) do
			local Position = ResolvePosition(Item)
			if Position then
				local Away = (Position - Spot).Magnitude
				if Away < Best then
					Setter, Best = Item, Away
				end
			end
		end
	end

	if not Setter then
		return false
	end

	AutoSpawnHoldUntil = tick() + 20

	if not pcall(function()
		SetSpawnPoint:FireServer(Setter.Name)
	end) then
		AutoSpawnHoldUntil = 0
		return false
	end

	task.wait(0.4)
	LockCFrame = nil
	CancelTween()

	local Character = GetCharacter()
	local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

	if Humanoid then
		pcall(function()
			Humanoid.Health = 0
		end)
	elseif Character then
		pcall(function()
			Character:BreakJoints()
		end)
	else
		AutoSpawnHoldUntil = 0
		return false
	end

	local Deadline = tick() + 20
	while tick() < Deadline do
		if IsAlive() and GetRoot() then
			break
		end
		task.wait(0.2)
	end

	task.wait(0.5)
	AutoSpawnHoldUntil = 0

	return IsAlive()
end

local function BuyHaki(Entry, Notify)
	local Root = GetRoot()
	if not Root then
		return false
	end

	local ReturnCFrame = Root.CFrame
	local Npc = GetHakiNpc(Entry)
	local Spot = (Npc and ResolvePosition(Npc)) or Entry.Spot

	if not Npc then
		HakiSpawnJump(Spot, Entry.Island)

		HoldAt(Spot, 1)
		Npc = WaitForHakiNpc(Entry, 10)

		if not Npc then
			Teleport(ReturnCFrame)
			if Notify then
				WindUI:Notify({ Title = Entry.Label, Content = "Seller did not load at the shop spot.", Duration = 4 })
			end
			return false
		end

		Spot = ResolvePosition(Npc) or Spot
	end

	HoldAt(Spot, 0.6)

	local ok, Result = pcall(function()
		return ClientEvents:WaitForChild(Entry.Remote):InvokeServer(Npc)
	end)

	task.wait(0.2)
	Teleport(ReturnCFrame)

	local Success = ok and Result ~= false

	if Notify then
		WindUI:Notify({
			Title = Entry.Label,
			Content = Success and "Purchased!" or "Purchase failed (check level / beli).",
			Duration = 4,
		})
	end

	return Success
end

local ShopSection = ShopTab:Section({ Title = "tr:HakiShopSection", Icon = "sparkles", Opened = true })

local AutoBuyRunning = {}
local AutoBuyToggles = {}

function HakiSeaLocked()
	return game.PlaceId ~= 6918802270
end

function HakiSeaWarning()
	if getgenv().ConfigurationTable.Language == "Thai" then
		return "ซื้อฮาคิได้เฉพาะ Sea 1 เท่านั้น"
	end
	return "Haki sellers are Sea 1 only."
end

local function StartAutoBuy(Entry)
	if AutoBuyRunning[Entry.Key] then
		return
	end

	if HakiSeaLocked() then
		AutoBuyRunning[Entry.Key] = false
		getgenv().Settings.AutoBuyHaki[Entry.Key] = false
		SaveSetting()
		SetToggleValue(AutoBuyToggles[Entry.Key], false)
		WindUI:Notify({ Title = Entry.Label, Content = HakiSeaWarning(), Duration = 5 })
		return
	end

	AutoBuyRunning[Entry.Key] = true

	task.spawn(function()
		while AutoBuyRunning[Entry.Key] do
			task.wait(3)

			if HakiSeaLocked() then
				AutoBuyRunning[Entry.Key] = false
				getgenv().Settings.AutoBuyHaki[Entry.Key] = false
				SaveSetting()
				SetToggleValue(AutoBuyToggles[Entry.Key], false)
				break
			end

			if HasHaki(Entry) then
				AutoBuyRunning[Entry.Key] = false
				getgenv().Settings.AutoBuyHaki[Entry.Key] = false
				SaveSetting()
				SetToggleValue(AutoBuyToggles[Entry.Key], false)
				break
			end

			if IsAlive() and CanBuyHaki(Entry) then
				local ok, Success = pcall(BuyHaki, Entry, false)

				if ok and Success then
					WindUI:Notify({ Title = Entry.Label, Content = "Purchased!", Duration = 4 })
				else
					task.wait(5)
				end
			end
		end
	end)
end

for _, Entry in ipairs(HakiTypes) do
	AutoBuyToggles[Entry.Key] = ShopSection:Toggle({
		Title = Entry.Key == "Buso" and "tr:AutoBuyBuso" or "tr:AutoBuyObservation",
		Desc = Entry.Key == "Buso" and "tr:AutoBuyBusoDesc" or "tr:AutoBuyObservationDesc",
		Path = "AutoBuyHaki." .. Entry.Key,
		Value = getgenv().Settings.AutoBuyHaki[Entry.Key],
		Icon = "check",
		Callback = function(Value)
			getgenv().Settings.AutoBuyHaki[Entry.Key] = Value
			SaveSetting()

			if Value then
				StartAutoBuy(Entry)
			else
				AutoBuyRunning[Entry.Key] = false
			end
		end,
	})

	if getgenv().Settings.AutoBuyHaki[Entry.Key] then
		task.defer(StartAutoBuy, Entry)
	end
end
(function()
	local SwordSection = ShopTab:Section({ Title = "tr:SwordShopSection", Icon = "sword", Opened = true })

	local SwordSeaPlace = 6918802270

	local SwordList = {
		{ Name = "Soul Cane", Price = 100000, Level = 1000, Spot = CFrame.new(2845, 11, 6117) },
		{ Name = "Operation Blade", Price = 250000, Level = 1000, Spot = CFrame.new(1784, 207, -3251) },
		{ Name = "Pipe", Price = 250000, Level = 0, Spot = CFrame.new(-598, 59, 4923) },
		{ Name = "Bisento", Price = 500000, Level = 0, Spot = CFrame.new(-5758, 482, 6774) },
	}

	local SwordInfo = {}
	for _, Entry in ipairs(SwordList) do
		SwordInfo[Entry.Name] = Entry
	end

	local function SpotVector(Value)
		if typeof(Value) == "CFrame" then
			return Value.Position
		end
		if typeof(Value) == "Vector3" then
			return Value
		end
		return nil
	end

	local function InSwordSea()
		return game.PlaceId == SwordSeaPlace
	end

	local BuySwordRemote = ClientEvents:WaitForChild("BuySword")
	local OwnedSwords = PlayerData:WaitForChild("Sword"):WaitForChild("OwnedSwords")

	local function GetSwordSellers()
		return NpcWorkspace:FindFirstChild("Sword Sellers")
	end

	local function GetSwordSeller(Name)
		local Folder = GetSwordSellers()
		return Folder and Folder:FindFirstChild(Name)
	end

	local function RememberSpot(Seller)
		if not InSwordSea() or not Seller or not SwordInfo[Seller.Name] then
			return
		end

		local Position = ResolvePosition(Seller)
		if not Position then
			return
		end

		local Spots = getgenv().Settings.SwordSpots
		local Saved = Spots[Seller.Name]

		if Saved and (Vector3.new(Saved[1], Saved[2], Saved[3]) - Position).Magnitude < 5 then
			return
		end

		Spots[Seller.Name] = { Position.X, Position.Y, Position.Z }
		SaveSetting()
	end

	local function GetSpot(Name)
		local Info = SwordInfo[Name]
		local Fixed = Info and SpotVector(Info.Spot)
		if Fixed then
			return Fixed
		end

		local Saved = getgenv().Settings.SwordSpots[Name]
		if type(Saved) == "table" and #Saved == 3 then
			return Vector3.new(Saved[1], Saved[2], Saved[3])
		end

		return nil
	end

	local function ScanSpots()
		local Folder = GetSwordSellers()
		if not Folder then
			return
		end

		for _, Seller in ipairs(Folder:GetChildren()) do
			RememberSpot(Seller)
		end
	end

	task.spawn(function()
		if not InSwordSea() then
			return
		end

		local Folder = NpcWorkspace:WaitForChild("Sword Sellers", 30)
		if not Folder then
			return
		end

		ScanSpots()

		Folder.ChildAdded:Connect(function(Seller)
			task.wait(0.5)
			RememberSpot(Seller)
		end)
	end)

	local function GetSwordPrice(Name)
		local Info = SwordInfo[Name]
		return Info and Info.Price or 0
	end

	local function GetSwordLevel(Name)
		local Info = SwordInfo[Name]
		return Info and Info.Level or 0
	end

	local function HasSword(Name)
		if OwnedSwords.Value == "" then
			return false
		end

		local ok, List = pcall(function()
			return HttpService:JSONDecode(OwnedSwords.Value)
		end)

		if not ok or type(List) ~= "table" then
			return false
		end

		for _, Owned in pairs(List) do
			if Owned == Name or Owned == (Name .. " V2") then
				return true
			end
		end

		return false
	end

	local function FormatMoney(Amount)
		local Text = tostring(Amount)
		while true do
			local Replaced
			Text, Replaced = Text:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
			if Replaced == 0 then
				break
			end
		end
		return Text
	end

	local SwordLabelToName = {}

	local function BuildSwordLabels()
		SwordLabelToName = {}
		local Labels = {}

		for _, Entry in ipairs(SwordList) do
			local Label = Entry.Name .. " - $" .. FormatMoney(Entry.Price)

			if Entry.Level > 0 then
				Label = Label .. " (Lv." .. Entry.Level .. ")"
			end

			if HasSword(Entry.Name) then
				Label = Label .. " [Owned]"
			end

			SwordLabelToName[Label] = Entry.Name
			table.insert(Labels, Label)
		end

		return Labels
	end

	local SelectedSword = getgenv().Settings.SelectedSword ~= "" and getgenv().Settings.SelectedSword or nil

	local function LabelForSword(Name)
		if not Name then
			return nil
		end

		for Label, Value in pairs(SwordLabelToName) do
			if Value == Name then
				return Label
			end
		end

		return nil
	end

	local SwordDropdown = SwordSection:Dropdown({
		Title = "tr:SelectSword",
		Desc = "tr:SelectSwordDesc",
		Multi = false,
		AllowNone = false,
		Values = BuildSwordLabels(),
		Value = LabelForSword(SelectedSword),
		Callback = function(Value)
			SelectedSword = SwordLabelToName[Value] or Value
			getgenv().Settings.SelectedSword = SelectedSword or ""
			SaveSetting()
		end,
	})

	local function WaitForSwordSeller(Name, Timeout, Position)
		local Deadline = tick() + (Timeout or 8)

		while tick() < Deadline do
			local Seller = GetSwordSeller(Name)
			if Seller and ResolvePosition(Seller) then
				RememberSpot(Seller)
				return Seller
			end

			task.wait(0.25)
		end

		return GetSwordSeller(Name)
	end

	local BuyingSword = false

	local function BuySword(Name)
		if not InSwordSea() then
			WindUI:Notify({ Title = Name, Content = "Sword sellers are Sea 1 only.", Duration = 4 })
			return false
		end

		local Price = GetSwordPrice(Name) or 0
		if CurrencyValue.Value < Price then
			WindUI:Notify({ Title = Name, Content = "Not enough Beli ($" .. FormatMoney(Price) .. ").", Duration = 4 })
			return false
		end

		local NeedLevel = GetSwordLevel(Name)
		if NeedLevel > 0 and LevelValue.Value < NeedLevel then
			WindUI:Notify({ Title = Name, Content = "Need level " .. NeedLevel .. ".", Duration = 4 })
			return false
		end

		local Root = GetRoot()
		if not Root then
			return false
		end

		local ReturnCFrame = Root.CFrame
		local Seller = GetSwordSeller(Name)
		local Spot = GetSpot(Name) or (Seller and ResolvePosition(Seller))

		if not Spot then
			WindUI:Notify({
				Title = Name,
				Content = "Spot unknown. Walk past that seller once, then try again.",
				Duration = 5,
			})
			return false
		end

		HoldAt(Spot, 1)

		if not Seller then
			Seller = WaitForSwordSeller(Name, 8, Spot)

			if not Seller then
				Teleport(ReturnCFrame)
				WindUI:Notify({ Title = Name, Content = "Seller did not stream in at the spot.", Duration = 4 })
				return false
			end
		end

		HoldAt(ResolvePosition(Seller) or Spot, 0.6)

		local ok, Result = pcall(function()
			return BuySwordRemote:InvokeServer(Seller)
		end)

		task.wait(0.2)
		Teleport(ReturnCFrame)

		local Success = ok and Result ~= false and Result ~= nil

		WindUI:Notify({
			Title = Name,
			Content = Success and "Purchased!" or "Purchase failed (check beli / level / owned).",
			Duration = 4,
		})

		return Success
	end

	SwordSection:Button({
		Title = "tr:BuySword",
		Desc = "tr:BuySwordDesc",
		Callback = function()
			if BuyingSword then
				return
			end

			if not SelectedSword then
				WindUI:Notify({ Title = "Sword", Content = "Pick a sword first.", Duration = 3 })
				return
			end

			if HasSword(SelectedSword) then
				WindUI:Notify({ Title = SelectedSword, Content = "You already own this sword.", Duration = 3 })
				return
			end

			BuyingSword = true
			task.spawn(function()
				pcall(BuySword, SelectedSword)
				pcall(function()
					SwordDropdown:Refresh(BuildSwordLabels())
				end)
				BuyingSword = false
			end)
		end,
	})
end)()
;
(function()
	local MerchantSection = ShopTab:Section({ Title = "tr:MerchantSection", Icon = "coins", Opened = true })

	MerchantBusy = false

	local Wares = {
		{ Name = "Ancient Blade Relic", Flag = "BoughtBladeRelic", Price = 1000000 },
		{ Name = "Blade Fragment", Flag = "BoughtBladeFragment", Price = 300000 },
	}

	local AutoRunning = false
	local Busy = false
	local LastAttempt = 0
	local LastModel = nil

	local TriedModel = nil
	local Fails = 0
	local MaxFails = 3

	local ActiveDrive = nil

	local function FindMerchant()
		local Folder = NpcWorkspace:FindFirstChild("WanderingMerchant")
		if not Folder then
			return nil
		end

		local Model = Folder:FindFirstChild("Wandering Merchant")
		if Model and Model:FindFirstChild("Interact") then
			return Model
		end

		for _, Child in ipairs(Folder:GetChildren()) do
			if Child:IsA("Model") and Child:FindFirstChild("Interact") then
				return Child
			end
		end

		return nil
	end

	local function MerchantState(Model)
		local Value = PlayerData:FindFirstChild("WanderingMerchantData")
		local Raw = Value and Value.Value

		if type(Raw) ~= "string" or Raw == "" then
			return {}
		end

		local ok, Data = pcall(function()
			return HttpService:JSONDecode(Raw)
		end)

		if not ok or type(Data) ~= "table" then
			return {}
		end

		if Data.MerchantIndex ~= Model:GetAttribute("Index") then
			return {}
		end

		return Data
	end

	local function GetCurrency()
		local Value = PlayerData:FindFirstChild("Currency")
		return Value and Value.Value or 0
	end

	local function WantedWares(Model)
		local Stock = Model:FindFirstChild("Stock")
		local Data = MerchantState(Model)
		local Wanted = {}

		if Data.BusinessDone then
			return Wanted
		end

		for _, Ware in ipairs(Wares) do
			if not Data[Ware.Flag] and Stock and Stock:FindFirstChild(Ware.Name) then
				table.insert(Wanted, Ware)
			end
		end

		return Wanted
	end

	local DrivePriority = 4

	local function HoldDrive(Drive)
		task.spawn(function()
			local Deadline = tick() + 90

			while Drive.On and tick() < Deadline do
				ClaimDrive("Merchant", DrivePriority)
				task.wait(0.25)
			end

			if Drive.On then
				Drive.On = false
				MerchantBusy = false
				EndRunner("Merchant")
				HandBackMerchant()
			elseif VenuzRun.Owner == "Merchant" then
				ReleaseDrive("Merchant")
				HandBackMerchant()
			end
		end)
	end

	function HandBackMerchant()
		if FarmerBusy() then
			HandBackDrive()
		end
	end

	local FarTravel = 2000

	local function NearestSetterTo(Position)
		local Best, BestDistance = nil, math.huge

		for _, Setter in ipairs(SpawnSetters:GetChildren()) do
			local Spot = ResolvePosition(Setter)
			if Spot then
				local Distance = (Spot - Position).Magnitude
				if Distance < BestDistance then
					Best, BestDistance = Setter, Distance
				end
			end
		end

		return Best, BestDistance
	end

	local function SpawnJumpTo(Position)
		local Root = GetRoot()
		if not Root then
			return false
		end

		local Away = (Root.Position - Position).Magnitude
		if Away <= FarTravel then
			return false
		end

		local Setter, SetterAway = NearestSetterTo(Position)
		if not Setter or SetterAway >= Away then
			return false
		end

		AutoSpawnHoldUntil = tick() + 20

		if not pcall(function()
			SetSpawnPoint:FireServer(Setter.Name)
		end) then
			AutoSpawnHoldUntil = 0
			return false
		end

		task.wait(0.4)
		LockCFrame = nil
		CancelTween()

		local Character = GetCharacter()
		local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

		if Humanoid then
			pcall(function()
				Humanoid.Health = 0
			end)
		elseif Character then
			pcall(function()
				Character:BreakJoints()
			end)
		else
			AutoSpawnHoldUntil = 0
			return false
		end

		local Deadline = tick() + 20
		while tick() < Deadline do
			if IsAlive() and GetRoot() then
				break
			end
			task.wait(0.2)
		end

		task.wait(0.5)
		AutoSpawnHoldUntil = 0

		return IsAlive()
	end

	local function BuyFromMerchant()
		if not IsAlive() then
			return false, "Character is dead."
		end

		local Model = FindMerchant()
		if not Model then
			return false, "Merchant is not in Npc_Workspace."
		end

		local Spot = ResolvePosition(Model)
		if not Spot then
			return false, "Merchant has not streamed in yet."
		end

		local Root = GetRoot()
		if not Root then
			return false, "No character."
		end

		local Remote = Model:FindFirstChild("Interact")
		if not Remote or not Remote:IsA("RemoteFunction") then
			return false, "Merchant has no Interact remote."
		end

		local Wanted = WantedWares(Model)
		if #Wanted == 0 then
			return true, "Nothing left to buy from this merchant."
		end

		local Affordable = {}
		for _, Ware in ipairs(Wanted) do
			if GetCurrency() >= Ware.Price then
				table.insert(Affordable, Ware)
			end
		end

		if #Affordable == 0 then
			return false, "Not enough money yet."
		end

		Wanted = Affordable

		local Drive = { On = true }
		ActiveDrive = Drive

		MerchantBusy = true
		BeginRunner("Merchant")
		HoldDrive(Drive)
		ClaimDrive("Merchant", DrivePriority)
		StartRender()

		local function Finish(Ok, Reason)
			Drive.On = false
			ActiveDrive = nil
			MerchantBusy = false
			LockCFrame = nil
			CancelTween()
			EndRunner("Merchant")
			HandBackMerchant()
			return Ok, Reason
		end

		local Stand = CFrame.new(Spot + Vector3.new(0, 5, 0))

		SpawnJumpTo(Spot)

		local Deadline = tick() + 45

		while tick() < Deadline do
			local Current = GetRoot()
			if not Current then
				return Finish(false, "Lost the character on the way.")
			end

			if (Current.Position - Stand.Position).Magnitude <= 8 then
				break
			end

			LockCFrame = nil
			TravelTo(Stand, 8)
		end

		local Arrived = GetRoot()
		if not Arrived or (Arrived.Position - Stand.Position).Magnitude > 15 then
			return Finish(false, "Could not reach the merchant.")
		end

		CancelTween()
		LockCFrame = Stand
		task.wait(0.4)

		local Bought = 0
		local LastReason = nil
		local BoughtNames = {}
		local Spent = 0

		for _, Ware in ipairs(Wanted) do
			if GetCurrency() >= Ware.Price then
				local ok, Success, Reason = pcall(function()
					return Remote:InvokeServer(Ware.Name)
				end)

				if ok and Success then
					Bought = Bought + 1
					table.insert(BoughtNames, Ware.Name .. "  -  $" .. Webhook.Num(Ware.Price))
					Spent = Spent + Ware.Price
				else
					LastReason = (ok and Reason) or "InvokeFailed"
				end

				task.wait(0.4)
			else
				LastReason = "NotEnoughMoney"
			end
		end

		if Bought == 0 then
			return Finish(false, "Bought nothing (" .. tostring(LastReason) .. ").")
		end

		pcall(function()
			Webhook.Merchant(BoughtNames, Spent)
		end)

		return Finish(true, "Bought " .. Bought .. " of " .. #Wanted .. " wares.")
	end

	VenuzToggle.AutoMerchant = function(Value)
		getgenv().Settings.AutoMerchant.Enabled = Value
		SaveSetting()

		if not Value then
			AutoRunning = false
			return
		end

		if AutoRunning then
			return
		end

		AutoRunning = true

		task.spawn(function()
			while AutoRunning and getgenv().Settings.AutoMerchant.Enabled do
				if not IsCurrentInstance() then
					if MerchantBusy then
						MerchantBusy = false
						EndRunner("Merchant")
					end
					break
				end

				if IsAlive() and not Busy then
					if ActiveDrive then
						ActiveDrive.On = false
						ActiveDrive = nil
					end

					if MerchantBusy then
						MerchantBusy = false
						EndRunner("Merchant")
						HandBackMerchant()
					end

					local Model = FindMerchant()

					if Model and Model ~= TriedModel then
						TriedModel = Model
						LastModel = nil
						Fails = 0
					end

					if Model and Model ~= LastModel and Fails < MaxFails and tick() - LastAttempt > 15 then
						LastModel = Model
						Busy = true

						local ok, Success = pcall(BuyFromMerchant)

						if ActiveDrive then
							ActiveDrive.On = false
							ActiveDrive = nil
						end

						if MerchantBusy then
							MerchantBusy = false
							EndRunner("Merchant")
							HandBackMerchant()
						end

						Busy = false

						LastAttempt = tick()

						if ok and Success then
							Fails = 0
						else
							Fails = Fails + 1

							if Fails < MaxFails then
								LastModel = nil
							end
						end
					end
				end

				task.wait(3)
			end

			AutoRunning = false
		end)
	end

	MerchantSection:Toggle({
		Title = "tr:MerchantAuto",
		Path = "AutoMerchant.Enabled",
		Desc = "tr:MerchantAutoDesc",
		Value = getgenv().Settings.AutoMerchant.Enabled,
		Icon = "check",
		Callback = VenuzToggle.AutoMerchant,
	})

	if getgenv().Settings.AutoMerchant.Enabled then
		task.defer(VenuzToggle.AutoMerchant, true)
	end
end)()

do
	local ChestSection = Automatic:Section({ Title = "tr:ChestSection", Icon = "package", Opened = true })

	local AutoChestRunning = false

	local ChestTouchGap = 0.03

	function ChestCollected(Model)
		if not Model or not Model.Parent then
			return true
		end

		if Model:FindFirstChild("OpenUI") then
			return true
		end

		local Top = Model:FindFirstChild("Top") or Model

		for _, Part in ipairs(Top:GetDescendants()) do
			if Part:IsA("MeshPart") then
				return Part.Transparency >= 1
			end
		end

		return false
	end

	function ChestBlocked()
		return MerchantBusy or BossDriving()
	end

	local function CollectChestList(Done)
		local List = {}
		for _, Model in ipairs(workspace:GetChildren()) do
			if Model.Name == "Chest" and not (Done and Done[Model]) then
				if not ChestCollected(Model) then
					local Hitbox = Model:FindFirstChild("Hitbox")
					if Hitbox and Hitbox:IsA("BasePart") then
						table.insert(List, { Model = Model, Hitbox = Hitbox })
					end
				end
			end
		end
		return List
	end

	local function ChestTravelTo(Position, Radius, Timeout)
		local Deadline = tick() + (Timeout or 25)

		while AutoChestRunning and not ChestBlocked() and tick() < Deadline do
			local Root = GetRoot()
			if not Root then
				return false
			end

			local Character = GetCharacter()
			if Character then
				NoclipCharacter(Character)
			end

			local Offset = Position - Root.Position
			if Offset.Magnitude <= (Radius or 4) then
				Root.CFrame = CFrame.new(Position)
				Root.AssemblyLinearVelocity = Vector3.zero
				return true
			end

			local Delta = RunService.Heartbeat:Wait()
			local Speed = getgenv().Settings.AutoFarmLevel.TweenSpeed
			local Step = math.min(Speed * Delta, 40)
			local Direction = Offset.Unit
			local NextPos = Root.Position + Direction * Step
			Root.CFrame = CFrame.lookAt(NextPos, NextPos + Direction)
			Root.AssemblyLinearVelocity = Direction * Speed
		end

		return false
	end

	local function ChestTouchParts()
		local Parts = {}
		local Root = GetRoot()
		if Root then
			table.insert(Parts, Root)
		end

		local Character = GetCharacter()
		if Character then
			for _, Name in ipairs({
				"Torso",
				"UpperTorso",
				"LowerTorso",
				"Left Leg",
				"Right Leg",
				"LeftFoot",
				"RightFoot",
			}) do
				local Part = Character:FindFirstChild(Name)
				if Part and Part:IsA("BasePart") then
					table.insert(Parts, Part)
				end
			end
		end

		return Parts
	end

	local function TouchChest(Model, Hitbox)
		if not Hitbox or not Hitbox.Parent then
			return false
		end

		if typeof(firetouchinterest) ~= "function" then
			return false
		end

		local Deadline = tick() + 2.5

		while AutoChestRunning and not ChestBlocked() and tick() < Deadline do
			if ChestCollected(Model) then
				return true
			end

			if not Hitbox.Parent then
				return ChestCollected(Model)
			end

			for _, Part in ipairs(ChestTouchParts()) do
				pcall(firetouchinterest, Part, Hitbox, 0)
				pcall(firetouchinterest, Part, Hitbox, 1)
			end

			local Answer = tick() + 0.5
			while tick() < Answer do
				if ChestCollected(Model) then
					return true
				end
				task.wait(ChestTouchGap)
			end
		end

		return ChestCollected(Model)
	end

	local function CollectChestsHere()
		local Done = {}
		local Guard = 0

		while AutoChestRunning and Guard < 200 do
			while AutoChestRunning and ChestBlocked() do
				task.wait(0.5)
			end

			local List = CollectChestList(Done)
			if #List == 0 then
				return
			end

			local Root = GetRoot()
			if not Root then
				return
			end

			table.sort(List, function(a, b)
				return (a.Hitbox.Position - Root.Position).Magnitude < (b.Hitbox.Position - Root.Position).Magnitude
			end)

			local Target = List[1]
			Done[Target.Model] = true
			Guard = Guard + 1

			ChestTravelTo(Target.Hitbox.Position, 4, 15)
			TouchChest(Target.Model, Target.Hitbox)
		end
	end

	local function StartAutoChest()
		if AutoChestRunning then
			return
		end
		AutoChestRunning = true

		task.spawn(function()
			while AutoChestRunning do
				if not IsCurrentInstance() then
					AutoChestRunning = false
					break
				end

				local Visited = {}

				while AutoChestRunning and IsCurrentInstance() do
					while AutoChestRunning and ChestBlocked() do
						task.wait(0.5)
					end

					CollectChestsHere()

					local Root = GetRoot()
					if not Root then
						task.wait(0.5)
						break
					end

					local Name, Position, Best = nil, nil, math.huge

					for _, Setter in ipairs(SpawnSetters:GetChildren()) do
						if not Visited[Setter.Name] then
							local Spot = ResolvePosition(Setter)
							if Spot then
								local Distance = (Spot - Root.Position).Magnitude
								if Distance < Best then
									Name, Position, Best = Setter.Name, Spot, Distance
								end
							end
						end
					end

					if not Name then
						break
					end

					Visited[Name] = true

					pcall(function()
						CancelTween()
						ChestTravelTo(Position + Vector3.new(0, 5, 0), 8, 30)

						task.wait(0.5)
						CollectChestsHere()
					end)

					task.wait(0.1)
				end

				task.wait(1)
			end
		end)
	end

	local AutoChestToggle = ChestSection:Toggle({
		Title = "tr:AutoCollectChest",
		Path = "AutoCollectChest",
		Desc = "tr:AutoCollectChestDesc",
		Value = getgenv().Settings.AutoCollectChest,
		Icon = "check",
		Callback = function(Value)
			getgenv().Settings.AutoCollectChest = Value
			SaveSetting()

			if Value then
				StartAutoChest()
			else
				AutoChestRunning = false
			end
		end,
	})

	if getgenv().Settings.AutoCollectChest then
		task.delay(1, StartAutoChest)
	end

	local AutoHakiSection = Automatic:Section({ Title = "tr:AutoHakiSection", Icon = "sparkles", Opened = true })

	local function GetHakiToggleRemote(Entry)
		local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")

		if Entry.Key == "Buso" then
			local Character = GetCharacter()
			local Server = (Character and Character:FindFirstChild("Buso_Server"))
				or (
					PlayerGui
					and PlayerGui:FindFirstChild("FormerStarterCharacterScripts")
					and PlayerGui.FormerStarterCharacterScripts:FindFirstChild("Buso_Server")
				)
			return Server and Server:FindFirstChild("Comunication")
		end

		local Server = PlayerGui and PlayerGui:FindFirstChild("ObservationHaki_Server")
		return Server and Server:FindFirstChild("Comunication")
	end

	local function IsHakiOn(Entry)
		local Character = GetCharacter()
		local Flag = Character and Character:FindFirstChild(Entry.Flag)
		return Flag ~= nil and Flag.Value == true
	end

	local AutoHakiRunning = {}
	local AutoHakiToggles = {}

	local function StartAutoHaki(Entry)
		if AutoHakiRunning[Entry.Key] then
			return
		end
		AutoHakiRunning[Entry.Key] = true

		task.spawn(function()
			while AutoHakiRunning[Entry.Key] do
				task.wait(1)

				pcall(function()
					if not IsAlive() or IsHakiOn(Entry) then
						return
					end

					local Remote = GetHakiToggleRemote(Entry)
					if Remote then
						Remote:FireServer()
					end
				end)
			end
		end)
	end

	for _, Entry in ipairs(HakiTypes) do
		AutoHakiToggles[Entry.Key] = AutoHakiSection:Toggle({
			Title = Entry.Key == "Buso" and "tr:AutoBuso" or "tr:AutoObservation",
			Desc = Entry.Key == "Buso" and "tr:AutoBusoDesc" or "tr:AutoObservationDesc",
			Path = "AutoHaki." .. Entry.Key,
			Value = getgenv().Settings.AutoHaki[Entry.Key],
			Icon = "check",
			Callback = function(Value)
				getgenv().Settings.AutoHaki[Entry.Key] = Value
				SaveSetting()

				if Value then
					StartAutoHaki(Entry)
				else
					AutoHakiRunning[Entry.Key] = false
				end
			end,
		})

		if getgenv().Settings.AutoHaki[Entry.Key] then
			task.defer(StartAutoHaki, Entry)
		end
	end
end

local SeaPlaces = {
	[6918802270] = 1,
	[14979402479] = 2,
	[99664616626491] = 3,
}

local function CurrentSea()
	return SeaPlaces[game.PlaceId]
end

local Sea3Toggle

do
	local Sea2 = {
		NeedLevel = 2200,
		ScrollSpot = Vector3.new(-429, 230, -3087),
		NpcSpot = Vector3.new(-2117.5, 46.2, -2940),
	}

	local function GetScrollModel()
		local Logic = workspace:FindFirstChild("Logic")
		local POI = Logic and Logic:FindFirstChild("PointsOfInterest")
		return POI and POI:FindFirstChild("Poneglyph Scroll")
	end

	local function GetSea2Npc()
		local Teleporter = NpcWorkspace:FindFirstChild("Sea Teleporter")
		return Teleporter and Teleporter:FindFirstChild("Sea 2")
	end

	local function IsSea2Unlocked()
		local Flag = PlayerData:FindFirstChild("Sea2Unlocked")
		return Flag ~= nil and Flag.Value == true
	end

	local function GetScrollTool()
		local Character = GetCharacter()
		local Backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
		return (Character and Character:FindFirstChild("Poneglyph Scroll"))
			or (Backpack and Backpack:FindFirstChild("Poneglyph Scroll"))
	end

	local function WaitForThing(Getter, Timeout)
		local Deadline = tick() + (Timeout or 8)
		while tick() < Deadline do
			local Thing = Getter()
			if Thing then
				return Thing
			end
			task.wait(0.25)
		end
		return Getter()
	end

	local Sea2Status = "-"

	local function StepSea2()
		local Sea = CurrentSea()
		if Sea and Sea >= 2 then
			Sea2Status = "Already in Sea " .. Sea
			return true
		end

		if SeaHopInFlight() then
			Sea2Status = "Crossing to Sea 2, waiting for the place to load"
			return false
		end

		NoteSeaNeed("Sea2", 2)

		if not IsSea2Unlocked() then
			if LevelValue.Value < Sea2.NeedLevel then
				Sea2Status = "Need level " .. Sea2.NeedLevel
				return false
			end

			if not GetScrollTool() then
				Sea2Status = "Getting Poneglyph Scroll"
				HoldAt(Sea2.ScrollSpot, 1)

				local Model = WaitForThing(GetScrollModel, 8)
				local Pick = Model and Model:FindFirstChild("Pick")

				if not Pick then
					Sea2Status = "Scroll not found (already taken?)"
					return false
				end

				pcall(function()
					Pick:InvokeServer()
				end)
				task.wait(1)

				if not GetScrollTool() then
					Sea2Status = "Pick failed, retrying"
					return false
				end
			end

			EquipWeapon("Poneglyph Scroll")
			task.wait(0.4)

			local Character = GetCharacter()
			if not (Character and Character:FindFirstChild("Poneglyph Scroll")) then
				Sea2Status = "Could not equip scroll"
				return false
			end

			Sea2Status = "Talking to Sea Teleporter"
			HoldAt(Sea2.NpcSpot, 1)

			local Npc = WaitForThing(GetSea2Npc, 8)
			local UnlockSea = Npc and Npc:FindFirstChild("UnlockSea")

			if not UnlockSea then
				Sea2Status = "Sea 2 NPC not loaded"
				return false
			end

			pcall(function()
				UnlockSea:InvokeServer()
			end)
			task.wait(1)

			if not IsSea2Unlocked() then
				Sea2Status = "Unlock rejected by server"
				return false
			end
		end

		local May, Why = MaySeaTravel("Sea2", 2)
		if not May then
			Sea2Status = Why
			return false
		end

		Sea2Status = "Teleporting to Sea 2"
		HoldAt(Sea2.NpcSpot, 1)

		local Npc = WaitForThing(GetSea2Npc, 8)
		local TeleportRemote = Npc and Npc:FindFirstChild("Teleport")

		if not TeleportRemote then
			Sea2Status = "Sea 2 NPC not loaded"
			return false
		end

		pcall(function()
			TeleportRemote:InvokeServer()
		end)
		MarkSeaHop("Sea2", 2)
		Sea2Status = "Crossing to Sea 2"
		return true
	end

	local Sea3 = {
		NeedLevel = 4200,
		NpcSpot = Vector3.new(2491, 27.9, 15971),
	}

	local function GetGatekeeperRemote()
		local Folder = NpcWorkspace:FindFirstChild("Sea3Unlocker")
		local Npc = Folder and Folder:FindFirstChild("Gatekeeper")
		return Npc and Npc:FindFirstChild("Interact")
	end

	local function IsSea3Unlocked()
		local Flag = PlayerData:FindFirstChild("Sea3Unlocked")
		return Flag ~= nil and Flag.Value == true
	end

	SeaPlaceIds = { [1] = 6918802270, [2] = 14979402479, [3] = 99664616626491 }

	SeaHubs = {
		[1] = { Spot = Vector3.new(-2118, 46, -2943), Where = "Starter Island" },
		[2] = { Spot = Vector3.new(2496, 28, 15977), Where = "Flower Capital" },
		[3] = { Spot = Vector3.new(-5783, 565, 433), Where = "Land of Gods" },
	}

	SeaHop = { Until = 0, Target = nil, Owner = nil }

	SeaNeeds = {}

	SeaTravelRank = {
		Manual = 0,
		Sea2 = 1,
		Sea3 = 2,
		Sword = 3,
		Style = 4,
		Awaken = 5,
	}

	local SeaNeedLife = 12
	local SeaHopLife = 30

	function NoteSeaNeed(Owner, Sea)
		SeaNeeds[Owner] = { Sea = Sea, Until = tick() + SeaNeedLife }
	end

	function LiveSeaNeeds()
		local Now, Live = tick(), {}

		for Owner, Need in pairs(SeaNeeds) do
			if Now > Need.Until then
				SeaNeeds[Owner] = nil
			else
				Live[Owner] = Need.Sea
			end
		end

		return Live
	end

	function SeaHopInFlight()
		return tick() < SeaHop.Until and CurrentSea() ~= SeaHop.Target
	end

	function MarkSeaHop(Owner, Target)
		SeaHop.Owner, SeaHop.Target, SeaHop.Until = Owner, Target, tick() + SeaHopLife
	end

	function MaySeaTravel(Owner, Target)
		NoteSeaNeed(Owner, Target)

		local Best, BestRank
		for Name in pairs(LiveSeaNeeds()) do
			local Rank = SeaTravelRank[Name] or 99
			if not BestRank or Rank < BestRank then
				Best, BestRank = Name, Rank
			end
		end

		if Best == nil or Best == Owner then
			return true
		end

		return false, "Waiting: " .. Best .. " needs Sea " .. tostring(SeaNeeds[Best].Sea)
	end

	function ScanSeaNpc(Number)
		local Root = workspace:FindFirstChild("Npc_Workspace")
		if not Root then
			return nil
		end

		local Wanted = "Sea " .. Number

		for _, Model in ipairs(Root:GetDescendants()) do
			if Model.Name == Wanted then
				local Remote = Model:FindFirstChild("Teleport") or Model:FindFirstChild("Interact")
				if Remote then
					return { Model = Model, Remote = Remote }
				end
			end
		end

		return nil
	end

	function CallSeaNpc(Entry)
		local Remote = Entry.Remote
		local Argument = Remote.Name == "Teleport" and nil or "Teleport"

		return pcall(function()
			if Remote:IsA("RemoteFunction") then
				return Remote:InvokeServer(Argument)
			end
			Remote:FireServer(Argument)
		end)
	end

	function CrossToSea3()
		local Remote = WaitForThing(GetGatekeeperRemote, 8)
		if not Remote then
			return false
		end

		pcall(function()
			Remote:InvokeServer("Teleport")
		end)
		return true
	end

	function RideToSea(Sea, Target, Owner)
		local Hub = SeaHubs[Sea]
		if not Hub then
			return false
		end

		HoldAt(Hub.Spot, 1.5)

		local Entry = WaitForThing(function()
			return ScanSeaNpc(Target)
		end, 8)

		if Entry then
			local Spot = ResolvePosition(Entry.Model)
			if Spot then
				HoldAt(Spot, 1)
			end

			CallSeaNpc(Entry)
			MarkSeaHop(Owner or "Manual", Target)
			return true
		end

		if Target == 3 and Sea == 2 and CrossToSea3() then
			MarkSeaHop(Owner or "Manual", Target)
			return true
		end

		return false
	end

	function SeaUnlocked(Number)
		if Number <= 1 then
			return true
		end
		if Number == 2 then
			return IsSea2Unlocked()
		end
		if Number == 3 then
			return IsSea2Unlocked() and IsSea3Unlocked()
		end
		return false
	end

	function StepTowardSea(Target, Owner)
		Owner = Owner or "Manual"

		local Sea = CurrentSea()

		if not Sea then
			return false, "Not in one of the three seas"
		end

		if Sea == Target then
			SeaHop.Until = 0
			return true, "In Sea " .. Target
		end

		if SeaHopInFlight() then
			return false, "Crossing to Sea " .. tostring(SeaHop.Target) .. ", waiting for the place to load"
		end

		local May, Why = MaySeaTravel(Owner, Target)
		if not May then
			return false, Why
		end

		local Step = Target > Sea and Sea + 1 or Sea - 1

		if Step > Sea and not SeaUnlocked(Step) then
			return false, "Sea " .. Step .. " is not unlocked yet"
		end

		if not RideToSea(Sea, Step, Owner) then
			return false, "Sea " .. Step .. " NPC not found at " .. (SeaHubs[Sea] and SeaHubs[Sea].Where or "this sea")
		end

		return false, "Crossing to Sea " .. Step
	end
	(function()
		local SeaTeleportSection =
			TeleportTab:Section({ Title = "tr:SeaTeleportSection", Icon = "ship", Opened = true })
		local Driving = false

		local function ManualTarget()
			local Value = tonumber(getgenv().Settings.ManualSeaTarget)
			return (Value and SeaPlaceIds[Value]) and Value or nil
		end

		local function ClearManualTarget()
			if getgenv().Settings.ManualSeaTarget ~= 0 then
				getgenv().Settings.ManualSeaTarget = 0
				SaveSetting()
			end
		end

		local function ConflictingNeeds(Number)
			local Names = {}

			for Owner, Want in pairs(LiveSeaNeeds()) do
				if Owner ~= "Manual" and Want ~= Number then
					table.insert(Names, Owner .. " (Sea " .. tostring(Want) .. ")")
				end
			end

			table.sort(Names)
			return Names
		end

		local function DriveManualSea()
			if Driving then
				return
			end
			Driving = true

			task.spawn(function()
				local Said, Fails = nil, 0

				while Driving and IsCurrentInstance() do
					local Target = ManualTarget()
					if not Target then
						break
					end

					if not CurrentSea() then
						ClearManualTarget()
						break
					end

					NoteSeaNeed("Manual", Target)

					local Before = SeaHop.Until
					local Arrived, Status = StepTowardSea(Target, "Manual")

					if Arrived then
						ClearManualTarget()
						WindUI:Notify({ Title = "Sea " .. Target, Content = Status, Duration = 5 })
						break
					end

					if SeaHop.Until ~= Before then
						Fails = 0
					elseif not SeaHopInFlight() then
						Fails = Fails + 1
					end

					if Status ~= Said then
						Said = Status
						WindUI:Notify({ Title = "Sea " .. Target, Content = Status, Duration = 4 })
					end

					if Fails >= 8 then
						ClearManualTarget()
						WindUI:Notify({
							Title = "Sea " .. Target,
							Content = "Gave up. " .. Status,
							Duration = 8,
						})
						break
					end

					task.wait(3)
				end

				Driving = false
			end)
		end

		local function TravelToSea(Number)
			local Sea = CurrentSea()

			if Sea == Number then
				ClearManualTarget()
				WindUI:Notify({
					Title = "Sea " .. Number,
					Content = "You are already in Sea " .. Number .. ".",
					Duration = 4,
				})
				return
			end

			if Driving then
				WindUI:Notify({
					Title = "Sea " .. Number,
					Content = "Already on the way to Sea " .. tostring(ManualTarget()) .. ".",
					Duration = 5,
				})
				return
			end

			if SeaHopInFlight() then
				WindUI:Notify({
					Title = "Sea " .. Number,
					Content = "Already crossing to Sea " .. tostring(SeaHop.Target) .. ". Wait for the place to load.",
					Duration = 5,
				})
				return
			end

			if Number >= 2 and not IsSea2Unlocked() then
				WindUI:Notify({
					Title = "Sea " .. Number,
					Content = "Sea 2 is not unlocked yet. Use Auto Sea 2 first.",
					Duration = 5,
				})
				return
			end

			if Number == 3 and not IsSea3Unlocked() then
				WindUI:Notify({
					Title = "Sea 3",
					Content = "Sea 3 is not unlocked yet. Use Auto Sea 3 first.",
					Duration = 5,
				})
				return
			end

			if not (SeaPlaceIds[Number] and Sea and SeaHubs[Sea]) then
				WindUI:Notify({
					Title = "Sea " .. Number,
					Content = "This place is not one of the three seas.",
					Duration = 4,
				})
				return
			end

			local Fighting = ConflictingNeeds(Number)

			if #Fighting > 0 then
				WindUI:Notify({
					Title = "Sea " .. Number,
					Content = "Going anyway, but "
						.. table.concat(Fighting, ", ")
						.. " will cross back once you arrive. Turn it off to stay.",
					Duration = 8,
				})
			end

			getgenv().Settings.ManualSeaTarget = Number
			SaveSetting()

			WindUI:Notify({
				Title = "Sea " .. Number,
				Content = math.abs(Number - Sea) > 1
						and ("Two hops. Going through Sea " .. (Number > Sea and Sea + 1 or Sea - 1) .. " first, then on to Sea " .. Number .. " by itself.")
					or ("Flying to the sea NPC at " .. SeaHubs[Sea].Where .. "..."),
				Duration = 5,
			})

			DriveManualSea()
		end

		SeaTeleportSection:Button({
			Title = "tr:TeleportSea1",
			Desc = "tr:TeleportSea1Desc",
			Callback = function()
				TravelToSea(1)
			end,
		})

		SeaTeleportSection:Button({
			Title = "tr:TeleportSea2",
			Desc = "tr:TeleportSea2Desc",
			Callback = function()
				TravelToSea(2)
			end,
		})

		SeaTeleportSection:Button({
			Title = "tr:TeleportSea3",
			Desc = "tr:TeleportSea3Desc",
			Callback = function()
				TravelToSea(3)
			end,
		})

		task.defer(function()
			local Target = ManualTarget()

			if not Target then
				return
			end

			if CurrentSea() == Target then
				ClearManualTarget()
				WindUI:Notify({ Title = "Sea " .. Target, Content = "Arrived in Sea " .. Target .. ".", Duration = 5 })
				return
			end

			DriveManualSea()
		end)
	end)()

	local SeaSection = Automatic:Section({ Title = "tr:SeaSection", Icon = "ship", Opened = true })

	local Sea2Running = false
	local Sea2Toggle

	VenuzToggle.Sea2 = function(Value)
		getgenv().Settings.AutoSea2 = Value
		SaveSetting()

		if not Value then
			Sea2Running = false
			return
		end

		if CurrentSea() ~= 1 then
			getgenv().Settings.AutoSea2 = false
			SaveSetting()
			SetToggleValue(Sea2Toggle, false)
			return
		end

		if Sea2Running then
			return
		end
		Sea2Running = true

		task.spawn(function()
			while Sea2Running do
				if not IsCurrentInstance() then
					Sea2Running = false
					break
				end

				local ReturnCFrame = nil
				local Root = GetRoot()
				if Root then
					ReturnCFrame = Root.CFrame
				end

				local ok, Done = pcall(StepSea2)

				if ok and Done then
					Sea2Running = false
					getgenv().Settings.AutoSea2 = false
					SaveSetting()
					SetToggleValue(Sea2Toggle, false)
					WindUI:Notify({ Title = "Auto Sea 2", Content = Sea2Status, Duration = 5 })
					break
				end

				if ReturnCFrame then
					Teleport(ReturnCFrame)
				end

				WindUI:Notify({ Title = "Auto Sea 2", Content = Sea2Status, Duration = 3 })
				task.wait(10)
			end
		end)
	end

	Sea2Toggle = SeaSection:Toggle({
		Title = "tr:AutoSea2",
		Path = "AutoSea2",
		Desc = "tr:AutoSea2Desc",

		Value = getgenv().Settings.AutoSea2,
		Icon = "check",
		Callback = VenuzToggle.Sea2,
	})

	if getgenv().Settings.AutoSea2 then
		task.defer(VenuzToggle.Sea2, true)
	end

	local function GetRedEmperor()
		local function Match(Model)
			if not Model:IsA("Model") then
				return nil
			end

			if (string.gsub(GetMobName(Model), "%d+$", "")) ~= "Red Emperor" then
				return nil
			end

			local Humanoid = Model:FindFirstChildOfClass("Humanoid")
			local MobRoot = Model:FindFirstChild("HumanoidRootPart")

			if Humanoid and MobRoot and Humanoid.Health > 0 then
				return { Mob = Model, Root = MobRoot, Humanoid = Humanoid }
			end

			return nil
		end

		for _, Entry in ipairs(IterNPCs()) do
			if (string.gsub(GetMobName(Entry.Mob), "%d+$", "")) == "Red Emperor" then
				return Entry
			end
		end

		for _, Mob in ipairs(workspace:GetChildren()) do
			local Found = Match(Mob)
			if Found then
				return Found
			end
		end

		return nil
	end

	local function Sea3Weapon()
		local Weapon = FarmWeaponName()
		if Weapon ~= "" then
			return Weapon
		end

		return GetWeaponList()[1]
	end

	local function Sea3FightActive()
		local Gui = LocalPlayer:FindFirstChild("PlayerGui")
		return Gui ~= nil and Gui:FindFirstChild("TimerGUI") ~= nil
	end

	local Sea3Status = "-"
	local Sea3Running = false
	local Sea3BossSeen = 0
	local Sea3LastAttack = 0
	local Sea3AttackDelay = 0.15

	VenuzToggle.Sea3 = function(Value)
		getgenv().Settings.AutoSea3 = Value
		SaveSetting()

		if not Value then
			Sea3Running = false
			EndRunner("Sea3")
			return
		end

		if CurrentSea() ~= 2 then
			getgenv().Settings.AutoSea3 = false
			SaveSetting()
			SetToggleValue(Sea3Toggle, false)
			WindUI:Notify({ Title = "Auto Sea 3", Content = "This only works in the Sea 2 place.", Duration = 5 })
			return
		end

		if Sea3Running then
			return
		end

		SetToggleValue(AutoFarmToggle, false)
		SetToggleValue(VenuzToggle.BossToggle, false)
		SetToggleValue(VenuzToggle.MobToggle, false)
		StopAllBosses()

		Sea3Running = true
		BeginRunner("Sea3")

		task.spawn(function()
			local Finished = false

			while Sea3Running do
				task.wait()

				if not IsCurrentInstance() then
					break
				end

				if getgenv().Settings.AutoFarmLevel.Enabled or getgenv().Settings.AutoFarmBoss.Enabled then
					Sea3Status = "Stopped: another farm is running"
					getgenv().Settings.AutoSea3 = false
					SaveSetting()
					SetToggleValue(Sea3Toggle, false)
					WindUI:Notify({ Title = "Auto Sea 3", Content = Sea3Status, Duration = 5 })
					break
				end

				local Ok = pcall(function()
					if not IsAlive() then
						LockCFrame = nil
						HoldCFrame = nil
						CancelTween()
						task.wait(1)
						return
					end

					NoteSeaNeed("Sea3", IsSea3Unlocked() and 3 or 2)

					if IsSea3Unlocked() then
						if SeaHopInFlight() then
							Sea3Status = "Crossing to Sea 3, waiting for the place to load"
							task.wait(2)
							return
						end

						local May, Why = MaySeaTravel("Sea3", 3)
						if not May then
							Sea3Status = Why
							task.wait(2)
							return
						end

						Sea3Status = "Teleporting to Sea 3"
						LockCFrame = nil
						CancelTween()
						HoldAt(Sea3.NpcSpot, 1)

						local Remote = WaitForThing(GetGatekeeperRemote, 8)
						if not Remote then
							Sea3Status = "Gatekeeper not loaded"
							task.wait(2)
							return
						end

						pcall(function()
							Remote:InvokeServer("Teleport")
						end)
						MarkSeaHop("Sea3", 3)
						Sea3Status = "Crossing to Sea 3"
						Finished = true
						return
					end

					local Target = GetRedEmperor()
					if Target then
						if Sea3BossSeen == 0 then
							Sea3BossSeen = tick()
						end

						if not Sea3FightActive() and tick() - Sea3BossSeen < 25 then
							Sea3Status = "Waiting for cutscene"
							LockCFrame = nil
							CancelTween()
							StopRender()
							task.wait(0.5)
							return
						end

						StartRender()
						Sea3Status = "Fighting Red Emperor"

						local Root = GetRoot()
						if not Root then
							return
						end

						local Tool = EquipWeapon(Sea3Weapon())
						local Stand = GetAttackCFrame(Target.Root.CFrame)

						if (Root.Position - Stand.Position).Magnitude > 30 then
							LockCFrame = nil
							TravelTo(Stand, 30)
							return
						end

						CancelTween()
						LockCFrame = Stand

						if tick() - Sea3LastAttack >= Sea3AttackDelay then
							Sea3LastAttack = tick()
							task.spawn(AttackWith, Tool, Target.Root)
						end

						return
					end

					Sea3BossSeen = 0

					if LevelValue.Value < Sea3.NeedLevel then
						Sea3Status = "Need level " .. Sea3.NeedLevel
						LockCFrame = nil
						task.wait(5)
						return
					end

					Sea3Status = "Talking to Gatekeeper"
					LockCFrame = nil
					CancelTween()
					HoldAt(Sea3.NpcSpot, 1)

					local Remote = WaitForThing(GetGatekeeperRemote, 8)
					if not Remote then
						Sea3Status = "Gatekeeper not loaded"
						task.wait(2)
						return
					end

					local Retry = false
					pcall(function()
						Retry = Remote:InvokeServer("CheckForRetry") == true
					end)

					if Retry then
						pcall(function()
							Remote:InvokeServer("Retry")
						end)
					else
						pcall(function()
							Remote:InvokeServer()
						end)
					end

					LockCFrame = nil
					CancelTween()
					StopRender()

					local Deadline = tick() + 20
					while Sea3Running and tick() < Deadline and not GetRedEmperor() do
						task.wait(0.5)
					end
				end)

				if Finished then
					break
				end

				if not Ok then
					task.wait(0.25)
				end
			end

			Sea3Running = false
			EndRunner("Sea3")

			if Finished then
				getgenv().Settings.AutoSea3 = false
				SaveSetting()
				SetToggleValue(Sea3Toggle, false)
				WindUI:Notify({ Title = "Auto Sea 3", Content = Sea3Status, Duration = 5 })
			end
		end)
	end

	Sea3Toggle = SeaSection:Toggle({
		Title = "tr:AutoSea3",
		Path = "AutoSea3",
		Desc = "tr:AutoSea3Desc",

		Value = getgenv().Settings.AutoSea3,
		Icon = "check",
		Callback = VenuzToggle.Sea3,
	})

	if getgenv().Settings.AutoSea3 then
		task.defer(VenuzToggle.Sea3, true)
	end
end

do
	local SwordTab = TabGroups.Item:Tab({
		Title = "tr:SwordTab",
		Icon = "sword",
		Locked = false,
	})

	SwordDrivePriority = 1.5

	function OwnsSword(Name)
		if type(Name) == "table" then
			for _, Alias in ipairs(Name) do
				if OwnsSword(Alias) then
					return true
				end
			end

			return false
		end

		if type(Name) ~= "string" or Name == "" then
			return false
		end

		local Folder = PlayerData:FindFirstChild("Sword")
		local Owned = Folder and Folder:FindFirstChild("OwnedSwords")

		if Owned and type(Owned.Value) == "string" and Owned.Value ~= "" then
			local Ok, Decoded = pcall(function()
				return HttpService:JSONDecode(Owned.Value)
			end)

			if Ok and type(Decoded) == "table" then
				for Key, Value in pairs(Decoded) do
					if Value == Name or (Value == true and Key == Name) then
						return true
					end
				end
			end
		end

		return ToolNamed(Name) ~= nil
	end

	function SetElementTitle(Element, Text)
		if type(Element) ~= "table" then
			return false
		end

		if pcall(function()
			Element:SetTitle(Text)
		end) then
			return true
		end

		pcall(function()
			Element.Title = Text
		end)
		return false
	end

	local MarineBase = {
		KeyPoi = "Lava Key",
		KeyTool = "Lava Key",
		DoorPoi = "MarineBaseCageDoor",
		CauldronPoi = "MarineBaseCauldron",
	}

	local function PointsOfInterest()
		local Logic = workspace:FindFirstChild("Logic")
		return Logic and Logic:FindFirstChild("PointsOfInterest")
	end

	local function PoiPrompt(Name)
		local POI = PointsOfInterest()
		local Model = POI and POI:FindFirstChild(Name)

		if not Model then
			return nil, nil
		end

		return Model:FindFirstChildWhichIsA("ProximityPrompt", true), ResolvePosition(Model)
	end

	local function LavaKeyTool()
		return ToolNamed(MarineBase.KeyTool)
	end

	local function LavaKeyModel()
		local POI = PointsOfInterest()
		return POI and POI:FindFirstChild(MarineBase.KeyPoi)
	end

	local function TakeLavaKey(Hunt, Root)
		if LavaKeyTool() then
			return true
		end

		local Model = LavaKeyModel()

		if not Model then
			Hunt.Status = "Lava Key is not on the map"
			task.wait(1)
			return false
		end

		local Spot = ResolvePosition(Model)
		if not Spot then
			Hunt.Status = "Lava Key has not streamed in"
			task.wait(0.5)
			return false
		end

		local Stand = CFrame.new(Spot + Vector3.new(0, 5, 0))

		if (Root.Position - Stand.Position).Magnitude > 12 then
			Hunt.Status = "Flying to the Lava Key"
			LockCFrame = nil
			TravelTo(Stand, 12)
			return false
		end

		CancelTween()
		LockCFrame = Stand
		Hunt.Status = "Taking the Lava Key"

		local Pick = Model:FindFirstChild("Pick", true)

		if Pick then
			pcall(function()
				if Pick:IsA("RemoteFunction") then
					Pick:InvokeServer()
				else
					Pick:FireServer()
				end
			end)
		else
			FirePrompt(Model:FindFirstChildWhichIsA("ProximityPrompt", true))
		end

		task.wait(0.5)
		return LavaKeyTool() ~= nil
	end

	local function OpenMarineCage(Hunt, Root)
		local Prompt, Spot = PoiPrompt(MarineBase.DoorPoi)

		if not Spot then
			Hunt.Status = "Cage door has not streamed in"
			task.wait(0.5)
			return
		end

		if not (LavaKeyTool() or TakeLavaKey(Hunt, Root)) then
			return
		end

		local Stand = CFrame.new(Spot + Vector3.new(0, 5, 0))

		if (Root.Position - Stand.Position).Magnitude > 12 then
			Hunt.Status = "Taking the Lava Key to the cage"
			LockCFrame = nil
			TravelTo(Stand, 12)
			return
		end

		CancelTween()
		LockCFrame = Stand

		if not Prompt then
			Hunt.Status = "Cage door prompt is not there yet"
			task.wait(0.5)
			return
		end

		EquipWeapon(MarineBase.KeyTool)
		Hunt.Status = "Opening the Marine Base cage"
		FirePrompt(Prompt)

		Hunt.CageOpened = true
		task.wait(1)
	end

	local function SummonMaceBoss(Hunt, Root)
		if not Hunt.CageOpened and (LavaKeyModel() or LavaKeyTool()) then
			OpenMarineCage(Hunt, Root)
			return
		end

		local Prompt, Spot = PoiPrompt(MarineBase.CauldronPoi)

		if not Spot then
			Hunt.Status = "Cauldron has not streamed in"
			task.wait(0.5)
			return
		end

		local Stand = CFrame.new(Spot + Vector3.new(0, 5, 0))

		if (Root.Position - Stand.Position).Magnitude > 12 then
			Hunt.Status = "Taking the " .. Hunt.Item .. " to the cauldron"
			LockCFrame = nil
			TravelTo(Stand, 12)
			return
		end

		CancelTween()
		LockCFrame = Stand

		if not Prompt then
			Hunt.Status = "Cauldron prompt is not there yet"
			task.wait(0.5)
			return
		end

		EquipWeapon(Hunt.Item)
		Hunt.Status = "Summoning " .. Hunt.Boss
		FirePrompt(Prompt)
		task.wait(2)

		if not ToolNamed(Hunt.Item) then
			Hunt.SummonFails = 0
			return
		end

		Hunt.SummonFails = (Hunt.SummonFails or 0) + 1

		if Hunt.SummonFails >= 3 then
			Hunt.SummonFails = 0
			Hunt.CageOpened = false
		end
	end

	local SwordHunts = {
		{
			Key = "SharkBlade",
			Sword = "Shark Blade",
			Label = "Auto Shark Blade",
			Setting = "AutoSharkBlade",
			Desc = "tr:SharkBladeDesc",
			Sea = 1,
			Mob = "Shark Boss",
			NeedLevel = 120,
		},
		{
			Key = "TwoSwordStyle",
			Sword = "2 Sword Style",
			Label = "Auto 2SS",
			Setting = "Auto2SS",
			Desc = "tr:TwoSwordStyleDesc",
			Sea = 1,

			Mob = "Dual Swordsman",
			Spot = Vector3.new(-2994, 61.6, 2140.6),
			Item = "Book",
			Npc = "Doctor White",
			NpcSpot = Vector3.new(-2859.6, 18.3, 1412.9),
		},
		{
			Key = "GoldenStaff",
			Sword = "Golden Staff",
			Label = "Auto Golden Staff",
			Setting = "AutoGoldenStaff",
			Desc = "tr:GoldenStaffDesc",
			Sea = 1,
			Mob = "Thunder God",
			NeedLevel = 1100,
		},
		{
			Key = "Shushi",
			Sword = "Shushi",
			Label = "Auto Shushi",
			Setting = "AutoShushi",
			Desc = "tr:ShushiDesc",
			Sea = 1,
			Mob = "Ryummy",
			NeedLevel = 2150,

			Names = { "Shushi", "Shusui", "Sushi", "Shushui", "Shusi" },
		},
		{
			Key = "Raiu",
			Sword = "Raiu",
			Label = "Auto Raiu",
			Setting = "AutoRaiu",
			Desc = "tr:RaiuDesc",
			Sea = 1,
			Mob = "Shiryu",
			NeedLevel = 1850,

			Item = "Scroll",
			Npc = "Scroll Merchant",
			NpcSpot = Vector3.new(5542.9, 122.1, -39.6),
			GiveRemote = "GetSwordFromNPC",
			GiveArg = "Raiu",
			NeedBeli = 75000,
		},
		{
			Key = "FishmanTrident",
			Sword = "Fishman Trident",
			Label = "Auto Fishman Trident",
			Setting = "AutoFishmanTrident",
			Desc = "tr:FishmanTridentDesc",
			Sea = 1,
			Mob = "Neptune",
			NeedLevel = 1700,

			Item = "Fork",
			Npc = "Fork Merchant",
			NpcSpot = Vector3.new(4445.8, 120.2, -3078.2),
			GiveRemote = "GetSwordFromNPC",
			GiveArg = "Fishman Trident",
			NeedBeli = 50000,
		},
		{
			Key = "Mace",
			Sword = "Mace",
			Label = "Auto Mace",
			Setting = "AutoMace",
			Desc = "tr:MaceDesc",
			Sea = 1,
			Mob = "Marine Captain",
			NeedLevel = 650,

			Item = "Lava Ore",
			Deliver = SummonMaceBoss,
			Boss = "Mace Boss",
		},
	}

	local SwordSections = {}

	local function SwordSectionFor(Sea)
		if not SwordSections[Sea] then
			SwordSections[Sea] = SwordTab:Section({
				Title = "tr:SwordSea" .. Sea .. "Section",
				Icon = "sword",
				Opened = true,
			})
		end

		return SwordSections[Sea]
	end

	local function SwordHuntWeapon()
		local Weapon = FarmWeaponName()
		if Weapon ~= "" then
			return Weapon
		end

		return GetWeaponList()[1]
	end

	local function SwordHuntTitle(Hunt)
		if OwnsSword(Hunt.Names or Hunt.Sword) then
			return Hunt.Label .. " [Owner]"
		end

		return Hunt.Label
	end

	local function SwordHuntSpot(Hunt)
		if Hunt.Spot then
			return Hunt.Spot
		end

		local Entry = FindEntryByMob(Hunt.Mob)
		return Entry and (Entry.MonPOS or Entry.WaitPOS) or nil
	end

	local SwordNpcRemotes = { "Interact", "Talk", "Give", "Trade", "Buy", "Teleport" }

	local SwordNpcCache = {}

	local function FindSwordNpc(Name)
		if type(Name) ~= "string" or Name == "" then
			return nil, nil
		end

		local Cached = SwordNpcCache[Name]
		if Cached and tick() - Cached.At < 1 and (Cached.Model == nil or Cached.Model.Parent) then
			return Cached.Model, Cached.Remote
		end

		local Root = workspace:FindFirstChild("Npc_Workspace")
		if not Root then
			return nil, nil
		end

		local Wanted = string.lower(Name)

		local function Remember(Model, Remote)
			SwordNpcCache[Name] = { Model = Model, Remote = Remote, At = tick() }
			return Model, Remote
		end

		for _, Object in ipairs(Root:GetDescendants()) do
			if string.find(string.lower(Object.Name), Wanted, 1, true) then
				for _, Key in ipairs(SwordNpcRemotes) do
					local Remote = Object:FindFirstChild(Key)
					if Remote and (Remote:IsA("RemoteFunction") or Remote:IsA("RemoteEvent")) then
						return Remember(Object, Remote)
					end
				end

				if Object:IsA("Model") then
					return Remember(Object, nil)
				end
			end
		end

		return Remember(nil, nil)
	end

	local function DeliverSwordItem(Hunt, Root)
		local Item = Hunt.Item
		local Model, Remote = FindSwordNpc(Hunt.Npc)
		local Spot = Hunt.NpcSpot or (Model and ResolvePosition(Model))

		if not Spot then
			Hunt.Status = Hunt.Npc .. " has not loaded yet"
			LockCFrame = nil
			task.wait(1)
			return
		end

		if Hunt.NeedBeli and Hunt.NeedBeli > 0 and CurrencyValue.Value < Hunt.NeedBeli then
			Hunt.Status = Hunt.Npc
				.. " wants $"
				.. RT.Num(Hunt.NeedBeli)
				.. " (now $"
				.. RT.Num(CurrencyValue.Value)
				.. ")"
			LockCFrame = nil
			IdleRunner(Hunt.Key)
			task.wait(2)
			return
		end

		local Stand = CFrame.new(Spot + Vector3.new(0, 5, 0))

		if (Root.Position - Stand.Position).Magnitude > 10 then
			Hunt.Status = "Taking the " .. Item .. " to " .. Hunt.Npc
			LockCFrame = nil
			TravelTo(Stand, 10)
			return
		end

		CancelTween()
		LockCFrame = Stand

		local Shared = Hunt.GiveRemote and ClientEvents:FindFirstChild(Hunt.GiveRemote) or nil

		if not (Remote or Shared) then
			Hunt.Status = "Waiting for " .. Hunt.Npc .. " to load"
			task.wait(0.5)
			return
		end

		EquipWeapon(Item)

		if tick() - Hunt.LastTalk < 2 then
			task.wait(0.2)
			return
		end

		local Arg = Hunt.GiveArg or Hunt.Sword

		Hunt.LastTalk = tick()
		Hunt.Status = "Trading the " .. Item .. " for " .. Hunt.Sword

		pcall(function()
			if Shared then
				if Shared:IsA("RemoteFunction") then
					Shared:InvokeServer(Arg)
				else
					Shared:FireServer(Arg)
				end
			elseif Remote:IsA("RemoteFunction") then
				Remote:InvokeServer()
			else
				Remote:FireServer()
			end
		end)

		task.wait(0.5)
	end

	local function FightHuntTarget(Hunt, Root, Name, Target, Wanted)
		local Tool = EquipWeapon(SwordHuntWeapon())
		local MobRoot = Target.Root
		local Stand = GetAttackCFrame(MobRoot.CFrame)

		if (Root.Position - Stand.Position).Magnitude > 30 then
			Hunt.Status = "Flying to " .. Name
			LockCFrame = nil
			TravelTo(Stand, 30)
			return
		end

		Hunt.Status = "Fighting " .. Name .. " for " .. Wanted
		CancelTween()
		LockCFrame = Stand

		if tick() - Hunt.LastAttack >= Hunt.AttackDelay then
			Hunt.LastAttack = tick()
			task.spawn(AttackWith, Tool, MobRoot)
		end
	end

	local function StopSwordHunt(Hunt)
		Hunt.Running = false

		local Loop = Hunt.Loop
		Hunt.Loop = nil

		if Loop and Loop ~= coroutine.running() then
			pcall(function()
				task.cancel(Loop)
			end)
		end

		EndRunner(Hunt.Key)
	end

	local function FinishSwordHunt(Hunt, Text)
		Hunt.Status = Text
		getgenv().Settings[Hunt.Setting] = false
		SaveSetting()
		StopSwordHunt(Hunt)
		SetToggleValue(Hunt.Toggle, false)
		SetElementTitle(Hunt.Toggle, SwordHuntTitle(Hunt))
		WindUI:Notify({ Title = Hunt.Label, Content = Text, Duration = 6 })
	end

	local function SwordHuntStep(Hunt)
		if OwnsSword(Hunt.Names or Hunt.Sword) then
			Hunt.Finished = Hunt.Sword .. " is yours. Stopping."
			return
		end

		if not IsAlive() then
			LockCFrame = nil
			HoldCFrame = nil
			CancelTween()
			task.wait(1)
			return
		end

		NoteSeaNeed("Sword", Hunt.Sea)

		if CurrentSea() ~= Hunt.Sea then
			if not ClaimDrive(Hunt.Key, SwordDrivePriority) then
				Hunt.Status = "A boss farm is driving, waiting"
				task.wait(0.3)
				return
			end

			StartRender()
			LockCFrame = nil
			CancelTween()

			local _, Status = StepTowardSea(Hunt.Sea, "Sword")
			Hunt.Status = Status
			task.wait(5)
			return
		end

		if Hunt.NeedLevel > 0 and LevelValue.Value < Hunt.NeedLevel then
			Hunt.Status = "Need level " .. Hunt.NeedLevel .. " (now " .. LevelValue.Value .. ")"
			IdleRunner(Hunt.Key)
			task.wait(2)
			return
		end

		local Spot = SwordHuntSpot(Hunt)

		if not Spot then
			Hunt.Status = Hunt.Mob .. " has no known spot"
			IdleRunner(Hunt.Key)
			task.wait(5)
			return
		end

		if not ClaimDrive(Hunt.Key, SwordDrivePriority) then
			Hunt.Status = "A boss farm is driving, waiting"
			task.wait(0.3)
			return
		end

		local Root = GetRoot()
		if not Root then
			return
		end

		if Hunt.Boss then
			local Summoned = FindMobs(Hunt.Boss, Root.Position)[1]

			if Summoned then
				StartRender()
				FightHuntTarget(Hunt, Root, Hunt.Boss, Summoned, Hunt.Sword)
				return
			end
		end

		if Hunt.Item and ToolNamed(Hunt.Item) then
			StartRender();
			(Hunt.Deliver or DeliverSwordItem)(Hunt, Root)
			return
		end

		if KeepBossQuest(Hunt.Mob) then
			return
		end

		StartRender()

		local Target = FindMobs(Hunt.Mob, Root.Position)[1]

		if not Target then
			local State = BossWaitAt(Hunt.Key, Spot)

			if State == "Flying" then
				Hunt.Status = "Flying to " .. Hunt.Mob
			elseif State == "Farming" then
				Hunt.Status = "Waiting for " .. Hunt.Mob .. " - farming the mobs around it"
			else
				Hunt.Status = "Waiting for " .. Hunt.Mob .. " to respawn"
			end

			task.wait(0.5)
			return
		end

		FightHuntTarget(Hunt, Root, Hunt.Mob, Target, Hunt.Item or Hunt.Sword)
	end

	local function SyncSwordHunt(Hunt)
		if getgenv().Settings[Hunt.Setting] ~= true then
			Hunt.Status = "Idle"
			StopSwordHunt(Hunt)
			return
		end

		if OwnsSword(Hunt.Names or Hunt.Sword) then
			Hunt.Status = "You already own " .. Hunt.Sword
			StopSwordHunt(Hunt)
			SetElementTitle(Hunt.Toggle, SwordHuntTitle(Hunt))
			WindUI:Notify({ Title = Hunt.Label, Content = Hunt.Status, Duration = 5 })
			return
		end

		if Hunt.Running then
			return
		end

		if not RequireWeapon(Hunt.Label, Hunt.Toggle) then
			getgenv().Settings[Hunt.Setting] = false
			SaveSetting()
			return
		end

		Hunt.Running = true
		Hunt.Finished = nil
		BeginRunner(Hunt.Key)

		Hunt.Loop = task.spawn(function()
			while Hunt.Running do
				task.wait()

				if not IsCurrentInstance() then
					Hunt.Running = false
					EndRunner(Hunt.Key)
					break
				end

				if not pcall(SwordHuntStep, Hunt) then
					task.wait(0.25)
				end

				if Hunt.Finished then
					local Text = Hunt.Finished
					Hunt.Finished = nil
					FinishSwordHunt(Hunt, Text)
					break
				end
			end
		end)
	end

	local SwordParagraphs = {}
	local SwordBySea = {}

	for _, Hunt in ipairs(SwordHunts) do
		Hunt.Status = "Idle"
		Hunt.Running = false
		Hunt.LastAttack = 0
		Hunt.LastTalk = 0
		Hunt.AttackDelay = 0.15
		Hunt.NeedLevel = Hunt.NeedLevel or 0

		local Section = SwordSectionFor(Hunt.Sea)

		if not SwordParagraphs[Hunt.Sea] then
			SwordParagraphs[Hunt.Sea] = RT.Status(Section, "tr:SwordSea" .. Hunt.Sea .. "Status")
			SwordBySea[Hunt.Sea] = {}
		end

		table.insert(SwordBySea[Hunt.Sea], Hunt)

		Hunt.Toggle = Section:Toggle({
			Title = SwordHuntTitle(Hunt),
			Path = Hunt.Setting,
			Desc = Hunt.Desc,

			Value = getgenv().Settings[Hunt.Setting],
			Icon = "check",
			Callback = function(Value)
				getgenv().Settings[Hunt.Setting] = Value
				SaveSetting()
				SyncSwordHunt(Hunt)
			end,
		})

		if getgenv().Settings[Hunt.Setting] then
			task.defer(SyncSwordHunt, Hunt)
		end
	end

	for Sea, List in pairs(SwordBySea) do
		task.spawn(function()
			while task.wait(1) do
				if not IsCurrentInstance() then
					break
				end

				for _, Hunt in ipairs(List) do
					local Owned = OwnsSword(Hunt.Names or Hunt.Sword)

					if Owned ~= Hunt.WasOwned then
						Hunt.WasOwned = Owned
						SetElementTitle(Hunt.Toggle, SwordHuntTitle(Hunt))
					end
				end

				RT.Push("Sword hunts Sea " .. Sea, SwordParagraphs[Sea], function()
					local Lines = { RT.Head("Sea " .. Sea .. " Swords", RT.Amber) }
					local Working = false

					for _, Hunt in ipairs(List) do
						if Hunt.Running then
							Working = true
							RT.Add(Lines, RT.Field("Hunting", Hunt.Sword, RT.Amber))
							RT.Add(Lines, RT.State(Hunt.Status, true))
						end
					end

					if not Working then
						RT.Add(Lines, RT.State("Idle", false))
					end

					return table.concat(Lines, "\n")
				end)
			end
		end)
	end
end

do
	local FightStyleTab = TabGroups.Item:Tab({
		Title = "tr:FightStyleTab",
		Icon = "hand",
		Locked = false,
	})

	local StyleDrivePriority = 1.5

	local StyleBase = {
		["Black Leg"] = { NeedLevel = 1, NeedBeli = 50000, Spot = Vector3.new(-5562, 603, -2251.6) },
		["Fishman"] = { NeedLevel = 2200, NeedBeli = 450000, Spot = Vector3.new(-5442, 602.9, -2249) },
		["Electro"] = { NeedLevel = 2200, NeedBeli = 450000, Spot = Vector3.new(-5502.8, 603, -2249.1) },
		["Cyborg"] = { NeedLevel = 2200, NeedBeli = 800000, Spot = Vector3.new(-5375.7, 603.5, -2247.6) },
		["Dragon Claw"] = { NeedLevel = 2200, NeedBeli = 150, Spot = Vector3.new(-5306.8, 605.2, -2250.3) },
	}

	local SageSpot = Vector3.new(-5444.1, 603.9, -2124.8)
	local StyleMasteryNeed = 300

	local StyleUpgrades = {
		{
			Key = "BlackLegV2",
			Style = "Black Leg",
			Label = "Auto Black Leg V2",
			Setting = "AutoBlackLegV2",
			Desc = "tr:BlackLegV2Desc",
			Material = "Phantom Lantern",
			MaterialKey = "PhantomLantern",
			MaterialCount = 2,
			Currency = "Beli",
			Price = 5000000,
		},
		{
			Key = "FishmanV2",
			Style = "Fishman",
			Label = "Auto Fishman V2",
			Setting = "AutoFishmanV2",
			Desc = "tr:FishmanV2Desc",
			Material = "Seabeast Heart",
			MaterialKey = "SeabeastHeart",
			MaterialCount = 2,
			Currency = "Beli",
			Price = 5000000,
		},
		{
			Key = "CyborgV2",
			Style = "Cyborg",
			Label = "Auto Cyborg V2",
			Setting = "AutoCyborgV2",
			Desc = "tr:CyborgV2Desc",
			Material = "Saturn's Ring",
			MaterialKey = "SaturnsRing",
			MaterialCount = 2,
			Currency = "Beli",
			Price = 5000000,
		},
		{
			Key = "ElectroV2",
			Style = "Electro",
			Label = "Auto Electro V2",
			Setting = "AutoElectroV2",
			Desc = "tr:ElectroV2Desc",
			Material = "Raijin's Core",
			MaterialKey = "RaijinsCore",
			MaterialCount = 2,
			Currency = "Gems",
			Price = 500,
		},
		{
			Key = "DragonClawV2",
			Style = "Dragon Claw",
			Label = "Auto Dragon Claw V2",
			Setting = "AutoDragonClawV2",
			Desc = "tr:DragonClawV2Desc",
			Material = "Dragon Heart",
			MaterialKey = "DragonHeart",
			MaterialCount = 2,
			Currency = "Gems",
			Price = 250,
		},
	}

	local function OwnedStyles()
		local Value = PlayerData:FindFirstChild("OwnedFightingStyles")

		if not Value or type(Value.Value) ~= "string" or Value.Value == "" then
			return {}
		end

		local Ok, List = pcall(function()
			return HttpService:JSONDecode(Value.Value)
		end)

		return (Ok and type(List) == "table") and List or {}
	end

	local function OwnsStyle(Name)
		for Key, Item in pairs(OwnedStyles()) do
			if Item == Name or (Item == true and Key == Name) then
				return true
			end
		end

		return false
	end

	local function StyleRank(Name)
		local Value = PlayerData:FindFirstChild("FightingStyleLevels")

		if not Value or type(Value.Value) ~= "string" or Value.Value == "" then
			return 1
		end

		local Ok, Map = pcall(function()
			return HttpService:JSONDecode(Value.Value)
		end)

		if not Ok or type(Map) ~= "table" then
			return 1
		end

		return tonumber(Map[Name]) or 1
	end

	local function HasStyleV2(Name)
		return StyleRank(Name) >= 2
	end

	local function StyleMasteryOf(Name)
		local Folder = PlayerData:FindFirstChild("Mastery")
		local Entry = Folder and Folder:FindFirstChild(Name)
		local Level = Entry and Entry:FindFirstChild(Name .. "Level")
		return Level and math.max(0, Level.Value) or 0
	end

	local function EquippedStyle()
		local Value = PlayerData:FindFirstChild("FightingStyle")
		return (Value and tostring(Value.Value)) or "Combat"
	end

	local function StyleMaterial(Key)
		local Value = PlayerData:FindFirstChild(Key)
		return (Value and tonumber(Value.Value)) or 0
	end

	local function StyleWallet(Currency)
		if Currency == "Gems" then
			local Value = PlayerData:FindFirstChild("Gems")
			return (Value and tonumber(Value.Value)) or 0
		end

		return CurrencyValue.Value
	end

	local function StyleMoneyText(Entry)
		if Entry.Currency == "Gems" then
			return RT.Num(Entry.Price) .. " gems"
		end

		return "$" .. RT.Num(Entry.Price)
	end

	local function StyleTrainer(Name)
		local Folder = NpcWorkspace:FindFirstChild("FightingStyle")
		return Folder and Folder:FindFirstChild(Name)
	end

	local function SageNpc()
		local Folder = NpcWorkspace:FindFirstChild("FightingStyleV2Upgrader")
		return Folder and Folder:FindFirstChild("Sage Of Combat")
	end

	local function StyleTitle(Entry)
		return HasStyleV2(Entry.Style) and (Entry.Label .. " [Owner]") or Entry.Label
	end

	local StyleFarmSources = {
		PhantomLantern = {
			Label = "Ghost Ship",
			Toggles = {
				{ Path = "AutoGhostShip.Enabled" },

				{
					Path = "AutoGhostShip.Summon",
					When = function()
						local Setting = getgenv().Settings.AutoGhostShip
						local List = Setting.Source == "Buy Fruit" and Setting.Rarities or Setting.Fruits
						return #NormalizeList(List) > 0
					end,
				},
			},
		},
		SeabeastHeart = {
			Label = "Sea Beast",
			Toggles = { { Path = "AutoSeaBeast.Enabled" }, { Path = "AutoSeaBeast.Find" } },
		},
		SaturnsRing = {

			Label = "Saturn Boss",
			Toggles = { { Path = "AutoSaturnBoss.Enabled" } },
		},
		RaijinsCore = {
			Label = "Raijin",
			Toggles = { { Path = "AutoRaijin.Summon" }, { Path = "AutoRaijin.Kill" } },
		},
		DragonHeart = {
			Label = "Dragon Hybrid Boss",
			Toggles = { { Path = "AutoDragonHydra.Summon" }, { Path = "AutoDragonHydra.Kill" } },
		},
	}

	local function StyleSettingAt(Path)
		local Node = getgenv().Settings

		for Part in string.gmatch(Path, "[^%.]+") do
			if type(Node) ~= "table" then
				return nil
			end
			Node = Node[Part]
		end

		return Node
	end

	local function StyleSetToggle(Path, Value)
		if StyleSettingAt(Path) == Value then
			return
		end

		for _, Entry in ipairs(ConfigWidgets) do
			if Entry.Path == Path then
				SetToggleValue(Entry.Widget, Value)

				if type(Entry.Callback) == "function" then
					pcall(Entry.Callback, Value)
				end

				return
			end
		end
	end

	local function StyleFarmStop(Entry)
		if not Entry.Turned then
			return
		end

		for Path in pairs(Entry.Turned) do
			StyleSetToggle(Path, false)
		end

		Entry.Turned = nil
	end

	local function StyleFarmStart(Entry, Source)
		Entry.Turned = Entry.Turned or {}

		for _, Toggle in ipairs(Source.Toggles) do
			local Allowed = true

			if type(Toggle.When) == "function" then
				local Ok, Result = pcall(Toggle.When)
				Allowed = Ok and Result == true
			end

			if Allowed and StyleSettingAt(Toggle.Path) ~= true then
				Entry.Turned[Toggle.Path] = true
				StyleSetToggle(Toggle.Path, true)
			end
		end
	end

	local function StyleEquip(Entry)
		if EquippedStyle() == Entry.Style then
			return true
		end

		local Swap = ClientEvents:FindFirstChild("ChangeFightingStyle")

		if not Swap then
			return false
		end

		if tick() - Entry.LastSwap >= 2 then
			Entry.LastSwap = tick()

			pcall(function()
				if Swap:IsA("RemoteFunction") then
					Swap:InvokeServer(Entry.Style)
				else
					Swap:FireServer(Entry.Style)
				end
			end)
		end

		return false
	end

	local function StandAt(Entry, Root, Spot, Status)
		local Stand = CFrame.new(Spot + Vector3.new(0, 5, 0))

		if (Root.Position - Stand.Position).Magnitude > 10 then
			Entry.Status = Status
			LockCFrame = nil
			TravelTo(Stand, 10)
			return false
		end

		CancelTween()
		LockCFrame = Stand
		return true
	end

	local function BuyStyleStep(Entry, Base)
		if LevelValue.Value < Base.NeedLevel then
			Entry.Status = "Need level "
				.. Base.NeedLevel
				.. " for "
				.. Entry.Style
				.. " (now "
				.. LevelValue.Value
				.. ")"
			IdleRunner(Entry.Key)
			task.wait(2)
			return
		end

		if CurrencyValue.Value < Base.NeedBeli then
			Entry.Status = "Need $"
				.. RT.Num(Base.NeedBeli)
				.. " for "
				.. Entry.Style
				.. " (now $"
				.. RT.Num(CurrencyValue.Value)
				.. ")"
			IdleRunner(Entry.Key)
			task.wait(2)
			return
		end

		if not ClaimDrive(Entry.Key, StyleDrivePriority) then
			Entry.Status = "A boss farm is driving, waiting"
			task.wait(0.3)
			return
		end

		local Root = GetRoot()
		if not Root then
			return
		end

		StartRender()

		local Trainer = StyleTrainer(Entry.Style)
		local Spot = (Trainer and ResolvePosition(Trainer)) or Base.Spot

		if not StandAt(Entry, Root, Spot, "Flying to the " .. Entry.Style .. " trainer") then
			return
		end

		local Remote = ClientEvents:FindFirstChild("BuyFightingStyle")

		if not Remote then
			Entry.Status = "BuyFightingStyle has not loaded yet"
			task.wait(0.5)
			return
		end

		if tick() - Entry.LastTalk < 2 then
			task.wait(0.2)
			return
		end

		Entry.LastTalk = tick()
		Entry.Status = "Buying " .. Entry.Style .. " for $" .. RT.Num(Base.NeedBeli)

		pcall(function()
			if Remote:IsA("RemoteFunction") then
				Remote:InvokeServer(Entry.Style)
			else
				Remote:FireServer(Entry.Style)
			end
		end)

		task.wait(0.5)
	end

	local function UpgradeStyleStep(Entry)
		if HasStyleV2(Entry.Style) then
			Entry.Finished = Entry.Style .. " V2 is yours. Stopping."
			return
		end

		if not OwnsStyle(Entry.Style) then
			local Base = StyleBase[Entry.Style]

			if not Base then
				Entry.Status = "No trainer known for " .. Entry.Style
				IdleRunner(Entry.Key)
				task.wait(5)
				return
			end

			BuyStyleStep(Entry, Base)
			return
		end

		local Mastery = StyleMasteryOf(Entry.Style)

		if Mastery < StyleMasteryNeed then
			StyleEquip(Entry)
			Entry.Status = "Need mastery "
				.. StyleMasteryNeed
				.. " (now "
				.. Mastery
				.. ") - farm with "
				.. Entry.Style
				.. " equipped"
			IdleRunner(Entry.Key)
			task.wait(3)
			return
		end

		local Held = StyleMaterial(Entry.MaterialKey)
		local Wallet = StyleWallet(Entry.Currency)
		local Source = StyleFarmSources[Entry.MaterialKey]

		if Held < Entry.MaterialCount or Wallet < Entry.Price then
			local Want = Held < Entry.MaterialCount
					and (Entry.MaterialCount .. "x " .. Entry.Material .. " (have " .. Held .. ")")
				or StyleMoneyText(Entry)

			if not Source then
				Entry.Status = "Need " .. Want
				IdleRunner(Entry.Key)
				task.wait(3)
				return
			end

			if not HasBossWeaponPicked() then
				Entry.Status = "Need " .. Want .. " - pick a Boss Weapon so " .. Source.Label .. " can farm"
				IdleRunner(Entry.Key)
				task.wait(5)
				return
			end

			StyleFarmStart(Entry, Source)

			Entry.Status = "Need " .. Want .. " - farming " .. Source.Label
			IdleRunner(Entry.Key)
			task.wait(3)
			return
		end

		StyleFarmStop(Entry)

		if not ClaimDrive(Entry.Key, StyleDrivePriority) then
			Entry.Status = "A boss farm is driving, waiting"
			task.wait(0.3)
			return
		end

		local Root = GetRoot()
		if not Root then
			return
		end

		StartRender()

		if not StyleEquip(Entry) then
			Entry.Status = "Equipping " .. Entry.Style
			task.wait(0.5)
			return
		end

		local Sage = SageNpc()
		local Spot = (Sage and ResolvePosition(Sage)) or SageSpot

		if not StandAt(Entry, Root, Spot, "Taking " .. Entry.Style .. " to the Sage Of Combat") then
			return
		end

		local Remote = Sage and Sage:FindFirstChild("Interact")

		if not Remote then
			Entry.Status = "Waiting for the Sage Of Combat to load"
			task.wait(0.5)
			return
		end

		if tick() - Entry.LastTalk < 2 then
			task.wait(0.2)
			return
		end

		Entry.LastTalk = tick()
		Entry.Status = "Evolving " .. Entry.Style .. " for " .. StyleMoneyText(Entry)

		local Ok, Success, Reason = pcall(function()
			if Remote:IsA("RemoteFunction") then
				return Remote:InvokeServer(Entry.Style)
			end

			Remote:FireServer(Entry.Style)
			return nil
		end)

		if Ok and Success == false and type(Reason) == "string" then
			Entry.Status = "Sage refused: " .. Reason
		end

		task.wait(1)
	end

	local function StopStyleRun(Entry)
		Entry.Running = false

		StyleFarmStop(Entry)

		local Loop = Entry.Loop
		Entry.Loop = nil

		if Loop and Loop ~= coroutine.running() then
			pcall(function()
				task.cancel(Loop)
			end)
		end

		EndRunner(Entry.Key)
	end

	local function FinishStyleRun(Entry, Text)
		Entry.Status = Text
		getgenv().Settings[Entry.Setting] = false
		SaveSetting()
		StopStyleRun(Entry)
		SetToggleValue(Entry.Toggle, false)
		SetElementTitle(Entry.Toggle, StyleTitle(Entry))
		WindUI:Notify({ Title = Entry.Label, Content = Text, Duration = 6 })
	end

	local function StyleStep(Entry)
		if not IsAlive() then
			LockCFrame = nil
			HoldCFrame = nil
			CancelTween()
			task.wait(1)
			return
		end

		NoteSeaNeed("Style", 3)

		if CurrentSea() ~= 3 then
			if not ClaimDrive(Entry.Key, StyleDrivePriority) then
				Entry.Status = "A boss farm is driving, waiting"
				task.wait(0.3)
				return
			end

			StartRender()
			LockCFrame = nil
			CancelTween()

			local _, Status = StepTowardSea(3, "Style")
			Entry.Status = Status
			task.wait(5)
			return
		end

		UpgradeStyleStep(Entry)
	end

	local function SyncStyle(Entry)
		if getgenv().Settings[Entry.Setting] ~= true then
			Entry.Status = "Idle"
			StopStyleRun(Entry)
			return
		end

		if HasStyleV2(Entry.Style) then
			Entry.Status = "You already own " .. Entry.Style .. " V2"
			StopStyleRun(Entry)
			SetElementTitle(Entry.Toggle, StyleTitle(Entry))
			WindUI:Notify({ Title = Entry.Label, Content = Entry.Status, Duration = 5 })
			return
		end

		if Entry.Running then
			return
		end

		Entry.Running = true
		Entry.Finished = nil
		BeginRunner(Entry.Key)

		Entry.Loop = task.spawn(function()
			while Entry.Running do
				task.wait()

				if not IsCurrentInstance() then
					Entry.Running = false
					EndRunner(Entry.Key)
					break
				end

				if not pcall(StyleStep, Entry) then
					task.wait(0.25)
				end

				if Entry.Finished then
					local Text = Entry.Finished
					Entry.Finished = nil
					FinishStyleRun(Entry, Text)
					break
				end
			end
		end)
	end

	local StyleSection = FightStyleTab:Section({ Title = "tr:StyleV2Section", Icon = "hand", Opened = true })
	local StyleParagraph = RT.Status(StyleSection, "tr:StyleV2Status")

	for _, Entry in ipairs(StyleUpgrades) do
		Entry.Status = "Idle"
		Entry.Running = false
		Entry.LastTalk = 0
		Entry.LastSwap = 0

		Entry.Toggle = StyleSection:Toggle({
			Title = StyleTitle(Entry),
			Path = Entry.Setting,
			Desc = Entry.Desc,

			Value = getgenv().Settings[Entry.Setting],
			Icon = "check",
			Callback = function(Value)
				getgenv().Settings[Entry.Setting] = Value
				SaveSetting()
				SyncStyle(Entry)
			end,
		})

		if getgenv().Settings[Entry.Setting] then
			task.defer(SyncStyle, Entry)
		end
	end

	task.spawn(function()
		while task.wait(1) do
			if not IsCurrentInstance() then
				break
			end

			for _, Entry in ipairs(StyleUpgrades) do
				local Done = HasStyleV2(Entry.Style)

				if Done ~= Entry.WasDone then
					Entry.WasDone = Done
					SetElementTitle(Entry.Toggle, StyleTitle(Entry))
				end
			end

			RT.Push("Fighting Style V2", StyleParagraph, function()
				local Lines = { RT.Head("Fighting Style V2", RT.Pink) }
				local Working = false

				for _, Entry in ipairs(StyleUpgrades) do
					if Entry.Running then
						Working = true
						RT.Add(Lines, RT.Field("Getting", Entry.Style .. " V2", RT.Pink))
						RT.Add(Lines, RT.State(Entry.Status, true))
					end
				end

				if not Working then
					RT.Add(Lines, RT.State("Idle", false))
				end

				return table.concat(Lines, "\n")
			end)
		end
	end)
end

do
	local AwakeningTab = TabGroups.Farm:Tab({
		Title = "tr:AwakeningTab",
		Icon = "sparkles",
		Locked = false,
	})
	SetTabOrder(AwakeningTab, 5)

	local AwakenDrivePriority = 1.5

	local AwakenConfig = (function()
		local Ok, Config = pcall(function()
			local Folder = game:GetService("ReplicatedStorage"):WaitForChild("Config", 10)
			local Module = Folder and Folder:WaitForChild("AwakeningConfig", 10)
			return Module and require(Module)
		end)

		return (Ok and type(Config) == "table") and Config or {}
	end)()

	local FallbackSkills = {
		Gear4 = { "Gear 4th", "Kong Gun", "Double Culverin", "Flight", "Kong Organ", "King Kong Gun" },
		Gear5 = {
			"Gear 5",
			"Kaminari Lightning",
			"God Clap",
			"Spiritual Dominance",
			"Gomu Giant",
			"Bajrang Gun",
			"Cloud Fly",
		},
		Enel = {
			"Transformation",
			"Thunder Reflux",
			"Chain Lightning",
			"Guiding Thunder",
			"Terror Beam",
			"Dual Lightning Emperor",
			"Thunder Flight",
		},
		DragonHybrid = {
			"Hybrid Mode",
			"Heatwave Barrage",
			"Thunder Bite",
			"Wyrmbreak Clawstorm",
			"Thunderblast Breath",
			"Wyrm Ascent",
		},
	}

	local FallbackMaterial = {
		Gear4 = "Gear 4 Book",
		Gear5 = "Drums of Liberation",
		Enel = "RaijinsCore",
		DragonHybrid = "DragonHeart",
	}

	-- Enel and DragonHybrid keep their material in a PlayerData counter, the Gum books sit in
	-- the StoredItems bag (config marks those with storedItem).
	local FallbackStored = {
		Gear4 = true,
		Gear5 = true,
	}

	local FallbackLabel = {
		Enel = "Raijin Core",
		DragonHybrid = "Dragon's Heart",
	}

	-- Used when the awakening config cannot be read and there is no skill name list to count.
	local FallbackSkillCount = {
		Gear4 = 6,
		Gear5 = 7,
		Enel = 7,
		DragonHybrid = 6,
	}

	local function VariantConfig(Key)
		local Entry = AwakenConfig[Key]
		return type(Entry) == "table" and Entry or nil
	end

	-- The Gum gears are keyed as Gear4/Gear5 in the config, but the other fruits may use a
	-- different name, so fall back to the row that spends the same material.
	local function VariantKey(Key, Material)
		if VariantConfig(Key) then
			return Key
		end

		for Name, Row in pairs(AwakenConfig) do
			if type(Name) == "string" and type(Row) == "table" and Row.material == Material then
				return Name
			end
		end

		return Key
	end

	local function SkillList(Key)
		local Entry = VariantConfig(Key)
		local List = {}

		if Entry and type(Entry.skills) == "table" then
			for _, Row in ipairs(Entry.skills) do
				local Name = type(Row) == "table" and Row[1] or Row
				if type(Name) == "string" and Name ~= "" then
					table.insert(List, Name)
				end
			end
		end

		if #List == 0 then
			for _, Name in ipairs(FallbackSkills[Key] or {}) do
				table.insert(List, Name)
			end
		end

		return List
	end

	-- One material per skill, so the skill list is the real count. DragonHybrid lists 6 skills
	-- but a skillCount of 4, and the Poneglyph still takes 6 Dragon Hearts.
	local function SkillNeed(Key)
		local List = SkillList(Key)

		if #List > 0 then
			return #List
		end

		local Entry = VariantConfig(Key)
		local Count = Entry and tonumber(Entry.skillCount) or nil

		if Count and Count > 0 then
			return Count
		end

		return FallbackSkillCount[Key] or 6
	end

	local function MaterialName(Key)
		local Entry = VariantConfig(Key)
		local Name = Entry and Entry.material
		return type(Name) == "string" and Name or (FallbackMaterial[Key] or "")
	end

	-- material is the data key (RaijinsCore), materialName is what the player sees.
	local function MaterialLabel(Key)
		local Entry = VariantConfig(Key)
		local Name = Entry and Entry.materialName
		return type(Name) == "string" and Name or (FallbackLabel[Key] or MaterialName(Key))
	end

	local function MaterialStored(Key)
		local Entry = VariantConfig(Key)

		if Entry then
			return Entry.storedItem == true
		end

		return FallbackStored[Key] == true
	end

	local function MasteryFruit(Key)
		local Entry = VariantConfig(Key)
		local Name = Entry and Entry.masteryKey
		return type(Name) == "string" and Name or nil
	end

	local GumMasteryNeed = 300

	local function MasteryNeed(Key)
		local Entry = VariantConfig(Key)
		return math.max(GumMasteryNeed, tonumber(Entry and Entry.masteryReq) or GumMasteryNeed)
	end

	local function EatenFruit()
		return PlayerDataString("CurrentSuperPower", "")
	end

	local function GumEaten()
		return EatenFruit() == "Gum"
	end

	local function FruitMastery(Name)
		local Mastery = PlayerData:FindFirstChild("Mastery")
		local Fruit = Mastery and Mastery:FindFirstChild("Fruit")
		local Entry = Fruit and Fruit:FindFirstChild(Name)
		local Level = Entry and Entry:FindFirstChild(Name .. "Level")
		return Level and math.max(0, Level.Value) or 0
	end

	local function GumMastery()
		return FruitMastery("Gum")
	end

	local function Gear2Owned()
		local Gears = PlayerData:FindFirstChild("Gears")
		local Flag = Gears and Gears:FindFirstChild("Gear2Unlocked")
		return Flag ~= nil and Flag.Value == true
	end

	local function StoredCount(Name)
		if Name == "" then
			return 0
		end

		local Value = PlayerData:FindFirstChild("StoredItems")
		local Raw = Value and Value.Value

		if type(Raw) ~= "string" or Raw == "" then
			return 0
		end

		local Ok, Data = pcall(function()
			return HttpService:JSONDecode(Raw)
		end)

		if not Ok or type(Data) ~= "table" then
			return 0
		end

		local Entry = Data[Name]

		if type(Entry) == "number" then
			return Entry
		end

		if Entry == true then
			return 1
		end

		if type(Entry) == "table" then
			return tonumber(Entry.Count or Entry.Amount or Entry.amount) or 1
		end

		return 0
	end

	-- Bosses drop their material into a PlayerData counter (RaijinsCore, DragonHeart) while the
	-- Gum books sit in the StoredItems bag.
	local function MaterialHeld(Key, DataKey)
		local Name = MaterialName(Key)

		if not MaterialStored(Key) then
			local Value = PlayerData:FindFirstChild(DataKey or Name)
			local Count = Value and tonumber(Value.Value)

			if Count then
				return math.max(0, math.floor(Count))
			end
		end

		return StoredCount(Name)
	end

	local function PowerFolder(Fruit)
		local Gui = LocalPlayer:FindFirstChild("PlayerGui")
		local Root = Gui and Gui:FindFirstChild("FruitPowers")
		return Root and Root:FindFirstChild(Fruit or "Gum")
	end

	-- PlayerData.FruitAwakenings holds the awakened skill count per gear, e.g. {"Gear4":1}.
	local function AwakenRecord()
		local Value = PlayerData:FindFirstChild("FruitAwakenings")
		local Raw = Value and Value.Value

		if type(Raw) ~= "string" then
			Raw = PlayerData:GetAttribute("FruitAwakenings")
		end

		if type(Raw) == "table" then
			return Raw
		end

		if type(Raw) ~= "string" or Raw == "" then
			return nil
		end

		local Ok, Data = pcall(function()
			return HttpService:JSONDecode(Raw)
		end)

		return (Ok and type(Data) == "table") and Data or nil
	end

	local function RecordCount(Key, Data)
		local Entry = Data[Key]

		if type(Entry) == "number" then
			return math.max(0, math.floor(Entry))
		end

		if Entry == true then
			return SkillNeed(Key)
		end

		if type(Entry) == "table" then
			local Count = tonumber(Entry.Count or Entry.count or Entry.Amount or Entry.amount)

			if Count then
				return math.max(0, math.floor(Count))
			end

			local Total = 0

			for _, Row in pairs(Entry) do
				if Row then
					Total = Total + 1
				end
			end

			return Total
		end

		-- The record loaded but has no row for this gear, so nothing is awakened yet.
		return 0
	end

	local function AwakenedCount(Key, Fruit)
		local Data = AwakenRecord()

		if Data then
			return RecordCount(Key, Data)
		end

		local Folder = PowerFolder(Fruit)

		if not Folder then
			return nil
		end

		local Count, Seen = 0, 0

		for _, Name in ipairs(SkillList(Key)) do
			local Item = Folder:FindFirstChild(Name)

			if Item then
				Seen = Seen + 1

				if not (Item:IsA("LocalScript") and Item.Disabled) then
					Count = Count + 1
				end
			end
		end

		if Seen == 0 then
			return nil
		end

		return Count
	end

	local GearmanSpot = Vector3.new(5019, 16, 2476)
	local GearmanWaitSpot = Vector3.new(5019, 16, 2476)
	local PoneglyphSpot = Vector3.new(3210.1, 36.3, 16971.2)

	local function GearmanNpc()
		local Folder = NpcWorkspace:FindFirstChild("GearSeller")
		if not Folder then
			return nil
		end

		local Named = Folder:FindFirstChild("Gearman Puzrat")
		if Named and Named:FindFirstChild("UnlockGear2") then
			return Named
		end

		for _, Model in ipairs(Folder:GetChildren()) do
			if Model:FindFirstChild("UnlockGear2") then
				return Model
			end
		end

		return nil
	end

	local function Gear2Price()
		local Npc = GearmanNpc()
		local Price = Npc and Npc:FindFirstChild("Price")
		return (Price and tonumber(Price.Value)) or 100000
	end

	local function PoneglyphParts()
		local Model = workspace:FindFirstChild("Poneglyph")

		if not Model then
			return nil, nil, nil
		end

		local Mesh = Model:FindFirstChild("Meshes/poneglyph")
		local Holder = Mesh and Mesh:FindFirstChild("PP")
		local Prompt = (Holder and Holder:FindFirstChildWhichIsA("ProximityPrompt"))
			or Model:FindFirstChildWhichIsA("ProximityPrompt", true)

		local Placements = Model:FindFirstChild("Placements")
		local Stand = Placements and Placements:FindFirstChild("PlayerCFrame")
		local Spot = (Stand and Stand:IsA("BasePart") and Stand.Position) or ResolvePosition(Model) or PoneglyphSpot

		return Model, Prompt, Spot
	end

	local function PoneglyphRemotes()
		local Model = workspace:FindFirstChild("Poneglyph")
		local Mesh = Model and Model:FindFirstChild("Meshes/poneglyph")
		local Scripts = Mesh and Mesh:FindFirstChild("PoneglyphScripts")

		if not Scripts then
			return nil, nil
		end

		return Scripts:FindFirstChild("Awaken"), Scripts:FindFirstChild("SkipCutscene")
	end

	local function FireRemote(Remote, ...)
		if not Remote then
			return false
		end

		local Args = table.pack(...)

		return (pcall(function()
			if Remote:IsA("RemoteFunction") then
				Remote:InvokeServer(table.unpack(Args, 1, Args.n))
			else
				Remote:FireServer(table.unpack(Args, 1, Args.n))
			end
		end))
	end

	-- The awakening cutscene anchors the player. Skip it and ask the server to release the
	-- character, then clear the local anchor in case the cutscene left it set.
	local function SkipAwakenCutscene()
		local _, Skip = PoneglyphRemotes()

		FireRemote(Skip)
		task.wait(0.3)
		FireRemote(ClientEvents and ClientEvents:FindFirstChild("OnDeanchor"))

		local Root = GetRoot()

		if Root and Root.Anchored then
			pcall(function()
				Root.Anchored = false
			end)
		end
	end

	local ConfirmWords = {
		"awaken",
		"confirm",
		"upgrade",
		"accept",
		"yes",
		"ปลด",
		"ยืนยัน",
		"ตกลง",
		"อัป",
	}

	local function VariantWords(Key)
		local Words = { string.lower(Key) }

		local Fruits = AwakenConfig.FruitVariants
		local Gum = type(Fruits) == "table" and Fruits.Gum or nil
		local Entry = type(Gum) == "table" and type(Gum.variants) == "table" and Gum.variants[Key] or nil
		local Label = Entry and Entry.label

		if type(Label) == "string" and Label ~= "" then
			table.insert(Words, string.lower(Label))
		else
			table.insert(Words, string.lower((string.gsub(Key, "(%a)(%d)", "%1 %2"))))
		end

		return Words
	end

	local function ButtonText(Button)
		local Parts = {}

		local Ok, Text = pcall(function()
			return Button.Text
		end)

		if Ok and type(Text) == "string" then
			table.insert(Parts, Text)
		end

		for _, Child in ipairs(Button:GetDescendants()) do
			if Child:IsA("TextLabel") then
				table.insert(Parts, Child.Text)
			end
		end

		return string.lower(table.concat(Parts, " "))
	end

	local function FindMenuButton(Words)
		local Gui = LocalPlayer:FindFirstChild("PlayerGui")

		if not Gui then
			return nil
		end

		for _, Object in ipairs(Gui:GetDescendants()) do
			if Object:IsA("GuiButton") and Object.Visible and Object.AbsoluteSize.X > 0 then
				local Screen = Object:FindFirstAncestorWhichIsA("LayerCollector")

				if Screen and Screen.Enabled then
					local Text = ButtonText(Object)

					for _, Word in ipairs(Words) do
						if string.find(Text, Word, 1, true) then
							return Object
						end
					end
				end
			end
		end

		return nil
	end

	local function PressMenuButton(Button)
		local Pressed = pcall(function()
			local GuiService = game:GetService("GuiService")
			local VIM = game:GetService("VirtualInputManager")

			Button.Selectable = true
			Button.SelectionImageObject = nil
			GuiService.SelectedObject = Button

			VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, nil)
			task.wait(0.1)
			VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, nil)

			GuiService.SelectedObject = nil
		end)

		return FireButton(Button) or Pressed
	end

	local Awakenings = {
		{
			Key = "Gear2",
			Runner = "AwakenGear2",
			Label = "Auto Gear 2",
			Title = "tr:AwakenGear2",
			Desc = "tr:AwakenGear2Desc",
			Setting = "Gear2",
			Stage = "Gear 2",
			Kind = "Buy",
			Sea = 1,
			NeedLevel = 750,
			NeedMastery = GumMasteryNeed,
		},
		{
			Key = "Gear4",
			Runner = "AwakenGear4",
			Label = "Auto Gear 4",
			Title = "tr:AwakenGear4",
			Desc = "tr:AwakenGear4Desc",
			Setting = "Gear4",
			Stage = "Gear 4",
			Kind = "Awaken",
			Variant = "Gear4",

			FarmSea = 1,
			Mob = "G4 Boss",
		},
		{
			Key = "Gear5",
			Runner = "AwakenGear5",
			Label = "Auto Gear 5",
			Title = "tr:AwakenGear5",
			Desc = "tr:AwakenGear5Desc",
			Setting = "Gear5",
			Stage = "Gear 5",
			Kind = "Awaken",
			Variant = "Gear5",

			FarmSea = 2,
			BossLabel = "Dragon Boss",
			BossToggles = { "AutoDragonBoss.Summon", "AutoDragonBoss.Kill" },
		},
		{
			Key = "Electricity",
			Runner = "AwakenElectricity",
			Label = "Auto Electricity Awakening",
			Title = "tr:AwakenElectricity",
			Desc = "tr:AwakenElectricityDesc",
			Setting = "Electricity",
			Stage = "Electricity",
			Kind = "Awaken",
			Variant = "Enel",
			Fruit = "Electricity",
			MaterialKey = "RaijinsCore",
			Group = "Fruit",

			FarmSea = 3,
			PoneglyphSea = 3,
			BossLabel = "Raijin",
			BossToggles = { "AutoRaijin.Summon", "AutoRaijin.Kill" },
		},
		{
			Key = "Dragon",
			Runner = "AwakenDragon",
			Label = "Auto Dragon Awakening",
			Title = "tr:AwakenDragon",
			Desc = "tr:AwakenDragonDesc",
			Setting = "Dragon",
			Stage = "Dragon",
			Kind = "Awaken",
			Variant = "DragonHybrid",
			Fruit = "Dragon",
			MaterialKey = "DragonHeart",
			Group = "Fruit",

			FarmSea = 3,
			PoneglyphSea = 3,
			BossLabel = "Dragon Hybrid Boss",
			BossToggles = { "AutoDragonHydra.Summon", "AutoDragonHydra.Kill" },
		},
	}

	local function EntryFruit(Entry)
		return MasteryFruit(Entry.Variant) or Entry.Fruit or "Gum"
	end

	local function FruitReady(Entry)
		return EatenFruit() == EntryFruit(Entry)
	end

	local function Setting(Entry)
		local Store = getgenv().Settings.AutoAwakening
		return type(Store) == "table" and Store[Entry.Setting] == true
	end

	local function SetSetting(Entry, Value)
		local Store = getgenv().Settings.AutoAwakening

		if type(Store) ~= "table" then
			Store = {}
			getgenv().Settings.AutoAwakening = Store
		end

		Store[Entry.Setting] = Value
	end

	local function SettingAt(Path)
		local Node = getgenv().Settings

		for Part in string.gmatch(Path, "[^%.]+") do
			if type(Node) ~= "table" then
				return nil
			end
			Node = Node[Part]
		end

		return Node
	end

	local function SetPathToggle(Path, Value)
		if SettingAt(Path) == Value then
			return
		end

		for _, Widget in ipairs(ConfigWidgets) do
			if Widget.Path == Path then
				SetToggleValue(Widget.Widget, Value)

				if type(Widget.Callback) == "function" then
					pcall(Widget.Callback, Value)
				end

				return
			end
		end
	end

	local function BossFarmStop(Entry)
		if not Entry.Turned then
			return
		end

		for Path in pairs(Entry.Turned) do
			SetPathToggle(Path, false)
		end

		Entry.Turned = nil
	end

	local function BossFarmStart(Entry)
		Entry.Turned = Entry.Turned or {}

		for _, Path in ipairs(Entry.BossToggles or {}) do
			if SettingAt(Path) ~= true then
				Entry.Turned[Path] = true
				SetPathToggle(Path, true)
			end
		end
	end

	local function StandAt(Entry, Root, Spot, Status)
		local Stand = CFrame.new(Spot + Vector3.new(0, 5, 0))

		if (Root.Position - Stand.Position).Magnitude > 10 then
			Entry.Status = Status
			LockCFrame = nil
			TravelTo(Stand, 10)
			return false
		end

		CancelTween()
		LockCFrame = Stand
		return true
	end

	local function FightMob(Entry, Root, Name)
		local Target = FindMobs(Name, Root.Position, nil)[1]

		if not Target then
			local Spot = Entry.Spot or BossSpotFor(Name) or (FindEntryByMob(Name) or {}).MonPOS

			if not Spot then
				Entry.Status = Name .. " has no known spot"
				IdleRunner(Entry.Runner)
				task.wait(5)
				return
			end

			Entry.Spot = Spot

			local State = BossWaitAt(Entry.Runner, Spot, nil, true)

			if State == "Flying" then
				Entry.Status = "Flying to " .. Name
			else
				Entry.Status = "Waiting for " .. Name .. " to respawn"
			end

			task.wait(0.5)
			return
		end

		RememberBossSpot(Name, Target.Root.Position)

		if KeepBossQuest(Name) then
			return
		end

		local Tool = EquipWeapon(BossWeaponName())
		local MobRoot = Target.Root
		local Stand = GetAttackCFrame(MobRoot.CFrame)

		if (Root.Position - Stand.Position).Magnitude > 30 then
			Entry.Status = "Flying to " .. Name
			LockCFrame = nil
			TravelTo(Stand, 30)
			return
		end

		Entry.Status = "Fighting "
			.. Name
			.. " for the "
			.. MaterialLabel(Entry.Variant)
			.. (Entry.Left and (" (" .. (Entry.Held or 0) .. "/" .. Entry.Left .. ")") or "")
		CancelTween()
		LockCFrame = Stand

		if tick() - Entry.LastAttack >= Entry.AttackDelay then
			Entry.LastAttack = tick()
			task.spawn(AttackWith, Tool, MobRoot)
		end
	end

	local function BuyGear2(Entry)
		if Gear2Owned() then
			Entry.Finished = "Gear 2 is unlocked. Stopping."
			return
		end

		if not GumEaten() then
			local Eaten = EatenFruit()
			Entry.Status = "Eat the Gum fruit first (holding " .. (Eaten ~= "" and Eaten or "no fruit") .. ")"
			IdleRunner(Entry.Runner)
			task.wait(3)
			return
		end

		local Mastery = GumMastery()

		if Mastery < Entry.NeedMastery then
			Entry.Status = "Need Gum mastery "
				.. Entry.NeedMastery
				.. " (now "
				.. Mastery
				.. ") - farm with Gum equipped"
			LockCFrame = nil
			CancelTween()
			IdleRunner(Entry.Runner)
			task.wait(3)
			return
		end

		NoteSeaNeed("Awaken", Entry.Sea)

		if CurrentSea() ~= Entry.Sea then
			if not ClaimDrive(Entry.Runner, AwakenDrivePriority) then
				Entry.Status = "A boss farm is driving, waiting"
				task.wait(0.3)
				return
			end

			StartRender()
			LockCFrame = nil
			CancelTween()

			local _, Status = StepTowardSea(Entry.Sea, "Awaken")
			Entry.Status = Status
			task.wait(5)
			return
		end

		if LevelValue.Value < Entry.NeedLevel then
			Entry.Status = "Need level " .. Entry.NeedLevel .. " (now " .. LevelValue.Value .. ")"
			IdleRunner(Entry.Runner)
			task.wait(3)
			return
		end

		local Price = Gear2Price()

		if CurrencyValue.Value < Price then
			Entry.Status = "Need $" .. RT.Num(Price) .. " (now $" .. RT.Num(CurrencyValue.Value) .. ")"
			IdleRunner(Entry.Runner)
			task.wait(3)
			return
		end

		if not ClaimDrive(Entry.Runner, AwakenDrivePriority) then
			Entry.Status = "A boss farm is driving, waiting"
			task.wait(0.3)
			return
		end

		local Root = GetRoot()
		if not Root then
			return
		end

		StartRender()

		local Npc = GearmanNpc()
		local Remote = Npc and Npc:FindFirstChild("UnlockGear2")
		local Spot = (Remote and (ResolvePosition(Npc) or GearmanSpot)) or GearmanWaitSpot

		if
			not StandAt(
				Entry,
				Root,
				Spot,
				Remote and "Flying to Gearman Puzrat" or "Flying to the Gearman Puzrat wait spot"
			)
		then
			return
		end

		if not Remote then
			Entry.Status = "Waiting for Gearman Puzrat to load at the wait spot"
			task.wait(0.5)
			return
		end

		if tick() - Entry.LastTalk < 2 then
			task.wait(0.2)
			return
		end

		Entry.LastTalk = tick()
		Entry.Status = "Buying Gear 2 for $" .. RT.Num(Price)

		pcall(function()
			if Remote:IsA("RemoteFunction") then
				Remote:InvokeServer()
			else
				Remote:FireServer()
			end
		end)

		task.wait(0.6)
	end

	local function SpendMaterial(Entry, Root)
		local _, Prompt, Spot = PoneglyphParts()

		if not Spot then
			Entry.Status = "Poneglyph has not streamed in yet"
			LockCFrame = nil
			task.wait(1)
			return
		end

		if not StandAt(Entry, Root, Spot, "Taking the " .. MaterialLabel(Entry.Variant) .. " to the Poneglyph") then
			return
		end

		local Material = MaterialLabel(Entry.Variant)
		local Before = MaterialHeld(Entry.Variant, Entry.MaterialKey)
		local Awaken = PoneglyphRemotes()

		-- The Poneglyph takes the awakening straight from a remote, so skip the menu when it
		-- is there and only fall back to clicking when the remote cannot be found.
		if Awaken then
			if tick() - Entry.LastTalk < 2.5 then
				task.wait(0.2)
				return
			end

			Entry.LastTalk = tick()
			Entry.Status = "Awakening " .. Entry.Stage .. " at the Poneglyph"

			local Sent = FireRemote(Awaken, "confirm", Entry.Variant)

			task.wait(0.5)
			SkipAwakenCutscene()

			Entry.PickedAt = 0
			Entry.Fails = Sent and 0 or (Entry.Fails + 1)

			if Entry.Fails >= 5 then
				Entry.Status = "The Poneglyph refused the " .. Entry.Stage .. " awakening"
				Entry.Fails = 0
				task.wait(3)
				return
			end

			task.wait(1)
			return
		end

		local Pick = FindMenuButton(VariantWords(Entry.Variant))

		if Pick then
			Entry.Status = "Choosing " .. Entry.Stage .. " on the Poneglyph"
			PressMenuButton(Pick)
			Entry.PickedAt = tick()
			Entry.Fails = 0
			task.wait(1.2)
			return
		end

		if Entry.PickedAt > 0 and tick() - Entry.PickedAt <= 12 then
			if MaterialHeld(Entry.Variant, Entry.MaterialKey) < Before then
				Entry.PickedAt = 0
				return
			end

			local Confirm = FindMenuButton(ConfirmWords)

			if Confirm then
				Entry.Status = "Confirming the " .. Entry.Stage .. " awakening"
				PressMenuButton(Confirm)
				Entry.PickedAt = 0
				task.wait(1.5)
				return
			end

			Entry.Status = "Waiting for the Poneglyph menu"
			task.wait(0.5)
			return
		end

		Entry.PickedAt = 0

		if not Prompt then
			Entry.Status = "Waiting for the Poneglyph prompt to load"
			task.wait(0.5)
			return
		end

		if tick() - Entry.LastTalk < 3 then
			task.wait(0.2)
			return
		end

		Entry.LastTalk = tick()
		Entry.Fails = Entry.Fails + 1
		Entry.Status = "Opening the Poneglyph menu"

		task.spawn(FirePrompt, Prompt)
		task.wait(1.5)

		if Entry.Fails >= 5 and not FindMenuButton(VariantWords(Entry.Variant)) then
			Entry.Status = "The Poneglyph menu will not open - press E on it by hand once"
			Entry.Fails = 0
			task.wait(3)
		end
	end

	local function AwakenStep(Entry)
		local Fruit = EntryFruit(Entry)

		if not FruitReady(Entry) then
			local Eaten = EatenFruit()
			Entry.Status = "Eat the " .. Fruit .. " fruit first (holding " .. (Eaten ~= "" and Eaten or "no fruit") .. ")"
			BossFarmStop(Entry)
			IdleRunner(Entry.Runner)
			task.wait(3)
			return
		end

		local Need = SkillNeed(Entry.Variant)
		local Done = AwakenedCount(Entry.Variant, Fruit)

		if Done and Done >= Need then
			Entry.Finished = Entry.Stage .. " is fully awakened (" .. Done .. "/" .. Need .. "). Stopping."
			return
		end

		local Mastery = FruitMastery(Fruit)
		local NeedMastery = MasteryNeed(Entry.Variant)

		if Mastery < NeedMastery then
			Entry.Status = "Need "
				.. Fruit
				.. " mastery "
				.. NeedMastery
				.. " (now "
				.. Mastery
				.. ") - farm with "
				.. Fruit
				.. " equipped"
			BossFarmStop(Entry)
			LockCFrame = nil
			CancelTween()
			IdleRunner(Entry.Runner)
			task.wait(3)
			return
		end

		local Material = MaterialLabel(Entry.Variant)
		local Held = MaterialHeld(Entry.Variant, Entry.MaterialKey)
		local Left = Done and math.max(0, Need - Done) or Need
		local Sea = Entry.PoneglyphSea or 2

		-- Only walk to the Poneglyph once every missing skill can be awakened in one trip.
		-- Done is nil when the skill folder cannot be read, so spend right away instead of
		-- farming a full set that may not be needed.
		if Held > 0 and (not Done or Held >= Left) then
			BossFarmStop(Entry)

			NoteSeaNeed("Awaken", Sea)

			if CurrentSea() ~= Sea then
				if not ClaimDrive(Entry.Runner, AwakenDrivePriority) then
					Entry.Status = "A boss farm is driving, waiting"
					task.wait(0.3)
					return
				end

				StartRender()
				LockCFrame = nil
				CancelTween()

				local _, Status = StepTowardSea(Sea, "Awaken")
				Entry.Status = Status
				task.wait(5)
				return
			end

			if not ClaimDrive(Entry.Runner, AwakenDrivePriority) then
				Entry.Status = "A boss farm is driving, waiting"
				task.wait(0.3)
				return
			end

			local Root = GetRoot()
			if not Root then
				return
			end

			StartRender()
			SpendMaterial(Entry, Root)
			return
		end

		NoteSeaNeed("Awaken", Entry.FarmSea)

		if CurrentSea() ~= Entry.FarmSea then
			if not ClaimDrive(Entry.Runner, AwakenDrivePriority) then
				Entry.Status = "A boss farm is driving, waiting"
				task.wait(0.3)
				return
			end

			StartRender()
			LockCFrame = nil
			CancelTween()

			local _, Status = StepTowardSea(Entry.FarmSea, "Awaken")
			Entry.Status = Status
			task.wait(5)
			return
		end

		if Entry.BossToggles then
			if not HasBossWeaponPicked() then
				Entry.Status = "Need " .. Material .. " - pick a Boss Weapon so " .. Entry.BossLabel .. " can farm"
				IdleRunner(Entry.Runner)
				task.wait(5)
				return
			end

			BossFarmStart(Entry)
			Entry.Status = "Need "
				.. Left
				.. "x "
				.. Material
				.. " (have "
				.. Held
				.. ") - farming "
				.. Entry.BossLabel
			IdleRunner(Entry.Runner)
			task.wait(3)
			return
		end

		if not ClaimDrive(Entry.Runner, AwakenDrivePriority) then
			Entry.Status = "A boss farm is driving, waiting"
			task.wait(0.3)
			return
		end

		local Root = GetRoot()
		if not Root then
			return
		end

		StartRender()

		Entry.Held = Held
		Entry.Left = Left

		FightMob(Entry, Root, Entry.Mob)
	end

	local function EntryTitle(Entry)
		if Entry.Kind == "Buy" then
			return Gear2Owned() and (Entry.Label .. " [Owner]") or Entry.Label
		end

		local Done = AwakenedCount(Entry.Variant, EntryFruit(Entry))
		local Need = SkillNeed(Entry.Variant)

		if Done and Done >= Need then
			return Entry.Label .. " [Owner]"
		end

		if Done then
			return Entry.Label .. " [" .. Done .. "/" .. Need .. "]"
		end

		return Entry.Label
	end

	local function AlreadyDone(Entry)
		if Entry.Kind == "Buy" then
			return Gear2Owned()
		end

		local Done = AwakenedCount(Entry.Variant, EntryFruit(Entry))
		return Done ~= nil and Done >= SkillNeed(Entry.Variant)
	end

	local function StopRun(Entry)
		Entry.Running = false

		BossFarmStop(Entry)

		local Loop = Entry.Loop
		Entry.Loop = nil

		if Loop and Loop ~= coroutine.running() then
			pcall(function()
				task.cancel(Loop)
			end)
		end

		EndRunner(Entry.Runner)
	end

	local function FinishRun(Entry, Text)
		Entry.Status = Text
		SetSetting(Entry, false)
		SaveSetting()
		StopRun(Entry)
		SetToggleValue(Entry.Toggle, false)
		SetElementTitle(Entry.Toggle, EntryTitle(Entry))
		WindUI:Notify({ Title = Entry.Label, Content = Text, Duration = 6 })
	end

	local function Step(Entry)
		if not IsAlive() then
			LockCFrame = nil
			HoldCFrame = nil
			CancelTween()
			task.wait(1)
			return
		end

		if Entry.Kind == "Buy" then
			BuyGear2(Entry)
			return
		end

		AwakenStep(Entry)
	end

	local function Sync(Entry)
		if not Setting(Entry) then
			Entry.Status = "Idle"
			StopRun(Entry)
			return
		end

		if AlreadyDone(Entry) then
			Entry.Status = Entry.Kind == "Buy" and "You already unlocked Gear 2"
				or ("You already awakened " .. Entry.Stage)
			StopRun(Entry)
			SetSetting(Entry, false)
			SaveSetting()
			SetToggleValue(Entry.Toggle, false)
			SetElementTitle(Entry.Toggle, EntryTitle(Entry))
			WindUI:Notify({ Title = Entry.Label, Content = Entry.Status, Duration = 5 })
			return
		end

		if Entry.Kind ~= "Buy" and not RequireBossWeapon(Entry.Label, Entry.Toggle) then
			SetSetting(Entry, false)
			SaveSetting()
			return
		end

		if Entry.Running then
			return
		end

		Entry.Running = true
		Entry.Finished = nil
		BeginRunner(Entry.Runner)

		Entry.Loop = task.spawn(function()
			while Entry.Running do
				task.wait()

				if not IsCurrentInstance() then
					Entry.Running = false
					EndRunner(Entry.Runner)
					break
				end

				if not pcall(Step, Entry) then
					task.wait(0.25)
				end

				if Entry.Finished then
					local Text = Entry.Finished
					Entry.Finished = nil
					FinishRun(Entry, Text)
					break
				end
			end
		end)
	end

	local GumSection = AwakeningTab:Section({ Title = "tr:AwakenGumSection", Icon = "sparkles", Opened = true })
	local GumParagraph = RT.Status(GumSection, "tr:AwakenGumStatus")

	local FruitSection = AwakeningTab:Section({ Title = "tr:AwakenFruitSection", Icon = "zap", Opened = true })
	local FruitParagraph = RT.Status(FruitSection, "tr:AwakenFruitStatus")

	for _, Entry in ipairs(Awakenings) do
		Entry.Status = "Idle"
		Entry.Running = false
		Entry.LastTalk = 0
		Entry.LastAttack = 0
		Entry.AttackDelay = 0.15
		Entry.PickedAt = 0
		Entry.Fails = 0
		Entry.Variant = VariantKey(Entry.Variant, MaterialName(Entry.Variant))

		local Host = Entry.Group == "Fruit" and FruitSection or GumSection

		Entry.Toggle = Host:Toggle({
			Title = EntryTitle(Entry),
			Path = "AutoAwakening." .. Entry.Setting,
			Desc = Entry.Desc,

			Value = Setting(Entry),
			Icon = "check",
			Callback = function(Value)
				SetSetting(Entry, Value)
				SaveSetting()
				Sync(Entry)
			end,
		})

		if Setting(Entry) then
			task.defer(Sync, Entry)
		end
	end

	task.spawn(function()
		while task.wait(1) do
			if not IsCurrentInstance() then
				break
			end

			for _, Entry in ipairs(Awakenings) do
				local Title = EntryTitle(Entry)

				if Title ~= Entry.WasTitle then
					Entry.WasTitle = Title
					SetElementTitle(Entry.Toggle, Title)
				end
			end

			RT.Push("Gum awakening", GumParagraph, function()
				local Lines = { RT.Head("Gum Awakening", RT.Purple) }
				local Eaten = EatenFruit()

				RT.Add(
					Lines,
					RT.Field("Fruit eaten", Eaten ~= "" and Eaten or "none", GumEaten() and RT.Green or RT.Red)
						.. RT.Sep
						.. RT.Paint("Mastery: ", RT.Muted)
						.. RT.Bold(
							GumMastery() .. "/" .. GumMasteryNeed,
							GumMastery() >= GumMasteryNeed and RT.Green or RT.Amber
						)
				)

				RT.Add(
					Lines,
					RT.Flag("Gear 2", Gear2Owned())
						.. RT.Sep
						.. RT.Paint("Beli: ", RT.Muted)
						.. RT.Bold("$" .. RT.Num(CurrencyValue.Value), RT.Amber)
				)

				for _, Entry in ipairs(Awakenings) do
					if Entry.Kind == "Awaken" and Entry.Group ~= "Fruit" then
						local Done = AwakenedCount(Entry.Variant, "Gum")
						local Need = SkillNeed(Entry.Variant)
						local Material = MaterialLabel(Entry.Variant)
						local Held = MaterialHeld(Entry.Variant, Entry.MaterialKey)

						RT.Add(
							Lines,
							RT.Paint(Entry.Stage .. ": ", RT.Muted)
								.. (Done and RT.Progress(Done, Need) or RT.Bold("equip Gum to read", RT.Muted))
								.. RT.Sep
								.. RT.Field(Material, tostring(Held), Held > 0 and RT.Green or RT.Muted)
						)
					end
				end

				local Working = false

				for _, Entry in ipairs(Awakenings) do
					if Entry.Running and Entry.Group ~= "Fruit" then
						Working = true
						RT.Add(Lines, RT.Field("Working on", Entry.Stage, RT.Pink))
						RT.Add(Lines, RT.State(Entry.Status, true))
					end
				end

				if not Working then
					RT.Add(Lines, RT.State("Idle", false))
				end

				return table.concat(Lines, "\n")
			end)

			RT.Push("Sea 3 awakening", FruitParagraph, function()
				local Lines = { RT.Head("Sea 3 Awakening", RT.Purple) }
				local Eaten = EatenFruit()

				RT.Add(
					Lines,
					RT.Field("Fruit eaten", Eaten ~= "" and Eaten or "none", RT.Muted)
						.. RT.Sep
						.. RT.Field("Sea", tostring(CurrentSea()), CurrentSea() == 3 and RT.Green or RT.Amber)
				)

				for _, Entry in ipairs(Awakenings) do
					if Entry.Group == "Fruit" then
						local Fruit = EntryFruit(Entry)
						local Ready = Eaten == Fruit
						local Done = Ready and AwakenedCount(Entry.Variant, Fruit) or nil
						local Need = SkillNeed(Entry.Variant)
						local Material = MaterialLabel(Entry.Variant)
						local Held = MaterialHeld(Entry.Variant, Entry.MaterialKey)
						local Mastery = FruitMastery(Fruit)

						RT.Add(
							Lines,
							RT.Paint(Fruit .. ": ", RT.Muted)
								.. (Done and RT.Progress(Done, Need) or RT.Bold("equip " .. Fruit .. " to read", RT.Muted))
								.. RT.Sep
								.. RT.Field(Material, Held .. "/" .. Need, Held >= Need and RT.Green or RT.Muted)
								.. RT.Sep
								.. RT.Paint("Mastery: ", RT.Muted)
								.. RT.Bold(
									Mastery .. "/" .. GumMasteryNeed,
									Mastery >= GumMasteryNeed and RT.Green or RT.Amber
								)
						)
					end
				end

				local Busy = false

				for _, Entry in ipairs(Awakenings) do
					if Entry.Running and Entry.Group == "Fruit" then
						Busy = true
						RT.Add(Lines, RT.Field("Working on", Entry.Stage, RT.Pink))
						RT.Add(Lines, RT.State(Entry.Status, true))
					end
				end

				if not Busy then
					RT.Add(Lines, RT.State("Idle", false))
				end

				return table.concat(Lines, "\n")
			end)
		end
	end)
end

FruitsTab = TabGroups.Item:Tab({
	Title = "tr:FruitsTab",
	Icon = "apple",
	Locked = false,
})

LogicFolder = workspace:WaitForChild("Logic")
FruitSpawnsFolder = LogicFolder:WaitForChild("FruitSpawns")
FruitDropsFolder = LogicFolder:WaitForChild("FruitDrops")
CollectFruit = ClientEvents:WaitForChild("CollectFruit")

FruitNames = {
	"Allosaurus",
	"Barrier",
	"Bomb",
	"Buddha",
	"Circus",
	"Darkness",
	"Dough",
	"Dragon",
	"Electricity",
	"Flame",
	"Gas",
	"Gravity",
	"Gum",
	"Ice",
	"Kilo",
	"Leopard",
	"Light",
	"Love",
	"Magma",
	"Magnet",
	"Mammoth",
	"Okuchi",
	"Operation",
	"Paw",
	"Phoenix",
	"Sand",
	"Saturn",
	"Shadow",
	"Smoke",
	"Snow",
	"Soul",
	"Spike",
	"Spin",
	"String",
	"Tremor",
	"Vanish",
	"Venom",
	"Wolf",
}

function IsWanted(Name)
	local Whitelist = getgenv().Settings.FruitSniper.Whitelist
	if type(Whitelist) ~= "table" or not next(Whitelist) then
		return true
	end

	for Key, Value in pairs(Whitelist) do
		if Value == Name or (Value == true and Key == Name) then
			return true
		end
	end

	return false
end

function GetWorldFruits()
	local Fruits = {}

	for _, Folder in ipairs({ FruitSpawnsFolder, FruitDropsFolder }) do
		for _, Item in ipairs(Folder:GetDescendants()) do
			if Item:IsA("Tool") then
				table.insert(Fruits, Item)
			end
		end
	end

	return Fruits
end

function IsEatenFruit(Tool)
	local Ok, Value = pcall(Tool.GetAttribute, Tool, "FruitPower")
	return Ok and Value == true
end

function GetBackpackFruits()
	local Fruits = {}
	local Backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	local Character = GetCharacter()

	for _, Container in ipairs({ Backpack, Character }) do
		if Container then
			for _, Item in ipairs(Container:GetChildren()) do
				if Item:IsA("Tool") and Item:FindFirstChild("Droppable") and not IsEatenFruit(Item) then
					table.insert(Fruits, Item)
				end
			end
		end
	end

	return Fruits
end

function FruitHandle(Tool)
	return Tool:FindFirstChild("Handle") or Tool:FindFirstChildWhichIsA("BasePart")
end

function IsHeld(Tool)
	local Parent = Tool.Parent
	return Parent ~= nil and (Parent:IsA("Backpack") or Parent == GetCharacter())
end

FruitSniperRunning = false
FruitSniperStatus = "Idle"

function PrepareFruitPrompt(Handle)
	local Prompt = Handle:FindFirstChildOfClass("ProximityPrompt")
	if not Prompt then
		return nil
	end

	pcall(function()
		Prompt.HoldDuration = 0
		Prompt.RequiresLineOfSight = false
		Prompt.Enabled = true
		if Prompt.MaxActivationDistance < 30 then
			Prompt.MaxActivationDistance = 30
		end
	end)

	return Prompt
end

function FruitPosition(Tool)
	local Handle = FruitHandle(Tool)
	if Handle and Handle.Parent then
		return Handle.Position, Handle
	end

	local ok, Pivot = pcall(function()
		return Tool:GetPivot().Position
	end)

	if ok and Pivot and Pivot.Magnitude > 1 then
		return Pivot, nil
	end

	return nil, nil
end

SniperDrivePriority = 3

function SnipeFruit(Tool)
	TpActive = false
	CancelTween()

	local Deadline = tick() + 25

	while tick() < Deadline do
		if not FruitSniperRunning then
			return IsHeld(Tool)
		end
		if IsHeld(Tool) then
			return true
		end
		if not Tool.Parent then
			return IsHeld(Tool)
		end

		if not ClaimDrive("Sniper", SniperDrivePriority) then
			FruitSniperStatus = "Waiting for the merchant"
			task.wait(0.3)
		else
			local Root = GetRoot()
			if not Root then
				return false
			end

			local Character = GetCharacter()
			if Character then
				NoclipCharacter(Character)
			end

			local Position, Handle = FruitPosition(Tool)
			if not Position then
				return false
			end

			StartRender()

			local Goal = CFrame.new(Position + Vector3.new(0, 2, 0))

			if (Root.Position - Goal.Position).Magnitude > 5 then
				LockCFrame = nil
				TravelTo(Goal, 5)
			else
				CancelTween()
				LockCFrame = Goal
				task.wait(0.1)

				if Handle then
					local Prompt = PrepareFruitPrompt(Handle)

					if Prompt then
						task.spawn(function()
							FirePrompt(Prompt)
						end)
					elseif firetouchinterest then
						pcall(function()
							firetouchinterest(Root, Handle, 0)
							firetouchinterest(Root, Handle, 1)
						end)
					end
				end
			end
		end
	end

	return IsHeld(Tool)
end

function CanStoreFruit(Name)
	local Limit
	local Label = LocalPlayer:FindFirstChild("PlayerGui")
	Label = Label and Label:FindFirstChild("Inventory")
	Label = Label and Label:FindFirstChild("MainFrame")
	Label = Label and Label:FindFirstChild("Overhead")
	Label = Label and Label:FindFirstChild("Storage")
	Label = Label and Label:FindFirstChild("Amount")

	if Label and Label:IsA("TextLabel") then
		Limit = tonumber(string.match(Label.Text, "(%-?%d+)"))
	end

	if not Limit then
		local Storable = PlayerData:FindFirstChild("FruitCopiesStorable")
		if not Storable then
			return true, nil
		end

		Limit = Storable.Value

		local Owned = LocalPlayer:FindFirstChild("GamepassesOwn")
		local Gifted = PlayerData:FindFirstChild("GiftedPasses")

		for Pass, Bonus in pairs({ FruitBag = 5, UnlimitedFruitBag = 15 }) do
			local Own = Owned and Owned:FindFirstChild(Pass)
			local Gift = Gifted and Gifted:FindFirstChild(Pass)
			if (Own and Own.Value) or (Gift and Gift.Value) then
				Limit = Limit + Bonus
			end
		end
	end

	local Stored = 0
	local Collected = PlayerData:FindFirstChild("CollectedFruits")

	if Collected then
		for Entry in string.gmatch(tostring(Collected.Value), "[^,]+") do
			if Entry == Name then
				Stored = Stored + 1
			end
		end
	end

	return Stored < Limit, Limit - Stored
end

function StoreFruit(Tool)
	if not IsHeld(Tool) then
		return false
	end

	if not CanStoreFruit(Tool.Name) then
		return false
	end

	local Character = GetCharacter()
	local Humanoid = GetHumanoid()

	if Tool.Parent ~= Character and Humanoid then
		pcall(function()
			Humanoid:EquipTool(Tool)
		end)

		local Deadline = tick() + 2
		while tick() < Deadline and Tool.Parent ~= GetCharacter() do
			task.wait(0.1)
		end
	end

	if Tool.Parent ~= GetCharacter() then
		return false
	end

	pcall(function()
		CollectFruit:FireServer(Tool)
	end)
	task.wait(0.5)

	return true
end

function SniperStep()
	if getgenv().Settings.FruitSniper.StoreToBag then
		for _, Tool in ipairs(GetBackpackFruits()) do
			if not FruitSniperRunning then
				return
			end

			if IsWanted(Tool.Name) and CanStoreFruit(Tool.Name) then
				FruitSniperStatus = "Storing " .. Tool.Name
				if StoreFruit(Tool) then
					WindUI:Notify({
						Title = "Fruit Sniper",
						Content = Tool.Name .. " stored in Fruit Bag.",
						Duration = 4,
					})
				end
			end
		end
	end

	local Wanted = {}
	for _, Tool in ipairs(GetWorldFruits()) do
		if IsWanted(Tool.Name) and Tool.Parent then
			table.insert(Wanted, Tool)
		end
	end

	if #Wanted == 0 then
		FruitSniperStatus = "Waiting for spawns"
		return
	end

	BeginRunner("Sniper")

	for _, Tool in ipairs(Wanted) do
		if not FruitSniperRunning then
			break
		end

		if Tool.Parent then
			FruitSniperStatus = "Sniping " .. Tool.Name

			if SnipeFruit(Tool) then
				WindUI:Notify({ Title = "Fruit Sniper", Content = "Picked up " .. Tool.Name .. "!", Duration = 4 })

				if getgenv().Settings.FruitSniper.StoreToBag then
					if CanStoreFruit(Tool.Name) then
						if StoreFruit(Tool) then
							WindUI:Notify({
								Title = "Fruit Sniper",
								Content = Tool.Name .. " stored in Fruit Bag.",
								Duration = 4,
							})
						end
					else
						WindUI:Notify({
							Title = "Fruit Sniper",
							Content = Tool.Name .. " already stored (max copies), kept in backpack.",
							Duration = 4,
						})
					end
				end
			end
		end
	end

	EndRunner("Sniper")
	FruitSniperStatus = "Waiting for spawns"
end

SniperSection = FruitsTab:Section({ Title = "tr:FruitSniperSection", Icon = "crosshair", Opened = true })

SniperSection:Dropdown({
	Title = "tr:FruitWhitelist",
	Path = "FruitSniper.Whitelist",
	Desc = "tr:FruitWhitelistDesc",
	Multi = true,
	AllowNone = true,
	Value = getgenv().Settings.FruitSniper.Whitelist,
	Values = FruitNames,
	Callback = function(Value)
		getgenv().Settings.FruitSniper.Whitelist = NormalizeList(Value)
		SaveSetting()
	end,
})

SniperSection:Toggle({
	Title = "tr:FruitStoreToBag",
	Path = "FruitSniper.StoreToBag",
	Desc = "tr:FruitStoreToBagDesc",
	Value = getgenv().Settings.FruitSniper.StoreToBag,
	Icon = "check",
	Callback = function(Value)
		getgenv().Settings.FruitSniper.StoreToBag = Value
		SaveSetting()
	end,
})

VenuzToggle.FruitSniper = function(Value)
	getgenv().Settings.FruitSniper.Enabled = Value
	SaveSetting()

	if not Value then
		FruitSniperRunning = false
		FruitSniperStatus = "Idle"
		EndRunner("Sniper")
		return
	end

	if FruitSniperRunning then
		return
	end

	FruitSniperRunning = true

	task.spawn(function()
		while FruitSniperRunning and getgenv().Settings.FruitSniper.Enabled do
			if not IsCurrentInstance() then
				break
			end

			if IsAlive() then
				pcall(SniperStep)

				EndRunner("Sniper")
			end
			task.wait(1)
		end

		FruitSniperRunning = false
		EndRunner("Sniper")
	end)
end

FruitSniperToggle = SniperSection:Toggle({
	Title = "tr:FruitSniper",
	Path = "FruitSniper.Enabled",
	Desc = "tr:FruitSniperDesc",

	Value = getgenv().Settings.FruitSniper.Enabled,
	Icon = "check",
	Callback = VenuzToggle.FruitSniper,
})

FruitTeleportSection = FruitsTab:Section({ Title = "tr:FruitTeleportSection", Icon = "map-pin", Opened = true })

SelectedWorldFruit = getgenv().Settings.SelectedFruit ~= "" and getgenv().Settings.SelectedFruit or nil

WorldFruitDropdown = FruitTeleportSection:Dropdown({
	Title = "tr:FruitSelect",
	Path = "SelectedFruit",
	Desc = "tr:FruitSelectDesc",
	Multi = false,
	AllowNone = true,
	Values = (function()
		local Names = {}
		for _, Tool in ipairs(GetWorldFruits()) do
			table.insert(Names, Tool.Name)
		end
		return Names
	end)(),
	Value = SelectedWorldFruit,
	Callback = function(Value)
		SelectedWorldFruit = Value
		getgenv().Settings.SelectedFruit = Value or ""
		SaveSetting()
	end,
})

FruitTeleportSection:Button({
	Title = "tr:FruitRefresh",
	Desc = "tr:FruitRefreshDesc",
	Callback = function()
		local Names = {}
		for _, Tool in ipairs(GetWorldFruits()) do
			table.insert(Names, Tool.Name)
		end

		pcall(function()
			WorldFruitDropdown:Refresh(Names)
		end)
		WindUI:Notify({ Title = "Fruits", Content = #Names .. " fruit(s) on the map.", Duration = 4 })
	end,
})

FruitTeleportSection:Button({
	Title = "tr:TeleportGo",
	Desc = "tr:FruitTeleportGoDesc",
	Callback = function()
		if not SelectedWorldFruit then
			return
		end

		for _, Tool in ipairs(GetWorldFruits()) do
			if Tool.Name == SelectedWorldFruit then
				local Position = FruitPosition(Tool)
				if Position then
					TeleportTo(Position)
					return
				end
			end
		end

		WindUI:Notify({ Title = "Fruits", Content = "Fruit is no longer on the map.", Duration = 4 })
	end,
})

if getgenv().Settings.FruitSniper.Enabled then
	task.defer(VenuzToggle.FruitSniper, true)
end
;
(function()
	local EatSection = FruitsTab:Section({ Title = "tr:EatSection", Icon = "utensils", Opened = true })
	local EatParagraph = RT.Status(EatSection, "tr:EatStatus")

	local ET = {
		Status = "Idle",
		Running = false,
		Loop = nil,
		LastPull = 0,
		LastEat = 0,
		Toggle = nil,
	}

	local function EatTarget()
		local Value = getgenv().Settings.AutoEatFruit.Fruit

		if type(Value) == "table" then
			Value = NormalizeList(Value)[1]
		end

		return (type(Value) == "string" and Value ~= "") and Value or nil
	end

	local function EatenFruitName()
		return PlayerDataString("CurrentSuperPower", "")
	end

	local function BagCount(Name)
		local Value = PlayerData:FindFirstChild("CollectedFruits")
		local Raw = Value and tostring(Value.Value) or ""
		local Total = 0

		for Item in string.gmatch(Raw, "[^,]+") do
			if Item:match("^%s*(.-)%s*$") == Name then
				Total = Total + 1
			end
		end

		return Total
	end

	local function CarriedFruit(Name)
		for _, Container in ipairs({ GetCharacter(), LocalPlayer:FindFirstChildOfClass("Backpack") }) do
			if Container then
				local Tool = Container:FindFirstChild(Name)

				if Tool and Tool:IsA("Tool") and not IsEatenFruit(Tool) then
					return Tool
				end
			end
		end

		return nil
	end

	local function PullFromBag(Name)
		local Gui = LocalPlayer:FindFirstChild("PlayerGui")
		local Inventory = Gui and Gui:FindFirstChild("Inventory")
		local Equip = Inventory and Inventory:FindFirstChild("Equip")

		if not (Equip and Equip:IsA("RemoteFunction")) then
			return false
		end

		return (pcall(function()
			Equip:InvokeServer(Name)
		end))
	end

	local function IsEatingNow()
		local Character = GetCharacter()
		local Flag = Character and Character:FindFirstChild("Eating")
		return Flag ~= nil and Flag.Value == true
	end

	local function EatCarried(Tool)
		local Humanoid = GetHumanoid()

		if not Humanoid then
			return false
		end

		if Tool.Parent ~= GetCharacter() then
			pcall(function()
				Humanoid:EquipTool(Tool)
			end)
			task.wait(0.3)
		end

		if Tool.Parent ~= GetCharacter() then
			return false
		end

		local Activate = Tool:FindFirstChild("Activate")

		if not (Activate and Activate:IsA("RemoteEvent")) then
			return false
		end

		return (pcall(function()
			Activate:FireServer()
		end))
	end

	local function StopEat()
		ET.Running = false
		ET.Status = "Idle"

		if ET.Loop then
			pcall(function()
				task.cancel(ET.Loop)
			end)
			ET.Loop = nil
		end
	end

	local function FinishEat(Name)
		getgenv().Settings.AutoEatFruit.Enabled = false
		SaveSetting()
		StopEat()
		ET.Status = "Ate the " .. Name .. " fruit"
		SetToggleValue(ET.Toggle, false)

		WindUI:Notify({
			Title = "Auto Eat Fruit",
			Content = ConfigThai() and ("กิน " .. Name .. " แล้ว") or ("Ate the " .. Name .. " fruit."),
			Duration = 5,
		})
	end

	local function EatStep()
		local Name = EatTarget()

		if not Name then
			ET.Status = "Pick a fruit first"
			task.wait(1)
			return
		end

		if EatenFruitName() == Name then
			FinishEat(Name)
			return
		end

		if not IsAlive() then
			ET.Status = "Waiting for the character"
			task.wait(1)
			return
		end

		if IsEatingNow() then
			ET.Status = "Eating " .. Name
			task.wait(0.5)
			return
		end

		local Tool = CarriedFruit(Name)

		if not Tool then
			local Stored = BagCount(Name)

			if Stored <= 0 then
				ET.Status = "No " .. Name .. " in the backpack or Fruit Bag"
				task.wait(1)
				return
			end

			if tick() - ET.LastPull >= 1.5 then
				ET.LastPull = tick()
				ET.Status = "Taking " .. Name .. " out of the Fruit Bag (" .. Stored .. " stored)"
				PullFromBag(Name)
				task.wait(0.6)
			end

			return
		end

		if tick() - ET.LastEat < 2.5 then
			task.wait(0.2)
			return
		end

		ET.LastEat = tick()
		ET.Status = "Eating " .. Name

		if not EatCarried(Tool) then
			ET.Status = "Could not eat " .. Name .. ", trying again"
		end

		task.wait(1)
	end

	local function SyncEat()
		if getgenv().Settings.AutoEatFruit.Enabled ~= true then
			StopEat()
			return
		end

		if not EatTarget() then
			getgenv().Settings.AutoEatFruit.Enabled = false
			SaveSetting()
			StopEat()
			SetToggleValue(ET.Toggle, false)

			WindUI:Notify({
				Title = "Auto Eat Fruit",
				Content = ConfigThai() and "เลือกผลที่จะกินก่อน" or "Pick the fruit to eat first.",
				Duration = 5,
			})

			return
		end

		if ET.Running then
			return
		end

		ET.Running = true

		ET.Loop = task.spawn(function()
			while ET.Running do
				task.wait(0.3)

				if not IsCurrentInstance() then
					ET.Running = false
					break
				end

				if not pcall(EatStep) then
					task.wait(0.5)
				end
			end
		end)
	end

	EatSection:Dropdown({
		Title = "tr:EatSelect",
		Path = "AutoEatFruit.Fruit",
		Desc = "tr:EatSelectDesc",
		Multi = false,
		AllowNone = true,
		Values = FruitNames,
		Value = EatTarget(),
		Callback = function(Value)
			if type(Value) == "table" then
				Value = NormalizeList(Value)[1]
			end

			getgenv().Settings.AutoEatFruit.Fruit = type(Value) == "string" and Value or ""
			SaveSetting()
			SyncEat()
		end,
	})

	ET.Toggle = EatSection:Toggle({
		Title = "tr:EatToggle",
		Path = "AutoEatFruit.Enabled",
		Desc = "tr:EatToggleDesc",
		Value = getgenv().Settings.AutoEatFruit.Enabled,
		Icon = "check",
		Callback = function(Value)
			getgenv().Settings.AutoEatFruit.Enabled = Value
			SaveSetting()
			SyncEat()
		end,
	})

	task.spawn(function()
		while task.wait(1) do
			if not IsCurrentInstance() then
				break
			end

			RT.Push("Auto Eat Fruit", EatParagraph, function()
				local Name = EatTarget()
				local Eaten = EatenFruitName()
				local Lines = {
					RT.Head("Auto Eat Fruit", RT.Purple),
					RT.State(ET.Status, ET.Running),
					RT.Field("Eaten now", Eaten ~= "" and Eaten or "none", Eaten ~= "" and RT.Purple or RT.Muted)
						.. RT.Sep
						.. RT.Field("Wanted", Name or "none", Name and RT.Text or RT.Muted),
				}

				if Name then
					RT.Add(
						Lines,
						RT.Flag("In backpack", CarriedFruit(Name) ~= nil)
							.. RT.Sep
							.. RT.Field("In Fruit Bag", tostring(BagCount(Name)))
					)
				end

				return table.concat(Lines, "\n")
			end)
		end
	end)

	if getgenv().Settings.AutoEatFruit.Enabled then
		task.defer(SyncEat)
	end
end)()
;
(function()
	local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

	local PowersConfig = (function()
		local ok, Config = pcall(function()
			return require(game:GetService("ReplicatedStorage"):WaitForChild("Config"):WaitForChild("Powers"))
		end)
		return ok and Config or {}
	end)()

	local function GetRobuxMarket()
		local Gui = PlayerGui:FindFirstChild("FruitShop")
		if not Gui then
			return nil
		end

		local Main = Gui:FindFirstChild("MainFrame")
		Main = Main and Main:FindFirstChild("FruitShop")
		Main = Main and Main:FindFirstChild("Main")
		Main = Main and Main:FindFirstChild("PageHolder")

		return Main and Main:FindFirstChild("Robux Market") or nil
	end

	local function GetBuyRemote()
		local Market = GetRobuxMarket()
		return Market and Market:FindFirstChild("BuyFruitWithBeli") or nil
	end

	local function GetFruitsBought()
		local Value = PlayerData:FindFirstChild("FruitsBought")
		return Value and tostring(Value.Value) or ""
	end

	local function AlreadyBought(Name)
		return string.find(GetFruitsBought(), Name, 1, true) ~= nil
	end

	local function FruitPrice(Name)
		local Entry = PowersConfig[Name]
		return Entry and tonumber(Entry.BeliPrice) or 0
	end

	local function GetBeli()
		local Names = { "Beli", "Money", "Cash" }

		for _, Container in ipairs({ LocalPlayer:FindFirstChild("leaderstats"), PlayerData, LocalPlayer }) do
			if Container then
				for _, Key in ipairs(Names) do
					local Value = Container:FindFirstChild(Key)
					if Value and (Value:IsA("NumberValue") or Value:IsA("IntValue")) then
						return Value.Value
					end
				end
			end
		end

		return nil
	end

	local FruitBagPasses = { FruitBag = 5, UnlimitedFruitBag = 15 }

	local function GetStorableCopies()
		local Inventory = PlayerGui:FindFirstChild("Inventory")
		local Label = Inventory and Inventory:FindFirstChild("MainFrame")
		Label = Label and Label:FindFirstChild("Overhead")
		Label = Label and Label:FindFirstChild("Storage")
		Label = Label and Label:FindFirstChild("Amount")

		if Label and Label:IsA("TextLabel") then
			local Number = tonumber(string.match(Label.Text, "(%-?%d+)"))
			if Number then
				return Number
			end
		end

		local Storable = PlayerData:FindFirstChild("FruitCopiesStorable")
		if not Storable then
			return nil
		end

		local Bonus = 0
		local Owned = LocalPlayer:FindFirstChild("GamepassesOwn")
		local Gifted = PlayerData:FindFirstChild("GiftedPasses")

		for Name, Amount in pairs(FruitBagPasses) do
			local Own = Owned and Owned:FindFirstChild(Name)
			local Gift = Gifted and Gifted:FindFirstChild(Name)
			if (Own and Own.Value) or (Gift and Gift.Value) then
				Bonus = Bonus + Amount
			end
		end

		return Bonus + Storable.Value
	end

	local function HasWhitelist(Whitelist)
		return type(Whitelist) == "table" and next(Whitelist) ~= nil
	end

	local function IsWantedBy(Whitelist, Name)
		if not HasWhitelist(Whitelist) then
			return false
		end

		for Key, Value in pairs(Whitelist) do
			if Value == Name or (Value == true and Key == Name) then
				return true
			end
		end

		return false
	end

	local function GetShopStock()
		local Stock = {}
		local Market = GetRobuxMarket()

		if not Market then
			return Stock
		end

		for _, Child in ipairs(Market:GetChildren()) do
			if Child:IsA("GuiObject") and Child:FindFirstChild("Holder") and PowersConfig[Child.Name] then
				table.insert(Stock, {
					Name = Child.Name,
					Frame = Child,
					InStock = Child:GetAttribute("InStock") and true or false,
					Price = FruitPrice(Child.Name),
					Bought = AlreadyBought(Child.Name),
				})
			end
		end

		table.sort(Stock, function(a, b)
			return a.Name < b.Name
		end)

		return Stock
	end

	local function GetDealerPosition()
		local Sellers = workspace:FindFirstChild("Npc_Workspace")
		Sellers = Sellers and Sellers:FindFirstChild("BlackMarket Sellers")
		local Dealer = Sellers and Sellers:FindFirstChild("Fruit Dealer")
		local Npc = Dealer and Dealer:FindFirstChild("NPC")
		local Root = Npc and (Npc:FindFirstChild("HumanoidRootPart") or Npc:FindFirstChild("Clicker"))

		return Root and Root.Position or nil
	end

	local function WaitForFruitTool(Name, Timeout)
		local Deadline = tick() + (Timeout or 10)

		while tick() < Deadline do
			for _, Tool in ipairs(GetBackpackFruits()) do
				if Tool.Name == Name then
					return Tool
				end
			end
			task.wait(0.25)
		end

		return nil
	end

	local DealerRunning = false
	local DealerStatus = "Idle"

	local function BuyFruitFromDealer(Entry)
		local Remote = GetBuyRemote()
		if not Remote then
			return false, "Fruit shop UI not loaded"
		end

		if not Entry.InStock then
			return false, "Out of stock"
		end

		if AlreadyBought(Entry.Name) then
			return false, "Already bought this rotation"
		end

		local Setting = getgenv().Settings.FruitDealer

		local Beli = GetBeli()
		if Beli and Entry.Price > 0 and Beli < Entry.Price then
			return false, "Not enough Beli"
		end

		local ok = pcall(function()
			Remote:InvokeServer(Entry.Name)
		end)
		if not ok then
			return false, "Purchase remote failed"
		end

		local Tool = WaitForFruitTool(Entry.Name, 10)
		if not Tool then
			return AlreadyBought(Entry.Name), "Bought, but the fruit never reached the backpack"
		end

		if Setting.StoreToBag then
			DealerStatus = "Storing " .. Entry.Name
			StoreFruit(Tool)
		end

		return true, nil
	end

	local WhitelistWarned = false

	local function DealerStep()
		local Setting = getgenv().Settings.FruitDealer

		if not HasWhitelist(Setting.Whitelist) then
			DealerStatus = "No fruit selected"
			if not WhitelistWarned then
				WhitelistWarned = true
				WindUI:Notify({
					Title = "Fruit Dealer",
					Content = "Select at least one fruit in the whitelist first.",
					Duration = 6,
				})
			end
			return
		end

		WhitelistWarned = false

		local Stock = GetShopStock()

		if #Stock == 0 then
			DealerStatus = "Shop not loaded"
			return
		end

		for _, Entry in ipairs(Stock) do
			if not DealerRunning then
				return
			end

			if Entry.InStock and not Entry.Bought and IsWantedBy(Setting.Whitelist, Entry.Name) then
				DealerStatus = "Buying " .. Entry.Name
				local Bought, Reason = BuyFruitFromDealer(Entry)

				if Bought then
					WindUI:Notify({
						Title = "Fruit Dealer",
						Content = "Bought " .. Entry.Name .. " for " .. Entry.Price .. " Beli.",
						Duration = 5,
					})
				elseif Reason and Reason ~= "Out of stock" and Reason ~= "Already bought this rotation" then
					WindUI:Notify({
						Title = "Fruit Dealer",
						Content = Entry.Name .. ": " .. Reason,
						Duration = 5,
					})
				end
			end
		end

		DealerStatus = "Waiting stock"
	end

	local DealerSection = FruitsTab:Section({ Title = "tr:DealerSection", Icon = "store", Opened = true })

	DealerSection:Dropdown({
		Title = "tr:DealerWhitelist",
		Path = "FruitDealer.Whitelist",
		Desc = "tr:DealerWhitelistDesc",
		Multi = true,
		AllowNone = true,
		Value = getgenv().Settings.FruitDealer.Whitelist,
		Values = FruitNames,
		Callback = function(Value)
			getgenv().Settings.FruitDealer.Whitelist = NormalizeList(Value)
			SaveSetting()
		end,
	})

	DealerSection:Toggle({
		Title = "tr:DealerStore",
		Path = "FruitDealer.StoreToBag",
		Desc = "tr:DealerStoreDesc",
		Value = getgenv().Settings.FruitDealer.StoreToBag,
		Icon = "check",
		Callback = function(Value)
			getgenv().Settings.FruitDealer.StoreToBag = Value
			SaveSetting()
		end,
	})

	DealerSection:Button({
		Title = "tr:DealerRefresh",
		Desc = "tr:DealerRefreshDesc",
		Callback = function()
			local Stock = GetShopStock()

			if #Stock == 0 then
				WindUI:Notify({ Title = "Fruit Dealer", Content = "Fruit shop UI not loaded yet.", Duration = 5 })
				return
			end

			local Lines = {}
			for _, Entry in ipairs(Stock) do
				if Entry.InStock and not Entry.Bought then
					local Fits, Left = CanStoreFruit(Entry.Name)
					local Note = Fits and (Left and (" (" .. Left .. " left)") or "") or " (already stored)"
					table.insert(Lines, Entry.Name .. " - " .. Entry.Price .. Note)
				end
			end

			local Storable = GetStorableCopies()
			local Header = "Storable Copies per fruit: " .. (Storable and tostring(Storable) or "?")

			WindUI:Notify({
				Title = "Fruit Dealer",
				Content = Header .. "\n" .. (#Lines > 0 and table.concat(Lines, "\n") or "Nothing in stock."),
				Duration = 8,
			})
		end,
	})

	local FruitDealerToggle
	VenuzToggle.FruitDealer = function(Value)
		getgenv().Settings.FruitDealer.Enabled = Value
		SaveSetting()

		if not Value then
			DealerRunning = false
			DealerStatus = "Idle"
			return
		end

		if not HasWhitelist(getgenv().Settings.FruitDealer.Whitelist) then
			getgenv().Settings.FruitDealer.Enabled = false
			SaveSetting()
			DealerRunning = false
			DealerStatus = "No fruit selected"
			WindUI:Notify({
				Title = "Fruit Dealer",
				Content = "Select at least one fruit in the whitelist before enabling.",
				Duration = 6,
			})
			SetToggleValue(FruitDealerToggle, false)
			return
		end

		if DealerRunning then
			return
		end

		DealerRunning = true

		task.spawn(function()
			while DealerRunning and getgenv().Settings.FruitDealer.Enabled do
				if IsAlive() then
					pcall(DealerStep)
				end
				task.wait(3)
			end

			DealerRunning = false
		end)
	end

	FruitDealerToggle = DealerSection:Toggle({
		Title = "tr:DealerAuto",
		Path = "FruitDealer.Enabled",
		Desc = "tr:DealerAutoDesc",

		Value = getgenv().Settings.FruitDealer.Enabled,
		Icon = "check",
		Callback = VenuzToggle.FruitDealer,
	})

	if getgenv().Settings.FruitDealer.Enabled then
		task.defer(VenuzToggle.FruitDealer, true)
	end

	local SpinPrices = {
		Beli = 125000,
		Gem = 50,
		Robux = 200,
	}

	local function GetGems()
		for _, Container in ipairs({ LocalPlayer:FindFirstChild("leaderstats"), PlayerData, LocalPlayer }) do
			if Container then
				for _, Key in ipairs({ "Gems", "Gem", "Diamond" }) do
					local Value = Container:FindFirstChild(Key)
					if Value and (Value:IsA("NumberValue") or Value:IsA("IntValue")) then
						return Value.Value
					end
				end
			end
		end
		return 0
	end

	local function GetFruitSpins()
		local Details = PlayerData and PlayerData:FindFirstChild("FruitSpinDetails")
		local Spins = Details and Details:FindFirstChild("FruitSpins")
		if not Spins then
			return nil
		end
		return tonumber(Spins.Value)
	end

	local function GetSpinMarket()
		local Gui = PlayerGui:FindFirstChild("FruitShop")
		if not Gui then
			return nil
		end

		local Main = Gui:FindFirstChild("MainFrame")
		Main = Main and Main:FindFirstChild("FruitShop")
		Main = Main and Main:FindFirstChild("Main")
		Main = Main and Main:FindFirstChild("PageHolder")

		return Main and Main:FindFirstChild("Spin Market") or nil
	end

	local function GetSpinButton(Currency)
		local SpinMarket = GetSpinMarket()
		local Buttons = SpinMarket and SpinMarket:FindFirstChild("SpinButtons")
		if not Buttons then
			return nil
		end

		local Button
		if Currency == "Gem" then
			Button = Buttons:FindFirstChild("GemsSpinButton")
		elseif Currency == "Robux" then
			Button = Buttons:FindFirstChild("RobuxSpinButton")
		else
			Button = Buttons:FindFirstChild("MoneySpinButton")
		end

		return Button
	end

	local function WaitUntil(Check, Timeout, Interval)
		local Deadline = os.clock() + (Timeout or 10)

		while true do
			local Ok, Result = pcall(Check)
			if Ok and Result then
				return Result
			end

			if os.clock() >= Deadline then
				return nil
			end

			task.wait(Interval or 0.15)
		end
	end

	local function GetStripOffset()
		local SpinMarket = GetSpinMarket()
		local Spin = SpinMarket and SpinMarket:FindFirstChild("Spin")
		local Strip = Spin and Spin:FindFirstChild("Strip")
		return Strip and Strip.Position.X.Scale or nil
	end

	local function ShopIsOpen()
		local Gui = PlayerGui:FindFirstChild("FruitShop")
		local Handle = Gui and Gui:FindFirstChild("BlackMarketHandle")
		local Opened = Handle and Handle:FindFirstChild("Opened")
		local MainFrame = Gui and Gui:FindFirstChild("MainFrame")

		return Opened ~= nil and Opened.Value == true and MainFrame ~= nil and MainFrame.AbsoluteSize.X > 0
	end

	local function ShowSpinPage()
		local Gui = PlayerGui:FindFirstChild("FruitShop")
		local PageHolder = Gui and Gui:FindFirstChild("MainFrame")
		PageHolder = PageHolder and PageHolder:FindFirstChild("FruitShop")
		PageHolder = PageHolder and PageHolder:FindFirstChild("Main")
		PageHolder = PageHolder and PageHolder:FindFirstChild("PageHolder")
		if not PageHolder then
			return false
		end

		local SpinMarket = PageHolder:FindFirstChild("Spin Market")
		local RobuxMarket = PageHolder:FindFirstChild("Robux Market")
		if SpinMarket then
			SpinMarket.Visible = true
		end
		if RobuxMarket then
			RobuxMarket.Visible = false
		end

		return SpinMarket ~= nil
	end

	local function OpenBlackMarket(Timeout)
		if ShopIsOpen() then
			return false
		end

		local Gui = PlayerGui:FindFirstChild("FruitShop")
		local Handle = Gui and Gui:FindFirstChild("BlackMarketHandle")
		local MainFrame = Gui and Gui:FindFirstChild("MainFrame")

		pcall(function()
			local ShopBtn = PlayerGui.ShopGui.MainFrame.Store.Main.Store.Market.Holder.Button
			if getconnections then
				for _, Signal in ipairs({ ShopBtn.MouseButton1Click, ShopBtn.MouseButton1Down, ShopBtn.Activated }) do
					for _, Connection in pairs(getconnections(Signal)) do
						pcall(function()
							Connection:Fire()
						end)
					end
				end
			end
			if firesignal then
				firesignal(ShopBtn.MouseButton1Click)
				firesignal(ShopBtn.MouseButton1Down)
			end
		end)

		if Handle then
			pcall(function()
				Handle:Fire()
			end)
		end

		WaitUntil(ShopIsOpen, Timeout or 12)

		pcall(function()
			if MainFrame and MainFrame.Size.X.Scale == 0 then
				MainFrame.Size = UDim2.fromScale(1, 1)
				MainFrame.Position = UDim2.fromScale(0, 0)
				MainFrame.Visible = true
			end
		end)

		return true
	end

	local function CloseBlackMarket()
		local Gui = PlayerGui:FindFirstChild("FruitShop")
		local Handle = Gui and Gui:FindFirstChild("BlackMarketHandle")
		local MainFrame = Gui and Gui:FindFirstChild("MainFrame")
		local Opened = Handle and Handle:FindFirstChild("Opened")

		if not (Opened and MainFrame) then
			return
		end

		Opened.Value = false
		pcall(function()
			game:GetService("TweenService")
				:Create(MainFrame, TweenInfo.new(0.5), {
					Size = UDim2.fromScale(0, 0),
					Position = MainFrame.Position + UDim2.fromScale(0, 1),
				})
				:Play()
		end)
	end

	local function PressGuiButton(Button)
		return pcall(function()
			Button.Selectable = true
			Button.SelectionImageObject = nil

			local GuiService = game:GetService("GuiService")
			local VIM = game:GetService("VirtualInputManager")

			GuiService.SelectedObject = Button
			VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, nil)
			task.wait(0.1)
			VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, nil)
			task.wait(0.4)
			GuiService.SelectedObject = nil
		end)
	end

	local function ConfirmRobuxPrompt(Timeout)
		local Deadline = os.clock() + (Timeout or 12)

		while os.clock() < Deadline do
			local Target
			pcall(function()
				local Root = (gethui and gethui()) or game:GetService("CoreGui")
				local App = Root:FindFirstChild("PurchasePromptApp") or Root:FindFirstChild("PurchasePrompt")
				if not App then
					return
				end

				for _, Item in ipairs(App:GetDescendants()) do
					if Item:IsA("TextButton") and Item.Visible then
						local Text = string.lower(tostring(Item.Text))
						if string.find(Text, "buy", 1, true) or string.find(Text, "ซื้อ", 1, true) then
							Target = Item
							break
						end
					end
				end
			end)

			if Target then
				PressGuiButton(Target)
				return true
			end

			task.wait(0.3)
		end

		return false
	end

	local SpinFruitRunning = false
	local SpinFruitStatus = "Idle"
	local SpinFruitStatusLabel

	local SpinProbed = false

	local function SetSpinStatus(Text)
		SpinFruitStatus = Text

		if SpinFruitStatusLabel then
			local Frame = RT.Frame(SpinFruitStatusLabel)
			pcall(function()
				Frame:SetTitle("Status: " .. Text)
			end)
		end
	end

	local function SpinFruitStep()
		local Setting = getgenv().Settings.AutoSpinFruit
		local Currency = Setting.Currency or "Beli"

		local function Balance()
			if Currency == "Beli" then
				return GetBeli()
			elseif Currency == "Gem" then
				return GetGems()
			end
			return nil
		end

		local BeforeSpins = GetFruitSpins()

		if BeforeSpins ~= nil and BeforeSpins <= 0 and SpinProbed then
			SetSpinStatus("No spins left (FruitSpins = 0)")
			pcall(CloseBlackMarket)
			return
		end

		local BeforeBalance = Balance()
		if Currency == "Beli" and BeforeBalance and BeforeBalance < SpinPrices.Beli then
			SetSpinStatus("Not enough Beli (need 125,000)")
			return
		elseif Currency == "Gem" and BeforeBalance and BeforeBalance < SpinPrices.Gem then
			SetSpinStatus("Not enough Gems (need 50)")
			return
		end

		if not ShopIsOpen() then
			SetSpinStatus("Opening Black Market...")
			OpenBlackMarket(15)

			if not WaitUntil(ShopIsOpen, 15) then
				SetSpinStatus("Black Market UI did not open")
				return
			end
		end

		SetSpinStatus("Waiting for Spin Market...")
		if not WaitUntil(ShowSpinPage, 15) then
			SetSpinStatus("Spin Market page not found")
			return
		end

		local SpinBtn = WaitUntil(function()
			local Button = GetSpinButton(Currency)
			if not Button then
				return nil
			end

			if Currency == "Robux" then
				Button.Visible = true
				if Button.Parent then
					Button.Parent.Visible = true
				end
			end

			if Button.Visible and Button.AbsoluteSize.X > 0 then
				return Button
			end

			return nil
		end, 15)

		if not SpinBtn then
			SetSpinStatus("Spin button not ready")
			return
		end

		local BeforeFruits = GetBackpackFruits()
		local StartOffset = GetStripOffset() or 0
		local Started = false

		for Attempt = 1, 3 do
			SetSpinStatus("Spinning with " .. Currency .. " (try " .. Attempt .. ")...")
			PressGuiButton(SpinBtn)

			if Currency == "Robux" then
				SetSpinStatus("Confirming Robux purchase...")
				if not ConfirmRobuxPrompt(15) then
					SetSpinStatus("Robux prompt not confirmed (confirm it manually)")
				end
			end

			Started = WaitUntil(function()
				local Offset = GetStripOffset()
				if Offset and math.abs(Offset - StartOffset) > 0.05 then
					return true
				end

				local Now = Balance()
				if BeforeBalance and Now and Now < BeforeBalance then
					return true
				end

				local NowSpins = GetFruitSpins()
				if BeforeSpins and NowSpins and NowSpins < BeforeSpins then
					return true
				end

				return false
			end, 6) ~= nil

			if Started then
				break
			end
		end

		if not Started then
			if BeforeSpins ~= nil and BeforeSpins <= 0 and (GetFruitSpins() or 0) <= 0 then
				SpinProbed = true
				SetSpinStatus("No spins left (FruitSpins = 0)")
				pcall(CloseBlackMarket)
				return
			end

			SetSpinStatus("Click did not register, retrying next cycle")
			return
		end

		SpinProbed = false

		SetSpinStatus("Spinning animation...")
		WaitUntil(function()
			local Offset = GetStripOffset()
			return Offset ~= nil and Offset <= -10
		end, 25)

		task.wait(1)

		if Setting.StoreToBag then
			local NewFruits = WaitUntil(function()
				for _, Tool in ipairs(GetBackpackFruits()) do
					local IsNew = true
					for _, Old in ipairs(BeforeFruits) do
						if Old == Tool then
							IsNew = false
							break
						end
					end
					if IsNew then
						return true
					end
				end
				return false
			end, 5)

			if NewFruits then
				for _, Tool in ipairs(GetBackpackFruits()) do
					local IsNew = true
					for _, Old in ipairs(BeforeFruits) do
						if Old == Tool then
							IsNew = false
							break
						end
					end

					if IsNew then
						SetSpinStatus("Storing " .. Tool.Name)
						StoreFruit(Tool)
					end
				end
			end
		end

		SetSpinStatus("Waiting...")
	end

	VenuzToggle.AutoSpinFruit = function(Value)
		getgenv().Settings.AutoSpinFruit.Enabled = Value
		SaveSetting()

		if not Value then
			SpinFruitRunning = false
			SetSpinStatus("Idle")
			pcall(CloseBlackMarket)
			return
		end

		if SpinFruitRunning then
			return
		end

		SpinProbed = false
		SpinFruitRunning = true

		task.spawn(function()
			while SpinFruitRunning and getgenv().Settings.AutoSpinFruit.Enabled do
				if IsAlive() then
					pcall(SpinFruitStep)
				end
				task.wait(0.5)
			end

			SpinFruitRunning = false
			pcall(CloseBlackMarket)
		end)
	end

	local SpinFruitSection = FruitsTab:Section({ Title = "tr:SpinFruitSection", Icon = "shuffle", Opened = true })

	SpinFruitStatusLabel = SpinFruitSection:Paragraph({
		Title = "Status: Idle",
		Desc = "tr:SpinFruitAutoDesc",
	})

	SpinFruitSection:Dropdown({
		Title = "tr:SpinFruitCurrency",
		Path = "AutoSpinFruit.Currency",
		Desc = "tr:SpinFruitCurrencyDesc",
		Multi = false,
		AllowNone = false,
		Value = getgenv().Settings.AutoSpinFruit.Currency,
		Values = { "Beli", "Gem", "Robux" },
		Callback = function(Value)
			getgenv().Settings.AutoSpinFruit.Currency = Value
			SaveSetting()
		end,
	})

	SpinFruitSection:Toggle({
		Title = "tr:SpinFruitStore",
		Path = "AutoSpinFruit.StoreToBag",
		Desc = "tr:SpinFruitStoreDesc",
		Value = getgenv().Settings.AutoSpinFruit.StoreToBag,
		Icon = "check",
		Callback = function(Value)
			getgenv().Settings.AutoSpinFruit.StoreToBag = Value
			SaveSetting()
		end,
	})

	SpinFruitSection:Toggle({
		Title = "tr:SpinFruitAuto",
		Desc = "tr:SpinFruitAutoDesc",
		Path = "AutoSpinFruit.Enabled",
		Value = getgenv().Settings.AutoSpinFruit.Enabled,
		Icon = "check",
		Callback = VenuzToggle.AutoSpinFruit,
	})

	if getgenv().Settings.AutoSpinFruit.Enabled then
		task.defer(VenuzToggle.AutoSpinFruit, true)
	end
end)()
;
(function()
	local FishingTab = TabGroups.Farm:Tab({
		Title = "tr:FishingTab",
		Icon = "fish",
		Locked = false,
	})
	SetTabOrder(FishingTab, 4)

	local FishingRodRequest = ClientEvents:WaitForChild("FishingRodRequest")
	local CollectFish = ClientEvents:WaitForChild("CollectFish")
	local WaterModel = workspace:WaitForChild("Logic"):WaitForChild("Water")

	local RodPriority = { ["Legendary Fishing Rod"] = 3, ["Rare Fishing Rod"] = 2, ["Wooden Fishing Rod"] = 1 }
	local FishRarities = { "Common", "Rare", "Legendary", "Mythical" }

	local CastSettleTime = 0.15
	local SpotInterval = 0.1
	local CatchSettleTime = 0.15
	local CycleDelay = 0.1

	local FishingRunning = false

	local function IsRodTool(Tool)
		return Tool:IsA("Tool") and string.find(Tool.Name, "Fishing Rod") ~= nil
	end

	local function GetToolContainers()
		return { GetCharacter(), LocalPlayer:FindFirstChildOfClass("Backpack") }
	end

	local function GetRodTool()
		local Best, BestScore = nil, -1

		for _, Container in ipairs(GetToolContainers()) do
			if Container then
				for _, Tool in ipairs(Container:GetChildren()) do
					if IsRodTool(Tool) then
						local Score = RodPriority[Tool.Name] or 0
						if Score > BestScore then
							Best, BestScore = Tool, Score
						end
					end
				end
			end
		end

		return Best
	end

	local function GetFishTool()
		for _, Container in ipairs(GetToolContainers()) do
			if Container then
				for _, Tool in ipairs(Container:GetChildren()) do
					if Tool:IsA("Tool") and not IsRodTool(Tool) then
						for _, Rarity in ipairs(FishRarities) do
							if string.sub(Tool.Name, 1, #Rarity) == Rarity then
								return Tool, Rarity
							end
						end
					end
				end
			end
		end
	end

	local function EquipTool(Tool)
		local Character = GetCharacter()
		local Humanoid = GetHumanoid()

		if not (Tool and Character and Humanoid) then
			return false
		end

		if Tool.Parent == Character then
			return true
		end

		pcall(function()
			Humanoid:EquipTool(Tool)
		end)

		local Deadline = os.clock() + 1
		while Tool.Parent ~= Character and os.clock() < Deadline do
			task.wait(0.05)
		end

		return Tool.Parent == Character
	end

	local FishRaycastParams = RaycastParams.new()
	FishRaycastParams.FilterDescendantsInstances = { WaterModel }
	if not pcall(function()
		FishRaycastParams.FilterType = Enum.RaycastFilterType.Include
	end) then
		pcall(function()
			FishRaycastParams.FilterType = Enum.RaycastFilterType.Whitelist
		end)
	end

	local function GetCastPosition(Distance)
		local Root = GetRoot()
		if not Root then
			return nil
		end

		local Target = Root.Position + Root.CFrame.LookVector * Distance
		local Result = workspace:Raycast(Target + Vector3.new(0, 250, 0), Vector3.new(0, -600, 0), FishRaycastParams)

		if Result then
			return Result.Position
		end

		return Vector3.new(Target.X, 2.5, Target.Z)
	end

	local function GetCacheCharacters()
		local Logic = workspace:FindFirstChild("Logic")
		local Cache = Logic and Logic:FindFirstChild("Cache")
		return Cache and Cache:FindFirstChild("Character")
	end

	local function GetCacheNode()
		local Characters = GetCacheCharacters()
		return Characters and Characters:FindFirstChild(LocalPlayer.Name)
	end

	local function StartFishWatch()
		local Watch = { Model = nil, Connection = nil, Known = {} }
		local Characters = GetCacheCharacters()

		if not Characters then
			return Watch
		end

		local Node = Characters:FindFirstChild(LocalPlayer.Name)
		if Node then
			for _, Child in ipairs(Node:GetDescendants()) do
				Watch.Known[Child] = true
			end
		end

		Watch.Connection = Characters.DescendantAdded:Connect(function(Descendant)
			if Watch.Model or not Descendant:IsA("Model") or Watch.Known[Descendant] then
				return
			end

			local Current = Characters:FindFirstChild(LocalPlayer.Name)
			if Current and (Descendant == Current or Descendant:IsDescendantOf(Current)) then
				Watch.Model = Descendant
			end
		end)

		return Watch
	end

	local function StopFishWatch(Watch)
		if Watch.Connection then
			pcall(function()
				Watch.Connection:Disconnect()
			end)
			Watch.Connection = nil
		end
	end

	local function PeekFishModel(Watch)
		if Watch.Model and Watch.Model.Parent then
			return Watch.Model
		end

		local Node = GetCacheNode()
		if Node then
			for _, Child in ipairs(Node:GetChildren()) do
				if Child:IsA("Model") and not Watch.Known[Child] then
					return Child
				end
			end
		end

		return nil
	end

	local function SpamSpotFish(Watch)
		while FishingRunning do
			pcall(function()
				FishingRodRequest:InvokeServer("SpotFish")
			end)

			local NextSend = os.clock() + SpotInterval
			repeat
				local Model = PeekFishModel(Watch)
				if Model then
					return Model
				end
				task.wait(0.03)
			until os.clock() >= NextSend or not FishingRunning
		end

		return PeekFishModel(Watch)
	end

	local function HandleCaughtFish()
		local Tool = GetFishTool()
		if Tool and EquipTool(Tool) then
			pcall(function()
				CollectFish:FireServer(Tool)
			end)
		end
	end

	local function FishingCycle()
		local Rod = GetRodTool()

		if not Rod then
			return false, "No fishing rod found"
		end

		if not EquipTool(Rod) then
			return false, "Failed to equip rod"
		end

		local RodName = Rod.Name
		local Position = GetCastPosition(getgenv().Settings.AutoFish.CastDistance)

		if not Position then
			return false, "No character"
		end

		local Watch = StartFishWatch()

		local Ok = pcall(function()
			FishingRodRequest:InvokeServer("Shoot", Position)
		end)

		if not Ok then
			StopFishWatch(Watch)
			return false, "Shoot rejected"
		end

		task.wait(CastSettleTime)

		local FishModel = SpamSpotFish(Watch)
		StopFishWatch(Watch)

		if FishModel then
			pcall(function()
				FishingRodRequest:InvokeServer("PullFish", FishModel)
			end)
		end

		pcall(function()
			FishingRodRequest:InvokeServer("Spool", RodName)
		end)

		task.wait(CatchSettleTime)
		pcall(HandleCaughtFish)

		return true
	end

	local FishMainSection = FishingTab:Section({ Title = "tr:FishMainSection", Icon = "fish", Opened = true })

	FishMainSection:Slider({
		Title = "tr:FishCastDistance",
		Path = "AutoFish.CastDistance",
		Desc = "tr:FishCastDistanceDesc",
		Value = {
			Min = 5,
			Max = 80,
			Default = getgenv().Settings.AutoFish.CastDistance,
		},
		Callback = function(Value)
			getgenv().Settings.AutoFish.CastDistance = tonumber(Value) or 25
			SaveSetting()
		end,
	})

	local AutoFishToggle
	VenuzToggle.AutoFish = function(Value)
		getgenv().Settings.AutoFish.Enabled = Value
		SaveSetting()

		if not Value then
			FishingRunning = false
			return
		end

		if not GetRodTool() then
			getgenv().Settings.AutoFish.Enabled = false
			SaveSetting()
			WindUI:Notify({
				Title = "Auto Fish",
				Content = "No fishing rod in your inventory. Buy one from the Fishing Rod Dealer first.",
				Duration = 6,
			})
			SetToggleValue(AutoFishToggle, false)
			return
		end

		if FishingRunning then
			return
		end

		FishingRunning = true

		task.spawn(function()
			while FishingRunning and getgenv().Settings.AutoFish.Enabled do
				if IsAlive() then
					local Ok, Reason = FishingCycle()

					if not Ok and Reason == "No fishing rod found" then
						WindUI:Notify({ Title = "Auto Fish", Content = Reason, Duration = 5 })
						break
					end
				end

				task.wait(CycleDelay)
			end

			FishingRunning = false
			getgenv().Settings.AutoFish.Enabled = false
			SetToggleValue(AutoFishToggle, false)
		end)
	end

	AutoFishToggle = FishMainSection:Toggle({
		Title = "tr:AutoFish",
		Desc = "tr:AutoFishDesc",
		Path = "AutoFish.Enabled",

		Value = getgenv().Settings.AutoFish.Enabled,
		Icon = "check",
		Callback = VenuzToggle.AutoFish,
	})

	if getgenv().Settings.AutoFish.Enabled then
		task.defer(VenuzToggle.AutoFish, true)
	end
end)()
;
(function()
	local QuestMobs, QuestBosses = {}, {}
	for _, Entry in ipairs(getgenv().LevelConfig or {}) do
		if Entry.MonName then
			QuestMobs[Entry.MonName] = true
			if IsBoss(Entry) then
				QuestBosses[Entry.MonName] = Entry.MonPOS
			end
		end
	end

	local BossNames = (function()
		local Set = {}

		local ok, Rewards = pcall(function()
			return require(game:GetService("ReplicatedStorage"):WaitForChild("Config"):WaitForChild("NPCRewards"))
		end)

		if ok and type(Rewards) == "table" then
			for Name in pairs(Rewards) do
				if type(Name) == "string" and not QuestMobs[Name] then
					Set[Name] = true
				end
			end
		end

		for Name in pairs(QuestBosses) do
			Set[Name] = true
		end

		local List = {}
		for Name in pairs(Set) do
			table.insert(List, Name)
		end
		table.sort(List)
		return List
	end)()

	local BossSet = {}
	for _, Name in ipairs(BossNames) do
		BossSet[Name] = true
	end

	local function StripCount(Name)
		return (string.gsub(Name, "%d+$", ""))
	end

	local function ZoneNameOf(Mob)
		local Node = Mob

		while Node and Node.Parent and Node.Parent ~= NPCZones do
			Node = Node.Parent
		end

		return Node and Node.Name or "?"
	end

	local BossWords = {
		"boss",
		"beast",
		"leviathan",
		"kraken",
		"cthulhu",
		"emperor",
		"lord",
		"king",
		"queen",
		"titan",
		"warden",
		"raid",
	}

	local function LooksLikeBoss(Mob, Name)
		if QuestMobs[Name] then
			return false
		end

		if Mob:GetAttribute("Boss") or Mob:GetAttribute("IsBoss") or Mob:FindFirstChild("BossHealthBar") then
			return true
		end

		local Lower = string.lower(Name)
		for _, Word in ipairs(BossWords) do
			if string.find(Lower, Word, 1, true) then
				return true
			end
		end

		local Folder = string.lower(tostring(Mob.Parent and Mob.Parent.Name))
		return string.find(Folder, "boss", 1, true) ~= nil or string.find(Folder, "raid", 1, true) ~= nil
	end

	local function ScanBosses()
		local Root = GetRoot()
		local Origin = Root and Root.Position
		local Found = {}

		for _, Entry in ipairs(IterNPCs()) do
			local Mob, MobRoot, Humanoid = Entry.Mob, Entry.Root, Entry.Humanoid
			local Name = StripCount(GetMobName(Mob))

			if BossSet[Name] or LooksLikeBoss(Mob, Name) then
				table.insert(Found, {
					Name = Name,
					Zone = ZoneNameOf(Mob),
					Mob = Mob,
					Root = MobRoot,
					Humanoid = Humanoid,
					Distance = Origin and (MobRoot.Position - Origin).Magnitude or 0,
				})
			end
		end

		table.sort(Found, function(A, B)
			return A.Distance < B.Distance
		end)

		return Found
	end

	ValkyrieScanBosses = ScanBosses

	local function RememberSpot(Name, Position)
		local Settings = getgenv().Settings.AutoFarmBoss
		if type(Settings.Spots) ~= "table" then
			Settings.Spots = {}
		end

		local Saved = Settings.Spots[Name]
		if type(Saved) == "table" and #Saved == 3 then
			if (Vector3.new(Saved[1], Saved[2], Saved[3]) - Position).Magnitude < 20 then
				return
			end
		end

		Settings.Spots[Name] = { Position.X, Position.Y, Position.Z }
		QueueSave()
	end

	local function SpotOf(Name)
		local Spots = getgenv().Settings.AutoFarmBoss.Spots
		local Saved = type(Spots) == "table" and Spots[Name] or nil
		if type(Saved) == "table" and #Saved == 3 then
			return Vector3.new(Saved[1], Saved[2], Saved[3])
		end

		return QuestBosses[Name]
	end

	local function SelectedBosses()
		local Value = getgenv().Settings.AutoFarmBoss.Bosses
		local List, Seen = {}, {}

		if type(Value) ~= "table" then
			return List
		end

		for Key, Item in pairs(Value) do
			local Name = nil
			if type(Item) == "string" then
				Name = Item
			elseif Item == true and type(Key) == "string" then
				Name = Key
			end

			if Name and not Seen[Name] then
				Seen[Name] = true
				table.insert(List, Name)
			end
		end

		table.sort(List)
		return List
	end

	local BossSelectDropdown = nil

	local BossFarmSection = VenuzSections.Boss

	BossSelectDropdown = BossFarmSection:Dropdown({
		Title = "tr:BossSelect",
		Path = "AutoFarmBoss.Bosses",
		Desc = "tr:BossSelectDesc",
		Multi = true,
		AllowNone = true,
		Values = BossNames,
		Value = getgenv().Settings.AutoFarmBoss.Bosses,
		Callback = function(Value)
			getgenv().Settings.AutoFarmBoss.Bosses = NormalizeList(Value)
			SaveSetting()
		end,
	})

	BossFarmSection:Toggle({
		Title = "tr:BossDodge",
		Path = "AutoFarmBoss.Dodge",
		Desc = "tr:BossDodgeDesc",
		Value = getgenv().Settings.AutoFarmBoss.Dodge,
		Icon = "check",
		Callback = function(Value)
			getgenv().Settings.AutoFarmBoss.Dodge = Value
			SaveSetting()
		end,
	})

	local BossRunning = false
	local BossLoop = nil
	local BossLastAttack = 0
	local BossComboStart = 0
	local BossDodgeUntil = 0
	local BossAttackDelay = 0.15

	VenuzToggle.AutoBoss = function(Value)
		if Value and not RequireWeapon("Auto Farm Boss", VenuzToggle.BossToggle) then
			getgenv().Settings.AutoFarmBoss.Enabled = false
			SaveSetting()
			return
		end

		getgenv().Settings.AutoFarmBoss.Enabled = Value
		SaveSetting()

		if not Value then
			BossRunning = false
			BossComboStart = 0
			BossDodgeUntil = 0
			if BossLoop then
				pcall(function()
					task.cancel(BossLoop)
				end)
				BossLoop = nil
			end
			EndRunner("Boss")
			return
		end

		SetToggleValue(AutoFarmToggle, false)
		SetToggleValue(Sea3Toggle, false)
		SetToggleValue(VenuzToggle.MobToggle, false)
		StopDrivingBosses()

		if BossRunning then
			return
		end

		BossRunning = true
		VenuzRun.BossEpoch = VenuzRun.Epoch
		BeginRunner("Boss")

		BossLoop = task.spawn(function()
			while BossRunning do
				task.wait()

				if not IsCurrentInstance() then
					BossRunning = false
					EndRunner("Boss")
					break
				end

				local Success = pcall(function()
					if not IsAlive() then
						LockCFrame = nil

						HoldCFrame = nil
						CancelTween()
						task.wait(1)
						return
					end

					local Wanted = SelectedBosses()
					if #Wanted == 0 then
						LockCFrame = nil
						task.wait(1)
						return
					end

					local WantedSet = {}
					for _, Name in ipairs(Wanted) do
						WantedSet[Name] = true
					end

					local Target = nil
					for _, Data in ipairs(ScanBosses()) do
						if WantedSet[Data.Name] then
							RememberSpot(Data.Name, Data.Root.Position)
							if not Target then
								Target = Data
							end
						end
					end

					local Root = GetRoot()
					if not Root then
						return
					end

					if not ClaimDrive("Boss", Target and 2 or 1) then
						task.wait(0.3)
						return
					end

					if VenuzRun.BossEpoch ~= VenuzRun.Epoch then
						VenuzRun.BossEpoch = VenuzRun.Epoch
						BossComboStart = 0
						BossDodgeUntil = 0
						LockCFrame = nil
						HoldCFrame = nil
						CancelTween()
					end

					if not Target then
						BossComboStart = 0
						BossDodgeUntil = 0

						local Spot = nil
						for _, Name in ipairs(Wanted) do
							Spot = SpotOf(Name)
							if Spot then
								break
							end
						end

						if Spot then
							if BossWaitAt("Boss", Spot) == "Farming" then
								return
							end
						else
							IdleRunner("Boss")
						end

						task.wait(0.5)
						return
					end

					local MobRoot = Target.Root
					local Tool = EquipWeapon(FarmWeaponName())
					local Stand = GetAttackCFrame(MobRoot.CFrame)

					if (Root.Position - Stand.Position).Magnitude > 30 then
						StartRender()
						LockCFrame = nil
						TravelTo(Stand, 30)
						return
					end

					StartRender()
					CancelTween()
					LockCFrame = Stand

					if tick() - BossLastAttack >= BossAttackDelay then
						BossLastAttack = tick()
						task.spawn(AttackWith, Tool, MobRoot)
					end
				end)

				if not Success then
					task.wait(0.25)
				end
			end
		end)
	end

	local AutoBossToggle = BossFarmSection:Toggle({
		Title = "tr:AutoFarmBoss",
		Path = "AutoFarmBoss.Enabled",
		Desc = "tr:AutoFarmBossDesc",

		Value = getgenv().Settings.AutoFarmBoss.Enabled,
		Icon = "check",
		Callback = VenuzToggle.AutoBoss,
	})

	VenuzToggle.BossToggle = AutoBossToggle

	task.spawn(function()
		while task.wait(3) do
			if not IsCurrentInstance() then
				break
			end

			pcall(function()
				local Added = false

				for _, Data in ipairs(ScanBosses()) do
					RememberSpot(Data.Name, Data.Root.Position)

					if not BossSet[Data.Name] then
						BossSet[Data.Name] = true
						table.insert(BossNames, Data.Name)
						Added = true
					end
				end

				if Added then
					table.sort(BossNames)
					pcall(function()
						BossSelectDropdown:Refresh(BossNames)
					end)
				end
			end)
		end
	end)

	if getgenv().Settings.AutoFarmBoss.Enabled then
		task.defer(VenuzToggle.AutoBoss, true)
	end
end)()
;
(function()
	local MobSpots = {}

	local MobNames = (function()
		local Sea = ({ [6918802270] = 1, [14979402479] = 2, [99664616626491] = 3 })[game.PlaceId] or 1
		local List, Seen = {}, {}

		for _, Entry in ipairs(getgenv().LevelConfig or {}) do
			if Entry.MonName and SeaOfEntry(Entry) == Sea and not IsBoss(Entry) then
				if not Seen[Entry.MonName] then
					Seen[Entry.MonName] = true
					MobSpots[Entry.MonName] = Entry.MonPOS
					table.insert(List, Entry.MonName)
				end
			end
		end

		table.sort(List)
		return List
	end)()

	local function SelectedMobs()
		local List = NormalizeList(getgenv().Settings.AutoFarmMob.Mobs)
		local Wanted = {}

		for _, Name in ipairs(List) do
			if MobSpots[Name] then
				table.insert(Wanted, Name)
			end
		end

		return Wanted
	end

	local MobFarmSection = VenuzSections.Mob

	MobFarmSection:Dropdown({
		Title = "tr:MobSelect",
		Path = "AutoFarmMob.Mobs",
		Desc = "tr:MobSelectDesc",
		Multi = true,
		AllowNone = true,
		Values = MobNames,
		Value = getgenv().Settings.AutoFarmMob.Mobs,
		Callback = function(Value)
			getgenv().Settings.AutoFarmMob.Mobs = NormalizeList(Value)
			SaveSetting()
		end,
	})

	MobFarmSection:Toggle({
		Title = "tr:MobAutoQuest",
		Path = "AutoFarmMob.AutoQuest",
		Desc = "tr:MobAutoQuestDesc",
		Value = getgenv().Settings.AutoFarmMob.AutoQuest,
		Icon = "check",
		Callback = function(Value)
			getgenv().Settings.AutoFarmMob.AutoQuest = Value
			SaveSetting()
		end,
	})

	local MobQuest = {
		Name = nil,
		CancelTried = false,
		AcceptFails = 0,
		AcceptBlockedAt = 0,
	}

	local function ResetMobQuest()
		MobQuest.Name = nil
		MobQuest.CancelTried = false
		MobQuest.AcceptFails = 0
		MobQuest.AcceptBlockedAt = 0
	end

	local function HandleMobQuest(MonName)
		if not getgenv().Settings.AutoFarmMob.AutoQuest or not MonName then
			return false
		end

		local Entry = FindEntryByMob(MonName)
		if not Entry then
			return false
		end

		if MobQuest.Name ~= MonName then
			MobQuest.Name = MonName
			MobQuest.CancelTried = false
			MobQuest.AcceptFails = 0
			MobQuest.AcceptBlockedAt = 0
		end

		if not GetActiveQuest() then
			MobQuest.CancelTried = false

			if MobQuest.AcceptBlockedAt > 0 and tick() - MobQuest.AcceptBlockedAt >= VenuzFarm.AcceptRetryTime then
				MobQuest.AcceptFails = 0
				MobQuest.AcceptBlockedAt = 0
			end

			if MobQuest.AcceptFails >= VenuzFarm.MaxAcceptTries then
				return false
			end

			if AcceptQuest(Entry) then
				MobQuest.AcceptFails = 0
				MobQuest.AcceptBlockedAt = 0
			else
				MobQuest.AcceptFails = MobQuest.AcceptFails + 1
				if MobQuest.AcceptFails >= VenuzFarm.MaxAcceptTries then
					MobQuest.AcceptBlockedAt = tick()
				end
				task.wait(0.2)
			end

			return true
		end

		if not QuestMatches(Entry) and not MobQuest.CancelTried then
			MobQuest.CancelTried = true
			if CancelQuest() then
				return true
			end
		end

		return false
	end

	local MobRunning = false
	local MobLoop = nil
	local MobLastAttack = 0
	local MobAttackDelay = 0.15

	VenuzToggle.AutoMob = function(Value)
		if Value and not RequireWeapon("Auto Farm Mob", VenuzToggle.MobToggle) then
			getgenv().Settings.AutoFarmMob.Enabled = false
			SaveSetting()
			return
		end

		getgenv().Settings.AutoFarmMob.Enabled = Value
		SaveSetting()

		if not Value then
			MobRunning = false
			ResetTags()
			ResetMobQuest()
			if MobLoop then
				pcall(function()
					task.cancel(MobLoop)
				end)
				MobLoop = nil
			end
			EndRunner("Mob")
			return
		end

		SetToggleValue(AutoFarmToggle, false)
		SetToggleValue(Sea3Toggle, false)
		SetToggleValue(VenuzToggle.BossToggle, false)
		StopDrivingBosses()

		if MobRunning then
			return
		end

		MobRunning = true
		ResetTags()
		ResetMobQuest()
		VenuzRun.MobEpoch = VenuzRun.Epoch
		BeginRunner("Mob")

		MobLoop = task.spawn(function()
			while MobRunning do
				task.wait()

				if not IsCurrentInstance() then
					MobRunning = false
					EndRunner("Mob")
					break
				end

				local Success = pcall(function()
					if not IsAlive() then
						LockCFrame = nil

						HoldCFrame = nil
						CancelTween()
						task.wait(1)
						return
					end

					if not ClaimDrive("Mob", 1) then
						task.wait(0.3)
						return
					end

					StartRender()

					if VenuzRun.MobEpoch ~= VenuzRun.Epoch then
						VenuzRun.MobEpoch = VenuzRun.Epoch
						LockCFrame = nil
						HoldCFrame = nil
						CancelTween()
						ResetTags()
					end

					local Wanted = SelectedMobs()
					if #Wanted == 0 then
						LockCFrame = nil
						task.wait(1)
						return
					end

					local Root = GetRoot()
					if not Root then
						return
					end

					local Alive = {}
					for _, Name in ipairs(Wanted) do
						for _, Data in ipairs(FindMobs(Name, Root.Position, nil)) do
							Data.Name = Name
							table.insert(Alive, Data)
						end
					end

					table.sort(Alive, function(A, B)
						return A.Distance < B.Distance
					end)

					local Target = Alive[1]

					if HandleMobQuest(Target and Target.Name or Wanted[1]) then
						return
					end

					if not Target then
						local Spot = MobSpots[Wanted[1]]
						if not Spot then
							LockCFrame = nil
							task.wait(0.5)
							return
						end

						local WaitCFrame = CFrame.new(Spot + Vector3.new(0, 20, 0))

						if (Root.Position - WaitCFrame.Position).Magnitude > 25 then
							LockCFrame = nil
							TravelTo(WaitCFrame, 25)
						else
							LockCFrame = WaitCFrame
						end

						task.wait(0.3)
						return
					end

					local MobRoot = Target.Root
					local Anchor = nil

					local Nearby = {}
					for _, Data in ipairs(Alive) do
						if (Data.Root.Position - MobRoot.Position).Magnitude <= VenuzFarm.AggroRadius then
							table.insert(Nearby, Data)
						end
					end

					for Tagged in pairs(TaggedMobs) do
						if not Tagged.Parent then
							TaggedMobs[Tagged] = nil
						end
					end

					local Lead, Count, Center = PickCluster(Nearby, VenuzFarm.PackRadius)

					if Lead and Count > 1 and Center then
						MobRoot = Lead.Root
						Anchor = CFrame.new(Center)
						CurrentTag = nil
					else
						local Picked, Tagging = PickTarget(Nearby)
						if Picked then
							MobRoot = Picked.Root
						end

						if Tagging and Picked then
							if CurrentTag ~= Picked.Mob then
								CurrentTag = Picked.Mob
								TagDeadline = tick() + TagHoldTime
							elseif tick() >= TagDeadline then
								TaggedMobs[Picked.Mob] = true
								CurrentTag = nil
							end
						else
							CurrentTag = nil
						end
					end

					local Tool = EquipWeapon(FarmWeaponName())
					local Stand = GetAttackCFrame(Anchor or MobRoot.CFrame)

					if (Root.Position - Stand.Position).Magnitude > 30 then
						LockCFrame = nil
						TravelTo(Stand, 30)
						return
					end

					CancelTween()
					LockCFrame = Stand

					if tick() - MobLastAttack >= MobAttackDelay then
						MobLastAttack = tick()
						task.spawn(AttackWith, Tool, MobRoot)
					end
				end)

				if not Success then
					task.wait(0.25)
				end
			end
		end)
	end

	local AutoMobToggle = MobFarmSection:Toggle({
		Title = "tr:AutoFarmMob",
		Path = "AutoFarmMob.Enabled",
		Desc = "tr:AutoFarmMobDesc",

		Value = getgenv().Settings.AutoFarmMob.Enabled,
		Icon = "check",
		Callback = VenuzToggle.AutoMob,
	})

	VenuzToggle.MobToggle = AutoMobToggle

	if getgenv().Settings.AutoFarmMob.Enabled then
		task.defer(VenuzToggle.AutoMob, true)
	end
end)()

BossSetupSection = BossTab:Section({ Title = "tr:BossSetupSection", Icon = "scroll-text", Opened = true })

BossSetupSection:Toggle({
	Title = "tr:BossAutoQuest",
	Path = "AutoBossQuest",
	Desc = "tr:BossAutoQuestDesc",
	Value = getgenv().Settings.AutoBossQuest,
	Icon = "check",
	Callback = function(Value)
		getgenv().Settings.AutoBossQuest = Value
		SaveSetting()

		if not Value then
			ResetBossQuest()
		end
	end,
})

BossSea2Section = BossTab
BossSea3Section = BossTab
;
(function()
	local Sea3Place = 99664616626491
	local TotemSpot = Vector3.new(-5783, 565, 433)
	local BossName = "Dragon Hybrid Boss"

	local HydraMobs = {
		{ Name = "Celestial Guard", Spot = Vector3.new(-5177, 513, -1164) },
		{ Name = "Celestial Captain", Spot = Vector3.new(-5790, 515, -1161) },
		{ Name = "Barren Rebel", Spot = Vector3.new(-5027, 503, -95) },
		{ Name = "Enslaved Pirate", Spot = Vector3.new(-5904, 501, -102) },
		{ Name = "God's Knight", Spot = Vector3.new(-3220, 914, 2433) },
	}

	local function GetTotem()
		return workspace:FindFirstChild("TrumpetTotem")
	end

	local function ClaimPrompt()
		local Totem = GetTotem()
		local Root = Totem and Totem:FindFirstChild("Root")
		return Root and Root:FindFirstChildOfClass("ProximityPrompt")
	end

	local function KillsLeft()
		local Totem = GetTotem()
		local Count = Totem and Totem:FindFirstChild("Count")
		return Count and Count.Value or -1
	end

	local function TrumpetTool()
		for _, Container in ipairs({ GetCharacter(), LocalPlayer:FindFirstChildOfClass("Backpack") }) do
			if Container then
				for _, Tool in ipairs(Container:GetChildren()) do
					if Tool:IsA("Tool") and string.find(string.lower(Tool.Name), "trumpet") then
						return Tool
					end
				end
			end
		end
		return nil
	end

	local function FindHydra()
		local Root = GetRoot()
		return FindMobs(BossName, Root and Root.Position, nil)[1]
	end

	local HydraSection = BossSea3Section:Section({ Title = "tr:HydraSection", Icon = "flame", Opened = true })

	local HydraStatus = "-"
	local HydraParagraph = RT.Status(HydraSection, "tr:HydraStatus")

	local HydraRunning = false
	local HydraLoop = nil
	local HydraLastAttack = 0
	local HydraComboStart = 0
	local HydraDodgeUntil = 0
	local HydraAttackDelay = 0.15
	local HydraLastBlow = 0
	local HydraLastClaim = 0
	local HydraHornTries = 0
	local HydraHornAt = 0
	local HydraSummonToggle, HydraKillToggle

	local function WantSummon()
		return getgenv().Settings.AutoDragonHydra.Summon == true
	end

	local function WantKill()
		return getgenv().Settings.AutoDragonHydra.Kill == true
	end

	local function FindHesitation()
		local Gui = LocalPlayer:FindFirstChild("PlayerGui")
		if not Gui then
			return nil
		end

		for _, Screen in ipairs(Gui:GetChildren()) do
			if Screen:IsA("ScreenGui") and Screen.Enabled then
				local Main = Screen:FindFirstChild("MainFrame")
				local Frame = Main and Main:FindFirstChild("Frame")
				local Hesitation = Frame and Frame:FindFirstChild("Hesitation")

				if Hesitation and Hesitation.Visible then
					return Hesitation
				end
			end
		end

		return nil
	end

	local function AcceptHornPrompt()
		local Hesitation = FindHesitation()

		if not Hesitation then
			HydraHornTries = 0
			return false
		end

		local Accept = Hesitation:FindFirstChild("Accept")
		local Button = Accept and Accept:FindFirstChild("Button")

		if not (Button and Button:IsA("GuiButton")) then
			HydraHornTries = 0
			return false
		end

		if HydraHornTries >= 8 then
			return false
		end

		if tick() - HydraHornAt < 0.5 then
			return true
		end

		HydraHornAt = tick()
		HydraHornTries = HydraHornTries + 1

		if not FireButton(Button) then
			pcall(function()
				local GuiService = game:GetService("GuiService")
				local VIM = game:GetService("VirtualInputManager")

				Button.Selectable = true
				GuiService.SelectedObject = Button
				VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, nil)
				task.wait(0.1)
				VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, nil)
				GuiService.SelectedObject = nil
			end)
		end

		return true
	end

	local function StopHydra()
		HydraRunning = false
		HydraComboStart = 0
		HydraDodgeUntil = 0
		HydraStatus = "Idle"
		ResetTags()

		if HydraLoop then
			pcall(function()
				task.cancel(HydraLoop)
			end)
			HydraLoop = nil
		end

		EndRunner("Hydra")
	end

	local function SyncHydra()
		if not (WantSummon() or WantKill()) then
			StopHydra()
			return
		end

		if game.PlaceId ~= Sea3Place then
			StopHydra()
			return
		end

		if not HasBossWeaponPicked() then
			getgenv().Settings.AutoDragonHydra.Summon = false
			getgenv().Settings.AutoDragonHydra.Kill = false
			SaveSetting()
			StopHydra()
			RequireBossWeapon("Dragon Hybrid Boss", HydraSummonToggle, HydraKillToggle)
			return
		end

		if WantSummon() then
			SetToggleValue(AutoFarmToggle, false)
			SetToggleValue(Sea3Toggle, false)
			SetToggleValue(VenuzToggle.BossToggle, false)
			SetToggleValue(VenuzToggle.MobToggle, false)
		end

		if HydraRunning then
			return
		end

		HydraRunning = true
		ResetTags()
		BeginRunner("Hydra")

		HydraLoop = task.spawn(function()
			while HydraRunning do
				task.wait()

				if not IsCurrentInstance() then
					HydraRunning = false
					EndRunner("Hydra")
					break
				end

				local Success = pcall(function()
					if not IsAlive() then
						LockCFrame = nil
						HoldCFrame = nil
						CancelTween()
						task.wait(1)
						return
					end

					local Root = GetRoot()
					if not Root then
						return
					end

					local Summoning = WantSummon()
					local Boss = FindHydra()

					if not Boss and not Summoning then
						HydraStatus = "Waiting for the boss"
						HydraComboStart = 0
						HydraDodgeUntil = 0
						IdleRunner("Hydra")
						task.wait(0.5)
						return
					end

					if Boss and not WantKill() then
						HydraStatus = "Boss is up, Auto Kill is off"
						IdleRunner("Hydra")
						task.wait(0.5)
						return
					end

					if not ClaimDrive("Hydra", Boss and 2 or 1) then
						HydraStatus = "Another farm is moving, waiting"
						task.wait(0.3)
						return
					end

					local Tool = EquipWeapon(BossWeaponName())

					if Summoning and AcceptHornPrompt() then
						HydraStatus = "Confirming the horn"
						task.wait(0.3)
						return
					end

					if Boss then
						local MobRoot = Boss.Root
						local Stand = GetAttackCFrame(MobRoot.CFrame)

						if (Root.Position - Stand.Position).Magnitude > 30 then
							HydraStatus = "Flying to " .. BossName
							StartRender()
							LockCFrame = nil
							TravelTo(Stand, 30)
							return
						end

						HydraStatus = "Fighting " .. BossName
						StartRender()
						CancelTween()
						LockCFrame = Stand

						if tick() - HydraLastAttack >= HydraAttackDelay then
							HydraLastAttack = tick()
							task.spawn(AttackWith, Tool, MobRoot)
						end

						return
					end

					HydraComboStart = 0
					HydraDodgeUntil = 0

					StartRender()

					local Horn = TrumpetTool()
					if Horn then
						HydraStatus = "Blowing " .. Horn.Name

						local Humanoid = GetHumanoid()
						if Horn.Parent ~= GetCharacter() and Humanoid then
							pcall(function()
								Humanoid:EquipTool(Horn)
							end)
							task.wait(0.3)
						end

						if tick() - HydraLastBlow >= 1 then
							HydraLastBlow = tick()
							task.spawn(function()
								pcall(function()
									Horn:Activate()
								end)
							end)
						end

						task.wait(0.5)
						return
					end

					local Prompt = ClaimPrompt()
					local Left = KillsLeft()

					if Prompt and Prompt.Enabled then
						HydraStatus = "Claiming Trumpet"

						local Stand = CFrame.new(TotemSpot + Vector3.new(0, 6, 0))
						if (Root.Position - Stand.Position).Magnitude > 10 then
							LockCFrame = nil
							TravelTo(Stand, 10)
							return
						end

						CancelTween()
						LockCFrame = Stand

						if tick() - HydraLastClaim >= 1 then
							HydraLastClaim = tick()
							task.spawn(function()
								if not FirePrompt(Prompt) then
									HydraStatus = "Executor cannot fire the totem prompt"
								end
							end)
						end

						task.wait(0.5)
						return
					end

					HydraStatus = Left >= 0 and ("Farming Land of Gods (" .. Left .. " kills left)")
						or "Flying to Land of Gods"

					local Alive = {}
					for _, Entry in ipairs(HydraMobs) do
						for _, Data in ipairs(FindMobs(Entry.Name, Root.Position, nil)) do
							Data.Name = Entry.Name
							table.insert(Alive, Data)
						end
					end

					table.sort(Alive, function(A, B)
						return A.Distance < B.Distance
					end)

					local Target = Alive[1]

					if not Target then
						local Spot = HydraMobs[1].Spot
						local WaitCFrame = CFrame.new(Spot + Vector3.new(0, 20, 0))

						if (Root.Position - WaitCFrame.Position).Magnitude > 25 then
							LockCFrame = nil
							TravelTo(WaitCFrame, 25)
						else
							LockCFrame = WaitCFrame
						end

						task.wait(0.3)
						return
					end

					if KeepBossQuest(Target.Name) then
						return
					end

					local MobRoot = Target.Root
					local Anchor = nil

					local Nearby = {}
					for _, Data in ipairs(Alive) do
						if (Data.Root.Position - MobRoot.Position).Magnitude <= VenuzFarm.AggroRadius then
							table.insert(Nearby, Data)
						end
					end

					for Tagged in pairs(TaggedMobs) do
						if not Tagged.Parent then
							TaggedMobs[Tagged] = nil
						end
					end

					local Lead, Count, Center = PickCluster(Nearby, VenuzFarm.PackRadius)

					if Lead and Count > 1 and Center then
						MobRoot = Lead.Root
						Anchor = CFrame.new(Center)
						CurrentTag = nil
					else
						local Picked, Tagging = PickTarget(Nearby)
						if Picked then
							MobRoot = Picked.Root
						end

						if Tagging and Picked then
							if CurrentTag ~= Picked.Mob then
								CurrentTag = Picked.Mob
								TagDeadline = tick() + TagHoldTime
							elseif tick() >= TagDeadline then
								TaggedMobs[Picked.Mob] = true
								CurrentTag = nil
							end
						else
							CurrentTag = nil
						end
					end

					local Stand = GetAttackCFrame(Anchor or MobRoot.CFrame)

					if (Root.Position - Stand.Position).Magnitude > 30 then
						LockCFrame = nil
						TravelTo(Stand, 30)
						return
					end

					CancelTween()
					LockCFrame = Stand

					if tick() - HydraLastAttack >= HydraAttackDelay then
						HydraLastAttack = tick()
						task.spawn(AttackWith, Tool, MobRoot)
					end
				end)

				if not Success then
					task.wait(0.25)
				end
			end
		end)
	end

	VenuzToggle.AutoSummon = function(Value)
		getgenv().Settings.AutoDragonHydra.Summon = Value
		SaveSetting()
		SyncHydra()
	end

	VenuzToggle.AutoKill = function(Value)
		getgenv().Settings.AutoDragonHydra.Kill = Value
		SaveSetting()
		SyncHydra()
	end

	HydraSummonToggle = HydraSection:Toggle({
		Title = "tr:AutoSummon",
		Path = "AutoDragonHydra.Summon",
		Desc = "tr:AutoSummonDesc",

		Value = getgenv().Settings.AutoDragonHydra.Summon,
		Icon = "check",
		Callback = VenuzToggle.AutoSummon,
	})

	HydraKillToggle = HydraSection:Toggle({
		Title = "tr:AutoKill",
		Path = "AutoDragonHydra.Kill",
		Desc = "tr:AutoKillDesc",
		Value = getgenv().Settings.AutoDragonHydra.Kill,
		Icon = "check",
		Callback = VenuzToggle.AutoKill,
	})

	RegisterHopTarget({
		Key = "Hydra",
		Label = "Dragon Hybrid Boss",
		Find = FindHydra,
		Enabled = function()
			return WantSummon() or WantKill()
		end,
	})

	VenuzToggle.NeedsHydra = function()
		return WantSummon()
	end

	VenuzToggle.StopHydra = function()
		getgenv().Settings.AutoDragonHydra.Summon = false
		getgenv().Settings.AutoDragonHydra.Kill = false
		SaveSetting()
		StopHydra()
		SetToggleValue(HydraSummonToggle, false)
		SetToggleValue(HydraKillToggle, false)
	end

	task.spawn(function()
		while task.wait(1) do
			if not IsCurrentInstance() then
				break
			end
			RT.Push("Hydra status", HydraParagraph, function()
				local Left = KillsLeft()
				local Prompt = ClaimPrompt()
				local Boss = FindHydra()
				local Lines = {
					RT.Head("Hydra", RT.Red),
					RT.State(HydraStatus, HydraRunning),
					RT.Paint("Kills required: ", RT.Muted) .. (Left >= 0 and RT.Bold(
						Left,
						Left == 0 and RT.Green or RT.Amber
					) or RT.Bold("totem not loaded", RT.Red)),
					RT.Flag("Totem ready", Prompt and Prompt.Enabled) .. RT.Sep .. RT.Flag("Trumpet", TrumpetTool()),
				}

				RT.Add(Lines, RT.Target("Boss", Boss))

				return table.concat(Lines, "\n")
			end)
		end
	end)

	if getgenv().Settings.AutoDragonHydra.Summon or getgenv().Settings.AutoDragonHydra.Kill then
		task.defer(SyncHydra)
	end
end)()
;
(function()
	local Sea3Place = 99664616626491
	local BossName = "Raijin"

	local PillarSpots = {
		Vector3.new(-5732, 1937, 7250),
		Vector3.new(-5809, 1937, 7537),
		Vector3.new(-5629, 1937, 7438),
		Vector3.new(-5908, 1937, 7357),
	}

	local RaijinMobs = {
		{ Name = "Thunder Disciple", Spot = Vector3.new(-4734, 991, 7415) },
	}

	local function QuestFolder()
		return workspace:FindFirstChild("RaijinSpawnQuest")
	end

	local function PillarModel(Index)
		local Root = QuestFolder()
		local Pillars = Root and Root:FindFirstChild("Pillars")
		return Pillars and Pillars:FindFirstChild("Pillar" .. Index)
	end

	local function PillarPrompt(Index)
		local Model = PillarModel(Index)
		local Part = Model and Model:FindFirstChild("Part")
		return Part and Part:FindFirstChildOfClass("ProximityPrompt")
	end

	local function PillarSpot(Index)
		local Model = PillarModel(Index)
		local Part = Model and Model:FindFirstChild("Part")
		return Part and Part.Position or PillarSpots[Index]
	end

	local function ChargedCount()
		local Root = QuestFolder()
		local Count = Root and Root:GetAttribute("PillarsCharged")

		if type(Count) == "number" then
			return Count
		end

		for Index = 1, 4 do
			local Model = PillarModel(Index)
			local Sphere = Model and Model:FindFirstChild("Sphere")
			local Gui = Sphere and Sphere:FindFirstChild("ChargeStatus")
			local Label = Gui and Gui:FindFirstChild("Text")

			if Label then
				local Done = string.match(Label.Text, "(%d+)%s*/%s*4")
				if Done then
					return tonumber(Done)
				end
			end
		end

		return -1
	end

	-- The server stamps OnCooldownUntil with the server clock the next summon unlocks at,
	-- so charging pillars before that only burns Divine Spark for nothing.
	local function RaijinCooldown()
		local Root = QuestFolder()
		if not Root then
			return nil
		end

		local Until = Root:GetAttribute("OnCooldownUntil")
		if type(Until) ~= "number" or Until <= 0 then
			return 0
		end

		return math.max(0, Until - workspace:GetServerTimeNow())
	end

	local function ScanSpark()
		local Total, First = 0, nil

		for _, Container in ipairs({ GetCharacter(), LocalPlayer:FindFirstChildOfClass("Backpack") }) do
			if Container then
				for _, Item in ipairs(Container:GetChildren()) do
					local Name = string.lower(Item.Name)
					if Item:IsA("Tool") and (string.find(Name, "divine") or string.find(Name, "spark")) then
						Total = Total + 1
						First = First or Item
					end
				end
			end
		end

		if Total > 0 then
			return Total, First
		end

		local Data = LocalPlayer:FindFirstChild("PlayerData")
		if Data then
			for _, Value in ipairs(Data:GetDescendants()) do
				if Value:IsA("IntValue") or Value:IsA("NumberValue") then
					local Name = string.lower(Value.Name)
					if string.find(Name, "divinespark") or string.find(Name, "divine spark") then
						return Value.Value, nil
					end
				end
			end
		end

		return 0, nil
	end

	local SparkAt, SparkNum, SparkItem = 0, 0, nil

	local function SparkCount()
		if tick() - SparkAt < 0.5 then
			return SparkNum, SparkItem
		end

		SparkAt = tick()
		SparkNum, SparkItem = ScanSpark()
		return SparkNum, SparkItem
	end

	local function FindRaijin()
		local Root = GetRoot()
		return FindMobs(BossName, Root and Root.Position, nil)[1]
	end

	local RaijinSection = BossSea3Section:Section({ Title = "tr:RaijinSection", Icon = "zap", Opened = true })

	local RaijinStatus = "-"
	local RaijinParagraph = RT.Status(RaijinSection, "tr:RaijinStatus")

	local RaijinRunning = false
	local RaijinLoop = nil
	local RaijinLastAttack = 0
	local RaijinComboStart = 0
	local RaijinDodgeUntil = 0
	local RaijinAttackDelay = 0.15
	local RaijinLastFire = 0
	local RaijinPillar = 1
	local RaijinSummonToggle, RaijinKillToggle

	local function WantRaijinSummon()
		return getgenv().Settings.AutoRaijin.Summon == true
	end

	local function WantRaijinKill()
		return getgenv().Settings.AutoRaijin.Kill == true
	end

	local function StopRaijin()
		RaijinRunning = false
		RaijinComboStart = 0
		RaijinDodgeUntil = 0
		RaijinStatus = "Idle"
		ResetTags()

		if RaijinLoop then
			pcall(function()
				task.cancel(RaijinLoop)
			end)
			RaijinLoop = nil
		end

		EndRunner("Raijin")
	end

	local function SyncRaijin()
		if not (WantRaijinSummon() or WantRaijinKill()) then
			StopRaijin()
			return
		end

		if game.PlaceId ~= Sea3Place then
			StopRaijin()
			return
		end

		if not HasBossWeaponPicked() then
			getgenv().Settings.AutoRaijin.Summon = false
			getgenv().Settings.AutoRaijin.Kill = false
			SaveSetting()
			StopRaijin()
			RequireBossWeapon("Raijin", RaijinSummonToggle, RaijinKillToggle)
			return
		end

		if WantRaijinSummon() then
			SetToggleValue(AutoFarmToggle, false)
			SetToggleValue(Sea3Toggle, false)
			SetToggleValue(VenuzToggle.BossToggle, false)
			SetToggleValue(VenuzToggle.MobToggle, false)
		end

		if RaijinRunning then
			return
		end

		RaijinRunning = true
		ResetTags()
		BeginRunner("Raijin")

		RaijinLoop = task.spawn(function()
			while RaijinRunning do
				task.wait()

				if not IsCurrentInstance() then
					RaijinRunning = false
					EndRunner("Raijin")
					break
				end

				local Success = pcall(function()
					if not IsAlive() then
						LockCFrame = nil
						HoldCFrame = nil
						CancelTween()
						task.wait(1)
						return
					end

					local Root = GetRoot()
					if not Root then
						return
					end

					local Summoning = WantRaijinSummon()
					local Boss = FindRaijin()

					if not Boss and not Summoning then
						RaijinStatus = "Waiting for Raijin"
						RaijinComboStart = 0
						RaijinDodgeUntil = 0
						IdleRunner("Raijin")
						task.wait(0.5)
						return
					end

					if Boss and not WantRaijinKill() then
						RaijinStatus = "Raijin is up, Auto Kill is off"
						IdleRunner("Raijin")
						task.wait(0.5)
						return
					end

					if not ClaimDrive("Raijin", Boss and 2 or 1) then
						RaijinStatus = "Another farm is moving, waiting"
						task.wait(0.3)
						return
					end

					if Boss then
						local Tool = EquipWeapon(BossWeaponName())
						local MobRoot = Boss.Root
						local Stand = GetAttackCFrame(MobRoot.CFrame)

						if (Root.Position - Stand.Position).Magnitude > 30 then
							RaijinStatus = "Flying to " .. BossName
							StartRender()
							LockCFrame = nil
							TravelTo(Stand, 30)
							return
						end

						RaijinStatus = "Fighting " .. BossName
						StartRender()
						CancelTween()
						LockCFrame = Stand

						if tick() - RaijinLastAttack >= RaijinAttackDelay then
							RaijinLastAttack = tick()
							task.spawn(AttackWith, Tool, MobRoot)
						end

						return
					end

					RaijinComboStart = 0
					RaijinDodgeUntil = 0

					StartRender()

					local Sparks, Spark = SparkCount()
					local Charged = ChargedCount()
					local Cooldown = RaijinCooldown() or 0

					local Prompt, Index = nil, nil

					if Sparks > 0 and Cooldown <= 0 then
						for Step = 0, 3 do
							local Try = ((RaijinPillar - 1 + Step) % 4) + 1
							local Found = PillarPrompt(Try)

							if Found == nil or Found.Enabled then
								Prompt, Index = Found, Try
								break
							end
						end
					end

					if Index then
						RaijinPillar = Index
						RaijinStatus = "Charging Pillar "
							.. Index
							.. " ("
							.. (Charged >= 0 and Charged or "?")
							.. "/4, "
							.. Sparks
							.. " spark)"

						local Spot = PillarSpot(Index)
						local Stand = CFrame.new(Spot + Vector3.new(0, 6, 0))

						if (Root.Position - Stand.Position).Magnitude > 12 then
							LockCFrame = nil
							TravelTo(Stand, 12)
							return
						end

						CancelTween()
						LockCFrame = Stand

						if not Prompt then
							task.wait(0.3)
							return
						end

						local Humanoid = GetHumanoid()
						if Spark and Spark.Parent ~= GetCharacter() and Humanoid then
							pcall(function()
								Humanoid:EquipTool(Spark)
							end)
							task.wait(0.2)
						end

						if tick() - RaijinLastFire >= 1 then
							RaijinLastFire = tick()

							task.spawn(function()
								if not FirePrompt(Prompt) then
									RaijinStatus = "Executor cannot fire the pillar prompt"
								end
							end)

							SparkAt = 0

							RaijinPillar = (Index % 4) + 1
						end

						task.wait(0.5)
						return
					end

					if Cooldown > 0 then
						RaijinStatus = "Raijin on cooldown, farming for " .. RT.Clock(Cooldown)
					else
						RaijinStatus = Charged >= 4 and "Pillars are lit, farming until Raijin lands"
							or (
								Charged >= 0 and ("Farming for Divine Spark (" .. Charged .. "/4 pillars)")
								or "Farming for Divine Spark"
							)
					end

					local Alive = {}
					for _, Entry in ipairs(RaijinMobs) do
						for _, Data in ipairs(FindMobs(Entry.Name, Root.Position, nil)) do
							Data.Name = Entry.Name
							table.insert(Alive, Data)
						end
					end

					table.sort(Alive, function(A, B)
						return A.Distance < B.Distance
					end)

					local Target = Alive[1]

					if not Target then
						local Spot = RaijinMobs[1].Spot
						local WaitCFrame = CFrame.new(Spot + Vector3.new(0, 20, 0))

						if (Root.Position - WaitCFrame.Position).Magnitude > 25 then
							LockCFrame = nil
							TravelTo(WaitCFrame, 25)
						else
							LockCFrame = WaitCFrame
						end

						task.wait(0.3)
						return
					end

					if KeepBossQuest(Target.Name) then
						return
					end

					local MobRoot = Target.Root
					local Anchor = nil

					local Nearby = {}
					for _, Data in ipairs(Alive) do
						if (Data.Root.Position - MobRoot.Position).Magnitude <= VenuzFarm.AggroRadius then
							table.insert(Nearby, Data)
						end
					end

					for Tagged in pairs(TaggedMobs) do
						if not Tagged.Parent then
							TaggedMobs[Tagged] = nil
						end
					end

					local Lead, Count, Center = PickCluster(Nearby, VenuzFarm.PackRadius)

					if Lead and Count > 1 and Center then
						MobRoot = Lead.Root
						Anchor = CFrame.new(Center)
						CurrentTag = nil
					else
						local Picked, Tagging = PickTarget(Nearby)
						if Picked then
							MobRoot = Picked.Root
						end

						if Tagging and Picked then
							if CurrentTag ~= Picked.Mob then
								CurrentTag = Picked.Mob
								TagDeadline = tick() + TagHoldTime
							elseif tick() >= TagDeadline then
								TaggedMobs[Picked.Mob] = true
								CurrentTag = nil
							end
						else
							CurrentTag = nil
						end
					end

					local Stand = GetAttackCFrame(Anchor or MobRoot.CFrame)

					if (Root.Position - Stand.Position).Magnitude > 30 then
						LockCFrame = nil
						TravelTo(Stand, 30)
						return
					end

					CancelTween()
					LockCFrame = Stand

					if tick() - RaijinLastAttack >= RaijinAttackDelay then
						RaijinLastAttack = tick()
						task.spawn(AttackWith, EquipWeapon(BossWeaponName()), MobRoot)
					end
				end)

				if not Success then
					task.wait(0.25)
				end
			end
		end)
	end

	RaijinSummonToggle = RaijinSection:Toggle({
		Title = "tr:RaijinSummon",
		Path = "AutoRaijin.Summon",
		Desc = "tr:RaijinSummonDesc",
		Value = getgenv().Settings.AutoRaijin.Summon,
		Icon = "check",
		Callback = function(Value)
			getgenv().Settings.AutoRaijin.Summon = Value
			SaveSetting()
			SyncRaijin()
		end,
	})

	RaijinKillToggle = RaijinSection:Toggle({
		Title = "tr:RaijinKill",
		Path = "AutoRaijin.Kill",
		Desc = "tr:RaijinKillDesc",
		Value = getgenv().Settings.AutoRaijin.Kill,
		Icon = "check",
		Callback = function(Value)
			getgenv().Settings.AutoRaijin.Kill = Value
			SaveSetting()
			SyncRaijin()
		end,
	})

	RegisterHopTarget({
		Key = "Raijin",
		Label = "Raijin Boss",
		Find = FindRaijin,
		Enabled = function()
			return WantRaijinSummon() or WantRaijinKill()
		end,
	})

	VenuzToggle.NeedsRaijin = function()
		return WantRaijinSummon()
	end

	VenuzToggle.StopRaijin = function()
		getgenv().Settings.AutoRaijin.Summon = false
		getgenv().Settings.AutoRaijin.Kill = false
		SaveSetting()
		StopRaijin()
		SetToggleValue(RaijinSummonToggle, false)
		SetToggleValue(RaijinKillToggle, false)
	end

	task.spawn(function()
		while task.wait(1) do
			if not IsCurrentInstance() then
				break
			end
			RT.Push("Raijin status", RaijinParagraph, function()
				local Charged = ChargedCount()
				local Sparks = SparkCount()
				local Boss = FindRaijin()
				local Lines = {
					RT.Head("Raijin", RT.Red),
					RT.State(RaijinStatus, RaijinRunning),
					RT.Paint("Pillars charged: ", RT.Muted)
						.. (Charged >= 0 and RT.Bold(Charged .. "/4", Charged >= 4 and RT.Green or RT.Amber) or RT.Bold(
							"pillars not loaded",
							RT.Red
						))
						.. RT.Sep
						.. RT.Paint("Divine Spark: ", RT.Muted)
						.. RT.Bold(Sparks, Sparks > 0 and RT.Green or RT.Muted),
				}

				local Cooldown = RaijinCooldown()

				RT.Add(
					Lines,
					RT.Paint("Summon cooldown: ", RT.Muted)
						.. (Cooldown and RT.Bold(
							Cooldown > 0 and RT.Clock(Cooldown) or "ready",
							Cooldown > 0 and RT.Amber or RT.Green
						) or RT.Bold("quest not loaded", RT.Red))
				)

				RT.Add(Lines, RT.Target("Boss", Boss))

				return table.concat(Lines, "\n")
			end)
		end
	end)

	if getgenv().Settings.AutoRaijin.Summon or getgenv().Settings.AutoRaijin.Kill then
		task.defer(SyncRaijin)
	end
end)()
;
(function()
	local Sea2Place = 14979402479
	local BossName = "Dough Boss"
	local FragmentName = "Mirror Fragment"

	local FragmentNpcName = "NewWorld_Studios"

	local MirrorWorldSpot = Vector3.new(-59938, 78, 997)

	local SoulBossSpot = Vector3.new(-4396, 271, 16871)

	local DoughIslandSpot = Vector3.new(-3243, 98, 11115)

	local DoughMobs = {
		{ Name = "Dough Pirate", Spot = Vector3.new(-2603, 52, 10870) },
		{ Name = "Dough Captain", Spot = Vector3.new(-2657, 40, 11359) },
	}

	local function PlayerData()
		return LocalPlayer:FindFirstChild("PlayerData")
	end

	local function ValueIn(Name, Default)
		local Data = PlayerData()
		local Item = Data and Data:FindFirstChild(Name)
		return Item and Item.Value or Default
	end

	local function HasFragment()
		for _, Container in ipairs({ GetCharacter(), LocalPlayer:FindFirstChildOfClass("Backpack") }) do
			if Container then
				local Tool = Container:FindFirstChild(FragmentName)
				if Tool and Tool:IsA("Tool") then
					return true
				end
			end
		end

		local Stored = ValueIn("StoredItems", nil)
		if type(Stored) == "string" and Stored ~= "" then
			local Ok, Decoded = pcall(function()
				return HttpService:JSONDecode(Stored)
			end)

			if Ok and type(Decoded) == "table" and Decoded[FragmentName] then
				return true
			end
		end

		return false
	end

	local function GaveFragment()
		return LocalPlayer:GetAttribute("GaveMirror") and true or false
	end

	local function MirrorUnlocked()
		return (LocalPlayer:GetAttribute("UnlockedMirrorWorld") or ValueIn("UnlockedMirrorWorld", false)) and true
			or false
	end

	local function Doughnuts()
		return ValueIn("Doughnuts", 0) or 0
	end

	local function Gems()
		return ValueIn("Gems", 0) or 0
	end

	local function NpcIn(FolderName, PreferName)
		local Root = workspace:FindFirstChild("Npc_Workspace")
		local Folder = Root and Root:FindFirstChild(FolderName)

		if not Folder then
			return nil
		end

		if PreferName then
			local Named = Folder:FindFirstChild(PreferName)
			if Named and Named:FindFirstChild("Interact") then
				return Named
			end
		end

		for _, Model in ipairs(Folder:GetChildren()) do
			if Model:FindFirstChild("Interact") then
				return Model
			end
		end

		return nil
	end

	local function NpcSpot(Model)
		return ResolvePosition(Model)
	end

	local function MirrorPortal()
		local Logic = workspace:FindFirstChild("Logic")
		local POI = Logic and Logic:FindFirstChild("PointsOfInterest")
		local Mirror = POI and POI:FindFirstChild("Mirror")
		local Part = Mirror and Mirror:FindFirstChild("Part")
		local PP = Part and Part:FindFirstChild("PP")

		return PP and PP:FindFirstChildOfClass("ProximityPrompt") or nil, Part
	end

	local function MirrorExit()
		local Logic = workspace:FindFirstChild("Logic")
		local POI = Logic and Logic:FindFirstChild("PointsOfInterest")
		local Gate = POI and POI:FindFirstChild("TPMirror")

		if not Gate then
			return nil, nil
		end

		local Plane = Gate:FindFirstChild("Meshes/Mirror_Plane.001")
		local Prompt = Plane and Plane:FindFirstChildOfClass("ProximityPrompt")

		if Prompt then
			return Prompt, Plane
		end

		for _, Object in ipairs(Gate:GetDescendants()) do
			if Object:IsA("ProximityPrompt") then
				local Part = Object.Parent
				if Part and Part:IsA("BasePart") then
					return Object, Part
				end
			end
		end

		return nil, nil
	end

	local function InMirrorWorld()
		local Root = GetRoot()
		return Root ~= nil and Root.Position.X < -30000
	end

	local function FindDough()
		local Root = GetRoot()
		return FindMobs(BossName, Root and Root.Position, nil)[1]
	end

	local DoughSection = BossSea2Section:Section({ Title = "tr:DoughSection", Icon = "cookie", Opened = true })

	local DoughStatus = "-"
	local DoughParagraph = RT.Status(DoughSection, "tr:DoughStatus")

	local DoughRunning = false
	local DoughLoop = nil
	local DoughLastAttack = 0
	local DoughComboStart = 0
	local DoughDodgeUntil = 0
	local DoughAttackDelay = 0.15
	local DoughLastInvoke = 0
	local DoughLastPortal = 0

	local DoughPortalWait = 0

	local DoughPortalOut = false

	local DoughTalkWait = 0
	local DoughCooldownUntil = 0
	local DoughFragmentToggle, DoughUnlockToggle, DoughSpawnToggle, DoughKillToggle

	local function WantFragment()
		return getgenv().Settings.AutoDoughBoss.Fragment == true
	end

	local function WantUnlock()
		return getgenv().Settings.AutoDoughBoss.Unlock == true
	end

	local function WantSpawn()
		return getgenv().Settings.AutoDoughBoss.Spawn == true
	end

	local function WantKill()
		return getgenv().Settings.AutoDoughBoss.Kill == true
	end

	local function AnyDough()
		return WantFragment() or WantUnlock() or WantSpawn() or WantKill()
	end

	local function DoughWork()
		if tick() < DoughPortalWait or tick() < DoughTalkWait then
			return "Transit"
		end

		if WantSpawn() and MirrorUnlocked() and tick() >= DoughCooldownUntil then
			return "Spawn"
		end

		if WantUnlock() and not MirrorUnlocked() then
			if GaveFragment() or HasFragment() or WantFragment() then
				return "Unlock"
			end
		end

		if WantFragment() and not (HasFragment() or GaveFragment() or MirrorUnlocked()) then
			return "Fragment"
		end

		return nil
	end

	local function StopDough()
		DoughRunning = false
		DoughComboStart = 0
		DoughDodgeUntil = 0
		DoughPortalWait = 0
		DoughPortalOut = false
		DoughTalkWait = 0
		DoughStatus = "Idle"
		ResetTags()

		if DoughLoop then
			pcall(function()
				task.cancel(DoughLoop)
			end)
			DoughLoop = nil
		end

		EndRunner("Dough")
	end

	local function GrindMobs(Root, List)
		local Alive = {}
		for _, Entry in ipairs(List) do
			for _, Data in ipairs(FindMobs(Entry.Name, Root.Position, nil)) do
				Data.Name = Entry.Name
				table.insert(Alive, Data)
			end
		end

		table.sort(Alive, function(A, B)
			return A.Distance < B.Distance
		end)

		local Target = Alive[1]

		if not Target then
			local Spot = List[1].Spot
			local WaitCFrame = CFrame.new(Spot + Vector3.new(0, 20, 0))

			if (Root.Position - WaitCFrame.Position).Magnitude > 25 then
				LockCFrame = nil
				TravelTo(WaitCFrame, 25)
			else
				LockCFrame = WaitCFrame
			end

			task.wait(0.3)
			return
		end

		if KeepBossQuest(Target.Name) then
			return
		end

		local MobRoot = Target.Root
		local Anchor = nil

		local Nearby = {}
		for _, Data in ipairs(Alive) do
			if (Data.Root.Position - MobRoot.Position).Magnitude <= VenuzFarm.AggroRadius then
				table.insert(Nearby, Data)
			end
		end

		for Tagged in pairs(TaggedMobs) do
			if not Tagged.Parent then
				TaggedMobs[Tagged] = nil
			end
		end

		local Lead, Count, Center = PickCluster(Nearby, VenuzFarm.PackRadius)

		if Lead and Count > 1 and Center then
			MobRoot = Lead.Root
			Anchor = CFrame.new(Center)
			CurrentTag = nil
		else
			local Picked, Tagging = PickTarget(Nearby)
			if Picked then
				MobRoot = Picked.Root
			end

			if Tagging and Picked then
				if CurrentTag ~= Picked.Mob then
					CurrentTag = Picked.Mob
					TagDeadline = tick() + TagHoldTime
				elseif tick() >= TagDeadline then
					TaggedMobs[Picked.Mob] = true
					CurrentTag = nil
				end
			else
				CurrentTag = nil
			end
		end

		local Stand = GetAttackCFrame(Anchor or MobRoot.CFrame)

		if (Root.Position - Stand.Position).Magnitude > 30 then
			LockCFrame = nil
			TravelTo(Stand, 30)
			return
		end

		CancelTween()
		LockCFrame = Stand

		if tick() - DoughLastAttack >= DoughAttackDelay then
			DoughLastAttack = tick()
			task.spawn(AttackWith, EquipWeapon(BossWeaponName()), MobRoot)
		end
	end

	local function HoverAt(Root, Spot)
		local WaitCFrame = CFrame.new(Spot + Vector3.new(0, 20, 0))

		if (Root.Position - WaitCFrame.Position).Magnitude > 25 then
			LockCFrame = nil
			TravelTo(WaitCFrame, 25)
		else
			LockCFrame = WaitCFrame
			task.wait(0.5)
		end
	end

	local function TalkTo(Root, Model)
		local Spot = NpcSpot(Model)
		if not Spot then
			return nil
		end

		local Stand = CFrame.new(Spot + Vector3.new(0, 4, 0))

		if (Root.Position - Stand.Position).Magnitude > 10 then
			LockCFrame = nil
			TravelTo(Stand, 10)
			return nil
		end

		CancelTween()
		DoughTalkWait = tick() + 1.5
		StopRender()

		if tick() - DoughLastInvoke < 2 then
			return nil
		end

		DoughLastInvoke = tick()

		local Ok, Result = pcall(function()
			return Model.Interact:InvokeServer()
		end)

		return Ok and Result or nil
	end

	local function SyncDough()
		if not AnyDough() then
			StopDough()
			return
		end

		if game.PlaceId ~= Sea2Place then
			StopDough()
			return
		end

		if not HasBossWeaponPicked() then
			getgenv().Settings.AutoDoughBoss.Fragment = false
			getgenv().Settings.AutoDoughBoss.Unlock = false
			getgenv().Settings.AutoDoughBoss.Spawn = false
			getgenv().Settings.AutoDoughBoss.Kill = false
			SaveSetting()
			StopDough()
			RequireBossWeapon("Dough Boss", DoughFragmentToggle, DoughUnlockToggle, DoughSpawnToggle, DoughKillToggle)
			return
		end

		if DoughRunning then
			return
		end

		DoughRunning = true
		ResetTags()
		BeginRunner("Dough")

		DoughLoop = task.spawn(function()
			while DoughRunning do
				task.wait()

				if not IsCurrentInstance() then
					DoughRunning = false
					EndRunner("Dough")
					break
				end

				local Success = pcall(function()
					if not IsAlive() then
						LockCFrame = nil
						HoldCFrame = nil
						CancelTween()
						task.wait(1)
						return
					end

					local Root = GetRoot()
					if not Root then
						return
					end

					local Boss = FindDough()
					local Work = DoughWork()

					if not Boss and not Work and InMirrorWorld() then
						Work = "Leave"
					end

					if not Boss and not Work then
						local Left = DoughCooldownUntil - tick()

						if Left > 0 and WantSpawn() then
							DoughStatus = "Boss on cooldown (" .. math.max(0, math.round(Left / 60)) .. " min)"
						elseif WantKill() then
							DoughStatus = "Waiting for the Dough Boss to spawn"
						elseif WantUnlock() and not MirrorUnlocked() then
							DoughStatus = "No Mirror Fragment - turn on Auto Farm Mirror Fragment"
						else
							DoughStatus = "Nothing to do"
						end

						DoughComboStart = 0
						DoughDodgeUntil = 0
						IdleRunner("Dough")
						task.wait(0.5)
						return
					end

					local Busy = Boss ~= nil or tick() < DoughPortalWait or tick() < DoughTalkWait
					if not ClaimDrive("Dough", Busy and 2 or 1) then
						task.wait(0.3)
						return
					end

					if tick() < DoughPortalWait and InMirrorWorld() == DoughPortalOut then
						DoughStatus = DoughPortalOut and "Leaving Mirror World" or "Entering Mirror World"
						StopRender()
						task.wait(0.3)
						return
					end

					if tick() < DoughTalkWait then
						StopRender()
						task.wait(0.2)
						return
					end
					StartRender()

					if Boss then
						if not WantKill() then
							DoughStatus = "Dough Boss is up, Auto Kill is off"
							IdleRunner("Dough")
							task.wait(0.5)
							return
						end

						local Tool = EquipWeapon(BossWeaponName())
						local MobRoot = Boss.Root
						local Stand = GetAttackCFrame(MobRoot.CFrame)

						if (Root.Position - Stand.Position).Magnitude > 30 then
							DoughStatus = "Flying to " .. BossName
							TravelTo(Stand, 30)
							return
						end

						DoughStatus = "Fighting " .. BossName
						StartRender()
						CancelTween()
						LockCFrame = Stand

						if tick() - DoughLastAttack >= DoughAttackDelay then
							DoughLastAttack = tick()
							task.spawn(AttackWith, Tool, MobRoot)
						end

						return
					end

					DoughComboStart = 0
					DoughDodgeUntil = 0

					if Work == "Leave" then
						local Prompt, Part = MirrorExit()
						if not (Prompt and Part) then
							DoughStatus = "Mirror gate out has not loaded"
							LockCFrame = nil
							IdleRunner("Dough")
							task.wait(0.5)
							return
						end

						DoughStatus = "Leaving Mirror World"

						pcall(function()
							Prompt.Enabled = true
							Prompt.HoldDuration = 0
							Prompt.RequiresLineOfSight = false
							Prompt.MaxActivationDistance = 1000
						end)

						local Stand = CFrame.new(Part.Position + Vector3.new(0, 4, 0))

						if (Root.Position - Stand.Position).Magnitude > 8 then
							LockCFrame = nil
							TravelTo(Stand, 8)
							return
						end

						CancelTween()
						LockCFrame = Stand

						if tick() - DoughLastPortal >= 1 then
							DoughLastPortal = tick()
							DoughPortalWait = tick() + 8
							DoughPortalOut = true
							task.spawn(function()
								if not FirePrompt(Prompt) then
									DoughStatus = "Executor cannot fire the mirror prompt"
								end
							end)
							StopRender()
						end

						task.wait(0.5)
						return
					end

					if WantSpawn() and MirrorUnlocked() and tick() >= DoughCooldownUntil then
						if Gems() < 50 then
							DoughStatus = "Not enough gems to call the boss (need 50)"
						else
							local Spawner = NpcIn("DoughBossSpawner")

							if not (Spawner or InMirrorWorld()) then
								local Prompt, Part = MirrorPortal()

								if Prompt and Part then
									DoughStatus = "Going through the mirror gate"

									pcall(function()
										Prompt.Enabled = true
										Prompt.HoldDuration = 0
										Prompt.RequiresLineOfSight = false
										Prompt.MaxActivationDistance = 1000
									end)

									local StandPos = Vector3.new(-3262, 98, 11119)
									local Stand = CFrame.new(StandPos)

									if (Root.Position - Stand.Position).Magnitude > 8 then
										LockCFrame = nil
										TravelTo(Stand, 8)
										return
									end

									CancelTween()
									LockCFrame = Stand

									if tick() - DoughLastPortal >= 1 then
										DoughLastPortal = tick()
										DoughPortalWait = tick() + 8
										DoughPortalOut = false
										task.spawn(function()
											if not FirePrompt(Prompt) then
												DoughStatus = "Executor cannot fire the mirror prompt"
											end
										end)
										StopRender()
									end

									task.wait(0.5)
									return
								end

								DoughStatus = "Flying to Mirror World"
								local WaitCFrame = CFrame.new(MirrorWorldSpot + Vector3.new(0, 20, 0))

								if (Root.Position - WaitCFrame.Position).Magnitude > 50 then
									LockCFrame = nil
									TravelTo(WaitCFrame, 50)
								else
									LockCFrame = WaitCFrame
									task.wait(0.5)
								end

								return
							end

							if Spawner then
								DoughStatus = "Calling the Dough Boss (50 gems)"

								local Spot = NpcSpot(Spawner) or MirrorWorldSpot
								local Stand = CFrame.new(Spot)

								if (Root.Position - Stand.Position).Magnitude > 10 then
									LockCFrame = nil
									TravelTo(Stand, 10)
									return
								end

								CancelTween()
								LockCFrame = Stand

								if tick() - DoughLastInvoke >= 2 then
									DoughLastInvoke = tick()

									local Ok, Result = pcall(function()
										return Spawner.Interact:InvokeServer()
									end)

									if Ok and type(Result) == "number" then
										DoughCooldownUntil = tick() + Result
									end
								end

								task.wait(0.3)
								return
							end

							DoughStatus = "Looking for the Dough Boss spawner"
							HoverAt(Root, MirrorWorldSpot)
							return
						end
					end

					if WantUnlock() and not MirrorUnlocked() then
						local Npc = NpcIn(FragmentName, FragmentNpcName)

						if not GaveFragment() then
							if HasFragment() then
								if Npc then
									DoughStatus = "Giving the Mirror Fragment to the Mirror World NPC"
									TalkTo(Root, Npc)
									task.wait(0.3)
									return
								end

								DoughStatus = "Flying to Dough Island for the Mirror World NPC"
								HoverAt(Root, DoughIslandSpot)
								return
							end

							if not WantFragment() then
								DoughStatus = "No Mirror Fragment - turn on Auto Farm Mirror Fragment"
								LockCFrame = nil
								task.wait(0.5)
								return
							end
						elseif Doughnuts() >= 10 then
							if Npc then
								DoughStatus = "Unlocking Mirror World (10 Doughnuts)"
								TalkTo(Root, Npc)
								task.wait(0.3)
								return
							end

							DoughStatus = "Flying to Dough Island for the Mirror World NPC"
							HoverAt(Root, DoughIslandSpot)
							return
						else
							DoughStatus = "Farming Doughnuts (" .. Doughnuts() .. "/10)"
							GrindMobs(Root, DoughMobs)
							return
						end
					end

					if WantFragment() and not (HasFragment() or GaveFragment() or MirrorUnlocked()) then
						DoughStatus = "Farming Soul Boss for a Mirror Fragment"
						GrindMobs(Root, { { Name = "Soul Boss", Spot = SoulBossSpot } })
						return
					end

					LockCFrame = nil
					IdleRunner("Dough")
					task.wait(0.5)
				end)

				if not Success then
					task.wait(0.25)
				end
			end
		end)
	end

	DoughFragmentToggle = DoughSection:Toggle({
		Title = "tr:DoughFragment",
		Path = "AutoDoughBoss.Fragment",
		Desc = "tr:DoughFragmentDesc",
		Value = getgenv().Settings.AutoDoughBoss.Fragment,
		Icon = "check",
		Callback = function(Value)
			getgenv().Settings.AutoDoughBoss.Fragment = Value
			SaveSetting()
			SyncDough()
		end,
	})

	DoughUnlockToggle = DoughSection:Toggle({
		Title = "tr:DoughUnlock",
		Path = "AutoDoughBoss.Unlock",
		Desc = "tr:DoughUnlockDesc",
		Value = getgenv().Settings.AutoDoughBoss.Unlock,
		Icon = "check",
		Callback = function(Value)
			getgenv().Settings.AutoDoughBoss.Unlock = Value
			SaveSetting()
			SyncDough()
		end,
	})

	DoughSpawnToggle = DoughSection:Toggle({
		Title = "tr:DoughSpawn",
		Path = "AutoDoughBoss.Spawn",
		Desc = "tr:DoughSpawnDesc",
		Value = getgenv().Settings.AutoDoughBoss.Spawn,
		Icon = "check",
		Callback = function(Value)
			getgenv().Settings.AutoDoughBoss.Spawn = Value
			SaveSetting()
			SyncDough()
		end,
	})

	DoughKillToggle = DoughSection:Toggle({
		Title = "tr:DoughKill",
		Path = "AutoDoughBoss.Kill",
		Desc = "tr:DoughKillDesc",
		Value = getgenv().Settings.AutoDoughBoss.Kill,
		Icon = "check",
		Callback = function(Value)
			getgenv().Settings.AutoDoughBoss.Kill = Value
			SaveSetting()
			SyncDough()
		end,
	})

	RegisterHopTarget({
		Key = "Dough",
		Label = "Dough Boss",
		Find = FindDough,
		Enabled = AnyDough,
	})

	VenuzToggle.NeedsDough = function()
		return false
	end

	VenuzToggle.StopDough = function()
		getgenv().Settings.AutoDoughBoss.Fragment = false
		getgenv().Settings.AutoDoughBoss.Unlock = false
		getgenv().Settings.AutoDoughBoss.Spawn = false
		getgenv().Settings.AutoDoughBoss.Kill = false
		SaveSetting()
		StopDough()
		SetToggleValue(DoughFragmentToggle, false)
		SetToggleValue(DoughUnlockToggle, false)
		SetToggleValue(DoughSpawnToggle, false)
		SetToggleValue(DoughKillToggle, false)
	end

	task.spawn(function()
		while task.wait(1) do
			if not IsCurrentInstance() then
				break
			end
			RT.Push("Dough status", DoughParagraph, function()
				local Left = DoughCooldownUntil - tick()
				local Boss = FindDough()
				local Lines = {
					RT.Head("Dough Boss", RT.Red),
					RT.State(DoughStatus, DoughRunning),
					RT.Flag("Fragment", HasFragment() or GaveFragment())
						.. RT.Sep
						.. RT.Flag("Mirror World", MirrorUnlocked()),
					RT.Paint("Doughnuts: ", RT.Muted)
						.. RT.Bold(Doughnuts() .. "/10", Doughnuts() >= 10 and RT.Green or RT.Amber)
						.. RT.Sep
						.. RT.Paint("Gems: ", RT.Muted)
						.. RT.Bold(RT.Num(Gems()) .. "/50", Gems() >= 50 and RT.Green or RT.Amber),
				}

				RT.Add(Lines, RT.Target("Boss", Boss))
				RT.Add(
					Lines,
					RT.Paint("Cooldown: ", RT.Muted)
						.. RT.Bold(Left > 0 and RT.Clock(Left) or "ready", Left > 0 and RT.Amber or RT.Green)
				)

				return table.concat(Lines, "\n")
			end)
		end
	end)

	if
		getgenv().Settings.AutoDoughBoss.Fragment
		or getgenv().Settings.AutoDoughBoss.Unlock
		or getgenv().Settings.AutoDoughBoss.Spawn
		or getgenv().Settings.AutoDoughBoss.Kill
	then
		task.defer(SyncDough)
	end
end)()
;
(function()
	local Sea2Place = 14979402479
	local BossName = "Dragon Boss"

	local DragonMobs = {
		{ Name = "Beast Pirate", Spot = Vector3.new(6696, 1131, 7413) },
		{ Name = "Elite Beast", Spot = Vector3.new(7353, 1137, 7227) },
	}

	local function GetTotem()
		local Logic = workspace:FindFirstChild("Logic")
		local POI = Logic and Logic:FindFirstChild("PointsOfInterest")
		return POI and POI:FindFirstChild("DragonTotem")
	end

	local function KillsLeft()
		local Totem = GetTotem()
		local Count = Totem and Totem:FindFirstChild("Count")
		return Count and Count.Value or -1
	end

	local function FindDragon()
		local Root = GetRoot()
		return FindMobs(BossName, Root and Root.Position, nil)[1]
	end

	local DragonSection = BossSea2Section:Section({ Title = "tr:DragonSection", Icon = "flame", Opened = true })

	local DragonStatus = "-"
	local DragonParagraph = RT.Status(DragonSection, "tr:DragonStatus")

	local DragonRunning = false
	local DragonLoop = nil
	local DragonLastAttack = 0
	local DragonComboStart = 0
	local DragonDodgeUntil = 0
	local DragonAttackDelay = 0.15
	local DragonSummonToggle, DragonKillToggle

	local function WantSummon()
		return getgenv().Settings.AutoDragonBoss.Summon == true
	end

	local function WantKill()
		return getgenv().Settings.AutoDragonBoss.Kill == true
	end

	local function StopDragon()
		DragonRunning = false
		DragonComboStart = 0
		DragonDodgeUntil = 0
		DragonStatus = "Idle"
		ResetTags()

		if DragonLoop then
			pcall(function()
				task.cancel(DragonLoop)
			end)
			DragonLoop = nil
		end

		EndRunner("Dragon")
	end

	local function SyncDragon()
		if not (WantSummon() or WantKill()) then
			StopDragon()
			return
		end

		if game.PlaceId ~= Sea2Place then
			StopDragon()
			return
		end

		if not HasBossWeaponPicked() then
			getgenv().Settings.AutoDragonBoss.Summon = false
			getgenv().Settings.AutoDragonBoss.Kill = false
			SaveSetting()
			StopDragon()
			RequireBossWeapon("Dragon Boss", DragonSummonToggle, DragonKillToggle)
			return
		end

		if WantSummon() then
			SetToggleValue(AutoFarmToggle, false)
			SetToggleValue(Sea3Toggle, false)
			SetToggleValue(VenuzToggle.BossToggle, false)
			SetToggleValue(VenuzToggle.MobToggle, false)
		end

		if DragonRunning then
			return
		end

		DragonRunning = true
		ResetTags()
		BeginRunner("Dragon")

		DragonLoop = task.spawn(function()
			while DragonRunning do
				task.wait()

				if not IsCurrentInstance() then
					DragonRunning = false
					EndRunner("Dragon")
					break
				end

				local Success = pcall(function()
					if not IsAlive() then
						LockCFrame = nil
						HoldCFrame = nil
						CancelTween()
						task.wait(1)
						return
					end

					local Root = GetRoot()
					if not Root then
						return
					end

					local Summoning = WantSummon()
					local Boss = FindDragon()

					if not Boss and not Summoning then
						DragonStatus = "Waiting for the boss"
						DragonComboStart = 0
						DragonDodgeUntil = 0
						IdleRunner("Dragon")
						task.wait(0.5)
						return
					end

					if Boss and not WantKill() then
						DragonStatus = "Boss is up, Auto Kill is off"
						IdleRunner("Dragon")
						task.wait(0.5)
						return
					end

					if not ClaimDrive("Dragon", Boss and 2 or 1) then
						DragonStatus = "Another farm is moving, waiting"
						task.wait(0.3)
						return
					end

					if Boss then
						local Tool = EquipWeapon(BossWeaponName())
						local MobRoot = Boss.Root
						local Stand = GetAttackCFrame(MobRoot.CFrame)

						if (Root.Position - Stand.Position).Magnitude > 30 then
							DragonStatus = "Flying to " .. BossName
							StartRender()
							LockCFrame = nil
							TravelTo(Stand, 30)
							return
						end

						DragonStatus = "Fighting " .. BossName
						StartRender()
						CancelTween()
						LockCFrame = Stand

						if tick() - DragonLastAttack >= DragonAttackDelay then
							DragonLastAttack = tick()
							task.spawn(AttackWith, Tool, MobRoot)
						end

						return
					end

					DragonComboStart = 0
					DragonDodgeUntil = 0

					StartRender()

					local Left = KillsLeft()
					DragonStatus = Left >= 0 and ("Farming Dragon Island (" .. Left .. " kills left)")
						or "Flying to Dragon Island"

					local Alive = {}
					for _, Entry in ipairs(DragonMobs) do
						for _, Data in ipairs(FindMobs(Entry.Name, Root.Position, nil)) do
							Data.Name = Entry.Name
							table.insert(Alive, Data)
						end
					end

					table.sort(Alive, function(A, B)
						return A.Distance < B.Distance
					end)

					local Target = Alive[1]

					if not Target then
						local Spot = DragonMobs[1].Spot
						local WaitCFrame = CFrame.new(Spot + Vector3.new(0, 20, 0))

						if (Root.Position - WaitCFrame.Position).Magnitude > 25 then
							LockCFrame = nil
							TravelTo(WaitCFrame, 25)
						else
							LockCFrame = WaitCFrame
						end

						task.wait(0.3)
						return
					end

					if KeepBossQuest(Target.Name) then
						return
					end

					local MobRoot = Target.Root
					local Anchor = nil

					local Nearby = {}
					for _, Data in ipairs(Alive) do
						if (Data.Root.Position - MobRoot.Position).Magnitude <= VenuzFarm.AggroRadius then
							table.insert(Nearby, Data)
						end
					end

					for Tagged in pairs(TaggedMobs) do
						if not Tagged.Parent then
							TaggedMobs[Tagged] = nil
						end
					end

					local Lead, Count, Center = PickCluster(Nearby, VenuzFarm.PackRadius)

					if Lead and Count > 1 and Center then
						MobRoot = Lead.Root
						Anchor = CFrame.new(Center)
						CurrentTag = nil
					else
						local Picked, Tagging = PickTarget(Nearby)
						if Picked then
							MobRoot = Picked.Root
						end

						if Tagging and Picked then
							if CurrentTag ~= Picked.Mob then
								CurrentTag = Picked.Mob
								TagDeadline = tick() + TagHoldTime
							elseif tick() >= TagDeadline then
								TaggedMobs[Picked.Mob] = true
								CurrentTag = nil
							end
						else
							CurrentTag = nil
						end
					end

					local Stand = GetAttackCFrame(Anchor or MobRoot.CFrame)

					if (Root.Position - Stand.Position).Magnitude > 30 then
						LockCFrame = nil
						TravelTo(Stand, 30)
						return
					end

					CancelTween()
					LockCFrame = Stand

					if tick() - DragonLastAttack >= DragonAttackDelay then
						DragonLastAttack = tick()
						task.spawn(AttackWith, EquipWeapon(BossWeaponName()), MobRoot)
					end
				end)

				if not Success then
					task.wait(0.25)
				end
			end
		end)
	end

	DragonSummonToggle = DragonSection:Toggle({
		Title = "tr:DragonSummon",
		Path = "AutoDragonBoss.Summon",
		Desc = "tr:DragonSummonDesc",

		Value = getgenv().Settings.AutoDragonBoss.Summon,
		Icon = "check",
		Callback = function(Value)
			getgenv().Settings.AutoDragonBoss.Summon = Value
			SaveSetting()
			SyncDragon()
		end,
	})

	DragonKillToggle = DragonSection:Toggle({
		Title = "tr:DragonKill",
		Path = "AutoDragonBoss.Kill",
		Desc = "tr:DragonKillDesc",
		Value = getgenv().Settings.AutoDragonBoss.Kill,
		Icon = "check",
		Callback = function(Value)
			getgenv().Settings.AutoDragonBoss.Kill = Value
			SaveSetting()
			SyncDragon()
		end,
	})

	RegisterHopTarget({
		Key = "Dragon",
		Label = "Dragon Boss",
		Find = FindDragon,
		Enabled = function()
			return WantSummon() or WantKill()
		end,
	})

	VenuzToggle.NeedsDragon = function()
		return WantSummon()
	end

	VenuzToggle.StopDragon = function()
		getgenv().Settings.AutoDragonBoss.Summon = false
		getgenv().Settings.AutoDragonBoss.Kill = false
		SaveSetting()
		StopDragon()
		SetToggleValue(DragonSummonToggle, false)
		SetToggleValue(DragonKillToggle, false)
	end

	task.spawn(function()
		while task.wait(1) do
			if not IsCurrentInstance() then
				break
			end
			RT.Push("Dragon status", DragonParagraph, function()
				local Left = KillsLeft()
				local Boss = FindDragon()
				local Lines = {
					RT.Head("Dragon Boss", RT.Red),
					RT.State(DragonStatus, DragonRunning),
					RT.Paint("Kills required: ", RT.Muted) .. (Left >= 0 and RT.Bold(
						Left,
						Left == 0 and RT.Green or RT.Amber
					) or RT.Bold("totem not loaded", RT.Red)),
				}

				RT.Add(Lines, RT.Target("Boss", Boss))

				return table.concat(Lines, "\n")
			end)
		end
	end)

	if getgenv().Settings.AutoDragonBoss.Summon or getgenv().Settings.AutoDragonBoss.Kill then
		task.defer(SyncDragon)
	end
end)()
;
(function()
	local BossSea2Place = 14979402479

	local ZenithSpot = Vector3.new(1392, 128, 7144)
	local ZenithName = "Zenith Boss"

	local ZenithSection = BossSea2Section:Section({ Title = "tr:ZenithSection", Icon = "skull", Opened = true })

	local ZenithStatus = "-"
	local ZenithParagraph = RT.Status(ZenithSection, "tr:ZenithStatus")

	local ZenithRunning = false
	local ZenithLoop = nil
	local ZenithLastAttack = 0
	local ZenithComboStart = 0
	local ZenithDodgeUntil = 0
	local ZenithAttackDelay = 0.15
	local ZenithArrivedAt = 0
	local ZenithHopping = false
	local ZenithKillToggle

	local function FindZenith()
		local Root = GetRoot()
		local Origin = Root and Root.Position
		local Best, BestDist = nil, math.huge

		for _, Entry in ipairs(IterNPCs()) do
			if string.find(string.lower(GetMobName(Entry.Mob)), "zenith") then
				local Distance = Origin and (Entry.Root.Position - Origin).Magnitude or 0
				if Distance < BestDist then
					BestDist = Distance
					Best = { Mob = Entry.Mob, Root = Entry.Root, Humanoid = Entry.Humanoid, Distance = Distance }
				end
			end
		end

		return Best
	end

	local function HopServer()
		if ZenithHopping then
			return
		end
		ZenithHopping = true

		local TeleportService = game:GetService("TeleportService")
		local HttpService = game:GetService("HttpService")
		local PlaceId = game.PlaceId

		local ok, Body = pcall(function()
			return game:HttpGet(
				"https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
			)
		end)

		if ok then
			local Decoded = nil
			pcall(function()
				Decoded = HttpService:JSONDecode(Body)
			end)

			local Candidates = {}
			if Decoded and type(Decoded.data) == "table" then
				for _, Server in ipairs(Decoded.data) do
					if Server.id ~= game.JobId and (Server.playing or 0) < (Server.maxPlayers or 0) then
						table.insert(Candidates, Server.id)
					end
				end
			end

			if #Candidates > 0 then
				local Pick = Candidates[math.random(1, #Candidates)]
				pcall(function()
					TeleportService:TeleportToPlaceInstance(PlaceId, Pick, LocalPlayer)
				end)
				return
			end
		end

		pcall(function()
			TeleportService:Teleport(game.PlaceId, LocalPlayer)
		end)

		ZenithHopping = false
	end

	local function HopEmptyServer()
		if ZenithHopping then
			return
		end
		ZenithHopping = true

		local TeleportService = game:GetService("TeleportService")
		local HttpService = game:GetService("HttpService")
		local PlaceId = game.PlaceId
		local Url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"

		local Body = nil

		local Request = (http and http.request) or request or (syn and syn.request)

		if Request then
			pcall(function()
				local Response = Request({ Url = Url, Method = "GET" })
				Body = Response and Response.Body
			end)
		end

		if not Body then
			pcall(function()
				Body = game:HttpGet(Url)
			end)
		end

		if Body then
			local Decoded = nil
			pcall(function()
				Decoded = HttpService:JSONDecode(Body)
			end)

			local Candidates = {}
			if Decoded and type(Decoded.data) == "table" then
				for _, Server in ipairs(Decoded.data) do
					if Server.id and Server.id ~= game.JobId and (Server.playing or 0) < 2 then
						table.insert(Candidates, Server.id)
					end
				end
			end

			if #Candidates > 0 then
				local Pick = Candidates[math.random(1, #Candidates)]
				pcall(function()
					TeleportService:TeleportToPlaceInstance(PlaceId, Pick, LocalPlayer)
				end)
				return
			end
		end

		ZenithHopping = false

		HopServer()
	end

	local function StopZenith()
		ZenithRunning = false
		ZenithComboStart = 0
		ZenithDodgeUntil = 0
		ZenithArrivedAt = 0
		ZenithStatus = "Idle"

		if ZenithLoop then
			pcall(function()
				task.cancel(ZenithLoop)
			end)
			ZenithLoop = nil
		end

		EndRunner("Zenith")
	end

	local function SyncZenith()
		if getgenv().Settings.AutoZenithBoss.Enabled ~= true then
			StopZenith()
			return
		end

		if game.PlaceId ~= BossSea2Place then
			StopZenith()
			return
		end

		if not HasBossWeaponPicked() then
			getgenv().Settings.AutoZenithBoss.Enabled = false
			SaveSetting()
			StopZenith()
			RequireBossWeapon("Zenith Boss", ZenithKillToggle)
			return
		end

		if ZenithRunning then
			return
		end

		SetToggleValue(Sea3Toggle, false)

		ZenithRunning = true
		ZenithArrivedAt = 0
		BeginRunner("Zenith")

		ZenithLoop = task.spawn(function()
			while ZenithRunning do
				task.wait()

				if not IsCurrentInstance() then
					ZenithRunning = false
					EndRunner("Zenith")
					break
				end

				local Success = pcall(function()
					if not IsAlive() then
						LockCFrame = nil
						HoldCFrame = nil
						CancelTween()
						task.wait(1)
						return
					end

					local Root = GetRoot()
					if not Root then
						return
					end

					local Boss = FindZenith()

					if not Boss then
						ZenithComboStart = 0
						ZenithDodgeUntil = 0
						IdleRunner("Zenith")

						if ZenithArrivedAt == 0 then
							ZenithArrivedAt = tick()
						end

						ZenithStatus = string.format("Waiting for the boss (%ds)", math.floor(tick() - ZenithArrivedAt))

						task.wait(0.5)
						return
					end

					if not ClaimDrive("Zenith", 2) then
						ZenithStatus = "Another boss farm is moving, waiting"
						task.wait(0.3)
						return
					end

					do
						ZenithArrivedAt = 0

						local Tool = EquipWeapon(BossWeaponName())
						local MobRoot = Boss.Root
						local Stand = GetAttackCFrame(MobRoot.CFrame)

						if (Root.Position - Stand.Position).Magnitude > 30 then
							ZenithStatus = "Flying to " .. ZenithName
							StartRender()
							LockCFrame = nil
							TravelTo(Stand, 30)
							return
						end

						ZenithStatus = "Fighting " .. ZenithName
						StartRender()
						CancelTween()
						LockCFrame = Stand

						if tick() - ZenithLastAttack >= ZenithAttackDelay then
							ZenithLastAttack = tick()
							task.spawn(AttackWith, Tool, MobRoot)
						end

						return
					end
				end)

				if not Success then
					task.wait(0.25)
				end
			end
		end)
	end

	ZenithKillToggle = ZenithSection:Toggle({
		Title = "tr:ZenithKill",
		Path = "AutoZenithBoss.Enabled",
		Desc = "tr:ZenithKillDesc",

		Value = getgenv().Settings.AutoZenithBoss.Enabled,
		Icon = "check",
		Callback = function(Value)
			getgenv().Settings.AutoZenithBoss.Enabled = Value
			SaveSetting()
			SyncZenith()
		end,
	})

	RegisterHopTarget({
		Key = "Zenith",
		Label = ZenithName,
		Find = FindZenith,
		Enabled = function()
			return getgenv().Settings.AutoZenithBoss.Enabled == true
		end,
	})

	VenuzToggle.NeedsZenith = function()
		return false
	end

	VenuzToggle.StopZenith = function()
		getgenv().Settings.AutoZenithBoss.Enabled = false
		SaveSetting()
		StopZenith()
		SetToggleValue(ZenithKillToggle, false)
	end

	task.spawn(function()
		while task.wait(1) do
			if not IsCurrentInstance() then
				break
			end
			RT.Push("Zenith status", ZenithParagraph, function()
				local Boss = FindZenith()
				local Lines = {
					RT.Head("Zenith Boss", RT.Red),
					RT.State(ZenithStatus, ZenithRunning),
				}

				if Boss then
					RT.Add(Lines, RT.Target("Boss", Boss))
				end

				RT.Add(
					Lines,
					RT.Flag("Auto Kill", getgenv().Settings.AutoZenithBoss.Enabled)
						.. RT.Sep
						.. RT.Flag("Priority", true)
						.. " "
						.. RT.Bold("#" .. PriorityOf("Zenith"), RT.Muted)
				)

				return table.concat(Lines, "\n")
			end)
		end
	end)

	if getgenv().Settings.AutoZenithBoss.Enabled then
		task.defer(SyncZenith)
	end

	local BossSea3Place = 99664616626491
	local SaturnSpot = Vector3.new(3561, 1147, 1084)
	local SaturnName = "Saturn Boss"

	local SaturnSection = BossSea3Section:Section({ Title = "tr:SaturnSection", Icon = "skull", Opened = true })

	local SaturnStatus = "-"
	local SaturnParagraph = RT.Status(SaturnSection, "tr:SaturnStatus")

	local SaturnRunning = false
	local SaturnLoop = nil
	local SaturnLastAttack = 0
	local SaturnComboStart = 0
	local SaturnDodgeUntil = 0
	local SaturnAttackDelay = 0.15
	local SaturnKillToggle

	local function FindSaturn()
		local Root = GetRoot()
		local Origin = Root and Root.Position
		local Best, BestDist = nil, math.huge

		for _, Entry in ipairs(IterNPCs()) do
			if string.find(string.lower(GetMobName(Entry.Mob)), "saturn") then
				local Distance = Origin and (Entry.Root.Position - Origin).Magnitude or 0
				if Distance < BestDist then
					BestDist = Distance
					Best = { Mob = Entry.Mob, Root = Entry.Root, Humanoid = Entry.Humanoid, Distance = Distance }
				end
			end
		end

		return Best
	end

	local SaturnWaves = {
		{ Match = "saturn", Boss = true, Final = true },
		{ Match = "minion", Boss = true },
		{ Match = "paw", Boss = true },
		{ Match = "raider captain", Boss = false },
		{ Match = "raider", Boss = false },
	}

	local SaturnEvent = { At = 0, Spot = SaturnSpot, SeenAt = 0, Fought = false, SawBoss = false, ArrivedAt = 0 }
	local SaturnEventLife = 1200
	local SaturnEventWords = {
		"authority has been invoked",
		"higher being has descended",
		"started raiding egg island",
		"raiding egg island",
	}

	local function NoteSaturnCall(Text)
		if type(Text) ~= "string" then
			return
		end

		local Lower = string.lower(Text)
		for _, Word in ipairs(SaturnEventWords) do
			if string.find(Lower, Word, 1, true) then
				if SaturnEvent.Fought then
					return
				end

				SaturnEvent.At = tick()
				SaturnEvent.Spot = SaturnSpot
				SaturnEvent.SeenAt = 0
				SaturnEvent.ArrivedAt = 0

				if SaturnRunning then
					SaturnStatus = "Event called, flying to Egg Island"
				end

				return
			end
		end
	end

	local function SaturnEventLive()
		return tick() - SaturnEvent.At <= SaturnEventLife
	end

	local SaturnWaveGap = 90

	local SaturnArriveGrace = 10

	local function FinishSaturnEvent()
		SaturnEvent.At = 0
		SaturnEvent.Fought = false
		SaturnEvent.SeenAt = 0
		SaturnEvent.SawBoss = false
		SaturnEvent.ArrivedAt = 0
		SaturnEvent.Spot = SaturnSpot
	end

	task.spawn(function()
		pcall(function()
			game:GetService("TextChatService").MessageReceived:Connect(function(Message)
				NoteSaturnCall(Message and Message.Text)
			end)
		end)

		pcall(function()
			local Events = game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents", 15)
			local Filtered = Events and Events:WaitForChild("OnMessageDoneFiltering", 15)

			if Filtered then
				Filtered.OnClientEvent:Connect(function(Data)
					NoteSaturnCall(type(Data) == "table" and Data.Message or Data)
				end)
			end
		end)
	end)

	local function FindSaturnTarget()
		local Root = GetRoot()
		local Origin = Root and Root.Position
		local Best, BestRank, BestDist = nil, math.huge, math.huge

		local Anchor = SaturnEvent.Spot or SaturnSpot

		for _, Entry in ipairs(IterNPCs()) do
			local Label = GetMobName(Entry.Mob)
			local Lower = string.lower(Label)

			for Rank, Wave in ipairs(SaturnWaves) do
				if
					string.find(Lower, Wave.Match, 1, true)
					and (Wave.Boss or (Entry.Root.Position - Anchor).Magnitude <= 1500)
				then
					local Distance = Origin and (Entry.Root.Position - Origin).Magnitude or 0

					if Rank < BestRank or (Rank == BestRank and Distance < BestDist) then
						BestRank, BestDist = Rank, Distance
						Best = {
							Mob = Entry.Mob,
							Root = Entry.Root,
							Humanoid = Entry.Humanoid,
							Distance = Distance,
							Boss = Wave.Boss,
							Final = Wave.Final,
							Label = Label,
						}
					end

					break
				end
			end
		end

		return Best
	end

	local function StopSaturn()
		SaturnRunning = false
		SaturnComboStart = 0
		SaturnDodgeUntil = 0
		SaturnStatus = "Idle"

		if SaturnLoop then
			pcall(function()
				task.cancel(SaturnLoop)
			end)
			SaturnLoop = nil
		end

		EndRunner("Saturn")
	end

	local function SyncSaturn()
		if getgenv().Settings.AutoSaturnBoss.Enabled ~= true then
			StopSaturn()
			return
		end

		if game.PlaceId ~= BossSea3Place then
			StopSaturn()
			return
		end

		if not HasBossWeaponPicked() then
			getgenv().Settings.AutoSaturnBoss.Enabled = false
			SaveSetting()
			StopSaturn()
			RequireBossWeapon("Saturn Boss", SaturnKillToggle)
			return
		end

		if SaturnRunning then
			return
		end

		SetToggleValue(Sea3Toggle, false)

		SaturnRunning = true
		BeginRunner("Saturn")

		SaturnLoop = task.spawn(function()
			while SaturnRunning do
				task.wait()

				if not IsCurrentInstance() then
					SaturnRunning = false
					EndRunner("Saturn")
					break
				end

				local Success = pcall(function()
					if not IsAlive() then
						LockCFrame = nil
						HoldCFrame = nil
						CancelTween()
						task.wait(1)
						return
					end

					local Root = GetRoot()
					if not Root then
						return
					end

					local Target = FindSaturnTarget()

					if Target then
						SaturnEvent.Spot = Target.Root.Position
						SaturnEvent.SeenAt = tick()
						SaturnEvent.ArrivedAt = 0
						SaturnEvent.Fought = true

						if Target.Final then
							SaturnEvent.SawBoss = true
						end
					elseif SaturnEvent.SawBoss then
						FinishSaturnEvent()
						SaturnStatus = "Saturn cleared, back to the other farms"
						IdleRunner("Saturn")
						task.wait(0.5)
						return
					elseif SaturnEvent.Fought and tick() - SaturnEvent.SeenAt >= SaturnWaveGap then
						FinishSaturnEvent()
						SaturnStatus = "Event cleared, waiting for the next call"
					end

					local Live = SaturnEventLive()

					if not Target and not Live then
						SaturnStatus = "Waiting for the Egg Island call"
						SaturnComboStart = 0
						SaturnDodgeUntil = 0
						IdleRunner("Saturn")
						task.wait(0.5)
						return
					end

					if not ClaimDrive("Saturn", (Target or Live) and 2 or 1) then
						SaturnStatus = "Another boss farm is moving, waiting"
						task.wait(0.3)
						return
					end

					if Target then
						local Tool = EquipWeapon(BossWeaponName())
						local MobRoot = Target.Root
						local Stand = GetAttackCFrame(MobRoot.CFrame)

						if (Root.Position - Stand.Position).Magnitude > 30 then
							SaturnStatus = "Flying to " .. Target.Label
							StartRender()
							LockCFrame = nil
							TravelTo(Stand, 30)
							return
						end

						SaturnStatus = "Fighting " .. Target.Label
						StartRender()
						CancelTween()
						LockCFrame = Stand

						if tick() - SaturnLastAttack >= SaturnAttackDelay then
							SaturnLastAttack = tick()
							task.spawn(AttackWith, Tool, MobRoot)
						end

						return
					end

					StartRender()

					SaturnComboStart = 0
					SaturnDodgeUntil = 0

					local Spot = SaturnEvent.Spot or SaturnSpot

					if not Live then
						SaturnStatus = "Waiting for the Egg Island call"
						IdleRunner("Saturn")
						task.wait(1)
						return
					end

					local WaitCFrame = CFrame.new(Spot + Vector3.new(0, 25, 0))

					if (Root.Position - WaitCFrame.Position).Magnitude > 400 then
						SaturnStatus = "Event called, flying to Egg Island"
						SaturnEvent.ArrivedAt = 0
						LockCFrame = nil
						TravelTo(WaitCFrame, 25)
						return
					end

					if SaturnEvent.ArrivedAt == 0 then
						SaturnEvent.ArrivedAt = tick()
					end

					if not SaturnEvent.Fought and tick() - SaturnEvent.ArrivedAt >= SaturnArriveGrace then
						FinishSaturnEvent()
						SaturnStatus = "Nothing spawned, call dropped"
						IdleRunner("Saturn")
						task.wait(0.5)
						return
					end

					if FarmMobsAround("Saturn", Spot, 500) then
						SaturnStatus = "Clearing mobs between waves"
						return
					end

					SaturnStatus = "On Egg Island, waiting for the next wave"
					LockCFrame = WaitCFrame
					task.wait(0.3)
				end)

				if not Success then
					task.wait(0.25)
				end
			end
		end)
	end

	SaturnKillToggle = SaturnSection:Toggle({
		Title = "tr:SaturnKill",
		Path = "AutoSaturnBoss.Enabled",
		Desc = "tr:SaturnKillDesc",
		Value = getgenv().Settings.AutoSaturnBoss.Enabled,
		Icon = "check",
		Callback = function(Value)
			getgenv().Settings.AutoSaturnBoss.Enabled = Value
			SaveSetting()
			SyncSaturn()
		end,
	})

	RegisterHopTarget({
		Key = "Saturn",
		Label = SaturnName,
		Find = function()
			return FindSaturnTarget() or (SaturnEventLive() and SaturnEvent or nil)
		end,
		Enabled = function()
			return getgenv().Settings.AutoSaturnBoss.Enabled == true
		end,
	})

	VenuzToggle.NeedsSaturn = function()
		return false
	end

	VenuzToggle.StopSaturn = function()
		getgenv().Settings.AutoSaturnBoss.Enabled = false
		SaveSetting()
		StopSaturn()
		SetToggleValue(SaturnKillToggle, false)
	end

	task.spawn(function()
		while task.wait(1) do
			if not IsCurrentInstance() then
				break
			end
			RT.Push("Saturn status", SaturnParagraph, function()
				local Boss = FindSaturn()
				local Target = FindSaturnTarget()
				local Lines = {
					RT.Head("Saturn Boss", RT.Red),
					RT.State(SaturnStatus, SaturnRunning),
					RT.Flag("Event Called", SaturnEventLive()),
				}

				if Boss then
					RT.Add(Lines, RT.Target("Boss", Boss))
				elseif Target then
					RT.Add(Lines, RT.Target(Target.Label, Target))
				end

				RT.Add(Lines, RT.Flag("Auto Kill", getgenv().Settings.AutoSaturnBoss.Enabled))

				return table.concat(Lines, "\n")
			end)
		end
	end)

	if getgenv().Settings.AutoSaturnBoss.Enabled then
		task.defer(SyncSaturn)
	end

	local EnmaSpot = Vector3.new(3744, 165, 15881)
	local EnmaName = "Enma Boss"

	local EnmaSection = BossSea2Section:Section({ Title = "tr:EnmaSection", Icon = "skull", Opened = true })

	local EnmaStatus = "-"
	local EnmaParagraph = RT.Status(EnmaSection, "tr:EnmaStatus")

	local EnmaRunning = false
	local EnmaLoop = nil
	local EnmaLastAttack = 0
	local EnmaAttackDelay = 0.15
	local EnmaArrivedAt = 0
	local EnmaKillToggle

	local function FindEnma()
		local Root = GetRoot()
		local Origin = Root and Root.Position
		local Best, BestDist = nil, math.huge

		for _, Entry in ipairs(IterNPCs()) do
			if string.find(string.lower(GetMobName(Entry.Mob)), "enma") then
				local Distance = Origin and (Entry.Root.Position - Origin).Magnitude or 0
				if Distance < BestDist then
					BestDist = Distance
					Best = { Mob = Entry.Mob, Root = Entry.Root, Humanoid = Entry.Humanoid, Distance = Distance }
				end
			end
		end

		return Best
	end

	local function StopEnma()
		EnmaRunning = false
		EnmaArrivedAt = 0
		EnmaStatus = "Idle"

		if EnmaLoop then
			pcall(function()
				task.cancel(EnmaLoop)
			end)
			EnmaLoop = nil
		end

		EndRunner("Enma")
	end

	local function SyncEnma()
		if getgenv().Settings.AutoEnmaBoss.Enabled ~= true then
			StopEnma()
			return
		end

		if game.PlaceId ~= BossSea2Place then
			StopEnma()
			return
		end

		if not HasBossWeaponPicked() then
			getgenv().Settings.AutoEnmaBoss.Enabled = false
			SaveSetting()
			StopEnma()
			RequireBossWeapon("Enma Boss", EnmaKillToggle)
			return
		end

		if EnmaRunning then
			return
		end

		SetToggleValue(Sea3Toggle, false)

		EnmaRunning = true
		EnmaArrivedAt = 0
		BeginRunner("Enma")

		EnmaLoop = task.spawn(function()
			while EnmaRunning do
				task.wait()

				if not IsCurrentInstance() then
					EnmaRunning = false
					EndRunner("Enma")
					break
				end

				local Success = pcall(function()
					if not IsAlive() then
						LockCFrame = nil
						HoldCFrame = nil
						CancelTween()
						task.wait(1)
						return
					end

					local Root = GetRoot()
					if not Root then
						return
					end

					local Boss = FindEnma()

					if not Boss then
						IdleRunner("Enma")

						if EnmaArrivedAt == 0 then
							EnmaArrivedAt = tick()
						end

						EnmaStatus = string.format("Waiting for the boss (%ds)", math.floor(tick() - EnmaArrivedAt))

						task.wait(0.5)
						return
					end

					if not ClaimDrive("Enma", 2) then
						EnmaStatus = "Another boss farm is moving, waiting"
						task.wait(0.3)
						return
					end

					do
						EnmaArrivedAt = 0

						local Tool = EquipWeapon(BossWeaponName())
						local MobRoot = Boss.Root
						local Stand = GetAttackCFrame(MobRoot.CFrame)

						if (Root.Position - Stand.Position).Magnitude > 30 then
							EnmaStatus = "Flying to " .. EnmaName
							StartRender()
							LockCFrame = nil
							TravelTo(Stand, 30)
							return
						end

						EnmaStatus = "Fighting " .. EnmaName
						StartRender()
						CancelTween()
						LockCFrame = Stand

						if tick() - EnmaLastAttack >= EnmaAttackDelay then
							EnmaLastAttack = tick()
							task.spawn(AttackWith, Tool, MobRoot)
						end

						return
					end
				end)

				if not Success then
					task.wait(0.25)
				end
			end
		end)
	end

	EnmaKillToggle = EnmaSection:Toggle({
		Title = "tr:EnmaKill",
		Path = "AutoEnmaBoss.Enabled",
		Desc = "tr:EnmaKillDesc",
		Value = getgenv().Settings.AutoEnmaBoss.Enabled,
		Icon = "check",
		Callback = function(Value)
			getgenv().Settings.AutoEnmaBoss.Enabled = Value
			SaveSetting()
			SyncEnma()
		end,
	})

	RegisterHopTarget({
		Key = "Enma",
		Label = EnmaName,
		Find = FindEnma,
		Enabled = function()
			return getgenv().Settings.AutoEnmaBoss.Enabled == true
		end,
	})

	VenuzToggle.NeedsEnma = function()
		return false
	end

	VenuzToggle.StopEnma = function()
		getgenv().Settings.AutoEnmaBoss.Enabled = false
		SaveSetting()
		StopEnma()
		SetToggleValue(EnmaKillToggle, false)
	end

	task.spawn(function()
		while task.wait(1) do
			if not IsCurrentInstance() then
				break
			end
			RT.Push("Enma status", EnmaParagraph, function()
				local Boss = FindEnma()
				local Lines = {
					RT.Head("Enma Boss", RT.Red),
					RT.State(EnmaStatus, EnmaRunning),
				}

				if Boss then
					RT.Add(Lines, RT.Target("Boss", Boss))
				end

				RT.Add(
					Lines,
					RT.Flag("Auto Kill", getgenv().Settings.AutoEnmaBoss.Enabled)
						.. RT.Sep
						.. RT.Flag("Priority", true)
						.. " "
						.. RT.Bold("#" .. PriorityOf("Enma"), RT.Muted)
				)

				return table.concat(Lines, "\n")
			end)
		end
	end)

	if getgenv().Settings.AutoEnmaBoss.Enabled then
		task.defer(SyncEnma)
	end

	local VaultName = "Vault Chest"

	local VaultSection = BossSea2Section:Section({ Title = "tr:VaultSection", Icon = "vault", Opened = true })

	local VaultStatus = "-"
	local VaultParagraph = RT.Status(VaultSection, "tr:VaultStatus")

	local VaultRunning = false
	local VaultLoop = nil
	local VaultLastAttack = 0
	local VaultComboStart = 0
	local VaultDodgeUntil = 0
	local VaultAttackDelay = 0.15
	local VaultArrivedAt = 0
	local VaultKillToggle

	local function NameMatches(Name, Words)
		local Lower = string.lower(Name)

		for _, Word in ipairs(Words) do
			if string.find(Lower, Word, 1, true) then
				return true
			end
		end

		return false
	end

	local function FindRaidTarget(Words)
		local Root = GetRoot()
		local Origin = Root and Root.Position
		local Best, BestDist = nil, math.huge

		for _, Entry in ipairs(IterNPCs()) do
			if NameMatches(GetMobName(Entry.Mob), Words) then
				local Distance = Origin and (Entry.Root.Position - Origin).Magnitude or 0
				if Distance < BestDist then
					BestDist = Distance
					Best = { Mob = Entry.Mob, Root = Entry.Root, Humanoid = Entry.Humanoid, Distance = Distance }
				end
			end
		end

		return Best
	end

	local VaultWords = { "vault chest" }

	local function FindVault()
		return FindRaidTarget(VaultWords)
	end

	local function StopVault()
		VaultRunning = false
		VaultComboStart = 0
		VaultDodgeUntil = 0
		VaultArrivedAt = 0
		VaultStatus = "Idle"

		if VaultLoop then
			pcall(function()
				task.cancel(VaultLoop)
			end)
			VaultLoop = nil
		end

		EndRunner("Vault")
	end

	local function SyncVault()
		if getgenv().Settings.AutoVaultChest.Enabled ~= true then
			StopVault()
			return
		end

		if game.PlaceId ~= BossSea2Place then
			StopVault()
			return
		end

		if not HasBossWeaponPicked() then
			getgenv().Settings.AutoVaultChest.Enabled = false
			SaveSetting()
			StopVault()
			RequireBossWeapon(VaultName, VaultKillToggle)
			return
		end

		if VaultRunning then
			return
		end

		SetToggleValue(Sea3Toggle, false)

		VaultRunning = true
		VaultArrivedAt = 0
		BeginRunner("Vault")

		VaultLoop = task.spawn(function()
			while VaultRunning do
				task.wait()

				if not IsCurrentInstance() then
					VaultRunning = false
					EndRunner("Vault")
					break
				end

				local Success = pcall(function()
					if not IsAlive() then
						LockCFrame = nil
						HoldCFrame = nil
						CancelTween()
						task.wait(1)
						return
					end

					local Root = GetRoot()
					if not Root then
						return
					end

					local Boss = FindVault()

					if not Boss then
						VaultComboStart = 0
						VaultDodgeUntil = 0
						IdleRunner("Vault")

						if VaultArrivedAt == 0 then
							VaultArrivedAt = tick()
						end

						VaultStatus =
							string.format("Waiting for the Vault Chest (%ds)", math.floor(tick() - VaultArrivedAt))

						task.wait(0.5)
						return
					end

					if not ClaimDrive("Vault", 2) then
						VaultStatus = "Another boss farm is moving, waiting"
						task.wait(0.3)
						return
					end

					do
						VaultArrivedAt = 0

						local Tool = EquipWeapon(BossWeaponName())
						local MobRoot = Boss.Root
						local Stand = GetAttackCFrame(MobRoot.CFrame)

						if (Root.Position - Stand.Position).Magnitude > 30 then
							VaultStatus = "Flying to " .. VaultName
							StartRender()
							LockCFrame = nil
							TravelTo(Stand, 30)
							return
						end

						VaultStatus = "Fighting " .. VaultName
						StartRender()
						CancelTween()
						LockCFrame = Stand

						if tick() - VaultLastAttack >= VaultAttackDelay then
							VaultLastAttack = tick()
							task.spawn(AttackWith, Tool, MobRoot)
						end

						return
					end
				end)

				if not Success then
					task.wait(0.25)
				end
			end
		end)
	end

	VaultKillToggle = VaultSection:Toggle({
		Title = "tr:VaultKill",
		Path = "AutoVaultChest.Enabled",
		Desc = "tr:VaultKillDesc",
		Value = getgenv().Settings.AutoVaultChest.Enabled,
		Icon = "check",
		Callback = function(Value)
			getgenv().Settings.AutoVaultChest.Enabled = Value
			SaveSetting()
			SyncVault()
		end,
	})

	RegisterHopTarget({
		Key = "Vault",
		Label = VaultName,
		Find = FindVault,
		Enabled = function()
			return getgenv().Settings.AutoVaultChest.Enabled == true
		end,
	})

	VenuzToggle.NeedsVault = function()
		return false
	end

	VenuzToggle.StopVault = function()
		getgenv().Settings.AutoVaultChest.Enabled = false
		SaveSetting()
		StopVault()
		SetToggleValue(VaultKillToggle, false)
	end

	task.spawn(function()
		while task.wait(1) do
			if not IsCurrentInstance() then
				break
			end
			RT.Push("Vault status", VaultParagraph, function()
				local Boss = FindVault()
				local Lines = {
					RT.Head(VaultName, RT.Red),
					RT.State(VaultStatus, VaultRunning),
				}

				if Boss then
					RT.Add(Lines, RT.Target("Vault Chest", Boss))
				end

				RT.Add(
					Lines,
					RT.Flag("Auto Kill", getgenv().Settings.AutoVaultChest.Enabled)
						.. RT.Sep
						.. RT.Flag("Priority", true)
						.. " "
						.. RT.Bold("#" .. PriorityOf("Vault"), RT.Muted)
				)

				return table.concat(Lines, "\n")
			end)
		end
	end)

	if getgenv().Settings.AutoVaultChest.Enabled then
		task.defer(SyncVault)
	end

	local RedEmperorName = "The Red Emperor"

	local ThroneSpot = Vector3.new(-2240.6, 1006.7, 2439.8)

	local RedEmperorSection = BossSea3Section:Section({ Title = "tr:RedEmperorSection", Icon = "crown", Opened = true })

	local RedEmperorStatus = "-"
	local RedEmperorParagraph = RT.Status(RedEmperorSection, "tr:RedEmperorStatus")

	local RedEmperorRunning = false
	local RedEmperorLoop = nil
	local RedEmperorLastAttack = 0
	local RedEmperorAttackDelay = 0.15
	local RedEmperorArrivedAt = 0
	local RedEmperorKillToggle, RedEmperorWaitToggle

	local function RedEmperorSpawnPart()
		return workspace:FindFirstChild("RedEmpSpawnPart")
	end

	local function RedEmperorLabel(Name)
		local Part = RedEmperorSpawnPart()
		local Spawn = Part and Part:FindFirstChild("Spawn")
		local Board = Spawn and Spawn:FindFirstChild("RedEmperorTimer")
		local Label = Board and Board:FindFirstChild(Name)

		if not Label then
			return nil
		end

		local Ok, Text = pcall(function()
			return Label.Text
		end)

		return (Ok and type(Text) == "string" and Text ~= "") and Text or nil
	end

	local function RedEmperorTimer()
		local Part = RedEmperorSpawnPart()

		if Part then
			local SpawnAt = Part:GetAttribute("RedEmpSpawnTime")
			local BaseAt = Part:GetAttribute("RedEmpBaseFinish")

			if type(SpawnAt) == "number" then
				local Left = math.max(0, SpawnAt - workspace:GetServerTimeNow())
				local Reduced = type(BaseAt) == "number" and math.floor(math.max(0, BaseAt - SpawnAt) / 60) or nil

				return Left, Reduced
			end
		end

		local Title = RedEmperorLabel("Title")
		if not Title then
			return nil, nil
		end

		local Reduced = tonumber(string.match(RedEmperorLabel("Sub") or "", "reduced by (%d+)") or "")

		if string.find(string.lower(Title), "descended", 1, true) then
			return 0, Reduced
		end

		local Hours, Minutes, Seconds = string.match(Title, "(%d+):(%d+):(%d+)")
		if not Hours then
			return nil, Reduced
		end

		return tonumber(Hours) * 3600 + tonumber(Minutes) * 60 + tonumber(Seconds), Reduced
	end

	local function RedEmperorSpot()
		local Part = RedEmperorSpawnPart()
		local Position = Part and ResolvePosition(Part)

		if Position then
			RememberBossSpot(RedEmperorName, Position)
			return Position
		end

		return BossSpotFor(RedEmperorName) or ThroneSpot
	end

	local RedEmperorWords = { "red emperor" }

	local function RedEmperorFromFolder()
		local Folder = workspace:FindFirstChild("Red Emperor")
		if not Folder then
			return nil
		end

		local Root = GetRoot()
		local Origin = Root and Root.Position
		local Best, BestDist = nil, math.huge

		for _, Model in ipairs(Folder:GetChildren()) do
			if Model:IsA("Model") then
				local Humanoid = Model:FindFirstChildOfClass("Humanoid")
				local MobRoot = Humanoid and (Humanoid.RootPart or Model:FindFirstChild("HumanoidRootPart"))

				if Humanoid and MobRoot and Humanoid.Health > 0 then
					local Distance = Origin and (MobRoot.Position - Origin).Magnitude or 0
					if Distance < BestDist then
						BestDist = Distance
						Best = { Mob = Model, Root = MobRoot, Humanoid = Humanoid, Distance = Distance }
					end
				end
			end
		end

		return Best
	end

	local function FindRedEmperor()
		return RedEmperorFromFolder() or FindRaidTarget(RedEmperorWords)
	end

	local function WantRedEmperorWait()
		return getgenv().Settings.AutoRedEmperor.WaitAtThrone == true
	end

	local function RedEmperorWaitBefore()
		return math.max(0, tonumber(getgenv().Settings.AutoRedEmperor.WaitBefore) or 120)
	end

	local function StopRedEmperor()
		RedEmperorRunning = false
		RedEmperorArrivedAt = 0
		RedEmperorStatus = "Idle"

		if RedEmperorLoop then
			pcall(function()
				task.cancel(RedEmperorLoop)
			end)
			RedEmperorLoop = nil
		end

		EndRunner("RedEmperor")
	end

	local function SyncRedEmperor()
		if getgenv().Settings.AutoRedEmperor.Enabled ~= true then
			StopRedEmperor()
			return
		end

		if game.PlaceId ~= BossSea3Place then
			StopRedEmperor()
			return
		end

		if not HasBossWeaponPicked() then
			getgenv().Settings.AutoRedEmperor.Enabled = false
			SaveSetting()
			StopRedEmperor()
			RequireBossWeapon(RedEmperorName, RedEmperorKillToggle)
			return
		end

		SetToggleValue(Sea3Toggle, false)

		if RedEmperorRunning then
			return
		end

		RedEmperorRunning = true
		RedEmperorArrivedAt = 0
		BeginRunner("RedEmperor")

		RedEmperorLoop = task.spawn(function()
			while RedEmperorRunning do
				task.wait()

				if not IsCurrentInstance() then
					RedEmperorRunning = false
					EndRunner("RedEmperor")
					break
				end

				local Success = pcall(function()
					if not IsAlive() then
						LockCFrame = nil
						HoldCFrame = nil
						CancelTween()
						task.wait(1)
						return
					end

					local Root = GetRoot()
					if not Root then
						return
					end

					local Boss = FindRedEmperor()

					if not Boss then
						local Left = RedEmperorTimer()
						local Spot = RedEmperorSpot()

						if WantRedEmperorWait() and Spot and Left and Left <= RedEmperorWaitBefore() then
							if not ClaimDrive("RedEmperor", 1) then
								RedEmperorStatus = "Another farm is moving, waiting"
								task.wait(0.3)
								return
							end

							StartRender()

							local WaitCFrame = CFrame.new(Spot + Vector3.new(0, 25, 0))

							if (Root.Position - WaitCFrame.Position).Magnitude > 25 then
								RedEmperorStatus = "Flying to the Throne Room (" .. RT.Clock(Left) .. " left)"
								LockCFrame = nil
								TravelTo(WaitCFrame, 25)
								return
							end

							RedEmperorStatus = "Waiting at the Throne Room (" .. RT.Clock(Left) .. " left)"
							CancelTween()
							LockCFrame = WaitCFrame
							task.wait(0.3)
							return
						end

						IdleRunner("RedEmperor")

						if RedEmperorArrivedAt == 0 then
							RedEmperorArrivedAt = tick()
						end

						if Left then
							RedEmperorStatus = "Boss spawns in " .. RT.Clock(Left)
						else
							RedEmperorStatus =
								string.format("Waiting for the boss (%ds)", math.floor(tick() - RedEmperorArrivedAt))
						end

						task.wait(0.5)
						return
					end

					if not ClaimDrive("RedEmperor", 2) then
						RedEmperorStatus = "Another boss farm is moving, waiting"
						task.wait(0.3)
						return
					end

					do
						RedEmperorArrivedAt = 0

						local Tool = EquipWeapon(BossWeaponName())
						local MobRoot = Boss.Root
						local Stand = GetAttackCFrame(MobRoot.CFrame)

						RememberBossSpot(RedEmperorName, MobRoot.Position)

						if (Root.Position - Stand.Position).Magnitude > 30 then
							RedEmperorStatus = "Flying to " .. RedEmperorName
							StartRender()
							LockCFrame = nil
							TravelTo(Stand, 30)
							return
						end

						RedEmperorStatus = "Fighting " .. RedEmperorName
						StartRender()
						CancelTween()
						LockCFrame = Stand

						if tick() - RedEmperorLastAttack >= RedEmperorAttackDelay then
							RedEmperorLastAttack = tick()
							task.spawn(AttackWith, Tool, MobRoot)
						end

						return
					end
				end)

				if not Success then
					task.wait(0.25)
				end
			end
		end)
	end

	RedEmperorWaitToggle = RedEmperorSection:Toggle({
		Title = "tr:RedEmperorWait",
		Path = "AutoRedEmperor.WaitAtThrone",
		Desc = "tr:RedEmperorWaitDesc",
		Value = getgenv().Settings.AutoRedEmperor.WaitAtThrone,
		Icon = "check",
		Callback = function(Value)
			getgenv().Settings.AutoRedEmperor.WaitAtThrone = Value
			SaveSetting()
		end,
	})

	RedEmperorSection:Slider({
		Title = "tr:RedEmperorBefore",
		Path = "AutoRedEmperor.WaitBefore",
		Desc = "tr:RedEmperorBeforeDesc",
		Value = {
			Min = 10,
			Max = 900,
			Default = getgenv().Settings.AutoRedEmperor.WaitBefore,
		},
		Callback = function(Value)
			getgenv().Settings.AutoRedEmperor.WaitBefore = tonumber(Value) or 120
			SaveSetting()
		end,
	})

	RedEmperorKillToggle = RedEmperorSection:Toggle({
		Title = "tr:RedEmperorKill",
		Path = "AutoRedEmperor.Enabled",
		Desc = "tr:RedEmperorKillDesc",
		Value = getgenv().Settings.AutoRedEmperor.Enabled,
		Icon = "check",
		Callback = function(Value)
			getgenv().Settings.AutoRedEmperor.Enabled = Value
			SaveSetting()
			SyncRedEmperor()
		end,
	})

	RegisterHopTarget({
		Key = "RedEmperor",
		Label = RedEmperorName,
		Find = FindRedEmperor,
		Enabled = function()
			return getgenv().Settings.AutoRedEmperor.Enabled == true
		end,
	})

	VenuzToggle.NeedsRedEmperor = function()
		return false
	end

	VenuzToggle.StopRedEmperor = function()
		getgenv().Settings.AutoRedEmperor.Enabled = false
		SaveSetting()
		StopRedEmperor()
		SetToggleValue(RedEmperorKillToggle, false)
	end

	task.spawn(function()
		while task.wait(1) do
			if not IsCurrentInstance() then
				break
			end
			RT.Push("Red Emperor status", RedEmperorParagraph, function()
				local Boss = FindRedEmperor()
				local Left, Reduced = RedEmperorTimer()
				local Lines = {
					RT.Head(RedEmperorName, RT.Red),
					RT.State(RedEmperorStatus, RedEmperorRunning),
					RT.Paint("Spawns in: ", RT.Muted) .. (Left and RT.Bold(
						RT.Clock(Left),
						Left <= RedEmperorWaitBefore() and RT.Green or RT.Amber
					) or RT.Bold("timer not loaded", RT.Red)) .. RT.Sep .. RT.Paint("Reduced by: ", RT.Muted) .. RT.Bold(
						(Reduced or 0) .. " / 120 min",
						(Reduced or 0) >= 120 and RT.Green or RT.Muted
					),
				}

				if Boss then
					RT.Add(Lines, RT.Target("Boss", Boss))
				end

				RT.Add(
					Lines,
					RT.Flag("Auto Kill", getgenv().Settings.AutoRedEmperor.Enabled)
						.. RT.Sep
						.. RT.Flag("Wait At Throne", WantRedEmperorWait())
						.. RT.Sep
						.. RT.Flag("Priority", true)
						.. " "
						.. RT.Bold("#" .. PriorityOf("RedEmperor"), RT.Muted)
				)

				return table.concat(Lines, "\n")
			end)
		end
	end)

	if getgenv().Settings.AutoRedEmperor.Enabled then
		task.defer(SyncRedEmperor)
	end

	local GhostName = "Ghost Ship"

	local GhostPoints = { Common = 1, Uncommon = 3, Rare = 5, Legendary = 15, Mythical = 20 }
	local GhostNeed = 20

	local GhostPowers = (function()
		local Ok, Config = pcall(function()
			return require(game:GetService("ReplicatedStorage"):WaitForChild("Config"):WaitForChild("Powers"))
		end)
		return (Ok and type(Config) == "table") and Config or {}
	end)()

	local GhostRarities = { "Common", "Uncommon", "Rare", "Legendary", "Mythical" }

	do
		local Setting = getgenv().Settings.AutoGhostShip

		if type(Setting.Rarities) ~= "table" then
			Setting.Rarities = {}
		end

		if type(Setting.Fruits) ~= "table" then
			Setting.Fruits = {}
		end

		if #NormalizeList(Setting.Rarities) == 0 and type(Setting.Fruits) == "table" then
			local Seen, List = {}, {}

			for _, Name in ipairs(NormalizeList(Setting.Fruits)) do
				local Entry = GhostPowers[Name]
				local Rarity = Entry and Entry.RareText

				if Rarity and GhostPoints[Rarity] and not Seen[Rarity] then
					Seen[Rarity] = true
					table.insert(List, Rarity)
				end
			end

			Setting.Rarities = List
		end
	end

	local GhostSection = BossSea3Section:Section({ Title = "tr:GhostSection", Icon = "ship", Opened = true })
	local GhostParagraph = RT.Status(GhostSection, "tr:GhostStatus")

	local GS = {
		Status = "-",
		Running = false,
		Loop = nil,
		LastAttack = 0,
		AttackDelay = 0.15,
		ArrivedAt = 0,
		LastFeed = 0,
		LastPull = 0,
		LastBuy = 0,
		Fed = 0,
		CalledAt = 0,
		ChestAt = 0,
		LastChest = 0,
		ChestSkip = nil,
		ChestFired = nil,
		ChestTools = 0,
		ShipSeen = false,
		DeadAt = 0,
		Pulled = nil,
		KillToggle = nil,
		SummonToggle = nil,
	}

	local function GhostCrate()
		return workspace:FindFirstChild("GhostShipCrate")
	end

	local function GhostWeather()
		local Logic = workspace:FindFirstChild("Logic")
		local MapData = Logic and Logic:FindFirstChild("MapData")
		local Value = MapData and MapData:FindFirstChild("Weather")
		local Text = Value and Value:IsA("StringValue") and Value.Value

		return (type(Text) == "string" and Text ~= "") and Text or nil
	end

	-- GhostShipClient rejects the offering with "The ship only accepts offerings during a
	-- storm..." unless the crate carries StormActive, which the server flips together with
	-- Workspace.Logic.MapData.Weather.
	local function GhostStorm()
		local Crate = GhostCrate()
		local Active = Crate and Crate:GetAttribute("StormActive")

		if type(Active) == "boolean" then
			return Active
		end

		local Weather = GhostWeather()
		return Weather ~= nil and string.find(string.lower(Weather), "storm", 1, true) ~= nil
	end

	local function GhostProgress()
		local Crate = GhostCrate()
		if not Crate then
			return nil
		end

		for _, Key in ipairs({ "Points", "Score", "Progress", "Count", "Sacrificed", "Offered" }) do
			local Attribute = Crate:GetAttribute(Key)
			if type(Attribute) == "number" then
				return Attribute
			end

			local Value = Crate:FindFirstChild(Key)
			if Value and Value:IsA("ValueBase") and type(Value.Value) == "number" then
				return Value.Value
			end
		end

		return nil
	end

	local function GhostRarityOf(Name)
		local Entry = GhostPowers[Name]
		local Rarity = Entry and Entry.RareText

		return (Rarity and GhostPoints[Rarity]) and Rarity or nil
	end

	local function GhostFruitPoints(Name)
		local Rarity = GhostRarityOf(Name)
		return Rarity and GhostPoints[Rarity] or 0
	end

	local function GhostRarityList()
		return NormalizeList(getgenv().Settings.AutoGhostShip.Rarities)
	end

	local function GhostFruitList()
		return NormalizeList(getgenv().Settings.AutoGhostShip.Fruits)
	end

	local function GhostWants(Name)
		local Rarity = GhostRarityOf(Name)

		if not Rarity then
			return false
		end

		local Picked = false
		for _, Wanted in ipairs(GhostFruitList()) do
			if Wanted == Name then
				Picked = true
				break
			end
		end

		if not Picked then
			return false
		end

		local Rarities = GhostRarityList()
		if #Rarities == 0 then
			return true
		end

		for _, Wanted in ipairs(Rarities) do
			if Wanted == Rarity then
				return true
			end
		end

		return false
	end

	local GhostSources = { "Fruit Bag", "In Backpack", "Buy Fruit" }

	local function GhostSource()
		local Value = getgenv().Settings.AutoGhostShip.Source

		if type(Value) == "table" then
			Value = NormalizeList(Value)[1]
		end

		return table.find(GhostSources, Value) and Value or GhostSources[1]
	end

	local function GhostUseBag()
		return GhostSource() == "Fruit Bag"
	end

	local function GhostUseBackpack()
		return GhostSource() == "In Backpack"
	end

	function GS.UseBuy()
		return GhostSource() == "Buy Fruit"
	end

	function GS.BuyWants(Name)
		local Rarity = GhostRarityOf(Name)

		if not Rarity then
			return false
		end

		for _, Wanted in ipairs(GhostRarityList()) do
			if Wanted == Rarity then
				return true
			end
		end

		return false
	end

	function GS.Allows(Name)
		if GS.UseBuy() then
			return GS.BuyWants(Name)
		end

		return GhostWants(Name)
	end

	function GS.HasPicks()
		if GS.UseBuy() then
			return #GhostRarityList() > 0
		end

		return #GhostFruitList() > 0
	end

	function GS.BuyPick(Need)
		local Stock = GetShopStock()

		if #Stock == 0 then
			return nil, nil, false
		end

		local Beli = GetBeli()
		local Best, BestPoints = nil, nil

		for _, Entry in ipairs(Stock) do
			if
				Entry.InStock
				and not Entry.Bought
				and GS.BuyWants(Entry.Name)
				and not (Beli and Entry.Price > 0 and Beli < Entry.Price)
			then
				local Points = GhostFruitPoints(Entry.Name)

				if Points > 0 then
					local Enough = Points >= Need
					local BestEnough = BestPoints ~= nil and BestPoints >= Need

					if
						not Best
						or (Enough and not BestEnough)
						or (Enough and BestEnough and Points < BestPoints)
						or (not Enough and not BestEnough and Points > BestPoints)
					then
						Best, BestPoints = Entry.Name, Points
					end
				end
			end
		end

		return Best, BestPoints, true
	end

	function GS.Buy(Name)
		local Remote = GetBuyRemote()

		if not Remote then
			return false
		end

		return (pcall(function()
			Remote:InvokeServer(Name)
		end))
	end

	function GS.WaitTool(Name, Timeout)
		local Deadline = tick() + (Timeout or 6)

		while tick() < Deadline do
			if not (GS.Running and IsAlive()) then
				return nil
			end

			local Character = GetCharacter()
			local Backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
			local Tool = (Character and Character:FindFirstChild(Name)) or (Backpack and Backpack:FindFirstChild(Name))

			if Tool and Tool:IsA("Tool") then
				return Tool
			end

			task.wait(0.2)
		end

		return nil
	end

	local function GhostCarried()
		local Loose = GhostUseBackpack() or GS.UseBuy()
		local Best, BestPoints = nil, -1

		for _, Container in ipairs({ GetCharacter(), LocalPlayer:FindFirstChildOfClass("Backpack") }) do
			if Container then
				for _, Tool in ipairs(Container:GetChildren()) do
					if
						Tool:IsA("Tool")
						and Tool:FindFirstChild("Droppable")
						and GS.Allows(Tool.Name)
						and (Loose or Tool.Name == GS.Pulled)
					then
						local Points = GhostFruitPoints(Tool.Name)
						if Points > BestPoints then
							Best, BestPoints = Tool, Points
						end
					end
				end
			end
		end

		return Best, math.max(BestPoints, 0)
	end

	local function GhostFromBag(Need)
		local Value = PlayerData:FindFirstChild("CollectedFruits")
		local Raw = Value and tostring(Value.Value) or ""
		local Best, BestPoints = nil, nil

		for Name in string.gmatch(Raw, "[^,]+") do
			Name = Name:match("^%s*(.-)%s*$")

			if GhostWants(Name) then
				local Points = GhostFruitPoints(Name)

				if Points > 0 then
					local Enough = Points >= Need
					local BestEnough = BestPoints ~= nil and BestPoints >= Need
					if
						not Best
						or (Enough and not BestEnough)
						or (Enough and BestEnough and Points < BestPoints)
						or (not Enough and not BestEnough and Points > BestPoints)
					then
						Best, BestPoints = Name, Points
					end
				end
			end
		end

		return Best, BestPoints
	end

	local function GhostPullFromBag(Name)
		local Gui = LocalPlayer:FindFirstChild("PlayerGui")
		local Inventory = Gui and Gui:FindFirstChild("Inventory")
		local Equip = Inventory and Inventory:FindFirstChild("Equip")

		if not (Equip and Equip:IsA("RemoteFunction")) then
			return false
		end

		return pcall(function()
			Equip:InvokeServer(Name)
		end)
	end

	local function GhostFindShip()
		local Found = FindRaidTarget({ "ghost ship", "phantom ship" })
		if Found then
			return Found
		end

		local Root = GetRoot()
		local Origin = Root and Root.Position

		for _, Model in ipairs(workspace:GetChildren()) do
			if Model:IsA("Model") and string.find(string.lower(Model.Name), "ghost ship", 1, true) then
				local Humanoid = Model:FindFirstChildOfClass("Humanoid")
				local MobRoot = Humanoid and (Humanoid.RootPart or Model:FindFirstChild("HumanoidRootPart"))

				if Humanoid and MobRoot and Humanoid.Health > 0 then
					return {
						Mob = Model,
						Root = MobRoot,
						Humanoid = Humanoid,
						Distance = Origin and (MobRoot.Position - Origin).Magnitude or 0,
					}
				end
			end
		end

		return nil
	end

	function GS.FindChest()
		local Zones = NPCZones or workspace:FindFirstChild("NPC Zones")
		local Monsters = Zones and Zones:FindFirstChild("Monsters")
		local List = Monsters and Monsters:FindFirstChild("NPCS")

		if not List then
			return nil
		end

		for _, Model in ipairs(List:GetChildren()) do
			if string.find(string.lower(Model.Name), "ghost ship", 1, true) then
				for _, Object in ipairs(Model:GetDescendants()) do
					if Object.Name == "Chest" then
						local Prompt = Object:IsA("ProximityPrompt") and Object
							or Object:FindFirstChildWhichIsA("ProximityPrompt", true)

						if Prompt then
							return Object, Prompt
						end
					end
				end
			end
		end

		return nil
	end

	function GS.CountTools()
		local Total = 0

		for _, Container in ipairs({ GetCharacter(), LocalPlayer:FindFirstChildOfClass("Backpack") }) do
			if Container then
				for _, Tool in ipairs(Container:GetChildren()) do
					if Tool:IsA("Tool") then
						Total = Total + 1
					end
				end
			end
		end

		return Total
	end

	function GS.ClaimChest(Root)
		local Chest, Prompt = GS.FindChest()

		if not (Chest and Prompt) then
			if GS.DeadAt > 0 and tick() - GS.DeadAt <= 20 then
				CancelTween()
				GS.Status = "Ghost Ship is down, waiting for the chest"
				task.wait(0.2)
				return true
			end

			GS.DeadAt = 0
			GS.ChestAt = 0
			return false
		end

		if GS.ChestSkip == Chest then
			return false
		end

		if not ClaimDrive("GhostShip", 2) then
			GS.Status = "Another boss farm is moving, waiting"
			task.wait(0.3)
			return true
		end

		if GS.ChestAt == 0 then
			GS.ChestAt = tick()
		end

		if tick() - GS.ChestAt > 30 then
			GS.ChestSkip = Chest
			GS.ChestAt = 0
			GS.Status = "Ghost Ship chest will not open, back to waiting"
			return false
		end

		local Spot = ResolvePosition(Chest)
		if not Spot then
			GS.Status = "Loading the Ghost Ship chest"
			task.wait(0.3)
			return true
		end

		StartRender()

		local Stand = CFrame.new(Spot + Vector3.new(0, 5, 0))

		if (Root.Position - Stand.Position).Magnitude > 12 then
			GS.Status = "Flying to the Ghost Ship chest"
			LockCFrame = nil
			TravelTo(Stand, 12)
			return true
		end

		CancelTween()
		LockCFrame = Stand

		if GS.ChestFired ~= Chest then
			GS.ChestFired = Chest
			GS.ChestTools = GS.CountTools()
			GS.LastChest = tick()
			GS.Status = "Opening the Ghost Ship chest"

			task.spawn(FirePrompt, Prompt)
			task.wait(0.2)
			return true
		end

		if GS.CountTools() > GS.ChestTools then
			GS.Status = "Ghost Ship loot is in the backpack"
			GS.ChestSkip = Chest
			GS.ChestAt = 0
			GS.DeadAt = 0
			return false
		end

		GS.Status = "Waiting for the Ghost Ship loot"
		task.wait(0.2)
		return true
	end

	local GhostCallLife = 900

	local function NoteGhostCall(Text)
		if type(Text) ~= "string" then
			return
		end

		local Lower = string.lower(Text)
		if string.find(Lower, "phantom ship", 1, true) or string.find(Lower, "from the abyss", 1, true) then
			GS.CalledAt = tick()
		end
	end

	local function GhostCallLive()
		return GS.CalledAt > 0 and (tick() - GS.CalledAt) <= GhostCallLife
	end

	task.spawn(function()
		pcall(function()
			game:GetService("TextChatService").MessageReceived:Connect(function(Message)
				NoteGhostCall(Message and Message.Text)
			end)
		end)

		pcall(function()
			local Events = game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents", 15)
			local Filtered = Events and Events:WaitForChild("OnMessageDoneFiltering", 15)

			if Filtered then
				Filtered.OnClientEvent:Connect(function(Data)
					NoteGhostCall(type(Data) == "table" and Data.Message or Data)
				end)
			end
		end)
	end)

	local function GhostOffer(Crate, Tool)
		local Handed = false

		-- What GhostShipClient itself calls once its storm check passes.
		local AddFruit = Crate:FindFirstChild("AddFruit")

		if AddFruit and AddFruit:IsA("RemoteFunction") then
			local Ok = pcall(function()
				AddFruit:InvokeServer(Tool)
			end)

			if Ok then
				return true
			end
		end

		-- Only the crate prompt. Firing every prompt underneath also pokes the summon NPC.
		local Holder = Crate:FindFirstChild("PP")
		local Prompt = Holder and Holder:FindFirstChild("CratePrompt")

		if Prompt and Prompt:IsA("ProximityPrompt") then
			task.spawn(FirePrompt, Prompt)
			Handed = true
		end

		for _, Name in ipairs({ "Interact", "Offer", "Sacrifice", "Deposit", "Give" }) do
			local Remote = Crate:FindFirstChild(Name, true)

			if Remote then
				pcall(function()
					if Remote:IsA("RemoteFunction") then
						Remote:InvokeServer(Tool)
					elseif Remote:IsA("RemoteEvent") then
						Remote:FireServer(Tool)
					end
				end)
				Handed = true
			end
		end

		if not Handed and typeof(firetouchinterest) == "function" then
			local Root = GetRoot()
			local Handle = Tool and Tool:FindFirstChild("Handle")

			for _, Part in ipairs(Crate:GetDescendants()) do
				if Part:IsA("BasePart") then
					for _, Mine in ipairs({ Root, Handle }) do
						if Mine then
							pcall(firetouchinterest, Mine, Part, 0)
							pcall(firetouchinterest, Mine, Part, 1)
						end
					end
				end
			end

			Handed = true
		end

		return Handed
	end

	local function WantGhostKill()
		return getgenv().Settings.AutoGhostShip.Enabled == true
	end

	local function WantGhostSummon()
		return getgenv().Settings.AutoGhostShip.Summon == true
	end

	local function StopGhost()
		GS.Running = false
		GS.ArrivedAt = 0
		GS.ChestAt = 0
		GS.ChestSkip = nil
		GS.ChestFired = nil
		GS.ShipSeen = false
		GS.DeadAt = 0
		GS.Pulled = nil
		GS.Status = "Idle"

		if GS.Loop then
			pcall(function()
				task.cancel(GS.Loop)
			end)
			GS.Loop = nil
		end

		EndRunner("GhostShip")
	end

	local function GhostFeedCrate(Crate, Root)
		local Left = GhostNeed - (GhostProgress() or GS.Fed)

		if Left <= 0 then
			GS.Status = "Altar full (20/20), waiting for the ship"
			return true
		end

		if not GhostStorm() then
			GS.Status = "Waiting for a storm, the altar takes nothing right now (weather: "
				.. (GhostWeather() or "unknown")
				.. ")"
			IdleRunner("GhostShip")
			task.wait(1)
			return true
		end

		local Spot = ResolvePosition(Crate)
		if not Spot then
			GS.Status = "Loading the altar"
			return true
		end

		StartRender()

		local Stand = CFrame.new(Spot + Vector3.new(0, 5, 0))

		if (Root.Position - Stand.Position).Magnitude > 10 then
			GS.Status = "Flying to the altar, " .. Left .. " points still needed"
			LockCFrame = nil
			TravelTo(Stand, 10)
			return true
		end

		CancelTween()
		LockCFrame = Stand

		local Tool = GhostCarried()

		if not Tool then
			if GS.UseBuy() then
				if tick() - GS.LastBuy >= 2 then
					local Name, _, Loaded = GS.BuyPick(Left)

					if Name then
						GS.LastBuy = tick()
						GS.Status = "Buying " .. Name .. " from the Fruit Dealer"

						if GS.Buy(Name) then
							GS.Pulled = Name

							if not GS.WaitTool(Name, 10) then
								GS.Pulled = nil
								GS.Status = Name .. " was paid for but never reached the backpack"
							end
						else
							GS.Status = "Cannot buy from the Fruit Dealer right now"
						end

						return true
					end

					GS.Status = (
						Loaded and "Nothing in the Fruit Dealer stock to buy"
						or "Fruit shop is not loaded yet"
					)
						.. ", "
						.. Left
						.. " points still needed"
				end
			elseif GhostUseBag() then
				if tick() - GS.LastPull >= 1.5 then
					local Name = GhostFromBag(Left)

					if Name then
						GS.LastPull = tick()
						GS.Pulled = Name
						GS.Status = "Taking " .. Name .. " from the Fruit Bag"
						GhostPullFromBag(Name)

						if not GS.WaitTool(Name, 6) then
							GS.Pulled = nil
							GS.Status = Name .. " never came out of the Fruit Bag"
						end

						return true
					end

					GS.Status = "No fruit of the picked rarities, " .. Left .. " points still needed"
				end
			else
				GS.Status = "No fruit of the picked rarities, " .. Left .. " points still needed"
			end

			IdleRunner("GhostShip")
			task.wait(1)
			return true
		end

		local Humanoid = GetHumanoid()
		if Tool.Parent ~= GetCharacter() and Humanoid then
			pcall(function()
				Humanoid:EquipTool(Tool)
			end)
			task.wait(0.25)
			return true
		end

		if tick() - GS.LastFeed >= 1.2 then
			GS.LastFeed = tick()
			local Points = GhostFruitPoints(Tool.Name)
			GS.Status = "Putting " .. Tool.Name .. " in the altar (+" .. Points .. " points)"

			if GhostOffer(Crate, Tool) then
				GS.Pulled = nil

				if GhostProgress() == nil then
					GS.Fed = GS.Fed + Points
				end
			else
				GS.Status = "Cannot put fruit in the altar"
			end
		end

		task.wait(0.4)
		return true
	end

	local function SyncGhost()
		if not (WantGhostKill() or WantGhostSummon()) then
			StopGhost()
			return
		end

		if not HasBossWeaponPicked() then
			getgenv().Settings.AutoGhostShip.Enabled = false
			getgenv().Settings.AutoGhostShip.Summon = false
			SaveSetting()
			StopGhost()
			RequireBossWeapon(GhostName, GS.KillToggle, GS.SummonToggle)
			return
		end

		if WantGhostSummon() and not GS.HasPicks() then
			getgenv().Settings.AutoGhostShip.Summon = false
			SaveSetting()
			SetToggleValue(GS.SummonToggle, false)
			WindUI:Notify({
				Title = GhostName,
				Content = ConfigThai
						and ConfigThai()
						and (GS.UseBuy() and "โหมด Buy Fruit ต้องเลือกระดับผลที่จะซื้อก่อน อย่างน้อย 1 ระดับ" or "เลือกผลที่ยอมให้ใช้เรียกเรือก่อน อย่างน้อย 1 ชนิด")
					or (
						GS.UseBuy() and "Pick at least one rarity to buy first."
						or "Pick at least one fruit it may spend first."
					),
				Duration = 6,
			})

			if not WantGhostKill() then
				StopGhost()
				return
			end
		end

		if GS.Running then
			return
		end

		GS.Running = true
		GS.ArrivedAt = 0
		GS.Fed = 0
		BeginRunner("GhostShip")

		GS.Loop = task.spawn(function()
			while GS.Running do
				task.wait()

				if not IsCurrentInstance() then
					GS.Running = false
					EndRunner("GhostShip")
					break
				end

				local Success = pcall(function()
					if not IsAlive() then
						GS.Pulled = nil
						LockCFrame = nil
						HoldCFrame = nil
						CancelTween()
						task.wait(1)
						return
					end

					local Root = GetRoot()
					if not Root then
						return
					end

					local Ship = GhostFindShip()

					if Ship then
						GS.Fed = 0
						GS.ChestAt = 0
						GS.ChestSkip = nil
						GS.ChestFired = nil
						GS.ShipSeen = true
						GS.DeadAt = 0

						if not WantGhostKill() then
							GS.Status = "Ghost Ship is up, turn on Auto Kill to fight it"
							IdleRunner("GhostShip")
							task.wait(0.5)
							return
						end

						if not ClaimDrive("GhostShip", 2) then
							GS.Status = "Another boss farm is moving, waiting"
							task.wait(0.3)
							return
						end

						GS.ArrivedAt = 0

						local Tool = EquipWeapon(BossWeaponName())
						local MobRoot = Ship.Root
						local Stand = GetAttackCFrame(MobRoot.CFrame)

						RememberBossSpot(GhostName, MobRoot.Position)

						if (Root.Position - Stand.Position).Magnitude > 30 then
							GS.Status = "Flying to " .. GhostName
							StartRender()
							LockCFrame = nil
							TravelTo(Stand, 30)
							return
						end

						GS.Status = "Fighting " .. GhostName
						StartRender()
						CancelTween()
						LockCFrame = Stand

						if tick() - GS.LastAttack >= GS.AttackDelay then
							GS.LastAttack = tick()
							task.spawn(AttackWith, Tool, MobRoot)
						end

						return
					end

					if GS.ShipSeen then
						GS.ShipSeen = false
						GS.DeadAt = tick()
						GS.ChestAt = 0
						GS.ChestFired = nil
					end

					if GS.ClaimChest(Root) then
						GS.Fed = 0
						return
					end

					local Crate = WantGhostSummon() and GhostCrate() or nil

					if Crate then
						if not ClaimDrive("GhostShip", 1) then
							GS.Status = "Another farm is moving, waiting"
							task.wait(0.3)
							return
						end

						GhostFeedCrate(Crate, Root)
						return
					end

					GS.Fed = 0
					IdleRunner("GhostShip")

					if GS.ArrivedAt == 0 then
						GS.ArrivedAt = tick()
					end

					if GhostCallLive() then
						GS.Status = "Someone called the ship, looking for it"
					elseif WantGhostSummon() then
						GS.Status = "Waiting for rain and the altar to show up"
					else
						GS.Status = string.format("Waiting for the ship (%ds)", math.floor(tick() - GS.ArrivedAt))
					end

					task.wait(0.5)
				end)

				if not Success then
					task.wait(0.25)
				end
			end
		end)
	end

	GS.KillToggle = GhostSection:Toggle({
		Title = "tr:GhostKill",
		Path = "AutoGhostShip.Enabled",
		Desc = "tr:GhostKillDesc",
		Value = getgenv().Settings.AutoGhostShip.Enabled,
		Icon = "check",
		Callback = function(Value)
			getgenv().Settings.AutoGhostShip.Enabled = Value
			SaveSetting()
			SyncGhost()
		end,
	})

	GS.SummonToggle = GhostSection:Toggle({
		Title = "tr:GhostSummon",
		Path = "AutoGhostShip.Summon",
		Desc = "tr:GhostSummonDesc",
		Value = getgenv().Settings.AutoGhostShip.Summon,
		Icon = "check",
		Callback = function(Value)
			getgenv().Settings.AutoGhostShip.Summon = Value
			SaveSetting()
			SyncGhost()
		end,
	})

	GhostSection:Dropdown({
		Title = "tr:GhostSource",
		Path = "AutoGhostShip.Source",
		Desc = "tr:GhostSourceDesc",
		Multi = false,
		AllowNone = false,
		Values = GhostSources,
		Value = GhostSource(),
		Callback = function(Value)
			getgenv().Settings.AutoGhostShip.Source = table.find(GhostSources, Value) and Value or GhostSources[1]
			GS.Pulled = nil
			SaveSetting()
			SyncGhost()
		end,
	})

	GhostSection:Dropdown({
		Title = "tr:GhostFruits",
		Path = "AutoGhostShip.Fruits",
		Desc = "tr:GhostFruitsDesc",
		Multi = true,
		AllowNone = true,
		Values = FruitNames,
		Value = getgenv().Settings.AutoGhostShip.Fruits,
		Callback = function(Value)
			getgenv().Settings.AutoGhostShip.Fruits = NormalizeList(Value)
			SaveSetting()
			SyncGhost()
		end,
	})

	GhostSection:Dropdown({
		Title = "tr:GhostRarity",
		Path = "AutoGhostShip.Rarities",
		Desc = "tr:GhostRarityDesc",
		Multi = true,
		AllowNone = true,
		Values = GhostRarities,
		Value = getgenv().Settings.AutoGhostShip.Rarities,
		Callback = function(Value)
			getgenv().Settings.AutoGhostShip.Rarities = NormalizeList(Value)
			SaveSetting()
			SyncGhost()
		end,
	})

	RegisterHopTarget({
		Key = "GhostShip",
		Label = GhostName,
		Find = function()
			return GhostFindShip()
				or (GS.FindChest() and GS or nil)
				or (GhostCallLive() and GS or nil)
				or (GhostCrate() and GS or nil)
		end,
		Enabled = function()
			return WantGhostKill() or WantGhostSummon()
		end,
	})

	VenuzToggle.NeedsGhostShip = function()
		return WantGhostSummon()
	end

	VenuzToggle.StopGhostShip = function()
		getgenv().Settings.AutoGhostShip.Enabled = false
		getgenv().Settings.AutoGhostShip.Summon = false
		SaveSetting()
		StopGhost()
		SetToggleValue(GS.KillToggle, false)
		SetToggleValue(GS.SummonToggle, false)
	end

	task.spawn(function()
		while task.wait(1) do
			if not IsCurrentInstance() then
				break
			end
			RT.Push("Ghost Ship status", GhostParagraph, function()
				local Ship = GhostFindShip()
				local Crate = GhostCrate()
				local Points = GhostProgress() or GS.Fed
				local Lines = {
					RT.Head(GhostName, RT.Red),
					RT.State(GS.Status, GS.Running),
					RT.Flag("Altar open", Crate ~= nil) .. RT.Sep .. RT.Flag("Ship called", GhostCallLive()),
				}

				if Crate then
					local Storm = GhostStorm()

					RT.Add(
						Lines,
						RT.Paint("Points: ", RT.Muted)
							.. RT.Bold(Points .. "/" .. GhostNeed, Points >= GhostNeed and RT.Green or RT.Amber)
							.. RT.Sep
							.. RT.Field("Fruit from", GhostSource())
					)

					RT.Add(
						Lines,
						RT.Paint("Weather: ", RT.Muted)
							.. RT.Bold(GhostWeather() or "unknown", Storm and RT.Green or RT.Muted)
							.. RT.Sep
							.. RT.Flag("Altar accepting fruit", Storm)
					)
				end

				if Ship then
					RT.Add(Lines, RT.Target("Ship", Ship))
				end

				RT.Add(
					Lines,
					RT.Flag("Auto Kill", WantGhostKill())
						.. RT.Sep
						.. RT.Flag("Auto Summon", WantGhostSummon())
						.. RT.Sep
						.. RT.Flag("Priority", true)
						.. " "
						.. RT.Bold("#" .. PriorityOf("GhostShip"), RT.Muted)
				)

				if WantGhostSummon() and not GS.HasPicks() then
					RT.Add(
						Lines,
						RT.Paint(
							GS.UseBuy() and "Pick a rarity below before the summon can buy anything"
								or "Pick the fruits it may spend below before the summon can run",
							RT.Amber
						)
					)
				end

				return table.concat(Lines, "\n")
			end)
		end
	end)

	if getgenv().Settings.AutoGhostShip.Enabled or getgenv().Settings.AutoGhostShip.Summon then
		task.defer(SyncGhost)
	end

	;
	(function()
		local CthulhuName = "Cthulhu"
		local CthulhuWords = { "cthulhu" }
		local CthulhuShard = "Prismatic Shard"
		local CthulhuPool = Vector3.new(-3970.5, 2.5, 6895.7)
		local CthulhuForgeSpot = Vector3.new(-5340.8, 514, -1453.1)
		local CthulhuWatchSwap = 25
		local CthulhuWaterLift = 6

		local CthulhuCost = {
			{ Key = "PhantomLantern", Label = "Phantom Lantern" },
			{ Key = "DragonHeart", Label = "Dragon Heart" },
			{ Key = "SeabeastHeart", Label = "Seabeast Heart" },
			{ Key = "RaijinsCore", Label = "Raijin's Core" },
			{ Key = "SaturnsRing", Label = "Saturn's Ring" },
		}

		local CthulhuSection = BossSea3Section:Section({ Title = "tr:CthulhuSection", Icon = "shell", Opened = true })
		local CthulhuParagraph = RT.Status(CthulhuSection, "tr:CthulhuStatus")

		local CT = {
			Status = "-",
			Running = false,
			Loop = nil,
			LastAttack = 0,
			AttackDelay = 0.15,
			ArrivedAt = 0,
			LastCraft = 0,
			LastCall = 0,
			BossSeen = false,
			CalledAt = 0,
			Anchored = false,
			WantAnchor = false,
			KillToggle = nil,
			SummonToggle = nil,
		}

		local function CthulhuCount(Name)
			local Data = LocalPlayer:FindFirstChild("PlayerData")
			local Value = Data and Data:FindFirstChild(Name)

			return (Value and type(Value.Value) == "number") and Value.Value or 0
		end

		local function CthulhuShards()
			return CthulhuCount("PrismaticShards")
		end

		local function CthulhuMissing()
			local Missing = {}

			for _, Item in ipairs(CthulhuCost) do
				if CthulhuCount(Item.Key) < 1 then
					table.insert(Missing, Item.Label)
				end
			end

			return Missing
		end

		local function CthulhuStorm()
			local Logic = workspace:FindFirstChild("Logic")
			local MapData = Logic and Logic:FindFirstChild("MapData")
			local Weather = MapData and MapData:FindFirstChild("Weather")

			if not Weather then
				return false
			end

			return string.find(string.lower(tostring(Weather.Value)), "storm", 1, true) ~= nil
		end

		-- The real summon spot is workspace.CthulhuWhirpool, spelled without the second "l" by the
		-- game, and it only exists while the storm is running. The sea also permanently holds an
		-- invisible WhirlpoolCloud marker sitting right on the water line, which is what the old
		-- name-only match kept flying out to on a clear day before drowning on something it could
		-- never trigger. Match both spellings, skip the cloud and the Cloud Watcher npc, and only
		-- accept a model that actually carries the summon remote or a prompt.
		local CthulhuPoolWords = { "whirpool", "whirlpool" }

		local function CthulhuShardRemote(Object)
			local Remote = Object:FindFirstChild("AddShard")

			return (Remote and Remote:IsA("RemoteFunction")) and Remote or nil
		end

		local function CthulhuInteractive(Object)
			if CthulhuShardRemote(Object) then
				return true
			end

			for _, Child in ipairs(Object:GetDescendants()) do
				if Child:IsA("ProximityPrompt") or Child:IsA("ClickDetector") then
					return true
				end
			end

			return false
		end

		local function CthulhuPoolModel()
			for _, Object in ipairs(workspace:GetChildren()) do
				local Lower = string.lower(Object.Name)

				if not (string.find(Lower, "watcher", 1, true) or string.find(Lower, "cloud", 1, true)) then
					for _, Word in ipairs(CthulhuPoolWords) do
						if string.find(Lower, Word, 1, true) then
							if CthulhuInteractive(Object) then
								return Object
							end

							break
						end
					end
				end
			end

			return nil
		end

		local function CthulhuWaterTop(Spot)
			local Logic = workspace:FindFirstChild("Logic")
			local Water = Logic and Logic:FindFirstChild("Water")

			if not Water then
				return nil
			end

			local Top = nil

			local function Check(Part)
				if not (Part and Part:IsA("BasePart")) then
					return
				end

				local Local = Part.CFrame:Inverse() * Spot
				local Half = Part.Size * 0.5

				if math.abs(Local.X) <= Half.X and math.abs(Local.Z) <= Half.Z then
					local Surface = Part.Position.Y + Half.Y

					if not Top or Surface > Top then
						Top = Surface
					end
				end
			end

			Check(Water)

			for _, Part in ipairs(Water:GetDescendants()) do
				Check(Part)
			end

			return Top
		end

		-- Every stand spot out here sits over open water, so lift it clear of the surface. Losing the
		-- render lock then drops the character onto air instead of into the sea.
		local function CthulhuSafeCFrame(Spot, Height)
			local Wanted = Spot.Y + (Height or 8)
			local Top = CthulhuWaterTop(Spot)

			if Top and Wanted < Top + CthulhuWaterLift then
				Wanted = Top + CthulhuWaterLift
			end

			return CFrame.new(Spot.X, Wanted, Spot.Z)
		end

		local function CthulhuOverWater(Root)
			return CthulhuWaterTop(Root.Position) ~= nil
		end

		-- Cthulhu swims between four nodes about 45 studs under the sea and only replicates once the
		-- character is near one, so Auto Kill rotates through them while it waits.
		local function CthulhuWatchSpot()
			local Logic = workspace:FindFirstChild("Logic")
			local Folder = Logic and Logic:FindFirstChild("CthulhuNodes")
			local Spots = {}

			if Folder then
				for _, Part in ipairs(Folder:GetChildren()) do
					if Part:IsA("BasePart") then
						table.insert(Spots, Part.Position)
					end
				end
			end

			if #Spots == 0 then
				return CthulhuPool
			end

			table.sort(Spots, function(Left, Right)
				if Left.X ~= Right.X then
					return Left.X < Right.X
				end

				return Left.Z < Right.Z
			end)

			return Spots[(math.floor(tick() / CthulhuWatchSwap) % #Spots) + 1]
		end

		-- Anchoring the root is what actually keeps the character out of the water while the runner is
		-- parked with nothing to do. Only ever undo an anchor this module set itself.
		local function CthulhuAnchor(On)
			local Root = GetRoot()

			if not Root then
				CT.Anchored = false
				return
			end

			if On then
				if not Root.Anchored then
					pcall(function()
						Root.Anchored = true
					end)
				end

				CT.Anchored = true
				return
			end

			if CT.Anchored then
				pcall(function()
					Root.Anchored = false
				end)
			end

			CT.Anchored = false
		end

		local function FindCthulhu()
			return FindRaidTarget(CthulhuWords)
		end

		-- Cthulhu swims 45 studs under open sea and never turns up next to a farm, so there is nothing
		-- to sweep for. The server shouts when it wakes, exactly like the Saturn Egg Island call, so
		-- the runner waits on that line and only then flies out.
		local CthulhuCallLife = 1800
		local CthulhuCallWords = {
			"something ancient has awakened beneath the sea",
			"awakened beneath the sea",
		}

		local function NoteCthulhuCall(Text)
			if type(Text) ~= "string" then
				return
			end

			local Lower = string.lower(Text)

			for _, Word in ipairs(CthulhuCallWords) do
				if string.find(Lower, Word, 1, true) then
					CT.CalledAt = tick()
					return
				end
			end
		end

		local function CthulhuCallLive()
			return CT.CalledAt > 0 and (tick() - CT.CalledAt) <= CthulhuCallLife
		end

		task.spawn(function()
			pcall(function()
				game:GetService("TextChatService").MessageReceived:Connect(function(Message)
					NoteCthulhuCall(Message and Message.Text)
				end)
			end)

			pcall(function()
				local Events = game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents", 15)
				local Filtered = Events and Events:WaitForChild("OnMessageDoneFiltering", 15)

				if Filtered then
					Filtered.OnClientEvent:Connect(function(Data)
						NoteCthulhuCall(type(Data) == "table" and Data.Message or Data)
					end)
				end
			end)

			-- The red [SERVER] line is pushed straight down ClientEvents.SystemMessage on this game,
			-- so read that as well instead of relying on it reaching the chat window.
			pcall(function()
				local Remote = ClientEvents and ClientEvents:FindFirstChild("SystemMessage")

				if Remote and Remote:IsA("RemoteEvent") then
					Remote.OnClientEvent:Connect(function(...)
						for _, Value in ipairs({ ... }) do
							if type(Value) == "string" then
								NoteCthulhuCall(Value)
							elseif type(Value) == "table" then
								NoteCthulhuCall(Value.Message or Value.Text)
							end
						end
					end)
				end
			end)
		end)

		local function CthulhuForge()
			local Folder = workspace:FindFirstChild("Npc_Workspace")
			local Group = Folder and Folder:FindFirstChild("EliteBlacksmith")

			if not Group then
				return nil
			end

			local Npc = Group:FindFirstChild("Doran the Forge")

			if Npc and Npc:FindFirstChild("Interact") then
				return Npc
			end

			for _, Model in ipairs(Group:GetChildren()) do
				if Model:FindFirstChild("Interact") then
					return Model
				end
			end

			return nil
		end

		-- WhirlpoolClient only uses the prompt to open a confirmation dialog and then calls
		-- AddShard:InvokeServer() itself, so firing the prompt alone leaves the runner sitting in
		-- front of an unanswered text box. Go straight to the remote and keep the prompt, click and
		-- touch passes as a fallback for the day the model changes.
		local function CthulhuTrigger(Object, Root)
			local Shard = CthulhuShardRemote(Object)

			if Shard then
				local Ok = pcall(function()
					return Shard:InvokeServer()
				end)

				if Ok then
					return true
				end
			end

			local Fired = false

			for _, Child in ipairs(Object:GetDescendants()) do
				if Child:IsA("ProximityPrompt") then
					if FirePrompt(Child) then
						Fired = true
					end
				elseif Child:IsA("ClickDetector") and typeof(fireclickdetector) == "function" then
					if pcall(fireclickdetector, Child) then
						Fired = true
					end
				end
			end

			if not Fired and Root and typeof(firetouchinterest) == "function" then
				local Parts = {}

				if Object:IsA("BasePart") then
					table.insert(Parts, Object)
				end

				for _, Part in ipairs(Object:GetDescendants()) do
					if Part:IsA("BasePart") then
						table.insert(Parts, Part)
					end
				end

				for _, Part in ipairs(Parts) do
					pcall(firetouchinterest, Root, Part, 0)
					pcall(firetouchinterest, Root, Part, 1)
				end

				Fired = #Parts > 0
			end

			return Fired
		end

		local function CthulhuCraftShard(Root)
			if getgenv().Settings.AutoCthulhu.Craft ~= true then
				CT.Status = "No " .. CthulhuShard .. ", Auto Craft is off"
				CT.WantAnchor = CthulhuOverWater(Root)
				IdleRunner("Cthulhu")
				task.wait(1)
				return
			end

			local Missing = CthulhuMissing()

			if #Missing > 0 then
				CT.Status = "Missing for the shard: " .. table.concat(Missing, ", ")
				CT.WantAnchor = CthulhuOverWater(Root)
				IdleRunner("Cthulhu")
				task.wait(2)
				return
			end

			local Npc = CthulhuForge()
			local Spot = (Npc and ResolvePosition(Npc)) or CthulhuForgeSpot
			local Stand = CFrame.new(Spot + Vector3.new(0, 5, 0))

			if (Root.Position - Stand.Position).Magnitude > 12 then
				CT.Status = "Flying to Doran the Forge"
				StartRender()
				LockCFrame = nil
				TravelTo(Stand, 12)
				return
			end

			CancelTween()
			LockCFrame = Stand

			if not (Npc and Npc:FindFirstChild("Interact")) then
				CT.Status = "Doran the Forge has not streamed in"
				task.wait(0.5)
				return
			end

			if tick() - CT.LastCraft < 2 then
				return
			end

			CT.LastCraft = tick()
			CT.Status = "Forging the " .. CthulhuShard

			local Ok, Result = pcall(function()
				return Npc.Interact:InvokeServer(CthulhuShard)
			end)

			if not (Ok and Result) then
				CT.Status = "Doran would not forge the shard, trying again"
			end

			task.wait(1)
		end

		local function CthulhuCallBoss(Root)
			local Pool = CthulhuPoolModel()

			-- Nothing out here is worth a trip before the storm. The whirlpool model is not even in
			-- the workspace yet and the materials keep, so stay wherever the other farms are, drop
			-- the anchor and let them keep the character. The forge run and the whirlpool run then
			-- happen back to back inside the same storm.
			if not (Pool or CthulhuStorm()) then
				CT.Status = "Waiting for the storm (every 2h 35m)"
				CT.WantAnchor = false
				IdleRunner("Cthulhu")
				task.wait(1)
				return
			end

			if CthulhuShards() < 1 then
				CthulhuCraftShard(Root)
				return
			end

			if not Pool then
				CT.Status = "Storm is up, waiting for the whirlpool"
				CT.WantAnchor = CthulhuOverWater(Root)
				IdleRunner("Cthulhu")
				task.wait(1)
				return
			end

			local Spot = ResolvePosition(Pool) or CthulhuPool
			local Stand = CthulhuSafeCFrame(Spot, 8)

			if (Root.Position - Stand.Position).Magnitude > 12 then
				CT.Status = "Taking the " .. CthulhuShard .. " to the whirlpool"
				StartRender()
				LockCFrame = nil
				TravelTo(Stand, 12)
				return
			end

			StartRender()
			CancelTween()
			LockCFrame = Stand
			CT.WantAnchor = true

			if tick() - CT.LastCall < 3 then
				return
			end

			CT.LastCall = tick()
			CT.Status = "Calling " .. CthulhuName .. " at the whirlpool"

			if not CthulhuTrigger(Pool, Root) then
				CT.Status = "Nothing on the whirlpool to interact with"
			end

			task.wait(2)
		end

		local function WantCthulhuKill()
			return getgenv().Settings.AutoCthulhu.Enabled == true
		end

		local function WantCthulhuSummon()
			return getgenv().Settings.AutoCthulhu.Summon == true
		end

		local function StopCthulhu()
			CT.Running = false
			CT.ArrivedAt = 0
			CT.BossSeen = false
			CT.WantAnchor = false
			CT.Status = "Idle"

			CthulhuAnchor(false)

			if CT.Loop then
				pcall(function()
					task.cancel(CT.Loop)
				end)
				CT.Loop = nil
			end

			EndRunner("Cthulhu")
		end

		local function SyncCthulhu()
			if not (WantCthulhuKill() or WantCthulhuSummon()) then
				StopCthulhu()
				return
			end

			if not HasBossWeaponPicked() then
				getgenv().Settings.AutoCthulhu.Enabled = false
				getgenv().Settings.AutoCthulhu.Summon = false
				SaveSetting()
				StopCthulhu()
				RequireBossWeapon(CthulhuName, CT.KillToggle, CT.SummonToggle)
				return
			end

			if CT.Running then
				return
			end

			CT.Running = true
			CT.ArrivedAt = 0
			BeginRunner("Cthulhu")

			CT.Loop = task.spawn(function()
				while CT.Running do
					task.wait()

					if not IsCurrentInstance() then
						CT.Running = false
						CthulhuAnchor(false)
						EndRunner("Cthulhu")
						break
					end

					CT.WantAnchor = false

					local Success = pcall(function()
						if not IsAlive() then
							LockCFrame = nil
							HoldCFrame = nil
							CancelTween()
							CthulhuAnchor(false)
							task.wait(1)
							return
						end

						local Root = GetRoot()
						if not Root then
							return
						end

						local Boss = FindCthulhu()

						if Boss then
							CT.BossSeen = true
							CT.ArrivedAt = 0

							if not WantCthulhuKill() then
								CT.Status = CthulhuName .. " is up, turn on Auto Kill to fight it"
								IdleRunner("Cthulhu")
								task.wait(0.5)
								return
							end

							if not ClaimDrive("Cthulhu", 2) then
								CT.Status = "Another boss farm is moving, waiting"
								task.wait(0.3)
								return
							end

							local Tool = EquipWeapon(BossWeaponName())
							local MobRoot = Boss.Root
							local Stand = GetAttackCFrame(MobRoot.CFrame)

							RememberBossSpot(CthulhuName, MobRoot.Position)

							if (Root.Position - Stand.Position).Magnitude > 30 then
								CT.Status = "Flying to " .. CthulhuName
								StartRender()
								LockCFrame = nil
								TravelTo(Stand, 30)
								return
							end

							CT.Status = "Fighting " .. CthulhuName
							StartRender()
							CancelTween()
							LockCFrame = Stand

							if tick() - CT.LastAttack >= CT.AttackDelay then
								CT.LastAttack = tick()
								task.spawn(AttackWith, Tool, MobRoot)
							end

							return
						end

						if CT.BossSeen then
							CT.BossSeen = false
							CT.CalledAt = 0
						end

						if WantCthulhuSummon() then
							if not ClaimDrive("Cthulhu", 1) then
								CT.Status = "Another farm is moving, waiting"
								task.wait(0.3)
								return
							end

							CthulhuCallBoss(Root)
							return
						end

						-- Nothing to check nearby: Cthulhu spawns far out at sea and only replicates
						-- once the character is over its nodes. Wait on the server call, then go.
						if WantCthulhuKill() then
							if not CthulhuCallLive() then
								CT.ArrivedAt = 0
								CT.Status = "Waiting for the call from the deep"
								IdleRunner("Cthulhu")
								task.wait(1)
								return
							end

							if not ClaimDrive("Cthulhu", 1) then
								CT.Status = "Another farm is moving, waiting"
								task.wait(0.3)
								return
							end

							local Wait = CthulhuSafeCFrame(CthulhuWatchSpot(), BossWaitHeight)

							StartRender()

							if (Root.Position - Wait.Position).Magnitude > 30 then
								CT.Status = CthulhuName .. " was called, flying out to the sea"
								LockCFrame = nil
								TravelTo(Wait, 30)
								return
							end

							CancelTween()
							LockCFrame = Wait
							CT.WantAnchor = true

							if CT.ArrivedAt == 0 then
								CT.ArrivedAt = tick()
							end

							CT.Status =
								string.format("Watching for %s (%ds)", CthulhuName, math.floor(tick() - CT.ArrivedAt))
							task.wait(0.3)
							return
						end

						IdleRunner("Cthulhu")

						if CT.ArrivedAt == 0 then
							CT.ArrivedAt = tick()
						end

						CT.Status = string.format("Waiting for %s (%ds)", CthulhuName, math.floor(tick() - CT.ArrivedAt))
						task.wait(0.5)
					end)

					local Owner = VenuzRun.Owner

					if Owner and Owner ~= "Cthulhu" and tick() <= VenuzRun.Until then
						CT.WantAnchor = false
					end

					CthulhuAnchor(CT.WantAnchor)

					if not Success then
						task.wait(0.25)
					end
				end
			end)
		end

		CT.KillToggle = CthulhuSection:Toggle({
			Title = "tr:CthulhuKill",
			Path = "AutoCthulhu.Enabled",
			Desc = "tr:CthulhuKillDesc",
			Value = getgenv().Settings.AutoCthulhu.Enabled,
			Icon = "check",
			Callback = function(Value)
				getgenv().Settings.AutoCthulhu.Enabled = Value
				SaveSetting()
				SyncCthulhu()
			end,
		})

		CT.SummonToggle = CthulhuSection:Toggle({
			Title = "tr:CthulhuSummon",
			Path = "AutoCthulhu.Summon",
			Desc = "tr:CthulhuSummonDesc",
			Value = getgenv().Settings.AutoCthulhu.Summon,
			Icon = "check",
			Callback = function(Value)
				getgenv().Settings.AutoCthulhu.Summon = Value
				SaveSetting()
				SyncCthulhu()
			end,
		})

		CthulhuSection:Toggle({
			Title = "tr:CthulhuCraft",
			Path = "AutoCthulhu.Craft",
			Desc = "tr:CthulhuCraftDesc",
			Value = getgenv().Settings.AutoCthulhu.Craft,
			Icon = "check",
			Callback = function(Value)
				getgenv().Settings.AutoCthulhu.Craft = Value
				SaveSetting()
			end,
		})

		RegisterHopTarget({
			Key = "Cthulhu",
			Label = CthulhuName,
			Find = function()
				return FindCthulhu()
			end,
			Enabled = function()
				return WantCthulhuKill() or WantCthulhuSummon()
			end,
		})

		VenuzToggle.NeedsCthulhu = function()
			return WantCthulhuSummon()
		end

		VenuzToggle.StopCthulhu = function()
			getgenv().Settings.AutoCthulhu.Enabled = false
			getgenv().Settings.AutoCthulhu.Summon = false
			SaveSetting()
			StopCthulhu()
			SetToggleValue(CT.KillToggle, false)
			SetToggleValue(CT.SummonToggle, false)
		end

		task.spawn(function()
			while task.wait(1) do
				if not IsCurrentInstance() then
					break
				end

				RT.Push("Cthulhu status", CthulhuParagraph, function()
					local Boss = FindCthulhu()
					local Pool = CthulhuPoolModel()
					local Shards = CthulhuShards()
					local Lines = {
						RT.Head(CthulhuName, RT.Red),
						RT.State(CT.Status, CT.Running),
						RT.Flag("Storm", CthulhuStorm())
							.. RT.Sep
							.. RT.Flag("Whirlpool", Pool ~= nil)
							.. RT.Sep
							.. RT.Flag("Called", CthulhuCallLive())
							.. RT.Sep
							.. RT.Field(CthulhuShard, Shards),
					}

					if Boss then
						RT.Add(Lines, RT.Target("Boss", Boss))
					end

					if Shards < 1 and getgenv().Settings.AutoCthulhu.Craft then
						local Missing = CthulhuMissing()
						RT.Add(
							Lines,
							#Missing > 0 and RT.Paint("Craft needs: " .. table.concat(Missing, ", "), RT.Amber)
								or RT.Paint("Materials ready for the forge", RT.Green)
						)
					end

					RT.Add(
						Lines,
						RT.Flag("Auto Kill", WantCthulhuKill())
							.. RT.Sep
							.. RT.Flag("Auto Summon", WantCthulhuSummon())
							.. RT.Sep
							.. RT.Flag("Priority", true)
							.. " "
							.. RT.Bold("#" .. PriorityOf("Cthulhu"), RT.Muted)
					)

					return table.concat(Lines, "\n")
				end)
			end
		end)

		if getgenv().Settings.AutoCthulhu.Enabled or getgenv().Settings.AutoCthulhu.Summon then
			task.defer(SyncCthulhu)
		end
	end)()

	local BeastName = "Sea Beast"

	local BeastSection = BossTab:Section({ Title = "tr:BeastSection", Icon = "waves", Opened = true })

	local BeastStatus = "-"
	local BeastParagraph = RT.Status(BeastSection, "tr:BeastStatus")

	local BeastRunning = false
	local BeastLoop = nil
	local BeastLastAttack = 0
	local BeastComboStart = 0
	local BeastDodgeUntil = 0
	local BeastAttackDelay = 0.15
	local BeastLift = 3
	local BeastArrivedAt = 0
	local BeastKillToggle
	local BeastFindToggle
	local BeastSpotIndex = 1
	local BeastSpotUntil = 0
	local BeastTravelUntil = 0
	local BeastTravelTime = 180
	local BeastHunting = false
	local BeastNextHunt = 0
	local BeastHuntUntil = 0

	local function BeastInterval()
		return math.max(1, tonumber(getgenv().Settings.AutoSeaBeast.Interval) or 20) * 60
	end

	local function BeastDuration()
		return math.max(1, tonumber(getgenv().Settings.AutoSeaBeast.Duration) or 1) * 60
	end

	local function BeastRestWait()
		BeastHunting = false
		BeastHuntUntil = 0
		BeastSpotUntil = 0
		BeastTravelUntil = 0
		BeastSpotIndex = 1
		BeastNextHunt = tick() + BeastInterval()
	end

	local function BeastHuntNow()
		BeastHunting = false
		BeastHuntUntil = 0
		BeastSpotUntil = 0
		BeastTravelUntil = 0
		BeastSpotIndex = 1
		BeastNextHunt = 0
	end

	local BeastSpotHold = 1.5

	local BeastWords = { "sea beast" }

	local function FindBeast()
		return FindRaidTarget(BeastWords)
	end

	local function WantBeastKill()
		return getgenv().Settings.AutoSeaBeast.Enabled == true
	end

	local function WantBeastFind()
		return getgenv().Settings.AutoSeaBeast.Find == true
	end

	local BeastSpotSweep, BeastSpotSweepAt = nil, 0

	local function BeastSpots()
		local Spots, Seen = {}, {}

		local function Add(Part)
			if not (Part and Part:IsA("BasePart")) then
				return
			end

			local Key = math.floor(Part.Position.X) .. "_" .. math.floor(Part.Position.Z)
			if Seen[Key] then
				return
			end

			Seen[Key] = true
			table.insert(Spots, Part.Position)
		end

		local Logic = workspace:FindFirstChild("Logic")
		local Folder = Logic and Logic:FindFirstChild("Seabeast Spawns")

		if Folder then
			for _, Part in ipairs(Folder:GetChildren()) do
				Add(Part)
			end
		end

		Add(workspace:FindFirstChild("SeaBeastSpawnPoint"))

		if #Spots == 0 then
			local Now = os.clock()
			if BeastSpotSweep and (Now - BeastSpotSweepAt) < 10 then
				return BeastSpotSweep
			end
			BeastSpotSweepAt = Now

			for _, Part in ipairs(workspace:GetDescendants()) do
				if Part:IsA("BasePart") then
					local Lower = string.lower(Part.Name)
					if string.find(Lower, "seabeast", 1, true) and string.find(Lower, "spawn", 1, true) then
						Add(Part)
					end
				end
			end

			BeastSpotSweep = Spots
		end

		return Spots
	end

	local BeastBounds = nil

	local function SeaBounds()
		if BeastBounds then
			return BeastBounds
		end

		local Sea = ({ [6918802270] = 1, [14979402479] = 2, [99664616626491] = 3 })[game.PlaceId] or 1
		local MinX, MaxX, MinZ, MaxZ = math.huge, -math.huge, math.huge, -math.huge
		local Found = false

		for _, Entry in ipairs(getgenv().LevelConfig or {}) do
			local Spot = Entry.MonPOS
			if Spot and SeaOfEntry(Entry) == Sea then
				Found = true
				MinX = math.min(MinX, Spot.X)
				MaxX = math.max(MaxX, Spot.X)
				MinZ = math.min(MinZ, Spot.Z)
				MaxZ = math.max(MaxZ, Spot.Z)
			end
		end

		for _, Spot in ipairs(BeastSpots()) do
			Found = true
			MinX = math.min(MinX, Spot.X)
			MaxX = math.max(MaxX, Spot.X)
			MinZ = math.min(MinZ, Spot.Z)
			MaxZ = math.max(MaxZ, Spot.Z)
		end

		if not Found then
			return nil
		end

		local Pad = 2500

		BeastBounds = {
			MinX = MinX - Pad,
			MaxX = MaxX + Pad,
			MinZ = MinZ - Pad,
			MaxZ = MaxZ + Pad,
		}

		return BeastBounds
	end

	local BeastLegStep = 1200
	local BeastFlyHeight = 25
	local BeastPoints = nil

	local function BeastRoute()
		if BeastPoints then
			return BeastPoints
		end

		local Bounds = SeaBounds()
		if not Bounds then
			return {}
		end

		local Route = {}

		for _, Spot in ipairs(BeastSpots()) do
			table.insert(Route, Vector3.new(Spot.X, BeastFlyHeight, Spot.Z))
		end

		local Columns = math.max(2, math.ceil((Bounds.MaxX - Bounds.MinX) / BeastLegStep))
		local Rows = math.max(2, math.ceil((Bounds.MaxZ - Bounds.MinZ) / BeastLegStep))
		local StepX = (Bounds.MaxX - Bounds.MinX) / Columns
		local StepZ = (Bounds.MaxZ - Bounds.MinZ) / Rows

		for Row = 0, Rows do
			local Z = Bounds.MinZ + Row * StepZ

			for Column = 0, Columns do
				local Index = (Row % 2 == 0) and Column or (Columns - Column)
				table.insert(Route, Vector3.new(Bounds.MinX + Index * StepX, BeastFlyHeight, Z))
			end
		end

		BeastPoints = Route
		return Route
	end

	local function StopBeast()
		BeastRunning = false
		BeastComboStart = 0
		BeastDodgeUntil = 0
		BeastArrivedAt = 0
		BeastSpotUntil = 0
		BeastTravelUntil = 0
		BeastSpotIndex = 1
		BeastHunting = false
		BeastHuntUntil = 0
		BeastNextHunt = 0
		BeastStatus = "Idle"

		if BeastLoop then
			pcall(function()
				task.cancel(BeastLoop)
			end)
			BeastLoop = nil
		end

		EndRunner("Beast")
	end

	local function SyncBeast()
		if not (WantBeastKill() or WantBeastFind()) then
			StopBeast()
			return
		end

		if not HasBossWeaponPicked() then
			getgenv().Settings.AutoSeaBeast.Enabled = false
			getgenv().Settings.AutoSeaBeast.Find = false
			SaveSetting()
			StopBeast()
			RequireBossWeapon(BeastName, BeastKillToggle, BeastFindToggle)
			return
		end

		if BeastRunning then
			return
		end

		BeastRunning = true
		BeastArrivedAt = 0
		BeginRunner("Beast")

		BeastLoop = task.spawn(function()
			while BeastRunning do
				task.wait()

				if not IsCurrentInstance() then
					BeastRunning = false
					EndRunner("Beast")
					break
				end

				local Success = pcall(function()
					if not IsAlive() then
						LockCFrame = nil
						HoldCFrame = nil
						CancelTween()
						task.wait(1)
						return
					end

					local Root = GetRoot()
					if not Root then
						return
					end

					local Boss = FindBeast()

					if not Boss then
						BeastComboStart = 0
						BeastDodgeUntil = 0

						if not WantBeastFind() then
							BeastHunting = false
							BeastHuntUntil = 0
							BeastNextHunt = 0
							BeastSpotUntil = 0
							BeastTravelUntil = 0
							BeastSpotIndex = 1
							IdleRunner("Beast")
							BeastStatus = WantBeastKill() and "Auto Find is off, waiting for the beast" or "Idle"
							task.wait(1)
							return
						end

						if not BeastHunting then
							local Left = BeastNextHunt - tick()

							if Left > 0 then
								IdleRunner("Beast")
								BeastStatus = "Next search in " .. RT.Clock(Left)
								task.wait(1)
								return
							end

							BeastHunting = true
							BeastHuntUntil = tick() + BeastDuration()
							BeastSpotUntil = 0
							BeastTravelUntil = 0
							BeastSpotIndex = 1
						end

						if tick() >= BeastHuntUntil then
							BeastRestWait()
							IdleRunner("Beast")
							BeastStatus = "Nothing found, next search in " .. RT.Clock(BeastInterval())
							task.wait(1)
							return
						end

						local Spots = BeastRoute()
						if #Spots == 0 then
							BeastRestWait()
							IdleRunner("Beast")
							BeastStatus = "Could not work out where this sea is"
							task.wait(2)
							return
						end

						if not ClaimDrive("Beast", 1) then
							BeastStatus = "Another farm is moving, waiting"
							task.wait(0.3)
							return
						end

						StartRender()

						local Index = ((BeastSpotIndex - 1) % #Spots) + 1
						local Spot = Spots[Index]
						local WaitCFrame = CFrame.new(Spot + Vector3.new(0, 25, 0))
						local Away = (Root.Position - WaitCFrame.Position).Magnitude

						if Away > 300 then
							if BeastTravelUntil == 0 then
								BeastTravelUntil = tick() + BeastTravelTime
							end

							if tick() >= BeastTravelUntil then
								BeastTravelUntil = 0
								BeastSpotUntil = 0
								BeastSpotIndex = BeastSpotIndex + 1
								BeastStatus = "Could not reach that spot, trying the next one"
								task.wait(0.5)
								return
							end

							BeastStatus = string.format("Flying out to sea (%s studs left)", RT.Num(Away))
							BeastSpotUntil = 0
							LockCFrame = nil
							TravelTo(WaitCFrame, 300)
							return
						end

						BeastTravelUntil = 0

						if Away > 80 then
							BeastSpotUntil = 0
							BeastStatus =
								string.format("Searching the sea, point %d/%d (%s studs)", Index, #Spots, RT.Num(Away))
							LockCFrame = nil
							TravelTo(WaitCFrame, 80)
							return
						end

						CancelTween()
						LockCFrame = WaitCFrame

						if BeastSpotUntil == 0 then
							BeastSpotUntil = tick() + BeastSpotHold
						elseif tick() >= BeastSpotUntil then
							BeastSpotUntil = 0
							BeastSpotIndex = BeastSpotIndex + 1
						end

						BeastStatus = string.format("Watching point %d/%d", Index, #Spots)

						task.wait(0.3)
						return
					end

					if not WantBeastKill() then
						BeastRestWait()
						BeastStatus = "Sea Beast is up, Auto Kill is off"
						IdleRunner("Beast")
						task.wait(0.5)
						return
					end

					if not ClaimDrive("Beast", 2) then
						BeastStatus = "Another boss farm is moving, waiting"
						task.wait(0.3)
						return
					end

					do
						BeastArrivedAt = 0

						BeastRestWait()

						local Tool = EquipWeapon(BossWeaponName())
						local MobRoot = Boss.Root

						local Stand = GetAttackCFrame(MobRoot.CFrame) + Vector3.new(0, BeastLift, 0)

						if (Root.Position - Stand.Position).Magnitude > 30 then
							BeastStatus = "Flying to " .. BeastName
							StartRender()
							LockCFrame = nil
							TravelTo(Stand, 30)
							return
						end

						BeastStatus = "Fighting " .. BeastName
						StartRender()
						CancelTween()
						LockCFrame = Stand

						if tick() - BeastLastAttack >= BeastAttackDelay then
							BeastLastAttack = tick()
							task.spawn(AttackWith, Tool, MobRoot)
						end

						return
					end
				end)

				if not Success then
					task.wait(0.25)
				end
			end
		end)
	end

	BeastFindToggle = BeastSection:Toggle({
		Title = "tr:BeastFind",
		Path = "AutoSeaBeast.Find",
		Desc = "tr:BeastFindDesc",
		Value = getgenv().Settings.AutoSeaBeast.Find,
		Icon = "check",
		Callback = function(Value)
			getgenv().Settings.AutoSeaBeast.Find = Value
			BeastHuntNow()
			SaveSetting()
			SyncBeast()
		end,
	})

	BeastSection:Slider({
		Title = "tr:BeastInterval",
		Path = "AutoSeaBeast.Interval",
		Desc = "tr:BeastIntervalDesc",
		Value = {
			Min = 1,
			Max = 120,
			Default = getgenv().Settings.AutoSeaBeast.Interval,
		},
		Callback = function(Value)
			getgenv().Settings.AutoSeaBeast.Interval = tonumber(Value) or 20
			SaveSetting()
		end,
	})

	BeastSection:Slider({
		Title = "tr:BeastDuration",
		Path = "AutoSeaBeast.Duration",
		Desc = "tr:BeastDurationDesc",
		Value = {
			Min = 1,
			Max = 30,
			Default = getgenv().Settings.AutoSeaBeast.Duration,
		},
		Callback = function(Value)
			getgenv().Settings.AutoSeaBeast.Duration = tonumber(Value) or 1
			SaveSetting()
		end,
	})

	BeastKillToggle = BeastSection:Toggle({
		Title = "tr:BeastKill",
		Path = "AutoSeaBeast.Enabled",
		Desc = "tr:BeastKillDesc",
		Value = getgenv().Settings.AutoSeaBeast.Enabled,
		Icon = "check",
		Callback = function(Value)
			getgenv().Settings.AutoSeaBeast.Enabled = Value
			SaveSetting()
			SyncBeast()
		end,
	})

	RegisterHopTarget({
		Key = "Beast",
		Label = BeastName,
		Find = FindBeast,
		Enabled = function()
			return WantBeastKill() or WantBeastFind()
		end,
	})

	VenuzToggle.NeedsBeast = function()
		return false
	end

	VenuzToggle.StopBeast = function()
		getgenv().Settings.AutoSeaBeast.Enabled = false
		getgenv().Settings.AutoSeaBeast.Find = false
		SaveSetting()
		StopBeast()
		SetToggleValue(BeastKillToggle, false)
		SetToggleValue(BeastFindToggle, false)
	end

	task.spawn(function()
		while task.wait(1) do
			if not IsCurrentInstance() then
				break
			end
			RT.Push("Beast status", BeastParagraph, function()
				local Boss = FindBeast()
				local Lines = {
					RT.Head(BeastName, RT.Red),
					RT.State(BeastStatus, BeastRunning),
					RT.Field("Route points", tostring(#BeastRoute())),
				}

				if Boss then
					RT.Add(Lines, RT.Target("Sea Beast", Boss))
				end

				if WantBeastFind() then
					local Left = BeastHunting and (BeastHuntUntil - tick()) or (BeastNextHunt - tick())

					RT.Add(
						Lines,
						RT.Paint("Search: ", RT.Muted)
							.. RT.Bold(BeastHunting and "searching" or "waiting", BeastHunting and RT.Green or RT.Amber)
							.. RT.Sep
							.. RT.Paint(BeastHunting and "Gives up in: " or "Starts in: ", RT.Muted)
							.. RT.Bold(RT.Clock(math.max(Left, 0)), RT.Text)
					)

					RT.Add(
						Lines,
						RT.Field("Every", RT.Clock(BeastInterval()))
							.. RT.Sep
							.. RT.Field("For", RT.Clock(BeastDuration()))
					)
				else
					RT.Add(Lines, RT.Paint("Search: ", RT.Muted) .. RT.Bold("off", RT.Muted))
				end

				RT.Add(
					Lines,
					RT.Flag("Auto Find", WantBeastFind())
						.. RT.Sep
						.. RT.Flag("Auto Kill", WantBeastKill())
						.. RT.Sep
						.. RT.Flag("Priority", true)
						.. " "
						.. RT.Bold("#" .. PriorityOf("Beast"), RT.Muted)
				)

				return table.concat(Lines, "\n")
			end)
		end
	end)

	if getgenv().Settings.AutoSeaBeast.Enabled or getgenv().Settings.AutoSeaBeast.Find then
		task.defer(SyncBeast)
	end

	local BossLabels = {
		Hydra = "Dragon Hybrid Boss",
		Raijin = "Raijin Boss",
		Dough = "Dough Boss",
		Dragon = "Dragon Boss",
		Zenith = "Zenith Boss",
		Saturn = "Saturn Boss",
		Enma = "Enma Boss",
		Vault = "Vault Chest",
		RedEmperor = "The Red Emperor",
		GhostShip = "Ghost Ship",
		Beast = "Sea Beast",
	}

	local PrioritySection = BossTab:Section({ Title = "tr:PrioritySection", Icon = "list-ordered", Opened = true })
	local PriorityParagraph = RT.Status(PrioritySection, "tr:PriorityStatus")
	local PrioritySelected = nil

	local function KeyFromLabel(Label)
		if type(Label) ~= "string" then
			return nil
		end

		for Name, Value in pairs(BossLabels) do
			if Value == Label then
				return Name
			end
		end

		return nil
	end

	local function PriorityLabels()
		local Values = {}

		for _, Name in ipairs(BossModules) do
			table.insert(Values, BossLabels[Name] or Name)
		end

		return Values
	end

	local function MovePriority(Delta)
		if not PrioritySelected then
			WindUI:Notify({ Title = "Boss Priority", Content = "Pick a boss first.", Duration = 3 })
			return
		end

		local Order = BossPriorityList()
		local Index = table.find(Order, PrioritySelected)
		local Target = Index and (Index + Delta) or nil

		if not Target or Target < 1 or Target > #Order then
			return
		end

		Order[Index], Order[Target] = Order[Target], Order[Index]

		getgenv().Settings.BossPriority = Order
		SaveSetting()
		InvalidateBossPriority()
	end

	PrioritySection:Dropdown({
		Title = "tr:PrioritySelect",
		Desc = "tr:PrioritySelectDesc",
		Multi = false,
		AllowNone = true,
		Values = PriorityLabels(),
		Value = nil,
		Callback = function(Value)
			PrioritySelected = KeyFromLabel(Value)
		end,
	})

	PrioritySection:Button({
		Title = "tr:PriorityUp",
		Desc = "tr:PriorityUpDesc",
		Callback = function()
			MovePriority(-1)
		end,
	})

	PrioritySection:Button({
		Title = "tr:PriorityDown",
		Desc = "tr:PriorityDownDesc",
		Callback = function()
			MovePriority(1)
		end,
	})

	task.spawn(function()
		while task.wait(1) do
			if not IsCurrentInstance() then
				break
			end
			RT.Push("Boss priority", PriorityParagraph, function()
				local Lines = { RT.Head("Boss Priority", RT.Blue) }

				for Index, Name in ipairs(BossPriorityList()) do
					local Line = RT.Flag(Index .. ". " .. (BossLabels[Name] or Name), VenuzRun.Active[Name] == true)

					if VenuzRun.Owner == Name then
						Line = Line .. RT.Sep .. RT.Bold("driving", RT.Green)
					end

					RT.Add(Lines, Line)
				end

				return table.concat(Lines, "\n")
			end)
		end
	end)

	local HopSection = BossTab:Section({ Title = "tr:HopSection", Icon = "server", Opened = true })

	local HopStatus = "-"
	local HopParagraph = RT.Status(HopSection, "tr:HopStatus")
	local HopIdleSince = 0
	local HopBlockers = { Hydra = true, Raijin = true, Dough = true, Dragon = true, Saturn = true, GhostShip = true }

	local function HopLabels()
		local Values = {}

		for _, Entry in ipairs(HopTargetList()) do
			table.insert(Values, Entry.Label)
		end

		return Values
	end

	local function HopKeyFromLabel(Label)
		for _, Entry in ipairs(HopTargetList()) do
			if Entry.Label == Label then
				return Entry.Key
			end
		end

		return nil
	end

	local function HopWanted()
		local Picked = NormalizeList(getgenv().Settings.AutoHopServer.Bosses)
		local Wanted, Any = {}, false

		for _, Label in ipairs(Picked) do
			local Key = HopKeyFromLabel(Label)
			if Key then
				Wanted[Key] = true
				Any = true
			end
		end

		if not Any then
			return nil
		end

		return Wanted
	end

	HopSection:Dropdown({
		Title = "tr:HopBosses",
		Path = "AutoHopServer.Bosses",
		Desc = "tr:HopBossesDesc",
		Multi = true,
		AllowNone = true,
		Values = HopLabels(),
		Value = getgenv().Settings.AutoHopServer.Bosses,
		Callback = function(Value)
			getgenv().Settings.AutoHopServer.Bosses = NormalizeList(Value)
			HopIdleSince = 0
			SaveSetting()
		end,
	})

	HopSection:Toggle({
		Title = "tr:HopEnable",
		Path = "AutoHopServer.Enabled",
		Desc = "tr:HopEnableDesc",
		Value = getgenv().Settings.AutoHopServer.Enabled,
		Icon = "check",
		Callback = function(Value)
			getgenv().Settings.AutoHopServer.Enabled = Value
			HopIdleSince = 0
			SaveSetting()
		end,
	})

	HopSection:Slider({
		Title = "tr:HopWait",
		Path = "AutoHopServer.Wait",
		Desc = "tr:HopWaitDesc",
		Value = {
			Min = 5,
			Max = 120,
			Default = getgenv().Settings.AutoHopServer.Wait,
		},
		Callback = function(Value)
			getgenv().Settings.AutoHopServer.Wait = Value
			SaveSetting()
		end,
	})

	task.spawn(function()
		while task.wait(1) do
			if not IsCurrentInstance() then
				break
			end

			pcall(function()
				if getgenv().Settings.AutoHopServer.Enabled ~= true then
					HopIdleSince = 0
					HopStatus = "Idle"
					return
				end

				local Wanted = HopWanted()
				local Watching, Live, Waiting = 0, nil, {}

				for _, Entry in ipairs(HopTargetList()) do
					if (Wanted == nil or Wanted[Entry.Key]) and Entry.Enabled() then
						Watching = Watching + 1
						Waiting[Entry.Key] = true

						if Entry.Find() then
							Live = Entry.Label
						end
					end
				end

				if Watching == 0 then
					HopIdleSince = 0
					HopStatus = Wanted and "Picked bosses are turned off" or "No boss is turned on"
					return
				end

				if Live then
					HopIdleSince = 0
					HopStatus = Live .. " is up, staying here"
					return
				end

				for Name in pairs(VenuzRun.Active) do
					if HopBlockers[Name] and not Waiting[Name] then
						HopIdleSince = 0
						HopStatus = (BossLabels[Name] or Name) .. " is still working"
						return
					end
				end

				if HopIdleSince == 0 then
					HopIdleSince = tick()
				end

				local Wait = tonumber(getgenv().Settings.AutoHopServer.Wait) or 10
				local Left = Wait - (tick() - HopIdleSince)

				if Left <= 0 then
					HopIdleSince = 0
					if Waiting.Zenith or Waiting.Enma then
						HopStatus = "Nothing up, looking for an empty server..."
						HopEmptyServer()
					else
						HopStatus = "Nothing up, hopping server..."
						HopServer()
					end

					task.wait(3)
					return
				end

				HopStatus = string.format("Nothing up - hop in %ds", math.ceil(Left))
			end)

			RT.Push("Hop status", HopParagraph, function()
				local Picked = NormalizeList(getgenv().Settings.AutoHopServer.Bosses)
				local Lines = {
					RT.Head("Hop Server", RT.Blue),
					RT.State(HopStatus, getgenv().Settings.AutoHopServer.Enabled == true),
					RT.Field("Wait", tostring(getgenv().Settings.AutoHopServer.Wait) .. "s"),
					RT.Field("Hop for", #Picked > 0 and table.concat(Picked, ", ") or "every boss that is on"),
				}

				return table.concat(Lines, "\n")
			end)
		end
	end)
end)()
;
(function()
	local VIM = game:GetService("VirtualInputManager")

	local SkillTab = TabGroups.Farm:Tab({
		Title = "tr:SkillTab",
		Icon = "wand",
		Locked = false,
	})
	SetTabOrder(SkillTab, 3)

	local KeyChoices = { "Z", "X", "C", "V", "B", "F", "N", "P", "E" }

	local function AllKeys()
		local List, Seen = {}, {}
		for _, Group in ipairs({
			getgenv().Settings.AutoSkill.Melee,
			getgenv().Settings.AutoSkill.Fruit,
			getgenv().Settings.AutoSkill.Sword,
		}) do
			for _, Key in ipairs(NormalizeList(Group)) do
				if not Seen[Key] then
					Seen[Key] = true
					table.insert(List, Key)
				end
			end
		end
		return List
	end

	local function TapKey(Letter, Hold)
		local Code = Enum.KeyCode[Letter]
		if not Code then
			return
		end

		pcall(function()
			VIM:SendKeyEvent(true, Code, false, game)
			if Hold and Hold > 0 then
				task.wait(Hold)
			end
			VIM:SendKeyEvent(false, Code, false, game)
		end)
	end

	local function IsBossMob(Mob)
		local Name = (string.gsub(GetMobName(Mob), "%d+$", ""))
		local Entry = FindEntryByMob(Name)
		return (Entry ~= nil and IsBoss(Entry)) or string.find(Name, "Boss") ~= nil
	end

	local function NearestEnemy(Range, WantMob, WantBoss)
		local Root = GetRoot()
		if not Root then
			return nil
		end

		local Best, BestDist = nil, Range

		for _, Entry in ipairs(IterNPCs()) do
			local Distance = (Entry.Root.Position - Root.Position).Magnitude
			if Distance <= BestDist then
				local Boss = IsBossMob(Entry.Mob)
				if (Boss and WantBoss) or (not Boss and WantMob) then
					BestDist = Distance
					Best = Entry.Mob
				end
			end
		end

		return Best
	end

	local SkillSection = SkillTab:Section({ Title = "tr:SkillSection", Icon = "wand", Opened = true })

	SkillSection:Dropdown({
		Title = "tr:SkillMelee",
		Path = "AutoSkill.Melee",
		Desc = "tr:SkillMeleeDesc",
		Multi = true,
		AllowNone = true,
		Values = KeyChoices,
		Value = getgenv().Settings.AutoSkill.Melee,
		Callback = function(Value)
			getgenv().Settings.AutoSkill.Melee = NormalizeList(Value)
			SaveSetting()
		end,
	})

	SkillSection:Dropdown({
		Title = "tr:SkillFruit",
		Path = "AutoSkill.Fruit",
		Desc = "tr:SkillFruitDesc",
		Multi = true,
		AllowNone = true,
		Values = KeyChoices,
		Value = getgenv().Settings.AutoSkill.Fruit,
		Callback = function(Value)
			getgenv().Settings.AutoSkill.Fruit = NormalizeList(Value)
			SaveSetting()
		end,
	})

	SkillSection:Dropdown({
		Title = "tr:SkillSword",
		Path = "AutoSkill.Sword",
		Desc = "tr:SkillSwordDesc",
		Multi = true,
		AllowNone = true,
		Values = KeyChoices,
		Value = getgenv().Settings.AutoSkill.Sword,
		Callback = function(Value)
			getgenv().Settings.AutoSkill.Sword = NormalizeList(Value)
			SaveSetting()
		end,
	})

	SkillSection:Slider({
		Title = "tr:SkillHold",
		Path = "AutoSkill.HoldDuration",
		Desc = "tr:SkillHoldDesc",
		Value = { Min = 0, Max = 5, Default = getgenv().Settings.AutoSkill.HoldDuration },
		Step = 0.1,
		Callback = function(Value)
			getgenv().Settings.AutoSkill.HoldDuration = tonumber(Value) or 0
			SaveSetting()
		end,
	})

	SkillSection:Slider({
		Title = "tr:SkillDelay",
		Path = "AutoSkill.Delay",
		Desc = "tr:SkillDelayDesc",
		Value = { Min = 0, Max = 10, Default = getgenv().Settings.AutoSkill.Delay },
		Step = 0.1,
		Callback = function(Value)
			getgenv().Settings.AutoSkill.Delay = tonumber(Value) or 0.5
			SaveSetting()
		end,
	})

	SkillSection:Dropdown({
		Title = "tr:SkillUseOn",
		Path = "AutoSkill.UseOn",
		Desc = "tr:SkillUseOnDesc",
		Multi = true,
		AllowNone = true,
		Values = { "Mob", "Boss" },
		Value = getgenv().Settings.AutoSkill.UseOn,
		Callback = function(Value)
			getgenv().Settings.AutoSkill.UseOn = NormalizeList(Value)
			SaveSetting()
		end,
	})

	SkillSection:Slider({
		Title = "tr:SkillRange",
		Path = "AutoSkill.Range",
		Desc = "tr:SkillRangeDesc",
		Value = { Min = 20, Max = 500, Default = getgenv().Settings.AutoSkill.Range },
		Step = 10,
		Callback = function(Value)
			getgenv().Settings.AutoSkill.Range = tonumber(Value) or 150
			SaveSetting()
		end,
	})

	local SkillRunning = false

	VenuzToggle.AutoSkill = function(Value)
		getgenv().Settings.AutoSkill.Enabled = Value
		SaveSetting()

		if not Value then
			SkillRunning = false
			return
		end

		if SkillRunning then
			return
		end
		SkillRunning = true

		task.spawn(function()
			while SkillRunning and getgenv().Settings.AutoSkill.Enabled do
				local Setting = getgenv().Settings.AutoSkill
				local Gap = math.max(0.05, tonumber(Setting.Delay) or 0.5)

				if IsAlive() then
					local WantMob, WantBoss = false, false
					for _, Kind in ipairs(NormalizeList(Setting.UseOn)) do
						if Kind == "Mob" then
							WantMob = true
						elseif Kind == "Boss" then
							WantBoss = true
						end
					end
					if not WantMob and not WantBoss then
						WantMob, WantBoss = true, true
					end

					local Range = math.max(20, tonumber(Setting.Range) or 150)
					local Enemy = NearestEnemy(Range, WantMob, WantBoss)

					if Enemy then
						local Hold = tonumber(Setting.HoldDuration) or 0

						for _, Key in ipairs(AllKeys()) do
							if not (SkillRunning and getgenv().Settings.AutoSkill.Enabled) then
								break
							end
							if Enemy.Parent == nil then
								break
							end

							TapKey(Key, Hold)
							task.wait(0.08)
						end
					end
				end

				task.wait(Gap)
			end

			SkillRunning = false
		end)
	end

	local AutoSkillToggle = SkillSection:Toggle({
		Title = "tr:SkillToggle",
		Path = "AutoSkill.Enabled",
		Desc = "tr:SkillToggleDesc",
		Value = getgenv().Settings.AutoSkill.Enabled,
		Icon = "check",
		Callback = VenuzToggle.AutoSkill,
	})

	if getgenv().Settings.AutoSkill.Enabled then
		task.defer(VenuzToggle.AutoSkill, true)
	end
end)()
;
(function()
	local UserInputService = game:GetService("UserInputService")

	local function FindSkill(Name)
		local Gui = LocalPlayer:FindFirstChild("PlayerGui")
		local Root = Gui and Gui:FindFirstChild("FormerStarterCharacterScripts")
		Root = Root and Root:FindFirstChild("NormalSkills")
		return Root and Root:FindFirstChild(Name)
	end

	local function ApplyDash()
		local Dashing = FindSkill("Dashing")
		local Values = Dashing and Dashing:FindFirstChild("Values")
		if not Values then
			return
		end
		local CoolDown = Values:FindFirstChild("CoolDown")
		local Energy = Values:FindFirstChild("EnergyLost")
		if CoolDown then
			CoolDown.Value = 0
		end
		if Energy then
			Energy.Value = 0
		end
	end

	local function ApplyGeppo()
		local Geppo = FindSkill("Geppo")
		local CoolDown = Geppo and Geppo:FindFirstChild("CoolDown")
		if CoolDown then
			CoolDown.Value = 0
		end

		local Data = LocalPlayer:FindFirstChild("PlayerData")
		local Buffs = Data and Data:FindFirstChild("Buffs")
		local SkyWalk = Buffs and Buffs:FindFirstChild("SkyWalkBuff")
		if SkyWalk then
			SkyWalk.Value = 999
		end
	end

	local MiscTab = TabGroups.System:Tab({
		Title = "tr:MiscTab",
		Icon = "rocket",
		Locked = false,
	})

	local MiscSection = MiscTab:Section({ Title = "tr:MiscSection", Icon = "rocket", Opened = true })

	local DashRunning = false
	local GeppoRunning = false

	VenuzToggle.DashNoCooldown = function(Value)
		getgenv().Settings.Misc.DashNoCooldown = Value
		SaveSetting()

		if not Value then
			DashRunning = false
			return
		end
		if DashRunning then
			return
		end
		DashRunning = true

		task.spawn(function()
			while DashRunning and getgenv().Settings.Misc.DashNoCooldown do
				pcall(ApplyDash)
				task.wait(0.5)
			end
			DashRunning = false
		end)
	end

	MiscSection:Toggle({
		Title = "tr:DashNoCooldown",
		Path = "Misc.DashNoCooldown",
		Desc = "tr:DashNoCooldownDesc",
		Value = getgenv().Settings.Misc.DashNoCooldown,
		Icon = "check",
		Callback = VenuzToggle.DashNoCooldown,
	})

	VenuzToggle.SkyJumpInf = function(Value)
		getgenv().Settings.Misc.SkyJumpInf = Value
		SaveSetting()

		if not Value then
			GeppoRunning = false
			return
		end
		if GeppoRunning then
			return
		end
		GeppoRunning = true

		task.spawn(function()
			while GeppoRunning and getgenv().Settings.Misc.SkyJumpInf do
				pcall(ApplyGeppo)
				task.wait(0.5)
			end
			GeppoRunning = false
		end)
	end

	MiscSection:Toggle({
		Title = "tr:SkyJumpInf",
		Path = "Misc.SkyJumpInf",
		Desc = "tr:SkyJumpInfDesc",
		Value = getgenv().Settings.Misc.SkyJumpInf,
		Icon = "check",
		Callback = VenuzToggle.SkyJumpInf,
	})

	local JumpConnection = nil

	VenuzToggle.InfiniteJump = function(Value)
		getgenv().Settings.Misc.InfiniteJump = Value
		SaveSetting()

		if JumpConnection == nil then
			JumpConnection = UserInputService.JumpRequest:Connect(function()
				if not getgenv().Settings.Misc.InfiniteJump then
					return
				end
				local Humanoid = GetHumanoid()
				if Humanoid then
					pcall(function()
						Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
					end)
				end
			end)
		end
	end

	MiscSection:Toggle({
		Title = "tr:InfiniteJump",
		Path = "Misc.InfiniteJump",
		Desc = "tr:InfiniteJumpDesc",
		Value = getgenv().Settings.Misc.InfiniteJump,
		Icon = "check",
		Callback = VenuzToggle.InfiniteJump,
	})

	local CodeSection = MiscTab:Section({ Title = "tr:CodeSection", Icon = "gift", Opened = true })

	local CodeList = {
		"ABYSSALCTHLHU",
		"PHANTOMSHIP",
		"CRIMSONEMPEROR",
		"SPIDERCYBORG",
		"ELECAWAKENING",
		"1HEXP",
		"300KMembers",
		"THANKS4PLAYING",
		"STATREFUND",
		"DRAGONUPD",
		"OKUCHI",
		"Sub2Xenoty",
		"Sub2CaptainMaui",
		"RELEASE",
		"FREECASH",
		"FREEGEMS",
		"PATCH",
		"HAZESEAS2026",
		"SUBSCRIBETOHAZEYT",
		"Sub2Nikkolapz",
		"Sub2BadiTubes",
		"Sub2BrosSiam",
		"Sub2BuilderboyTV",
	}

	local RedeemingCodes = false

	local function ClaimCodeRemote()
		local Replication = game:GetService("ReplicatedStorage"):FindFirstChild("Replication")
		local Events = Replication and Replication:FindFirstChild("ClientEvents")
		return Events and Events:FindFirstChild("ClaimCode")
	end

	CodeSection:Button({
		Title = "tr:RedeemAllCodes",
		Desc = "tr:RedeemAllCodesDesc",
		Icon = "gift",
		Callback = function()
			if RedeemingCodes then
				return
			end

			local Remote = ClaimCodeRemote()
			if not Remote then
				WindUI:Notify({
					Title = "Codes",
					Content = "ClaimCode remote not found.",
					Icon = VenuzIcon,
					Duration = 5,
				})
				return
			end

			RedeemingCodes = true

			task.spawn(function()
				local Claimed, Failed = 0, 0

				for _, Code in ipairs(CodeList) do
					local Ok, Message, Rewards = pcall(function()
						return Remote:InvokeServer(Code)
					end)

					if Ok and Rewards then
						Claimed = Claimed + 1
					else
						Failed = Failed + 1
					end

					task.wait(0.6)
				end

				RedeemingCodes = false

				WindUI:Notify({
					Title = "Codes",
					Content = string.format("Redeemed %d / %d codes (%d skipped).", Claimed, #CodeList, Failed),
					Icon = VenuzIcon,
					Duration = 6,
				})
			end)
		end,
	})

	if getgenv().Settings.Misc.DashNoCooldown then
		task.defer(VenuzToggle.DashNoCooldown, true)
	end
	if getgenv().Settings.Misc.SkyJumpInf then
		task.defer(VenuzToggle.SkyJumpInf, true)
	end
	if getgenv().Settings.Misc.InfiniteJump then
		task.defer(VenuzToggle.InfiniteJump, true)
	end
end)()
;
(function()
	local WebhookTab = TabGroups.System:Tab({
		Title = "tr:WebhookTab",
		Icon = "webhook",
		Locked = false,
	})

	local WH = Webhook

	local function Thai()
		return getgenv().ConfigurationTable.Language == "Thai"
	end

	local function Notify(ThaiText, EnglishText)
		WindUI:Notify({
			Title = "Webhook",
			Content = Thai() and ThaiText or EnglishText,
			Icon = VenuzIcon,
			Duration = 5,
		})
	end

	local SetupSection = WebhookTab:Section({ Title = "tr:WebhookSetupSection", Icon = "webhook", Opened = true })
	local StatusPanel = RT.Status(SetupSection, "tr:WebhookStatus")

	local function Refresh()
		if not StatusPanel then
			return
		end

		local Config = WH.Config() or {}
		local Url = WH.Trim(Config.Url)
		local Linked = WH.ValidUrl(Url)

		local On = {}
		for Name, Value in pairs(type(Config.Events) == "table" and Config.Events or {}) do
			if Value == true then
				table.insert(On, Name)
			end
		end
		table.sort(On)

		local Lines = {
			RT.Head("Webhook"),
			RT.Field(
				"Link",
				Linked and "connected" or (Url == "" and "not set" or "not a webhook URL"),
				Linked and RT.Green or RT.Red
			),
			RT.Field(
				"Ping ID",
				WH.Trim(Config.UserId) ~= "" and WH.Trim(Config.UserId) or "none",
				WH.Trim(Config.UserId) ~= "" and RT.Cyan or RT.Muted
			),
			RT.Field("Events on", #On > 0 and table.concat(On, ", ") or "none", #On > 0 and RT.Text or RT.Muted),
			RT.Head("Traffic", RT.Purple),
			RT.Field("Sent", tostring(WH.Sent), RT.Green) .. RT.Paint("  ·  ", RT.Faint) .. RT.Field(
				"Failed",
				tostring(WH.Failed),
				WH.Failed > 0 and RT.Red or RT.Muted
			) .. RT.Paint("  ·  ", RT.Faint) .. RT.Field("Queued", tostring(#WH.Queue), RT.Muted),
			RT.Field(
				"Last error",
				WH.LastError ~= "" and WH.LastError or "none",
				WH.LastError ~= "" and RT.Red or RT.Muted
			),
			RT.Head("This run", RT.Amber),
			RT.Field("Uptime", WH.Uptime(), RT.Cyan)
				.. RT.Paint("  ·  ", RT.Faint)
				.. RT.Field("Bosses", tostring(WH.Session.Bosses), RT.Red)
				.. RT.Paint("  ·  ", RT.Faint)
				.. RT.Field("Fruits", tostring(WH.Session.Fruits), RT.Pink)
				.. RT.Paint("  ·  ", RT.Faint)
				.. RT.Field("Deaths", tostring(WH.Session.Deaths), RT.Muted),
		}

		RT.Push("Webhook status", StatusPanel, function()
			return table.concat(Lines, "\n")
		end)
	end

	task.spawn(function()
		while true do
			pcall(Refresh)
			task.wait(5)
		end
	end)

	local function Fire(Build)
		if not WH.Url() then
			Notify(
				"ยังไม่ได้ใส่ลิงก์ Webhook หรือลิงก์ไม่ถูกต้อง",
				"No valid webhook URL is set yet."
			)
			return
		end

		if not WH.Sender() then
			Notify(
				"Executor ตัวนี้ส่ง HTTP ไม่ได้ ใช้ Webhook ไม่ได้",
				"This executor has no HTTP request function, so webhooks cannot be sent."
			)
			return
		end

		local Ok, Reason = Build()

		if Ok == false then
			Notify("ส่งไม่สำเร็จ: " .. tostring(Reason), "Could not send: " .. tostring(Reason))
		else
			Notify(
				"ส่งเข้าคิวแล้ว รอสักครู่",
				"Queued. It lands in Discord in a moment."
			)
		end

		task.delay(0.5, Refresh)
	end

	WebhookTab:Input({
		Title = "tr:WebhookUrl",
		Desc = "tr:WebhookUrlDesc",
		Path = "Webhook.Url",
		Value = getgenv().Settings.Webhook.Url,
		Callback = function(Value)
			getgenv().Settings.Webhook.Url = WH.Trim(Value)
			SaveSetting()

			if getgenv().Settings.Webhook.Url ~= "" and not WH.ValidUrl(getgenv().Settings.Webhook.Url) then
				Notify(
					"ลิงก์นี้ไม่ใช่ Webhook ของ Discord ต้องขึ้นต้นด้วย https://discord.com/api/webhooks/",
					"That is not a Discord webhook URL. It has to start with https://discord.com/api/webhooks/"
				)
			end

			Refresh()
		end,
	})

	WebhookTab:Input({
		Title = "tr:WebhookUserId",
		Desc = "tr:WebhookUserIdDesc",
		Path = "Webhook.UserId",
		Value = getgenv().Settings.Webhook.UserId,
		Callback = function(Value)
			getgenv().Settings.Webhook.UserId = WH.Trim(Value)
			SaveSetting()
			Refresh()
		end,
	})

	WebhookTab:Toggle({
		Title = "tr:WebhookHideName",
		Desc = "tr:WebhookHideNameDesc",
		Path = "Webhook.HideName",
		Value = getgenv().Settings.Webhook.HideName,
		Icon = "check",
		Callback = function(Value)
			getgenv().Settings.Webhook.HideName = Value
			SaveSetting()
		end,
	})

	WebhookTab:Button({
		Title = "tr:WebhookTest",
		Desc = "tr:WebhookTestDesc",
		Callback = function()
			Fire(function()
				return WH.SendTest()
			end)
		end,
	})

	local EventSection = WebhookTab:Section({ Title = "tr:WebhookEventSection", Icon = "bell", Opened = true })

	local EventList = {
		{ "ScriptStart", "WebhookEvStart" },
		{ "Merchant", "WebhookEvMerchant" },
		{ "BossKill", "WebhookEvBoss" },
		{ "Fruit", "WebhookEvFruit" },
		{ "Sword", "WebhookEvSword" },
		{ "Accessory", "WebhookEvAccessory" },
		{ "LevelUp", "WebhookEvLevel" },
		{ "SeaUnlock", "WebhookEvSea" },
		{ "Death", "WebhookEvDeath" },
		{ "ServerHop", "WebhookEvHop" },
	}

	for _, Entry in ipairs(EventList) do
		local Key = Entry[1]

		EventSection:Toggle({
			Title = "tr:" .. Entry[2],
			Desc = "tr:" .. Entry[2] .. "Desc",
			Path = "Webhook.Events." .. Key,
			Value = getgenv().Settings.Webhook.Events[Key],
			Icon = "check",
			Callback = function(Value)
				getgenv().Settings.Webhook.Events[Key] = Value
				SaveSetting()
				Refresh()
			end,
		})
	end

	EventSection:Slider({
		Title = "tr:WebhookLevelStep",
		Desc = "tr:WebhookLevelStepDesc",
		Path = "Webhook.LevelStep",
		Value = {
			Min = 1,
			Max = 500,
			Default = getgenv().Settings.Webhook.LevelStep,
		},
		Callback = function(Value)
			getgenv().Settings.Webhook.LevelStep = math.max(1, math.floor(tonumber(Value) or 25))
			SaveSetting()
		end,
	})

	local PingValues = {}
	for _, Entry in ipairs(EventList) do
		table.insert(PingValues, Entry[1])
	end

	EventSection:Dropdown({
		Title = "tr:WebhookPing",
		Desc = "tr:WebhookPingDesc",
		Path = "Webhook.PingOn",
		Multi = true,
		AllowNone = true,
		Values = PingValues,
		Value = NormalizeList(getgenv().Settings.Webhook.PingOn),
		Callback = function(Value)
			getgenv().Settings.Webhook.PingOn = NormalizeList(Value)
			SaveSetting()
		end,
	})

	local HeartSection = WebhookTab:Section({ Title = "tr:WebhookHeartSection", Icon = "clock", Opened = true })

	HeartSection:Toggle({
		Title = "tr:WebhookHeart",
		Desc = "tr:WebhookHeartDesc",
		Path = "Webhook.Heartbeat",
		Value = getgenv().Settings.Webhook.Heartbeat,
		Icon = "check",
		Callback = function(Value)
			getgenv().Settings.Webhook.Heartbeat = Value
			SaveSetting()
		end,
	})

	HeartSection:Slider({
		Title = "tr:WebhookHeartMinutes",
		Desc = "tr:WebhookHeartMinutesDesc",
		Path = "Webhook.HeartbeatMinutes",
		Value = {
			Min = 1,
			Max = 240,
			Default = getgenv().Settings.Webhook.HeartbeatMinutes,
		},
		Callback = function(Value)
			getgenv().Settings.Webhook.HeartbeatMinutes = math.max(1, math.floor(tonumber(Value) or 30))
			SaveSetting()
		end,
	})

	local ViewSection = WebhookTab:Section({ Title = "tr:WebhookViewSection", Icon = "send", Opened = true })

	local ViewButtons = {
		{
			"WebhookViewPlayer",
			"user",
			function()
				return WH.SendPlayer()
			end,
		},
		{
			"WebhookViewFruit",
			"apple",
			function()
				return WH.SendFruitBag()
			end,
		},
		{
			"WebhookViewSword",
			"sword",
			function()
				return WH.SendSwords()
			end,
		},
		{
			"WebhookViewBoss",
			"skull",
			function()
				return WH.SendBosses()
			end,
		},
		{
			"WebhookViewRunner",
			"activity",
			function()
				return WH.SendRunners()
			end,
		},
		{
			"WebhookViewSession",
			"history",
			function()
				return WH.SendSession(true)
			end,
		},
	}

	for _, Entry in ipairs(ViewButtons) do
		ViewSection:Button({
			Title = "tr:" .. Entry[1],
			Desc = "tr:" .. Entry[1] .. "Desc",
			Icon = Entry[2],
			Callback = function()
				Fire(Entry[3])
			end,
		})
	end

	task.defer(function()
		WH.StartWatchers()
		Refresh()

		if WH.Url() and WH.On("ScriptStart") then
			WH.Report({
				Event = "ScriptStart",
				Title = WH.T("StartTitle"),
				Note = WH.T("StartNote"),
				Rows = {
					{ WH.T("RowPlayer"), WH.Who(), WH.Ink.Cyan },
					{ WH.T("RowLevel"), WH.Num(WH.Level()), WH.Ink.Blue },
					{ WH.T("RowBeli"), "$" .. WH.Num(WH.Beli()), WH.Ink.Amber },
					{ WH.T("RowGems"), WH.Num(WH.Gems()), WH.Ink.Pink },
					{ WH.T("RowServer"), tostring(game.JobId ~= "" and game.JobId or "studio"), WH.Ink.Grey },
				},
				Color = WH.Color.Good,
			})
		end
	end)
end)()

local Tab = TabGroups.System:Tab({
	Title = "tr:Configuration",
	Icon = "settings",
	Locked = false,
})

Tab:Section({ Title = "tr:Interface", Icon = "settings-2" })

local themeValues = {}
for name, _ in pairs(WindUI:GetThemes()) do
	table.insert(themeValues, name)
end

Tab:Dropdown({
	Title = "tr:themeDropdown",
	Desc = "tr:themeDropdownDesc",
	Multi = false,
	AllowNone = false,
	Value = getgenv().ConfigurationTable.Themes,
	Values = themeValues,
	Callback = function(theme)
		getgenv().ConfigurationTable.Themes = theme
		SaveConfiguration()
		WindUI:SetTheme(theme)
	end,
})

Tab:Toggle({
	Title = "tr:ToggleTransparency",
	Desc = "tr:ToggleTransparencyDesc",
	Value = getgenv().ConfigurationTable.Transparent,
	Icon = "check",
	Callback = function(e)
		getgenv().ConfigurationTable.Transparent = e
		SaveConfiguration()
		Window:ToggleTransparency(e)
	end,
})

local AntiAfkConnection = nil

VenuzToggle.AntiAFK = function(enabled)
	getgenv().ConfigurationTable.AntiAFK = enabled
	SaveConfiguration()

	if AntiAfkConnection then
		pcall(function()
			AntiAfkConnection:Disconnect()
		end)
		AntiAfkConnection = nil
	end

	if enabled then
		local VirtualUser = game:GetService("VirtualUser")
		AntiAfkConnection = LocalPlayer.Idled:Connect(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end
end

local AntiAFKToggle = Tab:Toggle({
	Title = "tr:AntiAFK",
	Desc = "tr:AntiAFKDesc",

	Value = getgenv().ConfigurationTable.AntiAFK,
	Icon = "check",
	Callback = VenuzToggle.AntiAFK,
})

local AutoRejoinConnection = nil

VenuzToggle.AutoRejoin = function(enabled)
	getgenv().ConfigurationTable.AutoRejoin = enabled
	SaveConfiguration()

	if AutoRejoinConnection then
		pcall(function()
			AutoRejoinConnection:Disconnect()
		end)
		AutoRejoinConnection = nil
	end

	if enabled then
		pcall(function()
			local Overlay = game:GetService("CoreGui"):WaitForChild("RobloxPromptGui"):WaitForChild("promptOverlay")
			AutoRejoinConnection = Overlay.ChildAdded:Connect(function(child)
				if child.Name == "ErrorPrompt" then
					game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
				end
			end)
		end)
	end
end

local AutoRejoinToggle = Tab:Toggle({
	Title = "tr:AutoRejoin",
	Desc = "tr:AutoRejoinDesc",

	Value = getgenv().ConfigurationTable.AutoRejoin,
	Icon = "check",
	Callback = VenuzToggle.AutoRejoin,
})

Tab:Toggle({
	Title = "tr:AutoExecutor",
	Desc = "tr:AutoExecutorDesc",
	Value = getgenv().ConfigurationTable.AutoExecutor,
	Icon = "check",
	Callback = function(Value)
		getgenv().ConfigurationTable.AutoExecutor = Value
		SaveConfiguration()
	end,
})

Tab:Keybind({
	Title = "tr:MinimizeBind",
	Desc = "tr:MinimizeBindDesc",
	Value = getgenv().ConfigurationTable.MinimizeBind,
	Callback = function(v)
		getgenv().ConfigurationTable.MinimizeBind = v
		SaveConfiguration()
		Window:SetToggleKey(Enum.KeyCode[v])
	end,
})

Tab:Section({ Title = "tr:FPSIS", Icon = "gamepad" })

Tab:Slider({
	Title = "tr:FPSVALUE",
	Desc = "tr:FPSVALUEDesc",
	Value = {
		Min = 1,
		Max = 240,
		Default = getgenv().ConfigurationTable.FPSValue,
	},
	Callback = function(Value)
		getgenv().ConfigurationTable.FPSValue = Value
		SaveConfiguration()
	end,
})

VenuzToggle.FPSLock = function(v)
	getgenv().ConfigurationTable.LockFPS = v
	SaveConfiguration()

	if v then
		task.spawn(function()
			local Applied = nil

			while getgenv().ConfigurationTable.LockFPS do
				local Want = tonumber(getgenv().ConfigurationTable.FPSValue)

				if Want and Want ~= Applied then
					Applied = Want
					pcall(setfpscap, Want)
				end

				task.wait(0.5)
			end

			pcall(setfpscap, 240)
		end)
	else
		pcall(function()
			setfpscap(240)
		end)
	end
end

local FPSLockToggle = Tab:Toggle({
	Title = "tr:FPSLOCK",
	Desc = "tr:FPSLOCKDesc",

	Value = getgenv().ConfigurationTable.LockFPS,
	Icon = "check",
	Callback = VenuzToggle.FPSLock,
})

ScreenColors = {
	["White"] = Color3.fromRGB(255, 255, 255),
	["Black"] = Color3.fromRGB(0, 0, 0),
}

function ScreenColorName()
	local Name = getgenv().ConfigurationTable.ScreenColor
	return ScreenColors[Name] and Name or "White"
end

function ScreenOverlayRoots()
	local Roots = {}

	local function Add(Value)
		if typeof(Value) == "Instance" then
			Roots[#Roots + 1] = Value
		end
	end

	if gethui then
		local Ok, Hidden = pcall(gethui)
		if Ok then
			Add(Hidden)
		end
	end

	local Ok, Core = pcall(game.GetService, game, "CoreGui")
	if Ok then
		Add(Core)
	end

	Add(game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui"))

	return Roots
end

function ScreenOverlayRoot()
	return ScreenOverlayRoots()[1]
end

function FindScreenOverlay()
	for _, Root in ipairs(ScreenOverlayRoots()) do
		local Found = nil
		pcall(function()
			Found = Root:FindFirstChild("Venuz_White")
		end)

		if Found then
			return Found
		end
	end

	return nil
end

function ApplyScreenColor()
	local screenGui = FindScreenOverlay()
	local frame = screenGui and screenGui:FindFirstChild("Venuz_1")

	if frame then
		frame.BackgroundColor3 = ScreenColors[ScreenColorName()]
	end
end

ScreenTopOrder = -1

function SetGameCoreGui(On)
	local StarterGui = game:GetService("StarterGui")

	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, On)
	end)

	task.spawn(function()
		for _ = 1, 6 do
			local Ok = pcall(function()
				StarterGui:SetCore("TopbarEnabled", On)
			end)

			if Ok then
				return
			end

			task.wait(0.5)
		end
	end)
end

ScreenOverlayGuard = nil

function StartScreenOverlayGuard()
	if ScreenOverlayGuard then
		return
	end

	ScreenOverlayGuard = task.spawn(function()
		while getgenv().ConfigurationTable.WhileScreen do
			local Gui = FindScreenOverlay()
			local Frame = Gui and Gui:FindFirstChild("Venuz_1")

			if not (Gui and Gui.Parent and Frame) then
				ScreenOverlayGuard = nil
				VenuzToggle.WhiteScreen(true)
				return
			end

			pcall(function()
				Gui.Enabled = true
				Gui.IgnoreGuiInset = true
				Gui.DisplayOrder = ScreenTopOrder

				Frame.Visible = true
				Frame.ZIndex = ScreenTopOrder
				Frame.BackgroundTransparency = 0
			end)

			task.wait(1)
		end

		ScreenOverlayGuard = nil
		SetGameCoreGui(true)
	end)
end

VenuzToggle.WhiteScreen = function(v)
	getgenv().ConfigurationTable.WhileScreen = v
	SaveConfiguration()

	local screenGui = FindScreenOverlay()

	if v then
		if not screenGui then
			screenGui = Instance.new("ScreenGui")
			screenGui.Name = "Venuz_White"
			screenGui.Enabled = true
			screenGui.IgnoreGuiInset = true
			screenGui.DisplayOrder = ScreenTopOrder
			screenGui.ResetOnSpawn = false
			screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

			local frame = Instance.new("Frame")
			frame.Name = "Venuz_1"
			frame.Position = UDim2.new(0, 0, 0, 0)
			frame.Size = UDim2.new(1, 0, 1, 0)
			frame.BorderSizePixel = 0
			frame.ZIndex = ScreenTopOrder
			frame.BackgroundTransparency = 0
			frame.BackgroundColor3 = ScreenColors[ScreenColorName()]
			frame.Parent = screenGui

			local Parented = pcall(function()
				screenGui.Parent = ScreenOverlayRoot()
			end)

			if not Parented or not screenGui.Parent then
				pcall(function()
					screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
				end)
			end
		else
			screenGui.Enabled = true
			ApplyScreenColor()
		end

		SetGameCoreGui(false)
		StartScreenOverlayGuard()
	else
		if screenGui then
			screenGui.Enabled = false
		end

		SetGameCoreGui(true)
	end
end

Tab:Dropdown({
	Title = "tr:ScreenColor",
	Desc = "tr:ScreenColorDesc",
	Multi = false,
	AllowNone = false,
	Values = { "White", "Black" },
	Value = ScreenColorName(),
	Callback = function(Value)
		getgenv().ConfigurationTable.ScreenColor = ScreenColors[Value] and Value or "White"
		SaveConfiguration()
		ApplyScreenColor()
	end,
})

local WhiteScreenToggle = Tab:Toggle({
	Title = "tr:WhiteScreen",
	Desc = "tr:WhiteScreenDesc",

	Value = getgenv().ConfigurationTable.WhileScreen,
	Icon = "check",
	Callback = VenuzToggle.WhiteScreen,
})

task.defer(function()
	for Callback, Enabled in pairs({
		[VenuzToggle.AntiAFK] = getgenv().ConfigurationTable.AntiAFK,
		[VenuzToggle.AutoRejoin] = getgenv().ConfigurationTable.AutoRejoin,
		[VenuzToggle.FPSLock] = getgenv().ConfigurationTable.LockFPS,
		[VenuzToggle.WhiteScreen] = getgenv().ConfigurationTable.WhileScreen,
	}) do
		if Enabled then
			pcall(Callback, true)
		end
	end
end)

Tab:Section({ Title = "tr:LanguageTab", Icon = "languages" })

Tab:Dropdown({
	Title = "tr:Language",
	Desc = "tr:LanguageDesc",
	Multi = false,
	AllowNone = false,
	Values = { "English (US)", "Thai" },
	Value = getgenv().ConfigurationTable.Language,
	Callback = function(Callback)
		getgenv().ConfigurationTable.Language = Callback
		SaveConfiguration()
	end,
})

Tab:Button({
	Title = "tr:ChangedLanguage",
	Desc = "tr:ChangedLanguageDesc",
	Callback = function()
		if getgenv().ConfigurationTable.Language == "English (US)" then
			WindUI:SetLanguage("English (US)")
		else
			WindUI:SetLanguage("Thai")
		end
		Window:SelectTab(1)
	end,
})

ConfigFolder = FolderSettings .. "/Configs"
ConfigNameInput = ""
ConfigPicked = ""

function ConfigSafeName(Name)
	Name = tostring(Name or ""):match("^%s*(.-)%s*$")
	Name = Name:gsub("[^%w _%-]", "")
	return Name:sub(1, 40)
end

function ConfigPath(Name)
	return ConfigFolder .. "/" .. Name .. ".json"
end

function ConfigReady()
	if not (makefolder and isfolder) then
		return false
	end

	pcall(function()
		if not isfolder(FolderConfiguration) then
			makefolder(FolderConfiguration)
		end
		if not isfolder(FolderSettings) then
			makefolder(FolderSettings)
		end
		if not isfolder(ConfigFolder) then
			makefolder(ConfigFolder)
		end
	end)

	return isfolder(ConfigFolder) == true
end

function ConfigNames()
	local List = {}
	if not listfiles or not ConfigReady() then
		return List
	end

	local ok, Files = pcall(listfiles, ConfigFolder)
	if not ok or type(Files) ~= "table" then
		return List
	end

	for _, Path in ipairs(Files) do
		local Name = tostring(Path):match("([^/\\]+)%.json$")
		if Name then
			table.insert(List, Name)
		end
	end

	table.sort(List)
	return List
end

function ConfigSave(Name)
	Name = ConfigSafeName(Name)
	if Name == "" or not writefile or not ConfigReady() then
		return false, Name
	end

	SanitizeSettings()

	local ok = pcall(function()
		writefile(ConfigPath(Name), HttpService:JSONEncode(getgenv().Settings))
	end)

	return ok, Name
end

function SettingsAt(Path)
	local Node = getgenv().Settings

	for Part in Path:gmatch("[^%.]+") do
		if type(Node) ~= "table" then
			return nil
		end
		Node = Node[Part]
	end

	return Node
end

function SetWidgetValue(Widget, Value)
	if type(Widget) ~= "table" then
		return false
	end

	for _, Name in ipairs({ "SetValue", "Set", "Select" }) do
		local Found, Method = pcall(function()
			return Widget[Name]
		end)

		if Found and type(Method) == "function" and pcall(Method, Widget, Value) then
			return true
		end
	end

	return false
end

function ConfigSyncWidgets()
	for _, Entry in ipairs(ConfigWidgets) do
		local Value = SettingsAt(Entry.Path)

		if Value == "" then
			Value = nil
		end

		pcall(SetWidgetValue, Entry.Widget, Value)

		if type(Entry.Callback) == "function" then
			pcall(Entry.Callback, Value)
		end
	end
end

function ConfigApply(Name)
	Name = ConfigSafeName(Name)
	if Name == "" or not (readfile and isfile) or not isfile(ConfigPath(Name)) then
		return false
	end

	local ok, Decoded = pcall(function()
		return HttpService:JSONDecode(readfile(ConfigPath(Name)))
	end)

	if not ok or type(Decoded) ~= "table" then
		return false
	end

	MergeSettings(DefaultSettings, Decoded)
	getgenv().Settings = Decoded
	SanitizeSettings()
	Decoded.AutoFarmLevel.Weapon = FarmWeaponMode()
	Decoded.AutoFarmLevel.BossWeapon = BossWeaponMode()
	ConfigApplying = true
	pcall(ConfigSyncWidgets)
	InvalidateBossPriority()
	ConfigApplying = false

	SaveSetting()

	return true
end

function ConfigRemove(Name)
	Name = ConfigSafeName(Name)
	if Name == "" or not (delfile and isfile) or not isfile(ConfigPath(Name)) then
		return false
	end

	return pcall(delfile, ConfigPath(Name)) == true
end

function ConfigThai()
	return getgenv().ConfigurationTable.Language == "Thai"
end

function ConfigNotify(Thai, English)
	WindUI:Notify({
		Title = "Config",
		Content = ConfigThai() and Thai or English,
		Icon = VenuzIcon,
		Duration = 5,
	})
end

Tab:Section({ Title = "tr:ConfigSection", Icon = "folder" })

pcall(function()
	Tab:Input({
		Title = "tr:ConfigName",
		Desc = "tr:ConfigNameDesc",
		Value = "",
		Callback = function(Value)
			ConfigNameInput = ConfigSafeName(Value)
		end,
	})
end)

Tab:Button({
	Title = "tr:ConfigCreate",
	Desc = "tr:ConfigCreateDesc",
	Callback = function()
		local Name = ConfigNameInput
		if Name == "" then
			Name = "Config_" .. os.date("%d%m_%H%M")
		end

		local Saved, Final = ConfigSave(Name)
		if not Saved then
			ConfigNotify(
				"บันทึกคอนฟิกไม่สำเร็จ (executor ไม่รองรับการเขียนไฟล์)",
				"Could not save config (executor cannot write files)."
			)
			return
		end

		ConfigPicked = Final
		pcall(function()
			ConfigDropdown:Refresh(ConfigNames())
		end)
		ConfigNotify(
			'บันทึกคอนฟิก "' .. Final .. '" แล้ว',
			'Saved config "' .. Final .. '".'
		)
	end,
})

ConfigDropdown = Tab:Dropdown({
	Title = "tr:ConfigList",
	Desc = "tr:ConfigListDesc",
	Multi = false,
	AllowNone = true,
	Values = ConfigNames(),
	Callback = function(Value)
		ConfigPicked = ConfigSafeName(Value)
	end,
})

Tab:Button({
	Title = "tr:ConfigLoad",
	Desc = "tr:ConfigLoadDesc",
	Callback = function()
		if ConfigPicked == "" then
			ConfigNotify("เลือกคอนฟิกก่อน", "Pick a config first.")
			return
		end

		if not ConfigApply(ConfigPicked) then
			ConfigNotify("โหลดคอนฟิกไม่สำเร็จ", "Could not load that config.")
			return
		end

		ConfigNotify(
			'โหลด "'
				.. ConfigPicked
				.. '" แล้ว ปุ่มในเมนูและระบบที่กำลังรันเปลี่ยนตามทันที',
			'Loaded "' .. ConfigPicked .. '". Menu and running features switched over right away.'
		)
	end,
})

Tab:Button({
	Title = "tr:ConfigDelete",
	Desc = "tr:ConfigDeleteDesc",
	Callback = function()
		if ConfigPicked == "" then
			ConfigNotify("เลือกคอนฟิกก่อน", "Pick a config first.")
			return
		end

		if not ConfigRemove(ConfigPicked) then
			ConfigNotify("ลบคอนฟิกไม่สำเร็จ", "Could not delete that config.")
			return
		end

		ConfigNotify('ลบ "' .. ConfigPicked .. '" แล้ว', 'Deleted "' .. ConfigPicked .. '".')
		ConfigPicked = ""
		pcall(function()
			ConfigDropdown:Refresh(ConfigNames())
		end)
	end,
})

Tab:Button({
	Title = "tr:ConfigRefresh",
	Desc = "tr:ConfigRefreshDesc",
	Callback = function()
		pcall(function()
			ConfigDropdown:Refresh(ConfigNames())
		end)
	end,
})

local queueteleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
local TeleportCheck = false

while not Players.LocalPlayer do
	task.wait()
end

LocalPlayer.OnTeleport:Connect(function(State)
	pcall(function()
		if
			getgenv().ConfigurationTable
			and getgenv().ConfigurationTable.AutoExecutor
			and not TeleportCheck
			and queueteleport
		then
			TeleportCheck = true
			queueteleport(
				"loadstring(game:HttpGet('https://raw.githubusercontent.com/x2Kotaro/Venuz-hub/main/Loader.lua'))()"
			)
		end
	end)
end)

Window:SetToggleKey(Enum.KeyCode[getgenv().ConfigurationTable.MinimizeBind])
pcall(function()
	Window:SelectTab(1)
end)

WindUI:Notify({
	Title = "tr:ScriptLoader",
	Content = "tr:ScriptLoaded",
	Icon = VenuzIcon,
	Duration = 5,
})