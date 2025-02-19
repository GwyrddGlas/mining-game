local lg = love.graphics

local function createSkinsMenu(menu)
    return {
        label.new("Name", menu.color.bg, font.tiny, menu.width * 0.38, menu.height * 0.42, "left"),
            characterName = textbox.new("", "Pickle", menu.color.fg, menu.color.idle, menu.color.fg, menu.width * 0.38, menu.height * 0.45, menu.width * 0.15, menu.height * 0.05),
            createButton("Colour Picker", 38, 51, 15, 5, function()
                skinColourToggle = not skinColourToggle
            end),
            createButton("Save", 38, 65, 15, 5, function()
                save_config()
                note:new("Settings saved!", "success")
            end),
            createButton("Back", 30, 90, 40, 9, revertScreen()),   
        }
end

return createSkinsMenu