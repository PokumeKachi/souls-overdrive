local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages

local Replecs = require(Packages.Replecs)

local RunService = game:GetService("RunService")

local World = require(script.Parent.World)

local replicator = Replecs.create(World)

if RunService:IsServer() then
	replicator.server:init(World)
else
	replicator.client:init(World)
end

return replicator
