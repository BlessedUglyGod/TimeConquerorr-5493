# UI + hub polish — Studio integration

For the Studio thread. All files are drop-in; nothing existing is replaced. Requires `HubConfig` (PR #2, already live) and, for the Gate Board, `TD.Lobby.ModeLobbyConfig` (PR #3, already live). Nothing here was run in Studio yet: these are unverified until the checklist at the end passes.

| Repo file | Create in Studio as |
|---|---|
| `src/ReplicatedStorage/TD/UI/Theme.luau` | ModuleScript `ReplicatedStorage.TD.UI.Theme` |
| `src/ReplicatedStorage/TD/UI/Icons.luau` | ModuleScript `ReplicatedStorage.TD.UI.Icons` |
| `src/ReplicatedStorage/TD/UI/UiKit.luau` | ModuleScript `ReplicatedStorage.TD.UI.UiKit` |
| `src/ReplicatedStorage/TD/HubDistricts.luau` | ModuleScript `ReplicatedStorage.TD.HubDistricts` |
| `src/ServerScriptService/TD/Services/HubDecorator.luau` | ModuleScript `ServerScriptService.TD.Services.HubDecorator` |
| `src/StarterPlayerScripts/TD/HubHud.luau` | ModuleScript `StarterPlayer.StarterPlayerScripts.TD.HubHud` |
| `src/StarterPlayerScripts/TD/HubAtmosphere.luau` | ModuleScript `StarterPlayer.StarterPlayerScripts.TD.HubAtmosphere` |

`TD.UI` is a Folder in `ReplicatedStorage.TD`.

## Server

Where `HubService` builds the hub (it calls `HubBuilder.build()`), decorate right after:

```lua
local HubDecorator = require(Services.HubDecorator)
local built = HubBuilder.build()
local added = HubDecorator.decorate(built.Root)
print("Hub decor parts:", added)
```

If HubService builds the hub internally, call `HubDecorator.decorate()` after `HubService.init(...)` (it finds `Workspace.Hub`).

## Client (TDClient)

```lua
local HubHud = require(script.Parent.HubHud)
local HubAtmosphere = require(script.Parent.HubAtmosphere)

-- same handlers already registered with HubClient for stations
HubHud.registerMenu("Summon", function() Menus.openSummon() end)
HubHud.registerMenu("Team", function() Menus.openTeam() end)
HubHud.init({ openLobby = function(modeId) LobbyClient.open(modeId) end })
HubAtmosphere.init()

-- show the hub HUD only in the Hub UI state (adapt to UiState's actual API)
UiState.onChanged(function(state)
	HubHud.setVisible(state == "Hub")
end)
```

Dock tiles for menus without a handler (Collection, Quests, Shop, Pass) show dimmed and answer "Coming soon"; they light up when `registerMenu` is called for them.

Optional: replace HubClient's `SetCore("SendNotification")` toast with `UiKit.toast(text, "Info")` so hub messages share the style.

## Adding mode gates

When a mode is enabled in `ModeLobbyConfig`, append its gate station:

```lua
local HubDistricts = require(TD.HubDistricts)
local Theme = require(TD.UI.Theme)
for _, s in HubDistricts.gateStations({ Infinite = true }, function(m) return Theme.Color.Mode[m] end) do
	table.insert(HubConfig.Stations, s)
end
```

and remove that mode's queue-pad entry from `HubConfig.Portals`. Register `HubClient.registerMenu("Lobby_Infinite", function() LobbyClient.open("Infinite") end)`.

## Checklist

- [ ] No errors in Output on server start and client join.
- [ ] Hub: HubHud shows name, gems, gold; buying/summoning updates the chips.
- [ ] Walk into each district: the location strip changes name and tick colour.
- [ ] PLAY opens the Gate Board; Story card opens the Story lobby; locked cards toast their reason.
- [ ] Summon / Units dock tiles open the existing windows; Esc and the scrim close UiKit windows.
- [ ] Enter a match: HubHud hidden, hub lighting removed, TDHud unchanged. Return: both back.
- [ ] Decor: no blocked paths, nothing floating; label clutter from spawn gone.
- [ ] Phone emulator 844×390: bottom dock with PLAY centred, Gate Board full screen.
