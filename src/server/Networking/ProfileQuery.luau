local ServerScriptService = game:GetService("ServerScriptService")

local Api = ServerScriptService.Api

local Profile = require(Api.Profile)

local profileQuery = {}

function profileQuery.LastPlayed(Player)
	local profile = Profile:GetProfile(Player)
	local lastPlayed = profile and profile.Data and profile.Data.LastPlayed
	if lastPlayed then
		return os.time() - lastPlayed
	else
		return "INFINITE"
	end
end

return profileQuery
