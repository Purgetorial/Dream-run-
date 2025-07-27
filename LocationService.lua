-- purgetorial/dream-run-/Dream-run--c6e19a1472899b0fe558b182fcfa5a80333cb4a1/LocationService.lua
-- LocationService.lua  |  shared helper for lobby / track spawn points
local Workspace = game:GetService("Workspace")

local LocationService = {}

-- NEW: Gets the CFrame for a specific stage's start pad
function LocationService.GetStartCFrame(stageNumber: number)
	local stagesFolder = Workspace:FindFirstChild("GeneratedStages")
	local stageModel = stagesFolder and stagesFolder:FindFirstChild("Stage" .. stageNumber)

	if not stageModel then
		warn("Could not find Stage", stageNumber)
		return CFrame.new(0, 3, 0) -- fallback somewhere safe
	end

	local startPad = stageModel:FindFirstChild("StartPad")
	return (startPad and startPad.CFrame or stageModel:GetPrimaryPartCFrame()) + Vector3.new(0, 4, 0)
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