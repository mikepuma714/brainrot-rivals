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
local DebugAddScore = remotes:WaitForChild("DebugAddScore")
local ScoreUpdate = remotes:WaitForChild("ScoreUpdate")

local MIN_PLAYERS = 2
local MAX_PLAYERS = 12
local COUNTDOWN_TIME = 10
local COUNTDOWN_TO_START = 5
local MATCH_DURATION = 60
local WIN_SCORE = 5

-- mapKey = mapId .. "|" .. tostring(ranked)
local queues = {}
local queuedKeyByUserId = {}
local countdownRunning = {}

-- Current match state (for scoring)
local matchScores = { A = 0, B = 0 }
local currentPickedPlayers = nil
local currentMapId = nil
local teamByUserId = {}

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

local function broadcastScore()
	local payload = { A = matchScores.A, B = matchScores.B }
	for _, plr in ipairs(Players:GetPlayers()) do
		ScoreUpdate:FireClient(plr, payload)
	end
end

local function addScore(team)
	if team ~= "A" and team ~= "B" then return end
	if not currentPickedPlayers or not currentMapId then return end
	matchScores[team] = (matchScores[team] or 0) + 1
	broadcastScore()

	if matchScores[team] >= WIN_SCORE then
		local picked = currentPickedPlayers
		local mapId = currentMapId
		currentPickedPlayers = nil
		currentMapId = nil
		matchScores.A = 0
		matchScores.B = 0
		endMatch(picked, mapId, team)
	end
end

local function oppositeTeam(team)
	return (team == "A") and "B" or "A"
end

local function hookDeathsForMatchPlayers()
	for _, plr in ipairs(currentPickedPlayers or {}) do
		local team = teamByUserId[plr.UserId]
		if team then
			local function hookCharacter(character)
				local hum = character:FindFirstChildOfClass("Humanoid")
				if hum then
					hum.Died:Connect(function()
						addScore(oppositeTeam(team))
					end)
				end
			end
			if plr.Character then
				hookCharacter(plr.Character)
			end
			plr.CharacterAdded:Connect(hookCharacter)
		end
	end
end

local function endMatch(picked, mapId, winnerTeam)
	currentPickedPlayers = nil
	currentMapId = nil
	teamByUserId = {}
	matchScores.A = 0
	matchScores.B = 0

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

		currentPickedPlayers = playersList
		currentMapId = mapId
		matchScores.A = 0
		matchScores.B = 0
		teamByUserId = {}
		local half = math.ceil(#playersList / 2)
		for i, plr in ipairs(playersList) do
			teamByUserId[plr.UserId] = (i <= half) and "A" or "B"
		end
		hookDeathsForMatchPlayers()
		broadcastScore()

		-- Timer fallback: end after MATCH_DURATION, winner = higher score or A if tie
		task.delay(MATCH_DURATION, function()
			if not currentPickedPlayers then return end
			local winnerTeam = (matchScores.A >= matchScores.B) and "A" or "B"
			endMatch(currentPickedPlayers, currentMapId, winnerTeam)
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

DebugAddScore.OnServerEvent:Connect(function(player, team)
	if not currentPickedPlayers or not currentMapId then return end
	if type(team) ~= "string" then return end
	addScore(team)
end)

Players.PlayerRemoving:Connect(function(player)
	removeFromQueue(player.UserId)
end)

return QueueService
