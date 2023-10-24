local BASE = (...):match('(.-)[^%.]+$')
local parser = require(BASE.."parser")
local typed = require(BASE.."typed")
local command = require(BASE.."command")
local choice = require(BASE.."choice")

local core = {}
core.pause_action = false

core.typing = typed
core.typing.max_width = 500
core.typing.char_per_sec = 60
core.typing.delay = 1
core.typing.offset = 0
core.typing.name = ""
core.typing.text = ""
core.typing.fulltext = ""
core.typing.paused = false
core.typing.ended = true

core.story = {}
core.story_global_constants = {}
core.file = ""
core.index_story = 1
core.label_story = ""
core.label_indicator = "@"
core.ended = false

core.commands = {}
core.command = {}
core.parser = {}
core.parser.callbacks = {}

core.command.register = function(tag, func, nonparsed)
    command.register(core, tag, func, nonparsed)
end
core.command.unregister = function(tag)
    command.unregister(core, tag)
end
core.command.run = function(line)
    parser.run(core, line)
end

core.parser.parse_for_typing = function(line_info)
    if #line_info == 1 then
        core.typing.name = ""
        core.typing.set(core, line_info[1])
    elseif #line_info == 2 then
        core.typing.name = line_info[1]
        core.typing.set(core, line_info[2])
    end
end

core.parser.set_typing_parser = function(func)
    command.register_for_typing(core, func)
end

core.update = function(dt)
    core.typing.update_typing(core, dt)
end

core.choice = {}
core.choice.current_choice_commands = {}
core.choice.current_choice_titles = {}
core.choice.length = 0
core.choice.active = false
core.pick_choice = choice(core)


return core
