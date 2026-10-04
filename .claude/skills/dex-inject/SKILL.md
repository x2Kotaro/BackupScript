---
name: dex-inject
description: Inject a Luau script from this repo into the running Roblox client through the Dex MCP bridge, then read the console back to see whether it worked. Use when asked to inject / execute / run a script in-game, to test an edit to Scripts/*.lua live, or to find out why an injected script errored ("ยิงสคริปต์เข้าเกม", "รันในเกม", "inject STE.lua", "ทำไมสคริปต์ error").
---

# Injecting a script into the running game

The `dex` MCP server bridges this repo to a live Roblox client. `dex_inject` is the
edit → run → read-the-error loop; everything else here supports it.

## Token budget

- Inject by `file`, never paste the script into `code`. Never `Read` a whole `Scripts/*.lua` to
  check it — `grep -n` + `Read` with `offset`/`limit`.
- `capture_ms` only as long as needed (1500 default, 5000 for HTTP UI loads). Report `Status` +
  errors only, not the whole `Output`.
- `dex_console`: `errors_only: true` or `filter`, `count ≤ 20`.
- State checks via one `dex_exec` returning a few compact lines.

## Before injecting

1. `dex_status`. If it times out the bridge is not running — the user must execute
   `Dex_Mcp/DexBridge.lua` in their executor. Rejoining or teleporting kills it, so this
   is the first thing to re-check after any "it stopped working".
2. Know which file. If the user says "inject this" and a file is open in their editor,
   that file is the target; otherwise ask rather than guessing between `Scripts/*.lua`.

## Injecting

```
dex_inject { file: "Scripts/STE.lua" }
```

- `file` is relative to the repo root. `url` and `code` are the other two sources —
  exactly one of the three.
- `cleanup` defaults to `"ValkyrieCleanup"`, the teardown these scripts park in `getgenv()`.
  Leave it alone for repo scripts; pass `""` for a script that has no teardown, and the
  right global name for a script that uses a different one. Skipping it on a repo script
  stacks a second window and a second set of loops on the same character.
- `capture_ms` (default 1500) is how long the console is watched after the chunk starts.
  Raise it for a script that loads a UI library over HTTP; 5000 is usually enough.

Read `Status` in the reply:

| Status | Means |
|---|---|
| `running` | Normal for anything with a UI or a loop. Not an error. |
| `returned` | Ran to the end without yielding forever. |
| `errored` | `Error` holds the traceback. Fix the file, inject again. |

`Output` is whatever the client printed during the window, warnings and errors included.

## After injecting

- An error thrown later (a callback, a loop's next tick) is not in `Output`. Get it with
  `dex_console { errors_only: true }`, optionally `filter` on the chunk name.
- To check state a script left behind, `dex_exec` is cheaper than re-injecting:
  `return type(getgenv().ValkyrieCleanup)`, `return getgenv().Settings.Main.AutoSell`.
- To look at what the script built, `dex_tree` on `Players.LocalPlayer.PlayerGui`.
- "No errors" doesn't mean it works. For automation changes, measure the behavior the edit
  was meant to fix (hits landed, rejected actions, time spent dodging) with a counter or
  timeline probe from `dex-mechanics` (`references/probes.md` §4/§8).
- If the script misbehaves because the game rule is unclear (wrong cooldown, whiffed hits,
  guessed event names), stop patching values and use the `dex-mechanics` skill to confirm
  the rule first.

## Iterating

Edit the file with Edit, then call `dex_inject` on the same path again — the cleanup call
makes re-injection safe, no rejoin needed. Do not paste the whole file into `code`; inject
by `file` so what runs is what is on disk.

## Gotchas

- `compile error: ...` comes back before anything runs, and is a syntax error in the file,
  reported at the line the executor sees. Nothing was injected.
- A script that errors during startup can leave `ValkyrieCleanup` unset, so the next inject
  has nothing to tear down and the half-built UI stays on screen. `dex_exec` a manual
  `Library:Unload()` or have the user rejoin.
- The injected chunk runs with the executor's full permissions in the game the user is
  actually playing. Show the user what will run when injecting anything they did not write.
