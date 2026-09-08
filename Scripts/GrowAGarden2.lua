pcall(function()
    if game:GetService("CoreGui"):FindFirstChild("Folder"):FindFirstChild("WindUI") then
        return
    end
end)

getgenv().ConfigurationTable = {}
getgenv().Settings = {}
 
local FolderConfiguration = "Venuz Hub"
local FolderSettings = "Venuz Hub/Grow A Garden 2"
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
local VirtualInputManager = game:GetService("VirtualInputManager")
local CollectionService = game:GetService("CollectionService")

local filenameConfiguration = FolderConfiguration .. "/" .. "Setting_".. LocalPlayer.Name .. ".json"
local filenameSetting = FolderSettings .. "/" .. "Config_".. LocalPlayer.Name..".json"

---- ============ Configuration ============ ---- 

local DefaultConfiguration = {
    ["Themes"] = "Crimson",
    ["Transparent"] = true,
    ["AntiAFK"] = true,
    ["AutoRejoin"] = false,
    ["AutoExecutor"] = true,
    ["MinimizeBind"] = "End",
    ["Language"] = "English (US)",
    ["FPSValue"] = 144,
    ["LockFPS"] = false,
    ["WhileScreen"] = false,
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

---- ============ SaveSettings ============ ----

local DefaultSettings = {
    ["Main"] = {
        ["SelectPlant"] = {},
        ["SelectMethod"] = "Random",
        ["AutoPlant"] = false,
        ["SelectHarvestName"] = {},
        ["SelectHarvestRarity"] = {},
        ["SelectHarvestMutation"] = {},
        ["AutoHarvestSelected"] = false,
        ["HarvestAll"] = false,
        ["AutoPlantDelay"] = 0.0001,
        ["AutoHarvestDelay"] = 0.0001,
        ["AutoSell"] = false,
        ["AutoSellDelay"] = 1,
        ["AutoSellFull"] = false,
        ["SelectStealName"] = {},
        ["SelectStealRarity"] = {},
        ["SelectStealMutation"] = {},
        ["AutoStealSelected"] = false,
        ["StealAll"] = false,
        ["AutoStealDelay"] = 0.0001,
        ["SelectSeedBuy"] = {},
        ["AutoBuySeed"] = false,
        ["AutoBuyDelay"] = 0.5,
        ["SelectGearBuy"] = {},
        ["AutoBuyGear"] = false,
        ["SelectPropBuy"] = {},
        ["AutoBuyProp"] = false,
        ["AutoBuyGearDelay"] = 0.5,
    },
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

---- ============ Setup UI ============ ----

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/x2Kotaro/API/main/test.lua"))()

local Device
if UserInputService.TouchEnabled then
    Device = UDim2.fromOffset(450, 300)
else
    Device = UDim2.fromOffset(650, 520)
end

WindUI:Localization({
    Enabled = true,
    Prefix = "tr:",
    DefaultLanguage = getgenv().ConfigurationTable.Language,
    Translations = {
        ["Thai"] = {
            ["Automaic"] = "อัตโนมัติ",
            ["AutoPlantTab"] = "ปลูกพืชออโต้",
            ["SelectPlant"] = "เลือกพืช",
            ["DescSelectPlant"] = "เลือกว่าจะปลูกพืชอะไรบ้าง เลือกได้หลายอย่าง",
            ["SelectMethod"] = "เลือกรูปแบบ",
            ["DescSelectMethod"] = "Random = ปลูกตำแหน่งสุ่ม / Player = ปลูกตรงตัวละครยืนอยู่",
            ["AutoPlantDelay"] = "ความเร็วในการปลูก (Delay)",
            ["DescAutoPlantDelay"] = "ตั้งค่าหน่วงเวลาปลูก ใส่ตัวเลขยิ่งน้อยยิ่งไว (หน่วยเป็นวินาที)",
            ["AutoPlant"] = "ปลูกพืชออโต้",
            ["DescAutoPlant"] = "เปิดแล้วระบบจะปลูกพืชให้เองอัตโนมัติตามที่เลือกไว้ด้านบน",
            ["AutoHarvestTab"] = "เก็บเกี่ยวออโต้",
            ["SelectHarvestName"] = "เลือกพืชที่จะเก็บเกี่ยว",
            ["DescSelectHarvestName"] = "เลือกชื่อผลไม้ที่อยากให้เก็บ ไม่เลือกก็เก็บทุกอย่าง",
            ["SelectHarvestRarity"] = "เลือกระดับความหายาก",
            ["DescSelectHarvestRarity"] = "เลือกว่าจะให้เก็บเฉพาะผลไม้ระดับไหน เช่น Common, Rare, Legendary",
            ["SelectHarvestMutation"] = "เลือกผลกลายพันธุ์",
            ["DescSelectHarvestMutation"] = "เลือกว่าจะเก็บแบบไหน เช่น ธรรมดา, Gold, Rainbow",
            ["AutoHarvestDelay"] = "ความเร็วในการเก็บเกี่ยว (Delay)",
            ["DescAutoHarvestDelay"] = "ตั้งค่าหน่วงเวลาเก็บเกี่ยว ใส่ตัวเลขยิ่งน้อยยิ่งไว (หน่วยเป็นวินาที)",
            ["AutoHarvestSelected"] = "เก็บเกี่ยวตามที่เลือก",
            ["DescAutoHarvestSelected"] = "เก็บเกี่ยวเฉพาะผลไม้ที่ตรงกับเงื่อนไขที่เลือกไว้ด้านบน",
            ["HarvestAll"] = "เก็บเกี่ยวทั้งหมด",
            ["DescHarvestAll"] = "เก็บเกี่ยวผลไม้ทุกอย่างในสวนโดยไม่สนเงื่อนไขอะไรเลย",
            ["AutoSellTab"] = "ขายออโต้",
            ["AutoSellDelay"] = "ความเร็วในการขาย (Delay)",
            ["DescAutoSellDelay"] = "ตั้งค่าหน่วงเวลาขาย ใส่ตัวเลขยิ่งน้อยยิ่งขายไว (หน่วยเป็นวินาที)",
            ["AutoSell"] = "ขายออโต้ตามเวลา",
            ["DescAutoSell"] = "เปิดแล้วจะขายผลไม้ในกระเป๋าให้เรื่อยๆ ตามเวลา Delay ที่ตั้งไว้",
            ["AutoSellFull"] = "ขายออโต้เมื่อกระเป๋าเต็ม",
            ["DescAutoSellFull"] = "ขายผลไม้ให้อัตโนมัติเฉพาะตอนที่ช่องเก็บของเต็มเท่านั้น",
            ["ShopTab"] = "ร้านค้า",
            ["DescShopTab"] = "ซื้อเมล็ดพืช",
            ["SeedShopTab"] = "ร้านซื้อเมล็ด",
            ["SelectSeedBuy"] = "เลือกเมล็ดพืช",
            ["DescSelectSeedBuy"] = "เลือกเมล็ดพืชที่ต้องการซื้อรัวๆ",
            ["AutoBuyDelay"] = "หน่วงเวลาการซื้อ (Delay)",
            ["DescAutoBuyDelay"] = "ตั้งเวลาหน่วง ยิ่งน้อยยิ่งซื้อไว (วินาที)",
            ["AutoBuySeed"] = "ออโต้ซื้อเมล็ด",
            ["DescAutoBuySeed"] = "เปิดเพื่อเริ่มซื้อเมล็ดอัตโนมัติ",
            ["GearShopTab"] = "ร้านซื้อเกียร์",
            ["SelectGearBuy"] = "เลือกเกียร์",
            ["DescSelectGearBuy"] = "เลือกเกียร์ที่ต้องการซื้อรัวๆ",
            ["AutoBuyGearDelay"] = "หน่วงเวลาซื้อเกียร์ (Delay)",
            ["DescAutoBuyGearDelay"] = "ตั้งเวลาหน่วง ยิ่งน้อยยิ่งซื้อไว (วินาที)",
            ["AutoBuyGear"] = "ออโต้ซื้อเกียร์",
            ["DescAutoBuyGear"] = "เปิดเพื่อเริ่มซื้อเกียร์อัตโนมัติ",
            ["PropShopTab"] = "ร้านซื้อของตกแต่ง",
            ["SelectPropBuy"] = "เลือกของตกแต่ง",
            ["DescSelectPropBuy"] = "เลือกของตกแต่งที่ต้องการซื้อรัวๆ",
            ["AutoBuyProp"] = "ออโต้ซื้อของตกแต่ง",
            ["DescAutoBuyProp"] = "เปิดเพื่อเริ่มซื้อของตกแต่งอัตโนมัติ",
            ["Configuration"] = "การตั้งค่า",
            ["Interface"] = "อินเตอร์เฟซ",
            ["themeDropdown"] = "เลือกธีม",
            ["ToggleTransparency"] = "พื้นหลังโปร่งใส",
            ["AntiAFK"] = "ป้องกันการหลุด (Anti-AFK)",
            ["AutoRejoin"] = "เข้าเกมใหม่เมื่อหลุด (Auto Rejoin)",
            ["AutoExecutor"] = "รันสคริปต์อัตโนมัติ (Auto Execute)",
            ["MinimizeBind"] = "ปุ่มซ่อน/แสดงเมนู",
            ["FPSIS"] = "การตั้งค่า FPS",
            ["FPSVALUE"] = "ค่า FPS",
            ["FPSLOCK"] = "ล็อค FPS",
            ["WhiteScreen"] = "จอขาว (ลดแลค)",
            ["LanguageTab"] = "ภาษา",
            ["Language"] = "เลือกภาษา",
            ["ChangedLanguage"] = "เปลี่ยนภาษา",
            ["ScriptLoader"] = "ตัวโหลดสคริปต์",
            ["ScriptLoaded"] = "โหลดสคริปต์เสร็จสมบูรณ์",
        },
        ["English (US)"] = {
            ["Automaic"] = "Automatic",
            ["AutoPlantTab"] = "Auto Plant",
            ["SelectPlant"] = "Select Plant",
            ["DescSelectPlant"] = "Pick which plants you want to grow. You can select multiple.",
            ["SelectMethod"] = "Select Method",
            ["DescSelectMethod"] = "Random = plant at a random spot / Player = plant where you're standing.",
            ["AutoPlantDelay"] = "Auto Plant Delay",
            ["DescAutoPlantDelay"] = "How fast the auto-plant runs. Lower number = faster. (in seconds)",
            ["AutoPlant"] = "Auto Plant",
            ["DescAutoPlant"] = "Turn this on and it will plant seeds for you based on what you picked above.",
            ["AutoHarvestTab"] = "Auto Harvest",
            ["SelectHarvestName"] = "Select Harvest Name",
            ["DescSelectHarvestName"] = "Pick which fruits to harvest. Leave empty to harvest everything.",
            ["SelectHarvestRarity"] = "Select Harvest Rarity",
            ["DescSelectHarvestRarity"] = "Only harvest fruits of these rarities, like Common, Rare, Legendary, etc.",
            ["SelectHarvestMutation"] = "Select Harvest Mutation",
            ["DescSelectHarvestMutation"] = "Only harvest fruits with these mutations, like None, Gold, Rainbow, etc.",
            ["AutoHarvestDelay"] = "Auto Harvest Delay",
            ["DescAutoHarvestDelay"] = "How fast the auto-harvest runs. Lower number = faster. (in seconds)",
            ["AutoHarvestSelected"] = "Auto Harvest Selected",
            ["DescAutoHarvestSelected"] = "Harvests only the fruits that match your filters above.",
            ["HarvestAll"] = "Harvest All",
            ["DescHarvestAll"] = "Harvests every fruit in your garden, no filters applied.",
            ["AutoSellTab"] = "Auto Sell",
            ["AutoSellDelay"] = "Auto Sell Delay",
            ["DescAutoSellDelay"] = "How fast the auto-sell runs. Lower number = faster. (in seconds)",
            ["AutoSell"] = "Auto Sell By Delay",
            ["DescAutoSell"] = "Keeps selling your fruits on a timer based on the delay you set above.",
            ["AutoSellFull"] = "Auto Sell With Backpack Full",
            ["DescAutoSellFull"] = "Only sells your fruits when your backpack is completely full.",
            ["ShopTab"] = "Shop",
            ["DescShopTab"] = "Buy seeds here",
            ["SeedShopTab"] = "Seed Shop",
            ["SelectSeedBuy"] = "Select Seed",
            ["DescSelectSeedBuy"] = "Select the seed you want to auto buy.",
            ["AutoBuyDelay"] = "Auto Buy Delay",
            ["DescAutoBuyDelay"] = "Delay for auto buy. Lower is faster (seconds).",
            ["AutoBuySeed"] = "Auto Buy Seed",
            ["DescAutoBuySeed"] = "Turn on to automatically buy the selected seed.",
            ["GearShopTab"] = "Gear Shop",
            ["SelectGearBuy"] = "Select Gear",
            ["DescSelectGearBuy"] = "Select the gear you want to auto buy.",
            ["AutoBuyGearDelay"] = "Auto Buy Gear Delay",
            ["DescAutoBuyGearDelay"] = "Delay for auto gear buy. Lower is faster (seconds).",
            ["AutoBuyGear"] = "Auto Buy Gear",
            ["DescAutoBuyGear"] = "Turn on to automatically buy the selected gear.",
            ["PropShopTab"] = "Props Shop",
            ["SelectPropBuy"] = "Select Prop",
            ["DescSelectPropBuy"] = "Select the prop you want to auto buy.",
            ["AutoBuyProp"] = "Auto Buy Prop",
            ["DescAutoBuyProp"] = "Turn on to automatically buy the selected prop.",
            ["Configuration"] = "Configuration",
            ["Interface"] = "Interface Settings",
            ["themeDropdown"] = "Select Theme",
            ["ToggleTransparency"] = "Toggle Window Transparency",
            ["AntiAFK"] = "Anti-AFK",
            ["AutoRejoin"] = "AutoRejoin",
            ["AutoExecutor"] = "AutoExecutor",
            ["MinimizeBind"] = "Minimize Bind",
            ["FPSIS"] = "FPS",
            ["FPSVALUE"] = "FPS",
            ["FPSLOCK"] = "FPS Lock",
            ["WhiteScreen"] = "White Screen",
            ["LanguageTab"] = "Language",
            ["Language"] = "Select Language",
            ["ChangedLanguage"] = "Change Language",
            ["ScriptLoader"] = "Script Loader",
            ["ScriptLoaded"] = "Script has been loaded successfully.",
        }
    }
})

local CurrentLanguage = getgenv().ConfigurationTable.Language

if CurrentLanguage == "English (US)" then
    WindUI:SetLanguage("English (US)")
else
    WindUI:SetLanguage("Thai")
end

local Window = WindUI:CreateWindow({
    Title = "Valkyrie Hub",
    Author = "by Phoenix",
    Size = Device,
    Transparent = getgenv().ConfigurationTable.Transparent,
    Theme = getgenv().ConfigurationTable.Themes,
    SideBarWidth = 200,
    HasOutline = true,
    ScrollBarEnabled = true,
    Resizable = false,
})

Window:Tag({
    Title = "Update Latest 2/20/2026",
    Color = Color3.fromHex("#f4fc02"),
    Radius = 13,
})

Window:EditOpenButton({
    Title = "Valkyrie Hub",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new(
        Color3.fromHex("FF0F7B"), 
        Color3.fromHex("F89B29")
    ),
    OnlyMobile = true,
    Enabled = true,
    Draggable = true,
})

---- ============ Function ============ ----

function TeleportToWaypoint(Position)
    hrp.CFrame = CFrame.new(Position)
end

---- ============ List Data ============ ----

local SeedsTable = {}
local ShopSeedsTable = {}
local success, seedData = pcall(function()
    return require(game:GetService("ReplicatedStorage"):WaitForChild("SharedModules"):WaitForChild("SeedData"))
end)

if success and type(seedData) == "table" then
    for _, data in ipairs(seedData) do
        if type(data) == "table" and data.SeedName then
            table.insert(SeedsTable, data.SeedName)
            if data.RestockShop == true then
                table.insert(ShopSeedsTable, data.SeedName)
            end
        end
    end
end

local Rarity = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Super"}
local SeedRarity = {
    ["Carrot"] = "Common",
    ["Strawberry"] = "Common",
    ["Blueberry"] = "Common",
    ["Tulip"] = "Uncommon",
    ["Tomato"] = "Uncommon",
    ["Apple"] = "Uncommon",
    ["Bamboo"] = "Rare",
    ["Corn"] = "Rare",
    ["Cactus"] = "Rare",
    ["Pineapple"] = "Rare",
    ["Baby Cactus"] = "Rare",
    ["Horned Melon"] = "Rare",
    ["Mushroom"] = "Epic",
    ["Green Bean"] = "Epic",
    ["Banana"] = "Epic",
    ["Grape"] = "Epic",
    ["Coconut"] = "Epic",
    ["Mango"] = "Epic",
    ["Glow Mushroom"] = "Epic",
    ["Dragon Fruit"] = "Legendary",
    ["Acorn"] = "Legendary",
    ["Cherry"] = "Legendary",
    ["Sunflower"] = "Legendary",
    ["Poison Ivy"] = "Legendary",
    ["Gold"] = "Legendary",
    ["Venus Fly Trap"] = "Mythic",
    ["Pomegranate"] = "Mythic",
    ["Poison Apple"] = "Mythic",
    ["Ghost Pepper"] = "Mythic",
    ["Romanesco"] = "Mythic",
    ["Rainbow"] = "Mythic",
    ["Moon Bloom"] = "Super",
    ["Dragon's Breath"] = "Super",
}

local GearDataList = {
    {ItemName = "Common Watering Can", ItemType = "Watering Can", Cost = 2000, Rarity = "Common"},
    {ItemName = "Common Sprinkler", ItemType = "Common Sprinkler", Cost = 3000, Rarity = "Common"},
    {ItemName = "Sign", ItemType = "Sign", Cost = 4000, Rarity = "Common"},
    {ItemName = "Trowel", ItemType = "Trowel", Cost = 1000, Rarity = "Rare"},
    {ItemName = "Speed Mushroom", ItemType = "Mushroom", Cost = 1500, Rarity = "Rare"},
    {ItemName = "Jump Mushroom", ItemType = "Mushroom", Cost = 1800, Rarity = "Rare"},
    {ItemName = "Uncommon Sprinkler", ItemType = "Uncommon Sprinkler", Cost = 10000, Rarity = "Uncommon"},
    {ItemName = "Shrink Mushroom", ItemType = "Mushroom", Cost = 10000, Rarity = "Epic"},
    {ItemName = "Lantern", ItemType = "Lantern", Cost = 12000, Rarity = "Rare"},
    {ItemName = "Supersize Mushroom", ItemType = "Mushroom", Cost = 20000, Rarity = "Epic"},
    {ItemName = "Flashbang", ItemType = "Flashbang", Cost = 20000, Rarity = "Epic"},
    {ItemName = "Invisibility Mushroom", ItemType = "Mushroom", Cost = 30000, Rarity = "Legendary"},
    {ItemName = "Teleporter", ItemType = "Teleporter", Cost = 60000, Rarity = "Legendary"},
    {ItemName = "Rare Sprinkler", ItemType = "Rare Sprinkler", Cost = 80000, Rarity = "Rare"},
    {ItemName = "Gnome", ItemType = "Gnome", Cost = 100000, Rarity = "Epic"},
    {ItemName = "Basic Pot", ItemType = "EmptyPot", Cost = 300000, Rarity = "Epic"},
    {ItemName = "Super Sprinkler", ItemType = "Super Sprinkler", Cost = 300000, Rarity = "Super"},
    {ItemName = "Wheelbarrow", ItemType = "Wheelbarrow", Cost = 500000, Rarity = "Legendary"},
    {ItemName = "Super Watering Can", ItemType = "Watering Can", Cost = 1000000, Rarity = "Super"},
    {ItemName = "Legendary Sprinkler", ItemType = "Legendary Sprinkler", Cost = 1200000, Rarity = "Legendary"},
}

local GearNamesTable = {}
for _, gear in ipairs(GearDataList) do
    table.insert(GearNamesTable, gear.ItemName)
end

local MutationsTable = {"None"}
local isMutation = {}
for i,v in pairs(game:GetService("ReplicatedStorage").SharedModules.MutationData:GetChildren()) do
    table.insert(MutationsTable, v.Name)
    isMutation[v.Name] = true
end

local PropNamesTable = {}
pcall(function()
    for i,v in pairs(game:GetService("ReplicatedStorage").SharedModules.CrateData:GetChildren()) do
        table.insert(PropNamesTable, v.Name)
    end
end)


---- ============ Interface ============ ----

local Tab = Window:Tab({
    Title = "tr:Automaic",
    Icon = "code-xml",
    Opened = true,
})

local AutoPlantTab = Tab:Section({ Title = "tr:AutoPlantTab", Icon = "flower", Opened = true})

local SelectPlant = AutoPlantTab:Dropdown({
    Title = "tr:SelectPlant",
    Desc = "tr:DescSelectPlant",
    Multi = true,
    AllowNone = false,
    Value = getgenv().Settings.Main.SelectPlant,
    Values = SeedsTable,
    Callback = function(e)
        getgenv().Settings.Main.SelectPlant = e
        SaveSetting()
    end,
})

local SelectMethod = AutoPlantTab:Dropdown({
    Title = "tr:SelectMethod",
    Desc = "tr:DescSelectMethod",
    Multi = false,
    AllowNone = false,
    Value = getgenv().Settings.Main.SelectMethod,
    Values = {"Random", "Player"},
    Callback = function(e)
        getgenv().Settings.Main.SelectMethod = e
        SaveSetting()
    end,
})

local AutoPlantDelay = AutoPlantTab:Input({
    Title = "tr:AutoPlantDelay",
    Desc = "tr:DescAutoPlantDelay",
    Value = tostring(getgenv().Settings.Main.AutoPlantDelay),
    Callback = function(e)
        local val = tonumber(e)
        if val then
            getgenv().Settings.Main.AutoPlantDelay = val
            SaveSetting()
        end
    end,
})

local AutoPlantToggle = AutoPlantTab:Toggle({
    Title = "tr:AutoPlant",
    Desc = "tr:DescAutoPlant",
    Value = getgenv().Settings.Main.AutoPlant,
    Callback = function(e)
        getgenv().Settings.Main.AutoPlant = e
        SaveSetting()

        if e then
            task.spawn(function()
                while getgenv().Settings.Main.AutoPlant do
                    task.wait(getgenv().Settings.Main.AutoPlantDelay)
                    pcall(function()
                        local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
                        local character = game:GetService("Players").LocalPlayer.Character
                        if not character then return end
                        
                        local humanoid = character:FindFirstChild("Humanoid")
                        if not humanoid then return end

                        local selectedPlants = getgenv().Settings.Main.SelectPlant
                        local tool = character:FindFirstChildWhichIsA("Tool")
                        local hasValidToolEquipped = false

                        if tool then
                            local seedName = tool:GetAttribute("SeedTool")
                            if seedName and (#selectedPlants == 0 or table.find(selectedPlants, seedName)) then
                                hasValidToolEquipped = true
                            end
                        end

                        if not hasValidToolEquipped and #selectedPlants > 0 then
                            local backpack = game:GetService("Players").LocalPlayer:FindFirstChild("Backpack")
                            if backpack then
                                for _, v in pairs(backpack:GetChildren()) do
                                    local seed = v:GetAttribute("SeedTool")
                                    if seed and v:GetAttribute("MainCategory") and table.find(selectedPlants, seed) then
                                        humanoid:EquipTool(v)
                                        tool = v
                                        hasValidToolEquipped = true
                                        break
                                    end
                                end
                            end
                        end

                        if not hasValidToolEquipped or not tool then return end

                        local seedName = tool:GetAttribute("SeedTool")
                        if not seedName then return end

                        for i,v in pairs(workspace.Gardens:GetChildren()) do
                            if v:GetAttribute("OwnerUserId") == game.Players.LocalPlayer.UserId then
                                getgenv().Plot = v.Name
                            end
                        end

                        if not getgenv().Plot then return end

                        local worldPos
                        local method = getgenv().Settings.Main.SelectMethod

                        if method == "Player" then
                            local hrp = character:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                worldPos = hrp.Position
                            end
                        elseif method == "Random" then
                            local column = math.random(1, 2)
                            local plantAreaName = "PlantAreaColumn" .. tostring(column)
                            local plantArea = workspace.Gardens[getgenv().Plot].Visual:FindFirstChild(plantAreaName)

                            if plantArea then
                                local size = plantArea.Size
                                local cf = plantArea.CFrame
                                local rx = (math.random() - 0.5) * size.X
                                local rz = (math.random() - 0.5) * size.Z
                                worldPos = cf:PointToWorldSpace(Vector3.new(rx, 0, rz))
                            end
                        end

                        if worldPos then
                            Networking.Plant.PlantSeed:Fire(worldPos, seedName, tool)
                        end
                    end)
                end
            end)
        end
    end,
})

local AutoHarvestTab = Tab:Section({ Title = "tr:AutoHarvestTab", Icon = "leaf", Opened = true})
local SelectHarvestName = AutoHarvestTab:Dropdown({
    Title = "tr:SelectHarvestName",
    Desc = "tr:DescSelectHarvestName",
    Multi = true,
    AllowNone = true,
    Value = getgenv().Settings.Main.SelectHarvestName,
    Values = SeedsTable,
    Callback = function(e)
        getgenv().Settings.Main.SelectHarvestName = e
        SaveSetting()
    end,
})

local SelectHarvestRarity = AutoHarvestTab:Dropdown({
    Title = "tr:SelectHarvestRarity",
    Desc = "tr:DescSelectHarvestRarity",
    Multi = true,
    AllowNone = true,
    Value = getgenv().Settings.Main.SelectHarvestRarity,
    Values = Rarity,
    Callback = function(e)
        getgenv().Settings.Main.SelectHarvestRarity = e
        SaveSetting()
    end,
})

local SelectHarvestMutation = AutoHarvestTab:Dropdown({
    Title = "tr:SelectHarvestMutation",
    Desc = "tr:DescSelectHarvestMutation",
    Multi = true,
    AllowNone = true,
    Value = getgenv().Settings.Main.SelectHarvestMutation,
    Values = MutationsTable,
    Callback = function(e)
        getgenv().Settings.Main.SelectHarvestMutation = e
        SaveSetting()
    end,
})

local AutoHarvestDelay = AutoHarvestTab:Input({
    Title = "tr:AutoHarvestDelay",
    Desc = "tr:DescAutoHarvestDelay",
    Value = tostring(getgenv().Settings.Main.AutoHarvestDelay),
    Callback = function(e)
        getgenv().Settings.Main.AutoHarvestDelay = e
        SaveSetting()
    end,
})

local AutoHarvestSelected = AutoHarvestTab:Toggle({
    Title = "tr:AutoHarvestSelected",
    Desc = "tr:DescAutoHarvestSelected",
    Value = getgenv().Settings.Main.AutoHarvestSelected,
    Callback = function(e)
        getgenv().Settings.Main.AutoHarvestSelected = e
        SaveSetting()

        if e then
            task.spawn(function()
                while getgenv().Settings.Main.AutoHarvestSelected do
                    task.wait(getgenv().Settings.Main.AutoHarvestDelay)
                    pcall(function()
                        if not getgenv().Plot then
                            for i,v in pairs(workspace.Gardens:GetChildren()) do
                                if v:GetAttribute("OwnerUserId") == game.Players.LocalPlayer.UserId then
                                    getgenv().Plot = v.Name
                                end
                            end
                        end
                        if not getgenv().Plot then return end
                        
                        local garden = workspace.Gardens:FindFirstChild(getgenv().Plot)
                        if not garden then return end
                        local plantsFolder = garden:FindFirstChild("Plants")
                        if not plantsFolder then return end

                        local activeNameFilter = getgenv().Settings.Main.SelectHarvestName and type(getgenv().Settings.Main.SelectHarvestName) == "table" and #getgenv().Settings.Main.SelectHarvestName > 0
                        local activeRarityFilter = getgenv().Settings.Main.SelectHarvestRarity and type(getgenv().Settings.Main.SelectHarvestRarity) == "table" and #getgenv().Settings.Main.SelectHarvestRarity > 0
                        local activeMutationFilter = getgenv().Settings.Main.SelectHarvestMutation and type(getgenv().Settings.Main.SelectHarvestMutation) == "table" and #getgenv().Settings.Main.SelectHarvestMutation > 0

                        local hasActiveFilter = activeNameFilter or activeRarityFilter or activeMutationFilter
                        if not hasActiveFilter then return end

                        for _, plant in pairs(plantsFolder:GetChildren()) do
                            local seedName = plant:GetAttribute("SeedName")
                            local mutation = plant:GetAttribute("Mutation") or "None"
                            local rarity = SeedRarity[seedName] or "None"

                            local matchName = activeNameFilter and table.find(getgenv().Settings.Main.SelectHarvestName, seedName)
                            local matchRarity = activeRarityFilter and table.find(getgenv().Settings.Main.SelectHarvestRarity, rarity)
                            local matchMutation = activeMutationFilter and table.find(getgenv().Settings.Main.SelectHarvestMutation, mutation)

                            if matchName or matchRarity or matchMutation then
                                local fruitsFolder = plant:FindFirstChild("Fruits")
                                if fruitsFolder then
                                    for _, fruit in pairs(fruitsFolder:GetChildren()) do
                                        local harvestPart = fruit:FindFirstChild("HarvestPart")
                                        if harvestPart then
                                            local prompt = harvestPart:FindFirstChild("HarvestPrompt")
                                            if prompt and prompt:IsA("ProximityPrompt") then
                                                if fireproximityprompt then
                                                    fireproximityprompt(prompt)
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end)
                end
            end)
        end
    end,
})

local HarvestAll = AutoHarvestTab:Toggle({
    Title = "tr:HarvestAll",
    Desc = "tr:DescHarvestAll",
    Value = getgenv().Settings.Main.HarvestAll,
    Callback = function(e)
        getgenv().Settings.Main.HarvestAll = e
        SaveSetting()

        if e then
            task.spawn(function()
                while getgenv().Settings.Main.HarvestAll do
                    task.wait(getgenv().Settings.Main.AutoHarvestDelay)
                    pcall(function()
                        if not getgenv().Plot then
                            for i,v in pairs(workspace.Gardens:GetChildren()) do
                                if v:GetAttribute("OwnerUserId") == game.Players.LocalPlayer.UserId then
                                    getgenv().Plot = v.Name
                                end
                            end
                        end
                        if not getgenv().Plot then return end
                        
                        local garden = workspace.Gardens:FindFirstChild(getgenv().Plot)
                        if not garden then return end
                        local plantsFolder = garden:FindFirstChild("Plants")
                        if not plantsFolder then return end

                        for _, plant in pairs(plantsFolder:GetChildren()) do
                            local fruitsFolder = plant:FindFirstChild("Fruits")
                            if fruitsFolder then
                                for _, fruit in pairs(fruitsFolder:GetChildren()) do
                                    local harvestPart = fruit:FindFirstChild("HarvestPart")
                                    if harvestPart then
                                        local prompt = harvestPart:FindFirstChild("HarvestPrompt")
                                        if prompt and prompt:IsA("ProximityPrompt") then
                                            if fireproximityprompt then
                                                fireproximityprompt(prompt)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end)
                end
            end)
        end
    end,
})

local AutoStealTab = Tab:Section({ Title = "Auto Steal", Icon = "ghost", Opened = true})

local SelectStealName = AutoStealTab:Dropdown({
    Title = "Select Steal Name",
    Desc = "Pick which fruits to steal. Leave empty to steal everything.",
    Multi = true,
    AllowNone = true,
    Value = getgenv().Settings.Main.SelectStealName,
    Values = SeedsTable,
    Callback = function(e)
        getgenv().Settings.Main.SelectStealName = e
        SaveSetting()
    end,
})

local SelectStealRarity = AutoStealTab:Dropdown({
    Title = "Select Steal Rarity",
    Desc = "Only steal fruits of these rarities.",
    Multi = true,
    AllowNone = true,
    Value = getgenv().Settings.Main.SelectStealRarity,
    Values = Rarity,
    Callback = function(e)
        getgenv().Settings.Main.SelectStealRarity = e
        SaveSetting()
    end,
})

local SelectStealMutation = AutoStealTab:Dropdown({
    Title = "Select Steal Mutation",
    Desc = "Only steal fruits with these mutations.",
    Multi = true,
    AllowNone = true,
    Value = getgenv().Settings.Main.SelectStealMutation,
    Values = MutationsTable,
    Callback = function(e)
        getgenv().Settings.Main.SelectStealMutation = e
        SaveSetting()
    end,
})

local ActiveTween = nil
local function TweenDirect(targetPosition, speed)
    local character = game.Players.LocalPlayer.Character
    if not character then return end
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    local tweenService = game:GetService("TweenService")

    if ActiveTween then
        ActiveTween:Cancel()
        ActiveTween = nil
    end

    local originalCFrame = humanoidRootPart.CFrame
    local _, originalY, _ = originalCFrame:ToOrientation()

    local finalPosition = CFrame.new(targetPosition) * CFrame.Angles(0, originalY, 0)
    local distance = (humanoidRootPart.Position - targetPosition).Magnitude

    local timeToTween = distance / speed
    if timeToTween <= 0.01 then timeToTween = 0.01 end

    local tweenUp = tweenService:Create(
        humanoidRootPart,
        TweenInfo.new(timeToTween, Enum.EasingStyle.Linear),
        {CFrame = finalPosition}
    )

    ActiveTween = tweenUp
    tweenUp:Play()

    tweenUp.Completed:Connect(function()
        if tweenUp.PlaybackState == Enum.PlaybackState.Completed then
            ActiveTween = nil
        end
    end)

    return tweenUp
end

local AutoStealSelected = AutoStealTab:Toggle({
    Title = "Auto Steal Selected",
    Desc = "Steals only the fruits that match your filters above.",
    Value = getgenv().Settings.Main.AutoStealSelected,
    Callback = function(e)
        getgenv().Settings.Main.AutoStealSelected = e
        SaveSetting()

        if not e then
            local char = game:GetService("Players").LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.Anchored = false
            end
        end

        if e then
            task.spawn(function()
                while getgenv().Settings.Main.AutoStealSelected do
                    task.wait()
                    pcall(function()
                        if workspace:GetAttribute("ActivePhase") ~= "Night" then return end
                        
                        local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
                        if not pg then return end
                        
                        local activeNameFilter = getgenv().Settings.Main.SelectStealName and type(getgenv().Settings.Main.SelectStealName) == "table" and #getgenv().Settings.Main.SelectStealName > 0
                        local activeRarityFilter = getgenv().Settings.Main.SelectStealRarity and type(getgenv().Settings.Main.SelectStealRarity) == "table" and #getgenv().Settings.Main.SelectStealRarity > 0
                        local activeMutationFilter = getgenv().Settings.Main.SelectStealMutation and type(getgenv().Settings.Main.SelectStealMutation) == "table" and #getgenv().Settings.Main.SelectStealMutation > 0

                        local hasActiveFilter = activeNameFilter or activeRarityFilter or activeMutationFilter
                        if not hasActiveFilter then return end
                        
                        -- สุ่มลำดับบ้าน
                        local plotIndices = {1, 2, 3, 4, 5, 6}
                        for idx = #plotIndices, 2, -1 do
                            local j = math.random(1, idx)
                            plotIndices[idx], plotIndices[j] = plotIndices[j], plotIndices[idx]
                        end
                        
                        local totalStealCount = 0
                        local myPlotName = getgenv().Plot
                        if not myPlotName then
                            for _, v in pairs(workspace.Gardens:GetChildren()) do
                                if v:GetAttribute("OwnerUserId") == game.Players.LocalPlayer.UserId then
                                    myPlotName = v.Name
                                    break
                                end
                            end
                        end
                        
                        for _, i in ipairs(plotIndices) do
                            if not getgenv().Settings.Main.AutoStealSelected then return end
                            if workspace:GetAttribute("ActivePhase") ~= "Night" then break end
                            
                            local plotName = "Plot" .. i
                            local garden = workspace.Gardens:FindFirstChild(plotName)
                            if not garden then continue end
                            
                            local ownerId = garden:GetAttribute("OwnerUserId")
                            if not ownerId or ownerId == 0 or ownerId == "" or ownerId == game.Players.LocalPlayer.UserId then continue end
                            
                            -- เช็ค Unlocked ถ้า false = continue ไปบ้านอื่นต่อ
                            local guiPlot = pg:FindFirstChild(plotName)
                            if guiPlot and guiPlot:FindFirstChild("PlayerFrame") then
                                local unlocked = guiPlot.PlayerFrame:FindFirstChild("Unlocked")
                                if unlocked and unlocked.Visible == false then
                                    continue
                                end
                            end
                            
                            local plantsFolder = garden:FindFirstChild("Plants")
                            if not plantsFolder then continue end
                            
                            local validFruits = {}
                            for _, plant in pairs(plantsFolder:GetChildren()) do
                                local seedName = plant:GetAttribute("SeedName")
                                local mutation = plant:GetAttribute("Mutation") or "None"
                                local rarity = SeedRarity[seedName] or "None"
    
                                local matchName = activeNameFilter and table.find(getgenv().Settings.Main.SelectStealName, seedName)
                                local matchRarity = activeRarityFilter and table.find(getgenv().Settings.Main.SelectStealRarity, rarity)
                                local matchMutation = activeMutationFilter and table.find(getgenv().Settings.Main.SelectStealMutation, mutation)
    
                                if matchName or matchRarity or matchMutation then
                                    local fruitsFolder = plant:FindFirstChild("Fruits")
                                    if fruitsFolder then
                                        for _, fruit in pairs(fruitsFolder:GetChildren()) do
                                            local harvestPart = fruit:FindFirstChild("HarvestPart")
                                            if harvestPart then
                                                local prompt = harvestPart:FindFirstChild("StealPrompt")
                                                if prompt and prompt:IsA("ProximityPrompt") then
                                                    table.insert(validFruits, {Fruit = fruit, Prompt = prompt})
                                                end
                                            end
                                        end
                                    end
                                end
                            end

                            if #validFruits > 0 then
                                local targetPos
                                local visual = garden:FindFirstChild("Visual")
                                local prim = visual and visual:FindFirstChild("PRIM")
                                if prim then
                                    targetPos = (prim.CFrame * CFrame.new(0, 25, 0)).Position
                                else
                                    targetPos = (garden:GetPivot() * CFrame.new(0, 25, 0)).Position
                                end
                                
                                local tween = TweenDirect(targetPos, 35)
                                if tween then tween.Completed:Wait() end
                                
                                local character = game.Players.LocalPlayer.Character
                                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                                if hrp then hrp.Velocity = Vector3.zero end

                                local forceBreakPlot = false
                                for idx2, item in ipairs(validFruits) do
                                    if hrp then 
                                        hrp.CFrame = CFrame.new(targetPos)
                                        hrp.Velocity = Vector3.zero 
                                    end
                                    if forceBreakPlot then break end
                                    
                                    -- เช็คบ้านล็อคระหว่างทำ
                                    if guiPlot and guiPlot:FindFirstChild("PlayerFrame") then
                                        local unlocked = guiPlot.PlayerFrame:FindFirstChild("Unlocked")
                                        if unlocked and unlocked.Visible == false then
                                            forceBreakPlot = true
                                            break
                                        end
                                    end
                                    
                                    local fruit = item.Fruit
                                    local prompt = item.Prompt
                                    
                                    if fruit and fruit:IsDescendantOf(workspace) then
                                        local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
                                        local userId = tonumber(fruit:GetAttribute("UserId"))
                                        local plantId = fruit:GetAttribute("PlantId")
                                        local fruitId = fruit:GetAttribute("FruitId")
                                        
                                        if userId and plantId then
                                            Networking.Steal.BeginSteal:Fire(userId, plantId, fruitId or "")
                                            Networking.Steal.CompleteSteal:Fire()
                                        end
                                        task.wait(0.05)
                                        
                                        if not getgenv().Settings.Main.AutoStealSelected then
                                            return
                                        end
                                        
                                        totalStealCount = totalStealCount + 1
                                    end
                                end
                            end
                        end
                        
                        -- กลับบ้านหลังจากวนครบทุกบ้านแล้ว
                        if totalStealCount > 0 and myPlotName then
                            local myGarden = workspace.Gardens:FindFirstChild(myPlotName)
                            if myGarden then
                                local myVisual = myGarden:FindFirstChild("Visual")
                                local myPrim = myVisual and myVisual:FindFirstChild("PRIM")
                                local char2 = game.Players.LocalPlayer.Character
                                local hrp2 = char2 and char2:FindFirstChild("HumanoidRootPart")
                                if hrp2 then
                                    local homePos
                                    if myPrim then
                                        homePos = (myPrim.CFrame * CFrame.new(0, 15, 0)).Position
                                    else
                                        homePos = (myGarden:GetPivot() * CFrame.new(0, 15, 0)).Position
                                    end
                                    local tweenHome = TweenDirect(homePos, 35)
                                    if tweenHome then tweenHome.Completed:Wait() end
                                    task.wait()
                                end
                            end
                        end
                    end)
                end
            end)
        end
    end,
})

local StealAll = AutoStealTab:Toggle({
    Title = "Steal All",
    Desc = "Steals every fruit from other plots at night, no filters applied.",
    Value = getgenv().Settings.Main.StealAll,
    Callback = function(e)
        getgenv().Settings.Main.StealAll = e
        SaveSetting()

        if not e then
            local char = game:GetService("Players").LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.Anchored = false
            end
        end

        if e then
            task.spawn(function()
                while getgenv().Settings.Main.StealAll do
                    task.wait()
                    pcall(function()
                        if workspace:GetAttribute("ActivePhase") ~= "Night" then return end
                        
                        local pg = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
                        if not pg then return end
                        
                        -- สุ่มลำดับบ้าน
                        local plotIndices = {1, 2, 3, 4, 5, 6}
                        for idx = #plotIndices, 2, -1 do
                            local j = math.random(1, idx)
                            plotIndices[idx], plotIndices[j] = plotIndices[j], plotIndices[idx]
                        end
                        
                        local totalStealCount = 0
                        local myPlotName = getgenv().Plot
                        if not myPlotName then
                            for _, v in pairs(workspace.Gardens:GetChildren()) do
                                if v:GetAttribute("OwnerUserId") == game.Players.LocalPlayer.UserId then
                                    myPlotName = v.Name
                                    break
                                end
                            end
                        end
                        
                        for _, i in ipairs(plotIndices) do
                            if not getgenv().Settings.Main.StealAll then return end
                            if workspace:GetAttribute("ActivePhase") ~= "Night" then break end
                            
                            local plotName = "Plot" .. i
                            local garden = workspace.Gardens:FindFirstChild(plotName)
                            if not garden then continue end
                            
                            local ownerId = garden:GetAttribute("OwnerUserId")
                            if not ownerId or ownerId == 0 or ownerId == "" or ownerId == game.Players.LocalPlayer.UserId then continue end
                            
                            -- เช็ค Unlocked ถ้า false = continue ไปบ้านอื่นต่อ
                            local guiPlot = pg:FindFirstChild(plotName)
                            if guiPlot and guiPlot:FindFirstChild("PlayerFrame") then
                                local unlocked = guiPlot.PlayerFrame:FindFirstChild("Unlocked")
                                if unlocked and unlocked.Visible == false then
                                    continue
                                end
                            end
                            
                            local plantsFolder = garden:FindFirstChild("Plants")
                            if not plantsFolder then continue end
                            
                            local validFruits = {}
                            for _, plant in pairs(plantsFolder:GetChildren()) do
                                local fruitsFolder = plant:FindFirstChild("Fruits")
                                if fruitsFolder then
                                    for _, fruit in pairs(fruitsFolder:GetChildren()) do
                                        local harvestPart = fruit:FindFirstChild("HarvestPart")
                                        if harvestPart then
                                            local prompt = harvestPart:FindFirstChild("StealPrompt")
                                            if prompt and prompt:IsA("ProximityPrompt") then
                                                table.insert(validFruits, {Fruit = fruit, Prompt = prompt})
                                            end
                                        end
                                    end
                                end
                            end

                            if #validFruits > 0 then
                                local targetPos
                                local visual = garden:FindFirstChild("Visual")
                                local prim = visual and visual:FindFirstChild("PRIM")
                                if prim then
                                    targetPos = (prim.CFrame * CFrame.new(0, 25, 0)).Position
                                else
                                    targetPos = (garden:GetPivot() * CFrame.new(0, 25, 0)).Position
                                end
                                
                                local tween = TweenDirect(targetPos, 35)
                                if tween then tween.Completed:Wait() end
                                
                                local character = game.Players.LocalPlayer.Character
                                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                                if hrp then hrp.Velocity = Vector3.zero end

                                local forceBreakPlot = false
                                for idx2, item in ipairs(validFruits) do
                                    if hrp then 
                                        hrp.CFrame = CFrame.new(targetPos)
                                        hrp.Velocity = Vector3.zero 
                                    end
                                    if forceBreakPlot then break end
                                    
                                    -- เช็คบ้านล็อคระหว่างทำ
                                    if guiPlot and guiPlot:FindFirstChild("PlayerFrame") then
                                        local unlocked = guiPlot.PlayerFrame:FindFirstChild("Unlocked")
                                        if unlocked and unlocked.Visible == false then
                                            forceBreakPlot = true
                                            break
                                        end
                                    end
                                    
                                    local fruit = item.Fruit
                                    local prompt = item.Prompt
                                    
                                    if fruit and fruit:IsDescendantOf(workspace) then
                                        local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
                                        local userId = tonumber(fruit:GetAttribute("UserId"))
                                        local plantId = fruit:GetAttribute("PlantId")
                                        local fruitId = fruit:GetAttribute("FruitId")
                                        
                                        if userId and plantId then
                                            Networking.Steal.BeginSteal:Fire(userId, plantId, fruitId or "")
                                            Networking.Steal.CompleteSteal:Fire()
                                        end
                                        task.wait(0.05)
                                        
                                        if not getgenv().Settings.Main.StealAll then
                                            return
                                        end
                                        
                                        totalStealCount = totalStealCount + 1
                                    end
                                end
                            end
                        end
                        
                        -- กลับบ้านหลังจากวนครบทุกบ้านแล้ว
                        if totalStealCount > 0 and myPlotName then
                            local myGarden = workspace.Gardens:FindFirstChild(myPlotName)
                            if myGarden then
                                local myVisual = myGarden:FindFirstChild("Visual")
                                local myPrim = myVisual and myVisual:FindFirstChild("PRIM")
                                local char2 = game.Players.LocalPlayer.Character
                                local hrp2 = char2 and char2:FindFirstChild("HumanoidRootPart")
                                if hrp2 then
                                    local homePos
                                    if myPrim then
                                        homePos = (myPrim.CFrame * CFrame.new(0, 15, 0)).Position
                                    else
                                        homePos = (myGarden:GetPivot() * CFrame.new(0, 15, 0)).Position
                                    end
                                    local tweenHome = TweenDirect(homePos, 35)
                                    if tweenHome then tweenHome.Completed:Wait() end
                                    task.wait()
                                end
                            end
                        end
                    end)
                end
            end)
        end
    end,
})

local AutoSellTab = Tab:Section({ Title = "tr:AutoSellTab", Icon = "shopping-cart", Opened = true})

local AutoSellDelay = AutoSellTab:Input({
    Title = "tr:AutoSellDelay",
    Desc = "tr:DescAutoSellDelay",
    Value = getgenv().Settings.Main.AutoSellDelay,
    Callback = function(e)
        getgenv().Settings.Main.AutoSellDelay = tonumber(e)
        SaveSetting()
    end,
})

local AutoBargainToggle = AutoSellTab:Toggle({
    Title = "Auto Bargain",
    Desc = "Automatically bargain with Steven before selling all.",
    Value = getgenv().Settings.Main.AutoBargain,
    Callback = function(e)
        getgenv().Settings.Main.AutoBargain = e
        SaveSetting()
    end,
})

local UseDailyDealToggle = AutoSellTab:Toggle({
    Title = "Use Daily Deal",
    Desc = "Use Steven's Daily Deal if available.",
    Value = getgenv().Settings.Main.UseDailyDeal,
    Callback = function(e)
        getgenv().Settings.Main.UseDailyDeal = e
        SaveSetting()
    end,
})

local AutoSellToggle = AutoSellTab:Toggle({
    Title = "tr:AutoSell",
    Desc = "tr:DescAutoSell",
    Value = getgenv().Settings.Main.AutoSell,
    Callback = function(e)
        getgenv().Settings.Main.AutoSell = e
        SaveSetting()

        if e then
            task.spawn(function()
                while getgenv().Settings.Main.AutoSell do
                    task.wait(getgenv().Settings.Main.AutoSellDelay)
                    pcall(function()
                        local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
                        
                        if getgenv().Settings.Main.UseDailyDeal then
                            local dealInfo = Networking.NPCS.CheckDailyDeal:Fire()
                            if dealInfo and dealInfo.Available then
                                Networking.NPCS.UseDailyDealAll:Fire()
                                return
                            end
                        end
                        
                        if getgenv().Settings.Main.AutoBargain then
                            local bid = Networking.NPCS.AskBidAll:Fire()
                            if bid and bid.Success then
                                task.wait(0.5)
                            end
                        end
                        
                        Networking.NPCS.SellAll:Fire()
                    end)
                end
            end)
        end
    end,
})

local AutoSellFullToggle = AutoSellTab:Toggle({
    Title = "tr:AutoSellFull",
    Desc = "tr:DescAutoSellFull",
    Value = getgenv().Settings.Main.AutoSellFull,
    Callback = function(e)
        getgenv().Settings.Main.AutoSellFull = e
        SaveSetting()

        if e then
            task.spawn(function()
                while getgenv().Settings.Main.AutoSellFull do
                    task.wait(0.5)
                    pcall(function()
                        local player = game:GetService("Players").LocalPlayer
                        local fruitCount = player:GetAttribute("FruitCount")
                        local maxCapacity = player:GetAttribute("MaxFruitCapacity")
                        if fruitCount and maxCapacity and fruitCount >= maxCapacity then
                            local Networking = require(game:GetService("ReplicatedStorage").SharedModules.Networking)
                            
                            if getgenv().Settings.Main.UseDailyDeal then
                                local dealInfo = Networking.NPCS.CheckDailyDeal:Fire()
                                if dealInfo and dealInfo.Available then
                                    Networking.NPCS.UseDailyDealAll:Fire()
                                    return
                                end
                            end
                            
                            if getgenv().Settings.Main.AutoBargain then
                                local bid = Networking.NPCS.AskBidAll:Fire()
                                if bid and bid.Success then
                                    task.wait(0.5)
                                end
                            end
                            
                            Networking.NPCS.SellAll:Fire()
                        end
                    end)
                end
            end)
        end
    end,
})

local ShopTab = Window:Tab({
    Title = "tr:ShopTab",
    Icon = "store",
    Opened = false,
})

local SeedShopTab = ShopTab:Section({ Title = "tr:SeedShopTab", Icon = "sprout", Opened = true})

local SelectSeedBuy = SeedShopTab:Dropdown({
    Title = "tr:SelectSeedBuy",
    Desc = "tr:DescSelectSeedBuy",
    Multi = true,
    AllowNone = true,
    Value = getgenv().Settings.Main.SelectSeedBuy,
    Values = ShopSeedsTable,
    Callback = function(e)
        getgenv().Settings.Main.SelectSeedBuy = e
        SaveSetting()
    end,
})

local AutoBuySeedToggle = SeedShopTab:Toggle({
    Title = "tr:AutoBuySeed",
    Desc = "tr:DescAutoBuySeed",
    Value = getgenv().Settings.Main.AutoBuySeed,
    Callback = function(e)
        getgenv().Settings.Main.AutoBuySeed = e
        SaveSetting()

        if e then
            task.spawn(function()
                while getgenv().Settings.Main.AutoBuySeed do
                    task.wait(0.5)
                    pcall(function()
                        local selectedSeeds = getgenv().Settings.Main.SelectSeedBuy
                        if type(selectedSeeds) == "table" then
                            for _, seedName in pairs(selectedSeeds) do
                                for byte = 97, 122 do
                                    local args = {
                                        buffer.fromstring(string.char(byte) .. "\000" .. string.char(#seedName) .. seedName)
                                    }
                                    game:GetService("ReplicatedStorage"):WaitForChild("SharedModules"):WaitForChild("Packet"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
                                end
                            end
                        elseif type(selectedSeeds) == "string" then
                            for byte = 97, 122 do
                                local args = {
                                    buffer.fromstring(string.char(byte) .. "\000" .. string.char(#selectedSeeds) .. selectedSeeds)
                                }
                                game:GetService("ReplicatedStorage"):WaitForChild("SharedModules"):WaitForChild("Packet"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
                            end
                        end
                    end)
                end
            end)
        end
    end,
})

local GearShopTab = ShopTab:Section({ Title = "tr:GearShopTab", Icon = "wrench", Opened = true})

local SelectGearBuy = GearShopTab:Dropdown({
    Title = "tr:SelectGearBuy",
    Desc = "tr:DescSelectGearBuy",
    Multi = true,
    AllowNone = true,
    Value = getgenv().Settings.Main.SelectGearBuy,
    Values = GearNamesTable,
    Callback = function(e)
        getgenv().Settings.Main.SelectGearBuy = e
        SaveSetting()
    end,
})



local AutoBuyGearToggle = GearShopTab:Toggle({
    Title = "tr:AutoBuyGear",
    Desc = "tr:DescAutoBuyGear",
    Value = getgenv().Settings.Main.AutoBuyGear,
    Callback = function(e)
        getgenv().Settings.Main.AutoBuyGear = e
        SaveSetting()

        if e then
            task.spawn(function()
                while getgenv().Settings.Main.AutoBuyGear do
                    task.wait(0.5)
                    pcall(function()
                        local selectedGears = getgenv().Settings.Main.SelectGearBuy
                        if type(selectedGears) == "table" then
                            for _, gearName in pairs(selectedGears) do
                                for byte = 97, 122 do
                                    local args = {
                                        buffer.fromstring(string.char(byte) .. "\000" .. string.char(#gearName) .. gearName)
                                    }
                                    game:GetService("ReplicatedStorage"):WaitForChild("SharedModules"):WaitForChild("Packet"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
                                end
                            end
                        elseif type(selectedGears) == "string" then
                            for byte = 97, 122 do
                                local args = {
                                    buffer.fromstring(string.char(byte) .. "\000" .. string.char(#selectedGears) .. selectedGears)
                                }
                                game:GetService("ReplicatedStorage"):WaitForChild("SharedModules"):WaitForChild("Packet"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
                            end
                        end
                    end)
                end
            end)
        end
    end,
})

local PropShopTab = ShopTab:Section({ Title = "tr:PropShopTab", Icon = "box", Opened = true})

local SelectPropBuy = PropShopTab:Dropdown({
    Title = "tr:SelectPropBuy",
    Desc = "tr:DescSelectPropBuy",
    Multi = true,
    AllowNone = true,
    Value = getgenv().Settings.Main.SelectPropBuy,
    Values = PropNamesTable,
    Callback = function(e)
        getgenv().Settings.Main.SelectPropBuy = e
        SaveSetting()
    end,
})

local AutoBuyPropToggle = PropShopTab:Toggle({
    Title = "tr:AutoBuyProp",
    Desc = "tr:DescAutoBuyProp",
    Value = getgenv().Settings.Main.AutoBuyProp,
    Callback = function(e)
        getgenv().Settings.Main.AutoBuyProp = e
        SaveSetting()

        if e then
            task.spawn(function()
                while getgenv().Settings.Main.AutoBuyProp do
                    task.wait(0.5)
                    pcall(function()
                        local selectedProps = getgenv().Settings.Main.SelectPropBuy
                        if type(selectedProps) == "table" then
                            for _, propName in pairs(selectedProps) do
                                for byte = 97, 122 do
                                    local args = {
                                        buffer.fromstring(string.char(byte) .. "\000" .. string.char(#propName) .. propName)
                                    }
                                    game:GetService("ReplicatedStorage"):WaitForChild("SharedModules"):WaitForChild("Packet"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
                                end
                            end
                        elseif type(selectedProps) == "string" then
                            for byte = 97, 122 do
                                local args = {
                                    buffer.fromstring(string.char(byte) .. "\000" .. string.char(#selectedProps) .. selectedProps)
                                }
                                game:GetService("ReplicatedStorage"):WaitForChild("SharedModules"):WaitForChild("Packet"):WaitForChild("RemoteEvent"):FireServer(unpack(args))
                            end
                        end
                    end)
                end
            end)
        end
    end,
})

---- ============ Configuration ============ ----

Window:Divider()

local Tab = Window:Tab({
    Title = "tr:Configuration",
    Icon = "settings",
    Locked = false,
})

local Interface = Tab:Section({ Title = "tr:Interface", Icon = "settings-2"})

local themeValues = {}
for name, _ in pairs(WindUI:GetThemes()) do
    table.insert(themeValues, name)
end

local themeDropdown = Tab:Dropdown({
    Title = "tr:themeDropdown",
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

local ToggleTransparency = Tab:Toggle({
    Title = "tr:ToggleTransparency",
    Value = getgenv().ConfigurationTable.Transparent,
    Icon = "check",
    Callback = function(e)
        getgenv().ConfigurationTable.Transparent = e
        SaveConfiguration()
        Window:ToggleTransparency(e)
    end,
    Value = WindUI:GetTransparency()
})

local AntiAFK = Tab:Toggle({
    Title = "tr:AntiAFK",
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

local AutoRejoin = Tab:Toggle({
    Title = "tr:AutoRejoin",
    Value = getgenv().ConfigurationTable.AutoRejoin,
    Icon = "check",
    Callback = function(enabled)
        getgenv().ConfigurationTable.AutoRejoin = enabled
        SaveConfiguration()

        if enabled then
            if not enabled then
                if getgenv().Settings.Automatic.AutoFarm.AutoFarmRock then
                    getgenv().Settings.Automatic.AutoFarm.AutoFarmRock:Disconnect()
                    getgenv().Settings.Automatic.AutoFarm.AutoFarmRock = nil
                end
                return
            end

            if getgenv().Settings.Automatic.AutoFarm.AutoFarmRock then
                return
            end

            getgenv().Settings.Automatic.AutoFarm.AutoFarmRock = game.CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
                if child.Name == "ErrorPrompt" then
                    game:GetService("TeleportService"):Teleport(game.PlaceId, game:GetService("Players").LocalPlayer)
                end
            end)
        end
    end
})

local AutoExecutor = Tab:Toggle({
    Title = "tr:AutoExecutor",
    Value = getgenv().ConfigurationTable.AutoExecutor,
    Icon = "check",
    Callback = function(Value)
        getgenv().ConfigurationTable.AutoExecutor = Value
        SaveConfiguration()
    end
})

local MinimizeBind = Tab:Keybind({
    Title = "tr:MinimizeBind",
    Value = getgenv().ConfigurationTable.MinimizeBind,
    Callback = function(v)
        getgenv().ConfigurationTable.MinimizeBind = v
        SaveConfiguration()
        Window:SetToggleKey(Enum.KeyCode[v])
    end
})

local FPSIS = Tab:Section({ Title = "tr:FPSIS", Icon = "gamepad"})

local FPSVALUE = Tab:Slider({
    Title = "tr:FPSVALUE",
    Value = {
        Min = 1,
        Max = 240,
        Default = getgenv().ConfigurationTable.FPSValue
    },
    Callback = function(Value)
        getgenv().ConfigurationTable.FPSValue = Value
        SaveConfiguration()
    end
})

local FPSLOCK = Tab:Toggle({
    Title = "tr:FPSLOCK",
    Default = getgenv().ConfigurationTable.LockFPS,
    Icon = "check",
    Callback = function(v)
        getgenv().ConfigurationTable.LockFPS = v
        SaveConfiguration()

        if v then
            task.spawn(function()
                pcall(function()
                    while getgenv().ConfigurationTable.LockFPS do task.wait()
                        if getgenv().ConfigurationTable.LockFPS then
                            setfpscap(tonumber(getgenv().ConfigurationTable.FPSValue))
                        else
                            setfpscap(240)
                        end
                    end
                end)
            end)
        end
    end
})

local WhiteScreen = Tab:Toggle({
    Title = "tr:WhiteScreen",
    Default = getgenv().ConfigurationTable.WhileScreen,
    Icon = "check",
    Callback = function(v)
        getgenv().ConfigurationTable.WhileScreen = v
        SaveConfiguration()

        local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        local screenGui = playerGui:FindFirstChild("Venuz_White")

        if v then
            if not screenGui then
                screenGui = Instance.new("ScreenGui")
                screenGui.Name = "Venuz_White"
                screenGui.Enabled = true
                screenGui.IgnoreGuiInset = true
                screenGui.Parent = playerGui

                local frame = Instance.new("Frame")
                frame.Name = "Venuz_1"
                frame.Position = UDim2.new(0,0,0,0)
                frame.Size = UDim2.new(1,0,1,0)
                frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                frame.Parent = screenGui
            else
                screenGui.Enabled = true
            end
        else
            if screenGui then
                screenGui.Enabled = false
            end
        end
    end
})

local LanguageTab =  Tab:Section({ Title = "tr:LanguageTab", Icon = "languages"})

local Language = Tab:Dropdown({
    Title = "tr:Language",
    Multi = false,
    AllowNone = false,
    Values = {"English (US)","Thai"},
    Value = getgenv().ConfigurationTable.Language,
    Callback = function(Callback)
        getgenv().ConfigurationTable.Language = Callback
        SaveConfiguration()
    end
})

local ChangedLanguage = Tab:Button({
    Title = "tr:ChangedLanguage",
    Callback = function()
        if getgenv().ConfigurationTable.Language == "English (US)" then
            WindUI:SetLanguage("English (US)")
        else
            WindUI:SetLanguage("Thai")
        end
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

local RunService = game:GetService("RunService")
RunService.RenderStepped:Connect(function()
    local isActive = getgenv().Settings.Main.AutoStealSelected or getgenv().Settings.Main.StealAll or getgenv().Settings.Main.AutoHarvestSelected or getgenv().Settings.Main.HarvestAll

    if not isActive then
        local existingFooter = workspace:FindFirstChild("Venuz_Footer")
        if existingFooter then
            existingFooter:Destroy()
        end
        return
    end

    local plr = game.Players.LocalPlayer
    local char = plr.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")

    if not hrp or not hum or hum.Health <= 0 then
        return
    end

    local footer = workspace:FindFirstChild("Venuz_Footer")
    if not footer then
        footer = Instance.new("Part")
        footer.Name = "Venuz_Footer"
        footer.Parent = workspace
        footer.Size = Vector3.new(2, 0.2, 1.5)
        footer.Transparency = 1
        footer.Anchored = true
        footer.CanCollide = true
    end

    footer.CFrame = hrp.CFrame * CFrame.new(0, -3.1, 0)
end)

WindUI:Notify({
    Title = "tr:ScriptLoader",
    Content = "tr:ScriptLoaded",
    Icon = VenuzIcon,
    Duration = 5,
})