--!strict
-- HubDistricts: data for the polished hub pass (environment plan: docs/hub/ENVIRONMENT_PLAN.md).
-- Install as ModuleScript ReplicatedStorage.TD.HubDistricts (next to HubConfig; read by HubDecorator on the
-- server and HubAtmosphere on the client). It only adds to HubConfig: zone positions, portals and stations
-- stay in HubConfig, so HubBuilder/HubService keep working unchanged.

local HubDistricts = {}

-- Hub-only lighting. Applied by HubAtmosphere while HubLocation == "Hub", restored for matches.
-- Late-afternoon "golden hour": warm key light, cool sky, light haze so the island reads as floating.
HubDistricts.Lighting = {
	ClockTime = 16.6,
	GeographicLatitude = 28,
	Brightness = 2.4,
	Ambient = Color3.fromRGB(70, 66, 88),
	OutdoorAmbient = Color3.fromRGB(128, 120, 140),
	ColorShift_Top = Color3.fromRGB(255, 226, 190),
	EnvironmentDiffuseScale = 0.6,
	EnvironmentSpecularScale = 0.5,
	Atmosphere = {
		Density = 0.32,
		Offset = 0.12,
		Color = Color3.fromRGB(222, 200, 190),
		Decay = Color3.fromRGB(110, 96, 150),
		Glare = 0.4,
		Haze = 1.6,
	},
	Bloom = { Intensity = 0.35, Size = 22, Threshold = 1.6 }, -- only neon (interactables) blooms
	ColorCorrection = { Brightness = 0.02, Contrast = 0.06, Saturation = 0.08, TintColor = Color3.fromRGB(255, 248, 240) },
	SunRays = { Intensity = 0.06, Spread = 0.7 },
}

-- Per-district dressing. Kinds are built by HubDecorator from primitives (H2a); H2b swaps them for meshes
-- at the same positions. `Accent` = the district's single accent colour (matches Theme.Color.District).
export type DistrictDressing = {
	Zone: string,
	Accent: Color3,
	Gateway: boolean, -- dial arch over the walkway entrance
	Props: { string }, -- prop kinds, see HubDecorator.PROPS
	Trees: "Green" | "Blossom" | "Crystal" | "None",
}

HubDistricts.Dressing = {
	{ Zone = "Plaza", Accent = Color3.fromRGB(226, 220, 205), Gateway = false, Props = { "HourMarkers", "PlazaLamps", "SpireGears" }, Trees = "None" },
	{ Zone = "Gates", Accent = Color3.fromRGB(70, 220, 210), Gateway = true, Props = { "ModeBanners" }, Trees = "Green" },
	{ Zone = "Summon", Accent = Color3.fromRGB(150, 110, 240), Gateway = true, Props = { "StarPillars", "HaloRings" }, Trees = "Crystal" },
	{ Zone = "Market", Accent = Color3.fromRGB(250, 150, 70), Gateway = true, Props = { "Stalls", "LanternString", "Crates" }, Trees = "Green" },
	{ Zone = "Workshop", Accent = Color3.fromRGB(214, 168, 72), Gateway = true, Props = { "GearWall", "Anvils" }, Trees = "None" },
	{ Zone = "Garden", Accent = Color3.fromRGB(240, 120, 150), Gateway = true, Props = { "Pond", "Benches", "FlowerBeds" }, Trees = "Blossom" },
	{ Zone = "Guild", Accent = Color3.fromRGB(205, 190, 160), Gateway = true, Props = { "NoticePillars", "HangingBanners" }, Trees = "Green" },
	{ Zone = "Rift", Accent = Color3.fromRGB(120, 110, 200), Gateway = true, Props = { "CrystalShards", "BasaltSpikes" }, Trees = "None" },
} :: { DistrictDressing }

-- Scatter settings for trees and lanterns along walkways.
HubDistricts.Scatter = {
	Seed = 5493, -- fixed: the island looks the same on every server
	Trees = 46,
	TreeMinRadius = 52, -- keep the plaza open
	TreeClearance = 8, -- studs from any zone platform / walkway edge
	LanternSpacing = 16,
}

-- Mode gates to add for the lobby flow (PR #3: every mode lobby opens from a station with Menu "Lobby_<Mode>").
-- Story's gate already exists in the live place. Append these to HubConfig.Stations when each mode turns on
-- (Enabled = ModeLobbyConfig mode Enabled). Positions are proposals; confirm in a Studio walk-through.
-- Kind "Altar" = a keystone plinth in front of the arch that HubDecorator dresses as a gate.
HubDistricts.ModeGates = {
	{ Mode = "Infinite", Zone = "Gates", Offset = Vector3.new(-22, 0, 2) },
	{ Mode = "Challenge", Zone = "Gates", Offset = Vector3.new(22, 0, 2) },
	{ Mode = "Survival", Zone = "Gates", Offset = Vector3.new(30, 0, -18) },
	{ Mode = "Event", Zone = "Gates", Offset = Vector3.new(-30, 0, -18) },
	{ Mode = "Dungeon", Zone = "Rift", Offset = Vector3.new(-10, 0, 0) },
	{ Mode = "Raid", Zone = "Rift", Offset = Vector3.new(10, 0, 0) },
	{ Mode = "BossRush", Zone = "Rift", Offset = Vector3.new(0, 0, -14) },
}

-- StationDefs for HubConfig.Stations, built from ModeGates. `enabledModes` = set of enabled mode ids.
function HubDistricts.gateStations(enabledModes: { [string]: boolean }, color: (mode: string) -> Color3): { any }
	local out = {}
	for _, g in HubDistricts.ModeGates do
		table.insert(out, {
			Id = g.Mode .. "Gate",
			Label = g.Mode == "BossRush" and "Boss Rush" or g.Mode,
			Zone = g.Zone,
			Offset = g.Offset,
			Kind = "Altar",
			Menu = "Lobby_" .. g.Mode,
			Enabled = enabledModes[g.Mode] == true,
			Color = color(g.Mode),
		})
	end
	return out
end

return HubDistricts
