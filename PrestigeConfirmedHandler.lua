--------------------------------------------------------------------
-- PrestigeConfirmedHandler.lua (Updated with Anti-Exploit)
-- • Calls the new AntiExploitService to validate requests.
--------------------------------------------------------------------
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local Players             = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Service Modules
local DataAPI            = require(ServerScriptService.PlayerDataManager)
local AntiExploitService = require(ServerScriptService.AntiExploitService)

-- Remotes
local Remotes           = ReplicatedStorage:WaitForChild("Remotes")
local RequestPrestige   = Remotes:WaitForChild("RequestPrestige")
local PrestigeConfirmed = Remotes:WaitForChild("PrestigeConfirmed")
local TeleportToLobby   = ReplicatedStorage:WaitForChild("TeleportToLobby")

--------------------------------------------------------------------
-- Server-side handler
--------------------------------------------------------------------
RequestPrestige.OnServerEvent:Connect(function(player)
	-- Call the validator first
	if not AntiExploitService.Validate(player, "RequestPrestige") then return end

	local d = DataAPI.Get(player)
	if not d then
		PrestigeConfirmed:FireClient(player, false, "Data not found")
		return
	end

	-- Perform prestige
	d.Prestige += 1
	d.BestTime = math.huge
	DataAPI.Set(player, "Prestige", d.Prestige) -- Use the Set helper to mark as dirty
	DataAPI.Set(player, "BestTime", d.BestTime)

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