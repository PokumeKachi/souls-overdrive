-- here we will store RightGrip and the original C0
local rightGrip: Motor6D? = nil
local originalC0: CFrame? = nil

-- the offset you want to add to the grip (5,0,70)
local chopOffset = CFrame.Angles(
    math.rad(5),
    math.rad(0),
    math.rad(70)
)

-- trying to find RightGrip (works for both R15 and R6)
local function ensureRightGrip()
    if rightGrip and rightGrip.Parent then
        return true
    end

    -- R15: RightHand, R6: Right Arm
    local rightLimb = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
    if not rightLimb then
        return false
    end

    -- searching for a Motor6D named RightGrip
    for _, child in ipairs(rightLimb:GetChildren()) do
        if child:IsA("Motor6D") and child.Name == "RightGrip" then
            rightGrip = child
            originalC0 = rightGrip.C0
            print("[Axe] Found RightGrip:", rightGrip, "C0:", originalC0)
            return true
        end
    end

    print("[Axe] RightGrip not found (is the axe actually equipped?)")
    return false
end

local inside = false

local function startAnimation()
    if inside then return end
    inside = true

    -- try finding RightGrip only when entering the tree zone
    if ensureRightGrip() and originalC0 then
        -- adjust the axe position: base C0 * our offset
        rightGrip.C0 = originalC0 * chopOffset
    end

    if not track.IsPlaying then
        track:Play()
    end
end

local function stopAnimation()
    if not inside then return end
    inside = false

    -- reset the grip back to normal
    if rightGrip and originalC0 then
        rightGrip.C0 = originalC0
    end

    if track.IsPlaying then
        track:Stop()
    end
end
