-- purgetorial/dream-run-/Dream-run--c6e19a1472899b0fe558b182fcfa5a80333cb4a1/BoostService.lua
--------------------------------------------------------------------
-- BoostService.lua · (Simplified for new structure)
--------------------------------------------------------------------
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

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
		-- Create a BoolValue for all boosts, regardless of duration
		local boolValue = Instance.new("BoolValue")
		boolValue.Name = boostName
		boolValue.Parent = activeBoostsFolder
	end
end)


-- Public function called by ProductService
function BoostService.GrantFromPurchase(player, productId: number)
	for boostName, def in pairs(BOOST_DEFINITIONS) do
		if def.ProductId == productId then
			-- We will add new logic here in a later step
			return true
		end
	end
	return false
end

return BoostService