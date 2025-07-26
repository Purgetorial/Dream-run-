--------------------------------------------------------------------
-- ShopService.lua  |  central entry for all coin-based shop purchases (Optimized)
-- • Now uses require() for BoostService, removing _G dependency.
-- • Handles all purchases made with the in-game "Coin" currency.
--------------------------------------------------------------------
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players            = game:GetService("Players")

-- Service Modules
local DataAPI       = require(ServerScriptService.PlayerDataManager)
local BoostService  = require(ServerScriptService.BoostService) -- Correctly require the module
local ShopItems     = require(ReplicatedStorage.Config.ShopItems)

-- Remote from the UI (ShopController)
local Remotes   = ReplicatedStorage:WaitForChild("Remotes")
local BuyItem   = Remotes:FindFirstChild("BuyItem") or Instance.new("RemoteFunction", Remotes)
BuyItem.Name    = "BuyItem"

--------------------------------------------------------------------
-- Fast lookup tables for shop items
--------------------------------------------------------------------
local cosmeticsByName = {}
for _, item in ipairs(ShopItems.Cosmetics or {}) do
	cosmeticsByName[item.Name] = item
end

local boostsByName = {}
for _, item in ipairs(ShopItems.Boosts or {}) do
	-- Only include boosts that can be bought with coins
	if item.Price and not item.ProductId then
		boostsByName[item.BoostName] = item
	end
end

--------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------
local function chargeCoins(player, price)
	local data = DataAPI.Get(player)
	if not data or (data.Coins or 0) < price then
		return false -- Not enough coins
	end

	DataAPI.AddCoins(player, -price) -- Use the AddCoins helper to subtract
	return true
end

--------------------------------------------------------------------
-- Main Purchase Handler
--------------------------------------------------------------------
BuyItem.OnServerInvoke = function(player, tab: string, itemName: string)
	if not (player and tab and itemName) then return false end

	local data = DataAPI.Get(player)
	if not data then return false end

	-- Handle Cosmetic Purchases
	if tab == "Cosmetics" then
		local itemInfo = cosmeticsByName[itemName]
		if not (itemInfo and itemInfo.Price) then return false end

		-- Check if already owned
		local ownedCosmetics = data.OwnedCosmetics or {}
		local ownedCategory = ownedCosmetics[itemInfo.Tab] or {}
		if table.find(ownedCategory, itemName) then
			return true -- Already owned, count as success
		end

		if not chargeCoins(player, itemInfo.Price) then
			return false -- Failed to charge coins
		end

		table.insert(ownedCategory, itemName)
		data.OwnedCosmetics[itemInfo.Tab] = ownedCategory
		DataAPI.Set(player, "OwnedCosmetics", data.OwnedCosmetics) -- Mark for saving

		return true
	end

	-- Handle Coin-Priced Boost Purchases
	if tab == "Boosts" then
		local itemInfo = boostsByName[itemName]
		if not (itemInfo and itemInfo.Price) then return false end

		if not chargeCoins(player, itemInfo.Price) then
			return false -- Failed to charge coins
		end

		-- Activate the boost using the required module
		if BoostService then
			BoostService.Activate(player, itemInfo.BoostName, itemInfo.Duration)
		end

		return true
	end

	return false
end