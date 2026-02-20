local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Maps = require(Config:WaitForChild("Maps"))
local TrophyRules = require(Config:WaitForChild("TrophyRules"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestQueue = remotes:WaitForChild("RequestQueue")
local QueueStatus = remotes:WaitForChild("QueueStatus")
local MatchState = remotes:WaitForChild("MatchState")

local QueueService = {}

-- mapKey = mapId .. "|" .. tostring(ranked)
local queues = {}
local queuedKeyByUserId = {}

local function mapExists(mapId)
	for _, m in ipairs(Maps.List) do
		if m.id == mapId then return true end
	end
	return false
end

local function sendQueueStatus(player, ok, reason, payload)
	QueueStatus:FireClient(player, {
		ok = ok,
		reason = reason or "",
		state = payload,
	})
end

local function removeFromQueue(userId)
	local key = queuedKeyByUserId[userId]
	if not key then return end
	queuedKeyByUserId[userId] = nil

	local q = queues[key]
	if not q then return end

	for i = #q, 1, -1 do
		if q[i] == userId then
			table.remove(q, i)
			break
		end
	end

	if #q == 0 then
		queues[key] = nil
	end
end

local function broadcastMatchFound(mapId, ranked, userIds)
	for i, uid in ipairs(userIds) do
		local player = Players:GetPlayerByUserId(uid)
		if player then
			local team = (i <= 6) and "A" or "B"
			MatchState:FireClient(player, {
				phase = "match_found",
				mapId = mapId,
				ranked = ranked,
				team = team,
			})
		end
	end
end

local function tryMakeMatch(queueKey)
	local q = queues[queueKey]
	if not q or #q < 12 then return end

	local picked = {}
	for i = 1, 12 do
		table.insert(picked, table.remove(q, 1))
	end

	for _, uid in ipairs(picked) do
		queuedKeyByUserId[uid] = nil
	end

	if #q == 0 then
		queues[queueKey] = nil
	end

	local mapId, rankedStr = queueKey:match("^(.-)|(.+)$")
	local ranked = (rankedStr == "true")

	broadcastMatchFound(mapId, ranked, picked)
end

RequestQueue.OnServerEvent:Connect(function(player, mapId)
	if type(mapId) ~= "string" then
		return sendQueueStatus(player, false, "bad_map")
	end
	if not mapExists(mapId) then
		return sendQueueStatus(player, false, "unknown_map")
	end

	local profile = PlayerDataService:Get(player.UserId)
	local trophies = tonumber(profile.trophies) or 0
	local rankedUnlocked = TrophyRules.isRankedUnlocked(trophies)

	if (not rankedUnlocked) and (not TrophyRules.isMapUnlocked(mapId, trophies)) then
		return sendQueueStatus(player, false, "map_locked")
	end

	removeFromQueue(player.UserId)

	local ranked = rankedUnlocked
	local key = mapId .. "|" .. tostring(ranked)

	queues[key] = queues[key] or {}
	table.insert(queues[key], player.UserId)
	queuedKeyByUserId[player.UserId] = key

	sendQueueStatus(player, true, "", {
		queued = true,
		mapId = mapId,
		ranked = ranked,
		queuedCount = #queues[key],
	})

	tryMakeMatch(key)
end)

Players.PlayerRemoving:Connect(function(player)
	removeFromQueue(player.UserId)
end)

return QueueService
