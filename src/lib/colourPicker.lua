local colourPicker = {}

local slider_size = {x = 16, y = 256}
local box_size = {x = 256, y = 256}

local function rgb_from_hue(hue)
    local k = (hue / 60) % 6
    local f = hue % 60 / 60

    local v = 255
    local p = 0
    local q = math.floor(v * (1 - f))
    local t = math.floor(v * f)

    if k == 0 then
        return v, t, p
    elseif k == 1 then
        return q, v, p
    elseif k == 2 then
        return p, v, t
    elseif k == 3 then
        return p, q, v
    elseif k == 4 then
        return t, p, v
    else
        return v, p, q
    end
end

local function draw_color_box(color_box)
    local r, g, b = rgb_from_hue(color_box.hue)
    love.graphics.setColor(r / 255, g / 255, b / 255)
    love.graphics.rectangle("fill", color_box.pos.x - box_size.x / 2, color_box.pos.y - box_size.y / 2, box_size.x, box_size.y)

    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", color_box.selected.x, color_box.selected.y, 10)

    -- Draw hue slider
    for i = 0, 360, 60 do
        r, g, b = rgb_from_hue(i)
        love.graphics.setColor(r / 255, g / 255, b / 255)
        love.graphics.rectangle("fill", color_box.hue_x_pos, color_box.pos.y - box_size.y / 2 + i * (box_size.y / 360), slider_size.x, box_size.y / 6)
    end
end

local function pick_color(self)
    local mouse_x, mouse_y = love.mouse.getPosition()
    mouse_x = (mouse_x / love.graphics.getWidth() * 2 - 1)
    mouse_y = (mouse_y / love.graphics.getHeight() * -2 + 1)

    if love.mouse.isDown(1) then
        self.in_hue_range = mouse_x > (self.hue_x_pos / love.graphics.getWidth() * 2 - 1)
    end
    if love.mouse.isDown(1) then
        if self.in_hue_range then
            self.hue = ((mouse_y + 1) / 2) * 360
        else
            local width = ((mouse_x + 1) / 2)
            local height = ((mouse_y + 1) / 2)
            self.selected.x = self.pos.x - box_size.x / 2 + width * box_size.x
            self.selected.y = self.pos.y - box_size.y / 2 + height * box_size.y

            local saturation = 255 * width
            saturation = math.floor(saturation * height)
            local b, g, r = rgb_from_hue(self.hue)
            b = math.floor(b * height)
            g = math.floor(g * height)
            r = math.floor(r * height)
            self.color = {math.max(r, saturation), math.max(g, saturation), math.max(b, saturation), 255}
        end
    end

    if love.keyboard.isDown("return") then
        return 0, self.color
    elseif love.keyboard.isDown("escape") or love.keyboard.isDown("backspace") then
        return 2
    end

    return 1, self.color
end

function colourPicker.new(pos, hue)
    local r, g, b = rgb_from_hue(hue or 0)
    local color = {r, g, b, 255}
    local color_box = {
        pos = pos,
        mouse_pos = {x = 0, y = 0},
        selected = {x = pos.x, y = pos.y},
        box_range = {
            width = function(value) return (value - pos.x + box_size.x / 2) / box_size.x end,
            height = function(value) return (value - pos.y + box_size.y / 2) / box_size.y end,
            inverse_width = function(value) return pos.x - box_size.x / 2 + value * box_size.x end,
            inverse_height = function(value) return pos.y - box_size.y / 2 + value * box_size.y end,
        },
        hue_range = {
            y = function(value) return (value - pos.y + box_size.y / 2) / box_size.y * 360 end,
            inverse_y = function(value) return pos.y - box_size.y / 2 + value / 360 * box_size.y end
        },
        hue_x_pos = pos.x + box_size.x + 20,
        in_hue_range = false,
        hue = hue,
        color = color,
        get = pick_color
    }

    return color_box
end

function colourPicker.update(color_box)
    local r, c = color_box:get()
    return r, c
end

function colourPicker.draw(color_box)
    draw_color_box(color_box)
end

return colourPicker