local COLUMNS = "time,name,amount"
local BLOCK_READER_SIDE = "right"
local OUTPUT_FILE = "data.csv"
local INTERVAL = 5

local blockReader = peripheral.wrap(BLOCK_READER_SIDE)
local file = io.open(OUTPUT_FILE, "r")

local firstLine
if file ~= nil then
    firstLine = file:read()
    file:close()
end

file = io.open(OUTPUT_FILE, "a")

if firstLine == nil then
    file:write(COLUMNS)
end

function displayLogs(newLine)
    term.clear()
    term.setCursorPos(1, 1)
    print("Logging: "..newLine)
end

while true do
    local currentData = blockReader.getBlockData()
    local currentTime = os.epoch()
    local newLine = currentTime..","..currentData["boxedChemical"]["gasName"]..","..currentData["boxedChemical"]["amount"].."\n"
    file:write(newLine)
    displayLogs(newLine)
    sleep(INTERVAL)
end