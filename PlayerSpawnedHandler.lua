-- PlayerSpawnedHandler.lua  |  spawns players in the lobby & handles fall reset
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local LocationService    = require(ReplicatedStorage:WaitForChild("LocationService"))

local ServerResetRunTimer = ReplicatedStorage:WaitForChild("ServerResetRunTimer")
local TeleportToLobby     = ReplicatedStorage:WaitForChild("TeleportToLobby")
local TeleportToStart     = ReplicatedStorage:WaitForChild("TeleportToStart")
local OpenMainMenu        = ReplicatedStorage:WaitForChild("OpenMainMenu")

local RESPAWN_Y = -20      -- Y-level that counts as “fallen”

--------------------------------------------------------------------
--  Player join / respawn
--------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local hrp = character:WaitForChild("HumanoidRootPart", 5)
		if not hrp then return end

		-- ??  ONE authoritative lobby position
		hrp.CFrame = LocationService.GetLobbyCFrame()
		ServerResetRunTimer:Fire(player)
		OpenMainMenu:FireClient(player)

		----------------------------------------------------------------
		--  Fall-detection loop – teleport back to StartPad
		----------------------------------------------------------------
		task.spawn(function()
			while character.Parent and player.Parent == Players do
				if hrp.Position.Y < RESPAWN_Y then
					TeleportToStart:FireClient(player)
					repeat task.wait(0.2) until
					not (character.Parent
						and player.Parent == Players
						and hrp.Position.Y < RESPAWN_Y)
				end
				task.wait(0.2)
			end
		end)
	end)
end)
