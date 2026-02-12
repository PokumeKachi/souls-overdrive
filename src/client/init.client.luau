local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages

local Chrono = require(Packages.Chrono)
Chrono.Start()

-- local Tween = require(Packages.TweenPlus)
--
-- local tween = Tween(workspace.Part, {
-- 	Position = Vector3.new(0, 10, 0),
-- 	Color = Color3.fromRGB(255, 255, 0),
-- 	-- And as many more as you’d like.
-- }, { -- Options (optional).
-- 	Time = 50,
-- 	EasingStyle = "Sine",
-- 	EasingDirection = "InOut",
-- })
--
-- tween:Start()
