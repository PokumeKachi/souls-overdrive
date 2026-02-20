local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages

local Jecs = require(Packages.Jecs)
local Replecs = require(Packages.Replecs)

local World = require(script.Parent.World)

local Components = {
    Energy = World:component(),
}

for name, component in Components do
    World:set(component, Jecs.Name, name)
    World:add(component, Replecs.shared)
end

return Components
