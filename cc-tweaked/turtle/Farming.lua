local p = require('cc.pretty')

local TITLE = "---FARMING---"
local STATE = ""

local CROP_TAG = "minecraft:crops"
local START_BLOCK_SLOT = 1
local END_BLOCK_SLOT = 2
local PLACEABLE_BLOCK_SLOT = 5
local RETURN_HOME_SLOT = 4
local HARVEST_START_SLOT = 5

local currentHarvestSlot = HARVEST_START_SLOT
local start = {x=0, y=0, z=0}
local current = {x=0, y=0, z=0}
local path = {current}
local isPathTracing = true
local isFacingForward = true
local log = {}

local function info(state, task)
    term.clear()
    term.setCursorPos(1, 1)
    p.print(p.text(TITLE, colors.yellow))
    p.print(p.text(state, colors.white))
    p.print(p.text(task, colors.green))
    -- Append log
    table.insert(log, {state=state, task=task, position=current})
end

local function dumpLogToFile()
    local file = io.open("log.txt", "w")
    if file == nil then
        error("Could not open file")
    end
    for i, entry in ipairs(log) do
        file.write(entry.state..": "..entry.task.."\n")
    end
    file.close()
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

local function checkStartingConditions()
    -- Check that we have all the necessary blocks
    if not (turtle.getItemCount(START_BLOCK_SLOT) > 0) then
        error("Missing start block")
    end
    if not (turtle.getItemCount(END_BLOCK_SLOT) > 0) then
        error("Missing end block")
    end
    if not (turtle.getItemCount(PLACEABLE_BLOCK_SLOT) > 0) then
        error("Missing placeable block")
    end
    if turtle.getItemCount(RETURN_HOME_SLOT) > 0 then
        error("Debug: Return home slot is not empty")
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

-- TODO: Extend to consider z axis
local function contextAwareForward(notModifyCurrent)
    turtle.forward()
    if notModifyCurrent then
        return
    end
    if isFacingForward then
        current = {x=current.x+1, y=current.y, z=current.z}
    else
        current = {x=current.x-1, y=current.y, z=current.z}
    end
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

local function shouldMoveDown()
    local hasBlock, data = turtle.inspectDown()
    if hasBlock then
        STATE = "Last detected block: "..data["name"].." at "..current.x..", "..current.y..", "..current.z
    else
        STATE = "Last detected block: None at "..current.x..", "..current.y..", "..current.z
    end
    return not hasBlock and data["name"] ~= "minecraft:water"
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
    contextAwareForward()
    if isPathTracing then
        table.insert(path, current)
    end
    -- Check if we can move down (we want to be as close to the ground as possible)

    -- Check if we can move down or if there is water
    while shouldMoveDown() do
        turtle.down()
        current = {x=current.x, y=current.y-1, z=current.z}
        if isPathTracing then
            table.insert(path, current)
        end
    end
end

local function handleFieldCrossing()
    local success = false;
    -- Check if block below is water
    local hasBlock, data = turtle.inspectDown()
    if hasBlock and data["name"] == "minecraft:water" then
        print("Found water, crossing")
       -- Expect single block wide water streak -> Turn and move one more block
       if not isFacingForward then
            turtle.turnRight()
            contextAwareForward(true)
            turtle.turnLeft()
            current = {x=current.x, y=current.y, z=current.z+1}
            if isPathTracing then
                table.insert(path, current)
            end
        else
            turtle.turnLeft()
            contextAwareForward(true)
            turtle.turnRight()
            current = {x=current.x, y=current.y, z=current.z+1}
            if isPathTracing then
                table.insert(path, current)
            end
        end
        success = true
    end
    -- Check if block below is farmland now
    hasBlock, data = turtle.inspectDown()
    if hasBlock and data["name"] == "minecraft:farmland" then
        print("Found farm again, finishing crossing")
        success = true
    else
        -- Expect field may have gotten shorter -> Move forward until we are over the field
        local tries = 5
        print("Moving forward to find farm")
        while not isOverFarm() and tries > 0 do
            nextMove()
            tries = tries - 1
        end
        success = tries > 0
    end
    return success;
end

-- Assumption: We move leftwards over the farm
local function laneChange()
    if isFacingForward then
        turtle.turnLeft()
        contextAwareForward(true)
        turtle.turnLeft()
        current = {x=current.x, y=current.y, z=current.z+1}
        if isPathTracing then
            table.insert(path, current)
        end
        isFacingForward = false
    else
        turtle.turnRight()
        contextAwareForward(true)
        turtle.turnRight()
        current = {x=current.x, y=current.y, z=current.z+1}
        if isPathTracing then
            table.insert(path, current)
        end
        isFacingForward = true
    end
end

-- TODO: Check correctness
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
            contextAwareForward(true)
            turtle.turnRight()
            current = {x=current.x, y=current.y, z=current.z-1}
        end
    end
end

local function mainCycle()
    local working = true
    while working do
        local forceReturn = turtle.getItemCount(RETURN_HOME_SLOT) > 0
        if forceReturn or isAtEnd() then
            dumpLogToFile()
            working = false
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
                if not isOverFarm() then
                    info(STATE, "Field crossing")
                    local success = handleFieldCrossing()
                    if not success then
                        info(STATE, "Error: Could not find farm")
                        working = false
                        returnToStart()
                    end
                end
            end
        end
        -- Debug sleep
        os.sleep(1)
    end
end
-- Equip harvest tool
turtle.select(HARVEST_START_SLOT)
turtle.equipLeft()

checkStartingConditions()
mainCycle()
print("Finished farming")