NAME = "Subterra"
VERSION = "v0.013"

-- GLOBALS
local lg = love.graphics
local fs = love.filesystem
local kb = love.keyboard
local lm = love.mouse
local lt = love.thread
local lw = love.window

-- Load configuration module
local Config = require("src.config")

function love.load()
    love.setDeprecationOutput(false)

    -- Load configuration
    config = Config.load()

    -- Creating folders
    if not fs.getInfo("worlds") then
        fs.createDirectory("worlds")
    end

    -- Loading classes
    require("src.class.util")
    require_folder("src.class")

    exString.import()

    -- Creating window
    lw.setMode(config.window.width, config.window.height, {
        fullscreen = config.window.fullscreen,
        resizable = config.window.resizable,
        borderless = config.window.borderless,
        highdpi = true
    })
    
    lw.setTitle(NAME .. " [" .. VERSION .. "]")

    -- Defining states
    state:define_state("src/state/game.lua", "game")
    state:define_state("src/state/menu.lua", "menu")
    state:define_state("src/state/paused.lua", "paused")
    state:define_state("src/state/grasslands.lua", "grasslands")
    state:define_state("src/state/icy.lua", "icy")

    -- POSTER
    poster = require("src.lib.poster")

    lg.setDefaultFilter("nearest", "nearest", 16)
    lg.setLineStyle("rough")
    lm.setVisible(false)

    -- Scaling
    scale_x = lg.getWidth() * 0.001
    scale_y = lg.getHeight() * 0.001

    -- Loading fonts
    font = {
        regular = lg.newFont("src/font/inter.ttf", 15 * scale_x),
        large = lg.newFont("src/font/inter.ttf", 6 * scale_x),
        tiny = lg.newFont("src/font/inter.ttf", 10 * scale_x),
        title = lg.newFont("src/font/MinecraftEvenings.ttf", 70 * scale_x),
        subtitle = lg.newFont("src/font/MinecraftEvenings.ttf", 40 * scale_x),
    }

    lg.setFont(font.regular)

    -- Loading tileset
    tileAtlas, tiles = loadAtlas("src/assets/tileset.png", 16, 16, 0)
    tileBreakImg, tileBreak = loadAtlas("src/assets/tileBreak.png", 16, 16, 0)

    -- Loading audio
    gameAudio = {
        background = {},
        currentTrackIndex = 1,
        isMusicPlaying = false
    }

    local function loadAudio(trackList, path)
        local audioSources = {}
        for _, trackName in ipairs(trackList) do
            local trackPath = path .. trackName .. ".mp3"
            if fs.getInfo(trackPath) then
                local source = love.audio.newSource(trackPath, "stream")
                source:setVolume(config.audio.master * config.audio.music)
                table.insert(audioSources, source)
            else
                print("Track " .. trackName .. " not found at path: " .. trackPath)
            end
        end
        return audioSources
    end

    local audioPath = "src/assets/audio/"
    local backgroundTracks = {"vanishinghope", "dreadfulwhispers"}
    gameAudio.background = loadAudio(backgroundTracks, audioPath)

    local function playNextTrack()
        if #gameAudio.background > 0 then
            -- Stop the current track if it's playing
            if gameAudio.isMusicPlaying then
                gameAudio.background[gameAudio.currentTrackIndex]:stop()
            end

            -- Move to the next track
            gameAudio.currentTrackIndex = (gameAudio.currentTrackIndex % #gameAudio.background) + 1
            local music = gameAudio.background[gameAudio.currentTrackIndex]

            -- Play the next track
            music:setLooping(false) -- Disable looping for individual tracks
            music:play()
            gameAudio.isMusicPlaying = true
        else
            note:new("No background music available to play.")
            print("No background music available to play.")
        end
    end

    playNextTrack()
    applyMasterVolume()

    state:load("menu", {})

    console:init(500, 200, font.tiny)

    config.debug.enabled = false
end

function save_config()
    Config.save(config)
end

function clear_config()
    Config.clear()
end

function applyMasterVolume()
    for _, source in pairs(gameAudio.background) do
        source:setVolume(config.audio.master * config.audio.music)
    end
end

function love.update(dt)
    keybind:trigger("keydown")
    state:update(dt)
    note:update(dt)
    smoof:update(dt)
    floatText:update(dt)
end

function love.draw()
    state:draw()
    note:draw()

    if state.loadedStateName ~= "menu" and state.loadedStateName ~= "paused" then
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
                return
            elseif _INVENTORY and _INVENTORY.inventoryOpen then
                _INVENTORY:toggleInventory()
                return
            end
        end
    end

    if key == gameControls.save then
        worldGen:saveWorld()
        note:new("Saved the game.", "default", 3, true)
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