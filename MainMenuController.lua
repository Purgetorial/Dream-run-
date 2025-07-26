local player = game.Players.LocalPlayer
local gui = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OpenMainMenuLocal = ReplicatedStorage:WaitForChild("OpenMainMenuLocal")
local RequestRunStart = ReplicatedStorage.Remotes:WaitForChild("RequestRunStart")

local mainPanel = gui:WaitForChild("MainPanel")
local leaderboardButton = mainPanel.ButtonHolder:WaitForChild("LeaderboardButton")
local shopButton = mainPanel.ButtonHolder:WaitForChild("ShopButton")
local cosmeticsButton = mainPanel.ButtonHolder:WaitForChild("CosmeticsButton")
local statsButton = mainPanel.ButtonHolder:WaitForChild("StatsButton")
local settingsButton = mainPanel.ButtonHolder:WaitForChild("SettingsButton")

local OpenShopEvent = ReplicatedStorage:WaitForChild("OpenShop")
local OpenCosmeticsEvent = ReplicatedStorage:WaitForChild("OpenCosmetics")
local OpenLeaderboardEvent = ReplicatedStorage:WaitForChild("OpenLeaderboard")
local OpenStatsEvent = ReplicatedStorage:WaitForChild("OpenStats")

-- Hide MainMenu at game start (no fade)
gui.Enabled = false
mainPanel.Visible = true

local function openMenu()
	gui.Enabled = true
	mainPanel.Visible = true
end

local function closeMenu()
	mainPanel.Visible = false
	gui.Enabled = false
end

-- Toggle menu on event (from HUD menu button)
OpenMainMenuLocal.Event:Connect(function()
	if gui.Enabled then
		closeMenu()
	else
		openMenu()
	end
end)


leaderboardButton.MouseButton1Click:Connect(function()
	closeMenu()
	OpenLeaderboardEvent:Fire()
end)

shopButton.MouseButton1Click:Connect(function()
	closeMenu()
	OpenShopEvent:Fire()
end)

cosmeticsButton.MouseButton1Click:Connect(function()
	closeMenu()
	OpenCosmeticsEvent:Fire()
end)

statsButton.MouseButton1Click:Connect(function()
	closeMenu()
	OpenStatsEvent:Fire()
end)

-- ESC closes menu
game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.Escape and gui.Enabled then
		closeMenu()
	end
end)
