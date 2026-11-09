# Hub integration guide (for the Studio executor)

Four files, all drop-in. No existing script needs to be replaced; GameServer and TDClient each get a few lines.

| Repo file | Create in Studio as |
|---|---|
| `src/ReplicatedStorage/TD/HubConfig.luau` | ModuleScript `ReplicatedStorage.TD.HubConfig` |
| `src/ServerScriptService/TD/Services/HubBuilder.luau` | ModuleScript `ServerScriptService.TD.Services.HubBuilder` |
| `src/ServerScriptService/TD/Services/HubService.luau` | ModuleScript `ServerScriptService.TD.Services.HubService` |
| `src/StarterPlayerScripts/TD/HubClient.luau` | ModuleScript `StarterPlayer.StarterPlayerScripts.TD.HubClient` |

`HubBuilder` and `HubService` must be siblings (HubService requires `script.Parent.HubBuilder`).

## Server (GameServer)

```lua
local HubService = require(Services.HubService)

HubService.init({
	-- only one local match at a time in the prototype
	canStartLocal = function()
		local phase = State:GetAttribute("Phase")
		if phase == "Lobby" then
			return true
		end
		return false, "A match is already running, try again soon"
	end,
	-- same start flow as the RequestStart remote
	onTravel = function(req)
		-- req.Portal.Mode is "Story" for now; req.Players are already on the map
		WaveService.start() -- or whatever RequestStart calls from Lobby
	end,
	notify = function(player, text)
		Remotes.Notify:FireClient(player, text)
	end,
})

-- in the existing WaveService.onMatchEnd hook (Won or Lost):
HubService.onMatchEnded()

-- remote gating (PlaceUnit, RequestStart):
if not HubService.isInMatch(player) then return end

-- in the tick: reset when the map is empty
if State:GetAttribute("Phase") ~= "Lobby" and HubService.countInMatch() == 0 then
	WaveService.reset()
end
```

## What the integrated build does (Studio, 2026-11-07)

The executor integrated this PR and playtested it. These choices are now part of the contract:

- `Workspace.TDMap` has a `PlayerSpawn` part (players arrive there) and `ModelStreamingMode = Persistent`, so the map is always streamed to clients that arrive from the hub.
- The old baseplate is removed; `Workspace.Hub.HubSpawn` is the only `SpawnLocation`.
- **Gating:** `PlaceUnit` and `RequestStart` are refused unless `HubService.isInMatch(player)` (`HubLocation == "Match"`), so nobody can place units or start waves from the hub.
- **Empty map reset:** when `HubService.countInMatch()` drops to 0 (everyone returned, left or was moved back), GameServer resets the match to Lobby so the next portal group starts clean.
- Upgrade Forge and Trait Well are enabled and open the Team window until their own menus exist (H3).
- The Return to Hub button is in the top right corner.

If a `SpawnLocation` other than `HubSpawn` is added later, it is harmless: HubService moves every new character to the right place (hub or map) after spawn anyway.

`RequestReplay` after Won/Lost still works for players who stay on the map; players who pressed Return to Hub are not moved back. If you prefer the hub to be the only way to replay, disable the Play Again button when `HubLocation` exists.

## Client (TDClient)

```lua
local HubClient = require(script.Parent.HubClient)

HubClient.registerMenu("Summon", function() Menus.openSummon() end)
HubClient.registerMenu("Team", function() Menus.openTeam() end)

HubClient.onLocationChanged(function(location)
	-- hide battle-only UI (unit bar, Start button, money/lives) in the hub
	Hud.setBattleVisible(location == "Match")
	-- overhead camera toggle only makes sense on the map
end)

HubClient.init()
```

Use the real function names from `Menus` / `Hud`; the ones above are placeholders. Menu ids not registered show a "not available yet" toast, so `Guide`, `Upgrade`, `ShopGold` etc. are safe before their UIs exist.

## Contract

| Thing | Type | Direction | Notes |
|---|---|---|---|
| `TD.Remotes.HubOpenMenu` | RemoteEvent | server → client | `(menuId: string, stationId: string)` |
| `TD.Remotes.HubReturn` | RemoteEvent | client → server | no args, throttled 2 s, only while `HubLocation == "Match"` |
| Player attr `HubLocation` | string | server-written | `"Hub"`, `"Match"`, `"Travelling"` |
| Player attr `HubMode`, `HubPortal` | string | server-written | set while in a match |
| Player attr `HubCogs` | csv string | server-written | found Lost Cogs (not saved yet) |
| QueuePad attrs `Queued`, `Countdown` | number | server-written | for custom UI later |

## Test checklist

Status after the first Studio playtest: 1–6 passed; 7 (2-player queue) and 8 (Lost Cogs) still to test.

1. Play solo: spawn on the Plaza at `(0, 4, 426)`, Spire visible, Story portal straight north.
2. Walk onto the Story pad: billboard counts down from 8, then you land on TDMap and wave 1 starts.
3. Lose or win: after 10 s you are back in the hub. Return to Hub button works mid-match.
4. Die during a wave: respawn on the map, not in the hub.
5. Summon altar, Team desk, Forge and Trait Well prompts open the existing windows. Gold Shop shows "opens in a later update".
6. Jump off the island: back on the Plaza.
7. 2-player test: both on the pad → one group; one steps off → removed from the queue. Second group while a match runs → "A match is already running".
8. Climb the Spire spiral and take the waterfall stair: two "Lost Cog found" toasts.
