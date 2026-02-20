local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local React = require(Packages.React)
local Signal = require(Packages.Signal)

local welcomeGui = require(script.Welcome)
local narratorGui = require(script.Narrator)

return function()
	local showWelcome, setShowWelcome = React.useState(true)

	local children = {}

	if showWelcome then
		table.insert(
			children,
			React.createElement(welcomeGui, {
				cleanupCallback = function()
					setShowWelcome(false)
				end,
			})
		)
	else
		table.insert(children, React.createElement(narratorGui, {}))
	end

	return React.createElement("ScreenGui", {
		ScreenInsets = Enum.ScreenInsets.None,
	}, children)
end
