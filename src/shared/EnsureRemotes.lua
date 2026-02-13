local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local function ensure(name, className)
	local obj = remotes:FindFirstChild(name)
	if not obj then
		obj = Instance.new(className)
		obj.Name = name
		obj.Parent = remotes
	end
	return obj
end

-- Existing (keep)
ensure("GetLobbyState", "RemoteFunction")

-- New (add)
ensure("GetProfile", "RemoteFunction")
ensure("AddTrophies", "RemoteEvent") -- debug only
