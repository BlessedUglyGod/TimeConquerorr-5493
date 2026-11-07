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

## Screens: Summon and Trait Reroll

| Repo file | Create in Studio as |
|---|---|
| `src/ReplicatedStorage/TD/UI/UiParts.luau` | ModuleScript `ReplicatedStorage.TD.UI.UiParts` |
| `src/StarterPlayerScripts/TD/Screens/SummonScreen.luau` | ModuleScript `StarterPlayer.StarterPlayerScripts.TD.Screens.SummonScreen` |
| `src/StarterPlayerScripts/TD/Screens/TraitRerollScreen.luau` | ModuleScript `StarterPlayer.StarterPlayerScripts.TD.Screens.TraitRerollScreen` |

The screens do not know the live remotes' exact shapes. Each one takes a small **backend adapter** (types at the top of each file) that the Studio thread writes once in TDClient against the real `Summon` / `GetProfile` remotes, `Banners`, `Rarities` and `Config.Units`. The sketch below shows the intent; rename fields to match the live modules.

```lua
local SummonScreen = require(script.Parent.Screens.SummonScreen)
local TraitRerollScreen = require(script.Parent.Screens.TraitRerollScreen)

local function unitView(uid, owned) -- owned = profile.Units[uid]
	local def = Config.Units[owned.Id]
	return { Uid = uid, UnitId = owned.Id, Name = def.Name, Rarity = def.Rarity, Level = owned.Level, Shiny = owned.Shiny }
end

SummonScreen.init({
	getBanners = function()
		local out = {}
		for _, bn in Banners.active() do -- active by dates
			table.insert(out, {
				Id = bn.Id, Name = bn.Name, EndsAt = bn.EndsAt, Accent = Rarities.color(bn.FeaturedRarity),
				Featured = (map bn.Featured to unit views), Rates = (map bn.Rates to { Rarity, Chance }),
				PityMax = bn.Pity, PityLabel = "to a guaranteed " .. bn.PityRarity,
				CostSingle = bn.Cost1, CostTen = bn.Cost10, TenNote = "Epic or better guaranteed",
			})
		end
		return out
	end,
	getPity = function(id) return (cachedProfile.Pity or {})[id] or 0 end,
	getBalance = function() return player:GetAttribute("Gems") or 0 end,
	onBalanceChanged = function(cb) player:GetAttributeChangedSignal("Gems"):Connect(cb) end,
	summon = function(bannerId, count)
		local ok, res = pcall(Remotes.Summon.InvokeServer, Remotes.Summon, bannerId, count)
		if not ok or type(res) ~= "table" or res.Error then return false, (type(res) == "table" and res.Error) or "Summon failed" end
		cachedProfile = Remotes.GetProfile:InvokeServer() -- refresh pity / discovered
		return true, (map res.Results to unit views with New = first time)
	end,
	getUnitModel = function(unitId) return ReplicatedStorage.TD.UnitModels:FindFirstChild(unitId) end,
})

TraitRerollScreen.init({
	getUnits = function() (owned units as unit views + Trait = { Id, Name, Rarity, Effects = { "+35% damage", ... } }) end,
	getOdds = function() return (server trait odds as { Rarity, Chance }) end,
	getBalance = function() return player:GetAttribute("TraitShards") or 0 end,
	costs = { Single = 1, Ten = 10, Lock = 10 }, -- Lock = nil if the server has no trait lock
	tenRule = "Stops early on Legendary or better",
	reroll = function(uid, count, lock) (invoke the trait reroll remote; return true, { Trait = ..., Rolls = n } or false, "reason") end,
})

HubClient.registerMenu("Summon", function() SummonScreen.open() end)
HubHud.registerMenu("Summon", SummonScreen.open)
HubClient.registerMenu("Traits", function() TraitRerollScreen.open() end) -- set TraitWell station Menu = "Traits"
```

If the live game has no trait reroll remote yet, it needs a server endpoint first (server-rolled, cost deducted server-side, validated unit ownership); the screen is ready for it.

### Screen checklist

- [ ] Summon: tabs switch banners; pity bar and costs match the profile; x1 and x10 play the reveal; Legendary+ shows the full-stage reveal; Skip and Done work; gems update.
- [ ] Not enough gems: buttons dim and tapping says how many are missing.
- [ ] Trait Reroll: unit strip filter cycles rarities; selecting a unit fills the left and current trait; reroll spins and lands on the server result; odds row flashes; lock toggles the cost.
- [ ] Both at 844×390: readable, nothing off-screen.

## More screens

| Repo file | Create in Studio as | Menu id / hook |
|---|---|---|
| `src/ReplicatedStorage/TD/UI/DialogueData.luau` | ModuleScript `ReplicatedStorage.TD.UI.DialogueData` | — |
| `src/StarterPlayerScripts/TD/Screens/DialogueScreen.luau` | `…TD.Screens.DialogueScreen` | `"Talk"` (NPC stations; HubClient passes the station id) |
| `src/StarterPlayerScripts/TD/Screens/CollectionBookScreen.luau` | `…TD.Screens.CollectionBookScreen` | `"Collection"` |
| `src/StarterPlayerScripts/TD/Screens/UnitsScreen.luau` | `…TD.Screens.UnitsScreen` | `"Team"` (replaces the old Team window when ready) |
| `src/StarterPlayerScripts/TD/Screens/EvolutionScreen.luau` | `…TD.Screens.EvolutionScreen` | `"Evolution"` (Upgrade Forge station) |
| `src/StarterPlayerScripts/TD/Screens/ResultsScreen.luau` | `…TD.Screens.ResultsScreen` | on match end (`UiState = Results`) |

```lua
local function openMenu(id) -- one router for stations, dock and dialogue choices
	local open = menuHandlers[id]
	if open then open() else UiKit.toast("Coming soon", "Info") end
end

DialogueScreen.init({ openMenu = openMenu, setHudVisible = HubHud.setVisible })
HubClient.registerMenu("Talk", function(stationId) DialogueScreen.open(stationId) end)
-- HubConfig: set Menu = "Talk" on the Guide, Clockkeeper and Merchant stations

CollectionBookScreen.init({
	getEntries = function() (every unit in Config.Units: { UnitId, Name, Rarity, Group = world or element, Discovered = profile.Discovered[id] == true }) end,
	-- getMilestones / claimMilestone: add when the server has Collection milestones
})

UnitsScreen.init({
	getUnits = function() (owned units + Stats = { { Label = "Damage", Value = "120" }, ... }, TraitName, TraitRarity, CanEvolve) end,
	getTeam = function() return cachedProfile.Team (as uids) end,
	setTeam = function(uids) (Remotes.SetTeam:FireServer(uids) or an InvokeServer that returns ok, err; then refresh cachedProfile) end,
	openTraits = TraitRerollScreen.open,
	openEvolution = EvolutionScreen.open,
})

EvolutionScreen.init({
	getCandidates = function() (owned units whose Config entry has an evolution) end,
	getPlan = function(uid) (paths with Into, stat deltas, materials Have/Need/Source, quest steps) end,
	evolve = function(uid, pathId) (server endpoint: validate ownership + materials, consume, swap unit) end,
})

-- match end (client): from the server's results message
ResultsScreen.show({
	Won = won, Title = "Prologue · Stage 1 · Normal", Stars = stars, Waves = "Wave 10 / 10",
	Rewards = { { Icon = "Gems", Label = "Gems", Amount = 50 }, { Icon = "Gold", Label = "Gold", Amount = 200 } },
	Players = { { Name = "goo", Damage = 12345, IsLocal = true } },
	CanReplay = true, AutoReturnIn = 10,
}, { onReplay = function() Remotes.RequestReplay:FireServer() end, onReturn = function() Remotes.HubReturn:FireServer() end })
```

Server endpoints still missing for full function: trait reroll, evolution, collection milestones. The screens show "not connected" / disabled reasons until their backends exist, so nothing pretends to work.

### Checklist (more screens)

- [ ] Talk to Lumi, Oro, Nim: typing, tap/Space skips then advances, choices open Summon / Units / lobby; Esc closes; camera returns.
- [ ] Collection: tabs per group, page arrows, silhouettes for undiscovered, detail popover, completion %.
- [ ] Units: tap slot then unit (or unit then slot) equips; Unequip; full team shows the reason; Traits/Evolve jump with the unit selected.
- [ ] Evolution: path tabs, materials red/green with source toast, Evolve disabled with the first missing requirement.
- [ ] Results: Victory/Defeat banner, rewards flip in, damage list for parties, Replay/Return work, countdown.
