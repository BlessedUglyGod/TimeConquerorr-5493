--!strict
-- HubService: server side of the main hub.
-- Install as ModuleScript ServerScriptService.TD.Services.HubService and call
-- HubService.init({ onTravel = ... }) once from GameServer (see docs/hub/INTEGRATION.md).
--
-- Responsibilities:
--   * builds Workspace.Hub (HubBuilder) and spawns players there
--   * portal queues: standing on a QueuePad joins, leaving it leaves; countdown, then travel
--   * stations / NPCs: ProximityPrompt -> validated -> HubOpenMenu fired to that client
--   * return to hub after a match (auto, or via HubReturn remote)
--   * hidden Lost Cogs (found list kept as a player attribute; persistence is phase H3)
-- The client only sends intent (HubReturn). Queues, travel and menus are decided here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local TD = ReplicatedStorage:WaitForChild("TD")
local HubConfig = require(TD:WaitForChild("HubConfig"))
local HubBuilder = require(script.Parent:WaitForChild("HubBuilder"))

export type TravelRequest = {
	Portal: HubConfig.PortalDef,
	Players: { Player },
}

export type Options = {
	-- Called for Local destinations after characters were moved to the map.
	-- GameServer can use it to reset/start the match (e.g. WaveService.reset(); MatchState.setMode(mode)).
	onTravel: ((TravelRequest) -> ())?,
	-- Returns true when a Local match may be joined now (e.g. MatchState phase == "Lobby").
	canStartLocal: (() -> (boolean, string?))?,
	-- Server -> client toast, reuse TD.Remotes.Notify if present.
	notify: ((Player, string) -> ())?,
}

local HubService = {}

local built: HubBuilder.BuiltHub? = nil
local options: Options = {}
local queues: { [string]: { Player } } = {}
local countdowns: { [string]: number } = {} -- portal id -> seconds left (absent = not counting)
local lastMenu: { [Player]: number } = {}
local lastReturn: { [Player]: number } = {}
local remotes: { OpenMenu: RemoteEvent, Return: RemoteEvent }? = nil

local LOCATION_ATTR = "HubLocation" -- "Hub" | "Match" | "Travelling"

local function notify(player: Player, text: string)
	if options.notify then
		options.notify(player, text)
	end
end

local function ensureRemote(folder: Instance, name: string): RemoteEvent
	local r = folder:FindFirstChild(name)
	if r and r:IsA("RemoteEvent") then
		return r
	end
	local e = Instance.new("RemoteEvent")
	e.Name = name
	e.Parent = folder
	return e
end

local function rootPart(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		return hrp
	end
	return nil
end

local function isAlive(player: Player): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

-- Is a world position over the pad (pad footprint, up to 8 studs above it)?
local function onPad(pad: BasePart, pos: Vector3): boolean
	local localPos = pad.CFrame:PointToObjectSpace(pos)
	local half = pad.Size / 2
	return math.abs(localPos.X) <= half.X and math.abs(localPos.Z) <= half.Z and localPos.Y >= -1 and localPos.Y <= 8
end

local function removeFromQueues(player: Player)
	for _, q in queues do
		local i = table.find(q, player)
		if i then
			table.remove(q, i)
		end
	end
end

function HubService.sendToHub(player: Player)
	player:SetAttribute(LOCATION_ATTR, "Hub")
	player:SetAttribute("HubMode", nil)
	player:SetAttribute("HubPortal", nil)
	local character = player.Character
	if character then
		local jitter = Vector3.new(math.random(-6, 6), 0, math.random(-3, 3))
		character:PivotTo(HubConfig.spawnCFrame() + jitter)
	end
end

-- Arrival point: <Map>.PlayerSpawn part if the Studio build adds one, else above the map pivot.
local function arrivalCFrame(map: Model): CFrame
	local arrival = map:FindFirstChild("PlayerSpawn")
	if arrival and arrival:IsA("BasePart") then
		return arrival.CFrame + Vector3.new(0, 3, 0)
	end
	return map:GetPivot() + Vector3.new(0, 6, 0)
end

local function travelLocal(portal: HubConfig.PortalDef, group: { Player })
	local mapName = portal.Destination.MapName or "TDMap"
	local map = workspace:FindFirstChild(mapName)
	if not map or not map:IsA("Model") then
		for _, p in group do
			notify(p, "Map is not available right now")
		end
		return
	end
	if options.canStartLocal then
		local ok, why = options.canStartLocal()
		if not ok then
			for _, p in group do
				notify(p, why or "A match is already running")
			end
			return
		end
	end
	local base = arrivalCFrame(map)
	for i, p in group do
		p:SetAttribute(LOCATION_ATTR, "Match")
		p:SetAttribute("HubMode", portal.Mode)
		p:SetAttribute("HubPortal", portal.Id)
		local character = p.Character
		if character then
			character:PivotTo(base + Vector3.new((i - 1) * 4 - 10, 3, 0))
		end
	end
	if options.onTravel then
		options.onTravel({ Portal = portal, Players = group })
	end
end

local function travelTeleport(portal: HubConfig.PortalDef, group: { Player })
	local placeId = portal.Destination.PlaceId
	if not placeId or RunService:IsStudio() then
		for _, p in group do
			notify(p, "Teleport is disabled in Studio; using the local map")
		end
		travelLocal(portal, group)
		return
	end
	for _, p in group do
		p:SetAttribute(LOCATION_ATTR, "Travelling")
	end
	task.spawn(function()
		local tpOptions = Instance.new("TeleportOptions")
		tpOptions.ShouldReserveServer = true
		tpOptions:SetTeleportData({ Mode = portal.Mode, PortalId = portal.Id })
		for attempt = 1, 3 do
			local ok, err = pcall(function()
				TeleportService:TeleportAsync(placeId, group, tpOptions)
			end)
			if ok then
				return
			end
			warn(("[Hub] teleport attempt %d failed: %s"):format(attempt, tostring(err)))
			task.wait(2 ^ attempt)
		end
		for _, p in group do
			if p.Parent then
				notify(p, "Teleport failed, please try again")
				HubService.sendToHub(p)
			end
		end
	end)
end

local function launch(portal: HubConfig.PortalDef)
	local q = queues[portal.Id]
	local group: { Player } = {}
	for i = 1, math.min(#q, portal.MaxPlayers) do
		table.insert(group, q[i])
	end
	for _, p in group do
		removeFromQueues(p)
	end
	if portal.Destination.Kind == "Teleport" then
		travelTeleport(portal, group)
	else
		travelLocal(portal, group)
	end
end

local function updatePadStatus(portal: HubConfig.PortalDef)
	if not built then
		return
	end
	local pad = built.PortalPads[portal.Id]
	local n = #queues[portal.Id]
	local cd = countdowns[portal.Id]
	pad:SetAttribute("Queued", n)
	pad:SetAttribute("Countdown", if cd then math.ceil(cd) else -1)
	local gui = pad:FindFirstChild("Status")
	local text = gui and gui:FindFirstChild("Text")
	if text and text:IsA("TextLabel") then
		if not portal.Enabled then
			text.Text = "Coming soon"
		elseif cd then
			text.Text = string.format("%d/%d  starting in %d", n, portal.MaxPlayers, math.ceil(cd))
		elseif n > 0 and n < portal.MinPlayers then
			text.Text = string.format("%d/%d  need %d", n, portal.MaxPlayers, portal.MinPlayers)
		else
			text.Text = string.format("%d/%d  step in to join", n, portal.MaxPlayers)
		end
	end
end

local refreshAccum = 0
local function step(dt: number)
	if not built then
		return
	end
	refreshAccum += dt
	local doScan = refreshAccum >= 0.25 -- pad occupancy scan at 4 Hz is plenty
	if doScan then
		refreshAccum = 0
	end
	for _, portal in HubConfig.Portals do
		local q = queues[portal.Id]
		if doScan then
			local pad = built.PortalPads[portal.Id]
			-- drop players who left the pad / died / left the hub
			for i = #q, 1, -1 do
				local p = q[i]
				local hrp = rootPart(p)
				if not p.Parent or not hrp or not isAlive(p) or p:GetAttribute(LOCATION_ATTR) ~= "Hub" or not onPad(pad, hrp.Position) then
					table.remove(q, i)
				end
			end
			-- add players standing on the pad
			if portal.Enabled then
				for _, p in Players:GetPlayers() do
					if #q >= portal.MaxPlayers then
						break
					end
					local hrp = rootPart(p)
					if hrp and isAlive(p) and p:GetAttribute(LOCATION_ATTR) == "Hub" and not table.find(q, p) and onPad(pad, hrp.Position) then
						removeFromQueues(p)
						table.insert(q, p)
					end
				end
			end
		end
		-- countdown
		if portal.Enabled and #q >= portal.MinPlayers then
			local left = (countdowns[portal.Id] or portal.Countdown) - dt
			if left <= 0 then
				countdowns[portal.Id] = nil
				launch(portal)
			else
				countdowns[portal.Id] = left
			end
		else
			countdowns[portal.Id] = nil
		end
		if doScan then
			updatePadStatus(portal)
		end
	end
	-- fall-off safety net
	if doScan then
		local killY = HubConfig.Origin.Y - HubConfig.KillPlaneDepth
		for _, p in Players:GetPlayers() do
			local hrp = rootPart(p)
			if hrp and p:GetAttribute(LOCATION_ATTR) == "Hub" and hrp.Position.Y < killY then
				HubService.sendToHub(p)
			end
		end
	end
end

local function onStationTriggered(def: HubConfig.StationDef, player: Player)
	if not remotes then
		return
	end
	if player:GetAttribute(LOCATION_ATTR) ~= "Hub" then
		return
	end
	if not def.Enabled then
		notify(player, def.Label .. " opens in a later update")
		return
	end
	local now = os.clock()
	if now - (lastMenu[player] or 0) < HubConfig.Rules.MenuThrottle then
		return
	end
	lastMenu[player] = now
	remotes.OpenMenu:FireClient(player, def.Menu, def.Id)
end

local function onCogTouched(cogId: string, hit: BasePart)
	local character = hit.Parent
	local player = character and Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end
	local found = tostring(player:GetAttribute("HubCogs") or "")
	local list = string.split(found, ",")
	if table.find(list, cogId) then
		return
	end
	local newValue = if found == "" then cogId else found .. "," .. cogId
	player:SetAttribute("HubCogs", newValue)
	local count = #string.split(newValue, ",")
	notify(player, string.format("Lost Cog found! (%d/%d)", count, #HubConfig.HiddenCogs))
end

-- Call from GameServer when a match ends (Won/Lost) so players return automatically.
function HubService.onMatchEnded()
	local delaySec = HubConfig.Rules.AutoReturnAfterMatch
	if delaySec <= 0 then
		return
	end
	task.delay(delaySec, function()
		for _, p in Players:GetPlayers() do
			if p:GetAttribute(LOCATION_ATTR) == "Match" then
				HubService.sendToHub(p)
			end
		end
	end)
end

-- Players currently on the match map. GameServer resets the match when this drops to 0.
function HubService.countInMatch(): number
	local n = 0
	for _, p in Players:GetPlayers() do
		if p:GetAttribute(LOCATION_ATTR) == "Match" then
			n += 1
		end
	end
	return n
end

-- True when the player is on the map; GameServer gates PlaceUnit / RequestStart with it.
function HubService.isInMatch(player: Player): boolean
	return player:GetAttribute(LOCATION_ATTR) == "Match"
end

function HubService.getBuilt(): HubBuilder.BuiltHub?
	return built
end

function HubService.init(opts: Options?)
	options = opts or {}
	built = HubBuilder.build()
	local hub = built :: HubBuilder.BuiltHub

	local remoteFolder = TD:FindFirstChild("Remotes") or Instance.new("Folder")
	remoteFolder.Name = "Remotes"
	remoteFolder.Parent = TD
	remotes = {
		OpenMenu = ensureRemote(remoteFolder, "HubOpenMenu"), -- server -> client (menuId, stationId)
		Return = ensureRemote(remoteFolder, "HubReturn"), -- client -> server, no args
	}

	for _, portal in HubConfig.Portals do
		queues[portal.Id] = {}
	end

	for _, def in HubConfig.Stations do
		local pp = hub.Stations[def.Id]
		pp.Triggered:Connect(function(player: Player)
			onStationTriggered(def, player)
		end)
	end

	for cogId, cog in hub.Cogs do
		cog.Touched:Connect(function(hit: BasePart)
			onCogTouched(cogId, hit)
		end)
	end

	local r = remotes :: { OpenMenu: RemoteEvent, Return: RemoteEvent }
	r.Return.OnServerEvent:Connect(function(player: Player)
		local now = os.clock()
		if now - (lastReturn[player] or 0) < HubConfig.Rules.ReturnThrottle then
			return
		end
		lastReturn[player] = now
		if player:GetAttribute(LOCATION_ATTR) == "Match" then
			HubService.sendToHub(player)
		end
	end)

	local function onCharacter(player: Player)
		-- Respawns go to wherever the player currently is; new players start in the hub.
		task.defer(function()
			if player:GetAttribute(LOCATION_ATTR) ~= "Match" then
				HubService.sendToHub(player)
				return
			end
			-- died during a match: respawn on the map, not in the hub
			local portal = HubConfig.getPortal(tostring(player:GetAttribute("HubPortal") or ""))
			local mapName = if portal then portal.Destination.MapName or "TDMap" else "TDMap"
			local map = workspace:FindFirstChild(mapName)
			local character = player.Character
			if map and map:IsA("Model") and character then
				character:PivotTo(arrivalCFrame(map))
			end
		end)
	end
	local function onPlayer(player: Player)
		player:SetAttribute(LOCATION_ATTR, "Hub")
		player.CharacterAdded:Connect(function()
			onCharacter(player)
		end)
		if player.Character then
			onCharacter(player)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in Players:GetPlayers() do
		onPlayer(p)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		removeFromQueues(player)
		lastMenu[player] = nil
		lastReturn[player] = nil
	end)

	RunService.Heartbeat:Connect(step)
end

return HubService
