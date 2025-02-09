local Config = {}

-- Default configuration
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
        enabled = false,
        text_color = {255, 255, 255},
        showChunkBorders = false,
        showCollision = false,
        saveChunks = true,
        playerCollision = true
    }
}

function Config.load()
    local fs = love.filesystem
    local ttf = require("src.class.ttf")

    if fs.getInfo("config.lua") then
        local success, loaded_config = pcall(ttf.load, "config.lua")
        if success then
            return Config.validate(loaded_config)
        else
            print("Error loading config: " .. tostring(loaded_config))
        end
    end

    Config.save(default_config)
    return default_config
end

function Config.save(config)
    local ttf = require("src.class.ttf")
    local success, err = pcall(ttf.save, config, "config.lua")
    if not success then
        print("Error saving config: " .. tostring(err))
    end
end

function Config.clear()
    local fs = love.filesystem
    fs.remove("config.lua")
end

function Config.validate(config)
    local validated_config = {}

    for section, default_values in pairs(default_config) do
        validated_config[section] = {}
        for key, default_value in pairs(default_values) do
            if config[section] and config[section][key] ~= nil then
                validated_config[section][key] = config[section][key]
            else
                validated_config[section][key] = default_value
            end
        end
    end

    return validated_config
end

return Config