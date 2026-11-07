--!strict
-- ModeLobbyConfig: data for every mode lobby (shared by server and client).
-- Install as ModuleScript ReplicatedStorage.TD.Lobby.ModeLobbyConfig.
--
-- One entry per mode. PartyService, MatchLaunchService and LobbyClient read only this data, so a new
-- mode or option is a data change, not a code change. The server re-validates every selection with
-- ModeLobbyConfig.validateSelection; the client uses the same function only to grey out buttons.

export type Choice = {
	Id: string,
	Label: string,
	Enabled: boolean?, -- false = shown as locked
	Requires: { [string]: string }?, -- other option values this choice needs, e.g. { Difficulty = "Hard" }
	Stages: number?, -- on a World choice: how many stages that world has
	MapId: string?, -- on a World/Map choice: Config.Modes[Mode].Maps entry it plays on
}

export type OptionDef = {
	Id: string, -- "World", "Stage", "Difficulty", "Map", ...
	Label: string,
	Choices: { Choice },
	Default: string,
	-- Numeric choices limited by another option's choice.Stages (Story: Stage limited by World).
	LimitBy: string?,
}

export type Requirements = {
	MinAccountLevel: number?,
	UnlockFlag: string?, -- profile flag, e.g. "StoryCleared_AshVeilValley_6"
	MinTeamSize: number?, -- units in the equipped team
}

export type ModeDef = {
	Id: string,
	Label: string,
	Enabled: boolean,
	Layout: "Story" | "Generic", -- which lobby layout the client builds
	MinPlayers: number,
	MaxPlayers: number, -- per-mode cap, never above ModeLobbyConfig.GlobalMaxPlayers
	AllowPublic: boolean,
	AllowPrivate: boolean,
	AllowInvites: boolean,
	AllowReplay: boolean,
	StartCountdown: number, -- seconds between the leader pressing Start and the launch
	Place: string, -- key into ModeLobbyConfig.Places
	Options: { OptionDef },
	Requirements: Requirements?,
}

local ModeLobbyConfig = {}

ModeLobbyConfig.GlobalMaxPlayers = 6
ModeLobbyConfig.MaxLoadout = 6 -- units in a team
ModeLobbyConfig.ConfigVersion = 1 -- bump when the ticket schema changes; match servers refuse other versions

-- Place ids inside the one experience. 0 = not published yet -> MatchLaunchService falls back to Local.
ModeLobbyConfig.Places = {
	Hub = 116509641758969, -- current TD place (hub + prototype map)
	Match = 0, -- TD Match place (set after publishing, see docs/multiplayer/PUBLISHING.md)
}

-- Launch strategy. "Auto": Local in Studio or when the place id is 0, Reserved otherwise.
ModeLobbyConfig.LaunchMode = "Auto" :: "Auto" | "Local" | "Reserved"

-- Difficulty numbers (HealthMul, RewardMul) and the list of maps/stages per mode live in the live
-- Config (Config.Difficulties, Config.Modes) and are enforced by MatchContext.build. This file never
-- duplicates combat numbers; Nightmare stays locked until Config.Difficulties has it.

local function difficultyOption(enabledHard: boolean, enabledNightmare: boolean): OptionDef
	return {
		Id = "Difficulty",
		Label = "Difficulty",
		Default = "Normal",
		Choices = {
			{ Id = "Normal", Label = "Normal" },
			{ Id = "Hard", Label = "Hard", Enabled = enabledHard },
			{ Id = "Nightmare", Label = "Nightmare", Enabled = enabledNightmare },
		},
	}
end

-- Story: World (chapter) -> Stage. Worlds follow docs/STORY_WORLDS.md; each world is its own set of
-- enemies/maps (no mixing). Only the prototype world is enabled until the world content is merged.
-- Stage ids are numbers as strings, because the live MatchContext takes Stage as an integer.
local storyStages: { Choice } = {}
for i = 1, 6 do
	table.insert(storyStages, { Id = tostring(i), Label = if i == 6 then "Stage 6 (Boss)" else "Stage " .. i })
end

ModeLobbyConfig.Modes = {
	{
		Id = "Story", Label = "Story", Enabled = true, Layout = "Story",
		MinPlayers = 1, MaxPlayers = 6, AllowPublic = true, AllowPrivate = true, AllowInvites = true, AllowReplay = true,
		StartCountdown = 5, Place = "Match",
		Options = {
			{
				Id = "World", Label = "Chapter", Default = "Prototype",
				Choices = {
					{ Id = "Prototype", Label = "Prologue: Training Grounds", Stages = 1, MapId = "TDMap" },
					{ Id = "AshVeilValley", Label = "1. Ash Veil Valley", Enabled = false, Stages = 6, MapId = "AshVeilValley" },
					{ Id = "TwilightThreshold", Label = "2. Twilight Threshold", Enabled = false, Stages = 6, MapId = "TwilightThreshold" },
					{ Id = "SaltfangArchipelago", Label = "3. Saltfang Archipelago", Enabled = false, Stages = 6, MapId = "SaltfangArchipelago" },
					{ Id = "GatefallCity", Label = "4. Gatefall City", Enabled = false, Stages = 6, MapId = "GatefallCity" },
				},
			},
			{ Id = "Stage", Label = "Stage", Default = "1", Choices = storyStages, LimitBy = "World" },
			difficultyOption(true, false),
		},
		Requirements = { MinTeamSize = 1 },
	},
	{
		Id = "Infinite", Label = "Infinite", Enabled = false, Layout = "Generic",
		MinPlayers = 1, MaxPlayers = 6, AllowPublic = true, AllowPrivate = true, AllowInvites = true, AllowReplay = true,
		StartCountdown = 5, Place = "Match",
		Options = {
			{ Id = "Map", Label = "Map", Default = "TDMap", Choices = { { Id = "TDMap", Label = "Training Grounds" } } },
		},
		Requirements = { UnlockFlag = "StoryCleared_Prototype" },
	},
	{
		Id = "Dungeon", Label = "Dungeons", Enabled = false, Layout = "Generic",
		MinPlayers = 1, MaxPlayers = 4, AllowPublic = true, AllowPrivate = true, AllowInvites = true, AllowReplay = true,
		StartCountdown = 5, Place = "Match",
		Options = {
			{ Id = "Map", Label = "Dungeon", Default = "SunkenLanternShrine", Choices = { { Id = "SunkenLanternShrine", Label = "Sunken Lantern Shrine" } } },
			difficultyOption(true, false),
		},
		Requirements = { MinAccountLevel = 10 },
	},
	{
		Id = "Raid", Label = "Raids", Enabled = false, Layout = "Generic",
		MinPlayers = 2, MaxPlayers = 6, AllowPublic = true, AllowPrivate = true, AllowInvites = true, AllowReplay = false,
		StartCountdown = 8, Place = "Match",
		Options = {
			{ Id = "Map", Label = "Raid", Default = "TDMap", Choices = { { Id = "TDMap", Label = "Raid prototype" } } },
			difficultyOption(true, false),
		},
		Requirements = { MinAccountLevel = 20, MinTeamSize = 6 },
	},
	{
		Id = "Challenge", Label = "Challenges", Enabled = false, Layout = "Generic",
		MinPlayers = 1, MaxPlayers = 3, AllowPublic = true, AllowPrivate = true, AllowInvites = true, AllowReplay = false,
		StartCountdown = 5, Place = "Match",
		Options = {
			{ Id = "Challenge", Label = "Challenge", Default = "Daily", Choices = { { Id = "Daily", Label = "Daily" }, { Id = "Weekly", Label = "Weekly" } } },
		},
		Requirements = { MinAccountLevel = 5 },
	},
	{
		Id = "Survival", Label = "Survival", Enabled = false, Layout = "Generic",
		MinPlayers = 1, MaxPlayers = 6, AllowPublic = true, AllowPrivate = true, AllowInvites = true, AllowReplay = true,
		StartCountdown = 5, Place = "Match",
		Options = {
			{ Id = "Map", Label = "Map", Default = "TDMap", Choices = { { Id = "TDMap", Label = "Training Grounds" } } },
			difficultyOption(true, false),
		},
	},
	{
		Id = "BossRush", Label = "Boss Rush", Enabled = false, Layout = "Generic",
		MinPlayers = 1, MaxPlayers = 4, AllowPublic = true, AllowPrivate = true, AllowInvites = true, AllowReplay = true,
		StartCountdown = 5, Place = "Match",
		Options = {
			{ Id = "Map", Label = "Arena", Default = "TDMap", Choices = { { Id = "TDMap", Label = "Training Grounds" } } },
			difficultyOption(true, false),
		},
		Requirements = { MinAccountLevel = 15 },
	},
	{
		Id = "Event", Label = "Event", Enabled = false, Layout = "Generic",
		MinPlayers = 1, MaxPlayers = 6, AllowPublic = true, AllowPrivate = true, AllowInvites = true, AllowReplay = true,
		StartCountdown = 5, Place = "Match",
		Options = {
			{ Id = "Event", Label = "Event", Default = "None", Choices = { { Id = "None", Label = "No active event", Enabled = false } } },
		},
	},
} :: { ModeDef }

local byId: { [string]: ModeDef } = {}
for _, mode in ModeLobbyConfig.Modes do
	assert(mode.MaxPlayers <= ModeLobbyConfig.GlobalMaxPlayers, mode.Id .. ": MaxPlayers above the global cap")
	assert(mode.MinPlayers >= 1 and mode.MinPlayers <= mode.MaxPlayers, mode.Id .. ": bad MinPlayers")
	byId[mode.Id] = mode
end

function ModeLobbyConfig.getMode(modeId: string): ModeDef?
	return byId[modeId]
end

function ModeLobbyConfig.getOption(mode: ModeDef, optionId: string): OptionDef?
	for _, opt in mode.Options do
		if opt.Id == optionId then
			return opt
		end
	end
	return nil
end

function ModeLobbyConfig.getChoice(opt: OptionDef, choiceId: string): Choice?
	for _, c in opt.Choices do
		if c.Id == choiceId then
			return c
		end
	end
	return nil
end

local function choiceAllowed(mode: ModeDef, opt: OptionDef, choice: Choice, selection: { [string]: string }): boolean
	if choice.Enabled == false then
		return false
	end
	if opt.LimitBy then
		local limitOpt = ModeLobbyConfig.getOption(mode, opt.LimitBy)
		local limitChoice = limitOpt and ModeLobbyConfig.getChoice(limitOpt, selection[opt.LimitBy] or "")
		local n = tonumber(choice.Id)
		if not limitChoice or not n or n < 1 or n > (limitChoice.Stages or 1) then
			return false
		end
	end
	if choice.Requires then
		for key, value in choice.Requires do
			if selection[key] ~= value then
				return false
			end
		end
	end
	return true
end

-- Choices of one option that are valid with the rest of the selection (client uses this for the UI).
function ModeLobbyConfig.availableChoices(mode: ModeDef, optionId: string, selection: { [string]: string }): { Choice }
	local out = {}
	local opt = ModeLobbyConfig.getOption(mode, optionId)
	if opt then
		for _, c in opt.Choices do
			if choiceAllowed(mode, opt, c, selection) then
				table.insert(out, c)
			end
		end
	end
	return out
end

function ModeLobbyConfig.defaultSelection(mode: ModeDef): { [string]: string }
	local sel: { [string]: string } = {}
	for _, opt in mode.Options do
		sel[opt.Id] = opt.Default
	end
	return sel
end

-- After one option changed, move dependent options to their first valid choice.
function ModeLobbyConfig.fixDependents(mode: ModeDef, selection: { [string]: string })
	for _, opt in mode.Options do
		local current = ModeLobbyConfig.getChoice(opt, selection[opt.Id] or "")
		if not current or not choiceAllowed(mode, opt, current, selection) then
			local first = ModeLobbyConfig.availableChoices(mode, opt.Id, selection)[1]
			selection[opt.Id] = if first then first.Id else opt.Default
		end
	end
end

-- Full check of a selection table coming from anywhere (client, ticket). Unknown keys are rejected.
function ModeLobbyConfig.validateSelection(mode: ModeDef, selection: any): (boolean, string?)
	if typeof(selection) ~= "table" then
		return false, "Bad selection"
	end
	for key, value in selection do
		if typeof(key) ~= "string" or typeof(value) ~= "string" or not ModeLobbyConfig.getOption(mode, key) then
			return false, "Unknown option"
		end
	end
	for _, opt in mode.Options do
		local value = selection[opt.Id]
		local choice = if typeof(value) == "string" then ModeLobbyConfig.getChoice(opt, value) else nil
		if not choice then
			return false, opt.Label .. " is not set"
		end
		if not choiceAllowed(mode, opt, choice, selection) then
			return false, choice.Label .. " is locked"
		end
	end
	return true, nil
end

-- Lobby selection -> the raw table the live MatchContext.build(raw) validates
-- ({ Mode, MapId, Stage, Difficulty, Party }). MatchContext stays the single authority for what a match
-- is; this config only decides what the lobby UI offers.
function ModeLobbyConfig.toContextRaw(mode: ModeDef, selection: { [string]: string }, party: { number }): { [string]: any }
	local mapId: string? = selection.Map
	for _, opt in mode.Options do
		local choice = ModeLobbyConfig.getChoice(opt, selection[opt.Id] or "")
		if choice and choice.MapId then
			mapId = choice.MapId
		end
	end
	return {
		Mode = mode.Id,
		MapId = mapId, -- nil -> MatchContext picks the first map of the mode
		Stage = tonumber(selection.Stage or "1") or 1,
		Difficulty = selection.Difficulty or "Normal",
		Party = table.clone(party),
	}
end

return ModeLobbyConfig
