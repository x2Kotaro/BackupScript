local HttpService = game:GetService("HttpService")
local checkexecutor = identifyexecutor()
local Hwid = game:GetService("RbxAnalyticsService"):GetClientId()

getgenv().LicenseKey = ""

if not getgenv().LicenseKey then
    getgenv().LicenseKey = ""
end

-- if checkexecutor == "Xeno" then
--     game.Players.LocalPlayer:kick("Xeno not supported pls check 🟢﹕status in discord")
--     return
-- elseif checkexecutor == "Solara" then
--     game.Players.LocalPlayer:kick("Solara not supported pls check #status in discord")
--     return
-- end

local KeyFile = "Venuz Hub/KeySystem".."/".."VenuzKey"..".txt"

function CheckKey()
local res = http.request({
    Url = "https://pandadevelopment.net/v2_validation?key=".. getgenv().LicenseKey.."&service=venuzhub&hwid="..Hwid,
    Method = "GET",
    Headers = {
        ["Content-Type"] = "application/json"
    },
}).Body

local sucess, data = pcall(function()
    return HttpService:JSONDecode(res)
end)

if sucess then
    if data["V2_Authentication"] == "success" then
        if data["Key_Information"].Premium_Mode == true then
            print("Key Correct | Premium Mode")
        else
            print("Key Correct | Free Mode")
        end
    else
        print("Key Invalid")
    end
end
end

CheckKey()