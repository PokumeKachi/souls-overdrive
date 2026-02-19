local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Packages = ReplicatedStorage.Packages
local React = require(Packages.React)
local Ripple = require(Packages.ReactRipple)

local Promise = require(Packages.Promise)

local Shared = ReplicatedStorage.Shared
local assets = require(Shared.assets)

local ANIMATION_DURATION = 3

return function(props: {
	position: UDim2,
	text: string,
	cleanupCallback: () -> (),
})
	local hideBinding, hideTween = Ripple.useTween(0, {
		easing = "expoOut",
		duration = ANIMATION_DURATION,
		start = true,
	})

	React.useEffect(function()
		local inputConnection: RBXScriptConnection

        inputConnection= UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
			if gameProcessedEvent then
				return
			end

			if
				input.UserInputType == Enum.UserInputType.Keyboard
				or input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
                inputConnection:Disconnect()
				hideTween:setGoal(1)
				Promise.delay(ANIMATION_DURATION):andThen(props.cleanupCallback)

				local camera = workspace.CurrentCamera
				local oldFov = 70

				local cameraTween = TweenService:Create(
					workspace.CurrentCamera,
					TweenInfo.new(ANIMATION_DURATION, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
					{
						FieldOfView = oldFov,
					}
				)

				camera.FieldOfView = 120
				cameraTween:Play()
			end
		end)

		return function()
			inputConnection:Disconnect()
		end
	end, {})

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = props.position,
		Size = UDim2.fromScale(1, 1),

		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = hideBinding:map(function(t)
			return t
		end),
	}, {
		React.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = hideBinding:map(function(t)
				return UDim2.fromScale(0.5, 0.4 - 1 * t)
			end),
			Size = hideBinding:map(function(t)
				local scaleX = 0.2 * (1 + 2 * t)
				local scaleY = scaleX
				return UDim2.fromScale(scaleX, scaleY)
			end),

			BackgroundTransparency = 1,

			ImageContent = Content.fromUri(assets.images.groupLogo),
			ScaleType = Enum.ScaleType.Fit,
		}),
		React.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = hideBinding:map(function(t)
				return UDim2.fromScale(0.5, 0.8 + 1 * t)
			end),
			Size = hideBinding:map(function(t)
				local scaleX = 0.4 * (1 + 2 * t)
				local scaleY = 0.1 * (1 + 2 * t)
				return UDim2.fromScale(scaleX, scaleY)
			end),

			BackgroundTransparency = 1,

			Text = props.text,
			TextColor3 = Color3.new(1, 1, 1),
			TextTransparency = hideBinding:map(function(t)
				return t
			end),

			Font = Enum.Font.RobotoMono,
			TextScaled = true,
			AutomaticSize = Enum.AutomaticSize.X,
		}),
	})
end
