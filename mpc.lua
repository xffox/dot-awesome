awful = require("awful")

local config = {host = "localhost", port = "6600"}

local function mpc(command)
    -- injections, yeah
    return string.format("mpc -h %s -p %s %s", config.host, config.port, command)
end

function toggle()
    awful.util.spawn(mpc("toggle"))
end

function stop()
    awful.util.spawn(mpc("stop"))
end

function prev()
    awful.util.spawn(mpc("prev"))
end

function next()
    awful.util.spawn(mpc("next"))
end

function status(fmt)
    -- injections, yeah
    return awful.util.pread(mpc("-f '" .. fmt .. "' current"))
end

function configure(host, port)
    config = {host = host, port = port}
end

return {toggle = toggle, stop = stop, prev = prev, next = next, status = status, configure = configure}
