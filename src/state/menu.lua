local menu = {}

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

local function loadSkins()
    local skinAnimations = _PLAYER.skinAnimations
    skins = {
        {name = "default", path = skinAnimations.default.skin, id = nil},
        {name = "skin1", path = skinAnimations.skin1.skin, id = nil}
    }

    for _, v in ipairs(skins) do
        v.id = love.graphics.newImage(v.path)
    end
end

local function selectSkin(skinName)
    selectedSkin = skinName
end


local function load()
    local selected = menu:getSelectedTextbox("load")
    if selected then
        state:load("game", {type = "load", worldName = selected.text})
    end

    if _PLAYER then
        loadSkins()
    end
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

local function delete()
    local selected, selectedIndex = menu:getSelectedTextbox("load")
    if selected then
        if not menu.deleteConfirmed then
            note:new("Warning: This will delete the world PERMANENTLY. This is your only warning", "danger", 8)
            menu.deleteConfirmed = true
        else
            removeDirectory("worlds/"..selected.text)
            menu.screen.load[selectedIndex] = nil
            note:new("World '"..selected.text.."' deleted.", "success")
        end
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

local function drawSkins()
    local skinWidth = 600
    local skinHeight = 300
    local skinSpacing = 20
    local totalWidth = #skins * (skinWidth + skinSpacing) - skinSpacing
    local startX = (love.graphics.getWidth() - totalWidth) / 2
    local startY = (love.graphics.getHeight() - skinHeight) / 2

    for i, skin in ipairs(skins) do
        local x = startX + (i - 1) * (skinWidth + skinSpacing)
        local y = startY
        
        -- Adjust the outline rectangle to be less wide
        local outlineWidth = skinWidth / 2

        if skin.name == selectedSkin then
            love.graphics.setColor(1, 1, 0) -- Yellow outline for selected skin
            love.graphics.rectangle("line", x + (skinWidth - outlineWidth) / 2, y - 5, outlineWidth, skinHeight + 10)
        end

        love.graphics.setColor(1, 1, 1)
        -- Adjust the position to center the sprite
        local spriteScaleX = skinWidth / skin.id:getWidth()
        local spriteScaleY = skinHeight / skin.id:getHeight()
        local spriteX = x + (skinWidth - (spriteScaleX * skin.id:getWidth())) / 2
        local spriteY = y + (skinHeight - (spriteScaleY * skin.id:getHeight())) / 2
        love.graphics.draw(skin.id, spriteX, spriteY, 0, spriteScaleX, spriteScaleY)

        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(font.regular)
        local skinNameWidth = font.regular:getWidth(skin.name)
        love.graphics.print(skin.name, x + (skinWidth - skinNameWidth) / 2, y + skinHeight + 10)

        if love.mouse.isDown(1) then
            local mouseX, mouseY = love.mouse.getPosition()
            if mouseX >= x and mouseX <= x + skinWidth and mouseY >= y and mouseY <= y + skinHeight then
                selectSkin(skin.name)
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
        success = {0.4, 0.9, 0.4}
    }

    self.currentScreen = "main"
    self.screen = {
        main = {
            label.new(NAME, self.color.success, font.large, 0, lg.getHeight() * 0.2, "center"),
            label.new(VERSION, self.color.success, font.regular, 12, 12, "left"),
            button.new("Singleplayer", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.4, self.width * 0.4, self.height * 0.09, changeScreen("singleplayer")),
            button.new("Multiplayer", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.5, self.width * 0.4, self.height * 0.09, changeScreen("multiplayer")),
            button.new("Skins", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.6, self.width * 0.4, self.height * 0.09, changeScreen("skins")),
            --button.new("Mods", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.6, self.width * 0.4, self.height * 0.09, changeScreen("skins")),
            button.new("Options", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.7, self.width * 0.4, self.height * 0.09, changeScreen("options")),
            button.new("Quit Game", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.8, self.width * 0.4, self.height * 0.09, exitButton),
        },
        singleplayer = {
            label.new("Singleplayer", self.color.success, font.large, 0, lg.getHeight() * 0.2, "center"),
            button.new("New world", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.4, self.width * 0.4, self.height * 0.09, changeScreen("new")),
            button.new("Load world", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.5, self.width * 0.4, self.height * 0.09, changeScreen("load")),
        },
        multiplayer = {
            label.new("Multiplayer", self.color.success, font.large, 0, lg.getHeight() * 0.2, "center"),

        },
        options = {
            label.new("Options", self.color.success, font.large, 0, lg.getHeight() * 0.2, "center"),
            button.new("Sounds", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.4, self.width * 0.4, self.height * 0.09, changeScreen("sounds")),
            button.new("Graphics", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.5, self.width * 0.4, self.height * 0.09, changeScreen("graphics")),
            button.new("Back", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.6, self.width * 0.4, self.height * 0.09, changeScreen("main")),
        },
        skins = {
            label.new("Skins", self.color.success, font.large, 0, lg.getHeight() * 0.2, "center"),
            button.new("Back", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.8, self.width * 0.4, self.height * 0.09, changeScreen("options")),
        },
        sounds = { --setting up for later
            label.new("Sound Settings", self.color.success, font.large, 0, lg.getHeight() * 0.2, "center"),
            --slider.new("Master Volume", 0, 100, sound.volume.master, self.width * 0.3, self.height * 0.3, self.width * 0.4, self.height * 0.05, {0.4, 0.4, 0.4}, {1, 1, 1}, function(value) sound.volume.master = value / 100 end),
            --slider.new("Music Volume", 0, 100, sound.volume.music, self.width * 0.3, self.height * 0.35, self.width * 0.4, self.height * 0.05, {0.4, 0.4, 0.4}, {1, 1, 1}, function(value) sound.volume.music = value / 100 end),
            --slider.new("SFX Volume", 0, 100, sound.volume.sfx, self.width * 0.3, self.height * 0.4, self.width * 0.4, self.height * 0.05, {0.4, 0.4, 0.4}, {1, 1, 1}, function(value) sound.volume.sfx = value / 100 end),
            --checkbox.new("Enable Music", self.width * 0.3, self.height * 0.45, self.width * 0.4, self.height * 0.05, {0.4, 0.4, 0.4}, {1, 1, 1}, sound.enableMusic, function(value) sound.enableMusic = value end),
            --checkbox.new("Enable SFX", self.width * 0.3, self.height * 0.5, self.width * 0.4, self.height * 0.05, {0.4, 0.4, 0.4}, {1, 1, 1}, sound.enableSFX, function(value) sound.enableSFX = value end),
            button.new("Back", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.8, self.width * 0.4, self.height * 0.09, changeScreen("options")),
        },
        graphics = {
            label.new("Graphics Settings", self.color.success, font.large, 0, lg.getHeight() * 0.2, "center"),
            --checkbox.new("Use Light", self.width * 0.3, self.height * 0.3, self.width * 0.4, self.height * 0.05, {0.4, 0.4, 0.4}, {1, 1, 1}, window.graphics.useLight, function(value) window.graphics.useLight = value end),
            --checkbox.new("Use Shaders", self.width * 0.3, self.height * 0.35, self.width * 0.4, self.height * 0.05, {0.4, 0.4, 0.4}, {1, 1, 1}, window.graphics.useShaders, function(value) window.graphics.useShaders = value end),
            --slider.new("Bloom", 0, 1, window.graphics.bloom, self.width * 0.3, self.height * 0.4, self.width * 0.4, self.height * 0.05, {0.4, 0.4, 0.4}, {1, 1, 1}, function(value) window.graphics.bloom = value end),
            --slider.new("Light Distance", 0, 1000, window.graphics.lightDistance, self.width * 0.3, self.height * 0.45, self.width * 0.4, self.height * 0.05, {0.4, 0.4, 0.4}, {1, 1, 1}, function(value) window.graphics.lightDistance = value end),
            --slider.new("Ambient Light", 0, 1, window.graphics.ambientLight, self.width * 0.3, self.height * 0.5, self.width * 0.4, self.height * 0.05, {0.4, 0.4, 0.4}, {1, 1, 1}, function(value) window.graphics.ambientLight = value end),
            --colorpicker.new("Light Color", window.graphics.lightColor, self.width * 0.3, self.height * 0.55, self.width * 0.4, self.height * 0.05, {0.4, 0.4, 0.4}, {1, 1, 1}, function(r, g, b) window.graphics.lightColor = {r, g, b} end),
            button.new("Back", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.8, self.width * 0.4, self.height * 0.09, changeScreen("options")),
        },
        new = {
            label.new("New world", self.color.success, font.large, 0, lg.getHeight() * 0.2, "center"),
            worldName = textbox.new("", "World name", self.color.fg, self.color.idle, self.color.bg, self.width * 0.3, self.height * 0.5, self.width * 0.4, self.height * 0.09),
            seed = textbox.new("", "Seed", self.color.fg, self.color.idle, self.color.bg, self.width * 0.3, self.height * 0.6, self.width * 0.4, self.height * 0.09, false, 10),
            button.new("Create world", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.7, self.width * 0.4, self.height * 0.09, createButton),
            button.new("Back", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.8, self.width * 0.4, self.height * 0.09, changeScreen("main")),
        },
        load = {
            label.new("Load world", self.color.success, font.large, lg.getWidth() * 0.05, lg.getHeight() * 0.2, "left"),
            button.new("Load world", self.color.success, self.color.bg, self.width * 0.05, self.height * 0.6, self.width * 0.25, self.height * 0.09, load),
            button.new("Delete world", self.color.danger, self.color.bg, self.width * 0.05, self.height * 0.7, self.width * 0.25, self.height * 0.09, delete),
            button.new("Back", self.color.fg, self.color.bg, self.width * 0.05, self.height * 0.8, self.width * 0.25, self.height * 0.09, changeScreen("main")),
        }
    }

    local y = 0.1
    for i, world in ipairs(fs.getDirectoryItems("worlds")) do
        if fs.getInfo("worlds/"..world).type == "directory" then
            self.screen.load[#self.screen.load+1] = textbox.new(world, world, self.color.fg, self.color.idle, self.color.bg, self.width * 0.35, self.height * y, self.width * 0.5, self.height * 0.09, function() return false end)
            y = y + 0.1
        end
    end

    load()
    self.deleteConfirmed = false
end

function menu:update(dt)
    if self.currentScreen == "skins" and not _PLAYER then
        self.currentScreen = "main"
        note:new("Warning: You must load ingame first.", "danger", 8)
        return 
    end

    for _, v in pairs(self.screen[self.currentScreen]) do
        if type(v.update) == "function" then
            v:update(dt)
        end
    end
end

function menu:draw()
    for _, v in pairs(self.screen[self.currentScreen]) do
        v:draw()
    end

    if self.currentScreen == "skins" then
        drawSkins()
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

    -- Update positions and dimensions of menu elements
    for _, screen in pairs(self.screen) do
        for _, element in pairs(screen) do
            if type(element) == "table" and type(element.resize) == "function" then
                element:resize(w, h)
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

function menu:mousepressed(x, y, k)
    for _, v in pairs(self.screen[self.currentScreen]) do
        if type(v.mousepressed) == "function" then
            v:mousepressed(x, y, k)
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