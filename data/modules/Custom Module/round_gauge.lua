-- Round Gauge Component
-- This component represents a round gauge with a needle pointing to a current value.

local myFontId = sasl.gl.loadFont("Roboto-Regular.ttf")

-- Properties
defineProperty("dataref", "")
defineProperty("minValue", 0)
defineProperty("maxValue", 1000)
defineProperty("currentValue", 0)
defineProperty("dangerMin", 0)
defineProperty("dangerMax", 1000)

-- Function to draw the round gauge
function draw()
    local centerX = get(position)[3] / 2
    local centerY = get(position)[4] / 2
    local radius = math.min(centerX, centerY) - 10
    
    -- Calculate the scaling factor
    local valueToAngleScaleFactor = 270 / (get(maxValue) - get(minValue))
    
    -- Draw the gauge circle
    sasl.gl.drawCircle(centerX, centerY, radius, {0, 1, 0, 1}) -- Green circle
    
    -- Calculate angles for danger zones
    local lowDangerStartAngle = 135
    local lowDangerEndAngle = 135 + ((get(dangerMin) - get(minValue)) * valueToAngleScaleFactor)
    local highDangerStartAngle = 135 + ((get(dangerMax) - get(minValue)) * valueToAngleScaleFactor)
    local highDangerEndAngle = 405
    
    -- Draw danger zones
    sasl.gl.drawArc(centerX, centerY, radius, lowDangerStartAngle, lowDangerEndAngle, {1, 0, 0, 1}) -- Red low danger
    sasl.gl.drawArc(centerX, centerY, radius, highDangerStartAngle, highDangerEndAngle, {1, 0, 0, 1}) -- Red high danger
    
    -- Calculate needle angle
    local needleAngle = 135 + ((get(currentValue) - get(minValue)) * valueToAngleScaleFactor)
    
    -- Draw the needle
    sasl.gl.drawLine(centerX, centerY, centerX + radius * math.cos(math.rad(needleAngle)), centerY + radius * math.sin(math.rad(needleAngle)), {1, 1, 1, 1}) -- White needle
    
    -- Draw the digital readout
    sasl.gl.setFontBold(myFontId, true)
    sasl.gl.drawText(myFontId, centerX, centerY - radius - 20, string.format("%.1f", get(currentValue)), 22, false, false, TEXT_ALIGN_CENTER, {1, 1, 1, 1})
    sasl.gl.setFontBold(myFontId, false)
end

-- Update function
function update()
    -- Update the current value from the dataref
    currentValue = get(dataref)
end
