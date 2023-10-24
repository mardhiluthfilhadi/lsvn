local BASE = (...) .. "."
local lovestory = require(BASE.."core")
local parser = require(BASE.."parser")
local std_cmds = require(BASE.."std")
local storage = require(BASE.."storage")

-- LOOP HELPER
local loop_help = {}
loop_help.head_index = {}
loop_help.loop_resolve = {}
loop_help.end_index = {}

-- IF HELPER
local if_help = {}
if_help.condition_resolve = true

-- COROUTINE COMMAND
local coroutine_help = {}
coroutine_help.prev_index = 0
coroutine_help.prev_label = ""
coroutine_help.active = false

local storage_container = {}

local new_storage = function(name)
    if storage_container[name] ~= nil then return end
    storage_container[name] = {length=0}
end
new_storage("default")

local parse_file = function(core, contents, file_tag)
    return parser.parse_file(core, contents, file_tag)
end

local add_file = function(core, contents, file_tag)
    local file_parsed = parse_file(core, contents, file_tag)
    for label, items in pairs(file_parsed) do
        core.story[label] = items
    end
end

local init_story = function(core, first_label, first_file)
    first_label = first_label or "@default"
    core.file = first_file or "init"
    core.label_story = core.file..first_label
    local line = core.story[core.label_story][core.index_story]
    core.command.run(line)
end

local next_command = function(core)
    if core.index_story == #core.story[core.label_story] then return end
    if core.ended  then return end
	if core.choice.active then return end
    core.index_story = core.index_story + 1
    local line = core.story[core.label_story][core.index_story]
    core.command.run(line)
end

local next_action = function(core)
    if core.pause_action then return end
    if core.typing.paused then
        core.typing.paused = false
    elseif not core.typing.ended then
        core.typing.skip(core)
    else
        core.next_command()
    end
end

local storage_set = function(tag, value, storage_name)
    local name = storage_name or "default"
    storage.set(storage_container[name], tag, value)
end
local storage_remove = function(tag, storage_name)
    local name = storage_name or "default"
    storage.remove(storage_container[name], tag)
end
local storage_get = function(tag, storage_name)
    local name = storage_name or "default"
    return storage.get(storage_container[name], tag)
end
local storage_get_length = function(storage_name)
    local name = storage_name or "default"
    return storage_container[name].length
end

local get_current_state = function(core, storage_names)
    storage_names = storage_names or {"default"}
    local states = {}
    states.storages = {}
    states.story = {}
    states.story.constants = {}
    states.choice = {}
    states.typing = {}
    states.typing.text = core.typing.text
    states.typing.name = core.typing.name
    states.typing.fulltext = core.typing.fulltext

    for k,v in pairs(core.choice) do
        states.choice[k] = v
    end

    for i=1, #storage_names do
        states.storages[storage_names[i]] = storage_container[storage_names]
    end
    states.choice = {}
    states.choice.active = core.choice.active
    states.choice.current_choice_commands = core.choice.current_choice_commands
    states.choice.current_choice_titles = core.choice.current_choice_titles
    states.choice.length = core.choice.length

    states.story.label = core.label_story
    states.story.index = core.index_story

    for index,const in ipairs(core.story_global_constants) do
        states.story.constants[index] = const
    end

    -- LOOP HELPER
    states.loop_help = loop_help
    -- IF HELPER
    states.if_help = if_help
    -- COROUTINE COMMAND
    states.coroutine_help = coroutine_help

    return states
end

local revive_state = function(core, states)
    for k,v in pairs(states.storages) do
        storage_container[k] =  v
    end

    for k,v in pairs(states.choice) do
        core.choice[k] = v
    end

    core.typing.text = ""
    core.typing.name = states.typing.name
    core.typing.fulltext = states.typing.fulltext
    core.typing.ended = false
    core.typing.offset = 0

    core.choice.active = states.choice.active
    core.choice.current_choice_commands = states.choice.current_choice_commands
    core.choice.current_choice_titles = states.choice.current_choice_titles
    core.choice.length = states.choice.length

    core.label_story = states.story.label
    core.index_story = states.story.index

    core.story_global_constants = {}
    for index,const in ipairs(states.story.constants) do
        core.story_global_constants[index] = const
    end

    -- LOOP HELPER
    loop_help = states.loop_help
    -- IF HELPER
    if_help = states.if_help
    -- COROUTINE COMMAND
    coroutine_help = states.coroutine_help
end

lovestory.new_storage = new_storage
lovestory.storage = {}
lovestory.storage.set = storage_set
lovestory.storage.get = storage_get
lovestory.storage.remove = storage_remove
lovestory.get_state = function(storages)
    return get_current_state(lovestory, storages)
end

lovestory.revive_state = function(data)
    revive_state(lovestory, data)
end

lovestory.std_cmds = function()
    std_cmds(lovestory)
end

lovestory.next_action = function()
    next_action(lovestory)
end
lovestory.next_command = function()
    next_command(lovestory)
end
lovestory.init_story = function(first_label, first_file)
    init_story(lovestory, first_label, first_file)
end
lovestory.add_file = function(contents, file_tag)
    add_file(lovestory, contents, file_tag)
end


lovestory.get_storage = function(name)
    return storage_container[name]
end


    -- JUMP COMMAND
lovestory.command.register("jump", function(label, index, file_name)
    lovestory.file = file_name or lovestory.file
    if label then
        lovestory.label_story = lovestory.file..lovestory.label_indicator..label
    end
    lovestory.index_story = index or 1
    local line = lovestory.story[lovestory.label_story][lovestory.index_story]
    lovestory.command.run(line)
end)

    -- END STORY COMMAND
lovestory.command.register("end_story", function()
	lovestory.typing.name = ""
	lovestory.typing.set(lovestory, "")
    lovestory.ended = true
end)

    -- INCLUDE LIBRARY
lovestory.command.register("include", function(filepath)
    require(filepath)(lovestory)
    lovestory.next_command()
end)

-- While Loop Command
lovestory.command.register("while", function(cond)
    table.insert(loop_help.head_index, lovestory.index_story)
    table.insert(loop_help.end_index, parser.get_end_block(lovestory, {"while", "end_while"}))
    if cond then
        table.insert(loop_help.loop_resolve, false)
        lovestory.next_command()
    else
        table.insert(loop_help.loop_resolve, true)
        lovestory.parser.callbacks["jump"](nil, loop_help.end_index[#loop_help.end_index])
    end
end)

lovestory.command.register("break", function()
    loop_help.loop_resolve[#loop_help.loop_resolve] = true
    lovestory.parser.callbacks["jump"](nil, loop_help.end_index[#end_index])
end)

lovestory.command.register("end_while", function()
    local cond = loop_help.loop_resolve[#loop_help.loop_resolve]
    local head = loop_help.head_index[#loop_help.head_index]
    table.remove(loop_help.loop_resolve, #loop_help.loop_resolve)
    table.remove(loop_help.head_index, #loop_help.head_index)
    table.remove(loop_help.end_index, #loop_help.end_index)
    if cond then
        lovestory.next_command()
    else
        lovestory.parser.callbacks["jump"](nil, head)
    end
end)

-- IF COMMAND
lovestory.command.register("if", function(cond)
    local next_cond_index = parser.get_tag_index_within_block(lovestory, "elseif", nil, {"if", "end_if"}) or
    (parser.get_tag_index_within_block(lovestory, "else", nil, {"if", "end_if"}) or
    parser.get_end_block(lovestory, {"if", "end_if"}))
    if cond then
        if_help.condition_resolve = true
        lovestory.next_command()
    else
        if_help.condition_resolve = false
        lovestory.parser.callbacks["jump"](nil, next_cond_index)
    end
end)

lovestory.command.register("elseif", function(cond)
    if if_help.condition_resolve then
        lovestory.parser.callbacks["jump"](nil, lovestory.get_end_block(lovestory, {"if", "end_if"}, 1))
    elseif cond then
        if_help.condition_resolve = true
        lovestory.next_command()
    else
        local next_cond_index = parser.get_tag_index_within_block(lovestory, "elseif", nil, {"if", "end_if"}) or
        (parser.get_tag_index_within_block(lovestory, "else", nil, {"if", "end_if"}) or
        parser.get_end_block(lovestory, {"if", "end_if"}))

        lovestory.parser.callbacks["jump"](nil, next_cond_index)
    end
end)

lovestory.command.register("else", function(cond)
    if if_help.condition_resolve then
        lovestory.parser.callbacks["jump"](nil, parser.get_end_block(lovestory, {"if", "end_if"}, 1))
    else
        if_help.condition_resolve = true
        lovestory.next_command()
    end
end)

lovestory.command.register("end_if", function()
    if_help.condition_resolve = true
    lovestory.next_command()
end)

-- JUMP TO COROUTINE
lovestory.command.register("coroutine", function(label, index)
    coroutine_help.prev_index = lovestory.index_story
    coroutine_help.prev_label = lovestory.label_story
    coroutine_help.active = true
    lovestory.parser.callbacks['#jump'](label, index)
end)

-- END COROUTINE
lovestory.command.register("end_coroutine", function()
    if not coroutine_help.active then return end
    lovestory.index_story = coroutine_help.prev_index + 1
    lovestory.label_story = coroutine_help.prev_label
    coroutine_help.active = false
    local line = lovestory.story[lovestory.label_story][lovestory.index_story]
    lovestory.command.run(line)
end)

return lovestory
