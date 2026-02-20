local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Maps = require(Config:WaitForChild("Maps"))
local TrophyRules = require(Config:WaitForChild("TrophyRules"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestQueue = remotes:WaitForChild("RequestQueue")
local QueueStatus = remotes:WaitForChild("QueueStatus")

local QueueService = {}

local queued: {[number]: { mapId: string, ranked: boolean }} = {}

local function mapExists(mapId)
	for _, m in ipairs(Maps.List) do
		if m.id == mapId then return true end
	end
	return false
end

local function send(player, ok, reason, payload)
	QueueStatus:FireClient(player, {
		ok = ok,
		reason = reason or "",
		state = payload,
	})
end

RequestQueue.OnServerEvent:Connect(function(player, mapId)
	if type(mapId) ~= "string" then
		return send(player, false, "bad_map")
	end
	if not mapExists(mapId) then
		return send(player, false, "unknown_map")
	end

	local profile = PlayerDataService:Get(player.UserId)
	local trophies = tonumber(profile.trophies) or 0
	local rankedUnlocked = TrophyRules.isRankedUnlocked(trophies)

	if (not rankedUnlocked) and (not TrophyRules.isMapUnlocked(mapId, trophies)) then
		return send(player, false, "map_locked")
	end

	queued[player.UserId] = { mapId = mapId, ranked = rankedUnlocked }

	return send(player, true, "", { queued = true, mapId = mapId, ranked = rankedUnlocked })
end)

return QueueService
