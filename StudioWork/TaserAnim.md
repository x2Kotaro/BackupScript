# Taser animation — สถานะ + วิธีทำต่อ

## เช็คแล้ว (Dex live vs Studio)

CWS เก็บ animation แบบ **group** ไม่ใช่ในตัว Tool
- live: `ReplicatedStorage.Assets.Misc.CWS_Directory.anim.pistol`
- studio: `ReplicatedStorage.GameSettings.Assets.Misc.CWS_Directory.anim.pistol`

Taser (`Info.anim`) ทุกช่อง = `group = "pistol"` → เล่นชุด pistol

**pistol group IDs (studio ตรงกับ live ทุกตัว):**

| slot | AnimationId |
|---|---|
| idle | `rbxassetid://8317258850` |
| fire | `rbxassetid://8317420836` |
| last_fire | `rbxassetid://8317420836` |
| reload | `rbxassetid://9080326525` |
| equip | `rbxassetid://8317598834` |
| hold_down | `rbxassetid://8317655410` |
| melee_attack | `rbxassetid://8881693307` |

→ Studio ไม่ได้ขาด animation. ที่ยิงแล้วปืนไม่ขยับก่อนหน้านี้ = บั๊ก WeldConstraint (แก้ไปแล้ว).
**เทสในเกมก่อน** — idle/fire อาจเล่นปกติแล้ว.

## ทำไมดึง "frame animation" ต้นฉบับให้ไม่ได้

`game:GetObjects("rbxassetid://8317258850")` → **HTTP 403**
asset พวกนี้เป็นของผู้สร้าง CWS ไม่ใช่ของ account นี้ → export keyframe ออกมาไม่ได้

## ทางทำ animation เอง

1. เปิด Animation Editor → rig ตัว dummy R15 (CWS อนิเมตตัวละครผู้เล่น ไม่ใช่ viewmodel)
2. ทำ:
   - **idle** — Loop = true, Priority = `Idle` (หรือ `Movement`)
   - **fire** — Loop = false, Priority = `Action`
3. Publish → ได้ assetId
4. ส่ง id มา → ผมจะ wire ให้ (เลือกได้ 2 แบบ):

   **A. ทับ pistol group** — ง่าย แต่กระทบปืน pistol-group ทุกกระบอก
   **B. สร้าง group `taser` เฉพาะ** — clone pistol แล้วแก้เฉพาะ idle/fire,
      set `Info.anim.idle.group`/`fire.group` = `"taser"` — กระทบเฉพาะ taser (แนะนำ)

รัน `StudioWork/PrepTaserAnimGroup.lua` = เตรียมแบบ B ไว้ (ตอนนี้ยังใช้ id เดิม เป็น placeholder)
