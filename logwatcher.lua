local awful = require("awful")

-- FIXME:
local logwatcher = {}
logwatcher.logs = 
{
    emerge = { file = "/var/log/emerge.log" },
}
--logwatcher.logs_quiet = nil
--logwatcher.logs_interval = 1
--logwatcher.disp_timeout = 5
--
--function log_watch()
--  local events, nread, errno, errstr = inot:nbread()
--  if events then
--    for i, event in ipairs(events) do
--      for logname, log in pairs(logwatcher.logs) do
--        if event.wd == log.wd then log_changed(logname) end
--      end
--    end
--  end
--end
--
--function log_changed(logname)
--  local log = logwatcher.logs[logname]
--
--  -- read log file
--  local f = io.open(log.file)
--  local l = f:read("*all")
--  f:close()
--
--  -- first read just set length
--  if not log.len then
--    log.len = #l
--
--  -- if updated
--  else
--    local diff = l:sub(log.len +1, #l-1)
--
--    -- check if ignored
--    local ignored = false
--    for i, phr in ipairs(log.ignore or {}) do
--    if diff:find(phr) then ignored = true; break end
--    end
--
--    -- display log updates
--    if not (ignored or logwatcher.logs_quiet) then
--      naughty.notify{
--        title = '<span color="white">' .. logname .. "</span>: " .. log.file,
--        text = awful.util.escape(diff),
--        timeout = logwatcher.disp_timeout,
--      }
--    end
--
--    -- set last length
--    log.len = #l
--  end
--end
--
--local errno, errstr
--inot, errno, errstr = inotify.init(true)
--for logname, log in pairs(logwatcher.logs) do
--  log_changed(logname)
--  log.wd, errno, errstr = inot:add_watch(log.file, { "IN_MODIFY" })
--end
--
--awful.hooks.timer.register(logwatcher.logs_interval, log_watch)

local function watch(logs)
    -- TODO: this was working some time ago..., fix if needed
end

return {watch = watch}
