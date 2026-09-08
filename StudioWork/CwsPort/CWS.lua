-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw

local t = {
	dir = game.ReplicatedStorage.Assets.Misc.CWS_Directory,
	services = {
		uis = game:GetService("UserInputService"),
		rs = game:GetService("RunService"),
		de = game:GetService("Debris"),
		ts = game:GetService("TweenService"),
		gs = game:GetService("GuiService"),
		plrs = game:GetService("Players"),
		http = game:GetService("HttpService"),
		py = game:GetService("PhysicsService"),
		tr = game.Workspace.Terrain,
		cas = game:GetService("ContextActionService"),
		sp = game:GetService("StarterPlayer"),
		sg = game:GetService("StarterGui")
	},
	default_crosshair = 57571495
}
game:GetService("RunService"):IsStudio()
local v_u_1 = nil
function t.LineCast(_, p2, p3, p4, p5, p6, _2)
	--[[ line: 26 | upvalues: none]]
	local v7 = RaycastParams.new()
	v7.FilterDescendantsInstances = p6
	v7.FilterType = p5
	local v8 = workspace:Raycast(p2, p3 * p4, v7)
	if v8 then
		return v8.Instance, v8.Position, v8.Normal
	end
	return nil, p2 + p3 * p4, nil
end
function t.VisualizeRay(_3, p9, p10, p11)
	--[[ line: 40 | upvalues: (copy) t]]
	local Magnitude = (p9.Origin - p10).Magnitude
	local v12 = Instance.new("Part", workspace)
	t.services.py:SetPartCollisionGroup(v12, "NonHittable")
	v12.Anchored = true
	v12.CanCollide = false
	v12.Material = Enum.Material.SmoothPlastic
	v12.Size = Vector3.new(p11, p11, Magnitude)
	v12.CFrame = CFrame.lookAt(p9.Origin, p10) * CFrame.new(0, 0, -Magnitude / 2)
	return v12
end
function t.CreateRay(_4, p13: Ray, p14: vector, p15: number)
	--[[ line: 54 | upvalues: none]]
	local v16 = p13.Origin - p14
	local v17: number = vector.magnitude(v16)
	local v18 = Vector3.new(p15, p15, v17)
	local v_u_19 = CFrame.lookAt(p13.Origin, p14) * CFrame.new(0, 0, -v17 / 2)
	local v_u_20 = v18 * 0.5
	return function(p21: vector)
		--[[ line: 61 | upvalues: (copy) v_u_19, (copy) v_u_20]]
		local v22 = v_u_19:PointToObjectSpace(p21)
		local X = v22.X
		local v23
		if math.abs(X) <= v_u_20.X then
			local Y = v22.Y
			if math.abs(Y) <= v_u_20.Y then
				local Z = v22.Z
				v23 = math.abs(Z) <= v_u_20.Z
			else
				v23 = false
			end
		else
			v23 = false
		end
		return v23
	end
end
local GetPartsInPart = workspace.GetPartsInPart
function t.IsInPart(_5, p24, p25)
	--[[ line: 99 | upvalues: (copy) GetPartsInPart]]
	local v26 = OverlapParams.new()
	v26.FilterType = Enum.RaycastFilterType.Include
	v26.FilterDescendantsInstances = { p25 }
	local v27 = GetPartsInPart(workspace, p24, v26)
	return next(v27) and true or false
end
function t.CheckTool(p28)
	--[[ line: 107 | upvalues: none]]
	local v29 = p28.weapon.tool and p28.char
	if v29 then
		v29 = p28.weapon.tool.Parent == p28.char
	end
	return v29
end
function t.UpdateCrosshair(p30)
	--[[ line: 111 | upvalues: (copy) t]]
	if p30.weapon.info.crosshair then
		if p30.weapon.info.crosshair.enabled then
			p30.services.uis.MouseIconEnabled = true
			p30:SetMouseCursorImage(t.default_crosshair)
		else
			p30.services.uis.MouseIconEnabled = false
		end
	else
		p30.services.uis.MouseIconEnabled = true
		p30:SetMouseCursorImage(t.default_crosshair)
		return
	end
end
function t.Tracer(p31, p32, p33, p34, p_u_35)
	--[[ line: 125 | upvalues: (copy) t]]
	local v36 = t.dir.effects.tracer:FindFirstChild(p33)
	if v36 and p34 then
		local v_u_37 = Instance.new("Attachment", t.services.tr)
		local v_u_38 = Instance.new("Attachment", t.services.tr)
		local v_u_39 = v36:Clone()
		v_u_39.Parent = t.services.tr
		v_u_39.Attachment0 = v_u_37
		v_u_39.Attachment1 = v_u_38
		v_u_37.WorldPosition = p34.WorldPosition
		v_u_38.WorldPosition = p32
		p31.modules.Func.Spawn(function()
			--[[ line: 136 | upvalues: (ref) t, (copy) v_u_39, (copy) p_u_35, (copy) v_u_37, (copy) v_u_38]]
			t.services.rs.Heartbeat:Wait()
			v_u_39.TextureSpeed = 0
			for v40 = 0, 1, p_u_35 do
				v_u_39.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, v40), NumberSequenceKeypoint.new(1, 0) })
				t.services.rs.Heartbeat:Wait()
			end
			for v41 = 0, 1, p_u_35 do
				v_u_39.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, v41) })
				t.services.rs.Heartbeat:Wait()
			end
			v_u_39:Destroy()
			v_u_37:Destroy()
			v_u_38:Destroy()
		end)
	end
end
function t.GetUserConfig(p42, p43)
	--[[ line: 160 | upvalues: none]]
	return p42.player:GetAttribute("config_" .. p43)
end
function t.OnScreen(p44, p45)
	--[[ line: 164 | upvalues: none]]
	local _6, v46 = p44.camera:WorldToScreenPoint(p45)
	return v46
end
function t.GetQualityLevel(_7)
	--[[ line: 169 | upvalues: none]]
	return UserSettings():GetService("UserGameSettings").SavedQualityLevel.Value
end
function t.GetDistance(p47, p48, p49)
	--[[ line: 173 | upvalues: none]]
	if p48 and p49 then
		return p47.modules.Func.GetMagnitude(p48 - p49)
	end
end
function t.FireRemote(p50, p51, p52)
	--[[ line: 179 | upvalues: (ref) v_u_1]]
	if not v_u_1 and p50.remote_size_seed then
		v_u_1 = Random.new(p50.remote_size_seed)
		if v_u_1 then
			v_u_1:NextNumber()
		end
		p50.remote_size_seed = p50.player.userId
	end
	if v_u_1 then
		local v53 = p50.remotes[p51]
		if v53 then
			p52.remote_size = v_u_1:NextNumber()
			v53:FireServer(p52)
		end
	end
end
function t.GetRemotes(p_u_54)
	--[[ line: 211 | upvalues: (copy) t]]
	for _8, v_u_55 in ipairs((t.dir.remos:GetChildren())) do
		if v_u_55:IsA("RemoteEvent") then
			v_u_55.OnClientEvent:Connect(function(...)
				--[[ line: 214 | upvalues: (copy) p_u_54, (copy) v_u_55]]
				if p_u_54.on_remote[v_u_55.Name] then
					p_u_54.on_remote[v_u_55.Name](...)
				end
			end)
			p_u_54.remotes[v_u_55.Name] = v_u_55
		end
	end
	t.dir.remos.ChildAdded:Connect(function(p_u_56)
		--[[ line: 218 | upvalues: (copy) p_u_54]]
		if p_u_56:IsA("RemoteEvent") then
			p_u_56.OnClientEvent:Connect(function(...)
				--[[ line: 220 | upvalues: (ref) p_u_54, (copy) p_u_56]]
				if p_u_54.on_remote[p_u_56.Name] then
					p_u_54.on_remote[p_u_56.Name](...)
				end
			end)
			p_u_54.remotes[p_u_56.Name] = p_u_56
		end
	end)
end
function t.LoadAnimations(p_u_57)
	--[[ line: 226 | upvalues: (copy) t]]
	if p_u_57.human and (p_u_57.human.Parent and (p_u_57.human.Parent.Parent and p_u_57.human.Parent.Parent:IsA("Workspace"))) then
		for v58, _9 in ipairs(p_u_57.anim) do
			table.remove(p_u_57.anim, v58)
		end
		local anim = p_u_57.dir.anim
		for _10, v59 in ipairs((anim:GetChildren())) do
			if v59:IsA("Folder") then
				p_u_57.anim[v59.Name] = {}
				for _11, v60 in ipairs((v59:GetChildren())) do
					local v61 = p_u_57.human:LoadAnimation(v60)
					p_u_57.anim[v59.Name][v60.Name] = v61
					local priority = v60:GetAttribute("priority")
					if priority then
						v61.Priority = Enum.AnimationPriority[priority]
					end
					p_u_57.anim[v59.Name][("%*!track"):format(v60.Name)] = v61:GetMarkerReachedSignal("sound"):Connect(function(p62)
						--[[ line: 245 | upvalues: (copy) p_u_57]]
						if p_u_57.weapon.handle then
							p_u_57:PlaySoundFromHolder(p_u_57.weapon.handle, p62, nil, true)
							local v63 = p_u_57.weapon.handle:FindFirstChild(p62)
							if v63 then
								p_u_57:FireRemote("PlaySound", { overlap = true, sound = v63 })
							end
						end
					end)
				end
			elseif v59:IsA("Animation") then
				local v64 = p_u_57.human:LoadAnimation(v59)
				p_u_57.anim[v59.Name] = v64
				local priority2 = v59:GetAttribute("priority")
				if priority2 then
					v64.Priority = Enum.AnimationPriority[priority2]
				end
				p_u_57.anim[("%*!track"):format(v59.Name)] = v64:GetMarkerReachedSignal("sound"):Connect(function(p65)
					--[[ line: 269 | upvalues: (copy) p_u_57, (ref) t]]
					p_u_57:PlaySoundFromHolder(p_u_57.weapon.handle, p65, nil, true)
					local v66 = p_u_57.weapon.handle:FindFirstChild(p65)
					if v66 then
						t:FireRemote("PlaySound", { overlap = true, sound = v66 })
					end
				end)
			end
		end
	end
end
function t.SetAnimations(p67)
	--[[ line: 285 | upvalues: none]]
	if p67.weapon.info and p67.weapon.info.anim then
		for v68, v69 in pairs(p67.weapon.anim) do
			if v69[1] then
				v69[1]:Stop()
				p67.weapon.anim[v68] = nil
			end
		end
		for v70, v71 in pairs(p67.weapon.info.anim) do
			if v71.group then
				local t2 = { p67.anim[v71.group][v70], v71 }
				p67.weapon.anim[v70] = t2
			end
		end
	end
end
function t.HitEffect(p_u_72, p_u_73, p_u_74, p_u_75, p_u_76, p_u_77, p_u_78, p_u_79)
	--[[ line: 302 | upvalues: (copy) t]]
	if p_u_77 then
		local function NewEffect(p80)
			--[[ line: 306 | upvalues: (copy) p_u_72, (copy) p_u_73, (copy) p_u_74, (copy) p_u_75, (ref) p_u_76, (copy) p_u_77, (ref) t, (copy) p_u_78, (copy) p_u_79]]
			if p_u_72.weapon.tool then
				p_u_72:FireRemote("HitEffect", {
					pos = p_u_73,
					hit = p_u_74,
					norm = p_u_75,
					name = p_u_76,
					shotgun = p_u_72.weapon.info.shotgun,
					impact_name = p_u_77
				})
			end
			local v81 = nil
			local v82 = t.dir.effects.impact:FindFirstChild(p_u_77)
			if v82 then
				if not t.GetUserConfig({ player = p_u_72.player }, "bloods") or p_u_72.player:GetAttribute("Young") == true then
					if p_u_76 == "Blood" then
						p_u_76 = "CensoredHit"
					elseif p_u_76 == "Headshot" then
						p_u_76 = "CensoredCriticalHit"
					end
				end
				for _12, v83 in ipairs((v82:GetChildren())) do
					if string.match(p_u_76, v83.Name) ~= nil then
						v81 = v83
					end
				end
				local v84 = v81 or v82:FindFirstChild("Other")
				if v84 then
					local t3 = {}
					local v85 = false
					for _13, v86 in ipairs((v84:GetChildren())) do
						if v86:IsA("IntValue") and v86.Name == "BulletHole" then
							table.insert(t3, v86)
						end
					end
					if p_u_78 and #t3 > 0 then
						p_u_78(t3[math.random(1, #t3)])
					end
					v84:FindFirstChild("BulletHole")
					for _14, v87 in ipairs((v84:GetChildren())) do
						if v87:IsA("ParticleEmitter") then
							local v88 = Instance.new("Attachment", workspace.Terrain)
							if v85 == false then
								local Hit = v87.Parent:FindFirstChild("Hit")
								if Hit then
									v85 = true
									local v89 = Hit:Clone()
									v89.Parent = v88
									if p_u_72.weapon and (p_u_72.weapon.info and p_u_72.weapon.info.shotgun) then
										v89.Volume = v89.Volume / (p_u_72.weapon.info.shotgun.count / 2)
									end
									v89.PlaybackSpeed = v89.PlaybackSpeed * math.random(9, 11) * 0.1
									v89:Play()
								end
							end
							v88.WorldCFrame = CFrame.new(p_u_73, p_u_73 + p_u_75)
							local v90 = v87:Clone()
							local PartColor = v90:FindFirstChild("PartColor")
							if PartColor and (PartColor.Value and p_u_74) then
								v90.Color = ColorSequence.new(p_u_74.Color)
							end
							v90.Parent = v88
							local v91 = p_u_79
							v90:Emit((math.min(v91, p80)))
							local v92 = p_u_79
							game.Debris:AddItem(v88, math.min(v92, p80) + 1)
						end
					end
				end
			end
		end
		NewEffect(3)
	end
end
function t.GetWeaponAnimation(p93, p94)
	--[[ line: 382 | upvalues: none]]
	for v95, v96 in pairs(p93.weapon.anim) do
		if v95 == p94 then
			return v96
		end
	end
end
function t.GetAnimation(p97, p98)
	--[[ line: 392 | upvalues: none]]
	for v99, v100 in pairs(p97.anim) do
		if v99 == p98 then
			return v100
		end
	end
end
function t.PlayWeaponAnimation(p101, p102)
	--[[ line: 400 | upvalues: none]]
	local v103 = p101:GetWeaponAnimation(p102)
	if v103 then
		v103[1]:Play(v103[2].face, v103[2].weight, v103[2].speed)
		if p101.weapon.tool and p101.weapon.info.anim[p102] then
			if p101.weapon.info.anim[p102].cframe then
				p101.weapon.info.anim[p102].cframe(p101.weapon.tool)
			end
			if p101.weapon.info.anim[p102].runfunc then
				p101.weapon.info.anim[p102].runfunc(p101, v103[1])
			end
		end
	end
end
function t.PlayAnimation(p104, p105)
	--[[ line: 415 | upvalues: none]]
	local v106 = p104:GetAnimation(p105)
	if v106 then
		v106:Play()
	end
end
function t.StopWeaponAnimation(p107, p108)
	--[[ line: 422 | upvalues: none]]
	local v109 = p107:GetWeaponAnimation(p108)
	if v109 then
		v109[1]:Stop()
	end
end
function t.StopAnimation(p110, p111)
	--[[ line: 429 | upvalues: none]]
	local v112 = p110:GetAnimation(p111)
	if v112 then
		v112:Stop()
	end
end
function t.StopAllAnimations(p113)
	--[[ line: 436 | upvalues: none]]
	for _15, v114 in pairs(p113.weapon.anim) do
		if v114[1] then
			v114[1]:Stop()
		end
	end
end
function t.EmitHandleEffects(p115, p116, p117)
	--[[ line: 444 | upvalues: none]]
	if p115.weapon.handle then
		local v118 = p115.weapon.handle:FindFirstChild(p116)
		if v118 then
			for _16, v_u_119 in ipairs((v118:GetChildren())) do
				if v_u_119:IsA("ParticleEmitter") then
					local v120 = v_u_119:GetAttribute("emit") or p117
					if v120 then
						v_u_119:Emit(v120)
					else
						local delay = v_u_119:GetAttribute("delay")
						if delay then
							v_u_119.Enabled = true
							p115.modules.Func.Delay(delay, function()
								--[[ line: 463 | upvalues: (copy) v_u_119]]
								v_u_119.Enabled = false
							end)
						else
							warn(v_u_119:GetFullName() .. " -> Warning: This ParticleEmitter has no emit or delay attributes.")
						end
					end
				elseif v_u_119:IsA("Light") then
					local v121 = v_u_119:GetAttribute("delay") or p117
					if v121 then
						v_u_119.Enabled = true
						p115.modules.Func.Delay(v121, function()
							--[[ line: 474 | upvalues: (copy) v_u_119]]
							v_u_119.Enabled = false
						end)
					else
						warn(v_u_119:GetFullName() .. " -> Warning: This Light has no delay attribute.")
					end
				elseif v_u_119:IsA("ModuleScript") then
					require(v_u_119)(p115, p116, p117)
				end
			end
		end
	end
end
function t.SetHandleEffects(p122, p123, p124, p125)
	--[[ line: 488 | upvalues: none]]
	if p122.weapon.handle and (p123 and (p124 and p125)) then
		local v126 = p123:FindFirstChild(p124)
		local v127 = p122.weapon.handle:FindFirstChild(p125)
		if v126 and (v127 and not v127:GetAttribute("effect_loaded")) then
			if p122.weapon.tool then
				p122:FireRemote("SetHandleEffects", {
					handle = p122.weapon.handle,
					holder = p123,
					name = p124,
					point = p125
				})
			end
			v127:SetAttribute("effect_loaded", true)
			for _17, v128 in ipairs((v126:GetChildren())) do
				if p122.weapon.tool then
					v128:Clone().Parent = v127
				elseif v128:GetAttribute("fe") then
					v128:Clone().Parent = v127
				end
			end
		end
	end
end
function t.WorldCFrameRotationToC0ObjectSpace(p129, p130)
	--[[ line: 519 | upvalues: none]]
	local _18 = p129.Part1.CFrame
	local Part0 = p129.Part0
	local C1 = p129.C1
	local _19 = p129.C0
	return Part0.CFrame:inverse() * p130 * C1
end
function t.IsFirstPerson(p131)
	--[[ line: 531 | upvalues: none]]
	if p131.head then
		return p131.head.LocalTransparencyModifier >= 1
	end
	return nil
end
function t.IsMobile(p132)
	--[[ line: 538 | upvalues: none]]
	local v133 = p132.services.uis.TouchEnabled and not p132.services.uis.KeyboardEnabled and not (p132.services.uis.MouseEnabled or p132.services.uis.GamepadEnabled)
	if v133 then
		v133 = not p132.services.gs:IsTenFootInterface()
	end
	return v133
end
function t.GetOffsets(p134)
	--[[ line: 543 | upvalues: none]]
	local v135 = CFrame.new()
	for _20, v136 in pairs(p134) do
		v135 = v135 * v136
	end
	return v135
end
function t.RenderArms(p137)
	--[[ line: 549 | upvalues: none]]
	local camera = p137.camera
	local torso = p137.torso
	if torso then
		local left_arm_weld = p137.left_arm_weld
		local right_arm_weld = p137.right_arm_weld
		local _21 = p137.left_arm
		local _22 = p137.right_arm
		if p137:IsFirstPerson() then
			p137.origin.arms_restored = false
			local v138 = CFrame.new(-1, -1, 0)
			local v139 = CFrame.new(1, -1, 0)
			local viewmodel_alpha = p137.viewmodel_alpha
			-- [port] the decompiler named these locals CFrame/CFrame2, which shadowed the
			-- CFrame global one line later and made CFrame.Angles throw every frame.
			local cameraCFrame = camera.CFrame
			local torsoCFrame = torso.CFrame
			local v140 = CFrame.Angles(0, 1.5707963267948966, 0)
			local v141 = CFrame.Angles(0, -1.5707963267948966, 0)
			if left_arm_weld then
				left_arm_weld.C0 = left_arm_weld.C0:Lerp((cameraCFrame * v138):ToObjectSpace(torsoCFrame):Inverse() * v141, viewmodel_alpha)
			end
			if right_arm_weld then
				right_arm_weld.C0 = right_arm_weld.C0:Lerp((cameraCFrame * v139):ToObjectSpace(torsoCFrame):Inverse() * v140, viewmodel_alpha)
			end
		end
		if not p137.origin.arms_restored then
			if left_arm_weld then
				left_arm_weld.C0 = p137.origin.LeftShoulderC0
			end
			if left_arm_weld then
				left_arm_weld.C1 = p137.origin.LeftShoulderC1
			end
			if right_arm_weld then
				right_arm_weld.C0 = p137.origin.RightShoulderC0
			end
			p137.origin.arms_restored = true
		end
	end
end
function t.PlaySoundFromHolder(p142, p143, p144, p145, p146)
	--[[ line: 682 | upvalues: none]]
	if p143 and p144 then
		local v147 = p143:FindFirstChild(p144)
		if v147 then
			if p145 and p146 then
				if not v147:GetAttribute("origin_pitch") then
					v147:SetAttribute("origin_pitch", v147.PlaybackSpeed)
				end
				p145 = p145 + v147:GetAttribute("origin_pitch")
			end
			if p146 then
				v147.PlaybackSpeed = p145 or v147.PlaybackSpeed
				v147:Play()
				return
			end
			local Parent = v147.Parent
			local v148 = v147:Clone()
			v148.PlaybackSpeed = p145 + v148.PlaybackSpeed or v148.PlaybackSpeed
			v148.Parent = Parent
			v148:Play()
			p142.services.de:AddItem(v148, v148.TimeLength / v148.PlaybackSpeed)
		end
	end
end
function t.StopAllSoundsFromHolder(_23, p149)
	--[[ line: 702 | upvalues: none]]
	if p149 then
		for _24, v150 in ipairs((p149:GetChildren())) do
			if v150:IsA("Sound") and v150.Playing then
				v150:Stop()
			end
		end
	end
end
function t.CameraRecoil(p_u_151, p152, p153, p154)
	--[[ line: 712 | upvalues: none]]
	local Y2 = p152.Y
	local X2 = p152.X
	local v155: vector = Vector3.new(Y2, X2, 0)
	local v_u_156 = p153[1]
	local v_u_157 = p153[2]
	local v_u_158 = v155 / v_u_156 * 2
	local v_u_159 = v155 / v_u_157 * 2
	local v_u_160 = p_u_151.modules.Spring.create()
	coroutine.wrap(function()
		--[[ line: 719 | upvalues: (copy) v_u_156, (copy) p_u_151, (copy) v_u_158, (copy) v_u_160, (copy) v_u_157, (copy) v_u_159]]
		for v161 = v_u_156, 1, -1 do
			p_u_151.services.rs.RenderStepped:Wait()
			local v162 = v_u_158 * ((v161 - 1) / (v_u_156 - 1))
			local v163 = v_u_160:update(0.016666666666666666)
			local camera2 = p_u_151.camera
			local CFrame3 = p_u_151.camera.CFrame
			local Angles = CFrame.Angles
			local X3 = v162.X
			local Y3 = v162.Y
			local Z2 = v163.Z
			camera2.CFrame = CFrame3 * Angles(X3, Y3, (math.rad(Z2)))
		end
		for v164 = v_u_157, 1, -1 do
			p_u_151.services.rs.RenderStepped:Wait()
			local v165 = -v_u_159 * ((v164 - 1) / (v_u_157 - 1))
			local v166 = v_u_160:update(0.016666666666666666)
			local camera3 = p_u_151.camera
			local CFrame4 = p_u_151.camera.CFrame
			local Angles2 = CFrame.Angles
			local X4 = v165.X
			local Y4 = v165.Y
			local Z3 = v166.Z
			camera3.CFrame = CFrame4 * Angles2(X4, Y4, (math.rad(Z3)))
		end
	end)()
	v_u_160:shove((Vector3.new(0, 0, p154)))
end
function t.GuiSetTexts(p167, p168)
	--[[ line: 736 | upvalues: none]]
	local t4 = {}
	if p168 then
		t4.wpn_name = p168.Name
		t4.ammo = p168:GetAttribute("ammo")
	else
		t4.wpn_name = p167.weapon.tool.Name
		t4.ammo = p167.weapon.tool:GetAttribute("ammo")
	end
	t4.max_ammo = p167.weapon.info.max_ammo
	for v169, v170 in pairs(p167.weapon.info.gui_text) do
		t4[v169] = v170.Text
	end
	for _25, v171 in ipairs((p167.gui.weapon:GetChildren())) do
		if v171:IsA("TextLabel") and t4[v171.Name] then
			v171.Text = t4[v171.Name]
		end
	end
	local v172 = p168:GetAttribute("ammo") / p167.weapon.info.max_ammo
	p167.gui.weapon.ammo.TextColor3 = Color3.new(1, math.min(v172, 1), (math.min(v172, 1)))
	p167.gui.weapon.ammo.UIStroke.Color = Color3.new(0.3333333333333333, math.min(v172, 0.3333333333333333), (math.min(v172, 0.3333333333333333)))
end
function t.UpdateWeaponGui(p173)
	--[[ line: 761 | upvalues: none]]
	if p173.gui and (p173.gui:FindFirstChild("weapon") and p173.weapon.tool) then
		p173.gui.weapon.ammo.Text = p173.weapon.tool:GetAttribute("ammo")
		local v174 = p173.weapon.tool:GetAttribute("ammo") / p173.weapon.info.max_ammo
		p173.gui.weapon.ammo.TextColor3 = Color3.new(1, math.min(v174, 1), (math.min(v174, 1)))
		p173.gui.weapon.ammo.UIStroke.Color = Color3.new(0.3333333333333333, math.min(v174, 0.3333333333333333), (math.min(v174, 0.3333333333333333)))
	end
end
function t.GetGui(p175)
	--[[ line: 770 | upvalues: none]]
	local CWS_Gui = p175.player.PlayerGui:WaitForChild("CWS_Gui")
	if CWS_Gui then
		p175.gui = CWS_Gui
	end
end
function t.IsCWS(_26, p176)
	--[[ line: 777 | upvalues: none]]
	return p176:GetAttribute("cws_enabled")
end
function t.GetInfo(p177, p178)
	--[[ line: 781 | upvalues: none]]
	p177.weapon.info = {}
	for _27, v179 in pairs((p178:GetDescendants())) do
		if v179:IsA("ValueBase") then
			p177.weapon.info[v179.Name] = v179.Value
		elseif v179:IsA("ModuleScript") and v179.Name == "Info" then
			local v180 = require(v179)
			for v181, v182 in pairs(v180) do
				p177.weapon.info[v181] = v182
			end
		end
	end
	table.freeze(p177.weapon.info)
end
function t.LockInfo(p_u_183, p_u_184)
	--[[ line: 797 | upvalues: none]]
	for _28, v_u_185 in ipairs((p_u_184:GetDescendants())) do
		if v_u_185:IsA("ValueBase") then
			local Value = v_u_185.Value
			p_u_183.signals.lock_value_change = v_u_185.Changed:Connect(function()
				--[[ line: 801 | upvalues: (copy) p_u_183, (copy) v_u_185, (ref) Value]]
				if p_u_183.weapon.lock_info then
					v_u_185.Value = Value
				else
					Value = v_u_185.Value
				end
			end)
		end
	end
	local v_u_186 = p_u_184:GetAttributes()
	p_u_183.signals.lock_attribute_change = p_u_184.AttributeChanged:Connect(function(p187)
		--[[ line: 811 | upvalues: (copy) p_u_183, (copy) p_u_184, (ref) v_u_186]]
		if p_u_183.weapon.lock_info then
			if p187 ~= "reloaded" then
				p_u_184:SetAttribute(p187, v_u_186[p187])
			end
		end
		v_u_186 = p_u_184:GetAttributes()
	end)
end
function t.GetToolInfo(_29, p188)
	--[[ line: 822 | upvalues: none]]
	if p188 then
		local t5 = {}
		for _30, v189 in ipairs((p188:GetChildren())) do
			if v189:IsA("ModuleScript") then
				for v190, v191 in pairs(require(v189)) do
					t5[v190] = v191
				end
			end
		end
		for v192, v193 in pairs((p188:GetAttributes())) do
			t5[v192] = v193
		end
	end
end
function t.BindKey(p194, p195, p196)
	--[[ line: 838 | upvalues: none]]
	local KeyCode = p195.KeyCode
	local UserInputType = p195.UserInputType
	local v_u_197 = nil
	local function isPressed(p198)
		--[[ line: 842 | upvalues: (ref) v_u_197]]
		return p198 == v_u_197
	end
	for v199, v200 in pairs(p194.modules.settings.KeyBinds.keybinds) do
		if v200 == KeyCode or v200 == UserInputType then
			v_u_197 = v199
			p196(v199, isPressed)
			break
		end
	end
end
function t.KeyToName(p201, p202)
	--[[ line: 854 | upvalues: none]]
	local KeyCode2 = p202.KeyCode
	local UserInputType2 = p202.UserInputType
	local v203 = nil
	for v204, v205 in pairs(p201.modules.settings.KeyBinds.keybinds) do
		if v205 == KeyCode2 or v205 == UserInputType2 then
			v203 = v204
		end
	end
	return v203 or ""
end
function t.GetModules(p206)
	--[[ line: 870 | upvalues: (copy) t]]
	if p206 and p206.modules then
		for v207, _31 in pairs(p206.modules) do
			table.remove(p206.modules, v207)
		end
	end
	local t6 = {}
	for _32, v208 in ipairs((t.dir.modules:GetChildren())) do
		if v208:IsA("ModuleScript") then
			t6[v208.Name] = require(v208)
			v208.Name = ""
			v208:Destroy()
		elseif v208:IsA("Folder") then
			for _33, v209 in ipairs((v208:GetChildren())) do
				if v209:IsA("ModuleScript") and v209.Name ~= script.Name then
					if not t6[v208.name] then
						t6[v208.name] = {}
					end
					t6[v208.name][v209.Name] = require(v209)
					v209:Destroy()
				end
			end
			v208.Name = ""
			v208:Destroy()
		end
	end
	return t6
end
function t.CreateLoop(_34, p_u_210, p_u_211)
	--[[ line: 897 | upvalues: none]]
	local t7 = {}
	local v_u_212 = false
	function t7.Disconnect(_35)
		--[[ line: 900 | upvalues: (ref) v_u_212]]
		v_u_212 = true
	end
	task.spawn(function()
		--[[ line: 903 | upvalues: (copy) p_u_210, (ref) v_u_212, (copy) p_u_211]]
		while task.wait(p_u_210) and v_u_212 == false do
			p_u_211()
		end
	end)
	return t7
end
function t.ClearEvents(p213)
	--[[ line: 911 | upvalues: none]]
	for v214, v215 in pairs(p213.events) do
		v215:Disconnect()
		p213.events[v214] = nil
	end
	table.clear(p213.events)
end
function t.ClearSignals(p216)
	--[[ line: 919 | upvalues: none]]
	for v217, v218 in pairs(p216.signals) do
		v218:Disconnect()
		p216.signals[v217] = nil
	end
	table.clear(p216.signals)
end
function t.SetSpread(p219, p220)
	--[[ line: 927 | upvalues: none]]
	if p219.weapon.info and (p219.weapon.info.spread and (p219.weapon.tool and p219.weapon.state.equipped)) then
		p219.spread = p220
	end
end
function t.RemoveQueues(p221, p222)
	--[[ line: 933 | upvalues: none]]
	for _36, v223 in pairs(p222) do
		local v224 = p221.queues[v223]
		if v224 then
			v224:Fire()
			v224:Destroy()
		end
	end
end
function t.SetMouseCursorImage(p225, p226)
	--[[ line: 943 | upvalues: none]]
	if p226 then
		p225.mouse.Icon = "http://www.roblox.com/asset?id=" .. tostring(p226)
	else
		p225.mouse.Icon = ""
	end
end
return function(p227)
	--[[ line: 953 | upvalues: (copy) t]]
	local t8 = {
		player = p227,
		char = nil,
		camera = game.Workspace.CurrentCamera,
		modules = t.GetModules(),
		mouse = p227:GetMouse(),
		remotes = {},
		events = {},
		signals = {},
		keydown = {},
		queues = {},
		gui = nil,
		weapon = {}
	}
	t8.weapon.tool = nil
	t8.weapon.lock_info = false
	t8.weapon.info = {}
	t8.weapon.state = {
		equipping = false,
		equipped = false,
		shooting = false,
		reloading = false,
		aim = false,
		hold_down = false,
		melee_attack = false,
		inventory_toggle = false,
		dodging = false,
		teleporting = false
	}
	t8.weapon.anim = {}
	t8.anim = {}
	t8.on_remote = {}
	t8.remote_size_seed = nil
	t8.origin = {}
	t8.mobile = false
	t8.spread = 0
	t8.camera_offset = { shake = CFrame.new(), ads = CFrame.new() }
	t8.viewmodel_alpha = 0.185
	local t9 = { __index = t }
	return setmetatable(t8, t9)
end