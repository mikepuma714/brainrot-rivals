local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetProfile = Remotes:WaitForChild("GetProfile")
local AddTrophies = Remotes:WaitForChild("AddTrophies")
local SetSelectedMap = Remotes:WaitForChild("SetSelectedMap")
local RequestQueue = Remotes:WaitForChild("RequestQueue")
local QueueStatus = Remotes:WaitForChild("QueueStatus")
local MatchState = Remotes:WaitForChild("MatchState")
local DebugAddScore = Remotes:WaitForChild("DebugAddScore")
local ScoreUpdate = Remotes:WaitForChild("ScoreUpdate")

local player = Players.LocalPlayer
local queueState = { queued = false, reason = "", mapId = nil }
local lastScore = { A = 0, B = 0 }

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotDebugGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 360, 0, 500)
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

local headerLabel = Instance.new("TextLabel")
headerLabel.Name = "Header"
headerLabel.Size = UDim2.new(1, -20, 0, 64)
headerLabel.Position = UDim2.new(0, 10, 0, 50)
headerLabel.BackgroundTransparency = 1
headerLabel.TextSize = 14
headerLabel.TextWrapped = true
headerLabel.TextXAlignment = Enum.TextXAlignment.Left
headerLabel.TextYAlignment = Enum.TextYAlignment.Top
headerLabel.Font = Enum.Font.Gotham
headerLabel.Text = "Loading..."
headerLabel.Parent = frame

local mapListFrame = Instance.new("Frame")
mapListFrame.Name = "MapList"
mapListFrame.Size = UDim2.new(1, -20, 0, 130)
mapListFrame.Position = UDim2.new(0, 10, 0, 118)
mapListFrame.BackgroundTransparency = 1
mapListFrame.ClipsDescendants = true
mapListFrame.Parent = frame

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
		string.format("Trophies: %d | Ranked: %s | Selected: %s", num(state.trophies), tostring(state.rankedUnlocked == true), tostring(state.selectedMapId or "—")),
		"Queued: " .. tostring(queueState.queued),
	}
	if queueState.reason and queueState.reason ~= "" then
		table.insert(lines, "Queue Error: " .. tostring(queueState.reason))
	end
	local lastMatch = _G.__lastMatchFound
	if lastMatch and lastMatch.phase == "match_found" then
		table.insert(lines, string.format("Match: FOUND | Map: %s | Team: %s", tostring(lastMatch.mapId or "—"), tostring(lastMatch.team or "—")))
	end
	local matchOver = _G.__lastMatchOver
	if matchOver and matchOver.winner then
		table.insert(lines, string.format("Match: OVER | Winner: Team %s", tostring(matchOver.winner)))
	end
	table.insert(lines, string.format("Score: A %d - %d B", lastScore.A, lastScore.B))
	headerLabel.Text = table.concat(lines, "\n")

	-- Clear existing map buttons
	for _, child in ipairs(mapListFrame:GetChildren()) do
		child:Destroy()
	end

	local selectedMapId = state.selectedMapId or "brainrot_island"
	local y = 0
	local rowHeight = 26

	for _, map in ipairs(state.availableMaps or {}) do
		local reward = num(map.trophyReward)
		local unlockAt = num(map.unlockAt)
		local mark = (map.unlocked == true) and "✅" or "❌"
		local isSelected = (map.id == selectedMapId)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, rowHeight - 2)
		btn.Position = UDim2.new(0, 0, 0, y)
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 12
		btn.Text = string.format("%s %s (Reward: %d, UnlockAt: %d) %s", isSelected and "► " or "  ", tostring(map.name or map.id), reward, unlockAt, mark)
		btn.BackgroundTransparency = isSelected and 0.5 or 0.8
		btn.Parent = mapListFrame
		if map.unlocked == true then
			btn.MouseButton1Click:Connect(function()
				SetSelectedMap:FireServer(map.id)
				task.wait(0.1)
				refresh()
			end)
		end
		y = y + rowHeight
	end
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

makeButton("Queue", 310, function()
	local state = GetProfile:InvokeServer()
	local mapId = state.selectedMapId or "brainrot_island"
	RequestQueue:FireServer(mapId)
end)

makeButton("Refresh", 355, function()
	refresh()
end)

makeButton("A +1", 400, function()
	DebugAddScore:FireServer("A")
end)

makeButton("B +1", 445, function()
	DebugAddScore:FireServer("B")
end)

ScoreUpdate.OnClientEvent:Connect(function(s)
	if type(s) ~= "table" then return end
	lastScore.A = tonumber(s.A) or 0
	lastScore.B = tonumber(s.B) or 0
	refresh()
end)

QueueStatus.OnClientEvent:Connect(function(msg)
	queueState.queued = (msg.state and msg.state.queued == true) or false
	queueState.reason = (type(msg.reason) == "string") and msg.reason or ""
	queueState.mapId = (msg.state and msg.state.mapId) or nil
	refresh()
end)

MatchState.OnClientEvent:Connect(function(msg)
	if not msg then return end
	if msg.phase == "match_found" then
		_G.__lastMatchFound = msg
		refresh()
	elseif msg.phase == "match_over" then
		_G.__lastMatchOver = { winner = msg.winner, mapId = msg.mapId }
		-- Update header immediately so "Match OVER" shows even if refresh() yields or errors
		local winner = tostring(msg.winner or "?")
		local existing = headerLabel.Text or ""
		if not existing:find("Match: OVER") then
			headerLabel.Text = existing .. "\nMatch: OVER | Winner: Team " .. winner
		end
		task.defer(refresh)
	end
end)

refresh()
