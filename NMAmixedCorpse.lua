-- ========== CIRCLE TWEEN TEST ==========
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

local CIRCLE_RADIUS = 30
local CIRCLE_PERIOD = 2.4  -- giây / 1 vòng

local SAINTS_PARTS = {
    "SaintsLeftArm","SaintsRibcage","SaintsRightArm","SaintsLeftLeg","SaintsRightLeg",
}

local circleConnection = nil
local direction = 1
local startTime = tick()

-- ========== KIỂM TRA CORPSE ==========
local function hasCorpse()
    local char = localPlayer.Character
    if not char then return false end

    -- Tìm trực tiếp trong character
    if char:FindFirstChild("Corpse") then return true end

    -- Tìm trong Entities nếu game dùng cấu trúc đó
    local entities = workspace:FindFirstChild("Entities")
    if entities then
        local myEntity = entities:FindFirstChild(localPlayer.Name)
        if myEntity and myEntity:FindFirstChild("Corpse", true) then
            return true
        end
    end

    return false
end

-- ========== SAINTS PART ==========
local function getHeldSaintPart()
    local char = localPlayer.Character
    if not char then return nil end

    for _, name in ipairs(SAINTS_PARTS) do
        local part = char:FindFirstChild(name)
        if part then return part, name end
    end

    local entities = workspace:FindFirstChild("Entities")
    if entities then
        local myEntity = entities:FindFirstChild(localPlayer.Name)
        if myEntity then
            for _, name in ipairs(SAINTS_PARTS) do
                local part = myEntity:FindFirstChild(name, true)
                if part then return part, name end
            end
        end
    end

    return nil
end

-- ========== STOP / START ==========
local function stopCircle()
    if circleConnection then
        circleConnection:Disconnect()
        circleConnection = nil
    end
end

local function scheduleDirectionFlip()
    local delay = math.random(2, 5)
    task.delay(delay, function()
        if circleConnection then
            direction = -direction
            startTime = tick()
            scheduleDirectionFlip()
        end
    end)
end

local function startCircle()
    if circleConnection then return end
    startTime = tick()
    direction = 1
    scheduleDirectionFlip()

    circleConnection = RunService.Heartbeat:Connect(function()
        -- ✅ Dừng ngay nếu corpse biến mất
        if not hasCorpse() then
            stopCircle()
            return
        end

        local part, name = getHeldSaintPart()
        if not part then
            stopCircle()
            return
        end

        local char = localPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local elapsed = tick() - startTime
        local angle   = (elapsed / CIRCLE_PERIOD) * (2 * math.pi) * direction
        local center  = hrp.Position

        hrp.CFrame = CFrame.new(
            Vector3.new(
                center.X + CIRCLE_RADIUS * math.cos(angle),
                center.Y,
                center.Z + CIRCLE_RADIUS * math.sin(angle)
            )
        ) * CFrame.Angles(0, -angle * direction, 0)
    end)
end

-- ========== MAIN LOOP ==========
RunService.Heartbeat:Connect(function()
    local hasPart  = getHeldSaintPart() ~= nil
    local corpseOk = hasCorpse()

    if hasPart and corpseOk and not circleConnection then
        startCircle()
    elseif (not hasPart or not corpseOk) and circleConnection then
        -- ✅ Dừng nếu mất saints part HOẶC mất corpse
        stopCircle()
    end
end)

print("✅ Circle Test loaded!")
