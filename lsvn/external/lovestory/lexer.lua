local BASE = (...):match('(.-)[^%.]+$')
local su = require(BASE.."string_utils")
-- this is implement dumb lexer but straight forward
-- no fancy stuff here
local operators = {
    ["=="] = true,
    ["~="] = true,
    [">="] = true,
    ["<="] = true,
    [">"] = true,
    ["<"] = true,
    ["+"] = true,
    ["-"] = true,
    ["*"] = true,
    ["/"] = true,
    [".."] = true,
}

local states = {
    finished = "finished",
    unfinished = "unfinished",
}

local types = {
    nmb = 'number',
    tbl = 'table',
    str = 'string',
    func = 'function',
    bool = 'boolean',
    kywrd = 'keyword',
    cmmnt = 'comment',
}

local close_sym = {
    ["table"] = "}",
    ["string"] = [[" or ']],
    ["function"] = "end",
    ["boolean"] = ")",
    ["keyword"] = ")",
}

local is_token_clean = function(tokens)
    local clean = true
    for _, tok in ipairs(tokens) do
        if tok.states == states.unfinished then
            clean = false
            r = tok.row
            c = tok.col
            return clean, r, c, close_sym[tok.typed]
        end
    end
    return clean, 0, 0, ""
end

local get_type = function(keyword)
    if keyword == "true" or
    keyword == "false" then
        return types.bool
    elseif tonumber(keyword) then
        return types.nmb
    elseif string.find(keyword, "%.%.") then
        return types.str
    elseif string.find(keyword, "=") or
    string.find(keyword, "not ") or
    string.find(keyword, " and ") or
    string.find(keyword, " or ") or
    string.find(keyword, "<") or
    string.find(keyword, ">") then
        return types.bool
    elseif string.find(keyword, "+") or
    string.find(keyword, "-") or
    string.find(keyword, "*") or
    string.find(keyword, "/") then
        return types.nmb
    else
        return types.kywrd
    end
end

local line_lexer = function(str, index, file)
    local tokens = {}
    local current_token = ""
    local in_string_single_qt = false
    local in_string_double_qt = false
    local in_string_double_br = false
    local in_comment = false
    local in_table = false
    local in_func = false
    local in_keyword = false
    local get_left = false
    local tab_depth = 0
    local func_depth = 0
    local keyword_depth = 0
    local current_kind = states.finished
    local current_type = types.kywrd
    local ends = 0
    local length = 0

    for ch in str:gmatch(".") do
        ends = ends + 1
        length = length + 1
        if ch ~= " " and
        string.sub(current_token..ch, #current_token) == "--" then
            in_comment = true
            if current_type == types.kywrd then
                current_type = get_type(current_token)
            end

            if #string.sub(current_token..ch, 1, #current_token - 1) > 0 then
                local tok = string.sub(current_token..ch, 1, #current_token - 1)
                local end_match = false
                for k,v in pairs(operators) do
                    if operators[string.sub(tok, #tok - #k + 1)] then
                       end_match = true
                    end
                end
                if end_match or
                string.sub(tok, #tok - 2) == "not" or
                string.sub(tok, #tok - 1) == "or" or
                string.sub(tok, #tok - 2) == "and" then
                    current_kind = states.unfinished
                end

                table.insert(
                    tokens,
                    {row=(index or 1), col=ends-length+1, typed=current_type, states=current_kind, token=tok}
                )
            end
            current_token = "--"
            current_kind = states.finished
            current_type = types.cmmnt
            length = 0
        elseif ch == "(" and
        not in_string_single_qt and
        not in_string_double_qt and
        not in_string_double_br and
        not in_comment and
        not in_table and
        not in_func then
            in_keyword = true
            keyword_depth = keyword_depth + 1
            current_kind = states.unfinished
            current_type = types.kywrd
            current_token = current_token .. ch
        elseif ch == ")" and in_keyword then
            keyword_depth = keyword_depth - 1
            if keyword_depth == 0 then
                in_keyword = false
                current_kind = states.finished
                current_type = types.kywrd
                current_token = current_token .. ch
                table.insert(
                    tokens,
                    {row=(index or 1), col=ends-length+1, typed=current_type, states=current_kind, token=current_token}
                )
                current_token = ""
                current_kind = states.finished
                current_type = types.kywrd
                length = 0
            else
                current_token = current_token .. ch
            end
        elseif ch == "'" and
        not in_string_single_qt and
        not in_string_double_qt and
        not in_string_double_br and
        not in_comment and
        not in_keyword and
        not in_table and
        not in_func then
            in_string_single_qt = true
            current_kind = states.unfinished
            current_type = types.str
            current_token = current_token .. ch
        elseif ch == "'" and in_string_single_qt then
            in_string_single_qt = false
            current_kind = states.finished
            current_token = current_token .. ch
        elseif current_token == '"' and
        not in_string_single_qt and
        not in_string_double_qt and
        not in_string_double_br and
        not in_comment and
        not in_keyword and
        not in_table and
        not in_func then
            in_string_double_qt = true
            current_kind = states.unfinished
            current_type = types.str
            current_token = current_token .. ch
        elseif ch == '"' and in_string_double_qt then
            in_string_double_qt = false
            current_kind = states.finished
            current_token = current_token .. ch
        elseif current_token..ch == '[[' and
        not in_string_single_qt and
        not in_string_double_qt and
        not in_string_double_br and
        not in_comment and
        not in_keyword and
        not in_table and
        not in_func then
            in_string_double_br = true
            current_kind = states.unfinished
            current_type = types.str
            current_token = current_token .. ch
        elseif current_token..ch == ']]' and in_string_double_br then
            in_string_double_br = false
            current_kind = states.finished
            current_token = current_token .. ch
        elseif ch == "{" and
        not in_string_single_qt and
        not in_string_double_qt and
        not in_string_double_br and
        not in_comment and
        not in_keyword and
        not in_func then
            tab_depth = tab_depth + 1
            in_table = true
            current_kind = states.unfinished
            current_type = types.tbl
            current_token = current_token .. ch
        elseif ch == "}" and in_table then
            tab_depth = tab_depth - 1
            if tab_depth == 0 then
                in_table = false
                current_kind = states.finished
            end
            current_token = current_token .. ch
        elseif current_token..ch == "function" and
        not in_string_single_qt and
        not in_string_double_qt and
        not in_string_double_br and
        not in_comment and
        not in_table then
            in_func = true
            func_depth = func_depth + 1
            current_type = types.func
            current_kind = states.unfinished
            current_token = current_token .. ch
        elseif ch ~= " " and
        string.sub(current_token..ch, #current_token + #ch - 2) == "end" and
        in_func then
            func_depth = func_depth - 1
            if func_depth == 0 then
                in_func = false
                current_kind = states.finished
            end
            current_token = current_token .. ch
        elseif ch == " " and
        not in_string_single_qt and
        not in_string_double_qt and
        not in_string_double_br and
        not in_comment and
        not in_keyword and
        not in_table and
        not in_func then
            local end_match = false
            local begin_match = false
            for k,v in pairs(operators) do
                if operators[string.sub(current_token, #current_token - #k + 1)] and #current_token > #k then
                   end_match = true
                end
            end
            for k,v in pairs(operators) do
                if operators[string.sub(current_token, 1, #k)] then
                   begin_match = true
                end
            end
            if end_match or
            current_token == "not" then
                current_token = current_token .. ch
            elseif current_token == "or" or
            current_token == "and" or
            operators[current_token] or
            begin_match then
                local left_expression = tokens[#tokens].token
                table.remove(tokens, #tokens)
                current_token = left_expression.." "..current_token .. ch
            elseif current_token ~= "" then
                if current_type == types.kywrd then
                    current_type = get_type(current_token)
                end

                local end_match = false
                for k,v in pairs(operators) do
                    if operators[string.sub(current_token, #current_token - #k + 1)] then
                       end_match = true
                    end
                end
                if end_match or
                string.sub(current_token, #current_token - 2) == "not" or
                string.sub(current_token, #current_token - 1) == "or" or
                string.sub(current_token, #current_token - 2) == "and" then
                    current_kind = states.unfinished
                end
                table.insert(tokens, {row=(index or 1), col=ends-length+1, typed=current_type, states=current_kind, token=current_token})
                current_token = ""
                current_kind = states.finished
                current_type = types.kywrd
                length = 0
            end
        else
            current_token = current_token .. ch
        end
    end
    if #current_token > 0 then
        if current_type == types.kywrd then
            current_type = get_type(current_token)
        end
        local end_match = false
        for k,v in pairs(operators) do
            if operators[string.sub(current_token, #current_token - #k + 1)] then
               end_match = true
            end
        end
        if end_match or
        string.sub(current_token, #current_token - 3) == " not" or
        string.sub(current_token, #current_token - 2) == " or" or
        string.sub(current_token, #current_token - 3) == " and" then
            current_kind = states.unfinished
        end
        table.insert(tokens, {row=(index or 1), col=ends-length+1, typed=current_type, states=current_kind, token=current_token})
    end
    if index and file then
        local clean, r, c , need = is_token_clean(tokens)
        assert(clean, "\n\n[EROR] "..file..":"..r..":"..c..":".." Sorry to mention bruh, but expected: "..need.." (unfinished expression)")
    end
    return tokens
end

local multiline_lexer = function(lines, index, file)
    local tokens = {}
    local current_states = nil
    local current_type = nil
    local current_token = ""
    local current_row = 0
    local parrent_type = nil
    local parrent_row = nil
    local depth = 0
    
    for row, line in ipairs(lines) do
        local current_tokens = line_lexer(line)
        for _, tok in ipairs(current_tokens) do
            if tok.typed ~= types.cmmnt then

            if tok.token == "for" or
            tok.token == "if" or
            tok.token == "while" or
            tok.states == states.unfinished then
                depth = depth + 1
                current_states = current_states or tok.states
                current_type = current_type or tok.typed
                current_row = row+index - 1
            end

            if tok.states == states.finished and (string.sub(tok.token, #tok.token - 2) == "end" or
            string.find(tok.token, "}") or
            string.find(tok.token, ")") or
            string.find(tok.token, "]]")) then
                depth = depth - 1
            end
            if tok.states == states.finished and (current_states == states.finished or current_states == nil) then
                tok.row = row+index - 1
                table.insert(tokens, tok)
            else
                current_token = current_token.." "..tok.token
                if depth == 0 then
                    local the_row = row+index - 1
                    current_states = states.finished
                    table.insert(tokens, {row=the_row, col=1, states=current_states, typed=current_type, token=current_token})
                end
            end
            end
        end
        current_token = current_token.."\n"..su.repeats(depth, "    ")
    end
    if current_token ~= "" then
        table.insert(tokens, {row=current_row, col=1, states=current_states, typed=current_type, token=current_token})
    end
    if index and file then
        local clean, r, c , need = is_token_clean(tokens)
        assert(clean, "\n\n[EROR] "..file..":"..r..":"..c..":".." Sorry to mention bruh, but expected: "..need.." (unfinished expression)")
    end
    return tokens
end

return function(contents, core)
    local index
    local file

    if core then
        index = core.index_story + core.story[core.label_story].index
        file = string.sub(core.label_story, 1, string.find(core.label_story, "@") - 1)..".txt"
    end

    if type(contents) == "string" then
        return line_lexer(contents, index, file)
    elseif type(contents) == "table" then
        return multiline_lexer(contents, index, file)
    else
        assert(false, "Unreacable contents to lex: "..type(contents))
    end
end
