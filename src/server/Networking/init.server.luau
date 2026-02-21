local ServerScriptService = game:GetService("ServerScriptService")

local API = ServerScriptService.API

local Networking = require(API.Networking)

local profileQuery = require(script.ProfileQuery)

Networking.getLastPlayed.On(profileQuery.LastPlayed)
