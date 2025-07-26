--------------------------------------------------------------------
-- CosmeticsService.lua
--  · Keeps server-side record of owned & equipped cosmetics
--  · Pushes trail colours to the client
--  · Grants “Lightspeed Trail” automatically to Lightspeed pass owners
--------------------------------------------------------------------
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataAPI      = require(game.ServerScriptService.PlayerDataManager)
local TrailColors  = require(ReplicatedStorage.Config.TrailColors)

--------------------------------------------------------------------  constants
local LIGHTSPEED_TRAIL = "Lightspeed Trail"

--------------------------------------------------------------------  remotes
local Rem = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder", ReplicatedStorage)
Rem.Name  = "Remotes"

local GetCosmetics    = Rem:FindFirstChild("GetCosmetics")    or Instance.new("RemoteFunction", Rem)
GetCosmetics.Name     = "GetCosmetics"

local EquipCosmetic   = Rem:FindFirstChild("EquipCosmetic")   or Instance.new("RemoteEvent",   Rem)
EquipCosmetic.Name    = "EquipCosmetic"

local UnequipCosmetic = Rem:FindFirstChild("UnequipCosmetic") or Instance.new("RemoteEvent",   Rem)
UnequipCosmetic.Name  = "UnequipCosmetic"

local SetTrailColor   = Rem:FindFirstChild("SetTrailColor")   or Instance.new("RemoteEvent",   Rem)
SetTrailColor.Name    = "SetTrailColor"

--------------------------------------------------------------------  helpers
local function ensure(tbl, key, default)
	if tbl[key] == nil then tbl[key] = default end
	return tbl[key]
end

local function pushColour(player, trailName)
	local seq = TrailColors[trailName or "Default"] or TrailColors.Default
	SetTrailColor:FireClient(player, seq)
end

--------------------------------------------------------------------  RPC: client asks for owned/equipped lists
GetCosmetics.OnServerInvoke = function(player)
	local data = DataAPI.Get(player) or {}

	----------------------------------------------------------------  unlock Lightspeed Trail if pass owned
	local ownsLS =    (data.Gamepasses and data.Gamepasses.Lightspeed)
		or player:FindFirstChild("PermanentLightspeed")
	if ownsLS then
		data.OwnedCosmetics         = ensure(data, "OwnedCosmetics",         {})
		data.OwnedCosmetics.Trails  = ensure(data.OwnedCosmetics, "Trails", {})
		if not table.find(data.OwnedCosmetics.Trails, LIGHTSPEED_TRAIL) then
			table.insert(data.OwnedCosmetics.Trails, LIGHTSPEED_TRAIL)
		end
	end

	return {
		OwnedCosmetics    = table.clone(data.OwnedCosmetics    or {}),
		EquippedCosmetics = table.clone(data.EquippedCosmetics or {}),
	}
end

--------------------------------------------------------------------  equip / unequip from UI
EquipCosmetic.OnServerEvent:Connect(function(player, tab, name)
	if tab ~= "Trails" then return end
	local data = DataAPI.Get(player); if not data then return end

	local owned = ensure(ensure(data,"OwnedCosmetics",{}), "Trails", {})
	for _,v in ipairs(owned) do
		if v == name then
			ensure(data,"EquippedCosmetics",{}).Trails = name
			DataAPI.Save(player)
			pushColour(player, name)
			EquipCosmetic:FireClient(player, tab, name)
			return
		end
	end
end)

UnequipCosmetic.OnServerEvent:Connect(function(player, tab)
	if tab ~= "Trails" then return end
	local data = DataAPI.Get(player); if not data then return end
	if data.EquippedCosmetics then data.EquippedCosmetics.Trails = nil end
	DataAPI.Save(player)
	pushColour(player, "Default")
	UnequipCosmetic:FireClient(player, tab)
end)

--------------------------------------------------------------------  apply colour each respawn
local function applyTrailOnSpawn(plr)
	local eq = (DataAPI.Get(plr).EquippedCosmetics or {}).Trails
	pushColour(plr, eq)
end

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function() applyTrailOnSpawn(plr) end)
end)
for _,pl in ipairs(Players:GetPlayers()) do
	if pl.Character then applyTrailOnSpawn(pl) end
end
