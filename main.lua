NAME = "Miners Odyssey"
VERSION = "v0.010 (Pre Alpha 1c)"
config = {}

-- GLOBALS
lg = love.graphics
fs = love.filesystem
kb = love.keyboard
lm = love.mouse
lt = love.thread
random = math.random
noise = love.math.noise
sin = math.sin
cos = math.cos
f = string.format
floor = math.floor

function love.load()
    -- Loaidng classes
    require("src.class.util")
    require_folder("src.class")

    exString.import()   

    --Global keypress events love.system.openURL("file://"..love.filesystem.getSaveDirectory())
    keybind:new("keypressed", {"escape","lshift"}, love.event.push, "quit")
    keybind:new("keypressed", {"escape","lctrl"}, love.system.openURL, "file://"..love.filesystem.getSaveDirectory())

    -- Defining states
    state:define_state("src/state/game.lua", "game")
    state:define_state("src/state/menu.lua", "menu")
    state:define_state("src/state/paused.lua", "paused")

    --Config
    local default_config = {
        window = {
            width = 1280,
            height = 720,
            fullscreen = true,
            resizable = true,
            vsync = true
        },
        graphics = {
            useLight = true,
            useShaders = true,
            bloom = 0.4,
            brightness = 0.19,
            lightDistance = 500,
            ambientLight = 0.3,
            lightColor = {1, 0.9, 0.8},
            tileSize = 40,
            assetSize = 16
        },
        audio = {
            master = 1,
            music = 0.2,
            sfx = 1
        },
        settings = {
            chunkSaveInterval = 10,
            chunkSize = 6,
            playerName = "Pickle",
            skinColour = {
                colour = {0.149, 0.361, 0.259, 1.0},
                colour2 = {25/255, 60/255, 62/255, 1.0} 
            }
        },
        debug = {
            enabled = true,
            text_color = {255, 255, 255},
            showChunkBorders = false,
            showCollision = false,
            saveChunks = true,
            playerCollision = true
        }
    }

    gameControls = {
        right = "d",
        left = "a",
        down = "s",
        up = "w",
        sprint = "lshift",
        inventory = "i",
        chat = "t",
        pause = "escape"
    }

    if fs.getInfo("config.lua") then
        config = ttf.load("config.lua")
    else
        config = default_config
        save_config()
    end

    -- Creating folders
    if not fs.getInfo("worlds") then
        fs.createDirectory("worlds")
    end

    -- Creating window
    love.window.setMode(config.window.width, config.window.height, {fullscreen=config.window.fullscreen, resizable=config.window.resizable })
    love.window.setTitle(NAME.." ["..VERSION.."]")

    -- POSTER
    poster = require("src.lib.poster")

    lg.setDefaultFilter("nearest", "nearest")
    lg.setLineStyle("rough")
    lm.setVisible(false)

    --Scaling
    scale_x = lg.getWidth() * 0.001
    scale_y = lg.getHeight() * 0.001

    --Loading fonts
    font = {
        regular = lg.newFont("src/font/monogram.ttf", 24 * scale_x),
        large = lg.newFont("src/font/monogram.ttf", 64 * scale_x),
        tiny = lg.newFont("src/font/monogram.ttf", 16 * scale_x),
        title = lg.newFont("src/font/PressStart2P-Regular.ttf", 40 * scale_x),
    }

    lg.setFont(font.regular)

    -- Loading tileset
    tileAtlas, tiles = loadAtlas("src/assets/tileset.png", 16, 16, 0)
    tileBreakImg, tileBreak = loadAtlas("src/assets/tileBreak.png", 16, 16, 0)

    -- loading shader
    replaceShader = love.graphics.newShader("src/lib/poster/shaders/replacement.frag")
    local targetColor = {0.149, 0.361, 0.259, 1.0}
    local replacementColor = config.settings.skinColour.colour
    local replacementColor2 = config.settings.skinColour.colour2
    local tolerance = 0.1

    replaceShader:send("targetColor", targetColor)
    replaceShader:send("replacementColor", replacementColor)
    replaceShader:send("replacementColor2", replacementColor2)
    replaceShader:send("tolerance", tolerance)
    
    -- loading audio
    gameAudio = {background = {}, menu = {}}

    local backgroundMusic = {
        "serenity",
        "dreaming",
        "silent_echoes"
    }

    local path = "src/assets/audio/"
    for _, v in ipairs(backgroundMusic) do
        if love.filesystem.exists(path..v..".mp3") then
            gameAudio.background[#gameAudio.background+1] = love.audio.newSource(path..tostring(v)..".mp3", "stream")
        else 
            print(v.." not found at path "..path)
        end
    end

    gameAudio.menu[#gameAudio.menu+1] = love.audio.newSource(path.."Dreamers.wav", "stream")
    gameAudio.menu[1]:play()

    applyMasterVolume()

    state:load("menu", {worldName = "test"})
    --state:load("game", {type = "load", worldName = "test"})

    console:init(500, 200, font.tiny)
    console:setVisible(false)

    config.debug.enabled = false
end

function save_config()
    ttf.save(config, "config.lua")
end

function clear_config()
    fs.remove("config.lua")
end

function applyMasterVolume()
    for _, source in pairs(gameAudio.background) do
        source:setVolume(config.audio.master * config.audio.music)
    end
    if gameAudio.menu[1] then
        gameAudio.menu[1]:setVolume(config.audio.master * config.audio.music)
    end
end

--The following are callback functions
function love.update(dt)
    keybind:trigger("keydown")
    state:update(dt)
    note:update(dt)
--    console:update(dt)
    smoof:update(dt)
    floatText:update(dt)
end

function love.draw()
    lg.setColor(1, 1, 1, 1)
    state:draw()

    note:draw()

    if state.loadedStateName == "game" then
        console:draw()
    end

    local mx, my = lm.getPosition()
    lg.setColor(1, 1, 1, 1)
    lg.circle("fill", mx, my, 2 * scale_x)
    lg.circle("line", mx, my, 4 * scale_x)
end

function love.keypressed(key)
    keybind:keypressed(key)
    keybind:trigger("keypressed", key)
    state:keypressed(key)
    console:keypressed(key)

    if key == gameControls.pause then
        if console:getVisible() then
            console:setVisible(false) 
        elseif _INVENTORY and _INVENTORY.inventoryOpen then
            _INVENTORY:toggleInventory()
        elseif state.loadedStateName == "game" then
            state:load("paused")
        elseif state.loadedStateName == "paused" then
            state:load("game")
        else
            state:load("menu")
        end
    end

    if key == gameControls.chat then
        if _INVENTORY and _INVENTORY.inventoryOpen then
            _INVENTORY:toggleInventory()
        end
        if state.loadedStateName == "game" then
            console:setVisible(true)
        end
    elseif key == "f2" then
        config.debug.enabled = not config.debug.enabled
    end

    -- DEBUG KEYS
    if state.loadedStateName == "game" and not console:getVisible() then
        if key == "l" then
            config.graphics.useLight = not config.graphics.useLight
            note:new("Lights: "..tostring(config.graphics.useLight))
        elseif key == "b" then
            config.debug.showChunkBorders = not config.debug.showChunkBorders
            note:new("Show chunk borders: "..tostring(config.debug.showChunkBorders))
        end
    end
end

function love.textinput(t)
    state:textinput(t)
    console:textinput(t)
end

function love.keyreleased(key)
    keybind:trigger("keyreleased", key)
    keybind:keyreleased(key)
    state:keyreleased(key)
end

function love.resize(w, h)
    scale_x = w / config.window.width
    scale_y = h / config.window.height
    state:resize(w, h)
end

function love.mousepressed(x, y, key)
    state:mousepressed(x, y, key)
end

function love.mousereleased(x, y, button, istouch, presses)
    state:mousereleased(x, y, button, istouch, presses)
end

function love.mousemoved(x, y, dx, dy, touched)
    state:mousemoved(x, y, dx, dy)
end

function love.wheelmoved(x, y)
    state:wheelmoved(x, y)
end

function love.quit()
    state:quit()
end