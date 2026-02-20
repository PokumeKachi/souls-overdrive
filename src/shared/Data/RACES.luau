local names = {
	"HUMAN",
    -- Normal dude
	"VAMPIRE",
    -- Lifesteal
    -- 2x resistance
    -- 2x damage
    --
    -- Burn under the sun
    -- Cannot use Hamon
    -- Cannot gain EXP
	"SAIYAN",
    -- Deaths still give EXP
    -- 2x EXP gain
    -- 2x damage
    --
    -- 2x energy bar drain
}

local RACES = {}
for i, name in ipairs(names) do
	RACES[name] = i
end

return RACES
