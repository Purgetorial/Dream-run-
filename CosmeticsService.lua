--------------------------------------------------------------------
-- CosmeticsService.lua (Asynchronous Update)
-- • FIX: Replaced RemoteFunction with RemoteEvents to prevent UI freezing.
-- • The client now requests data and receives it asynchronously.
--------------------------------------------------------------------
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Service Modules
local DataAPI      = require(ServerScriptService.PlayerDataManager)

--------------------------------------------------------------------
-- Remotes
--------------------------------------------------------------------
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- IN: Client asks for its data
local RequestCosmetics  = Remotes:FindFirstChild("RequestCosmetics") or Instance.new("RemoteEvent", Remotes)
RequestCosmetics.Name   = "RequestCosmetics"

-- OUT: Server sends data back to the specific client
local ReceiveCosmetics  = Remotes:FindFirstChild("ReceiveCosmetics") or Instance.new("RemoteEvent", Remotes)
ReceiveCosmetics.Name   = "ReceiveCosmetics"

-- Other remotes handled by this service
local EquipCosmetic   = Remotes:WaitForChild("EquipCosmetic")
local UnequipCosmetic = Remotes:WaitForChild("UnequipCosmetic")
local SetTrailColor   = Remotes:WaitForChild("SetTrailColor")

--------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------
local function ensure(tbl, key, default)
	if tbl[key] == nil then tbl[key] = default end
	return tbl[key]
end

local function pushColor(player, trailName)
	local TrailColors = require(ReplicatedStorage.Config.TrailColors)
	local seq = TrailColors[trailName or "Default"] or TrailColors.Default
	SetTrailColor:FireClient(player, seq)
end

--------------------------------------------------------------------
-- Asynchronous Data Provider
--------------------------------------------------------------------
RequestCosmetics.OnServerEvent:Connect(function(player)
	local data = DataAPI.Get(player)
	if not data then return end

	-- Check for Lightspeed pass ownership
	local gamepasses = data.Gamepasses or {}
	if gamepasses.Lightspeed then
		local cosmetics = ensure(data, "OwnedCosmetics", {})
		local trails = ensure(cosmetics, "Trails", {})
		if not table.find(trails, "Lightspeed Trail") then
			table.insert(trails, "Lightspeed Trail")
			DataAPI.Set(player, "OwnedCosmetics", cosmetics) -- Mark for saving
		end
	end

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
		pushColor(player, name)
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

	pushColor(player, "Default")
	UnequipCosmetic:FireClient(player, tab)
end)

--------------------------------------------------------------------
-- Apply Color on Respawn
--------------------------------------------------------------------
local function applyTrailOnSpawn(player)
	local data = DataAPI.Get(player)
	if data and data.EquippedCosmetics then
		pushColor(player, data.EquippedCosmetics.Trails)
	end
end

Players.PlayerAdded:Connect(function(player)
	if player.Character then
		applyTrailOnSpawn(player)
	end
	player.CharacterAdded:Connect(function()
		applyTrailOnSpawn(player)
	end)
end)