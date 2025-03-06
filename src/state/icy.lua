local inventory = require("src/class/inventory")
local minimap = require("src/lib/minimap")
local statusBars = require("src/lib/statusBars")

UI = require("src/lib/UIHandler")

local lg = love.graphics
local fs = love.filesystem
local kb = love.keyboard
local lm = love.mouse
local joy = love.joystick
local lt = love.thread

local icy = {}

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

function icy:load(data)
    config = ttf.load("config.lua")

    lg.setBackgroundColor(0, 0, 0)
    self:resize(love.graphics.getWidth(), love.graphics.getHeight())

    local playerX, playerY = 0, 0 -- Grid coordinates!
    local playerLoaded = false -- True if player loaded from save file
    local playerInventory = {}
  
    local worldData = fs.load("worlds/"..data.name.."/config.lua")()
    
    self.worldName = worldData.name
    self.seed = worldData.seed
    self.worldType = "IceCaves"
   
    playerInventory = worldData.player.inventory
    playerX = worldData.player.x 
    playerY = worldData.player.y 
    playerLoaded = true
    
    -- Initializing the ECS world
    self.world = ecs.new()
    self.world:loadSystemFromFolder("src/system")

    -- Initializing player
    self.player = self.world:newEntity("src/entity/player.lua", playerX, playerY, {x = playerX, y = playerY, inventory = playerInventory, playerLoaded = playerLoaded})
    _PLAYER = self.player -- Set global reference
    self.inventory = _INVENTORY

    worldGen:load({
        player = self.player,
        world = self.world,
        worldName = self.worldName,
        seed = self.seed,
        worldType = self.worldType
    })
      
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
        IronIngot = 10, 
        GoldIngot = 11, 
        EmeraldIngot = 12, 
        DiamondIngot = 13, 
        RubyIngot = 14,
        TanzeniteIngot = 15, 
        CopperIngot = 16, 
        Wall = 18,
        MossyCobble = 27,
        Crafting = 28,
        Furnace = 29,
        StoneBrick = 30,
        Grass = 31,
        Dirt = 32,
        Lantern = 33,
        Chest = 34,
        Ice = 35,
        Teleporter = 36,
        Water = 37,
        Snow = 38,
        health = 41,
        halfHeart = 42,
        MagicPlant = 49,
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
        {"brightness", "amount", config.graphics.brightness * 1.2},
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

      -- Load snow texture
      self.snowTexture = love.graphics.newImage('src/assets/raintex.png')
      self.snowTexture:setWrap('repeat', 'repeat')
  
      -- Create mesh for snow
      local vertices = {
          { 0, 0, 0, 0, 255, 255, 255, 255 }, -- Top-left
          { self.snowTexture:getWidth(), 0, 1, 0, 255, 255, 255, 255 }, -- Top-right
          { self.snowTexture:getWidth(), self.snowTexture:getHeight(), 1, 1, 255, 255, 255, 255 }, -- Bottom-right
          { 0, self.snowTexture:getHeight(), 0, 1, 255, 255, 255, 255 }, -- Bottom-left
      }
      self.snowMesh = love.graphics.newMesh(vertices, 'fan')
      self.snowMesh:setTexture(self.snowTexture)
  
      -- Snow intensity
      self.snowIntense = false
      self.snowTime = 0.0
      self.snowWave = 5.0
end

function icy:unload()
    ecs.unload()
    self.world = nil
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

local function isJoystickButtonDown(button)
    local joysticks = joy.getJoysticks()
    for _, joystick in ipairs(joysticks) do
        if joystick:isDown(button) then
            return true
        end
    end
    return false
end

local function centerEntityOnTile(entity, x, y, tileSize)
    entity.x = x * tileSize + (tileSize / 2)
    entity.y = y * tileSize + (tileSize / 2) - (entity.collisionBoxHeight / 2)
end

function worldGen:centerPlayerOnTile(x, y)
    x = x or self.player.gridX
    y = y or self.player.gridY
    centerEntityOnTile(self.player, x, y, self.tileSize)
end


function icy:update(dt)
    self.visibleEntities = self.world:queryRect(camera.x - self.renderBuffer, camera.y - self.renderBuffer, lg.getWidth() + self.renderBuffer * 2, lg.getHeight() + self.renderBuffer * 2)
    local health = config.player.health

    local mx, my = camera:getMouse()
    
    local lookX = getJoystickAxis(3) -- Right Stick X
    local lookY = getJoystickAxis(4) -- Right Stick Y

    for i,v in ipairs(self.visibleEntities) do
        v.hover = false
        if fmath.pointInRect(mx, my, v.x, v.y, v.width, v.height) and fmath.distance(v.gridX, v.gridY, self.player.gridX, self.player.gridY) < self.player.reach and not self.inventory.inventoryOpen and not UI.active then
            v.hover = true
            self.hoverEntity = v
        end
    end

    --self.slimeSpawnTimer = (self.slimeSpawnTimer or 0) + dt
    --if self.slimeSpawnTimer >= 120 then
    --    self.slimeSpawnTimer = 0
    --    if #self.slimes < 5 then
    --        self.slimes[#self.slimes+1] = spawnSlimes(self.player.gridX, self.player.gridY, self.world)
    --    end
    --end

    self.snowTime = self.snowTime + dt * 7

    if self.snowIntense then
        self.snowWave = 5 + math.sin(self.snowTime) * 1.5
        for i = 1, 4 do
            local u, v = self.snowMesh:getVertexAttribute(i, 2)
            u, v = u - dt / self.snowWave, v - dt * 1.3
            self.snowMesh:setVertexAttribute(i, 2, u, v)
        end
    else
        for i = 1, 4 do
            local u, v = self.snowMesh:getVertexAttribute(i, 2)
            u, v = u - dt / 12, v - dt / 2 -- Slower snow
            self.snowMesh:setVertexAttribute(i, 2, u, v)
        end
    end
    
    --attempt for controller
    if math.abs(lookX) > 0.2 or math.abs(lookY) > 0.2 then
       local direction = {x = lookX, y = lookY}
       local directionLength = math.sqrt(direction.x * direction.x + direction.y * direction.y)
       direction.x = direction.x / directionLength
       direction.y = direction.y / directionLength

       local closestEntity = nil
       local closestDistance = math.huge
           for i, v in ipairs(self.visibleEntities) do
           local entityCenterX = v.x + v.width / 2
           local entityCenterY = v.y + v.height / 2
           local playerCenterX = self.player.x + self.player.width / 2
           local playerCenterY = self.player.y + self.player.height / 2
                   local dx = entityCenterX - playerCenterX
           local dy = entityCenterY - playerCenterY
           local distance = math.sqrt(dx * dx + dy * dy)

           local dotProduct = direction.x * dx + direction.y * dy
           local angle = math.acos(dotProduct / (directionLength * distance))

           if angle < math.pi / 4 and distance < closestDistance then
               closestEntity = v
               closestDistance = distance
           end
       end
           if closestEntity and fmath.distance(closestEntity.gridX, closestEntity.gridY, self.player.gridX, self.player.gridY) < self.player.reach and not self.inventory.inventoryOpen and not UI.active then
           closestEntity.hover = true
           self.hoverEntity = closestEntity
       end
    end

    local placeTrigger = getJoystickAxis(5) -- LT
    local mineTrigger = getJoystickAxis(6) -- RT
     
    if mineTrigger > 0.5 and self.hoverEntity and not self.inventory.inventoryOpen then
        self.player:mine(self.hoverEntity)
    end
    
    if placeTrigger > 0.5 and self.hoverEntity and not self.inventory.inventoryOpen then
        self.player:placeTile(self.hoverEntity)
    end
    
    -- Updating camera
    camera:lookAtEntity(self.player)
    camera:update(dt)
    
    -- Updating world
    worldGen:update(dt)
    UI:update(dt)

    self.player:update(dt)

    --for _, v in ipairs(self.slimes) do
    --    v:update(dt)
    --end

    -- Internal timer used for shaders
    self.time = self.time + dt
    if self.time > math.pi * 2 then self.time = 0 end

    self.player.time = self.player.time + dt * 0.05
    if self.player.time >= 24 then
        self.player.time = 0 
    end

    -- Handle dying
    if health <= 0 then
        if self.player.spawnX and self.player.spawnY then
            self.player:teleport(self.player.spawnX, self.player.spawnY)
        end
        
        health = 10
        
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
        self.player:mine(self.hoverEntity)
    end
end

function icy:drawHud()
    local iconScale = 30 * scale_x
    local radiationScale = 34 * scale_x
    local width, height = lg.getWidth(), lg.getHeight()

    local hotbarX = width * 0.5
    local hotbarY = height - height * 0.07
    local hotbarWidth = width * 0.28 
    local hotbarHeight = height * 0.07
    local itemSize = hotbarHeight * 0.8
    local maxHotbarItems = 4
    local itemSpacing = (hotbarWidth - itemSize * maxHotbarItems) / (maxHotbarItems - 1)
    local cornerRadius = 2

    local hotbarPadding = itemSize * 0.08 
    local adjustedHotbarWidth = hotbarWidth + hotbarPadding * 2

    local itemX = hotbarX - (adjustedHotbarWidth * 0.5) + hotbarPadding
    local itemY = hotbarY + (hotbarHeight - itemSize) * 0.5

    self.inventory:draw(self.icon, itemSize, 10 * scale_x, cornerRadius, maxHotbarItems)

    self.inventory:drawHotbar(self.icon)
end

function icy:gamepadpressed(joystick, button)
    self.inventory:gamepadpressed(joystick, button)
end

function icy:draw()
    self.canvas:set()
    lg.clear()

    camera:push()
    self.world:update(self.visibleEntities)
    self.player:draw()

   -- for _, v in ipairs(self.slimes) do
   --     v:draw()
   -- end

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
    
    love.graphics.setColor(1, 1, 1, 0.3) -- Ensure snow is white
    love.graphics.draw(self.snowMesh, 0, 0, 0, love.graphics.getWidth() / self.snowTexture:getWidth(), love.graphics.getHeight() / self.snowTexture:getHeight())
    if self.snowIntense then
        love.graphics.draw(self.snowMesh, 0, 0, 0, love.graphics.getWidth() / self.snowTexture:getWidth(), love.graphics.getHeight() / self.snowTexture:getHeight())
    end
   
    self:drawHud()

    local all, all_len = self.world:query()
    if config.debug.enabled then
        lg.setColor(1, 0, 0)
        local bumpItems = self.world:getBumpWorld():countItems()
        lg.setFont(font.tiny)
        lg.printf("FPS: " .. love.timer.getFPS() ..
        "\nRam: " .. tostring(math.floor(collectgarbage("count") / 1024) + 100) .. " MB" ..
        "\nVRam: " .. tostring(math.floor(love.graphics.getStats().texturememory / 1024 / 1024)) .. " MB" ..
        "\nLoaded chunks: " .. worldGen.loadedChunkCount ..
        "\nBump items: " .. bumpItems ..
        "\nDimension: " .. _worldType, 
        -12, 12, lg.getWidth(), "center")
    
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

    UI:draw()

    --TODO make slimes a mob class
    minimap:draw(self.player, self.slimes, all, camera, "right")
   
    local barWidth = 250
    local barSpacing = 10
    local barsX = 30
    local barsY = 150
    statusBars.drawAllBars(self.player, barsX, barsY, barWidth, barSpacing)
end

function icy:keypressed(key)
    local gameControls = config.settings.gameControls

    if key == gameControls.save then
        worldGen:saveWorld()
    end

    if key == gameControls.conjure and not console.isOpen then
        UI:toggle("arcane", {})
    end

    -- Inventory
    self.inventory:keypressed(key)

    -- Hotbar selection
    if tonumber(key) and tonumber(key) >= 1 and tonumber(key) <= 8 then
        self.inventory.selectedIndex = tonumber(key)
        self.inventory.highlightedItem = self.inventory.inventoryOrder[self.inventory.selectedIndex]
    end
end

function icy:wheelmoved(x, y)
    self.inventory.selectedIndex = self.inventory.selectedIndex + y
    if self.inventory.selectedIndex < 1 then
        self.inventory.selectedIndex = 8
    elseif self.inventory.selectedIndex > 8 then
        self.inventory.selectedIndex = 1
    end
    self.inventory.highlightedItem = self.inventory.inventoryOrder[self.inventory.selectedIndex]
end

function icy:resize(w, h)

end

function icy:mousepressed(x, y, button)
    if self.inventory.inventoryOpen then
        self.inventory:mousepressed(x, y, button)
    end

    UI:mousepressed(x, y, button)

    -- Placing/Interacting
    if button == 2 and self.hoverEntity and not self.inventory.inventoryOpen then
        local itemId = self.icon[self.inventory.highlightedItem]

        -- If it's a teleporter, open the UI instead of placing a tile
        if self.hoverEntity.type == 15 and itemId == nil then
            UI:open("teleporter", {})
        else
            self.player:placeTile(self.hoverEntity)  -- Place a block
            self.player:interact(self.hoverEntity)  -- Interact only if not a teleporter
        end
    end
end

function icy:mousereleased(x, y, button)
    UI:mousereleased(x, y, button)
end

return icy