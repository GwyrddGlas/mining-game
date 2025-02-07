local TeleporterUI = {}
local teleporter_meta = {__index = TeleporterUI}

local lg = love.graphics

local hoverSound = love.audio.newSource("src/assets/audio/button-hover.wav", "static")

local buttonGlowShader = love.graphics.newShader[[
    extern float time;
    extern vec2 size;
    extern vec2 position;
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec2 uv = (screen_coords - position) / size;
        float glow = sin(time * 3.0 + uv.x * 10.0) * 0.5 + 0.5;
        return vec4(0.5, 0.5, 1.0, 1) * glow;  // Glowing border color
    }
]]

local glowShader = love.graphics.newShader[[
    extern float time;
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec2 uv = screen_coords / love_ScreenSize.xy;
        float glow = sin(time * 2.0 + uv.x * 10.0) * 0.5 + 0.5;
        return vec4(0.2, 0.2, 0.4, 0.2) * glow;  // Blueish glow
    }
]]

local dimensions = {
    {name = "grasslands", color = {0.2, 0.8, 0.2}},  -- Green
    {name = "The Caverns", color = {0.6, 0.8, 1.0}},  -- Light blue
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
            name = dimension.name,
            color = dimension.color,
            x = startX,
            y = startY + (i - 1) * (buttonHeight + spacing),
            width = buttonWidth,
            height = buttonHeight,
            scale = 1,
            targetScale = 1,
            isHovered = false,
            isClicked = false,
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
    for _, button in ipairs(buttons) do
        button.isHovered = mx > button.x and mx < button.x + button.width and
                           my > button.y and my < button.y + button.height

        if button.isHovered then
            button.targetScale = 1.05
            if not button.wasHovered then
                hoverSound:stop()
                hoverSound:setVolume(config.audio.sfx)
                hoverSound:play()
            end
        else
            button.targetScale = 1
        end

        if button.isClicked then
            button.targetScale = 0.95
        end

        button.scale = button.scale + (button.targetScale - button.scale) * 10 * dt
        button.wasHovered = button.isHovered
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

    -- Draw teleporter buttons
    for _, button in ipairs(buttons) do
        local centerX, centerY = button.x + button.width / 2, button.y + button.height / 2
        local scaledWidth, scaledHeight = button.width * button.scale, button.height * button.scale
        local drawX, drawY = centerX - scaledWidth / 2, centerY - scaledHeight / 2

        lg.setColor(button.color)
        lg.rectangle("fill", drawX, drawY, scaledWidth, scaledHeight, 5, 5)

        lg.setShader(buttonGlowShader)
        buttonGlowShader:send("time", love.timer.getTime())
        buttonGlowShader:send("size", {button.width, button.height})
        buttonGlowShader:send("position", {button.x, button.y})

        lg.setColor(button.color)
        lg.rectangle("line", drawX, drawY, scaledWidth, scaledHeight, 5, 5)

        lg.setShader()
        
        -- Draw text
        lg.setColor(1, 1, 1)
        lg.printf(button.name, button.x, button.y + button.height / 2 - 10, button.width, "center")
    end
end

function TeleporterUI:mousepressed(x, y, button)
    if not self.isOpen then return end

    for _, btn in ipairs(buttons) do
        if x > btn.x and x < btn.x + btn.width and y > btn.y and y < btn.y + btn.height then
            btn.isClicked = true
            selectedDimension = btn.name
            self:teleport(selectedDimension)
        end
    end
end

function TeleporterUI:mousereleased(x, y, button)
    if button == 1 then
        for _, btn in ipairs(buttons) do
            btn.isClicked = false
        end
    end
end

function TeleporterUI:teleport(dimension)
    self:close()
    state:load(dimension, _WORLDATA)
end

return TeleporterUI