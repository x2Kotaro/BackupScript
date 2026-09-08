pcall(function()
    if game:GetService("CoreGui"):FindFirstChild("Folder"):FindFirstChild("WindUI") then
        return
    end
end)


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

local filenameConfiguration = FolderConfiguration .. "/" .. "Setting.json"
local filenameSetting = FolderSettings .. "/" .. "GameConfig_".. LocalPlayer.Name ..".json"

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
    ["Automatic"] = {
        ["AutoCollect"] = {
            ["AutoCollect"] = false,
            ["AutoCollectDelay"] = 20,
        },
        ["AutoCollectPet"] = {
            ["Eard1"] = 0,
            ["Eard2"] = 0
        },
        ["AutoBuyEggs"] = {
            ["SelectEgg"] = {},
            ["SelectEggsWithMutation"] = {},
            ["AutoBuyEgg"] = false,
            ["AutoBuyEggwithmutation"] = false,
            ["AutoBuyEggwithEventSnow"] = false,
            ["infactionSnow"] = false,
            ["SelectEventSnow"] = {},
        },
        ["AutoPlace"] = {
            ["SelectEgg"] = {},
            ["AutoEquipEgg"] = false,
            ["AutoPlacePet"] = false,
            ["AutoPlaceOcean"] = false,
            ["AutoHatch"] = false,
            ["AutoPlaceOceanElite"] = false,
            ["AutoPlacePetElite"] = false,
        },
        ["Fish"] = {
            ["SelectBait"] = nil,
            ["AutoFish"] = false,
        },
        ["Feed"] = {
            ["SelectFruit"] = nil,
            ["AutoEquip"] = false,
            ["Mutation"] = {},
            ["AutoFeed"] = false,
            ["SelectPet"] = {},
        },
    },

    ["Purchase"] = {
        ["Food"] = {
            ["Foods"] = {},
            ["AutoBuyFoods"] = false,
        }
    },

    ["Utility"] = {
        ["Event"] = {
            ["AutoClaimQuest"] = false,
            ["AutoClaimEgg"] = false,
        },
        ["Gift"] = {
            ["Teleport"] = nil,
        },
        ["Webhook"] = {
            ["WebhookUrl"] = "",
            ["Ping"] = false,
            ["AutoBuyEgg"] = false,
            ["AutoBuyFood"] = false,
        },
        ["Misc"] = {
        ["DisableAnimationPet"] = false,
        ["DisableEffectGetMoney"] = false,
        ["AutoLikeHopServer"] = false,
        ["DelayAutoLike"] = 15,
        ["SelectPlayers"] = {},
        ["AutoLike"] = false,
        ["DelayAutoLikeAFK"] = 30,
        ["AdventCalender"] = false,
        ["AutoSeasonPass"] = false,
        },
        ["Premium"] = {
            ["PositionFish"] = nil,
            ["SelectBait"] = nil,
            ["AutoFish"] = false,
            ["AutoSellEgg"] = false,
            ["SelectEgg"] = {},
            ["SelectMutation"] = {},
            ["HopServer"] = false,
            ["HopServerEvent"] = false,
            ["HopServerList"] = "Snow",
            ["Method"] = "Status",
            ["AutoTrade"] = false,
            ["MinEarns"] = 0,
            ["MaxEarns"] = 0,
            ["AutoClaimKitsune"] = false,
            ["AutoPlacePetBest"] = false,
            ["AutoPlaceOceanBest"] = false,
            ["MinValue"] = 0,
            ["MaxValue"] = 0,
            ["AutoEquipTrade"] = false,
            ["AutoReplacePet"] = false,
            ["AutoReplaceElite"] = false,
            ["AutoReplaceFish"] = false,
            ["SelectRarity"] = "Common",
            ["IncomeMin"] = 0,
            ["IncomeMax"] = 100,
            ["AutoFarmPet"] = false,
        },
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

---- ============ CheckRole ============ ----

local KeyFile = "Venuz Hub/KeySystem".."/".."VenuzKey"..".txt"
local api = loadstring(game:HttpGet("https://sdkapi-public.luarmor.net/library.lua"))()
api.script_id = "274209c355e95ffe3ba729826b475b88"

local status = api.check_key(readfile(KeyFile))

if status.code == "KEY_VALID" then
    if status.data.note == "Premium" then
        getgenv().Premium = false
        getgenv().IsPremium = "Premium Access"
    else
        getgenv().Premium = true
        getgenv().IsPremium = "Standard"
    end
end

---- ============ Interface ============ ----

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
            -- Tabs --
            ["Feed"] = "ให้อาหารสัตว์ออโต้",
            ["PremiumTab"] = "พรีเมี่ยม",
            ["MiscTab"] = "อื่นๆ",
            ["WebhookTab"] = "เว็บฮุก",
            ["GiftTab"] = "เทรดของ",
            ["Extras"] = "ส่วนเสริม",
            ["Food"] = "อาหาร",
            ["Purchase"] = "การซื้อ",
            ["Info"] = "ข้อมูล",
            ["Automatic"] = "อัตโนมัติ",
            ["AutoCollect"] = "เก็บเงินและสัตว์",
            ["Eggs"] = "ซื้อไข่ออโต้",
            ["Place"] = "วางกับเปิดไข่ออโต้",
            ["Shop"] = "ร้านค้า",
            ["Feed"] = "ให้อาหารสัตว์ใหญ่ออโต้",
            ["Quest"] = "รับเควสออโต้",
            ["Fish"] = "ตกปลาออโต้",
            ["Gift"] = "ให้ของออโต้",
            ["Webhook"] = "เว็บฮุก",
            ["Misc"] = "อื่นๆ",
            ["Premium"] = "พรีเมี่ยม",
            ["Configuration"] = "การตั้งค่า",
            -- Tsunami --
            ["TsunamiTab"] = "สึนามิ",
            ["SelectRarity"] = "เลือกความหายาก",
            ["IncomeMin"] = "รายได้ขั้นต่ำ",
            ["IncomeMax"] = "รายได้สูงสุด",
            ["AutoFarmPet"] = "ฟาร์มสัตว์ออโต้",
            --Info
            ["Info"] = "แนะนำค่าย Venuz Hub",
            ["InfoDesc"] = "ยินดีต้อนรับเข้าสู่ Venuz Hub\nขอบคุณที่เลือกใช้ค่ายโปรของเรา!",
            ["dc"] = "เข้าร่วมเซิฟเวอร์ดิสคอด!!!",
            ["dcdesc"] = "คลิกที่นี่เพื่อเข้าดิสคอดของเรา",
            -- Automatic --
             -- Auto Collect --
             ["AutoCollectTab"] = "เก็บเงินออโต้",
             ["AutoCollect"] = "เก็บเงินออโต้",
             ["AutoCollectDesc"] = "เก็บเงินอัตโนมัติในบ้านของคุณ",
             ["DelayCollect"] = "ดีเลย์เก็บเงินต่อรอบ",
             -- Quick --
             ["QuickTab"] = "ทันที",
             ["QuickCollect"] = "เก็บเงินทันที",
             ["QuickCollectDesc"] = "จะเก็บเงินให้คุณรอบเดียวทันทีตอนกด",
             -- Auto Collect Pet --
             ["CollectPet"] = "เก็บสัตว์ออโต้",
             ["AutoPetEard1"] = "ค่าเงินต่ำที่สุด",
             ["AutoPetEard2"] = "ค่าเงินที่สูงที่สุด",
             ["CollectAllPetEarn"] = "เก็บสัตว์ตามจำนวนค่าเงิน",
             ["CollectAllPet"] = "เก็บสัตว์ขึ้นมาทั้งหมด",
             -- AutoBuyEggs --
             ["AutoBuyEggTab"] = "ซื้อไข่ออโต้",
             ["SelectEggs"] = "เลือกไข่",
             ["AutoBuyEgg"] = "ซื้อไข่ออโต้",
             ["AutoBuyEggDesc"] = "ซื้อไข่ที่เลือกคุณเลือกเอาไว้เมื่อไข่มาบนสายพาน",
             ["AutoBuyEggwithmutationTab"] = "ซื้อไข่ออโต้แบบติดกลายพันธ์",
             ["SelectEggsWith"] = "เลือกไข่",
             ["SelectMutation"] = "เลือกกลายพันธ์",
             ["AutoBuyEggwithmutation"] = "ซื้อไข่แบบติดกลายพันธ์ออโต้",
             ["AutoBuyEggwithmutationDesc"] = "ซื้อไข่ติดกลายพันธ์ที่คุณเลือกเอาไว้",
             ["AutoBuyEggwithEventSnowTab"] = "ซื้อไข่ออโต้อีเว้น",
             ["SelectEggevent"] = "เลือกไข่",
             ["SnowMutatuion"] = "เลือกกลายพันธ์",
             ["AutoBuyEggwithEventSnow"] = "ซื้อไข่ออโต้แบบติดอีเว้น",
             ["AutoBuyEggwithEventSnowDesc"] = "ซื้อไข่ที่คุณเลือกเอาไว้",
             -- AutoPlace --
             ["AutoEquipEggTabs"] = "ถือไข่หรือสัตว์ออโต้",
             ["SelectEggPlace"] = "เลือกไข่หรือสัตว์",
             ["Refresh"] = "รีเฟรช",
             ["AutoEquipEgg"] = "ถือไข่หรือสัตว์ออโต้",
             ["AutoEquipEggDesc"] = "ถือไข่หรือสัตว์ที่คุณเลือกออโต้",
             ["AutoPlaceTab"] = "วางออโต้",
             ["AutoPlacePet"] = "วางไข่หรือสัตว์ออโต้",
             ["AutoPlaceOcean"] = "วางไข่หรือปลาออโต้",
             ["AutoHatchTab"] = "เปิดไข่ออโต้",
             ["AutoHatch"] = "เปิดไข่ออโต้",
             ["AutoPlacePetElite"] = "วางสัตว์ระดับ Elite ออโต้",
             -- Auto Feed --
            ["AutoEquipFruit"] = "สวมใส่อาหารออโต้",
            ["SelectFruit"] = "เลือกอาหาร",
            ["AutoEquip"] = "สวมใส่อาหารออโต้",
            ["AutoFeedTab"] = "ให้อาหารออโต้",
            ["SettingsFeedTab"] = "ตั้งค่าไม่ให้อาหาร",
            ["SelectPet"] = "เลือกสัตว์ใหญ่",
            ["AutoFeed"] = "ให้อาหารสัตว์ใหญ่ออโต้",
            ["AutoFeedDesc"] = "ให้อาหารสัตว์ใหญ่ของคุณออโต้",
             -- Fish --
             ["FishTab"] = "ตกปลาออโต้",
             ["SelectBaitNormal"] = "เลือกเหยื่อ",
             ["AutoFish"] = "ตกปลาออโต้",
            -- Purchase --
             -- Food --
             ["FruitTab"] = "อาหาร",
             ["SelectFruitShop"] = "เลือกอาหารที่จะซื้อ",
             ["AutoBuyFruits"] = "ซื้ออาหารออโต้",
             ["AutoBuyFruitsDesc"] = "ซื้ออาหารออโต้ที่คุณเลือกเอาไว้",
            -- Utility --
             -- Event --
             ["QuestTab"] = "อีเว้น",
             ["AutoClaimQuest"] = "รับเควสออโต้",
             ["AutoClaimEgg"] = "รับไข่ออโต้",
             -- Gfit --
             ["SelectTypeGift"] = "เลือกชนิดของที่จะให้",
             ["SelectItem"] = "เลือกไอเท็มที่จะให้",
             ["SelectPlayer"] = "เลือกผู้เล่น",
             ["GiftAmount"] = "จำนวน",
             ["StartGift"] = "เริ่มให้ของ",
             ["GiftTeleport"] = "วาป",
             -- Webhook --
             ["TabsWebhook"] = "เว็บฮุก",
             ["WebhookUrl"] = "URL เว็บฮุก",
             ["WebhookPing"] = "แท็กเมื่อส่งเว็บฮุก",
             ["TestWebhook"] = "ทดสอบเว็บฮุก",
             ["EggTabsWebhook"] = "ไข่และอาหาร",
             ["CheckAllEgg"] = "เช็คไข่ทั้งหมดในตัว",
             ["CheckAllFood"] = "เช็คอาหารทั้งหมดในตัว",
             ["AutoBuyEggNotify"] = "แจ้งเตือนเมื่อซื้อไข่ออโต้",
             ["AutoBuyFoodNotify"] = "แจ้งเตือนเมื่อซื้ออาหารออโต้",
             -- Misc --
             ["MiscTabs"] = "อื่นๆ",
             ["DisableAnimation"] = "ปิดใช้งานอนิเมชั่น (สัตว์)",
             ["DisableMoney"] = "ปิดใช้งานเอฟเฟค เก็บเงิน",
             ["LikeTabs"] = "กดไลค์ออโต้ (อีเว้น)",
             ["AutolikeServerHop"] = "กดไลค์ออโต้ (ย้ายเซิฟ)",
             ["DelayAutoLike"] = "ล่าช้า",
             ["AutoLikeTabs1"] = "กดไลค์ออโต้ (AFK)",
             ["SelectPlayers_AutoLike"] = "เลือกผู้เล่น",
             ["AutolikeAFK"] = "กดไลค์ออโต้ (AFK)",
             ["AutolikeDelay"] = "ล่าช้า",
             ["RedeemAllCodes"] = "ใส่โค้ดทั้งหมดในเกม",
             ["UnlockBigPet2"] = "ปลดล็อคสัตว์ใหญ่ตัวที่ 2 (เสี่ยง)",
             ["AdventCalender"] = "รับของปฏิทินคริสต์มาสออโต้",
             ["SeasonPass"] = "รับของซีซันพาสออโต้",
            -- Premium --
            ["FishPosition"] = "ตำแหน่งตกปลา",
            ["PositionFish"] = "ตำแหน่ง",
            ["SavePosition"] = "เซฟ ตำแหน่ง",
            ["SelectBait"] = "เลือกเหยื่อ",
            ["AutoFishPremiumTabs"] = "ตกปลา",
            ["AutoFishPremium"] = "ตกปลาออโต้ (เฉพาะตอนอีเว้นมา)",
            ["ServerHopFindEvent"] = "ย้านเซิฟหาอีเว้น",
            ["AutoSellEggTab"] = "ขายไข่ออโต้",
            ["SelectEggAutoSell"] = "เลือกไข่ที่จะขาย",
            ["SelectMutationAutoSell"] = "เลือกกลายพันธ์ที่จะขาย",
            ["AutoSellEgg"] = "ขายไข่ออโต้",
            ["Weather"] = "สภาพอากาศ",
            ["InfoWeather"] = "ข้อมูล",
            ["InfoWeatherDesc"] = "ไม่มี ข้อมูล",
            ["ServerHopFindEventSnow"] = "เลือก อีเว้น",
            ["ServerHopFindEventHalloween"] = "ย้ายหาเซิฟที่มีอีเว้น",
            ["TradeSection"] = "เทรด",
            ["ShowStatus"] = "สถานะ",
            ["ShowStatusDesc"] = "สถานะปัจจุบัน",
            ["Method"] = "วิธีการทำงาน",
            ["AutoTrade"] = "เทรดออโต้",
            ["MaxEarns"] = "เงินเยอะที่สุด",
            ["MinEarns"] = "เงินต่ำสุด",
            ["KitsuneTabs"] = "หาจิ้งจอกออโต้",
            ["AutoClaimKitsune"] = "รับจิ้งจอกออโต้",
            ["PlaceBest"] = "วางสัตว์ที่ดีที่สุด",
            ["AutoPlacePetBest"] = "วางสัตว์ที่ดีที่สุดออโต้",
            ["AutoPlaceOceanBest"] = "วางปลาที่ดีที่สุดออโต้",
            ["AutoEquipTrade"] = "ถือสัตว์ออโต้",
            ["MinValue"] = "เงินต่ำสุด",
            ["MaxValue"] = "เงินเยอะที่สุด",
            ["AutoEquipPet"] = "สวมใส่สัตว์ออโต้",
            ["ReplaceBest"] = "เปลี่ยนสัตว์ที่ดีที่สุดออโต้",
            ["AutoReplacePet"] = "เปลี่ยนสัตว์ออโต้",
            ["AutoReplaceElite"] = "เปลี่ยนสัตว์ระดับ Elite ออโต้",
            ["AutoReplaceFish"] = "เปลี่ยนปลาที่ดีที่สุดออโต้",
            -- Settings
            ["Interface"] = "การตั้งค่า",
            ["themeDropdown"] = "เลือก ธีม",
            ["ToggleTransparency"] = "UI โปรพื้นหลังโปร่งใส่",
            ["AntiAFK"] = "ป้องกันหลุดออกจากเกม (Anti-AFK)",
            ["AutoRejoin"] = "เข้าร่วมเกมอัตโนมัติเมื่อหลุด (AutoRejoin)",
            ["AutoExecutor"] = "รันโปรออโต้เมื่อย้ายเซิฟ (AutoExecutor)",
            ["MinimizeBind"] = "ปุ่มที่จะใช้เปิดปิดโปร",
            ["FPSIS"] = "FPS",
            ["FPSVALUE"] = "FPS",
            ["FPSLOCK"] = "ล็อค FPS",
            ["WhiteScreen"] = "จอขาว",
            ["LanguageTab"] = "ภาษา",
            ["Language"] = "เลือกภาษา",
            ["ChangedLanguage"] = "เปลี่ยนภาษา",
        },
        ["English (US)"] = {
            -- Tabs --
            ["Feed"] = "Auto Feed",
            ["PremiumTab"] = "Premium",
            ["MiscTab"] = "Misc",
            ["WebhookTab"] = "Webhook",
            ["GiftTab"] = "Gift",
            ["Extras"] = "Extras",
            ["Food"] = "Food",
            ["Purchase"] = "Purchase",
            ["Info"] = "Info",
            ["Automatic"] = "Automatic",
            ["AutoCollectTab"] = "Auto Collect",
            ["Eggs"] = "Auto BuyEggs",
            ["Place"] = "Auto Place & Hatch",
            ["Shop"] = "Shop",
            ["Feed"] = "Auto Feed",
            ["Quest"] = "Quest",
            ["Fish"] = "Fish",
            ["Gift"] = "Gift",
            ["Webhook"] = "Webhook",
            ["Misc"] = "Misc",
            ["Premium"] = "Premium",
            ["Configuration"] = "Configuration",
            -- Tsunami --
            ["TsunamiTab"] = "Tsunami",
            ["SelectRarity"] = "Select Rarity",
            ["IncomeMin"] = "Income Min",
            ["IncomeMax"] = "Income Max",
            ["AutoFarmPet"] = "Auto Farm Pet",
            --Info
            ["Info"] = "Info Venuz Hub",
            ["InfoDesc"] = "Welcome To Venuz Hub\nThank you for choosing Venuz Hub!",
            ["dc"] = "Join Server Discord!!!",
            ["dcdesc"] = "Click link to join server discord",
            -- Automatic --
             -- Auto Collect --
             ["AutoCollectTab"] = "Auto Collect",
             ["AutoCollect"] = "Auto Collect Money",
             ["AutoCollectDesc"] = "automatic collect coin in your home.",
             ["DelayCollect"] = "Delay",
             -- Quick --
             ["QuickTab"] = "Quick",
             ["QuickCollect"] = "Quick Collect Money",
             ["QuickCollectDesc"] = "It will collect money you once immediately when you press it.",
             -- Auto Collect Pet --
             ["CollectPet"] = "Auto Collect Pets",
             ["AutoPetEard1"] = "Min Earnings",
             ["AutoPetEard2"] = "Max Earnings",
             ["CollectAllPetEarn"] = "Collect Pets by Earnings",
             ["CollectAllPet"] = "Collect All Pets",
             -- AutoBuyEggs --
             ["AutoBuyEggTab"] = "Auto Buy Eggs",
             ["AutoBuyEggTab"] = "Auto Buy Egg",
             ["SelectEggs"] = "Select Eggs",
             ["AutoBuyEgg"] = "Auto Buy Egg",
             ["AutoBuyEggDesc"] = "Automatically buys the eggs you selected when they appear on the conveyor belt.",
             ["AutoBuyEggwithmutationTab"] = "Auto Buy Eggs with mutation",
             ["SelectEggsWith"] = "Select Eggs",
             ["SelectMutation"] = "Select Mutation",
             ["AutoBuyEggwithmutation"] = "Auto Buy Mutated Egg",
             ["AutoBuyEggwithmutationDesc"] = "Automatically buys the mutated eggs you selected.",
             ["SelectEggevent"] = "Select Event Egg",
             ["SnowMutatuion"] = "Select Mutation",
             ["AutoBuyEggwithEventSnow"] = "Auto Buy Event Egg",
             ["AutoBuyEggwithEventSnowDesc"] = "Buys the eggs you selected.",
             -- AutoPlace --
             ["AutoEquipEggTabs"] = "Auto Equip Egg or Pet",
             ["SelectEggPlace"] = "Select Egg or Pet",
             ["Refresh"] = "Refresh",
             ["AutoEquipEgg"] = "Auto Equip Egg or Pet",
             ["AutoEquipEggDesc"] = "Automatically equips the egg or pet you selected.",
             ["AutoPlaceTab"] = "Auto Place",
             ["AutoPlacePet"] = "Auto Place Egg or Pet",
             ["AutoPlaceOcean"] = "Auto Place Egg or Fish",
             ["AutoHatchTab"] = "Auto Hatch",
             ["AutoHatch"] = "Auto Hatch",
             ["AutoPlacePetElite"] = "Auto Place Elite Pet",
             -- Auto Feed --
             ["AutoEquipFruit"] = "Auto Equip Food",
             ["SelectFruit"] = "Select Food",
             ["AutoEquip"] = "Auto Equip",
             ["AutoFeedTab"] = "Auto Feed",
             ["SettingsFeedTab"] = "Do Not Feed",
             ["SelectPet"] = "Select Big Pet",
             ["AutoFeed"] = "Auto Feed",
             ["AutoFeedDesc"] = "Automatic Feed your big pets.",
             -- Fish --
             ["FishTab"] = "Auto Fishing",
             ["SelectBaitNormal"] = "Select Bait",
             ["AutoFish"] = "Auto Fish",
            -- Purchase --
             -- Food --
             ["FruitTab"] = "Food",
             ["SelectFruitShop"] = "Select Food to Buy",
             ["AutoBuyFruits"] = "Auto Buy Food",
             ["AutoBuyFruitsDesc"] = "Automatically buys the food you selected.",
            -- Utility --
             -- Event --
             ["QuestTab"] = "Event",
             ["AutoClaimQuest"] = "Auto Claim Quest",
             ["AutoClaimEgg"] = "Auto Claim Egg",
             -- Gfit --
             ["SelectTypeGift"] = "Select type",
             ["SelectItem"] = "Select the item",
             ["SelectPlayer"] = "Select player",
             ["GiftAmount"] = "Amount",
             ["StartGift"] = "Send Gift",
             ["GiftTeleport"] = "Teleport",
             -- Webhook --
            ["TabsWebhook"] = "Webhook",
            ["WebhookUrl"] = "Webhook URL",
            ["WebhookPing"] = "Ping when sending webhook",
            ["TestWebhook"] = "Test Webhook",
            ["EggTabsWebhook"] = "Eggs & Food",
            ["CheckAllEgg"] = "Check all eggs in inventory",
            ["CheckAllFood"] = "Check all food in inventory",
            ["AutoBuyEggNotify"] = "Auto Buy Egg Notify",
            ["AutoBuyFoodNotify"] = "Auto Buy Food Notify",
            -- Misc --
            ["MiscTabs"] = "Misc",
            ["DisableAnimation"] = "Disable Animation (Pet)",
            ["DisableMoney"] = "Disable Effect (Get Money)",
            ["LikeTabs"] = "Auto Like (Event)",
            ["AutolikeServerHop"] = "Auto Like (HopServer)",
            ["DelayAutoLike"] = "Delay",
            ["AutoLikeTabs1"] = "Auto Like (AFK)",
            ["SelectPlayers_AutoLike"] = "Select Players",
            ["AutolikeAFK"] = "Auto Like (AFK)",
            ["AutolikeDelay"] = "Delay",
            ["UnlockBigPet2"] = "Unlock Big Pet 2 (risky)",
            ["AdventCalender"] = "Auto Claim Advent Calender",
            ["SeasonPass"] = "Auto Claim Season Pass",
            -- Premium --
            ["FishPosition"] = "Fish Position",
            ["PositionFish"] = "Position",
            ["SavePosition"] = "Save Position",
            ["SelectBait"] = "Select Bait",
            ["AutoFishPremiumTabs"] = "Auto Fish",
            ["AutoFishPremium"] = "Auto Fish (Event Only)",
            ["ServerHopFindEvent"] = "Server Hop Find Event",
            ["AutoSellEggTab"] = "Auto Sell Egg",
            ["SelectEggAutoSell"] = "Select Eggs",
            ["SelectMutationAutoSell"] = "Select Mutations",
            ["AutoSellEgg"] = "Auto Sell Egg",
            ["Weather"] = "Weather",
            ["InfoWeather"] = "Info",
            ["InfoWeatherDesc"] = "No Information",
            ["ServerHopFindEventSnow"] = "Select Event",
            ["ServerHopFindEventHalloween"] = "Server Hop Find Event",
            ["TradeSection"] = "Trade",
            ["ShowStatus"] = "Status",
            ["ShowStatusDesc"] = "Current Status",
            ["Method"] = "Method",
            ["AutoTrade"] = "Auto Trade",
            ["MinEarns"] = "Min Earnings",
            ["MaxEarns"] = "Max Earnings",
            ["KitsuneTabs"] = "Auto Find Kitsune",
            ["AutoClaimKitsune"] = "Auto Claim Kitsune",
            ["PlaceBest"] = "Auto Place Best Pet",
            ["AutoPlacePetBest"] = "Auto Place Best Pet",
            ["AutoPlaceOceanBest"] = "Auto Place Best Fish",
            ["RedeemAllCodes"] = "Redeem All Codes",
            ["AutoEquipTrade"] = "Auto Equip Trade Pet",
            ["MinValue"] = "Earn/s Min",
            ["MaxValue"] = "Earn/s Max",
            ["AutoEquipPet"] = "Auto Equip Pet",
            ["ReplaceBest"] = "Auto Replace Best Pet",
            ["AutoReplacePet"] = "Auto Replace Pet",
            ["AutoReplaceElite"] = "Auto Replace Elite Pet",
            ["AutoReplaceFish"] = "Auto Replace Fish",
            -- Settings
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
            ["LanguageTab"] = "LanguageTab",
            ["Language"] = "Select Language",
            ["ChangedLanguage"] = "Change Language",
        },
    }
})

local CurrentLanguage = getgenv().ConfigurationTable.Language

if CurrentLanguage == "English (US)" then
    WindUI:SetLanguage("English (US)")
else
    WindUI:SetLanguage("Thai")
end

local Window = WindUI:CreateWindow({
    Title = "Venuz Hub",
    Icon = VenuzIcon,
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
    Title = getgenv().IsPremium,
    Color = Color3.fromHex("#30ff6a"),
    Radius = 13,
})

Window:Tag({
    Title = "Update Latest 2/21/2025",
    Color = Color3.fromHex("#f4fc02"),
    Radius = 13,
})

Window:EditOpenButton({
    Title = "Venuz Hub",
    Icon = VenuzIcon,
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

---- ============ Optimize ============ ----

local myIsland

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

for i,v in pairs(workspace.Art[getgenv().MyIsland].ENV.Conveyor:GetChildren()) do
    if v:IsA("Model") then
        getgenv().Conveyor = v.Name
    end
end

workspace.Art[getgenv().MyIsland].ENV.Conveyor.ChildRemoved:Connect(function(child)
	getgenv().Conveyor = child.Name
end)

repeat task.wait(1) until LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("Data")

---- ============ function ============ ----

function TeleportToWaypoint(Position)
    hrp.CFrame = Position
end

function SendDiscordEmbed(url, embed)
    local http = game:GetService("HttpService")
    local headers = {
        ["Content-Type"] = "application/json"
    }
    local data = {
        ["content"] = embed.content,
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

---- ============ Info ============ ----

local Tab = Window:Tab({
    Title = "tr:Info",
    Icon = "info",
    Locked = false,
})

local InfoHub = Tab:Paragraph({
    Title = "tr:Info",
    Desc = "tr:InfoDesc"
})

local JoinServerDiscord = Tab:Button({
    Title = "tr:dc",
    Desc = "tr:dcdesc",
    Callback = function(Value)
        local discordInvite = "https://discord.gg/SKyMbVBJmz"

        setclipboard(discordInvite)

        pcall(function()
            local HttpService = game:GetService("HttpService")
            request({
                Url = "http://127.0.0.1:6463/rpc?v=1",
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["Origin"] = "https://discord.com"
                },
                Body = HttpService:JSONEncode({
                    cmd = "INVITE_BROWSER",
                    args = {
                        code = "SKyMbVBJmz"
                    },
                    nonce = HttpService:GenerateGUID(false)
                })
            })
        end)
    end
})

---- ============ Automatic ============ ----

-- ============ Auto Collect ============ --

local Section = Window:Section({
    Title = "tr:Automatic",
    Icon = "code-xml",
    Opened = false,
})

local Tab = Section:Tab({
    Title = "tr:AutoCollectTab",
    Icon = "hand",
    Opened = true,
})

getgenv().Collecting = false
local AutoCollectTab = Tab:Section({ Title = "tr:AutoCollectTab", Icon = "hand-grab"})

local AutoCollect = Tab:Toggle({
    Title = "tr:AutoCollect",
    Desc = "tr:AutoCollectDesc",
    Value = getgenv().Settings.Automatic.AutoCollect.AutoCollect,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoCollect.AutoCollect = Value
        SaveSetting()
        if Value then
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.Automatic.AutoCollect.AutoCollect do
                        if not getgenv().Settings.Utility.Premium.AutoTrade then
                        getgenv().Collecting = true
                        local oldPOS = hrp.CFrame
                        local MyIsland = workspace.Art[getgenv().MyIsland]:GetPivot()
                        TeleportToWaypoint(MyIsland)
                        task.wait(1.5)
                        TeleportToWaypoint(oldPOS)
                        getgenv().Collecting = false
                        end
                        for i,v in pairs(workspace.Pets:GetChildren()) do
                            if v:GetAttribute("UserId") == game.Players.LocalPlayer.UserId then
                                local args = {
                                    "Claim",
                                    bit32.bxor(
                                        game.Players.LocalPlayer.UserId, 
                                        game:GetService("ReplicatedStorage").Time:GetAttribute("s"), 
                                        game:GetService("ReplicatedStorage").Time.Value
                                    )
                                }
                                workspace:WaitForChild("Pets"):WaitForChild(v.Name):WaitForChild("RE"):FireServer(unpack(args))
                            end
                        end
                        task.wait(getgenv().Settings.Automatic.AutoCollect.AutoCollectDelay)
                    end
                end)
            end)
        else
            getgenv().Collecting = false
        end
    end
})

local DelayCollect = Tab:Slider({
    Title = "tr:DelayCollect",
    Value = {
        Min = 20,
        Max = 120,
        Default = getgenv().Settings.Automatic.AutoCollect.AutoCollectDelay,
    },
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoCollect.AutoCollectDelay = Value
        SaveSetting()
    end
})

-- ============ Quick ============ --

local QuickTab = Tab:Section({ Title = "tr:QuickTab", Icon = "fast-forward"})

local QuickCollect = Tab:Button({
    Title = "tr:QuickCollect",
    Desc = "tr:QuickCollectDesc",
    Callback = function()
        local oldPosition = hrp.CFrame
        local pos = workspace.Art[getgenv().MyIsland]:GetPivot()
        hrp.CFrame = pos
        for i,v in pairs(workspace.Pets:GetChildren()) do
            if v:GetAttribute("UserId") == game.Players.LocalPlayer.UserId then
                local args = {
                    "Claim",
                    bit32.bxor(game.Players.LocalPlayer.UserId, game:GetService("ReplicatedStorage").Time:GetAttribute("s"), game:GetService("ReplicatedStorage").Time.Value)
                }
                workspace:WaitForChild("Pets"):WaitForChild(v.Name):WaitForChild("RE"):FireServer(unpack(args))
            end
        end
        task.wait(1)
        hrp.CFrame = oldPosition
    end
})

-- ============ Auto Collect Pet ============ --

local CollectPet = Tab:Section({ Title = "tr:CollectPet", Icon = "cat"})

local Eard1 = Tab:Input({
    Title = "tr:AutoPetEard1",
    Value = getgenv().Settings.Automatic.AutoCollectPet.Eard1,
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoCollectPet.Eard1 = tonumber(Value)
        SaveSetting()
    end
})

local Eard2 = Tab:Input({
    Title = "tr:AutoPetEard2",
    Value = getgenv().Settings.Automatic.AutoCollectPet.Eard2,
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoCollectPet.Eard2 = tonumber(Value)
        SaveSetting()
    end
})

local CollectAllPetEarn = Tab:Button({
    Title = "tr:CollectAllPetEarn",
    Callback = function()
        for i,v in pairs(workspace.Pets:GetChildren()) do
            if v:GetAttribute("UserId") == UserId then
                if not v:GetAttribute("BigPetType") then 
                    if v:GetAttribute("ProduceSpeed") >= getgenv().Settings.Automatic.AutoCollectPet.Eard1 and v:GetAttribute("ProduceSpeed") <= getgenv().Settings.Automatic.AutoCollectPet.Eard2 then
                        game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("CharacterRE"):FireServer(unpack({"Del",v.Name,bit32.bxor(game.Players.LocalPlayer.UserId, game:GetService("ReplicatedStorage").Time:GetAttribute("s"), game:GetService("ReplicatedStorage").Time.Value)}))
                    end
                end
            end
        end
    end
})

local CollectAllPet = Tab:Button({
    Title = "tr:CollectAllPet",
    Callback = function()
        for i,v in pairs(workspace.Pets:GetChildren()) do
            if not v:GetAttribute("BigPetType") then
                game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("CharacterRE"):FireServer(unpack({"Del",v.Name,bit32.bxor(game.Players.LocalPlayer.UserId, game:GetService("ReplicatedStorage").Time:GetAttribute("s"), game:GetService("ReplicatedStorage").Time.Value)}))
            end
        end
    end
})

-- ============ AutoBuyEgg ============ --

local Tab = Section:Tab({
    Title = "tr:Eggs",
    Icon = "egg",
    Opened = true,
})

local EggsTable = {}
local EggsValueMap = {}
local RealNameMap = {}
local NameMap = {
    ["BiteForceSharkEgg"] = "Axe Shark Egg",
    ["MetroGiraffeEgg"] = "Sly Fox Egg",
}

local MutationModule = require(game.ReplicatedStorage.Config.ResMutate)

local listMutation = MutationModule["__index"]

local ConveyorPool = game:GetService("ReplicatedStorage").ConveyorPool
local ConveyorFolder = workspace.Art[getgenv().MyIsland].ENV.Conveyor

local AutoBuyEggTab = Tab:Section({ Title = "tr:AutoBuyEggTab", Icon = "egg" })

repeat task.wait() until getgenv().Conveyor ~= nil

function Updated()
    EggsTable = {}
    EggsValueMap = {}
    RealNameMap = {}
    
    for _, v in pairs(game:GetService("ReplicatedStorage").ConveyorPool:GetChildren()) do
        if v.Name == getgenv().Conveyor then
            for attrName, _ in pairs(v:GetAttributes()) do
                local displayName = NameMap[attrName] or attrName
                
                if not table.find(EggsTable, displayName) then
                    table.insert(EggsTable, displayName)
                    EggsValueMap[displayName] = attrName
                    RealNameMap[attrName] = displayName
                end
            end
            
            for i = #EggsTable, 1, -1 do
                local realName = EggsValueMap[EggsTable[i]]
                if v:GetAttribute(realName) == nil then
                    local displayName = EggsTable[i]
                    EggsValueMap[displayName] = nil
                    RealNameMap[realName] = nil
                    table.remove(EggsTable, i)
                end
            end
        end
    end
end

Updated()

function GetDisplayNamesFromSettings()
    local savedRealNames = getgenv().Settings.Automatic.AutoBuyEggs.SelectEgg
    local displayNames = {}
    
    for _, realName in pairs(savedRealNames) do
        local displayName = RealNameMap[realName] or realName
        table.insert(displayNames, displayName)
    end
    
    return displayNames
end

function GetDisplayNamesFromSettings1()
    local savedRealNames = getgenv().Settings.Automatic.AutoBuyEggs.SelectEggsWithMutation
    local displayNames = {}
    
    for _, realName in pairs(savedRealNames) do
        local displayName = RealNameMap[realName] or realName
        table.insert(displayNames, displayName)
    end
    
    return displayNames
end

local initialDisplayNames = GetDisplayNamesFromSettings()
local initialDisplayNames1 = GetDisplayNamesFromSettings1()

local SelectEggs = Tab:Dropdown({
    Title = "tr:SelectEggs",
    Multi = true,
    AllowNone = false,
    Value = initialDisplayNames,
    Values = EggsTable,
    Callback = function(Value)
        local realNames = {}
        for _, displayName in pairs(Value) do
            local realName = EggsValueMap[displayName]
            if realName then
                table.insert(realNames, realName)
            end
        end
        
        getgenv().Settings.Automatic.AutoBuyEggs.SelectEgg = realNames
        SaveSetting()
    end
})

local AutoBuyEgg = Tab:Toggle({
    Title = "tr:AutoBuyEgg",
    Desc = "tr:AutoBuyEggDesc",
    Value = getgenv().Settings.Automatic.AutoBuyEggs.AutoBuyEgg,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoBuyEggs.AutoBuyEgg = Value
        SaveSetting()
        task.spawn(function()
            pcall(function()
                while getgenv().Settings.Automatic.AutoBuyEggs.AutoBuyEgg do task.wait(1)
                    for i,v in pairs(game:GetService("ReplicatedStorage").Eggs[getgenv().MyIsland]:GetChildren()) do
                        if table.find(getgenv().Settings.Automatic.AutoBuyEggs.SelectEgg, v:GetAttribute("T")) then
                            game:GetService("ReplicatedStorage").Remote.CharacterRE:FireServer("BuyEgg", v.Name)
                        end
                    end
                end
            end)
        end)
    end
})

local AutoBuyEggwithmutationTab = Tab:Section({ Title = "tr:AutoBuyEggwithmutationTab", Icon = "radiation"})

local SelectEggsWith = Tab:Dropdown({
    Title = "tr:SelectEggsWith",
    Values = EggsTable,
    Value = initialDisplayNames1,
    Multi = true,
    AllowNone = false,
    Callback = function(Value)
        local realNames = {}
        for _, displayName in pairs(Value) do
            local realName = EggsValueMap[displayName]
            if realName then
                table.insert(realNames, realName)
            end
        end
        
        getgenv().Settings.Automatic.AutoBuyEggs.SelectEggsWithMutation = realNames
        SaveSetting()
    end
})

local SelectMutation = Tab:Dropdown({
    Title = "tr:SelectMutation",
    Values = listMutation,
    Value = getgenv().Settings.Automatic.AutoBuyEggs.SelectMutation,
    Multi = true,
    AllowNone = false,
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoBuyEggs.SelectMutation = Value
        SaveSetting()
    end
})

local AutoBuyEggwithmutation = Tab:Toggle({
    Title = "tr:AutoBuyEggwithmutation",
    Desc = "tr:AutoBuyEggwithmutationDesc",
    Value = getgenv().Settings.Automatic.AutoBuyEggs.AutoBuyEggwithmutation,
    Icon = "check",
    Callback = function(Callback)
        getgenv().Settings.Automatic.AutoBuyEggs.AutoBuyEggwithmutation = Callback
        SaveSetting()

        if Callback then
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.Automatic.AutoBuyEggs.AutoBuyEggwithmutation do task.wait(1)
                        for i, v in pairs(game:GetService("ReplicatedStorage").Eggs[getgenv().MyIsland]:GetChildren()) do
                            if table.find(getgenv().Settings.Automatic.AutoBuyEggs.SelectEggsWithMutation, v:GetAttribute("T")) then
                                if table.find(getgenv().Settings.Automatic.AutoBuyEggs.SelectMutation, v:GetAttribute("M")) then
                                    game:GetService("ReplicatedStorage").Remote.CharacterRE:FireServer("BuyEgg", v.Name)
                                    break
                                end
                            end
                        end
                    end
                end)
            end)
        end
    end
})

local AutoBuyEggwithEventSnowTab = Tab:Section({ Title = "tr:AutoBuyEggwithEventSnowTab", Icon = "snowflake"})

local SelectEggevent = Tab:Dropdown({
    Title = "tr:SelectEggevent",
    Values = {"RhinoRockEgg", "DarkGoatyEgg", "SaberCubEgg", "GeneralKongEgg"},
    Value = getgenv().Settings.Automatic.AutoBuyEggs.SelectEventSnow,
    Multi = true,
    AllowNone = false,
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoBuyEggs.SelectEventSnow = Value
        SaveSetting()
    end
})

local SnowMutatuion = Tab:Toggle({
    Title = "tr:SnowMutatuion",
    Value = getgenv().Settings.Automatic.AutoBuyEggs.infactionSnow,
    Icon = "check",
    Callback = function(Snow)
        getgenv().Settings.Automatic.AutoBuyEggs.infactionSnow = Snow
        SaveSetting()
    end
})

local AutoBuyEggwithEventSnow = Tab:Toggle({
    Title = "tr:AutoBuyEggwithEventSnow",
    Desc = "tr:AutoBuyEggwithEventSnowDesc",
    Value = getgenv().Settings.Automatic.AutoBuyEggs.AutoBuyEggwithEventSnow,
    Icon = "check",
    Callback = function(Snow)
        getgenv().Settings.Automatic.AutoBuyEggs.AutoBuyEggwithEventSnow = Snow
        SaveSetting()

        if Snow then
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.Automatic.AutoBuyEggs.AutoBuyEggwithEventSnow do task.wait(3)
                        for i,v in pairs(game:GetService("ReplicatedStorage").Eggs[getgenv().MyIsland]:GetChildren()) do
                            if table.find(getgenv().Settings.Automatic.AutoBuyEggs.SelectEventSnow, v:GetAttribute("T")) then
                                if getgenv().Settings.Automatic.AutoBuyEggs.infactionSnow then
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
    Updated()
    
    SelectEggs:Refresh(EggsTable, true, displayValues)
    SelectEggsWith:Refresh(EggsTable, true, displayValues)
end)

ConveyorFolder.ChildAdded:Connect(function(child)
    if child:IsA("Model") then
        getgenv().Conveyor = child.Name
    end
    Updated()
    
    SelectEggs:Refresh(EggsTable, true, displayValues)
    SelectEggsWith:Refresh(EggsTable, true, displayValues)
end)

-- ============ Auto Place & Hatch ============ --

local Tab = Section:Tab({
    Title = "tr:Place",
    Icon = "cat",
    Opened = true,
})

local AutoEquipEgg = Tab:Section({ Title = "tr:AutoEquipEggTabs", Icon = "egg"})

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

SelectEggPlace = Tab:Dropdown({
    Title = "tr:SelectEggPlace",
    Multi = true,
    AllowNone = false,
    Value = getgenv().Settings.Automatic.AutoPlace.SelectEgg,
    Values = Items,
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoPlace.SelectEgg = Value
        SaveSetting()
    end
})

local Refresh = Tab:Button({
    Title = "tr:Refresh",
    Callback = function()
        UpdateEgg()
        if SelectEggPlace then
            SelectEggPlace:Refresh(Items)
        end
    end
})

local AutoEquipEgg = Tab:Toggle({
    Title = "tr:AutoEquipEgg",
    Desc = "tr:AutoEquipEggDesc",
    Value = getgenv().Settings.Automatic.AutoPlace.AutoEquipEgg,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoPlace.AutoEquipEgg = Value
        SaveSetting()
        if Value then
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.Automatic.AutoPlace.AutoEquipEgg do task.wait(0.5)
                        if getgenv().Settings.Automatic.AutoPlace.AutoPlacePet or getgenv().Settings.Automatic.AutoPlace.AutoPlaceOcean then
                            local equipped = false
                            for _, eggName in ipairs(getgenv().Settings.Automatic.AutoPlace.SelectEgg) do
                                for i, v in pairs(game:GetService("Players").LocalPlayer.PlayerGui.Data.Egg:GetChildren()) do
                                    if v:GetAttribute("T") == eggName and not v:FindFirstChild("DI") then
                                        local holdUID = game.Players.LocalPlayer:GetAttribute("HoldUID")
                                        if not chr:FindFirstChild("HandObj") or holdUID ~= v.Name then
                                            game:GetService("ReplicatedStorage").Remote.CharacterRE:FireServer("Focus", v.Name)
                                            equipped = true
                                            break
                                        end
                                    end
                                end
                                if equipped then break end
                            end
                        end
                    end
                end)
            end)
        end
    end
})

local AutoPlaceTab = Tab:Section({ Title = "tr:AutoPlaceTab", Icon = "layout-template"})

local FarmPet = {}
local WaterPet = {}
local EliteFarmBlocks = {}
local EliteWaterBlocks = {}

function parseFarmName(name)
    local x, y, z = name:match("Farm_split_(%d+)_(%d+)_(%d+)")
    return tonumber(x), tonumber(y), tonumber(z)
end

function parseWaterName(name)
    local x, y, z = name:match("WaterFarm_split_?_(%d+)_(%d+)_(%d+)")
    return tonumber(x), tonumber(y), tonumber(z)
end

function compareFarm(a, b)
    local ax, ay, az = parseFarmName(a.Name)
    local bx, by, bz = parseFarmName(b.Name)

    if ax ~= bx then
        return ax < bx
    elseif ay ~= by then
        return ay < by
    else
        return az < bz
    end
end

function compareWater(a, b)
    local ax, ay, az = parseWaterName(a.Name)
    local bx, by, bz = parseWaterName(b.Name)

    if ax ~= bx then
        return ax < bx
    elseif ay ~= by then
        return ay < by
    else
        return az < bz
    end
end

function compareEliteBlocks(a, b)
    local aNum = tonumber(a.Name)
    local bNum = tonumber(b.Name)
    if aNum and bNum then
        return aNum < bNum
    end
    return a.Name < b.Name
end

for _, v in ipairs(workspace.Art[getgenv().MyIsland]:GetChildren()) do
    if v.Name:match("^Farm_split") then
        local inserted = false
        for i = 1, #FarmPet do
            if compareFarm(v, FarmPet[i]) then
                table.insert(FarmPet, i, v)
                inserted = true
                break
            end
        end
        if not inserted then
            table.insert(FarmPet, v)
        end
    end
end

for _, v in ipairs(workspace.Art[getgenv().MyIsland]:GetChildren()) do
    if v.Name:lower():find("^water") then
        local inserted = false
        for i = 1, #WaterPet do
            if compareWater(v, WaterPet[i]) then
                table.insert(WaterPet, i, v)
                inserted = true
                break
            end
        end
        if not inserted then
            table.insert(WaterPet, v)
        end
    end
end

local eliteFarmEnv = workspace.Art[getgenv().MyIsland]:FindFirstChild("ENV")
if eliteFarmEnv then
    local eliteFarmFolder = eliteFarmEnv:FindFirstChild("EliteFarmBlocks")
    if eliteFarmFolder then
        for _, v in ipairs(eliteFarmFolder:GetChildren()) do
            if v:IsA("BasePart") then
                table.insert(EliteFarmBlocks, v)
            end
        end
        table.sort(EliteFarmBlocks, compareEliteBlocks)
    end
end

if eliteFarmEnv then
    local eliteWaterFolder = eliteFarmEnv:FindFirstChild("EliteWaterBlocks")
    if eliteWaterFolder then
        for _, v in ipairs(eliteWaterFolder:GetChildren()) do
            if v:IsA("BasePart") then
                table.insert(EliteWaterBlocks, v)
            end
        end
        table.sort(EliteWaterBlocks, compareEliteBlocks)
    end
end

local AutoPlacePet = Tab:Toggle({
    Title = "tr:AutoPlacePet",
    Value = getgenv().Settings.Automatic.AutoPlace.AutoPlacePet,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoPlace.AutoPlacePet = Value
        SaveSetting()

        if Value then
            task.spawn(function()
                pcall(function()
                    local index = 1
                    while getgenv().Settings.Automatic.AutoPlace.AutoPlacePet do task.wait(.1)
                        if #FarmPet > 0 then
                            local pos = FarmPet[index].Position
                            local ohTable2 = {
                                ["DST"] = pos + Vector3.new(0, 10, 0),
                                ["ID"] = game.Players.LocalPlayer:GetAttribute("HoldUID")
                            }

                            game:GetService("ReplicatedStorage").Remote.CharacterRE:FireServer("Place", ohTable2)

                            index = index + 1
                            if index > #FarmPet then
                                index = 1
                            end
                        end
                    end
                end)
            end)
        end
    end
})

local AutoPlaceOcean = Tab:Toggle({
    Title = "tr:AutoPlaceOcean",
    Value = getgenv().Settings.Automatic.AutoPlace.AutoPlaceOcean,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoPlace.AutoPlaceOcean = Value
        SaveSetting()
        if Value then
            task.spawn(function()
                pcall(function()
                    local index = 1
                    while getgenv().Settings.Automatic.AutoPlace.AutoPlaceOcean do task.wait(.1)
                        if #WaterPet > 0 then
                            local pos = WaterPet[index].Position
                            local ohTable2 = {
                                ["DST"] = pos + Vector3.new(0, 10, 0),
                                ["ID"] = game.Players.LocalPlayer:GetAttribute("HoldUID")
                            }

                            game:GetService("ReplicatedStorage").Remote.CharacterRE:FireServer("Place", ohTable2)

                            index = index + 1
                            if index > #WaterPet then
                                index = 1
                            end
                        end
                    end
                end)
            end)
        end
    end
})

local AutoPlacePetElite = Tab:Toggle({
    Title = "tr:AutoPlacePetElite",
    Value = getgenv().Settings.Automatic.AutoPlace.AutoPlacePetElite or false,
    Icon = "star",
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoPlace.AutoPlacePetElite = Value
        SaveSetting()

        if Value then
            task.spawn(function()
                pcall(function()
                    local index = 1
                    while getgenv().Settings.Automatic.AutoPlace.AutoPlacePetElite do 
                        task.wait(.1)
                        
                        if #EliteFarmBlocks > 0 then
                            local pos = EliteFarmBlocks[index].Position
                            
                            local args = {
                                "Place",
                                {
                                    ["DST"] = pos,
                                    ["ID"] = game.Players.LocalPlayer:GetAttribute("HoldUID")
                                }
                            }
                            
                            game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("CharacterRE"):FireServer(unpack(args))

                            index = index + 1
                            if index > #EliteFarmBlocks then
                                index = 1
                            end
                        end
                    end
                end)
            end)
        end
    end
})

local AutoHatchTab = Tab:Section({ Title = "tr:AutoHatchTab", Icon = "sparkles"})

local AutoHatch = Tab:Toggle({
    Title = "tr:AutoHatch",
    Value = getgenv().Settings.Automatic.AutoPlace.AutoHatch,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Automatic.AutoPlace.AutoHatch = Value
        SaveSetting()
        if Value then
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.Automatic.AutoPlace.AutoHatch do task.wait(1)
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

-- ============ Fish ============ --

local Tab = Section:Tab({
    Title = "tr:Fish",
    Icon = "fish",
    Opened = true,
})

local BaitsFree = {
    ["Cheese Bait"] = "FishingBait1",
    ["Fly Bait"] = "FishingBait2",
    ["Fish Bait"] = "FishingBait3",
    ["Mushroom Bait"] = "FishingBait4",
    ["Hamburger Bait"] = "FishingBait5",
    ["Drumstick Bait"] = "FishingBait6",
}

local BaitReverse = {}
for name, value in pairs(BaitsFree) do
    BaitReverse[value] = name
end

local FishTab = Tab:Section({ Title = "tr:FishTab", Icon = "fish"})

local SelectBaitNormal = Tab:Dropdown({
    Title = "tr:SelectBaitNormal",
    Multi = false,
    AllowNone = true,
    Values = {"Cheese Bait", "Fly Bait", "Fish Bait", "Mushroom Bait", "Hamburger Bait", "Drumstick Bait"},
    Value = BaitReverse[getgenv().Settings.Automatic.Fish.SelectBait],
    Callback = function(Value)
        getgenv().Settings.Automatic.Fish.SelectBait = BaitsFree[Value]
        SaveSetting()
    end
})

local AutoFish

AutoFish = Tab:Toggle({
    Title = "tr:AutoFish",
    Value = getgenv().Settings.Automatic.Fish.AutoFish,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Automatic.Fish.AutoFish = Value
        SaveSetting()

        if Value then
            if not getgenv().Settings.Automatic.Fish.SelectBait then
                WindUI:Notify({Title = "Venuz | Notify", Content = "Please Select Bait", Duration = 5})
                task.wait(.5)
                AutoFish:Set(false)
                return
            end

            task.spawn(function()
                pcall(function()
                    local fishingPosition = CFrame.new(-536, 16, 164)
                    
                    while getgenv().Settings.Automatic.Fish.AutoFish do task.wait()
                        if not getgenv().Settings.Automatic.Fish.AutoFish then break end

                        if game.Players.LocalPlayer:GetAttribute("HoldUID") ~= "FishRob" then
                            game.Players.LocalPlayer:SetAttribute("HoldUID", "FishRob")
                        end

                        if not hrp.Anchored then 
                            hrp.Anchored = true
                            humanoid.PlatformStand = false
                            humanoid.WalkSpeed = 0 
                        end

                        if not getgenv().Collecting then
                            TeleportToWaypoint(fishingPosition)
                        end

                        if not getgenv().Collecting then
                            local AnimFish = game.Players.LocalPlayer.Character:GetAttribute("AnimFish")
                            
                            if AnimFish == "Ready" then
                                local targetPos = Vector3.new(88.4163818359375, 11, -287.8595886230469)
                                game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("FishingRE"):FireServer("Throw", {
                                    Bait = getgenv().Settings.Automatic.Fish.SelectBait, 
                                    Pos = targetPos
                                })
                            elseif AnimFish == "Pull" then
                                game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("FishingRE"):FireServer("POUT", {SUC = 1})
                            end
                        end
                    end
                end)
            end)
        else
            game.Players.LocalPlayer:SetAttribute("HoldUID", nil)
            hrp.Anchored = false
            humanoid.PlatformStand = false
            humanoid.WalkSpeed = 29
        end
    end
})

-- ============ Auto Feed ============ --

local Fruits = {}

for i,v in pairs(game:GetService("Players").LocalPlayer.PlayerGui.Data.FoodStore.LST:GetAttributes()) do
    table.insert(Fruits, i)
end

local Tab = Section:Tab({
    Title = "tr:Feed",
    Icon = "apple",
    Opened = true,
})

local AutoFeed

local AutoEquipFruit = Tab:Section({ Title = "tr:AutoEquipFruit", Icon = "apple"})
SelectFruit = Tab:Dropdown({
    Title = "tr:SelectFruit",
    Values = Fruits,
    Multi = false,
    Value = getgenv().Settings.Automatic.Feed.SelectFruit,
    AllowNone = false,
    Callback = function(Value)
        getgenv().Settings.Automatic.Feed.SelectFruit = Value
        SaveSetting()
    end
})

AutoEquip = Tab:Toggle({
    Title = "tr:AutoEquip",
    Value = getgenv().Settings.Automatic.Feed.AutoEquip,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Automatic.Feed.AutoEquip = Value
        SaveSetting()

        if Value then
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.Automatic.Feed.AutoEquip do task.wait(0.5)
                        if getgenv().Settings.Automatic.Feed.AutoFeed then
                            game:GetService("ReplicatedStorage").Remote.CharacterRE:FireServer(unpack({[1] = "Focus",[2] = getgenv().Settings.Automatic.Feed.SelectFruit}))
                        end
                    end
                end)
            end)
        end
    end
})

SettingsFeedTab = Tab:Section({ Title = "tr:SettingsFeedTab", Icon = "cog"})

SelectMutationBigPet = Tab:Dropdown({
    Title = "Select Mutation",
    Value = getgenv().Settings.Automatic.Feed.Mutation,
    Values = listMutation,
    Multi = true,
    AllowNone = true,
    Callback = function(Value)
        getgenv().Settings.Automatic.Feed.Mutation = Value
        SaveSetting()
    end
})

AutoFeedTab = Tab:Section({ Title = "tr:AutoFeedTab", Icon = "utensils-crossed"})

SelectPet = Tab:Dropdown({
    Title = "tr:SelectPet",
    Values = {"Big Pet1","Big Pet2", "Big Fish"},
    Multi = true,
    Value = getgenv().Settings.Automatic.Feed.SelectPet,
    AllowNone = false,
    Callback = function(Value)
        getgenv().Settings.Automatic.Feed.SelectPet = Value
        SaveSetting()
    end
})

AutoFeed = Tab:Toggle({
    Title = "tr:AutoFeed",
    Desc = "tr:AutoFeedDesc",
    Value = getgenv().Settings.Automatic.Feed.AutoFeed,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Automatic.Feed.AutoFeed = Value
        SaveSetting()

        if Value then
            if not getgenv().Settings.Automatic.Feed.SelectPet or #getgenv().Settings.Automatic.Feed.SelectPet == 0 then
                WindUI:Notify({
                    Title = "Venuz | Notify",
                    Content = "Please Select at least one Pet Mode.",
                    Icon = VenuzIcon,
                    Duration = 5,
                })
                task.wait(.5)
                AutoFeed:Set(false)
                return
            end
            
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.Automatic.Feed.AutoFeed do 
                        task.wait(0.5)
                        
                        local shortestDistance = 30
                        local selectedPets = getgenv().Settings.Automatic.Feed.SelectPet
                        
                        local petPositions = {}
                        for _, petName in pairs(selectedPets) do
                            if petName == "Big Pet1" then
                                table.insert(petPositions, workspace.Art[getgenv().MyIsland].ENV.BigPet["1"].Position)
                            elseif petName == "Big Pet2" then
                                table.insert(petPositions, workspace.Art[getgenv().MyIsland].ENV.BigPet["2"].Position)
                            elseif petName == "Big Fish" then
                                table.insert(petPositions, workspace.Art[getgenv().MyIsland].ENV.BigPet["3"].Position)
                            end
                        end
                        
                        for i, v in pairs(workspace.Pets:GetChildren()) do
                            if v:IsA("BasePart") then
                                for _, petPos in pairs(petPositions) do
                                    local distance = (petPos - v.Position).Magnitude
                                    
                                    if distance < shortestDistance then
                                        local shouldFeed = true
                                        if #getgenv().Settings.Automatic.Feed.Mutation > 0 then
                                            if table.find(getgenv().Settings.Automatic.Feed.Mutation, v:GetAttribute("Mutate")) then
                                                shouldFeed = false
                                            end
                                        end
                                        
                                        if shouldFeed then
                                            game:GetService("ReplicatedStorage").Remote.PetRE:FireServer("Feed", tostring(v.Name))
                                            break
                                        end
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

---- ============ Purchase ============ ----

-- ============ Foods ============ --

local Section = Window:Section({
    Title = "tr:Purchase",
    Icon = "bitcoin",
    Opened = false,
})

local Tab = Section:Tab({
    Title = "tr:Food",
    Icon = "shopping-basket",
    Opened = true,
})

local FruitTab = Tab:Section({ Title = "tr:FruitTab", Icon = "apple"})    

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

local SelectFruitShop = Tab:Dropdown({
    Title = "tr:SelectFruitShop",
    Values = Fruits,
    Multi = true,
    Value = getgenv().Settings.Purchase.Food.Foods,
    AllowNone = false,
    Callback = function(Value)
        getgenv().Settings.Purchase.Food.Foods = Value
        SaveSetting()
    end
})

local AutoBuyFruits = Tab:Toggle({
    Title = "tr:AutoBuyFruits",
    Desc = "tr:AutoBuyFruitsDesc",
    Value = getgenv().Settings.Purchase.Food.AutoBuyFoods,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Purchase.Food.AutoBuyFoods = Value
        SaveSetting()
        
        if Value then
            task.spawn(function()
                local purchasedFruits = {}
                local lastWebhookTime = nil
                local webhookCooldown = 10
                
                while getgenv().Settings.Purchase.Food.AutoBuyFoods do 
                    task.wait(1)
                    
                    for i, v in pairs(game:GetService("Players").LocalPlayer.PlayerGui.Data.FoodStore.LST:GetAttributes()) do
                        if table.find(getgenv().Settings.Purchase.Food.Foods, i) then
                            if v > 0 then
                                game:GetService("ReplicatedStorage").Remote.FoodStoreRE:FireServer(i)
                                
                                if purchasedFruits[i] then
                                    purchasedFruits[i] = purchasedFruits[i] + 1
                                else
                                    purchasedFruits[i] = 1
                                end
                                
                                if not lastWebhookTime then
                                    lastWebhookTime = os.time()
                                end
                                
                                break
                            end
                        end
                    end
                    
                    if getgenv().Settings.Utility.Webhook.AutoBuyFood then
                        if lastWebhookTime and os.time() - lastWebhookTime >= webhookCooldown then
                            if next(purchasedFruits) then
                                local infoName = (getgenv().ConfigurationTable.Language == "Thai") and "ข้อมูล" or "Info"
                                local resultName = (getgenv().ConfigurationTable.Language == "Thai") and "ผลการซื้อผลไม้" or "Fruits Bought"
                                
                                local fruitsList = ""
                                for fruitName, count in pairs(purchasedFruits) do
                                    fruitsList = fruitsList .. fruitName .. " (x" .. count .. ")\n"
                                end
                                
                                local embed = {
                                    ["title"] = "🍉 Auto Buy Fruits Result",
                                    ["color"] = 16777215,
                                    ["fields"] = {
                                        {
                                            ["name"] = infoName,
                                            ["value"] = "`` 👤 `` : **".. game:GetService("Players").LocalPlayer.Name .."**\n`` 💻 `` : **"..identifyexecutor().."**\n`` 🕓 `` : **".. os.date("%H:%M:%S") .."**\n`` 🎮 `` : **Game Build A Zoo**",
                                            ["inline"] = false
                                        },
                                        {
                                            ["name"] = resultName,
                                            ["value"] = "```"..fruitsList.."```",
                                            ["inline"] = false
                                        }
                                    },
                                    ["image"] = {
                                        ["url"] = "https://tr.rbxcdn.com/180DAY-f212509b8348e6273a1e4784d653ee07/768/432/Image/Webp/noFilter"
                                    }
                                }

                                if getgenv().Settings.Utility.Webhook.Ping then
                                    embed["content"] = "@everyone"
                                end

                                SendDiscordEmbed(getgenv().Settings.Utility.Webhook.WebhookUrl, embed)
                                
                                purchasedFruits = {}
                                lastWebhookTime = os.time()
                            end
                        end
                    end
                end
            end)
        end
    end
})

---- ============ Utility ============ ----

-- ============ Events ============ --

local Section = Window:Section({
    Title = "tr:Extras",
    Icon = "circuit-board",
    Opened = false,
})

local Tab = Section:Tab({
    Title = "tr:QuestTab",
    Icon = "target",
    Opened = true,
})

local QuestTab = Tab:Section({ Title = "tr:QuestTab", Icon = "target", Opened = true})

local AutoClaimQuest = Tab:Toggle({
    Title = "tr:AutoClaimQuest",
    Value = getgenv().Settings.Utility.Event.AutoClaimQuest,
    Icon = "check",
    Callback = function(Quest)
        getgenv().Settings.Utility.Event.AutoClaimQuest = Quest
        SaveSetting()

        task.spawn(function()
            pcall(function()
                if Quest then
                    while getgenv().Settings.Utility.Event.AutoClaimQuest do task.wait(1)
                        for i,v in pairs(game:GetService("Players").LocalPlayer.PlayerGui.Data.DinoEventTaskData.Tasks:GetChildren()) do
                            game:GetService("ReplicatedStorage").Remote.DinoEventRE:FireServer({["event"] = "claimreward",["id"] = v:GetAttribute("Id")})
                        end
                    end
                end
            end)
        end)
    end
}) 

local AutoClaim = Tab:Toggle({
    Title = "tr:AutoClaimEgg",
    Value = getgenv().Settings.Utility.Event.AutoClaimEgg,
    Icon = "check",
    Callback = function(Quest)
        getgenv().Settings.Utility.Event.AutoClaimEgg = Quest
        SaveSetting()

        if Quest then
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.Utility.Event.AutoClaimEgg do task.wait(1)
                        game:GetService("ReplicatedStorage").Remote.DinoEventRE:FireServer({["event"] = "onlinepack"})
                    end
                end)
            end)
        end
    end
})

-- ============ Gift ============ --

local Tab = Section:Tab({
    Title = "tr:GiftTab",
    Icon = "gift",
    Opened = true,
})

local GiftTab = Tab:Section({ Title = "tr:GiftTab", Icon = "gift", Opened = true})

local SelectedType = nil
local SelectedItem = nil
local SelectedPlayer = nil
local GiftAmount = 1
local IsGifting = false
local Foods = {}

for i,v in pairs(game:GetService("Players").LocalPlayer.PlayerGui.Data.FoodStore.LST:GetAttributes()) do
   table.insert(Foods, i)
end

local SelectTypeGift = GiftTab:Dropdown({
    Title = "tr:SelectTypeGift",
    Values = {"Egg", "Pet", "Food"},
    Multi = false,
    AllowNone = false,
    Value = nil,
    Callback = function(Value)
        SelectedType = Value
        UpdateItemList()
    end
})

local SelectItemGift = GiftTab:Dropdown({
    Title = "tr:SelectItem",
    Values = {},
    Multi = false,
    AllowNone = false,
    Callback = function(Value)
        SelectedItem = Value
    end
})

local SelectPlayerGift = GiftTab:Dropdown({
    Title = "tr:SelectPlayer",
    Values = {},
    Multi = false,
    AllowNone = false,
    Callback = function(Value)
        SelectedPlayer = Value
    end
})

local GiftAmountInput = GiftTab:Input({
    Title = "tr:GiftAmount",
    Default = "1",
    Placeholder = "Enter amount...",
    Numeric = true,
    Callback = function(Value)
        GiftAmount = tonumber(Value) or 1
    end
})

function UpdateItemList()
    local items = {}
    local itemData = {} -- เก็บข้อมูลไอเทมจริงเพื่อใช้ตอน Gift
    local Selected = nil
    
    if SelectedType == "Food" then
        Selected = game:GetService("Players").LocalPlayer.PlayerGui.Data.Asset
        
        for foodName, foodValue in pairs(Selected:GetAttributes()) do
            local isFoodItem = false
            for _, name in pairs(Foods) do
                if foodName == name then
                    isFoodItem = true
                    break
                end
            end
            
            if isFoodItem and foodValue > 0 then
                table.insert(items, foodName .. " (x" .. foodValue .. ")")
                itemData[foodName .. " (x" .. foodValue .. ")"] = foodName
            end
        end
    else
        -- Egg และ Pet
        if SelectedType == "Egg" then
            Selected = game:GetService("Players").LocalPlayer.PlayerGui.Data.Egg
        elseif SelectedType == "Pet" then
            Selected = game:GetService("Players").LocalPlayer.PlayerGui.Data.Pets
        end
        
        if Selected then
            local itemCount = {} -- นับจำนวนไอเทมแต่ละประเภท
            local itemNames = {} -- เก็บชื่อจริงของไอเทม
            
            for i,v in pairs(Selected:GetChildren()) do
                local canGift = false
                
                if SelectedType == "Egg" then
                    canGift = not v:FindFirstChild("DI")
                elseif SelectedType == "Pet" then
                    local isDeployed = false
                    for _, pet in pairs(workspace.Pets:GetChildren()) do
                        if pet.Name == v.Name then
                            isDeployed = true
                            break
                        end
                    end
                    canGift = not isDeployed
                end
                
                if canGift then
                    local displayName = v:GetAttribute("T") or v.Name
                    local mutation = v:GetAttribute("M")
                    
                    -- สร้างชื่อแสดงผล
                    local fullDisplayName = displayName
                    if mutation and mutation ~= "" then
                        fullDisplayName = displayName .. " " .. mutation
                    end
                    
                    -- นับจำนวน
                    if not itemCount[fullDisplayName] then
                        itemCount[fullDisplayName] = 0
                        itemNames[fullDisplayName] = {}
                    end
                    itemCount[fullDisplayName] = itemCount[fullDisplayName] + 1
                    table.insert(itemNames[fullDisplayName], v.Name) -- เก็บชื่อจริงไว้
                end
            end
            
            -- สร้าง list แสดงผล
            for displayName, count in pairs(itemCount) do
                local displayText = displayName .. " (x" .. count .. ")"
                table.insert(items, displayText)
                itemData[displayText] = itemNames[displayName] -- เก็บชื่อจริงทั้งหมด
            end
        end
    end
    
    -- เก็บข้อมูลไว้ใช้ตอน Gift
    getgenv().GiftItemData = itemData
    
    SelectItemGift:Refresh(items)
end

function UpdatePlayerList()
    local players = {}
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if player ~= game:GetService("Players").LocalPlayer then
            table.insert(players, player.Name)
        end
    end
    SelectPlayerGift:Refresh (players)
end

UpdatePlayerList()

game:GetService("Players").PlayerAdded:Connect(UpdatePlayerList)
game:GetService("Players").PlayerRemoving:Connect(UpdatePlayerList)

function GiftItem(playerName, itemUID)
    local holdArgs = {
        "Focus",
        itemUID
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("CharacterRE"):FireServer(unpack(holdArgs))
    
    task.wait(0.5)
    
    local holdUID = game:GetService("Players").LocalPlayer:GetAttribute("HoldUID")
    if holdUID == itemUID then
        local giftArgs = {
            game:GetService("Players"):WaitForChild(playerName)
        }
        game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("GiftRE"):FireServer(unpack(giftArgs))
        return true
    else
        return false
    end
end

local TeleportBTN = GiftTab:Toggle({
    Title = "tr:GiftTeleport",
    Value = getgenv().Settings.Utility.Gift.Teleport,
    Icon = "map-pin",
    Callback = function(Teleport)
        getgenv().Settings.Utility.Gift.Teleport = Teleport
        SaveSetting()
    end
})

local GiftButton
GiftButton = GiftTab:Button({
    Title = "tr:StartGift",
    Callback = function()
        if IsGifting then
            IsGifting = false
            GiftButton:Unlock()
            return
        end
        
        if not SelectedType or not SelectedItem or not SelectedPlayer then
            WindUI:Notify({
                Title = "Gift System",
                Content = "Please select Type, Item, and Player first!",
                Icon = VenuzIcon,
                Duration = 5,
            })
            return
        end
        
        IsGifting = true
        GiftButton:Lock()
        
        task.spawn(function()
            local successCount = 0
            local itemsToGift = getgenv().GiftItemData[SelectedItem]
            
            local targetPlayer = game:GetService("Players"):FindFirstChild(SelectedPlayer)
            if not targetPlayer then
                WindUI:Notify({
                    Title = "Gift System",
                    Content = "Player not found: " .. SelectedPlayer,
                    Icon = VenuzIcon,
                    Duration = 5,
                })
                IsGifting = false
                GiftButton:Unlock()
                return
            end
            
            local stickToPlayer
            if getgenv().Settings.Utility.Gift.Teleport then
                stickToPlayer = game:GetService("RunService").Heartbeat:Connect(function()
                    if not IsGifting then return end
                    
                    local localChar = game:GetService("Players").LocalPlayer.Character
                    local targetChar = targetPlayer.Character
                    
                    if localChar and targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
                        local targetHRP = targetChar.HumanoidRootPart
                        localChar:PivotTo(targetHRP.CFrame * CFrame.new(0, 0, -10))
                    end
                end)
            end
            
            if SelectedType == "Food" then
                for i = 1, GiftAmount do
                    if not IsGifting then 
                        WindUI:Notify({
                            Title = "Gift System",
                            Content = "Gifting stopped by user",
                            Icon = VenuzIcon,
                            Duration = 3,
                        })
                        break 
                    end
                    
                    if not getgenv().Settings.Utility.Gift.Teleport then
                        local localChar = game:GetService("Players").LocalPlayer.Character
                        local targetChar = targetPlayer.Character
                        
                        if localChar and targetChar then
                            local localPivot = localChar:GetPivot()
                            local targetPivot = targetChar:GetPivot()
                            local distance = (localPivot.Position - targetPivot.Position).Magnitude
                            
                            if distance > 20 then
                                WindUI:Notify({
                                    Title = "Gift System",
                                    Content = string.format("Too far! Distance: %.1fm (Max: 20m)", distance),
                                    Icon = VenuzIcon,
                                    Duration = 5,
                                })
                                break
                            end
                        else
                            WindUI:Notify({
                                Title = "Gift System",
                                Content = "Character not found!",
                                Icon = VenuzIcon,
                                Duration = 5,
                            })
                            break
                        end
                    end
                    
                    if GiftItem(SelectedPlayer, itemsToGift) then
                        successCount = successCount + 1
                    end
                    
                    if i < GiftAmount then
                        local elapsed = 0
                        repeat
                            task.wait(0.1)
                            elapsed = elapsed + 0.1
                        until elapsed >= 2.5 or not IsGifting
                    end
                end
            else
                local totalAvailable = #itemsToGift
                local amountToGift = math.min(GiftAmount, totalAvailable)
                
                if GiftAmount > totalAvailable then
                    WindUI:Notify({
                        Title = "Gift System",
                        Content = string.format("Only %d items available (Requested: %d)", totalAvailable, GiftAmount),
                        Icon = VenuzIcon,
                        Duration = 5,
                    })
                end
                
                for i = 1, amountToGift do
                    if not IsGifting then 
                        WindUI:Notify({
                            Title = "Gift System",
                            Content = "Gifting stopped by user",
                            Icon = VenuzIcon,
                            Duration = 3,
                        })
                        break 
                    end
                    
                    if not getgenv().Settings.Utility.Gift.Teleport then
                        local localChar = game:GetService("Players").LocalPlayer.Character
                        local targetChar = targetPlayer.Character
                        
                        if localChar and targetChar then
                            local localPivot = localChar:GetPivot()
                            local targetPivot = targetChar:GetPivot()
                            local distance = (localPivot.Position - targetPivot.Position).Magnitude
                            
                            if distance > 20 then
                                WindUI:Notify({
                                    Title = "Gift System",
                                    Content = string.format("Too far! Distance: %.1fm (Max: 20m)", distance),
                                    Icon = VenuzIcon,
                                    Duration = 5,
                                })
                                break
                            end
                        else
                            WindUI:Notify({
                                Title = "Gift System",
                                Content = "Character not found!",
                                Icon = VenuzIcon,
                                Duration = 5,
                            })
                            break
                        end
                    end
                    
                    if GiftItem(SelectedPlayer, itemsToGift[i]) then
                        successCount = successCount + 1
                    end
                    
                    if i < amountToGift then
                        local elapsed = 0
                        repeat
                            task.wait(0.1)
                            elapsed = elapsed + 0.1
                        until elapsed >= 2.5 or not IsGifting
                    end
                end
            end
            
            if stickToPlayer then
                stickToPlayer:Disconnect()
            end
            
            IsGifting = false
            GiftButton:Unlock()
            WindUI:Notify({
                Title = "Gift System",
                Content = string.format("Completed! %d items sent to %s", successCount, SelectedPlayer),
                Icon = VenuzIcon,
                Duration = 5,
            })
        end)
    end
})

-- ============ Webhook ============ --

local Tab = Section:Tab({
    Title = "tr:WebhookTab",
    Icon = "send",
    Opened = true,
})

local TabsWebhook = Tab:Section({ Title = "tr:TabsWebhook", Icon = "send"})

local WebhookUrl = Tab:Input({
    Title = "tr:WebhookUrl",
    Value = getgenv().Settings.Utility.Webhook.WebhookUrl,
    Placeholder = "https://discord.com/api/webhooks",
    Callback = function(Value)
        getgenv().Settings.Utility.Webhook.WebhookUrl = Value
        SaveSetting()
    end
})

local WebhookPing = Tab:Toggle({
    Title = "tr:WebhookPing",
    Value = getgenv().Settings.Utility.Webhook.Ping,
    Icon = "check",
    Callback = function(Ping)
        getgenv().Settings.Utility.Webhook.Ping = Ping
        SaveSetting()
    end
})

local testembed = {}

if getgenv().ConfigurationTable.Language == "Thai" then
    testembed = {
        title = "Venuz Test",
        content = "",
        color = 16777215,
        fields = {
            {
                name = "ข้อมูล",
                value = "`` 👤 `` : **ชื่อ " .. "||".. game.Players.LocalPlayer.Name.. "||" .. "**\n`` 💻 `` : **ตัวรัน "..identifyexecutor().."**\n`` 🕓 `` : **เวลา ".. currentTime .."**\n`` 🎮 `` : **Build A Zoo**",
                inline = false
            },
            {
                name = "Test Status",
                value = "```🟢```"
            }
        },
        image = {
            url = "https://tr.rbxcdn.com/180DAY-f212509b8348e6273a1e4784d653ee07/768/432/Image/Webp/noFilter"
        },
    }
else
    testembed = {
        title = "Venuz Test",
        content = "",
        color = 16777215,
        fields = {
            {
                name = "Info",
                value = "`` 👤 `` : **Name " .. "||".. game.Players.LocalPlayer.Name.. "||" .. "**\n`` 💻 `` : **Executor "..identifyexecutor().."**\n`` 🕓 `` : **Time ".. currentTime .."**\n`` 🎮 `` : **Build A Zoo**",
                inline = false
            },
            {
                name = "Test Status",
                value = "```🟢```"
            }
        },
        image = {
            url = "https://tr.rbxcdn.com/180DAY-f212509b8348e6273a1e4784d653ee07/768/432/Image/Webp/noFilter"
        },
    }
end

local TestWebhook = Tab:Button({
    Title = "tr:TestWebhook",
    Callback = function()
        if getgenv().Settings.Utility.Webhook.WebhookUrl == "" then
            WindUI:Notify({Title = "Venuz | Notify",Content = "Please Enter Webhook Url.",Icon = VenuzIcon,Duration = 5,})
            return
        end
        if getgenv().Settings.Utility.Webhook.Ping then
            testembed["content"] = "@everyone"
        end
        SendDiscordEmbed(getgenv().Settings.Utility.Webhook.WebhookUrl, testembed)
        WindUI:Notify({Title = "Venuz | Notify",Content = "Send Webhook Successfully.",Icon = VenuzIcon,Duration = 5,})
    end
})

local EggTabsWebhook = Tab:Section({ Title = "tr:EggTabsWebhook", Icon = "egg"})

local CheckAllEgg = Tab:Button({
    Title = "tr:CheckAllEgg",
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

        local embed = {}

        if getgenv().ConfigurationTable.Language == "Thai" then
            embed = {
                ["title"] = "Venuz Test",
                ["content"] = "",
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
        else
            embed = {
                ["title"] = "Venuz Test",
                ["content"] = "",
                ["color"] = 16777215,
                ["fields"] = {
                    {
                        ["name"] = "ข้อมูล",
                        ["value"] = "`` 👤 `` : **Name " .. "||".. game.Players.LocalPlayer.Name.. "||" .. "**\n`` 💻 `` : **Executor "..identifyexecutor().."**\n`` 🕓 `` : **Time ".. os.date("%H:%M:%S") .."**\n`` 🎮 `` : **Game Build A Zoo**",
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
        end

        if getgenv().Settings.Utility.Webhook.Ping then
            embed["content"] = "@everyone"
        end

        SendDiscordEmbed(getgenv().Settings.Utility.Webhook.WebhookUrl, embed)
    end
})

local AutoBuyEggNotify = Tab:Toggle({
    Title = "tr:AutoBuyEggNotify",
    Value = getgenv().Settings.Utility.Webhook.AutoBuyEgg,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Utility.Webhook.AutoBuyEgg = Value
        SaveSetting()

        task.spawn(function()
            pcall(function()
                if not Value then
                    if _G.conn then
                        _G.conn:Disconnect()
                        _G.conn = nil
                    end
                    return
                end

                if _G.conn then
                    return
                end

                _G.conn = game:GetService("Players").LocalPlayer.PlayerGui.Data.Egg.ChildAdded:Connect(function(child)
                    local Name = child:GetAttribute("T")
                    local Mutation = child:GetAttribute("M") or "No Mutation"
                    
                    local embed
                    if getgenv().ConfigurationTable.Language == "Thai" then
                        embed = {
                            ["title"] = "🐣 Auto BuyEgg Result",
                            ["color"] = 16777215,
                            ["fields"] = {
                                {
                                    ["name"] = "ข้อมูล",
                                    ["value"] = "`` 👤 `` : **ชื่อ " .. "||".. game.Players.LocalPlayer.Name.. "||" .. "**\n`` 💻 `` : **ตัวรัน "..identifyexecutor().."**\n`` 🕓 `` : **เวลา ".. os.date("%H:%M:%S") .."**\n`` 🎮 `` : **Game Build A Zoo**",
                                    ["inline"] = false
                                },
                                {
                                    ["name"] = "ผลการซื้อไข่",
                                    ["value"] = "```"..Name.."( "..Mutation.." )".."```",
                                    ["inline"] = false
                                }
                            },
                            ["image"] = {
                                ["url"] = "https://tr.rbxcdn.com/180DAY-f212509b8348e6273a1e4784d653ee07/768/432/Image/Webp/noFilter"
                            },
                        }
                    else
                        embed = {
                            ["title"] = "🐣 Auto BuyEgg Result",
                            ["color"] = 16777215,
                            ["fields"] = {
                                {
                                    ["name"] = "Info",
                                    ["value"] = "`` 👤 `` : **Name " .. "||".. game.Players.LocalPlayer.Name.. "||" .. "**\n`` 💻 `` : **Executor "..identifyexecutor().."**\n`` 🕓 `` : **Time ".. os.date("%H:%M:%S") .."**\n`` 🎮 `` : **Game Build A Zoo**",
                                    ["inline"] = false
                                },
                                {
                                    ["name"] = "Eggs Result",
                                    ["value"] = "```"..Name.."( "..Mutation.." )".."```",
                                    ["inline"] = false
                                }
                            },
                            ["image"] = {
                                ["url"] = "https://tr.rbxcdn.com/180DAY-f212509b8348e6273a1e4784d653ee07/768/432/Image/Webp/noFilter"
                            },
                        }
                    end

                    if getgenv().Settings.Utility.Webhook.Ping then
                        embed["content"] = "@everyone"
                    end

                    SendDiscordEmbed(getgenv().Settings.Utility.Webhook.WebhookUrl, embed)
                end)
            end)
        end)
    end
})

local AutoBuyFoodNotify = Tab:Toggle({
    Title = "tr:AutoBuyFoodNotify",
    Value = getgenv().Settings.Utility.Webhook.AutoBuyFood,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Utility.Webhook.AutoBuyFood = Value
        SaveSetting()
    end
})

-- ============ Misc ============ --

local Tab = Section:Tab({
    Title = "tr:MiscTab",
    Icon = "info",
    Opened = true,
})

function ServerHop()
    -- HopServer by Phoenix Venuz Hub

    local HTTP = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local Player = game.Players.LocalPlayer

    local res = http.request({
        Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100",
        Method = "GET",
    }).Body

    local success, data = pcall(function()
        return HTTP:JSONDecode(res)
    end)

    if success then
        local servers = {}
        for _, v in ipairs(data.data) do
            if v.id and v.playing > 0 and v.id ~= game.JobId then
                table.insert(servers, v.id)
            end
        end

        if #servers > 0 then
            local randomServer = servers[math.random(1, #servers)]
            print("🛰️ Hopping to server:", randomServer)
            TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer, Player)
        end
    end
end

local MiscTabs = Tab:Section({ Title = "tr:MiscTabs", Icon = "info"})

local DisableAnimation = Tab:Toggle({
    Title = "tr:DisableAnimation",
    Value = getgenv().Settings.Utility.Misc.DisableAnimationPet,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Utility.Misc.DisableAnimationPet = Value
        SaveSetting()

        task.spawn(function()
            pcall(function()
                if Value then
                    while getgenv().Settings.Utility.Misc.DisableAnimationPet do task.wait()
                        for i, v in pairs(workspace.Pets:GetChildren()) do
                            local Model = v:FindFirstChild("Model")
                            if Model then
                                local AnimationController = Model:FindFirstChild("AnimationController")
                                if AnimationController then
                                local animator = AnimationController:FindFirstChildOfClass("Animator")
                                    if animator then
                                        for _, animObj in pairs(animator:GetChildren()) do
                                            if animObj:IsA("Animation") then
                                                if not getgenv().Settings.Utility.Misc.DisableAnimationPet then
                                                    local track = animator:LoadAnimation(animObj)
                                                    track:Play()
                                                else
                                                    for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                                                        track:Stop()
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end)
    end
})

local DisableMoney = Tab:Toggle({
    Title = "tr:DisableMoney",
    Value = getgenv().Settings.Utility.Misc.DisableEffectGetMoney,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Utility.Misc.DisableEffectGetMoney = Value
        SaveSetting()

        if Value then
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.Utility.Misc.DisableEffectGetMoney do task.wait()
                        for i,v in pairs(game:GetService("Players")[LocalPlayer.Name].PlayerGui.PopupDrop:GetChildren()) do
                            if v.Name == "WorkItem" then
                                if v.Position == UDim2.new(0.02,0,0.29,0) then
                                    v.Visible = true
                                else
                                    v.Visible = false
                                end
                            end
                        end
                    end
                end)
            end)
        end
    end
})

local RedeemAllCodes = Tab:Button({
    Title = "tr:RedeemAllCodes",
    Callback = function()
        local CODES = {
            "60KCCU919",
            "4XW5RG4CHRY",
            "N7A68Q82H83",
            "3XKK8Z2WB6G",
            "ZTWPH3WW8SJ",
            "DS5523YSQ3C",
            "subtoZRGZeRoGhost",
            "DelayGift",
            "Nyaa",
            "Halloween1018",
            "druscxlla",
            "BLACKFRIDAY",
            "E5GSDBK7ATX",
            "9WC77XXCM5A",
            "BHNR9CB9TNC",
            "A38JBJ3TSSE",
            "9HDARHCQMWS",
            "SANTAGIFT25",
            "HOLIDAYFUN1",
            "SANTASWORKS"
        }

        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local RedemptionCodeRE = ReplicatedStorage.Remote.RedemptionCodeRE 

        for i = 1, 2 do
            for _, code in ipairs(CODES) do
                RedemptionCodeRE:FireServer({
                    event = "usecode",
                    code = code,
                })
                task.wait(0.3)
            end
        end
    end
})

local UnlockBigPet2 = Tab:Button({
    Title = "tr:UnlockBigPet2",
    Callback = function()
        game.ReplicatedStorage.Remote.CharacterRE:FireServer("UnlockBP", 2)
    end
})

local AdventCalender = Tab:Toggle({
    Title = "tr:AdventCalender",
    Value = getgenv().Settings.Utility.Misc.AutoAdventCalender,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Utility.Misc.AutoAdventCalender = Value
        SaveSetting()

        if Value then
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.Utility.Misc.AutoAdventCalender do task.wait(1)
                        for i = 1,30 do
                            game:GetService("ReplicatedStorage").Remote.AdventCalendarRE:FireServer({["event"] = "claimreward",["day"] = i})
                            task.wait(.5)
                        end
                    end
                end)
            end)
        end
    end
})

local SeasonPass = Tab:Toggle({
    Title = "tr:SeasonPass",
    Value = getgenv().Settings.Utility.Misc.AutoSeasonPass,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Utility.Misc.AutoSeasonPass = Value
        SaveSetting()

        if Value then
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.Utility.Misc.AutoSeasonPass do task.wait(1)
                        for i = 1,60 do
                            game:GetService("ReplicatedStorage").Remote.SeasonPassRE:FireServer({["LV"] = i,["T"] = "Claim"})
                            task.wait(0.1)
                        end
                    end
                end)
            end)
        end
    end
})

local LikeTabs = Tab:Section({ Title = "tr:LikeTabs", Icon = "heart"})

local AutolikeServerHop = Tab:Toggle({
    Title = "tr:AutolikeServerHop",
    Value = getgenv().Settings.Utility.Misc.AutoLikeHopServer,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Utility.Misc.AutoLikeHopServer = Value
        SaveSetting()

        task.spawn(function()
            pcall(function()
                if Value then
                    while getgenv().Settings.Utility.Misc.AutoLikeHopServer do task.wait(1)
                        for i,v in pairs(workspace.Art:GetChildren()) do
                            if v:GetAttribute("OccupyingPlayerId") then
                                if v:GetAttribute("OccupyingPlayerId") ~= game.Players.LocalPlayer.UserId then
                                    game:GetService("ReplicatedStorage").Remote.CharacterRE:FireServer("GiveLike", v:GetAttribute("OccupyingPlayerId"))
                                    task.wait(.1)
                                end
                            end
                        end
                        task.wait(getgenv().Settings.Utility.Misc.DelayAutoLike)
                        if getgenv().Settings.Utility.Misc.AutoLikeHopServer then
                        ServerHop()
                        end
                    end
                end
            end)
        end)
    end
})

local DelayAutoLike = Tab:Slider({
    Title = "tr:DelayAutoLike",
    Value = {
        Min = 1,
        Max = 30,
        Default = getgenv().Settings.Utility.Misc.DelayAutoLike,
    },
    Callback = function(Value)
        getgenv().Settings.Utility.Misc.DelayAutoLike = Value
        SaveSetting()
    end
})

local AutoLikeTabs1 = Tab:Section({ Title = "tr:AutoLikeTabs1", Icon = "heart"})

local Plrs = {}

for i,v in pairs(game:GetService("Players"):GetChildren()) do
    if v.Name ~= LocalPlayer.Name then
        table.insert(Plrs, v.Name)
    end
end

local SelectPlayers_AutoLike = Tab:Dropdown({
    Title = "tr:SelectPlayers_AutoLike",
    Value = {},
    Values = Plrs,
    Multi = true,
    AllowNone = false,
    Callback = function(Plr)
        Plrs = Plr
    end
})

local AutolikeAFK = Tab:Toggle({
    Title = "tr:AutolikeAFK",
    Value = getgenv().Settings.Utility.Misc.AutoLike,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Utility.Misc.AutoLike = Value
        SaveSetting()

        if Value then
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.Utility.Misc.AutoLike do
                        for i,v in pairs(game:GetService("Players"):GetChildren()) do
                            if table.find(Plrs, v.Name) then
                                game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("CharacterRE"):FireServer(unpack({"GiveLike",v.UserId}))
                                break
                            end
                        end
                        task.wait(getgenv().Settings.Utility.Misc.DelayAutoLikeAFK)
                    end
                end)
            end)
        end
    end
})

local AutolikeDelay = Tab:Slider({
    Title = "tr:AutolikeDelay",
    Value = {
        Min = 1,
        Max = 90,
        Default = getgenv().Settings.Utility.Misc.DelayAutoLikeAFK
    },
    Callback = function(Value)
        getgenv().Settings.Utility.Misc.DelayAutoLikeAFK = Value
        SaveSetting()
    end
})

game:GetService("Players").ChildAdded:Connect(function(Plr)
    if Plr.Name ~= LocalPlayer.Name and not table.find(Plrs, Plr.Name) then
        table.insert(Plrs, Plr.Name)
        SelectPlayers_AutoLike:Refresh(Plrs)
    end
end)

game:GetService("Players").ChildRemoved:Connect(function(Plr)
    local index = table.find(Plrs, Plr.Name)
    if index then
        table.remove(Plrs, index)
        SelectPlayers_AutoLike:Refresh(Plrs)
    end
end)

-- ============ Premium ============ --

local Tab = Section:Tab({
    Title = "tr:PremiumTab",
    Icon = "diamond-plus",
    Opened = true,
    Locked = getgenv().Premium
})

local Eggs = require(game:GetService("ReplicatedStorage").Config.ResEgg)
local Mutations = require(game:GetService("ReplicatedStorage").Config.ResMutate)

local EggsAutoSell = {}
local MutationsAutoSell = {}

for eggName in pairs(Eggs) do
    if eggName ~= "__index" then
        table.insert(EggsAutoSell, eggName)
    end
end

for MT in pairs(Mutations) do
    if MT ~= "__index" then
        table.insert(MutationsAutoSell, MT)
    end
end

local AutoSellTabs = Tab:Section({ Title = "tr:AutoSellEggTab", Icon = "egg"})

local SelectEggAutoSell = Tab:Dropdown({
    Title = "tr:SelectEggAutoSell",
    Multi = true,
    AllowNone = true,
    Values = EggsAutoSell,
    Value = getgenv().Settings.Utility.Premium.SelectEgg,
    Callback = function(Value)
        getgenv().Settings.Utility.Premium.SelectEgg = Value
        SaveSetting()
    end
})

local SelectEggAutoSell = Tab:Dropdown({
    Title = "tr:SelectMutationAutoSell",
    Multi = true,
    AllowNone = true,
    Values = MutationsAutoSell,
    Value = getgenv().Settings.Utility.Premium.SelectMutation,
    Callback = function(Value)
        getgenv().Settings.Utility.Premium.SelectMutation = Value
        SaveSetting()
    end
})

local SelectEggAutoSell

SelectEggAutoSell = Tab:Toggle({
    Title = "tr:AutoSellEgg",
    Value = getgenv().Settings.Utility.Premium.AutoSellEgg,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Utility.Premium.AutoSellEgg = Value
        SaveSetting()

        if Value then
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.Utility.Premium.AutoSellEgg do 
                        task.wait()
                        if not getgenv().Settings.Utility.Premium.AutoSellEgg then break end
                        
                        for i, v in pairs(game:GetService("Players").LocalPlayer.PlayerGui.Data.Egg:GetChildren()) do
                            if not v:FindFirstChild("DI") then
                                -- ตรวจสอบว่าเป็น Egg ที่เลือกหรือไม่
                                if #getgenv().Settings.Utility.Premium.SelectEgg > 0 then
                                    if table.find(getgenv().Settings.Utility.Premium.SelectEgg, v:GetAttribute("T")) then
                                        local shouldSell = false
                                        
                                        -- ถ้าเลือก Mutation ไว้
                                        if #getgenv().Settings.Utility.Premium.SelectMutation > 0 then
                                            -- ขายเฉพาะที่มี Mutation ที่เลือก
                                            if table.find(getgenv().Settings.Utility.Premium.SelectMutation, v:GetAttribute("M")) then
                                                shouldSell = true
                                            end
                                        else
                                            -- ถ้าไม่ได้เลือก Mutation ให้ขายเฉพาะที่ไม่มีบัพ (M = nil หรือ M = "")
                                            local mutation = v:GetAttribute("M")
                                            if mutation == nil or mutation == "" then
                                                shouldSell = true
                                            end
                                        end
                                        
                                        if shouldSell then
                                            game:GetService("ReplicatedStorage").Remote.PetRE:FireServer("Sell", v.Name, true)
                                        end
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

local Weather = Tab:Section({ Title = "tr:Weather", Icon = "cloud-rain"})

local InfoWeather = Tab:Paragraph({
    Title = "tr:InfoWeather",
    Desc = "tr:InfoWeatherDesc"
})

local ServerHopFindEventSnow = Tab:Dropdown({
    Title = "tr:ServerHopFindEventSnow",
    Value = getgenv().Settings.Utility.Premium.HopServerList,
    Values = {"Snow", "Halloween", "Sand", "Aurora", "Thanksgiving"},
    Multi = false,
    AllowNone = false,
    Callback = function(Value)
        getgenv().Settings.Utility.Premium.HopServerList = Value
        SaveSetting()
    end
})

local ServerHopFindEventHalloween = Tab:Toggle({
    Title = "tr:ServerHopFindEventHalloween",
    Value = getgenv().Settings.Utility.Premium.HopServerHollowen,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Utility.Premium.HopServerHollowen = Value
        SaveSetting()

        if Value then
            spawn(function()
                pcall(function()
                    while getgenv().Settings.Utility.Premium.HopServerHollowen do task.wait(1)
                        if workspace:GetAttribute("Weather") ~= getgenv().Settings.Utility.Premium.HopServerList then
                            ServerHop()
                        end
                    end
                end)
            end)
        end
    end
})

local EquipTradeSection = Tab:Section({ Title = "tr:AutoEquipTrade", Icon = "cog"})

local MinValue = Tab:Input({
    Title = "tr:MinValue",
    Value = tonumber(getgenv().Settings.Utility.Premium.MinValue),
    Placeholder = "1",
    Callback = function(Value)
        getgenv().Settings.Utility.Premium.MinValue = tonumber(Value)
        SaveSetting()
    end
})

local MaxValue = Tab:Input({
    Title = "tr:MaxValue",
    Value = tonumber(getgenv().Settings.Utility.Premium.MaxValue),
    Placeholder = "1",
    Callback = function(Value)
        getgenv().Settings.Utility.Premium.MaxValue = tonumber(Value)
        SaveSetting()
    end
})

local AutoEquipTrade = Tab:Toggle({
    Title = "tr:AutoEquipTrade",
    Value = getgenv().Settings.Utility.Premium.AutoEquipTrade,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Utility.Premium.AutoEquipTrade = Value
        SaveSetting()

        if Value then
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.Utility.Premium.AutoEquipTrade do task.wait(1)

                        local success, err = pcall(function()
                            local player = game:GetService("Players").LocalPlayer
                            local PetsFolder = player:WaitForChild("PlayerGui"):WaitForChild("Data"):WaitForChild("Pets")

                            local ReplicatedStorage = game:GetService("ReplicatedStorage")
                            local SharedModule = ReplicatedStorage:WaitForChild("Shared")

                            local PetModule
                            local reqSuccess = pcall(function()
                                PetModule = require(SharedModule)("Pet")
                            end)
                            
                            if not reqSuccess or not PetModule then
                                return
                            end

                            local function ToPlainNumber(value)
                                if type(value) == "string" then
                                    value = value:gsub(",", "")
                                    value = tonumber(value)
                                end
                                return math.floor(value or 0)
                            end

                            local deployedPets = {}
                            local workspacePets = workspace:WaitForChild("Pets"):GetChildren()

                            for _, pet in pairs(workspacePets) do
                                deployedPets[pet.Name] = pet
                            end

                            local shouldSkip = false

                            if #workspacePets > 0 then
                                local currentPetName = workspacePets[1].Name
                                local currentPetInst = PetsFolder:FindFirstChild(currentPetName)
                                
                                if currentPetInst then
                                    local petData = {}

                                    local attrSuccess = pcall(function()
                                        for attrName, attrValue in pairs(currentPetInst:GetAttributes()) do
                                            petData[attrName] = attrValue
                                        end
                                    end)
                                    
                                    if attrSuccess then
                                        local incomeSuccess, income = pcall(function()
                                            return PetModule:GetPetProduce(petData, 1)
                                        end)

                                        if incomeSuccess and income then
                                            local plainIncome = ToPlainNumber(income)

                                            if plainIncome >= getgenv().Settings.Utility.Premium.MinValue and 
                                               plainIncome <= getgenv().Settings.Utility.Premium.MaxValue then
                                                shouldSkip = true
                                            end
                                        end
                                    end
                                end

                                if not shouldSkip then
                                    game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("CharacterRE"):FireServer("Unfocus", currentPetName)
                                    task.wait(0.8)
                                end
                            end

                            if not shouldSkip then
                                for _, petInst in pairs(PetsFolder:GetChildren()) do
                                    if not deployedPets[petInst.Name] then
                                        local petData = {}
                                        
                                        local attrSuccess = pcall(function()
                                            for attrName, attrValue in pairs(petInst:GetAttributes()) do
                                                petData[attrName] = attrValue
                                            end
                                        end)
                                        
                                        if attrSuccess then
                                            local incomeSuccess, income = pcall(function()
                                                return PetModule:GetPetProduce(petData, 1)
                                            end)

                                            if incomeSuccess and income then
                                                local plainIncome = ToPlainNumber(income)

                                                if plainIncome >= getgenv().Settings.Utility.Premium.MinValue and 
                                                   plainIncome <= getgenv().Settings.Utility.Premium.MaxValue then
                                                    game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("CharacterRE"):FireServer("Focus", petInst.Name)
                                                    task.wait(0.5)
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end)
                    end
                end)
            end)
        end
    end
})

local TradeSection = Tab:Section({ Title = "tr:TradeSection", Icon = "handshake"})

getgenv().Status = "Waiting"
local ShowStatus
local Earns

function CheckStatus()
    for _, v in pairs(game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):GetDescendants()) do
        if v.Name == "SurfaceGui" and v:FindFirstChild("Root") then
            local stateTitle = v.Root:FindFirstChild("TradeBar") and v.Root.TradeBar:FindFirstChild("StateTitle")
            if stateTitle then
                -- ลบ attribute เดิมออกก่อน (ถ้ามี) เพื่อให้สามารถ reconnect ได้
                if stateTitle:GetAttribute("Connected") then
                    stateTitle:SetAttribute("Connected", nil)
                end
                
                stateTitle:SetAttribute("Connected", true)
                stateTitle:GetPropertyChangedSignal("Text"):Connect(function()
                    getgenv().Status = stateTitle.Text
                    ShowStatus:SetDesc("Status : " .. getgenv().Status)
                end)
                getgenv().Status = stateTitle.Text
                ShowStatus:SetDesc("Status : " .. getgenv().Status)
            end
        end
    end
end

ShowStatus = Tab:Paragraph({
    Title = "tr:ShowStatus",
    Desc = "Status : " .. getgenv().Status
})

game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui").ChildAdded:Connect(function(child)
    if child:IsA("SurfaceGui") then
        CheckStatus()
    end
end)

game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui").ChildRemoved:Connect(function(child)
    if child:IsA("SurfaceGui") then
        CheckStatus()
    end
end)

CheckStatus()

local CheckingLocked = false
local MinEarns
local MaxEarns

local Method = Tab:Dropdown({
    Title = "tr:Method",
    Value = getgenv().Settings.Utility.Premium.Method,
    Values = {"Status", "Earn/s"},
    Multi = false,
    AllowNone = false,
    Callback = function(Value)
        getgenv().Settings.Utility.Premium.Method = Value
        SaveSetting()

        if Value == "Status" then
            CheckingLocked = true
            if MinEarns and MaxEarns then
                MinEarns:Lock()
                MaxEarns:Lock()
            end
        else
            CheckingLocked = false
            if MinEarns and MaxEarns then
                MinEarns:Unlock()
                MaxEarns:Unlock()
            end
        end
    end
})

if getgenv().Settings.Utility.Premium.Method == "Status" then
    CheckingLocked = true
end

MinEarns = Tab:Input({
    Title = "tr:MinEarns",
    Value = tonumber(getgenv().Settings.Utility.Premium.MinEarns) or 1,
    Placeholder = "1",
    Locked = CheckingLocked,
    Callback = function(Value)
        getgenv().Settings.Utility.Premium.MinEarns = tonumber(Value)
        SaveSetting()
    end
})

MaxEarns = Tab:Input({
    Title = "tr:MaxEarns",
    Value = tonumber(getgenv().Settings.Utility.Premium.MaxEarns) or 999999,
    Placeholder = "999999",
    Locked = CheckingLocked,
    Callback = function(Value)
        getgenv().Settings.Utility.Premium.MaxEarns = tonumber(Value)
        SaveSetting()
    end
})

AutoTrade = Tab:Toggle({
    Title = "tr:AutoTrade",
    Value = getgenv().Settings.Utility.Premium.AutoTrade,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Utility.Premium.AutoTrade = Value
        SaveSetting()

        if Value then
            if getgenv().Settings.Utility.Premium.AutoFish then
                WindUI:Notify({Title = "Venuz | Notify",Content = "Your Enable Auto Fish",Duration = 5})
                task.wait(.5)
                AutoTrade:Set(false)
                return
            end

            if getgenv().Settings.Automatic.Fish.AutoFish then
                WindUI:Notify({Title = "Venuz | Notify",Content = "Your Enable Auto Fish",Duration = 5})
                task.wait(.5)
                AutoTrade:Set(false)
                return
            end

            if not getgenv().Settings.Utility.Premium.AutoEquipTrade then
                WindUI:Notify({Title = "Venuz | Notify",Content = "Please Enable Auto Equip Trade",Duration = 5})
                task.wait(.5)
                AutoTrade:Set(false)
                return
            end

            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.Utility.Premium.AutoTrade do 
                        task.wait(3)
                        
                        local Count = workspace.Art[getgenv().MyIsland].ENV.TradeZone.TradeZoneBoard.C.SurfaceGui.Num.Count
                        local playerGui = game:GetService("Players").LocalPlayer.PlayerGui
                        local surfaceGui = playerGui:FindFirstChild("SurfaceGui")
                        local hasRoot = surfaceGui and surfaceGui:FindFirstChild("Root") ~= nil
                        
                        if surfaceGui and (not surfaceGui.Enabled or not hasRoot) and not string.match(Count.Text, "^0/%d+$") then
                            local awayPos = workspace.Art[getgenv().MyIsland].ENV.AreaRange.CFrame * CFrame.new(0, 50, 50)
                            hrp.CFrame = awayPos
                            task.wait(2)
                            
                            hrp.CFrame = workspace.Art[getgenv().MyIsland].ENV.TradeZone.Zone.TradeZone5.TradePart.AddMore.CFrame * CFrame.new(7, 2, 0)
                            hrp.CFrame = CFrame.lookAt(hrp.Position, workspace.Art[getgenv().MyIsland].ENV.TradeZone.Zone.TradeZone5.TradePart.AddMore.Position)
                            task.wait(1)
                        end
                        
                        if game.Players.LocalPlayer:GetAttribute("HoldUID") == nil then
                            continue
                        end
                        
                        if not string.match(Count.Text, "^0/%d+$") then
                            hrp.CFrame = workspace.Art[getgenv().MyIsland].ENV.TradeZone.Zone.TradeZone5.TradePart.AddMore.CFrame * CFrame.new(7, 2, 0)
                            hrp.CFrame = CFrame.lookAt(hrp.Position, workspace.Art[getgenv().MyIsland].ENV.TradeZone.Zone.TradeZone5.TradePart.AddMore.Position)
                        else
                            hrp.CFrame = workspace.Art[getgenv().MyIsland].ENV.AreaRange.CFrame * CFrame.new(0, 20, 0)
                            repeat task.wait(1) until not string.match(workspace.Art[getgenv().MyIsland].ENV.TradeZone.TradeZoneBoard.C.SurfaceGui.Num.Count.Text, "^0/%d+$")
                        end
                        
                        task.wait(2)
                        
                        if string.match(Count.Text, "^0/%d+$") then
                            continue
                        end
                        
                        if getgenv().Settings.Utility.Premium.Method == "Status" then
                            if getgenv().Status == "Fair" or getgenv().Status == "ยุติ" then
                                fireclickdetector(workspace.Art[getgenv().MyIsland].ENV.TradeZone.Zone.TradeZone5.TradePart.Accept.ClickDetector, 25)
                                
                            elseif getgenv().Status == "Unfair" or getgenv().Status == "ไม่ยุติ" then
                                fireclickdetector(workspace.Art[getgenv().MyIsland].ENV.TradeZone.Zone.TradeZone5.TradePart.AddMore.ClickDetector, 25)
                                task.wait(1)
                                
                                local myIncome = 0
                                local theirIncome = 0
                                local found = false
                                
                                for _, v in pairs(playerGui.SurfaceGui:GetChildren()) do
                                    if v.Name == "Root" and not found then
                                        local TradeFrame = v:FindFirstChild("TradeFrame")
                                        if TradeFrame then
                                            local Trader = TradeFrame:FindFirstChild("Trader")
                                            if Trader then
                                                for _, prefab in pairs(Trader:GetChildren()) do
                                                    if prefab.Name == "TraderPrefab" then
                                                        local BTN = prefab:FindFirstChild("BTN")
                                                        if BTN then
                                                            local Stat = BTN:FindFirstChild("Stat")
                                                            if Stat then
                                                                local Price = Stat:FindFirstChild("Price")
                                                                if Price then
                                                                    local Value = Price:FindFirstChild("Value")
                                                                    if Value then
                                                                        local number = string.gsub(Value.Text, "[^%d]", "")
                                                                        local result = tonumber(number) or 0
                                                                        
                                                                        if myIncome == 0 then
                                                                            myIncome = result
                                                                        else
                                                                            theirIncome = result
                                                                        end
                                                                    end
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                        found = true
                                    end
                                end
                                
                                local minEarns = getgenv().Settings.Utility.Premium.MinEarns or 1
                                local maxEarns = getgenv().Settings.Utility.Premium.MaxEarns or 999999
                                
                                if theirIncome >= minEarns and theirIncome <= maxEarns then
                                    fireclickdetector(workspace.Art[getgenv().MyIsland].ENV.TradeZone.Zone.TradeZone5.TradePart.Accept.ClickDetector, 25)
                                else
                                    fireclickdetector(workspace.Art[getgenv().MyIsland].ENV.TradeZone.Zone.TradeZone5.TradePart.Decline.ClickDetector, 25)
                                end
                                
                                task.wait(2)
                            end
                            
                        elseif getgenv().Settings.Utility.Premium.Method == "Earn/s" then
                            local decided = false
                            local minEarns = getgenv().Settings.Utility.Premium.MinEarns or 1
                            local maxEarns = getgenv().Settings.Utility.Premium.MaxEarns or 999999
                            
                            for _, v in pairs(playerGui.SurfaceGui:GetChildren()) do
                                if v.Name == "Root" and not decided then
                                    local TradeFrame = v:FindFirstChild("TradeFrame")
                                    if TradeFrame then
                                        local Trader = TradeFrame:FindFirstChild("Trader")
                                        if Trader then
                                            local TraderPrefab = Trader:FindFirstChild("TraderPrefab")
                                            if TraderPrefab then
                                                local BTN = TraderPrefab:FindFirstChild("BTN")
                                                if BTN then
                                                    local Stat = BTN:FindFirstChild("Stat")
                                                    if Stat then
                                                        local Price = Stat:FindFirstChild("Price")
                                                        if Price then
                                                            local Value = Price:FindFirstChild("Value")
                                                            if Value then
                                                                local number = string.gsub(Value.Text, "[^%d]", "")
                                                                local result = tonumber(number)
                                                                
                                                                -- เช็คว่าอยู่ในช่วง Min-Max
                                                                if result >= minEarns and result <= maxEarns then
                                                                    fireclickdetector(workspace.Art[getgenv().MyIsland].ENV.TradeZone.Zone.TradeZone5.TradePart.Accept.ClickDetector, 25)
                                                                    decided = true
                                                                else
                                                                    fireclickdetector(workspace.Art[getgenv().MyIsland].ENV.TradeZone.Zone.TradeZone5.TradePart.AddMore.ClickDetector, 25)
                                                                    task.wait(1)
                                                                    
                                                                    local myIncome = 0
                                                                    local theirIncome = 0
                                                                    
                                                                    for _, root in pairs(playerGui.SurfaceGui:GetChildren()) do
                                                                        if root.Name == "Root" then
                                                                            local TF = root:FindFirstChild("TradeFrame")
                                                                            if TF then
                                                                                local Trd = TF:FindFirstChild("Trader")
                                                                                if Trd then
                                                                                    for _, prefab in pairs(Trd:GetChildren()) do
                                                                                        if prefab.Name == "TraderPrefab" then
                                                                                            local B = prefab:FindFirstChild("BTN")
                                                                                            if B then
                                                                                                local S = B:FindFirstChild("Stat")
                                                                                                if S then
                                                                                                    local P = S:FindFirstChild("Price")
                                                                                                    if P then
                                                                                                        local V = P:FindFirstChild("Value")
                                                                                                        if V then
                                                                                                            local num = string.gsub(V.Text, "[^%d]", "")
                                                                                                            local res = tonumber(num) or 0
                                                                                                            
                                                                                                            if myIncome == 0 then
                                                                                                                myIncome = res
                                                                                                            else
                                                                                                                theirIncome = res
                                                                                                            end
                                                                                                        end
                                                                                                    end
                                                                                                end
                                                                                            end
                                                                                        end
                                                                                    end
                                                                                end
                                                                            end
                                                                        end
                                                                    end
                                                                    
                                                                    -- เช็คว่าอยู่ในช่วง Min-Max
                                                                    if theirIncome >= minEarns and theirIncome <= maxEarns then
                                                                        fireclickdetector(workspace.Art[getgenv().MyIsland].ENV.TradeZone.Zone.TradeZone5.TradePart.Accept.ClickDetector, 25)
                                                                    else
                                                                        fireclickdetector(workspace.Art[getgenv().MyIsland].ENV.TradeZone.Zone.TradeZone5.TradePart.Decline.ClickDetector, 25)
                                                                    end
                                                                    decided = true
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                                
                                if decided then
                                    break
                                end
                            end
                            
                            task.wait(2)
                        end
                    end
                end)
            end)
        end
    end
})

local TradeSection = Tab:Section({ Title = "tr:PlaceBest", Icon = "layout-template"})

local AutoPlacePetBest = Tab:Toggle({
    Title = "tr:AutoPlacePetBest",
    Value = getgenv().Settings.Utility.Premium.AutoPlacePetBest,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Utility.Premium.AutoPlacePetBest = Value
        SaveSetting()

        if Value then
            task.spawn(function()
                pcall(function()
                    local normalIndex = 1
                    local eliteIndex = 1
                    
                    while getgenv().Settings.Utility.Premium.AutoPlacePetBest do 
                        task.wait(.5)
                        
                        -- ⭐ ลิสต์สัตว์น้ำที่ต้องการข้าม (ไม่ต้องการวาง)
                        local OceanPets = {
                            "Swordfish",
                            "Shark",
                            "Dolphin",
                            "AngelFish",
                            "Catfish",
                            "Bighead",
                            "Flounder",
                            "Alligator",
                            "Hairtail",
                            "Butterflyfish",
                            "Needlefish",
                            "ElectricEel",
                            "Manta",
                            "Whale",
                            "JellyFish",
                            "Starfish",
                            "OceanSunfish",
                            "SeaSlug",
                            "PirateCrab",
                            "Narwhal",
                            "Seahorse",
                            "Lobster"
                        }

                        local Players = game:GetService("Players")
                        local LocalPlayer = Players.LocalPlayer
                        local playerData = LocalPlayer.PlayerGui:FindFirstChild("Data")
                        local PetsFolder = playerData:FindFirstChild("Pets")
                        local HttpService = game:GetService("HttpService")

                        local ReplicatedStorage = game:GetService("ReplicatedStorage")
                        local SharedModule = ReplicatedStorage:WaitForChild("Shared")
                        local PetModule = require(SharedModule)("Pet")

                        for _, v in pairs(workspace.PlayerBuiltBlocks:GetChildren()) do
                            local p = tonumber(string.match(v.Name, "%d+"))
                            if p == game.Players.LocalPlayer.UserId then
                                local data = v.Value
                                if typeof(data) == "string" then
                                    local success, decoded = pcall(function()
                                        return HttpService:JSONDecode(data)
                                    end)

                                    if success and typeof(decoded) == "table" and decoded[1] and decoded[1].UID then
                                        getgenv().E = decoded[1].UID
                                    else
                                        getgenv().E = nil
                                    end
                                end
                            end
                        end

                        local function ToPlainNumber(value)
                            if type(value) == "string" then
                                value = value:gsub(",", "")
                                value = tonumber(value)
                            end
                            return math.floor(value or 0)
                        end

                        -- ⭐ สร้าง Set สำหรับตรวจสอบสัตว์น้ำที่ต้องข้าม
                        local oceanSet = {}
                        for _, petName in ipairs(OceanPets) do
                            oceanSet[petName] = true
                            oceanSet[petName:lower()] = true
                        end

                        local deployedPets = {}
                        local workspacePets = workspace:FindFirstChild("Pets")
                        if workspacePets then
                            for _, pet in pairs(workspacePets:GetChildren()) do
                                deployedPets[pet.Name] = true
                            end
                        end

                        local currentHoldUID = LocalPlayer:GetAttribute("HoldUID")
                        if currentHoldUID and deployedPets[currentHoldUID] then
                            game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("CharacterRE"):FireServer("Focus")
                            task.wait(.2)
                        end

                        local maxIncome = 0
                        local bestPet = nil
                        local petCategory = nil

                        for _, petInst in pairs(PetsFolder:GetChildren()) do
                            local uid = tostring(petInst.Name)
                            if uid == getgenv().E then
                                continue
                            end

                            if not deployedPets[petInst.Name] then
                                local petType = petInst:GetAttribute("T")
                                local isElite = petInst:GetAttribute("Elite")
                                
                                -- ⭐ ข้ามสัตว์น้ำทั้งหมด (ไม่สนใจว่า Elite หรือไม่)
                                local isOcean = oceanSet[petType] or oceanSet[petType:lower()]
                                if isOcean then
                                    continue -- ข้ามสัตว์น้ำทันที
                                end
                                
                                local petData = {}
                                for attrName, attrValue in pairs(petInst:GetAttributes()) do
                                    petData[attrName] = attrValue
                                end
                                
                                local success, income = pcall(function()
                                    return PetModule:GetPetProduce(petData, 1)
                                end)
                                
                                if success then
                                    local plainIncome = ToPlainNumber(income)
                                    
                                    if plainIncome > maxIncome then
                                        maxIncome = plainIncome
                                        bestPet = petInst
                                        
                                        -- ⭐ จัดหมวดหมู่เฉพาะสัตว์บก (Farm Pets)
                                        if isElite then
                                            petCategory = "EliteFarm"
                                        else
                                            petCategory = "Farm"
                                        end
                                    end
                                end
                            end
                        end

                        if bestPet then
                            if LocalPlayer:GetAttribute("HoldUID") == nil then
                                game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("CharacterRE"):FireServer("Focus", bestPet.Name)
                                task.wait(.3)
                            else
                                local placedSuccessfully = false
                                
                                -- ⭐ วางเฉพาะสัตว์บกเท่านั้น
                                if petCategory == "EliteFarm" then
                                    if #EliteFarmBlocks > 0 then
                                        local pos = EliteFarmBlocks[eliteIndex].Position
                                        local args = {
                                            "Place",
                                            {
                                                ["DST"] = pos,
                                                ["ID"] = LocalPlayer:GetAttribute("HoldUID")
                                            }
                                        }
                                        game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("CharacterRE"):FireServer(unpack(args))
                                        
                                        eliteIndex = eliteIndex + 1
                                        if eliteIndex > #EliteFarmBlocks then
                                            eliteIndex = 1
                                        end
                                        placedSuccessfully = true
                                    end
                                    
                                elseif petCategory == "Farm" then
                                    if #FarmPet > 0 then
                                        local pos = FarmPet[normalIndex].Position
                                        local ohTable2 = {
                                            ["DST"] = pos + Vector3.new(0, 10, 0),
                                            ["ID"] = LocalPlayer:GetAttribute("HoldUID")
                                        }
                                        game:GetService("ReplicatedStorage").Remote.CharacterRE:FireServer("Place", ohTable2)

                                        normalIndex = normalIndex + 1
                                        if normalIndex > #FarmPet then
                                            normalIndex = 1
                                        end
                                        placedSuccessfully = true
                                    end
                                end
                                
                                if not placedSuccessfully then
                                    print(string.format("No available slots for %s pets!", petCategory))
                                end
                            end
                        else
                            print("No farm pets available to place!")
                        end
                    end
                end)
            end)
        end
    end
})

local AutoPlaceOceanBest = Tab:Toggle({
    Title = "tr:AutoPlaceOceanBest",
    Value = getgenv().Settings.Utility.Premium.AutoPlaceOceanBest,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Utility.Premium.AutoPlaceOceanBest = Value
        SaveSetting()

        if Value then
            task.spawn(function()
                pcall(function()
                    local index = 1
                    while getgenv().Settings.Utility.Premium.AutoPlaceOceanBest do task.wait(.5)
                        local OceanPets = {
                            "Swordfish",
                            "Shark",
                            "Dolphin",
                            "AngelFish",
                            "Catfish",
                            "Bighead",
                            "Flounder",
                            "Alligator",
                            "Hairtail",
                            "Butterflyfish",
                            "Needlefish",
                            "ElectricEel",
                            "Manta",
                            "Whale",
                            "JellyFish",
                            "Starfish",
                            "OceanSunfish",
                            "SeaSlug",
                            "PirateCrab",
                            "Narwhal",
                            "Seahorse",
                            "Lobster"
                        }

                        local Players = game:GetService("Players")
                        local LocalPlayer = Players.LocalPlayer
                        local playerData = LocalPlayer.PlayerGui:FindFirstChild("Data")
                        local PetsFolder = playerData:FindFirstChild("Pets")

                        local ReplicatedStorage = game:GetService("ReplicatedStorage")
                        local SharedModule = ReplicatedStorage:WaitForChild("Shared")
                        local PetModule = require(SharedModule)("Pet")

                        for _, v in pairs(workspace.PlayerBuiltBlocks:GetChildren()) do
                            local p = tonumber(string.match(v.Name, "%d+"))
                            if p == game.Players.LocalPlayer.UserId then
                                local data = v.Value
                                if typeof(data) == "string" then
                                    local success, decoded = pcall(function()
                                        return HttpService:JSONDecode(data)
                                    end)

                                    if success and typeof(decoded) == "table" and decoded[1] and decoded[1].UID then
                                        local uid = decoded[1].UID
                                        getgenv().A = uid
                                    else
                                        getgenv().A = nil
                                    end
                                end
                            end
                        end

                        local function ToPlainNumber(value)
                            if type(value) == "string" then
                                value = value:gsub(",", "")
                                value = tonumber(value)
                            end
                            return math.floor(value or 0)
                        end

                        local oceanSet = {}
                        for _, petName in ipairs(OceanPets) do
                            oceanSet[petName] = true
                            oceanSet[petName:lower()] = true
                        end

                        local deployedPets = {}
                        local workspacePets = workspace:FindFirstChild("Pets")
                        if workspacePets then
                            for _, pet in pairs(workspacePets:GetChildren()) do
                                deployedPets[pet.Name] = true
                            end
                        end

                        local currentHoldUID = LocalPlayer:GetAttribute("HoldUID")
                        if currentHoldUID and deployedPets[currentHoldUID] then
                            game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("CharacterRE"):FireServer("Focus")
                            task.wait(.2)
                        end

                        local maxIncome = 0
                        local bestPet = nil
                        local category = "Ocean"

                        for _, petInst in pairs(PetsFolder:GetChildren()) do

                            local uid = tostring(petInst.Name)
                            if uid == getgenv().A then
                                continue
                            end

                            if not deployedPets[petInst.Name] then
                                local petType = petInst:GetAttribute("T")
                                local isOcean = oceanSet[petType] or oceanSet[tostring(petType):lower()]
                                
                                local isMatch = false
                                if category == "Mountain" then
                                    isMatch = not isOcean
                                elseif category == "Ocean" then
                                    isMatch = isOcean
                                end
                                
                                if isMatch then
                                    local petData = {}
                                    for attrName, attrValue in pairs(petInst:GetAttributes()) do
                                        petData[attrName] = attrValue
                                    end
                                    
                                    local success, income = pcall(function()
                                        return PetModule:GetPetProduce(petData, 1)
                                    end)
                                    
                                    if success then
                                        local plainIncome = ToPlainNumber(income)
                                        if plainIncome > maxIncome then
                                            maxIncome = plainIncome
                                            bestPet = petInst
                                        end
                                    end
                                end
                            end
                        end

                        if bestPet then
                            if LocalPlayer:GetAttribute("HoldUID") == nil then
                                game:GetService("ReplicatedStorage"):WaitForChild("Remote"):WaitForChild("CharacterRE"):FireServer("Focus", bestPet.Name)
                                task.wait(.2)
                            else
                                if #WaterPet > 0 then
                                    local holdUID = game.Players.LocalPlayer:GetAttribute("HoldUID")
                                    if not holdUID then
                                        continue
                                    end

                                    local pos = WaterPet[index].Position
                                    local ohTable2 = {
                                        ["DST"] = pos + Vector3.new(0, 10, 0),
                                        ["ID"] = holdUID
                                    }

                                    game:GetService("ReplicatedStorage").Remote.CharacterRE:FireServer("Place", ohTable2)

                                    index = index + 1
                                    if index > #WaterPet then
                                        index = 1
                                    end
                                end
                            end
                        else
                            print(string.format("No %s pets available!", category))
                        end
                    end
                end)
            end)
        end
    end
})

local ReplaceSection = Tab:Section({ Title = "tr:ReplaceBest", Icon = "layout-template"})

AutoReplacePet = Tab:Toggle({
    Title = "tr:AutoReplacePet",
    Value = getgenv().Settings.Utility.Premium.AutoReplacePet,
    Icon = "refresh-cw",
    Callback = function(Value)
        getgenv().Settings.Utility.Premium.AutoReplacePet = Value
        SaveSetting()

        if Value then
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.Utility.Premium.AutoReplacePet do 
                        task.wait(.5)
                        
                        local OceanPets = {
                            "Swordfish", "Shark", "Dolphin", "AngelFish", "Catfish",
                            "Bighead", "Flounder", "Alligator", "Hairtail", "Butterflyfish",
                            "Needlefish", "ElectricEel", "Manta", "Whale", "JellyFish",
                            "Starfish", "OceanSunfish"
                        }

                        local Players = game:GetService("Players")
                        local LocalPlayer = Players.LocalPlayer
                        local playerData = LocalPlayer.PlayerGui:FindFirstChild("Data")
                        local PetsFolder = playerData:FindFirstChild("Pets")

                        local ReplicatedStorage = game:GetService("ReplicatedStorage")
                        local SharedModule = ReplicatedStorage:WaitForChild("Shared")
                        local PetModule = require(SharedModule)("Pet")

                        local function ToPlainNumber(value)
                            if type(value) == "string" then
                                value = value:gsub(",", "")
                                value = tonumber(value)
                            end
                            return math.floor(value or 0)
                        end

                        local oceanSet = {}
                        for _, petName in ipairs(OceanPets) do
                            oceanSet[petName] = true
                            oceanSet[petName:lower()] = true
                        end

                        local function GetPetCategory(petType, isElite)
                            local isOcean = oceanSet[petType] or oceanSet[petType:lower()]
                            if isOcean then
                                return isElite and "EliteOcean" or "Ocean"
                            else
                                return isElite and "EliteFarm" or "Farm"
                            end
                        end

                        local deployedPetsList = {}
                        local workspacePets = workspace:FindFirstChild("Pets")
                        
                        if workspacePets then
                            for _, petModel in pairs(workspacePets:GetChildren()) do
                                local uid = petModel.Name
                                
                                local petInst = PetsFolder:FindFirstChild(uid)
                                
                                if petInst then
                                    local petType = petInst:GetAttribute("T")
                                    local isElite = petInst:GetAttribute("Elite")
                                    local bigPetType = petModel:GetAttribute("BigPetType")
                                    
                                    if not bigPetType then
                                        local petData = {}
                                        for attrName, attrValue in pairs(petInst:GetAttributes()) do
                                            petData[attrName] = attrValue
                                        end
                                        
                                        local success, income = pcall(function()
                                            return PetModule:GetPetProduce(petData, 1)
                                        end)
                                        
                                        if success then
                                            local plainIncome = ToPlainNumber(income)
                                            local category = GetPetCategory(petType, isElite)
                                            
                                            local isOcean = oceanSet[petType] or oceanSet[petType:lower()]
                                            
                                            if not isOcean then
                                                local petPosition = petModel.Position
                                                
                                                table.insert(deployedPetsList, {
                                                    UID = uid,
                                                    Type = petType,
                                                    Category = category,
                                                    Income = plainIncome,
                                                    Position = petPosition,
                                                    Model = petModel
                                                })
                                            end
                                        end
                                    end
                                end
                            end
                        end

                        if #deployedPetsList > 0 then
                            table.sort(deployedPetsList, function(a, b)
                                return a.Income < b.Income
                            end)
                            
                            local worstPet = deployedPetsList[1]
                            local savedPosition = worstPet.Position
                            
                            local deployedPets = {}
                            for _, pet in ipairs(deployedPetsList) do
                                deployedPets[pet.UID] = true
                            end
                            
                            local inventoryPets = {}
                            local maxInventoryIncome = 0
                            
                            for _, petInst in pairs(PetsFolder:GetChildren()) do
                                local uid = tostring(petInst.Name)
                                
                                if not deployedPets[uid] then
                                    local petType = petInst:GetAttribute("T")
                                    local isElite = petInst:GetAttribute("Elite")
                                    
                                    local isOcean = oceanSet[petType] or oceanSet[petType:lower()]
                                    
                                    if not isOcean then
                                        local petData = {}
                                        for attrName, attrValue in pairs(petInst:GetAttributes()) do
                                            petData[attrName] = attrValue
                                        end
                                        
                                        local success, income = pcall(function()
                                            return PetModule:GetPetProduce(petData, 1)
                                        end)
                                        
                                        if success then
                                            local plainIncome = ToPlainNumber(income)
                                            local category = GetPetCategory(petType, isElite)
                                            
                                            if plainIncome > maxInventoryIncome then
                                                maxInventoryIncome = plainIncome
                                            end
                                            
                                            if plainIncome > worstPet.Income and category == worstPet.Category then
                                                table.insert(inventoryPets, {
                                                    UID = uid,
                                                    Type = petType,
                                                    Category = category,
                                                    Income = plainIncome,
                                                    Instance = petInst
                                                })
                                            end
                                        end
                                    end
                                end
                            end
                            
                            local RemoteEvent = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("CharacterRE")
                            
                            if #inventoryPets > 0 then
                                table.sort(inventoryPets, function(a, b)
                                    return a.Income > b.Income
                                end)
                                
                                local bestInInventory = inventoryPets[1]
                                
                                RemoteEvent:FireServer("Del", worstPet.UID, bit32.bxor(LocalPlayer.UserId, ReplicatedStorage.Time:GetAttribute("s"), ReplicatedStorage.Time.Value))
                                task.wait(.5)
                                
                                RemoteEvent:FireServer("Focus", bestInInventory.UID)
                                task.wait(.3)
                                
                                local args = {
                                    "Place",
                                    {
                                        ["DST"] = savedPosition,
                                        ["ID"] = bestInInventory.UID
                                    }
                                }
                                RemoteEvent:FireServer(unpack(args))
                                task.wait(.5)
                            elseif worstPet.Income < maxInventoryIncome then
                                RemoteEvent:FireServer("Del", worstPet.UID, bit32.bxor(LocalPlayer.UserId, ReplicatedStorage.Time:GetAttribute("s"), ReplicatedStorage.Time.Value))
                                task.wait(.5)
                            end
                        end
                    end
                end)
            end)
        end
    end
})

AutoReplaceFish = Tab:Toggle({
    Title = "tr:AutoReplaceFish",
    Value = getgenv().Settings.Utility.Premium.AutoReplaceFish,
    Icon = "fish",
    Callback = function(Value)
        getgenv().Settings.Utility.Premium.AutoReplaceFish = Value
        SaveSetting()

        if Value then
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.Utility.Premium.AutoReplaceFish do 
                        task.wait(.5)
                        
                        local OceanPets = {
                            "Swordfish", "Shark", "Dolphin", "AngelFish", "Catfish",
                            "Bighead", "Flounder", "Alligator", "Hairtail", "Butterflyfish",
                            "Needlefish", "ElectricEel", "Manta", "Whale", "JellyFish",
                            "Starfish", "OceanSunfish"
                        }

                        local Players = game:GetService("Players")
                        local LocalPlayer = Players.LocalPlayer
                        local playerData = LocalPlayer.PlayerGui:FindFirstChild("Data")
                        local PetsFolder = playerData:FindFirstChild("Pets")

                        local ReplicatedStorage = game:GetService("ReplicatedStorage")
                        local SharedModule = ReplicatedStorage:WaitForChild("Shared")
                        local PetModule = require(SharedModule)("Pet")

                        local function ToPlainNumber(value)
                            if type(value) == "string" then
                                value = value:gsub(",", "")
                                value = tonumber(value)
                            end
                            return math.floor(value or 0)
                        end

                        local oceanSet = {}
                        for _, petName in ipairs(OceanPets) do
                            oceanSet[petName] = true
                            oceanSet[petName:lower()] = true
                        end

                        local function GetPetCategory(petType, isElite)
                            local isOcean = oceanSet[petType] or oceanSet[petType:lower()]
                            if isOcean then
                                return isElite and "EliteOcean" or "Ocean"
                            else
                                return isElite and "EliteFarm" or "Farm"
                            end
                        end

                        local deployedPetsList = {}
                        local workspacePets = workspace:FindFirstChild("Pets")
                        
                        if workspacePets then
                            for _, petModel in pairs(workspacePets:GetChildren()) do
                                local uid = petModel.Name
                                
                                local petInst = PetsFolder:FindFirstChild(uid)
                                
                                if petInst then
                                    local petType = petInst:GetAttribute("T")
                                    local isElite = petInst:GetAttribute("Elite")
                                    
                                    local petData = {}
                                    for attrName, attrValue in pairs(petInst:GetAttributes()) do
                                        petData[attrName] = attrValue
                                    end
                                    
                                    local success, income = pcall(function()
                                        return PetModule:GetPetProduce(petData, 1)
                                    end)
                                    
                                    if success then
                                        local plainIncome = ToPlainNumber(income)
                                        local category = GetPetCategory(petType, isElite)
                                        
                                        local isOcean = oceanSet[petType] or oceanSet[petType:lower()]
                                        
                                        if isOcean then
                                            local petPosition = petModel.Position
                                            
                                            table.insert(deployedPetsList, {
                                                UID = uid,
                                                Type = petType,
                                                Category = category,
                                                Income = plainIncome,
                                                Position = petPosition,
                                                Model = petModel
                                            })
                                        end
                                    end
                                end
                            end
                        end

                        if #deployedPetsList > 0 then
                            table.sort(deployedPetsList, function(a, b)
                                return a.Income < b.Income
                            end)
                            
                            local worstPet = deployedPetsList[1]
                            local savedPosition = worstPet.Position
                            
                            local deployedPets = {}
                            for _, pet in ipairs(deployedPetsList) do
                                deployedPets[pet.UID] = true
                            end
                            
                            local inventoryPets = {}
                            local maxInventoryIncome = 0
                            
                            for _, petInst in pairs(PetsFolder:GetChildren()) do
                                local uid = tostring(petInst.Name)
                                
                                if not deployedPets[uid] then
                                    local petType = petInst:GetAttribute("T")
                                    local isElite = petInst:GetAttribute("Elite")
                                    
                                    local isOcean = oceanSet[petType] or oceanSet[petType:lower()]
                                    
                                    if isOcean then
                                        local petData = {}
                                        for attrName, attrValue in pairs(petInst:GetAttributes()) do
                                            petData[attrName] = attrValue
                                        end
                                        
                                        local success, income = pcall(function()
                                            return PetModule:GetPetProduce(petData, 1)
                                        end)
                                        
                                        if success then
                                            local plainIncome = ToPlainNumber(income)
                                            local category = GetPetCategory(petType, isElite)
                                            
                                            if plainIncome > maxInventoryIncome then
                                                maxInventoryIncome = plainIncome
                                            end
                                            
                                            if plainIncome > worstPet.Income and category == worstPet.Category then
                                                table.insert(inventoryPets, {
                                                    UID = uid,
                                                    Type = petType,
                                                    Category = category,
                                                    Income = plainIncome,
                                                    Instance = petInst
                                                })
                                            end
                                        end
                                    end
                                end
                            end
                            
                            local RemoteEvent = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("CharacterRE")
                            
                            if #inventoryPets > 0 then
                                table.sort(inventoryPets, function(a, b)
                                    return a.Income > b.Income
                                end)
                                
                                local bestInInventory = inventoryPets[1]
                                
                                RemoteEvent:FireServer("Del", worstPet.UID, bit32.bxor(LocalPlayer.UserId, ReplicatedStorage.Time:GetAttribute("s"), ReplicatedStorage.Time.Value))
                                task.wait(.5)
                                
                                RemoteEvent:FireServer("Focus", bestInInventory.UID)
                                task.wait(.3)
                                
                                local args = {
                                    "Place",
                                    {
                                        ["DST"] = savedPosition,
                                        ["ID"] = bestInInventory.UID
                                    }
                                }
                                RemoteEvent:FireServer(unpack(args))
                                task.wait(.5)
                            elseif worstPet.Income < maxInventoryIncome then
                                RemoteEvent:FireServer("Del", worstPet.UID, bit32.bxor(LocalPlayer.UserId, ReplicatedStorage.Time:GetAttribute("s"), ReplicatedStorage.Time.Value))
                                task.wait(.5)
                            end
                        end
                    end
                end)
            end)
        end
    end
})

AutoReplaceElite = Tab:Toggle({
    Title = "tr:AutoReplaceElite",
    Value = getgenv().Settings.Utility.Premium.AutoReplaceElite,
    Icon = "star",
    Callback = function(Value)
        getgenv().Settings.Utility.Premium.AutoReplaceElite = Value
        SaveSetting()

        if Value then
            task.spawn(function()
                pcall(function()
                    while getgenv().Settings.Utility.Premium.AutoReplaceElite do 
                        task.wait(.5)
                        
                        local OceanPets = {
                            "Swordfish", "Shark", "Dolphin", "AngelFish", "Catfish",
                            "Bighead", "Flounder", "Alligator", "Hairtail", "Butterflyfish",
                            "Needlefish", "ElectricEel", "Manta", "Whale", "JellyFish",
                            "Starfish", "OceanSunfish"
                        }

                        local Players = game:GetService("Players")
                        local LocalPlayer = Players.LocalPlayer
                        local playerData = LocalPlayer.PlayerGui:FindFirstChild("Data")
                        local PetsFolder = playerData:FindFirstChild("Pets")

                        local ReplicatedStorage = game:GetService("ReplicatedStorage")
                        local SharedModule = ReplicatedStorage:WaitForChild("Shared")
                        local PetModule = require(SharedModule)("Pet")

                        local function ToPlainNumber(value)
                            if type(value) == "string" then
                                value = value:gsub(",", "")
                                value = tonumber(value)
                            end
                            return math.floor(value or 0)
                        end

                        local oceanSet = {}
                        for _, petName in ipairs(OceanPets) do
                            oceanSet[petName] = true
                            oceanSet[petName:lower()] = true
                        end

                        local function GetPetCategory(petType, isElite)
                            local isOcean = oceanSet[petType] or oceanSet[petType:lower()]
                            if isOcean then
                                return isElite and "EliteOcean" or "Ocean"
                            else
                                return isElite and "EliteFarm" or "Farm"
                            end
                        end

                        local deployedPetsList = {}
                        local workspacePets = workspace:FindFirstChild("Pets")
                        
                        if workspacePets then
                            for _, petModel in pairs(workspacePets:GetChildren()) do
                                local uid = petModel.Name
                                
                                local petInst = PetsFolder:FindFirstChild(uid)
                                
                                if petInst then
                                    local petType = petInst:GetAttribute("T")
                                    local isElite = petInst:GetAttribute("Elite")
                                    
                                    if isElite then
                                        local petData = {}
                                        for attrName, attrValue in pairs(petInst:GetAttributes()) do
                                            petData[attrName] = attrValue
                                        end
                                        
                                        local success, income = pcall(function()
                                            return PetModule:GetPetProduce(petData, 1)
                                        end)
                                        
                                        if success then
                                            local plainIncome = ToPlainNumber(income)
                                            local category = GetPetCategory(petType, isElite)
                                            local petPosition = petModel.Position
                                            
                                            table.insert(deployedPetsList, {
                                                UID = uid,
                                                Type = petType,
                                                Category = category,
                                                Income = plainIncome,
                                                Position = petPosition,
                                                Model = petModel
                                            })
                                        end
                                    end
                                end
                            end
                        end

                        if #deployedPetsList > 0 then
                            table.sort(deployedPetsList, function(a, b)
                                return a.Income < b.Income
                            end)
                            
                            local worstPet = deployedPetsList[1]
                            local savedPosition = worstPet.Position
                            
                            local deployedPets = {}
                            for _, pet in ipairs(deployedPetsList) do
                                deployedPets[pet.UID] = true
                            end
                            
                            local inventoryPets = {}
                            local maxInventoryIncome = 0
                            
                            for _, petInst in pairs(PetsFolder:GetChildren()) do
                                local uid = tostring(petInst.Name)
                                
                                if not deployedPets[uid] then
                                    local petType = petInst:GetAttribute("T")
                                    local isElite = petInst:GetAttribute("Elite")
                                    
                                    if isElite then
                                        local petData = {}
                                        for attrName, attrValue in pairs(petInst:GetAttributes()) do
                                            petData[attrName] = attrValue
                                        end
                                        
                                        local success, income = pcall(function()
                                            return PetModule:GetPetProduce(petData, 1)
                                        end)
                                        
                                        if success then
                                            local plainIncome = ToPlainNumber(income)
                                            local category = GetPetCategory(petType, isElite)
                                            
                                            if plainIncome > maxInventoryIncome then
                                                maxInventoryIncome = plainIncome
                                            end
                                            
                                            if plainIncome > worstPet.Income and category == worstPet.Category then
                                                table.insert(inventoryPets, {
                                                    UID = uid,
                                                    Type = petType,
                                                    Category = category,
                                                    Income = plainIncome,
                                                    Instance = petInst
                                                })
                                            end
                                        end
                                    end
                                end
                            end
                            
                            local RemoteEvent = ReplicatedStorage:WaitForChild("Remote"):WaitForChild("CharacterRE")
                            
                            if #inventoryPets > 0 then
                                table.sort(inventoryPets, function(a, b)
                                    return a.Income > b.Income
                                end)
                                
                                local bestInInventory = inventoryPets[1]
                                
                                RemoteEvent:FireServer("Del", worstPet.UID, bit32.bxor(LocalPlayer.UserId, ReplicatedStorage.Time:GetAttribute("s"), ReplicatedStorage.Time.Value))
                                task.wait(.5)
                                
                                RemoteEvent:FireServer("Focus", bestInInventory.UID)
                                task.wait(.3)
                                
                                local args = {
                                    "Place",
                                    {
                                        ["DST"] = savedPosition,
                                        ["ID"] = bestInInventory.UID
                                    }
                                }
                                RemoteEvent:FireServer(unpack(args))
                                task.wait(.5)
                            elseif worstPet.Income < maxInventoryIncome then
                                RemoteEvent:FireServer("Del", worstPet.UID, bit32.bxor(LocalPlayer.UserId, ReplicatedStorage.Time:GetAttribute("s"), ReplicatedStorage.Time.Value))
                                task.wait(.5)
                            end
                        end
                    end
                end)
            end)
        end
    end
})

-- สร้างตรงนี้

task.spawn(function()
    while task.wait(1) do
        if not InfoWeather then
            break
        end

        local CurrentWeather = workspace:GetAttribute("Weather")
        local NextWeather = workspace:GetAttribute("NextWeather")
        local WeatherRemainingTime = workspace:GetAttribute("WeatherRemainingTime")
        local CurrentTranslation = "Current"
        local NextWeatherTranslation = "Next"

        local minutes = math.floor(WeatherRemainingTime / 60)
        local seconds = math.floor(WeatherRemainingTime % 60)
        
        local formattedTime = string.format("%02d:%02d", minutes, seconds)

        local WeatherRemainingTimeTranslation = "Time Left"

        InfoWeather:SetDesc(
        "<font color='#00D9FF'><b>▸".. CurrentTranslation.."</b></font>\n"..
        "<font color='#FFFFFF'>  └─ </font><font color='#7FFF00'><b>"..CurrentWeather.."</b></font>\n"..
        
        "<font color='#FF6B9D'><b>▸".. NextWeatherTranslation.."</b></font>\n"..
        "<font color='#FFFFFF'>  └─ </font><font color='#FFA500'><b>"..NextWeather.."</b></font>\n"..
        
        "<font color='#DA70D6'><b>▸".. WeatherRemainingTimeTranslation.."</b></font>\n"..
        "<font color='#FFFFFF'>  └─ </font><font color='#00FF94'><b>"..formattedTime.."</b></font>")
    end
end)



-- ============ Tsunami ============ ----

local TsunamiSection = Tab:Section({ Title = "tr:TsunamiTab", Icon = "waves"})

local SelectRarity = Tab:Dropdown({
   Title = "tr:SelectRarity",
   Multi = true,
   AllowNone = false,
   Value = getgenv().Settings.Utility.Premium.SelectRarity,
    Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "Divine", "Prismatic"},
    Callback = function(Value)
        getgenv().Settings.Utility.Premium.SelectRarity = Value
        SaveSetting()
    end
})

local IncomeMin = Tab:Input({
    Title = "tr:IncomeMin",
    Value = tonumber(getgenv().Settings.Utility.Premium.IncomeMin),
    Placeholder = "0",
    Callback = function(Value)
        getgenv().Settings.Utility.Premium.IncomeMin = tonumber(Value)
        SaveSetting()
    end
})

local IncomeMax = Tab:Input({
    Title = "tr:IncomeMax",
    Value = tonumber(getgenv().Settings.Utility.Premium.IncomeMax),
    Placeholder = "100",
    Callback = function(Value)
        getgenv().Settings.Utility.Premium.IncomeMax = tonumber(Value)
        SaveSetting()
    end
})

local AutoFarmPet = Tab:Toggle({
    Title = "tr:AutoFarmPet",
    Value = getgenv().Settings.Utility.Premium.AutoFarmPet,
    Icon = "check",
    Callback = function(Value)
        getgenv().Settings.Utility.Premium.AutoFarmPet = Value
        SaveSetting()

        if Value then
            task.spawn(function()
                local RarityConfigs = {
                    ["Common"] = CFrame.new(791, -24, 4059),
                    ["Uncommon"] = CFrame.new(742, -24, 4068),
                    ["Rare"] = CFrame.new(601, -24, 4065),
                    ["Epic"] = CFrame.new(400, -24, 4066),
                    ["Legendary"] = CFrame.new(120, -24, 4064),
                    ["Mythical"] = CFrame.new(-661, -24, 4072),
                    ["Divine"] = CFrame.new(-661, -24, 4072),
                    ["Prismatic"] = CFrame.new(-1224, -24, 4070),
                }

                local MapRarity = {
                    ["Common"] = "R1",
                    ["Uncommon"] = "R2",
                    ["Rare"] = "R3",
                    ["Epic"] = "R4",
                    ["Legendary"] = "R5",
                    ["Mythical"] = "R6",
                    ["Divine"] = "R7",
                    ["Prismatic"] = "R8",
                }

                local function TeleportToHome()
                    pcall(function()
                        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(851, -17, 4066)
                    end)
                end

                 local function IsWaveActive()
                    for _, v in pairs(workspace.Tsunami.Waves:GetDescendants()) do
                        if v:IsA("BasePart") then
                            return true
                        end
                    end
                    return false
                end

                while getgenv().Settings.Utility.Premium.AutoFarmPet do
                    local SelectedRarities = getgenv().Settings.Utility.Premium.SelectRarity
                    if type(SelectedRarities) ~= "table" then SelectedRarities = {SelectedRarities} end
                    local IncomeMin = getgenv().Settings.Utility.Premium.IncomeMin or 0
                    local IncomeMax = getgenv().Settings.Utility.Premium.IncomeMax or 1000000 
                    
                    for _, SelectRarity in pairs(SelectedRarities) do
                        if not getgenv().Settings.Utility.Premium.AutoFarmPet then break end

                        if RarityConfigs[SelectRarity] then
                            -- Check Wave Before Teleport
                            if IsWaveActive() then
                                game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = RarityConfigs[SelectRarity]
                                repeat task.wait(1) until not IsWaveActive() or not getgenv().Settings.Utility.Premium.AutoFarmPet
                            end
                            
                            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = RarityConfigs[SelectRarity]
                            task.wait(1)
                            
                            -- Check Wave After Arrive
                            if IsWaveActive() then
                                repeat task.wait(1) until not IsWaveActive() or not getgenv().Settings.Utility.Premium.AutoFarmPet
                            end

                            local Folder = workspace:WaitForChild("Tsunami"):WaitForChild("Gen"):FindFirstChild(MapRarity[SelectRarity])

                            if Folder then
                                for _, v in pairs(Folder:GetChildren()) do
                                    if not getgenv().Settings.Utility.Premium.AutoFarmPet then break end
                                    
                                    -- Check Wave Before Action
                                    if IsWaveActive() then
                                        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = RarityConfigs[SelectRarity]
                                        repeat task.wait(1) until not IsWaveActive() or not getgenv().Settings.Utility.Premium.AutoFarmPet
                                    end

                                    if v:FindFirstChild("RootPart") and v.RootPart:FindFirstChild("GUI/TsunamiPetGUI") then
                                        local GUI = v.RootPart["GUI/TsunamiPetGUI"]
                                        if GUI:FindFirstChild("Rarity") and GUI:FindFirstChild("Income") then
                                            local RarityText = GUI.Rarity.Text
                                            local IncomeText = GUI.Income.Text
                                            local CurrentIncome = tonumber(string.gsub(IncomeText, "[^%d]", "")) or 0

                                            if table.find(SelectedRarities, RarityText) and CurrentIncome >= IncomeMin and CurrentIncome <= IncomeMax then
                                                -- Final Wave Check
                                                 if IsWaveActive() then
                                                    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = RarityConfigs[SelectRarity]
                                                    repeat task.wait(1) until not IsWaveActive() or not getgenv().Settings.Utility.Premium.AutoFarmPet
                                                end
                                                
                                                game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = v.RootPart.CFrame
                                                task.wait(0.2)
                                                v.RootPart.RE:FireServer()
                                                task.wait(0.5)
                                                TeleportToHome()
                                                task.wait(1)
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    task.wait(.1)
                end
            end)
        end
    end
})


-- ============ Configuration ============ ----

Window:Divider()

local Tab = Window:Tab({
    Title = "Configuration",
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
        getgenv().ConfigurationTable.AntiAFK = enabled
        SaveConfiguration()

        if enabled then
            task.spawn(function()
                while getgenv().ConfigurationTable.AntiAFK do task.wait(700)
                    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
                    task.wait(0.1)
                    game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
                end
            end)
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
                if _G.E then
                    _G.E:Disconnect()
                    _G.E = nil
                end
                return
            end

            if _G.E then
                return
            end

            _G.E = game.CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
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

WindUI:Notify({
    Title = "Script | Loader",
    Content = "Script Loader Successfully",
    Icon = VenuzIcon,
    Duration = 5,
})
