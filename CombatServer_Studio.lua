local _TC=require(game:GetService("ReplicatedStorage").GameSettings.Groups.MapConfig)
local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local debris = game:GetService("Debris")
local testService = game:GetService("TestService")
local proxPromptService = game:GetService("ProximityPromptService")
local collectionService = game:GetService("CollectionService")

local Cache = require(game.ServerScriptService.Core.Cache)

local assets = replicatedStorage.GameSettings
local MapConfig = require(replicatedStorage.GameSettings.Groups.MapConfig)
local modules = assets.Modules
local mainui = assets.HUD.SPH_UI

local config = require(assets.Groups.MapConfig)

local physicsService = game:GetService("PhysicsService")
pcall(function() physicsService:RegisterCollisionGroup("Casings") end)
pcall(function() physicsService:RegisterCollisionGroup("Players") end)
pcall(function() physicsService:RegisterCollisionGroup("RootParts") end)
pcall(function() physicsService:RegisterCollisionGroup("Guns") end)
pcall(function() physicsService:RegisterCollisionGroup("Debris") end)
physicsService:CollisionGroupSetCollidable("Casings","Casings",false)
physicsService:CollisionGroupSetCollidable("Casings","Players",false)
physicsService:CollisionGroupSetCollidable("Guns","Guns",false)
physicsService:CollisionGroupSetCollidable("Guns","Players",false)
physicsService:CollisionGroupSetCollidable("Casings","Guns",false)
physicsService:CollisionGroupSetCollidable("RootParts","Guns",false)
physicsService:CollisionGroupSetCollidable("RootParts","Casings",false)
physicsService:CollisionGroupSetCollidable("Debris","Casings",false)
physicsService:CollisionGroupSetCollidable("Debris","Guns",false)

if config.disablePlayerDebrisCollision then
	physicsService:CollisionGroupSetCollidable("Debris","Players",false)
	physicsService:CollisionGroupSetCollidable("Debris","RootParts",false)
end

local weldMod = require(modules.WeldMod)
local bridgeNet = require(replicatedStorage.GameSettings.Modules.BridgeNet)
local viewMod = require(modules.ViewMod)
local explosionMod = require(modules.ExplosionFX)
local ragdoll = require(modules.RagdollMod)
local fractureGlass = require(modules.FractureGlass)
local hitscan = require(modules.Hitscan)

local bodyAnimRequest = bridgeNet.CreateBridge("BodyAnimRequest")
local bodyAnimCommand = bridgeNet.CreateBridge("BodyAnimCommand")
local switchWeapon = bridgeNet.CreateBridge("SwitchWeapon")
local repFire = bridgeNet.CreateBridge("ReplicateFire")
local repReload = bridgeNet.CreateBridge("Reload")
local repSound = bridgeNet.CreateBridge("ReplicateSound")
local bulletHit = bridgeNet.CreateBridge("BulletHit")
local repHit = bridgeNet.CreateBridge("ReplicateHit")
local repChamber = bridgeNet.CreateBridge("PlayerChamber")
local moveBolt = bridgeNet.CreateBridge("MoveBolt")
local playerFire = bridgeNet.CreateBridge("PlayerFire")
local playSound = bridgeNet.CreateBridge("PlaySound")
local fallDamage = bridgeNet.CreateBridge("FallDamage")
local repBolt = bridgeNet.CreateBridge("ReplicateBolt")
local switchFireMode = bridgeNet.CreateBridge("SwitchFireMode")
local playerDropGun = bridgeNet.CreateBridge("PlayerDropGun")
local playerToggleAttachment = bridgeNet.CreateBridge("PlayerToggleAttachment")
local repToggleAttachment = bridgeNet.CreateBridge("ReplicateToggleAttachment")
local repBoltOpen = bridgeNet.CreateBridge("RepBoltOpen")
local magGrab = bridgeNet.CreateBridge("MagGrab")
local repMagGrab = bridgeNet.CreateBridge("ReplicateMagGrab")
local playerLean = bridgeNet.CreateBridge("PlayerLean")
local repLean = bridgeNet.CreateBridge("ReplicateLean")
local toggleFreeCam = bridgeNet.CreateBridge("ToggleFreeCam")
local hitFeedback = bridgeNet.CreateBridge("HitFeedback")

local function MergeTables(table1, table2)
	return table.pack(table.unpack(table1), table.unpack(table2))
end

local ignoreParts = collectionService:GetTagged("SPH_NoCollide")
collectionService:GetInstanceAddedSignal("SPH_NoCollide"):Connect(function(newInstance)
	table.insert(ignoreParts, newInstance)
end)

game:GetService("SoundService").RespectFilteringEnabled = true

local workspaceRoot = workspace:WaitForChild("โมเดลทั้งหมด")

local mainFolder = Instance.new("Folder")
mainFolder.Name = "ปืน"
mainFolder.Parent = workspaceRoot
local projectiles = Instance.new("Folder")
projectiles.Name = "Projectiles"
projectiles.Parent = mainFolder
local cache = Instance.new("Folder")
cache.Name = "Cache"
cache.Parent = mainFolder
local bodies = Instance.new("Folder")
bodies.Name = "Bodies"
bodies.Parent = mainFolder
local shells = Instance.new("Folder")
shells.Name = "Shells"
shells.Parent = mainFolder
local drops = Instance.new("Folder")
drops.Name = "Drops"
drops.Parent = mainFolder

local dropTable = {}
local dropCFrame = CFrame.new(0,1,-3)

local function MakeCharacterRig(char)
	local head = char:WaitForChild("Head", 20)
	local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")

	if torso then
		local ls = torso:FindFirstChild("Left Shoulder")
		local rs = torso:FindFirstChild("Right Shoulder")
		if ls then ls.Enabled = true end
		if rs then rs.Enabled = true end
	end

	local rig = viewMod.RigModel(nil, true, head)
	rig.Parent = char

	local lArmWeld = weldMod.BlankWeld(rig["Left Arm"],char["Left Arm"])
	lArmWeld.Parent = rig
	lArmWeld.Name = "law"
	lArmWeld.Enabled = false
	rig["Left Arm"].Transparency = 1

	local rArmWeld = weldMod.BlankWeld(rig["Right Arm"],char["Right Arm"])
	rArmWeld.Parent = rig
	rArmWeld.Name = "raw"
	rArmWeld.Enabled = false
	rig["Right Arm"].Transparency = 1

	local animController = Instance.new("AnimationController",rig)
	local animator = Instance.new("Animator",animController)

	return rig
end

local function SetupGun(tool,wepStats)
	tool.CanBeDropped = false
	if not tool:FindFirstChild("Ammo") then
		local ammoFolder = Instance.new("Folder",tool)
		ammoFolder.Name = "Ammo"

		local magAmmo = Instance.new("DoubleConstrainedValue",ammoFolder)
		magAmmo.Name = "MagAmmo"
		magAmmo.MaxValue = wepStats.magazineCapacity
		magAmmo.Value = wepStats.magazineAmmo or magAmmo.MaxValue

		local arcadeAmmoPool = Instance.new("DoubleConstrainedValue",ammoFolder)
		arcadeAmmoPool.Name = "ArcadeAmmoPool"
		arcadeAmmoPool.MaxValue = wepStats.maxAmmoPool
		arcadeAmmoPool.Value = wepStats.startAmmoPool

		if not wepStats.openBolt then
			local chambered = Instance.new("BoolValue",tool)
			chambered.Value = wepStats.startChambered
			chambered.Name = "Chambered"

			if chambered.Value then
				if magAmmo.Value > 0 then
					magAmmo.Value -= 1
				else
					chambered.Value = false
				end
			end
		end

		local boltReady = Instance.new("BoolValue",tool)
		boltReady.Value = true
		boltReady.Name = "BoltReady"

		local fireMode = Instance.new("IntValue",tool)
		fireMode.Value = wepStats.fireMode
		fireMode.Name = "FireMode"
	end
end

local function EquipGun(rig, tool)
	if tool.Parent == rig.Parent and assets.WeaponModels:FindFirstChild(tool.Name) then
		local wepStats = require(tool.SPH_Weapon.WeaponStats)
		local gun = assets.WeaponModels[tool.Name]:Clone()

		if not wepStats.disableAutoRigging then
			weldMod.WeldModel(gun,gun.Grip,false)

			for _, partName in ipairs(wepStats.rigParts) do
				if gun:FindFirstChild(partName) then
					gun.Grip["Grip_"..partName]:Destroy()
					local newMotor = weldMod.M6D(gun.Grip,gun[partName])
					newMotor.Name = partName
					newMotor.Parent = gun.Grip
				end
			end

			for _, desc in gun:GetDescendants() do
				if desc:IsA("BasePart") then
					desc.CanCollide = false
				end
			end
		end

		local projectile = gun:FindFirstChild(wepStats.projectile)
		if (wepStats.openBolt or not tool.Chambered.Value) and projectile and wepStats.projectile ~= "Bullet" then
			projectile:SetAttribute("OriginalTransparency", projectile.Transparency)
			projectile.Transparency = 1
			for _, child in ipairs(projectile:GetDescendants()) do
				if child:IsA("BasePart") then
					child.Transparency = 1
				end
			end
		end

		for _, part in ipairs(gun:GetChildren()) do
			if part.Name == "SightReticle" and part:FindFirstChild("SurfaceGui") then
				part.SurfaceGui.Enabled = false
			end
		end

		gun.Parent = rig.Weapon
		if rig.AnimBase:FindFirstChild("GunMotor") then rig.AnimBase:FindFirstChild("GunMotor"):Destroy() end
		local gunMotor = weldMod.BlankM6D(rig.AnimBase,gun.Grip)
		gunMotor.Name = "GunMotor"

		local char = rig.Parent
		local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
		if torso then
			local ls = torso:FindFirstChild("Left Shoulder")
			local rs = torso:FindFirstChild("Right Shoulder")
			if ls then ls.Enabled = false end
			if rs then rs.Enabled = false end
		end
		rig.law.Enabled = true
		rig.raw.Enabled = true

		rig.BaseWeld.C0 = wepStats.serverOffset

		SetupGun(tool,wepStats)

		return gun
	end
end

local function IsGunLoaded(tool)
	if not tool or not tool:FindFirstChild("SPH_Weapon") then return false end
	local wepStats = require(tool.SPH_Weapon.WeaponStats)
	local gunAmmo = tool.Ammo
	return not wepStats.openBolt and tool.Chambered.Value or wepStats.openBolt and gunAmmo.MagAmmo.Value > 0
end

local function PlayerFire(player, firePoint)
	if player:GetAttribute("FreeCamActive") then
		player:Kick("1")
		return
	end
	local tool = player.Character:FindFirstChildWhichIsA("Tool")
	if not tool or not tool:IsA("Tool") then return end
	if not tool:FindFirstChild("SPH_Weapon") then return end
	local wepStats = require(tool.SPH_Weapon.WeaponStats)
	local gunAmmo = tool.Ammo
	local magAmmo = gunAmmo.MagAmmo
	if wepStats.fireMode == 4 then
		if not wepStats.openBolt then
			tool.Chambered.Value = false
		end
		tool.BoltReady.Value = false
	elseif not IsGunLoaded(tool) then
		if tool.BoltReady.Value then
			return
		elseif wepStats.emptyCloseBolt then
			tool.BoltReady.Value = true
			return
		end
	else
		if not wepStats.openBolt then
			tool.Chambered.Value = false
		end
		tool.BoltReady.Value = not wepStats.emptyLockBolt
		if magAmmo.Value > 0 then
			magAmmo.Value -= 1
			if not wepStats.openBolt then
				tool.Chambered.Value = true
			end
			tool.BoltReady.Value = true
		end
	end

	local _char = player.Character
	local _hrp = _char and _char:FindFirstChild("HumanoidRootPart")
	if _hrp then
		local point = _hrp.Position
		local dist = config.fireEffectDistance
		repFire:FireAllInRangeExcept(player,point,dist,player,firePoint)
	end
end

local OVERRIDE_GROUPS = require(game:GetService("ReplicatedStorage").GameSettings.Groups.MapConfig).COMBAT_OVERRIDE_GROUPS
local DIVISIONS = require(game:GetService("ReplicatedStorage").GameSettings.Groups.MapConfig).DIVISIONS or {}
local function HasUnit(plr)
	for gid in pairs(DIVISIONS) do
		if Cache.InGroup(plr, gid) then return true end
	end
	return false
end

function TeamKillCheck(player1, player2)
	for groupId in pairs(OVERRIDE_GROUPS) do
		if Cache.InGroup(player1, groupId) then
			return true
		end
	end

	if player1:GetAttribute("WantedBank") and player2:GetAttribute("WantedBank") then
		return false
	end

	if player1:GetAttribute("WantedBank") or player2:GetAttribute("WantedBank") then
		return true
	end

	if player1:GetAttribute("Wanted") then
		return false
	end

	if player2:GetAttribute("Wanted") then
		return true
	end

	if player1.Team and player1.Team.Name == MapConfig.MAIN_TEAM and not HasUnit(player1) then
		if player2.Team and player2.Team.Name == _TC.DEFAULT_TEAM then
			return true
		elseif player2:GetAttribute("Wanted") or player2:GetAttribute("WantedBank") then
			return true
		else
			return false
		end
	end

	if not config.teamKill and not player1.Neutral and not player2.Neutral then
		if player1.Team == player2.Team then
			return false
		end
	end

	return true
end

local function CheckTool(player,tool)
	if tool:FindFirstChild("SPH_Weapon") and assets.WeaponModels:FindFirstChild(tool.Name) then
		local wepStats = require(tool.SPH_Weapon.WeaponStats)
		SetupGun(tool,wepStats)
	end
end

local function MakePickUpAble(tool, model, mainPart)
	tool.Parent = model
	model.Name = tool.Name

	local proxPrompt = Instance.new("ProximityPrompt")
	proxPrompt.MaxActivationDistance = config.pickupDistance
	proxPrompt.Style = Enum.ProximityPromptStyle.Custom
	proxPrompt.RequiresLineOfSight = false
	proxPrompt.KeyboardKeyCode = config.pickupKey[1]
	proxPrompt.HoldDuration = 0
	proxPrompt.Parent = mainPart

	local promptListener
	promptListener = proxPrompt.Triggered:Connect(function(player)
		if player.Character.Humanoid.Health <= 0 then
			return
		else
			promptListener:Disconnect()
		end

		tool.Parent = player.Backpack
		model:Destroy()
	end)

	local highlight = Instance.new("Highlight")
	highlight.Name = "PickupHighlight"
	highlight.FillTransparency = 0.7
	highlight.FillColor = Color3.new(1,1,1)
	highlight.Parent = model
	highlight.Enabled = false
end

local function SpawnGun(tool,gunPosition,dropPlayer)
	if not tool or not tool:FindFirstChild("SPH_Weapon") then return end
	local wepStats = require(tool.SPH_Weapon.WeaponStats)
	local dropModel = assets.WeaponModels:FindFirstChild(tool.Name)
	if not dropModel then return end
	dropModel = dropModel:Clone()
	dropModel.Grip.Anchored = false
	dropModel.Grip.CanTouch = true

	task.delay(config.dropGunAnchorTime, function()
		for _, desc in dropModel:GetDescendants() do
			if desc:IsA("BasePart") then
				desc.Anchored = true
				desc.CanCollide = false
			end
		end
	end)

	dropModel.PrimaryPart = dropModel.Grip
	dropModel.Grip.Size = dropModel:GetExtentsSize()

	if #dropModel:GetChildren() < 2 then
		dropModel.Grip.CanCollide = true
	else
		dropModel.Grip.CanCollide = false
	end

	for _, part in ipairs(dropModel:GetDescendants()) do
		if part:IsA("BasePart") then
			if string.find(part.Name,"AimPart") then
				part:Destroy()
			elseif part.Name ~= "Grip" then
				local newWeld = weldMod.Weld(dropModel.Grip,part)
				newWeld.Parent = dropModel.Grip
				part.Anchored = false
				part.CanCollide = true
				part.CanTouch = false
				part.CollisionGroup = "Guns"
			end
		end
	end

	MakePickUpAble(tool,dropModel,dropModel.Grip)

	local projectile = dropModel:FindFirstChild(wepStats.projectile)
	if (wepStats.openBolt or not tool.Chambered.Value) and projectile and wepStats.projectile ~= "Bullet" then
		projectile.Transparency = 1
		for _, child in ipairs(projectile:GetDescendants()) do
			if child:IsA("BasePart") then
				child.Transparency = 1
			end
		end
	end

	dropModel.Parent = drops

	if dropPlayer then dropModel.Grip:SetNetworkOwner(dropPlayer) end

	dropModel:SetPrimaryPartCFrame(gunPosition)

	local position = #dropTable + 1
	table.insert(dropTable,position,dropModel)

	if #dropTable > config.maxDroppedGuns then
		local objectToDestroy = dropTable[1]
		table.remove(dropTable,1)
		objectToDestroy:Destroy()
	end

	task.delay(config.dropDespawnTime,function()
		table.remove(dropTable,position)
		dropModel:Destroy()
	end)

	return dropModel
end

players.PlayerAdded:Connect(function(newPlayer)
	if config.strikes then
		newPlayer:SetAttribute("Strikes", 0)
	end

	local deaths
	if config.leaderboard then
		local leaderstats = newPlayer:FindFirstChild("leaderstats")
		if not leaderstats then
			leaderstats = Instance.new("Folder",newPlayer)
			leaderstats.Name = "leaderstats"
		end
		local kills = Instance.new("IntValue",leaderstats)
		kills.Name = "K"
		deaths = Instance.new("IntValue",leaderstats)
		deaths.Name = "D"
	end

	newPlayer.CharacterAdded:Connect(function(newChar)
		local humanoid = newChar:WaitForChild("Humanoid", 20)
		local animator = humanoid:WaitForChild("Animator", 20)

		local torso = newChar:WaitForChild("Torso", 5) or newChar:WaitForChild("UpperTorso", 5)
		if torso then
			local ls = torso:FindFirstChild("Left Shoulder")
			local rs = torso:FindFirstChild("Right Shoulder")
			if ls then ls.Enabled = true end
			if rs then rs.Enabled = true end
		end

		local newRig = MakeCharacterRig(newChar)
		humanoid.BreakJointsOnDeath = not config.ragdolls

		humanoid.Died:Connect(function()
			if not newChar:FindFirstChild("HumanoidRootPart") then return end
			newChar.Humanoid:UnequipTools()

			if torso then
				local ls = torso:FindFirstChild("Left Shoulder")
				local rs = torso:FindFirstChild("Right Shoulder")
				if ls then ls.Enabled = true end
				if rs then rs.Enabled = true end
			end

			local robloxDamageTag = newChar.Humanoid:FindFirstChildWhichIsA("ObjectValue")
			newRig:Destroy()
			if config.leaderboard then deaths.Value += 1 end

			local hrp, newBody
			if config.ragdolls and newChar:FindFirstChild("HumanoidRootPart") then
				newBody = ragdoll.MakeCorpse(newChar)
				newBody.Parent = bodies
				hrp = newBody.HumanoidRootPart
				debris:AddItem(newBody,config.bodyDespawn)
				if #bodies:GetChildren() > config.bodyLimit then
					bodies:GetChildren()[1]:Destroy()
				end

				local bodyTorso
				if humanoid.RigType == Enum.HumanoidRigType.R6 then
					bodyTorso = newBody.Torso
				else
					bodyTorso = newBody.UpperTorso
				end

				local deathForce = Instance.new("VectorForce",bodyTorso.NeckAttachment)
				deathForce.Attachment0 = deathForce.Parent
				deathForce.Force = Vector3.new(0,0,-600)
				debris:AddItem(deathForce,0.2)

				task.delay(config.bodyAnchorTime, function()
					for _, desc in newBody:GetDescendants() do
						if desc:IsA("BasePart") then
							desc.Anchored = true
							desc.CanCollide = false
						elseif desc:IsA("Constraint") then
							desc.Enabled = false
						end
					end
				end)
			else
				hrp = newChar.HumanoidRootPart
			end

			if config.bloodPuddle and config.ragdolls and not newChar:GetAttribute("FrozenDeath") then
				task.delay(1, function()
					local bodyToCheck = newBody or newChar
					local bodyTorso = bodyToCheck:FindFirstChild("Torso") or bodyToCheck:FindFirstChild("UpperTorso")
					if bodyTorso then
						local rayParams = RaycastParams.new()
						rayParams.FilterDescendantsInstances = {bodyToCheck, mainFolder}
						rayParams.FilterType = Enum.RaycastFilterType.Exclude
						local rayResult = workspace:Raycast(bodyTorso.Position, Vector3.new(0,-100,0), rayParams)
						if rayResult and rayResult.Instance then
							local bloodPuddle = replicatedStorage.GameSettings.Assets.BloodPuddle:Clone()
							bloodPuddle.Parent = workspace
							bloodPuddle:SetPrimaryPartCFrame(CFrame.new(rayResult.Position))
							local animController = bloodPuddle:FindFirstChild("AnimationController")
							if animController then
								local puddleAnims = {}
								for _, anim in ipairs(bloodPuddle:GetChildren()) do
									if anim:IsA("Animation") and anim.Name:match("PuddleAnim") then
										table.insert(puddleAnims, anim)
									end
								end
								if #puddleAnims > 0 then
									local randomAnim = puddleAnims[math.random(1, #puddleAnims)]
									local animTrack = animController:LoadAnimation(randomAnim)
									animTrack:AdjustSpeed(math.random(50, 150) / 100)
									animTrack:Play()
									animTrack.Stopped:Wait()
									bloodPuddle:Destroy()
								end
							end
						end
					end
				end)
			end

			if config.dropOnDeath then
				local equippedTool = newChar:FindFirstChildWhichIsA("Tool")
				if equippedTool and equippedTool:FindFirstChild("SPH_Weapon") then
					SpawnGun(equippedTool, newChar.HumanoidRootPart.CFrame * dropCFrame, newPlayer)
				end
				for _, tool in ipairs(newPlayer.Backpack:GetChildren()) do
					if tool:FindFirstChild("SPH_Weapon") then
						SpawnGun(tool, newBody and newBody.HumanoidRootPart.CFrame * dropCFrame or newChar.HumanoidRootPart.CFrame * dropCFrame, newPlayer)
						task.wait()
					end
				end
			end
		end)

		newPlayer.Backpack.ChildAdded:Connect(function(child)
			if child:FindFirstChild("SPH_Weapon") then
				CheckTool(newPlayer,child)
			end
		end)

		for _, tool in ipairs(newPlayer.Backpack:GetChildren()) do
			if tool:FindFirstChild("SPH_Weapon") then
				CheckTool(newPlayer,tool)
			end
		end

		task.wait()
		local _pg = newPlayer:FindFirstChildOfClass("PlayerGui")
		if _pg then
			local newGui = mainui:Clone()
			newGui.Parent = _pg

			if config.deathScreen then
				assets.HUD.DeathScreen:Clone().Parent = _pg
			end
		end
	end)
end)

players.PlayerRemoving:Connect(function(player)
	local character = player.Character
	if config.dropOnLeave and character then
		local equippedTool = character:FindFirstChildWhichIsA("Tool")
		if equippedTool and equippedTool:FindFirstChild("SPH_Weapon") then
			SpawnGun(equippedTool, character.HumanoidRootPart.CFrame * dropCFrame, player)
		end

		for _, tool in ipairs(player.Backpack:GetChildren()) do
			if tool:FindFirstChild("SPH_Weapon") then
				SpawnGun(tool, character.HumanoidRootPart.CFrame * dropCFrame, player)
				task.wait()
			end
		end
	end
end)

bodyAnimRequest:Connect(function(player, angle)
	local char = player.Character
	if not char then return end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
	if not torso then return end
	local weaponRig = char:FindFirstChild("WeaponRig")
	if weaponRig then
		local torsoShoulder_L = torso:FindFirstChild("Left Shoulder")
		local torsoShoulder_R = torso:FindFirstChild("Right Shoulder")
		local equippedWeapon = weaponRig.Weapon:FindFirstChildWhichIsA("Model")
		if equippedWeapon then
			if torsoShoulder_L and torsoShoulder_L.Enabled then torsoShoulder_L.Enabled = false end
			if torsoShoulder_R and torsoShoulder_R.Enabled then torsoShoulder_R.Enabled = false end
			if not weaponRig.law.Enabled then weaponRig.law.Enabled = true end
			if not weaponRig.raw.Enabled then weaponRig.raw.Enabled = true end
		else
			if torsoShoulder_L and not torsoShoulder_L.Enabled then torsoShoulder_L.Enabled = true end
			if torsoShoulder_R and not torsoShoulder_R.Enabled then torsoShoulder_R.Enabled = true end
			if weaponRig.law.Enabled then weaponRig.law.Enabled = false end
			if weaponRig.raw.Enabled then weaponRig.raw.Enabled = false end
		end
	end
	bodyAnimCommand:FireAllInRangeExcept(player, char.HumanoidRootPart.Position, config.animDistance, char, angle)
end)

switchWeapon:Connect(function(player, tool)
	local character = player.Character
	if not character then return end
	local weaponRig = character:FindFirstChild("WeaponRig")
	if not weaponRig then return end
	if character.Humanoid.Health <= 0 then return end

	local rig = weaponRig
	local curWeapon = rig.Weapon:FindFirstChildWhichIsA("Model")

	local torso
	if character.Humanoid.RigType == Enum.HumanoidRigType.R6 then
		torso = character:FindFirstChild("Torso")
	else
		torso = character:FindFirstChild("UpperTorso")
	end

	if curWeapon then
		if torso then
			local ls = torso:FindFirstChild("Left Shoulder")
			local rs = torso:FindFirstChild("Right Shoulder")
			if ls then ls.Enabled = true end
			if rs then rs.Enabled = true end
		end
		rig.law.Enabled = false
		rig.raw.Enabled = false
		curWeapon:Destroy()
	end

	if tool and typeof(tool) == "Instance" then
		EquipGun(rig, tool)
	else
		if torso then
			local ls = torso:FindFirstChild("Left Shoulder")
			local rs = torso:FindFirstChild("Right Shoulder")
			if ls then ls.Enabled = true end
			if rs then rs.Enabled = true end
		end
		rig.law.Enabled = false
		rig.raw.Enabled = false
	end
end)

repReload:Connect(function(player)
	if config.listenForReloadSpam then
		if player:GetAttribute("LastReload") then
			if time() - player:GetAttribute("LastReload") <= 0.5 then return end
		end
		player:SetAttribute("LastReload", time())
	end

	local tool = player.Character:FindFirstChildWhichIsA("Tool")
	if not tool then return end
	if not tool:FindFirstChild("SPH_Weapon") then return end

	local wepStats = require(tool.SPH_Weapon.WeaponStats)
	local magAmmo = tool.Ammo.MagAmmo
	local arcadeAmmoPool = tool.Ammo.ArcadeAmmoPool

	if not wepStats.operationType or type(wepStats.operationType) == "string" then
		wepStats.operationType = 1
	end

	if not wepStats.magType or type(wepStats.magType) == "string" then
		wepStats.magType = 1
	end

	if wepStats.magType == 2 then
		magAmmo.Value += 1
	elseif wepStats.magType == 3 then
		local ammoNeeded = magAmmo.MaxValue - magAmmo.Value
		local clipSize = (wepStats.clipSize or wepStats.magazineCapacity)
		if ammoNeeded >= clipSize then
			magAmmo.Value += clipSize
		else
			magAmmo.Value += 1
		end
	else
		magAmmo.Value = magAmmo.MaxValue
	end

	arcadeAmmoPool.Value = arcadeAmmoPool.MaxValue

	if wepStats.operationType == 4 and not tool.Chambered.Value then
		tool.Chambered.Value = true
		magAmmo.Value -= 1
	end

	local gunModel = player.Character.WeaponRig.Weapon:FindFirstChildWhichIsA("Model")
	if wepStats.projectile and gunModel:FindFirstChild(wepStats.projectile) then
		local projectile = gunModel:FindFirstChild(wepStats.projectile)
		projectile.Transparency = projectile:GetAttribute("OriginalTransparency") or 0
		for _, child in ipairs(projectile:GetDescendants()) do
			if child:IsA("BasePart") then
				child.Transparency = 0
			end
		end
	end
end)

playSound:Connect(function(player, soundName)
	if not player.Character then return end
	local weaponRig = player.Character:FindFirstChild("WeaponRig")
	if not weaponRig then return end

	local weapon = weaponRig.Weapon:FindFirstChildWhichIsA("Model")
	if not weapon then return end
	local soundToPlay = weapon.Grip:FindFirstChild(soundName)
	if soundToPlay then
		repSound:FireToAllExcept(player,player,soundToPlay)
	end
end)

bulletHit:Connect(function(player, tool, raycastResult, bulletCFrame)
	if player:GetAttribute("FreeCamActive") then
		player:Kick("2")
		return
	end

	if config.ammoCountCheck then
		local currentTime = tick()
		local lastFiredTime = player:GetAttribute("LastFiredTime") or 0
		local timeDiff = currentTime - lastFiredTime

		if timeDiff >= 0.05 or not player:GetAttribute("LastFiredMagCount") or
			tool.Ammo.MagAmmo.Value < player:GetAttribute("LastFiredMagCount") then
			player:SetAttribute("LastFiredGun", tool.Name)
			player:SetAttribute("LastFiredMagCount", tool.Ammo.MagAmmo.Value)
			player:SetAttribute("LastFiredTime", currentTime)
		else
			return
		end
	end

	if not tool then
		return
	elseif tool and typeof(tool) ~= "Instance" then
		return
	elseif config.requireEquippedGun and tool.Parent ~= player.Character then
		if config.strikes then
			player:SetAttribute("Strikes", player:GetAttribute("Strikes") + 1)
			player:SetAttribute("LastStrikeReason", "Attempting to deal damage with no tool equipped")
		end
		return
	elseif tool.Parent ~= player.Character and tool.Parent ~= player.Backpack then
		return
	end

	local wepStats
	if typeof(tool) == "table" then
		wepStats = require(tool.model.Parent.TurretModule).guns[tool.index]
	elseif tool:IsA("Tool") and tool:FindFirstChild("SPH_Weapon") then
		wepStats = require(tool.SPH_Weapon.WeaponStats)
	end

	if wepStats.explosiveAmmo then
		explosionMod(raycastResult.Position, wepStats.explosionRadius, wepStats.explosionEffect, player)

		if config.listenForExplosionSpam then
			local lastExplosion = player:GetAttribute("LastExplosion")
			if lastExplosion and time() - lastExplosion <= 0.3 then
				return
			end
			player:SetAttribute("LastExplosion", time())
		end
	else
		local position = raycastResult.Position
		repHit:FireAllInRangeExcept(player, position, config.maxHitDistance, tool, raycastResult)
	end

	local hitPart = raycastResult.Instance
	if not hitPart or not hitPart.Parent then return end
	local humanoid = hitPart.Parent:FindFirstChildWhichIsA("Humanoid")
	local otherPlayer
	if humanoid then otherPlayer = players:GetPlayerFromCharacter(humanoid.Parent) end
	local damage = wepStats.damage[hitPart.Name] or wepStats.damage.Other

	if humanoid and humanoid.Parent:FindFirstChild("ForceFieldSafeZone") then return end

	if humanoid and humanoid.Health > 0 and ((otherPlayer and TeamKillCheck(player,otherPlayer)) or not otherPlayer) then

		if config.serverSideHitCheck then
			local shooterHead = player.Character and player.Character:FindFirstChild("Head")
			if not shooterHead then return end
			local targetChar = humanoid.Parent
			local origin = shooterHead.Position
			local losOK = false
			for _, pn in ipairs({"Head","HumanoidRootPart","UpperTorso","LowerTorso","Torso"}) do
				local tp = targetChar:FindFirstChild(pn)
				if tp then
					local diff = tp.Position - origin
					local ray = hitscan.FireHitscanBullet(
						origin,
						diff.Unit,
						diff.Magnitude + 4,
						MergeTables(ignoreParts, {player.Character})
					)
					if not ray or (ray.Instance and ray.Instance:IsDescendantOf(targetChar)) then
						losOK = true
						break
					end
				end
			end
			if not losOK then return end
		end

		if config.killAngleCheck then
			local headCFrame = player.Character.HumanoidRootPart.CFrame
			local otherHumanoidPosition = humanoid.Parent.WorldPivot.Position
			local positionDifference = (headCFrame.Position - otherHumanoidPosition).Unit
			local angleToTarget = math.pow((headCFrame.LookVector - positionDifference).Magnitude / 2, 2)
			if angleToTarget < 0.5 then return end
		end

		local willKill = humanoid.Health > 0 and humanoid.Health - damage <= 0

		if humanoid.Health > 0 then
			for _, oldc in ipairs(humanoid:GetChildren()) do
				if oldc.Name == "creator" and oldc:IsA("ObjectValue") then oldc:Destroy() end
			end
			local creator = Instance.new("ObjectValue")
			creator.Name = "creator"
			creator.Value = player
			creator.Parent = humanoid
			debris:AddItem(creator, 3)
			humanoid:SetAttribute("KillWeapon", (typeof(tool) == "Instance" and tool.Name) or nil)
		end

		humanoid:TakeDamage(damage)

		if not humanoid:GetAttribute("RagdollEnabled") then
			hitFeedback:FireTo(player, humanoid.Parent, damage, hitPart.Name == "Head")
		end

		if otherPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			replicatedStorage.GameSettings.Events.CreateDamageIndicator:FireClient(
				otherPlayer,
				player.Name,
				player.Character.HumanoidRootPart.Position
			)
		end

		if willKill then
			if config.leaderboard then player.leaderstats.K.Value += 1 end
			local killer = Instance.new("ObjectValue",humanoid.Parent)
			killer.Name = "Killer"
			killer.Value = player

			if config.bloodPuddle and not humanoid.Parent:GetAttribute("FrozenDeath") then
				task.delay(1, function()
					local deadBody = humanoid.Parent
					local deadTorso = deadBody:FindFirstChild("Torso") or deadBody:FindFirstChild("UpperTorso")

					if deadTorso then
						local rayParams = RaycastParams.new()
						rayParams.FilterDescendantsInstances = {deadBody}
						rayParams.FilterType = Enum.RaycastFilterType.Exclude

						local rayResult = workspace:Raycast(deadTorso.Position, Vector3.new(0,-100,0), rayParams)

						if rayResult and rayResult.Instance then
							local bloodPuddle = replicatedStorage.GameSettings.Assets.BloodPuddle:Clone()
							bloodPuddle.Parent = workspace
							bloodPuddle:SetPrimaryPartCFrame(CFrame.new(rayResult.Position))

							local animController = bloodPuddle:FindFirstChild("AnimationController")
							if animController then
								local anims = bloodPuddle:GetChildren()
								local puddleAnims = {}

								for _, anim in ipairs(anims) do
									if anim:IsA("Animation") and anim.Name:match("PuddleAnim") then
										table.insert(puddleAnims, anim)
									end
								end

								if #puddleAnims > 0 then
									local randomAnim = puddleAnims[math.random(1, #puddleAnims)]
									local animTrack = animController:LoadAnimation(randomAnim)
									animTrack:AdjustSpeed(math.random(50, 150) / 100)
									animTrack:Play()
									animTrack.Stopped:Wait()
									bloodPuddle:Destroy()
								end
							end
						end
					end
				end)
			end

			if config.listenForKillAll then
				if player:GetAttribute("LastKillTime") then
					local lastTime = player:GetAttribute("LastKillTime")
					if time() - lastTime <= 0.1 then
						player:SetAttribute("MultiKill", (player:GetAttribute("MultiKill") or 0) + 1)
						if player:GetAttribute("MultiKill") > config.multiKillThreshold then
							return
						end
					else
						player:SetAttribute("MultiKill", 0)
					end
					if config.multiKillDistanceCheck and time() - lastTime < 3 and (humanoid.Parent.WorldPivot.Position - player:GetAttribute("LastKillPosition")).Magnitude > 100 then
						if config.strikes then
							player:SetAttribute("Strikes", player:GetAttribute("Strikes") + 1)
							player:SetAttribute("LastStrikeReason", "Attempting to kill multiple players >100 studs apart")
						end
						return
					end
				end

				player:SetAttribute("LastKillTime", time())
				player:SetAttribute("LastKillPosition", humanoid.Parent.WorldPivot.Position)
			end
		end

	elseif hitPart.Name == "_glass" and config.glassShatter and not hitPart:GetAttribute("Shattered") then
		hitPart:SetAttribute("Shattered", true)
		local hitPosition = raycastResult.Position

		local tempPart = hitPart:Clone()
		tempPart.Name = "TempGlass"
		tempPart.Parent = workspace

		local prevTransparency = hitPart.Transparency
		local prevCanCollide = hitPart.CanCollide
		local prevCanQuery = hitPart.CanQuery
		local prevCanTouch = hitPart.CanTouch

		hitPart.Transparency = 1
		hitPart.CanCollide = false
		hitPart.CanQuery = false
		hitPart.CanTouch = false

		task.delay(config.glassRespawnTime, function()
			if hitPart and hitPart.Parent then
				hitPart.Transparency = prevTransparency
				hitPart.CanCollide = prevCanCollide
				hitPart.CanQuery = prevCanQuery
				hitPart.CanTouch = prevCanTouch
				hitPart:SetAttribute("Shattered", false)
			end
		end)

		if hitPart:IsA("Part") and hitPart.Shape == Enum.PartType.Block or hitPart:IsA("WedgePart") then
			fractureGlass(tempPart, hitPosition, bulletCFrame.LookVector * 10)
		else
			tempPart:Destroy()
		end

		local soundAtt = Instance.new("Attachment")
		soundAtt.Parent = workspace.Terrain
		soundAtt.WorldPosition = hitPosition

		local glassSound = Instance.new("Sound")
		glassSound.Name = "GlassBreak"
		glassSound.SoundId = "rbxassetid://516789356"
		glassSound.Volume = 0.4
		glassSound.RollOffMaxDistance = 80
		glassSound.RollOffMinDistance = 10
		glassSound.Parent = soundAtt

		glassSound:Play()

		debris:AddItem(soundAtt, 5)

	elseif not hitPart.Anchored and config.useBulletForce and ((humanoid and humanoid.Health <= 0) or not humanoid) then
		local tempAtt = Instance.new("Attachment",hitPart)
		tempAtt.WorldCFrame = CFrame.new(raycastResult.Position) * (bulletCFrame - bulletCFrame.Position)
		local force = Instance.new("VectorForce",tempAtt)
		force.Attachment0 = tempAtt
		force.Force = Vector3.new(0,0,-wepStats.bulletForce)
		debris:AddItem(tempAtt,0.1)
		if not otherPlayer or humanoid.Health <= 0 then
			pcall(function()
				hitPart:SetNetworkOwner(player)
			end)
		end
	end
end)

repChamber:Connect(function(player)
	local tool = player.Character:FindFirstChildWhichIsA("Tool")
	if tool and tool.Parent == player.Character then
		tool.BoltReady.Value = true
		if tool:FindFirstChild("Chambered") then
			tool.Chambered.Value = false
		end
		if tool.Ammo.MagAmmo.Value > 0 and tool:FindFirstChild("Chambered") then
			tool.Ammo.MagAmmo.Value -= 1
			tool.Chambered.Value = true
		end
	end
end)

repBoltOpen:Connect(function(player)
	local tool = player.Character:FindFirstChildWhichIsA("Tool")
	if tool and tool.Parent == player.Character then
		tool.BoltReady.Value = false
		if tool:FindFirstChild("Chambered") then
			tool.Chambered.Value = false
		end
	end
end)

moveBolt:Connect(function(player,direction,magAmmo)
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local playerPosition = player.Character.HumanoidRootPart.Position
		repBolt:FireAllInRangeExcept(player, playerPosition, config.fireEffectDistance, player, direction, magAmmo)
	end
end)

switchFireMode:Connect(function(player,newFireMode)
	local tool = player.Character:FindFirstChildWhichIsA("Tool")
	if tool and tool:FindFirstChild("SPH_Weapon") then
		tool.FireMode.Value = newFireMode
	end
end)

proxPromptService.PromptTriggered:Connect(function(prompt,player)
	if prompt.Name == "AmmoGiver" and prompt:FindFirstChild("SPH_PromptConfig") then
		local ammoTaken = false
		local promptConfig = prompt.SPH_PromptConfig
		local ammoPool = promptConfig.AmmoPool
		if ammoPool.Value < 1 and not promptConfig.InfAmmo.Value then return end
		local ammoType = promptConfig.AmmoType.Value

		local tools = player.Backpack:GetChildren()
		local equippedTool = player.Character:FindFirstChildWhichIsA("Tool")
		if equippedTool then table.insert(tools,equippedTool) end

		for _, tool in ipairs(tools) do
			if tool:FindFirstChild("SPH_Weapon") then
				local wepStats = require(tool.SPH_Weapon.WeaponStats)
				local arcadeAmmoPool = tool.Ammo.ArcadeAmmoPool

				if wepStats.infiniteAmmo then
					continue
				elseif arcadeAmmoPool.Value < arcadeAmmoPool.MaxValue and (wepStats.ammoType == ammoType or ammoType == "Universal") then
					ammoTaken = true
					local ammoNeeded = arcadeAmmoPool.MaxValue - arcadeAmmoPool.Value
					if ammoPool.Value > ammoNeeded then
						arcadeAmmoPool.Value = arcadeAmmoPool.MaxValue
						ammoPool.Value -= ammoNeeded
					else
						arcadeAmmoPool.Value += ammoPool.Value
						ammoPool.Value = 0
					end

					if ammoPool.Value <= 0 and config.despawnEmptyAmmoBoxes then
						prompt.Enabled = false
						task.delay(config.ammoBoxDespawnTime,function()
							if ammoPool.Value <= 0 then
								prompt.Parent.Parent:Destroy()
							end
						end)
					end
				elseif arcadeAmmoPool.Value <= 0 then
					break
				end
			end
		end

		if ammoTaken and prompt.Parent:FindFirstChild("Ammo") then prompt.Parent.Ammo:Play() end

	elseif prompt.Name == "GunGiver" and prompt:FindFirstChild("SPH_PromptConfig") then
		local cfg = prompt.SPH_PromptConfig
		local gunName = prompt:GetAttribute("ToolToGive") or prompt:FindFirstChildWhichIsA("Tool").Name
		local gunPool = cfg.GunPool

		if not cfg.AllowDupes.Value and (player.Character:FindFirstChild(gunName) or player.Backpack:FindFirstChild(gunName)) then return end

		if gunPool.Value > 0 or cfg.InfGuns.Value then
			local newGun = prompt:FindFirstChildWhichIsA("Tool") or game.ServerStorage.ToolStorage:FindFirstChild(gunName)
			if not newGun then
				return
			else
				newGun = newGun:Clone()
			end
			newGun.Parent = player.Backpack
			gunPool.Value -= 1

			if gunPool.Value < 1 then
				prompt.Enabled = false
				local listener
				listener = gunPool.Changed:Connect(function()
					if gunPool.Value > 0 then
						listener:Disconnect()
						prompt.Enabled = true
					end
				end)
			end

			local gunModels = prompt.Parent.Parent:FindFirstChild("GunModels")
			if not cfg.InfGuns.Value and cfg.RemoveModels.Value and gunModels and #gunModels:GetChildren() > gunPool.Value then
				gunModels:GetChildren()[1]:Destroy()
			end

			if prompt.Parent:FindFirstChild("TakeGun") then
				prompt.Parent.TakeGun:Play()
			end
		end
	end
end)

playerFire:Connect(PlayerFire)

replicatedStorage.GameSettings.Events.PlayCharacterSound.OnServerEvent:Connect(function(player, soundType)
	player:SetAttribute("LastCharacterSound", os.clock())
end)

playerToggleAttachment:Connect(function(player, attachmentType, toggle)
	local char = player.Character
	if not char then return end
	local rig = char:FindFirstChild("WeaponRig")
	if not rig then return end
	local weapon = rig:FindFirstChild("Weapon")
	if not weapon then return end
	local weaponModel = weapon:FindFirstChildWhichIsA("Model")
	if not weaponModel then return end
	local grip = weaponModel:FindFirstChild("Grip")
	if not grip then return end
	if attachmentType == 0 and grip:FindFirstChild("Flashlight") then
		repToggleAttachment:FireToAllExcept(player,grip.Flashlight,toggle)
	elseif attachmentType == 1 and grip:FindFirstChild("Laser") then
		repToggleAttachment:FireToAllExcept(player,grip.Laser,toggle,char)
	end
end)

magGrab:Connect(function(player)
	if player.Character then
		local tool = player.Character:FindFirstChildWhichIsA("Tool")
		local humanoid = player.Character.Humanoid
		if not tool or not humanoid or humanoid.Health <= 0 then return end

		if not tool:FindFirstChild("SPH_Weapon") then return end
		local weaponModel = player.Character.WeaponRig.Weapon:FindFirstChildWhichIsA("Model")
		local wepStats = require(tool.SPH_Weapon.WeaponStats)

		local magPart = wepStats.projectile ~= "Bullet" and weaponModel[wepStats.projectile] or weaponModel:FindFirstChild("Mag")
		if magPart then
			repMagGrab:FireToAllExcept(player,magPart)
		end
	end
end)

playerLean:Connect(function(player,leanDirection)
	if player.Character then
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if not humanoid or humanoid.Health <= 0 then return end
		repLean:FireToAllExcept(player,player.Character,leanDirection)
	end
end)

toggleFreeCam:Connect(function(player)
	local newState = not player:GetAttribute("FreeCamActive")
	player:SetAttribute("FreeCamActive", newState)
	toggleFreeCam:FireTo(player, newState)
end)