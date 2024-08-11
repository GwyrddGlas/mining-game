local console = {}

local function setColor(r, g, b, a)
    if type(r) == "table" then
        r, g, b, a = r[1], r[2], r[3], r[4]
    end
    a = a or 255
    love.graphics.setColor(r/255, g/255, b/255, a/255)
end

local channels = {
    ["all"] = {color = {255, 255, 255}, prefix = "[All]"},
    ["local"] = {color = {200, 200, 200}, prefix = "[Local]"},
    ["whisper"] = {color = {255, 150, 255}, prefix = "[Whisper]"},
    ["system"] = {color = {255, 255, 0}, prefix = "[System]"},
}

local commands = {
    ["/clear"] = function(self)
        self:clearHistory()
        self:addMessage("Chat cleared.", "system")
    end,
    ["/all"] = function(self, message)
        self:addMessage(message, "all")
    end,
    ["/l"] = function(self, message)
        self:addMessage(message, "local")
    end,
    ["/w"] = function(self, target, message)
        self:addMessage(message, "whisper", target)
    end,
    ["/give"] = function(self, ...)
        local args = {...}
        if #args < 2 then
            self:addMessage("Usage: /give <item> <quantity>", "system")
            return
        end
        local item = args[1]
        local quantity = tonumber(args[2])
        
        if not quantity or quantity <= 0 then
            self:addMessage("Invalid quantity. Please use a positive number.", "system")
            return
        end
        
        -- Assuming _INVENTORY is a global inventory system
        if _INVENTORY and _INVENTORY.giveItem then
            _INVENTORY:giveItem(item, quantity)
            self:addMessage("Gave " .. quantity .. " " .. item .. "(s) to the player.", "system")
        else
            self:addMessage("Inventory system not found or giveItem function not available.", "system")
        end
    end,
}

function console:init(x, y, width, height, visible, font)
    self.x = x or 0
    self.y = y or 0
    self.width = width or 300
    self.height = height or 200
    self.visible = visible or true
    self.font = font or love.graphics.newFont(14)
    self.inputHeight = self.font:getHeight() + 10
    self.chatHeight = self.height - self.inputHeight

    self.messages = {}
    self.input = ""
    self.scroll = 0
    self.maxMessages = 100
    self.activeChannel = "all"
    self.isOpen = false
    self.inputBox = {
        x = self.x,
        y = self.y + self.chatHeight,
        width = self.width,
        height = self.inputHeight
    }
end

function console:addMessage(message, channel, from)
    channel = channel or self.activeChannel
    local prefix = channels[channel].prefix
    local color = channels[channel].color
    if from then
        prefix = prefix .. " " .. from
    end
    
    local fullMessage = prefix .. " " .. tostring(config.settings.playerName) .. ": " .. message
    table.insert(self.messages, 1, {text = fullMessage, color = color, timer = 6}) 
    
    if #self.messages > self.maxMessages then
        table.remove(self.messages)
    end
end

function console:lua(text)
    local args = {}
    for arg in string.gmatch(text, "%S+") do
        table.insert(args, arg)
    end

    local command = args[1]
    if commands[command] then
        commands[command](unpack(args, 2))
    else
        local status, err = pcall(loadstring(text))
        err = err or false
        if err then
            self:print("LUA: "..tostring(err))
        end
    end
end

function console:clearHistory()
    self.messages = {}
    self.scroll = 0
end

function console:update(dt)
    if not state.loadedStateName == "game" then
        return 
    end

    for i = 1, #self.messages do
        local message = self.messages[i]
        message.timer = message.timer - dt
        if message.timer <= 0 and not self.visible then
            table.remove(self.messages, i)
        end
    end
end

function console:draw()
    if self.visible then
        love.graphics.setColor(0.2, 0.2, 0.25, 0.6)
        love.graphics.rectangle("fill", self.inputBox.x, self.inputBox.y, self.inputBox.width, self.inputBox.height, 10, 10)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(self.input, self.inputBox.x + 5, self.inputBox.y + 5, self.inputBox.width - 10)

        -- Draw typing indicator 
        if #self.input > 0 then
            love.graphics.setColor(0.5, 0.8, 1, 0.8)
            love.graphics.circle("fill", self.inputBox.x + self.inputBox.width - 15, self.inputBox.y + self.inputBox.height / 2, 3)
        end
    end

    -- Draw messages
    love.graphics.setFont(self.font)
    local y = self.y + self.chatHeight - self.font:getHeight() - 5
    local visibleCount = 0
    for i = 1, math.min(#self.messages, 10 + self.scroll) do
        local message = self.messages[i]
        if message.timer > 0 then
            setColor(message.color)
            love.graphics.printf(message.text, self.x + 5, y, self.width - 10)
            y = y - self.font:getHeight() - 2
            visibleCount = visibleCount + 1
        end
        if visibleCount >= 10 then
            break
        end
    end
end

function console:keypressed(key)
    if not state.loadedStateName == "game" then
        return 
    end

    if key == "return" and #self.input >= 1 then
        self:processInput()
    elseif key == "backspace" then
        self.input = self.input:sub(1, -2)
    end
end

function console:textinput(t)
	if not self.visible then return end
    self.input = self.input .. t
end

function console:wheelmoved(x, y)
    if y > 0 then
        self.scroll = math.min(self.scroll + 1, #self.messages - 10)
    elseif y < 0 then
        self.scroll = math.max(self.scroll - 1, 0)
    end
end

function console:processInput()
    if self.input:sub(1, 1) == "/" then
        local parts = {}
        for part in self.input:gmatch("%S+") do
            table.insert(parts, part)
        end
        local command = table.remove(parts, 1)
        if commands[command] then
            commands[command](self, unpack(parts))
        else
            self:addMessage("Unknown command: " .. command, "system")
        end
    else
        self:addMessage(self.input, self.activeChannel)
    end
    self.input = ""
end

function console:setVisible(visible)
    self.visible = visible
end

function console:getVisible()
    return self.visible
end

function console:setFont(font)
    self.font = font
    self.inputHeight = self.font:getHeight() + 10
    self.chatHeight = self.height - self.inputHeight
    self.inputBox.y = self.y + self.chatHeight
    self.inputBox.height = self.inputHeight
end

return console