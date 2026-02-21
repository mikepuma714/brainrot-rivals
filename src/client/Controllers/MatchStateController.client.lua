local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local MatchStateEvent = RemotesFolder:WaitForChild("MatchState")

local DEFAULT_WALK_SPEED = 16
local DEFAULT_JUMP_POWER = 50

local function setMovementEnabled(enabled: boolean)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if enabled then
		humanoid.WalkSpeed = DEFAULT_WALK_SPEED
		humanoid.JumpPower = DEFAULT_JUMP_POWER
		humanoid.AutoRotate = true
	else
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.AutoRotate = false
	end
end

-- Handle respawn while frozen/unfrozen
player.CharacterAdded:Connect(function()
	-- default to enabled on spawn; server will send MatchState again if needed
	setMovementEnabled(true)
end)

MatchStateEvent.OnClientEvent:Connect(function(state)
	if type(state) ~= "table" then return end

	if state.phase == "countdown" then
		setMovementEnabled(false)
	elseif state.phase == "in_match" then
		setMovementEnabled(true)
	end
end)
