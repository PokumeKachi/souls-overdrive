local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages

local Jecs = require(Packages.Jecs)
local Replecs = require(Packages.Replecs)

local ServerScriptService = game:GetService('ServerScriptService')

local API = ServerScriptService.API

local ecsAPI = require(API.ECS)

local ecsNetworking = {}

function ecsNetworking:ReplicationInit()
	-- local function AutoUpdate(_, _, _)
	--        ecsAPI:Replicate()
	--    end
	--
	-- for name, component in Components do
	--        World:set(component, Jecs.OnAdd, AutoUpdate)
	--        World:set(component, Jecs.OnChange, AutoUpdate)
	--        World:set(component, Jecs.OnRemove, AutoUpdate)
	-- end
end

return ecsNetworking
