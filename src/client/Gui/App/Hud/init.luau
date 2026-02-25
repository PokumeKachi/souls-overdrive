local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local React = require(Packages.React)

local EnergyMeter = require(script.EnergyMeter)

return function()
	return React.createElement("Frame", {
		Position = UDim2.new(),
		Size = UDim2.fromScale(1, 1),

		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
	}, {
		React.createElement(EnergyMeter),
	})
end
