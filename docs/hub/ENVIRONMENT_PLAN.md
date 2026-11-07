# Meridian Isle — environment plan (polished hub)

Builds on [HUB_DESIGN.md](HUB_DESIGN.md) (PR #2): same island, same zone positions in `HubConfig`, same stations. This plan turns the H1 test platform into a hub that feels like a finished anime game. It follows the owner's order: combat and Infinite Mode first; the hub's serious build starts when they work. Code for the first pass: `HubDistricts.luau` (data), `HubDecorator.luau` (server dressing), `HubAtmosphere.luau` (client lighting and motion).

## What is wrong with H1 today (from the Studio screenshots)

1. **Labels pile up.** Every zone sign, portal and station label is visible from the plaza at once and overlaps ("Raids/Dungeons/Challenges/Gate" in one cluster). Fix: `HubDecorator.tuneLabels` limits distances (zone signs 110, portals 80, stations 42 studs) and makes station labels smaller than zone signs; the HubHud location strip names the district you are in.
2. **Flat and empty.** Grey disks on green with nothing between them. Fix: gateways, trees, lanterns, props per district, height changes in H2b.
3. **Default lighting.** Midday Roblox sky, no atmosphere. Fix: hub-only golden-hour lighting with haze (HubAtmosphere), restored for matches.
4. **No motion.** Fix: turning gears, precessing halos, drifting petals, client-side only.
5. **Primitive NPCs** (block bodies). Fix in H2b: rigged original characters with idle animations and the dialogue UI (SCREENS.md).

## Art direction

- **Theme:** "sky sundial at golden hour": warm marble and brass clockwork, violet time-crystal light, pink blossom in the garden, deep purple sky toward dusk. It matches the UI's night-purple glass so the menus feel part of the place.
- **Silhouette first:** each district must read from the plaza by shape alone: gate arches (Gate Terrace), star pillars and halos (Sanctum), stall roofs (Market), giant gears (Workshop), blossom canopy (Garden), banners and notice pillars (Wayfarers' Hall), crystal spikes (Rift).
- **Colour discipline:** one accent per district (Theme `District.*`). Neon is only for interactables and a few landmark lights, so "glowing = usable" stays true.
- **Original only:** no recognisable shrines, schools or villages from other games or shows; shapes come from the clock/time theme.

## Districts

| District | Mood | Landmarks and dressing | Interactables | NPC |
|---|---|---|---|---|
| Meridian Plaza | open, bright, social | Spire with turning floating gears, 12 brass hour stones inlaid in the ring (12 o'clock glows teal, pointing at the Gate Terrace), four lamp posts | leaderboards, news board, daily chest (later) | Archivist Lumi (guide) |
| Gate Terrace | ceremonial, busy | row of mode gate arches with mode-colour membranes, mode pennants along the rim | Story, Infinite, Challenge, Survival, Event gates → mode lobbies | Gatewarden (lobby help) |
| Starfall Sanctum | mystical, night | six star pillars in a circle, two tilted halo rings over the altar, crystal trees | Summon altar, banner board | Seer (banner info) |
| Lantern Market | warm, lively | four stalls with coloured awnings, paper-lantern string, crates | Gold, Gem, Event shops | Peddler Nim |
| Cogwright Workshop | industrial-brass | three giant turning gears as a back wall, anvils with embers | Team desk, Upgrade Forge (Evolution), Trait Well (Trait Reroll) | Clockkeeper Oro |
| Dusk Garden | calm | blossom trees, pond with stepping stones, benches facing the centre, flower beds, drifting petals | AFK circle, emote stage, unit showcase pedestals | — |
| Wayfarers' Hall | adventurous | notice pillars, hanging banners | Quest board, Season Pass board | Questmaster |
| Rift Overlook | dangerous, endgame | crystal shards, basalt spikes at the rim, darker light | Dungeon, Raid, Boss Rush gates | Riftwatcher |

District gateways: every walkway enters its district through a "dial arch" (two marble pillars and an arc of brass ticks with the district accent at the keystone).

## Mode portals

All eight `ModeLobbyConfig` modes get a gate (`HubDistricts.ModeGates`). Story's gate already exists. Each gate is an arch plus a keystone station with `Menu = "Lobby_<Mode>"` that opens that mode's lobby. When a mode turns on, its old H1 queue-pad portal in `HubConfig.Portals` is removed and the keystone takes the pad's place. Positions in `ModeGates` are proposals to confirm in a Studio walk-through.

| Gate | District |
|---|---|
| Story, Infinite, Challenge, Survival, Event | Gate Terrace |
| Dungeon, Raid, Boss Rush | Rift Overlook |

## Lighting and atmosphere (`HubDistricts.Lighting`)

Clock time 16.6, warm sun, lilac-grey haze (Atmosphere density 0.32), light bloom with a high threshold (only neon blooms), slight contrast/saturation lift, faint sun rays. Applied when `HubLocation = "Hub"`, removed on match entry so combat lighting stays as built. H3: slow day-to-dusk cycle (16.0 → 19.0 over 20 minutes, then back) and night lanterns.

## Phases

| Phase | Content | Budget |
|---|---|---|
| **H2a — primitive dressing** (code in this PR) | `HubDecorator`: gateways, 46 trees, walkway lanterns, district props, label tuning; `HubAtmosphere`: lighting + motion | about 800 extra parts, under 40 lights |
| **H2b — modelled pass** | replace each prop kind with a mesh at the same positions (one kind at a time); terrain cliffs under the island; modelled Spire; real NPC rigs + idle animations; ambient audio per district | under 3,000 parts total, StreamingEnabled with one Model per district |
| **H3 — living hub** | day–dusk cycle, event re-skins by config, leaderboards and news board, daily chest, Spire secret room | — |

## Performance rules

- Decor parts: anchored, `CanTouch`/`CanQuery` off, `CanCollide` only for things you can walk into, `CastShadow` off on small parts.
- At most one in two walkway lanterns has a real light; neon carries the rest.
- Animation runs on the client only (`HubSpin` tag) and stops outside the hub.
- Fixed random seed, so every server builds the same island.

## Verification checklist (Studio thread)

- [ ] Walk every walkway: no props block the path, no floating or sunken props.
- [ ] Labels: from the spawn only zone signs are readable; station labels appear within ~40 studs.
- [ ] Lighting switches on Story gate travel and back.
- [ ] Mobile (844×390): HUD dock usable, labels readable.
- [ ] MicroProfiler in the hub: no RenderStepped spike from HubSpin.
