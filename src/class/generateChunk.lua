local chunksToGenerate, chunkSize, tileSize, seed = ...

-- Tonumbering the seed in case it comes in as a string
seed = tonumber(seed)

-- Importing some löve modules
love.math = require("love.math")
love.mouse = require("love.mouse")

-- Shorthands cause i'm lazy
local fs = love.filesystem
local noise = love.math.noise

local noiseScale = 0.6 -- Global noise scale

-- Loading biome files
local biomes = {}
for _, file in ipairs(fs.getDirectoryItems("src/biome")) do
    biomes[#biomes+1] = fs.load("src/biome/"..file)()
end

-- A fractal noise function for more interesting noise
local function fractalNoise(x, y, seed, scale, iterations, ampScale, freqScale)
    -- Normal function
    local function normal(value, min, max)
        return (value - min) / (max - min)
    end
    iterations = iterations or 5
    ampScale = ampScale or 0.6
    freqScale = freqScale or 2
    local totalAmp = 0
    local maxValue = 0
    local amp = 1
    local frequency = scale
    local value = 0

    for i=1, iterations do
        value = value + noise(x * frequency, y * frequency, seed ) * amp
        if value > maxValue then
            maxValue = value
        end
        totalAmp = totalAmp + amp
        amp = amp * ampScale
        frequency = frequency * freqScale 
    end

    value = value / totalAmp

    return normal(value, 0, 1)
end

-- Determines the biome, at x & y
local biomeCount = #biomes
local function biomeNoise(x, y, scale)
    local scaleBase = 0.01 * scale 
    local scaleDetail = 0.02 * scale
    local noise1 = noise(x * scaleBase, y * scaleBase, seed + 100)
    local noise2 = noise(x * scaleDetail, y * scaleDetail, seed + 200)
    local combined = (noise1 * 0.7 + noise2 * 0.3) 
    return math.floor(combined * biomeCount + 1)
end

local function blendBiomes(x, y, scale)
    local mainBiome = biomeNoise(x, y, scale)
    local blendFactor = fractalNoise(x, y, seed + 300, 0.05 * scale, 3, 0.5, 2)
    if blendFactor > 0.8 then
        local secondaryBiome = biomeNoise(x + 100, y + 100, scale) 
        if secondaryBiome ~= mainBiome then
            return secondaryBiome
        end
    end
    return mainBiome
end

-- A noise function that returs a boolean
local function generateNoise(x, y, scaleBase, scaleDetail, thresh, ratio1, ratio2, seedOffset)
    scaleBase = scaleBase * noiseScale
    scaleDetail = scaleDetail * noiseScale
    return noise(x * scaleBase, y * scaleBase, seed + seedOffset) * ratio1 + noise(x * scaleDetail, y * scaleDetail, seed + seedOffset) * ratio2 > thresh and true or false
end

-- Tile definitions. this is dumb
local wall = 1
local ground = 2
local coal = 3
local iron = 4
local gold = 6
local uranium = 7
local diamond = 8
local ruby = 9
local tanzenite = 10
local copper = 11
local idk = 12
local Crafting = 13
local Furnace = 14
local Grass = 16

-- Generating the requested chunks
-- Generating the requested chunks
if type(chunksToGenerate) == "table" then
    for i, v in ipairs(chunksToGenerate) do
        local finalChunk = {
            x = v.x,
            y = v.y,
            tiles = {}
        }
        -- the world coordinates of the chunk
        local chunkWorldX = v.x * chunkSize * tileSize
        local chunkWorldY = v.y * chunkSize * tileSize

        local chunk = {}

        for y = 1, chunkSize do
            chunk[y] = {}
            for x = 1, chunkSize do
                -- Grid coordinates for the tile
                local tileX = (v.x * chunkSize) + x
                local tileY = (v.y * chunkSize) + y
                
                -- World coordinates for the tile
                local worldX = chunkWorldX + (x * tileSize)
                local worldY = chunkWorldY + (y * tileSize)

                -- Determine the biome for this tile
                local biomeIndex = blendBiomes(tileX, tileY, noiseScale)

                -- Tile setup
                local tile = wall

                local tileBiome = biomes[biomeIndex]
                    
                local sway = -1 + (noise(tileY * 0.01, tileX * 0.01, seed) * 2)
                local swayAmount = 0.05
                local isCave = generateNoise(tileX, tileY, tileBiome.caveScaleBase, tileBiome.caveScaleDetail, tileBiome.caveThresh, tileBiome.caveRatio1, tileBiome.caveRatio2, 0)
                
                if isCave then
                    tile = tileBiome.groundTile or Grass

                    for i, ore in ipairs(tileBiome.ores) do
                        if generateNoise(tileX, tileY, ore.scaleBase, ore.scaleDetail, ore.thresh, ore.ratio1, ore.ratio2, ore.seedOffset) then
                            local probability = ore.spawnProbability + (love.math.random() * (1 - ore.spawnProbability))
                            if probability >= 1 - ore.spawnProbability then
                                tile = i + 2
                            end
                        end
                    end                
                else
                    tile = tileBiome.surfaceTile or wall 
                end

                if tileBiome.features then
                    for _, feature in ipairs(tileBiome.features) do
                        if generateNoise(tileX, tileY, feature.scaleBase, feature.scaleDetail, feature.thresh, feature.ratio1, feature.ratio2, feature.seedOffset) then
                            tile = feature.tileType
                        end
                    end
                end

                chunk[y][x] = {type = tile, x = worldX, y = worldY, biome = biomeIndex}
            end
        end

        for y = 1, #chunk do
            for x = 1, #chunk[1] do
                local tile = chunk[y][x]
                finalChunk.tiles[#finalChunk.tiles+1] = {x = tile.x, y = tile.y, type = tile.type, biome = tile.biome}
            end
        end

        love.thread.getChannel("worldGen"):push(finalChunk)
    end
end