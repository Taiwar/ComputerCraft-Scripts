comp = require "component"
event = require "event"
serialization = require "serialization"
g = comp.glasses
m = comp.modem

g.removeAll()

base_y = 40
base_x = 10
base_width = 100
base_text_scale = 0.8
primary_color = {1, 1, 1 }
--primary_color = {0.467, 0, 1 }
primary_color_dark = {primary_color[1] - 0.2, primary_color[2] - 0.2, primary_color[3] - 0.2}

waste_box = 0
fuel_box = 0
r_capacity_end_box = 0
r_capacity_start_box = 0
energy_box = 0
capacity_end_box = 0
capacity_start_box = 0

tab_functions = {
    [1] = function() g.removeAll() end,
    [2] = function() g.removeAll() os.exit() end
}

function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function addInfoText(text, y)
    local label = g.addTextLabel()
    label.setPosition(base_x, y)
    label.setScale(base_text_scale)
    label.setColor(primary_color[1], primary_color[2] , primary_color[3])
    label.setAlpha(0.8)
    label.setText(text)

    return label
end

function initFuelDisplay(y)
    waste_box = g.addRect()
    fuel_box = g.addRect()
    capacity_end_box = g.addRect()
    capacity_start_box = g.addRect()

    capacity_start_box.setSize(10.8, 0.8)
    capacity_start_box.setPosition(base_x - 0.8, y-0.4)
    capacity_start_box.setColor(primary_color_dark[1], primary_color_dark[2] , primary_color_dark[3])

    capacity_end_box.setSize(10.8, 0.8)
    capacity_end_box.setPosition(base_x + base_width, y-0.4)
    capacity_end_box.setColor(primary_color_dark[1], primary_color_dark[2] , primary_color_dark[3])

    waste_box.setColor(0.1059, 0, 0.902)
    waste_box.setAlpha(0.9)

    fuel_box.setColor(0.8431, 0.937, 0)
    fuel_box.setAlpha(0.9)
end

function initPowerDisplay(y)
    energy_box = g.addRect()
    capacity_end_box = g.addRect()
    capacity_start_box = g.addRect()

    capacity_start_box.setSize(10.8, 0.8)
    capacity_start_box.setPosition(base_x - 0.8, y-0.4)
    capacity_start_box.setColor(primary_color_dark[1], primary_color_dark[2] , primary_color_dark[3])

    capacity_end_box.setSize(10.8, 0.8)
    capacity_end_box.setPosition(base_x + base_width, y-0.4)
    capacity_end_box.setColor(primary_color_dark[1], primary_color_dark[2] , primary_color_dark[3])

    --energy_box.setColor(0.3019, 0.8196, 0.8745)
    energy_box.setColor(primary_color[1], primary_color[2] , primary_color[3])
    energy_box.setAlpha(0.9)
end

function updateFuelDisplay(fuel, waste, capacity, y)
    local waste_ratio = waste/capacity
    local fuel_ratio = fuel/capacity
    local waste_width = waste_ratio*100
    local fuel_width = fuel_ratio*100
    --local waste_percentage = tostring(waste_ratio*100).."%"

    waste_box.setSize(10, waste_width)
    waste_box.setPosition(base_x + fuel_width, y)

    fuel_box.setSize(10, fuel_width)
    fuel_box.setPosition(base_x, y)
end

function updatePowerDisplay(energy, capacity, y)
    local energy_ratio = energy/capacity
    local energy_width = energy_ratio*100

    energy_box.setSize(10, energy_width)
    energy_box.setPosition(base_x, y)
end

function addBgBox(y)
    local bg_box_prim = g.addRect()
    local bg_box_sec = g.addRect()

    bg_box_prim.setSize(36, 134)
    bg_box_prim.setPosition(base_x - 6, y - 12)
    bg_box_prim.setColor(primary_color_dark[1], primary_color_dark[2] , primary_color_dark[3])
    bg_box_prim.setAlpha(0.4)

    bg_box_sec.setSize(32, 130)
    bg_box_sec.setPosition(base_x - 4, y - 10)
    bg_box_sec.setColor(0, 0 , 0)
    bg_box_sec.setAlpha(0.6)
end

m.open(8000)
m.open(8001)

addBgBox(base_y)
addBgBox(base_y + 38)
production_info = addInfoText("", base_y)
waste_info = addInfoText("Reactor fuel status:", base_y + 10)
power_info = addInfoText("Capacitor bank power:", base_y + 48)
initFuelDisplay(base_y + 10)
initPowerDisplay(base_y + 45)

production_info.setText("Waiting for signal")

while true do
    local _, _, _, port, _, message = event.pull("modem_message")
    local msg = serialization.unserialize(message)

    if port == 8000 then
        if msg[1] then
            production_info.setText("Energy output in kRF/t: "..msg[4]/1000)
            power_info.setText("Energy stored in kRF: "..msg[6]/1000)
            updateFuelDisplay(msg[2], msg[3], msg[5], base_y + 10)
            updatePowerDisplay(msg[6], msg[7], base_y + 45)
        else
            production_info.setText("Reactor offline")
        end
    elseif port == 8001 then
        print("executing function: "..msg[1])
        tab_functions[msg[1]]()
    end
end
