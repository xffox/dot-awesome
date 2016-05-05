naughty = require("naughty")
awful = require("awful")

local commandviewer = {objs = {}, commands={}}
commandviewer.interval = 10
-- use as array to preserve the order
function view_command(command)
    if commandviewer.objs[command] ~= nil then
        hide_view(commandviewer.objs[command])
        commandviewer.objs[command] = nil
        for i,v in pairs(commandviewer.commands) do
            if v == command then
                table.remove(commandviewer.commands, i)
                break
            end
        end

        if table.getn(commandviewer.commands) == 0 then
            awful.hooks.timer.unregister(update_commandviewer)
        end
    else
        commandviewer.objs[command] = show_view(command)
        table.insert(commandviewer.commands, command)

        if table.getn(commandviewer.commands) == 1 then
            awful.hooks.timer.register(commandviewer.interval,
                update_commandviewer)
        end
    end
end

-- return view object
function show_view(command)
    local f = io.popen(command)
    local ns = f:read("*all")
    f:close()

    return naughty.notify{
        title = command,
        text = ns,
        position = "top_left",
        run = function()
            view_command(command) --destroy view
        end,
        timeout = 0,
    }
end

function hide_view(obj)
    naughty.destroy(obj)
end

function update_commandviewer()
    -- views disappear when they don't fit on the screen in the current implementation
    -- based on naughty
    for i,command in pairs(commandviewer.commands) do
        hide_view(commandviewer.objs[command])
        commandviewer.objs[command] = show_view(command)
    end
end

return {view_command = view_command}
