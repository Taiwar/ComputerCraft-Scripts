comp = require "component"
event = require "event"
m = comp.modem
r = comp.br_reactor
r_data = {}

while true do
    r_data[1] = r.getConnected();
    r_data[2] = r.getActive();
    r_data[3] = r.getFuelAmount();
    r_data[4] = r.getWasteAmount();
    r_data[5] = r.getEnergyProducedLastTick();
    m.send("e853c07a-6923-49e9-97fe-63c9dd1ed497", 8000, serialization.serialize(r_data))
    os.sleep(1)
end
