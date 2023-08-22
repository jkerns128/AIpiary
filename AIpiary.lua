local args = {...}

local component = require("component")
local event = require("event")
local sides = require("sides")

mutatorAddress = "d7c3c76a-83d3-4110-9136-b627c55b2b9a"
mutatorTransposer = component.proxy(mutatorAddress)

droneFilterAddress = "99738d59-affb-46cf-9ab8-eea166665d10"
droneFilter = component.proxy(droneFilterAddress)

BGSaddress = "640b681a-7d46-431d-96d0-89085e7fe34e"
BGStransposer = component.proxy(BGSaddress)

frameAddress = "1a7a7cdf-805f-48de-8f00-9206e15026a6"
frameTransposer = component.proxy(frameAddress)

targetType = args[1]
firstQueenType = args[2]
secondQueenType = args[3]
effect = "None"
if #args > 3 then
  effect = args[4]
end

function beeScore(bee)
  --Scores the bee based on the current target type
  beeActive = bee["active"]
  beeInactive = bee["inactive"]

  score = sideScore(beeActive) + sideScore(beeInactive)

  if beeActive["species"]["name"] == targetType or 
      beeInactive["species"]["name"] == targetType then
    score = score + 200
  end

  if traitEquality(beeActive, beeInactive) then
    score = score + 5
  end

  return tonumber(score)
end

function sideScore (beeSide)
  --Scores one side of the bee's traits (active or inactive)
  score = beeSide["fertility"] * 20 + beeSide["flowering"] - beeSide["lifespan"]*3 + beeSide["speed"]*10

  if beeSide["tolerantFlyer"] then
    score = score + 3
  end
  if beeSide["nocturnal"] then
    score = score + 13
  end  
  if beeSide["caveDwelling"] then
    score = score + 1
  end

  if beeSide["effect"] == effect then 
    score = score + 5 
  end


  if beeSide["humidityTolerance"] == "Both 1" then score = score + 5 end
  if beeSide["humidityTolerance"] == "Both 2" then score = score + 8 end
  if beeSide["humidityTolerance"] == "Both 3" then score = score + 10 end
  if beeSide["humidityTolerance"] == "Both 4" then score = score + 12 end
  if beeSide["humidityTolerance"] == "Both 5" then score = score + 15 end

  if beeSide["temperatureTolerance"] == "Both 1" then score = score + 5 end
  if beeSide["temperatureTolerance"] == "Both 2" then score = score + 8 end
  if beeSide["temperatureTolerance"] == "Both 3" then score = score + 10 end
  if beeSide["temperatureTolerance"] == "Both 4" then score = score + 12 end
  if beeSide["temperatureTolerance"] == "Both 5" then score = score + 15 end

  return score
end

function traitEquality(firstSide, secondSide)
  
  if firstSide["species"]["name"] ~= secondSide["species"]["name"] then return false end
  if firstSide["tolerantFlyer"] ~= secondSide["tolerantFlyer"] then return false end
  if firstSide["lifespan"] ~= secondSide["lifespan"] then return false end
  if firstSide["humidityTolerance"] ~= secondSide["humidityTolerance"] then return false end
  if firstSide["effect"] ~= secondSide["effect"] then return false end
  if firstSide["flowering"] ~= secondSide["flowering"] then return false end
  if firstSide["nocturnal"] ~= secondSide["nocturnal"] then return false end
  if firstSide["fertility"] ~= secondSide["fertility"] then return false end
  if firstSide["speed"] ~= secondSide["speed"] then return false end
  if firstSide["flowerProvider"] ~= secondSide["flowerProvider"] then return false end
  if firstSide["temperatureTolerance"] ~= secondSide["temperatureTolerance"] then return false end
  if firstSide["caveDwelling"] ~= secondSide["caveDwelling"] then return false end
  
  return true
end

function isTargetType(bee)
  a = bee["active"]["species"]["name"] == targetType
  b = bee["inactive"]["species"]["name"] == targetType
  return a or b
end

















-- Main AI Loop


while component.redstone.getInput(sides.right) > 0 do


  -- Checking type of princess for mutator

  for currIndex = 1, mutatorTransposer.getInventorySize(4) do
    mutatorSlot = mutatorTransposer.getStackInSlot(4,currIndex)

    if mutatorSlot ~= nil then
      mutatorSlot = mutatorSlot["individual"]
      if mutatorSlot["displayName"] == firstQueenType then
         mutatorTransposer.transferItem(4,1,1,currIndex)
      else
        mutatorTransposer.transferItem(4,3,1,currIndex)
      end
    end
  end

  for currIndex = 1, mutatorTransposer.getInventorySize(5) do
    mutatorSlot = mutatorTransposer.getStackInSlot(5,currIndex)
  
    if mutatorSlot ~= nil then
      mutatorSlot = mutatorSlot["individual"]
      if mutatorSlot["displayName"] == secondQueenType then
         mutatorTransposer.transferItem(5,3,1,currIndex)
      else
        mutatorTransposer.transferItem(5,1,1,currIndex)
      end
    end
  end



  -- Drone filter

  if(droneFilter.getAllStacks(5)(0)["individual"] ~= nil) then
    for currIndex = 1, droneFilter.getInventorySize(5) do
      currSlot = droneFilter.getStackInSlot(5,currIndex)
      
      if currSlot ~= nil then
        if isTargetType(currSlot["individual"]) then
          droneFilter.transferItem(5,4,64,currIndex)
        else
          droneFilter.transferItem(5,2,64,currIndex)        
        end
      end
    end
  end


  -- Gene selection and type selector

  BGSdSlot = BGStransposer.getAllStacks(5)(0)
  BGSpSlot = BGStransposer.getAllStacks(3)(0)

  if BGSdSlot["individual"] ~= nil and BGSpSlot["individual"] ~= nil then

    -- Frame manipulation

    frame = frameTransposer.getAllStacks(5)(0)
    if(frame["name"] ~= nil) then
      health = frame["maxDamage"] - frame["damage"]

      if(health <= 5) then
        frameTransposer.transferItem(5,3)
        if(frameTransposer.getAllStacks(1)(0) ~= nil) then
          frameTransposer.transferItem(1,5)
        end
      end
    else 
      if(frameTransposer.getAllStacks(1)(0) ~= nil) then
        frameTransposer.transferItem(1,5)
      end
    end

    -- Best Bee Selection

    bestIndex = 0
    bestScore = -99
    currScore = 0

    for currIndex = 1, BGStransposer.getInventorySize(5) do
      currSlot = BGStransposer.getStackInSlot(5,currIndex)
      
      if currSlot ~= nil then
        currScore = beeScore(currSlot["individual"])
        if currScore > bestScore then
          bestScore = currScore
          bestIndex = currIndex
        end
      end
    end
    
    if(bestScore > 0 and BGSpSlot["individual"] ~= nil) then
      print("Score: ",bestScore)
      bestBee = BGStransposer.getStackInSlot(5,bestIndex)["individual"]
      beePurity = traitEquality(bestBee["active"], bestBee["inactive"])
      princess = BGSpSlot["individual"]
      princessPurity = traitEquality(princess["active"], princess["inactive"])
      equality = traitEquality(princess["active"],bestBee["active"])
      if(beePurity and princessPurity and equality and isTargetType(bestBee)) then
        BGStransposer.transferItem(5,1,1,bestIndex)
        BGStransposer.transferItem(3,1)
        return
      else
        BGStransposer.transferItem(5,4,1,bestIndex)
        BGStransposer.transferItem(3,4)
      end
    end
  end

end  