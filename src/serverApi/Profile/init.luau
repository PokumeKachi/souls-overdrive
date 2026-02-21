local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages
local Promise = require(Packages.Promise)

local ServerStorage = game:GetService("ServerStorage")
local ServerPackages = ServerStorage.Packages
local ProfileStore = require(ServerPackages.ProfileStore)

local Players = game:GetService("Players")

local Schema = require("@self/Schema")
local PlayerStore = ProfileStore.New("PlayerStore", Schema)

type ProfileSession = typeof(PlayerStore:StartSessionAsync())

local Profiles: { [Player]: ProfileSession } = {}

local profileAPI = {}

function profileAPI:GetProfile(player: Player): ProfileSession?
	return Profiles[player]
end

function profileAPI:SetProfile(player: Player, value: ProfileSession?): ()
	Profiles[player] = value
end

function profileAPI:StartSession(player: Player)
	return Promise.new(function(resolve, reject, onCancel)
		local profile: ProfileSession = PlayerStore:StartSessionAsync(`{player.UserId}`, {
			Cancel = function()
				return player.Parent ~= Players
			end,
		})

		if profile ~= nil then
			profile:AddUserId(player.UserId)
			profile:Reconcile()

			profile.OnSessionEnd:Connect(function()
				profileAPI:SetProfile(player, nil)
				player:Kick(`Your data has been loaded on another server - please rejoin`)
			end)

			if player.Parent == Players then
				profileAPI:SetProfile(player, profile)

				resolve(profile)
			else
				profile:EndSession()

				reject("Player left before data was fully loaded")
			end
		else
			player:Kick(`Data load fail - Please rejoin`)

			reject("Loaded data is nil")
		end
	end)
end

function profileAPI:EndSession(player: Player): ()
	local profile = Profiles[player]

	if profile ~= nil then
		profile:EndSession()
	end
end

function profileAPI.OnLastSave(player: Player): RBXScriptSignal
	if Profiles[player] then
		return Profiles[player].OnLastSave
	end
end

function profileAPI.OnSessionEnd(player: Player): RBXScriptSignal
	if Profiles[player] then
		return Profiles[player].OnSessionEnd
	end
end

return profileAPI
