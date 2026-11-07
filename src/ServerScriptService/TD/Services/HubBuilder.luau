--!strict
-- HubBuilder: procedurally builds the basic hub ("Meridian Isle") from HubConfig.
-- Install as ModuleScript ServerScriptService.TD.Services.HubBuilder.
-- Call HubBuilder.build() once on the server (HubService does it). It is idempotent:
-- an existing Workspace.Hub is destroyed and rebuilt, so tuning HubConfig + re-running is safe.
-- Only primitive parts and built-in materials are used (see docs/hub/HUB_DESIGN.md, "Assets").

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HubConfig = require(ReplicatedStorage:WaitForChild("TD"):WaitForChild("HubConfig"))

export type BuiltHub = {
	Root: Folder,
	Spawn: BasePart,
	PortalPads: { [string]: BasePart }, -- portal id -> pad the queue is measured on
	Stations: { [string]: ProximityPrompt }, -- station id -> prompt
	Cogs: { [string]: BasePart },
}

local HubBuilder = {}

local P = HubConfig.Palette
local ORIGIN: Vector3 = HubConfig.Origin
local DISK = CFrame.Angles(0, 0, math.rad(90)) -- cylinder axis X -> Y

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Flat disk whose top face is at `top` height.
local function disk(parent: Instance, name: string, centre: Vector3, radius: number, thickness: number, color: Color3, material: Enum.Material?): Part
	local p = part(parent, name, Vector3.new(thickness, radius * 2, radius * 2),
		CFrame.new(centre - Vector3.new(0, thickness / 2, 0)) * DISK, color, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function label(adornee: BasePart, text: string, color: Color3, height: number, maxDistance: number?)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(220, 50)
	gui.StudsOffsetWorldSpace = Vector3.new(0, height, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = maxDistance or 120
	gui.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.Name = "Text"
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.GothamBlack
	t.TextScaled = true
	t.Text = text
	t.TextColor3 = color
	t.TextStrokeTransparency = 0.3
	t.Parent = gui
	gui.Parent = adornee
end

local function prompt(parent: BasePart, action: string, object: string, enabled: boolean): ProximityPrompt
	local pp = Instance.new("ProximityPrompt")
	pp.Name = "HubPrompt"
	pp.ActionText = if enabled then action else "Coming soon"
	pp.ObjectText = object
	pp.MaxActivationDistance = HubConfig.Rules.PromptDistance
	pp.RequiresLineOfSight = false
	pp.HoldDuration = 0
	pp.Enabled = true -- disabled stations still show "Coming soon"; the server refuses them
	pp.Parent = parent
	return pp
end

-- Straight walkway from a to b (both on the island surface).
local function walkway(parent: Instance, name: string, a: Vector3, b: Vector3)
	local mid = (a + b) / 2
	local len = (b - a).Magnitude
	part(parent, name, Vector3.new(HubConfig.PathWidth, 0.4, len),
		CFrame.lookAt(mid, b) + Vector3.new(0, 0.2, 0), P.Path, Enum.Material.Cobblestone)
end

local function buildIsland(root: Folder): BasePart
	local island = Instance.new("Folder")
	island.Name = "Island"
	island.Parent = root
	local r = HubConfig.IslandRadius
	local t = HubConfig.IslandThickness
	disk(island, "Top", ORIGIN, r, 2, P.Grass, Enum.Material.Grass)
	disk(island, "Rock", ORIGIN - Vector3.new(0, 2, 0), r - 4, t, Color3.fromRGB(120, 105, 95), Enum.Material.Rock)
	-- Tapered underside: stacked shrinking disks read as a floating rock from below.
	for i = 1, 4 do
		disk(island, "Under" .. i, ORIGIN - Vector3.new(0, 2 + t + (i - 1) * 10, 0), (r - 4) * (1 - i * 0.18), 10,
			Color3.fromRGB(100, 88, 80), Enum.Material.Rock)
	end
	-- Low rim wall so nobody walks off by accident (gaps at the waterfall and the cog edge).
	local segments = 36
	for i = 0, segments - 1 do
		local deg = i * 360 / segments
		if not (deg >= 170 and deg <= 190) then -- south gap: waterfall overlook
			local a = math.rad(deg)
			local pos = ORIGIN + Vector3.new(math.sin(a) * (r - 1), 1.5, -math.cos(a) * (r - 1))
			part(island, "Rim", Vector3.new(2 * math.pi * r / segments + 0.5, 3, 2),
				CFrame.lookAt(pos, Vector3.new(ORIGIN.X, pos.Y, ORIGIN.Z)), P.Stone, Enum.Material.Marble)
		end
	end
	-- Spawn
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = HubConfig.spawnCFrame() - Vector3.new(0, 3.5, 0)
	spawn.Color = P.Teal
	spawn.Material = Enum.Material.Neon
	spawn.Transparency = 0.6
	spawn.CanCollide = true
	spawn.Parent = root
	return spawn
end

-- The Meridian Spire: central landmark, a tower with brass clock rings.
local function buildSpire(root: Folder)
	local spire = Instance.new("Model")
	spire.Name = "MeridianSpire"
	spire.Parent = root
	disk(spire, "Plinth", ORIGIN + Vector3.new(0, 1, 0), 12, 1, P.Stone, Enum.Material.Marble)
	local h = 0
	for i, w in { 10, 8, 6.5, 5 } do
		local seg = 16 - i * 2
		part(spire, "Tier" .. i, Vector3.new(w, seg, w), CFrame.new(ORIGIN + Vector3.new(0, 1 + h + seg / 2, 0)),
			P.Stone, Enum.Material.Marble)
		h += seg
		local ring = disk(spire, "Ring" .. i, ORIGIN + Vector3.new(0, 1 + h + 0.5, 0), w * 0.9, 1, P.Brass, Enum.Material.Metal)
		ring.CanCollide = false
	end
	-- Clock face (one per side) and a glowing crystal on top.
	for i = 0, 3 do
		local a = math.rad(i * 90)
		local pos = ORIGIN + Vector3.new(math.sin(a) * 5.1, 1 + 20, -math.cos(a) * 5.1)
		local face = part(spire, "ClockFace", Vector3.new(7, 7, 0.4), CFrame.lookAt(pos, pos + (pos - Vector3.new(ORIGIN.X, pos.Y, ORIGIN.Z))),
			P.Night, Enum.Material.Glass)
		face.Shape = Enum.PartType.Block
		local hand = part(spire, "Hand", Vector3.new(0.4, 3, 0.2), face.CFrame * CFrame.new(0, 1.2, -0.3), P.Brass, Enum.Material.Neon)
		hand.CanCollide = false
	end
	local crystal = part(spire, "Crystal", Vector3.new(3, 6, 3), CFrame.new(ORIGIN + Vector3.new(0, 1 + h + 4, 0)) * CFrame.Angles(0, math.rad(45), 0),
		P.Teal, Enum.Material.Neon)
	crystal.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color = P.Teal
	light.Range = 40
	light.Brightness = 2
	light.Parent = crystal
end

local function buildZones(root: Folder)
	local zones = Instance.new("Folder")
	zones.Name = "Zones"
	zones.Parent = root
	for _, z in HubConfig.Zones do
		local centre = HubConfig.zoneCenter(z)
		local model = Instance.new("Model")
		model.Name = z.Id
		model:SetAttribute("Label", z.Label)
		model:SetAttribute("Phase", z.Phase)
		model.Parent = zones
		local floor = disk(model, "Floor", centre + Vector3.new(0, 0.6, 0), z.Size, 0.6, z.Color, z.Material)
		if z.Radius > 0 then
			-- walkway from plaza edge to zone edge
			local dir = (centre - ORIGIN).Unit
			walkway(model, "Walkway", ORIGIN + dir * (HubConfig.PlazaRadius - 2), centre - dir * (z.Size - 2))
			-- zone sign on a post at the zone entrance
			local signPos = centre - dir * (z.Size - 1) + Vector3.new(0, 4, 0)
			local post = part(model, "SignPost", Vector3.new(1, 8, 1), CFrame.new(signPos), P.Brass, Enum.Material.Metal)
			label(post, z.Label, Color3.new(1, 1, 1), 6, 200)
			if z.Phase > 1 then
				-- Zones from later phases are visible but fenced with a translucent barrier.
				local barrier = disk(model, "Barrier", centre + Vector3.new(0, 10, 0), z.Size - 1, 20, P.Locked, Enum.Material.ForceField)
				barrier.Transparency = 0.5
				label(floor, "Opening soon", P.Locked, 14)
			end
		end
	end
end

local function buildPortal(parent: Instance, def: HubConfig.PortalDef): BasePart
	local cf = HubConfig.placeInZone(def.Zone, def.Offset)
	local model = Instance.new("Model")
	model.Name = def.Id
	model:SetAttribute("Mode", def.Mode)
	model:SetAttribute("Enabled", def.Enabled)
	model.Parent = parent
	local color = if def.Enabled then def.Color else P.Locked
	-- Arch: two pillars, a lintel, and a glowing membrane facing the plaza.
	for _, x in { -5, 5 } do
		part(model, "Pillar", Vector3.new(2, 14, 2), cf * CFrame.new(x, 7.6, 0), P.Stone, Enum.Material.Marble)
	end
	part(model, "Lintel", Vector3.new(13, 2, 2.4), cf * CFrame.new(0, 15.6, 0), P.Brass, Enum.Material.Metal)
	local membrane = part(model, "Membrane", Vector3.new(8, 12, 0.3), cf * CFrame.new(0, 7.6, 0), color, Enum.Material.Neon)
	membrane.Transparency = if def.Enabled then 0.25 else 0.7
	membrane.CanCollide = false
	-- Queue pad in front of the arch (towards the plaza). Standing on it = in queue.
	local pad = part(model, "QueuePad", Vector3.new(12, 0.4, 10), cf * CFrame.new(0, 1.1, -7), color, Enum.Material.Neon)
	pad.Transparency = 0.4
	pad.CanCollide = false
	pad:SetAttribute("PortalId", def.Id)
	pad:SetAttribute("Queued", 0)
	pad:SetAttribute("Countdown", -1)
	label(membrane, def.Label, Color3.new(1, 1, 1), 9, 160)
	local status = Instance.new("BillboardGui")
	status.Name = "Status"
	status.Size = UDim2.fromOffset(200, 30)
	status.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	status.MaxDistance = 60
	local st = Instance.new("TextLabel")
	st.Name = "Text"
	st.BackgroundTransparency = 1
	st.Size = UDim2.fromScale(1, 1)
	st.Font = Enum.Font.GothamBold
	st.TextScaled = true
	st.TextColor3 = Color3.new(1, 1, 1)
	st.TextStrokeTransparency = 0.4
	st.Text = if def.Enabled then string.format("0/%d  step in to join", def.MaxPlayers) else "Coming soon"
	st.Parent = status
	status.Parent = pad
	return pad
end

local function buildStation(parent: Instance, def: HubConfig.StationDef): ProximityPrompt
	local cf = HubConfig.placeInZone(def.Zone, def.Offset)
	local model = Instance.new("Model")
	model.Name = def.Id
	model:SetAttribute("Menu", def.Menu)
	model:SetAttribute("Enabled", def.Enabled)
	model.Parent = parent
	local color = if def.Enabled then def.Color else P.Locked
	local anchor: BasePart
	if def.Kind == "Altar" then
		disk(model, "Base", cf.Position + Vector3.new(0, 2.2, 0), 5, 1.6, P.Stone, Enum.Material.Marble)
		anchor = part(model, "Core", Vector3.new(3, 3, 3), cf * CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)),
			color, Enum.Material.Neon)
		anchor.CanCollide = false
	elseif def.Kind == "Counter" then
		anchor = part(model, "Counter", Vector3.new(10, 3.5, 3), cf * CFrame.new(0, 2.9, 0), color, Enum.Material.WoodPlanks)
		part(model, "Awning", Vector3.new(11, 0.4, 5), cf * CFrame.new(0, 8, 1), color, Enum.Material.Fabric)
		for _, x in { -5, 5 } do
			part(model, "Pole", Vector3.new(0.5, 7, 0.5), cf * CFrame.new(x, 4.6, 2.5), P.Brass, Enum.Material.Metal)
		end
	elseif def.Kind == "Board" then
		anchor = part(model, "Board", Vector3.new(10, 7, 0.6), cf * CFrame.new(0, 6, 0), color, Enum.Material.Wood)
		for _, x in { -4.5, 4.5 } do
			part(model, "Leg", Vector3.new(0.6, 6, 0.6), cf * CFrame.new(x, 3.4, 0.4), P.Brass, Enum.Material.Wood)
		end
	else -- Npc: simple placeholder figure (to be replaced by a rigged original character)
		part(model, "Legs", Vector3.new(2, 2.5, 1), cf * CFrame.new(0, 2.15, 0), P.Night)
		anchor = part(model, "Torso", Vector3.new(2.4, 2.6, 1.2), cf * CFrame.new(0, 4.7, 0), color)
		local head = part(model, "Head", Vector3.new(1.8, 1.8, 1.8), cf * CFrame.new(0, 6.9, 0), Color3.fromRGB(255, 224, 196))
		head.Shape = Enum.PartType.Ball
		part(model, "Hat", Vector3.new(2.6, 0.4, 2.6), cf * CFrame.new(0, 7.9, 0), color, Enum.Material.Fabric)
	end
	label(anchor, def.Label, Color3.new(1, 1, 1), if def.Kind == "Npc" then 4.5 else 5)
	local verb = if def.Kind == "Npc" then "Talk" else "Open"
	return prompt(anchor, verb, def.Label, def.Enabled)
end

-- Waterfall overlook + hidden ledge below the south edge, and the cog collectibles.
local function buildSecrets(root: Folder): { [string]: BasePart }
	local secrets = Instance.new("Folder")
	secrets.Name = "Secrets"
	secrets.Parent = root
	local r = HubConfig.IslandRadius
	-- waterfall pouring off the south gap in the rim
	local fall = part(secrets, "Waterfall", Vector3.new(16, 60, 1), CFrame.new(ORIGIN + Vector3.new(0, -26, r + 1)),
		Color3.fromRGB(150, 210, 255), Enum.Material.Glass)
	fall.Transparency = 0.45
	fall.CanCollide = false
	-- ledge behind the waterfall, reached by a hidden stair along the cliff
	part(secrets, "HiddenLedge", Vector3.new(18, 1, 10), CFrame.new(ORIGIN + Vector3.new(0, -24, r - 22)), P.Stone, Enum.Material.Slate)
	-- Offsets from the island centre; the first steps hug the cliff outside the rock (radius r - 4),
	-- the last ones turn inward under the overhang, below the rock's bottom (y < -16).
	local cliffSteps = {
		Vector3.new(10, -3, r + 4), Vector3.new(14, -6, r + 4), Vector3.new(18, -9, r + 4), Vector3.new(18, -12, r),
		Vector3.new(16, -15, r - 2), Vector3.new(14, -18, r - 6), Vector3.new(10, -21, r - 12), Vector3.new(5, -23.5, r - 18),
	}
	for i, offset in cliffSteps do
		part(secrets, "Step" .. i, Vector3.new(4, 1, 4), CFrame.new(ORIGIN + offset), Color3.fromRGB(120, 105, 95), Enum.Material.Rock)
	end
	-- Floating stepping stones spiralling up the Spire to its top ring (jump gaps < 3.5 studs high).
	for i = 0, 11 do
		local a = math.rad(200 + i * 40)
		local radius = 16 - i * 0.7
		part(secrets, "SpiralStone" .. i, Vector3.new(4, 0.8, 4),
			CFrame.new(ORIGIN + Vector3.new(math.sin(a) * radius, 4 + i * 3.4, -math.cos(a) * radius)), P.Stone, Enum.Material.Marble)
	end
	local cogs: { [string]: BasePart } = {}
	for _, c in HubConfig.HiddenCogs do
		local cog = part(secrets, c.Id, Vector3.new(0.6, 2.4, 2.4), CFrame.new(ORIGIN + c.Position) * CFrame.Angles(0, math.rad(90), 0),
			P.Brass, Enum.Material.Neon)
		cog.Shape = Enum.PartType.Cylinder
		cog.CanCollide = false
		cog:SetAttribute("CogId", c.Id)
		cogs[c.Id] = cog
	end
	return cogs
end

function HubBuilder.build(): BuiltHub
	local old = workspace:FindFirstChild("Hub")
	if old then
		old:Destroy()
	end
	local root = Instance.new("Folder")
	root.Name = "Hub"

	local spawn = buildIsland(root)
	disk(root, "Plaza", ORIGIN + Vector3.new(0, 0.5, 0), HubConfig.PlazaRadius, 0.5, P.Stone, Enum.Material.Marble)
	buildSpire(root)
	buildZones(root)

	local portalsFolder = Instance.new("Folder")
	portalsFolder.Name = "Portals"
	portalsFolder.Parent = root
	local pads: { [string]: BasePart } = {}
	for _, def in HubConfig.Portals do
		pads[def.Id] = buildPortal(portalsFolder, def)
	end

	local stationsFolder = Instance.new("Folder")
	stationsFolder.Name = "Stations"
	stationsFolder.Parent = root
	local stations: { [string]: ProximityPrompt } = {}
	for _, def in HubConfig.Stations do
		stations[def.Id] = buildStation(stationsFolder, def)
	end

	local cogs = buildSecrets(root)
	root.Parent = workspace
	return { Root = root, Spawn = spawn, PortalPads = pads, Stations = stations, Cogs = cogs }
end

return HubBuilder
