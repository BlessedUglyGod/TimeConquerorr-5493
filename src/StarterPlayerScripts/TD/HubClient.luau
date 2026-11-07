--!strict
-- HubClient: client side of the main hub.
-- Install as ModuleScript StarterPlayer.StarterPlayerScripts.TD.HubClient and from TDClient:
--   local HubClient = require(script.Parent.HubClient)
--   HubClient.registerMenu("Summon", function() Menus.openSummon() end)
--   HubClient.registerMenu("Team", function() Menus.openTeam() end)
--   HubClient.onLocationChanged(function(location) hud.Enabled = location == "Match" end)
--   HubClient.init()
-- Menu ids come from HubConfig.Stations[*].Menu. Unknown ids show a toast instead of failing.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local TD = ReplicatedStorage:WaitForChild("TD")
local Remotes = TD:WaitForChild("Remotes")

local HubClient = {}

local menus: { [string]: (stationId: string) -> () } = {}
local locationListeners: { (string) -> () } = {}
local returnGui: ScreenGui? = nil

function HubClient.registerMenu(menuId: string, open: (stationId: string) -> ())
	menus[menuId] = open
end

function HubClient.onLocationChanged(callback: (string) -> ())
	table.insert(locationListeners, callback)
	callback(HubClient.getLocation())
end

function HubClient.getLocation(): string
	return tostring(player:GetAttribute("HubLocation") or "Hub")
end

local function toast(text: string)
	pcall(function()
		StarterGui:SetCore("SendNotification", { Title = "Meridian Isle", Text = text, Duration = 3 })
	end)
end

local function buildReturnButton(): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "HubReturn"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.Enabled = false
	local button = Instance.new("TextButton")
	button.Name = "Return"
	button.AnchorPoint = Vector2.new(0, 1)
	button.Position = UDim2.new(0, 12, 1, -12)
	button.Size = UDim2.fromOffset(150, 44)
	button.BackgroundColor3 = Color3.fromRGB(40, 44, 80)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 18
	button.Text = "Return to Hub"
	button.AutoButtonColor = true
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	button.Parent = gui
	button.Activated:Connect(function()
		local r = Remotes:FindFirstChild("HubReturn")
		if r and r:IsA("RemoteEvent") then
			r:FireServer()
		end
	end)
	gui.Parent = player:WaitForChild("PlayerGui")
	return gui
end

local function onLocation()
	local location = HubClient.getLocation()
	if returnGui then
		returnGui.Enabled = location == "Match"
	end
	for _, cb in locationListeners do
		task.spawn(cb, location)
	end
end

function HubClient.init()
	returnGui = buildReturnButton()
	local openMenu = Remotes:WaitForChild("HubOpenMenu") :: RemoteEvent
	openMenu.OnClientEvent:Connect(function(menuId: unknown, stationId: unknown)
		if typeof(menuId) ~= "string" then
			return
		end
		local open = menus[menuId]
		if open then
			open(if typeof(stationId) == "string" then stationId else "")
		else
			toast(menuId .. " is not available yet")
		end
	end)
	player:GetAttributeChangedSignal("HubLocation"):Connect(onLocation)
	onLocation()
end

return HubClient
