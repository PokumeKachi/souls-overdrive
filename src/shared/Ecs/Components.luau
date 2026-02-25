local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Jecs = require(Packages.Jecs)
local Replecs = require(Packages.Replecs)

local Shared = ReplicatedStorage.Shared
local World = require(Shared.Ecs.World)

local Components = {
	Energy = World:component() :: Jecs.id<number>,
	Player = World:component() :: Jecs.id<number>,
}

for name, component in Components do
	World:set(component, Jecs.Name, name)
	World:add(component, Replecs.shared)
end

return Components
