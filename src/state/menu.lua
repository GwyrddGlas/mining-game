local colourPicker = require("src.lib.colourPicker")

local lg = love.graphics
local fs = love.filesystem
local kb = love.keyboard
local lm = love.mouse
local lt = love.thread
local gameControls = config.settings.gameControls

local menu = {
    selectedWorld = nil,
    titleOffset = 0,
    titleSpeed = 20,  
    titleAmplitude = 10,
    skinOffset = 0
}

local nightSkyImage
local nightSkyCloudsImage
local nightSkyImageScaleX, nightSkyImageScaleY
local cloudSpeed = 11
local cloudOffset = 0
local skinColourToggle = false

-- Button functions
local function changeScreen(screen)
    return function()
        menu.currentScreen = screen
    end
end

local function exitButton()
    love.event.push("quit")
end

local function createButton()
    -- Limiting the max seed to the highest 32-bit integer minus 1000 because the world generation offsets the seed by up to 1000.
    -- Negative seeds are not allowed. At least for now.
    local maxSeed = 2147483647 - 1000
    local worldName = menu.screen.new.worldName.text

    if #worldName < 1 then
        worldName = "Untitled Game"
    end

    local seed = menu.screen.new.seed.text

    -- If no seed is provided, use the current time
    if #seed < 1 then
        seed = os.time()
    end

    if tonumber(seed) then
        seed = tonumber(seed)
    else
        seed = hashcode(seed)
    end

    if seed > maxSeed then
        seed = maxSeed
    end

    state:load("game", {type = "new", worldName = worldName, seed = tonumber(seed)})
end

local skins = {}
local selectedSkin = "default"
local picker
local characterSprite

local function loadSkins()
    local skinAnimations = {
        default = {skin = "src/assets/player/skin.png"},
        skin1 = {skin = "src/assets/player/skinBlue.png"}
    }
    skins = {
        {name = "default", path = skinAnimations.default.skin, id = nil},
        {name = "skin1", path = skinAnimations.skin1.skin, id = nil}
    }

    nightSkyImage = love.graphics.newImage("src/assets/night_sky_with_moon_and_stars.png")
    nightSkyCloudsImage = love.graphics.newImage("src/assets/clouds.png")
    nightSkyImageScaleX = love.graphics.getWidth() / nightSkyImage:getWidth()
    nightSkyImageScaleY = love.graphics.getHeight() / nightSkyImage:getHeight()
    
    for _, v in ipairs(skins) do
        v.id = love.graphics.newImage(v.path)
    end

    characterSprite = love.graphics.newImage("src/assets/player/skin.png")
end

local function selectSkin(skinName)
    selectedSkin = skinName
end

local function load()
    if currentTrack then
        currentTrack:stop()
        gameAudio.menu[1]:setVolume(config.audio.master * config.audio.music)
        gameAudio.menu[1]:play()
    end

    if menu.selectedWorld then
        state:load("game", {type = "load", worldName = menu.selectedWorld})
    end
    
    colourPicker.load("src/assets/pallet.png", config.skinColour.colour)
    loadSkins()
end

local function removeDirectory(dir)
    if fs.getInfo(dir).type == "directory" then
        for _, sub in pairs(fs.getDirectoryItems(dir)) do
            removeDirectory(dir.."/"..sub)
            fs.remove(dir.."/"..sub)
        end
    else
        fs.remove(dir)
    end
    fs.remove(dir)
end

function menu:nextSkin()
    if self.skinOffset + 3 < #skins then
        self.skinOffset = self.skinOffset + 1
        -- Update selectedSkin
        local newSelectedIndex = self.skinOffset + 1
        if newSelectedIndex <= #skins then
            selectedSkin = skins[newSelectedIndex].name
        end
    end
end

function menu:prevSkin()
    if self.skinOffset > 0 then
        self.skinOffset = self.skinOffset - 1
        -- Update selectedSkin
        local newSelectedIndex = self.skinOffset + 1
        selectedSkin = skins[newSelectedIndex].name
    end
end

function menu:selectCurrentSkin()
    selectSkin(selectedSkin)
end

function menu:drawCharacterPreview()
    local previewWidth = 200
    local previewHeight = 400
    local x = self.width * 0.7 + previewWidth/1.5
    local y = self.height * 0.7 - previewHeight

    -- Draw character sprite
    lg.setColor(1, 1, 1)
    local spriteX = x + previewWidth / 2
    local spriteY = y + previewHeight / 2
    
    -- Find the selected skin
    local selectedSkinImage
    for _, skin in ipairs(skins) do
        if skin.name == selectedSkin then
            selectedSkinImage = skin.id
            break
        end
    end
    
    local scale = 16
    lg.setShader(replaceShader)
    lg.draw(selectedSkinImage, spriteX, spriteY, 0, scale, scale, selectedSkinImage:getWidth() / 2, selectedSkinImage:getHeight() / 2)
    lg.setShader()
end

local function delete()
    if menu.selectedWorld then
        if not menu.deleteConfirmed then
            note:new("Warning: This will delete the world PERMANENTLY. This is your only warning", "danger", 8)
            menu.deleteConfirmed = true
        else
            removeDirectory("worlds/"..menu.selectedWorld)
            menu.selectedWorld = nil
            note:new("World '"..menu.selectedWorld.."' deleted.", "success")
            -- Reload the world list
            menu:load()
        end
    else
        note:new("Please select a world first", "danger")
    end
end

local function setNewKey(action, key)
    gameControls[action] = key
end

function menu:getSelectedTextbox(screen)
    for i, v in ipairs(self.screen[screen]) do
        if v.type == "textbox" and v.selected then
            return v, i
        end
    end
    return nil
end

local function drawSkins()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local rectX = 200
    local rectWidth = screenWidth - 400
    local rectHeight = 400
    local startY = (screenHeight - rectHeight) / 2

    local skinWidth = 300
    local skinHeight = 300
    local skinSpacing = 50
    local visibleSkins = 3
    local totalSkinWidth = visibleSkins * skinWidth + (visibleSkins - 1) * skinSpacing
    local startX = rectX + (rectWidth - totalSkinWidth) / 2

    -- Draw fancy background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", rectX, startY, rectWidth, rectHeight, 20, 20)

    -- Draw border
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.setLineWidth(5)
    love.graphics.rectangle("line", rectX, startY, rectWidth, rectHeight, 20, 20)

    -- Draw skins
    for i = 1, visibleSkins do
        local index = (menu.skinOffset or 0) + i
        local skin = skins[index]
        if skin then
            local x = startX + (i - 1) * (skinWidth + skinSpacing)
            local y = startY + 50

            -- Draw skin background
            love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
            love.graphics.rectangle("fill", x, y, skinWidth, skinHeight, 10, 10)

            -- Draw skin image
            love.graphics.setColor(1, 1, 1)
            local scale = math.min(skinWidth / skin.id:getWidth(), skinHeight / skin.id:getHeight()) * 0.8
            local spriteX = x + skinWidth / 2
            local spriteY = y + skinHeight / 2
            love.graphics.draw(skin.id, spriteX, spriteY, 0, scale, scale, skin.id:getWidth() / 2, skin.id:getHeight() / 2)

            -- Draw skin name
            love.graphics.setFont(font.regular)
            local skinNameWidth = font.regular:getWidth(skin.name)
            love.graphics.print(skin.name, x + (skinWidth - skinNameWidth) / 2, y + skinHeight + 10)

            -- Highlight selected skin
            if skin.name == selectedSkin then
                lg.setColor(221/255, 195/255, 105/255, 1)
                love.graphics.rectangle("line", x, y, skinWidth, skinHeight, 10, 10)
            end
        end
    end
end

function menu:load()
    lg.setBackgroundColor(0.1, 0.1, 0.1)
    self.width, self.height = lg.getWidth(), lg.getHeight()
    self.color = {
        fg = {1, 1, 1},
        bg = {0, 0, 0},
        idle = {0.4, 0.4, 0.4},
        danger = {0.8, 0.2, 0.2},
        success = {223/255, 147/255, 95/255},
        darker1 = {200.7/255, 132.3/255, 85.5/255},
        darker2 = {180/255, 119/255, 76.5/255} 
    }

    self.currentScreen = "main"

    self.screen = {
        main = {
            label.new(NAME, self.color.success, font.title, 0, lg.getHeight() * 0.2, "center"),
            label.new(VERSION, self.color.bg, font.regular, self.width*0.47 - font.regular:getWidth(VERSION)*0.4, self.height - 55, "center"),
            label.new("dsc.gg/miners-odyssey", self.color.bg, font.regular, 10, self.height - 55, "left"),
            button.new("Singleplayer", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.4, self.width * 0.4, self.height * 0.09, changeScreen("singleplayer")),
            button.new("Multiplayer", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.5, self.width * 0.4, self.height * 0.09, changeScreen("multiplayer")),
            --button.new("Mods", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.6, self.width * 0.4, self.height * 0.09, changeScreen("skins")),
            button.new("Settings", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.6, self.width * 0.4, self.height * 0.09, changeScreen("options")),
            button.new("Quit Game", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.7, self.width * 0.4, self.height * 0.09, exitButton),
            button.new("Change", self.color.fg, self.color.bg, self.width * 0.7, self.height * 0.7, self.width * 0.2, self.height * 0.09, changeScreen("skins")),        
        },
        singleplayer = {
            label.new("Singleplayer", self.color.success, font.title, 0, lg.getHeight() * 0.15, "center"),
            button.new("New world", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.4, self.width * 0.4, self.height * 0.09, changeScreen("new")),
            button.new("Load world", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.5, self.width * 0.4, self.height * 0.09, changeScreen("load")),
            button.new("Back", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.6, self.width * 0.4, self.height * 0.09, changeScreen("main")),
        },
        multiplayer = {
            label.new("Multiplayer", self.color.success, font.title, 0, lg.getHeight() * 0.15, "center"),
            ipAddress = textbox.new("", "IP Address", self.color.fg, self.color.idle, self.color.bg, self.width * 0.3, self.height * 0.4, self.width * 0.4, self.height * 0.09),
            port = textbox.new("", "Port", self.color.fg, self.color.idle, self.color.bg, self.width * 0.3, self.height * 0.5, self.width * 0.4, self.height * 0.09),
            button.new("Create Server", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.6, self.width * 0.4, self.height * 0.09, function()
                --local ip = menu.screen.multiplayer.ipAddress.text
                --local port = tonumber(menu.screen.multiplayer.port.text)
                --if ip ~= "" and port then
                --    network:init(ip, port)
                --    network:createServer()
                --    note:new("Server created at " .. ip .. ":" .. port, "success")
                --else
                --    note:new("Please enter a valid IP and Port", "danger")
                --end
                
                note:new("Multiplayer is not yet functional.", "important")
            end),
            button.new("Connect", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.7, self.width * 0.4, self.height * 0.09, function() 
                --local ip = menu.screen.multiplayer.ipAddress.text
                --local port = tonumber(menu.screen.multiplayer.port.text)
                --if ip ~= "" and port then
                --    network:init(ip, port)
                --    if network:connect() then
                --        note:new("Connected to server", "success")
                --    end
                --else
                --    note:new("Please enter a valid IP and Port", "danger")
                --end
                
                note:new("Multiplayer is not yet functional.", "important")
            end),
            button.new("Back", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.8, self.width * 0.4, self.height * 0.09, changeScreen("main")),
        },
        options = {
            label.new("Settings", self.color.success, font.title, 0, lg.getHeight() * 0.15, "center"),
            button.new("Graphics", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.3, self.width * 0.4, self.height * 0.09, changeScreen("graphics")),
            button.new("Sounds", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.4, self.width * 0.4, self.height * 0.09, changeScreen("sounds")),
            button.new("Controls", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.5, self.width * 0.4, self.height * 0.09, changeScreen("controls")),
            button.new("Save", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.6, self.width * 0.4, self.height * 0.09, function()
                clear_config()
                save_config()
                note:new("Settings saved!", "success")
            end),
            button.new("Back", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.7, self.width * 0.4, self.height * 0.09, changeScreen("main") ),
        },
        skins = {       
            label.new("Name", self.color.bg, font.tiny, self.width * 0.38, self.height * 0.42, "left"),
            characterName = textbox.new("", "Pickle", self.color.fg, self.color.idle, self.color.bg, self.width * 0.38, self.height * 0.45, self.width * 0.15, self.height * 0.05),
            --label.new("Colour", self.color.bg, font.tiny, self.width * 0.38, self.height * 0.52, "left"),
            button.new("Colour Picker", self.color.fg, self.color.bg, self.width * 0.38, self.height * 0.51, self.width * 0.15, self.height * 0.05, function(f)
                skinColourToggle = not skinColourToggle
                print(tostring(f))
            end),
            
            button.new("Save", self.color.fg, self.color.bg, self.width * 0.38, self.height * 0.65, self.width * 0.15, self.height * 0.05, function()
                save_config()
                note:new("Settings saved!", "success")
            end),
            button.new("Back", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.9, self.width * 0.4, self.height * 0.09, changeScreen("main")),
        },
        sounds = {
            label.new("Sound Settings", self.color.success, font.title, 0, lg.getHeight() * 0.15, "center"),
            slider.new("Master Volume", 0, 1, config.audio.master, self.width * 0.3, self.height * 0.4, self.width * 0.4, self.height * 0.05, {0.4, 0.4, 0.4}, {1, 1, 1}, function(value) 
                config.audio.master = value
                applyMasterVolume()
              end),
              slider.new("Music Volume", 0, 1, config.audio.music, self.width * 0.3, self.height * 0.5, self.width * 0.4, self.height * 0.05, {0.4, 0.4, 0.4}, {1, 1, 1}, function(value) 
                config.audio.music = value
                if currentTrack then
                    currentTrack:setVolume(value * config.audio.master)
                end
                if gameAudio.menu[1] then
                    gameAudio.menu[1]:setVolume(value * config.audio.master)
                end
            end),
            slider.new("SFX Volume", 0, 1, config.audio.sfx, self.width * 0.3, self.height * 0.6, self.width * 0.4, self.height * 0.05, {0.4, 0.4, 0.4}, {1, 1, 1}, function(value) config.audio.sfx = value end),
            button.new("Back", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.8, self.width * 0.4, self.height * 0.09, changeScreen("options"))
        },
        graphics = {
            label.new("Graphics Settings", self.color.success, font.title, 0, lg.getHeight() * 0.15, "center"),
            checkbox.new("Fog", self.color.fg, self.color.fg, self.width * 0.3, self.height * 0.3, self.width * 0.4, self.height * 0.05, config.graphics.useLight, 
                function(isChecked) 
                    config.graphics.useLight = isChecked 
                end),        
            checkbox.new("Shaders", self.color.fg, self.color.fg, self.width * 0.4, self.height * 0.3, self.width * 0.4, self.height * 0.05, config.graphics.useShaders, 
                function(isChecked) 
                    config.graphics.useShaders = isChecked 
                end),              
            checkbox.new("Vsync", self.color.fg, self.color.fg, self.width * 0.5, self.height * 0.3, self.width * 0.4, self.height * 0.05, config.window.vsync, 
                function(isChecked) 
                    love.window.setVSync(isChecked)
                    config.graphics.vsync = isChecked
                end),       
            
            slider.new("Bloom", 0, 1, config.graphics.bloom, self.width * 0.3, self.height * 0.4, self.width * 0.4, self.height * 0.05, {0.4, 0.4, 0.4}, {1, 1, 1}, function(value) config.graphics.bloom = value end),
            slider.new("Light Distance", 0, 600, config.graphics.lightDistance, self.width * 0.3, self.height * 0.5, self.width * 0.4, self.height * 0.05, {0.4, 0.4, 0.4}, {1, 1, 1}, function(value) config.graphics.ambientLight = value end),
            slider.new("Brightness", 0, 0.4, config.graphics.brightness, self.width * 0.3, self.height * 0.6, self.width * 0.4, self.height * 0.05, {0.4, 0.4, 0.4}, {1, 1, 1}, function(value) config.graphics.brightness = value end),
            slider.new("Ambient Light", 0, 1, config.graphics.ambientLight, self.width * 0.3, self.height * 0.7, self.width * 0.4, self.height * 0.05, {0.4, 0.4, 0.4}, {1, 1, 1}, function(value) config.graphics.ambientLight = value end),
            --colourPicker.new("Light Color", config.graphics.lightColor, self.width * 0.3, self.height * 0.55, self.width * 0.4, self.height * 0.05, {0.4, 0.4, 0.4}, {1, 1, 1}, function(r, g, b) config.graphics.lightColor = {r, g, b} end),
            button.new("Reset Graphics Settings", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.8, self.width * 0.4, self.height * 0.09, function()
                local defaultGraphics = {
                    useLight = true,
                    useShaders = true,
                    bloom = 0.4,
                    brightness = 0.19,
                    lightDistance = 500,
                    ambientLight = 0.3,
                    lightColor = {1, 0.9, 0.8},
                    tileSize = 40,
                    assetSize = 16
                }
            
                for key, value in pairs(defaultGraphics) do
                    config.graphics[key] = value
                end
                    
                save_config()
                note:new("Graphics settings have been reset to default.", "success")
            end),
            button.new("Back", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.9, self.width * 0.4, self.height * 0.09, changeScreen("options"))
        },
        new = {
            label.new("New world", self.color.success, font.title, 0, lg.getHeight() * 0.15, "center"),
            worldName = textbox.new("", "World name", self.color.fg, self.color.idle, self.color.bg, self.width * 0.3, self.height * 0.4, self.width * 0.4, self.height * 0.09),
            seed = textbox.new("", "Seed", self.color.fg, self.color.idle, self.color.bg, self.width * 0.3, self.height * 0.5, self.width * 0.4, self.height * 0.09, false, 10),
            button.new("Create world", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.6, self.width * 0.4, self.height * 0.09, createButton),
            button.new("Back", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.7, self.width * 0.4, self.height * 0.09, changeScreen("main")),
        },
        load = {
            label.new("Select World", self.color.success, font.title, 0, lg.getHeight() * 0.15, "center"),
            --button.new("Load world", self.color.success, self.color.bg, self.width * 0.05, self.height * 0.6, self.width * 0.25, self.height * 0.09, load),
            --button.new("Delete world", self.color.danger, self.color.bg, self.width * 0.05, self.height * 0.7, self.width * 0.25, self.height * 0.09, delete),
            --button.new("Back", self.color.fg, self.color.bg, self.width * 0.05, self.height * 0.8, self.width * 0.25, self.height * 0.09, changeScreen("main")),
        },
        controls = {
            label.new("Controls", self.color.success, font.title, 0, lg.getHeight() * 0.15, "center"),
            keybox.new("Forward", self.color.fg, self.color.fg, self.width * 0.3, self.height * 0.3, 120, self.height * 0.09, gameControls.up, function(key)
                setNewKey("up", key)
            end),
            keybox.new("Backward", self.color.fg, self.color.fg, self.width * 0.3, self.height * 0.4, 120, self.height * 0.09, gameControls.down, function(key)
                setNewKey("down", key)
            end),
            keybox.new("Left", self.color.fg, self.color.fg, self.width * 0.3, self.height * 0.5, 120, self.height * 0.09, gameControls.left, function(key)
                setNewKey("left", key)
            end),
            keybox.new("Right", self.color.fg, self.color.fg, self.width * 0.3, self.height * 0.6, 120, self.height * 0.09, gameControls.right, function(key)
                setNewKey("right", key)
            end),
            keybox.new("Sprint", self.color.fg, self.color.fg, self.width * 0.5, self.height * 0.3, 120, self.height * 0.09, gameControls.sprint, function(key)
                setNewKey("sprint", key)
            end),
            keybox.new("Inventory", self.color.fg, self.color.fg, self.width * 0.5, self.height * 0.4, 120, self.height * 0.09, gameControls.inventory, function(key)
                setNewKey("inventory", key)
            end),
            keybox.new("Chat", self.color.fg, self.color.fg, self.width * 0.5, self.height * 0.5, 120, self.height * 0.09, gameControls.chat, function(key)
                setNewKey("chat", key)
            end),
            keybox.new("Pause", self.color.fg, self.color.fg, self.width * 0.5, self.height * 0.6, 120, self.height * 0.09, gameControls.pause, function(key)
                setNewKey("pause", key)
            end),

            button.new("Back", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.8, self.width * 0.4, self.height * 0.09, changeScreen("options")),
        },
    }

    local y = 0.4
    for i, world in ipairs(fs.getDirectoryItems("worlds")) do
        if fs.getInfo("worlds/"..world).type == "directory" then
            -- World button
            self.screen.load[#self.screen.load+1] = button.new(
                world, 
                self.color.fg, 
                self.color.bg, 
                self.width * 0.35, 
                self.height * y, 
                self.width * 0.3, 
                self.height * 0.09, 
                function() 
                    gameName = world
                    state:load("game", {type = "load", worldName = world})
                end
            )
            -- Delete button for this world
            self.screen.load[#self.screen.load+1] = button.new(
                "X", 
                self.color.danger, 
                self.color.bg, 
                self.width * 0.66, 
                self.height * y, 
                self.width * 0.08, 
                self.height * 0.08, 
                function()
                    if not self.deleteConfirmed then
                        note:new("Warning: This will delete '"..world.."' PERMANENTLY. \nPress again to confirm.", "danger", 8)
                        self.deleteConfirmed = world
                    elseif self.deleteConfirmed == world then
                        removeDirectory("worlds/"..world)
                        self.selectedWorld = nil
                        note:new("World '"..world.."' deleted.", "success")
                        self:load()  -- Reload the menu to update the world list
                    else
                        self.deleteConfirmed = false
                    end
                end
            )
            y = y + 0.1
        end
    end

    load()
    self.deleteConfirmed = false
end

function updateSkinColours(colour1, colour2)
    colour2 = colour2 or colour1
   config.skinColour.colour = colour1
   config.skinColour.colour2 = colour2
    replaceShader:send("replacementColor", colour1)
    --replaceShader:send("replacementcolour2", colour2)
end

function menu:update(dt)
    self.titleOffset = self.titleAmplitude * math.sin(love.timer.getTime() * self.titleSpeed / self.titleAmplitude)
    cloudOffset = cloudOffset + cloudSpeed * dt
    colourPicker.update(dt)

    local selected = colourPicker.getSelectedColor()

    updateSkinColours({selected[1],selected[2],selected[3], 1.0}, {selected[1],selected[2],selected[3], 1.0})

    local skinNameSave = self.screen.skins.characterName.text
    config.settings.playerName = skinNameSave ~= "" and skinNameSave or "Pickle"

    for _, v in pairs(self.screen[self.currentScreen]) do
        if type(v.update) == "function" then
            v:update(dt)
        end
    end
end

function menu:drawCharacterEditor()
    -- Background for skin stuff
    local bgWidth = 500
    local bgHeight = 500
    local bgX = (self.width - bgWidth) / 2
    local bgY = (self.height - bgHeight) / 2

    -- Draw the darker outline layers to create a 3D effect
    lg.setColor(self.color.darker2)
    lg.rectangle("line", bgX - 5, bgY - 5, bgWidth + 10, bgHeight + 10, 5, 5)
    lg.setLineWidth(6)
    
    lg.setColor(self.color.darker1)
    lg.rectangle("line", bgX - 3, bgY - 3, bgWidth + 6, bgHeight + 6, 5, 5)
    lg.setLineWidth(4)

    -- Draw the centered background
    lg.setColor(self.color.success)
    lg.rectangle("fill", bgX, bgY, bgWidth, bgHeight)

    local scale = 7
    local spriteX = bgX - 150
    local spriteY = bgY + 20
    local spriteWidth = characterSprite:getWidth() * scale / 4
    local spriteHeight = characterSprite:getHeight() * scale

    -- Draw the outline around the character sprite
    lg.setColor(self.color.darker2)
    lg.rectangle("line", spriteX + spriteWidth + 45, spriteY - 5, spriteWidth + 10, spriteHeight + 10, 5, 5)
    lg.setColor(1, 1, 1)
    
    -- Draw the character sprite
    lg.setShader(replaceShader)
    lg.draw(characterSprite, spriteX, spriteY, 0, scale, scale)
    lg.setShader()

    if skinColourToggle then
        colourPicker.draw()
    end
end

function menu:draw()
    love.graphics.draw(nightSkyImage, 0, 0, 0, nightSkyImageScaleX, nightSkyImageScaleY)

    -- Draw clouds
    local cloudWidth = nightSkyCloudsImage:getWidth()
    local cloudHeight = nightSkyCloudsImage:getHeight()
    
    -- Draw the first part of the clouds
    love.graphics.draw(nightSkyCloudsImage, -cloudOffset, 0)
    
    -- Draw the second part of the clouds (to wrap around)
    love.graphics.draw(nightSkyCloudsImage, -cloudOffset + cloudWidth, 0)

    if self.currentScreen == "main" then
        self:drawCharacterPreview()
    elseif self.currentScreen == "skins" then
        self:drawCharacterEditor()
    end

    for i, v in pairs(self.screen[self.currentScreen]) do
        if i == 1 and self.currentScreen == "main" then
            v.y = lg.getHeight() * 0.2 + self.titleOffset
        end
        v:draw()
    end

end

function menu:textinput(t)
    for _, v in pairs(self.screen[self.currentScreen]) do
        if type(v.textinput) == "function" then
            v:textinput(t)
        end
    end
end

function menu:keypressed(key)
    for _, v in pairs(self.screen[self.currentScreen]) do
        if type(v.keypressed) == "function" then
            v:keypressed(key)
        end
    end
end

function menu:resize(w, h)
    self.width, self.height = w, h

    if nightSkyImage then
        nightSkyImageScaleX = w / nightSkyImage:getWidth()
        nightSkyImageScaleY = h / nightSkyImage:getHeight()
    end

    for screenName, screen in pairs(self.screen) do
        for _, element in pairs(screen) do
            if type(element) == "table" and type(element.resize) == "function" then
                element:resize(w, h)
            elseif type(element) == "table" and element.type == "button" then
                element.x = w * (element.x / self.width)
                element.y = h * (element.y / self.height)
                element.width = w * (element.width / self.width)
                element.height = h * (element.height / self.height)
            end
        end
    end

    -- Update positions and dimensions of skins
    if self.currentScreen == "skins" then
        local skinWidth = 600
        local skinHeight = 300
        local skinSpacing = 10
        local totalWidth = #skins * (skinWidth + skinSpacing) - skinSpacing
        local startX = (w - totalWidth) / 2
        local startY = (h - skinHeight) / 2

        for i, skin in ipairs(skins) do
            local x = startX + (i - 1) * (skinWidth + skinSpacing)
            local y = startY

            skin.x = x
            skin.y = y
            skin.width = skinWidth
            skin.height = skinHeight
        end
    end
end

function menu:mousepressed(x, y, button)
    if self.currentScreen == "skins" then
        local screenWidth = love.graphics.getWidth()
        local screenHeight = love.graphics.getHeight()
        local rectX = 200
        local rectWidth = screenWidth - 400
        local rectHeight = 400
        local startY = (screenHeight - rectHeight) / 2

        -- Check left arrow
        if x < rectX and y > startY and y < startY + rectHeight then
            self:prevSkin()
        end

        -- Check right arrow
        if x > rectX + rectWidth and y > startY and y < startY + rectHeight then
            self:nextSkin()
        end

        -- Check "Select" button
        local buttonWidth = 150
        local buttonHeight = 50
        local buttonX = screenWidth / 2 - buttonWidth / 2
        local buttonY = startY + rectHeight + 20
        if x > buttonX and x < buttonX + buttonWidth and y > buttonY and y < buttonY + buttonHeight then
            self:selectCurrentSkin()
        end
    end

    -- Existing mousepressed logic
    for _, v in pairs(self.screen[self.currentScreen]) do
        if type(v.mousepressed) == "function" then
            v:mousepressed(x, y, button)
        end
    end
end

function menu:mousereleased(x, y, button, istouch, presses)
    for _, v in pairs(self.screen[self.currentScreen]) do
        if type(v.mousereleased) == "function" then
            v:mousereleased(x, y, button, istouch, presses)
        end
    end
end

function menu:mousemoved(x, y, dx, dy)
    for _, v in pairs(self.screen[self.currentScreen]) do
        if type(v.mousemoved) == "function" then
            v:mousemoved(x, y, dx, dy)
        end
    end
end

return menu