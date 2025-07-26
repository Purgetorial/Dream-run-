-- FXConfig.lua  |  tweak without touching code
return {
	FOV_MIN            = 70,
	FOV_MAX            = 88,
	ZOOM_TIME          = 0.25,    -- sec in/out

	BOOST = {
		MULTIPLIER     = 1.6,     -- WalkSpeed × 1.6
		DURATION       = 2.5,     -- sec  (free players)
		EXTRA_DURATION = 3.5,     -- extra for Lightspeed pass
		COOLDOWN       = 8,       -- sec
	},

	LIGHTNING_CUE_RATE = 0.8,     -- sound fires every 0.8 s while sprinting
}
