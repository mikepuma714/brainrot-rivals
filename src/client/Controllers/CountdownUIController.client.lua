local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local MatchStateEvent = RemotesFolder:WaitForChild("MatchState")

-- UI
local function getOrCreateGui()
	local pg = player:WaitForChild("PlayerGui")

	local gui = pg:FindFirstChild("MatchCountdownGui")
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "MatchCountdownGui"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.Parent = pg
	end

	local label = gui:FindFirstChild("CountdownLabel")
	if not label then
		label = Instance.new("TextLabel")
		label.Name = "CountdownLabel"
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Position = UDim2.fromScale(0.5, 0.25)
		label.Size = UDim2.fromOffset(300, 120)
		label.BackgroundTransparency = 1
		label.TextScaled = true
		label.Font = Enum.Font.GothamBlack
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0.2
		label.Visible = false
		label.Parent = gui
	end

	return label
end

local label = getOrCreateGui()

-- countdown state
local countdownToken = 0

local function startCountdown(seconds: number)
	countdownToken += 1
	local token = countdownToken

	label.Visible = true

	for t = seconds, 1, -1 do
		if token ~= countdownToken then return end
		label.Text = tostring(t)
		task.wait(1)
	end

	if token ~= countdownToken then return end
	label.Text = "GO!"
	task.wait(0.6)

	if token ~= countdownToken then return end
	label.Visible = false
end

local function stopCountdown()
	countdownToken += 1
	label.Visible = false
end

MatchStateEvent.OnClientEvent:Connect(function(state)
	if type(state) ~= "table" then return end

	if state.phase == "countdown" then
		local seconds = tonumber(state.seconds) or 5
		task.spawn(function()
			startCountdown(seconds)
		end)
	elseif state.phase == "in_match" then
		stopCountdown()
	end
end)
