local console = {}
local lg = love.graphics

local function setColor(r, g, b, a)
    if type(r) == "table" then
        r, g, b, a = r[1], r[2], r[3], r[4]
    end
    a = a or 255
    lg.setColor(r/255, g/255, b/255, a/255)
end

local function truncateMessage(message, maxLength)
    if #message > maxLength then
        return message:sub(1, maxLength - 3) .. "..."
    end
    return message
end

local playerNameColor = {255, 165, 0}
local outlineColor = {50, 50, 50, 255} 
local chatBubbleColor = {40, 40, 45, 0.8}  
local chatBubblePadding = 5 
local fixedInputHeight = 30
local maxMessageLength = 25

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
    ["/conjure"] = function(self, quantity)
        local amount = math.min(tonumber(quantity), _PLAYER.magicCap)
        _PLAYER.magic = math.min(_PLAYER.magic + amount, _PLAYER.magicCap)
        self:addMessage(truncateMessage("Gave " .. tostring(amount) .. " conjuration", maxMessageLength), "system")
    end,
    ["/give"] = function(self, ...)
        local args = {...}
        if #args < 2 then
            self:addMessage(truncateMessage("Usage: /give <item> <quantity>", maxMessageLength), "system")
            return
        end
        local item = args[1]
        local quantity = tonumber(args[2])
        
        if not quantity or quantity <= 0 then
            self:addMessage(truncateMessage("Invalid quantity. Please use a positive number.", maxMessageLength), "system")
            return
        end
        
        -- Assuming _INVENTORY is a global inventory system
        if _INVENTORY and _INVENTORY.giveItem then
            _INVENTORY:giveItem(item, quantity)
            self:addMessage(truncateMessage("Gave " .. quantity .. " " .. item .. "(s).", maxMessageLength), "system")
        else
            self:addMessage(truncateMessage("Inventory system not found or giveItem function not available.", maxMessageLength), "system")
        end
    end,
}

function console:init(width, height, font)
    self.width = width or 500
    self.height = height or 250

    self.font = font

    self.inputHeight = fixedInputHeight
    self.chatHeight = self.height - self.inputHeight

    -- Position the console at the bottom-left corner of the screen
    self.x = 0
    self.y = lg.getHeight() - self.height

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
    
    local truncatedMessage = truncateMessage(message, maxMessageLength)
    
    local fullMessage = {
        prefix = prefix,
        color = color
    }
    
    if channel == "system" then
        fullMessage.text = " " .. truncatedMessage
    else
        if from then
            prefix = prefix .. " " .. from
        end
        fullMessage.playerName = tostring(config.settings.playerName)
        fullMessage.text = ": " .. truncatedMessage
    end
    
    table.insert(self.messages, 1, fullMessage)
    
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

function console:draw()
    local screenWidth = lg.getWidth()
    local screenHeight = lg.getHeight()

    local rectWidth = 500
    local rectHeight = 250

    local rectX = 20
    local rectY = screenHeight - rectHeight - 20
    
    lg.setLineWidth(5)
    
    -- Draw the outline
    lg.setColor(45/255, 54/255, 72/255) 
    lg.rectangle("line", rectX, rectY, rectWidth, rectHeight, 5, 5)

    -- Draw the filled rectangle
    lg.setColor(21/255, 29/255, 40/255, 0.6) 
    lg.rectangle("fill", rectX, rectY, rectWidth, rectHeight, 5, 5)

    lg.setFont(self.font)

    local messageY = rectY + rectHeight - self.font:getHeight() - 10 
    local maxMessageWidth = rectWidth - 20

    -- Draw each message
    local visibleMessages = {}
    local startIndex = math.max(#self.messages - 9, 1)
    for i = startIndex, #self.messages do
       local message = self.messages[i]
       
       setColor(message.color)
       lg.printf(message.prefix, rectX + 10, messageY, maxMessageWidth)
       
       if message.playerName then
           lg.setColor(playerNameColor[1]/255, playerNameColor[2]/255, playerNameColor[3]/255)
           local nameWidth = self.font:getWidth(message.playerName .. " ")
           lg.print(message.playerName .. " ", rectX + 10 + lg.getFont():getWidth(message.prefix .. " "), messageY)
           
           lg.setColor(message.color[1]/255, message.color[2]/255, message.color[3]/255)
           lg.print(message.text, rectX + 10 + nameWidth + lg.getFont():getWidth(message.prefix .. " "), messageY)
       else
           lg.setColor(message.color[1]/255, message.color[2]/255, message.color[3]/255)
           lg.print(message.text, rectX + 10 + lg.getFont():getWidth(message.prefix), messageY)
       end
       
       messageY = messageY - (self.font:getHeight() + chatBubblePadding)
    end
 
    -- Draw the input text
    lg.setColor(255, 255, 255)
    lg.print(self.input, rectX + 5, rectY + rectHeight - self.font:getHeight() - 10  + 5)
end

function console:keypressed(key)
    if state.loadedStateName ~= "game" and not self.isOpen then
        return 
    end

    if key == "return" and #self.input >= 1 then
        self:processInput()
        self.isOpen = false
    elseif key == "backspace" then
        self.input = self.input:sub(1, -2)
    end
end

function console:textinput(t)
    if not self.isOpen then return end
    
    -- Enforce max message length
    if #self.input < maxMessageLength then
        self.input = self.input .. t
    end
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

function console:setFont(fontSize)
    self.font = fontSize and font[fontSize] or lg.newFont(14)
    self.inputHeight = self.font:getHeight() + 10
    self.chatHeight = self.height - self.inputHeight
    self.inputBox.y = self.y + self.chatHeight
    self.inputBox.height = self.inputHeight
end

return console