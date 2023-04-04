local p = require("cc.pretty")

local reactor = peripheral.find("BiggerReactors_Reactor")

local THRESHOLD = .8 -- 80 %
local IDLE_TIMER = 30
local WORKING_TIMER = 60

local capa = reactor.battery().capacity()

local TITLE = "---REACTOR CONTROL---"
local SETTINGS = "Threshold: "..THRESHOLD.." ("..((capa*THRESHOLD)/1000000).."MFE)"

local function info(state, task)
    term.clear()
    term.setCursorPos(1, 1)
    p.print(p.text(TITLE, colors.yellow))
    p.print(p.text(SETTINGS, colors.blue))
    p.print(p.text(state, colors.white))
    p.print(p.text(task, colors.green))
end

while true do
    local stored = reactor.battery().stored()
    info("Checking: "..tostring(reactor.active()), (stored/1000000).." kFE")

    local shouldBeOn = (stored / capa) < THRESHOLD

    if shouldBeOn ~= reactor.active()  then
        reactor.setActive(shouldBeOn)
        if shouldBeOn then
            info("Checking", "Energy stores below threshold ("..(stored/1000000).." kFE). Activating reactor...")
            os.sleep(WORKING_TIMER)
        else
            info("Checking", "Energy stores above threshold ("..(stored/1000000).." kFE). Deactivating reactor...")
            os.sleep(IDLE_TIMER)
        end
    else
        info("Idling: "..tostring(reactor.active()), (stored/1000000).." kFE")
        os.sleep(IDLE_TIMER)
    end
end
