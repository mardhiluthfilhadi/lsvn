local BASE = (...):match('(.-)[^%.]+$')
local s_utils = require(BASE.."string_utils")

local typing_tag = {"pause", "skip_to_end", "skip"}
local count_delay = 0
local big_scalar = 0
local reminder_scalar = 0
local reminder_delay = 0
local wait_time = 0

local get_cleaned_text = function(text)
    local result = text
    for i=1, #typing_tag do
        result = s_utils.remove_word(result, "{"..typing_tag[i].."}")
    end
    local rem_rubish = string.find(result, "{")
    if rem_rubish ~= nil then
        result = string.sub(result, 1, rem_rubish - 1)
    end
    return result
end

-- Just dumb one for default, BUT IT WORK FOR MONOSCAPE FONT THOUGHT! ISN'T COOL?!
local measure_width = function(str, font_size)
    return string.len(str) * font_size
end
local get_wraped_text = function(str, font_size, max_width)
    local result = ""
    local wrapped_line = ""
    for ch in str:gmatch(".") do
        -- check for current char is space, because we wont split one word into two
        if ch == " " and measure_width(get_cleaned_text(wrapped_line), font_size) > max_width then
            result = result..wrapped_line.."\n"
            wrapped_line = ""
        else
            wrapped_line = wrapped_line..ch
        end
    end
    result = result..wrapped_line
    return result
end

local set_measure_tool = function(func)
    measure_width = func
end


local skip_to_end = function(core)
    core.typing.text = get_cleaned_text(core.typing.fulltext)
    core.typing.ended = true
end

local skip = function(core)
    local end_type = string.find(core.typing.fulltext, "{", string.len(core.typing.text) + core.typing.offset)
    if end_type == nil then
        skip_to_end(core)
        return
    end
    core.typing.text = get_cleaned_text(string.sub(core.typing.fulltext, 1, end_type - 1))
end

local typing_callbacks = {
    ["pause"] = function(core)
        core.typing.paused = true
    end,
    ["skip_to_end"] = skip_to_end,
    ["skip"] = skip
}
local update_typing = function(core, dt)
    if core.typing.paused then return end
    if core.typing.ended then return end
    if string.len(core.typing.text) == string.len(get_cleaned_text(core.typing.fulltext)) then
        core.typing.ended = true
    end
  	if count_delay < core.typing.delay then
  		count_delay = count_delay + 1
  		return
  	end
    local tobe_index = core.typing.offset + string.len(core.typing.text) + 1
    local tobe_type = string.sub(core.typing.fulltext, tobe_index, tobe_index)
    if tobe_type == "{" then
        local closed_curly = string.find(core.typing.fulltext, "}", tobe_index)
        local tag = string.sub(core.typing.fulltext, tobe_index + 1, closed_curly - 1)
        if typing_callbacks[tag] ~= nil then
            core.typing.offset = core.typing.offset + string.len("{"..tag.."}")
            tobe_type = ""
            typing_callbacks[tag](core)
        end
    end
    core.typing.text = core.typing.text..tobe_type
	  count_delay= 0
end

local update = function(core, dt)
    big_scalar = core.typing.char_per_sec*dt
    if big_scalar < .5 then
        reminder_delay = reminder_delay + big_scalar - math.floor(big_scalar)
        core.typing.delay = (1/big_scalar) - (1/reminder_delay)
        big_scalar = 1
    elseif big_scalar < 1 and big_scalar > .5 then
        big_scalar = 1
    elseif big_scalar > 1 then
        reminder_scalar = reminder_scalar + big_scalar - math.floor(big_scalar)
        big_scalar = math.floor(big_scalar)
    end

    local n = big_scalar + math.floor(reminder_scalar)
    for i = 1, n do
        update_typing(core, dt)
    end
    if reminder_scalar > 1 then reminder_scalar = 0 end
    if reminder_delay > 1 then reminder_delay = 0 end
end

local set_fulltext = function(core, text)
    core.typing.fulltext = get_wraped_text(text, nil, core.typing.max_width)
    core.typing.text = ""
    core.typing.ended = false
    core.typing.paused = false
    core.typing.offset = 0
end

local register_tag = function(tag, func)
    typing_callbacks[tag] = func
    table.insert(typing_tag, tag)
end

local M = {}
M.register_tag = register_tag
M.update_typing = update
M.set = set_fulltext
M.skip = skip
M.set_measure_tool = set_measure_tool
return M
