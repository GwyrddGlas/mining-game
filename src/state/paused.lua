local pauseScreen = {
    width = 0,
    height = 0,
    color = {
        fg = {1, 1, 1},
        bg = {0, 0, 0},
        success = {223/255, 147/255, 95/255},
    }
}

function pauseScreen:load()
    self.width, self.height = love.graphics.getDimensions()
    
    self.elements = {
        label.new("Paused", self.color.success, font.title, 0, self.height * 0.2, "center"),
        button.new("Resume", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.4, self.width * 0.4, self.height * 0.09, function() self:resume() end),
        button.new("Settings", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.5, self.width * 0.4, self.height * 0.09, function() self:openSettings() end),
        button.new("Main Menu", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.6, self.width * 0.4, self.height * 0.09, function() self:returnToMainMenu() end),
        button.new("Quit Game", self.color.fg, self.color.bg, self.width * 0.3, self.height * 0.7, self.width * 0.4, self.height * 0.09, function() love.event.quit() end),
    }
end

function pauseScreen:update(dt)
    for _, element in ipairs(self.elements) do
        if type(element.update) == "function" then
            element:update(dt)
        end
    end
end

function pauseScreen:draw()
    -- Draw a semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)

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
end

function pauseScreen:resume()
    state:load("menu", {worldName = gameName})
end

function pauseScreen:openSettings()
    -- Implement your settings screen logic here
    print("Opening settings")
end

function pauseScreen:returnToMainMenu()
    state:load("menu")
end

return pauseScreen