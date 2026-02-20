-- ServerScriptService/Server/ProfileRemotes

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Make sure remotes exist
require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("EnsureRemotes"))

-- Services
local PlayerDataService = require(script.Parent:WaitForChild("Services"):WaitForChild("PlayerDataService"))

-- Shared rules
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Maps = require(Config:WaitForChild("Maps"))
local TrophyRules = require(Config:WaitForChild("TrophyRules"))

-- Remotes
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetLobbyState = remotes:WaitForChild("GetLobbyState")
local GetProfile = remotes:WaitForChild("GetProfile")
local AddTrophies = remotes:WaitForChild("AddTrophies")

-- Simple profile for UI/other calls
GetProfile.OnServerInvoke = function(player)
	local data = PlayerDataService:Get(player.UserId)
	local trophies = data.trophies or 0

	return {
		trophies = trophies,
		selectedBrainrotId = data.selectedBrainrotId,
		rankedUnlocked = TrophyRules.isRankedUnlocked(trophies),
	}
end

-- Full lobby state (maps + unlocks)
GetLobbyState.OnServerInvoke = function(player)
	local data = PlayerDataService:Get(player.UserId)
	local trophies = data.trophies or 0
	local rankedUnlocked = TrophyRules.isRankedUnlocked(trophies)

	local unlockedMaps = {}
	local availableMaps = {}

	for _, m in ipairs(Maps.List) do
		local unlocked = TrophyRules.isMapUnlocked(m.id, trophies) or rankedUnlocked
		unlockedMaps[m.id] = unlocked

		if unlocked then
			table.insert(availableMaps, {
				id = m.id,
				name = m.name,
				trophyReward = m.trophyReward,
			})
		end
	end

	return {
		trophies = trophies,
		selectedBrainrotId = data.selectedBrainrotId,
		rankedUnlocked = rankedUnlocked,
		unlockedMaps = unlockedMaps,
		availableMaps = availableMaps,
	}
end

-- Debug/admin: adds trophies (server-authoritative)
AddTrophies.OnServerEvent:Connect(function(player, amount)
	if typeof(amount) ~= "number" then return end
	if amount ~= amount then return end -- NaN guard
	amount = math.floor(amount)
	if amount == 0 then return end

	PlayerDataService:IncrementTrophies(player, amount)
	PlayerDataService:Save(player) -- immediate persist for testing
end)

print("✅ ProfileRemotes ready: GetLobbyState/GetProfile/AddTrophies")
