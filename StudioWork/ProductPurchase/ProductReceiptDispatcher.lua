--!strict
-- Single owner of MarketplaceService.ProcessReceipt for the whole game.
--
-- Before this module existed, ProductPurchaseService AND PXItemService each set
-- MarketplaceService.ProcessReceipt directly. Roblox keeps only the LAST assignment --
-- whichever Script happened to run second silently replaced the first, so every
-- product the first script handled (nuke, random gun, riot, unjail, buying money with
-- Robux, gamepass gifts, or the PX shop items, depending on load order) stopped being
-- granted at all. Players were charged and got nothing; Roblox auto-refunds an
-- unclaimed receipt after a few days, but nothing tells them why it never arrived.
--
-- Every product now registers a handler here instead of touching ProcessReceipt
-- itself, and this module is the only place that assigns it. Register() warns loudly
-- if two callers ever claim the same product id again.
--
-- This is also the single place that fires the purchase effect: every product that
-- comes through here plays the same confetti burst + sound on a successful grant, so
-- every Robux purchase in the game feels like a purchase -- not just the two systems
-- (PrizeWheel, KillEffect) that happened to call it themselves before.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = ReplicatedStorage:WaitForChild("GameSettings"):WaitForChild("Events")
local confettiEvent = Events:FindFirstChild("CreateConfettis")
if not confettiEvent then
	confettiEvent = Instance.new("RemoteEvent")
	confettiEvent.Name = "CreateConfettis"
	confettiEvent.Parent = Events
end

local Dispatcher = {}

type Handler = (receiptInfo: any) -> Enum.ProductPurchaseDecision

local handlers: { [number]: Handler } = {}
local grantedReceipts: { [string]: boolean } = {}

-- Registers the handler that grants `productId`. Call once per product at script
-- load time (not inside ProcessReceipt) so every product is claimed before the first
-- purchase can arrive.
function Dispatcher.Register(productId: number, handler: Handler)
	if handlers[productId] then
		warn(("[ProductReceiptDispatcher] product %d registered twice -- the first handler is being replaced. This is exactly the bug this module exists to prevent; give the new product its own id instead."):format(productId))
	end
	handlers[productId] = handler
end

-- Plays the same purchase effect (confetti + sound) any successful grant should use.
-- Exposed too, for a handler that wants the effect somewhere other than right after
-- the grant (PrizeWheelService/KillEffectService time it to the reward reveal instead).
function Dispatcher.CelebrateGrant(player: Player?)
	if player and player.Parent then
		confettiEvent:FireClient(player)
	end
end

local function processReceipt(receiptInfo)
	-- Roblox retries an unresolved receipt, so a receipt already granted (server
	-- restarted before Roblox got the first PurchaseGranted, say) must not run the
	-- handler a second time.
	if grantedReceipts[receiptInfo.PurchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local handler = handlers[receiptInfo.ProductId]
	if not handler then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local ok, result = pcall(handler, receiptInfo)
	if not ok then
		warn(("[ProductReceiptDispatcher] handler for product %d errored: %s"):format(receiptInfo.ProductId, tostring(result)))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if result == Enum.ProductPurchaseDecision.PurchaseGranted then
		grantedReceipts[receiptInfo.PurchaseId] = true
		Dispatcher.CelebrateGrant(Players:GetPlayerByUserId(receiptInfo.PlayerId))
	end

	return result
end

MarketplaceService.ProcessReceipt = processReceipt

-- ProcessReceipt is write-only once assigned (Roblox will not read it back even to
-- the script that set it), so this is the only lever left for an admin command or a
-- unit test that wants to drive a receipt through without a real purchase.
Dispatcher._simulateReceipt = processReceipt

return Dispatcher
