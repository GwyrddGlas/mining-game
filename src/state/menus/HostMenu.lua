local multiplayer = require("src.class.network")
local lg = love.graphics

local function createHostMenu(menu)
    local screen_width = lg.getWidth()
    local screen_height = lg.getHeight()
    local button_width = menu.width * 0.15
    local button_height = menu.height * 0.05

    local elements = {
        label.new("Host", menu.color.fg, font.subtitle, 0, lg.getHeight() * 0.05, "center"),
        
        port = textbox.new("25565", "Port", menu.color.fg, menu.color.idle, 
                         menu.color.fg, 
                         screen_width/2 - button_width/2, 
                         screen_height * 0.3, 
                         button_width, button_height)
    }

    elements.hostButton = button.new(
        "Host", menu.color.white, menu.color.white, 
        screen_width/2 - button_width/2,
        screen_height * 0.45,
        button_width, 
        button_height, 
        function()
            local port_number = tonumber(elements.port.text)
            if port_number then
                menu.multiplayer = multiplayer.host(port_number)
                if not menu.multiplayer then
                    menu.notification = "Failed to host on port "..port_number
                else
                    menu.screen = "lobby"
                    menu.notification = "Hosting on port "..port_number
                end
            else
                menu.notification = "Please enter a valid port number"
            end
        end
    )

    elements.backButton = createButton(
        "Back", 
        screen_width/2 - button_width/2, 
        screen_height * 0.55, 
        button_width, 
        button_height, 
        function() menu.screen = "main" end
    )

    return elements
end

return createHostMenu