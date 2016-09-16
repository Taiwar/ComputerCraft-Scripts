comp = require "component"
event = require "event"
term = require "term"
serialization = require "serialization"
m = comp.modem
msg = {}

hub_adress = "e853c07a-6923-49e9-97fe-63c9dd1ed497"
tab_functions = {
    [1] = "clear HUD",
    [2] = "show Homescreen",
    [3] = "show Reactor",
    [4] = "terminate HUD"
}

function tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function has_key (tab, key)
    for index, value in pairs(tab) do
        if index == key then
            return true
        end
    end

    return false
end

while true do
    print("Select function:")
    for i=1, tablelength(tab_functions) do
        print(i..":   "..tab_functions[i])
    end

    local cmd = tonumber(io.read())

    if has_key(tab_functions, cmd) == true then
        msg[1] = cmd
        m.send(hub_adress, 8001, serialization.serialize(msg))
    else
        print("requested function: "..cmd.." not available!")
    end
    --term.clear()
end

