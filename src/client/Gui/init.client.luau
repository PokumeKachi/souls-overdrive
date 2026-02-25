local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local React = require(Packages.React)
local ReactRoblox = require(Packages.ReactRoblox)

local App = require(script.App)

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local guiHandle = Instance.new("ScreenGui")
local guiRoot = ReactRoblox.createRoot(guiHandle)

guiHandle.ScreenInsets = Enum.ScreenInsets.None
guiHandle.ResetOnSpawn = false
guiHandle.Parent = Player:WaitForChild("PlayerGui")
guiRoot:render(React.createElement(App))
