local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Animation IDs (bat_smash played locally on input from AbilityInputController)
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
	track.Looped = false
	track.Priority = Enum.AnimationPriority.Action
	track:Stop(0)
	track:Play(0.05, 1, 1)
end

-- Expose for AbilityInputController: play animation on input (server no longer fires PlayAbility)
_G.playBatSmash = function()
	playAnim("bat_smash")
end
