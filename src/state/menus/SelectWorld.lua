local lg = love.graphics

local function createSelectWorldMenu(menu)
    return {
        label.new("Select World", menu.color.fg, font.title, 0, lg.getHeight() * 0.15, "center"),
        createButton("Back", 30, 90, 40, 9, revertScreen()), --tmp    
    }
end

return createSelectWorldMenu