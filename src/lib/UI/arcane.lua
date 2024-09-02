local ArcaneUI = {}
local lg = love.graphics

function ArcaneUI:open(data)
    self.isOpen = true
    self.data = data

end

function ArcaneUI:close()
    self.isOpen = false

end

function ArcaneUI:update(dt)
    if not self.isOpen then return end

end

function ArcaneUI:draw()
    if not self.isOpen then return end

    lg.print("TEST INVENTORY")
end

return ArcaneUI