# TD — Project status (for an external assistant)

_Last updated: 2026-11-07 20:55 UTC. Keep this file current when anything below changes._

Original anime-inspired tower defense for Roblox, place **TD** (placeId 116509641758969). All characters, names and assets are original; nothing may copy an existing franchise.

## Where the code lives
- **Roblox Studio is the source of truth.** Game code is not yet mirrored into this repo; it lives in the place. Plain-text backups: the owner exports a `.rbxlx`, and a copy of the docs sits in `ServerStorage.TDDocs`.
- **This repo** holds design docs and **data modules** (`content/`) that the Studio session merges into the live Config:

| Repo file | Merged into the place as |
|---|---|
| `content/Units.lua` | `Config.Units` (20 pack units, all live; see below) |
| `content/Enemies.lua` | `Config.Enemies` (map 2 enemies + 3 bosses) |
| `content/Elements.lua` | `Config.ElementChart` + statuses Poison, Mark |
| `content/Worlds/*.lua` | 4 Story worlds (enemies, stages, materials, rewards) |
| `content/Maps/SunkenLanternShrine.lua` | map 2 concept (not built) |
| `content/Evolutions.lua` | `Config.Evolutions` + evolved units via `build()` |
| `content/Progression.lua` | placement limits + Standard/UltraRare progression profiles |
| `docs/CONTENT_ROSTER.md`, `docs/STORY_WORLDS.md` | content schema and design rules |

## Architecture in the place (short)
- `ReplicatedStorage.TD`: `Config` (all data), `Rarities`, `Banners`, `HubConfig`, `Remotes`, `State` (match attributes).
- `ServerScriptService.TD.GameServer` bootstraps `ServerScriptService.TD.Services.*`:
  - Match: `MatchState`, `WaveService`, `EnemyService`, `UnitService`, `StatusService`, `MatchContext` and `Fx`. A match starts only from a validated `MatchContext { Mode, MapId, Stage, Difficulty, Party }`.
  - Meta: `PlayerDataService` (profile v1, session lock, autosave), `SummonService`, plus the evolution, trait reroll, team and match-result endpoints.
  - **Hub**: `HubService` is started by GameServer. It calls `HubBuilder`, which builds "Meridian Isle" from `HubConfig` at (0,0,400) at runtime only, and `HubBuilder` calls `HubDecor` for the decoration. The hub appears as `Workspace.Hub` during Play and is not saved in the place.
  - Multiplayer (design in PR #3, `docs/multiplayer/`): `PartyService`, `MatchLaunchService` and `MatchServerBridge`. Today it uses the local strategy; reserved servers in a separate Match place are ready but untested.
- Client: `StarterPlayerScripts.TD` (`TDClient` controller, `Hud`, `Menus`, plus the new UI screens built on one shared design system).
- `Workspace`: `TDMap` (Training Grounds) and `AshVeilValley` (Story world 1 map).
- Server-authoritative everywhere: clients send intent only, and every remote is validated and throttled.

## Live unit ids
- Original 6: `Spark` (Ren Voltblade), `Mortar` (Mira Emberfall), `Frost` (Yuki Frostveil), `Tycoon` (Baron Goldmane), `Kaze`, `Tora`.
- Pack units, first batch: `Pip`, `Hana`, `Gus`, `Rin`, `Momo`, `Kaito`, `Jin`, `Nami`, `Akane`, `Seren`.
- Pack units, second batch (live since 2026-11-07, module `TD.ContentPack2`, damage divided by 2.5 to fit the live scale): `Sora`, `Lumi`, `Haru`, `Daichi`, `Valka`, `Ryu`, `Ozu`, `Kurenai`, `Aeris`, `Tokiya`.
  - These abilities were seen firing in play: RiptideWave, Encore, Permafrost, Faultline, Thunderthrone, InfernoDive, TotalEclipse, Daybreak and TimeStop.
  - The passives Execute, Purify, Haggle and BorrowedTime are implemented, as is Lumi's aura.
- Standard banner: Mythic 0.5% (Kurenai, Aeris) and Common 59.5%. `Tokiya` is Exclusive, uses the UltraRare profile and is on no banner.
- Evolved units: 16 ids from `content/Evolutions.lua`, such as `KazeGalehawk` and `RenGatebreaker`.

## Done and verified in Studio (play mode via MCP)
- **Core TD loop:** placement, combat, upgrades, sell, abilities, target modes, Auto Abilities and Auto Upgrade, win/loss, rewards. Statuses: Slow, Stun, Burn, ArmorBreak, Poison and Mark. Element chart, flying enemies, Chain and Pierce attacks.
- **Infinite Mode:** endless scaling with a boss every 10 waves, rewards by wave reached and a personal best. Verified locally.
- **Story world 1, Ash Veil Valley:** map plus stages that unlock in order. Trying to start a locked stage is rejected, and the lobby marks locked stages in red.
- **Hub "Meridian Isle":** Story portal queue for 1–6 players, return to hub, stations, and 3D NPCs Luma and Oro with dialogue.
- **New UI** (one design system): hub HUD with PLAY and a mode board, Summon, Trait Reroll x1/x10, Collection Book, Units (team of 6, Level Up, Star Up), Evolution, Match Results, NPC dialogue and unified toasts. The combat HUD is separate from the hub HUD.
- **Evolution:** server endpoint and screen, verified on Kaze → Kaze Galehawk. Materials and Gold are spent, and level and trait carry over to the new unit. A request below the required level is rejected with a reason.
- **Per-player match wallets:** each player starts with $300 and spends only their own money. Kill and wave rewards go to each player's wallet. Income and sell refunds (70%) go to the unit's owner only, and nobody can upgrade or sell another player's unit.
- **Placement limits:** 10 units per player overall plus a per-unit limit, both per player. The unit button shows "3/4 placed", and an over-limit placement is rejected with "Limit reached: Ren Voltblade 4/4".
- **UltraRare profile:** no stars, full power from the first copy, duplicates give +500 Mastery XP, Star Up is hidden and the units screen shows "Full power" plus the mastery level. No ultra-rare unit is live yet, so this is untested in combat.
- **Summons** with pity and the x10 guarantee, plus the profile with team, levels, stars and traits.

## Open items / not verified
- A **2-player test** with Studio Team Test: wallets, ownership, portal queue.
- **DataStore persistence:** Studio API access is off, so profiles run in memory.
- **Cross-place teleports** to reserved match servers, which only work on a published place.
- **Mobile layout** on a real device, screenshots of the new UI and hub on PC, and the NPC model orientation.
- Server checks for awakening questlines (`Progression.Awakenings`, Tokiya).
- 3D models: the 10 second-batch units, the evolved units and most pack enemies still use primitive figures or the base model.
- Story worlds 2–4 (data in `content/Worlds/`), map 2 Sunken Lantern Shrine, and a `Secret` rarity in `TD.Rarities`.
- Mirroring the place source into this repo, which is waiting for an `.rbxlx` export from the owner.

## Open pull requests (repo)
- **#5:** evolutions, placement limits and progression profiles. Already integrated into the place; the PR only makes the repo match.
- **#2:** Meridian Isle hub design and drop-in Luau modules (branch `claude/project-thread-12tipa`).
- **#3:** mode lobbies and reserved match servers, design and drop-in code (`claude/project-thread-q9x3v4`).
- **#4:** Meridian UI design system, hub HUD and hub environment pass (`claude/project-thread-obtjna`).
- These PRs are not merged into `main`; their code is integrated into the place by the Studio session. Read their branches for the drop-in sources.

## Coordination with Astra (Codex, visuals)

### Zones
| Area | Owner |
|---|---|
| Game logic and data: waves, combat, abilities, match economy, placement limits, saves, awakening, stats of the remaining units, modes and matchmaking; hub transitions, interactions and match launch | **Claude** (Studio thread + this repo) |
| Visuals: original 3D models of units and enemies, portraits, icons, hub decor, screens and HUD for PC and mobile | **Astra** |

Astra's first task is one model of an existing unit plus its inventory card, to check the style and the integration before the whole roster is reworked.

### Shared files (who edits what)
- **`ServerScriptService.TD.Services.UnitService`** places units (logic, Claude) **and** builds their look through `buildFigure` (visual hook). Astra prepares models separately: a Model per unit id under `ReplicatedStorage.TD.UnitModels`, following the contract below. Wiring a new model into `UnitService` is **one agreed edit** made by Claude; Astra does not edit `UnitService` directly.
- **`ServerScriptService.TD.Services.EnemyService`** (`spawn`) works the same way: enemies are invisible roots moved along the path, and the model is welded to that root. Models go in `ServerStorage.TDEnemyModels`. Hub NPC models go in `ServerStorage.TDHubProps`.
- **`ServerScriptService.TD.Services.HubDecor`** belongs to Astra (decor only). **`HubBuilder`, `HubService` and `HubConfig`** belong to Claude (layout, portals, stations, interactions). New decor must not block portals, station prompts or the spawn.
- **Client UI** (`StarterPlayerScripts.TD`: `Hud`, `Menus`, the screens): Astra owns the look. Claude owns the data the screens read and the remotes they call. Changing a remote's name or payload needs a note here first.
- **`ReplicatedStorage.TD.Config`** belongs to Claude. Astra reads it and never writes to it.

### Model contract (live, confirmed by the Studio thread)
- **Where models go**

| Kind | Location |
|---|---|
| Unit | `ReplicatedStorage.TD.UnitModels/<unitId>` |
| Enemy | `ServerStorage.TDEnemyModels/<enemyId>` |
| Hub NPC | `ServerStorage.TDHubProps/Npc_<StationId>` |

- **Unit** (`UnitService.buildFigure`, owned by the Studio thread)
  - Any single `Model`, front facing local −Z, pivot at the geometric centre.
  - The code scales it to **6.2 studs** tall, places it 0.6 studs above a code-made pedestal `Base` (which carries the `LvN` billboard), and renames it `Visual`. All parts are forced Anchored and CanCollide false.
  - `FxClient` moves `Visual` with `PivotTo`, so the model must be **one Model**.
  - An optional BasePart named **`Muzzle`** is where projectiles start; without one, the first part is used.
  - No PrimaryPart, Root or attachments are required.
  - An evolved unit without its own model uses its base unit's model.
- **Enemy** (`EnemyService.spawn`)
  - Any Model, front facing −Z.
  - The code scales it to **`Size` × 1.3** studs tall, centres it on an invisible root and welds it unanchored.
  - The status ring and HP billboard are made by code. No parts are required.
- **NPC**
  - Any Model. The code scales it to **7.5 studs** tall, puts its bottom on the floor and turns it to face the station's CFrame.
- **Names the server reads:** only `Muzzle`. `FxOrigin`, `Overhead`, `HitPoint` and `Aura` are not read yet; they are optional and reserved for future use.
- Status tints are applied to the model's parts by code, so avoid textures that hide colour changes.
- Every asset must be original, with its source and licence listed in the asset manifest.

### Remotes and state (`ReplicatedStorage.TD.Remotes`)
- **RemoteFunctions**
  - `Summon(bannerId, 1|10)` → `ok, { Results = {{ Id, Rarity, Shiny }}, Pity, PityAt }`
  - `GetProfile()` → `{ Gems, Gold, Units = {{ Uid, Id, Shiny, Level }}, Team, Pity, Discovered, Progress[unitId] = { Level, Stars, Trait, MasteryXp }, Milestones, TraitRerolls, Materials, StoryCleared, InfiniteBest, Stats }`
  - `Progress("LevelUp"|"StarUp"|"RollTrait", unitId)` → `ok, msg`
  - `TraitReroll(unitId, 1|10)` → `ok, { Trait, Rolls }`
  - `SetTeamSync({ unitIds })` → `ok, why`
  - `Evolve(unitId, pathId)` → `ok, msg`
- **RemoteEvents**
  - Client to server: `PlaceUnit(unitId, Vector3)`, `UpgradeUnit(model)`, `SellUnit(model)`, `SetTargetMode(model, mode)`, `UseAbility(model)`, `SetAutoSetting("Ability"|"Upgrade", bool)`, `RequestStart`, `RequestReplay`, `SetTeam`, `LobbyAction(action, arg)`, `HubReturn`.
  - Server to client: `Notify`, `MatchResult` (`{ Won, Title, Wave, Rewards = {{ Icon, Label, Amount, Rarity }}, CanReplay }`), `LobbyState`, `HubOpenMenu(menuId, stationId)`.
  - Unreliable server to client: `CombatFx(kind, a, b, color, size, life)` with kinds `beam`, `lob`, `burst`, `ring`, `pillar` and `attack`.
- **Player attributes:** `Gems`, `Gold`, `TraitRerolls`, `Team`, `MatchMoney`, `HubLocation`, `AutoAbility`, `AutoUpgrade`.
- **`ReplicatedStorage.TD.State` attributes:** `Phase`, `Wave`, `MaxWaves`, `Lives`, `Countdown`, `EnemiesLeft`, `Mode`, `MapId`, `Difficulty`, `BossName`, `BossHp`, `StartMoney`.

### Entries per system (id → UI data → player action → server result)
| System | UI reads | Player action (remote) | Server result |
|---|---|---|---|
| Placement | `Config.Units[id]` (Cost, PlacementLimit), own wallet in the match, placed counts | `PlaceUnit(unitId, position)` | a unit is placed and money spent, or a refusal with a reason ("Limit reached: <Name> 3/3", "Unit limit 10/10", not enough money, bad position); the button shows "2/3 placed" |
| Upgrade / Sell | unit `Levels`, the owner | `UpgradeUnit(model)`, `SellUnit(model)` | owner only; the upgrade costs the owner's money, and selling refunds 70% to the owner |
| Ability | `Ability` (Name, Cooldown, Description) | `UseAbility(model)` | the effect plus the cooldown end time (server time) |
| Target mode | — | `SetTargetMode(model, mode)` | the mode is stored on the unit |
| Match wallet | player attribute `MatchMoney` | — | kill and wave rewards go to each player; income and sell refunds go to the unit's owner |
| Summon | `Banners`, `GetProfile().Pity` | `Summon(bannerId, 1 or 10)` | `ok, { Results, Pity, PityAt }` |
| Team | `GetProfile().Units`, `Team` | `SetTeamSync({ unitIds })` | `ok, why` |
| Level / Stars / Trait | `GetProfile().Progress[unitId]` | `Progress("LevelUp" / "StarUp" / "RollTrait", unitId)`, `TraitReroll(unitId, 1 or 10)` | `ok, msg` / `ok, { Trait, Rolls }` |
| Match end | — | `RequestReplay`, `HubReturn` | `MatchResult` event with rewards and `CanReplay` |
| Evolution | `Config.Evolutions[id]` (Materials, Gold, MinLevel, MinStars), `GetProfile().Materials` | `Evolve(unitId, pathId)` | `ok, msg`; the new unit keeps level and trait |
| UltraRare | profile id "UltraRare", `Progress[unitId].MasteryXp` | — | no star row; show "Full power" and the Mastery level; duplicates become +500 Mastery XP |

### Open tasks for Astra
- [ ] **First:** a model for `Kaze` in `ReplicatedStorage.TD.UnitModels/Kaze` plus its inventory card. Follow the live contract above: one Model, front facing −Z, pivot at the centre, optional `Muzzle` at the bow. The card reads `Config.Units.Kaze` and `GetProfile().Progress.Kaze`.
- [ ] Models for the 10 second-batch units: `Sora`, `Lumi`, `Haru`, `Daichi`, `Valka`, `Ryu`, `Ozu`, `Kurenai`, `Aeris`, `Tokiya`. Their look prompts are in `TD.ContentPack2` (and in `content/Units.lua` → `Look`).
- [ ] Models for the 16 evolved units (prompts: the `Look` fields in `content/Evolutions.lua`). Until a model exists, the base unit's model is used.

## Rules for any contributor
- Original content only, inspired by genres but never copied.
- Server-authoritative: never trust the client, and validate every remote.
- Story Mode never mixes enemies across worlds (see `docs/STORY_WORLDS.md`).
- Placement limits are per player. Ultra-rare units never need duplicates.
- The match logic never depends on the hub, and everything a match needs comes from `MatchContext`.
- No Prestige, no PvP, no real-money products without the owner's approval.
- Code and docs are in English; reports to the owner are in Russian.
