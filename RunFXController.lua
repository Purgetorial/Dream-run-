--------------------------------------------------------------------
-- RunFXController.lua • build-up zoom ? POP boost ? smooth settle
-- 02-Aug-25  – running-wind stays on after Shift / stamina end
--------------------------------------------------------------------
local Plr , RS , UIS , TwS , Rep = game.Players.LocalPlayer ,
	game:GetService("RunService") ,
	game:GetService("UserInputService") ,
	game:GetService("TweenService") ,
	game:GetService("ReplicatedStorage")

local Rem         = Rep.Remotes
local SprintEvt   = Rem.SprintToggle
local BoostFX     = Rem.BoostBroadcast
local TrailTog    = Rem.TrailToggle
local FX          = require(Rep.Config.FXConfig)

----------------------------  FOV numbers  --------------------------
local IDLE_FOV    = FX.FOV_MIN
local RUN_FOV     = FX.FOV_MAX
local POP_FOV     = 120
local CRUISE_FOV  = 96
local POP_TIME    = 0.35
local SETTLE_TIME = 0.9
local RETURN_TIME = 0.5
local BUILDUP_SEC = 0.65

------------------------------  Sounds  ----------------------------
local BoomSample      = Rep.RunFXAssets.SonicBoom ; BoomSample.Volume = 1.3
local WindLoopPrefab  = Rep.RunFXAssets.RunningWind ; WindLoopPrefab.Volume = 0.75

---------------------------  Stamina bar  --------------------------
local function findBar(timeout)
	local pg = Plr:WaitForChild("PlayerGui")
	local t  = 0
	while t < timeout do
		for _, d in ipairs(pg:GetDescendants()) do
			if d:IsA("Frame") and d.Name == "Bar" then
				return d, d:FindFirstChild("Fill") or d
			end
		end
		t += RS.Heartbeat:Wait()
	end
end
local barFrame, barFill = findBar(10)
local function setBar(v) if barFill then barFill.Size = UDim2.new(v,0,1,0) end end

--------------------------  Runtime state  -------------------------
local cam = workspace.CurrentCamera
local char, hum, topSpeed, stam
local fxOn, sprint, timer = false, false, 0
local windLoop, fovTween, currentTarget

------------------------------ Helpers -----------------------------
local function ensureWind()
	if windLoop and windLoop.Parent then return windLoop end
	windLoop            = WindLoopPrefab:Clone()
	windLoop.Looped     = true
	windLoop.Parent     = cam
	return windLoop
end
local function startWind() local s = ensureWind(); if not s.IsPlaying then s:Play() end end
local function stopWind()  if windLoop then windLoop:Stop() end end
local function setTrails(on) TrailTog:FireServer(on) end

local function tweenFOV(toFov, dur)
	if currentTarget and math.abs(currentTarget - toFov) < 0.1 then return end
	if fovTween then fovTween:Cancel() end
	currentTarget = toFov
	fovTween = TwS:Create(
		cam,
		TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{FieldOfView = toFov}
	)
	fovTween:Play()
end

---------------------------  Render loop  ---------------------------
RS.RenderStepped:Connect(function(dt)
	if not (hum and topSpeed and stam) then return end
	setBar(stam.Value/100)

	local moving   = hum.MoveDirection.Magnitude > 0
	local nearTop  = hum.WalkSpeed >= topSpeed.Value * 0.98
	timer          = (moving and nearTop) and (timer + dt) or 0

	local wantFX   = (timer >= BUILDUP_SEC) or sprint
	if wantFX and not fxOn then
		fxOn = true
		startWind(); setTrails(true)
		if not sprint then tweenFOV(RUN_FOV, FX.ZOOM_TIME) end
	elseif (not wantFX) and fxOn then
		fxOn = false
		stopWind();  setTrails(false)
		tweenFOV(IDLE_FOV, RETURN_TIME)
	end
end)

-------------------------  Sprint keybinds  -------------------------
UIS.InputBegan:Connect(function(i,gp)
	if gp or i.KeyCode ~= Enum.KeyCode.LeftShift then return end
	if not (stam and stam.Value >= 100) then return end  -- full-bar gate

	sprint = true
	SprintEvt:FireServer(true)

	local boom = BoomSample:Clone(); boom.Parent = cam; boom:Play()

	tweenFOV(POP_FOV, POP_TIME)
	task.delay(POP_TIME, function()
		if sprint then tweenFOV(CRUISE_FOV, SETTLE_TIME) end
	end)
end)

UIS.InputEnded:Connect(function(i,gp)
	if gp or i.KeyCode ~= Enum.KeyCode.LeftShift then return end
	sprint = false
	SprintEvt:FireServer(false)
	tweenFOV(fxOn and RUN_FOV or IDLE_FOV, RETURN_TIME)
end)

----------------------  Lightspeed server boost --------------------
BoostFX.OnClientEvent:Connect(function(on)
	sprint = on
	if on then
		startWind()
		tweenFOV(CRUISE_FOV, SETTLE_TIME)
	else
		-- Keep wind & trails if FX already active
		if not fxOn then stopWind(); setTrails(false) end
		tweenFOV(fxOn and RUN_FOV or IDLE_FOV, RETURN_TIME)
	end
end)

---------------------------  Respawn hook  --------------------------
local function onChar(c)
	char, hum  = c, c:WaitForChild("Humanoid")
	topSpeed   = c:WaitForChild("CurrentSpeed")
	stam       = Plr:WaitForChild("Stamina")

	cam.FieldOfView, currentTarget = IDLE_FOV, IDLE_FOV
	fxOn, sprint, timer = false, false, 0
	setBar(1)
end
Plr.CharacterAdded:Connect(onChar)
if Plr.Character then onChar(Plr.Character) end
