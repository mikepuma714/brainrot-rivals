local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestAbility = remotes:WaitForChild("RequestAbility")

local AbilitiesFolder = script.Parent:WaitForChild("Abilities")
local AbilityModules = {
	bat_smash = require(AbilitiesFolder:WaitForChild("BatSmash")),
}

RequestAbility.OnServerEvent:Connect(function(player: Player, payload)
	if typeof(payload) ~= "table" then return end
	local abilityId = payload.abilityId
	if type(abilityId) ~= "string" then return end

	local ability = AbilityModules[abilityId]
	if ability then
		ability:Execute(player)
	end
end)

return {}
