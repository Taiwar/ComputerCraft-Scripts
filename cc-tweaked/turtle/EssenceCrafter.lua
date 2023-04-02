local p = require('cc.pretty')
local bridge = peripheral.find("rsBridge")

local TITLE = "---ESSENCE CRAFTER---"
local STATE = ""

-- Constants for operation
local OUTPUT_SLOT = 5
local INPUT_SLOT = 1
local EXPORT_DIRECTION = "up"
local MIN_STOCK = 9

-- Example RS item structure
--[[ 
item = {
    amount = 0,
    displayName = 0,
    fingerprint = "",
    isCraftable = false,
    name = ""
} 
]]

-- String constants to make writing exclusions easier and less error-prone
local MYSTICAL_AGRICULTURE = "mysticalagriculture:"
local MYSTICAL_AGRADDITIONS = "mysticalagradditions:"
local MINECRAFT = "minecraft:"
local ESSENCE = "_essence"
local DEFAULT = "default"

local LOOP = true -- Continously get all essences from AE system and craft them
local LOOP_TIMEOUT = 20 -- Time to wait between loop iterations (in s)

-- List of item names to be excluded from processing
-- These are mainly essences which have multiple recipes and you don't want to autocraft into one specific recipe all the time
local exclusions = {
    MYSTICAL_AGRADDITIONS.."insanium"..ESSENCE,
    MYSTICAL_AGRICULTURE.."supremium"..ESSENCE,
    MYSTICAL_AGRICULTURE.."imperium"..ESSENCE,
    MYSTICAL_AGRICULTURE.."tertium"..ESSENCE,
    MYSTICAL_AGRICULTURE.."prudentium"..ESSENCE,
    MYSTICAL_AGRICULTURE.."inferium"..ESSENCE,
    MYSTICAL_AGRICULTURE.."fertilized"..ESSENCE,
    MYSTICAL_AGRICULTURE.."stone"..ESSENCE,
    MYSTICAL_AGRICULTURE.."dirt"..ESSENCE,
    MYSTICAL_AGRICULTURE.."nature"..ESSENCE,
    MYSTICAL_AGRICULTURE.."dye"..ESSENCE,
    -- MYSTICAL_AGRICULTURE.."wood"..ESSENCE,
    MYSTICAL_AGRICULTURE.."water"..ESSENCE,
    MYSTICAL_AGRICULTURE.."ice"..ESSENCE,
    MYSTICAL_AGRICULTURE.."fire"..ESSENCE,
    MYSTICAL_AGRICULTURE.."nether"..ESSENCE,
    MYSTICAL_AGRICULTURE.."nature"..ESSENCE,
    MYSTICAL_AGRICULTURE.."nether_quartz"..ESSENCE,
    MYSTICAL_AGRICULTURE.."experience"..ESSENCE,
    MYSTICAL_AGRICULTURE.."rabbit"..ESSENCE,
    MYSTICAL_AGRICULTURE.."mystical_flower"..ESSENCE
}

-- Predefined recipes for crafting essences
-- 0 = none
-- anything else = amount provided / given positions
local recipes = {
    [DEFAULT] = {
        1, 1, 1,
        1, 0, 1,
        1, 1, 1
    },
    full = {
        1, 1, 1,
        1, 1, 1,
        1, 1, 1
    },
    dumbbell = {
        1, 1, 1,
        0, 1, 0,
        1, 1, 1
    },
    line1 = {
        1, 1, 1,
        0, 0, 0,
        0, 0, 0
    },
    line2 = {
        0, 0, 0,
        1, 1, 1,
        0, 0, 0
    },
    line3 = {
        0, 0, 0,
        0, 0, 0,
        1, 1, 1
    },
    cross = {
        0, 1, 0,
        1, 1, 1,
        0, 1, 0
    }
}

local craftingTableMapping = {
    2, 3, 4,
    6, 7, 8,
    10, 11, 12
}

-- Set up mappings of essence-name to product recipes
local productMappings = {
    [DEFAULT] = {
        [DEFAULT] = {
            recipe = recipes[DEFAULT]
        }
    },
    [MYSTICAL_AGRICULTURE.."diamond"..ESSENCE] = {
        [DEFAULT] = {
            recipe = recipes["full"]
        }
    },
    [MYSTICAL_AGRICULTURE.."silicon"..ESSENCE] = {
        [DEFAULT] = {
            recipe = recipes["line1"]
        }
    },
    [MYSTICAL_AGRICULTURE.."wood"..ESSENCE] = {
        [MINECRAFT.."oak_log"] = {
            recipe = recipes["line1"],
            goal = 256
        },
        [MINECRAFT.."spruce_log"] = {
            recipe = recipes["line2"],
            goal = 256
        },
        [MINECRAFT.."birch_log"] = {
            recipe = recipes["line3"],
            goal = 256
        }
    }
}

local function info(state, task)
    term.clear()
    term.setCursorPos(1, 1)
    p.print(p.text(TITLE, colors.yellow))
    p.print(p.text(state, colors.white))
    p.print(p.text(task, colors.green))
end

-- Helper function to create sum of elements in table
-- Preconditions: t ~= nil and t only contains numbers
-- Returns: Sum of elements in table
local function sumTable(t)
    local sum = 0
    for _, v in pairs(t) do
        sum = sum + v
    end
    return sum
end

local stored = 0

local function findEssences(items)
    local results = {}
    -- Iterate over each item
    for _, item in pairs(items) do
        -- Make sure item is a table
        if type(item) == 'table' then
            -- Look for all items that have either "mysticalagriculture:" or "mysticalagradditions:" and has "_essence" in its name
            if (string.find(string.lower(item['name']), MYSTICAL_AGRICULTURE)
                    or string.find(string.lower(item['name']), MYSTICAL_AGRADDITIONS))
                    and string.find(string.lower(item['name']), ESSENCE)
            then
                -- Go through all entries of the exclusions list and match the name of the item contains an excluded string
                local isExcluded = false
                for _, v in pairs(exclusions) do
                    if string.lower(item['name']) == v then
                        isExcluded = true
                        break
                    end
                end
                if not isExcluded then
                    stored = stored + 1
                    results[stored] = item
                end
            end
        end
    end
    return results
end

-- Instructs a connected export bus to export a specific item from the database
local function requestEssence(name, stock, recipe)
    local maxStackSize = math.min(64, stock-MIN_STOCK)
    local min = sumTable(recipe)
    local times = math.floor(maxStackSize / min)
    -- Trigger export once into robot-input-slot
    print("Requesting "..times.." times")
    bridge.exportItem({name=name, count=times*min}, EXPORT_DIRECTION)
end

-- Aligns essence into crafting grid
-- Returns: True if recipe could be formed at least once, otherwise false
local function alignEssence(recipe)
    print("alignEssence")
    local couldAlign = false

    turtle.select(INPUT_SLOT)
    local essence = turtle.getItemDetail()

    -- Only process further if there is essence in the input slot
    if essence ~= nil then

        -- Calculate amount of essence per position in recipe
        local amountPerPosition = 0
        -- Avoid division by 0
        if sumTable(recipe) ~= 0 then
            -- Amount per position is maximum (total / positions) rounded down
            amountPerPosition = math.floor(essence["count"] / sumTable(recipe))
        end

        -- Only align items if pattern can be filled at least once
        if amountPerPosition >= 1 then
            for position, amount in pairs(recipe) do
                if amount > 0 then
                    -- Map from recipe position to inventory position
                    local slot = craftingTableMapping[position]
                    -- Transfer calculated amount to slot in "crafting table"
                    turtle.transferTo(slot, amountPerPosition)
                end
            end
            couldAlign = true
        end
    end
    return couldAlign
end

-- Cleans robot's inventory
local function cleanInv()
    for i = 1, 16, 1 do
        turtle.select(i)
        -- Drop out the front because in the example setup this is an interface and therefore passed back into the system for potential future use
        turtle.drop()
    end
end

-- Output results in output slot
local function outputResult()
    turtle.select(OUTPUT_SLOT)
    -- Drop out the front because in the example setup this is an interface
    turtle.drop()
end

-- Craft essences in input slot until no longer possible
local function craftEssence(recipe)
    print("craftEssence")
    -- Only craft if essence could be aligned
    if alignEssence(recipe) then
        repeat
            local couldCraft = true
            -- Keep crafting and exporting while it works
            while couldCraft do
                turtle.select(OUTPUT_SLOT)
                -- always try to craft a bit less than a stack, so there's no overflow
                couldCraft = turtle.craft(1) -- returns true if it was able to craft at least one result
                -- if something is in outputSlot, export it
                if turtle.getItemCount(OUTPUT_SLOT) > 0 then
                    outputResult()
                end
            end
        until not alignEssence(recipe) -- repeat until input is not enough to fill pattern anymore
    end
    cleanInv()
end

local CRAFTING_MAX_ITER = 100

-- Main program function
local function main()
    info("Main", "Gathering info")
    -- Fetch all items currents in network
    local currentState = bridge.listItems()

    -- Find/Filter all essences we want to process
    info("Main", "Filtering info")
    local essences = findEssences(currentState)
    -- Process each essence
    for _, item in pairs(essences) do
        info("Main", "Processing "..item["displayName"])


        local itemCount = item["amount"]
        local mapping = productMappings[DEFAULT]

        -- Check if there's an entry in mappings with this essence's name
        if productMappings[item["name"]] ~= nil then
            -- Set recipe to the one in the matching mapping
            mapping = productMappings[item["name"]]
        end

        for productName, instructions in pairs(mapping) do
            local productInfo = bridge.getItem({name=productName})
            local i = 0
            local enoughStock = itemCount ~= nil and itemCount > (sumTable(instructions["recipe"]) + MIN_STOCK)
            local wantMoreProduct = productName == DEFAULT or (productInfo ~= nil and productInfo["amount"] < instructions["goal"])
            local productDisplayName = productName == DEFAULT and DEFAULT or productInfo["displayName"]
            -- Craft until minimum stock level is reached
            while enoughStock and wantMoreProduct do
                i = i + 1
                info("Main", i.." - Processing "..item["displayName"].." to create "..productDisplayName)
                print("enoughStock: "..tostring(enoughStock).." wantMoreProduct: "..tostring(wantMoreProduct))
                print("itemCount: "..itemCount)
                -- Request essence to be exported into turtle
                requestEssence(item["name"], itemCount, instructions["recipe"])
                os.sleep(0.2) -- Give export bus some time
                -- Start crafting
                craftEssence(instructions["recipe"])
    
                -- Refresh count
                local currentItem = bridge.getItem({name=item["name"]})
                -- If item could be found in AE system get its count, otherwise set itemCount to 0.
                if currentItem ~= nil then
                    itemCount = currentItem["amount"];
                else
                    itemCount = 0
                end

                if i > CRAFTING_MAX_ITER then
                    print("Reached max crafting iterations: Cleaning inv and moving on")
                    cleanInv()
                end

                productInfo = bridge.getItem({name=productName})
                wantMoreProduct = productName == DEFAULT or (productInfo ~= nil and productInfo["amount"] < instructions["goal"])
                enoughStock = itemCount ~= nil and itemCount > (sumTable(instructions["recipe"]) + MIN_STOCK)
            end
        end
    end
end

if LOOP then
    while true do
        info("Root", "Cleaning")
        cleanInv()
        main()
        info("Root", "Sleeping")
        os.sleep(LOOP_TIMEOUT)
    end
else
    info("Main", "Start")
    main()
    print("Finished run.")
end