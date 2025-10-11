local Identifier = "venuzhub"
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local HWID = game:GetService("RbxAnalyticsService"):GetClientId()

function ValidateKey(key, serviceId, hwid)
    local validationUrl = "https://pandadevelopment.net/v2_validation"
        .. "?key=" .. tostring(key)
        .. "&service=" .. tostring(serviceId)
        .. "&hwid=" .. tostring(hwid)

    local success, response = pcall(function()
        return request({
            Url = validationUrl,
            Method = "GET"
        })
    end)

    if not success or not response then
        warn("[Pelinda Ov2.5] Request failed: " .. tostring(response))
        return false, "Request failed"
    end

    if not response.Success then
        warn("[Pelinda Ov2.5] HTTP Error: " .. tostring(response.StatusCode) .. " " .. tostring(response.StatusMessage))
        return false, "HTTP error"
    end

    local ok, jsonData = pcall(function()
        return game:GetService("HttpService"):JSONDecode(response.Body)
    end)

    if not ok or type(jsonData) ~= "table" then
        warn("[Pelinda Ov2.5] JSON decode failed")
        return false, "JSON decode error"
    end

    if tostring(jsonData["V2_Authentication"]) == "success" then
        local premium = type(jsonData["Key_Information"]) == "table" and jsonData["Key_Information"]["Premium_Mode"] == true

        if premium then
            pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/VenuzHub/Scripts/refs/heads/main/Plant.lua"))()
            end)
            return true, "Authenticated (Premium)"
        else
            LocalPlayer:Kick("เกมนี้เทสสำหรับพรีเมียมเท่านั้น.")
            return false, "Not premium"
        end
    else
        local reason = tostring(jsonData["reason"] or "Unknown reason")
        warn("[Pelinda Ov2.5] Authentication failed: " .. reason)
        return false, "Authentication failed: " .. reason
    end
end

-- Main
if getgenv().LicenseKey == "" then
    LocalPlayer:Kick("คีย์ไม่ถูกต้อง")
    return
end

local isValid, message = ValidateKey(getgenv().LicenseKey, Identifier, HWID)
if isValid then
    print("[Pelinda Ov2.5] Key is VALID. Welcome!")
else
    print("[Pelinda Ov2.5] Key is INVALID. " .. message)
end

getgenv().LicenseKey = ""
loadstring(game:HttpGet("https://raw.githubusercontent.com/x2Kotaro/Venuz-hub/main/PlantPremium.lua"))()