local ServerScriptService = game:GetService("ServerScriptService")
local API = ServerScriptService.API
local Profile = require(API.Profile)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Promise = require(Packages.Promise)

local Players = game:GetService("Players")

local function PlayerAdded(player: Player)
	Profile:StartSession(player):andThen(function()
		print(`Profile loaded for {player.DisplayName}!`)

		local profile = Profile:GetProfile(player)

		print(`Player last joined our game {os.time() - profile.Data.LastPlayed} seconds ago!`)

		Profile.OnLastSave(player):Connect(function()
			print(`Last chance to save data for {player.DisplayName}!`)
			local profile = Profile:GetProfile(player)

			profile.Data.LastPlayed = os.time()
		end)
	end, function(reason)
		print(`Data load for {player.DisplayName} failed because of {reason}!`)
	end)
end

local function PlayerRemoved(player: Player)
	Profile:EndSession(player)
end

for _, player in Players:GetPlayers() do
	Promise.try(PlayerAdded, player)
end

Players.PlayerAdded:Connect(PlayerAdded)
Players.PlayerRemoving:Connect(PlayerRemoved)
