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
        label = "Magic",
        icon = nil 
    },
    stamina = {
        backgroundColour = {0.2, 0.2, 0.2, 0.8},  -- Dark grey
        fillColour = {0, 0.6, 0.2, 1},           -- Bright green
        label = "Stamina",
        icon = nil
    },
    time = {
        backgroundColour = {0.1, 0.1, 0.1, 0.8},  -- Dark background
        fillColour = {1, 1, 1, 1},               -- White 
        label = "Time",
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

local function lerpColor(color1, color2, t)
    return {
        color1[1] + (color2[1] - color1[1]) * t,
        color1[2] + (color2[2] - color1[2]) * t,
        color1[3] + (color2[3] - color1[3]) * t,
        color1[4] + (color2[4] - color1[4]) * t
    }
end

local function getTimeOfDayColor(time)
    -- Normalize time to a 24-hour cycle (0 to 1)
    local normalizedTime = time % 24 / 24

    -- Define color transitions
    local sunriseColor = {1, 0.8, 0.4, 1}  -- Orange-yellow (sunrise)
    local dayColor = {0.6, 0.8, 1, 1}      -- Light blue (daytime)
    local sunsetColor = {1, 0.4, 0.2, 1}   -- Red-orange (sunset)
    local nightColor = {0.1, 0.1, 0.3, 1}  -- Dark blue (nighttime)

    -- Interpolate colors based on time
    if normalizedTime < 0.25 then
        -- Sunrise to daytime
        return lerpColor(sunriseColor, dayColor, normalizedTime / 0.25)
    elseif normalizedTime < 0.5 then
        -- Daytime to sunset
        return lerpColor(dayColor, sunsetColor, (normalizedTime - 0.25) / 0.25)
    elseif normalizedTime < 0.75 then
        -- Sunset to nighttime
        return lerpColor(sunsetColor, nightColor, (normalizedTime - 0.5) / 0.25)
    else
        -- Nighttime to sunrise
        return lerpColor(nightColor, sunriseColor, (normalizedTime - 0.75) / 0.25)
    end
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

    if barType == "time" then
        local timeColor = getTimeOfDayColor(value)
        local gradient = createSmoothGradientMesh(fillWidth, height, timeColor)
        lg.setColor(1, 1, 1, 1)
        lg.draw(gradient, x, y)
    else
        local gradient = createSmoothGradientMesh(fillWidth, height, config.fillColour)
        lg.setColor(1, 1, 1, 1)
        lg.draw(gradient, x, y)
    end

    lg.setStencilTest()

    -- Draw outline
    lg.setColor(0.1, 0.1, 0.1, 1)
    lg.setLineWidth(2)
    lg.rectangle("line", x, y, width, height, cornerRadius, cornerRadius)

    -- Draw label
    lg.setFont(font.tiny)
    local label = string.format("%s: %d/%d", config.label, value, maxValue)
    local labelTime = string.format("%s: %02d:00", config.label, value % 24) 
    local labelWidth = font.tiny:getWidth(label)
    local labelX = x + 10 
    local labelY = y + (height - font.tiny:getHeight()) / 2

    lg.setColor(1, 1, 1, 1)

    if barType == "time" then
        lg.print(labelTime, labelX, labelY)
    else
        lg.print(label, labelX, labelY)
    end

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
    statusBars.drawBar(x, y + (barHeight + spacing) * 3, width, barHeight, player.time, 24, "time") 
end

return statusBars