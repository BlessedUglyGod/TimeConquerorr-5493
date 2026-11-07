# TD — Story Mode worlds and content guidelines

## Rule: world consistency (owner requirement, 2026-11-07)

Every Story Mode world has its **own** thematically fitting enemies, antagonists, bosses, environment and story. Enemies belong to their world; Story Mode never mixes unrelated enemies across worlds. Events, crossover challenges and other special modes (boss rush, raids, global events) may mix worlds on purpose.

Each world must eventually include:

1. Thematically consistent regular enemies.
2. Elite enemies and minibosses.
3. Major antagonists as stage bosses.
4. Distinctive abilities and combat mechanics.
5. Fitting environments and visual effects.
6. Progressive difficulty and connected story stages.
7. World-specific rewards and evolution materials.

Worlds are **inspired by genres** (ninja, spirit swordsmen, pirates, dungeon hunters, …). We hold no anime licenses, so every character, faction, name, design and asset is original. Do not reuse or lightly rename franchise characters, signature techniques, iconic terms (for example a franchise's name for its monsters or power-ups) or recognisable outfits.

Priority stays on the playable prototype; world content is merged in stages by the Studio session.

### Checklist for a new world
- One `content/Worlds/<WorldId>.lua` module with the fields below.
- Every `Pool`, `Miniboss`, `Boss`, `Enrage.Summon` and `Mechanics[].Spawn` id points to an enemy **of the same world**.
- At least 4 regular, 2 elite, 1 miniboss, 1 boss; 5 stages; 3 materials (Rare, Epic, Legendary).
- A `Look` prompt per enemy for model generation, written as an original design.
- Difficulty steps up from the previous world (see scale table).

## Module format (`content/Worlds/*.lua`)

| Field | Meaning |
|---|---|
| `Id, Name, Genre, Order` | `Order` = position in the story path |
| `Faction, Environment, Story` | design text (environment includes VFX notes) |
| `Enemies[id]` | live `Config.Enemies` schema (`Name, Health, Speed, Reward, Damage, Size, Color, Shape, Armor, CCResist, Boss, Enrage`) plus `World`, `Tier` (`Regular`/`Elite`/`Miniboss`/`Boss`), `Mechanics`, `Phases`, `Look` |
| `Stages[i]` | `Id, Name, Story, Waves, StartMoney, Pool = {enemyIds}, Miniboss?, Boss?` |
| `Materials[id]` | `Name, Rarity, Use` |
| `Rewards[stageId]` | `FirstClear = { Gems, Materials? }`, `Drops = { materialId = { Chance, Count } }` |

Merge: `for id, def in World.Enemies do Config.Enemies[id] = def end`. Enemy ids are unique across all content files. Wave lists per stage are generated from `Pool` (or hand-written later); the miniboss/boss spawns on the last wave.

## Worlds v1

| # | World | Genre | Faction | Miniboss | Boss | Materials |
|---|---|---|---|---|---|---|
| 1 | Ash Veil Valley | Ninja | Crow Mask Syndicate (rogue ninjas) | The Twin Fangs | Kagero of the Ninefold Mask | Ash Scroll, Crow Mask Shard, Ninefold Seal |
| 2 | Twilight Threshold | Spirit swordsmen | The Unmoored (spirits that refused to cross) | The Severed Judge | Yomikage, the Fallen Ferryman | Soul Lantern Wick, Verdict Chain, Ferryman's Coin |
| 3 | Saltfang Archipelago | Pirates | Blackbrine Crew + Iron Tide Navy | Commodore Vael Ironhull | Captain Redmaw Saltfang | Brine Doubloon, Iron Tide Compass, Saltfang Pearl |
| 4 | Gatefall City | Dungeon hunters | Gate monsters + the Ruin Court | Warden of the Red Gate | Morrag, the Ashen Sovereign | Gate Crystal, Red Gate Shard, Sovereign Core |

The existing map 2 (Sunken Lantern Shrine) with its yokai-style roster (`content/Enemies.lua`) can become a fifth world, a shrine/yokai world, or move to Challenge mode.

### World signatures
- **Ash Veil Valley**: speed and deception. Smoke clouds shrink unit range, decoys soak shots, the boss swaps masks to resist one element at a time, so players need mixed elements.
- **Twilight Threshold**: ethereal enemies and sword waves that disable a line of units. Light units and spread-out placement matter. The miniboss reflects (disables units that hit it during Reflect), and the boss sheds its disguise at 50%.
- **Saltfang Archipelago**: two factions on the same map. Pirates leap forward and explode, gulls steal money, the navy shields and tanks, cannons disable units. The boss heals once and calls a Cannon Crab.
- **Gatefall City**: the highest HP and the widest mix of armor. Spiders burrow, hounds phase, gargoyles fly, mimics steal 100 money on a leak. The boss opens a Gate behind the core and slows unit attack speed with an ash field.

### Scale (base Health, before +21%/wave)

| World | Regular | Elite | Miniboss | Boss | Start money |
|---|---|---|---|---|---|
| 1 | 40–90 | 300–420 | 2.2k | 4.8k | 300–350 |
| 2 | 60–200 | 480–600 | 3.0k | 6.2k | 325–375 |
| 3 | 70–260 | 800–950 | 4.2k | 8.0k | 350–400 |
| 4 | 150–520 | 900–1400 | 5.5k | 10k | 375–425 |

## New mechanic ids introduced by worlds
`SmokeCloud` (unit range multiplier in an area), `MaskSwap` (rotating element resistance), `SwordWave` (disables units on a line), `Reflect`, `Unbound` (boss form change), `ExplodeOnDeath` (disables nearby units), `StealMoneyOnLeak`, `CannonBarrage` (disables N units), `HealOnce`, `OpenGate` (spawns behind the core), `AshField` (unit cooldown multiplier). The others are shared with `content/Enemies.lua` (Phase, Blink, Burrow, DisableUnit, ShieldAura, HealAura, ChargeBelowHp, SummonEvery/Now, ShieldSelf, CleanseEvery, SplitOnDeath).

Suggested build order: `Blink`, `Phase`, `Burrow`, `SummonEvery` and `DisableUnit` cover most of world 1–2. Leave the rest for when those worlds are scheduled.
