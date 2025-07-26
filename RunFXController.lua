--------------------------------------------------------------------
-- RunFXController.lua • build-up zoom, sprint effects, and sounds (Optimized)
-- • Replaces inefficient UI search with a direct path.
-- • Simplifies state management for visual effects.
-- • Consolidates trail toggling logic for better organization.
--------------------------------------------------------------------
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Remotes & Config
local Remotes         = ReplicatedStorage.Remotes
local SprintToggle    = Remotes.SprintToggle
local BoostBroadcast  = Remotes.BoostBroadcast
local TrailToggle     = Remotes.TrailToggle -- This remote will be fired from here
local FXConfig        = require(ReplicatedStorage.Config.FXConfig)

-- Sound Assets
local RunFXAssets     = ReplicatedStorage:WaitForChild("RunFXAssets")
local BoomSample      = RunFXAssets:WaitForChild("SonicBoom")
local WindLoopPrefab  = RunFXAssets:WaitForChild("RunningWind")

-- UI Stamina Bar (Direct Path)
local StaminaBar = player:WaitForChild("PlayerGui"):WaitForChild("HUDGui"):WaitForChild("StaminaBar"):WaitForChild("Bar")

--------------------------
-- State & Configuration
--------------------------
local cam = workspace.CurrentCamera
local IDLE_FOV    = FXConfig.FOV_MIN
local RUN_FOV     = FXConfig.FOV_MAX
local SPRINT_FOV  = 95 -- A dedicated FOV for sprinting
local POP_TIME    = 0.2
local SETTLE_TIME = 0.8
local RETURN_TIME = 0.4

local fxOn, isSprinting = false, false
local windSound, fovTween

--------------------------
-- Helper Functions
--------------------------
local function setStaminaBar(percentage)
	if StaminaBar and StaminaBar:FindFirstChild("Fill") then
		StaminaBar.Fill.Size = UDim2.fromScale(math.clamp(percentage, 0, 1), 1)
	end
end

local function ensureWindSound()
	if not windSound or not windSound.Parent then
		windSound = WindLoopPrefab:Clone()
		windSound.Looped = true
		windSound.Volume = 0.7
		windSound.Parent = cam
	end
	return windSound
end

local function tweenFOV(targetFov, duration)
	if fovTween then fovTween:Cancel() end
	local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	fovTween = TweenService:Create(cam, info, {FieldOfView = targetFov})
	fovTween:Play()
end

local function setVisuals(enabled: boolean)
	if fxOn == enabled then return end
	fxOn = enabled

	TrailToggle:FireServer(enabled) -- Tell server to replicate trail state

	if enabled then
		ensureWindSound():Play()
		tweenFOV(RUN_FOV, 0.5)
	else
		if windSound then windSound:Stop() end
		tweenFOV(IDLE_FOV, RETURN_TIME)
	end
end

--------------------------
-- Main Logic
--------------------------
local function onCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	local stamina = player:WaitForChild("Stamina")
	local currentSpeed = character:WaitForChild("CurrentSpeed")

	-- Reset state on new character
	isSprinting = false
	setVisuals(false)
	cam.FieldOfView = IDLE_FOV

	-- Render loop connection per character
	local connection
	connection = RunService.RenderStepped:Connect(function()
		if not humanoid or humanoid.Health <= 0 then
			connection:Disconnect() -- Disconnect if character is gone
			return
		end

		setStaminaBar(stamina.Value / 100)

		local isMoving = humanoid.MoveDirection.Magnitude > 0.1
		local isNearTopSpeed = humanoid.WalkSpeed >= currentSpeed.Value * 0.9

		-- Only show run FX when moving near top speed and not sprinting
		setVisuals(isMoving and isNearTopSpeed and not isSprinting)
	end)
end

--------------------------
-- Input and Remote Events
--------------------------
local function startSprint()
	if isSprinting then return end
	local stamina = player:FindFirstChild("Stamina")
	if not stamina or stamina.Value < 100 then return end -- Full stamina required

	isSprinting = true
	SprintToggle:FireServer(true)

	local boom = BoomSample:Clone()
	boom.Parent = cam
	boom:Play()
	game:GetService("Debris"):AddItem(boom, 2)

	tweenFOV(SPRINT_FOV, POP_TIME)
end

local function endSprint()
	if not isSprinting then return end
	isSprinting = false
	SprintToggle:FireServer(false)

	-- Return to the correct FOV based on whether the run FX should be active
	tweenFOV(fxOn and RUN_FOV or IDLE_FOV, RETURN_TIME)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or input.KeyCode ~= Enum.KeyCode.LeftShift then return end
	startSprint()
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if gameProcessed or input.KeyCode ~= Enum.KeyCode.LeftShift then return end
	endSprint()
end)

-- Handle server-side forced "Lightspeed" boost
BoostBroadcast.OnClientEvent:Connect(function(enabled)
	if enabled then
		isSprinting = true
		tweenFOV(SPRINT_FOV, SETTLE_TIME)
		ensureWindSound():Play()
		TrailToggle:FireServer(true) -- Also enable trails
	else
		isSprinting = false
		-- Only stop effects if the player isn't regularly running fast
		if not fxOn then
			if windSound then windSound:Stop() end
			TrailToggle:FireServer(false)
		end
		tweenFOV(fxOn and RUN_FOV or IDLE_FOV, RETURN_TIME)
	end
end)

--------------------------
-- Initialization
--------------------------
if player.Character then onCharacter(player.Character) end
player.CharacterAdded:Connect(onCharacter)