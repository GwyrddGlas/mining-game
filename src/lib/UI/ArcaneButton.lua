local ArcaneButton = {}
local arcane_button_meta = {__index = ArcaneButton}

local lg = love.graphics

local hoverSound = love.audio.newSource("src/assets/audio/button-hover.wav", "static")

function ArcaneButton.new(number, text, color, textColor, x, y, width, height, leftSprite, rightSprite, func)
    return setmetatable({
        number = number,
        text = text,
        color = color,
        textColor = textColor,
        x = x,
        y = y,
        width = width,
        height = height,
        func = func,
        buttonLeft = tiles[60],
        buttonCenter = tiles[61],
        buttonRight = tiles[62],
        leftSprite = tiles[leftSprite],
        rightSprite = tiles[rightSprite],
        scale = 1,
        targetScale = 1,
        isHovered = false,
        wasHovered = false,  
        isClicked = false
    }, arcane_button_meta)
end


function ArcaneButton:mouseOver()
    local mx, my = love.mouse.getPosition()
    return mx > self.x and mx < self.x + self.width and my > self.y and my < self.y + self.height or false
end

function ArcaneButton:update(dt)
    self.wasHovered = self.isHovered
    self.isHovered = self:mouseOver()
    
    if self.isHovered then
        self.targetScale = 1.05
        if not self.wasHovered then
            hoverSound:stop()
            hoverSound:setVolume(config.audio.sfx)
            hoverSound:play()
        end
    else
        self.targetScale = 1
    end
    
    if self.isClicked then
        self.targetScale = 0.95
    end
    
    self.scale = self.scale + (self.targetScale - self.scale) * 10 * dt
end

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

function ArcaneButton:draw()
    local centerX, centerY = self.x + self.width/2, self.y + self.height/2
    local scaledWidth, scaledHeight = self.width * self.scale, self.height * self.scale
    local drawX, drawY = centerX - scaledWidth/2, centerY - scaledHeight/2
    local spriteScale = 2

    -- Draw button background
    lg.setColor(1, 1, 1, 0.2)
    lg.rectangle("fill", self.x, self.y, self.width, self.height, 5, 5)
    lg.setColor(1, 1, 1, 1)

    -- Draw sprites if they exist
    if self.leftSprite then
        lg.draw(tileAtlas, self.leftSprite, self.x + self.height * 0.2, self.y + self.height * 0.25, 0, spriteScale, spriteScale)
    end
    
    if self.rightSprite then
        lg.draw(tileAtlas, self.rightSprite, self.x + self.width - self.height * 1.2, self.y + self.height * 0.25, 0, spriteScale, spriteScale)
    end

    lg.push()
    lg.translate(centerX, centerY)
    lg.scale(self.scale)
    lg.translate(-centerX, -centerY)

    -- Draw glowing border with shader
    lg.setShader(buttonGlowShader)
    buttonGlowShader:send("time", love.timer.getTime())
    buttonGlowShader:send("size", {self.width, self.height})
    buttonGlowShader:send("position", {self.x, self.y})
   
    lg.setColor(self.color)
    lg.rectangle("line", self.x, self.y, self.width, self.height, 5, 5)
    lg.setShader()  -- Reset shader

        
    -- Text
    lg.setColor(self.textColor)
    local font = lg.getFont()
    local textX, textWidth
    
    if self.leftSprite and self.rightSprite then
        textX = self.x + self.height * 1.2
        textWidth = self.width - self.height * 2.4
    else
        textX = self.x + self.height * 0.5
        textWidth = self.width - self.height
    end
    
    local y = self.y + (self.height / 2) - ((font:getAscent() - font:getDescent()) / 2)
    lg.printf(self.text, textX, y, textWidth, "center")

    -- Draw the number
    if self.number then
        local numberX = self.x + self.width * 0.25
        lg.print(self.number, numberX, self.y + (self.height / 2) - ((font:getAscent() - font:getDescent()) / 2))
    end

    lg.pop()
end

function ArcaneButton:mousepressed(x, y, k)
    if k == 1 and self:mouseOver() then
        self.isClicked = true
        if type(self.func) == "function" then
            self.func(self)
            hoverSound:stop()
            hoverSound:play()
        end
    end
end

function ArcaneButton:mousereleased(x, y, k)
    if k == 1 then
        self.isClicked = false
    end
end

return ArcaneButton