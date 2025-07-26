--------------------------------------------------------------------
-- BoostService.lua · (Final, TYPO-FIXED & Data-Aware Version)
-- • FIX: Corrected the typo in GetService("ServerScriptService").
-- • FIX: Waits for player data to be loaded before granting a game pass.
--------------------------------------------------------------------
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService") -- TYPO FIXED

-- Service Modules
local DataAPI      = require(ServerScriptService.PlayerDataManager)
local ShopItems    = require(ReplicatedStorage.Config.ShopItems)

-- Module Interface
local BoostService = {}

-- Dynamically build config from ShopItems
local BOOST_DEFINITIONS = {}
for _, item in ipairs(ShopItems.Boosts) do
	BOOST_DEFINITIONS[item.BoostName] = { Duration = item.Duration, ProductId = item.ProductId }
end

-- Remotes
local Remotes  = ReplicatedStorage:WaitForChild("Remotes")
local ToggleLowGravity = Remotes:WaitForChild("ToggleLowGravity")

-- Initialize ActiveBoosts folder
Players.PlayerAdded:Connect(function(p)
	local activeBoostsFolder = Instance.new("Folder")
	activeBoostsFolder.Name = "ActiveBoosts"
	activeBoostsFolder.Parent = p
	for boostName, def in pairs(BOOST_DEFINITIONS) do
		if def.Duration and def.Duration > 0 then
			local boolValue = Instance.new("BoolValue")
			boolValue.Name = boostName
			boolValue.Parent = activeBoostsFolder
		end
	end
end)

-- Private grant function
local function grantLightspeed(player)
	-- KEY FIX: Wait for player data to exist
	local data = DataAPI.Get(player)
	if not data then
		for _ = 1, 50 do -- Wait up to 5 seconds for data
			task.wait(0.1)
			data = DataAPI.Get(player)
			if data then break end
		end
		if not data then
			warn(`[BoostService] Grant failed: Data for {player.Name} never loaded.`)
			return
		end
	end

	print(`[BoostService] Granting Lightspeed to {player.Name}`)

	if not player:FindFirstChild("PermanentLightspeed") then
		local tag = Instance.new("BoolValue"); tag.Name = "PermanentLightspeed"; tag.Parent = player
	end

	local gamepasses = data.Gamepasses or {}; gamepasses.Lightspeed = true
	local cosmetics = data.OwnedCosmetics or {}; cosmetics.Trails = cosmetics.Trails or {}
	if not table.find(cosmetics.Trails, "Lightspeed Trail") then
		table.insert(cosmetics.Trails, "Lightspeed Trail")
	end

	DataAPI.Set(player, "Gamepasses", gamepasses)
	DataAPI.Set(player, "OwnedCosmetics", cosmetics)
end

-- Public function called by ProductService
function BoostService.GrantFromPurchase(player, productId: number)
	for boostName, def in pairs(BOOST_DEFINITIONS) do
		if def.ProductId == productId then
			if boostName == "Lightspeed" then
				grantLightspeed(player)
			else
				-- This is where you would apply timed boosts
			end
			return true
		end
	end
	return false
end

return BoostService