--!strict
-- UiParts: system-level parts shared by several screens (Summon, Trait Reroll, Evolution, Units).
-- Install as ModuleScript ReplicatedStorage.TD.UI.UiParts (client). Built on Theme + UiKit.
-- These are pieces, not layouts: each screen places them in its own arrangement (docs/ui/SCREENS.md).

local RunService = game:GetService("RunService")

local Theme = require(script.Parent:WaitForChild("Theme"))
local UiKit = require(script.Parent:WaitForChild("UiKit"))

local C = Theme.Color
local UiParts = {}

function UiParts.rarityColor(rarity: string?): Color3
	return (rarity and C.Rarity[rarity]) or C.TextMuted
end

-- Cost tag: currency icon + amount, red when unaffordable.
export type CostTag = { Instance: Frame, set: (amount: number, affordable: boolean) -> () }

function UiParts.costTag(parent: Instance, currencyIcon: string, color: Color3): CostTag
	local f = Instance.new("Frame")
	f.BackgroundColor3 = C.Scrim
	f.BackgroundTransparency = 0.4
	f.BorderSizePixel = 0
	f.AutomaticSize = Enum.AutomaticSize.X
	f.Size = UDim2.fromOffset(0, 26)
	f.Parent = parent
	UiKit.corner(f, Theme.Radius.Small)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, Theme.Space.XS)
	pad.PaddingRight = UDim.new(0, Theme.Space.S)
	pad.Parent = f
	UiKit.list(f, Enum.FillDirection.Horizontal, Theme.Space.XS)
	UiKit.icon(f, currencyIcon, 18, color)
	local t = UiKit.text(f, { Text = "0", Font = Theme.Font.BodyBold, Size = Theme.TextSize.Body })
	t.AutomaticSize = Enum.AutomaticSize.X
	t.Size = UDim2.fromOffset(0, 26)
	t.TextTruncate = Enum.TextTruncate.None
	return {
		Instance = f,
		set = function(amount: number, affordable: boolean)
			t.Text = UiKit.formatNumber(amount)
			t.TextColor3 = if affordable then C.Text else C.Danger
		end,
	}
end

-- Rarity odds table. rows = { { Rarity, Chance (0..1) } } in display order. highlight(rarity) flashes a row.
export type OddsRow = { Rarity: string, Label: string?, Chance: number }
export type RarityTable = { Instance: Frame, set: (rows: { OddsRow }) -> (), highlight: (rarity: string) -> () }

function UiParts.rarityTable(parent: Instance): RarityTable
	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = parent
	UiKit.list(frame, Enum.FillDirection.Vertical, Theme.Space.XS).VerticalAlignment = Enum.VerticalAlignment.Top
	local rowsByRarity: { [string]: Frame } = {}
	local api: RarityTable
	api = {
		Instance = frame,
		set = function(rows: { OddsRow })
			for _, child in frame:GetChildren() do
				if child:IsA("Frame") then
					child:Destroy()
				end
			end
			table.clear(rowsByRarity)
			for i, r in rows do
				local color = UiParts.rarityColor(r.Rarity)
				local row = UiKit.surface(frame, "Raised", Theme.Radius.Small)
				row.LayoutOrder = i
				row.Size = UDim2.new(1, 0, 0, 30)
				local stroke = row:FindFirstChildOfClass("UIStroke")
				if stroke then
					stroke.Color = color
					stroke.Transparency = 0.55
				end
				local name = UiKit.text(row, { Text = r.Label or r.Rarity, Font = Theme.Font.BodyBold, Color = color })
				name.Position = UDim2.fromOffset(Theme.Space.M, 0)
				name.Size = UDim2.new(0.6, 0, 1, 0)
				local pct = UiKit.text(row, { Text = string.format("%.2f%%", r.Chance * 100), Font = Theme.Font.BodyMedium, AlignX = Enum.TextXAlignment.Right })
				pct.AnchorPoint = Vector2.new(1, 0)
				pct.Position = UDim2.new(1, -Theme.Space.M, 0, 0)
				pct.Size = UDim2.new(0.4, 0, 1, 0)
				rowsByRarity[r.Rarity] = row
			end
		end,
		highlight = function(rarity: string)
			local row = rowsByRarity[rarity]
			if row then
				row.BackgroundColor3 = UiParts.rarityColor(rarity)
				row.BackgroundTransparency = 0.6
				UiKit.tween(row, Theme.Motion.Emphasis, { BackgroundColor3 = C.Raised, BackgroundTransparency = Theme.Transparency.Card })
			end
		end,
	}
	return api
end

-- Unit preview: a ViewportFrame with the unit model turning slowly, or a rarity-tinted placeholder plate
-- with the unit's name when no model is available. setAura(color) tints the floor ring (trait / rarity).
export type Preview = { Instance: Frame, show: (model: Model?, name: string, rarity: string?) -> (), setAura: (color: Color3) -> () }

function UiParts.preview(parent: Instance): Preview
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.ClipsDescendants = true
	holder.Parent = parent

	local aura = Instance.new("Frame") -- elliptical floor glow under the unit
	aura.Name = "Aura"
	aura.AnchorPoint = Vector2.new(0.5, 0.5)
	aura.Position = UDim2.fromScale(0.5, 0.86)
	aura.Size = UDim2.fromScale(0.7, 0.1)
	aura.BackgroundColor3 = C.Accent
	aura.BackgroundTransparency = 0.6
	aura.BorderSizePixel = 0
	aura.Parent = holder
	local ac = Instance.new("UICorner")
	ac.CornerRadius = UDim.new(0.5, 0)
	ac.Parent = aura

	local vp = Instance.new("ViewportFrame")
	vp.BackgroundTransparency = 1
	vp.Size = UDim2.fromScale(1, 1)
	vp.Ambient = Color3.fromRGB(150, 140, 180)
	vp.LightColor = Color3.fromRGB(255, 240, 230)
	vp.LightDirection = Vector3.new(-1, -1, -0.6)
	vp.Parent = holder
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	cam.Parent = vp
	vp.CurrentCamera = cam

	local placeholder = UiKit.text(holder, { Text = "", Font = Theme.Font.DisplayBold, Size = Theme.TextSize.Headline, AlignX = Enum.TextXAlignment.Center, Upper = true })
	placeholder.AnchorPoint = Vector2.new(0.5, 0.5)
	placeholder.Position = UDim2.fromScale(0.5, 0.5)
	placeholder.Size = UDim2.new(1, -Theme.Space.XL, 0, 40)

	local current: Model? = nil
	local angle = 0
	local focus = CFrame.new()
	local distance = 10
	local conn: RBXScriptConnection? = nil

	local function stop()
		if conn then
			conn:Disconnect()
			conn = nil
		end
	end

	return {
		Instance = holder,
		show = function(model: Model?, name: string, rarity: string?)
			stop()
			if current then
				current:Destroy()
				current = nil
			end
			aura.BackgroundColor3 = UiParts.rarityColor(rarity)
			if model then
				local m = model:Clone()
				m.Parent = vp
				local cf, size = m:GetBoundingBox()
				focus = cf
				distance = math.max(size.Y, size.X, size.Z) * 2.2
				current = m
				placeholder.Text = ""
				conn = RunService.RenderStepped:Connect(function(dt)
					if not holder:IsDescendantOf(game) or not holder.Visible then
						return
					end
					angle += dt * 0.5
					cam.CFrame = CFrame.new(focus.Position + Vector3.new(math.sin(angle) * distance, size.Y * 0.15, math.cos(angle) * distance), focus.Position)
				end)
				holder.Destroying:Once(stop)
			else
				placeholder.Text = name
				placeholder.TextColor3 = UiParts.rarityColor(rarity)
			end
		end,
		setAura = function(color: Color3)
			UiKit.tween(aura, Theme.Motion.Enter, { BackgroundColor3 = color })
		end,
	}
end

-- Unit card: portrait slot (rarity-framed), level, name. Used by the unit strip and results grids.
export type UnitView = { Uid: string, Name: string, Rarity: string, Level: number?, Stars: number?, Shiny: boolean?, Portrait: string? }

function UiParts.unitCard(parent: Instance, unit: UnitView, size: Vector2): TextButton
	local color = UiParts.rarityColor(unit.Rarity)
	local card = Instance.new("TextButton")
	card.Name = unit.Uid
	card.Text = ""
	card.Size = UDim2.fromOffset(size.X, size.Y)
	card.BackgroundColor3 = C.Raised
	card.BackgroundTransparency = Theme.Transparency.Card
	card.BorderSizePixel = 0
	card.Parent = parent
	UiKit.corner(card, Theme.Radius.Medium)
	local stroke = UiKit.stroke(card, color, Theme.Stroke.Hairline)
	stroke.Name = "Frame"
	UiKit.interactive(card)
	if unit.Portrait and unit.Portrait ~= "" then
		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.Size = UDim2.fromScale(1, 1)
		img.Image = unit.Portrait
		img.ScaleType = Enum.ScaleType.Crop
		img.Parent = card
		UiKit.corner(img, Theme.Radius.Medium)
	else
		local initials = UiKit.text(card, { Text = string.sub(unit.Name, 1, 2), Font = Theme.Font.DisplayBold, Size = math.floor(size.Y * 0.32), Color = color, AlignX = Enum.TextXAlignment.Center, Upper = true })
		initials.AnchorPoint = Vector2.new(0.5, 0.5)
		initials.Position = UDim2.fromScale(0.5, 0.42)
		initials.Size = UDim2.new(1, 0, 0, size.Y * 0.4)
	end
	local band = Instance.new("Frame") -- rarity band at the bottom with the level
	band.BorderSizePixel = 0
	band.BackgroundColor3 = C.Scrim
	band.BackgroundTransparency = 0.25
	band.AnchorPoint = Vector2.new(0, 1)
	band.Position = UDim2.fromScale(0, 1)
	band.Size = UDim2.new(1, 0, 0, 20)
	band.Parent = card
	local rule = Instance.new("Frame")
	rule.BorderSizePixel = 0
	rule.BackgroundColor3 = color
	rule.Size = UDim2.new(1, 0, 0, 2)
	rule.Parent = band
	local lv = UiKit.text(band, { Text = if unit.Level then "Lv. " .. unit.Level else unit.Name, Size = Theme.TextSize.Caption, Font = Theme.Font.BodyBold })
	lv.Position = UDim2.fromOffset(Theme.Space.S, 2)
	lv.Size = UDim2.new(1, -Theme.Space.S, 1, -2)
	if unit.Shiny then
		local s = UiKit.text(card, { Text = "SHINY", Size = 11, Font = Theme.Font.DisplayBold, Color = C.Emphasis })
		s.Position = UDim2.fromOffset(Theme.Space.XS, Theme.Space.XS)
		s.Size = UDim2.fromOffset(60, 14)
	end
	return card
end

-- Selected state for a unit card: strong rarity stroke + brackets.
function UiParts.setSelected(card: GuiObject, selected: boolean)
	local frame = card:FindFirstChild("Frame")
	if frame and frame:IsA("UIStroke") then
		frame.Thickness = if selected then Theme.Stroke.Focus else Theme.Stroke.Hairline
	end
	for _, child in card:GetChildren() do
		if child.Name == "Bracket" then
			child:Destroy()
		end
	end
	if selected then
		UiKit.brackets(card, C.Text, 10)
	end
end

-- Unit strip: horizontal scroller of owned units with a rarity filter. onSelect(uid).
export type UnitStrip = { Instance: Frame, set: (units: { UnitView }) -> (), select: (uid: string) -> () }

local RARITY_ORDER = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Exclusive" }

function UiParts.unitStrip(parent: Instance, onSelect: (uid: string) -> ()): UnitStrip
	local bar = UiKit.surface(parent, "Base", Theme.Radius.Medium)
	bar.Size = UDim2.new(1, 0, 0, 104)
	local filterBtn = Instance.new("TextButton")
	filterBtn.AnchorPoint = Vector2.new(1, 0.5)
	filterBtn.Position = UDim2.new(1, -Theme.Space.M, 0.5, 0)
	filterBtn.Size = UDim2.fromOffset(110, Theme.TouchTarget)
	filterBtn.BackgroundColor3 = C.Raised
	filterBtn.BorderSizePixel = 0
	filterBtn.FontFace = Theme.Font.Display
	filterBtn.TextSize = Theme.TextSize.Label
	filterBtn.TextColor3 = C.TextMuted
	filterBtn.Text = "ALL"
	filterBtn.Parent = bar
	UiKit.corner(filterBtn, Theme.Radius.Medium)
	UiKit.stroke(filterBtn)
	UiKit.interactive(filterBtn, C.Overlay, C.Raised)

	local scroller = Instance.new("ScrollingFrame")
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.Position = UDim2.fromOffset(Theme.Space.M, Theme.Space.S)
	scroller.Size = UDim2.new(1, -110 - Theme.Space.M * 3, 1, -Theme.Space.S * 2)
	scroller.ScrollingDirection = Enum.ScrollingDirection.X
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.X
	scroller.CanvasSize = UDim2.new()
	scroller.ScrollBarThickness = 3
	scroller.ScrollBarImageColor3 = C.StrokeStrong
	scroller.Parent = bar
	UiKit.list(scroller, Enum.FillDirection.Horizontal, Theme.Space.S)

	local all: { UnitView } = {}
	local filter: string? = nil
	local cards: { [string]: TextButton } = {}
	local selected: string? = nil

	local function rank(r: string): number
		return table.find(RARITY_ORDER, r) or 0
	end

	local function render()
		for _, card in cards do
			card:Destroy()
		end
		table.clear(cards)
		local list = table.clone(all)
		table.sort(list, function(a, b)
			if rank(a.Rarity) ~= rank(b.Rarity) then
				return rank(a.Rarity) > rank(b.Rarity)
			end
			return (a.Level or 0) > (b.Level or 0)
		end)
		for i, u in list do
			if not filter or u.Rarity == filter then
				local card = UiParts.unitCard(scroller, u, Vector2.new(80, 84))
				card.LayoutOrder = i
				card.Activated:Connect(function()
					onSelect(u.Uid)
				end)
				cards[u.Uid] = card
				if u.Uid == selected then
					UiParts.setSelected(card, true)
				end
			end
		end
	end

	filterBtn.Activated:Connect(function()
		-- cycle: All -> each rarity present -> All
		local present = {}
		for _, r in RARITY_ORDER do
			for _, u in all do
				if u.Rarity == r then
					table.insert(present, r)
					break
				end
			end
		end
		local idx = if filter then table.find(present, filter) else 0
		local nextIdx = (idx or 0) + 1
		filter = present[nextIdx]
		filterBtn.Text = if filter then string.upper(filter) else "ALL"
		filterBtn.TextColor3 = if filter then UiParts.rarityColor(filter) else C.TextMuted
		render()
	end)

	return {
		Instance = bar,
		set = function(units: { UnitView })
			all = units
			render()
		end,
		select = function(uid: string)
			if selected and cards[selected] then
				UiParts.setSelected(cards[selected], false)
			end
			selected = uid
			if cards[uid] then
				UiParts.setSelected(cards[uid], true)
			end
		end,
	}
end

return UiParts
