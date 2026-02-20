local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Promise = require(Packages.Promise)

local Players = game:GetService("Players")

local Lifetime = require(script.Lifetime)

Players.PlayerAdded:Connect(Lifetime.PlayerAdded)
Players.PlayerRemoving:Connect(Lifetime.PlayerRemoved)

for _, player in Players:GetPlayers() do
	Promise.try(Lifetime.PlayerAdded, player)
end

