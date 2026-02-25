local ServerScriptService = game:GetService("ServerScriptService")

local Api = ServerScriptService.Api

local ecsApi = require(Api.Ecs)

-- local Interval = ecsApi:CreateInterval(1 / 30)

local function system(world: typeof(ecsApi:GetWorld()), state: typeof(ecsApi:GetState()))
    -- system logic goes here
end

local function check()
    -- return Interval()
end

return {
    name = "name",
    system = system,
    phase = ecsApi:GetPhases().PostUpdate,
    runConditions = {
        check,
    },
}
