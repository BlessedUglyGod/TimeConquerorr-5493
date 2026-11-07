--!strict
-- HubHud: the hub's own HUD (never shown in a match). Install as ModuleScript
-- StarterPlayer.StarterPlayerScripts.TD.HubHud. Spec: docs/ui/SCREENS.md, "Hub HUD" and "Gate Board".
--
-- What it does (all functional, no mock data):
--   * currency chips bound to the server-written player attributes Gems / Gold
--   * a dock of system shortcuts; each one calls the menu handler registered for its menu id, the same
--     handlers HubClient uses for stations. Unregistered ids show as locked ("Coming soon").
--   * a location strip that names the district you are standing in (from HubConfig zones)
--   * the Gate Board: Play opens a mode picker built from ModeLobbyConfig; an enabled mode calls
--     opts.openLobby(modeId) (LobbyClient.open), a locked mode explains why.
--
-- From TDClient:
--   local HubHud = require(script.Parent.HubHud)
--   HubHud.registerMenu("Summon", Menus.openSummon)        -- same functions as HubClient.registerMenu
--   HubHud.registerMenu("Team", Menus.openTeam)
--   HubHud.init({ openLobby = function(modeId) LobbyClient.open(modeId) end })
--   UiState.onChanged(function(state) HubHud.setVisible(state == "Hub") end) -- adapt to UiState's API

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local TD = ReplicatedStorage:WaitForChild("TD")
local UI = TD:WaitForChild("UI")
local Theme = require(UI:WaitForChild("Theme"))
local UiKit = require(UI:WaitForChild("UiKit"))
local HubConfig = require(TD:WaitForChild("HubConfig"))

local C = Theme.Color

export type InitOptions = {
	openLobby: ((modeId: string) -> ())?,
}

type DockItem = { Id: string, Label: string, Icon: string, Menu: string }

-- Order = priority. Play is handled separately (Gate Board) and always first.
local DOCK: { DockItem } = {
	{ Id = "Summon", Label = "Summon", Icon = "Summon", Menu = "Summon" },
	{ Id = "Team", Label = "Units", Icon = "Team", Menu = "Team" },
	{ Id = "Collection", Label = "Collection", Icon = "Collection", Menu = "Collection" },
	{ Id = "Quests", Label = "Quests", Icon = "Quests", Menu = "Quests" },
	{ Id = "Shop", Label = "Shop", Icon = "Shop", Menu = "ShopGold" },
	{ Id = "Pass", Label = "Pass", Icon = "Pass", Menu = "Pass" },
}

local HubHud = {}

local menus: { [string]: () -> () } = {}
local options: InitOptions = {}
local gui: ScreenGui? = nil
local dockTiles: { [string]: TextButton } = {}
local visible = true

function HubHud.registerMenu(menuId: string, open: () -> ())
	menus[menuId] = open
	local tile = dockTiles[menuId]
	if tile then
		tile:SetAttribute("Locked", false)
	end
end

function HubHud.setVisible(on: boolean)
	visible = on
	if gui then
		gui.Enabled = on
	end
	if not on then
		UiKit.closeAll()
	end
end

local function openMenu(menuId: string)
	local open = menus[menuId]
	if open then
		UiKit.closeAll()
		open()
	else
		UiKit.toast("Coming soon", "Info")
	end
end

-- Gate Board ------------------------------------------------------------------------------------------
-- A row of tall mode cards (not a list of buttons): accent band, mode name, party size, state line.

local gateBoard: UiKit.Window? = nil

local function lockReason(mode: any): string?
	if not mode.Enabled then
		return "Opens in a later update"
	end
	local req = mode.Requirements
	if req and req.MinAccountLevel then
		local level = tonumber(player:GetAttribute("AccountLevel")) or 0
		if level < req.MinAccountLevel then
			return "Reach account level " .. req.MinAccountLevel
		end
	end
	return nil -- unlock flags and team size are checked by the server when the party starts
end

local function buildGateBoard(): UiKit.Window?
	local lobbyFolder = TD:FindFirstChild("Lobby")
	local configModule = lobbyFolder and lobbyFolder:FindFirstChild("ModeLobbyConfig")
	if not configModule or not configModule:IsA("ModuleScript") then
		return nil
	end
	local ModeLobbyConfig = (require :: any)(configModule)
	local win = UiKit.window({ Name = "TDGateBoard", Title = "Choose a mode", Accent = C.Interactive, Size = Vector2.new(880, 460) })

	local scroller = Instance.new("ScrollingFrame")
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.Size = UDim2.fromScale(1, 1)
	scroller.ScrollingDirection = Enum.ScrollingDirection.X
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.X
	scroller.CanvasSize = UDim2.new()
	scroller.ScrollBarThickness = 4
	scroller.ScrollBarImageColor3 = C.StrokeStrong
	scroller.Parent = win.Body
	UiKit.list(scroller, Enum.FillDirection.Horizontal, Theme.Space.M)

	for i, mode in ModeLobbyConfig.Modes do
		local accent = C.Mode[mode.Id] or C.Accent
		local reason = lockReason(mode)
		local card = Instance.new("TextButton")
		card.Name = mode.Id
		card.LayoutOrder = i
		card.Text = ""
		card.Size = UDim2.new(0, 168, 1, -8)
		card.BackgroundColor3 = C.Raised
		card.BorderSizePixel = 0
		card.Parent = scroller
		UiKit.corner(card, Theme.Radius.Medium)
		UiKit.stroke(card, if reason then C.Stroke else accent)
		UiKit.interactive(card, C.Overlay, C.Raised)

		local band = Instance.new("Frame") -- mode accent band at the top: the card's identity
		band.BorderSizePixel = 0
		band.BackgroundColor3 = if reason then C.Locked else accent
		band.Size = UDim2.new(1, 0, 0, 6)
		band.Parent = card
		UiKit.corner(band, Theme.Radius.Small)

		local icon = UiKit.icon(card, mode.Id, 48, if reason then C.Locked else accent)
		icon.Position = UDim2.fromOffset(Theme.Space.L, 28)

		local name = UiKit.text(card, { Text = mode.Label, Font = Theme.Font.DisplayBold, Size = Theme.TextSize.Title, Upper = true,
			Color = if reason then C.TextMuted else C.Text })
		name.Position = UDim2.fromOffset(Theme.Space.L, 92)
		name.Size = UDim2.new(1, -Theme.Space.L * 2, 0, 30)

		local party = if mode.MinPlayers == mode.MaxPlayers then tostring(mode.MaxPlayers) else mode.MinPlayers .. "-" .. mode.MaxPlayers
		local meta = UiKit.text(card, { Text = party .. " players", Size = Theme.TextSize.Caption, Color = C.TextMuted })
		meta.Position = UDim2.fromOffset(Theme.Space.L, 124)
		meta.Size = UDim2.new(1, -Theme.Space.L * 2, 0, 18)

		local state = UiKit.text(card, { Text = reason or "Open lobby", Size = Theme.TextSize.Caption, Font = Theme.Font.BodyBold,
			Color = if reason then C.TextFaint else accent })
		state.AnchorPoint = Vector2.new(0, 1)
		state.Position = UDim2.new(0, Theme.Space.L, 1, -Theme.Space.L)
		state.Size = UDim2.new(1, -Theme.Space.L * 2, 0, 18)
		state.TextWrapped = true

		card.Activated:Connect(function()
			if reason then
				UiKit.toast(mode.Label .. ": " .. reason, "Info")
			elseif options.openLobby then
				win.close()
				options.openLobby(mode.Id)
			else
				UiKit.toast("Walk to the " .. mode.Label .. " gate on the Gate Terrace", "Info")
			end
		end)
	end
	return win
end

local function openGateBoard()
	if not gateBoard then
		gateBoard = buildGateBoard()
	end
	if gateBoard then
		gateBoard.open()
	else
		UiKit.toast("Walk to a gate on the Gate Terrace to play", "Info")
	end
end

-- HUD -------------------------------------------------------------------------------------------------

local function dockTile(parent: Instance, item: DockItem, size: number, order: number): TextButton
	local b = Instance.new("TextButton")
	b.Name = item.Id
	b.LayoutOrder = order
	b.Text = ""
	b.Size = UDim2.fromOffset(size, size)
	b.BackgroundColor3 = C.Base
	b.BackgroundTransparency = Theme.Transparency.Panel
	b.BorderSizePixel = 0
	b.Parent = parent
	UiKit.corner(b, Theme.Radius.Medium)
	UiKit.stroke(b)
	UiKit.interactive(b, C.Raised, C.Base)
	local icon = UiKit.icon(b, item.Icon, math.floor(size * 0.42))
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.Position = UDim2.new(0.5, 0, 0, math.floor(size * 0.14))
	local label = UiKit.text(b, { Text = item.Label, Size = Theme.TextSize.Caption, Font = Theme.Font.BodyMedium, AlignX = Enum.TextXAlignment.Center, Color = C.TextMuted })
	label.AnchorPoint = Vector2.new(0, 1)
	label.Position = UDim2.new(0, 0, 1, -4)
	label.Size = UDim2.new(1, 0, 0, 16)
	local function refresh()
		local locked = b:GetAttribute("Locked") == true
		label.TextColor3 = if locked then C.TextFaint else C.TextMuted
		if icon:IsA("TextLabel") then
			icon.TextTransparency = if locked then 0.5 else 0
		elseif icon:IsA("ImageLabel") then
			icon.ImageTransparency = if locked then 0.5 else 0
		end
	end
	b:SetAttribute("Locked", menus[item.Menu] == nil)
	b:GetAttributeChangedSignal("Locked"):Connect(refresh)
	refresh()
	b.Activated:Connect(function()
		openMenu(item.Menu)
	end)
	dockTiles[item.Menu] = b
	return b
end

local function playButton(parent: Instance, width: number, height: number, order: number): TextButton
	local b = Instance.new("TextButton")
	b.Name = "Play"
	b.LayoutOrder = order
	b.Size = UDim2.fromOffset(width, height)
	b.BackgroundColor3 = C.Accent
	b.BorderSizePixel = 0
	b.FontFace = Theme.Font.DisplayBold
	b.TextSize = Theme.TextSize.Title
	b.TextColor3 = C.TextOnAccent
	b.Text = "PLAY"
	b.Parent = parent
	UiKit.corner(b, Theme.Radius.Medium)
	UiKit.interactive(b, C.AccentHover, C.Accent)
	b.Activated:Connect(openGateBoard)
	return b
end

local function build()
	local screen = UiKit.screen("TDHubHud", Theme.Layer.HubHud)
	screen.Enabled = visible
	gui = screen

	-- top-left: player plate + currencies
	local plate = Instance.new("Frame")
	plate.Name = "Plate"
	plate.BackgroundTransparency = 1
	plate.Position = UDim2.fromOffset(Theme.Space.L, Theme.Space.L)
	plate.Size = UDim2.fromOffset(360, 84)
	plate.Parent = screen
	UiKit.list(plate, Enum.FillDirection.Vertical, Theme.Space.S).VerticalAlignment = Enum.VerticalAlignment.Top
	local nameLabel = UiKit.text(plate, { Text = player.DisplayName, Font = Theme.Font.Display, Size = Theme.TextSize.Title, Upper = true })
	nameLabel.LayoutOrder = 1
	local chips = Instance.new("Frame")
	chips.LayoutOrder = 2
	chips.BackgroundTransparency = 1
	chips.Size = UDim2.new(1, 0, 0, Theme.Size.ChipHeight)
	chips.Parent = plate
	UiKit.list(chips, Enum.FillDirection.Horizontal, Theme.Space.S)
	local gems = UiKit.chip(chips, "Gems", C.Gems)
	local gold = UiKit.chip(chips, "Gold", C.Gold)
	local function bind(attr: string, chip: UiKit.Chip)
		local function update()
			chip.setValue(tonumber(player:GetAttribute(attr)) or 0)
		end
		player:GetAttributeChangedSignal(attr):Connect(update)
		update()
	end
	bind("Gems", gems)
	bind("Gold", gold)

	-- location strip (top centre): district name with its accent tick
	local strip = Instance.new("Frame")
	strip.Name = "Location"
	strip.AnchorPoint = Vector2.new(0.5, 0)
	strip.Position = UDim2.new(0.5, 0, 0, Theme.Space.L)
	strip.Size = UDim2.fromOffset(260, 28)
	strip.BackgroundTransparency = 1
	strip.Parent = screen
	local tick = Instance.new("Frame")
	tick.AnchorPoint = Vector2.new(0.5, 1)
	tick.Position = UDim2.fromScale(0.5, 1)
	tick.Size = UDim2.fromOffset(32, Theme.Size.AccentRule)
	tick.BorderSizePixel = 0
	tick.BackgroundColor3 = C.Accent
	tick.Parent = strip
	local where = UiKit.text(strip, { Text = "", Font = Theme.Font.Display, Size = Theme.TextSize.Label, AlignX = Enum.TextXAlignment.Center, Upper = true, Color = C.TextMuted })
	where.Size = UDim2.new(1, 0, 1, -4)

	-- dock: right edge column (Regular) or bottom bar (Compact)
	local dock = Instance.new("Frame")
	dock.Name = "Dock"
	dock.BackgroundTransparency = 1
	dock.Parent = screen

	local function layoutDock(layout: UiKit.LayoutClass)
		for _, child in dock:GetChildren() do
			if not child:IsA("UIListLayout") then
				child:Destroy()
			end
		end
		local old = dock:FindFirstChildOfClass("UIListLayout")
		if old then
			old:Destroy()
		end
		table.clear(dockTiles)
		if layout == "Compact" then
			local s = Theme.Size.DockItemCompact
			dock.AnchorPoint = Vector2.new(0.5, 1)
			dock.Position = UDim2.new(0.5, 0, 1, -Theme.Space.S)
			dock.Size = UDim2.fromOffset((#DOCK + 2) * (s + Theme.Space.XS), s)
			UiKit.list(dock, Enum.FillDirection.Horizontal, Theme.Space.XS, Enum.HorizontalAlignment.Center)
			local half = math.ceil(#DOCK / 2)
			for i, item in DOCK do
				dockTile(dock, item, s, if i <= half then i else i + 1)
			end
			playButton(dock, s * 2, s, half + 1) -- Play sits in the middle, under the thumb
		else
			local s = Theme.Size.DockItem
			dock.AnchorPoint = Vector2.new(1, 0.5)
			dock.Position = UDim2.new(1, -Theme.Space.L, 0.5, 0)
			dock.Size = UDim2.fromOffset(s, (#DOCK + 1) * (s + Theme.Space.S))
			UiKit.list(dock, Enum.FillDirection.Vertical, Theme.Space.S, Enum.HorizontalAlignment.Right)
			playButton(dock, s, s, 0)
			for i, item in DOCK do
				dockTile(dock, item, s, i)
			end
		end
	end
	UiKit.onLayoutChanged(layoutDock)

	-- district tracking: nearest zone whose platform contains the character (cheap, 4 Hz)
	local lastZone: string? = nil
	task.spawn(function()
		while screen.Parent do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local zoneId: string? = nil
			if root and root:IsA("BasePart") then
				local pos = root.Position
				local best = math.huge
				for _, z in HubConfig.Zones do
					local d = (Vector3.new(pos.X, 0, pos.Z) - (HubConfig.zoneCenter(z) * Vector3.new(1, 0, 1))).Magnitude
					if d <= z.Size + 6 and d < best then
						best = d
						zoneId = z.Id
					end
				end
			end
			if zoneId ~= lastZone then
				lastZone = zoneId
				local zone = if zoneId then HubConfig.getZone(zoneId) else nil
				where.Text = if zone then string.upper(zone.Label) else ""
				tick.BackgroundColor3 = if zoneId and C.District[zoneId] then C.District[zoneId] else C.Accent
				tick.Visible = zone ~= nil
				where.TextTransparency = 1
				UiKit.tween(where, Theme.Motion.Enter, { TextTransparency = 0 })
			end
			task.wait(0.25)
		end
	end)
end

function HubHud.init(opts: InitOptions?)
	options = opts or {}
	build()
end

-- Exposed so stations (HubClient "Play" style prompts) can open it too.
HubHud.openGateBoard = openGateBoard

return HubHud
