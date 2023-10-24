local ls = require("lsvn.external.lovestory")
local lsvn = require("lsvn")
local game = require("lsvn.game")

local screen = lsvn.new_screen
local gr = love.graphics

local default = screen("default")
local gui = default.plugin.gui
local tween = default.plugin.tween
local timer = default.plugin.timer
local sound = default.plugin.sound
local assets = default.manager.assets
local settings = default.manager.settings
local rgba = default.plugin.rgba
local sw = settings.screen_width
local sh = settings.screen_height
local cx = sw/2
local cy = sh/2

-- DEFAULT VALUE FOR INIT THE STATE
local hud_config = {
    text_box = {
        x = 60,
        y = cy+cy/2.3,
        img = "assets.images.cgs.msgbox-bg",
        name_font = assets.fonts['VictorMono-Bold'](14),
        text_font = assets.fonts['VictorMono-Medium'](12),
        typing_char_per_sec = 120,
        typing_max_width = 600,
    }
}


-- //////////////////////////////
--[[

        [TODO]: NAVBAR
        [TODO]: BASIC SOUND SETTINGS
        [TODO]: BASIC TYPING SETTINGS
        [TODO]: SLOT PANEL

]]--
-- \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

-- THIS IS THE STATE OR WHATEVER
default.base = game.object.vn_base(default) -- Background, Character, and CGS
default.hud = game.object.vn_hud(default, hud_config) -- Textbox, choice, buttons, and etc
default.navbar = game.object.navbar(default, 30, 60, {vertical = true})
game.init_base_hud(default)
default.paused = false
default.hided = false

gui.theme.color = {
	normal   = {bg = rgba("#2F2149"), fg = rgba("#DCDCDC")},
	hovered  = {bg = rgba("#2F2149"), fg = rgba("#DCDCDC")},
	active   = {bg = rgba("#78C8D1"), fg = rgba("#DCDCDC")}
}
-- -- THIS IS THE ENTRY POINT YOOOIINKK...
function default.init()
    local font = assets.fonts['VictorMono-Medium'](13)
    local fullscreen = gui.btn("fullscreen", {font=font}, 0, 0, 140, 40).set_callbacs(function()
        settings.default.fullscreen = not settings.default.fullscreen
        love.window.setFullscreen(settings.default.fullscreen)
        lsvn.resize()
    end)
    local savebtn = gui.btn("save", {font=font}, 0, 0, 180, 60).set_callbacs(function()
        default.navbar.pause()
        default.goto("save")
    end)
    local loadbtn = gui.btn("load", {font=font}, 0, 0, 160, 30).set_callbacs(function()
        lsvn.load_state(1)
    end)
    local pausebtn = gui.btn("title", {font=font}, 0, 0, 100, 50).set_callbacs(function()
        default.goto("title")
    end)
    default.navbar.add({fullscreen, savebtn, loadbtn, pausebtn})
    default.navbar.set_states("closed", {x=30}, {x=-190}, .2)
end

function default.update(dt)
    if not default.hided then
    default.navbar.update(dt)
    default.hud.update(dt)
    end

    if not default.paused and not default.hided then
    tween:update(dt)
    timer:update(dt)
    end
end

function default.draw()
    if not default.hided then
    default.navbar.draw()
    default.base.draw()
    default.hud.draw()
    gui.draw()
    end
end

function default.on_save()
    local data = {}
    data.base = default.base.on_save()
    return data
end

function default.on_load(data)
    default.base.on_load(data.base)
    if ls.typing.fulltext ~= "" then
        default.hud.text_box.hided = false
    end
end

function default.pause()
    default.paused = true
    default.navbar.pause()
end

function default.hide()
    default.hided = true
end

function default.resume()
    default.hided = false
    default.paused = false
end

return default
