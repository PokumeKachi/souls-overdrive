local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local React = require(Packages.React)
local Ripple = require(Packages.ReactRipple)

local Promise = require(Packages.Promise)

local Shared = ReplicatedStorage.Shared
local Networking = require(Shared.Networking)

local TEXT_DURATION = 3

local function displayText(text: string, slideInSpring, setMessage)
	slideInSpring:setGoal(1)

	Promise.try(function()
		local current = ""

		for i = 1, #text do
			current ..= text:sub(i, i)
			setMessage(current)
			task.wait(0.02 + (i / #text) ^ 2 * 0.08)
		end

		return Promise.delay(TEXT_DURATION)
	end):andThen(function()
		slideInSpring:setGoal(0)

		for i = #text, 1, -3 do
			setMessage(text:sub(1, i - 1))
			task.wait()
		end

		setMessage("")
	end)
end

return function(props: {
	cleanupCallback: () -> (),
})
	local message, setMessage = React.useState("")

	local slideIn, slideInSpring = Ripple.useSpring(0, {
		tension = 50,
		friction = 20,
		start = true,
	})

	React.useEffect(function()
		Networking.getLastPlayed.Invoke():andThen(function(lastPlayed: number)
			displayText(
				`It's been quite a while... [CODE: {lastPlayed} SECONDS SINCE LAST CONSCIOUS]`,
				slideInSpring,
				setMessage
			)
		end)
	end, {})

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = slideIn:map(function(value)
			local offset = (1 - value) * 0.5
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
