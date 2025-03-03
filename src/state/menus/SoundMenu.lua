local lg = love.graphics

local function createSoundMenu(menu)
    return {
        label.new("Sound Settings", menu.color.fg, font.subtitle, 0, lg.getHeight() * 0.05, "center"),
        
        slider.new("Master Volume", 0, 1, config.audio.master, menu.width * 0.3, menu.height * 0.4, menu.width * 0.4, menu.height * 0.05, {0.4, 0.4, 0.4}, {1, 1, 1}, function(value) 
            config.audio.master = value
            applyMasterVolume()
          end),
        
        slider.new("Music Volume", 0, 1, config.audio.music, menu.width * 0.3, menu.height * 0.5, menu.width * 0.4, menu.height * 0.05, {0.4, 0.4, 0.4}, {1, 1, 1}, function(value) 
            config.audio.music = value
            if currentTrack then
                currentTrack:setVolume(value * config.audio.master)
            end
        end),
        
        slider.new("SFX Volume", 0, 1, config.audio.sfx, menu.width * 0.3, menu.height * 0.6, menu.width * 0.4, menu.height * 0.05, {0.4, 0.4, 0.4}, {1, 1, 1}, function(value) config.audio.sfx = value end),
        button.new("Back", menu.color.white, menu.color.white, menu.width * 0.3, menu.height * 0.8, menu.width * 0.4, menu.height * 0.09, revertScreen())
    }
end

return createSoundMenu