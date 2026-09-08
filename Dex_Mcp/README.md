# Dex_Mcp

เชื่อม Claude กับ **Dex++ (out.lua)** ที่รันอยู่ในเกม Roblox ผ่าน MCP

Claude สั่งอ่าน instance tree / properties / decompile script / รัน Luau ได้จากในแชท

---

## โครงสร้าง

```
Dex_Mcp/
  server.js        MCP stdio server + HTTP listener 127.0.0.1:8790  (Node, zero dependency)
  DexBridge.lua    รันในโปรแกรม executor — โหลด Dex++ แล้วต่อกลับมาที่ server
  package.json
  README.md
```

```
Claude ──stdio JSON-RPC── server.js
                             │
                    127.0.0.1:8790
                             │
              GET /cmd (long-poll)  ←── DexBridge.lua (ในเกม)
              POST /result          ──→
```

---

## ติดตั้ง

### 1. ลงทะเบียน MCP server

ไม่ต้อง `npm install` — ไม่มี dependency

server.js รันได้ 2 โหมด เลือกเอาอันเดียว:

| โหมด | ใครสตาร์ท | bridge รอดตอนปิด session Claude ไหม |
|------|-----------|--------------------------------------|
| **daemon (แนะนำ)** | เราเอง / ตอน login | รอด |
| stdio | Claude spawn เป็น child | **ไม่รอด** — Dex ขึ้น Failed |

**วิธี A — daemon (แนะนำ)**

ดับเบิลคลิก `Dex_Mcp/start-daemon.cmd` (หรือ `npm run daemon`) แล้วปล่อยค้างไว้ จากนั้นลงทะเบียนแบบ http:

```powershell
claude mcp add dex --scope user --transport http http://127.0.0.1:8790/mcp
```

ให้สตาร์ทเองตอนเปิดเครื่อง: กด `Win+R` พิมพ์ `shell:startup` แล้วเอา shortcut ของ
`start-daemon-hidden.vbs` ไปวางในโฟลเดอร์ที่เด้งขึ้นมา (ตัว `.vbs` รันแบบไม่มีหน้าต่าง console)

`start-daemon-hidden.vbs` เรียก `daemon-loop.cmd` ซึ่งเป็น watchdog: เช็ค `/ping` ทุก 10 วินาที
ถ้า node ตายหรือยังไม่ขึ้นก็สตาร์ทใหม่ให้เอง และจะไม่สตาร์ท node ซ้ำถ้าพอร์ตตอบอยู่แล้ว
ถ้า MCP ขึ้น `failed` ให้เช็คก่อนว่า daemon ยังอยู่ไหม:

```powershell
netstat -ano | findstr 8790
curl http://127.0.0.1:8790/ping
```

ไม่มีอะไร `LISTENING` = daemon ตาย ให้เปิด `start-daemon-hidden.vbs` แล้ว `/mcp` reconnect ใน Claude

daemon อยู่ยาวข้าม session ของ Claude ทั้งหมด — เปิด/ปิด Claude กี่รอบ DexBridge ในเกมก็ไม่หลุด

**วิธี B — stdio (Claude spawn เอง)**

```powershell
claude mcp add dex --scope user -- node d:/ProjectValkyrieHub/Dex_Mcp/server.js
```

ง่ายกว่าแต่ `server.js` ตายพร้อม session ทุกครั้ง พอร์ต 8790 ปิด DexBridge ในเกมเลยขึ้น
`server unreachable` แล้ว Dex ก็ Failed — ใช้เฉพาะตอนลองสั้นๆ

รีสตาร์ท Claude Code แล้วเช็คด้วย `/mcp` — ต้องเห็น `dex` ขึ้นมา

### 2. เตรียมฝั่ง Roblox

DexBridge หาซอร์ส Dex++ ตามลำดับนี้:

1. Dex โหลดอยู่แล้ว (`getgenv().DexMain`) → ข้ามไปเลย
2. `getgenv().DexSource` เป็น string
3. ไฟล์ `out.lua` ใน workspace folder ของ executor
4. `CONFIG.DexUrl` (ค่าเริ่มต้นว่าง)

**ทางง่ายสุด:** ก็อป `out.lua` ไปไว้ใน workspace folder ของ executor (เช่น `Wave/workspace/out.lua`, `Solara/workspace/out.lua`)

**หรือ** โฮสต์ `out.lua` ไว้บน GitHub raw แล้วแก้ใน `DexBridge.lua`:

```lua
DexUrl = "https://raw.githubusercontent.com/<you>/<repo>/main/out.lua",
```

### 3. รัน bridge ในเกม

โยน `DexBridge.lua` ทั้งไฟล์เข้า executor แล้วกด execute หรือโหลดจาก URL:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/<you>/<repo>/main/Dex_Mcp/DexBridge.lua"))()
```

ถ้าติดจะเห็นใน console:

```
[DexBridge] connecting to http://127.0.0.1:8790
[DexBridge] connected
[DexBridge] ready - ops: console, decompile, exec, inject, props, select, status, tree
```

---

## ใช้ยังไง

คุยกับ Claude ปกติ:

> เช็คหน่อยว่า Dex ต่ออยู่ไหม

> ดู tree ใต้ `game.Workspace` ลึก 3 ชั้น

> Baseplate มี property อะไรบ้าง เอาเฉพาะที่ชื่อมี "color"

> decompile `game.Players.LocalPlayer.PlayerScripts.ClientMain` ให้หน่อย

> รัน Luau นับ Part ทั้งหมดใน Workspace

### Tool ทั้งหมด

| tool | ทำอะไร | args |
|---|---|---|
| `dex_status` | เช็คว่า bridge ต่ออยู่ + ข้อมูล place/player | — |
| `dex_tree` | เดิน instance tree | `path`, `path_parts`, `depth` (default 2, max 5) |
| `dex_props` | อ่าน property ทั้งหมด (รวมที่สืบทอดมา) | `path`, `filter`, `include_hidden` |
| `dex_decompile` | decompile script | `path` |
| `dex_exec` | รัน Luau แล้วเอาค่ากลับ | `code` |
| `dex_select` | เลื่อน Dex explorer ไปที่ instance นั้น | `path` |
| `dex_inject` | ยิงสคริปต์ทั้งไฟล์เข้าเกม แล้วเอา console กลับมา | `file`, `url`, `code`, `chunk_name`, `capture_ms`, `cleanup` |
| `dex_console` | อ่าน console ย้อนหลัง (LogService) | `count`, `filter`, `errors_only` |
| `dex_spy` | ดักทุก remote ที่ไคลเอนต์ยิงออก (ทุกสคริปต์ รวมของเกมเอง) | `action`, `incoming`, `max`, `limit`, `direction`, `filter`, `since` |

**เรื่อง path:** ใช้ dot path เช่น `"game.Workspace.Baseplate"` หรือ `"Workspace.Baseplate"` ก็ได้ ถ้าชื่อ instance มีจุดอยู่ในตัวเอง ให้ส่ง `path_parts` เป็น array แทน เช่น `["Workspace", "My.Weird.Name"]`

---

## Remote spy (`dex_spy`)

ดักทุก `FireServer` / `InvokeServer` ที่ออกจากไคลเอนต์ **ไม่ว่าสคริปต์ไหนเป็นคนยิง** — สคริปต์ของเกมเองก็ติด
ใช้ตอนที่เกิดอะไรฝั่งเซิร์ฟ (โดนเตะ / คำขอถูกปฏิเสธ / ทำงานแล้วเงียบ) แล้วต้องรู้ว่าจริง ๆ มีอะไรถูกส่งออกไปบ้าง

```jsonc
// เริ่มบันทึก (ล้าง buffer เดิม)
{ "action": "start" }

// เริ่มพร้อมดักขาเข้าด้วย (server -> client) — เสียงดัง ใช้เท่าที่จำเป็น
// ดักทุก RemoteEvent ใน ReplicatedStorage / ReplicatedFirst / Workspace / Lighting
// ไม่สนว่า folder ชื่ออะไร (Remotes, Network, ไม่มี folder เลยก็ได้)
// ผลลัพธ์บอก RemotesFound = เจอกี่ตัว, WatchedIn = อยู่ service ไหนบ้าง
{ "action": "start", "incoming": true }

// อ่านที่บันทึกไว้ ใหม่สุดอยู่ท้าย
{ "action": "read", "limit": 50 }

// อ่านเฉพาะที่ใหม่กว่ารอบก่อน ส่ง Latest จากผลลัพธ์ก่อนหน้ามา
{ "action": "read", "since": 128 }

// กรองตามชื่อ remote / argument / สคริปต์ที่เรียก
{ "action": "read", "filter": "hatch" }

{ "action": "status" }   // ดูว่ากำลังบันทึกอยู่ไหม เก็บไปกี่รายการ
{ "action": "stop" }     // หยุดบันทึก (hook ยังอยู่)
{ "action": "clear" }    // ล้าง buffer
```

แต่ละรายการที่ได้กลับมา:

| field | คือ |
|---|---|
| `N` | ลำดับ ใช้กับ `since` |
| `At` | วินาทีนับจากตอน `start` |
| `Dir` | `out` = ไคลเอนต์ยิงออก, `in` = เซิร์ฟส่งมา |
| `Method` | `FireServer` / `InvokeServer` / `OnClientEvent` |
| `Remote`, `Path`, `Class` | ตัว remote |
| `Args` | argument ที่ส่ง (ย่อแล้ว) |
| `From` | สคริปต์ที่เรียก — **บรรทัดที่ชี้ไปสคริปต์ของเกมเอง คือของน่าสนใจ** เพราะแปลว่าเกมเป็นคนส่ง ไม่ใช่เรา |

ขาเข้าจะเกาะ remote ที่เกิดทีหลังให้ด้วย (`DescendantAdded`) เพดานที่ 600 connection กันเกมที่มี remote เป็นพัน

ข้อจำกัด: hook ติดตั้งครั้งเดียวแล้วอยู่ยาว `stop` แค่หยุดบันทึก ไม่ได้ถอด hook (ถอด namecall metamethod คือส่วนที่พังง่าย)
executor ที่ไม่มี `hookmetamethod` / `getnamecallmethod` / `newcclosure` จะดักไม่ได้ — `start` จะบอกในผลลัพธ์ว่าติดตั้งอะไรได้บ้าง

---

## Injection (แก้ไฟล์ → ยิงเข้าเกม → อ่าน error)

`dex_exec` รันโค้ดสั้น ๆ แล้วรอค่ากลับ — สคริปต์จริงที่สร้าง UI แล้ววนลูปตลอดจะค้างจนหมด timeout
`dex_inject` เลยแยกออกมา: รันบน thread ของตัวเอง, เรียก teardown ตัวเก่าให้ก่อน, แล้วดัก console คืนมาให้แค่ช่วงสั้น ๆ

```
inject Scripts/STE.lua ให้หน่อย
```

Claude จะเรียก `dex_inject { file: "Scripts/STE.lua" }` แล้วอ่าน `Status` กลับมา:

| Status | แปลว่า |
|---|---|
| `running` | ปกติสำหรับสคริปต์ที่มี UI / ลูป — ไม่ใช่ error |
| `returned` | รันจนจบไฟล์ |
| `errored` | ดู `Error` เป็น traceback เต็ม |

- `file` นับ path จาก repo root (เปลี่ยนได้ด้วย `DEX_MCP_ROOT`) — ส่งได้อย่างเดียวจาก `file` / `url` / `code`
- `cleanup` ค่าเริ่มต้น `"ValkyrieCleanup"` คือ teardown ที่สคริปต์ใน repo นี้ฝากไว้ใน `getgenv()`
  ถ้าไม่เรียก การ inject ซ้ำจะได้หน้าต่างซ้อนกันสองอัน — สคริปต์ที่ไม่มี teardown ส่ง `""`
- `capture_ms` ค่าเริ่มต้น 1500 ms ถ้าสคริปต์โหลด UI library ผ่านเน็ตให้เพิ่มเป็น 5000
- error ที่โผล่หลังหมดช่วงดักจะไม่อยู่ใน `Output` — ใช้ `dex_console { errors_only: true }` ตามไปอ่าน

**Skill:** `.claude/skills/dex-inject/SKILL.md` เป็นตัวบอก Claude Code ว่า flow นี้ทำยังไง
พูดว่า "inject STE.lua" หรือ "ทำไมสคริปต์ error" ก็เข้าเงื่อนไขแล้ว ไม่ต้องเรียก tool เอง

---

## ตั้งค่า

**ฝั่ง server** (environment variable):

| var | default | ความหมาย |
|---|---|---|
| `DEX_MCP_PORT` | `8790` | port ที่ listen |
| `DEX_MCP_HOLD_MS` | `1000` | ค้าง long-poll นานสุดกี่ ms ก่อนตอบ 204 |
| `DEX_MCP_TIMEOUT_MS` | `20000` | รอผลจากเกมนานสุดกี่ ms |
| `DEX_MCP_TOKEN` | `""` | ถ้าตั้ง ต้องมี header `X-Dex-Token` ตรงกัน |
| `DEX_MCP_ROOT` | cwd | โฟลเดอร์ที่ `dex_inject.file` แบบ relative นับจาก |
| `DEX_MCP_MAX_INJECT` | `4194304` | ขนาดซอร์สสูงสุดที่ยอม inject (byte) |

**ฝั่ง Lua** — แก้ตาราง `CONFIG` หัวไฟล์ `DexBridge.lua` (`Host`, `Token`, `Gap`, `MaxNodes`, `MaxDepth`, `MaxString`, `AntiAFK`) หรือตั้งค่า `getgenv().DexAntiAFK = true/false`

ถ้าเปลี่ยน port ต้องแก้ **ทั้งสองฝั่ง**

---

## หยุด bridge

```lua
getgenv().DexBridgeStop()
```

รัน `DexBridge.lua` ซ้ำได้เลย — มันจะฆ่าตัวเก่าก่อนอัตโนมัติ

---

## ทำไมใช้ long-poll ไม่ใช่ WebSocket

server ค้าง `GET /cmd` ไว้จนกว่าจะมีคำสั่งเข้ามา แล้วตอบทันที latency จึงเกือบ 0 อยู่แล้ว
WebSocket จะช่วยได้แค่ตอนที่ไม่มี request ค้างอยู่ ซึ่งเป็นช่วงไม่กี่ ms
แลกกับความยุ่งยาก + executor หลายตัวไม่มี `WebSocket.connect` — ไม่คุ้ม

---

## Dex ขึ้น Failed ตอนปิด session Claude

อาการ: ใน executor console เห็น `[DexBridge] server unreachable, retrying...` ทุกครั้งที่ปิด Claude

สาเหตุ: `dex` ลงทะเบียนเป็น **stdio** อยู่ Claude เลยเป็นเจ้าของ process `server.js` — ปิด
session = child ตาย = พอร์ต 8790 ตาย = DexBridge หาเซิร์ฟไม่เจอ

วิธีแก้: ย้ายไป daemon + http ตาม [ติดตั้ง วิธี A](#1-ลงทะเบียน-mcp-server) ด้านบน
สั่งครั้งเดียวจบ:

```powershell
claude mcp remove dex --scope user
claude mcp add dex --scope user --transport http http://127.0.0.1:8790/mcp
```

แล้วเปิด `start-daemon.cmd` ค้างไว้ (หรือใส่ shortcut ของ `start-daemon-hidden.vbs` ใน `shell:startup`)

> ถ้าเปิด daemon แล้วเจอ `port 8790 already in use` แปลว่ายังมี `server.js` แบบ stdio
> ค้างจาก session เก่าอยู่ — ปิด Claude Code ให้หมดก่อน แล้วค่อยเปิด daemon

---

## แก้ปัญหา

**`timeout after 20000ms waiting for Dex bridge`**
Bridge ไม่ได้รัน หรือหลุด — เช็ค console ในเกม แล้ว execute `DexBridge.lua` ใหม่

**`anchor not found in Dex source`**
`out.lua` อัปเดตแล้วบรรทัดที่ใช้เกาะเปลี่ยนไป เปิด `out.lua` grep หา `InitAfterMain(appTable)` แล้วแก้ค่า `ANCHOR` ใน `DexBridge.lua`
(ปัจจุบันอยู่ที่ `out.lua:14539` มีที่เดียวในไฟล์)

**`your executor exposes no HTTP request function`**
Executor ไม่มี `request` / `syn.request` / `http_request` — ใช้ไม่ได้ ต้องเปลี่ยน executor

**`no Dex++ source found`**
ยังไม่ได้เอา `out.lua` ไปวางใน workspace folder และไม่ได้ตั้ง `CONFIG.DexUrl` — ดูขั้นตอนที่ 2

**`EADDRINUSE`**
port 8790 ถูกใช้อยู่ ตั้ง `DEX_MCP_PORT` ใหม่ แล้วแก้ `CONFIG.Host` ใน Lua ให้ตรง

**tool ตอบกลับมาใหญ่มากจน context เต็ม**
ลด `depth` ใน `dex_tree` หรือใส่ `filter` ใน `dex_props` ค่า cap เริ่มต้นคือ 2000 node / 4000 ตัวอักษรต่อ string

---

## ข้อควรระวัง

- `dex_exec` / `dex_inject` รัน Luau ด้วยสิทธิ์เต็มของ executor ในเกมที่คุณเข้าอยู่ — ตรวจโค้ดก่อนอนุมัติทุกครั้ง
  `dex_inject` อ่านไฟล์จากดิสก์ได้ตาม path ที่ส่งมา ให้ดูชื่อไฟล์ทุกครั้งก่อนกดอนุมัติ
- server bind แค่ `127.0.0.1` ไม่เปิดออกเน็ต แต่ script อื่นในเครื่องยิงได้ ถ้าห่วงให้ตั้ง `DEX_MCP_TOKEN`
- rejoin / teleport = Dex ตาย = bridge ตาย ต้อง execute ใหม่
- `dex_decompile` ใช้เวลาหลายวินาที ถ้าใช้ Konstant/Shiny ถ้าเกิน 20 วิ ให้เพิ่ม `DEX_MCP_TIMEOUT_MS`
