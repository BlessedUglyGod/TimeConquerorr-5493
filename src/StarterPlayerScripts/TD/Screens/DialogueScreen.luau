--!strict
-- DialogueScreen: NPC conversations (spec: docs/ui/SCREENS.md, "NPC dialogue").
-- Install as ModuleScript StarterPlayer.StarterPlayerScripts.TD.Screens.DialogueScreen.
--
-- A visual-novel strip across the bottom third, not a centred window: nameplate in the NPC's district
-- accent, bust (portrait image, the NPC model in a ViewportFrame, or a monogram), typed text, choices.
-- Choices open real systems through the same menu handlers stations use.
--   DialogueScreen.init({ openMenu = function(menuId) ... end, setHudVisible = HubHud.setVisible })
--   HubClient.registerMenu("Talk", function(stationId) DialogueScreen.open(stationId) end)
-- (set the NPC stations' Menu to "Talk" in HubConfig; their Id must be a DialogueData key)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UI = ReplicatedStorage:WaitForChild("TD"):WaitForChild("UI")
local Theme = require(UI:WaitForChild("Theme"))
local UiKit = require(UI:WaitForChild("UiKit"))
local UiParts = require(UI:WaitForChild("UiParts"))
local DialogueData = require(UI:WaitForChild("DialogueData"))

local C = Theme.Color
local CHARS_PER_SECOND = 40

export type InitOptions = {
	openMenu: (menuId: string) -> (),
	setHudVisible: ((visible: boolean) -> ())?,
	focusCamera: boolean?, -- ease the camera toward the NPC while talking (default true)
}

local DialogueScreen = {}

local options: InitOptions? = nil
local gui: ScreenGui? = nil
local refs: {
	strip: CanvasGroup,
	nameplate: TextLabel,
	title: TextLabel,
	rule: Frame,
	body: TextLabel,
	hint: TextLabel,
	choices: Frame,
	bust: Frame,
}? = nil
local activeNpc: string? = nil
local typing = false
local skipTyping = false
local advance: (() -> ())? = nil
local savedCamera: { Type: Enum.CameraType, CFrame: CFrame }? = nil

local function build()
	local screen = UiKit.screen("TDDialogue", Theme.Layer.Modal)
	screen.Enabled = false
	gui = screen

	local strip = Instance.new("CanvasGroup")
	strip.Name = "Strip"
	strip.AnchorPoint = Vector2.new(0.5, 1)
	strip.Position = UDim2.new(0.5, 0, 1, -Theme.Space.L)
	strip.Size = UDim2.new(1, -Theme.Space.XXL * 2, 0, 200)
	strip.BackgroundColor3 = C.Base
	strip.BackgroundTransparency = Theme.Transparency.Panel
	strip.BorderSizePixel = 0
	strip.Parent = screen
	UiKit.corner(strip, Theme.Radius.Large)
	UiKit.stroke(strip)
	UiKit.brackets(strip, C.StrokeStrong)

	-- bust (left)
	local bust = Instance.new("Frame")
	bust.Name = "Bust"
	bust.BackgroundTransparency = 1
	bust.Size = UDim2.new(0, 180, 1, 0)
	bust.Parent = strip

	-- nameplate + text (middle)
	local nameplate = UiKit.text(strip, { Text = "", Font = Theme.Font.DisplayBold, Size = Theme.TextSize.Title, Upper = true })
	nameplate.Position = UDim2.fromOffset(196, Theme.Space.L)
	nameplate.Size = UDim2.new(0.5, 0, 0, 28)
	local title = UiKit.text(strip, { Text = "", Size = Theme.TextSize.Caption, Color = C.TextMuted })
	title.Position = UDim2.fromOffset(196, Theme.Space.L + 28)
	title.Size = UDim2.new(0.5, 0, 0, 18)
	local rule = Instance.new("Frame")
	rule.BorderSizePixel = 0
	rule.Position = UDim2.fromOffset(196, Theme.Space.L + 50)
	rule.Size = UDim2.fromOffset(48, Theme.Size.AccentRule)
	rule.Parent = strip
	local body = UiKit.text(strip, { Text = "", Size = Theme.TextSize.Body + 1 })
	body.Position = UDim2.fromOffset(196, Theme.Space.L + 60)
	body.Size = UDim2.new(0.6, -196, 1, -(Theme.Space.L + 60) - 30)
	body.TextWrapped = true
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextTruncate = Enum.TextTruncate.None
	local hint = UiKit.text(strip, { Text = "", Size = Theme.TextSize.Caption, Color = C.TextFaint })
	hint.AnchorPoint = Vector2.new(0, 1)
	hint.Position = UDim2.new(0, 196, 1, -Theme.Space.S)
	hint.Size = UDim2.new(0.5, 0, 0, 16)

	-- choices (right)
	local choices = Instance.new("Frame")
	choices.Name = "Choices"
	choices.BackgroundTransparency = 1
	choices.AnchorPoint = Vector2.new(1, 0.5)
	choices.Position = UDim2.new(1, -Theme.Space.L, 0.5, 0)
	choices.Size = UDim2.new(0.4, -Theme.Space.L, 1, -Theme.Space.L * 2)
	choices.Parent = strip
	UiKit.list(choices, Enum.FillDirection.Vertical, Theme.Space.S, Enum.HorizontalAlignment.Right)

	-- tapping the text area completes the line, then advances
	local tapArea = Instance.new("TextButton")
	tapArea.BackgroundTransparency = 1
	tapArea.Text = ""
	tapArea.Position = UDim2.fromOffset(180, 0)
	tapArea.Size = UDim2.new(0.6, -180, 1, 0)
	tapArea.Parent = strip
	tapArea.Activated:Connect(function()
		if typing then
			skipTyping = true
		elseif advance then
			advance()
		end
	end)

	UiKit.onLayoutChanged(function(layout)
		local compact = layout == "Compact"
		-- Compact: taller strip, choices drop under the text
		strip.Size = if compact then UDim2.new(1, -Theme.Space.L * 2, 0, 260) else UDim2.new(1, -Theme.Space.XXL * 2, 0, 200)
		bust.Size = UDim2.new(0, if compact then 110 else 180, if compact then 0.55 else 1, 0)
		local x = if compact then 120 else 196
		nameplate.Position = UDim2.fromOffset(x, Theme.Space.L)
		title.Position = UDim2.fromOffset(x, Theme.Space.L + 28)
		rule.Position = UDim2.fromOffset(x, Theme.Space.L + 50)
		body.Position = UDim2.fromOffset(x, Theme.Space.L + 60)
		body.Size = if compact then UDim2.new(1, -x - Theme.Space.L, 0, 70) else UDim2.new(0.6, -x, 1, -(Theme.Space.L + 60) - 30)
		choices.AnchorPoint = if compact then Vector2.new(0.5, 1) else Vector2.new(1, 0.5)
		choices.Position = if compact then UDim2.new(0.5, 0, 1, -Theme.Space.S) else UDim2.new(1, -Theme.Space.L, 0.5, 0)
		choices.Size = if compact then UDim2.new(1, -Theme.Space.L * 2, 0, 100) else UDim2.new(0.4, -Theme.Space.L, 1, -Theme.Space.L * 2)
		local list = choices:FindFirstChildOfClass("UIListLayout")
		if list then
			list.FillDirection = if compact then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical
			list.Wraps = compact
		end
	end)

	refs = { strip = strip, nameplate = nameplate, title = title, rule = rule, body = body, hint = hint, choices = choices, bust = bust }
end

local function npcModel(stationId: string): Model?
	local hub = workspace:FindFirstChild("Hub")
	local stations = hub and hub:FindFirstChild("Stations")
	local m = stations and stations:FindFirstChild(stationId)
	return if m and m:IsA("Model") then m else nil
end

local function focusCamera(stationId: string)
	local o = options
	if o and o.focusCamera == false then
		return
	end
	local model = npcModel(stationId)
	local cam = workspace.CurrentCamera
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not model or not cam or not root or not root:IsA("BasePart") then
		return
	end
	savedCamera = { Type = cam.CameraType, CFrame = cam.CFrame }
	local npcPos = model:GetPivot().Position + Vector3.new(0, 4, 0)
	local fromPos = root.Position:Lerp(npcPos, 0.25) + Vector3.new(0, 4, 0) + (root.Position - npcPos).Unit * 6
	cam.CameraType = Enum.CameraType.Scriptable
	TweenService:Create(cam, Theme.Motion.Enter, { CFrame = CFrame.lookAt(fromPos, npcPos) }):Play()
end

local function restoreCamera()
	local cam = workspace.CurrentCamera
	if savedCamera and cam then
		cam.CameraType = savedCamera.Type
	end
	savedCamera = nil
end

local function setBust(stationId: string, npc: DialogueData.Npc, accent: Color3)
	local r = refs :: any
	for _, child in r.bust:GetChildren() do
		child:Destroy()
	end
	if npc.Portrait and npc.Portrait ~= "" then
		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.Size = UDim2.fromScale(1, 1)
		img.Image = npc.Portrait
		img.ScaleType = Enum.ScaleType.Fit
		img.Parent = r.bust
		return
	end
	local preview = UiParts.preview(r.bust)
	preview.show(npcModel(stationId), npc.Name, nil)
	preview.setAura(accent)
end

local function close()
	local o = options
	activeNpc = nil
	advance = nil
	restoreCamera()
	local r = refs
	if gui and r then
		UiKit.tween(r.strip, Theme.Motion.Exit, { GroupTransparency = 1 }).Completed:Once(function()
			if not activeNpc and gui then
				gui.Enabled = false
			end
		end)
	end
	if o and o.setHudVisible then
		o.setHudVisible(true)
	end
end

local function typeLine(text: string)
	local r = refs :: any
	typing = true
	skipTyping = false
	r.body.Text = text
	r.body.MaxVisibleGraphemes = 0
	local total = utf8.len(text) or #text
	local elapsed = 0
	while not skipTyping do
		elapsed += task.wait()
		local shown = math.min(total, math.floor(elapsed * CHARS_PER_SECOND))
		r.body.MaxVisibleGraphemes = shown
		if shown >= total then
			break
		end
	end
	r.body.MaxVisibleGraphemes = -1
	typing = false
end

local showNode: (stationId: string, nodeId: string) -> ()

showNode = function(stationId: string, nodeId: string)
	local npc = DialogueData[stationId]
	local node = npc and npc.Nodes[nodeId]
	local r = refs
	if not npc or not node or not r then
		close()
		return
	end
	for _, child in r.choices:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	advance = nil
	r.hint.Text = ""
	typeLine(node.Text)
	if activeNpc ~= stationId then
		return -- closed while typing
	end
	local list = node.Choices
	if not list or #list == 0 then
		r.hint.Text = "Tap to continue"
		advance = close
		return
	end
	for i, choice in list do
		local variant: UiKit.ButtonVariant = if choice.Menu then "Primary" elseif choice.Close then "Ghost" else "Secondary"
		local btn = UiKit.button(r.choices, { Text = choice.Text, Variant = variant, OnActivated = function()
			if choice.Menu then
				local o = options
				close()
				if o then
					o.openMenu(choice.Menu)
				end
			elseif choice.Next then
				task.spawn(showNode, stationId, choice.Next)
			else
				close()
			end
		end })
		btn.Instance.LayoutOrder = i
		btn.Instance.TextXAlignment = Enum.TextXAlignment.Left
		btn.Instance.Size = UDim2.new(1, 0, 0, Theme.Size.ButtonHeight)
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, Theme.Space.M)
		pad.Parent = btn.Instance
		-- choices arrive one after another
		btn.Instance.TextTransparency = 1
		UiKit.tween(btn.Instance, Theme.Motion.Enter, { TextTransparency = 0 })
		task.wait(0.04)
	end
end

function DialogueScreen.init(opts: InitOptions)
	options = opts
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not activeNpc then
			return
		end
		if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
			close()
		elseif input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
			if typing then
				skipTyping = true
			elseif advance then
				advance()
			end
		end
	end)
end

function DialogueScreen.open(stationId: string)
	local npc = DialogueData[stationId]
	if not npc then
		UiKit.toast("They have nothing to say right now", "Info")
		return
	end
	if not gui then
		build()
	end
	local r = refs :: any
	UiKit.closeAll()
	local o = options
	if o and o.setHudVisible then
		o.setHudVisible(false)
	end
	activeNpc = stationId
	local accent = C.District[npc.District] or C.Accent
	r.nameplate.Text = string.upper(npc.Name)
	r.nameplate.TextColor3 = accent
	r.title.Text = npc.Title
	r.rule.BackgroundColor3 = accent
	setBust(stationId, npc, accent)
	;(gui :: ScreenGui).Enabled = true
	r.strip.GroupTransparency = 1
	r.strip.Position = UDim2.new(0.5, 0, 1, -Theme.Space.L + Theme.Motion.EnterOffset)
	UiKit.tween(r.strip, Theme.Motion.Enter, { GroupTransparency = 0, Position = UDim2.new(0.5, 0, 1, -Theme.Space.L) })
	focusCamera(stationId)
	task.spawn(showNode, stationId, npc.Start)
end

DialogueScreen.close = close

return DialogueScreen
