-- colorPicker.lua

local colorPicker = {}

local selectedcolor, bordercolor = {0, 0, 0}, {50, 50, 50}
local x, y, c_x, c_y = 0, 0, 150, 150
local radius = 25
local getcopy = false
local pallet, palletd, palletw, palleth, prevx, hand
local keyrgb, keyhex = "c", "h"

local set = love.graphics.setColor
local prints = love.graphics.print
local rec = love.graphics.rectangle
local cir = love.graphics.circle

local function setpallet(x, y)
    local r, g, b = palletd:getPixel(x, y)
    selectedcolor = {r, g, b}
end

local function rgbtohex(selected)
    local hex = {}
    for i, color in ipairs(selected) do
        color = string.format("%X", color * 256) --hexadecimal format or "x = lowercase"
        hex[i] = string.format("%02s", string.sub(color, 1, 2)) --min 00 strings
    end
    return table.concat(hex)
end

function colorPicker.load(imagePath)
    palletd = love.image.newImageData(imagePath) --pallet 300px
    palletw, palleth = palletd:getDimensions()
    pallet = love.graphics.newImage(palletd)
    prevx = palletw + 50
    hand = love.mouse.getSystemCursor("hand")
end

function colorPicker.update(dt)
    if love.mouse.isDown(1) then
        istouch = true
    else
        istouch = nil
    end

    if love.keyboard.isDown("up") then
        c_y = c_y > 1 and c_y - 1 or 1
        setpallet(c_x, c_y)
    elseif love.keyboard.isDown("down") then
        c_y = c_y < palleth - 1 and c_y + 1 or palleth - 1
        setpallet(c_x, c_y)
    elseif love.keyboard.isDown("left") then
        c_x = c_x > 1 and c_x - 1 or 1
        setpallet(c_x, c_y)
    elseif love.keyboard.isDown("right") then
        c_x = c_x < palletw - 1 and c_x + 1 or palletw - 1
        setpallet(c_x, c_y)
    end

    getcopy = (love.system.getClipboardText() == "(" .. table.concat(selectedcolor, ",") .. ")" or love.system.getClipboardText() == rgbtohex(selectedcolor)) and true or false
end

function colorPicker.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == keyrgb or key == "kp1" or key == "1" then
        love.system.setClipboardText("(" .. table.concat(selectedcolor, ",") .. ")")
        getcopy = true
    elseif key == keyhex or key == "kp2" or key == "2" then
        love.system.setClipboardText(rgbtohex(selectedcolor))
        getcopy = true
    elseif key == "return" or key == "kpenter" or key == "kp0" then
        love.system.setClipboardText("")
        c_x, c_y = 150, 150
        setpallet(c_x, c_y)
        getcopy = true
    end
end

function colorPicker.draw()
    x, y = love.mouse.getPosition()

    if (x > 0 and x < palletw) and (y > 0 and y < palleth) and istouch then
        c_x, c_y = x, y
        setpallet(x, y)
    end

    set(255, 255, 255, 255)
    love.graphics.draw(pallet)
    set(bordercolor)
    rec("line", 0, 0, palletw, palleth)
    cir("line", c_x, c_y, radius, 100)

   --set(255, 0, 0, 200)
   --prints("Red " .. selectedcolor[1] * 255, prevx, 120)
   --set(0, 255, 0, 200)
   --prints("Green " .. selectedcolor[2] * 255, prevx, 150)
   --set(0, 0, 255, 200)
   --prints("Blue " .. selectedcolor[3] * 255, prevx, 180)

    if love.system.getClipboardText() == "(" .. table.concat(selectedcolor, ",") .. ")" then
        set(0, 0, 250)
    else
        set(200, 200, 200)
    end

    if love.system.getClipboardText() == rgbtohex(selectedcolor) then
        set(0, 0, 250)
    else
        set(200, 200, 200)
    end
end

function colorPicker.getSelectedColor()
    return selectedcolor
end

return colorPicker
