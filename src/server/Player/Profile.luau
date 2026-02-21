local ServerScriptService = game:GetService("ServerScriptService")

local API = ServerScriptService.API

local profileAPI = require(API.Profile)

local profilePlayer = {}

function profilePlayer.PlayerAdded(player: Player)
	return profileAPI:StartSession(player):andThen(function()
		print(`Profile loaded for {player.DisplayName}!`)

		local profile = profileAPI:GetProfile(player)

		print(`Player last joined our game {os.time() - profile.Data.LastPlayed} seconds ago!`)

		profileAPI.OnLastSave(player):Connect(function()
			print(`Last chance to save data for {player.DisplayName}!`)
			local profile = profileAPI:GetProfile(player)

			profile.Data.LastPlayed = os.time()
		end)

        return profile
	end, function(reason)
		warn(`Data load for {player.DisplayName} failed because of {reason}!`)
	end)
end

function profilePlayer.PlayerRemoved(player: Player)
	profileAPI:EndSession(player)
end

return profilePlayer
