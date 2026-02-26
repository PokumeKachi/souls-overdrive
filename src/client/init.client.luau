local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Chrono = require(Packages.Chrono)

Chrono.Start()

local ContextActionService = game:GetService("ContextActionService")

local Jabby = require(Packages.Jabby)

local client = Jabby.obtain_client()

local function create_widget(_, state: Enum.UserInputState)
	if state ~= Enum.UserInputState.Begin then
		return
	end
	client.spawn_app(client.apps.home, nil)
end

ContextActionService:BindAction("Open Jabby Home", create_widget, false, Enum.KeyCode.F4)
