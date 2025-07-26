-- CoinController.lua  |  spawns, animates & plays SFX when collecting
--------------------------------------------------------------------
local Players            = game:GetService("Players")
local Workspace          = game:GetService("Workspace")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")
local Debris             = game:GetService("Debris")

local player         = Players.LocalPlayer
local CoinCollected  = ReplicatedStorage:WaitForChild("CoinCollected")
local Remotes        = ReplicatedStorage:WaitForChild("Remotes")
local StartRun       = Remotes:WaitForChild("StartRun")
local TeleportToLobby= ReplicatedStorage:WaitForChild("TeleportToLobby")
local TeleportToStart= ReplicatedStorage:WaitForChild("TeleportToStart")

local coinTemplate   = ReplicatedStorage:WaitForChild("Coin")
local CFG            = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("CoinConfig"))

--------------------------------------------------------------------
-- new: coin collect sound (cached for performance)
--------------------------------------------------------------------
local COLLECT_SOUND_ID = "rbxassetid://1169755927"  -- free “bling” SFX
local collectSound

local function playCollectSound()
	if not collectSound then
		collectSound = Instance.new("Sound")
		collectSound.Name     = "CoinPickupSFX"
		collectSound.SoundId  = COLLECT_SOUND_ID
		collectSound.Volume   = 1
		collectSound.Parent   = Workspace.CurrentCamera
	end
	collectSound:Play()
end

--------------------------------------------------------------------
-- internal state
--------------------------------------------------------------------
local coinFolder = Instance.new("Folder")
coinFolder.Name  = "LocalCoins"
coinFolder.Parent= Workspace.CurrentCamera or Workspace

--------------------------------------------------------------------
-- helpers
--------------------------------------------------------------------
local function clearCoins()
	coinFolder:ClearAllChildren()
end

local function animateCoin(coin, baseY)
	local t0 = tick()
	local upright = CFrame.Angles(math.rad(90), 0, 0)
	RunService.RenderStepped:Connect(function()
		if not coin.Parent then return end
		local t = tick() - t0
		local y = baseY + math.sin(t * CFG.BOB_SPEED) * CFG.BOB_HEIGHT
		local spin = CFrame.Angles(0, 0, math.rad((t * CFG.SPIN_SPEED) % 360))
		coin.CFrame = CFrame.new(coin.Position.X, y, coin.Position.Z) * upright * spin
	end)
end

local function waitForRunFolder()
	local rf = Workspace:WaitForChild("GeneratedDreamRun", 20)
	if not rf then return end
	for i = 1, CFG.NUM_SEGMENTS do
		local seg = rf:WaitForChild("Segment_" .. i, 20)
		if not seg then return end
	end
	return rf
end

local function spawnCoins()
	clearCoins()
	local runFolder = waitForRunFolder()
	if not runFolder then return end

	for i = 1, CFG.NUM_SEGMENTS do
		if i % CFG.COIN_INTERVAL == 0 then
			local segment = runFolder:FindFirstChild("Segment_" .. i)
			if segment then
				local part   = segment:IsA("Model") and segment.PrimaryPart or segment
				if part then
					local y = part.Position.Y + (part.Size.Y / 2) + CFG.HOVER_Y_OFFSET
					local coin = coinTemplate:Clone()
					coin.Name  = "Coin_" .. i
					coin.CFrame= CFrame.new(0, y, part.Position.Z) * CFrame.Angles(math.rad(90),0,0)
					coin.Anchored, coin.CanCollide, coin.CanTouch = true, false, true
					coin.Parent = coinFolder

					animateCoin(coin, y)

					coin.Touched:Connect(function(hit)
						if hit and hit.Parent == player.Character then
							playCollectSound()                              -- <- NEW
							CoinCollected:FireServer(i, coin.Position)
							coin:Destroy()
						end
					end)
				end
			end
		end
	end
end

--------------------------------------------------------------------
-- hooks
--------------------------------------------------------------------
local function resetCoins() spawnCoins() end

StartRun.OnClientEvent:Connect(resetCoins)
TeleportToLobby.OnClientEvent:Connect(resetCoins)
TeleportToStart.OnClientEvent:Connect(resetCoins)

-- first join
spawnCoins()
