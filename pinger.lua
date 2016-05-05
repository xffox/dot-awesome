awful = require("awful")

function alive(command)
    return os.execute(command) == 0
end

function register_pinger(host, time, func_up, func_down)
    if host == nil or time == nil or func_up == nil or func_down == nil then
        return
    end

    local pinger = {}
    pinger.host = host 
    pinger.time = time 
    pinger.func_up = func_up
    pinger.func_down = func_down
    --initial
    pinger.is_up = nil

    --1 second timeout is still a problem for a single thread responsiveness
    --create object once
    pinger.command = "ping -W 1 -c 1 -n >/dev/null 2>&1 " .. pinger.host

    pinger.update = function()
        local res = alive(pinger.command)
        if pinger.is_up ~= res then
            if res then
                pinger.func_up()
            else
                pinger.func_down()
            end
            pinger.is_up = res
        end
    end

    awful.hooks.timer.register(pinger.time, pinger.update)

    --initial update can take time - turn it off
    pinger.update()
end

return {register_pinger = register_pinger}
