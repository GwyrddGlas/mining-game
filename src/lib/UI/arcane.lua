local ArcaneUI = {}
local lg = love.graphics

local numRectangles = 5
local rectWidth = 250
local rectHeight = 60
local spacing = 10

local ArcaneButton = require("src/lib/UI/ArcaneButton")


local recipes = require("src/lib/ui/recipes")

function ArcaneUI:init()
    self.buttons = self.buttons or {}

    local startY = (lg.getHeight() / 2) - ((numRectangles * rectHeight + (numRectangles - 1) * spacing) / 2)
    local xPosition = (lg.getWidth() / 2) - (rectWidth / 2)

    for i, recipe in ipairs(recipes) do
        local buttonY = startY + (i - 1) * (rectHeight + spacing)
        
        self.buttons[#self.buttons+1] = ArcaneButton.new(recipe.cost, "->", {1,1,1}, {1,1,1}, xPosition, buttonY, rectWidth, rectHeight, recipe.input, recipe.output, function() 
            if _PLAYER.magic > recipe.cost then
                _PLAYER.magic = _PLAYER.magic - recipe.cost
                note:new("Conjured "..recipe.name, "success")
            end
        end) 
    end
end

function ArcaneUI:open(data)
    self.isOpen = true
    self.data = data
end

function ArcaneUI:close()
    self.isOpen = false
end

function ArcaneUI:update(dt)
    if not self.isOpen then return end
    for _, button in ipairs(self.buttons) do
        button:update(dt)
    end
end

function ArcaneUI:draw()
    if not self.isOpen then return end
    for _, button in ipairs(self.buttons) do
        button:draw()
    end
end

function ArcaneUI:mousepressed(x, y, button)
    if not self.isOpen then return end
    for _, btn in ipairs(self.buttons) do
        btn:mousepressed(x, y, button)
    end
end

function ArcaneUI:mousereleased(x, y, button)
    if not self.isOpen then return end
    for _, btn in ipairs(self.buttons) do
        btn:mousereleased(x, y, button)
    end
end

return ArcaneUI