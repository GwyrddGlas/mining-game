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
        self.worldData = fs.load("worlds/"..data.worldName.."/config.lua")()
        self.worldName = self.worldData.name
        self.seed = self.worldData.seed
        playerInventory = self.worldData.player.inventory
        playerX = self.worldData.player.x 
        playerY = self.worldData.player.y 
        playerLoaded = true

        note:new("Loaded world '"..self.worldName.."'", "success")
    end

    love.keyboard.setTextInput(false)

    -- Initializing the ECS world
    self.world = ecs.new()
    self.world:loadSystemFromFolder("src/system")

    --Exposing self.world for debug purposes
    _WORLD = self.world
    _WORLDATA = self.worldData

    -- Initializing player
    self.player = self.world:newEntity("src/entity/player.lua", playerX, playerY, {x = playerX, y = playerY, inventory = playerInventory, playerLoaded = playerLoaded})
    self.inventory = inventory:new(self.player)
    
    self.slimes = {}
        
    -- Exposing for debug purposes
    _PLAYER = self.player
    _INVENTORY = self.inventory

    -- Initializing worldGen
    worldGen:load({player = self.player, world = self.world, worldName = self.worldName, seed = self.seed})
    
    self.renderBuffer = worldGen.tileSize * 2
    self.hoverEntity = false 
    self.time = 0 

    self.inventory.selectedIndex = 1
    self.inventory.highlightedItem = self.inventory.inventoryOrder[self.inventory.selectedIndex]

    self.fireflies = {}
    for i = 1, 50 do
        table.insert(self.fireflies, {
            x = math.random(0, love.graphics.getWidth()),
            y = math.random(0, love.graphics.getHeight()),
            direction = math.random() * 2 * math.pi,
            speed = math.random(20, 50),
            brightness = math.random(),
            size = math.random(2, 4),
        })
    end

    -- Icon tile id's
    self.icon = {
        Coal = 1,
        Iron = 2,
        Gold = 3,
        Uranium = 4,
        Diamond = 5,
        DimensionalShard = 6,
        Tanzenite = 7,
        Copper = 8,
        Shrub = 9, --stick
        IronIngot = 10, 
        GoldIngot = 11, 
        EmeraldIngot = 12, 
        DiamondIngot = 13, 
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
        {"brightness", "amount", config.graphics.brightness},
        {"contrast", "amount",config.graphics.contrast},
        {"saturation", "amount", config.graphics.saturation},
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

    self.fireflies = {}
    for i = 1, 50 do
        table.insert(self.fireflies, {
            x = math.random(0, love.graphics.getWidth()),
            y = math.random(0, love.graphics.getHeight()),
            direction = math.random() * 2 * math.pi,
            speed = math.random(20, 50),
            brightness = math.random(),
        })
    end

    playBackgroundMusic()

    UI:register("arcane", require("src/lib/UI/arcane"))
    UI:register("teleporter", require("src/lib/UI/teleporter"))
end

function game:unload()
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

local function spawnSlimes(playerX, playerY, world)
    local spawnRadius = 16
    local spawnX = playerX + math.random(-spawnRadius, spawnRadius)
    local spawnY = playerY + math.random(-spawnRadius, spawnRadius)

    local slime = world:newEntity("src/entity/slime.lua", spawnX, spawnY, {x = spawnX, y = spawnY})
    centerEntityOnTile(slime, spawnX, spawnY, worldGen.tileSize)
    return slime
end

function game:update(dt)
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

    self.slimeSpawnTimer = (self.slimeSpawnTimer or 0) + dt
    if self.slimeSpawnTimer >= 120 then
        self.slimeSpawnTimer = 0
        if #self.slimes < 5 then
            self.slimes[#self.slimes+1] = spawnSlimes(self.player.gridX, self.player.gridY, self.world)
        end
    end

    for _, firefly in ipairs(self.fireflies) do
        firefly.x = firefly.x + math.cos(firefly.direction) * firefly.speed * dt
        firefly.y = firefly.y + math.sin(firefly.direction) * firefly.speed * dt

        if math.random() < 0.01 then
            firefly.direction = math.random() * 2 * math.pi
        end

        -- Flicker brightness and size
        firefly.brightness = firefly.brightness + (math.random() - 0.5) * 0.1
        firefly.brightness = math.max(0, math.min(1, firefly.brightness)) -- Clamp brightness

        firefly.size = 2 + math.sin(self.time * 5) * 1 

        firefly.x = firefly.x % love.graphics.getWidth()
        firefly.y = firefly.y % love.graphics.getHeight()
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

    for _, v in ipairs(self.slimes) do
        v:update(dt)
    end

    -- Internal timer used for shaders
    self.time = self.time + dt
    if self.time > math.pi * 2 then self.time = 0 end

    self.player.time = self.player.time + dt * 0.025 --1 day = 16min
    if self.player.time >= 24 then
        self.player.time = 0 
        self.player.days = self.player.days + 1
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

function game:drawHud()
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

function game:gamepadpressed(joystick, button)
    self.inventory:gamepadpressed(joystick, button)
end

function game:draw()
    self.canvas:set()
    lg.clear()

    camera:push()
    self.world:update(self.visibleEntities)
    self.player:draw()

    for _, v in ipairs(self.slimes) do
        v:draw()
    end

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

    love.graphics.setColor(1, 1, 0)
    for _, firefly in ipairs(self.fireflies) do
        love.graphics.setColor(1, 1, 0, firefly.brightness) 
        love.graphics.circle("fill", firefly.x, firefly.y, firefly.size / 2)
    end

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

    lg.print("Day "..self.player.days, barsX, barsY - 50)
end

function game:keypressed(key)
    local gameControls = config.settings.gameControls

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

function game:wheelmoved(x, y)
    self.inventory.selectedIndex = self.inventory.selectedIndex + y
    if self.inventory.selectedIndex < 1 then
        self.inventory.selectedIndex = 8
    elseif self.inventory.selectedIndex > 8 then
        self.inventory.selectedIndex = 1
    end
    self.inventory.highlightedItem = self.inventory.inventoryOrder[self.inventory.selectedIndex]
end

function game:resize(w, h)

end

function game:mousepressed(x, y, button)
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

function game:mousereleased(x, y, button)
    UI:mousereleased(x, y, button)
end

return game