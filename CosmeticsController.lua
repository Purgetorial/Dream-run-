--------------------------------------------------------------------
-- CosmeticsController.lua | Trails list + equip / recolor UX (Optimized)
-- • Implements UI caching to eliminate lag when opening the menu.
-- • Simplifies state management for equipping/unequipping trails.
-- • Fetches cosmetic data more efficiently.
--------------------------------------------------------------------
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local UserInputService   = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- Remotes & Config
local Remotes         = ReplicatedStorage.Remotes
local GetCosmetics    = Remotes.GetCosmetics
local EquipCosmetic   = Remotes.EquipCosmetic
local UnequipCosmetic = Remotes.UnequipCosmetic
local ModalState      = ReplicatedStorage.UIEvents.ModalState
local OpenCosmetics   = ReplicatedStorage.OpenCosmetics
local ShopItems       = require(ReplicatedStorage.Config.ShopItems)

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
local itemRows = {} -- Cache for UI rows [trailName] = row

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

-- Refreshes the state of all buttons in the list
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
		-- Prevent spamming
		if not btn.AutoButtonColor then return end

		if equippedTrail == item.Name then
			-- Unequip current trail
			UnequipCosmetic:FireServer("Trails")
			equippedTrail = ""
		else
			-- Equip new trail
			EquipCosmetic:FireServer("Trails", item.Name)
			equippedTrail = item.Name
		end
		-- Immediately update UI for responsiveness
		refreshAllButtonStyles()
	end)

	row.Parent = content
	itemRows[item.Name] = row
end

local function initializeCosmetics()
	if hasInitialized then return end

	-- Create rows for all cosmetic items once
	for _, itemData in ipairs(ShopItems.Cosmetics) do
		createRow(itemData)
	end

	hasInitialized = true
	content.CanvasSize = UDim2.fromOffset(0, content.UILayout.AbsoluteContentSize.Y)
end

local function refreshPanel()
	local data = GetCosmetics:InvokeServer()
	local owned = data.OwnedCosmetics.Trails or {}
	equippedTrail = data.EquippedCosmetics.Trails or ""

	-- Set visibility based on ownership
	for name, row in pairs(itemRows) do
		row.Visible = table.find(owned, name) ~= nil
	end

	refreshAllButtonStyles()
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

-- Server echo handlers to confirm equip/unequip
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

-- For Studio previewing
if not game:GetService("RunService"):IsRunning() then open() end