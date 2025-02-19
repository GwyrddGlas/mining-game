local lg = love.graphics
local gameControls = config.settings.gameControls

local function setNewKey(action, key)
    gameControls[action] = key
end

local function createControlsMenu(menu)
    return {
        label.new("Controls", menu.color.fg, font.title, 0, lg.getHeight() * 0.15, "center"),
        keybox.new("Forward", menu.color.white, menu.color.white, menu.width * 0.3, menu.height * 0.3, 120, menu.height * 0.09, gameControls.up, function(key)
            setNewKey("up", key)
        end),
        keybox.new("Backward", menu.color.white, menu.color.white, menu.width * 0.3, menu.height * 0.4, 120, menu.height * 0.09, gameControls.down, function(key)
            setNewKey("down", key)
        end),
        keybox.new("Left", menu.color.white, menu.color.white, menu.width * 0.3, menu.height * 0.5, 120, menu.height * 0.09, gameControls.left, function(key)
            setNewKey("left", key)
        end),
        keybox.new("Right", menu.color.white, menu.color.white, menu.width * 0.3, menu.height * 0.6, 120, menu.height * 0.09, gameControls.right, function(key)
            setNewKey("right", key)
        end),
        keybox.new("Sprint", menu.color.white, menu.color.white, menu.width * 0.5, menu.height * 0.3, 120, menu.height * 0.09, gameControls.sprint, function(key)
            setNewKey("sprint", key)
        end),
        keybox.new("Inventory", menu.color.white, menu.color.white, menu.width * 0.5, menu.height * 0.4, 120, menu.height * 0.09, gameControls.inventory, function(key)
            setNewKey("inventory", key)
        end),
        keybox.new("Chat", menu.color.white, menu.color.white, menu.width * 0.5, menu.height * 0.5, 120, menu.height * 0.09, gameControls.chat, function(key)
            setNewKey("chat", key)
        end),
        keybox.new("Pause", menu.color.white, menu.color.white, menu.width * 0.5, menu.height * 0.6, 120, menu.height * 0.09, gameControls.pause, function(key)
            setNewKey("pause", key)
        end),
        keybox.new("Conjure", menu.color.white, menu.color.white, menu.width * 0.7, menu.height * 0.3, 120, menu.height * 0.09, gameControls.conjure, function(key)
            setNewKey("conjure", key)
        end),
        keybox.new("Save", menu.color.white, menu.color.white, menu.width * 0.7, menu.height * 0.4, 120, menu.height * 0.09, gameControls.save, function(key)
            setNewKey("save", key)
        end),
        createButton("Back", 30, 80, 40, 9, revertScreen()),    
    }
end

return createControlsMenu