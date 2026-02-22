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

local MIN_PLAYERS = 2
local MAX_PLAYERS = 12
local COUNTDOWN_TIME = 10
local COUNTDOWN_TO_START = 5
local MATCH_DURATION = 60

-- mapKey = mapId .. "|" .. tostring(ranked)
local queues = {}
local queuedKeyByUserId = {}
local countdownRunning = {}

local function mapExists(mapId)
	for _, m in ipairs(Maps.List) do
		if m.id == mapId then return true end
	end
	return false
end

local function getMapReward(mapId)
	for _, m in ipairs(Maps.List) do
		if m.id == mapId then
			return tonumber(m.trophyReward) or 0
		end
	end
	return 0
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

-- Teams auto-balance: first half A, second half B
local function broadcastMatchFound(mapId, ranked, userIds)
	local half = math.ceil(#userIds / 2)
	for i, uid in ipairs(userIds) do
		local player = Players:GetPlayerByUserId(uid)
		if player then
			local team = (i <= half) and "A" or "B"
			MatchState:FireClient(player, {
				phase = "match_found",
				mapId = mapId,
				ranked = ranked,
				team = team,
			})
		end
	end
end

local function endMatch(picked, mapId, winnerTeam)
	for _, plr in ipairs(picked) do
		if plr and plr.Parent == Players then
			MatchState:FireClient(plr, {
				phase = "match_over",
				mapId = mapId,
				winner = winnerTeam,
			})
		end
	end

	local reward = getMapReward(mapId)
	local half = math.ceil(#picked / 2)
	for i, plr in ipairs(picked) do
		if plr and plr.Parent == Players then
			local team = (i <= half) and "A" or "B"
			if team == winnerTeam then
				PlayerDataService:IncrementTrophies(plr, reward)
				PlayerDataService:Save(plr)
			end
		end
	end

	for _, plr in ipairs(picked) do
		if plr and plr.Parent == Players then
			plr:LoadCharacter()
			MatchState:FireClient(plr, { phase = "lobby" })
		end
	end
end

local function teleportToMapSpawns(players, mapId)
	local mapFolder = workspace:FindFirstChild(mapId)
	if not mapFolder then
		warn("Map not found:", mapId)
		return
	end

	local teamASpawn = mapFolder:FindFirstChild("TeamASpawn")
	local teamBSpawn = mapFolder:FindFirstChild("TeamBSpawn")

	local half = math.ceil(#players / 2)

	for i, player in ipairs(players) do
		if player and player.Character and player.Character.PrimaryPart then
			local spawn = (i <= half) and teamASpawn or teamBSpawn
			if spawn then
				player.Character:SetPrimaryPartCFrame(spawn.CFrame + Vector3.new(0, 3, 0))
			end
		end
	end
end

local function startMatchWithPlayers(queueKey, picked)
	for _, uid in ipairs(picked) do
		queuedKeyByUserId[uid] = nil
	end
	local q = queues[queueKey]
	if q and #q == 0 then
		queues[queueKey] = nil
	end
	local mapId, rankedStr = queueKey:match("^(.-)|(.+)$")
	local ranked = (rankedStr == "true")
	broadcastMatchFound(mapId, ranked, picked)

	-- Phase: countdown (5s) then in_match
	for _, uid in ipairs(picked) do
		local player = Players:GetPlayerByUserId(uid)
		if player then
			MatchState:FireClient(player, { phase = "countdown", seconds = COUNTDOWN_TO_START, mapId = mapId, ranked = ranked })
		end
	end
	task.delay(COUNTDOWN_TO_START, function()
		local playersList = {}
		for _, uid in ipairs(picked) do
			local player = Players:GetPlayerByUserId(uid)
			if player then
				MatchState:FireClient(player, { phase = "in_match", mapId = mapId, ranked = ranked })
				table.insert(playersList, player)
			end
		end
		teleportToMapSpawns(playersList, mapId)

		-- TEMP: end the match after MATCH_DURATION
		task.delay(MATCH_DURATION, function()
			local winnerTeam = "A"
			endMatch(playersList, mapId, winnerTeam)
		end)
	end)
end

-- Start match when: 12 players (immediate) or countdown ends with >= 2
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

	local q = queues[key]
	sendQueueStatus(player, true, "", {
		queued = true,
		mapId = mapId,
		ranked = ranked,
		queuedCount = #q,
	})

	-- Immediate start when queue hits 12
	if #q >= MAX_PLAYERS then
		countdownRunning[key] = false
		local picked = {}
		for i = 1, MAX_PLAYERS do
			table.insert(picked, table.remove(q, 1))
		end
		startMatchWithPlayers(key, picked)
		return
	end

	-- First player in this queue: start countdown
	if #q == 1 then
		countdownRunning[key] = true
		task.delay(COUNTDOWN_TIME, function()
			if not countdownRunning[key] then return end
			countdownRunning[key] = false

			local qNow = queues[key]
			if not qNow or #qNow < MIN_PLAYERS then return end

			local toTake = math.min(MAX_PLAYERS, #qNow)
			local picked = {}
			for i = 1, toTake do
				table.insert(picked, table.remove(qNow, 1))
			end
			startMatchWithPlayers(key, picked)
		end)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	removeFromQueue(player.UserId)
end)

return QueueService
