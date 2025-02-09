-- ==========================================================
--  JPI EDM-730/830-Style Engine Monitor (Closer to real layout)
--  SASL plugin script
-- ==========================================================
-- Define the size of the component
size = {400, 500}

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
local fuelRemDR   = globalProperty("sim/cockpit2/fuel/fuel_quantity[0]", 0.0)
local voltsDR     = globalProperty("sim/cockpit2/electrical/bus_volts[0]", 0.0)
local oatDR       = globalProperty("sim/cockpit2/temperature/outside_air_temp_degf", 0.0)

local fuelFlowGPH = createProperty("fuelFlowGPH")

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
        position = {290, 445, 100, 45},
        dataref = oilTempDR,
        minValue = 75,
        maxValue = 250,
        dangerMin = 75,
        dangerMax = 245,
        nameAbbrv = "OIL-T",
        valueFormat = "%.0f"
    },
    line_gauge {
        position = {290, 400, 100, 45},
        dataref = oilPressDR,
        minValue = 0,
        maxValue = 115,
        dangerMin = 20,
        dangerMax = 110,
        nameAbbrv = "OIL-P",
        valueFormat = "%.0f"
    },
    line_gauge {
        position = {290, 355, 100, 45},
        dataref = voltsDR,
        minValue = 20,
        maxValue = 32,
        dangerMin = 24,
        dangerMax = 28,
        nameAbbrv = "VOLTS",
        valueFormat = "%.1f"
    },
    line_gauge {   
        position = {290, 310, 100, 45},
        dataref = fuelFlowGPH,
        minValue = 0,
        maxValue = 20,
        dangerMin = 0,
        dangerMax = 20,
        nameAbbrv = "GPH",
        valueFormat = "%.1f"
    },
    line_gauge {
        position = {290, 265, 100, 45},
        dataref = fuelRemDR,
        minValue = 0,
        maxValue = 60,
        dangerMin = 10,
        dangerMax = 60,
        nameAbbrv = "REM",
        valueFormat = "%.1f"
    },
    line_gauge {
        position = {290, 220, 100, 45},
        dataref = oatDR,
        minValue = -50,
        maxValue = 120,
        dangerMin = -50,
        dangerMax = 120,
        nameAbbrv = "OAT-F",
        valueFormat = "%.1f"

    },
    round_gauge {
        position = {10, 380, 200, 240},
        dataref = rpmDR,
        minValue = 0,
        maxValue = 3000,
        dangerMin = 0,
        dangerMax = 2700,
        nameAbbrv = "RPM",
        valueFormat = "%.0f"
    }
}

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

function drawDottedLine(x1, y1, x2, y2, color)
    local step = 5  -- Length of each dot
    local gap = 3   -- Gap between dots
    local length = math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
    local dx = (x2 - x1) / length
    local dy = (y2 - y1) / length

    for i = 0, length, step + gap do
        local startX = x1 + i * dx
        local startY = y1 + i * dy
        local endX = startX + step * dx
        local endY = startY + step * dy
        sasl.gl.drawLine(startX, startY, endX, endY, color)
    end
end

function draw()
    ----------------------------------
    -- 1) Background
    ----------------------------------
    sasl.gl.drawRectangle(0, 0, get(position)[3], get(position)[4], {0, 0, 0, 1})
    
    ----------------------------------
    -- 3) Range Indicator
    ----------------------------------
    local lowRangeValue = 170
    local highRangeValue = 450
    local rangeX = 35  -- Position to the left of the bars
    local rangeY = 100
    local rangeHeight = 80  -- Align with CHT bar height
    local rangeColor = {0, 1, 0, 1}
    local dangerColor = {1, 0, 0, 1}
    
    -- Draw the range indicator line
    sasl.gl.drawRectangle(rangeX, rangeY, 5, rangeHeight, rangeColor)
    sasl.gl.drawRectangle(rangeX, rangeY + (rangeHeight * (highRangeValue / maxCHT)), 5, rangeHeight * 0.1, dangerColor)
    
    -- Add range labels
    sasl.gl.drawText(myFontId, rangeX - 10, rangeY + rangeHeight - 10, tostring(highRangeValue), 10, false, false, TEXT_ALIGN_RIGHT, rangeColor)
    sasl.gl.drawText(myFontId, rangeX - 10, rangeY, tostring(lowRangeValue), 10, false, false, TEXT_ALIGN_RIGHT, rangeColor)

    ----------------------------------
    -- 4) EGT/CHT Bar Graph region
    ----------------------------------
    local barsX     = 30
    local barsY     = 100
    local barsWidth = 200
    local barsHeight = 200  -- portion in the lower/middle
    local labelsXOffset = 100
    
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
        local segmentHeight = 5
        
        -- Define colors
        local egtColor = {0.0, 0.5, 1.0, 1}  -- Specific blue color for EGT
        local chtColorNormal = {0.0, 1.0, 0.0, 1}  -- Green for normal CHT
        local chtColorHigh = {1.0, 0.0, 0.0, 1}  -- Red for high CHT

        -- Draw white line from bottom of graph to where the EGT and CHT labels start
        drawDottedLine(cx + 1, barsY, cx + 1, barsY + chtBarH + labelsXOffset - 5, {1, 1, 1, 1})

        -- Calculate position for the red line
        local highRangeY = barsY + (highRangeValue / maxCHT) * 80
        sasl.gl.drawLine(cx + 2, highRangeY, cx + colWidth * 0.5, highRangeY, {1, 0, 0, 1})

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
        
        -- Cylinder EGT label directly above CHT (blue text)
        sasl.gl.drawText(myFontId, cx, barsY + chtBarH + labelsXOffset + 20, string.format("%.0f", egtVal), 14, true, false, TEXT_ALIGN_CENTER, egtColor)
        
        -- Cylinder CHT label below EGT (white text)
        sasl.gl.drawText(myFontId, cx, barsY + chtBarH + labelsXOffset, string.format("%.0f", chtVal), 14, true, false, TEXT_ALIGN_CENTER, chtColor)
        
        -- Cylinder index near bottom
        sasl.gl.drawText(myFontId, cx, barsY - 15, tostring(i), 14, true, false, TEXT_ALIGN_CENTER, {1,1,1,1})
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

