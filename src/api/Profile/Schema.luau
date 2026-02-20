local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared

local RACES = require(Shared.Data.RACES)
local STATS = require(Shared.Data.STATS)

local Schema = {
	Cash = 0,
	Level = 0,
    LastPlayed = 0,
    Race = RACES.HUMAN,
    Stats = STATS,
}

return Schema
