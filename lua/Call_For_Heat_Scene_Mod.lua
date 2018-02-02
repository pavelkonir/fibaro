--[[
%% properties
%% events
%% globals
fiveMinuteTimer
--]]


-- Scene         : Call For Heat Scene
-- Version       : 1.0
-- Date Created  : 28 February 2016
-- Last Changed  : 2 February 2018
-- Created By    : Dave Harrison
-- Modified by   : Pavel Konir (pavel@konir.cz)
-- Mods          : - Boiler switch over relay (Qubino Flush 1D realy)
--                 - Do not expect to reach the temperature. Use of inertia of radiators.

-- Purpose       : To turn on the boiler whenever a room needs heat
-- Trigger       : Triggered by the Timer Scene updating the fiveMinuteTimer global variable


-------------------- Declaration: Local Variables
local boilerSwitch = 35

-- Amount by which temperature needs to fall below setpoint before turning heating on
local threshold = 0.3

local sourceTrigger = fibaro:getSourceTrigger()
local currentDate = os.date("%d/%m/%Y %X")
local currentDateTime = os.date("*t")

-------------------- Functions

-- getRoomsAndDevices
---------------------
-- Get the list of rooms and devices to monitor
-- Only rooms with both a thermostat and thermometer will be selected
function getRoomsAndDevices()

    local rooms = {}

    local allRooms = api.get("/rooms")

    for k, room in pairs(allRooms) do

        local thermostat = room.defaultThermostat
        local thermometer = room.defaultSensors.temperature

        if (thermostat ~= nil and thermometer ~= nil) then
            if (thermostat ~= 0 and thermometer ~= 0) then

                -- Ignore any rooms where the thermostat doesn't have a value
                if (tonumber(fibaro:getValue(thermostat, "value")) > 0) then
                    local newRoom = {id = room.id, name = room.name, thermostat = thermostat, thermometer = thermometer}
                    table.insert(rooms, newRoom)
                end
            end
        end
    end

    return rooms
end

-- asterisk
-----------
-- Output an asterisk if true
function asterisk(condition)
    local asterisk = ""

    if (condition) then
        asterisk = " *"
    end

    return asterisk
end

-------------------- Main
-- fibaro:debug(">> Trigger Type: " .. sourceTrigger.type)

if (sourceTrigger.name ~= nil) then
    -- fibaro:debug(">> Trigger Name: " .. sourceTrigger.name)
end

-- Get the rooms and devices that we want to monitor
local rooms = getRoomsAndDevices()

-- Is the heating already on?
local boilerOn = (fibaro:getValue(boilerSwitch, "value") == "1")
fibaro:debug(currentDate .. "  Boiler on: " .. tostring(boilerOn))

local turnBoilerOn = false
local turnBoilerOff = true

-- Check each room
for i , room in pairs(rooms) do

    local roomTemp = tonumber(fibaro:getValue(room.thermometer, "value"))
    local roomSetpoint = tonumber(fibaro:getValue(room.thermostat, "targetLevel"))

    -- Has the temperature fallen below setpoint by more than the threshold?
    local belowThreshold = roomTemp <= (roomSetpoint - threshold)

    fibaro:debug(">> Room: " .. room.name .. "   Temperature: " .. roomTemp .. "   Set Point: " .. roomSetpoint .. asterisk(belowThreshold))

    -- If the boiler is not on, then check if any rooms need heat
    if (not boilerOn) then

        -- Need to turn the boiler on?
        if (belowThreshold) then
            turnBoilerOn = true
        end
    else
        -- Is the temperature still below the setpoint?
        if (belowThreshold) then
            turnBoilerOff = false
        end
    end
end


-- Turn the boiler on?
if (not boilerOn and turnBoilerOn) then
    fibaro:debug("*** Turning on heating")
    fibaro:call(boilerSwitch, "turnOn")
end

if (not boilerOn and not turnBoilerOn) then
    fibaro:debug("*** Keep heating off")
end

-- Turn the boiler off?
if (boilerOn and turnBoilerOff) then
    fibaro:debug("*** Turning off heating")
    fibaro:call(boilerSwitch, "turnOff")
end
