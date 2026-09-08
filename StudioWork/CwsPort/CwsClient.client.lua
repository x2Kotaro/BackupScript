-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
game:GetService("StarterPlayer")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local v_u_1 = RunService:IsStudio()
local v_u_2 = require((Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule")))
-- [port] placeId 102256505262642 has none of the cave place's shared modules.
-- GameSettings/Replica were only read for the dodge-animation pick (patched below),
-- so they are dropped outright and the other two are local stand-ins.
local GameSettings = nil
local Replica = nil
local BindableEvents = (function()
	local folder = ReplicatedStorage:FindFirstChild("CwsBindables")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "CwsBindables"
		folder.Parent = ReplicatedStorage
	end
	local api = {}
	function api:GetEvent(name)
		local event = folder:FindFirstChild(name)
		if not event then
			event = Instance.new("BindableEvent")
			event.Name = name
			event.Parent = folder
		end
		return event.Event
	end
	return api
end)()
local function canHitTarget(_, model)
	local humanoid = model and model:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end
-- [port] the cave place ships a patched PlayerModule that exposes GetShiftLockEnabled.
-- The stock module has no such method, so fall back to the mouse behaviour, which is
-- LockCenter for both shift lock and first person -- the two states CWS tests for.
local function getShiftLockEnabled()
	local ok, enabled = pcall(function()
		return v_u_2:GetShiftLockEnabled()
	end)
	if ok then
		return enabled
	end
	return game:GetService("UserInputService").MouseBehavior == Enum.MouseBehavior.LockCenter
end
local LocalPlayer = Players.LocalPlayer
local _ = game.ReplicatedStorage.Assets.Misc.CWS_Directory
local CWS = script:WaitForChild("CWS")
local LocalPlayer2 = require(CWS)(Players.LocalPlayer)
CWS:Destroy()
local t = {}
local t2 = {}
local v_u_3 = false
-- [port] this place has no Satchel backpack; WaitForChild would stall the script.
local BackpackGui = LocalPlayer.PlayerGui:FindFirstChild("BackpackGui") or Instance.new("ScreenGui")
BindKey = nil
local function unAim()
	--[[ line: 54 | upvalues: (copy) LocalPlayer2]]
	if LocalPlayer2.weapon.info then
		LocalPlayer2.weapon.state.aim = false
		LocalPlayer2.services.uis.MouseDeltaSensitivity = 1
		LocalPlayer2.services.ts:Create(LocalPlayer2.camera, TweenInfo.new(0.3), { FieldOfView = LocalPlayer2.origin.FOV }):Play()
		LocalPlayer2.human:SetAttribute("CanSprint", true)
	end
end
local function onMobileButtonAdded(p_u_4: userdata)
	--[[ line: 66 | upvalues: (copy) t2, (copy) LocalPlayer2, (ref) v_u_3, (copy) unAim]]
	if p_u_4.Name ~= "CROUCH" and p_u_4.Name ~= "JumpButton" then
		local v5 = t2
		table.insert(v5, p_u_4)
		local t3 = { KeyCode = LocalPlayer2.modules.settings.KeyBinds.keybinds[p_u_4.Name] }
		LocalPlayer2.events["mobile_down" .. p_u_4.Name] = p_u_4:GetAttributeChangedSignal("Pressing"):Connect(function()
			--[[ line: 74 | upvalues: (copy) p_u_4, (ref) v_u_3, (ref) unAim, (ref) LocalPlayer2, (copy) t3]]
			if p_u_4:GetAttribute("Pressing") then
				if v_u_3 then
					if p_u_4.Name == "AIM" then
						unAim()
						v_u_3 = false
						LocalPlayer2.keydown[LocalPlayer2:KeyToName(t3)] = false
					end
					if p_u_4.Name == "SHOOT" or p_u_4.Name == "RELOAD" then
						LocalPlayer2.keydown[LocalPlayer2:KeyToName(t3)] = true
						BindKey(t3)
					end
				else
					LocalPlayer2.keydown[LocalPlayer2:KeyToName(t3)] = true
					BindKey(t3)
					return
				end
			else
				return
			end
		end)
		LocalPlayer2.events["mobile_up" .. p_u_4.Name] = p_u_4:GetAttributeChangedSignal("Pressing"):Connect(function()
			--[[ line: 94 | upvalues: (copy) p_u_4, (ref) LocalPlayer2, (copy) t3]]
			if not p_u_4:GetAttribute("Pressing") then
				LocalPlayer2.keydown[LocalPlayer2:KeyToName(t3)] = false
			end
		end)
	end
end
local function setMobileButtonVisible(p6: boolean)
	--[[ line: 103 | upvalues: (copy) t2, (copy) v_u_2, (copy) LocalPlayer2]]
	for _2, v7 in pairs(t2) do
		if v7.Name ~= "AIM" or v_u_2:GetShiftLockEnabled() then
			v7.Visible = p6
		end
	end
	LocalPlayer2.gui.mobile.cursor.Visible = p6
end
local v_u_8 = tick()
local v_u_9 = nil
local v_u_10 = nil
task.spawn(function()
	--[[ line: 137 | upvalues: (copy) LocalPlayer, (ref) v_u_10]]
	v_u_10 = LocalPlayer.PlayerGui:WaitForChild("MousePositionGui"):WaitForChild("center")
end)
LocalPlayer2.origin.FOV = LocalPlayer2.camera.FieldOfView
LocalPlayer2.on_remote = {
	Shoot = function(p11, p12)
		--[[ line: 144 | upvalues: (copy) LocalPlayer, (copy) LocalPlayer2]]
		if p11 ~= LocalPlayer then
			if p12.fire_sound then
				local v13 = LocalPlayer2.modules.Func.GetRandom(-0.01, 0.01)
				local v14 = p12.fire_sound:Clone()
				v14.SoundGroup = game.SoundService.Master.Cws
				v14.Parent = p12.fire_sound.Parent
				v14.PlaybackSpeed = v13 + p12.fire_sound.PlaybackSpeed or v14.PlaybackSpeed
				v14:Play()
				LocalPlayer2.services.de:AddItem(v14, v14.TimeLength / v14.PlaybackSpeed)
			end
			if p12.handle then
				local fire_point = p12.handle:FindFirstChild("fire_point")
				local casing_point = p12.handle:FindFirstChild("casing_point")
				if fire_point and (casing_point and LocalPlayer2:OnScreen(fire_point.WorldPosition)) then
					local t4 = {
						weapon = {}
					}
					t4.weapon.handle = p12.handle
					t4.modules = LocalPlayer2.modules
					t4.weapon.last_shot_ray = p12.ray
					LocalPlayer2.EmitHandleEffects(t4, fire_point.Name)
					LocalPlayer2.EmitHandleEffects(t4, casing_point.Name)
				end
			end
			if p12.ray and (p12.pos and (LocalPlayer2.head and (LocalPlayer2:CreateRay(p12.ray, p12.pos, 7.5)(LocalPlayer2.head.Position) and not p12.is_tool))) then
				LocalPlayer2:PlaySoundFromHolder(LocalPlayer2.dir.sounds, "bullet_miss", LocalPlayer2.modules.Func.GetRandom(-0.2, 0.2), false)
				LocalPlayer2:CameraRecoil(Vector2.new(LocalPlayer2.modules.Func.GetRandom(-0.05, 0.05), LocalPlayer2.modules.Func.GetRandom(-0.05, 0.05)), { 3, LocalPlayer2.modules.Func.GetRandom(10, 30) }, LocalPlayer2.modules.Func.GetRandom(-40, 40))
				LocalPlayer2.gui.bullet_miss.ImageTransparency = 0
				LocalPlayer2.services.ts:Create(LocalPlayer2.gui.bullet_miss, TweenInfo.new(2), { ImageTransparency = 1 }):Play()
			end
		end
	end,
	RemoteSize = function(p15)
		--[[ line: 195 | upvalues: (copy) LocalPlayer2]]
		LocalPlayer2.remote_size_seed = p15
	end,
	PlaySound = function(p16, p17)
		--[[ line: 206 | upvalues: (copy) LocalPlayer, (copy) LocalPlayer2]]
		if p16 ~= LocalPlayer and p17.sound then
			if p17.pitch and p17.overlap then
				if not p17.sound:GetAttribute("origin_pitch") then
					p17.sound:SetAttribute("origin_pitch", p17.sound.PlaybackSpeed)
				end
				p17.pitch = p17.pitch + p17.sound:GetAttribute("origin_pitch")
			end
			if p17.overlap then
				p17.sound.PlaybackSpeed = p17.pitch or p17.sound.PlaybackSpeed
				p17.sound:Play()
				return
			end
			local v18 = p17.sound:Clone()
			v18.Parent = p17.sound.Parent
			v18.PlaybackSpeed = p17.pitch + p17.sound.PlaybackSpeed or v18.PlaybackSpeed
			v18:Play()
			LocalPlayer2.services.de:AddItem(v18, v18.TimeLength / v18.PlaybackSpeed)
		end
	end,
	SetHandleEffects = function(p19, p20)
		--[[ line: 230 | upvalues: (copy) LocalPlayer, (copy) LocalPlayer2]]
		if p19 ~= LocalPlayer and (p20.holder and (p20.name and p20.point)) then
			local t5 = {
				weapon = {}
			}
			t5.weapon.handle = p20.handle
			LocalPlayer2.SetHandleEffects(t5, p20.holder, p20.name, p20.point)
		end
	end,
	EmitHandleEffects = function(p21, p22)
		--[[ line: 238 | upvalues: (copy) LocalPlayer, (copy) LocalPlayer2]]
		if p21 ~= LocalPlayer and (p22.handle and p22.name) then
			local name = p22.handle:FindFirstChild(p22.name)
			if name and LocalPlayer2:OnScreen(name.WorldPosition) then
				local t6 = {
					weapon = {}
				}
				t6.weapon.handle = p22.handle
				t6.modules = LocalPlayer2.modules
				LocalPlayer2.EmitHandleEffects(t6, p22.name)
			end
		end
	end,
	HitEffect = function(p23, p24)
		--[[ line: 252 | upvalues: (copy) LocalPlayer, (copy) LocalPlayer2]]
		if p23 ~= LocalPlayer and (p24.pos and (LocalPlayer2:OnScreen(p24.pos) and LocalPlayer2:GetDistance(LocalPlayer2.camera.CFrame.Position, p24.pos) <= 500)) then
			local t7 = {
				weapon = {}
			}
			t7.weapon.info = {}
			t7.weapon.info.shotgun = p24.shotgun
			t7.player = LocalPlayer2.player
			LocalPlayer2.HitEffect(t7, p24.pos, p24.hit, p24.norm, p24.name, p24.impact_name, nil, 1)
		end
	end,
	CastBullet = function(p25, p26)
		--[[ line: 266 | upvalues: (copy) LocalPlayer, (copy) LocalPlayer2]]
		if p25 ~= LocalPlayer and (LocalPlayer2.char and (LocalPlayer2.head and (p26.ray and LocalPlayer2:CreateRay(p26.ray, p26.pos, 7.5)(LocalPlayer2.head.Position)))) then
			LocalPlayer2:PlaySoundFromHolder(LocalPlayer2.dir.sounds, "bullet_miss", LocalPlayer2.modules.Func.GetRandom(-0.2, 0.2), false)
			LocalPlayer2:CameraRecoil(Vector2.new(LocalPlayer2.modules.Func.GetRandom(-0.05, 0.05), LocalPlayer2.modules.Func.GetRandom(-0.05, 0.05)), { 3, LocalPlayer2.modules.Func.GetRandom(10, 30) }, LocalPlayer2.modules.Func.GetRandom(-40, 40))
			LocalPlayer2.gui.bullet_miss.ImageTransparency = 0
			LocalPlayer2.services.ts:Create(LocalPlayer2.gui.bullet_miss, TweenInfo.new(2), { ImageTransparency = 1 }):Play()
		end
	end,
	BulletHole = function(p27, p28)
		--[[ line: 290 | upvalues: (copy) LocalPlayer, (copy) LocalPlayer2]]
		if p27 ~= LocalPlayer and p28.pos then
			local _3 = LocalPlayer2:GetDistance(LocalPlayer2.camera.CFrame.Position, p28.pos) <= 1000
		end
	end,
	BloodSplatter = function(_4, p29)
		--[[ line: 299 | upvalues: (copy) LocalPlayer]]
		if LocalPlayer:GetAttribute("config_bloods") == true and (p29.target and p29.hit_name) then
			local hit_name = p29.target:FindFirstChild(p29.hit_name)
			if hit_name and not hit_name:FindFirstChild("cws_blood_splatter_texture") then
				for _5, v30 in pairs((Enum.NormalId:GetEnumItems())) do
					local v31 = math.random(0, 50) * 0.1
					local Texture = Instance.new("Texture")
					Texture.Texture = "rbxassetid://721969496"
					Texture.Parent = hit_name
					Texture.Face = v30
					Texture.OffsetStudsU = v31
					Texture.OffsetStudsV = v31
					Texture.StudsPerTileU = 2
					Texture.StudsPerTileV = 2
					Texture.Name = "cws_blood_splatter_texture"
					Texture.Color3 = Color3.new(0.419608, 0.419608, 0.419608)
					game.Debris:AddItem(Texture, 10)
				end
			end
		end
	end,
	Tracer = function(p32, p33)
		--[[ line: 322 | upvalues: (copy) LocalPlayer, (copy) LocalPlayer2]]
		if p32 ~= LocalPlayer and (p33.pos and (p33.name and (p33.start and p33.alpha))) then
			local t8 = { modules = LocalPlayer2.modules }
			LocalPlayer2.Tracer(t8, p33.pos, p33.name, p33.start, p33.alpha)
		end
	end
}
LocalPlayer2:GetRemotes()
local function highlight(p34)
	--[[ line: 334 | upvalues: (copy) TweenService]]
	if p34 then
		local Highlight = p34:FindFirstChild("Highlight")
		if not Highlight then
			Highlight = Instance.new("Highlight")
			Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
			Highlight.Parent = p34
		end
		Highlight.FillColor = Color3.fromRGB(255, 217, 217)
		Highlight.OutlineColor = Color3.fromRGB(255, 64, 64)
		Highlight.FillTransparency = 0.3
		Highlight.OutlineTransparency = 0.5
		Highlight.Parent = p34
		task.wait(0.05)
		local v35 = TweenService:Create(Highlight, TweenInfo.new(0.25), { FillTransparency = 0.5, OutlineTransparency = 0.75, FillColor = Color3.fromRGB(255, 64, 64) })
		v35:Play()
		v35.Completed:Wait()
		local v36 = TweenService:Create(Highlight, TweenInfo.new(0.05), { FillTransparency = 1, OutlineTransparency = 1 })
		v36:Play()
		v36.Completed:Wait()
		Highlight:Destroy()
	end
end
local t9 = {}
local function createdmgIndicator(p_u_37, p_u_38, p_u_39)
	--[[ line: 380 | upvalues: (copy) t9, (copy) TweenService]]
	task.spawn(function()
		--[[ line: 381 | upvalues: (copy) p_u_37, (ref) t9, (copy) p_u_38, (copy) p_u_39, (ref) TweenService]]
		local Head = p_u_37:FindFirstChild("Head")
		if Head then
			if t9[p_u_37] then
				t9[p_u_37].Gui:Destroy()
			end
			local v40 = (not t9[p_u_37] and 0 or t9[p_u_37].Damage) + p_u_38
			local Part = Instance.new("Part")
			Part.Anchored = true
			Part.CanCollide = false
			Part.CanQuery = false
			Part.Transparency = 1
			Part.Position = Head.Position + Vector3.new(0, 2, 0)
			Part.Parent = workspace
			local v41 = script.DamageGui:Clone()
			local Frame = v41:WaitForChild("Frame")
			local TextLabel = Frame:WaitForChild("TextLabel")
			local UIStroke = TextLabel:WaitForChild("UIStroke")
			v41.Enabled = true
			local v42 = v40 * 10
			local v43 = -math.floor(v42) / 10
			TextLabel.Text = tostring(v43)
			Frame.Rotation = math.random(-15, 15)
			t9[p_u_37] = { Gui = Part, Damage = v40 }
			if p_u_39 then
				TextLabel.TextColor3 = Color3.fromRGB(255, 33, 33)
				TextLabel.UIStroke.Transparency = 0.6
			end
			v41.Parent = Part
			local v44 = TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			local v45 = TweenService:Create(Part, TweenInfo.new(0.75, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), { Position = Part.Position + Vector3.new(0, 3, 0) })
			local v46 = TweenService:Create(TextLabel, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { TextTransparency = 1 })
			local v47 = TweenService:Create(UIStroke, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Transparency = 1 })
			TweenService:Create(Frame, v44, { Rotation = 0 }):Play()
			v45:Play()
			task.wait(0.5)
			v46:Play()
			v47:Play()
			v47.Completed:Wait()
			if t9[p_u_37] and t9[p_u_37].Gui == Part then
				t9[p_u_37] = nil
				Part:Destroy()
			end
		end
	end)
end
local function hitmarker(_6, _7, p48)
	--[[ line: 447 | upvalues: (copy) LocalPlayer2, (ref) v_u_10, (copy) TweenService, (copy) Debris]]
	local v49 = script[p48 and "Head" or "Body"]:Clone()
	local Size = v49.Size
	v49.Size = UDim2.fromScale(0, 0)
	v49.Parent = LocalPlayer2.mobile and LocalPlayer2.gui.mobile.cursor or v_u_10
	local v50 = TweenService:Create(v49, TweenInfo.new(0.25, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), { Size = Size })
	v50:Play()
	v50.Completed:Wait()
	task.wait(0.01)
	local v_u_51 = TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
	for _8, v_u_52 in pairs((v49:GetChildren())) do
		if v_u_52:IsA("ImageLabel") then
			task.spawn(function()
				--[[ line: 469 | upvalues: (ref) TweenService, (copy) v_u_52, (copy) v_u_51]]
				TweenService:Create(v_u_52, v_u_51, { ImageTransparency = 1 }):Play()
			end)
		end
	end
	Debris:AddItem(v49, 2)
end
local t10 = {}
local function FireProjectile()
	--[[ line: 501 | upvalues: (copy) LocalPlayer2, (copy) t10, (ref) v_u_3, (copy) LocalPlayer]]
	if LocalPlayer2.weapon.tool then
		if LocalPlayer2.weapon.tool:GetAttribute("ammo") <= 0 or (LocalPlayer2.weapon.info.projectile == nil or LocalPlayer2.weapon.info.projectile.object == nil) then
			return
		else
			local tool = LocalPlayer2.weapon.tool
			LocalPlayer2.weapon.lock_info = false
			LocalPlayer2.weapon.tool:SetAttribute("ammo", LocalPlayer2.weapon.tool:GetAttribute("ammo") - 1)
			local v53 = t10
			local I_Name = LocalPlayer2.weapon.tool:GetAttribute("I_Name")
			v53[I_Name] = v53[I_Name] - 1
			LocalPlayer2.weapon.lock_info = true
			LocalPlayer2:UpdateWeaponGui()
			local object = LocalPlayer2.weapon.tool:FindFirstChild(LocalPlayer2.weapon.info.projectile.object)
			if object then
				object.Transparency = 1
				LocalPlayer2:PlaySoundFromHolder(LocalPlayer2.weapon.handle, "fire", LocalPlayer2.modules.Func.GetRandom(-0.01, 0.01), false)
				local v54 = nil
				if LocalPlayer2.weapon.info.projectile.direction_type == 0 then
					if LocalPlayer2.mobile then
						local ViewportSize = LocalPlayer2.camera.ViewportSize
						local v55 = ViewportSize.X * 0.5
						local v56 = ViewportSize.Y * (v_u_3 and 0.5 or 0.3)
						v54 = LocalPlayer2.camera:ViewportPointToRay(v55, v56, 0).Direction * LocalPlayer2.weapon.info.projectile.force
					else
						v54 = CFrame.new(LocalPlayer.Character.Head.Position, LocalPlayer2.mouse.Hit.Position).LookVector * LocalPlayer2.weapon.info.projectile.force
					end
				elseif LocalPlayer2.weapon.info.projectile.direction_type == 1 then
					if LocalPlayer2.mobile then
						local ViewportSize2 = LocalPlayer2.camera.ViewportSize
						local v57 = ViewportSize2.X * 0.5
						local v58 = ViewportSize2.Y * (v_u_3 and 0.5 or 0.3)
						local v59 = LocalPlayer2.camera:ViewportPointToRay(v57, v58, 0).Direction * LocalPlayer2.weapon.info.projectile.force
						local dist = LocalPlayer2.weapon.info.projectile.dist
						v54 = v59 + Vector3.new(0, dist, 0)
					else
						local v60 = (LocalPlayer2.mouse.Hit.Position - LocalPlayer.Character.Head.Position).unit * LocalPlayer2.weapon.info.projectile.force
						local dist2 = LocalPlayer2.weapon.info.projectile.dist
						v54 = v60 + Vector3.new(0, dist2, 0)
					end
				end
				LocalPlayer2:PlayWeaponAnimation("fire")
				local v_u_61 = LocalPlayer2.services.http:GenerateGUID(false)
				local Name = tool.Name
				local v62 = nil
				local v63 = nil
				local v64 = nil
				if LocalPlayer2.weapon.info.explosive then
					if LocalPlayer2.weapon.info.explosive.when == 1 then
						local v65 = not LocalPlayer2.hold_time and 0 or tick() - LocalPlayer2.hold_time
						local v66 = LocalPlayer2.modules.Func.GetRandom(LocalPlayer2.weapon.info.explosive.fusetime[1], LocalPlayer2.weapon.info.explosive.fusetime[2]) - v65
						v62 = math.max(0, v66)
						v63 = function(p67)
							--[[ line: 566 | upvalues: (ref) LocalPlayer2, (copy) Name, (copy) v_u_61]]
							local t11 = { name = Name, pos = p67, id = v_u_61 }
							LocalPlayer2.dir.remos.Explode:FireServer(t11)
						end
					elseif LocalPlayer2.weapon.info.explosive.when == 0 then
						v64 = function(_9, p68)
							--[[ line: 570 | upvalues: (ref) LocalPlayer2, (copy) Name, (copy) v_u_61]]
							local t12 = { name = Name, pos = p68, id = v_u_61 }
							LocalPlayer2.dir.remos.Explode:FireServer(t12)
							return false, true
						end
					elseif LocalPlayer2.weapon.info.explosive.when == 2 then
						v64 = function(p69, p70, p71)
							--[[ line: 575 | upvalues: (ref) LocalPlayer2, (copy) Name, (copy) v_u_61]]
							if p71 == Vector3.FromNormalId(Enum.NormalId.Top) or p69.Parent:FindFirstChild("Humanoid") then
								local t13 = { name = Name, pos = p70, id = v_u_61 }
								LocalPlayer2.dir.remos.Explode:FireServer(t13)
								return false, true
							end
						end
					end
				end
				-- [port] same decompiler shadowing bug as CWS.RenderArms: the local named
				-- CFrame hid the global, so CFrame.new was nil by the next line.
				local headCFrame = LocalPlayer2.head.CFrame
				local X = object.Size.X
				local Y = object.Size.Y
				local Z = object.Size.Z
				local v72 = headCFrame * CFrame.new(0, 0, -math.max(X, Y, Z) - 2)
				if LocalPlayer2.mobile then
					local cameraCFrame = LocalPlayer2.camera.CFrame
					local X2 = object.Size.X
					local Y2 = object.Size.Y
					local Z2 = object.Size.Z
					v72 = cameraCFrame * CFrame.new(0, 0, -math.max(X2, Y2, Z2) - 2)
				end
				local v73 = nil
				if LocalPlayer2.weapon.info.projectile.hitsound then
					local hitsound = LocalPlayer2.dir.sounds:FindFirstChild(LocalPlayer2.weapon.info.projectile.hitsound)
					v73 = hitsound and {
						{ hitsound },
						0.1
					} or v73
				end
				LocalPlayer2:FireRemote("FireProjectile", {
					id = v_u_61,
					tool = tool,
					obj = object,
					pos = v72,
					vel = v54,
					life = v62,
					hitsound = v73,
					when = LocalPlayer2.weapon.info.explosive.when
				})
				local v74 = object:Clone()
				v74.Transparency = 0
				v74.Anchored = true
				for _10, v75 in ipairs((v74:GetChildren())) do
					if v75:IsA("ParticleEmitter") or (v75:IsA("PointLight") or v75:IsA("Trail")) then
						v75.Enabled = true
					end
				end
				local Weld = v74:FindFirstChildOfClass("Weld")
				if Weld then
					Weld:Destroy()
				end
				LocalPlayer2.modules.RigidBody.new({
					position = v72,
					velocity = v54,
					acceleration = LocalPlayer2.weapon.info.projectile.acceleration,
					elasticity = LocalPlayer2.weapon.info.projectile.elasticity,
					obj = v74,
					life = LocalPlayer2.weapon.info.projectile.life or v62,
					hitremove = LocalPlayer2.weapon.info.projectile.hitremove,
					ignore = { LocalPlayer2.char, LocalPlayer2.camera },
					angle_physics = LocalPlayer2.weapon.info.projectile.rotation,
					hitsound = v73,
					on_hit = v64,
					on_remove = v63
				})
			end
		end
	else
		return
	end
end
local function Shoot()
	--[[ line: 621 | upvalues: (copy) LocalPlayer2, (ref) v_u_3, (copy) v_u_2, (copy) Players, (copy) canHitTarget, (copy) LocalPlayer, (copy) Debris, (copy) highlight, (copy) createdmgIndicator, (copy) hitmarker]]
	LocalPlayer2.weapon.state.shooting = true
	LocalPlayer2:PlaySoundFromHolder(LocalPlayer2.weapon.handle, "fire", LocalPlayer2.modules.Func.GetRandom(-0.01, 0.01), false)
	if LocalPlayer2.weapon.handle:FindFirstChild("casing") then
		LocalPlayer2.modules.Func.Delay(LocalPlayer2.modules.Func.GetRandom(0.3, 0.8), function()
			--[[ line: 625 | upvalues: (ref) LocalPlayer2]]
			LocalPlayer2:PlaySoundFromHolder(LocalPlayer2.weapon.handle, "casing", LocalPlayer2.modules.Func.GetRandom(-0.1, 0.1))
		end)
	end
	if LocalPlayer2.weapon.tool:GetAttribute("ammo") - 1 < 1 then
		if LocalPlayer2:GetWeaponAnimation("last_fire") then
			LocalPlayer2:PlayWeaponAnimation("last_fire")
		else
			LocalPlayer2:PlayWeaponAnimation("fire")
		end
	else
		LocalPlayer2:PlayWeaponAnimation("fire")
	end
	LocalPlayer2:CameraRecoil(Vector2.new(LocalPlayer2.modules.Func.GetRandom(LocalPlayer2.weapon.info.recoil.dir.X[1], LocalPlayer2.weapon.info.recoil.dir.X[2]), LocalPlayer2.modules.Func.GetRandom(LocalPlayer2.weapon.info.recoil.dir.Y[1], LocalPlayer2.weapon.info.recoil.dir.Y[2])), LocalPlayer2.weapon.info.recoil.inout, LocalPlayer2.modules.Func.GetRandom(-LocalPlayer2.weapon.info.recoil.rotation, LocalPlayer2.weapon.info.recoil.rotation))
	LocalPlayer2.weapon.lock_info = false
	LocalPlayer2.weapon.tool:SetAttribute("ammo", LocalPlayer2.weapon.tool:GetAttribute("ammo") - 1)
	LocalPlayer2.weapon.lock_info = true
	LocalPlayer2:UpdateWeaponGui()
	local v_u_76 = true
	local Position = LocalPlayer2.head.Position
	local v77
	if LocalPlayer2.mobile then
		local ViewportSize3 = LocalPlayer2.camera.ViewportSize
		local v78 = ViewportSize3.Y * (v_u_3 and 0.5 or 0.35)
		local v79 = ViewportSize3.X * 0.5
		if v_u_2:GetShiftLockEnabled() then
			v79 = ViewportSize3.X * 0.525
		end
		local v80 = LocalPlayer2.camera:ViewportPointToRay(v79, v78)
		local _11 = v80.Direction
		local v81 = workspace:Raycast(v80.Origin, v80.Direction * 5000)
		v77 = v81 and v81.Position - LocalPlayer2.head.Position or v80.Direction
	else
		v77 = CFrame.new(LocalPlayer2.head.Position, LocalPlayer2.mouse.Hit.Position).LookVector
	end
	local v82 = CFrame.new(Vector3.new(), v77)
	local v83 = CFrame.fromOrientation(0, 0, (Random.new():NextNumber(0, 6.283185307179586)))
	local fromOrientation = CFrame.fromOrientation
	local v84 = Random.new():NextNumber(LocalPlayer2.spread, 0)
	local LookVector = (v82 * (v83 * fromOrientation(math.rad(v84), 0, 0))).LookVector
	local v85 = LocalPlayer2.weapon.state.aim and 0.5 or 1
	LocalPlayer2:SetSpread(LocalPlayer2.modules.Func.Lerp(LocalPlayer2.spread, LocalPlayer2.weapon.info.spread.max * (LocalPlayer2.human.WalkSpeed / (LocalPlayer2.services.sp.CharacterWalkSpeed / 2)) * v85, LocalPlayer2.weapon.info.spread.alpha))
	local function Cast(p86, p87, p88, p89, p90)
		--[[ line: 699 | upvalues: (ref) LocalPlayer2, (copy) Position, (ref) LookVector, (ref) v_u_76, (ref) Players, (ref) canHitTarget, (ref) LocalPlayer, (ref) Debris, (ref) highlight, (ref) createdmgIndicator, (ref) hitmarker]]
		local v91 = p90 or 1
		local v_u_92, v_u_93, v_u_94 = LocalPlayer2:LineCast(p86 or Position, LookVector, LocalPlayer2.weapon.info.max_dist or 1000, p87 or Enum.RaycastFilterType.Exclude, p88 or { LocalPlayer2.char, LocalPlayer2.camera })
		if LookVector and (Position and not LocalPlayer2.weapon.info.no_near_miss) then
			local v95 = LocalPlayer2:GetDistance(Position, v_u_93)
			if v_u_76 and v_u_93 then
				if not LocalPlayer2.weapon.info.tracer then
					LocalPlayer2.weapon.handle:FindFirstChild("fire_point")
				end
				LocalPlayer2:FireRemote("CastBullet", { ray = Ray.new(Position, LookVector * v95), pos = v_u_93 })
			end
		end
		LocalPlayer2:GetDistance(Position, v_u_93)
		if LocalPlayer2.weapon.info.tracer then
			LocalPlayer2:Tracer(v_u_93, LocalPlayer2.weapon.info.tracer.name, LocalPlayer2.weapon.handle:FindFirstChild("fire_point"), LocalPlayer2.weapon.info.tracer.alpha)
			LocalPlayer2:FireRemote("Tracer", {
				pos = v_u_93,
				name = LocalPlayer2.weapon.info.tracer.name,
				start = LocalPlayer2.weapon.handle:FindFirstChild("fire_point"),
				alpha = LocalPlayer2.weapon.info.tracer.alpha
			})
		end
		if p89 and not p89(v_u_93) then
			return
		end
		if v_u_92 then
			local Humanoid = v_u_92.Parent:FindFirstChildOfClass("Humanoid")
			local Parent = Players:GetPlayerFromCharacter(v_u_92.Parent)
			local v96 = Parent and canHitTarget(LocalPlayer, Parent) ~= true and true or false
			if Humanoid then
				if v_u_92.Name == "Head" then
					local headshot = LocalPlayer2.weapon.info.damage.headshot
					local v97 = LocalPlayer2.weapon.info.damage.headshot * v91
					local v98 = math.min(headshot, v97)
					local v99 = false
					local Character = LocalPlayer.Character
					if Character then
						Character = Character:FindFirstChild("Humanoid")
					end
					local v100 = Character:GetAttribute("DamageBoost") and true or v99
					local DefenseBoost = Humanoid:GetAttribute("DefenseBoost")
					local v101 = v98 * (v100 and 1.1 or 1) * (DefenseBoost and 0.9 or 1)
					if not v96 and (not LocalPlayer2.weapon.tool or LocalPlayer2.weapon.tool.Name ~= "\236\136\152\234\176\145" and LocalPlayer2.weapon.tool.Name ~= "BubbleGun") and not v_u_92.Parent:HasTag("Ragdoll") then
						local Parent2 = v_u_92.Parent
						local v_u_102 = script
						local HeadShotSound = game.ReplicatedStorage.Assets.Misc.CWS_Directory.sounds.HeadShotSound
						task.spawn(function()
							--[[ line: 478 | upvalues: (copy) HeadShotSound, (copy) v_u_102, (ref) Debris]]
							local v103 = HeadShotSound:Clone()
							v103.Parent = v_u_102
							v103:Play()
							Debris:AddItem(v103, 5)
						end)
						task.spawn(highlight, Parent2)
						task.spawn(createdmgIndicator, Parent2, v101, true)
						task.spawn(hitmarker, Parent2, v101, true)
					end
					LocalPlayer2:HitEffect(v_u_93, v_u_92, v_u_94, "Headshot", LocalPlayer2.weapon.info.effects.impact, function(p104)
						--[[ line: 751 | upvalues: (copy) v_u_93, (copy) v_u_92, (copy) v_u_94, (ref) LocalPlayer2]]
						local t14 = {
							Alpha = 0.2,
							DelayRemove = 10,
							Texture = p104.Value,
							Size = { Can = 10, Pic = p104.Size.Value },
							Color = p104.Color.Value,
							raycastResult = { Position = v_u_93, Instance = v_u_92, Normal = v_u_94 }
						}
						LocalPlayer2.modules.DecalSystem.New(t14)
					end, 10)
					local v105 = false
					for _12, v106 in ipairs((LocalPlayer2.services.plrs:GetChildren())) do
						if v106:GetAttribute("WantedLevel") ~= nil and (v106:GetAttribute("WantedLevel") > 1 and v106 ~= LocalPlayer) then
							local Character2 = v106.Character
							if Character2 and (Character2.PrimaryPart and LocalPlayer2:OnScreen(Character2.PrimaryPart.Position)) then
								v105 = true
								break
							end
						end
					end
					if not (v96 or LocalPlayer2.weapon.tool:GetAttribute("cantDamage")) then
						LocalPlayer2:FireRemote("Damage", {
							head = LocalPlayer2.head.Position,
							target = Humanoid,
							hit_name = v_u_92.Name,
							damage = v98,
							tool = LocalPlayer2.weapon.tool,
							velocity = LookVector * 500,
							auth = v105
						})
					end
					if LocalPlayer2.weapon.tool:GetAttribute("can_wanted") ~= nil then
						return v_u_92, v_u_93
					end
					LocalPlayer2:FireRemote("BloodSplatter", { target = Humanoid.Parent, hit_name = v_u_92.Name })
					return v_u_92, v_u_93
				end
				local v107 = LocalPlayer2.modules.Func.GetRandom(LocalPlayer2.weapon.info.damage.min, LocalPlayer2.weapon.info.damage.max)
				local v108 = v107 * v91
				local v109 = math.min(v107, v108)
				local v110 = false
				local Character3 = LocalPlayer.Character
				if Character3 then
					Character3 = Character3:FindFirstChild("Humanoid")
				end
				local v111 = Character3:GetAttribute("DamageBoost") and true or v110
				local DefenseBoost2 = Humanoid:GetAttribute("DefenseBoost")
				local v112 = v109 * (v111 and 1.1 or 1) * (DefenseBoost2 and 0.9 or 1)
				if not v96 and (not LocalPlayer2.weapon.tool or LocalPlayer2.weapon.tool.Name ~= "\236\136\152\234\176\145" and LocalPlayer2.weapon.tool.Name ~= "BubbleGun") and not v_u_92.Parent:HasTag("Ragdoll") then
					local Parent3 = v_u_92.Parent
					local v_u_113 = script
					local BodyShotSound = game.ReplicatedStorage.Assets.Misc.CWS_Directory.sounds.BodyShotSound
					task.spawn(function()
						--[[ line: 478 | upvalues: (copy) BodyShotSound, (copy) v_u_113, (ref) Debris]]
						-- [port] the decompiler inlined the headshot copy of this block here but left
						-- it pointing at the headshot locals, so every body shot threw on Clone.
						local v103 = BodyShotSound:Clone()
						v103.Parent = v_u_113
						v103:Play()
						Debris:AddItem(v103, 5)
					end)
					task.spawn(highlight, Parent3)
					task.spawn(createdmgIndicator, Parent3, v112, false)
					task.spawn(hitmarker, Parent3, v112, false)
				end
				LocalPlayer2:HitEffect(v_u_93, v_u_92, v_u_94, "Blood", LocalPlayer2.weapon.info.effects.impact, function(p114)
					--[[ line: 804 | upvalues: (copy) v_u_93, (copy) v_u_92, (copy) v_u_94, (ref) LocalPlayer2]]
					local t15 = {
						Alpha = 0.2,
						DelayRemove = 10,
						Texture = p114.Value,
						Size = { Can = 10, Pic = p114.Size.Value },
						Color = p114.Color.Value,
						raycastResult = { Position = v_u_93, Instance = v_u_92, Normal = v_u_94 }
					}
					LocalPlayer2.modules.DecalSystem.New(t15)
				end, 10)
				local v115 = false
				for _13, v116 in ipairs((LocalPlayer2.services.plrs:GetChildren())) do
					if v116:GetAttribute("WantedLevel") ~= nil and (v116:GetAttribute("WantedLevel") > 1 and v116 ~= LocalPlayer) then
						local Character4 = v116.Character
						if Character4 and (Character4.PrimaryPart and LocalPlayer2:OnScreen(Character4.PrimaryPart.Position)) then
							v115 = true
							break
						end
					end
				end
				if not (v96 or LocalPlayer2.weapon.tool:GetAttribute("cantDamage")) then
					LocalPlayer2:FireRemote("Damage", {
						head = LocalPlayer2.head.Position,
						target = Humanoid,
						hit_name = v_u_92.Name,
						damage = v109,
						tool = LocalPlayer2.weapon.tool,
						velocity = LookVector * 100,
						auth = v115
					})
				end
				if LocalPlayer2.weapon.tool:GetAttribute("can_wanted") ~= nil then
					return v_u_92, v_u_93
				end
				LocalPlayer2:FireRemote("BloodSplatter", { target = Humanoid.Parent, hit_name = v_u_92.Name })
				return v_u_92, v_u_93
			end
			local Material = v_u_92.Material
			local v_u_117 = nil
			if v_u_92:IsA("Terrain") and Material == Enum.Material.Plastic then
				Material = Enum.Material.Water
			end
			LocalPlayer2:HitEffect(v_u_93, v_u_92, v_u_94, tostring(Material), LocalPlayer2.weapon.info.effects.impact, function(p118)
				--[[ line: 857 | upvalues: (ref) v_u_117, (copy) v_u_92, (copy) v_u_93, (copy) v_u_94, (ref) LocalPlayer2]]
				v_u_117 = p118
				local t16 = {
					Alpha = 0.2,
					DelayRemove = 10,
					Texture = p118.Value,
					Size = { Can = 10, Pic = p118.Size.Value / 3 },
					Color = v_u_92.Color,
					raycastResult = { Position = v_u_93, Instance = v_u_92, Normal = v_u_94 }
				}
				LocalPlayer2.modules.DecalSystem.New(t16)
			end, 10)
		end
		return v_u_92, v_u_93
	end
	local v119 = nil
	if LocalPlayer2.weapon.info.shotgun then
		for _14 = 1, LocalPlayer2.weapon.info.shotgun.count do
			local _15
			_15, v119 = Cast()
			local v120 = CFrame.fromOrientation(0, 0, (Random.new():NextNumber(0, 6.283185307179586)))
			local fromOrientation2 = CFrame.fromOrientation
			local v121 = Random.new():NextNumber(LocalPlayer2.spread, 0)
			LookVector = (v82 * (v120 * fromOrientation2(math.rad(v121), 0, 0))).LookVector
		end
	else
		local _16
		_16, v119 = Cast()
	end
	local v122 = LocalPlayer2:GetDistance(Position, v119)
	local v123 = Ray.new(Position, LookVector * v122)
	LocalPlayer2.weapon.last_shot_ray = v123
	LocalPlayer2:EmitHandleEffects("fire_point")
	LocalPlayer2:EmitHandleEffects("casing_point")
	local v124 = false
	for _17, v125 in ipairs((LocalPlayer2.services.plrs:GetChildren())) do
		if v125:GetAttribute("WantedLevel") ~= nil and (v125:GetAttribute("WantedLevel") > 0 and v125 ~= LocalPlayer) then
			local Character5 = v125.Character
			if Character5 and (Character5.PrimaryPart and LocalPlayer2:OnScreen(Character5.PrimaryPart.Position)) then
				v124 = true
				break
			end
		end
	end
	if v119 then
		local v126 = LocalPlayer2:GetDistance(Position, v119)
		LocalPlayer2:FireRemote("Shoot", {
			tool = LocalPlayer2.weapon.tool,
			fire_sound = LocalPlayer2.weapon.handle:FindFirstChild("fire"),
			handle = LocalPlayer2.weapon.handle,
			ray = Ray.new(Position, LookVector * v126),
			pos = v119,
			auth = v124,
			is_tool = LocalPlayer2.weapon.info.do_not_bullet_miss or LocalPlayer2.weapon.info.tool or false
		})
	end
	LocalPlayer2.modules.Func.QueueWait(60 / LocalPlayer2.weapon.info.rpm, function(p127)
		--[[ line: 960 | upvalues: (ref) LocalPlayer2]]
		LocalPlayer2.queues.rpm = p127
	end)
	LocalPlayer2.weapon.state.shooting = false
	local _18 = false
end
local v_u_128 = 0
local function request_dodge()
	--[[ line: 994 | upvalues: (copy) LocalPlayer2, (ref) v_u_128, (copy) GameSettings, (copy) Replica, (copy) LocalPlayer]]
	if not LocalPlayer2.weapon.state.dodging and LocalPlayer2.human:GetAttribute("RagdollEnabled") == false then
		if tick() - v_u_128 < 1.5 then
			return
		end
		v_u_128 = tick()
		local v129 = 1 -- [port] was GameSettings.TEAM_CONFIG[Replica.Data.TeamId].CanDodge and 2 or 1
		local _19 = LocalPlayer.CameraMode
		local v130 = "Dodge" .. v129
		local Length = LocalPlayer2:GetAnimation(v130).Length
		local t17 = { Enum.PlayerActions.CharacterJump }
		if v129 == 1 then
			t17 = Enum.PlayerActions:GetEnumItems()
		end
		LocalPlayer2.services.cas:BindAction("freezeMovement", function()
			--[[ line: 1017 | upvalues: none]]
			return Enum.ContextActionResult.Sink
		end, false, table.unpack(t17))
		task.delay(Length, function()
			--[[ line: 1023 | upvalues: (ref) LocalPlayer2]]
			LocalPlayer2.services.cas:UnbindAction("freezeMovement")
		end)
		LocalPlayer2:PlaySoundFromHolder(LocalPlayer2.dir.sounds, v130, LocalPlayer2.modules.Func.GetRandom(-0.1, 0.1), false)
		LocalPlayer2:FireRemote("Dodge", { skill = v129 })
		task.spawn(function()
			--[[ line: 1028 | upvalues: (ref) LocalPlayer2]]
			for _20 = 1, 45 do
				LocalPlayer2.human:Move(LocalPlayer2.hrp.CFrame.LookVector, false)
				LocalPlayer2.services.rs.RenderStepped:Wait()
			end
		end)
		LocalPlayer2.weapon.state.dodging = true
		LocalPlayer2:PlayAnimation(v130)
		task.wait(Length + 0.5)
		LocalPlayer2.weapon.state.dodging = false
	end
end
local v_u_131 = os.clock()
local v_u_132 = false
function BindKey(p133)
	--[[ line: 1045 | upvalues: (copy) LocalPlayer2, (ref) v_u_131, (ref) v_u_132, (copy) FireProjectile, (copy) Shoot, (ref) v_u_8, (ref) v_u_9, (copy) v_u_2, (ref) v_u_3, (copy) LocalPlayer, (copy) request_dodge]]
	local function CanShoot()
		--[[ line: 1046 | upvalues: (ref) LocalPlayer2]]
		local v134 = LocalPlayer2.weapon.tool and LocalPlayer2.weapon.state.equipped and (LocalPlayer2.weapon.handle and not LocalPlayer2.weapon.state.melee_attack and not (LocalPlayer2.weapon.state.shooting or LocalPlayer2.weapon.state.reloading))
		if v134 then
			if LocalPlayer2.human.Health > 0 then
				v134 = LocalPlayer2:CheckTool()
			else
				v134 = false
			end
		end
		return v134
	end
	LocalPlayer2:BindKey(p133, function(_21, p135)
		--[[ line: 1047 | upvalues: (copy) CanShoot, (ref) v_u_131, (ref) LocalPlayer2, (ref) v_u_132, (ref) FireProjectile, (ref) Shoot, (ref) v_u_8, (ref) v_u_9, (ref) v_u_2, (ref) v_u_3, (ref) LocalPlayer, (ref) request_dodge]]
		if p135("SHOOT") and CanShoot() then
			local v_u_136 = os.clock()
			v_u_131 = v_u_136
			if LocalPlayer2.weapon.state.hold_down then
				if LocalPlayer2.weapon.state.hold_down then
					LocalPlayer2.weapon.state.hold_down = false
					LocalPlayer2:StopWeaponAnimation("hold_down")
					local v137 = LocalPlayer2
					v137.viewmodel_offset = v137.viewmodel_offset * CFrame.new(0, 0, -0.5)
				end
				if LocalPlayer2.weapon.state.hold_down_by_force then
					return
				end
				v_u_132 = true
			end
			local v_u_138 = false
			local function cancelled()
				--[[ line: 1061 | upvalues: (ref) v_u_138, (copy) v_u_136, (ref) v_u_131, (ref) v_u_132, (ref) LocalPlayer2]]
				if not v_u_138 then
					v_u_138 = true
					if v_u_136 == v_u_131 then
						task.delay(0.5, function()
							--[[ line: 1069 | upvalues: (ref) v_u_136, (ref) v_u_131, (ref) v_u_132, (ref) LocalPlayer2]]
							if v_u_136 == v_u_131 and (v_u_132 and not LocalPlayer2.weapon.state.hold_down) then
								LocalPlayer2.weapon.state.hold_down_by_force = false
								LocalPlayer2.weapon.state.hold_down = true
								LocalPlayer2:PlayWeaponAnimation("hold_down")
								local v139 = LocalPlayer2
								v139.viewmodel_offset = v139.viewmodel_offset * CFrame.new(0, 0, 0.5)
							end
						end)
					end
				end
			end
			if LocalPlayer2.weapon.info.projectile then
				if LocalPlayer2.weapon.info.explosive and (LocalPlayer2.weapon.info.explosive.holdable and (LocalPlayer2.weapon.info.explosive.fusetime and LocalPlayer2.weapon.info.explosive.when == 1)) then
					LocalPlayer2:PlaySoundFromHolder(LocalPlayer2.weapon.handle, "hold", 0, false)
					LocalPlayer2.weapon.state.holdpreparing = true
					LocalPlayer2.hold_time = tick()
					local tool2 = LocalPlayer2.weapon.tool
					LocalPlayer2.holding_tool = tool2
					LocalPlayer2:PlayWeaponAnimation("pull")
					task.spawn(function()
						--[[ line: 1087 | upvalues: (copy) tool2, (ref) LocalPlayer2, (ref) FireProjectile]]
						while task.wait(1) and (tool2 == LocalPlayer2.weapon.tool and (LocalPlayer2.holding_tool == tool2 and LocalPlayer2.holding_tool)) do
							if tick() - LocalPlayer2.hold_time >= LocalPlayer2.weapon.info.explosive.fusetime[2] and (LocalPlayer2.holding_tool and tool2 == LocalPlayer2.weapon.tool) then
								FireProjectile()
								return
							end
						end
					end)
				else
					FireProjectile()
				end
			elseif LocalPlayer2.weapon.tool:GetAttribute("ammo") > 0 then
				if LocalPlayer2.weapon.info.fire_mode > 0 then
					LocalPlayer2.modules.Func.Spawn(function()
						--[[ line: 1104 | upvalues: (ref) LocalPlayer2, (ref) Shoot, (ref) v_u_138, (copy) v_u_136, (ref) v_u_131, (ref) v_u_132]]
						if LocalPlayer2.weapon.info.fire_mode <= 1 then
							Shoot()
						else
							for _22 = 1, LocalPlayer2.weapon.info.fire_mode do
								Shoot()
							end
						end
						if not v_u_138 then
							v_u_138 = true
							if v_u_136 == v_u_131 then
								task.delay(0.5, function()
									--[[ line: 1069 | upvalues: (ref) v_u_136, (ref) v_u_131, (ref) v_u_132, (ref) LocalPlayer2]]
									if v_u_136 == v_u_131 and (v_u_132 and not LocalPlayer2.weapon.state.hold_down) then
										LocalPlayer2.weapon.state.hold_down_by_force = false
										LocalPlayer2.weapon.state.hold_down = true
										LocalPlayer2:PlayWeaponAnimation("hold_down")
										local v139 = LocalPlayer2
										v139.viewmodel_offset = v139.viewmodel_offset * CFrame.new(0, 0, 0.5)
									end
								end)
							end
						end
					end)
				else
					LocalPlayer2.modules.Func.Spawn(function()
						--[[ line: 1116 | upvalues: (ref) v_u_8, (ref) LocalPlayer2, (ref) v_u_9, (copy) cancelled, (ref) CanShoot, (ref) Shoot, (ref) v_u_138, (copy) v_u_136, (ref) v_u_131, (ref) v_u_132]]
						local v140 = tick()
						v_u_8 = v140
						local fire_ready = LocalPlayer2.weapon.handle:FindFirstChild("fire_ready")
						if fire_ready then
							fire_ready:Clone().Parent = LocalPlayer2.hrp
							v_u_9 = LocalPlayer2:PlaySoundFromHolder(LocalPlayer2.hrp, "fire_ready", nil, true)
						end
						if LocalPlayer2.weapon.info.anim.fire_ready then
							LocalPlayer2:PlayWeaponAnimation("fire_ready")
						end
						if LocalPlayer2.weapon.info.fire_ready then
							task.wait(LocalPlayer2.weapon.info.fire_ready)
							if v_u_8 ~= v140 then
								return cancelled()
							end
							LocalPlayer2:StopWeaponAnimation("fire_ready")
						end
						while LocalPlayer2.keydown.SHOOT and (CanShoot() and LocalPlayer2.weapon.tool:GetAttribute("ammo") > 0) do
							Shoot()
						end
						if not v_u_138 then
							v_u_138 = true
							if v_u_136 == v_u_131 then
								task.delay(0.5, function()
									--[[ line: 1069 | upvalues: (ref) v_u_136, (ref) v_u_131, (ref) v_u_132, (ref) LocalPlayer2]]
									if v_u_136 == v_u_131 and (v_u_132 and not LocalPlayer2.weapon.state.hold_down) then
										LocalPlayer2.weapon.state.hold_down_by_force = false
										LocalPlayer2.weapon.state.hold_down = true
										LocalPlayer2:PlayWeaponAnimation("hold_down")
										local v139 = LocalPlayer2
										v139.viewmodel_offset = v139.viewmodel_offset * CFrame.new(0, 0, 0.5)
									end
								end)
							end
						end
					end)
				end
			else
				LocalPlayer2:PlaySoundFromHolder(LocalPlayer2.weapon.handle, "empty", nil, true)
			end
			return
		end
		if p135("RELOAD") and (LocalPlayer2.weapon.tool and (LocalPlayer2.weapon.state.equipped and (not LocalPlayer2.weapon.state.shooting and (not LocalPlayer2.weapon.state.melee_attack and (not LocalPlayer2.weapon.state.reloading and (LocalPlayer2.human.Health > 0 and (LocalPlayer2.weapon.tool:GetAttribute("ammo") < LocalPlayer2.weapon.info.max_ammo and LocalPlayer2:CheckTool()))))))) then
			LocalPlayer2.weapon.state.reloading = true
			local reload = LocalPlayer2.weapon.handle:FindFirstChild("reload")
			if reload then
				LocalPlayer2:FireRemote("PlaySound", { overlap = true, sound = reload })
				LocalPlayer2:PlaySoundFromHolder(LocalPlayer2.weapon.handle, "reload", nil, true)
			end
			LocalPlayer2:PlayWeaponAnimation("reload")
			LocalPlayer2.weapon.lock_info = false
			LocalPlayer2.weapon.tool:SetAttribute("ammo", 0)
			LocalPlayer2:UpdateWeaponGui()
			LocalPlayer2.weapon.lock_info = true
			local UIGradient = LocalPlayer2.gui.weapon.icon:FindFirstChild("UIGradient")
			local v_u_141
			if UIGradient then
				UIGradient.Offset = Vector2.new(-0.6, 0)
				v_u_141 = LocalPlayer2.services.ts:Create(UIGradient, TweenInfo.new(LocalPlayer2.weapon.info.reload_time + 1), { Offset = Vector2.new(0.6, 0) })
				v_u_141:Play()
			else
				v_u_141 = nil
			end
			local v_u_142 = false
			LocalPlayer2.modules.Func.QueueWait(LocalPlayer2.weapon.info.reload_time, function(p143)
				--[[ line: 1172 | upvalues: (ref) LocalPlayer2, (ref) v_u_142, (ref) v_u_141, (ref) UIGradient]]
				LocalPlayer2.queues.reload_time = p143
				p143.Event:Connect(function()
					--[[ line: 1174 | upvalues: (ref) v_u_142, (ref) v_u_141, (ref) UIGradient]]
					v_u_142 = true
					if v_u_141 and UIGradient then
						v_u_141:Cancel()
						UIGradient.Offset = Vector2.new(0.6, 0)
						v_u_141 = nil
						UIGradient = nil
					end
				end)
			end)
			if v_u_142 then
				LocalPlayer2.weapon.state.reloading = false
			else
				LocalPlayer2.weapon.lock_info = false
				LocalPlayer2.weapon.tool:SetAttribute("ammo", LocalPlayer2.weapon.info.max_ammo)
				LocalPlayer2.weapon.lock_info = true
				LocalPlayer2:UpdateWeaponGui()
				LocalPlayer2.weapon.state.reloading = false
			end
			return
		end
		if p135("HOLD_DOWN") and (LocalPlayer2.weapon.tool and (LocalPlayer2.weapon.state.equipped and (not LocalPlayer2.weapon.state.reloading and (not LocalPlayer2.weapon.state.aim and (not LocalPlayer2.weapon.state.melee_attack and (not LocalPlayer2.weapon.state.shooting and LocalPlayer2:CheckTool())))))) then
			if LocalPlayer2.weapon.state.hold_down then
				if LocalPlayer2.weapon.state.hold_down then
					LocalPlayer2.weapon.state.hold_down = false
					LocalPlayer2:StopWeaponAnimation("hold_down")
					local v144 = LocalPlayer2
					v144.viewmodel_offset = v144.viewmodel_offset * CFrame.new(0, 0, -0.5)
				end
			elseif not LocalPlayer2.weapon.state.hold_down then
				LocalPlayer2.weapon.state.hold_down_by_force = true
				LocalPlayer2.weapon.state.hold_down = true
				LocalPlayer2:PlayWeaponAnimation("hold_down")
				local v145 = LocalPlayer2
				v145.viewmodel_offset = v145.viewmodel_offset * CFrame.new(0, 0, 0.5)
			end
		end
		if p135("AIM") and (LocalPlayer2.weapon.tool and (LocalPlayer2.weapon.state.equipped and (v_u_2:GetShiftLockEnabled() or LocalPlayer2:IsFirstPerson()))) and (LocalPlayer2.weapon.info.aim and (not LocalPlayer2.weapon.state.melee_attack and (not LocalPlayer2.weapon.state.reloading and LocalPlayer2:CheckTool()))) then
			if LocalPlayer2.mobile then
				if LocalPlayer2.weapon.state.aim then
					LocalPlayer2.weapon.state.aim = false
					LocalPlayer2.services.uis.MouseDeltaSensitivity = 1
					LocalPlayer2.services.ts:Create(LocalPlayer2.camera, TweenInfo.new(LocalPlayer2.weapon.info.aim.inout[2]), { FieldOfView = LocalPlayer2.origin.FOV }):Play()
					if LocalPlayer2.weapon.tool and LocalPlayer2.weapon.tool.Parent:IsA("Model") then
						LocalPlayer2:UpdateCrosshair()
					end
				else
					LocalPlayer2.weapon.state.aim = true
					LocalPlayer2.services.uis.MouseDeltaSensitivity = LocalPlayer2.weapon.info.aim.delta
					LocalPlayer2.services.ts:Create(LocalPlayer2.camera, TweenInfo.new(LocalPlayer2.weapon.info.aim.inout[1]), { FieldOfView = LocalPlayer2.weapon.info.aim.fov }):Play()
				end
			else
				LocalPlayer2.weapon.state.aim = true
				LocalPlayer2.services.uis.MouseDeltaSensitivity = LocalPlayer2.weapon.info.aim.delta
				LocalPlayer2.services.ts:Create(LocalPlayer2.camera, TweenInfo.new(LocalPlayer2.weapon.info.aim.inout[1]), { FieldOfView = LocalPlayer2.weapon.info.aim.fov }):Play()
			end
			LocalPlayer2.human:SetAttribute("CanSprint", false)
			if LocalPlayer2.weapon.state.aim then
				v_u_3 = true
			end
		end
		if p135("MELEE_ATTACK") and (LocalPlayer2.weapon.tool and (LocalPlayer2.weapon.state.equipped and (not LocalPlayer2.weapon.state.melee_attack and (not LocalPlayer2.weapon.state.shooting and (not LocalPlayer2.weapon.state.aim and LocalPlayer2:CheckTool()))))) then
			if LocalPlayer2.weapon.info.melee_attack then
				LocalPlayer2.weapon.state.reloading = false
				if LocalPlayer2.queues.reload_time then
					LocalPlayer2.queues.reload_time:Fire()
				end
				LocalPlayer2:StopAllSoundsFromHolder(LocalPlayer2.weapon.handle)
				LocalPlayer2:StopWeaponAnimation("reload")
				LocalPlayer2:PlayWeaponAnimation("melee_attack")
				LocalPlayer2:PlaySoundFromHolder(LocalPlayer2.weapon.handle, "melee_attack", nil, true)
				LocalPlayer2:FireRemote("PlaySound", { overlap = true, sound = LocalPlayer2.weapon.handle:FindFirstChild("melee_attack") })
				local v_u_146 = nil
				task.delay(0.1, function()
					--[[ line: 1249 | upvalues: (ref) v_u_146, (ref) LocalPlayer2, (ref) LocalPlayer]]
					v_u_146 = LocalPlayer2.weapon.handle.Touched:Connect(function(p147)
						--[[ line: 1250 | upvalues: (ref) LocalPlayer2, (ref) v_u_146, (ref) LocalPlayer]]
						local Humanoid2 = p147.Parent:FindFirstChild("Humanoid")
						if Humanoid2 and Humanoid2 ~= LocalPlayer2.human then
							LocalPlayer2:HitEffect(p147.Position, p147, Vector3.FromNormalId(Enum.NormalId.Front), "Punch", LocalPlayer2.weapon.info.effects.impact, nil, 10)
							v_u_146:Disconnect()
							v_u_146 = nil
							local v148 = false
							for _23, v149 in ipairs((LocalPlayer2.services.plrs:GetChildren())) do
								if v149:GetAttribute("WantedLevel") ~= nil and (v149:GetAttribute("WantedLevel") > 1 and v149 ~= LocalPlayer) then
									local Character6 = v149.Character
									if Character6 and (Character6.PrimaryPart and LocalPlayer2:OnScreen(Character6.PrimaryPart.Position)) then
										v148 = true
										break
									end
								end
							end
							if not LocalPlayer2.weapon.tool:GetAttribute("cantDamage") then
								LocalPlayer2:FireRemote("Damage", {
									head = LocalPlayer2.head.Position,
									target = Humanoid2,
									hit_name = p147.Name,
									damage = LocalPlayer2.weapon.info.melee_attack.damage,
									tool = LocalPlayer2.weapon.tool,
									velocity = LocalPlayer2.head.CFrame.LookVector * 100,
									auth = v148,
									ragdoll = LocalPlayer2.weapon.info.melee_attack.ragdoll
								})
							end
						end
					end)
					task.wait(0.25)
					if v_u_146 then
						v_u_146:Disconnect()
						v_u_146 = nil
					end
				end)
				LocalPlayer2.weapon.state.melee_attack = true
				task.wait(LocalPlayer2.weapon.info.melee_attack.rate)
				LocalPlayer2.weapon.state.melee_attack = false
			end
		end
		if p135("DODGE") then
			request_dodge()
		end
	end)
end
BindableEvents:GetEvent("request_dodge"):Connect(request_dodge)
local function player_died()
	--[[ line: 1304 | upvalues: (copy) LocalPlayer2, (ref) v_u_10, (copy) setMobileButtonVisible]]
	LocalPlayer2.weapon.tool = nil
	LocalPlayer2.weapon.handle = nil
	LocalPlayer2.weapon.state.equipped = false
	LocalPlayer2.services.uis.MouseIconEnabled = true
	LocalPlayer2:ClearEvents()
	LocalPlayer2:ClearSignals()
	LocalPlayer2:SetMouseCursorImage()
	LocalPlayer2.gui.weapon.Visible = false
	v_u_10.NoAmmo.Visible = false
	LocalPlayer2.gui.mobile.cursor.NoAmmo.Visible = false
	setMobileButtonVisible(false)
	LocalPlayer2.weapon.state.hold_down = false
	LocalPlayer2.services.uis.MouseDeltaSensitivity = 1
	LocalPlayer2.weapon.state.aim = false
	LocalPlayer2:StopAllSoundsFromHolder(LocalPlayer2.weapon.handle)
	LocalPlayer2:RemoveQueues({ "equip_time", "rpm", "reload_time" })
end
local v_u_150 = nil
RunService.Heartbeat:Connect(function(_24: number)
	--[[ line: 1327 | upvalues: (copy) LocalPlayer2, (ref) v_u_150]]
	if LocalPlayer2.weapon.info and (LocalPlayer2.weapon.info.spread and LocalPlayer2.weapon.state.equipped) then
		local Velocity = LocalPlayer2.modules.Func.GetMagnitude(LocalPlayer2.hrp.Velocity)
		if LocalPlayer2.weapon.info.spread.min_running <= Velocity then
			local v151 = LocalPlayer2
			local running = LocalPlayer2.weapon.info.spread.running
			v151:SetSpread(math.min(running, Velocity) * LocalPlayer2.weapon.info.spread.mult_running)
		elseif not LocalPlayer2.weapon.state.shooting then
			LocalPlayer2:SetSpread(LocalPlayer2.modules.Func.Lerp(LocalPlayer2.spread, LocalPlayer2.weapon.info.spread.min, LocalPlayer2.weapon.info.spread.decay_alpha))
		end
	end
	if v_u_150 and (LocalPlayer2.human and LocalPlayer2.human.Health > 0) then
		LocalPlayer2:RenderArms()
		if LocalPlayer2:IsFirstPerson() then
			v_u_150.Position = UDim2.fromScale(0.5, 0.5)
			return
		end
		v_u_150.Position = UDim2.fromScale(0.5, 0.35)
	end
end)
local v_u_152 = nil
BindableEvents:GetEvent("MobileShiftLockStateChanged"):Connect(function(p153: boolean)
	--[[ line: 1375 | upvalues: (ref) v_u_152, (copy) LocalPlayer2, (copy) unAim]]
	v_u_152 = p153
	if (LocalPlayer2:IsFirstPerson() or v_u_152) and LocalPlayer2.weapon.tool then
		LocalPlayer2.gui.mobile.AIM.Visible = true
	else
		LocalPlayer2.gui.mobile.AIM.Visible = false
		unAim()
	end
end)
LocalPlayer2.services.rs.RenderStepped:Connect(function()
	--[[ line: 1380 | upvalues: (copy) LocalPlayer2, (ref) v_u_10, (copy) LocalPlayer]]
	local v154 = LocalPlayer2:IsMobile()
	LocalPlayer2.mobile = v154
	LocalPlayer2.gui.mobile.Visible = v154
	if LocalPlayer2.char then
		local right_arm = LocalPlayer2.right_arm
		local left_arm = LocalPlayer2.left_arm
		if right_arm and left_arm then
			right_arm.LocalTransparencyModifier = 0
			left_arm.LocalTransparencyModifier = 0
			right_arm.CastShadow = false
			left_arm.CastShadow = false
		end
		if not LocalPlayer2.mobile and v_u_10 then
			v_u_10.Position = UDim2.fromOffset(LocalPlayer2.mouse.X, LocalPlayer2.mouse.Y)
		end
		if LocalPlayer2.head and (LocalPlayer:GetAttribute("config_camera_shake") and (not LocalPlayer2.weapon.state.shooting and (not LocalPlayer2.weapon.state.dodging and (not LocalPlayer2.weapon.state.aim and (LocalPlayer2.human and LocalPlayer2.human.Health > 0))))) then
			local CFrame3 = LocalPlayer2.head.CFrame:ToObjectSpace(LocalPlayer2.hrp.CFrame)
			if LocalPlayer2.origin.old_cam_cf then
				local _25, _26, v155 = CFrame3:ToOrientation()
				local v156, v157, _27 = CFrame3:ToObjectSpace(LocalPlayer2.origin.old_cam_cf):ToEulerAnglesXYZ()
				LocalPlayer2.camera_offset.shake = LocalPlayer2.camera_offset.shake:Lerp(CFrame.Angles(v156 * 0.15, v157 * 0.15, -v155 * 0.15), 0.075)
			end
			LocalPlayer2.origin.old_cam_cf = CFrame3
		else
			LocalPlayer2.camera_offset.shake = LocalPlayer2.camera_offset.shake:Lerp(CFrame.new(), 0.075)
		end
		if LocalPlayer2.weapon.state.equipped and LocalPlayer2.weapon.state.aim then
			local _28 = LocalPlayer2.weapon.ads_point
		end
	end
	local camera_offset = LocalPlayer2.GetOffsets(LocalPlayer2.camera_offset)
	LocalPlayer2.camera.CFrame = LocalPlayer2.camera.CFrame * camera_offset
end)
LocalPlayer2.services.uis.InputBegan:Connect(function(p158, p159)
	--[[ line: 1431 | upvalues: (copy) LocalPlayer2]]
	if not p159 then
		LocalPlayer2.keydown[LocalPlayer2:KeyToName(p158)] = true
		BindKey(p158)
	end
end)
LocalPlayer2.services.uis.InputEnded:Connect(function(p160, p161)
	--[[ line: 1438 | upvalues: (copy) LocalPlayer2, (copy) unAim]]
	if not p161 then
		LocalPlayer2.keydown[LocalPlayer2:KeyToName(p160)] = false
		LocalPlayer2:BindKey(p160, function(_29, p162)
			--[[ line: 1441 | upvalues: (ref) LocalPlayer2, (ref) unAim]]
			if p162("AIM") and (LocalPlayer2.weapon.tool and LocalPlayer2.weapon.state.equipped) then
				unAim()
			end
		end)
	end
end)
workspace.ChildRemoved:Connect(function(p163)
	--[[ line: 1449 | upvalues: (copy) LocalPlayer2, (copy) player_died]]
	if p163 == LocalPlayer2.char then
		player_died()
	end
end)
task.delay(5, function()
	--[[ line: 1466 | upvalues: (copy) LocalPlayer]]
	LocalPlayer.PlayerScripts.DescendantRemoving:Connect(function(p164)
		--[[ line: 1467 | upvalues: (ref) LocalPlayer]]
		if p164:IsA("BaseScript") then
			LocalPlayer:Kick("?")
			for _30, v165 in ipairs((LocalPlayer.PlayerScripts:GetChildren())) do
				if v165 then
					v165:Destroy()
				end
			end
		end
	end)
	for _31, v_u_166 in pairs((LocalPlayer.PlayerScripts:GetDescendants())) do
		if v_u_166:IsA("BaseScript") then
			v_u_166:GetPropertyChangedSignal("Disabled"):Connect(function()
				--[[ line: 1479 | upvalues: (copy) v_u_166, (ref) LocalPlayer]]
				if v_u_166.Disabled == true then
					LocalPlayer:Kick("don\'t do that")
					for _32, v167 in ipairs((LocalPlayer.PlayerScripts:GetChildren())) do
						if v167 then
							v167:Destroy()
						end
					end
				end
			end)
		end
	end
end)
local function onCharacterAdded(p168)
	--[[ line: 1493 | upvalues: (copy) LocalPlayer2, (ref) v_u_150, (copy) BackpackGui, (ref) v_u_132, (copy) unAim, (copy) t, (ref) v_u_10, (copy) setMobileButtonVisible, (copy) t10, (ref) v_u_152, (copy) v_u_1, (copy) player_died, (copy) onMobileButtonAdded]]
	if not LocalPlayer2.gui then
		LocalPlayer2:GetGui()
		LocalPlayer2.gui.weapon.Visible = false
		v_u_150 = LocalPlayer2.gui.mobile:WaitForChild("cursor")
	end
	LocalPlayer2.gui.Enabled = true
	LocalPlayer2.char = p168
	LocalPlayer2.human = p168:WaitForChild("Humanoid")
	LocalPlayer2.torso = p168:WaitForChild("Torso")
	LocalPlayer2.head = p168:WaitForChild("Head")
	LocalPlayer2.hrp = p168:WaitForChild("HumanoidRootPart")
	LocalPlayer2.right_arm = p168:WaitForChild("Right Arm")
	LocalPlayer2.left_arm = p168:WaitForChild("Left Arm")
	LocalPlayer2.left_arm_weld = LocalPlayer2.torso:WaitForChild("Left Shoulder")
	LocalPlayer2.right_arm_weld = LocalPlayer2.torso:WaitForChild("Right Shoulder")
	LocalPlayer2.viewmodel_offset = CFrame.new(0, 0, 0)
	LocalPlayer2:LoadAnimations()
	LocalPlayer2.origin.RightShoulderC0 = LocalPlayer2.right_arm_weld.C0
	LocalPlayer2.origin.LeftShoulderC0 = LocalPlayer2.left_arm_weld.C0
	LocalPlayer2.origin.LeftShoulderC1 = LocalPlayer2.left_arm_weld.C1
	LocalPlayer2.camera.FieldOfView = LocalPlayer2.origin.FOV
	LocalPlayer2.services.uis.MouseDeltaSensitivity = 1
	LocalPlayer2:ClearEvents()
	LocalPlayer2:ClearSignals()
	LocalPlayer2:SetMouseCursorImage()
	LocalPlayer2.human:GetAttributeChangedSignal("Unarmed"):Connect(function()
		--[[ line: 1522 | upvalues: (ref) LocalPlayer2, (ref) BackpackGui]]
		if LocalPlayer2.human:GetAttribute("Unarmed") == true then
			BackpackGui.Enabled = false
			LocalPlayer2.human:UnequipTools()
		end
	end)
	LocalPlayer2.right_arm.ChildAdded:Connect(function(p169: userdata)
		--[[ line: 1532 | upvalues: (ref) LocalPlayer2]]
		if p169.Name == "RightGrip" then
			LocalPlayer2.tool_grip_weld = p169
			LocalPlayer2.origin.ToolGripC0 = p169.C0
			LocalPlayer2.origin.ToolGripC1 = p169.C1
			local v_u_170 = nil
			v_u_170 = p169.AncestryChanged:Connect(function(_33, p171)
				--[[ line: 1540 | upvalues: (ref) LocalPlayer2, (ref) v_u_170]]
				if p171 ~= LocalPlayer2.right_arm then
					LocalPlayer2.tool_grip_weld = nil
					v_u_170:Disconnect()
				end
			end)
		end
	end)
	local v_u_172 = false
	local function checkRunning()
		--[[ line: 1551 | upvalues: (ref) LocalPlayer2, (ref) v_u_132, (ref) v_u_172]]
		if LocalPlayer2.weapon.tool and (LocalPlayer2.weapon.tool.Parent and (LocalPlayer2.weapon.tool.Parent == LocalPlayer2.char and (LocalPlayer2.weapon.state.equipped and not (LocalPlayer2.weapon.state.reloading or LocalPlayer2.weapon.state.shooting)))) then
			if LocalPlayer2.human:GetAttribute("Running") then
				if not LocalPlayer2.weapon.state.hold_down then
					if not LocalPlayer2.weapon.state.hold_down then
						LocalPlayer2.weapon.state.hold_down_by_force = false
						LocalPlayer2.weapon.state.hold_down = true
						LocalPlayer2:PlayWeaponAnimation("hold_down")
						local v173 = LocalPlayer2
						v173.viewmodel_offset = v173.viewmodel_offset * CFrame.new(0, 0, 0.5)
					end
					v_u_132 = true
					v_u_172 = true
				end
			end
			if v_u_172 then
				if LocalPlayer2.weapon.state.hold_down then
					LocalPlayer2.weapon.state.hold_down = false
					LocalPlayer2:StopWeaponAnimation("hold_down")
					local v174 = LocalPlayer2
					v174.viewmodel_offset = v174.viewmodel_offset * CFrame.new(0, 0, -0.5)
				end
				v_u_172 = false
				v_u_132 = false
			end
		end
	end
	LocalPlayer2.human:GetAttributeChangedSignal("Running"):Connect(checkRunning)
	p168.ChildRemoved:Connect(function(p175)
		--[[ line: 1573 | upvalues: (ref) LocalPlayer2, (ref) unAim, (ref) t, (ref) v_u_10, (ref) setMobileButtonVisible]]
		if LocalPlayer2.weapon.handle and (LocalPlayer2.weapon.handle.Parent and p175 == LocalPlayer2.weapon.handle.Parent) then
			LocalPlayer2.render_gun = false
			LocalPlayer2.weapon.state.aim = false
			local RightGrip = LocalPlayer2.right_arm:FindFirstChild("RightGrip")
			LocalPlayer2.human:SetAttribute("CanSprint", true)
			if RightGrip and (LocalPlayer2.weapon.tool and LocalPlayer2.weapon.tool:FindFirstChild("ADS")) then
				unAim()
			end
			if t.WeaponAmmoChange then
				t.WeaponAmmoChange:Disconnect()
				v_u_10.NoAmmo.Visible = false
				LocalPlayer2.gui.mobile.cursor.NoAmmo.Visible = false
			end
			LocalPlayer2.weapon.tool = nil
			LocalPlayer2.weapon.handle = nil
			LocalPlayer2.weapon.state.equipped = false
			LocalPlayer2.services.uis.MouseIconEnabled = true
			LocalPlayer2:ClearSignals()
			LocalPlayer2:SetMouseCursorImage()
			LocalPlayer2:StopAllSoundsFromHolder(LocalPlayer2.weapon.handle)
			LocalPlayer2:RemoveQueues({ "equip_time", "rpm", "reload_time" })
			LocalPlayer2.gui.weapon.Visible = false
			setMobileButtonVisible(false)
			LocalPlayer2.services.uis.MouseDeltaSensitivity = 1
			LocalPlayer2.services.ts:Create(LocalPlayer2.camera, TweenInfo.new(1), { FieldOfView = LocalPlayer2.origin.FOV }):Play()
			LocalPlayer2:StopAllAnimations()
		end
	end)
	p168.ChildAdded:Connect(function(p_u_176)
		--[[ line: 1607 | upvalues: (ref) LocalPlayer2, (ref) v_u_10, (ref) t, (ref) t10, (ref) setMobileButtonVisible, (ref) v_u_152, (ref) unAim, (ref) v_u_1, (copy) checkRunning]]
		local Handle = p_u_176:FindFirstChild("Handle")
		if p_u_176:IsA("Tool") and (LocalPlayer2:IsCWS(p_u_176) and Handle) then
			LocalPlayer2.render_gun = true
			if LocalPlayer2.human:GetAttribute("Unarmed") == true then
				LocalPlayer2.human:UnequipTools()
			end
			if p_u_176:GetAttribute("ammo") <= 0 then
				if LocalPlayer2.mobile then
					LocalPlayer2.gui.mobile.cursor.NoAmmo.Visible = true
				else
					v_u_10.NoAmmo.Visible = true
				end
			end
			if t.WeaponAmmoChange then
				t.WeaponAmmoChange:Disconnect()
			end
			t.WeaponAmmoChange = p_u_176:GetAttributeChangedSignal("ammo"):Connect(function()
				--[[ line: 1629 | upvalues: (copy) p_u_176, (ref) LocalPlayer2, (ref) v_u_10]]
				if p_u_176:GetAttribute("ammo") <= 0 then
					if LocalPlayer2.mobile then
						LocalPlayer2.gui.mobile.cursor.NoAmmo.Visible = true
					else
						v_u_10.NoAmmo.Visible = true
					end
				else
					v_u_10.NoAmmo.Visible = false
					LocalPlayer2.gui.mobile.cursor.NoAmmo.Visible = false
					return
				end
			end)
			LocalPlayer2:ClearSignals()
			if not p_u_176:GetAttribute("I_Name") then
				local v177 = LocalPlayer2.services.http:GenerateGUID(false)
				p_u_176:SetAttribute("I_Name", v177)
				t10[v177] = p_u_176:GetAttribute("ammo")
			end
			if LocalPlayer2.mobile then
				setMobileButtonVisible(true)
			end
			LocalPlayer2.modules.Func.Spawn(function()
				--[[ line: 1651 | upvalues: (ref) LocalPlayer2]]
				LocalPlayer2.modules.Func.Wait()
				LocalPlayer2:UpdateCrosshair()
			end)
			LocalPlayer2:StopAllAnimations()
			LocalPlayer2:GetInfo(p_u_176)
			LocalPlayer2:LockInfo(p_u_176)
			LocalPlayer2:GuiSetTexts(p_u_176)
			LocalPlayer2:SetAnimations()
			if LocalPlayer2:IsMobile() then
				if LocalPlayer2:IsFirstPerson() or v_u_152 then
					local _34 = LocalPlayer2.weapon.tool
					LocalPlayer2.gui.mobile.AIM.Visible = true
				else
					LocalPlayer2.gui.mobile.AIM.Visible = false
					unAim()
				end
			end
			if LocalPlayer2.weapon.state.hold_down then
				LocalPlayer2:PlayWeaponAnimation("hold_down")
			end
			LocalPlayer2:PlayWeaponAnimation("equip")
			LocalPlayer2:PlayWeaponAnimation("idle")
			LocalPlayer2.weapon.ads_point = Handle:FindFirstChild("ads_point")
			LocalPlayer2.gui.weapon.Visible = true
			LocalPlayer2.weapon.lock_info = true
			LocalPlayer2.weapon.handle = Handle
			LocalPlayer2.weapon.state.equipped = false
			LocalPlayer2.weapon.tool = nil
			LocalPlayer2.viewmodel_offset = LocalPlayer2.weapon.info.viewmodel_offset or CFrame.new(0, 0, 0)
			if v_u_1 then
				local v_u_178 = nil
				v_u_178 = p_u_176.Info.Changed:Connect(function()
					--[[ line: 1676 | upvalues: (ref) LocalPlayer2, (copy) p_u_176, (ref) v_u_178]]
					if LocalPlayer2.weapon.tool == p_u_176 then
						print("changed info, but nothing gonna changed")
						LocalPlayer2:GetInfo(p_u_176)
					else
						v_u_178:Disconnect()
					end
				end)
			end
			task.spawn(function()
				--[[ line: 1685 | upvalues: (ref) LocalPlayer2]]
				local RightGrip2 = LocalPlayer2.right_arm:WaitForChild("RightGrip")
				if RightGrip2 then
					LocalPlayer2.origin.grip_c0 = RightGrip2.C0
				end
			end)
			LocalPlayer2:PlaySoundFromHolder(LocalPlayer2.weapon.handle, "equip", LocalPlayer2.modules.Func.GetRandom(-0.05, 0.05), true)
			if LocalPlayer2.weapon.info.icon and (LocalPlayer2.weapon.info.icon.id and LocalPlayer2.weapon.info.icon.size) then
				LocalPlayer2.gui.weapon.icon.Image = p_u_176.TextureId or LocalPlayer2.weapon.info.icon.id
				LocalPlayer2.gui.weapon.icon.Size = UDim2.fromScale(LocalPlayer2.weapon.info.icon.size[1], LocalPlayer2.weapon.info.icon.size[2])
				LocalPlayer2.gui.weapon.icon.UIAspectRatioConstraint.AspectRatio = LocalPlayer2.weapon.info.icon.ratio or 2
				LocalPlayer2.gui.weapon.icon.ImageColor3 = LocalPlayer2.weapon.info.icon.color or Color3.new(1, 1, 1)
				if p_u_176.TextureId then
					LocalPlayer2.gui.weapon.icon.UIScale.Scale = 2
					LocalPlayer2.gui.weapon.icon.UIAspectRatioConstraint.AspectRatio = 1
				end
			end
			if LocalPlayer2.weapon.info.tool or LocalPlayer2.weapon.info.melee then
				LocalPlayer2.gui.weapon.Visible = false
			end
			LocalPlayer2.modules.Func.QueueWait(LocalPlayer2.weapon.info.equip_time, function(p179)
				--[[ line: 1705 | upvalues: (ref) LocalPlayer2]]
				LocalPlayer2.queues.equip_time = p179
			end)
			LocalPlayer2.weapon.state.equipped = true
			LocalPlayer2.weapon.tool = p_u_176
			checkRunning()
			LocalPlayer2:SetHandleEffects(LocalPlayer2.dir.effects.muzzle, LocalPlayer2.weapon.info.effects.muzzle, "fire_point")
			LocalPlayer2:SetHandleEffects(LocalPlayer2.dir.effects.casing, LocalPlayer2.weapon.info.effects.casing, "casing_point")
		end
	end)
	LocalPlayer2.human.Died:Connect(function()
		--[[ line: 1716 | upvalues: (ref) player_died]]
		player_died()
	end)
	LocalPlayer2.human.StateChanged:Connect(function(p180, p181)
		--[[ line: 1720 | upvalues: (ref) LocalPlayer2]]
		if p181 == Enum.HumanoidStateType.Jumping and (LocalPlayer2.weapon.info and (LocalPlayer2.weapon.info.spread and LocalPlayer2.weapon.state.equipped)) then
			LocalPlayer2:SetSpread(LocalPlayer2.weapon.info.spread.jumping)
		end
		if p180 ~= Enum.HumanoidStateType.Jumping then
			if p181 == Enum.HumanoidStateType.Landed and (LocalPlayer2.weapon.info and (LocalPlayer2.weapon.info.spread and LocalPlayer2.weapon.state.equipped)) then
				LocalPlayer2:SetSpread(LocalPlayer2.weapon.info.spread.min)
			end
		end
	end)
	for _35, v182 in ipairs((LocalPlayer2.gui.mobile:GetDescendants())) do
		if v182:IsA("ImageButton") then
			task.spawn(onMobileButtonAdded, v182)
		end
	end
	LocalPlayer2.gui.mobile.DescendantAdded:Connect(function(p183)
		--[[ line: 1740 | upvalues: (ref) onMobileButtonAdded]]
		if p183:IsA("ImageButton") then
			onMobileButtonAdded(p183)
		end
	end)
end
task.spawn(function()
	--[[ line: 1747 | upvalues: (copy) LocalPlayer, (copy) onCharacterAdded]]
	if LocalPlayer.Character then
		onCharacterAdded(LocalPlayer.Character)
	end
end)
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)