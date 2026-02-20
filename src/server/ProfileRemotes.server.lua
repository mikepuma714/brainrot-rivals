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

-- Canonical Profile payload (locked contract). All fields guaranteed, no nils.
-- trophies: number, selectedBrainrotId: string, rankedUnlocked: boolean,
-- unlockedMap: number (count), availableMaps: { { id, name, trophyReward, unlockAt, unlocked } }
local function buildProfilePayload(player)
	local data = PlayerDataService:Get(player.UserId)
	local trophies = type(data.trophies) == "number" and data.trophies or 0
	local selectedBrainrotId = type(data.selectedBrainrotId) == "string" and data.selectedBrainrotId or "tung_tung_sahur"
	local rankedUnlocked = TrophyRules.isRankedUnlocked(trophies) == true

	local unlockedCount = 0
	local availableMaps = {}

	for _, m in ipairs(Maps.List) do
		local unlocked = TrophyRules.isMapUnlocked(m.id, trophies) or rankedUnlocked
		if unlocked then
			unlockedCount += 1
		end
		table.insert(availableMaps, {
			id = m.id,
			name = m.name or "",
			trophyReward = type(m.trophyReward) == "number" and m.trophyReward or 0,
			unlockAt = TrophyRules.getMapUnlockAt(m.id),
			unlocked = unlocked,
		})
	end

	return {
		trophies = trophies,
		selectedBrainrotId = selectedBrainrotId,
		rankedUnlocked = rankedUnlocked,
		unlockedMap = unlockedCount,
		availableMaps = availableMaps,
	}
end

GetProfile.OnServerInvoke = function(player)
	return buildProfilePayload(player)
end

GetLobbyState.OnServerInvoke = function(player)
	local payload = buildProfilePayload(player)
	-- Add unlockedMaps table for consumers that key by map id
	local unlockedMaps = {}
	for _, m in ipairs(payload.availableMaps) do
		unlockedMaps[m.id] = m.unlocked
	end
	payload.unlockedMaps = unlockedMaps
	return payload
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
