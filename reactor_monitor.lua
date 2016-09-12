comp = require "component"
event = require "event"
serialization = require "serialization"
m = comp.modem
r = comp.br_reactor
r_data = {}

while true do
    r_data["IsActive"] = r.getActive()
    r_data["Fuel in ml"] = r.getFuelAmount()
    r_data["Waste in ml"] = r.getWasteAmount()
    r_data["EnergyOutput in RF/t"] = math.floor(r.getEnergyProducedLastTick())
    m.send("e853c07a-6923-49e9-97fe-63c9dd1ed497", 8000, serialization.serialize(r_data))
    os.sleep(1)
end
