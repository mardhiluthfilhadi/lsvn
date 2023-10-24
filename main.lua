local lsvn = require "lsvn"
function love.load()
    lsvn.init()
end

function love.update(dt)
    lsvn.update(dt)
end

function love.draw()
    lsvn.draw()
end

function love.keypressed( key, scancode, isrepeat )
    if key == "escape" then
        love.event.quit()
    end
    lsvn.keypressed( key, scancode, isrepeat )
end

function love.resize(...)
    lsvn.resize(...)
end
function love.keyreleased(...)
    lsvn.keyreleased(...)
end
function love.mousepressed(...)
    lsvn.mousepressed(...)
end
function love.mousereleased(...)
    lsvn.mousereleased(...)
end
function love.touchreleased(...)
    lsvn.touchreleased(...)
end
function love.textedited(...)
    lsvn.textedited(...)
end
function love.textinput(...)
    lsvn.textinput(...)
end

