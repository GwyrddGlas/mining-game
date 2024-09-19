local lg = love.graphics
local fs = love.filesystem
local kb = love.keyboard
local lm = love.mouse
local lt = love.thread
local joy = love.joystick
local noise = love.math.noise
local random = math.random
local sin = math.sin
local cos = math.cos
local min = math.min
local max = math.max
local f = string.format
local floor = math.floor

local gameControls = config.settings.gameControls

local function isJoystickButtonDown(button)
    local joysticks = joy.getJoysticks()
    for _, joystick in ipairs(joysticks) do
        if joystick:isDown(button) then
            return true
        end
    end
    return false
end

local function getJoystickAxis(axis)
    local joysticks = joy.getJoysticks()
    for _, joystick in ipairs(joysticks) do
        local value = joystick:getAxis(axis)
        if math.abs(value) > 0.2 then  -- Dead zone
            return value
        end
    end
    return 0
end

return {
    filter = function(e)
        return e.control or false
    end,

    process = function(e, dt)
        local right = kb.isDown(gameControls.right) or getJoystickAxis(1) > 0
        local left = kb.isDown(gameControls.left) or getJoystickAxis(1) < 0
        local down = kb.isDown(gameControls.down) or getJoystickAxis(2) > 0
        local up = kb.isDown(gameControls.up) or getJoystickAxis(2) < 0
        local space = kb.isDown(gameControls.sprint) or isJoystickButtonDown(1)
        local speed = e.speed

        if UI.active then
            return
        end

        if space then 
            if _PLAYER.stamina > 0 then
                speed = e.speed * 1.4 
                _PLAYER.stamina = _PLAYER.stamina - dt
            end
        else
            _PLAYER.stamina = min(_PLAYER.stamina + dt * 0.5, 10)
        end

        _PLAYER.magic = min(_PLAYER.magic + dt * 0.1, _PLAYER.magicCap)

        e.moving = false
        local xOffset = (e.collisonBoxWidth / 2)
        local nx, ny = e.x - xOffset, e.y 

        if not console.isOpen then
            local axisX = getJoystickAxis(1)
            local axisY = getJoystickAxis(2)
            
            if right or axisX > 0 then
                nx = nx + speed * dt * max(axisX, 1)
                e.moving = true
            elseif left or axisX < 0 then
                nx = nx + speed * dt * min(axisX, -1)
                e.moving = true
            end
            if down or axisY > 0 then
                ny = ny + speed * dt * max(axisY, 1)
                e.moving = true
            elseif up or axisY < 0 then
                ny = ny + speed * dt * min(axisY, -1)
                e.moving = true
            end
        end
            
        -- Collisions
        local fx, fy, col, len = e.bumpWorld:move(e, nx, ny)

        if not config.debug.playerCollision then
            fx, fy = nx, ny
        end

        if len > 0 then
            e.moving = false
        end
        e.x = fx + xOffset
        e.y = fy 

        e:updateGridCoordinates()

        e._SPATIAL.spatial:update_item_cell(e.x, e.y, e)
    end
}