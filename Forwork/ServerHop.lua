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