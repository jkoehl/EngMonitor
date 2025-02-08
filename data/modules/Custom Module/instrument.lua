-- ==========================================================
--  JPI EDM-730/830-Style Engine Monitor (Closer to real layout)
--  SASL plugin script
-- ==========================================================
-- Define the size of the component
size = {640, 480}

local myFontId = sasl.gl.loadFont("Roboto-Regular.ttf")

-- Number of cylinders
local numCylinders = 4  -- The screenshot seems to show 4 cylinders

------------------------------------------------------------
-- DATAREFS
------------------------------------------------------------
local mpDR        = globalProperty("sim/flightmodel/engine/ENGN_MPR[0]", 0.0)       
local rpmDR       = globalProperty("sim/flightmodel/engine/ENGN_propmode[0]", 0.0)  
local egtCylDR    = globalProperty("sim/cockpit2/engine/indicators/EGT_CYL_deg_C")   
local chtCylDR    = globalProperty("sim/cockpit2/engine/indicators/CHT_CYL_deg_C")   
local oilTempDR   = globalProperty("sim/cockpit2/engine/indicators/oil_temperature_deg_C[0]", 0.0)  -- In °F
local fuelFlowDR  = globalProperty("sim/cockpit2/engine/indicators/fuel_flow_kg_sec[0]", 0.0)
local voltsDR     = globalProperty("sim/cockpit2/electrical/bus_volts[0]", 0.0)
local oatDR       = globalProperty("sim/cockpit2/temperature/outside_air_temp_degf", 0.0)

-- Additional references for “REM,” “Oil Press,” etc. as needed:
local fuelRemDR   = createGlobalPropertyf("my/custom/fuel_remaining", 58.9) 
local oilPressDR  = createGlobalPropertyf("my/custom/oil_press_psi", 70.0)

------------------------------------------------------------
-- INTERNAL VARIABLES
------------------------------------------------------------
local manifoldPressure = 0
local rpm = 0
local oilTemp = 0
local oilPress = 0
local fuelFlow = 0
local volts = 0
local oat = 0
local fuelRem = 0

local egtCylValues = {}
local chtCylValues = {}

local maxEGT = 1650  
local maxCHT = 450   

-- Define subcomponents
components = {
    gauge_component {
        position = {320, 600, 150, 60},
        dataref = oilTempDR,
        minValue = 75,
        maxValue = 250,
        dangerMin = 75,
        dangerMax = 245,
        nameAbbrv = "OIL-T"
    },
    gauge_component {
        position = {320, 520, 150, 60},
        dataref = oilPressDR,
        minValue = 0,
        maxValue = 115,
        dangerMin = 20,
        dangerMax = 115,
        nameAbbrv = "OIL-P"
    },
    gauge_component {
        position = {320, 440, 150, 60},
        dataref = fuelFlowDR,
        minValue = 0,
        maxValue = 20,
        dangerMin = 0,
        dangerMax = 20,
        nameAbbrv = "GPH"
    },
    gauge_component {
        position = {320, 360, 150, 60},
        dataref = fuelRemDR,
        minValue = 0,
        maxValue = 60,
        dangerMin = 0,
        dangerMax = 60,
        nameAbbrv = "FUEL"
    },
    gauge_component {
        position = {320, 280, 150, 60},
        dataref = oatDR,
        minValue = -50,
        maxValue = 50,
        dangerMin = -50,
        dangerMax = 50,
        nameAbbrv = "OAT"
    },
    gauge_component {
        position = {320, 200, 150, 60},
        dataref = voltsDR,
        minValue = 0,
        maxValue = 30,
        dangerMin = 0,
        dangerMax = 30,
        nameAbbrv = "BAT"
    }
}

-- Compute approximate % power:
local function computePercentPower(mp, rpm)
    local result = (mp / 29.0) * (rpm / 2700.0) * 100
    if result > 100 then result = 100 end
    return result
end

------------------------------------------------------------
-- UPDATE
------------------------------------------------------------
function update()
    manifoldPressure = get(mpDR) or 0
    rpm = get(rpmDR) or 0
    oilTemp = get(oilTempDR) or 0
    oilPress = get(oilPressDR) or 0
    fuelFlow = get(fuelFlowDR) or 0
    volts = get(voltsDR) or 0
    oat = get(oatDR) or 0
    fuelRem = get(fuelRemDR) or 0
    
    for i = 1, numCylinders do
        egtCylValues[i] = get(egtCylDR, i) or 0
        chtCylValues[i] = get(chtCylDR, i) or 0
    end

    updateAll(components)
end

------------------------------------------------------------
-- DRAW
------------------------------------------------------------

function draw()
    ----------------------------------
    -- 1) Background
    ----------------------------------
    sasl.gl.drawRectangle(0, 0, size[1], size[2], {0, 0, 0, 1})
    
    ----------------------------------
    -- 2) Large Round Gauge for RPM/MAP
    ----------------------------------
    local gaugeCenterX = 160
    local gaugeCenterY = size[2] - 160   -- 160 px down from top
    local gaugeRadius  = 140
    
    -- Draw outer circle:
    sasl.gl.drawCircle(gaugeCenterX, gaugeCenterY, gaugeRadius, false, {0,1,0,1})
    
    -- Optionally draw a green arc from, say, 0 to 2700 RPM:
    -- We'll define a function to get the angle for a given RPM:
    local function rpmToAngle(rpmVal)
        -- Suppose we map 0 RPM = -135° and 2700 RPM = +135° (i.e., 270 degrees total)
        local fraction = rpmVal / 2700
        local angle = -135 + fraction * 270
        return angle
    end
    
    -- We can draw the arc for normal RPM range:
    local startAngle = rpmToAngle(0)
    local endAngle   = rpmToAngle(2700)
    sasl.gl.drawArc(gaugeCenterX, gaugeCenterY, gaugeRadius - 5, gaugeRadius, startAngle, endAngle - startAngle, {0, 1, 0, 1})
    
    -- Draw the redline area above 2700 if desired (example only):
    -- e.g. if max is 2700, we skip that. If you had 2800 or 3000, you could do:
    -- sasl.gl.drawArc(...)

    -- Needle for current RPM
    local currentAngle = math.rad(rpmToAngle(rpm))
    local needleLength = gaugeRadius - 20
    local needleX = gaugeCenterX + needleLength * math.cos(currentAngle)
    local needleY = gaugeCenterY + needleLength * math.sin(currentAngle)
    sasl.gl.drawLine(gaugeCenterX, gaugeCenterY, needleX, needleY, {1,1,1,1})

    -- Draw big text of actual RPM in center
    sasl.gl.drawText(
        myFontId,
        gaugeCenterX,
        gaugeCenterY + 10,
        string.format("%.0f", rpm),
        24, true, false, TEXT_ALIGN_CENTER,
        {1,1,1,1}
    )
    
    -- Underneath that, draw MAP
    sasl.gl.drawText(
        myFontId,
        gaugeCenterX,
        gaugeCenterY - 20,
        string.format("%.1f\"", manifoldPressure),
        20, true, false, TEXT_ALIGN_CENTER,
        {1,1,1,1}
    )
    
    ----------------------------------
    -- 3) % HP readout near the gauge
    ----------------------------------
    local pctHP = computePercentPower(manifoldPressure, rpm)
    sasl.gl.drawText(
        myFontId,
        gaugeCenterX, 
        gaugeCenterY - 55,
        string.format("%2.0f %% HP", pctHP),
        20, true, false, TEXT_ALIGN_CENTER,
        {1,1,1,1}
    )

    ----------------------------------
    -- 4) EGT/CHT Bar Graph region
    ----------------------------------
    local barsX     = 20
    local barsY     = 100
    local barsWidth = size[1] - 40
    local barsHeight = 200  -- portion in the lower/middle
    
    -- We can place the EGT and CHT numbers above each bar:
    local colWidth = barsWidth / numCylinders
    
    -- Identify highest EGT (for optional highlight)
    local highestEgtIndex = 1
    local highestEgtValue = egtCylValues[1]
    for i = 2, numCylinders do
        if egtCylValues[i] > highestEgtValue then
            highestEgtIndex = i
            highestEgtValue = egtCylValues[i]
        end
    end
    
    for i = 1, numCylinders do
        local cx = barsX + (i - 1) * colWidth + colWidth * 0.5
        -- EGT in °F
        local egtVal = egtCylValues[i]
        local chtVal = chtCylValues[i]
        
        -- Fraction for height
        local egtFrac = egtVal / maxEGT
        if egtFrac > 1 then egtFrac = 1 end
        local chtFrac = chtVal / maxCHT
        if chtFrac > 1 then chtFrac = 1 end
        
        -- Max bar for EGT ~ 1650
        local egtBarH = egtFrac * 120
        -- We'll use smaller bar for CHT, or place it differently
        local chtBarH = chtFrac * 80
        
        -- Fixed segment height
        local segmentHeight = 10
        
        -- Define colors
        local egtColor = {0.0, 0.5, 1.0, 1}  -- Specific blue color for EGT
        local chtColorNormal = {0.0, 1.0, 0.0, 1}  -- Green for normal CHT
        local chtColorHigh = {1.0, 0.0, 0.0, 1}  -- Red for high CHT
        
        -- Draw segmented EGT bar
        local numSegments = math.floor(egtBarH / segmentHeight)
        for j = 0, numSegments - 1 do
            sasl.gl.drawRectangle(cx - 10, barsY + j * segmentHeight, 10, segmentHeight - 2, egtColor)
        end
        
        -- Determine CHT color
        local chtColor = chtVal > maxCHT and chtColorHigh or chtColorNormal
        
        -- Draw segmented CHT bar
        numSegments = math.floor(chtBarH / segmentHeight)
        for j = 0, numSegments - 1 do
            sasl.gl.drawRectangle(cx + 2, barsY + j * segmentHeight, 8, segmentHeight - 2, chtColor)
        end
        
        -- Cylinder EGT label above (blue text)
        sasl.gl.drawText(myFontId, cx, barsY + egtBarH + 5, string.format("%.0f", egtVal), 14, true, false, TEXT_ALIGN_CENTER, {0.5,0.7,1,1})
        
        -- Cylinder CHT label below (white text)
        sasl.gl.drawText(myFontId, cx + 6, barsY + chtBarH + 5, string.format("%.0f", chtVal), 10, true, false, TEXT_ALIGN_LEFT, {1,1,1,1})
        
        -- Cylinder index near bottom
        sasl.gl.drawText(myFontId, cx, barsY - 15, tostring(i), 14, true, false, TEXT_ALIGN_CENTER, {1,1,1,1})
        
        -- Optional highlight for highest EGT
        if i == highestEgtIndex then
            sasl.gl.drawWideLine(cx - 15, barsY + egtBarH + 2, cx + 15, barsY + egtBarH + 2, 2, {1, 1, 0, 1})
        end
    end
    
    ----------------------------------
    -- 6) Large Digital EGT/CHT readout at bottom
    ----------------------------------
    local avgEGT = 0
    local avgCHT = 0
    for i=1, numCylinders do
        avgEGT = avgEGT + egtCylValues[i]
        avgCHT = avgCHT + chtCylValues[i]
    end
    avgEGT = avgEGT / numCylinders
    avgCHT = avgCHT / numCylinders
    
    -- The screenshot shows EGT large on left, CHT large on right
    local bottomY = 40
    sasl.gl.drawText(myFontId, 100, bottomY,  string.format("%.0f", avgEGT), 32, true, false, TEXT_ALIGN_CENTER, {1,1,1,1})
    sasl.gl.drawText(myFontId, 280, bottomY,  string.format("%.0f", avgCHT), 32, true, false, TEXT_ALIGN_CENTER, {1,1,1,1})
    
    -- You can label them:
    sasl.gl.drawText(myFontId, 100, bottomY - 30, "EGT", 16, true, false, TEXT_ALIGN_CENTER, {0.8,0.8,0.8,1})
    sasl.gl.drawText(myFontId, 280, bottomY - 30, "CHT", 16, true, false, TEXT_ALIGN_CENTER, {0.8,0.8,0.8,1})

    drawAll(components)
end