--!strict
-- LobbyClient: mode lobby window (Story layout first; other modes use the same window with their options).
-- Install as ModuleScript StarterPlayer.StarterPlayerScripts.TD.LobbyClient. From TDClient:
--   local LobbyClient = require(script.Parent.LobbyClient)
--   LobbyClient.init({ openTeam = function() Menus.openTeam() end })
--   HubClient.registerMenu("Lobby_Story", function() LobbyClient.open("Story") end)
-- Spec: docs/multiplayer/STORY_LOBBY_UI.md. The client only sends intent through LobbyAction; the
-- server (PartyService) decides and answers with a LobbyState snapshot that this window redraws.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

local player = Players.LocalPlayer
local TD = ReplicatedStorage:WaitForChild("TD")
local Remotes = TD:WaitForChild("Remotes")
local ModeLobbyConfig = require(TD:WaitForChild("Lobby"):WaitForChild("ModeLobbyConfig"))

export type InitOptions = {
	openTeam: (() -> ())?, -- opens the existing Team window ("Edit team")
}

local LobbyClient = {}

local C = {
	Panel = Color3.fromRGB(28, 32, 58),
	Card = Color3.fromRGB(44, 50, 86),
	Accent = Color3.fromRGB(214, 168, 72),
	Good = Color3.fromRGB(80, 190, 120),
	Bad = Color3.fromRGB(200, 80, 90),
	Muted = Color3.fromRGB(150, 155, 180),
	Text = Color3.new(1, 1, 1),
}

local initOptions: InitOptions = {}
local gui: ScreenGui
local body: Frame
local title: TextLabel
local lastState: { [string]: any }? = nil
local openModeId: string? = nil

local function send(action: string, arg: any?)
	(Remotes:WaitForChild("LobbyAction") :: RemoteEvent):FireServer(action, arg)
end

local function corner(parent: Instance, r: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = parent
end

local function label(parent: Instance, text: string, size: number, color: Color3?): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, 0, 0, size + 8)
	l.Font = Enum.Font.GothamMedium
	l.TextSize = size
	l.TextColor3 = color or C.Text
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.Text = text
	l.Parent = parent
	return l
end

local function button(parent: Instance, text: string, color: Color3, onClick: () -> (), width: number?): TextButton
	local b = Instance.new("TextButton")
	b.Size = if width then UDim2.fromOffset(width, 40) else UDim2.new(1, 0, 0, 40) -- 40 px: touch friendly
	b.BackgroundColor3 = color
	b.TextColor3 = C.Text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 16
	b.Text = text
	b.AutoButtonColor = true
	b.Parent = parent
	corner(b, 8)
	b.Activated:Connect(onClick)
	return b
end

local function column(parent: Instance, x: number, w: number): Frame
	local f = Instance.new("Frame")
	f.BackgroundTransparency = 1
	f.Position = UDim2.new(x, 8, 0, 0)
	f.Size = UDim2.new(w, -16, 1, 0)
	f.Parent = parent
	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 6)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = f
	return f
end

local function clear()
	for _, child in body:GetChildren() do
		child:Destroy()
	end
end

local function summary(mode: ModeLobbyConfig.ModeDef, selection: { [string]: string }): string
	local parts = {}
	for _, opt in mode.Options do
		local choice = ModeLobbyConfig.getChoice(opt, selection[opt.Id] or "")
		table.insert(parts, if choice then choice.Label else "?")
	end
	return table.concat(parts, " · ")
end

-- Leader: "< value >" cycler over valid choices. Others: read-only text.
local function optionRow(parent: Instance, mode: ModeLobbyConfig.ModeDef, opt: ModeLobbyConfig.OptionDef, selection: { [string]: string }, canEdit: boolean)
	local row = Instance.new("Frame")
	row.BackgroundColor3 = C.Card
	row.Size = UDim2.new(1, 0, 0, 44)
	row.Parent = parent
	corner(row, 8)
	local name = label(row, opt.Label, 14, C.Muted)
	name.Position = UDim2.fromOffset(10, 0)
	name.Size = UDim2.new(0.35, 0, 1, 0)
	local current = ModeLobbyConfig.getChoice(opt, selection[opt.Id] or "")
	local value = label(row, if current then current.Label else "?", 16)
	value.Position = UDim2.new(0.35, 40, 0, 0)
	value.Size = UDim2.new(0.65, -90, 1, 0)
	value.TextXAlignment = Enum.TextXAlignment.Center
	if not canEdit then
		return
	end
	local choices = ModeLobbyConfig.availableChoices(mode, opt.Id, selection)
	local function step(dir: number)
		if #choices <= 1 then
			return
		end
		local idx = 1
		for i, c in choices do
			if current and c.Id == current.Id then
				idx = i
			end
		end
		local nextChoice = choices[(idx - 1 + dir) % #choices + 1]
		send("SetOption", { Option = opt.Id, Choice = nextChoice.Id })
	end
	local prev = button(row, "<", C.Panel, function() step(-1) end, 36)
	prev.Position = UDim2.new(0.35, 0, 0, 2)
	local nxt = button(row, ">", C.Panel, function() step(1) end, 36)
	nxt.AnchorPoint = Vector2.new(1, 0)
	nxt.Position = UDim2.new(1, -4, 0, 2)
	-- locked choices are listed so players know they exist
	local locked = 0
	for _, c in opt.Choices do
		if c.Enabled == false then
			locked += 1
		end
	end
	if locked > 0 then
		value.Text ..= ("  (+%d locked)"):format(locked)
	end
end

local function drawBrowse(state: { [string]: any }, mode: ModeLobbyConfig.ModeDef)
	local left = column(body, 0, 0.6)
	local right = column(body, 0.6, 0.4)
	label(left, "Open parties", 16, C.Accent)
	local browse = state.Browse or {}
	if #browse == 0 then
		label(left, "No public parties yet. Create one or use Quick Join.", 14, C.Muted)
	end
	for _, entry in browse do
		local card = Instance.new("Frame")
		card.BackgroundColor3 = C.Card
		card.Size = UDim2.new(1, 0, 0, 52)
		card.Parent = left
		corner(card, 8)
		local l1 = label(card, ("%s  %d/%d"):format(entry.LeaderName, entry.Count, entry.Max), 15)
		l1.Position = UDim2.fromOffset(10, 2)
		l1.Size = UDim2.new(1, -110, 0, 24)
		local l2 = label(card, summary(mode, entry.Selection), 12, C.Muted)
		l2.Position = UDim2.fromOffset(10, 26)
		l2.Size = UDim2.new(1, -110, 0, 20)
		local join = button(card, "Join", C.Good, function() send("Join", entry.Id) end, 90)
		join.AnchorPoint = Vector2.new(1, 0.5)
		join.Position = UDim2.new(1, -6, 0.5, 0)
	end
	for _, inv in state.Invites or {} do
		button(left, ("Accept invite from %s"):format(inv.LeaderName), C.Accent, function() send("Join", inv.Id) end)
	end
	label(right, "Play", 16, C.Accent)
	button(right, "Quick Join", C.Good, function() send("QuickJoin") end)
	if mode.AllowPublic then
		button(right, "Create Public Party", C.Card, function() send("Create", true) end)
	end
	if mode.AllowPrivate then
		button(right, "Create Private Party", C.Card, function() send("Create", false) end)
	end
	label(right, "Solo: create a party and press Start.", 12, C.Muted)
end

local function drawParty(state: { [string]: any }, mode: ModeLobbyConfig.ModeDef)
	local party = state.Party
	local isLeader = party.LeaderUserId == player.UserId
	local editable = isLeader and party.State == "Open"
	local left = column(body, 0, 0.45)
	local right = column(body, 0.45, 0.55)

	label(left, ("Party %d/%d  ·  %s"):format(#party.Members, party.Max, if party.Public then "Public" else "Private"), 16, C.Accent)
	local me: { [string]: any }? = nil
	for i = 1, party.Max do
		local m = party.Members[i]
		local slot = Instance.new("Frame")
		slot.BackgroundColor3 = if m then C.Card else C.Panel
		slot.Size = UDim2.new(1, 0, 0, 40)
		slot.Parent = left
		corner(slot, 8)
		if m then
			if m.UserId == player.UserId then
				me = m
			end
			local text = (if m.Leader then "★ " else "") .. m.Name .. ("  ·  %d units"):format(#m.Team)
			local l = label(slot, text, 15)
			l.Position = UDim2.fromOffset(10, 0)
			l.Size = UDim2.new(1, -120, 1, 0)
			local ready = label(slot, if m.Ready or m.Leader then "READY" else "not ready", 13, if m.Ready or m.Leader then C.Good else C.Muted)
			ready.AnchorPoint = Vector2.new(1, 0)
			ready.Position = UDim2.new(1, if editable and not m.Leader then -56 else -8, 0, 0)
			ready.Size = UDim2.new(0, 70, 1, 0)
			ready.TextXAlignment = Enum.TextXAlignment.Right
			if editable and not m.Leader then
				local kick = button(slot, "✕", C.Bad, function() send("Kick", m.UserId) end, 40)
				kick.AnchorPoint = Vector2.new(1, 0.5)
				kick.Position = UDim2.new(1, -4, 0.5, 0)
				kick.Size = UDim2.fromOffset(40, 32)
			end
		else
			local l = label(slot, "Empty slot", 14, C.Muted)
			l.Position = UDim2.fromOffset(10, 0)
		end
	end

	label(right, mode.Label .. " settings", 16, C.Accent)
	for _, opt in mode.Options do
		optionRow(right, mode, opt, party.Selection, editable)
	end
	if editable and mode.AllowPublic and mode.AllowPrivate then
		button(right, if party.Public then "Visibility: Public" else "Visibility: Private", C.Card, function()
			send("SetPublic", not party.Public)
		end)
	end
	local team = if me then me.Team else {}
	button(right, ("Team: %d unit(s)  ·  Edit"):format(#team), C.Card, function()
		if initOptions.openTeam then
			initOptions.openTeam()
		end
	end)
	if mode.AllowInvites then
		button(right, "Invite Friends", C.Card, function()
			pcall(function()
				if SocialService:CanSendGameInviteAsync(player) then
					SocialService:PromptGameInvite(player)
				end
			end)
		end)
	end

	local actions = Instance.new("Frame")
	actions.BackgroundTransparency = 1
	actions.Size = UDim2.new(1, 0, 0, 40)
	actions.Parent = right
	local row = Instance.new("UIListLayout")
	row.FillDirection = Enum.FillDirection.Horizontal
	row.Padding = UDim.new(0, 6)
	row.Parent = actions
	if party.State == "Starting" then
		label(right, ("Starting in %d…"):format(party.Countdown or 0), 18, C.Good)
		if isLeader then
			button(actions, "Cancel", C.Bad, function() send("CancelStart") end, 110)
		end
	elseif party.State == "Launching" then
		label(right, "Launching match…", 18, C.Good)
	else
		if isLeader then
			button(actions, "Start", C.Good, function() send("Start") end, 110)
		else
			local ready = me ~= nil and me.Ready
			button(actions, if ready then "Unready" else "Ready", if ready then C.Muted else C.Good, function()
				send("SetReady", not ready)
			end, 110)
		end
		button(actions, "Leave", C.Bad, function() send("Leave") end, 90)
	end
end

local function redraw()
	if not gui or not lastState then
		return
	end
	local state = lastState :: { [string]: any }
	if not state.Open then
		gui.Enabled = false
		return
	end
	local mode = ModeLobbyConfig.getMode(state.ModeId)
	if not mode then
		return
	end
	gui.Enabled = true
	title.Text = mode.Label .. " Lobby"
	clear()
	if state.Party then
		drawParty(state, mode)
	else
		drawBrowse(state, mode)
	end
end

local function build()
	gui = Instance.new("ScreenGui")
	gui.Name = "ModeLobby"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromScale(0.7, 0.7)
	panel.BackgroundColor3 = C.Panel
	panel.Parent = gui
	corner(panel, 14)
	local limit = Instance.new("UISizeConstraint")
	limit.MinSize = Vector2.new(520, 380)
	limit.MaxSize = Vector2.new(820, 540)
	limit.Parent = panel

	title = label(panel, "Lobby", 22, C.Accent)
	title.Position = UDim2.fromOffset(16, 8)
	title.Size = UDim2.new(1, -80, 0, 32)
	local close = button(panel, "✕", C.Bad, function() LobbyClient.close() end, 40)
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -10, 0, 8)

	body = Instance.new("Frame")
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromOffset(8, 52)
	body.Size = UDim2.new(1, -16, 1, -60)
	body.Parent = panel
end

function LobbyClient.open(modeId: string)
	openModeId = modeId
	send("Open", modeId)
end

-- Closing the window keeps the party (players can walk around the hub while waiting for friends).
function LobbyClient.close()
	openModeId = nil
	send("Close")
	gui.Enabled = false
end

function LobbyClient.isOpen(): boolean
	return openModeId ~= nil
end

function LobbyClient.init(opts: InitOptions?)
	initOptions = opts or {}
	build()
	(Remotes:WaitForChild("LobbyState") :: RemoteEvent).OnClientEvent:Connect(function(state: any)
		if typeof(state) ~= "table" then
			return
		end
		lastState = state
		-- party updates arrive even with the window closed; only show it if the player opened it
		-- or is in a party that is starting/launching
		if state.Open and not openModeId and not (state.Party and state.Party.State ~= "Open") then
			return
		end
		redraw()
	end)
end

return LobbyClient
