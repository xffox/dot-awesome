naughty = require("naughty")
awful = require("awful")
lfs = require("lfs")

local mpd_status_view
function switch_mpd_status(mpc, fmt)
    if mpd_status_view == nil then
        local img = find_cover(mpc)
        local status = mpc.status(fmt)
        mpd_status_view = naughty.notify({title = "MPD",  text = status,
            icon = img, icon_size = 250, timeout = 0,
            run = function()
                if img ~= nil and img ~= "" then
                    awful.util.spawn('feh "' .. img .. '"')
                end
                switch_mpd_status(mpc)
            end})
    else
        naughty.destroy(mpd_status_view)
        mpd_status_view = nil
    end
end

function find_cover(mpc)
    local COVER_PATTERNS = {"^cover.jpg$", "^cover.png$"}
    local CONF_PATH = '/etc/mpd.conf'
    local res = nil
    local track_filename = mpc.status("%file%")
    if track_filename ~= "" then
        local f = io.open(CONF_PATH, 'r')
        if f ~= nil then
            conf = f:read("*all")
            local music_path = string.match(conf, 'music_directory%s+"(.-)"')
            if music_path ~= nil then
                local track_path = string.match(track_filename, "(.*)/")
                if track_path ~= nil then
                    local status, dir_iter, dir_obj = pcall(lfs.dir, music_path .. '/' .. track_path)
                    if status then
                        for file in dir_iter, dir_obj do
                            for _, pattern in ipairs(COVER_PATTERNS) do
                                if string.match(file, pattern) then
                                    res = music_path .. '/' .. track_path .. '/' .. file
                                    break
                                end
                            end
                            if res ~= nil then
                                break
                            end
                        end
                    end
                end
            end
            f:close()
        end
    end
    return res
end

return {switch_mpd_status = switch_mpd_status}
