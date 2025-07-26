--------------------------------------------------------------------
-- CoinController.lua  |  spawns, animates & handles collection (Optimized)
-- • MAJOR PERFORMANCE FIX: Replaced individual RenderStepped loops with TweenService.
-- • Centralizes coin animation, preventing client-side lag.
-- • Uses a cached sound for better performance.
--------------------------------------------------------------------
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local Debris            = game:GetService("Debris")
local Workspace         = game:GetService("Workspace")

local player         = Players.LocalPlayer

-- Remotes & Config
local Remotes         = ReplicatedStorage:WaitForChild("Remotes")
local CoinCollected   = Remotes:WaitForChild("CoinCollected")
local StartRun        = Remotes:WaitForChild("StartRun")
local TeleportToLobby = ReplicatedStorage:WaitForChild("TeleportToLobby")
local CFG             = require(ReplicatedStorage.Config.CoinConfig)
local coinTemplate    = ReplicatedStorage:WaitForChild("Coin")

--------------------------------------------------------------------
-- Sound Caching
--------------------------------------------------------------------
local COLLECT_SOUND_ID = "rbxassetid://1169755927"
local collectSound
local function playCollectSound()
	if not collectSound then
		collectSound = Instance.new("Sound")
		collectSound.Name     = "CoinPickupSFX"
		collectSound.SoundId  = COLLECT_SOUND_ID
		collectSound.Volume   = 0.8
		collectSound.Parent   = Workspace.CurrentCamera or Workspace
	end
	collectSound:Play()
end

--------------------------------------------------------------------
-- State & Coin Management
--------------------------------------------------------------------
local coinFolder = Instance.new("Folder")
coinFolder.Name  = "LocalCoins"
coinFolder.Parent= Workspace.CurrentCamera or Workspace

local activeTweens = {} -- Keep track of tweens to cancel them

local function clearCoins()
	-- Cancel all running tweens before destroying coins
	for _, tween in pairs(activeTweens) do
		tween:Cancel()
	end
	activeTweens = {}
	coinFolder:ClearAllChildren()
end

--------------------------------------------------------------------
-- Optimized Animation
--------------------------------------------------------------------
local function animateCoin(coin)
	-- Randomize starting rotation for variety
	coin.CFrame = coin.CFrame * CFrame.Angles(0, math.rad(math.random(0, 360)), 0)
	local originalY = coin.Position.Y

	-- Create Bobbing Tween (up and down)
	local bobInfo = TweenInfo.new(CFG.BOB_SPEED, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local bobGoal = { Position = Vector3.new(coin.Position.X, originalY + CFG.BOB_HEIGHT, coin.Position.Z) }
	local bobTween = TweenService:Create(coin, bobInfo, bobGoal)

	-- Create Spinning Tween (rotation)
	-- The duration is calculated to match the desired degrees-per-second speed
	local spinDuration = 360 / CFG.SPIN_SPEED
	local spinInfo = TweenInfo.new(spinDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false)
	local spinGoal = { CFrame = coin.CFrame * CFrame.Angles(0, math.rad(360), 0) }
	local spinTween = TweenService:Create(coin, spinInfo, spinGoal)

	-- Play and track the tweens
	bobTween:Play()
	spinTween:Play()
	table.insert(activeTweens, bobTween)
	table.insert(activeTweens, spinTween)
end


--------------------------------------------------------------------
-- Coin Spawning
--------------------------------------------------------------------
local function spawnCoins()
	clearCoins()
	local runFolder = Workspace:WaitForChild("GeneratedDreamRun", 10)
	if not runFolder then return end

	for i = 1, CFG.NUM_SEGMENTS do
		if i % CFG.COIN_INTERVAL == 0 then
			local segment = runFolder:FindFirstChild("Segment_" .. i)
			local part = segment and (segment:IsA("Model") and segment.PrimaryPart or segment)

			if part then
				local y = part.Position.Y + (part.Size.Y / 2) + CFG.HOVER_Y_OFFSET
				local coin = coinTemplate:Clone()
				coin.Name = "Coin_" .. i
				coin.CFrame = CFrame.new(0, y, part.Position.Z) * CFrame.Angles(math.rad(90), 0, 0)
				coin.Anchored = true
				coin.CanCollide = false
				coin.CanTouch = true
				coin.Parent = coinFolder

				animateCoin(coin)

				coin.Touched:Connect(function(hit)
					if hit and hit.Parent == player.Character then
						playCollectSound()
						CoinCollected:FireServer(i, coin.Position)
						coin:Destroy() -- Touched connection is automatically cleaned up
					end
				end)
			end
		end
	end
end

--------------------------------------------------------------------
-- Hooks
--------------------------------------------------------------------
-- A single function to handle resetting coins
local function resetAndSpawnCoins()
	spawnCoins()
end

StartRun.OnClientEvent:Connect(resetAndSpawnCoins)
TeleportToLobby.OnClientEvent:Connect(resetAndSpawnCoins)

-- Initial spawn on join
if player.Character then
	resetAndSpawnCoins()
else
	player.CharacterAdded:Wait()
	resetAndSpawnCoins()
end