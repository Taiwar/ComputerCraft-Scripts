comp = require "component"
event = require "event"
serialization = require "serialization"
g = comp.glasses
m = comp.modem

g.removeAll()

base_y = 40
base_x = 10
base_text_scale = 0.8;

function addInfoText(text, y)
    local label = g.addTextLabel()
    label.setPosition(base_x, y)
    label.setScale(base_text_scale)
    label.setColor(255, 20 , 20)
    label.setAlpha(0.8)
    label.setText(text)
end

function displayFuel(fuel, waste, capacity, y)
    local base_width = 100
    local waste_ratio = waste/capacity
    local fuel_ratio = fuel/capacity
    local waste_width = waste_ratio*100
    local fuel_width = fuel_ratio*100
    local capacity_width = base_width - fuel_width + waste_width
    local waste_box = g.addRect()
    local fuel_box = g.addRect()
    local capacity_box = g.addRect()

    capacity_box.setSize(10, capacity_width)
    capacity_box.setPosition(base_x + fuel_width + waste_width, y)
    waste_box.setColor(0.8, 0.8, 0.8)
    waste_box.setAlpha(0.7)

    waste_box.setSize(10, waste_width)
    waste_box.setPosition(base_x + fuel_width, y)
    waste_box.setColor(0.1059, 0, 0.902)
    waste_box.setAlpha(0.9)

    fuel_box.setSize(10, fuel_width)
    fuel_box.setPosition(base_x, y)
    fuel_box.setColor(0.8431, 0.937, 0)
    fuel_box.setAlpha(0.9)

    return tostring(waste_ratio*100).."%"
end

function addBgBox()
    local bg_box = g.addRect()

    bg_box.setSize(34, 134)
    bg_box.setPosition(base_x - 6, base_y - 10)
    bg_box.setColor(0, 0, 0)
    bg_box.setAlpha(0.4)
end

addInfoText("Waiting for signal", base_y)

m.open(8000)

while true do
    local _, receiver, sender, port, _, message = event.pull("modem_message")
    local r_data = serialization.unserialize(message)

    g.removeAll()
    addBgBox()
    if r_data[1] then
        addInfoText("Energy output in RF/t: "..r_data[4], base_y)
        addInfoText("Waste: "..displayFuel(r_data[2], r_data[3], r_data[5], base_y + 10), base_y + 10)
    else
        addInfoText("Reactor offline", base_y)
    end

    os.sleep(1)
end
