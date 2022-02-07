NAME = "Cave game"
VERSION = 0.1
 
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
    require_folder("src/class")

    exString.import()

    --Global keypress events love.system.openURL("file://"..love.filesystem.getSaveDirectory())
    keybind:new("keypressed", {"escape","lshift"}, love.event.push, "quit")
    keybind:new("keypressed", {"escape","lctrl"}, love.system.openURL, "file://"..love.filesystem.getSaveDirectory())

    -- Defining states
    state:define_state("src/state/game.lua", "game")
    state:define_state("src/state/menu.lua", "menu")

    --Config
    default_config = {
        window = {
            width = 1024,
            height = 576,
            fullscreen = false,
            title = NAME.." ["..VERSION.."]"
        },
        graphics = {
            useLight = true,
            lightDistance = 400,
            ambientLight = 0.1,
            lightColor = {1, 0.9, 0.8},
            tileSize = 40,
            assetSize = 16
        },
        settings = {
            chunkSaveInterval = 10,
            chunkSize = 6
        },
        debug = {
            enabled = true,
            text_color = {255, 144, 79},
            showChunkBorders = false,
            showCollision = false,
            saveChunks = true,
            playerCollision = true
        }
    }

    config = default_config
    if fs.getInfo("config.lua") then
        --config = ttf.load("config.lua")
    else
        --save_config()
    end

    -- Creating folders
    if not fs.getInfo("worlds") then
        fs.createDirectory("worlds")
    end

    -- Creating window
    love.window.setMode(config.window.width, config.window.height, {fullscreen=config.window.fullscreen})
    love.window.setTitle(config.window.title)

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
    }

    lg.setFont(font.regular)

    -- Loading tileset
    tileAtlas, tiles = loadAtlas("src/assets/tileset.png", 16, 16, 0)
    tileBreakImg, tileBreak = loadAtlas("src/assets/tileBreak.png", 16, 16, 0)


    --state:load("menu", {worldName = "test"})
    state:load("game", {type = "load", worldName = "test"})

    console:init(0, 0, lg.getWidth(), lg.getHeight(), false, font.regular)
    console:setVisible(false)


    for i=1, 30 do
        print(weightedRandom({100, 20, 20, 20}))
    end

end

function save_config()
    ttf.save(config, "config.lua")
end

function clear_config()
    fs.remove("config.lua")
end

--The following are callback functions
function love.update(dt)
    keybind:trigger("keydown")
    state:update(dt)
    note:update(dt)
    console:update(dt)
end

function love.draw()
    lg.setColor(1, 1, 1, 1)
    state:draw()

    note:draw()

    lg.setColor(1, 0, 1)
    lg.print(love.timer.getFPS(), 12, 12)

    console:draw()

    local mx, my = lm.getPosition()
    lg.setColor(1, 1, 1, 1)
    lg.circle("fill", mx, my, 2 * scale_x)
end

function love.keypressed(key)
    keybind:keypressed(key)
    keybind:trigger("keypressed", key)
    state:keypressed(key)
    console:keypressed(key)
    if key == "escape" then
        if console:getVisible() then
            console:setVisible(false) 
        else
            state:load("menu")
        end
    end

    if key == "f1" then
        console:setVisible(true)
    end
    -- DEBUG KEYS
    if state.loadedStateName == "game" and not console:getVisible() then
        if key == "l" then
            config.graphics.useLight = not config.graphics.useLight
        elseif key == "b" then
            config.debug.showChunkBorders = not config.debug.showChunkBorders
        elseif key == "c" then
            config.debug.showCollision = not config.debug.showCollision
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

function love.mousepressed(x, y, key)
    state:mousepressed(x, y, key)
end

function love.mousereleased(x, y, key)
    state:mousereleased(x, y, key)
end

function love.wheelmoved(x, y)
    state:wheelmoved(x, y)
end

function love.quit()
    state:quit()
end