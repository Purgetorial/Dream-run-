-- TeleportToStartHandler.lua
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local LocationService    = require(ReplicatedStorage:WaitForChild("LocationService"))

local TeleportToStart = ReplicatedStorage:WaitForChild("TeleportToStart")
local TeleportToLobby = ReplicatedStorage:WaitForChild("TeleportToLobby")
local player          = Players.LocalPlayer

TeleportToStart.OnClientEvent:Connect(function()
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.CFrame = LocationService.GetStartCFrame()
	end
end)

TeleportToLobby.OnClientEvent:Connect(function()
	local char = player.Character or player.CharacterAdded:Wait()
	local hrp  = char:WaitForChild("HumanoidRootPart", 5)
	if hrp then
		hrp.CFrame = LocationService.GetLobbyCFrame()
	end
end)
