-- check inventory

local function CheckItem(itemName, mode)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local DataPlayer = ReplicatedStorage.Remotes.GetData:InvokeServer(game.Players.LocalPlayer)
    local Items = require(ReplicatedStorage.Scripts.Items.Items)
    
    local IndexMap = {}
    for name, data in pairs(Items) do
        IndexMap[data.Index] = name
    end
    
    for uuid, itemData in pairs(DataPlayer.Inventory) do
        local currentItemName = IndexMap[itemData.Index]
        if currentItemName == itemName then
            if mode == "value" then
                return true
            elseif mode == "name" then
                return uuid
            else
                return uuid
            end
        end
    end
    
    if mode == "value" then
        return false
    end
    
    return nil
end

game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Inventory"):FireServer(unpack({"UsableItem","8eef0f8d-fdf5-4505-9b0c-869407b49f1f"}))
