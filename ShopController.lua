-------------------------------------------------------------------------------
-- ShopController.lua · (Optimized with UI Caching)
-- • Implements a UI caching system to prevent recreating item rows.
-- • Drastically improves performance and responsiveness when opening or switching tabs.
-- • Uses direct leaderstat connections for live coin updates.
-------------------------------------------------------------------------------
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService   = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Config & Remotes
local ShopItems      = require(ReplicatedStorage.Config.ShopItems)
local Remotes        = ReplicatedStorage.Remotes
local BuyItemRF      = Remotes.BuyItem
local GetCosmetics   = Remotes.GetCosmetics
local OpenShopEvt    = ReplicatedStorage.OpenShop
local ModalState     = ReplicatedStorage.UIEvents.ModalState

-- UI References
local panel      = script.Parent
local gui        = panel.Parent
local content    = panel.ContentArea
local rowTpl     = content.ItemTemplate
local closeBtn   = panel.CloseButton
local coinsLabel = panel.CurrencyBar.CoinsLabel
local tabs = {
	Boosts    = panel.TabsBar.BoostsTab,
	Cosmetics = panel.TabsBar.CosmeticsTab,
	Robux     = panel.TabsBar.RobuxTab,
}

-------------------------------------------------------------------------------
-- State & Caching
-------------------------------------------------------------------------------
local SELECTED_COLOR   = Color3.fromRGB(0, 180, 255)
local UNSELECTED_COLOR = Color3.fromRGB(0, 110, 185)
local currentTab = "Boosts"
local hasInitialized = false
local itemRows = { Boosts = {}, Cosmetics = {}, Robux = {} } -- Cache for UI rows

-------------------------------------------------------------------------------
-- Helper Functions
-------------------------------------------------------------------------------
local function comma(n: number): string
	return tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
end

local function updateCoins(value)
	coinsLabel.Text = comma(value)
end

local function styleButton(btn: TextButton, state: string, isRobux: boolean)
	btn:SetAttribute("State", state)
	if state == "Buy" then
		btn.Text = isRobux and "R$" or "BUY"
		btn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
		btn.AutoButtonColor = true
	elseif state == "Active" then
		btn.Text = "ACTIVE"
		btn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
		btn.AutoButtonColor = false
	elseif state == "Owned" then
		btn.Text = "OWNED"
		btn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		btn.AutoButtonColor = false
	else -- "..." (processing)
		btn.Text = "..."
		btn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
		btn.AutoButtonColor = false
	end
end

-------------------------------------------------------------------------------
-- UI Population & Management
-------------------------------------------------------------------------------
local function createRow(tabName, item)
	local row = rowTpl:Clone()
	row.Name = item.Name
	row.Icon.Image = item.Icon or "rbxassetid://3926305904"
	row.NameLabel.Text = item.Name
	row.DescLabel.Text = item.Desc or ""

	local isRobux = item.ProductId ~= nil
	row.PriceLabel.Visible = not isRobux and item.Price and item.Price > 0
	if row.PriceLabel.Visible then
		row.PriceLabel.Text = "? " .. comma(item.Price) -- Using a coin icon
	end

	local btn = row.BuyButton
	btn.MouseButton1Click:Connect(function()
		if btn:GetAttribute("State") ~= "Buy" then return end
		styleButton(btn, "...", isRobux)

		if isRobux then
			MarketplaceService:PromptProductPurchase(player, item.ProductId)
			task.wait(0.5) -- Give time for purchase prompt to process
			if btn:GetAttribute("State") == "..." then styleButton(btn, "Buy", isRobux) end
		else
			local success = BuyItemRF:InvokeServer(tabName, item.BoostName or item.Name)
			if success then
				styleButton(btn, (tabName == "Boosts") and "Active" or "Owned", isRobux)
			else
				styleButton(btn, "Buy", isRobux)
			end
		end
	end)

	row.Parent = content
	itemRows[tabName][item.Name] = row
	return row
end

local function initializeShop()
	if hasInitialized then return end

	-- Create all rows for all tabs at once
	for _, item in ipairs(ShopItems.Boosts) do createRow("Boosts", item) end
	for _, item in ipairs(ShopItems.Cosmetics) do createRow("Cosmetics", item) end
	for _, item in ipairs(ShopItems.Robux) do createRow("Robux", item) end

	hasInitialized = true
	content.CanvasSize = UDim2.fromOffset(0, content.UILayout.AbsoluteContentSize.Y)
end

local function setTab(tabName: string)
	currentTab = tabName

	-- Update tab button colors
	for name, btn in pairs(tabs) do
		btn.BackgroundColor3 = (name == tabName) and SELECTED_COLOR or UNSELECTED_COLOR
	end

	-- Update row visibility based on the selected tab
	for tab, rows in pairs(itemRows) do
		for _, row in pairs(rows) do
			row.Visible = (tab == tabName)
		end
	end
end

local function refreshButtonStates()
	-- Refresh cosmetics
	local cosmeticsData = GetCosmetics:InvokeServer()
	local ownedTrails = cosmeticsData.OwnedCosmetics.Trails or {}
	for _, trailName in ipairs(ownedTrails) do
		if itemRows.Cosmetics[trailName] then
			styleButton(itemRows.Cosmetics[trailName].BuyButton, "Owned", false)
		end
	end

	-- Refresh boosts
	local activeBoosts = player:WaitForChild("ActiveBoosts")
	for _, boostFlag in ipairs(activeBoosts:GetChildren()) do
		if itemRows.Boosts[boostFlag.Name] then
			styleButton(itemRows.Boosts[boostFlag.Name].BuyButton, boostFlag.Value and "Active" or "Buy", true)
		end
	end
	-- Specifically check for Lightspeed gamepass
	if player:FindFirstChild("PermanentLightspeed") and itemRows.Boosts["Lightspeed"] then
		styleButton(itemRows.Boosts["Lightspeed"].BuyButton, "Owned", true)
	end
end

-------------------------------------------------------------------------------
-- Open / Close Logic
-------------------------------------------------------------------------------
local function openShop()
	initializeShop()
	refreshButtonStates()
	ModalState:Fire(true)
	gui.Enabled, panel.Visible = true, true
	setTab(currentTab)
end

local function closeShop()
	gui.Enabled, panel.Visible = false, false
	ModalState:Fire(false)
end

closeBtn.MouseButton1Click:Connect(closeShop)
UserInputService.InputBegan:Connect(function(i, gp)
	if not gp and i.KeyCode == Enum.KeyCode.Escape and gui.Enabled then closeShop() end
end)
OpenShopEvt.Event:Connect(openShop)

-- Live coin counter connection
player:WaitForChild("leaderstats"):WaitForChild("Coins").Changed:Connect(updateCoins)
updateCoins(player.leaderstats.Coins.Value)

-- For Studio previewing
if not game:GetService("RunService"):IsRunning() then openShop() end