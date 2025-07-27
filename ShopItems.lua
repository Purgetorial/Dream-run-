-- purgetorial/dream-run-/Dream-run--c6e19a1472899b0fe558b182fcfa5a80333cb4a1/ShopItems.lua
--------------------------------------------------------------------
-- ShopItems.lua
--  • Single source of truth for everything sold in the Shop UI
--  • RESTRUCTURED: Added Upgrades and Perks, moved Trails to Game Pass
--------------------------------------------------------------------
return {
	----------------------------------------------------------------
	-- ? UPGRADES (Coin-priced, reset on prestige)
	----------------------------------------------------------------
	Upgrades = {
		-- Max Speed Upgrades
		{ Name = "Speed I",    Key = "MaxSpeed",    TargetLevel = 1, Price = 100, Icon = "rbxassetid://14664721214", Desc = "+1 Max Speed" },
		{ Name = "Speed II",   Key = "MaxSpeed",    TargetLevel = 2, Price = 250, Icon = "rbxassetid://14664721214", Desc = "+2 Max Speed" },
		{ Name = "Speed III",  Key = "MaxSpeed",    TargetLevel = 3, Price = 500, Icon = "rbxassetid://14664721214", Desc = "+3 Max Speed" },

		-- Sprint Speed Upgrades
		{ Name = "Sprint I",   Key = "SprintSpeed", TargetLevel = 1, Price = 150, Icon = "rbxassetid://3926307978", Desc = "+5% Sprint Speed" },
		{ Name = "Sprint II",  Key = "SprintSpeed", TargetLevel = 2, Price = 300, Icon = "rbxassetid://3926307978", Desc = "+10% Sprint Speed" },
		{ Name = "Sprint III", Key = "SprintSpeed", TargetLevel = 3, Price = 600, Icon = "rbxassetid://3926307978", Desc = "+15% Sprint Speed" },

		-- Stamina Upgrades
		{ Name = "Stamina I",  Key = "Stamina",     TargetLevel = 1, Price = 75,  Icon = "rbxassetid://3926305904", Desc = "+10 Max Stamina" },
		{ Name = "Stamina II", Key = "Stamina",     TargetLevel = 2, Price = 200, Icon = "rbxassetid://3926305904", Desc = "+20 Max Stamina" },
		{ Name = "Stamina III",Key = "Stamina",     TargetLevel = 3, Price = 450, Icon = "rbxassetid://3926305904", Desc = "+30 Max Stamina" },
	},

	----------------------------------------------------------------
	-- ? PERKS (Reset on prestige, unless from a Game Pass)
	----------------------------------------------------------------
	Perks = {
		{ Name = "Unlock Sprint", Key = "SprintUnlocked", Price = 100, Icon = "rbxassetid://3926307978", Desc = "Enables the ability to sprint. Resets on Prestige." },
		{ Name = "Double Jump",   Key = "DoubleJump",     Price = 100, Icon = "rbxassetid://14664720179", Desc = "Allows you to jump a second time in the air. Resets on Prestige." },
		{ Name = "Double Coins",  Key = "DoubleCoins",    Price = 100, ProductId = 50, Icon = "rbxassetid://14664720471", Desc = "Permanently get 2x coins with Robux, or until you Prestige with Coins." },
	},

	----------------------------------------------------------------
	-- ? COSMETICS (Game Pass / Robux only)
	----------------------------------------------------------------
	Cosmetics = {
		{
			Name      = "Rainbow Trail",
			Tab       = "Trails",
			ProductId = 12345678, -- !! REPLACE WITH YOUR GAME PASS ID !!
			Desc      = "Leave a vibrant rainbow behind you! (Requires Game Pass)",
			Icon      = "rbxassetid://14664719657",
		},
		{
			Name      = "Golden Trail",
			Tab       = "Trails",
			ProductId = 12345679, -- !! REPLACE WITH YOUR GAME PASS ID !!
			Desc      = "Shine with a golden glow as you run. (Requires Game Pass)",
			Icon      = "rbxassetid://14664719905",
		},
	},

	----------------------------------------------------------------
	-- ? ROBUX  (Coin packs)
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