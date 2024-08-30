local lg = love.graphics

local minimap = {}

local minimapRadius = 125
local minimapScale = 8

local miniMapColors = {
    {0.2, 0.2, 0.2, 1},    -- 0: Black (Wall)
    {0.65, 0.65, 0.7, 1},  -- 1: Light Gray (Stone)
    {0.7, 0.5, 0.3, 1},    -- 2: Brown (Shrub)
    {0.1, 0.1, 0.1, 1},    -- 3: Brown (Coal)
    {0.7529, 0.7529, 0.7529, 1}, -- 4: Silver (Tanzenite)
    {1.0, 1.8, 0.2, 1},    -- 5: Yellow (Gold)
    {0, 0.2, 0.8, 1},      -- 6: Green (Uranium)
    {1, 0.2, 0, 1},        -- 8: Purple (Unknown)
    {0.8, 0.2, 0.2, 1},    -- 7: Red (Ruby)
    {0.2, 0, 0.8, 1},      -- 9: Cyan (Diamond)
    {1.0, 0.5, 0.2, 1},    -- 10: Orange (Copper)
    {0.8, 0.8, 0.2, 1},    -- 11: Yellow-Green (Uranium)
    {1, 1, 1, 1},          -- 12: 
    {1, 1, 1, 1},          -- 13: 
    {1, 1, 1, 1},          -- 14: 
    {102/255, 123/255, 13/255, 1}, -- 15: Grass (Green)
}

local function atan2(y, x)
    if x > 0 then
        return math.atan(y/x)
    elseif x < 0 and y >= 0 then
        return math.atan(y/x) + math.pi
    elseif x < 0 and y < 0 then
        return math.atan(y/x) - math.pi
    elseif x == 0 and y > 0 then
        return math.pi/2
    elseif x == 0 and y < 0 then
        return -math.pi/2
    else -- x == 0 and y == 0
        return 0
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

    lg.setColor(0.1, 0.1, 0.1, 0.8)
    lg.circle("fill", minimapX, minimapY, minimapRadius)
    
    lg.setColor(102/255, 104/255, 133/255) 
    lg.setLineWidth(3)
    lg.circle("line", minimapX, minimapY, minimapRadius)
    
    lg.setLineWidth(5) 
    lg.circle("line", minimapX, minimapY, minimapRadius + 2) 

    -- Draw compass points
    local compassColor = {1,1,1}
    local compassOffset = minimapRadius + 20
    lg.setColor(compassColor)
    lg.setFont(font.regular)
    lg.print("N", minimapX - 5, minimapY - compassOffset - 15)
    lg.print("S", minimapX - 5, minimapY + compassOffset - 15)
    lg.print("W", minimapX - compassOffset - 7, minimapY - 7)
    lg.print("E", minimapX + compassOffset - 7, minimapY - 7)
    
    -- Draw minimap coordinates
    lg.setColor(1, 1, 1, 1)
    lg.setFont(font.tiny)
    local xText = string.format("x: %i", player.gridX)
    local xTextWidth = lg.getFont():getWidth(xText)
    local xTextX = minimapX - minimapRadius
    local xTextY = minimapY + minimapRadius + 15 
    lg.print(xText, xTextX, xTextY)
    
    -- Draw y-coordinate
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
    
    local playerColor = {0, 1, 0, 1}
    local playerSize = minimapScale
    
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
            lg.setColor(playerColor[1], playerColor[2], playerColor[3], playerColor[4])
            lg.rectangle(
                "fill",
                minimapX - playerSize / 2,
                minimapY - playerSize / 2,
                playerSize,
                playerSize
            )
        end
    end
    
    -- Reset stencil test
    lg.setStencilTest()

    -- Draw player direction indicator
    local directionLength = 15
    local mx, my = camera:getMouse()
    local playerAngle = atan2(my - player.y, mx - player.x)
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