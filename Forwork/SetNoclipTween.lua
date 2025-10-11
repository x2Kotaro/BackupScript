function SetNoclip(state)
    if state then
        Clip = false
        if not Noclipping then
            Noclipping = RunService.Stepped:Connect(function()
                if speaker.Character then
                    for _, child in pairs(speaker.Character:GetDescendants()) do
                        if child:IsA("BasePart") and child.CanCollide then
                            child.CanCollide = false
                        end
                    end
                end
            end)
        end
    else
        Clip = true
        if Noclipping then
            Noclipping:Disconnect()
            Noclipping = nil
        end
        if speaker.Character then
            for _, child in pairs(speaker.Character:GetDescendants()) do
                if child:IsA("BasePart") then
                    child.CanCollide = true
                end
            end
        end
    end
end