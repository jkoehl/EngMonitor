panel2d = false
panelWidth3d = 2048
panelHeight3d = 2048

sasl.options.setAircraftPanelRendering(true)
sasl.options.set3DRendering(false)
sasl.options.setInteractivity(false)

size = { 2048, 2048 }

components = { 
    instrument {
        position = { 0, 775, 400, 500 };
    }
}

newWindow = contextWindow { 
    position = { 50, 50, 640, 640 };
    noBackground = false; 
    minimumSize = { 300, 300 };
    maximumSize = { 1200, 1200 };
    gravity = { 0, 1, 0, 1 };
    visible = true;
    components = { 
        instrument {
            position = { 0, 0, 400, 500 };
        }
    }
}

-- Render to texture at
-- X=0, Y=775
-- width=400
-- height=500