return {
    name = "Grass",
    tile = 2,
    -- Shape
    caveScaleBase = 0,
    caveScaleDetail = 0,
    caveThresh = 0,
    caveRatio1 = 0,
    caveRatio2 = 0,
    elevationScale = 0.8,
    waterLevel = 0.3,
    sandLevel = 0.3,
    stoneLevel = 0.1,
    featureScale = 0.2,
    treeThreshold = 0.8,
    rockThreshold = 0,

    ores = {
        {
            -- Shrub
            type = "Shrub",
            scaleBase = 0.5,
            scaleDetail = 0.2,
            thresh = 0.55,
            ratio1 = 0.2,
            ratio2 = 0.6,
            spawnProbability = 1,
            seedOffset = 700
        },
        {
            -- Mushroom
            type = "Mushroom",
            scaleBase = 0.5,
            scaleDetail = 0.2,
            thresh = 0.55,
            ratio1 = 0.2,
            ratio2 = 0.6,
            spawnProbability = 1,
            seedOffset = 700
        }
    }
}