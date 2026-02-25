local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlayAbility = remotes:WaitForChild("PlayAbility")

-- TEMP animation id placeholder (we'll replace once you publish the real animation)
local ANIMS = {
	bat_smash = "rbxassetid://73195248201536"
}

local function playAnim(abilityId: string)
	local char = player.Character
	if not char then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local animId = ANIMS[abilityId]
	if not animId or animId == "rbxassetid://0" then
		warn("[AbilityAnimation] Missing AnimationId for", abilityId)
		return
	end

	local anim = Instance.new("Animation")
	anim.AnimationId = animId

	local track = animator:LoadAnimation(anim)
	track:Play()
end

PlayAbility.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then return end
	local abilityId = payload.abilityId
	if type(abilityId) ~= "string" then return end
	playAnim(abilityId)
end)
