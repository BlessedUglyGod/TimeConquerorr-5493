--!strict
-- UiKit: shared building blocks of the Meridian UI system. Install as ModuleScript ReplicatedStorage.TD.UI.UiKit
-- (client only: it touches PlayerGui). Spec: docs/ui/UI_DESIGN_SYSTEM.md.
--
-- UiKit gives every screen the same type, colour, spacing, motion and input behaviour. It does NOT give
-- screens their layout: each system (Summon, Trait Reroll, Collection, Lobby, ...) composes these parts
-- into its own layout described in docs/ui/SCREENS.md. A screen that is only `UiKit.window` + a list of
-- buttons is a placeholder, not a finished screen.

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent:WaitForChild("Theme"))
local Icons = require(script.Parent:WaitForChild("Icons"))

local C = Theme.Color
local UiKit = {}

-- Layout / scale --------------------------------------------------------------------------------------

export type LayoutClass = "Compact" | "Regular"

local scaleObjects: { UIScale } = {}
local layoutListeners: { (LayoutClass) -> () } = {}
local currentScale = 1
local currentLayout: LayoutClass = "Regular"

local function viewport(): Vector2
	local cam = workspace.CurrentCamera
	return if cam then cam.ViewportSize else Theme.Responsive.Reference
end

local function recompute()
	local size = viewport()
	local ref = Theme.Responsive.Reference
	local r = Theme.Responsive
	currentScale = math.clamp(math.min(size.X / ref.X, size.Y / ref.Y), r.MinScale, r.MaxScale)
	local shortSide = math.min(size.X, size.Y)
	local touchOnly = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local layout: LayoutClass = if shortSide < r.CompactShortSide or touchOnly then "Compact" else "Regular"
	for _, s in scaleObjects do
		s.Scale = currentScale
	end
	if layout ~= currentLayout then
		currentLayout = layout
		for _, cb in layoutListeners do
			task.spawn(cb, layout)
		end
	end
end

local watching = false
local function watchViewport()
	if watching then
		return
	end
	watching = true
	local function hook(cam: Camera?)
		if cam then
			cam:GetPropertyChangedSignal("ViewportSize"):Connect(recompute)
		end
	end
	hook(workspace.CurrentCamera)
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		hook(workspace.CurrentCamera)
		recompute()
	end)
	UserInputService.LastInputTypeChanged:Connect(recompute)
	recompute()
end

function UiKit.layout(): LayoutClass
	watchViewport()
	return currentLayout
end

function UiKit.scale(): number
	watchViewport()
	return currentScale
end

-- Called now and on every Compact <-> Regular change.
function UiKit.onLayoutChanged(callback: (LayoutClass) -> ())
	watchViewport()
	table.insert(layoutListeners, callback)
	task.spawn(callback, currentLayout)
end

-- A ScreenGui on its own layer with the shared UIScale and safe-area insets.
function UiKit.screen(name: string, layer: number): ScreenGui
	watchViewport()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local old = playerGui:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.DisplayOrder = layer
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	local s = Instance.new("UIScale")
	s.Scale = currentScale
	s.Parent = gui
	table.insert(scaleObjects, s)
	gui.Parent = playerGui
	return gui
end

-- Primitives ------------------------------------------------------------------------------------------

function UiKit.corner(parent: GuiObject, radius: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or Theme.Radius.Medium)
	c.Parent = parent
end

function UiKit.stroke(parent: GuiObject, color: Color3?, thickness: number?): UIStroke
	local s = Instance.new("UIStroke")
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Color = color or C.Stroke
	s.Thickness = thickness or Theme.Stroke.Hairline
	s.Parent = parent
	return s
end

function UiKit.padding(parent: GuiObject, px: number)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, px)
	p.PaddingBottom = UDim.new(0, px)
	p.PaddingLeft = UDim.new(0, px)
	p.PaddingRight = UDim.new(0, px)
	p.Parent = parent
end

function UiKit.list(parent: GuiObject, direction: Enum.FillDirection, gap: number, align: Enum.HorizontalAlignment?): UIListLayout
	local l = Instance.new("UIListLayout")
	l.FillDirection = direction
	l.Padding = UDim.new(0, gap)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.HorizontalAlignment = align or Enum.HorizontalAlignment.Left
	l.VerticalAlignment = Enum.VerticalAlignment.Center
	l.Parent = parent
	return l
end

export type TextProps = {
	Text: string,
	Size: number?, -- Theme.TextSize value
	Font: Font?,
	Color: Color3?,
	AlignX: Enum.TextXAlignment?,
	Upper: boolean?, -- display face is set in uppercase
}

function UiKit.text(parent: Instance, props: TextProps): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.FontFace = props.Font or Theme.Font.Body
	l.TextSize = props.Size or Theme.TextSize.Body
	l.TextColor3 = props.Color or C.Text
	l.TextXAlignment = props.AlignX or Enum.TextXAlignment.Left
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.Text = if props.Upper then string.upper(props.Text) else props.Text
	l.Size = UDim2.new(1, 0, 0, l.TextSize + 6)
	l.Parent = parent
	return l
end

-- Solid surface. `level` picks the value step (Base / Raised / Overlay).
function UiKit.surface(parent: Instance, level: "Base" | "Raised" | "Overlay", radius: number?): Frame
	local f = Instance.new("Frame")
	f.BackgroundColor3 = if level == "Base" then C.Base elseif level == "Raised" then C.Raised else C.Overlay
	f.BackgroundTransparency = if level == "Base" then Theme.Transparency.Panel elseif level == "Raised" then Theme.Transparency.Card else 0
	f.BorderSizePixel = 0
	f.Parent = parent
	UiKit.corner(f, radius)
	UiKit.stroke(f)
	return f
end

-- Corner brackets: short L-shaped strokes on two opposite corners. The system's "layered, cut-corner"
-- detail, done with frames because Roblox has no angled corners. Used on windows and selected cards only.
function UiKit.brackets(parent: GuiObject, color: Color3, length: number?)
	local len = length or Theme.Size.Bracket
	local t = Theme.Stroke.Focus
	-- drawn just inside the edge so CanvasGroup windows do not clip them
	for _, corner in { Vector2.new(0, 0), Vector2.new(1, 1) } do
		for _, horizontal in { true, false } do
			local f = Instance.new("Frame")
			f.Name = "Bracket"
			f.BorderSizePixel = 0
			f.BackgroundColor3 = color
			f.AnchorPoint = corner
			f.Position = UDim2.fromScale(corner.X, corner.Y)
			f.Size = if horizontal then UDim2.fromOffset(len, t) else UDim2.fromOffset(t, len)
			f.ZIndex = 5
			f.Parent = parent
		end
	end
end

-- Icon: uploaded image when available, otherwise the glyph tile.
function UiKit.icon(parent: Instance, id: string, size: number, tint: Color3?): GuiObject
	local def = Icons.get(id)
	local color = tint or def.Tint or C.Text
	if def.Asset ~= "" then
		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.Size = UDim2.fromOffset(size, size)
		img.Image = def.Asset
		img.ImageColor3 = color
		img.ScaleType = Enum.ScaleType.Fit
		img.Parent = parent
		return img
	end
	local tile = Instance.new("TextLabel")
	tile.Size = UDim2.fromOffset(size, size)
	tile.BackgroundColor3 = color
	tile.BackgroundTransparency = 0.82
	tile.BorderSizePixel = 0
	tile.FontFace = Theme.Font.DisplayBold
	tile.TextSize = math.floor(size * 0.46)
	tile.TextColor3 = color
	tile.Text = def.Glyph
	tile.Parent = parent
	UiKit.corner(tile, Theme.Radius.Small)
	return tile
end

-- Motion ----------------------------------------------------------------------------------------------

function UiKit.tween(object: Instance, info: TweenInfo, goal: { [string]: any }): Tween
	local t = TweenService:Create(object, info, goal)
	t:Play()
	return t
end

-- Press feedback shared by every clickable thing: hover lift (mouse only), press scale.
function UiKit.interactive(button: GuiButton, hoverColor: Color3?, baseColor: Color3?)
	button.AutoButtonColor = false
	local s = Instance.new("UIScale")
	s.Parent = button
	local base = baseColor or button.BackgroundColor3
	button.MouseEnter:Connect(function()
		if hoverColor and button.Active then
			UiKit.tween(button, Theme.Motion.Fast, { BackgroundColor3 = hoverColor })
		end
	end)
	button.MouseLeave:Connect(function()
		if hoverColor then
			UiKit.tween(button, Theme.Motion.Fast, { BackgroundColor3 = base })
		end
		UiKit.tween(s, Theme.Motion.Fast, { Scale = 1 })
	end)
	button.InputBegan:Connect(function(input)
		local t = input.UserInputType
		if button.Active and (t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch) then
			UiKit.tween(s, Theme.Motion.Fast, { Scale = Theme.Motion.PressScale })
		end
	end)
	button.InputEnded:Connect(function()
		UiKit.tween(s, Theme.Motion.Fast, { Scale = 1 })
	end)
end

-- Buttons ---------------------------------------------------------------------------------------------

export type ButtonVariant = "Primary" | "Secondary" | "Ghost" | "Danger"

export type ButtonProps = {
	Text: string,
	Variant: ButtonVariant?,
	Icon: string?,
	Width: number?, -- px; nil = fill parent width
	OnActivated: () -> (),
}

export type Button = {
	Instance: TextButton,
	setEnabled: (enabled: boolean, reason: string?) -> (),
	setText: (text: string) -> (),
}

local VARIANT = {
	Primary = { Fill = C.Accent, Hover = C.AccentHover, Text = C.TextOnAccent, Stroke = C.StrokeStrong },
	Secondary = { Fill = C.Raised, Hover = C.Overlay, Text = C.Text, Stroke = C.StrokeStrong },
	Ghost = { Fill = C.Base, Hover = C.Raised, Text = C.TextMuted, Stroke = nil },
	Danger = { Fill = Color3.fromRGB(70, 30, 40), Hover = Color3.fromRGB(96, 38, 50), Text = C.Danger, Stroke = C.Danger },
}

function UiKit.button(parent: Instance, props: ButtonProps): Button
	local v = VARIANT[props.Variant or "Secondary"]
	local b = Instance.new("TextButton")
	b.Size = if props.Width then UDim2.fromOffset(props.Width, Theme.Size.ButtonHeight) else UDim2.new(1, 0, 0, Theme.Size.ButtonHeight)
	b.BackgroundColor3 = v.Fill
	b.BorderSizePixel = 0
	b.FontFace = Theme.Font.Display
	b.TextSize = Theme.TextSize.Label
	b.TextColor3 = v.Text
	b.Text = string.upper(props.Text)
	b.Parent = parent
	UiKit.corner(b, Theme.Radius.Medium)
	if v.Stroke then
		UiKit.stroke(b, v.Stroke)
	end
	UiKit.interactive(b, v.Hover, v.Fill)
	local reasonText: string? = nil
	b.Activated:Connect(function()
		if b.Active then
			props.OnActivated()
		elseif reasonText then
			UiKit.toast(reasonText, "Info")
		end
	end)
	local api: Button = {
		Instance = b,
		setEnabled = function(enabled: boolean, reason: string?)
			b.Active = enabled
			reasonText = if enabled then nil else reason
			b.BackgroundColor3 = if enabled then v.Fill else C.Raised
			b.TextColor3 = if enabled then v.Text else C.TextFaint
		end,
		setText = function(text: string)
			b.Text = string.upper(text)
		end,
	}
	return api
end

-- Currency chip: icon + number, bound by the caller.
export type Chip = { Instance: Frame, setValue: (value: number) -> () }

local function formatNumber(n: number): string
	if n >= 1e6 then
		return string.format("%.1fM", n / 1e6)
	elseif n >= 1e4 then
		return string.format("%.1fK", n / 1e3)
	end
	local s = tostring(math.floor(n))
	-- thousands separator for 1,000..9,999
	return (s:reverse():gsub("(%d%d%d)(%d)", "%1,%2")):reverse()
end
UiKit.formatNumber = formatNumber

function UiKit.chip(parent: Instance, iconId: string, color: Color3): Chip
	local f = UiKit.surface(parent, "Base", Theme.Radius.Small)
	f.Size = UDim2.fromOffset(120, Theme.Size.ChipHeight)
	f.AutomaticSize = Enum.AutomaticSize.X
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, Theme.Space.XS)
	pad.PaddingRight = UDim.new(0, Theme.Space.M)
	pad.Parent = f
	UiKit.list(f, Enum.FillDirection.Horizontal, Theme.Space.S)
	UiKit.icon(f, iconId, 24, color)
	local value = UiKit.text(f, { Text = "0", Font = Theme.Font.BodyBold, Size = Theme.TextSize.Body })
	value.AutomaticSize = Enum.AutomaticSize.X
	value.Size = UDim2.fromOffset(0, Theme.Size.ChipHeight)
	value.TextTruncate = Enum.TextTruncate.None
	local shown = 0
	return {
		Instance = f,
		setValue = function(n: number)
			value.Text = formatNumber(n)
			if n > shown then -- gain: brief accent pulse, no bounce on loss
				value.TextColor3 = color
				UiKit.tween(value, Theme.Motion.Enter, { TextColor3 = C.Text })
			end
			shown = n
		end,
	}
end

-- Progress bar (pity, quest, pass, XP). Ratio 0..1.
export type Progress = { Instance: Frame, set: (ratio: number) -> () }

function UiKit.progress(parent: Instance, color: Color3, height: number?): Progress
	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, 0, 0, height or 6)
	track.BackgroundColor3 = C.Overlay
	track.BorderSizePixel = 0
	track.Parent = parent
	UiKit.corner(track, 3)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = track
	UiKit.corner(fill, 3)
	return {
		Instance = track,
		set = function(ratio: number)
			UiKit.tween(fill, Theme.Motion.Enter, { Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1) })
		end,
	}
end

-- Toasts ----------------------------------------------------------------------------------------------
-- Replaces StarterGui:SetCore("SendNotification"): same look as the rest of the UI, max 3 on screen.

local toastGui: ScreenGui? = nil
local toastStack: Frame? = nil
local liveToasts: { CanvasGroup } = {}
local toastCounter = 0
local TOAST_COLOR = { Info = C.Interactive, Success = C.Positive, Warning = C.Warning, Error = C.Danger }

function UiKit.toast(text: string, kind: ("Info" | "Success" | "Warning" | "Error")?)
	if not toastGui or not toastGui.Parent then
		toastGui = UiKit.screen("TDToasts", Theme.Layer.Toast)
		local stack = Instance.new("Frame")
		stack.Name = "Stack"
		stack.BackgroundTransparency = 1
		stack.AnchorPoint = Vector2.new(0.5, 0)
		stack.Position = UDim2.new(0.5, 0, 0, 72)
		stack.Size = UDim2.fromOffset(420, 200)
		stack.Parent = toastGui
		UiKit.list(stack, Enum.FillDirection.Vertical, Theme.Space.S, Enum.HorizontalAlignment.Center).VerticalAlignment = Enum.VerticalAlignment.Top
		toastStack = stack
	end
	local stack = toastStack :: Frame
	if #liveToasts >= 3 then
		local oldest = table.remove(liveToasts, 1)
		if oldest then
			oldest:Destroy()
		end
	end
	toastCounter += 1
	local g = Instance.new("CanvasGroup")
	g.Size = UDim2.fromOffset(420, 44)
	g.BackgroundColor3 = C.Base
	g.BackgroundTransparency = 0.08 -- toasts sit over anything, so nearly opaque
	g.BorderSizePixel = 0
	g.GroupTransparency = 1
	g.LayoutOrder = toastCounter
	table.insert(liveToasts, g)
	g.Parent = stack
	UiKit.corner(g, Theme.Radius.Medium)
	UiKit.stroke(g)
	local bar = Instance.new("Frame") -- left status rule
	bar.Size = UDim2.new(0, 3, 1, 0)
	bar.BackgroundColor3 = TOAST_COLOR[kind or "Info"]
	bar.BorderSizePixel = 0
	bar.Parent = g
	local t = UiKit.text(g, { Text = text, Font = Theme.Font.BodyMedium })
	t.Position = UDim2.fromOffset(Theme.Space.L, 0)
	t.Size = UDim2.new(1, -Theme.Space.L * 2, 1, 0)
	UiKit.tween(g, Theme.Motion.Enter, { GroupTransparency = 0 })
	task.delay(3, function()
		if g.Parent then
			UiKit.tween(g, Theme.Motion.Exit, { GroupTransparency = 1 }).Completed:Wait()
			g:Destroy()
		end
		local i = table.find(liveToasts, g)
		if i then
			table.remove(liveToasts, i)
		end
	end)
end

-- Windows ---------------------------------------------------------------------------------------------
-- One window open at a time (opening another closes the current one). Esc / gamepad B closes.
-- `window` gives only the frame: title bar with accent rule, close button, body. The body layout is the
-- screen's own (see docs/ui/SCREENS.md).

export type WindowProps = {
	Name: string,
	Title: string,
	Accent: Color3?, -- rule colour under the title; system/district accent, default violet
	Size: Vector2?, -- px at scale 1, clamped to Theme.Size.WindowMin/Max; Compact layout = full screen
	OnClose: (() -> ())?,
}

export type Window = {
	Gui: ScreenGui,
	Root: CanvasGroup,
	Body: Frame,
	TitleLabel: TextLabel,
	open: () -> (),
	close: () -> (),
	isOpen: () -> boolean,
}

local openWindow: Window? = nil

function UiKit.closeAll()
	if openWindow then
		openWindow.close()
	end
end

function UiKit.window(props: WindowProps): Window
	local gui = UiKit.screen(props.Name, Theme.Layer.Window)
	gui.Enabled = false
	local scrim = Instance.new("TextButton") -- dims the world for readability; clicking it closes
	scrim.Name = "Scrim"
	scrim.Text = ""
	scrim.AutoButtonColor = false
	scrim.BackgroundColor3 = C.Scrim
	scrim.BackgroundTransparency = Theme.Transparency.Scrim
	scrim.BorderSizePixel = 0
	scrim.Size = UDim2.fromScale(1, 1)
	scrim.Parent = gui
	local wanted = props.Size or Vector2.new(720, 480)
	local size = Vector2.new(
		math.clamp(wanted.X, Theme.Size.WindowMin.X, Theme.Size.WindowMax.X),
		math.clamp(wanted.Y, Theme.Size.WindowMin.Y, Theme.Size.WindowMax.Y)
	)

	local root = Instance.new("CanvasGroup")
	root.Name = "Window"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.BackgroundColor3 = C.Base
	root.BackgroundTransparency = Theme.Transparency.Panel
	root.BorderSizePixel = 0
	root.Parent = gui
	UiKit.corner(root, Theme.Radius.Large)
	UiKit.stroke(root)
	UiKit.brackets(root, C.StrokeStrong)

	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.BackgroundTransparency = 1
	titleBar.Size = UDim2.new(1, 0, 0, Theme.Size.TitleBar)
	titleBar.Parent = root
	local title = UiKit.text(titleBar, { Text = props.Title, Font = Theme.Font.Display, Size = Theme.TextSize.Title, Upper = true })
	title.Position = UDim2.fromOffset(Theme.Space.XL, 0)
	title.Size = UDim2.new(1, -Theme.Space.XL * 2 - 44, 1, 0)
	local rule = Instance.new("Frame")
	rule.Name = "AccentRule"
	rule.BorderSizePixel = 0
	rule.BackgroundColor3 = props.Accent or C.Accent
	rule.Position = UDim2.new(0, Theme.Space.XL, 1, -Theme.Size.AccentRule)
	rule.Size = UDim2.fromOffset(56, Theme.Size.AccentRule) -- short rule, not a full-width bar
	rule.Parent = titleBar

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "Close"
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.Position = UDim2.new(1, -Theme.Space.S, 0.5, 0)
	closeBtn.Size = UDim2.fromOffset(Theme.TouchTarget, Theme.TouchTarget)
	closeBtn.BackgroundColor3 = C.Base
	closeBtn.BorderSizePixel = 0
	closeBtn.FontFace = Theme.Font.BodyBold
	closeBtn.TextSize = 20
	closeBtn.TextColor3 = C.TextMuted
	closeBtn.Text = "X"
	closeBtn.Parent = titleBar
	UiKit.corner(closeBtn, Theme.Radius.Medium)
	UiKit.interactive(closeBtn, C.Raised, C.Base)

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.BackgroundTransparency = 1
	body.Position = UDim2.fromOffset(0, Theme.Size.TitleBar)
	body.Size = UDim2.new(1, 0, 1, -Theme.Size.TitleBar)
	body.Parent = root
	UiKit.padding(body, Theme.Space.XL)

	local function applyLayout(layout: LayoutClass)
		if layout == "Compact" then
			root.Size = UDim2.new(1, -Theme.Space.L * 2, 1, -Theme.Space.L * 2)
		else
			root.Size = UDim2.fromOffset(size.X, size.Y)
		end
	end
	UiKit.onLayoutChanged(applyLayout)

	local isOpen = false
	local win: Window
	local function close()
		if not isOpen then
			return
		end
		isOpen = false
		if openWindow == win then
			openWindow = nil
		end
		local t = UiKit.tween(root, Theme.Motion.Exit, { GroupTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, Theme.Motion.EnterOffset) })
		t.Completed:Once(function()
			if not isOpen then
				gui.Enabled = false
			end
		end)
		if props.OnClose then
			task.spawn(props.OnClose)
		end
	end
	local function open()
		if isOpen then
			return
		end
		if openWindow and openWindow ~= win then
			openWindow.close()
		end
		isOpen = true
		openWindow = win
		gui.Enabled = true
		root.GroupTransparency = 1
		root.Position = UDim2.new(0.5, 0, 0.5, Theme.Motion.EnterOffset)
		UiKit.tween(root, Theme.Motion.Enter, { GroupTransparency = 0, Position = UDim2.fromScale(0.5, 0.5) })
	end
	closeBtn.Activated:Connect(close)
	scrim.Activated:Connect(close)
	win = { Gui = gui, Root = root, Body = body, TitleLabel = title, open = open, close = close, isOpen = function()
		return isOpen
	end }
	return win
end

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
		if openWindow and not GuiService.MenuIsOpen then
			openWindow.close()
		end
	end
end)

return UiKit
