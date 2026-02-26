local ServerScriptService = game:GetService("ServerScriptService")

local Api = ServerScriptService.Api
local networkingApi = require(Api.Networking)

local profileQuery = require(script.ProfileQuery)

networkingApi.getLastPlayed.On(profileQuery.LastPlayed)
