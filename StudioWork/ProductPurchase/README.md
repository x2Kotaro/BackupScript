# Robux purchase effect + the ProcessReceipt collision it uncovered

The ask was: play a confetti burst + sound every time a Robux Product finishes
paying out, everywhere that happens in the game. Doing that safely first required
fixing something the search turned up: two scripts were fighting over the same
Roblox callback, and one of them was silently losing.

## The bug

`MarketplaceService.ProcessReceipt` is a single callback -- Roblox keeps only the
*last* assignment. Two Scripts were each doing `MarketplaceService.ProcessReceipt =
function(receiptInfo) ... end` outright:

- `ServerScriptService.Combat.ProductPurchaseService` -- nuke, random gun, riot,
  unjail-via-Robux, prize wheel spin bundles, airdrop kill-effect rolls, buying money
  with Robux, gamepass gifts.
- `ServerScriptService.Core.PXItemService` -- the five PX shop items (jetpack, sign,
  machete, quasar, taser).

Whichever Script's top-level code ran second replaced the first's callback entirely.
Every product the *first* script handled stopped being granted -- a player would pay
real Robux, Roblox would call the surviving ProcessReceipt, get `NotProcessedYet`
forever (nothing recognised the product id), and the purchase would eventually
auto-refund with no explanation. Given this place's Script load order, PXItemService
was very likely the one that landed last, meaning nuke/random gun/riot/unjail/prize
wheel/airdrop/buy-money/gamepass-gift purchases were probably all silently dead.

## The fix

`ProductReceiptDispatcher` (ModuleScript, `ServerScriptService.Core`) is now the only
thing that touches `MarketplaceService.ProcessReceipt`. Every product registers a
handler with it instead:

```lua
ProductReceiptDispatcher.Register(productId, function(receiptInfo)
	-- ... grant the product, return a Enum.ProductPurchaseDecision
end)
```

`Register` warns loudly if the same product id is claimed twice, so this exact bug
(two systems silently sharing one id) can't happen again without at least a console
warning pointing at it. The dispatcher also keeps the receipt-dedupe safeguard
(`grantedReceipts`, keyed by `PurchaseId`) that PXItemService used to have on its own
-- now every product gets it, not just the PX shop items.

Both `PXItemService` and `ProductPurchaseService` were rewritten to register instead
of assigning `ProcessReceipt` directly. Their granting logic is otherwise unchanged.

## The effect

`ProductReceiptDispatcher.CelebrateGrant(player)` fires `CreateConfettis` at the
player -- the same RemoteEvent `PrizeWheelService` and `KillEffectService` already
used to celebrate a win. `processReceipt` calls it automatically after any handler
returns `PurchaseGranted`, so every Robux product in the game gets the same
confetti + sound the moment it's granted, with nothing to add per-product.

Verified live: fired `CreateConfettis` at a real player in Play mode and confirmed
the client's `Confetti` LocalScript actually receives and handles it (client-side
listener fired exactly once per server fire).

Registration itself was verified by instrumenting `Register` and reading
`LogService:GetLogHistory()` from inside the running server (calling back into the
dispatcher via a fresh `require()` from outside the live server script doesn't share
its module cache in this tool, so testing has to happen from inside a real script or
by reading the log the real scripts produced) -- 26 products registered cleanly across
both scripts, all going through the one dispatcher.

## Two content bugs this surfaced, not fixed here

**`PRIZE_WHEEL.SPIN_PRODUCT_ID` and `AIRDROP.ROBUX_PRODUCT_ID` each reuse a
`MONEY_PRODUCT_IDS` id:**

```
Config.PRIZE_WHEEL.SPIN_PRODUCT_ID = 3601873409   -- == MONEY_PRODUCT_IDS[3601873409] (50,000 บาท)
Config.AIRDROP.ROBUX_PRODUCT_ID    = 3601873405   -- == MONEY_PRODUCT_IDS[3601873405] (100,375 บาท)
```

Two different Developer Products in the Creator Dashboard were apparently pointed at
the same id as two of the "buy money" packages. Before this fix, which one a player
actually got was decided by undefined dictionary iteration order -- could go either
way, including possibly changing between server restarts. After this fix it's at
least deterministic (money always wins, a warning prints), but that just means the
Prize Wheel spin bundle and the Airdrop kill-effect roll can currently never be
bought with Robux at all -- paying for either one just adds money instead. Fixing
this needs a real decision only the game's owner can make (create a separate
Developer Product for one or both), so it's flagged rather than guessed at.

**A third, unrelated dead Robux prompt:** `Workspace.โมเดลทั้งหมด.ของตกแต่ง.Model.Chess.Chess
Handler` calls `MarketplaceService:PromptProductPurchase(pl, 937144134)`. That id
isn't in `DEV_PRODUCTS`, `PX_ITEMS`, `MONEY_PRODUCT_IDS`, or `GAMEPASS_GIFT_PRODUCT_IDS`
-- nothing in the game has ever granted it. Not touched here since it's a chess
minigame perk with no visible spec for what it should give.
