local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestAbility = remotes:WaitForChild("RequestAbility")

-- Bat Smash on F: play animation locally (smooth), then tell server to validate/apply damage
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.F then
		if _G.playBatSmash then
			_G.playBatSmash()
		end
		RequestAbility:FireServer({ abilityId = "bat_smash" })
	end
end)
