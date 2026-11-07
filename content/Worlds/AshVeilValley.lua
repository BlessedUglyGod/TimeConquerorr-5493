--!strict
-- Story world 1 (ninja genre): Ash Veil Valley. Original faction and characters.
-- Format: see docs/STORY_WORLDS.md. World.Enemies uses the live Config.Enemies schema
-- (Name, Health, Speed, Reward, Damage, Size, Color, Shape, Armor, CCResist, Boss, Enrage)
-- plus World, Tier, Mechanics, Phases, Look. Merge: Config.Enemies[id] = def.

local World = {}

World.Id = "AshVeilValley"
World.Name = "Ash Veil Valley"
World.Genre = "Ninja"
World.Order = 1
World.Faction = "The Crow Mask Syndicate, a rogue ninja clan that burned its own village and now hunts scrolls of forbidden technique."
World.Environment = "Terraced mountain valley under falling ash: bamboo forests, wooden watchtowers, rope bridges, a burnt-out hidden village, red paper charms on every gate. VFX: ash flakes, smoke puffs on vanish, crow feathers on hit."
World.Story = "The Syndicate is stealing the valley's sealed scrolls. The player's team chases them from the outer bamboo road to the Ninefold Shrine, where their leader tries to open the last seal."

World.Enemies = {
	-- Regular
	CrowRunner = {
		World = "AshVeilValley", Tier = "Regular",
		Name = "Crow Runner", Health = 60, Speed = 10, Reward = 3, Damage = 1, Size = 2,
		Color = Color3.fromRGB(40, 40, 50), Shape = "Ball", Armor = "Swift", CCResist = 0,
		Look = "Lean rogue ninja in a black wrap with a crow-beak half mask, running hunched with arms back",
	},
	KunaiThrower = {
		World = "AshVeilValley", Tier = "Regular",
		Name = "Kunai Thrower", Health = 90, Speed = 7, Reward = 3, Damage = 1, Size = 2,
		Color = Color3.fromRGB(70, 60, 60), Shape = "Ball", Armor = "Flesh", CCResist = 0,
		Look = "Ninja in grey ash-stained garb with a bandolier of kunai and a cloth hood",
	},
	SmokeBomber = {
		World = "AshVeilValley", Tier = "Regular",
		Name = "Smoke Bomber", Health = 80, Speed = 7.5, Reward = 4, Damage = 1, Size = 2,
		Color = Color3.fromRGB(150, 150, 150), Shape = "Ball", Armor = "Swift", CCResist = 0,
		Mechanics = { { Id = "SmokeCloud", Every = 8, Radius = 8, Duration = 3, UnitRangeMul = 0.7 } },
		Look = "Short ninja with a round belly pouch of smoke bombs and goggles, trailing grey smoke",
	},
	PaperDecoy = {
		World = "AshVeilValley", Tier = "Regular",
		Name = "Paper Decoy", Health = 40, Speed = 8, Reward = 1, Damage = 1, Size = 2,
		Color = Color3.fromRGB(230, 220, 190), Shape = "Block", Armor = "Flesh", CCResist = 0,
		Look = "Flat paper cut-out of a ninja held together by a red talisman, flutters as it moves",
	},
	-- Elite
	ChainEnforcer = {
		World = "AshVeilValley", Tier = "Elite",
		Name = "Iron-Chain Enforcer", Health = 420, Speed = 4.5, Reward = 15, Damage = 3, Size = 3.5,
		Color = Color3.fromRGB(90, 90, 100), Shape = "Cylinder", Armor = "Armored", CCResist = 0.3,
		Mechanics = { { Id = "SummonEvery", Every = 10, Spawn = "PaperDecoy", Count = 2 } },
		Look = "Heavy ninja in lacquered plates with a long weighted chain wrapped around the shoulders, crow mask with iron studs",
	},
	VenomKunoichi = {
		World = "AshVeilValley", Tier = "Elite",
		Name = "Venom Kunoichi", Health = 300, Speed = 8, Reward = 14, Damage = 2, Size = 2.5,
		Color = Color3.fromRGB(90, 40, 110), Shape = "Ball", Armor = "Swift", CCResist = 0.2,
		Mechanics = { { Id = "DisableUnit", Every = 9, Range = 10, Duration = 1.5 }, { Id = "Phase", Every = 7, Duration = 0.8 } },
		Look = "Agile kunoichi in purple with a veil, green-dripping needle fans in both hands",
	},
	-- Miniboss
	TwinFangs = {
		World = "AshVeilValley", Tier = "Miniboss", Boss = true,
		Name = "The Twin Fangs", Health = 2200, Speed = 5, Reward = 120, Damage = 10, Size = 5,
		Color = Color3.fromRGB(160, 40, 40), Shape = "Cylinder", Armor = "Swift", CCResist = 0.5,
		Enrage = { AtHealth = 0.5, SpeedMul = 1.4, Summon = "CrowRunner", SummonCount = 4 },
		Mechanics = { { Id = "SplitOnDeath", Spawn = "CrowRunner", Count = 4 } },
		Look = "Two brothers fighting back to back as one model, one with a red fang mask and a ninjato, the other with a white fang mask and a kusarigama",
	},
	-- Boss (main antagonist)
	KageroNinefold = {
		World = "AshVeilValley", Tier = "Boss", Boss = true,
		Name = "Kagero of the Ninefold Mask", Health = 4800, Speed = 3.5, Reward = 300, Damage = 20, Size = 7,
		Color = Color3.fromRGB(30, 25, 30), Shape = "Cylinder", Armor = "Armored", CCResist = 0.6,
		Enrage = { AtHealth = 0.33, SpeedMul = 1.3, Summon = "ChainEnforcer", SummonCount = 2 },
		Mechanics = {
			{ Id = "MaskSwap", Every = 12, Elements = { "Fire", "Lightning", "Wind" }, ResistMul = 0.5 }, -- resists one element at a time, shown on the boss bar
			{ Id = "Blink", Every = 10, Distance = 12 },
		},
		Phases = {
			{ AtHealth = 0.66, Mechanics = { { Id = "SummonNow", Spawn = "SmokeBomber", Count = 4 } } },
			{ AtHealth = 0.33, Mechanics = { { Id = "SmokeCloud", Every = 6, Radius = 14, Duration = 3, UnitRangeMul = 0.6 } } },
		},
		Look = "Tall ninja lord in a long ash-grey coat, a ring of nine floating masks orbiting the head, one mask worn at a time, crow-feather mantle, two short blades",
	},
}

World.Stages = {
	{ Id = "AVV_1", Name = "Bamboo Road", Story = "Crow Runners raid a scroll caravan.", Waves = 10, StartMoney = 300, Pool = { "CrowRunner", "KunaiThrower" } },
	{ Id = "AVV_2", Name = "Rope Bridges", Story = "The Syndicate covers its escape with smoke.", Waves = 12, StartMoney = 300, Pool = { "CrowRunner", "KunaiThrower", "SmokeBomber", "PaperDecoy" } },
	{ Id = "AVV_3", Name = "Watchtower Pass", Story = "The Twin Fangs guard the pass.", Waves = 12, StartMoney = 325, Pool = { "KunaiThrower", "SmokeBomber", "PaperDecoy", "ChainEnforcer" }, Miniboss = "TwinFangs" },
	{ Id = "AVV_4", Name = "Burnt Village", Story = "Elite enforcers hold the ruins.", Waves = 14, StartMoney = 325, Pool = { "CrowRunner", "SmokeBomber", "ChainEnforcer", "VenomKunoichi" } },
	{ Id = "AVV_5", Name = "Ninefold Shrine", Story = "Kagero tries to break the last seal.", Waves = 15, StartMoney = 350, Pool = { "CrowRunner", "KunaiThrower", "SmokeBomber", "ChainEnforcer", "VenomKunoichi" }, Boss = "KageroNinefold" },
}

World.Materials = {
	AshScroll = { Name = "Ash Scroll", Rarity = "Rare", Use = "Evolution material for ninja-themed units (stage drops)." },
	CrowMaskShard = { Name = "Crow Mask Shard", Rarity = "Epic", Use = "Elite drop; second evolution step." },
	NinefoldSeal = { Name = "Ninefold Seal", Rarity = "Legendary", Use = "Boss drop; final evolution / awakening of ninja units." },
}

World.Rewards = {
	AVV_1 = { FirstClear = { Gems = 50 }, Drops = { AshScroll = { Chance = 0.3, Count = 1 } } },
	AVV_2 = { FirstClear = { Gems = 50 }, Drops = { AshScroll = { Chance = 0.4, Count = 1 } } },
	AVV_3 = { FirstClear = { Gems = 75, Materials = { CrowMaskShard = 1 } }, Drops = { AshScroll = { Chance = 0.5, Count = 1 }, CrowMaskShard = { Chance = 0.1, Count = 1 } } },
	AVV_4 = { FirstClear = { Gems = 75 }, Drops = { AshScroll = { Chance = 0.5, Count = 2 }, CrowMaskShard = { Chance = 0.15, Count = 1 } } },
	AVV_5 = { FirstClear = { Gems = 150, Materials = { NinefoldSeal = 1 } }, Drops = { CrowMaskShard = { Chance = 0.25, Count = 1 }, NinefoldSeal = { Chance = 0.03, Count = 1 } } },
}

return World
