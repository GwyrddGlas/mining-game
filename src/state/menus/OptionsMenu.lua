local lg = love.graphics

local function createOptionsMenu(menu)
    return {
        label.new("Settings", menu.color.fg, font.title, 0, lg.getHeight() * 0.15, "center"),
      
        createButton("Graphics", 30, 30, 40, 9, changeScreen("graphics")),
        createButton("Sounds", 30, 40, 40, 9, changeScreen("sounds")),
        createButton("Controls", 30, 50, 40, 9, changeScreen("controls")),
        createButton("Debug", 30, 60, 40, 9, changeScreen("debug")),
        createButton("Save", 30, 70, 40, 9, function()
            clear_config()
            save_config()
            note:new("Settings saved!", "success")
        end),
       
        createButton("Back", 30, 80, 40, 9, changeScreen("main")),
    }
end

return createOptionsMenu