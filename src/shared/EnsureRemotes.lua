local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function ensureFolder(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end

local function ensureRemote(parent, className, name)
	local r = parent:FindFirstChild(name)
	if not r then
		r = Instance.new(className)
		r.Name = name
		r.Parent = parent
	end
	return r
end

local remotes = ensureFolder(ReplicatedStorage, "Remotes")

-- These must match the names your game uses
ensureRemote(remotes, "RemoteFunction", "GetLobbyState")
ensureRemote(remotes, "RemoteFunction", "GetProfile")
ensureRemote(remotes, "RemoteEvent", "AddTrophies")
ensureRemote(remotes, "RemoteEvent", "SetSelectedMap")

-- If you still use this anywhere, keep it too:
ensureRemote(remotes, "RemoteFunction", "GetLobbyState")

return true
