local NotificationLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/IceMinisterq/Notification-Library/Main/Library.lua"))()

if game:GetService("CoreGui"):FindFirstChild("WindUI") then
    return
    NotificationLibrary:SendNotification("Info", "You already have a script.", 3)
end

_G.ConfigurationTable = {}
_G.Settings = {}

local FolderConfiguration = "Venuz Hub"
local FolderSettings = "Venuz Hub/Dig it"
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local chr = LocalPlayer.Character
local hrp = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
local HttpService = game:GetService("HttpService")
local VenuzIcon = "rbxassetid://92691624917972"
local UserInputService = game:GetService("UserInputService")

local filenameConfiguration = FolderConfiguration .. "/" .. "Setting" .. ".json"
local filenameSetting = FolderSettings .. "/" .. "Dig it_".. LocalPlayer.Name .. ".json"

--------------------------- Configuration Save ---------------------------

function LoadConfiguration()
    if readfile and isfile and isfile(filenameConfiguration) then
        _G.ConfigurationTable = HttpService:JSONDecode(readfile(filenameConfiguration))
    else
        _G.ConfigurationTable = {
            Themes = "Dark",
            Transparent = true,
            AntiAFK = true,
            AutoExecutor = false,
            MinimizeBind = "End"
        }
    end
end

function saveConfiguration()
    if writefile and makefolder then
        if not isfolder("Venuz Hub") then makefolder("Venuz Hub") end
        if not isfolder(FolderConfiguration) then makefolder(FolderConfiguration) end
        local json = HttpService:JSONEncode(_G.ConfigurationTable)
        writefile(filenameConfiguration, json)
    end
end

LoadConfiguration()

--------------------------- SaveSettings ---------------------------

function LoadSettings()
    if readfile and isfile and isfile(filenameSetting) then
        _G.Settings = HttpService:JSONDecode(readfile(filenameSetting))
    else
        _G.Settings = {

        }
    end
end

function SaveSetting()
    if writefile and makefolder then
        if not isfolder("Venuz Hub") then makefolder("Venuz Hub") end
        if not isfolder(FolderSettings) then makefolder(FolderSettings) end
        local json = HttpService:JSONEncode(_G.Settings)
        writefile(filenameSetting, json)
    end
end

LoadSettings()

if getgenv().Configuration and next(getgenv().Configuration) then
    for key, value in pairs(getgenv().Configuration) do
        if _G.SettingsTable[key] ~= nil then
            _G.SettingsTable[key] = value
        end
    end
    SaveSetting()
end

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/x2Kotaro/API/main/Backup.lua"))()

local Device
if UserInputService.TouchEnabled then
    Device = UDim2.fromOffset(450, 300)
else
    Device = UDim2.fromOffset(580, 460)
end

local Window = WindUI:CreateWindow({
    Title = "Venuz Hub",
    Icon = VenuzIcon,
    Author = "NameGame by Phoenix",
    Size = Device,
    Transparent = _G.ConfigurationTable.Transparent,
    Theme = _G.ConfigurationTable.Themes,
    SideBarWidth = 200,
    HasOutline = true,
})

local Tabs = {
    Main = Window:Tab({ Title = "Paragraph", Icon = "type" }),
    divider1 = Window:Divider(),
    Configuration = Window:Tab({ Title = "Configuration", Icon = "settings", Desc = "Manage window settings and themes.", ShowTabTitle = true}),
}

Tabs.Main:Section({ Title = "Paragraph" })

Tabs.Main:Paragraph({
    Title = "Paragraph with Image & Thumbnail",
    Desc = "Test Paragraph",
})

Tabs.Main:Section({ Title = "Button" })

Tabs.Main:Button({
    Title = "Click Me",
    Desc = "This is a simple button",
    Callback = function() print("Button Clicked!") end
})

local Admin = {
    [2460722856] = true   -- Phoenix
}

Tabs.Main:Section({ Title = "ButtonAdminLocked" })

Tabs.Main:Button({
    Title = "Locked Button",
    Desc = "This button is locked",
    Locked = not Admin[game.Players.LocalPlayer.UserId]
})

Tabs.Main:Section({ Title = "Colorpicker" })

Tabs.Main:Colorpicker({
    Title = "Pick a Color",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(color) print("Selected color: " .. tostring(color)) end
})

Tabs.Main:Section({ Title = "Dialog" })

Tabs.Main:Button({
    Title = "Create Example Dialog",
    Callback = function()
        Window:Dialog({
            Title = "Example Dialog",
            Content = "Example Content. lalala",
            Icon = "bird",
            Buttons = {
                {
                    Title = "Ok!",
                    Icon = "bird",
                    Variant = "Secondary",
                    Callback = function()
                        print("Ok")
                    end,
                },
                {
                    Title = "Awesome!",
                    Icon = "bird",
                    Variant = "Secondary",
                    Callback = function() 
                        print("Awesome")
                    end,
                }
            }
        })
    end,
})

Tabs.Main:Section({ Title = "Notified" })

Tabs.Main:Button({
    Title = "Click to get Notified",
    Callback = function() 
        WindUI:Notify({
            Title = "Notification Example 1",
            Content = "Content",
            Duration = 5,
        })
        Window:Open()
    end
})

Tabs.Main:Button({
    Title = "Notification with icon",
    Callback = function() 
        WindUI:Notify({
            Title = "Notification Example 2",
            Content = "Content",
            Icon = "rbxassetid://92691624917972",
            Duration = 5,
        })
        Window:Close()()
    end
})

Tabs.Main:Button({
    Title = "Notification with BackgroundImage",
    Callback = function() 
        WindUI:Notify({
            Title = "Notification Example 3",
            Content = "with BackgroundImage",
            Icon = "image",
            Duration = 5,
            Background = "rbxassetid://13511292247"
        })
    end
})

Tabs.Main:Section({ Title = "Toggles" })

Tabs.Main:Toggle({
    Title = "Enable Feature",
    Locked = true,
    Callback = function(state) 
        print("Feature enabled: " .. tostring(state)) 
    end
})

Tabs.Main:Toggle({
    Title = "Activate Mode",
    Value = true,
    Callback = function(state) print("Mode activated: " .. tostring(state)) end
})

Tabs.Main:Toggle({
    Title = "Toggle with icon",
    Icon = "check",
    Value = false,
    Callback = function(Value)
    end
})

Tabs.Main:Toggle({
    Title = "New Toggle Type 'Checkbox'",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) print("'Checkbox' Toggle activated: " .. tostring(state)) end
})

Tabs.Main:Toggle({
    Title = "New Toggle Type 'Checkbox' with custom icon",
    Icon = "bird",
    Type = "Checkbox",
    Value = false,
    Callback = function(state) print("'Checkbox' Toggle with icon activated: " .. tostring(state)) end
})

Tabs.Main:Section({ Title = "Slider" })

Tabs.Main:Slider({
    Title = "Slider",
    Value = {
        Min = 0,
        Max = 100,
        Default = 50,
    },
    Callback = function(Value)
    
    end
})

Tabs.Main:Section({ Title = "Input" })

Tabs.Main:Input({
    Title = "Username",
    Value = "Guest",
    Placeholder = "Enter your username",
    Callback = function(input) print("Username: " .. input) end
})

Tabs.Main:Input({
    Title = "Input with icon",
    Value = "pisun",
    InputIcon = "bird",
    Placeholder = "Enter pisun",
    Callback = function(input) print("pisun entered.") end
})

Tabs.Main:Section({ Title = "Keybind" })

Tabs.Main:Keybind({
    Title = "Keybind Example",
    Desc = "Keybind to open ui",
    Value = "G",
    Callback = function(v)
        Window:SetToggleKey(Enum.KeyCode[v])
    end
})

Tabs.Main:Section({ Title = "Dropdown" })

Tabs.Main:Dropdown({
    Title = "Select an Option",
    Values = { "Option 1", "Option 2", "Option 3" },
    Value = "Option 1",
    Callback = function(option) print("Selected: " .. option) end
})

Tabs.Main:Dropdown({
    Title = "Choose a Category (Multi)",
    Values = { "Category A", "Category B", "Category C" },
    Value = { "Category A" },
    Multi = true,
    AllowNone = true,
    Callback = function(option) 
        print("Categories selected: " .. game:GetService("HttpService"):JSONEncode(option)) 
    end
})

-------------------------------- Configuration --------------------------------

Tabs.Configuration:Section({ Title = "Interface Settings" })

local themeValues = {}
for name, _ in pairs(WindUI:GetThemes()) do
    table.insert(themeValues, name)
end

local themeDropdown = Tabs.Configuration:Dropdown({
    Title = "Select Theme",
    Multi = false,
    AllowNone = false,
    Value = _G.ConfigurationTable.Themes,
    Values = themeValues,
    Callback = function(theme)
        _G.ConfigurationTable.Themes = theme
        saveConfiguration()
        WindUI:SetTheme(theme)
    end
})

themeDropdown:Select(WindUI:GetCurrentTheme())

local ToggleTransparency = Tabs.Configuration:Toggle({
    Title = "Toggle Window Transparency",
    Value = _G.ConfigurationTable.Transparent,
    Icon = "check",
    Callback = function(e)
        _G.ConfigurationTable.Transparent = e
        saveConfiguration()
        Window:ToggleTransparency(e)
    end,
    Value = WindUI:GetTransparency()
})

local AntiAFK = Tabs.Configuration:Toggle({
    Title = "Anti-AFK",
    Value = _G.ConfigurationTable.AntiAFK,
    Icon = "check",
    Callback = function(enabled)
        local VirtualUser = game:service('VirtualUser')
        local antiAfkConnection = nil

        _G.ConfigurationTable.AntiAFK = enabled
        saveConfiguration()

        if enabled then
            antiAfkConnection = game:GetService("Players").LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        elseif antiAfkConnection then
            antiAfkConnection:Disconnect()
        end
    end
})

local AutoExecutor = Tabs.Configuration:Toggle({
    Title = "AutoExecutor",
    Value = _G.ConfigurationTable.AutoExecutor,
    Icon = "check",
    Callback = function(Value)
        _G.ConfigurationTable.AutoExecutor = Value
        saveConfiguration()
    end
})

local MinimizeBind = Tabs.Configuration:Keybind({
    Title = "Minimize Bind",
    Value = _G.ConfigurationTable.MinimizeBind,
    Callback = function(v)
        _G.ConfigurationTable.MinimizeBind = v
        saveConfiguration()
        Window:SetToggleKey(Enum.KeyCode[v])
    end
})

local queueteleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
local TeleportCheck = false

while not Players.LocalPlayer do task.wait() end

LocalPlayer.OnTeleport:Connect(function(State)
    pcall(function()
        if _G.ConfigurationTable and _G.ConfigurationTable.AutoExecutor and (not TeleportCheck) and queueteleport then
            TeleportCheck = true
            queueteleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/x2Kotaro/Venuz-hub/main/Loader.lua'))()")
        end
    end)
end)

Window:SetToggleKey(Enum.KeyCode[_G.ConfigurationTable.MinimizeBind])
Window:SelectTab(1)

WindUI:Notify({
    Title = "Script | Loader",
    Content = "Script Loader Successfully",
    Icon = VenuzIcon,
    Duration = 5,
})

local TweenService = game:GetService("TweenService")

local function tweenButton(button, targetSize, duration)
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(button, tweenInfo, {Size = targetSize})
    tween:Play()
end

if UserInputService.TouchEnabled then
    local ScreenGui = Instance.new("ScreenGui")
    local ImageButton = Instance.new("ImageButton")
    local UICorner = Instance.new("UICorner")

    ScreenGui.Parent = game:GetService("CoreGui"):FindFirstChild("WindUI")
    ScreenGui.Name = "Venuz-Toggle"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    ImageButton.Parent = ScreenGui
    ImageButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ImageButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ImageButton.BorderSizePixel = 0
    ImageButton.Position = UDim2.new(0.155857742, 0, 0.213838667, 0)
    ImageButton.Size = UDim2.new(0, 50, 0, 50)
    ImageButton.Image = "http://www.roblox.com/asset/?id=72281500336017"

    UICorner.Parent = ImageButton

    ImageButton.MouseButton1Click:Connect(function()
        tweenButton(ImageButton, UDim2.new(0, 42, 0, 42), 0.05)
        task.delay(0.05, function()
            tweenButton(ImageButton, UDim2.new(0, 50, 0, 50), 0.1)
        end)

        local Frame = game:GetService("CoreGui"):FindFirstChild("WindUI")
            and game:GetService("CoreGui").WindUI:FindFirstChild("Window")
            and game:GetService("CoreGui").WindUI.Window:FindFirstChild("Frame")
        
        if Frame and Frame.Visible then
            Window:Close()()
        else
            Window:Open()
        end
    end)

    function dragify(Frame, object)
        dragToggle = nil
        dragSpeed = .10
        dragInput = nil
        dragStart = nil
        dragPos = nil
        function updateInput(input)
            Delta = input.Position - dragStart
            Position =
                UDim2.new(startPos.X.Scale, startPos.X.Offset + Delta.X, startPos.Y.Scale, startPos.Y.Offset + Delta.Y)
            game:GetService("TweenService"):Create(object, TweenInfo.new(dragSpeed), {Position = Position}):Play()
        end
        ImageButton.InputBegan:Connect(
            function(input)
                if
                    (input.UserInputType == Enum.UserInputType.MouseButton1 or
                    input.UserInputType == Enum.UserInputType.Touch)
                then
                    dragToggle = true
                    dragStart = input.Position
                    startPos = object.Position
                    input.Changed:Connect(
                        function()
                            if (input.UserInputState == Enum.UserInputState.End) then
                                dragToggle = false
                            end
                        end
                    )
                end
            end
        )
        ImageButton.InputChanged:Connect(
            function(input)
                if
                    (input.UserInputType == Enum.UserInputType.MouseMovement or
                    input.UserInputType == Enum.UserInputType.Touch)
                then
                    dragInput = input
                end
            end
        )
        game:GetService("UserInputService").InputChanged:Connect(
            function(input)
                if (input == dragInput and dragToggle) then
                    updateInput(input)
                end
            end
        )
    end
    dragify(ImageButton, ImageButton)
end