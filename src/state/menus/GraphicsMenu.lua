local lg = love.graphics

local function createGraphicsMenu(menu)
    return {
        label.new("Graphics Settings", menu.color.fg, font.title, 0, lg.getHeight() * 0.15, "center"),
        
            checkbox.new(
                "Shaders", menu.color.white, menu.color.white, 
                menu.width * 0.3, menu.height * 0.3, menu.width * 0.4, menu.height * 0.05, 
                config.graphics.useShaders, 
                function(isChecked) 
                    config.graphics.useShaders = isChecked 
                end
            ),
        
            checkbox.new(
                "Vsync", menu.color.white, menu.color.white, 
                menu.width * 0.4, menu.height * 0.3, menu.width * 0.4, menu.height * 0.05, 
                config.window.vsync, 
                function(isChecked) 
                    love.window.setVSync(isChecked)
                    config.graphics.vsync = isChecked
                end
            ),
        
            checkbox.new(
                "Fog", menu.color.white, menu.color.white, 
                menu.width * 0.5, menu.height * 0.3, menu.width * 0.4, menu.height * 0.05, 
                config.graphics.useLight, 
                function(isChecked) 
                    config.graphics.useLight = isChecked 
                end
            ),
       
            checkbox.new(
                "Borderless", menu.color.white, menu.color.white, 
                menu.width * 0.6, menu.height * 0.3, menu.width * 0.4, menu.height * 0.05, 
                config.window.borderless, 
                function(isChecked) 
                    config.window.borderless = isChecked 
                    config.window.resizable = isChecked 
                    config.window.fullscreen = not isChecked 
                end
            ),
        
            slider.new(
                "Bloom", 0, 1, config.graphics.bloom, 
                menu.width * 0.3, menu.height * 0.4, menu.width * 0.4, menu.height * 0.05, 
                {0.4, 0.4, 0.4}, {1, 1, 1}, 
                function(value) config.graphics.bloom = value end
            ),
        
            slider.new(
                "Light Distance", 0, 600, config.graphics.lightDistance, 
                menu.width * 0.3, menu.height * 0.5, menu.width * 0.4, menu.height * 0.05, 
                {0.4, 0.4, 0.4}, {1, 1, 1}, 
                function(value) config.graphics.lightDistance = value end
            ),
        
            slider.new(
                "Brightness", 0, 0.4, config.graphics.brightness, 
                menu.width * 0.3, menu.height * 0.6, menu.width * 0.4, menu.height * 0.05, 
                {0.4, 0.4, 0.4}, {1, 1, 1}, 
                function(value) config.graphics.brightness = value end
            ),
        
            slider.new(
                "Ambient Light", 0, 1, config.graphics.ambientLight, 
                menu.width * 0.3, menu.height * 0.7, menu.width * 0.4, menu.height * 0.05, 
                {0.4, 0.4, 0.4}, {1, 1, 1}, 
                function(value) config.graphics.ambientLight = value end
            ),
        
            -- Color picker for light color (commented out for now)
            -- colourPicker.new(
            --     "Light Color", config.graphics.lightColor, 
            --     menu.width * 0.3, menu.height * 0.55, menu.width * 0.4, menu.height * 0.05, 
            --     {0.4, 0.4, 0.4}, {1, 1, 1}, 
            --     function(r, g, b) config.graphics.lightColor = {r, g, b} end
            -- ),
        
            button.new(
                "Reset Graphics Settings", menu.color.white, menu.color.white, 
                menu.width * 0.3, menu.height * 0.8, menu.width * 0.4, menu.height * 0.09, 
                function()
                    local defaultGraphics = {
                        useLight = true,
                        useShaders = true,
                        bloom = 0.4,
                        brightness = 0.19,
                        lightDistance = 500,
                        ambientLight = 0.3,
                        lightColor = {1, 0.9, 0.8},
                        tileSize = 40,
                        assetSize = 16
                    }
        
                    for key, value in pairs(defaultGraphics) do
                        config.graphics[key] = value
                    end
        
                    save_config() 
                    note:new("Graphics settings have been reset, you will need to restart game.", "success")
                end
            ),
        
            createButton("Back", 30, 90, 40, 9, revertScreen()),
        }
end

return createGraphicsMenu