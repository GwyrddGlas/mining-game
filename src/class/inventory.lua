local inventory = {}
local crafting = require("src/class/crafting")

function inventory:new(player)
    local inv = setmetatable({}, {__index = inventory})
    self.player = player -- Assign player to self.player
    player.inventoryOrder = player.inventoryOrder or {}
    player.craftingGrid = player.craftingGrid or {} 
    player.craftingGridOrder = player.craftingGridOrder or {} 
    player.crafting = player.crafting or crafting:new(player) 
    
    inv.highlightedItem = nil
    inv.selectedItem = nil
    inv.selectedIndex = nil
    inv.inventoryOrder = player.inventoryOrder
    
    for item, _ in pairs(player.inventory) do
        player.inventoryOrder[#player.inventoryOrder + 1] = item
    end

    return inv
end

function inventory:getInventoryBounds()
    local width, height = lg.getWidth(), lg.getHeight()
    local inventoryRows, inventoryColumns = 3, 6
    local itemSize = self:getInventoryItemSize()
    local itemSpacing = self:getInventoryItemSpacing()
    local inventoryWidth = inventoryColumns * (itemSize + itemSpacing) - itemSpacing
    local inventoryHeight = inventoryRows * (itemSize + itemSpacing) - itemSpacing
    local inventoryX = width * 0.5 - inventoryWidth * 0.5
    local inventoryY = height * 0.5 - inventoryHeight * 0.5
    return inventoryX, inventoryY, inventoryWidth, inventoryHeight
end

function inventory:getInventoryItemSize()
    return 50 * scale_x
end

function inventory:getInventoryItemSpacing()
    return 10 * scale_x
end

function inventory:getInventoryColumns()
    return 6
end

function inventory:getInventoryItemAtIndex(index)
    return self.player.inventoryOrder[index]
end

function inventory:swapItems(index, clickedItem)
    local selectedIndex = self.selectedItem.index
    local selectedItem = self.player.inventory[selectedIndex]

    if clickedItem then
        self.player.inventory[selectedIndex] = clickedItem
        self.player.inventoryOrder[selectedIndex] = clickedItem
    end
    
    if selectedItem then 
        self.player.inventory[index] = selectedItem
        self.player.inventoryOrder[index] = selectedItem
    end
end

function inventory:moveSelectedItemToEmptySlot(index)
    local selectedIndex = self.selectedItem.index
    local selectedItem = self.player.inventory[selectedIndex]

    if selectedItem then 
        self.player.inventory[selectedIndex] = nil
        self.player.inventory[index] = selectedItem
        self.player.inventoryOrder[selectedIndex] = nil
        self.player.inventoryOrder[index] = selectedItem
    end
end

function inventory:selectItem(index, clickedItem)
    self.selectedItem = {item = clickedItem, index = index}
end

function inventory:giveItem(item, quantity)
    if not self.player.inventory[item] then
        self.player.inventory[item] = 0
        table.insert(self.player.inventoryOrder, item)
    end
    self.player.inventory[item] = self.player.inventory[item] + quantity
end

function inventory:mousepressed(x, y, button)
    local inventoryX, inventoryY, inventoryWidth, inventoryHeight = self:getInventoryBounds()
    local itemSize = self:getInventoryItemSize()
    local itemSpacing = self:getInventoryItemSpacing()
    local inventoryColumns = self:getInventoryColumns()
    local inventoryRows = 3
    local inventoryPadding = itemSize * 0.2

    if self:isMouseInsideInventory(x, y, inventoryX, inventoryY, inventoryWidth, inventoryHeight) then
        self:handleInventoryClick(x, y, button, inventoryX, inventoryY, itemSize, itemSpacing, inventoryPadding)
    else
        self.selectedItem = nil
    end
end

function inventory:isMouseInsideInventory(x, y, inventoryX, inventoryY, inventoryWidth, inventoryHeight)
    return x >= inventoryX and x <= inventoryX + inventoryWidth and y >= inventoryY and y <= inventoryY + inventoryHeight
end

function inventory:handleInventoryClick(x, y, button, inventoryX, inventoryY, itemSize, itemSpacing, inventoryPadding)
    local inventoryColumns = self:getInventoryColumns()
    local inventoryRows = 3

    for row = 1, inventoryRows do
        for col = 1, inventoryColumns do
            local slotX = inventoryX + inventoryPadding + (col - 1) * (itemSize + itemSpacing)
            local slotY = inventoryY + inventoryPadding + (row - 1) * (itemSize + itemSpacing)

            if self:isMouseInsideSlot(x, y, slotX, slotY, itemSize) then
                local index = (row - 1) * inventoryColumns + col
                local clickedItem = self.player.inventoryOrder[index]

                if button == 1 then
                    self:handleLeftClick(index, clickedItem)
                elseif button == 2 and clickedItem then
                    self:handleRightClick(index, clickedItem)
                end

                return
            end
        end
    end
end

function inventory:handleLeftClick(index, clickedItem)
    if self.selectedItem then
        if clickedItem then
            self:swapItems(index, clickedItem)
        else
            self:moveSelectedItemToEmptySlot(index)
        end
        self.selectedItem = nil
    else
        if clickedItem then
            self:selectItem(index, clickedItem)
        end
    end
end

function inventory:handleRightClick(index, clickedItem)
    -- Find the first available slot in the crafting grid
    local craftingGrid = self.player.craftingGrid
    local craftingGridOrder = self.player.craftingGridOrder
    local craftIndex = 1
    while craftingGrid[craftIndex] do
        craftIndex = craftIndex + 1
        if craftIndex > 9 then
            break
        end
    end
    if craftIndex <= 9 then
        -- Move the item to the next available slot in the crafting grid
        self.player.crafting:moveInventoryItemToCraftingGrid(clickedItem, craftIndex)
    end
end

function inventory:isMouseInsideSlot(x, y, slotX, slotY, itemSize)
    return x >= slotX and x <= slotX + itemSize and y >= slotY and y <= slotY + itemSize
end

function inventory:keypressed(key)
    if key == "i" then
        self.inventoryOpen = not self.inventoryOpen
    end
end

function inventory:draw(icon, itemSize, itemSpacing, cornerRadius, maxHotbarItems)
    if not self.inventoryOpen then
        return 
    end

    local inventoryRows = 3
    local inventoryColumns = maxHotbarItems
    local inventoryPadding = itemSize * 0.2
    local width, height = lg.getWidth(), lg.getHeight()
    local inventoryWidth = inventoryColumns * (itemSize + itemSpacing) - itemSpacing + inventoryPadding * 2
    local inventoryHeight = inventoryRows * (itemSize + itemSpacing) - itemSpacing + inventoryPadding * 2
    local inventoryX = width * 0.5 - inventoryWidth * 0.5
    local inventoryY = height * 0.5 - inventoryHeight * 0.5
    
    -- Inventory background
    lg.setColor(0.2, 0.2, 0.25, 0.9)  -- Slightly blue-ish dark background
    lg.rectangle("fill", inventoryX, inventoryY, inventoryWidth, inventoryHeight, cornerRadius, cornerRadius)

    for row = 1, inventoryRows do
        for col = 1, inventoryColumns do
            local index = (row - 1) * inventoryColumns + col
            local x = inventoryX + inventoryPadding + (col - 1) * (itemSize + itemSpacing)
            local y = inventoryY + inventoryPadding + (row - 1) * (itemSize + itemSpacing)
            local item = self.player.inventoryOrder[index]

            -- Inventory slots
            lg.setColor(0.3, 0.3, 0.4, 0.7) 
            lg.rectangle("fill", x, y, itemSize, itemSize, cornerRadius, cornerRadius)
            lg.setColor(0.5, 0.5, 0.6, 0.9)  -- Light gray border
            lg.setLineWidth(2)
            lg.rectangle("line", x, y, itemSize, itemSize, cornerRadius, cornerRadius)
            lg.setLineWidth(1)

            if item then
                local quantity = self.player.inventory[item]
                
                -- Selected item
                if self.selectedItem and self.selectedItem.item == item then
                    lg.setColor(0.2, 0.6, 0.8, 0.8) 
                    lg.setLineWidth(3)
                    lg.rectangle("line", x, y, itemSize, itemSize, cornerRadius, cornerRadius)
                    lg.setLineWidth(1)
                end
                
                if icon[item] then
                    lg.setColor(1, 1, 1)
                    if tileAtlas and tiles[icon[item]] then
                        lg.draw(tileAtlas, tiles[icon[item]], x + itemSize * 0.1, y + itemSize * 0.1, 0, itemSize * 0.8 / config.graphics.assetSize, itemSize * 0.8 / config.graphics.assetSize)

                        lg.setFont(font.regular)
                        local quantityText = tostring(quantity)
                        local textWidth = font.regular:getWidth(quantityText)
                        local textHeight = font.regular:getHeight()
                        local textX = x + itemSize - textWidth - itemSize * 0.1
                        local textY = y + itemSize - textHeight - itemSize * 0.1

                        lg.setColor(1, 1, 1)
                        lg.print(quantityText, textX, textY)
                    end
                else
                    print("Failed to load "..tostring(item))
                end
            end

            -- Hover effect
            local mouseX, mouseY = love.mouse.getPosition()
            if mouseX >= x and mouseX <= x + itemSize and mouseY >= y and mouseY <= y + itemSize then
                if item then
                    lg.setColor(1, 1, 1)
                    lg.print(tostring(item), x, y - 20) 
                end

                lg.setColor(0.3, 0.8, 1)
                lg.setLineWidth(3)
                lg.rectangle("line", x, y, itemSize, itemSize, cornerRadius, cornerRadius)
                lg.setLineWidth(1)
            end
        end
    end
end

return inventory