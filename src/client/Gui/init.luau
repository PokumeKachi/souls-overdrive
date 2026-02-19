local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local React = require(Packages.React)

local welcomeGui = require(script.Welcome)

return function()
	local showWelcome, setShowWelcome = React.useState(true)

	local child = welcomeGui

	if showWelcome then
		child = React.createElement(welcomeGui, {
			position = UDim2.fromScale(0.5, 0.5),
			text = "« PRESS ANY KEYS TO PROCEED »",
            cleanupCallback = function()
                setShowWelcome(false)
            end,
		})
	end

	return React.createElement("ScreenGui", {
		ScreenInsets = Enum.ScreenInsets.None,
	}, { child })
end
