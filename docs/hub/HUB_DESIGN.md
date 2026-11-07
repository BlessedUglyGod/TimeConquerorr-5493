# Meridian Isle — main hub design

The hub is where every session starts and ends. It is a floating island built around a broken clock tower: the game's theme is conquering time, so each zone is a "district" of a giant sundial, laid out like hours on a clock face. Players should be able to read the whole island from the spawn point, reach any major system in under 15 seconds of walking, and always see where the play button is.

This document covers the full vision. What gets built when is in [HUB_ROADMAP.md](HUB_ROADMAP.md); how the code plugs into the prototype is in [INTEGRATION.md](INTEGRATION.md).

## Pillars

1. **Play is one step away.** The Story portal is straight ahead of spawn, past the Spire. Everything else is optional.
2. **Every system has a place.** Summon, team, upgrades, shops, quests and social features each live in a physical station, so new players learn the game by walking around. Every station also has a menu shortcut in the HUD for veterans.
3. **Readable at a glance.** One landmark in the middle, each district a different colour and floor material, signs at every entrance, light beams over the important stations.
4. **Grows without a rebuild.** Districts from later phases are already on the map, fenced with a translucent barrier and an "Opening soon" sign. Turning one on is a config change (`HubConfig.Zones[*].Phase`, `Stations[*].Enabled`, `Portals[*].Enabled`).

## Layout

Top-down, north is -Z. Angles are clockwise from north, radii from the island centre (island radius 170 studs).

```
                         N (0°)
                   [ Gate Terrace ]
             Story · Infinite · Challenges
     Rift Overlook                    Starfall Sanctum
   (320°) Dungeons·Raids              (60°) Summon altar, banners
                   \                 /
 Wayfarers' Hall —— MERIDIAN PLAZA —— Lantern Market
  (285°) quests,     Spire, spawn,     (115°) gold/gem/event
  season pass,       guide NPC,         shops, merchant NPC
  clans later        leaderboards
                   /                 \
       Dusk Garden                    Cogwright Workshop
   (225°) social, AFK,                (170°) team & collection,
   photo spots, stage                 upgrade forge, trait well
                         S (180°)
              waterfall gap · hidden ledge
```

| Zone | Angle / radius | Purpose | Stations and NPCs | Hub phase |
|---|---|---|---|---|
| Meridian Plaza | centre | Spawn, orientation, social hub | Meridian Spire (landmark), Archivist Lumi (guide / tutorial NPC), leaderboards and news board (H2), daily login chest (H3) | H1 |
| Gate Terrace | 0° / 115 | All play modes | Portals: Story (H1), Infinite, Challenges (H2+). Each portal has a queue pad, a party counter and a countdown | H1 |
| Starfall Sanctum | 60° / 110 | Summoning | Summon altar (x1 / x10), banner board with featured units and timers, pity display, summon cinematic stage (H2) | H1 |
| Cogwright Workshop | 170° / 112 | Unit progression | Team & Collection desk, Clockkeeper Oro (NPC), Upgrade Forge (levels, evolution), Trait Well (traits / potential), Awakening chamber (H4) | H1 desk, H2+ rest |
| Lantern Market | 115° / 112 | Shops | Gold shop, Gem shop, Event shop, Peddler Nim (rotating stock). Robux products only after owner approval | H2 |
| Wayfarers' Hall | 285° / 112 | Goals | Quest board (daily / weekly), Season pass board, achievements, clan registry (H4) | H2 |
| Dusk Garden | 225° / 110 | Social space | Benches, AFK circle, emote stage, photo spots, unit showcase pedestals (players display a favourite unit), trading post later only for tradeable items | H2 |
| Rift Overlook | 320° / 120 | Endgame | Dungeon and Raid portals, global event gate, boss rush / survival gates | H3 |

### Hidden areas

Hidden areas reward exploration and give regulars something to show friends. All three exist in the H1 geometry; the reward comes in H3.

- **Spire summit.** Floating stepping stones spiral up around the Spire to its top ring. Lost Cog #1 sits by the crystal.
- **Behind the waterfall.** The south rim has a gap with a waterfall pouring off the island. A stair hugs the cliff and turns in under the overhang to a hidden ledge. Lost Cog #2.
- **Edge of the world.** A cog tucked by the rim behind the Wayfarers' Hall. Lost Cog #3.
- Later: a "stopped clock" room inside the Spire opened by finding all cogs (cosmetic title + hub emote), seasonal hidden cogs during events.

Found cogs are tracked per player (`HubCogs` attribute now, profile field in H3). Hidden areas never give power, only cosmetics, so missing them never hurts progression.

## Visual direction (original)

- **Theme:** "sky sundial". Warm white marble and brass clockwork against a deep twilight sky, with teal time-crystal light as the accent. Not a copy of any existing game's hub: no anime-school courtyards, no ninja villages, no recognisable landmarks.
- **Palette** (`HubConfig.Palette`): marble `#E2DCCD`, brass `#D6A848`, twilight `#282C50`, time-teal `#46DCD2`, rose `#F07896`, violet `#966EF0`, ember `#FA9646`. Each district gets one accent: Gates teal, Sanctum violet, Workshop brass, Market ember, Garden rose, Rift twilight.
- **Shapes:** round platforms and arches (clock faces, gears, rings). Paths radiate from the Spire like clock hands.
- **Lighting (H2):** a slow day–dusk cycle in the hub only, soft bloom, Atmosphere with a light haze so the island floats. Neon is reserved for interactables (portals, altar cores, queue pads) so players learn "glowing = usable".
- **Motion (H2):** Spire clock hands turn, floating gears orbit the Spire, portal membranes ripple, banner board cycles featured units, ambient particles (dust motes, petals in the Garden).
- **Audio (H2):** original or licensed ambient loop, per-zone ambience, portal hum, summon chime. Logged in `ASSET_MANIFEST.md`.
- **Assets:** H1 uses only primitive parts and built-in materials, built by `HubBuilder`. H2 swaps in modelled meshes zone by zone without changing positions, because every station reads its position from `HubConfig`.

## Flow

1. Join → spawn on the Plaza facing the Gate Terrace. First-time players get a short Lumi tutorial: walk to the Summon altar, pull the free starter x10, set the team at the Workshop, step on the Story pad (H2).
2. Step on a portal pad → join that portal's queue (up to the portal's `MaxPlayers`, 6 for co-op). Countdown starts at `MinPlayers`; leaving the pad leaves the queue.
3. Countdown ends → the group travels. Prototype: characters move to `Workspace.TDMap` in the same place. Later: a reserved server in a mode place via `TeleportService`, with `TeleportData = { Mode, PortalId }`.
4. Match ends → players return to the hub automatically after 10 s, or press **Return to Hub**.

## Systems map

| System | Where in the hub | Menu id | Backed by |
|---|---|---|---|
| Summon | Starfall Sanctum altar + banner board | `Summon` | existing `SummonService`, `Menus` summon window |
| Team & Collection | Workshop desk, Clockkeeper Oro | `Team` | existing `Menus` team window |
| Upgrade / evolve | Workshop forge | `Upgrade` | to build |
| Traits / potential | Workshop trait well | `Traits` | to build |
| Shops | Lantern Market | `ShopGold`, `ShopEvent` | to build |
| Quests / season pass | Wayfarers' Hall | `Quests`, `Pass` | to build |
| Guide / tutorial | Plaza, Archivist Lumi | `Guide` | to build |
| Play modes | Gate Terrace, Rift Overlook | portal queues | `HubService` |

## Technical notes

- The hub is a `Folder` `Workspace.Hub`, built at server start by `HubBuilder.build()` from `HubConfig`. It sits at `HubConfig.Origin = (0, 0, 400)` (island spans z 230..570), clear of `Workspace.TDMap` around the origin.
- Part budget for H1: about 250 parts. H2 target under 3,000 parts with StreamingEnabled-friendly models (one Model per zone).
- Security: queues, travel, station access and cog pickup are decided on the server. The only client remote is `HubReturn` (no arguments, throttled, only works while in a match). Stations open menus through server-fired `HubOpenMenu`; the menus themselves still validate every action on the server as they do today.
- Mobile: stations use `ProximityPrompt`, which has a tap button on touch devices; portals need only walking. The Return button is 150×44 px.
