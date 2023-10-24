-- Wrapper of image for compatibility with
-- tweening (flux) and serializing (binser)
local BASE = (...):match('(.-)[^%.]+$')
local asset = require(BASE.."asset")
local hex2color = require(BASE.."external.hex2color")
local settings = require("settings")
local sw = settings.screen_width
local sh = settings.screen_height
local cx = sw/2
local cy = sh/2
local gr = love.graphics

local new_image = function(filepath, x, y, r, sx, sy)
    local img = {}
    if type(filepath) == "table" then
        for k,v in pairs(filepath) do
            if filepath[k] then
                img[k] = v
            end
        end
        img.source = asset.get_source(img.src)
    elseif type(filepath) == "string" then
        img.source = asset.get_source(filepath)
        img.src = filepath
        img.x = x or cx
        img.y = y or cy
        img.width = img.source:getWidth()
        img.height = img.source:getHeight()
        img.r = r or 0
        img.sx = sx or 1
        img.sy = sy or img.sx
        img.alpha = 1
        img.tint = "#ffffff"
        img.anchor = {
            x = 0.5,
            y = 0.5,
        }
    elseif type(filepath) == "userdata" then
        img.source = filepath
        img.x = x or cx
        img.y = y or cy
        img.width = img.source:getWidth()
        img.height = img.source:getHeight()
        img.r = r or 0
        img.sx = sx or 1
        img.sy = sy or img.sx
        img.alpha = 1
        img.tint = "#ffffff"
        img.anchor = {
            x = 0.5,
            y = 0.5,
        }
    end
    img.set_scale = function(x, y)
        img.sx = x or 1
        img.sy = y or img.sx
    end
    img.set_anchor = function(x, y)
        img.anchor.x = x or 0.5
        img.anchor.y = y or img.anchor.x
    end
    return img
end

local image_for_save = function(img)
    assert(img.src ~= nil, "Image can't save because no source")
    assert(img.src ~= "", "Image can't save because no source")
    if img == nil then
        return nil
    end
    local image = {}
    for k,v in pairs(img) do
        if type(v) ~= "userdata" and type(v) ~= "function" then
            image[k] = v
        end
    end
    return image
end

local draw_image_once = function(image, get_global_scale, get_resized_screen_matrix)
    if image == nil then return end
    local new_sw, new_sh, padw, padh = get_resized_screen_matrix()
    local global_scale = get_global_scale()

    local offx = image.width  * image.sx * image.anchor.x * global_scale
    local offy = image.height * image.sy * image.anchor.y * global_scale
    local trsltx = image.x * new_sw / sw + padw
    local trslty = image.y * new_sh / sh + padh
    gr.push()
    gr.setColor(hex2color(image.tint, image.alpha))
    gr.translate(trsltx, trslty)
    gr.rotate(image.r)
    gr.draw(image.source, -offx, -offy, 0, image.sx * global_scale, image.sy * global_scale)
    gr.pop()
end

local M = {}
M.new = new_image
M.save = image_for_save
M.draw = draw_image_once
return M
