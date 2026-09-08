# CWS port — cave place 96256228241730 → main place 102256505262642

The main place already had a taser, but it was a plain SPH-style gun: a raycast, damage,
and the ragdoll flag. The cave place runs the whole **CWS** framework ("Cave Weapon System
by JIWONZ"), which is where the muzzle flash, tracer, impact decals, hit markers, ammo HUD
and reload timer actually live. This port moves that framework across, so the taser in the
main place behaves like the one in the cave place rather than approximating it.

## What is now in the main place

| Path | Origin |
| --- | --- |
| `ReplicatedStorage.Assets.Misc.CWS_Directory` | copied whole (360 instances: remos, remotes, anim, effects, sounds, modules) |
| `StarterGui.CWS_Gui` | copied (ammo / max_ammo / weapon name / ammo type / icon / mobile buttons) |
| `StarterGui.MousePositionGui` | copied (crosshair + the "NoAmmo" marker) |
| `StarterPlayer.StarterPlayerScripts.CwsClient` | copied, patched (see below) |
| `ServerScriptService.Combat.CwsServer` | the server half, written for the cave place and reused as-is |
| `ServerStorage.PXItems["ปืนช็อตไฟฟ้ารัวเร็ว"]` | the CWS taser tool, replacing the old SPH-style one |

The old tool's `Fire` RemoteEvent, `Script` and `Client` are gone; the CWS tool carries only
`Handle`, `Taser`, `ADS` and `Info`.

## Transferring between two Studio instances

Studio's clipboard is not reachable from a plugin and the MCP bridge is per-instance, so
`xfer.lua` does it over HTTP instead: it walks a subtree, encodes every property, attribute
and tag into JSON, and rebuilds the tree in the other instance. Instance-valued properties
(`Part0`, `Attachment0`, …) become node ids and are re-resolved after the rebuild, so welds
survive. Property names come from a per-class table because Luau has no reflection; reads
and writes are wrapped in `pcall`, so an over-broad list is harmless.

Usage: serve the file over localhost, then in each Studio instance fetch it into a
ModuleScript and `require` it — `X.dump(root)` on one side, `X.build(nodes, parent)` on the
other. The cave place needed `HttpService.HttpEnabled = true` for this; it has been set back
to `false`.

## Patches applied to the copied scripts

The cave place's scripts came out of a saved-instance dump, and three defects only showed up
once they ran in a different place:

1. **Missing shared modules.** `CwsClient` required `ReplicatedStorage.Modules.Shared.{Replica,
   BindableEvents,canHitTarget}` and `ReplicatedStorage.GameSettings`, none of which exist here
   in that shape. `GameSettings`/`Replica` were read in exactly one line — picking dodge
   animation 1 or 2 — so that line is now a constant, `BindableEvents` is a local
   BindableEvent registry, and `canHitTarget` is a live-humanoid check. `BackpackGui` is
   `FindFirstChild` with a dummy fallback, because this place has no Satchel and
   `WaitForChild` would have stalled the script forever.
2. **`GetShiftLockEnabled`.** The cave place ships a patched `PlayerModule` that adds this
   method; the stock one has no such thing, and the call killed the equip handler, which is
   why the HUD showed 0 rounds. It now falls back to `UserInputService.MouseBehavior ==
   LockCenter`, which covers both states CWS tests for.
3. **Two decompiler artifacts** — these are bugs in the cave place too, and have been fixed
   there as well:
   - `CWS.RenderArms` declared `local CFrame = camera.CFrame`, shadowing the global one line
     before calling `CFrame.Angles`. It threw every frame in first person.
   - The body-shot branch of `CwsClient` is an inlined copy of the headshot branch that was
     left pointing at the headshot locals, so `BodyShotSound` was never used and every body
     shot threw `attempt to index nil with 'Clone'`.

The taser's muzzle emitters were also rebuilt from `effects.muzzle.pulse` — the hand-built
copies were missing the `emit` / `delay` / `fe` attributes CWS reads, so the flash fell back
to defaults and warned on every shot.

## Ragdoll

The knockdown is the taser's own, in `Info.custom_server.damage`: it sets the Humanoid
attribute `RagdollEnabled`, shoves the torso, waits 5 seconds and clears it.
`Combat.RagdollService` turns that flag into limp joints. No other weapon touches the flag,
so no other weapon knocks anyone down. `CombatService` still carries the separate
`WeaponKnocksDown` gate for SPH guns listed in `MapConfig.hitRagdollTools`; nothing currently
matches it.

`RagdollService` now also covers NPCs: player characters are prepared on spawn, anything else
with a Humanoid is prepared the first time it is actually knocked down.

## Verified in Play

- HUD: weapon name `ปืนช็อตไฟฟ้ารัวเร็ว`, ammo type `Lithium Battery`, `비살상무기`, 3 / 3 rounds.
- Firing spawns `Sound fire` on the handle, a `pulse` Beam tracer, an impact `Spark` emitter
  and six impact textures on the target. No script errors.
- Three shots empty the magazine, the crosshair's `NoAmmo` marker appears, `R` reloads and
  restores 3 rounds after the 2 second timer.
- Tasing a real R6 rig: 5 of 6 Motor6Ds disabled, 5 ball sockets enabled, `PlatformStand`,
  `HumanoidStateType.Physics`, torso tilt 76°, head dropped to the floor — then fully restored.
  `RagdollEnabled` true → false measured at **5.00 s**.

## Known limitation

CWS's animations belong to the cave game's creator, so Roblox refuses to load them here:
every `anim` asset reports "The experience doesn't have access permission" and resolves to
length 0. Firing, effects, sounds, damage, HUD and ragdoll all work; the **hand and weapon
animations do not play**, and cannot, until those animations are re-uploaded under this
game's owner. Their ids are in `ReplicatedStorage.Assets.Misc.CWS_Directory.anim`.

## Update — stun logic moved out of the client-replicated Tool

`Info` is a ModuleScript parented under the Tool, so it replicates in full to whichever
client is holding the gun — including its `Source`, readable by any exploit. The original
port put the taser's stun/ragdoll implementation there as `custom_server.damage`, which meant
the exact stun duration, knockback force and trigger condition sat in plain Luau text inside
every player's own Backpack the moment they picked the gun up, and could be called directly
client-side.

That logic now lives in `ServerScriptService.Combat.WeaponServerLogic` (`WeaponServerLogic.server.lua`
in this folder), a table keyed by `Tool.Name`, parented only under `ServerScriptService` —
nothing there is ever sent to a client. `CwsServer.onDamage` looks the weapon up by name after
resolving damage instead of reading `info.custom_server`; a weapon with no entry in the table
just has no server-only behaviour, same as before.

`Info.lua` keeps everything the client legitimately needs (spread, animations, effects, HUD
text, damage numbers for the hitmarker) — that part matches how every other CWS gun in the
game already works, and isn't new exposure. Verified in Play mode: `require(tool.Info)` from
the client no longer has a `custom_server` key, the shot still applies 3 damage, and the
target still ragdolls for exactly 5.00s.
