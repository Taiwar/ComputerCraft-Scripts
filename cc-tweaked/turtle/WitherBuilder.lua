local MAIN_LOOP_TIMER = 20
local WITHER_SPAWN_TIMER = 10
local WITHER_KILL_TIMER = 5

local FLOOR_BLOCK_SLOT = 4

local FUEL_SLOT = 1
local FUEL_ITEM = "minecraft:coal"

local WITHER_BODY_SLOT = 2
local WITHER_BODY_ITEM = "minecraft:soul_sand"
local WITHER_HEAD_SLOT = 3
local WITHER_HEAD_ITEM = "minecraft:wither_skeleton_skull"
-- For testing
-- local WITHER_HEAD_ITEM = "minecraft:sand"

local bridge = peripheral.find("rsBridge")

if bridge == nil then error("rsBridge not found") end

function refuel()
    turtle.select(FUEL_SLOT)

    local fuelCount = turtle.getItemCount(FUEL_SLOT)
    local fuelDiff = 64 - fuelCount

    if fuelDiff > 16 then
        bridge.exportItem({name=FUEL_ITEM, count=fuelDiff}, "bottom")
        sleep(1)
        turtle.suck()
        -- TODO: Check if items actually present
    end


    local level = turtle.getFuelLevel()
    local maxLevel = turtle.getFuelLimit()
    if level / maxLevel < 0.8 then
        local ok, err = turtle.refuel()
        if ok then
            local new_level = turtle.getFuelLevel()
            print(("Refuelled %d, current level is %d"):format(new_level - level, new_level))
        else
            printError(err)
        end
    end
end

function requestMaterials()
    turtle.select(WITHER_BODY_SLOT)
    local bodySlotDetails = turtle.getItemDetail(WITHER_BODY_SLOT)
    local bodySlotDiff = 4
    if bodySlotDetails ~= nil then
        if bodySlotDetails["name"] ~= WITHER_BODY_ITEM then
            print("Item in body slot ("..bodySlotDetails["name"]..") is not "..WITHER_BODY_ITEM)
            return false
        end
        bodySlotDiff = bodySlotDiff - bodySlotDetails["count"]
    end

    if bodySlotDiff > 0 then
        bridge.exportItem({name=WITHER_BODY_ITEM, count=bodySlotDiff}, "bottom")
        sleep(0.5)
        turtle.suck()
        -- TODO: Check if items actually present
    end

    turtle.select(WITHER_HEAD_SLOT)
    local headSlotDetails = turtle.getItemDetail(WITHER_HEAD_SLOT)
    local headSlotDiff = 3
    if headSlotDetails ~= nil then
        if headSlotDetails["name"] ~= WITHER_HEAD_ITEM then
            print("Item in head slot ("..headSlotDetails["name"]..") is not "..WITHER_HEAD_ITEM)
            return false
        end
        headSlotDiff = headSlotDiff - headSlotDetails["count"]
    end

    if headSlotDiff > 0 then
        bridge.exportItem({name=WITHER_HEAD_ITEM, count=headSlotDiff}, "bottom")
        sleep(0.5)
        turtle.suck()
        -- TODO: Check if items actually present
    end


    return true
end

function buildWither()
    buildBody()
    buildHeads()
end

function buildBody()
    turtle.select(WITHER_BODY_SLOT)
    turtle.up()
    turtle.placeDown()
    turtle.up()
    turtle.placeDown()
    turtle.turnRight()
    turtle.forward()
    turtle.placeDown()
    turtle.back()
    turtle.back()
    turtle.placeDown()
    turtle.forward()
    turtle.turnLeft()
end

function buildHeads()
    turtle.select(WITHER_HEAD_SLOT)
    turtle.up()
    turtle.turnLeft()
    turtle.forward()
    turtle.placeDown()
    turtle.back()
    turtle.back()
    turtle.placeDown()
    turtle.forward()
    turtle.turnRight()
    turtle.placeDown()
end

function enterChamber()
    turtle.select(FLOOR_BLOCK_SLOT)
    turtle.digUp()
    turtle.up()
    turtle.up()
    turtle.placeDown()
end

function exitChamber()
    turtle.select(FLOOR_BLOCK_SLOT)
    turtle.dig()
    turtle.forward()
    turtle.forward()
    turtle.turnRight()
    turtle.turnRight()
    turtle.place()
    turtle.down()
    turtle.down()
    turtle.down()
    turtle.down()

    -- Wait for wither spawn
    sleep(WITHER_SPAWN_TIMER)

    -- Kill wither
    redstone.setOutput("back", true)
    sleep(WITHER_KILL_TIMER)
    redstone.setOutput("back", false)

    turtle.forward()
    turtle.dig()
    turtle.forward()
    turtle.down()
    turtle.placeUp()
    turtle.turnRight()
    turtle.turnRight()
end


while true do
    print("Refueling")
    refuel()
    if requestMaterials() then
        print("Successfully Requested materials")
        print("Entering")
        enterChamber()
        print("Building")
        buildWither()
        print("Exiting")
        exitChamber()
    else
        print("Error when requesting materials")
    end
    print("Sleeping")
    sleep(MAIN_LOOP_TIMER)
end