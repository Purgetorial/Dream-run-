-- purgetorial/dream-run-/Dream-run--c6e19a1472899b0fe558b182fcfa5a80333cb4a1/PrestigeController.lua
--------------------------------------------------------------------
-- PrestigeController.lua (Optimized & Rewards Display)
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
local PrestigeCfg       = require(ReplicatedStorage.Config.PrestigeConfig) -- NEW

--------------------------------------------------------------------
-- State & Config
--------------------------------------------------------------------
local isAwaitingResponse = false

--------------------------------------------------------------------
-- UI Update Functions
--------------------------------------------------------------------
local function updateLabels(prestigeLevel: number)
	local nextLevel = prestigeLevel + 1

	-- Calculate rewards for the NEXT level
	local coinReward = nextLevel * PrestigeCfg.LUMP_COIN_AWARD_PER_LEVEL
	local speedBonus = nextLevel * PrestigeCfg.SPEED_BONUS_PER_LEVEL
	local collectBonus = nextLevel * PrestigeCfg.COIN_COLLECT_BONUS_PER_LEVEL * 100

	levelLabel.Text = string.format("Prestige: %d ? %d", prestigeLevel, nextLevel)

	-- Display all the upcoming rewards
	bonusLabel.Text = string.format(
		"Rewards for Next Level:\n" ..
			"• Instantly gain %d Coins\n" ..
			"• +%.2f Base Speed (Permanent)\n" ..
			"• +%d%% Coin Collection Bonus",
		coinReward,
		speedBonus,
		collectBonus
	)
end

local function updateButtonState()
	if isAwaitingResponse then
		prestigeButton.Text = "PRESTIGING..."
		prestigeButton.AutoButtonColor = false
		prestigeButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
	else
		prestigeButton.Text = "PRESTIGE NOW" -- Changed text
		prestigeButton.AutoButtonColor = true
		prestigeButton.BackgroundColor3 = Color3.fromRGB(255, 85, 0) -- Changed color
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