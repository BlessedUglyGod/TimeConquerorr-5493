--!strict
-- TD content pack: elements, armor chart and status effects used by Units/Enemies/Bosses.
-- The live Config already has Lightning/Fire/Ice and Flesh/Swift/Armored plus
-- Slow/Stun/Burn/ArmorBreak. Entries marked New = true need code support.

local Elements = {}

Elements.List = {
	"Lightning", "Fire", "Ice", -- existing
	"Water", "Wind", "Earth", "Nature", "Light", "Shadow", "Arcane", -- new
}

-- Damage multiplier: Chart[element][armor]. Missing entries = 1.0.
-- Armor types: Flesh, Swift, Armored (existing), Ethereal, Plated (new).
Elements.Chart = {
	Lightning = { Armored = 1.25, Ethereal = 0.8 },
	Fire = { Flesh = 1.25, Armored = 0.8 },
	Ice = { Swift = 1.25, Plated = 0.8 },
	Water = { Armored = 1.1, Plated = 0.9 },
	Wind = { Swift = 1.2, Armored = 0.75 },
	Earth = { Armored = 1.3, Swift = 0.8, Ethereal = 0.6 },
	Nature = { Flesh = 1.2, Plated = 0.8 },
	Light = { Ethereal = 1.4, Plated = 0.9 },
	Shadow = { Flesh = 1.15, Ethereal = 1.15, Plated = 0.85 },
	Arcane = {}, -- neutral against everything
}

-- Status effects. Strength meaning per effect is in Desc.
Elements.StatusEffects = {
	Slow = { Desc = "Speed multiplied by (1 - Strength). Strongest wins.", Stacking = "Strongest", BossResist = 0.5 },
	Stun = { Desc = "Cannot move.", Stacking = "Refresh", BossImmune = true },
	Burn = { Desc = "Strength damage per second.", Stacking = "Strongest", BossResist = 0 },
	ArmorBreak = { Desc = "Damage taken x(1 + Strength).", Stacking = "Strongest", BossResist = 0 },
	-- New
	Poison = { New = true, Desc = "Strength damage per second, stacks up to 3 sources, ignores armor chart.", Stacking = "Add", MaxStacks = 3, BossResist = 0 },
	Freeze = { New = true, Desc = "Like Stun but blue tint; the next hit on a frozen enemy deals +25%.", Stacking = "Refresh", BossImmune = true },
	Mark = { New = true, Desc = "Damage taken from all sources x(1 + Strength). Separate from ArmorBreak (they multiply).", Stacking = "Strongest", BossResist = 0 },
	Grounded = { New = true, Desc = "Flying enemy becomes targetable by ground-only units.", Stacking = "Refresh" },
}

-- Enemy states (set by enemy mechanics, cleared by some unit passives).
Elements.EnemyStates = {
	Shield = "Absorbs damage before HP (number). Removed by Purify.",
	Phased = "Untargetable and immune. Removed by Purify / RevealingLight.",
	Burrowed = "Untargetable, still moving. Removed by RevealingLight / Faultline.",
}

return Elements
