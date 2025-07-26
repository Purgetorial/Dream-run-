--------------------------------------------------------------------
-- LowGravityController.lua  |  per-player fake “low gravity”
--------------------------------------------------------------------
local RS        = game:GetService("RunService")
local Rep       = game:GetService("ReplicatedStorage")
local player    = game.Players.LocalPlayer
local camera    = workspace.CurrentCamera

local ToggleEv  = Rep.Remotes.ToggleLowGravity
local FORCE_MULT= 0.6          -- 60 % gravity removed

local function addForce(dur)
	local root = player.Character and player.Character:WaitForChild("HumanoidRootPart")
	if not root then return end
	local gv = FORCE_MULT * workspace.Gravity * root.AssemblyMass
	local vf = Instance.new("VectorForce")
	vf.Force  = Vector3.new(0, gv, 0)
	vf.ApplyAtCenterOfMass = true
	vf.Attachment0 = Instance.new("Attachment", root)
	vf.Parent = root
	RS.Heartbeat:Wait()  -- ensure physics update
	task.delay(dur or 120, function() vf:Destroy() end)
end

ToggleEv.OnClientEvent:Connect(function(enable, dur)
	if enable then addForce(dur) end
end)
