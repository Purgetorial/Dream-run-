--------------------------------------------------------------------
-- PrestigeController.lua (Optimized)
-- • Updates the UI in real-time using leaderstat connections.
-- • Provides instant feedback when the prestige button is clicked.
--------------------------------------------------------------------
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- UI & Remotes
local ModalState        = ReplicatedStorage.UIEvents:WaitForChild("ModalState")
local gui               = script.Parent
local panel             = gui.PrestigePanel
local levelLabel        = panel.InfoBox.PrestigeLevelLabel
local bonusLabel        = panel.InfoBox.PrestigeBonusLabel
local prestigeButton    = panel.PrestigeButton
local Remotes           = ReplicatedStorage.Remotes
local RequestPrestige   = Remotes.RequestPrestige
local PrestigeConfirmed = Remotes.PrestigeConfirmed
local OpenPrestigeEvt   = ReplicatedStorage:WaitForChild("OpenPrestige")

--------------------------------------------------------------------
-- State & Config
--------------------------------------------------------------------
local isAwaitingResponse = false
local COIN_BONUS_PER_LEVEL = 15 -- +15% per level

--------------------------------------------------------------------
-- UI Update Functions
--------------------------------------------------------------------
local function updateLabels(prestigeLevel: number)
	levelLabel.Text = "Prestige Level: " .. tostring(prestigeLevel)
	bonusLabel.Text = string.format("Coin Bonus: +%d%%", prestigeLevel * COIN_BONUS_PER_LEVEL)
end

local function updateButtonState()
	if isAwaitingResponse then
		prestigeButton.Text = "PRESTIGING..."
		prestigeButton.AutoButtonColor = false
		prestigeButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
	else
		prestigeButton.Text = "PRESTIGE"
		prestigeButton.AutoButtonColor = true
		prestigeButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	end
end

--------------------------------------------------------------------
-- Open / Close Logic
--------------------------------------------------------------------
local function open()
	isAwaitingResponse = false
	updateButtonState()
	gui.Enabled, panel.Visible = true, true
	ModalState:Fire(true)
end

local function close()
	gui.Enabled, panel.Visible = false, false
	ModalState:Fire(false)
end

OpenPrestigeEvt.OnClientEvent:Connect(open)

--------------------------------------------------------------------
-- Event Connections
--------------------------------------------------------------------
prestigeButton.MouseButton1Click:Connect(function()
	if isAwaitingResponse then return end
	isAwaitingResponse = true
	updateButtonState()
	RequestPrestige:FireServer()
end)

PrestigeConfirmed.OnClientEvent:Connect(function(success: boolean)
	isAwaitingResponse = false
	updateButtonState()
	if success then
		-- The panel will auto-close after a successful prestige
		close()
	end
end)

-- Connect to leaderstats to keep the UI live
local function connectToLeaderstats()
	local ls = player:WaitForChild("leaderstats")
	local prestigeValue = ls:WaitForChild("Prestige")

	-- Initial update
	updateLabels(prestigeValue.Value)

	-- Listen for changes
	prestigeValue.Changed:Connect(updateLabels)
end

connectToLeaderstats()