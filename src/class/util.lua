-- Various utility functions
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

function wRand(weights)
    local weightSum = 0
    for i,v in ipairs(weights) do weightSum = weightSum + v end
    local target = weightSum * random()
    local rSum = 0
    for i,v in ipairs(weights) do
        rSum = rSum + v
        if rSum > target then
            return i
        end
    end
end

function tprint(tbl, indent) --https://gist.github.com/ripter/4270799
    if not indent then indent = 0 end
    for k, v in pairs(tbl) do
      formatting = string.rep("  ", indent) .. k .. ": "
      if type(v) == "table" then
        print(formatting)
        tprint(v, indent+1)
      elseif type(v) == 'boolean' then
        print(formatting .. tostring(v))      
      else
        print(formatting .. tostring(v))
      end
    end
end

function require_folder(folder)
    local fs = love.filesystem
    local folderPath = folder:gsub("%.", "/")
    
    if fs.getInfo(folderPath) then
        for _, v in ipairs(fs.getDirectoryItems(folderPath)) do
            local path = folderPath .. "/" .. v
            local info = fs.getInfo(path)
            if info.type == "directory" then
                _G[v] = require(folder .. "." .. v)
            elseif info.type == "file" and path:match("%.lua$") then
                local moduleName = v:match("(.+)%.lua$")
                _G[moduleName] = require(folder .. "." .. moduleName)
            end
        end
    else
        error(string.format("Folder '%s' does not exist", folder))
    end
end

function hasValue(t, val)
    for k,v in pairs(t) do
        if v == val then return true end
    end
end

function get_file_type(file_name)
    return string.match(file_name, "%..+"):sub(2)
end

function get_file_name(file_name)
    return string.match(file_name, ".+%."):sub(1, -2) 
end

-- Converts colors from 0-255 to 0-1
function convertColor(r, g, b, a)
    a = a or 255
    return r / 255,  g / 255,  b / 255,  a / 255
end

function setColor(r, g, b, a)
    a = a or 255
    lg.setColor(r / 255, g / 255, b / 255, a / 255)
end

function loadAtlas(path, tileWidth, tileHeight, padding)
	if not love.filesystem.getInfo(path) then
		error("'"..path.."' doesn't exist.")
	end

	local a = {}
	local img = love.graphics.newImage(path)
	local width = math.floor(img:getWidth() / tileWidth)
	local height = math.floor(img:getHeight() / tileHeight)
		
	local x, y = padding, padding
	for i=1, width * height do
		a[i] = love.graphics.newQuad(x, y, tileWidth, tileHeight, img:getWidth(), img:getHeight())
		x = x + tileWidth + padding
		if x > ((width-1) * tileWidth) then
			x = padding
			y = y + tileHeight + padding
		end
	end

	return img, a
end