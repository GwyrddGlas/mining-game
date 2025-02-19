local lg = love.graphics

local function createHostMenu(menu)
    return {
        label.new("Host", menu.color.fg, font.title, 0, lg.getHeight() * 0.15, "center"),
        port = textbox.new("25565", "Port", menu.color.fg, menu.color.idle, menu.color.fg, menu.width * 0.38, menu.height * 0.45, menu.width * 0.15, menu.height * 0.05),
        createButton("Host", 38, 51, 15, 5, hostHame),
        createButton("Back", 30, 60, 40, 9, revertScreen()),    
    }
end

return createHostMenu