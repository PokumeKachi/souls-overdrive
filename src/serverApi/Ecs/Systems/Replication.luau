local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Promise = require(Packages.Promise)

local ServerScriptService = game:GetService("ServerScriptService")

local Api = ServerScriptService.Api
local networkingApi = require(Api.Networking)
local ecsApi = require(Api.Ecs)

local Interval = ecsApi:CreateInterval(1 / 30)

local function system(world: typeof(ecsApi:GetWorld()), state: typeof(ecsApi:GetState()))
	for player, buf, variants in ecsApi:GetReplicator():collect_updates() do
		Promise.try(function()
			networkingApi.ecsUpdate.Fire(player, buf, variants)
		end)
	end
end

local function check()
	return Interval()
end

return {
	name = "Replication",
	system = system,
	phase = ecsApi:GetPhases().PostUpdate,
	runConditions = {
		check,
	},
}
