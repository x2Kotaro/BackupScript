local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local nukeSystem = require(script:WaitForChild("nukeModule"))
local riotSystem = require(script:WaitForChild("riotModule"))
local GameSettings = ReplicatedStorage:WaitForChild("GameSettings"):WaitForChild("Events")
local AlreadyOwnRankGPRE = GameSettings:WaitForChild("AlreadyOwnRankGP")
local GunsFolder = script:WaitForChild("Guns")

local Config = require(ReplicatedStorage.GameSettings.Groups.MapConfig)
local ProductReceiptDispatcher = require(script.Parent.Parent.Core.ProductReceiptDispatcher)

_G.NukeLaunch = function()
	if not nukeSystem.nukeEnabled then
		task.spawn(function() pcall(nukeSystem.Launch) end)
	end
end
_G.NukeAbort = function()
	task.spawn(function() pcall(nukeSystem.Abort) end)
end
_G.RiotStart = function()
	task.spawn(function() pcall(riotSystem.startRiot) end)
end
_G.RiotEnd = function()
	task.spawn(function() pcall(riotSystem.endRiot) end)
end

local function giveRandomGun(player)
	local backpack = player:WaitForChild("Backpack")
	local char = player.Character or player.CharacterAdded:Wait()
	local availableGuns = {}
	for _, gun in ipairs(GunsFolder:GetChildren()) do
		if not (backpack:FindFirstChild(gun.Name) or char:FindFirstChild(gun.Name) or player.StarterGear:FindFirstChild(gun.Name)) then
			table.insert(availableGuns, gun)
		end
	end
	if #availableGuns == 0 then return end
	availableGuns[math.random(#availableGuns)]:Clone().Parent = backpack
end

local NUKE_PRODUCT = Config.DEV_PRODUCTS.NUKE
local RANDOM_GUN_PRODUCT = Config.DEV_PRODUCTS.RANDOM_GUN
local RIOT_PRODUCT = Config.DEV_PRODUCTS.RIOT
local UNJAIL_PRODUCT = Config.DEV_PRODUCTS.UNJAIL
local PRIZE_WHEEL_SPIN_PRODUCT = Config.PRIZE_WHEEL and Config.PRIZE_WHEEL.SPIN_PRODUCT_ID or 0
local KILL_EFFECT_PRODUCT = Config.AIRDROP and Config.AIRDROP.ROBUX_PRODUCT_ID or 0

if KILL_EFFECT_PRODUCT ~= 0 then
	local taken = {
		[NUKE_PRODUCT] = "NUKE",
		[RANDOM_GUN_PRODUCT] = "RANDOM_GUN",
		[RIOT_PRODUCT] = "RIOT",
		[UNJAIL_PRODUCT] = "UNJAIL",
		[PRIZE_WHEEL_SPIN_PRODUCT] = "PRIZE_WHEEL_SPIN",
	}
	local clash = taken[KILL_EFFECT_PRODUCT]
	if clash then
		warn(("[Airdrop] ROBUX_PRODUCT_ID %d already belongs to %s - airdrop Robux purchases disabled. Create a separate developer product."):format(KILL_EFFECT_PRODUCT, clash))
		KILL_EFFECT_PRODUCT = 0
	end
end

local ProductActions = {
	[NUKE_PRODUCT] = function(receiptInfo)
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player or nukeSystem.nukeEnabled then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		task.spawn(function() pcall(nukeSystem.Launch) end)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end,

	[RANDOM_GUN_PRODUCT] = function(receiptInfo)
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
		pcall(function() giveRandomGun(player) end)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end,

	[RIOT_PRODUCT] = function(receiptInfo)
		task.spawn(function() pcall(riotSystem.startRiot) end)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end,

	[PRIZE_WHEEL_SPIN_PRODUCT] = function(receiptInfo)
		if PRIZE_WHEEL_SPIN_PRODUCT == 0 then return Enum.ProductPurchaseDecision.NotProcessedYet end
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
		local count = (Config.PRIZE_WHEEL and Config.PRIZE_WHEEL.SPINS_PER_PURCHASE) or 5
		if _G.GrantPrizeWheelSpins and _G.GrantPrizeWheelSpins(player, count) then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end,

	[KILL_EFFECT_PRODUCT] = function(receiptInfo)
		if KILL_EFFECT_PRODUCT == 0 then return Enum.ProductPurchaseDecision.NotProcessedYet end
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
		local rolls = (Config.AIRDROP and Config.AIRDROP.ROBUX_ROLLS) or 1
		if _G.GrantKillEffectRoll and _G.GrantKillEffectRoll(player, rolls) then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end,

	[UNJAIL_PRODUCT] = function(receiptInfo)
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if _G.UnjailPlayer then
			_G.UnjailPlayer(player)
		else
			pcall(function()
				game:GetService("DataStoreService"):GetDataStore("Prisoner"):RemoveAsync(player.UserId)
			end)
			task.wait(0.5)
			player:SetAttribute("jail", 0)
			player:SetAttribute("jailReason", nil)
			player:SetAttribute("jailOfficer", nil)
			if player:FindFirstChild("Detained") then player.Detained.Value = false end
			if player:FindFirstChild("Officer") then player.Officer.Value = nil end
			local teams = game:GetService("Teams")
			local newTeam = teams:FindFirstChild(Config.DEFAULT_TEAM)
			if newTeam then
				player.Team = newTeam
				player.Neutral = false
			end
			task.wait(0.3)
			player:LoadCharacter()
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end,
}

-- Registered with the shared dispatcher instead of touching ProcessReceipt directly --
-- see ProductReceiptDispatcher for why (this file used to set it outright, and
-- whichever of this script or PXItemService loaded second silently won, killing every
-- product the other one handled). Purchase-effect confetti fires automatically there
-- on every PurchaseGranted, so none of these handlers need to trigger it themselves.
for productId, action in pairs(ProductActions) do
	if productId ~= 0 then
		ProductReceiptDispatcher.Register(productId, function(receiptInfo)
			local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
			if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
			return action(receiptInfo)
		end)
	end
end

if Config.MONEY_PRODUCT_IDS then
	for productId, moneyAmount in pairs(Config.MONEY_PRODUCT_IDS) do
		ProductReceiptDispatcher.Register(productId, function(receiptInfo)
			local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
			if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
			local leaderstats = player:FindFirstChild("leaderstats")
			local money = leaderstats and leaderstats:FindFirstChild("เงิน")
			if money then money.Value = money.Value + moneyAmount end
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end)
	end
end

if Config.GAMEPASS_GIFT_PRODUCT_IDS then
	for gpId, giftProdId in pairs(Config.GAMEPASS_GIFT_PRODUCT_IDS) do
		ProductReceiptDispatcher.Register(giftProdId, function(receiptInfo)
			if _G.ProcessGamePassGift then
				return _G.ProcessGamePassGift(receiptInfo)
			end
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end)
	end
end

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
	if not player.Character or not player:FindFirstChild("Backpack") then player.CharacterAdded:Wait() end
	local playerTeamName = player.Team and player.Team.Name or ""
	if prompt:GetAttribute("GunPrompt") then
		if Config.NON_ARMED_TEAMS[playerTeamName] then
			return
		end
		MarketplaceService:PromptProductPurchase(player, RANDOM_GUN_PRODUCT)
	elseif prompt:GetAttribute("NukePrompt") then
		MarketplaceService:PromptProductPurchase(player, NUKE_PRODUCT)
	elseif prompt:GetAttribute("RiotPrompt") then
		MarketplaceService:PromptProductPurchase(player, RIOT_PRODUCT)
	end
end)

AlreadyOwnRankGPRE.OnServerEvent:Connect(function(player, gamepassId)
	if typeof(gamepassId)~="number" then return end
	local success, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
	end)
	if success and owns then
		pcall(function() giveRandomGun(player) end)
	end
end)

Players.PlayerAdded:Connect(function(player)
	nukeSystem.SyncPlayer(player)
end)