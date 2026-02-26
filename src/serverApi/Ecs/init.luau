local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Jecs = require(Packages.Jecs)
local Replecs = require(Packages.Replecs)
local Jabby = require(Packages.Jabby)
local Planck = require(Packages.Planck)
local PlanckRunService = require(Packages.PlanckRunService)
local Scheduler = Planck.Scheduler

local Shared = ReplicatedStorage.Shared
local World = require(Shared.Ecs.World)
local Components = require(Shared.Ecs.Components)
local Replicator = require(Shared.Ecs.Replicator).server

local ServerScriptService = game:GetService("ServerScriptService")

local Api = ServerScriptService.Api
local networkingApi = require(Api.Networking)
local Systems = Api.Ecs.Systems

local state = {}
local scheduler: typeof(Scheduler.new()) = Scheduler.new(World, state):addPlugin(PlanckRunService.Plugin.new())

local ecsApi = {}

function ecsApi:Init()
	networkingApi.ecsReceiveFullWorldData.On(function(player: Player)
		Replicator:mark_player_ready(player)
		return Replicator:get_full(player)
	end)

	ecsApi:AddSystem(Systems._Replication)

	Jabby.register({
		applet = Jabby.applets.world,
		name = "world",
		configuration = {
			world = World,
		},
	})

	return ecsApi
end

function ecsApi:AddSystem(system: ModuleScript)
	scheduler:addSystem(require(system))

	return ecsApi
end

local CreatePlayer = require(script.CreatePlayer)

function ecsApi:CreatePlayer(player: Player): typeof(World:entity(nil :: any))
	return CreatePlayer(player)
end

local CreateInterval = require(script.CreateInterval)

function ecsApi:CreateInterval(seconds: number)
	return CreateInterval(seconds)
end

function ecsApi:GetSystems(): Folder
	return Systems
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

return ecsApi
