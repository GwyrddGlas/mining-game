local lg = love.graphics

local function createSingleplayerMenu(menu)
    return {
        label.new("New world", menu.color.fg, font.title, 0, lg.getHeight() * 0.15, "center"),
        worldName = textbox.new("", "World name", menu.color.white, menu.color.idle, menu.color.fg, menu.width * 0.3, menu.height * 0.4, menu.width * 0.4, menu.height * 0.09),
        seed = textbox.new("", "Seed", menu.color.white, menu.color.idle, menu.color.fg, menu.width * 0.3, menu.height * 0.5, menu.width * 0.4, menu.height * 0.09, false, 10),
        createButton("Create world", 30, 60, 40, 9, createNewWorld),
        createButton("Back", 30, 70, 40, 9, revertScreen()),    
    }
end

return createSingleplayerMenu