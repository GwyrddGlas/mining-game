local inventory = {}
local crafting = require("src/class/crafting")

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
local joy = love.joystick

local colors = {
    inventoryBackground = {30, 30, 40, 220},      -- Dark gray with slight transparency
    hotbarBackground = {40, 40, 50, 220},         -- Slightly lighter dark gray
    defaultSlot = {60, 60, 70, 200},              -- Default slot color
    hoveredSlot = {100, 150, 255, 200},           -- Light blue for hovered slots
    selectedSlot = {255, 200, 100, 200},          -- Gold for selected slots
    itemNameText = {255, 255, 255},               -- White text for item names
    itemNameBackground = {0, 0, 0, 150},          -- Semi-transparent black for item name backgrounds
    quantityText = {255, 255, 255},               -- White text for quantities
    defaultBorder = {80, 80, 90, 200},            -- Default border color
    highlightedBorder = {255, 100, 150, 200},     -- Pink for highlighted borders
}

local function setColor(r, g, b, a)
    if type(r) == "table" then
        r, g, b, a = r[1], r[2], r[3], r[4]
    end
    a = a or 255
    lg.setColor(r/255, g/255, b/255, a/255)
end

-- Draw a drop shadow for depth
local function drawDropShadow(x, y, width, height, radius, shadowColor, offset)
    lg.setColor(shadowColor)
    lg.rectangle("fill", x + offset, y + offset, width, height, radius, radius)
end

local function isJoystickButtonDown(button)
    local joysticks = love.joystick.getJoysticks()
    for _, joystick in ipairs(joysticks) do
        if joystick:isDown(button) then
            return true
        end
    end
    return false
end

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
    local inventoryRows, inventoryColumns = 4, 4
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
    return 4
end

function inventory:getInventoryItemAtIndex(index)
    return self.player.inventoryOrder[index]
end

function inventory:swapInventoryItems(item1, item2)
    if not item1 or not item2 or item1 == item2 then
        return
    end

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
    
    if index1 and index2 then
        inventoryOrder[index1], inventoryOrder[index2] = inventoryOrder[index2], inventoryOrder[index1]
    end
end

function inventory:removeItemFromInventory(item)
    local itemName = type(item) == "number" and convertIconToName(item) or item
    
    if self.player.inventory[itemName] then
        self.player.inventory[itemName] = self.player.inventory[itemName] - 1
        
        if self.player.inventory[itemName] <= 0 then
            self.player.inventory[itemName] = nil
            for i, inventoryItem in ipairs(self.player.inventoryOrder) do
                if inventoryItem == itemName then
                    table.remove(self.player.inventoryOrder, i)
                    break
                end
            end
        end
    end
end

function inventory:giveItem(item, quantity)
    if not type(item) == "string" then
        return
    end

    quantity = quantity or 1
    item = item:gsub("^%l", string.upper)

    if not self.player.inventory[item] then
        self.player.inventory[item] = 0
        table.insert(self.player.inventoryOrder, item)
    end
    self.player.inventory[item] = math.max(0, (self.player.inventory[item] or 0) + quantity)
    
    if self.player.inventory[item] == 0 then
        self:removeItemFromInventory(item)
    end
end

function inventory:toggleInventory()
    self.inventoryOpen = not self.inventoryOpen
end 

function inventory:moveInventoryItemToIndex(item, newIndex)
    local inventoryOrder = self.player.inventoryOrder
    local oldIndex
    
    for i, existingItem in ipairs(inventoryOrder) do
        if existingItem == item then
            oldIndex = i
            break
        end
    end
    
    if oldIndex and oldIndex ~= newIndex then
        table.remove(inventoryOrder, oldIndex)
        table.insert(inventoryOrder, newIndex, item)
    end
end

function inventory:gamepadpressed(joystick, button)
    if button == "y" and not console.isOpen and not UI.active then
        self:toggleInventory()
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
    local inventoryRows = 4
    local inventoryPadding = itemSize * 0.2
    local clickedIndex = nil
    
    -- Check if the click is within the inventory bounds
    if x >= inventoryX and x <= inventoryX + inventoryWidth and y >= inventoryY and y <= inventoryY + inventoryHeight then
        for row = 1, inventoryRows do
            for col = 1, inventoryColumns do
                local slotX = inventoryX + inventoryPadding + (col - 1) * (itemSize + itemSpacing)
                local slotY = inventoryY + inventoryPadding + (row - 1) * (itemSize + itemSpacing)
                if x >= slotX and x < slotX + itemSize + itemSpacing and 
                   y >= slotY and y < slotY + itemSize + itemSpacing then
                    clickedIndex = (row - 1) * inventoryColumns + col
                    break
                end
            end
            if clickedIndex then break end
        end
    end

    -- Handle the click
    if clickedIndex then
        local clickedItem = self:getInventoryItemAtIndex(clickedIndex)
        if button == 1 then
            if self.selectedItem then
                if clickedItem then
                    self:swapInventoryItems(self.selectedItem, clickedItem)
                else
                    self:moveInventoryItemToIndex(self.selectedItem, clickedIndex)
                end
                self.selectedItem = nil
            else
                self.selectedItem = clickedItem
            end
        end
    else
        self.selectedItem = nil
    end
end

function inventory:keypressed(key)
    local gameControls = config.settings.gameControls

    if key == gameControls.inventory and not console.isOpen and not UI.active then
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
    local maxHotbarItems = 8
    local itemSpacing = itemSize * 0.2
    local cornerRadius = 5 

    local hotbarPadding = itemSize * 0.08 
    local totalHotbarWidth = (itemSize + itemSpacing) * maxHotbarItems - itemSpacing + hotbarPadding * 2

    -- Center the hotbar horizontally
    local hotbarBackgroundX = hotbarX - totalHotbarWidth * 0.5
    local hotbarBackgroundY = hotbarY

    -- Draw hotbar background
    drawDropShadow(hotbarBackgroundX, hotbarBackgroundY, totalHotbarWidth, hotbarHeight, cornerRadius, {0, 0, 0, 0.5}, 2)
    setColor(colors.hotbarBackground)
    lg.rectangle("fill", hotbarBackgroundX, hotbarBackgroundY, totalHotbarWidth, hotbarHeight, cornerRadius, cornerRadius)

    -- Calculate the starting position for the items
    local itemX = hotbarBackgroundX + hotbarPadding
    local itemY = hotbarBackgroundY + (hotbarHeight - itemSize) * 0.5

    local selectedIndex = self.selectedIndex

    for i = 1, maxHotbarItems do
        local x = itemX + (i - 1) * (itemSize + itemSpacing)
        local y = itemY
    
        -- Draw item slot
        if i == selectedIndex then
            setColor(colors.selectedSlot)
        else
            setColor(colors.defaultSlot)
        end

        -- Draw item slot border
        if i == selectedIndex then
            setColor(colors.highlightedBorder)
            lg.setLineWidth(3)
        else
            setColor(colors.defaultBorder)
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
                    lg.setColor(1, 1, 1, 1)
                    lg.draw(tileAtlas, tiles[self.icon[item]], x + itemSize * 0.1, y + itemSize * 0.1, 0, itemSize * 0.8 / config.graphics.assetSize, itemSize * 0.8 / config.graphics.assetSize)
                    
                    lg.setFont(font.regular)
                    local quantityText = tostring(quantity)
                    local textWidth = font.regular:getWidth(quantityText)
                    local textHeight = font.regular:getHeight()
                    local textX = x + itemSize - textWidth - itemSize * 0.1
                    local textY = y + itemSize - textHeight - itemSize * 0.1
    
                    setColor(colors.quantityText)
                    lg.print(quantityText, textX, textY)
                end
            end
        end
    end
    lg.setColor(1, 1, 1, 1)
end

function inventory:draw(icon, itemSize, itemSpacing, cornerRadius, maxHotbarItems)
    if not self.inventoryOpen then
        return 
    end

    local inventoryRows = 4
    local inventoryColumns = maxHotbarItems
    local inventoryPadding = itemSize * 0.2
    local width, height = lg.getWidth(), lg.getHeight()
    local inventoryWidth = inventoryColumns * (itemSize + itemSpacing) - itemSpacing + inventoryPadding * 2
    local inventoryHeight = inventoryRows * (itemSize + itemSpacing) - itemSpacing + inventoryPadding * 2
    local inventoryX = width * 0.5 - inventoryWidth * 0.5
    local inventoryY = height * 0.5 - inventoryHeight * 0.5
    
    -- Inventory background
    setColor(colors.inventoryBackground)
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

            -- Default slot color
            setColor(colors.defaultSlot)
            lg.rectangle("fill", x, y, itemSize, itemSize, cornerRadius, cornerRadius)

            -- Highlight selected item
            if item == self.selectedItem then
                setColor(colors.selectedSlot)
                lg.setLineWidth(3)
                lg.rectangle("line", x, y, itemSize, itemSize, cornerRadius, cornerRadius)
                lg.setLineWidth(1)
            end

            if item then
                local quantity = self.player.inventory[item]
                
                if icon[item] then
                    if tileAtlas and tiles[icon[item]] then
                        lg.setColor(1, 1, 1, 1) 
                        lg.draw(tileAtlas, tiles[icon[item]], x + itemSize * 0.1, y + itemSize * 0.1, 0, itemSize * 0.8 / config.graphics.assetSize, itemSize * 0.8 / config.graphics.assetSize)

                        lg.setFont(font.regular)
                        local quantityText = tostring(quantity)
                        local textWidth = font.regular:getWidth(quantityText)
                        local textHeight = font.regular:getHeight()
                        local textX = x + itemSize - textWidth - itemSize * 0.1
                        local textY = y + itemSize - textHeight - itemSize * 0.1

                        setColor(colors.quantityText)
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

                setColor(colors.highlightedBorder)
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