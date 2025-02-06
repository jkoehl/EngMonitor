-- SASL plugin: Simulates a JPI EDM-730/830 style display

local myFontId = sasl.gl.loadFont("Roboto-Regular.ttf")

size = {400, 300}

local numCylinders = 4

local mpDR           = globalProperty("sim/flightmodel/engine/ENGN_MPR[0]", 0.0)       -- Manifold Pressure
local rpmDR          = globalProperty("sim/flightmodel/engine/ENGN_propmode[0]", 0.0)  -- RPM
local egtDR          = globalProperty("sim/cockpit2/engine/indicators/EGT_deg_C[0]") -- EGT
local chtDR          = globalProperty("sim/cockpit2/engine/indicators/CHT_deg_C[0]") -- CHT
local egtCylDR       = globalProperty("sim/cockpit2/engine/indicators/EGT_CYL_deg_C") -- EGT array
local chtCylDR       = globalProperty("sim/cockpit2/engine/indicators/CHT_CYL_deg_C") -- CHT array
local oilTempDR      = globalProperty("sim/flightmodel/engine/ENGN_oil_temp_c[0]", 0.0) 
local oilPressDR     = globalProperty("sim/flightmodel/engine/ENGN_oil_press_psi[0]", 0.0)
local fuelFlowDR     = globalProperty("sim/cockpit2/engine/indicators/fuel_flow_kg_sec[0]", 0.0)
-- local fuelUsedDR     = globalProperty("sim/cockpit2/engine/indicators/fuel_usedGallons[0]", 0.0)
local voltsDR        = globalProperty("sim/cockpit2/electrical/bus_volts[0]", 0.0)
local oatDR          = globalProperty("sim/cockpit2/temperature/outside_air_temp_degc", 0.0)

local manifoldPressure = 0
local rpm             = 0
local egt             = 0
local cht             = 0
local egtCylValues    = {0, 0, 0, 0}  -- Array to store EGT values for each cylinder
local chtCylValues    = {0, 0, 0, 0}  -- Array to store CHT values for each cylinder
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
    -- Read single-value datarefs
    manifoldPressure = get(mpDR) or 0
    rpm = get(rpmDR) or 0
    egt = get(egtDR) or 0
    cht = get(chtDR) or 0
    oilTemp = get(oilTempDR) or 0
    oilPress = get(oilPressDR) or 0
    fuelFlow = get(fuelFlowDR) or 0
    volts = get(voltsDR) or 0
    oat = get(oatDR) or 0

    for i = 1, numCylinders do
        egtCylValues[i] = get(egtCylDR, i) or 0
        chtCylValues[i] = get(chtCylDR, i) or 0
    end

    -- Compute derived values
    percentPower = computePercentPower(manifoldPressure, rpm)
end

function draw()
    -- Clear the background or draw a black rect for the gauge area
    sasl.gl.drawRectangle(0, 0, 400, 300, {0, 0, 0, 1})  -- black background for example

    -- Draw RPM & MAP Gauge
    sasl.gl.drawCircle(100, 200, 90, false, {0, 1, 0, 1})  -- Green outer circle
    sasl.gl.drawText(myFontId, 100, 270, "RPM", 20, true, false, TEXT_ALIGN_CENTER, {1, 1, 1, 1})
    sasl.gl.drawText(myFontId, 100, 250, string.format("%d", rpm), 30, true, false, TEXT_ALIGN_CENTER, {1, 1, 1, 1})
    sasl.gl.drawText(myFontId, 100, 230, "MAP", 20, true, false, TEXT_ALIGN_CENTER, {1, 1, 1, 1})
    sasl.gl.drawText(myFontId, 100, 210, string.format("%.1f", manifoldPressure), 30, true, false, TEXT_ALIGN_CENTER, {1, 1, 1, 1})
    
    -- Power Percentage
    sasl.gl.drawText(myFontId, 200, 270, string.format("%d%% HP", percentPower), 20, true, false, TEXT_ALIGN_LEFT, {1, 1, 1, 1})
    
    -- Draw EGT & CHT Bars
    local barWidth = 20
    local baseX = 50
    local baseY = 100
    
    for i = 1, numCylinders do
        local egtHeight = math.min((egtCylValues[i] or 0) / 1650 * 100, 100)
        local chtHeight = math.min((chtCylValues[i] or 0) / 850 * 100, 100)
        
        -- Draw EGT Bar (Blue)
        sasl.gl.drawRectangle(baseX + (i - 1) * 60, baseY, barWidth, egtHeight, {0, 0, 1, 1})
        
        -- Draw CHT Bar (Red)
        sasl.gl.drawRectangle(baseX + (i - 1) * 60 + barWidth + 5, baseY, barWidth, chtHeight, {1, 0, 0, 1})
        
        -- Cylinder Number
        sasl.gl.drawText(myFontId, baseX + (i - 1) * 60 + 10, baseY - 10, tostring(i), 15, true, false, TEXT_ALIGN_CENTER, {1, 1, 1, 1})
    end
    
    -- Large Numeric Readouts
    sasl.gl.drawText(myFontId, 300, 50, string.format("EGT %d", egt), 30, true, false, TEXT_ALIGN_LEFT, {1, 1, 1, 1})
    sasl.gl.drawText(myFontId, 300, 20, string.format("CHT %d", cht), 30, true, false, TEXT_ALIGN_LEFT, {1, 1, 1, 1})
    
    -- Other Readouts (Fuel Flow, OAT, Volts)
    sasl.gl.drawText(myFontId, 250, 270, string.format("%.1f GPH", fuelFlow), 20, true, false, TEXT_ALIGN_LEFT, {1, 1, 1, 1})
    sasl.gl.drawText(myFontId, 250, 250, string.format("%d OAT", oat), 20, true, false, TEXT_ALIGN_LEFT, {1, 1, 1, 1})
    sasl.gl.drawText(myFontId, 250, 230, string.format("%.1f BAT", volts), 20, true, false, TEXT_ALIGN_LEFT, {1, 1, 1, 1})

end