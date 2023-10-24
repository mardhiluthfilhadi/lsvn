local BASE = (...):match('(.-)[^%.]+$')

local s_utils = require(BASE.."string_utils")
local lexer = require(BASE.."lexer")

local get_global_constant = function(core)
    local global_constant = ""
    for i=1, #core.story_global_constants do
        global_constant = global_constant.."local "..lexer(core.story_global_constants[i].name)[1].token.." = "..core.story_global_constants[i].value.."\n"
    end
    return global_constant
end

local get_line_info = function(core, line)
    local tokens = lexer(line)
    if #tokens == 0 then return nil end
    if tokens[#tokens].typed == 7 then
        table.remove(tokens, #tokens)
    end
    if #tokens == 0 then return nil end
    local tag = tokens[1].token
    table.remove(tokens, 1)
    local args = tokens
    return tag, args
end

local get_tag_index_within_block = function(core, tag, start_index, block_indicate)
    local depth = 1
    local tokens = core.story[core.label_story]
    start_index = start_index or (core.index_story + 1)

    for i = start_index, #tokens do
        local token = lexer(tokens[i])
        if token[1].token == block_indicate[1] then
            depth = depth + 1
        elseif token[1].token == tag then
            if depth == 1 then
                return i
            end
        elseif token[1].token == block_indicate[2] then
            depth = depth - 1
            if depth == 0 then
                return nil
            end
        end
    end
    return nil
end

local get_end_block = function(core, block_indicate, init_depth)
    init_depth = init_depth or 0
    local depth = init_depth
    local tokens = core.story[core.label_story]
    local start_index = core.index_story

    for i = start_index, #tokens do
        local token = lexer(tokens[i])
        if #token >= 1 then
            if block_indicate[1] == "begin" then
                if token[2] and token[2].token == block_indicate[1] then
                    depth = depth + 1
                end
                if token[#token].typed == "function" and token[#token].states == "unfinished" then
                    depth = depth + 1
                end
                for index,tok in ipairs(token) do
                    if tok.token == "for" or
                    tok.token == "if" or
                    tok.token == "while" then
                        depth = depth + 1
                    end
                    if tok.token == "end" and index ~= 1 then
                        depth = depth - 1
                        if depth == 0 then
                            return i
                        end
                    end
                end
            end
            if token[1].token == block_indicate[1] then
                depth = depth + 1
            elseif token[1].token == block_indicate[2] then
                depth = depth - 1
                if depth == 0 then
                    return i
                end
            end
        end
    end
    local file = string.sub(core.label_story, 1, string.find(core.label_story, "@") - 1)..".txt"
    local r = core.index_story + core.story[core.label_story].index
    local c = tostring(1)
    assert(depth == init_depth, "\n[EROR] "..file..":"..r..":"..c..":".." <End of File> You seems forget to end the block with '"..block_indicate[2].."' keyword.")
    return nil
end

local parse_for_command = function(core, tag, args, ret)
    local parse = loadstring or load

    if args[1] and args[1].token == 'begin' then
        local cmd = {}
        for i=core.index_story, get_end_block(core, {"begin", "end"}) - 1 do
            table.insert(cmd, core.story[core.label_story][i])
        end
        local tobe_args = lexer(cmd, core)
        for i=1, 2 do table.remove(tobe_args, 1) end
        args = tobe_args
        core.index_story = get_end_block(core, {"begin", "end"})
    end

    local args_parsed = {}
    local global_constant = get_global_constant(core)
    local file = string.sub(core.label_story, 1, string.find(core.label_story, "@") - 1)..".txt"
    local index = core.index_story + core.story[core.label_story].index
    if core.commands[tag].nonparsed then
        args_parsed = args
    else
        for i=1, #args, 1 do
            local chunks = parse(global_constant.."\nreturn "..args[i].token)
            local ok, content = pcall(chunks)
            assert(ok, "\n\n[EROR] "..file..":"..index..":"..tostring(1)..":"..tostring(content))
            args_parsed[i] = content
        end
    end
    
    if ret then
        return {type="cmd", tag=tag, args=args}
    else
        core.parser.callbacks[tag](unpack(args_parsed))
    end
end

local parse_for_typing = function(core, line, ret)
    local line_info = lexer(line, core)
    local global_constant = get_global_constant(core)
    local parse = loadstring or load
    local parsed_line = {}
    local file = string.sub(core.label_story, 1, string.find(core.label_story, "@") - 1)..".txt"
    local index = core.index_story + core.story[core.label_story].index
    for i=1, #line_info do
        local chunks = parse(global_constant.."\nreturn "..line_info[i].token)
        local ok, content = pcall(chunks)
        assert(ok, "\n\n[EROR] "..file..":"..index..":"..tostring(1)..":"..tostring(content))
        parsed_line[i] = content
    end
    if ret then
        return {type="typ", info=line_info}
    else
        core.parser.parse_for_typing(parsed_line)
    end
end

local parse_file_contents_to_table = function(core, prepared_contents, file_name)
    assert(prepared_contents ~= nil, "File contents not provided")

	if file_name == nil then file_name = "init" end
    local labels = {}
    local label_index = string.find(prepared_contents, core.label_indicator)
    local label_lines = s_utils.count(string.sub(prepared_contents, 1, label_index), "\n") + 1
    while label_index ~= nil do
        local end_label = string.find(prepared_contents, "\n", label_index)
        if end_label == nil then end_label = #prepared_contents + 1 end
        local label_name = string.sub(prepared_contents, label_index, end_label - 1)
        label_lines = s_utils.count(string.sub(prepared_contents, 1, label_index), "\n") + 1
        table.insert(labels, {index=label_lines, name=label_name})
        label_index = string.find(prepared_contents, core.label_indicator, end_label)
    end

	local chunks = {}
	local result = {}

	if #labels == 0 then
		labels[1] = {index=0, name="@default"}
		chunks[labels[1].name] = {content=string.sub(prepared_contents, 1), index=labels[1].index}
	else

	if string.find(prepared_contents, labels[1].name) > 1 then
		chunks["@default"] = {
		    content=string.sub(
    			prepared_contents,
    			1,
    			string.find(prepared_contents, labels[1].name) - 1
    	    ),
    	    index=0
    	}
	end

    for i=1, #labels - 1 do
		chunks[labels[i].name] = {
		    content=string.sub(
    			prepared_contents,
    			string.find(prepared_contents, labels[i].name) + #labels[i].name + 1,
    			string.find(prepared_contents, labels[i + 1].name) - 1
    		),
    		index = labels[i].index
    	}
	end

	chunks[labels[#labels].name] = {
	    content=string.sub(
    		prepared_contents,
    		string.find(prepared_contents, labels[#labels].name) + #labels[#labels].name + 1
    	),
    	index = labels[#labels].index
    }
    end
	for i=1,#labels do
		if #chunks[labels[i].name].content == 0 then
			chunks[labels[i].name].content = "No child in this label\n#end_story"
		end
	end

	for k, v in pairs(chunks) do
		result[file_name..k] = s_utils.split_by_char(v.content, "\n")
		result[file_name..k].index = v.index
	end
	return result
end

local run = function(core, line)
    local tag, args = get_line_info(core, line)
    if tag == nil then core.next_action() end
    if core.commands[tag] then
        parse_for_command(core, tag, args)
    else
        parse_for_typing(core, line)
    end
end

local M = {}

M.parse_file = parse_file_contents_to_table
M.get_tag_index_within_block = get_tag_index_within_block
M.get_end_block = get_end_block
M.run = run

return M
