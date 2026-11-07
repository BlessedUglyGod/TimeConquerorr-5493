--!strict
-- Story world 4 (dungeon-hunter genre): Gatefall City. Original monsters and characters.
-- Format: see docs/STORY_WORLDS.md. Enemies use the live Config.Enemies schema + World, Tier, Mechanics, Phases, Look.

local World = {}

World.Id = "GatefallCity"
World.Name = "Gatefall City"
World.Genre = "Dungeon hunters"
World.Order = 4
World.Faction = "Monsters pouring from ranked dungeon Gates that tear open across a modern city, and the Ruin Court, the intelligent rulers waiting at the bottom of the deepest Gate."
World.Environment = "Night-time modern city: neon signs, cracked highways, glowing blue and red Gate portals hovering over intersections, dungeon interiors of black stone and crystal. VFX: portal ripples, shadow smoke, crystal shards on kills, rank letters (E to S) shown over each Gate."
World.Story = "Gates are opening faster every night. The team clears them from E-rank to S-rank, follows the trail of a red Gate that never closes, and descends to face the Ashen Sovereign."

World.Enemies = {
	-- Regular
	GateGoblin = {
		World = "GatefallCity", Tier = "Regular",
		Name = "Gate Goblin", Health = 200, Speed = 8, Reward = 4, Damage = 1, Size = 2,
		Color = Color3.fromRGB(90, 140, 70), Shape = "Ball", Armor = "Flesh", CCResist = 0,
		Look = "Small green dungeon goblin with a crude stone dagger and a crystal shard stuck in its forehead",
	},
	CaveSpider = {
		World = "GatefallCity", Tier = "Regular",
		Name = "Crystal Spider", Health = 150, Speed = 11, Reward = 4, Damage = 1, Size = 2,
		Color = Color3.fromRGB(80, 60, 120), Shape = "Ball", Armor = "Swift", CCResist = 0,
		Mechanics = { { Id = "Burrow", Every = 7, Duration = 1.5 } },
		Look = "Dog-sized spider with crystal growths on its back that glow purple",
	},
	ShadeHound = {
		World = "GatefallCity", Tier = "Regular",
		Name = "Shade Hound", Health = 220, Speed = 10, Reward = 5, Damage = 2, Size = 2.5,
		Color = Color3.fromRGB(20, 20, 30), Shape = "Ball", Armor = "Ethereal", CCResist = 0,
		Mechanics = { { Id = "Phase", Every = 6, Duration = 1 } },
		Look = "Wolf made of black smoke with glowing blue eyes and a collar of broken chains",
	},
	StoneGargoyle = {
		World = "GatefallCity", Tier = "Regular",
		Name = "Stone Gargoyle", Health = 300, Speed = 6, Reward = 6, Damage = 2, Size = 3,
		Color = Color3.fromRGB(120, 120, 125), Shape = "Block", Armor = "Plated", CCResist = 0.2, Flying = true,
		Look = "Hunched grey stone gargoyle with bat wings and moss in the cracks",
	},
	RuneGolem = {
		World = "GatefallCity", Tier = "Regular",
		Name = "Rune Golem", Health = 520, Speed = 4, Reward = 8, Damage = 3, Size = 3.5,
		Color = Color3.fromRGB(100, 90, 80), Shape = "Block", Armor = "Armored", CCResist = 0.3,
		Look = "Blocky stone golem covered in glowing orange runes, one big crystal eye",
	},
	-- Elite
	OgreChieftain = {
		World = "GatefallCity", Tier = "Elite",
		Name = "Gate Ogre Chieftain", Health = 1400, Speed = 4, Reward = 28, Damage = 4, Size = 5,
		Color = Color3.fromRGB(140, 90, 60), Shape = "Block", Armor = "Armored", CCResist = 0.5,
		Mechanics = { { Id = "HealAura", Every = 4, Radius = 10, HealPct = 0.05 }, { Id = "ChargeBelowHp", HpPct = 0.4, SpeedMult = 1.8, Duration = 3 } },
		Look = "Huge ogre with a bone crown and a totem club, war paint, a goblin riding on its shoulder",
	},
	MimicChest = {
		World = "GatefallCity", Tier = "Elite",
		Name = "Mimic Chest", Health = 900, Speed = 7, Reward = 60, Damage = 2, Size = 3,
		Color = Color3.fromRGB(180, 140, 60), Shape = "Block", Armor = "Plated", CCResist = 0.4,
		Mechanics = { { Id = "StealMoneyOnLeak", Amount = 100 }, { Id = "Burrow", Every = 9, Duration = 2 } },
		Look = "Gold-trimmed treasure chest with a long tongue and rows of teeth, scuttling on spider legs",
	},
	-- Miniboss
	RedGateWarden = {
		World = "GatefallCity", Tier = "Miniboss", Boss = true,
		Name = "Warden of the Red Gate", Health = 5500, Speed = 3, Reward = 250, Damage = 20, Size = 7,
		Color = Color3.fromRGB(150, 30, 30), Shape = "Block", Armor = "Plated", CCResist = 0.6,
		Enrage = { AtHealth = 0.4, SpeedMul = 1.3, Summon = "RuneGolem", SummonCount = 3 },
		Mechanics = { { Id = "ShieldSelf", Every = 15, ShieldPctOfMaxHp = 0.1 }, { Id = "SummonEvery", Every = 12, Spawn = "GateGoblin", Count = 4 } },
		Look = "Armoured knight-statue with a red Gate portal glowing in its chest, a tower shield of black stone and a halberd",
	},
	-- Boss (main antagonist)
	AshenSovereign = {
		World = "GatefallCity", Tier = "Boss", Boss = true,
		Name = "Morrag, the Ashen Sovereign", Health = 10000, Speed = 2.8, Reward = 550, Damage = 40, Size = 9,
		Color = Color3.fromRGB(50, 40, 40), Shape = "Block", Armor = "Armored", CCResist = 0.8,
		Enrage = { AtHealth = 0.2, SpeedMul = 1.5, Summon = "OgreChieftain", SummonCount = 1 },
		Mechanics = {
			{ Id = "SummonEvery", Every = 10, Spawn = "ShadeHound", Count = 3 },
			{ Id = "CleanseEvery", Every = 12 },
		},
		Phases = {
			{ AtHealth = 0.7, Mechanics = { { Id = "OpenGate", Spawn = "StoneGargoyle", Count = 4, Desc = "Opens a Gate behind the core: gargoyles fly the path in reverse for 10 studs" } } },
			{ AtHealth = 0.4, Mechanics = { { Id = "AshField", Every = 10, Radius = 14, UnitCooldownMul = 1.3, Duration = 4 } } },
		},
		Look = "Ancient demon king on a throne-shaped armour of black stone and embers, crown of floating ash, burning eyes, cape of smoke, greatsword of cracked obsidian",
	},
}

World.Stages = {
	{ Id = "GC_1", Name = "E-Rank Gate: Subway", Story = "A small Gate opens in the subway.", Waves = 12, StartMoney = 375, Pool = { "GateGoblin", "CaveSpider" } },
	{ Id = "GC_2", Name = "C-Rank Gate: Overpass", Story = "Shade hounds spill onto the highway.", Waves = 14, StartMoney = 375, Pool = { "GateGoblin", "CaveSpider", "ShadeHound", "StoneGargoyle" } },
	{ Id = "GC_3", Name = "The Red Gate", Story = "A Gate that will not close; its Warden appears.", Waves = 14, StartMoney = 400, Pool = { "ShadeHound", "StoneGargoyle", "RuneGolem", "MimicChest" }, Miniboss = "RedGateWarden" },
	{ Id = "GC_4", Name = "A-Rank Dungeon Halls", Story = "Inside the Gate, the ogre clans rule.", Waves = 15, StartMoney = 400, Pool = { "GateGoblin", "RuneGolem", "OgreChieftain", "MimicChest" } },
	{ Id = "GC_5", Name = "Throne of Ash (S-Rank)", Story = "Morrag wakes at the bottom of the deepest Gate.", Waves = 15, StartMoney = 425, Pool = { "CaveSpider", "ShadeHound", "StoneGargoyle", "RuneGolem", "OgreChieftain" }, Boss = "AshenSovereign" },
}

World.Materials = {
	GateCrystal = { Name = "Gate Crystal", Rarity = "Rare", Use = "Evolution material for hunter/shadow units." },
	RedGateShard = { Name = "Red Gate Shard", Rarity = "Epic", Use = "Elite/miniboss drop; second evolution step." },
	SovereignCore = { Name = "Sovereign Core", Rarity = "Legendary", Use = "Boss drop; awakening of hunter/shadow units." },
}

World.Rewards = {
	GC_1 = { FirstClear = { Gems = 80 }, Drops = { GateCrystal = { Chance = 0.3, Count = 1 } } },
	GC_2 = { FirstClear = { Gems = 80 }, Drops = { GateCrystal = { Chance = 0.4, Count = 1 } } },
	GC_3 = { FirstClear = { Gems = 110, Materials = { RedGateShard = 1 } }, Drops = { GateCrystal = { Chance = 0.5, Count = 1 }, RedGateShard = { Chance = 0.1, Count = 1 } } },
	GC_4 = { FirstClear = { Gems = 110 }, Drops = { GateCrystal = { Chance = 0.5, Count = 2 }, RedGateShard = { Chance = 0.15, Count = 1 } } },
	GC_5 = { FirstClear = { Gems = 225, Materials = { SovereignCore = 1 } }, Drops = { RedGateShard = { Chance = 0.25, Count = 1 }, SovereignCore = { Chance = 0.03, Count = 1 } } },
}

return World
