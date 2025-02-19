local lg = love.graphics

local function createMultiplayerMenu(menu)
    return {
        label.new("Multiplayer", menu.color.fg, font.title, 0, lg.getHeight() * 0.15, "center"),
        createButton("Host", 30, 40, 40, 9, changeScreen("host")),
        createButton("Join", 30, 50, 40, 9, changeScreen("join")),
        createButton("Back", 30, 60, 40, 9, revertScreen()),    
    }
end

return createMultiplayerMenu