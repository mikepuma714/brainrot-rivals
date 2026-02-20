local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Ensure remotes exist (must return something; yours now returns true)
require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("EnsureRemotes"))

local PlayerDataService = require(ServerScriptService.Server:WaitForChild("Services"):WaitForChild("PlayerDataService"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")

local GetProfile = remotes:WaitForChild("GetProfile")
local AddTrophies = remotes:WaitForChild("AddTrophies")

GetProfile.OnServerInvoke = function(player)
	local data = PlayerDataService:Get(player.UserId)

	return {
		trophies = data.trophies or 0,
		unlockedMap = 1, -- we'll compute properly next step
		ranked = (data.trophies or 0) >= 120,
		selectedBrainrotId = data.selectedBrainrotId or "tung_tung_sahur",
	}
end

AddTrophies.OnServerEvent:Connect(function(player, amount)
	if typeof(amount) ~= "number" then return end
	PlayerDataService:IncrementTrophies(player, amount)
end)

print("[ProfileRemotes] Now using PlayerDataService (single source of truth)")
