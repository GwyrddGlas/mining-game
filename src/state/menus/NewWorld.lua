local lg = love.graphics

local function createSingleplayerMenu(menu)
    return {
        label.new("New world", menu.color.fg, font.title, 0, lg.getHeight() * 0.15, "center"),
        worldName = textbox.new("", "World name", menu.color.white, menu.color.idle, menu.color.fg, menu.width * 0.3, menu.height * 0.4, menu.width * 0.4, menu.height * 0.09),
        seed = textbox.new("", "Seed", menu.color.white, menu.color.idle, menu.color.fg, menu.width * 0.3, menu.height * 0.5, menu.width * 0.4, menu.height * 0.09, false, 10),
        createButton("Create world", 30, 60, 40, 9, function()
            local maxSeed = 2147483647 - 1000
            local wrldName = menu.screen.new.worldName.text
                
            if #wrldName < 1 then
                wrldName = "Untitled Game"
            end
        
            local seed = menu.screen.new.seed.text
        
            -- If no seed is provided, use the current time
            if #seed < 1 then
                seed = os.time()
            end
        
            if tonumber(seed) then
                seed = tonumber(seed)
            else
                seed = hashcode(seed)
            end
        
            if seed > maxSeed then
                seed = maxSeed
            end
        
            state:load("game", {type = "new", worldName = wrldName, seed = tonumber(seed)})
        end),
        createButton("Back", 30, 70, 40, 9, revertScreen()),    
    }
end

return createSingleplayerMenu