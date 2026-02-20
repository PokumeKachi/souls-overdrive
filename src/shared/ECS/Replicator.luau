local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages

local Replecs = require(Packages.Replecs)

local RunService = game:GetService("RunService")

local World = require(script.Parent.World)

if RunService:IsServer() then
	return Replecs.create_server(World)
else
	return Replecs.create_client(World)
end
