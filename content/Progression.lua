--!strict
-- TD content: placement limits and unit progression profiles.
--
-- 1) PLACEMENT LIMITS (per player, both enforced at the same time by the server):
--    * Limits.PerPlayerTotal          : all units one player may have placed at once
--                                       (math.huge = no overall cap; live since 2026-11-08)
--    * unit.PlacementLimit            : copies of THIS unit one player may have placed at once
--      (set in content/Units.lua for pack units, in Limits.ById below for the original 6,
--       evolved units inherit their base's value through Evolutions.build)
--    * Limits.Modes[mode]             : optional per-mode overrides (nil = use the defaults)
--    Progression.placementLimit(unitId, def) is the single lookup the server and the UI use.
--    UI text: "2/3 placed"; when blocked: "Limit reached: Ozu Goldleaf 3/3", or in a capped
--    mode such as Challenge: "Unit limit 6/6".
--
-- 2) PROGRESSION PROFILES: which rules a unit follows.
--    * Standard  : stars 1..5 from duplicate copies (current system).
--    * UltraRare : NO duplicate star grind. Stars are disabled and the unit gets the full 5-star
--                  stat bonus from the start; the UI hides the star row (or shows 5/5 filled).
--                  Progress instead comes from Mastery + a unit-specific Awakening questline +
--                  boss/signature materials. Extra copies convert to Mastery XP, never needed.
--    Profile lookup order: unit.ProgressionProfile > Progression.UnitProfiles[id]
--      > Progression.RarityProfiles[rarity] > "Standard".
--    Ultra-rare by default: Secret, Exclusive. Special evolved units opt in by id.
--
-- Plain Lua style (pairs, no type annotations) so it also runs in a stock Lua test runner.

local Progression = {}

---------------------------------------------------------------- placement limits
Progression.Limits = {
	PerPlayerTotal = math.huge, -- no overall cap (live); only per-unit limits and mode caps apply
	-- Fallback when a unit has no PlacementLimit: by Role, then by rarity.
	ByRole = { Economy = 3, Support = 3 },
	ByRarity = { Common = 6, Rare = 4, Epic = 3, Legendary = 2, Mythic = 2, Secret = 1, Exclusive = 1 },
	-- Every live unit, by live Config id (also covers units whose def has no PlacementLimit yet).
	ById = {
		Spark = 4, -- Ren, Rare single-target DPS
		Mortar = 3, -- Mira, Epic splash + Meteor
		Frost = 4, -- Yuki, Rare control
		Tycoon = 3, -- Baron, Legendary economy
		Kaze = 6, -- Common long range
		Tora = 5, -- Common short splash
		Pip = 6, Hana = 5, Gus = 5, Rin = 5, Momo = 4,
		Kaito = 4, Jin = 4, Nami = 4, Seren = 3, Akane = 3,
	},
	-- Optional per-mode overrides, e.g. a challenge that allows only one copy of everything.
	Modes = {
		Challenge = { PerPlayerTotal = 6 }, -- live challenge cap (daily and weekly challenges)
		-- Example: SomeMode = { PerPlayerTotal = 8, PerUnitMax = 2 },
	},
}

-- Returns the per-player limit for one unit in a mode (mode may be nil).
function Progression.placementLimit(unitId, def, mode)
	local L = Progression.Limits
	local limit = L.ById[unitId]
		or (def and def.PlacementLimit)
		or (def and def.EvolvedFrom and L.ById[def.EvolvedFrom]) -- evolved forms of the original 6
		or (def and L.ByRole[def.Role])
		or (def and L.ByRarity[def.Rarity])
		or 4
	local m = mode and L.Modes[mode]
	if m and m.PerUnitMax then
		limit = math.min(limit, m.PerUnitMax)
	end
	return limit
end

function Progression.perPlayerTotal(mode)
	local m = mode and Progression.Limits.Modes[mode]
	return (m and m.PerPlayerTotal) or Progression.Limits.PerPlayerTotal
end

-- Server-side check helper. placedByUnit = { [unitId] = n } and placedTotal for THIS player only.
-- Returns ok, reason ("UnitLimit" | "TotalLimit"), current, max.
function Progression.canPlace(unitId, def, placedByUnit, placedTotal, mode)
	local total = Progression.perPlayerTotal(mode)
	if placedTotal >= total then
		return false, "TotalLimit", placedTotal, total
	end
	local limit = Progression.placementLimit(unitId, def, mode)
	local n = placedByUnit[unitId] or 0
	if n >= limit then
		return false, "UnitLimit", n, limit
	end
	return true, nil, n, limit
end

---------------------------------------------------------------- progression profiles
Progression.Profiles = {
	Standard = {
		Stars = { Enabled = true, Start = 1, Max = 5, Source = "Duplicates", CopiesPerStar = { 1, 2, 3, 4 } },
		Mastery = false,
		Awakening = false,
	},
	UltraRare = {
		-- No duplicate grind: stars off, full 5-star stat bonus applied from the first copy.
		Stars = { Enabled = false, GrantMaxStatBonus = true, Max = 5, ShowAs = "Hidden" }, -- or "FullMax" to draw 5/5
		DuplicateConversion = { MasteryXP = 500 }, -- extra copies are never required; they just give XP
		Mastery = "UltraRareMastery",
		Awakening = true, -- questline defined per unit in Progression.Awakenings
		ShowInUI = { "Mastery", "Awakening", "Signature" }, -- replaces the star row
	},
}

Progression.RarityProfiles = {
	Common = "Standard",
	Rare = "Standard",
	Epic = "Standard",
	Legendary = "Standard",
	Mythic = "Standard", -- summonable on rate-up banners, keeps stars (change here if desired)
	Secret = "UltraRare",
	Exclusive = "UltraRare",
}

-- Unit-level opt-ins, for special unique evolved units and one-offs.
Progression.UnitProfiles = {
	Tokiya = "UltraRare", -- Exclusive (already UltraRare by rarity, listed for clarity)
	-- Special unique evolved units go here when designed, e.g. a Mythic's awakened form.
}

function Progression.profileId(unitId, def)
	return (def and def.ProgressionProfile)
		or Progression.UnitProfiles[unitId]
		or (def and Progression.RarityProfiles[def.Rarity])
		or "Standard"
end

function Progression.profile(unitId, def)
	return Progression.Profiles[Progression.profileId(unitId, def)]
end

---------------------------------------------------------------- mastery (ultra-rare)
-- XP from playing WITH the unit placed. Rewards are cumulative.
Progression.Mastery = {
	UltraRareMastery = {
		MaxLevel = 10,
		XpToNext = { 300, 500, 800, 1200, 1700, 2300, 3000, 3800, 4700 },
		XpSources = { MatchPlayed = 20, MatchWon = 50, BossDefeated = 40, AbilityUsed = 2, StageFirstClear = 150 },
		Rewards = {
			[2] = { DamageMul = 1.02 },
			[3] = { RangeMul = 1.02 },
			[4] = { DamageMul = 1.03, Title = "Adept" },
			[5] = { AbilityCooldownMul = 0.95 },
			[6] = { DamageMul = 1.03 },
			[7] = { RangeMul = 1.03 },
			[8] = { DamageMul = 1.04, Title = "Master" },
			[9] = { AbilityCooldownMul = 0.95 },
			[10] = { DamageMul = 1.05, Aura = "MasteryGlow", Title = "Grandmaster" },
		},
	},
}

---------------------------------------------------------------- awakening questlines
-- Requirement types (server checks against the profile's stats):
--   ClearStage { Stage, WithUnit = true, Difficulty? }   AbilityUses { Count }
--   BossKillsWithUnit { Count, Boss? }                   InfiniteWave { Wave, WithUnit = true }
--   KillsWithUnit { Count }                              MasteryLevel { Level }
--   Material { Id, Count }                               Gold { Amount }
-- Rewards: StatMul { Damage, Range, Cooldown }, AbilityParams { key = value } (merged into Ability),
--   Passive (id), Visual (model/aura id), Title. Each step needs the previous one.
Progression.Awakenings = {
	Tokiya = {
		Signature = { Id = "HourglassSand", Name = "Hourglass Sand", Source = "Boss drop: The Hourless Shogun (map 2) and Morrag, the Ashen Sovereign (Gatefall City S-rank)" },
		Steps = {
			{
				Id = "Tokiya_A1", Name = "The Stopped Clock",
				Story = "Tokiya senses a crack in time inside the burning village.",
				Requirements = {
					{ Type = "ClearStage", Stage = "AVV_4", WithUnit = true },
					{ Type = "AbilityUses", Count = 25 },
					{ Type = "Gold", Amount = 10000 },
				},
				Reward = { AbilityParams = { Duration = 3.5 }, Title = "Timekeeper" },
			},
			{
				Id = "Tokiya_A2", Name = "Echo of the Ferryman",
				Story = "A ferryman who refuses to let time move on must be faced.",
				Requirements = {
					{ Type = "ClearStage", Stage = "TT_5", WithUnit = true },
					{ Type = "BossKillsWithUnit", Count = 5 },
					{ Type = "Material", Id = "FerrymansCoin", Count = 1 },
					{ Type = "Material", Id = "HourglassSand", Count = 3 },
				},
				Reward = { StatMul = { Damage = 1.1 }, AbilityParams = { BossDuration = 1.5 } },
			},
			{
				Id = "Tokiya_A3", Name = "Keeper of the Last Hour",
				Story = "Tokiya rewinds the Hourless Shogun's stolen hour.",
				Requirements = {
					{ Type = "MasteryLevel", Level = 7 },
					{ Type = "InfiniteWave", Wave = 40, WithUnit = true },
					{ Type = "Material", Id = "SovereignCore", Count = 1 },
					{ Type = "Material", Id = "HourglassSand", Count = 10 },
				},
				Reward = {
					StatMul = { Damage = 1.15, Range = 1.05 },
					Passive = "RewindEcho", -- after Time Stop, the next 3 attacks deal +50% (needs server support)
					Visual = "TokiyaAwakened",
					Title = "Keeper of the Last Hour",
				},
			},
		},
		AwakenedLook = "Tokiya awakened: coat turns midnight blue with glowing golden clock hands sweeping across it, both eyes now clock faces, a halo of slowly rotating roman numerals, hourglass staff with sand frozen mid-air",
	},
}

-- Template for the next Secret / unique evolved unit (copy, rename, fill in):
-- Progression.Awakenings.<UnitId> = {
--     Signature = { Id, Name, Source = "<boss of its themed world>" },
--     Steps = { { Id, Name, Story, Requirements = {...}, Reward = {...} }, ... },  -- 3 steps
--     AwakenedLook = "...",
-- }

return Progression
