comp = require "component"
event = require "event"
serialization = require "serialization"
m = comp.modem
r = comp.br_reactor
c = comp.capacitor_bank
msg_data = {}

hub_adress = "e853c07a-6923-49e9-97fe-63c9dd1ed497"

while true do
    msg_data[1] = r.getActive()
    msg_data[2] = r.getFuelAmount()
    msg_data[3] = r.getWasteAmount()
    msg_data[4] = math.floor(r.getEnergyProducedLastTick())
    msg_data[5] = r.getFuelAmountMax()
    msg_data[6] = c.getEnergyStored()
    msg_data[7] = c.getMaxEnergyStored()
    m.send(hub_adress, 8000, serialization.serialize(msg_data))
    os.sleep(1)
end
