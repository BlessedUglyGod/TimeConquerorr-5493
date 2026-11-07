--!strict
-- TD content pack: 3 bosses (draft v1). Same fields as Enemies plus:
--   IsBoss = true, Title, Phases = { { AtHpPct, Mechanics... } }
-- Bosses are immune to Stun/Freeze (BossImmune) and take reduced Slow (BossResist)
-- per Elements.StatusEffects. HP is base before the +12%/wave scaling.

local Bosses = {}

Bosses.GravemawTortoise = {
	Id = "GravemawTortoise", Name = "Gravemaw", Title = "The Moss-Shell Tyrant",
	IsBoss = true,
	Hp = 3200, Speed = 2.5, Reward = 400, Damage = 15, Armor = "Plated", Flying = false, CCResist = 0.6,
	Look = "Giant ancient tortoise with a shrine and stone lanterns growing on its mossy shell, glowing amber eyes, stone jaw with tusks",
	Mechanics = {
		{ Id = "SummonEvery", Every = 12, Spawn = "Shellback", Count = 1 },
	},
	Phases = {
		{ AtHpPct = 0.66, Mechanics = { { Id = "ShellUp", Duration = 5, DamageTakenMult = 0.2, StopMoving = true } } },
		{ AtHpPct = 0.33, Mechanics = { { Id = "ShellUp", Duration = 5, DamageTakenMult = 0.2, StopMoving = true }, { Id = "SummonNow", Spawn = "Shellback", Count = 3 } } },
	},
	Counter = "Burst damage between shells; ArmorBreak/Mark and Earth units. Save abilities for after ShellUp ends.",
}

Bosses.VeilwitchNoxra = {
	Id = "VeilwitchNoxra", Name = "Noxra", Title = "The Veilwitch",
	IsBoss = true,
	Hp = 2600, Speed = 4.5, Reward = 450, Damage = 15, Armor = "Ethereal", Flying = true, CCResist = 0.5,
	Look = "Tall floating witch made of violet smoke, wide-brim hat with candle wax dripping, cracked porcelain mask, cloak of tattered paper talismans, many lantern spirits orbiting",
	Mechanics = {
		{ Id = "Blink", Every = 9, Distance = 14 }, -- teleports forward along the path
		{ Id = "SummonEvery", Every = 10, Spawn = "Wisp", Count = 3 },
	},
	Phases = {
		{ AtHpPct = 0.5, Mechanics = { { Id = "DisableUnit", Every = 8, Range = 16, Count = 2, Duration = 3 } } },
		{ AtHpPct = 0.2, Mechanics = { { Id = "Phase", Every = 6, Duration = 1.5 } } },
	},
	Counter = "Needs CanHitAir units (Rin, Ryu, Aeris). Light beats Ethereal; Purify strips Phase. Spread units so Disable cannot hit all.",
}

Bosses.HollowShogun = {
	Id = "HollowShogun", Name = "The Hollow Shogun", Title = "Lord of the Empty Hour",
	IsBoss = true,
	Hp = 6000, Speed = 3, Reward = 800, Damage = 50, Armor = "Armored", Flying = false, CCResist = 0.7,
	Look = "Towering empty suit of black and gold samurai armour with no body inside, blue ghost-fire leaking from the joints, cracked oni mask, enormous broken clock embedded in the chest plate, two nodachi",
	Mechanics = {
		{ Id = "CleanseEvery", Every = 10 }, -- removes Slow/Burn/Poison/Mark/ArmorBreak from itself
	},
	Phases = {
		{ AtHpPct = 0.7, Mechanics = { { Id = "SummonNow", Spawn = "IronRhino", Count = 2 }, { Id = "ShieldSelf", ShieldPctOfMaxHp = 0.15 } } },
		{ AtHpPct = 0.4, Mechanics = { { Id = "SummonNow", Spawn = "HexLantern", Count = 3 }, { Id = "StealTime", Every = 12, AbilityCooldownAdd = 10 } } },
		{ AtHpPct = 0.15, Mechanics = { { Id = "Enrage", SpeedMult = 1.6, ImmuneTo = { "Execute" } } } },
	},
	Counter = "Final boss of map 2. Purify for the shield, AntiAir for the Lanterns, hold Time Stop / Daybreak for the 15% enrage.",
}

return Bosses
