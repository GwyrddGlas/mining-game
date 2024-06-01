local inventory = require("src.class.inventory")

local crafting = {}

function crafting:new(player)
    local craft = setmetatable({}, {__index = crafting})
    craft.player = player
    craft.craftingOpen = false
    craft.selectedRecipe = nil
    craft.craftingGrid = {}
    craft.craftingResult = nil
    craft.recipes = {
        --temp
        {"Wood", "Wood", "Stick"},
        {"Stone", "Stone", "Cobblestone"},
    }
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

function crafting:keypressed(key)
    if key == "c" then
        self.craftingOpen = not self.craftingOpen
    end
end

function crafting:mousepressed(x, y, button)
    if not self.craftingOpen then
        return
    end

    local craftingX, craftingY, craftingWidth, craftingHeight = self:getCraftingBounds()
    local itemSize = self:getCraftingItemSize()
    local itemSpacing = self:getCraftingItemSpacing()
    local craftingColumns = self:getCraftingColumns()
    local craftingRows = 3
    local craftingPadding = itemSize * 0.2

    if x >= craftingX and x <= craftingX + craftingWidth and y >= craftingY and y <= craftingY + craftingHeight then
        for row = 1, craftingRows do
            for col = 1, craftingColumns do
                local slotX = craftingX + craftingPadding + (col - 1) * (itemSize + itemSpacing)
                local slotY = craftingY + craftingPadding + (row - 1) * (itemSize + itemSpacing)
                if x >= slotX and x <= slotX + itemSize and y >= slotY and y <= slotY + itemSize then
                    local index = (row - 1) * craftingColumns + col
                    -- Handle crafting grid interaction
                end
            end
        end
    end

    -- Check if the mouse is clicked on the crafting result slot
    local resultSlotX = craftingX + craftingWidth + itemSpacing
    local resultSlotY = craftingY + craftingHeight / 2 - itemSize / 2
    if x >= resultSlotX and x <= resultSlotX + itemSize and y >= resultSlotY and y <= resultSlotY + itemSize then
        -- Handle crafting result interaction
    end
end

function crafting:update()
    if not self.craftingOpen then
        return
    end

    -- Check if the items in the crafting grid match any recipe
    for _, recipe in ipairs(self.recipes) do
        local matchCount = 0
        for i = 1, 9 do
            if self.craftingGrid[i] == recipe[i] then
                matchCount = matchCount + 1
            end
        end
        if matchCount == 9 then
            self.selectedRecipe = recipe
            self.craftingResult = recipe[10]
            break
        else
            self.selectedRecipe = nil
            self.craftingResult = nil
        end
    end
end

function crafting:draw()
    if not self.craftingOpen then
        return
    end
    --TODO: optimise and clean up
    local width, height = lg.getWidth(), lg.getHeight()

    local craftingRows = 3
    local hotbarWidth = width * 0.3
    local hotbarHeight = height * 0.07
    local itemSize = hotbarHeight * 0.8
    local cornerRadius = itemSize * 0.2
    local craftingPadding = itemSize * 0.2
    --local craftingX, craftingY, craftingWidth, craftingHeight = self:getCraftingBounds()
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
            
            lg.setColor(0.3, 0.3, 0.3, 0.9)
            lg.rectangle("fill", slotX, slotY, itemSize, itemSize, cornerRadius, cornerRadius)
            lg.setColor(0.5, 0.5, 0.5, 0.9)
            lg.rectangle("line", slotX, slotY, itemSize, itemSize, cornerRadius, cornerRadius)
            
            -- Draw items in the crafting grid slots
            local index = (row - 1) * craftingColumns + col
            local item = self.craftingGrid[index]
            if item then
                lg.setColor(1, 1, 1)
                lg.print(item, slotX + itemSize * 0.1, slotY + itemSize * 0.1)
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
        lg.setColor(1, 1, 1)
        lg.print(self.craftingResult, resultSlotX + itemSize * 0.1, resultSlotY + itemSize * 0.1)
    end
end

return crafting