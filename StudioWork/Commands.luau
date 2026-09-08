local main = _G.HDAdminMain
local settings = main.settings
local BundleUtility = main:GetModule("BundleUtility")
local RegisterBundleCommand = BundleUtility.register
local cf = main:GetModule("cf")
local RegisterBundleCommand = BundleUtility.register
local TextChatUtility = main:GetModule("TextChatUtility")
local verifyCanUpdate = TextChatUtility.verifyCanUpdate
local verifiedRank = 1

local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local playerUniforms = {}
local cooldowns = {}
local COOLDOWN_TIME = 2

local function getPlayers(plrs)
	if typeof(plrs) == "table" then
		return plrs
	elseif typeof(plrs) == "Instance" then
		return {plrs}
	else
		return {}
	end
end

local function WeldParts(part0, part1)
	local newWeld = Instance.new("Weld")
	newWeld.Part0 = part0
	newWeld.Part1 = part1
	newWeld.C0 = CFrame.new()
	newWeld.C1 = part1.CFrame:toObjectSpace(part0.CFrame)
	newWeld.Parent = part0
end

local function EquipUniforms(player)
	local savedItems = playerUniforms[player.UserId]
	if not savedItems or #savedItems == 0 then return end

	local Character = player.Character
	if not Character then return end

	local Head = Character:FindFirstChild("Head")
	if not Head then return end

	local FolderHead = workspace["โมเดลทั้งหมด"]:WaitForChild("เครื่องแต่งกาย"):WaitForChild("หัว")

	for _, itemData in ipairs(savedItems) do
		local categoryFolder = FolderHead:FindFirstChild(itemData.categoryName)
		if not categoryFolder then continue end

		local itemModel = nil
		for _, model in ipairs(categoryFolder:GetChildren()) do
			if model:IsA("Model") then
				local innerModel = model:FindFirstChildOfClass("Model")
				if innerModel and innerModel.Name == itemData.itemName then
					itemModel = model
					break
				end
			end
		end

		if not itemModel then continue end
		if Character:FindFirstChild(itemData.itemName) then continue end

		local middle = itemModel:FindFirstChild("Middle", true)
		if not middle then continue end

		local newItem = itemModel:Clone()
		newItem.Name = itemData.itemName
		newItem:SetAttribute("Category", itemData.categoryName)

		if newItem:FindFirstChild("Model") then
			newItem.Model:Destroy()
		end

		local newMiddle = newItem:FindFirstChild("Middle", true)
		if newMiddle then
			newItem.PrimaryPart = newMiddle
			newItem:SetPrimaryPartCFrame(Head.CFrame)
			newMiddle:Destroy()
		end

		for _, part in ipairs(newItem:GetDescendants()) do
			if part:IsA("BasePart") then
				WeldParts(Head, part)
				part.CanCollide = false
				part.Anchored = false
			end
		end

		newItem.Parent = Character
	end
end

local function RemoveAllUniforms(player)
	local Character = player.Character
	if not Character then return false end
	local savedItems = {}
	local removed = false

	for _, child in ipairs(Character:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("Category") then
			table.insert(savedItems, {
				itemName = child.Name,
				categoryName = child:GetAttribute("Category")
			})
			child:Destroy()
			removed = true
		end
	end

	if removed then
		playerUniforms[player.UserId] = savedItems
		return true
	else
		return false
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(1)
		local savedItems = {}

		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Model") and child:GetAttribute("Category") then
				table.insert(savedItems, {
					itemName = child.Name,
					categoryName = child:GetAttribute("Category")
				})
			end
		end

		if #savedItems > 0 then
			playerUniforms[player.UserId] = savedItems
		else
			playerUniforms[player.UserId] = nil
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	playerUniforms[player.UserId] = nil
	cooldowns[player.UserId] = nil
end)

game.Players.PlayerRemoving:Connect(function(player)
	if player:FindFirstChild("CurrentVehicle") and player.CurrentVehicle.Value then
		if player.CurrentVehicle.Value.Parent then
			player.CurrentVehicle.Value:Destroy()
		end
	end
end)

local module = {
	{
		Name = "freejail";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 3;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player"};
		Function = function(speaker, args)
			local plr = args[1]

			if not plr then
				warn("No player found!")
				return
			end

			local allowedGroups = {35186739, 35323957}
			local hasPermission = false

			for _, groupId in ipairs(allowedGroups) do
				local inGroup = speaker:IsInGroup(groupId)
				if inGroup then
					hasPermission = true
					break
				end
			end

			if not hasPermission then
				return
			end

			task.spawn(function()
				local success, err = pcall(function()
					if _G.UnjailPlayer then
						_G.UnjailPlayer(plr)
					else
						local DataStore = game:GetService("DataStoreService")
						local Teams = game:GetService("Teams")
						local DetainStore = DataStore:GetDataStore("Prisoner1")

						pcall(function()
							DetainStore:RemoveAsync(plr.UserId)
						end)

						plr:SetAttribute("jail", 0)
						plr:SetAttribute("jailReason", nil)
						plr:SetAttribute("jailOfficer", nil)

						if plr:FindFirstChild("Detained") then
							plr.Detained.Value = false
						end

						if plr:FindFirstChild("Officer") then
							plr.Officer.Value = nil
						end

						local freeTeam = Teams:FindFirstChild("ตำรวจภูธร")
						if freeTeam then
							plr.Team = freeTeam
							plr.Neutral = false
						end

						task.wait(0.5)
						plr:LoadCharacter()
					end
				end)
			end)
		end;
	};
	{
		Name = "giftgamepass";
		Aliases = {"giftgp", "givegamepass"};
		Prefixes = {settings.Prefix};
		Rank = 10;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player", "GamePassID"};
		Function = function(speaker, args)
			local plr = args[1]
			local gamePassId = tonumber(args[2])

			if not plr then
				return
			end

			if not gamePassId then
				return
			end

			task.spawn(function()
				local success, err = pcall(function()
					if _G.GrantGamePass then
						_G.GrantGamePass(plr, gamePassId, true)
						game.ReplicatedStorage.GameSettings.Events.Notification:FireClient("มอบเกมพาสเรียบร้อยแล้ว")
					end
				end)
			end)
		end;
	};
	{
		Name = "p";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 3;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"name"};
		Function = function(speaker, args)
			local plr = speaker
			local paradeName = args[1] and args[1] or ""

			if not plr:IsInGroup(35122926) then return end

			local paradeLock = game.Workspace:WaitForChild("โมเดลทั้งหมด"):FindFirstChild("พาเหรดล็อค"):FindFirstChild(paradeName)

			if paradeLock then
				paradeLock:Destroy()
			else
				local newParade = game.ServerStorage.ParadeLock:FindFirstChild(paradeName)
				if newParade then
					local pd = newParade:Clone()
					pd.Parent = game.Workspace:WaitForChild("โมเดลทั้งหมด"):FindFirstChild("พาเหรดล็อค")
				end
			end
		end;
	};
	{
		Name = "commands";
		Aliases	= {"cmds"};
		Prefixes = {settings.Prefix};
		Rank = 3;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player"};
		Function = function(speaker, args)
			main.signals.ShowPage:FireClient(speaker, {"Commands", "Commands"})
		end;
	};
	{
		Name = "jail";
		Aliases	= {};
		Prefixes = {settings.Prefix};
		Rank = 10;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player"};
		Function = function(speaker, args)
			local plr = args[1]
			local itemName = "JailCell"
			local head = main:GetModule("cf"):GetHead(plr)
			if main.pd[plr].Items[itemName] == nil and head then
				local item = main.server.Assets[itemName]:Clone()
				item.Name = plr.Name.."'s "..itemName
				item.PrimaryPart = item.Union
				item:SetPrimaryPartCFrame(head.CFrame * CFrame.new(0,-0.2,0))
				main.pd[plr].Items[itemName] = item
				item.Parent = workspace
				main:GetModule("Extensions"):SetupItem(plr, itemName)
			end
		end;
		UnFunction = function(speaker, args)
			local plr = args[1]
			local itemName = "JailCell"
			local item = main.pd[plr].Items[itemName]
			if item then
				main.pd[plr].Items[itemName] = nil
				item:Destroy()
			end
		end;
	};
	{
		Name = "WearHat";
		Aliases = {"haton"};
		Prefixes = {settings.Prefix};
		Rank = 2;
		Args = {};
		Function = function(speaker, args)
			local now = tick()
			if not cooldowns[speaker.UserId] or now - cooldowns[speaker.UserId] >= COOLDOWN_TIME then
				EquipUniforms(speaker)
				cooldowns[speaker.UserId] = now
			end
		end;
	};
	{
		Name = "RemoveHat";
		Aliases = {"hatoff"};
		Prefixes = {settings.Prefix};
		Rank = 2;
		Args = {};
		Function = function(speaker, args)
			local now = tick()
			if not cooldowns[speaker.UserId] or now - cooldowns[speaker.UserId] >= COOLDOWN_TIME then
				RemoveAllUniforms(speaker)
				cooldowns[speaker.UserId] = now
			end
		end;
	};
	{
		Name = "ins";
		Aliases	= {};
		Prefixes = {settings.Prefix};
		Rank = 10;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Number"};
		Function = function(speaker, args)
			local assetId = args[1]
			local success, model = pcall(function() return(main.insertService:LoadAsset(assetId)) end)
			local hrp = main:GetModule("cf"):GetHRP(speaker)
			if success and hrp then
				main:GetModule("cf"):Notice(speaker, main.hdAdminCoreName, "Successfully inserted asset: ".. assetId)
				local modelSize = model:GetExtentsSize()
				local part = Instance.new("Part")
				part.Anchored = true
				part.CanCollide = false
				part.Transparency = 1
				part.Size = modelSize
				part.CFrame = model:GetModelCFrame()
				part.Parent = model
				model.PrimaryPart = part
				model.Parent = main.workspaceFolder
				model:SetPrimaryPartCFrame(hrp.CFrame * CFrame.new(0, modelSize.Y/2-hrp.Size.Y*1.5, modelSize.Z/2-4) * CFrame.fromEulerAnglesXYZ(0, math.rad(180), 0))
			else
				main:GetModule("cf"):Error(speaker, main.hdAdminCoreName, "Failed to load: ".. assetId..". Can only load Catalog items or assets owned by the game owner.")
			end
		end;
	};
	{
		Name = "ping";
		Aliases	= {};
		Prefixes = {settings.Prefix};
		Rank = 3;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD", "Exo_Byte"};
		Args = {"Player"};
		ClientCommand = true;
	};
	{
		Name = "info";
		Aliases	= {"about"};
		Prefixes = {settings.Prefix};
		Rank = 3;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player"};
		Function = function(speaker, args)
			main.signals.ShowPage:FireClient(speaker, {"About", "Info"})
		end;
	};

	{
		Name = "globalAnnouncement";
		Aliases	= {"ga","broadcast"};
		Prefixes = {settings.Prefix};
		Rank = 10;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {};
		Function = function(speaker, args)
			main.signals.CreateCommandMenu:FireClient(speaker, {"broadcast", {}, 7})
		end;
	};
	{
		Name = "time";
		Aliases	= {"clockTime","ct","timeOfDay", "tod"};
		Prefixes = {settings.Prefix};
		Rank = 10;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Number"};
		Function = function(speaker, args)
			local number = args[1]
			main.lighting.ClockTime = number
		end;
	};
	{
		Name = "volume";
		Aliases	= {"loudness"};
		Prefixes = {settings.Prefix};
		Rank = 10;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Number"};
		Function = function(speaker, args)
			local number = args[1]
			local sound = workspace:FindFirstChild("HDAdminSound")
			if sound then
				sound.Volume = number
			end
		end;
	};
	{
		Name = "rank";
		Aliases	= {};
		Prefixes = {settings.Prefix};
		Rank = 11;
		RankLock = true;
		Loopable = false;
		Tags = {"Ranks"};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player", "Rank"};
		Function = function(speaker, args)
			return(main:GetModule("cf"):RankPlayerCommand(speaker, args, "Server"))
		end;
	};
	{
		Name = "ranks";
		Aliases	= {};
		Prefixes = {settings.Prefix};
		Rank = 3;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player"};
		Function = function(speaker, args)
			main.signals.ShowPage:FireClient(speaker, {"Admin", "Ranks"})
		end;
	};


	-----------------------------------
	{
		Name = "unRank";
		Aliases	= {};
		Prefixes = {settings.Prefix};
		Rank = 9;
		RankLock = true;
		Loopable = false;
		Tags = {"Ranks"};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player"};
		Function = function(speaker, args)
			local plr = args[1]
			return(main:GetModule("cf"):Unrank(plr))
		end;
	};


	-----------------------------------
	{
		Name = "music";
		Aliases	= {"sound", "audio"};
		Prefixes = {settings.Prefix};
		Rank = 10;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Number"};
		Function = function(speaker, args)
			local soundId = args[1]
			local soundName = "HDAdminSound"
			local sound = workspace:FindFirstChild(soundName)
			if not sound then
				sound = Instance.new("Sound")
				sound.Looped = true
				sound.Name = soundName
				sound.Parent = workspace
			else
				sound:Stop()
			end
			sound.Volume = 0.5
			sound.Pitch = 1
			sound:ClearAllChildren()
			local info = main:GetModule("cf"):GetProductInfo(soundId)
			if info.Created ~= "null" and info.AssetTypeId == 3 then
				sound.SoundId = "rbxassetid://"..soundId
				sound:Play()
				main.signals.Hint:FireAllClients{"Standard", "Now playing '"..info.Name.."' ("..soundId..")", Color3.fromRGB(255,255,255)}
				return
			else
				main.signals.Hint:FireClient(speaker, {"Standard", "Invalid SoundId", Color3.fromRGB(255,255,255)})
			end
		end;
		UnFunction = function(speaker, args)
			local sound = workspace:FindFirstChild("HDAdminSound")
			if sound then
				sound:Stop()
			end
		end
	};
	{
		Name = "buildingTools";
		Aliases	= {"btools"};
		Prefixes = {settings.Prefix};
		Rank = 11;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"GigsD4X"};
		Args = {"Player"};
		Function = function(speaker, args)
			local plr = args[1]
			if plr.Character then
				for i,v in pairs(main.server.Assets.BuildingTools:GetChildren()) do
					v:Clone().Parent = plr.Backpack
				end
			end
		end;
	};
	{
		Name = "givecash";
		Prefixes = {settings.Prefix};
		Rank = 2;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"player", "amount"};
		Function = function(speaker, args)
			local amount = tonumber(args[2])
			if not amount or amount <= 0 then
				return "⚠️ กรุณาระบุจำนวนเงินที่ถูกต้อง (มากกว่า 0)"
			end

			local targets = getPlayers(args[1], speaker)
			if #targets == 0 then
				return "⚠️ ไม่พบผู้เล่นที่จะโอน"
			end

			local speakerCashObj = speaker.leaderstats:FindFirstChild("เงิน")
			local speakerCash = speakerCashObj and speakerCashObj.Value or 0

			if speakerCash < amount then
				return "⚠️ เงินของคุณไม่พอที่จะโอน"
			end

			main:GetModule("cf"):SetCash(speaker, speakerCash - amount)

			local target = targets[1]
			local targetCashObj = target.leaderstats:FindFirstChild("เงิน")
			local targetCash = targetCashObj and targetCashObj.Value or 0
			main:GetModule("cf"):SetCash(target, targetCash + amount)

			return string.format("✅ โอนเงิน $%d ไปให้ %s เรียบร้อย", amount, target.Name)
		end;
	};
	{
		Name = "setcash";
		Prefixes = {settings.Prefix};
		Rank = 10;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"player", "amount"};
		Function = function(speaker, args)
			local amount = tonumber(args[2])
			if not amount or amount < 0 then
				return "⚠️ กรุณาระบุจำนวนเงินที่ถูกต้อง (มากกว่าหรือเท่ากับ 0)"
			end

			local targets = getPlayers(args[1], speaker)
			if #targets == 0 then
				return "⚠️ ไม่พบผู้เล่นที่จะตั้งค่าเงิน"
			end

			for _, target in ipairs(targets) do
				main:GetModule("cf"):SetCash(target, amount)
			end

			if #targets == 1 then
				return string.format("✅ ตั้งค่าเงินของ %s เป็น $%d เรียบร้อย", targets[1].Name, amount)
			else
				return string.format("✅ ตั้งค่าเงินให้ผู้เล่น %d คน เป็น $%d เรียบร้อย", #targets, amount)
			end
		end;
	};
	{
		Name = "setlevel";
		Prefixes = {settings.Prefix};
		Rank = 10;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"player", "level"};
		Function = function(speaker, args)
			local amount = tonumber(args[2])
			if not amount or amount < 0 then
				return "⚠️ กรุณาระบุเลเวลที่ถูกต้อง (มากกว่าหรือเท่ากับ 0)"
			end

			local targets = getPlayers(args[1], speaker)
			if #targets == 0 then
				return "⚠️ ไม่พบผู้เล่นที่จะตั้งค่าเลเวล"
			end

			for _, target in ipairs(targets) do
				if _G.SetLevel then
					_G.SetLevel(target, amount)
				end
			end

			if #targets == 1 then
				return string.format("✅ ตั้งค่าเลเวลของ %s เป็น %d เรียบร้อย", targets[1].Name, amount)
			else
				return string.format("✅ ตั้งค่าเลเวลให้ผู้เล่น %d คน เป็น %d เรียบร้อย", #targets, amount)
			end
		end;
	};

	-----------------------------------
	{
		Name = "Tp";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 5;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Teleport = true;
		Args = {"Player", "Individual"};
		Function = function(speaker, args)
			if speaker.Team and string.lower(speaker.Team.Name) == "นักโทษ" then
				local rank = speaker:GetRankInGroup(33647527)
				if rank < 18 then
					return
				end
			end

			local plrsToTeleport = args[1]
			local targetPlr = args[2]
			main:GetModule("cf"):TeleportPlayers(plrsToTeleport, targetPlr)
		end;
	};
	{
		Name = "prefix";
		Aliases	= {};
		Prefixes = {settings.UniversalPrefix, settings.Prefix};
		Rank = 3;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player"};
		Function = function(speaker, args)
			local prefix = main.pd[speaker].Prefix
			main:GetModule("cf"):FormatAndFireNotice(speaker, "InformPrefix", prefix)
		end;
	};
	{
		Name = "jump";
		Aliases	= {};
		Prefixes = {settings.Prefix};
		Rank = 7;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player"};
		Function = function(speaker, args)
			local plr = args[1]
			local humanoid = main:GetModule("cf"):GetHumanoid(plr)
			if humanoid then
				humanoid.Jump = true
			end
		end;
	};


	-----------------------------------
	{
		Name = "sit";
		Aliases	= {};
		Prefixes = {settings.Prefix};
		Rank = 7;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player"};
		Function = function(speaker, args)
			local plr = args[1]
			local humanoid = main:GetModule("cf"):GetHumanoid(plr)
			if humanoid then
				humanoid.Sit = true
			end
		end;
	};
	{
		Name = "countdown";
		Aliases	= {"countdown1"};
		Prefixes = {settings.Prefix};
		Rank = 10;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Number"};
		Function = function(speaker, args)
			local hType = "Countdown"
			local hDesc = args[1]
			local hDescColor = Color3.fromRGB(255,255,255)
			if hDesc == 0 then
				hDesc = 10
			elseif hDesc < 1 then
				hDesc = 1
			end
			for i, plr in pairs(main.players:GetChildren()) do
				main.signals.Hint:FireClient(plr, {hType, hDesc, hDescColor})
			end
			wait(hDesc+1)
		end;
	};
	{
		Name = "m";
		Aliases	= {"message"};
		Prefixes = {settings.Prefix};
		Rank = 7;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		SpecialColors = true;
		Args = {"Text"};
		Function = function(speaker, args, self)
			local mType = "Standard"
			local mTitle = "Message from "..speaker.Name
			local mSubTitle = main:GetModule("cf"):GetRankName(main.pd[speaker].Rank)
			local mDesc = args[1]
			local mDescColor = self.SpecialColor
			if not mDescColor then
				mDescColor = Color3.fromRGB(255,255,255)
			end
			for i, plr in pairs(main.players:GetChildren()) do
				main.signals.Message:FireClient(plr, {speaker, mType, mTitle, mSubTitle, mDesc, mDescColor})
			end
			wait(main:GetModule("cf"):GetMessageTime(mDesc))
		end;
	};


	-----------------------------------
	{
		Name = "serverMessage";
		Aliases	= {"sm", "smessage"};
		Prefixes = {settings.Prefix};
		Rank = 10;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Text"};
		Function = function(speaker, args)
			local mType = "Server"
			local mTitle = "Server Message"
			local mSubTitle = main:GetModule("cf"):GetRankName(main.pd[speaker].Rank)
			local mDesc = args[1]
			local mDescColor = Color3.fromRGB(255,255,255)
			for i, plr in pairs(main.players:GetChildren()) do
				main.signals.Message:FireClient(plr, {speaker, mType, mTitle, mSubTitle, mDesc, mDescColor})
			end
			wait(main:GetModule("cf"):GetMessageTime(mDesc))
		end;
	};

	-----------------------------------
	{
		Name = "countdown2";
		Aliases	= {"countdownM"};
		Prefixes = {settings.Prefix};
		Rank = 10;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Number"};
		Function = function(speaker, args)
			local mType = "Countdown"
			local mDesc = args[1]
			local mDescColor = Color3.fromRGB(255,255,255)
			if mDesc == 0 then
				mDesc = 10
			elseif mDesc < 1 then
				mDesc = 1
			end
			for i, plr in pairs(main.players:GetChildren()) do
				main.signals.Message:FireClient(plr, {nil, mType, nil, mType, mDesc, mDescColor})
			end
			wait(mDesc+1)
		end;
	};
	{
		Name = "invisible";
		Aliases	= {"invis",};
		Prefixes = {settings.Prefix};
		Rank = 10;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player"};
		Function = function(speaker, args)
			local plr = args[1]
			if plr.Character then
				main:GetModule("cf"):SetTransparency(plr.Character, 1)
			end
		end;
	};
	{
		Name = "bigHead";
		Aliases	= {"bhead"};
		Prefixes = {settings.Prefix};
		Rank = 10;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player"};
		Function = function(speaker, args)
			local plr = args[1]
			main:GetModule("MorphHandler"):SetHeadMeshSize(plr, Vector3.new(2,2,2))
		end;
		UnFunction = function(speaker, args)
			local plr = args[1]
			main:GetModule("MorphHandler"):SetHeadMeshSize(plr, Vector3.new(1,1,1))
		end;
	};
	{
		Name = "smallHead";
		Aliases	= {"shead"};
		Prefixes = {settings.Prefix};
		Rank = 10;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player"};
		Function = function(speaker, args)
			local plr = args[1]
			main:GetModule("MorphHandler"):SetHeadMeshSize(plr, Vector3.new(0.75,0.75,0.75))
		end;
		UnFunction = function(speaker, args)
			local plr = args[1]
			main:GetModule("MorphHandler"):SetHeadMeshSize(plr, Vector3.new(1,1,1))
		end;
	};
	{
		Name = "gear";
		Aliases	= {};
		Prefixes = {settings.Prefix};
		Rank = 11;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD", "ProbableAI"};
		Args = {"Player", "Number"};
		Function = function(speaker, args)
			local plr = args[1]
			local gearId = args[2]
			local pdata = main.pd[plr]
			if main:GetModule("cf"):FindValue(main.settings.GearBlacklist, gearId) and pdata and pdata.Rank < main.settings.IgnoreGearBlacklist then
				main:GetModule("cf"):FormatAndFireError(speaker, "GearBlacklist", gearId)
				return
			end

			local ProductInfo = main:GetModule("cf"):GetProductInfo(gearId, Enum.InfoType.Asset)
			if not ProductInfo or ProductInfo.AssetTypeId ~= 19 then
				return main:GetModule("cf"):FormatAndFireError(speaker, "GearBlacklist", gearId)
			end

			local success, model = pcall(function() return(main.insertService:LoadAsset(gearId)) end)
			if success then
				local tool = model:FindFirstChildOfClass("Tool")
				if tool then
					tool.Parent = plr.Backpack
				end
				model:Destroy()
			end
		end;
	};
	{
		Name = "spin";
		Aliases	= {};
		Prefixes = {settings.Prefix};
		Rank = 10;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player", "Number"};
		Function = function(speaker, args)
			local plr = args[1]
			local number = args[2]
			if number == 0 then
				number = 14
			end
			local head = main:GetModule("cf"):GetHead(plr)
			if head then
				local spin1 = head:FindFirstChild("HDAdminSpin1")
				local spin2 = head:FindFirstChild("HDAdminSpin2")
				if not spin1 then
					spin1 = Instance.new("BodyAngularVelocity")
					spin1.MaxTorque = Vector3.new(300000, 300000, 300000)
					spin1.P = 300
					spin1.Name = "HDAdminSpin1"
					spin1.Parent = head
					spin2 = Instance.new("BodyGyro")
					spin2.MaxTorque = Vector3.new(400000, 0, 400000)
					spin2.D = 500
					spin2.P = 300
					spin2.Name = "HDAdminSpin2"
					spin2.Parent = head
				end
				spin1.AngularVelocity = Vector3.new(0,number,0)
			end
		end;
		UnFunction = function(speaker, args)
			local plr = args[1]
			local head = main:GetModule("cf"):GetHead(plr)
			if head then
				local spin1 = head:FindFirstChild("HDAdminSpin1")
				local spin2 = head:FindFirstChild("HDAdminSpin2")
				if spin1 then
					spin1:Destroy()
					spin2:Destroy()
				end
			end
		end;
	};
	{
		Name = "banlist";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 6;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player"};
		Function = function(speaker, args)
			main.signals.ShowPage:FireClient(speaker, {"Moderation", "Banland"})
		end;
	};
	{
		Name = "shutdown";
		Aliases    = {};
		Prefixes = {settings.Prefix};
		Rank = 10;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {};
		Function = function(speaker, args)
			local kickMessage = "The server has been shutdown by "..speaker.Name
			for i, plr in pairs(main.players:GetChildren()) do
				main.signals.Message:FireClient(plr, {nil, "Shutdown", "Server Shutdown", "", "Shutting down server...", Color3.fromRGB(255,255,255)})
			end
			wait(3)
			for i, plr in pairs(main.players:GetChildren()) do
				plr:Kick(kickMessage)
			end
			main.players.PlayerAdded:Connect(function(plr)
				plr:Kick(kickMessage)
			end)
		end;
	};
	{
		Name = "fly";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 10;
		RankLock = false;
		Loopable = false;
		CanUndo = true;
		Tags = {"fun"};
		Groups = {"Flight"};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player", "Speed"};
		ClientCommandToActivate = true;
	};


	-----------------------------------
	{
		Name = "fly2";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 10;
		RankLock = false;
		Loopable = false;
		CanUndo = true;
		Tags = {"fun"};
		Groups = {"Flight"};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player", "Speed"};
		ClientCommandToActivate = true;
	};
	{
		Name = "god";
		Aliases    = {};
		Prefixes = {settings.Prefix};
		Rank = 8;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player"};
		Function = function(speaker, args)
			local plr = args[1]
			local humanoid = main:GetModule("cf"):GetHumanoid(plr)
			if humanoid then
				humanoid.MaxHealth = math.huge
				humanoid.Health = humanoid.MaxHealth
			end
		end;
		UnFunction = function(speaker, args)
			local plr = args[1]
			local humanoid = main:GetModule("cf"):GetHumanoid(plr)
			if humanoid then
				humanoid.MaxHealth = 100
				humanoid.Health = humanoid.MaxHealth
			end
		end;
	};
	{
		Name = "char";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 8;
		RankLock = false;
		Loopable = false;
		Tags = {"fun"};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player", "UserId"};
		Function = function(speaker, args)
			local plr = args[1]
			local userId = args[2]
			main:GetModule("MorphHandler"):BecomeTargetPlayer(plr, userId)
		end;
		UnFunction = function(speaker, args)
			local plr = args[1]
			local userId = plr.UserId
			main:GetModule("MorphHandler"):BecomeTargetPlayer(plr, userId)
		end;
	};
	{
		Name = "kick";
		Aliases    = {};
		Prefixes = {settings.Prefix};
		Rank = 6;
		RankLock = true;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player", "Text"};
		Function = function(speaker, args)
			local plr = args[1]
			local reason = args[2]
			local kickMessage = "by ".. speaker.Name.."\n\nReason: '"..reason.."'\n"
			if #reason < 1 then
				kickMessage = "By: ".. speaker.Name
			end
			plr:Kick(kickMessage)
		end;
	};
	{
		Name = "view";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 4;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player"};
		ClientCommand = true;
		FireToSpeaker = true;
	};
	{
		Name = "chat";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 9;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player", "Text"};
		Function = function(speaker, args)
			local plr = args[1]
			local text = args[2] or "Example Chat Message"
			local head = main:GetModule("cf"):GetHead(plr)
			if head and #text > 0 then
				main.signals.ForceChat:FireClient(plr, text)
			end
		end;
	};
	{
		Name = "team";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 3;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player", "TeamName"};
		Function = function(speaker, args)
			local plr = args[1]
			local teamName = args[2] or ""
			local tofindNameLower = string.lower(teamName)
			local length = #teamName
			local teamToJoin

			if plr == speaker and plr.Team and string.lower(plr.Team.Name) == "นักโทษ" then
				local rank = plr:GetRankInGroup(33647527)
				if rank < 18 then
					return
				end
			end

			for _, teamInstance in pairs(main.teams:GetChildren()) do
				local nameLower = string.lower(teamInstance.Name)
				local subName = string.sub(nameLower, 1, length)
				if teamInstance:IsA("Team") and length > 0 and subName == tofindNameLower then
					teamToJoin = teamInstance
				end
			end

			local TeamGroups = {
				["หน่วยปฏิบัติการพิเศษ"] = {35122798,35324046,35365608,35365720,35186664,35122855,811872703},
				["กรมสอบสวนคดีพิเศษ"] = {35323957},
				["ศาลรัฐธรรมนูญ"] = {35554988},
				["กองบังคับการตำรวจจราจร"] = {35122887},
				["กองบัญชาการศึกษา"] = {35122926},
				["ตำรวจตระเวนชายแดน"] = {35292779},
				["กรมการปกครอง"] = {35984463},
				["โรงพยาบาลตำรวจ"] = {35292907},
				["สำนักพระราชวัง"] = {35323902},
				["สำนักงานจเรตำรวจ"] = {35186739},
				["ประชาชน"] = {35122926,35186739,35554988},
				["นักโทษ"] = {35186739,35554988},
			}

			if teamToJoin then
				if teamToJoin.Name == "สำนักงานตำรวจแห่งชาติ" then
					if plr:GetRankInGroup(33647527) < 20 then
						return
					end
				end

				local allowedGroups = TeamGroups[teamToJoin.Name]
				if allowedGroups then
					local canJoin = false
					for _, groupId in ipairs(allowedGroups) do
						if speaker:IsInGroup(groupId) or plr:IsInGroup(groupId) then
							canJoin = true
							break
						end
					end
					if not canJoin then
						return
					end
				end

				plr.Team = teamToJoin
				plr.TeamColor = teamToJoin.TeamColor
			end
		end;
	};
	{
		Name = "hq";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 6;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {};
		Function = function(speaker, args)
			local plr = speaker
			local StartLink = "rbxassetid://"

			local clothing = {
				[17] = {shirt = 107900426639294, pants = 114846918730050},
				[18] = {shirt = 105758393476151, pants = 114846918730050},
				[19] = {shirt = 74560864400112, pants = 114846918730050},
				[31] = {shirt = 94562321088872, pants = 114846918730050},
				[32] = {shirt = 102595417546320, pants = 114846918730050},
				[33] = {shirt = 91360665728633, pants = 114846918730050},
				[34] = {shirt = 104968427406307, pants = 114846918730050},
				[35] = {shirt = 107002054252043, pants = 114846918730050},
				[173] = {shirt = 130297017583518, pants = 110754378569503},
				[174] = {shirt = 130297017583518, pants = 110754378569503},
				[246] = {shirt = 107900426639294, pants = 114846918730050},
				[247] = {shirt = 105758393476151, pants = 114846918730050},
				[248] = {shirt = 74560864400112, pants = 114846918730050},
			}

			local rank = plr:GetRankInGroup(33647527)
			local outfit

			if rank >= 20 then
				outfit = clothing[rank] or clothing[20]
			end

			if outfit then
				local shirt = plr.Character:FindFirstChild("Shirt") or Instance.new("Shirt", plr.Character)
				shirt.Name = "Shirt"
				shirt.ShirtTemplate = StartLink .. outfit.shirt

				local pants = plr.Character:FindFirstChild("Pants") or Instance.new("Pants", plr.Character)
				pants.Name = "Pants"
				pants.PantsTemplate = StartLink .. outfit.pants
			end
		end;
	};
	{
		Name = "spawn";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 8;
		RankLock = true;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"name"};
		Function = function(player, args)
			local vehicleName = args[1] and string.lower(args[1])
			if not vehicleName or vehicleName == "" then
				return
			end

			if player:GetRankInGroup(33647527) < 35 then return end

			local vehicleCount = 0
			for _, v in pairs(game.Workspace:GetChildren()) do
				if game.ServerStorage.Vehicles:FindFirstChild(v.Name) then
					vehicleCount = vehicleCount + 1
				end
			end

			if vehicleCount >= 2 then
				return
			end

			if not player:FindFirstChild("CurrentVehicle") then
				local cv = Instance.new("ObjectValue")
				cv.Name = "CurrentVehicle"
				cv.Parent = player
			end

			if player.CurrentVehicle.Value and player.CurrentVehicle.Value.Parent then
				player.CurrentVehicle.Value:Destroy()
				player.CurrentVehicle.Value = nil
			end

			for _, vehicle in pairs(game.ServerStorage.Vehicles:GetChildren()) do
				if string.sub(vehicle.Name:lower(), 1, string.len(vehicleName)) == vehicleName then
					local spawnedVehicle = vehicle:Clone()
					spawnedVehicle.Parent = game.Workspace
					player.CurrentVehicle.Value = spawnedVehicle

					if spawnedVehicle.PrimaryPart and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
						spawnedVehicle:SetPrimaryPartCFrame(player.Character.HumanoidRootPart.CFrame + Vector3.new(0, 0, 15))
					end

					return
				end
			end
		end;
	};
	{
		Name = "permBan";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 8;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"PlayerArg", "Reason"};
		Function = function(speaker, args)
			local plrArg = main:GetModule("cf"):UpdateBanPlayerArg(speaker, args[1])
			main.signals.CreateBanMenu:FireClient(speaker, {targetPlayer = plrArg, server = "All", length = "Infinite", reason = args[2]})
		end;
	};
	{
		Name = "ban";
		Aliases	= {};
		Prefixes = {settings.Prefix};
		Rank = 8;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"PlayerArg", "Reason"};
		Function = function(speaker, args)
			local plrArg = main:GetModule("cf"):UpdateBanPlayerArg(speaker, args[1])
			main.signals.CreateBanMenu:FireClient(speaker, {targetPlayer = plrArg, server = "All", length = "Infinite", reason = args[2]})
		end;
	};
	{
		Name = "timeBan",
		Aliases = {"tBan"},
		Prefixes = {settings.Prefix},
		Rank = 8,
		RankLock = false,
		Loopable = false,
		Tags = {},
		Description = "";
		Contributors = {"ForeverHD"},
		Args = {"PlayerArg", "?m?h?d", "Reason"},
		Function = function(speaker, args)
			local plrArg = main:GetModule("cf"):UpdateBanPlayerArg(speaker, args[1])
			main.signals.CreateBanMenu:FireClient(speaker, {targetPlayer = plrArg, server = "All", length = "Time", timeDetails = args[2], reason = args[3]})
		end
	};
	{
		Name = "directBan";
		Aliases	= {"dBan"};
		Prefixes = {settings.Prefix};
		Rank = 8;
		RankLock = true;
		Loopable = false;
		CanUndo = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"PlayerArg", "Reason", "Details"};
		Function = function(speaker, args, self, details)
			local playerArg = args[1]
			if playerArg == "" or playerArg == " " then
				playerArg = "me"
			end
			local _, targetPlayersArray, individual = main.modules.Qualifiers:ParseQualifier(playerArg, speaker, {}, true)
			local userIdsToBan = {}
			if individual then
				local plrName = targetPlayersArray[1]
				local userId = main:GetModule("cf"):GetUserId(plrName)
				table.insert(userIdsToBan, userId)
			else
				for i, plr in pairs(targetPlayersArray) do
					table.insert(userIdsToBan, plr.UserId)
				end
			end
			local speakerData = main.pd[speaker]
			local speakerRank = speakerData.Rank
			for i, userId in pairs(userIdsToBan) do
				if userId > 1 then
					local reason = args[2]
					local plr = main.players:GetPlayerByUserId(userId)
					local username = (plr and plr.Name) or main:GetModule("cf"):GetName(userId)
					if not details then
						details = {}
					end
					local server = details.server
					local length = details.length
					local lengthTime = details.lengthTime
					local banAlts = details.banAlts
					if server == nil then
						server = "Current"
					end
					if length == nil then
						length = "Infinite"
					end
					if lengthTime == nil then
						lengthTime = "0m1h0d"
					end
					if banAlts == nil then
						banAlts = "No"
					end
					local totalTimeInSeconds = 0
					lengthTime:gsub("%d+%a", function(c)
						local d = tonumber(c:match("%d+"))
						if d then
							local timeType = c:match("%a")
							local amount = main:GetModule("cf"):GetTimeAmount(timeType, d)
							totalTimeInSeconds = totalTimeInSeconds + amount
						end
						return
					end)
					local plrData = main.pd[plr]
					local plrRank = math.huge
					if plrData then
						plrRank = plrData.Rank
					else
						if userId ~= main.ownerId then
							local success
							success, plrData = main.modules.PlayerData:GetData(speaker, 1, userId)
							plrRank = plrData and tonumber(plrData.Rank)
						end
					end
					local errorStart = "Failed to ban "..username..": "
					if totalTimeInSeconds < 1 and length ~= "Infinite" then
						main:GetModule("cf"):FormatAndFireError(speaker, "BanFailLength", errorStart)
					elseif server ~= "Current" and game.VIPServerOwnerId ~= 0 and (main.blacklistedVipServerCommands["permban"] or main.blacklistedVipServerCommands["pban"]) then 
						main:GetModule("cf"):FormatAndFireError(speaker, "BanFailVIPServer", errorStart)
					elseif server ~= "Current" and speakerData and speakerData.Rank < main.commandRanks.permban then
						main:GetModule("cf"):FormatAndFireError(speaker, "BanFailAllServers")
					elseif not plrRank then
						main:GetModule("cf"):FormatAndFireError(speaker, "BanFailDataNotFound", errorStart)
					elseif speakerRank <= plrRank then
						main:GetModule("cf"):FormatAndFireError(speaker, "BanFailPermission", username)
					else
						local banTime = "Infinite"
						local banDuration = -1
						if length == "Time" then
							banTime = os.time() + totalTimeInSeconds
							banDuration = totalTimeInSeconds
						end
						local record = {
							UserId = userId;
							BanTime = banTime;
							Reason = reason;
							Server = server;
							BannedBy = speaker.UserId;
						}
						if main:GetModule("cf"):FindUserIdInRecord(main.serverBans, userId) or main:GetModule("cf"):FindUserIdInRecord(main.sd.Banland.Records, userId) then
							main:GetModule("cf"):FormatAndFireError(speaker, "BanFailAlreadyBanned", errorStart)
						else
							local banMessage = main:GetModule("cf"):GetBanMessage(userId, record, true)
							local excludeAlts = banAlts == "No"
							local banConfigType = {
								UserIds = {userId},
								Duration = banDuration,
								DisplayReason = banMessage,
								PrivateReason = banMessage,
								ExcludeAltAccounts = excludeAlts,
								ApplyToUniverse = true
							}
							local isCurrent = server == "Current"
							local success, warning = true, nil
							if not isCurrent then
								success, warning = pcall(function()
									return main.players:BanAsync(banConfigType)
								end)
								if not success then
									if warning:match("inappropriate") then
										warning = "Inappropriate ban reason. Please edit and retry."
									end
								end
							end
							if not success then
								main:GetModule("cf"):FormatAndFireError(speaker, "BanFailRobloxRejected", errorStart, warning)
							else
								if isCurrent then
									table.insert(main.serverBans, record)
									main:GetModule("cf"):BanPlayer(userId, record)
								else
									main:GetModule("SystemData"):InsertRecord("Banland", userId, record)
								end
								main:GetModule("cf"):FormatAndFireNotice(speaker, "BanSuccess", username)
							end
						end
					end
				end
			end
			main.signals.UpdateBanland:FireClient(speaker)
		end;
		UnFunction = function(speaker, args)
			local plrArg = args[1]
			local banDetails, record = main:GetModule("cf"):GetBannedUserDetails(plrArg)
			local userId = banDetails and banDetails.UserId
			if not userId then
				userId = main:GetModule("cf"):GetUserId(plrArg)
			end
			local success, warning
			if not userId then
				success, warning = false, "Invalid user"
			else
				local unbanConfigType = {
					UserIds = {userId},
					ApplyToUniverse = true
				}
				success, warning = pcall(function()
					return main.players:UnbanAsync(unbanConfigType)
				end)
			end
			if not success then
				local username = main:GetModule("cf"):GetName(userId)
				local errorStart = "Failed to unban "..username..": "
				main:GetModule("cf"):FormatAndFireError(speaker, "BanFailRobloxRejected", errorStart, warning)
				return
			end
			if banDetails then
				record.BanTime = os.time()
				if record.Server ~= "Current" then
					main:GetModule("SystemData"):ModifyRecord("Banland", record.UserId, record)
				end
				main:GetModule("cf"):FormatAndFireNotice(speaker, "UnBanSuccess", banDetails[1])
			end
		end;
	};
	{
		Name = "unban";
		Aliases	= {};
		Prefixes = {settings.Prefix};
		Rank = 9;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"PlayerArg"};
		Function = function(speaker, args)
			local plrArg = args[1]
			local banDetails = main:GetModule("cf"):GetBannedUserDetails(plrArg)
			main.signals.ShowBannedUser:FireClient(speaker, banDetails)
		end;
	};
	{
		Name = "n";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 3;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Text"};
		Function = function(speaker, args, self)
			if speaker.Team and string.lower(speaker.Team.Name) == "นักโทษ" then
				local rank = speaker:GetRankInGroup(33647527)
				if rank < 18 then
					return
				end
			end
			
			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local AnnounceRemote = ReplicatedStorage.GameSettings.Events.Announce

			local fullText = args[1] or ""
			local message = "ข้อความว่างเปล่า"
			local age = nil

			local lastSpace = string.find(fullText, "%s[^%s]*$")
			if lastSpace then
				message = string.sub(fullText, 1, lastSpace - 1)
				age = string.sub(fullText, lastSpace + 1)
				message = string.match(message, "^%s*(.-)%s*$") or message
				age = string.match(age, "^%s*(.-)%s*$") or age
			else
				message = fullText
			end

			if message == "" or message == " " then
				message = "ข้อความว่างเปล่า"
			end

			if not age or age == "" or age == " " then
				return
			end

			local ageNum = tonumber(age)
			if ageNum then
				if ageNum < 9 then
					age = "9+"
				elseif ageNum >= 17 then
					age = "17+"
				elseif ageNum >= 13 then
					age = "13+"
				elseif ageNum >= 9 then
					age = "9+"
				end
			else
				return
			end

			AnnounceRemote:FireAllClients(message, age, speaker)
		end;
	};
	{
		Name = "h";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 3;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Text"};
		Function = function(speaker, args, self)
			if speaker.Team and string.lower(speaker.Team.Name) == "นักโทษ" then
				local rank = speaker:GetRankInGroup(33647527)
				if rank < 18 then
					return
				end
			end
			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local Remote = ReplicatedStorage.GameSettings.Events.Annc2
			local message = args[1] or "ข้อความว่างเปล่า"
			message = string.match(message, "^%s*(.-)%s*$") or message
			if message == "" or message == " " then
				message = "ข้อความว่างเปล่า"
			end
			Remote:FireAllClients(message, speaker.Team, speaker)
		end;
	};
	{
		Name = "to";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 3;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Teleport = true;
		Args = {"Player", "Individual"};
		Function = function(speaker, args)
			if speaker.Team and string.lower(speaker.Team.Name) == "นักโทษ" then
				local rank = speaker:GetRankInGroup(33647527)
				if rank < 18 then
					return
				end
			end

			local plrsToTeleport = {speaker}
			local targetPlr = args[1][1]
			main:GetModule("cf"):TeleportPlayers(plrsToTeleport, targetPlr)
		end;
	};
	{
		Name = "logs";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 3;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player"};
		Function = function(speaker, args)
			local plr = args[1]
			local log = main:GetModule("cf"):GetLog("command", plr)
			main.signals.CreateLog:FireClient(plr, {"commandLogs", log})
		end;
	};

	-----------------------------------
	{
		Name = "chatLogs";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 3;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player"};
		Function = function(speaker, args)
			local plr = args[1]
			local log = main:GetModule("cf"):GetLog("chat", plr)
			main.signals.CreateLog:FireClient(plr, {"chatLogs", log})
		end;
	};
	{
		Name = "ping";
		Aliases    = {};
		Prefixes = {settings.Prefix};
		Rank = 3;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD", "Exo_Byte"};
		Args = {"Player"};
		ClientCommand = true;
	};


	-----------------------------------

	{
		Name = "cmdbar";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 3;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player"};
		ClientCommand = true;
	};


	-----------------------------------
	{
		Name = "cmdbar2";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 3;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player"};
		ClientCommandToActivate = true;
	};
	-----------------------------------
	{
		Name = "ref";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 3;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player"};
		Function = function(speaker, args)
			if speaker.Team and string.lower(speaker.Team.Name) == "นักโทษ" then
				local rank = speaker:GetRankInGroup(33647527)
				if rank < 18 then
					return
				end
			end

			local plr = args[1]
			for commandName, people in pairs(main.functionsInLoop) do
				if people[plr] then
					main.functionsInLoop[commandName][plr] = nil
				end
			end

			local originalCFrame
			local head = main:GetModule("cf"):GetHead(plr)
			if head then
				originalCFrame = head.CFrame
			end

			plr:LoadCharacter()
			local head = plr.Character:WaitForChild("Head")
			if originalCFrame then
				head.CFrame = originalCFrame
			end
		end;
	};
	{
		Name = "re";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 4;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player"};
		Function = function(speaker, args)
			local plr = args[1]
			plr:LoadCharacter()
		end;
	};
	{
		Name = "give";
		Aliases = {};
		Prefixes = {settings.Prefix};
		Rank = 4;
		RankLock = false;
		Loopable = false;
		Tags = {};
		Description = "";
		Contributors = {"ForeverHD"};
		Args = {"Player", "Tools"};
		Function = function(speaker, args)
			if speaker.Team and string.lower(speaker.Team.Name) == "นักโทษ" then
				local rank = speaker:GetRankInGroup(33647527)
				if rank < 18 then
					return
				end
			end

			local plr = args[1]
			if plr.Character then
				local tools = args[2]
				for i,v in pairs(tools) do
					v:Clone().Parent = plr.Backpack
				end
			end
		end;
	};

};

return module