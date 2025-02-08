panel2d = false
panelWidth3d = 2048
panelHeight3d = 2048

size = { 2048, 2048 }

newWindow = contextWindow { 
    name = ’Window’;
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