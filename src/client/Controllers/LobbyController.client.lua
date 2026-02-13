local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RemotesDef = require(Shared:WaitForChild("Remotes"))

local remotesFolder = ReplicatedStorage:WaitForChild(RemotesDef.FolderName)
local getLobbyStateFn = remotesFolder:WaitForChild(RemotesDef.Functions.GetLobbyState)

local function pretty(t)
	local ok, json = pcall(function()
		return game:GetService("HttpService"):JSONEncode(t)
	end)
	return ok and json or "<unable to encode>"
end

task.wait(2)

local state = getLobbyStateFn:InvokeServer()
print("[LobbyController] Lobby state:", pretty(state))
