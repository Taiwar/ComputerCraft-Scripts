comp = require "component"
    event = require "event"
    serialization = require "serialization"
    g = comp.glasses
    m = comp.modem

    g.removeAll()

    base_y = 50;
    x = 10;

    function addInfoText(text, iteration)
        local label = g.addTextLabel()
        label.setPosition(x, 50 + iteration*10)
        label.setScale(1)
        label.setColor(255, 20 , 20)
        label.setAlpha(0.8)
        label.setText(text)
    end

    addInfoText("Waiting for signal", 0)


    m.open(8000)

    while true do
        local counter = 0
        local _, receiver, sender, port, _, message = event.pull("modem_message")
        local r_data = serialization.unserialize(message)
        g.removeAll()
        for k, v in pairs( r_data ) do
            if k == "IsActive" and v == false then
                g.removeAll()
                addInfoText("Reactor offline", 0)
                break
            elseif k ~= "IsActive" then
                addInfoText(k..": "..tostring(v), counter)
                counter = counter + 1
            end
        end
        os.sleep(1)
    end
