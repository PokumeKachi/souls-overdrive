local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Api = ReplicatedStorage.Api

local ecsApi = require(Api.Ecs):ReplicationInit()
