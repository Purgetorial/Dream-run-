-- purgetorial/dream-run-/Dream-run--c6e19a1472899b0fe558b182fcfa5a80333cb4a1/CosmeticsService.lua
--------------------------------------------------------------------
-- CosmeticsService.lua (Server-Side Trails)
-- • Manages trail creation, coloring, and visibility for all players.
-- • Trails are now replicated, so everyone can see them.
--------------------------------------------------------------------
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Service Modules
local DataAPI      = require(ServerScriptService.PlayerDataManager)
local TrailColors  = require(ReplicatedStorage.Config.TrailColors)

--------------------------------------------------------------------
-- Remotes
--------------------------------------------------------------------
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestCosmetics  = Remotes:WaitForChild("RequestCosmetics")
local ReceiveCosmetics  = Remotes:WaitForChild("ReceiveCosmetics")
local EquipCosmetic     = Remotes:WaitForChild("EquipCosmetic")
local UnequipCosmetic   = Remotes:WaitForChild("UnequipCosmetic")
-- The server will now control TrailToggle directly
local TrailToggle       = Remotes:WaitForChild("TrailToggle")

--------------------------------------------------------------------
-- Trail Management
--------------------------------------------------------------------
local TRAIL_PREFABS = {
	Glow       = ReplicatedStorage.RunFXAssets:WaitForChild("Glow"),
	TrailInner = ReplicatedStorage.RunFXAssets:WaitForChild("TrailInner"),
	TrailOuter = ReplicatedStorage.RunFXAssets:WaitForChild("TrailOuter"),
}
local activeTrails = {} -- [player.UserId] = {table of trail instances}

local function ensureAttachments(part: BasePart)
	local a0 = part:FindFirstChild("TrailAtt0") or Instance.new("Attachment", part)
	a0.Name, a0.Position = "TrailAtt0", Vector3.new(0, 0.5, 0)
	local a1 = part:FindFirstChild("TrailAtt1") or Instance.new("Attachment", part)
	a1.Name, a1.Position = "TrailAtt1", Vector3.new(0, -0.5, 0)
	return a0, a1
end

local function createTrailsForCharacter(char: Model)
	local plr = Players:GetPlayerFromCharacter(char)
	if not plr then return {} end

	local trailInstances = {}
	for _, part in ipairs(char:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			local a0, a1 = ensureAttachments(part)

			local trailInner = TRAIL_PREFABS.TrailInner:Clone()
			trailInner.Attachment0, trailInner.Attachment1 = a0, a1
			trailInner.Enabled = false
			trailInner.Parent = part
			table.insert(trailInstances, trailInner)

			local trailOuter = TRAIL_PREFABS.TrailOuter:Clone()
			trailOuter.Attachment0, trailOuter.Attachment1 = a0, a1
			trailOuter.Enabled = false
			trailOuter.Parent = part
			table.insert(trailInstances, trailOuter)
		end
	end
	return trailInstances
end

local function destroyTrailsForPlayer(player)
	local userId = player.UserId
	if activeTrails[userId] then
		for _, trail in ipairs(activeTrails[userId]) do
			if trail and trail.Parent then
				trail:Destroy()
			end
		end
		activeTrails[userId] = nil
	end
end

local function setTrailColor(player, trailName: string)
	local trailList = activeTrails[player.UserId]
	if not trailList then return end

	local colorSequence = TrailColors[trailName] or TrailColors.Default
	for _, trailInstance in ipairs(trailList) do
		if trailInstance and trailInstance:IsA("Trail") then
			trailInstance.Color = colorSequence
		end
	end
end

-- The server now listens to the toggle event it receives from RunService
TrailToggle.OnServerEvent:Connect(function(player, enabled: boolean)
	local trailList = activeTrails[player.UserId]
	if not trailList then return end

	for _, trailInstance in ipairs(trailList) do
		if trailInstance and trailInstance.Parent then
			trailInstance.Enabled = enabled
		end
	end
end)


--------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------
local function ensure(tbl, key, default)
	if tbl[key] == nil then tbl[key] = default end
	return tbl[key]
end

--------------------------------------------------------------------
-- Asynchronous Data Provider
--------------------------------------------------------------------
RequestCosmetics.OnServerEvent:Connect(function(player)
	local data = DataAPI.Get(player)
	if not data then return end

	-- Fire the data back to the requesting client
	ReceiveCosmetics:FireClient(player, {
		OwnedCosmetics    = data.OwnedCosmetics or {},
		EquippedCosmetics = data.EquippedCosmetics or {},
	})
end)

--------------------------------------------------------------------
-- Equip / Unequip Logic
--------------------------------------------------------------------
EquipCosmetic.OnServerEvent:Connect(function(player, tab, name)
	if tab ~= "Trails" then return end
	local data = DataAPI.Get(player)
	if not data then return end

	local owned = ensure(ensure(data, "OwnedCosmetics", {}), "Trails", {})
	if table.find(owned, name) then
		ensure(data, "EquippedCosmetics", {}).Trails = name
		DataAPI.Set(player, "EquippedCosmetics", data.EquippedCosmetics) -- Mark for saving
		setTrailColor(player, name)
		EquipCosmetic:FireClient(player, tab, name) -- Echo back for confirmation
	end
end)

UnequipCosmetic.OnServerEvent:Connect(function(player, tab)
	if tab ~= "Trails" then return end
	local data = DataAPI.Get(player)
	if not data then return end

	if data.EquippedCosmetics then
		data.EquippedCosmetics.Trails = nil
		DataAPI.Set(player, "EquippedCosmetics", data.EquippedCosmetics) -- Mark for saving
	end

	setTrailColor(player, "Default")
	UnequipCosmetic:FireClient(player, tab)
end)

--------------------------------------------------------------------
-- Apply and manage trails on spawn
--------------------------------------------------------------------
local function onCharacterAdded(player, character)
	-- Clean up old trails first
	destroyTrailsForPlayer(player)

	-- Create new trails and store them
	activeTrails[player.UserId] = createTrailsForCharacter(character)

	-- Apply the correct color based on saved data
	local data = DataAPI.Get(player)
	local equippedTrail = data and data.EquippedCosmetics and data.EquippedCosmetics.Trails
	setTrailColor(player, equippedTrail or "Default")
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
end)

Players.PlayerRemoving:Connect(destroyTrailsForPlayer)