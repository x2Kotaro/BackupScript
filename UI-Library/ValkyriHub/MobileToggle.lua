--[[
    Valkyrie Hub // MobileToggle

    Floating round button that opens and closes the menu. Shown on desktop and on touch
    devices alike: on phones it is the only way in, on PC it sits next to the keybind.
    Replaces the library's built-in FloatingButton, which is a flat 50% transparent disc
    that also fires the toggle while you drag it.

    Usage:

        local MobileToggle = loadstring(game:HttpGet("<host>/MobileToggle.lua"))()

        local Toggle = MobileToggle.new({
            Logo = IconValkyrie,          -- asset id, no "rbxassetid://"
            Accent = Accent,              -- Color3
            Gradient = Gradient,          -- Color3, second stop of the ring gradient
            Window = Window,              -- library window; :SetOpen is driven from here
            Library = Library,            -- optional, only used to hide the built-in button
        })

        Toggle:Toggle()          -- flip
        Toggle:SetOpen(false)    -- force state
        Toggle:SetVisible(false) -- hide the button itself
        Toggle:Destroy()         -- full teardown

    Re-running the script is safe: `new` tears down whatever the previous execution left
    behind (gui + every connection + the tween loop) before building anything.
]]

local MobileToggle = { }

local CoreGui = cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")
local Players = cloneref and cloneref(game:GetService("Players")) or game:GetService("Players")
local UserInputService = cloneref and cloneref(game:GetService("UserInputService")) or game:GetService("UserInputService")
local TweenService = cloneref and cloneref(game:GetService("TweenService")) or game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local GuiName = "Valkyrie_MobileToggle"
local GlobalKey = "ValkyrieMobileToggle"

-- how far a finger may travel before the touch counts as a drag instead of a tap
local DragThreshold = 8
local ButtonSize = 44
-- the button is free to sit anywhere; this is only how much of it must stay on screen
local EdgePadding = 6

local function GetParent()
    if gethui then
        local Ok, Result = pcall(gethui)

        if Ok and Result then
            return Result
        end
    end

    local Ok, Result = pcall(function()
        return CoreGui:IsA("CoreGui") and CoreGui
    end)

    if Ok and Result then
        return Result
    end

    return LocalPlayer:FindFirstChildOfClass("PlayerGui")
end

-- everything a previous execution may have left behind: the handle it stored in getgenv,
-- plus any orphan ScreenGui that survived a crash before Destroy could run
local function CleanPrevious()
    local Previous = getgenv()[GlobalKey]

    if type(Previous) == "table" and type(Previous.Destroy) == "function" then
        pcall(function()
            Previous:Destroy()
        end)
    end

    getgenv()[GlobalKey] = nil

    for _, Container in ipairs({ GetParent(), CoreGui, LocalPlayer:FindFirstChildOfClass("PlayerGui") }) do
        if typeof(Container) == "Instance" then
            for _, Child in ipairs(Container:GetChildren()) do
                if Child.Name == GuiName then
                    pcall(function()
                        Child:Destroy()
                    end)
                end
            end
        end
    end
end

local Handle = { }
Handle.__index = Handle

function Handle:Track(Connection)
    table.insert(self.Connections, Connection)

    return Connection
end

function Handle:Paint()
    -- open reads as lit: accent halo and a solid ring. closed dims down but never to the
    -- washed out 50% the built-in button sits at
    local Open = self.IsOpen

    TweenService:Create(self.Halo, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = Open and 0.72 or 0.88,
        Size = Open and UDim2.new(1, 12, 1, 12) or UDim2.new(1, 7, 1, 7)
    }):Play()

    TweenService:Create(self.Stroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Transparency = Open and 0 or 0.35,
        Thickness = Open and 2 or 1.6
    }):Play()

    TweenService:Create(self.Logo, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ImageTransparency = Open and 0 or 0.2
    }):Play()
end

function Handle:Ripple()
    self.Pulse.Size = UDim2.new(1, -8, 1, -8)
    self.Pulse.BackgroundTransparency = 0.45

    TweenService:Create(self.Pulse, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = UDim2.new(1, 24, 1, 24),
        BackgroundTransparency = 1
    }):Play()

    TweenService:Create(self.Button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, ButtonSize - 4, 0, ButtonSize - 4)
    }):Play()

    task.delay(0.12, function()
        if self.Destroyed then return end

        TweenService:Create(self.Button, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, ButtonSize, 0, ButtonSize)
        }):Play()
    end)
end

function Handle:SetOpen(State)
    self.IsOpen = State and true or false

    local Window = self.Options.Window

    if Window and type(Window.SetOpen) == "function" then
        pcall(function()
            Window:SetOpen(self.IsOpen)
        end)
    end

    if type(self.Options.OnToggle) == "function" then
        pcall(self.Options.OnToggle, self.IsOpen)
    end

    self:Paint()
end

function Handle:Toggle()
    self:Ripple()
    self:SetOpen(not self.IsOpen)
end

function Handle:SetVisible(State)
    self.Gui.Enabled = State and true or false
end

-- the button stays wherever it was dropped. This only pulls it back if it was left
-- (or a rotation / resize pushed it) past the screen, so it can never become unreachable
function Handle:Clamp(Animate)
    local Viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local Position = self.Button.AbsolutePosition

    local MaxX = math.max(EdgePadding, Viewport.X - ButtonSize - EdgePadding)
    local MaxY = math.max(EdgePadding, Viewport.Y - ButtonSize - EdgePadding)

    local TargetX = math.clamp(Position.X, EdgePadding, MaxX)
    local TargetY = math.clamp(Position.Y, EdgePadding, MaxY)
    local Target = UDim2.new(0, TargetX, 0, TargetY)

    getgenv()[GlobalKey .. "_Position"] = Target

    -- already inside the screen: leave it exactly where the finger let go
    if TargetX == Position.X and TargetY == Position.Y then
        self.Button.Position = Target

        return
    end

    if Animate == false then
        self.Button.Position = Target
    else
        TweenService:Create(self.Button, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = Target
        }):Play()
    end
end

function Handle:Destroy()
    if self.Destroyed then return end

    self.Destroyed = true

    for _, Connection in ipairs(self.Connections) do
        pcall(function()
            Connection:Disconnect()
        end)
    end

    table.clear(self.Connections)

    if self.SpinThread then
        pcall(function()
            task.cancel(self.SpinThread)
        end)

        self.SpinThread = nil
    end

    -- give the library's own floating button its visibility back
    if self.LibraryButton then
        pcall(function()
            self.LibraryButton.Visible = true
        end)

        self.LibraryButton = nil
    end

    pcall(function()
        self.Gui:Destroy()
    end)

    if getgenv()[GlobalKey] == self then
        getgenv()[GlobalKey] = nil
    end
end

function MobileToggle.new(Options)
    Options = Options or { }

    CleanPrevious()

    -- shown on desktop as well as touch: the keybind still works, the button is just a
    -- second way in. Pass TouchOnly = true to restrict it to touch devices.
    if Options.TouchOnly and not UserInputService.TouchEnabled then
        return nil
    end

    local Accent = Options.Accent or Color3.fromRGB(255, 80, 80)
    local Gradient = Options.Gradient or Color3.fromRGB(120, 20, 20)
    local Logo = tostring(Options.Logo or "")

    local Self = setmetatable({
        Options = Options,
        Connections = { },
        IsOpen = true,
        Destroyed = false
    }, Handle)

    if Options.Window and Options.Window.IsOpen ~= nil then
        Self.IsOpen = Options.Window.IsOpen and true or false
    end

    local Gui = Instance.new("ScreenGui")
    Gui.Name = GuiName
    Gui.ResetOnSpawn = false
    Gui.IgnoreGuiInset = true
    Gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    Gui.DisplayOrder = 999999
    Gui.Parent = GetParent()

    Self.Gui = Gui

    local Button = Instance.new("TextButton")
    Button.Name = "Toggle"
    Button.Text = ""
    Button.AutoButtonColor = false
    Button.BackgroundTransparency = 1
    Button.BorderSizePixel = 0
    Button.Size = UDim2.new(0, ButtonSize, 0, ButtonSize)
    Button.Position = getgenv()[GlobalKey .. "_Position"] or UDim2.new(0, EdgePadding, 0.34, 0)
    Button.ZIndex = 10
    Button.Parent = Gui

    Self.Button = Button

    -- soft accent aura behind everything, this is what stops it reading as a flat grey disc
    local Halo = Instance.new("Frame")
    Halo.Name = "Halo"
    Halo.AnchorPoint = Vector2.new(0.5, 0.5)
    Halo.Position = UDim2.new(0.5, 0, 0.5, 0)
    Halo.Size = UDim2.new(1, 12, 1, 12)
    Halo.BackgroundColor3 = Accent
    Halo.BackgroundTransparency = 0.72
    Halo.BorderSizePixel = 0
    Halo.ZIndex = 9
    Halo.Parent = Button

    Instance.new("UICorner", Halo).CornerRadius = UDim.new(1, 0)

    local HaloGradient = Instance.new("UIGradient")
    HaloGradient.Color = ColorSequence.new(Accent, Gradient)
    HaloGradient.Rotation = 45
    HaloGradient.Parent = Halo

    Self.Halo = Halo

    -- the body: dark disc so the logo keeps its contrast on bright maps
    local Body = Instance.new("Frame")
    Body.Name = "Body"
    Body.Size = UDim2.new(1, 0, 1, 0)
    Body.BackgroundColor3 = Color3.fromRGB(24, 22, 27)
    Body.BackgroundTransparency = 0.08
    Body.BorderSizePixel = 0
    Body.ZIndex = 10
    Body.Parent = Button

    Instance.new("UICorner", Body).CornerRadius = UDim.new(1, 0)

    local BodyGradient = Instance.new("UIGradient")
    BodyGradient.Color = ColorSequence.new(Color3.fromRGB(46, 40, 50), Color3.fromRGB(18, 16, 21))
    BodyGradient.Rotation = 90
    BodyGradient.Parent = Body

    local Stroke = Instance.new("UIStroke")
    Stroke.Thickness = 2
    Stroke.Transparency = 0
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Stroke.Parent = Body

    local StrokeGradient = Instance.new("UIGradient")
    StrokeGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Accent),
        ColorSequenceKeypoint.new(0.5, Gradient),
        ColorSequenceKeypoint.new(1, Accent)
    })
    StrokeGradient.Parent = Stroke

    Self.Stroke = Stroke

    -- tap feedback ring, expands out of the button and fades
    local Pulse = Instance.new("Frame")
    Pulse.Name = "Pulse"
    Pulse.AnchorPoint = Vector2.new(0.5, 0.5)
    Pulse.Position = UDim2.new(0.5, 0, 0.5, 0)
    Pulse.Size = UDim2.new(1, -8, 1, -8)
    Pulse.BackgroundColor3 = Accent
    Pulse.BackgroundTransparency = 1
    Pulse.BorderSizePixel = 0
    Pulse.ZIndex = 11
    Pulse.Parent = Button

    Instance.new("UICorner", Pulse).CornerRadius = UDim.new(1, 0)

    Self.Pulse = Pulse

    local Image = Instance.new("ImageLabel")
    Image.Name = "Logo"
    Image.AnchorPoint = Vector2.new(0.5, 0.5)
    Image.Position = UDim2.new(0.5, 0, 0.5, 0)
    Image.Size = UDim2.new(0, math.floor(ButtonSize * 0.56), 0, math.floor(ButtonSize * 0.56))
    Image.BackgroundTransparency = 1
    Image.ScaleType = Enum.ScaleType.Fit
    Image.Image = Logo ~= "" and ("rbxassetid://" .. Logo) or ""
    Image.ZIndex = 12
    Image.Parent = Button

    Self.Logo = Image

    -- the ring gradient rotates slowly so the button reads as alive without pulling focus
    Self.SpinThread = task.spawn(function()
        while not Self.Destroyed do
            StrokeGradient.Rotation = (StrokeGradient.Rotation + 1) % 360
            HaloGradient.Rotation = (HaloGradient.Rotation + 0.5) % 360

            task.wait(0.03)
        end
    end)

    -- the library builds its own mobile button; two of them is noise
    local Items = Options.Window and Options.Window.Items
    local Builtin = Items and Items["FloatingButton"]

    if Builtin and Builtin.Instance then
        Self.LibraryButton = Builtin.Instance
        Builtin.Instance.Visible = false
    end

    local Dragging = false
    local Moved = 0
    local DragStart
    local StartPosition

    Self:Track(Button.InputBegan:Connect(function(Input)
        if Input.UserInputType ~= Enum.UserInputType.Touch and Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        Dragging = true
        Moved = 0
        DragStart = Input.Position
        StartPosition = Button.Position

        TweenService:Create(Body, TweenInfo.new(0.12), { BackgroundTransparency = 0 }):Play()
    end))

    Self:Track(UserInputService.InputChanged:Connect(function(Input)
        if not Dragging then return end
        if Input.UserInputType ~= Enum.UserInputType.Touch and Input.UserInputType ~= Enum.UserInputType.MouseMovement then
            return
        end

        local Delta = Input.Position - DragStart

        Moved = math.max(Moved, math.abs(Delta.X) + math.abs(Delta.Y))

        Button.Position = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + Delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + Delta.Y
        )
    end))

    Self:Track(UserInputService.InputEnded:Connect(function(Input)
        if not Dragging then return end
        if Input.UserInputType ~= Enum.UserInputType.Touch and Input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        Dragging = false

        TweenService:Create(Body, TweenInfo.new(0.18), { BackgroundTransparency = 0.08 }):Play()

        -- a short press is a tap, anything further was the user moving the button
        if Moved <= DragThreshold then
            Self:Toggle()
        end

        Self:Clamp(true)
    end))

    local Camera = workspace.CurrentCamera

    if Camera then
        Self:Track(Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            if Self.Destroyed then return end

            Self:Clamp(true)
        end))
    end

    Self:Paint()

    task.defer(function()
        if Self.Destroyed then return end

        Self:Clamp(false)
    end)

    getgenv()[GlobalKey] = Self

    return Self
end

-- exposed so a script can tear the button down without holding the handle
function MobileToggle.Destroy()
    CleanPrevious()
end

return MobileToggle