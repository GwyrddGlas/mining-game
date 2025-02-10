local lg = love.graphics

local minimap = {}

local minimapRadius = 125
local minimapScale = 8

-- Enhanced color palette for the minimap
local miniMapColors = {
    {0.2, 0.2, 0.2, 1},        -- 0: Black (Wall)
    {0.65, 0.65, 0.7, 1},      -- 1: Light Gray (Stone)
    {0.7, 0.5, 0.3, 1},        -- 2: Brown (Shrub)
    {102/255, 123/255, 13/255, 1},        -- 3: Dark Brown (Coal)
    {0.7529, 0.7529, 0.7529, 1}, -- 4: Silver (Tanzenite)
    {1.0, 0.8, 0.2, 1},        -- 5: Gold (Gold)
    {1.0, 0.5, 0.2, 1},          -- 6: Blue (Uranium)
    {0, 1, 0, 1},            -- 7: Red (Ruby)
    {0.8, 0.2, 0.2, 1},        -- 8: Dark Red (Unknown)
    {0.2, 0, 0.8, 1},          -- 9: Purple (Diamond)
    {0, 0.2, 0.8, 1},        -- 10: Orange (Copper)
    {0.8588, 0.3765, 0.0784, 1},        -- 11: Yellow-Green (Copper actual)
    {1, 1, 1, 1},              -- 12: White (Unused)
    {1, 1, 1, 1},              -- 13: White (Unused)
    {1, 1, 1, 1},              -- 14: White (Unused)
    {102/255, 123/255, 13/255, 1}, -- 15: Grass (Green)
}

-- Helper function to create a smooth gradient
local function createGradientMesh(width, height, color)
    return lg.newMesh({
        {0, 0, 0, 0, color[1], color[2], color[3], color[4]},
        {width, 0, 1, 0, color[1] * 0.8, color[2] * 0.8, color[3] * 0.8, color[4]},
        {width, height, 1, 1, color[1] * 0.6, color[2] * 0.6, color[3] * 0.6, color[4]},
        {0, height, 0, 1, color[1] * 0.4, color[2] * 0.4, color[3] * 0.4, color[4]}
    }, "fan")
end

-- Draw a drop shadow for depth
local function drawDropShadow(x, y, radius, shadowColor, offset)
    lg.setColor(shadowColor)
    lg.circle("fill", x + offset, y + offset, radius)
end

-- Draw a glowing effect
local function drawGlow(x, y, radius, color)
    lg.setColor(color)
    for i = 1, 3 do
        lg.circle("line", x, y, radius + i, 32)
    end
end

function minimap:draw(player, all, camera, position)
    position = position or "left"
    
    local screenWidth = lg.getWidth()
    local screenHeight = lg.getHeight()
    local padding = 30
    local minimapX, minimapY
    
    if position == "left" then
        minimapX = minimapRadius + padding
        minimapY = minimapRadius + padding
    else -- "right"
        minimapX = screenWidth - minimapRadius - padding
        minimapY = minimapRadius + padding
    end

    -- Draw drop shadow
    drawDropShadow(minimapX, minimapY, minimapRadius, {0, 0, 0, 0.5}, 2)

    -- Draw minimap background
    lg.setColor(0.1, 0.1, 0.1, 0.8)
    lg.circle("fill", minimapX, minimapY, minimapRadius)

    -- Draw minimap outline
    lg.setColor(1, 1, 1, 0.8)
    lg.setLineWidth(2)
    lg.circle("line", minimapX, minimapY, minimapRadius)

    -- Draw compass points
    local compassColor = {1, 1, 1, 0.8}
    local compassOffset = minimapRadius + 20
    lg.setColor(compassColor)
    lg.setFont(font.tiny)
    lg.print("N", minimapX - 5, minimapY - compassOffset - 15)
    lg.print("S", minimapX - 5, minimapY + compassOffset - 15)
    lg.print("W", minimapX - compassOffset - 12, minimapY - 7)
    lg.print("E", minimapX + compassOffset - 7, minimapY - 7)

    -- Draw minimap coordinates
    lg.setColor(1, 1, 1, 1)
    lg.setFont(font.tiny)
    local xText = string.format("x: %i", player.gridX)
    local xTextWidth = lg.getFont():getWidth(xText)
    local xTextX = minimapX - minimapRadius
    local xTextY = minimapY + minimapRadius + 15 
    lg.print(xText, xTextX, xTextY)
    
    local yText = string.format("y: %i", player.gridY)
    local yTextWidth = lg.getFont():getWidth(yText)
    local yTextX = minimapX + minimapRadius - yTextWidth
    local yTextY = minimapY + minimapRadius + 15
    lg.print(yText, yTextX, yTextY)    

    -- Set circular stencil
    lg.stencil(function()
        lg.circle("fill", minimapX, minimapY, minimapRadius - 2)
    end, "replace", 1)
    lg.setStencilTest("greater", 0)
    
    -- Draw tiles
    for i, v in ipairs(all) do
        if v.entityType == "tile" then
            local tileType = tonumber(v.type)
            if tileType and miniMapColors[tileType] then
                local color = miniMapColors[tileType]
                lg.setColor(color[1], color[2], color[3], color[4])
                lg.rectangle(
                    "fill",
                    minimapX + (v.gridX - player.gridX) * minimapScale,
                    minimapY + (v.gridY - player.gridY) * minimapScale,
                    minimapScale,
                    minimapScale
                )
            end
        elseif v.entityType == "player" then
            -- Draw player indicator with a glowing effect
            lg.setColor(0, 1, 0, 1)
            drawGlow(minimapX, minimapY, 5, {0, 1, 0, 0.5})
            lg.rectangle(
                "fill",
                minimapX - minimapScale / 2,
                minimapY - minimapScale / 2,
                minimapScale,
                minimapScale
            )
        end
    end
    
    -- Reset stencil test
    lg.setStencilTest()

    -- Draw player direction indicator
    local directionLength = 15
    local mx, my = camera:getMouse()
    local playerAngle = math.atan2(my - player.y, mx - player.x)
    lg.setColor(1, 1, 1, 0.8)
    lg.setLineWidth(2)
    lg.line(
        minimapX,
        minimapY,
        minimapX + math.cos(playerAngle) * directionLength,
        minimapY + math.sin(playerAngle) * directionLength
    )
    
    lg.setLineWidth(1)
end

return minimap