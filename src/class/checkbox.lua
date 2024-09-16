local checkbox = {}
local checkbox_meta = {__index = checkbox}

local lg = love.graphics
local fs = love.filesystem
local kb = love.keyboard
local lm = love.mouse
local lt = love.thread

local checkSound = love.audio.newSource("src/assets/audio/button-hover.wav", "static")

function checkbox.new(text, color, textColor, x, y, width, height, initialState, func)
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
        isChecked = initialState or false
    }, checkbox_meta)
end

function checkbox:mouseOver()
    local mx, my = love.mouse.getPosition()
    return mx > self.x and mx < self.x + self.height and my > self.y and my < self.y + self.height or false
end

function checkbox:update(dt)
    self.wasHovered = self.isHovered
    self.isHovered = self:mouseOver()
    
    if self.isHovered then
        self.targetScale = 1.05
        if not self.wasHovered then
            checkSound:stop()
            checkSound:play()
        end
    else
        self.targetScale = 1
    end
    
    if self.isClicked then
        self.targetScale = 0.95
    end
    
    self.scale = self.scale + (self.targetScale - self.scale) * 10 * dt
end

function checkbox:draw()
    local centerX, centerY = self.x + self.height/2, self.y + self.height/2
    local scaledSize = self.height * self.scale
    local drawX, drawY = centerX - scaledSize/2, centerY - scaledSize/2

    lg.push()
    lg.translate(centerX, centerY)
    lg.scale(self.scale)
    lg.translate(-centerX, -centerY)

    -- Draw checkbox
    lg.setColor(self.color)
    lg.rectangle("line", drawX, drawY, scaledSize, scaledSize)

    if self.isChecked then
        -- Draw check mark
        lg.setLineWidth(2)
        local padding = scaledSize * 0.2
        lg.line(drawX + padding, drawY + scaledSize/2, 
                drawX + scaledSize/2, drawY + scaledSize - padding,
                drawX + scaledSize - padding, drawY + padding)
        lg.setLineWidth(1)
    end

    -- Text
    lg.setColor(self.textColor)
    local font = lg.getFont()
    local textY = self.y + (self.height / 2) - ((font:getAscent() - font:getDescent()) / 2)
    lg.printf(self.text, self.x + self.height + 10, textY, self.width - self.height - 10, "left")

    lg.pop()
end

function checkbox:mousepressed(x, y, k)
    if k == 1 and self:mouseOver() then
        self.isClicked = true
        self.isChecked = not self.isChecked
        checkSound:stop()
        checkSound:play()
        if type(self.func) == "function" then
            self.func(self.isChecked)
        end
    end
end

function checkbox:mousereleased(x, y, k)
    if k == 1 then
        self.isClicked = false
    end
end

return checkbox