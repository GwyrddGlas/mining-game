-- TILE ENTITY
local tileData = require("src.class.tileData")
--local worldGen = require("src.class.worldGen")

local entity = {}

function entity:load(data, ecs)
    self.bumpWorld = ecs.bumpWorld
    self.entityType = "tile"
    self.visible = true
    self.width = worldGen.tileSize
    self.height = worldGen.tileSize
    self.x = data.x--floor(data.x / self.width) * self.width
    self.y = data.y--floor(data.y / self.height) * self.height
    self.gridX = math.floor(self.x / floor(config.graphics.tileSize * scale_x))
    self.gridY = math.floor(self.y / floor(config.graphics.tileSize * scale_x))
    self.hover = false

    self:setType(data.type)

    self.color = {1, 1, 1}
end

function entity:setType(type)
    -- House cleaning before changing type
    if tileData[type] then 
       if not tileData[type].solid then
            if self.bumpWorld:hasItem(self) then
                self.bumpWorld:remove(self)
            end
        end
    else
        return 
    end

    -- Changing type
    self.type = type
    self.tileData = tileData[self.type]
    self.maxHP = self.tileData.maxHP
    self.hp = self.maxHP
    self.mined = false
    self.placed = false
    
    -- Creating bump item if solid
    if self.tileData.solid and not  self.bumpWorld:hasItem(self) then
        self.bumpWorld:add(self, self.x, self.y, self.width, self.height) 
    end
end

function entity:mine()
    if self.tileData.destructible then
        self.hp = self.hp - 1
        if self.hp < 0 then
            if _PLAYER.stamina > 0 then
                _PLAYER.stamina = _PLAYER.stamina - 1
            end

            local nextType = 2
            -- Drops
            local dropCount = random(self.tileData.drop[1], self.tileData.drop[2])
            if dropCount > 0 then
                local dropType = self.tileData.type
                if self.item then
                    dropType = self.tileData.item
                end
                if not _PLAYER.inventory[dropType] then
                    _PLAYER.inventory[dropType] = 0
                    _PLAYER.inventoryOrder[#_PLAYER.inventoryOrder + 1] = dropType 
                end
                _PLAYER.inventory[dropType] = _PLAYER.inventory[dropType] + dropCount
                floatText:new("+"..dropCount, self.x, self.y, font.regular, color[ self.tileData.type:lower() ])
            end

            -- If the mined tile is a wall, Maybe replace it with a gem
            if self.tileData.type == "Wall" then
                if random() < 0.05 then
                    nextType = wRand({80, 10, 10}) + 6
                end
            end

            --TODO: replace with better system
            --replace grass with dirt
            if self.tileData.type == "Grass" then
                nextType = 17
            end
        
            if self.tileData.type == "Dirt" then
                nextType = 2
            end

            self:setType(nextType)
            self.chunk.modified = true
        end
    end    
end

local function convertIconToDefinition(iconValue)
    local iconDefinitions = {
        [18] = 1,   -- Wall
        [1] = 2,    -- Coal
        [9] = 4,   -- Shrub
        [7] = 5,   -- Tanzenite
        [3] = 6,    -- Gold
        [4] = 7,    -- Uranium
        [5] = 8,    -- Diamond
        [6] = 9,    -- Ruby
        [10] = 10,    -- idk
        [2] = 4,    -- Iron
        [8] = 11,   -- Copper
        [28] = 13,  -- Crafting
        [29] = 14,  -- Furnace
        [44] = 15,  -- StoneBrick
        [45] = 16,   -- Grass
        [46] = 17,   -- Mushroom
        [33] = 15,  -- Torch
    }
    
    return iconDefinitions[iconValue] or 12
end

function entity:place(id)
    local newTileType = convertIconToDefinition(id)
    if self.tileData.placeable and tileData[newTileType] and tileData[newTileType].placeable then
        self:setType(newTileType)
        self.chunk.modified = true
    end
end

local minSolidVisible = 0.3
local torchID = "Torch"

function entity:draw()
    if _PLAYER and _PLAYER.control then
        -- Checking if tile is visible to player 
        local los =  bresenham.los(self.gridX, self.gridY, _PLAYER.gridX, _PLAYER.gridY, function(x, y)
            if worldGen.tiles[y] then
                if worldGen.tiles[y][x] then
                    if not worldGen.tiles[y][x].tileData then
                        print("Warning: tileData is nil for tile at position: " .. x .. ", " .. y)
                        return true
                    elseif not worldGen.tiles[y][x].tileData.solid then
                        return true
                    end
               end
            end
        end)

        -- Check if the torch is selected
        local isTorchSelected = _INVENTORY.highlightedItem == torchID
        
        -- Calculating lighting
        local shade = 0
        if config.graphics.useLight then
            local distanceFromPlayer = fmath.distance(self.x, self.y, _PLAYER.x, _PLAYER.y)
            local maxDistance = config.graphics.lightDistance * scale_x

            shade = 1 - (3 / maxDistance) * distanceFromPlayer
            if shade < config.graphics.ambientLight then
                shade = config.graphics.ambientLight
            end
            if not los then
                shade = config.graphics.ambientLight * 0.2
            end

            -- Ensure solid blocks are always somewhat visible
            if self.tileData.solid then
                shade = math.max(shade, minSolidVisible)
            end

                  -- Apply additional light if the torch is selected
            if isTorchSelected then
                local torchLightRadius = 100 -- Adjust based on your game's light distance
                local torchShade = 1 - (2 / torchLightRadius) * distanceFromPlayer
                print("Torch: "..tostring(isTorchSelected))

                shade = math.max(shade, torchShade)
            end
        end
  
        -- Drawing tile
        lg.setColor(self.color)

        if self.tileData then
            if self.tileData.textureID then
                lg.draw(tileAtlas, tiles[self.tileData.textureID], self.x, self.y, 0, self.width / config.graphics.assetSize, self.height / config.graphics.assetSize)
            end

            -- Drawing tile item
            if self.tileData.item then
                lg.draw(tileAtlas, tiles[self.tileData.itemTextureID], self.x, self.y, 0, self.width / config.graphics.assetSize, self.height / config.graphics.assetSize)
            end
        end

        -- Drawing light
        lg.setBlendMode("multiply", "premultiplied")
        local r, g, b = config.graphics.lightColor[1], config.graphics.lightColor[2], config.graphics.lightColor[3]
        lg.setColor(r * shade, g * shade, b * shade, 1)
        lg.rectangle("fill", self.x, self.y, self.width, self.height)
        lg.setBlendMode("alpha")

        -- Drawing hover indicator
        if self.hover then
            lg.setBlendMode("add")
            lg.setColor(1, 1, 1, 1)
            lg.rectangle("line", self.x + 1, self.y + 1, self.width - 2, self.height - 2)
            lg.setColor(1, 1, 1, 0.1)
            lg.rectangle("fill", self.x + 1, self.y + 1, self.width - 2, self.height - 2)
            lg.setBlendMode("alpha")
        end

        -- Drawing breaking indicator
        if self.hp then
            if self.hp < self.maxHP then
                local frame = #tileBreak - math.floor((#tileBreak / self.maxHP) * self.hp)
                lg.setColor(1, 1, 1, 0.8)
                lg.draw(tileBreakImg, tileBreak[frame], self.x, self.y, 0, self.width / config.graphics.assetSize, self.height / config.graphics.assetSize)
            end
        end
    end
end

return entity