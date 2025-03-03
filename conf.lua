function love.conf(c)
    c.console = true
    c.window.msaa = 16
    c.graphics.renderers = {"vulkan", "opengl"}
end