-- purgetorial/dream-run-/Dream-run--c6e19a1472899b0fe558b182fcfa5a80333cb4a1/PrestigeConfirmedHandler.lua
--------------------------------------------------------------------
-- PrestigeConfirmedHandler.lua (Updated with Stat Resets & Rewards)
--------------------------------------------------------------------
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local Players             = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Service Modules
local DataAPI            = require(ServerScriptService.PlayerDataManager)
local AntiExploitService = require(ServerScriptService.AntiExploitService)
local PrestigeCfg        = require(ReplicatedStorage.Config.PrestigeConfig) -- NEW

-- Remotes
local Remotes           = ReplicatedStorage:WaitForChild("Remotes")
local RequestPrestige   = Remotes:WaitForChild("RequestPrestige")
local PrestigeConfirmed = Remotes:WaitForChild("PrestigeConfirmed")
local TeleportToLobby   = ReplicatedStorage:WaitForChild("TeleportToLobby")

--------------------------------------------------------------------
-- Server-side handler
--------------------------------------------------------------------
RequestPrestige.OnServerEvent:Connect(function(player)
	if not AntiExploitService.Validate(player, "RequestPrestige") then return end

	local d = DataAPI.Get(player)
	if not d then
		PrestigeConfirmed:FireClient(player, false, "Data not found")
		return
	end

	-- Perform prestige
	d.Prestige += 1
	d.BestTime = math.huge
	d.CurrentStage = 1 

	-- NEW: Grant lump sum coin reward
	local coinReward = d.Prestige * PrestigeCfg.LUMP_COIN_AWARD_PER_LEVEL
	DataAPI.AddCoins(player, coinReward)

	-- Reset Upgrades and Perks to default
	local defaultData = DataAPI.GetDefaultData()
	d.Upgrades = defaultData.Upgrades
	d.Perks = defaultData.Perks

	-- Use the Set helper to mark data as dirty for saving
	DataAPI.Set(player, "Prestige", d.Prestige)
	DataAPI.Set(player, "BestTime", d.BestTime)
	DataAPI.Set(player, "CurrentStage", d.CurrentStage)
	DataAPI.Set(player, "Upgrades", d.Upgrades)
	DataAPI.Set(player, "Perks", d.Perks)


	-- Sync leaderstats
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		if ls:FindFirstChild("Prestige") then ls.Prestige.Value = d.Prestige end
		if ls:FindFirstChild("BestTime") then ls.BestTime.Value = d.BestTime end
	end

	-- Tell client we succeeded and teleport them
	PrestigeConfirmed:FireClient(player, true, d.Prestige)
	TeleportToLobby:FireClient(player)
end)