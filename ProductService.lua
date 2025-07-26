--------------------------------------------------------------------
-- ProductService.lua · handles ALL Developer Products / Game-passes
--------------------------------------------------------------------
local MPS     = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local Rep     = game:GetService("ReplicatedStorage")

local DataAPI      = require(game.ServerScriptService.PlayerDataManager)
local BoostService = _G.BoostService
local ShopItems    = require(Rep:WaitForChild("Config"):WaitForChild("ShopItems"))

--------------------------------------------------------------------  BUILD LOOKUPS
local COIN_PACKS = {}   -- [productId] = amount
local BOOSTS     = {}   -- [productId] = true   (handled by BoostService)

for _, item in ipairs(ShopItems.Robux) do
	if item.Reward == "Boost" then
		BOOSTS[item.ProductId] = true
	elseif typeof(item.Reward)=="number" then
		COIN_PACKS[item.ProductId] = item.Reward
	end
end

--------------------------------------------------------------------  RECEIPT
MPS.ProcessReceipt = function(receiptInfo)
	local pl = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not pl then return Enum.ProductPurchaseDecision.NotProcessedYet end

	-- Coin packs
	local coins = COIN_PACKS[receiptInfo.ProductId]
	if coins then
		local data = DataAPI.Get(pl)
		if data then
			data.Coins += coins
			local ls = pl:FindFirstChild("leaderstats")
			if ls and ls:FindFirstChild("Coins") then ls.Coins.Value = data.Coins end
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- Boosts / Game-passes
	if BOOSTS[receiptInfo.ProductId] and BoostService and BoostService._grantGamePass then
		if BoostService._grantGamePass(pl, receiptInfo.ProductId) then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end
