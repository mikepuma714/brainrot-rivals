local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local store = DataStoreService:GetDataStore("BrainrotRivals_Profile_v1")

local ProfileService = {}
local profiles = {}

local UNLOCKS = {
	[1] = 0,    -- map1 always
	[2] = 20,
	[3] = 50,
	[4] = 80,
	[5] = 120,
}

local function computeUnlockedMap(trophies)
	local unlocked = 1
	for mapId = 2, 5 do
		if trophies >= UNLOCKS[mapId] then
			unlocked = mapId
		end
	end
	return unlocked
end

local function defaultProfile()
	return { trophies = 0, unlockedMap = 1, ranked = false }
end

function ProfileService:Get(player)
	return profiles[player.UserId]
end

function ProfileService:AddTrophies(player, amount)
	local p = profiles[player.UserId]
	if not p then return end

	p.trophies += amount
	p.unlockedMap = computeUnlockedMap(p.trophies)

	if p.unlockedMap >= 5 then
		p.ranked = true
	end
end

Players.PlayerAdded:Connect(function(player)
	local data
	pcall(function()
		data = store:GetAsync(tostring(player.UserId))
	end)

	if type(data) ~= "table" then
		data = defaultProfile()
	end

	-- recompute just in case
	data.unlockedMap = computeUnlockedMap(data.trophies)
	if data.unlockedMap >= 5 then data.ranked = true end

	profiles[player.UserId] = data
end)

Players.PlayerRemoving:Connect(function(player)
	local p = profiles[player.UserId]
	if not p then return end

	pcall(function()
		store:SetAsync(tostring(player.UserId), p)
	end)

	profiles[player.UserId] = nil
end)

return ProfileService
