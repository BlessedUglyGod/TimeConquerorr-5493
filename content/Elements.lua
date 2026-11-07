--!strict
-- TD content pack v2: element chart rows/columns and new status effects, live schema.
-- Merge:
--   for el, row in Elements.ElementChart do
--       Config.ElementChart[el] = Config.ElementChart[el] or {}
--       for armor, mul in row do Config.ElementChart[el][armor] = mul end
--   end
--   for id, def in Elements.Statuses do Config.Statuses[id] = def end  -- (or whatever the live table is named)
-- Live statuses already cover Slow, Stun, Burn, ArmorBreak; units here use them with live conventions.

local Elements = {}

-- ElementChart[element][armor] = damage multiplier, missing = 1.
-- New elements: Water, Wind, Earth, Nature, Light, Shadow, Arcane.
-- New armors: Ethereal (spirits), Plated (heavy shells). Existing rows get the two new columns.
Elements.ElementChart = {
	Lightning = { Ethereal = 0.8 },
	Fire = { Plated = 0.85 },
	Ice = { Plated = 0.8 },
	Water = { Armored = 1.1, Plated = 0.9 },
	Wind = { Swift = 1.2, Armored = 0.75 },
	Earth = { Armored = 1.3, Swift = 0.8, Ethereal = 0.6 },
	Nature = { Flesh = 1.2, Plated = 0.8 },
	Light = { Ethereal = 1.4, Plated = 0.9 },
	Shadow = { Flesh = 1.15, Ethereal = 1.15, Plated = 0.85 },
	Arcane = {}, -- neutral against everything
}

-- New statuses, same fields as the live ones.
Elements.Statuses = {
	Poison = {
		Name = "Poison", Kind = "DoT", Stacking = "Strongest", TickInterval = 0.5,
		Tint = Color3.fromRGB(150, 220, 70),
		-- strength = damage per second (on the live HP scale)
	},
	Freeze = {
		Name = "Freeze", Kind = "Stop", Stacking = "Refresh", CC = true, BossImmunityAfter = 2,
		Tint = Color3.fromRGB(150, 210, 255),
		-- like Stun with an ice tint; design note: next hit on a frozen enemy +25% (optional)
	},
	Mark = {
		Name = "Mark", Kind = "DamageTakenMul", Stacking = "Strongest",
		Tint = Color3.fromRGB(180, 120, 255),
		-- strength = damage-taken multiplier (1.2 = +20%); multiplies with ArmorBreak
	},
}

-- Enemy states used by enemy mechanics and unit passives (need code, not statuses):
--   Shield   = number absorbed before Health. Removed by Passive "Purify".
--   Phased   = untargetable and immune. Removed by "Purify" / "RevealingLight".
--   Burrowed = untargetable, still moving. Removed by "RevealingLight" / ability "Faultline".
--   Grounded = Flying enemy becomes targetable by CanHitAir = false units (InfernoDive).

return Elements
