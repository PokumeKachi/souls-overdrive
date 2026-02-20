local Lifetime = {}

local ServerScriptService = game:GetService("ServerScriptService")
local API = ServerScriptService.API
local Profile = require(API.Profile)

function Lifetime.PlayerAdded(player: Player)
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

function Lifetime.PlayerRemoved(player: Player)
	Profile:EndSession(player)
end

return Lifetime
