--------------------------------------------------------------------
-- CosmeticsController.lua  |  Trails list + equip / recolour UX
--------------------------------------------------------------------
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local UIS                = game:GetService("UserInputService")

local Remotes        = ReplicatedStorage.Remotes
local GetCosmetics   = Remotes.GetCosmetics
local EquipCosmetic  = Remotes.EquipCosmetic
local UnequipCosmetic= Remotes.UnequipCosmetic
local SetTrailColor  = Remotes.SetTrailColor

local ModalState     = ReplicatedStorage.UIEvents.ModalState
local OpenCosmetics  = ReplicatedStorage.OpenCosmetics

local ShopItems  = require(ReplicatedStorage.Config.ShopItems)
local TrailColours = require(ReplicatedStorage.Config.TrailColors)

--------------------------------------------------------------------  UI refs
local panel    = script.Parent
local gui      = panel.Parent
local content  = panel.ContentArea
local rowTpl   = content.RowTemplate
local closeBtn = panel.CloseButton

--------------------------------------------------------------------  Build meta table once
local TrailMeta = {}
for _, it in ipairs(ShopItems.Cosmetics or {}) do TrailMeta[it.Name] = it end

--------------------------------------------------------------------  Local state
local player   = Players.LocalPlayer
local equipped = ""  -- current equipped trail name

--------------------------------------------------------------------  Helpers
local function style(btn, isEq)
	btn.Text            = isEq and "Equipped" or "Equip"
	btn.BackgroundColor3= isEq and Color3.fromRGB(0,200,0) or Color3.fromRGB(0,170,0)
	btn.AutoButtonColor = not isEq
end

local function clearRows()
	for _,c in ipairs(content:GetChildren()) do
		if c:IsA("Frame") and c ~= rowTpl then c:Destroy() end
	end
end

local function recolor(seq) SetTrailColor:FireServer(seq) end  -- fallback

local function addRow(name:string, isEq:boolean)
	local meta = TrailMeta[name] or {}
	local f = rowTpl:Clone(); f.Visible = true

	f.NameLabel.Text = name
	f.DescLabel.Text = meta.Desc or ""
	if meta.Icon then f.Icon.Image = meta.Icon end

	local btn = f.EquipButton
	style(btn, isEq)

	btn.MouseButton1Click:Connect(function()
		if equipped == name then
			UnequipCosmetic:FireServer("Trails")
			equipped = ""
		else
			EquipCosmetic:FireServer("Trails", name)
			equipped = name
		end
		for _, row in ipairs(content:GetChildren()) do
			if row:IsA("Frame") and row ~= rowTpl then
				style(row.EquipButton, row.NameLabel.Text == equipped)
			end
		end
	end)

	f.Parent = content
end

local function populate()
	clearRows()
	local data      = GetCosmetics:InvokeServer()
	local owned     = data.OwnedCosmetics.Trails or {}
	equipped        = data.EquippedCosmetics.Trails or ""

	for _, trail in ipairs(owned) do
		addRow(trail, trail == equipped)
	end
end

--------------------------------------------------------------------  Remote echo (so UI updates when server confirms equip)
EquipCosmetic.OnClientEvent:Connect(function(_, tab, name)
	if tab ~= "Trails" then return end
	equipped = name
	populate()
end)
UnequipCosmetic.OnClientEvent:Connect(function(_, tab)
	if tab == "Trails" then equipped = ""; populate() end
end)

--------------------------------------------------------------------  Open / Close
local function open()  ModalState:Fire(true); populate(); gui.Enabled = true; panel.Visible = true end
local function close() ModalState:Fire(false); gui.Enabled = false; panel.Visible = false end

closeBtn.MouseButton1Click:Connect(close)
UIS.InputBegan:Connect(function(i,gp) if not gp and i.KeyCode==Enum.KeyCode.Escape and gui.Enabled then close() end end)
OpenCosmetics.Event:Connect(open)

if not game:GetService("RunService"):IsRunning() then open() end  -- Studio preview
