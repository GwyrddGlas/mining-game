local ArcaneUI = {}
local lg = love.graphics

local rectWidth = 250
local rectHeight = 60
local spacing = 10

local ArcaneButton = require("src/lib/UI/ArcaneButton")
local recipes = require("src/lib/ui/recipes")

function ArcaneUI:init()
    self.listButtons = {}
    self.sectionButtons = {}
    self.activeSection = nil

    -- Calculate total width of all section buttons
    local totalSections = 0
    for _ in pairs(recipes) do
        totalSections = totalSections + 1
    end
    local totalWidth = (totalSections * rectWidth) + ((totalSections - 1) * spacing)

    local startX = (lg.getWidth() - totalWidth) / 2
    local startY = 200  

    for section, _ in pairs(recipes) do
        self.sectionButtons[#self.sectionButtons + 1] = ArcaneButton.new(
            nil, 
            section,
            {1, 1, 1},
            {0.8, 0.8, 0.8},
            startX,
            startY,
            rectWidth,
            rectHeight,
            nil,
            nil,
            function()
                self:setActiveSection(section)
            end
        )
        startX = startX + rectWidth + spacing
    end

    self:initializeListButtons()
end

function ArcaneUI:initializeListButtons()
    self.listButtons = {}
    if self.activeSection and recipes[self.activeSection] then
        local startY = 50 + (#self.sectionButtons * (rectHeight + spacing)) + spacing
        local xPosition = (lg.getWidth() / 2) - (rectWidth / 2)

        for i, recipe in ipairs(recipes[self.activeSection]) do
            local buttonY = startY + (i - 1) * (rectHeight + spacing)
            
            self.listButtons[#self.listButtons + 1] = ArcaneButton.new(
                recipe.cost,
                "->",
                {1, 1, 1},
                {1, 1, 1},
                xPosition,
                buttonY,
                rectWidth,
                rectHeight,
                recipe.input,
                recipe.output,
                function() 
                    if _PLAYER.magic > recipe.cost then
                        _PLAYER.magic = _PLAYER.magic - recipe.cost
                        console:addMessage("Conjured " .. recipe.name, "system")
                    else
                        console:addMessage("Not enough conjuration", "system")
                    end
                end
            ) 
        end
    end
end

function ArcaneUI:setActiveSection(section)
    self.activeSection = section
    self:initializeListButtons()
end

function ArcaneUI:open(data)
    self.isOpen = true
    self.data = data
    self.activeSection = nil
    self:initializeListButtons()
end

function ArcaneUI:close()
    self.isOpen = false
end

function ArcaneUI:update(dt)
    if not self.isOpen then return end
    for _, button in ipairs(self.sectionButtons) do
        button:update(dt)
    end
    for _, button in ipairs(self.listButtons) do
        button:update(dt)
    end
end

function ArcaneUI:draw()
    if not self.isOpen then return end
    for _, button in ipairs(self.sectionButtons) do
        button:draw()
    end
    for _, button in ipairs(self.listButtons) do
        button:draw()
    end
end

function ArcaneUI:mousepressed(x, y, button)
    if not self.isOpen then return end
    for _, btn in ipairs(self.sectionButtons) do
        btn:mousepressed(x, y, button)
    end
    for _, btn in ipairs(self.listButtons) do
        btn:mousepressed(x, y, button)
    end
end

function ArcaneUI:mousereleased(x, y, button)
    if not self.isOpen then return end
    for _, btn in ipairs(self.sectionButtons) do
        btn:mousereleased(x, y, button)
    end
    for _, btn in ipairs(self.listButtons) do
        btn:mousereleased(x, y, button)
    end
end

return ArcaneUI