local label = {}
local label_meta = {__index = label}

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

function label.new(text, color, font, x, y, align)
    return setmetatable({
        text = text,
        color = color,
        font = font,
        x = x,
        y = y,
        align = align
    }, label_meta)
end

function label:draw()
    lg.setColor(self.color)

    local of = lg.getFont()
    lg.setFont(self.font)
    
    lg.printf(self.text, self.x, self.y, lg.getWidth(), self.align)

    lg.setFont(of)
end

return label