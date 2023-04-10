local p = require("cc.pretty")

local reactor = peripheral.find("BiggerReactors_Reactor")

local IDLE_TIMER = 60
local REFRESH_TIMER = 3

local capacity = reactor.battery().capacity()

local TITLE = "---REACTOR CONTROL---"
local CAPACITY = "Capacity: "..(capacity/1000000).." MFE"
local STATE = "Getting initial sample"
local lastDelta = 0

local TPS = 20

local function info(stored, rodLevel, temp, delta, task)
    local d = (math.floor(delta) == 0 and lastDelta) or delta
    term.clear()
    term.setCursorPos(1, 1)
    p.print(p.text(TITLE, colors.yellow))
    p.print(p.text(CAPACITY, colors.blue))
    p.print(p.text("Rods level: "..rodLevel, colors.orange))
    p.print(p.text("Temperature: "..string.format("%.2f", temp).." K", colors.red))
    p.print(p.text("Stored: "..string.format("%.2f", stored/1000000).." MFE", colors.green))
    p.print(p.text("Flow: "..string.format("%.2f", (-1*d/1000)/TPS).." kFE/t", (d <= 0 and colors.green) or colors.red))
    p.print(p.text("-------------", colors.lightGray))
    p.print(p.text("State: "..STATE, colors.white))
    p.print(p.text("Task: "..task, colors.white))
end

local function getCurrentRodLevel()
    local rodCount = reactor.controlRodCount()
    local totalRodLevel = 0
    for i = 0, rodCount-1, 1 do
        totalRodLevel = totalRodLevel + reactor.getControlRod(i).level()
    end
    return totalRodLevel / rodCount
end

local function verboseWait(time, label)
    if time < 0 then
        return
    end
    local current = 0
    local lastStored = reactor.battery().stored()
    while current < time do
        local stored = reactor.battery().stored()
        local delta = lastStored - stored
        local rodLevel = math.floor(getCurrentRodLevel())
        local temp = reactor.casingTemperature()
        info(stored, rodLevel, temp, delta, label.." "..time-current.."s...")
        os.sleep(1)
        current = current + 1
    end
end

local function waitForStableTemp()
    repeat
        local last = reactor.casingTemperature()
        verboseWait(REFRESH_TIMER, "Waiting for temp stabilization")
        local current = reactor.casingTemperature()
    until math.abs(last - current) < 1
end

local lastStored = reactor.battery().stored()
local currentRodLevel = math.floor(getCurrentRodLevel())
verboseWait(1, "Waiting")
while true do
    local currentStored = reactor.battery().stored()
    -- positive delta -> losing energy, negative delta -> gaining energy
    local delta = lastStored - currentStored
    if delta > 0 then
            -- if we're losing energy, retract rods one step
        lastDelta = delta
        currentRodLevel = currentRodLevel - 1
        reactor.setAllControlRodLevels(currentRodLevel)
        STATE = "Powering up"
        waitForStableTemp()
    elseif lastDelta > 0 then
        -- if we're not losing energy and last time we were, we can idle for a bit
        lastDelta = delta
        STATE = "Idling"
        verboseWait(IDLE_TIMER, "Waiting")
    else
        -- if we're not losing energy and last time we weren't either, we try extending rods
        currentRodLevel = currentRodLevel + 1
        reactor.setAllControlRodLevels(currentRodLevel)
        STATE = "Powering down"
        waitForStableTemp()
    end
end
