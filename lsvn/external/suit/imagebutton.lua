-- This file is part of SUIT, copyright (c) 2016 Matthias Richter

local BASE = (...):match('(.-)[^%.]+$')

local function isType(val, typ)
	return type(val) == "userdata" and val.typeOf and val:typeOf(typ)
end

return function(core, normal, ...)
	local opt, x,y,w,h = core.getOptionsAndSize(...)
	opt.normal = normal or opt.normal or opt[1]
	opt.hovered = opt.hovered or opt[2] or opt.normal
	opt.active = opt.active or opt[3] or opt.hovered
	opt.id = opt.id or opt.normal

	local image = assert(opt.normal, "No image for state `normal'")
  local sx, sy = w/image:getWidth(), h/image:getHeight()
	core:registerMouseHit(opt.id, x, y, function(u,v)
		-- mouse in image?
		u, v = math.floor(u+.5), math.floor(v+.5)
		if u < 0 or u >= image:getWidth()*sx or v < 0 or v >= image:getHeight()*sy then
			return false
		end

		if opt.mask then
			-- alpha test
			assert(isType(opt.mask, "ImageData"), "Option `mask` is not a love.image.ImageData")
			assert(u < mask:getWidth()*sx and v < mask:getHeight()*sy, "Mask may not be smaller than image.")
			local i,j = math.floor(u/sx), math.floor(v/sy)
			local _,_,_,a = mask:getPixel(u,v)
			return a > 0
		end
		return true
	end)

	if core:isActive(opt.id) then
		image = opt.active
	elseif core:isHovered(opt.id) then
		image = opt.hovered
	end

	assert(isType(image, "Image"), "state image is not a love.graphics.image")

	core:registerDraw(opt.draw or function(image,x,y,sx,sy, r,g,b,a)
		love.graphics.setColor(r,g,b,a)
		love.graphics.draw(image,x,y, 0, sx,sy)
	end, image, x,y, sx,sy, love.graphics.getColor())

	return {
		id = opt.id,
		hit = core:mouseReleasedOn(opt.id),
		hovered = core:isHovered(opt.id),
		entered = core:isHovered(opt.id) and not core:wasHovered(opt.id),
		left = not core:isHovered(opt.id) and core:wasHovered(opt.id)
	}
end
