local ServerStorage = game:GetService("ServerStorage")
local Packages = ServerStorage.Packages
local ProfileStore = require(Packages.ProfileStore)

local PROFILE_SCHEMA = {
	Cash = 0,
	Level = 0,
}

local Players = game:GetService("Players")

local PlayerStore = ProfileStore.New("PlayerStore", PROFILE_SCHEMA)
local Profiles: { [Player]: typeof(PlayerStore:StartSessionAsync()) } = {}

local function PlayerAdded(player: Player)
	local profile: typeof(PlayerStore:StartSessionAsync()) = PlayerStore:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile ~= nil then
        profile:AddUserId(player.UserId)
        profile:Reconcile()

        profile.OnSessionEnd:Connect(function()
            Profiles[player] = nil
            player:Kick(`Profile session end - Please rejoin`)
        end)

        if player.Parent == Players then
            Profiles[player] = profile
            print(`Profile loaded for {player.DisplayName}!`)
        else
            profile:EndSession()
        end
	else
		player:Kick(`Data load fail - Please rejoin`)
	end
end

for _, player in Players:GetPlayers() do
   task.spawn(PlayerAdded, player)
end

Players.PlayerAdded:Connect(PlayerAdded)

Players.PlayerRemoving:Connect(function(player)
   local profile = Profiles[player]
   if profile ~= nil then
      profile:EndSession()
   end
end)
