local json = require("src.lib.dkjson")
local crafting = {}

local recipesFile = love.filesystem.read("src/assets/recipes/recipes.json")
local recipes = json.decode(recipesFile)

function crafting:new(player)
    local craft = setmetatable({}, {__index = crafting})
    self.player = player
    player.craftingGridOrder = player.craftingGridOrder or {}

    craft.selectedRecipe = nil
    craft.craftingGrid = {}
    craft.craftingGridOrder = {}
    craft.craftingResult = nil
    craft.recipes = {}
    return craft
end

function crafting:getCraftingBounds()
    local inventoryX, inventoryY, inventoryWidth, inventoryHeight = inventory:getInventoryBounds()
    local craftingRows, craftingColumns = 3, 3
    local itemSize = self:getCraftingItemSize()
    local itemSpacing = self:getCraftingItemSpacing()
    local craftingWidth = craftingColumns * (itemSize + itemSpacing) - itemSpacing
    local craftingHeight = craftingRows * (itemSize + itemSpacing) - itemSpacing
    local craftingX = inventoryX + inventoryWidth + itemSpacing
    local craftingY = inventoryY
    return craftingX, craftingY, craftingWidth, craftingHeight
end

function crafting:getCraftingItemSize()
    return 50 * scale_x
end

function crafting:getCraftingItemSpacing()
    return 10 * scale_x
end

function crafting:getCraftingColumns()
    return 3
end

function crafting:getCraftingItemAtIndex(index)
    return self.player.craftingGridOrder[index]
end

function crafting:swapCraftingItems(item1, item2)
    if not item1 or not item2 then
        return
    end

    local craftingGrid = self.player.craftingGrid
    local craftingGridOrder = self.player.craftingGridOrder
    local index1, index2

    for i, item in ipairs(craftingGridOrder) do
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

    craftingGridOrder[index1], craftingGridOrder[index2] = craftingGridOrder[index2], craftingGridOrder[index1]
    craftingGrid[item1], craftingGrid[item2] = craftingGrid[item2], craftingGrid[item1]
end

function crafting:moveInventoryItemToCraftingGrid(item, index)
    local inventory = self.player.inventory
    local craftingGrid = self.player.craftingGrid
    local craftingGridOrder = self.player.craftingGridOrder
    local quantity = inventory[item]
    
    -- Remove the item from the inventory
    inventory[item] = nil
    for i, existingItem in ipairs(self.player.inventoryOrder) do
        if existingItem == item then
            table.remove(self.player.inventoryOrder, i)
            break
        end
    end
    
    -- Check if the slot in the crafting grid is already occupied
    if craftingGrid[index] then
        local existingItem = craftingGrid[index].item
        local existingQuantity = craftingGrid[index].quantity
        
        -- If the items are the same, combine the quantities
        if existingItem == item then
            craftingGrid[index].quantity = existingQuantity + quantity
        else
            -- If the items are different, return the existing item to the inventory
            inventory[existingItem] = existingQuantity
            table.insert(self.player.inventoryOrder, existingItem)
            
            -- Remove the existing item from the crafting grid
            for i, gridItem in ipairs(craftingGridOrder) do
                if gridItem == existingItem then
                    table.remove(craftingGridOrder, i)
                    break
                end
            end
            
            -- Add the new item to the crafting grid
            table.insert(craftingGridOrder, index, item)
            craftingGrid[index] = {item = item, quantity = quantity}
        end
    else
        -- Add the item to the empty slot in the crafting grid
        table.insert(craftingGridOrder, index, item)
        craftingGrid[index] = {item = item, quantity = quantity}
    end
end

function crafting:keypressed(key)
    --if key == "c" then
    --    self.craftingOpen = not self.craftingOpen
    --end
end

function crafting:mousepressed(x, y, button)
    local craftingX, craftingY, craftingWidth, craftingHeight = self:getCraftingBounds()
    local itemSize = self:getCraftingItemSize()
    local itemSpacing = self:getCraftingItemSpacing()
    local craftingColumns = self:getCraftingColumns()
    local craftingRows = 3
    local craftingPadding = itemSize * 0.2

    if self:isMouseInsideCraftingGrid(x, y, craftingX, craftingY, craftingWidth, craftingHeight) then
        self:handleCraftingGridClick(x, y, button, craftingX, craftingY, itemSize, itemSpacing, craftingPadding)
    else
        self.selectedItem = nil
    end

    self:handleCraftingResultClick(x, y, craftingX, craftingY, craftingWidth, craftingHeight, itemSize, itemSpacing)
end

function crafting:isMouseInsideCraftingGrid(x, y, craftingX, craftingY, craftingWidth, craftingHeight)
    return x >= craftingX and x <= craftingX + craftingWidth and y >= craftingY and y <= craftingY + craftingHeight
end

function crafting:handleCraftingGridClick(x, y, button, craftingX, craftingY, itemSize, itemSpacing, craftingPadding)
    local craftingColumns = self:getCraftingColumns()
    local craftingRows = 3

    for row = 1, craftingRows do
        for col = 1, craftingColumns do
            local slotX = craftingX + craftingPadding + (col - 1) * (itemSize + itemSpacing)
            local slotY = craftingY + craftingPadding + (row - 1) * (itemSize + itemSpacing)

            if self:isMouseInsideSlot(x, y, slotX, slotY, itemSize) then
                local index = (row - 1) * craftingColumns + col
                local clickedItem = self.player.craftingGrid[index]

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

function crafting:isMouseInsideSlot(x, y, slotX, slotY, itemSize)
    return x >= slotX and x <= slotX + itemSize and y >= slotY and y <= slotY + itemSize
end

function crafting:handleLeftClick(index, clickedItem)
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

function crafting:swapItems(index, clickedItem)
    local selectedIndex = self.selectedItem.index
    local selectedItem = self.player.craftingGrid[selectedIndex]
    self.player.craftingGrid[selectedIndex] = clickedItem
    self.player.craftingGrid[index] = selectedItem
    self.player.craftingGridOrder[selectedIndex] = clickedItem.item
    self.player.craftingGridOrder[index] = selectedItem.item
end

function crafting:moveSelectedItemToEmptySlot(index)
    local selectedIndex = self.selectedItem.index
    local selectedItem = self.player.craftingGrid[selectedIndex]
    self.player.craftingGrid[selectedIndex] = nil
    self.player.craftingGrid[index] = selectedItem
    self.player.craftingGridOrder[selectedIndex] = nil
    self.player.craftingGridOrder[index] = selectedItem.item
end

function crafting:selectItem(index, clickedItem)
    self.selectedItem = {item = clickedItem.item, index = index}
end

function crafting:handleRightClick(index, clickedItem)
    self:moveItemToInventory(clickedItem)
    self:removeItemFromCraftingGrid(index, clickedItem)
end

function crafting:moveItemToInventory(clickedItem)
    local inventory = self.player.inventory
    local inventoryOrder = self.player.inventoryOrder
    inventory[clickedItem.item] = clickedItem.quantity
    table.insert(inventoryOrder, clickedItem.item)
end

function crafting:removeItemFromCraftingGrid(index, clickedItem)
    self.player.craftingGrid[index] = nil
    for i, gridItem in ipairs(self.player.craftingGridOrder) do
        if gridItem == clickedItem.item then
            table.remove(self.player.craftingGridOrder, i)
            break
        end
    end
end

function crafting:handleCraftingResultClick(x, y, craftingX, craftingY, craftingWidth, craftingHeight, itemSize, itemSpacing)
    local resultSlotX = craftingX + craftingWidth + itemSpacing
    local resultSlotY = craftingY + craftingHeight / 2 - itemSize / 2

    if self:isMouseInsideSlot(x, y, resultSlotX, resultSlotY, itemSize) then
        -- Handle crafting result interaction
    end
end

function crafting:update()
    -- Convert the crafting grid items to a 2D array
    local craftingItems = {}
    for row = 1, 3 do
        craftingItems[row] = {}
        for col = 1, 3 do
            local index = (row - 1) * 3 + col
            local itemData = self.player.craftingGrid[index]
            if itemData then
                craftingItems[row][col] = itemData.item
            else
                craftingItems[row][col] = ""
            end
        end
    end

    -- Check if the crafting grid items match any recipe
    for _, recipe in ipairs(recipes) do
        local match = true
        for row = 1, 3 do
            for col = 1, 3 do
                local slotKey = "slot" .. ((row - 1) * 3 + col)
                if craftingItems[row][col] ~= recipe.input[row][slotKey] then
                    match = false
                    break
                end
            end
            if not match then
                break
            end
        end
        if match then
            self.selectedRecipe = recipe
            self.craftingResult = recipe.output
            return
        end
    end

    -- No matching recipe found
    self.selectedRecipe = nil
    self.craftingResult = nil
end
function crafting:draw(icon)
    local width, height = lg.getWidth(), lg.getHeight()

    local craftingRows = 3
    local hotbarWidth = width * 0.3
    local hotbarHeight = height * 0.07
    local itemSize = hotbarHeight * 0.8
    local cornerRadius = itemSize * 0.2
    local craftingPadding = itemSize * 0.2
    local itemSpacing = (hotbarWidth - itemSize * craftingRows) / (craftingRows - 1)
    
    local inventoryPadding = itemSize * 0.2
    local itemSpacing = self:getCraftingItemSpacing()
    local craftingColumns = self:getCraftingColumns()
    local inventoryWidth = craftingColumns * (itemSize + itemSpacing) - itemSpacing + inventoryPadding * 2
    local inventoryHeight = craftingRows * (itemSize + itemSpacing) - itemSpacing + inventoryPadding * 2
    
    local craftingWidth = craftingColumns * (itemSize + itemSpacing) - itemSpacing + craftingPadding * 2
    local craftingHeight = craftingRows * (itemSize + itemSpacing) - itemSpacing + craftingPadding * 2
    local craftingX = width * 0.74 - craftingWidth * 0.5
    local craftingY = height * 0.5 - craftingHeight * 0.5
        
    -- Draw crafting UI background
    lg.setColor(0.2, 0.2, 0.2, 0.8)
    lg.rectangle("fill", craftingX, craftingY, inventoryWidth, inventoryHeight, cornerRadius, cornerRadius)

    -- Draw crafting grid slots
    for row = 1, craftingRows do
        for col = 1, craftingColumns do
            local slotX = craftingX + craftingPadding + (col - 1) * (itemSize + itemSpacing)
            local slotY = craftingY + craftingPadding + (row - 1) * (itemSize + itemSpacing)
            
            local index = (row - 1) * craftingColumns + col -- Calculate the index here
            
            lg.setColor(0.3, 0.3, 0.3, 0.9)
            lg.rectangle("fill", slotX, slotY, itemSize, itemSize, cornerRadius, cornerRadius)
            lg.setColor(0.5, 0.5, 0.5, 0.9)
            lg.rectangle("line", slotX, slotY, itemSize, itemSize, cornerRadius, cornerRadius)
            
            --selected
            if self.selectedItem and index == self.selectedItem.index then
                lg.setColor(1, 1, 1, 0.5)
                lg.rectangle("fill", slotX, slotY, itemSize, itemSize, cornerRadius, cornerRadius)
            end

            --hover
            local mouseX, mouseY = love.mouse.getPosition()
            if mouseX >= slotX and mouseX <= slotX + itemSize and mouseY >= slotY and mouseY <= slotY + itemSize then
                lg.setBlendMode("add")
                lg.setColor(1, 1, 1, 1)
                lg.rectangle("line", slotX + 1, slotY + 1, itemSize - 2, itemSize - 2)
                lg.setColor(1, 1, 1, 0.1)
                lg.rectangle("fill", slotX + 1, slotY + 1, itemSize - 2, itemSize - 2)
                lg.setBlendMode("alpha")
            end
            
            -- Draw items in the crafting grid slots
            local itemData = self.player.craftingGrid[index] -- Retrieve the item directly from craftingGrid using the index
           
            if itemData then
                local item = itemData.item
                local quantity = itemData.quantity
                local quantityText = tostring(quantity)

                local textWidth = font.regular:getWidth(quantityText)
                local textHeight = font.regular:getHeight()
                local textX = slotX + itemSize - textWidth - itemSize * 0.1
                local textY = slotY + itemSize - textHeight - itemSize * 0.1
                lg.setColor(1, 1, 1)
                lg.draw(tileAtlas, tiles[icon[item]],  slotX + itemSize * 0.1, slotY + itemSize * 0.1, 0, itemSize * 0.8 / config.graphics.assetSize, itemSize * 0.8 / config.graphics.assetSize)
                
                lg.print(quantityText, textX, textY)
            end
        end
    end

    -- Draw crafting result slot
    local resultSlotX = craftingX + craftingWidth + itemSpacing
    local resultSlotY = craftingY + craftingHeight / 2 - itemSize / 2

    lg.setColor(0.3, 0.3, 0.3, 0.9)
    lg.rectangle("fill", resultSlotX, resultSlotY, itemSize, itemSize, cornerRadius, cornerRadius)
    lg.setColor(0.5, 0.5, 0.5, 0.9)
    lg.rectangle("line", resultSlotX, resultSlotY, itemSize, itemSize, cornerRadius, cornerRadius)    
    
    -- Draw crafting result item
    if self.craftingResult then
--        local quantity = itemData.quantity
        --local quantityText = tostring(quantity)
        lg.setColor(1, 1, 1)   
     
        lg.draw(tileAtlas, tiles[icon[self.craftingResult]],  resultSlotX + itemSize * 0.1, resultSlotY + itemSize * 0.1, 0, itemSize * 0.8 / config.graphics.assetSize, itemSize * 0.8 / config.graphics.assetSize)
       -- lg.print(quantityText, textX, textY)
    end
end

return crafting