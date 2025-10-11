local player = game.Players.LocalPlayer
local char = player.Character
if char then
    local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
     if rootPart then
        local pos = rootPart.Position
         local roundedPos = math.round(pos.X) .. ", " .. math.round(pos.Y) .. ", " .. math.round(pos.Z)
          setclipboard(roundedPos)
     end
 end