local BASE = (...):match('(.-)[^%.]+$')

local split_by_char = function(str, ch)
    local result = {}
    local begin_index = 1
    local separator_index, end_sep = string.find(str, ch)
    while separator_index ~= nil do
        local substr = string.sub(str, begin_index, separator_index - 1)
        table.insert(result, substr)
        begin_index = end_sep + 1
        separator_index, end_sep = string.find(str, ch, separator_index + 1)
    end
    local substr = string.sub(str, begin_index)
    table.insert(result, substr)
    return result
end

local join_by_char = function(tab, ch)
    if #tab == 1 then
        return tab[1]
    end
    local result = tab[1]
    for i=2,#tab do
        result = result..ch..tab[i]
    end
    return result
end

local remove_word_once = function(str, index, end_index, ch)
	if string.len(ch) == 0 then return str end
    local ch_index = string.find(str, ch, index)
    if ch_index == 0 or ch_index > end_index then return str end
    if ch_index == 1 then return string.sub(str, string.len(ch) + 1) end
    local str_begin = string.sub(str, 1, ch_index - 1)
    local str_end = string.sub(str, ch_index + string.len(ch) + 1)
    return str_begin..str_end
end

local remove_word = function(str, word)
    return join_by_char(split_by_char(str, word), "")
end

local next_no_match_index = function(str, index, ch)
	index = index + 1
    while string.sub(str, index, index + string.len(ch) - 1) == ch do
        index = index + 1
        if index > string.len(str) then
            index = 0
            break
        end
    end
    return index
end

local begin_with = function(str, ch)
    return string.sub(str, 1, string.len(ch)) == ch
end

local end_with = function(str, ch)
    return string.sub(str, string.len(str) - string.len(ch) + 1) == ch
end

local trim = function(str)
    local res = ""
    for ch in str:gmatch(".") do
        if ch ~= " " then
            res = res..ch
        end
    end
    return res
end

local count = function(str, chr)
    local vount = 0
    local i,j = string.find(str, chr, 1)
    while i ~= nil do
        vount = vount + 1
        i,j = string.find(str, chr, j + 1)
    end
    return vount
end

local reps = function(n, ch)
    local res = ""
    for i = 1, n do
        res = res..ch
    end
    return res
end

local M = {}
M.split_by_char = split_by_char
M.join_by_char = join_by_char
M.next_no_match_index = next_no_match_index
M.remove_word = remove_word
M.end_with = end_with
M.begin_with = begin_with
M.remove_word_once = remove_word_once
M.trim = trim
M.count = count
M.repeats = reps

return M
