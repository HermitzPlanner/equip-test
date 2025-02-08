function renderCanvas(obj, canvas) {
    const getTextContent = (selector) => obj.querySelector(selector)?.textContent?.trim() || notFoundMessage;

    const indexHex = getTextContent("Index")  // Index of the sprite you want to render
    const file = getTextContent("File")

    const spriteSize = 8;  // Size of each sprite in the spritesheet
    const sheetColumns = 16;  // Number of sprites per row in the spritesheet
    
    const spriteIndex = parseInt(indexHex, 16);  // Convert hex index to decimal
    const spriteX = (spriteIndex % sheetColumns) * spriteSize;
    const spriteY = Math.floor(spriteIndex / sheetColumns) * spriteSize;

    const scaleFactor = 6;  // Scale-up factor
    const outlineThickness = 1;  // Thickness of outline in pixels

    // Set canvas size for sprite + outline
    canvas.width = spriteSize * scaleFactor + outlineThickness * 2 * scaleFactor;
    canvas.height = spriteSize * scaleFactor + outlineThickness * 2 * scaleFactor;
    const context = canvas.getContext('2d');
    context.imageSmoothingEnabled = false;

    const spriteSheet = new Image();
    spriteSheet.src = normalizeFile(file);  // Replace with the path to your spritesheet

    spriteSheet.onload = () => {
        const offCanvas = document.createElement('canvas');
        offCanvas.width = spriteSize;
        offCanvas.height = spriteSize;
        const offContext = offCanvas.getContext('2d');
        offContext.imageSmoothingEnabled = false;

        // Draw sprite on offscreen canvas
        offContext.drawImage(spriteSheet, spriteX, spriteY, spriteSize, spriteSize, 0, 0, spriteSize, spriteSize);

        // Get pixel data and make it black
        const imageData = offContext.getImageData(0, 0, spriteSize, spriteSize);
        const data = imageData.data;
        for (let i = 0; i < data.length; i += 4) {
            if (data[i + 3] > 0) {  // Only non-transparent pixels
                data[i] = 0; data[i + 1] = 0; data[i + 2] = 0; data[i + 3] = 255;
            }
        }
        offContext.putImageData(imageData, 0, 0);

        // Draw outline
        const centerOffset = outlineThickness * scaleFactor;
        const outlineOffset = 0.3;
        for (let dx = -outlineOffset; dx <= outlineOffset; dx += outlineOffset) {
            for (let dy = -outlineOffset; dy <= outlineOffset; dy += outlineOffset) {
                if (dx !== 0 || dy !== 0) {
                    context.drawImage(offCanvas, 0, 0, spriteSize, spriteSize,
                        centerOffset + dx * scaleFactor, centerOffset + dy * scaleFactor,
                        spriteSize * scaleFactor, spriteSize * scaleFactor);
                }
            }
        }

        // Draw original sprite centered
        context.drawImage(spriteSheet, spriteX, spriteY, spriteSize, spriteSize,
            centerOffset, centerOffset, spriteSize * scaleFactor, spriteSize * scaleFactor);
    };
}


function normalizeFile(string) {
    const fileMappings = {
        "halloween24": "assets/174_rotmg.assets.EmbeddedAssets_Halloween24Embed.png",
        "lofiObj7": "assets/204_rotmg.assets.EmbeddedAssets_LofiObj7Embed.png",
        "lofiObj6": "assets/203_rotmg.assets.EmbeddedAssets_LofiObj6Embed.png",
        "shmittySheet": "assets/48_rotmg.assets.EmbeddedAssets_ShmittySheetEmbed.png",
        "lofiObj3": "assets/113_rotmg.assets.EmbeddedAssets_LofiObj3Embed.png",
        "lofiObj5": "assets/220_rotmg.assets.EmbeddedAssets_LofiObj5Embed.png",
        "gPlusSheet": "assets/27_rotmg.assets.EmbeddedAssets_GPlusSheetEmbed.png",
        "customObjects64x64": "assets/211_rotmg.assets.EmbeddedAssets_CustomObjects64x64.png",
        "lostHallsObjects8x8": "assets/59_rotmg.assets.EmbeddedAssets_LostHallsObjects8x8.png",
        "lofiObj2": "assets/30_rotmg.assets.EmbeddedAssets_LofiObj2Embed.png"
    };

    return fileMappings[string] || "no file name";
}