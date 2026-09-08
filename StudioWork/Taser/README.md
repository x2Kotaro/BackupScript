# 연발 테이저건 (repeating taser) — import into place 96256228241730

The Studio place is a `UniversalSynSaveInstance` dump of the live game
("[🌱] หน่วยถ้ำ", CaveArmy). Everything that can't be saved out of a running place was
missing, so importing the tool meant rebuilding the parts of the game it depends on.

Source of truth for every value here: the live client, read through the Dex bridge.

## What was added

| Where | What |
| --- | --- |
| `ServerStorage.ServerAssets.Tools.연발 테이저건` | The tool, rebuilt instance by instance (22 descendants, matches live exactly) |
| `ServerStorage.ServerAssets.Tools.*` | Folder created; all 5 tools moved here — `GameSettings` looks them up at this exact path |
| `ServerScriptService.CwsServer` | The missing CWS server half (`CwsServer.server.lua`) |
| `ServerScriptService.PlayerDataServer` | Replica bootstrap (`PlayerDataServer.server.lua`) |
| `ReplicatedStorage.Assets.Misc.CWS_Directory.modules.*` | `Func`, `settings`, `Spring`, `DecalSystem`, `RigidBody` (`CWS_Modules/`) |
| `ReplicatedStorage.Assets.Gui.InventorySearchFrame` | Rebuilt; Satchel waits on it |
| `StarterPack` | Test copies of the taser and Quasar — delete these if tools should be purchase-only |

## The tool

`Build.lua` recreates it; `Info.lua` is the recovered config module.

- Handle (invisible anchor) + `Taser` MeshPart `rbxassetid://8438694198` with its
  SurfaceAppearance + `ADS` aim point, welded exactly as in the live game
- `fire_point` / `casing_point` attachments, 4 muzzle emitters, PointLight, 8 sounds
- Attributes: `cws_enabled`, `ammo=3`, `vm_long`, `I_Name`, `ToolType`
- `Info`: 200 rpm, 3 rounds, 2s reload, 30 stud range, 1–3 damage (5 headshot),
  30 melee damage, and the `custom_server.damage` hook that ragdolls the target for 5s

## Things in the dump that were broken and had to be repaired

These blocked the weapon; each is a genuine defect in the saved place, not a change of design.

1. **`StarterPlayerScripts` CoreScript stubs** — `PlayerModule`, `RbxCharacterSounds`,
   `PlayerScriptsLoader`, `ChatScript`, `BubbleChat` were saved as `-- Ignored`.
   `require(PlayerModule)` threw and killed `CwsClient` on line 10. Deleted so Roblox
   injects the real ones.
2. **`ReplicatedStorage.RemoteEvents`** — the `Remote` module always creates its events
   fresh on the server, so the saved folder produced duplicate names and clients bound
   to the dead copies. Deleted; it is rebuilt at runtime.
3. **`TopbarPlus.VERSION`** — the decompiler scoped the `pcall` results inside the retry
   loop, so `Name` was read off a nil and every require threw. Also made the
   `GetProductInfo` retry bounded; unbounded, a Studio session without marketplace
   access hung Satchel forever.
4. **`Modules.Shared.Promise`** — the decompiler inlined one advancer helper three times
   but left all three copies referencing the first copy's locals, so `finally` called a
   nil. This is what kept `Replica` from ever resolving.
5. **`CWS_Directory.modules`** — the live game strips this folder after the client loads
   it, so it saved empty and `modules.settings.KeyBinds` was nil. Rebuilt from the call
   sites; the keybinds themselves were read out of the live client's memory and are the
   real ones (SHOOT=MB1, AIM=MB2, RELOAD=R, MELEE=T, HOLD_DOWN=E, DODGE=Q).

## Verified in Play mode

- Tool equips, HUD binds: `wpn_name=연발 테이저건`, `ammo 3/3`, `Lithium Battery`, `비살상무기`
- Real mouse click fires: ammo decrements, `Damage` reaches the server
- Hit applied: dummy 100 → 97.56 HP (the 1–3 roll), `RagdollEnabled` set true then
  cleared after 5s by `custom_server.damage`
- Backpack hotbar builds all 10 slots

## Still missing from the dump (not weapon-related)

- `CWS_Directory.modules.CryptoClient` — present in the live client, unused by `CwsClient`
- The game's DataStore layer: `PlayerDataServer` gives each player a fresh
  `PLAYER_DATA_TEMPLATE` per session, nothing is persisted
- The ragdoll server system — the taser sets `RagdollEnabled`, but only
  `RagdollSystemClient` survived; the server half that acts on the attribute is gone
- `WaterBlurHandler` errors on a missing workspace part
- One startup race in Satchel (`satchel:333`) — harmless, the hotbar still builds
