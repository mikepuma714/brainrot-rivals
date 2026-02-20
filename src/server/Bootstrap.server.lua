local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ServerConfig = require(script.Parent:WaitForChild("Config"):WaitForChild("ServerConfig"))

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemotesDef = require(Shared:WaitForChild("Remotes"))

local PlayerDataService = require(script.Parent:WaitForChild("Services"):WaitForChild("PlayerDataService"))

local TrophyRules = require(Shared:WaitForChild("Config"):WaitForChild("TrophyRules"))
local Maps = require(Shared:WaitForChild("Config"):WaitForChild("Maps"))

if ServerConfig.DEBUG then
	print("[BrainrotRivals] DEBUG mode ON")
end

require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("EnsureRemotes"))
require(script.Parent:WaitForChild("Services"):WaitForChild("QueueService"))

-- Create remotes folder and functions if needed
local remotesFolder = ReplicatedStorage:FindFirstChild(RemotesDef.FolderName)
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = RemotesDef.FolderName
	remotesFolder.Parent = ReplicatedStorage
end

local getLobbyStateFn = remotesFolder:FindFirstChild(RemotesDef.Functions.GetLobbyState)
if not getLobbyStateFn then
	getLobbyStateFn = Instance.new("RemoteFunction")
	getLobbyStateFn.Name = RemotesDef.Functions.GetLobbyState
	getLobbyStateFn.Parent = remotesFolder
end

getLobbyStateFn.OnServerInvoke = function(player)
	local data = PlayerDataService:Get(player.UserId)
	local trophies = data.trophies or 0

	-- compute unlocks
	local unlocked = {}
	for _, m in ipairs(Maps.List) do
		unlocked[m.id] = TrophyRules.isMapUnlocked(m.id, trophies)
	end

	return {
		trophies = trophies,
		rankedUnlocked = TrophyRules.isRankedUnlocked(trophies),
		unlockedMaps = unlocked,
		availableMaps = Maps.List, -- so client can render names + rewards
		selectedBrainrotId = data.selectedBrainrotId,
	}
end
