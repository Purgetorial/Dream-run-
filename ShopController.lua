-------------------------------------------------------------------------------
-- ShopController.lua · (Final Bug Fix Version)
-- • FIX: Corrected tab initialization logic so items appear instantly.
-- • FIX: Robux purchases are now correctly handled entirely on the client.
-- • Opens instantly and updates button states in the background.
-------------------------------------------------------------------------------
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")

local player = Players.LocalPlayer

-- Config & Remotes
local ShopItems         = require(ReplicatedStorage.Config.ShopItems)
local Remotes           = ReplicatedStorage.Remotes
local BuyItemRF         = Remotes.BuyItem
local OpenShopEvt       = ReplicatedStorage.OpenShop
local ModalState        = ReplicatedStorage.UIEvents.ModalState
local RequestCosmetics  = Remotes.RequestCosmetics
local ReceiveCosmetics  = Remotes.ReceiveCosmetics

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
local itemRows = { Boosts = {}, Cosmetics = {}, Robux = {} }

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
		btn.BackgroundColor3 = isRobux and Color3.fromRGB(0, 80, 255) or Color3.fromRGB(0, 170, 0)
		btn.Active = true
		btn.AutoButtonColor = true
	elseif state == "Active" then
		btn.Text = "ACTIVE"
		btn.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
		btn.Active = false
		btn.AutoButtonColor = false
	elseif state == "Owned" then
		btn.Text = "OWNED"
		btn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		btn.Active = false
		btn.AutoButtonColor = false
	else
		btn.Text = "..."
		btn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
		btn.Active = false
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
		row.PriceLabel.Text = "? " .. comma(item.Price)
	end

	local btn = row.BuyButton
	btn.MouseButton1Click:Connect(function()
		if btn:GetAttribute("State") ~= "Buy" then return end
		styleButton(btn, "...", isRobux)

		-- FIX: Correctly differentiate between Robux and Coin purchases
		if isRobux then
			-- Robux purchases are handled entirely on the client
			MarketplaceService:PromptProductPurchase(player, item.ProductId)
			task.wait(0.5)
			-- Reset button state if purchase is cancelled
			if btn:GetAttribute("State") == "..." then
				styleButton(btn, "Buy", isRobux)
			end
		else
			-- Coin purchases are handled by the server
			local success = BuyItemRF:InvokeServer(tabName, item.Name)
			if success then
				styleButton(btn, "Owned", isRobux)
			else
				styleButton(btn, "Buy", isRobux)
			end
		end
	end)

	row.Parent = content
	itemRows[tabName][item.Name] = row
	return row
end

local function setTab(tabName: string)
	currentTab = tabName

	for name, btn in pairs(tabs) do
		btn.BackgroundColor3 = (name == tabName) and SELECTED_COLOR or UNSELECTED_COLOR
	end

	for tab, rows in pairs(itemRows) do
		for _, row in pairs(rows) do
			row.Visible = (tab == tabName)
		end
	end
end

local function initializeShop()
	if hasInitialized then return end

	for _, item in ipairs(ShopItems.Boosts) do createRow("Boosts", item) end
	for _, item in ipairs(ShopItems.Cosmetics) do createRow("Cosmetics", item) end
	for _, item in ipairs(ShopItems.Robux) do createRow("Robux", item) end

	hasInitialized = true
	content.CanvasSize = UDim2.fromOffset(0, content.UIListLayout.AbsoluteContentSize.Y)
end

local function updateAllButtonStates()
	for _, row in pairs(itemRows.Cosmetics) do
		styleButton(row.BuyButton, "...", false)
	end

	RequestCosmetics:FireServer()

	local activeBoosts = player:WaitForChild("ActiveBoosts", 5)
	if activeBoosts then
		for _, boostFlag in ipairs(activeBoosts:GetChildren()) do
			-- Find the corresponding item info to check if it's a Robux item
			local itemInfo = ShopItems.Boosts[boostFlag.Name]
			if itemRows.Boosts[boostFlag.Name] and itemInfo then
				styleButton(itemRows.Boosts[boostFlag.Name].BuyButton, boostFlag.Value and "Active" or "Buy", true)
			end
		end
	end
	if player:FindFirstChild("PermanentLightspeed") and itemRows.Boosts["Lightspeed"] then
		styleButton(itemRows.Boosts["Lightspeed"].BuyButton, "Owned", true)
	end
end

-------------------------------------------------------------------------------
-- Open / Close Logic & Event Connections
-------------------------------------------------------------------------------
local function openShop()
	initializeShop()
	ModalState:Fire(true)
	gui.Enabled, panel.Visible = true, true

	-- FIX: This now correctly sets the initial tab visibility
	setTab(currentTab)

	task.spawn(updateAllButtonStates)
end

local function closeShop()
	gui.Enabled, panel.Visible = false, false
	ModalState:Fire(false)
end

for name, button in pairs(tabs) do
	button.MouseButton1Click:Connect(function()
		setTab(name)
	end)
end

closeBtn.MouseButton1Click:Connect(closeShop)
UserInputService.InputBegan:Connect(function(i, gp)
	if not gp and i.KeyCode == Enum.KeyCode.Escape and gui.Enabled then closeShop() end
end)
OpenShopEvt.Event:Connect(openShop)

ReceiveCosmetics.OnClientEvent:Connect(function(cosmeticsData)
	if not cosmeticsData or not cosmeticsData.OwnedCosmetics then return end

	for _, row in pairs(itemRows.Cosmetics) do
		styleButton(row.BuyButton, "Buy", false)
	end

	local ownedTrails = cosmeticsData.OwnedCosmetics.Trails or {}
	for _, trailName in ipairs(ownedTrails) do
		if itemRows.Cosmetics[trailName] then
			styleButton(itemRows.Cosmetics[trailName].BuyButton, "Owned", false)
		end
	end
end)

local leaderstats = player:WaitForChild("leaderstats")
leaderstats:WaitForChild("Coins").Changed:Connect(updateCoins)
updateCoins(leaderstats.Coins.Value)

if not RunService:IsRunning() then openShop() end