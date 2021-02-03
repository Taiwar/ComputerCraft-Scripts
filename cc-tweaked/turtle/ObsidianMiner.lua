local p = require('cc.pretty')

local BLOCK_NAME = "minecraft:obsidian"
local START_SLOT = 1
local REFUEL_SLOT = 16

local world = {}
for x = -30, 30 do
  world[x] = {}
  for y = -10, 30 do
    world[x][y] = {}
    for z = -30, 30 do
      world[x][y][z] = 'unknown'
    end
  end
end

local found_block = true
local curr_coords = { x = 0 , y = 0, z = 0 }
local facing = 0 -- 0 is forward, +1 is one rotation clockwise
local totalMined = 0

function detectNeighbors(onlyDown)
  -- Inspect down
  local isBlock, blockData = turtle.inspectDown()
  if isBlock then
    world[curr_coords.x][curr_coords.y - 1][curr_coords.z] = blockData.name
  else
    world[curr_coords.x][curr_coords.y - 1][curr_coords.z] = 'air'
  end
  if not onlyDown then
    -- Inspect up
    local isBlock, blockData = turtle.inspectUp()
    if isBlock then
      world[curr_coords.x][curr_coords.y + 1][curr_coords.z] = blockData.name
    else
      world[curr_coords.x][curr_coords.y + 1][curr_coords.z] = 'air'
    end
    -- Inspect forward
    local isBlock, blockData = turtle.inspect()
    if isBlock then
      world[curr_coords.x + 1][curr_coords.y][curr_coords.z] = blockData.name
    else
      world[curr_coords.x + 1][curr_coords.y][curr_coords.z] = 'air'
    end

    turn('right')
    -- Inspect right
    local isBlock, blockData = turtle.inspect()
    if isBlock then
      world[curr_coords.x][curr_coords.y][curr_coords.z + 1] = blockData.name
    else
      world[curr_coords.x][curr_coords.y][curr_coords.z + 1] = 'air'
    end
    turn('right')
    -- Inspect back
    local isBlock, blockData = turtle.inspect()
    if isBlock then
      world[curr_coords.x - 1][curr_coords.y][curr_coords.z] = blockData.name
    else
      world[curr_coords.x - 1][curr_coords.y][curr_coords.z] = 'air'
    end
    turn('right')
    -- Inspect left
    local isBlock, blockData = turtle.inspect()
    if isBlock then
      world[curr_coords.x][curr_coords.y][curr_coords.z - 1] = blockData.name
    else
      world[curr_coords.x][curr_coords.y][curr_coords.z - 1] = 'air'
    end
    -- Face forward again
    turn('right')
  end
end

function findBlockToMine()
  local found = false
  local block_coords
  for x, _ in pairs(world) do
    for y, _ in pairs(world[x]) do
      for z, block in pairs(world[x][y]) do
        if block == BLOCK_NAME then
          found = true
          block_coords = { x = x , y = y, z = z }
        end
      end
    end
  end
  return found, block_coords
end

function moveAbove(coords)
  while curr_coords.x ~= coords.x do
    if curr_coords.x < coords.x then
      move('forward')
    else
      move('back')
    end
  end
  if curr_coords.z ~= coords.z  then
    turn('right')
    while curr_coords.z ~= coords.z do
      if curr_coords.z < coords.z then
        move('forward')
      else
        move('back')
      end
    end
    turn('left')
  end
end

function mine(coords)
  while curr_coords.y ~= coords.y + 1 do
    move('down')
    if world[curr_coords.x][curr_coords.y][curr_coords.z] == 'unknown' then
      world[curr_coords.x][curr_coords.y][curr_coords.z] = 'air'
      detectNeighbors()
    end
  end
  turtle.digDown()
  move('down')
  detectNeighbors()
  while curr_coords.y ~= 0 do
    move('up')
  end

  totalMined = totalMined + 1
end

function turn(direction)
  if direction == 'right' then
    turtle.turnRight()
    facing = (facing + 1) % 4
  else
    turtle.turnLeft()
    facing = (facing - 1) % 4
  end
end

function move(direction)
  local movement = 0
  if direction == 'up' then
    turtle.up()
    curr_coords.y = curr_coords.y + 1
  elseif direction == 'down' then
    turtle.down()
    curr_coords.y = curr_coords.y - 1
  else
    if direction == 'forward' then
      turtle.forward()
      movement = 1
    else
      turtle.back()
      movement = -1
    end
    if facing % 2 == 0 then -- If facing forward or back
      curr_coords.x = curr_coords.x + movement
    else -- If facing right or left
      curr_coords.z = curr_coords.z + movement
    end
  end
end

function checkFuel()
  p.print(p.text('Fuel: '..turtle.getFuelLevel(), colors.blue))
  if turtle.getFuelLevel() < 10 then
    p.print(p.text('Refueling', colors.orange))
    local slot = turtle.getSelectedSlot()
    turtle.select(REFUEL_SLOT)
    local success = turtle.refuel()
    turtle.select(slot)
    if not success then
      error('Ran out of fuel!')
    end
  end
end

p.print(p.text('Looking for: '..BLOCK_NAME, colors.purple))
turtle.select(START_SLOT)
repeat
  checkFuel()
  detectNeighbors(true)
  local found, block_coords = findBlockToMine()
  if found then
    p.print(p.text('Mining block at: '..block_coords.x..', '..block_coords.y..', '..block_coords.z, colors.purple))
    moveAbove(block_coords)
    mine(block_coords)
  end
  found_block = found
until not found_block

p.print(p.text('No more blocks found! Total mined: '..totalMined, colors.green))