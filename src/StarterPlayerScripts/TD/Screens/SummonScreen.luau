--!strict
-- SummonScreen: the Starfall Sanctum's own interface (spec: docs/ui/SCREENS.md, "Summon").
-- Install as ModuleScript StarterPlayer.StarterPlayerScripts.TD.Screens.SummonScreen.
--
-- A stage, not a form: the active banner fills the window, controls sit on it. The screen never rolls;
-- backend.summon calls the live `Summon` RemoteFunction and the screen plays back the server's results.
--   SummonScreen.init(backend)              -- adapter in TDClient, docs/ui/INTEGRATION.md "Screens"
--   HubClient.registerMenu("Summon", function() SummonScreen.open() end)
--   HubHud.registerMenu("Summon", SummonScreen.open)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = ReplicatedStorage:WaitForChild("TD"):WaitForChild("UI")
local Theme = require(UI:WaitForChild("Theme"))
local UiKit = require(UI:WaitForChild("UiKit"))
local UiParts = require(UI:WaitForChild("UiParts"))

local C = Theme.Color

export type BannerView = {
	Id: string,
	Name: string,
	Accent: Color3?, -- banner's own colour (stage tint, tab rule); default violet
	Backdrop: string?, -- rbxassetid of the banner art; empty = night-sky stage in the accent colour
	EndsAt: number?, -- os.time() when the banner ends; nil = permanent
	Featured: { UiParts.UnitView & { UnitId: string? } },
	Rates: { UiParts.OddsRow },
	PityMax: number?, -- summons until the guarantee
	PityLabel: string?, -- e.g. "to a guaranteed Mythic"
	CostSingle: number,
	CostTen: number,
	TenNote: string?, -- e.g. "Epic or better guaranteed"
}

export type SummonResult = UiParts.UnitView & { New: boolean?, UnitId: string? }

export type Backend = {
	getBanners: () -> { BannerView }, -- active banners only
	getPity: (bannerId: string) -> number,
	getBalance: () -> number, -- gems
	onBalanceChanged: ((callback: () -> ()) -> ())?,
	summon: (bannerId: string, count: number) -> (boolean, { SummonResult } | string),
	getUnitModel: ((unitId: string) -> Model?)?,
}

local HIGH_RARITY = { Legendary = true, Mythic = true, Exclusive = true }
local TOP_RARITY = { Mythic = true, Exclusive = true }

local SummonScreen = {}

local backend: Backend? = nil
local win: UiKit.Window? = nil
local refresh: (() -> ())? = nil

local function timeLeft(endsAt: number?): string
	if not endsAt then
		return ""
	end
	local s = math.max(0, endsAt - os.time())
	local d, h, m = s // 86400, (s % 86400) // 3600, (s % 3600) // 60
	if d > 0 then
		return string.format("Ends in %dd %dh", d, h)
	end
	return string.format("Ends in %dh %dm", h, m)
end

local function build(b: Backend): UiKit.Window
	local w = UiKit.window({ Name = "TDSummon", Title = "Summon", Accent = C.Accent, Size = Vector2.new(880, 580) })
	local body = w.Body
	local banners: { BannerView } = {}
	local current: BannerView? = nil
	local busy = false

	-- banner tabs (top row)
	local tabs = Instance.new("Frame")
	tabs.BackgroundTransparency = 1
	tabs.Size = UDim2.new(1, 0, 0, Theme.TouchTarget)
	tabs.Parent = body
	UiKit.list(tabs, Enum.FillDirection.Horizontal, Theme.Space.S)

	-- the stage
	local stage = Instance.new("Frame")
	stage.Name = "Stage"
	stage.Position = UDim2.fromOffset(0, Theme.TouchTarget + Theme.Space.S)
	stage.Size = UDim2.new(1, 0, 1, -(Theme.TouchTarget + Theme.Space.S) - 96)
	stage.BackgroundColor3 = C.Scrim
	stage.BackgroundTransparency = 0.25
	stage.BorderSizePixel = 0
	stage.ClipsDescendants = true
	stage.Parent = body
	UiKit.corner(stage, Theme.Radius.Medium)
	local stageStroke = UiKit.stroke(stage)
	local backdrop = Instance.new("ImageLabel")
	backdrop.BackgroundTransparency = 1
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.ScaleType = Enum.ScaleType.Crop
	backdrop.ImageTransparency = 0.15
	backdrop.Parent = stage
	local tint = Instance.new("Frame") -- accent wash when no art is uploaded
	tint.BorderSizePixel = 0
	tint.Size = UDim2.fromScale(1, 1)
	tint.BackgroundTransparency = 0.88
	tint.Parent = stage

	local bannerTitle = UiKit.text(stage, { Text = "", Font = Theme.Font.DisplayBold, Size = Theme.TextSize.Hero, Upper = true })
	bannerTitle.Position = UDim2.fromOffset(Theme.Space.XL, Theme.Space.L)
	bannerTitle.Size = UDim2.new(0.7, 0, 0, 50)
	local timer = UiKit.text(stage, { Text = "", Font = Theme.Font.Timer, Size = Theme.TextSize.Body, Color = C.TextMuted, AlignX = Enum.TextXAlignment.Right })
	timer.AnchorPoint = Vector2.new(1, 0)
	timer.Position = UDim2.new(1, -Theme.Space.XL, 0, Theme.Space.L + 12)
	timer.Size = UDim2.fromOffset(200, 22)

	local previewHolder = Instance.new("Frame")
	previewHolder.BackgroundTransparency = 1
	previewHolder.Position = UDim2.new(0, 0, 0, 70)
	previewHolder.Size = UDim2.new(0.58, 0, 1, -70)
	previewHolder.Parent = stage
	local preview = UiParts.preview(previewHolder)
	local featuredName = UiKit.text(stage, { Text = "", Font = Theme.Font.DisplayBold, Size = Theme.TextSize.Title, Upper = true })
	featuredName.AnchorPoint = Vector2.new(0, 1)
	featuredName.Position = UDim2.new(0, Theme.Space.XL, 1, -Theme.Space.L)
	featuredName.Size = UDim2.new(0.5, 0, 0, 28)

	local featuredCol = Instance.new("Frame")
	featuredCol.BackgroundTransparency = 1
	featuredCol.AnchorPoint = Vector2.new(1, 0)
	featuredCol.Position = UDim2.new(1, -Theme.Space.XL, 0, 70)
	featuredCol.Size = UDim2.new(0.36, 0, 1, -70 - Theme.Space.L)
	featuredCol.Parent = stage
	UiKit.list(featuredCol, Enum.FillDirection.Vertical, Theme.Space.S, Enum.HorizontalAlignment.Right).VerticalAlignment = Enum.VerticalAlignment.Top

	-- rates overlay (inside the stage)
	local ratesPanel = UiKit.surface(stage, "Base", Theme.Radius.Medium)
	ratesPanel.AnchorPoint = Vector2.new(1, 0)
	ratesPanel.Position = UDim2.new(1, -Theme.Space.XL, 0, 70)
	ratesPanel.Size = UDim2.new(0.36, 0, 0, 260)
	ratesPanel.ZIndex = 5
	ratesPanel.Visible = false
	UiKit.padding(ratesPanel, Theme.Space.M)
	local rates = UiParts.rarityTable(ratesPanel)

	-- footer: pity + rates link on the left, x1 / x10 on the right
	local footer = Instance.new("Frame")
	footer.BackgroundTransparency = 1
	footer.AnchorPoint = Vector2.new(0, 1)
	footer.Position = UDim2.fromScale(0, 1)
	footer.Size = UDim2.new(1, 0, 0, 84)
	footer.Parent = body

	local pityLabel = UiKit.text(footer, { Text = "", Size = Theme.TextSize.Caption, Font = Theme.Font.BodyBold, Color = C.TextMuted })
	pityLabel.Position = UDim2.fromOffset(0, 10)
	pityLabel.Size = UDim2.new(0.4, 0, 0, 18)
	local pityHolder = Instance.new("Frame")
	pityHolder.BackgroundTransparency = 1
	pityHolder.Position = UDim2.fromOffset(0, 34)
	pityHolder.Size = UDim2.new(0.4, 0, 0, 8)
	pityHolder.Parent = footer
	local pity = UiParts.progress(pityHolder, C.Emphasis, 8)
	local ratesBtn = UiKit.button(footer, { Text = "Rates", Variant = "Ghost", Width = 96, OnActivated = function()
		ratesPanel.Visible = not ratesPanel.Visible
		featuredCol.Visible = not ratesPanel.Visible
	end })
	ratesBtn.Instance.Position = UDim2.fromOffset(0, 48)

	local buttons = Instance.new("Frame")
	buttons.BackgroundTransparency = 1
	buttons.AnchorPoint = Vector2.new(1, 0)
	buttons.Position = UDim2.fromScale(1, 0)
	buttons.Size = UDim2.new(0.58, 0, 1, 0)
	buttons.Parent = footer
	UiKit.list(buttons, Enum.FillDirection.Horizontal, Theme.Space.M, Enum.HorizontalAlignment.Right).VerticalAlignment = Enum.VerticalAlignment.Top

	local one: UiKit.Button
	local ten: UiKit.Button
	local oneCost: UiParts.CostTag
	local tenCost: UiParts.CostTag
	local tenNote: TextLabel
	local updateButtons: () -> ()
	local doSummon: (count: number) -> ()

	local function summonButton(label: string, order: number, emphasis: boolean, count: number): (UiKit.Button, UiParts.CostTag, TextLabel)
		local holder = Instance.new("Frame")
		holder.BackgroundTransparency = 1
		holder.LayoutOrder = order
		holder.Size = UDim2.fromOffset(210, 84)
		holder.Parent = buttons
		local btn = UiKit.button(holder, { Text = label, Variant = "Primary", OnActivated = function()
			task.spawn(doSummon, count)
		end })
		btn.Instance.Size = UDim2.new(1, 0, 0, 48)
		if emphasis then
			btn.Instance.BackgroundColor3 = C.Emphasis
			local s = btn.Instance:FindFirstChildOfClass("UIStroke")
			if s then
				s.Color = C.Text
			end
		end
		local tag = UiParts.costTag(holder, "Gems", C.Gems)
		tag.Instance.AnchorPoint = Vector2.new(0.5, 0)
		tag.Instance.Position = UDim2.new(0.5, 0, 0, 44)
		local note = UiKit.text(holder, { Text = "", Size = Theme.TextSize.Caption, Color = C.TextFaint, AlignX = Enum.TextXAlignment.Center })
		note.Position = UDim2.fromOffset(0, 70)
		note.Size = UDim2.new(1, 0, 0, 14)
		return btn, tag, note
	end
	one, oneCost = summonButton("Summon x1", 1, false, 1)
	ten, tenCost, tenNote = summonButton("Summon x10", 2, true, 10)

	updateButtons = function()
		local bn = current
		local balance = b.getBalance()
		for _, spec in { { one, oneCost, if bn then bn.CostSingle else 0 }, { ten, tenCost, if bn then bn.CostTen else 0 } } do
			local btn, tag, cost = spec[1] :: UiKit.Button, spec[2] :: UiParts.CostTag, spec[3] :: number
			tag.set(cost, balance >= cost)
			if busy or not bn then
				btn.setEnabled(false, nil)
			elseif balance < cost then
				btn.setEnabled(false, string.format("Need %d more gems", cost - balance))
			else
				btn.setEnabled(true)
			end
		end
		tenNote.Text = if bn and bn.TenNote then bn.TenNote else ""
	end

	local function showFeatured(unit: UiParts.UnitView & { UnitId: string? })
		local model = if b.getUnitModel and unit.UnitId then b.getUnitModel(unit.UnitId) else nil
		preview.show(model, unit.Name, unit.Rarity)
		featuredName.Text = string.upper(unit.Name)
		featuredName.TextColor3 = UiParts.rarityColor(unit.Rarity)
	end

	local function selectBanner(bn: BannerView)
		current = bn
		local accent = bn.Accent or C.Accent
		bannerTitle.Text = string.upper(bn.Name)
		timer.Text = timeLeft(bn.EndsAt)
		backdrop.Image = bn.Backdrop or ""
		tint.BackgroundColor3 = accent
		tint.BackgroundTransparency = if bn.Backdrop and bn.Backdrop ~= "" then 1 else 0.85
		stageStroke.Color = accent
		for _, tab in tabs:GetChildren() do
			if tab:IsA("TextButton") then
				local on = tab.Name == bn.Id
				tab.TextColor3 = if on then C.Text else C.TextMuted
				local rule = tab:FindFirstChild("Rule")
				if rule and rule:IsA("Frame") then
					rule.Visible = on
					rule.BackgroundColor3 = accent
				end
			end
		end
		for _, child in featuredCol:GetChildren() do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		for i, unit in bn.Featured do
			local row = Instance.new("TextButton")
			row.LayoutOrder = i
			row.Text = ""
			row.Size = UDim2.new(1, 0, 0, 64)
			row.BackgroundColor3 = C.Raised
			row.BackgroundTransparency = Theme.Transparency.Card
			row.BorderSizePixel = 0
			row.Parent = featuredCol
			UiKit.corner(row, Theme.Radius.Medium)
			UiKit.stroke(row, UiParts.rarityColor(unit.Rarity))
			UiKit.interactive(row)
			local card = UiParts.unitCard(row, unit, Vector2.new(52, 52))
			card.Position = UDim2.fromOffset(6, 6)
			card.Active = false
			local name = UiKit.text(row, { Text = unit.Name, Font = Theme.Font.BodyBold })
			name.Position = UDim2.fromOffset(68, 10)
			name.Size = UDim2.new(1, -76, 0, 22)
			local rarity = UiKit.text(row, { Text = unit.Rarity, Size = Theme.TextSize.Caption, Font = Theme.Font.BodyBold, Color = UiParts.rarityColor(unit.Rarity) })
			rarity.Position = UDim2.fromOffset(68, 34)
			rarity.Size = UDim2.new(1, -76, 0, 18)
			row.Activated:Connect(function()
				showFeatured(unit)
			end)
		end
		if bn.Featured[1] then
			showFeatured(bn.Featured[1])
		end
		rates.set(bn.Rates)
		local count = b.getPity(bn.Id)
		if bn.PityMax and bn.PityMax > 0 then
			pityLabel.Text = string.format("Pity %d / %d %s", count, bn.PityMax, bn.PityLabel or "")
			pity.set(count / bn.PityMax)
			pityHolder.Visible = true
		else
			pityLabel.Text = ""
			pityHolder.Visible = false
		end
		updateButtons()
	end

	local function buildTabs()
		for _, child in tabs:GetChildren() do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		for i, bn in banners do
			local tab = Instance.new("TextButton")
			tab.Name = bn.Id
			tab.LayoutOrder = i
			tab.AutomaticSize = Enum.AutomaticSize.X
			tab.Size = UDim2.fromOffset(0, Theme.TouchTarget)
			tab.BackgroundTransparency = 1
			tab.FontFace = Theme.Font.Display
			tab.TextSize = Theme.TextSize.Label
			tab.TextColor3 = C.TextMuted
			tab.Text = "  " .. string.upper(bn.Name) .. "  "
			tab.Parent = tabs
			local rule = Instance.new("Frame")
			rule.Name = "Rule"
			rule.BorderSizePixel = 0
			rule.AnchorPoint = Vector2.new(0.5, 1)
			rule.Position = UDim2.fromScale(0.5, 1)
			rule.Size = UDim2.new(0.6, 0, 0, Theme.Size.AccentRule)
			rule.Visible = false
			rule.Parent = tab
			tab.Activated:Connect(function()
				if not busy then
					selectBanner(bn)
				end
			end)
		end
	end

	-- Reveal ------------------------------------------------------------------------------------------
	local function bigReveal(unit: SummonResult)
		local color = UiParts.rarityColor(unit.Rarity)
		local veil = Instance.new("Frame")
		veil.BorderSizePixel = 0
		veil.BackgroundColor3 = if TOP_RARITY[unit.Rarity] then C.Emphasis else color
		veil.BackgroundTransparency = 0.2
		veil.Size = UDim2.fromScale(1, 1)
		veil.ZIndex = 20
		veil.Parent = w.Root
		UiKit.tween(veil, Theme.Motion.Enter, { BackgroundColor3 = C.Scrim, BackgroundTransparency = 0.15 })
		local holder = Instance.new("Frame")
		holder.BackgroundTransparency = 1
		holder.Size = UDim2.fromScale(1, 0.75)
		holder.ZIndex = 21
		holder.Parent = veil
		local p = UiParts.preview(holder)
		p.show(if b.getUnitModel and unit.UnitId then b.getUnitModel(unit.UnitId) else nil, unit.Name, unit.Rarity)
		local name = UiKit.text(veil, { Text = unit.Name, Font = Theme.Font.DisplayBold, Size = Theme.TextSize.Hero, Upper = true, Color = color, AlignX = Enum.TextXAlignment.Center })
		name.AnchorPoint = Vector2.new(0.5, 0)
		name.Position = UDim2.fromScale(0.5, 0.76)
		name.ZIndex = 22
		local sub = UiKit.text(veil, { Text = unit.Rarity .. (if unit.Shiny then "  ·  SHINY" else "") .. (if unit.New then "  ·  NEW" else ""),
			Font = Theme.Font.Display, Size = Theme.TextSize.Title, Upper = true, AlignX = Enum.TextXAlignment.Center })
		sub.AnchorPoint = Vector2.new(0.5, 0)
		sub.Position = UDim2.fromScale(0.5, 0.88)
		sub.ZIndex = 22
		local s = Instance.new("UIScale")
		s.Scale = 0.8
		s.Parent = name
		UiKit.tween(s, Theme.Motion.Emphasis, { Scale = 1 })
		-- hold, tap to continue (or 2.5 s)
		local done = false
		local tap = Instance.new("TextButton")
		tap.BackgroundTransparency = 1
		tap.Text = ""
		tap.Size = UDim2.fromScale(1, 1)
		tap.ZIndex = 30
		tap.Parent = veil
		tap.Activated:Connect(function()
			done = true
		end)
		local t0 = os.clock()
		while not done and os.clock() - t0 < 2.5 do
			task.wait(0.05)
		end
		veil:Destroy()
	end

	local function playResults(results: { SummonResult })
		-- charge: darken the stage, gather a ring of light
		local overlay = Instance.new("Frame")
		overlay.BackgroundColor3 = C.Scrim
		overlay.BackgroundTransparency = 1
		overlay.BorderSizePixel = 0
		overlay.Size = UDim2.fromScale(1, 1)
		overlay.ZIndex = 10
		overlay.Parent = stage
		local ring = Instance.new("Frame")
		ring.AnchorPoint = Vector2.new(0.5, 0.5)
		ring.Position = UDim2.fromScale(0.5, 0.5)
		ring.Size = UDim2.fromOffset(420, 420)
		ring.BackgroundTransparency = 1
		ring.ZIndex = 11
		ring.Parent = overlay
		local rc = Instance.new("UICorner")
		rc.CornerRadius = UDim.new(0.5, 0)
		rc.Parent = ring
		UiKit.stroke(ring, C.Accent, 3)
		UiKit.tween(overlay, Theme.Motion.Enter, { BackgroundTransparency = 0.1 })
		UiKit.tween(ring, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Size = UDim2.fromOffset(40, 40) })
		task.wait(0.6)
		ring:Destroy()

		local skip = false
		local skipBtn = UiKit.button(overlay, { Text = "Skip", Variant = "Ghost", Width = 96, OnActivated = function()
			skip = true
		end })
		skipBtn.Instance.AnchorPoint = Vector2.new(1, 0)
		skipBtn.Instance.Position = UDim2.new(1, -Theme.Space.M, 0, Theme.Space.M)
		skipBtn.Instance.ZIndex = 12

		-- grid: 1 card centred, or 5 x 2
		local grid = Instance.new("Frame")
		grid.BackgroundTransparency = 1
		grid.AnchorPoint = Vector2.new(0.5, 0.5)
		grid.Position = UDim2.fromScale(0.5, 0.5)
		grid.Size = UDim2.fromOffset(if #results > 1 then 5 * 100 + 4 * 12 else 100, if #results > 1 then 2 * 112 + 12 else 112)
		grid.ZIndex = 12
		grid.Parent = overlay
		local layout = Instance.new("UIGridLayout")
		layout.CellSize = UDim2.fromOffset(100, 112)
		layout.CellPadding = UDim2.fromOffset(12, 12)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = grid

		for i, unit in results do
			local slot = Instance.new("Frame")
			slot.BackgroundTransparency = 1
			slot.LayoutOrder = i
			slot.Parent = grid
			local card = UiParts.unitCard(slot, unit, Vector2.new(100, 112))
			card.ZIndex = 13
			local s = Instance.new("UIScale")
			s.Scale = 0.6
			s.Parent = card
			card.Visible = true
			UiKit.tween(s, Theme.Motion.Emphasis, { Scale = 1 })
			if unit.New then
				local badge = UiKit.text(card, { Text = "NEW", Size = 11, Font = Theme.Font.DisplayBold, Color = C.Emphasis, AlignX = Enum.TextXAlignment.Right })
				badge.AnchorPoint = Vector2.new(1, 0)
				badge.Position = UDim2.new(1, -Theme.Space.XS, 0, Theme.Space.XS)
				badge.Size = UDim2.fromOffset(40, 14)
			end
			if HIGH_RARITY[unit.Rarity] and not skip then
				bigReveal(unit)
			elseif not skip then
				task.wait(0.12)
			end
		end
		-- summary stays until tapped
		skipBtn.setText("Done")
		local closed = false
		skipBtn.Instance.Activated:Connect(function()
			closed = true
		end)
		while not closed and overlay.Parent and w.isOpen() do
			task.wait(0.1)
		end
		overlay:Destroy()
	end

	doSummon = function(count: number)
		local bn = current
		if busy or not bn then
			return
		end
		busy = true
		updateButtons()
		local ok, res = b.summon(bn.Id, count)
		if ok and typeof(res) == "table" then
			playResults(res :: { SummonResult })
		else
			UiKit.toast(if typeof(res) == "string" then res else "Summon failed", "Error")
		end
		busy = false
		if current then
			selectBanner(current) -- refresh pity + costs from the server's new state
		end
	end

	UiKit.onLayoutChanged(function(layout)
		local compact = layout == "Compact"
		featuredCol.Size = if compact then UDim2.new(0.42, 0, 1, -70 - Theme.Space.L) else UDim2.new(0.36, 0, 1, -70 - Theme.Space.L)
		previewHolder.Size = if compact then UDim2.new(0.55, 0, 1, -70) else UDim2.new(0.58, 0, 1, -70)
		bannerTitle.TextSize = if compact then Theme.TextSize.Headline else Theme.TextSize.Hero
	end)

	refresh = function()
		banners = b.getBanners()
		buildTabs()
		local keep: BannerView? = nil
		for _, bn in banners do
			if current and bn.Id == current.Id then
				keep = bn
			end
		end
		local pick = keep or banners[1]
		if pick then
			selectBanner(pick)
		else
			current = nil
			bannerTitle.Text = "NO ACTIVE BANNER"
			updateButtons()
		end
	end
	if b.onBalanceChanged then
		b.onBalanceChanged(function()
			if not busy then
				updateButtons()
			end
		end)
	end
	-- banner countdown
	task.spawn(function()
		while w.Gui.Parent do
			if w.isOpen() and current then
				timer.Text = timeLeft(current.EndsAt)
			end
			task.wait(30)
		end
	end)
	return w
end

function SummonScreen.init(b: Backend)
	backend = b
end

function SummonScreen.open()
	local b = backend
	if not b then
		UiKit.toast("Summon is not connected yet", "Warning")
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

return SummonScreen
