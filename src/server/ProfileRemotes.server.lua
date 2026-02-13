local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("EnsureRemotes"))

local ProfileService = require(script.Parent:WaitForChild("ProfileService"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local GetProfile = remotes:WaitForChild("GetProfile")
local AddTrophies = remotes:WaitForChild("AddTrophies")

GetProfile.OnServerInvoke = function(player)
	local p = ProfileService:Get(player)
	return {
		trophies = p.trophies,
		unlockedMap = p.unlockedMap,
		ranked = p.ranked,
	}
end

AddTrophies.OnServerEvent:Connect(function(player, amount)
	if typeof(amount) ~= "number" then return end
	ProfileService:AddTrophies(player, amount)
end)
