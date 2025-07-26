--------------------------------------------------------------------
-- BoostService.lua · timed boosts + permanent Lightspeed pass (ModuleScript)
-- • Converted to a ModuleScript to remove reliance on _G.
-- • Handles activating temporary boosts and permanent game passes.
--------------------------------------------------------------------
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataAPI           = require(game.ServerScriptService.PlayerDataManager)

-- Module Interface
local BoostService = {}

--------------------------------------------------------------------
-- CONFIGURATION
--------------------------------------------------------------------
local PRODUCT = {
	LowGravity   = 3344707026, -- Developer Product (Robux each use)
	DoubleCoins  = 3347370678,
	Lightspeed   = 1339241349, -- Game-pass (permanent)
}

local BOOST_DEFINITIONS = {
	DoubleCoins = {Duration = 120},
	LowGravity  = {Duration = 120},
}

--------------------------------------------------------------------
-- REMOTES
--------------------------------------------------------------------
local Remotes  = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
Remotes.Name   = "Remotes"

local ToggleLowGravity = Remotes:FindFirstChild("ToggleLowGravity") or Instance.new("RemoteEvent", Remotes)
ToggleLowGravity.Name  = "ToggleLowGravity"

--------------------------------------------------------------------
-- Initialize ActiveBoosts folder for players
--------------------------------------------------------------------
Players.PlayerAdded:Connect(function(p)
	local activeBoostsFolder = Instance.new("Folder")
	activeBoostsFolder.Name = "ActiveBoosts"
	activeBoostsFolder.Parent = p

	for boostName, _ in pairs(BOOST_DEFINITIONS) do
		local boolValue = Instance.new("BoolValue")
		boolValue.Name = boostName
		boolValue.Parent = activeBoostsFolder
	end
end)

--------------------------------------------------------------------
-- PRIVATE FUNCTIONS
--------------------------------------------------------------------
local function applyTimedBoost(player, boostName, duration)
	local flag = player:FindFirstChild("ActiveBoosts") and player.ActiveBoosts:FindFirstChild(boostName)
	if not flag or flag.Value then return end -- Don't stack boosts

	flag.Value = true

	-- Special client-side logic for LowGravity
	if boostName == "LowGravity" then
		ToggleLowGravity:FireClient(player, true, duration)
	end

	-- Set an expiration time attribute for the Stats UI
	local expireTime = Instance.new("NumberValue")
	expireTime.Name = "ExpireAt"
	expireTime.Value = os.time() + duration
	expireTime.Parent = flag

	task.delay(duration, function()
		if flag and flag.Parent then
			flag.Value = false
			if expireTime and expireTime.Parent then
				expireTime:Destroy()
			end
			-- Tell client to disable effect if it was visual
			if boostName == "LowGravity" then
				ToggleLowGravity:FireClient(player, false, 0)
			end
		end
	end)
end

local function grantLightspeed(player)
	if not player:FindFirstChild("PermanentLightspeed") then
		local tag = Instance.new("BoolValue")
		tag.Name = "PermanentLightspeed"
		tag.Parent = player
	end

	local data = DataAPI.Get(player)
	if not data then return end

	local gamepasses = data.Gamepasses or {}
	gamepasses.Lightspeed = true
	data.Gamepasses = gamepasses

	local cosmetics = data.OwnedCosmetics or {}
	cosmetics.Trails = cosmetics.Trails or {}
	if not table.find(cosmetics.Trails, "Lightspeed Trail") then
		table.insert(cosmetics.Trails, "Lightspeed Trail")
	end
	data.OwnedCosmetics = cosmetics

	-- Mark data as dirty to trigger autosave
	DataAPI.Set(player, "Gamepasses", data.Gamepasses)
	DataAPI.Set(player, "OwnedCosmetics", data.OwnedCosmetics)
end

--------------------------------------------------------------------
-- PUBLIC INTERFACE (Used by ProductService and ShopService)
--------------------------------------------------------------------
-- This function handles purchases made with Robux
function BoostService.GrantFromPurchase(player, productId: number)
	if productId == PRODUCT.Lightspeed then
		grantLightspeed(player)
		return true
	elseif productId == PRODUCT.LowGravity then
		applyTimedBoost(player, "LowGravity", BOOST_DEFINITIONS.LowGravity.Duration)
		return true
	elseif productId == PRODUCT.DoubleCoins then
		applyTimedBoost(player, "DoubleCoins", BOOST_DEFINITIONS.DoubleCoins.Duration)
		return true
	end
	return false
end

-- This function handles boosts purchased with in-game currency (coins)
function BoostService.Activate(player, boostName: string, duration: number)
	if BOOST_DEFINITIONS[boostName] then
		applyTimedBoost(player, boostName, duration or BOOST_DEFINITIONS[boostName].Duration)
		return true
	end
	return false
end

return BoostService