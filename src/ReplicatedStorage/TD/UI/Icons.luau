--!strict
-- Icons: the shared icon language. Install as ModuleScript ReplicatedStorage.TD.UI.Icons.
--
-- Every icon has an id used by UI code. `Asset` is the uploaded image (rbxassetid://...). Until the art is
-- uploaded (and logged in ASSET_MANIFEST.md) an icon renders as its `Glyph`: a 1-2 letter mark on a
-- small tile in the icon's tint. The fallback is deliberately plain so nobody mistakes it for final art.
--
-- Art brief for the real set (docs/ui/UI_DESIGN_SYSTEM.md, "Icons"): 24 px grid, 2 px rounded strokes,
-- one filled detail per icon in the tint colour, no outlines-plus-shadow, no gradients. Original shapes.

export type IconDef = {
	Asset: string, -- "" until uploaded
	Glyph: string,
	Tint: Color3?,
}

local Icons: { [string]: IconDef } = {
	-- navigation / dock
	Play = { Asset = "", Glyph = "GO" },
	Summon = { Asset = "", Glyph = "SU", Tint = Color3.fromRGB(150, 110, 240) },
	Team = { Asset = "", Glyph = "TM", Tint = Color3.fromRGB(214, 168, 72) },
	Collection = { Asset = "", Glyph = "CB", Tint = Color3.fromRGB(214, 168, 72) },
	Quests = { Asset = "", Glyph = "QS", Tint = Color3.fromRGB(205, 190, 160) },
	Shop = { Asset = "", Glyph = "SH", Tint = Color3.fromRGB(250, 150, 70) },
	Pass = { Asset = "", Glyph = "SP", Tint = Color3.fromRGB(240, 200, 90) },
	Settings = { Asset = "", Glyph = "OP" },
	Close = { Asset = "", Glyph = "X" },
	Back = { Asset = "", Glyph = "<" },
	Lock = { Asset = "", Glyph = "LK", Tint = Color3.fromRGB(96, 98, 120) },
	-- currencies
	Gems = { Asset = "", Glyph = "G", Tint = Color3.fromRGB(120, 200, 255) },
	Gold = { Asset = "", Glyph = "C", Tint = Color3.fromRGB(240, 196, 90) },
	TraitShard = { Asset = "", Glyph = "TS", Tint = Color3.fromRGB(78, 214, 204) },
	-- modes (keys = ModeLobbyConfig ids)
	Story = { Asset = "", Glyph = "ST", Tint = Color3.fromRGB(70, 220, 210) },
	Infinite = { Asset = "", Glyph = "IN", Tint = Color3.fromRGB(150, 110, 240) },
	Challenge = { Asset = "", Glyph = "CH", Tint = Color3.fromRGB(250, 150, 70) },
	Survival = { Asset = "", Glyph = "SV", Tint = Color3.fromRGB(110, 190, 120) },
	Dungeon = { Asset = "", Glyph = "DG", Tint = Color3.fromRGB(240, 120, 150) },
	Raid = { Asset = "", Glyph = "RD", Tint = Color3.fromRGB(226, 92, 100) },
	BossRush = { Asset = "", Glyph = "BR", Tint = Color3.fromRGB(200, 70, 60) },
	Event = { Asset = "", Glyph = "EV", Tint = Color3.fromRGB(240, 200, 90) },
}

local Module = {}

local UNKNOWN: IconDef = { Asset = "", Glyph = "?" }

function Module.get(id: string): IconDef
	return Icons[id] or UNKNOWN
end

function Module.has(id: string): boolean
	return Icons[id] ~= nil
end

return Module
