--!strict
-- CollectionBookScreen: the Collection Book (spec: docs/ui/SCREENS.md, "Collection Book").
-- Install as ModuleScript StarterPlayer.StarterPlayerScripts.TD.Screens.CollectionBookScreen.
--
-- A bound book, not a grid dump: chapter tabs along the top edge (one per group: world, element...),
-- two facing pages of entries (one page on Compact), silhouettes for units not yet discovered, a spine
-- between the pages, and a milestone track along the bottom with real claim buttons.
--   CollectionBookScreen.init(backend)
--   HubHud.registerMenu("Collection", CollectionBookScreen.open)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = ReplicatedStorage:WaitForChild("TD"):WaitForChild("UI")
local Theme = require(UI:WaitForChild("Theme"))
local UiKit = require(UI:WaitForChild("UiKit"))
local UiParts = require(UI:WaitForChild("UiParts"))

local C = Theme.Color

export type Entry = {
	UnitId: string,
	Name: string,
	Rarity: string,
	Group: string, -- chapter the entry belongs to; chapters appear in first-seen order
	Discovered: boolean, -- from Profile.Discovered
	Portrait: string?,
	FirstAt: number?, -- os.time() of first summon, if the profile keeps it
	Blurb: string?, -- one line of flavour shown when discovered
}

export type Milestone = { Id: string, Need: number, Reward: string, Claimed: boolean }

export type Backend = {
	getEntries: () -> { Entry },
	getMilestones: (() -> { Milestone })?, -- nil until Collection milestones exist on the server
	claimMilestone: ((id: string) -> (boolean, string?))?,
	getUnitModel: ((unitId: string) -> Model?)?,
}

local PER_PAGE = 8 -- 4 x 2 per page

local CollectionBookScreen = {}

local backend: Backend? = nil
local win: UiKit.Window? = nil
local refresh: (() -> ())? = nil

local function build(b: Backend): UiKit.Window
	local w = UiKit.window({ Name = "TDCollection", Title = "Collection Book", Accent = C.Gold, Size = Vector2.new(880, 580) })
	local body = w.Body

	local entries: { Entry } = {}
	local groups: { string } = {}
	local group: string? = nil
	local spread = 1 -- page spread index within the chapter
	local compact = false

	-- chapter tabs
	local tabs = Instance.new("Frame")
	tabs.BackgroundTransparency = 1
	tabs.Size = UDim2.new(1, -140, 0, 36)
	tabs.Parent = body
	UiKit.list(tabs, Enum.FillDirection.Horizontal, Theme.Space.XS)
	local completion = UiKit.text(body, { Text = "", Font = Theme.Font.Display, Size = Theme.TextSize.Label, Upper = true, Color = C.Gold, AlignX = Enum.TextXAlignment.Right })
	completion.AnchorPoint = Vector2.new(1, 0)
	completion.Position = UDim2.fromScale(1, 0)
	completion.Size = UDim2.fromOffset(140, 36)

	-- the book: two pages and a spine
	local book = Instance.new("Frame")
	book.BackgroundTransparency = 1
	book.Position = UDim2.fromOffset(0, 44)
	book.Parent = body
	local function page(): Frame
		local p = UiKit.surface(book, "Raised", Theme.Radius.Small)
		UiKit.padding(p, Theme.Space.M)
		local grid = Instance.new("UIGridLayout")
		grid.CellPadding = UDim2.fromOffset(Theme.Space.S, Theme.Space.S)
		grid.CellSize = UDim2.new(0.25, -Theme.Space.S, 0.5, -Theme.Space.S)
		grid.SortOrder = Enum.SortOrder.LayoutOrder
		grid.Parent = p
		return p
	end
	local left = page()
	local right = page()
	local spine = Instance.new("Frame")
	spine.BorderSizePixel = 0
	spine.BackgroundColor3 = C.Gold
	spine.BackgroundTransparency = 0.5
	spine.AnchorPoint = Vector2.new(0.5, 0)
	spine.Position = UDim2.fromScale(0.5, 0)
	spine.Size = UDim2.new(0, 2, 1, 0)
	spine.Parent = book

	-- detail popover (inside the book)
	local detail = UiKit.surface(book, "Base", Theme.Radius.Medium)
	detail.AnchorPoint = Vector2.new(0.5, 0.5)
	detail.Position = UDim2.fromScale(0.5, 0.5)
	detail.Size = UDim2.fromOffset(360, 300)
	detail.ZIndex = 10
	detail.Visible = false
	UiKit.brackets(detail, C.Gold)
	local detailPreviewHolder = Instance.new("Frame")
	detailPreviewHolder.BackgroundTransparency = 1
	detailPreviewHolder.Size = UDim2.new(1, 0, 0, 190)
	detailPreviewHolder.Parent = detail
	local detailPreview = UiParts.preview(detailPreviewHolder)
	local detailName = UiKit.text(detail, { Text = "", Font = Theme.Font.DisplayBold, Size = Theme.TextSize.Title, Upper = true, AlignX = Enum.TextXAlignment.Center })
	detailName.Position = UDim2.fromOffset(0, 192)
	local detailMeta = UiKit.text(detail, { Text = "", Size = Theme.TextSize.Caption, Font = Theme.Font.BodyBold, AlignX = Enum.TextXAlignment.Center })
	detailMeta.Position = UDim2.fromOffset(0, 222)
	local detailBlurb = UiKit.text(detail, { Text = "", Size = Theme.TextSize.Caption, Color = C.TextMuted, AlignX = Enum.TextXAlignment.Center })
	detailBlurb.Position = UDim2.fromOffset(Theme.Space.L, 244)
	detailBlurb.Size = UDim2.new(1, -Theme.Space.L * 2, 0, 44)
	detailBlurb.TextWrapped = true
	local detailClose = Instance.new("TextButton")
	detailClose.BackgroundTransparency = 1
	detailClose.Text = ""
	detailClose.Size = UDim2.fromScale(1, 1)
	detailClose.ZIndex = 11
	detailClose.Parent = detail
	detailClose.Activated:Connect(function()
		detail.Visible = false
	end)

	-- page turn arrows
	local prevBtn = UiKit.button(body, { Text = "<", Variant = "Ghost", Width = Theme.TouchTarget, OnActivated = function()
		spread -= 1
		if refresh then
			refresh()
		end
	end })
	local nextBtn = UiKit.button(body, { Text = ">", Variant = "Ghost", Width = Theme.TouchTarget, OnActivated = function()
		spread += 1
		if refresh then
			refresh()
		end
	end })
	local pageLabel = UiKit.text(body, { Text = "", Size = Theme.TextSize.Caption, Color = C.TextMuted, AlignX = Enum.TextXAlignment.Center })

	-- milestone track
	local track = UiKit.surface(body, "Base", Theme.Radius.Medium)
	track.AnchorPoint = Vector2.new(0, 1)
	track.Position = UDim2.fromScale(0, 1)
	track.Size = UDim2.new(1, 0, 0, 64)
	local trackBarHolder = Instance.new("Frame")
	trackBarHolder.BackgroundTransparency = 1
	trackBarHolder.AnchorPoint = Vector2.new(0, 0.5)
	trackBarHolder.Position = UDim2.new(0, Theme.Space.L, 0.5, 0)
	trackBarHolder.Size = UDim2.new(1, -Theme.Space.L * 2, 0, 6)
	trackBarHolder.Parent = track
	local trackBar = UiParts.progress(trackBarHolder, C.Gold, 6)
	local trackNodes = Instance.new("Frame")
	trackNodes.BackgroundTransparency = 1
	trackNodes.Size = UDim2.fromScale(1, 1)
	trackNodes.Parent = trackBarHolder

	local function entryTile(parent: Frame, e: Entry, order: number)
		local color = UiParts.rarityColor(e.Rarity)
		local tile = Instance.new("TextButton")
		tile.LayoutOrder = order
		tile.Text = ""
		tile.BackgroundColor3 = C.Base
		tile.BackgroundTransparency = Theme.Transparency.Card
		tile.BorderSizePixel = 0
		tile.Parent = parent
		UiKit.corner(tile, Theme.Radius.Small)
		UiKit.stroke(tile, if e.Discovered then color else C.Stroke)
		UiKit.interactive(tile)
		if e.Discovered then
			if e.Portrait and e.Portrait ~= "" then
				local img = Instance.new("ImageLabel")
				img.BackgroundTransparency = 1
				img.Size = UDim2.new(1, 0, 1, -22)
				img.Image = e.Portrait
				img.ScaleType = Enum.ScaleType.Crop
				img.Parent = tile
			else
				local mono = UiKit.text(tile, { Text = string.sub(e.Name, 1, 2), Font = Theme.Font.DisplayBold, Size = Theme.TextSize.Headline, Color = color, AlignX = Enum.TextXAlignment.Center, Upper = true })
				mono.Position = UDim2.fromScale(0, 0.18)
			end
			local name = UiKit.text(tile, { Text = e.Name, Size = Theme.TextSize.Caption, Font = Theme.Font.BodyBold, AlignX = Enum.TextXAlignment.Center })
			name.AnchorPoint = Vector2.new(0, 1)
			name.Position = UDim2.new(0, 0, 1, -2)
		else
			-- silhouette: dark plate + rarity-tinted question mark, so rarity is a hint, not a spoiler
			local q = UiKit.text(tile, { Text = "?", Font = Theme.Font.DisplayBold, Size = Theme.TextSize.Hero, Color = color, AlignX = Enum.TextXAlignment.Center })
			q.Position = UDim2.fromScale(0, 0.12)
			q.TextTransparency = 0.6
			local name = UiKit.text(tile, { Text = "Undiscovered", Size = Theme.TextSize.Caption, Color = C.TextFaint, AlignX = Enum.TextXAlignment.Center })
			name.AnchorPoint = Vector2.new(0, 1)
			name.Position = UDim2.new(0, 0, 1, -2)
		end
		tile.Activated:Connect(function()
			if not e.Discovered then
				UiKit.toast("Summon this unit to fill the page", "Info")
				return
			end
			detailPreview.show(if b.getUnitModel then b.getUnitModel(e.UnitId) else nil, e.Name, e.Rarity)
			detailName.Text = string.upper(e.Name)
			detailName.TextColor3 = color
			detailMeta.Text = e.Rarity .. (if e.FirstAt then "  ·  first met " .. os.date("%d %b %Y", e.FirstAt) else "")
			detailMeta.TextColor3 = color
			detailBlurb.Text = e.Blurb or ""
			detail.Visible = true
		end)
	end

	local function clearPage(p: Frame)
		for _, child in p:GetChildren() do
			if child:IsA("GuiButton") then
				child:Destroy()
			end
		end
	end

	local function renderTabs()
		for _, child in tabs:GetChildren() do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		for i, g in groups do
			local on = g == group
			local tab = Instance.new("TextButton")
			tab.LayoutOrder = i
			tab.AutomaticSize = Enum.AutomaticSize.X
			tab.Size = UDim2.fromOffset(0, 36)
			tab.BackgroundColor3 = if on then C.Raised else C.Base
			tab.BackgroundTransparency = if on then 0.1 else 0.5
			tab.BorderSizePixel = 0
			tab.FontFace = Theme.Font.Display
			tab.TextSize = Theme.TextSize.Label
			tab.TextColor3 = if on then C.Gold else C.TextMuted
			tab.Text = "  " .. string.upper(g) .. "  "
			tab.Parent = tabs
			UiKit.corner(tab, Theme.Radius.Small)
			tab.Activated:Connect(function()
				group = g
				spread = 1
				if refresh then
					refresh()
				end
			end)
		end
	end

	local function renderMilestones(discovered: number, total: number)
		for _, child in trackNodes:GetChildren() do
			child:Destroy()
		end
		local list = if b.getMilestones then b.getMilestones() else {}
		if #list == 0 then
			trackBar.set(if total > 0 then discovered / total else 0)
			return
		end
		local maxNeed = list[#list].Need
		trackBar.set(discovered / math.max(1, maxNeed))
		for _, m in list do
			local x = m.Need / math.max(1, maxNeed)
			local reached = discovered >= m.Need
			local node = Instance.new("TextButton")
			node.AnchorPoint = Vector2.new(0.5, 0.5)
			node.Position = UDim2.fromScale(x, 0.5)
			node.Size = UDim2.fromOffset(Theme.TouchTarget - 8, Theme.TouchTarget - 8)
			node.BackgroundColor3 = if m.Claimed then C.Raised elseif reached then C.Gold else C.Base
			node.BorderSizePixel = 0
			node.FontFace = Theme.Font.BodyBold
			node.TextSize = Theme.TextSize.Caption
			node.TextColor3 = if reached and not m.Claimed then C.TextOnAccent else C.TextMuted
			node.Text = if m.Claimed then "OK" else tostring(m.Need)
			node.Parent = trackNodes
			UiKit.corner(node, Theme.Radius.Small)
			UiKit.stroke(node, C.Gold)
			node.Activated:Connect(function()
				if m.Claimed then
					UiKit.toast(m.Reward .. " already claimed", "Info")
				elseif not reached then
					UiKit.toast(string.format("Discover %d units: %s", m.Need, m.Reward), "Info")
				elseif b.claimMilestone then
					local ok, err = b.claimMilestone(m.Id)
					UiKit.toast(if ok then "Claimed " .. m.Reward else (err or "Could not claim"), if ok then "Success" else "Error")
					if refresh then
						refresh()
					end
				end
			end)
		end
	end

	refresh = function()
		entries = b.getEntries()
		table.clear(groups)
		local seen: { [string]: boolean } = {}
		local discovered = 0
		for _, e in entries do
			if not seen[e.Group] then
				seen[e.Group] = true
				table.insert(groups, e.Group)
			end
			if e.Discovered then
				discovered += 1
			end
		end
		if not group or not seen[group] then
			group = groups[1]
		end
		completion.Text = string.format("%d / %d  ·  %d%%", discovered, #entries, if #entries > 0 then math.floor(discovered / #entries * 100) else 0)
		renderTabs()

		local inGroup: { Entry } = {}
		for _, e in entries do
			if e.Group == group then
				table.insert(inGroup, e)
			end
		end
		local perSpread = if compact then PER_PAGE else PER_PAGE * 2
		local spreads = math.max(1, math.ceil(#inGroup / perSpread))
		spread = math.clamp(spread, 1, spreads)
		clearPage(left)
		clearPage(right)
		local first = (spread - 1) * perSpread
		for i = 1, perSpread do
			local e = inGroup[first + i]
			if e then
				entryTile(if i <= PER_PAGE then left else right, e, i)
			end
		end
		pageLabel.Text = string.format("%d / %d", spread, spreads)
		prevBtn.setEnabled(spread > 1, "First page")
		nextBtn.setEnabled(spread < spreads, "Last page")
		renderMilestones(discovered, #entries)
	end

	UiKit.onLayoutChanged(function(layout)
		compact = layout == "Compact"
		left.Size = if compact then UDim2.fromScale(1, 1) else UDim2.new(0.5, -Theme.Space.M, 1, 0)
		right.Visible = not compact
		right.Position = UDim2.new(0.5, Theme.Space.M, 0, 0)
		right.Size = UDim2.new(0.5, -Theme.Space.M, 1, 0)
		spine.Visible = not compact
		prevBtn.Instance.Position = UDim2.new(0, 0, 1, -64 - Theme.Space.S - Theme.Size.ButtonHeight)
		nextBtn.Instance.AnchorPoint = Vector2.new(1, 0)
		nextBtn.Instance.Position = UDim2.new(1, 0, 1, -64 - Theme.Space.S - Theme.Size.ButtonHeight)
		pageLabel.AnchorPoint = Vector2.new(0.5, 0)
		pageLabel.Position = UDim2.new(0.5, 0, 1, -64 - Theme.Space.S - Theme.Size.ButtonHeight + 10)
		pageLabel.Size = UDim2.fromOffset(120, 20)
		if refresh then
			refresh()
		end
	end)
	book.Size = UDim2.new(1, 0, 1, -44 - 64 - Theme.Size.ButtonHeight - Theme.Space.S * 2)
	return w
end

function CollectionBookScreen.init(b: Backend)
	backend = b
end

function CollectionBookScreen.open()
	local b = backend
	if not b then
		UiKit.toast("Collection Book is not connected yet", "Warning")
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

return CollectionBookScreen
