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
    
    if not index1 then
        return
    end

    if not index2 then
        return
    end
    
    inventoryOrder[index1], inventoryOrder[index2] = inventoryOrder[index2], inventoryOrder[index1]
    inventory[item1], inventory[item2] = inventory[item2], inventory[item1]
end

function inventory:giveItem(item, quantity)
    if not self.player.inventory[item] then
        self.player.inventory[item] = 0
        table.insert(self.player.inventoryOrder, item)
    end
    self.player.inventory[item] = self.player.inventory[item] + quantity
end

function inventory:moveInventoryItemToIndex(item, index)
    local inventory = self.player.inventory
    local inventoryOrder = self.player.inventoryOrder
    local quantity = inventory[item]
    
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
                if x >= slotX and x <= slotX + itemSize and y >= slotY and y <= slotY + itemSize then
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
                    --return
                end
            end
        end
    else
        self.selectedItem = nil
    end

    if button == 2 and clickedItem then
        print("right click")

        -- Find the first available slot in the crafting grid
        local craftingGrid = self.player.craftingGrid
        local craftingGridOrder = self.player.craftingGridOrder
        local index = 1
        while craftingGrid[index] do
            index = index + 1
            if index > 9 then
                break
            end
        end
        if index <= 9 then
            -- Move the item to the next available slot in the crafting grid
            self.player.crafting:moveInventoryItemToCraftingGrid(clickedItem, index)
        end
    end
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
    
    --inventory background
    --lg.setColor(0.2, 0.2, 0.2, 0.8)
    --lg.rectangle("fill", inventoryX, inventoryY, inventoryWidth, inventoryHeight, cornerRadius, cornerRadius)

    for row = 1, inventoryRows do
        for col = 1, inventoryColumns do
            local index = (row - 1) * inventoryColumns + col
            local x = inventoryX + inventoryPadding + (col - 1) * (itemSize + itemSpacing)
            local y = inventoryY + inventoryPadding + (row - 1) * (itemSize + itemSpacing)

            --inventory slots
           -- lg.setColor(0.3, 0.3, 0.3, 0.9)
           -- lg.rectangle("fill", x, y, itemSize, itemSize, cornerRadius, cornerRadius)
           -- lg.setColor(0.5, 0.5, 0.5, 0.9)
           -- lg.rectangle("line", x, y, itemSize, itemSize, cornerRadius, cornerRadius)
            
            local item = self.player.inventoryOrder[index]
            if item then
                local quantity = self.player.inventory[item]
                
                --selected 
                if self.selectedItem == item then
                    lg.setColor(1, 1, 1, 0.5)
                    lg.rectangle("fill", x, y, itemSize, itemSize)
                end
                
                --print(tostring(item).."  "..tostring(self.icon[item]))
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

                        lg.print(quantityText, textX, textY)
                    end
                else
                    print("Failed to load "..tostring(item))
                end
            end

            --hover
            local mouseX, mouseY = love.mouse.getPosition()
            if mouseX >= x and mouseX <= x + itemSize and mouseY >= y and mouseY <= y + itemSize then
                lg.print(tostring(item), x, y - 10)

                --lg.setBlendMode("add")
                --lg.setColor(1, 1, 1, 1)
                --lg.rectangle("line", x + 1, y + 1, itemSize - 2, itemSize - 2)
                --lg.setColor(1, 1, 1, 0.1)
                --lg.rectangle("fill", x + 1, y + 1, itemSize - 2, itemSize - 2)
                --lg.setBlendMode("alpha")   
                
                lg.setColor(12/255, 150/255, 140/255)
                lg.setLineWidth(2)
                lg.rectangle("line", x, y, itemSize, itemSize)
                lg.setLineWidth(1)
            end
        end
    end
end

return inventory 