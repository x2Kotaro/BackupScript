local UserId = game.Players.LocalPlayer.UserId
local count = 0

for i,v in pairs(game:GetService("Players")["1234DEe12348"].PlayerGui.Main.WantedPosterGui.Frame.Main.WantedItem:GetChildren()) do
    if v.Name == "WantedItem_Title" then
        v:GetPropertyChangedSignal("Text"):Connect(function()
            print(v.Text)
        end)
    end
end
