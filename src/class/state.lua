-- A bare bones state system
local state = {
    currentState = false,
    loadedStateName = "",
    state_list = {},
    stateHistory = {} 
}

-- state_module: Path to a state module file
-- name: Name of the state, Used in state:load
function state:define_state(state_module, name)
    self.state_list[name] = state_module
end

-- state: state name as defined with define_state
-- data: Anything you want to pass to the state in the state's load function
function state:load(state_name, data)
    if self.currentState then
        table.insert(self.stateHistory, {
            name = self.loadedStateName,
            state = self.currentState
        })
    end
    
    self.currentState = nil
    if self.state_list[state_name] then
        self.loadedStateName = state_name
        self.currentState = love.filesystem.load(self.state_list[state_name])()
        if type(self.currentState.load) == "function" and self.currentState then
            self.currentState:load(data)
        end
    else
        error(string.format("STATE: State '%s' does not exist!", state_name))
    end
end 

function state:unload()
    self.currentState = nil
end

function state:get_state()
    return self.currentState
end

function state:get_current_state_name()
    return self.loadedStateName
end

function state:resume_previous_state()
    if #self.stateHistory > 0 then
        local previousState = table.remove(self.stateHistory)
        self.loadedStateName = previousState.name
        self.currentState = previousState.state
        if type(self.currentState.resume) == "function" then
            self.currentState:resume()
        end
    else
        error("STATE: No previous state to resume!")
    end
end

function state:update(dt)
    if type(self.currentState.update) == "function" then
        self.currentState:update(dt)
    end
end

function state:resize(w, h)
    if type(self.currentState.resize) == "function" then
        self.currentState:resize(w, h)
    end
end

function state:draw()
    if type(self.currentState.draw) == "function" then
        self.currentState:draw()
    end
end

function state:keypressed(key)
    if type(self.currentState.keypressed) == "function" then
        self.currentState:keypressed(key)
    end
end

function state:keyreleased(key)
    if type(self.currentState.keyreleased) == "function" then
        self.currentState:keyreleased(key)
    end
end

function state:mousepressed(x, y, key)
    if type(self.currentState.mousepressed) == "function" then
        self.currentState:mousepressed(x, y, key)
    end
end

function state:mousereleased(x, y, button, istouch, presses)
    if type(self.currentState.mousereleased) == "function" then
        self.currentState:mousereleased(x, y, button, istouch, presses)
    end
end

function state:mousemoved(x, y, dx, dy, touched)
    if type(self.currentState.mousemoved) == "function" then
        self.currentState:mousemoved(x, y, dx, dy, touched)
    end
end

function state:wheelmoved(x, y)
    if type(self.currentState.wheelmoved) == "function" then
        self.currentState:wheelmoved(x, y)
    end
end

function state:quit()
    if type(self.currentState.quit) == "function" then
        self.currentState:quit()
    end
end

function state:textinput(t)
    if type(self.currentState.textinput) == "function" then
        self.currentState:textinput(t)
    end
end

return state