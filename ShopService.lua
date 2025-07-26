--------------------------------------------------------------------
-- ShopService.lua  |  (Final, Simplified Version)
-- • FIX: Now ONLY handles coin-based cosmetic purchases.
-- • Robux purchases are correctly handled by the client and ProductService.
--------------------------------------------------------------------
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players             = game:GetService("Players")

-- Service Modules
local DataAPI            = require(ServerScriptService.PlayerDataManager)
local AntiExploitService = require(ServerScriptService.AntiExploitService)
local ShopItems          = require(ReplicatedStorage.Config.ShopItems)

-- Remote from the UI
local Remotes   = ReplicatedStorage:WaitForChild("Remotes")
local BuyItemRF = Remotes:WaitForChild("BuyItem")

--------------------------------------------------------------------
-- Fast lookup for cosmetic items
--------------------------------------------------------------------
local cosmeticsByName = {}
for _, item in ipairs(ShopItems.Cosmetics or {}) do
	cosmeticsByName[item.Name] = item
end

--------------------------------------------------------------------
-- Helper to charge coins
--------------------------------------------------------------------
local function chargeCoins(player, price)
	local data = DataAPI.Get(player)
	if not data or (data.Coins or 0) < price then
		return false
	end
	DataAPI.AddCoins(player, -price)
	return true
end

--------------------------------------------------------------------
-- Main Purchase Handler (For Coins ONLY)
--------------------------------------------------------------------
BuyItemRF.OnServerInvoke = function(player, tab: string, itemName: string)
	if not AntiExploitService.Validate(player, "BuyItem") then return false end

	-- This remote now only handles Cosmetics, as they are the only coin items.
	if tab ~= "Cosmetics" then return false end

	local itemInfo = cosmeticsByName[itemName]
	if not (itemInfo and itemInfo.Price) then return false end

	local data = DataAPI.Get(player)
	if not data then return false end

	local ownedCosmetics = data.OwnedCosmetics or {}
	local ownedCategory = ownedCosmetics[itemInfo.Tab] or {}
	if table.find(ownedCategory, itemName) then
		return true -- Already owned
	end

	if not chargeCoins(player, itemInfo.Price) then
		return false
	end

	table.insert(ownedCategory, itemName)
	data.OwnedCosmetics[itemInfo.Tab] = ownedCategory
	DataAPI.Set(player, "OwnedCosmetics", data.OwnedCosmetics)

	return true
end