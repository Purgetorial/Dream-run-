--------------------------------------------------------------------
-- ShopService.lua  |  (Final, TYPO-FIXED & Data-Aware Version)
-- • FIX: Corrected the typo in GetService("ServerScriptService").
-- • FIX: Now waits for player data to be loaded before processing a purchase.
-- • Handles all purchases made with the in-game "Coin" currency.
--------------------------------------------------------------------
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService") -- TYPO FIXED
local Players             = game:GetService("Players")

-- Service Modules
local DataAPI            = require(ServerScriptService.PlayerDataManager)
local AntiExploitService = require(ServerScriptService.AntiExploitService)
local ShopItems          = require(ReplicatedStorage.Config.ShopItems)

-- Remote
local Remotes   = ReplicatedStorage:WaitForChild("Remotes")
local BuyItemRF = Remotes:WaitForChild("BuyItem")

--------------------------------------------------------------------
-- Fast lookup table for cosmetics
--------------------------------------------------------------------
local cosmeticsByName = {}
for _, item in ipairs(ShopItems.Cosmetics or {}) do
	cosmeticsByName[item.Name] = item
end

--------------------------------------------------------------------
-- Main Purchase Handler
--------------------------------------------------------------------
BuyItemRF.OnServerInvoke = function(player, tab: string, itemName: string)
	if not AntiExploitService.Validate(player, "BuyItem") then return false end

	-- KEY FIX: Wait for the player's data to be loaded before proceeding.
	local data = DataAPI.Get(player)
	if not data then
		for _ = 1, 50 do -- Wait up to 5 seconds for data
			task.wait(0.1)
			data = DataAPI.Get(player)
			if data then break end
		end
		if not data then
			warn(`[ShopService] Purchase failed: Data for {player.Name} never loaded.`)
			return false
		end
	end

	print(`[ShopService] Processing coin purchase for {player.Name}: {itemName}`)

	-- This service now ONLY handles cosmetics, for clarity.
	if tab == "Cosmetics" then
		local itemInfo = cosmeticsByName[itemName]
		if not (itemInfo and itemInfo.Price) then
			warn(`[ShopService] Purchase failed: Item "{itemName}" not found or has no price.`)
			return false
		end

		-- Check if player has enough coins
		if data.Coins < itemInfo.Price then
			print(`[ShopService] Purchase failed: {player.Name} has {data.Coins} coins, needs {itemInfo.Price}.`)
			return false
		end

		-- Charge coins and grant item
		DataAPI.AddCoins(player, -itemInfo.Price)

		local ownedCosmetics = data.OwnedCosmetics or {}
		local ownedCategory = ownedCosmetics[itemInfo.Tab] or {}
		if not table.find(ownedCategory, itemName) then
			table.insert(ownedCategory, itemName)
			DataAPI.Set(player, "OwnedCosmetics", ownedCosmetics)
		end

		print(`[ShopService] Purchase SUCCESS for {player.Name}: {itemName}`)
		return true
	end

	return false
end