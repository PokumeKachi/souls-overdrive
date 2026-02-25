local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local React = require(Packages.React)

local welcomeGui = require(script.Welcome)
local narratorGui = require(script.Narrator)
local hudGui = require(script.Hud)

return function ()
	local loaded, setLoaded = React.useState(false)

	if not loaded then
		return React.createElement(welcomeGui, {
			cleanupCallback = function()
				setLoaded(true)
			end,
		})
	end

	return React.createElement("Frame", {
		AnchorPoint = Vector2.zero,
		Position = UDim2.new(),
		Size = UDim2.fromScale(1, 1),

		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
	}, {
		React.createElement(narratorGui, {}),
		React.createElement(hudGui, {}),
	})
end
