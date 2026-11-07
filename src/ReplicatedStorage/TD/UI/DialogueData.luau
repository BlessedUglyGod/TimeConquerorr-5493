--!strict
-- DialogueData: NPC conversations (original characters and lines). Install as ModuleScript
-- ReplicatedStorage.TD.UI.DialogueData. Read by DialogueScreen.
--
-- Keys are HubConfig station ids of Kind "Npc" (the station's Menu becomes "Talk"; HubClient passes the
-- station id to the handler). Each NPC is a small graph of nodes. A choice can:
--   Next  = go to another node
--   Menu  = open a system through the same menu ids stations use ("Summon", "Team", "Lobby_Story", ...)
--   Close = end the conversation
-- Conditions are intentionally absent for now: quest-aware lines come with the quest system (Phase 5).

export type Choice = { Text: string, Next: string?, Menu: string?, Close: boolean? }
export type Node = { Text: string, Choices: { Choice }? }
export type Npc = {
	Name: string,
	Title: string, -- small line under the name
	District: string, -- HubConfig zone id: the nameplate takes that district's accent
	Portrait: string?, -- rbxassetid bust; nil = ViewportFrame of the NPC model or monogram
	Start: string,
	Nodes: { [string]: Node },
}

local DialogueData: { [string]: Npc } = {
	Guide = {
		Name = "Lumi",
		Title = "Archivist of Meridian Isle",
		District = "Plaza",
		Start = "greet",
		Nodes = {
			greet = {
				Text = "Oh, a new hand on the dial! Welcome to Meridian Isle. Every road here points somewhere worth going. What would you like to know?",
				Choices = {
					{ Text = "How do I start playing?", Next = "play" },
					{ Text = "Where do I get units?", Next = "units" },
					{ Text = "What is this place?", Next = "lore" },
					{ Text = "Nothing for now.", Close = true },
				},
			},
			play = {
				Text = "Walk north to the Gate Terrace, or press PLAY. Each gate opens a lobby: gather up to six friends, pick a stage and step through together.",
				Choices = {
					{ Text = "Open the gates for me.", Menu = "Lobby_Story" },
					{ Text = "Tell me something else.", Next = "greet" },
				},
			},
			units = {
				Text = "The Starfall Sanctum, north-east, is where defenders answer the call. Then visit Clockkeeper Oro in the Workshop to set your team.",
				Choices = {
					{ Text = "Take me to summoning.", Menu = "Summon" },
					{ Text = "Show me my team.", Menu = "Team" },
					{ Text = "Back.", Next = "greet" },
				},
			},
			lore = {
				Text = "The great clock stopped long ago, and time started leaking through the rifts. We guard what is left of it. Some say the Spire still keeps a few lost cogs...",
				Choices = {
					{ Text = "Lost cogs?", Next = "cogs" },
					{ Text = "Back.", Next = "greet" },
				},
			},
			cogs = {
				Text = "Look high, look behind falling water, look where the island ends. I won't say more. Archivists love a mystery.",
				Choices = { { Text = "I'll find them.", Close = true } },
			},
		},
	},
	Clockkeeper = {
		Name = "Oro",
		Title = "Clockkeeper of the Workshop",
		District = "Workshop",
		Start = "greet",
		Nodes = {
			greet = {
				Text = "Mind the gears. Every defender ticks a little differently: level them, tune their traits, and one day they'll evolve. What needs fixing?",
				Choices = {
					{ Text = "Manage my team.", Menu = "Team" },
					{ Text = "Reroll a trait.", Menu = "Traits" },
					{ Text = "Evolve a unit.", Menu = "Evolution" },
					{ Text = "Just looking.", Close = true },
				},
			},
		},
	},
	Merchant = {
		Name = "Nim",
		Title = "Peddler of Lantern Market",
		District = "Market",
		Start = "greet",
		Nodes = {
			greet = {
				Text = "Fresh stock every few hours, friend! Gold for the everyday, gems for the rare stuff, and event tokens while the lanterns are lit.",
				Choices = {
					{ Text = "Show me your wares.", Menu = "ShopGold" },
					{ Text = "Anything special today?", Menu = "ShopEvent" },
					{ Text = "Maybe later.", Close = true },
				},
			},
		},
	},
}

return DialogueData
