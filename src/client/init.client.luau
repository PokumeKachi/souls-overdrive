print("Hello world, from client!")
local UserInputService = game:GetService('UserInputService')

-- 🎥 Realistic Head Bob + Idle Breathing
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local cam = workspace.CurrentCamera

-- SETTINGS
local walkBobIntensity = 0.08
local sprintBobIntensity = 0.15
local swayIntensity = 0.02
local idleBobIntensity = 0.003
local idleBobSpeed = 2
local walkSpeed = 10
local sprintSpeed = 15
local bobSpeed = 5.5

local bobTime = 0
local idleTime = 0
local effectActive = false -- ❌ starts off

-- Create or get the event
local walkEffectEvent = ReplicatedStorage:FindFirstChild("WalkEffectEvent") or Instance.new("BindableEvent")
walkEffectEvent.Name = "WalkEffectEvent"
walkEffectEvent.Parent = ReplicatedStorage

-- Camera movement
RunService.RenderStepped:Connect(function(dt)
	if not effectActive then return end -- 🔒 do nothing until activated

	local moveDir = humanoid.MoveDirection.Magnitude
	local baseCFrame = cam.CFrame

	if moveDir > 0 then
		bobTime += dt * bobSpeed
		local intensity = sprinting and sprintBobIntensity or walkBobIntensity
		local vertical = math.sin(bobTime * 2) * intensity
		local horizontal = math.sin(bobTime) * swayIntensity
		local offset = CFrame.new(horizontal, vertical, 0)
		cam.CFrame = baseCFrame * offset
	else
		idleTime += dt * idleBobSpeed
		local idleOffset = math.sin(idleTime) * idleBobIntensity
		cam.CFrame = baseCFrame * CFrame.new(0, idleOffset, 0)
	end
end)

-- 🔘 Control event
walkEffectEvent.Event:Connect(function(state)
	effectActive = state
end)
