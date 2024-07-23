local keybox = {}
local keybox_meta = {__index = keybox}

function keybox.new(text, color, textColor, x, y, width, height, initialKey, func)
    return setmetatable({
        text = text,
        color = color,
        textColor = textColor,
        x = x,
        y = y,
        width = width,
        height = height,
        func = func,
        scale = 1,
        targetScale = 1,
        isHovered = false,
        wasHovered = false,
        isClicked = false,
        isActive = false,
        key = initialKey or ""
    }, keybox_meta)
end

function keybox:mouseOver()
    local mx, my = love.mouse.getPosition()
    return mx > self.x and mx < self.x + self.width and my > self.y and my < self.y + self.height
end

function keybox:update(dt)
    self.wasHovered = self.isHovered
    self.isHovered = self:mouseOver()
    
    if self.isHovered then
        self.targetScale = 1.05
    else
        self.targetScale = 1
    end
    
    if self.isClicked then
        self.targetScale = 0.95
    end
    
    self.scale = self.scale + (self.targetScale - self.scale) * 10 * dt
end

function keybox:draw()
    local centerX, centerY = self.x + self.width/2, self.y + self.height/2
    local scaledWidth, scaledHeight = self.width * self.scale, self.height * self.scale
    local drawX, drawY = centerX - scaledWidth/2, centerY - scaledHeight/2

    lg.push()
    lg.translate(centerX, centerY)
    lg.scale(self.scale)
    lg.translate(-centerX, -centerY)

    -- Draw text (to the left of the box)
    lg.setColor(self.textColor)
    local font = lg.getFont()
    local textY = self.y + (self.height / 2) - ((font:getAscent() - font:getDescent()) / 2)
    lg.printf(self.text, self.x - 200, textY, 190, "right")  -- Adjust the 200 and 190 values as needed

    -- Draw keybox
    lg.setColor(self.color)
    lg.rectangle("line", drawX, drawY, scaledWidth, scaledHeight)

    -- Draw key
    lg.setColor(self.textColor)
    local keyText = self.isActive and "Press a key..." or self.key
    lg.printf(keyText, drawX, textY, scaledWidth, "center")

    lg.pop()
end

function keybox:mousepressed(x, y, button)
    if button == 1 and self:mouseOver() then
        self.isClicked = true
        self.isActive = true
    end
end

function keybox:mousereleased(x, y, button)
    if button == 1 then
        self.isClicked = false
    end
end

function keybox:keypressed(key)
    if self.isActive then
        self.key = key
        self.isActive = false
        if type(self.func) == "function" then
            self.func(self.key)
        end
    end
end

return keybox