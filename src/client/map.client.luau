local InsertService = game:GetService("InsertService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared

local assets = require(Shared.assets)

local model = InsertService:LoadAsset(1234567890)
model.Parent = workspace

local id = tonumber(assets.models.baseplate:match("%d+"))
assert(id, "invalid rbxassetid")
InsertService:LoadAsset(id)
