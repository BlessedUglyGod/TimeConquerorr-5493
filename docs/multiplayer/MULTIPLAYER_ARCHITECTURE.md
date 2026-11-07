# Multiplayer architecture: mode lobbies and instanced match servers

Owner requirement (2026-11-07): **Main Hub → Mode Lobby → private match instance → back to Main Hub.** Every major mode has its own lobby on shared party/matchmaking services. Tower defense gameplay runs in separate reserved servers, never in the shared hub server. This document is the design; the code in this PR implements the hub and match sides so the switch from today's same-place prototype to reserved servers is a config change.

## 1. Places inside one experience

One Roblox experience, several places. No separate experiences per mode: they would split DataStores, MemoryStore and the player base, and nothing in our modes needs that.

| Place | Role | Contains | Runs |
|---|---|---|---|
| **Hub** (start place, today's TD place 116509641758969) | Shared social server, up to ~30 players | Meridian Isle, NPCs, summon, inventory/team, all mode lobbies | `HubService`, `PartyService`, `MatchLaunchService`, `PlayerDataService`, summon/team services |
| **Match** (new place, same experience) | One reserved server per match, 1–6 players | All TD maps (Workspace or `ServerStorage.TD.Maps`), combat | `MatchServerBridge`, `MatchContext`, `WaveService`, enemy/unit/status services, `PlayerDataService` |

All modes share one Match place. A mode only changes data (`Config.Modes`, `ModeLobbyConfig`). A second match place is justified only if a mode needs a very different world (for example a huge raid map that should not ship with the other maps); then it gets its own `Places` key and the same scripts.

Shared code: `ReplicatedStorage.TD.Config`, `ReplicatedStorage.TD.Lobby.ModeLobbyConfig`, `MatchContext`, `PlayerDataService` and `MatchTicketStore` are the same files in both places (copy them, later sync with Rojo or packages). Match services must not require `HubService` (already a rule in TD_ARCHITECTURE).

## 2. Flow

```
HUB SERVER                                       MATCH SERVER (reserved, one per match)
──────────                                       ─────────────────────────────────────
Story Gate → LobbyClient.open("Story")
PartyService: create / join / quick join,
  options, public/private, ready, Start
  → countdown → MatchLaunchService.launch
MatchContext.build(raw)  (validate on hub)
ReserveServer(MatchPlaceId) → code, psId
MemoryStore TD_MatchTickets_v1[psId] = ticket
TeleportAsync(party, ReservedServerAccessCode)  ──►  MatchServerBridge: ticket = Tickets[game.PrivateServerId]
                                                      ctx = MatchContext.build(ticket.Context)  (validate again)
                                                      admit ctx.Party only, others → hub
                                                      wait party (≤45 s) → WaveService.startMatch(ctx)
                                                      waves / enemies / placements / objectives (own state)
                                                      Won/Lost → results, rewards to ctx.Party only
                                                      Replay (same server, same ctx) or Return to Hub
HubService: player arrives, HubLocation = Hub  ◄──  TeleportAsync(HubPlaceId, players)  (auto after 90 s)
                                                      last player leaves → ticket removed, server closes
```

Today (Studio, Match place not published) `MatchLaunchService` takes the **Local** strategy: same ticket, same `MatchContext.build`, then `startLocal` moves the party onto `Workspace.TDMap` and calls `WaveService.startMatch(ctx)` in the hub server, exactly what the Story portal does now. Combat code is the same in both strategies.

## 3. Shared services

| Module | Place | Job |
|---|---|---|
| `ModeLobbyConfig` (ReplicatedStorage.TD.Lobby) | both | Per-mode lobby data: label, layout, min/max players (global cap 6), public/private/invites/replay flags, start countdown, options (World/Stage/Difficulty/Map/...) with locked choices and dependencies, requirements. `toContextRaw` turns a selection into the raw table for `MatchContext.build`. |
| `PartyService` | hub | Parties (one per player), leader, ready states, options, invites, kick, public browse list and Quick Join inside the hub server, start countdown, hand-off to the launcher. Remotes `LobbyAction` (intent) and `LobbyState` (snapshot). |
| `MatchLaunchService` | hub | Builds and validates the ticket, picks Local or Reserved, reserves the server, writes the ticket, teleports with retries, records the active match for Rejoin. |
| `MatchTicketStore` | both | MemoryStore wrapper (retries/backoff) for tickets (`TD_MatchTickets_v1`, key = PrivateServerId, TTL 2 h) and active-match records (`TD_ActiveMatch_v1`, key = UserId, TTL 30 min). In-process table in Local mode. |
| `MatchServerBridge` | match | Loads and re-validates the ticket, admits only the party, starts the match, Replay, Return to Hub, auto return, cleanup. |
| `MatchContext` (live, Studio executor) | both | The single authority for what a match is: `{ Mode, MapId, Stage, Difficulty, Party }` checked against `Config.Modes` / `Config.Difficulties`. |

Per-mode lobby rules live in data. Different layouts are a `Layout` value the client switches on (`Story` today, `Generic` for the rest until they get their own screens).

### Mode table (initial values, all data)

| Mode | Enabled now | Players | Options | Replay |
|---|---|---|---|---|
| Story | yes | 1–6 | Chapter (world), Stage (limited by world), Difficulty | yes |
| Infinite | no | 1–6 | Map | yes |
| Dungeons | no | 1–4 | Dungeon, Difficulty | yes |
| Raids | no | 2–6 | Raid, Difficulty | no |
| Challenges | no | 1–3 | Daily / Weekly | no |
| Survival | no | 1–6 | Map, Difficulty | yes |
| Boss Rush | no | 1–4 | Arena, Difficulty | yes |
| Event | no | 1–6 | Event | yes |

Enabling a mode = `Enabled = true` here **and** an entry in the live `Config.Modes` (maps, stages, max players). `MatchContext.build` rejects anything `Config.Modes` does not allow, so the two can never disagree silently: the lobby shows an error instead of launching.

## 4. Teleport data contract and validation

**Rule: the client never decides what match it plays or who is in it.**

Ticket (written by the hub server only, `MatchTicketStore.Ticket`):

| Field | Meaning |
|---|---|
| `Version` | `ModeLobbyConfig.ConfigVersion`; the match server refuses other versions (old hub servers during an update) |
| `MatchId` | GUID, used for logs, reward idempotency and active-match records |
| `Context` | Output of `MatchContext.build` on the hub: `{ Mode, MapId, Stage, Difficulty, Party = { UserId } }` |
| `ModeId`, `Selection` | Lobby choices as picked (for results screen / analytics) |
| `Loadouts` | UserId → equipped unit ids at launch; the match re-reads the profile and only uses units the player owns |
| `LeaderUserId`, `PartyId`, `Public` | Party info |
| `HubPlaceId` | Where to return |
| `PrivateServerId`, `AccessCode` | Set after `ReserveServer`; access code stays server-side |
| `CreatedAt`, `Local` | Bookkeeping |

Why `ReserveServer` + MemoryStore and not `TeleportOptions.ShouldReserveServer` + `TeleportData`:
- `ReserveServer` returns the `PrivateServerId` **before** the teleport, so the ticket can be keyed by it. The match server reads `game.PrivateServerId`, which a client cannot fake, so a ticket can only ever be read by the server it was made for.
- TeleportData goes through the client and can be read and edited by exploiters. We send only `{ MatchId }` as a hint for logs and never trust it.
- The access code is kept server-side so a Rejoin can target the same server.

Validation on the match server, in order: reserved server (`PrivateServerId ~= ""`, `PrivateServerOwnerId == 0`) → ticket exists (5 tries over ~10 s) → `Version` matches → `ticket.PrivateServerId == game.PrivateServerId` → `MatchContext.build(ticket.Context)` passes with this place's Config → each joining player's UserId is in `ctx.Party`. Any failure sends players back to the hub with a message. Rewards are paid by the existing `onMatchEnd` to `ctx.Party` only, and only players actually present at start are put in the started ctx.

`HubLocation`: the bridge sets `HubLocation = "Match"` on admitted players, so the existing `PlaceUnit` / `RequestStart` gate in GameServer works unchanged in the match place. (Chosen over editing the gate: no combat code change.)

## 5. Failure handling

| Situation | Handling |
|---|---|
| Player leaves the hub while in a party | Removed; leadership passes to the next member; a running start countdown is cancelled. |
| A member walks into a match / dies out of the hub during the countdown | Dropped from the party by the 2 Hz hygiene loop; start re-checks `canStart` at the end of the countdown. |
| `MatchContext.build` fails on the hub | Launch refused, party stays in the lobby with the reason. |
| `ReserveServer` or MemoryStore write fails | Launch refused, party stays (nobody is teleported without a ticket). |
| `TeleportAsync` fails for the whole group | 3 tries with backoff (2, 4, 8 s), then everyone stays in the hub with a message. |
| Teleport fails for one player (`TeleportInitFailed`) | That player is retried into the same reserved server (same access code) up to 3 times; `Unauthorized` gives up at once. Then the player stays in the hub and the active-match record is cleared. |
| Party member never arrives | Match starts after 45 s with whoever arrived; latecomers in `ctx.Party` are still admitted (can help, but are not in the started ctx's reward list). |
| Nobody arrives | No start; the server closes by itself when empty. |
| Disconnect mid-match | Slot kept. The hub can offer **Rejoin** via `MatchLaunchService.rejoin` (active-match record, 30 min TTL). |
| Non-member joins the match server (bad link, follow) | Sent to the hub immediately. |
| Ticket missing / wrong version / invalid | Everyone sent to the hub with "Match setup failed". |
| Return to hub fails | 3 tries, then `Kick` with "please rejoin" so nobody is stuck on a dead server. |
| Match server shuts down | `BindToClose` removes the ticket. Profiles save through PlayerDataService's own `BindToClose`. |
| Profile session lock across places | Hub→match teleport: the hub saves and releases the lock on `PlayerRemoving`, the match server loads with the existing retry/wait. Must be checked on the published test place (see §7). |

## 6. Return flow

Match ends (Won/Lost) → existing end screen shows results and rewards (computed and saved on the match server, only for `ctx.Party`, once per `MatchId` + run) → buttons:
- **Replay** (if the mode allows): `MatchServerBridge.replay()` resets to Lobby and calls `WaveService.startMatch` with the same ctx in the same server.
- **Return to Hub**: the existing `HubReturn` remote, served by the bridge in the match place → `TeleportAsync(HubPlaceId)`.
- Auto return of everyone still there after 90 s.

On arrival in the hub, HubService already puts the player at the hub spawn with `HubLocation = "Hub"`. The `ReturnFrom` teleport data may be used for a "welcome back" toast only.

## 7. What can be tested where

| Behaviour | Studio Play (1 client) | Studio Start Server (2–6 clients) | Published test place (live servers) |
|---|---|---|---|
| Lobby UI, party create/join/leave, options, ready, kick, countdown | ✔ | ✔ (multi-party, Quick Join, invites inside one server) | ✔ |
| Local strategy: hub → TDMap → match → results → hub | ✔ | ✔ | ✔ |
| `MatchContext.build` validation, reward-to-party rule | ✔ | ✔ | ✔ |
| Match place played directly (`studioContext`, solo party) | ✔ | ✔ | — |
| `ReserveServer`, `TeleportAsync`, `TeleportInitFailed`, reserved-server ticket read | ✘ (teleport is not supported in Studio) | ✘ | **only here** |
| MemoryStore across servers | partial (needs Studio API access; same process only) | partial | **only here** |
| Rejoin, return teleport, session lock hand-over, auto return, server close | ✘ | ✘ | **only here** |
| `SocialService:PromptGameInvite` | ✘ | ✘ | **only here** |

Reporting rule: a teleport behaviour is "verified" only after it ran on the published test experience with real clients. Until then reports must say "Local strategy verified in Studio, reserved flow not yet verified".

## 8. Roadmap for this workstream

- **M0 (this PR):** design, data-driven lobby config, PartyService, MatchLaunchService (Local + Reserved), MatchTicketStore, MatchServerBridge, Story lobby UI. No change to combat. Local strategy is what runs.
- **M1:** integrate in Studio (hub place): Story Gate opens the Story lobby; the Story queue pad is disabled; Local strategy end to end. Verify in Studio with Start Server, 2–3 clients.
- **M2:** publish a test experience (Hub + Match places), set `Places.Match`, verify Hub → Story lobby → reserved match → results → hub on live servers, plus Rejoin and teleport failure paths. Report exactly which behaviours were verified.
- **M3:** cross-server public matchmaking (MemoryStore queue per mode + selection, a matchmaker loop in hub servers), friend join through `Player:GetFriendsOnline` + `TeleportToPlaceInstance` to the friend's hub.
- **M4:** generalize: enable Infinite, Dungeons, Raids, Challenges, Survival, Boss Rush and Events one at a time (data + their own `Layout` screens), Replay with a fresh reserved server for modes that need a clean state.
