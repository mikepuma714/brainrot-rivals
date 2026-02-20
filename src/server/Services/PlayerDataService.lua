local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local ServerConfig = require(script.Parent.Parent:WaitForChild("Config"):WaitForChild("ServerConfig"))

local PlayerDataService = {}
PlayerDataService.__index = PlayerDataService

local store = DataStoreService:GetDataStore(ServerConfig.DATASTORE_NAME)

-- in-memory cache
local cache: {[number]: any} = {}

local DEFAULT_DATA = {
	trophies = 0,
	selectedBrainrotId = "tung_tung_sahur",
}

local function deepCopy(t)
	local copy = {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			copy[k] = deepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

local function withRetries(fn, maxAttempts)
	maxAttempts = maxAttempts or 5
	local lastErr
	for attempt = 1, maxAttempts do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastErr = result
		task.wait(0.5 * attempt)
	end
	return false, lastErr
end

function PlayerDataService:Get(userId: number)
	if cache[userId] then
		return cache[userId]
	end
	-- if not loaded yet, return default (should be rare)
	cache[userId] = deepCopy(DEFAULT_DATA)
	return cache[userId]
end

function PlayerDataService:Load(player: Player)
	local userId = player.UserId

	local ok, data = withRetries(function()
		return store:GetAsync(tostring(userId))
	end)

	print("[PlayerDataService] GetAsync ok=", ok, " dataType=", typeof(data))
	if not ok then warn("[PlayerDataService] GetAsync error:", data) end

	if ok and type(data) == "table" then
		-- merge defaults
		local merged = deepCopy(DEFAULT_DATA)
		for k, v in pairs(data) do
			merged[k] = v
		end
		cache[userId] = merged
	else
		cache[userId] = deepCopy(DEFAULT_DATA)
	end

	if ServerConfig.DEBUG then
		print(("[PlayerDataService] Loaded %s trophies=%d"):format(player.Name, cache[userId].trophies))
	end

	return cache[userId]
end

function PlayerDataService:Save(player: Player)
	local userId = player.UserId
	local data = cache[userId]
	if not data then return end

	local payload = {
		trophies = data.trophies,
		selectedBrainrotId = data.selectedBrainrotId,
	}

	local ok, err = withRetries(function()
		return store:SetAsync(tostring(userId), payload)
	end)

	if not ok then
		warn("[PlayerDataService] Save failed for", player.Name, err)
	elseif ServerConfig.DEBUG then
		print("[PlayerDataService] Saved", player.Name, "trophies=", payload.trophies)
	end
end

function PlayerDataService:IncrementTrophies(player: Player, amount: number)
	local data = self:Get(player.UserId)
	data.trophies = math.max(0, (data.trophies or 0) + amount)
end

function PlayerDataService:SetSelectedBrainrot(player: Player, brainrotId: string)
	local data = self:Get(player.UserId)
	data.selectedBrainrotId = brainrotId
end

-- lifecycle hooks
Players.PlayerAdded:Connect(function(player)
	PlayerDataService:Load(player)
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerDataService:Save(player)
	cache[player.UserId] = nil
end)

game:BindToClose(function()
	-- best effort save
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerDataService:Save(player)
	end
end)

return PlayerDataService
