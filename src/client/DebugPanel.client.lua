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
frame.Size = UDim2.new(0, 360, 0, 220)
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
status.Size = UDim2.new(1, -20, 0, 40)
status.Position = UDim2.new(0, 10, 0, 50)
status.BackgroundTransparency = 1
status.TextScaled = true
status.Font = Enum.Font.Gotham
status.Text = "Loading..."
status.Parent = frame

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
	local profile = GetProfile:InvokeServer()
	status.Text = string.format("Trophies: %d | Unlocked Map: %d | Ranked: %s",
		profile.trophies,
		profile.unlockedMap,
		tostring(profile.ranked)
	)
end

makeButton("+3 Trophies (Map 1 Win)", 100, function()
	AddTrophies:FireServer(3)
	task.wait(0.1)
	refresh()
end)

makeButton("+20 Trophies (Unlock Test)", 145, function()
	AddTrophies:FireServer(20)
	task.wait(0.1)
	refresh()
end)

makeButton("Refresh", 190, function()
	refresh()
end)

refresh()
