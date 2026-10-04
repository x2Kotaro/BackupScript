---
name: dex-mechanics
description: Reverse-engineer how a live Roblox game mechanic actually works through the Dex MCP bridge (combat, combos, cooldowns, hit detection, stuns, iframes, AI/mob behavior, quests, spawns, prompts, movement, skills), so automation in Scripts/*.lua is built on confirmed rules instead of guessed names. Traces the execution path across modules, remotes, attributes, signals, animations, and timing, then cross-checks each finding against a second source. Use before writing or fixing farm/combat/automation logic, when a script "works sometimes", when hits whiff or get rejected, when two systems fight, or for "ระบบนี้ทำงานยังไง", "หา cooldown จริง", "ทำไมตีไม่โดน", "ทำไมหลบรัว", "reverse engineer", "วิเคราะห์ระบบเกม".
---

# Reverse-engineering a game mechanic

Goal: find the **rule the server enforces** and the **signal the client can read**, then write
the smallest automation that follows them. Every name/number/timing shipped in a script traces
to decompiled code or a live measurement (ideally both).

## Token budget (read first — hard rules)

Dex output lands in context verbatim. Most tokens in a session are wasted here.

1. **Memory first.** Check MEMORY.md / linked memories for the mechanic before probing. Don't
   re-measure a recorded fact; only probe what's missing or contradicted.
2. **Every `dex_exec` returns ≤ ~1.5 KB.** Filter + aggregate *inside the game*: counts per key,
   first N lines (`if #log < 40`), diffs only, `:sub(1, 1500)` on the final string. Drop noise at
   the source (for Ouwland FX: `_Swings`, `Slash_Effect`, `damage_indicator`, `Add_*`,
   `*state*`, `NpcNoticeEffect`). A log that comes back truncated = wasted call, redo smaller.
3. **Never `dex_decompile` a big module through the tool.** Use `dex_exec` with `decompile(x)` and
   return only matches: `s:find("function t.X")` → `s:sub(a, a + 1500)`, or `gmatch` a list of
   names/phases (probes §2). The tool form is fine only for scripts known to be < 2 KB.
4. **One exec per hypothesis.** Combine state checks (config, target, HP, quest state) into one
   call; don't chain 4 tiny calls.
5. **`dex_tree` depth ≤ 2 on a specific path**, never `game`/`Workspace` root.
   **`dex_console`**: `errors_only` or `filter`, `count ≤ 20`.
6. **Repo files:** never `Read` a whole `Scripts/*.lua`. `grep -n` the symbol, then `Read` with
   `offset`/`limit` ≤ 150. Read `references/probes.md` by section (`grep -n '^## '` then offset).
7. **Watch windows ≤ 12 s**, and check the precondition first (character alive, farm actually
   engaging the target) so a recording isn't empty.
8. **Reply short:** findings table + what changed. No transcript of probes.

## Evidence ledger

Tag each claim: `CONFIRMED` (two sources agree: code + live, or two live signals), `OBSERVED`
(seen live once), `READ` (in code, not seen live), `ASSUMED` (inferred from a name — never ship
silently). Design each probe to **break** a hypothesis, measure the real target
(`getgenv().ValkyrieFarm` / `ValkyrieFighter`), not a proxy.

Leave the game as found: disconnect connections, restore hooks, revert flipped config in the same
exec. Game-changing actions (remotes, movement) only if the user would do them anyway; say so.

## Workflow

1. **Frame** in 1–2 lines: mechanic + the question automation needs answered. List candidate state
   carriers: attributes, child flags (`Stun`, `RagDoll`, `iframe`, `Blocking`), values-folder
   accessors (`Utility.getvaluesfolder`), shared modules (presets/checkers), client controllers,
   remotes (`dex_spy`, EffectsEvent), animations, physics/constraints, UI (last resort).
2. **Map statically.** Find owners by what the code touches (`filtergc` by constant, probes §3),
   decompile the owning script (grep, not full dump). Shared modules often hold the server check
   (`IsServer()`, `*_server`, `Check_*`): write down the exact formula incl. clamps/divisors/grace.
   Note hidden deps: upvalues, stat multipliers, preset fallbacks, streaming, respawn.
3. **Verify live** with one timeline recorder (probes §4) on a single `os.clock()` base. Diff
   expectation vs timeline; each mismatch is a finding. Server `os.clock()` attrs are another
   epoch — stamp on arrival. Repeat 2–3 cycles for durations; change one variable at a time.
   Can't trigger a case → mark untested.
4. **Pick the data source**, best first: server-written replicated state → shared-check formula
   → server→client events (cosmetic, droppable) → client controller state → UI → name heuristics
   (hypothesis only). Note failure modes (streamed out, reset on respawn, per-weapon variants).
5. **Find conflicts**: grep every writer of the shared resource (`HumanoidRootPart.CFrame`,
   `Movement.Lock/Go/Cancel`, `Fighter.Continue`, `getgenv()` keys). Two loops writing one
   resource = jitter / random stops. Fixed `task.wait` vs real window = timing bug.
6. **Implement small**: read state instead of parallel counters, wait-until-state-changes with
   timeout, one predicate with named tunables + comment citing the measured source, hysteresis on
   per-frame switches. Prototype in `dex_exec` first, then `dex-inject` and re-measure the metric
   the change targets (before vs after).

## Report

Short mechanic brief: **Rule** (+ tag), **Signals** chosen and why, **Timings** table
(event · delay · range · samples), **Conflicts** handled, **Not verified** + what would confirm.
Save reusable game facts to project memory (link related ones); not what the code already says.

## Gotchas

- `getconnections` on `GetAttributeChangedSignal`/`GetPropertyChangedSignal` can return 0 —
  cross-check with `filtergc` or `.AttributeChanged`.
- Wrapping `Module.fn` misses callers that cached it; use `hookfunction` and restore in the same call.
- Dying models may lack parts: `FindFirstChildOfClass`, never `.Humanoid`.
- Bridge dies on rejoin/teleport: `dex_status` first when anything times out.
- Server scripts never decompile; server-only behavior stays below `CONFIRMED` unless a live test pins it.
- Module signatures change between updates (e.g. `(player, id)` with optional player) — read the
  function header before trusting a call's return.
