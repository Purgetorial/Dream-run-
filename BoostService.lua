--------------------------------------------------------------------
-- BoostService.lua · timed boosts + permanent Lightspeed pass
--------------------------------------------------------------------
local Players           = game:GetService("Players")
local RepStorage        = game:GetService("ReplicatedStorage")
local DataAPI           = require(game.ServerScriptService.PlayerDataManager)

--------------------------------------------------------------------  PRODUCT IDs
local PRODUCT = {
	LowGravity   = 3344707026,     -- Developer Product (Robux each use)
	DoubleCoins  = 3347370678,
	Lightspeed   = 1339241349,     -- Game-pass (permanent)
}

--------------------------------------------------------------------  BOOST DEFS
local BOOSTS = {
	DoubleCoins = {Duration = 120},
	LowGravity  = {Duration = 120},
}

--------------------------------------------------------------------  REMOTES
local Remotes  = RepStorage:FindFirstChild("Remotes") or Instance.new("Folder", RepStorage)
Remotes.Name   = "Remotes"

local LowGToggle = Remotes:FindFirstChild("ToggleLowGravity") or Instance.new("RemoteEvent", Remotes)
LowGToggle.Name  = "ToggleLowGravity"

--------------------------------------------------------------------  ACTIVEBOOSTS folder
Players.PlayerAdded:Connect(function(p)
	local f = Instance.new("Folder"); f.Name = "ActiveBoosts"; f.Parent = p
	for k in pairs(BOOSTS) do
		local b = Instance.new("BoolValue"); b.Name = k; b.Parent = f
	end
end)

--------------------------------------------------------------------  TIMED BOOST APPLIER
local function applyTimed(p, boostName, dur)
	local flag = p.ActiveBoosts:FindFirstChild(boostName); if not flag then return end
	if flag.Value then return end
	flag.Value = true
	if boostName == "LowGravity" then LowGToggle:FireClient(p,true,dur) end
	task.delay(dur, function()
		if flag.Parent then flag.Value = false end
		if boostName == "LowGravity" then LowGToggle:FireClient(p,false,0) end
	end)
end

--------------------------------------------------------------------  LIGHTSPEED PASS
local function grantLightspeed(p)
	if not p:FindFirstChild("PermanentLightspeed") then
		local tag = Instance.new("BoolValue"); tag.Name="PermanentLightspeed"; tag.Parent=p
	end
	local d = DataAPI.Get(p) or {}
	d.Gamepasses            = d.Gamepasses or {}
	d.Gamepasses.Lightspeed = true
	d.OwnedCosmetics        = d.OwnedCosmetics or {}
	d.OwnedCosmetics.Trails = d.OwnedCosmetics.Trails or {}
	if not table.find(d.OwnedCosmetics.Trails,"Lightspeed Trail") then
		table.insert(d.OwnedCosmetics.Trails,"Lightspeed Trail")
	end
	DataAPI.Save(p)
end

--------------------------------------------------------------------  PUBLIC INTERFACE (used by ProductService)
_G.BoostService = {
	_grantGamePass = function(p, productId:int)
		if productId == PRODUCT.Lightspeed then grantLightspeed(p); return true end
		if productId == PRODUCT.LowGravity then applyTimed(p,"LowGravity",BOOSTS.LowGravity.Duration); return true end
		if productId == PRODUCT.DoubleCoins then applyTimed(p,"DoubleCoins",BOOSTS.DoubleCoins.Duration); return true end
	end,
}
