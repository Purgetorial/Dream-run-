--------------------------------------------------------------------
-- ProductService.lua · handles ALL Developer Products / Game-passes (Optimized)
-- • Now uses require() for BoostService, removing the final _G dependency.
-- • Handles all Robux-based purchases.
--------------------------------------------------------------------
local MarketplaceService = game:GetService("MarketplaceService")
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Service Modules
local DataAPI      = require(ServerScriptService.PlayerDataManager)
local BoostService = require(ServerScriptService.BoostService) -- Correctly require the module
local ShopItems    = require(ReplicatedStorage.Config.ShopItems)

--------------------------------------------------------------------
-- Build Fast-Lookup Tables
--------------------------------------------------------------------
local COIN_PACKS = {}   -- [productId] = coinAmount
local BOOST_PRODUCTS = {}   -- [productId] = true

-- Process Robux-purchasable boosts (Developer Products and Game Passes)
for _, item in ipairs(ShopItems.Boosts or {}) do
	if item.ProductId then
		BOOST_PRODUCTS[item.ProductId] = true
	end
end

-- Process coin packs
for _, item in ipairs(ShopItems.Robux or {}) do
	if item.ProductId and typeof(item.Reward) == "number" then
		COIN_PACKS[item.ProductId] = item.Reward
	end
end

--------------------------------------------------------------------
-- Purchase Receipt Handler
--------------------------------------------------------------------
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Player might have left. Not an error, but we can't process it.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local productId = receiptInfo.ProductId

	-- Handle Coin Pack Purchases
	local coinAmount = COIN_PACKS[productId]
	if coinAmount then
		local data = DataAPI.Get(player)
		if data then
			DataAPI.AddCoins(player, coinAmount)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	-- Handle Boost / Game-Pass Purchases
	if BOOST_PRODUCTS[productId] then
		if BoostService and BoostService.GrantFromPurchase(player, productId) then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	-- If we reach here, the product ID wasn't found in our lookups.
	-- This is important to prevent processing purchases not related to our game.
	return Enum.ProductPurchaseDecision.NotProcessedYet
end