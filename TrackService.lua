-- TrackService.lua  |  builds + pools the DreamRun track
--------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage     = game:GetService("ServerStorage")
local Workspace         = game:GetService("Workspace")
local Players           = game:GetService("Players")

-- ??  import map constants so one file controls length
local CoinCfg = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("CoinConfig"))
local NUM_SEGMENTS   = CoinCfg.NUM_SEGMENTS
local SEGMENT_LENGTH = CoinCfg.SEGMENT_LENGTH

local TEMPLATE_FOLDER      = ReplicatedStorage
local SEGMENT_TEMPLATE     = TEMPLATE_FOLDER:WaitForChild("RunnerSegmentTemplate")
local START_PAD_TEMPLATE   = TEMPLATE_FOLDER:WaitForChild("StartPadTemplate")
local FINISH_PAD_TEMPLATE  = TEMPLATE_FOLDER:WaitForChild("FinishPadTemplate")

--------------------------------------------------------------------
-- REMOTES
--------------------------------------------------------------------
local Remotes         = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
Remotes.Name          = "Remotes"
local TrackSeedRemote = Remotes:FindFirstChild("TrackSeed") or Instance.new("RemoteEvent", Remotes)
TrackSeedRemote.Name  = "TrackSeed"

--------------------------------------------------------------------
-- POOL & GENERATED FOLDERS
--------------------------------------------------------------------
local POOL_FOLDER  = ServerStorage:FindFirstChild("SegmentPool") or Instance.new("Folder", ServerStorage)
POOL_FOLDER.Name   = "SegmentPool"

local GENERATED    = Workspace:FindFirstChild("GeneratedDreamRun") or Instance.new("Folder", Workspace)
GENERATED.Name     = "GeneratedDreamRun"

--------------------------------------------------------------------
-- RANDOM SEED
--------------------------------------------------------------------
local RANDOM_SEED = math.random(1, 1e7)
math.randomseed(RANDOM_SEED)

--------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------
local function getPooledSegment()
	local seg = POOL_FOLDER:FindFirstChildWhichIsA("BasePart") or POOL_FOLDER:FindFirstChildOfClass("Model")
	if seg then seg.Parent = nil; return seg end
	return SEGMENT_TEMPLATE:Clone()
end

local function poolSegment(seg) seg.Parent = POOL_FOLDER end

--------------------------------------------------------------------
-- BUILD TRACK
--------------------------------------------------------------------
local function clearPrevious()
	for _, obj in ipairs(GENERATED:GetChildren()) do
		poolSegment(obj)
	end
end

local function placeStartPad()
	local pad = START_PAD_TEMPLATE:Clone(); pad.Name = "StartPad"; pad.Parent = GENERATED
	local part = pad:IsA("Model") and pad.PrimaryPart or pad
	if part then part.CFrame = CFrame.new(0, 3, 5) end
end

local function placeSegments()
	for i = 1, NUM_SEGMENTS do
		local seg = getPooledSegment()
		seg.Name  = ("Segment_%d"):format(i)
		seg.Parent= GENERATED
		local z   = -(i-1) * SEGMENT_LENGTH
		local part= seg:IsA("Model") and seg.PrimaryPart or seg
		if part then part.CFrame = CFrame.new(0, 0, z) end
	end
end

local function placeFinishPad()
	local lastSeg = GENERATED:FindFirstChild(("Segment_%d"):format(NUM_SEGMENTS))
	if not lastSeg then return end

	local segPart = lastSeg:IsA("Model") and lastSeg.PrimaryPart or lastSeg
	if not segPart then return end

	-- y-position sits just above the final segment
	local padY = segPart.Position.Y + segPart.Size.Y/2 + 0.1

	local pad = FINISH_PAD_TEMPLATE:Clone()
	pad.Name  = "FinishPad"
	pad.Parent= GENERATED

	if pad:IsA("Model") and pad.PrimaryPart then
		pad:SetPrimaryPartCFrame(CFrame.new(0, padY, segPart.Position.Z))
	else
		-- pad is a single Part
		pad.CFrame = CFrame.new(0, padY, segPart.Position.Z)
	end
end

local function buildTrack()
	clearPrevious()
	placeStartPad()
	placeSegments()
	placeFinishPad()
end

--------------------------------------------------------------------
-- BOOTSTRAP & PLAYER SEED
--------------------------------------------------------------------
buildTrack()
Players.PlayerAdded:Connect(function(plr) TrackSeedRemote:FireClient(plr, RANDOM_SEED) end)

_G.TrackService = {
	Regenerate = buildTrack,
	RandomSeed = RANDOM_SEED,
}
