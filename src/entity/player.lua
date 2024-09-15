local entity = {}

local lg = love.graphics
local fs = love.filesystem
local kb = love.keyboard
local lm = love.mouse
local lt = love.thread
local random = math.random
local noise = love.math.noise
local sin = math.sin
local cos = math.cos
local f = string.format
local floor = math.floor
local joy = love.joystick

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
    self.stamina = 10
    self.magic = 2
    self.magicCap = 10
    self.inventory = data.inventory or {}
    self.craftingGrid = data.craftingGrid or {}
    self.craftingResult = data.craftingResult
    self.inventoryOrder = {}
    self.playerLoaded = data.playerLoaded
    self.selectedSkin = "default"
    
    self.color = {1, 1, 1}

    -- Animation related stuff
    self.skinAnimations = {
        default = {
            right = "src/assets/player/left.png",
            left = "src/assets/player/right.png",
            forward = "src/assets/player/forward.png",
            backward = "src/assets/player/backward.png",
            skin = "src/assets/player/skin.png",
        },
        skin1 = {
            right = "src/assets/player/leftBlue.png",
            left = "src/assets/player/rightBlue.png",
            forward = "src/assets/player/forwardBlue.png",
            backward = "src/assets/player/backwardBlue.png",
            skin = "src/assets/player/skinBlue.png",
        },
    }

    self.animation = {
        right = anim.new(self.skinAnimations[self.selectedSkin].right, config.graphics.assetSize, config.graphics.assetSize),
        left = anim.new(self.skinAnimations[self.selectedSkin].left, config.graphics.assetSize, config.graphics.assetSize),
        forward = anim.new(self.skinAnimations[self.selectedSkin].backward, config.graphics.assetSize, config.graphics.assetSize),
        backward = anim.new(self.skinAnimations[self.selectedSkin].forward, config.graphics.assetSize, config.graphics.assetSize)
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

function entity:interact(tile)
    if tile.entityType == "tile" then
        tile:onInteract(tile)
    end
end

function entity:place(tile, id)
    if tile.entityType ~= "tile" then
        return
    end

    local inventory = _PLAYER.inventory
    local inventoryOrder = _PLAYER.inventoryOrder
    local selectedItem = _INVENTORY.highlightedItem
    local itemQuantity = inventory[selectedItem]

    if type(itemQuantity) == "number" and itemQuantity > 0 then
        local originalType = tile.type

        tile:place(id)

        if tile.type ~= originalType then
            inventory[selectedItem] = itemQuantity - 1
            
            if inventory[selectedItem] <= 0 then
                inventory[selectedItem] = nil
                for i, item in ipairs(inventoryOrder) do
                    if item == selectedItem then
                        table.remove(inventoryOrder, i)
                        break
                    end
                end
            end
        end
    end
end

local function isJoystickButtonDown(button)
    local joysticks = joy.getJoysticks()
    for _, joystick in ipairs(joysticks) do
        if joystick:isDown(button) then
            return true
        end
    end
    return false
end

local function getJoystickAxis(axis)
    local joysticks = joy.getJoysticks()
    for _, joystick in ipairs(joysticks) do
        local value = joystick:getAxis(axis)
        if math.abs(value) > 0.2 then  -- Dead zone
            return value
        end
    end
    return 0
end

function entity:draw()
    if self.control then
        -- Facing the player
        local mx, my = camera:getMouse()
        local rightStickX = getJoystickAxis(3)
        local rightStickY = getJoystickAxis(4)
    
        local angle
    
        if math.abs(rightStickX) > 0.2 or math.abs(rightStickY) > 0.2 then
            angle = math.deg(math.atan2(-rightStickY, rightStickX))
        else
            angle = math.deg(fmath.angle(self.x, self.y, mx, my))
        end

        if angle > -45 and angle < 45 then
            self.direction = "right"
        elseif angle > 45 and angle < 135 then
            self.direction = "backward"
        elseif angle < -45 and angle > -135 then
            self.direction = "forward"
        else
            self.direction = "left"
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