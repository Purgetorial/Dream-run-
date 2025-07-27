--------------------------------------------------------------------
-- TrailController.lua  ·  Attach Glow + Trails to all body parts
--                        Enable / disable via Remotes.TrailToggle
-- 02-Aug-25
--------------------------------------------------------------------
local Players           = game:GetService("Players")
local Rep               = game:GetService("ReplicatedStorage")

local ASSETS            = Rep:WaitForChild("RunFXAssets")
local Remotes           = Rep:WaitForChild("Remotes")

-----------------------  Prefab references  ------------------------
local PREFABS = {
	Glow       = ASSETS:WaitForChild("Glow"),        -- PointLight
	TrailInner = ASSETS:WaitForChild("TrailInner"),  -- Trail
	TrailOuter = ASSETS:WaitForChild("TrailOuter"),  -- Trail
}

-----------------------  Local state  -----------------------------
local player            = Players.LocalPlayer
local attachmentsDone   : Model? = nil   -- last character we wired
local trailEnabled      = false          -- current ON/OFF state

--------------------------------------------------------------------
-- Ensure each BasePart (except HumanoidRootPart) has attachments
-- and the three FX objects cloned and wired
--------------------------------------------------------------------
local function ensureAttachments(part: BasePart)
	local a0 = part:FindFirstChild("TrailAtt0")
	local a1 = part:FindFirstChild("TrailAtt1")
	if not a0 then
		a0 = Instance.new("Attachment")
		a0.Name, a0.Position, a0.Parent = "TrailAtt0", Vector3.new(0, 0.5, 0), part
	end
	if not a1 then
		a1 = Instance.new("Attachment")
		a1.Name, a1.Position, a1.Parent = "TrailAtt1", Vector3.new(0, -0.5, 0), part
	end
	return a0, a1
end

local function attachFX(part: BasePart)
	-- PointLight
	if not part:FindFirstChild("Glow") then
		local light       = PREFABS.Glow:Clone()
		light.Enabled     = false
		light.Parent      = part
	end
	-- Trails
	local a0, a1 = ensureAttachments(part)
	for name, prefab in pairs({ TrailInner = PREFABS.TrailInner, TrailOuter = PREFABS.TrailOuter }) do
		if not part:FindFirstChild(name) then
			local tr       = prefab:Clone()
			tr.Attachment0 = a0
			tr.Attachment1 = a1
			-- ?? BUG FIX: Trails were invisible because their Transparency was not set.
			-- This ensures they have a visible gradient when enabled.
			tr.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.75, 0.8),
				NumberSequenceKeypoint.new(1, 1)
			})
			tr.Enabled     = false
			tr.Parent      = part
		end
	end
end

local function ensureAllParts(char: Model)
	if attachmentsDone == char then return end
	for _, obj in ipairs(char:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
			task.spawn(attachFX, obj)
		end
	end
	attachmentsDone = char
end

--------------------------------------------------------------------
-- Toggle helper (called from remote)
--------------------------------------------------------------------
local function setEffects(char: Model, enabled: boolean)
	if trailEnabled == enabled then return end
	trailEnabled = enabled
	for _, obj in ipairs(char:GetDescendants()) do
		if obj:IsA("PointLight") and obj.Name == "Glow" then
			obj.Enabled = enabled
		elseif obj:IsA("Trail") and (obj.Name == "TrailInner" or obj.Name == "TrailOuter") then
			obj.Enabled = enabled
		end
	end
end

--------------------------------------------------------------------
-- Remote: TrailToggle (fired by RunFXController via server echo)
--------------------------------------------------------------------
local TrailToggle = Remotes:WaitForChild("TrailToggle")
TrailToggle.OnClientEvent:Connect(function(on)
	local char = player.Character
	if char then setEffects(char, on) end
end)

--------------------------------------------------------------------
-- Recolour support (unchanged)
--------------------------------------------------------------------
local function recolor(seq)
	for _, descendant in ipairs(player.Character:GetDescendants()) do
		if descendant:IsA("Trail") and (descendant.Name=="TrailInner" or descendant.Name=="TrailOuter") then
			descendant.Color = seq
		end
	end
end
Remotes.SetTrailColor.OnClientEvent:Connect(recolor)

--------------------------------------------------------------------
-- Character added – ensure attachments exist
--------------------------------------------------------------------
player.CharacterAdded:Connect(function(char)
	trailEnabled, attachmentsDone = false, nil
	ensureAllParts(char)
end)
if player.Character then ensureAllParts(player.Character) end