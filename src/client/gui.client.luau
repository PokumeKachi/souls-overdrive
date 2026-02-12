local Packages = ReplicatedStorage.Packages

local Vide = require(Packages.Vide)

local create = Vide.create

local gui = create("ScreenGui")({
	create("Frame")({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.4, 0.7),

		create("TextLabel")({
			Text = "hi",
		}),

		create("TextLabel")({
			Text = "bye",
		}),

		create("TextButton")({
			Text = "click me",

			Activated = function()
				print("clicked!")
			end,
		}),
	}),
})

gui.Parent = game.Players.LocalPlayer.PlayerGui
