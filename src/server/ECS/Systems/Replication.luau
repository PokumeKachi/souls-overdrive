local ServerScriptService = game:GetService("ServerScriptService")

local API = ServerScriptService.API

local ecsAPI = require(API.ECS)

local Interval = ecsAPI:CreateInterval(1 / 30)

local function system(world: typeof(ecsAPI:GetWorld()), state: typeof(ecsAPI:GetState()))
    ecsAPI:Replicate()
end

local function check()
    return Interval()
end

return {
    name = "Replication",
    system = system,
    phase = ecsAPI:GetPhases().PostUpdate,
    runConditions = {
        check,
    },
}
