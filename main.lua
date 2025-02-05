NAME = "Subterra"
VERSION = "v0.012"
config = {}
local ttf = require("src.class.ttf")

-- GLOBALS
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

function love.load()
    love.setDeprecationOutput(false) --Remove when updating to love 12

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
            bloom = 0.5,
            brightness = 0.19,
            lightDistance = 500,
            ambientLight = 0.4,
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
            gameControls = {
                right = "d",
                left = "a",
                down = "s",
                up = "w",
                save = "f5",
                sprint = "lshift",
                inventory = "i",
                chat = "t",
                conjure = "g",
                pause = "escape"
            }
        },
        player = {
            health = 10,
            stamina = 10,
            magic = 2,
            magicCap = 10,
        },
        skinColour = {
            colour = {0.149, 0.361, 0.259, 1.0},
            colour2 = {25/255, 60/255, 62/255, 1.0} 
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
    
    -- Loading classes
    require("src.class.util")
    require_folder("src.class")

    exString.import()   

    -- Creating window
    love.window.setMode(config.window.width, config.window.height, {fullscreen=config.window.fullscreen, resizable=config.window.resizable })
    love.window.setTitle(NAME.." ["..VERSION.."]")

    -- Defining states
    state:define_state("src/state/game.lua", "game")
    state:define_state("src/state/menu.lua", "menu")
    state:define_state("src/state/paused.lua", "paused")

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
        regular = lg.newFont("src/font/inter.ttf", 15 * scale_x),
        large = lg.newFont("src/font/inter.ttf", 6 * scale_x),
        tiny = lg.newFont("src/font/inter.ttf", 10 * scale_x),
        title = lg.newFont("src/font/MinecraftEvenings.ttf", 70 * scale_x),
    }

    lg.setFont(font.regular)

    -- Loading tileset
    tileAtlas, tiles = loadAtlas("src/assets/tileset.png", 16, 16, 0)
    tileBreakImg, tileBreak = loadAtlas("src/assets/tileBreak.png", 16, 16, 0)

    -- loading shader
    replaceShader = love.graphics.newShader("src/lib/poster/shaders/replacement.frag")
    local targetColor = {0.149, 0.361, 0.259, 1.0}
    replacementColor = config.skinColour.colour
    replacementColor2 = config.skinColour.colour2
    
    local tolerance = 0.1

    replaceShader:send("targetColor", targetColor)
    replaceShader:send("replacementColor", replacementColor)
    replaceShader:send("tolerance", tolerance)
    
    -- loading audio
    gameAudio = {
        background = 0
    }

    local function loadAudio(trackList, path)
        local audioSources = {}
        for _, trackName in ipairs(trackList) do
            local trackPath = path .. trackName .. ".mp3"
            if love.filesystem.exists(trackPath) then
                table.insert(audioSources, love.audio.newSource(trackPath, "stream"))
            else
                print("Track " .. trackName .. " not found at path: " .. path)
            end
        end
        return audioSources
    end
    
    local audioPath = "src/assets/audio/"
    local backgroundTracks = {"1"}
    gameAudio.background = loadAudio(backgroundTracks, audioPath)

    local function playBackgroundMusic()
        if #gameAudio.background > 0 then
            local music = gameAudio.background[1]
            if not music:isPlaying() then
                music:setLooping(true)
                music:play()
            end
        else
            print("No background music available to play.")
        end
    end
    
    playBackgroundMusic()
    applyMasterVolume()

    state:load("menu", {worldName = "test"})
    --state:load("game", {type = "load", worldName = "test"})

    console:init(500, 200, font.tiny)

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
    local gameControls = config.settings.gameControls

    keybind:keypressed(key)
    keybind:trigger("keypressed", key)
    state:keypressed(key)
    console:keypressed(key)
    
    if key == "escape" then
        if UI then
            if UI.active then
                UI:close()
                return  -- Prevent further processing of the escape key
            elseif _INVENTORY and _INVENTORY.inventoryOpen then
                _INVENTORY:toggleInventory()
                return
            end
        end
    end
        
    if key == gameControls.pause then
        if console.isOpen then
            console.isOpen = false
        else
            if _INVENTORY and _INVENTORY.inventoryOpen then
                _INVENTORY:toggleInventory()
            end
            
            if state.loadedStateName == "game" and not UI.active then
                state:load("paused")
            elseif state.loadedStateName == "game" and UI.active then
                UI.close()
            elseif state.loadedStateName == "paused" then
                state:resume_previous_state()
            else
                state:load("menu")
            end
        end
    elseif key == gameControls.chat then
        if _INVENTORY and _INVENTORY.inventoryOpen then
            _INVENTORY:toggleInventory()
        end
        if state.loadedStateName == "game" then
            console.isOpen = true
        end
    elseif key == "f2" then
        config.debug.enabled = not config.debug.enabled
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

function love.gamepadpressed(joystick, button)
    state:gamepadpressed(joystick, button)
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