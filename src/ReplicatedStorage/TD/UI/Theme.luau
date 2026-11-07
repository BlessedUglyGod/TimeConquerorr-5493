--!strict
-- Theme: design tokens of the "Meridian UI" system (hub + main menu). Spec: docs/ui/UI_DESIGN_SYSTEM.md.
-- Install as ModuleScript ReplicatedStorage.TD.UI.Theme. Pure data, no instances; safe on server and client.
--
-- Rule: UI code never writes a literal Color3, font, size or duration. It reads a token from here, so a
-- visual change is one edit. The combat HUD (TDHud) may adopt these tokens later but is not required to.

local Theme = {}

-- Colour --------------------------------------------------------------------------------------------
-- Direction (owner's reference, 2026-11-07): night-purple glass panels, violet/magenta accents, ivory text,
-- strong rarity colours. Panels are semi-transparent so the hub shows through, but every panel keeps a
-- dark enough fill + hairline stroke that text stays readable over any background. Depth comes from
-- layered translucent surfaces (Base -> Raised -> Overlay), strokes and corner brackets, not gradients.
Theme.Color = {
	-- surfaces (night purple). Pair with Theme.Transparency.* below.
	Base = Color3.fromRGB(22, 14, 38), -- window / dock glass
	Raised = Color3.fromRGB(38, 24, 64), -- cards inside a window
	Overlay = Color3.fromRGB(58, 38, 94), -- hover, selected rows, inputs
	Scrim = Color3.fromRGB(6, 4, 14), -- dims the world behind a window
	Stroke = Color3.fromRGB(92, 68, 140), -- 1 px hairlines
	StrokeStrong = Color3.fromRGB(168, 128, 240), -- focused / selected outlines, corner brackets

	-- text
	Text = Color3.fromRGB(246, 240, 255), -- ivory with a lilac lean, not pure white
	TextMuted = Color3.fromRGB(184, 172, 214),
	TextFaint = Color3.fromRGB(126, 114, 160),
	TextOnAccent = Color3.fromRGB(255, 255, 255),

	-- brand accent: violet, with magenta for emphasis (rare reveals, x10, "new" badges).
	Accent = Color3.fromRGB(150, 96, 246),
	AccentHover = Color3.fromRGB(172, 124, 255),
	AccentPressed = Color3.fromRGB(118, 70, 210),
	Emphasis = Color3.fromRGB(226, 92, 214),
	-- the hub's "glowing = usable" colour, kept for world-linked UI (gates, prompts, location strip)
	Interactive = Color3.fromRGB(78, 214, 204),

	-- status
	Positive = Color3.fromRGB(96, 214, 140),
	Warning = Color3.fromRGB(250, 186, 80),
	Danger = Color3.fromRGB(240, 84, 96),
	Locked = Color3.fromRGB(104, 96, 130),

	-- currencies (chips and cost tags only)
	Gems = Color3.fromRGB(150, 160, 255),
	Gold = Color3.fromRGB(246, 196, 84),
	TraitShard = Color3.fromRGB(186, 120, 255),

	-- rarity: the strongest colours in the system, reserved for unit/trait/reward rarity.
	-- Keys match ReplicatedStorage.TD.Rarities ids; if that module defines a colour, prefer it.
	Rarity = {
		Common = Color3.fromRGB(200, 200, 212),
		Uncommon = Color3.fromRGB(120, 214, 130),
		Rare = Color3.fromRGB(86, 160, 255),
		Epic = Color3.fromRGB(184, 104, 255),
		Legendary = Color3.fromRGB(255, 200, 70),
		Mythic = Color3.fromRGB(240, 96, 220),
		Exclusive = Color3.fromRGB(255, 72, 88),
	} :: { [string]: Color3 },

	-- district accents (match HubConfig.Palette; used for location strip and portal cards)
	District = {
		Plaza = Color3.fromRGB(226, 220, 205),
		Gates = Color3.fromRGB(70, 220, 210),
		Summon = Color3.fromRGB(150, 110, 240),
		Market = Color3.fromRGB(250, 150, 70),
		Workshop = Color3.fromRGB(214, 168, 72),
		Garden = Color3.fromRGB(240, 120, 150),
		Guild = Color3.fromRGB(205, 190, 160),
		Rift = Color3.fromRGB(120, 110, 200),
	} :: { [string]: Color3 },

	-- mode accents (gate cards, lobby header). Keys = ModeLobbyConfig mode ids.
	Mode = {
		Story = Color3.fromRGB(70, 220, 210),
		Infinite = Color3.fromRGB(150, 110, 240),
		Challenge = Color3.fromRGB(250, 150, 70),
		Survival = Color3.fromRGB(110, 190, 120),
		Dungeon = Color3.fromRGB(240, 120, 150),
		Raid = Color3.fromRGB(226, 92, 100),
		BossRush = Color3.fromRGB(200, 70, 60),
		Event = Color3.fromRGB(240, 200, 90),
	} :: { [string]: Color3 },
}

-- Transparency: panels are glass, text never is.
Theme.Transparency = {
	Panel = 0.22, -- windows, dock, chips
	Card = 0.3, -- cards inside a window (stacks on the panel => still dark enough)
	Scrim = 0.5, -- full-screen dim behind an open window: keeps text readable over a bright hub
	Disabled = 0.5, -- applied to content, not the panel
}

-- Typography ----------------------------------------------------------------------------------------
-- Roblox font families (built in, no upload needed).
--   Display: Oswald  - condensed, strong uppercase titles; reads like an anime title card without
--                      imitating any game's logo.
--   Body:    Builder Sans - Roblox's UI face, best legibility at small sizes on phones.
--   Numeric: Builder Sans Bold with tabular feel for counters; Roboto Mono only for timers.
local function family(name: string, weight: Enum.FontWeight): Font
	return Font.new("rbxasset://fonts/families/" .. name .. ".json", weight)
end

Theme.Font = {
	Display = family("Oswald", Enum.FontWeight.SemiBold),
	DisplayBold = family("Oswald", Enum.FontWeight.Bold),
	Body = family("BuilderSans", Enum.FontWeight.Regular),
	BodyMedium = family("BuilderSans", Enum.FontWeight.Medium),
	BodyBold = family("BuilderSans", Enum.FontWeight.Bold),
	Timer = family("RobotoMono", Enum.FontWeight.Medium),
}

-- Type scale in px at UIScale 1 (1280x720 reference). Six steps; nothing in between.
Theme.TextSize = {
	Caption = 13, -- hints, counters under icons
	Body = 16,
	Label = 15, -- button text (uppercase display face)
	Title = 22, -- window titles
	Headline = 30, -- mode / district names in cards
	Hero = 44, -- results banner, district arrival title
}

-- Space and shape -----------------------------------------------------------------------------------
-- 4 px grid.
Theme.Space = { XS = 4, S = 8, M = 12, L = 16, XL = 24, XXL = 32 }

Theme.Radius = {
	Small = 3, -- chips, inputs
	Medium = 4, -- buttons, cards (small radii: the look is angular, not bubbly)
	Large = 6, -- windows
}

Theme.Stroke = { Hairline = 1, Focus = 2 }

-- Minimum touch target (px after scaling). Buttons never render smaller than this on touch devices.
Theme.TouchTarget = 44

Theme.Size = {
	ButtonHeight = 40,
	DockItem = 64, -- square dock tiles (PC); phone bottom bar uses DockItemCompact
	DockItemCompact = 52,
	ChipHeight = 32,
	TitleBar = 48,
	AccentRule = 2, -- short violet rule under window titles
	Bracket = 14, -- length of the corner brackets on windows and selected cards (the "layered" detail)
	WindowMin = Vector2.new(480, 320),
	WindowMax = Vector2.new(880, 580),
}

-- Motion --------------------------------------------------------------------------------------------
-- Short and consistent. Enter = Quint Out, exit = Quad In (exits are faster than entries).
Theme.Motion = {
	Fast = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), -- hover, press
	Enter = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), -- windows, toasts in
	Exit = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), -- windows, toasts out
	Emphasis = TweenInfo.new(0.36, Enum.EasingStyle.Back, Enum.EasingDirection.Out), -- reward pop, badge
	EnterOffset = 12, -- px a window travels while fading in
	PressScale = 0.96,
}

-- Layering (ScreenGui.DisplayOrder). TDHud (combat) should sit at 10; hub UI never shares a ScreenGui with it.
Theme.Layer = {
	HubHud = 20,
	Window = 30,
	Modal = 40,
	Toast = 50,
	Transition = 60, -- loading curtain between Hub / Loading / Match
}

-- Responsive ----------------------------------------------------------------------------------------
-- Reference resolution 1280x720. UIScale = clamp(min(w/1280, h/720), Min, Max).
Theme.Responsive = {
	Reference = Vector2.new(1280, 720),
	MinScale = 0.72,
	MaxScale = 1.35,
	-- Compact layout when the short side is below this many px (phones, small windows) or on touch-only.
	CompactShortSide = 560,
}

return Theme
