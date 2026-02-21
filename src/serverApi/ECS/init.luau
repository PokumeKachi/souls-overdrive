local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Jecs = require(Packages.Jecs)
local Replecs = require(Packages.Replecs)
local Planck = require(Packages.Planck)
local PlanckRunService = require(Packages.PlanckRunService)
local Scheduler = Planck.Scheduler
local Promise = require(Packages.Promise)

local Shared = ReplicatedStorage.Shared
local World = require(Shared.ECS.World)
local Components = require(Shared.ECS.Components)
local Replicator = require(Shared.ECS.Replicator).server

local ServerScriptService = game:GetService("ServerScriptService")

local API = ServerScriptService.API
local Networking = require(API.Networking)

local RunService = game:GetService("RunService")

local state = {}

type SchedulerType = typeof(Scheduler.new(nil :: any, nil :: any))

local function createScheduler(): SchedulerType
	local RunServicePlugin: typeof(PlanckRunService.Plugin.new()) = PlanckRunService.Plugin.new()

	return Scheduler.new(World, state):addPlugin(RunServicePlugin)
end

local scheduler: SchedulerType = createScheduler()

local ecsAPI = {}

function ecsAPI:GetWorld()
	return World
end

function ecsAPI:GetComponents()
	return Components
end

function ecsAPI:GetReplicator()
	return Replicator
end

function ecsAPI:GetScheduler(): typeof(Scheduler.new(nil :: any, nil :: any))
	return scheduler
end

function ecsAPI:GetState()
	return state
end

function ecsAPI:CreatePlayer(player: Player): typeof(World:entity(nil :: any))
	local entity = World:entity()

	World:add(entity, Replecs.networked)

	World:add(entity, Jecs.pair(Replecs.reliable, Components.Energy))
	World:set(entity, Components.Energy, 150)

	return entity
end

function ecsAPI.SendFullWorld(player: Player)
	Replicator:mark_player_ready(player)
	return Replicator:get_full(player)
end

function ecsAPI:Replicate()
	for player, buf, variants in Replicator:collect_updates() do
		Promise.try(function()
			while not Replicator:is_player_ready(player) do
				task.wait()
			end

			Networking.ecsUpdate.Fire(player, buf, variants)
		end)
	end
end

function ecsAPI:GetPhases()
	return PlanckRunService.Phases
end

function ecsAPI:CreateInterval(seconds: number)
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

return ecsAPI
