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

function inventory:swapInventoryItems(item1, item2)
    if not item1 or not item2 then
        return
    end

    local inventory = self.player.inventory
    local inventoryOrder = self.player.inventoryOrder
    local index1, index2
    
    for i, item in ipairs(inventoryOrder) do
        if item == item1 then
            index1 = i
        elseif item == item2 then
            index2 = i
        end
        
        if index1 and index2 then
            break
        end
    end
    
    if not index1 or not index2 then
        return
    end
    
    inventoryOrder[index1], inventoryOrder[index2] = inventoryOrder[index2], inventoryOrder[index1]
    
    -- Ensure quantities are not negative
    inventory[item1] = math.max(0, inventory[item1] or 0)
end

function inventory:removeItemFromInventory(item)
    self.player.inventory[item] = nil
    for i, inventoryItem in ipairs(self.player.inventoryOrder) do
        if inventoryItem == item then
            table.remove(self.player.inventoryOrder, i)
            break
        end
    end
end

function inventory:giveItem(item, quantity)
    if not self.player.inventory[item] then
        self.player.inventory[item] = 0
        table.insert(self.player.inventoryOrder, item)
    end
    self.player.inventory[item] = math.max(0, (self.player.inventory[item] or 0) + quantity)
    
    -- Remove item from inventory if quantity becomes 0
    if self.player.inventory[item] == 0 then
        self:removeItemFromInventory(item)
    end
end

function inventory:toggleInventory()
    self.inventoryOpen = not self.inventoryOpen
end 

function inventory:moveInventoryItemToIndex(item, index)
    local inventory = self.player.inventory
    local inventoryOrder = self.player.inventoryOrder
    local quantity = inventory[item]
    
    if not quantity or quantity <= 0 then
        self:removeItemFromInventory(item)
        return
    end
    
    -- Find the current index of the item
    local currentIndex
    for i, existingItem in ipairs(inventoryOrder) do
        if existingItem == item then
            currentIndex = i
            break
        end
    end
    
    if currentIndex then
        table.remove(inventoryOrder, currentIndex)
        table.insert(inventoryOrder, index, item)
        inventory[item] = quantity
    end
end

function inventory:mousepressed(x, y, button)
    if not self.inventoryOpen then
        return
    end

    local inventoryX, inventoryY, inventoryWidth, inventoryHeight = self:getInventoryBounds()
    local itemSize = self:getInventoryItemSize()
    local itemSpacing = self:getInventoryItemSpacing()
    local inventoryColumns = self:getInventoryColumns()
    local inventoryRows = 3
    local inventoryPadding = itemSize * 0.2
    local clickedItem = nil
    
    if x >= inventoryX and x <= inventoryX + inventoryWidth and y >= inventoryY and y <= inventoryY + inventoryHeight then
        for row = 1, inventoryRows do
            for col = 1, inventoryColumns do
                local slotX = inventoryX + inventoryPadding + (col - 1) * (itemSize + itemSpacing)
                local slotY = inventoryY + inventoryPadding + (row - 1) * (itemSize + itemSpacing)
                -- Check if the mouse is anywhere within the slot
                if x >= slotX and x < slotX + itemSize + itemSpacing and 
                   y >= slotY and y < slotY + itemSize + itemSpacing then
                    local index = (row - 1) * inventoryColumns + col
                    clickedItem = self:getInventoryItemAtIndex(index)
                    if button == 1 and self.selectedItem then
                        if clickedItem then
                            self:swapInventoryItems(self.selectedItem, clickedItem)
                        else
                            self:moveInventoryItemToIndex(self.selectedItem, index)
                        end
                        self.selectedItem = nil
                    else
                        self.selectedItem = clickedItem
                    end
                    break
                end
            end
            if clickedItem then break end
        end
    else
        self.selectedItem = nil
    end

    --if button == 2 and clickedItem then
    --    -- Find the first available slot in the crafting grid
    --    local craftingGrid = self.player.craftingGrid
    --    local craftingGridOrder = self.player.craftingGridOrder
    --    local index = 1
    --    while craftingGrid[index] do
    --        index = index + 1
    --        if index > 9 then
    --            break
    --        end
    --    end
    --    if index <= 9 then
    --        -- Move the item to the next available slot in the crafting grid
    --        self.player.crafting:moveInventoryItemToCraftingGrid(clickedItem, index)
    --    end
    --end
end

function inventory:keypressed(key)
    if key == gameControls.inventory and not console.isOpen then
        self:toggleInventory()
    end
end

function inventory:drawItemName(item, x, y, itemSize)
    lg.setColor(0, 0, 0, 0.7)  -- Semi-transparent black background
    local padding = 4 * scale_x
    local nameWidth = font.regular:getWidth(item) + padding * 2
    local nameHeight = font.regular:getHeight() + padding * 2
    lg.rectangle("fill", x, y - nameHeight, nameWidth, nameHeight, 4, 4)
    
    lg.setColor(1, 1, 1)
    lg.print(tostring(item), x + padding, y - nameHeight + padding)
end

function inventory:drawHotbar(icon)
    self.icon = icon

    local width, height = lg.getWidth(), lg.getHeight()

    local hotbarX = width * 0.5
    local hotbarY = height - height * 0.07
    local hotbarWidth = width * 0.28 
    local hotbarHeight = height * 0.07
    local itemSize = hotbarHeight * 0.8
    local maxHotbarItems = 6
    local itemSpacing = (hotbarWidth - itemSize * maxHotbarItems) / (maxHotbarItems - 1)
    local cornerRadius = itemSize * 0.2

    local hotbarPadding = itemSize * 0.08 
    local adjustedHotbarWidth = hotbarWidth + hotbarPadding * 2

    local itemX = hotbarX - (adjustedHotbarWidth * 0.5) + hotbarPadding
    local itemY = hotbarY + (hotbarHeight - itemSize) * 0.5

    local selectedIndex = self.selectedIndex

    -- Draw hotbar background
    lg.setColor(83/255, 83/255, 83/255, 0.9)  -- Dark gray background from inventory
    lg.rectangle("fill", hotbarX - adjustedHotbarWidth * 0.5, hotbarY, adjustedHotbarWidth, hotbarHeight, cornerRadius, cornerRadius)

    for i = 1, maxHotbarItems do
        local x = itemX + (i - 1) * (itemSize + itemSpacing)
        local y = itemY
    
        -- Draw item slot
        if i == selectedIndex then
            lg.setColor(0.2, 0.6, 0.8, 0.8)  -- Bright blue for selected slot
        else
            lg.setColor(51/255, 51/255, 51/255, 0.7)  -- Darker gray for slots from inventory
        end
        lg.rectangle("fill", x, y, itemSize, itemSize, cornerRadius, cornerRadius)
    
        -- Draw item slot border
        if i == selectedIndex then
            lg.setColor(0.3, 0.8, 1)  -- Brighter blue border for selected slot
            lg.setLineWidth(3)
        else
            lg.setColor(99/255, 99/255, 99/255, 0.9)  -- Light gray border from inventory
            lg.setLineWidth(2)
        end
        lg.rectangle("line", x, y, itemSize, itemSize, cornerRadius, cornerRadius)
        lg.setLineWidth(1)

        -- Draw item icon and quantity
        local item = self.player.inventoryOrder[i]
        if item then
            local quantity = self.player.inventory[item]
            if self.icon[item] then
                if tileAtlas and tiles[self.icon[item]] then
                    lg.setColor(1, 1, 1)
                    lg.draw(tileAtlas, tiles[self.icon[item]], x + itemSize * 0.1, y + itemSize * 0.1, 0, itemSize * 0.8 / config.graphics.assetSize, itemSize * 0.8 / config.graphics.assetSize)
                    
                    lg.setFont(font.regular)
                    local quantityText = tostring(quantity)
                    local textWidth = font.regular:getWidth(quantityText)
                    local textHeight = font.regular:getHeight()
                    local textX = x + itemSize - textWidth - itemSize * 0.1
                    local textY = y + itemSize - textHeight - itemSize * 0.1
    
                    lg.setColor(1, 1, 1)
                    lg.print(quantityText, textX, textY)
                end
            end
        end
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
    lg.setColor(83/255, 83/255, 83/255)
    lg.rectangle("fill", inventoryX, inventoryY, inventoryWidth, inventoryHeight, cornerRadius, cornerRadius)

    local mouseX, mouseY = love.mouse.getPosition()
    local hoveredItem = nil
    local hoveredX, hoveredY = 0, 0

    for row = 1, inventoryRows do
        for col = 1, inventoryColumns do
            local index = (row - 1) * inventoryColumns + col
            local x = inventoryX + inventoryPadding + (col - 1) * (itemSize + itemSpacing)
            local y = inventoryY + inventoryPadding + (row - 1) * (itemSize + itemSpacing)
            local item = self.player.inventoryOrder[index]

            -- Inventory slots
            lg.setColor(51/255,51/255,51/255) 
            lg.rectangle("fill", x, y, itemSize, itemSize, cornerRadius, cornerRadius)
            lg.setColor(99/255,99/255,99/255)  -- Light gray border
            lg.setLineWidth(2)
            lg.rectangle("line", x, y, itemSize, itemSize, cornerRadius, cornerRadius)
            lg.setLineWidth(1)

            if item then
                local quantity = self.player.inventory[item]
                
                -- Selected item
                if self.selectedItem == item then
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
            if mouseX >= x and mouseX <= x + itemSize and mouseY >= y and mouseY <= y + itemSize then
                if item then
                    hoveredItem = item
                    hoveredX, hoveredY = x, y
                end

                lg.setColor(0.3, 0.8, 1)
                lg.setLineWidth(3)
                lg.rectangle("line", x, y, itemSize, itemSize, cornerRadius, cornerRadius)
                lg.setLineWidth(1)
            end
        end
    end

    -- Draw hovered item name last
    if hoveredItem then
        self:drawItemName(hoveredItem, hoveredX, hoveredY, itemSize)
    end
end

return inventory 