local chunksToGenerate, chunkSize, tileSize, seed = ...

seed = tonumber(seed)

love.math = require("love.math")
love.mouse = require("love.mouse")

local fs = love.filesystem
local noise = love.math.noise

local noiseScale = 1.2

-- Load biomes
local biomes = {}
for _, file in ipairs(fs.getDirectoryItems("src/biome")) do
    biomes[#biomes+1] = fs.load("src/biome/"..file)()
end

-- Fractal noise for terrain elevation
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

-- Determines the biome at (x, y)
local biomeCount = #biomes
local function biomeNoise(x, y, scale)
    local scaleBase = 0.1 * scale
    local scaleDetail = 0.09 * scale
    return math.floor((noise(x * scaleBase, y * scaleBase, seed + 100) * 0.8 + noise(x * scaleDetail, y * scaleDetail, seed + 100) * 0.2) * biomeCount + 1)
end

-- Tile definitions
local grass = 1
local sand = 2
local water = 3
local stone = 4
local tree = 5
local rock = 6

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
        for y = 1, chunkSize do
            chunk[y] = {}
            for x = 1, chunkSize do
                -- Grid coordinates for the tile
                local tileX = (v.x * chunkSize) + x
                local tileY = (v.y * chunkSize) + y
                -- World coordinates for the tile
                local worldX = chunkWorldX + (x * tileSize)
                local worldY = chunkWorldY + (y * tileSize)

                -- Determine biome
                local biomeIndex = biomeNoise(tileX, tileY, noiseScale)
                local biome = biomes[biomeIndex]

                -- Determine elevation
                local elevation = fractalNoise(tileX, tileY, seed, biome.elevationScale, 5, 0.6, 2)

                -- Determine tile type based on elevation and biome
                local tile = grass
                if elevation < biome.waterLevel then
                    tile = water
                elseif elevation < biome.sandLevel then
                    tile = sand
                elseif elevation < biome.stoneLevel then
                    tile = stone
                end

                -- Add surface features (trees, rocks)
                if tile == grass or tile == sand then
                    local featureNoise = noise(tileX * biome.featureScale, tileY * biome.featureScale, seed + 200)
                    if featureNoise > biome.treeThreshold then
                        tile = tree
                    elseif featureNoise > biome.rockThreshold then
                        tile = rock
                    end
                end

                chunk[y][x] = {type = tile, x = worldX, y = worldY, biome = biomeIndex}
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