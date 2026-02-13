-- Trophy-based unlock rules: maps and ranked mode
local TrophyRules = {}

-- Map IDs that require trophies to unlock (extend as needed)
local MAP_THRESHOLDS = {
	-- mapId = trophies required
	["default"] = 0,
}

function TrophyRules.isMapUnlocked(mapId, trophies)
	local required = MAP_THRESHOLDS[mapId]
	if required == nil then
		required = 0
	end
	return (trophies or 0) >= required
end

function TrophyRules.isRankedUnlocked(trophies)
	return (trophies or 0) >= 10
end

return TrophyRules
