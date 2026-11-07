--!strict
-- MatchTicketStore: the server-only record of every launched match (the "ticket").
-- Install as ModuleScript ServerScriptService.TD.Services.Match.MatchTicketStore.
--
-- The hub writes the ticket BEFORE teleporting; the match server reads it by its own
-- game.PrivateServerId, which the client cannot influence. Client TeleportData is never the
-- source of truth (it only carries the MatchId as a hint for logs).
--
-- Reserved mode: MemoryStore sorted maps (shared by every server of the experience).
-- Local mode: an in-process table (same place, Studio play test).

local MemoryStoreService = game:GetService("MemoryStoreService")
local HttpService = game:GetService("HttpService")

-- Context is exactly what the live MatchContext.build(raw) returned on the hub:
-- { Mode, MapId, Stage, Difficulty, Party = { UserId } }. The match server builds it AGAIN from this
-- table (same validation, same Config) before WaveService.startMatch, so a stale or edited ticket
-- cannot start an invalid match. Context.Party is the allow-list of who may enter.
export type Ticket = {
	Version: number,
	MatchId: string,
	Context: { [string]: any },
	ModeId: string,
	Selection: { [string]: string }, -- lobby options as picked (World, Stage, Difficulty, ...)
	Loadouts: { [string]: { string } }, -- tostring(UserId) -> unit ids (re-validated against the profile)
	LeaderUserId: number,
	Public: boolean,
	PartyId: string,
	CreatedAt: number, -- os.time()
	HubPlaceId: number,
	PrivateServerId: string?, -- set by MatchLaunchService after ReserveServer
	AccessCode: string?, -- server-only; lets players rejoin the same reserved server
	Local: boolean,
}

export type ActiveMatch = {
	MatchId: string,
	PlaceId: number,
	AccessCode: string,
	ExpiresAt: number,
}

local MatchTicketStore = {}

local TICKET_TTL = 2 * 60 * 60 -- a match never lives longer than 2 h
local ACTIVE_TTL = 30 * 60

local useLocal = false
local localTickets: { [string]: Ticket } = {}
local localActive: { [number]: ActiveMatch } = {}

local ticketMap: MemoryStoreSortedMap? = nil
local activeMap: MemoryStoreSortedMap? = nil

local function maps(): (MemoryStoreSortedMap, MemoryStoreSortedMap)
	if not ticketMap then
		ticketMap = MemoryStoreService:GetSortedMap("TD_MatchTickets_v1")
		activeMap = MemoryStoreService:GetSortedMap("TD_ActiveMatch_v1")
	end
	return ticketMap :: MemoryStoreSortedMap, activeMap :: MemoryStoreSortedMap
end

-- MemoryStore calls can throttle; retry with backoff (0.5, 1, 2 s).
local function retry<T>(label: string, fn: () -> T): (boolean, T?)
	local lastErr: any = nil
	for attempt = 1, 4 do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastErr = result
		if attempt < 4 then
			task.wait(0.5 * 2 ^ (attempt - 1))
		end
	end
	warn(("[MatchTicketStore] %s failed: %s"):format(label, tostring(lastErr)))
	return false, nil
end

-- true = keep everything in this server (Studio / same-place prototype).
function MatchTicketStore.setLocal(enabled: boolean)
	useLocal = enabled
end

function MatchTicketStore.newMatchId(): string
	return HttpService:GenerateGUID(false)
end

-- Key = PrivateServerId of the reserved server (Reserved) or MatchId (Local).
function MatchTicketStore.put(key: string, ticket: Ticket): boolean
	if useLocal then
		localTickets[key] = table.clone(ticket)
		return true
	end
	local tickets = maps()
	local ok = retry("put " .. key, function()
		tickets:SetAsync(key, ticket, TICKET_TTL)
		return true
	end)
	return ok
end

function MatchTicketStore.get(key: string): Ticket?
	if useLocal then
		return localTickets[key]
	end
	local tickets = maps()
	local ok, value = retry("get " .. key, function()
		return tickets:GetAsync(key)
	end)
	if ok and typeof(value) == "table" then
		return value :: any
	end
	return nil
end

function MatchTicketStore.remove(key: string)
	if useLocal then
		localTickets[key] = nil
		return
	end
	local tickets = maps()
	retry("remove " .. key, function()
		tickets:RemoveAsync(key)
		return true
	end)
end

-- "Where is this player's running match?" Used by the hub to offer Rejoin after a disconnect.
function MatchTicketStore.setActive(userId: number, active: ActiveMatch)
	if useLocal then
		localActive[userId] = active
		return
	end
	local _, active_ = maps()
	retry("setActive", function()
		active_:SetAsync(tostring(userId), active, ACTIVE_TTL)
		return true
	end)
end

function MatchTicketStore.getActive(userId: number): ActiveMatch?
	local value: any
	if useLocal then
		value = localActive[userId]
	else
		local _, active_ = maps()
		local ok, v = retry("getActive", function()
			return active_:GetAsync(tostring(userId))
		end)
		value = if ok then v else nil
	end
	if typeof(value) == "table" and (value.ExpiresAt or 0) > os.time() then
		return value
	end
	return nil
end

function MatchTicketStore.clearActive(userId: number, matchId: string?)
	if useLocal then
		local a = localActive[userId]
		if a and (not matchId or a.MatchId == matchId) then
			localActive[userId] = nil
		end
		return
	end
	local _, active_ = maps()
	retry("clearActive", function()
		-- only clear if it still points at this match (the player may already be in a newer one).
		-- UpdateAsync returning nil cancels instead of deleting, so read then remove.
		local old: any = active_:GetAsync(tostring(userId))
		if matchId and typeof(old) == "table" and old.MatchId ~= matchId then
			return true
		end
		active_:RemoveAsync(tostring(userId))
		return true
	end)
end

return MatchTicketStore
