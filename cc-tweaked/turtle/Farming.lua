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
local facing = "north" -- Relative
local log = {}

---- START UTILITY FUNCTIONS ----

local function info(state, task)
    term.clear()
    term.setCursorPos(1, 1)
    p.print(p.text(TITLE, colors.yellow))
    p.print(p.text(state, colors.white))
    p.print(p.text(task, colors.green))
    -- Append log
    table.insert(log, {level="info", text=state.." - "..task, position=current})
end

local function debug(message)
    p.print(p.text(message, colors.lightGray))
    -- Append log
    table.insert(log, {level="debug", text=message, position=current})
end

local function dumpLogToFile()
    local file = fs.open("log.txt", "w+")
    if file == nil then
        error("Could not open file")
    end
    for i, entry in ipairs(log) do
        file.write(entry["level"]..": "..entry["text"].." at xyz "..entry["position"]["x"]..", "..entry["position"]["y"]..", "..entry["position"]["z"].."\n")
    end
    file.close()
end

local function dumpPositionLogToFile()
    local file = fs.open("position_log.txt", "w")
    if file == nil then
        error("Could not open file")
    end
    -- TODO: This may have side effects
    -- Add index field to each path entry
    for i, entry in ipairs(path) do
        entry["index"] = i
    end

    local logTable = {current=current, facing=facing, path=path}
    file.write(textutils.serialize(logTable, {allow_repetitions=true}))
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

---- END UTILITY FUNCTIONS ----

---- START BASIC MOVEMENT FUNCTIONS ----

local function contextAwareForward()
    local success = turtle.forward()
    if not success then
        return false
    end
    if facing == "north" then
        current = {x=current.x, y=current.y, z=current.z-1}
    elseif facing == "east" then
        current = {x=current.x+1, y=current.y, z=current.z}
    elseif facing == "south" then
        current = {x=current.x, y=current.y, z=current.z+1}
    elseif facing == "west" then
        current = {x=current.x-1, y=current.y, z=current.z}
    end
    return true
end

local function contextAwareBack()
    local success = turtle.back()
    if not success then
        return false
    end
    if facing == "north" then
        current = {x=current.x, y=current.y, z=current.z+1}
    elseif facing == "east" then
        current = {x=current.x-1, y=current.y, z=current.z}
    elseif facing == "south" then
        current = {x=current.x, y=current.y, z=current.z-1}
    elseif facing == "west" then
        current = {x=current.x+1, y=current.y, z=current.z}
    end
    return true
end

local function contextAwareTurnRight()
    turtle.turnRight()
    if facing == "north" then
        facing = "east"
    elseif facing == "east" then
        facing = "south"
    elseif facing == "south" then
        facing = "west"
    elseif facing == "west" then
        facing = "north"
    end
end

local function contextAwareTurnLeft()
    turtle.turnLeft()
    if facing == "north" then
        facing = "west"
    elseif facing == "west" then
        facing = "south"
    elseif facing == "south" then
        facing = "east"
    elseif facing == "east" then
        facing = "north"
    end
end

local function contextAwareDown()
    local success = turtle.down()
    if not success then
        return false
    end
    current = {x=current.x, y=current.y-1, z=current.z}
    return success
end

local function contextAwareUp()
    local success = turtle.up()
    if not success then
        return false
    end
    current = {x=current.x, y=current.y+1, z=current.z}
    return success
end

local function faceDirection(direction)
    if facing == direction then
        return
    elseif facing == "north" then
        if direction == "east" then
            contextAwareTurnRight()
        elseif direction == "south" then
            contextAwareTurnRight()
            contextAwareTurnRight()
        elseif direction == "west" then
            contextAwareTurnLeft()
        end
    elseif facing == "east" then
        if direction == "south" then
            contextAwareTurnRight()
        elseif direction == "west" then
            contextAwareTurnRight()
            contextAwareTurnRight()
        elseif direction == "north" then
            contextAwareTurnLeft()
        end
    elseif facing == "south" then
        if direction == "west" then
            contextAwareTurnRight()
        elseif direction == "north" then
            contextAwareTurnRight()
            contextAwareTurnRight()
        elseif direction == "east" then
            contextAwareTurnLeft()
        end
    elseif facing == "west" then
        if direction == "north" then
            contextAwareTurnRight()
        elseif direction == "east" then
            contextAwareTurnRight()
            contextAwareTurnRight()
        elseif direction == "south" then
            contextAwareTurnLeft()
        end
    end
end

---- END BASIC MOVEMENT FUNCTIONS ----

local function harvest()
    turtle.select(currentHarvestSlot)
    turtle.placeDown()
    turtle.suckDown()

    -- TODO: Handle crops with seeds and other different mechanics
end

---- START FARMING FUNCTIONS ----

local function isOverFarm()
    local hasBlock, data = turtle.inspectDown()
    -- Check if block has growth metadata
    local isCrop = hasBlock and data["tags"][CROP_TAG]
    return isCrop
end

local function isFacingObstacle()
    local hasBlock, data = turtle.inspect()
    if not hasBlock then
        return false
    end
    -- Check if block has growth metadata
    local isCrop = data["tags"][CROP_TAG]
    return not isCrop
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
        local s = contextAwareUp()
        if s and isPathTracing then
            table.insert(path, current)
            dumpPositionLogToFile()
        end
    end
    -- Do actual move
    local s = contextAwareForward()
    if s and isPathTracing then
        table.insert(path, current)
        dumpPositionLogToFile()
    end
    -- Check if we can move down (we want to be as close to the ground as possible)

    -- Check if we can move down or if there is water
    while shouldMoveDown() do
        s = contextAwareDown()
        if s and isPathTracing then
            table.insert(path, current)
            dumpPositionLogToFile()
        end
    end
end

-- TODO: Handle obstacles/lane size changes
local function handleFieldCrossing()
    local success = false;
    -- Check if block below is water
    local hasBlock, data = turtle.inspectDown()
    if hasBlock and data["name"] == "minecraft:water" then
        debug("Found water, crossing")
       -- Expect single block wide water streak -> Turn and move one more block
       if facing == "south" then
            contextAwareTurnRight()
            local s = contextAwareForward()
            contextAwareTurnLeft()
            if s and isPathTracing then
                table.insert(path, current)
                dumpPositionLogToFile()
            end
        elseif facing == "north" then
            contextAwareTurnLeft()
            local s = contextAwareForward()
            contextAwareTurnRight()

            if s and isPathTracing then
                table.insert(path, current)
                dumpPositionLogToFile()
            end
        else
            error("handleFieldCrossing: Unexpected facing direction")
        end
        success = true
    end
    -- Check if block below is farmland now
    hasBlock, data = turtle.inspectDown()
    if hasBlock and data["name"] == "minecraft:farmland" then
        debug("Found farm again, finishing crossing")
        success = true
    else
        -- Expect field may have gotten shorter -> Move forward until we are over the field
        local tries = 5
        debug("Moving forward to find farm")
        while not isOverFarm() and tries > 0 do
            nextMove()
            tries = tries - 1
        end
        success = tries > 0
    end
    return success;
end

-- Assumption: We move leftwards over the farm
-- TODO: Handle obstacles/lane size decreasing
-- TODO: Handle lane size increasing
local function laneChange(tries)
    if tries == nil then
        tries = 0
    end
    debug("Attempting lane change. Tries: "..tries)
    if tries > 5 then
        return false
    end
    local success = false
    if facing == "north" then
        contextAwareTurnLeft()
        success = contextAwareForward()
        contextAwareTurnLeft()
        if success and isPathTracing then
            table.insert(path, current)
            dumpPositionLogToFile()
        end
    elseif facing == "south" then
        contextAwareTurnRight()
        success = contextAwareForward()
        contextAwareTurnRight()
        if success and isPathTracing then
            table.insert(path, current)
            dumpPositionLogToFile()
        end
    else
        error("laneChange: Unexpected facing direction")
    end
    if success then
        debug("Lane change successful")
        return true
    end
    -- If we could not move forward, move one block back along the lane and try again
    -- We are facing back along the lane, so we should turn around and then move back
    debug("Could not move forward, backtracking and retrying lane change")
    contextAwareTurnLeft()
    local s = contextAwareTurnLeft()
    contextAwareBack()
    if s and isPathTracing then
        table.insert(path, current)
        dumpPositionLogToFile()
    end
    if tries == nil then
        tries = 0
    end
    -- Retry lane change
    return laneChange(tries+1)
end

local function returnToStart()
    -- Trace back path step by step
    for i = #path, 1, -1 do
        local step = path[i]
        while current.x < step.x do
            faceDirection("east")
            contextAwareForward()
        end
        while current.x > step.x do
            faceDirection("west")
            contextAwareForward()
        end
        while current.z < step.z do
            faceDirection("south")
            contextAwareForward()
        end
        while current.z > step.z do
            faceDirection("north")
            contextAwareForward()
        end
        while current.y < step.y do
            contextAwareUp()
        end
        while current.y > step.y do
            contextAwareDown()
        end
    end
    faceDirection("north")
end

---- END FARMING FUNCTIONS ----

local function mainCycle()
    local working = true
    while working do
        local forceReturn = turtle.getItemCount(RETURN_HOME_SLOT) > 0
        if forceReturn or isAtEnd() then
            dumpLogToFile()
            working = false
            info(STATE, "Returning to start. Forced return?: "..tostring(forceReturn))
            returnToStart()
            if isAtStart() then
                info(STATE, "Finished farming")
            else
                info(STATE, "Error: Not at start")
            end
        else
            info(STATE, "Moving to next block")
            local isObstructed = isFacingObstacle()
            if not isObstructed then
                debug("Not obstructed - Next move")
                nextMove()
            end
            if not isObstructed and isOverFarm() then
                info(STATE, "Harvesting")
                harvest()
            else 
                info(STATE, "Lane change")
                debug("Was obstructed? "..tostring(isObstructed))
                laneChange()
                if not isOverFarm() then
                    debug("Field crossing necessary")
                    info(STATE, "Field crossing")
                    local success = handleFieldCrossing()
                    if not success then
                        info(STATE, "Error: Could not find farm")
                        working = false
                        returnToStart()
                    end
                else
                    debug("Regular lane change successful")
                end
            end
        end
        dumpLogToFile()
        -- Debug sleep
        os.sleep(0)
    end
end

---- MAIN ----

checkStartingConditions()
mainCycle()
debug("Finished farming")