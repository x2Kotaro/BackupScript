local HttpService = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")

local GROUPS = {
	{"LuaSourceContainer", {"Source"}},
	{"BaseScript", {"Disabled"}},
	{"Script", {"RunContext"}},
	{"ValueBase", {"Value"}},
	{"Animation", {"AnimationId"}},
	{"Sound", {"SoundId","Volume","PlaybackSpeed","Looped","RollOffMaxDistance","RollOffMinDistance","RollOffMode","EmitterSize","PlayOnRemove","TimePosition"}},
	{"ParticleEmitter", {"Acceleration","Brightness","Color","Drag","EmissionDirection","Enabled","FlipbookLayout","FlipbookMode","FlipbookFramerate","FlipbookStartRandom","Lifetime","LightEmission","LightInfluence","LockedToPart","Orientation","Rate","RotSpeed","Rotation","Shape","ShapeInOut","ShapeStyle","Size","Speed","SpreadAngle","Squash","Texture","TimeScale","Transparency","VelocityInheritance","WindAffectsDrag","ZOffset"}},
	{"Beam", {"Attachment0","Attachment1","Brightness","Color","CurveSize0","CurveSize1","Enabled","FaceCamera","LightEmission","LightInfluence","Segments","Texture","TextureLength","TextureMode","TextureSpeed","Transparency","Width0","Width1","ZOffset"}},
	{"Trail", {"Attachment0","Attachment1","Brightness","Color","Enabled","FaceCamera","Lifetime","LightEmission","LightInfluence","MaxLength","MinLength","Texture","TextureLength","TextureMode","Transparency","WidthScale"}},
	{"Light", {"Brightness","Color","Enabled","Shadows"}},
	{"PointLight", {"Range"}},
	{"SpotLight", {"Range","Angle","Face"}},
	{"Attachment", {"CFrame","Visible"}},
	{"BasePart", {"Anchored","CanCollide","CanQuery","CanTouch","CastShadow","CFrame","Color","Massless","Material","Reflectance","Size","Transparency","CollisionGroup","TopSurface","BottomSurface","EnableFluidForces"}},
	{"Part", {"Shape"}},
	{"MeshPart", {"MeshId","TextureID","DoubleSided","RenderFidelity","CollisionFidelity"}},
	{"SurfaceAppearance", {"AlphaMode","ColorMap","MetalnessMap","NormalMap","RoughnessMap"}},
	{"SpecialMesh", {"MeshId","MeshType","Offset","Scale","TextureId","VertexColor"}},
	{"Decal", {"Texture","Color3","Transparency","Face","ZIndex"}},
	{"Texture", {"StudsPerTileU","StudsPerTileV","OffsetStudsU","OffsetStudsV"}},
	{"JointInstance", {"C0","C1","Part0","Part1","Enabled"}},
	{"Constraint", {"Attachment0","Attachment1","Enabled","Visible"}},
	{"BallSocketConstraint", {"LimitsEnabled","TwistLimitsEnabled","UpperAngle","TwistLowerAngle","TwistUpperAngle","Radius","Restitution","MaxFrictionTorque"}},
	{"Tool", {"CanBeDropped","Enabled","Grip","ManualActivationOnly","RequiresHandle","ToolTip","TextureId"}},
	{"Model", {"PrimaryPart","WorldPivot"}},
	{"LayerCollector", {"Enabled","ResetOnSpawn","ZIndexBehavior"}},
	{"ScreenGui", {"DisplayOrder","IgnoreGuiInset","ScreenInsets","ClipToDeviceSafeArea","SafeAreaCompatibility"}},
	{"BillboardGui", {"Active","AlwaysOnTop","Brightness","ClipsDescendants","DistanceLowerLimit","DistanceStep","DistanceUpperLimit","ExtentsOffset","ExtentsOffsetWorldSpace","LightInfluence","MaxDistance","Size","SizeOffset","StudsOffset","StudsOffsetWorldSpace"}},
	{"SurfaceGui", {"Active","AlwaysOnTop","Brightness","ClipsDescendants","Face","LightInfluence","PixelsPerStud","SizingMode","CanvasSize"}},
	{"GuiObject", {"Active","AnchorPoint","AutomaticSize","BackgroundColor3","BackgroundTransparency","BorderColor3","BorderMode","BorderSizePixel","ClipsDescendants","LayoutOrder","Position","Rotation","Selectable","Size","SizeConstraint","Visible","ZIndex"}},
	{"TextLabel", {"Font","FontFace","LineHeight","MaxVisibleGraphemes","RichText","Text","TextColor3","TextScaled","TextSize","TextStrokeColor3","TextStrokeTransparency","TextTransparency","TextTruncate","TextWrapped","TextXAlignment","TextYAlignment"}},
	{"TextButton", {"Font","FontFace","LineHeight","MaxVisibleGraphemes","RichText","Text","TextColor3","TextScaled","TextSize","TextStrokeColor3","TextStrokeTransparency","TextTransparency","TextTruncate","TextWrapped","TextXAlignment","TextYAlignment","AutoButtonColor","Modal"}},
	{"TextBox", {"Font","FontFace","RichText","Text","TextColor3","TextScaled","TextSize","TextStrokeColor3","TextStrokeTransparency","TextTransparency","TextWrapped","TextXAlignment","TextYAlignment","PlaceholderText","PlaceholderColor3","ClearTextOnFocus","MultiLine","TextEditable"}},
	{"ImageLabel", {"Image","ImageColor3","ImageRectOffset","ImageRectSize","ImageTransparency","ScaleType","SliceCenter","SliceScale","TileSize","ResampleMode"}},
	{"ImageButton", {"Image","ImageColor3","ImageRectOffset","ImageRectSize","ImageTransparency","ScaleType","SliceCenter","SliceScale","TileSize","ResampleMode","AutoButtonColor","HoverImage","PressedImage","Modal"}},
	{"ViewportFrame", {"Ambient","CurrentCamera","ImageColor3","ImageTransparency","LightColor","LightDirection"}},
	{"UIStroke", {"ApplyStrokeMode","Color","Enabled","LineJoinMode","Thickness","Transparency"}},
	{"UIGradient", {"Color","Enabled","Offset","Rotation","Transparency"}},
	{"UIScale", {"Scale"}},
	{"UIAspectRatioConstraint", {"AspectRatio","AspectType","DominantAxis"}},
	{"UISizeConstraint", {"MaxSize","MinSize"}},
	{"UITextSizeConstraint", {"MaxTextSize","MinTextSize"}},
	{"UICorner", {"CornerRadius"}},
	{"UIPadding", {"PaddingBottom","PaddingLeft","PaddingRight","PaddingTop"}},
	{"UIListLayout", {"Padding","FillDirection","HorizontalAlignment","VerticalAlignment","SortOrder"}},
	{"UIGridLayout", {"CellPadding","CellSize","FillDirection","FillDirectionMaxCells","HorizontalAlignment","SortOrder","StartCorner","VerticalAlignment"}},
	{"Highlight", {"Adornee","DepthMode","Enabled","FillColor","FillTransparency","OutlineColor","OutlineTransparency"}},
	{"Folder", {}},
	{"RemoteEvent", {}},
	{"BindableEvent", {}},
	{"RemoteFunction", {}},
	{"Configuration", {}},
	{"Weld", {}},
	{"WeldConstraint", {"Part0","Part1","Enabled"}},
	{"Motor6D", {}},
	{"Humanoid", {}},
	{"AnimationController", {}},
	{"Animator", {}},
	{"Bone", {}},
	{"NumberValue", {}},
}

local M = {}

local function encodeValue(v, idOf)
	local t = typeof(v)
	if t == "number" or t == "string" or t == "boolean" then
		return {k = "p", v = v}
	elseif t == "EnumItem" then
		return {k = "Enum", e = tostring(v.EnumType), v = v.Name}
	elseif t == "Color3" then
		return {k = "Color3", v = {v.R, v.G, v.B}}
	elseif t == "Vector3" then
		return {k = "Vector3", v = {v.X, v.Y, v.Z}}
	elseif t == "Vector2" then
		return {k = "Vector2", v = {v.X, v.Y}}
	elseif t == "UDim" then
		return {k = "UDim", v = {v.Scale, v.Offset}}
	elseif t == "UDim2" then
		return {k = "UDim2", v = {v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset}}
	elseif t == "CFrame" then
		return {k = "CFrame", v = {v:GetComponents()}}
	elseif t == "NumberRange" then
		return {k = "NumberRange", v = {v.Min, v.Max}}
	elseif t == "Rect" then
		return {k = "Rect", v = {v.Min.X, v.Min.Y, v.Max.X, v.Max.Y}}
	elseif t == "BrickColor" then
		return {k = "BrickColor", v = v.Name}
	elseif t == "ColorSequence" then
		local kp = {}
		for _, p in ipairs(v.Keypoints) do
			table.insert(kp, {p.Time, p.Value.R, p.Value.G, p.Value.B})
		end
		return {k = "ColorSequence", v = kp}
	elseif t == "NumberSequence" then
		local kp = {}
		for _, p in ipairs(v.Keypoints) do
			table.insert(kp, {p.Time, p.Value, p.Envelope})
		end
		return {k = "NumberSequence", v = kp}
	elseif t == "Font" then
		return {k = "Font", v = {v.Family, v.Weight.Name, v.Style.Name}}
	elseif t == "Content" then
		local uri = nil
		pcall(function() uri = v.Uri end)
		return {k = "Content", v = uri or ""}
	elseif t == "Instance" then
		local id = idOf[v]
		if id then return {k = "Ref", v = id} end
		return nil
	end
	return nil
end

function M.dump(root)
	local flat = {}
	local idOf = {}
	local function collect(inst, pid)
		local id = #flat + 1
		flat[id] = {inst = inst, pid = pid}
		idOf[inst] = id
		for _, c in ipairs(inst:GetChildren()) do
			collect(c, id)
		end
	end
	collect(root, 0)

	local nodes = {}
	for id, rec in ipairs(flat) do
		local inst = rec.inst
		local props = {}
		local seen = {}
		for _, grp in ipairs(GROUPS) do
			local ok, isa = pcall(function() return inst:IsA(grp[1]) end)
			if ok and isa then
				for _, pname in ipairs(grp[2]) do
					if not seen[pname] then
						seen[pname] = true
						local ok2, val = pcall(function() return inst[pname] end)
						if ok2 then
							local enc = encodeValue(val, idOf)
							if enc ~= nil then props[pname] = enc end
						end
					end
				end
			end
		end
		local attrs = {}
		for k, v in pairs(inst:GetAttributes()) do
			local enc = encodeValue(v, idOf)
			if enc ~= nil then attrs[k] = enc end
		end
		local tags = CollectionService:GetTags(inst)
		nodes[id] = {
			id = id,
			pid = rec.pid,
			cn = inst.ClassName,
			n = inst.Name,
			p = props,
			a = (next(attrs) ~= nil) and attrs or nil,
			t = (#tags > 0) and tags or nil,
		}
	end
	return nodes
end

local function decodeValue(e, made)
	local k = e.k
	if k == "p" then return e.v
	elseif k == "Enum" then
		local en = Enum[e.e:gsub("^Enum%.", "")]
		return en and en[e.v] or nil
	elseif k == "Color3" then return Color3.new(e.v[1], e.v[2], e.v[3])
	elseif k == "Vector3" then return Vector3.new(e.v[1], e.v[2], e.v[3])
	elseif k == "Vector2" then return Vector2.new(e.v[1], e.v[2])
	elseif k == "UDim" then return UDim.new(e.v[1], e.v[2])
	elseif k == "UDim2" then return UDim2.new(e.v[1], e.v[2], e.v[3], e.v[4])
	elseif k == "CFrame" then return CFrame.new(table.unpack(e.v))
	elseif k == "NumberRange" then return NumberRange.new(e.v[1], e.v[2])
	elseif k == "Rect" then return Rect.new(e.v[1], e.v[2], e.v[3], e.v[4])
	elseif k == "BrickColor" then return BrickColor.new(e.v)
	elseif k == "ColorSequence" then
		local kp = {}
		for _, p in ipairs(e.v) do
			table.insert(kp, ColorSequenceKeypoint.new(p[1], Color3.new(p[2], p[3], p[4])))
		end
		return ColorSequence.new(kp)
	elseif k == "NumberSequence" then
		local kp = {}
		for _, p in ipairs(e.v) do
			table.insert(kp, NumberSequenceKeypoint.new(p[1], p[2], p[3]))
		end
		return NumberSequence.new(kp)
	elseif k == "Font" then
		local ok, f = pcall(function()
			return Font.new(e.v[1], Enum.FontWeight[e.v[2]], Enum.FontStyle[e.v[3]])
		end)
		return ok and f or nil
	elseif k == "Content" then return e.v
	elseif k == "Ref" then return made[e.v]
	end
	return nil
end

function M.build(nodes, parent)
	local made = {}
	for _, n in ipairs(nodes) do
		local ok, inst = pcall(Instance.new, n.cn)
		if not ok then
			error("cannot create " .. tostring(n.cn) .. " (" .. tostring(n.n) .. ")")
		end
		inst.Name = n.n
		made[n.id] = inst
	end
	local deferred = {}
	for _, n in ipairs(nodes) do
		local inst = made[n.id]
		for pname, e in pairs(n.p) do
			if e.k == "Ref" then
				table.insert(deferred, {inst, pname, e})
			else
				local val = decodeValue(e, made)
				if val ~= nil then pcall(function() inst[pname] = val end) end
			end
		end
		if n.a then
			for k, e in pairs(n.a) do
				local val = decodeValue(e, made)
				if val ~= nil then pcall(function() inst:SetAttribute(k, val) end) end
			end
		end
		if n.t then
			for _, tag in ipairs(n.t) do pcall(function() CollectionService:AddTag(inst, tag) end) end
		end
	end
	for _, n in ipairs(nodes) do
		if n.pid ~= 0 then made[n.id].Parent = made[n.pid] end
	end
	for _, d in ipairs(deferred) do
		local val = decodeValue(d[3], made)
		if val ~= nil then pcall(function() d[1][d[2]] = val end) end
	end
	made[1].Parent = parent
	return made[1]
end

return M
