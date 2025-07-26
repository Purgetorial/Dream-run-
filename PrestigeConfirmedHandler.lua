--------------------------------------------------------------------
-- PrestigeConfirmedHandler.lua
--  • Handles “Prestige” button presses
--  • Deducts coins, increments Prestige, resets run-stats
--  • Fires PrestigeConfirmed client event on success / failure
--------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
	Remotes = Instance.new("Folder", ReplicatedStorage)
	Remotes.Name = "Remotes"
end

--------------------------------------------------------------------  -- ensure RemoteEvents exist
local RequestPrestige  = Remotes:FindFirstChild("RequestPrestige")
	or Instance.new("RemoteEvent", Remotes)
RequestPrestige.Name   = "RequestPrestige"

local PrestigeConfirmed = Remotes:FindFirstChild("PrestigeConfirmed")
	or Instance.new("RemoteEvent", Remotes)
PrestigeConfirmed.Name  = "PrestigeConfirmed"

--[[ ADD THIS: Ensure TeleportToLobby remote exists so we can fire it ]]
local TeleportToLobby = ReplicatedStorage:FindFirstChild("TeleportToLobby")
	or Instance.new("RemoteEvent", ReplicatedStorage)
TeleportToLobby.Name  = "TeleportToLobby"


--------------------------------------------------------------------  -- dependencies
local DataAPI = require(game.ServerScriptService.PlayerDataManager)

--------------------------------------------------------------------  -- server-side handler
RequestPrestige.OnServerEvent:Connect(function(plr)
	local d = DataAPI.Get(plr)
	if not d then
		PrestigeConfirmed:FireClient(plr, false, "Data not found")
		return
	end

	--[[
		REMOVED THE COST CHECK: The original code had a cost check here
		that we are removing to make prestiging free.
	]]

	-- perform prestige
	d.Prestige     += 1
	d.BestTime      = math.huge
	d.RunsFinished  = 0
	-- optional: reset other per-run stats here

	DataAPI.Save(plr)

	-- You can remove this function if you want, or keep it for leaderstat syncing
	local function syncLeaderstats(plr, data)
		local ls = plr:FindFirstChild("leaderstats")
		if not ls then return end
		if ls:FindFirstChild("Prestige") then
			ls.Prestige.Value = data.Prestige
		end
		if ls:FindFirstChild("Coins") then
			ls.Coins.Value = data.Coins
		end
	end

	syncLeaderstats(plr, d)

	-- tell client we succeeded & new prestige level
	PrestigeConfirmed:FireClient(plr, true, d.Prestige)

	--[[ ADD THIS: Teleport the player back to the lobby after prestiging ]]
	TeleportToLobby:FireClient(plr)
end)