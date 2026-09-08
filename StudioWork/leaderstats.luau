local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local CashStore = DataStoreService:GetDataStore("Cash")
local LevelStore = DataStoreService:GetDataStore("Levels")

local PAYCHECK_TIME = 600
local PAYCHECK_AMOUNT = 1000
local EXP_TIMER = 60
local EXP_GAIN = 100
local BASE_EXP_NEED = 1000
local EXP_ADD_PER_LEVEL = 100
local AUTOSAVE_INTERVAL = 300
local SAVE_COOLDOWN = 5
local MAX_SAVE_RETRIES = 3

local playerTimers = {}
local lastSaveTime = {}
local sessionData = {}

local function getExpNeed(level)
	return BASE_EXP_NEED + (level * EXP_ADD_PER_LEVEL)
end

local function calculateLevelFromTotalExp(totalExp)
	local level = 0
	local expUsed = 0

	while true do
		local expNeeded = getExpNeed(level)
		if expUsed + expNeeded > totalExp then
			break
		end
		expUsed += expNeeded
		level += 1
	end

	local currentExp = totalExp - expUsed
	return level, currentExp
end

local function savePlayerData(player, force)
	if not force then
		local lastSave = lastSaveTime[player.UserId] or 0
		if os.clock() - lastSave < SAVE_COOLDOWN then
			return false
		end
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local dataFolder = player:FindFirstChild("Data")
	if not leaderstats or not dataFolder then
		return false
	end

	local cashValue = leaderstats:FindFirstChild("เงิน")
	local experienceValue = dataFolder:FindFirstChild("Experience")
	if not cashValue or not experienceValue then
		return false
	end

	if sessionData[player.UserId] then
		if cashValue.Value == 0 and sessionData[player.UserId].cash > 0 then
			return false
		end
		if experienceValue.Value == 0 and sessionData[player.UserId].experience > 0 then
			return false
		end
	end

	lastSaveTime[player.UserId] = os.clock()

	local cashSaved = false
	local expSaved = false

	for _ = 1, MAX_SAVE_RETRIES do
		if not cashSaved then
			local success = pcall(function()
				CashStore:SetAsync("Player_" .. player.UserId, cashValue.Value)
			end)
			cashSaved = success
		end

		if not expSaved then
			local success = pcall(function()
				LevelStore:SetAsync("Player_" .. player.UserId, experienceValue.Value)
			end)
			expSaved = success
		end

		if cashSaved and expSaved then
			sessionData[player.UserId] = {
				cash = cashValue.Value,
				experience = experienceValue.Value
			}
			return true
		end

		task.wait(1)
	end

	return cashSaved and expSaved
end

_G.SetLevel = function(player, level)
	local leaderstats = player:FindFirstChild("leaderstats")
	local dataFolder = player:FindFirstChild("Data")
	if not (leaderstats and dataFolder) then return end
	local Level = leaderstats:FindFirstChild("เลเวล")
	local Experience = dataFolder:FindFirstChild("Experience")
	local Exp = dataFolder:FindFirstChild("Exp")
	local ExpNeed = dataFolder:FindFirstChild("ExpNeed")
	if not (Level and Experience and Exp and ExpNeed) then return end
	local totalExp = 0
	for i = 0, level - 1 do
		totalExp += getExpNeed(i)
	end
	Experience.Value = totalExp
	Level.Value = level
	Exp.Value = 0
	ExpNeed.Value = getExpNeed(level)
	savePlayerData(player, true)
end

Players.PlayerAdded:Connect(function(player)
	repeat task.wait() until player:FindFirstChild("leaderstats")

	local leaderstats = player:FindFirstChild("leaderstats") or Instance.new("Folder", player)
	leaderstats.Name = "leaderstats"

	local dataFolder = player:FindFirstChild("Data") or Instance.new("Folder", player)
	dataFolder.Name = "Data"

	local loadedCash = 0
	local loadedExperience = 0

	pcall(function()
		local data = CashStore:GetAsync("Player_" .. player.UserId)
		if type(data) == "number" then
			loadedCash = data
		end
	end)

	pcall(function()
		local data = LevelStore:GetAsync("Player_" .. player.UserId)
		if type(data) == "number" then
			loadedExperience = data
		end
	end)

	sessionData[player.UserId] = {
		cash = loadedCash,
		experience = loadedExperience
	}

	local Cash = leaderstats:FindFirstChild("เงิน") or Instance.new("IntValue", leaderstats)
	Cash.Name = "เงิน"
	Cash.Value = loadedCash

	local Level = leaderstats:FindFirstChild("เลเวล") or Instance.new("IntValue", leaderstats)
	Level.Name = "เลเวล"

	local Exp = dataFolder:FindFirstChild("Exp") or Instance.new("IntValue", dataFolder)
	Exp.Name = "Exp"

	local ExpNeed = dataFolder:FindFirstChild("ExpNeed") or Instance.new("IntValue", dataFolder)
	ExpNeed.Name = "ExpNeed"

	local Experience = dataFolder:FindFirstChild("Experience") or Instance.new("IntValue", dataFolder)
	Experience.Name = "Experience"
	Experience.Value = loadedExperience

	local calculatedLevel, currentExp = calculateLevelFromTotalExp(loadedExperience)
	Level.Value = calculatedLevel
	Exp.Value = currentExp
	ExpNeed.Value = getExpNeed(calculatedLevel)

	playerTimers[player.UserId] = {
		paycheckTimer = 0,
		expTimer = 0,
		autoSaveTimer = 0
	}
end)

Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player, true)
	playerTimers[player.UserId] = nil
	lastSaveTime[player.UserId] = nil
	sessionData[player.UserId] = nil
end)

RunService.Heartbeat:Connect(function(deltaTime)
	for _, player in ipairs(Players:GetPlayers()) do
		local timers = playerTimers[player.UserId]
		if not timers then continue end

		local leaderstats = player:FindFirstChild("leaderstats")
		local dataFolder = player:FindFirstChild("Data")
		if not leaderstats or not dataFolder then continue end

		local Cash = leaderstats:FindFirstChild("เงิน")
		local Level = leaderstats:FindFirstChild("เลเวล")
		local Exp = dataFolder:FindFirstChild("Exp")
		local ExpNeed = dataFolder:FindFirstChild("ExpNeed")
		local Experience = dataFolder:FindFirstChild("Experience")
		if not (Cash and Level and Exp and ExpNeed and Experience) then continue end

		timers.paycheckTimer += deltaTime
		if timers.paycheckTimer >= PAYCHECK_TIME then
			timers.paycheckTimer = 0
			Cash.Value += PAYCHECK_AMOUNT
			pcall(function()
				game.ReplicatedStorage.GameSettings.Assets.Notifycation.Notification:FireClient(
					player,
					"คุณ " .. player.Name .. " ได้รับเช็คเงินเดือนเรียบร้อยแล้ว"
				)
			end)
		end

		timers.expTimer += deltaTime
		if timers.expTimer >= EXP_TIMER then
			timers.expTimer = 0
			Exp.Value += EXP_GAIN
			Experience.Value += EXP_GAIN

			while Exp.Value >= ExpNeed.Value do
				Exp.Value -= ExpNeed.Value
				Level.Value += 1
				ExpNeed.Value = getExpNeed(Level.Value)
			end
		end

		timers.autoSaveTimer += deltaTime
		if timers.autoSaveTimer >= AUTOSAVE_INTERVAL then
			timers.autoSaveTimer = 0
			task.spawn(function()
				savePlayerData(player, false)
			end)
		end
	end
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		savePlayerData(player, true)
	end
	task.wait(3)
end)