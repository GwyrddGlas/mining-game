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

-- Colors
local playerNameColor = {255, 223, 186}  -- Soft Gold
local outlineColor = {70, 70, 90, 255}  -- Dark gray-blue for outline
local chatBubbleColor = {0, 0, 0, 200}  
local inputBoxColor = {30, 30, 40, 200}  -- Darker for the input box

local chatBubblePadding = 5
local fixedInputHeight = 30
local maxMessageLength = 25

-- Channel colors
local channels = {
    ["all"] = {color = {220, 220, 220}, prefix = "[All]"},  -- Light gray for general chat
    ["local"] = {color = {180, 180, 180}, prefix = "[Local]"},  -- Gray for local messages
    ["whisper"] = {color = {180, 120, 220}, prefix = "[Whisper]"},  -- Soft purple for whispers
    ["system"] = {color = {255, 255, 100}, prefix = "[System]"},  -- Yellow for system messages
}

local magic = config.player.magic
local magicCap = config.player.magicCap

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
        local amount = math.min(tonumber(quantity), magicCap)
        magic = math.min(magic + amount, magicCap)
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

function console:draw()
    local screenWidth = lg.getWidth()
    local screenHeight = lg.getHeight()

    local rectWidth = 500
    local rectHeight = 250

    local rectX = 20
    local rectY = screenHeight - rectHeight - 20

    lg.setLineWidth(5)

    setColor(outlineColor)  -- Outline color
    lg.rectangle("line", rectX, rectY, rectWidth, rectHeight, 5, 5)

    setColor(chatBubbleColor)  -- Chat bubble background color
    lg.rectangle("fill", rectX, rectY, rectWidth, rectHeight, 5, 5)

    lg.setFont(self.font)

    local messageY = rectY + rectHeight - self.font:getHeight() - 40
    local maxMessageWidth = rectWidth - 20

    -- Draw each message
    local visibleMessages = {}
    local startIndex = math.max(#self.messages - 9, 1)
    for i = startIndex, #self.messages do
       local message = self.messages[i]

       setColor(message.color)
       lg.printf(message.prefix, rectX + 10, messageY, maxMessageWidth)

       if message.playerName then
           setColor(playerNameColor)  -- Soft gold for player name
           local nameWidth = self.font:getWidth(message.playerName .. " ")
           lg.print(message.playerName .. " ", rectX + 10 + lg.getFont():getWidth(message.prefix .. " "), messageY)

           setColor(message.color)
           lg.print(message.text, rectX + 10 + nameWidth + lg.getFont():getWidth(message.prefix .. " "), messageY)
       else
           setColor(message.color)
           lg.print(message.text, rectX + 10 + lg.getFont():getWidth(message.prefix), messageY)
       end

       messageY = messageY - (self.font:getHeight() + chatBubblePadding)
    end

    -- Draw the input text box
    setColor(inputBoxColor)  -- Darker box for input
    lg.rectangle("fill", rectX, rectY + rectHeight - self.inputHeight, rectWidth, self.inputHeight)

    setColor({255, 255, 255})  -- White text for the input
    lg.print(self.input, rectX + 5, rectY + rectHeight - self.font:getHeight() - 10 + 5)
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
        local args = {}
        for word in self.input:gmatch("%S+") do
            table.insert(args, word)
        end

        local command = table.remove(args, 1)
        if commands[command] then
            commands[command](self, unpack(args))
        else
            self:addMessage("Unknown command: " .. command, "system")
        end
    else
        self:addMessage(self.input, self.activeChannel)
    end

    self.input = ""
end

return console