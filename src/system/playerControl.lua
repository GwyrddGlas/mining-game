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
local gameControls = config.settings.gameControls

return {
    filter = function(e)
        return e.control or false
    end,

    process = function(e, dt)
        local right = kb.isDown(gameControls.right)
        local left = kb.isDown(gameControls.left)
        local down = kb.isDown(gameControls.down)
        local up = kb.isDown(gameControls.up)
        local space = kb.isDown(gameControls.sprint)
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
            _PLAYER.stamina = math.min(_PLAYER.stamina + dt * 0.5, 10)
        end

        _PLAYER.magic = math.min(_PLAYER.magic + dt * 0.1, _PLAYER.magicCap)

        e.moving = false
        local xOffset = (e.collisonBoxWidth / 2)
        local nx, ny = e.x - xOffset, e.y 

        if not console.isOpen then
            if right then
                nx = nx + speed * dt
                e.moving = true
            elseif left then
                nx = nx - speed * dt
                e.moving = true
            end
            if down then
                ny = ny + speed * dt
                e.moving = true
            elseif up then
                ny = ny - speed * dt
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