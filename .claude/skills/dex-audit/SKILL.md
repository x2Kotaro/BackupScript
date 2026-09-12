---
name: dex-audit
description: Security-audit a live Roblox game the user owns through the Dex MCP bridge — map its anti-cheat, catalogue every client→server remote and what validation the server does (or skips), and hunt exploitable weaknesses (item duplication, rollback-on-rejoin, timestamp trust, unvalidated FireServer args) so they can be fixed. Read-only recon by default; changes go into a written report, not the game. Use for "หา anti-cheat", "วิเคราะห์ช่องโหว่ remote", "ทำไมโดนแบน/โดนยิง", "หาช่องโหว่ rollback/ดูปไอเทม", "audit เกมตัวเอง".
---

# Auditing a live game for exploitable weaknesses

Defensive workflow. Goal: find how a game the **user owns** can be exploited so the
holes get patched. All findings land in a report file under `Audit/`. Do not modify the
target game, do not build a working exploit — proof-of-concept stays at the "here is the
unvalidated call and what a crafted arg would do" level, enough to write the fix.

Scope check first: this is only for a game the user owns or is authorized to test. If that
is unclear, ask before touching remotes. Say so plainly — this is the one place to break
caveman terseness.

## Tools (all from the `dex` MCP server)

| Tool | Use in an audit |
|---|---|
| `dex_status` | Confirm bridge + place. Do this first; rejoin/teleport kills the bridge. |
| `dex_tree` | Walk `ReplicatedStorage`, `ServerScriptService` (names only, server scripts don't decompile client-side), `Players.LocalPlayer`. Find remote folders + anti-cheat scripts. |
| `dex_decompile` | Read LocalScripts / ModuleScripts on the client: anti-cheat logic, remote wrappers, what args the client sends. |
| `dex_spy` | The core recon tool. Records every FireServer/InvokeServer (and optionally server→client). Shows the calling script. |
| `dex_exec` | Probe state, enumerate remotes, read attributes/values. Read-only queries only during audit. |
| `dex_console` | Catch anti-cheat warnings/kick reasons printed after the fact. |

## Phase 1 — map the anti-cheat

1. `dex_status` to confirm the target.
2. `dex_tree` on `ReplicatedStorage`, `StarterPlayer.StarterPlayerScripts`,
   `Players.LocalPlayer.PlayerScripts`, `Workspace`. Flag anything named
   *anticheat / guard / detect / security / adminlog / report / heartbeat / integrity*.
3. `dex_decompile` each candidate. Record, per detector:
   - **what it watches** (walkspeed, position delta, gravity, tool count, remote rate,
     humanoid state, `__namecall` hooks, GUI presence)
   - **client-side vs server-side** — a check that lives in a LocalScript is advisory only;
     note it as *client-side, bypassable* (this is usually the answer to "ทำไมโดนยิง":
     the detection that fired was server-side, or a client heartbeat the exploit stopped
     sending).
   - **the punish path** — does it `Kick` locally, or `FireServer` a report the server
     acts on? Trace the remote.
4. Write the anti-cheat map into the report before touching remotes.

## Phase 2 — catalogue every client→server remote

1. `dex_spy { action: "start", incoming: true, max: 2000 }`.
2. Play the game normally through every economy action: pick up item, equip, trade,
   sell, open chest, claim reward, teleport between places, **rejoin**.
3. `dex_spy { action: "read", direction: "out", limit: 300 }`. For each distinct remote:
   - name, type (Event vs Function), calling script, arg shape + example values
   - what server action it triggers (infer from name + effect)
   - poll with `since:` = the previous `Latest` to page long sessions.
4. Build a remote inventory table in the report.

## Phase 3 — find the weaknesses

Go down the inventory asking, per remote, "what does the server trust that the client sends?"

- **Unvalidated args** — remote takes an amount / itemId / price / target and the server
  looks like it uses it directly. Note what a crafted value (negative amount, foreign
  itemId, another player's id) would do. Confirm the client never re-checks server-side by
  reading the client wrapper — the server code isn't visible, so reason from the arg
  contract + observed effect, and mark confidence.
- **Client-authoritative state** — position, currency, tool ownership pushed *up* by the
  client and echoed back. Duplication and teleport hacks live here.
- **Rate / replay** — same remote spammable? Any nonce or sequence number, or can a
  captured call be re-fired?

### Item duplication / rollback-on-rejoin / timestamp (the headline case)

The reported bug: **items roll back on rejoin, and the rollback window is a timestamp hole.**
Walk this specific chain:

1. On join, spy the **incoming** load — does the server send the client its inventory +
   a `savedAt` / `lastSave` / `timestamp`? `dex_spy { direction: "in" }`.
2. Watch how a save is triggered — periodic autosave remote, on-action save, or on-leave
   (`BindToClose` server-side, invisible here — infer from the save-remote cadence).
3. The dup pattern to prove out:
   - state changes on server (spend item / receive item),
   - client leaves **before** the next save commits, so the server persists the *older*
     snapshot → item comes back on rejoin (rollback).
   - If the save key is a **client-sent timestamp** and the server keeps the row with the
     *newer* timestamp, a client that sends a future/frozen timestamp can pin an old
     inventory and replay it — classic timestamp-trust dup.
4. Establish, from the spy timeline, **the exact ordering** between the mutation, the save,
   and disconnect. That timing gap is the finding. Record the observed sequence numbers and
   the wall-clock deltas.

## Report

Write to `Audit/<game>-<date>.md` (create `Audit/`):

- **Anti-cheat map** — each detector, client- or server-side, what it watches, punish path.
- **Remote inventory** — table: remote · type · args · server effect · calling script.
- **Findings** — one block each: title, severity, the remote/flow, the trusted-input or
  timing gap, a concrete exploit sketch (inputs → effect, no working payload), **and the
  fix** (server-side validation, authoritative state, save-ordering / monotonic
  server-clock timestamp, idempotency key). Rank most severe first.
- **Why detections fire** — if the question was "ทำไมโดนยิง", tie the ban/kick to the
  specific server-side or heartbeat check found in Phase 1.

## Gotchas

- Server scripts never decompile from the client. Everything about server validation is
  *inferred* from remote contracts and observed effects — always mark confidence and say
  what would confirm it (a repro, a value probe).
- `dex_spy` only sees this client's traffic. A dup needing two clients can't be fully
  observed from one session — note that as a limitation.
- The bridge dies on rejoin/teleport, but rejoin is part of the test — re-run `dex_status`
  and restart the spy after every rejoin, and stitch the timeline across sessions manually.
- Recon is read-only. Never fire a remote with a crafted malicious value against a live
  shared server to "confirm" a dup — reason it from the contract, or test in a private
  server the user controls. This stays a report, not an attack.
