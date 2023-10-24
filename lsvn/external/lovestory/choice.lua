local BASE = (...):match('(.-)[^%.]+$')
local parser = require(BASE.."parser")
local lexer = require(BASE.."lexer")

return function(core)
    core.command.register("choice", function()
        core.choice.active = true
        core.choice.current_choice_commands = {}
        core.choice.current_choice_titles = {}
        core.choice.length = 0

        local tag_indices = {}
        local index = parser.get_tag_index_within_block(core, "tag", nil, {"choice", "end_choice"})
        assert(index ~= nil, "You must provide at least 1 tag before end_choice")
        while index ~= nil do
            table.insert(tag_indices, index)
            index = parser.get_tag_index_within_block(core, "tag", index + 1, {"choice", "end_choice"})
        end

        for i=1,#tag_indices do
            core.choice.current_choice_commands[i] = tag_indices[i]
            core.choice.current_choice_titles[i] = lexer(core.story[core.label_story][tag_indices[i]])
        end
        core.choice.length = #tag_indices
    end)

    core.command.register("tag", function()
        local end_block = parser.get_end_block(core, {"choice", "end_choice"}, 1)
        core.parser.callbacks["jump"](nil, end_block)
    end)

    core.command.register("end_choice", function()
        core.next_command()
    end)

    return function(index)
        core.choice.active = false
        core.parser.callbacks["jump"](nil, core.choice.current_choice_commands[index] + 1)
    end
end
