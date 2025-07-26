--------------------------------------------------------------------
-- StatsController.lua (Optimized & Bug-Fixed)
-- • FIX: Removed an invalid function call that was causing a warning.
-- • Now updates all stats (PB, Coins, Prestige) in real-time.
-- • Fixes the active boost timer to provide an accurate live countdown.
--------------------------------------------------------------------
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")

local player = Players.LocalPlayer

-- UI Refs
local panel    = script.Parent
local gui      = panel.Parent
local closeBtn = panel.CloseButton
local content  = panel.ContentArea
local rowTpl   = content.StatTemplate

-- Remotes & Events
local UIEvents     = ReplicatedStorage:WaitForChild("UIEvents")
local ModalState   = UIEvents:WaitForChild("ModalState")
local Remotes      = ReplicatedStorage:WaitForChild("Remotes")
local GetStatsRF   = Remotes:WaitForChild("GetStats")
local OpenStatsEvt = ReplicatedStorage:WaitForChild("OpenStats")

--------------------------------------------------------------------
-- State & Helpers
--------------------------------------------------------------------
local rowsByKey = {} -- ["Coins"] = ValueLabel
local connections = {} -- To hold script connections so we can disconnect them
local boostRows = {} -- To manage active boost countdowns

local function fmtTime(t:number): string
	return (t == math.huge) and "--:--.--"
		or string.format("%d:%05.2f", math.floor(t/60), t % 60)
end

local function clearRows()
	for _, child in ipairs(content:GetChildren()) do
		if child:IsA("Frame") and child ~= rowTpl then
			child:Destroy()
		end
	end
	rowsByKey = {}
	boostRows = {}
end

local function createRow(key: string, val: any, order: number)
	local row = rowTpl:Clone()
	row.Visible = true
	row.LayoutOrder = order
	row.NameLabel.Text = key
	row.ValueLabel.Text = tostring(val)
	row.Parent = content
	rowsByKey[key] = row.ValueLabel
	return row
end

--------------------------------------------------------------------
-- Live UI Management
--------------------------------------------------------------------
local function updateBoosts()
	for boostName, data in pairs(boostRows) do
		local remaining = math.max(0, math.ceil(data.expireTime - os.time()))
		if remaining > 0 then
			data.label.Text = remaining .. "s"
		else
			data.row:Destroy() -- Remove the row when the boost expires
			boostRows[boostName] = nil
		end
	end
end

-- Forward declare the close function so it can be referenced
local close 

local function watchStats()
	-- Disconnect any old connections to prevent memory leaks
	for _, conn in pairs(connections) do conn:Disconnect() end
	table.clear(connections)

	local ls = player:WaitForChild("leaderstats")
	if not ls then close() return end

	-- Connect to leaderstat changes
	table.insert(connections, ls.Coins.Changed:Connect(function(v) rowsByKey["Coins"].Text = tostring(v) end))
	table.insert(connections, ls.Prestige.Changed:Connect(function(v) rowsByKey["Prestige"].Text = tostring(v) end))
	table.insert(connections, ls.BestTime.Changed:Connect(function(v) rowsByKey["Personal Best"].Text = fmtTime(v) end))

	-- Connect to the Heartbeat to update boost timers
	table.insert(connections, RunService.Heartbeat:Connect(updateBoosts))
end

--------------------------------------------------------------------
-- Open / Close Panel
--------------------------------------------------------------------
local function open()
	ModalState:Fire(true)
	gui.Enabled, panel.Visible = true, true

	local stats = GetStatsRF:InvokeServer()
	if not stats then
		-- The stats werent loaded, we should close the panel.
		-- We can't call close() directly here because it may not be defined yet.
		-- Instead, we can just disable the GUI.
		gui.Enabled, panel.Visible = false, false
		ModalState:Fire(false)
		return
	end

	clearRows()

	local ord = 1
	createRow("Prestige", stats.Prestige, ord); ord += 1
	createRow("Personal Best", fmtTime(stats.BestTime), ord); ord += 1
	createRow("Coins", stats.Coins, ord); ord += 1
	createRow("Lifetime Coins", stats.TotalCoins, ord); ord += 1
	createRow("Runs Finished", stats.RunsFinished, ord); ord += 1

	local boostsFolder = player:WaitForChild("ActiveBoosts")
	for _, boostFlag in ipairs(boostsFolder:GetChildren()) do
		if boostFlag.Value and boostFlag:IsA("BoolValue") then
			local expireAt = boostFlag:FindFirstChild("ExpireAt")
			if expireAt then
				local row = createRow("Active: " .. boostFlag.Name, "", ord); ord += 1
				boostRows[boostFlag.Name] = {
					row = row,
					label = row.ValueLabel,
					expireTime = expireAt.Value,
				}
			end
		end
	end

	watchStats()
end

close = function()
	for _, conn in pairs(connections) do conn:Disconnect() end
	table.clear(connections)

	gui.Enabled, panel.Visible = false, false
	ModalState:Fire(false)
end

closeBtn.MouseButton1Click:Connect(close)
UserInputService.InputBegan:Connect(function(inp, gp)
	if not gp and inp.KeyCode == Enum.KeyCode.Escape and gui.Enabled then
		close()
	end
end)
OpenStatsEvt.Event:Connect(open)

if not RunService:IsRunning() then open() end