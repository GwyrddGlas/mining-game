local socket = require("socket")

local network = {}

function network:init(ip, port)
    self.ip = ip
    self.port = port
    self.server = nil
    self.client = nil
end

function network:createServer()
    self.server = socket.bind(self.ip, self.port)
    self.server:settimeout(0)
    print("Server created at " .. self.ip .. ":" .. self.port)
end

function network:connect()
    self.client = socket.tcp()
    self.client:settimeout(0)
    local success, err = self.client:connect(self.ip, self.port)
    if not success then
        note:new("Failed to connect: ".. err, "danger")
        return false
    end
    return true
end

function network:send(data)
    if self.client then
        self.client:send(data .. "\n")
    end
end

function network:receive()
    if self.server then
        local client = self.server:accept()
        if client then
            client:settimeout(0)
            local data, err = client:receive()
            if data then
                print("Received: " .. data)
            end
        end
    elseif self.client then
        local data, err = self.client:receive()
        if data then
            print("Received: " .. data)
        end
    end
end

return network