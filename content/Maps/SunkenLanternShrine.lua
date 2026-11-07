--!strict
-- TD content pack v2: map 2 "Sunken Lantern Shrine" (concept + data).
-- Waves use the live format { enemyId, count, interval } plus optional Lane ("A"|"B"|"Both")
-- and Delay (s from wave start). Without lane support, run every group on lane A then Merged.

local Map = {}

Map.Id = "SunkenLanternShrine"
Map.Name = "Sunken Lantern Shrine"
Map.Theme = "Flooded hilltop shrine at dusk: shallow turquoise water, moss-covered stone steps, floating paper lanterns, cherry trees with violet petals, half-sunk torii gates."
Map.Size = Vector3.new(180, 1, 180)
Map.StartMoney = 350 -- live map 1 starts at 300; two lanes need a little more
Map.StartLives = 20
Map.MaxWaves = 15

-- Lane A (north portal) and lane B (west portal) merge at (0, 0, 20), then share Merged to the core.
Map.Lanes = {
	A = { Vector3.new(-70, 0, -80), Vector3.new(-70, 0, -40), Vector3.new(30, 0, -40), Vector3.new(30, 0, 0), Vector3.new(0, 0, 0), Vector3.new(0, 0, 20) },
	B = { Vector3.new(-85, 0, 60), Vector3.new(-40, 0, 60), Vector3.new(-40, 0, 20), Vector3.new(0, 0, 20) },
	Merged = { Vector3.new(0, 0, 20), Vector3.new(60, 0, 20), Vector3.new(60, 0, 70), Vector3.new(80, 0, 70) },
}

-- Water zones: only units with Placement = "Water" or "Any" may stand here (XZ rectangles).
Map.WaterZones = {
	{ Min = Vector3.new(-30, 0, -30), Max = Vector3.new(20, 0, -5) },
	{ Min = Vector3.new(10, 0, 30), Max = Vector3.new(50, 0, 60) },
}

-- Lantern pads on the torii bridge: +10% range, one unit each.
Map.Pads = {
	{ Position = Vector3.new(10, 3, 10), Bonus = { Stat = "Range", Mult = 1.1 } },
	{ Position = Vector3.new(-10, 3, 30), Bonus = { Stat = "Range", Mult = 1.1 } },
	{ Position = Vector3.new(50, 3, 30), Bonus = { Stat = "Range", Mult = 1.1 } },
}

Map.Waves = {
	{ { "Mudling", 10, 1, Lane = "A" } }, -- 1
	{ { "Mudling", 12, 0.8, Lane = "Both" }, { "SkitterMoth", 3, 1.5, Lane = "B", Delay = 6 } }, -- 2
	{ { "SplitterSlime", 4, 2.5, Lane = "A" }, { "Mudling", 8, 0.8, Lane = "B", Delay = 2 } }, -- 3
	{ { "Burrower", 6, 1.5, Lane = "Both" }, { "Shellback", 2, 4, Lane = "A", Delay = 5 } }, -- 4
	{ { "Wisp", 8, 1, Lane = "B" }, { "SkitterMoth", 6, 1, Lane = "A", Delay = 4 } }, -- 5
	{ { "Shellback", 4, 3, Lane = "Both" }, { "TotemBearer", 2, 4, Lane = "Both", Delay = 3 } }, -- 6
	{ { "ShieldDrummer", 2, 5, Lane = "A" }, { "SplitterSlime", 6, 1.5, Lane = "A", Delay = 1 }, { "Burrower", 6, 1, Lane = "B", Delay = 4 } }, -- 7
	{ { "GravemawTortoise", 1, 0, Lane = "A" }, { "Mudling", 15, 0.7, Lane = "B", Delay = 3 } }, -- 8
	{ { "HexLantern", 4, 3, Lane = "Both" }, { "Wisp", 10, 0.8, Lane = "Both", Delay = 2 } }, -- 9
	{ { "IronRhino", 3, 5, Lane = "A" }, { "TotemBearer", 3, 3, Lane = "B", Delay = 2 }, { "SkitterMoth", 10, 0.6, Lane = "Both", Delay = 6 } }, -- 10
	{ { "ShieldDrummer", 3, 4, Lane = "Both" }, { "Shellback", 6, 2, Lane = "Both", Delay = 2 }, { "Burrower", 8, 0.8, Lane = "A", Delay = 8 } }, -- 11
	{ { "VeilwitchNoxra", 1, 0, Lane = "B" }, { "HexLantern", 2, 6, Lane = "A", Delay = 6 } }, -- 12
	{ { "IronRhino", 5, 3, Lane = "Both" }, { "SplitterSlime", 8, 1, Lane = "Both", Delay = 3 }, { "Wisp", 12, 0.6, Lane = "Both", Delay = 6 } }, -- 13
	{ { "ShieldDrummer", 4, 3, Lane = "Both" }, { "TotemBearer", 4, 3, Lane = "Both", Delay = 1 }, { "IronRhino", 4, 3, Lane = "Both", Delay = 4 }, { "HexLantern", 4, 3, Lane = "Both", Delay = 8 } }, -- 14
	{ { "HourlessShogun", 1, 0, Lane = "A" }, { "Shellback", 4, 4, Lane = "B", Delay = 4 }, { "SkitterMoth", 12, 0.8, Lane = "Both", Delay = 10 } }, -- 15
}

return Map
