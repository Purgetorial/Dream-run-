--------------------------------------------------------------------
-- ShopItems.lua
--  • Single source of truth for everything sold in the Shop UI
--  • Used by: ShopController (client), ProductService & BoostService (server)
--------------------------------------------------------------------
return {
	----------------------------------------------------------------
	-- ? COSMETICS  (coin-priced, equipable)
	----------------------------------------------------------------
	Cosmetics = {
		{
			Name  = "Rainbow Trail",
			Price = 1000,
			Tab   = "Trails",
			Desc  = "Leave a vibrant rainbow behind you!",
			Icon  = "rbxassetid://14664719657",
		},
		{
			Name  = "Golden Trail",
			Price = 1000,
			Tab   = "Trails",
			Desc  = "Shine with a golden glow as you run.",
			Icon  = "rbxassetid://14664719905",
		},
		-- Game-pass exclusive cosmetic (shows as OWNED when pass present)
		{
			Name  = "Lightspeed Trail",
			Price = 0,
			Tab   = "Trails",
			Desc  = "Crimson crackling energy for Lightspeed owners.",
			Icon  = "rbxassetid://14664721214",
		},
	},

	----------------------------------------------------------------
	-- ? BOOSTS  (Boosts tab — all purchasable with Robux)
	----------------------------------------------------------------
	Boosts = {
		{
			Name      = "Low Gravity",
			BoostName = "LowGravity",          -- matches ActiveBoosts flag
			ProductId = 3344707026,            -- Developer Product
			Desc      = "Floaty jumps for 2 minutes.",
			Duration  = 120,                   -- seconds (server side)
			Icon      = "rbxassetid://14664720179",
		},
		{
			Name      = "Double Coins",
			BoostName = "DoubleCoins",
			ProductId = 3347370678,            -- Developer Product
			Desc      = "Earn twice the coins for 2 minutes.",
			Duration  = 120,
			Icon      = "rbxassetid://14664720471",
		},
		{
			Name      = "Lightspeed",
			BoostName = "Lightspeed",
			ProductId = 3345816814,            -- Game-pass ID
			Desc      = "Permanent speed bonus & exclusive trail.",
			Icon      = "rbxassetid://14664721214",
		},
	},

	----------------------------------------------------------------
	-- ? ROBUX  (coin packs — stay in their own tab)
	----------------------------------------------------------------
	Robux = {
		{
			Name       = "500 Coins",
			ProductId  = 3346929901,
			Reward     = 500,                  -- coins granted
			Desc       = "Get 500 coins instantly.",
			Icon       = "rbxassetid://14664720971",
		},
		{
			Name       = "1000 Coins",
			ProductId  = 3346930431,
			Reward     = 1000,
			Desc       = "Get 1,000 coins instantly.",
			Icon       = "rbxassetid://14664720971",
		},
		{
			Name       = "2000 Coins",
			ProductId  = 3346930540,
			Reward     = 2000,
			Desc       = "Get 2,000 coins instantly.",
			Icon       = "rbxassetid://14664720971",
		},
	},
}
