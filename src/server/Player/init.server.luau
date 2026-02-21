local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage.Packages

local Promise = require(Packages.Promise)

local Players = game:GetService("Players")

local profilePlayer = require(script.Profile)
local ecsPlayer = require(script.ECS)

local function playerAdded(player: Player)
    profilePlayer.PlayerAdded(player):andThen(function(profile)
        ecsPlayer.PlayerAdded(player)
    end)
end

local function playerRemoved(player: Player)
    profilePlayer.PlayerRemoved(player)
end

Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(playerRemoved)

for _, player in Players:GetPlayers() do
	Promise.try(playerAdded, player)
end

