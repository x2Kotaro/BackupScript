local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local ProductReceiptDispatcher = require(script.Parent.ProductReceiptDispatcher)

local Config = require(ReplicatedStorage.GameSettings.Groups.MapConfig)
local pxConfig = Config.PX_SHOP
local itemConfig = Config.PX_ITEMS
if not pxConfig or not itemConfig or not itemConfig.ENABLED then return end

local Events = ReplicatedStorage.GameSettings.Events
local Notification = Events:FindFirstChild("Notification")

local jetpackEvent = Events:FindFirstChild("PXJetpack")
if not jetpackEvent then
	jetpackEvent = Instance.new("RemoteEvent")
	jetpackEvent.Name = "PXJetpack"
	jetpackEvent.Parent = Events
end

local function ensureEvent(name)
	local event = Events:FindFirstChild(name)
	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = Events
	end
	return event
end

local openShopEvent = ensureEvent("PXItemShop")
local buyEvent = ensureEvent("PXBuyItem")

local shopFolder = workspace:WaitForChild(pxConfig.FOLDER_NAME, 60)
if not shopFolder then return end
local itemShop = shopFolder:WaitForChild("ItemShop", 30)
if not itemShop then return end

local itemFolder = ServerStorage:FindFirstChild(itemConfig.FOLDER)

local function notify(player, message)
	if Notification then Notification:FireClient(player, message) end
end

local function formatMoney(amount)
	local digits = tostring(math.floor(amount))
	local formatted = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	formatted = formatted:gsub("^,", "")
	return formatted
end

local function sourceTool(itemDefinition)
	if itemDefinition.ToolFrom == "Tools" then
		local folder = ServerStorage:FindFirstChild("Tools")
		return folder and folder:FindFirstChild(itemDefinition.ToolName or itemDefinition.Name)
	end
	return itemFolder and itemFolder:FindFirstChild(itemDefinition.Name)
end

local function hasTool(player, toolName)
	local backpack = player:FindFirstChild("Backpack")
	if backpack and backpack:FindFirstChild(toolName) then return true end
	local character = player.Character
	if character and character:FindFirstChild(toolName) then return true end
	return false
end

local previewConfig = itemConfig.PREVIEW or {}

local function inShopRange(player)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end
	local shopPosition = itemShop:GetPivot().Position
	return (rootPart.Position - shopPosition).Magnitude <= (previewConfig.BUY_DISTANCE or 60)
end

local function purchase(player, itemKey)
	local itemDefinition = itemKey and itemConfig.ITEMS[itemKey]
	if not itemDefinition then return end
	if itemDefinition.Hidden then return end
	if not inShopRange(player) then return end

	local tool = sourceTool(itemDefinition)
	if not tool then
		notify(player, string.format(itemConfig.MSG_NO_STOCK or "ยังไม่มีสินค้า %s ในระบบ", itemDefinition.Name))
		return
	end

	if hasTool(player, tool.Name) then
		notify(player, string.format(itemConfig.MSG_ALREADY, itemDefinition.Name))
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local money = leaderstats and leaderstats:FindFirstChild("เงิน")
	if not money then return end
	if money.Value < itemDefinition.Price then
		notify(player, string.format(itemConfig.MSG_NO_MONEY, formatMoney(itemDefinition.Price)))
		return
	end

	money.Value -= itemDefinition.Price
	local clone = tool:Clone()
	clone.Parent = player.Backpack
	notify(player, string.format(itemConfig.MSG_BOUGHT, itemDefinition.Name))
end

buyEvent.OnServerEvent:Connect(function(player, itemKey)
	if typeof(itemKey) ~= "string" then return end
	purchase(player, itemKey)
end)

local function grantRobuxPurchase(player, itemKey)
	local itemDefinition = itemConfig.ITEMS[itemKey]
	if not itemDefinition then return false end
	local tool = sourceTool(itemDefinition)
	if not tool then return false end
	local clone = tool:Clone()
	clone.Parent = player.Backpack
	notify(player, string.format(itemConfig.MSG_BOUGHT, itemDefinition.Name))
	return true
end

-- Registered with the shared dispatcher instead of touching ProcessReceipt directly --
-- see ProductReceiptDispatcher for why. Purchase-effect confetti fires automatically
-- there on every PurchaseGranted, so it is not repeated here.
for itemKey, itemDefinition in pairs(itemConfig.ITEMS) do
	if itemDefinition.ProductId and itemDefinition.ProductId > 0 then
		ProductReceiptDispatcher.Register(itemDefinition.ProductId, function(receiptInfo)
			local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
			if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
			if not grantRobuxPurchase(player, itemKey) then
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end)
	end
end

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
	if not prompt:IsDescendantOf(itemShop) then return end
	if not inShopRange(player) then return end
	openShopEvent:FireClient(player, true)
end)

jetpackEvent.OnServerEvent:Connect(function(player, state)
	local character = player.Character
	if not character then return end
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool then return end
	local handle = tool:FindFirstChild("Handle")
	if not handle then return end
	for _, attachment in ipairs(handle:GetChildren()) do
		if attachment:IsA("Attachment") then
			for _, emitter in ipairs(attachment:GetChildren()) do
				if emitter:IsA("ParticleEmitter") then
					emitter.Enabled = state == true
				end
			end
		end
	end
end)
