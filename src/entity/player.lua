local entity = {}

function entity:load(data, ecs)
    self.bumpWorld = ecs.bumpWorld
    self.entityType = "player"
    self.visible = false

    self.tileSize = math.floor(config.graphics.tileSize * scale_x)

    self.x = data.x * self.tileSize
    self.y = data.y * self.tileSize

    self.width = self.tileSize
    self.height = self.tileSize
    self.collisonBoxWidth = math.floor(config.graphics.tileSize * scale_x * 0.7)
    self.collisionBoxHeight = math.floor(config.graphics.tileSize * scale_x * 0.5)

    -- Chunk coordinates, Used to detect when player moves to a new chunk
    self.chunkX = 0
    self.chunkY = 0
    self.oChunkX = 0
    self.oChunkY = 0

    -- Player attributes
    self.speed = 100 * scale_x
    self.control = false
    self.reach = 6
    self.mineSpeed = 10
    self.mineTick = 0
    self.health = 10
    self.radiation = 0
    self.inventory = data.inventory
    self.crafting = data.crafting
    self.inventoryOrder = {}
    self.playerLoaded = data.playerLoaded
    self.inRangeOfRadiation = false

    self.color = {1, 1, 1}

    -- Animation related stuff
    self.animation = {
        right = anim.new("src/assets/player/left.png", config.graphics.assetSize, config.graphics.assetSize),
        left = anim.new("src/assets/player/right.png", config.graphics.assetSize, config.graphics.assetSize),
        forward = anim.new("src/assets/player/backward.png", config.graphics.assetSize, config.graphics.assetSize),
        backward = anim.new("src/assets/player/forward.png", config.graphics.assetSize, config.graphics.assetSize),
    }
    self.moving = false
    self.direction = "right"

    -- Creating bump item
    self.bumpWorld:add(self, self.x, self.y, self.collisonBoxWidth, self.collisionBoxHeight)

    -- Updating coordinates
    self:updateChunkCoordinates()
    self:updateGridCoordinates()
end

function entity:updateChunkCoordinates()
    self.oChunkX = self.chunkX
    self.oChunkY = self.chunkY
    self.chunkX = floor(self.x / (config.settings.chunkSize * self.tileSize))
    self.chunkY = floor(self.y / (config.settings.chunkSize * self.tileSize))
end

function entity:updateGridCoordinates()
    self.gridX = math.floor(self.x / floor(config.graphics.tileSize * scale_x))
    self.gridY = math.floor(self.y / floor(config.graphics.tileSize * scale_x))
end

function entity:teleport(x, y)
    self.x = x
    self.y = y
    self.bumpWorld:update(self, self.x, self.y)

    camera:lookAtEntity(self, true)
    self:updateChunkCoordinates()
    self:updateGridCoordinates()
    worldGen:updateChunks()
    self._SPATIAL.spatial:update_item_cell(self.x, self.y, self)
end

function entity:mine(tile)
    if tile.entityType == "tile" then
        self.mineTick = self.mineTick + love.timer.getDelta()
        if self.mineTick > (1 / self.mineSpeed) then
            tile:mine() 
            self.mineTick = 0
        end 
    end
end

function entity:place(tile, id)
    tile:place(id)
end

function entity:draw()
    if self.control then
        -- Facing the player
        -- I'm sure theres a better way to do this but fuck it
        local mx, my = camera:getMouse()
        local angle = math.deg(fmath.angle(self.x, self.y, mx, my))

        if angle > -45 and angle < 45 then
            self.direction = "right"
        elseif angle > 45 and angle < 135 then
            self.direction = "backward"
        elseif angle < -45 and angle > -135 then
            self.direction = "forward"
        else
            self.direction = "left"
        end
        
        -- Radiation
        if not self.inRangeOfRadiation then
            self.radiation = self.radiation - 0.1 * love.timer.getDelta()
            if self.radiation < 0 then self.radiation = 0 end
        end

        if self.radiation > 5 then
            if math.random() < 0.1 and self.health > 0 then
                local healthLoss = self.radiation * 0.01
                self.health = math.max(0, self.health - healthLoss)
            end
        end

        lg.setColor(self.color)
        --lg.rectangle("fill", self.x, self.y, config.graphics.tileSize * scale_x, config.graphics.tileSize * scale_x)
        if self.moving then
            self.animation[self.direction]:start()
            self.animation[self.direction]:update(love.timer.getDelta())
        else
            self.animation[self.direction]:reset()
            self.animation[self.direction]:stop()
        end
        
        local x = self.x - (self.tileSize / 2)
        local y = self.y - (self.tileSize / 2)
        self.animation[self.direction]:draw(x, y, self.tileSize / config.graphics.assetSize, self.tileSize / config.graphics.assetSize)
    end
end

return entity 