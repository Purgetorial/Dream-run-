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

--------------------------------------------------------------------  ensure RemoteEvents exist
local RequestPrestige  = Remotes:FindFirstChild("RequestPrestige")
	or Instance.new("RemoteEvent", Remotes)
RequestPrestige.Name   = "RequestPrestige"

local PrestigeConfirmed = Remotes:FindFirstChild("PrestigeConfirmed")
	or Instance.new("RemoteEvent", Remotes)
PrestigeConfirmed.Name  = "PrestigeConfirmed"

--------------------------------------------------------------------  dependencies
local DataAPI = require(game.ServerScriptService.PlayerDataManager)

--------------------------------------------------------------------  configurable cost formula
-- By default:  100 000 coins × (current prestige + 1)
local function prestigeCost(currentPrestige: number): number
	return 100_000 * (currentPrestige + 1)
end

--------------------------------------------------------------------  helper to sync leaderstats
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

--------------------------------------------------------------------  server-side handler
RequestPrestige.OnServerEvent:Connect(function(plr)
	local d = DataAPI.Get(plr)
	if not d then
		PrestigeConfirmed:FireClient(plr, false, "Data not found")
		return
	end

	local cost = prestigeCost(d.Prestige)
	if d.Coins < cost then
		PrestigeConfirmed:FireClient(plr, false, "Not enough coins")
		return
	end

	-- perform prestige
	d.Coins        -= cost
	d.Prestige     += 1
	d.BestTime      = math.huge
	d.RunsFinished  = 0
	-- optional: reset other per-run stats here

	DataAPI.Save(plr)
	syncLeaderstats(plr, d)

	-- tell client we succeeded & new prestige level
	PrestigeConfirmed:FireClient(plr, true, d.Prestige)
end)
