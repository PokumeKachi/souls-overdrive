local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages

local Jecs = require(Packages.Jecs)
local Replecs = require(Packages.Replecs)

local world = Jecs.world()

local replicator = Replecs.create_client(world)
