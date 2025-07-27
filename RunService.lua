-- purgetorial/dream-run-/Dream-run--c6e19a1472899b0fe558b182fcfa5a80333cb4a1/RunService.lua
--------------------------------------------------------------------
-- RunService.lua • speed, stamina, run-timer, STAGE PROGRESSION
--------------------------------------------------------------------
local Players, WS, RS, Rep = game:GetService("Players"),
	game:GetService("Workspace"),
	game:GetService("RunService"),
	game:GetService("ReplicatedStorage")

local DataAPI         = require(game.ServerScriptService.PlayerDataManager)
local LocationService = require(Rep.LocationService)
local SpeedCfg        = require(Rep.Config.SpeedConfig)
local PrestigeCfg     = require(Rep.Config.PrestigeConfig) -- NEW


------------------------------ Remotes -----------------------------
local R             = Rep:WaitForChild("Remotes")
local StartRun      = R:WaitForChild("StartRun")
local FinishRun     = R:WaitForChild("FinishRun")
local SprintEvt     = R:WaitForChild("SprintToggle")
local BoostFX       = R:WaitForChild("BoostBroadcast")
local TrailTog      = R:WaitForChild("TrailToggle")
local ReqRunStart   = Rep.Remotes:WaitForChild("RequestRunStart")
local TeleportStart = Rep:WaitForChild("TeleportToStart")
local OpenPrestige  = Rep:WaitForChild("OpenPrestige")

-- New remote to inform client of stage completion
local StageComplete = Rep.Remotes:FindFirstChild("StageComplete") or Instance.new("RemoteEvent", Rep.Remotes)
StageComplete.Name  = "StageComplete"

TrailTog.OnServerEvent:Connect(function(p,on) TrailTog:FireClient(p,on) end)

---------------------------- Constants ----------------------------
local SPRINT_MULT, ACCEL_RATE   = 0.50 , 20
local REST_FRAC, MAX_STAM       = 0.50 , 100
local DRAIN_RATE, REGEN_RATE    = 38   , 22
local TOTAL_STAGES = 10

--------------------------- Helpers -------------------------------
local function baseSpeed(pl)
	local d  = DataAPI.Get(pl)
	local pr = d and d.Prestige or 0
	-- NEW: Calculate speed with the prestige bonus
	local prestigeSpeedBonus = pr * PrestigeCfg.SPEED_BONUS_PER_LEVEL
	return SpeedCfg.BASE_SPEED + prestigeSpeedBonus
end

--------------------------- State tables --------------------------
local targetSpeed, sprinting, idleTimer, running = {}, {}, {}, {}

-------------------------- Sprint toggle --------------------------
local function setSprint(plr, on)
	if on then
		local s = plr:FindFirstChild("Stamina")
		if not (s and s.Value >= MAX_STAM) then return end
	end
	if sprinting[plr.UserId] == on then return end
	sprinting[plr.UserId] = on

	BoostFX:FireClient(plr, on)
	task.defer(function()
		local base = baseSpeed(plr)
		targetSpeed[plr.UserId] = on and base*(1+SPRINT_MULT) or base
	end)
end
SprintEvt.OnServerEvent:Connect(setSprint)

----------------------------- Char init ---------------------------
Players.PlayerAdded:Connect(function(plr)
	local st = Instance.new("NumberValue", plr)
	st.Name, st.Value = "Stamina", MAX_STAM

	plr.CharacterAdded:Connect(function(c)
		local hum = c:WaitForChild("Humanoid")
		local cur = Instance.new("IntValue", c); cur.Name="CurrentSpeed"
		hum.WalkSpeed          = 0
		local base             = baseSpeed(plr)
		targetSpeed[plr.UserId]= base
		cur.Value              = base
		sprinting[plr.UserId]  = false
		idleTimer[plr.UserId]  = 0
	end)
end)

----------------------------- Heartbeat ---------------------------
RS.Heartbeat:Connect(function(dt)
	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character; if not char then continue end
		local hum  = char:FindFirstChildOfClass("Humanoid")
		local cur  = char:FindFirstChild("CurrentSpeed"); if not (hum and cur) then continue end

		if hum.MoveDirection.Magnitude == 0 then
			idleTimer[plr.UserId] += dt
			if idleTimer[plr.UserId] > 0.1 then
				targetSpeed[plr.UserId] = baseSpeed(plr) * REST_FRAC
			end
		else
			idleTimer[plr.UserId] = 0
			if not sprinting[plr.UserId] then targetSpeed[plr.UserId] = baseSpeed(plr) end
		end
		local s = plr.Stamina
		if sprinting[plr.UserId] then
			s.Value = math.max(0, s.Value - DRAIN_RATE*dt)
			if s.Value == 0 then setSprint(plr,false) end
		else
			s.Value = math.min(MAX_STAM, s.Value + REGEN_RATE*dt)
		end
		local goal = targetSpeed[plr.UserId] or baseSpeed(plr)
		local diff = goal - hum.WalkSpeed
		local step = ACCEL_RATE * dt
		hum.WalkSpeed += math.clamp(diff,-step,step)
		cur.Value = goal
	end
end)

---------------------------- Run timer ----------------------------
ReqRunStart.OnServerEvent:Connect(function(plr)
	if running[plr.UserId] then return end
	local data = DataAPI.Get(plr)
	if not data then return end

	if plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") then
		plr.Character.Humanoid.WalkSpeed = 0
	end
	setSprint(plr,false)

	-- Start at the player's current stage
	local startCFrame = LocationService.GetStartCFrame(data.CurrentStage)
	TeleportStart:FireClient(plr, startCFrame)
	running[plr.UserId] = tick()

	local best = (plr.leaderstats and plr.leaderstats:FindFirstChild("BestTime"))
		and plr.leaderstats.BestTime.Value or math.huge
	StartRun:FireClient(plr, best)
end)


----------------------- Stage Completion Logic --------------------
local function onFinishPadTouched(hit, stageNumber)
	local plr = Players:GetPlayerFromCharacter(hit.Parent)
	if not plr then return end

	local t0  = running[plr.UserId]
	if not t0 then return end -- Not currently running

	local data = DataAPI.Get(plr)
	if not data or data.CurrentStage ~= stageNumber then
		-- Touched the wrong finish line, ignore
		return
	end

	-- Player completed the correct stage
	if stageNumber < TOTAL_STAGES then
		-- Advance to the next stage
		data.CurrentStage += 1
		DataAPI.Set(plr, "CurrentStage", data.CurrentStage)

		local nextStageCFrame = LocationService.GetStartCFrame(data.CurrentStage)
		TeleportStart:FireClient(plr, nextStageCFrame)
		StageComplete:FireClient(plr, stageNumber, data.CurrentStage)

	else -- Player completed the final stage
		running[plr.UserId] = nil -- Stop the run

		local elapsed = tick() - t0
		DataAPI.UpdateBestTime(plr, elapsed)
		DataAPI.IncrementRuns(plr)

		FinishRun:FireClient(plr, elapsed)
		OpenPrestige:FireClient(plr) -- Show prestige panel
	end
end

-- Connect the Touched event to all finish pads
task.spawn(function()
	local stagesFolder = WS:WaitForChild("GeneratedStages")
	for i = 1, TOTAL_STAGES do
		local stage = stagesFolder:WaitForChild("Stage"..i)
		local finishPad = stage and stage:WaitForChild("FinishPad")
		if finishPad then
			finishPad.Touched:Connect(function(hit)
				onFinishPadTouched(hit, i)
			end)
		end
	end
end)