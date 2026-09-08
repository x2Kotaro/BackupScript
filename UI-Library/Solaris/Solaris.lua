local SolarisLib = loadstring(game:HttpGet("https://solarishub.dev/SolarisLib.lua"))()

local win = SolarisLib:New({
   Name = "SolarisLib",
   FolderToSave = "SolarisLibStuff"
})

local tab = win:Tab("Tab 1")

local sec = tab:Section("Elements")

sec:Button("Button", function()
   SolarisLib:Notification("Test", "This is a notification test.")
end)

local toggle = sec:Toggle("Toggle", false,"Toggle", function(t)
   print(t)
end)

local slider = sec:Slider("Slider", 0,25,0,2.5,"Slider", function(t)
   print(t)
end)

local dropdown = sec:Dropdown("Dropdown", {"a","b","c","d","e"},"","Dropdown", function(t)
   print(t)
end)

local multidropdown =sec:MultiDropdown("Multi Dropdown", {"a","b","c","d","e"},{"b", "c"},"Dropdown", function(t)
   print(table.concat(t, ", "))
end)

sec:Colorpicker("Colorpicker", Color3.fromRGB(255,255,255),"Colorpicker", function(t)
   print(t)
end)

sec:Textbox("Textbox", true, function(t)
   print(t)
end)

sec:Bind("Hold Bind", Enum.KeyCode.E, true, "BindHold", function(t)
   print(t)
end)

sec:Bind("Normal Bind", Enum.KeyCode.F, false, "BindNormal", function()
   print("Bind pressed")
end)

local label = sec:Label("Label")

local tab2 = win:Tab("Tab 2")