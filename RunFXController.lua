-- purgetorial/dream-run-/Dream-run--c6e19a1472899b0fe558b182fcfa5a80333cb4a1/RunFXController.lua
--------------------------------------------------------------------
-- RunFXController.lua ? State-based effects controller
-- • UPDATE: No longer fires TrailToggle, as server handles trails.
--------------------------------------------------------------------
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- ?? ACTION REQUIRED: Replace these placeholder IDs with your own sound asset IDs.
local ELECTRIC_SOUND_IDS = {
	"rbxassetid://9116276961", -- Electric/Sparks Sound 1
	"rbxassetid://9116277729", -- Electric/Sparks Sound 2
	"rbxassetid://9116276946", -- Electric/Sparks Sound 3
}
local ELECTRIC_SOUND_OVERLAP = 0.5 -- How many seconds before a sound ends to start the next one.

-- Remotes & Config
local Remotes         = ReplicatedStorage.Remotes
local SprintToggle    = Remotes.SprintToggle
local BoostBroadcast  = Remotes.BoostBroadcast
-- local TrailToggle     = Remotes.TrailToggle -- REMOVED
local FXConfig        = require(ReplicatedStorage.Config.FXConfig)

-- Sound Assets
local RunFXAssets      = ReplicatedStorage:WaitForChild("RunFXAssets")
local ElectricBurstSample = RunFXAssets:WaitForChild("ElectricBurst")
local WindLoopPrefab   = RunFXAssets:WaitForChild("RunningWind")

-- UI Stamina Bar
local StaminaBar = player:WaitForChild("PlayerGui"):WaitForChild("HUDGui"):WaitForChild("StaminaBar")

--------------------------
-- State & Configuration
--------------------------
local cam = workspace.CurrentCamera
local IDLE_FOV    = FXConfig.FOV_MIN
local RUN_FOV     = FXConfig.FOV_MAX
local SPRINT_FOV  = 95
local RETURN_TIME = 0.4

-- State Machine
local State = { IDLE = 1, RUNNING = 2, SPRINTING = 3 }
local currentState = State.IDLE
local isSprinting = false

-- Sound Instances & Controls
local windSound, fovTween
local electricSoundPool = {}
local electricSoundCoroutine

--------------------------
-- Helper Functions
-- ... (this section is unchanged)
--------------------------
local function setStaminaBar(percentage)
	if StaminaBar and StaminaBar:FindFirstChild("Bar") then
		StaminaBar.Bar.Size = UDim2.fromScale(math.clamp(percentage, 0, 1), 1)
	end
end

local function tweenFOV(targetFov, duration)
	if fovTween then fovTween:Cancel() end
	local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	fovTween = TweenService:Create(cam, info, {FieldOfView = targetFov})
	fovTween:Play()
end

local function ensureWindSound()
	if not windSound or not windSound.Parent then
		windSound = WindLoopPrefab:Clone()
		windSound.Looped, windSound.Volume, windSound.Parent = true, 0.7, cam
	end
	return windSound
end

local function startElectricSoundSequence()
	if electricSoundCoroutine then task.cancel(electricSoundCoroutine) end
	if #electricSoundPool == 0 then return end

	electricSoundCoroutine = task.spawn(function()
		local currentIndex = 1
		while true do
			local sound = electricSoundPool[currentIndex]
			sound.TimePosition = 0
			sound:Play()
			local waitTime = math.max(0.1, sound.TimeLength - ELECTRIC_SOUND_OVERLAP)
			task.wait(waitTime)
			currentIndex = (currentIndex % #electricSoundPool) + 1
		end
	end)
end

local function stopElectricSoundSequence()
	if electricSoundCoroutine then
		task.cancel(electricSoundCoroutine)
		electricSoundCoroutine = nil
	end
	for _, sound in ipairs(electricSoundPool) do
		sound:Stop()
	end
end
--------------------------
-- State Transition Logic
--------------------------
local function setState(newState)
	if currentState == newState then return end

	-- Exit previous state
	if currentState == State.RUNNING or currentState == State.SPRINTING then
		-- TrailToggle:FireServer(false) -- REMOVED
		if windSound then windSound:Stop() end
		stopElectricSoundSequence()
	end

	currentState = newState

	-- Enter new state
	if newState == State.IDLE then
		tweenFOV(IDLE_FOV, RETURN_TIME)
	elseif newState == State.RUNNING or newState == State.SPRINTING then
		-- TrailToggle:FireServer(true) -- REMOVED
		ensureWindSound():Play()
		startElectricSoundSequence()
		if newState == State.RUNNING then
			tweenFOV(RUN_FOV, 0.5)
		else -- SPRINTING
			tweenFOV(SPRINT_FOV, 0.3)
		end
	end
end
-- ... (rest of the file is unchanged)
--------------------------
-- Main Logic
--------------------------
local function initializeSounds()
	if #electricSoundPool > 0 then return end
	for _, id in ipairs(ELECTRIC_SOUND_IDS) do
		local sound = Instance.new("Sound")
		sound.SoundId, sound.Volume, sound.Parent = id, 0.6, cam
		table.insert(electricSoundPool, sound)
	end
	for _, sound in ipairs(electricSoundPool) do
		sound:Play()
		sound:Stop()
	end
end

local function onCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	local stamina = player:WaitForChild("Stamina")
	local currentSpeed = character:WaitForChild("CurrentSpeed")

	initializeSounds()
	isSprinting = false
	setState(State.IDLE)
	cam.FieldOfView = IDLE_FOV

	local connection
	connection = RunService.RenderStepped:Connect(function()
		if not humanoid or humanoid.Health <= 0 then
			connection:Disconnect()
			return
		end
		setStaminaBar(stamina.Value / 100)
		local isMoving = humanoid.MoveDirection.Magnitude > 0.1
		local isNearTopSpeed = humanoid.WalkSpeed >= currentSpeed.Value * 0.9
		local targetState
		if isSprinting and isMoving then
			targetState = State.SPRINTING
		elseif isNearTopSpeed and isMoving then
			targetState = State.RUNNING
		else
			targetState = State.IDLE
		end
		setState(targetState)
	end)
end

--------------------------
-- Input and Remote Events
--------------------------
local function startSprint()
	if isSprinting then return end
	local stamina = player:FindFirstChild("Stamina")
	if not stamina or stamina.Value < 100 then return end

	isSprinting = true
	SprintToggle:FireServer(true)

	local burst = ElectricBurstSample:Clone()
	burst.Volume = 1.0 
	burst.Parent = cam
	burst:Play()
	game:GetService("Debris"):AddItem(burst, 2)
end

local function endSprint()
	if not isSprinting then return end
	isSprinting = false
	SprintToggle:FireServer(false)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or input.KeyCode ~= Enum.KeyCode.LeftShift then return end
	startSprint()
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if gameProcessed or input.KeyCode ~= Enum.Code.LeftShift then return end
	endSprint()
end)

BoostBroadcast.OnClientEvent:Connect(function(enabled)
	isSprinting = enabled
end)

--------------------------
-- Initialization
--------------------------
if player.Character then onCharacter(player.Character) end
player.CharacterAdded:Connect(onCharacter)