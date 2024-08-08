local inventory = require("src/class/inventory")
local crafting = require("src/class/crafting")

local lg = love.graphics
local fs = love.filesystem
local kb = love.keyboard
local lm = love.mouse
local lt = love.thread

local game = {}

local currentIndex = 1
currentTrack = gameAudio.background[currentIndex]

local function playNextTrack()
    currentIndex = currentIndex + 1
    if currentIndex > #gameAudio.background then
        currentIndex = 1
    end
    
    currentTrack = gameAudio.background[currentIndex]
    if currentTrack then
        currentTrack:play()
        currentTrack:setVolume(config.audio.music * config.audio.master)
    end
end

local function playBackgroundMusic()
    playNextTrack()
end

function game:load(data)
    config = ttf.load("config.lua")

    lg.setBackgroundColor(0, 0, 0)
    self:resize(love.graphics.getWidth(), love.graphics.getHeight())

    local playerX, playerY = 0, 0 -- Grid coordinates!
    local playerLoaded = false -- True if player loaded from save file
    local playerInventory = {}
   
    if data.type == "new" then
        self.worldName = data.worldName
        self.seed = data.seed
        note:new("Created world '"..self.worldName.."'", "success")
    elseif data.type == "load" then
        local worldData = fs.load("worlds/"..data.worldName.."/config.lua")()
        self.worldName = worldData.name
        self.seed = worldData.seed
        playerInventory = worldData.player.inventory
        playerX = worldData.player.x 
        playerY = worldData.player.y 
        playerLoaded = true

        note:new("Loaded world '"..self.worldName.."'", "success")
    end

    -- Initializing the ECS world
    self.world = ecs.new()
    self.world:loadSystemFromFolder("src/system")

    --Exposing self.world for debug purposes
    if config.debug.enabled then
        _WORLD = self.world
    end

    -- Initializing player
    self.player = self.world:newEntity("src/entity/player.lua", playerX, playerY, {x = playerX, y = playerY, inventory = playerInventory, playerLoaded = playerLoaded})
    self.inventory = inventory:new(self.player)
    self.crafting = crafting:new(self.player)

    -- Exposing for debug purposes
    _PLAYER = self.player
    _INVENTORY = self.inventory

    -- Initializing worldGen
    worldGen:load({player = self.player, world = self.world, worldName = self.worldName, seed = self.seed})
    
    self.renderBuffer = worldGen.tileSize * 2
    self.hoverEntity = false -- Contains the entity the mouse is over, Used for mining
    self.time = 0 -- Timer used for shader animations

    self.inventory.selectedIndex = 1
    self.inventory.highlightedItem = self.inventory.inventoryOrder[self.inventory.selectedIndex]

    -- Icon tile id's
    self.icon = {
        Coal = 1,
        Iron = 2,
        Gold = 3,
        Uranium = 4,
        Diamond = 5,
        Ruby = 6,
        Tanzenite = 7,
        Copper = 8,
        Shrub = 9, --stick
        Wall = 18,
        Crafting = 28,
        Furnace = 29,
        StoneBrick = 30,
        Grass = 31,
        Dirt = 32,
        Torch = 33,
        Chest = 34,
        health = 41,
        halfHeart = 42,
        radiation = 43,
        Mushroom = 51,
    }

    -- Poster stuff
    self.canvas = poster.new()
    self.shaders = poster.newChain(
    {"chromaticAberrationRadius", "brightness", "contrast", "saturation", "vignette", "waveDistortion", "horizontalBlur"}, 
    {
        {"chromaticAberrationRadius", "position", {lg.getWidth() / 2, lg.getHeight() / 2}},
        {"chromaticAberrationRadius", "offset", 0 * scale_x},
        {"waveDistortion", "intensity", 0},
        {"waveDistortion", "scale", config.graphics.tileSize * scale_x * 0.5},
        {"waveDistortion", "phase", 0},
        {"brightness", "amount", config.graphics.brightness},
        {"contrast", "amount", 1.2},
        {"saturation", "amount", 1.2},
        {"vignette", "radius", 1},
        {"vignette", "opacity", 1},
        {"vignette", "softness", 1},
        {"vignette", "color", {0, 0, 0}},
        {"horizontalBlur", "amount", 0},
    })

    self.shaders:addMacro("time", {
        {"waveDistortion", "phase", 1}
    })

    self.shaders:addMacro("rad", {
        {"chromaticAberrationRadius", "offset", 2},
        {"waveDistortion", "intensity", 0.0003},
    })

    self.bloom = poster.newChain(
        {"verticalBlur", "horizontalBlur"}, 
    {
        {"verticalBlur", "amount", 3},
        {"horizontalBlur", "amount", 3},
    })

    self.inventory.inventoryOpen = false

    playBackgroundMusic()
    gameAudio.menu[1]:stop()
end

function game:unload()
    ecs.unload()
    self.world = nil
end

function game:update(dt)
    -- Querying for visible entities
    self.visibleEntities = self.world:queryRect(camera.x - self.renderBuffer, camera.y - self.renderBuffer, lg.getWidth() + self.renderBuffer * 2, lg.getHeight() + self.renderBuffer * 2)

    -- Storing the entity the mouse is hovering over
    local mx, my = camera:getMouse()
    for i,v in ipairs(self.visibleEntities) do
        v.hover = false
        if fmath.pointInRect(mx, my, v.x, v.y, v.width, v.height) and fmath.distance(v.gridX, v.gridY, self.player.gridX, self.player.gridY) < self.player.reach and not self.inventory.inventoryOpen then
            v.hover = true
            self.hoverEntity = v
        end
    end
    
    -- Updating camera
    camera:lookAtEntity(self.player)
    camera:update(dt)
    
    -- Updating world
    worldGen:update(dt)

    -- Updating crafting grid
    crafting:update()

    -- Internal timer used for shaders
    self.time = self.time + dt
    if self.time > math.pi * 2 then self.time = 0 end
    
    -- Settings macros
    --self.shaders:setMacro("rad", self.player.radiation)
    --self.shaders:setMacro("time", self.time)

    -- Handle dying
    if self.player.health <= 0 then
        if self.player.spawnX and self.player.spawnY then
            self.player:teleport(self.player.spawnX, self.player.spawnY)
        end
        
        self.player.health = 10
        
        for item, _ in pairs(self.player.inventory) do
            self.player.inventory[item] = nil
        end
        self.player.inventoryOrder = {}
    end

    -- Handle music transitioning 
    if gameAudio.background[currentIndex] and not gameAudio.background[currentIndex]:isPlaying() then
        playNextTrack()
    end

    --Mining
    if lm.isDown(1) and self.hoverEntity and not self.inventory.inventoryOpen then
        if _PLAYER.stamina > 0 then
            self.player:mine(self.hoverEntity)
            _PLAYER.stamina = _PLAYER.stamina - dt * 2
        end
    end
end

function game:drawHud()
    local iconScale = 30 * scale_x
    local radiationScale = 34 * scale_x
    local width, height = lg.getWidth(), lg.getHeight()

    local hotbarX = width * 0.5
    local hotbarY = height - height * 0.07
    local hotbarWidth = width * 0.28 
    local hotbarHeight = height * 0.07
    local itemSize = hotbarHeight * 0.8
    local maxHotbarItems = 6
    local itemSpacing = (hotbarWidth - itemSize * maxHotbarItems) / (maxHotbarItems - 1)
    local cornerRadius = itemSize * 0.2

    local hotbarPadding = itemSize * 0.08 
    local adjustedHotbarWidth = hotbarWidth + hotbarPadding * 2

    local itemX = hotbarX - (adjustedHotbarWidth * 0.5) + hotbarPadding
    local itemY = hotbarY + (hotbarHeight - itemSize) * 0.5

    self.inventory:draw(self.icon, itemSize, self.crafting:getCraftingItemSpacing(), cornerRadius, maxHotbarItems)
    
    if self.inventory.inventoryOpen then
        self.crafting:draw(self.icon)
    else
        self.inventory:drawHotbar(self.icon)
    end
end

function game:draw()
    self.canvas:set()
    lg.clear()
    camera:push()
    self.world:update(self.visibleEntities)
    self.player:draw()
    floatText:draw()
    camera:pop()
    self.canvas:unset()

    lg.setColor(1, 1, 1, 1)
    if config.graphics.useShaders then
        self.canvas:draw(self.shaders)
        lg.setBlendMode("add")
        lg.setColor(1, 1, 1, config.graphics.bloom)
        self.canvas:draw(self.bloom, self.bloom)
        lg.setBlendMode("alpha")
    else
        self.canvas:draw()
    end
   
    self:drawHud()

    local all, all_len = self.world:query()
    if config.debug.enabled then
        lg.setColor(1, 0, 0)
        local bumpItems = self.world:getBumpWorld():countItems()
        lg.setFont(font.tiny)
        lg.printf("FPS: "..love.timer.getFPS()..
        "\nRam: " .. tostring(math.floor(collectgarbage("count")/1024)+100).." MB"..
        "\nVRam: " .. tostring(math.floor(love.graphics.getStats().texturememory/1024/1024)).." MB"..
        "\nLoaded chunks: "..worldGen.loadedChunkCount..
        "\nBump items: "..bumpItems, -12, 12, lg.getWidth(), "center")
        worldGen:draw()
    end

    -- DEBUG BUMP WORLD
    if config.debug.showCollision then
        camera:push()
        lg.setColor(0, 1, 1)
        local items, len = self.world:getBumpWorld():getItems()
        if len > 0 then
            for i,v in ipairs(items) do
                local x, y, w, h = self.world:getBumpWorld():getRect(v)
                lg.rectangle("line", x, y, w, h)
            end
        end
        camera:pop()
    end

    self:drawMinimap(all)
    self:drawHealthBar()
    self:drawStaminaBar()
end

function game:drawHealthBar()
    local minimapRadius = 125
    local minimapX = 30 + minimapRadius
    local minimapY = 30 + minimapRadius
    
    local barWidth = minimapRadius * 2
    local barHeight = 20
    local barX = minimapX - minimapRadius
    local barY = minimapY + minimapRadius + 80

    -- Draw background
    lg.setColor(0.2, 0.2, 0.2, 0.8)
    lg.rectangle("fill", barX, barY, barWidth, barHeight)

    -- Draw health
    local healthPercentage = self.player.health / 10
    lg.setColor(0.5, 0.1, 0.1, 1)
    lg.rectangle("fill", barX, barY, barWidth * healthPercentage, barHeight, 10, 10)

    -- Draw border
    lg.setColor(1, 1, 1, 1)
    lg.rectangle("line", barX, barY, barWidth, barHeight, 10, 10)
end

function game:drawStaminaBar()
    local minimapRadius = 120
    local minimapX = 30 + minimapRadius
    local minimapY = 30 + minimapRadius
    
    local barWidth = minimapRadius * 1.5
    local barHeight = 20
    local barX = minimapX - minimapRadius
    local barY = minimapY + minimapRadius + 115 
    local cornerRadius = 10

    -- Draw background
    lg.setColor(0.2, 0.2, 0.2, 0.8)
    lg.rectangle("fill", barX, barY, barWidth, barHeight, cornerRadius, cornerRadius)

    -- Calculate stamina width
    local staminaPercentage = self.player.stamina / 10 
    local staminaWidth = barWidth * staminaPercentage

    -- Create stencil for rounded stamina bar
    lg.stencil(function()
        lg.rectangle("fill", barX, barY, barWidth, barHeight, cornerRadius, cornerRadius)
    end, "replace", 1)

    lg.setStencilTest("greater", 0)

    local barHeight = 20 
    
    local gradient = lg.newMesh({
        {0, 0, 0, 0, 0, 0.3, 0.2, 1},
        {staminaWidth, 0, 1, 0, 0, 0.3, 0.2, 1},
        {staminaWidth, barHeight, 1, 1, 0, 0.5, 0.4, 1},
        {0, barHeight, 0, 1, 0, 0.5, 0.4, 1}
    }, "fan")
    
    lg.setColor(1, 1, 1, 1) 
    lg.draw(gradient, barX, barY)
    lg.setStencilTest() 

    -- Draw border
    lg.setColor(1, 1, 1, 1)
    lg.rectangle("line", barX, barY, barWidth, barHeight, cornerRadius, cornerRadius)
end

function game:drawMinimap(all)
    local minimapRadius = 125
    local minimapX = 30 + minimapRadius
    local minimapY = 30 + minimapRadius
    local minimapScale = 8

    -- Draw circular background
    lg.setColor(0.1, 0.1, 0.1, 0.8)
    lg.circle("fill", minimapX, minimapY, minimapRadius)
    
    -- Draw blue-ish border
    lg.setColor(0.2, 0.2, 0.25)
    lg.setLineWidth(3)
    lg.circle("line", minimapX, minimapY, minimapRadius)
    
    lg.setColor(0.15, 0.15, 0.2)  -- Adjust this color to fit well with the existing blue-ish color
    lg.setLineWidth(5)  -- Slightly thicker line for the outline
    lg.circle("line", minimapX, minimapY, minimapRadius + 2) 

    -- Draw compass points
    local compassColor = {1,1,1}
    local compassOffset = minimapRadius + 20
    lg.setColor(compassColor)
    lg.setFont(font.regular)
    lg.print("N", minimapX - 5, minimapY - compassOffset - 15)
    lg.print("S", minimapX - 5, minimapY + compassOffset - 15)
    lg.print("W", minimapX - compassOffset - 7, minimapY - 7)
    lg.print("E", minimapX + compassOffset - 7, minimapY - 7)
    
    -- Draw minimap coordinates
    lg.setColor(1, 1, 1, 1)
    lg.setFont(font.tiny)
    local xText = string.format("x: %i", self.player.gridX)
    local xTextWidth = lg.getFont():getWidth(xText)
    local xTextX = minimapX - minimapRadius
    local xTextY = minimapY + minimapRadius + 15 
    lg.print(xText, xTextX, xTextY)
    
    -- Draw y-coordinate
    local yText = string.format("y: %i", self.player.gridY)
    local yTextWidth = lg.getFont():getWidth(yText)
    local yTextX = minimapX + minimapRadius - yTextWidth
    local yTextY = minimapY + minimapRadius + 15
    lg.print(yText, yTextX, yTextY)    
    
    -- Set circular stencil
    lg.stencil(function()
        lg.circle("fill", minimapX, minimapY, minimapRadius - 2)
    end, "replace", 1)
    lg.setStencilTest("greater", 0)
    
    local miniMapColors = {
        {0.2, 0.2, 0.2, 1},    -- 0: Black (Wall)
        {0.65, 0.65, 0.7, 1},    -- 1: Light Gray (Stone)
        {0.7, 0.5, 0.3, 1},    -- 2: Brown (Shrub)
        {0.1, 0.1, 0.1, 1},    -- 3: Brown (Coal)
        {0.7529, 0.7529, 0.7529, 1},    -- 4: Silver (Tanzenite)
        {1.0, 1.8, 0.2, 1},    -- 5: Yellow (Gold)
        {0, 0.2, 0.8, 1},    -- 6: Green (Uranium)
        {1, 0.2, 0, 1},    -- 8: Purple (Unknown)
        {0.8, 0.2, 0.2, 1},    -- 7: Red (Ruby)
        {0.2, 0, 0.8, 1},    -- 9: Cyan (Diamond)
        {1.0, 0.5, 0.2, 1},    -- 10: Orange (Copper)
        {0.8, 0.8, 0.2, 1},    -- 11: Yellow-Green (Uranium)
        {1, 1, 1, 1},    -- 12: 
        {1, 1, 1, 1},    -- 13: 
        {1, 1, 1, 1},    -- 14: 
        {102/255, 123/255, 13/255, 1},    -- 15: Grass (Green)
    }
    
    local playerColor = {0, 1, 0, 1}
    local playerSize = minimapScale
    
    for i, v in ipairs(all) do
        if v.entityType == "tile" then
            local tileType = tonumber(v.type)
            if tileType and miniMapColors[tileType] then
                local color = miniMapColors[tileType]
                lg.setColor(color[1], color[2], color[3], color[4])
                lg.rectangle(
                    "fill",
                    minimapX + (v.gridX - self.player.gridX) * minimapScale,
                    minimapY + (v.gridY - self.player.gridY) * minimapScale,
                    minimapScale,
                    minimapScale
                )
            end
        elseif v.entityType == "player" then
            lg.setColor(playerColor[1], playerColor[2], playerColor[3], playerColor[4])
            lg.rectangle(
                "fill",
                minimapX - playerSize / 2,
                minimapY - playerSize / 2,
                playerSize,
                playerSize
            )
        end
    end
    
    -- Reset stencil test
    lg.setStencilTest()
    
    local function atan2(y, x)
        if x > 0 then
            return math.atan(y/x)
        elseif x < 0 and y >= 0 then
            return math.atan(y/x) + math.pi
        elseif x < 0 and y < 0 then
            return math.atan(y/x) - math.pi
        elseif x == 0 and y > 0 then
            return math.pi/2
        elseif x == 0 and y < 0 then
            return -math.pi/2
        else -- x == 0 and y == 0
            return 0
        end
    end

    -- Draw player direction indicator
    local directionLength = 15
    local mx, my = camera:getMouse()
    local playerAngle = atan2(my - self.player.y, mx - self.player.x)
    lg.setColor(1, 1, 1, 0.8)
    lg.setLineWidth(2)
    lg.line(
        minimapX,
        minimapY,
        minimapX + math.cos(playerAngle) * directionLength,
        minimapY + math.sin(playerAngle) * directionLength
    )
    
    lg.setLineWidth(1)
end

function game:keypressed(key)
    if key == "f5" then
        worldGen:saveWorld()
    end

    -- Inventory
    self.inventory:keypressed(key)

    --Crafting
    self.crafting:keypressed(key)

    -- Hotbar selection
    if tonumber(key) and tonumber(key) >= 1 and tonumber(key) <= 6 then
        self.inventory.selectedIndex = tonumber(key)
        self.inventory.highlightedItem = self.inventory.inventoryOrder[self.inventory.selectedIndex]
    end
end

function game:wheelmoved(x, y)
    self.inventory.selectedIndex = self.inventory.selectedIndex + y
    if self.inventory.selectedIndex < 1 then
        self.inventory.selectedIndex = 6
    elseif self.inventory.selectedIndex > 6 then
        self.inventory.selectedIndex = 1
    end
    self.inventory.highlightedItem = self.inventory.inventoryOrder[self.inventory.selectedIndex]
end

function game:resize(w, h)

end

function game:mousepressed(x, y, button)
    if self.inventory.inventoryOpen then
        self.inventory:mousepressed(x, y, button)
        self.crafting:mousepressed(x, y, button)
    end

    --Placing/Interacting
    if button == 2 and self.hoverEntity and not self.inventory.inventoryOpen then
        if _PLAYER.stamina > 0.5 then
            local itemId = self.icon[self.inventory.highlightedItem]
            self.player:place(self.hoverEntity, itemId)
            _PLAYER.stamina = _PLAYER.stamina - 0.5
        end
    end
end

return game