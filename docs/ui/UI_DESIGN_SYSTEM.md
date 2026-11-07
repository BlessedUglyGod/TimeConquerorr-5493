# Meridian UI — design system

One visual identity for every hub screen and menu; a distinct layout for every system. Code: `src/ReplicatedStorage/TD/UI/` (`Theme`, `Icons`, `UiKit`). Per-screen layouts: [SCREENS.md](SCREENS.md). Install steps: [INTEGRATION.md](INTEGRATION.md).

## Direction

Taken from the owner's reference image (2026-11-07), adapted, not copied:

- **Night-purple glass.** Panels are semi-transparent dark violet, so the hub stays visible behind them. Readability comes first: an open window dims the world with a scrim, panel fills never go lighter than `Base`, and text is never transparent.
- **Violet accent, magenta emphasis.** Violet marks what you can press. Magenta is saved for moments: x10, rare reveals, "new".
- **Rarity is the loudest colour.** Common grey → Rare blue → Epic purple → Legendary gold → Mythic magenta → Exclusive red. It appears only on units, traits and rewards, so it always means something.
- **Layered, angular panels.** Small corner radii (3–6 px), 1 px strokes, corner brackets on windows and selected cards, cards stacked on the window glass. No pill shapes, no soft blobs.
- **Anime title-card type.** Condensed uppercase display titles over a clean sans body.

What we avoid, on purpose: gradient fills, glow-on-everything, drop-shadow stacks, default Roblox grey buttons, `SetCore` notifications, full-width coloured header bars, emoji as icons, and the same centred rectangle for every system.

## Tokens (`Theme.luau`)

UI code never writes a literal colour, font, size or duration. It reads a token.

### Colour

| Token | RGB | Use |
|---|---|---|
| `Base` | 22, 14, 38 @ 0.22 transparency | windows, dock, chips |
| `Raised` | 38, 24, 64 @ 0.30 | cards inside a window |
| `Overlay` | 58, 38, 94 | hover, selected rows, inputs |
| `Scrim` | 6, 4, 14 @ 0.50 | dims the world behind a window |
| `Stroke` / `StrokeStrong` | 92, 68, 140 / 168, 128, 240 | hairlines / focus, brackets |
| `Text` / `TextMuted` / `TextFaint` | 246, 240, 255 / 184, 172, 214 / 126, 114, 160 | three text levels, no more |
| `Accent` (+Hover/Pressed) | 150, 96, 246 | primary actions, selection |
| `Emphasis` | 226, 92, 214 | x10, rare reveals, new badges |
| `Interactive` | 78, 214, 204 | world-linked UI (gates, location strip): the hub's "glowing = usable" colour |
| `Positive` / `Warning` / `Danger` | green / amber / red | status only |
| `Gems` / `Gold` / `TraitShard` | | currency chips and cost tags |
| `Rarity.*` | see Theme | units, traits, rewards only. Prefer `TD.Rarities` colours where defined, so world and UI agree |
| `District.*`, `Mode.*` | | one accent per hub district / game mode (rule under titles, gate cards) |

Contrast: `Text` on `Base` over a white sky with the scrim on is above 7:1; `TextMuted` stays above 4.5:1. Don't put `TextFaint` on anything that must be read (it is for disabled states and hints).

### Typography

| Role | Face | Size (px @ 1280×720) |
|---|---|---|
| Hero (results, reveals) | Oswald Bold, uppercase | 44 |
| Headline (unit / mode names) | Oswald Bold | 30 |
| Title (window titles) | Oswald SemiBold, uppercase | 22 |
| Label (buttons, tabs) | Oswald SemiBold, uppercase | 15 |
| Body | Builder Sans Regular/Medium | 16 |
| Caption (hints, counters) | Builder Sans Medium | 13 |
| Timers | Roboto Mono Medium | 16 |

All built in: no font uploads. Titles in the reference use a brush script; Roblox has no brush face, so each system's title can be an uploaded title image (one per system, original lettering, logged in `ASSET_MANIFEST.md`) with the Oswald title as the fallback.

### Space, shape, size

- 4 px grid: `XS 4 · S 8 · M 12 · L 16 · XL 24 · XXL 32`. Window padding is XL; gaps between cards are M.
- Radii: chips 3, buttons/cards 4, windows 6.
- Buttons 40 px high; anything tappable is at least 44 px after scaling on touch (`Theme.TouchTarget`).
- Windows: 480×320 to 880×580 at scale 1; full screen minus 16 px gutter in the Compact layout.

### Motion

| Token | Duration / easing | Use |
|---|---|---|
| `Fast` | 0.12 s Quad Out | hover colour, press scale 0.96 |
| `Enter` | 0.22 s Quint Out, 12 px rise + fade | windows, toasts, cards |
| `Exit` | 0.14 s Quad In | closing (exits faster than entries) |
| `Emphasis` | 0.36 s Back Out | reward pop, rarity reveal, badge |

System animations (summon, reroll, evolution) are choreographed per screen from these, never with other easings. Nothing loops forever in a menu except a reveal's ambient shimmer.

### Layers

`ScreenGui.DisplayOrder`: TDHud (combat) 10 · HubHud 20 · windows 30 · modals 40 · toasts 50 · loading curtain 60. Hub UI never shares a ScreenGui with TDHud.

## Components (`UiKit.luau`)

Building blocks, not layouts. Every screen composes them into its own arrangement.

| Component | What it gives |
|---|---|
| `screen(name, layer)` | ScreenGui with the shared UIScale, safe-area insets, `ResetOnSpawn = false` |
| `window{...}` | scrim + glass frame + title + short accent rule + close (44 px) + brackets; one open at a time; Esc / gamepad B / scrim tap closes; Compact = full screen |
| `surface(parent, level)` | Base / Raised / Overlay glass with stroke |
| `button{Text, Variant, OnActivated}` | Primary / Secondary / Ghost / Danger; hover, press scale, `setEnabled(false, reason)` shows the reason as a toast when tapped |
| `chip(parent, icon, colour)` | currency counter, pulses on gain |
| `progress(parent, colour)` | pity, quest, XP, pass bars |
| `icon(parent, id, size)` | uploaded icon or the glyph fallback |
| `brackets(parent, colour)` | the corner bracket detail |
| `toast(text, kind)` | replaces `SetCore("SendNotification")`; max 3 |
| `layout()` / `onLayoutChanged` / `scale()` | Compact vs Regular, responsive scale |

Planned next (built when the first screen needs them): `tabs`, `unitCard` (portrait, rarity frame, level, stars, lock), `unitStrip` (bottom unit selector with filter/sort, used by Traits, Evolution, Units), `costTag`, `rarityTable`, `confirmModal`, `viewport` (3D unit preview with idle spin), `systemRail` (left system switcher, see below).

## Icons (`Icons.luau`)

One icon language: 24 px grid, 2 px rounded strokes, one filled detail in the icon's tint, no outlines-plus-shadow, no gradients, original shapes. Each icon id has an `Asset` (empty until uploaded) and a 1–2 letter glyph fallback drawn on a tinted tile, plain enough that nobody mistakes it for final art. The set to draw: navigation (Play, Summon, Units, Inventory, Traits, Evolution, Collection, Quests, Shop, Pass, Settings, Close, Back, Lock, Filter, Sort, Info), currencies (Gems, Gold, Trait Shard, per-world materials), the eight modes, elements.

## Responsive layout

- Reference 1280×720. `UIScale = clamp(min(w/1280, h/720), 0.72, 1.35)`.
- **Regular** (PC, tablets landscape): dock column on the right edge, player plate top left, location strip top centre.
- **Compact** (short side < 560 px, or touch without keyboard): dock becomes a bottom bar with Play in the centre under the thumb; windows go full screen; side panels inside screens stack vertically or become tabs. Each screen spec says what moves.
- `ScreenInsets = DeviceSafeInsets` on every ScreenGui (notches, the Roblox top bar).

## System shell

The reference's left-hand list of systems becomes the **system rail**: when any system window is open on PC, a narrow rail on its left lists Summon · Units · Inventory · Traits · Evolution · Quests · Shop, so players hop between systems without closing. Only the rail and the currency bar are shared; the content area of each system has its own layout ([SCREENS.md](SCREENS.md)). On Compact the rail collapses to a "back" button plus the system title.

## Hub UI vs combat HUD

- `UiState` (client): `Hub` shows HubHud; `ModeLobby` shows the lobby window over the hub; `Loading` shows only the curtain; `Match` shows only TDHud; `Results` shows the results screen over TDHud.
- HubHud's `setVisible` follows `UiState == "Hub"`; any open hub window closes when leaving Hub.
- The combat HUD keeps its own layout. It may read `Theme` tokens later for colour and type consistency, but nothing in the hub depends on it.

## Rules for every new screen

1. Start from the screen's spec in SCREENS.md; if it has none, write it first.
2. Use tokens and UiKit parts; no literal colours, fonts or durations.
3. Every button does something real or shows why it can't (`setEnabled(false, reason)`). No placeholder buttons.
4. The server decides: screens send intent and render the server's answer.
5. Check Compact at 844×390 (phone landscape) and Regular at 1920×1080 before calling a screen done.
