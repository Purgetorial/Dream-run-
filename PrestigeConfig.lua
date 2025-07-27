-- Create this file at: ReplicatedStorage/Config/PrestigeConfig.lua
return {
	-- A flat amount of coins awarded instantly for each prestige level attained.
	-- Example: At Prestige 5, you get 5 * 250 = 1250 coins.
	LUMP_COIN_AWARD_PER_LEVEL = 250,

	-- A permanent increase to your character's base speed for each prestige level.
	-- This bonus applies BEFORE any temporary upgrades.
	SPEED_BONUS_PER_LEVEL = 0.75,

	-- The percentage bonus applied to each coin you collect.
	-- Example: At Prestige 5, you get a 5 * 10% = 50% bonus on coins.
	COIN_COLLECT_BONUS_PER_LEVEL = 0.10, -- 10%
}