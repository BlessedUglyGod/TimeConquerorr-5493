--!strict
-- TD content pack: 10 regular enemies (draft v1).
-- Target: merge into ReplicatedStorage.TD.Config.Enemies.
--
-- Schema (draft):
--   Id, Name       string
--   Hp             number  base HP (live server scales +12%/wave on top)
--   Speed          number  studs per second
--   Reward         number  money on kill
--   Damage         number  lives lost on leak
--   Armor          string  Flesh | Swift | Armored | Ethereal | Plated (see Elements.Chart)
--   Flying         boolean only CanHitAir units target it (unless Grounded)
--   CCResist       number  0..1, reduces Slow strength and Stun/Freeze duration
--   Mechanics      {Mechanic}? data-driven behaviours, each { Id = string, ...params }
--   Look           string  model-generation prompt
-- Reference: existing Crawler/Dasher/Brute sit around Hp 30/20/120.

local Enemies = {}

Enemies.Mudling = {
	Id = "Mudling", Name = "Mudling",
	Hp = 28, Speed = 7, Reward = 4, Damage = 1, Armor = "Flesh", Flying = false, CCResist = 0,
	Look = "Small round blob of wet mud with two pebble eyes and a leaf sprout on top, waddling",
}

Enemies.SkitterMoth = {
	Id = "SkitterMoth", Name = "Skitter Moth",
	Hp = 22, Speed = 11, Reward = 6, Damage = 1, Armor = "Swift", Flying = true, CCResist = 0,
	Look = "Dusty grey moth the size of a cat with glowing violet eye-spots on the wings, fluttering erratically",
}

Enemies.Shellback = {
	Id = "Shellback", Name = "Shellback",
	Hp = 180, Speed = 3.5, Reward = 14, Damage = 3, Armor = "Plated", Flying = false, CCResist = 0.2,
	Look = "Squat beetle-crab with a thick bronze dome shell covered in rivets, tiny legs, steam vents on the back",
}

Enemies.Wisp = {
	Id = "Wisp", Name = "Drift Wisp",
	Hp = 45, Speed = 8, Reward = 8, Damage = 1, Armor = "Ethereal", Flying = true, CCResist = 0,
	Mechanics = { { Id = "Phase", Every = 5, Duration = 1 } },
	Look = "Floating teardrop of pale cyan flame with a small smiling mask, trailing sparkles",
}

Enemies.SplitterSlime = {
	Id = "SplitterSlime", Name = "Splitter Slime",
	Hp = 90, Speed = 5, Reward = 6, Damage = 2, Armor = "Flesh", Flying = false, CCResist = 0,
	Mechanics = { { Id = "SplitOnDeath", Spawn = "Mudling", Count = 3 } },
	Look = "Jiggly lime-green slime cube with three Mudling silhouettes visible inside",
}

Enemies.TotemBearer = {
	Id = "TotemBearer", Name = "Totem Bearer",
	Hp = 140, Speed = 4.5, Reward = 16, Damage = 2, Armor = "Armored", Flying = false, CCResist = 0.1,
	Mechanics = { { Id = "HealAura", Radius = 10, Every = 3, HealPct = 0.06 } },
	Look = "Hunched goblin-like spirit in a straw cloak carrying a tall carved wooden totem with a green glowing face",
}

Enemies.ShieldDrummer = {
	Id = "ShieldDrummer", Name = "Shield Drummer",
	Hp = 120, Speed = 4.5, Reward = 16, Damage = 2, Armor = "Armored", Flying = false, CCResist = 0.1,
	Mechanics = { { Id = "ShieldAura", Radius = 10, Every = 6, ShieldPctOfMaxHp = 0.25 } },
	Look = "Round armoured imp beating a large taiko drum strapped to its belly, blue hexagon sigils pulsing from the drum",
}

Enemies.Burrower = {
	Id = "Burrower", Name = "Burrower",
	Hp = 70, Speed = 9, Reward = 10, Damage = 2, Armor = "Swift", Flying = false, CCResist = 0,
	Mechanics = { { Id = "Burrow", Every = 6, Duration = 2 } },
	Look = "Mole-like creature with drill-shaped claws and a mining helmet lamp, sandy fur",
}

Enemies.HexLantern = {
	Id = "HexLantern", Name = "Hex Lantern",
	Hp = 95, Speed = 5.5, Reward = 18, Damage = 2, Armor = "Ethereal", Flying = true, CCResist = 0.3,
	Mechanics = { { Id = "DisableUnit", Every = 7, Range = 12, Duration = 2 } },
	Look = "Haunted paper lantern with a single purple eye and a long tongue, chains dangling below, floating",
}

Enemies.IronRhino = {
	Id = "IronRhino", Name = "Iron Rhino",
	Hp = 320, Speed = 4, Reward = 30, Damage = 5, Armor = "Plated", Flying = false, CCResist = 0.5,
	Mechanics = { { Id = "ChargeBelowHp", HpPct = 0.5, SpeedMult = 2.0, Duration = 3 } },
	Look = "Bulky rhino beast wearing samurai-style iron plates, a single huge horn of steel, glowing red eyes",
}

return Enemies
