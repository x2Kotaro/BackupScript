# Probe snippets (tested live, OpiumwareMac, full sUNC)

Paste into `dex_exec`. Each one cleans up after itself and returns compact text.
Keep observation windows ≤ 12s (bridge op timeout ~20s).

## §0 Resolve an actor

```lua
-- Nearest NPC model under a root whose name matches a pattern. Swap the root for the game's NPC folder.
-- Player characters are skipped: some games (Ouwland) parent them under the same NPC folder.
local Players = game:GetService("Players")
local function nearest(root, pattern, from)
  local best, bd
  for _, m in ipairs(root:GetDescendants()) do
    if m:IsA("Model") and m.Name:match(pattern) and not Players:GetPlayerFromCharacter(m) then
      local r, h = m:FindFirstChild("HumanoidRootPart"), m:FindFirstChildOfClass("Humanoid")
      if r and h and h.Health > 0 then
        local d = (r.Position - from).Magnitude
        if not bd or d < bd then best, bd = m, d end
      end
    end
  end
  return best, bd
end
local me = game.Players.LocalPlayer.Character
local mob, d = nearest(workspace:FindFirstChild("Humanoids") or workspace, "^Bandit", me.HumanoidRootPart.Position)
return mob and (mob:GetFullName() .. " d=" .. math.floor(d)) or "none"
```

If a hub exposes its state (`getgenv().ValkyrieFarm.ConfigFarm.Mob`), use that instead,
so you measure the real target.

## §1 Snapshot: everything a mechanic could be stored in

```lua
local function snap(inst)
  local out = {}
  for k, v in pairs(inst:GetAttributes()) do out[#out+1] = "@" .. k .. "=" .. tostring(v) end
  for _, c in ipairs(inst:GetChildren()) do
    if not (c:IsA("BasePart") or c:IsA("Accessory") or c:IsA("Clothing")) then
      out[#out+1] = c.ClassName .. ":" .. c.Name .. (c:IsA("ValueBase") and ("=" .. tostring(c.Value)) or "")
    end
  end
  table.sort(out)
  return table.concat(out, ", ")
end
local U = require(game.ReplicatedStorage.CAM.Global.Utility)   -- game-specific values accessor, if any
local lp = game.Players.LocalPlayer
return "char: " .. snap(lp.Character) .. "\nvalues: " .. snap(U.getvaluesfolder(lp))
```

To diff states, call `snap` before and after an action in the same exec and return only
the entries that differ.

## §2 Module and preset dump (numbers that drive the mechanic)

```lua
local M = require(game.ReplicatedStorage.CAM.Global.Combat_presets)
local out = {}
for k, v in pairs(M) do out[#out+1] = k .. ":" .. (type(v) == "table" and "tbl" or tostring(v)) end
local p = M.Presets["Regular Katana"]
for k, v in pairs(p) do out[#out+1] = "  preset." .. k .. "=" .. (type(v) == "table" and "tbl" or tostring(v)) end
return table.concat(out, "\n")
```

Use `dex_decompile` on the ModuleScript for the full source, including nested tables and
server-side checks. To search a big decompile inside the game instead of returning all of it:

```lua
local s = decompile(game.ReplicatedStorage.CAM.Global.Checker)
local i = s:find("function t.check")
local names = {}
for w in s:sub(i, i + 9000):gmatch('FindFirstChild%("([%w_ ]+)"%)') do names[w] = true end
local l = {} for k in pairs(names) do l[#l+1] = k end table.sort(l)
return table.concat(l, ", ")   -- every child flag the check reads (Stun, CombatStun, Blocking, ...)
```

## §3 Function forensics: who implements, who touches

```lua
local f = require(game.ReplicatedStorage.CAM.Global.Combat_presets).Check_can_do_combat_server
local i = debug.getinfo(f)
local ks = {} for _, k in ipairs(getconstants(f)) do if type(k) == "string" then ks[#ks+1] = k end end
local ups = {} for k, v in pairs(getupvalues(f)) do ups[#ups+1] = tostring(k) .. ":" .. typeof(v) end
local out = { ("src=%s line=%s params=%s"):format(i.source, i.linedefined or i.currentline, i.numparams),
              "consts: " .. table.concat(ks, ","), "ups: " .. table.concat(ups, ",") }

-- Every closure whose constants mention a state name, i.e. all readers/writers of it:
for _, g in ipairs(filtergc("function", { Constants = { "last_combo" }, IgnoreExecutor = true }, false)) do
  local gi = debug.getinfo(g)
  out[#out+1] = "gc: " .. tostring(gi.source) .. ":" .. tostring(gi.linedefined or gi.currentline)
end
return table.concat(out, "\n")
```

- `decompile(fn)` fails on bare functions, so decompile `i.source`'s script.
- `getprotos(f)` lists nested functions. `getupvalues` exposes cached modules and state.
- Who listens to a signal: `for _, c in ipairs(getconnections(inst.ChildAdded)) do debug.getinfo(c.Function).source end`.
  This can return 0 for `GetAttributeChangedSignal`, so fall back to `filtergc`.

## §4 Timeline recorder (the main verification tool)

Records every relevant change on one clock. Set `ACTORS`, `WATCH` and `DURATION`. The
optional `act()` performs the controlled action (keep it to what the user would do anyway).

```lua
local RS = game:GetService("RunService")
local lp = game.Players.LocalPlayer
local me = lp.Character
local target = --[[ actor from §0 or hub state ]] nil
local ACTORS = { me = me, mob = target }
local WATCH = { RagDoll = 1, CombatStun = 1, Stun = 1, Strict_Stun = 1, iframe = 1, Blocking = 1 } -- child names; nil = all non-part children
local DURATION = 6
local MAXLINES = 40   -- keep the return small (token budget); raise only when needed
local NOISE = { "_Swings", "Slash_Effect", "damage_indicator", "^Add_", "state", "NpcNoticeEffect" } -- Ouwland FX spam

local t0, log, cs = os.clock(), {}, {}
local function L(s) if #log < MAXLINES then log[#log+1] = ("%.2f %s"):format(os.clock() - t0, s) end end
local function noisy(n) n = tostring(n) for _, p in ipairs(NOISE) do if n:find(p) then return true end end end
local function on(sig, fn) cs[#cs+1] = sig:Connect(fn) end

for tag, m in pairs(ACTORS) do
  if m then
    on(m.AttributeChanged, function(a) L(tag .. " @" .. a .. "=" .. tostring(m:GetAttribute(a))) end)
    on(m.ChildAdded, function(c) if not c:IsA("BasePart") and (not WATCH or WATCH[c.Name]) then
      L(tag .. " +" .. c.Name .. (c:IsA("ValueBase") and ("=" .. tostring(c.Value)) or "")) end end)
    on(m.ChildRemoved, function(c) if not WATCH or WATCH[c.Name] then L(tag .. " -" .. c.Name) end end)
    local h = m:FindFirstChildOfClass("Humanoid")
    if h then
      local last = h.Health
      on(h.HealthChanged, function(v) L(("%s hp %d->%d"):format(tag, last, v)) last = v end)
      local an = h:FindFirstChildOfClass("Animator")
      if an then on(an.AnimationPlayed, function(t) L(tag .. " anim " .. t.Animation.AnimationId) end) end
    end
  end
end
-- Server -> client FX about these actors (adjust the path to the game's effects remote):
local fx = game.ReplicatedStorage:FindFirstChild("Communication", true)
fx = fx and fx:FindFirstChild("EffectsEvent", true)
fx = fx and (fx:IsA("RemoteEvent") and fx or fx:FindFirstChildWhichIsA("RemoteEvent"))
if fx then on(fx.OnClientEvent, function(name, src, phase)
  if noisy(name) then return end
  for tag, m in pairs(ACTORS) do if src == m then L(tag .. " fx " .. tostring(name) .. " " .. tostring(phase)) end end
end) end

-- local function act() ... end  task.spawn(act)
task.wait(DURATION)
for _, c in ipairs(cs) do c:Disconnect() end
return table.concat(log, "\n"):sub(1, 1500)
```

For "how often / which kinds", count instead of logging lines:
`cnt[key] = (cnt[key] or 0) + 1`, then return `key xN` lines — far smaller than a raw log.

Holding position during an experiment (behind the target, facing it):

```lua
local hold = RS.Heartbeat:Connect(function()
  local r, mr = me.HumanoidRootPart, target.HumanoidRootPart
  if mr.Parent then local p = (mr.CFrame * CFrame.new(0, 0, 4)).Position
    r.CFrame = CFrame.lookAt(p, mr.Position) r.AssemblyLinearVelocity = Vector3.zero end
end)
-- ... hold:Disconnect() before returning
```

### Recording longer than the op timeout

Use `dex_inject { code = ..., cleanup = "" }` to start the recorder, storing lines in
`getgenv().MechLog` and a stopper in `getgenv().MechStop`. Then read it with
`dex_exec { code = "return table.concat(getgenv().MechLog, '\\n', math.max(1, #getgenv().MechLog - 80))" }`
and end with `getgenv().MechStop()`.

## §5 Call tracing (who calls what, with what, when)

Wrap a module field. This sees every caller that accesses it through the table:

```lua
local M = require(game.ReplicatedStorage.Communication.ServerAndClient.Signals.SignalEvent)
local KEY, orig, t0, log = "ToServer", nil, os.clock(), {}
orig = M[KEY]
M[KEY] = function(...)
  local a, p = table.pack(...), {}
  for i = 1, math.min(a.n, 7) do p[i] = tostring(a[i]) end
  log[#log+1] = ("%.2f %s <- %s"):format(os.clock() - t0, table.concat(p, ","), tostring(debug.info(2, "s")))
  return orig(...)
end
task.wait(4)
M[KEY] = orig
return #log .. " calls\n" .. table.concat(log, "\n", 1, math.min(#log, 25))
```

For callers that cached the function in an upvalue, use
`local old; old = hookfunction(fn, newcclosure(function(...) ... return old(...) end))`
and `restorefunction(fn)` in the same exec. Use `dex_spy` for raw remote traffic
(`start` → act → `read { direction = "out", filter = ... }`). It names the calling script.

## §6 Animations and hit timing

```lua
local an = target:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("Animator")
local out = {}
for _, t in ipairs(an:GetPlayingAnimationTracks()) do
  out[#out+1] = ("%s %s %.2f/%.2f speed=%.2f"):format(t.Name, t.Animation.AnimationId, t.TimePosition, t.Length, t.Speed)
end
return table.concat(out, "\n")
```

For hit frames, connect `track:GetMarkerReachedSignal(name)` or `track.KeyframeReached`
inside a §4 recorder, and compare them against the HP-drop timestamps to get the real
windup → damage delay.

## §7 Geometry: position, facing, reach, line of sight

```lua
local r, mr = me.HumanoidRootPart, target.HumanoidRootPart
local to = mr.Position - r.Position
if to.Magnitude < 0.01 then return "same position (target is yourself?)" end
local params = RaycastParams.new() params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = { me }
local hit = workspace:Raycast(r.Position, to, params)
return ("dist=%.1f facing=%.2f (1=looking at it) height=%.1f los=%s mobUp=%s"):format(
  to.Magnitude, r.CFrame.LookVector:Dot(to.Unit), -to.Y,
  tostring(hit == nil or hit.Instance:IsDescendantOf(target)), tostring(mr.CFrame.UpVector))
```

A mob's `UpVector` that isn't ~(0,1,0) means it's tilted or knocked down. Offsets built
from `mobCFrame * CFrame.new(...)` will swing sideways, so use world or flattened axes.
Log `facing` on every accepted hit to catch aim drift.

## §8 Counters for before/after checks

```lua
local me = game.Players.LocalPlayer.Character
local hits, bad, prev, seq = 0, 0, me:GetAttribute("last_combo"), {}
local c = me:GetAttributeChangedSignal("last_cmbat"):Connect(function()
  local n = me:GetAttribute("last_combo")
  local expect = (prev and prev >= 5) and 1 or ((prev or 0) + 1)
  hits += 1 if n ~= expect then bad += 1 end prev = n seq[#seq+1] = n
end)
task.wait(8) c:Disconnect()
return ("hits=%d outOfOrder=%d seq=%s"):format(hits, bad, table.concat(seq))
```

Adapt this to whatever the change was meant to improve: hits/sec, damage events, time spent
dodging, rejected actions.
