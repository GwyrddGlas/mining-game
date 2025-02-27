local lg = love.graphics

local function createMainMenu(menu)
    return {
        label.new(VERSION, menu.color.white, font.regular, menu.width * 0.47 - font.regular:getWidth(VERSION) * 0.4, menu.height - 55, "center"),
        label.new("discord.gg/DhJYCtKEab", menu.color.white, font.regular, 10, menu.height - 55, "left"),
        label.new(""..NAME, menu.color.fg, font.title, 0, lg.getHeight() * 0.15, "center"),
       
        createButton("Singleplayer", 30, 40, 40, 9, changeScreen("singleplayer")),
        createButton("Multiplayer", 30, 50, 40, 9, changeScreen("multiplayer")),
        createButton("Settings", 30, 60, 40, 9, changeScreen("options")),
        createButton("Quit Game", 30, 70, 40, 9, exitButton),
    }
end

return createMainMenu