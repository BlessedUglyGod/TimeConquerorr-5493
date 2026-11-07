--!strict
-- TD content pack: second map concept "Sunken Lantern Shrine" (draft v1).
-- Same coordinate convention as Config.Waypoints on map 1 (axis-aligned segments, Y = ground).
-- Two lanes start at separate portals and merge at the Torii bridge before the core.

local Map = {}

Map.Id = "SunkenLanternShrine"
Map.Name = "Sunken Lantern Shrine"
Map.Theme = "Flooded hilltop shrine at dusk: shallow turquoise water, moss-covered stone steps, floating paper lanterns, cherry trees with violet petals, half-sunk torii gates."
Map.Size = Vector3.new(180, 1, 180)
Map.StartMoney = 650
Map.StartLives = 20
Map.MaxWaves = 15

-- Lane A (north portal) and lane B (west portal) merge at (0, 0, 20).
Map.Lanes = {
	A = {
		Vector3.new(-70, 0, -80),
		Vector3.new(-70, 0, -40),
		Vector3.new(30, 0, -40),
		Vector3.new(30, 0, 0),
		Vector3.new(0, 0, 0),
		Vector3.new(0, 0, 20),
	},
	B = {
		Vector3.new(-85, 0, 60),
		Vector3.new(-40, 0, 60),
		Vector3.new(-40, 0, 20),
		Vector3.new(0, 0, 20),
	},
	Merged = { -- shared tail from the merge point to the core
		Vector3.new(0, 0, 20),
		Vector3.new(60, 0, 20),
		Vector3.new(60, 0, 70),
		Vector3.new(80, 0, 70),
	},
}

-- Water zones: only units with Placement = "Water" or "Any" can stand here.
-- Rectangles as { Min = Vector3, Max = Vector3 } on the XZ plane.
Map.WaterZones = {
	{ Min = Vector3.new(-30, 0, -30), Max = Vector3.new(20, 0, -5) }, -- inner pond inside lane A's loop
	{ Min = Vector3.new(10, 0, 30), Max = Vector3.new(50, 0, 60) }, -- lotus pond by the merged lane
}

-- Special terrain feature: "Lantern Bridges". Placement pads on the torii bridge
-- with +10% range for any unit (high ground). Max 1 unit per pad.
Map.Pads = {
	{ Position = Vector3.new(10, 3, 10), Bonus = { Stat = "Range", Mult = 1.1 } },
	{ Position = Vector3.new(-10, 3, 30), Bonus = { Stat = "Range", Mult = 1.1 } },
	{ Position = Vector3.new(50, 3, 30), Bonus = { Stat = "Range", Mult = 1.1 } },
}

-- Waves: each entry is a list of groups { Enemy, Count, Interval (s), Delay (s from wave start), Lane }.
-- Lane = "A" | "B" | "Both" (Both = alternate). Bosses use ids from Bosses.lua.
Map.Waves = {
	{ { Enemy = "Mudling", Count = 10, Interval = 1.0, Delay = 0, Lane = "A" } },
	{ { Enemy = "Mudling", Count = 12, Interval = 0.8, Delay = 0, Lane = "Both" }, { Enemy = "SkitterMoth", Count = 3, Interval = 1.5, Delay = 6, Lane = "B" } },
	{ { Enemy = "SplitterSlime", Count = 4, Interval = 2.5, Delay = 0, Lane = "A" }, { Enemy = "Mudling", Count = 8, Interval = 0.8, Delay = 2, Lane = "B" } },
	{ { Enemy = "Burrower", Count = 6, Interval = 1.5, Delay = 0, Lane = "Both" }, { Enemy = "Shellback", Count = 2, Interval = 4, Delay = 5, Lane = "A" } },
	{ { Enemy = "Wisp", Count = 8, Interval = 1.0, Delay = 0, Lane = "B" }, { Enemy = "SkitterMoth", Count = 6, Interval = 1.0, Delay = 4, Lane = "A" } },
	{ { Enemy = "Shellback", Count = 4, Interval = 3, Delay = 0, Lane = "Both" }, { Enemy = "TotemBearer", Count = 2, Interval = 4, Delay = 3, Lane = "Both" } },
	{ { Enemy = "ShieldDrummer", Count = 2, Interval = 5, Delay = 0, Lane = "A" }, { Enemy = "SplitterSlime", Count = 6, Interval = 1.5, Delay = 1, Lane = "A" }, { Enemy = "Burrower", Count = 6, Interval = 1, Delay = 4, Lane = "B" } },
	{ { Enemy = "GravemawTortoise", Count = 1, Interval = 0, Delay = 0, Lane = "A" }, { Enemy = "Mudling", Count = 15, Interval = 0.7, Delay = 3, Lane = "B" } },
	{ { Enemy = "HexLantern", Count = 4, Interval = 3, Delay = 0, Lane = "Both" }, { Enemy = "Wisp", Count = 10, Interval = 0.8, Delay = 2, Lane = "Both" } },
	{ { Enemy = "IronRhino", Count = 3, Interval = 5, Delay = 0, Lane = "A" }, { Enemy = "TotemBearer", Count = 3, Interval = 3, Delay = 2, Lane = "B" }, { Enemy = "SkitterMoth", Count = 10, Interval = 0.6, Delay = 6, Lane = "Both" } },
	{ { Enemy = "ShieldDrummer", Count = 3, Interval = 4, Delay = 0, Lane = "Both" }, { Enemy = "Shellback", Count = 6, Interval = 2, Delay = 2, Lane = "Both" }, { Enemy = "Burrower", Count = 8, Interval = 0.8, Delay = 8, Lane = "A" } },
	{ { Enemy = "VeilwitchNoxra", Count = 1, Interval = 0, Delay = 0, Lane = "B" }, { Enemy = "HexLantern", Count = 2, Interval = 6, Delay = 6, Lane = "A" } },
	{ { Enemy = "IronRhino", Count = 5, Interval = 3, Delay = 0, Lane = "Both" }, { Enemy = "SplitterSlime", Count = 8, Interval = 1, Delay = 3, Lane = "Both" }, { Enemy = "Wisp", Count = 12, Interval = 0.6, Delay = 6, Lane = "Both" } },
	{ { Enemy = "ShieldDrummer", Count = 4, Interval = 3, Delay = 0, Lane = "Both" }, { Enemy = "TotemBearer", Count = 4, Interval = 3, Delay = 1, Lane = "Both" }, { Enemy = "IronRhino", Count = 4, Interval = 3, Delay = 4, Lane = "Both" }, { Enemy = "HexLantern", Count = 4, Interval = 3, Delay = 8, Lane = "Both" } },
	{ { Enemy = "HollowShogun", Count = 1, Interval = 0, Delay = 0, Lane = "A" }, { Enemy = "Shellback", Count = 4, Interval = 4, Delay = 4, Lane = "B" }, { Enemy = "SkitterMoth", Count = 12, Interval = 0.8, Delay = 10, Lane = "Both" } },
}

return Map
