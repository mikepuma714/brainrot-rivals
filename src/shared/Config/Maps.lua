-- Map definitions: single source of truth. Keys: id, name, trophyReward, unlockAt
local Maps = {}

Maps.List = {
	{ id = "brainrot_island", name = "Brainrot Island", trophyReward = 3,  unlockAt = 0 },
	{ id = "meme_mall",      name = "Meme Mall",      trophyReward = 5,  unlockAt = 20 },
	{ id = "ocean_city",     name = "Ocean City",     trophyReward = 7,  unlockAt = 50 },
	{ id = "the_city",       name = "The City",       trophyReward = 15, unlockAt = 80 },
	{ id = "final_boss",     name = "The Final Boss", trophyReward = 50, unlockAt = 120 },
}
Maps.RankedUnlockAt = 120

return Maps
