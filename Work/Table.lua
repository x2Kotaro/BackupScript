-- 
--  ขายของห้ามลบเด็ดขาด
-- 

local Knit = require(game:GetService("ReplicatedStorage").Shared.Packages.Knit)
local PC = Knit.GetController("PlayerController")
repeat task.wait() until PC.Replica

local inventory = PC.Replica.Data.Inventory

print("========== EQUIPMENTS (DEEP DIVE) ==========\n")

if inventory.Equipments and type(inventory.Equipments) == "table" then
    local equipCount = 0
    
    -- Loop ชั้นแรก
    for slot, data in pairs(inventory.Equipments) do
        print("Slot:", slot, "Type:", type(data))
        
        -- ถ้าเป็น table ให้ดูข้างใน
        if type(data) == "table" then
            equipCount = equipCount + 1
            print("  Equipment #" .. equipCount .. ":")
            
            -- Loop ข้างใน
            for key, value in pairs(data) do
                if type(value) == "table" then
                    print("    " .. tostring(key) .. " = {")
                    
                    -- Loop ชั้นที่ 3 (ถ้ามี)
                    for k, v in pairs(value) do
                        if type(v) == "table" then
                            print("      " .. tostring(k) .. " = {...} (nested table)")
                        else
                            print("      " .. tostring(k) .. " =", tostring(v))
                        end
                    end
                    
                    print("    }")
                else
                    print("    " .. tostring(key) .. " =", tostring(value))
                end
            end
            print("")
        end
    end
    
    print("Total equipment slots:", equipCount)
else
    print("Equipments not found or not a table")
end