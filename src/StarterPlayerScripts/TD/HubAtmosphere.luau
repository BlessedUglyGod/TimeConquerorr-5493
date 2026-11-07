--!strict
-- HubAtmosphere: hub-only lighting and ambient motion (client). Install as ModuleScript
-- StarterPlayer.StarterPlayerScripts.TD.HubAtmosphere. From TDClient:
--   local HubAtmosphere = require(script.Parent.HubAtmosphere)
--   HubAtmosphere.init()                       -- follows the HubLocation attribute by itself
--
-- In the hub it applies HubDistricts.Lighting and adds Atmosphere / Bloom / ColorCorrection / SunRays
-- (named "HubFx_*"); on leaving the hub it restores the place's own Lighting values and removes them.
-- It also turns every part tagged "HubSpin" (set by HubDecorator) locally, only while in the hub.
-- Purely visual and local: nothing here replicates or touches gameplay.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local HubDistricts = require(ReplicatedStorage:WaitForChild("TD"):WaitForChild("HubDistricts"))

local player = Players.LocalPlayer
local L = HubDistricts.Lighting

local HubAtmosphere = {}

local LIGHTING_PROPS = { "ClockTime", "GeographicLatitude", "Brightness", "Ambient", "OutdoorAmbient", "ColorShift_Top",
	"EnvironmentDiffuseScale", "EnvironmentSpecularScale" }

local saved: { [string]: any }? = nil
local disabledFx: { Instance } = {}
local spinConn: RBXScriptConnection? = nil

local function addFx(className: string, props: { [string]: any })
	local fx = Instance.new(className)
	fx.Name = "HubFx_" .. className
	for k, v in props do
		(fx :: any)[k] = v
	end
	fx.Parent = Lighting
end

local function enterHub()
	if saved then
		return
	end
	local s = {}
	for _, prop in LIGHTING_PROPS do
		s[prop] = (Lighting :: any)[prop]
		local value = (L :: any)[prop]
		if value ~= nil then
			(Lighting :: any)[prop] = value
		end
	end
	saved = s
	-- the place's own Atmosphere/post effects would stack with ours: switch them off while in the hub
	for _, child in Lighting:GetChildren() do
		if not string.find(child.Name, "^HubFx_") then
			if child:IsA("Atmosphere") then
				child.Parent = nil
				table.insert(disabledFx, child)
			elseif child:IsA("PostEffect") and child.Enabled then
				child.Enabled = false
				table.insert(disabledFx, child)
			end
		end
	end
	addFx("Atmosphere", L.Atmosphere)
	addFx("BloomEffect", L.Bloom)
	addFx("ColorCorrectionEffect", L.ColorCorrection)
	addFx("SunRaysEffect", L.SunRays)

	spinConn = RunService.RenderStepped:Connect(function(dt)
		for _, p in CollectionService:GetTagged("HubSpin") do
			if p:IsA("BasePart") then
				local speed = math.rad((tonumber(p:GetAttribute("SpinSpeed")) or 0) * dt)
				if p:GetAttribute("SpinAxis") == "World" then
					local pos = p.Position
					p.CFrame = CFrame.new(pos) * CFrame.Angles(0, speed, 0) * (p.CFrame - pos)
				else
					p.CFrame *= CFrame.Angles(speed, 0, 0)
				end
			end
		end
	end)
end

local function leaveHub()
	if spinConn then
		spinConn:Disconnect()
		spinConn = nil
	end
	local s = saved
	if not s then
		return
	end
	saved = nil
	for prop, value in s do
		(Lighting :: any)[prop] = value
	end
	for _, child in Lighting:GetChildren() do
		if string.find(child.Name, "^HubFx_") then
			child:Destroy()
		end
	end
	for _, fx in disabledFx do
		if fx:IsA("Atmosphere") then
			fx.Parent = Lighting
		elseif fx:IsA("PostEffect") then
			fx.Enabled = true
		end
	end
	table.clear(disabledFx)
end

local function apply()
	local location = tostring(player:GetAttribute("HubLocation") or "Hub")
	if location == "Hub" then
		enterHub()
	else
		leaveHub()
	end
end

function HubAtmosphere.init()
	player:GetAttributeChangedSignal("HubLocation"):Connect(apply)
	apply()
end

return HubAtmosphere
