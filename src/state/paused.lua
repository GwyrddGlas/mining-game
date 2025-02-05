local pauseScreen = {
    width = 0,
    height = 0,
    color = {
        fg = {1, 1, 1},
        bg = {0, 0, 0},
        success = {223/255, 147/255, 95/255},
    },
}

local nightSkyImage
local nightSkyImageScaleX
local nightSkyImageScaleY

function pauseScreen:load()
    self.width, self.height = love.graphics.getDimensions()

    nightSkyImage = love.graphics.newImage("src/assets/background.png")
    nightSkyImageScaleX = love.graphics.getWidth() / nightSkyImage:getWidth()
    nightSkyImageScaleY = love.graphics.getHeight() / nightSkyImage:getHeight()
    
    local buttonData = {
        {text = "Resume", action = function() self:resume() end},
        {text = "Main Menu", action = function() self:returnToMainMenu() end},
        {text = "Settings", action = function() self:returnToSettingsMenu() end},
        {text = "Quit Game", action = function() love.event.quit() end},
    }
    
    self.elements = {
        label.new("Paused", self.color.fg, font.title, 0, self.height * 0.2, "center")
    }

    for i, data in ipairs(buttonData) do
        table.insert(self.elements, button.new(data.text, self.color.fg, self.color.fg,
            self.width * 0.3, self.height * (0.3 + i * 0.1), self.width * 0.4, self.height * 0.09, data.action))
    end
end

function pauseScreen:update(dt)
    for _, element in ipairs(self.elements) do
        if type(element.update) == "function" then
            element:update(dt)
        end
    end
end

function pauseScreen:draw()
    love.graphics.draw(nightSkyImage, 0, 0, 0, nightSkyImageScaleX, nightSkyImageScaleY)

    -- Draw all elements
    for _, element in ipairs(self.elements) do
        element:draw()
    end
end

function pauseScreen:keypressed(key)
    if key == "escape" then
        self:resume()
    end

    for _, element in ipairs(self.elements) do
        if type(element.keypressed) == "function" then
            element:keypressed(key)
        end
    end
end

function pauseScreen:mousepressed(x, y, button)
    for _, element in ipairs(self.elements) do
        if type(element.mousepressed) == "function" then
            element:mousepressed(x, y, button)
        end
    end
end

function pauseScreen:mousereleased(x, y, button)
    for _, element in ipairs(self.elements) do
        if type(element.mousereleased) == "function" then
            element:mousereleased(x, y, button)
        end
    end
end

function pauseScreen:resize(w, h)
    self.width, self.height = w, h
    
    -- Update positions of elements
    self.elements[1].y = h * 0.2
    for i = 2, #self.elements do
        local element = self.elements[i]
        element.x = w * 0.3
        element.y = h * (0.3 + (i-1) * 0.1)
        element.width = w * 0.4
        element.height = h * 0.09
    end

    if nightSkyImage then
        nightSkyImageScaleX = w / nightSkyImage:getWidth()
        nightSkyImageScaleY = h / nightSkyImage:getHeight()
    end
end

function pauseScreen:resume()
    state:resume_previous_state()
end

function pauseScreen:returnToMainMenu()
    state:load("menu")
end

function pauseScreen:returnToSettingsMenu()
    state:load("menu", {initialScreen = "options"})
end

return pauseScreen