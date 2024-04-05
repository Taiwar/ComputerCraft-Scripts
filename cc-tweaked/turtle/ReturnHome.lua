local start = {x=0, y=0, z=0}
local current = {x=0, y=0, z=0}
local path = {current}
local facing = "north"

local function readPositionLog()
    local file = fs.open("position_log.txt", "r")
    -- Format: {current=current, facing=facing, path=path}
    return textutils.unserialize(file.readAll())
end

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

local function main()
    local data = readPositionLog()
    current = data.current
    facing = data.facing
    path = data.path
    returnToStart()
end

main()