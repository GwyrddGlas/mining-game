local socket = require("src.lib.socket")

local multiplayer = {}

function multiplayer.host(port)
    local server = assert(socket.bind("*", port))
    local ip, port = server:getsockname()

    note:new("Server started on " .. ip .. ":" .. port)
    note:new("Waiting for players to join...")

    local clients = {} 

    return {
        accept = function()
            local client = server:accept() 
            client:settimeout(10)  

            table.insert(clients, client)
            note:new("Player connected! Total players: " .. #clients)

            return client
        end,
        receive = function(client)
            local message, err = client:receive()
            if err then
                note:new("Player disconnected or error: " .. err)
                return nil, err
            end
            return message
        end,
        send = function(client, message)
            client:send(message .. "\n")
        end,
        broadcast = function(message)
            for _, client in ipairs(clients) do
                client:send(message .. "\n")
            end
        end,
        close = function(client)
            client:close()
        end,
        closeAll = function()
            for _, client in ipairs(clients) do
                client:close()
            end
        end
    }
end

function multiplayer.join(ip, port)
    local client = assert(socket.tcp())
    client:settimeout(0) 

    local success, err = client:connect(ip, port)
    if not success and err ~= "timeout" then
        return nil, err
    end

    return {
        send = function(message)
            client:send(message .. "\n")
        end,
        receive = function()
            local message, err = client:receive()
            if err == "timeout" then
                return nil
            elseif err then
                return nil, err
            end
            return message
        end,
        close = function()
            client:close()
        end
    }
end

return multiplayer