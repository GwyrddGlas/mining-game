local chunksToGenerate, chunkSize, tileSize, seed = ...

seed = tonumber(seed)

love.math = require("love.math")
love.mouse = require("love.mouse")

local fs = love.filesystem
local noise = love.math.perlinNoise

local noiseScale = 1.2

-- Tile definitions
local wall = 20
local ground = 23
local coal = 5
local iron = 6
local gold = 7
local uranium = 8
local diamond = 9
local ruby = 10
local tanzenite = 11

-- Global cave generation parameters
local caveScaleBase = 0.05
local caveScaleDetail = 0.1
local caveThresh = 0.5
local caveRatio1 = 0.7
local caveRatio2 = 0.3

-- Global ore generation parameters
local ores = {
    {scaleBase = 0.1, thresh = 0.6, spawnProbability = 0.02, type = coal},
    {scaleBase = 0.1, thresh = 0.65, spawnProbability = 0.015, type = iron},
    {scaleBase = 0.1, thresh = 0.7, spawnProbability = 0.01, type = gold},
    {scaleBase = 0.1, thresh = 0.75, spawnProbability = 0.005, type = uranium},
    {scaleBase = 0.1, thresh = 0.8, spawnProbability = 0.002, type = diamond},
    {scaleBase = 0.1, thresh = 0.85, spawnProbability = 0.001, type = ruby},
    {scaleBase = 0.1, thresh = 0.9, spawnProbability = 0.0005, type = tanzenite},
}

local function generateCaveNoise(x, y, seedOffset)
    local baseNoise = noise(x * caveScaleBase, y * caveScaleBase, seed + seedOffset) * caveRatio1
    local detailNoise = noise(x * caveScaleDetail, y * caveScaleDetail, seed + seedOffset) * caveRatio2
    return (baseNoise + detailNoise) < caveThresh
end

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

                -- Tile setup
                local tile = wall

                if generateCaveNoise(tileX, tileY, 0) then
                    tile = ground

                    -- Ore generation
                    for _, ore in ipairs(ores) do
                        local oreNoiseValue = noise(tileX * ore.scaleBase, tileY * ore.scaleBase, seed + ore.type)
                        if oreNoiseValue > ore.thresh and love.math.random() < ore.spawnProbability then
                            tile = ore.type
                            break
                        end
                    end
                end

                chunk[y][x] = {type = tile, x = worldX, y = worldY}
            end
        end

        -- Flatten chunk for easier access
        for y = 1, #chunk do
            for x = 1, #chunk[1] do
                local tile = chunk[y][x]
                finalChunk.tiles[#finalChunk.tiles + 1] = {x = tile.x, y = tile.y, type = tile.type}
            end
        end

        love.thread.getChannel("worldGen"):push(finalChunk)
    end
end