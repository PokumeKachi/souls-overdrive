local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages

local Jecs = require(Packages.Jecs)

require(Packages.Replecs)
--[[
Replecs uses preregisted components.
You need to require replecs before creating a world, so these components are globally available.
Not doing so causes weird behaviours that are hard to debug.
]]
return Jecs.world()
