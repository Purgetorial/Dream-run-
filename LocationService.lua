-- LocationService.lua  |  shared helper for lobby / track spawn points
local Workspace = game:GetService("Workspace")

local LocationService = {}

-- Pad is automatically rebuilt by TrackService, so just read it live
function LocationService.GetStartCFrame()
	local folder = Workspace:FindFirstChild("GeneratedDreamRun")
	local pad    = folder and folder:FindFirstChild("StartPad")
	if not pad then
		return CFrame.new(0,3,0) -- fallback somewhere safe
	end
	local part = pad:IsA("Model") and pad.PrimaryPart or pad
	return (part and part.CFrame or CFrame.new(0,3,0)) + Vector3.new(0,3,0)
end

-- Looks for Lobby/Spawn, otherwise any base-part in Lobby
function LocationService.GetLobbyCFrame()
	local lobby = Workspace:FindFirstChild("Lobby")
	if lobby then
		local spawn = lobby:FindFirstChild("Spawn") or lobby:FindFirstChildWhichIsA("BasePart")
		if spawn then
			return spawn.CFrame + Vector3.new(0,3,0)
		end
	end
	return CFrame.new(0,3,100) -- last-ditch fallback
end

return LocationService
