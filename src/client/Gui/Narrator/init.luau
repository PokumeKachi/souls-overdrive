local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Packages = ReplicatedStorage.Packages
local React = require(Packages.React)
local Ripple = require(Packages.ReactRipple)

local Promise = require(Packages.Promise)

local Shared = ReplicatedStorage.Shared
local Networking = require(Shared.Networking)

local ANIMATION_DURATION = 3

local function displayText(text: string, slideInSpring, setMessage)
	slideInSpring:setGoal(1)

	Promise.try(function(setMessage)
		local current = ""

		for i = 1, #text do
			current ..= text:sub(i, i)
			setMessage(current)

			local t = i / #text -- 0 → 1
			local delay = 0.02 + (t ^ 2) * 0.08

			task.wait(delay)
		end
	end, setMessage)
end

return function(props: {
	cleanupCallback: () -> (),
})
	local message, setMessage = React.useState("")

	local slideIn, slideInSpring = Ripple.useSpring(0, {
		tension = 200,
		friction = 50,
		start = true,
	})

	React.useEffect(function()
        local promise = Networking.LastPlayed.Invoke():andThen(function(lastPlayed: number)
		displayText(`It's been quite a while... [CODE: {lastPlayed} SECONDS SINCE LAST CONSCIOUS]`, slideInSpring, setMessage)
        end)
	end, {})

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = slideIn:map(function(value)
			local offset = (1 - value) * 0.1
			return UDim2.fromScale(0.5, 0.5 - offset)
		end),
		Size = UDim2.fromScale(1, 1),

		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
	}, {
		React.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.2),
			Size = UDim2.fromScale(1, 0.5),

			BackgroundTransparency = 1,

			Text = message,
			TextColor3 = Color3.new(1, 1, 1),

			FontFace = Font.new(
				"rbxasset://fonts/families/RobotoMono.json",
				Enum.FontWeight.Regular,
				Enum.FontStyle.Italic
			),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
		}),
	})
end
