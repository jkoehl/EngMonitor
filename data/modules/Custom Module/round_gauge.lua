-- Round Gauge Component
-- This component represents a round gauge with a needle pointing to a current value.

local myFontId = sasl.gl.loadFont("Roboto-Regular.ttf")

-- Properties
defineProperty("minValue", 0)
defineProperty("maxValue", 3000)
defineProperty("currentValue", 0)
defineProperty("dangerMin", 0)
defineProperty("dangerMax", 2700)
defineProperty("nameAbbrv", "")
defineProperty("valueFormat", "%.2f")

-- Function to draw the round gauge
function draw()
    local gaugeRadius  = get(position)[3] / 2
    local gaugeCenterX = gaugeRadius
    local gaugeCenterY = 0
    local radiusThickness = 8
    
    -- Adjust the arc to be a half-circle
    local startAngle = 0  -- Start at the top
    local endAngle = 180     -- End at the bottom
    sasl.gl.drawArc(gaugeCenterX, gaugeCenterY, gaugeRadius - radiusThickness, gaugeRadius, startAngle, endAngle - startAngle, {0, 1, 0, 1})

    -- We'll define a function to get the angle for a given RPM:
    local function rpmToAngle(rpmVal)
        local fraction = rpmVal / get(maxValue)
        local angle = 180 - fraction * 180
        return angle
    end
    
    -- Draw the danger zone arc in red for the min and max danger values
    local dangerMaxStartAngle = rpmToAngle(get(dangerMax))
    local dangerMaxEndAngle = rpmToAngle(get(maxValue))
    sasl.gl.drawArc(gaugeCenterX, gaugeCenterY, gaugeRadius - radiusThickness, gaugeRadius, dangerMaxStartAngle, dangerMaxEndAngle - dangerMaxStartAngle, {1, 0, 0, 1})
    local dangerMinStartAngle = rpmToAngle(get(dangerMin))
    local dangerMinEndAngle = rpmToAngle(get(minValue))
    sasl.gl.drawArc(gaugeCenterX, gaugeCenterY, gaugeRadius - radiusThickness, gaugeRadius, dangerMinStartAngle, dangerMinEndAngle - dangerMinStartAngle, {1, 0, 0, 1})

    -- Draw the small white triangle needle on the outer edge
    local currentRPM = currentValue
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
        sasl.gl.drawWideLine(startX, startY, endX, endY, 2, {1, 1, 1, 1})
    end
    
    for i = 0, numMinorTicks do
        local angle = 180 - (i * 180 / numMinorTicks)
        local startX = gaugeCenterX + (gaugeRadius - minorTickLength) * math.cos(math.rad(angle))
        local startY = gaugeCenterY + (gaugeRadius - minorTickLength) * math.sin(math.rad(angle))
        local endX = gaugeCenterX + gaugeRadius * math.cos(math.rad(angle))
        local endY = gaugeCenterY + gaugeRadius * math.sin(math.rad(angle))
        sasl.gl.drawWideLine(startX, startY, endX, endY, 2, {1, 1, 1, 1})
    end
    
    -- Draw big text of actual RPM in center with an RPM label above it
    sasl.gl.drawText(
        myFontId,
        gaugeCenterX,
        gaugeCenterY + 50,
        get(nameAbbrv),
        24, true, false, TEXT_ALIGN_CENTER,
        {1,1,1,1}
    )
    sasl.gl.drawText(
        myFontId,
        gaugeCenterX,
        gaugeCenterY,
        string.format("%.0f", currentValue),
        48, true, false, TEXT_ALIGN_CENTER,
        {1,1,1,1}
    )
end

-- Update function
function update()
    -- Update the current value from the dataref
    currentValue = get(dataref)
end
