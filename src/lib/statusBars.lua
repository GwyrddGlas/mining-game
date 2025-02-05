local lg = love.graphics

local statusBars = {}

local barConfigs = {
    health = {
        backgroundColour = {0.2, 0.2, 0.2, 0.8},  -- Dark grey
        fillColour = {0.8, 0.1, 0.1, 1},         -- Bright red
        label = "Health",
        icon = nil 
    },
    magic = {
        backgroundColour = {0.1, 0.05, 0.2, 0.8}, -- Dark purple
        fillColour = {0.1, 0.5, 0.8, 1},         -- Bright blue
        label = "Conjuration",
        icon = nil 
    },
    stamina = {
        backgroundColour = {0.2, 0.2, 0.2, 0.8},  -- Dark grey
        fillColour = {0, 0.6, 0.2, 1},           -- Bright green
        label = "Stamina",
        icon = nil
    }
}

local function createSmoothGradientMesh(width, height, color)
    return lg.newMesh({
        {0, 0, 0, 0, color[1], color[2], color[3], color[4]},
        {width, 0, 1, 0, color[1] * 0.8, color[2] * 0.8, color[3] * 0.8, color[4]},
        {width, height, 1, 1, color[1] * 0.6, color[2] * 0.6, color[3] * 0.6, color[4]},
        {0, height, 0, 1, color[1] * 0.4, color[2] * 0.4, color[3] * 0.4, color[4]}
    }, "fan")
end

local function drawDropShadow(x, y, width, height, radius, shadowColor, offset)
    lg.setColor(shadowColor)
    lg.rectangle("fill", x + offset, y + offset, width, height, radius, radius)
end

function statusBars.drawBar(x, y, width, height, value, maxValue, barType)
    local config = barConfigs[barType]
    if not config then
        error("Invalid bar type: " .. tostring(barType))
    end

    local cornerRadius = 5
    local percentage = value / maxValue
    local fillWidth = width * percentage

    -- Draw drop shadow
    drawDropShadow(x, y, width, height, cornerRadius, {0, 0, 0, 0.3}, 2)

    -- Draw background
    lg.setColor(config.backgroundColour)
    lg.rectangle("fill", x, y, width, height, cornerRadius, cornerRadius)

    -- Draw fill with smooth gradient
    lg.stencil(function()
        lg.rectangle("fill", x, y, width, height, cornerRadius, cornerRadius)
    end, "replace", 1)

    lg.setStencilTest("greater", 0)
    local gradient = createSmoothGradientMesh(fillWidth, height, config.fillColour)
    lg.setColor(1, 1, 1, 1)
    lg.draw(gradient, x, y)
    lg.setStencilTest()

    -- Draw outline
    lg.setColor(0.1, 0.1, 0.1, 1)
    lg.setLineWidth(2)
    lg.rectangle("line", x, y, width, height, cornerRadius, cornerRadius)

    -- Draw label
    lg.setFont(font.tiny)
    local label = string.format("%s: %d/%d", config.label, value, maxValue)
    local labelWidth = font.tiny:getWidth(label)
    local labelX = x + 10 
    local labelY = y + (height - font.tiny:getHeight()) / 2
    lg.setColor(1, 1, 1, 1)
    lg.print(label, labelX, labelY)

    if config.icon then
        local icon = love.graphics.newImage(config.icon)
        local iconSize = height * 0.8
        lg.draw(icon, x + width - iconSize - 10, y + (height - iconSize) / 2, 0, iconSize / icon:getWidth(), iconSize / icon:getHeight())
    end
end

function statusBars.drawAllBars(player, x, y, width, spacing)
    local barHeight = 25
    statusBars.drawBar(x, y, width, barHeight, player.health, 10, "health")
    statusBars.drawBar(x, y + barHeight + spacing, width, barHeight, player.magic, player.magicCap, "magic")
    statusBars.drawBar(x, y + (barHeight + spacing) * 2, width, barHeight, player.stamina, 10, "stamina")
end

return statusBars