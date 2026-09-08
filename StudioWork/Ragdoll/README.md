# Knockdown ragdoll — place 102256505262642 (ปรับปรุง, main place)

Being tased drops the character into a real ragdoll for 5 seconds, then it stands back up.
Only the taser does this; every other gun damages normally.

## Where it lives

| Path | What |
| --- | --- |
| `ReplicatedStorage.GameSettings.Modules.RagdollMod` | `Setup` / `SetRagdolled` / `Cleanup` added next to the existing `MakeCorpse` |
| `ServerScriptService.Combat.RagdollService` | Builds the constraints per character and turns `RagdollEnabled` into limp joints |
| `ServerScriptService.Combat.CombatService` | `KnockDown` helper + call after `TakeDamage`, gated to knockdown weapons |
| `ReplicatedStorage.GameSettings.Groups.MapConfig` | `hitRagdoll*` keys and `PX_ITEMS.TASER` |
| `ServerStorage.PXItems.ปืนช็อตไฟฟ้ารัวเร็ว` | The taser tool itself |

## How it works

`Humanoid` attribute `RagdollEnabled` was already the switch in this place — the melee
tools set it and `CombatService` reads it — but nothing made a body actually go limp.
It now drives three things:

1. **RagdollService** (server) mirrors every Motor6D with a disabled
   `BallSocketConstraint` when a character spawns. On the flag it disables the motors
   and enables the sockets, sets `PlatformStand`, and reverses all of it when cleared.
2. **StarterPlayerScripts.Systems** (already existed) freezes the victim's input,
   unequips tools and applies the `RagdollVelocity` impulse.
3. **CombatService** sets the flag on a non-fatal hit, then clears it after
   `Config.hitRagdollDuration`. A second hit refreshes the timer instead of stacking.

The R6 `RootJoint` is deliberately left connected so the Humanoid keeps a valid root
and standing up is one state change. Everything else — neck, shoulders, hips — goes limp.

**The weapon rig fights back.** Something re-enables the shoulder Motor6Ds every frame
so it can drive the arms, which snapped them straight mid-ragdoll. `SetRagdolled` now
holds the loosened joints off on Heartbeat for as long as the character is down, rather
than trying to find and gate every writer.

`MakeCorpse` calls `Cleanup` first, so a player killed while down still turns into a
normal corpse.

## Which weapons knock down

```lua
Config.hitRagdoll = true
Config.hitRagdollDuration = 5
Config.hitRagdollTools = {
    ["ปืนช็อตไฟฟ้ารัวเร็ว"] = true,
    ["연발 테이저건"] = true,
}
```

A tool can also opt in on its own with a `HitRagdoll` attribute set to true — the taser
carries one. Anything not on the list damages without knocking down.

## The taser

Built from the live cave-army tool (same mesh, muzzle effects and sounds), but written
in this place's house style rather than as a CWS weapon: its own server `Script` owns
ammo, fire rate, the raycast, damage and the stun, and a small `Client` LocalScript
reports where the player is aiming. Tuning is `Config.PX_ITEMS.TASER`
(3 damage, 200 rpm, 3 rounds, 2s reload, 5s stun).

It sits in `ServerStorage.PXItems` under its Thai name because `PXItemService` resolves
shop items by `ITEMS[key].Name` — the shop entry, preview model and price were already
in the place, only the tool was missing.

## Verified in Play mode

- Direct flag test: 7 joints limp, torso flat at 90°, all joints restored and upright at 0°, health untouched
- Taser hit: `RagdollEnabled` true at 11.99s, false at 17.00s — 5.01s, damage 3
- M16A4 burst into the same target: 231 damage dealt, `RagdollEnabled` never set

## Known gaps (pre-existing)

- `ServerStorage.เควซาร์` / `มีดพร้า` read `PX_ITEMS.SWORD.STUN_TIME`, `STUN_KNOCKBACK`
  and `STUN_LIFT`, and none of those keys exist — so the melee stun never fires. Adding
  them to the SWORD block turns it on, now that ragdolls actually work.
- NPCs are not set up by RagdollService (players only), so a tased NPC gets the flag but
  no limp joints.

## Update — the taser is now a CWS weapon

The taser in `ServerStorage.PXItems` was replaced by the real CWS tool ported from the cave
place; see `../CwsPort/README.md`. The knockdown therefore no longer comes from
`CombatService.KnockDown` but from the tool's own `Info.custom_server.damage`, which sets the
same Humanoid attribute `RagdollEnabled` and clears it 5 seconds later. Everything below
still describes how that flag becomes limp joints.

`CombatService`'s `WeaponKnocksDown` gate and `MapConfig.hitRagdollTools` are still in place
for SPH-kit guns, but nothing currently matches them.

`RagdollService` was extended: player characters are still prepared on spawn, and any other
Humanoid in the workspace is now prepared the first time it is knocked down, so tased NPCs
go limp instead of only receiving the flag. That closes the gap noted below.
