local button = {}
local button_meta = {__index = button}

local hoverSound = love.audio.newSource("src/assets/audio/button-hover.wav", "static")

function button.new(text, color, textColor, x, y, width, height, func)
    return setmetatable({
        text = text,
        color = color,
        textColor = textColor,
        x = x,
        y = y,
        width = width,
        height = height,
        func = func,
        buttonLeft = tiles[57],
        buttonCenter = tiles[58],
        buttonRight = tiles[59],
        scale = 1,
        targetScale = 1,
        isHovered = false,
        wasHovered = false,  
        isClicked = false
    }, button_meta)
end

function button:mouseOver()
    local mx, my = love.mouse.getPosition()
    return mx > self.x and mx < self.x + self.width and my > self.y and my < self.y + self.height or false
end

function button:update(dt)
    self.wasHovered = self.isHovered  -- Store the previous hover state
    self.isHovered = self:mouseOver()
    
    if self.isHovered then
        self.targetScale = 1.05
        if not self.wasHovered then
            hoverSound:stop()  -- Stop any currently playing instance
            hoverSound:play()
        end
    else
        self.targetScale = 1
    end
    
    if self.isClicked then
        self.targetScale = 0.95
    end
    
    self.scale = self.scale + (self.targetScale - self.scale) * 10 * dt
end

function button:draw()
    local centerX, centerY = self.x + self.width/2, self.y + self.height/2
    local scaledWidth, scaledHeight = self.width * self.scale, self.height * self.scale
    local drawX, drawY = centerX - scaledWidth/2, centerY - scaledHeight/2

    lg.push()
    lg.translate(centerX, centerY)
    lg.scale(self.scale)
    lg.translate(-centerX, -centerY)

    lg.setColor(self.color)
    -- Left
    lg.draw(tileAtlas, self.buttonLeft, self.x, self.y, 0, self.height / config.graphics.assetSize, self.height / config.graphics.assetSize)

    -- Center
    lg.draw(tileAtlas, self.buttonCenter, self.x + self.height, self.y, 0, (self.width - (self.height * 2)) / config.graphics.assetSize, self.height / config.graphics.assetSize)

    -- Right
    lg.draw(tileAtlas, self.buttonRight, self.x + self.width - self.height, self.y, 0, self.height / config.graphics.assetSize, self.height / config.graphics.assetSize)

    -- Text
    lg.setColor(self.textColor)
    local font = lg.getFont()
    local y = self.y + (self.height / 2) - ((font:getAscent() - font:getDescent()) / 2)
    lg.printf(self.text, self.x, y, self.width, "center")

    lg.pop()
end

function button:mousepressed(x, y, k)
    if k == 1 and self:mouseOver() then
        self.isClicked = true
        if type(self.func) == "function" then
            self.func(self)
            hoverSound:stop()  -- Stop any currently playing instance
            hoverSound:play()
        end
    end
end

function button:mousereleased(x, y, k)
    if k == 1 then
        self.isClicked = false
    end
end

return button