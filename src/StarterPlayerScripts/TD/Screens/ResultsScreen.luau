--!strict
-- ResultsScreen: end of match (spec: docs/ui/SCREENS.md, "Results"). Shown in UiState "Results" over the
-- combat scene. Install as ModuleScript StarterPlayer.StarterPlayerScripts.TD.Screens.ResultsScreen.
--
-- Not a window: a banner across the top third (VICTORY / DEFEAT in Hero type with its status rule),
-- rewards flipping in one by one in the middle, the party's damage bars on the right, and the two real
-- actions (Replay, Return to Hub) at the bottom. Data comes from the server's match-end message.
--   ResultsScreen.show(data, { onReplay = ..., onReturn = ... })
--   ResultsScreen.hide()

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = ReplicatedStorage:WaitForChild("TD"):WaitForChild("UI")
local Theme = require(UI:WaitForChild("Theme"))
local UiKit = require(UI:WaitForChild("UiKit"))
local UiParts = require(UI:WaitForChild("UiParts"))

local C = Theme.Color

export type Reward = { Icon: string, Label: string, Amount: number?, Rarity: string? }
export type PlayerLine = { Name: string, Damage: number, IsLocal: boolean? }
export type ResultData = {
	Won: boolean,
	Title: string?, -- e.g. "Prologue · Stage 1 · Normal"
	Stars: number?, -- 0..3, nil = mode without stars
	Waves: string?, -- e.g. "Wave 10 / 10" or "Wave 37" (Infinite)
	Rewards: { Reward },
	Players: { PlayerLine }?,
	CanReplay: boolean?,
	AutoReturnIn: number?, -- seconds until the server sends everyone back, shown as a countdown
}
export type Actions = { onReplay: (() -> ())?, onReturn: () -> () }

local ResultsScreen = {}

local gui: ScreenGui? = nil
local token = 0

function ResultsScreen.hide()
	token += 1
	if gui then
		gui:Destroy()
		gui = nil
	end
end

function ResultsScreen.show(data: ResultData, actions: Actions)
	ResultsScreen.hide()
	local my = token
	local screen = UiKit.screen("TDResults", Theme.Layer.Modal)
	gui = screen
	local statusColor = if data.Won then C.Positive else C.Danger

	local scrim = Instance.new("Frame")
	scrim.BorderSizePixel = 0
	scrim.BackgroundColor3 = C.Scrim
	scrim.BackgroundTransparency = 1
	scrim.Size = UDim2.fromScale(1, 1)
	scrim.Parent = screen
	UiKit.tween(scrim, Theme.Motion.Enter, { BackgroundTransparency = Theme.Transparency.Scrim })

	-- banner
	local banner = Instance.new("Frame")
	banner.BackgroundTransparency = 1
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Position = UDim2.new(0.5, 0, 0.08, 0)
	banner.Size = UDim2.new(0.8, 0, 0, 120)
	banner.Parent = screen
	local headline = UiKit.text(banner, { Text = if data.Won then "Victory" else "Defeat", Font = Theme.Font.DisplayBold, Size = 64, Upper = true,
		Color = C.Text, AlignX = Enum.TextXAlignment.Center })
	headline.Size = UDim2.new(1, 0, 0, 70)
	local hs = Instance.new("UIScale")
	hs.Scale = 1.25
	hs.Parent = headline
	headline.TextTransparency = 1
	UiKit.tween(headline, Theme.Motion.Enter, { TextTransparency = 0 })
	UiKit.tween(hs, Theme.Motion.Emphasis, { Scale = 1 })
	local rule = Instance.new("Frame")
	rule.BorderSizePixel = 0
	rule.BackgroundColor3 = statusColor
	rule.AnchorPoint = Vector2.new(0.5, 0)
	rule.Position = UDim2.new(0.5, 0, 0, 74)
	rule.Size = UDim2.fromOffset(0, 3)
	rule.Parent = banner
	UiKit.tween(rule, Theme.Motion.Enter, { Size = UDim2.fromOffset(160, 3) })
	local sub = UiKit.text(banner, { Text = table.concat({ data.Title or "", data.Waves or "" }, if data.Title and data.Waves then "  ·  " else ""),
		Font = Theme.Font.Display, Size = Theme.TextSize.Label, Upper = true, Color = C.TextMuted, AlignX = Enum.TextXAlignment.Center })
	sub.Position = UDim2.fromOffset(0, 84)
	if data.Stars then
		local stars = UiKit.text(banner, { Text = string.rep("* ", data.Stars) .. string.rep("- ", 3 - data.Stars), Font = Theme.Font.DisplayBold,
			Size = Theme.TextSize.Title, Color = C.Gold, AlignX = Enum.TextXAlignment.Center })
		stars.Position = UDim2.fromOffset(0, 104)
	end

	-- rewards row
	local rewards = Instance.new("Frame")
	rewards.BackgroundTransparency = 1
	rewards.AnchorPoint = Vector2.new(0.5, 0.5)
	rewards.Position = UDim2.fromScale(0.42, 0.52)
	rewards.Size = UDim2.new(0.6, 0, 0, 120)
	rewards.Parent = screen
	UiKit.list(rewards, Enum.FillDirection.Horizontal, Theme.Space.M, Enum.HorizontalAlignment.Center)

	-- party damage (right)
	local party = data.Players
	if party and #party > 1 then
		local panel = UiKit.surface(screen, "Base", Theme.Radius.Medium)
		panel.AnchorPoint = Vector2.new(1, 0.5)
		panel.Position = UDim2.new(1, -Theme.Space.XL, 0.52, 0)
		panel.Size = UDim2.fromOffset(260, 40 + #party * 34)
		UiKit.padding(panel, Theme.Space.M)
		UiKit.list(panel, Enum.FillDirection.Vertical, Theme.Space.XS).VerticalAlignment = Enum.VerticalAlignment.Top
		local t = UiKit.text(panel, { Text = "Damage", Font = Theme.Font.Display, Size = Theme.TextSize.Label, Upper = true, Color = C.TextMuted })
		t.LayoutOrder = 0
		local top = 0
		for _, p in party do
			top = math.max(top, p.Damage)
		end
		table.sort(party, function(a, b)
			return a.Damage > b.Damage
		end)
		for i, p in party do
			local row = Instance.new("Frame")
			row.LayoutOrder = i
			row.BackgroundTransparency = 1
			row.Size = UDim2.new(1, 0, 0, 30)
			row.Parent = panel
			local n = UiKit.text(row, { Text = p.Name, Size = Theme.TextSize.Caption, Font = if p.IsLocal then Theme.Font.BodyBold else Theme.Font.Body,
				Color = if p.IsLocal then C.Text else C.TextMuted })
			n.Size = UDim2.new(0.6, 0, 0, 16)
			local d = UiKit.text(row, { Text = UiKit.formatNumber(p.Damage), Size = Theme.TextSize.Caption, Font = Theme.Font.BodyBold, AlignX = Enum.TextXAlignment.Right })
			d.Position = UDim2.fromScale(0.6, 0)
			d.Size = UDim2.new(0.4, 0, 0, 16)
			local barHolder = Instance.new("Frame")
			barHolder.BackgroundTransparency = 1
			barHolder.Position = UDim2.fromOffset(0, 20)
			barHolder.Size = UDim2.new(1, 0, 0, 4)
			barHolder.Parent = row
			UiParts.progress(barHolder, if p.IsLocal then C.Accent else C.StrokeStrong, 4).set(p.Damage / math.max(1, top))
		end
	end

	-- actions
	local bar = Instance.new("Frame")
	bar.BackgroundTransparency = 1
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -Theme.Space.XXL)
	bar.Size = UDim2.fromOffset(460, 76)
	bar.Parent = screen
	UiKit.list(bar, Enum.FillDirection.Horizontal, Theme.Space.M, Enum.HorizontalAlignment.Center).VerticalAlignment = Enum.VerticalAlignment.Top
	local replay = UiKit.button(bar, { Text = "Replay", Variant = "Secondary", Width = 200, OnActivated = function()
		if actions.onReplay then
			actions.onReplay()
		end
	end })
	replay.Instance.LayoutOrder = 1
	replay.setEnabled(data.CanReplay == true and actions.onReplay ~= nil, "Replay is not available for this mode")
	local back = UiKit.button(bar, { Text = "Return to Hub", Variant = "Primary", Width = 220, OnActivated = actions.onReturn })
	back.Instance.LayoutOrder = 2
	local countdown = UiKit.text(screen, { Text = "", Size = Theme.TextSize.Caption, Font = Theme.Font.Timer, Color = C.TextFaint, AlignX = Enum.TextXAlignment.Center })
	countdown.AnchorPoint = Vector2.new(0.5, 1)
	countdown.Position = UDim2.new(0.5, 0, 1, -Theme.Space.L)
	countdown.Size = UDim2.fromOffset(300, 16)

	UiKit.onLayoutChanged(function(layout)
		if my ~= token then
			return
		end
		local compact = layout == "Compact"
		rewards.Position = if compact then UDim2.fromScale(0.5, 0.5) else UDim2.fromScale(0.42, 0.52)
		rewards.Size = if compact then UDim2.new(0.95, 0, 0, 100) else UDim2.new(0.6, 0, 0, 120)
	end)

	-- rewards flip in after the banner lands
	task.spawn(function()
		task.wait(0.45)
		for i, r in data.Rewards do
			if my ~= token then
				return
			end
			local color = if r.Rarity then UiParts.rarityColor(r.Rarity) else C.Stroke
			local card = UiKit.surface(rewards, "Raised", Theme.Radius.Medium)
			card.LayoutOrder = i
			card.Size = UDim2.fromOffset(96, 112)
			local st = card:FindFirstChildOfClass("UIStroke")
			if st then
				st.Color = color
			end
			local icon = UiKit.icon(card, r.Icon, 40)
			icon.AnchorPoint = Vector2.new(0.5, 0)
			icon.Position = UDim2.new(0.5, 0, 0, Theme.Space.M)
			local amount = UiKit.text(card, { Text = if r.Amount then "x" .. UiKit.formatNumber(r.Amount) else "", Font = Theme.Font.BodyBold, AlignX = Enum.TextXAlignment.Center })
			amount.Position = UDim2.fromOffset(0, 60)
			local label = UiKit.text(card, { Text = r.Label, Size = 11, Color = if r.Rarity then color else C.TextMuted, AlignX = Enum.TextXAlignment.Center })
			label.Position = UDim2.fromOffset(0, 84)
			local s = Instance.new("UIScale")
			s.Scale = 0.5
			s.Parent = card
			UiKit.tween(s, Theme.Motion.Emphasis, { Scale = 1 })
			task.wait(0.15)
		end
		if #data.Rewards == 0 then
			local none = UiKit.text(rewards, { Text = if data.Won then "No rewards this time" else "No rewards on defeat", Color = C.TextMuted, AlignX = Enum.TextXAlignment.Center })
			none.Size = UDim2.fromScale(1, 1)
		end
	end)

	if data.AutoReturnIn and data.AutoReturnIn > 0 then
		task.spawn(function()
			local left = math.floor(data.AutoReturnIn :: number)
			while left > 0 and my == token do
				countdown.Text = string.format("Returning to hub in %ds", left)
				task.wait(1)
				left -= 1
			end
		end)
	end
end

return ResultsScreen
