local TeleporterUI = {}
local lg = love.graphics

local glowShader = love.graphics.newShader[[
    extern float time;
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        float glow = sin(time * 2.0 + screen_coords.x * 0.1 + screen_coords.y * 0.1) * 0.5 + 0.5;
        return vec4(0.5, 0.5, 1.0, glow);  // Blueish glow
    }
]]

local dimensions = {
    {name = "The Grasslands", color = {0.2, 0.8, 0.2}},  -- Green
    {name = "tmp", color = {0.8, 0.6, 0.2}},  -- Yellow
    {name = "tmp", color = {0.6, 0.8, 1.0}},     -- Light blue
}

local buttons = {}
local selectedDimension = nil

function TeleporterUI:init()
    local startX = (lg.getWidth() - 200) / 2
    local startY = 200
    local buttonWidth = 200
    local buttonHeight = 50
    local spacing = 10

    for i, dimension in ipairs(dimensions) do
        buttons[i] = {
            x = startX,
            y = startY + (i - 1) * (buttonHeight + spacing),
            width = buttonWidth,
            height = buttonHeight,
            color = dimension.color,
            name = dimension.name,
            isHovered = false,
            isSelected = false
        }
    end
end

function TeleporterUI:open()
    self.isOpen = true
    selectedDimension = nil
end

function TeleporterUI:close()
    self.isOpen = false
end

function TeleporterUI:update(dt)
    if not self.isOpen then return end

    local mx, my = love.mouse.getPosition()
    for i, button in ipairs(buttons) do
        button.isHovered = mx > button.x and mx < button.x + button.width and
                           my > button.y and my < button.y + button.height
    end
end

function TeleporterUI:draw()
    if not self.isOpen then return end

    -- Draw glowing background
    lg.setShader(glowShader)
    glowShader:send("time", love.timer.getTime())
    lg.setColor(1, 1, 1, 0.2)
    lg.rectangle("fill", 0, 0, lg.getWidth(), lg.getHeight())
    lg.setShader()

    -- Draw dimension buttons
    for i, button in ipairs(buttons) do
        lg.setColor(button.color)
        if button.isHovered or button.isSelected then
            lg.setColor(button.color[1] * 1.2, button.color[2] * 1.2, button.color[3] * 1.2)
        end
        lg.rectangle("fill", button.x, button.y, button.width, button.height, 5, 5)

        lg.setColor(1, 1, 1)
        lg.printf(button.name, button.x, button.y + button.height / 2 - 10, button.width, "center")
    end
end

function TeleporterUI:mousepressed(x, y, button)
    if not self.isOpen then return end
    
    for i, btn in ipairs(buttons) do
        if x > btn.x and x < btn.x + btn.width and y > btn.y and y < btn.y + btn.height then
            selectedDimension = btn.name
            self:teleport(selectedDimension)
        end
    end
end

function TeleporterUI:mousereleased(x, y, button)

end

function TeleporterUI:teleport(dimension)
    print("Teleporting to " .. dimension)
    self:close()
end

return TeleporterUI