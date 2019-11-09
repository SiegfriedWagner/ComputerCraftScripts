-- global functions/classes
Set = {}
Set.__index = Set

function Set:new(tdata)
    local self = setmetatable({}, Set)
    self.data = tdata
    return self
end

function Set:contains(element)
    for n=1, #self.data do
        if element == self.data[n] then
            return true
        end
    end
    return false
end


-- global variables
TvalidSapling = Set:new({"minecraft:sapling", "ic2:sapling", "rustic:sapling", "natura:overworld_sapling", "natura:overworld_sapling2", "forestry:sapling"})
TvalidFuel = Set:new({"minecraft:coal", "railcraft:fuel_coke"})
TvalidWood = Set:new({"minecraft:log", "ic2:rubber_wood", "rustic:log", "natura:overworld_logs", "natura:overworld_logs2", "forestry:log.0"})
xPos, zPos = 0,0
xDir, zDir = 1,0
-- functions

local function getItemPosition(TvalidSet)
    for n=1, 16 do
        if turtle.getItemCount(n) > 0 then
            local data= turtle.getItemDetail(n)
            if TvalidSet:contains(data.name) then
                return n
            end
        end
    end
    return 0
end

local function refuel( ammount )
	local fuelLevel = turtle.getFuelLevel()
	if fuelLevel == "unlimited" then
		return true
	end
	
	local needed = ammount or (xPos + zPos + 20)*6
    --print("DEBUG, refuel: needed", needed)
    while turtle.getFuelLevel() < needed do
        local fuelSlot = getItemPosition(TvalidFuel)
        if fuelSlot ~= 0 then
            turtle.select(fuelSlot)
        else
            return false
        end
        while turtle.getFuelLevel() < needed and turtle.getItemCount() > 0 do
            turtle.refuel(1)
        end
	end
	return true
end

local function tryForwards()
    if turtle.getFuelLevel() == 0 then
        print("Fuel error")
        return 0
    end
	while not turtle.forward() do
		if turtle.detect() then
			return false
        else
            turtle.attack()
			sleep( 0.5 )
		end
	end
	
	xPos = xPos + xDir
	zPos = zPos + zDir
	return true
end

local function turnLeft()
	turtle.turnLeft()
	xDir, zDir = zDir, -xDir
end

local function turnRight()
	turtle.turnRight()
	xDir, zDir = -zDir, xDir
end

local function isBlock(name, side)
    local success, data
    if side == "Up" then
        success, data = turtle.inspectUp()
    elseif side == "Down" then
        success, data = turtle.inspectDown()
    else
        success, data = turtle.inspect()
    end
    if success and data.name == name then
        return true
    else
        return false
    end
end
local function getBlockName(side)
    local success, data
    if side == "Up" then
        success, data = turtle.inspectUp()
    elseif side == "Down" then
        success, data = turtle.inspectDown()
    else
        success, data = turtle.inspect()
    end
    if success then
        print(data.name)
        return data.name
    else
        return nil
    end
end

local function placeSapling()
    local n = getItemPosition(TvalidSapling)
    if n == 0 then
        return false
    end
    turtle.select(n)
    if not TvalidSapling:contains(getBlockName("Down")) then
        turtle.digDown()
    end
    turtle.placeDown()
    turtle.select(1)
    return true
end

local function cutTree()
    turtle.dig()
    tryForwards()
    while TvalidWood:contains(getBlockName("Up")) do
        turtle.digUp()
        turtle.up()
    end
    while not isBlock("minecraft:dirt", "Down") and not isBlock("minecraft:grass", "Down") do
        turtle.digDown()
        turtle.down()
    end
    while not turtle.up() do
        turtle.digUp()
    end
    return true
end

local function isInventoryFull()
    for n=1, 16 do
        if turtle.getItemCount(n) == 0 then
            return false
        end
    end
    return true
end

local function cultivate()
    turtle.suckDown()
    placeSapling()
    if not tryForwards() then 
        if not cutTree() then
            print("DEBUG: ",  "Inventory full")
            return "Inventory full"
        end
    end
    if not refuel() then
        print("DEBUG: ", "Not enough fuel")
        return "Not enough fuel"
    end
    print("DEBUG: End position (", xPos, ",", zPos, ")")
    return "OK"
end

local function drop(slot, amount)
    if amount == nil then
        amount = 64
    end
    local prev = turtle.getSelectedSlot()
    turtle.select(slot)
    while not turtle.drop(amount) do
        print("Inventory full")
        os.pullEvent("char")
    end
    turtle.select(prev)
end

local function returnSupplies()
    print("Return supplies")
    if zPos ~= 0 then
        while zDir ~= -1 do
            turnLeft()
        end
        while zPos ~= 0 do
            cultivate()
        end
    end
    if xPos ~= 0 then
        while xDir ~= -1 do 
            turnLeft()
        end
        while xPos ~= 0 do
            cultivate()
        end
    end
    while xDir ~= -1 do
        turnLeft()
    end
    local availableFuel = 0
    local fuelSlot = 1
    local saplingsLoaded = 0
    for n=1,16 do
        if turtle.getItemCount(n) > 0 then
            local data = turtle.getItemDetail(n)
            if TvalidFuel:contains(data.name) then
                fuelSlot = n
                availableFuel = availableFuel + data.count
            elseif TvalidSapling:contains(data.name) then
                saplingsLoaded = saplingsLoaded + data.count
                if saplingsLoaded > 64 then 
                    drop(n, saplingsLoaded-64)
                    saplingsLoaded=64
                end
            else
                drop(n)
            end
        end
    end
    turnRight()
    turtle.select(fuelSlot)
    while turtle.getItemCount() ~= 64 do
        turtle.suck(64-turtle.getItemCount())
        if turtle.getItemCount() < 64 then
            sleep(300)
        end
    end
    while xDir ~= 1 do
        turnLeft()
    end
end

-- main loop
while true do
    while refuel() and not isInventoryFull()  do
        if isBlock("chisel:glass") then
            if zPos % 2 == 0 then
                turnRight()
                if not isBlock("chisel:glass") then
                    cultivate()
                    turnRight()
                else
                    break
                end
            else
                turnLeft()
                if not isBlock("chisel:glass") then
                    cultivate()
                    turnLeft()
                else
                    break
                end
            end
        else
            cultivate()
        end
    end
    returnSupplies()
    sleep(60)
end
