local ServerScriptService = game:GetService("ServerScriptService")

local Api = ServerScriptService.Api

local profileApi = require(Api.Profile)

local profilePlayer = {}

function profilePlayer.PlayerAdded(player: Player)
	return profileApi:StartSession(player):andThen(function()
		print(`Profile loaded for {player.DisplayName}!`)

		local profile = profileApi:GetProfile(player)

		print(`Player last joined our game {os.time() - profile.Data.LastPlayed} seconds ago!`)

		profileApi.OnLastSave(player):Connect(function()
			print(`Last chance to save data for {player.DisplayName}!`)
			local profile = profileApi:GetProfile(player)

			profile.Data.LastPlayed = os.time()
		end)

        return profile
	end, function(reason)
		warn(`Data load for {player.DisplayName} failed because of {reason}!`)
	end)
end

function profilePlayer.PlayerRemoved(player: Player)
	profileApi:EndSession(player)
end

return profilePlayer
