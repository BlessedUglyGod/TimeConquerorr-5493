--!strict
-- HubConfig: all data for the main lobby hub ("Meridian Isle").
-- Install as ModuleScript ReplicatedStorage.TD.HubConfig (shared by server and client).
-- Everything the hub builder, portals and stations need is here; code reads data, not names.

export type ZoneDef = {
	Id: string,
	Label: string,
	Angle: number, -- degrees clockwise from north (-Z), around Origin
	Radius: number, -- distance of the zone centre from Origin
	Size: number, -- platform radius
	Color: Color3,
	Material: Enum.Material,
	Phase: number, -- roadmap phase in which the zone is built (see docs/hub/HUB_ROADMAP.md)
}

export type Destination = {
	Kind: "Local" | "Teleport",
	-- Local: move characters to Workspace[MapName] in this place (prototype, phase H1)
	MapName: string?,
	-- Teleport: reserved server in another place (phase H3+)
	PlaceId: number?,
}

export type PortalDef = {
	Id: string,
	Label: string,
	Zone: string,
	Offset: Vector3, -- relative to zone centre, Y ignored
	Mode: string, -- passed to the match as TeleportData.Mode / player attribute HubMode
	Enabled: boolean, -- disabled portals are built but show "Coming soon"
	MinPlayers: number,
	MaxPlayers: number,
	Countdown: number, -- seconds after MinPlayers is reached
	Color: Color3,
	Destination: Destination,
}

export type StationDef = {
	Id: string,
	Label: string,
	Zone: string,
	Offset: Vector3,
	Kind: "Altar" | "Counter" | "Board" | "Npc",
	Menu: string, -- client menu id opened through HubOpenMenu
	Enabled: boolean,
	Color: Color3,
}

local HubConfig = {}

-- Where the hub sits (agreed with the Studio build: separate region around (0, 0, 400)). Workspace.TDMap is
-- ~200x200 around the world origin, the island spans z 230..570. Change this one value if it ever overlaps.
HubConfig.Origin = Vector3.new(0, 0, 400)
HubConfig.IslandRadius = 170
HubConfig.IslandThickness = 14
HubConfig.PlazaRadius = 42
HubConfig.PathWidth = 14
HubConfig.KillPlaneDepth = 80 -- falling this far below the island returns you to spawn

HubConfig.Palette = {
	Grass = Color3.fromRGB(110, 170, 120),
	Stone = Color3.fromRGB(226, 220, 205),
	Path = Color3.fromRGB(205, 190, 160),
	Brass = Color3.fromRGB(214, 168, 72),
	Night = Color3.fromRGB(40, 44, 80),
	Teal = Color3.fromRGB(70, 220, 210),
	Rose = Color3.fromRGB(240, 120, 150),
	Violet = Color3.fromRGB(150, 110, 240),
	Ember = Color3.fromRGB(250, 150, 70),
	Locked = Color3.fromRGB(120, 120, 130),
}

local P = HubConfig.Palette

HubConfig.Zones = {
	{ Id = "Plaza", Label = "Meridian Plaza", Angle = 0, Radius = 0, Size = 42, Color = P.Stone, Material = Enum.Material.Marble, Phase = 1 },
	{ Id = "Gates", Label = "Gate Terrace", Angle = 0, Radius = 115, Size = 40, Color = P.Stone, Material = Enum.Material.Slate, Phase = 1 },
	{ Id = "Summon", Label = "Starfall Sanctum", Angle = 60, Radius = 110, Size = 30, Color = P.Night, Material = Enum.Material.Slate, Phase = 1 },
	{ Id = "Market", Label = "Lantern Market", Angle = 115, Radius = 112, Size = 32, Color = P.Path, Material = Enum.Material.Cobblestone, Phase = 2 },
	{ Id = "Workshop", Label = "Cogwright Workshop", Angle = 170, Radius = 112, Size = 30, Color = P.Brass, Material = Enum.Material.DiamondPlate, Phase = 1 },
	{ Id = "Garden", Label = "Dusk Garden", Angle = 225, Radius = 110, Size = 34, Color = P.Grass, Material = Enum.Material.Grass, Phase = 2 },
	{ Id = "Guild", Label = "Wayfarers' Hall", Angle = 285, Radius = 112, Size = 30, Color = P.Stone, Material = Enum.Material.WoodPlanks, Phase = 2 },
	{ Id = "Rift", Label = "Rift Overlook", Angle = 320, Radius = 120, Size = 26, Color = P.Night, Material = Enum.Material.Basalt, Phase = 3 },
} :: { ZoneDef }

local LOCAL_MAP: Destination = { Kind = "Local", MapName = "TDMap" }

HubConfig.Portals = {
	{ Id = "Story", Label = "Story", Zone = "Gates", Offset = Vector3.new(0, 0, 18), Mode = "Story", Enabled = true,
		MinPlayers = 1, MaxPlayers = 6, Countdown = 8, Color = P.Teal, Destination = LOCAL_MAP },
	{ Id = "Infinite", Label = "Infinite", Zone = "Gates", Offset = Vector3.new(-22, 0, 8), Mode = "Infinite", Enabled = false,
		MinPlayers = 1, MaxPlayers = 6, Countdown = 8, Color = P.Violet, Destination = LOCAL_MAP },
	{ Id = "Challenge", Label = "Challenges", Zone = "Gates", Offset = Vector3.new(22, 0, 8), Mode = "Challenge", Enabled = false,
		MinPlayers = 1, MaxPlayers = 6, Countdown = 8, Color = P.Ember, Destination = LOCAL_MAP },
	{ Id = "Dungeon", Label = "Dungeons", Zone = "Rift", Offset = Vector3.new(-10, 0, 6), Mode = "Dungeon", Enabled = false,
		MinPlayers = 1, MaxPlayers = 4, Countdown = 10, Color = P.Rose, Destination = LOCAL_MAP },
	{ Id = "Raid", Label = "Raids", Zone = "Rift", Offset = Vector3.new(10, 0, 6), Mode = "Raid", Enabled = false,
		MinPlayers = 2, MaxPlayers = 6, Countdown = 12, Color = P.Ember, Destination = LOCAL_MAP },
} :: { PortalDef }

-- Menu ids are the contract with the client: HubClient maps each id to a UI function.
HubConfig.Stations = {
	{ Id = "SummonAltar", Label = "Summon", Zone = "Summon", Offset = Vector3.new(0, 0, 0), Kind = "Altar", Menu = "Summon", Enabled = true, Color = P.Violet },
	{ Id = "BannerBoard", Label = "Banners", Zone = "Summon", Offset = Vector3.new(0, 0, 20), Kind = "Board", Menu = "Summon", Enabled = true, Color = P.Night },
	{ Id = "TeamDesk", Label = "Team & Collection", Zone = "Workshop", Offset = Vector3.new(-12, 0, 0), Kind = "Counter", Menu = "Team", Enabled = true, Color = P.Brass },
	{ Id = "Forge", Label = "Upgrade Forge", Zone = "Workshop", Offset = Vector3.new(12, 0, 0), Kind = "Altar", Menu = "Upgrade", Enabled = false, Color = P.Ember },
	{ Id = "TraitWell", Label = "Trait Well", Zone = "Workshop", Offset = Vector3.new(0, 0, 14), Kind = "Altar", Menu = "Traits", Enabled = false, Color = P.Teal },
	{ Id = "GoldShop", Label = "Gold Shop", Zone = "Market", Offset = Vector3.new(-14, 0, 0), Kind = "Counter", Menu = "ShopGold", Enabled = false, Color = P.Brass },
	{ Id = "EventShop", Label = "Event Shop", Zone = "Market", Offset = Vector3.new(14, 0, 0), Kind = "Counter", Menu = "ShopEvent", Enabled = false, Color = P.Rose },
	{ Id = "QuestBoard", Label = "Quests", Zone = "Guild", Offset = Vector3.new(0, 0, 12), Kind = "Board", Menu = "Quests", Enabled = false, Color = P.Path },
	{ Id = "PassBoard", Label = "Season Pass", Zone = "Guild", Offset = Vector3.new(14, 0, 4), Kind = "Board", Menu = "Pass", Enabled = false, Color = P.Brass },
	{ Id = "Guide", Label = "Archivist Lumi", Zone = "Plaza", Offset = Vector3.new(16, 0, 16), Kind = "Npc", Menu = "Guide", Enabled = true, Color = P.Teal },
	{ Id = "Clockkeeper", Label = "Clockkeeper Oro", Zone = "Workshop", Offset = Vector3.new(0, 0, -14), Kind = "Npc", Menu = "Team", Enabled = true, Color = P.Brass },
	{ Id = "Merchant", Label = "Peddler Nim", Zone = "Market", Offset = Vector3.new(0, 0, -14), Kind = "Npc", Menu = "ShopGold", Enabled = false, Color = P.Ember },
} :: { StationDef }

-- Hidden collectibles ("Lost Cogs"), positions relative to Origin. Phase H3 adds the reward.
HubConfig.HiddenCogs = {
	{ Id = "Cog1", Position = Vector3.new(0, 47, 3), Hint = "Top of the Spire" },
	{ Id = "Cog2", Position = Vector3.new(0, -22, 150), Hint = "Behind the waterfall" },
	{ Id = "Cog3", Position = Vector3.new(-150, 4, -60), Hint = "Edge of the world" },
}

HubConfig.Rules = {
	PromptDistance = 10,
	MenuThrottle = 0.5, -- seconds between station uses per player
	ReturnThrottle = 2,
	AutoReturnAfterMatch = 10, -- seconds after Won/Lost before players go back to the hub (0 = off)
}

local zoneById: { [string]: ZoneDef } = {}
for _, z in HubConfig.Zones do
	zoneById[z.Id] = z
end

function HubConfig.getZone(id: string): ZoneDef?
	return zoneById[id]
end

-- World position of a zone centre on the island surface.
function HubConfig.zoneCenter(zone: ZoneDef): Vector3
	local a = math.rad(zone.Angle)
	return HubConfig.Origin + Vector3.new(math.sin(a) * zone.Radius, 0, -math.cos(a) * zone.Radius)
end

-- World CFrame for something placed in a zone, facing the plaza centre.
-- Offset axes: +Z = away from the plaza (outer edge), -Z = towards it, X = sideways.
function HubConfig.placeInZone(zoneId: string, offset: Vector3): CFrame
	local zone = zoneById[zoneId]
	assert(zone, "Unknown hub zone " .. zoneId)
	local centre = HubConfig.zoneCenter(zone)
	local facing = if zone.Radius > 0 then CFrame.lookAt(centre, Vector3.new(HubConfig.Origin.X, centre.Y, HubConfig.Origin.Z)) else CFrame.new(centre)
	local flat = Vector3.new(offset.X, 0, offset.Z)
	return facing * CFrame.new(flat)
end

function HubConfig.spawnCFrame(): CFrame
	return CFrame.new(HubConfig.Origin + Vector3.new(0, 4, 26))
end

local portalById: { [string]: PortalDef } = {}
for _, p in HubConfig.Portals do
	portalById[p.Id] = p
end

function HubConfig.getPortal(id: string): PortalDef?
	return portalById[id]
end

return HubConfig
