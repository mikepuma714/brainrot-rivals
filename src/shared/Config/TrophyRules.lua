-- Trophy-based unlock rules. Reads ONLY trophyReward/unlockAt from Maps.List.
local TrophyRules = {}

local Maps = require(script.Parent:WaitForChild("Maps"))

function TrophyRules.isMapUnlocked(mapId, trophies)
	local required = TrophyRules.getMapUnlockAt(mapId)
	return (trophies or 0) >= required
end

function TrophyRules.isRankedUnlocked(trophies)
	return (trophies or 0) >= (Maps.RankedUnlockAt or 120)
end

function TrophyRules.getMapReward(mapId)
	for _, m in ipairs(Maps.List) do
		if m.id == mapId then
			return (type(m.trophyReward) == "number") and m.trophyReward or 0
		end
	end
	return 0
end

function TrophyRules.getMapUnlockAt(mapId)
	for _, m in ipairs(Maps.List) do
		if m.id == mapId then
			return (type(m.unlockAt) == "number") and m.unlockAt or 0
		end
	end
	return 0
end

return TrophyRules
