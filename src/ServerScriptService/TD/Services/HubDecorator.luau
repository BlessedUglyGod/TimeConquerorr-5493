--!strict
-- HubDecorator: environment dressing for Meridian Isle (plan: docs/hub/ENVIRONMENT_PLAN.md, phase H2a).
-- Install as ModuleScript ServerScriptService.TD.Services.HubDecorator (sibling of HubBuilder).
-- Call once after HubBuilder.build():
--   local built = HubBuilder.build()
--   HubDecorator.decorate(built.Root)
--
-- It only ADDS a `Decor` folder under Workspace.Hub (plus label tuning), never moves gameplay parts, so
-- HubService (pads, prompts, cogs) is unaffected. Idempotent: an existing Decor folder is rebuilt.
-- Everything is anchored, CanCollide off for small props, CanQuery/CanTouch off, CastShadow off on tiny
-- parts. Parts tagged "HubSpin" are animated on the client by HubAtmosphere (no server cost).
-- Primitives only; H2b replaces each prop kind with a mesh at the same positions.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TD = ReplicatedStorage:WaitForChild("TD")
local HubConfig = require(TD:WaitForChild("HubConfig"))
local HubDistricts = require(TD:WaitForChild("HubDistricts"))

local HubDecorator = {}

local P = HubConfig.Palette
local ORIGIN: Vector3 = HubConfig.Origin
local DISK = CFrame.Angles(0, 0, math.rad(90))

local WOOD = Color3.fromRGB(120, 86, 62)
local DARK_STONE = Color3.fromRGB(70, 68, 84)
local LEAF = Color3.fromRGB(96, 156, 104)
local LEAF_DARK = Color3.fromRGB(74, 128, 88)
local BLOSSOM = Color3.fromRGB(246, 172, 196)
local BLOSSOM_LIGHT = Color3.fromRGB(252, 206, 220)
local LAMP = Color3.fromRGB(255, 214, 150)

local partCount = 0
local FLOOR = 0.6 -- top of a zone platform above the island surface (HubBuilder: floor disk top at +0.6)

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, solid: boolean?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = solid == true
	p.CanTouch = false
	p.CanQuery = solid == true
	if size.Magnitude < 3 then
		p.CastShadow = false
	end
	p.Parent = parent
	partCount += 1
	return p
end

local function ball(parent: Instance, name: string, d: number, pos: Vector3, color: Color3, material: Enum.Material?): Part
	local p = part(parent, name, Vector3.new(d, d, d), CFrame.new(pos), color, material)
	p.Shape = Enum.PartType.Ball
	return p
end

local function cylinder(parent: Instance, name: string, radius: number, height: number, cf: CFrame, color: Color3, material: Enum.Material?, solid: boolean?): Part
	local p = part(parent, name, Vector3.new(height, radius * 2, radius * 2), cf * DISK, color, material, solid)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function lightOn(p: BasePart, color: Color3, range: number, brightness: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = p
end

-- axis "Local" = around the part's own X axis (a cylinder's disk normal: wheels, gears);
-- "World" = around the world Y axis through the part (stars, tilted halos precess).
local function spin(p: BasePart, degPerSec: number, axis: "Local" | "World")
	p:SetAttribute("SpinSpeed", degPerSec)
	p:SetAttribute("SpinAxis", axis)
	CollectionService:AddTag(p, "HubSpin")
end

local function model(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- Gear disk with 8 welded teeth so its rotation is visible. `cf` = centre; the disk normal is cf's look vector.
local function gear(parent: Instance, name: string, radius: number, thickness: number, cf: CFrame, color: Color3, solid: boolean?): Part
	local g = part(parent, name, Vector3.new(thickness, radius * 2, radius * 2), cf * CFrame.Angles(0, math.rad(90), 0), color, Enum.Material.Metal, solid)
	g.Shape = Enum.PartType.Cylinder
	local toothSize = math.max(0.6, radius * 0.28)
	for t = 0, 7 do
		local ta = math.rad(t * 45)
		local tooth = part(parent, name .. "Tooth", Vector3.new(thickness, toothSize, toothSize),
			g.CFrame * CFrame.new(0, math.cos(ta) * (radius + toothSize * 0.35), math.sin(ta) * (radius + toothSize * 0.35)) * CFrame.Angles(ta, 0, 0), color, Enum.Material.Metal)
		tooth.Anchored = false
		tooth.Massless = true
		local weld = Instance.new("WeldConstraint") -- teeth follow when the client rotates the gear
		weld.Part0 = g
		weld.Part1 = tooth
		weld.Parent = tooth
	end
	return g
end

-- Reusable props ----------------------------------------------------------------------------------------

-- Lantern post: brass pole, small roof, warm neon lamp. ~4 parts.
local function lantern(parent: Instance, pos: Vector3, withLight: boolean)
	local m = model(parent, "Lantern")
	part(m, "Pole", Vector3.new(0.5, 7, 0.5), CFrame.new(pos + Vector3.new(0, 3.5, 0)), P.Brass, Enum.Material.Metal)
	local lamp = part(m, "Lamp", Vector3.new(1.2, 1.4, 1.2), CFrame.new(pos + Vector3.new(0, 7.4, 0)), LAMP, Enum.Material.Neon)
	part(m, "Cap", Vector3.new(1.8, 0.3, 1.8), CFrame.new(pos + Vector3.new(0, 8.25, 0)) * CFrame.Angles(0, math.rad(45), 0), DARK_STONE, Enum.Material.Slate)
	if withLight then
		lightOn(lamp, LAMP, 14, 1.2)
	end
end

-- Stylised tree: trunk + 2-3 canopy balls (low-poly anime look). ~4 parts.
local function tree(parent: Instance, pos: Vector3, style: string, rng: Random)
	local m = model(parent, "Tree")
	local h = rng:NextNumber(6, 10)
	part(m, "Trunk", Vector3.new(1.2, h, 1.2), CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6.28), math.rad(rng:NextNumber(-4, 4))), WOOD, Enum.Material.Wood, true)
	if style == "Crystal" then
		for i = 1, 3 do
			local s = part(m, "Shard", Vector3.new(1.4, rng:NextNumber(4, 7), 1.4),
				CFrame.new(pos + Vector3.new(rng:NextNumber(-1.5, 1.5), h + 1, rng:NextNumber(-1.5, 1.5))) * CFrame.Angles(math.rad(rng:NextNumber(-20, 20)), rng:NextNumber(0, 6.28), math.rad(rng:NextNumber(-20, 20))),
				P.Violet, Enum.Material.Neon)
			s.Transparency = 0.15
			if i == 1 then
				lightOn(s, P.Violet, 10, 0.8)
			end
		end
		return
	end
	local main = if style == "Blossom" then BLOSSOM else LEAF
	local alt = if style == "Blossom" then BLOSSOM_LIGHT else LEAF_DARK
	ball(m, "Canopy", rng:NextNumber(7, 9), pos + Vector3.new(0, h + 1.5, 0), main, Enum.Material.Grass)
	ball(m, "Canopy", rng:NextNumber(4.5, 6), pos + Vector3.new(rng:NextNumber(-2.5, 2.5), h + 3.5, rng:NextNumber(-2.5, 2.5)), alt, Enum.Material.Grass)
	if rng:NextNumber() > 0.5 then
		ball(m, "Canopy", rng:NextNumber(3.5, 5), pos + Vector3.new(rng:NextNumber(-3, 3), h, rng:NextNumber(-3, 3)), alt, Enum.Material.Grass)
	end
end

-- "Dial arch": two pillars + a half ring of brass ticks over a walkway. The hub's district gateway.
local function gateway(parent: Instance, cf: CFrame, width: number, accent: Color3)
	local m = model(parent, "Gateway")
	for _, x in { -width / 2, width / 2 } do
		part(m, "Pillar", Vector3.new(2, 12, 2), cf * CFrame.new(x, 6, 0), P.Stone, Enum.Material.Marble, true)
		part(m, "PillarCap", Vector3.new(2.6, 0.6, 2.6), cf * CFrame.new(x, 12.3, 0), P.Brass, Enum.Material.Metal)
	end
	-- arc of 9 ticks from pillar to pillar
	local r = width / 2
	for i = 0, 8 do
		local a = math.rad(180 - i * 22.5)
		local local_ = Vector3.new(math.cos(a) * r, 12.6 + math.sin(a) * r * 0.55, 0)
		part(m, "Tick", Vector3.new(1, if i % 2 == 0 then 2.2 else 1.4, 1), cf * CFrame.new(local_) * CFrame.Angles(0, 0, a - math.rad(90)),
			if i == 4 then accent else P.Brass, if i == 4 then Enum.Material.Neon else Enum.Material.Metal)
	end
end

-- District prop kinds ------------------------------------------------------------------------------------

type Ctx = { folder: Instance, zone: HubConfig.ZoneDef, centre: Vector3, accent: Color3, rng: Random, at: (offset: Vector3) -> CFrame }

local PROPS: { [string]: (Ctx) -> () } = {}

PROPS.HourMarkers = function(c)
	-- 12 brass hour stones inlaid on the plaza edge; 12 o'clock (north) glows: it points at the Gate Terrace.
	local r = HubConfig.PlazaRadius - 3
	for i = 0, 11 do
		local a = math.rad(i * 30)
		local pos = ORIGIN + Vector3.new(math.sin(a) * r, 1.05, -math.cos(a) * r)
		local long = i % 3 == 0
		part(c.folder, "Hour", Vector3.new(if long then 1.6 else 1, 0.2, if long then 5 else 3), CFrame.lookAt(pos, Vector3.new(ORIGIN.X, pos.Y, ORIGIN.Z)),
			if i == 0 then P.Teal else P.Brass, if i == 0 then Enum.Material.Neon else Enum.Material.Metal)
	end
end

PROPS.PlazaLamps = function(c)
	for i = 0, 3 do
		local a = math.rad(45 + i * 90)
		lantern(c.folder, ORIGIN + Vector3.new(math.sin(a) * 30, 1, -math.cos(a) * 30), true)
	end
end

PROPS.SpireGears = function(c)
	-- three floating gears around the Spire at different heights, each turning (client-side)
	for i, spec in { { 12, 18, 14 }, { 9, 28, -10 }, { 7, 36, 8 } } do
		local radius, height, speed = spec[1], spec[2], spec[3]
		local a = math.rad(i * 120)
		local pos = ORIGIN + Vector3.new(math.sin(a) * radius, height, -math.cos(a) * radius)
		-- face outward from the Spire so the gear is seen face-on from the plaza
		local g = gear(c.folder, "SpireGear", 3.2 - i * 0.5, 0.6, CFrame.lookAt(pos, pos + flat(pos - ORIGIN)), P.Brass)
		spin(g, speed * 3, "Local")
	end
end

PROPS.ModeBanners = function(c)
	-- tall pennants on the terrace rim, one per mode colour, so the terrace reads from the plaza
	local colours = { P.Teal, P.Violet, P.Ember, Color3.fromRGB(110, 190, 120), Color3.fromRGB(240, 200, 90) }
	for i, col in colours do
		local x = (i - 3) * 14
		local base = c.at(Vector3.new(x, 0, c.zone.Size - 4))
		part(c.folder, "BannerPole", Vector3.new(0.6, 18, 0.6), base * CFrame.new(0, 9, 0), P.Brass, Enum.Material.Metal)
		local cloth = part(c.folder, "Banner", Vector3.new(3.2, 8, 0.2), base * CFrame.new(1.9, 13, 0), col, Enum.Material.Fabric)
		cloth.CastShadow = true
	end
end

PROPS.StarPillars = function(c)
	for i = 0, 5 do
		local a = math.rad(i * 60 + 30)
		local pos = c.centre + Vector3.new(math.sin(a) * (c.zone.Size - 5), 0, -math.cos(a) * (c.zone.Size - 5))
		part(c.folder, "Pillar", Vector3.new(1.6, 9, 1.6), CFrame.new(pos + Vector3.new(0, 4.5, 0)), P.Night, Enum.Material.Slate, true)
		local star = part(c.folder, "Star", Vector3.new(1.2, 1.2, 1.2), CFrame.new(pos + Vector3.new(0, 10, 0)) * CFrame.Angles(math.rad(45), 0, math.rad(45)), c.accent, Enum.Material.Neon)
		spin(star, 40, "World")
	end
end

PROPS.HaloRings = function(c)
	-- two thin rings floating above the summon altar, rotating on different axes
	local altar = c.at(Vector3.new(0, 0, 0)).Position
	for i, r in { 6, 8 } do
		-- tilted thin disks read as rings of light; turning about world Y makes the tilt sweep around
		local ring = cylinder(c.folder, "Halo", r, 0.3, CFrame.new(altar + Vector3.new(0, 9 + i * 2, 0)) * CFrame.Angles(math.rad(if i == 1 then 16 else -12), 0, 0), c.accent, Enum.Material.Neon)
		ring.Transparency = 0.7
		spin(ring, if i == 1 then 18 else -12, "World")
	end
end

PROPS.Stalls = function(c)
	local awnings = { P.Ember, P.Rose, P.Teal, P.Brass }
	for i, x in { -24, -8, 8, 24 } do
		local base = c.at(Vector3.new(x, 0, c.zone.Size - 10))
		part(c.folder, "Counter", Vector3.new(7, 3, 2.5), base * CFrame.new(0, 1.5, 0), WOOD, Enum.Material.WoodPlanks, true)
		for _, px in { -3.2, 3.2 } do
			part(c.folder, "Post", Vector3.new(0.4, 7, 0.4), base * CFrame.new(px, 3.5, 1.6), WOOD, Enum.Material.Wood)
		end
		part(c.folder, "Awning", Vector3.new(8, 0.3, 4), base * CFrame.new(0, 7.2, 0.6) * CFrame.Angles(math.rad(-14), 0, 0), awnings[i], Enum.Material.Fabric)
	end
end

PROPS.LanternString = function(c)
	-- paper lanterns strung between two poles across the market
	local a = c.at(Vector3.new(-c.zone.Size + 6, 0, 0))
	local b = c.at(Vector3.new(c.zone.Size - 6, 0, 0))
	for _, cf in { a, b } do
		part(c.folder, "StringPole", Vector3.new(0.6, 12, 0.6), cf * CFrame.new(0, 6.5, 0), WOOD, Enum.Material.Wood)
	end
	local n = 9
	for i = 1, n do
		local t = i / (n + 1)
		local pos = a.Position:Lerp(b.Position, t) + Vector3.new(0, 12 - math.sin(t * math.pi) * 2.5, 0)
		local lamp = part(c.folder, "PaperLantern", Vector3.new(1.1, 1.5, 1.1), CFrame.new(pos), if i % 2 == 0 then P.Ember else LAMP, Enum.Material.Neon)
		if i % 3 == 0 then
			lightOn(lamp, LAMP, 12, 0.9)
		end
	end
end

PROPS.Crates = function(c)
	for _ = 1, 7 do
		local off = Vector3.new(c.rng:NextNumber(-c.zone.Size + 8, c.zone.Size - 8), 0, c.rng:NextNumber(c.zone.Size - 6, c.zone.Size - 3))
		local s = c.rng:NextNumber(1.8, 2.8)
		part(c.folder, "Crate", Vector3.new(s, s, s), c.at(off) * CFrame.new(0, s / 2, 0) * CFrame.Angles(0, c.rng:NextNumber(0, 1.5), 0), WOOD, Enum.Material.WoodPlanks, true)
	end
end

PROPS.GearWall = function(c)
	-- big half-buried gears behind the workshop stations: the district's silhouette
	for i, spec in { { -14, 9, 1 }, { 0, 12, -1 }, { 14, 8, 1 } } do
		local x, r, dir = spec[1], spec[2], spec[3]
		local base = c.at(Vector3.new(x, 0, c.zone.Size - 3))
		-- standing gear facing the plaza, partly sunk into the floor
		local g = gear(c.folder, "BigGear", r, 1.6, base * CFrame.new(0, r * 0.6, 0), if i == 2 then P.Brass else DARK_STONE, true)
		spin(g, 6 * dir, "Local")
	end
end

PROPS.Anvils = function(c)
	for _, x in { -20, 20 } do
		local base = c.at(Vector3.new(x, 0, -4))
		part(c.folder, "AnvilBase", Vector3.new(2, 2, 2), base * CFrame.new(0, 1, 0), DARK_STONE, Enum.Material.Slate, true)
		part(c.folder, "AnvilTop", Vector3.new(4, 1, 1.8), base * CFrame.new(0, 2.5, 0), Color3.fromRGB(60, 60, 70), Enum.Material.Metal, true)
		local ember = part(c.folder, "Ember", Vector3.new(0.6, 0.4, 0.6), base * CFrame.new(0.8, 3.2, 0), P.Ember, Enum.Material.Neon)
		lightOn(ember, P.Ember, 8, 1)
	end
end

PROPS.Pond = function(c)
	local cf = c.at(Vector3.new(-10, 0, 8))
	cylinder(c.folder, "PondRim", 9, 0.8, CFrame.new(cf.Position + Vector3.new(0, 0.4, 0)), P.Stone, Enum.Material.Marble, true)
	local water = cylinder(c.folder, "Water", 8.2, 0.4, CFrame.new(cf.Position + Vector3.new(0, 0.65, 0)), Color3.fromRGB(96, 170, 210), Enum.Material.Glass)
	water.Transparency = 0.25
	for i = 0, 4 do -- stepping stones across
		local p = cf.Position + Vector3.new(-8 + i * 4, 0.9, math.sin(i) * 1.5)
		cylinder(c.folder, "SteppingStone", 1.3, 0.4, CFrame.new(p), P.Stone, Enum.Material.Slate, true)
	end
end

PROPS.Benches = function(c)
	for i = 0, 3 do
		local a = math.rad(i * 90 + 45)
		local off = Vector3.new(math.sin(a) * (c.zone.Size - 8), 0, math.cos(a) * (c.zone.Size - 8))
		local base = c.at(off)
		local facing = CFrame.lookAt(base.Position, c.centre) -- benches face the garden's centre
		part(c.folder, "Seat", Vector3.new(6, 0.5, 2), facing * CFrame.new(0, 1.6, 0), WOOD, Enum.Material.WoodPlanks, true)
		part(c.folder, "Back", Vector3.new(6, 2, 0.4), facing * CFrame.new(0, 2.8, 0.9), WOOD, Enum.Material.WoodPlanks, true)
		for _, x in { -2.5, 2.5 } do
			part(c.folder, "Leg", Vector3.new(0.4, 1.4, 1.6), facing * CFrame.new(x, 0.7, 0), P.Brass, Enum.Material.Metal)
		end
	end
end

PROPS.FlowerBeds = function(c)
	local colours = { P.Rose, BLOSSOM_LIGHT, Color3.fromRGB(250, 230, 140), Color3.fromRGB(190, 160, 250) }
	for i = 1, 5 do
		local off = Vector3.new(c.rng:NextNumber(-c.zone.Size + 6, c.zone.Size - 6), 0, c.rng:NextNumber(-c.zone.Size + 10, c.zone.Size - 6))
		local cf = c.at(off)
		cylinder(c.folder, "Bed", 2.6, 0.8, CFrame.new(cf.Position + Vector3.new(0, 0.4, 0)), WOOD, Enum.Material.WoodPlanks)
		for f = 1, 4 do
			ball(c.folder, "Flower", 0.9, cf.Position + Vector3.new(c.rng:NextNumber(-1.8, 1.8), 1.1, c.rng:NextNumber(-1.8, 1.8)), colours[(i + f) % #colours + 1], Enum.Material.SmoothPlastic)
		end
	end
	-- drifting petals (one emitter for the whole garden)
	local emitterPart = part(c.folder, "PetalSource", Vector3.new(c.zone.Size * 1.6, 1, c.zone.Size * 1.6), CFrame.new(c.centre + Vector3.new(0, 20, 0)), BLOSSOM)
	emitterPart.Transparency = 1
	local e = Instance.new("ParticleEmitter")
	e.Rate = 6
	e.Lifetime = NumberRange.new(6, 9)
	e.Speed = NumberRange.new(1, 2)
	e.SpreadAngle = Vector2.new(30, 30)
	e.Acceleration = Vector3.new(0.6, -1.2, 0.3)
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-60, 60)
	e.Size = NumberSequence.new(0.35)
	e.Color = ColorSequence.new(BLOSSOM, BLOSSOM_LIGHT)
	e.LightEmission = 0.2
	e.Parent = emitterPart
end

PROPS.NoticePillars = function(c)
	for _, x in { -16, 16 } do
		local base = c.at(Vector3.new(x, 0, 2))
		cylinder(c.folder, "NoticePillar", 1.6, 9, base * CFrame.new(0, 4.5, 0), P.Stone, Enum.Material.Marble, true)
		for k = 0, 2 do
			part(c.folder, "Notice", Vector3.new(1.4, 1.8, 0.1), base * CFrame.Angles(0, math.rad(k * 120), 0) * CFrame.new(0, 5 + k * 1.2, -1.65), Color3.fromRGB(240, 232, 210), Enum.Material.SmoothPlastic)
		end
	end
end

PROPS.HangingBanners = function(c)
	for _, x in { -8, 0, 8 } do
		local base = c.at(Vector3.new(x, 0, c.zone.Size - 4))
		part(c.folder, "Frame", Vector3.new(4, 0.4, 0.4), base * CFrame.new(0, 13, 0), P.Brass, Enum.Material.Metal)
		part(c.folder, "Cloth", Vector3.new(3.4, 9, 0.15), base * CFrame.new(0, 8.4, 0), if x == 0 then P.Brass else P.Night, Enum.Material.Fabric)
		part(c.folder, "Post", Vector3.new(0.5, 13, 0.5), base * CFrame.new(0, 6.6, 0.4), WOOD, Enum.Material.Wood)
	end
end

PROPS.CrystalShards = function(c)
	for _ = 1, 9 do
		local off = Vector3.new(c.rng:NextNumber(-c.zone.Size + 3, c.zone.Size - 3), 0, c.rng:NextNumber(4, c.zone.Size - 2))
		local h = c.rng:NextNumber(4, 11)
		local s = part(c.folder, "Shard", Vector3.new(h * 0.25, h, h * 0.25),
			c.at(off) * CFrame.new(0, h / 2, 0) * CFrame.Angles(math.rad(c.rng:NextNumber(-18, 18)), c.rng:NextNumber(0, 6.28), math.rad(c.rng:NextNumber(-18, 18))),
			c.accent, Enum.Material.Neon)
		s.Transparency = 0.2
	end
end

PROPS.BasaltSpikes = function(c)
	for _ = 1, 8 do
		local off = Vector3.new(c.rng:NextNumber(-c.zone.Size, c.zone.Size), 0, c.rng:NextNumber(c.zone.Size - 6, c.zone.Size + 2))
		local h = c.rng:NextNumber(6, 16)
		part(c.folder, "Spike", Vector3.new(2.4, h, 2.4), c.at(off) * CFrame.new(0, h / 2, 0) * CFrame.Angles(0, c.rng:NextNumber(0, 1.5), math.rad(c.rng:NextNumber(-8, 8))),
			Color3.fromRGB(46, 42, 58), Enum.Material.Basalt, true)
	end
end

HubDecorator.PROPS = PROPS

-- Scatter (trees, lanterns) ------------------------------------------------------------------------------

local function segmentDistance(p: Vector3, a: Vector3, b: Vector3): number
	local ab = b - a
	local t = math.clamp((p - a):Dot(ab) / ab:Dot(ab), 0, 1)
	return (p - (a + ab * t)).Magnitude
end

local function walkways(): { { Vector3 } }
	local out = {}
	for _, z in HubConfig.Zones do
		if z.Radius > 0 then
			local centre = flat(HubConfig.zoneCenter(z))
			local dir = (centre - flat(ORIGIN)).Unit
			table.insert(out, { flat(ORIGIN), centre - dir * z.Size })
		end
	end
	return out
end

local function isClear(pos: Vector3, paths: { { Vector3 } }, clearance: number): boolean
	local p = flat(pos)
	if (p - flat(ORIGIN)).Magnitude > HubConfig.IslandRadius - 8 then
		return false
	end
	for _, z in HubConfig.Zones do
		if (p - flat(HubConfig.zoneCenter(z))).Magnitude < z.Size + clearance then
			return false
		end
	end
	for _, seg in paths do
		if segmentDistance(p, seg[1], seg[2]) < HubConfig.PathWidth / 2 + clearance then
			return false
		end
	end
	-- keep the waterfall overlook (south gap) open
	if p.Z - ORIGIN.Z > HubConfig.IslandRadius - 30 and math.abs(p.X - ORIGIN.X) < 20 then
		return false
	end
	return true
end

local function treeStyleAt(pos: Vector3): string
	-- the nearest dressed district decides the style, so the Garden is ringed with blossom etc.
	local best, style = math.huge, "Green"
	for _, d in HubDistricts.Dressing do
		local z = HubConfig.getZone(d.Zone)
		if z and z.Radius > 0 then
			local dist = (flat(pos) - flat(HubConfig.zoneCenter(z))).Magnitude
			if dist < best then
				best = dist
				style = if d.Trees == "None" then "Green" else d.Trees
			end
		end
	end
	return style
end

local function scatter(folder: Instance, rng: Random)
	local s = HubDistricts.Scatter
	local paths = walkways()
	-- lanterns along both sides of each walkway; every other one casts light (light budget)
	local lanterns = Instance.new("Folder")
	lanterns.Name = "Lanterns"
	lanterns.Parent = folder
	for _, seg in paths do
		local a, b = seg[1], seg[2]
		local dir = (b - a).Unit
		local side = Vector3.new(-dir.Z, 0, dir.X)
		local startDist = HubConfig.PlazaRadius + 4
		local len = (b - a).Magnitude
		local i = 0
		local d = startDist
		while d < len - 4 do
			for _, sgn in { -1, 1 } do
				local pos = a + dir * d + side * sgn * (HubConfig.PathWidth / 2 + 1.5) + Vector3.new(0, ORIGIN.Y, 0)
				lantern(lanterns, pos, i % 2 == 0 and sgn == 1)
			end
			i += 1
			d += s.LanternSpacing
		end
	end
	-- trees by rejection sampling (fixed seed => identical layout on every server)
	local trees = Instance.new("Folder")
	trees.Name = "Trees"
	trees.Parent = folder
	local placed, tries = 0, 0
	while placed < s.Trees and tries < s.Trees * 30 do
		tries += 1
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(s.TreeMinRadius, HubConfig.IslandRadius - 8)
		local pos = ORIGIN + Vector3.new(math.sin(a) * r, 0, -math.cos(a) * r)
		if isClear(pos, paths, s.TreeClearance) then
			tree(trees, pos, treeStyleAt(pos), rng)
			placed += 1
		end
	end
end

-- Labels -------------------------------------------------------------------------------------------------
-- The H1 build shows every zone sign, portal and station label at once from the plaza, which overlaps into
-- an unreadable cluster. Tighten the distances so only what is near is labelled; the HUD location strip and
-- zone signs handle orientation from afar.
local LABEL_DISTANCE = { ZoneSign = 110, Portal = 80, Station = 42, Status = 40 }

local function tuneLabels(root: Instance)
	for _, gui in root:GetDescendants() do
		if gui:IsA("BillboardGui") then
			local adornee = gui.Parent
			local kind = "Station"
			if gui.Name == "Status" then
				kind = "Status"
			elseif adornee and adornee.Name == "SignPost" then
				kind = "ZoneSign"
			elseif adornee and adornee.Name == "Membrane" then
				kind = "Portal"
			end
			gui.MaxDistance = LABEL_DISTANCE[kind]
			gui.AlwaysOnTop = false
			if kind == "Station" then
				gui.Size = UDim2.fromOffset(170, 34) -- smaller than zone signs: hierarchy
			end
		end
	end
end

-- Entry point ---------------------------------------------------------------------------------------------

function HubDecorator.decorate(hubRoot: Instance?): number
	local root = hubRoot or workspace:FindFirstChild("Hub")
	assert(root, "HubDecorator.decorate: Workspace.Hub not built yet")
	local old = root:FindFirstChild("Decor")
	if old then
		old:Destroy()
	end
	partCount = 0
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	local rng = Random.new(HubDistricts.Scatter.Seed)

	for _, d in HubDistricts.Dressing do
		local zone = HubConfig.getZone(d.Zone)
		if zone then
			local folder = Instance.new("Folder")
			folder.Name = d.Zone
			folder.Parent = decor
			local centre = HubConfig.zoneCenter(zone) + Vector3.new(0, FLOOR, 0)
			local ctx: Ctx = {
				folder = folder,
				zone = zone,
				centre = centre,
				accent = d.Accent,
				rng = rng,
				at = function(offset: Vector3): CFrame
					return HubConfig.placeInZone(zone.Id, offset) + Vector3.new(0, FLOOR, 0)
				end,
			}
			if d.Gateway and zone.Radius > 0 then
				-- arch where the walkway meets the platform, facing the plaza
				gateway(folder, ctx.at(Vector3.new(0, 0, -zone.Size + 2)), HubConfig.PathWidth + 4, d.Accent)
			end
			for _, kind in d.Props do
				local build = PROPS[kind]
				if build then
					build(ctx)
				else
					warn("HubDecorator: unknown prop kind " .. kind)
				end
			end
		end
	end
	scatter(decor, rng)
	decor.Parent = root
	tuneLabels(root)
	return partCount
end

return HubDecorator
