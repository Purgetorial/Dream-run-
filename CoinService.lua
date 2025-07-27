-- CoinService.lua  |  awards Dream Coins securely (+ anti-spam debounce)

--------------------------------------------------------------------
-- SERVICES & MODULES
--------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local DataAPI           = require(game.ServerScriptService.PlayerDataManager)
local PrestigeCfg       = require(ReplicatedStorage.Config.PrestigeConfig) -- NEW


--------------------------------------------------------------------
-- REMOTE
--------------------------------------------------------------------
local CoinCollected = ReplicatedStorage.Remotes:WaitForChild("CoinCollected")  -- fired by CoinController (client)

--------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------
local COIN_VALUE       = 1       -- base coin
local DEBOUNCE_SECONDS = 0.25    -- ignore repeat calls faster than this

--------------------------------------------------------------------
-- STATE: debounce tracker
-- recent[player][coinIndex] = lastTime tick()
--------------------------------------------------------------------
local recent = {}   -- [player] = { [idx] = t }

--------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------
local function addCoins(player, amount)
	-- updates Coins, TotalCoinsEarned and leaderstat in one place
	DataAPI.AddCoins(player, amount)
end

local function allowCollect(player, coinIndex)
	local now = tick()
	recent[player] = recent[player] or {}
	local last = recent[player][coinIndex] or 0
	if now - last < DEBOUNCE_SECONDS then
		return false
	end
	recent[player][coinIndex] = now
	return true
end

--------------------------------------------------------------------
-- MAIN HANDLER
--------------------------------------------------------------------
CoinCollected.OnServerEvent:Connect(function(player, coinIndex, coinPos)
	-- Basic arg validation
	if typeof(coinIndex) ~= "number" then return end
	if typeof(coinPos)   ~= "Vector3" then return end

	if not allowCollect(player, coinIndex) then
		return
	end

	-- Prestige & boost multipliers
	local data     = DataAPI.Get(player)
	local prestige = (data and data.Prestige) or 0
	local boosts   = player:FindFirstChild("ActiveBoosts")
	local double   = boosts and boosts:FindFirstChild("DoubleCoins") and boosts.DoubleCoins.Value

	-- NEW: Use the bonus from PrestigeConfig
	local mult     = 1 + (prestige * PrestigeCfg.COIN_COLLECT_BONUS_PER_LEVEL)
	local amount   = COIN_VALUE * mult
	if double then amount *= 2 end
	amount = math.floor(amount + 0.5)

	addCoins(player, amount)
end)

--------------------------------------------------------------------
-- CLEAN-UP on leave
--------------------------------------------------------------------
Players.PlayerRemoving:Connect(function(plr)
	recent[plr] = nil
end)