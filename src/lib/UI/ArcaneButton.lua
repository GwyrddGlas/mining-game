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


function ArcaneButton:draw()
    local centerX, centerY = self.x + self.width/2, self.y + self.height/2
    local scaledWidth, scaledHeight = self.width * self.scale, self.height * self.scale
    local drawX, drawY = centerX - scaledWidth/2, centerY - scaledHeight/2
    local spriteScale = 2

    lg.push()
    lg.translate(centerX, centerY)
    lg.scale(self.scale)
    lg.translate(-centerX, -centerY)

    lg.setColor(self.color)

    -- Draw button background
    lg.draw(tileAtlas, self.buttonLeft, self.x, self.y, 0, self.height / config.graphics.assetSize, self.height / config.graphics.assetSize)
    lg.draw(tileAtlas, self.buttonCenter, self.x + self.height, self.y, 0, (self.width - (self.height * 2)) / config.graphics.assetSize, self.height / config.graphics.assetSize)
    lg.draw(tileAtlas, self.buttonRight, self.x + self.width - self.height, self.y, 0, self.height / config.graphics.assetSize, self.height / config.graphics.assetSize)

    local leftSpriteX = self.x + self.height * 0.2
    local rightSpriteX = self.x + self.width - self.height * 1.2
    
    -- Draw sprites if they exist
    if self.leftSprite then
        lg.draw(tileAtlas, self.leftSprite, leftSpriteX, self.y + self.height * 0.25, 0, spriteScale, spriteScale)
    end
    if self.rightSprite then
        lg.draw(tileAtlas, self.rightSprite, rightSpriteX, self.y + self.height * 0.25, 0, spriteScale, spriteScale)
    end
        
    -- Text
    lg.setColor(self.textColor)
    local font = lg.getFont()
    local textX, textWidth
    
    if self.leftSprite and self.rightSprite then
        textX = leftSpriteX + self.height * 1.2
        textWidth = rightSpriteX - textX
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