local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Networking = require(Shared.Networking)
local World = require(Shared.Ecs.World)
local Components = require(Shared.Ecs.Components)
local Replicator = require(Shared.Ecs.Replicator).client

local ecsApi = {}

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local REPLICATION_INIT_FINISH = false

function ecsApi:ReplicationInit()
	Networking.ecsReceiveFullWorldData.Invoke():andThen(function(buf, variants)
		Replicator:apply_full(buf, variants)
	end)

	Networking.ecsUpdate.On(function(buf, variants)
		Replicator:apply_updates(buf, variants)
	end)

    REPLICATION_INIT_FINISH = true

	return self
end

local playerEntity

function ecsApi:GetLocalPlayerEntity(): typeof(World:entity())
    while not REPLICATION_INIT_FINISH do
        task.wait()
    end

	if not playerEntity then
		for entity, userId in World:query(Components.Player) do
			if userId == Player.UserId then
				playerEntity = entity
			end
		end
	end

	return playerEntity
end

function ecsApi:GetReplicator()
	return Replicator
end

return ecsApi
