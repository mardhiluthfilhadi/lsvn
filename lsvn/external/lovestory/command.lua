local BASE = (...):match('(.-)[^%.]+$')
local parser = require(BASE.."parser")
local register_command = function(core, tag, func, parsed)
    assert(core.commands[tag] ~= "exists", "Tag of command already exists. Pick other tag name.")
    core.parser.callbacks[tag] = func
    core.commands[tag] = {state="exists", nonparsed=parsed or false}
end

local unregister_command = function(core, tag)
    assert(core.commands[tag] == "exists", "The command is not exists. Are you mean to register it?")
    core.parser.callbacks[tag] = nil
    core.commands[tag] = nil
end

local register_for_typing = function(core, func)
    core.parser.parse_for_typing = func
end

local M = {}
M.register = register_command
M.unregister = unregister_command
M.register_for_typing = register_for_typing
return M
