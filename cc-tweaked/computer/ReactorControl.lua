local p = require('cc.pretty')

local energyStorage = peripheral.wrap('back')

local THRESHOLD = .8 -- 80 %
local RS_OUT = "bottom"
local IDLE_TIMER = 30
local WORKING_TIMER = 60

local lastSignal = redstone.getOutput(RS_OUT)

local capa = energyStorage.getEnergyCapacity()

p.print(p.text('Iniitialized program with threshold: '..THRESHOLD..' ('..((capa*THRESHOLD)/1000000)..' MFE)', colors.white))
while true do
    p.print(p.text('Checking...', colors.gray))
    local stored = energyStorage.getEnergy()

    local signal = (stored / capa) < THRESHOLD

    if signal ~= lastSignal  then
        if signal then
            p.print(p.text('Energy stores below threshold ('..(stored/1000000)..' kRF). Activating reactor...', colors.green))
        else
            p.print(p.text('Energy stores above threshold ('..(stored/1000000)..' kRF). Deactivating reactor...', colors.blue))
        end
        redstone.setOutput(RS_OUT, signal)
        os.sleep(WORKING_TIMER)
    else
        p.print(p.text('Idling...', colors.gray))
        os.sleep(IDLE_TIMER)
    end
end
