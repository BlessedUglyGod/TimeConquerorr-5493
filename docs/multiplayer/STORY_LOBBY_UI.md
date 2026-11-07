# Story lobby UI (minimal spec)

Code: `src/StarterPlayerScripts/TD/LobbyClient.luau`. Server: `PartyService`. Data: `ModeLobbyConfig` (mode `Story`, `Layout = "Story"`).

## Entry

The **Story Gate** in the hub (Gate Terrace, where the Story queue pad is now) gets a ProximityPrompt station whose `Menu = "Lobby_Story"`. Triggering it opens the lobby window. Closing the window (✕) keeps your party, so you can walk around and come back.

## Window

One centered panel, 70% of the screen, clamped to 520×380 … 820×540 px. Buttons are 40 px high (touch). Colours follow the hub palette (night blue panel, brass titles).

### State A: not in a party (browse)

| Left (60%) | Right (40%) |
|---|---|
| **Open parties**: one card per public party in this hub server: leader name, `count/max`, summary "Prologue · Stage 1 · Normal", **Join** | **Quick Join** (fullest open public Story party, or a new public party if none) |
| Pending invites: **Accept invite from X** | **Create Public Party**, **Create Private Party** |
| Empty state: "No public parties yet…" | Hint: solo = create a party and press Start |

### State B: in a party

| Left (45%) | Right (55%) |
|---|---|
| Header: `Party n/max · Public/Private` | **Story settings** |
| 6 slots (or the mode cap): ★ leader, name, `k units`, READY / not ready; leader sees ✕ kick on others; empty slots say "Empty slot" | **Chapter** `< Prologue: Training Grounds (+4 locked) >` |
| | **Stage** `< Stage 1 >` (only stages of the chosen chapter) |
| | **Difficulty** `< Normal >` (Hard available, Nightmare locked) |
| | **Visibility: Public/Private** (leader) |
| | **Team: k unit(s) · Edit** → opens the existing Team window |
| | **Invite Friends** → Roblox invite prompt |
| | Action row: leader **Start** / member **Ready ↔ Unready**, **Leave** |

Non-leaders see the settings as read-only text. Any settings change un-readies everyone.

While starting: "Starting in N…" (5 s for Story) and the leader gets **Cancel**; anyone un-readying or leaving also cancels. Then "Launching match…", then the window closes and the player is moved to the match (Local) or teleported (Reserved).

## Rules (enforced by the server, mirrored in the UI)

- Start needs: mode enabled, `MinPlayers` ≤ members ≤ cap, all non-leaders ready, valid selection, each member in the hub with at least 1 equipped unit, `MatchContext.build` accepts the selection.
- Errors arrive as the existing `Notify` toast ("Kenji is not ready", "Stage is locked", …).
- Rate limit 0.2 s per action. All actions are intent; the client never sends party members, map or rewards.

## Out of scope for the minimal version

Unit portraits in slots, chat bubbles, party-wide team preview, chapter art, cross-server browse (M3), Rejoin banner (M2).
