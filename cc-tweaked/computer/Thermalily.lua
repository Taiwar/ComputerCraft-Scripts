local p = require('cc.pretty')

local TITLE = "---THERMALILY---"
local STATE = ""

local RS_IN_SIDES = {"left", "right"}
local FLUID_SIDE = "bottom"
local FLUID_PLACEMENT_TIME = 6

local LOOP_TIMEOUT = 3

local function length(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end
  
local lilyCount = length(RS_IN_SIDES)

local function info(state, task)
    term.clear()
    term.setCursorPos(1, 1)
    p.print(p.text(TITLE, colors.yellow))
    p.print(p.text(state, colors.white))
    p.print(p.text(task, colors.green))
end

local function verboseWait(time)
    if time < 0 then
        return
    end
    local current = 0
    while current < time do
        info(STATE, "Waiting: "..time-current.." more seconds")
        os.sleep(1)
        current = current + 1
    end
end


local function dropLava()
    rs.setAnalogOutput(FLUID_SIDE, 15)
    verboseWait(FLUID_PLACEMENT_TIME)
    rs.setAnalogOutput(FLUID_SIDE, 0)
end

local function checkSignals()
    local shouldDrop = true
    local max = 0
    for _, side in ipairs(RS_IN_SIDES) do
        local input = rs.getAnalogInput(side)
        if input == 0 then
            info("checkSignals", "Lily on "..side.." is working("..input..")")
            shouldDrop = false -- We should wait for all lilies to be done before reading max
        elseif input > max then
            max = input
        end
    end
    return shouldDrop, max
end

local function main()
    info("main", "Checking signals")
    local shouldDrop, max = checkSignals()
    if not shouldDrop then
        info("Main", "Some lilies still working")
        return
    end

    if max == 0 then
        info("Main", "All lilies working")
        return
    end
    local sleepTimeSeconds = max * 20
    STATE = "All lilies not working, waiting for pessimistic cooldown"
    verboseWait(sleepTimeSeconds)
    info("main", "Placing fluid "..lilyCount.." times")
    for _ = 1, lilyCount do
        dropLava()
    end
end

-- Start by dropping lava
STATE = "Placing initial lava "..lilyCount.." times"
for _ = 1, lilyCount do
    dropLava()
end
while true do
    info("Root", "Main")
    main()
    STATE = "Finished cycle, waiting for "..LOOP_TIMEOUT.." seconds"
    verboseWait(LOOP_TIMEOUT)
end