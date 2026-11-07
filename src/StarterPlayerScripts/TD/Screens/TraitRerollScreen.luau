--!strict
-- TraitRerollScreen: the Trait Well's own interface (spec: docs/ui/SCREENS.md, "Trait Reroll").
-- Install as ModuleScript StarterPlayer.StarterPlayerScripts.TD.Screens.TraitRerollScreen.
--
-- The screen never rolls: it calls backend.reroll and shows the server's answer. The backend adapter is
-- written once in TDClient against the live remotes (see docs/ui/INTEGRATION.md, "Screens"):
--   TraitRerollScreen.init(backend)
--   HubClient.registerMenu("Traits", function(stationId) TraitRerollScreen.open() end)
--   HubHud.registerMenu("Traits", TraitRerollScreen.open)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = ReplicatedStorage:WaitForChild("TD"):WaitForChild("UI")
local Theme = require(UI:WaitForChild("Theme"))
local UiKit = require(UI:WaitForChild("UiKit"))
local UiParts = require(UI:WaitForChild("UiParts"))

local C = Theme.Color

export type TraitView = { Id: string, Name: string, Rarity: string, Effects: { string } }
export type UnitWithTrait = UiParts.UnitView & { Trait: TraitView? }
export type RerollResult = { Trait: TraitView, Rolls: number? } -- Rolls: how many rolls an x10 used

export type Backend = {
	getUnits: () -> { UnitWithTrait }, -- owned units (from GetProfile)
	getOdds: () -> { UiParts.OddsRow }, -- server's trait rarity table
	getBalance: () -> number, -- reroll currency owned
	onBalanceChanged: ((callback: () -> ()) -> ())?,
	costs: { Single: number, Ten: number, Lock: number? }, -- Lock = nil => locking not supported
	tenRule: string?, -- caption under x10, e.g. "Stops early on Legendary or better"
	reroll: (uid: string, count: number, lock: boolean) -> (boolean, RerollResult | string),
	getUnitModel: ((uid: string) -> Model?)?,
	currencyIcon: string?, -- Icons id, default "TraitShard"
}

local HIGH_RARITY = { Legendary = true, Mythic = true, Exclusive = true }
local SPIN_ORDER = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Exclusive" }

local TraitRerollScreen = {}

local backend: Backend? = nil
local win: UiKit.Window? = nil
local refresh: ((preselect: string?) -> ())? = nil

local function traitCard(parent: Instance, caption: string, order: number)
	local card = UiKit.surface(parent, "Raised", Theme.Radius.Medium)
	card.LayoutOrder = order
	card.Size = UDim2.new(1, 0, 0, 96)
	local cap = UiKit.text(card, { Text = caption, Size = Theme.TextSize.Caption, Font = Theme.Font.Display, Upper = true, Color = C.TextMuted })
	cap.Position = UDim2.fromOffset(Theme.Space.L, Theme.Space.S)
	cap.Size = UDim2.new(1, -Theme.Space.L * 2, 0, 16)
	local name = UiKit.text(card, { Text = "", Font = Theme.Font.DisplayBold, Size = Theme.TextSize.Headline })
	name.Position = UDim2.fromOffset(Theme.Space.L, 26)
	name.Size = UDim2.new(1, -Theme.Space.L * 2, 0, 34)
	local effects = UiKit.text(card, { Text = "", Size = Theme.TextSize.Body, Color = C.TextMuted })
	effects.Position = UDim2.fromOffset(Theme.Space.L, 62)
	effects.Size = UDim2.new(1, -Theme.Space.L * 2, 0, 26)
	effects.TextWrapped = true
	local stroke = card:FindFirstChildOfClass("UIStroke") :: UIStroke
	local function show(trait: TraitView?, emptyName: string, emptyText: string)
		if trait then
			local color = UiParts.rarityColor(trait.Rarity)
			name.Text = trait.Name
			name.TextColor3 = color
			effects.Text = table.concat(trait.Effects, ",  ")
			stroke.Color = color
		else
			name.Text = emptyName
			name.TextColor3 = C.TextMuted
			effects.Text = emptyText
			stroke.Color = C.Stroke
		end
	end
	return card, name, stroke, show
end

local function build(b: Backend): UiKit.Window
	local w = UiKit.window({ Name = "TDTraitReroll", Title = "Trait Reroll", Accent = C.TraitShard, Size = Vector2.new(880, 580) })
	local body = w.Body
	local currency = b.currencyIcon or "TraitShard"

	-- three columns over a bottom unit strip
	local top = Instance.new("Frame")
	top.BackgroundTransparency = 1
	top.Size = UDim2.new(1, 0, 1, -104 - Theme.Space.M)
	top.Parent = body

	local unitCol = Instance.new("Frame")
	unitCol.BackgroundTransparency = 1
	unitCol.Parent = top
	local preview = UiParts.preview(unitCol)
	preview.Instance.Size = UDim2.new(1, 0, 1, -56)
	local unitName = UiKit.text(unitCol, { Text = "", Font = Theme.Font.DisplayBold, Size = Theme.TextSize.Title })
	unitName.AnchorPoint = Vector2.new(0, 1)
	unitName.Position = UDim2.new(0, 0, 1, -22)
	local unitMeta = UiKit.text(unitCol, { Text = "", Size = Theme.TextSize.Caption, Font = Theme.Font.BodyBold })
	unitMeta.AnchorPoint = Vector2.new(0, 1)
	unitMeta.Position = UDim2.fromScale(0, 1)

	local mid = Instance.new("Frame")
	mid.BackgroundTransparency = 1
	mid.Parent = top
	UiKit.list(mid, Enum.FillDirection.Vertical, Theme.Space.S, Enum.HorizontalAlignment.Center).VerticalAlignment = Enum.VerticalAlignment.Top
	local _, _, _, showCurrent = traitCard(mid, "Current trait", 1)
	local arrow = UiKit.text(mid, { Text = "v  v", Font = Theme.Font.DisplayBold, Size = Theme.TextSize.Title, Color = C.Accent, AlignX = Enum.TextXAlignment.Center })
	arrow.LayoutOrder = 2
	local newCard, newName, newStroke, showNew = traitCard(mid, "New trait", 3)

	-- forward declarations (used by handlers created below)
	local selectedUnitById: (uid: string) -> UnitWithTrait?
	local updateButtons: () -> ()

	-- lock row
	local lockOn = false
	if b.costs.Lock then
		local row = Instance.new("TextButton")
		row.LayoutOrder = 4
		row.Text = ""
		row.Size = UDim2.new(1, 0, 0, Theme.TouchTarget)
		row.BackgroundColor3 = C.Raised
		row.BackgroundTransparency = Theme.Transparency.Card
		row.BorderSizePixel = 0
		row.Parent = mid
		UiKit.corner(row, Theme.Radius.Medium)
		UiKit.stroke(row)
		UiKit.interactive(row)
		local box = Instance.new("Frame")
		box.AnchorPoint = Vector2.new(0, 0.5)
		box.Position = UDim2.new(0, Theme.Space.M, 0.5, 0)
		box.Size = UDim2.fromOffset(18, 18)
		box.BackgroundColor3 = C.Base
		box.BorderSizePixel = 0
		box.Parent = row
		UiKit.corner(box, Theme.Radius.Small)
		UiKit.stroke(box, C.StrokeStrong)
		local lbl = UiKit.text(row, { Text = "Lock current trait", Font = Theme.Font.BodyMedium })
		lbl.Position = UDim2.fromOffset(Theme.Space.M + 28, 0)
		lbl.Size = UDim2.new(1, -140, 1, 0)
		local tag = UiParts.costTag(row, currency, C.TraitShard)
		tag.Instance.AnchorPoint = Vector2.new(1, 0.5)
		tag.Instance.Position = UDim2.new(1, -Theme.Space.M, 0.5, 0)
		tag.set(b.costs.Lock, true)
		row.Activated:Connect(function()
			lockOn = not lockOn
			box.BackgroundColor3 = if lockOn then C.Accent else C.Base
			updateButtons()
		end)
	end

	local actions = Instance.new("Frame")
	actions.LayoutOrder = 5
	actions.BackgroundTransparency = 1
	actions.Size = UDim2.new(1, 0, 0, Theme.Size.ButtonHeight + 20)
	actions.Parent = mid
	UiKit.list(actions, Enum.FillDirection.Horizontal, Theme.Space.M, Enum.HorizontalAlignment.Center).VerticalAlignment = Enum.VerticalAlignment.Top

	local oddsCol = Instance.new("Frame")
	oddsCol.BackgroundTransparency = 1
	oddsCol.Parent = top
	local oddsTitle = UiKit.text(oddsCol, { Text = "Trait odds", Font = Theme.Font.Display, Size = Theme.TextSize.Label, Upper = true, Color = C.TextMuted })
	oddsTitle.Size = UDim2.new(1, 0, 0, 24)
	local oddsHolder = Instance.new("Frame")
	oddsHolder.BackgroundTransparency = 1
	oddsHolder.Position = UDim2.fromOffset(0, 28)
	oddsHolder.Size = UDim2.new(1, 0, 1, -28)
	oddsHolder.Parent = oddsCol
	local odds = UiParts.rarityTable(oddsHolder)

	-- state
	local units: { UnitWithTrait } = {}
	local selectedUid: string? = nil
	local busy = false
	local ten: UiKit.Button
	local one: UiKit.Button

	local function selectedUnit(): UnitWithTrait?
		for _, u in units do
			if u.Uid == selectedUid then
				return u
			end
		end
		return nil
	end

	selectedUnitById = function(uid: string): UnitWithTrait?
		for _, u in units do
			if u.Uid == uid then
				return u
			end
		end
		return nil
	end

	updateButtons = function()
		local balance = b.getBalance()
		local lockCost = if lockOn then (b.costs.Lock or 0) else 0
		for _, spec in { { one, b.costs.Single }, { ten, b.costs.Ten } } do
			local btn, cost = spec[1] :: UiKit.Button, (spec[2] :: number) + lockCost
			if busy then
				btn.setEnabled(false, nil)
			elseif not selectedUid then
				btn.setEnabled(false, "Select a unit first")
			elseif balance < cost then
				btn.setEnabled(false, string.format("Need %d more", cost - balance))
			else
				btn.setEnabled(true)
			end
		end
	end

	local function rerollButton(label: string, count: number, cost: number, emphasis: boolean, onActivated: () -> ()): UiKit.Button
		local holder = Instance.new("Frame")
		holder.BackgroundTransparency = 1
		holder.Size = UDim2.fromOffset(196, Theme.Size.ButtonHeight + 20)
		holder.LayoutOrder = count
		holder.Parent = actions
		local btn = UiKit.button(holder, { Text = label, Variant = "Primary", OnActivated = onActivated })
		if emphasis then
			local s = btn.Instance:FindFirstChildOfClass("UIStroke")
			if s then
				s.Color = C.Emphasis
				s.Thickness = Theme.Stroke.Focus
			end
		end
		local tag = UiParts.costTag(holder, currency, C.TraitShard)
		tag.Instance.AnchorPoint = Vector2.new(0.5, 0)
		tag.Instance.Position = UDim2.new(0.5, 0, 0, Theme.Size.ButtonHeight - 4)
		tag.set(cost, true)
		return btn
	end

	local function setUnits(list: { UnitWithTrait }, strip: UiParts.UnitStrip)
		units = list
		strip.set(list)
	end

	local strip: UiParts.UnitStrip
	local function select(uid: string)
		selectedUid = uid
		strip.select(uid)
		local u = selectedUnit()
		if not u then
			return
		end
		local model = if b.getUnitModel then b.getUnitModel(uid) else nil
		preview.show(model, u.Name, u.Rarity)
		if u.Trait then
			preview.setAura(UiParts.rarityColor(u.Trait.Rarity))
		end
		unitName.Text = string.upper(u.Name)
		unitMeta.Text = string.format("%s%s", u.Rarity, if u.Level then "  ·  Lv. " .. u.Level else "")
		unitMeta.TextColor3 = UiParts.rarityColor(u.Rarity)
		showCurrent(u.Trait, "No trait", "Reroll to get a trait")
		showNew(nil, "?", "Reroll to get a new trait")
		updateButtons()
	end

	-- spin animation on the new-trait card, then land on the server's result
	local function play(result: RerollResult)
		for i = 1, 10 do
			local r = SPIN_ORDER[(i % #SPIN_ORDER) + 1]
			newName.Text = "?"
			newStroke.Color = UiParts.rarityColor(r)
			newCard.BackgroundColor3 = UiParts.rarityColor(r)
			newCard.BackgroundTransparency = 0.85
			task.wait(0.03 + i * 0.006) -- slows down
		end
		newCard.BackgroundColor3 = C.Raised
		newCard.BackgroundTransparency = Theme.Transparency.Card
		showNew(result.Trait, "", "")
		local s = Instance.new("UIScale")
		s.Scale = 0.92
		s.Parent = newCard
		UiKit.tween(s, Theme.Motion.Emphasis, { Scale = 1 }).Completed:Once(function()
			s:Destroy()
		end)
		odds.highlight(result.Trait.Rarity)
		preview.setAura(UiParts.rarityColor(result.Trait.Rarity))
		if HIGH_RARITY[result.Trait.Rarity] then
			-- rare reveal: dim the window, big name, short hold
			local veil = Instance.new("Frame")
			veil.BackgroundColor3 = C.Scrim
			veil.BackgroundTransparency = 1
			veil.BorderSizePixel = 0
			veil.Size = UDim2.fromScale(1, 1)
			veil.ZIndex = 10
			veil.Parent = w.Root
			local big = UiKit.text(veil, { Text = result.Trait.Name, Font = Theme.Font.DisplayBold, Size = Theme.TextSize.Hero, Upper = true,
				Color = UiParts.rarityColor(result.Trait.Rarity), AlignX = Enum.TextXAlignment.Center })
			big.AnchorPoint = Vector2.new(0.5, 0.5)
			big.Position = UDim2.fromScale(0.5, 0.45)
			big.ZIndex = 11
			big.TextTransparency = 1
			local rarity = UiKit.text(veil, { Text = result.Trait.Rarity, Font = Theme.Font.Display, Size = Theme.TextSize.Title, Upper = true, Color = C.Text, AlignX = Enum.TextXAlignment.Center })
			rarity.AnchorPoint = Vector2.new(0.5, 0)
			rarity.Position = UDim2.fromScale(0.5, 0.53)
			rarity.ZIndex = 11
			rarity.TextTransparency = 1
			UiKit.tween(veil, Theme.Motion.Enter, { BackgroundTransparency = 0.3 })
			UiKit.tween(big, Theme.Motion.Emphasis, { TextTransparency = 0 })
			UiKit.tween(rarity, Theme.Motion.Enter, { TextTransparency = 0 })
			task.wait(1.2)
			UiKit.tween(veil, Theme.Motion.Exit, { BackgroundTransparency = 1 })
			UiKit.tween(big, Theme.Motion.Exit, { TextTransparency = 1 })
			UiKit.tween(rarity, Theme.Motion.Exit, { TextTransparency = 1 }).Completed:Wait()
			veil:Destroy()
		end
	end

	local function doReroll(count: number)
		local u = selectedUnit()
		if busy or not u then
			return
		end
		busy = true
		updateButtons()
		local ok, res = b.reroll(u.Uid, count, lockOn)
		if ok and typeof(res) == "table" then
			local result = res :: RerollResult
			play(result)
			u.Trait = result.Trait
			showCurrent(result.Trait, "", "")
			if count > 1 and result.Rolls then
				UiKit.toast(string.format("Used %d of %d rolls", result.Rolls, count), "Info")
			end
		else
			UiKit.toast(if typeof(res) == "string" then res else "Reroll failed", "Error")
		end
		busy = false
		updateButtons()
	end

	one = rerollButton("Reroll x1", 1, b.costs.Single, false, function()
		task.spawn(doReroll, 1)
	end)
	ten = rerollButton("Reroll x10", 10, b.costs.Ten, true, function()
		task.spawn(doReroll, 10)
	end)
	if b.tenRule then
		local rule = UiKit.text(mid, { Text = b.tenRule, Size = Theme.TextSize.Caption, Color = C.TextFaint, AlignX = Enum.TextXAlignment.Center })
		rule.LayoutOrder = 6
	end

	strip = UiParts.unitStrip(body, select)
	strip.Instance.AnchorPoint = Vector2.new(0, 1)
	strip.Instance.Position = UDim2.fromScale(0, 1)

	-- responsive: three columns (Regular) / preview header + stacked (Compact, odds hidden behind toast)
	UiKit.onLayoutChanged(function(layout)
		if layout == "Compact" then
			unitCol.Size = UDim2.new(0.34, -Theme.Space.S, 1, 0)
			unitCol.Position = UDim2.fromScale(0, 0)
			mid.Size = UDim2.new(0.66, 0, 1, 0)
			mid.Position = UDim2.new(0.34, Theme.Space.S, 0, 0)
			oddsCol.Visible = false
		else
			unitCol.Size = UDim2.new(0.3, -Theme.Space.M, 1, 0)
			unitCol.Position = UDim2.fromScale(0, 0)
			mid.Size = UDim2.new(0.42, -Theme.Space.M, 1, 0)
			mid.Position = UDim2.new(0.3, 0, 0, 0)
			oddsCol.Size = UDim2.new(0.28, -Theme.Space.M, 1, 0)
			oddsCol.Position = UDim2.new(0.72, Theme.Space.M, 0, 0)
			oddsCol.Visible = true
		end
	end)

	refresh = function(preselect: string?)
		setUnits(b.getUnits(), strip)
		odds.set(b.getOdds())
		local want = preselect or selectedUid
		if want and selectedUnitById(want) then
			select(want)
		elseif units[1] then
			select(units[1].Uid)
		end
		updateButtons()
	end
	if b.onBalanceChanged then
		b.onBalanceChanged(updateButtons)
	end
	return w
end

function TraitRerollScreen.init(b: Backend)
	backend = b
end

-- uid: optional unit to preselect (e.g. from the Units detail drawer)
function TraitRerollScreen.open(uid: string?)
	local b = backend
	if not b then
		UiKit.toast("Trait Reroll is not connected yet", "Warning")
		return
	end
	if not win then
		win = build(b)
	end
	if refresh then
		refresh(uid)
	end
	;(win :: UiKit.Window).open()
end

return TraitRerollScreen
