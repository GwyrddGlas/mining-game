local colourPicker = require("src.lib.colourPicker")
local network = require("src.class.network")

local lg = love.graphics
local fs = love.filesystem
local kb = love.keyboard
local lm = love.mouse
local lt = love.thread


local menu = {
    selectedWorld = nil,
    currentScreen = nil,
    previousScreen = nil,
    screenHistory = {},
    titleOffset = 0,
    titleSpeed = 20,  
    titleAmplitude = 10,
    skinOffset = 0
}

local logo
local nightSkyImage
local nightSkyImageScaleX, nightSkyImageScaleY
local cloudSpeed = 11
local cloudOffset = 0
local skinColourToggle = false
local backgroundShader = love.graphics.newShader("src/lib/poster/shaders/background.frag")

function changeScreen(screen)
    return function()
        if not menu.screen[screen] then
            note:new("Error: Screen '" .. tostring(screen) .. "' does not exist!")
            return
        end

        table.insert(menu.screenHistory, menu.currentScreen)
        menu.currentScreen = screen
    end
end

function createButton(text, xPercent, yPercent, widthPercent, heightPercent, action)
    return button.new(
        text, 
        menu.color.white, 
        menu.color.white, 
        menu.width * (xPercent / 100), 
        menu.height * (yPercent / 100), 
        menu.width * (widthPercent / 100), 
        menu.height * (heightPercent / 100), 
        action
    )
end

function revertScreen()
    return function()
        if #menu.screenHistory > 0 then
            menu.currentScreen = table.remove(menu.screenHistory)
        else
            menu.currentScreen = "main"
        end
    end
end

local function exitButton()
    love.event.push("quit")
end

local skins = {}
local selectedSkin = "default"
local picker
local characterSprite

local function loadSkins()
    -- Release existing resources
    if nightSkyImage then nightSkyImage:release() end
    if characterSprite then characterSprite:release() end

    -- Load new resources
    nightSkyImage = love.graphics.newImage("src/assets/background.png")
    nightSkyImageScaleX = love.graphics.getWidth() / nightSkyImage:getWidth()
    nightSkyImageScaleY = love.graphics.getHeight() / nightSkyImage:getHeight()

    -- Load skins
    local skinAnimations = {
        default = {skin = "src/assets/player/skin.png"},
        skin1 = {skin = "src/assets/player/skinBlue.png"}
    }
    skins = {
        {name = "default", path = skinAnimations.default.skin, id = nil},
        {name = "skin1", path = skinAnimations.skin1.skin, id = nil}
    }

    for _, v in ipairs(skins) do
        v.id = love.graphics.newImage(v.path)
    end

    characterSprite = love.graphics.newImage("src/assets/player/skin.png")
end

local function load()
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


local function hostHame()
    local port = menu.screen.host.port.text
    network.host(port)
    note:new("Server hosted on "..tostring(port))
end

local function joinHame()
    local port = menu.screen.join.joinPort.text
    local IP = menu.screen.join.IP.text

    -- Validate IP and port
    if IP == "" or port == "" then
        note:new("Please enter a valid IP and port.", "danger")
        return
    end

    -- Attempt to join the server
    local success, err = pcall(function()
        network.join(IP, port)
    end)

    if success then
        note:new("Connected to server at " .. IP .. ":" .. port, "success")
       
       
       -- state:load("game", {type = "multiplayer", IP = IP, port = port})
    else
        note:new("Failed to connect to server: " .. tostring(err), "danger")
    end
end

function menu:getSelectedTextbox(screen)
    for i, v in ipairs(self.screen[screen]) do
        if v.type == "textbox" and v.selected then
            return v, i
        end
    end
    return nil
end

function menu:load(args)
    args = args or {} 
    self.currentScreen = args.initialScreen or "main"
    love.keyboard.setTextInput(true)

    lg.setBackgroundColor(0.1, 0.1, 0.1)
    self.width, self.height = lg.getWidth(), lg.getHeight()
    self.color = {
        fg = {1.000, 0.722, 0.0},
        white = {1, 1, 1},
        bg = {0, 0, 0},
        idle = {0.4, 0.4, 0.4},
        danger = {0.8, 0.2, 0.2},
        success = {223/255, 147/255, 95/255},
        darker1 = {200.7/255, 132.3/255, 85.5/255},
        darker2 = {180/255, 119/255, 76.5/255} 
    }  

    local mainMenu = require("src.state.menus.MainMenu")
    local singleplayerMenu = require("src.state.menus.SingleplayerMenu")
    local multiplayerMenu = require("src.state.menus.MultiplayerMenu")
    local optionsMenu = require("src.state.menus.OptionsMenu")
    local graphicsMenu = require("src.state.menus.GraphicsMenu")
    local newWorld = require("src.state.menus.NewWorld")
    local selectWorld = require("src.state.menus.SelectWorld")
    local hostMenu = require("src.state.menus.HostMenu")
    local joinMenu = require("src.state.menus.JoinMenu")
    local soundMenu = require("src.state.menus.SoundMenu")
    local controlsMenu = require("src.state.menus.ControlsMenu")
    local debugMenu = require("src.state.menus.DebugMenu")
    local skinsMenu = require("src.state.menus.SkinsMenu")

    self.screen = {
        main = mainMenu(self),
        load = selectWorld(self),
        new = newWorld(self), 
        singleplayer = singleplayerMenu(self),
        multiplayer = multiplayerMenu(self),
        host = hostMenu(self),
        join = joinMenu(self),
        options = optionsMenu(self),
        graphics = graphicsMenu(self),
        sounds = soundMenu(self),
        controls = controlsMenu(self),
        debug = debugMenu(self),
        skins = skinsMenu(self)
    }

    local y = 0.4
    for i, world in ipairs(fs.getDirectoryItems("worlds")) do
        if fs.getInfo("worlds/"..world).type == "directory" then
            -- World button
            self.screen.load[#self.screen.load+1] = button.new(
                world, 
                self.color.white, 
                self.color.white, 
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

local time = 0
function menu:update(dt)
    self.titleOffset = self.titleAmplitude * math.sin(love.timer.getTime() * self.titleSpeed / self.titleAmplitude)
    cloudOffset = cloudOffset + cloudSpeed * dt
    colourPicker.update(dt)

    time = time + dt/10

    backgroundShader:send("time", time)           
    backgroundShader:send("contrast", 1.5)  
    backgroundShader:send("colour_1", {0, 0, 0, 1.0})
    backgroundShader:send("colour_2", {0, 0, 0, 1.0})
    backgroundShader:send("colour_3", {0.7, 0.5, 0.9, 0.7})


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
    lg.setShader(backgroundShader)

    love.graphics.draw(nightSkyImage, 0, 0, 0, nightSkyImageScaleX, nightSkyImageScaleY)  
    lg.setShader()
    
    if self.currentScreen == "skins" then
        self:drawCharacterEditor()
    end

    for i, v in pairs(self.screen[self.currentScreen]) do
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