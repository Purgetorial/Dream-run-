--------------------------------------------------------------------
-- ProductService.lua · (Final, TYPO-FIXED & Debuggable Version)
-- • FIX: Corrected the typo in GetService("ServerScriptService").
-- • FIX: Adds print statements for clear debugging of Robux purchases.
--------------------------------------------------------------------
local MarketplaceService = game:GetService("MarketplaceService")
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService") -- TYPO FIXED

-- Service Modules
local DataAPI      = require(ServerScriptService.PlayerDataManager)
local BoostService = require(ServerScriptService.BoostService)
local ShopItems    = require(ReplicatedStorage.Config.ShopItems)

-- Build Lookup Tables
local COIN_PACKS, BOOST_PRODUCTS = {}, {}
for _, item in ipairs(ShopItems.Boosts or {}) do if item.ProductId then BOOST_PRODUCTS[item.ProductId] = true end end
for _, item in ipairs(ShopItems.Robux or {}) do if item.ProductId then COIN_PACKS[item.ProductId] = item.Reward end end

--------------------------------------------------------------------
-- Purchase Receipt Handler
--------------------------------------------------------------------
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end

	local productId = receiptInfo.ProductId
	local granted = false
	print(`[ProductService] Processing receipt for {player.Name}, ProductId: {productId}`)

	-- Handle Coin Pack Purchases
	if COIN_PACKS[productId] then
		print(`[ProductService] Granting coin pack: {COIN_PACKS[productId]} coins.`)
		DataAPI.AddCoins(player, COIN_PACKS[productId])
		granted = true
	end

	-- Handle Boost / Game-Pass Purchases
	if not granted and BOOST_PRODUCTS[productId] then
		print(`[ProductService] Granting boost/game pass...`)
		if BoostService.GrantFromPurchase(player, productId) then
			granted = true
		end
	end

	if granted then
		print(`[ProductService] SUCCESS: Purchase granted for ProductId {productId}.`)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	else
		warn(`[ProductService] FAILED: Unrecognized ProductId processed: {productId}`)
		return Enum.ProductPurchaseDecision.PurchaseGranted -- Consume receipt to prevent retries
	end
end