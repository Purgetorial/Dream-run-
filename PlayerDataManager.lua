-- purgetorial/dream-run-/Dream-run--c6e19a1472899b0fe558b182fcfa5a80333cb4a1/PlayerDataManager.lua
--------------------------------------------------------------------
--  PlayerDataManager.lua  •  Luau version (Optimized)
--  • Now uses require() for LeaderboardService, removing _G dependency.
--  • Includes robust autosave and reliable data handling.
--  • ADDED: Upgrades and Perks data structure.
--------------------------------------------------------------------
local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")

-- Service Modules
local LeaderboardService = require(game.ServerScriptService.LeaderboardService)

local MAIN_KEY    = "PlayerData_v3"
local AUTOSAVE_INTERVAL = 60 -- seconds
local store       = DataStoreService:GetDataStore(MAIN_KEY)

--------------------------------------------------------------------
--  Default structure
--------------------------------------------------------------------
local function getDefaultData()
	return {
		BestTime          = math.huge,
		Prestige          = 0,
		Coins             = 0,
		TotalCoinsEarned  = 0,
		RunsFinished      = 0,
		CurrentStage      = 1, -- NEW: Track player's current stage
		OwnedCosmetics    = {},
		EquippedCosmetics = {},
		Gamepasses        = {},
		-- Upgrades that reset on prestige
		Upgrades = {
			MaxSpeed    = 0,
			SprintSpeed = 0,
			Stamina     = 0,
		},
		-- Perks that reset on prestige (unless from a game pass)
		Perks = {
			DoubleJump      = false,
			SprintUnlocked  = false,
			DoubleCoins     = false, -- For coin-purchased version
		}
	}
end


--------------------------------------------------------------------
--  In-memory cache & dirty flag system
--------------------------------------------------------------------
local session: {[number]: any} = {}
local dirty:   {[number]: boolean} = {} -- Tracks players whose data has changed and needs saving

--------------------------------------------------------------------
--  Utilities
--------------------------------------------------------------------
local function deepClone(tbl)
	local clone = {}
	for k, v in pairs(tbl) do
		clone[k] = (typeof(v) == "table") and deepClone(v) or v
	end
	return clone
end

-- Ensure nested tables exist to prevent errors
local function ensure(tbl, key, default)
	if not tbl[key] then tbl[key] = default end
	return tbl[key]
end

--------------------------------------------------------------------
--  DataStore wrappers (with retries)
--------------------------------------------------------------------
local function loadData(userId: number)
	for i = 1, 3 do
		local ok, data = pcall(function()
			return store:GetAsync("ID_" .. userId)
		end)
		if ok then
			local defaultData = getDefaultData()
			local loadedData = data or deepClone(defaultData)
			-- Ensure all default keys are present to prevent errors with new features
			for key, value in pairs(defaultData) do
				if loadedData[key] == nil then
					loadedData[key] = value
					-- NEW: Also check for nested tables
				elseif typeof(value) == "table" then
					for subKey, subValue in pairs(value) do
						if loadedData[key][subKey] == nil then
							loadedData[key][subKey] = subValue
						end
					end
				end
			end
			return loadedData
		end
		warn(("[DataStore] Load failed for %d (attempt %d). Retrying..."):format(userId, i))
		task.wait(2)
	end
	warn(("[DataStore] CRITICAL: Could not load data for %d after 3 attempts. Using default data."):format(userId))
	return getDefaultData()
end

local function saveData(userId: number)
	local data = session[userId]
	if not (data and dirty[userId]) then return true end -- Only save if data exists and is dirty

	for i = 1, 3 do
		local ok, err = pcall(function()
			store:SetAsync("ID_" .. userId, data)
		end)
		if ok then
			dirty[userId] = nil -- Mark as no longer needing a save
			return true
		end
		warn(("[DataStore] Save failed for %d (attempt %d): %s"):format(userId, i, tostring(err)))
		task.wait(2)
	end
	warn(("[DataStore] CRITICAL: Could not save data for %d after 3 attempts."):format(userId))
	return false
end

--------------------------------------------------------------------
--  Leaderstats
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
--  Player join / leave & Autosave
--------------------------------------------------------------------
Players.PlayerAdded:Connect(function(plr)
	local data = loadData(plr.UserId)
	session[plr.UserId] = data
	setupLeaderstats(plr, data)

	-- Keep global board in sync using the required module
	LeaderboardService.UpdatePrestige(plr, data.Prestige)
	LeaderboardService.UpdateBestTime(plr, data.BestTime)
end)

Players.PlayerRemoving:Connect(function(plr)
	saveData(plr.UserId)
	session[plr.UserId] = nil
	dirty[plr.UserId] = nil
end)

-- Autosave loop
task.spawn(function()
	while task.wait(AUTOSAVE_INTERVAL) do
		for userId, _ in pairs(dirty) do
			if Players:GetPlayerByUserId(userId) then -- Check if player is still in game
				saveData(userId)
			end
		end
	end
end)

game:BindToClose(function()
	if RunService:IsStudio() then return end
	-- Save all dirty data one last time before shutdown
	for userId, _ in pairs(dirty) do
		if Players:GetPlayerByUserId(userId) then
			saveData(userId)
		end
	end
end)

--------------------------------------------------------------------
--  PUBLIC API
--------------------------------------------------------------------
local DataAPI = {}
DataAPI.GetDefaultData = getDefaultData -- Expose for resetting on prestige

function DataAPI.Get(plr: Player)
	return session[plr.UserId]
end

function DataAPI.Save(plr: Player)
	warn("DataAPI.Save is deprecated and should be removed. Saving is automatic.")
end

function DataAPI.Set(plr: Player, key: string, value: any)
	local d = session[plr.UserId]
	if d and d[key] ~= value then
		d[key] = value
		dirty[plr.UserId] = true
	end
end

function DataAPI.AddCoins(plr: Player, amount: number)
	local d = session[plr.UserId] ; if not d then return end
	d.Coins            = (d.Coins or 0) + amount
	if amount > 0 then
		d.TotalCoinsEarned = (d.TotalCoinsEarned or 0) + amount
	end
	dirty[plr.UserId] = true

	local ls = plr:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Coins") then
		ls.Coins.Value = d.Coins
	end
end

function DataAPI.IncrementRuns(plr: Player)
	local d = session[plr.UserId]
	if not d then return end
	d.RunsFinished = (d.RunsFinished or 0) + 1
	dirty[plr.UserId] = true
end

function DataAPI.UpdateBestTime(plr: Player, newTime: number)
	local d = session[plr.UserId]; if not d then return end
	if newTime < (d.BestTime or math.huge) then
		d.BestTime = newTime
		dirty[plr.UserId] = true

		local ls = plr:FindFirstChild("leaderstats")
		if ls and ls:FindFirstChild("BestTime") then
			ls.BestTime.Value = newTime
		end

		-- Push to global leaderboard service
		LeaderboardService.UpdateBestTime(plr, newTime)
	end
end

function DataAPI.GetStats(plr: Player)
	local d = session[plr.UserId] or getDefaultData()
	return {
		Prestige     = d.Prestige,
		BestTime     = d.BestTime,
		Coins        = d.Coins,
		TotalCoins   = d.TotalCoinsEarned,
		RunsFinished = d.RunsFinished,
	}
end

return DataAPI