local NotificationLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/IceMinisterq/Notification-Library/Main/Library.lua"))()

if game:GetService("CoreGui"):FindFirstChild("WindUI") then
    return
    NotificationLibrary:SendNotification("Infomation", "You already have a script.", 3)
end

getgenv().ConfigurationTable = {}
getgenv().Settings = {}

local FolderConfiguration = "Venuz Hub"
local FolderSettings = "Venuz Hub/Build_A_Zoo"
local FolderSlots = "Venuz Hub/Slots"
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local chr = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local hrp = chr:WaitForChild("HumanoidRootPart")
local humanoid = chr:WaitForChild("Humanoid")
local HttpService = game:GetService("HttpService")
local VenuzIcon = "rbxassetid://92691624917972"
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local UserId = LocalPlayer.UserId
local currentTime = os.date("%H:%M:%S")

local filenameConfiguration = FolderConfiguration .. "/" .. "Setting" .. ".json"
local filenameSetting = FolderSettings .. "/" .. "Build_A_Zoo".. LocalPlayer.Name .. ".json"

--------------------------- Configuration ---------------------------

local DefaultConfiguration = {
    Themes = "Dark",
    Transparent = true,
    AntiAFK = true,
    AutoExecutor = true,
    MinimizeBind = "End",
    Language = "English",
}

local function MergeConfiguration(loaded, defaults)
    for key, defaultValue in pairs(defaults) do
        if type(defaultValue) == "table" then
            loaded[key] = MergeConfiguration(loaded[key] or {}, defaultValue)
        else
            if loaded[key] == nil then
                loaded[key] = defaultValue
            end
        end
    end
    return loaded
end

function LoadConfiguration()
    if readfile and isfile and isfile(filenameConfiguration) then
        local data = readfile(filenameConfiguration)
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(data)
        end)

        if success and type(decoded) == "table" then
            getgenv().ConfigurationTable = MergeConfiguration(decoded, DefaultConfiguration)
        else
            warn("[Configuration] Failed to decode, using default.")
            getgenv().ConfigurationTable = DefaultConfiguration
        end
    else
        getgenv().ConfigurationTable = DefaultConfiguration
    end
end

function SaveConfiguration()
    if writefile and makefolder then
        if not isfolder("Venuz Hub") then makefolder("Venuz Hub") end
        if not isfolder(FolderConfiguration) then makefolder(FolderConfiguration) end

        local json = HttpService:JSONEncode(getgenv().ConfigurationTable)
        writefile(filenameConfiguration, json)
    end
end

LoadConfiguration()

--------------------------- SaveSettings ---------------------------

local DefaultSettings = {
    ["AutoCollect"] = {
        ["AutoCollect"] = false,
        ["Delay"] = 20,
        ["Value"] = 0
    },

    ["AutoBuyEgg"] = {
        ["AutoBuyEgg"] = false,
        ["SelectEgg"] = {},
        ["SelectMutation"] = {},
        ["AutoBuyEggwithmutation"] = false,
        ["SelectEventSnow"] = {},
        ["SelectEggsWithMutation"] = {},
        ["AutoBuyEggwithEventSnow"] = false,
        ["infactionSnow"] = false,
    },

    ["AutoPlace"] = {
        ["SelectEgg"] = nil,
        ["AutoEquipEgg"] = false,
        ["AutoPlacePet"] = false,
        ["AutoPlaceOcean"] = false,
        ["AutoHatch"] = false,
    },

    ["Shop"] = {
        ["Fruits"] = {},
        ["AutoBuyFruits"] = false,
    },
    
    ["Feed"] = {
        ["SelectFruit"] = nil,
        ["AutoEquip"] = false,
        ["AutoFeed"] = false,
        ["SelectPet"] = nil,
    },

    ["Quest"] = {
        ["AutoSnowQuest"] = false,
    },

    ["Webhook"] = {
        ["WebhookUrl"] = "",
        ["CheckAllEgg"] = false,
    },

    ["Fish"] = {
        ["SelectBait"] = nil,
        ["AutoFish"] = false,
    },

    ["Premium"] = {
        ["PositionFish"] = nil,
        ["SelectBait"] = nil,
        ["AutoFish"] = false,
        ["HopServer"] = false,
    }
}

local function MergeSettings(defaults, loaded)
    for k,v in pairs(defaults) do
        if type(v) == "table" then
            if type(loaded[k]) ~= "table" then
                loaded[k] = v
            else
                MergeSettings(v, loaded[k])
            end
        else
            if loaded[k] == nil then
                loaded[k] = v
            end
        end
    end
end

function LoadSettings()
    if readfile and isfile and isfile(filenameSetting) then
        local loaded = HttpService:JSONDecode(readfile(filenameSetting))
        MergeSettings(DefaultSettings, loaded)
        getgenv().Settings = loaded
    else
        getgenv().Settings = DefaultSettings
    end
end

function SaveSetting()
    if writefile and makefolder then
        if not isfolder("Venuz Hub") then makefolder("Venuz Hub") end
        if not isfolder(FolderSettings) then makefolder(FolderSettings) end
        local json = HttpService:JSONEncode(getgenv().Settings)
        writefile(filenameSetting, json)
    end
end

LoadSettings()

if getgenv().Configuration and next(getgenv().Configuration) then
    for key, value in pairs(getgenv().Configuration) do
        if getgenv().Settings[key] ~= nil then
            getgenv().Settings[key] = value
        end
    end
    SaveSetting()
end

--------------------------- CheckingRole ---------------------------

local KeyFile = "Venuz Hub/KeySystem".."/".."VenuzKey"..".txt"

local res = http.request({
    Url = "https://pandadevelopment.net/v2_validation?key=".. readfile(KeyFile).."&service=venuzhub&hwid=venuzontop",
    Method = "GET",
    Headers = {
        ["Content-Type"] = "application/json"
    },
}).Body

local sucess, data = pcall(function()
    return HttpService:JSONDecode(res)
end)

if sucess then
    if data["Key_Information"].Premium_Mode == true then
        getgenv().Premium = false
        getgenv().IsPremium = "Premium Access"
    else
        getgenv().Premium = true
        getgenv().IsPremium = "Standard"
    end
end

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/x2Kotaro/API/refs/heads/main/WindUIVenuz.lua"))()

local Device
if UserInputService.TouchEnabled then
    Device = UDim2.fromOffset(450, 300)
else
    Device = UDim2.fromOffset(580, 460)
end

local Window = WindUI:CreateWindow({
    Title = "Venuz Hub by Phoenix",
    Icon = VenuzIcon,
    Author = getgenv().IsPremium,
    Size = Device,
    Transparent = getgenv().ConfigurationTable.Transparent,
    Theme = getgenv().ConfigurationTable.Themes,
    SideBarWidth = 200,
    HasOutline = true,
})

local Tabs = {
    Automatic = Window:Tab({ Title = "Auto Collect", Icon = "code-xml", ShowTabTitle = true }),
    Eggs = Window:Tab({ Title = "Auto BuyEggs", Icon = "egg", ShowTabTitle = true }),
    Place = Window:Tab({ Title = "Auto Place & Hatch", Icon = "hammer", ShowTabTitle = true }),
    Shop = Window:Tab({ Title = "Shop", Icon = "shopping-basket", ShowTabTitle = true }),
    Feed = Window:Tab({ Title = "Auto Feed", Icon = "signpost-big", ShowTabTitle = true }),
    Quest = Window:Tab({ Title = "Quest", Icon = "newspaper", ShowTabTitle = true }),
    Fish = Window:Tab({ Title = "Fish", Icon = "fish", ShowTabTitle = true }),
    Gift = Window:Tab({ Title = "Gift", Icon = "gift", ShowTabTitle = true}),
    Webhook = Window:Tab({ Title = "Webhook", Icon = "send", ShowTabTitle = true}),
    Premium = Window:Tab({ Title = "Premium", Icon = "diamond-plus", ShowTabTitle = true, Locked = getgenv().Premium}),
    divider1 = Window:Divider(),
    Configuration = Window:Tab({ Title = "Configuration", Icon = "settings", Desc = "Manage window settings and themes.", ShowTabTitle = true}),
}

------------------------Translations---------------------------

local Translations = {
    ["English (US)"] = {
        -- Tabs --
        Automatic = "Auto Collect",
        Eggs = "Auto BuyEgg",
        Place = "Auto Place & Hatch",
        Shop = "Shop",
        Feed = "Auto Feed",
        Quest = "Quest",
        Fish = "Fish",
        Gift = "Gift",
        Webhook = "Webhook",
        Premium = "Premium",
        Configuration = "Configuration",
        -- Section Auto Collect --
        AutoCollectTab = "↪ Auto Collect",
        AutoCollect_Title = "Auto Collect",
        AutoCollect_Desc = "Automatically collect your pets.",
        DelayCollect = "Delay",
        QuickTab = "↪ Quick",
        QuickCollect_Title = "Quick Collect",
        QuickCollect_Desc = "Collect all at once.",
        CollectPet = "↪ Auto Collect Pet",
        Eard = "Earn/s",
        CollectAllPetEarn = "Collect Pet Earn/s",
        CollectAllPet = "Collect All Pet",
        -- Section Auto BuyEgg --
        AutoBuyEggTab = "↪ Auto Buy Eggs",
        SelectEggs = "Select Eggs",
        AutoBuyEgg_Title = "Auto Buy Eggs",
        AutoBuyEgg_Desc = "Automatically buy eggs for your pets.",
        AutoBuyEggwithmutationTab = "↪ Auto Buy Eggs With Mutation",
        SelectEggsWith = "Select Eggs",
        SelectMutation = "Mutations",
        AutoBuyEggwithmutation_Title = "Auto BuyEgg with Mutation",
        AutoBuyEggwithmutation_Desc = "Automatically buy eggs with mutation.",
        AutoBuyEggwithEventSnowTab = "↪ Auto Buy Eggs Event",
        SelectEggevent = "Select Egg",
        SnowMutatuion = "Mutation Snow",
        AutoBuyEggwithEventSnow_Title = "Auto Buy Eggs with Event Snow",
        AutoBuyEggwithEventSnow_Desc = "Automatically buy eggs during the snow event.",
        -- Auto Place & Hatch --
        AutoEquipEgg = "↪ Auto Equip Egg",
        SelectEggPlace = "Select Egg",
        Refresh = "Refresh",
        AutoEquipEgg_Title = "Auto Equip",
        AutoEquipEgg_Desc = "Automatically equip your egg.",
        AutoPlaceTab = "↪ Auto Place",
        AutoPlacePet = "Auto Place Pet",
        AutoPlaceOcean = "Auto Place Ocean",
        AutoHatchTab = "Auto Hatch",
        AutoHatch = "Auto Hatch",
        -- Section Shop --
        FruitTab = "↪ Fruits Stock",
        SelectFruitShop = "Select Fruit",
        AutoBuyFruits_Title = "Auto Buy Fruits",
        AutoBuyFruits_Desc = "Automatically buy fruits.",
        -- Section Auto Feed --
        AutoEquipFruit = "↪ Auto Equip Fruit",
        SelectFruit = "Select Fruit",
        AutoEquip = "Auto Equip",
        AutoFeedTab = "↪ Auto Feed",
        SelectPet = "Select Pet",
        AutoFeed_Title = "Auto Feed",
        AutoFeed_Desc = "Automatically feed your pets.",
        -- Section Event --
        QuestTab = "↪ Snow Tasks",
        AutoSnowTask = "Auto Claim Reward",
        -- Section Fish --
        FishTab = "↪ Auto Fish",
        SelectBaitNormal = "Select Bait",
        AutoFish = "Auto Fish",
        -- Section Gift --
        PetName = "Pet Name",
        Mutation = "Mutation",
        PetHave = "Pet Owned",
        EggName = "Egg Name",
        EggHave = "Egg Owned",
        NotFoundItem = "Item not found.",
        SelectItem = "Select item...",
        Infomation = "Information",
        SelectedPlayer = "Selected Player",
        Amout = "Amount",
        SendGift = "Send Gift",
        TabsGift = "↪ Gift",
        -- Section Webhook --
        TabsWebhook = "↪ Setup Webhook",
        WebhookUrl = "URL",
        TestWebhook = "Test Webhook",
        EggTabsWebhook = "Eggs",
        CheckAllEgg = "Check All Egg",
        -- Section Premium --
        FishPosition = "↪ Fish Position",
        PositionFish = "Position",
        SavePosition = "Save Position",
        AutoFishPremiumTabs = "↪ Auto Fish",
        SelectBait = "Select Bait",
        AutoFishPremium = "Auto Fish (Event Only)",
        ServerHopFindSnow = "Server Hop Find Snow",
        -- Section Configuration --
        themeDropdown = "Select Theme",
        ToggleTransparency = "Toggle Window Transparency",
        AntiAFK = "Anti-AFK",
        AutoExecutor = "Auto Executor",
        MinimizeBind = "Minimize Bind",
        LanguageTab = "↪ Language",
        Interface = "↪ Interface Settings",
        Language = "Language",
        ChangedLanguage = "Change Language",
        Interface = "↪ Interface Settings",
    },
    ["Thai"] = {
        -- Tabs --
        Automatic = "เก็บอัตโนมัติ",
        Eggs = "ซื้อไข่อัตโนมัติ",
        Place = "วางและฟักไข่อัตโนมัติ",
        Shop = "ร้านค้า",
        Feed = "ให้อาหารอัตโนมัติ",
        Quest = "ภารกิจ",
        Fish = "ตกปลา",
        Gift = "ของขวัญ",
        Webhook = "เว็บฮุก",
        Premium = "พรีเมียม",
        Configuration = "ตั้งค่า",
        -- Section Auto Collect --
        AutoCollectTab = "↪ เก็บอัตโนมัติ",
        AutoCollect_Title = "เก็บอัตโนมัติ",
        AutoCollect_Desc = "เก็บสัตว์เลี้ยงของคุณโดยอัตโนมัติ",
        DelayCollect = "ล่าช้า",
        QuickTab = "↪ ทันที",
        QuickCollect_Title = "เก็บแบบเร็ว",
        QuickCollect_Desc = "เก็บทั้งหมดในครั้งเดียว",
        CollectPet = "↪ เก็บสัตว์อัตโนมัติ",
        Eard = "ได้รับ/วินาที",
        CollectAllPetEarn = "ได้รับจากสัตว์จากการเก็บ/วินาที",
        CollectAllPet = "เก็บสัตว์ทั้งหมด",
        -- Section Auto BuyEgg --
        AutoBuyEggTab = "↪ ซื้อไข่อัตโนมัติ",
        SelectEggs = "เลือกไข่",
        AutoBuyEgg_Title = "ซื้อไข่อัตโนมัติ",
        AutoBuyEgg_Desc = "ซื้อไข่ให้สัตว์เลี้ยงสำหรับโดยอัตโนมัติ",
        AutoBuyEggwithmutationTab = "↪ ซื้อไข่พร้อมกลายพันธุ์อัตโนมัติ",
        SelectEggsWith = "เลือกไข่",
        SelectMutation = "เลือกลักษณะกลายพันธุ์",
        AutoBuyEggwithmutation_Title = "ซื้อไข่พร้อมกลายพันธุ์",
        AutoBuyEggwithmutation_Desc = "ซื้อไข่พร้อมลักษณะกลายพันธุ์โดยอัตโนมัติ",
        AutoBuyEggwithEventSnowTab = "↪ ซื้อไข่กิจกรรมหิมะ",
        SelectEggevent = "เลือกไข่อีเว้นต์",
        SnowMutatuion = "กลายพันธุ์หิมะ",
        AutoBuyEggwithEventSnow_Title = "ซื้อไข่อัตโนมัติพร้อมกิจกรรมหิมะ",
        AutoBuyEggwithEventSnow_Desc = "ซื้อไข่อัตโนมัติในช่วงกิจกรรมหิมะ",
        -- Auto Place & Hatch --
        AutoEquipEgg = "↪ สวมใส่ไข่อัตโนมัติ",
        SelectEggPlace = "เลือกไข่",
        Refresh = "รีเฟรช",
        AutoEquipEgg_Title = "สวมใส่อัตโนมัติ",
        AutoEquipEgg_Desc = "สวมใส่ไข่ของคุณโดยอัตโนมัติ",
        AutoPlaceTab = "↪ วางอัตโนมัติ",
        AutoPlacePet = "วางสัตว์อัตโนมัติ",
        AutoPlaceOcean = "วางในทะเลอัตโนมัติ",
        AutoHatchTab = "ฟักไข่อัตโนมัติ",
        AutoHatch = "ฟักอัตโนมัติ",
        -- Section Shop --
        FruitTab = "↪ คลังผลไม้",
        SelectFruit = "เลือกผลไม้",
        AutoBuyFruits_Title = "ซื้อผลไม้อัตโนมัติ",
        AutoBuyFruits_Desc = "ซื้อผลไม้โดยอัตโนมัติ",
        -- Section Auto Feed --
        AutoEquipFruit = "↪ สวมผลไม้อัตโนมัติ",
        SelectFruit = "เลือกผลไม้",
        AutoEquip = "สวมใส่อัตโนมัติ",
        AutoFeedTab = "↪ ให้อาหารอัตโนมัติ",
        SelectPet = "เลือกสัตว์เลี้ยง",
        AutoFeed_Title = "ให้อาหารอัตโนมัติ",
        AutoFeed_Desc = "ให้อาหารสัตว์ของคุณโดยอัตโนมัติ",
        -- Section Event --
        QuestTab = "↪ ภารกิจหิมะ",
        AutoSnowTask = "รับรางวัลอัตโนมัติ",
        -- Section Fish --
        FishTab = "↪ ตกปลาอัตโนมัติ",
        SelectBaitNormal = "เลือกเหยื่อ",
        AutoFish = "ตกปลาอัตโนมัติ",
        -- Section Gift --
        PetName = "ชื่อสัตว์",
        Mutation = "กลายพันธุ์",
        PetHave = "จำนวนสัตว์ที่มี",
        EggName = "ชื่อไข่",
        EggHave = "จำนวนไข่ที่มี",
        NotFoundItem = "ไม่พบรายการ",
        SelectItem = "เลือกรายการ...",
        Infomation = "สารสนเทศ",
        SelectedPlayer = "ผู้เล่นที่เลือก",
        Amout = "จำนวน",
        SendGift = "ส่งของขวัญ",
        TabsGift = "↪ ของขวัญ",
        -- Section Webhook --
        TabsWebhook = "↪ ตั้งค่าเว็บฮุก",
        WebhookUrl = "URL",
        TestWebhook = "ทดสอบเว็บฮุก",
        EggTabsWebhook = "ไข่",
        CheckAllEgg = "ตรวจสอบไข่ทั้งหมด",
        -- Section Premium --
        FishPosition = "↪ ตำแหน่งตกปลา",
        PositionFish = "ตำแหน่ง",
        SavePosition = "บันทึกตำแหน่ง",
        AutoFishPremiumTabs = "↪ ตกปลาอัตโนมัติ (พรีเมียม)",
        SelectBait = "เลือกเหยื่อ",
        AutoFishPremium = "ตกปลาอัตโนมัติ (เฉพาะกิจกรรม)",
        ServerHopFindSnow = "เปลี่ยนเซิร์ฟเวอร์หาหิมะ",
        -- Section Configuration --
        themeDropdown = "เลือกธีม",
        ToggleTransparency = "เปิด/ปิดความโปร่งใสหน้าต่าง",
        AntiAFK = "ป้องกันการหลุดออกจากประสบการณ์ (Anti-AFK)",
        AutoExecutor = "รันอัตโนมัติ (Auto Executor)",
        MinimizeBind = "ปุ่มย่อหน้าต่าง",
        LanguageTab = "↪ ภาษา",
        Interface = "↪ ตั้งค่าอินเทอร์เฟส",
        Language = "ภาษา",
        ChangedLanguage = "เปลี่ยนภาษา",
        Interface = "↪ การตั้งค่าอินเทอร์เฟซ",
    }
}

local function L(key)
    local lang = getgenv().ConfigurationTable.Language or "English"
    return Translations[lang][key] or Translations["English"][key] or key
end

-------------------------------- Function --------------------------------
local myIsland

function TeleportToWaypoint(Position)
    hrp.CFrame = Position
end

repeat task.wait(.1) for i,v in pairs(workspace.Art:GetChildren()) do
    if v:GetAttribute("OccupyingPlayerId") == UserId then
        myIsland = v
        getgenv().MyIsland = v.Name
        break
    end
end
until myIsland

local conveyorFolder
repeat
    task.wait(0.1)
    if myIsland:FindFirstChild("ENV") and myIsland.ENV:FindFirstChild("Conveyor") then
        conveyorFolder = myIsland.ENV.Conveyor
    end
until conveyorFolder

RunService.RenderStepped:Connect(function()
    for i,v in pairs(workspace.Art[getgenv().MyIsland].ENV.Conveyor:GetChildren()) do
        if v:IsA("Model") then
            getgenv().Conveyor = v.Name
        end
    end
end)

-------------------------------- Auto Collect --------------------------------

local AutoCollectTab = Tabs.Automatic:Section({ Title = "Auto Collect" })

local AutoCollectThread

local AutoCollect = Tabs.Automatic:Toggle({
    Title = "Auto Collect",
    Desc = "Automatic Collect your pets.",
    Value = getgenv().Settings.AutoCollect.AutoCollect,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.AutoCollect.AutoCollect = Value
        SaveSetting()

        if Value then
            AutoCollectThread = task.spawn(function()

                for _, v in pairs(workspace.Pets:GetChildren()) do
                    if v:GetAttribute("UserId") == UserId then
                        local root = v:FindFirstChild("RootPart")
                        if root and root:FindFirstChild("RE") then
                            root.RE:FireServer("Claim")
                        end
                    end
                end

                while getgenv().Settings.AutoCollect.AutoCollect do task.wait(getgenv().Settings.AutoCollect.Delay)
                    for _, v in pairs(workspace.Pets:GetChildren()) do
                        if v:GetAttribute("UserId") == UserId then
                            local root = v:FindFirstChild("RootPart")
                            if root and root:FindFirstChild("RE") then
                                root.RE:FireServer("Claim")
                            end
                        end
                    end
                end
            end)
        else
            if AutoCollectThread then
                task.cancel(AutoCollectThread)
                AutoCollectThread = nil
            end
        end
    end
})

local DelayCollect = Tabs.Automatic:Slider({
    Title = "Delay",
    Value = {
        Min = 20,
        Max = 120,
        Default = getgenv().Settings.AutoCollect.Delay,
    },
    Callback = function(Value)
        getgenv().Settings.AutoCollect.Delay = Value
        SaveSetting()
    end
})

local QuickTab = Tabs.Automatic:Section({ Title = "Quick" })

local QuickCollect = Tabs.Automatic:Button({
    Title = "Quick Collect",
    Desc = "Collect all at once.",
    Callback = function()
        for i,v in pairs(workspace.Pets:GetChildren()) do
            if v:GetAttribute("UserId") == UserId then
                v.RootPart.RE:FireServer("Claim")
            end
        end
    end
})

local CollectPet = Tabs.Automatic:Section({ Title = "Auto Collect Pet" })

local Eard = Tabs.Automatic:Input({
    Title = "Earn/s",
    Value = getgenv().Settings.AutoCollect.Value,
    Callback = function(Value)
        getgenv().Settings.AutoCollect.Value = tonumber(Value)
        SaveSetting()
    end
})

local CollectAllPetEarn = Tabs.Automatic:Button({
    Title = "Collect Pet Earn/s",
    Callback = function()
        for i,v in pairs(workspace.Pets:getDescendants()) do
            if v:GetAttribute("UserId") == UserId then
                if v.Name == "RootPart" then
                    if v:GetAttribute("ProduceSpeed") < getgenv().Settings.AutoCollect.Value then
                        game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("CharacterRE"):FireServer(unpack({"Del",v.Parent.Name}))
                    end
                end
            end
        end
    end
})

local CollectAllPet = Tabs.Automatic:Button({
    Title = "Collect All Pet",
    Callback = function()
        for i,v in pairs(game:GetService("Players").LocalPlayer.PlayerGui.Data.Pets:GetChildren()) do
            game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("CharacterRE"):FireServer(unpack({"Del",v.Name}))
         end
    end
})

-------------------------------- Auto BuyEgg --------------------------------

local EggsTable = {}

local ConveyorPool = game:GetService("ReplicatedStorage").ConveyorPool
local ConveyorFolder = workspace.Art[getgenv().MyIsland].ENV.Conveyor

function Updated()
    for i,v in pairs(game:GetService("ReplicatedStorage").ConveyorPool:GetChildren()) do
        if v.Name == getgenv().Conveyor then
            for i2 ,v2 in pairs(v:GetAttributes()) do
                if not table.find(EggsTable, i2) then
                    table.insert(EggsTable, i2)
                end
            end

            for i2 = #EggsTable, 1, -1 do
                if v:GetAttributes()[EggsTable[i2]] == nil then
                    table.remove(EggsTable, i2)
                end
            end
        end
    end
end

Updated()
local AutoBuyEggTab = Tabs.Eggs:Section({ Title = "Auto Buy Eggs" })

local SelectEggs = Tabs.Eggs:Dropdown({
    Title = "Select Eggs",
    Multi = true,
    AllowNone = false,
    Value = getgenv().Settings.AutoBuyEgg.SelectEgg,
    Values = EggsTable,
    Callback = function(Value)
        getgenv().Settings.AutoBuyEgg.SelectEgg = Value
        SaveSetting()
    end
})

local AutoBuyEgg = Tabs.Eggs:Toggle({
    Title = "Auto BuyEggs",
    Desc = "Automatic BuyEggs your pets.",
    Value = getgenv().Settings.AutoBuyEgg.AutoBuyEgg,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.AutoBuyEgg.AutoBuyEgg = Value
        SaveSetting()
        task.spawn(function()
            pcall(function()
                while getgenv().Settings.AutoBuyEgg.AutoBuyEgg do task.wait(1)
                    for i,v in pairs(game:GetService("ReplicatedStorage").Eggs[getgenv().MyIsland]:GetChildren()) do
                        if table.find(getgenv().Settings.AutoBuyEgg.SelectEgg, v:GetAttribute("T")) then
                            game:GetService("ReplicatedStorage").Remote.CharacterRE:FireServer("BuyEgg", v.Name)
                        end
                    end
                end
            end)
        end)
    end
})

local AutoBuyEggwithmutationTab = Tabs.Eggs:Section({ Title = "Auto Buy Eggs With Mutation" })

local SelectEggsWith = Tabs.Eggs:Dropdown({
    Title = "Select Eggs",
    Values = EggsTable,
    Value = getgenv().Settings.AutoBuyEgg.SelectEggsWithMutation,
    Multi = true,
    AllowNone = false,
    Callback = function(Value)
        getgenv().Settings.AutoBuyEgg.SelectEggsWithMutation = Value
        SaveSetting()
    end
})

local SelectMutation = Tabs.Eggs:Dropdown({
    Title = "Mutations",
    Values = {"Golden", "Diamond", "Electirc", "Fire", "Dino", "Snow"},
    Value = getgenv().Settings.AutoBuyEgg.SelectMutation,
    Multi = true,
    AllowNone = false,
    Callback = function(Value)
        getgenv().Settings.AutoBuyEgg.SelectMutation = Value
        SaveSetting()
    end
})

local AutoBuyEggwithmutation = Tabs.Eggs:Toggle({
    Title = "Auto BuyEgg with Mutation",
    Desc = "Automatic BuyEgg with Mutation your pets.",
    Value = getgenv().Settings.AutoBuyEgg.AutoBuyEggwithmutation,
    Icon = "check",
    Callback = function(Callback)
        getgenv().Settings.AutoBuyEgg.AutoBuyEggwithmutation = Callback
        SaveSetting()

        if Callback then
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.AutoBuyEgg.AutoBuyEggwithmutation do task.wait(1)
                        for i,v in pairs(game:GetService("ReplicatedStorage").Eggs[getgenv().MyIsland]:GetChildren()) do
                            if table.find(getgenv().Settings.AutoBuyEgg.SelectEggsWithMutation, v:GetAttribute("T")) then
                                if table.find(getgenv().Settings.AutoBuyEgg.SelectMutation, v:GetAttribute("M")) then
                                    game:GetService("ReplicatedStorage").Remote.CharacterRE:FireServer("BuyEgg", v.Name)
                                end
                            end
                        end
                    end
                end)
            end)
        end
    end
})

local AutoBuyEggwithEventSnowTab = Tabs.Eggs:Section({ Title = "Auto Buy Eggs Event" })

local SelectEggevent = Tabs.Eggs:Dropdown({
    Title = "Select Eggs",
    Values = {"RhinoRockEgg", "DarkGoatyEgg", "SaberCubEgg", "GeneralKongEgg"},
    Value = getgenv().Settings.AutoBuyEgg.SelectEventSnow,
    Multi = true,
    AllowNone = false,
    Callback = function(Value)
        getgenv().Settings.AutoBuyEgg.SelectEventSnow = Value
        SaveSetting()
    end
})

local SnowMutatuion = Tabs.Eggs:Toggle({
    Title = "Mutation Snow",
    Value = getgenv().Settings.AutoBuyEgg.infactionSnow,
    Icon = "check",
    Callback = function(Snow)
        getgenv().Settings.AutoBuyEgg.infactionSnow = Snow
        SaveSetting()
    end
})

local AutoBuyEggwithEventSnow = Tabs.Eggs:Toggle({
    Title = "Auto Buy Eggs with Event Snow",
    Desc = "Automatic BuyEgg with Event Snow your pets.",
    Value = getgenv().Settings.AutoBuyEgg.AutoBuyEggwithEventSnow,
    Icon = "check",
    Callback = function(Snow)
        getgenv().Settings.AutoBuyEgg.AutoBuyEggwithEventSnow = Snow
        SaveSetting()

        if Snow then
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.AutoBuyEgg.AutoBuyEggwithEventSnow do task.wait(1)
                        for i,v in pairs(game:GetService("ReplicatedStorage").Eggs[getgenv().MyIsland]:GetChildren()) do
                            if table.find(getgenv().Settings.AutoBuyEgg.SelectEventSnow, v:GetAttribute("T")) then
                                if getgenv().Settings.AutoBuyEgg.infactionSnow then
                                    if v:GetAttribute("M") == "Snow" then
                                        game:GetService("ReplicatedStorage").Remote.CharacterRE:FireServer("BuyEgg", v.Name)
                                    end
                                else
                                    game:GetService("ReplicatedStorage").Remote.CharacterRE:FireServer("BuyEgg", v.Name)
                                end
                            end
                        end
                    end
                end)
            end)
        end
    end
})

ConveyorFolder.ChildRemoved:Connect(function(child)
    if child.Name == getgenv().Conveyor then
        getgenv().Conveyor = nil
    end
    Updated(child)
    SelectEggs:Refresh(EggsTable)
    SelectEggsWith:Refresh(EggsTable)
end)

ConveyorFolder.ChildAdded:Connect(function(child)
    if child:IsA("Model") then
        getgenv().Conveyor = child.Name
    end
    Updated(child)
    SelectEggs:Refresh(EggsTable)
    SelectEggsWith:Refresh(EggsTable)
end)

-------------------------------- Auto Place & Hatch --------------------------------

local AutoEquipEgg = Tabs.Place:Section({ Title = "Auto Equip Egg" })

local Items = {}
local SelectEggPlace

function UpdateEgg()
    local EggFolder = game.Players.LocalPlayer.PlayerGui.Data.Egg

    for _, v in pairs(EggFolder:GetChildren()) do
        local T = v:GetAttribute("T")
        if T and not v:FindFirstChild("DI") and not table.find(Items, T) then
            table.insert(Items, T)
        end
    end

    for i = #Items, 1, -1 do
        local found = false
        for _, v in pairs(EggFolder:GetChildren()) do
            if v:GetAttribute("T") == Items[i] and not v:FindFirstChild("DI") then
                found = true
                break
            end
        end
        if not found then
            table.remove(Items, i)
        end
    end
end

UpdateEgg()

SelectEggPlace = Tabs.Place:Dropdown({
    Title = "Select Egg",
    Multi = false,
    AllowNone = false,
    Value = getgenv().Settings.AutoPlace.SelectEgg,
    Values = Items,
    Callback = function(Value)
        getgenv().Settings.AutoPlace.SelectEgg = Value
        SaveSetting()
    end
})

local Refresh = Tabs.Place:Button({
    Title = "Refresh",
    Callback = function()
        UpdateEgg()
        if SelectEgg then
            SelectEgg:Refresh(Items)
        end
    end
})

local AutoEquipEgg = Tabs.Place:Toggle({
    Title = "Auto Equip",
    Desc = "Automatic Equip your egg.",
    Value = getgenv().Settings.AutoPlace.AutoEquipEgg,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.AutoPlace.AutoEquipEgg = Value
        SaveSetting()
        if Value then
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.AutoPlace.AutoEquipEgg do task.wait(0.5)
                        if getgenv().Settings.AutoPlace.AutoPlacePet or getgenv().Settings.AutoPlace.AutoPlaceOcean then
                            for i,v in pairs(game:GetService("Players").LocalPlayer.PlayerGui.Data.Egg:GetChildren()) do
                                if v:GetAttribute("T") == getgenv().Settings.AutoPlace.SelectEgg and not v:FindFirstChild("DI") then
                                    if not chr:FindFirstChild("HandObj") then
                                        game:GetService("ReplicatedStorage").Remote.CharacterRE:FireServer("Focus", v.Name)
                                        break
                                    elseif game.Players.LocalPlayer:GetAttribute("HoldUID") ~= v.Name then
                                        game:GetService("ReplicatedStorage").Remote.CharacterRE:FireServer("Focus", v.Name)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end)
            end)
        end
    end
})

local AutoPlaceTab = Tabs.Place:Section({ Title = "Auto Place" })

local FarmPet = {}
local WaterPet = {}

for i,v in pairs(workspace.Art[getgenv().MyIsland]:GetChildren()) do
    if v.Name:lower():find("^farm") then
        table.insert(FarmPet, v)
    end
end

for i,v in pairs(workspace.Art[getgenv().MyIsland]:GetChildren()) do
    if v.Name:lower():find("^water") then
        table.insert(WaterPet, v)
    end
end

local AutoPlacePet = Tabs.Place:Toggle({
    Title = "Auto Place Pet",
    Value = getgenv().Settings.AutoPlace.AutoPlacePet,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.AutoPlace.AutoPlacePet = Value
        SaveSetting()
        if Value then
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.AutoPlace.AutoPlacePet do task.wait(2)
                        if #FarmPet > 0 then
                            local randompos = FarmPet[math.random(10, #FarmPet)]
                        
                            local ohString1 = "Place"
                            local ohTable2 = {
                                ["DST"] = randompos.Position,
                                ["ID"] = game.Players.LocalPlayer:GetAttribute("HoldUID")
                            }
                        
                            game:GetService("ReplicatedStorage").Remote.CharacterRE:FireServer(ohString1, ohTable2)
                        end
                    end
                end)
            end)
        end
    end
})

local AutoPlaceOcean = Tabs.Place:Toggle({
    Title = "Auto Place Ocean",
    Value = getgenv().Settings.AutoPlace.AutoPlaceOcean,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.AutoPlace.AutoPlaceOcean = Value
        SaveSetting()
        if Value then
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.AutoPlace.AutoPlaceOcean do task.wait(1)
                        if #WaterPet > 0 then
                            local randompos = WaterPet[math.random(1, #WaterPet)]
                        
                            local ohString1 = "Place"
                            local ohTable2 = {
                                ["DST"] = randompos.Position,
                                ["ID"] = game.Players.LocalPlayer:GetAttribute("HoldUID")
                            }
                        
                            game:GetService("ReplicatedStorage").Remote.CharacterRE:FireServer(ohString1, ohTable2)
                        end
                    end
                end)
            end)
        end
    end
})

local AutoHatchTab = Tabs.Place:Section({ Title = "Auto Hatch" })

local AutoHatch = Tabs.Place:Toggle({
    Title = "Auto Hatch",
    Value = getgenv().Settings.AutoPlace.AutoHatch,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.AutoPlace.AutoHatch = Value
        SaveSetting()
        if Value then
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.AutoPlace.AutoHatch do task.wait(1)
                        for i,v in pairs(workspace.PlayerBuiltBlocks:GetChildren()) do
                            if v:GetAttribute("UserId") == UserId then
                                if v:IsA("Model") and v:FindFirstChild("ExclamationMark") then
                                    fireproximityprompt(v.RootPart.ProximityPrompt)
                                end
                            end
                        end
                    end
                end)
            end)
        end
    end
})

-------------------------------- Shop --------------------------------

local FruitTab = Tabs.Shop:Section({ Title = "Fruits Stock" })    

local Fruitss = {}
local Fruits = {}
local Stock = {}

for i,v in pairs(game:GetService("Players").LocalPlayer.PlayerGui.Data.FoodStore:GetChildren()) do
    local att = v:GetAttributes()
    for i2,v2 in pairs(att) do
        table.insert(Fruitss, {Name = i2, Stock = v2})
    end
end

for i,v in pairs(Fruitss) do
    Fruits[i] = v.Name
    Stock[v] = v.Stock
end

local SelectFruitShop = Tabs.Shop:Dropdown({
    Title = "Select Fruit",
    Values = Fruits,
    Multi = true,
    Value = getgenv().Settings.Shop.Fruits,
    AllowNone = false,
    Callback = function(Value)
        getgenv().Settings.Shop.Fruits = Value
        SaveSetting()
    end
})

local AutoBuyFruits = Tabs.Shop:Toggle({
    Title = "Auto Buy Fruits",
    Desc = "Automatic Buy Fruits",
    Value = getgenv().Settings.Shop.AutoBuyFruits,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Shop.AutoBuyFruits = Value
        SaveSetting()

        if Value then
            spawn(function()
                pcall(function()
                    while getgenv().Settings.Shop.AutoBuyFruits do 
                        for i,v in ipairs(getgenv().Settings.Shop.Fruits) do
                            for i2,v2 in pairs(game:GetService("Players").LocalPlayer.PlayerGui.Data.FoodStore:GetChildren()) do
                                local att = v2:GetAttributes()
                                for fruitName, stockAmount in pairs(att) do
                                    Stock[fruitName] = stockAmount
                                end
                            end
                            if Stock[v] and Stock[v] > 0 then
                                game:GetService("ReplicatedStorage").Remote.FoodStoreRE:FireServer(v)
                            else
                                task.wait(.1)
                            end
                        end
                        task.wait(.1)
                    end
                end)
            end)
        end
    end
})

-------------------------------- Auto Feed --------------------------------

local AutoFeed

local AutoEquipFruit = Tabs.Feed:Section({ Title = "Auto Equip Fruit" })

local SelectFruit = Tabs.Feed:Dropdown({
    Title = "Select Fruit",
    Values = Fruits,
    Multi = false,
    Value = getgenv().Settings.Feed.SelectFruit,
    AllowNone = false,
    Callback = function(Value)
        getgenv().Settings.Feed.SelectFruit = Value
        SaveSetting()
    end
})

local AutoEquip = Tabs.Feed:Toggle({
    Title = "Auto Equip",
    Value = getgenv().Settings.Feed.AutoEquip,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Feed.AutoEquip = Value
        SaveSetting()

        if Value then
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.Feed.AutoEquip do task.wait(0.5)
                        if getgenv().Settings.Feed.AutoFeed then
                            game:GetService("ReplicatedStorage").Remote.CharacterRE:FireServer(unpack({[1] = "Focus",[2] = getgenv().Settings.Feed.SelectFruit}))
                        end
                    end
                end)
            end)
        end
    end
})

local AutoFeedTab = Tabs.Feed:Section({ Title = "Auto Feed" })

local SelectPet = Tabs.Feed:Dropdown({
    Title = "Select Pet",
    Values = {"Big Pet", "Big Fish"},
    Multi = false,
    Value = getgenv().Settings.Feed.SelectPet,
    AllowNone = false,
    Callback = function(Value)
        getgenv().Settings.Feed.SelectPet = Value
        SaveSetting()
    end
})

AutoFeed = Tabs.Feed:Toggle({
    Title = "Auto Feed",
    Desc = "Automatic Feed your big pets.",
    Value = getgenv().Settings.Feed.AutoFeed,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Feed.AutoFeed = Value
        SaveSetting()

        if Value then
            if not getgenv().Settings.Feed.SelectPet then
                WindUI:Notify({
                    Title = "Venuz | Notify",
                    Content = "Please Select Pet Mode.",
                    Icon = VenuzIcon,
                    Duration = 5,
                })
                task.wait(.5)
                AutoFeed:Set(false)
                return
            end
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.Feed.AutoFeed do task.wait(0.5)
                        if getgenv().Settings.Feed.SelectPet == "Big Pet" then
                            for i,v in pairs(workspace.Pets:GetChildren()) do
                                if v:FindFirstChild("RootPart") and table.find({"Normal","Unique"}, v:FindFirstChild("RootPart"):GetAttribute("BigPetType")) and v:FindFirstChild("RootPart"):GetAttribute("UserId") == UserId then
                                    game:GetService("ReplicatedStorage").Remote.PetRE:FireServer("Feed", v.Name)
                                end
                            end
                        elseif getgenv().Settings.Feed.SelectPet == "Big Fish" then
                            for i,v in pairs(workspace.Pets:GetChildren()) do
                                if v:FindFirstChild("RootPart"):GetAttribute("BigPetType") == "Fish" and v:FindFirstChild("RootPart"):GetAttribute("UserId") == UserId then
                                    game:GetService("ReplicatedStorage").Remote.PetRE:FireServer("Feed", v.Name)
                                end
                            end
                        end
                    end
                end)
            end)
        end
    end
})

-------------------------------- Quest --------------------------------

local QuestTab = Tabs.Quest:Section({ Title = "Snow Tasks" })

local AutoSnowTask = Tabs.Quest:Toggle({
    Title = "Auto ClaimReward",
    Value = getgenv().Settings.Quest.AutoSnowQuest,
    Icon = "check",
    Callback = function(Quest)
        getgenv().Settings.Quest.AutoSnowQuest = Quest
        SaveSetting()

        task.spawn(function()
            pcall(function()
                if Quest then
                    while getgenv().Settings.Quest.AutoSnowQuest do task.wait(1)
                        for i,v in pairs(game:GetService("Players").LocalPlayer.PlayerGui.Data.DinoEventTaskData.Tasks:GetChildren()) do
                            game:GetService("ReplicatedStorage").Remote.DinoEventRE:FireServer({["event"] = "claimreward",["id"] = v:GetAttribute("Id")})
                        end
                    end
                end
            end)
        end)
    end
})

-------------------------------- Fish --------------------------------

local BaitsFree = {
    ["Cheese Bait"] = "FishingBait1",
    ["Fly Bait"] = "FishingBait2",
    ["Fish Bait"] = "FishingBait3"
}

local BaitReverse = {}
for name, value in pairs(BaitsFree) do
    BaitReverse[value] = name
end

local FishTab = Tabs.Fish:Section({ Title = "Auto Fish" })

local SelectBaitNormal = Tabs.Fish:Dropdown({
    Title = "Select Bait",
    Multi = false,
    AllowNone = true,
    Values = {"Cheese Bait", "Fly Bait", "Fish Bait"},
    Value = BaitReverse[getgenv().Settings.Fish.SelectBait],
    Callback = function(Value)
        getgenv().Settings.Fish.SelectBait = BaitsFree[Value]
        SaveSetting()
    end
})

local AutoFish = Tabs.Fish:Toggle({
    Title = "Auto Fish",
    Value = getgenv().Settings.Fish.AutoFish,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Fish.AutoFish = Value
        SaveSetting()

        local State = game.Players.LocalPlayer.Character:GetAttribute("AnimFish")
        local PositionCG = CFrame.new(-582, 36, 66)

        task.spawn(function()
            pcall(function()
                if Value then
                    while getgenv().Settings.Fish.AutoFish do task.wait()

                        if not hrp.Anchored then
                            hrp.Anchored = true
                            TeleportToWaypoint(PositionCG)
                        end

                        if not hrp.Parent:FindFirstChild("FishRob") then
                            game.Players.LocalPlayer:SetAttribute("HoldUID", "FishRob")
                        end
                        if hrp.Parent:FindFirstChild("FishRob") then
                            task.wait(0.5)
                            if hrp.Anchored then
                            State = game.Players.LocalPlayer.Character:GetAttribute("AnimFish")
                            if State == "Ready" then

                                local foundSpecial = false

                                for i,v in pairs(workspace.FishPoints:GetChildren()) do
                                    local hasFX = v:FindFirstChild("FX_Fish_Special")
                                    
                                    if hasFX then
                                        game:GetService("ReplicatedStorage").Remote.FishingRE:FireServer("Throw", {["Bait"] = getgenv().Settings.Fish.SelectBait,["Pos"] = hasFX.Scope.Position})
                                        foundSpecial = true
                                        break
                                    end
                                end
                                if not foundSpecial then
                                    game:GetService("ReplicatedStorage").Remote.FishingRE:FireServer("Throw", {["Bait"] = getgenv().Settings.Fish.SelectBait,["Pos"] = Vector3.new(-626.116455078125, 11, 52.02362823486328)})
                                end                                                   
                                repeat task.wait()
                                    if not hrp.Anchored then
                                        hrp.Anchored = true
                                        TeleportToWaypoint(PositionCG)
                                    end
                                    State = game.Players.LocalPlayer.Character:GetAttribute("AnimFish")
                                until State == "Pull" or getgenv().Settings.Fish.AutoFish == false or game.Players.LocalPlayer:GetAttribute("HoldUID") ~= "FishRob"
                            elseif State == "Pull" then
                                game:GetService("ReplicatedStorage").Remote.FishingRE:FireServer("POUT", {["SUC"] = 1})
                            end
                        end
                    end
                end
                else
                    hrp.Anchored = false
                    game.Players.LocalPlayer:SetAttribute("HoldUID", nil)
                end
            end)
        end)
    end
})

-------------------------------- Gift --------------------------------
local SelectedPlr = nil
local SelectedTarget = nil
local SelectedMutation = nil
local SelectedType = nil

local Infomation = Tabs.Gift:Paragraph({
    Title = "Infomation",
    Desc = "select item..."
})

function updateInfomation()
    local holdUID = LocalPlayer:GetAttribute("HoldUID")

    if not holdUID then
        Infomation:SetDesc("select item...")
        SelectedTarget, SelectedMutation, SelectedType = nil, nil, nil
        return
    end

    local target, mutation = nil, nil
    local count = 0
    local foundType = nil

    for _, v in pairs(game:GetService("Players").LocalPlayer.PlayerGui.Data.Pets:GetChildren()) do
        if not v:GetAttribute("D") and v.Name == holdUID then
            target = v:GetAttribute("T")
            mutation = v:GetAttribute("M") or "No Mutation"
            foundType = "Pet"
            break
        end
    end

    if not foundType then
        for _, v in pairs(game:GetService("Players").LocalPlayer.PlayerGui.Data.Egg:GetChildren()) do
            if not v:FindFirstChild("DI") and v.Name == holdUID then
                target = v:GetAttribute("T")
                mutation = v:GetAttribute("M") or "No Mutation"
                foundType = "Egg"
                break
            end
        end
    end

    if target and foundType then
        SelectedTarget = target
        SelectedMutation = mutation
        SelectedType = foundType

        if foundType == "Pet" then
            for _, v in pairs(game:GetService("Players").LocalPlayer.PlayerGui.Data.Pets:GetChildren()) do
                if not v:GetAttribute("D") then
                    local match = (mutation == "No Mutation" and not v:GetAttribute("M"))
                        or (v:GetAttribute("M") == mutation)
                    if v:GetAttribute("T") == target and match then
                        count += 1
                    end
                end
            end
            Infomation:SetDesc(
                L("PetName") .. " : " .. target .."\n" .. L("Mutation") .. " : " .. mutation .."\n" .. L("PetHave") .. " : " .. count)
        else
            for _, v in pairs(game:GetService("Players").LocalPlayer.PlayerGui.Data.Egg:GetChildren()) do
                if not v:FindFirstChild("DI") then
                    local match = (mutation == "No Mutation" and not v:GetAttribute("M"))
                        or (v:GetAttribute("M") == mutation)
                    if v:GetAttribute("T") == target and match then
                        count += 1
                    end
                end
            end
            Infomation:SetDesc(L("EggName") .. " : " .. target .."\n" .. L("Mutation") .. " : " .. mutation .."\n" .. L("EggHave") .. " : " .. count)
        end
    else
        Infomation:SetDesc("ไม่พบ Item ที่ตรงกับ HoldUID")
        SelectedTarget, SelectedMutation, SelectedType = nil, nil, nil
    end
end

LocalPlayer:GetAttributeChangedSignal("HoldUID"):Connect(updateInfomation)
updateInfomation()

local TabsGift = Tabs.Gift:Section({ Title = "Gift" })

local PlayersTable = {}
local playersIndex = {}
local SelectedPlr = nil

local SelectedPlayer = Tabs.Gift:Dropdown({
    Title = "Select Player",
    Values = {},
    Multi = false,
    AllowNone = true,
    Callback = function(Value)
        SelectedPlr = Value
    end
})

local Amout = Tabs.Gift:Input({
    Title = "Amount",
    Value = 0,
    Placeholder = "1",
    Callback = function(Value)
        num = tonumber(Value)
    end
})

function SendHoldEggs(toPlayer, amount)
    if not SelectedTarget or not SelectedType then
        WindUI:Notify({
            Title = "Venuz | Notify",
            Content = "No item selected",
            Icon = VenuzIcon,
            Duration = 5,
        })
        return
    end

    local folder = (SelectedType == "Pet")
        and LocalPlayer.PlayerGui.Data.Pets
        or LocalPlayer.PlayerGui.Data.Egg

    -- สร้าง list ของ items ที่ match SelectedTarget + SelectedMutation
    local validItems = {}
    for _, v in pairs(folder:GetChildren()) do
        local isDeleted = (SelectedType == "Pet" and v:GetAttribute("D")) or (SelectedType == "Egg" and v:FindFirstChild("DI"))
        if not isDeleted then
            local mutationValue = v:GetAttribute("M") or "No Mutation"
            if v:GetAttribute("T") == SelectedTarget and mutationValue == SelectedMutation then
                table.insert(validItems, v)
            end
        end
    end

    if #validItems == 0 then
        WindUI:Notify({
            Title = "Venuz | Notify",
            Content = "No valid items to send",
            Icon = VenuzIcon,
            Duration = 5,
        })
        return
    end

    local sent = 0
    for _, egg in pairs(validItems) do
        if sent >= amount then break end

        if SelectedType == "Egg" then
            -- equip ก่อนส่ง
            game:GetService("ReplicatedStorage").Remote.CharacterRE:FireServer("Focus", egg.Name)
            task.wait(0.1)
            LocalPlayer:SetAttribute("HoldUID", egg.Name)
        else
            LocalPlayer:SetAttribute("HoldUID", egg.Name)
        end

        -- ส่ง item
        game:GetService("ReplicatedStorage").Remote.GiftRE:FireServer(toPlayer, egg)
        sent += 1
        task.wait(0.3)
    end

    if sent < amount then
        WindUI:Notify({
            Title = "Venuz | Notify",
            Content = "Not enough items (sent " .. sent .. "/" .. amount .. ")",
            Icon = VenuzIcon,
            Duration = 5,
        })
    end
end

local SendGift = Tabs.Gift:Button({
    Title = "Send Gift",
    Callback = function()
        if not SelectedPlr then
            WindUI:Notify({
                Title = "Venuz | Notify",
                Content = "No player selected",
                Icon = VenuzIcon,
                Duration = 5,
            })
            return
        end

        local targetPlayer = nil
        for _, p in pairs(game:GetService("Players"):GetPlayers()) do
            if p.Name == SelectedPlr then
                targetPlayer = p
                break
            end
        end

        if not targetPlayer then
            WindUI:Notify({
                Title = "Venuz | Notify",
                Content = "Selected player not found",
                Icon = VenuzIcon,
                Duration = 5,
            })
            return
        end

        local amount = tonumber(num) or 1
        if amount < 1 then
            WindUI:Notify({
                Title = "Venuz | Notify",
                Content = "Invalid amount",
                Icon = VenuzIcon,
                Duration = 5,
            })
            return
        end

        if targetPlayer then
            TeleportToWaypoint(targetPlayer.Character.HumanoidRootPart.CFrame)
        end

        task.wait(2)

        SendHoldEggs(targetPlayer, amount)
    end
})

function refreshDropdown()
    local names = {}
    for i, entry in ipairs(PlayersTable) do
        names[i] = entry.Name
    end
    SelectedPlayer:Refresh(names)

    if SelectedPlr and not table.find(names, SelectedPlr) then
        SelectedPlr = nil
    end
end

function addPlayer(player)
    if player == LocalPlayer then return end
    local uid = tostring(player.UserId)
    if playersIndex[uid] then
        local idx = playersIndex[uid]
        if PlayersTable[idx].Name ~= player.Name then
            PlayersTable[idx].Name = player.Name
            refreshDropdown()
        end
        return
    end

    table.insert(PlayersTable, { Name = player.Name, UserId = uid })
    playersIndex[uid] = #PlayersTable
    refreshDropdown()

    player:GetPropertyChangedSignal("Name"):Connect(function()
        local idx = playersIndex[uid]
        if idx then
            PlayersTable[idx].Name = player.Name
            refreshDropdown()
        end
    end)
end

function removePlayer(player)
    local uid = tostring(player.UserId)
    local idx = playersIndex[uid]
    if not idx then return end

    table.remove(PlayersTable, idx)
    playersIndex[uid] = nil
    for i = idx, #PlayersTable do
        playersIndex[PlayersTable[i].UserId] = i
    end

    refreshDropdown()
end

for _, p in ipairs(Players:GetPlayers()) do
    addPlayer(p)
end

Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(removePlayer)

-------------------------------- Webhook --------------------------------

local function SendDiscordEmbed(url, embed)
    local http = game:GetService("HttpService")
    local headers = {
        ["Content-Type"] = "application/json"
    }
    local data = {
        ["embeds"] = {
            {
                ["title"] = embed.title,
                ["description"] = embed.description,
                ["color"] = embed.color,
                ["fields"] = embed.fields,
                ["image"] = embed.image,
            }
        }
    }
    local body = http:JSONEncode(data)
    local response = request({
        Url = url,
        Method = "POST",
        Headers = headers,
        Body = body
    })
end

local TabsWebhook = Tabs.Webhook:Section({ Title = "Setup Webhook" })

local WebhookUrl = Tabs.Webhook:Input({
    Title = "Url",
    Value = getgenv().Settings.Webhook.WebhookUrl,
    Placeholder = "https://discord.com/api/webhooks",
    Callback = function(Value)
        getgenv().Settings.Webhook.WebhookUrl = Value
        SaveSetting()
    end
})

local testembed = {
    ["title"] = "Venuz Test",
    ["color"] = 16777215,
    ["fields"] = {
    {
        ["name"] = "ข้อมูล",
        ["value"] = "`` 👤 `` : **ชื่อ " .. "||".. game.Players.LocalPlayer.Name.. "||" .. "**\n`` 💻 `` : **ตัวรัน "..identifyexecutor().."**\n`` 🕓 `` : **เวลา ".. currentTime .."**\n`` 🎮 `` : **Build A Zoo**",
        ["inline"] =  false
    },
    {
        ["name"] = "Test Status",
        ["value"] = "```🟢```"
    }
    },
    ["image"] = {
      ["url"] = "https://tr.rbxcdn.com/180DAY-f212509b8348e6273a1e4784d653ee07/768/432/Image/Webp/noFilter"
    },
}

local TestWebhook = Tabs.Webhook:Button({
    Title = "Test Webhook",
    Callback = function()
        if getgenv().Settings.Webhook.WebhookUrl == "" then
            WindUI:Notify({Title = "Venuz | Notify",Content = "Please Enter Webhook Url.",Icon = VenuzIcon,Duration = 5,})
            return
        end
        SendDiscordEmbed(getgenv().Settings.Webhook.WebhookUrl, testembed)
        WindUI:Notify({Title = "Venuz | Notify",Content = "Send Webhook Successfully.",Icon = VenuzIcon,Duration = 5,})
    end
})

local EggTabsWebhook = Tabs.Webhook:Section({ Title = "Eggs" })

local CheckAllEgg = Tabs.Webhook:Button({
    Title = "Check All Egg",
    Callback = function(Value)
        local counts = {}

        for _, v in pairs(game:GetService("Players").LocalPlayer.PlayerGui.Data.Egg:GetChildren()) do
            if not v:FindFirstChild("DI") then
                local t = v:GetAttribute("T")
                local m = v:GetAttribute("M") or "No Mutation"
                if t then
                    local key = t
                    if m ~= "No Mutation" then
                        key = t .. " (" .. m .. ")"
                    end
                    counts[key] = (counts[key] or 0) + 1
                end
            end
        end

        local keys = {}
        for k in pairs(counts) do table.insert(keys, k) end
        table.sort(keys)

        local eggList = {}
        for _, name in ipairs(keys) do
            table.insert(eggList, name .. " x" .. counts[name])
        end
        local eggText = table.concat(eggList, "\n")

        local embed = {
            ["title"] = "Venuz Test",
            ["color"] = 16777215,
            ["fields"] = {
                {
                    ["name"] = "ข้อมูล",
                    ["value"] = "`` 👤 `` : **ชื่อ " .. "||".. game.Players.LocalPlayer.Name.. "||" .. "**\n`` 💻 `` : **ตัวรัน "..identifyexecutor().."**\n`` 🕓 `` : **เวลา ".. os.date("%H:%M:%S") .."**\n`` 🎮 `` : **Game Build A Zoo**",
                    ["inline"] =  false
                },
                {
                    ["name"] = "Eggs",
                    ["value"] = "```"..eggText.."```",
                    ["inline"] = false
                }
            },
            ["image"] = {
                ["url"] = "https://tr.rbxcdn.com/180DAY-f212509b8348e6273a1e4784d653ee07/768/432/Image/Webp/noFilter"
            },
        }
        SendDiscordEmbed(getgenv().Settings.Webhook.WebhookUrl, embed)
    end
})

-------------------------------- Premium --------------------------------

local Baits = {
    ["Cheese Bait"] = "FishingBait1",
    ["Fly Bait"] = "FishingBait2",
    ["Fish Bait"] = "FishingBait3"
}

local BaitReverse = {}
for name, value in pairs(Baits) do
    BaitReverse[value] = name
end

local FishPosition = Tabs.Premium:Section({ Title = "Fish Position" })

function GetVectorFromTable(posTable)
    if typeof(posTable) == "table" and #posTable > 0 then
        local posStr = table.concat(posTable, " ")
        local x, y, z = string.match(posStr, "([%-%d%.]+),%s*([%-%d%.]+),%s*([%-%d%.]+)")
        if x and y and z then
            return Vector3.new(tonumber(x), tonumber(y), tonumber(z))
        end
    end
    return nil
end

local PositionFish = Tabs.Premium:Paragraph({
    Title = "Position",
    Desc = "Position : "..(getgenv().Settings.Premium.PositionFish and table.concat(getgenv().Settings.Premium.PositionFish) or " : Not set")
})

local SavePosition = Tabs.Premium:Button({
    Title = "Save Position",
    Callback = function()
        local pos = hrp.Position
        getgenv().Settings.Premium.PositionFish = {math.round(pos.X) .. ", " .. math.round(pos.Y) .. ", " .. math.round(pos.Z)}
        SaveSetting()
        PositionFish:SetDesc("Position : " .. table.concat(getgenv().Settings.Premium.PositionFish) or "Not set")
    end
})

local AutoFishPremiumTabs = Tabs.Premium:Section({ Title = "Auto Fish" })

local SelectBait = Tabs.Premium:Dropdown({
    Title = "Select Bait",
    Multi = false,
    AllowNone = true,
    Values = {"Cheese Bait", "Fly Bait", "Fish Bait"},
    Value = BaitReverse[getgenv().Settings.Premium.SelectBait],
    Callback = function(Value)
        if getgenv().IsPremium == "Premium Access" then
            getgenv().Settings.Premium.SelectBait = Baits[Value]
            SaveSetting()
        end
    end
})

local AutoFishPremium = Tabs.Premium:Toggle({
    Title = "Auto Fish (Event Only)",
    Value = getgenv().Settings.Premium.AutoFish,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Premium.AutoFish = Value
        SaveSetting()

        local State = game.Players.LocalPlayer.Character:GetAttribute("AnimFish")

        task.spawn(function()
            pcall(function()
                if Value then
                    while getgenv().Settings.Premium.AutoFish do task.wait()

                        if not hrp.Anchored then
                            hrp.Anchored = true
                        end

                        if not hrp.Parent:FindFirstChild("FishRob") then
                            game.Players.LocalPlayer:SetAttribute("HoldUID", "FishRob")
                        end
                        if workspace:GetAttribute("Weather") == "Snow" then
                        if hrp.Parent:FindFirstChild("FishRob") then
                            TeleportToWaypoint(CFrame.new(GetVectorFromTable(getgenv().Settings.Premium.PositionFish)))
                            if hrp.Anchored then
                            State = game.Players.LocalPlayer.Character:GetAttribute("AnimFish")
                            if State == "Ready" then
                                for i,v in pairs(workspace.FishPoints:GetChildren()) do
                                    local hasFX = v:FindFirstChild("FX_Fish_Special")
                                    if hasFX then
                                        game:GetService("ReplicatedStorage").Remote.FishingRE:FireServer("Throw", {["Bait"] = getgenv().Settings.Premium.SelectBait,["Pos"] = hasFX.Scope.Position})
                                        break
                                    end
                                end                                                 
                                repeat task.wait()
                                    State = game.Players.LocalPlayer.Character:GetAttribute("AnimFish")
                                until State == "Pull" or getgenv().Settings.Fish.AutoFish == false or game.Players.LocalPlayer:GetAttribute("HoldUID") ~= "FishRob"
                            elseif State == "Pull" then
                                game:GetService("ReplicatedStorage").Remote.FishingRE:FireServer("POUT", {["SUC"] = 1})
                            end
                        end
                    end
                end
            end
                else
                    hrp.Anchored = false
                    game.Players.LocalPlayer:SetAttribute("HoldUID", nil)
                end
            end)
        end)
    end
})

function ServerHop()
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")

    local Servers = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    local Server, Next = nil, nil
    local function ListServers(cursor)
        local Raw = game:HttpGet(Servers .. ((cursor and "&cursor=" .. cursor) or ""))
        return HttpService:JSONDecode(Raw)
    end

    repeat
        local Servers = ListServers(Next)
        Server = Servers.data[math.random(1, (#Servers.data / 3))]
        Next = Servers.nextPageCursor
    until Server

    if Server.playing < Server.maxPlayers and Server.id ~= game.JobId then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, Server.id, game.Players.LocalPlayer)
    end
end

local ServerHopFindSnow = Tabs.Premium:Toggle({
    Title = "Server Hop Find Event",
    Value = getgenv().Settings.Premium.HopServer,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Premium.HopServer = Value
        SaveSetting()

        if Value then
            spawn(function()
                pcall(function()
                    while getgenv().Settings.Premium.HopServer do task.wait(1)
                        for i,v in pairs(workspace.FishPoints.FishPoint1:GetChildren()) do
                            if v.Name == "FX_Fish_Special_Wait" then
                                ServerHop()
                            end
                        end
                    end
                end)
            end)
        end
    end
})
-------------------------------- Configuration --------------------------------

local IS = Tabs.Configuration:Section({ Title = "Interface Settings" })

local themeValues = {}
for name, _ in pairs(WindUI:GetThemes()) do
    table.insert(themeValues, name)
end

local themeDropdown = Tabs.Configuration:Dropdown({
    Title = "Select Theme",
    Multi = false,
    AllowNone = false,
    Value = getgenv().ConfigurationTable.Themes,
    Values = themeValues,
    Callback = function(theme)
        getgenv().ConfigurationTable.Themes = theme
        SaveConfiguration()
        WindUI:SetTheme(theme)
    end
})

themeDropdown:Select(WindUI:GetCurrentTheme())

local ToggleTransparency = Tabs.Configuration:Toggle({
    Title = "Toggle Window Transparency",
    Value = getgenv().ConfigurationTable.Transparent,
    Icon = "check",
    Callback = function(e)
        getgenv().ConfigurationTable.Transparent = e
        SaveConfiguration()
        Window:ToggleTransparency(e)
    end,
    Value = WindUI:GetTransparency()
})

local AntiAFK = Tabs.Configuration:Toggle({
    Title = "Anti-AFK",
    Value = getgenv().ConfigurationTable.AntiAFK,
    Icon = "check",
    Callback = function(enabled)
        local VirtualUser = game:service('VirtualUser')
        local antiAfkConnection = nil

        getgenv().ConfigurationTable.AntiAFK = enabled
        SaveConfiguration()

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
    Value = getgenv().ConfigurationTable.AutoExecutor,
    Icon = "check",
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoExecutor = Value
        SaveConfiguration()
    end
})

local MinimizeBind = Tabs.Configuration:Keybind({
    Title = "Minimize Bind",
    Value = getgenv().ConfigurationTable.MinimizeBind,
    Callback = function(v)
        getgenv().ConfigurationTable.MinimizeBind = v
        SaveConfiguration()
        Window:SetToggleKey(Enum.KeyCode[v])
    end
})

local Language
local ChangedLanguage
local LanguageTab

function updateLanguage()
    -- 🔹 Tabs
    if Tabs.Automatic then Tabs.Automatic:SetTabTitle(L("Automatic")) end
    if Tabs.Eggs then Tabs.Eggs:SetTabTitle(L("Eggs")) end
    if Tabs.Place then Tabs.Place:SetTabTitle(L("Place")) end
    if Tabs.Shop then Tabs.Shop:SetTabTitle(L("Shop")) end
    if Tabs.Feed then Tabs.Feed:SetTabTitle(L("Feed")) end
    if Tabs.Quest then Tabs.Quest:SetTabTitle(L("Quest")) end
    if Tabs.Fish then Tabs.Fish:SetTabTitle(L("Fish")) end
    if Tabs.Gift then Tabs.Gift:SetTabTitle(L("Gift")) end
    if Tabs.Webhook then Tabs.Webhook:SetTabTitle(L("Webhook")) end
    if Tabs.Premium then Tabs.Premium:SetTabTitle(L("Premium")) end
    if Tabs.Configuration then Tabs.Configuration:SetTabTitle(L("Configuration")) end

    -- 🔹 Section: Auto Collect
    if AutoCollectTab then AutoCollectTab:SetTitle(L("AutoCollectTab")) end
    if AutoCollect then AutoCollect:SetTitle(L("AutoCollect_Title")) end
    if AutoCollect then AutoCollect:SetDesc(L("AutoCollect_Desc")) end
    if DelayCollect then DelayCollect:SetTitle(L("DelayCollect")) end
    if QuickTab then QuickTab:SetTitle(L("QuickTab")) end
    if QuickCollect then QuickCollect:SetTitle(L("QuickCollect_Title")) end
    if QuickCollect then QuickCollect:SetDesc(L("QuickCollect_Desc")) end
    if CollectPet then CollectPet:SetTitle(L("CollectPet")) end
    if Eard then Eard:SetTitle(L("Eard")) end
    if CollectAllPetEarn then CollectAllPetEarn:SetTitle(L("CollectAllPetEarn")) end
    if CollectAllPet then CollectAllPet:SetTitle(L("CollectAllPet")) end

    -- 🔹 Section: Auto Buy Eggs
    if AutoBuyEggTab then AutoBuyEggTab:SetTitle(L("AutoBuyEggTab")) end
    if SelectEggs then SelectEggs:SetTitle(L("SelectEggs")) end
    if AutoBuyEgg then AutoBuyEgg:SetTitle(L("AutoBuyEgg_Title")) end
    if AutoBuyEgg then AutoBuyEgg:SetDesc(L("AutoBuyEgg_Desc")) end
    if AutoBuyEggwithmutationTab then AutoBuyEggwithmutationTab:SetTitle(L("AutoBuyEggwithmutationTab")) end
    if SelectEggsWith then SelectEggsWith:SetTitle(L("SelectEggsWith")) end
    if SelectMutation then SelectMutation:SetTitle(L("SelectMutation")) end
    if AutoBuyEggwithmutation then AutoBuyEggwithmutation:SetTitle(L("AutoBuyEggwithmutation_Title")) end
    if AutoBuyEggwithmutation then AutoBuyEggwithmutation:SetDesc(L("AutoBuyEggwithmutation_Desc")) end
    if AutoBuyEggwithEventSnowTab then AutoBuyEggwithEventSnowTab:SetTitle(L("AutoBuyEggwithEventSnowTab")) end
    if SelectEggevent then SelectEggevent:SetTitle(L("SelectEggevent")) end
    if SnowMutatuion then SnowMutatuion:SetTitle(L("SnowMutatuion")) end
    if AutoBuyEggwithEventSnow then AutoBuyEggwithEventSnow:SetTitle(L("AutoBuyEggwithEventSnow_Title")) end
    if AutoBuyEggwithEventSnow then AutoBuyEggwithEventSnow:SetDesc(L("AutoBuyEggwithEventSnow_Desc")) end

    -- 🔹 Section: Auto Place & Hatch
    if AutoEquipEgg then AutoEquipEgg:SetTitle(L("AutoEquipEgg")) end
    if SelectEggPlace then SelectEggPlace:SetTitle(L("SelectEggPlace")) end
    if Refresh then Refresh:SetTitle(L("Refresh")) end
    if AutoEquipEgg then AutoEquipEgg:SetTitle(L("AutoEquipEgg_Title")) end
    if AutoEquipEgg then AutoEquipEgg:SetDesc(L("AutoEquipEgg_Desc")) end
    if AutoPlaceTab then AutoPlaceTab:SetTitle(L("AutoPlaceTab")) end
    if AutoPlacePet then AutoPlacePet:SetTitle(L("AutoPlacePet")) end
    if AutoPlaceOcean then AutoPlaceOcean:SetTitle(L("AutoPlaceOcean")) end
    if AutoHatchTab then AutoHatchTab:SetTitle(L("AutoHatchTab")) end
    if AutoHatch then AutoHatch:SetTitle(L("AutoHatch")) end

    -- 🔹 Section: Shop
    if FruitTab then FruitTab:SetTitle(L("FruitTab")) end
    if SelectFruitShop then SelectFruitShop:SetTitle(L("SelectFruit")) end
    if AutoBuyFruits then AutoBuyFruits:SetTitle(L("AutoBuyFruits_Title")) end
    if AutoBuyFruits then AutoBuyFruits:SetDesc(L("AutoBuyFruits_Desc")) end

    -- 🔹 Section: Auto Feed
    if AutoEquipFruit then AutoEquipFruit:SetTitle(L("AutoEquipFruit")) end
    if SelectFruit then SelectFruit:SetTitle(L("SelectFruit")) end
    if AutoEquip then AutoEquip:SetTitle(L("AutoEquip")) end
    if AutoFeedTab then AutoFeedTab:SetTitle(L("AutoFeedTab")) end
    if SelectPet then SelectPet:SetTitle(L("SelectPet")) end
    if AutoFeed then AutoFeed:SetTitle(L("AutoFeed_Title")) end
    if AutoFeed then AutoFeed:SetDesc(L("AutoFeed_Desc")) end

    -- 🔹 Section: Auto Quest
    if QuestTab then QuestTab:SetTitle(L("QuestTab")) end
    if AutoSnowTask then AutoSnowTask:SetTitle(L("AutoSnowTask")) end

    -- 🔹 Section: Fish
    if FishTab then FishTab:SetTitle(L("FishTab")) end
    if SelectBaitNormal then SelectBaitNormal:SetTitle(L("SelectBaitNormal")) end
    if AutoFish then AutoFish:SetTitle(L("AutoFish")) end

    -- 🔹 Section: Gift
    if TabsGift then TabsGift:SetTitle(L("TabsGift")) end
    if PetName then PetName:SetTitle(L("PetName")) end
    if Mutation then Mutation:SetTitle(L("Mutation")) end
    if PetHave then PetHave:SetTitle(L("PetHave")) end
    if EggName then EggName:SetTitle(L("EggName")) end
    if EggHave then EggHave:SetTitle(L("EggHave")) end
    if NotFoundItem then NotFoundItem:SetTitle(L("NotFoundItem")) end
    if SelectItem then SelectItem:SetTitle(L("SelectItem")) end
    if Infomation then Infomation:SetTitle(L("Infomation")) end
    if SelectedPlayer then SelectedPlayer:SetTitle(L("SelectedPlayer")) end
    if Amout then Amout:SetTitle(L("Amout")) end
    if SendGift then SendGift:SetTitle(L("SendGift")) end

    -- 🔹 Section: Webhook
    if TabsWebhook then TabsWebhook:SetTitle(L("TabsWebhook")) end
    if WebhookUrl then WebhookUrl:SetTitle(L("WebhookUrl")) end
    if TestWebhook then TestWebhook:SetTitle(L("TestWebhook")) end
    if EggTabsWebhook then EggTabsWebhook:SetTitle(L("EggTabsWebhook")) end
    if CheckAllEgg then CheckAllEgg:SetTitle(L("CheckAllEgg")) end

    -- 🔹 Section: Premium
    if FishPosition then FishPosition:SetTitle(L("FishPosition")) end
    if PositionFish then PositionFish:SetTitle(L("PositionFish")) end
    if SavePosition then SavePosition:SetTitle(L("SavePosition")) end
    if AutoFishPremiumTabs then AutoFishPremiumTabs:SetTitle(L("AutoFishPremiumTabs")) end
    if SelectBait then SelectBait:SetTitle(L("SelectBait")) end
    if AutoFishPremium then AutoFishPremium:SetTitle(L("AutoFishPremium")) end
    if ServerHopFindSnow then ServerHopFindSnow:SetTitle(L("ServerHopFindSnow")) end

    -- 🔹 Section: Configuration
    if themeDropdown then themeDropdown:SetTitle(L("themeDropdown")) end
    if ToggleTransparency then ToggleTransparency:SetTitle(L("ToggleTransparency")) end
    if AntiAFK then AntiAFK:SetTitle(L("AntiAFK")) end
    if AutoExecutor then AutoExecutor:SetTitle(L("AutoExecutor")) end
    if MinimizeBind then MinimizeBind:SetTitle(L("MinimizeBind")) end
    if LanguageTab then LanguageTab:SetTitle(L("LanguageTab")) end
    if Interface then Interface:SetTitle(L("Interface")) end
    if Language then Language:SetTitle(L("Language")) end
    if ChangedLanguage then ChangedLanguage:SetTitle(L("ChangedLanguage")) end
    if IS then IS:SetTitle(L("Interface")) end
end

LanguageTab =  Tabs.Configuration:Section({ Title = "↪ Language" })

Language = Tabs.Configuration:Dropdown({
    Title = "Language",
    Multi = false,
    AllowNone = false,
    Values = {"English (US)","Thai"},
    Value = getgenv().ConfigurationTable.Language,
    Callback = function(Callback)
        LanguageSelect = Callback
        getgenv().ConfigurationTable.Language = Callback
        SaveConfiguration()
    end
})

ChangedLanguage = Tabs.Configuration:Button({
    Title = "Change Language",
    Icon = "check",
    Callback = function()
        getgenv().ConfigurationTable.Language = LanguageSelect
        updateLanguage()
        Window:SelectTab(1)
    end
})

local queueteleport = queue_on_teleport
local TeleportCheck = false

while not Players.LocalPlayer do task.wait() end

LocalPlayer.OnTeleport:Connect(function(State)
    pcall(function()
        if getgenv().ConfigurationTable and getgenv().ConfigurationTable.AutoExecutor and (not TeleportCheck) and queueteleport then
            TeleportCheck = true
            queueteleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/x2Kotaro/Venuz-hub/main/Loader.lua"))()')
        end
    end)
end)

Window:SetToggleKey(Enum.KeyCode[getgenv().ConfigurationTable.MinimizeBind])
Window:SelectTab(1)

WindUI:Notify({
    Title = "Script | Loader",
    Content = "Script Loader Successfully",
    Icon = VenuzIcon,
    Duration = 5,
})

updateLanguage()

task.wait(5)

Updated()
SelectEggs:Refresh(EggsTable)
SelectEggsWith:Refresh(EggsTable)