local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Chrono = require(Packages.Chrono)
local React = require(Packages.React)
local ReactRoblox = require(Packages.ReactRoblox)

local Players = game:GetService('Players')

local Player = Players.LocalPlayer

local guiHandle = Instance.new('ScreenGui')
local guiRoot = ReactRoblox.createRoot(guiHandle)

local Gui = require(script.Gui)
local ECS = require(script.ECS)

Chrono.Start()

guiHandle.ScreenInsets = Enum.ScreenInsets.None
guiHandle.Parent = Player.PlayerGui

guiRoot:render(React.createElement(Gui))
