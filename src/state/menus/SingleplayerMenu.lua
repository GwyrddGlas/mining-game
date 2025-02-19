local lg = love.graphics

local function createSingleplayerMenu(menu)
    return {
        label.new("Singleplayer", menu.color.fg, font.title, 0, lg.getHeight() * 0.15, "center"),
        createButton("New world", 30, 40, 40, 9, changeScreen("new")),
        createButton("Load world", 30, 50, 40, 9, changeScreen("load")),
        createButton("Back", 30, 60, 40, 9, revertScreen()),
    }
end

return createSingleplayerMenu