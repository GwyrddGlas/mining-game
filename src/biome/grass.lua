return {
    name = "Grass",
    -- Shape
    caveScaleBase = 0,
    caveScaleDetail = 0.33,
    caveThresh = 0,
    caveRatio1 = 0,
    caveRatio2 = 0,

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
            -- Grass2          
            type = "Grass2",
            scaleBase = 1.2,  -- Slightly larger scale base for variation
            scaleDetail = 0.3,  -- More detailed scaling
            thresh = 0.4,  -- Different threshold for spawning
            ratio1 = 0.6,  -- Adjusted ratio
            ratio2 = 0.4,  -- Adjusted ratio
            spawnProbability = 0.9,  -- Lower spawn probability for variation
            seedOffset = 850  -- Different seed offset
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