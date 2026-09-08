--[[
	autoexec_dexbridge.lua

	Copy this file into your executor's autoexec folder (Potassium: Potassium/autoexec/).
	The executor runs everything in there on every injection, so the bridge comes back by
	itself after a crash, a client relaunch or a manual re-inject - the three cases
	queue_on_teleport inside DexBridge.lua cannot cover, because they happen before any Lua
	of ours exists.

	It expects DexBridge.lua to sit in the executor's workspace folder. Set BridgeUrl below
	if you would rather serve it over HTTP and have updates land without touching the file.
]]

local BridgeFile = "DexBridge.lua"
local BridgeUrl = ""

task.spawn(function()
	if getgenv().DexBridgeStop then return end

	-- autoexec fires before the place has finished loading; the bridge needs a LocalPlayer
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end

	local Players = game:GetService("Players")

	while not Players.LocalPlayer do
		task.wait()
	end

	local Source

	if isfile and isfile(BridgeFile) then
		local Ok, Body = pcall(readfile, BridgeFile)

		if Ok then Source = Body end
	end

	if type(Source) ~= "string" and BridgeUrl ~= "" then
		local Ok, Body = pcall(game.HttpGet, game, BridgeUrl, true)

		if Ok then Source = Body end
	end

	if type(Source) ~= "string" or #Source == 0 then
		warn("[DexBridge autoexec] no bridge source - put " .. BridgeFile .. " in the executor workspace or set BridgeUrl")

		return
	end

	local Chunk, Err = loadstring(Source, "=DexBridge")

	if not Chunk then
		warn("[DexBridge autoexec] bridge did not compile: " .. tostring(Err))

		return
	end

	Chunk()
end)
