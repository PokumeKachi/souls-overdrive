local ServerScriptService = game:GetService("ServerScriptService")

local Api = ServerScriptService.Api

local Networking = require(Api.Networking)

local profileQuery = require(script.ProfileQuery)

Networking.getLastPlayed.On(profileQuery.LastPlayed)
