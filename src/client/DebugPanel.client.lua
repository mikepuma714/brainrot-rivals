local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetProfile = Remotes:WaitForChild("GetProfile")
local AddTrophies = Remotes:WaitForChild("AddTrophies") -- debug only

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotDebugGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 360, 0, 320)
frame.Position = UDim2.new(0, 20, 0, 120)
frame.BackgroundTransparency = 0.2
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.TextScaled = true
title.Font = Enum.Font.GothamBlack
title.Text = "Brainrot Rivals Debug"
title.Parent = frame

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 160)
status.Position = UDim2.new(0, 10, 0, 50)
status.BackgroundTransparency = 1
status.TextScaled = false
status.TextSize = 14
status.TextWrapped = true
status.Font = Enum.Font.Gotham
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.Text = "Loading..."
status.Parent = frame

local function num(x)
	return (type(x) == "number") and x or 0
end

local function makeButton(text, y, onClick)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -20, 0, 40)
	btn.Position = UDim2.new(0, 10, 0, y)
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold
	btn.Text = text
	btn.Parent = frame
	btn.MouseButton1Click:Connect(onClick)
	return btn
end

local function refresh()
	local state = GetProfile:InvokeServer()
	local lines = {
		string.format("Trophies: %d | Ranked: %s", num(state.trophies), tostring(state.rankedUnlocked == true)),
		"Maps:",
	}
	for _, map in ipairs(state.availableMaps or {}) do
		local reward = num(map.trophyReward)
		local unlockAt = num(map.unlockAt)
		local mark = (map.unlocked == true) and "✅" or "❌"
		table.insert(lines, string.format("- %s (Reward: %d, UnlockAt: %d) %s", tostring(map.name or map.id), reward, unlockAt, mark))
	end
	status.Text = table.concat(lines, "\n")
end

makeButton("+3 Trophies (Map 1 Win)", 220, function()
	AddTrophies:FireServer(3)
	task.wait(0.1)
	refresh()
end)

makeButton("+20 Trophies (Unlock Test)", 265, function()
	AddTrophies:FireServer(20)
	task.wait(0.1)
	refresh()
end)

makeButton("Refresh", 310, function()
	refresh()
end)

refresh()
