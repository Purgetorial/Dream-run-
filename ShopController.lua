-------------------------------------------------------------------------------
-- ShopController.lua · Boosts tab (Low-Gravity, Double-Coins, Lightspeed),
--                      robust BUY / R$ / ACTIVE / OWNED buttons,
--                      always-visible descriptions,
--                      coloured tab buttons
-------------------------------------------------------------------------------
local Players, Rep, MPS, UIS = game:GetService("Players"),
	game:GetService("ReplicatedStorage"),
	game:GetService("MarketplaceService"),
	game:GetService("UserInputService")

local ShopItems       = require(Rep.Config.ShopItems)
local player          = Players.LocalPlayer
local activeBoosts    = player:WaitForChild("ActiveBoosts")

-- modal helper
local UIEvents   = Rep:FindFirstChild("UIEvents") or Instance.new("Folder", Rep)
UIEvents.Name    = "UIEvents"
local ModalState = UIEvents:FindFirstChild("ModalState") or Instance.new("BindableEvent", UIEvents)
ModalState.Name  = "ModalState"

-------------------------------------------------------------------------------
-- UI references
-------------------------------------------------------------------------------
local panel       = script.Parent
local content     = panel.ContentArea
local rowTemplate = content.ItemTemplate

local tabs = {
	Boosts    = panel.TabsBar.BoostsTab,
	Cosmetics = panel.TabsBar.CosmeticsTab,
	Robux     = panel.TabsBar.RobuxTab,
}

local closeBtn   = panel.CloseButton
local coinsLabel = panel.CurrencyBar.CoinsLabel

-------------------------------------------------------------------------------
-- colours
-------------------------------------------------------------------------------
local SELECTED_COLOR   = Color3.fromRGB(  0,180,255)  -- bright aqua
local UNSELECTED_COLOR = Color3.fromRGB(  0,110,185)  -- darker blue

-------------------------------------------------------------------------------
-- remotes
-------------------------------------------------------------------------------
local Remotes      = Rep.Remotes
local BuyItemRF    = Remotes:FindFirstChild("BuyItem") or Instance.new("RemoteFunction", Remotes)
BuyItemRF.Name     = "BuyItem"
local GetCosmetics = Remotes.GetCosmetics
local OpenShopEvt  = Rep.OpenShop

-------------------------------------------------------------------------------
-- coins label
-------------------------------------------------------------------------------
local function comma(n:number):string
	return tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
end
local function updateCoins() coinsLabel.Text = comma(player.leaderstats.Coins.Value) end
player.leaderstats.Coins.Changed:Connect(updateCoins); updateCoins()

-------------------------------------------------------------------------------
-- OWNED cache
-------------------------------------------------------------------------------
local owned = {}
local function refreshOwned()
	local data = GetCosmetics:InvokeServer()
	owned = {}
	for tab, list in pairs(data.OwnedCosmetics or {}) do
		owned[tab] = {}
		for _,n in ipairs(list) do owned[tab][n] = true end
	end
end

-------------------------------------------------------------------------------
-- style helper for Buy buttons
-------------------------------------------------------------------------------
local function style(btn:TextButton, state:string, robux:boolean?)
	if state == "Buy" then
		btn.Text = robux and "R$" or "BUY"
		btn.AutoButtonColor, btn.BackgroundColor3 = true, Color3.fromRGB(0,170,0)
	elseif state == "Active" then
		btn.Text = "ACTIVE"
		btn.AutoButtonColor, btn.BackgroundColor3 = false, Color3.fromRGB(255,170,0)
	elseif state == "Owned" then
		btn.Text = "OWNED"
		btn.AutoButtonColor, btn.BackgroundColor3 = false, Color3.fromRGB(100,100,100)
	else
		btn.Text = state
	end
	btn:SetAttribute("State", state)
end

-------------------------------------------------------------------------------
-- row builder
-------------------------------------------------------------------------------
local rowByBoost = {}  -- for live Active updates

local TAB_DATA = {
	Boosts    = ShopItems.Boosts,
	Cosmetics = ShopItems.Cosmetics,
	Robux     = ShopItems.Robux,
}

local function clearRows()
	for _,c in ipairs(content:GetChildren()) do
		if c:IsA("Frame") and c ~= rowTemplate then c:Destroy() end
	end
	rowByBoost = {}
end

local function addRow(tabName, item)
	local row = rowTemplate:Clone(); row.Visible = true
	row.Icon.Image     = item.Icon or "rbxassetid://3926305904"
	row.NameLabel.Text = item.Name
	row.DescLabel.Text = item.Desc or ""
	row.DescLabel.Visible = true

	local isRobux = (item.ProductId ~= nil)
	row.PriceLabel.Visible = not isRobux and item.Price and item.Price > 0
	if row.PriceLabel.Visible then
		row.PriceLabel.Text = "?? " .. item.Price
	end

	local btn = row.BuyButton
	---------------------------------------------------------------- purchase
	local function tryBuy()
		if btn:GetAttribute("State") ~= "Buy" then return end
		style(btn,"...",isRobux)
		if isRobux then
			MPS:PromptProductPurchase(player,item.ProductId)
			task.wait(0.25)
			if btn:GetAttribute("State")=="..." then style(btn,"Buy",isRobux) end
		else
			task.spawn(function()
				local ok = BuyItemRF:InvokeServer(tabName,item.BoostName or item.Name)
				if ok then
					style(btn, (tabName=="Boosts") and "Active" or "Owned", isRobux)
				else
					style(btn,"Buy",isRobux)
				end
			end)
		end
	end
	btn.MouseButton1Click:Connect(tryBuy)

	---------------------------------------------------------------- initial state
	if tabName=="Boosts" then
		if item.BoostName=="Lightspeed" and player:FindFirstChild("PermanentLightspeed") then
			style(btn,"Owned")
		else
			local flag = activeBoosts:FindFirstChild(item.BoostName)
			if flag and flag.Value then style(btn,"Active") else style(btn,"Buy",isRobux) end
			if flag then
				flag.Changed:Connect(function(v) style(btn,v and "Active" or "Buy",isRobux) end)
			end
			rowByBoost[item.BoostName]=btn
		end
	elseif tabName=="Cosmetics" then
		if owned.Trails and owned.Trails[item.Name] then style(btn,"Owned") else style(btn,"Buy") end
	else -- Robux coin packs
		style(btn,"Buy",true)
	end

	row.Parent = content
end

-------------------------------------------------------------------------------
-- populate tab
-------------------------------------------------------------------------------
local function populate(tab)
	clearRows()
	if tab=="Cosmetics" then refreshOwned() end
	for _,itm in ipairs(TAB_DATA[tab] or {}) do addRow(tab,itm) end
	task.defer(function()
		local y=0
		for _,v in ipairs(content:GetChildren()) do
			if v:IsA("Frame") and v~=rowTemplate then y+=v.AbsoluteSize.Y+4 end
		end
		content.CanvasSize=UDim2.fromOffset(0,y)
	end)
end

-------------------------------------------------------------------------------
-- tab select
-------------------------------------------------------------------------------
local currentTab = "Boosts"
local function setTab(name)
	currentTab = name
	for t,btn in pairs(tabs) do
		btn.BackgroundColor3 = (t==name) and SELECTED_COLOR or UNSELECTED_COLOR
	end
	populate(name)
end
for n,b in pairs(tabs) do b.MouseButton1Click:Connect(function() setTab(n) end) end

-------------------------------------------------------------------------------
-- open / close
-------------------------------------------------------------------------------
local function openShop()
	refreshOwned()
	ModalState:Fire(true)
	panel.Visible=true; panel.Parent.Enabled=true
	setTab(currentTab)
	updateCoins()
end
local function closeShop()
	panel.Visible=false; panel.Parent.Enabled=false
	ModalState:Fire(false)
end
closeBtn.MouseButton1Click:Connect(closeShop)
UIS.InputBegan:Connect(function(i,gp)
	if not gp and i.KeyCode==Enum.KeyCode.Escape and panel.Parent.Enabled then closeShop() end
end)
OpenShopEvt.Event:Connect(openShop)

-- preview in Studio
if not game:GetService("RunService"):IsRunning() then openShop() end
