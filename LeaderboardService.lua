-- LeaderboardService.lua  |  global PB & Prestige leaderboards
local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

-- Ordered stores
local BestTimeStore = DataStoreService:GetOrderedDataStore("GlobalBestTime_v1") -- stores -milliseconds (int)
local PrestigeStore = DataStoreService:GetOrderedDataStore("GlobalPrestige_v1")

-- RemoteFunction to client
local Remotes  = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder",ReplicatedStorage)
Remotes.Name   = "Remotes"
local RequestLeaderboard = Remotes:FindFirstChild("RequestLeaderboard") or Instance.new("RemoteFunction",Remotes)
RequestLeaderboard.Name  = "RequestLeaderboard"

--------------------------------------------------------------------
-- helpers
--------------------------------------------------------------------
local function updateBestTime(player, seconds)
	if not seconds or seconds <= 0 then return end
	local key = tostring(player.UserId)

	local ms   = math.floor(seconds * 1000 + 0.5)      -- ? int milliseconds
	local neg  = -ms                                   -- lower is faster

	local ok, current = pcall(BestTimeStore.GetAsync, BestTimeStore, key)
	if ok and (not current or neg < current) then
		pcall(BestTimeStore.SetAsync, BestTimeStore, key, neg)
	end
end

local function updatePrestige(player, prestige:number)
	if not prestige or prestige < 0 then return end
	local key = tostring(player.UserId)

	-- always overwrite if the value changed (higher OR lower)
	local ok, cur = pcall(PrestigeStore.GetAsync, PrestigeStore, key)
	if ok and cur == prestige then return end  -- no change

	pcall(PrestigeStore.SetAsync, PrestigeStore, key, prestige)
end

_G.LeaderboardService = {
	UpdateBestTime   = updateBestTime,
	UpdatePrestige   = updatePrestige,
}

--------------------------------------------------------------------
-- RemoteFunction implementation
--------------------------------------------------------------------
local PAGE = 50
RequestLeaderboard.OnServerInvoke = function(_, boardType)
	boardType = boardType or "BestTime"
	local store = (boardType=="Prestige") and PrestigeStore or BestTimeStore
	local desc  = false                                   -- high?low
	local data  = store:GetSortedAsync(desc, PAGE):GetCurrentPage()

	local result = {}
	for rank, entry in ipairs(data) do
		local uid  = tonumber(entry.key)
		local name = "Player"
		local plr  = Players:GetPlayerByUserId(uid)
		if plr then name = plr.Name else
			pcall(function() name = Players:GetNameFromUserIdAsync(uid) end)
		end

		local bestSeconds = math.abs(entry.value) / 1000   -- ? convert back
		local prestigeVal = (boardType=="Prestige")
			and entry.value
			or (PrestigeStore:GetAsync(entry.key) or 0)

		table.insert(result, {
			Name      = name,
			BestTime  = bestSeconds,
			Prestige  = prestigeVal,
		})
	end
	return result
end
