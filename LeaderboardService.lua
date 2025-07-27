--------------------------------------------------------------------
-- LeaderboardService.lua  |  global PB & Prestige leaderboards (ModuleScript)
-- • Converted to a ModuleScript to remove reliance on _G.
-- • Handles fetching and updating global leaderboard data.
--------------------------------------------------------------------
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

-- The main module table we will return
local LeaderboardService = {}

--------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------
function LeaderboardService.UpdateBestTime(player, seconds)
	if not (player and seconds and seconds > 0 and seconds ~= math.huge) then return end
	local key = tostring(player.UserId)

	-- We store negative milliseconds so lower (faster) times rank higher
	local ms   = math.floor(seconds * 1000)
	local valueToStore  = -ms

	-- NEW: Added explicit logging for success and failure.
	local success, err = pcall(function()
		BestTimeStore:SetAsync(key, valueToStore)
	end)

	if not success then
		warn(("[LeaderboardService] SetAsync failed for BestTimeStore. Player: %s, Error: %s"):format(player.Name, tostring(err)))
	else
		print(("[LeaderboardService] Successfully updated global BestTime for %s to %f seconds."):format(player.Name, seconds))
	end
end

function LeaderboardService.UpdatePrestige(player, prestige:number)
	if not (player and prestige and prestige >= 0) then return end
	local key = tostring(player.UserId)

	pcall(function()
		PrestigeStore:SetAsync(key, prestige)
	end)
end

--------------------------------------------------------------------
-- RemoteFunction Implementation
--------------------------------------------------------------------
local PAGE_SIZE = 50
RequestLeaderboard.OnServerInvoke = function(_, boardType: string)
	boardType = (boardType == "Prestige") and "Prestige" or "BestTime"
	local store = (boardType == "Prestige") and PrestigeStore or BestTimeStore

	-- For BestTime, ascending is false (higher negative number is better)
	-- For Prestige, ascending is false (higher prestige is better)
	local isAscending = false 

	local pages = store:GetSortedAsync(isAscending, PAGE_SIZE)
	local data = {}

	local success, result = pcall(function()
		return pages:GetCurrentPage()
	end)

	if not success then
		warn("[LeaderboardService] Failed to get page from DataStore: " .. tostring(result))
		return {} -- Return empty table on failure
	end

	for rank, entry in ipairs(result) do
		local uid = tonumber(entry.key)
		if not uid then continue end

		local name = "Player"
		local prestigeVal = 0

		-- Safely get player name
		local nameSuccess, nameResult = pcall(Players.GetNameFromUserIdAsync, Players, uid)
		if nameSuccess then name = nameResult end

		-- Safely get prestige value
		local prestigeSuccess, prestigeResult = pcall(PrestigeStore.GetAsync, PrestigeStore, tostring(uid))
		if prestigeSuccess and prestigeResult then prestigeVal = prestigeResult end

		-- Convert value back to positive seconds for BestTime board
		local timeValue = (boardType == "BestTime") and (math.abs(entry.value) / 1000) or math.huge

		table.insert(data, {
			Name      = name,
			BestTime  = timeValue,
			Prestige  = prestigeVal,
		})
	end

	return data
end

return LeaderboardService