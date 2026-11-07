# Screens — one layout per system

Every system gets its own layout, presentation and interaction built from the shared parts in [UI_DESIGN_SYSTEM.md](UI_DESIGN_SYSTEM.md). Shared across all of them: the system rail (PC), the currency bar, tokens, motion and input rules. Everything else on this page is system-specific.

Status key: **Spec** = layout agreed, **Code** = Luau in this repo, **Live** = integrated in Studio.

| System | Station in the hub | Backend today | Status |
|---|---|---|---|
| Hub HUD + Gate Board | — | player attrs, `ModeLobbyConfig` | Code |
| Summon | Starfall Sanctum altar + banner board | `Summon` RemoteFunction, `Banners`, `SummonService` | Spec (code next) |
| Trait Reroll | Workshop, Trait Well | traits on units (Phase 3) | Spec (code next) |
| Units / Team | Workshop desk, Clockkeeper Oro | `SetTeam`, `GetProfile` | Spec |
| Collection Book | Workshop desk tab | `Profile.Discovered` | Spec |
| Mode lobby | Gate Terrace gates | `PartyService`, `LobbyClient` (PR #3) | Spec (restyle of PR #3 window) |
| Evolution | Workshop, Upgrade Forge | to build (Phase 3 remainder) | Spec |
| NPC dialogue | every NPC | to build | Spec |
| Results | match end | `WaveService` rewards | Spec |
| Shops, Quests, Pass, Inventory, Ability manager, Crafting, Awakening, Trading, Dungeon board | their districts | to build | Outline |

---

## Hub HUD (Code: `HubHud.luau`)

Not a window: the frame around the world while you walk the hub.

- **Top left: player plate.** Display name in Oswald, currency chips (Gems, Gold) bound to the server attributes, pulsing on gain.
- **Top centre: location strip.** The district you stand in (from `HubConfig` zones), with a short tick in that district's accent. Fades in on arrival. Replaces most floating labels for orientation.
- **Right edge: dock.** PLAY (violet, largest) then Summon, Units, Collection, Quests, Shop, Pass. A tile whose menu has no handler is shown dimmed and says "Coming soon" when tapped; it lights up when the handler is registered.
- **Compact:** the dock becomes a bottom bar with PLAY in the middle, two-wide.

### Gate Board (Code)

PLAY opens a horizontal row of tall mode cards, one per `ModeLobbyConfig` mode: a mode-colour band at the top, mode glyph, name, party size, and a state line ("Open lobby" or why it is locked: "Opens in a later update", "Reach account level 10"). Enabled → `LobbyClient.open(mode)`. The physical gates on the Gate Terrace open the same lobbies; the board is the shortcut for regulars.

---

## Summon (Spec — code next)

**Identity:** a stage, not a form. The banner art fills the window; controls sit on top of it.

### Layout (Regular)

```
┌ rail ┬───────────────────────────────────────────────────────────────┐
│      │ [banner tabs: Standard · Featured · Event]           ✕       │
│      │ ┌──────────────────────────── banner stage ────────────────┐ │
│      │ │ banner title (title image / Oswald Hero)    ends in 2d 4h│ │
│      │ │                                                          │ │
│      │ │   featured unit 3D preview      featured list (2-3 cards)│ │
│      │ │   (ViewportFrame, idle spin)    with rarity frames       │ │
│      │ │                                                          │ │
│      │ └──────────────────────────────────────────────────────────┘ │
│      │  pity ▓▓▓▓▓▓▓░░░ 62/90 to Mythic   [Rates ⓘ]                │
│      │                      [ SUMMON x1  ◆50 ]  [ SUMMON x10 ◆450 ] │
└──────┴───────────────────────────────────────────────────────────────┘
```

- **Banner tabs** come from `Banners` (only active ones, by `dates`). Each banner can set its own backdrop image and accent; default backdrop = night sky + its rarity colour.
- **Featured** list from the banner's `featured`; tapping a card swaps the 3D preview.
- **Pity bar** from the profile's `Pity[bannerId]` and the banner's pity threshold; label says what it guarantees.
- **Rates** opens an overlay table (rarity colour, %, from the banner's rates), the same `rarityTable` part Trait Reroll uses.
- **x1 / x10** show the cost tag; disabled with the reason when gems are short ("Need 120 more gems"). x10 gets the magenta emphasis edge and states its guarantee.
- **Compact:** tabs become a dropdown; the preview shrinks to the upper half; buttons become a full-width pair at the bottom.

### Summon sequence

1. Press → buttons lock, the server call runs (`Summon` RemoteFunction: banner id + count). The UI never rolls anything.
2. **Charge (0.6 s):** the stage darkens, a ring of light gathers at the centre.
3. **Reveal:** results flip in one by one (x10: a 5×2 grid, 0.12 s apart). Each card's frame takes its rarity colour as it flips.
4. **Rare presentation:** Legendary and above interrupt the grid: full-stage flash in the rarity colour, the unit's 3D preview with name in Hero type, a 1.2 s hold, tap to continue. Mythic/Exclusive add the magenta burst. Shiny adds a sparkle sweep.
5. **Summary:** grid of all results; "NEW" badge on first-time units (`Discovered`), Skip button available from step 2 on.

---

## Trait Reroll (Spec — code next)

**Identity:** a ritual at the Trait Well. The selected unit stands on the left; the current trait "transforms" into the new one in the centre.

### Layout (Regular)

```
┌ rail ┬─────────────────────────────────────────────────────────────────┐
│      │ TRAIT REROLL  (title image)                               ✕     │
│      │ ┌ unit ───────────┐ ┌ current trait ──────┐ ┌ trait odds ─────┐ │
│      │ │ 3D preview      │ │ [icon] trait name  │ │ Common   65.00% │ │
│      │ │ (idle, aura in  │ │ +35% dmg, -10% SPA  │ │ Rare     22.00% │ │
│      │ │  trait colour)  │ └─────────────────────┘ │ Epic      9.00% │ │
│      │ │                 │        ⌄ ⌄              │ Legendary 3.00% │ │
│      │ │ Lv 60 · name    │ ┌ new trait ──────────┐ │ Mythic    0.80% │ │
│      │ │ rarity · stars  │ │  ?   reroll to get  │ │ Exclusive 0.20% │ │
│      │ └─────────────────┘ └─────────────────────┘ └─────────────────┘ │
│      │                 [☐ 🔒 Lock current trait   ✦10]                  │
│      │                 [ REROLL x1  ✦1 ]   [ REROLL x10  ✦10 ]          │
│      │ ┌ unit strip: owned units, lv, rarity frame ┐ [filter][sort]    │
└──────┴─────────────────────────────────────────────────────────────────┘
```

- **Unit strip** (shared `unitStrip` part): owned units from `GetProfile`, filter by rarity, sort by level/rarity; selecting one fills the left column.
- **Current trait card**: name in the trait's rarity colour, its effects as plain lines (from the trait definitions in `Config`).
- **New trait card**: "?" until a reroll; after a reroll it shows the result with Keep / Revert if the server supports a pending result, otherwise the result replaces the current trait directly (state the rule in the card's caption).
- **Odds table** = `rarityTable`, values from the server's trait rarity table, never hard-coded in the UI.
- **Lock current trait**: toggle with its own cost; only shown when the server supports locks. A locked trait greys out both reroll buttons with the reason.
- **x10**: rolls until the server's stop rule (e.g. stop on Legendary+) and shows the best result; caption states the rule.
- **Confirm** modal before replacing a Legendary or better trait.
- **Compact:** unit column becomes a header row (small preview + name), odds collapse behind an ⓘ button, unit strip stays at the bottom.

### Reroll sequence

1. Press → server call (unit uid, count, lock). Buttons lock, cost tag ticks down.
2. **Spin (0.5 s):** the new-trait card cycles rarity colours, slowing down.
3. **Land:** card settles on the result rarity with the `Emphasis` pop; the unit's aura in the 3D preview recolours.
4. **Rare reveal (Legendary+):** stage dims, the trait name in Hero type with a rarity burst, hold 1 s.
5. Odds table highlights the row that hit.

---

## Units / Team (Spec)

**Identity:** a roster wall. Grid of unit cards (portrait, rarity frame, level, stars, element), six team slots pinned across the top; drag a card onto a slot (PC) or tap card → tap slot (touch). Detail drawer slides from the right with stats, abilities, trait, and buttons that jump to Trait Reroll / Evolution with that unit selected. Backend: `GetProfile`, `SetTeam`.

## Collection Book (Spec)

**Identity:** a bound book, not a grid dump. Pages per world/element, silhouettes for undiscovered units, discovered ones in colour with first-summon date; page footer shows completion % and the milestone reward track (Collection milestones, Phase 3 remainder). Backend: `Profile.Discovered`.

## Mode lobby (Spec — restyle of PR #3)

Keep PR #3's structure (browse parties / in party) and add identity: the chosen mode's colour on the header rule and gate card, the chapter's art as the settings column backdrop for Story, party slots as six tall portrait cards with READY states (green rule + check), Start as the only Primary button. Countdown uses Timer type in the header.

## Evolution (Spec)

**Identity:** before → after. Two 3D previews side by side with an arrow of light between them; stat deltas listed in the middle (green up, red down); below, material slots with owned/needed counts (each slot links to where to get it: stage, shop, quest) and quest steps with progress bars; branching evolutions show path tabs. Evolve plays a transformation: silhouette flash, swap, Hero-type new name.

## NPC dialogue (Spec)

**Identity:** a visual-novel strip at the bottom third. Speaker nameplate in the NPC's district accent, portrait or a ViewportFrame bust on the left, text typed at 40 chars/s (tap completes the line, tap again advances), 2–4 choices as stacked buttons on the right. Choices can open systems (shop, quest board, lobby) through the same menu ids as stations. The camera eases toward the NPC while talking; the hub HUD hides.

## Results (Spec)

Victory/defeat banner in Hero type (Positive/Danger rule), stars earned, rewards flipping in with rarity frames, per-player damage bar list for parties, then Replay / Return to Hub. Shown in `UiState = Results` over the combat scene.

## Outline (to spec when each system is built)

- **Shops:** shelf layout per shop (Gold shop = market stall with item tiles and stock timers; Event shop = event-themed board with currency of that event).
- **Quests:** pinned daily/weekly columns with claim stamps; Season Pass: horizontal track with free/premium rows.
- **Inventory:** category tabs on the left, item grid, detail panel with "use" / "where from".
- **Ability manager:** unit's ability slots with cooldown dials, auto-cast toggles.
- **Crafting / Awakening:** recipe on a forge table / awakening circle with material ring.
- **Trading:** two mirrored offer grids, both-side confirm with a 3 s lock.
- **Dungeon board:** map-style cards with modifiers and weekly reset timer.
