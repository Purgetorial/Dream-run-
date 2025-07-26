--------------------------------------------------------------------
-- TrailColors.lua  ·  ColorSequence presets for every cosmetic trail
--------------------------------------------------------------------
return {

	----------------------------------------------------------------
	--  Default (no trail equipped)
	----------------------------------------------------------------
	Default = ColorSequence.new{
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,255,255)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,255,255)),
	},

	----------------------------------------------------------------
	--  Rainbow Trail
	----------------------------------------------------------------
	["Rainbow Trail"] = ColorSequence.new{
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,  0,  0)),
		ColorSequenceKeypoint.new(0.20, Color3.fromRGB(255,127,  0)),
		ColorSequenceKeypoint.new(0.40, Color3.fromRGB(255,255,  0)),
		ColorSequenceKeypoint.new(0.60, Color3.fromRGB(  0,255,  0)),
		ColorSequenceKeypoint.new(0.80, Color3.fromRGB(  0,  0,255)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(139,  0,255)),
	},

	----------------------------------------------------------------
	--  Golden Trail
	----------------------------------------------------------------
	["Golden Trail"] = ColorSequence.new{
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,203,  0)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,140,  0)),
	},

	----------------------------------------------------------------
	--  Lightspeed Trail  (NEW)  – deep red core, faint orange edge
	----------------------------------------------------------------
	["Lightspeed Trail"] = ColorSequence.new{
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 40, 40)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,140, 40)),
	},
}
