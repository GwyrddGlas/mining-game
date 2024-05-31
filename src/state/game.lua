local inventory = require("src/class/inventory")
local crafting = require("src/class/crafting")

local game = {}

local currentIndex = 1
local currentTrack = gameAudio.background[currentIndex]

local function playNextTrack()
    currentIndex = currentIndex + 1
    if currentIndex > #gameAudio.background then
        currentIndex = 1
    end
    
    currentTrack = gameAudio.background[currentIndex]
    if currentTrack then
        currentTrack:setVolume(0.2)
        currentTrack:play()
    end
end

local function playBackgroundMusic()
    playNextTrack()
end

function game:load(data)
    lg.setBackgroundColor(0, 0, 0)
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
        playerX = worldData.player.x 
        playerY = worldData.player.y 
        playerLoaded = true

        playerInventory = worldData.player.inventory
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

    -- Expsing self.player for debug purposes
    _PLAYER = self.player

    -- Initializing worldGen
    worldGen:load({player = self.player, world = self.world, worldName = self.worldName, seed = self.seed})
    
    self.renderBuffer = worldGen.tileSize * 2
    self.hoverEntity = false -- Contains the entity the mouse is over, Used for mining
    self.time = 0 -- Timer used for shader animations

    self.inventory = inventory:new(self.player)
    self.crafting = crafting:new(self.player)

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
        Shrub = 9,
        Wall = 18,
        Crafting = 28,
        Furnace = 29,
        health = 41,
        radiation = 42,
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
        {"brightness", "amount", 0.19},
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

    playBackgroundMusic()
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
        if fmath.pointInRect(mx, my, v.x, v.y, v.width, v.height) and fmath.distance(v.gridX, v.gridY, self.player.gridX, self.player.gridY) < self.player.reach and not self.inventoryOpen then
            v.hover = true
            self.hoverEntity = v
        end
    end
    
    -- Updating camera
    camera:lookAtEntity(self.player)
    camera:update(dt)
    
    -- Updating world
    worldGen:update(dt)

    -- Internal timer used for shaders
    self.time = self.time + dt
    if self.time > math.pi * 2 then self.time = 0 end
    -- Settings macros
    self.shaders:setMacro("rad", self.player.radiation)
    self.shaders:setMacro("time", self.time)

    -- Handle music transitioning 
    if gameAudio.background[currentIndex] and not gameAudio.background[currentIndex]:isPlaying() then
        playNextTrack()
    end

    -- Mining
    if lm.isDown(1) and self.hoverEntity and not self.inventoryOpen then
        self.player:mine(self.hoverEntity) 
    end

    -- Block Placing
    if lm.isDown(2) and  not self.inventoryOpen then

    end
end

function game:drawHud()
    local iconScale = 40 * scale_x
    local radiationScale = 34 * scale_x
    local width, height = lg.getWidth(), lg.getHeight()

    -- Player Inventory (Hotbar)
    local maxHotbarItems = 6
    local hotbarX = width * 0.5
    local hotbarY = height - height * 0.07
    local hotbarWidth = width * 0.3
    local hotbarHeight = height * 0.07
    local itemSize = hotbarHeight * 0.8
    local itemSpacing = (hotbarWidth - itemSize * maxHotbarItems) / (maxHotbarItems - 1)
    local itemX = hotbarX - (hotbarWidth * 0.5)
    local itemY = hotbarY + (hotbarHeight - itemSize) * 0.5
    local cornerRadius = itemSize * 0.2

    -- Draw hotbar background
    lg.setColor(0.2, 0.2, 0.2, 0.8)
    lg.rectangle("fill", hotbarX - hotbarWidth * 0.5, hotbarY, hotbarWidth, hotbarHeight, cornerRadius, cornerRadius)

    for i = 1, maxHotbarItems do
        local x = itemX + (i - 1) * (itemSize + itemSpacing)
        local y = itemY
    
        -- Draw item slot
        lg.setColor(0.3, 0.3, 0.3, 0.9)
        lg.rectangle("fill", x, y, itemSize, itemSize, cornerRadius, cornerRadius)
        lg.setColor(0.5, 0.5, 0.5, 0.9)
        lg.rectangle("line", x, y, itemSize, itemSize, cornerRadius, cornerRadius)
    
        -- Draw item icon and quantity
        local item = self.player.inventoryOrder[i]
        if item then
            local quantity = self.player.inventory[item]
            if self.icon[item] then
                if tileAtlas and tiles[self.icon[item]] then
                    lg.setColor(1, 1, 1)
                    lg.draw(tileAtlas, tiles[self.icon[item]], x + itemSize * 0.1, y + itemSize * 0.1, 0, itemSize * 0.8 / config.graphics.assetSize, itemSize * 0.8 / config.graphics.assetSize)
                    
                    lg.setFont(font.regular)
                    local quantityText = tostring(quantity)
                    local textWidth = font.regular:getWidth(quantityText)
                    local textHeight = font.regular:getHeight()
                    local textX = x + itemSize - textWidth - itemSize * 0.1
                    local textY = y + itemSize - textHeight - itemSize * 0.1
    
                    lg.setColor(1, 1, 1)
                    lg.print(quantityText, textX, textY)
                end
            end
        end
    end

    local function drawIconValue(icon, value, x, y, sizeScale, isHealth)
        sizeScale = sizeScale or iconScale
        
        if isHealth then
            local heartCount = math.floor(value / 2)
            local halfHeart = value % 2 ~= 0
            local heartSpacing = 2

            for i = 1, heartCount do
                lg.setColor(1, 1, 1, 1)
                lg.draw(tileAtlas, tiles[self.icon[icon]], x + (i - 1) * (sizeScale + heartSpacing), y, 0, sizeScale / config.graphics.assetSize, sizeScale / config.graphics.assetSize)
            end

            if halfHeart then
                lg.setColor(1, 1, 1, 1)
                lg.draw(tileAtlas, tiles[self.icon[icon] + 1], x + heartCount * (sizeScale + heartSpacing), y, 0, sizeScale / config.graphics.assetSize, sizeScale / config.graphics.assetSize)
            end
        else
            lg.setColor(1, 1, 1, 1)
            lg.draw(tileAtlas, tiles[self.icon[icon]], x, y, 0, sizeScale / config.graphics.assetSize, sizeScale / config.graphics.assetSize)
            lg.setFont(font.regular)
            local formattedValue = math.floor(value * 100) / 100
            lg.print(formattedValue, x + sizeScale, y + sizeScale * 0.2)
        end
    end 

    if self.inventory.inventoryOpen then
        self.inventory:draw(self.icon, itemSize, itemSpacing, cornerRadius, maxHotbarItems)
        self.crafting:draw()
    end

    -- Health
    local healthX = hotbarX - hotbarWidth * 0.5 + itemSize * 0.2
    local healthY = hotbarY + (hotbarHeight - itemSize) * 0.5 - 75
    drawIconValue("health", math.floor(self.player.health), healthX, healthY, nil, true)

    -- Radiation
    local radiationX = healthX + 200 * scale_x
    local radiationY = healthY
    drawIconValue("radiation", math.floor(self.player.radiation), radiationX, radiationY, radiationScale)
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

    if config.debug.enabled then
        lg.setColor(1, 0, 0)
        local all, all_len = self.world:query()
        local bumpItems = self.world:getBumpWorld():countItems()
        lg.setFont(font.tiny)
        lg.printf("FPS: "..love.timer.getFPS()..
        "\nEntities: "..#self.visibleEntities.."/"..all_len..
        "\nX: "..floor(self.player.x).." ("..self.player.gridX..") Y: "..floor(self.player.y).." ("..self.player.gridY..")"..
        "\nChunkX: "..self.player.chunkX.." ChunkY: "..self.player.chunkY..
        "\nLoaded chunks: "..worldGen.loadedChunkCount..
        "\nBump items: "..bumpItems..
        "\nWorld name: "..self.worldName.." World seed: "..tostring(self.seed), -12, 12, lg.getWidth(), "center")
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

    --self:drawMinimap(all)
end

function game:drawMinimap(all)
    -- Minimap
    local minimapScale = 4
    local minimapX = lg.getWidth() * 0.8
    local minimapY = lg.getHeight() * 0.8

    local miniMapColors = {
        {0, 0, 0, 1},
        {1, 1, 1, 1},
        {0.5, 0.5, 0.5},
        {0.8, 0.7, 0.5},
        {0.9, 0.9, 0.1},
        {0.1, 0.9, 0.1},
        {0.1, 0.7, 0.9},
        {0.9, 0.1, 0.1},
        {0.1, 0.1, 0.9},
        {0.1, 0.8, 0.9},
        {0.3, 0.8, 0.9},
        {0.3, 0.8, 0.9},
    }

    miniMapColors[0] = {1, 0, 0}
    
    local biomes = {
        {1, 0.6, 0.7},
        {0.1, 0.6, 0.3},
        {1, 0.3, 0.9},
        {1, 0.2, 0.2},
    }
    for i,v in ipairs(all) do
        if v.entityType == "tile" then
            if tonumber(v.type) then
                lg.setColor(miniMapColors[v.type])
                lg.rectangle("fill", minimapX + v.gridX * minimapScale - (self.player.gridX * minimapScale), minimapY + v.gridY * minimapScale - (self.player.gridY * minimapScale), minimapScale, minimapScale)
            end

            --lg.setColor(biomes[v.biome], biomes[v.biome], biomes[v.biome], 0.1)
            --lg.rectangle("line", minimapX + v.gridX * minimapScale - (self.player.gridX * minimapScale), minimapY + v.gridY * minimapScale - (self.player.gridY * minimapScale), minimapScale, minimapScale)
        elseif v.entityType == "player" then
            lg.setColor(0, 1, 0)
            lg.rectangle("fill", minimapX + v.gridX * minimapScale - (self.player.gridX * minimapScale), minimapY + v.gridY * minimapScale - (self.player.gridY * minimapScale), minimapScale, minimapScale)
        end
    end
end

function game:keypressed(key)
    if key == "f5" then
        worldGen:saveWorld()
    end

    -- Inventory
    inventory:keypressed(key)

    --Crafting
    self.crafting:keypressed(key)
end

function game:mousepressed(x, y, k)
    if self.inventory.inventoryOpen then
        self.inventory:mousepressed(x, y, button)
    elseif self.crafting.craftingOpen then
        self.crafting:mousepressed(x, y, button)
    end
end

return game