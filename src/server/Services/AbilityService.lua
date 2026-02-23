local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestAbility = remotes:WaitForChild("RequestAbility")

-- TEMP: only implementing Bat Smash for Tung Tung Sahur
local ABILITY_ID = "bat_smash"
local COOLDOWN = 2.0

local lastUseByUserId: {[number]: number} = {}

local function canUse(userId: number)
	local now = os.clock()
	local last = lastUseByUserId[userId] or 0
	if (now - last) < COOLDOWN then
		return false
	end
	lastUseByUserId[userId] = now
	return true
end

RequestAbility.OnServerEvent:Connect(function(player: Player, payload)
	if typeof(payload) ~= "table" then return end
	if payload.abilityId ~= ABILITY_ID then return end

	-- basic safety checks
	if not player or player.Parent ~= Players then return end
	if not player.Character then return end
	if not canUse(player.UserId) then return end

	print(("[AbilityService] %s used %s"):format(player.Name, ABILITY_ID))

	-- NEXT STEP will add:
	-- 1) in_match validation
	-- 2) character check (must be tung_tung_sahur)
	-- 3) hitbox + damage + knockback
end)

return {}
