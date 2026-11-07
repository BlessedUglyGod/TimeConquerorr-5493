--!strict
-- PartyService: parties for every mode lobby (hub server only).
-- Install as ModuleScript ServerScriptService.TD.Services.Match.PartyService and call
-- PartyService.init({...}) once from GameServer (see docs/multiplayer/INTEGRATION.md).
--
-- One party per player. 1..6 members, capped per mode by ModeLobbyConfig. The leader picks the
-- options; changing an option un-readies everyone. Start = every member ready + mode rules pass,
-- then a short countdown, then opts.launch(party) (MatchLaunchService.launch).
--
-- Remotes (ReplicatedStorage.TD.Remotes):
--   LobbyAction  client -> server  (action: string, arg: any)   intent only, validated here
--   LobbyState   server -> client  (snapshot table)              what the lobby UI draws

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local TD = ReplicatedStorage:WaitForChild("TD")
local ModeLobbyConfig = require(TD:WaitForChild("Lobby"):WaitForChild("ModeLobbyConfig"))

export type Party = {
	Id: string,
	ModeId: string,
	LeaderUserId: number,
	Members: { Player },
	Ready: { [number]: boolean },
	Selection: { [string]: string },
	Public: boolean,
	Invited: { [number]: number }, -- userId -> os.clock() of the invite
	State: "Open" | "Starting" | "Launching",
	CountdownEnds: number?,
}

export type Options = {
	-- Unit ids of the player's equipped team (PlayerDataService). Shown in the lobby, sent in the ticket.
	getLoadout: (Player) -> { string },
	-- Hands the ready party to MatchLaunchService. Returns false + reason to keep the party in the lobby.
	launch: (Party) -> (boolean, string?),
	-- Mode requirements beyond team size (account level, unlock flags). Default: allowed.
	checkRequirements: ((Player, ModeLobbyConfig.ModeDef) -> (boolean, string?))?,
	-- Only players standing in the hub may use lobbies. Default: HubLocation attribute == "Hub" or unset.
	isInHub: ((Player) -> boolean)?,
	notify: ((Player, string) -> ())?,
}

local PartyService = {}

local INVITE_TTL = 60
local ACTION_THROTTLE = 0.2

local options: Options
local parties: { [string]: Party } = {}
local partyOf: { [Player]: Party } = {}
local browsing: { [Player]: string } = {} -- player -> mode id whose lobby window is open
local lastAction: { [Player]: number } = {}
local stateRemote: RemoteEvent

local function notify(player: Player, text: string)
	if options.notify then
		options.notify(player, text)
	end
end

local function inHub(player: Player): boolean
	if options.isInHub then
		return options.isInHub(player)
	end
	local loc = player:GetAttribute("HubLocation")
	return loc == nil or loc == "Hub"
end

local function capOf(party: Party): number
	local mode = ModeLobbyConfig.getMode(party.ModeId)
	return if mode then math.min(mode.MaxPlayers, ModeLobbyConfig.GlobalMaxPlayers) else 1
end

local function snapshotParty(party: Party): { [string]: any }
	local members = {}
	for _, p in party.Members do
		table.insert(members, {
			UserId = p.UserId,
			Name = p.DisplayName,
			Ready = party.Ready[p.UserId] == true,
			Leader = p.UserId == party.LeaderUserId,
			Team = options.getLoadout(p),
		})
	end
	return {
		Id = party.Id,
		ModeId = party.ModeId,
		LeaderUserId = party.LeaderUserId,
		Members = members,
		Max = capOf(party),
		Selection = table.clone(party.Selection),
		Public = party.Public,
		State = party.State,
		Countdown = if party.CountdownEnds then math.max(0, math.ceil(party.CountdownEnds - os.clock())) else nil,
	}
end

local function browseList(modeId: string): { { [string]: any } }
	local list = {}
	for _, party in parties do
		if party.ModeId == modeId and party.Public and party.State == "Open" and #party.Members < capOf(party) then
			local leader = Players:GetPlayerByUserId(party.LeaderUserId)
			table.insert(list, {
				Id = party.Id,
				LeaderName = if leader then leader.DisplayName else "?",
				Count = #party.Members,
				Max = capOf(party),
				Selection = table.clone(party.Selection),
			})
		end
	end
	return list
end

local function sendTo(player: Player)
	local party = partyOf[player]
	local modeId = if party then party.ModeId else browsing[player]
	if not modeId then
		stateRemote:FireClient(player, { Open = false })
		return
	end
	local invites = {}
	for _, other in parties do
		local t = other.Invited[player.UserId]
		if t and os.clock() - t < INVITE_TTL and other ~= party then
			local leader = Players:GetPlayerByUserId(other.LeaderUserId)
			table.insert(invites, { Id = other.Id, ModeId = other.ModeId, LeaderName = if leader then leader.DisplayName else "?" })
		end
	end
	stateRemote:FireClient(player, {
		Open = true,
		ModeId = modeId,
		Party = if party then snapshotParty(party) else nil,
		Browse = if party then nil else browseList(modeId),
		Invites = invites,
	})
end

-- Members of the party plus everyone browsing that mode (their public list changed).
local function broadcast(modeId: string)
	for p, m in browsing do
		if m == modeId then
			sendTo(p)
		end
	end
	for p, party in partyOf do
		if party.ModeId == modeId and not browsing[p] then
			sendTo(p)
		end
	end
end

local function unreadyAll(party: Party)
	for userId in party.Ready do
		party.Ready[userId] = false
	end
	if party.State == "Starting" then
		party.State = "Open"
		party.CountdownEnds = nil
	end
end

local function removeMember(player: Player)
	local party = partyOf[player]
	if not party then
		return
	end
	partyOf[player] = nil
	local i = table.find(party.Members, player)
	if i then
		table.remove(party.Members, i)
	end
	party.Ready[player.UserId] = nil
	if #party.Members == 0 then
		parties[party.Id] = nil
	else
		if party.LeaderUserId == player.UserId then
			party.LeaderUserId = party.Members[1].UserId
			notify(party.Members[1], "You are now the party leader")
		end
		if party.State == "Starting" then
			party.State = "Open"
			party.CountdownEnds = nil
		end
	end
	broadcast(party.ModeId)
end

local function canJoinMode(player: Player, mode: ModeLobbyConfig.ModeDef): (boolean, string?)
	if not mode.Enabled then
		return false, mode.Label .. " is not open yet"
	end
	if not inHub(player) then
		return false, "Return to the hub first"
	end
	local req = mode.Requirements
	if req and req.MinTeamSize and #options.getLoadout(player) < req.MinTeamSize then
		return false, "Equip at least " .. req.MinTeamSize .. " unit(s)"
	end
	if options.checkRequirements then
		return options.checkRequirements(player, mode)
	end
	return true, nil
end

local function addMember(player: Player, party: Party): (boolean, string?)
	local mode = ModeLobbyConfig.getMode(party.ModeId)
	if not mode then
		return false, "Unknown mode"
	end
	local ok, why = canJoinMode(player, mode)
	if not ok then
		return false, why
	end
	if party.State ~= "Open" then
		return false, "That party is already starting"
	end
	if #party.Members >= capOf(party) then
		return false, "Party is full"
	end
	removeMember(player)
	table.insert(party.Members, player)
	party.Ready[player.UserId] = false
	party.Invited[player.UserId] = nil
	partyOf[player] = party
	broadcast(party.ModeId)
	return true, nil
end

local function isLeader(player: Player, party: Party?): boolean
	return party ~= nil and party.LeaderUserId == player.UserId and party.State ~= "Launching"
end

function PartyService.canStart(party: Party): (boolean, string?)
	local mode = ModeLobbyConfig.getMode(party.ModeId)
	if not mode or not mode.Enabled then
		return false, "Mode is closed"
	end
	if #party.Members < mode.MinPlayers then
		return false, ("Need at least %d players"):format(mode.MinPlayers)
	end
	if #party.Members > capOf(party) then
		return false, "Too many players"
	end
	local ok, why = ModeLobbyConfig.validateSelection(mode, party.Selection)
	if not ok then
		return false, why
	end
	for _, p in party.Members do
		if party.Ready[p.UserId] ~= true and p.UserId ~= party.LeaderUserId then
			return false, p.DisplayName .. " is not ready"
		end
		local okJoin, whyJoin = canJoinMode(p, mode)
		if not okJoin then
			return false, p.DisplayName .. ": " .. (whyJoin or "not allowed")
		end
	end
	return true, nil
end

local handlers: { [string]: (Player, any) -> () } = {}

handlers.Open = function(player, modeId)
	if typeof(modeId) ~= "string" or not ModeLobbyConfig.getMode(modeId) then
		return
	end
	browsing[player] = modeId
	sendTo(player)
end

handlers.Close = function(player, _)
	browsing[player] = nil
end

handlers.Create = function(player, isPublic)
	local modeId = browsing[player]
	local mode = modeId and ModeLobbyConfig.getMode(modeId)
	if not mode then
		return
	end
	local ok, why = canJoinMode(player, mode)
	if not ok then
		notify(player, why or "Not allowed")
		return
	end
	local public = isPublic == true and mode.AllowPublic or not mode.AllowPrivate
	removeMember(player)
	local party: Party = {
		Id = HttpService:GenerateGUID(false),
		ModeId = mode.Id,
		LeaderUserId = player.UserId,
		Members = { player },
		Ready = { [player.UserId] = false },
		Selection = ModeLobbyConfig.defaultSelection(mode),
		Public = public,
		Invited = {},
		State = "Open",
		CountdownEnds = nil,
	}
	ModeLobbyConfig.fixDependents(mode, party.Selection)
	parties[party.Id] = party
	partyOf[player] = party
	broadcast(mode.Id)
end

handlers.Join = function(player, partyId)
	local party = typeof(partyId) == "string" and parties[partyId] or nil
	if not party then
		notify(player, "That party no longer exists")
		return
	end
	local invited = party.Invited[player.UserId]
	if not party.Public and not (invited and os.clock() - invited < INVITE_TTL) then
		notify(player, "That party is private")
		return
	end
	local ok, why = addMember(player, party)
	if not ok then
		notify(player, why or "Cannot join")
	end
end

-- Public matchmaking inside this hub server: the fullest open public party of the mode, else a new one.
handlers.QuickJoin = function(player, _)
	local modeId = browsing[player]
	if not modeId then
		return
	end
	local best: Party? = nil
	for _, party in parties do
		if party.ModeId == modeId and party.Public and party.State == "Open" and #party.Members < capOf(party) then
			if not best or #party.Members > #best.Members then
				best = party
			end
		end
	end
	if best then
		local ok, why = addMember(player, best)
		if not ok then
			notify(player, why or "Cannot join")
		end
	else
		handlers.Create(player, true)
	end
end

handlers.Leave = function(player, _)
	removeMember(player)
	sendTo(player)
end

handlers.SetOption = function(player, arg)
	local party = partyOf[player]
	if not isLeader(player, party) or typeof(arg) ~= "table" then
		return
	end
	local p = party :: Party
	local mode = ModeLobbyConfig.getMode(p.ModeId)
	local optionId, choiceId = arg.Option, arg.Choice
	if not mode or typeof(optionId) ~= "string" or typeof(choiceId) ~= "string" then
		return
	end
	local opt = ModeLobbyConfig.getOption(mode, optionId)
	if not opt or not ModeLobbyConfig.getChoice(opt, choiceId) then
		return
	end
	local candidate = table.clone(p.Selection)
	candidate[optionId] = choiceId
	ModeLobbyConfig.fixDependents(mode, candidate)
	local ok, why = ModeLobbyConfig.validateSelection(mode, candidate)
	if not ok then
		notify(player, why or "Not available")
		return
	end
	p.Selection = candidate
	unreadyAll(p)
	broadcast(p.ModeId)
end

handlers.SetPublic = function(player, value)
	local party = partyOf[player]
	if not isLeader(player, party) or typeof(value) ~= "boolean" then
		return
	end
	local p = party :: Party
	local mode = ModeLobbyConfig.getMode(p.ModeId)
	if not mode or (value and not mode.AllowPublic) or (not value and not mode.AllowPrivate) then
		return
	end
	p.Public = value
	broadcast(p.ModeId)
end

handlers.SetReady = function(player, value)
	local party = partyOf[player]
	if not party or party.State == "Launching" or typeof(value) ~= "boolean" then
		return
	end
	party.Ready[player.UserId] = value
	if not value and party.State == "Starting" then
		party.State = "Open"
		party.CountdownEnds = nil
	end
	broadcast(party.ModeId)
end

-- Invite a player who is in this hub server. Friends on other servers get the Roblox invite prompt
-- from the client (SocialService:PromptGameInvite), join the experience, then accept here.
handlers.Invite = function(player, userId)
	local party = partyOf[player]
	if not isLeader(player, party) or typeof(userId) ~= "number" then
		return
	end
	local p = party :: Party
	local mode = ModeLobbyConfig.getMode(p.ModeId)
	local target = Players:GetPlayerByUserId(userId)
	if not mode or not mode.AllowInvites or not target or target == player then
		return
	end
	p.Invited[userId] = os.clock()
	notify(target, player.DisplayName .. " invited you to a " .. mode.Label .. " party")
	sendTo(target)
end

handlers.Kick = function(player, userId)
	local party = partyOf[player]
	if not isLeader(player, party) or typeof(userId) ~= "number" or userId == player.UserId then
		return
	end
	local target = Players:GetPlayerByUserId(userId)
	if target and partyOf[target] == party then
		removeMember(target)
		notify(target, "You were removed from the party")
		sendTo(target)
	end
end

handlers.Start = function(player, _)
	local party = partyOf[player]
	if not isLeader(player, party) then
		return
	end
	local p = party :: Party
	if p.State ~= "Open" then
		return
	end
	local ok, why = PartyService.canStart(p)
	if not ok then
		notify(player, why or "Cannot start")
		return
	end
	local mode = ModeLobbyConfig.getMode(p.ModeId) :: ModeLobbyConfig.ModeDef
	p.State = "Starting"
	p.CountdownEnds = os.clock() + mode.StartCountdown
	broadcast(p.ModeId)
end

handlers.CancelStart = function(player, _)
	local party = partyOf[player]
	if party and isLeader(player, party) and party.State == "Starting" then
		party.State = "Open"
		party.CountdownEnds = nil
		broadcast(party.ModeId)
	end
end

local function launchParty(party: Party)
	local ok, why = PartyService.canStart(party)
	if not ok then
		party.State = "Open"
		party.CountdownEnds = nil
		for _, p in party.Members do
			notify(p, "Start cancelled: " .. (why or "?"))
		end
		broadcast(party.ModeId)
		return
	end
	party.State = "Launching"
	party.CountdownEnds = nil
	broadcast(party.ModeId)
	local okLaunch, whyLaunch = options.launch(party)
	if not okLaunch then
		party.State = "Open"
		for _, p in party.Members do
			notify(p, "Launch failed: " .. (whyLaunch or "?"))
		end
		broadcast(party.ModeId)
		return
	end
	-- Launched: the party is done; players are in the match (or travelling to it).
	parties[party.Id] = nil
	for _, p in party.Members do
		partyOf[p] = nil
		browsing[p] = nil
		stateRemote:FireClient(p, { Open = false })
	end
	broadcast(party.ModeId)
end

function PartyService.getParty(player: Player): Party?
	return partyOf[player]
end

-- For tests and the debug hook: list of party snapshots.
function PartyService.debugList(): { { [string]: any } }
	local out = {}
	for _, party in parties do
		table.insert(out, snapshotParty(party))
	end
	return out
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

function PartyService.init(opts: Options)
	options = opts
	local remotes = TD:FindFirstChild("Remotes") or Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = TD
	local actionRemote = ensureRemote(remotes, "LobbyAction")
	stateRemote = ensureRemote(remotes, "LobbyState")

	actionRemote.OnServerEvent:Connect(function(player: Player, action: any, arg: any)
		if typeof(action) ~= "string" then
			return
		end
		local handler = handlers[action]
		if not handler then
			return
		end
		local now = os.clock()
		if now - (lastAction[player] or 0) < ACTION_THROTTLE then
			return
		end
		lastAction[player] = now
		handler(player, arg)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		removeMember(player)
		browsing[player] = nil
		lastAction[player] = nil
	end)

	-- Countdown + hygiene loop (2 Hz is enough for a lobby).
	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, party in parties do
				-- members who left the hub (died into a match, teleported) drop out of the party
				for i = #party.Members, 1, -1 do
					local p = party.Members[i]
					if party.State ~= "Launching" and (not p.Parent or not inHub(p)) then
						removeMember(p)
					end
				end
				if parties[party.Id] and party.State == "Starting" then
					if party.CountdownEnds and os.clock() >= party.CountdownEnds then
						task.spawn(launchParty, party)
					else
						broadcast(party.ModeId) -- countdown tick
					end
				end
			end
		end
	end)
end

return PartyService
