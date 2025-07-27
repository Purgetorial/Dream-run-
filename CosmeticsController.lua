--------------------------------------------------------------------
-- CosmeticsController.lua | (Asynchronous, No-Freeze Caching & Bug Fix)
-- • FIX: Uses asynchronous events to request and receive cosmetic data, eliminating UI freezing.
-- • Opens instantly and updates item visibility in the background.
--------------------------------------------------------------------
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")

local player = Players.LocalPlayer

-- Remotes & Config
local Remotes           = ReplicatedStorage.Remotes
local EquipCosmetic     = Remotes.EquipCosmetic
local UnequipCosmetic   = Remotes.UnequipCosmetic
local ModalState        = ReplicatedStorage.UIEvents.ModalState
local OpenCosmetics     = ReplicatedStorage.OpenCosmetics
local ShopItems         = require(ReplicatedStorage.Config.ShopItems)
local RequestCosmetics  = Remotes.RequestCosmetics
local ReceiveCosmetics  = Remotes.ReceiveCosmetics

-- UI Refs
local panel     = script.Parent
local gui       = panel.Parent
local content   = panel.ContentArea
local rowTpl    = content.RowTemplate
local closeBtn  = panel.CloseButton

--------------------------------------------------------------------
-- State & Caching
--------------------------------------------------------------------
local hasInitialized = false
local equippedTrail = ""
local itemRows = {}

--------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------
local function styleButton(btn: TextButton, isEquipped: boolean)
	if isEquipped then
		btn.Text = "EQUIPPED"
		btn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
		btn.AutoButtonColor = false
	else
		btn.Text = "EQUIP"
		btn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
		btn.AutoButtonColor = true
	end
end

local function refreshAllButtonStyles()
	for trailName, row in pairs(itemRows) do
		styleButton(row.EquipButton, trailName == equippedTrail)
	end
end

--------------------------------------------------------------------
-- UI Population & Management
--------------------------------------------------------------------
local function createRow(item)
	local row = rowTpl:Clone()
	row.Name = item.Name
	row.NameLabel.Text = item.Name
	row.DescLabel.Text = item.Desc or ""
	if item.Icon then row.Icon.Image = item.Icon end

	local btn = row.EquipButton
	btn.MouseButton1Click:Connect(function()
		if not btn.AutoButtonColor then return end

		if equippedTrail == item.Name then
			UnequipCosmetic:FireServer("Trails")
			equippedTrail = ""
		else
			EquipCosmetic:FireServer("Trails", item.Name)
			equippedTrail = item.Name
		end
		refreshAllButtonStyles()
	end)

	row.Parent = content
	itemRows[item.Name] = row
end

local function initializeCosmetics()
	if hasInitialized then return end

	for _, itemData in ipairs(ShopItems.Cosmetics) do
		createRow(itemData)
	end

	hasInitialized = true
	content.CanvasSize = UDim2.fromOffset(0, content.UIListLayout.AbsoluteContentSize.Y)
end

local function refreshPanel()
	-- Hide all rows initially
	for _, row in pairs(itemRows) do
		row.Visible = false
	end

	-- Request latest data from the server
	RequestCosmetics:FireServer()
end

--------------------------------------------------------------------
-- Open / Close Logic
--------------------------------------------------------------------
local function open()
	initializeCosmetics()
	refreshPanel()
	ModalState:Fire(true)
	gui.Enabled, panel.Visible = true, true
end

local function close()
	gui.Enabled, panel.Visible = false, false
	ModalState:Fire(false)
end

closeBtn.MouseButton1Click:Connect(close)
UserInputService.InputBegan:Connect(function(i, gp)
	if not gp and i.KeyCode == Enum.KeyCode.Escape and gui.Enabled then close() end
end)
OpenCosmetics.Event:Connect(open)

-- Listen for the server to send back cosmetic data
ReceiveCosmetics.OnClientEvent:Connect(function(cosmeticsData)
	if not cosmeticsData or not cosmeticsData.OwnedCosmetics then return end

	local owned = cosmeticsData.OwnedCosmetics.Trails or {}
	equippedTrail = cosmeticsData.EquippedCosmetics.Trails or ""

	-- Set visibility based on ownership
	for name, row in pairs(itemRows) do
		row.Visible = table.find(owned, name) ~= nil
	end

	refreshAllButtonStyles()
end)

EquipCosmetic.OnClientEvent:Connect(function(_, tab, name)
	if tab == "Trails" then
		equippedTrail = name
		refreshAllButtonStyles()
	end
end)

UnequipCosmetic.OnClientEvent:Connect(function(_, tab)
	if tab == "Trails" then
		equippedTrail = ""
		refreshAllButtonStyles()
	end
end)

if not RunService:IsRunning() then open() end