return {
    name = "Grass",
    tile = 16,
    
    -- Shape
    caveScaleBase = 0.03,
    caveScaleDetail = 0.23,
    caveThresh = 0.63,  
    caveRatio1 = 0.56,
    caveRatio2 = 0.3,

    ores = {
        {
            -- Grass          
            type = "Grass",
            scaleBase = 1,  
            scaleDetail = 0.2,  
            thresh = 0.3,  
            ratio1 = 0.7,
            ratio2 = 0.3,
            spawnProbability = 1, 
            seedOffset = 800
        },
       
        {
            -- Shrub        11
            type = "Shrub",
            scaleBase = 0.5,
            scaleDetail = 0.2,
            thresh = 0.55,
            ratio1 = 0.2,
            ratio2 = 0.6,
            spawnProbability = 1,
            seedOffset = 700
        },
    }
}