local p = require('cc.pretty')

local depot = peripheral.wrap('bottom')

function getDepotItem()
    return depot.list()[1]
end

function freeSlot(original, current)
    if turtle.getItemCount(current) == 0 then
        if original ~= current then
            turtle.select(original)
            turtle.transferTo(current)
            turtle.select(original)
        end
        return true
    else
        local next = (current + 1) % 16
        if next == current then
            return false
        else
            return freeSlot(original, next)
        end
    end
end


-- TODO: Handle products that are more than inputs? (could be more than 1 stack output)
-- TODO: Optimize smelt-times by merging stacks
while true do
    os.pullEvent('turtle_inventory')
    p.print(p.text('Inv changed, smelting...', colors.blue))
    for slot = 1, 16 do
        local slotItem = turtle.getItemDetail(slot)
        if slotItem ~= nil then
            p.print(p.text('Smelting: ', colors.blue)..p.text(slot..' ('..slotItem.name..')', colors.orange))
            turtle.select(slot)
            if not turtle.dropDown() then
                error('Couldn\'t drop items to smelt!')
            end
            local timeout = 30
            repeat
                os.sleep(1)
                timeout = timeout - 1
            until slotItem.name ~= getDepotItem().name or timeout < 1
            if freeSlot(slot, slot) then
                turtle.suckDown()
                turtle.drop()
                p.print(p.text('Exporting: ', colors.blue) .. p.text(tostring(slot), colors.orange))
            else
                error('Couldn\'t pick up smelted items: Inventory full!')
            end
        end
    end
    p.print(p.text('Done', colors.blue))
end