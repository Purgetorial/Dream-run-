--------------------------------------------------------------------
--  PlayerDataManager.lua  •  Luau version
--------------------------------------------------------------------
local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")

local MAIN_KEY = "PlayerData_v3"
local store    = DataStoreService:GetDataStore(MAIN_KEY)

--------------------------------------------------------------------
--  default structure
--------------------------------------------------------------------
local DEFAULT_DATA = {
	BestTime          = math.huge,
	Prestige          = 0,
	Coins             = 0,

	TotalCoinsEarned  = 0,
	RunsFinished      = 0,

	OwnedCosmetics    = {},
	EquippedCosmetics = {},
}

--------------------------------------------------------------------
--  in-memory cache
--------------------------------------------------------------------
local session: {[number]: any} = {}

--------------------------------------------------------------------
--  utilities
--------------------------------------------------------------------
local function deepClone(tbl)
	local clone = {}
	for k, v in pairs(tbl) do
		clone[k] = (typeof(v) == "table") and deepClone(v) or v
	end
	return clone
end

--------------------------------------------------------------------
--  DataStore wrappers (3 retries)
--------------------------------------------------------------------
local function loadData(userId: number)
	for _ = 1, 3 do
		local ok, data = pcall(function()
			return store:GetAsync("ID_" .. userId)
		end)
		if ok then
			return data or deepClone(DEFAULT_DATA)
		end
		task.wait(1)
	end
	return deepClone(DEFAULT_DATA)
end

local function saveData(userId: number, data)
	for _ = 1, 3 do
		local ok, err = pcall(function()
			store:SetAsync("ID_" .. userId, data)
		end)
		if ok then return true end
		warn("[DataStore] Save failed for", userId, err)
		task.wait(1)
	end
	return false
end

--------------------------------------------------------------------
--  leaderstats (Prestige | Coins | BestTime)
--------------------------------------------------------------------
local function setupLeaderstats(plr: Player, data)
	local ls = Instance.new("Folder")
	ls.Name  = "leaderstats"
	ls.Parent= plr

	local prestige = Instance.new("IntValue")
	prestige.Name  = "Prestige"
	prestige.Value = data.Prestige
	prestige.Parent= ls

	local coins = Instance.new("IntValue")
	coins.Name   = "Coins"
	coins.Value  = data.Coins
	coins.Parent = ls

	local pb = Instance.new("NumberValue")
	pb.Name   = "BestTime"
	pb.Value  = data.BestTime
	pb.Parent = ls
end

--------------------------------------------------------------------
--  player join / leave
--------------------------------------------------------------------
Players.PlayerAdded:Connect(function(plr)
	local data = loadData(plr.UserId)
	session[plr.UserId] = data
	setupLeaderstats(plr, data)

	-- ? keep global board in sync
	if _G.LeaderboardService then
		_G.LeaderboardService.UpdatePrestige(plr, data.Prestige)
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	local data = session[plr.UserId]
	if data then
		saveData(plr.UserId, data)
		session[plr.UserId] = nil
	end
end)

game:BindToClose(function()
	if RunService:IsStudio() then return end
	for _, plr in ipairs(Players:GetPlayers()) do
		local data = session[plr.UserId]
		if data then saveData(plr.UserId, data) end
	end
end)

--------------------------------------------------------------------
--  PUBLIC API
--------------------------------------------------------------------
local DataAPI = {}

function DataAPI.Get(plr: Player)
	return session[plr.UserId]
end

function DataAPI.Save(plr: Player)
	return saveData(plr.UserId, session[plr.UserId])
end

function DataAPI.Set(plr: Player, key: string, value)
	local d = session[plr.UserId]
	if d then
		d[key] = value
		DataAPI.Save(plr)
	end
end

-- increment helpers ------------------------------------------------
function DataAPI.AddCoins(plr: Player, amount: number)
	local d = session[plr.UserId] ; if not d then return end
	d.Coins            = (d.Coins or 0) + amount
	d.TotalCoinsEarned = (d.TotalCoinsEarned or 0) + amount

	local ls = plr:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Coins") then
		ls.Coins.Value = d.Coins
	end
end

function DataAPI.IncrementRuns(plr: Player)
	local d = session[plr.UserId]
	if not d then return end
	d.RunsFinished = (d.RunsFinished or 0) + 1
	DataAPI.Save(plr)            -- <-- add this line
end


--------------------------------------------------------------------
-- Best-time helper  (ONLY block shown changed; rest of file same)
--------------------------------------------------------------------
function DataAPI.UpdateBestTime(plr: Player, newTime: number)
	local d = session[plr.UserId]; if not d then return end
	if newTime < (d.BestTime or math.huge) then
		d.BestTime = newTime

		-- live leaderstat update
		local ls = plr:FindFirstChild("leaderstats")
		if ls and ls:FindFirstChild("BestTime") then
			ls.BestTime.Value = newTime
		end

		-- ? push to global leaderboard service (if present)
		if _G.LeaderboardService and _G.LeaderboardService.UpdateBestTime then
			_G.LeaderboardService.UpdateBestTime(plr, newTime)
		end

		DataAPI.Save(plr)
	end
end


--------------------------------------------------------------------
--  Stats helper
--------------------------------------------------------------------
--------------------------------------------------------------------
function DataAPI.GetStats(plr: Player)
	local d = session[plr.UserId] or DEFAULT_DATA
	return {
		Prestige     = d.Prestige,
		BestTime     = d.BestTime,
		Coins        = d.Coins,            -- NEW: current wallet
		TotalCoins   = d.TotalCoinsEarned,
		RunsFinished = d.RunsFinished,
	}
end
--------------------------------------------------------------------


return DataAPI
