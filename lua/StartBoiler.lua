--[[
%% properties
%% events
%% globals
--]]

if (fibaro:countScenes()>1) then
    fibaro:debug('There are already running instances!');
    fibaro:abort();
end

-- ******* configuration section *******

local deviceMap = {}
-- tempMap[device id thermometer in room] = {id thermostatic head from same room as thermometer}
deviceMap[28] = {5,7}
deviceMap[38] = {9}

local boilerRelayId = 35 -- The boiler control device id
local maxDifference = 0.3 -- Maximal difference between required and actual temperatures

-- ******* end configuration section *******


local boilerRelayState = tonumber(fibaro:getValue(boilerRelayId, "value"))
while true do
    local tempIsLow = false
    local roomNameRequiredHeating = ""
    for k,v in pairs(deviceMap) do
        local thermometerTemp = fibaro:getValue(k, "value")
        roomNameRequiredHeating = fibaro:getRoomNameByDeviceID(k)
        fibaro:debug("Measured temperature in '" .. roomNameRequiredHeating .. "' : " .. thermometerTemp)
        for i, thermostaticHeadId in ipairs(v) do
            local requiredTemp = fibaro:getValue(thermostaticHeadId, "value")
            fibaro:debug("Thermostatic head name '" .. fibaro:getName(thermostaticHeadId) .. "' required temperature: " .. requiredTemp)
            if (requiredTemp - thermometerTemp >= maxDifference) then
                tempIsLow = true
                break
            end
        end
        if (tempIsLow == true) then
            break
        end
    end

    if (tempIsLow == true) then
        fibaro:debug("In some rooms there is a lower temperature. Room name: " .. roomNameRequiredHeating)
        if (boilerRelayState == 0) then
            fibaro:debug("Boiler is switched off, it will be started")
            fibaro:call(boilerRelayId, "turnOn");
            boilerRelayState = 1
        else
            fibaro:debug("Boiler is already on")
        end
    else
        fibaro:debug("Temperatures are all right in all rooms")
        if (boilerRelayState == 1) then
            fibaro:debug("Boiler is switched on, it will be stoped")
            fibaro:call(boilerRelayId, "turnOff");
            boilerRelayState = O
        else
            fibaro:debug("Boiler is already switched off")
        end
    end

    fibaro:sleep(300000);
end
