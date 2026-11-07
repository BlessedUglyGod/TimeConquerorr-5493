--!strict
-- TD content pack v2: 10 enemies + 3 bosses in the live Config.Enemies schema.
-- Merge: for id, def in Enemies do Config.Enemies[id] = def end
-- Live fields: Name, Health, Speed, Reward, Damage, Size, Color, Shape, Armor, CCResist, Boss, Enrage.
-- Scale: Mudling = Crawler (70 HP); bosses ~3.6k-8.4k vs live boss 4200. Health is base, before +21%/wave.
-- Not read by the live server yet: Flying, Title, Mechanics (handlers keyed by Id), Phases
-- (each fires once when Health drops below AtHealth), Counter (design note).
-- Armor "Ethereal" and "Plated" are new: add their columns to Config.ElementChart (see Elements.lua).

local Enemies = {}

Enemies.Mudling = {
	Name = "Mudling",
	Health = 70,
	Speed = 7,
	Reward = 2,
	Damage = 1,
	Size = 2,
	Color = Color3.fromRGB(110, 80, 50),
	Shape = "Ball",
	Armor = "Flesh",
	CCResist = 0,
	Look = "Small round blob of wet mud with two pebble eyes and a leaf sprout on top, waddling",
}

Enemies.SkitterMoth = {
	Name = "Skitter Moth",
	Health = 55,
	Speed = 11,
	Reward = 3,
	Damage = 1,
	Size = 2,
	Color = Color3.fromRGB(150, 140, 160),
	Shape = "Ball",
	Armor = "Swift",
	CCResist = 0,
	Flying = true,
	Look = "Dusty grey moth the size of a cat with glowing violet eye-spots on the wings, fluttering erratically",
}

Enemies.Shellback = {
	Name = "Shellback",
	Health = 450,
	Speed = 3.5,
	Reward = 7,
	Damage = 3,
	Size = 4,
	Color = Color3.fromRGB(170, 120, 60),
	Shape = "Ball",
	Armor = "Plated",
	CCResist = 0.2,
	Look = "Squat beetle-crab with a thick bronze dome shell covered in rivets, tiny legs, steam vents on the back",
}

Enemies.Wisp = {
	Name = "Drift Wisp",
	Health = 110,
	Speed = 8,
	Reward = 4,
	Damage = 1,
	Size = 2,
	Color = Color3.fromRGB(150, 230, 240),
	Shape = "Ball",
	Armor = "Ethereal",
	CCResist = 0,
	Flying = true,
	Mechanics = { { Id = "Phase", Duration = 1, Every = 5 } },
	Look = "Floating teardrop of pale cyan flame with a small smiling mask, trailing sparkles",
}

Enemies.SplitterSlime = {
	Name = "Splitter Slime",
	Health = 225,
	Speed = 5,
	Reward = 3,
	Damage = 2,
	Size = 3.5,
	Color = Color3.fromRGB(150, 220, 70),
	Shape = "Block",
	Armor = "Flesh",
	CCResist = 0,
	Mechanics = { { Id = "SplitOnDeath", Count = 3, Spawn = "Mudling" } },
	Look = "Jiggly lime-green slime cube with three Mudling silhouettes visible inside",
}

Enemies.TotemBearer = {
	Name = "Totem Bearer",
	Health = 350,
	Speed = 4.5,
	Reward = 8,
	Damage = 2,
	Size = 3.5,
	Color = Color3.fromRGB(120, 140, 80),
	Shape = "Cylinder",
	Armor = "Armored",
	CCResist = 0.1,
	Mechanics = { { Id = "HealAura", Every = 3, HealPct = 0.06, Radius = 10 } },
	Look = "Hunched goblin-like spirit in a straw cloak carrying a tall carved wooden totem with a green glowing face",
}

Enemies.ShieldDrummer = {
	Name = "Shield Drummer",
	Health = 300,
	Speed = 4.5,
	Reward = 8,
	Damage = 2,
	Size = 3.5,
	Color = Color3.fromRGB(70, 110, 200),
	Shape = "Cylinder",
	Armor = "Armored",
	CCResist = 0.1,
	Mechanics = { { Id = "ShieldAura", Every = 6, Radius = 10, ShieldPctOfMaxHp = 0.25 } },
	Look = "Round armoured imp beating a large taiko drum strapped to its belly, blue hexagon sigils pulsing from the drum",
}

Enemies.Burrower = {
	Name = "Burrower",
	Health = 175,
	Speed = 9,
	Reward = 5,
	Damage = 2,
	Size = 2.5,
	Color = Color3.fromRGB(200, 170, 110),
	Shape = "Ball",
	Armor = "Swift",
	CCResist = 0,
	Mechanics = { { Id = "Burrow", Duration = 2, Every = 6 } },
	Look = "Mole-like creature with drill-shaped claws and a mining helmet lamp, sandy fur",
}

Enemies.HexLantern = {
	Name = "Hex Lantern",
	Health = 240,
	Speed = 5.5,
	Reward = 9,
	Damage = 2,
	Size = 3,
	Color = Color3.fromRGB(140, 70, 200),
	Shape = "Cylinder",
	Armor = "Ethereal",
	CCResist = 0.3,
	Flying = true,
	Mechanics = { { Id = "DisableUnit", Duration = 2, Every = 7, Range = 12 } },
	Look = "Haunted paper lantern with a single purple eye and a long tongue, chains dangling below, floating",
}

Enemies.IronRhino = {
	Name = "Iron Rhino",
	Health = 800,
	Speed = 4,
	Reward = 15,
	Damage = 5,
	Size = 5,
	Color = Color3.fromRGB(80, 80, 90),
	Shape = "Block",
	Armor = "Plated",
	CCResist = 0.5,
	Mechanics = { { Id = "ChargeBelowHp", Duration = 3, HpPct = 0.5, SpeedMult = 2 } },
	Look = "Bulky rhino beast wearing samurai-style iron plates, a single huge horn of steel, glowing red eyes",
}

-------------------------------------------------------------------- BOSSES
Enemies.GravemawTortoise = {
	Name = "Gravemaw",
	Health = 4480,
	Speed = 2.5,
	Reward = 200,
	Damage = 15,
	Size = 10,
	Color = Color3.fromRGB(80, 120, 70),
	Shape = "Ball",
	Armor = "Plated",
	CCResist = 0.6,
	Boss = true,
	Title = "The Moss-Shell Tyrant",
	Enrage = { AtHealth = 0.33, SpeedMul = 1, Summon = "Shellback", SummonCount = 3 },
	Mechanics = { { Id = "SummonEvery", Count = 1, Every = 12, Spawn = "Shellback" } },
	Phases = {
		{ AtHealth = 0.66, Mechanics = { { Id = "ShellUp", DamageTakenMult = 0.2, Duration = 5, StopMoving = true } } },
		{ AtHealth = 0.33, Mechanics = { { Id = "ShellUp", DamageTakenMult = 0.2, Duration = 5, StopMoving = true } } },
	},
	Counter = "Burst damage between shells; ArmorBreak/Mark and Earth units. Save abilities for after ShellUp ends.",
	Look = "Giant ancient tortoise with a shrine and stone lanterns growing on its mossy shell, glowing amber eyes, stone jaw with tusks",
}

Enemies.VeilwitchNoxra = {
	Name = "Noxra",
	Health = 3640,
	Speed = 4.5,
	Reward = 225,
	Damage = 15,
	Size = 8,
	Color = Color3.fromRGB(110, 60, 170),
	Shape = "Cylinder",
	Armor = "Ethereal",
	CCResist = 0.5,
	Boss = true,
	Title = "The Veilwitch",
	Flying = true,
	Enrage = { AtHealth = 0.5, SpeedMul = 1.2, Summon = "Wisp", SummonCount = 3 },
	Mechanics = { { Id = "Blink", Distance = 14, Every = 9 }, { Id = "SummonEvery", Count = 3, Every = 10, Spawn = "Wisp" } },
	Phases = {
		{ AtHealth = 0.5, Mechanics = { { Id = "DisableUnit", Count = 2, Duration = 3, Every = 8, Range = 16 } } },
		{ AtHealth = 0.2, Mechanics = { { Id = "Phase", Duration = 1.5, Every = 6 } } },
	},
	Counter = "Needs CanHitAir units (Rin, Ryu, Aeris). Light beats Ethereal; Purify strips Phase. Spread units so Disable cannot hit all.",
	Look = "Tall floating witch made of violet smoke, wide-brim hat with candle wax dripping, cracked porcelain mask, cloak of tattered paper talismans, many lantern spirits orbiting",
}

Enemies.HollowShogun = {
	Name = "The Hollow Shogun",
	Health = 8400,
	Speed = 3,
	Reward = 400,
	Damage = 50,
	Size = 11,
	Color = Color3.fromRGB(30, 30, 40),
	Shape = "Block",
	Armor = "Armored",
	CCResist = 0.7,
	Boss = true,
	Title = "Lord of the Empty Hour",
	Enrage = { AtHealth = 0.15, SpeedMul = 1.6, Summon = "IronRhino", SummonCount = 1 },
	Mechanics = { { Id = "CleanseEvery", Every = 10 } },
	Phases = {
		{ AtHealth = 0.7, Mechanics = { { Id = "SummonNow", Count = 2, Spawn = "IronRhino" }, { Id = "ShieldSelf", ShieldPctOfMaxHp = 0.15 } } },
		{ AtHealth = 0.4, Mechanics = { { Id = "SummonNow", Count = 3, Spawn = "HexLantern" }, { Id = "StealTime", AbilityCooldownAdd = 10, Every = 12 } } },
		{ AtHealth = 0.15, Mechanics = { { Id = "ImmuneTo", List = { "Execute" } } } },
	},
	Counter = "Final boss of map 2. Purify for the shield, AntiAir for the Lanterns, hold Time Stop / Daybreak for the 15% enrage.",
	Look = "Towering empty suit of black and gold samurai armour with no body inside, blue ghost-fire leaking from the joints, cracked oni mask, enormous broken clock embedded in the chest plate, two nodachi",
}

return Enemies
