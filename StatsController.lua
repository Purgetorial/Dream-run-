--------------------------------------------------------------------
-- StatsController.lua
--------------------------------------------------------------------
------------------------------ Services ----------------------------
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS               = game:GetService("UserInputService")

------------------------------ UI refs ----------------------------
local panel    = script.Parent                     -- StatsPanel
local gui      = panel.Parent                      -- StatsGui
local closeBtn = panel.CloseButton
local content  = panel.ContentArea                 -- ScrollingFrame
local rowTpl   = content.StatTemplate              -- invisible template

------------------------------ Remotes & Events -------------------
local UIEvents     = ReplicatedStorage:WaitForChild("UIEvents")
local ModalState   = UIEvents:WaitForChild("ModalState")

local Remotes      = ReplicatedStorage:WaitForChild("Remotes")    -- ? FIX
local GetStatsRF   = Remotes:WaitForChild("GetStats")             -- ? FIX
local OpenStatsEvt = ReplicatedStorage:WaitForChild("OpenStats")

------------------------------ Helpers ----------------------------
local player = Players.LocalPlayer
local rowsByKey = {}         -- ["Coins"] = ValueLabel
local coinConn  -- RBXScriptConnection

local function fmtTime(t:number): string
	return (t == math.huge) and "--:--.--"
		or string.format("%d:%05.2f", math.floor(t/60), t%60)
end

local function clearRows()
	for _, ch in ipairs(content:GetChildren()) do
		if ch:IsA("Frame") and ch ~= rowTpl then ch:Destroy() end
	end
	rowsByKey = {}
end

local function addRow(key:string, val:any, order:number)
	local r = rowTpl:Clone()
	r.Visible, r.LayoutOrder = true, order
	r.NameLabel.Text, r.ValueLabel.Text = key, tostring(val)
	r.Parent = content
	rowsByKey[key] = r.ValueLabel
end

---------------- live Coins watcher --------------------------------
local function watchCoins()
	if coinConn then coinConn:Disconnect(); coinConn = nil end
	local ls = player:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Coins") and rowsByKey["Coins"] then
		coinConn = ls.Coins.Changed:Connect(function(v)
			rowsByKey["Coins"].Text = tostring(v)
		end)
	end
end

---------------- open / close -------------------------------------
local function open()
	ModalState:Fire(true)
	local stats, serverTime = GetStatsRF:InvokeServer()

	clearRows()
	local ord = 1
	addRow("Prestige",        stats.Prestige,           ord); ord += 1
	addRow("Personal Best",   fmtTime(stats.BestTime),  ord); ord += 1
	addRow("Coins",           stats.Coins,              ord); ord += 1
	addRow("Lifetime Coins",  stats.TotalCoins,         ord); ord += 1
	addRow("Runs Finished",   stats.RunsFinished,       ord); ord += 1

	-- active boosts (if any)
	local boosts = player:WaitForChild("ActiveBoosts")
	for _, b in ipairs(boosts:GetChildren()) do
		if b.Value and b:FindFirstChild("ExpireAt") then
			local remain = math.max(0, math.ceil(b.ExpireAt.Value - serverTime))
			addRow("Active "..b.Name, remain.." s", ord)
			ord += 1
		end
	end

	watchCoins()
	gui.Enabled, panel.Visible = true, true
end

local function close()
	gui.Enabled, panel.Visible = false, false
	ModalState:Fire(false)
	if coinConn then coinConn:Disconnect(); coinConn = nil end
end

closeBtn.MouseButton1Click:Connect(close)
UIS.InputBegan:Connect(function(inp,gp)
	if not gp and inp.KeyCode == Enum.KeyCode.Escape and gui.Enabled then close() end
end)
OpenStatsEvt.Event:Connect(open)

-- Studio preview
if not game:GetService("RunService"):IsRunning() then open() end
