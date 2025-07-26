--------------------------------------------------------------------
-- RunService.lua • speed, stamina, sprint, run-timer
--------------------------------------------------------------------
local Players, WS, RS, Rep = game:GetService("Players"),
	game:GetService("Workspace"),
	game:GetService("RunService"),
	game:GetService("ReplicatedStorage")

local DataAPI   = require(game.ServerScriptService.PlayerDataManager)
local SpeedCfg  = require(Rep.Config.SpeedConfig)

------------------------------ Remotes -----------------------------
local R             = Rep:WaitForChild("Remotes")
local StartRun      = R:WaitForChild("StartRun")
local FinishRun     = R:WaitForChild("FinishRun")
local SprintEvt     = R:WaitForChild("SprintToggle")
local BoostFX       = R:WaitForChild("BoostBroadcast")
local TrailTog      = R:WaitForChild("TrailToggle")
local ReqRunStart   = Rep.Remotes:WaitForChild("RequestRunStart")
local TeleportStart = Rep:WaitForChild("TeleportToStart")

-- ? New: OpenPrestige RemoteEvent (server ? client)
local OpenPrestige  = Rep:FindFirstChild("OpenPrestige")
if not OpenPrestige then
	OpenPrestige          = Instance.new("RemoteEvent")
	OpenPrestige.Name     = "OpenPrestige"
	OpenPrestige.Parent   = Rep
end

TrailTog.OnServerEvent:Connect(function(p,on) TrailTog:FireClient(p,on) end)

------------------------------ Pads -------------------------------
local track = WS:WaitForChild("GeneratedDreamRun")
local sPart = (track.StartPad:IsA("Model")  and track.StartPad.PrimaryPart)  or track.StartPad
local fPart = (track.FinishPad:IsA("Model") and track.FinishPad.PrimaryPart) or track.FinishPad

---------------------------- Constants ----------------------------
local SPRINT_MULT, ACCEL_RATE   = 0.50 , 20
local REST_FRAC, MAX_STAM       = 0.50 , 100
local DRAIN_RATE, REGEN_RATE    = 38   , 22

--------------------------- Helpers -------------------------------
local function baseSpeed(pl)
	local d  = DataAPI.Get(pl)
	local pr = d and d.Prestige or 0
	local ls = (d and d.Gamepasses and d.Gamepasses.Lightspeed)
		or pl:FindFirstChild("PermanentLightspeed")
	local bonus = ls and (SpeedCfg.BOOST_SPEEDS.Lightspeed or 0) or 0
	return SpeedCfg.BASE_SPEED + pr*SpeedCfg.PRESTIGE_DELTA + bonus
end

--------------------------- State tables --------------------------
local targetSpeed, sprinting, idleTimer = {}, {}, {}

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

		-- stamina
		local s = plr.Stamina
		if sprinting[plr.UserId] then
			s.Value = math.max(0, s.Value - DRAIN_RATE*dt)
			if s.Value == 0 then setSprint(plr,false) end
		else
			s.Value = math.min(MAX_STAM, s.Value + REGEN_RATE*dt)
		end

		-- speed easing
		local goal = targetSpeed[plr.UserId] or baseSpeed(plr)
		local diff = goal - hum.WalkSpeed
		local step = ACCEL_RATE * dt
		hum.WalkSpeed += math.clamp(diff,-step,step)
		cur.Value = goal
	end
end)

---------------------------- Run timer ----------------------------
local running = {}
ReqRunStart.OnServerEvent:Connect(function(plr)
	if running[plr.UserId] then return end
	if plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") then
		plr.Character.Humanoid.WalkSpeed = 0
	end
	setSprint(plr,false)

	TeleportStart:FireClient(plr, sPart.CFrame + Vector3.new(0,4,0))
	running[plr.UserId] = tick()

	local best = (plr.leaderstats and plr.leaderstats:FindFirstChild("BestTime"))
		and plr.leaderstats.BestTime.Value or math.huge
	StartRun:FireClient(plr, best)
end)

fPart.Touched:Connect(function(hit)
	local plr = Players:GetPlayerFromCharacter(hit.Parent); if not plr then return end
	local t0  = running[plr.UserId]; if not t0 then return end
	running[plr.UserId] = nil

	local elapsed = tick() - t0
	DataAPI.UpdateBestTime(plr, elapsed)   -- leaderstats & datastore
	DataAPI.IncrementRuns(plr)             -- tracks runs finished ?
	FinishRun:FireClient(plr, elapsed)

	OpenPrestige:FireClient(plr)           -- ? show Prestige panel
end)
