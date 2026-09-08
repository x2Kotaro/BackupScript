local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local KeySystem = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame") 
local KeyMain = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local HeaderText = Instance.new("TextLabel")
local Description = Instance.new("TextLabel")
local ImageLabel = Instance.new("ImageLabel")
local KeyInput = Instance.new("TextBox")
local UICorner_2 = Instance.new("UICorner")
local UIPadding = Instance.new("UIPadding")
local Submit = Instance.new("TextButton")
local UICorner_3 = Instance.new("UICorner")
local GetKey = Instance.new("TextButton")
local UICorner_4 = Instance.new("UICorner")
local UIStroke1 = Instance.new("UIStroke")
local UIStroke2 = Instance.new("UIStroke")
local DC = Instance.new("ImageButton")
local Close = Instance.new("ImageButton")

--Settings:

KeySystem.Name = "KeySystem"
KeySystem.Parent = game:GetService("CoreGui")
KeySystem.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

MainFrame.Name = "MainFrame"
MainFrame.Parent = KeySystem
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MainFrame.BackgroundTransparency = 1.000
MainFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BorderSizePixel = 0
MainFrame.Size = UDim2.new(1, 0, 1, 0)

KeyMain.Name = "KeyMain"
KeyMain.Parent = MainFrame
KeyMain.AnchorPoint = Vector2.new(0.5, 0.5)
KeyMain.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
KeyMain.BorderColor3 = Color3.fromRGB(0, 0, 0)
KeyMain.BorderSizePixel = 0
KeyMain.Position = UDim2.new(0.5, 0, 0.5, 0)
KeyMain.Size = UDim2.new(0.370000005, 0, 0.522000015, 0)

UICorner.Parent = KeyMain

HeaderText.Name = "HeaderText"
HeaderText.Parent = KeyMain
HeaderText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
HeaderText.BackgroundTransparency = 1.000
HeaderText.BorderColor3 = Color3.fromRGB(0, 0, 0)
HeaderText.BorderSizePixel = 0
HeaderText.Position = UDim2.new(0, 0, 0.183333337, 0)
HeaderText.Size = UDim2.new(1, 0, 0.143333331, 0)
HeaderText.Font = Enum.Font.SourceSansBold
HeaderText.Text = "Venuz Hub - Key System"
HeaderText.TextColor3 = Color3.fromRGB(255, 255, 255)
HeaderText.TextSize = 25.000
HeaderText.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
HeaderText.TextWrapped = true

Description.Name = "Description"
Description.Parent = KeyMain
Description.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Description.BackgroundTransparency = 1.000
Description.BorderColor3 = Color3.fromRGB(0, 0, 0)
Description.BorderSizePixel = 0
Description.Position = UDim2.new(0, 0, 0.303333342, 0)
Description.Size = UDim2.new(1, 0, 0.0633333325, 0)
Description.Font = Enum.Font.SourceSansSemibold
Description.Text = "Please enter Key"
Description.TextColor3 = Color3.fromRGB(80, 80, 80)
Description.TextSize = 17.000
Description.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)

ImageLabel.Parent = KeyMain
ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ImageLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
ImageLabel.BorderSizePixel = 0
ImageLabel.Position = UDim2.new(0.446511626, 0, 0.0333333351, 0)
ImageLabel.Size = UDim2.new(0.104651161, 0, 0.150000006, 0)
ImageLabel.Image = "http://www.roblox.com/asset/?id=72281500336017"

KeyInput.Name = "KeyInput"
KeyInput.Parent = KeyMain
KeyInput.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
KeyInput.BorderColor3 = Color3.fromRGB(26, 26, 26)
KeyInput.Position = UDim2.new(0.143999994, 0, 0.442999989, 0)
KeyInput.Size = UDim2.new(0.709302306, 0, 0.113333337, 0)
KeyInput.Font = Enum.Font.GothamBold
KeyInput.PlaceholderText = "Enter your key"
KeyInput.Text = ""
KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyInput.TextSize = 14.000
KeyInput.TextXAlignment = Enum.TextXAlignment.Left
KeyInput.TextTruncate = Enum.TextTruncate.AtEnd

UICorner_2.CornerRadius = UDim.new(0, 4)
UICorner_2.Parent = KeyInput

UIPadding.Parent = KeyInput
UIPadding.PaddingLeft = UDim.new(0.0500000007, 0)

UIStroke1.Parent = KeyInput
UIStroke1.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke1.Color = Color3.fromRGB(65, 65, 65)
UIStroke1.Thickness = 0.5

Submit.Name = "Submit"
Submit.Parent = KeyMain
Submit.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Submit.BorderColor3 = Color3.fromRGB(0, 0, 0)
Submit.BorderSizePixel = 0
Submit.Position = UDim2.new(0.517455995, 0, 0.656695008, 0)
Submit.Size = UDim2.new(0.269767463, 0, 0.116686381, 0)
Submit.Font = Enum.Font.GothamMedium
Submit.Text = "Submit"
Submit.TextColor3 = Color3.fromRGB(0, 0, 0)
Submit.TextSize = 14.000

UICorner_3.CornerRadius = UDim.new(0, 6)
UICorner_3.Parent = Submit

GetKey.Name = "GetKey"
GetKey.Parent = KeyMain
GetKey.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
GetKey.BackgroundTransparency = 1.000
GetKey.BorderColor3 = Color3.fromRGB(0, 0, 0)
GetKey.BorderSizePixel = 0
GetKey.Position = UDim2.new(0.20815371, 0, 0.656695127, 0)
GetKey.Size = UDim2.new(0.269767463, 0, 0.116686493, 0)
GetKey.Font = Enum.Font.GothamMedium
GetKey.Text = "Get Key"
GetKey.TextColor3 = Color3.fromRGB(255, 255, 255)
GetKey.TextSize = 14.000

UIStroke2.Parent = GetKey
UIStroke2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke2.Color = Color3.fromRGB(255, 255, 255)
UIStroke2.Thickness = 0.7

UICorner_4.CornerRadius = UDim.new(0, 6)
UICorner_4.Parent = GetKey

DC.Name = "DC"
DC.Parent = KeyMain
DC.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
DC.BackgroundTransparency = 1.000
DC.BorderColor3 = Color3.fromRGB(0, 0, 0)
DC.BorderSizePixel = 0
DC.Position = UDim2.new(0.023, 0, 0.0299999993, 0)
DC.Size = UDim2.new(0.0579979122, 0, 0.0666101724, 0)
DC.Image = "http://www.roblox.com/asset/?id=76181608348088"

Close.Name = "Close"
Close.Parent = KeyMain
Close.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Close.BackgroundTransparency = 1.000
Close.BorderColor3 = Color3.fromRGB(0, 0, 0)
Close.BorderSizePixel = 0
Close.Position = UDim2.new(0.916167915, 0, 0.0266695302, 0)
Close.Size = UDim2.new(0.0549999997, 0, 0.0700000003, 0)
Close.Image = "http://www.roblox.com/asset/?id=9545003266"

Close.MouseButton1Click:Connect(function()
	KeySystem:Destroy()
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
	KeyMain.InputBegan:Connect(
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
	KeyMain.InputChanged:Connect(
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

dragify(KeyMain, KeyMain)