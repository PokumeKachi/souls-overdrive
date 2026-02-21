local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages

local Jecs = require(Packages.Jecs)

local Shared = ReplicatedStorage.Shared

local Networking = require(Shared.Networking)
local Replicator = require(Shared.ECS.Replicator).client
local World = require(Shared.ECS.World)
local Components = require(Shared.ECS.Components)

Networking.ecsReceiveFullWorldData.Invoke():andThen(function(buf, variants)
	Replicator:apply_full(buf, variants)
end)

Networking.ecsUpdate.On(function(buf, variants)
	Replicator:apply_updates(buf, variants)
end)

return nil
