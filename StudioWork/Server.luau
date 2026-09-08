local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage.GameSettings.Modules.ProductID)

local PlayerDataStore = DataStoreService:GetDataStore(Config.DATA_STORE_KEY)

local PlayerDataCache = {}

local PendingGifts = {}

local GamePassRewards = {
	[1675000165] = { "M82A1" },
	[1650209782] = { "M82A1" },

	[1675116139] = { "SPAS-12" },
	[1650506387] = { "SPAS-12" },

	[1675022037] = { "Colt M5" },
	[1650203779] = { "Colt M5" },

	[1530619889] = { "M134 Minigun" },
	[1018243769] = { "M134 Minigun" },

	[1675209836] = { "SV-98M" },
	[1649924164] = { "SV-98M" },

	[1675057976] = { "M249" },
	[1650187849] = { "M249" },

	[1675227590] = { "M4A1 Street Sweeper" },
	[1650099990] = { "M4A1 Street Sweeper" },

	[1675016166] = { "มอเตอร์ไซค์" },
	[1650433603] = { "มอเตอร์ไซค์" },

	[1675442591] = { "HK416A5" },
	[1649912008] = { "HK416A5" },
}

local GetPlayerDataRemote = Instance.new("RemoteFunction")
GetPlayerDataRemote.Name = "GetPlayerData"
GetPlayerDataRemote.Parent =  ReplicatedStorage.GameSettings.Events

local UpdateDataRemote = Instance.new("RemoteEvent")
UpdateDataRemote.Name = "UpdateData"
UpdateDataRemote.Parent =  ReplicatedStorage.GameSettings.Events

local SetGiftPlayerRemote = Instance.new("RemoteEvent")
SetGiftPlayerRemote.Name = "SetGiftPlayer"
SetGiftPlayerRemote.Parent =  ReplicatedStorage.GameSettings.Events

function getDefaultData()
	return {
		OwnedGamePass = {},
		GiftGamepass = {},
		Date = {},
		Time = {}
	}
end

function loadPlayerData(player)
	local userId = player.UserId
	local success, data = pcall(function()
		return PlayerDataStore:GetAsync(userId)
	end)

	if success and data then
		PlayerDataCache[userId] = data
	else
		PlayerDataCache[userId] = getDefaultData()
	end

	local playerData = PlayerDataCache[userId]
	local needSave = false

	for gamePassId, _ in pairs(GamePassRewards) do
		local ownsPass = false

		pcall(function()
			ownsPass = MarketplaceService:UserOwnsGamePassAsync(userId, gamePassId)
		end)

		if ownsPass and not playerData.OwnedGamePass[tostring(gamePassId)] then
			playerData.OwnedGamePass[tostring(gamePassId)] = true
			playerData.Date[tostring(gamePassId)] = os.date("%Y-%m-%d")
			playerData.Time[tostring(gamePassId)] = os.time()
			needSave = true
		end
	end

	if needSave then
		savePlayerData(player)
	end

	return PlayerDataCache[userId]
end

function savePlayerData(player)
	local userId = player.UserId
	local data = PlayerDataCache[userId]

	if not data then return false end

	local success, err = pcall(function()
		PlayerDataStore:SetAsync(userId, data)
	end)

	if success then
		return true
	else
		return false
	end
end

function hasGamePass(player, gamePassId)
	local userId = player.UserId
	local data = PlayerDataCache[userId]

	if not data then return false end

	local id = tostring(gamePassId)

	if data.OwnedGamePass[id] == true or data.GiftGamepass[id] == true then
		return true
	end

	local ownsPass = false
	pcall(function()
		ownsPass = MarketplaceService:UserOwnsGamePassAsync(userId, gamePassId)
	end)

	return ownsPass
end

function grantGamePass(player, gamePassId, isGift)
	local userId = player.UserId
	local data = PlayerDataCache[userId]

	if not data then return false end

	local id = tostring(gamePassId)

	if isGift then
		data.GiftGamepass[id] = true
		data.Date[id] = os.date("%Y-%m-%d")
		data.Time[id] = os.time()
	else
		data.OwnedGamePass[id] = true
		data.Date[id] = os.date("%Y-%m-%d")
		data.Time[id] = os.time()
	end

	player:SetAttribute(gamePassId, true)

	savePlayerData(player)

	return true
end

GetPlayerDataRemote.OnServerInvoke = function(player)
	local userId = player.UserId
	return PlayerDataCache[userId] or getDefaultData()
end

UpdateDataRemote.OnServerEvent:Connect(function(player, dataType, key, value)
	local userId = player.UserId
	local data = PlayerDataCache[userId]

	if not data then return end

	if data[dataType] then
		data[dataType][key] = value
		savePlayerData(player)
	end
end)

SetGiftPlayerRemote.OnServerEvent:Connect(function(player, targetPlayer, gamePassId)
	if not targetPlayer or not targetPlayer:IsA("Player") then
		warn("❌ Target player ไม่ถูกต้อง")
		return
	end

	PendingGifts[player.UserId] = {
		TargetPlayer = targetPlayer,
		GamePassId = gamePassId
	}

end)

_G.ProcessGamePassGift = function(receiptInfo)
	local userId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId
	local player = Players:GetPlayerByUserId(userId)

	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local gamePassId = nil
	for gpId, giftProdId in pairs(Config.GAMEPASS_GIFT_PRODUCT_IDS) do
		if giftProdId == productId then
			gamePassId = tonumber(gpId)
			break
		end
	end

	if gamePassId then
		local giftInfo = PendingGifts[userId]

		if giftInfo and giftInfo.TargetPlayer and giftInfo.GamePassId == gamePassId then
			local targetPlayer = giftInfo.TargetPlayer

			if targetPlayer and targetPlayer.Parent then
				grantGamePass(targetPlayer, gamePassId, true)
				PendingGifts[userId] = nil
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end
		end
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

local function giveTools(player, toolList)
	local team = player.Team
	if team and (team.Name == "ประชาชน" or team.Name == "นักโทษ") then
		return
	end

	for _, toolName in ipairs(toolList) do
		local tool = ServerStorage.Tools:FindFirstChild(toolName)
		if tool and not player.Backpack:FindFirstChild(toolName) then
			tool:Clone().Parent = player.Backpack
		end
	end
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	if not wasPurchased then return end

	if hasGamePass(player, gamePassId) then
		return
	end

	grantGamePass(player, gamePassId, false)

	player:SetAttribute(gamePassId, true)

	local rewards = GamePassRewards[gamePassId]
	if rewards then
		giveTools(player, rewards)
	end
end)

_G.GrantGamePass = function(player, gamePassId, isGift)
	return grantGamePass(player, gamePassId, isGift)
end

local function giveSignTool(player)
	task.spawn(function()
		task.wait(1)

		if not player or not player.Parent then
			warn("[ป้าย] ผู้เล่นออกไปแล้ว ไม่ต้องแจก")
			return
		end

		local toolName = "ป้าย"

		local success, owned = pcall(function()
			return hasGamePass(player, 1709248065)
		end)

		if success and owned then
			toolName = "ป้ายยักษ์"
		end

		print("[ป้าย] กำลังแจก \"" .. toolName .. "\" ให้ " .. player.Name)

		local backpack = player:FindFirstChild("Backpack")
		if not backpack then
			warn("[ป้าย] ไม่เจอ Backpack ของ " .. player.Name)
			return
		end

		if backpack:FindFirstChild(toolName) then
			print("[ป้าย] " .. player.Name .. " มี \"" .. toolName .. "\" อยู่แล้ว")
			return
		end

		-- เช็คว่า Tool ติดอยู่กับตัวละครหรือเปล่า (ถือในมืออยู่)
		local character = player.Character
		if character and character:FindFirstChild(toolName) then
			print("[ป้าย] " .. player.Name .. " ถือ \"" .. toolName .. "\" อยู่แล้ว")
			return
		end

		local signTool = ServerStorage.Tools:FindFirstChild(toolName)
		if signTool then
			signTool:Clone().Parent = backpack
			print("[ป้าย] ✅ แจก \"" .. toolName .. "\" ให้ " .. player.Name .. " สำเร็จ")
		else
			warn("[ป้าย] ❌ หา Tool \"" .. toolName .. "\" ไม่เจอใน ServerStorage.Tools!")
			-- แสดง list ของ Tools ทั้งหมดเพื่อ Debug
			print("[ป้าย] Tools ที่มีใน ServerStorage.Tools:")
			for _, tool in ipairs(ServerStorage.Tools:GetChildren()) do
				print("  - " .. tool.Name)
			end
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	loadPlayerData(player)

	local data = PlayerDataCache[player.UserId]
	if not data then return end

	local function processGamepassTable(tbl)
		for gamePassId, owned in pairs(tbl or {}) do
			if owned then
				gamePassId = tonumber(gamePassId)
				player:SetAttribute(gamePassId, true)

				local rewards = GamePassRewards[gamePassId]
				if rewards then
					giveTools(player, rewards)
				end
			end
		end
	end

	processGamepassTable(data.OwnedGamePass)
	processGamepassTable(data.GiftGamepass)

	player.CharacterAdded:Connect(function(character)
		-- แจกป้ายให้ทุกคน
		giveSignTool(player)

		local team = player.Team
		if team and (team.Name == "ประชาชน" or team.Name == "นักโทษ") then
			return
		end

		for gamePassId, rewards in pairs(GamePassRewards) do
			if player:GetAttribute(gamePassId) then
				giveTools(player, rewards)
			end
		end
	end)

	-- กรณีที่ตัวละครเกิดขึ้นก่อนที่ CharacterAdded จะถูก Connect (Race Condition)
	if player.Character then
		print("[ป้าย] ตัวละครของ " .. player.Name .. " เกิดขึ้นแล้วก่อน Connect — แจกป้ายเลย")
		giveSignTool(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)

	PendingGifts[player.UserId] = nil

	task.wait(1)
	PlayerDataCache[player.UserId] = nil
end)