local slider = {}
local slider_meta = {__index = slider}

-- Helper function to validate numeric values
local function validateNumber(value, name, default)
    if type(value) ~= "number" or value ~= value then -- Check for NaN
        print(string.format("Warning: Invalid %s. Using default value: %d", name, default))
        return default
    end
    return value
end

-- Helper function to validate color tables
local function validateColor(color, name, default)
    if type(color) ~= "table" or #color < 3 or #color > 4 then
        print(string.format("Warning: Invalid %s. Using default color: {1, 1, 1, 1}", name))
        return default
    end
    return color
end

function slider.new(label, min, max, value, x, y, width, height, color, handleColor, onValueChange)
    -- Validate inputs
    min = validateNumber(min, "min", 0)
    max = validateNumber(max, "max", 100)
    value = validateNumber(value, "value", min)
    x = validateNumber(x, "x", 0)
    y = validateNumber(y, "y", 0)
    width = validateNumber(width, "width", 200)
    height = validateNumber(height, "height", 40)
    color = validateColor(color, "color", {0.5, 0.5, 0.5, 1})
    handleColor = validateColor(handleColor, "handleColor", {1, 1, 1, 1})

    if min > max then
        print("Warning: min > max. Swapping min and max values.")
        min, max = max, min
    end
    value = math.min(math.max(value, min), max)

    if onValueChange and type(onValueChange) ~= "function" then
        print("Warning: onValueChange is not a function. Setting to nil.")
        onValueChange = nil
    end

    return setmetatable({
        min = min,
        max = max,
        value = value,
        x = x,
        y = y,
        buttonLeft = tiles[57],  
        buttonCenter = tiles[58],
        buttonRight = tiles[59], 
        width = width,
        height = height,
        color = color,
        handleColor = handleColor,
        label = label or "Slider",
        dragging = false,
        onValueChange = onValueChange
    }, slider_meta)
end

function slider:getValue()
    return self.value or self.min
end

function slider:setValue(value)
    if value == nil then
        value = self.min
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
    if x < self.x then
        x = self.x
    elseif x > self.x + self.width then
        x = self.x + self.width
    end

    local value = (x - self.x) / self.width
    value = value * (self.max - self.min) + self.min
    local oldValue = self.value
    self:setValue(value)

    if self.value ~= oldValue and self.onValueChange then
        self.onValueChange(self.value)
    end
end

function slider:draw()
    local lg = love.graphics

    lg.setColor(self.color)
    lg.draw(tileAtlas, self.buttonLeft, self.x, self.y, 0, self.height / config.graphics.assetSize, self.height / config.graphics.assetSize)

    lg.draw(tileAtlas, self.buttonCenter, self.x + self.height, self.y, 0, (self.width - (self.height * 2)) / config.graphics.assetSize, self.height / config.graphics.assetSize)

    lg.draw(tileAtlas, self.buttonRight, self.x + self.width - self.height, self.y, 0, self.height / config.graphics.assetSize, self.height / config.graphics.assetSize)

    -- Draw slider handle
    local handleWidth = 16
    local handleHeight = self.height - 10
    local handleX = self.x + (self.value - self.min) / (self.max - self.min) * (self.width - handleWidth)
    local handleY = self.y + (self.height - handleHeight) / 2

    lg.setColor(self.handleColor)
    lg.rectangle("fill", handleX, handleY, handleWidth, handleHeight, 2, 2)

    local font = lg.getFont()
    if font then
        local labelWidth = font:getWidth(self.label)
        local labelHeight = font:getHeight()
        local labelX = self.x + (self.width - labelWidth) / 2
        local labelY = self.y + (self.height - labelHeight) / 2

        lg.setColor(1, 1, 1)
        lg.print(self.label, labelX, labelY)
    end
end

return slider