local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Jecs = require(Packages.Jecs)
local Replecs = require(Packages.Replecs)

local Shared = ReplicatedStorage.Shared
local World = require(Shared.Ecs.World)
local Components = require(Shared.Ecs.Components)

return function(player: Player): typeof(World:entity(nil :: any))
	local entity = World:entity()

	World:set(entity, Replecs.networked, {
		[player] = true,
	})

	World:add(entity, Jecs.pair(Replecs.reliable, Components.Energy))
	World:set(entity, Components.Energy, 150)

	World:add(entity, Jecs.pair(Replecs.reliable, Components.Player))
	World:set(entity, Components.Player, player.UserId)

	return entity
end
