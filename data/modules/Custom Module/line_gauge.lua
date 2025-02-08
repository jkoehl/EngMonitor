-- Gauge Component
-- This component represents a gauge with a needle pointing to a current value.

local myFontId = sasl.gl.loadFont("Roboto-Regular.ttf")

-- Properties
defineProperty("nameAbbrv", "")
defineProperty("minValue", 0)
defineProperty("maxValue", 1000)
defineProperty("currentValue", 0)
defineProperty("dangerMin", 0)
defineProperty("dangerMax", 1000)
defineProperty("valueFormat", "%.1f")

-- Function to draw the gauge
function draw()
    local leftMargin = 0
    local bottomMargin = 2
    local linePosY = 20
    local lineWidth = get(position)[3] - (leftMargin + leftMargin)
    local lineMiddleX = lineWidth / 2
    local lineHeight = 10
    local width = get(position)[3]
    local height = get(position)[4]
    local needleBaseWidth = 14
    local needleLength = 14
    local outlineWidth = 2

    -- Adjust the starting and ending positions of the gauge line
    local lineStart = leftMargin
    local lineEnd = width - leftMargin
    
    -- Calculate the scaling factor
    local valueToPixelScaleFactor = (lineEnd - lineStart) / (get(maxValue) - get(minValue))

    -- Draw the gauge line over the background
    sasl.gl.drawRectangle(lineStart, linePosY + bottomMargin, lineEnd - lineStart, lineHeight, {0, 1, 0, 1}) -- Green line
    
    -- Calculate positions for danger zones
    local lowDangerStartX = lineStart
    local lowDangerEndX = math.max((get(dangerMin) - get(minValue)) * valueToPixelScaleFactor, lineStart)
    local highDangerStartX = math.max(lineEnd - ((get(maxValue) - get(dangerMax)) * valueToPixelScaleFactor), lineEnd)
    local highDangerEndX = math.min(lineEnd - ((get(maxValue) - get(dangerMax)) * valueToPixelScaleFactor), lineEnd)

    -- Draw danger zones
    sasl.gl.drawRectangle(lowDangerStartX, linePosY + bottomMargin, lowDangerEndX - lowDangerStartX, lineHeight, {1, 0, 0, 1}) -- Red low danger
    sasl.gl.drawRectangle(highDangerStartX, linePosY + bottomMargin, highDangerEndX - highDangerStartX, lineHeight, {1, 0, 0, 1}) -- Red high danger
    
    local needlePositionX = lineStart + ((get(currentValue) - get(minValue)) * valueToPixelScaleFactor)
    local needlePositionY = linePosY + bottomMargin

    -- Draw the needle using a black and white triangle
    sasl.gl.drawTriangle(needlePositionX, needlePositionY, needlePositionX - needleBaseWidth / 2, needlePositionY + needleLength, needlePositionX + needleBaseWidth / 2, needlePositionY + needleLength, {0, 0, 0, 1})
    sasl.gl.drawTriangle(
        needlePositionX, needlePositionY + outlineWidth, 
        needlePositionX - (needleBaseWidth / 2) + outlineWidth, needlePositionY + needleLength - outlineWidth, 
        needlePositionX + (needleBaseWidth / 2) - outlineWidth, needlePositionY + needleLength - outlineWidth, 
        {1, 1, 1, 1}
    )
    
    -- Draw the digital readout
    sasl.gl.setFontBold(myFontId, true)
    sasl.gl.drawText(myFontId, lineMiddleX - 2, bottomMargin, string.format(get(valueFormat), get(currentValue)), 18, false, false, TEXT_ALIGN_RIGHT, {1, 1, 1, 1})
    sasl.gl.setFontBold(myFontId, false)
    sasl.gl.drawText(myFontId, lineMiddleX + 2, bottomMargin, get(nameAbbrv), 12, false, false, TEXT_ALIGN_LEFT, {1, 1, 1, 1})
end

-- Update function
function update()
    -- Update the current value from the dataref
    currentValue = get(dataref)
end
