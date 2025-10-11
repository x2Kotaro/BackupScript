repeat task.wait() until game:IsLoaded()

if checkexecutor == "Xeno" then
    task.wait(1)
    game.Players.LocalPlayer:Kick("Xeno not supported, please check 🟢﹕status in Discord")
elseif checkexecutor == "Solara" then
    task.wait(1)
    game.Players.LocalPlayer:Kick("Solara not supported, please check 🟢﹕status in Discord")
end

local UserKey = ""
local PlayerService = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Service = "venuzhub"
local HWID = game:GetService("RbxAnalyticsService"):GetClientId()
local checkexecutor = identifyexecutor()

local KeyFile = "Venuz Hub/KeySystem".."/".."VenuzKey"..".txt"

local TextContent = {
    WelcomeTitle = "Welcome to Venuz Hub",
    KeySystemTitle = "Authentication Required",
    EnterKey = "Enter your key to continue",
    GetKey = "Get Key",
    SubmitKey = "Authenticate",
    Validating = "Verifying credentials...",
    CheckingGame = "Scanning game environment...",
    LoadingSaved = "Loading cached credentials...",
    CorrectKey = "Authentication successful!",
    WrongKey = "Invalid key",
    PremiumUser = "Account Type: Premium",
    NormalUser = "Account Type: Standard",
    GameDetected = "Game detected:",
    GameNotFound = "No supported game found",
    DiscordCopied = "Discord link copied to clipboard",
    KeyCopied = "Key link copied to clipboard",
    PleaseEnterKey = "Please enter your key",
    RequestFailed = "Connection failed",
    NoHTTPSupport = "HTTP requests not supported",
    RequestingData = "Requesting data...",
    LoadingScript = "Loading script...",
    ScriptLoaded = "Script loaded successfully"
}

local function getRevenueMode()
    local url = "https://pandadevelopment.net/api/revenue-mode?service=" .. Service
    
    local success, response = pcall(function()
        return http.request({
            Url = url,
            Method = "GET",
            Headers = { ["Content-Type"] = "application/json" }
        })
    end)
    if success and response.Success then
        local responseJson = HttpService:JSONDecode(response.Body)
        return responseJson.revenueMode or ""
    else
        warn("Error getting revenue mode:", response and response.StatusCode or "Request failed")
        return ""
    end
end

local function SaveKey(key)
    local FolderPath = "Venuz Hub/KeySystem"
    
    if not isfolder(FolderPath) then
        makefolder(FolderPath)
    end

    if writefile then
        writefile(KeyFile, key)
    end
end

local function LoadKey()
    if readfile and pcall(function() readfile(KeyFile) end) then
        return readfile(KeyFile)
    end
    return ""
end

function RemoveKeyUI()
    do
        local keyui = game:GetService("CoreGui"):FindFirstChild("VenuzPremiumKey")
        if keyui then
            keyui:Destroy()
        end
    end
end
RemoveKeyUI()

local AlertSystem = {}
AlertSystem.ActiveAlerts = {}
AlertSystem.Container = nil

function AlertSystem:CreateContainer()
    if not self.Container then
        local containerGui = Instance.new("ScreenGui")
        local containerFrame = Instance.new("Frame")
        local listLayout = Instance.new("UIListLayout")
        
        containerGui.Name = "AlertContainer"
        containerGui.Parent = game:GetService("CoreGui")
        containerGui.ResetOnSpawn = false
        containerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        containerGui.DisplayOrder = 999
        
        containerFrame.Name = "Container"
        containerFrame.Parent = containerGui
        containerFrame.AnchorPoint = Vector2.new(0.5, 0)
        containerFrame.Position = UDim2.new(0.5, 0, 0, 20)
        containerFrame.Size = UDim2.new(0, 300, 0, 0)
        containerFrame.BackgroundTransparency = 1
        containerFrame.AutomaticSize = Enum.AutomaticSize.Y
        
        listLayout.Parent = containerFrame
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 12)
        listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        
        self.Container = containerFrame
    end
    return self.Container
end

function AlertSystem:CreateAlert(config)
    local TweenService = game:GetService("TweenService")
    local container = self:CreateContainer()
    
    local alertFrame = Instance.new("Frame")
    local alertCorner = Instance.new("UICorner")
    local gradient = Instance.new("UIGradient")
    local glowFrame = Instance.new("Frame")
    local glowCorner = Instance.new("UICorner")
    local glowGradient = Instance.new("UIGradient")
    local iconFrame = Instance.new("Frame")
    local iconCorner = Instance.new("UICorner")
    local iconLabel = Instance.new("TextLabel")
    local messageLabel = Instance.new("TextLabel")
    local particleFrame = Instance.new("Frame")
    
    local colors = {
        success = {
            main = Color3.fromRGB(16, 185, 129),
            glow = Color3.fromRGB(52, 211, 153),
            dark = Color3.fromRGB(6, 78, 59),
            icon = "✓"
        },
        error = {
            main = Color3.fromRGB(239, 68, 68),
            glow = Color3.fromRGB(252, 165, 165),
            dark = Color3.fromRGB(127, 29, 29),
            icon = "✗"
        },
        info = {
            main = Color3.fromRGB(59, 130, 246),
            glow = Color3.fromRGB(147, 197, 253),
            dark = Color3.fromRGB(30, 58, 138),
            icon = "ℹ"
        },
        warning = {
            main = Color3.fromRGB(245, 158, 11),
            glow = Color3.fromRGB(251, 191, 36),
            dark = Color3.fromRGB(120, 53, 15),
            icon = "⚠"
        },
        loading = {
            main = Color3.fromRGB(147, 51, 234),
            glow = Color3.fromRGB(192, 132, 252),
            dark = Color3.fromRGB(88, 28, 135),
            icon = "⟳"
        }
    }
    
    local alertColor = colors[config.Type or "info"]
    
    -- Outer Glow
    glowFrame.Name = "GlowFrame"
    glowFrame.Parent = alertFrame
    glowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    glowFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    glowFrame.Size = UDim2.new(1, 16, 1, 16)
    glowFrame.BackgroundColor3 = alertColor.glow
    glowFrame.BackgroundTransparency = 0.4
    glowFrame.BorderSizePixel = 0
    glowFrame.ZIndex = 1
    
    glowCorner.CornerRadius = UDim.new(0, 26)
    glowCorner.Parent = glowFrame
    
    glowGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, alertColor.glow),
        ColorSequenceKeypoint.new(1, alertColor.dark)
    }
    glowGradient.Rotation = 45
    glowGradient.Parent = glowFrame
    
    -- Main Alert Frame
    alertFrame.Name = "AlertFrame"
    alertFrame.Parent = container
    alertFrame.Size = UDim2.new(0, 280, 0, 52)
    alertFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    alertFrame.BorderSizePixel = 0
    alertFrame.ZIndex = 2
    alertFrame.LayoutOrder = #self.ActiveAlerts + 1
    
    alertCorner.CornerRadius = UDim.new(0, 20)
    alertCorner.Parent = alertFrame
    
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 28)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(22, 22, 22)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 18))
    }
    gradient.Rotation = 135
    gradient.Parent = alertFrame
    
    -- Particle Effect Background
    particleFrame.Name = "ParticleFrame"
    particleFrame.Parent = alertFrame
    particleFrame.Size = UDim2.new(1, 0, 1, 0)
    particleFrame.BackgroundColor3 = alertColor.main
    particleFrame.BackgroundTransparency = 0.96
    particleFrame.BorderSizePixel = 0
    particleFrame.ZIndex = 2
    
    local particleCorner = Instance.new("UICorner")
    particleCorner.CornerRadius = UDim.new(0, 20)
    particleCorner.Parent = particleFrame
    
    -- Icon Frame
    iconFrame.Name = "IconFrame"
    iconFrame.Parent = alertFrame
    iconFrame.Position = UDim2.new(0, 12, 0.5, -16)
    iconFrame.Size = UDim2.new(0, 32, 0, 32)
    iconFrame.BackgroundColor3 = alertColor.main
    iconFrame.BackgroundTransparency = 0.85
    iconFrame.BorderSizePixel = 0
    iconFrame.ZIndex = 4
    
    iconCorner.CornerRadius = UDim.new(0, 10)
    iconCorner.Parent = iconFrame
    
    -- Icon Gradient
    local iconGradient = Instance.new("UIGradient")
    iconGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, alertColor.glow),
        ColorSequenceKeypoint.new(1, alertColor.main)
    }
    iconGradient.Rotation = 135
    iconGradient.Parent = iconFrame
    
    -- Icon
    iconLabel.Name = "IconLabel"
    iconLabel.Parent = iconFrame
    iconLabel.Size = UDim2.new(1, 0, 1, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = alertColor.icon
    iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconLabel.TextSize = 18
    iconLabel.Font = Enum.Font.SourceSansBold
    iconLabel.TextXAlignment = Enum.TextXAlignment.Center
    iconLabel.TextYAlignment = Enum.TextYAlignment.Center
    iconLabel.ZIndex = 5
    
    -- Message
    messageLabel.Name = "MessageLabel"
    messageLabel.Parent = alertFrame
    messageLabel.Position = UDim2.new(0, 54, 0, 0)
    messageLabel.Size = UDim2.new(1, -64, 1, 0)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = config.Content or config.Title or "Notification"
    messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    messageLabel.TextSize = 14
    messageLabel.Font = Enum.Font.SourceSansSemibold
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Center
    messageLabel.TextTruncate = Enum.TextTruncate.AtEnd
    messageLabel.ZIndex = 4
    
    -- Accent Bar
    local accentBar = Instance.new("Frame")
    accentBar.Name = "AccentBar"
    accentBar.Parent = alertFrame
    accentBar.Position = UDim2.new(0, 0, 0, 0)
    accentBar.Size = UDim2.new(0, 3, 1, 0)
    accentBar.BackgroundColor3 = alertColor.main
    accentBar.BorderSizePixel = 0
    accentBar.ZIndex = 5
    
    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(1, 0)
    accentCorner.Parent = accentBar
    
    table.insert(self.ActiveAlerts, alertFrame)
    
    -- Spawn Animation
    alertFrame.Size = UDim2.new(0, 0, 0, 52)
    alertFrame.BackgroundTransparency = 1
    iconLabel.TextTransparency = 1
    messageLabel.TextTransparency = 1
    glowFrame.BackgroundTransparency = 1
    accentBar.BackgroundTransparency = 1
    
    local expandTween = TweenService:Create(alertFrame, 
        TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 280, 0, 52),
        BackgroundTransparency = 0
    })
    
    TweenService:Create(glowFrame, TweenInfo.new(0.6), {
        BackgroundTransparency = 0.4
    }):Play()
    
    TweenService:Create(iconLabel, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
        TextTransparency = 0
    }):Play()
    
    TweenService:Create(messageLabel, TweenInfo.new(0.4), {
        TextTransparency = 0
    }):Play()
    
    TweenService:Create(accentBar, TweenInfo.new(0.4), {
        BackgroundTransparency = 0
    }):Play()
    
    expandTween:Play()
    
    -- Rotating Gradient Effect
    spawn(function()
        local rotation = 0
        while alertFrame.Parent do
            rotation = rotation + 2
            gradient.Rotation = 135 + math.sin(rotation / 30) * 20
            glowGradient.Rotation = 45 + rotation
            iconGradient.Rotation = 135 + rotation * 2
            wait(0.03)
        end
    end)
    
    -- Glow Pulse
    spawn(function()
        while glowFrame.Parent do
            TweenService:Create(glowFrame, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundTransparency = 0.6,
                Size = UDim2.new(1, 20, 1, 20)
            }):Play()
            wait(1.2)
            TweenService:Create(glowFrame, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundTransparency = 0.4,
                Size = UDim2.new(1, 16, 1, 16)
            }):Play()
            wait(1.2)
        end
    end)
    
    -- Icon Frame Pulse
    spawn(function()
        while iconFrame.Parent do
            TweenService:Create(iconFrame, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {
                BackgroundTransparency = 0.7,
                Size = UDim2.new(0, 36, 0, 36)
            }):Play()
            wait(0.8)
            TweenService:Create(iconFrame, TweenInfo.new(0.8, Enum.EasingStyle.Sine), {
                BackgroundTransparency = 0.85,
                Size = UDim2.new(0, 32, 0, 32)
            }):Play()
            wait(0.8)
        end
    end)
    
    -- Loading Icon Rotation
    if config.Type == "loading" then
        spawn(function()
            local rotation = 0
            while iconLabel.Parent do
                rotation = rotation + 8
                iconLabel.Rotation = rotation
                wait(0.02)
            end
        end)
    end
    
    -- Auto Dismiss
    if config.Duration and config.Duration > 0 then
        spawn(function()
            wait(config.Duration)
            
            TweenService:Create(alertFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 0, 0, 52),
                BackgroundTransparency = 1
            }):Play()
            
            TweenService:Create(glowFrame, TweenInfo.new(0.5), {
                BackgroundTransparency = 1
            }):Play()
            
            TweenService:Create(iconLabel, TweenInfo.new(0.3), {
                TextTransparency = 1
            }):Play()
            
            TweenService:Create(messageLabel, TweenInfo.new(0.3), {
                TextTransparency = 1
            }):Play()
            
            TweenService:Create(accentBar, TweenInfo.new(0.3), {
                BackgroundTransparency = 1
            }):Play()
            
            wait(0.5)
            
            for i, alert in ipairs(self.ActiveAlerts) do
                if alert == alertFrame then
                    table.remove(self.ActiveAlerts, i)
                    break
                end
            end
            
            alertFrame:Destroy()
        end)
    end
    
    return alertFrame
end

function ValidateKey()
    if not UserKey or UserKey == "" then
        AlertSystem:CreateAlert({
            Title = "Authentication",
            Content = TextContent.PleaseEnterKey,
            Type = "error",
            Duration = 3
        })
        return false
    end

    local success, response = pcall(function()
        local res = http.request({
            Url = "https://pandadevelopment.net/v2_validation?key=" .. UserKey .. "&service=venuzhub&hwid=" .. HWID,
            Method = "GET",
            Headers = {
                ["Content-Type"] = "application/json"
            },
        }).Body
        return HttpService:JSONDecode(res)
    end)

    if not success or not response then
        AlertSystem:CreateAlert({
            Title = "Authentication",
            Content = "Error occurred while contacting server.",
            Type = "error",
            Duration = 3
        })
        return false
    end

    if response["V2_Authentication"] == "success" then
        if response["Key_Information"].Premium_Mode == true then
            AlertSystem:CreateAlert({
                Title = "Authentication",
                Content = TextContent.CorrectKey .. " (Premium Mode)",
                Type = "success",
                Duration = 2
            })
        else
            AlertSystem:CreateAlert({
                Title = "Authentication",
                Content = TextContent.CorrectKey .. " (Free Mode)",
                Type = "success",
                Duration = 2
            })
        end

        SaveKey(UserKey)
        RemoveKeyUI()

        task.wait(3)

        local PlaceId = game.PlaceId
        local gameNames = {
            [17357719939] = "Wizard West",
            [126265917374091] = "Wizard West",
            [87039211657390] = "Arise Crossover",
            [116614712661486] = "Arise Crossover",
            [128336380114944] = "Arise Crossover",
            [111989938562194] = "Brainrot Evolution",
            [129827112113663] = "Prospecting",
            [105555311806207] = "Build A Zoo"
        }

        local gameName = gameNames[PlaceId]
        if gameName then
            AlertSystem:CreateAlert({
                Title = "Venuz Hub",
                Content = TextContent.GameDetected .. " " .. gameName,
                Type = "info",
                Duration = 2
            })
            task.wait(1.8)

            if PlaceId == 17357719939 or PlaceId == 126265917374091 then
                loadstring(game:HttpGet("https://raw.githubusercontent.com/VenuzHub/Scripts/main/WizardWest.lua"))()
            elseif PlaceId == 87039211657390 or PlaceId == 116614712661486 or PlaceId == 128336380114944 then
                loadstring(game:HttpGet("https://raw.githubusercontent.com/VenuzHub/Scripts/main/Arise_Crossover.lua"))()
            elseif PlaceId == 111989938562194 then
                loadstring(game:HttpGet("https://raw.githubusercontent.com/x2Kotaro/Venuz-hub/main/BrainrotEvolution.lua"))()
            elseif PlaceId == 129827112113663 then
                loadstring(game:HttpGet("https://raw.githubusercontent.com/VenuzHub/Scripts/main/Prospecting.lua"))()
            elseif PlaceId == 105555311806207 then
                loadstring(game:HttpGet("https://raw.githubusercontent.com/VenuzHub/Scripts/refs/heads/main/BuildAZoo.lua"))()
            elseif PlaceId == 127742093697776 then
                loadstring(game:HttpGet("https://raw.githubusercontent.com/VenuzHub/Scripts/main/PlnatVs.lua"))()
            end
        else
            game.Players.LocalPlayer:Kick("Venuz Hub | " .. TextContent.GameNotFound)
        end

        return true
    else
        AlertSystem:CreateAlert({
            Title = "Authentication",
            Content = TextContent.WrongKey,
            Type = "error",
            Duration = 3
        })
        return false
    end
end

local statusText

function ValidateKeyAlready(statusTextElement)
    if not UserKey or UserKey == "" then
        if statusTextElement then
            statusTextElement.Text = TextContent.PleaseEnterKey
        end
        return false
    end

    if statusTextElement then
        statusTextElement.Text = TextContent.RequestingData
    end
    task.wait(0.3)

    local success, response = pcall(function()
        local res = http.request({
            Url = "https://pandadevelopment.net/v2_validation?key=" .. UserKey .. "&service=venuzhub&hwid=" .. HWID,
            Method = "GET",
            Headers = {
                ["Content-Type"] = "application/json"
            },
        }).Body
        return HttpService:JSONDecode(res)
    end)

    if not success or not response then
        if statusTextElement then
            statusTextElement.Text = TextContent.NoHTTPSupport
        end
        return false
    end

    if response["V2_Authentication"] == "success" then
        if statusTextElement then
            if response["Key_Information"].Premium_Mode then
                statusTextElement.Text = TextContent.CorrectKey .. " (Premium Mode)"
            else
                statusTextElement.Text = TextContent.CorrectKey .. " (Free Mode)"
            end
        end

        SaveKey(UserKey)
        task.wait(1)

        if statusTextElement then
            statusTextElement.Text = TextContent.CheckingGame
        end
        task.wait(0.5)

        local PlaceId = game.PlaceId
        local gameNames = {
            [17357719939] = "Wizard West",
            [126265917374091] = "Wizard West",
            [87039211657390] = "Arise Crossover",
            [116614712661486] = "Arise Crossover",
            [128336380114944] = "Arise Crossover",
            [111989938562194] = "Brainrot Evolution",
            [129827112113663] = "Prospecting",
            [105555311806207] = "Build A Zoo",
            [127742093697776] = "Plants Vs Brainrots"
        }

        local gameName = gameNames[PlaceId]
        if gameName then
            if statusTextElement then
                statusTextElement.Text = TextContent.GameDetected .. " " .. gameName
            end
            task.wait(1)
            return true
        else
            if statusTextElement then
                statusTextElement.Text = TextContent.GameNotFound
            end
            task.wait(2)
            game.Players.LocalPlayer:Kick("Venuz Hub | " .. TextContent.GameNotFound)
            return false
        end
    else
        if statusTextElement then
            statusTextElement.Text = TextContent.WrongKey
        end
        return false
    end
end

UserKey = LoadKey()

if UserKey ~= "" then
    local function CreateSavedKeyUI()
        local TweenService = game:GetService("TweenService")
        local savedKeyGui = Instance.new("ScreenGui")
        local mainFrame = Instance.new("Frame")
        local contentFrame = Instance.new("Frame")
        local cornerMain = Instance.new("UICorner")
        local strokeMain = Instance.new("UIStroke")

        local headerFrame = Instance.new("Frame")
        local titleLabel = Instance.new("TextLabel")
        local statusLabel = Instance.new("TextLabel")
        
        local logoFrame = Instance.new("Frame")
        local logoCorner = Instance.new("UICorner")
        local logoLabel = Instance.new("TextLabel")
        
        local progressFrame = Instance.new("Frame")
        local progressBar = Instance.new("Frame")
        local progressFill = Instance.new("Frame")
        local progressCorners = {}
        progressCorners[1] = Instance.new("UICorner")
        progressCorners[2] = Instance.new("UICorner")
        
        local localStatusText = Instance.new("TextLabel")
        
        savedKeyGui.Name = "VenuzModernSavedKey"
        savedKeyGui.Parent = game:GetService("CoreGui")
        savedKeyGui.ResetOnSpawn = false
        
        mainFrame.Name = "MainFrame"
        mainFrame.Parent = savedKeyGui
        mainFrame.Size = UDim2.new(1, 0, 1, 0)
        mainFrame.BackgroundTransparency = 1
        mainFrame.BorderSizePixel = 0
        
        contentFrame.Name = "ContentFrame"
        contentFrame.Parent = mainFrame
        contentFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        contentFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        contentFrame.Size = UDim2.new(0, 400, 0, 280)
        contentFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
        contentFrame.BorderSizePixel = 0
        
        cornerMain.CornerRadius = UDim.new(0, 16)
        cornerMain.Parent = contentFrame
        
        strokeMain.Color = Color3.fromRGB(38, 38, 38)
        strokeMain.Thickness = 1
        strokeMain.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        strokeMain.Parent = contentFrame

        headerFrame.Name = "HeaderFrame"
        headerFrame.Parent = contentFrame
        headerFrame.Size = UDim2.new(1, 0, 0, 120)
        headerFrame.BackgroundTransparency = 1
        headerFrame.BorderSizePixel = 0
        
        logoFrame.Name = "LogoFrame"
        logoFrame.Parent = headerFrame
        logoFrame.AnchorPoint = Vector2.new(0.5, 0)
        logoFrame.Position = UDim2.new(0.5, 0, 0, 20)
        logoFrame.Size = UDim2.new(0, 60, 0, 60)
        logoFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        logoFrame.BorderSizePixel = 0
        
        logoCorner.CornerRadius = UDim.new(0, 12)
        logoCorner.Parent = logoFrame
        
        logoLabel.Name = "LogoLabel"
        logoLabel.Parent = logoFrame
        logoLabel.Size = UDim2.new(1, 0, 1, 0)
        logoLabel.BackgroundTransparency = 1
        logoLabel.Text = "V"
        logoLabel.TextColor3 = Color3.fromRGB(147, 51, 234)
        logoLabel.TextSize = 28
        logoLabel.Font = Enum.Font.SourceSansBold
        logoLabel.TextXAlignment = Enum.TextXAlignment.Center
        
        titleLabel.Name = "TitleLabel"
        titleLabel.Parent = headerFrame
        titleLabel.AnchorPoint = Vector2.new(0.5, 0)
        titleLabel.Position = UDim2.new(0.5, 0, 0, 85)
        titleLabel.Size = UDim2.new(0.9, 0, 0, 25)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = "Venuz Hub"
        titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        titleLabel.TextSize = 20
        titleLabel.Font = Enum.Font.SourceSansSemibold
        
        statusLabel.Name = "StatusLabel"
        statusLabel.Parent = headerFrame
        statusLabel.AnchorPoint = Vector2.new(0.5, 0)
        statusLabel.Position = UDim2.new(0.5, 0, 0, 105)
        statusLabel.Size = UDim2.new(0.9, 0, 0, 20)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Text = TextContent.LoadingSaved
        statusLabel.TextColor3 = Color3.fromRGB(163, 163, 163)
        statusLabel.TextSize = 12
        statusLabel.Font = Enum.Font.SourceSans
        
        progressFrame.Name = "ProgressFrame"
        progressFrame.Parent = contentFrame
        progressFrame.Position = UDim2.new(0, 30, 0, 150)
        progressFrame.Size = UDim2.new(1, -60, 0, 80)
        progressFrame.BackgroundTransparency = 1
        
        progressBar.Name = "ProgressBar"
        progressBar.Parent = progressFrame
        progressBar.Position = UDim2.new(0, 0, 0, 30)
        progressBar.Size = UDim2.new(1, 0, 0, 6)
        progressBar.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
        progressBar.BorderSizePixel = 0
        
        progressCorners[1].CornerRadius = UDim.new(0, 3)
        progressCorners[1].Parent = progressBar
        
        progressFill.Name = "ProgressFill"
        progressFill.Parent = progressBar
        progressFill.Size = UDim2.new(0, 0, 1, 0)
        progressFill.BackgroundColor3 = Color3.fromRGB(147, 51, 234)
        progressFill.BorderSizePixel = 0
        
        progressCorners[2].CornerRadius = UDim.new(0, 3)
        progressCorners[2].Parent = progressFill
        
        localStatusText.Name = "StatusText"
        localStatusText.Parent = progressFrame
        localStatusText.Position = UDim2.new(0, 0, 0, 50)
        localStatusText.Size = UDim2.new(1, 0, 0, 20)
        localStatusText.BackgroundTransparency = 1
        localStatusText.Text = TextContent.LoadingSaved
        localStatusText.TextColor3 = Color3.fromRGB(163, 163, 163)
        localStatusText.TextSize = 14
        localStatusText.Font = Enum.Font.SourceSans
        localStatusText.TextXAlignment = Enum.TextXAlignment.Center
        
        contentFrame.Position = UDim2.new(0.5, 0, 0.5, 50)
        contentFrame.Size = UDim2.new(0, 0, 0, 0)
        mainFrame.BackgroundTransparency = 1
        
        TweenService:Create(mainFrame, TweenInfo.new(0.3), {
            BackgroundTransparency = 1
        }):Play()
        
        TweenService:Create(contentFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back), {
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 400, 0, 280)
        }):Play()
        
        return savedKeyGui, localStatusText, progressFill
    end
    
    local savedKeyGui, uiStatusText, progressFill = CreateSavedKeyUI()
    statusText = uiStatusText
    
    local TweenService = game:GetService("TweenService")
    
    statusText.Text = TextContent.LoadingSaved
    TweenService:Create(progressFill, TweenInfo.new(0.5), {Size = UDim2.new(0.2, 0, 1, 0)}):Play()
    task.wait(0.8)
    
    statusText.Text = TextContent.RequestingData
    TweenService:Create(progressFill, TweenInfo.new(0.5), {Size = UDim2.new(0.4, 0, 1, 0)}):Play()
    
    local isValid = ValidateKeyAlready(statusText)
    
    if isValid then
        TweenService:Create(progressFill, TweenInfo.new(0.5), {Size = UDim2.new(0.8, 0, 1, 0)}):Play()
        task.wait(0.5)

        statusText.Text = "Loading Successfully"
        TweenService:Create(progressFill, TweenInfo.new(0.5), {Size = UDim2.new(1.0, 0, 1, 0)}):Play()
        task.wait(1)

        statusText.Text = "Enjoy!"
        task.wait(1)
        
        TweenService:Create(savedKeyGui.MainFrame.ContentFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 25)
        }):Play()
        
        task.wait(0.4)
        savedKeyGui:Destroy()
        task.wait(0.5)
        
        local PlaceId = game.PlaceId
        if PlaceId == 17357719939 or PlaceId == 126265917374091 then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/VenuzHub/Scripts/main/WizardWest.lua"))()
        elseif PlaceId == 87039211657390 or PlaceId == 116614712661486 or PlaceId == 128336380114944 then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/VenuzHub/Scripts/main/Arise_Crossover.lua"))()
        elseif PlaceId == 111989938562194 then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/x2Kotaro/Venuz-hub/main/BrainrotEvolution.lua"))()
        elseif PlaceId == 129827112113663 then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/VenuzHub/Scripts/main/Prospecting.lua"))()
        elseif PlaceId == 105555311806207 then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/VenuzHub/Scripts/main/BuildAZoo.lua"))()
        elseif PlaceId == 127742093697776 then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/VenuzHub/Scripts/main/PlnatVs.lua"))()
        end
        return
    else
        statusText.Text = TextContent.WrongKey
        task.wait(2)
        
        TweenService:Create(savedKeyGui.MainFrame.ContentFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 25)
        }):Play()
        
        task.wait(0.4)
        savedKeyGui:Destroy()
        
        UserKey = ""
        SaveKey("")
    end
end

local function CreateModernKeyUI()
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    
    local KeySystem = Instance.new("ScreenGui")
    local MainFrame = Instance.new("Frame")
    local KeyContainer = Instance.new("Frame")
    local UICorner = Instance.new("UICorner")
    local UIStroke = Instance.new("UIStroke")
    local MainGradient = Instance.new("UIGradient")
    
    -- Outer Glow
    local GlowFrame = Instance.new("Frame")
    local GlowCorner = Instance.new("UICorner")
    local GlowGradient = Instance.new("UIGradient")

    -- Header
    local HeaderFrame = Instance.new("Frame")
    local HeaderGradient = Instance.new("UIGradient")
    local LogoFrame = Instance.new("Frame")
    local LogoCorner = Instance.new("UICorner")
    local LogoGradient = Instance.new("UIGradient")
    local LogoLabel = Instance.new("TextLabel")
    local TitleLabel = Instance.new("TextLabel")
    local CloseButton = Instance.new("TextButton")
    local CloseCorner = Instance.new("UICorner")
    
    -- Content
    local ContentFrame = Instance.new("Frame")
    local DescriptionLabel = Instance.new("TextLabel")
    
    -- Input
    local InputFrame = Instance.new("Frame")
    local InputCorner = Instance.new("UICorner")
    local InputStroke = Instance.new("UIStroke")
    local InputGradient = Instance.new("UIGradient")
    local InputIcon = Instance.new("TextLabel")
    local KeyInput = Instance.new("TextBox")
    
    -- Buttons
    local ButtonFrame = Instance.new("Frame")
    
    local GetKeyButton = Instance.new("TextButton")
    local GetKeyCorner = Instance.new("UICorner")
    local GetKeyStroke = Instance.new("UIStroke")
    local GetKeyGradient = Instance.new("UIGradient")
    
    local SubmitButton = Instance.new("TextButton")
    local SubmitCorner = Instance.new("UICorner")
    local SubmitGradient = Instance.new("UIGradient")

    local Colors = {
        Background = Color3.fromRGB(18, 18, 18),
        Surface = Color3.fromRGB(25, 25, 25),
        Border = Color3.fromRGB(45, 45, 45),
        Primary = Color3.fromRGB(147, 51, 234),
        PrimaryLight = Color3.fromRGB(192, 132, 252),
        PrimaryDark = Color3.fromRGB(88, 28, 135),
        Secondary = Color3.fromRGB(59, 130, 246),
        Success = Color3.fromRGB(16, 185, 129),
        Error = Color3.fromRGB(239, 68, 68),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(180, 180, 180),
        TextMuted = Color3.fromRGB(130, 130, 130)
    }
    
    KeySystem.Name = "VenuzPremiumKey"
    KeySystem.Parent = game:GetService("CoreGui")
    KeySystem.ResetOnSpawn = false
    KeySystem.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    KeySystem.DisplayOrder = 100
    
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = KeySystem
    MainFrame.Size = UDim2.new(1, 0, 1, 0)
    MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    MainFrame.BackgroundTransparency = 1
    MainFrame.BorderSizePixel = 0
    
    -- Outer Glow Effect
    GlowFrame.Name = "GlowFrame"
    GlowFrame.Parent = MainFrame
    GlowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    GlowFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    GlowFrame.Size = UDim2.new(0, 360, 0, 440)
    GlowFrame.BackgroundColor3 = Colors.Primary
    GlowFrame.BackgroundTransparency = 0.5
    GlowFrame.BorderSizePixel = 0
    GlowFrame.ZIndex = 1
    
    GlowCorner.CornerRadius = UDim.new(0, 24)
    GlowCorner.Parent = GlowFrame
    
    GlowGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Colors.PrimaryLight),
        ColorSequenceKeypoint.new(0.5, Colors.Primary),
        ColorSequenceKeypoint.new(1, Colors.PrimaryDark)
    }
    GlowGradient.Rotation = 45
    GlowGradient.Parent = GlowFrame
    
    -- Main Container
    KeyContainer.Name = "KeyContainer"
    KeyContainer.Parent = MainFrame
    KeyContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    KeyContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
    KeyContainer.Size = UDim2.new(0, 340, 0, 420)
    KeyContainer.BackgroundColor3 = Colors.Background
    KeyContainer.BorderSizePixel = 0
    KeyContainer.ClipsDescendants = true
    KeyContainer.ZIndex = 2
    
    UICorner.CornerRadius = UDim.new(0, 20)
    UICorner.Parent = KeyContainer
    
    UIStroke.Color = Colors.Border
    UIStroke.Thickness = 1.5
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Transparency = 0.3
    UIStroke.Parent = KeyContainer
    
    MainGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 22, 22)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(18, 18, 18)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 16, 16))
    }
    MainGradient.Rotation = 135
    MainGradient.Parent = KeyContainer

    -- Header with Gradient
    HeaderFrame.Name = "HeaderFrame"
    HeaderFrame.Parent = KeyContainer
    HeaderFrame.Size = UDim2.new(1, 0, 0, 110)
    HeaderFrame.BackgroundColor3 = Colors.Primary
    HeaderFrame.BackgroundTransparency = 0.92
    HeaderFrame.BorderSizePixel = 0
    HeaderFrame.ZIndex = 3
    
    HeaderGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Colors.Primary),
        ColorSequenceKeypoint.new(1, Colors.PrimaryDark)
    }
    HeaderGradient.Rotation = 135
    HeaderGradient.Parent = HeaderFrame
    
    -- Logo with Gradient Background
    LogoFrame.Name = "LogoFrame"
    LogoFrame.Parent = HeaderFrame
    LogoFrame.AnchorPoint = Vector2.new(0.5, 0)
    LogoFrame.Position = UDim2.new(0.5, 0, 0, 18)
    LogoFrame.Size = UDim2.new(0, 48, 0, 48)
    LogoFrame.BackgroundColor3 = Colors.Primary
    LogoFrame.BackgroundTransparency = 0.8
    LogoFrame.BorderSizePixel = 0
    LogoFrame.ZIndex = 4
    
    LogoCorner.CornerRadius = UDim.new(0, 12)
    LogoCorner.Parent = LogoFrame
    
    LogoGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Colors.PrimaryLight),
        ColorSequenceKeypoint.new(1, Colors.Primary)
    }
    LogoGradient.Rotation = 135
    LogoGradient.Parent = LogoFrame
    
    LogoLabel.Name = "LogoLabel"
    LogoLabel.Parent = LogoFrame
    LogoLabel.Size = UDim2.new(1, 0, 1, 0)
    LogoLabel.BackgroundTransparency = 1
    LogoLabel.Text = "V"
    LogoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    LogoLabel.TextSize = 26
    LogoLabel.Font = Enum.Font.SourceSansBold
    LogoLabel.ZIndex = 5
    
    TitleLabel.Name = "TitleLabel"
    TitleLabel.Parent = HeaderFrame
    TitleLabel.AnchorPoint = Vector2.new(0.5, 0)
    TitleLabel.Position = UDim2.new(0.5, 0, 0, 72)
    TitleLabel.Size = UDim2.new(0.9, 0, 0, 28)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "VENUZ HUB"
    TitleLabel.TextColor3 = Colors.Text
    TitleLabel.TextSize = 19
    TitleLabel.Font = Enum.Font.SourceSansBold
    TitleLabel.ZIndex = 4
    
    -- Close Button
    CloseButton.Name = "CloseButton"
    CloseButton.Parent = HeaderFrame
    CloseButton.AnchorPoint = Vector2.new(1, 0)
    CloseButton.Position = UDim2.new(1, -12, 0, 12)
    CloseButton.Size = UDim2.new(0, 32, 0, 32)
    CloseButton.BackgroundColor3 = Colors.Surface
    CloseButton.BackgroundTransparency = 0.2
    CloseButton.BorderSizePixel = 0
    CloseButton.Text = "×"
    CloseButton.TextColor3 = Colors.TextSecondary
    CloseButton.TextSize = 22
    CloseButton.Font = Enum.Font.SourceSansBold
    CloseButton.ZIndex = 5
    
    CloseCorner.CornerRadius = UDim.new(0, 8)
    CloseCorner.Parent = CloseButton
    
    -- Content Frame
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Parent = KeyContainer
    ContentFrame.Position = UDim2.new(0, 0, 0, 110)
    ContentFrame.Size = UDim2.new(1, 0, 1, -110)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.ZIndex = 3
    
    DescriptionLabel.Name = "DescriptionLabel"
    DescriptionLabel.Parent = ContentFrame
    DescriptionLabel.AnchorPoint = Vector2.new(0.5, 0)
    DescriptionLabel.Position = UDim2.new(0.5, 0, 0, 22)
    DescriptionLabel.Size = UDim2.new(0.88, 0, 0, 24)
    DescriptionLabel.BackgroundTransparency = 1
    DescriptionLabel.Text = "กรอกคีย์เพื่อเข้าใช้งาน"
    DescriptionLabel.TextColor3 = Colors.TextSecondary
    DescriptionLabel.TextSize = 14
    DescriptionLabel.Font = Enum.Font.SourceSans
    DescriptionLabel.TextXAlignment = Enum.TextXAlignment.Center
    DescriptionLabel.ZIndex = 4
    
    -- Input Frame with Gradient
    InputFrame.Name = "InputFrame"
    InputFrame.Parent = ContentFrame
    InputFrame.AnchorPoint = Vector2.new(0.5, 0)
    InputFrame.Position = UDim2.new(0.5, 0, 0, 58)
    InputFrame.Size = UDim2.new(0.88, 0, 0, 50)
    InputFrame.BackgroundColor3 = Colors.Surface
    InputFrame.BorderSizePixel = 0
    InputFrame.ZIndex = 4
    
    InputCorner.CornerRadius = UDim.new(0, 12)
    InputCorner.Parent = InputFrame
    
    InputStroke.Color = Colors.Border
    InputStroke.Thickness = 1.5
    InputStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    InputStroke.Transparency = 0.5
    InputStroke.Parent = InputFrame
    
    InputGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 28, 28)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 22, 22))
    }
    InputGradient.Rotation = 90
    InputGradient.Parent = InputFrame
    
    InputIcon.Name = "InputIcon"
    InputIcon.Parent = InputFrame
    InputIcon.Position = UDim2.new(0, 14, 0.5, -10)
    InputIcon.Size = UDim2.new(0, 20, 0, 20)
    InputIcon.BackgroundTransparency = 1
    InputIcon.Text = "🔒"
    InputIcon.TextColor3 = Colors.TextMuted
    InputIcon.TextSize = 16
    InputIcon.ZIndex = 5
    
    KeyInput.Name = "KeyInput"
    KeyInput.Parent = InputFrame
    KeyInput.Position = UDim2.new(0, 42, 0, 0)
    KeyInput.Size = UDim2.new(1, -52, 1, 0)
    KeyInput.BackgroundTransparency = 1
    KeyInput.PlaceholderText = "venuz_xxxxxxxxxxx"
    KeyInput.Text = ""
    KeyInput.TextColor3 = Colors.Text
    KeyInput.PlaceholderColor3 = Colors.TextMuted
    KeyInput.TextSize = 14
    KeyInput.Font = Enum.Font.SourceSans
    KeyInput.TextXAlignment = Enum.TextXAlignment.Left
    KeyInput.ClearTextOnFocus = false
    KeyInput.ZIndex = 5
    
    -- Button Frame
    ButtonFrame.Name = "ButtonFrame"
    ButtonFrame.Parent = ContentFrame
    ButtonFrame.AnchorPoint = Vector2.new(0.5, 0)
    ButtonFrame.Position = UDim2.new(0.5, 0, 0, 128)
    ButtonFrame.Size = UDim2.new(0.88, 0, 0, 120)
    ButtonFrame.BackgroundTransparency = 1
    ButtonFrame.ZIndex = 4
    
    -- Get Key Button with Gradient Border
    GetKeyButton.Name = "GetKeyButton"
    GetKeyButton.Parent = ButtonFrame
    GetKeyButton.Position = UDim2.new(0, 0, 0, 0)
    GetKeyButton.Size = UDim2.new(1, 0, 0, 50)
    GetKeyButton.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    GetKeyButton.BorderSizePixel = 0
    GetKeyButton.Text = "📋 Get Key"
    GetKeyButton.TextColor3 = Colors.Text
    GetKeyButton.TextSize = 15
    GetKeyButton.Font = Enum.Font.SourceSansSemibold
    GetKeyButton.ZIndex = 5
    
    GetKeyCorner.CornerRadius = UDim.new(0, 12)
    GetKeyCorner.Parent = GetKeyButton
    
    GetKeyStroke.Color = Colors.Primary
    GetKeyStroke.Thickness = 1.5
    GetKeyStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    GetKeyStroke.Transparency = 0.3
    GetKeyStroke.Parent = GetKeyButton
    
    SubmitButton.Name = "SubmitButton"
    SubmitButton.Parent = ButtonFrame
    SubmitButton.Position = UDim2.new(0, 0, 0, 62)
    SubmitButton.Size = UDim2.new(1, 0, 0, 50)
    SubmitButton.BackgroundColor3 = Colors.Primary
    SubmitButton.BorderSizePixel = 0
    SubmitButton.Text = "✓ Check Key"
    SubmitButton.TextColor3 = Color3.fromRGB(0,0,0)
    SubmitButton.TextSize = 15
    SubmitButton.Font = Enum.Font.SourceSansSemibold
    SubmitButton.ZIndex = 5
    
    SubmitCorner.CornerRadius = UDim.new(0, 12)
    SubmitCorner.Parent = SubmitButton
    
    SubmitGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Colors.PrimaryLight),
        ColorSequenceKeypoint.new(0.5, Colors.Primary),
        ColorSequenceKeypoint.new(1, Colors.PrimaryDark)
    }
    SubmitGradient.Rotation = 135
    SubmitGradient.Parent = SubmitButton

    -- Hover Effects
    local function createPremiumHover(button, config)
        local originalBg = button.BackgroundColor3
        local stroke = button:FindFirstChildOfClass("UIStroke")
        
        button.MouseEnter:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
                BackgroundColor3 = config.hoverColor or Color3.fromRGB(35, 35, 35),
                Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset, 0, 54)
            }):Play()
            
            if stroke then
                TweenService:Create(stroke, TweenInfo.new(0.3), {
                    Transparency = 0.2,
                    Thickness = 2
                }):Play()
            end
        end)
        
        button.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
                BackgroundColor3 = originalBg,
                Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset, 0, 50)
            }):Play()
            
            if stroke then
                TweenService:Create(stroke, TweenInfo.new(0.3), {
                    Transparency = 0.6,
                    Thickness = 1.5
                }):Play()
            end
        end)
    end
    
    createPremiumHover(GetKeyButton, {hoverColor = Color3.fromRGB(32, 32, 32)})
    createPremiumHover(SubmitButton, {hoverColor = Colors.PrimaryLight})
    
    CloseButton.MouseEnter:Connect(function()
        TweenService:Create(CloseButton, TweenInfo.new(0.2), {
            BackgroundColor3 = Colors.Error,
            BackgroundTransparency = 0,
            Size = UDim2.new(0, 36, 0, 36)
        }):Play()
    end)
    
    CloseButton.MouseLeave:Connect(function()
        TweenService:Create(CloseButton, TweenInfo.new(0.2), {
            BackgroundColor3 = Colors.Surface,
            BackgroundTransparency = 0.2,
            Size = UDim2.new(0, 32, 0, 32)
        }):Play()
    end)

    -- Input Focus Effects
    KeyInput.Focused:Connect(function()
        TweenService:Create(InputStroke, TweenInfo.new(0.3), {
            Color = Colors.Primary,
            Thickness = 2,
            Transparency = 0
        }):Play()
        
        TweenService:Create(InputFrame, TweenInfo.new(0.3), {
            Size = UDim2.new(0.88, 0, 0, 54)
        }):Play()
        
        InputIcon.Text = "🔓"
        TweenService:Create(InputIcon, TweenInfo.new(0.3), {
            TextColor3 = Colors.Primary
        }):Play()
    end)
    
    KeyInput.FocusLost:Connect(function()
        TweenService:Create(InputStroke, TweenInfo.new(0.3), {
            Color = Colors.Border,
            Thickness = 1.5,
            Transparency = 0.5
        }):Play()
        
        TweenService:Create(InputFrame, TweenInfo.new(0.3), {
            Size = UDim2.new(0.88, 0, 0, 50)
        }):Play()
        
        InputIcon.Text = "🔒"
        TweenService:Create(InputIcon, TweenInfo.new(0.3), {
            TextColor3 = Colors.TextMuted
        }):Play()
    end)

    -- Spawn Animations
    KeyContainer.Size = UDim2.new(0, 0, 0, 0)
    GlowFrame.Size = UDim2.new(0, 0, 0, 0)
    MainFrame.BackgroundTransparency = 1
    
    TweenService:Create(MainFrame, TweenInfo.new(0.4), {
        BackgroundTransparency = 1
    }):Play()
    
    TweenService:Create(KeyContainer, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 340, 0, 420)
    }):Play()
    
    TweenService:Create(GlowFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 360, 0, 440)
    }):Play()
    
    -- Gradient Rotation Animations
    spawn(function()
        local rotation = 0
        while KeyContainer.Parent do
            rotation = rotation + 1
            MainGradient.Rotation = 135 + math.sin(rotation / 40) * 20
            HeaderGradient.Rotation = 135 + rotation
            GlowGradient.Rotation = 45 + rotation * 0.5
            LogoGradient.Rotation = 135 + rotation * 2
            SubmitGradient.Rotation = 135 + rotation * 1.5
            wait(0.03)
        end
    end)

    
    -- Glow Pulse
    spawn(function()
        while GlowFrame.Parent do
            TweenService:Create(GlowFrame, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {
                BackgroundTransparency = 0.65,
                Size = UDim2.new(0, 370, 0, 450)
            }):Play()
            wait(1.5)
            TweenService:Create(GlowFrame, TweenInfo.new(1.5, Enum.EasingStyle.Sine), {
                BackgroundTransparency = 0.5,
                Size = UDim2.new(0, 360, 0, 440)
            }):Play()
            wait(1.5)
        end
    end)

    -- Dragging System
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    HeaderFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
            input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = KeyContainer.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
            input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            KeyContainer.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
            GlowFrame.Position = KeyContainer.Position
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
            input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    -- Close Button
    CloseButton.MouseButton1Click:Connect(function()
        TweenService:Create(KeyContainer, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        }):Play()
        
        TweenService:Create(GlowFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        }):Play()
        
        TweenService:Create(MainFrame, TweenInfo.new(0.4), {
            BackgroundTransparency = 1
        }):Play()
        
        wait(0.4)
        KeySystem:Destroy()
    end)
    
    GetKeyButton.MouseButton1Click:Connect(function()
        GetKeyButton.Text = "⏳ กำลังคัดลอก..."
        if getRevenueMode() == "SECUREDLINKVERTISE" then
            local keyLink = "https://pandadevelopment.net/getkey/proceed_hwid?service=" .. tostring(Service) .. "&hwid=" .. tostring(HWID)
            setclipboard(keyLink)
        elseif getRevenueMode() == "SECUREDLOOTLABS" then
            local keyLink = "https://pandadevelopment.net/getkey/proceed_hwid?service=" .. tostring(Service) .. "&hwid=" .. tostring(HWID)
            setclipboard(keyLink)
        elseif getRevenueMode() == "SECUREDLINKVERTISEANDLOOTLABS" then
            local keyLink = "https://pandadevelopment.net/getkey/proceed_hwid?service=" .. tostring(Service) .. "&hwid=" .. tostring(HWID)
            setclipboard(keyLink)
        else
            local keyLink = "https://pandadevelopment.net/getkey?service=" .. tostring(Service) .. "&hwid=" .. tostring(HWID)
            setclipboard(keyLink)
        end
        AlertSystem:CreateAlert({Content = "คัดลอกลิงก์รับคีย์แล้ว!", Type = "success", Duration = 2})
        wait(1.2)
        GetKeyButton.Text = "📋 Get Key"
    end)
    
    SubmitButton.MouseButton1Click:Connect(function()
        local Key = KeyInput.Text
        
        if Key == "" then
            AlertSystem:CreateAlert({Content = "กรุณากรอกคีย์ก่อนยืนยัน!", Type = "warning", Duration = 2})
            
            local originalPos = InputFrame.Position
            for i = 1, 2 do
                TweenService:Create(InputFrame, TweenInfo.new(0.08), {
                    Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset + 6, originalPos.Y.Scale, originalPos.Y.Offset)
                }):Play()
                wait(0.08)
                TweenService:Create(InputFrame, TweenInfo.new(0.08), {
                    Position = UDim2.new(originalPos.X.Scale, originalPos.X.Offset - 6, originalPos.Y.Scale, originalPos.Y.Offset)
                }):Play()
                wait(0.08)
            end
            TweenService:Create(InputFrame, TweenInfo.new(0.08), {
                Position = originalPos
            }):Play()
            
            return
        end
        
        SubmitButton.Text = "⏳ กำลังตรวจสอบ..."
        UserKey = Key
        
        spawn(function()
            local success = ValidateKey()
            wait(1)
            if not success then
                SubmitButton.Text = "✓ Check Key"
            end
        end)
    end)

    KeyInput.FocusLost:Connect(function(enterPressed)
        if enterPressed and KeyInput.Text ~= "" then
            SubmitButton.MouseButton1Click:Fire()
        end
    end)
    
    return KeySystem
end

CreateModernKeyUI()

return AlertSystem