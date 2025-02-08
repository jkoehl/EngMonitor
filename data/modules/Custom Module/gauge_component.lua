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

-- Function to draw the gauge
function draw()
    -- Define margin
    local leftMargin = 10
    local bottomMargin = 2
    local linePosY = 20
    local lineHeight = 10
    local width = get(position)[3]
    local height = get(position)[4]

    -- Adjust the starting and ending positions of the gauge line
    local lineStart = leftMargin
    local lineEnd = width - leftMargin
    
    -- Calculate the scaling factor
    local valueToPixelScaleFactor = (lineEnd - lineStart) / (get(maxValue) - get(minValue))
    -- Log all of the inputs to the scale factor calculation
    print("================================")
    print("nameAbbrv: " .. get(nameAbbrv))
    print("lineStart: " .. lineStart .. " lineEnd: " .. lineEnd)
    print("minValue: " .. get(minValue) .. " maxValue: " .. get(maxValue))
    print("valueToPixelScaleFactor: " .. valueToPixelScaleFactor)

    -- Draw the gauge line over the background
    sasl.gl.drawRectangle(lineStart, linePosY + bottomMargin, lineEnd - lineStart, lineHeight, {0, 1, 0, 1}) -- Green line
    
    -- Calculate positions for danger zones
    local lowDangerStartX = lineStart
    local lowDangerEndX = math.max((get(dangerMin) - get(minValue)) * valueToPixelScaleFactor, lineStart)
    local highDangerStartX = math.max(lineEnd - ((get(maxValue) - get(dangerMax)) * valueToPixelScaleFactor), lineEnd)
    local highDangerEndX = math.min(lineEnd - ((get(maxValue) - get(dangerMax)) * valueToPixelScaleFactor), lineEnd)

    -- Print all of the danger zone inputs to the log
    print("================================")
    print("nameAbbrv: " .. get(nameAbbrv))
    print("dangerMin: " .. get(dangerMin) .. ", dangerMax: " .. get(dangerMax))
    print("lowDangerStartX: " .. lowDangerStartX .. ", lowDangerEndX: " .. lowDangerEndX)
    print("highDangerStartX: " .. highDangerStartX .. ", highDangerEndX: " .. highDangerEndX)

    -- Draw danger zones
    sasl.gl.drawRectangle(lowDangerStartX, linePosY + bottomMargin, lowDangerEndX - lowDangerStartX, lineHeight, {1, 0, 0, 1}) -- Red low danger
    sasl.gl.drawRectangle(highDangerStartX, linePosY + bottomMargin, highDangerEndX - highDangerStartX, lineHeight, {1, 0, 0, 1}) -- Red high danger
    
    local needlePositionX = lineStart + ((get(currentValue) - get(minValue)) * valueToPixelScaleFactor)
    local needlePositionY = linePosY + bottomMargin + lineHeight
    -- Log all of the inputs into the needle calculation
    print("currentValue: " .. get(currentValue))
    print("needlePositionX: " .. needlePositionX .. ", needlePositionY: " .. needlePositionY)   

    -- Draw the needle pointing down
    sasl.gl.drawTriangle(needlePositionX, needlePositionY, needlePositionX - 5, needlePositionY + 5, needlePositionX + 5, needlePositionY + 5, {1, 1, 1, 1}) -- White needle
    
    -- Draw the digital readout
    sasl.gl.drawText(myFontId, leftMargin, bottomMargin, string.format("%.0f", get(currentValue)), 18, false, false, TEXT_ALIGN_LEFT, {1, 1, 1, 1})
    sasl.gl.drawText(myFontId, leftMargin + 40, bottomMargin, get(nameAbbrv), 18, false, false, TEXT_ALIGN_LEFT, {1, 1, 1, 1})
end

-- Update function
function update()
    -- Update the current value from the dataref
    currentValue = get(dataref)
end
