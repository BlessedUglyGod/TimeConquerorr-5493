--!strict
-- UnitsScreen: roster + team manager (spec: docs/ui/SCREENS.md, "Units / Team").
-- Install as ModuleScript StarterPlayer.StarterPlayerScripts.TD.Screens.UnitsScreen.
--
-- A roster wall: six team slots pinned across the top, the owned-unit grid below, and a detail drawer
-- that slides in from the right with stats and jumps to Trait Reroll / Evolution for that unit.
-- Team changes go to the server immediately (backend.setTeam); the screen redraws from its answer.
--   UnitsScreen.init(backend)
--   HubClient.registerMenu("Team", function() UnitsScreen.open() end)
--   HubHud.registerMenu("Team", UnitsScreen.open)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = ReplicatedStorage:WaitForChild("TD"):WaitForChild("UI")
local Theme = require(UI:WaitForChild("Theme"))
local UiKit = require(UI:WaitForChild("UiKit"))
local UiParts = require(UI:WaitForChild("UiParts"))

local C = Theme.Color

export type Stat = { Label: string, Value: string }
export type UnitDetail = UiParts.UnitView & {
	UnitId: string,
	Element: string?,
	Stats: { Stat }?, -- damage, range, cooldown, cost... already formatted by the adapter
	TraitName: string?,
	TraitRarity: string?,
	CanEvolve: boolean?,
}

export type Backend = {
	getUnits: () -> { UnitDetail },
	getTeam: () -> { string }, -- uids in slot order
	maxTeam: number?, -- default 6
	setTeam: (uids: { string }) -> (boolean, string?),
	getUnitModel: ((unitId: string) -> Model?)?,
	openTraits: ((uid: string) -> ())?,
	openEvolution: ((uid: string) -> ())?,
}

local UnitsScreen = {}

local backend: Backend? = nil
local win: UiKit.Window? = nil
local refresh: (() -> ())? = nil

local function build(b: Backend): UiKit.Window
	local w = UiKit.window({ Name = "TDUnits", Title = "Units", Accent = C.District.Workshop, Size = Vector2.new(880, 580) })
	local body = w.Body
	local maxTeam = b.maxTeam or 6

	local units: { UnitDetail } = {}
	local team: { string } = {}
	local selectedUid: string? = nil
	local pendingSlot: number? = nil -- slot the player tapped, waiting for a unit
	local saving = false

	local function byUid(uid: string?): UnitDetail?
		for _, u in units do
			if u.Uid == uid then
				return u
			end
		end
		return nil
	end

	-- team slots
	local slotsRow = Instance.new("Frame")
	slotsRow.BackgroundTransparency = 1
	slotsRow.Size = UDim2.new(1, 0, 0, 96)
	slotsRow.Parent = body
	UiKit.list(slotsRow, Enum.FillDirection.Horizontal, Theme.Space.S)
	local slotsLabel = UiKit.text(slotsRow, { Text = "Team", Font = Theme.Font.Display, Size = Theme.TextSize.Label, Upper = true, Color = C.TextMuted })
	slotsLabel.Size = UDim2.fromOffset(56, 96)

	-- roster grid
	local roster = Instance.new("ScrollingFrame")
	roster.BackgroundTransparency = 1
	roster.BorderSizePixel = 0
	roster.Position = UDim2.fromOffset(0, 96 + Theme.Space.M)
	roster.ScrollBarThickness = 4
	roster.ScrollBarImageColor3 = C.StrokeStrong
	roster.AutomaticCanvasSize = Enum.AutomaticSize.Y
	roster.CanvasSize = UDim2.new()
	roster.Parent = body
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(88, 96)
	grid.CellPadding = UDim2.fromOffset(Theme.Space.S, Theme.Space.S)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = roster

	-- detail drawer
	local drawer = UiKit.surface(body, "Base", Theme.Radius.Medium)
	drawer.AnchorPoint = Vector2.new(1, 0)
	drawer.Position = UDim2.new(1, 0, 0, 96 + Theme.Space.M)
	drawer.ClipsDescendants = true
	local previewHolder = Instance.new("Frame")
	previewHolder.BackgroundTransparency = 1
	previewHolder.Size = UDim2.new(1, 0, 0, 150)
	previewHolder.Parent = drawer
	local preview = UiParts.preview(previewHolder)
	local info = Instance.new("Frame")
	info.BackgroundTransparency = 1
	info.Position = UDim2.fromOffset(Theme.Space.M, 150)
	info.Size = UDim2.new(1, -Theme.Space.M * 2, 1, -150 - Theme.Space.M)
	info.Parent = drawer
	UiKit.list(info, Enum.FillDirection.Vertical, Theme.Space.XS).VerticalAlignment = Enum.VerticalAlignment.Top
	local dName = UiKit.text(info, { Text = "", Font = Theme.Font.DisplayBold, Size = Theme.TextSize.Title, Upper = true })
	dName.LayoutOrder = 1
	local dMeta = UiKit.text(info, { Text = "", Size = Theme.TextSize.Caption, Font = Theme.Font.BodyBold })
	dMeta.LayoutOrder = 2
	local statsBox = Instance.new("Frame")
	statsBox.LayoutOrder = 3
	statsBox.BackgroundTransparency = 1
	statsBox.AutomaticSize = Enum.AutomaticSize.Y
	statsBox.Size = UDim2.new(1, 0, 0, 0)
	statsBox.Parent = info
	UiKit.list(statsBox, Enum.FillDirection.Vertical, 2)
	local dTrait = UiKit.text(info, { Text = "", Size = Theme.TextSize.Caption, Font = Theme.Font.BodyBold })
	dTrait.LayoutOrder = 4
	local actions = Instance.new("Frame")
	actions.LayoutOrder = 5
	actions.BackgroundTransparency = 1
	actions.AutomaticSize = Enum.AutomaticSize.Y
	actions.Size = UDim2.new(1, 0, 0, 0)
	actions.Parent = info
	UiKit.list(actions, Enum.FillDirection.Vertical, Theme.Space.XS)

	local equipBtn: UiKit.Button
	local traitBtn: UiKit.Button
	local evoBtn: UiKit.Button

	local function save(newTeam: { string })
		if saving then
			return
		end
		saving = true
		local ok, err = b.setTeam(newTeam)
		saving = false
		if not ok then
			UiKit.toast(err or "Could not change the team", "Error")
		end
		pendingSlot = nil
		if refresh then
			refresh()
		end
	end

	local function placeInSlot(uid: string, slot: number)
		local newTeam = table.clone(team)
		local existing = table.find(newTeam, uid)
		if existing then
			table.remove(newTeam, existing)
			if existing < slot then
				slot -= 1
			end
		end
		slot = math.clamp(slot, 1, #newTeam + 1)
		if newTeam[slot] then
			newTeam[slot] = uid -- replace what was there
		else
			table.insert(newTeam, uid)
		end
		while #newTeam > maxTeam do
			table.remove(newTeam)
		end
		task.spawn(save, newTeam)
	end

	equipBtn = UiKit.button(actions, { Text = "Equip", Variant = "Primary", OnActivated = function()
		local uid = selectedUid
		if not uid then
			return
		end
		local idx = table.find(team, uid)
		if idx then
			local newTeam = table.clone(team)
			table.remove(newTeam, idx)
			task.spawn(save, newTeam)
		else
			placeInSlot(uid, pendingSlot or (#team + 1))
		end
	end })
	equipBtn.Instance.LayoutOrder = 1
	traitBtn = UiKit.button(actions, { Text = "Traits", Variant = "Secondary", OnActivated = function()
		if selectedUid and b.openTraits then
			b.openTraits(selectedUid)
		end
	end })
	traitBtn.Instance.LayoutOrder = 2
	evoBtn = UiKit.button(actions, { Text = "Evolve", Variant = "Secondary", OnActivated = function()
		if selectedUid and b.openEvolution then
			b.openEvolution(selectedUid)
		end
	end })
	evoBtn.Instance.LayoutOrder = 3

	local function showDetail()
		local u = byUid(selectedUid)
		drawer.Visible = u ~= nil
		if not u then
			return
		end
		local color = UiParts.rarityColor(u.Rarity)
		preview.show(if b.getUnitModel then b.getUnitModel(u.UnitId) else nil, u.Name, u.Rarity)
		dName.Text = string.upper(u.Name)
		dName.TextColor3 = color
		local meta = { u.Rarity }
		if u.Level then
			table.insert(meta, "Lv. " .. u.Level)
		end
		if u.Element then
			table.insert(meta, u.Element)
		end
		dMeta.Text = table.concat(meta, "  ·  ")
		dMeta.TextColor3 = color
		for _, child in statsBox:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		for i, stat in u.Stats or {} do
			local row = Instance.new("Frame")
			row.LayoutOrder = i
			row.BackgroundTransparency = 1
			row.Size = UDim2.new(1, 0, 0, 20)
			row.Parent = statsBox
			local l = UiKit.text(row, { Text = stat.Label, Size = Theme.TextSize.Caption, Color = C.TextMuted })
			l.Size = UDim2.fromScale(0.6, 1)
			local v = UiKit.text(row, { Text = stat.Value, Size = Theme.TextSize.Caption, Font = Theme.Font.BodyBold, AlignX = Enum.TextXAlignment.Right })
			v.Position = UDim2.fromScale(0.6, 0)
			v.Size = UDim2.fromScale(0.4, 1)
		end
		dTrait.Text = if u.TraitName then "Trait: " .. u.TraitName else "No trait yet"
		dTrait.TextColor3 = if u.TraitRarity then UiParts.rarityColor(u.TraitRarity) else C.TextFaint
		local inTeam = table.find(team, u.Uid) ~= nil
		equipBtn.setText(if inTeam then "Unequip" else if pendingSlot then "Equip to slot " .. pendingSlot else "Equip")
		equipBtn.setEnabled(inTeam or #team < maxTeam or pendingSlot ~= nil, "Team is full: tap a slot to replace it")
		traitBtn.setEnabled(b.openTraits ~= nil, "Trait Reroll is not open yet")
		evoBtn.setEnabled(b.openEvolution ~= nil and u.CanEvolve == true, if b.openEvolution then "This unit cannot evolve yet" else "Evolution is not open yet")
	end

	local function renderSlots()
		for _, child in slotsRow:GetChildren() do
			if child:IsA("GuiButton") or (child:IsA("Frame") and child.Name == "Slot") then
				child:Destroy()
			end
		end
		for i = 1, maxTeam do
			local u = byUid(team[i])
			local holder: GuiButton
			if u then
				holder = UiParts.unitCard(slotsRow, u, Vector2.new(88, 96))
			else
				local empty = Instance.new("TextButton")
				empty.Text = "+"
				empty.FontFace = Theme.Font.DisplayBold
				empty.TextSize = Theme.TextSize.Headline
				empty.TextColor3 = C.TextFaint
				empty.Size = UDim2.fromOffset(88, 96)
				empty.BackgroundColor3 = C.Base
				empty.BackgroundTransparency = 0.5
				empty.BorderSizePixel = 0
				empty.Parent = slotsRow
				UiKit.corner(empty, Theme.Radius.Medium)
				UiKit.stroke(empty, C.Stroke)
				UiKit.interactive(empty)
				holder = empty
			end
			holder.Name = "Slot" .. i
			holder.LayoutOrder = i
			if pendingSlot == i then
				UiParts.setSelected(holder, true)
			end
			holder.Activated:Connect(function()
				if pendingSlot == i then
					pendingSlot = nil -- second tap cancels
				else
					pendingSlot = i
					if u then
						selectedUid = u.Uid
					elseif selectedUid and not table.find(team, selectedUid) then
						placeInSlot(selectedUid, i) -- unit chosen first, then slot
						return
					end
				end
				if refresh then
					refresh()
				end
			end)
		end
	end

	local function renderRoster()
		for _, child in roster:GetChildren() do
			if child:IsA("GuiButton") then
				child:Destroy()
			end
		end
		for i, u in units do
			local card = UiParts.unitCard(roster, u, Vector2.new(88, 96))
			card.LayoutOrder = i
			if table.find(team, u.Uid) then
				local tag = UiKit.text(card, { Text = "IN TEAM", Size = 10, Font = Theme.Font.DisplayBold, Color = C.Positive, AlignX = Enum.TextXAlignment.Right })
				tag.AnchorPoint = Vector2.new(1, 0)
				tag.Position = UDim2.new(1, -Theme.Space.XS, 0, Theme.Space.XS)
				tag.Size = UDim2.fromOffset(60, 12)
			end
			if u.Uid == selectedUid then
				UiParts.setSelected(card, true)
			end
			card.Activated:Connect(function()
				if pendingSlot and not table.find(team, u.Uid) then
					placeInSlot(u.Uid, pendingSlot) -- slot chosen first, then unit
					return
				end
				selectedUid = u.Uid
				if refresh then
					refresh()
				end
			end)
		end
	end

	UiKit.onLayoutChanged(function(layout)
		local compact = layout == "Compact"
		roster.Size = if compact then UDim2.new(1, 0, 0.5, -96) else UDim2.new(0.62, 0, 1, -96 - Theme.Space.M)
		drawer.Size = if compact then UDim2.new(1, 0, 0.5, -Theme.Space.M) else UDim2.new(0.36, 0, 1, -96 - Theme.Space.M)
		drawer.AnchorPoint = if compact then Vector2.new(0, 1) else Vector2.new(1, 0)
		drawer.Position = if compact then UDim2.fromScale(0, 1) else UDim2.new(1, 0, 0, 96 + Theme.Space.M)
		slotsLabel.Visible = not compact
		grid.CellSize = if compact then UDim2.fromOffset(72, 80) else UDim2.fromOffset(88, 96)
	end)

	refresh = function()
		units = b.getUnits()
		team = b.getTeam()
		if selectedUid and not byUid(selectedUid) then
			selectedUid = nil
		end
		if not selectedUid then
			selectedUid = team[1] or (units[1] and units[1].Uid)
		end
		renderSlots()
		renderRoster()
		showDetail()
	end
	return w
end

function UnitsScreen.init(b: Backend)
	backend = b
end

function UnitsScreen.open()
	local b = backend
	if not b then
		UiKit.toast("Units are not connected yet", "Warning")
		return
	end
	if not win then
		win = build(b)
	end
	if refresh then
		refresh()
	end
	;(win :: UiKit.Window).open()
end

return UnitsScreen
