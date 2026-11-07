# TD — Content roster v1 (units, enemies, bosses, map 2)

Ready-to-integrate data for the Studio place. Story Mode worlds and the world-consistency rule are in [STORY_WORLDS.md](STORY_WORLDS.md). Everything is original: names, looks and abilities are not based on any existing franchise character.

| File | Goes to | Contents |
|---|---|---|
| `content/Units.lua` | `Config.Units` | 20 units |
| `content/Enemies.lua` | `Config.Enemies` | 10 enemies + 3 bosses (`Boss = true`) |
| `content/Elements.lua` | `Config.ElementChart` + statuses | 7 new elements, 2 new armor types, 3 new statuses (Poison, Freeze, Mark) |
| `content/Maps/SunkenLanternShrine.lua` | new map module | map 2: two lanes, water zones, pads, 15 waves |

**Schema (v2)** matches the live `ReplicatedStorage.TD.Config` so merging is a loop of `Config.Units[id] = def`:

- Units: `Name, Rarity, Role, Description, Cost, Attack, Element, Color, Hair, Levels, Ability`. `Levels[1]` has no `Cost`; `Levels[2..3].Cost` is the upgrade price. `Splash` is the splash radius. `OnHit = { StatusId = { strength, duration, Chance = p? } }`.
- Conventions: Slow strength is the speed multiplier (0.7 = 30% slower), ArmorBreak/Mark are damage-taken multipliers (1.2 = +20%), Burn/Poison strength is damage per second.
- Enemies: `Name, Health, Speed, Reward, Damage, Size, Color, Shape, Armor, CCResist, Boss, Enrage = { AtHealth, SpeedMul, Summon, SummonCount }`.
- Waves: `{ enemyId, count, interval }` plus optional `Lane` and `Delay` for map 2.
- Extra fields the live server ignores until implemented: `Attack = "Chain"/"Pierce"` with `ChainCount/ChainFalloff/PierceCount`, OnHit `Chance`, `CanHitAir`, `Placement`, `Passive`, `Aura`, `Ability.UnlockLevel`, enemy `Flying`, `Mechanics`, `Phases`, `Title`, `Counter`, and `Look` (model prompt).

**Scale**: placement $75–220 for Common–Legendary, $260–280 for Mythic/Exclusive; upgrades $60–220 (Mythic/Exclusive up to $300). Mudling = Crawler at 70 HP, other enemy HP and unit damage scaled by the same ×2.5, bosses 3.6k–8.4k vs the live 4.2k boss. Rewards and income halved to fit the $300 start. Numbers are relative first passes; the balance bot has the final word.

## Units (20)

| Unit | Rarity | Element | Role | Signature |
|---|---|---|---|---|
| Pip Copperbolt | Common | Lightning | DPS | First hit on a new target ×2 |
| Hana Thornshot | Common | Nature | DPS | Poison, hits air |
| Gus Pebblefist | Common | Earth | Splash | Short-range ground slam |
| Rin Paperkite | Common | Wind | AntiAir | Long range, +50% vs Flying |
| Momo Lanternbell | Common | Fire | Support | Burn pulse, reveals Burrowed/Phased |
| Sora Tidecaller | Rare | Water | Control | Slow splash; **Riptide Wave** pushes enemies back. Can stand in water |
| Kaito Ashveil | Rare | Shadow | DPS | 20% crit ×2 |
| Lumi Starpetal | Rare | Light | Support | Range aura; **Encore** +40% attack speed |
| Jin Ironbloom | Rare | Earth | AntiArmor | Armor Break up to 30% |
| Nami Gale | Rare | Wind | DPS | Chain arrows 2→4 targets |
| Akane Crimsonwire | Epic | Fire | DPS | Burning chain whip; **Ring of Fire** |
| Haru Glacierheart | Epic | Ice | Control | Slow pulse, Freeze chance; **Permafrost** |
| Seren Moonquill | Epic | Arcane | Support | Mark (+20% damage taken) spread across the wave |
| Daichi Quakeborn | Epic | Earth | Splash | Big splash, stun chance; **Faultline** |
| Valka Stormcrown | Legendary | Lightning | DPS | Chain 4→6; **Thunderthrone** |
| Ryu Ashenwing | Legendary | Fire | AntiAir | Burn splash, +75% vs Flying; **Inferno Dive** grounds flyers |
| Ozu Goldleaf | Legendary | Light | Economy | 30/65/110 per wave, −5% upgrade costs |
| Kurenai of the Eclipse | Mythic | Shadow | DPS | Pierce, Execute <12%; **Total Eclipse** |
| Aeris Dawnbreaker | Mythic | Light | DPS | Pierce 6→10, strips Shield/Phase; **Daybreak** full-path beam |
| Tokiya Clockveil | Exclusive | Arcane | Control | −10% ability cooldowns team-wide; **Time Stop** + rewind |

Rarity spread: Common 5, Rare 5, Epic 4, Legendary 3, Mythic 2, Exclusive 1. Each unit has a `Look` field written as a prompt for `generate_mesh` (chibi 3D style, same as the current models).

Suggested banner placement: Commons/Rares/Epics into the standard pool; Valka + Ryu as the first featured Legendaries; Mythics on rate-up banners only; Tokiya as an event/exclusive reward, not summonable.

## Enemies (10)

| Enemy | Armor | HP / Speed | Mechanic |
|---|---|---|---|
| Mudling | Flesh | 70 / 7 | Basic swarm |
| Skitter Moth | Swift, Flying | 55 / 11 | Needs CanHitAir |
| Shellback | Plated | 450 / 3.5 | Tank |
| Drift Wisp | Ethereal, Flying | 110 / 8 | Phase: untargetable 1 s every 5 s |
| Splitter Slime | Flesh | 225 / 5 | Splits into 3 Mudlings |
| Totem Bearer | Armored | 350 / 4.5 | Heals allies 6% every 3 s in 10 studs |
| Shield Drummer | Armored | 300 / 4.5 | Gives allies a 25% max-HP shield every 6 s |
| Burrower | Swift | 175 / 9 | Underground (untargetable) 2 s every 6 s |
| Hex Lantern | Ethereal, Flying | 240 / 5.5 | Disables the nearest unit for 2 s every 7 s |
| Iron Rhino | Plated | 800 / 4 | Charges ×2 speed below 50% HP, 50% CC resist |

## Bosses (3)

- **Gravemaw, the Moss-Shell Tyrant** (Plated, 4480 HP). Summons a Shellback every 12 s. At 66% and 33% HP it hides in its shell for 5 s (takes 20% damage, stops); the live `Enrage` at 33% summons 3 Shellbacks. Counter: burst between shells, Armor Break/Mark.
- **Noxra, the Veilwitch** (Ethereal, Flying, 3640 HP). Blinks 14 studs forward every 9 s, summons 3 Wisps every 10 s. Below 50% (live `Enrage`: ×1.2 speed, 3 Wisps) it disables 2 units at a time, below 20% it phases. Counter: anti-air + Light; Purify.
- **The Hourless Shogun** (Armored, 8400 HP, final boss). Cleanses its debuffs every 10 s. At 70% summons 2 Iron Rhinos and gains a shield, at 40% summons Hex Lanterns and adds 10 s to your ability cooldowns every 12 s, at 15% the live `Enrage` gives ×1.6 speed and a Rhino, and it becomes immune to Execute.

## Map 2 — Sunken Lantern Shrine

Flooded hilltop shrine at dusk: turquoise shallow water, moss steps, floating paper lanterns, violet cherry trees, half-sunk torii gates.

- **Two lanes**: north portal (lane A, a long loop around a pond) and west portal (lane B, short) merge at the torii bridge, then one shared tail to the core. Waves can send enemies down A, B or both, so players must split defenses before the merge or stack at it.
- **Water zones**: two ponds where only `Placement = "Water"/"Any"` units (Sora for now) may stand. Gives water units a niche and a reason to collect them.
- **Lantern pads**: three raised pads on the bridge with +10% range, one unit each.
- **15 waves**, start money 350, bosses on wave 8 (Gravemaw), 12 (Noxra) and 15 (Hourless Shogun).

## New code needed to support this content

1. Attack types `Chain` (ChainCount, ChainFalloff) and `Pierce` (PierceCount); `Attack = "None"` for pure supports.
2. `CanHitAir` targeting filter + `Flying` enemies + `Grounded` status.
3. Statuses Poison, Freeze, Mark (defined in `Elements.lua`); enemy states Shield, Phased, Burrowed, Grounded.
4. Enemy mechanic handlers keyed by `Mechanics[i].Id`: Phase, SplitOnDeath, HealAura, ShieldAura, Burrow, DisableUnit, ChargeBelowHp, SummonEvery/SummonNow, Blink, ShellUp, ShieldSelf, CleanseEvery, StealTime, Enrage. Boss `Phases` trigger once when Health drops below `AtHealth`; the live `Enrage` already covers one threshold per boss.
5. Unit passives keyed by `Passive.Id` and auras (`Aura` on levels), plus the 13 abilities listed above.
6. Multi-lane waypoints and water-zone placement rule in `canPlaceAt` for map 2.

Order suggestion: (1)+(2) first; they unlock 14 of 20 units with no special abilities. Then enemies with simple mechanics (Splitter, Burrow, Phase), then bosses.
