-- CoinConfig.lua  |  constants shared by client + server
return {
	NUM_SEGMENTS        = 150,   -- how many segments the generator builds
	SEGMENT_LENGTH      = 40,    -- studs per segment
	COIN_INTERVAL       = 3,     -- place a coin every Nth segment
	HOVER_Y_OFFSET      = 3,     -- studs above segment top
	SPIN_SPEED          = 180,   -- °/s
	BOB_SPEED           = 2,     -- Hz
	BOB_HEIGHT          = 0.6,
}
