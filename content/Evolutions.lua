--!strict
-- TD content: evolution paths for the 16 live units + evolved unit definitions.
--
-- Merge (once Config.Units is filled):
--   local Evolutions = require(path.to.Evolutions)
--   Config.Evolutions = Evolutions.Paths
--   for id, def in Evolutions.build(Config.Units) do Config.Units[id] = def end
--
-- Paths[unitId] = { { Id, Into, Materials = { [materialId] = n }, Gold, MinLevel, MinStars } }
--   * one step per unit for now (the list allows a second step later)
--   * materials come from the Story world that matches the unit's theme (docs/STORY_WORLDS.md)
--
-- Evolved units are DERIVED from the live base definition by build(), so they always match
-- the live schema and any balance changes made to the base unit:
--   Levels: Damage x DamageMul, Range x RangeMul, Cooldown x CooldownMul, Cost x CostMul,
--           Splash/ChainCount/PierceCount/Income kept, OnHit kept, then AddOnHit merged in.
--   Name/Description/Color/Hair/Look replaced; Ability/Passive/Attack/Element/Role/Rarity inherited
--   unless the Overrides table sets them. Evolved = true, EvolvedFrom = base id.
-- Nothing here needs a new server ability: evolved units reuse their base ability ids and
-- only change numbers or add an existing status (Slow, Stun, Burn, ArmorBreak, Poison, Mark).
--
-- !! BaseIds: the 6 original units' Config ids were not visible from the repo. Fix the right-hand
-- !! side if they differ (the pack units use the ids from content/Units.lua).

local Evolutions = {}

Evolutions.BaseIds = {
	Ren = "RenVoltblade",
	Mira = "MiraEmberfall",
	Yuki = "YukiFrostveil",
	Baron = "BaronGoldmane",
	Kaze = "KazeSwiftarrow",
	Tora = "ToraIronfist",
}
local B = Evolutions.BaseIds

-- Requirement tiers by base rarity.
local TIER = {
	Common = { Gold = 2000, MinLevel = 20, MinStars = 1, Rare = 10, Epic = 1, Legendary = 0 },
	Rare = { Gold = 5000, MinLevel = 25, MinStars = 2, Rare = 15, Epic = 2, Legendary = 0 },
	Epic = { Gold = 12000, MinLevel = 30, MinStars = 3, Rare = 20, Epic = 4, Legendary = 0 },
	Legendary = { Gold = 25000, MinLevel = 40, MinStars = 4, Rare = 25, Epic = 6, Legendary = 1 },
}
Evolutions.Tiers = TIER

-- World material sets (Rare, Epic, Legendary), defined in content/Worlds/*.lua.
local WORLD = {
	AshVeilValley = { "AshScroll", "CrowMaskShard", "NinefoldSeal" },
	TwilightThreshold = { "SoulWick", "VerdictChain", "FerrymansCoin" },
	SaltfangArchipelago = { "BrineDoubloon", "NavyCompass", "SaltfangPearl" },
	GatefallCity = { "GateCrystal", "RedGateShard", "SovereignCore" },
}

local function path(baseId, into, rarity, world)
	local t, m = TIER[rarity], WORLD[world]
	local mats = { [m[1]] = t.Rare, [m[2]] = t.Epic }
	if t.Legendary > 0 then
		mats[m[3]] = t.Legendary
	end
	return { { Id = baseId .. "_Evo1", Into = into, World = world, Materials = mats, Gold = t.Gold, MinLevel = t.MinLevel, MinStars = t.MinStars } }
end

-- Evolved unit specs. Mul defaults: Damage 1.35, Range 1.1, Cooldown 0.9, Cost 1.15.
Evolutions.Units = {
	------------------------------------------------ Ash Veil Valley (ninja)
	KaitoNightveil = {
		From = "KaitoAshveil", Rarity = "Rare", World = "AshVeilValley",
		Name = "Kaito Nightveil", Description = "Evolved Kaito. Crits also Mark the target (+15% damage taken).",
		Color = Color3.fromRGB(25, 25, 35), Hair = Color3.fromRGB(120, 110, 160),
		AddOnHit = { Mark = { 1.15, 3 } },
		Look = "Kaito grown older: long midnight hooded coat with silver crow-feather trim, ash hair tied back, twin daggers now curved shadow blades leaving violet afterimages, crow mask hanging at the hip",
	},
	KazeGalehawk = {
		From = B.Kaze, Rarity = "Common", World = "AshVeilValley",
		Name = "Kaze Galehawk", Description = "Evolved Kaze. Longer range and arrows that slow.",
		Color = Color3.fromRGB(90, 140, 100), Hair = Color3.fromRGB(60, 60, 50),
		Mul = { Range = 1.2 },
		AddOnHit = { Slow = { 0.85, 1.5 } },
		Look = "Kaze as a valley scout-ninja: hawk-feather cloak, longbow wrapped in red charm paper, ash-grey scarf, a hawk perched on the shoulder",
	},
	ToraStoneclaw = {
		From = B.Tora, Rarity = "Common", World = "AshVeilValley",
		Name = "Tora Stoneclaw", Description = "Evolved Tora. Heavier splash with a small stun chance.",
		Color = Color3.fromRGB(150, 80, 40), Hair = Color3.fromRGB(30, 25, 20),
		AddOnHit = { Stun = { 1, 0.5, Chance = 0.08 } },
		Look = "Tora as a mountain-temple brawler: tiger-stripe gi, iron tiger-claw gauntlets, shaved sides and a short topknot, prayer beads",
	},
	HanaBriarshade = {
		From = "HanaThornshot", Rarity = "Common", World = "AshVeilValley",
		Name = "Hana Briarshade", Description = "Evolved Hana. Stronger poison darts from a blowpipe.",
		Color = Color3.fromRGB(60, 110, 70), Hair = Color3.fromRGB(40, 90, 50),
		AddOnHit = { Poison = { 10, 4 } }, -- merged: strongest of base and this wins per level
		Look = "Hana as a forest kunoichi: dark green shinobi garb with leaf armour, a bamboo blowpipe with thorn darts, mossy hair in a single long braid, half mask of woven vines",
	},
	------------------------------------------------ Twilight Threshold (spirit swordsmen)
	YukiPalemoon = {
		From = B.Yuki, Rarity = "Rare", World = "TwilightThreshold",
		Name = "Yuki Palemoon", Description = "Evolved Yuki. Spirit frost: stronger slow, more stuns.",
		Color = Color3.fromRGB(200, 220, 245), Hair = Color3.fromRGB(240, 245, 255),
		AddOnHit = { Slow = { 0.55, 2.5 } },
		Look = "Yuki as a border spirit-guardian: white funeral-style kimono with pale blue moon crest, translucent ice katana with spirit flame, long silver hair, floating snow lanterns",
	},
	MomoSoulbell = {
		From = "MomoLanternbell", Rarity = "Common", World = "TwilightThreshold",
		Name = "Momo Soulbell", Description = "Evolved Momo. Spirit-fire pulse; still reveals hidden enemies.",
		Color = Color3.fromRGB(120, 170, 240), Hair = Color3.fromRGB(70, 50, 40),
		Mul = { Damage = 1.6 },
		AddOnHit = { Burn = { 20, 3 } },
		Look = "Momo as a little shrine keeper of the dusk city: dark blue yukata with lantern pattern, pole lantern burning with pale blue spirit fire, a big bell on the ribbon",
	},
	SerenInkveil = {
		From = "SerenMoonquill", Rarity = "Epic", World = "TwilightThreshold",
		Name = "Seren Inkveil", Description = "Evolved Seren. Writes verdicts in spirit ink: stronger Mark.",
		Color = Color3.fromRGB(20, 25, 60), Hair = Color3.fromRGB(15, 20, 50),
		AddOnHit = { Mark = { 1.3, 5 } },
		Look = "Seren as a spirit archivist: ink-black robe with glowing white calligraphy, floating ledger of names, brush-pen staff dripping blue ink, round glasses with a crack",
	},
	RinTalismancer = {
		From = "RinPaperkite", Rarity = "Common", World = "TwilightThreshold",
		Name = "Rin Talismancer", Description = "Evolved Rin. Talisman kites still hunt flyers and now slow them.",
		Color = Color3.fromRGB(245, 240, 225), Hair = Color3.fromRGB(250, 250, 250),
		AddOnHit = { Slow = { 0.8, 1.5 } },
		Look = "Rin as a spirit courier: white and red shrine outfit, a swarm of folded talisman-kites circling her, long red scarf, bell earring",
	},
	------------------------------------------------ Saltfang Archipelago (pirates)
	BaronGoldtide = {
		From = B.Baron, Rarity = "Legendary", World = "SaltfangArchipelago",
		Name = "Baron Goldtide", Description = "Evolved Baron. Treasure-fleet owner: more income per wave.",
		Color = Color3.fromRGB(30, 60, 110), Hair = Color3.fromRGB(230, 190, 60),
		Mul = { Damage = 1.2, Income = 1.3 },
		Look = "Baron as a merchant-admiral: navy and gold captain's coat, tricorn with a lion crest, golden mane, a treasure chest that floats beside him spilling coins",
	},
	NamiStormsail = {
		From = "NamiGale", Rarity = "Rare", World = "SaltfangArchipelago",
		Name = "Nami Stormsail", Description = "Evolved Nami. Sea-wind arrows chain to more targets.",
		Color = Color3.fromRGB(40, 120, 140), Hair = Color3.fromRGB(50, 170, 170),
		AddChain = 1,
		Look = "Nami as a ship's lookout archer: sailcloth coat, compass on the belt, bow carved from a ship's mast with rope string, teal hair blown by sea wind",
	},
	AkaneScarletCorsair = {
		From = "AkaneCrimsonwire", Rarity = "Epic", World = "SaltfangArchipelago",
		Name = "Akane, Scarlet Corsair", Description = "Evolved Akane. Burning chain-whip boarding hook; stronger Burn.",
		Color = Color3.fromRGB(120, 20, 30), Hair = Color3.fromRGB(220, 40, 50),
		AddOnHit = { Burn = { 40, 4 } },
		Look = "Akane as a corsair: crimson long coat with gold trim, black tricorn with a red plume, flaming chain-whip ending in a grappling hook, eyepatch with a flame symbol",
	},
	PipCannonwright = {
		From = "PipCopperbolt", Rarity = "Common", World = "SaltfangArchipelago",
		Name = "Pip Cannonwright", Description = "Evolved Pip. Ship gunner: bigger shots, first hit still doubled.",
		Color = Color3.fromRGB(150, 110, 60), Hair = Color3.fromRGB(190, 105, 50),
		Mul = { Damage = 1.45, Cooldown = 1.0 },
		Look = "Pip as a ship's gunner-mechanic: brass goggles, sailor vest with tool pockets, a hand cannon covered in copper coils, powder-burnt cheeks",
	},
	------------------------------------------------ Gatefall City (dungeon hunters)
	RenGatebreaker = {
		From = B.Ren, Rarity = "Rare", World = "GatefallCity",
		Name = "Ren Gatebreaker", Description = "Evolved Ren. Lightning blade tuned for armoured Gate monsters.",
		Color = Color3.fromRGB(30, 40, 70), Hair = Color3.fromRGB(240, 220, 90),
		AddOnHit = { ArmorBreak = { 1.15, 3 } },
		Look = "Ren as a ranked hunter: dark tactical jacket with a glowing hunter badge, lightning blade with a crystal core, hair crackling with sparks, fingerless gloves",
	},
	MiraCinderqueen = {
		From = B.Mira, Rarity = "Epic", World = "GatefallCity",
		Name = "Mira Cinderqueen", Description = "Evolved Mira. Dungeon-forged fire; meteors burn longer.",
		Color = Color3.fromRGB(90, 20, 20), Hair = Color3.fromRGB(255, 120, 40),
		AddOnHit = { Burn = { 35, 4 } },
		Look = "Mira as an S-rank fire mage: black and ember robe with crystal shoulder plates, crown of floating embers, staff topped with a red Gate shard",
	},
	JinRunesmith = {
		From = "JinIronbloom", Rarity = "Rare", World = "GatefallCity",
		Name = "Jin Runesmith", Description = "Evolved Jin. Rune hammer: stronger, longer Armor Break.",
		Color = Color3.fromRGB(90, 70, 60), Hair = Color3.fromRGB(120, 75, 40),
		AddOnHit = { ArmorBreak = { 1.4, 6 } },
		Look = "Jin as a hunter guild smith: rune-etched apron and gauntlets, hammer with a glowing orange rune head, crystal goggles, ponytail with a metal clasp",
	},
	GusCrystalfist = {
		From = "GusPebblefist", Rarity = "Common", World = "GatefallCity",
		Name = "Gus Crystalfist", Description = "Evolved Gus. Crystal gauntlets: wider splash.",
		Color = Color3.fromRGB(120, 90, 150), Hair = Color3.fromRGB(40, 35, 30),
		Mul = { Splash = 1.25 },
		Look = "Gus as a dungeon tank: purple crystal gauntlets grown from Gate shards, padded brown armour, scar on the nose, headband with a hunter rank tag",
	},
}

-- Config.Evolutions
Evolutions.Paths = {}
for into, spec in pairs(Evolutions.Units) do
	Evolutions.Paths[spec.From] = path(spec.From, into, spec.Rarity, spec.World)
end

local DEFAULT_MUL = { Damage = 1.35, Range = 1.1, Cooldown = 0.9, Cost = 1.15, Splash = 1, Income = 1 }

-- Plain Lua style (pairs, no compound ops) so the module also runs in a stock Lua test runner.
local function round5(x)
	return math.floor(x / 5 + 0.5) * 5
end

local function copy(t)
	if type(t) ~= "table" then
		return t
	end
	local c = {}
	for k, v in pairs(t) do
		c[k] = copy(v)
	end
	return c
end

-- Merge an OnHit entry, keeping whichever is stronger (Slow: lower speed multiplier is stronger).
local function mergeStatus(onHit, status, add)
	local cur = onHit[status]
	if not cur then
		onHit[status] = copy(add)
		return
	end
	local stronger
	if status == "Slow" then
		stronger = add[1] < cur[1]
	else
		stronger = add[1] > cur[1]
	end
	local merged = copy(stronger and add or cur)
	merged[2] = math.max(cur[2], add[2])
	local ca, cc = add.Chance or add[3], cur.Chance or cur[3]
	if ca or cc then
		merged.Chance = math.max(ca or 1, cc or 1)
		merged[3] = nil
		if merged.Chance >= 1 then
			merged.Chance = nil
		end
	end
	onHit[status] = merged
end

-- Returns { [evolvedId] = unitDef } built from the live base defs. Skips (and warns about) missing bases.
function Evolutions.build(baseUnits)
	local out = {}
	for id, spec in pairs(Evolutions.Units) do
		local base = baseUnits[spec.From]
		if not base then
			warn(("[Evolutions] base unit %s missing, %s skipped"):format(spec.From, id))
		else
			local mul = copy(DEFAULT_MUL)
			for k, v in pairs(spec.Mul or {}) do
				mul[k] = v
			end
			local def = copy(base)
			def.Name, def.Description = spec.Name, spec.Description
			def.Color, def.Hair, def.Look = spec.Color, spec.Hair, spec.Look
			def.Evolved, def.EvolvedFrom = true, spec.From
			def.Cost = round5((base.Cost or 0) * mul.Cost)
			for _, lv in ipairs(def.Levels) do
				if lv.Cost then
					lv.Cost = round5(lv.Cost * mul.Cost)
				end
				if lv.Damage then
					lv.Damage = math.floor(lv.Damage * mul.Damage + 0.5)
				end
				if lv.Range then
					lv.Range = math.floor(lv.Range * mul.Range * 10 + 0.5) / 10
				end
				if lv.Cooldown and lv.Cooldown > 0 then
					lv.Cooldown = math.floor(lv.Cooldown * mul.Cooldown * 100 + 0.5) / 100
				end
				if lv.Splash then
					lv.Splash = lv.Splash * mul.Splash
				end
				if lv.Income then
					lv.Income = round5(lv.Income * mul.Income)
				end
				if spec.AddChain and lv.ChainCount then
					lv.ChainCount = lv.ChainCount + spec.AddChain
				end
				if spec.AddOnHit then
					lv.OnHit = lv.OnHit or {}
					for status, v in pairs(spec.AddOnHit) do
						mergeStatus(lv.OnHit, status, v)
					end
				end
			end
			for k, v in pairs(spec.Overrides or {}) do
				def[k] = copy(v)
			end
			out[id] = def
		end
	end
	return out
end

return Evolutions
