local slider = {}
local slider_meta = {__index = slider}

function slider.new(label, min, max, value, x, y, width, height, color, handleColor, onValueChange)
    return setmetatable({
        min = min,
        max = max,
        value = value,
        x = x,
        y = y,
        width = width,
        height = height,
        color = color,
        handleColor = handleColor,
        label = label,
        dragging = false,
        onValueChange = onValueChange 
    }, slider_meta)
end

function slider:getValue()
    return self.value or 0
end

function slider:setValue(value)
    if value == nil then
        value = self.min or 0
    end
    self.value = math.min(math.max(value, self.min), self.max)
end

function slider:mouseOver()
    local mx, my = love.mouse.getPosition()
    return mx >= self.x and mx <= self.x + self.width and my >= self.y and my <= self.y + self.height
end

function slider:mousepressed(x, y, button)
    if button == 1 and self:mouseOver() then
        self.dragging = true
        self:updateValue(x)
    end
end

function slider:mousereleased(x, y, button, istouch, presses)
    if button == 1 then
        self.dragging = false
    end
end

function slider:mousemoved(x, y, dx, dy)
    if self.dragging then
        self:updateValue(x)
    end
end

function slider:updateValue(x)
    local value = (x - self.x) / self.width
    value = value * (self.max - self.min) + self.min
    local oldValue = self.value
    self:setValue(value)
    if self.value ~= oldValue and self.onValueChange then
        self.onValueChange(self.value)
    end
end

function slider:drawLabel()
    local font = love.graphics.getFont()
    local labelWidth = font:getWidth(self.label)
    local labelHeight = font:getHeight()
    local labelX = self.x + (self.width - labelWidth) / 2
    local labelY = self.y - labelHeight - 5
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(self.label, labelX, labelY)
end

function slider:draw()
    -- Draw slider track
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y + (self.height - 4) / 2, self.width, 4)

    -- Draw slider handle
    local handleWidth = 16
    local handleHeight = self.height
    local handleX = self.x + (self.value - self.min) / (self.max - self.min) * (self.width - handleWidth)
    local handleY = self.y

    love.graphics.setColor(self.handleColor)
    love.graphics.rectangle("fill", handleX, handleY, handleWidth, handleHeight)

   -- print("test slider")

    -- Draw label
    self:drawLabel()
end

return slider