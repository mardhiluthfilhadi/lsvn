local BASE = (...):match('(.-)[^%.]+$')
local suit = require(BASE.."external.suit")
local settings = require("settings")
local sw = settings.screen_width
local sh = settings.screen_height

local new_gui = function(gui_kind, value, opt, x, y, w, h)
    local gui = {}
    gui.active = true
    if type(gui_kind) == "table" then
        for k,v in pairs(gui_kind) do
            if gui_kind[k] then
                gui[k] = v
            end
        end
    else
        gui.kind = gui_kind
        gui.value = value
        if type(opt) ~= "table" then
            gui.opt = {}
            gui.x = opt
            gui.y = x
            gui.width = y
            gui.height = w
            if gui_kind == "ImageButton" then
                gui.width = gui.width or gui.value:getWidth()
                gui.height = gui.height or gui.value:getHeight()
            end
            gui.anchor = {
                x = 0,
                y = 0,
            }
        else
            gui.opt = opt
            gui.x = x
            gui.y = y
            gui.width = w
            gui.height = h
            if gui_kind == "ImageButton" then
                gui.width = gui.width or gui.value:getWidth()
                gui.height = gui.height or gui.value:getHeight()
            end
            gui.anchor = {
                x = 0,
                y = 0,
            }
        end
        gui.callbacs = nil
    end
    gui.id = gui.opt.id or value
    gui.opt.id = gui.opt.id or gui.id

    gui.set_callbacs = function(fn)
        gui.callbacs = fn
        return gui
    end
    gui.bound = function(x, y, w, h)
        gui.x = x
        gui.y = y or gui.x
        gui.width = w
        gui.height = h
        gui.id = gui.opt.id or gui.value
        gui.opt.id = gui.opt.id or gui.id
        return gui
    end
    gui.set_anchor = function(x, y)
        gui.anchor.x = x or 0
        gui.anchor.y = y or gui.anchor.x
        gui.id = gui.opt.id or gui.value
        gui.opt.id = gui.opt.id or gui.id
        return gui
    end
    return gui
end

local wrapper_for_instance = function(instance)
    local wrapper = {}
    wrapper.Button = function(...)
        return instance:Button(...)
    end
    wrapper.ImageButton = function(...)
        return instance:ImageButton(...)
    end
    wrapper.Input = function(...)
        return instance:Input(...)
    end
    wrapper.Slider = function(...)
        return instance:Slider(...)
    end
    wrapper.Label = function(...)
        return instance:Label(...)
    end
    wrapper.Checkbox = function(...)
        return instance:Checkbox(...)
    end
    return wrapper
end

local get_theme = function()
    local theme = {}
    for k,v in pairs(suit.theme) do
        if k == "color" then
            theme.color = {}
            theme.color.normal  = { bg = v.normal.bg, fg = v.normal.fg }
            theme.color.hovered = {bg = v.hovered.bg, fg = v.hovered.fg}
            theme.color.active  = { bg = v.active.bg, fg = v.active.fg }
        else
            theme[k] = v
        end
    end
    return theme
end

local new_suit_wrapper = function(get_global_scale, get_resized_screen_matrix)
    local wrapper = {}
    wrapper.active = true
    wrapper.callbacs_called = false
    wrapper.instance = suit.new()
    wrapper.elements = wrapper_for_instance(wrapper.instance)

    wrapper.new_gui = new_gui
    wrapper.theme = get_theme()
    wrapper.layout = wrapper.instance.layout
    wrapper.lyt = wrapper.layout

    wrapper.btn = function(...)
        local obj = new_gui("Button", ...)
        obj.opt.color = obj.opt.color or wrapper.theme.color
        obj.opt.draw = obj.opt.draw or wrapper.theme[obj.kind]
        return obj
    end
    wrapper.imgbtn = function(...)
        local obj = new_gui("ImageButton", ...)
        obj.opt.color = obj.opt.color or wrapper.theme.color
        obj.opt.draw = obj.opt.draw or wrapper.theme[obj.kind]
        return obj
    end
    wrapper.txtbx = function(...)
        local obj = new_gui("TextBox", ...)
        obj.opt.color = obj.opt.color or wrapper.theme.color
        obj.opt.draw = obj.opt.draw or wrapper.theme[obj.kind]
        return obj
    end
    wrapper.sldr = function(...)
        local obj = new_gui("Slider", ...)
        obj.opt.color = obj.opt.color or wrapper.theme.color
        obj.opt.draw = obj.opt.draw or wrapper.theme[obj.kind]
        return obj
    end
    wrapper.lbl = function(...)
        local obj = new_gui("Label", ...)
        obj.opt.color = obj.opt.color or wrapper.theme.color
        obj.opt.draw = obj.opt.draw or wrapper.theme[obj.kind]
        return obj
    end
    wrapper.ckbx = function(...)
        local obj = new_gui("Checkbox", ...)
        obj.opt.color = obj.opt.color or wrapper.theme.color
        obj.opt.draw = obj.opt.draw or wrapper.theme[obj.kind]
        return obj
    end

    wrapper.add = function(gui_object)
        local new_sw, new_sh, padw, padh = get_resized_screen_matrix()
        local global_scale = get_global_scale()

        local opt = {}
        for k,v in pairs(gui_object.opt) do
            if type(v) == "number" then
                opt[k] = math.floor(v * global_scale)
            else
                opt[k] = v
            end
        end
        local gui_element = wrapper.elements[gui_object.kind](
            gui_object.value,
            opt,
            (gui_object.x * new_sw / sw + padw) - gui_object.width*global_scale*gui_object.anchor.x,
            (gui_object.y * new_sh / sh + padh) - gui_object.height*global_scale*gui_object.anchor.y,
            gui_object.width * global_scale,
            gui_object.height * global_scale
        )
        if gui_element.hit and
        gui_object.callbacs and
        wrapper.active and
        gui_object.active and
        not wrapper.callbacs_called then
            gui_object.callbacs()
            wrapper.callbacs_called = true
        end
        if wrapper.active then
            return gui_element
        end
    end
    wrapper.draw = function()
        wrapper.callbacs_called = false
        wrapper.instance:draw()
    end

    return wrapper
end

return new_suit_wrapper
