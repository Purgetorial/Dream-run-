-- ShopService.lua  |  central entry for all coin-based shop purchases

local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Players            = game:GetService("Players")

local ShopItems     = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("ShopItems"))
local DataAPI        = require(game.ServerScriptService.PlayerDataManager)
local BoostService   = _G.BoostService       -- becomes non-nil after BoostService.lua loads

-- Remote from the UI (ShopController)
local Remotes   = ReplicatedStorage:WaitForChild("Remotes")
local BuyItem   = Remotes:FindFirstChild("BuyItem") or Instance.new("RemoteFunction", Remotes)
BuyItem.Name    = "BuyItem"

--------------------------------------------------------------------
-- ?  fast lookup tables  ?
--------------------------------------------------------------------
local cosmeticsByName = {}      -- [itemName] = itemInfo
for _, item in ipairs(ShopItems.Cosmetics or {}) do
	cosmeticsByName[item.Name] = item
end

local boostsByName = {}         -- optional coin-priced boosts
for _, item in ipairs(ShopItems.Boosts or {}) do
	if item.Price and not item.ProductId then
		boostsByName[item.BoostName] = item
	end
end

--------------------------------------------------------------------
-- ?  helpers  ?
--------------------------------------------------------------------
local function updateCoinsLeaderstat(player, newAmount)
	local stats = player:FindFirstChild("leaderstats")
	if stats and stats:FindFirstChild("Coins") then
		stats.Coins.Value = newAmount
	end
end

local function chargeCoins(player, price)
	local data = DataAPI.Get(player)
	if not data or (data.Coins or 0) < price then return false end
	data.Coins -= price
	updateCoinsLeaderstat(player, data.Coins)
	return true
end

--------------------------------------------------------------------
-- ?  main handler  ?
--------------------------------------------------------------------
BuyItem.OnServerInvoke = function(player, tab, itemName)
	if not player or not tab or not itemName then return false end
	local data = DataAPI.Get(player)
	if not data then return false end

	-- COSMETICS
	if tab == "Cosmetics" then
		local info = cosmeticsByName[itemName]
		if not info then return false end
		if not chargeCoins(player, info.Price) then return false end

		data.OwnedCosmetics[info.Tab] = data.OwnedCosmetics[info.Tab] or {}
		for _, v in ipairs(data.OwnedCosmetics[info.Tab]) do
			if v == itemName then return true end -- already owned
		end
		table.insert(data.OwnedCosmetics[info.Tab], itemName)
		DataAPI.Save(player)

		return true
	end

	-- BOOSTS
	if tab == "Boosts" then
		local info = boostsByName[itemName]
		if not info then return false end
		if not chargeCoins(player, info.Price) then return false end

		if BoostService and BoostService.Activate then
			BoostService.Activate(player, itemName, info.Duration)
		end
		return true
	end

	return false
end


