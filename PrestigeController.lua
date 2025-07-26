--------------------------------------------------------------------
-- PrestigeController.lua
--------------------------------------------------------------------
------------------------------ Services ----------------------------
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS               = game:GetService("UserInputService")

------------------------------ UIEvents ---------------------------
local ModalState = ReplicatedStorage.UIEvents:WaitForChild("ModalState")

------------------------------ GUI refs ---------------------------
local gui            = script.Parent                -- PrestigeGui
local panel          = gui.PrestigePanel
local infoBox        = panel.InfoBox
local levelLabel     = infoBox.PrestigeLevelLabel
local bonusLabel     = infoBox.PrestigeBonusLabel
local reqLabel       = panel.RequirementLabel
local warnLabel      = panel.WarningLabel
local prestigeButton = panel.PrestigeButton

------------------------------ Remotes ----------------------------
local Remotes          = ReplicatedStorage.Remotes
local RequestPrestige  = Remotes.RequestPrestige
local PrestigeConfirmed= Remotes.PrestigeConfirmed
local OpenPrestigeEvt  = ReplicatedStorage.OpenPrestige  -- fired from RunService
--------------------------------------------------------------------
local player      = Players.LocalPlayer
local awaiting    = false
local BONUS_PCT   = 15

------------------------------ UI update --------------------------
local function updateUI()
	local prestige = 0
	local ls = player:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Prestige") then
		prestige = ls.Prestige.Value
	end

	levelLabel.Text = "Prestige Level: "..tostring(prestige)
	bonusLabel.Text = string.format("+%d%% Coins", prestige * BONUS_PCT)
	reqLabel.Text   = "You finished your run!"
	warnLabel.Text  = "Prestiging grants a permanent coin bonus!"

	if awaiting then
		prestigeButton.Text              = "Prestiging..."
		prestigeButton.Active            = false
		prestigeButton.AutoButtonColor   = false
	else
		prestigeButton.Text              = "Prestige?"
		prestigeButton.Active            = true
		prestigeButton.AutoButtonColor   = true
	end
end

------------------------------ Open / Close -----------------------
local function open()
	awaiting = false
	updateUI()
	gui.Enabled = true
	panel.Visible = true
	ModalState:Fire(true)              -- lock Main-Menu
end

local function close()
	gui.Enabled = false
	panel.Visible = false
	ModalState:Fire(false)             -- unlock Main-Menu
end


OpenPrestigeEvt.OnClientEvent:Connect(open)

------------------------------ Button click -----------------------
prestigeButton.MouseButton1Click:Connect(function()
	if awaiting or not prestigeButton.Active then return end
	awaiting = true
	updateUI()
	RequestPrestige:FireServer()
end)

------------------------------ Server confirmation ---------------
if PrestigeConfirmed then
	PrestigeConfirmed.OnClientEvent:Connect(function(newLevel)
		awaiting = false
		updateUI()
		close()                             -- panel auto-closes
	end)
end

------------------------------ Leaderstat watchers ----------------
local function hookStats()
	local stats = player:WaitForChild("leaderstats")
	stats.ChildAdded:Connect(updateUI)
	stats.ChildRemoved:Connect(updateUI)
	for _, s in ipairs(stats:GetChildren()) do s.Changed:Connect(updateUI) end
end
if player:FindFirstChild("leaderstats") then hookStats()
else player.ChildAdded:Connect(function(c) if c.Name=="leaderstats" then hookStats() end end) end
