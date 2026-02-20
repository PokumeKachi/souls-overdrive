local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local React = require(Packages.React)
local Signal = require(Packages.Signal)

local welcomeGui = require(script.Welcome)
local narratorGui = require(script.Narrator)

return function()
	local loaded, setLoaded = React.useState(false)

	local children = {
		React.createElement(narratorGui, {}),
	}

	if not loaded then
		children = {
			React.createElement(welcomeGui, {
				cleanupCallback = function()
					setLoaded(true)
				end,
			}),
		}
	end

	return React.createElement("ScreenGui", {
		ScreenInsets = Enum.ScreenInsets.None,
	}, children)
end
