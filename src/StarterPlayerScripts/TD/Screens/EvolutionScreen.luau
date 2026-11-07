--!strict
-- EvolutionScreen: the Upgrade Forge's evolution interface (spec: docs/ui/SCREENS.md, "Evolution").
-- Install as ModuleScript StarterPlayer.StarterPlayerScripts.TD.Screens.EvolutionScreen.
--
-- Before -> after: two previews facing each other with a bar of light between them, stat deltas in the
-- middle, path tabs when a unit can evolve more than one way, then the requirements (materials with
-- owned/needed and where to get them, quest steps with progress). Evolve plays a transformation.
-- The server decides everything: getPlan is a snapshot, evolve is an intent.
--   EvolutionScreen.init(backend)
--   HubClient.registerMenu("Evolution", function() EvolutionScreen.open() end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = ReplicatedStorage:WaitForChild("TD"):WaitForChild("UI")
local Theme = require(UI:WaitForChild("Theme"))
local UiKit = require(UI:WaitForChild("UiKit"))
local UiParts = require(UI:WaitForChild("UiParts"))

local C = Theme.Color

export type StatDelta = { Label: string, Before: string, After: string, Better: boolean? }
export type Material = { Id: string, Name: string, Icon: string?, Have: number, Need: number, Source: string? }
export type Step = { Text: string, Progress: number, Goal: number }
export type Path = {
	Id: string,
	Label: string,
	Into: { UnitId: string, Name: string, Rarity: string },
	Stats: { StatDelta },
	Materials: { Material },
	Steps: { Step }?,
}
export type Plan = { Unit: UiParts.UnitView & { UnitId: string }, Paths: { Path } }

export type Backend = {
	getCandidates: () -> { UiParts.UnitView }, -- owned units that have an evolution
	getPlan: (uid: string) -> Plan?,
	evolve: (uid: string, pathId: string) -> (boolean, string?),
	getUnitModel: ((unitId: string) -> Model?)?,
}

local EvolutionScreen = {}

local backend: Backend? = nil
local win: UiKit.Window? = nil
local refresh: ((preselect: string?) -> ())? = nil

local function build(b: Backend): UiKit.Window
	local w = UiKit.window({ Name = "TDEvolution", Title = "Evolution", Accent = C.Emphasis, Size = Vector2.new(880, 580) })
	local body = w.Body

	local selectedUid: string? = nil
	local plan: Plan? = nil
	local pathIndex = 1
	local busy = false

	-- comparison stage
	local stage = Instance.new("Frame")
	stage.BackgroundTransparency = 1
	stage.Size = UDim2.new(1, 0, 0.5, 0)
	stage.Parent = body
	local beforeHolder = Instance.new("Frame")
	beforeHolder.BackgroundTransparency = 1
	beforeHolder.Size = UDim2.fromScale(0.3, 1)
	beforeHolder.Parent = stage
	local before = UiParts.preview(beforeHolder)
	local afterHolder = Instance.new("Frame")
	afterHolder.BackgroundTransparency = 1
	afterHolder.AnchorPoint = Vector2.new(1, 0)
	afterHolder.Position = UDim2.fromScale(1, 0)
	afterHolder.Size = UDim2.fromScale(0.3, 1)
	afterHolder.Parent = stage
	local after = UiParts.preview(afterHolder)
	local beforeName = UiKit.text(beforeHolder, { Text = "", Font = Theme.Font.DisplayBold, Size = Theme.TextSize.Label, Upper = true, AlignX = Enum.TextXAlignment.Center })
	beforeName.AnchorPoint = Vector2.new(0, 1)
	beforeName.Position = UDim2.fromScale(0, 1)
	local afterName = UiKit.text(afterHolder, { Text = "", Font = Theme.Font.DisplayBold, Size = Theme.TextSize.Label, Upper = true, AlignX = Enum.TextXAlignment.Center })
	afterName.AnchorPoint = Vector2.new(0, 1)
	afterName.Position = UDim2.fromScale(0, 1)

	-- bar of light between the two (the screen's signature) + stat deltas over it
	local beam = Instance.new("Frame")
	beam.BorderSizePixel = 0
	beam.BackgroundColor3 = C.Emphasis
	beam.BackgroundTransparency = 0.5
	beam.AnchorPoint = Vector2.new(0.5, 0.5)
	beam.Position = UDim2.fromScale(0.5, 0.5)
	beam.Size = UDim2.new(0.4, 0, 0, 2)
	beam.Parent = stage
	local deltas = Instance.new("Frame")
	deltas.BackgroundTransparency = 1
	deltas.AnchorPoint = Vector2.new(0.5, 0.5)
	deltas.Position = UDim2.fromScale(0.5, 0.5)
	deltas.Size = UDim2.new(0.38, 0, 1, -Theme.Space.L)
	deltas.Parent = stage
	UiKit.list(deltas, Enum.FillDirection.Vertical, 2, Enum.HorizontalAlignment.Center)

	-- path tabs
	local pathTabs = Instance.new("Frame")
	pathTabs.BackgroundTransparency = 1
	pathTabs.Position = UDim2.new(0, 0, 0.5, Theme.Space.S)
	pathTabs.Size = UDim2.new(1, 0, 0, 32)
	pathTabs.Parent = body
	UiKit.list(pathTabs, Enum.FillDirection.Horizontal, Theme.Space.XS, Enum.HorizontalAlignment.Center)

	-- requirements: materials (left) + steps (right), evolve button bottom right
	local req = Instance.new("Frame")
	req.BackgroundTransparency = 1
	req.Position = UDim2.new(0, 0, 0.5, 48)
	req.Size = UDim2.new(1, 0, 0.5, -48 - 104 - Theme.Space.M)
	req.Parent = body
	local mats = Instance.new("Frame")
	mats.BackgroundTransparency = 1
	mats.Size = UDim2.fromScale(0.55, 1)
	mats.Parent = req
	UiKit.list(mats, Enum.FillDirection.Horizontal, Theme.Space.S).VerticalAlignment = Enum.VerticalAlignment.Top
	local steps = Instance.new("Frame")
	steps.BackgroundTransparency = 1
	steps.Position = UDim2.new(0.55, Theme.Space.M, 0, 0)
	steps.Size = UDim2.new(0.45, -Theme.Space.M - 200, 1, 0)
	steps.Parent = req
	UiKit.list(steps, Enum.FillDirection.Vertical, Theme.Space.XS).VerticalAlignment = Enum.VerticalAlignment.Top
	local evolveHolder = Instance.new("Frame")
	evolveHolder.BackgroundTransparency = 1
	evolveHolder.AnchorPoint = Vector2.new(1, 0)
	evolveHolder.Position = UDim2.fromScale(1, 0)
	evolveHolder.Size = UDim2.fromOffset(190, 56)
	evolveHolder.Parent = req
	local evolveBtn: UiKit.Button
	local doEvolve: () -> ()
	evolveBtn = UiKit.button(evolveHolder, { Text = "Evolve", Variant = "Primary", OnActivated = function()
		task.spawn(doEvolve)
	end })
	evolveBtn.Instance.Size = UDim2.new(1, 0, 0, 52)
	evolveBtn.Instance.BackgroundColor3 = C.Emphasis

	local strip: UiParts.UnitStrip

	local function clear(f: Frame)
		for _, child in f:GetChildren() do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
	end

	local function renderPath()
		local p = plan
		clear(deltas)
		clear(mats)
		clear(steps)
		if not p or not p.Paths[pathIndex] then
			after.show(nil, "No evolution", nil)
			afterName.Text = ""
			evolveBtn.setEnabled(false, "This unit has no evolution")
			return
		end
		local path = p.Paths[pathIndex]
		local intoColor = UiParts.rarityColor(path.Into.Rarity)
		after.show(if b.getUnitModel then b.getUnitModel(path.Into.UnitId) else nil, path.Into.Name, path.Into.Rarity)
		afterName.Text = string.upper(path.Into.Name)
		afterName.TextColor3 = intoColor
		beam.BackgroundColor3 = intoColor
		for i, s in path.Stats do
			local row = Instance.new("Frame")
			row.LayoutOrder = i
			row.BackgroundTransparency = 1
			row.Size = UDim2.new(1, 0, 0, 22)
			row.Parent = deltas
			local l = UiKit.text(row, { Text = s.Label, Size = Theme.TextSize.Caption, Color = C.TextMuted })
			l.Size = UDim2.fromScale(0.4, 1)
			local v = UiKit.text(row, { Text = s.Before .. "  >  " .. s.After, Size = Theme.TextSize.Caption, Font = Theme.Font.BodyBold,
				Color = if s.Better == true then C.Positive elseif s.Better == false then C.Danger else C.Text, AlignX = Enum.TextXAlignment.Right })
			v.Position = UDim2.fromScale(0.4, 0)
			v.Size = UDim2.fromScale(0.6, 1)
		end
		local missing: string? = nil
		for i, m in path.Materials do
			local enough = m.Have >= m.Need
			if not enough and not missing then
				missing = string.format("Need %d more %s", m.Need - m.Have, m.Name)
			end
			local slot = Instance.new("TextButton")
			slot.LayoutOrder = i
			slot.Text = ""
			slot.Size = UDim2.fromOffset(84, 96)
			slot.BackgroundColor3 = C.Raised
			slot.BackgroundTransparency = Theme.Transparency.Card
			slot.BorderSizePixel = 0
			slot.Parent = mats
			UiKit.corner(slot, Theme.Radius.Medium)
			UiKit.stroke(slot, if enough then C.Positive else C.Stroke)
			UiKit.interactive(slot)
			local icon = UiKit.icon(slot, m.Icon or m.Id, 36)
			icon.AnchorPoint = Vector2.new(0.5, 0)
			icon.Position = UDim2.new(0.5, 0, 0, Theme.Space.S)
			local count = UiKit.text(slot, { Text = string.format("%d/%d", m.Have, m.Need), Font = Theme.Font.BodyBold, Size = Theme.TextSize.Body,
				Color = if enough then C.Positive else C.Danger, AlignX = Enum.TextXAlignment.Center })
			count.Position = UDim2.fromOffset(0, 50)
			local name = UiKit.text(slot, { Text = m.Name, Size = 11, Color = C.TextMuted, AlignX = Enum.TextXAlignment.Center })
			name.Position = UDim2.fromOffset(0, 72)
			slot.Activated:Connect(function()
				UiKit.toast(m.Name .. (if m.Source then ": " .. m.Source else ""), "Info")
			end)
		end
		for i, st in path.Steps or {} do
			local done = st.Progress >= st.Goal
			if not done and not missing then
				missing = st.Text
			end
			local row = Instance.new("Frame")
			row.LayoutOrder = i
			row.BackgroundTransparency = 1
			row.Size = UDim2.new(1, 0, 0, 34)
			row.Parent = steps
			local t = UiKit.text(row, { Text = (if done then "Done  " else "") .. st.Text, Size = Theme.TextSize.Caption, Color = if done then C.Positive else C.Text })
			t.Size = UDim2.new(1, 0, 0, 18)
			local barHolder = Instance.new("Frame")
			barHolder.BackgroundTransparency = 1
			barHolder.Position = UDim2.fromOffset(0, 22)
			barHolder.Size = UDim2.new(1, 0, 0, 4)
			barHolder.Parent = row
			UiParts.progress(barHolder, if done then C.Positive else C.Accent, 4).set(st.Progress / math.max(1, st.Goal))
		end
		if busy then
			evolveBtn.setEnabled(false, nil)
		else
			evolveBtn.setEnabled(missing == nil, missing)
		end
	end

	local function renderTabs()
		clear(pathTabs)
		local p = plan
		if not p or #p.Paths <= 1 then
			return
		end
		for i, path in p.Paths do
			local on = i == pathIndex
			local tab = Instance.new("TextButton")
			tab.LayoutOrder = i
			tab.AutomaticSize = Enum.AutomaticSize.X
			tab.Size = UDim2.fromOffset(0, 32)
			tab.BackgroundColor3 = if on then C.Overlay else C.Base
			tab.BackgroundTransparency = if on then 0.1 else 0.5
			tab.BorderSizePixel = 0
			tab.FontFace = Theme.Font.Display
			tab.TextSize = Theme.TextSize.Label
			tab.TextColor3 = if on then UiParts.rarityColor(path.Into.Rarity) else C.TextMuted
			tab.Text = "  " .. string.upper(path.Label) .. "  "
			tab.Parent = pathTabs
			UiKit.corner(tab, Theme.Radius.Small)
			tab.Activated:Connect(function()
				pathIndex = i
				renderTabs()
				renderPath()
			end)
		end
	end

	local function select(uid: string)
		selectedUid = uid
		strip.select(uid)
		plan = b.getPlan(uid)
		pathIndex = 1
		local p = plan
		if p then
			before.show(if b.getUnitModel then b.getUnitModel(p.Unit.UnitId) else nil, p.Unit.Name, p.Unit.Rarity)
			beforeName.Text = string.upper(p.Unit.Name)
			beforeName.TextColor3 = UiParts.rarityColor(p.Unit.Rarity)
		end
		renderTabs()
		renderPath()
	end

	-- transformation: white-out over the "after" preview, swap, Hero name
	local function transform(path: Path)
		local flash = Instance.new("Frame")
		flash.BorderSizePixel = 0
		flash.BackgroundColor3 = C.Text
		flash.BackgroundTransparency = 1
		flash.Size = UDim2.fromScale(1, 1)
		flash.ZIndex = 20
		flash.Parent = w.Root
		UiKit.tween(beam, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Size = UDim2.new(0.4, 0, 0, 24), BackgroundTransparency = 0 })
		task.wait(0.5)
		UiKit.tween(flash, Theme.Motion.Fast, { BackgroundTransparency = 0 })
		task.wait(0.15)
		beam.Size = UDim2.new(0.4, 0, 0, 2)
		beam.BackgroundTransparency = 0.5
		local color = UiParts.rarityColor(path.Into.Rarity)
		local name = UiKit.text(flash, { Text = path.Into.Name, Font = Theme.Font.DisplayBold, Size = Theme.TextSize.Hero, Upper = true, Color = color, AlignX = Enum.TextXAlignment.Center })
		name.AnchorPoint = Vector2.new(0.5, 0.5)
		name.Position = UDim2.fromScale(0.5, 0.5)
		name.ZIndex = 21
		UiKit.tween(flash, Theme.Motion.Enter, { BackgroundColor3 = C.Scrim, BackgroundTransparency = 0.2 })
		local s = Instance.new("UIScale")
		s.Scale = 0.7
		s.Parent = name
		UiKit.tween(s, Theme.Motion.Emphasis, { Scale = 1 })
		task.wait(1.4)
		UiKit.tween(flash, Theme.Motion.Exit, { BackgroundTransparency = 1 })
		UiKit.tween(name, Theme.Motion.Exit, { TextTransparency = 1 }).Completed:Wait()
		flash:Destroy()
	end

	doEvolve = function()
		local uid, p = selectedUid, plan
		if busy or not uid or not p or not p.Paths[pathIndex] then
			return
		end
		local path = p.Paths[pathIndex]
		busy = true
		renderPath()
		local ok, err = b.evolve(uid, path.Id)
		if ok then
			transform(path)
		else
			UiKit.toast(err or "Evolution failed", "Error")
		end
		busy = false
		if refresh then
			refresh(uid)
		end
	end

	strip = UiParts.unitStrip(body, select)
	strip.Instance.AnchorPoint = Vector2.new(0, 1)
	strip.Instance.Position = UDim2.fromScale(0, 1)

	UiKit.onLayoutChanged(function(layout)
		local compact = layout == "Compact"
		steps.Visible = not compact -- Compact: steps show through the Evolve button's reason
		mats.Size = if compact then UDim2.new(1, -200, 1, 0) else UDim2.fromScale(0.55, 1)
	end)

	refresh = function(preselect: string?)
		local list = b.getCandidates()
		strip.set(list)
		local want = preselect or selectedUid
		local found = false
		for _, u in list do
			if u.Uid == want then
				found = true
			end
		end
		if want and found then
			select(want)
		elseif list[1] then
			select(list[1].Uid)
		else
			plan = nil
			before.show(nil, "No units can evolve yet", nil)
			renderTabs()
			renderPath()
		end
	end
	return w
end

function EvolutionScreen.init(b: Backend)
	backend = b
end

function EvolutionScreen.open(uid: string?)
	local b = backend
	if not b then
		UiKit.toast("Evolution is not open yet", "Warning")
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

return EvolutionScreen
