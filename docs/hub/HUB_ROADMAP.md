# Meridian Isle — hub roadmap

The TD combat loop comes first. The hub starts once the core loop is stable (it is: Phase 1 done, Phase 2 combat and the Phase 3 foundation are in) and grows alongside the game. Each hub phase ends with something players can use; nothing waits for a "big reveal".

Phase names are prefixed **H** so they do not clash with the game roadmap phases (P1–P4 in `ROADMAP.md`).

## H1 — basic working hub (now, after P2 combat)

Goal: players spawn in a hub, walk to a portal, play a match, come back. Existing systems are reachable from stations.

- [x] `HubConfig` (zones, portals, stations, hidden cogs, rules) — `src/ReplicatedStorage/TD/HubConfig.luau`
- [x] `HubBuilder`: island, Plaza, Meridian Spire, 8 zone platforms with walkways and signs, portal arches with queue pads, stations, NPC placeholders, waterfall + hidden ledge, Spire spiral, 3 Lost Cogs — primitives only
- [x] `HubService`: spawn in hub, portal queues (min/max players, countdown, status billboard), Local travel to `TDMap`, Teleport travel stub (reserved server + retry, off in Studio), station prompts → `HubOpenMenu`, `HubReturn`, auto-return after match, respawn on the right side, fall-off safety net, cog pickup
- [x] `HubClient`: menu registry, Return to Hub button, location listeners (hide battle HUD in the hub)
- [ ] Studio integration by the executor (see `INTEGRATION.md`): wire `canStartLocal`, `onTravel` → start flow, `onMatchEnded`, register `Summon` / `Team` menus
- [ ] Playtest: spawn, Story portal solo, 2-player queue, return, respawn during a match, Summon and Team from stations, mobile prompt tap

Active in H1: Story portal, Summon altar + banner board, Team desk, Clockkeeper Oro, Archivist Lumi (shows a toast until the Guide menu exists). Everything else is built but shows "Coming soon".

**Exit:** a new player can join, summon, set a team and start a match without touching the HUD buttons.

## H2 — the hub feels alive (with P3 content)

- Visual pass, zone by zone: modelled Spire with turning clock hands, orbiting gears, portal ripple shader-like textures, banners, lanterns, foliage. Keep `HubConfig` positions.
- Hub-only lighting and Atmosphere, applied on hub entry and restored on match entry (client-side).
- Ambient audio and per-zone sounds (original/licensed, logged in `ASSET_MANIFEST.md`).
- Open **Lantern Market** (Gold shop, Gem shop, Peddler Nim rotating stock), **Wayfarers' Hall** (daily/weekly quests, achievements), **Dusk Garden** (benches, AFK circle, emote stage, unit showcase pedestals).
- **Infinite** and **Challenges** portals when those modes exist; map/difficulty picker on the portal pad (party leader chooses).
- Plaza leaderboards (best wave, wins) and a news board.
- Summon cinematic on the Sanctum stage (camera + VFX) instead of only the UI window.
- Lumi tutorial: guided first session (summon → team → Story).
- Party system: invite friends, party leader steps on the pad for the whole party.

**Exit:** every P3 system has a physical station; the hub passes a mobile and a 6-player test.

## H3 — progression and secrets (with P4 meta)

- Split places: hub place + mode places. Portals switch to `Destination.Kind = "Teleport"` with reserved servers for parties of up to 6, `TeleportData` carries mode, map, difficulty, party.
- **Rift Overlook**: Dungeon, Raid, Boss Rush, Survival gates; global event gate with a world-wide progress bar.
- **Workshop** stations: Upgrade Forge (levels, evolution), Trait Well (traits, potential).
- Lost Cogs persisted in the profile; all cogs open the Spire's stopped-clock room (cosmetic title + emote). Seasonal hidden cogs.
- Daily login chest on the Plaza; season pass board.

## H4 — live and social

- Clan hall in the Wayfarers' Hall (clan banner on display, clan quests).
- Awakening chamber and transformation stage in the Workshop.
- Event re-skins of the hub (seasonal decorations swapped by config), event shop rotation.
- Trading post only for items the rules allow (normal units are never tradeable).
- Admin/live-ops: server-side toggles for portals and stations, hub announcements.

## Rules that apply to every phase

- No Studio edits outside the executor thread; hub code goes through the repo.
- Server-authoritative: queues, travel, rewards, shops, cogs.
- No real-money products without the owner's approval. No copyrighted characters, music or recognisable locations.
- Each new station = one entry in `HubConfig.Stations` + one menu registered in `HubClient`.
