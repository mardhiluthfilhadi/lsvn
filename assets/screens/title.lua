local screen = require("lsvn").new_screen
local title = screen("title")
local ls = require "lsvn.external.lovestory"

local gui = title.plugin.gui
local tween = title.plugin.tween
local sound = title.plugin.sound
local assets = title.manager.assets
local settings = title.manager.settings
local rgba = title.plugin.rgba
local sw = settings.screen_width
local sh = settings.screen_height
local cx = sw/2
local cy = sh/2

local start, quit, b
local circle = {}
local font = assets.fonts['VictorMono-Medium'](12)
function title.init()
    gui.theme.color.normal.bg = rgba("#FF8E9F")
    gui.theme.color.hovered.bg = gui.theme.color.normal.bg
    gui.theme.color.active.bg = rgba("#FFC6C4")
    gui.theme.color.normal.fg = rgba("#FFFFEE")
    gui.theme.color.hovered.fg = gui.theme.color.normal.fg
    gui.theme.color.active.fg = rgba("#FFDDFF")
    start = gui.btn("Start", {font=font}).set_anchor(.5).set_callbacs(function()
        ls.command.run("jump 'start'")
        title.resolve()
    end)
    quit = gui.btn("Quit", {font=font}).set_anchor(.5).set_callbacs(function()
        love.event.quit()
    end)
    ls.command.run("bg '#89AEE1'")
    b = gui.imgbtn(assets.images.cgs.apel, {assets.images.cgs.apel, assets.images.cgs.pisang}, cx, 500).set_anchor(.5)
end
function title.update(dt)
    gui.lyt:reset(cx, 300)
    gui.lyt:padding(10, 10)
    gui.add(start.bound(gui.lyt:row(140, 50)))
    gui.add(quit.bound(gui.lyt:row()))
    gui.lyt:padding(10, 40)
    love.graphics.setColor(1,1,1,1)
    gui.add(b)
end
function title.draw(offx, offy, scale)
    gui.draw()
    love.graphics.setColor(rgba("#FFFFFF", .2))
    for _,pos in ipairs(circle) do
        love.graphics.circle("fill", pos.x + offx, pos.y + offy, 20 * scale)
    end
end

function title.on_destruct()
    circle = {}
end

function title.mousepressed(x, y)
    table.insert(circle, {x=x, y=y})
end

return title
