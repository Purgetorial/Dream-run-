-- ServerScriptService/StatsService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataAPI          = require(game.ServerScriptService.PlayerDataManager)

local Remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
Remotes.Name  = "Remotes"

local GetStatsRF = Remotes:FindFirstChild("GetStats") or Instance.new("RemoteFunction", Remotes)
GetStatsRF.Name  = "GetStats"

-- ? player is the first param
GetStatsRF.OnServerInvoke = function(player)
	-- returns stats table + server-time for boost countdown sync
	return DataAPI.GetStats(player), os.time()
end
