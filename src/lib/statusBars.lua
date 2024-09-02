local lg = love.graphics

local statusBars = {}

local barConfigs = {
    health = {
        backgroundColour = {0.2, 0.2, 0.2, 0.8},
        fillColour = {0.6, 0.1, 0.1, 1},
        label = "Health"
    },
    magic = {
        backgroundColour = {0.1, 0.05, 0.2, 0.8},
        fillColour = {0.1, 0.3, 0.6, 1},
        label = "Conjuration"
    },
    stamina = {
        backgroundColour = {0.2, 0.2, 0.2, 0.8},
        fillColour = {0, 0.3, 0.2, 1},
        label = "Stamina"
    }    
}

local function createGradientMesh(width, height, color)
    return lg.newMesh({
        {0, 0, 0, 0, color[1], color[2], color[3], color[4]},
        {width, 0, 1, 0, color[1], color[2], color[3], color[4]},
        {width, height, 1, 1, color[1] * 1.2, color[2] * 1.2, color[3] * 1.2, color[4]},
        {0, height, 0, 1, color[1] * 1.2, color[2] * 1.2, color[3] * 1.2, color[4]}
    }, "fan")
end

function statusBars.drawBar(x, y, width, height, value, maxValue, barType)
    local config = barConfigs[barType]
    if not config then
        error("Invalid bar type: " .. tostring(barType))
    end

    local cornerRadius = height * 0.2
    local percentage = value / maxValue
    local fillWidth = width * percentage

    lg.setColor(config.backgroundColour)
    lg.rectangle("fill", x, y, width, height, cornerRadius, cornerRadius)

    -- Create stencil for rounded fill bar
    lg.stencil(function()
        lg.rectangle("fill", x, y, width, height, cornerRadius, cornerRadius)
    end, "replace", 1)

    lg.setStencilTest("greater", 0)

    local gradient = createGradientMesh(fillWidth, height, config.fillColour)
    lg.setColor(1, 1, 1, 1)
    lg.draw(gradient, x, y)

    lg.setStencilTest()

    lg.setColor(1, 1, 1, 1)
    lg.rectangle("line", x, y, width, height, cornerRadius, cornerRadius)

    lg.setFont(font.tiny)
    local label = string.format("%s: %d/%d", config.label, value, maxValue)
    local labelWidth = font.tiny:getWidth(label)
    local labelX = x + (width - labelWidth) / 2
    local labelY = y + (height - font.tiny:getHeight()) / 2
    lg.setColor(1, 1, 1, 1)
    lg.print(label, labelX, labelY)
end

function statusBars.drawAllBars(player, x, y, width, spacing)
    local barHeight = 20
    statusBars.drawBar(x, y, width, barHeight, player.health, 10, "health")
    statusBars.drawBar(x, y + barHeight + spacing, width, barHeight, player.magic, player.magicCap, "magic")
    statusBars.drawBar(x, y + (barHeight + spacing) * 2, width, barHeight, player.stamina, 10, "stamina")
end

return statusBars