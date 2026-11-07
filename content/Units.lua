--!strict
-- TD content pack v2: 20 original units in the live Config.Units schema.
-- Merge: for id, def in Units do Config.Units[id] = def end
-- Live fields: Name, Rarity, Role, Description, Cost, Attack, Element, Color, Hair, Levels, Ability.
-- Upgrade prices capped at 180/220 (Mythic/Exclusive 240/300) to fit the live 60-220 range.
-- Levels[1] has no Cost (Cost is the placement price); Levels[2..3].Cost = upgrade price.
-- OnHit = { StatusId = { strength, duration, Chance = p? } } using live conventions
-- (Slow = speed multiplier, ArmorBreak/Mark = damage-taken multiplier, Burn/Poison = dps).
-- Fields the live server does not read yet (safe to ignore until implemented):
--   Attack "Chain" (ChainCount, ChainFalloff) / "Pierce" (PierceCount), OnHit Chance,
--   CanHitAir, Placement (map 2 water), Passive, Aura, Ability.UnlockLevel, Look (model prompt).

local Units = {}

-------------------------------------------------------------------- COMMON
Units.PipCopperbolt = {
	Name = "Pip Copperbolt",
	Rarity = "Common",
	Role = "DPS",
	Description = "First hit on each new target deals double damage.",
	Cost = 75,
	Attack = "Single",
	Element = "Lightning",
	Color = Color3.fromRGB(235, 200, 60),
	Hair = Color3.fromRGB(190, 105, 50),
	CanHitAir = false,
	Placement = "Ground",
	Levels = {
		{ Damage = 15, Range = 14, Cooldown = 0.5 },
		{ Cost = 60, Damage = 25, Range = 15, Cooldown = 0.45 },
		{ Cost = 110, Damage = 40, Range = 16, Cooldown = 0.4 },
	},
	Passive = { Id = "QuickDraw", FirstShotBonus = 2, Description = "First hit on each new target deals double damage." },
	Look = "Chibi teen mechanic with spiky copper hair and oversized goggles, yellow work overalls covered in patches, holding a stubby tesla-coil pistol wrapped in tape, small spark wisps around the hands",
}

Units.HanaThornshot = {
	Name = "Hana Thornshot",
	Rarity = "Common",
	Role = "DPS",
	Description = "Reliable single-target damage.",
	Cost = 85,
	Attack = "Single",
	Element = "Nature",
	Color = Color3.fromRGB(110, 170, 90),
	Hair = Color3.fromRGB(80, 130, 60),
	CanHitAir = true,
	Placement = "Ground",
	Levels = {
		{ Damage = 12, Range = 18, Cooldown = 0.8, OnHit = { Poison = { 5, 3 } } },
		{ Cost = 70, Damage = 20, Range = 19, Cooldown = 0.75, OnHit = { Poison = { 10, 3 } } },
		{ Cost = 120, Damage = 30, Range = 21, Cooldown = 0.7, OnHit = { Poison = { 17.5, 4 } } },
	},
	Look = "Chibi forest girl with mossy green twin buns, leaf-patterned short kimono, wooden slingshot carved like a vine, pouch of glowing seeds on the belt",
}

Units.GusPebblefist = {
	Name = "Gus Pebblefist",
	Rarity = "Common",
	Role = "Splash",
	Description = "Short-range area attack.",
	Cost = 100,
	Attack = "Splash",
	Element = "Earth",
	Color = Color3.fromRGB(140, 100, 70),
	Hair = Color3.fromRGB(40, 35, 30),
	CanHitAir = false,
	Placement = "Ground",
	Levels = {
		{ Damage = 22, Range = 9, Cooldown = 1.4, Splash = 5 },
		{ Cost = 70, Damage = 38, Range = 9, Cooldown = 1.3, Splash = 5.5 },
		{ Cost = 135, Damage = 60, Range = 10, Cooldown = 1.2, Splash = 6 },
	},
	Look = "Stocky chibi boy with a buzz cut and a headband, sleeveless brown gi, huge stone gauntlets with cracks glowing orange, bare feet",
}

Units.RinPaperkite = {
	Name = "Rin Paperkite",
	Rarity = "Common",
	Role = "AntiAir",
	Description = "+50% damage to Flying enemies.",
	Cost = 90,
	Attack = "Single",
	Element = "Wind",
	Color = Color3.fromRGB(240, 240, 235),
	Hair = Color3.fromRGB(250, 250, 250),
	CanHitAir = true,
	Placement = "Ground",
	Levels = {
		{ Damage = 18, Range = 24, Cooldown = 1 },
		{ Cost = 70, Damage = 28, Range = 26, Cooldown = 0.95 },
		{ Cost = 115, Damage = 42, Range = 28, Cooldown = 0.9 },
	},
	Passive = { Id = "SkyHunter", FlyingBonus = 1.5, Description = "+50% damage to Flying enemies." },
	Look = "Chibi courier girl with a short white bob and a red scarf, holding a large folded-paper kite that she throws like a boomerang, paper charms floating around",
}

Units.MomoLanternbell = {
	Name = "Momo Lanternbell",
	Rarity = "Common",
	Role = "Support",
	Description = "Enemies in range lose Burrowed/Phased (cannot hide).",
	Cost = 90,
	Attack = "Pulse",
	Element = "Fire",
	Color = Color3.fromRGB(245, 150, 60),
	Hair = Color3.fromRGB(90, 50, 30),
	CanHitAir = true,
	Placement = "Ground",
	Levels = {
		{ Damage = 5, Range = 10, Cooldown = 1.5, OnHit = { Burn = { 5, 2 } } },
		{ Cost = 70, Damage = 8, Range = 11, Cooldown = 1.4, OnHit = { Burn = { 7.5, 3 } } },
		{ Cost = 110, Damage = 12, Range = 12, Cooldown = 1.3, OnHit = { Burn = { 12.5, 3 } } },
	},
	Passive = { Id = "RevealingLight", Description = "Enemies in range lose Burrowed/Phased (cannot hide)." },
	Look = "Tiny chibi shrine helper with round cheeks, orange festival yukata, carrying a paper lantern on a long pole with a small flame spirit inside, bell on the hair ribbon",
}

-------------------------------------------------------------------- RARE
Units.SoraTidecaller = {
	Name = "Sora Tidecaller",
	Rarity = "Rare",
	Role = "Control",
	Description = "Riptide Wave: A wave rolls along the path toward the spawn, pushing enemies back 12 studs (bosses 3).",
	Cost = 140,
	Attack = "Splash",
	Element = "Water",
	Color = Color3.fromRGB(40, 70, 140),
	Hair = Color3.fromRGB(70, 150, 210),
	CanHitAir = false,
	Placement = "Any",
	Levels = {
		{ Damage = 20, Range = 13, Cooldown = 1.2, Splash = 5, OnHit = { Slow = { 0.75, 1.5 } } },
		{ Cost = 100, Damage = 32, Range = 14, Cooldown = 1.1, Splash = 5.5, OnHit = { Slow = { 0.7, 1.5 } } },
		{ Cost = 180, Damage = 50, Range = 15, Cooldown = 1, Splash = 6, OnHit = { Slow = { 0.65, 2 } } },
	},
	Ability = { Id = "RiptideWave", Name = "Riptide Wave", Cooldown = 30, UnlockLevel = 2, Damage = 100, Pushback = 12, Width = 6, Description = "A wave rolls along the path toward the spawn, pushing enemies back 12 studs (bosses 3)." },
	Look = "Chibi fisher boy with messy sea-blue hair, rolled-up navy pants, sailor collar shirt, holding a giant conch shell that sprays water, small fish charm on the neck",
}

Units.KaitoAshveil = {
	Name = "Kaito Ashveil",
	Rarity = "Rare",
	Role = "DPS",
	Description = "20% chance to deal double damage.",
	Cost = 155,
	Attack = "Single",
	Element = "Shadow",
	Color = Color3.fromRGB(55, 55, 65),
	Hair = Color3.fromRGB(150, 150, 155),
	CanHitAir = false,
	Placement = "Ground",
	Levels = {
		{ Damage = 55, Range = 10, Cooldown = 0.9 },
		{ Cost = 115, Damage = 90, Range = 11, Cooldown = 0.85 },
		{ Cost = 195, Damage = 138, Range = 12, Cooldown = 0.8 },
	},
	Passive = { Id = "Backstab", CritChance = 0.2, CritMult = 2, Description = "20% chance to deal double damage." },
	Look = "Chibi ninja-courier with ash-grey hair over one eye, charcoal hooded haori with torn hem, twin short daggers with purple smoke trails, mask covering the lower face",
}

Units.LumiStarpetal = {
	Name = "Lumi Starpetal",
	Rarity = "Rare",
	Role = "Support",
	Description = "Encore: Allies in range attack 40% faster for 8 s.",
	Cost = 150,
	Attack = "None",
	Element = "Light",
	Color = Color3.fromRGB(245, 235, 200),
	Hair = Color3.fromRGB(200, 175, 235),
	CanHitAir = false,
	Placement = "Ground",
	Levels = {
		{ Damage = 0, Range = 12, Cooldown = 0, Aura = { Target = "Allies", Stat = "Range", Mult = 1.08 } },
		{ Cost = 130, Damage = 0, Range = 13, Cooldown = 0, Aura = { Target = "Allies", Stat = "Range", Mult = 1.12 } },
		{ Cost = 220, Damage = 0, Range = 14, Cooldown = 0, Aura = { Target = "Allies", Stat = "Range", Mult = 1.15, Extra = { Stat = "Cooldown", Mult = 0.92 } } },
	},
	Ability = { Id = "Encore", Name = "Encore", Cooldown = 60, UnlockLevel = 3, CooldownMult = 0.6, Duration = 8, Description = "Allies in range attack 40% faster for 8 s." },
	Look = "Chibi idol-priestess with pale lilac long hair and star hairpins, white and gold layered dress, holding a microphone-shaped staff topped with a glowing flower",
}

Units.JinIronbloom = {
	Name = "Jin Ironbloom",
	Rarity = "Rare",
	Role = "AntiArmor",
	Description = "AntiArmor",
	Cost = 145,
	Attack = "Single",
	Element = "Earth",
	Color = Color3.fromRGB(180, 60, 50),
	Hair = Color3.fromRGB(120, 75, 40),
	CanHitAir = false,
	Placement = "Ground",
	Levels = {
		{ Damage = 45, Range = 9, Cooldown = 1.3, OnHit = { ArmorBreak = { 1.15, 4 } } },
		{ Cost = 105, Damage = 70, Range = 10, Cooldown = 1.2, OnHit = { ArmorBreak = { 1.2, 5 } } },
		{ Cost = 185, Damage = 110, Range = 10, Cooldown = 1.1, OnHit = { ArmorBreak = { 1.3, 6 } } },
	},
	Look = "Chibi blacksmith girl with a high brown ponytail and soot on the cheek, leather apron over a red tunic, giant hammer whose head is a blooming iron flower",
}

Units.NamiGale = {
	Name = "Nami Gale",
	Rarity = "Rare",
	Role = "DPS",
	Description = "Reliable single-target damage.",
	Cost = 145,
	Attack = "Chain",
	Element = "Wind",
	Color = Color3.fromRGB(120, 190, 140),
	Hair = Color3.fromRGB(60, 170, 170),
	CanHitAir = true,
	Placement = "Ground",
	Levels = {
		{ Damage = 22, Range = 18, Cooldown = 1, ChainCount = 2, ChainFalloff = 0.8 },
		{ Cost = 105, Damage = 35, Range = 19, Cooldown = 0.95, ChainCount = 3, ChainFalloff = 0.8 },
		{ Cost = 195, Damage = 52, Range = 20, Cooldown = 0.9, ChainCount = 4, ChainFalloff = 0.85 },
	},
	Look = "Chibi archer with teal side-swept hair and a feather earring, light green hunter coat flapping in wind, recurve bow with spinning wind rings on the tips",
}

-------------------------------------------------------------------- EPIC
Units.AkaneCrimsonwire = {
	Name = "Akane Crimsonwire",
	Rarity = "Epic",
	Role = "DPS",
	Description = "Ring of Fire: Spawns a burning ring on the path in range; enemies inside take 30 dps and get Burn.",
	Cost = 180,
	Attack = "Chain",
	Element = "Fire",
	Color = Color3.fromRGB(30, 25, 30),
	Hair = Color3.fromRGB(200, 30, 45),
	CanHitAir = false,
	Placement = "Ground",
	Levels = {
		{ Damage = 50, Range = 13, Cooldown = 1, ChainCount = 3, ChainFalloff = 0.85, OnHit = { Burn = { 12.5, 3 } } },
		{ Cost = 135, Damage = 80, Range = 14, Cooldown = 0.95, ChainCount = 4, ChainFalloff = 0.85, OnHit = { Burn = { 20, 3 } } },
		{ Cost = 220, Damage = 125, Range = 15, Cooldown = 0.9, ChainCount = 5, ChainFalloff = 0.9, OnHit = { Burn = { 30, 4 } } },
	},
	Ability = { Id = "RingOfFire", Name = "Ring of Fire", Cooldown = 45, UnlockLevel = 2, Dps = 75, Duration = 6, Radius = 10, Description = "Spawns a burning ring on the path in range; enemies inside take 30 dps and get Burn." },
	Look = "Chibi circus acrobat with crimson twin tails, black and red ringmaster jacket with gold buttons, a burning chain-whip coiled around one arm, smirk",
}

Units.HaruGlacierheart = {
	Name = "Haru Glacierheart",
	Rarity = "Epic",
	Role = "Control",
	Description = "Permafrost: Freezes every enemy in range for 2.5 s (bosses 0.8 s, ignores CC immunity once).",
	Cost = 190,
	Attack = "Pulse",
	Element = "Ice",
	Color = Color3.fromRGB(170, 210, 240),
	Hair = Color3.fromRGB(235, 245, 255),
	CanHitAir = true,
	Placement = "Ground",
	Levels = {
		{ Damage = 30, Range = 11, Cooldown = 1.6, OnHit = { Slow = { 0.7, 2 } } },
		{ Cost = 145, Damage = 50, Range = 12, Cooldown = 1.5, OnHit = { Slow = { 0.65, 2 } } },
		{ Cost = 220, Damage = 80, Range = 13, Cooldown = 1.4, OnHit = { Slow = { 0.6, 2.5 }, Freeze = { 1, 1.2, Chance = 0.1 } } },
	},
	Ability = { Id = "Permafrost", Name = "Permafrost", Cooldown = 50, UnlockLevel = 2, BossDuration = 0.8, Duration = 2.5, Description = "Freezes every enemy in range for 2.5 s (bosses 0.8 s, ignores CC immunity once)." },
	Look = "Calm chibi swordsman with frosty white hair tied low, pale blue haori with snowflake crest, a katana made of translucent ice resting on the shoulder, breath visible",
}

Units.SerenMoonquill = {
	Name = "Seren Moonquill",
	Rarity = "Epic",
	Role = "Support",
	Description = "Prefers unmarked targets so Mark spreads across the wave.",
	Cost = 170,
	Attack = "Single",
	Element = "Arcane",
	Color = Color3.fromRGB(45, 50, 110),
	Hair = Color3.fromRGB(30, 40, 90),
	CanHitAir = true,
	Placement = "Ground",
	Levels = {
		{ Damage = 25, Range = 16, Cooldown = 1.2, OnHit = { Mark = { 1.1, 4 } } },
		{ Cost = 140, Damage = 40, Range = 17, Cooldown = 1.1, OnHit = { Mark = { 1.15, 4 } } },
		{ Cost = 220, Damage = 62, Range = 18, Cooldown = 1, OnHit = { Mark = { 1.2, 5 } } },
	},
	Passive = { Id = "Annotate", Description = "Prefers unmarked targets so Mark spreads across the wave." },
	Look = "Chibi scholar with long navy hair and round glasses, star-map cloak, floating open book and a quill pen that writes glowing runes in the air",
}

Units.DaichiQuakeborn = {
	Name = "Daichi Quakeborn",
	Rarity = "Epic",
	Role = "Splash",
	Description = "Faultline: Cracks the path in front: 250 damage and 1.5 s stun in a line; un-burrows enemies.",
	Cost = 200,
	Attack = "Splash",
	Element = "Earth",
	Color = Color3.fromRGB(130, 90, 55),
	Hair = Color3.fromRGB(60, 50, 40),
	CanHitAir = false,
	Placement = "Ground",
	Levels = {
		{ Damage = 70, Range = 10, Cooldown = 2, Splash = 7, OnHit = { Stun = { 1, 0.6, Chance = 0.1 } } },
		{ Cost = 145, Damage = 112, Range = 11, Cooldown = 1.9, Splash = 7.5, OnHit = { Stun = { 1, 0.7, Chance = 0.12 } } },
		{ Cost = 220, Damage = 175, Range = 12, Cooldown = 1.8, Splash = 8, OnHit = { Stun = { 1, 0.8, Chance = 0.15 } } },
	},
	Ability = { Id = "Faultline", Name = "Faultline", Cooldown = 40, UnlockLevel = 3, Damage = 625, Length = 20, StunDuration = 1.5, Description = "Cracks the path in front: 250 damage and 1.5 s stun in a line; un-burrows enemies." },
	Look = "Huge-shouldered chibi monk with a shaved head and prayer beads of round boulders, earth-brown robes, stomping pose with cracks under the feet",
}

-------------------------------------------------------------------- LEGENDARY
Units.ValkaStormcrown = {
	Name = "Valka Stormcrown",
	Rarity = "Legendary",
	Role = "DPS",
	Description = "Thunderthrone: For 8 s attacks twice as fast and chain to 3 extra targets.",
	Cost = 215,
	Attack = "Chain",
	Element = "Lightning",
	Color = Color3.fromRGB(40, 60, 130),
	Hair = Color3.fromRGB(210, 215, 225),
	CanHitAir = true,
	Placement = "Ground",
	Levels = {
		{ Damage = 88, Range = 16, Cooldown = 1.1, ChainCount = 4, ChainFalloff = 0.85 },
		{ Cost = 165, Damage = 138, Range = 17, Cooldown = 1, ChainCount = 5, ChainFalloff = 0.9 },
		{ Cost = 220, Damage = 212, Range = 18, Cooldown = 0.9, ChainCount = 6, ChainFalloff = 0.9, OnHit = { Stun = { 1, 0.5, Chance = 0.08 } } },
	},
	Ability = { Id = "Thunderthrone", Name = "Thunderthrone", Cooldown = 60, UnlockLevel = 2, ChainBonus = 3, CooldownMult = 0.5, Duration = 8, Description = "For 8 s attacks twice as fast and chain to 3 extra targets." },
	Look = "Proud chibi warrior queen with silver braided hair and a jagged gold crown crackling with lightning, dark blue armored dress with a cape, spear made of a frozen lightning bolt",
}

Units.RyuAshenwing = {
	Name = "Ryu Ashenwing",
	Rarity = "Legendary",
	Role = "AntiAir",
	Description = "+75% damage to Flying enemies. Inferno Dive: Dives onto the strongest enemy in range: 600 damage in a 9-stud blast, grounds Flying enemies for 4 s.",
	Cost = 220,
	Attack = "Splash",
	Element = "Fire",
	Color = Color3.fromRGB(90, 60, 40),
	Hair = Color3.fromRGB(240, 120, 40),
	CanHitAir = true,
	Placement = "Ground",
	Levels = {
		{ Damage = 100, Range = 20, Cooldown = 1.4, Splash = 5, OnHit = { Burn = { 20, 3 } } },
		{ Cost = 160, Damage = 155, Range = 21, Cooldown = 1.3, Splash = 5.5, OnHit = { Burn = { 30, 3 } } },
		{ Cost = 220, Damage = 238, Range = 23, Cooldown = 1.2, Splash = 6, OnHit = { Burn = { 45, 4 } } },
	},
	Passive = { Id = "SkyHunter", FlyingBonus = 1.75, Description = "+75% damage to Flying enemies." },
	Ability = { Id = "InfernoDive", Name = "Inferno Dive", Cooldown = 55, UnlockLevel = 2, Damage = 1500, Radius = 9, Description = "Dives onto the strongest enemy in range: 600 damage in a 9-stud blast, grounds Flying enemies for 4 s." },
	Look = "Chibi sky-rider with black hair streaked ember orange, aviator jacket with fur collar, mechanical wings of charred metal feathers glowing at the edges, flame lance",
}

Units.OzuGoldleaf = {
	Name = "Ozu Goldleaf",
	Rarity = "Legendary",
	Role = "Economy",
	Description = "Upgrades of all your units cost 5% less (does not stack with another Ozu).",
	Cost = 200,
	Attack = "Single",
	Element = "Light",
	Color = Color3.fromRGB(40, 130, 90),
	Hair = Color3.fromRGB(240, 240, 240),
	CanHitAir = false,
	Placement = "Ground",
	Levels = {
		{ Damage = 15, Range = 10, Cooldown = 1.5, Income = 30 },
		{ Cost = 180, Damage = 22, Range = 10, Cooldown = 1.5, Income = 65 },
		{ Cost = 220, Damage = 35, Range = 11, Cooldown = 1.5, Income = 110 },
	},
	Passive = { Id = "Haggle", MaxStacks = 1, UpgradeDiscount = 0.05, Description = "Upgrades of all your units cost 5% less (does not stack with another Ozu)." },
	Look = "Old chibi tea merchant with a long white mustache and gold-leaf straw hat, emerald robe with coin embroidery, abacus slung on the back, teapot that pours gold light",
}

-------------------------------------------------------------------- MYTHIC
Units.KurenaiEclipse = {
	Name = "Kurenai of the Eclipse",
	Rarity = "Mythic",
	Role = "DPS",
	Description = "Instantly defeats non-boss enemies below 12% HP. Total Eclipse: Darkens the field for 6 s: all enemies take +25% damage and are slowed 30%.",
	Cost = 260,
	Attack = "Pierce",
	Element = "Shadow",
	Color = Color3.fromRGB(20, 20, 25),
	Hair = Color3.fromRGB(180, 20, 40),
	CanHitAir = false,
	Placement = "Ground",
	Levels = {
		{ Damage = 200, Range = 14, Cooldown = 1.2, PierceCount = 3 },
		{ Cost = 205, Damage = 312, Range = 15, Cooldown = 1.1, PierceCount = 4 },
		{ Cost = 300, Damage = 475, Range = 16, Cooldown = 1, PierceCount = 5 },
	},
	Passive = { Id = "Execute", BossThreshold = 0, Threshold = 0.12, Description = "Instantly defeats non-boss enemies below 12% HP." },
	Ability = { Id = "TotalEclipse", Name = "Total Eclipse", Cooldown = 70, UnlockLevel = 2, DamageTakenMult = 1.25, Duration = 6, Slow = 0.3, Description = "Darkens the field for 6 s: all enemies take +25% damage and are slowed 30%." },
	Look = "Elegant chibi swordswoman with long black hair fading to crimson tips, eyes with eclipse rings, black kimono with a red moon pattern, a long nodachi trailing dark mist, half-moon halo",
}

Units.AerisDawnbreaker = {
	Name = "Aeris Dawnbreaker",
	Rarity = "Mythic",
	Role = "DPS",
	Description = "Hits remove enemy Shield and Phased states. Daybreak: A beam along the whole path: 1200 damage to every enemy on it (bosses take 50%).",
	Cost = 265,
	Attack = "Pierce",
	Element = "Light",
	Color = Color3.fromRGB(235, 240, 250),
	Hair = Color3.fromRGB(245, 205, 80),
	CanHitAir = true,
	Placement = "Ground",
	Levels = {
		{ Damage = 175, Range = 22, Cooldown = 1.3, PierceCount = 6 },
		{ Cost = 200, Damage = 275, Range = 23, Cooldown = 1.2, PierceCount = 8 },
		{ Cost = 300, Damage = 425, Range = 25, Cooldown = 1.1, PierceCount = 10 },
	},
	Passive = { Id = "Purify", Description = "Hits remove enemy Shield and Phased states." },
	Ability = { Id = "Daybreak", Name = "Daybreak", Cooldown = 75, UnlockLevel = 2, Damage = 3000, Width = 5, Description = "A beam along the whole path: 1200 damage to every enemy on it (bosses take 50%)." },
	Look = "Radiant chibi paladin with short golden hair and a sunburst halo, white and sky-blue plate armor with feather motifs, a greatbow shaped like a rising sun firing beams",
}

-------------------------------------------------------------------- EXCLUSIVE
Units.TokiyaClockveil = {
	Name = "Tokiya Clockveil",
	Rarity = "Exclusive",
	Role = "Control",
	Description = "All your units' ability cooldowns are 10% shorter. Time Stop: Freezes every enemy on the map for 3 s (bosses 1 s), then rewinds them 8 studs back along the path.",
	Cost = 280,
	Attack = "Splash",
	Element = "Arcane",
	Color = Color3.fromRGB(30, 90, 95),
	Hair = Color3.fromRGB(200, 205, 215),
	CanHitAir = true,
	Placement = "Ground",
	Levels = {
		{ Damage = 138, Range = 15, Cooldown = 1.2, Splash = 6, OnHit = { Slow = { 0.8, 2 } } },
		{ Cost = 225, Damage = 212, Range = 16, Cooldown = 1.1, Splash = 6.5, OnHit = { Slow = { 0.75, 2 } } },
		{ Cost = 300, Damage = 325, Range = 18, Cooldown = 1, Splash = 7, OnHit = { Slow = { 0.7, 2.5 } } },
	},
	Passive = { Id = "BorrowedTime", CooldownMult = 0.9, Description = "All your units' ability cooldowns are 10% shorter." },
	Ability = { Id = "TimeStop", Name = "Time Stop", Cooldown = 90, UnlockLevel = 2, BossDuration = 1, Duration = 3, Rewind = 8, Description = "Freezes every enemy on the map for 3 s (bosses 1 s), then rewinds them 8 studs back along the path." },
	Look = "Mysterious chibi time-keeper with silver hair and one clock-face eye, long dark-teal coat with brass gears, a floating pocket-watch shield and an hourglass staff with sand flowing upward",
}

return Units
