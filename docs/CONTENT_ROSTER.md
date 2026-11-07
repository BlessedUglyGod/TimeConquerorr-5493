# TD — Content roster v1 (units, enemies, bosses, map 2)

Ready-to-integrate data for the Studio place. Everything is original: names, looks and abilities are not based on any existing franchise character.

| File | Goes to | Contents |
|---|---|---|
| `content/Units.lua` | `Config.Units` | 20 units |
| `content/Enemies.lua` | `Config.Enemies` | 10 enemies |
| `content/Bosses.lua` | `Config.Enemies` (IsBoss) | 3 bosses with HP phases |
| `content/Elements.lua` | `Config` element chart + `StatusService` defs | 7 new elements, 2 new armor types, 4 new statuses |
| `content/Maps/SunkenLanternShrine.lua` | new map module | map 2: two lanes, water zones, pads, 15 waves |

The live schema was not available when this was written, so field names follow the architecture doc (`Rarity`, `Element`, `Levels`, `OnHit`, `Ability.Id`, `Income`, armor, CC resist). Rename fields while merging if the live Config differs. Each module's header describes its schema.

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
| Ozu Goldleaf | Legendary | Light | Economy | 90/200/360 per wave, −5% upgrade costs |
| Kurenai of the Eclipse | Mythic | Shadow | DPS | Pierce, Execute <12%; **Total Eclipse** |
| Aeris Dawnbreaker | Mythic | Light | DPS | Pierce 6→10, strips Shield/Phase; **Daybreak** full-path beam |
| Tokiya Clockveil | Exclusive | Arcane | Control | −10% ability cooldowns team-wide; **Time Stop** + rewind |

Rarity spread: Common 5, Rare 5, Epic 4, Legendary 3, Mythic 2, Exclusive 1. **Mythic** must exist in `TD.Rarities` (between Legendary and Exclusive). Each unit has a `Look` field written as a prompt for `generate_mesh` (chibi 3D style, same as the current models).

Suggested banner placement: Commons/Rares/Epics into the standard pool; Valka + Ryu as the first featured Legendaries; Mythics on rate-up banners only; Tokiya as an event/exclusive reward, not summonable.

## Enemies (10)

| Enemy | Armor | HP / Speed | Mechanic |
|---|---|---|---|
| Mudling | Flesh | 28 / 7 | Basic swarm |
| Skitter Moth | Swift, Flying | 22 / 11 | Needs CanHitAir |
| Shellback | Plated | 180 / 3.5 | Tank |
| Drift Wisp | Ethereal, Flying | 45 / 8 | Phase: untargetable 1 s every 5 s |
| Splitter Slime | Flesh | 90 / 5 | Splits into 3 Mudlings |
| Totem Bearer | Armored | 140 / 4.5 | Heals allies 6% every 3 s in 10 studs |
| Shield Drummer | Armored | 120 / 4.5 | Gives allies a 25% max-HP shield every 6 s |
| Burrower | Swift | 70 / 9 | Underground (untargetable) 2 s every 6 s |
| Hex Lantern | Ethereal, Flying | 95 / 5.5 | Disables the nearest unit for 2 s every 7 s |
| Iron Rhino | Plated | 320 / 4 | Charges ×2 speed below 50% HP, 50% CC resist |

## Bosses (3)

- **Gravemaw, the Moss-Shell Tyrant** (Plated, 3200 HP). Summons a Shellback every 12 s. At 66% and 33% HP it hides in its shell for 5 s (takes 20% damage, stops). Counter: burst between shells, Armor Break/Mark.
- **Noxra, the Veilwitch** (Ethereal, Flying, 2600 HP). Blinks 14 studs forward every 9 s, summons 3 Wisps every 10 s. Below 50% it disables 2 units at a time, below 20% it phases. Counter: anti-air + Light; Purify.
- **The Hollow Shogun** (Armored, 6000 HP, final boss). Cleanses its debuffs every 10 s. At 70% summons 2 Iron Rhinos and gains a shield, at 40% summons Hex Lanterns and adds 10 s to your ability cooldowns every 12 s, at 15% enrages ×1.6 speed and becomes immune to Execute.

## Map 2 — Sunken Lantern Shrine

Flooded hilltop shrine at dusk: turquoise shallow water, moss steps, floating paper lanterns, violet cherry trees, half-sunk torii gates.

- **Two lanes**: north portal (lane A, a long loop around a pond) and west portal (lane B, short) merge at the torii bridge, then one shared tail to the core. Waves can send enemies down A, B or both, so players must split defenses before the merge or stack at it.
- **Water zones**: two ponds where only `Placement = "Water"/"Any"` units (Sora for now) may stand. Gives water units a niche and a reason to collect them.
- **Lantern pads**: three raised pads on the bridge with +10% range, one unit each.
- **15 waves**, start money 650, bosses on wave 8 (Gravemaw), 12 (Noxra) and 15 (Hollow Shogun).

## New code needed to support this content

1. Attack types `Chain` (ChainCount, ChainFalloff) and `Pierce` (PierceCount); `Attack = "None"` for pure supports.
2. `CanHitAir` targeting filter + `Flying` enemies + `Grounded` status.
3. Statuses Poison, Freeze, Mark, Grounded; enemy states Shield, Phased, Burrowed.
4. Enemy mechanic handlers keyed by `Mechanics[i].Id`: Phase, SplitOnDeath, HealAura, ShieldAura, Burrow, DisableUnit, ChargeBelowHp, SummonEvery/SummonNow, Blink, ShellUp, ShieldSelf, CleanseEvery, StealTime, Enrage. Boss `Phases` trigger once when HP drops below `AtHpPct`.
5. Unit passives keyed by `Passive.Id` and auras (`Aura` on levels), plus the 13 abilities listed above.
6. Multi-lane waypoints and water-zone placement rule in `canPlaceAt` for map 2.

Order suggestion: (1)+(2) first; they unlock 14 of 20 units with no special abilities. Then enemies with simple mechanics (Splitter, Burrow, Phase), then bosses.
