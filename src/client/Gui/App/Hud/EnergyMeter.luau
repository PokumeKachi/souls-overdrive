local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Jecs = require(Packages.Jecs)
local Replecs = require(Packages.Replecs)
local React = require(Packages.React)

local Shared = ReplicatedStorage.Shared
local Components = require(Shared.Ecs.Components)

local Api = ReplicatedStorage.Api
local ecsApi = require(Api.Ecs)

return function()
	local energy, setEnergy = React.useState(0)

	ecsApi
		:GetReplicator()
		:hook("changed", Jecs.pair(Replecs.reliable, Components.Energy), function(entity, id, newEnergy)
			print(ecsApi:GetLocalPlayerEntity())
			print(entity)
			print(id)
			print(newEnergy)
		end)

    ecsApi:GetLocalPlayerEntity()

	local uiCorner = React.createElement("UICorner", {
		CornerRadius = UDim.new(0.1),
	})

	return React.createElement("Frame", {
		Position = UDim2.new(0, 10, 0.95, -10),
		Size = UDim2.fromScale(0.2, 0.05),

		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0,
	}, {
		React.createElement("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.fromScale(1, 1),

			BackgroundColor3 = Color3.new(1, 0, 0),
			BackgroundTransparency = 0,
		}, {
			uiCorner,
		}),

		React.createElement("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Thickness = 5,
		}),
		uiCorner,
	})
end
