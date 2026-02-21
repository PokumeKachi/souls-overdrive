local ServerScriptService = game:GetService("ServerScriptService")

local API = ServerScriptService.API

local ecsAPI = require(API.ECS)

local entities = {}

local ecsPlayer = {}

function ecsPlayer.PlayerAdded(player: Player)
	local entity = ecsAPI:CreatePlayer(player)
	entities[player] = entity
end

return ecsPlayer
