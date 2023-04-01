local p = require('cc.pretty')

local TITLE = "---GANTRY FARM---"
local STATE = ""
local CYCLE_TIME = 40
local SLEEP_TIME = 60
local DIRECTION_SIDE = "top"

function info(newLine)
    term.clear()
    term.setCursorPos(1, 1)
    p.print(p.text(TITLE, colors.grey))
    p.print(p.text(STATE, colors.white))
    p.print(p.text(newLine, colors.green))
end

function verboseWait(time)
    if time < 0 then
        return
    end
    current = 0
    while current < time do
        info("Waiting: "..time-current.." more seconds")
        sleep(1)
        current = current + 1
    end
end

function loop()
    redstone.setOutput(DIRECTION_SIDE, true)
    STATE = "CYCLE"
    verboseWait(CYCLE_TIME) -- TODO: Replace with detection
    redstone.setOutput(DIRECTION_SIDE, false)
end

while true do
    loop()
    STATE = "SLEEP"
    verboseWait(SLEEP_TIME)
end