--------------------------------------------------------------------
-- HUDController.lua  |  DreamRun HUD
--  • Timer panel hidden on spawn
--  • Play button locked while any modal (Shop, Leaderboard, etc.) is open
--  • PB label updates the moment you beat your time
--------------------------------------------------------------------
------------------------------ Services ----------------------------
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

------------------------------ UI refs ----------------------------
local player = Players.LocalPlayer
local gui    = script.Parent              -- HUDGui

local infoPanel  = gui:WaitForChild("InfoPanel")
local timerLabel = infoPanel:WaitForChild("TimerLabel")
local pbLabel    = infoPanel:WaitForChild("PBLabel")

local menuButton = gui:WaitForChild("MenuButton")  -- bottom-left open-menu button
local playButton = gui:WaitForChild("PlayButton")

------------------------------ Remotes ----------------------------
local Remotes           = ReplicatedStorage:WaitForChild("Remotes")
local StartRun          = Remotes:WaitForChild("StartRun")
local FinishRun         = Remotes:WaitForChild("FinishRun")

local RequestRunStart   = ReplicatedStorage.Remotes:WaitForChild("RequestRunStart")
local TeleportToLobby   = ReplicatedStorage:WaitForChild("TeleportToLobby")
local TeleportToStart   = ReplicatedStorage:WaitForChild("TeleportToStart")
local OpenMainMenuLocal = ReplicatedStorage:WaitForChild("OpenMainMenuLocal")

------------------------------ Modal lock -------------------------
-- Any modal GUI should fire UIEvents.ModalState with true (open) / false (close)
local ModalState = ReplicatedStorage.UIEvents:WaitForChild("ModalState")

local openModals = 0
ModalState.Event:Connect(function(open:boolean)
	openModals += open and 1 or -1
	if openModals < 0 then openModals = 0 end         -- safety
	menuButton.Visible = (openModals == 0)
end)

--------------------------------------------------------------------
-- state & helpers
--------------------------------------------------------------------
local isRunning  = false
local startTick  = 0
local elapsed    = 0
local pb         = math.huge         -- personal-best seconds

local function fmt(t:number): string
	return (t == math.huge) and "--:--.--"
		or string.format("%d:%05.2f", math.floor(t/60), t%60)
end

local function refreshLabels()
	timerLabel.Text = "Time: "..fmt(elapsed)
	pbLabel.Text    = "PB: "..fmt(pb)
end

local function showTimerPanel(ok:boolean) infoPanel.Visible = ok end
local function showPlayButton(ok:boolean) playButton.Visible = ok end

--------------------------------------------------------------------
-- Run lifecycle handlers
--------------------------------------------------------------------
StartRun.OnClientEvent:Connect(function(pbFromServer:number?)
	if pbFromServer == nil then                    -- reset signal
		isRunning, elapsed = false, 0
		showTimerPanel(false)
		showPlayButton(true)
		refreshLabels()
		return
	end
	-- run begins
	pb        = pbFromServer
	startTick = tick()
	elapsed   = 0
	isRunning = true

	showTimerPanel(true)
	showPlayButton(false)
	refreshLabels()
end)

FinishRun.OnClientEvent:Connect(function(finalTime:number)
	isRunning = false
	elapsed   = finalTime
	if finalTime < pb then pb = finalTime end
	-- keep Play hidden; it'll show on lobby teleport
	showTimerPanel(false)
	refreshLabels()
end)

--------------------------------------------------------------------
-- Per-frame timer update
--------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	if isRunning then
		elapsed = tick() - startTick
		timerLabel.Text = "Time: "..fmt(elapsed)
	end
end)

--------------------------------------------------------------------
-- Leaderstats PB hook (no infinite yield)
--------------------------------------------------------------------
local function hookLeaderstats()
	local stats = player:WaitForChild("leaderstats")
	local best  = stats:WaitForChild("BestTime", 5)
	if not best then
		warn("[HUD] BestTime value missing after 5 s, placeholder used.")
		pb = math.huge
		return
	end
	pb = best.Value
	best.Changed:Connect(function(v) pb = v; refreshLabels() end)
end

if player:FindFirstChild("leaderstats") then
	hookLeaderstats()
else
	player.ChildAdded:Connect(function(c)
		if c.Name == "leaderstats" then hookLeaderstats() end
	end)
end

--------------------------------------------------------------------
-- Buttons
--------------------------------------------------------------------
menuButton.MouseButton1Click:Connect(function()
	OpenMainMenuLocal:Fire()
end)

playButton.MouseButton1Click:Connect(function()
	RequestRunStart:FireServer()
	showPlayButton(false)
end)

--------------------------------------------------------------------
-- Teleport / respawn resets
--------------------------------------------------------------------
local function resetToLobby()
	isRunning, elapsed = false, 0
	showTimerPanel(false)
	showPlayButton(true)
	refreshLabels()
end

TeleportToLobby.OnClientEvent:Connect(resetToLobby)
player.CharacterAdded:Connect(resetToLobby)

-- falling teleport intentionally does nothing to the timer
TeleportToStart.OnClientEvent:Connect(function() end)

--------------------------------------------------------------------
-- Initial UI state
--------------------------------------------------------------------
showTimerPanel(false)
showPlayButton(true)
refreshLabels()
