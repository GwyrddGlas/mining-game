local ArcaneUI = {}
local lg = love.graphics

local rectWidth = 250
local rectHeight = 60
local spacing = 10
local iconToName = {}

local ArcaneButton = require("src/lib/UI/ArcaneButton")
local recipes = require("src/lib/UI/recipes")

local icon = {
    Coal = 1, --1 - 8 are ores
    Iron = 2,
    Gold = 3,
    Uranium = 4,
    Diamond = 5,
    Ruby = 6,
    Tanzenite = 7,
    Copper = 8,
    Shrub = 9, --stick
    ironIngot = 10, 
    goldIngot = 11, 
    emeraldIngot = 12, 
    diamondIngot = 13, 
    rubyIngot = 14,
    tanzeniteIngot = 15, 
    copperIngot = 16, 
    Wall = 18,
    Crafting = 28,
    Furnace = 29,
    StoneBrick = 30,
    Grass = 31,
    Dirt = 32,
    Torch = 33,
    Chest = 34,
    Water = 35,
    Teleporter = 36,
    health = 41,
    halfHeart = 42,
    MagicPlant = 49,
    Mushroom = 51,
}

function ArcaneUI:init()
    self.listButtons = {}
    self.sectionButtons = {}
    self.sectionPositions = {}
    self.activeSections = {}

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
                self:toggleSection(section)
            end
        )
        self.sectionPositions[section] = startX
        startX = startX + rectWidth + spacing
    end

    for name, value in pairs(icon) do
        iconToName[value] = name
    end

    self:updateListButtons()
end

local glowShader = love.graphics.newShader[[
    extern float time;
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec2 uv = screen_coords / love_ScreenSize.xy;
        float glow = sin(time * 2.0 + uv.x * 10.0) * 0.5 + 0.5;
        return vec4(0.2, 0.2, 0.4, 0.2) * glow;  // Blueish glow
    }
]]

function ArcaneUI:drawBackground()
    lg.setShader(glowShader)
    glowShader:send("time", love.timer.getTime())
    lg.setColor(1, 1, 1, 1)
    lg.rectangle("fill", 0, 0, lg.getWidth(), lg.getHeight())
    lg.setShader()
end

function ArcaneUI:toggleSection(section)
    if self.activeSections[section] then
        self.activeSections[section] = nil
    else
        self.activeSections[section] = true
    end
    self:updateListButtons()
end

local function convertIconToName(iconValue)
    return iconToName[iconValue] or "Unknown"
end

function ArcaneUI:updateListButtons()
    self.listButtons = {}
    local startY = 50 + (#self.sectionButtons * (rectHeight + spacing)) + spacing

    for section, isActive in pairs(self.activeSections) do
        if isActive and recipes[section] then
            local xPosition = self.sectionPositions[section]

            for i, recipe in ipairs(recipes[section]) do
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
                        -- Check if the player has enough magic
                        if _PLAYER.magic < recipe.cost then
                            console:addMessage("Not enough magic", "")
                            return
                        end

                        -- Check if the player has the required input item
                        local inputItemName = convertIconToName(recipe.input)
                        if not _INVENTORY:hasItem(inputItemName) then
                            console:addMessage("You need " .. inputItemName .. " to craft this!", "")
                            return
                        end

                        -- Deduct magic and input item, then give the output item
                        _PLAYER.magic = _PLAYER.magic - recipe.cost
                        _INVENTORY:removeItemFromInventory(inputItemName)
                        _INVENTORY:giveItem(convertIconToName(recipe.output), 1)
                        console:addMessage("Conjured " .. recipe.name, "")
                    end
                ) 
            end
        end
    end
end

function ArcaneUI:open(data)
    self.isOpen = true
    self.data = data
    self.activeSections = {}
    self:updateListButtons()
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
    self:drawBackground() 

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