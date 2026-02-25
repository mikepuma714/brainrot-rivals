local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestAbility = remotes:WaitForChild("RequestAbility")

local ABILITY_ID = "bat_smash"
local COOLDOWN = 2.0
local DAMAGE = 35
local RANGE = 8

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

local function getHRP(player: Player)
	local char = player.Character
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoidFromHit(hit: Instance?)
	if not hit then return nil end
	local model = hit:FindFirstAncestorOfClass("Model")
	if not model then return nil end
	return model:FindFirstChildOfClass("Humanoid")
end

RequestAbility.OnServerEvent:Connect(function(player: Player, payload)
	if typeof(payload) ~= "table" then return end
	if payload.abilityId ~= ABILITY_ID then return end

	if not player or player.Parent ~= Players then return end
	if not player.Character then return end
	if not canUse(player.UserId) then return end

	local hrp = getHRP(player)
	if not hrp then return end

	-- Raycast forward for bat smash
	local origin = hrp.Position
	local direction = hrp.CFrame.LookVector * RANGE

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	params.IgnoreWater = true

	local result = workspace:Raycast(origin, direction, params)
	if not result then return end

	local humanoid = getHumanoidFromHit(result.Instance)
	if not humanoid then return end
	if humanoid.Health <= 0 then return end

	-- Prevent self damage
	if humanoid:IsDescendantOf(player.Character) then return end

	humanoid:TakeDamage(DAMAGE)

	local targetChar = humanoid.Parent
	local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
	if targetHrp then
		local pushDir = (targetHrp.Position - hrp.Position)
		if pushDir.Magnitude > 0 then
			pushDir = pushDir.Unit
		else
			pushDir = hrp.CFrame.LookVector
		end

		local HORIZONTAL_FORCE = 60
		local UP_FORCE = 20

		targetHrp:ApplyImpulse((pushDir * HORIZONTAL_FORCE + Vector3.new(0, UP_FORCE, 0)) * targetHrp.AssemblyMass)
	end

	print(("[AbilityService] %s hit with Bat Smash"):format(player.Name))
end)

return {}
