local BASE = (...):match('(.-)[^%.]+$')
local settings = require("settings")
local ls = require(BASE.."external.lovestory")
local asset = require(BASE.."asset")
local suit_wrapper = require(BASE.."gui")
local image_wrapper = require(BASE.."image")
local flux = require(BASE.."external.flux")
local tick = require(BASE.."external.tick")
local wave = require(BASE.."external.wave")
local hex2color = require(BASE.."external.hex2color")
local gr = love.graphics

local manager = {}

manager.colors = {}
manager.colors.background = settings.default.background_color

manager.screens = {}
manager.screens._current_active = nil
manager._previous_active_screens = {}
local screen_requesed = {}
local distribute_screen_shot = function(imageData)
    for i=1, #screen_requesed do
        manager.screens[screen_requesed[i]].on_chapture(imageData)
    end
end

local current_screen_args = nil
manager.activate_screen = function(name, ...)
    current_screen_args = {...}
    manager.screens._current_active = manager.screens[name]
    manager.screens._current_active.init(...)
    manager.screens._current_active.active = true
end

manager.deactivate_screen = function()
    current_screen_args = nil
    if not manager.screens._current_active then return end
    table.insert(manager._previous_active_screens, manager.screens._current_active)
    manager.screens._current_active.active = false
    manager.screens._current_active.on_destruct()
    manager.screens._current_active = nil
end

manager.new_screen = function(name, request_screen_shot, get_global_scale, get_resized_screen_matrix)
    local screen =  {}
    screen.id_name = name
    screen.active = false
    screen.manager = {}
    screen.manager.assets = asset.assets
    screen.manager.get_source = asset.get_source
    screen.manager.settings = settings
    screen.manager.get_screen = function(nm)
        return manager.screens[nm]
    end

    screen.plugin = {}
    screen.plugin.gui = suit_wrapper(get_global_scale, get_resized_screen_matrix)
    screen.plugin.tween = flux.group()
    screen.plugin.timer = tick.group()
    screen.plugin.sound = wave
    screen.plugin.rgba = hex2color

    screen.on_boot = function()end
    screen.keypressed = function()end
    screen.keyreleased = function()end
    screen.mousepressed = function()end
    screen.mousemoved = function()end
    screen.mousereleased = function()end
    screen.textinput = function()end
    screen.textedited = function()end
    screen.resize = function()end
    screen.touchpressed = function()end
    screen.touchmoved = function()end
    screen.touchreleased = function()end
    screen.init = function()end
    screen.update = function(dt)end
    screen.draw = function()end
    screen.on_destruct = function()end
    screen.on_load = function(data)end
    screen.on_save = function(slot)
        return {}
    end

    if request_screen_shot then
        table.insert(screen_requesed, name)
        screen.on_chapture = function(data)end
    end

    screen.image = {}
    screen.image.save = image_wrapper.save
    screen.image.new = image_wrapper.new
    screen.image.draw = function(img)
        image_wrapper.draw(img, get_global_scale, get_resized_screen_matrix)
    end

    screen.goback = function()
        local prev = table.remove(manager._previous_active_screens, #manager.screens._previous_active)
        screen.goto(prev.name)
    end

    screen.goto = function(nm, args)
        local delay = 0
        if screen_requesed[nm] then
            delay = .001
        end
        tick.delay(function()
        gr.captureScreenshot(distribute_screen_shot)
        end, delay):after(function()
        manager.deactivate_screen()
        manager.activate_screen(nm, args)
        if manager.screens.default and manager.screens.default.pause then
            manager.screens.default.pause()
            manager.screens.default.hide()
            manager.screens.default.active = false end
        end, delay)
    end
    screen.resolve = function()
        manager.deactivate_screen()
        if manager.screens.default and manager.screens.default.resume then
            manager.screens.default.active = true
            manager.screens.default.resume()
            ls.next_command()
        end
    end

    return screen
end
return manager
