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
local rpmDR       = globalProperty("sim/cockpit2/engine/indicators/engine_speed_rpm[0]", 0.0)  
local egtCylDR    = globalProperty("sim/cockpit2/engine/indicators/EGT_CYL_deg_C")   
local chtCylDR    = globalProperty("sim/cockpit2/engine/indicators/CHT_CYL_deg_C")   
local oilTempDR   = globalProperty("sim/cockpit2/engine/indicators/oil_temperature_deg_C[0]", 0.0)  -- In °F
local oilPressDR  = globalProperty("sim/cockpit2/engine/indicators/oil_pressure_psi[0]", 0.0)
local fuelFlowDR  = globalProperty("sim/cockpit2/engine/indicators/fuel_flow_kg_sec[0]", 0.0)
local voltsDR     = globalProperty("sim/cockpit2/electrical/bus_volts[0]", 0.0)
local oatDR       = globalProperty("sim/cockpit2/temperature/outside_air_temp_degf", 0.0)

local fuelFlowGPH = createProperty("fuelFlowGPH")
local fuelRemDR   = createGlobalPropertyf("my/custom/fuel_remaining", 0) 

------------------------------------------------------------
-- INTERNAL VARIABLES
------------------------------------------------------------
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
    line_gauge {
        position = {320, 600, 150, 60},
        dataref = oilTempDR,
        minValue = 75,
        maxValue = 250,
        dangerMin = 75,
        dangerMax = 245,
        nameAbbrv = "OIL-T"
    },
    line_gauge {
        position = {320, 520, 150, 60},
        dataref = oilPressDR,
        minValue = 0,
        maxValue = 115,
        dangerMin = 20,
        dangerMax = 115,
        nameAbbrv = "OIL-P"
    },
    line_gauge {
        position = {320, 440, 150, 60},
        dataref = fuelFlowGPH,
        minValue = 0,
        maxValue = 20,
        dangerMin = 0,
        dangerMax = 20,
        nameAbbrv = "GPH"
    },
    line_gauge {   
        position = {320, 360, 150, 60},
        dataref = fuelRemDR,
        minValue = 0,
        maxValue = 60,
        dangerMin = 0,
        dangerMax = 60,
        nameAbbrv = "FUEL"
    },
    line_gauge {
        position = {320, 280, 150, 60},
        dataref = oatDR,
        minValue = -50,
        maxValue = 50,
        dangerMin = -50,
        dangerMax = 50,
        nameAbbrv = "OAT"
    },
    line_gauge {
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
    rpm = get(rpmDR) or 0
    oilTemp = get(oilTempDR) or 0
    oilPress = get(oilPressDR) or 0
    volts = get(voltsDR) or 0
    oat = get(oatDR) or 0
    fuelRem = get(fuelRemDR) or 0
    
    for i = 1, numCylinders do
        egtCylValues[i] = get(egtCylDR, i) or 0
        chtCylValues[i] = get(chtCylDR, i) or 0
    end

    set(fuelFlowGPH, get(fuelFlowDR) * 1320.0)
    updateAll(components)
end

------------------------------------------------------------
-- DRAW
------------------------------------------------------------

-- Function to draw the RPM gauge
local function drawRPMGauge()
    local gaugeCenterX = 160
    local gaugeCenterY = size[2] - 160   -- 160 px down from top
    local gaugeRadius  = 120
    
    -- Adjust the arc to be a half-circle
    local startAngle = 0  -- Start at the top
    local endAngle = 180     -- End at the bottom
    sasl.gl.drawArc(gaugeCenterX, gaugeCenterY, gaugeRadius - 10, gaugeRadius, startAngle, endAngle - startAngle, {0, 1, 0, 1})

    -- We'll define a function to get the angle for a given RPM:
    local function rpmToAngle(rpmVal)
        -- Suppose we map 0 RPM = 180° and 2700 RPM = 0° (i.e., 270 degrees total)
        local fraction = rpmVal / 2700
        local angle = 180 - fraction * 270
        return angle
    end
    
    -- Draw the small white triangle needle on the outer edge
    local currentRPM = rpm
    local needleAngle = rpmToAngle(currentRPM)
    local needleLength = 10
    local needleBaseWidth = 5
    
    local needleTipX = gaugeCenterX + (gaugeRadius - needleLength) * math.cos(math.rad(needleAngle))
    local needleTipY = gaugeCenterY + (gaugeRadius - needleLength) * math.sin(math.rad(needleAngle))
    
    local needleBaseLeftX = gaugeCenterX + (gaugeRadius + needleLength) * math.cos(math.rad(needleAngle + needleBaseWidth))
    local needleBaseLeftY = gaugeCenterY + (gaugeRadius + needleLength) * math.sin(math.rad(needleAngle + needleBaseWidth))
    
    local needleBaseRightX = gaugeCenterX + (gaugeRadius + needleLength) * math.cos(math.rad(needleAngle - needleBaseWidth))
    local needleBaseRightY = gaugeCenterY + (gaugeRadius + needleLength) * math.sin(math.rad(needleAngle - needleBaseWidth))
    
    -- Draw black outline for the RPM needle
    local outlineOffset = 2
    local outlineTipX = gaugeCenterX + (gaugeRadius - needleLength - outlineOffset) * math.cos(math.rad(needleAngle))
    local outlineTipY = gaugeCenterY + (gaugeRadius - needleLength - outlineOffset) * math.sin(math.rad(needleAngle))
    
    local outlineBaseLeftX = gaugeCenterX + (gaugeRadius + needleLength + outlineOffset) * math.cos(math.rad(needleAngle + needleBaseWidth))
    local outlineBaseLeftY = gaugeCenterY + (gaugeRadius + needleLength + outlineOffset) * math.sin(math.rad(needleAngle + needleBaseWidth))
    
    local outlineBaseRightX = gaugeCenterX + (gaugeRadius + needleLength + outlineOffset) * math.cos(math.rad(needleAngle - needleBaseWidth))
    local outlineBaseRightY = gaugeCenterY + (gaugeRadius + needleLength + outlineOffset) * math.sin(math.rad(needleAngle - needleBaseWidth))
    
    sasl.gl.drawTriangle(outlineTipX, outlineTipY, outlineBaseLeftX, outlineBaseLeftY, outlineBaseRightX, outlineBaseRightY, {0, 0, 0, 1})
    
    -- RPM needle
    sasl.gl.drawTriangle(needleTipX, needleTipY, needleBaseLeftX, needleBaseLeftY, needleBaseRightX, needleBaseRightY, {1, 1, 1, 1})
    
    -- Draw hash marks around the RPM gauge
    local numMajorTicks = 10
    local numMinorTicks = 20
    local majorTickLength = 20
    local minorTickLength = 15
    
    for i = 0, numMajorTicks do
        local angle = 180 - (i * 180 / numMajorTicks)
        local startX = gaugeCenterX + (gaugeRadius - majorTickLength) * math.cos(math.rad(angle))
        local startY = gaugeCenterY + (gaugeRadius - majorTickLength) * math.sin(math.rad(angle))
        local endX = gaugeCenterX + gaugeRadius * math.cos(math.rad(angle))
        local endY = gaugeCenterY + gaugeRadius * math.sin(math.rad(angle))
        sasl.gl.drawLine(startX, startY, endX, endY, {1, 1, 1, 1})
    end
    
    for i = 0, numMinorTicks do
        local angle = 180 - (i * 180 / numMinorTicks)
        local startX = gaugeCenterX + (gaugeRadius - minorTickLength) * math.cos(math.rad(angle))
        local startY = gaugeCenterY + (gaugeRadius - minorTickLength) * math.sin(math.rad(angle))
        local endX = gaugeCenterX + gaugeRadius * math.cos(math.rad(angle))
        local endY = gaugeCenterY + gaugeRadius * math.sin(math.rad(angle))
        sasl.gl.drawLine(startX, startY, endX, endY, {1, 1, 1, 1})
    end
    
    -- Draw big text of actual RPM in center with an RPM label above it
    sasl.gl.drawText(
        myFontId,
        gaugeCenterX,
        gaugeCenterY + 65,
        "RPM",
        30, true, false, TEXT_ALIGN_CENTER,
        {1,1,1,1}
    )
    sasl.gl.drawText(
        myFontId,
        gaugeCenterX,
        gaugeCenterY + 10,
        string.format("%.0f", rpm),
        48, true, false, TEXT_ALIGN_CENTER,
        {1,1,1,1}
    )
end

function draw()
    ----------------------------------
    -- 1) Background
    ----------------------------------
    sasl.gl.drawRectangle(0, 0, size[1], size[2], {0, 0, 0, 1})
    
    ----------------------------------
    -- 2) Large Round Gauge for RPM/MAP
    ----------------------------------
    drawRPMGauge()
    
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