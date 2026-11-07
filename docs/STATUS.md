# TD — Project status (for an external assistant)

_Last updated: 2026-11-07 20:40 UTC. Keep this file current when anything below changes._

Original anime-inspired tower defense for Roblox, place **TD** (placeId 116509641758969). All characters, names and assets are original; nothing may copy an existing franchise.

## Where the code lives
- **Roblox Studio is the source of truth.** Game code is not yet mirrored into this repo; it lives in the place. Plain-text backups: the owner exports a `.rbxlx`, and a copy of the docs sits in `ServerStorage.TDDocs`.
- **This repo** holds design docs and **data modules** (`content/`) that the Studio session merges into the live Config:

| Repo file | Merged into the place as |
|---|---|
| `content/Units.lua` | `Config.Units` (20 pack units; 10 live, see below) |
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
- Pack units live: `Pip`, `Hana`, `Gus`, `Rin`, `Momo`, `Kaito`, `Jin`, `Nami`, `Akane`, `Seren`.
- Not integrated yet: `Sora`, `Lumi`, `Haru`, `Daichi`, `Valka`, `Ryu`, `Ozu`, `Kurenai`, `Aeris`, `Tokiya`. They need new ability code: RiptideWave, Encore, Permafrost, Faultline, Thunderthrone, InfernoDive, TotalEclipse, Daybreak and TimeStop, plus the passives Haggle, Execute, Purify and BorrowedTime.
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
- The 10 unintegrated units above, and server checks for awakening questlines (`Progression.Awakenings`, Tokiya).
- 3D models for evolved units; most pack units and pack enemies still use primitive figures.
- Story worlds 2–4 (data in `content/Worlds/`), map 2 Sunken Lantern Shrine, and a `Secret` rarity in `TD.Rarities`.
- Mirroring the place source into this repo, which is waiting for an `.rbxlx` export from the owner.

## Open pull requests (repo)
- **#5:** evolutions, placement limits and progression profiles. Already integrated into the place; the PR only makes the repo match.
- **#2:** Meridian Isle hub design and drop-in Luau modules (branch `claude/project-thread-12tipa`).
- **#3:** mode lobbies and reserved match servers, design and drop-in code (`claude/project-thread-q9x3v4`).
- **#4:** Meridian UI design system, hub HUD and hub environment pass (`claude/project-thread-obtjna`).
- These PRs are not merged into `main`; their code is integrated into the place by the Studio session. Read their branches for the drop-in sources.

## Rules for any contributor
- Original content only, inspired by genres but never copied.
- Server-authoritative: never trust the client, and validate every remote.
- Story Mode never mixes enemies across worlds (see `docs/STORY_WORLDS.md`).
- Placement limits are per player. Ultra-rare units never need duplicates.
- The match logic never depends on the hub, and everything a match needs comes from `MatchContext`.
- No Prestige, no PvP, no real-money products without the owner's approval.
- Code and docs are in English; reports to the owner are in Russian.
