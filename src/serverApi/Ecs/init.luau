local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Jecs = require(Packages.Jecs)
local Replecs = require(Packages.Replecs)
local Planck = require(Packages.Planck)
local PlanckRunService = require(Packages.PlanckRunService)
local Scheduler = Planck.Scheduler

local Shared = ReplicatedStorage.Shared
local World = require(Shared.Ecs.World)
local Components = require(Shared.Ecs.Components)
local Replicator = require(Shared.Ecs.Replicator).server

local ServerScriptService = game:GetService("ServerScriptService")

local Api = ServerScriptService.Api
local Networking = require(Api.Networking)
local Systems = Api.Ecs.Systems

local state = {}

type SchedulerType = typeof(Scheduler.new(nil :: any, nil :: any))

local function createScheduler(): SchedulerType
	local RunServicePlugin: typeof(PlanckRunService.Plugin.new()) = PlanckRunService.Plugin.new()

	return Scheduler.new(World, state):addPlugin(RunServicePlugin)
end

local scheduler: SchedulerType = createScheduler()

local ecsApi = {}

local REPLICATION_INIT_FINISH = false

function ecsApi:ReplicationInit()
	Networking.ecsReceiveFullWorldData.On(function(player: Player)
		Replicator:mark_player_ready(player)
		return Replicator:get_full(player)
	end)

	REPLICATION_INIT_FINISH = true

	ecsApi:AddSystem(Systems.Replication)
end

function ecsApi:GetScheduler(): typeof(Scheduler.new(nil :: any, nil :: any))
	return scheduler
end

function ecsApi:GetReplicator()
	return Replicator
end

function ecsApi:GetState()
	return state
end

function ecsApi:GetPhases()
	return PlanckRunService.Phases
end

function ecsApi:CreatePlayer(player: Player): typeof(World:entity(nil :: any))
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

function ecsApi:CreateInterval(seconds: number)
	local accumulator = 0
	local last = nil

	return function(): boolean
		local now = os.clock()

		if not last then
			last = now
			return true
		end

		local deltaTime = now - last

		last = now
		accumulator += deltaTime

		if accumulator >= seconds then
			accumulator -= seconds

			return true
		end

		return false
	end
end

function ecsApi:AddSystem(system: ModuleScript)
	scheduler:addSystem(require(system))
end

return ecsApi
