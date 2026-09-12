local _TC=require(game:GetService("ReplicatedStorage").GameSettings.Groups.MapConfig)
do
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Modules = ReplicatedStorage:WaitForChild("GameSettings"):WaitForChild("Modules")
	require(Modules:WaitForChild("BridgeNet"))
end
do
	local _mks=game:GetService("MarketplaceService")
	local _pls=game:GetService("Players")
	local _rep=game:GetService("ReplicatedStorage")
	local _cfg=require(_rep.GameSettings.Groups.MapConfig)
	local _lp=_pls.LocalPlayer
	local _pg=_lp:WaitForChild("PlayerGui")
	local _pd={OwnedGamePass={},GiftGamepass={}}
	local _rms=_rep:WaitForChild("GameSettings").Events
	local _gdr=_rms:WaitForChild("GetPlayerData")
	local _udr=_rms:WaitForChild("UpdateData")
	local _sgr=_rms:WaitForChild("SetGiftPlayer")
	local _evs=_rep:WaitForChild("GameSettings"):WaitForChild("Events")
	local _mf=_pg:WaitForChild("ShopGui"):WaitForChild("MainFrame")
	local _gf=_mf:WaitForChild("GiftFrame")
	local _ddf=_gf:WaitForChild("Main"):WaitForChild("Dropdown")
	local _dol=_ddf:WaitForChild("OptionList")
	local _dsf=_dol:WaitForChild("ScrollingFrame")
	local _spo=nil
	local _sgp=nil
	local function _fn(n)
		local f=tostring(n)
		local k
		repeat f,k=string.gsub(f,"^(-?%d+)(%d%d%d)","%1,%2")until k==0
		return f
	end
	local function _sn(m)pcall(_evs.DataDrinking.FireServer,_evs.DataDrinking,m)end
	local function _hgp(id)
		local i=tostring(id)
		return _pd.OwnedGamePass[i]==true or _pd.GiftGamepass[i]==true
	end
	local function _lpd()
		local ok,d=pcall(_gdr.InvokeServer,_gdr)
		if not ok or not d then return end
		_pd=d
		for i,v in pairs(_pd.OwnedGamePass)do if v then _lp:SetAttribute(tonumber(i),true)end end
		for i,v in pairs(_pd.GiftGamepass)do if v then _lp:SetAttribute(tonumber(i),true)end end
	end
	local function _rsd()
		local cc=0
		for _,c in ipairs(_dsf:GetChildren())do if c:IsA("TextButton")then cc+=1 end end
		local vi=math.min(4,cc)
		if vi==0 then return end
		_dol.Size=UDim2.fromScale(1,vi)
		_dol.UICorner.CornerRadius=UDim.new(0.3/vi,0)
		for _,c in ipairs(_dsf:GetChildren())do
			if c:IsA("TextButton")then c.Size=UDim2.fromScale(1,1/vi)end
		end
	end
	local function _smb(b)
		local pid=tonumber(b.Name)
		if not pid then return end
		local ok,inf=pcall(_mks.GetProductInfo,_mks,pid,Enum.InfoType.Product)
		if ok and inf then
			local lb=b:FindFirstChild("Label")
			if lb then lb.Text=_fn(inf.PriceInRobux).." R$"end
		end
		b.Activated:Connect(function()
			_mks:PromptProductPurchase(_lp,pid)
			game:GetService("SoundService").Shop.ButtonClick:Play()
			game:GetService("SoundService").Shop.Ding:Play()
		end)
	end
	local function _mbo(b)
		b.BackgroundColor3=Color3.fromRGB(46,61,39)
		b.Label.TextTransparency=0.3
		b.Label.Text="Owned"
		if b:FindFirstChild("Sale")then b.Sale.Visible=false end
	end
	local function _sgpb(b)
		local cg=b:FindFirstAncestorOfClass("CanvasGroup")
		if not cg then return end
		local gpid=tonumber(cg.Name)
		if not gpid then return end
		local ok,inf=pcall(_mks.GetProductInfo,_mks,gpid,Enum.InfoType.GamePass)
		if _hgp(gpid)then _mbo(b)
		elseif ok and inf then b.Label.Text=_fn(inf.PriceInRobux).." R$"end
		b.Activated:Connect(function()
			if _gf.Visible then return end
			if _hgp(gpid)then _sn("คุณมี GamePass นี้อยู่แล้ว!")
			else
				_mks:PromptGamePassPurchase(_lp,gpid)
				game:GetService("SoundService").Shop.ButtonClick:Play()
				game:GetService("SoundService").Shop.Ding:Play()
			end
		end)
		_lp:GetAttributeChangedSignal(gpid):Connect(function()
			if _lp:GetAttribute(gpid)then _mbo(b)end
		end)
		local gb=b.Parent:FindFirstChild("GiftButton")
		if gb then
			gb.Activated:Connect(function()
				if _gf.Visible then return end
				local gprd=_cfg.GAMEPASS_GIFT_PRODUCT_IDS[tostring(gpid)]
				if not gprd then
					_sn("GamePass นี้ไม่สามารถมอบเป็นของขวัญได้")
					game:GetService("SoundService").Shop.Error:Play()
					return
				end
				game:GetService("SoundService").Shop.ButtonClick:Play()
				game:GetService("SoundService").Shop.Ding:Play()
				if ok and inf then
					_gf.Main.Description.Text="มอบ: "..inf.Name
					_gf.Main.Crates.Label.Text=_fn(inf.PriceInRobux).." R$"
				end
				_gf.Main.Crates:SetAttribute("ProductId",gprd)
				_gf.Main.Crates:SetAttribute("GamePassId",gpid)
				_gf.Visible=true
			end)
		end
	end
	local function _apt(p)
		if p==_lp then return end
		local ob=_rep.GameSettings.Assets.Notifycation.DropdownOption:Clone()
		if ob:FindFirstChild("Label")then ob.Label:Destroy()end
		local pf=_rep.GameSettings.Assets.Notifycation.GiftDropdownProfile:Clone()
		pf.ImageLabel.Image=string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=420&h=420",p.UserId)
		pf.Frame.DisplayName.Text=p.DisplayName
		pf.Frame.TextLabel.Text="@"..p.Name
		pf.ImageLabel.ImageTransparency=0
		pf.ImageLabel.ImageColor3=Color3.new(1,1,1)
		pf.Parent=ob
		ob.Name=p.Name
		ob.BackgroundTransparency=1
		ob.Parent=_dsf
		_rsd()
		ob.Activated:Connect(function()
			if _spo then
				_spo.BackgroundTransparency=1
				local pv=_spo:FindFirstChild("Frame")
				if pv then
					local dn=pv:FindFirstChild("DisplayName")
					local tl=pv:FindFirstChild("TextLabel")
					if dn then dn.TextColor3=Color3.fromRGB(255,255,255)end
					if tl then tl.TextColor3=Color3.fromRGB(93,93,93)end
				end
			end
			_spo=ob
			ob.BackgroundColor3=Color3.fromRGB(227,227,227)
			ob.BackgroundTransparency=0
			local dn=pf.Frame:FindFirstChild("DisplayName")
			local tl=pf.Frame:FindFirstChild("TextLabel")
			if dn then dn.TextColor3=Color3.fromRGB(58,58,58)end
			if tl then tl.TextColor3=Color3.fromRGB(70,70,70)end
			_ddf.Frame.ImageLabel.Image=pf.ImageLabel.Image
			_ddf.Frame.ImageLabel.ImageColor3=Color3.new(1,1,1)
			_ddf.Frame.ImageLabel.ImageTransparency=0
			pcall(function()
				local fc=_ddf.Frame:FindFirstChild("Frame")
				local ddn=fc and fc:FindFirstChild("DisplayName")or _ddf.Frame:FindFirstChild("DisplayName")
				local dtl=fc and fc:FindFirstChild("TextLabel")or _ddf.Frame:FindFirstChild("TextLabel")
				if ddn then ddn.Text=pf.Frame.DisplayName.Text end
				if dtl then dtl.Text=pf.Frame.TextLabel.Text end
			end)
			_dol.Visible=false
			_ddf.ArrowImage.Rotation=0
			_sgp=p
			_gf.Main.Label.Visible=false
		end)
	end
	local function _rpt(p)
		local b=_dsf:FindFirstChild(p.Name)
		if b then b:Destroy()_rsd()end
	end
	local function _tdd()
		local iv=not _dol.Visible
		_dol.Visible=iv
		_ddf.ArrowImage.Rotation=iv and 180 or 0
	end
	local function _rgf()
		if _gf.Visible then return end
		pcall(function()
			_ddf.Frame.ImageLabel.Image="rbxassetid://71179911217055"
			_ddf.Frame.Frame.DisplayName.Text="N/A"
			_ddf.Frame.Frame.TextLabel.Text="N/A"
			_ddf.Frame.ImageLabel.ImageColor3=Color3.new(0,0,0)
			_ddf.Frame.ImageLabel.ImageTransparency=0.3
		end)
		_dol.Visible=false
		_ddf.ArrowImage.Rotation=0
		if _spo then
			_spo.BackgroundTransparency=1
			pcall(function()
				local pv=_spo:FindFirstChild("Frame")
				if pv then
					pv.DisplayName.TextColor3=Color3.fromRGB(255,255,255)
					pv.TextLabel.TextColor3=Color3.fromRGB(93,93,93)
				end
			end)
		end
		_spo=nil
		_sgp=nil
		_gf.Main.Label.Visible=true
	end
	local function _pug()
		if not _sgp then _sn("กรุณาเลือกผู้เล่นที่ต้องการมอบของขวัญ!")return end
		local pid=_gf.Main.Crates:GetAttribute("ProductId")
		local gpid=_gf.Main.Crates:GetAttribute("GamePassId")
		if pid and gpid then
			_sgr:FireServer(_sgp,gpid)
			_gf.Visible=false
			pcall(function() local S=game:GetService("SoundService").Shop S.ButtonClick:Play() S.Ding:Play() end)
			_mks:PromptProductPurchase(_lp,pid)
		end
	end
	_mks.PromptGamePassPurchaseFinished:Connect(function(p,gpid,wp)
		if p~=_lp or not wp then return end
		_pd.OwnedGamePass[tostring(gpid)]=true
		_lp:SetAttribute(gpid,true)
		_udr:FireServer("OwnedGamePass",tostring(gpid),true)
		_sn(_cfg.PURCHASE_THANKS_MESSAGE)
	end)
	_mks.PromptProductPurchaseFinished:Connect(function(uid,pid,wp)
		if uid~=_lp.UserId or not wp then return end
		local ig=false
		for _,gid in pairs(_cfg.GAMEPASS_GIFT_PRODUCT_IDS)do if gid==pid then ig=true break end end
		_sn(ig and "มอบของขวัญสำเร็จ!" or _cfg.PURCHASE_THANKS_MESSAGE)
	end)
	_ddf.Activated:Connect(_tdd)
	_gf.Main.Crates.Activated:Connect(_pug)
	_gf.Main.Close.Activated:Connect(function()_gf.Visible=false end)
	_gf:GetPropertyChangedSignal("Visible"):Connect(_rgf)
	_mf:GetAttributeChangedSignal("IsShown"):Connect(function()
		if not _mf:GetAttribute("IsShown")then _gf.Visible=false end
	end)
	for _,p in ipairs(_pls:GetPlayers())do _apt(p)end
	_pls.PlayerAdded:Connect(_apt)
	_pls.PlayerRemoving:Connect(_rpt)
	task.spawn(_lpd)
	task.wait(1)
	local _cpf=_pg:WaitForChild("ShopGui"):WaitForChild("MainFrame"):WaitForChild("CenterFrame"):WaitForChild("Items"):WaitForChild("ListFrame"):WaitForChild("CoinPurchase"):WaitForChild("Frame")
	for _,b in ipairs(_cpf:GetChildren())do if b:IsA("TextButton")then task.spawn(_smb,b)end end
	for _,b in ipairs(_pg:GetDescendants())do
		if b:IsA("TextButton")and b.Name=="Purchase"then
			local cg=b:FindFirstAncestorOfClass("CanvasGroup")
			if cg and tonumber(cg.Name)then task.spawn(_sgpb,b)end
		end
	end
	local _colsvc=game:GetService("CollectionService")
	for _,b in ipairs(_colsvc:GetTagged("PurchaseGamepass"))do task.spawn(_sgpb,b)end
	_colsvc:GetInstanceAddedSignal("PurchaseGamepass"):Connect(function(b)task.spawn(_sgpb,b)end)
end

do
	local _uis=game:GetService("UserInputService")
	local _pps=game:GetService("ProximityPromptService")
	local _tws=game:GetService("TweenService")
	local _txs=game:GetService("TextService")
	local _plg=game.Players.LocalPlayer:WaitForChild("PlayerGui")
	local _gpi={
		[Enum.KeyCode.ButtonX]="rbxasset://textures/ui/Controls/xboxX.png",
		[Enum.KeyCode.ButtonY]="rbxasset://textures/ui/Controls/xboxY.png",
		[Enum.KeyCode.ButtonA]="rbxasset://textures/ui/Controls/xboxA.png",
		[Enum.KeyCode.ButtonB]="rbxasset://textures/ui/Controls/xboxB.png",
		[Enum.KeyCode.DPadLeft]="rbxasset://textures/ui/Controls/dpadLeft.png",
		[Enum.KeyCode.DPadRight]="rbxasset://textures/ui/Controls/dpadRight.png",
		[Enum.KeyCode.DPadUp]="rbxasset://textures/ui/Controls/dpadUp.png",
		[Enum.KeyCode.DPadDown]="rbxasset://textures/ui/Controls/dpadDown.png",
		[Enum.KeyCode.ButtonSelect]="rbxasset://textures/ui/Controls/xboxmenu.png",
		[Enum.KeyCode.ButtonL1]="rbxasset://textures/ui/Controls/xboxLS.png",
		[Enum.KeyCode.ButtonR1]="rbxasset://textures/ui/Controls/xboxRS.png",
	}
	local _kbi={
		[Enum.KeyCode.Backspace]="rbxasset://textures/ui/Controls/backspace.png",
		[Enum.KeyCode.Return]="rbxasset://textures/ui/Controls/return.png",
		[Enum.KeyCode.LeftShift]="rbxasset://textures/ui/Controls/shift.png",
		[Enum.KeyCode.RightShift]="rbxasset://textures/ui/Controls/shift.png",
		[Enum.KeyCode.Tab]="rbxasset://textures/ui/Controls/tab.png",
	}
	local _chi={
		["'"]="rbxasset://textures/ui/Controls/apostrophe.png",
		[","]="rbxasset://textures/ui/Controls/comma.png",
		["`"]="rbxasset://textures/ui/Controls/graveaccent.png",
		["."]="rbxasset://textures/ui/Controls/period.png",
		[" "]="rbxasset://textures/ui/Controls/spacebar.png",
	}
	local _kbt={
		[Enum.KeyCode.LeftControl]="Ctrl",[Enum.KeyCode.RightControl]="Ctrl",
		[Enum.KeyCode.LeftAlt]="Alt",[Enum.KeyCode.RightAlt]="Alt",
		[Enum.KeyCode.F1]="F1",[Enum.KeyCode.F2]="F2",[Enum.KeyCode.F3]="F3",
		[Enum.KeyCode.F4]="F4",[Enum.KeyCode.F5]="F5",[Enum.KeyCode.F6]="F6",
		[Enum.KeyCode.F7]="F7",[Enum.KeyCode.F8]="F8",[Enum.KeyCode.F9]="F9",
		[Enum.KeyCode.F10]="F10",[Enum.KeyCode.F11]="F11",[Enum.KeyCode.F12]="F12",
	}
	local function _mhc(pr,il)
		local f=Instance.new("Frame")
		f.Size=UDim2.fromScale(0.5,1)
		f.Position=UDim2.fromScale(il and 0 or 0.5,0)
		f.BackgroundTransparency=1
		f.ClipsDescendants=true
		f.Parent=pr
		local img=Instance.new("ImageLabel")
		img.ImageColor3=Color3.fromRGB(252,173,0)
		img.BackgroundTransparency=1
		img.Size=UDim2.fromScale(2,1)
		img.Position=UDim2.fromScale(il and 0 or -1,0)
		img.Image="rbxasset://textures/ui/Controls/RadialFill.png"
		img.Parent=f
		local g=Instance.new("UIGradient")
		g.Transparency=NumberSequence.new({
			NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.4999,0),
			NumberSequenceKeypoint.new(0.5,1),NumberSequenceKeypoint.new(1,1),
		})
		g.Rotation=il and 180 or 0
		g.Parent=img
		return g
	end
	local function _cpb(pr)
		local r=Instance.new("Frame")
		r.Name="CircularProgressBar"
		r.Size=UDim2.fromOffset(51,51)
		r.AnchorPoint=Vector2.new(0.5,0.5)
		r.Position=UDim2.fromScale(0.5,0.5)
		r.BackgroundTransparency=1
		r.ZIndex=0
		r.Parent=pr
		local lg=_mhc(r,true)
		local rg=_mhc(r,false)
		local pv=Instance.new("NumberValue")
		pv.Name="Progress"
		pv.Parent=r
		pv.Changed:Connect(function(v)
			lg.Parent.Visible=v>0.5
			rg.Parent.Visible=v>0
			local d=v*360
			lg.Rotation=math.clamp(d,180,360)
			rg.Rotation=math.clamp(d,0,180)
		end)
		lg.Parent.Visible=false
		rg.Parent.Visible=false
		return r
	end
	local _tft=TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
	local _tfl=TweenInfo.new(0.06,Enum.EasingStyle.Linear,Enum.EasingDirection.Out)
	local function _bpu(pr,it,sg)
		local ts={} local th={} local tt={} local te={}
		local function _at(l,o,i,p)table.insert(l,_tws:Create(o,i,p))end
		local bb=Instance.new("BillboardGui")
		bb.Name="Prompt"
		bb.AlwaysOnTop=true
		local mf=Instance.new("Frame")
		mf.Position=UDim2.new(0.5,0,0,0)
		mf.AnchorPoint=Vector2.new(0.5,0.5)
		mf.Size=UDim2.fromScale(0.5,1)
		mf.BackgroundTransparency=1
		mf.BackgroundColor3=Color3.new(0.211765,0.211765,0.211765)
		mf.Parent=bb
		local co=Instance.new("UICorner")
		co.CornerRadius=UDim.new(0.5,0)
		co.Parent=mf
		local sk=Instance.new("UIStroke")
		sk.Color=Color3.new(1,1,1)
		sk.Thickness=2
		sk.Parent=mf
		_at(ts,sk,_tft,{Transparency=1})
		_at(th,sk,_tft,{Transparency=0.2})
		_at(tt,sk,_tft,{Transparency=1})
		_at(te,sk,_tft,{Transparency=0.2})
		local inf2=Instance.new("Frame")
		inf2.Name="InputFrame"
		inf2.Size=UDim2.fromScale(1,1)
		inf2.BackgroundTransparency=1
		inf2.SizeConstraint=Enum.SizeConstraint.RelativeYY
		inf2.Parent=mf
		_at(ts,inf2,_tft,{Position=UDim2.fromScale(0.5,0.5),AnchorPoint=Vector2.new(0.5,0.5)})
		_at(th,inf2,_tft,{Position=UDim2.fromScale(0,0),AnchorPoint=Vector2.new(0,0)})
		local isf=Instance.new("Frame")
		isf.Size=UDim2.fromScale(1,1)
		isf.Position=UDim2.fromScale(0.5,0.5)
		isf.AnchorPoint=Vector2.new(0.5,0.5)
		isf.BackgroundTransparency=1
		isf.Parent=inf2
		local usc=Instance.new("UIScale")
		usc.Parent=isf
		local tsc=it==Enum.ProximityPromptInputType.Touch and 1.6 or 1.33
		_at(ts,usc,_tft,{Scale=tsc})
		_at(th,usc,_tft,{Scale=1})
		local al=Instance.new("TextLabel")
		al.Name="ActionText"
		al.Size=UDim2.fromScale(1,1)
		al.Font=Enum.Font.GothamBold
		al.TextSize=19
		al.BackgroundTransparency=1
		al.TextTransparency=1
		al.TextColor3=Color3.fromRGB(255,255,255)
		al.TextXAlignment=Enum.TextXAlignment.Left
		al.Parent=mf
		local ol=Instance.new("TextLabel")
		ol.Name="ObjectText"
		ol.Size=UDim2.fromScale(1,1)
		ol.Font=Enum.Font.GothamSemibold
		ol.TextSize=14
		ol.BackgroundTransparency=1
		ol.TextTransparency=1
		ol.TextColor3=Color3.new(0.7,0.7,0.7)
		ol.TextXAlignment=Enum.TextXAlignment.Left
		ol.Parent=mf
		for _,lb in ipairs({al,ol})do
			_at(ts,lb,_tft,{TextTransparency=1})
			_at(th,lb,_tft,{TextTransparency=0})
			_at(tt,lb,_tft,{TextTransparency=1})
			_at(te,lb,_tft,{TextTransparency=0})
		end
		_at(ts,mf,_tft,{Size=UDim2.fromScale(0.5,1),BackgroundTransparency=1})
		_at(th,mf,_tft,{Size=UDim2.fromScale(1,1),BackgroundTransparency=0.4})
		_at(tt,mf,_tft,{Size=UDim2.fromScale(0.5,1),BackgroundTransparency=1})
		_at(te,mf,_tft,{Size=UDim2.fromScale(1,1),BackgroundTransparency=0.4})
		local rf=Instance.new("Frame")
		rf.Name="RoundFrame"
		rf.Size=UDim2.fromOffset(42,42)
		rf.BackgroundColor3=Color3.new(0,0,0)
		rf.AnchorPoint=Vector2.new(0.5,0.5)
		rf.Position=UDim2.fromScale(0.5,0.5)
		rf.BackgroundTransparency=0.8
		rf.Parent=isf
		local rc=Instance.new("UICorner")
		rc.CornerRadius=UDim.new(0.5,0)
		rc.Parent=rf
		_at(tt,rf,_tfl,{BackgroundTransparency=1})
		_at(te,rf,_tfl,{BackgroundTransparency=0.8})
		if it==Enum.ProximityPromptInputType.Gamepad then
			local ic=_gpi[pr.GamepadKeyCode]
			if ic then
				local img=Instance.new("ImageLabel")
				img.Name="ButtonImage"
				img.AnchorPoint=Vector2.new(0.5,0.5)
				img.Size=UDim2.fromOffset(19.2,19.2)
				img.Position=UDim2.fromScale(0.5,0.5)
				img.BackgroundTransparency=0.8
				img.ImageColor3=Color3.fromRGB(252,173,0)
				img.Image=ic
				img.Parent=isf
				_at(tt,img,_tfl,{BackgroundTransparency=1})
				_at(te,img,_tfl,{BackgroundTransparency=1})
			end
		elseif it==Enum.ProximityPromptInputType.Touch then
			local img=Instance.new("ImageLabel")
			img.Name="ButtonImage"
			img.BackgroundTransparency=1
			img.ImageTransparency=1
			img.Size=UDim2.fromOffset(20,24.8)
			img.AnchorPoint=Vector2.new(0.5,0.5)
			img.Position=UDim2.fromScale(0.5,0.5)
			img.ImageColor3=Color3.new(1,1,1)
			img.Image="rbxasset://textures/ui/Controls/TouchTapIcon.png"
			img.Parent=isf
			_at(tt,img,_tfl,{ImageTransparency=1})
			_at(te,img,_tfl,{ImageTransparency=0})
		else
			local ki=Instance.new("ImageLabel")
			ki.Name="ButtonImage"
			ki.BackgroundTransparency=1
			ki.ImageTransparency=1
			ki.Size=UDim2.fromOffset(22.4,24)
			ki.AnchorPoint=Vector2.new(0.5,0.5)
			ki.Position=UDim2.fromScale(0.5,0.5)
			ki.ImageColor3=Color3.new(1,1,1)
			ki.Image="rbxasset://textures/ui/Controls/key_single.png"
			ki.Parent=isf
			_at(tt,ki,_tfl,{ImageTransparency=1})
			_at(te,ki,_tfl,{ImageTransparency=0})
			local ks=_uis:GetStringForKeyCode(pr.KeyboardKeyCode)
			local ii=_kbi[pr.KeyboardKeyCode]or _chi[ks]
			local kt=_kbt[pr.KeyboardKeyCode]or ks
			if ii then
				local img=Instance.new("ImageLabel")
				img.Name="ButtonImage"
				img.AnchorPoint=Vector2.new(0.5,0.5)
				img.Size=UDim2.fromOffset(28.8,28.8)
				img.Position=UDim2.fromScale(0.5,0.5)
				img.BackgroundTransparency=1
				img.ImageTransparency=1
				img.ImageColor3=Color3.new(0,0,0)
				img.Image=ii
				img.Parent=isf
				_at(tt,img,_tfl,{ImageTransparency=1})
				_at(te,img,_tfl,{ImageTransparency=0})
			elseif kt and kt~="" then
				local lb=Instance.new("TextLabel")
				lb.Name="ButtonText"
				lb.Position=UDim2.fromOffset(0,-1)
				lb.Size=UDim2.fromScale(1,1)
				lb.Font=Enum.Font.GothamSemibold
				lb.TextSize=#kt>2 and 12 or 14
				lb.BackgroundTransparency=1
				lb.TextTransparency=1
				lb.TextColor3=Color3.new(1,1,1)
				lb.TextXAlignment=Enum.TextXAlignment.Center
				lb.Text=kt
				lb.Parent=isf
				_at(tt,lb,_tfl,{TextTransparency=1})
				_at(te,lb,_tfl,{TextTransparency=0})
			end
		end
		if it==Enum.ProximityPromptInputType.Touch or pr.ClickablePrompt then
			local btn=Instance.new("TextButton")
			btn.BackgroundTransparency=1
			btn.TextTransparency=1
			btn.Size=UDim2.fromScale(1,1)
			btn.Parent=bb
			bb.Active=true
			local hd=false
			btn.InputBegan:Connect(function(inp)
				if(inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseButton1)and inp.UserInputState~=Enum.UserInputState.Change then
					pr:InputHoldBegin()
					hd=true
				end
			end)
			btn.InputEnded:Connect(function(inp)
				if(inp.UserInputType==Enum.UserInputType.Touch or inp.UserInputType==Enum.UserInputType.MouseButton1)and hd then
					hd=false
					pr:InputHoldEnd()
				end
			end)
		end
		local hc,hec
		if pr.HoldDuration>0 then
			local bar=_cpb(isf)
			local bp=bar.Progress
			local ht=TweenInfo.new(pr.HoldDuration,Enum.EasingStyle.Linear,Enum.EasingDirection.Out)
			local rt=TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
			_at(ts,bp,ht,{Value=1})
			_at(th,bp,rt,{Value=0})
			hc=pr.PromptButtonHoldBegan:Connect(function()for _,t in ipairs(ts)do t:Play()end end)
			hec=pr.PromptButtonHoldEnded:Connect(function()for _,t in ipairs(th)do t:Play()end end)
		end
		local trc=pr.Triggered:Connect(function()for _,t in ipairs(tt)do t:Play()end end)
		local tec=pr.TriggerEnded:Connect(function()for _,t in ipairs(te)do t:Play()end end)
		local function _ul()
			local aw=_txs:GetTextSize(pr.ActionText,19,Enum.Font.GothamBold,Vector2.new(1000,1000)).X
			local ow=_txs:GetTextSize(pr.ObjectText,14,Enum.Font.GothamSemibold,Vector2.new(1000,1000)).X
			local mw=math.max(aw,ow)
			local ht2=(pr.ActionText~=""and pr.ActionText~=nil)or(pr.ObjectText~=""and pr.ObjectText~=nil)
			local tw=ht2 and(mw+48+12)or 42
			local oy=pr.ObjectText~=""and pr.ObjectText~=nil and 9 or 0
			al.Position=UDim2.new(0.5,48-tw/2,0,oy)
			ol.Position=UDim2.new(0.5,48-tw/2,0,-10)
			al.Text=pr.ActionText
			ol.Text=pr.ObjectText
			al.AutoLocalize=pr.AutoLocalize
			al.RootLocalizationTable=pr.RootLocalizationTable
			ol.AutoLocalize=pr.AutoLocalize
			ol.RootLocalizationTable=pr.RootLocalizationTable
			bb.Size=UDim2.fromOffset(tw,42)
			bb.SizeOffset=Vector2.new(pr.UIOffset.X/bb.Size.Width.Offset,pr.UIOffset.Y/bb.Size.Height.Offset)
		end
		local cc=pr.Changed:Connect(_ul)
		_ul()
		bb.Adornee=pr.Parent
		bb.Parent=sg
		pr:GetPropertyChangedSignal("Parent"):Connect(function()if not pr.Parent then sg:Destroy()end end)
		for _,t in ipairs(te)do t:Play()end
		return function()
			if hc then hc:Disconnect()end
			if hec then hec:Disconnect()end
			trc:Disconnect()
			tec:Disconnect()
			cc:Disconnect()
			for _,t in ipairs(tt)do t:Play()end
			task.wait(0.2)
			bb.Parent=nil
		end
	end
	for _,d in ipairs(workspace:GetDescendants())do
		if d:IsA("ProximityPrompt")then d.Style=Enum.ProximityPromptStyle.Custom end
	end
	workspace.DescendantAdded:Connect(function(o)
		if o:IsA("ProximityPrompt")then o.Style=Enum.ProximityPromptStyle.Custom end
	end)
	_pps.PromptShown:Connect(function(pr,it)
		local g=_plg:FindFirstChild("ProximityPrompts")
		if not g then
			g=Instance.new("ScreenGui")
			g.Name="ProximityPrompts"
			g.ResetOnSpawn=false
			g.Parent=_plg
		end
		local cl=_bpu(pr,it,g)
		pr.PromptHidden:Wait()
		cl()
	end)
end

do
	local _plz=game:GetService("Players")
	local _rep5=game:GetService("ReplicatedStorage")
	local _tws2=game:GetService("TweenService")
	local _rsr3=game:GetService("RunService")
	local _dbs=game:GetService("Debris")
	local _ast=_rep5.GameSettings
	local _mod=_ast.Modules
	local _lpl=_plz.LocalPlayer
	local _cfg2=require(_ast.Groups.MapConfig)
	local _hfx=require(_mod.HitFX)
	local _blh=require(_mod.BulletHandler)
	local _bn=require(_rep5.GameSettings.Modules.BridgeNet)
	local _bac=_bn.CreateBridge("BodyAnimCommand")
	local _rfi=_bn.CreateBridge("ReplicateFire")
	local _rso=_bn.CreateBridge("ReplicateSound")
	local _rhi=_bn.CreateBridge("ReplicateHit")
	local _rbo=_bn.CreateBridge("ReplicateBolt")
	local _rta=_bn.CreateBridge("ReplicateToggleAttachment")
	local _rmg=_bn.CreateBridge("ReplicateMagGrab")
	local _rln=_bn.CreateBridge("ReplicateLean")
	local _las={}
	local function _fb(p,fp,tr)
		if not p or not p.Character then return end
		local t=p.Character:FindFirstChildWhichIsA("Tool")
		if not t or not t:FindFirstChild("SPH_Weapon")then return end
		local rig=p.Character:WaitForChild("WeaponRig",10)
		if not rig then return end
		local wf=rig:FindFirstChild("Weapon")
		if not wf then return end
		local gm=wf:FindFirstChildWhichIsA("Model")
		if not gm then return end
		local ws=require(t.SPH_Weapon.WeaponStats)
		local ga=t:FindFirstChild("Ammo")
		if not ga then return end
		local sd=0
		if _cfg2.speedOfSound then
			local ch=_lpl.Character
			local rt=ch and ch:FindFirstChild("HumanoidRootPart")
			if rt then
				local rd=(rt.Position-fp.Position).Magnitude
				local mp=_cfg2.meterMultiplier or 1
				if mp>0 then
					local d=rd/mp
					local c=d/343
					if c==c and c<math.huge then sd=c end
				end
			end
		end
		_blh.FireFX(p,gm,"Muzzle",ws.muzzleChance,sd)
		if gm:FindFirstChild("Grip")then
			local mz=gm.Grip.Muzzle
			local bo=mz.WorldCFrame.Position
			local bd=mz.WorldCFrame.LookVector
			local bv=bd*ws.muzzleVelocity*_cfg2.meterMultiplier
			local tc=nil
			local _ma=ga:FindFirstChild("MagAmmo")
			if ws.tracers and _ma and _ma.Value%ws.tracerTiming==0 then tc=ws.tracerColor end
			_blh.FireBullet(rig,bo,bd,bv,t,p,tc,true)
		end
	end
	_bac:Connect(function(ch,ag)
		if not ch then return end
		local hm=ch:FindFirstChild("Humanoid")
		if not hm or hm.Health<=0 then return end
		local torso=ch:FindFirstChild("Torso")or ch:FindFirstChild("UpperTorso")
		local jt=torso and torso:FindFirstChild("Neck")
		if not jt then return end
		if typeof(ag)~="CFrame" then return end
		_tws2:Create(jt,TweenInfo.new(_cfg2.replicatedHeadRotationSpeed,Enum.EasingStyle.Quad),{C1=ag}):Play()
	end)
	_rln:Connect(function(ch,ld)
		if not ch or not ch:FindFirstChild("HumanoidRootPart")then return end
		local tc=CFrame.new(-ld/2,0,0)*CFrame.Angles(math.rad(90),math.rad(180)+math.rad(17*ld),0)
		local bj=ch.HumanoidRootPart:FindFirstChild("RootJoint")
		if bj then _tws2:Create(bj,TweenInfo.new(0.5),{C1=tc}):Play()end
	end)
	_rfi:Connect(_fb)
	_rso:Connect(function(p,s,ds)
		if not s then return end
		if not ds then s:Play()
		else
			local ch=p and p.Character
			if not ch then return end
			if not ch:FindFirstChild("Torso")and not ch:FindFirstChild("UpperTorso")then return end
			local ns=s:Clone()
			ns.Parent=s.Parent and s.Parent:IsA("BasePart")and s.Parent or ch:FindFirstChild("HumanoidRootPart")
			ns:Play()
			_dbs:AddItem(ns,math.max(ns.TimeLength,1))
		end
	end)
	_rhi:Connect(function(t,rr)
		if not t or not t:FindFirstChild("SPH_Weapon")then return end
		local bs=require(t.SPH_Weapon.WeaponStats)
		if rr.Instance and bs.projectile=="Bullet"then
			_hfx.HitEffect(rr.Position,rr.Instance,rr.Normal)
		end
	end)
	_rbo:Connect(function(p,d,ma)
		local ch=p and p.Character
		if not ch then return end
		local wr=ch:WaitForChild("WeaponRig",10)
		if not wr then return end
		local wf=wr:WaitForChild("Weapon",10)
		if not wf then return end
		local gm=wf:FindFirstChildWhichIsA("Model")
		if not gm then return end
		local t=ch:FindFirstChildWhichIsA("Tool")
		if not t then return end
		local sp=t:WaitForChild("SPH_Weapon",10)
		if not sp then return end
		local st=sp:WaitForChild("WeaponStats",10)
		if not st then return end
		local ws=require(st)
		_blh.MoveBolt(gm,{fireMoveParts=ws.fireMoveParts,fireRate=ws.fireRate,emptyLockBolt=ws.emptyLockBolt},d,ma)
	end)
	_rta:Connect(function(at,tg,ch)
		if not at then return end
		if at.Name=="Flashlight"then
			local l=at:FindFirstChildWhichIsA("Light")
			if l then l.Enabled=tg end
		elseif at.Name=="Laser"then
			if tg then
				if not at:FindFirstChild("Color")then return end
				local ld=Instance.new("Attachment",workspace.Terrain)
				ld.Name="ReplicatedLaser"
				local lu=_ast.HUD.LaserDotUI:Clone()
				lu.Enabled=true
				lu.Dot.ImageColor3=at.Color.Value
				lu.Parent=ld
				if _cfg2.laserTrail and ch:FindFirstChild("WeaponRig")then
					local wr=ch.WeaponRig
					if wr:FindFirstChild("Weapon")then
						local gm=wr.Weapon:FindFirstChildWhichIsA("Model")
						local gr=gm and gm:FindFirstChild("Grip")
						local la=gr and gr:FindFirstChild("Laser")
						if la then
							local bm=Instance.new("Beam")
							bm.Attachment0=la
							bm.Attachment1=ld
							bm.LightInfluence=0
							bm.Brightness=3
							bm.Segments=1
							bm.Width0=0.02
							bm.Width1=0.02
							bm.FaceCamera=true
							bm.Transparency=NumberSequence.new(0.5)
							bm.Name="ReplicatedLaserBeam"
							bm.Enabled=true
							bm.Color=ColorSequence.new(at.Color.Value)
							bm.Parent=ld
						end
					end
				end
				table.insert(_las,{laserDot=ld,attachment=at,ignoreModel=ch})
			else
				for i,o in ipairs(_las)do
					if o.attachment==at then o.laserDot:Destroy()table.remove(_las,i)break end
				end
			end
		end
	end)
	local _lur=1/30
	local _llu=0
	_rsr3.RenderStepped:Connect(function(dt)
		_llu+=dt
		if _llu<_lur then return end
		_llu=0
		local lp=RaycastParams.new()
		lp.FilterType=Enum.RaycastFilterType.Exclude
		local i=1
		while i<=#_las do
			local o=_las[i]
			local lpt=o.attachment
			if lpt and lpt.Parent then
				lp.FilterDescendantsInstances={o.ignoreModel}
				local dt2=o.laserDot
				local r=workspace:Raycast(lpt.WorldPosition,lpt.WorldCFrame.LookVector*600,lp)
				dt2.WorldPosition=r and r.Position or lpt.WorldPosition+lpt.WorldCFrame.LookVector*600
				i+=1
			else
				o.laserDot:Destroy()
				table.remove(_las,i)
			end
		end
	end)
	_rmg:Connect(function(mp)
		if not mp then return end
		mp.LocalTransparencyModifier=0
		for _,p in ipairs(mp:GetDescendants())do
			if p:IsA("BasePart")then p.LocalTransparencyModifier=0 end
		end
	end)
end

do
	local _tx={
		"5538771868","2953941272","4565400207","6429584813","4341732590"
	}
	local _st={Scale=0.3333333333333333,Transparency=0.9}
	local _fl={
		{Color=Color3.fromRGB(200,255,200),Radius=1,Distance=0,TextureID=1},
		{Color=Color3.fromRGB(0,255,0),Radius=0.5,Distance=0.2,TextureID=1},
		{Color=Color3.fromRGB(255,0,0),Radius=0.3,Distance=0.225,TextureID=1},
		{Color=Color3.fromRGB(255,170,0),Radius=1.5,Distance=0.25,TextureID=1},
		{Color=Color3.fromRGB(255,170,0),Radius=3,Distance=0.25,TextureID=1},
		{Color=Color3.fromRGB(0,255,0),Radius=0.5,Distance=0.3,TextureID=2},
		{Color=Color3.fromRGB(0,255,0),Radius=0.2,Distance=0.6,TextureID=2},
		{Color=Color3.fromRGB(0,255,0),Radius=0.4,Distance=0.65,TextureID=2},
		{Color=Color3.fromRGB(255,0,0),Radius=0.2,Distance=0.78,TextureID=2},
		{Color=Color3.fromRGB(0,255,0),Radius=0.25,Distance=0.9,TextureID=2},
		{Color=Color3.fromRGB(63,63,63),Radius=0.15,Distance=1.2,TextureID=2},
		{Color=Color3.fromRGB(63,63,63),Radius=0.15,Distance=1.5,TextureID=2},
	}
	local _rns=game:GetService("RunService")
	local _lts=game:GetService("Lighting")
	local _cam3=workspace.CurrentCamera
	local _fn3=_cam3:FindFirstChild("LensFlareNode")
	if _fn3 then _fn3:ClearAllChildren()
	else
		_fn3=Instance.new("Part")
		_fn3.Name="LensFlareNode"
		_fn3.Transparency=1
		_fn3.Anchored=true
		_fn3.CanCollide=false
		_fn3.Locked=true
		_fn3.Parent=_cam3
	end
	local _rp3=RaycastParams.new()
	_rp3.FilterType=Enum.RaycastFilterType.Exclude
	_rp3.FilterDescendantsInstances={_cam3}
	local function _isb(d)
		local r=workspace:Raycast(_cam3.CFrame.Position,d*10000,_rp3)
		if r then
			local p=r.Instance
			if p.Transparency+p.LocalTransparencyModifier<=0 then return true end
		end
		return false
	end
	local function _cf(d,idx)
		local sz=d.Radius*_st.Scale
		local a0=Instance.new("Attachment")
		a0.Name=idx.."_A0"
		a0.Parent=_fn3
		d.A0=a0
		local a1=Instance.new("Attachment")
		a1.Name=idx.."_A1"
		a1.Parent=_fn3
		d.A1=a1
		local bm=Instance.new("Beam")
		bm.Name=tostring(idx)
		bm.Color=ColorSequence.new(d.Color)
		bm.Width0=sz
		bm.Width1=sz
		bm.TextureSpeed=0
		bm.LightEmission=1
		bm.Texture="rbxassetid://".. _tx[d.TextureID]
		bm.Attachment0=a0
		bm.Attachment1=a1
		bm.Transparency=NumberSequence.new(_st.Transparency)
		bm.Parent=_fn3
		d.Beam=bm
	end
	for i,f in ipairs(_fl)do _cf(f,i)end
	local _scr=1/10
	local _lsc=0
	local _sb=false
	local _vps=_cam3.ViewportSize
	_cam3:GetPropertyChangedSignal("ViewportSize"):Connect(function()_vps=_cam3.ViewportSize end)
	_rns:BindToRenderStep("UpdateLensFlare",201,function(dt)
		_lsc+=dt
		local sd=_lts:GetSunDirection()
		local sp,os=_cam3:WorldToViewportPoint(sd*10000000)
		if os then
			if _lsc>=_scr then
				_lsc=0
				_sb=_isb(sd)
			end
			os=not _sb
		else
			_sb=false
			_lsc=0
		end
		local sv=Vector2.new(sp.X,sp.Y)
		local op=_vps-sv
		for i,f in ipairs(_fl)do
			local bm=f.Beam
			bm.Enabled=os
			if os then
				local r=f.Radius*_st.Scale
				local fp=op:Lerp(sv,f.Distance)
				local ry=_cam3:ViewportPointToRay(fp.X,fp.Y,1)
				local ps=ry.Origin
				local cf=CFrame.new(ps,ps-sd)
				f.A0.CFrame=cf*CFrame.new(-r/2,0,0)
				f.A1.CFrame=cf*CFrame.new(r/2,0,0)
			end
		end
	end)
end

do
	local _plfc=game.Players.LocalPlayer
	local _gid6=require(game:GetService("ReplicatedStorage").GameSettings.Groups.MapConfig).MAIN_GROUP_ID
	local _mr6=18
	local _okr6,_rk6=pcall(function() return _plfc:GetRankInGroup(_gid6) end)
	if _okr6 and _rk6>=_mr6 then
		local _pi=math.pi
		local _ab=math.abs
		local _cl=math.clamp
		local _ex=math.exp
		local _rd=math.rad
		local _sg=math.sign
		local _sq=math.sqrt
		local _tn=math.tan
		local _cas6=game:GetService("ContextActionService")
		local _pls6=game:GetService("Players")
		local _rsr6=game:GetService("RunService")
		local _stg6=game:GetService("StarterGui")
		local _uis6=game:GetService("UserInputService")
		local _ws6=game:GetService("Workspace")
		local _rep6=game:GetService("ReplicatedStorage")
		local _bn6=require(_rep6.GameSettings.Modules.BridgeNet)
		local _tfc=_bn6.CreateBridge("ToggleFreeCam")
		local _lp6=_pls6.LocalPlayer
		local _cam6=_ws6.CurrentCamera
		_ws6:GetPropertyChangedSignal("CurrentCamera"):Connect(function()if _ws6.CurrentCamera then _cam6=_ws6.CurrentCamera end end)
		local _tip=Enum.ContextActionPriority.Low.Value
		local _inp=Enum.ContextActionPriority.High.Value
		local _fmk={Enum.KeyCode.LeftShift,Enum.KeyCode.P}
		local _ng=Vector3.new(1,1,1)*64
		local _pg6=Vector2.new(0.75,1)*8
		local _fg=300
		local _pl6=_rd(90)
		local _vs=1.5
		local _ps=1.0
		local _fs=4.0
		local _Sp={}
		_Sp.__index=_Sp
		function _Sp.new(f,p)return setmetatable({f=f,p=p,v=p*0},_Sp)end
		function _Sp:Update(dt,g)
			local f=self.f*2*_pi
			local p0,v0=self.p,self.v
			local of=g-p0
			local dc=_ex(-f*dt)
			self.p=g+(v0*dt-of*(f*dt+1))*dc
			self.v=(f*dt*(of*f-v0)+v0)*dc
			return self.p
		end
		function _Sp:Reset(p)self.p=p self.v=p*0 end
		local _cp6=Vector3.new()
		local _cr6=Vector2.new()
		local _cf6=70
		local _vsp=_Sp.new(_vs,Vector3.new())
		local _psp=_Sp.new(_ps,Vector2.new())
		local _fsp=_Sp.new(_fs,0)
		local _In={}
		do
			local function _tc(x)
				local kc=2.0 local kd=0.15
				local function fc(v)return(_ex(kc*v)-1)/(_ex(kc)-1)end
				local function fd(v)return fc((v-kd)/(1-kd))end
				return _sg(x)*_cl(fd(_ab(x)),0,1)
			end
			local _gp={ButtonX=0,ButtonY=0,DPadDown=0,DPadUp=0,ButtonL2=0,ButtonR2=0,Thumbstick1=Vector2.new(),Thumbstick2=Vector2.new()}
			local _kb={W=0,A=0,S=0,D=0,E=0,Q=0,U=0,H=0,J=0,K=0,I=0,Y=0,Up=0,Down=0,LeftShift=0,RightShift=0}
			local _ms={Delta=Vector2.new(),MouseWheel=0}
			local _ngs=Vector3.new(1,1,1)
			local _nks=Vector3.new(1,1,1)
			local _pms=Vector2.new(1,1)*(_pi/64)
			local _pgs=Vector2.new(1,1)*(_pi/8)
			local _fws=1.0
			local _fgs=0.25
			local _nas=0.75
			local _nsm=0.25
			local _nsp=1
			function _In.Vel(dt)
				_nsp=_cl(_nsp+dt*(_kb.Up-_kb.Down)*_nas,0.01,4)
				local kg=Vector3.new(_tc(_gp.Thumbstick1.X),_tc(_gp.ButtonR2)-_tc(_gp.ButtonL2),_tc(-_gp.Thumbstick1.Y))*_ngs
				local kk=Vector3.new(_kb.D-_kb.A+_kb.K-_kb.H,_kb.E-_kb.Q+_kb.I-_kb.Y,_kb.S-_kb.W+_kb.J-_kb.U)*_nks
				local sh=_uis6:IsKeyDown(Enum.KeyCode.LeftShift)or _uis6:IsKeyDown(Enum.KeyCode.RightShift)
				return(kg+kk)*(_nsp*(sh and _nsm or 1))
			end
			function _In.Pan(dt)
				local kg=Vector2.new(_tc(_gp.Thumbstick2.Y),_tc(-_gp.Thumbstick2.X))*_pgs
				local km=_ms.Delta*_pms
				_ms.Delta=Vector2.new()
				return kg+km
			end
			function _In.Fov(dt)
				local kg=(_gp.ButtonX-_gp.ButtonY)*_fgs
				local km=_ms.MouseWheel*_fws
				_ms.MouseWheel=0
				return kg+km
			end
			local function _kp(_,s,i)_kb[i.KeyCode.Name]=s==Enum.UserInputState.Begin and 1 or 0 return Enum.ContextActionResult.Sink end
			local function _gb(_,s,i)_gp[i.KeyCode.Name]=s==Enum.UserInputState.Begin and 1 or 0 return Enum.ContextActionResult.Sink end
			local function _mp(_,_2,i)local d=i.Delta _ms.Delta=Vector2.new(-d.y,-d.x)return Enum.ContextActionResult.Sink end
			local function _tb(_,_2,i)_gp[i.KeyCode.Name]=i.Position return Enum.ContextActionResult.Sink end
			local function _tr(_,_2,i)_gp[i.KeyCode.Name]=i.Position.z return Enum.ContextActionResult.Sink end
			local function _mw(_,_2,i)_ms[i.UserInputType.Name]=-i.Position.z return Enum.ContextActionResult.Sink end
			local function _zo(t)for k,v in pairs(t)do t[k]=v*0 end end
			function _In.StartCapture()
				_cas6:BindActionAtPriority("FreecamKeyboard",_kp,false,_inp,Enum.KeyCode.W,Enum.KeyCode.U,Enum.KeyCode.A,Enum.KeyCode.H,Enum.KeyCode.S,Enum.KeyCode.J,Enum.KeyCode.D,Enum.KeyCode.K,Enum.KeyCode.E,Enum.KeyCode.I,Enum.KeyCode.Q,Enum.KeyCode.Y,Enum.KeyCode.Up,Enum.KeyCode.Down)
				_cas6:BindActionAtPriority("FreecamMousePan",_mp,false,_inp,Enum.UserInputType.MouseMovement)
				_cas6:BindActionAtPriority("FreecamMouseWheel",_mw,false,_inp,Enum.UserInputType.MouseWheel)
				_cas6:BindActionAtPriority("FreecamGamepadButton",_gb,false,_inp,Enum.KeyCode.ButtonX,Enum.KeyCode.ButtonY)
				_cas6:BindActionAtPriority("FreecamGamepadTrigger",_tr,false,_inp,Enum.KeyCode.ButtonR2,Enum.KeyCode.ButtonL2)
				_cas6:BindActionAtPriority("FreecamGamepadThumbstick",_tb,false,_inp,Enum.KeyCode.Thumbstick1,Enum.KeyCode.Thumbstick2)
			end
			function _In.StopCapture()
				_nsp=1
				_zo(_gp)_zo(_kb)_zo(_ms)
				_cas6:UnbindAction("FreecamKeyboard")
				_cas6:UnbindAction("FreecamMousePan")
				_cas6:UnbindAction("FreecamMouseWheel")
				_cas6:UnbindAction("FreecamGamepadButton")
				_cas6:UnbindAction("FreecamGamepadTrigger")
				_cas6:UnbindAction("FreecamGamepadThumbstick")
			end
		end
		local function _gfd(cf)
			local zn=0.1
			local vp=_cam6.ViewportSize
			local py=2*_tn(_cf6/2)
			local px=vp.x/vp.y*py
			local fx=cf.rightVector local fy=cf.upVector local fz=cf.lookVector
			local md=512 local mv=Vector3.new()
			for x=0,1,0.5 do for y=0,1,0.5 do
					local cx=(x-0.5)*px local cy=(y-0.5)*py
					local of=fx*cx-fy*cy+fz
					local og=cf.p+of*zn
					local rr=workspace:Raycast(og,of.unit*md)
					local h=rr and rr.Position or og+of.unit*md
					local ds=(h-og).Magnitude
					if md>ds then md=ds mv=of.unit end
				end end
			return fz:Dot(mv)*md
		end
		local function _sfc(dt)
			local v=_vsp:Update(dt,_In.Vel(dt))
			local p=_psp:Update(dt,_In.Pan(dt))
			local f=_fsp:Update(dt,_In.Fov(dt))
			local zf=_sq(_tn(_rd(70/2))/_tn(_rd(_cf6/2)))
			_cf6=_cl(_cf6+f*_fg*(dt/zf),1,120)
			_cr6=_cr6+p*_pg6*(dt/zf)
			_cr6=Vector2.new(_cl(_cr6.x,-_pl6,_pl6),_cr6.y%(2*_pi))
			local cc=CFrame.new(_cp6)*CFrame.fromOrientation(_cr6.x,_cr6.y,0)*CFrame.new(v*_ng*dt)
			_cp6=cc.p
			_cam6.CFrame=cc
			_cam6.Focus=cc*CFrame.new(0,0,-_gfd(cc))
			_cam6.FieldOfView=_cf6
		end
		local _PS={}
		do
			local _mb,_mi,_ct2,_cf2,_cc2,_cfv
			local _sg2={}
			local _cg={Backpack=true,Chat=true,Health=true,PlayerList=true}
			local _sc={BadgesNotificationsActive=true,PointsNotificationsActive=true}
			function _PS.Push()
				for n in pairs(_cg)do _cg[n]=_stg6:GetCoreGuiEnabled(Enum.CoreGuiType[n])_stg6:SetCoreGuiEnabled(Enum.CoreGuiType[n],false)end
				for n in pairs(_sc)do _sc[n]=_stg6:GetCore(n)_stg6:SetCore(n,false)end
				local pg=_lp6:FindFirstChildOfClass("PlayerGui")
				if pg then for _,g in ipairs(pg:GetChildren())do if g:IsA("ScreenGui")and g.Enabled then table.insert(_sg2,g)g.Enabled=false end end end
				_cfv=_cam6.FieldOfView _cam6.FieldOfView=70
				_ct2=_cam6.CameraType _cam6.CameraType=Enum.CameraType.Custom
				_cc2=_cam6.CFrame _cf2=_cam6.Focus
				_mi=_uis6.MouseIconEnabled _uis6.MouseIconEnabled=false
				_mb=_uis6.MouseBehavior _uis6.MouseBehavior=Enum.MouseBehavior.Default
			end
			function _PS.Pop()
				for n,v in pairs(_cg)do _stg6:SetCoreGuiEnabled(Enum.CoreGuiType[n],v)end
				for n,v in pairs(_sc)do _stg6:SetCore(n,v)end
				for _,g in ipairs(_sg2)do if g.Parent then g.Enabled=true end end
				table.clear(_sg2)
				_cam6.FieldOfView=_cfv _cam6.CameraType=_ct2 _cam6.CFrame=_cc2 _cam6.Focus=_cf2
				_uis6.MouseIconEnabled=_mi _uis6.MouseBehavior=_mb
			end
		end
		local function _stf()
			local cf=_cam6.CFrame
			_cr6=Vector2.new(cf:toEulerAnglesYXZ())
			_cp6=cf.p
			_cf6=_cam6.FieldOfView
			_vsp:Reset(Vector3.new())
			_psp:Reset(Vector2.new())
			_fsp:Reset(0)
			_PS.Push()
			_rsr6:BindToRenderStep("Freecam",Enum.RenderPriority.Camera.Value,_sfc)
			_In.StartCapture()
		end
		local function _spf()
			_In.StopCapture()
			_rsr6:UnbindFromRenderStep("Freecam")
			_PS.Pop()
		end
		do
			local _en=false
			local function _tf()_tfc:Fire()end
			_tfc:Connect(function(ns)
				if ns then _stf()else _spf()end
				_en=ns
			end)
			local function _cm(m)
				for i=1,#m-1 do if not _uis6:IsKeyDown(m[i])then return end end
				_tf()
			end
			local function _hai(_,s,i)
				if s==Enum.UserInputState.Begin then
					if i.KeyCode==_fmk[#_fmk]then _cm(_fmk)end
				end
				return Enum.ContextActionResult.Pass
			end
			_cas6:BindActionAtPriority("FreecamToggle",_hai,false,_tip,_fmk[#_fmk])
		end
	end
end

do
	if not game:IsLoaded()then game.Loaded:Wait()end
	local _rep7=game:GetService("ReplicatedStorage")
	local _pls7=game:GetService("Players")
	local _cam7=workspace.CurrentCamera
	local _pi7=require(_rep7.GameSettings.Modules.PoolInstance)
	local _ch7=require(_rep7.GameSettings.Modules.Charm)
	local _tr7=require(_rep7.GameSettings.Modules.Trove)
	local _db7=require(_rep7.GameSettings.Modules.Debounce)
	local _at7=_ch7.atom
	local _ef7=script:FindFirstChild("Effects")
	if not _ef7 then

		return
	end
	local _ve7=_ef7.Visuals
	local _ae7=_ef7.Auditories
	local _sp7=_pi7(_ve7.Splash,30)
	local _cpc=_cam7.CFrame.Position
	local _ccr=1/30
	local _lcc=0
	local function _pse(p)
		local s=_sp7.Get()
		local sn=s.Sound
		local pt=s.Particle
		local lt=math.max(pt.Lifetime.Max+5,sn.TimeLength+2)
		task.delay(lt,function()_sp7.Done(s)end)
		s.Parent=workspace.Terrain
		s.WorldPosition=p
		sn:Play()
		pt:Emit(5)
	end
	local function _sfs(rp)
		local ss={}
		for _,st in ipairs(_ae7.Footsteps:GetChildren())do
			local s=st:Clone()
			s.Parent=rp
			s.Looped=false
			ss[string.lower(s.Name)]={sound=s,volumeOffset=s:GetAttribute("plus")}
		end
		return ss
	end
	local function _sls(rp)
		local ls={}
		for _,st in ipairs(_ae7.Land:GetChildren())do
			local s=st:Clone()
			s.Parent=rp
			table.insert(ls,s)
		end
		return{sounds=ls,playRandom=function()ls[math.random(1,#ls)]:Play()end}
	end
	local function _cnp(p,d)
		local pp=p.Position
		local sz=p.Size
		local cp=_cpc
		local dq=d*d
		if sz.X+sz.Y+sz.Z<=16 then return(cp-pp).Magnitude^2<=dq end
		local h=sz/2
		local of={
			Vector3.new(h.X,h.Y,h.Z),Vector3.new(-h.X,h.Y,h.Z),
			Vector3.new(h.X,h.Y,-h.Z),Vector3.new(-h.X,h.Y,-h.Z),
			Vector3.new(h.X,-h.Y,h.Z),Vector3.new(-h.X,-h.Y,h.Z),
			Vector3.new(h.X,-h.Y,-h.Z),Vector3.new(-h.X,-h.Y,-h.Z),
		}
		for _,o in ipairs(of)do if(cp-(pp+o)).Magnitude^2<=dq then return true end end
		return(cp-pp).Magnitude^2<=dq
	end
	local function _sc7(ch)
		local rp=ch:WaitForChild("HumanoidRootPart",10)
		local to=ch:WaitForChild("Torso",1)
		local ll=ch:WaitForChild("Left Leg",1)
		local rl=ch:WaitForChild("Right Leg",1)
		local hm=ch:FindFirstChildOfClass("Humanoid")
		if not hm then return end
		local tr=_tr7.new()
		local st={
			jumping=_at7(false),walking=_at7(false),
			seated=_at7(false),died=_at7(false),
			hipHeight=_at7(0),jumpHeight=_at7(0),
		}
		local fs=_sfs(rp)
		local ls=_sls(rp)
		local function _uh()
			local lh=math.max(ll and ll.Size.Y or 0,rl and rl.Size.Y or 0)
			local bh=math.max(rp and rp.Size.Y or 0,to and to.Size.Y or 0)
			st.hipHeight(lh+bh*0.5+hm.HipHeight)
		end
		local function _uj()st.jumpHeight(hm.JumpPower^2/(2*workspace.Gravity))end
		_uj()_uh()
		tr:Add(workspace:GetPropertyChangedSignal("Gravity"):Connect(_uj))
		tr:Add(hm:GetPropertyChangedSignal("JumpPower"):Connect(_uj))
		if rp then tr:Add(rp:GetPropertyChangedSignal("Size"):Connect(_uh))end
		if ll then tr:Add(ll:GetPropertyChangedSignal("Size"):Connect(_uh))end
		local _sd=_db7.new(0.1)
		local _rp7=RaycastParams.new()
		_rp7.FilterDescendantsInstances={ch,_cam7}
		_rp7.FilterType=Enum.RaycastFilterType.Exclude
		tr:Add(hm.StateChanged:Connect(function(_,ns)
			if ns==Enum.HumanoidStateType.Swimming then
				if not rp or not rp.Parent then return end
				if math.abs(rp.AssemblyLinearVelocity.Y)>0.1 and _sd.is_allowed()and _cnp(rp,275)then
					local og=rp.Position+Vector3.new(0,10,0)
					local r=workspace:Raycast(og,Vector3.new(0,-20,0),_rp7)
					if r and r.Instance:IsA("Terrain")and r.Instance.Material==Enum.Material.Plastic then
						_pse(r.Position)
					end
				end
			end
		end))
		tr:Add(hm.StateChanged:Connect(function(o,n)
			if o==Enum.HumanoidStateType.Freefall and n==Enum.HumanoidStateType.Landed then
				ls.playRandom()
			end
		end))
		local spd=0
		tr:Add(hm.Running:Connect(function(v)spd=v st.walking(v>0)end))
		tr:Add(hm.Died:Connect(function()st.died(true)end))
		tr:Add(ch.Destroying:Connect(function()st.died(true)end))
		tr:Add(_ch7.subscribe(st.died,function(v)if v then tr:Destroy()end end))
		local _fm=10
		local _fa=0
		while hm and rp and not st.died()do
			if spd>_fm and st.walking()and not st.jumping()and not st.seated()and _cnp(rp,75)then
				local r=workspace:Raycast(rp.Position,Vector3.new(0,-st.hipHeight()*1.25,0),_rp7)
				if r and r.Material~=Enum.Material.Air then
					local k=(r.Material==Enum.Material.Sand or r.Material==Enum.Material.Grass)and"soft"or"hard"
					local sd2=fs[k]
					local s=sd2.sound
					s.PlaybackSpeed=math.random(9,11)*0.1
					s.Volume=math.clamp(spd/12,0,2)/2+sd2.volumeOffset
					s:Play()
					task.wait(6/spd)
				end
			end
			task.wait(0.05)
		end
	end
	local _rsr7=game:GetService("RunService")
	_rsr7.Heartbeat:Connect(function(dt)
		_lcc+=dt
		if _lcc>=_ccr then _lcc=0 _cpc=_cam7.CFrame.Position end
	end)
	require(_rep7.GameSettings.Modules.safePlayerAdded)(function(p)
		local ini=false
		p.CharacterAdded:Connect(function(ch)
			ini=true
			local hm=ch:WaitForChild("Humanoid",5)
			task.wait(1)
			if hm and hm.Parent then _sc7(ch)end
		end)
		if p.Character and p.Character:FindFirstChild("Humanoid")and not ini then
			_sc7(p.Character)
		end
	end)
end

do
	local _cas8=game:GetService("ContextActionService")
	local _rep8=game:GetService("ReplicatedStorage").GameSettings
	local _pls8=game:GetService("Players")
	local _db8=game:GetService("Debris")
	local _an8={}
	local function _oca8(ch)
		local hm=ch:WaitForChild("Humanoid",10)
		if not hm then return end
		ch:SetAttribute("SpeedBoot",false)
		hm.WalkSpeed=16
		local _amt8=hm:FindFirstChildOfClass("Animator")or Instance.new("Animator",hm)
		local ia=_amt8:LoadAnimation(_rep8.Assets.DrinkIdle)
		ia.Priority=Enum.AnimationPriority.Action2
		ia.Looped=true
		local da=_amt8:LoadAnimation(_rep8.Assets.DrinkEat)
		da.Priority=Enum.AnimationPriority.Action3
		da.Looped=false
		_an8.Idle=ia
		_an8.Drink=da
	end
	_cas8.LocalToolEquipped:Connect(function(t)
		if not t:HasTag("Drink")then return end
		if not _an8.Idle then return end
		_an8.Idle:Play()
		t.Handle.OpenSound.Volume=1
		t.Handle.OpenSound:Play()
		if t:GetAttribute("Connected")then return end
		t:SetAttribute("Connected",true)
		t.Activated:Once(function()
			local s=t.Handle.DrinkSound:Clone()
			s.Parent=_pls8.LocalPlayer.Character.PrimaryPart
			s.Volume=1
			s:Play()
			_db8:AddItem(s,5)
			if _an8.Drink then _an8.Drink:Play()end
			task.delay(0.5,function()
				local dt=t:GetAttribute("Type")
				local ch=_pls8.LocalPlayer.Character
				local hm=ch and ch:FindFirstChild("Humanoid")
				if hm then
					local function _sb(d)
						_rep8.Events.DataDrinking:FireServer("คุณได้รับบูสต์ความเร็วแล้วเป็นเวลา "..d)
						hm.Parent:SetAttribute("SpeedBoot",true)
						hm.WalkSpeed=27
						local c
						c=hm.Died:Connect(function()
							hm.Parent:SetAttribute("SpeedBoot",nil)
							hm.WalkSpeed=16
							c:Disconnect()
						end)
						return c
					end
					if dt==5 then
						local c=_sb("15 วินาที")
						task.delay(15,function()if hm.Health>0 then hm.WalkSpeed=16 hm.Parent:SetAttribute("SpeedBoot",nil)end if c then c:Disconnect()end end)
					elseif dt==6 then
						local c=_sb("30 วินาที")
						task.delay(30,function()if hm.Health>0 then hm.WalkSpeed=16 hm.Parent:SetAttribute("SpeedBoot",nil)end if c then c:Disconnect()end end)
					elseif dt==7 then
						local c=_sb("1 นาที")
						task.delay(60,function()if hm.Health>0 then hm.WalkSpeed=16 hm.Parent:SetAttribute("SpeedBoot",nil)end if c then c:Disconnect()end end)
					end
				end
				hm:UnequipTools()
				task.wait()
				t:Destroy()
			end)
		end)
	end)
	_cas8.LocalToolUnequipped:Connect(function(t)
		if t:HasTag("Drink")and _an8.Idle then _an8.Idle:Stop()end
	end)
	if _pls8.LocalPlayer.Character then _oca8(_pls8.LocalPlayer.Character)end
	_pls8.LocalPlayer.CharacterAdded:Connect(_oca8)
end

do
	local _pls9=game:GetService("Players")
	local _rsr9=game:GetService("RunService")
	local _rep9=game:GetService("ReplicatedStorage")
	local _pl9=_pls9.LocalPlayer
	local _ev9=_rep9:WaitForChild("GameSettings"):WaitForChild("Events")
	local _re9=_ev9:WaitForChild("ArrestEvent")
	local _rf9=_ev9:WaitForChild("ArrestFunction")
	local _tn9="กุญแจมือ"
	local _rs9=15*15
	local _us9=false
	local _eq9=false
	local _dc9=nil
	local _cp9={}
	local _ht9={}
	local _bk9=_pl9:WaitForChild("Backpack")
	local function _gt9()
		if _pl9.Character then
			local t=_pl9.Character:FindFirstChild(_tn9)
			if t then return t end
		end
		return _bk9:FindFirstChild(_tn9)
	end
	local function _dp9(uid)
		local c=_cp9[uid]
		if c then c:Disconnect()_cp9[uid]=nil end
	end
	local function _cnp9(op,pr,rp)
		local uid=op.UserId
		if _cp9[uid]then return end
		_cp9[uid]=pr.Triggered:Connect(function()
			if not _us9 and _eq9 and _gt9()then
				if rp and rp.Parent then _re9:FireServer("Detain",rp)end
			end
		end)
	end
	local function _sap(s)
		for _,o in ipairs(_pls9:GetPlayers())do
			if o~=_pl9 and o.Character then
				local r=o.Character:FindFirstChild("HumanoidRootPart")or o.Character.PrimaryPart
				if r then
					local p=r:FindFirstChild("ArrestPrompt_"..o.UserId)
					if p then p.Enabled=s end
				end
			end
		end
	end
	local _ld9=0
	local _dr9=1/20
	local function _upd()
		if not _eq9 or _us9 then return end
		local ch=_pl9.Character
		if not ch then return end
		local pr=ch:FindFirstChild("HumanoidRootPart")
		if not pr then return end
		local mp=pr.Position
		for _,o in ipairs(_pls9:GetPlayers())do
			if o~=_pl9 and o.Character then
				local or2=o.Character:FindFirstChild("HumanoidRootPart")or o.Character.PrimaryPart
				if or2 then
					local pr2=or2:FindFirstChild("ArrestPrompt_"..o.UserId)
					if pr2 then
						local ir=(mp-or2.Position).Magnitude^2<=_rs9
						pr2.Enabled=ir
						if ir then _cnp9(o,pr2,or2)else _dp9(o.UserId)end
					end
				end
			end
		end
	end
	local function _sdc()
		if _dc9 then _dc9:Disconnect()end
		_dc9=_rsr9.Heartbeat:Connect(function(dt)
			_ld9+=dt
			if _ld9<_dr9 then return end
			_ld9=0
			_upd()
		end)
	end
	local function _stdc()
		if _dc9 then _dc9:Disconnect()_dc9=nil end
		for uid in pairs(_cp9)do _dp9(uid)end
		_sap(false)
		_ld9=0
	end
	local function _rtn()
		if _us9 then _re9:FireServer("Release")end
		_us9=false
		if _eq9 then _sdc()end
	end
	local function _hkt(t)
		if _ht9[t]then return end
		_ht9[t]=true
		t.Equipped:Connect(function()
			_eq9=true
			task.wait(0.1)
			_upd()
			_sdc()
		end)
		t.Unequipped:Connect(function()
			_rtn()
			_eq9=false
			_stdc()
		end)
	end
	local function _sat()
		if _pl9.Character then
			local t=_pl9.Character:FindFirstChild(_tn9)
			if t and not _ht9[t]then _hkt(t)end
		end
		local t=_bk9:FindFirstChild(_tn9)
		if t and not _ht9[t]then _hkt(t)end
	end
	local function _hkch(ch)
		_us9=false _eq9=false _ht9={}
		local t=ch:FindFirstChild(_tn9)
		if t then _hkt(t)end
		ch.ChildAdded:Connect(function(c)
			if c.Name==_tn9 and c:IsA("Tool")and not _ht9[c]then _hkt(c)end
		end)
		ch:WaitForChild("Humanoid").Died:Connect(function()
			_rtn()_eq9=false _stdc()
		end)
	end
	_bk9.ChildAdded:Connect(function(c)
		if c.Name==_tn9 and c:IsA("Tool")and not _ht9[c]then _hkt(c)end
	end)
	_pl9.CharacterAdded:Connect(function(ch)
		task.wait(0.1)
		_hkch(ch)
		_sat()
	end)
	if _pl9.Character then _hkch(_pl9.Character)end
	_sat()
	_re9.OnClientEvent:Connect(function(s)
		if s=="Using"then
			_us9=true
			_stdc()
			local d=_rf9:InvokeServer()
			if not d then _us9=false if _eq9 then _sdc()end end
		elseif s=="JailSuccess"or s=="DetainFailed"then
			_us9=false
			if _eq9 then _sdc()end
		end
	end)
	_pls9.PlayerRemoving:Connect(function(o)_dp9(o.UserId)end)
	_pls9.PlayerAdded:Connect(function(o)o.CharacterAdded:Connect(function()_dp9(o.UserId)end)end)
	for _,o in ipairs(_pls9:GetPlayers())do o.CharacterAdded:Connect(function()_dp9(o.UserId)end)end
	_pl9:GetPropertyChangedSignal("Team"):Connect(function()if _eq9 and not _us9 then _upd()end end)
end

do
	local _pls0=game:GetService("Players")
	local _tws0=game:GetService("TweenService")
	local _rep0=game:GetService("ReplicatedStorage")
	local _ss0=game:GetService("SoundService")
	local _rsr0=game:GetService("RunService")
	local _pl0=_pls0.LocalPlayer
	local _pg0=_pl0:WaitForChild("PlayerGui")
	if not _G.AnncSystemRunning then
		_G.AnncSystemRunning=true
		local _gu0=nil
		local _ff0=nil
		local _tc0=nil
		local _arf=nil
		local _cpi={}
		local _aa={
			riot={active=false,endTime=0,frame=nil},
			nuke={active=false,endTime=0,frame=nil},
			robbery={active=false,frame=nil},
		}
		local _re0=_rep0.GameSettings.Events:WaitForChild("RiotEndAnnouncer")
		local _ne0=_rep0.GameSettings.Events:WaitForChild("NukeEvent")
		local _rb0=_rep0.GameSettings.Events:WaitForChild("BankRobberyAnnouncer")
		local _cr0=_rep0.GameSettings:WaitForChild("CurrentRiot")
		local _sd0=_ss0:WaitForChild("Annc"):WaitForChild("Annc")
		local _ti=TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
		local _to=TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.In)
		local function _hms(s)
			local h=math.floor(s/3600)
			local m=math.floor((s%3600)/60)
			local sc=s%60
			if h>0 then return string.format("%02i:%02i:%02i",h,m,sc)end
			return string.format("%02i:%02i",m,sc)
		end
		local function _ca0()
			for _,d in pairs(_aa)do
				if d.frame and d.frame.Parent then d.frame:Destroy()end
				d.frame=nil d.active=false
				if d.endTime then d.endTime=0 end
			end
			if _arf and _arf.Parent then _arf:Destroy()end
			_arf=nil
			if _ff0 and _ff0.Parent then _ff0:Destroy()end
			_ff0=nil
			if _tc0 then _tc0:Disconnect()_tc0=nil end
		end
		local function _ig0()
			_gu0=_pg0:WaitForChild("AnncGui")
			if not _ff0 or not _ff0.Parent then
				_ff0=Instance.new("Frame")
				_ff0.Name="flashFrame"
				_ff0.Size=UDim2.new(1,0,1,0)
				_ff0.BackgroundColor3=Color3.fromRGB(255,255,255)
				_ff0.BackgroundTransparency=1
				_ff0.BorderSizePixel=0
				_ff0.ZIndex=10
				_ff0.Parent=_gu0
			end
			if _gu0.Annc then _gu0.Annc.Visible=false end
			if _gu0.AnncBank then _gu0.AnncBank.Visible=false end
		end
		local function _ps0()if not _sd0.IsPlaying then _sd0:Play()end end
		local function _ss0f()
			for _,d in pairs(_aa)do if d.active then return end end
			if _sd0.IsPlaying then _sd0:Stop()end
		end
		local function _tfi(f,tp)
			f.Position=UDim2.new(tp.X.Scale,tp.X.Offset,-0.2,0)
			f.Visible=true
			_tws0:Create(f,_ti,{Position=tp}):Play()
		end
		local function _tfo(f,cb)
			local t=_tws0:Create(f,_to,{Position=UDim2.new(f.Position.X.Scale,f.Position.X.Offset,-0.2,0)})
			t.Completed:Once(function()if cb then cb()end end)
			t:Play()
		end
		local _p1={0.5} local _p2={0.3,0.7} local _p3={0.2,0.5,0.8}
		local _yp=0.097
		local function _gaf()
			local l={}
			if _aa.riot.active and _aa.riot.frame then table.insert(l,_aa.riot.frame)end
			if _aa.nuke.active and _aa.nuke.frame then table.insert(l,_aa.nuke.frame)end
			if _aa.robbery.active and _aa.robbery.frame then table.insert(l,_aa.robbery.frame)end
			return l
		end
		local function _up0(an)
			local f=_gaf()
			local n=#f
			if n==0 then return end
			local xl=n==1 and _p1 or n==2 and _p2 or _p3
			for i,fr in ipairs(f)do
				local xs=xl[i]or 0.5
				local tg=UDim2.new(xs,0,_yp,0)
				if an then _tws0:Create(fr,_ti,{Position=tg}):Play()
				else fr.Position=tg end
			end
		end
		local showRiot
		local showNuke
		local function _stu()
			if _tc0 then return end
			_tc0=_rsr0.Heartbeat:Connect(function()
				local ha=false
				local nw=os.time()
				for _,d in pairs(_aa)do
					if d.active then
						ha=true
						if d.endTime and d.endTime>0 and d.frame and d.frame.Parent then
							local tm=d.frame:FindFirstChild("Timer")
							if tm then tm.Text=_hms(math.max(0,d.endTime-nw))end
						end
					end
				end
				if not ha then _tc0:Disconnect()_tc0=nil end
			end)
		end
		local function _axm(tp,uid)
			local tp2=_pls0:GetPlayerByUserId(uid)
			local sx=not tp2 or not tp2:GetAttribute("WantedBank")
			local ex=tp:FindFirstChild("XMark")
			if sx then
				if not ex then
					local x=Instance.new("TextLabel")
					x.Name="XMark"
					x.Size=UDim2.new(1,0,1,0)
					x.BackgroundTransparency=1
					x.Text="✖"
					x.TextColor3=Color3.fromRGB(255,0,0)
					x.TextScaled=true
					x.Font=Enum.Font.GothamBold
					x.ZIndex=10
					x.Parent=tp
				end
			else if ex then ex:Destroy()end end
		end
		local function _cpa(ac,pids)
			local ts={}
			for _,c in ipairs(ac:GetChildren())do
				if c.Name=="AvatarTemplat"then
					c.Visible=false
					local x=c:FindFirstChild("XMark")
					if x then x:Destroy()end
					table.insert(ts,c)
				end
			end
			_cpi=pids
			local ct=math.min(5,#pids)
			for i=1,ct do
				local t=ts[i]
				if not t then break end
				local uid=pids[i]
				t.Image="https://www.roblox.com/headshot-thumbnail/image?userId="..uid.."&width=150&height=150&format=png"
				t.Visible=true
				t:SetAttribute("UserId",uid)
				_axm(t,uid)
			end
		end
		local showRobbery
		local function _uas()
			if not _arf then return end
			local ac=_arf:FindFirstChild("Avatar")
			if not ac then return end
			for _,t in ipairs(ac:GetChildren())do
				if t.Name=="AvatarTemplat"and t.Visible then
					local uid=t:GetAttribute("UserId")
					if uid then _axm(t,uid)end
				end
			end
			local tot,dd=0,0
			local ac2=_arf:FindFirstChild("Avatar")
			if ac2 then
				for _,t in ipairs(ac2:GetChildren())do
					if t.Name=="AvatarTemplat"and t.Visible then
						tot+=1
						if t:FindFirstChild("XMark")then dd+=1 end
					end
				end
			end
			if tot>0 and tot==dd then showRobbery(false,{})end
		end
		local function _mps()
			for _,p in ipairs(_pls0:GetPlayers())do
				p:GetAttributeChangedSignal("WantedBank"):Connect(_uas)
			end
			_pls0.PlayerAdded:Connect(function(p)p:GetAttributeChangedSignal("WantedBank"):Connect(_uas)end)
			_pls0.PlayerRemoving:Connect(function()task.wait(0.5)_uas()end)
		end
		showRobbery=function(ia,pids)
			if ia then
				if _arf and _arf.Parent then
					local ac=_arf:FindFirstChild("Avatar")
					if ac then _cpa(ac,pids)_uas()end
					_up0(true)
					return
				end
				_aa.robbery.active=true
				local f=_gu0.AnncBank:Clone()
				f.Name="RobberyAnnc"
				f.Parent=_gu0
				_arf=f
				_aa.robbery.frame=f
				f.Title.Text="ปล้นธนาคาร!"
				f.Desc.Text="มีกลุ่มคนกำลังปล้นธนาคาร"
				f.Visible=true
				if pids and #pids>0 then
					local ac=f:FindFirstChild("Avatar")
					if ac then _cpa(ac,pids)end
				end
				local fs=_gaf()
				local n=#fs
				local xl=n==1 and _p1 or n==2 and _p2 or _p3
				local mi=n
				local sx=xl[mi]or 0.5
				f.Position=UDim2.new(sx,0,-0.2,0)
				_up0(false)
				_tws0:Create(f,_ti,{Position=UDim2.new(xl[mi]or 0.5,0,_yp,0)}):Play()
				_ps0()
				task.spawn(function()
					while _aa.robbery.active do task.wait(0.5)_uas()end
				end)
			else
				_aa.robbery.active=false
				if _arf then _arf:Destroy()_arf=nil end
				_aa.robbery.frame=nil
				_cpi={}
				_up0(false)
				_ss0f()
			end
		end
		showRiot=function(ia,et)
			if ia then
				if _aa.riot.frame then return end
				_aa.riot.active=true _aa.riot.endTime=et
				local f=_gu0.Annc:Clone()
				f.Name="RiotAnnc"
				f.Parent=_gu0
				_aa.riot.frame=f
				f.Title.Text="เหตุจลาจล"
				f.Desc.Text="ขณะนี้มีการจลาจลเกิดขึ้น"
				f.Timer.Text=_hms(math.max(0,et-os.time()))
				_tfi(f,UDim2.new(0.5,0,_yp,0))
				task.defer(function()_up0(true)end)
				_ps0()
				_stu()
			else
				_aa.riot.active=false _aa.riot.endTime=0
				local f=_aa.riot.frame _aa.riot.frame=nil
				if f then _tfo(f,function()f:Destroy()end)end
				task.defer(function()_up0(true)_ss0f()end)
			end
		end
		showNuke=function(ia,rt)
			if ia then
				if _aa.nuke.frame then return end
				_aa.nuke.active=true _aa.nuke.endTime=os.time()+math.floor(rt or 75)
				local f=_gu0.Annc:Clone()
				f.Name="NukeAnnc"
				f.Parent=_gu0
				_aa.nuke.frame=f
				f.Title.Text="นิวเคลียร์"
				f.Desc.Text="นิวเคลียร์ถูกยิงแล้ว รีบไปยังบังเกอร์!"
				f.Timer.Text=_hms(rt or 75)
				_tfi(f,UDim2.new(0.5,0,_yp,0))
				task.defer(function()_up0(true)end)
				_ps0()
				_stu()
			else
				_aa.nuke.active=false _aa.nuke.endTime=0
				local f=_aa.nuke.frame _aa.nuke.frame=nil
				if f then _tfo(f,function()f:Destroy()end)end
				task.defer(function()
					_up0(true)
					_ss0.Explode.Explode:Play()
					if _ff0 then
						_ff0.BackgroundTransparency=0
						task.wait(0.1)
						_tws0:Create(_ff0,TweenInfo.new(14,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=1}):Play()
					end
					_ss0f()
				end)
			end
		end
		_pl0.CharacterAdded:Connect(function(ch)
			ch:WaitForChild("Humanoid")
			task.wait(0.5)
			_ig0()
		end)
		_ig0()
		_re0.OnClientEvent:Connect(showRiot)
		_ne0.OnClientEvent:Connect(showNuke)
		_rb0.OnClientEvent:Connect(showRobbery)
		_mps()
		if _cr0.Value~=0 then showRiot(true,_cr0.Value)end
		_gu0.Annc.Visible=false
		_gu0.AnncBank.Visible=false
	end
end

do
	repeat task.wait(0.5)until game.Players.LocalPlayer:FindFirstChild("leaderstats")
	repeat task.wait(0.5)until game.Players.LocalPlayer.leaderstats:FindFirstChild("เงิน")and game.Players.LocalPlayer.leaderstats:FindFirstChild("เลเวล")
	repeat task.wait(0.5)until game.Players.LocalPlayer:FindFirstChild("Data")
	repeat task.wait(0.5)until game.Players.LocalPlayer.Data:FindFirstChild("Exp")and game.Players.LocalPlayer.Data:FindFirstChild("ExpNeed")
	local _pls5=game:GetService("Players")
	local _soc=game:GetService("SocialService")
	local _rep5d=game:GetService("ReplicatedStorage")
	local _uis5=game:GetService("UserInputService")
	local _tb=require(_rep5d.GameSettings.Modules.Icon)
	local _bp=require(_rep5d.GameSettings.Modules.Backpack)
	local _pl5=_pls5.LocalPlayer
	local _cs=_tb.new()
	local _lv=_tb.new()
	local _an=_tb.new()
	local _fr=_tb.new()
	local _ave=_rep5d:WaitForChild("GameSettings"):WaitForChild("Events"):WaitForChild("ArmorVisibility")
	local function _fm5(n)
		if n>=1e9 then return string.format("%.2fB",n/1e9)
		elseif n>=1e6 then return string.format("%.2fM",n/1e6)
		elseif n>=1e3 then return string.format("%.2fK",n/1e3)
		else return tostring(n)end
	end
	local function _fm5b(n)
		local s=tostring(n)
		local b=s:match("^-?%d+")
		return b:reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","").." ฿"
	end
	local function _obp()pcall(_soc.PromptGameInvite,_soc,_pl5)end
	local function _isp()local t=_pl5.Team return t and t.Name== _TC.PRISONER_TEAM end
	local function _uc()
		_cs:setLabel(_fm5(_pl5.leaderstats["เงิน"].Value))
		_cs:setCaption(_fm5b(_pl5.leaderstats["เงิน"].Value))
	end
	local function _ul5()_lv:setLabel("เลเวล ".._pl5.leaderstats["เลเวล"].Value)end
	_pl5.leaderstats["เงิน"]:GetPropertyChangedSignal("Value"):Connect(_uc)
	_pl5.leaderstats["เลเวล"]:GetPropertyChangedSignal("Value"):Connect(_ul5)
	local _exp5=_pl5.Data:WaitForChild("Exp")
	local _expn5=_pl5.Data:WaitForChild("ExpNeed")
	_exp5:GetPropertyChangedSignal("Value"):Connect(function()
		_lv:setCaption(_exp5.Value.." / ".._expn5.Value)
	end)
	_uc()_ul5()
	_cs:setImage(95459240442938)_cs:oneClick(true)_cs:align("Right")
	_lv:setImage(93136954756149)_lv:oneClick(true)_lv:setCaption(_exp5.Value.." / ".._expn5.Value)_lv:align("Right")
	_fr:setImage(115398113982385)_fr:oneClick(true)_fr:align("Left")_fr:setOrder(3)_fr:bindEvent("selected",_obp)
	_an:setEnabled(true)
	local _ch5,_hm5,_amt
	local _av=nil
	local _ip=false
	local _cw=false
	local _cdi=nil
	local _st5={"กระบี่ประทวนทบ","กระบี่สัญญาบัตรทบ","กระบี่ประทวนทอ","กระบี่สัญญาบัตรทอ","กระบี่ประทวนทร","กระบี่สัญญาบัตรทร","กระบี่ประทวนตร","กระบี่สัญญาบัตรตร","กระบี่ประทวนองครักษ์","กระบี่สัญญาบัตรองค์รักษ์"}
	local _gt5={"TAR-21 Gold"}
	local _m1t={"ปืน M16A2","ปืน M16A2 ดาบปลายปืน"}
	local _m3t={"ปืน M16A3"}
	local _t2t={"ปืน TAR-21"}
	local _ant={"Armor40","Armor29","Armor60","Armor61"}
	local _wg={{table.unpack(_st5)},{table.unpack(_m1t)},{table.unpack(_m3t)},{table.unpack(_t2t)}}
	local _sw5={}
	for _,g in ipairs(_wg)do for _,n in ipairs(g)do table.insert(_sw5,n)end end
	local _wl={10,19,25,45,46,47,48,54,56,59,60,67,68,69,71,72,77,82,84,85,86}
	local _syt=nil
	local _syp=nil
	local _syc,_wc5,_twc,_prc
	local _d25=nil
	local _ndi={} local _rdi={} local _m1di={} local _m3di={} local _t2di={}
	local function _icp()
		if not _ch5 then return false end
		local s=_ch5:GetAttribute("Stance")
		return s=="Crouched"or s=="Prone"
	end
	local function _ha5()
		if not _ch5 then return false end
		return _ch5:FindFirstChild("Armor40")or _ch5:FindFirstChild("Armor29")or _ch5:FindFirstChild("Armor60")or _ch5:FindFirstChild("Armor61")
	end
	local function _hfl(l)
		if not _ch5 then return false end
		for _,t in ipairs(_ch5:GetChildren())do if t:IsA("Tool")and table.find(l,t.Name)then return true end end
		return false
	end
	local function _hss()return _hfl(_st5)end
	local function _hgu()return _hfl(_gt5)end
	local function _hm1()return _hfl(_m1t)end
	local function _hm3()return _hfl(_m3t)end
	local function _ht2()return _hfl(_t2t)end
	local function _udv()
		if _isp()then
			if _d25 then _d25:setEnabled(false)end
			for _,i in ipairs(_ndi)do i:setEnabled(false)end
			for _,i in ipairs(_rdi)do i:setEnabled(false)end
			for _,i in ipairs(_m1di)do i:setEnabled(false)end
			for _,i in ipairs(_m3di)do i:setEnabled(false)end
			for _,i in ipairs(_t2di)do i:setEnabled(false)end
			return
		end
		local sw=_hss()local m1=_hm1()local m3=_hm3()local t2=_ht2()
		local aw=sw or m1 or m3 or t2
		for _,i in ipairs(_ndi)do i:setEnabled(not aw)end
		if _d25 then _d25:setEnabled(not aw and _ha5())end
		for _,i in ipairs(_rdi)do i:setEnabled(sw)end
		for _,i in ipairs(_m1di)do i:setEnabled(m1)end
		for _,i in ipairs(_m3di)do i:setEnabled(m3)end
		for _,i in ipairs(_t2di)do i:setEnabled(t2)end
	end
	local _abd,_p3d,_a2d=false,false,false
	local function _sp3(v)
		if not _ch5 or _p3d then return end
		_p3d=true
		_ave:FireServer("Part3",v)
		task.delay(0.1,function()_p3d=false end)
	end
	local function _sav(s)
		if not _ch5 or _abd then return end
		_abd=true
		_ave:FireServer("Armor",s)
		task.delay(0.1,function()_abd=false end)
	end
	local function _sa2(h)
		if not _ch5 or _a2d then return end
		_a2d=true
		_ave:FireServer("Armor28",h)
		task.delay(0.1,function()_a2d=false end)
	end
	local function _gwg(n)
		for _,g in ipairs(_wg)do if table.find(g,n)then return g end end
		return nil
	end
	local function _gmw()
		if not _ch5 then return nil end
		for _,t in ipairs(_ch5:GetChildren())do if t:IsA("Tool")and table.find(_sw5,t.Name)then return t.Name end end
		return nil
	end
	local function _gtw(tc)
		if not tc then return nil end
		for _,t in ipairs(tc:GetChildren())do if t:IsA("Tool")and table.find(_sw5,t.Name)then return t.Name end end
		return nil
	end
	local function _swg(a,b)
		if not a or not b then return false end
		local g=_gwg(a)
		return g and table.find(g,b)~=nil
	end
	local function _gcfp(p)
		local c=p
		while c and c.Parent do
			if _pls5:GetPlayerFromCharacter(c)then return c end
			c=c.Parent
		end
		return nil
	end
	local function _gdi(id)
		for i=1,87 do
			local b=_rep5d.GameSettings.Animations:FindFirstChild("DANCE"..i)
			if b then
				local v=b:FindFirstChildOfClass("IntValue")
				if v and v.Value==id then return i end
			end
		end
		return nil
	end
	local function _iwl(i)return i~=nil and table.find(_wl,i)~=nil end
	local function _ssa()
		if _av then _av:Stop(0)_av=nil end
		if _amt then
			for _,t in ipairs(_amt:GetPlayingAnimationTracks())do
				if t.Animation and t.Animation.Name=="LocalAnimation"then t:Stop(0)end
			end
		end
		local o=_ch5 and _ch5:FindFirstChild("LocalAnimation")
		if o then o:Destroy()end
		_ip=false _cw=false _G.Enabled=false _cdi=nil
	end
	local function _sca()
		if _av then _av:Stop()_av=nil end
		local o=_ch5 and _ch5:FindFirstChild("LocalAnimation")
		if o then o:Destroy()end
		if _cdi==25 and _ha5()then _sav(false)end
		_cdi=nil _ip=false _cw=false _G.Enabled=false
		_rep5d.GameSettings.Events.SyncAnim:FireServer(0)
	end
	local function _csy()
		if _syc then _syc:Disconnect()_syc=nil end
		if _wc5 then _wc5:Disconnect()_wc5=nil end
		if _twc then _twc:Disconnect()_twc=nil end
		if _prc then _prc:Disconnect()_prc=nil end
		_syt=nil _syp=nil
		_ssa()
		if _an then _an:setEnabled(true)end
	end
	local function _psa(id,aw,di)
		if not _ch5 or not _hm5 then return end
		if _icp()then return end
		if not aw and _hm5.WalkSpeed>0 and _ch5:FindFirstChild("HumanoidRootPart")and _ch5.HumanoidRootPart.AssemblyLinearVelocity.Magnitude>1 then return end
		_ssa()
		local ao=Instance.new("Animation")
		ao.Name="LocalAnimation"
		ao.AnimationId="rbxassetid://"..id
		ao.Parent=_ch5
		_av=_amt:LoadAnimation(ao)
		_av:Play()
		_ip=true _cw=aw==true _G.Enabled=true _cdi=di
	end
	local function _ssy(tc)
		if _syc then _syc:Disconnect()end
		if _wc5 then _wc5:Disconnect()end
		if _twc then _twc:Disconnect()end
		if _prc then _prc:Disconnect()end
		_ssa()
		_syt=tc _syp=_pls5:GetPlayerFromCharacter(tc)
		_an:setEnabled(false)
		local sid=tc:GetAttribute("SyncAnimId")
		if sid and sid~=0 then
			local i=_gdi(sid)
			_psa(sid,_iwl(i),i)
		end
		_syc=tc:GetAttributeChangedSignal("SyncAnimId"):Connect(function()
			local ni=tc:GetAttribute("SyncAnimId")
			if not ni or ni==0 then _ssa()
			else local i=_gdi(ni)_psa(ni,_iwl(i),i)end
		end)
		_twc=tc.ChildRemoved:Connect(function(c)if c:IsA("Tool")and table.find(_sw5,c.Name)then _csy()end end)
		_wc5=_ch5.ChildRemoved:Connect(function(c)if c:IsA("Tool")and table.find(_sw5,c.Name)then _csy()end end)
		_prc=_pls5.PlayerRemoving:Connect(function(lp)if lp==_syp then _csy()end end)
	end
	local function _sal(ch)
		ch.ChildAdded:Connect(function(c)
			if c:IsA("Tool")then
				if table.find(_st5,c.Name)then
					if not _ha5()then
						task.defer(function()if c.Parent==_ch5 then c.Parent=_pl5.Backpack end end)
						return
					end
					if _cdi==25 then
						local sv=_cdi
						task.defer(function()
							if c.Parent==_ch5 then
								c.Parent=_pl5.Backpack
								task.wait(0.1)
								local la=_ch5:FindFirstChild("LocalAnimation")
								if la and _amt and(not _av or not _av.IsPlaying)then
									_av=_amt:LoadAnimation(la)
									_av:Play()
									_ip=true _cw=true _G.Enabled=true _cdi=sv
								end
							end
						end)
					else _sp3(false)end
					_udv()
				end
				if table.find(_gt5,c.Name)then _sa2(true)end
				if table.find(_m1t,c.Name)then _udv()end
				if table.find(_m3t,c.Name)then _udv()end
				if table.find(_t2t,c.Name)then _udv()end
				if table.find(_ant,c.Name)then task.wait(0.1)_udv()end
			end
		end)
		ch.ChildRemoved:Connect(function(c)
			if c:IsA("Tool")then
				if table.find(_st5,c.Name)then
					if _cdi and _cdi>=41 and _cdi<=48 then _sca()end
					if _cdi~=25 then _sp3(true)end
					_udv()
				end
				if table.find(_gt5,c.Name)then _sa2(false)end
				if table.find(_m1t,c.Name)then
					if _cdi and _cdi>=49 and _cdi<=61 then _sca()end
					_udv()
				end
				if table.find(_m3t,c.Name)then
					if _cdi and _cdi>=62 and _cdi<=75 then _sca()end
					_udv()
				end
				if table.find(_t2t,c.Name)then
					if _cdi and _cdi>=76 and _cdi<=87 then _sca()end
					_udv()
				end
				if table.find(_ant,c.Name)then task.wait(0.1)_udv()end
			end
		end)
		_sp3(not _hss())
		_sa2(_hgu())
		_udv()
	end
	local function _sc5(ch)
		_ch5=ch
		_hm5=ch:WaitForChild("Humanoid")
		_amt=_hm5:FindFirstChildOfClass("Animator")or Instance.new("Animator",_hm5)
		_av=nil _ip=false _cw=false _cdi=nil
		_abd=false _p3d=false _a2d=false
		_csy()
		_sal(ch)
	end
	if _pl5.Character then _sc5(_pl5.Character)end
	_pl5.CharacterAdded:Connect(_sc5)
	local function _pa5(id,aw,di)
		if not _ch5 or not _hm5 then return end
		if _icp()then return end
		if not aw and _hm5.WalkSpeed>0 and _ch5:FindFirstChild("HumanoidRootPart")and _ch5.HumanoidRootPart.AssemblyLinearVelocity.Magnitude>1 then return end
		local aid="rbxassetid://"..id
		local od=_ch5:FindFirstChild("LocalAnimation")
		if _av then _av:Stop()_av=nil end
		if od then
			if od.AnimationId==aid then
				od:Destroy()
				_ip=false _cw=false _G.Enabled=false
				if di==25 and _ha5()then _cdi=nil _sav(false)end
				_rep5d.GameSettings.Events.SyncAnim:FireServer(0)
				return
			end
			od:Destroy()
		end
		if _cdi==25 and _ha5()then _sav(false)end
		local ao=Instance.new("Animation")
		ao.Name="LocalAnimation"
		ao.AnimationId=aid
		ao.Parent=_ch5
		_av=_amt:LoadAnimation(ao)
		_av:Play()
		_ip=true _cw=aw==true _G.Enabled=true _cdi=di
		if di==25 and _ha5()then _sav(true)end
		_rep5d.GameSettings.Events.SyncAnim:FireServer(id)
	end
	task.spawn(function()
		while task.wait(0.1) do
			if _ip and not _cw and _ch5 and _ch5:FindFirstChild("HumanoidRootPart")then
				if _ch5.HumanoidRootPart.AssemblyLinearVelocity.Magnitude>0.1 then
					if _syt then _csy()
					else
						if _av then _av:Stop()_av=nil end
						local o=_ch5:FindFirstChild("LocalAnimation")
						if o then o:Destroy()end
						if _cdi==25 and _ha5()then _sav(false)end
						_cdi=nil _ip=false _cw=false _G.Enabled=false
						_rep5d.GameSettings.Events.SyncAnim:FireServer(0)
					end
				end
			end
			if _ip and _ch5 then
				local s=_ch5:GetAttribute("Stance")
				if s=="Crouched"or s=="Prone"then
					if _syt then _csy()else _sca()end
				end
			end
		end
	end)
	local function _ac5(ic,co)
		pcall(function()ic:modifyTheme({"Label","TextColor3",co})end)
		pcall(function()ic:modifyTheme({"IconLabel","TextColor3",co})end)
		pcall(function()ic:modifyTheme({"Widget","TextColor3",co})end)
		pcall(function()ic:modifyChildTheme({"Label","TextColor3",co})end)
	end
	local _yc=Color3.fromRGB(255,200,0)
	local _bc=Color3.fromRGB(0,55,255)
	local _rc=Color3.fromRGB(255,0,0)
	local _gc=Color3.fromRGB(0,200,0)
	local _pc=Color3.fromRGB(0,200,255)
	local _oc=Color3.fromRGB(255,60,100)
	local _db5={}
	for i=1,87 do
		local bt=_rep5d.GameSettings.Animations:FindFirstChild("DANCE"..i)
		if bt then
			local av=bt:FindFirstChildOfClass("IntValue")
			if av then
				local rl=0
				if i>=1 and i<=25 then rl=math.ceil(i/3)
				elseif i>=26 and i<=40 then rl=100+math.ceil((i-25)/3)end
				local di=_tb.new():setLabel(bt.Text)
				local aw=table.find(_wl,i)~=nil
				if i==25 then
					_ac5(di,_bc)
					_d25=di
					di:setEnabled(not _isp()and _ha5()and not _hss())
					table.insert(_db5,di)
				elseif i>=41 and i<=48 then
					_ac5(di,_rc)
					di:setEnabled(not _isp()and _hss())
					table.insert(_rdi,di)table.insert(_db5,di)
				elseif i>=49 and i<=61 then
					_ac5(di,_gc)
					di:setEnabled(not _isp()and _hm1())
					table.insert(_m1di,di)table.insert(_db5,di)
				elseif i>=62 and i<=75 then
					_ac5(di,_pc)
					di:setEnabled(not _isp()and _hm3())
					table.insert(_m3di,di)table.insert(_db5,di)
				elseif i>=76 and i<=87 then
					_ac5(di,_oc)
					di:setEnabled(not _isp()and _ht2())
					table.insert(_t2di,di)table.insert(_db5,di)
				elseif i>=26 then
					_ac5(di,_yc)
					di:setEnabled(not _isp())
					table.insert(_ndi,di)table.insert(_db5,di)
				else
					di:setEnabled(not _isp())
					table.insert(_ndi,di)table.insert(_db5,di)
				end
				di:bindEvent("selected",function()
					if _isp()then
						_rep5d.GameSettings.Events.DataDrinking:FireServer("ทีมนักโทษไม่สามารถใช้ท่าทางได้")
						di:deselect()return
					end
					if _icp()then di:deselect()return end
					if i>=1 and i<=40 then
						if _pl5:WaitForChild("leaderstats"):WaitForChild("เลเวล").Value>=rl then
							_pa5(av.Value,aw,i)
						else
							_rep5d.GameSettings.Events.DataDrinking:FireServer("ต้องการเลเวล "..rl.." ขึ้นไป")
						end
					else _pa5(av.Value,aw,i)end
					di:deselect()
				end)
			end
		end
	end
	_pl5:GetPropertyChangedSignal("Team"):Connect(function()
		_udv()
		if _isp()and _ip then if _syt then _csy()else _sca()end end
	end)
	_an:setImage(6034754445)
	_an:modifyTheme({"Dropdown","MaxIcons",4})
	_an:modifyChildTheme({"Widget","MinimumWidth",158})
	_an:setDropdown(_db5)
	_an:align("Right")
	local _ms5=_pl5:GetMouse()
	_uis5.InputBegan:Connect(function(inp,gp)
		if gp then return end
		local ic=inp.UserInputType==Enum.UserInputType.MouseButton1
		local it=inp.UserInputType==Enum.UserInputType.Touch
		if not ic and not it then return end
		if _isp()then return end
		local mw=_gmw()
		if not mw then return end
		local tg
		if it then
			local ur=workspace.CurrentCamera:ScreenPointToRay(inp.Position.X,inp.Position.Y)
			local rp=RaycastParams.new()
			rp.FilterDescendantsInstances={_ch5}
			rp.FilterType=Enum.RaycastFilterType.Exclude
			local r=workspace:Raycast(ur.Origin,ur.Direction*1000,rp)
			tg=r and r.Instance
		else tg=_ms5.Target end
		local tc=tg and _gcfp(tg)
		local tp=tc and _pls5:GetPlayerFromCharacter(tc)
		if tp and tp~=_pl5 then
			if _syt~=nil and tc~=_syt then return end
			local tw=_gtw(tc)
			local si=tc:GetAttribute("SyncAnimId")
			if _swg(mw,tw)and si and si~=0 then
				if _syt==tc then _csy()else _ssy(tc)end
			end
		end
	end)
end

do
	local _cam=workspace.CurrentCamera
	local _lt=game:GetService("Lighting")
	local _ss=game:GetService("SoundService")
	local _rs=game:GetService("RunService")
	local _bl=Instance.new("BlurEffect")
	_bl.Name="_"..script.Name.."BlurEffect"
	_bl.Enabled=false
	_bl.Parent=_lt
	local _cc=Instance.new("ColorCorrectionEffect")
	_cc.Name="_"..script.Name.."ColorCorrectionEffect"
	_cc.TintColor=Color3.new(0.717647,0.901961,1)
	_cc.Enabled=false
	_cc.Parent=_lt
	require(game.ReplicatedStorage:WaitForChild("GameSettings").Modules.Thread)
	local _cr=0.1
	local _lc=0
	local _wu=false
	task.wait(5)
	_rs.Heartbeat:Connect(function(dt)
		_lc+=dt
		if _lc<_cr then return end
		_lc=0
		local p=_cam.CFrame.Position
		local mn=p-Vector3.new(2,2,2)
		local mx=p+Vector3.new(2,2,2)
		local ok,mat=pcall(function()return workspace.Terrain:ReadVoxels(Region3.new(mn,mx):ExpandToGrid(4),4)end)
		if not ok then return end
		if not(mat[1]and mat[1][1]and mat[1][1][1])then return end
		local iw=mat[1][1][1]==Enum.Material.Water
		if iw==_wu then return end
		_wu=iw
		if iw then
			_ss.AmbientReverb=Enum.ReverbType.UnderWater
			_bl.Enabled=true
			_cc.Enabled=true
		else
			_ss.AmbientReverb=Enum.ReverbType.NoReverb
			_bl.Enabled=false
			_cc.Enabled=false
		end
	end)
end

do
	local _df=require(game.ReplicatedStorage.GameSettings.Modules.DistanceFade)
	local _ts=game:GetService("TweenService")
	local _rs2=game:GetService("RunService")
	local _dfi=_df.new()
	_dfi:UpdateSettings({EdgeDistanceCalculations=true,Texture="rbxassetid://18852900044",TextureTransparency=.25,BackgroundTransparency=0.95,TextureColor=Color3.fromRGB(115,248,255),BackgroundColor=Color3.fromRGB(0,153,255),TextureSize=Vector2.new(6,5.5),TextureOffset=Vector2.new(0,.5),Brightness=3})
	local _fld=game.Workspace:WaitForChild("โมเดลทั้งหมด"):WaitForChild("กำแพงล่องหน")
	local _tp={}
	local function _ap(c)
		if c:IsA("BasePart")and c.Name=="Part"then
			table.insert(_tp,c)_dfi:AddFace(c,Enum.NormalId.Front)_dfi:AddFace(c,Enum.NormalId.Back)
		end
	end
	local function _rp2(c)
		if c:IsA("BasePart")and c.Name=="Part"then
			for i,p in ipairs(_tp)do if p==c then table.remove(_tp,i)break end end
			_dfi:RemoveFace(c,Enum.NormalId.Front)_dfi:RemoveFace(c,Enum.NormalId.Back)
		end
	end
	for _,c in ipairs(_fld:GetChildren())do _ap(c)end
	_fld.ChildAdded:Connect(_ap)
	_fld.ChildRemoved:Connect(_rp2)
	local _tv=Instance.new("Vector3Value")
	_tv.Parent=script
	_ts:Create(_tv,TweenInfo.new(6,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,-1,false),{Value=Vector3.new(-6,5.5)}):Play()
	local _sr=1/30
	local _ls=0
	_rs2.Heartbeat:Connect(function(dt)
		_ls+=dt
		if _ls<_sr then return end
		_ls=0
		local ox=-3
		local oy=_tv.Value.Y
		for _,v in ipairs(_tp)do
			_dfi:UpdateFaceSettings(v,Enum.NormalId.Front,{TextureOffset=Vector2.new(ox,oy)})
			_dfi:UpdateFaceSettings(v,Enum.NormalId.Back,{TextureOffset=Vector2.new(-ox,oy)})
		end
		_dfi:Step()
	end)
end

do
	local _cas=game:GetService("ContextActionService")
	local _rep=game:GetService("ReplicatedStorage").GameSettings
	local _lsv=game:GetService("LocalizationService")
	local _pl=game:GetService("Players")
	local _lp=_pl.LocalPlayer
	local _pta=_rep:WaitForChild("Events"):WaitForChild("PlayToolAnim")
	local _it=false
	do
		local ok,c=pcall(function()return _lsv:GetCountryRegionForPlayerAsync(_lp)end)
		if ok and c=="TH"then _it=true end
	end
	local _sn={["ป้าย"]=true,["ป้ายยักษ์"]=true}
	local function _ds(t)
		if _sn[t.Name]then
			local h=t:FindFirstChild("Handle")local b=t:FindFirstChild("Board")
			if h then h:Destroy()end if b then b:Destroy()end
		end
	end
	local function _wc(ch)
		for _,t in ipairs(ch:GetChildren())do if t:IsA("Tool")then _ds(t)end end
		ch.ChildAdded:Connect(function(c)if c:IsA("Tool")then _ds(c)end end)
	end
	if not _it then
		for _,p in ipairs(_pl:GetPlayers())do if p.Character then _wc(p.Character)end p.CharacterAdded:Connect(_wc)end
		_pl.PlayerAdded:Connect(function(p)p.CharacterAdded:Connect(_wc)end)
	else
		local _et=nil
		local function _oe(t)
			if _sn[t.Name]then _lp.PlayerGui.TextSignGui.Enabled=true _pta:FireServer("TextSign",true)_et=t end
		end
		local function _ou(t)
			if _sn[t.Name]then _lp.PlayerGui.TextSignGui.Enabled=false _pta:FireServer("StopAll",false)_et=nil end
		end
		local function _scd(ch)
			local hm=ch:WaitForChild("Humanoid",5)
			if hm then hm.Died:Once(function()if _et then _et:Destroy()end end)end
		end
		_cas.LocalToolEquipped:Connect(_oe)
		_cas.LocalToolUnequipped:Connect(_ou)
		if _lp.Character then _scd(_lp.Character)end
		_lp.CharacterAdded:Connect(_scd)
	end
end

do
	repeat task.wait()until game:IsLoaded()
	local _plr=game.Players.LocalPlayer
	local _ssv=game:GetService("SoundService")
	local _ws=game:GetService("Workspace")
	local _m1=_ssv.Jail:WaitForChild("Jail")
	local _ms=_ssv.Main:WaitForChild("Main")
	local _as=_ssv.Annc:WaitForChild("Annc")
	local _wt=_ssv.Wanted:WaitForChild("Wanted")
	task.spawn(function()
		while task.wait(0.1)do
			local na=_ws:GetAttribute("NukeActive")
			local ra=_ws:GetAttribute("RiotActive")
			local wd=_plr:GetAttribute("Wanted")
			local wb=_plr:GetAttribute("WantedBank")
			local ap=_as.Playing local jp=_m1.Playing
			local sm=(not ra)and(not na)and(not ap)and(not jp)and(not wd)and(not wb)
			if sm then if not _ms.Playing then _ms:Play()end else if _ms.Playing then _ms:Stop()end end
			if ap or jp or ra then if _wt.Playing then _wt:Stop()end
			else
				if(wd or wb)and not _wt.Playing then _wt:Play()
				elseif(not wd and not wb)and _wt.Playing then _wt:Stop()end
			end
		end
	end)
end

do
	local _rs3=game:GetService("RunService")
	local _plx=game:GetService("Players").LocalPlayer
	local _ind=script:WaitForChild("Assets"):WaitForChild("Indicator")
	local _ipc=_ind.Character local _ipp=_ind.ProximityPrompt
	local _srt=1/30 local _lst=0
	local _prompts={}
	local function _add(d)if d:IsA("ProximityPrompt")then _prompts[d]=true end end
	for _,d in ipairs(workspace:GetDescendants())do _add(d)end
	workspace.DescendantAdded:Connect(_add)
	workspace.DescendantRemoving:Connect(function(d)if _prompts[d]then _prompts[d]=nil end end)
	local function _promptPart(pr)
		local par=pr.Parent
		if not par then return nil,nil end
		local pos
		if par:IsA("Attachment")then pos=par.WorldPosition
		elseif par:IsA("BasePart")then pos=par.Position
		elseif par:IsA("Model")then pos=par:GetPivot().Position
		else return nil,nil end
		local excl=pr:FindFirstAncestorWhichIsA("Model")
		if not excl then if par:IsA("Attachment")then excl=par.Parent else excl=par end end
		return pos,excl
	end
	local _rp=RaycastParams.new()
	_rp.FilterType=Enum.RaycastFilterType.Exclude
	_rp.IgnoreWater=true
	local function _blocked(origin,target,excl)
		local dir=target-origin
		local dist=dir.Magnitude
		if dist<0.05 then return false end
		_rp.FilterDescendantsInstances={_plx.Character,excl}
		local res=workspace:Raycast(origin,dir,_rp)
		return res~=nil and res.Distance<dist-0.5
	end
	local function _ui()
		local ch=_plx.Character
		local hr=ch and ch:FindFirstChild("HumanoidRootPart")
		if not hr then if _ind.Parent~=nil then _ind.Parent=nil end return end
		local hp=hr.Position
		local best,bestPos,bestD=nil,nil,math.huge
		for pr in pairs(_prompts)do
			if pr.Parent and pr.Enabled then
				local pos,excl=_promptPart(pr)
				if pos then
					local d=(pos-hp).Magnitude
					if d<=pr.MaxActivationDistance and d<bestD then
						if pr.RequiresLineOfSight then
							if not _blocked(hp,pos,excl)then best,bestPos,bestD=pr,pos,d end
						else
							best,bestPos,bestD=pr,pos,d
						end
					end
				end
			end
		end
		if not best then if _ind.Parent~=nil then _ind.Parent=nil end return end
		_ipp.WorldPosition=bestPos
		_ipc.WorldPosition=hp
		if _ind.Parent~=workspace then _ind.Parent=workspace end
	end
	_rs3.Heartbeat:Connect(function(dt)
		_lst=_lst+dt
		if _lst<_srt then return end
		_lst=0 _ui()
	end)
end
do
	local _plv=game:GetService("Players").LocalPlayer
	local _db=game:GetService("Debris")
	local _sg=Instance.new("ScreenGui")
	_sg.Name="SplatterScreen" _sg.ResetOnSpawn=false _sg.Parent=_plv.PlayerGui
	local _sc=false
	local function _spc(ch)
		local hm=ch:WaitForChild("Humanoid",5) if not hm then return end
		local hd=ch:FindFirstChild("Head") if not hd then return end
		local fc=hd:FindFirstChild("face")or hd:FindFirstChild("Face") if not fc then return end
		local nt=fc.Texture local dt="rbxassetid://82908315" local det="rbxassetid://15395252"
		local id=false local cpp=true local lh=hm.Health local frt
		hm.HealthChanged:Connect(function(nh)
			local dmg=lh-nh lh=nh
			if nh<=0 and not id then id=true if frt then task.cancel(frt)end fc.Texture=det return end
			if id or dmg<10 then return end
			if dmg>=30 and hm.Health>0 then
				if frt then task.cancel(frt)end
				fc.Texture=dt
				frt=task.delay(5,function()if hm.Health>0 and not id then fc.Texture=nt end end)
			end
			if not cpp and hm.Health>0 then return end
			cpp=false
			local _painFolder=script:FindFirstChild("Pain")
			local ps=_painFolder and _painFolder:GetChildren()or{}
			if #ps>0 then local s=ps[math.random(#ps)]:Clone()s.Parent=hd s:Play()_db:AddItem(s,s.TimeLength)end
			task.delay(5,function()cpp=true end)
			if not _sc then
				local _painFolder2=script:FindFirstChild("Pain")
				local sl=_painFolder2 and _painFolder2:GetChildren()or{}
				if #sl>0 then
					_sc=true local cl=sl[math.random(#sl)]:Clone()cl.Parent=hd cl:Play()_db:AddItem(cl,cl.TimeLength+1)
					task.delay(10,function()_sc=false end)
				end
			end
		end)
	end
	local _hc={}
	local function _oca(c)
		if not c:IsA("Model")then return end if _hc[c]then return end _hc[c]=true
		task.spawn(function()
			if c:FindFirstChildOfClass("Humanoid")or c:WaitForChild("Humanoid",2)then _spc(c)end
			c.AncestryChanged:Connect(function()if not c:IsDescendantOf(game)then _hc[c]=nil end end)
		end)
	end
	for _,c in ipairs(workspace:GetChildren())do _oca(c)end
	workspace.ChildAdded:Connect(_oca)
end

do
	local _plw=game:GetService("Players").LocalPlayer
	local _rsr=game:GetService("RunService")
	local _stg=game:GetService("StarterGui")
	repeat task.wait()until _plw.Character
	local _pgui=_plw:WaitForChild("PlayerGui")
	local _ldt=false
	local function _sbe(s)local g=_pgui:FindFirstChild("BackpackGui")if g then g.Enabled=s end end
	local function _sui()local g=_pgui:FindFirstChild("ShopGui")local mf=g and g:FindFirstChild("MainFrame")if mf and mf.Visible then mf.Visible=false end end
	_rsr.RenderStepped:Connect(function()
		if not _plw.Character then return end
		local det=_plw:FindFirstChild("Detained")
		local isd=det and det.Value==true
		if isd then
			_ldt=true
			pcall(function()_stg:SetCore("ResetButtonCallback",false)end)
			_sbe(false)
			_sui()
			local hm=_plw.Character:FindFirstChildOfClass("Humanoid")
			if hm then
				local ov=_plw:FindFirstChild("Officer")local of=ov and ov.Value
				hm:UnequipTools()
				if of and of.Character and of.Character:FindFirstChild("HumanoidRootPart")then
					local or2=of.Character.HumanoidRootPart
					local pr=_plw.Character:FindFirstChild("HumanoidRootPart")
					if pr then
						local lv=or2.CFrame.LookVector
						local bp=or2.Position-(lv*5)
						hm.WalkToPoint=bp
						local di=(pr.Position-or2.Position).Magnitude
						if di>7 then hm.WalkSpeed=16 elseif di<3 then hm.WalkSpeed=0 else hm.WalkSpeed=12 end
					end
				end
				if hm.Sit then hm.Jump=true end
				if of and of.Character then
					local oh=of.Character:FindFirstChildOfClass("Humanoid")
					if oh and oh.Jump then hm.Jump=true end
				end
			end
		elseif _plw:FindFirstChild("ArrestData")and _plw.ArrestData:FindFirstChild("Time")and _plw.ArrestData.Time.Value>0 then
			pcall(function()_stg:SetCore("ResetButtonCallback",false)end)
			_sbe(false)
		else
			if _ldt then
				_ldt=false
				local hm=_plw.Character and _plw.Character:FindFirstChildOfClass("Humanoid")
				if hm and _plw.Character:FindFirstChild("HumanoidRootPart")then
					hm.WalkToPoint=_plw.Character.HumanoidRootPart.Position
					task.defer(function()if hm and hm.Parent then hm.WalkSpeed=16 end end)
				end
			end
			pcall(function()_stg:SetCore("ResetButtonCallback",true)end)
			if _plw:GetAttribute("PianoPlaying") then _sbe(false) else _sbe(true) end
		end
	end)
	_plw.CharacterAdded:Connect(function()_ldt=false end)
end

do
	local _rep2=game:GetService("ReplicatedStorage")
	local _tsv=game:GetService("TweenService")
	local _rsr2=game:GetService("RunService")
	local _plh=game:GetService("Players")
	local _cam2=workspace.CurrentCamera
	local _plhh=_plh.LocalPlayer
	local _dg=Instance.new("ScreenGui")
	_dg.Name="DamageGui" _dg.ScreenInsets=Enum.ScreenInsets.DeviceSafeInsets
	_dg.IgnoreGuiInset=true _dg.ResetOnSpawn=false _dg.Parent=_plhh.PlayerGui
	local _ai={} local _it2=_rep2.GameSettings.Assets.KillFeed.DamageIndicator
	local _bs2=_it2.DamageIndicatorImage.Size
	_rep2.GameSettings.Events.CreateDamageIndicator.OnClientEvent:Connect(function(pn,hp)
		if pn==_plhh.Name then return end
		local pv=_ai[pn]
		if pv then pv.connection:Disconnect()pv.indicator:Destroy()_ai[pn]=nil end
		local ind=_it2:Clone()
		local img=ind.DamageIndicatorImage
		ind.Visible=true img.ImageTransparency=0 ind.Parent=_dg
		local function ca()
			local cf=_cam2.CFrame local cp=cf.Position
			local fl=cf.LookVector*Vector3.new(1,0,1)
			local rp2=CFrame.new(cp,cp+fl):PointToObjectSpace(hp)
			return math.deg(math.atan2(rp2.Z,rp2.X))+90,(cp-hp).Magnitude
		end
		local cn=_rsr2.RenderStepped:Connect(function()
			local a,d=ca()
			ind.Rotation=a
			local sc=math.max(0.35,math.clamp(1-d/200,0,1))
			img.Size=UDim2.fromScale(sc*_bs2.X.Scale,_bs2.Y.Scale)
		end)
		_ai[pn]={indicator=ind,connection=cn}
		task.delay(2,function()
			local e=_ai[pn]
			if not e or e.indicator~=ind then return end
			cn:Disconnect()
			local fd=_tsv:Create(img,TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{ImageTransparency=1})
			fd:Play()
			fd.Completed:Once(function()ind:Destroy()if _ai[pn]and _ai[pn].indicator==ind then _ai[pn]=nil end end)
		end)
	end)
end

do
	local _plq=game:GetService("Players").LocalPlayer
	local _rep3=game:GetService("ReplicatedStorage")
	local _mds=25*25 local _ar=nil
	local function _gr()
		if not _ar then
			local gs=_rep3:FindFirstChild("GameSettings")
			if gs then _ar=gs:WaitForChild("Events"):FindFirstChild("Authorize")end
		end
		return _ar
	end
	local function _ct(t)
		if not t:IsA("Tool")then return end
		if t.Name~="อนุญาตให้เข้าถึง"then return end
		if t:FindFirstChild("AlreadyConnected")then return end
		local f=Instance.new("BoolValue")f.Name="AlreadyConnected"f.Parent=t
		t.Activated:Connect(function()
			local ms=_plq:GetMouse()local tg=ms.Target
			if not tg then return end
			local md=tg:FindFirstAncestorOfClass("Model")
			if not(md and md:FindFirstChildOfClass("Humanoid"))then return end
			local tr=md:FindFirstChild("HumanoidRootPart")if not tr then return end
			local mc=_plq.Character local mr=mc and mc:FindFirstChild("HumanoidRootPart")
			if not mr then return end
			local ds=(mr.Position-tr.Position).Magnitude
			if ds*ds>_mds then return end
			local rm=_gr()
			if rm and rm:IsA("RemoteEvent")then rm:FireServer(md)end
		end)
	end
	local _bpk=_plq:WaitForChild("Backpack")
	local _bpc
	local function _wb()
		if _bpc then _bpc:Disconnect()end
		for _,t in ipairs(_bpk:GetChildren())do _ct(t)end
		_bpc=_bpk.ChildAdded:Connect(_ct)
	end
	_plq.CharacterAdded:Connect(function(ch)
		ch.ChildAdded:Connect(function(c)_ct(c)end)
		for _,c in ipairs(ch:GetChildren())do _ct(c)end
		_wb()
	end)
	if _plq.Character then
		local ch=_plq.Character
		ch.ChildAdded:Connect(function(c)_ct(c)end)
		for _,c in ipairs(ch:GetChildren())do _ct(c)end
	end
	_wb()
end

do
	local _plc=game:GetService("Players").LocalPlayer
	local _cpr=game:GetService("ContentProvider")
	local _rep4=game:GetService("ReplicatedStorage")
	local _gs4=_rep4:WaitForChild("GameSettings")
	local _pta4=_gs4:WaitForChild("Events"):WaitForChild("PlayToolAnim")
	local _cns={} local _eqt=nil local _sw="SPH_Weapon"
	local _rsw4=game:GetService("RunService")
	local _walking4=false
	local function _isw(t)return t:FindFirstChild(_sw)~=nil end
	local function _rid(v)local s=tostring(v)if s:find("rbxassetid://")then return s end return"rbxassetid://"..s end
	local function _ptl(t)
		if not t:IsA("Tool")then return end if _isw(t)then return end
		local tl={}
		local a1=t:FindFirstChild("AnimID")if a1 then local a=Instance.new("Animation")a.AnimationId=_rid(a1.Value)table.insert(tl,a)end
		local a2=t:FindFirstChild("AnimID2")if a2 then local a=Instance.new("Animation")a.AnimationId=_rid(a2.Value)table.insert(tl,a)end
		if #tl>0 then _cpr:PreloadAsync(tl)end
	end

	local _lockedL4,_lockedR4=nil,nil
	local function _captureArms4()
		local ch4=_plc.Character
		local torso4=ch4 and ch4:FindFirstChild("Torso")
		if not torso4 then return end
		local lsh=torso4:FindFirstChild("Left Shoulder")
		local rsh=torso4:FindFirstChild("Right Shoulder")
		if lsh then _lockedL4=lsh.Transform end
		if rsh then _lockedR4=rsh.Transform end
	end
	local function _playHeld(t)
		local a1=t:FindFirstChild("AnimID")local a2=t:FindFirstChild("AnimID2")
		if a1 then _pta4:FireServer("ToolAnimById",true,_rid(a1.Value),false)end
		if a2 then task.wait(0.02)if _eqt~=t then return end _pta4:FireServer("ToolAnimById",true,_rid(a2.Value),false)end
		task.wait(0.15)
		if _eqt==t then _captureArms4()end
	end
	local function _oeq(t)
		if _isw(t)then return end
		local a1=t:FindFirstChild("AnimID")local a2=t:FindFirstChild("AnimID2")
		if not a1 and not a2 then return end
		_eqt=t _lockedL4,_lockedR4=nil,nil _pta4:FireServer("StopAll",false)task.wait(0.05)
		if _eqt~=t then return end
		local ch4=_plc.Character
		local hm4=ch4 and ch4:FindFirstChildOfClass("Humanoid")
		if hm4 and hm4.MoveDirection.Magnitude>0.05 then
			_walking4=true
		else
			_walking4=false
			_playHeld(t)
		end
	end
	local function _ouq(t)if _isw(t)then return end _eqt=nil _walking4=false _lockedL4,_lockedR4=nil,nil _pta4:FireServer("StopAll",false)end

	_rsw4.Heartbeat:Connect(function()
		if not _eqt then return end
		local ch4=_plc.Character
		local hm4=ch4 and ch4:FindFirstChildOfClass("Humanoid")
		if not hm4 then return end
		local moving=hm4.MoveDirection.Magnitude>0.05
		if moving and not _walking4 then
			_walking4=true
			_pta4:FireServer("StopAll",false)
		elseif not moving and _walking4 then
			_walking4=false
			_playHeld(_eqt)
		end
	end)

	_rsw4:BindToRenderStep("HeldArmLock", Enum.RenderPriority.Last.Value, function()
		if not _walking4 or not _lockedL4 then return end
		local ch4=_plc.Character
		local torso4=ch4 and ch4:FindFirstChild("Torso")
		if not torso4 then return end
		local lsh=torso4:FindFirstChild("Left Shoulder")
		local rsh=torso4:FindFirstChild("Right Shoulder")
		if lsh then lsh.Transform=_lockedL4 end
		if rsh then rsh.Transform=_lockedR4 end
	end)
	local function _ht(t)
		if not t:IsA("Tool")then return end if _isw(t)then return end if _cns[t]then return end
		task.spawn(function()_ptl(t)end)
		_cns[t]={t.Equipped:Connect(function()_oeq(t)end),t.Unequipped:Connect(function()_ouq(t)end)}
	end
	local function _uht(t)
		if t==_eqt then _eqt=nil _pta4:FireServer("StopAll",false)end
		if _cns[t]then for _,c in pairs(_cns[t])do c:Disconnect()end _cns[t]=nil end
	end
	local function _wct(co)
		for _,c in pairs(co:GetChildren())do _ht(c)end
		co.ChildAdded:Connect(_ht)co.ChildRemoved:Connect(_uht)
	end
	local function _oca4(ch)
		if _eqt then _pta4:FireServer("StopAll",false)_eqt=nil end
		_cns={} _wct(ch)
	end
	_plc.CharacterAdded:Connect(_oca4)
	local _bpz=_plc:WaitForChild("Backpack")
	_wct(_bpz)
	if _plc.Character then _oca4(_plc.Character)end
end
do
	local _plA=game:GetService("Players").LocalPlayer
	local _repA=game:GetService("ReplicatedStorage")
	local _rsA=game:GetService("RunService")
	local _uisA=game:GetService("UserInputService")
	local _wsA=game:GetService("Workspace")
	local _plsA=game:GetService("Players")
	local _arA=_repA:WaitForChild("GameSettings"):WaitForChild("Events"):WaitForChild("AdminRemote")
	local _camA=_wsA.CurrentCamera
	_wsA:GetPropertyChangedSignal("CurrentCamera"):Connect(function()if _wsA.CurrentCamera then _camA=_wsA.CurrentCamera end end)
	local _ctrlA=nil
	task.spawn(function()
		local ok,pm=pcall(function()return require(_plA:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))end)
		if ok and pm then pcall(function()_ctrlA=pm:GetControls()end)end
	end)
	local _flA=false
	local _fcA=nil
	local _fsA=50
	local _curV=Vector3.zero
	local _upA=false
	local _dnA=false
	local function _sfA()
		_flA=false
		if _fcA then _fcA:Disconnect()_fcA=nil end
		_curV=Vector3.zero
		local ch=_plA.Character
		local hrp=ch and ch:FindFirstChild("HumanoidRootPart")
		if hrp then
			local bv=hrp:FindFirstChild("_ADMfv")
			local bg=hrp:FindFirstChild("_ADMfg")
			if bv then bv:Destroy()end
			if bg then bg:Destroy()end
		end
		local hm=ch and ch:FindFirstChildOfClass("Humanoid")
		if hm then hm.PlatformStand=false end
	end
	local function _gfA()
		local ch=_plA.Character
		if not ch then return end
		local hrp=ch:FindFirstChild("HumanoidRootPart")
		local hm=ch:FindFirstChildOfClass("Humanoid")
		if not hrp or not hm then return end
		_sfA()
		_flA=true
		hm.PlatformStand=true
		_curV=Vector3.zero
		local bv=Instance.new("BodyVelocity")
		bv.Name="_ADMfv"
		bv.MaxForce=Vector3.new(1,1,1)*9e9
		bv.Velocity=Vector3.zero
		bv.Parent=hrp
		local bg=Instance.new("BodyGyro")
		bg.Name="_ADMfg"
		bg.MaxTorque=Vector3.new(1,1,1)*9e9
		bg.P=5000
		bg.D=500
		bg.CFrame=hrp.CFrame
		bg.Parent=hrp
		_fcA=_rsA.RenderStepped:Connect(function(dt)
			if not _flA or not hrp.Parent then return end
			bg.CFrame=bg.CFrame:Lerp(_camA.CFrame,math.clamp(dt*10,0,1))
			local mv=Vector3.zero
			if _ctrlA then pcall(function()mv=_ctrlA:GetMoveVector()end)end
			local d=Vector3.zero
			d=d+_camA.CFrame.RightVector*mv.X
			d=d-_camA.CFrame.LookVector*mv.Z
			if _upA then d=d+Vector3.new(0,1,0)end
			if _dnA then d=d-Vector3.new(0,1,0)end
			local target=Vector3.zero
			if d.Magnitude>0 then target=d.Unit*_fsA end
			_curV=_curV:Lerp(target,math.clamp(dt*8,0,1))
			bv.Velocity=_curV
		end)
	end
	local function _tgA()
		if _flA then _sfA()else _gfA()end
	end
	_uisA.InputBegan:Connect(function(i,gp)
		if gp then return end
		local k=i.KeyCode
		if k==Enum.KeyCode.Space then _upA=true
		elseif k==Enum.KeyCode.LeftShift then _dnA=true
		elseif k==Enum.KeyCode.B then if _flA then _sfA()end
		elseif k==Enum.KeyCode.E then _fsA=math.clamp(_fsA+10,10,500)
		elseif k==Enum.KeyCode.Q then _fsA=math.clamp(_fsA-10,10,500)
		end
	end)
	_uisA.InputEnded:Connect(function(i)
		if i.KeyCode==Enum.KeyCode.Space then _upA=false
		elseif i.KeyCode==Enum.KeyCode.LeftShift then _dnA=false end
	end)
	_uisA.InputChanged:Connect(function(i,gp)
		if gp or not _flA then return end
		if i.UserInputType==Enum.UserInputType.MouseWheel then
			_fsA=math.clamp(_fsA+i.Position.Z*10,10,500)
		end
	end)
	local _btA=nil
	local function _mbtn()
		if _btA then return end
		if not _uisA.TouchEnabled then return end
		local sg=Instance.new("ScreenGui")
		sg.Name="_ADMflyBtn"
		sg.ResetOnSpawn=false
		sg.Parent=_plA:WaitForChild("PlayerGui")
		_btA=sg
		local function _mk(txt,yoff)
			local b=Instance.new("TextButton")
			b.Size=UDim2.fromOffset(64,64)
			b.Position=UDim2.new(1,-170,1,yoff)
			b.AnchorPoint=Vector2.new(0,0)
			b.BackgroundColor3=Color3.fromRGB(40,40,40)
			b.BackgroundTransparency=0.3
			b.TextColor3=Color3.new(1,1,1)
			b.TextScaled=true
			b.Text=txt
			b.Parent=sg
			Instance.new("UICorner",b).CornerRadius=UDim.new(0.2,0)
			return b
		end
		local up=_mk("▲",-300)
		local dn=_mk("▼",-230)
		local sUp=_mk("+",-160)
		local sDn=_mk("−",-90)
		local bcl=_mk("B",-20)
		bcl.BackgroundColor3=Color3.fromRGB(120,40,40)
		up.InputBegan:Connect(function(inp)if inp.UserInputType==Enum.UserInputType.Touch then _upA=true end end)
		up.InputEnded:Connect(function(inp)if inp.UserInputType==Enum.UserInputType.Touch then _upA=false end end)
		dn.InputBegan:Connect(function(inp)if inp.UserInputType==Enum.UserInputType.Touch then _dnA=true end end)
		dn.InputEnded:Connect(function(inp)if inp.UserInputType==Enum.UserInputType.Touch then _dnA=false end end)
		sUp.Activated:Connect(function()_fsA=math.clamp(_fsA+10,10,500)end)
		sDn.Activated:Connect(function()_fsA=math.clamp(_fsA-10,10,500)end)
		bcl.Activated:Connect(function()if _flA then _sfA()end end)
	end
	local function _hbtn(v)
		if _btA then _btA.Enabled=v end
	end
	local _efA=nil
	local _ecA={}
	local function _clA()
		if _efA then _efA:Destroy()_efA=nil end
		for _,c in ipairs(_ecA)do c:Disconnect()end
		_ecA={}
	end
	local function _mkA(t)
		if t==_plA then return end
		local ch=t.Character
		if not ch then return end
		local hd=ch:FindFirstChild("Head")
		if not hd then return end
		local col=t.TeamColor and t.TeamColor.Color or Color3.new(1,1,1)
		local hl=Instance.new("Highlight")
		hl.FillColor=col
		hl.OutlineColor=Color3.new(1,1,1)
		hl.FillTransparency=0.5
		hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
		hl.Adornee=ch
		hl.Parent=_efA
		local bb=Instance.new("BillboardGui")
		bb.Size=UDim2.new(0,200,0,50)
		bb.AlwaysOnTop=true
		bb.StudsOffset=Vector3.new(0,3,0)
		bb.Adornee=hd
		bb.Parent=_efA
		local tl=Instance.new("TextLabel")
		tl.Size=UDim2.new(1,0,1,0)
		tl.BackgroundTransparency=1
		tl.TextColor3=col
		tl.TextStrokeTransparency=0
		tl.Font=Enum.Font.SourceSansBold
		tl.TextScaled=true
		tl.Text=t.Name
		tl.Parent=bb
	end
	local function _toA()
		if _efA then _clA()return end
		_efA=Instance.new("Folder")
		_efA.Name="AdminESP"
		_efA.Parent=_plA:WaitForChild("PlayerGui")
		for _,p in ipairs(_plsA:GetPlayers())do
			_mkA(p)
			_ecA[#_ecA+1]=p.CharacterAdded:Connect(function()task.wait(1)if _efA then _mkA(p)end end)
		end
		_ecA[#_ecA+1]=_plsA.PlayerAdded:Connect(function(p)
			p.CharacterAdded:Connect(function()task.wait(1)if _efA then _mkA(p)end end)
		end)
	end
	local _vwA=false
	local function _vpA(n)
		local t=_plsA:FindFirstChild(n)
		if t and t.Character and t.Character:FindFirstChildOfClass("Humanoid")then
			_camA.CameraSubject=t.Character:FindFirstChildOfClass("Humanoid")
			_vwA=true
		end
	end
	local function _uvA()
		local ch=_plA.Character
		local hm=ch and ch:FindFirstChildOfClass("Humanoid")
		if hm then _camA.CameraSubject=hm end
		_vwA=false
	end
	_arA.OnClientEvent:Connect(function(a,arg)
		if a=="fly" then
			if tonumber(arg) then _fsA=math.clamp(tonumber(arg),10,500) end
			_mbtn()_hbtn(true)_gfA()
		elseif a=="unfly" then _hbtn(false)_sfA()
		elseif a=="esp" then _toA()
		elseif a=="view" then _vpA(arg)
		elseif a=="unview" then _uvA()
		end
	end)
	_plA.CharacterAdded:Connect(function()
		if _flA then task.wait(0.5)_gfA()end
		if _vwA then task.wait(0.5)_uvA()end
	end)
end
do
	repeat task.wait(1)until game.Players.LocalPlayer.Character
	local _nr=game.ReplicatedStorage.GameSettings.Events.Notify
	local _nt=game:GetService("StarterGui")
	local _plf=game.Players.LocalPlayer
	local _tsf=game:GetService("TweenService")
	local _fu=_plf.PlayerGui:WaitForChild("WantedGui"):WaitForChild("Fade")
	local _sf=_plf.PlayerGui:WaitForChild("WantedGui"):WaitForChild("Stars")
	local _bs3=game.ReplicatedStorage.GameSettings.Assets:FindFirstChild("BaseStar")
	local _se=game.SoundService.Wanted:FindFirstChild("Wanted")
	local _sts={} local _atw={}
	local function _cntw()for _,t in ipairs(_atw)do t:Cancel()end table.clear(_atw)end
	local function _cls()_cntw()for _,s in ipairs(_sts)do s:Destroy()end table.clear(_sts)end
	local _ctw=nil local _ict=false
	local function _scp()if _ctw then _ctw:Cancel()_ctw=nil end end
	local function _clp()
		_scp()
		local function st()
			_ctw=_tsf:Create(_fu,TweenInfo.new(0.5),{ImageColor3=_ict and Color3.fromRGB(60,122,255)or Color3.fromRGB(16,39,57)})
			_ict=not _ict _ctw:Play()
			_ctw.Completed:Once(function(s)if s==Enum.PlaybackState.Completed then st()end end)
		end
		st()
	end
	local function _crs(am)
		_cls()
		for i=1,am do
			local s=_bs3:Clone()s.Parent=_sf s.Visible=true table.insert(_sts,s)
			local it=false
			local function tp()
				local t=_tsf:Create(s,TweenInfo.new(1),{ImageTransparency=it and 0.5 or 0})
				table.insert(_atw,t)it=not it t:Play()
				t.Completed:Once(function(st2)if st2==Enum.PlaybackState.Completed and s.Parent then tp()end end)
			end
			local isc=false
			local function scp2()
				local t=_tsf:Create(s,TweenInfo.new(0.5),{ImageColor3=isc and Color3.new(0,0.4,1)or Color3.new(1,0.388,0.396)})
				table.insert(_atw,t)isc=not isc t:Play()
				t.Completed:Once(function(st2)if st2==Enum.PlaybackState.Completed and s.Parent then scp2()end end)
			end
			tp()scp2()
		end
	end
	_nr.OnClientEvent:Connect(function(t,t2)
		_nt:SetCore("SendNotification",{Title=t,Text=t2,Icon="rbxassetid://76825922984141",Duration=5})
	end)
	local function _uw()
		local iw=_plf:GetAttribute("Wanted")==true
		local iwb=_plf:GetAttribute("WantedBank")==true
		if iw or iwb then
			local sa=iwb and 5 or 2
			_crs(sa)_sf.Visible=true
			game.SoundService.Wanted.SuperIncrease:Play()
			_tsf:Create(_fu,TweenInfo.new(1),{ImageTransparency=0}):Play()
			_ict=false _clp()task.wait(1)_se:Play()
		else
			_scp()_sf.Visible=false _cls()
			_tsf:Create(_fu,TweenInfo.new(0.5),{ImageTransparency=1}):Play()
			game.SoundService.Wanted.SuperIncrease:Stop()
			task.wait(1)_se:Stop()
		end
	end
	_uw()
	_plf:GetAttributeChangedSignal("Wanted"):Connect(_uw)
	_plf:GetAttributeChangedSignal("WantedBank"):Connect(_uw)
end

do
	local Players = game:GetService("Players")
	local UIS = game:GetService("UserInputService")
	local RS = game:GetService("ReplicatedStorage")
	local LocalPlayer = Players.LocalPlayer
	local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
	local Events = RS:WaitForChild("GameSettings"):WaitForChild("Events")
	local getFn = Events:WaitForChild("TouchLayoutGet")
	local setEv = Events:WaitForChild("TouchLayoutSet")
	local DRAGGABLE = {
		ShootButton=true, AimButton=true, ReloadButton=true, PauseButton=true,
		SprintButton=true, FlashlightButton=true, CrouchButton=true, JumpButton=true,
		LaserButton=true, AmmoButton=true, ModeButton=true, LeanLeft=true, LeanRight=true,
	}
	local savedLayout = nil
	local defaults = {}
	local editing = false
	local overlayFrame = nil
	local activeTouchUI = nil
	local dragging = nil
	local prevTouchVisible = nil
	local function viewport()
		local cam = workspace.CurrentCamera
		local v = cam and cam.ViewportSize or Vector2.new(1, 1)
		if v.X <= 0 or v.Y <= 0 then return Vector2.new(1, 1) end
		return v
	end
	local function eachButton(ui, fn)
		for _, b in ipairs(ui:GetChildren()) do
			if (b:IsA("TextButton") or b:IsA("ImageButton")) and DRAGGABLE[b.Name] then
				fn(b)
			end
		end
	end
	local function contentRegion(ui)
		local ox, oy = ui.AbsolutePosition.X, ui.AbsolutePosition.Y
		local w, h = ui.AbsoluteSize.X, ui.AbsoluteSize.Y
		local pad = ui:FindFirstChildOfClass("UIPadding")
		if pad then
			local pl = pad.PaddingLeft.Offset + pad.PaddingLeft.Scale * w
			local pr = pad.PaddingRight.Offset + pad.PaddingRight.Scale * w
			local pt = pad.PaddingTop.Offset + pad.PaddingTop.Scale * h
			local pb = pad.PaddingBottom.Offset + pad.PaddingBottom.Scale * h
			ox = ox + pl; oy = oy + pt
			w = w - pl - pr; h = h - pt - pb
		end
		if w <= 0 then w = 1 end
		if h <= 0 then h = 1 end
		return ox, oy, w, h
	end
	local function frameLocal(ui, screenX, screenY)
		local ox, oy, w, h = contentRegion(ui)
		return UDim2.fromScale((screenX - ox) / w, (screenY - oy) / h)
	end
	local function captureDefaults(ui)
		eachButton(ui, function(b)
			if defaults[b.Name] == nil then defaults[b.Name] = b.Position end
		end)
	end
	local function applyLayout(ui)
		captureDefaults(ui)
		if not savedLayout then return end
		local vp = viewport()
		eachButton(ui, function(b)
			local p = savedLayout[b.Name]
			if p then
				b.Position = frameLocal(ui, p[1] * vp.X, p[2] * vp.Y)
			end
		end)
	end
	local function waitReady(ui, cb)
		task.spawn(function()
			local t0 = os.clock()
			while ui.Parent and ui.AbsoluteSize.X <= 0 and os.clock() - t0 < 5 do
				task.wait()
			end
			if ui.Parent then cb() end
		end)
	end
	local function hook(ui)
		editing = false
		dragging = nil
		overlayFrame = nil
		activeTouchUI = ui
		waitReady(ui, function() applyLayout(ui) end)
	end
	task.spawn(function()
		local ok, res = pcall(function() return getFn:InvokeServer() end)
		if ok and type(res) == "table" then savedLayout = res end
		if activeTouchUI and activeTouchUI.Parent then
			waitReady(activeTouchUI, function() applyLayout(activeTouchUI) end)
		end
	end)
	local function startEdit()
		local ui = activeTouchUI
		if not ui or not ui.Parent then
			local sph = PlayerGui:FindFirstChild("SPH_UI")
			ui = sph and sph:FindFirstChild("TouchPadUI")
		end
		if not ui then return end
		activeTouchUI = ui
		captureDefaults(ui)
		if overlayFrame then overlayFrame:Destroy() end
		editing = true
		prevTouchVisible = ui.Visible
		ui.Visible = true
		overlayFrame = Instance.new("Frame")
		overlayFrame.Name = "_ButtonEditOverlay"
		overlayFrame.BackgroundTransparency = 1
		overlayFrame.Size = UDim2.fromScale(1, 1)
		overlayFrame.Position = UDim2.fromScale(0, 0)
		overlayFrame.ZIndex = 50
		overlayFrame.Parent = ui
		eachButton(ui, function(b)
			local hnd = Instance.new("ImageButton")
			hnd.Name = "_h_" .. b.Name
			hnd.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
			hnd.BackgroundTransparency = 0.4
			hnd.BorderSizePixel = 0
			hnd.AutoButtonColor = false
			hnd.Active = true
			hnd.AnchorPoint = b.AnchorPoint
			hnd.Position = b.Position
			hnd.Size = b.Size
			hnd.ZIndex = 60
			hnd.Parent = overlayFrame
			local uic = Instance.new("UICorner")
			uic.CornerRadius = UDim.new(0, 6)
			uic.Parent = hnd
			hnd.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
					local aX = b.AbsolutePosition.X + b.AnchorPoint.X * b.AbsoluteSize.X
					local aY = b.AbsolutePosition.Y + b.AnchorPoint.Y * b.AbsoluteSize.Y
					dragging = { h = hnd, b = b, gdx = input.Position.X - aX, gdy = input.Position.Y - aY }
				end
			end)
		end)
	end
	local function stopEdit()
		editing = false
		dragging = nil
		if overlayFrame then overlayFrame:Destroy() overlayFrame = nil end
		if activeTouchUI and activeTouchUI.Parent and prevTouchVisible ~= nil then
			activeTouchUI.Visible = prevTouchVisible
		end
		prevTouchVisible = nil
	end
	UIS.InputChanged:Connect(function(input)
		if not editing or not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		local ui = activeTouchUI
		if not ui or not ui.Parent then return end
		local vp = viewport()
		local sx = math.clamp(input.Position.X - dragging.gdx, 0, vp.X)
		local sy = math.clamp(input.Position.Y - dragging.gdy, 0, vp.Y)
		local np = frameLocal(ui, sx, sy)
		dragging.b.Position = np
		dragging.h.AnchorPoint = dragging.b.AnchorPoint
		dragging.h.Position = np
	end)
	UIS.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
			dragging = nil
		end
	end)
	_G.SetTouchEditMode = function(on)
		if on then startEdit() else stopEdit() end
	end
	_G.SaveTouchButtons = function()
		local ui = activeTouchUI
		if not ui or not ui.Parent then return end
		local vp = viewport()
		local layout = {}
		eachButton(ui, function(b)
			local aX = b.AbsolutePosition.X + b.AnchorPoint.X * b.AbsoluteSize.X
			local aY = b.AbsolutePosition.Y + b.AnchorPoint.Y * b.AbsoluteSize.Y
			layout[b.Name] = { aX / vp.X, aY / vp.Y }
		end)
		savedLayout = layout
		pcall(function() setEv:FireServer("save", layout) end)
	end
	_G.ResetTouchButtons = function()
		savedLayout = nil
		pcall(function() setEv:FireServer("reset") end)
		local ui = activeTouchUI
		if ui and ui.Parent then
			eachButton(ui, function(b)
				if defaults[b.Name] then b.Position = defaults[b.Name] end
			end)
		end
		if editing then stopEdit() startEdit() end
	end
	local function watch(sph)
		local ui = sph:FindFirstChild("TouchPadUI")
		if ui then hook(ui) end
		sph.ChildAdded:Connect(function(c) if c.Name == "TouchPadUI" then hook(c) end end)
	end
	local sphNow = PlayerGui:FindFirstChild("SPH_UI")
	if sphNow then watch(sphNow) end
	PlayerGui.ChildAdded:Connect(function(c)
		if c.Name == "SPH_UI" then watch(c) end
	end)
end

do
	local UIS = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local GuiService = game:GetService("GuiService")
	local player = game:GetService("Players").LocalPlayer
	if UIS.TouchEnabled then
		local locking = false
		RunService.RenderStepped:Connect(function()
			if not UIS.MouseEnabled then
				if locking then
					UIS.MouseBehavior = Enum.MouseBehavior.Default
					locking = false
				end
				return
			end
			local want = (player.CameraMode == Enum.CameraMode.LockFirstPerson) and (not GuiService.MenuIsOpen)
			if want then
				if UIS.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
					UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
				end
				locking = true
			elseif locking then
				UIS.MouseBehavior = Enum.MouseBehavior.Default
				locking = false
			end
		end)
	end
end

local _MERGED_CLIENTS_=true

task.spawn(function()
	local RS=game:GetService("ReplicatedStorage")
	local Debris=game:GetService("Debris")
	local SoundService=game:GetService("SoundService")

	local GuiParticle=require(RS.GameSettings.Modules.GuiParticle)
	local emitVFX=require(RS.GameSettings.Modules.emitVFX)
	local TweenService=game:GetService("TweenService")
	local Lighting=game:GetService("Lighting")
	local MarketplaceService=game:GetService("MarketplaceService")

	local function screenRobuxEffect()
		task.wait(0.325)
		local p=GuiParticle.new(UDim2.fromScale(0.5,0.5),RS.GameSettings.Assets.VisualEffect.Robux)
		emitVFX(p,true)
		Debris:AddItem(p,3)
	end

	local blurTI=TweenInfo.new(0.4)
	local blurOff=nil
	local function setPurchaseBlur(on)
		local b=Lighting:FindFirstChild("GuiBlurBackground")
		local c=Lighting:FindFirstChild("GuiColorBackground")
		if b then TweenService:Create(b,blurTI,{Size=on and 18 or 0}):Play() end
		if c then TweenService:Create(c,blurTI,{TintColor=on and Color3.fromRGB(150,150,150) or Color3.fromRGB(255,255,255)}):Play() end
		if blurOff then task.cancel(blurOff) blurOff=nil end
		if on then

			blurOff=task.delay(30,function() blurOff=nil setPurchaseBlur(false) end)
		end
	end

	SoundService.Shop.Ding.Played:Connect(function()
		screenRobuxEffect()
		setPurchaseBlur(true)
	end)
	MarketplaceService.PromptProductPurchaseFinished:Connect(function() setPurchaseBlur(false) end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function() setPurchaseBlur(false) end)

	game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt, plr)
		if plr ~= game:GetService("Players").LocalPlayer then return end
		if prompt.Name == "Robux"
			or prompt:GetAttribute("NukePrompt") or prompt:GetAttribute("GunPrompt") or prompt:GetAttribute("RiotPrompt") then
			pcall(function() SoundService.Shop.ButtonClick:Play() SoundService.Shop.Ding:Play() end)
		end
	end)

	local robuxFeedback = RS.GameSettings.Events:FindFirstChild("RobuxFeedback")
	if robuxFeedback then
		robuxFeedback.OnClientEvent:Connect(function()
			pcall(function() SoundService.Shop.ButtonClick:Play() SoundService.Shop.Ding:Play() end)
		end)
	end

	task.spawn(function()
		local deco = workspace:FindFirstChild("โมเดลทั้งหมด") or workspace
		for _ = 1, 30 do
			for _, d in ipairs(workspace:GetDescendants()) do
				if d:IsA("ClickDetector") and d.Parent and d.Parent.Name == "Cup"
					and d.Parent.Parent and d.Parent.Parent.Name == "Donate" then
					d.MouseClick:Connect(function(pl)
						if pl == game:GetService("Players").LocalPlayer then
							pcall(function() SoundService.Shop.ButtonClick:Play() SoundService.Shop.Ding:Play() end)
						end
					end)
					return
				end
			end
			task.wait(1)
		end
	end)

end)

task.spawn(function()
	local RS=game:GetService("ReplicatedStorage")
	local TweenService=game:GetService("TweenService")
	local RunService=game:GetService("RunService")
	local Players=game:GetService("Players")
	local MarketplaceService=game:GetService("MarketplaceService")
	local Lighting=game:GetService("Lighting")

	local LocalPlayer=Players.LocalPlayer
	LocalPlayer:WaitForChild("PlayerGui")

	local Config=require(RS.GameSettings.Groups.MapConfig)
	local PW=Config.PRIZE_WHEEL
	if not PW then return end

	local Events=RS.GameSettings.Events
	local spinFn=Events:WaitForChild("PrizeWheelSpin")
	local stateEv=Events:WaitForChild("PrizeWheelState")
	local spinDoneEv=Events:WaitForChild("PrizeWheelSpinDone")

	local SpinnerAssets=RS.GameSettings.Assets:WaitForChild("SpinnerAssets")
	local Sounds=SpinnerAssets:WaitForChild("Sounds")

	local wheelModel=workspace:WaitForChild("โมเดลทั้งหมด"):WaitForChild("วงล้อโชคดี"):WaitForChild("PrizeWheel")
	local prizes=wheelModel:WaitForChild("Prizes")
	local root=prizes:WaitForChild("Root")
	local root2=prizes:WaitForChild("Root2")
	local dart=prizes:WaitForChild("Dart")
	local segments=prizes:WaitForChild("Segments")
	local prompt=root2.att:WaitForChild("ProximityPrompt")

	local baseCFrame=root.CFrame

	local BlurEffect=Lighting:FindFirstChild("PrizeWheelBlur")
	if not BlurEffect then
		BlurEffect=Instance.new("BlurEffect")
		BlurEffect.Size=0
		BlurEffect.Name="PrizeWheelBlur"
		BlurEffect.Parent=Lighting
	end

	local totalRarity=0
	for _,data in pairs(PW.REWARDS) do totalRarity+=data.Rarity end

	for key,data in pairs(PW.REWARDS) do
		local seg=segments:FindFirstChild(key)
		if seg then
			local gui=seg:FindFirstChild("SurfaceGui")
			local img=gui and gui:FindFirstChild("ImageLabel")
			local textLabel=img and img:FindFirstChild("TextLabel")
			local rarityText=img and img:FindFirstChild("RarityText")
			if textLabel then textLabel.Text=data.Name end
			if rarityText then
				local pct=data.Rarity*100/totalRarity
				rarityText.Text=string.format("%.1f",pct):gsub("%.0$","").. "%"
			end
		end
	end

	local highlightedParts={}
	for _,seg in ipairs(segments:GetChildren()) do
		if seg.Name~="Root" and seg:FindFirstChild("SegmentHighlight") then
			table.insert(highlightedParts,seg)
		end
	end

	local rayParams=RaycastParams.new()
	rayParams.FilterType=Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances=highlightedParts

	local spinning=false
	local currentAngle=0
	local lastHitPart=nil
	local renderConn=nil
	local nearEnd=false
	local lastHighlighted=nil

	local function updateDartHighlight()
		local worldPosA=dart.RaypointA.WorldPosition
		local dirVec=(dart.RaypointB.WorldPosition-dart.RaypointA.WorldPosition).Unit*10
		local result=workspace:Raycast(worldPosA,dirVec,rayParams)
		if result then
			if lastHitPart and lastHitPart~=result.Instance then
				local particleAtt=dart:FindFirstChild("Particle")
				local particleEmitter=particleAtt and particleAtt:FindFirstChild("ParticleEmitter")
				if particleEmitter then particleEmitter:Emit(1) end
				lastHitPart.SegmentHighlight.Enabled=false
				Sounds.select:Play()
			end
			if lastHighlighted~=result.Instance then
				lastHighlighted=result.Instance
				result.Instance.SegmentHighlight.FillTransparency=0.2
				TweenService:Create(result.Instance.SegmentHighlight,TweenInfo.new(0.25),{FillTransparency=1}):Play()
				if nearEnd then
					Sounds.select2:Play()
				end
			end
			lastHitPart=result.Instance
			lastHitPart.SegmentHighlight.Enabled=true
		end
	end

	local function playSpin(segmentKey)
		if spinning then return end
		spinning=true

		local camera=workspace.CurrentCamera
		prompt.Enabled=false
		camera.CameraType=Enum.CameraType.Scriptable
		camera.CFrame=CFrame.lookAt((baseCFrame*CFrame.new(0,0,-13)).Position,root.Position)
		root.particles.activated:Emit(1)

		for _,seg in ipairs(highlightedParts) do
			seg:SetAttribute("Blinked",false)
			local hl=seg:FindFirstChild("SegmentHighlight")
			if hl then hl.Enabled=false end
		end

		nearEnd=false
		lastHitPart=nil
		lastHighlighted=nil

		local segIndex=tonumber(segmentKey:match("%d+")) or 1
		local segCount=PW.SEGMENT_COUNT
		local segAngle=360/segCount
		local indexFromEnd=segCount+1-segIndex
		local loBound=(indexFromEnd-1)*segAngle+PW.SEGMENT_OFFSET
		local hiBound=indexFromEnd*segAngle-PW.SEGMENT_OFFSET
		local baseSpins=PW.SPIN_SPEED*360*PW.SPIN_DURATION
		local targetOffset=(math.random(loBound,hiBound)-currentAngle%360)%360
		local deltaAngle=baseSpins+targetOffset

		local numberValue=Instance.new("NumberValue")
		numberValue.Value=currentAngle

		renderConn=RunService.RenderStepped:Connect(function()
			currentAngle=numberValue.Value
			root.CFrame=baseCFrame*CFrame.Angles(0,0,math.rad(currentAngle))
			segments:PivotTo(root.CFrame)
			updateDartHighlight()
		end)

		local tween=TweenService:Create(numberValue,TweenInfo.new(PW.SPIN_DURATION,Enum.EasingStyle.Quint),{Value=currentAngle+deltaAngle})
		tween.Completed:Connect(function()
			if renderConn then renderConn:Disconnect() renderConn=nil end
			numberValue:Destroy()
			currentAngle=(currentAngle+deltaAngle)%360
			camera.CameraType=Enum.CameraType.Custom
			prompt.Enabled=true
		end)
		tween:Play()
		Sounds.spin:Play()

		task.delay(PW.SPIN_DURATION-5,function()
			nearEnd=true
		end)

		local camTween=TweenService:Create(camera,TweenInfo.new(PW.SPIN_DURATION-2),{
			CFrame=CFrame.lookAt((baseCFrame*CFrame.new(0,1,-8)).Position,(baseCFrame*CFrame.new(0,1,0)).Position)
		})
		camTween:Play()
		task.wait(PW.SPIN_DURATION*0.75)
		camTween:Cancel()
		nearEnd=false
		spinning=false
		Sounds.reward_display:Play()
		spinDoneEv:FireServer()
	end

	prompt.Triggered:Connect(function(player)
		if player~=LocalPlayer then return end
		if spinning then return end

		local result=spinFn:InvokeServer()
		if not result then
			local spinProductId=PW.SPIN_PRODUCT_ID
			if spinProductId and spinProductId~=0 then
				pcall(function()
					pcall(function() local S=game:GetService("SoundService").Shop S.ButtonClick:Play() S.Ding:Play() end)
					MarketplaceService:PromptProductPurchase(LocalPlayer,spinProductId)
				end)
			end
			return
		end

		playSpin(result)
	end)

	local spinsLeftLabel
	for _,child in ipairs(wheelModel:GetChildren()) do
		if child.Name=="SpinWheelPart" then
			local attachment=child:FindFirstChild("Attachment")
			local billboardGui=attachment and attachment:FindFirstChild("BillboardGui")
			if billboardGui then
				spinsLeftLabel=billboardGui:FindFirstChild("SpinsLeftLabel")
				break
			end
		end
	end

	stateEv.OnClientEvent:Connect(function(payload)
		if spinsLeftLabel and payload then
			spinsLeftLabel.Text="เหลือ: "..tostring((payload.free or 0)+(payload.paid or 0))
		end
	end)

end)

task.spawn(function()
	local Players = game:GetService("Players")
	local CS = game:GetService("CollectionService")
	local RS = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")

	local Config = require(RS.GameSettings.Groups.MapConfig)
	local PX = Config.PX_SHOP
	if not PX or not PX.ENABLED then return end

	local LocalPlayer = Players.LocalPlayer
	local Events = RS.GameSettings.Events
	local ToggleShop = Events:WaitForChild("ToggleShop", 60)

	local shopFolder = workspace:WaitForChild(PX.FOLDER_NAME, 60)
	if not shopFolder then return end

	local itemShop = shopFolder:WaitForChild("ItemShop", 30)

	local function setCartPromptText(hasCart)
		for _, prompt in ipairs(CS:GetTagged("CartPrompt")) do
			if prompt:IsDescendantOf(shopFolder) then
				prompt.ActionText = hasCart and PX.CART_RETURN_TEXT or PX.CART_TAKE_TEXT
			end
		end
	end

	local function bindCharacter(character)
		setCartPromptText(character:GetAttribute("HasCart") == true)
		character:GetAttributeChangedSignal("HasCart"):Connect(function()
			setCartPromptText(character:GetAttribute("HasCart") == true)
		end)
	end

	LocalPlayer.CharacterAdded:Connect(bindCharacter)
	if LocalPlayer.Character then
		task.spawn(bindCharacter, LocalPlayer.Character)
	end

	CS:GetInstanceAddedSignal("CartPrompt"):Connect(function()
		local char = LocalPlayer.Character
		setCartPromptText(char and char:GetAttribute("HasCart") == true)
	end)

	local shopOpen = false

	local function getMainFrame()
		local gui = LocalPlayer.PlayerGui:FindFirstChild("ShopGui")
		return gui and gui:FindFirstChild("MainFrame")
	end

	local function openShop()
		if shopOpen then return end
		local frame = getMainFrame()
		if not frame or not _G.ShowShopFrame then return end
		shopOpen = true
		workspace:SetAttribute("ShopGuiOpenedTopbar", true)
		_G.ShowShopFrame(frame)
	end

	local function closeShop()
		if not shopOpen then return end
		shopOpen = false
		workspace:SetAttribute("ShopGuiOpenedTopbar", false)
		local frame = getMainFrame()
		if _G.ShowShopFrame and _G.LastShownFrame == frame then
			_G.ShowShopFrame(nil)
		end
	end

	if ToggleShop then
		ToggleShop.OnClientEvent:Connect(function(state)
			if state then openShop() else closeShop() end
		end)
	end

	if itemShop then
		task.spawn(function()
			while true do
				task.wait(0.25)
				if shopOpen then
					local char = LocalPlayer.Character
					local root = char and char:FindFirstChild("HumanoidRootPart")
					if not root then
						closeShop()
					else
						local pivot = itemShop:GetPivot().Position
						if (root.Position - pivot).Magnitude > PX.PROMPT_DISTANCE + 8 then
							closeShop()
						elseif _G.LastShownFrame ~= getMainFrame() then
							shopOpen = false
							workspace:SetAttribute("ShopGuiOpenedTopbar", false)
						end
					end
				end
			end
		end)
	end

end)

task.spawn(function()

	local Players = game:GetService("Players")
	local RS = game:GetService("ReplicatedStorage")
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")

	local LocalPlayer = Players.LocalPlayer
	local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

	local gui = PlayerGui:WaitForChild("MobileShiftLockGui", 30)
	if not gui then return end
	local crosshair = gui:FindFirstChild("Center")
	if not crosshair then return end
	crosshair.Visible = false

	local function isLockedView()
		if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
			return false
		end
		local camera = workspace.CurrentCamera
		local char = LocalPlayer.Character
		local head = char and char:FindFirstChild("Head")
		if camera and head then
			if (camera.CFrame.Position - head.Position).Magnitude < 1.5 then
				return false
			end
		end
		return true
	end

	local mobileEnabled = false

	local function applyMobileLock(state)
		mobileEnabled = state and true or false
		local char = LocalPlayer.Character
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")

		if mobileEnabled then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			if humanoid then
				humanoid.AutoRotate = false
				humanoid.CameraOffset = Vector3.new(1.75, 0, 0)
			end
		else
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			if humanoid then
				humanoid.AutoRotate = true
				humanoid.CameraOffset = Vector3.new(0, 0, 0)
			end
		end
	end

	-- Hide default Roblox ShiftLock button / disable default mouse lock UI
	pcall(function()
		local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts", 10)
		local PlayerModule = PlayerScripts and PlayerScripts:WaitForChild("PlayerModule", 10)
		local CameraModule = PlayerModule and PlayerModule:WaitForChild("CameraModule", 10)
		local MouseLockController = CameraModule and CameraModule:WaitForChild("MouseLockController", 10)
		if MouseLockController then
			local boundKeys = MouseLockController:FindFirstChild("BoundKeys")
			if boundKeys then boundKeys.Value = "" end
		end
	end)

	local iconModule
	local gs = RS:FindFirstChild("GameSettings")
	if gs and gs:FindFirstChild("Modules") then
		iconModule = gs.Modules:FindFirstChild("Icon")
	end
	if not iconModule and RS:FindFirstChild("Modules") then
		iconModule = RS.Modules:FindFirstChild("TopbarPlus") or RS.Modules:FindFirstChild("Icon")
	end

	local okIcon, Icon
	if iconModule then
		okIcon, Icon = pcall(require, iconModule)
	end

	if okIcon and typeof(Icon) == "table" then
		local icon = Icon.new()
		icon:setName("ShiftLock")
		icon:setImage("rbxassetid://106884084091476")
		icon:setImageScale(0.6)
		icon:align("Right")
		icon:autoDeselect(false)

		local lastToggle = 0
		local function toggle()
			local now = os.clock()
			if now - lastToggle < 0.25 then return end
			lastToggle = now
			applyMobileLock(not mobileEnabled)
		end

		icon:bindEvent("selected", toggle)
		icon:bindEvent("deselected", toggle)

		task.spawn(function()
			local region
			for _ = 1, 60 do
				for _, gname in ipairs({"TopbarStandard", "TopbarCentered"}) do
					local g = PlayerGui:FindFirstChild(gname)
					local holders = g and g:FindFirstChild("Holders")
					if holders then
						for _, side in ipairs(holders:GetChildren()) do
							if side:IsA("GuiObject") then
								local w = side:FindFirstChild("ShiftLock")
								if w then region = w:FindFirstChild("ClickRegion", true) end
							end
						end
					end
				end
				if region then break end
				task.wait(0.25)
			end
			if region and region:IsA("GuiButton") then
				region.MouseButton1Click:Connect(toggle)
			end
		end)

		RunService:BindToRenderStep("MobileShiftLockStep", Enum.RenderPriority.Camera.Value + 1, function()
			if not mobileEnabled then return end
			local char = LocalPlayer.Character
			local humanoid = char and char:FindFirstChildOfClass("Humanoid")
			if not humanoid or humanoid.Health <= 0 then return end
			local root = char:FindFirstChild("HumanoidRootPart")
			if not root then return end

			if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			end

			if humanoid.CameraOffset ~= Vector3.new(1.75, 0, 0) then
				humanoid.CameraOffset = Vector3.new(1.75, 0, 0)
			end

			local look = workspace.CurrentCamera.CFrame.LookVector
			local flat = Vector3.new(look.X, 0, look.Z)
			if flat.Magnitude > 0.001 then
				local targetCFrame = CFrame.lookAt(root.Position, root.Position + flat.Unit)
				root.CFrame = targetCFrame
			end
		end)
	end

	RunService.RenderStepped:Connect(function()
		local active = mobileEnabled or isLockedView()
		if crosshair.Visible ~= active then
			crosshair.Visible = active
		end
	end)

	local function watch(char)
		local hum = char:WaitForChild("Humanoid", 10)
		if hum then
			hum.Died:Connect(function()
				crosshair.Visible = false
				if mobileEnabled then
					UserInputService.MouseBehavior = Enum.MouseBehavior.Default
					hum.CameraOffset = Vector3.new(0, 0, 0)
				end
			end)
		end
	end

	if LocalPlayer.Character then
		task.spawn(watch, LocalPlayer.Character)
	end

	LocalPlayer.CharacterAdded:Connect(function(char)
		watch(char)
		task.wait(0.5)
		applyMobileLock(mobileEnabled)
	end)

end)

task.spawn(function()
	local Players = game:GetService("Players")
	local ContextActionService = game:GetService("ContextActionService")
	local RS = game:GetService("ReplicatedStorage")

	local LocalPlayer = Players.LocalPlayer

	local FREEZE_ACTION = "PXFreezeMovement"

	local BackpackModule = nil
	local backpackTried = false

	local function getBackpackModule()
		if backpackTried then return BackpackModule end
		backpackTried = true
		local modules = RS:FindFirstChild("GameSettings")
		modules = modules and modules:FindFirstChild("Modules")
		local moduleScript = modules and modules:FindFirstChild("Backpack")
		if moduleScript then
			local ok, result = pcall(require, moduleScript)
			if ok then BackpackModule = result end
		end
		return BackpackModule
	end

	local function setBackpack(enabled)
		task.spawn(function()
			local mod = getBackpackModule()
			if mod and typeof(mod.SetBackpackEnabled) == "function" then
				pcall(function()
					mod:SetBackpackEnabled(enabled and true or false)
				end)
			end
		end)
	end

	local function onCharacterAdded(character)
		local humanoid = character:WaitForChild("Humanoid")
		local root = character:WaitForChild("HumanoidRootPart", 5)

		humanoid:SetAttribute("RagdollEnabled", false)
		setBackpack(true)
		ContextActionService:UnbindAction(FREEZE_ACTION)

		humanoid.AttributeChanged:Connect(function(name)
			if name ~= "RagdollEnabled" then return end
			if character:FindFirstChildOfClass("ForceField") then return end

			if humanoid:GetAttribute("RagdollEnabled") then
				setBackpack(false)
				humanoid:UnequipTools()
				humanoid:ChangeState(Enum.HumanoidStateType.Physics)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
				ContextActionService:BindAction(FREEZE_ACTION, function()
					return Enum.ContextActionResult.Sink
				end, false, unpack(Enum.PlayerActions:GetEnumItems()))

				local impulse = humanoid:GetAttribute("RagdollVelocity")
				if root and typeof(impulse) == "Vector3" and impulse.Magnitude > 0 then
					root:ApplyImpulse(impulse * root.AssemblyMass)
				end
			else
				setBackpack(true)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
				humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
				humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
				ContextActionService:UnbindAction(FREEZE_ACTION)
			end
		end)
	end

	LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
	if LocalPlayer.Character then
		task.spawn(onCharacterAdded, LocalPlayer.Character)
	end

end)

task.spawn(function()
	local Players=game:GetService("Players")
	local RS=game:GetService("ReplicatedStorage")

	local Config=require(RS.GameSettings.Groups.MapConfig)
	local KE=Config.AIRDROP
	if not KE or not KE.ENABLED then return end

	local LocalPlayer=Players.LocalPlayer

	do
		local Airdrop=Config.AIRDROP
		if Airdrop and Airdrop.ENABLED then
			task.spawn(function()
				local node=workspace
				for _,seg in ipairs(Airdrop.PROMPT_PATH) do
					node=node:WaitForChild(seg,30)
					if not node then return end
				end
				local promptAtt=node:WaitForChild("Product",10)
				promptAtt=promptAtt and promptAtt:WaitForChild("Main",10)
				promptAtt=promptAtt and promptAtt:WaitForChild("PromptAtt",10)
				if not promptAtt then return end
				local SoundService=game:GetService("SoundService")
				local Shop=SoundService:FindFirstChild("Shop")
				local function playRobuxFeedback()
					if Shop then
						local bc=Shop:FindFirstChild("ButtonClick")
						local ding=Shop:FindFirstChild("Ding")
						if bc then bc:Play() end
						if ding then ding:Play() end
					end
				end
				local robux=promptAtt:FindFirstChild("Robux")
				if robux then robux.Triggered:Connect(function(p) if p==LocalPlayer then playRobuxFeedback() end end) end
			end)
		end
	end

	local Modules=RS.GameSettings:WaitForChild("Modules")
	local KillEffects=Modules:WaitForChild("KillEffects",30)
	if not KillEffects then return end

	local root=workspace:WaitForChild("โมเดลทั้งหมด",60)
	if not root then return end
	local gunFolder=root:WaitForChild("ปืน",60)
	if not gunFolder then return end
	local bodies=gunFolder:WaitForChild("Bodies",60)
	if not bodies then return end

	local recent={}

	local function canPlay()
		local now=os.clock()
		local i=1
		while i<=#recent do
			if now-recent[i]>1 then
				table.remove(recent,i)
			else
				i+=1
			end
		end
		if #recent>=5 then return false end
		table.insert(recent,now)
		return true
	end

	local function onCorpse(corpse)
		if not corpse:IsA("Model") then return end
		local hum=corpse:FindFirstChildOfClass("Humanoid")
		if not hum then
			hum=corpse:WaitForChild("Humanoid",2)
		end
		if not hum then return end

		local creator=hum:FindFirstChild("creator")
		if not creator then
			creator=hum:WaitForChild("creator",1)
		end
		if not creator or not creator.Value then return end

		local killer=creator.Value
		if not killer:IsA("Player") then return end

		local moduleName=killer:GetAttribute("KillEffect")
		if not moduleName then return end

		local mod=KillEffects:FindFirstChild(moduleName)
		if not mod then return end

		local primary=corpse:FindFirstChild("Torso") or corpse:FindFirstChild("UpperTorso") or corpse:FindFirstChild("HumanoidRootPart")
		if not primary then return end

		local cam=workspace.CurrentCamera
		if cam and (primary.Position-cam.CFrame.Position).Magnitude>200 and killer~=LocalPlayer then return end

		if not canPlay() then return end

		local ok,fn=pcall(require,mod)
		if not ok or type(fn)~="function" then return end
		task.spawn(function()
			pcall(fn,corpse)
		end)
	end

	bodies.ChildAdded:Connect(onCorpse)

end)

task.spawn(function()

	local Players        = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local TweenService   = game:GetService("TweenService")
	local Debris         = game:GetService("Debris")

	local player = Players.LocalPlayer

	local bridgeNet   = require(ReplicatedStorage.GameSettings.Modules.BridgeNet)
	local hitFeedback = bridgeNet.CreateBridge("HitFeedback")

	local CHEVRON     = "rbxassetid://78472943642086"
	local HEAD_COLOR  = Color3.new(1, 0.129412, 0.129412)
	local BODY_COLOR  = Color3.new(1, 1, 1)
	local NUM_HEAD_COLOR = Color3.fromRGB(255, 33, 33)

	local SND_HEAD = "rbxassetid://8255306220"
	local SND_BODY = "rbxassetid://3748776946"

	local DEBOUNCE = 0.12

	local LAYOUT = {
		{rot =   0, pos = UDim2.fromScale( 0.5, -0.1), anc = Vector2.new(0.5, 0  )},
		{rot = -90, pos = UDim2.fromScale(-0.1,  0.5), anc = Vector2.new(0,   0.5)},
		{rot =  90, pos = UDim2.fromScale( 0.6,  0.5), anc = Vector2.new(0,   0.5)},
		{rot = 180, pos = UDim2.fromScale( 0.5,  0.6), anc = Vector2.new(0.5, 0  )},
	}

	local function makeMarker(scale, minPx, color, imgTransparency)
		local f = Instance.new("Frame")
		f.Name = "PXHitMarker"
		f.BackgroundTransparency = 1

		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromScale(0.5, 0.5)
		f.Size = UDim2.fromScale(scale, scale)
		f.ZIndex = 11

		local ar = Instance.new("UIAspectRatioConstraint")
		ar.AspectRatio = 1
		ar.Parent = f

		local sc = Instance.new("UISizeConstraint")
		sc.MinSize = Vector2.new(minPx, minPx)
		sc.Parent = f

		for _, d in ipairs(LAYOUT) do
			local img = Instance.new("ImageLabel")
			img.BackgroundTransparency = 1
			img.Image = CHEVRON
			img.ImageColor3 = color
			img.ImageTransparency = imgTransparency
			img.Size = UDim2.fromScale(0.5, 0.5)
			img.Rotation = d.rot
			img.Position = d.pos
			img.AnchorPoint = d.anc
			img.ZIndex = 11
			img.Parent = f
		end
		return f
	end

	local headMarker = makeMarker(0.15, 90, HEAD_COLOR, 0.35)
	local bodyMarker = makeMarker(0.10, 60, BODY_COLOR, 0.5)

	local dmgTemplate = Instance.new("BillboardGui")
	dmgTemplate.Name = "DamageNumberGui"

	dmgTemplate.Size = UDim2.new(10, 0, 5, 0)
	dmgTemplate.AlwaysOnTop = true
	dmgTemplate.MaxDistance = math.huge
	dmgTemplate.LightInfluence = 1
	dmgTemplate.StudsOffset = Vector3.zero
	dmgTemplate.Enabled = false
	do
		local frame = Instance.new("Frame")
		frame.Name = "Frame"
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.fromScale(0.5, 0.5)
		frame.BackgroundTransparency = 1
		frame.Size = UDim2.fromScale(1, 1)
		frame.Parent = dmgTemplate

		local szc = Instance.new("UISizeConstraint")
		szc.MinSize = Vector2.new(30, 20)
		szc.MaxSize = Vector2.new(1e9, 35)
		szc.Parent = frame

		local label = Instance.new("TextLabel")
		label.Name = "TextLabel"
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextScaled = true
		label.TextWrapped = true
		label.TextSize = 17
		label.FontFace = Font.new("rbxassetid://11702779409", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
		label.Parent = frame

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1
		stroke.Color = Color3.new(0, 0, 0)
		stroke.Transparency = 0.75
		stroke.LineJoinMode = Enum.LineJoinMode.Round
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		stroke.Parent = label
	end

	local function getUI()
		local pg = player:FindFirstChild("PlayerGui")
		local sph = pg and pg:FindFirstChild("SPH_UI")
		if sph then
			return sph:FindFirstChild("CrosshairContainer") or sph
		end
		return nil
	end

	local function triggerBuiltinHitmarker(container, isHead)
		if not container then return end
		local color = isHead and Color3.fromRGB(255, 33, 33) or Color3.fromRGB(255, 255, 255)
		container.Visible = true
		for _, line in ipairs(container:GetChildren()) do
			if line:IsA("Frame") then
				line.BackgroundColor3 = color
				line.BackgroundTransparency = isHead and 0.1 or 0.2
			end
		end
		task.spawn(function()
			local fadeInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			for _, line in ipairs(container:GetChildren()) do
				if line:IsA("Frame") then
					TweenService:Create(line, fadeInfo, {BackgroundTransparency = 1}):Play()
				end
			end
			task.wait(0.2)
			container.Visible = false
		end)
	end

	local lastMarker, lastMarkerHead = 0, false

	local function hitmarker(isHead)
		local parent = getUI()
		if not parent then return end

		local builtin = parent:FindFirstChild("HitmarkerContainer")
		if builtin then
			triggerBuiltinHitmarker(builtin, isHead)
		end

		local m = (isHead and headMarker or bodyMarker):Clone()
		local target = m.Size
		m.Size = UDim2.fromScale(0, 0)
		m.Position = UDim2.fromScale(0.5, 0.5)
		m.Parent = parent

		local grow = TweenService:Create(m,
			TweenInfo.new(0.2, Enum.EasingStyle.Circular, Enum.EasingDirection.Out),
			{Size = target})
		grow:Play()
		grow.Completed:Wait()
		task.wait(0.01)

		local fadeInfo = TweenInfo.new(0.8, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
		for _, c in ipairs(m:GetChildren()) do
			if c:IsA("ImageLabel") then
				TweenService:Create(c, fadeInfo, {ImageTransparency = 1}):Play()
			end
		end
		Debris:AddItem(m, 1.5)
	end

	local function tryMarker(isHead)
		local now = os.clock()

		if now - lastMarker < DEBOUNCE and not (isHead and not lastMarkerHead) then return end
		lastMarker, lastMarkerHead = now, isHead
		task.spawn(hitmarker, isHead)
	end

	local lastSound, lastSoundHead = 0, false

	local function trySound(isHead)
		local now = os.clock()
		if now - lastSound < DEBOUNCE and not (isHead and not lastSoundHead) then return end
		lastSound, lastSoundHead = now, isHead

		local s = Instance.new("Sound")
		s.SoundId = isHead and SND_HEAD or SND_BODY
		s.Volume  = isHead and 2.5 or 3
		s.Parent  = script
		s:Play()
		Debris:AddItem(s, 5)
	end

	local dmgCache = setmetatable({}, {__mode = "k"})

	local function createDmgIndicator(character, damage, isHead)
		task.spawn(function()
			local head = character:FindFirstChild("Head")
			if not head then return end

			local prev = dmgCache[character]
			if prev then prev.Gui:Destroy() end
			local total = (prev and prev.Damage or 0) + damage

			local part = Instance.new("Part")
			part.Anchored   = true
			part.CanCollide = false
			part.CanQuery   = false
			part.CanTouch   = false
			part.Transparency = 1
			part.Size = Vector3.one
			part.Position = head.Position + Vector3.new(0, 2, 0)
			part.Parent = workspace

			local gui   = dmgTemplate:Clone()
			local frame = gui.Frame
			local label = frame.TextLabel
			local stroke = label.UIStroke
			gui.Enabled = true

			label.Text = tostring(-math.floor(total * 10) / 10)
			frame.Rotation = math.random(-15, 15)

			if isHead then
				label.TextColor3 = NUM_HEAD_COLOR
				stroke.Transparency = 0.6
			else
				stroke.Transparency = 0.75
			end

			dmgCache[character] = {Gui = part, Damage = total}
			gui.Parent = part

			local rotInfo = TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
			local rise = TweenService:Create(part,
				TweenInfo.new(0.75, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
				{Position = part.Position + Vector3.new(0, 3, 0)})
			local fadeText = TweenService:Create(label,
				TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{TextTransparency = 1})
			local fadeStroke = TweenService:Create(stroke,
				TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{Transparency = 1})

			TweenService:Create(frame, rotInfo, {Rotation = 0}):Play()
			rise:Play()
			task.wait(0.5)
			fadeText:Play()
			fadeStroke:Play()
			fadeStroke.Completed:Wait()

			if dmgCache[character] and dmgCache[character].Gui == part then
				dmgCache[character] = nil
			end
			part:Destroy()
		end)
	end

	local highlightBusy = setmetatable({}, {__mode = "k"})

	local function highlight(character)
		if highlightBusy[character] then return end
		highlightBusy[character] = true

		task.spawn(function()
			local hl = character:FindFirstChild("HitFeedbackHighlight")
			if not hl then
				hl = Instance.new("Highlight")
				hl.Name = "HitFeedbackHighlight"
				hl.DepthMode = Enum.HighlightDepthMode.Occluded
			end
			hl.FillColor = Color3.fromRGB(255, 217, 217)
			hl.OutlineColor = Color3.fromRGB(255, 64, 64)
			hl.FillTransparency = 0.3
			hl.OutlineTransparency = 0.5
			hl.Parent = character

			task.wait(0.05)
			if hl.Parent then
				local t1 = TweenService:Create(hl, TweenInfo.new(0.25), {
					FillTransparency = 0.5,
					OutlineTransparency = 0.75,
					FillColor = Color3.fromRGB(255, 64, 64),
				})
				t1:Play()
				t1.Completed:Wait()
			end
			if hl.Parent then
				local t2 = TweenService:Create(hl, TweenInfo.new(0.05), {
					FillTransparency = 1,
					OutlineTransparency = 1,
				})
				t2:Play()
				t2.Completed:Wait()
			end
			hl:Destroy()
			highlightBusy[character] = nil
		end)
	end

	hitFeedback:Connect(function(victim, damage, isHead)
		if typeof(victim) ~= "Instance" or not victim:IsA("Model") then return end
		if type(damage) ~= "number" then return end
		isHead = isHead == true

		trySound(isHead)
		tryMarker(isHead)
		highlight(victim)
		createDmgIndicator(victim, damage, isHead)
	end)

end)

task.spawn(function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local LocalizationService = game:GetService("LocalizationService")

	local LocalPlayer = Players.LocalPlayer

	local function countryCodeToFlag(code)
		if not code or #code ~= 2 then return "🇹🇭" end
		code = code:upper()
		local base = 0x1F1E6
		local a = utf8.char(base + (string.byte(code, 1) - string.byte("A")))
		local b = utf8.char(base + (string.byte(code, 2) - string.byte("A")))
		return a .. b
	end

	local Model = workspace["โมเดลทั้งหมด"]["ของตกแต่ง"]:WaitForChild("DailyPlaytime", 30)
	if not Model then return end
	local SurfaceGui = Model:WaitForChild("Main"):WaitForChild("Board"):WaitForChild("SurfaceGui")
	local ScrollingFrame = SurfaceGui:WaitForChild("ScrollingFrame")
	local RowTemplate = ReplicatedStorage:WaitForChild("GameSettings"):WaitForChild("Assets"):WaitForChild("Gui"):WaitForChild("GlobalLeaderboardLabel2")

	local function toHMS(seconds)
		local h = math.floor(seconds / 3600)
		local m = math.floor((seconds % 3600) / 60)
		local s = seconds % 60
		return string.format("%02i:%02i:%02i", h, m, s)
	end

	local function handlePlayerData()
		local pinnedRow = RowTemplate:Clone()
		pinnedRow.ProfileFrame.Icon.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%s&w=100&h=100", LocalPlayer.UserId)
		local pinnedCountry = pinnedRow.ProfileFrame.Icon:FindFirstChild("Country")
		if pinnedCountry then
			pinnedCountry.Text = "🇹🇭"
			task.spawn(function()
				local ok, code = pcall(function()
					return LocalizationService:GetCountryRegionForPlayerAsync(LocalPlayer)
				end)
				if ok and code then
					pinnedCountry.Text = countryCodeToFlag(code)
				end
			end)
		end
		pinnedRow.Username.Text = LocalPlayer.Name .. " (คุณ)"
		pinnedRow.Value.Text = toHMS(LocalPlayer:GetAttribute("DailyTotalPlaytime") or 0)
		pinnedRow.Visible = true
		pinnedRow.Parent = SurfaceGui

		for _, v2 in pairs(ScrollingFrame:GetChildren()) do
			if v2.Name == LocalPlayer.Name then
				pinnedRow.Rank.Text = "#" .. tostring(v2.LayoutOrder)
			end
		end

		Model:GetAttributeChangedSignal("UniqueId"):Connect(function()
			local row = ScrollingFrame:FindFirstChild(LocalPlayer.Name)
			if row then
				pinnedRow.Rank.Text = "#" .. tostring(row.LayoutOrder)
			else
				pinnedRow.Rank.Text = "#?"
			end
		end)

		LocalPlayer:GetAttributeChangedSignal("DailyTotalPlaytime"):Connect(function()
			pinnedRow.Value.Text = toHMS(LocalPlayer:GetAttribute("DailyTotalPlaytime") or 0)
		end)
	end

	handlePlayerData()

end)

task.spawn(function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Modules = ReplicatedStorage:WaitForChild("GameSettings"):WaitForChild("Modules")
	local CrateOpenModule = Modules:WaitForChild("CrateOpen", 60)
	if not CrateOpenModule then return end

	local CrateOpen = require(CrateOpenModule)

	local Events = ReplicatedStorage.GameSettings:WaitForChild("Events")
	local rollEv = Events:WaitForChild("KillEffectRoll", 60)
	if not rollEv then return end

	local function onCratePurchased(ids)
		CrateOpen(ids)
	end

	rollEv.OnClientEvent:Connect(onCratePurchased)

end)

task.spawn(function()
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local Lighting = game:GetService("Lighting")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local LocalPlayer = Players.LocalPlayer
	local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
	local Gui = PlayerGui:WaitForChild("CCTVGui")
	Gui.ResetOnSpawn = false
	local BackpackGui = PlayerGui:WaitForChild("BackpackGui")
	local CurrentCamera = workspace.CurrentCamera

	local Config = require(ReplicatedStorage.GameSettings.Groups.MapConfig)
	local CFG = Config.CCTV
	if not CFG or not CFG.ENABLED then return end

	local SEAT_NAME = "seat_cctv"
	local CAMERA_OFFSET = 5
	local NOISE_ENABLED = true
	local NOISE_TRANSPARENCY = 0.9
	local CONTRAST = 0.1
	local SATURATION = -1

	local noise = Gui:WaitForChild("noise")
	local cctvName = Gui:WaitForChild("cctvName")
	local siteBtn = Gui:WaitForChild("site")
	local leftBtn = Gui:WaitForChild("Left")
	local rightBtn = Gui:WaitForChild("Right")

	local CamFolder = workspace:WaitForChild("โมเดลทั้งหมด", 30):WaitForChild("กล้องวงจรปิด", 30)

	local effect = Lighting:FindFirstChild("_CCTVColorCorrection")
	if not effect then
		effect = Instance.new("ColorCorrectionEffect")
		effect.Name = "_CCTVColorCorrection"
		effect.Parent = Lighting
	end
	effect.TintColor = Color3.new(1, 1, 1)
	effect.Brightness = 0
	effect.Enabled = false

	local active = false
	local seated = false
	local index = 1
	local connections = {}
	local noiseConn = nil
	local backpackForceConn = nil

	local function guiVisible(state)
		for _, child in ipairs(Gui:GetChildren()) do
			if child:IsA("GuiObject") then
				child.Visible = state
			end
		end
		if not state then return end
		if noise then noise.Visible = NOISE_ENABLED end
	end

	local function cameraList()
		local list = {}
		for _, child in ipairs(CamFolder:GetChildren()) do
			if child:IsA("Model") and child:FindFirstChild("LookPart") then
				table.insert(list, child)
			end
		end
		table.sort(list, function(a, b)
			local na = tonumber(a.Name:match("(%d+)$")) or math.huge
			local nb = tonumber(b.Name:match("(%d+)$")) or math.huge
			if na == nb then return a.Name < b.Name end
			return na < nb
		end)
		return list
	end

	local function randomRange(minValue, maxValue)
		return minValue + math.random() * (maxValue - minValue)
	end

	local function cameraDisplayName(model)
		return (CFG.NAMES and CFG.NAMES[model.Name]) or model:GetAttribute("Name") or model.Name
	end

	local function showCamera(i)
		local list = cameraList()
		if #list == 0 then return end
		if i < 1 then i = #list end
		if i > #list then i = 1 end
		index = i
		local model = list[index]
		local lookPart = model:FindFirstChild("LookPart")
		if not lookPart then return end
		CurrentCamera.CFrame = lookPart.CFrame + lookPart.CFrame.LookVector * CAMERA_OFFSET
		CurrentCamera.CameraSubject = model
		cctvName.Text = cameraDisplayName(model)
		siteBtn.Text = ""
	end

	local function disconnectAll()
		for key, conn in pairs(connections) do
			conn:Disconnect()
			connections[key] = nil
		end
		if noiseConn then
			noiseConn:Disconnect()
			noiseConn = nil
		end
	end

	local function stopViewing()
		disconnectAll()
		active = false
		seated = false
		effect.Enabled = false
		effect.Contrast = 0
		effect.Saturation = 0
		if backpackForceConn then
			backpackForceConn:Disconnect()
			backpackForceConn = nil
		end
		guiVisible(false)
		BackpackGui.Enabled = true
		local character = LocalPlayer.Character
		repeat
			CurrentCamera.CameraType = Enum.CameraType.Custom
			task.wait()
		until CurrentCamera.CameraType == Enum.CameraType.Custom
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			CurrentCamera.CameraSubject = humanoid or character
		end
	end

	local function startViewing()
		if active then return end
		local list = cameraList()
		if #list == 0 then return end
		active = true
		BackpackGui.Enabled = false
		backpackForceConn = BackpackGui:GetPropertyChangedSignal("Enabled"):Connect(function()
			if BackpackGui.Enabled then
				BackpackGui.Enabled = false
			end
		end)
		guiVisible(true)
		CurrentCamera.CameraType = Enum.CameraType.Scriptable

		effect.Enabled = true
		effect.Contrast = CONTRAST
		effect.Saturation = SATURATION

		if NOISE_ENABLED and noise then
			noise.ImageTransparency = NOISE_TRANSPARENCY
			noiseConn = RunService.Heartbeat:Connect(function()
				noise.AnchorPoint = Vector2.new(randomRange(0, 0.5), randomRange(0, 0.5))
			end)
		end

		showCamera(1)

		connections.left = leftBtn.MouseButton1Click:Connect(function()
			showCamera(index - 1)
		end)
		connections.right = rightBtn.MouseButton1Click:Connect(function()
			showCamera(index + 1)
		end)
		connections.site = siteBtn.MouseButton1Click:Connect(function()
			showCamera(index + 1)
		end)
	end

	local function bindCharacter(character)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if not humanoid then return end

		humanoid.Seated:Connect(function(isSeated, seat)
			if isSeated and seat and seat.Name == SEAT_NAME then
				seated = true
				humanoid:UnequipTools()
				startViewing()
			elseif not isSeated and seated then
				stopViewing()
			end
		end)

		humanoid.Jumping:Connect(function(jumping)
			if jumping and seated then
				stopViewing()
			end
		end)

		humanoid.Died:Connect(function()
			if seated then stopViewing() end
		end)
	end

	LocalPlayer.CharacterAdded:Connect(bindCharacter)
	if LocalPlayer.Character then
		task.spawn(bindCharacter, LocalPlayer.Character)
	end

	workspace.ChildRemoved:Connect(function(child)
		if child == LocalPlayer.Character and seated then
			stopViewing()
		end
	end)

	guiVisible(false)

end)

task.spawn(function()
	local Players = game:GetService("Players")
	local RS = game:GetService("ReplicatedStorage")
	local TweenService = game:GetService("TweenService")
	local StarterGui = game:GetService("StarterGui")
	local MarketplaceService = game:GetService("MarketplaceService")

	local Config = require(RS.GameSettings.Groups.MapConfig)
	local PX = Config.PX_SHOP
	local IT = Config.PX_ITEMS
	if not PX or not IT or not IT.ENABLED then return end

	local PV = IT.PREVIEW or {}
	if PV.ENABLED == false then return end

	local LocalPlayer = Players.LocalPlayer
	local Events = RS.GameSettings:WaitForChild("Events")
	local openEvent = Events:WaitForChild("PXItemShop", 60)
	local buyEvent = Events:WaitForChild("PXBuyItem", 60)
	if not openEvent or not buyEvent then return end

	local shopFolder = workspace:WaitForChild(PX.FOLDER_NAME, 60)
	if not shopFolder then return end
	local itemShop = shopFolder:WaitForChild("ItemShop", 30)
	if not itemShop then return end

	local cameraParts = itemShop:WaitForChild("CameraParts", 20)
	local previews = itemShop:WaitForChild("Previews", 20)
	if not cameraParts or not previews then return end

	local gui = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("ItemShopGui", 30)
	if not gui then return end
	local closeBtn = gui:WaitForChild("Close")
	local nextBtn = closeBtn:WaitForChild("Next")
	local prevBtn = closeBtn:WaitForChild("Prev")

	local camera = workspace.CurrentCamera

	local BackpackModule = nil
	local backpackTried = false

	local function getBackpackModule()
		if backpackTried then return BackpackModule end
		backpackTried = true
		local modules = RS.GameSettings:FindFirstChild("Modules")
		local moduleScript = modules and modules:FindFirstChild("Backpack")
		if moduleScript then
			local ok, result = pcall(require, moduleScript)
			if ok then BackpackModule = result end
		end
		return BackpackModule
	end

	local function setBackpackVisible(state)

		task.spawn(function()
			local mod = getBackpackModule()
			if mod and typeof(mod.SetBackpackEnabled) == "function" then
				pcall(function()
					mod:SetBackpackEnabled(state)
				end)
			end
		end)
	end

	local function setCharacterVisible(state)
		local char = LocalPlayer.Character
		if not char then return end
		local modifier = state and 0 or 1
		for _, d in ipairs(char:GetDescendants()) do
			if d:IsA("BasePart") or d:IsA("Decal") then
				d.LocalTransparencyModifier = modifier
			end
		end
	end

	local function fmtMoney(n)
		local s = tostring(math.floor(n))
		local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
		out = out:gsub("^,", "")
		return out
	end

	local order = {}
	for key, cfg in pairs(IT.ITEMS) do
		if not cfg.Hidden and previews:FindFirstChild(key) and cameraParts:FindFirstChild(key) then
			table.insert(order, { Key = key, Cfg = cfg })
		end
	end
	table.sort(order, function(a, b) return a.Cfg.Price < b.Cfg.Price end)
	if #order == 0 then return end

	local promptPart = Instance.new("Part")
	promptPart.Name = "PXPurchasePrompt"
	promptPart.Anchored = true
	promptPart.CanCollide = false
	promptPart.CanQuery = false
	promptPart.CanTouch = false
	promptPart.Transparency = 1
	promptPart.Size = Vector3.one

	local moneyPrompt = Instance.new("ProximityPrompt")
	moneyPrompt.Name = "Money"
	moneyPrompt.Style = Enum.ProximityPromptStyle.Default
	moneyPrompt.ObjectText = PV.MONEY_OBJECT_TEXT or "ซื้อ"
	moneyPrompt.KeyboardKeyCode = Enum.KeyCode.E
	moneyPrompt.HoldDuration = PV.MONEY_HOLD or 0.5
	moneyPrompt.MaxActivationDistance = PV.BUY_DISTANCE or 60
	moneyPrompt.RequiresLineOfSight = false
	moneyPrompt.UIOffset = Vector2.new(0, 0)
	moneyPrompt.Parent = promptPart

	local robuxPrompt = Instance.new("ProximityPrompt")
	robuxPrompt.Name = "Robux"
	robuxPrompt.Style = Enum.ProximityPromptStyle.Default
	robuxPrompt.ObjectText = PV.ROBUX_OBJECT_TEXT or "ซื้อด่วน (Robux)"
	robuxPrompt.ActionText = PV.ROBUX_ACTION_LOADING or "💎 ..."
	robuxPrompt.KeyboardKeyCode = Enum.KeyCode.Q
	robuxPrompt.HoldDuration = 0
	robuxPrompt.MaxActivationDistance = PV.BUY_DISTANCE or 60
	robuxPrompt.RequiresLineOfSight = false
	robuxPrompt.UIOffset = Vector2.new(0, 80)
	robuxPrompt.Parent = promptPart

	local robuxPriceCache = {}
	local function fetchRobuxPrice(productId)
		if robuxPriceCache[productId] then return robuxPriceCache[productId] end
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)
		end)
		if ok and info then
			robuxPriceCache[productId] = info.PriceInRobux
			return info.PriceInRobux
		end
		return nil
	end

	local index = 1
	local isOpen = false

	local function previewPosition(preview)
		if preview:IsA("Model") then return preview:GetPivot().Position end
		return preview.Position
	end

	local function ownsItem(cfg)
		local name = cfg.ToolName or cfg.Name
		local bp = LocalPlayer:FindFirstChild("Backpack")
		if bp and bp:FindFirstChild(name) then return true end
		local char = LocalPlayer.Character
		if char and char:FindFirstChild(name) then return true end
		return false
	end

	local function showItem(i)
		local entry = order[i]
		if not entry then return end
		local cfg = entry.Cfg
		local camPart = cameraParts:FindFirstChild(entry.Key)
		local preview = previews:FindFirstChild(entry.Key)
		if not camPart or not preview then return end

		camera.CameraType = Enum.CameraType.Scriptable
		TweenService:Create(camera, TweenInfo.new(PV.TWEEN_TIME or 0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {
			CFrame = camPart.CFrame,
			FieldOfView = PV.CAMERA_FOV or 40,
		}):Play()

		moneyPrompt.ObjectText = cfg.Name
		robuxPrompt.ObjectText = cfg.Name

		if ownsItem(cfg) then
			moneyPrompt.ActionText = PV.OWNED_TEXT or "มีอยู่แล้ว"
			robuxPrompt.Enabled = false
		else
			moneyPrompt.ActionText = string.format(PV.MONEY_ACTION_FORMAT or "💸 %s บาท", fmtMoney(cfg.Price))
			robuxPrompt.Enabled = (cfg.ProductId and cfg.ProductId > 0) and true or false
			if robuxPrompt.Enabled then
				local cachedPrice = robuxPriceCache[cfg.ProductId]
				robuxPrompt.ActionText = cachedPrice
					and string.format(PV.ROBUX_ACTION_FORMAT or "💎 %s R$", cachedPrice)
					or (PV.ROBUX_ACTION_LOADING or "💎 ...")
				if not cachedPrice then
					local myIndex = i
					task.spawn(function()
						local price = fetchRobuxPrice(cfg.ProductId)
						if price and isOpen and index == myIndex then
							robuxPrompt.ActionText = string.format(PV.ROBUX_ACTION_FORMAT or "💎 %s R$", price)
						end
					end)
				end
			end
		end

		promptPart.Position = previewPosition(preview)
		promptPart.Parent = workspace
	end

	local function closeShop()
		if not isOpen then return end
		isOpen = false
		gui.Enabled = false
		promptPart.Parent = nil
		camera.CameraType = Enum.CameraType.Custom
		camera.FieldOfView = PV.CAMERA_FOV_RESTORE or 70
		setBackpackVisible(true)
		setCharacterVisible(true)
	end

	local function openShop()
		if isOpen then return end
		isOpen = true
		index = 1
		gui.Enabled = true
		setBackpackVisible(false)
		setCharacterVisible(false)
		showItem(index)
	end

	local function step(delta)
		if not isOpen then return end
		index += delta
		if index > #order then index = 1 end
		if index < 1 then index = #order end
		showItem(index)
	end

	openEvent.OnClientEvent:Connect(function(state)
		if state then openShop() else closeShop() end
	end)

	nextBtn.Activated:Connect(function() step(1) end)
	prevBtn.Activated:Connect(function() step(-1) end)
	closeBtn.Activated:Connect(closeShop)

	moneyPrompt.Triggered:Connect(function()
		if not isOpen then return end
		local entry = order[index]
		if not entry then return end
		if ownsItem(entry.Cfg) then return end
		buyEvent:FireServer(entry.Key)
		task.delay(0.35, function()
			if isOpen then showItem(index) end
		end)
	end)

	robuxPrompt.Triggered:Connect(function()
		if not isOpen then return end
		local entry = order[index]
		if not entry then return end
		if ownsItem(entry.Cfg) then return end
		if not entry.Cfg.ProductId or entry.Cfg.ProductId <= 0 then return end
		MarketplaceService:PromptProductPurchase(LocalPlayer, entry.Cfg.ProductId)
	end)

	MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, wasPurchased)
		if wasPurchased and userId == LocalPlayer.UserId and isOpen then
			task.delay(0.5, function()
				if isOpen then showItem(index) end
			end)
		end
	end)

	LocalPlayer.CharacterRemoving:Connect(closeShop)

	task.spawn(function()
		while true do
			task.wait(0.3)
			if isOpen then
				local char = LocalPlayer.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if not root then
					closeShop()
				elseif (root.Position - itemShop:GetPivot().Position).Magnitude > (PV.BUY_DISTANCE or 60) then
					closeShop()
				end
			end
		end
	end)

end)
local PXItemShopClient_MERGED=true

task.spawn(function()

	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local TweenService = game:GetService("TweenService")
	game:GetService("StarterPlayer")
	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")
	local Debris = game:GetService("Debris")
	local v_u_1 = RunService:IsStudio()
	local v_u_2 = require((Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule")))

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
	local _ = game.ReplicatedStorage.GameSettings.Assets.Misc.CWS_Directory
	local CWS = script:WaitForChild("CWS")
	local LocalPlayer2 = require(CWS)(Players.LocalPlayer)
	CWS:Destroy()
	local t = {}
	local t2 = {}
	local v_u_3 = false

	local BackpackGui = LocalPlayer.PlayerGui:FindFirstChild("BackpackGui") or Instance.new("ScreenGui")
	BindKey = nil
	local function unAim()

		if LocalPlayer2.weapon.info then
			LocalPlayer2.weapon.state.aim = false
			LocalPlayer2.services.uis.MouseDeltaSensitivity = 1
			LocalPlayer2.services.ts:Create(LocalPlayer2.camera, TweenInfo.new(0.3), { FieldOfView = LocalPlayer2.origin.FOV }):Play()
			LocalPlayer2.human:SetAttribute("CanSprint", true)
		end
	end
	local function onMobileButtonAdded(p_u_4: userdata)

		if p_u_4.Name ~= "CROUCH" and p_u_4.Name ~= "JumpButton" then
			local v5 = t2
			table.insert(v5, p_u_4)
			local t3 = { KeyCode = LocalPlayer2.modules.settings.KeyBinds.keybinds[p_u_4.Name] }
			LocalPlayer2.events["mobile_down" .. p_u_4.Name] = p_u_4:GetAttributeChangedSignal("Pressing"):Connect(function()

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

				if not p_u_4:GetAttribute("Pressing") then
					LocalPlayer2.keydown[LocalPlayer2:KeyToName(t3)] = false
				end
			end)
		end
	end
	local function setMobileButtonVisible(p6: boolean)

		for _2, v7 in pairs(t2) do
			if v7.Name ~= "AIM" or getShiftLockEnabled() then
				v7.Visible = p6
			end
		end
		LocalPlayer2.gui.mobile.cursor.Visible = p6
	end
	local v_u_8 = tick()
	local v_u_9 = nil
	local v_u_10 = nil
	task.spawn(function()

		v_u_10 = LocalPlayer.PlayerGui:WaitForChild("MousePositionGui"):WaitForChild("center")
	end)
	LocalPlayer2.origin.FOV = LocalPlayer2.camera.FieldOfView
	LocalPlayer2.on_remote = {
		Shoot = function(p11, p12)

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

			LocalPlayer2.remote_size_seed = p15
		end,
		PlaySound = function(p16, p17)

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

			if p19 ~= LocalPlayer and (p20.holder and (p20.name and p20.point)) then
				local t5 = {
					weapon = {}
				}
				t5.weapon.handle = p20.handle
				LocalPlayer2.SetHandleEffects(t5, p20.holder, p20.name, p20.point)
			end
		end,
		EmitHandleEffects = function(p21, p22)

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

			if p25 ~= LocalPlayer and (LocalPlayer2.char and (LocalPlayer2.head and (p26.ray and LocalPlayer2:CreateRay(p26.ray, p26.pos, 7.5)(LocalPlayer2.head.Position)))) then
				LocalPlayer2:PlaySoundFromHolder(LocalPlayer2.dir.sounds, "bullet_miss", LocalPlayer2.modules.Func.GetRandom(-0.2, 0.2), false)
				LocalPlayer2:CameraRecoil(Vector2.new(LocalPlayer2.modules.Func.GetRandom(-0.05, 0.05), LocalPlayer2.modules.Func.GetRandom(-0.05, 0.05)), { 3, LocalPlayer2.modules.Func.GetRandom(10, 30) }, LocalPlayer2.modules.Func.GetRandom(-40, 40))
				LocalPlayer2.gui.bullet_miss.ImageTransparency = 0
				LocalPlayer2.services.ts:Create(LocalPlayer2.gui.bullet_miss, TweenInfo.new(2), { ImageTransparency = 1 }):Play()
			end
		end,
		BulletHole = function(p27, p28)

			if p27 ~= LocalPlayer and p28.pos then
				local _3 = LocalPlayer2:GetDistance(LocalPlayer2.camera.CFrame.Position, p28.pos) <= 1000
			end
		end,
		BloodSplatter = function(_4, p29)

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

			if p32 ~= LocalPlayer and (p33.pos and (p33.name and (p33.start and p33.alpha))) then
				local t8 = { modules = LocalPlayer2.modules }
				LocalPlayer2.Tracer(t8, p33.pos, p33.name, p33.start, p33.alpha)
			end
		end
	}
	LocalPlayer2:GetRemotes()
	local function highlight(p34)

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

		task.spawn(function()

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

					TweenService:Create(v_u_52, v_u_51, { ImageTransparency = 1 }):Play()
				end)
			end
		end
		Debris:AddItem(v49, 2)
	end
	local t10 = {}
	local function FireProjectile()

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

								local t11 = { name = Name, pos = p67, id = v_u_61 }
								LocalPlayer2.dir.remos.Explode:FireServer(t11)
							end
						elseif LocalPlayer2.weapon.info.explosive.when == 0 then
							v64 = function(_9, p68)

								local t12 = { name = Name, pos = p68, id = v_u_61 }
								LocalPlayer2.dir.remos.Explode:FireServer(t12)
								return false, true
							end
						elseif LocalPlayer2.weapon.info.explosive.when == 2 then
							v64 = function(p69, p70, p71)

								if p71 == Vector3.FromNormalId(Enum.NormalId.Top) or p69.Parent:FindFirstChild("Humanoid") then
									local t13 = { name = Name, pos = p70, id = v_u_61 }
									LocalPlayer2.dir.remos.Explode:FireServer(t13)
									return false, true
								end
							end
						end
					end

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

		LocalPlayer2.weapon.state.shooting = true
		LocalPlayer2:PlaySoundFromHolder(LocalPlayer2.weapon.handle, "fire", LocalPlayer2.modules.Func.GetRandom(-0.01, 0.01), false)
		if LocalPlayer2.weapon.handle:FindFirstChild("casing") then
			LocalPlayer2.modules.Func.Delay(LocalPlayer2.modules.Func.GetRandom(0.3, 0.8), function()

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
							local HeadShotSound = game.ReplicatedStorage.GameSettings.Assets.Misc.CWS_Directory.sounds.HeadShotSound
							task.spawn(function()

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
						local BodyShotSound = game.ReplicatedStorage.GameSettings.Assets.Misc.CWS_Directory.sounds.BodyShotSound
						task.spawn(function()

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

			LocalPlayer2.queues.rpm = p127
		end)
		LocalPlayer2.weapon.state.shooting = false
		local _18 = false
	end
	local v_u_128 = 0
	local function request_dodge()

		if not LocalPlayer2.weapon.state.dodging and LocalPlayer2.human:GetAttribute("RagdollEnabled") == false then
			if tick() - v_u_128 < 1.5 then
				return
			end
			v_u_128 = tick()
			local v129 = 1
			local _19 = LocalPlayer.CameraMode
			local v130 = "Dodge" .. v129
			local Length = LocalPlayer2:GetAnimation(v130).Length
			local t17 = { Enum.PlayerActions.CharacterJump }
			if v129 == 1 then
				t17 = Enum.PlayerActions:GetEnumItems()
			end
			LocalPlayer2.services.cas:BindAction("freezeMovement", function()

				return Enum.ContextActionResult.Sink
			end, false, table.unpack(t17))
			task.delay(Length, function()

				LocalPlayer2.services.cas:UnbindAction("freezeMovement")
			end)
			LocalPlayer2:PlaySoundFromHolder(LocalPlayer2.dir.sounds, v130, LocalPlayer2.modules.Func.GetRandom(-0.1, 0.1), false)
			LocalPlayer2:FireRemote("Dodge", { skill = v129 })
			task.spawn(function()

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

		local function CanShoot()

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

					if not v_u_138 then
						v_u_138 = true
						if v_u_136 == v_u_131 then
							task.delay(0.5, function()

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

					LocalPlayer2.queues.reload_time = p143
					p143.Event:Connect(function()

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

						v_u_146 = LocalPlayer2.weapon.handle.Touched:Connect(function(p147)

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
			workspace:SetAttribute("CWS_DEBUG_RENDERARMS", (workspace:GetAttribute("CWS_DEBUG_RENDERARMS") or 0) + 1)
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

		v_u_152 = p153
		if (LocalPlayer2:IsFirstPerson() or v_u_152) and LocalPlayer2.weapon.tool then
			LocalPlayer2.gui.mobile.AIM.Visible = true
		else
			LocalPlayer2.gui.mobile.AIM.Visible = false
			unAim()
		end
	end)
	LocalPlayer2.services.rs.RenderStepped:Connect(function()

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

		if not p159 then
			LocalPlayer2.keydown[LocalPlayer2:KeyToName(p158)] = true
			BindKey(p158)
		end
	end)
	LocalPlayer2.services.uis.InputEnded:Connect(function(p160, p161)

		if not p161 then
			LocalPlayer2.keydown[LocalPlayer2:KeyToName(p160)] = false
			LocalPlayer2:BindKey(p160, function(_29, p162)

				if p162("AIM") and (LocalPlayer2.weapon.tool and LocalPlayer2.weapon.state.equipped) then
					unAim()
				end
			end)
		end
	end)
	workspace.ChildRemoved:Connect(function(p163)

		if p163 == LocalPlayer2.char then
			player_died()
		end
	end)
	task.delay(5, function()

		LocalPlayer.PlayerScripts.DescendantRemoving:Connect(function(p164)

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

		workspace:SetAttribute("CWS_DEBUG_ENTER", (workspace:GetAttribute("CWS_DEBUG_ENTER") or 0) + 1)
		workspace:SetAttribute("CWS_DEBUG_HASGUI", LocalPlayer2.gui ~= nil)
		if not LocalPlayer2.gui then
			local ok, err = pcall(function()
				LocalPlayer2:GetGui()
			end)
			workspace:SetAttribute("CWS_DEBUG_GETGUI", ok and "ok" or ("err: " .. tostring(err)))
			if ok then
				LocalPlayer2.gui.weapon.Visible = false
				local ok2, err2 = pcall(function()
					v_u_150 = LocalPlayer2.gui.mobile:WaitForChild("cursor", 5)
				end)
				workspace:SetAttribute("CWS_DEBUG_V150", ok2 and "set" or ("err: " .. tostring(err2)))
			end
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

			if LocalPlayer2.human:GetAttribute("Unarmed") == true then
				BackpackGui.Enabled = false
				LocalPlayer2.human:UnequipTools()
			end
		end)
		LocalPlayer2.right_arm.ChildAdded:Connect(function(p169: userdata)

			if p169.Name == "RightGrip" then
				LocalPlayer2.tool_grip_weld = p169
				LocalPlayer2.origin.ToolGripC0 = p169.C0
				LocalPlayer2.origin.ToolGripC1 = p169.C1
				local v_u_170 = nil
				v_u_170 = p169.AncestryChanged:Connect(function(_33, p171)

					if p171 ~= LocalPlayer2.right_arm then
						LocalPlayer2.tool_grip_weld = nil
						v_u_170:Disconnect()
					end
				end)
			end
		end)
		local v_u_172 = false
		local function checkRunning()

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

						if LocalPlayer2.weapon.tool == p_u_176 then
							print("changed info, but nothing gonna changed")
							LocalPlayer2:GetInfo(p_u_176)
						else
							v_u_178:Disconnect()
						end
					end)
				end
				task.spawn(function()

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

			player_died()
		end)
		LocalPlayer2.human.StateChanged:Connect(function(p180, p181)

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

			if p183:IsA("ImageButton") then
				onMobileButtonAdded(p183)
			end
		end)
	end
	task.spawn(function()

		if LocalPlayer.Character then
			onCharacterAdded(LocalPlayer.Character)
		end
	end)
	LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
end)
local Systems2_MERGED=true