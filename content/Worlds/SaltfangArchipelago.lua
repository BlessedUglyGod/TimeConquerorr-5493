--!strict
-- Story world 3 (pirate genre): Saltfang Archipelago. Original crews and characters.
-- Format: see docs/STORY_WORLDS.md. Enemies use the live Config.Enemies schema + World, Tier, Mechanics, Phases, Look.

local World = {}

World.Id = "SaltfangArchipelago"
World.Name = "Saltfang Archipelago"
World.Genre = "Pirates"
World.Order = 3
World.Faction = "Two hostile forces: the Blackbrine Crew (pirates hunting a sunken treasure) and the Iron Tide Navy (a ruthless fleet that blockades every island)."
World.Environment = "Tropical islands with turquoise shallows, wooden docks and shipwrecks, a navy fortress of grey stone, a whirlpool at the edge of the map. VFX: cannon smoke, water splashes, gold coin bursts on kills."
World.Story = "Both the pirates and the navy want the Saltfang treasure. The team fights through crew raids and a navy blockade to the Whirlpool Throne, where the rival captain waits."

World.Enemies = {
	-- Regular: Blackbrine Crew
	DeckhandBrawler = {
		World = "SaltfangArchipelago", Tier = "Regular",
		Name = "Deckhand Brawler", Health = 160, Speed = 7, Reward = 4, Damage = 1, Size = 2.5,
		Color = Color3.fromRGB(170, 120, 80), Shape = "Ball", Armor = "Flesh", CCResist = 0,
		Look = "Burly pirate deckhand with a striped shirt, bandana and taped fists",
	},
	PowderMonkey = {
		World = "SaltfangArchipelago", Tier = "Regular",
		Name = "Powder Monkey", Health = 110, Speed = 10, Reward = 4, Damage = 1, Size = 2,
		Color = Color3.fromRGB(60, 50, 40), Shape = "Ball", Armor = "Swift", CCResist = 0,
		Mechanics = { { Id = "ExplodeOnDeath", Radius = 8, DisableDuration = 1 } }, -- disables units next to where it dies
		Look = "Small pirate cabin kid carrying a lit powder keg on the back, soot-covered face",
	},
	GrappleRaider = {
		World = "SaltfangArchipelago", Tier = "Regular",
		Name = "Grapple Raider", Health = 180, Speed = 6, Reward = 5, Damage = 2, Size = 2.5,
		Color = Color3.fromRGB(120, 40, 40), Shape = "Block", Armor = "Swift", CCResist = 0,
		Mechanics = { { Id = "Blink", Every = 8, Distance = 10 } }, -- grapple hook leap forward
		Look = "Lanky pirate with a grappling hook and a cutlass, red long coat and an eyepatch",
	},
	GullSwarm = {
		World = "SaltfangArchipelago", Tier = "Regular",
		Name = "Thief Gulls", Health = 70, Speed = 12, Reward = 3, Damage = 1, Size = 2,
		Color = Color3.fromRGB(240, 240, 240), Shape = "Ball", Armor = "Swift", CCResist = 0, Flying = true,
		Mechanics = { { Id = "StealMoneyOnLeak", Amount = 10 } },
		Look = "Flock of three trained seagulls wearing tiny pirate hats, one holding a coin",
	},
	-- Regular: Iron Tide Navy
	NavyRifleman = {
		World = "SaltfangArchipelago", Tier = "Regular",
		Name = "Iron Tide Rifleman", Health = 260, Speed = 5, Reward = 6, Damage = 2, Size = 2.5,
		Color = Color3.fromRGB(230, 230, 235), Shape = "Block", Armor = "Armored", CCResist = 0.1,
		Look = "Navy soldier in a white uniform with grey steel breastplate, tall cap and a long rifle",
	},
	-- Elite
	NavyLieutenant = {
		World = "SaltfangArchipelago", Tier = "Elite",
		Name = "Iron Tide Lieutenant", Health = 800, Speed = 4.5, Reward = 22, Damage = 3, Size = 3.5,
		Color = Color3.fromRGB(200, 205, 215), Shape = "Block", Armor = "Plated", CCResist = 0.4,
		Mechanics = { { Id = "ShieldAura", Every = 6, Radius = 12, ShieldPctOfMaxHp = 0.2 } },
		Look = "Strict navy officer with a heavy tower shield shaped like an anchor and a sabre, long coat",
	},
	CannonCrab = {
		World = "SaltfangArchipelago", Tier = "Elite",
		Name = "Cannon Crab", Health = 950, Speed = 3.5, Reward = 24, Damage = 4, Size = 4.5,
		Color = Color3.fromRGB(200, 80, 50), Shape = "Ball", Armor = "Plated", CCResist = 0.5,
		Mechanics = { { Id = "DisableUnit", Every = 8, Range = 16, Duration = 2 } }, -- cannon shot at a unit
		Look = "Giant red crab with a ship cannon bolted to its shell, pirate flag stuck in its back",
	},
	-- Miniboss
	CommodoreVael = {
		World = "SaltfangArchipelago", Tier = "Miniboss", Boss = true,
		Name = "Commodore Vael Ironhull", Health = 4200, Speed = 3, Reward = 200, Damage = 15, Size = 6,
		Color = Color3.fromRGB(180, 185, 200), Shape = "Block", Armor = "Plated", CCResist = 0.6,
		Enrage = { AtHealth = 0.4, SpeedMul = 1.2, Summon = "NavyRifleman", SummonCount = 4 },
		Mechanics = { { Id = "CannonBarrage", Every = 12, Targets = 3, DisableDuration = 2 } },
		Look = "Broad navy commodore with a steel prosthetic arm shaped like a ship's ram, white greatcoat with iron epaulettes, stern grey beard",
	},
	-- Boss (rival captain)
	CaptainRedmaw = {
		World = "SaltfangArchipelago", Tier = "Boss", Boss = true,
		Name = "Captain Redmaw Saltfang", Health = 8000, Speed = 3, Reward = 450, Damage = 30, Size = 8,
		Color = Color3.fromRGB(150, 30, 30), Shape = "Block", Armor = "Armored", CCResist = 0.7,
		Enrage = { AtHealth = 0.3, SpeedMul = 1.4, Summon = "GrappleRaider", SummonCount = 4 },
		Mechanics = {
			{ Id = "CannonBarrage", Every = 10, Targets = 3, DisableDuration = 2 },
			{ Id = "SummonEvery", Every = 14, Spawn = "DeckhandBrawler", Count = 3 },
		},
		Phases = {
			{ AtHealth = 0.6, Mechanics = { { Id = "HealOnce", HealPct = 0.15, Desc = "Drinks from the treasure flask" } } },
			{ AtHealth = 0.3, Mechanics = { { Id = "SummonNow", Spawn = "CannonCrab", Count = 1 } } },
		},
		Look = "Towering pirate captain with a huge red beard braided with gold coins, shark-tooth necklace, tricorn hat with a skull, an anchor used as a weapon, open crimson coat",
	},
}

World.Stages = {
	{ Id = "SA_1", Name = "Driftwood Docks", Story = "The Blackbrine Crew raids the harbour.", Waves = 12, StartMoney = 350, Pool = { "DeckhandBrawler", "PowderMonkey", "GullSwarm" } },
	{ Id = "SA_2", Name = "Shipwreck Shoals", Story = "Raiders leap between wrecks.", Waves = 14, StartMoney = 350, Pool = { "DeckhandBrawler", "PowderMonkey", "GrappleRaider", "GullSwarm" } },
	{ Id = "SA_3", Name = "Blockade Fortress", Story = "The Iron Tide Navy shuts the strait.", Waves = 14, StartMoney = 375, Pool = { "NavyRifleman", "NavyLieutenant", "GullSwarm" }, Miniboss = "CommodoreVael" },
	{ Id = "SA_4", Name = "Crab Reef", Story = "Both sides clash on the reef.", Waves = 15, StartMoney = 375, Pool = { "GrappleRaider", "NavyRifleman", "NavyLieutenant", "CannonCrab" } },
	{ Id = "SA_5", Name = "Whirlpool Throne", Story = "Captain Redmaw claims the treasure.", Waves = 15, StartMoney = 400, Pool = { "DeckhandBrawler", "PowderMonkey", "GrappleRaider", "CannonCrab", "GullSwarm" }, Boss = "CaptainRedmaw" },
}

World.Materials = {
	BrineDoubloon = { Name = "Brine Doubloon", Rarity = "Rare", Use = "Evolution material for pirate/sea units." },
	NavyCompass = { Name = "Iron Tide Compass", Rarity = "Epic", Use = "Elite/miniboss drop; second evolution step." },
	SaltfangPearl = { Name = "Saltfang Pearl", Rarity = "Legendary", Use = "Boss drop; awakening of pirate units." },
}

World.Rewards = {
	SA_1 = { FirstClear = { Gems = 70 }, Drops = { BrineDoubloon = { Chance = 0.3, Count = 1 } } },
	SA_2 = { FirstClear = { Gems = 70 }, Drops = { BrineDoubloon = { Chance = 0.4, Count = 1 } } },
	SA_3 = { FirstClear = { Gems = 100, Materials = { NavyCompass = 1 } }, Drops = { BrineDoubloon = { Chance = 0.5, Count = 1 }, NavyCompass = { Chance = 0.1, Count = 1 } } },
	SA_4 = { FirstClear = { Gems = 100 }, Drops = { BrineDoubloon = { Chance = 0.5, Count = 2 }, NavyCompass = { Chance = 0.15, Count = 1 } } },
	SA_5 = { FirstClear = { Gems = 200, Materials = { SaltfangPearl = 1 } }, Drops = { NavyCompass = { Chance = 0.25, Count = 1 }, SaltfangPearl = { Chance = 0.03, Count = 1 } } },
}

return World
