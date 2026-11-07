# Lobby + match launch integration (for the Studio executor)

All new files are drop-in. Combat code (WaveService, enemies, units, MatchContext) is not changed.

| Repo file | Create in Studio as | Place |
|---|---|---|
| `src/ReplicatedStorage/TD/Lobby/ModeLobbyConfig.luau` | ModuleScript `ReplicatedStorage.TD.Lobby.ModeLobbyConfig` | Hub + Match |
| `src/ServerScriptService/TD/Services/Match/MatchTicketStore.luau` | ModuleScript `ServerScriptService.TD.Services.Match.MatchTicketStore` | Hub + Match |
| `src/ServerScriptService/TD/Services/Match/PartyService.luau` | ModuleScript `ServerScriptService.TD.Services.Match.PartyService` | Hub |
| `src/ServerScriptService/TD/Services/Match/MatchLaunchService.luau` | ModuleScript `ServerScriptService.TD.Services.Match.MatchLaunchService` | Hub |
| `src/ServerScriptService/TD/Services/Match/MatchServerBridge.luau` | ModuleScript `ServerScriptService.TD.Services.Match.MatchServerBridge` | Match |
| `src/StarterPlayerScripts/TD/LobbyClient.luau` | ModuleScript `StarterPlayer.StarterPlayerScripts.TD.LobbyClient` | Hub |

The four server modules must be siblings in the `Match` folder.

## Hub place, GameServer (M1, Local strategy)

```lua
local MatchFolder = Services:WaitForChild("Match")
local PartyService = require(MatchFolder.PartyService)
local MatchLaunchService = require(MatchFolder.MatchLaunchService)
local MatchContext = require(Services.MatchContext)

local function notify(player, text) Remotes.Notify:FireClient(player, text) end
local function getLoadout(player) return PlayerDataService.getTeam(player) end -- the equipped unit ids

MatchLaunchService.init({
	MatchContext = MatchContext,
	getLoadout = getLoadout,
	notify = notify,
	-- Same thing the Story portal's onTravel does today, but for an already built ctx.
	startLocal = function(ctx, players, ticket)
		if State:GetAttribute("Phase") ~= "Lobby" then
			return false, "A match is already running, try again soon"
		end
		local map = workspace:FindFirstChild(ctx.MapId)
		local spawn = map and map:FindFirstChild("PlayerSpawn")
		for i, p in players do
			p:SetAttribute("HubLocation", "Match")
			p:SetAttribute("HubMode", ctx.Mode)
			if p.Character and spawn then
				p.Character:PivotTo(spawn.CFrame + Vector3.new((i - 1) * 4 - 10, 3, 0))
			end
		end
		return WaveService.startMatch(ctx)
	end,
})

PartyService.init({
	getLoadout = getLoadout,
	launch = MatchLaunchService.launch,
	notify = notify,
	-- isInHub defaults to HubLocation == "Hub"; checkRequirements (levels, unlocks) can be added later
})
```

HubConfig change: add a Story Gate station and turn off the Story queue pad (the pad flow and the lobby must not both launch):

```lua
-- HubConfig.Stations
{ Id = "StoryGate", Label = "Story Gate", Zone = "Gates", Offset = Vector3.new(0, 0, 18), Kind = "Board",
  Menu = "Lobby_Story", Enabled = true, Color = P.Teal },
-- HubConfig.Portals: Story -> Enabled = false (or remove the pad)
```

## Hub place, TDClient

```lua
local LobbyClient = require(script.Parent.LobbyClient)
LobbyClient.init({ openTeam = function() Menus.openTeam() end })
HubClient.registerMenu("Lobby_Story", function() LobbyClient.open("Story") end)
```

## Match place (M2, after publishing)

GameServer of the match place: same combat services, **no HubService**, plus:

```lua
local MatchServerBridge = require(Services.Match.MatchServerBridge)
MatchServerBridge.init({
	MatchContext = MatchContext,
	startMatch = WaveService.startMatch,
	resetMatch = function() WaveService.reset() end, -- whatever RequestReplay does today
	notify = notify,
	studioContext = { Mode = "Story", Stage = 1, Difficulty = "Normal" }, -- only for Studio play of this place
})
-- in WaveService's match-end hook (Won or Lost):
MatchServerBridge.onMatchEnded()
-- RequestReplay handler in the match place:
local ok, err = MatchServerBridge.replay(); if not ok then notify(player, err) end
```

`HubLocation`: the bridge sets `HubLocation = "Match"` on every admitted party member, so the existing `PlaceUnit` / `RequestStart` gate stays as it is. The Return to Hub button keeps working because the bridge serves the same `HubReturn` remote by teleporting to the hub.

Recommended for rewards: make `onMatchEnd` idempotent per `MatchServerBridge.getTicket().MatchId` + run number so a double end event can never pay twice.

## Switching Local → Reserved

Set `ModeLobbyConfig.Places.Match` to the Match place id. With `LaunchMode = "Auto"` live servers use Reserved and Studio keeps using Local. Nothing else changes.
