--------------------------------------------------------------------
-- LeaderboardController.lua  •  Fastest Times & Prestige board
--------------------------------------------------------------------
------------------------------ Services ----------------------------
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS               = game:GetService("UserInputService")

------------------------------ UI Refs ----------------------------
local panel  = script.Parent                   -- BoardPanel
local gui    = panel.Parent                    -- LeaderboardGui

local titleLbl = panel:WaitForChild("TitleLabel")
local closeBtn = panel:WaitForChild("CloseButton")

local timesTab = panel:WaitForChild("TimesTab")
local prestTab = panel:WaitForChild("PrestigeTab")

local listFrame = panel:WaitForChild("Entries")
local rowTpl    = listFrame:WaitForChild("EntryTemplate")

------------------------------ Remotes ----------------------------
local RequestLB = ReplicatedStorage.Remotes:WaitForChild("RequestLeaderboard")
local OpenLBEvt = ReplicatedStorage.OpenLeaderboard   -- BindableEvent fired from MainMenu

------------------------------ Modal Event ------------------------
local ModalState = ReplicatedStorage.UIEvents.ModalState

------------------------------ Helpers ----------------------------
local localName = Players.LocalPlayer.Name

local function fmtTime(t:number)
	return (t == math.huge) and "--:--.--"
		or string.format("%02d:%05.2f", math.floor(t/60), t%60)
end

local function clear()
	for _, f in ipairs(listFrame:GetChildren()) do
		if f:IsA("Frame") and f ~= rowTpl then f:Destroy() end
	end
end

local function makeRow(rank,rowData,mode)
	local f = rowTpl:Clone()
	f.Name  = "Row_"..rank
	f.Visible = true
	f.LayoutOrder = rank

	f.RankLabel.Text = "#" .. rank
	f.NameLabel.Text = rowData.Name or "Player"

	if mode == "BestTime" then
		f.TimeLabel.Visible      = true
		f.TimeLabel.Text         = fmtTime(rowData.BestTime)
		f.PrestigeLabel.Visible  = false
	else
		f.TimeLabel.Visible      = false
		f.PrestigeLabel.Visible  = true
		f.PrestigeLabel.Text     = tostring(rowData.Prestige or 0)
	end

	-- highlight the local player
	if rowData.Name == localName then
		f.BackgroundColor3 = Color3.fromRGB(200,255,200)
		f.Name = "PlayerRow"
	end

	f.Parent = listFrame
end

------------------------------ State ------------------------------
local mode = "BestTime"

local function highlightTabs()
	timesTab.BackgroundTransparency  = (mode=="BestTime") and 0 or 0.25
	prestTab.BackgroundTransparency  = (mode=="Prestige") and 0 or 0.25
end

local function refresh()
	local ok,data = pcall(function()
		return RequestLB:InvokeServer(mode)
	end)
	if not ok or typeof(data)~="table" then
		warn("[LB] Failed:", data); return
	end

	clear()
	for i,row in ipairs(data) do makeRow(i,row,mode) end

	titleLbl.Text = (mode=="BestTime") and "FASTEST TIMES" or "TOP PRESTIGE"
	highlightTabs()
end

------------------------------ Open / Close -----------------------
local function open()
	ModalState:Fire(true)
	gui.Enabled = true
	panel.Visible = true
	refresh()
end

local function close()
	gui.Enabled = false
	panel.Visible = false
	ModalState:Fire(false)
end

closeBtn.MouseButton1Click:Connect(close)
UIS.InputBegan:Connect(function(inp,gp)
	if gp then return end
	if inp.KeyCode == Enum.KeyCode.Escape and gui.Enabled then close() end
end)
OpenLBEvt.Event:Connect(open)

------------------------------ Tab clicks -------------------------
timesTab.MouseButton1Click:Connect(function()
	if mode ~= "BestTime" then mode="BestTime"; refresh() end
end)
prestTab.MouseButton1Click:Connect(function()
	if mode ~= "Prestige" then mode="Prestige"; refresh() end
end)

------------------------------ Studio Preview --------------------
if not game:GetService("RunService"):IsRunning() then
	gui.Enabled, panel.Visible = true, true
	makeRow(1,{Name=localName,BestTime=65.11,Prestige=2},"BestTime")
end
