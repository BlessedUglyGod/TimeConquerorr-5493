--!strict
-- TD content pack: 20 original units (draft v1).
-- Target: merge into ReplicatedStorage.TD.Config.Units (or require as a separate
-- ModuleScript ReplicatedStorage.TD.Content.Units and merge at boot).
--
-- Schema (draft, adapt to the live Config when integrating):
--   Id          string   unique key, PascalCase, same as the table key
--   Name        string   display name
--   Rarity      string   Common | Rare | Epic | Legendary | Mythic | Exclusive
--   Element     string   see Elements.lua
--   Role        string   DPS | Splash | Support | Control | AntiArmor | AntiAir | Economy
--   Attack      string   Single | Splash | Pulse | Chain | Pierce | None
--   CanHitAir   boolean  may target enemies with Flying = true
--   Placement   string   Ground | Water | Any (Water only matters on maps with water tiles)
--   Look        string   prompt for model generation (chibi 3D, original design)
--   Levels      {Level}  index 1 = placed, 2..3 = upgrades
--     Cost        number  price of this level (placement for Lv1, upgrade for Lv2/3)
--     Damage      number  per hit (per target for Splash/Pulse/Chain)
--     Range       number  studs
--     Cooldown    number  seconds between attacks
--     SplashRadius/ChainCount/ChainFalloff/PierceCount  optional per Attack
--     OnHit       {StatusRef}? statuses applied on hit, see Elements.lua StatusEffects
--     Aura        table?  passive effect on allies or enemies in Range
--     Income      number? money paid per cleared wave (Economy units)
--   Ability     table?  active ability: Id, Name, Cooldown, UnlockLevel, Params, Desc
--   Passive     table?  always-on rule: Id, Params, Desc
--
-- Balance: first-pass numbers, tuned only relative to each other. Lv1 cost
-- ~150-225 Common, 350-400 Rare, 550-700 Epic, 800-950 Legendary, 1400+ Mythic/Exclusive.
-- Splash/Chain/Pierce/support units have lower raw DPS on purpose. Re-tune with the bot run.

local Units = {}

-------------------------------------------------------------------- COMMON
Units.PipCopperbolt = {
	Id = "PipCopperbolt",
	Name = "Pip Copperbolt",
	Rarity = "Common",
	Element = "Lightning",
	Role = "DPS",
	Attack = "Single",
	CanHitAir = false,
	Placement = "Ground",
	Look = "Chibi teen mechanic with spiky copper hair and oversized goggles, yellow work overalls covered in patches, holding a stubby tesla-coil pistol wrapped in tape, small spark wisps around the hands",
	Levels = {
		{ Cost = 150, Damage = 6, Range = 14, Cooldown = 0.5 },
		{ Cost = 120, Damage = 10, Range = 15, Cooldown = 0.45 },
		{ Cost = 220, Damage = 16, Range = 16, Cooldown = 0.4 },
	},
	Passive = { Id = "QuickDraw", Params = { FirstShotBonus = 2.0 }, Desc = "First hit on each new target deals double damage." },
}

Units.HanaThornshot = {
	Id = "HanaThornshot",
	Name = "Hana Thornshot",
	Rarity = "Common",
	Element = "Nature",
	Role = "DPS",
	Attack = "Single",
	CanHitAir = true,
	Placement = "Ground",
	Look = "Chibi forest girl with mossy green twin buns, leaf-patterned short kimono, wooden slingshot carved like a vine, pouch of glowing seeds on the belt",
	Levels = {
		{ Cost = 175, Damage = 5, Range = 18, Cooldown = 0.8, OnHit = { { Id = "Poison", Duration = 3, Strength = 2 } } },
		{ Cost = 140, Damage = 8, Range = 19, Cooldown = 0.75, OnHit = { { Id = "Poison", Duration = 3, Strength = 4 } } },
		{ Cost = 250, Damage = 12, Range = 21, Cooldown = 0.7, OnHit = { { Id = "Poison", Duration = 4, Strength = 7 } } },
	},
}

Units.GusPebblefist = {
	Id = "GusPebblefist",
	Name = "Gus Pebblefist",
	Rarity = "Common",
	Element = "Earth",
	Role = "Splash",
	Attack = "Splash",
	CanHitAir = false,
	Placement = "Ground",
	Look = "Stocky chibi boy with a buzz cut and a headband, sleeveless brown gi, huge stone gauntlets with cracks glowing orange, bare feet",
	Levels = {
		{ Cost = 225, Damage = 9, Range = 9, Cooldown = 1.4, SplashRadius = 5 },
		{ Cost = 160, Damage = 15, Range = 9, Cooldown = 1.3, SplashRadius = 5.5 },
		{ Cost = 300, Damage = 24, Range = 10, Cooldown = 1.2, SplashRadius = 6 },
	},
}

Units.RinPaperkite = {
	Id = "RinPaperkite",
	Name = "Rin Paperkite",
	Rarity = "Common",
	Element = "Wind",
	Role = "AntiAir",
	Attack = "Single",
	CanHitAir = true,
	Placement = "Ground",
	Look = "Chibi courier girl with a short white bob and a red scarf, holding a large folded-paper kite that she throws like a boomerang, paper charms floating around",
	Levels = {
		{ Cost = 200, Damage = 7, Range = 24, Cooldown = 1.0 },
		{ Cost = 150, Damage = 11, Range = 26, Cooldown = 0.95 },
		{ Cost = 260, Damage = 17, Range = 28, Cooldown = 0.9 },
	},
	Passive = { Id = "SkyHunter", Params = { FlyingBonus = 1.5 }, Desc = "+50% damage to Flying enemies." },
}

Units.MomoLanternbell = {
	Id = "MomoLanternbell",
	Name = "Momo Lanternbell",
	Rarity = "Common",
	Element = "Fire",
	Role = "Support",
	Attack = "Pulse",
	CanHitAir = true,
	Placement = "Ground",
	Look = "Tiny chibi shrine helper with round cheeks, orange festival yukata, carrying a paper lantern on a long pole with a small flame spirit inside, bell on the hair ribbon",
	Levels = {
		{ Cost = 200, Damage = 2, Range = 10, Cooldown = 1.5, OnHit = { { Id = "Burn", Duration = 2, Strength = 2 } } },
		{ Cost = 150, Damage = 3, Range = 11, Cooldown = 1.4, OnHit = { { Id = "Burn", Duration = 3, Strength = 3 } } },
		{ Cost = 250, Damage = 5, Range = 12, Cooldown = 1.3, OnHit = { { Id = "Burn", Duration = 3, Strength = 5 } } },
	},
	Passive = { Id = "RevealingLight", Params = {}, Desc = "Enemies in range lose Burrowed/Phased (cannot hide)." },
}

-------------------------------------------------------------------- RARE
Units.SoraTidecaller = {
	Id = "SoraTidecaller",
	Name = "Sora Tidecaller",
	Rarity = "Rare",
	Element = "Water",
	Role = "Control",
	Attack = "Splash",
	CanHitAir = false,
	Placement = "Any",
	Look = "Chibi fisher boy with messy sea-blue hair, rolled-up navy pants, sailor collar shirt, holding a giant conch shell that sprays water, small fish charm on the neck",
	Levels = {
		{ Cost = 350, Damage = 8, Range = 13, Cooldown = 1.2, SplashRadius = 5, OnHit = { { Id = "Slow", Duration = 1.5, Strength = 0.25 } } },
		{ Cost = 250, Damage = 13, Range = 14, Cooldown = 1.1, SplashRadius = 5.5, OnHit = { { Id = "Slow", Duration = 1.5, Strength = 0.3 } } },
		{ Cost = 450, Damage = 20, Range = 15, Cooldown = 1.0, SplashRadius = 6, OnHit = { { Id = "Slow", Duration = 2, Strength = 0.35 } } },
	},
	Ability = {
		Id = "RiptideWave", Name = "Riptide Wave", Cooldown = 30, UnlockLevel = 2,
		Params = { Pushback = 12, Damage = 40, Width = 6 },
		Desc = "A wave rolls along the path toward the spawn, pushing enemies back 12 studs (bosses 3).",
	},
}

Units.KaitoAshveil = {
	Id = "KaitoAshveil",
	Name = "Kaito Ashveil",
	Rarity = "Rare",
	Element = "Shadow",
	Role = "DPS",
	Attack = "Single",
	CanHitAir = false,
	Placement = "Ground",
	Look = "Chibi ninja-courier with ash-grey hair over one eye, charcoal hooded haori with torn hem, twin short daggers with purple smoke trails, mask covering the lower face",
	Levels = {
		{ Cost = 400, Damage = 22, Range = 10, Cooldown = 0.9 },
		{ Cost = 300, Damage = 36, Range = 11, Cooldown = 0.85 },
		{ Cost = 500, Damage = 55, Range = 12, Cooldown = 0.8 },
	},
	Passive = { Id = "Backstab", Params = { CritChance = 0.2, CritMult = 2.0 }, Desc = "20% chance to deal double damage." },
}

Units.LumiStarpetal = {
	Id = "LumiStarpetal",
	Name = "Lumi Starpetal",
	Rarity = "Rare",
	Element = "Light",
	Role = "Support",
	Attack = "None",
	CanHitAir = false,
	Placement = "Ground",
	Look = "Chibi idol-priestess with pale lilac long hair and star hairpins, white and gold layered dress, holding a microphone-shaped staff topped with a glowing flower",
	Levels = {
		{ Cost = 400, Damage = 0, Range = 12, Cooldown = 0, Aura = { Target = "Allies", Stat = "Range", Mult = 1.08 } },
		{ Cost = 350, Damage = 0, Range = 13, Cooldown = 0, Aura = { Target = "Allies", Stat = "Range", Mult = 1.12 } },
		{ Cost = 600, Damage = 0, Range = 14, Cooldown = 0, Aura = { Target = "Allies", Stat = "Range", Mult = 1.15, Extra = { Stat = "Cooldown", Mult = 0.92 } } },
	},
	Ability = {
		Id = "Encore", Name = "Encore", Cooldown = 60, UnlockLevel = 3,
		Params = { Duration = 8, CooldownMult = 0.6 },
		Desc = "Allies in range attack 40% faster for 8 s.",
	},
}

Units.JinIronbloom = {
	Id = "JinIronbloom",
	Name = "Jin Ironbloom",
	Rarity = "Rare",
	Element = "Earth",
	Role = "AntiArmor",
	Attack = "Single",
	CanHitAir = false,
	Placement = "Ground",
	Look = "Chibi blacksmith girl with a high brown ponytail and soot on the cheek, leather apron over a red tunic, giant hammer whose head is a blooming iron flower",
	Levels = {
		{ Cost = 375, Damage = 18, Range = 9, Cooldown = 1.3, OnHit = { { Id = "ArmorBreak", Duration = 4, Strength = 0.15 } } },
		{ Cost = 275, Damage = 28, Range = 10, Cooldown = 1.2, OnHit = { { Id = "ArmorBreak", Duration = 5, Strength = 0.2 } } },
		{ Cost = 475, Damage = 44, Range = 10, Cooldown = 1.1, OnHit = { { Id = "ArmorBreak", Duration = 6, Strength = 0.3 } } },
	},
}

Units.NamiGale = {
	Id = "NamiGale",
	Name = "Nami Gale",
	Rarity = "Rare",
	Element = "Wind",
	Role = "DPS",
	Attack = "Chain",
	CanHitAir = true,
	Placement = "Ground",
	Look = "Chibi archer with teal side-swept hair and a feather earring, light green hunter coat flapping in wind, recurve bow with spinning wind rings on the tips",
	Levels = {
		{ Cost = 375, Damage = 9, Range = 18, Cooldown = 1.0, ChainCount = 2, ChainFalloff = 0.8 },
		{ Cost = 275, Damage = 14, Range = 19, Cooldown = 0.95, ChainCount = 3, ChainFalloff = 0.8 },
		{ Cost = 500, Damage = 21, Range = 20, Cooldown = 0.9, ChainCount = 4, ChainFalloff = 0.85 },
	},
}

-------------------------------------------------------------------- EPIC
Units.AkaneCrimsonwire = {
	Id = "AkaneCrimsonwire",
	Name = "Akane Crimsonwire",
	Rarity = "Epic",
	Element = "Fire",
	Role = "DPS",
	Attack = "Chain",
	CanHitAir = false,
	Placement = "Ground",
	Look = "Chibi circus acrobat with crimson twin tails, black and red ringmaster jacket with gold buttons, a burning chain-whip coiled around one arm, smirk",
	Levels = {
		{ Cost = 600, Damage = 20, Range = 13, Cooldown = 1.0, ChainCount = 3, ChainFalloff = 0.85, OnHit = { { Id = "Burn", Duration = 3, Strength = 5 } } },
		{ Cost = 450, Damage = 32, Range = 14, Cooldown = 0.95, ChainCount = 4, ChainFalloff = 0.85, OnHit = { { Id = "Burn", Duration = 3, Strength = 8 } } },
		{ Cost = 800, Damage = 50, Range = 15, Cooldown = 0.9, ChainCount = 5, ChainFalloff = 0.9, OnHit = { { Id = "Burn", Duration = 4, Strength = 12 } } },
	},
	Ability = {
		Id = "RingOfFire", Name = "Ring of Fire", Cooldown = 45, UnlockLevel = 2,
		Params = { Radius = 10, Duration = 6, Dps = 30 },
		Desc = "Spawns a burning ring on the path in range; enemies inside take 30 dps and get Burn.",
	},
}

Units.HaruGlacierheart = {
	Id = "HaruGlacierheart",
	Name = "Haru Glacierheart",
	Rarity = "Epic",
	Element = "Ice",
	Role = "Control",
	Attack = "Pulse",
	CanHitAir = true,
	Placement = "Ground",
	Look = "Calm chibi swordsman with frosty white hair tied low, pale blue haori with snowflake crest, a katana made of translucent ice resting on the shoulder, breath visible",
	Levels = {
		{ Cost = 650, Damage = 12, Range = 11, Cooldown = 1.6, OnHit = { { Id = "Slow", Duration = 2, Strength = 0.3 } } },
		{ Cost = 500, Damage = 20, Range = 12, Cooldown = 1.5, OnHit = { { Id = "Slow", Duration = 2, Strength = 0.35 } } },
		{ Cost = 850, Damage = 32, Range = 13, Cooldown = 1.4, OnHit = { { Id = "Slow", Duration = 2.5, Strength = 0.4 }, { Id = "Freeze", Chance = 0.1, Duration = 1.2 } } },
	},
	Ability = {
		Id = "Permafrost", Name = "Permafrost", Cooldown = 50, UnlockLevel = 2,
		Params = { Duration = 2.5, BossDuration = 0.8 },
		Desc = "Freezes every enemy in range for 2.5 s (bosses 0.8 s, ignores CC immunity once).",
	},
}

Units.SerenMoonquill = {
	Id = "SerenMoonquill",
	Name = "Seren Moonquill",
	Rarity = "Epic",
	Element = "Arcane",
	Role = "Support",
	Attack = "Single",
	CanHitAir = true,
	Placement = "Ground",
	Look = "Chibi scholar with long navy hair and round glasses, star-map cloak, floating open book and a quill pen that writes glowing runes in the air",
	Levels = {
		{ Cost = 550, Damage = 10, Range = 16, Cooldown = 1.2, OnHit = { { Id = "Mark", Duration = 4, Strength = 0.1 } } },
		{ Cost = 450, Damage = 16, Range = 17, Cooldown = 1.1, OnHit = { { Id = "Mark", Duration = 4, Strength = 0.15 } } },
		{ Cost = 750, Damage = 25, Range = 18, Cooldown = 1.0, OnHit = { { Id = "Mark", Duration = 5, Strength = 0.2 } } },
	},
	Passive = { Id = "Annotate", Params = {}, Desc = "Prefers unmarked targets so Mark spreads across the wave." },
}

Units.DaichiQuakeborn = {
	Id = "DaichiQuakeborn",
	Name = "Daichi Quakeborn",
	Rarity = "Epic",
	Element = "Earth",
	Role = "Splash",
	Attack = "Splash",
	CanHitAir = false,
	Placement = "Ground",
	Look = "Huge-shouldered chibi monk with a shaved head and prayer beads of round boulders, earth-brown robes, stomping pose with cracks under the feet",
	Levels = {
		{ Cost = 700, Damage = 28, Range = 10, Cooldown = 2.0, SplashRadius = 7, OnHit = { { Id = "Stun", Chance = 0.1, Duration = 0.6 } } },
		{ Cost = 500, Damage = 45, Range = 11, Cooldown = 1.9, SplashRadius = 7.5, OnHit = { { Id = "Stun", Chance = 0.12, Duration = 0.7 } } },
		{ Cost = 900, Damage = 70, Range = 12, Cooldown = 1.8, SplashRadius = 8, OnHit = { { Id = "Stun", Chance = 0.15, Duration = 0.8 } } },
	},
	Ability = {
		Id = "Faultline", Name = "Faultline", Cooldown = 40, UnlockLevel = 3,
		Params = { Damage = 250, Length = 20, StunDuration = 1.5 },
		Desc = "Cracks the path in front: 250 damage and 1.5 s stun in a line; un-burrows enemies.",
	},
}

-------------------------------------------------------------------- LEGENDARY
Units.ValkaStormcrown = {
	Id = "ValkaStormcrown",
	Name = "Valka Stormcrown",
	Rarity = "Legendary",
	Element = "Lightning",
	Role = "DPS",
	Attack = "Chain",
	CanHitAir = true,
	Placement = "Ground",
	Look = "Proud chibi warrior queen with silver braided hair and a jagged gold crown crackling with lightning, dark blue armored dress with a cape, spear made of a frozen lightning bolt",
	Levels = {
		{ Cost = 900, Damage = 35, Range = 16, Cooldown = 1.1, ChainCount = 4, ChainFalloff = 0.85 },
		{ Cost = 700, Damage = 55, Range = 17, Cooldown = 1.0, ChainCount = 5, ChainFalloff = 0.9 },
		{ Cost = 1200, Damage = 85, Range = 18, Cooldown = 0.9, ChainCount = 6, ChainFalloff = 0.9, OnHit = { { Id = "Stun", Chance = 0.08, Duration = 0.5 } } },
	},
	Ability = {
		Id = "Thunderthrone", Name = "Thunderthrone", Cooldown = 60, UnlockLevel = 2,
		Params = { Duration = 8, ChainBonus = 3, CooldownMult = 0.5 },
		Desc = "For 8 s attacks twice as fast and chain to 3 extra targets.",
	},
}

Units.RyuAshenwing = {
	Id = "RyuAshenwing",
	Name = "Ryu Ashenwing",
	Rarity = "Legendary",
	Element = "Fire",
	Role = "AntiAir",
	Attack = "Splash",
	CanHitAir = true,
	Placement = "Ground",
	Look = "Chibi sky-rider with black hair streaked ember orange, aviator jacket with fur collar, mechanical wings of charred metal feathers glowing at the edges, flame lance",
	Levels = {
		{ Cost = 950, Damage = 40, Range = 20, Cooldown = 1.4, SplashRadius = 5, OnHit = { { Id = "Burn", Duration = 3, Strength = 8 } } },
		{ Cost = 700, Damage = 62, Range = 21, Cooldown = 1.3, SplashRadius = 5.5, OnHit = { { Id = "Burn", Duration = 3, Strength = 12 } } },
		{ Cost = 1250, Damage = 95, Range = 23, Cooldown = 1.2, SplashRadius = 6, OnHit = { { Id = "Burn", Duration = 4, Strength = 18 } } },
	},
	Passive = { Id = "SkyHunter", Params = { FlyingBonus = 1.75 }, Desc = "+75% damage to Flying enemies." },
	Ability = {
		Id = "InfernoDive", Name = "Inferno Dive", Cooldown = 55, UnlockLevel = 2,
		Params = { Damage = 600, Radius = 9 },
		Desc = "Dives onto the strongest enemy in range: 600 damage in a 9-stud blast, grounds Flying enemies for 4 s.",
	},
}

Units.OzuGoldleaf = {
	Id = "OzuGoldleaf",
	Name = "Ozu Goldleaf",
	Rarity = "Legendary",
	Element = "Light",
	Role = "Economy",
	Attack = "Single",
	CanHitAir = false,
	Placement = "Ground",
	Look = "Old chibi tea merchant with a long white mustache and gold-leaf straw hat, emerald robe with coin embroidery, abacus slung on the back, teapot that pours gold light",
	Levels = {
		{ Cost = 800, Damage = 6, Range = 10, Cooldown = 1.5, Income = 90 },
		{ Cost = 900, Damage = 9, Range = 10, Cooldown = 1.5, Income = 200 },
		{ Cost = 1400, Damage = 14, Range = 11, Cooldown = 1.5, Income = 360 },
	},
	Passive = { Id = "Haggle", Params = { UpgradeDiscount = 0.05, MaxStacks = 1 }, Desc = "Upgrades of all your units cost 5% less (does not stack with another Ozu)." },
}

-------------------------------------------------------------------- MYTHIC
Units.KurenaiEclipse = {
	Id = "KurenaiEclipse",
	Name = "Kurenai of the Eclipse",
	Rarity = "Mythic",
	Element = "Shadow",
	Role = "DPS",
	Attack = "Pierce",
	CanHitAir = false,
	Placement = "Ground",
	Look = "Elegant chibi swordswoman with long black hair fading to crimson tips, eyes with eclipse rings, black kimono with a red moon pattern, a long nodachi trailing dark mist, half-moon halo",
	Levels = {
		{ Cost = 1400, Damage = 80, Range = 14, Cooldown = 1.2, PierceCount = 3 },
		{ Cost = 1100, Damage = 125, Range = 15, Cooldown = 1.1, PierceCount = 4 },
		{ Cost = 1900, Damage = 190, Range = 16, Cooldown = 1.0, PierceCount = 5 },
	},
	Passive = { Id = "Execute", Params = { Threshold = 0.12, BossThreshold = 0.0 }, Desc = "Instantly defeats non-boss enemies below 12% HP." },
	Ability = {
		Id = "TotalEclipse", Name = "Total Eclipse", Cooldown = 70, UnlockLevel = 2,
		Params = { Duration = 6, DamageTakenMult = 1.25, Slow = 0.3 },
		Desc = "Darkens the field for 6 s: all enemies take +25% damage and are slowed 30%.",
	},
}

Units.AerisDawnbreaker = {
	Id = "AerisDawnbreaker",
	Name = "Aeris Dawnbreaker",
	Rarity = "Mythic",
	Element = "Light",
	Role = "DPS",
	Attack = "Pierce",
	CanHitAir = true,
	Placement = "Ground",
	Look = "Radiant chibi paladin with short golden hair and a sunburst halo, white and sky-blue plate armor with feather motifs, a greatbow shaped like a rising sun firing beams",
	Levels = {
		{ Cost = 1450, Damage = 70, Range = 22, Cooldown = 1.3, PierceCount = 6 },
		{ Cost = 1100, Damage = 110, Range = 23, Cooldown = 1.2, PierceCount = 8 },
		{ Cost = 2000, Damage = 170, Range = 25, Cooldown = 1.1, PierceCount = 10 },
	},
	Passive = { Id = "Purify", Params = {}, Desc = "Hits remove enemy Shield and Phased states." },
	Ability = {
		Id = "Daybreak", Name = "Daybreak", Cooldown = 75, UnlockLevel = 2,
		Params = { Damage = 1200, Width = 5 },
		Desc = "A beam along the whole path: 1200 damage to every enemy on it (bosses take 50%).",
	},
}

-------------------------------------------------------------------- EXCLUSIVE
Units.TokiyaClockveil = {
	Id = "TokiyaClockveil",
	Name = "Tokiya Clockveil",
	Rarity = "Exclusive",
	Element = "Arcane",
	Role = "Control",
	Attack = "Splash",
	CanHitAir = true,
	Placement = "Ground",
	Look = "Mysterious chibi time-keeper with silver hair and one clock-face eye, long dark-teal coat with brass gears, a floating pocket-watch shield and an hourglass staff with sand flowing upward",
	Levels = {
		{ Cost = 1500, Damage = 55, Range = 15, Cooldown = 1.2, SplashRadius = 6, OnHit = { { Id = "Slow", Duration = 2, Strength = 0.2 } } },
		{ Cost = 1200, Damage = 85, Range = 16, Cooldown = 1.1, SplashRadius = 6.5, OnHit = { { Id = "Slow", Duration = 2, Strength = 0.25 } } },
		{ Cost = 2100, Damage = 130, Range = 18, Cooldown = 1.0, SplashRadius = 7, OnHit = { { Id = "Slow", Duration = 2.5, Strength = 0.3 } } },
	},
	Passive = { Id = "BorrowedTime", Params = { CooldownMult = 0.9 }, Desc = "All your units' ability cooldowns are 10% shorter." },
	Ability = {
		Id = "TimeStop", Name = "Time Stop", Cooldown = 90, UnlockLevel = 2,
		Params = { Duration = 3, BossDuration = 1, Rewind = 8 },
		Desc = "Freezes every enemy on the map for 3 s (bosses 1 s), then rewinds them 8 studs back along the path.",
	},
}

return Units
