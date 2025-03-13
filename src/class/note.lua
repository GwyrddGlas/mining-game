local note = {
    notifications = {},
    colour = {
        default = {0, 0, 0},
        important = {1, 0.5, 0},
        success = {0, 1, 0},
        danger = {1, 0, 0}
    }
}

local lg = love.graphics

function note:new(text, colour, time, useTexture)
    self.notifications[#self.notifications + 1] = {
        text = text,
        colour = colour or "default",
        time = time or 3,
        useTexture = useTexture or false,
    }
end

function note:update(dt)
    for i = #self.notifications, 1, -1 do
        local v = self.notifications[i]
        v.time = v.time - dt
        if v.time < 0 then
            table.remove(self.notifications, i)
        end
    end
end

function note:draw()
    lg.setFont(font.regular)
    for i, v in ipairs(self.notifications) do
        local textWidth = lg.getFont():getWidth(v.text)  
        local buttonHeight = lg.getFont():getHeight() + 20 
        local buttonWidth = textWidth + 40 

        local x = lg.getWidth() - buttonWidth - (lg.getWidth() * 0.05) 
        local y = -(lg.getHeight() * 0.01) + (lg.getHeight() * 0.05) * i

        if v.useTexture then
            local buttonLeft = tiles[60]
            local buttonCenter = tiles[61]
            local buttonRight = tiles[62]

            lg.setColor(1, 1, 1)

            -- Draw left part
            lg.draw(tileAtlas, buttonLeft, x, y, 0, buttonHeight / config.graphics.assetSize, buttonHeight / config.graphics.assetSize)

            -- Draw center part
            lg.draw(tileAtlas, buttonCenter, x + buttonHeight, y, 0, (buttonWidth - (buttonHeight * 2)) / config.graphics.assetSize, buttonHeight / config.graphics.assetSize)

            -- Draw right part
            lg.draw(tileAtlas, buttonRight, x + buttonWidth - buttonHeight, y, 0, buttonHeight / config.graphics.assetSize, buttonHeight / config.graphics.assetSize)
        end

        -- Draw text
        lg.setColor(self.colour[v.colour])
        lg.printf(v.text, x , y + 10, buttonWidth, "center")
    end
end

return note