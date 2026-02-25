local ServerScriptService = game:GetService("ServerScriptService")

local Api = ServerScriptService.Api

local ecsApi = require(Api.Ecs)

local entities = {}

local ecsPlayer = {}

function ecsPlayer.PlayerAdded(player: Player)
	local entity = ecsApi:CreatePlayer(player)
	entities[player] = entity
end

return ecsPlayer
