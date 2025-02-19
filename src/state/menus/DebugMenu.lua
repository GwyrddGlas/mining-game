local lg = love.graphics

local function createDebugMenu(menu)
    return {
        label.new("Debug", menu.color.fg, font.title, 0, lg.getHeight() * 0.15, "center"),
            checkbox.new("Debug Enabled", menu.color.white, menu.color.white, menu.width * 0.4, menu.height * 0.3, menu.width * 0.4, menu.height * 0.05, config.debug.enabled, 
                function(isChecked) 
                    config.debug.enabled = isChecked
                end),    
            
                checkbox.new("Show Chunk Borders", menu.color.white, menu.color.white, menu.width * 0.4, menu.height * 0.4, menu.width * 0.4, menu.height * 0.05, config.debug.showChunkBorders, 
                function(isChecked) 
                    config.debug.showChunkBorders = isChecked
                end),  

                checkbox.new("Show Collisions", menu.color.white, menu.color.white, menu.width * 0.4, menu.height * 0.5, menu.width * 0.4, menu.height * 0.05, config.debug.showCollision, 
                function(isChecked) 
                    config.debug.showCollision = isChecked
                end),    

                checkbox.new("Player Collision", menu.color.white, menu.color.white, menu.width * 0.4, menu.height * 0.6, menu.width * 0.4, menu.height * 0.05, config.debug.playerCollision, 
                function(isChecked) 
                    config.debug.playerCollision = isChecked
                end),    
            
            createButton("Back", 30, 70, 40, 9, revertScreen()),    
        }
end

return createDebugMenu