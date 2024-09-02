local UIHandler = {
    active = nil,
    types = {}
}

function UIHandler:register(name, uiModule)
    self.types[name] = uiModule
end

function UIHandler:open(ftype, data)
    if self.types[ftype] then
        self:close()
        self.active = self.types[ftype]
        self.active:open(data)
    else
        print("Warning: Attempted to open unknown UIHandler type: " .. ftype)
    end
end

function UIHandler:close()
    if self.active then
        self.active:close()
        self.active = nil
    end
end

function UIHandler:update(dt)
    if self.active then
        self.active:update(dt)
    end
end

function UIHandler:draw()
    if self.active then
        self.active:draw()
    end
end

return UIHandler