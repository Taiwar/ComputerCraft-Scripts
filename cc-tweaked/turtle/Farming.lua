local p = require('cc.pretty')

local TITLE = "---FARMING---"
local STATE = ""

local CROP_TAG = "minecraft:crops"
local START_BLOCK_SLOT = 1
local END_BLOCK_SLOT = 2
local RETURN_HOME_SLOT = 4
local HARVEST_START_SLOT = 5
local PLACEABLE_BLOCK_SLOT = 3

local currentHarvestSlot = HARVEST_START_SLOT
local start = {x=0, y=0, z=0}
local current = {x=0, y=0, z=0}
local path = {current}
local isPathTracing = true
local isFacingForward = true

local function info(state, task)
    term.clear()
    term.setCursorPos(1, 1)
    p.print(p.text(TITLE, colors.yellow))
    p.print(p.text(state, colors.white))
    p.print(p.text(task, colors.green))
end

local function verboseWait(time)
    if time < 0 then
        return
    end
    local current = 0
    while current < time do
        info(STATE, "Waiting: "..time-current.." more seconds")
        os.sleep(1)
        current = current + 1
    end
end

local function isAtStart()
    turtle.select(START_BLOCK_SLOT)
    return turtle.compareDown()
end

local function isAtEnd()
    turtle.select(END_BLOCK_SLOT)
    return turtle.compareDown()
end

local function harvest()
    turtle.select(currentHarvestSlot)
    turtle.placeDown()
    turtle.suckDown()

    -- TODO: Handle crops with seeds and other different mechanics
end

local function isOverFarm()
    local hasBlock, data = turtle.inspectDown()
    -- Check if block has growth metadata
    local isCrop = hasBlock and data["tags"][CROP_TAG]
    return isCrop
end

-- Decide on move and trace path
local function nextMove()
    -- Check if we can move forward and if not, move up
    while turtle.detect() do
        turtle.up()
        current = {x=current.x, y=current.y+1, z=current.z}
        if isPathTracing then
            table.insert(path, current)
        end
    end
    -- Do actual move
    turtle.forward()
    current = {x=current.x+1, y=current.y, z=current.z}
    if isPathTracing then
        table.insert(path, current)
    end
    -- Check if we can move down (we want to be as close to the ground as possible)
    while not turtle.detectDown() do
        turtle.down()
        current = {x=current.x, y=current.y-1, z=current.z}
        if isPathTracing then
            table.insert(path, current)
        end
    end
end

-- Assumption: We move leftwards over the farm
local function laneChange()
    if isFacingForward then
        turtle.turnLeft()
        turtle.forward()
        turtle.turnLeft()
        current = {x=current.x, y=current.y, z=current.z+1}
        if isPathTracing then
            table.insert(path, current)
        end
        isFacingForward = true
    else
        turtle.turnRight()
        turtle.forward()
        turtle.turnRight()
        current = {x=current.x, y=current.y, z=current.z+1}
        if isPathTracing then
            table.insert(path, current)
        end
        isFacingForward = false
    end
end

local function returnToStart()
    -- Trace back path
    for i = #path, 1, -1 do
        local point = path[i]
        while current.x > point.x do
            turtle.back()
            current = {x=current.x-1, y=current.y, z=current.z}
        end
        while current.y > point.y do
            turtle.down()
            current = {x=current.x, y=current.y-1, z=current.z}
        end
        while current.z > point.z do
            turtle.turnRight()
            turtle.forward()
            turtle.turnRight()
            current = {x=current.x, y=current.y, z=current.z-1}
        end
    end
end

local function mainCycle()
    local working = true
    while working do
        STATE = "Farming"
        local forceReturn = turtle.getItemCount(RETURN_HOME_SLOT) > 0
        if forceReturn or isAtEnd() then
            working = false
            -- TODO: Check correctness
            returnToStart()
            if isAtStart() then
                info(STATE, "Finished farming")
            else
                info(STATE, "Error: Not at start")
            end
        else
            info(STATE, "Moving to next block")
            nextMove()
            if isOverFarm() then
                info(STATE, "Harvesting")
                harvest()
            else 
                info(STATE, "Lane change")
                laneChange()
            end
        end
        -- Debug sleep
        os.sleep(0)
    end
end

mainCycle()
print("Finished farming")