local entity = {}

local lg = love.graphics
local floor = math.floor

function entity:load(data, ecs)
    self.bumpWorld = ecs.bumpWorld
    self.entityType = "slime"
    self.visible = false

    self.tileSize = floor(config.graphics.tileSize * scale_x)

    self.x = data.x * self.tileSize
    self.y = data.y * self.tileSize

    self.width = self.tileSize
    self.height = self.tileSize
    self.collisonBoxWidth = floor(config.graphics.tileSize * scale_x * 0.7)
    self.collisionBoxHeight = floor(config.graphics.tileSize * scale_x * 0.5)

    -- Chunk coordinates, Used to detect when player moves to a new chunk
    self.chunkX = 0
    self.chunkY = 0
    self.oChunkX = 0
    self.oChunkY = 0

    -- Attributes
    self.speed = 100 * scale_x
    self.health = 6
    self.color = {1, 1, 1, 1}

    -- Animation related stuff
    self.skinAnimations = {
        default = {
            right ="src/assets/mobs/slimeRight.png",
            left = "src/assets/mobs/slimeLeft.png",
            forward = "src/assets/mobs/slimeForward.png",
            backward = "src/assets/mobs/slimeBackward.png",
            skin = "src/assets/mobs/slimeBackward.png",
        },
    }

    self.animation = {
        right = anim.new(self.skinAnimations.default.right, config.graphics.assetSize, config.graphics.assetSize),
        left = anim.new(self.skinAnimations.default.left, config.graphics.assetSize, config.graphics.assetSize),
        forward = anim.new(self.skinAnimations.default.backward, config.graphics.assetSize, config.graphics.assetSize),
        backward = anim.new(self.skinAnimations.default.forward, config.graphics.assetSize, config.graphics.assetSize)
    }

    self.moving = false
    self.direction = "backward"

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
    self.gridX = floor(self.x / floor(config.graphics.tileSize * scale_x))
    self.gridY = floor(self.y / floor(config.graphics.tileSize * scale_x))
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

function entity:interact(tile)
    if tile.entityType == "tile" then
        tile:onInteract(tile)
    end
end

function entity:update(dt)
    
end

function entity:draw()
    lg.setColor(self.color)
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

return entity 