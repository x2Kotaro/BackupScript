-- case_rollback_sim.lua
-- จำลอง Case Purchase Rollback (client-only, รันใน terminal)
-- วิธีรัน: lua case_rollback_sim.lua

-- ============================================================
-- CONFIG (จำลอง toggle + dropdown)
-- ============================================================
local Config = {
    -- === TOGGLE (true/false) ===
    ENABLE_EXPLOIT_SIM   = true,   -- เปิด/ปิดจำลอง exploit
    PERSIST_ON_SPEND     = false,  -- หัก gems แล้ว save ทันทีหรือไม่
    AUTO_RECONCILE       = false,  -- reconcile ตอน disconnect หรือไม่
    SAVE_ON_LEAVE        = false,  -- save ตอน PlayerRemoving หรือไม่ (โหมดช่องโหว่ = false)

    -- === DROPDOWN (string) ===
    -- "normal" | "disconnect_during_spin" | "disconnect_before_award" | "reconcile_test"
    SIM_MODE             = "disconnect_during_spin",

    -- === DROPDOWN (string) ===
    -- "Case1_Starter" | "Case2_Rare" | "Case3_Legendary"
    TEST_CASE            = "Case2_Rare",
}

-- ============================================================
-- MOCK SERVER STATE (ในเครื่องเดียว)
-- ============================================================
local Server = {
    players = {},        -- [name] = { gems, inventory }
    pendingTxn = {},     -- [txnId] = { user, cosmetic, rarity, committed }
    remotes = {},        -- mock RemoteEvent
}

local CASES = {
    Case1_Starter   = { cost = 100,  pool = { {name="Hat_Common",  rarity="Common"} } },
    Case2_Rare      = { cost = 500,  pool = { {name="Wings_Rare",  rarity="Rare"} } },
    Case3_Legendary = { cost = 2000, pool = { {name="Aura_Legend", rarity="Legendary"} } },
}

-- ============================================================
-- MOCK REMOTE EVENT
-- ============================================================
local function makeRemote(name)
    local r = { name = name, _handlers = {}, _clientHandlers = {} }
    function r:FireServer(...)
        for _, h in ipairs(self._handlers) do h(...) end
    end
    function r:OnServerEvent(h)
        table.insert(self._handlers, h)
    end
    function r:FireClient(plr, ...)
        for _, h in ipairs(self._clientHandlers) do h(plr, ...) end
    end
    function r:OnClientEvent(h)
        table.insert(self._clientHandlers, h)
    end
    return r
end

Server.remotes.purchaseCase       = makeRemote("purchaseCase")
Server.remotes.casePurchaseResult = makeRemote("casePurchaseResult")
Server.remotes.awardCaseCosmetic  = makeRemote("awardCaseCosmetic")

-- ============================================================
-- HELPERS
-- ============================================================
local function log(tag, msg)
    print(("[%s] %s"):format(tag, msg))
end

local function now()
    return os.time()
end

local function randomId()
    return ("txn_%d_%d"):format(now(), math.random(1000, 9999))
end

local function saveData(name)
    local p = Server.players[name]
    if not p then return end
    log("SAVE", ("user=%s gems=%d inv=%d"):format(name, p.gems, #p.inventory))
    p._savedGems = p.gems
    p._savedInv  = #p.inventory
end

-- ============================================================
-- SERVER LOGIC
-- ============================================================
local function onPlayerAdded(name)
    Server.players[name] = { gems = 1000, inventory = {} }
    log("JOIN", ("%s gems=%d"):format(name, Server.players[name].gems))
end

local function onPlayerRemoving(name)
    local uid = name

    if Config.AUTO_RECONCILE then
        for txnId, info in pairs(Server.pendingTxn) do
            if info.user == uid and not info.committed then
                log("RECONCILE", ("committing txn=%s for %s"):format(txnId, name))
                table.insert(Server.players[uid].inventory, info.cosmetic)
                info.committed = true
            end
        end
    else
        log("RECONCILE", ("SKIPPED (AUTO_RECONCILE=false) — txn left unclaimed for %s"):format(name))
    end

    if Config.SAVE_ON_LEAVE then
        saveData(uid)
    else
        log("SAVE", ("SKIPPED on leave (SAVE_ON_LEAVE=false) — memory-only spend not persisted"))
    end

    Server.players[uid] = nil
end

Server.remotes.purchaseCase:OnServerEvent(function(name, caseName)
    local state = Server.players[name]
    local caseDef = CASES[caseName]
    if not (state and caseDef) then return end

    if state.gems < caseDef.cost then
        Server.remotes.casePurchaseResult:FireClient(name, { error = "not_enough_gems" })
        return
    end

    -- 1) หัก gems ทันที (in-memory)
    state.gems = state.gems - caseDef.cost
    log("SPEND", ("%s -%d gems (now=%d)"):format(name, caseDef.cost, state.gems))

    -- 2) roll
    local pick = caseDef.pool[ math.random(1, #caseDef.pool) ]
    local txnId = randomId()
    Server.pendingTxn[txnId] = {
        user = name,
        cosmetic = pick.name,
        rarity = pick.rarity,
        committed = false,
    }

    -- 3) PERSIST_ON_SPEND toggle
    if Config.PERSIST_ON_SPEND then
        saveData(name)
    else
        log("SPEND", "persist skipped (PERSIST_ON_SPEND=false) → in-memory only")
    end

    -- 4) ส่งผลให้ client
    Server.remotes.casePurchaseResult:FireClient(name, {
        cosmetic = pick.name,
        rarity = pick.rarity,
        transactionId = txnId,
    })
end)

Server.remotes.awardCaseCosmetic:OnServerEvent(function(name, cosmetic, rarity, txnId)
    local info = Server.pendingTxn[txnId]
    if not (info and info.user == name and not info.committed) then
        log("AWARD", ("rejected txn=%s"):format(tostring(txnId)))
        return
    end
    table.insert(Server.players[name].inventory, cosmetic)
    info.committed = true
    log("AWARD", ("%s got %s (%s) txn=%s"):format(name, cosmetic, rarity, txnId))
    saveData(name)
end)

-- ============================================================
-- CLIENT LOGIC
-- ============================================================
local LocalPlayer = "Player1"

local function simulateSpin(duration)
    log("CLIENT", ("spin animation start (%0.1fs)"):format(duration))
    -- จำลอง wait แบบ blocking
    local t = os.clock()
    while os.clock() - t < duration do end
    log("CLIENT", "spin animation end")
end

local function simulateDisconnect(reason)
    log("CLIENT", ("*** SIMULATED DISCONNECT: %s ***"):format(reason))
    -- ในจำลองนี้: trigger PlayerRemoving แล้วหยุด flow
    onPlayerRemoving(LocalPlayer)
end

Server.remotes.casePurchaseResult:OnClientEvent(function(name, payload)
    if payload.error then
        log("CLIENT", "error: " .. payload.error)
        return
    end

    log("CLIENT", ("result received: %s (%s) txn=%s")
        :format(payload.cosmetic, payload.rarity, payload.transactionId))

    local mode = Config.SIM_MODE

    if Config.ENABLE_EXPLOIT_SIM and mode == "disconnect_during_spin" then
        simulateSpin(0.3)
        simulateDisconnect("during spin animation")
        return
    end

    if Config.ENABLE_EXPLOIT_SIM and mode == "disconnect_before_award" then
        simulateSpin(0.5)
        simulateDisconnect("right before awardCaseCosmetic")
        return
    end

    if mode == "reconcile_test" then
        simulateSpin(0.3)
        Server.remotes.awardCaseCosmetic:FireServer(name, payload.cosmetic, payload.rarity, payload.transactionId)
        log("CLIENT", "award fired (normal)")
        return
    end

    -- normal
    simulateSpin(0.3)
    Server.remotes.awardCaseCosmetic:FireServer(name, payload.cosmetic, payload.rarity, payload.transactionId)
    log("CLIENT", "award fired (normal)")
end)

-- ============================================================
-- RUN
-- ============================================================
local function runPurchase()
    log("CLIENT", ("purchase request: case=%s mode=%s exploit=%s")
        :format(Config.TEST_CASE, Config.SIM_MODE, tostring(Config.ENABLE_EXPLOIT_SIM)))
    Server.remotes.purchaseCase:FireServer(LocalPlayer, Config.TEST_CASE)
end

math.randomseed(os.time())

print("============================================")
print(" CASE PURCHASE ROLLBACK SIMULATION")
print("============================================")
print((" mode=%s | case=%s"):format(Config.SIM_MODE, Config.TEST_CASE))
print((" exploit=%s | persist_on_spend=%s | auto_reconcile=%s | save_on_leave=%s")
    :format(tostring(Config.ENABLE_EXPLOIT_SIM), tostring(Config.PERSIST_ON_SPEND),
            tostring(Config.AUTO_RECONCILE), tostring(Config.SAVE_ON_LEAVE)))
print("--------------------------------------------")

onPlayerAdded(LocalPlayer)
runPurchase()

-- จำลอง rejoin เพื่อดู balance
print("\n--- REJOIN SIMULATION ---")
onPlayerAdded(LocalPlayer)
log("JOIN", ("(after rejoin) gems=%d inv=%d"):format(Server.players[LocalPlayer].gems, #Server.players[LocalPlayer].inventory))
