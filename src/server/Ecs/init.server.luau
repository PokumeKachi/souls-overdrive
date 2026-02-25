local ServerScriptService = game:GetService("ServerScriptService")
local Api = ServerScriptService.Api

local Networking = require(Api.Networking)

local ecsApi = require(Api.Ecs):ReplicationInit()
