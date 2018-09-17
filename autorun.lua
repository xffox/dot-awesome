local awful = require("awful")

local function run_once(prg)
    if prg then
        awful.spawn.with_shell("pgrep -u $USER -x \"" .. prg .. "\" || (" .. prg .. ")")
    end
end

local function run_restart(prg)
    if prg then
        awful.spawn.with_shell("pkill -u $USER -x \"" .. prg .. "\"; (" .. prg .. ")")
    end
end

local function show_terminal_session(session)
    if os.execute("xwininfo -name '" .. session .. "' >/dev/null 2>&1") ~= 0 then
        awful.spawn.with_shell("(urxvt -title '" .. session .. "' -e sh -c \"while ! pgrep -u $USER -fx 'tmux start'; do sleep 1;done; exec tmux attach -t '" .. session .. "'\")")
    end
end

local function run_apps(apps)
    for app = 1, #apps do
        run_once(apps[app])
    end
end

local function restart_apps(apps)
    for app = 1, #apps do
        run_restart(apps[app])
    end
end

local function run_sessions(sessions)
    for session = 1, #sessions do
        show_terminal_session(sessions[session])
    end
end

return {run_apps = run_apps, restart_apps = restart_apps, run_sessions = run_sessions}
