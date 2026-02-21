local ServerScriptService = game:GetService("ServerScriptService")
local API = ServerScriptService.API

local Networking = require(API.Networking)

local ecsAPI = require(API.ECS)
local Systems = script.Systems

Networking.ecsReceiveFullWorldData.On(ecsAPI.SendFullWorld)

local scheduler = ecsAPI:GetScheduler():addSystem(require(Systems.Replication))
