repeat task.wait() until game:IsLoaded()

if not script_key then
    script_key = ""
end

local PlayerService = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local FolderPath = "Venuz Hub/KeySystem"
local KeyFile = FolderPath .. "/VenuzKey.txt"

local function Trim(str)
    return str:match("^%s*(.-)%s*$")
end

local function SaveKey(key)
    if not isfolder(FolderPath) then makefolder(FolderPath) end
    if writefile then writefile(KeyFile, key) end
end

local function LoadKey()
    if not readfile or not writefile or not isfile or not isfolder or not makefolder then
        script_key = ""
        return ""
    end
    
    if not isfolder(FolderPath) then
        pcall(makefolder, FolderPath)
    end

    if not isfile(KeyFile) then
        pcall(writefile, KeyFile, "")
    end

    local success, content = pcall(readfile, KeyFile)
    if success and content then
        script_key = Trim(content)
    else
        script_key = ""
    end

    return script_key
end

local function RemoveKeyUI()
    local keyui = game:GetService("CoreGui"):FindFirstChild("VenuzKey")
    if keyui then keyui:Destroy() end
end

local gameNames = {
    [17357719939] = "Wizard West",
    [126265917374091] = "Wizard West",
    [87039211657390] = "Arise Crossover",
    [116614712661486] = "Arise Crossover",
    [128336380114944] = "Arise Crossover",
    [111989938562194] = "Brainrot Evolution",
    [129827112113663] = "Prospecting",
    [105555311806207] = "Build A Zoo",
    [127742093697776] = "Plants Vs Brainrots",
    [93978595733734] = "Violence District",
    [76558904092080] = "The Forge",
    [129009554587176] = "The Forge",
    [131884594917121] = "The Forge",
    [16997064928] = "Sorcerer Ascent",
    [17255868720] = "Sorcerer Ascent",
    [17796845390] = "Sorcerer Ascent",
    [18594963890] = "Sorcerer Ascent",
    [79469902309075] = "Sorcerer Ascent",
    [92950585659247] = "Sorcerer Ascent",
    [16997056665] = "Sorcerer Ascent",
    [131756752872026] = "Dive Down"
}

local function ValidateAndLoad(key, onError)
    if not key or key == "" then
        if onError then onError("กรุณากรอก Key") end
        return false
    end

    script_key = key

    local success, api = pcall(function()
        return loadstring(game:HttpGet("https://sdkapi-public.luarmor.net/library.lua"))()
    end)

    if not success or not api then
        if onError then onError("ไม่สามารถโหลด API ได้") end
        return false
    end

    api.script_id = "274209c355e95ffe3ba729826b475b88"

    local status = api.check_key(key)

    if status.code == "KEY_VALID" then
        SaveKey(key)
        RemoveKeyUI()

        local PlaceId = game.PlaceId
        local gameName = gameNames[PlaceId]
        
        if gameName then
            pcall(function()
                api.load_script()
            end)
        else
            game.Players.LocalPlayer:Kick("Venuz Hub | Game Not Supported")
        end
        return true
    else
        script_key = ""
        SaveKey("")
        
        local errorMessages = {
            KEY_HWID_LOCKED = "Key ถูกผูกกับ HWID อื่น",
            KEY_INCORRECT = "Key ไม่ถูกต้อง",
            KEY_EXPIRED = "Key หมดอายุแล้ว",
            KEY_BANNED = "Key ถูกแบน",
            KEY_EMPTY = "กรุณากรอก Key",
            KEY_TOO_SHORT = "Key สั้นเกินไป",
            KEY_TOO_LONG = "Key ยาวเกินไป"
        }

        if onError then 
            onError(errorMessages[status.code] or status.message) 
        end
        return false
    end
end

RemoveKeyUI()
script_key = LoadKey()

if script_key ~= "" then
    local success = ValidateAndLoad(script_key, nil)
    if success then
        return
    end
end

local Colors = {
    Background = Color3.fromRGB(15, 15, 15),
    Surface = Color3.fromRGB(25, 25, 25),
    Border = Color3.fromRGB(50, 50, 50),
    Primary = Color3.fromRGB(147, 51, 234),
    PrimaryLight = Color3.fromRGB(180, 100, 255),
    Text = Color3.fromRGB(255, 255, 255),
    TextMuted = Color3.fromRGB(130, 130, 130),
    Error = Color3.fromRGB(239, 68, 68),
    Success = Color3.fromRGB(34, 197, 94)
}

local KeySystem = Instance.new("ScreenGui")
KeySystem.Name = "VenuzKey"
KeySystem.Parent = game:GetService("CoreGui")
KeySystem.ResetOnSpawn = false
KeySystem.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = KeySystem
MainFrame.Size = UDim2.new(1, 0, 1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BackgroundTransparency = 1
MainFrame.BorderSizePixel = 0

local KeyContainer = Instance.new("Frame")
KeyContainer.Name = "KeyContainer"
KeyContainer.Parent = MainFrame
KeyContainer.AnchorPoint = Vector2.new(0.5, 0.5)
KeyContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
KeyContainer.Size = UDim2.new(0, 320, 0, 280)
KeyContainer.BackgroundColor3 = Colors.Background
KeyContainer.BorderSizePixel = 0

local ContainerCorner = Instance.new("UICorner")
ContainerCorner.CornerRadius = UDim.new(0, 16)
ContainerCorner.Parent = KeyContainer

local ContainerStroke = Instance.new("UIStroke")
ContainerStroke.Color = Colors.Border
ContainerStroke.Thickness = 1
ContainerStroke.Parent = KeyContainer

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Parent = KeyContainer
TitleLabel.Position = UDim2.new(0, 0, 0, 20)
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "VENUZ HUB"
TitleLabel.TextColor3 = Colors.Primary
TitleLabel.TextSize = 22
TitleLabel.Font = Enum.Font.SourceSansBold

local SubtitleLabel = Instance.new("TextLabel")
SubtitleLabel.Name = "Subtitle"
SubtitleLabel.Parent = KeyContainer
SubtitleLabel.Position = UDim2.new(0, 0, 0, 50)
SubtitleLabel.Size = UDim2.new(1, 0, 0, 20)
SubtitleLabel.BackgroundTransparency = 1
SubtitleLabel.Text = "กรอกคีย์เพื่อเข้าใช้งาน"
SubtitleLabel.TextColor3 = Colors.TextMuted
SubtitleLabel.TextSize = 14
SubtitleLabel.Font = Enum.Font.SourceSans

local InputFrame = Instance.new("Frame")
InputFrame.Name = "InputFrame"
InputFrame.Parent = KeyContainer
InputFrame.AnchorPoint = Vector2.new(0.5, 0)
InputFrame.Position = UDim2.new(0.5, 0, 0, 85)
InputFrame.Size = UDim2.new(0.88, 0, 0, 45)
InputFrame.BackgroundColor3 = Colors.Surface
InputFrame.BorderSizePixel = 0

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 10)
InputCorner.Parent = InputFrame

local InputStroke = Instance.new("UIStroke")
InputStroke.Color = Colors.Border
InputStroke.Thickness = 1
InputStroke.Parent = InputFrame

local KeyInput = Instance.new("TextBox")
KeyInput.Name = "KeyInput"
KeyInput.Parent = InputFrame
KeyInput.Position = UDim2.new(0, 12, 0, 0)
KeyInput.Size = UDim2.new(1, -24, 1, 0)
KeyInput.BackgroundTransparency = 1
KeyInput.PlaceholderText = "venuz_xxxxxxxxxxx"
KeyInput.Text = ""
KeyInput.TextColor3 = Colors.Text
KeyInput.PlaceholderColor3 = Colors.TextMuted
KeyInput.TextSize = 14
KeyInput.Font = Enum.Font.SourceSans
KeyInput.TextXAlignment = Enum.TextXAlignment.Left
KeyInput.ClearTextOnFocus = false

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "Status"
StatusLabel.Parent = KeyContainer
StatusLabel.Position = UDim2.new(0, 0, 0, 135)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = ""
StatusLabel.TextColor3 = Colors.Error
StatusLabel.TextSize = 13
StatusLabel.Font = Enum.Font.SourceSans

local GetKeyButton = Instance.new("TextButton")
GetKeyButton.Name = "GetKeyButton"
GetKeyButton.Parent = KeyContainer
GetKeyButton.AnchorPoint = Vector2.new(0.5, 0)
GetKeyButton.Position = UDim2.new(0.5, 0, 0, 165)
GetKeyButton.Size = UDim2.new(0.88, 0, 0, 42)
GetKeyButton.BackgroundColor3 = Colors.Surface
GetKeyButton.BorderSizePixel = 0
GetKeyButton.Text = "📋 Get Key"
GetKeyButton.TextColor3 = Colors.Text
GetKeyButton.TextSize = 15
GetKeyButton.Font = Enum.Font.SourceSansSemibold

local GetKeyCorner = Instance.new("UICorner")
GetKeyCorner.CornerRadius = UDim.new(0, 10)
GetKeyCorner.Parent = GetKeyButton

local GetKeyStroke = Instance.new("UIStroke")
GetKeyStroke.Color = Colors.Primary
GetKeyStroke.Thickness = 1
GetKeyStroke.Parent = GetKeyButton

local SubmitButton = Instance.new("TextButton")
SubmitButton.Name = "SubmitButton"
SubmitButton.Parent = KeyContainer
SubmitButton.AnchorPoint = Vector2.new(0.5, 0)
SubmitButton.Position = UDim2.new(0.5, 0, 0, 215)
SubmitButton.Size = UDim2.new(0.88, 0, 0, 42)
SubmitButton.BackgroundColor3 = Colors.Primary
SubmitButton.BorderSizePixel = 0
SubmitButton.Text = "✓ Check Key"
SubmitButton.TextColor3 = Colors.Text
SubmitButton.TextSize = 15
SubmitButton.Font = Enum.Font.SourceSansSemibold

local SubmitCorner = Instance.new("UICorner")
SubmitCorner.CornerRadius = UDim.new(0, 10)
SubmitCorner.Parent = SubmitButton

local isSubmitting = false

GetKeyButton.MouseButton1Click:Connect(function()
    local keyLink = "https://ads.luarmor.net/v/cb/nOrbNeZgYPZx/LozdfkfftTvmURUK"
    if setclipboard then
        setclipboard(keyLink)
        GetKeyButton.Text = "✓ คัดลอกลิงก์แล้ว!"
        task.delay(1.5, function()
            GetKeyButton.Text = "📋 Get Key"
        end)
    end
end)

SubmitButton.MouseButton1Click:Connect(function()
    if isSubmitting then return end
    
    local key = Trim(KeyInput.Text)
    if key == "" then
        StatusLabel.Text = "กรุณากรอกคีย์ก่อนยืนยัน!"
        StatusLabel.TextColor3 = Colors.Error
        return
    end

    isSubmitting = true
    SubmitButton.Text = "⏳ กำลังตรวจสอบ..."
    StatusLabel.Text = ""

    task.spawn(function()
        local success = ValidateAndLoad(key, function(errorMsg)
            StatusLabel.Text = errorMsg
            StatusLabel.TextColor3 = Colors.Error
        end)

        if success then
            StatusLabel.Text = "สำเร็จ!"
            StatusLabel.TextColor3 = Colors.Success
        else
            SubmitButton.Text = "✓ Check Key"
            isSubmitting = false
        end
    end)
end)

KeyInput.FocusLost:Connect(function(enterPressed)
    if enterPressed and KeyInput.Text ~= "" then
        SubmitButton.MouseButton1Click:Fire()
    end
end)

local dragging = false
local dragStart = nil
local startPos = nil

KeyContainer.InputBegan:Connect(function(input)
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
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
        input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)