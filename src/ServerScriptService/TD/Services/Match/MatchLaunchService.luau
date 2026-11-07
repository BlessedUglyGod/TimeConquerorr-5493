--!strict
-- MatchLaunchService: turns a ready party into a running match (hub server).
-- Install as ModuleScript ServerScriptService.TD.Services.Match.MatchLaunchService.
--
-- Two strategies, same input, same MatchContext:
--   Local    (today, Studio, Places.Match == 0): the existing same-place flow. The party is moved to
--            the map and WaveService.startMatch(ctx) runs in this server (opts.startLocal).
--   Reserved (published): ReserveServer on the Match place, write the ticket to MemoryStore keyed by
--            the reserved server's PrivateServerId, then TeleportAsync the party there. The match server
--            (MatchServerBridge) reads the ticket by its own game.PrivateServerId.
-- Combat code is identical in both: it only ever sees the ctx from MatchContext.build.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local TD = ReplicatedStorage:WaitForChild("TD")
local ModeLobbyConfig = require(TD:WaitForChild("Lobby"):WaitForChild("ModeLobbyConfig"))
local MatchTicketStore = require(script.Parent:WaitForChild("MatchTicketStore"))

export type Ticket = MatchTicketStore.Ticket

export type Options = {
	-- The live ServerScriptService.TD.Services.MatchContext module (build(raw) -> ctx?, err?).
	MatchContext: any,
	-- Local strategy: move `players` onto the map and call WaveService.startMatch(ctx). GameServer wires
	-- this to the same code the hub portal uses today. Return false + reason if a local match is running.
	startLocal: (ctx: any, players: { Player }, ticket: Ticket) -> (boolean, string?),
	getLoadout: ((Player) -> { string })?,
	notify: ((Player, string) -> ())?,
	-- Called when a teleport finally failed and the player stays in the hub.
	onTeleportGaveUp: ((Player) -> ())?,
}

local MatchLaunchService = {}

local TELEPORT_RETRIES = 3
local options: Options
local pendingTeleports: { [Player]: { Ticket: Ticket, Attempts: number } } = {}

local function notify(player: Player, text: string)
	if options.notify then
		options.notify(player, text)
	end
end

-- "Local" or "Reserved" for a mode, following ModeLobbyConfig.LaunchMode.
function MatchLaunchService.strategyFor(mode: ModeLobbyConfig.ModeDef): "Local" | "Reserved"
	local placeId = (ModeLobbyConfig.Places :: any)[mode.Place] or 0
	local wanted = ModeLobbyConfig.LaunchMode
	if wanted == "Local" then
		return "Local"
	end
	if RunService:IsStudio() or placeId == 0 then
		if wanted == "Reserved" then
			warn("[MatchLaunch] Reserved requested but unavailable (Studio or Match place id = 0); using Local")
		end
		return "Local"
	end
	return "Reserved"
end

local function buildTicket(party: any, mode: ModeLobbyConfig.ModeDef, players: { Player }): (Ticket?, string?)
	local ok, why = ModeLobbyConfig.validateSelection(mode, party.Selection)
	if not ok then
		return nil, why
	end
	local userIds = {}
	for _, p in players do
		table.insert(userIds, p.UserId)
	end
	local raw = ModeLobbyConfig.toContextRaw(mode, party.Selection, userIds)
	local ctx, err = options.MatchContext.build(raw)
	if not ctx then
		return nil, err or "Match settings rejected"
	end
	if #ctx.Party ~= #userIds then
		return nil, "Party is larger than this mode allows"
	end
	local loadouts: { [string]: { string } } = {}
	if options.getLoadout then
		for _, p in players do
			loadouts[tostring(p.UserId)] = options.getLoadout(p)
		end
	end
	local ticket: Ticket = {
		Version = ModeLobbyConfig.ConfigVersion,
		MatchId = MatchTicketStore.newMatchId(),
		Context = ctx,
		ModeId = mode.Id,
		Selection = table.clone(party.Selection),
		Loadouts = loadouts,
		LeaderUserId = party.LeaderUserId,
		Public = party.Public == true,
		PartyId = party.Id,
		CreatedAt = os.time(),
		HubPlaceId = game.PlaceId,
		PrivateServerId = nil,
		AccessCode = nil,
		Local = false,
	}
	return ticket, nil
end

local function launchLocal(ticket: Ticket, players: { Player }): (boolean, string?)
	ticket.Local = true
	MatchTicketStore.setLocal(true)
	MatchTicketStore.put(ticket.MatchId, ticket)
	local ok, err = options.startLocal(ticket.Context, players, ticket)
	if not ok then
		MatchTicketStore.remove(ticket.MatchId)
		return false, err
	end
	for _, p in players do
		p:SetAttribute("MatchId", ticket.MatchId)
	end
	return true, nil
end

local function teleportOptionsFor(ticket: Ticket): TeleportOptions
	local tpOptions = Instance.new("TeleportOptions")
	tpOptions.ReservedServerAccessCode = ticket.AccessCode :: string
	-- Hint only. The match server ignores it for authority and reads the ticket from MemoryStore.
	tpOptions:SetTeleportData({ MatchId = ticket.MatchId })
	return tpOptions
end

local function giveUp(player: Player, reason: string)
	pendingTeleports[player] = nil
	if player.Parent then
		player:SetAttribute("HubLocation", "Hub")
		player:SetAttribute("MatchId", nil)
		notify(player, reason)
		if options.onTeleportGaveUp then
			options.onTeleportGaveUp(player)
		end
	end
end

local function teleportGroup(ticket: Ticket, group: { Player })
	local placeId = (ModeLobbyConfig.Places :: any)[(ModeLobbyConfig.getMode(ticket.ModeId) :: ModeLobbyConfig.ModeDef).Place]
	for attempt = 1, TELEPORT_RETRIES do
		local alive = {}
		for _, p in group do
			if p.Parent then
				table.insert(alive, p)
			end
		end
		if #alive == 0 then
			return
		end
		local ok, err = pcall(function()
			TeleportService:TeleportAsync(placeId, alive, teleportOptionsFor(ticket))
		end)
		if ok then
			return
		end
		warn(("[MatchLaunch] TeleportAsync attempt %d failed: %s"):format(attempt, tostring(err)))
		task.wait(2 ^ attempt)
	end
	for _, p in group do
		giveUp(p, "Could not reach the match server, please try again")
	end
end

local function launchReserved(ticket: Ticket, mode: ModeLobbyConfig.ModeDef, players: { Player }): (boolean, string?)
	local placeId = (ModeLobbyConfig.Places :: any)[mode.Place]
	local okReserve, code, privateServerId = pcall(function()
		return TeleportService:ReserveServer(placeId)
	end)
	if not okReserve or typeof(code) ~= "string" or typeof(privateServerId) ~= "string" then
		warn("[MatchLaunch] ReserveServer failed: " .. tostring(code))
		return false, "Could not reserve a match server"
	end
	ticket.AccessCode = code
	ticket.PrivateServerId = privateServerId
	-- The ticket must exist before anyone arrives; never teleport without it.
	if not MatchTicketStore.put(privateServerId, ticket) then
		return false, "Match service is busy, try again"
	end
	local expires = os.time() + 30 * 60
	for _, p in players do
		p:SetAttribute("HubLocation", "Travelling")
		p:SetAttribute("MatchId", ticket.MatchId)
		pendingTeleports[p] = { Ticket = ticket, Attempts = 0 }
		MatchTicketStore.setActive(p.UserId, {
			MatchId = ticket.MatchId,
			PlaceId = placeId,
			AccessCode = code,
			ExpiresAt = expires,
		})
	end
	task.spawn(teleportGroup, ticket, players)
	return true, nil
end

-- Entry point for PartyService.init({ launch = MatchLaunchService.launch }).
function MatchLaunchService.launch(party: any): (boolean, string?)
	local mode = ModeLobbyConfig.getMode(party.ModeId)
	if not mode or not mode.Enabled then
		return false, "Mode is closed"
	end
	local players = {}
	for _, p in party.Members do
		if p.Parent then
			table.insert(players, p)
		end
	end
	if #players < mode.MinPlayers then
		return false, "Not enough players"
	end
	local ticket, err = buildTicket(party, mode, players)
	if not ticket then
		return false, err
	end
	if MatchLaunchService.strategyFor(mode) == "Local" then
		return launchLocal(ticket, players)
	end
	return launchReserved(ticket, mode, players)
end

-- Rejoin the reserved match a player disconnected from (hub UI "Rejoin" button, phase M2).
function MatchLaunchService.rejoin(player: Player): (boolean, string?)
	local active = MatchTicketStore.getActive(player.UserId)
	if not active then
		return false, "No running match"
	end
	local tpOptions = Instance.new("TeleportOptions")
	tpOptions.ReservedServerAccessCode = active.AccessCode
	tpOptions:SetTeleportData({ MatchId = active.MatchId, Rejoin = true })
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(active.PlaceId, { player }, tpOptions)
	end)
	if not ok then
		return false, tostring(err)
	end
	player:SetAttribute("HubLocation", "Travelling")
	return true, nil
end

function MatchLaunchService.init(opts: Options)
	options = opts

	-- Per-player teleport failures (Flooded, Unauthorized, IsTeleporting, network...): retry that player
	-- into the SAME reserved server with the same access code, then give up and keep them in the hub.
	TeleportService.TeleportInitFailed:Connect(function(player: Player, result: Enum.TeleportResult, message: string)
		local pending = pendingTeleports[player]
		if not pending then
			return
		end
		pending.Attempts += 1
		warn(("[MatchLaunch] %s teleport failed (%s): %s"):format(player.Name, result.Name, message))
		if pending.Attempts >= TELEPORT_RETRIES or result == Enum.TeleportResult.Unauthorized then
			MatchTicketStore.clearActive(player.UserId, pending.Ticket.MatchId)
			giveUp(player, "Teleport failed: " .. result.Name)
			return
		end
		task.delay(2 ^ pending.Attempts, function()
			if player.Parent and pendingTeleports[player] == pending then
				pcall(function()
					TeleportService:TeleportAsync(
						(ModeLobbyConfig.Places :: any)[(ModeLobbyConfig.getMode(pending.Ticket.ModeId) :: ModeLobbyConfig.ModeDef).Place],
						{ player },
						teleportOptionsFor(pending.Ticket)
					)
				end)
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		pendingTeleports[player] = nil -- left = teleport succeeded (or quit); nothing to retry
	end)
end

return MatchLaunchService
