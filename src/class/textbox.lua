local textbox = {}
local textbox_meta = {__index = textbox}
local lg = love.graphics
local fs = love.filesystem
local kb = love.keyboard
local lm = love.mouse
local lt = love.thread
local random = math.random
local noise = love.math.noise
local sin = math.sin
local cos = math.cos
local f = string.format
local floor = math.floor

local defaultInputFilter = function() return true end

function textbox.new(text, placeholder, color, textColor, textColorSelected, x, y, width, height, inputFilter, maxLength)
    return setmetatable({
        type = "textbox",
        text = text,
        placeholder = placeholder,
        color = color,
        textColor = textColor,
        textColorSelected = textColorSelected,
        x = x,
        y = y,
        width = width,
        height = height,
        inputFilter = inputFilter or defaultInputFilter,
        maxLength = maxLength or 100,
        selected = false,
        buttonLeft = tiles[57],
        buttonCenter = tiles[58],
        buttonRight = tiles[59],
    }, textbox_meta)
end

function textbox:mouseOver()
    local mx, my = love.mouse.getPosition()
    return mx > self.x and mx < self.x + self.width and my > self.y and my < self.y + self.height or false
end

function textbox:draw()
    lg.setColor(self.color)
    -- Left
    lg.draw(tileAtlas, self.buttonLeft, self.x, self.y, 0, self.height / config.graphics.assetSize, self.height / config.graphics.assetSize)

    -- Center
    lg.draw(tileAtlas, self.buttonCenter, self.x + self.height, self.y, 0, (self.width - (self.height * 2)) / config.graphics.assetSize, self.height / config.graphics.assetSize)

    -- Right
    lg.draw(tileAtlas, self.buttonRight, self.x + self.width - self.height, self.y, 0, self.height / config.graphics.assetSize, self.height / config.graphics.assetSize)

    -- Text
    lg.setColor(self.textColor)
    if self.selected then
        lg.setColor(self.textColorSelected)
    end
    local font = lg.getFont()
    local y = self.y + (self.height / 2) - ((font:getAscent() - font:getDescent()) / 2)
    local text = self.text
    if #self.text < 1 and not self.selected then
        text = self.placeholder
    end
    lg.printf(text, self.x, y, self.width, "center")


    --lg.setColor(1, 0, 1)
    --lg.rectangle("line", self.x, self.y, self.width, self.height)
end

function textbox:textinput(t)
    if self.selected and self.inputFilter(t) and #self.text < self.maxLength then
        self.text = self.text..t
    end
end

function textbox:keypressed(key)
    if self.selected then
        if key == "backspace" then
            self.text = self.text:sub(1, -2)
        end
    end
end

function textbox:mousepressed(x, y, k)
    if k == 1 and self:mouseOver() then
        self.selected = true
    else
        self.selected = false
    end
end

return textbox