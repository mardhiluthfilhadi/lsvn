local BASE = (...):match('(.-)[^%.]+$')
local ls = require(BASE.."external.lovestory")
local lsvn = require "lsvn"
local rgba = require "lsvn.external.hex2color"
local settings = require("settings")
local gr = love.graphics


local function resize_image_data(imageData, w, h)
    local new_data = love.image.newImageData(w, h)
    for i=0, new_data:getHeight() - 1 do
        for j=0, new_data:getWidth() - 1 do
            local normx = j/new_data:getWidth()
            local normy = i/new_data:getHeight()
            local x = math.floor(normx*imageData:getWidth())
            local y = math.floor(normy*imageData:getHeight())
            new_data:setPixel(j, i, imageData:getPixel(x, y))
        end
    end
    return new_data
end


local save_slot_data = function(image, slot)
    local data = {}
    local thumb = lsvn.resize_image_data(image, settings.slot_thumb_width, settings.slot_thumb_height)
    thumb:encode("png", settings.game_name..".thumb_slot_"..slot..".dat")
    data.slot = slot
    data.label = string.sub(ls.label_story, string.find(ls.label_story, "@") + 1, #ls.label_story)
    data.text = ls.typing.fulltext
    data.date = os.date()
    return lsvn.save_table("slot_"..slot..".dat", data)
end

local load_slot_data = function(slot)
    local s, data = lsvn.load_table("slot_"..slot..".dat")
    if not s  then return false, data end
    data.thumb = love.image.newImageData(settings.game_name..".thumb_slot_"..slot..".dat")
    return true, data
end

local get_all_slot = function()
    local all_data = {}
    local length = 0
    for i=1, settings.slot_for_saving do
        local s, data = load_slot_data(i)
        if s then
            all_data[tostring(i)] = data
            length = length + 1
        end
    end
    return all_data, length
end

local create_slot = function(screen, data, x, y)
    local gui = screen.plugin.gui
    local slot = {}
    slot.x = x or 0
    slot.y = y or 0
    slot.thumb = gui.imgbtn(data.thumb).set_anchor(.5).set_callbacs(function()
        screen.load_slot(data.slot)
    end)
    slot.title = gui.lbl(data.label, {align="center"}).set_anchor(.5)
    slot.text = gui.lbl(data.text, {align="center"}).set_anchor(.5)
    return slot
end

local create_empty_slot = function(screen, slot, x, y)
    local gui = screen.plugin.gui
    local slot = {}
    slot.x = x or 0
    slot.y = y or 0
    slot.thumb = gui.btn(".").set_anchor(.5).set_callbacs(function()
        screen.save_slot(slot)
    end)
    slot.title = gui.lbl("", {align="center"}).set_anchor(.5)
    slot.text = gui.lbl("", {align="center"}).set_anchor(.5)
    return slot
end

local create_base = function(screen)
    local sw = screen.manager.settings.screen_width
    local sh = screen.manager.settings.screen_height
    local cx = sw/2
    local cy = sh/2
    local result = {}

    result.background = nil
    result.characters = {}
    result.cgs = {}

    result.draw = function()
        screen.image.draw(result.background)
        for k, img in pairs(result.characters) do
            screen.image.draw(img)
        end
        for k, img in pairs(result.cgs) do
            screen.image.draw(img)
        end
    end
    result.on_save = function()
        local data = {}
        if result.background then
            data.background = screen.image.save(result.background)
        end
        data.characters = {}
        for k,img in pairs(result.characters) do
            data.characters[k] = screen.image.save(img)
        end
        data.cgs = {}
        for k,img in pairs(result.cgs) do
            data.cgs[k] = screen.image.save(img)
        end
        return data
    end
    result.on_load = function(images)
        result.background = nil
        result.characters = {}
        result.cgs = {}
        if images.background then
            result.background = screen.image.new(images.bg)
        end
        if images.characters then
            for k,v in pairs(images.characters) do
                result.characters[k] = screen.image.new(v)
            end
        end
        if images.cgs then
            for k,v in pairs(images.cgs) do
                result.cgs[k] = screen.image.new(v)
            end
        end
    end
    return result
end


local text_box = function(screen, x, y, bg_img, name_font, text_font, cps, m_width)
    local sw = screen.manager.settings.screen_width
    local sh = screen.manager.settings.screen_height
    local cx = sw/2
    local cy = sh/2
    ls.typing.char_per_sec = cps or 120
    ls.typing.max_width= m_width or 600
    local result = {}
    result.x, result.y = x, y
    result.name_font, result.text_font = name_font, text_font
    result.hided = true
    result.bg = screen.image.new(bg_img, cx, y)
    result.bg.set_anchor(.5, 0)
    result.bg.set_scale(sw/result.bg.width * .95)
    result.name = screen.plugin.gui.lbl("", {font=result.name_font, align="left", color = {normal={fg = rgba("#775555")}}}, result.x, result.y + 20, result.bg.width, result.name_font:getHeight())
    result.text = screen.plugin.gui.lbl("", {font=result.text_font, align="left", color = {normal={fg = rgba("#775555")}}}, result.x, result.y + 50, result.bg.width, result.name_font:getHeight())

    result.update = function(dt)
        ls.update(dt)
        if result.hided then return end

        result.name.value = ls.typing.name
        result.text.value = ls.typing.text

        screen.plugin.gui.add(result.name)
        screen.plugin.gui.add(result.text)
    end
    result.draw = function()
        if result.hided then return end
        screen.image.draw(result.bg)
    end

    return result
end


local create_hud = function(screen, conf)
    assert(conf ~= nil, "Give me some conf table. by object.vn_hud()")
    local sw = screen.manager.settings.screen_width
    local sh = screen.manager.settings.screen_height
    local cx = sw/2
    local cy = sh/2
    local result = {}
    result.text_box = text_box(
        screen,
        conf.text_box.x,
        conf.text_box.y,
        conf.text_box.img,
        conf.text_box.name_font,
        conf.text_box.text_font,
        conf.text_box.typing_char_per_sec,
        conf.text_box.typing_max_width
    )

    result.ctc = screen.plugin.gui.btn("ctc bruh", {draw=function()end}, 0, 0, sw, sh)
    result.ctc.set_callbacs(function()
        local skipped = false
        for _,node in pairs(screen.plugin.tween) do
            if node.progress then
                if node.progress < 1 then
                    node.progress = 1
                    skipped = true
                end
            end
        end
        if not skipped then
            ls.next_action()
        end
        if #ls.typing.fulltext > 0 then
            result.text_box.hided = false
        end
    end)

    result.face = nil
    local image_btns = {}
    result.update = function(dt)
        if result.text_box.hided and #ls.typing.fulltext > 0 then
            result.text_box.hided = false
        end

        if ls.choice.active then
            if #ls.choice.current_choice_titles[1] >= 4 then
                if #image_btns == 0 then
                for i=1, ls.choice.length do
                    local tok = ls.choice.current_choice_titles[i]
                    local file = string.sub(tok[2].token, 2, #tok[2].token - 1)
                    local img = lsvn.get_source(screen.manager.settings.cg_folder.."."..file)
                    tok[5] = tok[5] or {}
                    tok[6] = tok[6] or {}
                    local width = tonumber(tok[5].token)
                    local height = tonumber(tok[6].token)
                    image_btns[i] = screen.plugin.gui.imgbtn(img, tonumber(tok[3].token), tonumber(tok[4].token), width, height)
                end
                else
                    gr.setColor(1,1,1,1)
                    for index,btn in ipairs(image_btns) do
                    if screen.plugin.gui.add(btn).hit then
                        ls.pick_choice(index)
                        image_btns = {}
                    end
                    end
                end
            else
                for i=1, ls.choice.length do
                    local title = string.sub(ls.choice.current_choice_titles[i][2].token, 2, #ls.choice.current_choice_titles[i][2].token - 1)
                    if screen.plugin.gui.add(screen.plugin.gui.btn(title, cx - 200, 200 + (40 * (i - 1)), 400, 30)).hit then
                        ls.pick_choice(i)
                    end
                end
            end
        else
            screen.plugin.gui.add(result.ctc)
        end

        if not paused then
            result.text_box.update(dt)
        end
    end

    result.draw = function()
        result.text_box.draw()
        screen.image.draw(result.face)
    end

    return result
end


local create_navbar = function(screen, x, y, opt)
    assert(screen ~= nil, "You must provide your screen for this to work properly.")
    opt = opt or {}
    opt.padding = opt.padding or {}
    local nav = {}
    nav.status = "opened"
    nav.vertical = opt.vertical or false
    nav.toggle_btn_hided = opt.toggle_btn_hided
    nav.x = x or -180
    nav.y = y or 40
    nav.child_width = opt.child_width or nil
    nav.child_height = opt.child_height or nil
    nav.padding = {x = opt.padding.x or 10, y = opt.padding.y or opt.padding.x or 10}
    nav.font = opt.font or love.graphics.getFont()
    nav.anim = screen.plugin.tween
    nav.gui = screen.plugin.gui
    nav.toggle_btn = nav.gui.btn(" ", {
        font = nav.font,
        cornerRadius = opt.cornerRadius or 30,
        color = opt.color or {
            hovered = {bg = rgba("#FFDA00"), fg = rgba("#FFFFFF")},
            normal  = {bg = rgba("#FFDA00"), fg = rgba("#FFFFFF")},
            active  = {bg = rgba("#CBFFEA"), fg = rgba("#FFFFFF")},
        }
    }).set_callbacs(function()
        if not screen.paused then
            nav.toggle()
        end
    end)
    nav.childs = {}
    nav.add = function(gui)
        if gui.kind then
            nav.child_width = nav.child_width or gui.width
            nav.child_width = nav.child_height or gui.height
            gui.opt.font = gui.opt.font or nav.font
            table.insert(nav.childs, gui)
        elseif gui[1].kind then
            for i=1, #gui do
                nav.child_width = nav.child_width or gui[i].width
                nav.child_width = nav.child_height or gui[i].height
                gui[i].opt.font = gui[i].opt.font or nav.font
                table.insert(nav.childs, gui[i])
            end
        else
            assert(false, "Must provide gui element or array of gui element!")
        end
    end

    nav.aligment = {}
    nav.aligment.row = function(...)
        return nav.gui.lyt:row(...)
    end
    nav.aligment.col = function(...)
        return nav.gui.lyt:col(...)
    end

    nav.update = function(dt)
        local mode = "col"
        if nav.vertical then
            mode = "row"
        end
        nav.gui.lyt:reset(nav.x, nav.y)
        nav.gui.lyt:padding(nav.padding.x, nav.padding.y)
        local anyHit = false
        for _,btn in ipairs(nav.childs) do
            if nav.gui.add(btn.bound(nav.aligment[mode](btn.width or nav.child_width or 180, btn.height or nav.child_height or 60))).hit then
                anyHit = true
            end
        end
        if not nav.toggle_btn_hided then
            nav.toggle_btn.bound(
                nav.n_child_left(1, 40, 40)
            )
            if nav.toggle_btn.x < 10 then
                nav.toggle_btn.x = 10
            end
            nav.gui.add(nav.toggle_btn)
        end
    end

    nav.draw = function(ox, oy, scl)
        if nav.status == "opened" and
        nav.gui.instance:anyHit() and
        nav.gui.instance:isHit(screen.hud.ctc.id) and
        not nav.gui.instance:isHit(nav.toggle_btn.id) and
        not anyHit then
            nav.toggle()
        end
    end

    nav.pause = function()
        nav.toggle_btn.x = -180
        nav.status = "closed"
        nav.x = nav.closed.x or nav.x
        nav.y = nav.closed.y or nav.y
        nav.child_width = nav.closed.child_width or nav.child_width or 180
        nav.child_height = nav.closed.child_height or nav.child_height or 60

        nav.toggle_btn.value = " "
        nav.toggle_btn.opt.cornerRadius = 30
        nav.toggle_btn.opt.color.hovered = {bg = rgba("#FFDA00"), fg = rgba("#FFFFFF")}
        nav.toggle_btn.opt.color.normal  = {bg = rgba("#FFDA00"), fg = rgba("#FFFFFF")}
    end

    nav.set_states = function(current, opened, closed, dur)
        assert((current == "opened" or current == "closed"), "Current states is must be 'opened' or 'closed'")
        nav.status = current
        nav.move_duration = dur or .5
        nav.opened = opened or {x = 40}
        nav.closed = closed or {x = -180}
        nav.x = nav[nav.status].x or nav.x
        nav.y = nav[nav.status].y or nav.y
        nav.child_width = nav[nav.status].child_width or nav.child_width or 180
        nav.child_height = nav[nav.status].child_height or nav.child_height or 60
    end

    nav.toggle = function(ease)
        if nav.status == "opened" then
            nav.toggle_btn.value = ""
            nav.toggle_btn.opt.cornerRadius = 30
            nav.toggle_btn.opt.color.normal.bg = rgba("#FFDA00")
            nav.toggle_btn.opt.color.hovered.bg = rgba("#FFDA00")
            nav.status = "closed"
            nav.anim:to(nav, nav.move_duration, nav.closed):ease(ease or "linear")
        elseif nav.status == "closed" then
            nav.toggle_btn.value = "X"
            nav.toggle_btn.opt.cornerRadius = 0
            nav.toggle_btn.opt.color.normal.bg = rgba("#FF1818")
            nav.toggle_btn.opt.color.hovered.bg = rgba("#FF1818")
            nav.status = "opened"
            nav.anim:to(nav, nav.move_duration, nav.opened):ease(ease or "linear")
        end
    end
    nav.n_child_left = function(n, w, h)
        local x = (nav.childs[n].x or 0) + (nav.childs[n].width or 0) + nav.padding.x
        local y = (nav.childs[n].y or 0)
        return x, y, w or nav.childs[n].width, h or nav.childs[n].height
    end
    nav.n_child_right = function(n, w, h)
        local x = (nav.childs[n].x or 0) - (w or nav.childs[n].width or 0) - nav.padding.x
        local y = (nav.childs[n].y or 0)
        return x, y, w or nav.childs[n].width, h or nav.childs[n].height
    end
    nav.n_child_top = function(n, w, h)
        local x = (nav.childs[n].x or 0)
        local y = (nav.childs[n].y or 0) - (h or nav.childs[n].height or 0) - nav.padding.y
        return x, y, w or nav.childs[n].width, h or nav.childs[n].height
    end
    nav.n_child_bottom = function(n, w, h)
        local x = (nav.childs[n].x or 0)
        local y = (nav.childs[n].y or 0) + (nav.childs[n].height or 0) + nav.padding.y
        return x, y, w or nav.childs[n].width, h or nav.childs[n].height
    end
    return nav
end


-- -- This is function for registering ls command
local init_command_base_hud = function(screen)
    local base = screen.base
    local hud = screen.hud
    local sw = screen.manager.settings.screen_width
    local sh = screen.manager.settings.screen_height
    local cx = sw/2
    local cy = sh/2
    ls.command.register("bg", function(img, opt, conf)
        if img == false then
            if opt then
                screen.plugin.tween:to(base.background, (opt.time or 1), opt.props):ease(opt.ease or "linear"):oncomplete(function()
                    base.background = nil
                    ls.next_action()
                end)
            else
                base.background = nil
                ls.next_action()
            end
        elseif string.sub(img, 1, 1) == "#" then
            local bg_color = screen.plugin.rgba(img)
            gr.setBackgroundColor(bg_color)
            opt = opt or {}
            if opt.continue then
                ls.next_action()
            end
        else
            opt = opt or {}
            base.background = screen.image.new(screen.manager.settings.background_folder.."."..img, opt.x, opt.y, opt.r, opt.sx, opt.sy)
            opt.anchor = opt.anchor or {}
            base.background.set_anchor(opt.anchor.x, opt.anchor.y)
            base.background.alpha = opt.alpha or 1
            base.background.tint = opt.tint or "#ffffff"
            if conf then
                screen.plugin.tween:to(base.background, (conf.time or 1), conf.props):ease(conf.ease or "linear"):oncomplete(function()
                    if opt.continue then
                        ls.next_action()
                    end
                end)
            else
                if opt.continue then
                    ls.next_action()
                end
            end
        end
    end)

    local ch_pos = {
        most_left={x=0, y=cy, anchor={x=0, y=0.5}},
        left={x=cx/2, y=cy, anchor={x=0.5, y=0.5}},
        center={x=cx, y=cy, anchor={x=0.5, y=0.5}},
        right={x=cx+cx/2, y=cy, anchor={x=0.5, y=0.5}},
        most_right={x=sw, y=cy, anchor={x=1, y=0.5}},
        face={x=0, y=hud.text_box.y - 25, anchor={x=0, y=0}}
    }

    ls.command.register("ch", function(name, img, opt, conf)
        if tag == false then
            if img then
                local setted = false
                for key,ch in pairs(base.characters) do
                    screen.plugin.tween:to(ch, (img.time or 1), img.props):ease(img.ease or "linear"):oncomplete(function()
                        base.characters[key] = nil
                        if not setted then
                            setted = true
                            ls.next_action()
                        end
                    end)
                end
            else
                base.characters = {}
                ls.next_action()
            end
        elseif img == false then
            if name == 'face' then
                hud.face = nil
                base.characters[name] = nil
                hud.text_box.x = def_config.text_box.x
                ls.next_action()
                return
            end
            if opt then
                screen.plugin.tween:to(base.characters[name], (opt.time or 1), opt.props):ease(opt.ease or "linear"):oncomplete(function()
                    base.characters[name] = nil
                    ls.next_action()
                end)
            else
                base.characters[name] = nil
                ls.next_action()
            end
        else
            if ch_pos[name] then
                opt = opt or {}
                opt.x = opt.x or ch_pos[name].x
                opt.y = opt.y or ch_pos[name].y
                opt.anchor = opt.anchor or ch_pos[name].anchor
            else
                opt = opt or {}
                opt.anchor = opt.anchor or {}
            end

            base.characters[name] = screen.image.new(screen.manager.settings.character_folder.."."..img, opt.x, opt.y, opt.r, opt.sx, opt.sy)
            base.characters[name].set_anchor(opt.anchor.x, opt.anchor.y)
            base.characters[name].alpha = opt.alpha or 1
            base.characters[name].tint = opt.tint or "#ffffff"
            if name == 'face' then
                hud.face = screen.image.new(base.characters[name])
                base.characters[name] = nil
                hud.text_box.x = hud.face.width * hud.face.sx
                if opt.continue then
                    ls.next_action()
                end
                return
            end
            if conf then
                screen.plugin.tween:to(base.characters[name], (conf.time or 1), conf.props):ease(conf.ease or "linear"):oncomplete(function()
                    if opt.continue then
                        ls.next_action()
                    end
                end)
            else
                if opt.continue then
                    ls.next_action()
                end
            end
        end
    end)

    ls.command.register("cg", function(tag, img, x, y, opt, conf)
        if tag == false then
            if img then
                local setted = false
                for key,cg in pairs(base.cgs) do
                    screen.plugin.tween:to(cg, (img.time or 1), img.props):ease(img.ease or "linear"):oncomplete(function()
                        base.cgs[key] = nil
                        if not setted then
                            setted = true
                            ls.next_action()
                        end
                    end)
                end
            else
                base.cgs = {}
                ls.next_action()
            end
        elseif img == false then
            if x then
                screen.plugin.tween:to(base.cgs[tag], (x.time or 1), x.props):ease(x.ease or "linear"):oncomplete(function()
                    base.cgs[tag] = nil
                    ls.next_action()
                end)
            else
                base.cgs[tag] = nil
                ls.next_action()
            end
        else
            opt = opt or {}
            base.cgs[tag] = screen.image.new(screen.manager.settings.cg_folder.."."..img, x or cx, y or cy, opt.r, opt.sx, opt.sy)

            opt.anchor = opt.anchor or {}
            base.cgs[tag].set_anchor(opt.anchor.x, opt.anchor.y)
            base.cgs[tag].alpha = opt.alpha or 1
            base.cgs[tag].tint = opt.tint or "#ffffff"
            if conf then
                screen.plugin.tween:to(base.cgs[tag], (conf.time or 1), conf.props):ease(conf.ease or "linear"):oncomplete(function()
                    if opt.continue then
                        ls.next_action()
                    end
                end)
            else
                if opt.continue then
                    ls.next_action()
                end
            end
        end
    end)

    ls.command.register("msgbox", function(visible)
        ls.typing.fulltext = ""
        hud.text_box.hided = (not visible)
        ls.next_action()
    end)

    local shrtd = {
        bg = "background",
        ch = "characters",
        cg = "cgs",
    }

    ls.command.register("tween", function(obj, name, conf)
        if obj == "bg" then
            screen.plugin.tween:to(base[shrtd[obj]], (name.time or 1), name.props):ease(name.ease or "linear"):oncomplete((name.oncomplete or function()end)):onstart((name.onstart or function()end))
        else
            screen.plugin.tween:to(base[shrtd[obj]][name], (conf.time or 1), conf.props):ease(conf.ease or "linear"):oncomplete((conf.oncomplete or function()end)):onstart((conf.onstart or function()end))
        end
    end)
end

local get_resized_screen_matrix = function()
    return lsvn.get_resized_screen_matrix()
end
local get_global_scale = function()
    return lsvn.get_global_scale()
end

local M = {}
M.object = {}
M.object.vn_base = create_base
M.object.vn_hud = create_hud
M.object.navbar = create_navbar
M.init_base_hud = init_command_base_hud
M.save_slot_data = save_slot_data
M.load_slot_data = load_slot_data
M.get_all_slot = get_all_slot
M.get_resized_screen_matrix = get_resized_screen_matrix
M.get_global_scale = get_global_scale
return M
