local p = require('cc.pretty')

local RS_IN = "front"
local POWER_SIDE = "top"
local POWER_COLOR = colors.white
local DIRECTION_SIDE = "left"
local DIRECTION_COLOR = colors.orange
local DOOR_SIDE = "right"
local DOOR_COLOR = colors.magenta
local GATE_SIDE = "bottom"
local GATE_COLOR = colors.lightBlue
local SPIN_UP_TIMER = 1
local WIND_DOWN_TIMER = 5
local DOOR_TIMER = 3
local GATE_TIMER = 7

function setInactive()
    redstone.setOutput(POWER_SIDE, false)
    redstone.setOutput(DIRECTION_SIDE, false)
    redstone.setOutput(DOOR_SIDE, true)
    redstone.setOutput(GATE_SIDE, true)
end

function drawPrompt()
    term.clear()
    term.setCursorPos(1, 1)
    p.print(p.text('Door Control', colors.blue))
    p.print(p.text('[1]: Open'))
    p.print(p.text('[2]: Close'))
    p.print(p.line)
end

while true do
    setInactive()
    drawPrompt()
    p.write(p.text('Input command: ', colors.grey))
    local input = read()
    if input == '1' then
        p.print(p.text('Opening', colors.green))
        redstone.setOutput(DIRECTION_SIDE, true)
        print('reverse')
        print('gate')
        redstone.setOutput(DOOR_SIDE, true)
        redstone.setOutput(GATE_SIDE, false)
        redstone.setOutput(POWER_SIDE, true)
        os.sleep(SPIN_UP_TIMER)
        os.sleep(GATE_TIMER)
        print('door')
        redstone.setOutput(DIRECTION_SIDE, false)
        redstone.setOutput(DOOR_SIDE, false)
        redstone.setOutput(GATE_SIDE, true)
        os.sleep(DOOR_TIMER)
        redstone.setOutput(POWER_SIDE, false)

        os.sleep(WIND_DOWN_TIMER)
    elseif input == '2' then
        p.print(p.text('Closing', colors.red))
        redstone.setOutput(DIRECTION_SIDE, false)
        print('forward')
        print('door')
        redstone.setOutput(DOOR_SIDE, false)
        redstone.setOutput(GATE_SIDE, true)
        redstone.setOutput(POWER_SIDE, true)
        os.sleep(SPIN_UP_TIMER)
        os.sleep(GATE_TIMER)
        print('gate')
        redstone.setOutput(DIRECTION_SIDE, true)
        print('reverse')
        redstone.setOutput(DOOR_SIDE, true)
        redstone.setOutput(GATE_SIDE, false)
        os.sleep(DOOR_TIMER)
        redstone.setOutput(POWER_SIDE, false)

        os.sleep(WIND_DOWN_TIMER)
    else
        p.print(p.text('Unknown command'), colors.red)
        os.sleep(1)
    end
end
