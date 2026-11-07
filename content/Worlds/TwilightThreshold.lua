--!strict
-- Story world 2 (spirit-swordsman genre): Twilight Threshold. Original faction and characters.
-- Format: see docs/STORY_WORLDS.md. Enemies use the live Config.Enemies schema + World, Tier, Mechanics, Phases, Look.

local World = {}

World.Id = "TwilightThreshold"
World.Name = "Twilight Threshold"
World.Genre = "Spirit swordsmen"
World.Order = 2
World.Faction = "The Unmoored: spirits that refused to cross over, led by corrupted guardian swordsmen who once kept the border between the living and the dead."
World.Environment = "An endless dusk city on the border of the afterlife: white stone streets, paper-screen gates, a black river with floating lanterns, a giant broken moon. VFX: pale blue spirit flames, ink-slash sword arcs, chains of light."
World.Story = "The ferry that carries souls across has stopped. The team follows the Unmoored through the dusk city to the Last Pier, where the fallen ferryman holds the crossing hostage."

World.Enemies = {
	-- Regular
	Wraithling = {
		World = "TwilightThreshold", Tier = "Regular",
		Name = "Wraithling", Health = 80, Speed = 8, Reward = 3, Damage = 1, Size = 2,
		Color = Color3.fromRGB(200, 220, 240), Shape = "Ball", Armor = "Ethereal", CCResist = 0,
		Look = "Small hooded spirit with a blank white mask and a wispy tail instead of legs",
	},
	MaskedRevenant = {
		World = "TwilightThreshold", Tier = "Regular",
		Name = "Masked Revenant", Health = 140, Speed = 6, Reward = 4, Damage = 1, Size = 2.5,
		Color = Color3.fromRGB(60, 60, 80), Shape = "Block", Armor = "Flesh", CCResist = 0,
		Mechanics = { { Id = "Phase", Every = 6, Duration = 1 } },
		Look = "Gaunt spirit in a tattered funeral robe wearing a cracked bone mask, glowing blue chest hole",
	},
	CorruptedRonin = {
		World = "TwilightThreshold", Tier = "Regular",
		Name = "Corrupted Ronin", Health = 200, Speed = 5.5, Reward = 5, Damage = 2, Size = 2.5,
		Color = Color3.fromRGB(40, 30, 50), Shape = "Block", Armor = "Armored", CCResist = 0.1,
		Mechanics = { { Id = "ChargeBelowHp", HpPct = 0.4, SpeedMult = 1.6, Duration = 3 } },
		Look = "Ghostly swordsman in torn black hakama, black ink seeping from the eyes, katana wrapped in chains",
	},
	SoulMoth = {
		World = "TwilightThreshold", Tier = "Regular",
		Name = "Soul Moth", Health = 60, Speed = 11, Reward = 3, Damage = 1, Size = 2,
		Color = Color3.fromRGB(150, 200, 255), Shape = "Ball", Armor = "Ethereal", CCResist = 0, Flying = true,
		Look = "Glowing moth with wings like translucent paper lanterns, leaves a trail of light",
	},
	-- Elite
	ChainboundWarden = {
		World = "TwilightThreshold", Tier = "Elite",
		Name = "Chainbound Warden", Health = 600, Speed = 4, Reward = 18, Damage = 3, Size = 4,
		Color = Color3.fromRGB(110, 120, 140), Shape = "Block", Armor = "Plated", CCResist = 0.4,
		Mechanics = { { Id = "ShieldAura", Every = 7, Radius = 10, ShieldPctOfMaxHp = 0.2 } },
		Look = "Huge armoured spirit jailer wrapped in glowing chains, a lantern for a head, carrying a giant key",
	},
	BladeWraithCaptain = {
		World = "TwilightThreshold", Tier = "Elite",
		Name = "Blade-Wraith Captain", Health = 480, Speed = 6, Reward = 18, Damage = 3, Size = 3,
		Color = Color3.fromRGB(70, 40, 90), Shape = "Block", Armor = "Ethereal", CCResist = 0.3,
		Mechanics = { { Id = "SwordWave", Every = 9, Length = 18, DisableDuration = 1.5 } }, -- disables units along a line ahead of it
		Look = "Spectral swordsman captain in a long violet coat with a ragged captain's sash, sword trailing ink-black flame",
	},
	-- Miniboss
	SeveredJudge = {
		World = "TwilightThreshold", Tier = "Miniboss", Boss = true,
		Name = "The Severed Judge", Health = 3000, Speed = 3.5, Reward = 160, Damage = 12, Size = 6,
		Color = Color3.fromRGB(220, 220, 230), Shape = "Block", Armor = "Plated", CCResist = 0.6,
		Enrage = { AtHealth = 0.5, SpeedMul = 1.2, Summon = "MaskedRevenant", SummonCount = 4 },
		Mechanics = { { Id = "Reflect", Every = 10, Duration = 2, DisableAttackers = 1 } }, -- units that hit it during Reflect are disabled 1 s
		Look = "Headless spirit magistrate in white court robes, holding its own masked head in one hand and a scale of chains in the other",
	},
	-- Boss (main antagonist)
	YomikageFerryman = {
		World = "TwilightThreshold", Tier = "Boss", Boss = true,
		Name = "Yomikage, the Fallen Ferryman", Health = 6200, Speed = 3, Reward = 380, Damage = 25, Size = 8,
		Color = Color3.fromRGB(20, 30, 50), Shape = "Block", Armor = "Ethereal", CCResist = 0.7,
		Enrage = { AtHealth = 0.25, SpeedMul = 1.5, Summon = "BladeWraithCaptain", SummonCount = 2 },
		Mechanics = {
			{ Id = "SwordWave", Every = 8, Length = 24, DisableDuration = 2 },
			{ Id = "SummonEvery", Every = 12, Spawn = "Wraithling", Count = 4 },
		},
		Phases = {
			{ AtHealth = 0.5, Mechanics = { { Id = "Unbound", Duration = 0, Desc = "Sheds the ferryman robe: oar becomes a two-handed blade, Armor switches to Swift, attacks the field with SwordWave twice as often" }, { Id = "ShieldSelf", ShieldPctOfMaxHp = 0.15 } } },
		},
		Look = "Tall gaunt ferryman in a dark straw raincoat and wide hat, pale face with ink tears, a long oar that hides a curved blade, spirit lanterns hanging from the hat brim",
	},
}

World.Stages = {
	{ Id = "TT_1", Name = "Lantern Street", Story = "Wraithlings flood the dusk city.", Waves = 12, StartMoney = 325, Pool = { "Wraithling", "MaskedRevenant", "SoulMoth" } },
	{ Id = "TT_2", Name = "Paper Gate Ward", Story = "Corrupted ronin patrol the ward.", Waves = 12, StartMoney = 325, Pool = { "Wraithling", "MaskedRevenant", "CorruptedRonin" } },
	{ Id = "TT_3", Name = "Hall of Verdicts", Story = "The Severed Judge sentences the living.", Waves = 14, StartMoney = 350, Pool = { "MaskedRevenant", "CorruptedRonin", "ChainboundWarden" }, Miniboss = "SeveredJudge" },
	{ Id = "TT_4", Name = "Black River Docks", Story = "Blade-wraith captains hold the docks.", Waves = 14, StartMoney = 350, Pool = { "CorruptedRonin", "SoulMoth", "ChainboundWarden", "BladeWraithCaptain" } },
	{ Id = "TT_5", Name = "The Last Pier", Story = "Yomikage reveals why the ferry stopped.", Waves = 15, StartMoney = 375, Pool = { "Wraithling", "CorruptedRonin", "SoulMoth", "ChainboundWarden", "BladeWraithCaptain" }, Boss = "YomikageFerryman" },
}

World.Materials = {
	SoulWick = { Name = "Soul Lantern Wick", Rarity = "Rare", Use = "Evolution material for spirit/swordsman units." },
	VerdictChain = { Name = "Verdict Chain", Rarity = "Epic", Use = "Elite/miniboss drop; second evolution step." },
	FerrymansCoin = { Name = "Ferryman's Coin", Rarity = "Legendary", Use = "Boss drop; awakening of swordsman units." },
}

World.Rewards = {
	TT_1 = { FirstClear = { Gems = 60 }, Drops = { SoulWick = { Chance = 0.3, Count = 1 } } },
	TT_2 = { FirstClear = { Gems = 60 }, Drops = { SoulWick = { Chance = 0.4, Count = 1 } } },
	TT_3 = { FirstClear = { Gems = 90, Materials = { VerdictChain = 1 } }, Drops = { SoulWick = { Chance = 0.5, Count = 1 }, VerdictChain = { Chance = 0.1, Count = 1 } } },
	TT_4 = { FirstClear = { Gems = 90 }, Drops = { SoulWick = { Chance = 0.5, Count = 2 }, VerdictChain = { Chance = 0.15, Count = 1 } } },
	TT_5 = { FirstClear = { Gems = 175, Materials = { FerrymansCoin = 1 } }, Drops = { VerdictChain = { Chance = 0.25, Count = 1 }, FerrymansCoin = { Chance = 0.03, Count = 1 } } },
}

return World
