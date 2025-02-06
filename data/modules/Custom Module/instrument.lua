-- SASL plugin: Simulates a JPI EDM-730/830 style display

local myFontId = sasl.gl.loadFont("Roboto-Regular.ttf")

size = {400, 300}

local numCylinders = 4

local mpDR           = globalProperty("sim/flightmodel/engine/ENGN_MPR[0]", 0.0)       -- Manifold Pressure
local rpmDR          = globalProperty("sim/flightmodel/engine/ENGN_propmode[0]", 0.0)  -- RPM
local egtDR          = globalProperty("sim/cockpit2/engine/indicators/EGT_deg_C[0]", 0.0) -- EGT array if multiple cylinders
local chtDR          = globalProperty("sim/cockpit2/engine/indicators/CHT_deg_C[0]", 0.0) -- CHT array
local oilTempDR      = globalProperty("sim/flightmodel/engine/ENGN_oil_temp_c[0]", 0.0) 
local oilPressDR     = globalProperty("sim/flightmodel/engine/ENGN_oil_press_psi[0]", 0.0)
local fuelFlowDR     = globalProperty("sim/cockpit2/engine/indicators/fuel_flow_kg_sec[0]", 0.0)
-- local fuelUsedDR     = globalProperty("sim/cockpit2/engine/indicators/fuel_usedGallons[0]", 0.0)
local voltsDR        = globalProperty("sim/cockpit2/electrical/bus_volts[0]", 0.0)
local oatDR          = globalProperty("sim/cockpit2/temperature/outside_air_temp_degc", 0.0)

local manifoldPressure = 0
local rpm             = 0
local egtValues       = {}
local chtValues       = {}
local oilTemp         = 0
local oilPress        = 0
local fuelFlow        = 0
local fuelUsed        = 0
local volts           = 0
local oat             = 0

local percentPower    = 0
local timeRunning     = 0  -- example for tracking displayed time

--    e.g. for computing percent HP from MP & RPM, or EGT bar heights, etc.
local function computePercentPower(mp, rpm)
    -- This is a very rough placeholder. Real formula depends on your aircraft engine.
    -- For example, 29" MP @ 2700 RPM might be ~100% for a certain engine.
    local result = (mp / 29) * (rpm / 2700) * 100
    if result > 100 then 
        result = 100 
    end
    return result
end

function update()
    -- read data from X-Plane datarefs
    manifoldPressure = get(mpDR) or 0
    rpm             = get(rpmDR) or 0
    
    egtValues = get(egtDR) or {0, 0, 0, 0, 0, 0}
    chtValues = get(chtDR) or {0, 0, 0, 0, 0, 0}
    
    oilTemp     = get(oilTempDR)
    oilPress    = get(oilPressDR)
    fuelFlow    = get(fuelFlowDR)
    -- fuelUsed    = get(fuelUsedDR)
    volts       = get(voltsDR)
    oat         = get(oatDR)
    
    -- compute derived values
    percentPower = computePercentPower(manifoldPressure, rpm)
    
    -- track time: 
    -- timeRunning = timeRunning + get(frameTime)  -- frameTime is seconds since last frame, built-in SASL
    timeRunning = 0
end

function draw()
    -- Clear the background or draw a black rect for the gauge area
    sasl.gl.drawRectangle(0, 0, 400, 300, {0, 0, 0, 1})  -- black background for example

    -- a) Draw MP & RPM
    sasl.gl.drawText(
      myFontId, 
      20, 260, 
      string.format("MAP: %.1f", manifoldPressure), 
      12, 
      false, 
      false, 
      TEXT_ALIGN_LEFT, 
      {1, 1, 1, 1}
    )
    sasl.gl.drawText(
      myFontId, 
      20, 230, 
      string.format("RPM: %.0f", rpm), 
      12, 
      false, 
      false, 
      TEXT_ALIGN_LEFT, 
      {1, 1, 1, 1}
    )
    
    -- b) Draw percent power
    sasl.gl.drawText(
      myFontId, 
      20, 200, 
      string.format("%% HP: %.0f%%", percentPower), 
      12, 
      false, 
      false, 
      TEXT_ALIGN_LEFT, 
      {1, 1, 0, 1}
    )
    
    -- c) Draw EGT bar
    -- For demonstration, we map EGT range 400–1600 to bar height
    local egt = egtValues[1]
    local egtRange = 1600 - 400
    local barHeight = ((egt - 400) / egtRange) * 100
    if barHeight < 0 then barHeight = 0 end
    if barHeight > 100 then barHeight = 100 end
    
    sasl.gl.drawRectangle(100, 100, 20, barHeight, {1, 0, 0, 1}) 
    sasl.gl.drawText(
      myFontId, 
      130, 100, 
      string.format("EGT: %.0f°F", egt), 
      12, 
      false, 
      false, 
      TEXT_ALIGN_LEFT, 
      {1, 1, 1, 1}
    )
    
    -- d) Draw CHT bar
    -- Suppose 200–500 °F for typical range
    local cht = chtValues[1]
    local chtRange = 500 - 200
    local chtBarHeight = ((cht - 200) / chtRange) * 100
    if chtBarHeight < 0 then chtBarHeight = 0 end
    if chtBarHeight > 100 then chtBarHeight = 100 end
    
    sasl.gl.drawRectangle(200, 100, 20, chtBarHeight, {0, 0, 1, 1})
    sasl.gl.drawText(
      myFontId,
      230, 100, 
      string.format("CHT: %.0f°F", cht), 
      12, 
      false, 
      false, 
      TEXT_ALIGN_LEFT, 
      {1, 1, 1, 1}
    )

    -- e) Oil Temp / Press
    sasl.gl.drawText(
      myFontId, 
      20, 170, 
      string.format("Oil Temp: %.0f°F", oilTemp), 
      12, 
      false, 
      false, 
      TEXT_ALIGN_LEFT, 
      {1, 1, 1, 1}
    )
    sasl.gl.drawText(
      myFontId, 
      20, 140, 
      string.format("Oil Press: %.0f PSI", oilPress), 
      12, 
      false, 
      false, 
      TEXT_ALIGN_LEFT, 
      {1, 1, 1, 1}
    )
    
    -- f) Fuel Flow, Fuel Used
    sasl.gl.drawText(
      myFontId, 
      20, 110, 
      string.format("Fuel Flow: %.1f GPH", fuelFlow), 
      12, 
      false, 
      false, 
      TEXT_ALIGN_LEFT, 
      {1, 1, 1, 1}
    )
    -- sasl.gl.drawText(
    --   myFontId, 
    --   20, 80, 
    --   string.format("Fuel Used: %.1f G", fuelUsed), 
    --   12, 
    --   false, 
    --   false, 
    --   TEXT_ALIGN_LEFT, 
    --   {1, 1, 1, 1}
    -- )

    -- g) Volts and OAT
    sasl.gl.drawText(
      myFontId, 
      20, 50, 
      string.format("Volts: %.1f V", volts), 
      12, 
      false, 
      false, 
      TEXT_ALIGN_LEFT, 
      {1, 1, 1, 1}
    )
    sasl.gl.drawText(
      myFontId, 
      20, 20, 
      string.format("OAT: %.1f°C", oat), 
      12, 
      false, 
      false, 
      TEXT_ALIGN_LEFT, 
      {1, 1, 1, 1}
    )
    
    -- h) Time Running
    local hrs = math.floor(timeRunning / 3600)
    local mins = math.floor((timeRunning % 3600) / 60)
    sasl.gl.drawText(
        myFontId, 
        300, 20,
      string.format("%02d:%02d H:M", hrs, mins),
      12, 
      false, 
      false, 
      TEXT_ALIGN_LEFT, 
      {1, 1, 1, 1}
    )
end