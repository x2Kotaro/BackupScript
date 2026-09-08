-- CWS_Directory.modules.Func
--
-- The live game strips CWS_Directory.modules after the client loads it, so the
-- saved place came back with an empty folder and CwsClient died on the first
-- `modules.settings.KeyBinds` read. Rebuilt from the call sites in CwsClient and
-- its CWS module; the signatures are what those two scripts actually use.

local Func = {}

-- Uniform float, used for sound pitch jitter, spread and damage rolls.
function Func.GetRandom(min: number, max: number): number
	return min + math.random() * (max - min)
end

function Func.Lerp(from: number, to: number, alpha: number): number
	return from + (to - from) * alpha
end

function Func.GetMagnitude(vector: Vector3): number
	return vector.Magnitude
end

function Func.Spawn(callback, ...)
	return task.spawn(callback, ...)
end

function Func.Wait(duration: number?)
	return task.wait(duration)
end

function Func.Delay(duration: number, callback, ...)
	return task.delay(duration, callback, ...)
end

function Func.ReplaceChar(text: string, index: number, character: string): string
	return string.sub(text, 1, index - 1) .. character .. string.sub(text, index + 1)
end

-- Yields for `duration`, but hands the caller a BindableEvent first so the wait can
-- be cut short (CWS.RemoteQueues fires and destroys these to cancel a reload).
-- Returns true when it was cancelled early.
function Func.QueueWait(duration: number, onQueued: ((BindableEvent) -> ())?): boolean
	local queue = Instance.new("BindableEvent")
	local cancelled = false

	local connection = queue.Event:Connect(function()
		cancelled = true
	end)

	if onQueued then
		onQueued(queue)
	end

	local deadline = os.clock() + duration
	while not cancelled and os.clock() < deadline do
		task.wait()
	end

	connection:Disconnect()
	pcall(function()
		queue:Destroy()
	end)

	return cancelled
end

return Func
