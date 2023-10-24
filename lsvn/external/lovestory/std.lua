local BASE = (...):match('(.-)[^%.]+$')
local parser = require(BASE.."parser")
local lexer = require(BASE.."lexer")
local s_util = require(BASE.."string_utils")

-- LET COMMAND
local operators = {
    ["boolean"] = {
        "==",
        "~=",
        ">=",
        "<=",
        ">",
        "<"
    },
    ["number"] = {
        "+",
        "-",
        "*",
        "/"
    },
    ["string"] = {
        "%.%."
    }
}

local types = {}
local type_kind = {
    "number",
    "table",
    "string",
    "function",
    "boolean",
    "keyword",
    "comment",
}
local type_to_enum = {
    ["number"] = 1,
    ["table"] = 2,
    ["string"] = 3,
    ["function"] = 4,
    ["boolean"] = 5,
}
local get_global_constant = function(core)
    local global_constant = ""
    for i=1, #core.story_global_constants do
        global_constant = global_constant.."local "..lexer(core.story_global_constants[i].name)[1].token.." = "..core.story_global_constants[i].value.."\n"
    end
    return global_constant
end

local is_cirdep = function(name, value)
    if string.find(value.token, name.token) == nil then return false end
    if name.token == value.token then return true end
    if value.typed== "function" then return false end
    if value.typed == "keyword" then return false end
    local ope = 1
    local may_cirdep = s_util.split_by_char(value.token, operators[value.typed][ope])
    while #may_cirdep == 1 do
        if ope == #operators[type_kind[value.typed]] then break end
        ope = ope + 1
        local may_cirdep = s_util.split_by_char(value.token, operators[type_kind[value.typed]][ope])
    end
    for i=1, #may_cirdep do
        if s_util.trim(may_cirdep[i]) == name.token then
            return true
        end
    end
    return false
end

local handle_circular_depend = function(value, core)
    local parse = loadstring or load
    local global_constant = get_global_constant(core)
    value.token = parse(global_constant.."\nreturn "..value.token)()

    if value.typed == "string" then
        value.token = "'"..value.token.."'"
    end
    if value.typed == "keyword" then
        value.typed = type_to_enum[type(value.token)]
    end
    return value
end

local handle_returned_expression = function(value, core)
    local parse = loadstring or load
    local global_constant = get_global_constant(core)
    local liter = parse(global_constant.."\nreturn "..value.token)()
    value.typed = type(liter)
    return value
end

return function(core)
    core.command.register("end", function()
        core.next_command()
    end)


    -- STORE COMMAND
    core.command.register("store", function(tag, value, storage_name)
        core.storage.set(tag, value, storage_name)
        core.next_command()
    end)

    -- ADD NEW GLOBAL VARIABLE TO STORY
    core.command.register("let", function(name, value)
        local index = core.index_story
        local file = string.sub(core.label_story, 1, string.find(core.label_story, "@") - 1)..".txt"
        if is_cirdep(name, value) then
            value = handle_circular_depend(value, core)
        end
        if value.typed == "keyword" then
            value = handle_returned_expression(value, core)
            assert(value.typed ~= nil, "\n[EROR] "..file..":"..index..":"..tostring(6 + #name.token)..":".." "..value.token.." is not defined.")
        end
        local i = 1
        local found = false
        while i <= #core.story_global_constants do
            if core.story_global_constants[i].name == name.token then
                assert(
                    types[name.token] == value.typed,
                    "\n[EROR] "..file..":"..index..":"..tostring(6 + #name.token)..":".." Attemp to assign deffrend type to "..name.token.." (expected: "..types[name.token]..", but got: "..value.typed..")"
                )
                core.story_global_constants[i] = {name=name.token, value=value.token}
                found = true
                break
            end
            i = i+1
        end
        if not found then

        types[name.token] = value.typed
        table.insert(core.story_global_constants, {name=name.token, value=value.token})

        end
        core.next_command()
    end, true)

    -- REMOVE GLOBAL VARIABLE BY NAME
    core.command.register("free", function(name)
        for i=1, #core.story_global_constants do
            if core.story_global_constants[i].name == name.token then
                table.remove(core.story_global_constants, i)
                core.next_command()
                return
            end
        end

    end, true)
    core.command.register("run", function(fn, ...)
        fn(...)
    end)
end
