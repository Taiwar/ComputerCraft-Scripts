local TARGET_SIDE = "back"
local RS_OUT_SIDE = "right"
local CHECK_INTERVAL = 1

local LOWER_THRESHOLD = 0.95
local UPPER_THRESHOLD = 0.99

local target = peripheral.wrap(TARGET_SIDE)

if target == nil then error("Target not found") end

function adjustOutput()
    local max = target.getDangerPressure()
    local current = target.getPressure()
    local proportion = current / max

    print("Pressure at "..(string.format("%.3f", proportion*100)).."%")
    if proportion < LOWER_THRESHOLD then
        print("Lower than lower threshold --> Turning RS on")
        redstone.setOutput(RS_OUT_SIDE, true)
    elseif proportion > UPPER_THRESHOLD then
        print("Higher than upper threshold --> Turning RS off")
        redstone.setOutput(RS_OUT_SIDE, false)
    end
end

while true do
    term.clear()
    term.setCursorPos(1, 1)
    adjustOutput()
    sleep(CHECK_INTERVAL)
end