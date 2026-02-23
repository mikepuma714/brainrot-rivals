local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestAbility = remotes:WaitForChild("RequestAbility")

-- TEMP: Bat Smash mapped to key "F"
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.F then
		RequestAbility:FireServer({ abilityId = "bat_smash" })
	end
end)
