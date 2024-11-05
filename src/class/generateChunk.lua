local chunksToGenerate, chunkSize, tileSize, seed = ...

seed = tonumber(seed)

love.math = require("love.math")
love.mouse = require("love.mouse")

local fs = love.filesystem
local noise = love.math.noise

local noiseScale = 1.2

local biomes = {}
for _, file in ipairs(fs.getDirectoryItems("src/biome")) do
    biomes[#biomes+1] = fs.load("src/biome/"..file)()
end

local function fractalNoise(x, y, seed, scale, iterations, ampScale, freqScale)
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

    for i = 1, iterations do
        value = value + noise(x * frequency, y * frequency, seed) * amp
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
    local scaleBase = 0.1 * scale
    local scaleDetail = 0.09 * scale
    return math.floor((noise(x * scaleBase, y * scaleBase, seed + 100) * 0.8 + noise(x * scaleDetail, y * scaleDetail, seed + 100) * 0.2) * biomeCount + 1)
end

local function generateCaveNoise(x, y, scaleBase, scaleDetail, thresh, ratio1, ratio2, seedOffset)
    scaleBase = scaleBase * noiseScale
    scaleDetail = scaleDetail * noiseScale
    local baseNoise = noise(x * scaleBase, y * scaleBase, seed + seedOffset) * ratio1
    local detailNoise = noise(x * scaleDetail, y * scaleDetail, seed + seedOffset) * ratio2
    return (baseNoise + detailNoise) < thresh and true or false
end

-- Tile definitions
local wall = 1
local ground = 2
local coal = 3
local iron = 4
local gold = 5
local uranium = 6
local diamond = 7
local ruby = 8
local tanzenite = 9

-- Generating the requested chunks
if type(chunksToGenerate) == "table" then
    for i, v in ipairs(chunksToGenerate) do
        local finalChunk = {
            x = v.x,
            y = v.y,
            tiles = {}
        }
        -- The world coordinates of the chunk
        local chunkWorldX = v.x * chunkSize * tileSize
        local chunkWorldY = v.y * chunkSize * tileSize

        local chunk = {}
        local biome = 1
        for y = 1, chunkSize do
            chunk[y] = {}
            for x = 1, chunkSize do
                -- Grid coordinates for the tile
                local tileX = (v.x * chunkSize) + x
                local tileY = (v.y * chunkSize) + y
                -- World coordinates for the tile
                local worldX = chunkWorldX + (x * tileSize)
                local worldY = chunkWorldY + (y * tileSize)

                -- Tile setup
                local tile = wall

                -- Determine biome and terrain
                local tileBiome = biomes[biome]
                local sway = -1 + (noise(tileY * 0.01, tileX * 0.01, seed) * 2)
                local swayAmount = 0.05

                -- Use cave noise for generating organic voids
                if generateCaveNoise(tileX, tileY, tileBiome.caveScaleBase, tileBiome.caveScaleDetail, tileBiome.caveThresh + (swayAmount * sway), tileBiome.caveRatio1, tileBiome.caveRatio2, 0) then
                    tile = ground

                    -- Ores generation within the caves
                    for i, ore in ipairs(tileBiome.ores) do
                        if generateCaveNoise(tileX, tileY, ore.scaleBase, ore.scaleDetail, ore.thresh + 0.1, ore.ratio1, ore.ratio2, ore.seedOffset) then
                            local probability = ore.spawnProbability * 0.5 + (love.math.random() * (1 - (ore.spawnProbability * 0.5)))
                            if probability >= 1 - ore.spawnProbability then
                                tile = i + 2
                            end
                        end
                    end
                end

                chunk[y][x] = {type = tile, x = worldX, y = worldY, biome = biome}
            end
        end

        -- Flatten chunk for easier access
        for y = 1, #chunk do
            for x = 1, #chunk[1] do
                local tile = chunk[y][x]
                finalChunk.tiles[#finalChunk.tiles + 1] = {x = tile.x, y = tile.y, type = tile.type, biome = tile.biome}
            end
        end

        love.thread.getChannel("worldGen"):push(finalChunk)
    end
end