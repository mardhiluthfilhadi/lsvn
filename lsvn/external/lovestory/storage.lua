local BASE = (...):match('(.-)[^%.]+$')

local set_item = function(storage, tag, value)
    storage[tag] = value
    storage.length = storage.length + 1
end

local get_item = function(storage, tag)
    return storage[tag]
end

local remove_item = function(storage, tag)
    if storage.length == 0 then return end
    storage[tag] = nil
    storage.length = storage.length - 1
end

local M = {}
M.set = set_item
M.get = get_item
M.remove = remove_item

return M