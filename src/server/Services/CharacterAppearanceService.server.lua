local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Assets location
local BrainrotAssets = ReplicatedStorage:WaitForChild("BrainrotAssets")

local BRAINROT_ID = "tung_tung_sahur"

local function weldBatToRightHand(character: Model, batModel: Model)
	local rightHand =
		character:FindFirstChild("RightHand")
		or character:FindFirstChild("Right Arm") -- R6 fallback

	if not rightHand or not rightHand:IsA("BasePart") then
		warn("[CharacterAppearance] RightHand not found")
		return
	end

	-- Clone the bat into the character
	local bat = batModel:Clone()
	bat.Name = "Bat"
	bat.Parent = character

	-- Find the part to weld
	local handle = bat:FindFirstChild("Handle")

	if not handle then
		for _, d in ipairs(bat:GetDescendants()) do
			if d:IsA("BasePart") then
				handle = d
				break
			end
		end
	end

	if not handle then
		warn("[CharacterAppearance] Bat has no BasePart")
		bat:Destroy()
		return
	end

	-- Make sure bat physics won't interfere
	for _, d in ipairs(bat:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.Massless = true
		end
	end

	-- Position the bat relative to the hand
	handle.CFrame =
		rightHand.CFrame
		* CFrame.new(0, -0.8, -0.6)
		* CFrame.Angles(0, math.rad(90), math.rad(20))

	-- Weld to hand
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = rightHand
	weld.Part1 = handle
	weld.Parent = handle
end

local function applyForPlayer(player: Player, character: Model)
	local folder = BrainrotAssets:WaitForChild(BRAINROT_ID)
	local batModel = folder:WaitForChild("Bat")

	local existing = character:FindFirstChild("Bat")
	if existing then
		existing:Destroy()
	end

	weldBatToRightHand(character, batModel)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		applyForPlayer(player, character)
	end)
end)
