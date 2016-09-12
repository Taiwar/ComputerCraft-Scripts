comp = require "component"
event = require "event"
serialization = require "serialization"
g = comp.glasses
m = comp.modem

g.removeAll()

function addInfoText(text)
    local label = g.addTextLabel()
    label.setPosition(10, 50)
    label.setScale(1)
    label.setColor(255, 20 , 20)
    label.setAlpha(0.8)
    label.setText(text)
end

addInfoText("Waiting for signal")

r_data = {};

m.open(8000)

while true do
    local _, receiver, sender, port, _, message = event.pull("modem_message")
    --print("Got a message from " .. sender .. " on port " .. receiver .. ":"..port..": " .. tostring(message))
    r_data = serialization.unserialize(message)
    for k, v in pairs(r_data) do
        addInfoText(k..": "..v)
    end
    os.sleep(1)
end
