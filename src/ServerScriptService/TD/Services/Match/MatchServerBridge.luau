--!strict
-- MatchServerBridge: the match-place side of the flow (reserved server).
-- Install as ModuleScript ServerScriptService.TD.Services.Match.MatchServerBridge in the MATCH place
-- and call MatchServerBridge.init({...}) from that place's GameServer instead of HubService.init.
--
-- On server start:
--   1. Read the ticket from MemoryStore by game.PrivateServerId (never from client TeleportData).
--   2. ctx = MatchContext.build(ticket.Context)   -- same validation as the hub, current Config.
--   3. Admit only ctx.Party; anyone else is sent back to the hub.
--   4. When the whole party arrived (or ArrivalTimeout passed with at least one) -> WaveService.startMatch(ctx).
-- After the match: results stay on screen, Replay (if the mode allows) restarts with the same ctx,
-- Return to Hub teleports back, and everyone still here is returned automatically after AutoReturn.
--
-- HubLocation: party members get HubLocation = "Match" on arrival, so the existing PlaceUnit /
-- RequestStart gating in GameServer works unchanged in the match place (chosen over editing the gate).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local TD = ReplicatedStorage:WaitForChild("TD")
local ModeLobbyConfig = require(TD:WaitForChild("Lobby"):WaitForChild("ModeLobbyConfig"))
local MatchTicketStore = require(script.Parent:WaitForChild("MatchTicketStore"))

export type Options = {
	MatchContext: any, -- live MatchContext module
	-- WaveService.startMatch(ctx) -> ok, err (requires phase Lobby)
	startMatch: (ctx: any) -> (boolean, string?),
	-- Back to Lobby phase before a Replay (whatever RequestReplay does today). Optional.
	resetMatch: (() -> ())?,
	notify: ((Player, string) -> ())?,
	ArrivalTimeout: number?, -- seconds to wait for the full party (default 45)
	AutoReturn: number?, -- seconds after the match ends before everyone is sent home (default 90)
	-- Studio only: ctx used when the match place is played directly in Studio (no reserved server).
	studioContext: { [string]: any }?,
}

local MatchServerBridge = {}

local options: Options
local ticket: MatchTicketStore.Ticket? = nil
local ctx: any = nil
local loaded = false
local failed: string? = nil
local started = false
local ended = false
local arrived: { [number]: boolean } = {}
local lastReturn: { [Player]: number } = {}
local autoReturnToken = 0
local studioSolo = false -- match place played directly in Studio: everyone present is the party

local function notify(player: Player, text: string)
	if options.notify then
		options.notify(player, text)
	end
end

local function hubPlaceId(): number
	return if ticket and ticket.HubPlaceId ~= 0 then ticket.HubPlaceId else ModeLobbyConfig.Places.Hub
end

local function isMember(userId: number): boolean
	return ctx ~= nil and (studioSolo or table.find(ctx.Party, userId) ~= nil)
end

-- Teleport players to the hub. Retries, then kicks with a clear message as the last resort so nobody
-- is stuck alone on a finished match server.
function MatchServerBridge.returnToHub(players: { Player }, reason: string?)
	if #players == 0 then
		return
	end
	for _, p in players do
		p:SetAttribute("HubLocation", "Travelling")
		if ticket then
			MatchTicketStore.clearActive(p.UserId, ticket.MatchId)
		end
		if reason then
			notify(p, reason)
		end
	end
	if RunService:IsStudio() then
		warn("[MatchBridge] Studio: teleport to hub skipped for " .. #players .. " player(s)")
		return
	end
	task.spawn(function()
		local tpOptions = Instance.new("TeleportOptions")
		tpOptions:SetTeleportData({ ReturnFrom = if ticket then ticket.MatchId else "" })
		for attempt = 1, 3 do
			local alive = {}
			for _, p in players do
				if p.Parent then
					table.insert(alive, p)
				end
			end
			if #alive == 0 then
				return
			end
			local ok, err = pcall(function()
				TeleportService:TeleportAsync(hubPlaceId(), alive, tpOptions)
			end)
			if ok then
				return
			end
			warn(("[MatchBridge] return attempt %d failed: %s"):format(attempt, tostring(err)))
			task.wait(2 ^ attempt)
		end
		for _, p in players do
			if p.Parent then
				p:Kick("Could not return you to the hub. Please rejoin the game.")
			end
		end
	end)
end

local function admit(player: Player)
	if failed then
		MatchServerBridge.returnToHub({ player }, failed)
		return
	end
	if not isMember(player.UserId) then
		MatchServerBridge.returnToHub({ player }, "You are not part of this match")
		return
	end
	arrived[player.UserId] = true
	player:SetAttribute("HubLocation", "Match")
	player:SetAttribute("MatchId", if ticket then ticket.MatchId else "studio")
	if started and not ended then
		notify(player, "Rejoined the match")
	end
end

local function presentParty(): { number }
	local out = {}
	for _, p in Players:GetPlayers() do
		if isMember(p.UserId) then
			table.insert(out, p.UserId)
		end
	end
	return out
end

local function tryStart(): boolean
	if started or not ctx then
		return false
	end
	-- rewards go to ctx.Party only, so start with the members who actually arrived
	local raw = table.clone(ctx)
	raw.Party = presentParty()
	if #raw.Party == 0 then
		return false
	end
	local ok, err = options.startMatch(raw)
	if not ok then
		warn("[MatchBridge] startMatch failed: " .. tostring(err))
		return false
	end
	started = true
	return true
end

local function loadTicket(): (boolean, string?)
	local isReserved = game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
	if not isReserved then
		if RunService:IsStudio() then
			-- Studio play test of the match place: no ticket exists, use studioContext (or MatchContext
			-- defaults) and treat every player in the session as the party. Never reachable live.
			local built, err = options.MatchContext.build(table.clone(options.studioContext or {}))
			if not built then
				return false, err
			end
			studioSolo = true
			ctx = built
			return true, nil
		end
		return false, "This server is not a match server"
	end
	local t: MatchTicketStore.Ticket? = nil
	for _ = 1, 5 do -- MemoryStore write may still be propagating; ~10 s total
		t = MatchTicketStore.get(game.PrivateServerId)
		if t then
			break
		end
		task.wait(2)
	end
	if not t then
		return false, "Match data not found"
	end
	if t.Version ~= ModeLobbyConfig.ConfigVersion then
		return false, "Match data version mismatch"
	end
	if t.PrivateServerId ~= game.PrivateServerId then
		return false, "Match data does not belong to this server"
	end
	local built, err = options.MatchContext.build(t.Context)
	if not built then
		return false, err or "Match settings rejected"
	end
	ticket = t
	ctx = built
	return true, nil
end

-- Call from the existing WaveService match-end hook (Won or Lost) in the match place.
function MatchServerBridge.onMatchEnded()
	ended = true
	local mode = ctx and ModeLobbyConfig.getMode(ctx.Mode)
	for _, p in Players:GetPlayers() do
		p:SetAttribute("CanReplay", mode ~= nil and mode.AllowReplay)
	end
	autoReturnToken += 1
	local token = autoReturnToken
	task.delay(options.AutoReturn or 90, function()
		if token == autoReturnToken and ended then
			MatchServerBridge.returnToHub(Players:GetPlayers(), "Returning to the hub")
		end
	end)
end

-- Replay in the same reserved server with the same settings. Wire RequestReplay to this in the match place.
function MatchServerBridge.replay(): (boolean, string?)
	if not ended or not ctx then
		return false, "Match is still running"
	end
	local mode = ModeLobbyConfig.getMode(ctx.Mode)
	if not mode or not mode.AllowReplay then
		return false, "Replay is not available in this mode"
	end
	if options.resetMatch then
		options.resetMatch()
	end
	ended = false
	started = false
	autoReturnToken += 1 -- cancels the pending auto return
	if not tryStart() then
		ended = true
		return false, "Could not restart"
	end
	return true, nil
end

function MatchServerBridge.getContext(): any
	return ctx
end

function MatchServerBridge.getTicket(): MatchTicketStore.Ticket?
	return ticket
end

function MatchServerBridge.init(opts: Options)
	options = opts

	local remotes = TD:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = TD
	-- Same remote name as the hub, so the existing "Return to Hub" button works in the match place too.
	local returnRemote = remotes:FindFirstChild("HubReturn")
	if not returnRemote then
		local e = Instance.new("RemoteEvent")
		e.Name = "HubReturn"
		e.Parent = remotes
		returnRemote = e
	end
	(returnRemote :: RemoteEvent).OnServerEvent:Connect(function(player: Player)
		local now = os.clock()
		if now - (lastReturn[player] or 0) < 3 then
			return
		end
		lastReturn[player] = now
		MatchServerBridge.returnToHub({ player }, nil)
	end)

	Players.PlayerAdded:Connect(function(player: Player)
		while not loaded do
			task.wait(0.2)
		end
		admit(player)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		lastReturn[player] = nil
		-- A disconnect mid-match keeps the slot: the hub offers Rejoin through the active-match record.
		-- After the match ends there is nothing to rejoin.
		if ended and ticket then
			MatchTicketStore.clearActive(player.UserId, ticket.MatchId)
		end
	end)

	game:BindToClose(function()
		-- Reserved servers close when the last player leaves; drop the ticket so it cannot be reused.
		if ticket and ticket.PrivateServerId then
			MatchTicketStore.remove(ticket.PrivateServerId)
		end
	end)

	task.spawn(function()
		local ok, err = loadTicket()
		if not ok then
			failed = err or "Match setup failed"
			warn("[MatchBridge] " .. failed)
		end
		loaded = true
		for _, p in Players:GetPlayers() do
			admit(p)
		end
		if failed then
			return
		end
		-- Wait for the party, then start.
		local deadline = os.clock() + (options.ArrivalTimeout or 45)
		while not started do
			local all = true
			if studioSolo then
				all = #Players:GetPlayers() > 0
			else
				for _, userId in ctx.Party do
					if not arrived[userId] then
						all = false
						break
					end
				end
			end
			if all or os.clock() >= deadline then
				if tryStart() then
					break
				end
				if os.clock() >= deadline + 120 then
					warn("[MatchBridge] nobody arrived; server will close when empty")
					break
				end
			end
			task.wait(0.5)
		end
	end)
end

return MatchServerBridge
