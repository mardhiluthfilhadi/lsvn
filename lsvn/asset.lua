local BASE = (...):match('(.-)[^%.]+$')
local s_utils = require(BASE.."external.lovestory.string_utils")
local fs = love.filesystem
local assets = require(BASE.."external.cargo").init("assets")
local get_parsed_filepath = function(filepath)
    local list = s_utils.split_by_char(filepath, "%.")
    local fnme = list[#list]
    table.remove(list, #list)
    local fpth = s_utils.join_by_char(list, ".")
    return fpth.."['"..fnme.."']"
end

local get_source = function(filepath)
    local parse = loadstring or load
    assert(filepath ~= nil, "Filepath must be provided.")
    local source = parse("return function(assets)\nreturn "..get_parsed_filepath(filepath).."\nend")()
    local result
    if type(source(assets)) == "table"  then
        result = {}
        local file_list = fs.getDirectoryItems(source(assets)._path)
        for _, filename in ipairs(file_list) do
            local fnme = string.sub(filename, 1, #filename - 4)
            result[fnme] = source(assets)[fnme]
        end

    else
        result = source(assets)
    end
    return result
end
return {assets = assets, get_source = get_source}
