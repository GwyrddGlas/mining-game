local enet = require("enet")

local multiplayer = {}
multiplayer.__index = multiplayer

function multiplayer.host(port)
    local self = setmetatable({}, multiplayer)
    self.host = enet.host_create("*:" .. port)
    
    if not self.host then
        return nil, "Port " .. port .. " is already in use"
    end
    
    self.connections = {}
    self.is_host = true
    return self
end

function multiplayer.join(ip, port)
    local self = setmetatable({}, multiplayer)
    self.host = enet.host_create()
    self.server = self.host:connect(ip .. ":" .. port)
    
    if not self.server then
        return nil, "Failed to connect to server"
    end
    
    self.connections = {}
    self.is_host = false
    return self
end

function multiplayer:update()
    if not self.host then return end
    
    local event = self.host:service(10) -- 10ms timeout
    while event do
        if event.type == "receive" then
            self:on_receive(event.data, event.peer)
        elseif event.type == "connect" then
            self:on_connect(event.peer)
        elseif event.type == "disconnect" then
            self:on_disconnect(event.peer)
        end
        event = self.host:check_events()
    end
end

function multiplayer:on_receive(data, peer)
    -- To be overridden by user
end

function multiplayer:on_connect(peer)
    self.connections[peer] = true
    -- To be overridden by user
end

function multiplayer:on_disconnect(peer)
    self.connections[peer] = nil
    -- To be overridden by user
end

function multiplayer:send(data, peer)
    if peer then
        peer:send(data)
    else
        self.host:broadcast(data)
    end
end

function multiplayer:disconnect()
    if self.host then
        self.host:flush()
        if self.server then -- If we're a client
            self.server:disconnect()
        end
        self.host = nil
    end
end

return multiplayer