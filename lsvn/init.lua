local BASE = (...) .. "."
local ls = require(BASE.."external.lovestory")
local settings = require("settings")

local asset = require(BASE.."asset")
local manager = require(BASE.."screen")
local hex2color = require(BASE.."external.hex2color")
local binser = require(BASE.."external.binser")
local tick = require(BASE.."external.tick")

local gr = love.graphics
local fs = love.filesystem
local sy = love.system
local sw = settings.screen_width
local sh = settings.screen_height
local cx = sw/2
local cy = sh/2

local calc_scale = function(w, h)
    if sy.getOS() == "Web" then return 1 end
    return math.min((w or gr.getWidth())/sw, (h or gr.getHeight())/sh)
end

if sy.getOS() == "Web" then
love.window.setMode(settings.screen_width, settings.screen_height, {
    resizable = false,
})
else
love.window.setMode(settings.screen_width, settings.screen_height, {
    resizable = settings.screen_resizable,
})
end

local global_scale = calc_scale()
local new_sw = sw * global_scale
local new_sh = sh * global_scale
local new_cx = new_sw/2
local new_cy = new_sh/2
local padw = (gr.getWidth() - new_sw)/2
local padh = (gr.getHeight() - new_sh)/2

ls.typing.set_measure_tool(function(text)
    return gr.getFont():getWidth(text)
end)

local lsvn = {}
lsvn.assets = asset.assets
lsvn.settings = settings.default

lsvn.get_global_scale = function()
    return global_scale
end
lsvn.get_resized_screen_matrix = function()
    return new_sw, new_sh, padw, padh
end

local get_state_manager = function()
    local state = {}
    state.colors = {}
    state.colors.background = manager.colors.background

    state.screens = {}
    if manager.screens._current_active then
        state.screens.current_active_args = current_screen_args
        state.screens.current_active_id = manager.screens._current_active.id_name
    end
    return state
end

local set_state_manager = function(state)
    manager.colors.background = state.colors.background
    if state.screens.current_active_id then
        activate_screen(state.screens.current_active_id, unpack(state.screens.current_active_args))
    end
end

local load_screens_assets = function(screens_path)
    local screens_source = asset.get_source(screens_path)
    for _, screen in pairs(screens_source) do
        manager.screens[screen.id_name] = screen
    end
end

local format_for_save_slot = function(slot)
    return settings.game_name.."_"..settings.game_version.."_slot_"..string.format("%0"..string.len(tostring(settings.slot_for_saving)).."d", slot)..".data"
end

local save_state = function(storage_names, slot)
    slot = slot or 1
    assert(slot <= settings.slot_for_saving)
    local state = {}
    state.lovestory = ls.get_state(storage_names)
    state.manager = get_state_manager()
    state.screens = {}

    for _,screen in pairs(manager.screens) do
        state.screens[screen.id_name] = screen.on_save(slot)
    end

    local save_data = binser.s(state)

    local s, m = fs.write(format_for_save_slot(slot), save_data)
    return s, m
end


local load_state = function(slot)
    local info = fs.getInfo(format_for_save_slot(slot))
    if info == nil then return false end

    local load_data = fs.read(format_for_save_slot(slot))
    local state = binser.dn(load_data)
    ls.revive_state(state.lovestory)
    set_state_manager(state.manager)

    for _,screen in pairs(manager.screens) do
        screen.on_load(state.screens[screen.id_name])
    end
    return true
end

lsvn.save_table = function(filename, tab)
    local save_data = binser.s(tab)
    local s, m = fs.write(settings.game_name.."_"..settings.game_version.."."..filename, save_data)
    return s, m
end

lsvn.load_table = function(filename)
    local data, msg = fs.read(settings.game_name.."_"..settings.game_version.."."..filename)
    if data == nil then return false, msg end
    local tab = binser.dn(data)
    return true, tab
end


lsvn.save_state = save_state
lsvn.load_state = load_state
lsvn.get_source = asset.get_source
lsvn.resize_image_data = resize_image_data
lsvn.new_screen = function(nm, req)
    return manager.new_screen(nm, req, lsvn.get_global_scale, lsvn.get_resized_screen_matrix)
end
lsvn.save_settings = function()
    local set = {}
    for k,v in pairs(lsvn.settings) do
       set[k] = v
    end
    local set_data = binser.s(set)
    local s, m = fs.write(settings.game_name.."_"..settings.game_version.."_user_settings.data", set_data)
    assert(s, "Failed to save settings data.")
end

lsvn.load_settings = function()
    local info = fs.getInfo(settings.game_name.."_"..settings.game_version.."_user_settings.data")
    if info == nil then
        lsvn.save_settings()
        return
    end
    local set_data = fs.read(settings.game_name.."_"..settings.game_version.."_user_settings.data")
    local settings_loaded = binser.dn(set_data)
    for k,v in pairs(settings_loaded) do
       lsvn.settings[k] = v
    end
end

local register_com = function()
    ls.command.register("call", function(name, ...)
        if manager.screens.default and manager.screens.default.pause then
            manager.screens.default.pause()
            manager.screens.default.hide()
        end
        manager.activate_screen(name, ...)
    end)
end

lsvn.init = function(...)
    register_com()
    love.window.setTitle(settings.game_name)
    fs.setIdentity(settings.game_name)
    local stories = asset.get_source(settings.story_folder)
    for tag, story in pairs(stories) do
        ls.add_file(story, tag)
    end
    lsvn.load_settings()
    load_screens_assets(settings.screen_folder)
    love.window.setFullscreen(lsvn.settings.fullscreen)
    gr.setBackgroundColor(hex2color(lsvn.settings.background_color))

    for _,screen in pairs(manager.screens) do
        screen.on_boot()
    end

    if manager.screens.default then
        manager.screens.default.init(...)
        manager.screens.default.active = true
    end
    ls.init_story(settings.story_init_label, settings.story_init_file)
end

lsvn.update = function(dt)
    tick.update(dt)
    ls.update(dt)
    if manager.screens.default then manager.screens.default.update(dt) end
    if manager.screens._current_active then
        manager.screens._current_active.update(dt)
    end
end
lsvn.draw = function()
    if manager.screens.default then manager.screens.default.draw(padw, padh, global_scale) end
    if manager.screens._current_active then
        manager.screens._current_active.draw(padw, padh, global_scale)
    end
    gr.setColor(hex2color("#000000"))
    gr.rectangle("fill", 0, 0, padw, gr.getHeight())
    gr.rectangle("fill", gr.getWidth() - padw, 0, padw, gr.getHeight())
    gr.rectangle("fill", 0, 0, gr.getWidth(), padh)
    gr.rectangle("fill", 0, gr.getHeight() - padh, gr.getWidth(), padh)
end

lsvn.resize = function(w, h)
    if sy.getOS() ~= "Web" then
    global_scale = calc_scale(w, h)
    new_sw = sw * global_scale
    new_sh = sh * global_scale
    new_cx = new_sw/2
    new_cy = new_sh/2
    padw = (gr.getWidth() - new_sw)/2
    padh = (gr.getHeight() - new_sh)/2
    end
    for _,screen in pairs(manager.screens) do
        screen.resize(w, h)
    end
end

lsvn.keypressed = function( key, scancode, isrepeat )
    for _,screen in pairs(manager.screens) do
        if screen.active then screen.keypressed(key, scancode, isrepeat) end
    end
end
lsvn.keyreleased = function( key, scancode )
    for _,screen in pairs(manager.screens) do
        if screen.active then screen.keyreleased(key, scancode) end
    end
end
lsvn.mousepressed = function( x, y, button, istouch, presses )
    x = x - padw
    y = y - padh
    for _,screen in pairs(manager.screens) do
        if screen.active then screen.mousepressed(x, y, button, istouch, presses) end
    end
end
lsvn.mousemoved = function( x, y, dx, dy, istouch )
    x = x - padw
    y = y - padh
    for _,screen in pairs(manager.screens) do
        if screen.active then screen.mousemoved(x, y, dx, dy, istouch) end
    end
end
lsvn.mousereleased = function( x, y, button, istouch, presses )
    x = x - padw
    y = y - padh
    for _,screen in pairs(manager.screens) do
        if screen.active then screen.mousereleased(x, y, button, istouch, presses) end
    end
end
lsvn.textinput = function( text )
    for _,screen in pairs(manager.screens) do
        if screen.active then screen.textinput(text) end
    end
end
lsvn.textedited = function( text, start, length )
    for _,screen in pairs(manager.screens) do
        if screen.active then screen.textedited(text, start, length) end
    end
end
lsvn.touchpressed = function( id, x, y, dx, dy, pressure )
    x = x - padw
    y = y - padh
    for _,screen in pairs(manager.screens) do
        if screen.active then screen.touchpressed(id, x, y, dx, dy, pressure) end
    end
end
lsvn.touchmoved = function( id, x, y, dx, dy, pressure )
    x = x - padw
    y = y - padh
    for _,screen in pairs(manager.screens) do
        if screen.active then screen.touchmoved(id, x, y, dx, dy, pressure) end
    end
end
lsvn.touchreleased = function( id, x, y, dx, dy, pressure )
    x = x - padw
    y = y - padh
    for _,screen in pairs(manager.screens) do
        if screen.active then screen.touchreleased(id, x, y, dx, dy, pressure) end
    end
end
return lsvn
