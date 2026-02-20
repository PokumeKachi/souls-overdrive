local ServerScriptService = game:GetService("ServerScriptService")

local API = ServerScriptService.API

local Networking = require(API.Networking)
local Profile = require(API.Profile)

Networking.LastPlayed.On(function(Player)
	local profile = Profile:GetProfile(Player)
	local lastPlayed = profile and profile.Data and profile.Data.LastPlayed
	if lastPlayed then
		return os.time() - lastPlayed
	else
		return "INFINITE"
	end
end)
