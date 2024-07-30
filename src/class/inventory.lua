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

local inventory = {}

function inventory:new(player)
    local inv = setmetatable({}, {__index = inventory})
    self.player = player
    self.inventoryOpen = false
    
    return inv
end

function inventory:drawSlot(x, y, colour)
    local itemSize = 35 * scale_x
    local cornerRadius = 5

    -- Inventory slots
    lg.setColor(colour)
    lg.rectangle("fill", x, y, itemSize, itemSize, cornerRadius, cornerRadius)
    
    -- Gradient effect
    lg.setColor(0.2, 0.2, 0.25, 0.6)
    lg.rectangle("fill", x, y, itemSize, itemSize, cornerRadius, cornerRadius)
    
    -- Light border
    lg.setColor(0.5, 0.5, 0.5, 0.6)
    lg.setLineWidth(1)
    lg.rectangle("line", x, y, itemSize, itemSize, cornerRadius, cornerRadius)
end

function inventory:drawItemName(item, x, y, itemSize)
    lg.setColor(0, 0, 0, 0.7)  
    local padding = 4 * scale_x
    local nameWidth = font.regular:getWidth(item) + padding * 2
    local nameHeight = font.regular:getHeight() + padding * 2
    lg.rectangle("fill", x, y - nameHeight, nameWidth, nameHeight, 4, 4)
    
    lg.setColor(1, 1, 1)
    lg.print(tostring(item), x + padding, y - nameHeight + padding)
end

function inventory:mousepressed(x, y, button)
    
end

function inventory:keypressed(key)
    
end

function inventory:mousepressed(x, y, button)
    
end

function inventory:keypressed(key)
    
end

function inventory:craftingDraw(icon)
    local width, height = lg.getWidth(), lg.getHeight()

    local itemSize = 35 * scale_x
    local itemSpacing = 10 * scale_x
    local cornerRadius = itemSize * 0.2
    local craftingPadding = itemSize * 0.2
    local craftingRows = 3
    local craftingColumns = 3

    local craftingWidth = craftingColumns * (itemSize + itemSpacing) - itemSpacing + craftingPadding * 2
    local craftingHeight = craftingRows * (itemSize + itemSpacing) - itemSpacing + craftingPadding * 2
    local craftingX = width * 0.67 - craftingWidth * 0.5
    local craftingY = height * 0.5 - craftingHeight * 0.5

    -- Draw crafting UI background
    lg.setColor(0.1, 0.1, 0.1)
    lg.rectangle("fill", craftingX, craftingY, craftingWidth, craftingHeight, cornerRadius, cornerRadius)

    lg.setColor(0.2, 0.2, 0.25)
    lg.setLineWidth(3)
    lg.rectangle("line", craftingX, craftingY, craftingWidth, craftingHeight, cornerRadius, cornerRadius)
    lg.setLineWidth(1)

    -- Draw crafting grid slots
    for row = 1, craftingRows do
        for col = 1, craftingColumns do
            local slotX = craftingX + craftingPadding + (col - 1) * (itemSize + itemSpacing)
            local slotY = craftingY + craftingPadding + (row - 1) * (itemSize + itemSpacing)
            local index = (row - 1) * craftingColumns + col

            self:drawSlot(slotX, slotY, {0.3, 0.3, 0.4})

            -- Draw items in the crafting grid slots
            local itemData = self.player.craftingGrid[index]
            if itemData then
                local item = itemData.item
                local quantity = itemData.quantity
                local quantityText = tostring(quantity)

                local textWidth = font.regular:getWidth(quantityText)
                local textHeight = font.regular:getHeight()
                local textX = slotX + itemSize - textWidth - itemSize * 0.1
                local textY = slotY + itemSize - textHeight - itemSize * 0.1
                lg.setColor(1, 1, 1)
                if tiles[icon[item]] then
                    lg.draw(tileAtlas, tiles[icon[item]], slotX + itemSize * 0.1, slotY + itemSize * 0.1, 0, itemSize * 0.8 / config.graphics.assetSize, itemSize * 0.8 / config.graphics.assetSize)
                    lg.print(quantityText, textX, textY)
                end
            end

            -- Highlight selected item
            if self.selectedItem and index == self.selectedItem.index then
                lg.setColor(0.2, 0.6, 0.8, 0.8)
                lg.setLineWidth(3)
                lg.rectangle("line", slotX, slotY, itemSize, itemSize, cornerRadius, cornerRadius)
                lg.setLineWidth(1)
            end

            -- Highlight hovered slot
            local mouseX, mouseY = love.mouse.getPosition()
            if mouseX >= slotX and mouseX <= slotX + itemSize and mouseY >= slotY and mouseY <= slotY + itemSize then
                lg.setColor(0.3, 0.8, 1)
                lg.setLineWidth(3)
                lg.rectangle("line", slotX, slotY, itemSize, itemSize, cornerRadius, cornerRadius)
                lg.setLineWidth(1)
            end
        end
    end

    -- Draw crafting result slot
    local resultSlotX = craftingX + craftingWidth + itemSpacing
    local resultSlotY = craftingY + craftingHeight / 2 - itemSize / 2

    self:drawSlot(resultSlotX, resultSlotY, {0.3, 0.3, 0.4})

    -- Draw crafting result item
    if self.craftingResult then
        lg.setColor(1, 1, 1)
        if tiles[icon[self.craftingResult]] then
            lg.draw(tileAtlas, tiles[icon[self.craftingResult]], resultSlotX + itemSize * 0.1, resultSlotY + itemSize * 0.1, 0, itemSize * 0.8 / config.graphics.assetSize, itemSize * 0.8 / config.graphics.assetSize)
        end
    end
end

function inventory:draw(icon)
    --if not self.inventoryOpen then
    --    return 
    --end

    local itemSize = 35 * scale_x
    local itemSpacing = 10 * scale_x
    local cornerRadius = 8 * scale_x

    local inventoryRows = 5
    local maxHotbarItems = 8
    local inventoryColumns = maxHotbarItems
    local inventoryPadding = itemSize * 0.2
    local width, height = lg.getWidth(), lg.getHeight()
    local inventoryWidth = inventoryColumns * (itemSize + itemSpacing) - itemSpacing + inventoryPadding * 2
    local inventoryHeight = inventoryRows * (itemSize + itemSpacing) - itemSpacing + inventoryPadding * 2
    local inventoryX = width * 0.47 - inventoryWidth * 0.5
    local inventoryY = height * 0.5 - inventoryHeight * 0.5
    
    -- Inventory background
    lg.setColor(0.1, 0.1, 0.1)
    lg.rectangle("fill", inventoryX, inventoryY, inventoryWidth, inventoryHeight, cornerRadius, cornerRadius)

    -- Inventory border
    lg.setColor(0.2, 0.2, 0.25)
    lg.setLineWidth(3)
    lg.rectangle("line", inventoryX, inventoryY, inventoryWidth, inventoryHeight, cornerRadius, cornerRadius)
    lg.setLineWidth(1)

    for row = 1, inventoryRows do
        for col = 1, inventoryColumns do
            local index = (row - 1) * inventoryColumns + col
            local x = inventoryX + inventoryPadding + (col - 1) * (itemSize + itemSpacing)
            local y = inventoryY + inventoryPadding + (row - 1) * (itemSize + itemSpacing)

            self:drawSlot(x, y, {0.3, 0.3, 0.4})
        end
    end
end

return inventory